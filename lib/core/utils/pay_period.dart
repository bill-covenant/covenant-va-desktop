// Semi-monthly pay periods.
//
// Cut-offs fall on the 2nd and 4th Thursday of every month; payday is the
// Friday after the cut-off. A period runs from the day after the previous
// cut-off through the cut-off Thursday (both inclusive). In months with five
// Thursdays the 5th Thursday belongs to the period that ends on the next
// month's 2nd Thursday.
//
// All functions are pure and work on calendar dates (local, time-of-day
// ignored) so they can be unit tested.

class PayPeriod {
  /// First day of the period (day after the previous cut-off).
  final DateTime start;

  /// Cut-off Thursday — last day of the period (inclusive).
  final DateTime end;

  /// Friday after the cut-off.
  final DateTime payday;

  const PayPeriod({required this.start, required this.end, required this.payday});

  /// Stable identifier: the cut-off date as `YYYY-MM-DD`.
  String get key => formatIsoDate(end);

  String get label =>
      '${_fmtShort(start)} – ${_fmtShort(end)}, ${end.year}  •  Payday ${_fmtShort(payday)}';

  /// True if [date]'s calendar day falls inside this period.
  bool contains(DateTime date) {
    final d = dateOnly(date);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Map shape consumed by the timecard header dropdown.
  Map<String, dynamic> toOption() => {
        'key': key,
        'label': label,
        'start': start,
        'end': end,
        'payday': payday,
      };

  @override
  bool operator ==(Object other) =>
      other is PayPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'PayPeriod(${formatIsoDate(start)} → ${formatIsoDate(end)})';
}

/// Strips the time-of-day component.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// `YYYY-MM-DD` for a calendar date.
String formatIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// nth (1-based) Thursday of a month. [month] may be out of 1..12; it is
/// normalized (e.g. month 13 → January of the next year).
DateTime nthThursday(int year, int month, int n) {
  final first = DateTime(year, month, 1);
  final offset = (DateTime.thursday - first.weekday + 7) % 7; // days to first Thursday
  return DateTime(first.year, first.month, 1 + offset + 7 * (n - 1));
}

/// The cut-off immediately before [cutoff] (which must be a 2nd/4th Thursday).
DateTime previousCutoff(DateTime cutoff) {
  final second = nthThursday(cutoff.year, cutoff.month, 2);
  if (dateOnly(cutoff) == second) {
    return nthThursday(cutoff.year, cutoff.month - 1, 4);
  }
  return second;
}

/// The pay period that ends on [cutoff].
PayPeriod payPeriodForCutoff(DateTime cutoff) {
  final end = dateOnly(cutoff);
  final prev = previousCutoff(end);
  return PayPeriod(
    start: DateTime(prev.year, prev.month, prev.day + 1),
    end: end,
    payday: DateTime(end.year, end.month, end.day + 1),
  );
}

/// The pay period containing [date] (i.e. the first cut-off on/after it).
PayPeriod payPeriodContaining(DateTime date) {
  final d = dateOnly(date);
  for (var m = 0; m <= 1; m++) {
    for (final n in const [2, 4]) {
      final c = nthThursday(d.year, d.month + m, n);
      if (!c.isBefore(d)) return payPeriodForCutoff(c);
    }
  }
  // Unreachable: next month's 2nd Thursday is always after any date this month.
  throw StateError('No cut-off found after $d');
}

/// Pay periods that have started as of [today], most recent first. The first
/// element is the current (possibly still open) period.
List<PayPeriod> recentPayPeriods(DateTime today, {int count = 12}) {
  final periods = <PayPeriod>[];
  var cutoff = payPeriodContaining(today).end;
  while (periods.length < count) {
    periods.add(payPeriodForCutoff(cutoff));
    cutoff = previousCutoff(cutoff);
  }
  return periods;
}

String _fmtShort(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}';
}
