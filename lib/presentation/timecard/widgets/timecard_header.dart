import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TimecardViewMode { monthly, payPeriod, dateRange }

class TimecardHeader extends StatelessWidget {
  final TimecardViewMode viewMode;
  final Function(TimecardViewMode) onViewModeChanged;

  // Monthly mode
  final String selectedMonth;
  final List<String> monthOptions;
  final Function(String) onMonthChanged;

  // Pay period mode
  final String? selectedPayPeriod;
  final List<Map<String, dynamic>>? payPeriodOptions;
  final Function(String)? onPayPeriodChanged;

  // Date range mode
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback? onPickDateRange;

  final VoidCallback onLogHours;
  final VoidCallback? onRefresh;
  final Widget? trailing;

  const TimecardHeader({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.selectedMonth,
    required this.monthOptions,
    required this.onMonthChanged,
    this.selectedPayPeriod,
    this.payPeriodOptions,
    this.onPayPeriodChanged,
    this.startDate,
    this.endDate,
    this.onPickDateRange,
    required this.onLogHours,
    this.onRefresh,
    this.trailing,
  });

  String _formatMonthDisplay(String month) {
    final parts = month.split('-');
    final year = parts[0];
    final monthNum = int.parse(parts[1]);
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[monthNum - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(50, 24, 48, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.5),
                          offset: const Offset(0, 8),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.access_time_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'My Timecard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildFilterSelector(context),
                  const SizedBox(width: 12),
                  _buildLogHoursButton(),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // View mode toggle
          _buildViewModeToggle(context),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Monthly', TimecardViewMode.monthly, Icons.calendar_month),
          _buildToggleButton('Pay Period', TimecardViewMode.payPeriod, Icons.account_balance_wallet),
          _buildToggleButton('Date Range', TimecardViewMode.dateRange, Icons.date_range),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, TimecardViewMode mode, IconData icon) {
    final isActive = viewMode == mode;
    return GestureDetector(
      onTap: () => onViewModeChanged(mode),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSelector(BuildContext context) {
    switch (viewMode) {
      case TimecardViewMode.monthly:
        return _buildMonthSelector();
      case TimecardViewMode.payPeriod:
        return _buildPayPeriodSelector();
      case TimecardViewMode.dateRange:
        return _buildDateRangeButton(context);
    }
  }

  Widget _buildMonthSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          dropdownColor: const Color(0xFF1F2937),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          items: monthOptions.map((month) {
            return DropdownMenuItem(value: month, child: Text(_formatMonthDisplay(month)));
          }).toList(),
          onChanged: (value) { if (value != null) onMonthChanged(value); },
        ),
      ),
    );
  }

  Widget _buildPayPeriodSelector() {
    if (payPeriodOptions == null || payPeriodOptions!.isEmpty) {
      return const SizedBox();
    }
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPayPeriod,
          dropdownColor: const Color(0xFF1F2937),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          items: payPeriodOptions!.map((p) {
            return DropdownMenuItem(
              value: p['key'] as String,
              child: Text(p['label'] as String),
            );
          }).toList(),
          onChanged: (value) { if (value != null) onPayPeriodChanged?.call(value); },
        ),
      ),
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final label = (startDate != null && endDate != null)
        ? '${dateFormat.format(startDate!)} – ${dateFormat.format(endDate!)}'
        : 'Select Date Range';

    return GestureDetector(
      onTap: onPickDateRange,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogHoursButton() {
    return ElevatedButton.icon(
      onPressed: onLogHours,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Log Hours',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF7C3AED),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 8,
        shadowColor: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
