import 'package:flutter/material.dart';
import '../../../data/repositories/timecard_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/shift_hours.dart';
import 'time_card_widgets/clock_dialog/dialog_header.dart';
import 'time_card_widgets/clock_dialog/clock_button.dart';
import 'time_card_widgets/clock_dialog/time_log_section.dart';
import 'time_card_widgets/clock_dialog/dialog_footer.dart';
import 'time_card_widgets/clock_dialog/day_summary_dialog.dart';

class LogHoursDialog extends StatefulWidget {
  final TimeOfDay? initialClockIn;
  final TimeOfDay? initialClockOut;
  final void Function(TimeOfDay? clockIn, TimeOfDay? clockOut)? onClockStateChanged;

  const LogHoursDialog({
    Key? key,
    this.initialClockIn,
    this.initialClockOut,
    this.onClockStateChanged,
  }) : super(key: key);

  @override
  State<LogHoursDialog> createState() => _LogHoursDialogState();
}

class _LogHoursDialogState extends State<LogHoursDialog> {
  final TimecardRepository _timecardRepo = getIt<TimecardRepository>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _clockInTime;
  TimeOfDay? _clockOutTime;
  // Exact clock times recorded by the server (clock-in / clock-out / pending
  // shift). Used for the hours calculation until the VA edits a time.
  DateTime? _clockInDateTime;
  DateTime? _clockOutDateTime;
  bool _clockInEdited = false;
  bool _isClockingIn = false;
  bool _isResetting = false;

  bool get _isClockedIn => _clockInTime != null && _clockOutTime == null;
  bool get _isClockedOut => _clockInTime != null && _clockOutTime != null;
  bool get _canSave => _clockInTime != null && _clockOutTime != null;

  @override
  void initState() {
    super.initState();
    // Show parent's cached state immediately (no loading spinner)
    _clockInTime = widget.initialClockIn;
    _clockOutTime = widget.initialClockOut;
    // Then sync with backend in background
    _syncActiveClockIn();
  }

