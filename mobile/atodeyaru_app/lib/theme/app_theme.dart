import 'package:flutter/material.dart';

/// シンプルで安心感のあるデザイン（#52）。
/// 文字を大きめにし、重要な予定を大きく表示、専門用語を減らす方針に合わせた
/// 共通テーマ。iOS/Android共通のMaterial 3をベースにしつつ、
/// 各画面で戻る操作やダイアログなどOS標準の体験を尊重する（#53）。
class AppColors {
  static const primary = Color(0xFF2F6FED);
  static const background = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const danger = Color(0xFFE5484D); // 🔴 解約
  static const warning = Color(0xFFF5A623); // 🟡 申請 / 🟠 返却
  static const success = Color(0xFF2E9E5B); // 🟢 特典
  static const info = Color(0xFF2F6FED); // 🔵 確認
  static const textPrimary = Color(0xFF1B1F27);
  static const textSecondary = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      brightness: Brightness.light,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontSizeFactor: 1.05, // 文字を大きめに（#52）
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52), // 片手操作しやすい大きめタップ領域（#52）
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      ),
    );
  }
}

extension TaskTypeColor on String {
  Color get taskTypeColor {
    switch (this) {
      case 'cancellation':
        return AppColors.danger;
      case 'application':
        return AppColors.warning;
      case 'benefit':
        return AppColors.success;
      case 'device_return':
        return AppColors.warning;
      case 'confirmation':
      default:
        return AppColors.info;
    }
  }
}
