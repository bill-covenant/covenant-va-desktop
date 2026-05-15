import 'package:flutter/material.dart';
import '../../../data/repositories/timecard_repository.dart';
import '../../../core/di/service_locator.dart';
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
  DateTime? _clockInDateTime;
  bool _isLoading = false; // Start false — show UI immediately
  bool _isClockingIn = false;
  bool _isSaving = false;

  bool get _isClockedIn => _clockInTime != null && _clockOutTime == null;
  bool get _isClockedOut => _clockInTime != null && _clockOutTime != null;
  bool get _canSave => _clockInTime != null && _clockOutTime != null && !_isSaving;

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
      final activeClock = await _timecardRepo.getActiveClock();
      if (!mounted) return;

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
            _clockInTime = serverClockIn;
            _clockOutTime = null;
            _selectedDate = clockInDate;
          });
          _notifyClockState();
        } else {
          _clockInDateTime = activeClock;
          _selectedDate = clockInDate;
        }
      }
      // If no active clock and we don't have parent state, that's fine — UI already shows empty
    } catch (_) {
      // Silently fail — we already have parent state or empty state showing
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
            });
            _notifyClockState();
            _showError('Clock in failed: ${e.toString()}');
          }
        }
      } else if (_clockOutTime == null) {
        // CLOCK OUT — optimistic update first
        final now = TimeOfDay.now();
        setState(() {
          _clockOutTime = now;
        });
        _notifyClockState();

        // Then persist to backend
        try {
          final result = await _timecardRepo.clockOut();
          final clockOutDt = (result['clockOutTime'] as DateTime).toLocal();
          if (mounted) {
            setState(() {
              _clockOutTime = TimeOfDay(hour: clockOutDt.hour, minute: clockOutDt.minute);
            });
            _notifyClockState();
          }
        } catch (e) {
          // Revert optimistic update
          if (mounted) {
            setState(() {
              _clockOutTime = null;
            });
            _notifyClockState();
            _showError('Clock out failed: ${e.toString()}');
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

  void _handleReset() async {
    if (_clockInTime != null && _clockOutTime == null) {
      try {
        await _timecardRepo.clockOut();
      } catch (_) {}
    }
    setState(() {
      _clockInTime = null;
      _clockOutTime = null;
      _clockInDateTime = null;
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
    if (picked != null) onTimeSelected(picked);
  }

  double _calculateHours() {
    if (_clockInTime == null || _clockOutTime == null) return 0.0;
    final clockIn = _clockInTime!.hour + (_clockInTime!.minute / 60);
    final clockOut = _clockOutTime!.hour + (_clockOutTime!.minute / 60);
    double total = clockOut - clockIn;
    if (total < 0) total += 24;
    return total > 0 ? double.parse(total.toStringAsFixed(2)) : 0.0;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _handleSave() async {
    if (!_canSave) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DaySummaryDialog(
        clockInTime: _formatTime(_clockInTime!),
        clockOutTime: _formatTime(_clockOutTime!),
        totalHours: _calculateHours(),
      ),
    );

    if (result == null || !mounted) return;

    final hours = _calculateHours();
    final clockDesc = 'Clock In: ${_formatTime(_clockInTime!)}, Clock Out: ${_formatTime(_clockOutTime!)}';
    final notes = result['notes'] as String? ?? '';
    final moodLabel = result['moodLabel'] as String? ?? '';

    String description = clockDesc;
    if (moodLabel.isNotEmpty) description += '\nMood: $moodLabel';
    if (notes.isNotEmpty) description += '\nNotes: $notes';

    Navigator.pop(context, {
      'date': _selectedDate,
      'hoursWorked': hours,
      'description': description,
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onReset: _handleReset,
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
                          setState(() => _clockInTime = t);
                          _notifyClockState();
                        }, _clockInTime)
                    : null,
                onEditClockOut: _clockOutTime != null
                    ? () => _selectTime((t) {
                          setState(() => _clockOutTime = t);
                          _notifyClockState();
                        }, _clockOutTime)
                    : null,
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