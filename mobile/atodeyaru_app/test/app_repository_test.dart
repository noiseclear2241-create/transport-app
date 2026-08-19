import 'dart:io';

import 'package:atodeyaru_app/models/models.dart';
import 'package:atodeyaru_app/services/app_repository.dart';
import 'package:atodeyaru_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 実機のプラットフォームチャンネルを持たないテスト環境向けの通知スケジューラ。
/// 呼び出しを記録するだけで、実際の通知プラグインには一切触れない。
class FakeNotificationScheduler implements NotificationScheduler {
  int scheduleCount = 0;
  int cancelCount = 0;

  @override
  Future<void> scheduleTaskNotifications(TaskItem task, List<int> daysBeforeList) async {
    scheduleCount++;
  }

  @override
  Future<void> scheduleSnoozeNotification(TaskItem task, DateTime exactTime) async {
    scheduleCount++;
  }

  @override
  Future<void> cancelTaskNotifications(String taskId, {List<int> possibleDaysBefore = const []}) async {
    cancelCount++;
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // デスクトップ/CI環境で実際のSQLiteエンジン(sqlite3)を使う。
    // 本番のモバイル実装（sqfliteのプラットフォームチャンネル版）は差し替えない。
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // テスト実行のたびに使い捨ての一時ディレクトリへDBを作成し、
    // 過去の実行結果が残ってテストが不安定になるのを防ぐ。
    final tempDir = Directory.systemTemp.createTempSync('atodeyaru_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() {
    // AppSettings/デフォルト家族IDの永続化先をテストごとにクリーンな状態にする。
    SharedPreferences.setMockInitialValues({});
  });

  test('契約登録からタスク生成・完了・削除までの一連の流れが実DBを通して動く', () async {
    final fakeNotifications = FakeNotificationScheduler();
    final repo = AppRepository(notifications: fakeNotifications);

    // --- 初回読み込み：家族が0人なら「自分」が自動生成される（#24） ---
    await repo.load();
    expect(repo.isLoaded, isTrue);
    expect(repo.familyMembers, hasLength(1));
    expect(repo.familyMembers.first.name, '自分');
    expect(repo.canAddContract, isTrue, reason: '無料版でも1件目までは登録できる');

    // --- 契約登録 ---
    final contract = await repo.addContract(
      familyMemberId: repo.defaultFamilyMemberId,
      type: ContractType.smartphone,
      carrier: Carrier.docomo,
      contractDate: DateTime(2026, 8, 19),
    );
    expect(repo.contracts, hasLength(1));
    expect(repo.canAddContract, isFalse, reason: '無料版は契約1件まで（#23, #29）');

    // --- オプション登録：無料期間2か月 → 解約確認日が暦月計算で自動算出される（#15） ---
    await repo.upsertOption(
      contractId: contract.id,
      name: 'かけ放題オプション',
      startDate: DateTime(2026, 8, 19),
      freePeriod: PeriodPreset.m2,
    );
    final option = repo.optionsByContract[contract.id]!.single;
    expect(option.cancellationCheckDate, DateTime(2026, 10, 19));

    // --- タスクが自動生成され、ローカル通知の予約が呼ばれている ---
    final task = repo.tasks.singleWhere((t) => t.sourceType == 'option' && t.sourceId == option.id);
    expect(task.title, 'かけ放題オプションを確認');
    expect(task.dueDate, DateTime(2026, 10, 19));
    expect(task.status, TaskStatus.pending);
    expect(repo.pendingTasks, contains(task));
    expect(fakeNotifications.scheduleCount, greaterThan(0));

    // --- タスク完了（#40） ---
    await repo.completeTask(task);
    final completed = repo.completedTasks.singleWhere((t) => t.id == task.id);
    expect(completed.status, TaskStatus.done);
    expect(completed.completedAt, isNotNull);
    expect(repo.pendingTasks.any((t) => t.id == task.id), isFalse);

    // --- 契約削除で関連タスクも消える（掃除漏れがないか、#64のデータ削除の前提確認） ---
    await repo.deleteContract(contract.id);
    expect(repo.contracts, isEmpty);
    expect(repo.tasks.where((t) => t.sourceId == option.id), isEmpty);
  });

  test('無料期間「わからない」を選ぶと自動計算されず、案内対象になる（#42）', () async {
    final repo = AppRepository(notifications: FakeNotificationScheduler());
    await repo.load();

    final contract = await repo.addContract(
      familyMemberId: repo.defaultFamilyMemberId,
      type: ContractType.internet,
      carrier: Carrier.other,
      carrierOther: 'ローカル光回線',
      contractDate: DateTime(2026, 1, 10),
    );

    await repo.upsertOption(
      contractId: contract.id,
      name: '謎オプション',
      startDate: DateTime(2026, 1, 10),
      freePeriod: PeriodPreset.unknown,
    );

    final option = repo.optionsByContract[contract.id]!.single;
    expect(option.cancellationCheckDate, isNull);
    // 解約確認日が決まらないタスクは生成されない。
    expect(repo.tasks.where((t) => t.sourceType == 'option' && t.sourceId == option.id), isEmpty);
  });
}
