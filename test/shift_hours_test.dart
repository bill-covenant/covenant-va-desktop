import 'package:covenant_va_desktop/core/utils/shift_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same-day shift', () {
    final r = resolveShift(DateTime(2026, 9, 29, 9, 0), DateTime(2026, 9, 29, 17, 30));
    expect(r.isValid, isTrue);
    expect(r.hours, 8.5);
  });

  test('uses exact server timestamps (seconds included)', () {
    final r = resolveShift(
      DateTime.utc(2026, 9, 29, 1, 0, 0),
      DateTime.utc(2026, 9, 29, 3, 0, 36),
    );
    expect(r.hours, 2.01);
  });

  test('overnight shift: end before start is moved to next day', () {
    final r = resolveShift(DateTime(2026, 9, 28, 22, 0), DateTime(2026, 9, 28, 6, 0));
    expect(r.isValid, isTrue);
    expect(r.hours, 8.0);
    expect(r.end, DateTime(2026, 9, 29, 6, 0));
  });

  test('server-recorded shift crossing midnight', () {
    final r = resolveShift(DateTime(2026, 9, 28, 22, 0), DateTime(2026, 9, 29, 6, 15));
    expect(r.hours, 8.25);
  });

  test('inferred overnight longer than 16h is rejected', () {
    // 6 AM → 5 AM would be a 23h overnight shift
    final r = resolveShift(DateTime(2026, 9, 29, 6, 0), DateTime(2026, 9, 29, 5, 0));
    expect(r.isValid, isFalse);
    expect(r.hours, 0);
  });

  test('zero-length shift is rejected', () {
    final t = DateTime(2026, 9, 29, 9, 0);
    final r = resolveShift(t, t);
    expect(r.isValid, isFalse);
  });

  test('longer than 24h is rejected', () {
    final r = resolveShift(DateTime(2026, 9, 28, 8, 0), DateTime(2026, 9, 29, 9, 0));
    expect(r.isValid, isFalse);
  });

  test('exactly 24h is allowed', () {
    final r = resolveShift(DateTime.utc(2026, 9, 28, 8, 0), DateTime.utc(2026, 9, 29, 8, 0));
    expect(r.isValid, isTrue);
    expect(r.hours, 24.0);
  });
}
