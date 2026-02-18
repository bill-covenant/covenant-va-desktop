// lib/presentation/timecard/widgets/log_hours_dialog.dart

import 'package:flutter/material.dart';
import '../../../data/repositories/timecard_repository.dart';
import '../../../core/di/service_locator.dart';
import 'time_card_widgets/break_entry.dart';
import 'time_card_widgets/break_section.dart';
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
  DateTime? _clockInDateTime; // Full DateTime from backend
  final List<BreakEntry> _paidBreaks = [];
  final List<BreakEntry> _lunchBreaks = [];
  bool _isLoading = true;
  bool _isClockingIn = false;

  bool get _isClockedIn => _clockInTime != null && _clockOutTime == null;
  bool get _isClockedOut => _clockInTime != null && _clockOutTime != null;
  bool get _canSave => _clockInTime != null && _clockOutTime != null;

  @override
  void initState() {
    super.initState();
    _loadActiveClockIn();
  }

  /// Check backend for active clock-in on dialog open
  Future<void> _loadActiveClockIn() async {
    try {
      final activeClock = await _timecardRepo.getActiveClock();
      if (activeClock != null && mounted) {
        final localTime = activeClock.toLocal();
        setState(() {
          _clockInDateTime = activeClock;
          _clockInTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
          _clockOutTime = null;
          _isLoading = false;
        });
        _notifyClockState();
      } else {
        // Also check if parent passed initial state (fallback)
        setState(() {
          _clockInTime = widget.initialClockIn;
          _clockOutTime = widget.initialClockOut;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading active clock: $e');
      setState(() {
        _clockInTime = widget.initialClockIn;
        _clockOutTime = widget.initialClockOut;
        _isLoading = false;
      });
    }
  }

  void _notifyClockState() {
    widget.onClockStateChanged?.call(_clockInTime, _clockOutTime);
  }

  Future<void> _handleClockToggle() async {
    if (_isClockingIn) return;

    setState(() => _isClockingIn = true);

    try {
      if (_clockInTime == null) {
        // CLOCK IN — save to backend
        final clockInDt = await _timecardRepo.clockIn();
        final localTime = clockInDt.toLocal();
        setState(() {
          _clockInDateTime = clockInDt;
          _clockInTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
          _clockOutTime = null;
        });
        print('✅ Clocked in at ${_clockInTime}');
      } else if (_clockOutTime == null) {
        // CLOCK OUT — clear backend, get times
        final result = await _timecardRepo.clockOut();
        final clockOutDt = (result['clockOutTime'] as DateTime).toLocal();
        setState(() {
          _clockOutTime = TimeOfDay(hour: clockOutDt.hour, minute: clockOutDt.minute);
        });
        print('✅ Clocked out at ${_clockOutTime}');
      }
    } catch (e) {
      print('❌ Clock toggle error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clock error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() => _isClockingIn = false);
      _notifyClockState();
    }
  }

  void _handleReset() async {
    // If clocked in, clear backend too
    if (_clockInTime != null && _clockOutTime == null) {
      try {
        await _timecardRepo.clockOut();
      } catch (_) {}
    }
    setState(() {
      _clockInTime = null;
      _clockOutTime = null;
      _clockInDateTime = null;
      _paidBreaks.clear();
      _lunchBreaks.clear();
    });
    _notifyClockState();
  }

  void _addPaidBreak() {
    setState(() {
      _paidBreaks.add(BreakEntry(
        start: TimeOfDay(hour: 11, minute: 0),
        end: TimeOfDay(hour: 11, minute: 15),
      ));
    });
  }

  void _addLunchBreak() {
    setState(() {
      _lunchBreaks.add(BreakEntry(
        start: TimeOfDay(hour: 12, minute: 0),
        end: TimeOfDay(hour: 13, minute: 0),
      ));
    });
  }

  void _removePaidBreak(int index) {
    setState(() => _paidBreaks.removeAt(index));
  }

  void _removeLunchBreak(int index) {
    setState(() => _lunchBreaks.removeAt(index));
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
    for (var b in _paidBreaks) total -= _breakDuration(b);
    for (var b in _lunchBreaks) total -= _breakDuration(b);
    return total > 0 ? double.parse(total.toStringAsFixed(2)) : 0.0;
  }

  double _breakDuration(BreakEntry b) {
    final s = b.start.hour + (b.start.minute / 60);
    final e = b.end.hour + (b.end.minute / 60);
    double d = e - s;
    if (d < 0) d += 24;
    return d;
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
        constraints: const BoxConstraints(maxHeight: 780),
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
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Column(
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TimeLogSection(
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
                          const SizedBox(height: 16),
                          BreakSection(
                            title: 'Paid Breaks',
                            icon: Icons.coffee_rounded,
                            color: const Color(0xFF10B981),
                            breaks: _paidBreaks,
                            onAdd: _addPaidBreak,
                            onRemove: _removePaidBreak,
                            onEditStart: (i) => _selectTime(
                              (t) => setState(() => _paidBreaks[i].start = t),
                              _paidBreaks[i].start,
                            ),
                            onEditEnd: (i) => _selectTime(
                              (t) => setState(() => _paidBreaks[i].end = t),
                              _paidBreaks[i].end,
                            ),
                          ),
                          const SizedBox(height: 16),
                          BreakSection(
                            title: 'Lunch Breaks',
                            icon: Icons.restaurant_rounded,
                            color: const Color(0xFFF59E0B),
                            breaks: _lunchBreaks,
                            onAdd: _addLunchBreak,
                            onRemove: _removeLunchBreak,
                            onEditStart: (i) => _selectTime(
                              (t) => setState(() => _lunchBreaks[i].start = t),
                              _lunchBreaks[i].start,
                            ),
                            onEditEnd: (i) => _selectTime(
                              (t) => setState(() => _lunchBreaks[i].end = t),
                              _lunchBreaks[i].end,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
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