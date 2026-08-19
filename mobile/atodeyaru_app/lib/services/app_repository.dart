import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'database_service.dart';
import 'date_calculator.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'task_generator.dart';

const _uuid = Uuid();

/// アプリ全体の状態を保持するリポジトリ（ChangeNotifier）。
///
/// - ローカルDB（sqflite）とのやり取りを一元化
/// - オプション/特典/端末の変更に応じたタスクの再生成
/// - ローカル通知の再スケジュール
/// - 無料版の利用制限（契約1件・端末1台、#23, #29）
///
/// UIはこのクラスをProviderで受け取り、直接DatabaseServiceを触らない。
class AppRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final SettingsService _settingsService = SettingsService.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<FamilyMember> familyMembers = [];
  List<Contract> contracts = [];
  Map<String, List<ContractOption>> optionsByContract = {};
  Map<String, List<Benefit>> benefitsByContract = {};
  List<Device> devices = [];
  List<TaskItem> tasks = [];
  AppSettings settings = const AppSettings();

  String? _defaultFamilyMemberId;
  String get defaultFamilyMemberId => _defaultFamilyMemberId!;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    settings = await _settingsService.load();
    familyMembers = await _db.getFamilyMembers();

    if (familyMembers.isEmpty) {
      // 無料版でも「自分」1人分は内部的に自動生成する（#24）。
      final me = FamilyMember(id: _uuid.v4(), name: '自分', relation: '本人', createdAt: DateTime.now());
      await _db.upsertFamilyMember(me);
      familyMembers = [me];
    }
    _defaultFamilyMemberId = await _settingsService.getDefaultFamilyMemberId() ?? familyMembers.first.id;
    await _settingsService.setDefaultFamilyMemberId(_defaultFamilyMemberId!);

    contracts = await _db.getContracts();
    for (final c in contracts) {
      optionsByContract[c.id] = await _db.getOptions(contractId: c.id);
      benefitsByContract[c.id] = await _db.getBenefits(contractId: c.id);
    }
    devices = await _db.getDevices();
    tasks = await _db.getTasks();

    _loaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // 無料版の利用制限（#23, #29, #30）
  // ---------------------------------------------------------------------
  bool get canAddContract => settings.isPremium || contracts.isEmpty;
  bool get canAddDevice => settings.isPremium || devices.isEmpty;
  bool get canAddFamilyMember => settings.isPremium;
  bool get canUseGoogleCalendar => settings.isPremium;

  // ---------------------------------------------------------------------
  // family members（#24）。電話番号は同姓同名の家族を区別するための任意項目。
  // ---------------------------------------------------------------------
  Future<void> addFamilyMember(String name, String? relation, {String? phoneNumber}) async {
    final m = FamilyMember(
      id: _uuid.v4(),
      name: name,
      relation: relation,
      phoneNumber: phoneNumber,
      createdAt: DateTime.now(),
    );
    await _db.upsertFamilyMember(m);
    familyMembers = await _db.getFamilyMembers();
    notifyListeners();
  }

  Future<void> updateFamilyMember(FamilyMember updated) async {
    await _db.upsertFamilyMember(updated);
    familyMembers = await _db.getFamilyMembers();
    notifyListeners();
  }

  /// 家族メンバーを削除する。最後の1人（自分）は削除できない。
  /// 削除済みメンバーが所有していた契約・端末はデータとしては残るため、
  /// 別のメンバーへの付け替えを促す（#24）。
  Future<void> deleteFamilyMember(String id) async {
    if (familyMembers.length <= 1) return;
    await _db.deleteFamilyMember(id);
    familyMembers = await _db.getFamilyMembers();
    if (_defaultFamilyMemberId == id) {
      _defaultFamilyMemberId = familyMembers.first.id;
      await _settingsService.setDefaultFamilyMemberId(_defaultFamilyMemberId!);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // contracts
  // ---------------------------------------------------------------------
  Future<Contract> addContract({
    required String familyMemberId,
    required ContractType type,
    required Carrier carrier,
    String? carrierOther,
    required DateTime contractDate,
    String? contractNumber,
    int? monthlyFeeYen,
    String? memo,
  }) async {
    final now = DateTime.now();
    final contract = Contract(
      id: _uuid.v4(),
      familyMemberId: familyMemberId,
      type: type,
      carrier: carrier,
      carrierOther: carrierOther,
      contractDate: contractDate,
      contractNumber: contractNumber,
      monthlyFeeYen: monthlyFeeYen,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertContract(contract);
    contracts = await _db.getContracts();
    optionsByContract[contract.id] = [];
    benefitsByContract[contract.id] = [];
    notifyListeners();
    return contract;
  }

  Future<void> updateContract(Contract updated) async {
    await _db.upsertContract(updated);
    contracts = await _db.getContracts();
    notifyListeners();
  }

  Future<void> deleteContract(String id) async {
    for (final o in optionsByContract[id] ?? []) {
      await _notifications.cancelTaskNotifications(o.id);
    }
    for (final b in benefitsByContract[id] ?? []) {
      await _notifications.cancelTaskNotifications(b.id);
    }
    await _db.deleteContract(id);
    contracts = await _db.getContracts();
    optionsByContract.remove(id);
    benefitsByContract.remove(id);
    tasks = await _db.getTasks();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // options（無料期間の自動計算 #15 とタスク再生成をここで一括して行う）
  // ---------------------------------------------------------------------
  Future<void> upsertOption({
    required String contractId,
    String? id,
    required String name,
    int? monthlyFeeYen,
    required DateTime startDate,
    required PeriodPreset freePeriod,
    int? freePeriodCustomMonths,
    DateTime? manualCancellationCheckDate,
    String? memo,
    List<int>? notifyDaysBefore,
  }) async {
    final now = DateTime.now();
    final autoDate = DateCalculator.calculateFreePeriodEndDate(
      startDate: startDate,
      freePeriod: freePeriod,
      customMonths: freePeriodCustomMonths,
    );
    final option = ContractOption(
      id: id ?? _uuid.v4(),
      contractId: contractId,
      name: name,
      monthlyFeeYen: monthlyFeeYen,
      startDate: startDate,
      freePeriod: freePeriod,
      freePeriodCustomMonths: freePeriodCustomMonths,
      cancellationCheckDate: manualCancellationCheckDate ?? autoDate,
      memo: memo,
      notifyDaysBefore: notifyDaysBefore ?? defaultCancellationNotifyDaysBefore,
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertOption(option);
    optionsByContract[contractId] = await _db.getOptions(contractId: contractId);

    await _regenerateTaskForSource(
      sourceType: 'option',
      sourceId: option.id,
      familyMemberId: _contractOwner(contractId),
      build: () => TaskGenerator.forOption(option, _contractOwner(contractId)),
      notifyDaysBefore: option.notifyDaysBefore,
    );
    notifyListeners();
  }

  Future<void> deleteOption(String contractId, String optionId) async {
    await _notifications.cancelTaskNotifications(optionId);
    await _db.deleteOption(optionId);
    optionsByContract[contractId] = await _db.getOptions(contractId: contractId);
    tasks = await _db.getTasks();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // benefits（申請と受取を分離して管理 #18）
  // ---------------------------------------------------------------------
  Future<void> upsertBenefit({
    required String contractId,
    String? id,
    required String name,
    int? amountYen,
    required BenefitType type,
    required bool applicationRequired,
    DateTime? applicationStartDate,
    DateTime? applicationDeadline,
    DateTime? expectedReceiptDate,
    String? condition,
    String? memo,
    BenefitStatus status = BenefitStatus.notApplied,
  }) async {
    final now = DateTime.now();
    final benefit = Benefit(
      id: id ?? _uuid.v4(),
      contractId: contractId,
      name: name,
      amountYen: amountYen,
      type: type,
      applicationRequired: applicationRequired,
      applicationStartDate: applicationStartDate,
      applicationDeadline: applicationDeadline,
      expectedReceiptDate: expectedReceiptDate,
      condition: condition,
      memo: memo,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertBenefit(benefit);
    benefitsByContract[contractId] = await _db.getBenefits(contractId: contractId);

    final owner = _contractOwner(contractId);
    await _regenerateTaskForSource(
      sourceType: 'benefit_application',
      sourceId: benefit.id,
      familyMemberId: owner,
      build: () => TaskGenerator.forBenefitApplication(benefit, owner),
      notifyDaysBefore: defaultCancellationNotifyDaysBefore,
    );
    await _regenerateTaskForSource(
      sourceType: 'benefit_receipt',
      sourceId: benefit.id,
      familyMemberId: owner,
      build: () => TaskGenerator.forBenefitReceipt(benefit, owner),
      notifyDaysBefore: defaultCancellationNotifyDaysBefore,
    );
    notifyListeners();
  }

  Future<void> updateBenefitStatus(String contractId, Benefit benefit, BenefitStatus status) async {
    final updated = benefit.copyWith(status: status);
    await _db.upsertBenefit(updated);
    benefitsByContract[contractId] = await _db.getBenefits(contractId: contractId);
    notifyListeners();
  }

  Future<void> deleteBenefit(String contractId, String benefitId) async {
    await _notifications.cancelTaskNotifications(benefitId);
    await _db.deleteBenefit(benefitId);
    benefitsByContract[contractId] = await _db.getBenefits(contractId: contractId);
    tasks = await _db.getTasks();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // devices（返却時期管理 #19, #20）
  // ---------------------------------------------------------------------
  Future<Device> upsertDevice({
    String? id,
    required String familyMemberId,
    String? contractId,
    required String name,
    String? maker,
    DateTime? purchaseDate,
    DateTime? useStartDate,
    required DevicePurchaseMethod purchaseMethod,
    int? priceYen,
    int? installmentCount,
    int? monthlyPaymentYen,
    String? returnProgramName,
    required ReturnPeriodPreset returnPeriod,
    int? returnPeriodCustomMonths,
    DateTime? manualReturnCheckDate,
    DateTime? returnDeadline,
    String? memo,
    List<int>? notifyDaysBefore,
  }) async {
    final now = DateTime.now();
    final baseDate = useStartDate ?? purchaseDate ?? now;
    final autoDate = DateCalculator.calculateReturnCheckDate(
      baseDate: baseDate,
      returnPeriod: returnPeriod,
      customMonths: returnPeriodCustomMonths,
    );
    final device = Device(
      id: id ?? _uuid.v4(),
      familyMemberId: familyMemberId,
      contractId: contractId,
      name: name,
      maker: maker,
      purchaseDate: purchaseDate,
      useStartDate: useStartDate,
      purchaseMethod: purchaseMethod,
      priceYen: priceYen,
      installmentCount: installmentCount,
      monthlyPaymentYen: monthlyPaymentYen,
      returnProgramName: returnProgramName,
      returnPeriod: returnPeriod,
      returnPeriodCustomMonths: returnPeriodCustomMonths,
      returnCheckDate: manualReturnCheckDate ?? autoDate,
      returnDeadline: returnDeadline,
      memo: memo,
      notifyDaysBefore: notifyDaysBefore ?? defaultReturnNotifyDaysBefore,
      createdAt: now,
      updatedAt: now,
    );
    await _db.upsertDevice(device);
    devices = await _db.getDevices();

    if (id == null) {
      for (var i = 0; i < defaultChecklistLabels.length; i++) {
        await _db.upsertChecklistItem(ChecklistItem(
          id: _uuid.v4(),
          deviceId: device.id,
          label: defaultChecklistLabels[i],
          checked: false,
          sortOrder: i,
        ));
      }
    }

    await _regenerateTaskForSource(
      sourceType: 'device_return',
      sourceId: device.id,
      familyMemberId: familyMemberId,
      build: () => TaskGenerator.forDeviceReturn(device, familyMemberId),
      notifyDaysBefore: device.notifyDaysBefore,
    );
    notifyListeners();
    return device;
  }

  Future<void> deleteDevice(String id) async {
    await _notifications.cancelTaskNotifications(id);
    await _db.deleteDevice(id);
    devices = await _db.getDevices();
    tasks = await _db.getTasks();
    notifyListeners();
  }

  Future<List<ChecklistItem>> getChecklistItems(String deviceId) => _db.getChecklistItems(deviceId);

  Future<void> toggleChecklistItem(ChecklistItem item) async {
    await _db.upsertChecklistItem(item.copyWith(checked: !item.checked));
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // tasks（完了・あとで・履歴 #39, #40, #41）
  // ---------------------------------------------------------------------
  Future<void> completeTask(TaskItem task) async {
    final updated = task.copyWith(status: TaskStatus.done, completedAt: DateTime.now());
    await _db.upsertTask(updated);
    await _notifications.cancelTaskNotifications(task.id);
    tasks = await _db.getTasks();
    notifyListeners();
  }

  Future<void> reopenTask(TaskItem task) async {
    final updated = task.copyWith(status: TaskStatus.pending, completedAt: null);
    await _db.upsertTask(updated);
    tasks = await _db.getTasks();
    notifyListeners();
  }

  /// 通知の「あとで」機能（#39）。指定した日時ちょうどに再通知する。
  Future<void> snoozeTask(TaskItem task, DateTime until) async {
    final updated = task.copyWith(status: TaskStatus.snoozed, snoozedUntil: until);
    await _db.upsertTask(updated);
    await _notifications.cancelTaskNotifications(task.id);
    await _notifications.scheduleSnoozeNotification(updated, until);
    tasks = await _db.getTasks();
    notifyListeners();
  }

  List<TaskItem> get pendingTasks =>
      tasks.where((t) => t.status != TaskStatus.done).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<TaskItem> get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.done).toList()
        ..sort((a, b) => (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt));

  // ---------------------------------------------------------------------
  // settings / subscription（#31, #34）
  // ---------------------------------------------------------------------
  Future<void> completeOnboarding() async {
    settings = settings.copyWith(onboardingCompleted: true);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> startFreeTrial() async {
    settings = settings.copyWith(
      subscriptionState: SubscriptionState.trial,
      trialStartedAt: DateTime.now(),
    );
    await _settingsService.save(settings);
    notifyListeners();
  }

  /// StoreKit / Google Play Billing からの購入結果を反映する（#32, #33, #34）。
  Future<void> applySubscriptionState(SubscriptionState state, {DateTime? nextBillingDate}) async {
    settings = settings.copyWith(subscriptionState: state, nextBillingDate: nextBillingDate);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> setGoogleCalendarConnected(bool connected, {String? calendarId}) async {
    settings = settings.copyWith(googleCalendarConnected: connected, googleCalendarId: calendarId);
    await _settingsService.save(settings);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    settings = settings.copyWith(notificationsEnabled: enabled);
    await _settingsService.save(settings);
    notifyListeners();
  }

  /// アカウント削除（#64）：端末内の全データを削除し、初回起動と同じ状態に戻す。
  Future<void> deleteAllData() async {
    await _notifications.cancelAll();
    await _db.deleteAllData();
    await _settingsService.clearAll();
    familyMembers = [];
    contracts = [];
    optionsByContract = {};
    benefitsByContract = {};
    devices = [];
    tasks = [];
    settings = const AppSettings();
    _defaultFamilyMemberId = null;
    // load()が「自分」の再作成・オンボーディング状態の初期化まで行う。
    await load();
  }

  // ---------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------
  String _contractOwner(String contractId) {
    final contract = contracts.firstWhere((c) => c.id == contractId);
    return contract.familyMemberId;
  }

  Future<void> _regenerateTaskForSource({
    required String sourceType,
    required String sourceId,
    required String familyMemberId,
    required TaskItem? Function() build,
    required List<int> notifyDaysBefore,
  }) async {
    // 既存タスクを洗い替え、常に最新の日付・金額を反映する。
    final existing = await _db.getTasksBySource(sourceType, sourceId);
    final wasDone = existing.isNotEmpty && existing.first.status == TaskStatus.done;
    for (final t in existing) {
      await _notifications.cancelTaskNotifications(t.id);
    }
    await _db.deleteTasksBySource(sourceType, sourceId);

    final newTask = build();
    if (newTask != null) {
      final toSave = wasDone
          ? newTask.copyWith(status: TaskStatus.done, completedAt: DateTime.now())
          : newTask;
      await _db.upsertTask(toSave);
      if (!wasDone && settings.notificationsEnabled) {
        await _notifications.scheduleTaskNotifications(toSave, notifyDaysBefore);
      }
    }
    tasks = await _db.getTasks();
  }
}
