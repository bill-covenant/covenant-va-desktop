// lib/presentation/timecard/widgets/log_hours_dialog.dart

import 'package:flutter/material.dart';
import 'time_card_widgets/break_entry.dart';
import 'time_card_widgets/time_field.dart';
import 'time_card_widgets/break_section.dart';

class LogHoursDialog extends StatefulWidget {
  const LogHoursDialog({Key? key}) : super(key: key);

  @override
  State<LogHoursDialog> createState() => _LogHoursDialogState();
}

class _LogHoursDialogState extends State<LogHoursDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _clockInTime;
  TimeOfDay? _clockOutTime;
  final List<BreakEntry> _paidBreaks = [];
  final List<BreakEntry> _lunchBreaks = [];
  
  bool get _canSave => _clockInTime != null && _clockOutTime != null;

  void _handleClockIn() {
    setState(() {
      _clockInTime = TimeOfDay.now();
    });
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
    setState(() {
      _paidBreaks.removeAt(index);
    });
  }

  void _removeLunchBreak(int index) {
    setState(() {
      _lunchBreaks.removeAt(index);
    });
  }

  Future<void> _selectTime(BuildContext context, Function(TimeOfDay) onTimeSelected, TimeOfDay? initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B8DEF),
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  double _calculateHours() {
    if (_clockInTime == null || _clockOutTime == null) return 0.0;
    
    final clockIn = _clockInTime!.hour + (_clockInTime!.minute / 60);
    final clockOut = _clockOutTime!.hour + (_clockOutTime!.minute / 60);
    
    double totalHours = clockOut - clockIn;
    if (totalHours < 0) totalHours += 24;
    
    // Subtract break times
    for (var breakEntry in _paidBreaks) {
      totalHours -= _calculateBreakDuration(breakEntry);
    }
    for (var breakEntry in _lunchBreaks) {
      totalHours -= _calculateBreakDuration(breakEntry);
    }
    
    return totalHours > 0 ? totalHours : 0.0;
  }

  double _calculateBreakDuration(BreakEntry breakEntry) {
    final start = breakEntry.start.hour + (breakEntry.start.minute / 60);
    final end = breakEntry.end.hour + (breakEntry.end.minute / 60);
    double duration = end - start;
    if (duration < 0) duration += 24;
    return duration;
  }

  void _handleSave() {
    if (!_canSave) return;
    
    final hours = _calculateHours();
    final description = 'Clock In: ${_formatTime(_clockInTime!)}, Clock Out: ${_formatTime(_clockOutTime!)}';
    
    Navigator.pop(context, {
      'date': _selectedDate,
      'hoursWorked': hours,
      'description': description,
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔥🔥🔥 NEW TIME CARD DIALOG LOADED 🔥🔥🔥');
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildClockInButton(),
            _buildScrollableContent(),
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0E7FF)],
                  ).createShader(bounds),
                  child: const Text(
                    'Time Card',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your work hours and breaks easily',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockInButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: InkWell(
        onTap: _clockInTime == null ? _handleClockIn : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: _clockInTime == null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.6),
                      const Color(0xFF7C3AED).withOpacity(0.6),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _clockInTime == null 
                    ? 'Clock In' 
                    : 'Clocked In at ${_formatTime(_clockInTime!)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            _buildClockInOutFields(),
            const SizedBox(height: 20),
            BreakSection(
              title: 'Paid Breaks',
              icon: Icons.coffee_rounded,
              color: const Color(0xFF10B981),
              breaks: _paidBreaks,
              onAdd: _addPaidBreak,
              onRemove: _removePaidBreak,
              onEditStart: (index) => _selectTime(
                context,
                (time) => setState(() => _paidBreaks[index].start = time),
                _paidBreaks[index].start,
              ),
              onEditEnd: (index) => _selectTime(
                context,
                (time) => setState(() => _paidBreaks[index].end = time),
                _paidBreaks[index].end,
              ),
            ),
            const SizedBox(height: 20),
            BreakSection(
              title: 'Lunch Breaks',
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFF59E0B),
              breaks: _lunchBreaks,
              onAdd: _addLunchBreak,
              onRemove: _removeLunchBreak,
              onEditStart: (index) => _selectTime(
                context,
                (time) => setState(() => _lunchBreaks[index].start = time),
                _lunchBreaks[index].start,
              ),
              onEditEnd: (index) => _selectTime(
                context,
                (time) => setState(() => _lunchBreaks[index].end = time),
                _lunchBreaks[index].end,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildClockInOutFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TimeField(
              label: 'Clock In',
              time: _clockInTime,
              onTap: _clockInTime == null
                  ? null
                  : () => _selectTime(
                        context,
                        (time) => setState(() => _clockInTime = time),
                        _clockInTime,
                      ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TimeField(
              label: 'Clock Out',
              time: _clockOutTime,
              onTap: _clockInTime == null
                  ? null
                  : () => _selectTime(
                        context,
                        (time) => setState(() => _clockOutTime = time),
                        _clockOutTime,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canSave ? _handleSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: _canSave
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.3),
                            Colors.grey.withOpacity(0.2),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _canSave
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.save_rounded,
                      size: 20,
                      color: _canSave ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _canSave ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}