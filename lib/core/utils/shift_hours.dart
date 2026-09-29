/// Shift duration math for the Log Hours dialog.
///
/// Works on full [DateTime]s (not TimeOfDay) so shifts crossing midnight and
/// DST changes are computed correctly.
class ShiftResult {
  final DateTime start;
  final DateTime end;

  /// Hours rounded to 2 decimals; 0 when [error] is set.
  final double hours;

  /// User-facing validation message, or null when the shift is valid.
  final String? error;

  const ShiftResult({
    required this.start,
    required this.end,
    required this.hours,
    this.error,
  });

  bool get isValid => error == null;
}

/// Longest overnight shift we infer when clock-out is earlier than clock-in.
const Duration maxInferredOvernight = Duration(hours: 16);

/// Longest single entry the server accepts.
const Duration maxShiftDuration = Duration(hours: 24);

/// Resolves a shift from [start] to [end].
///
/// If [end] is not after [start] (e.g. user picked 10 PM → 6 AM on the same
/// day) the end is moved to the next calendar day, but only when that yields a
/// shift of at most [maxInferredOvernight]; otherwise a validation error is
/// returned. Durations that are zero/negative or longer than
/// [maxShiftDuration] are rejected.
ShiftResult resolveShift(DateTime start, DateTime end) {
  var effectiveEnd = end;

  if (!effectiveEnd.isAfter(start)) {
    final nextDay = DateTime(end.year, end.month, end.day + 1, end.hour,
        end.minute, end.second, end.millisecond);
    if (nextDay.isAfter(start) &&
        nextDay.difference(start) <= maxInferredOvernight) {
      effectiveEnd = nextDay;
    } else {
      return ShiftResult(
        start: start,
        end: end,
        hours: 0,
        error: effectiveEnd.isAtSameMomentAs(start)
            ? 'Clock-out must be after clock-in.'
            : 'Clock-out is before clock-in. If this was an overnight shift it '
                'would be over ${maxInferredOvernight.inHours} hours — please check your times.',
      );
    }
  }

  final duration = effectiveEnd.difference(start);
  if (duration <= Duration.zero) {
    return ShiftResult(
      start: start,
      end: effectiveEnd,
      hours: 0,
      error: 'Total hours must be greater than zero.',
    );
  }
  if (duration > maxShiftDuration) {
    return ShiftResult(
      start: start,
      end: effectiveEnd,
      hours: 0,
      error: 'A single entry can\'t be longer than ${maxShiftDuration.inHours} hours. '
          'Please check your clock-in and clock-out times.',
    );
  }

  final hours = double.parse((duration.inSeconds / 3600).toStringAsFixed(2));
  if (hours <= 0) {
    return ShiftResult(
      start: start,
      end: effectiveEnd,
      hours: 0,
      error: 'Total hours must be greater than zero.',
    );
  }
  return ShiftResult(start: start, end: effectiveEnd, hours: hours);
}
