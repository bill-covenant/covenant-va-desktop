// lib/presentation/timecard/widgets/monthly_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/time_entry.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;

  const MonthlySummaryCard({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? [const Color(0xFF1A1D2E), const Color(0xFF232738)]
              : [const Color(0xFF7C3AED), const Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: _isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? Colors.black.withOpacity(0.4)
                : const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assessment_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatMonth(summary.month),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(context,
                  icon: Icons.access_time_rounded,
                  label: 'Total Hours',
                  value: '${summary.totalHours}',
                  suffix: 'hrs',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(context,
                  icon: Icons.calendar_today,
                  label: 'Days Logged',
                  value: '${summary.daysLogged}',
                  suffix: 'days',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(context,
                  icon: Icons.trending_up,
                  label: 'Avg per Day',
                  value: '${summary.avgPerDay}',
                  suffix: 'hrs',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(context,
                  icon: Icons.attach_money,
                  label: 'Estimated',
                  value: '\$${summary.estimatedEarnings.toStringAsFixed(0)}',
                  suffix: '',
                ),
              ),
            ],
          ),
          
          // Progress bar (optional - showing percentage of expected hours)
          if (summary.daysLogged > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '${summary.daysLogged} / ${_getDaysInMonth()} days',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: summary.daysLogged / _getDaysInMonth(),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatMonth(String month) {
    try {
      final date = DateTime.parse('$month-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return month;
    }
  }

  int _getDaysInMonth() {
    try {
      final date = DateTime.parse('${summary.month}-01');
      return DateTime(date.year, date.month + 1, 0).day;
    } catch (e) {
      return 30;
    }
  }
}