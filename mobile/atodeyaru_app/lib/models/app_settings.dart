import 'enums.dart';

/// 端末内に保存する設定・課金状態（#34, #45）。
/// アカウント/課金/家族共有/Googleカレンダー連携はサーバー管理が必要になるが、
/// MVPでは端末ローカルに「現在の状態のキャッシュ」として保持し、
/// ストアからの検証結果で更新する設計にしておく（#46）。
class AppSettings {
  final bool onboardingCompleted;
  final SubscriptionState subscriptionState;
  final DateTime? trialStartedAt; // 7日間無料体験の開始日時（#31）
  final DateTime? nextBillingDate;
  final bool googleCalendarConnected;
  final String? googleCalendarId;
  final bool notificationsEnabled;

  const AppSettings({
    this.onboardingCompleted = false,
    this.subscriptionState = SubscriptionState.free,
    this.trialStartedAt,
    this.nextBillingDate,
    this.googleCalendarConnected = false,
    this.googleCalendarId,
    this.notificationsEnabled = true,
  });

  bool get isPremium =>
      subscriptionState == SubscriptionState.premium ||
      subscriptionState == SubscriptionState.trial ||
      subscriptionState == SubscriptionState.cancelling;

  /// トライアル残り日数（7日間、#31）。マイナスは体験終了済み。
  int trialDaysRemaining(DateTime now) {
    if (trialStartedAt == null) return 0;
    final end = trialStartedAt!.add(const Duration(days: 7));
    return end.difference(now).inHours ~/ 24 + (end.difference(now).inHours % 24 > 0 ? 1 : 0);
  }

  AppSettings copyWith({
    bool? onboardingCompleted,
    SubscriptionState? subscriptionState,
    DateTime? trialStartedAt,
    DateTime? nextBillingDate,
    bool? googleCalendarConnected,
    String? googleCalendarId,
    bool? notificationsEnabled,
  }) =>
      AppSettings(
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        subscriptionState: subscriptionState ?? this.subscriptionState,
        trialStartedAt: trialStartedAt ?? this.trialStartedAt,
        nextBillingDate: nextBillingDate ?? this.nextBillingDate,
        googleCalendarConnected: googleCalendarConnected ?? this.googleCalendarConnected,
        googleCalendarId: googleCalendarId ?? this.googleCalendarId,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}
