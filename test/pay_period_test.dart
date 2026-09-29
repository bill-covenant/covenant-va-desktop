import 'package:covenant_va_desktop/core/utils/pay_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime d(int y, int m, int day) => DateTime(y, m, day);

  group('nthThursday', () {
    test('finds 2nd and 4th Thursdays', () {
      expect(nthThursday(2026, 9, 2), d(2026, 9, 10));
      expect(nthThursday(2026, 9, 4), d(2026, 9, 24));
      // Month starting on a Thursday
      expect(nthThursday(2026, 10, 1), d(2026, 10, 1));
      expect(nthThursday(2026, 10, 2), d(2026, 10, 8));
    });

    test('normalizes month overflow/underflow', () {
      expect(nthThursday(2026, 13, 2), d(2027, 1, 14));
      expect(nthThursday(2027, 0, 4), d(2026, 12, 24));
    });
  });

  group('payPeriodContaining', () {
    test('today (2026-09-29) is in the open period Sep 25 – Oct 8', () {
      final p = payPeriodContaining(DateTime(2026, 9, 29, 15, 42));
      expect(p.start, d(2026, 9, 25));
      expect(p.end, d(2026, 10, 8));
      expect(p.payday, d(2026, 10, 9));
      expect(p.key, '2026-10-08');
    });

    test('cut-off day itself belongs to the period it closes', () {
      final p = payPeriodContaining(DateTime(2026, 10, 8, 23, 59));
      expect(p.end, d(2026, 10, 8));
      expect(p.contains(DateTime(2026, 10, 8, 23, 59)), isTrue);

      // The Friday after the cut-off starts the next period
      final next = payPeriodContaining(d(2026, 10, 9));
      expect(next.start, d(2026, 10, 9));
      expect(next.end, d(2026, 10, 22));
      expect(p.contains(d(2026, 10, 9)), isFalse);
    });

    test('5-Thursday month: the 5th Thursday rolls into next month\'s period', () {
      // October 2026 has Thursdays 1, 8, 15, 22, 29
      final p = payPeriodContaining(d(2026, 10, 29));
      expect(p.start, d(2026, 10, 23));
      expect(p.end, d(2026, 11, 12));
      expect(p.payday, d(2026, 11, 13));
    });

    test('December → January rollover', () {
      // December 2026 has 5 Thursdays (3, 10, 17, 24, 31)
      final p = payPeriodContaining(d(2026, 12, 31));
      expect(p.start, d(2026, 12, 25));
      expect(p.end, d(2027, 1, 14));
      expect(p.payday, d(2027, 1, 15));
      expect(payPeriodContaining(d(2027, 1, 1)), p);
      expect(payPeriodContaining(d(2027, 1, 14)), p);
    });

    test('first period of a year starts in the previous December', () {
      final p = payPeriodForCutoff(d(2027, 1, 14));
      expect(p.start, d(2026, 12, 25));
    });
  });

  group('recentPayPeriods', () {
    final periods = recentPayPeriods(DateTime(2026, 9, 29, 9));

    test('includes the current open period first', () {
      expect(periods.length, 12);
      expect(periods.first.start, d(2026, 9, 25));
      expect(periods.first.end, d(2026, 10, 8));
      expect(periods[1].start, d(2026, 9, 11));
      expect(periods[1].end, d(2026, 9, 24));
      expect(periods[2].start, d(2026, 8, 28));
      expect(periods[2].end, d(2026, 9, 10));
    });

    test('periods are contiguous with no gaps or overlaps', () {
      for (var i = 0; i < periods.length - 1; i++) {
        final newer = periods[i];
        final older = periods[i + 1];
        final dayAfterOlder = DateTime(older.end.year, older.end.month, older.end.day + 1);
        expect(newer.start, dayAfterOlder, reason: '$older → $newer');
      }
    });

    test('every cut-off is a 2nd or 4th Thursday and every start has begun', () {
      final today = d(2026, 9, 29);
      for (final p in periods) {
        expect(p.end.weekday, DateTime.thursday);
        expect(
          p.end == nthThursday(p.end.year, p.end.month, 2) ||
              p.end == nthThursday(p.end.year, p.end.month, 4),
          isTrue,
        );
        expect(p.start.isAfter(today), isFalse);
      }
    });

    test('keys are unique', () {
      expect(periods.map((p) => p.key).toSet().length, periods.length);
    });

    test('spans a year boundary', () {
      final jan = recentPayPeriods(d(2027, 1, 5), count: 3);
      expect(jan[0].start, d(2026, 12, 25));
      expect(jan[0].end, d(2027, 1, 14));
      expect(jan[1].start, d(2026, 12, 11));
      expect(jan[1].end, d(2026, 12, 24));
      expect(jan[2].end, d(2026, 12, 10));
    });
  });

  test('formatIsoDate pads month and day', () {
    expect(formatIsoDate(d(2026, 1, 5)), '2026-01-05');
  });
}
