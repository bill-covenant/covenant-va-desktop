import 'package:flutter/material.dart';

class DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const DateRangePickerDialog({
    Key? key,
    this.initialStart,
    this.initialEnd,
  }) : super(key: key);

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  late DateTime _viewMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _selectingEnd = false;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    _viewMonth = DateTime(
      (_startDate ?? DateTime.now()).year,
      (_startDate ?? DateTime.now()).month,
    );
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (!_selectingEnd || _startDate == null || day.isBefore(_startDate!)) {
        _startDate = day;
        _endDate = null;
        _selectingEnd = true;
      } else {
        _endDate = day;
        _selectingEnd = false;
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_startDate == null || _endDate == null) return false;
    return !day.isBefore(_startDate!) && !day.isAfter(_endDate!);
  }

  bool _isStart(DateTime day) =>
      _startDate != null && day.year == _startDate!.year && day.month == _startDate!.month && day.day == _startDate!.day;

  bool _isEnd(DateTime day) =>
      _endDate != null && day.year == _endDate!.year && day.month == _endDate!.month && day.day == _endDate!.day;

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  List<DateTime?> _getCalendarDays() {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final lastDay = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(_viewMonth.year, _viewMonth.month, d));
    }
    return days;
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${_monthNames[d.month - 1].substring(0, 3)} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B2E), Color(0xFF2A2640)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.15),
              blurRadius: 60,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.date_range, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Date Range',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selected range display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(_formatDate(_startDate), style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_forward, size: 16, color: Colors.white.withOpacity(0.5)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(_formatDate(_endDate), style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Calendar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.chevron_left, color: Colors.white.withOpacity(0.7), size: 20),
                          ),
                        ),
                      ),
                      Text(
                        '${_monthNames[_viewMonth.month - 1]} ${_viewMonth.year}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1)),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Day headers
                  Row(
                    children: _dayNames.map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.4))),
                      ),
                    )).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Calendar grid
                  ..._buildCalendarRows(),
                ],
              ),
            ),

            // Quick presets
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _buildPresetButton('Last 7 days', () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 6));
                      _endDate = now;
                      _selectingEnd = false;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildPresetButton('Last 14 days', () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 13));
                      _endDate = now;
                      _selectingEnd = false;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildPresetButton('This month', () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = DateTime(now.year, now.month, 1);
                      _endDate = now;
                      _viewMonth = DateTime(now.year, now.month);
                      _selectingEnd = false;
                    });
                  }),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Center(
                            child: Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: (_startDate != null && _endDate != null)
                          ? () => Navigator.pop(context, DateTimeRange(start: _startDate!, end: _endDate!))
                          : null,
                      child: MouseRegion(
                        cursor: (_startDate != null && _endDate != null) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: (_startDate != null && _endDate != null)
                                ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)])
                                : null,
                            color: (_startDate != null && _endDate != null) ? null : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                color: (_startDate != null && _endDate != null) ? Colors.white : Colors.white.withOpacity(0.3),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalendarRows() {
    final days = _getCalendarDays();
    final rows = <Widget>[];

    for (int i = 0; i < days.length; i += 7) {
      final week = days.sublist(i, (i + 7).clamp(0, days.length));
      while (week.length < 7) {
        week.add(null);
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: week.map((day) {
              if (day == null) return const Expanded(child: SizedBox(height: 40));

              final isStart = _isStart(day);
              final isEnd = _isEnd(day);
              final inRange = _isInRange(day);
              final today = _isToday(day);
              final isSelected = isStart || isEnd;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDayTap(day),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : inRange
                                ? const Color(0xFF8B5CF6).withOpacity(0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: isStart ? const Radius.circular(20) : Radius.zero,
                          right: isEnd ? const Radius.circular(20) : Radius.zero,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: today && !isSelected
                                ? Border.all(color: const Color(0xFF8B5CF6), width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || today ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : inRange
                                        ? Colors.white.withOpacity(0.9)
                                        : today
                                            ? const Color(0xFF8B5CF6)
                                            : Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
