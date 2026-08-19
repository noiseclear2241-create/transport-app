import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';
import 'date_calculator.dart';

/// ローカル通知サービス（#36, #37, #38）。
///
/// サーバーから毎回通知する設計は禁止（#38）。固定の予定（解約確認日・
/// 返却確認日など）は端末側のローカル通知のみで完結させ、サーバー費用を
/// 発生させない。タイムゾーンはAsia/Tokyo固定（#15）。
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'atodeyaru_reminders';
  static const _channelName = 'やることリマインダー';
  static const _channelDescription = '解約確認・キャッシュバック申請・返却時期などのお知らせ';

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // 初回起動タイミングを自前で制御する（#37）
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// 初回の通知許可リクエスト（#37）。
  /// iOS: UNUserNotificationCenter の許可ダイアログ。
  /// Android 13+ (API 33+): POST_NOTIFICATIONS 権限。
  Future<bool> requestPermission() async {
    await init();
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidImpl?.requestNotificationsPermission();

    return iosGranted ?? androidGranted ?? true;
  }

  // 「あとで」スヌーズ通知（#39）専用のID空間。日数ベースのIDと衝突しないよう
  // daysBefore に負の番兵値を使う。
  static const _snoozeMarker = -1;

  int _notificationIdFor(String taskId, int daysBefore) {
    // タスクID(文字列)と通知タイミングから安定した整数IDを作る。
    return Object.hash(taskId, daysBefore) & 0x7fffffff;
  }

  /// タスクの締切日から、指定された「○日前」リストぶんの通知をまとめて予約する。
  Future<void> scheduleTaskNotifications(TaskItem task, List<int> daysBeforeList) async {
    await init();
    for (final days in daysBeforeList) {
      final notifyDate = DateCalculator.notifyDateFor(task.dueDate, days);
      // 朝9時に通知（ITに詳しくないユーザーにも分かりやすい固定時刻）。
      final scheduled = tz.TZDateTime(
        tz.local,
        notifyDate.year,
        notifyDate.month,
        notifyDate.day,
        9,
      );
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final body = days == 0
          ? '今日は「${task.title}」の日です。'
          : days == 1
              ? '明日は「${task.title}」の日です。'
              : '「${task.title}」まであと$days日です。';

      await _plugin.zonedSchedule(
        _notificationIdFor(task.id, days),
        '${task.type.emoji} ${task.title}',
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.active),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task:${task.id}',
      );
    }
  }

  /// 「あとで」機能（#39）：正確な日時を指定して1件だけ通知する。
  /// 日付単位の scheduleTaskNotifications と異なり、時刻まで指定できる。
  Future<void> scheduleSnoozeNotification(TaskItem task, DateTime exactTime) async {
    await init();
    final scheduled = tz.TZDateTime.from(exactTime, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _notificationIdFor(task.id, _snoozeMarker),
      '${task.type.emoji} ${task.title}',
      '「${task.title}」の通知です。',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.active),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:${task.id}',
    );
  }

  /// タスクの通知をすべてキャンセルする（完了・削除・再計算時に使用）。
  Future<void> cancelTaskNotifications(String taskId, {List<int> possibleDaysBefore = const [
    90, 60, 30, 14, 7, 3, 1, 0,
  ]}) async {
    await init();
    for (final days in possibleDaysBefore) {
      await _plugin.cancel(_notificationIdFor(taskId, days));
    }
    await _plugin.cancel(_notificationIdFor(taskId, _snoozeMarker));
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
