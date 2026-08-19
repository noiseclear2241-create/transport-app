import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// アプリ設定・課金状態のローカル保存（#45, #46）。
/// 小容量のキー・バリューのみのため SharedPreferences で十分であり、
/// サーバーコストを増やさない。
class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _kOnboarding = 'onboarding_completed';
  static const _kSubState = 'subscription_state';
  static const _kTrialStart = 'trial_started_at';
  static const _kNextBilling = 'next_billing_date';
  static const _kGCalConnected = 'google_calendar_connected';
  static const _kGCalId = 'google_calendar_id';
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kDefaultFamilyMemberId = 'default_family_member_id';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      onboardingCompleted: prefs.getBool(_kOnboarding) ?? false,
      subscriptionState:
          SubscriptionState.fromValue(prefs.getString(_kSubState) ?? SubscriptionState.free.value),
      trialStartedAt: _parse(prefs.getString(_kTrialStart)),
      nextBillingDate: _parse(prefs.getString(_kNextBilling)),
      googleCalendarConnected: prefs.getBool(_kGCalConnected) ?? false,
      googleCalendarId: prefs.getString(_kGCalId),
      notificationsEnabled: prefs.getBool(_kNotificationsEnabled) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, settings.onboardingCompleted);
    await prefs.setString(_kSubState, settings.subscriptionState.value);
    if (settings.trialStartedAt != null) {
      await prefs.setString(_kTrialStart, settings.trialStartedAt!.toIso8601String());
    }
    if (settings.nextBillingDate != null) {
      await prefs.setString(_kNextBilling, settings.nextBillingDate!.toIso8601String());
    }
    await prefs.setBool(_kGCalConnected, settings.googleCalendarConnected);
    if (settings.googleCalendarId != null) {
      await prefs.setString(_kGCalId, settings.googleCalendarId!);
    }
    await prefs.setBool(_kNotificationsEnabled, settings.notificationsEnabled);
  }

  Future<String?> getDefaultFamilyMemberId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultFamilyMemberId);
  }

  Future<void> setDefaultFamilyMemberId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultFamilyMemberId, id);
  }

  /// アカウント削除（#64）：設定もすべて初期化する。
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  DateTime? _parse(String? value) => value == null ? null : DateTime.parse(value);
}