  /// Sync with backend WITHOUT blocking the UI
  Future<void> _syncActiveClockIn() async {
    try {
      final status = await _timecardRepo.getClockStatus();
      if (!mounted) return;

      // A pending shift = clocked out but not yet saved. Restore both times so
      // the VA can Save it (this is what prevents the worked time being lost).
      if (status.pendingClockIn != null && status.pendingClockOut != null) {
        final inLocal = status.pendingClockIn!.toLocal();
        final outLocal = status.pendingClockOut!.toLocal();
        setState(() {
          _clockInDateTime = status.pendingClockIn;
          _clockOutDateTime = status.pendingClockOut;
          _clockInEdited = false;
          _clockInTime = TimeOfDay(hour: inLocal.hour, minute: inLocal.minute);
          _clockOutTime = TimeOfDay(hour: outLocal.hour, minute: outLocal.minute);
          // Date the entry to the clock-in day — covers overnight shifts.
          _selectedDate = DateTime(inLocal.year, inLocal.month, inLocal.day);
        });
        _notifyClockState();
        return;
      }

      final activeClock = status.clockIn;
      if (activeClock != null) {
        final localTime = activeClock.toLocal();
        final serverClockIn = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
        // Always use the clock-in date, not today — covers overnight shifts crossing midnight
        final clockInDate = DateTime(localTime.year, localTime.month, localTime.day);
        // Only update if different from what we're showing
        if (_clockInTime?.hour != serverClockIn.hour ||
            _clockInTime?.minute != serverClockIn.minute) {
          setState(() {
            _clockInDateTime = activeClock;
            _clockOutDateTime = null;
            _clockInTime = serverClockIn;
            _clockOutTime = null;
            _selectedDate = clockInDate;
          });
          _notifyClockState();
        } else {
          setState(() {
            _clockInDateTime = activeClock;
            _selectedDate = clockInDate;
          });
        }
      }
      // If no active clock and we don't have parent state, that's fine — UI already shows empty
    } catch (e) {
      // Keep showing the parent's cached state, but tell the VA it may be stale.
      _showError('Could not refresh clock status — showing last known times. '
          '${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _notifyClockState() {
    widget.onClockStateChanged?.call(_clockInTime, _clockOutTime);
  }

  Future<bool> _showClockConfirmation({required bool isClockIn}) async {
    final now = TimeOfDay.now();
    final timeStr = _formatTime(now);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isClockIn
                    ? const Color(0xFF7C3AED).withOpacity(0.4)
                    : const Color(0xFFEF4444).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isClockIn
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isClockIn
                          ? [const Color(0xFF7C3AED), const Color(0xFF9333EA)]
                          : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isClockIn
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFEF4444))
                            .withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isClockIn ? Icons.play_arrow_rounded : Icons.stop_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  isClockIn ? 'Start Your Shift?' : 'End Your Shift?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                // Subtitle
                Text(
                  isClockIn
                      ? 'You are about to clock in at $timeStr.\nYour time will start tracking.'
                      : 'You are about to clock out at $timeStr.\nYour shift will be recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: isClockIn
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isClockIn
                                  ? Icons.play_arrow_rounded
                                  : Icons.stop_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isClockIn ? 'Clock In' : 'Clock Out',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return confirmed == true;
  }

  Future<void> _handleClockToggle() async {
    if (_isClockingIn) return;

    if (_clockInTime == null) {
      // CLOCK IN — show confirmation first
      final confirmed = await _showClockConfirmation(isClockIn: true);
      if (!confirmed || !mounted) return;
    } else if (_clockOutTime == null) {
      // CLOCK OUT — show confirmation first
      final confirmed = await _showClockConfirmation(isClockIn: false);
      if (!confirmed || !mounted) return;
    }

    setState(() => _isClockingIn = true);

    try {
      if (_clockInTime == null) {
        // CLOCK IN — optimistic update first
        final now = TimeOfDay.now();
        setState(() {
          _clockInTime = now;
          _clockOutTime = null;
          _clockInDateTime = DateTime.now();
          _clockOutDateTime = null;
          _clockInEdited = false;
          _selectedDate = DateTime.now();
        });
        _notifyClockState();

        // Then persist to backend
        try {
          final clockInDt = await _timecardRepo.clockIn();
          final localTime = clockInDt.toLocal();
          if (mounted) {
            setState(() {
              _clockInDateTime = clockInDt;
              // Update with exact server time (may differ by a second)
              _clockInTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
            });
            _notifyClockState();
          }
        } catch (e) {
          // Revert optimistic update
          if (mounted) {
            setState(() {
              _clockInTime = null;
              _clockOutTime = null;
              _clockInDateTime = null;
              _clockOutDateTime = null;
            });
            _notifyClockState();
            _showError('Clock in failed: ${e.toString().replaceFirst('Exception: ', '')}');
          }
        }
      } else if (_clockOutTime == null) {
        // CLOCK OUT — optimistic update first
        final now = TimeOfDay.now();
        setState(() {
          _clockOutTime = now;
          _clockOutDateTime = DateTime.now();
        });
        _notifyClockState();

        // Then persist to backend
        try {
          final result = await _timecardRepo.clockOut();
          final clockOutDt = (result['clockOutTime'] as DateTime).toLocal();
          if (mounted) {
            setState(() {
              _clockOutTime = TimeOfDay(hour: clockOutDt.hour, minute: clockOutDt.minute);
              _clockOutDateTime = result['clockOutTime'] as DateTime;
              // Use the server-recorded clock-in unless the VA edited it.
              if (!_clockInEdited) {
                final inDt = result['clockInTime'] as DateTime;
                final inLocal = inDt.toLocal();
                _clockInDateTime = inDt;
                _clockInTime = TimeOfDay(hour: inLocal.hour, minute: inLocal.minute);
                _selectedDate = DateTime(inLocal.year, inLocal.month, inLocal.day);
              }
            });
            _notifyClockState();
          }
        } catch (e) {
          // Revert optimistic update
          if (mounted) {
            setState(() {
              _clockOutTime = null;
              _clockOutDateTime = null;
            });
            _notifyClockState();
            _showError('Clock out failed: ${e.toString().replaceFirst('Exception: ', '')}');
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isClockingIn = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _handleReset() async {
    if (_isResetting) return;
    setState(() => _isResetting = true);
    // Discard the shift entirely (clears active + pending) so it isn't recorded.
    // Only clear the UI once the server has actually discarded it — otherwise
    // the shift would silently come back (or be lost) on the next sync.
    try {
      await _timecardRepo.clockClear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      _showError('Could not discard the shift: ${e.toString().replaceFirst('Exception: ', '')}');
      return;
    }
    if (!mounted) return;
    setState(() {
      _isResetting = false;
      _clockInTime = null;
      _clockOutTime = null;
      _clockInDateTime = null;
      _clockOutDateTime = null;
      _clockInEdited = false;
    });
    _notifyClockState();
  }


  Future<void> _selectTime(Function(TimeOfDay) onTimeSelected, TimeOfDay? initialTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5B8DEF),
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) onTimeSelected(picked);
  }

  /// Resolves the shift from full DateTimes. Server-recorded clock times are
  /// used as-is; manually edited times are placed on the entry date, and a
  /// clock-out earlier than clock-in is treated as the next day (≤16h only).
  ShiftResult? _currentShift() {
    if (_clockInTime == null || _clockOutTime == null) return null;
    final start = _clockInDateTime?.toLocal() ??
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
            _clockInTime!.hour, _clockInTime!.minute);
    final end = _clockOutDateTime?.toLocal() ??
        DateTime(start.year, start.month, start.day,
            _clockOutTime!.hour, _clockOutTime!.minute);
    return resolveShift(start, end);
  }

  double _calculateHours() {
    final shift = _currentShift();
    if (shift == null || !shift.isValid) return 0.0;
    return shift.hours;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _handleSave() async {
    if (!_canSave) return;

    final shift = _currentShift();
    if (shift == null) return;
    if (!shift.isValid) {
      _showError(shift.error!);
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DaySummaryDialog(
        clockInTime: _formatTime(_clockInTime!),
        clockOutTime: _formatTime(_clockOutTime!),
        totalHours: shift.hours,
      ),
    );

    if (result == null || !mounted) return;

    final hours = shift.hours;
    final clockDesc = 'Clock In: ${_formatTime(_clockInTime!)}, Clock Out: ${_formatTime(_clockOutTime!)}';
    final notes = result['notes'] as String? ?? '';
    final moodLabel = result['moodLabel'] as String? ?? '';

    String description = clockDesc;
    if (moodLabel.isNotEmpty) description += '\nMood: $moodLabel';
    if (notes.isNotEmpty) description += '\nNotes: $notes';

    // Date the entry to the shift's start (clock-in) day — covers overnight
    // shifts and matches the server's pending clock-in date.
    Navigator.pop(context, {
      'date': DateTime(shift.start.year, shift.start.month, shift.start.day),
      'hoursWorked': hours,
      'description': description,
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftError = _currentShift()?.error;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.3),
              blurRadius: 40, offset: const Offset(0, 20), spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 60, offset: const Offset(0, 30),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              isClockedOut: _isClockedOut,
              onReset: _isResetting ? () {} : _handleReset,
            ),
            ClockButton(
              clockInTime: _clockInTime,
              clockOutTime: _clockOutTime,
              isClockedIn: _isClockedIn,
              isClockedOut: _isClockedOut,
              totalHours: _calculateHours(),
              formatTime: _formatTime,
              onTap: _isClockingIn ? () {} : _handleClockToggle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TimeLogSection(
                clockInTime: _clockInTime,
                clockOutTime: _clockOutTime,
                onEditClockIn: _clockInTime != null
                    ? () => _selectTime((t) {
                          setState(() {
                            _clockInTime = t;
                            // Manually edited — place on the entry date
                            _clockInDateTime = null;
                            _clockInEdited = true;
                          });
                          _notifyClockState();
                        }, _clockInTime)
                    : null,
                onEditClockOut: _clockOutTime != null
                    ? () => _selectTime((t) {
                          setState(() {
                            _clockOutTime = t;
                            _clockOutDateTime = null;
                          });
                          _notifyClockState();
                        }, _clockOutTime)
                    : null,
              ),
            ),
            if (shiftError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shiftError,
                        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            DialogFooter(
              canSave: _canSave,
              onCancel: () => Navigator.pop(context),
              onSave: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}