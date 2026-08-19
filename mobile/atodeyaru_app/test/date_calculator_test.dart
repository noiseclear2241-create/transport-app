import 'package:atodeyaru_app/models/enums.dart';
import 'package:atodeyaru_app/services/date_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateCalculator.addCalendarMonths', () {
    test('仕様どおり：2026-08-19 + 2か月 = 2026-10-19 (#15)', () {
      final result = DateCalculator.addCalendarMonths(DateTime(2026, 8, 19), 2);
      expect(result, DateTime(2026, 10, 19));
    });

    test('年をまたぐ加算', () {
      final result = DateCalculator.addCalendarMonths(DateTime(2026, 11, 15), 3);
      expect(result, DateTime(2027, 2, 15));
    });

    test('月末クランプ：1/31 + 1か月 = 2/28（うるう年でない）', () {
      final result = DateCalculator.addCalendarMonths(DateTime(2027, 1, 31), 1);
      expect(result, DateTime(2027, 2, 28));
    });

    test('月末クランプ：1/31 + 1か月 = 2/29（うるう年）', () {
      final result = DateCalculator.addCalendarMonths(DateTime(2028, 1, 31), 1);
      expect(result, DateTime(2028, 2, 29));
    });

    test('0か月は同じ日付', () {
      final result = DateCalculator.addCalendarMonths(DateTime(2026, 8, 19), 0);
      expect(result, DateTime(2026, 8, 19));
    });

    test('12か月は1年後の同じ日', () {
      final result = DateCalculator.addCalendarMonths(DateTime(2026, 8, 19), 12);
      expect(result, DateTime(2027, 8, 19));
    });
  });

  group('DateCalculator.calculateFreePeriodEndDate', () {
    test('わからない、の場合はnull', () {
      final result = DateCalculator.calculateFreePeriodEndDate(
        startDate: DateTime(2026, 8, 19),
        freePeriod: PeriodPreset.unknown,
      );
      expect(result, isNull);
    });

    test('カスタム月数を使う', () {
      final result = DateCalculator.calculateFreePeriodEndDate(
        startDate: DateTime(2026, 8, 19),
        freePeriod: PeriodPreset.custom,
        customMonths: 4,
      );
      expect(result, DateTime(2026, 12, 19));
    });
  });

  group('DateCalculator.calculateReturnCheckDate', () {
    test('25か月目（#20）', () {
      final result = DateCalculator.calculateReturnCheckDate(
        baseDate: DateTime(2026, 8, 19),
        returnPeriod: ReturnPeriodPreset.m25,
      );
      expect(result, DateTime(2028, 9, 19));
    });
  });

  group('DateCalculator.daysUntil', () {
    test('未来日はプラス、過去日はマイナス', () {
      final today = DateTime(2026, 8, 19);
      expect(DateCalculator.daysUntil(DateTime(2026, 8, 26), today), 7);
      expect(DateCalculator.daysUntil(DateTime(2026, 8, 12), today), -7);
      expect(DateCalculator.daysUntil(DateTime(2026, 8, 19), today), 0);
    });
  });
}
