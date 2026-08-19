import '../models/enums.dart';

/// 無料期間終了日・返却確認日などを「カレンダー上の月単位」で計算するユーティリティ。
///
/// 例（#15）：
///   契約日 2026-08-19 + 無料期間2か月 → 2026-10-19
///
/// 30日を単純加算するのではなく、月をまたいだ「同じ日」を基準にする。
/// 加算先の月にその日が存在しない場合（例: 1/31 + 1か月）は、
/// その月の末日にクランプする（例: 2/28 または 2/29）。
///
/// 日付は日付のみを扱い、時刻情報は保持しない（タイムゾーンは Asia/Tokyo 前提で
/// 通知スケジューリング側が変換する）。
class DateCalculator {
  const DateCalculator._();

  /// [date] に [months] か月を暦月単位で加算する。
  static DateTime addCalendarMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    // Dartの整数除算は負数を切り捨てるため、負の月インデックスも正しく扱う。
    final monthIndexRaw = totalMonths % 12;
    final monthIndex = monthIndexRaw < 0 ? monthIndexRaw + 12 : monthIndexRaw;
    final month = monthIndex + 1;
    final lastDayOfMonth = _lastDayOfMonth(year, month);
    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    return DateTime(year, month, day);
  }

  static int _lastDayOfMonth(int year, int month) {
    final firstOfNextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  /// オプションの無料期間終了日（＝解約確認日の目安）を計算する（#15）。
  /// カスタム月数・わからない、の場合はnullを返し、ユーザーの手動入力に委ねる。
  static DateTime? calculateFreePeriodEndDate({
    required DateTime startDate,
    required PeriodPreset freePeriod,
    int? customMonths,
  }) {
    if (freePeriod == PeriodPreset.unknown) return null;
    final months = freePeriod == PeriodPreset.custom ? customMonths : freePeriod.months;
    if (months == null) return null;
    return addCalendarMonths(startDate, months);
  }

  /// 端末の返却確認日を計算する（#20）。
  /// 会社・プログラムにより条件が異なるため「返却確認日」「返却目安」という
  /// 表現に統一し、断定的な「返却期限」は自動計算しない。
  static DateTime? calculateReturnCheckDate({
    required DateTime baseDate,
    required ReturnPeriodPreset returnPeriod,
    int? customMonths,
  }) {
    if (returnPeriod == ReturnPeriodPreset.unknown) return null;
    final months = returnPeriod == ReturnPeriodPreset.custom ? customMonths : returnPeriod.months;
    if (months == null) return null;
    return addCalendarMonths(baseDate, months);
  }

  /// 通知タイミング（days前）から実際の通知日を計算する。
  static DateTime notifyDateFor(DateTime dueDate, int daysBefore) {
    return DateTime(dueDate.year, dueDate.month, dueDate.day).subtract(Duration(days: daysBefore));
  }

  /// 「あと○日」の表示用（#25）。日付のみで比較し、時刻の影響を受けない。
  static int daysUntil(DateTime target, DateTime today) {
    final t = DateTime(target.year, target.month, target.day);
    final b = DateTime(today.year, today.month, today.day);
    return t.difference(b).inDays;
  }
}
