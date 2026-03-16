import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/time_entry.dart';
import '../bloc/dashboard_state.dart';

// ============================================
// TODAY'S SUMMARY CARD
// ============================================

class TodaySummaryCard extends StatelessWidget {
  final DashboardLoaded state;

  const TodaySummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hrs = state.todayHoursWorked;
    final wholeHrs = hrs.floor();
    final mins = ((hrs - wholeHrs) * 60).round();
    final timeStr = wholeHrs > 0 ? '${wholeHrs}h ${mins}m' : mins > 0 ? '${mins}m' : '0h';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(20),
        border: _isDark() ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: _isDark()
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    BoxShadow(color: const Color(0xFF047857).withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: Icon(Icons.today_rounded, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 12),
              Text("Today's Summary", style: TextStyle(color: _textPrimary(), fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _SummaryItem(icon: Icons.access_time_filled_rounded, label: 'Hours Worked', value: timeStr, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _SummaryItem(icon: Icons.task_alt_rounded, label: 'Tasks Due', value: state.todayTasks.length.toString(), color: const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _SummaryItem(icon: Icons.description_rounded, label: 'Time Entries', value: state.todayEntriesCount.toString(), color: const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(icon, color: color, size: 16)),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: _textPrimary(), fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: _textSecondary(), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// UPCOMING TASKS CARD
// ============================================

class UpcomingTasksCard extends StatelessWidget {
  final List<TaskModel> tasks;

  const UpcomingTasksCard({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(20),
        border: _isDark() ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: _isDark()
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    BoxShadow(color: const Color(0xFFB45309).withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: Icon(Icons.upcoming_rounded, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 12),
              Text('Upcoming Tasks', style: TextStyle(color: _textPrimary(), fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${tasks.length}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF10B981).withOpacity(0.4), size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text("You're all caught up!", style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )
          else
            ...tasks.map((task) => _TaskItem(task: task)),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final TaskModel task;

  const _TaskItem({required this.task});

  bool get _isOverdue {
    if (task.dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = task.dueDate!.toLocal();
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDate.isBefore(today);
  }

  String _formatDueDate() {
    if (task.dueDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = task.dueDate!.toLocal();
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = taskDate.difference(today).inDays;
    if (diff < 0) return '${-diff}d overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  Color get _priorityColor {
    switch (task.priority) {
      case 'URGENT': return const Color(0xFFEF4444);
      case 'HIGH': return const Color(0xFFF59E0B);
      case 'MEDIUM': return const Color(0xFF3B82F6);
      default: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = _isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverdue
            ? (_isDark() ? const Color(0xFF3B1515) : const Color(0xFFFEF2F2))
            : _surfaceBg(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? (_isDark() ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA))
              : _borderColor(),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _priorityColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _priorityColor.withOpacity(0.3), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(color: _textPrimary(), fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOverdue ? const Color(0xFFEF4444).withOpacity(0.08) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatDueDate(),
              style: TextStyle(
                color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// RECENT ACTIVITY CARD
// ============================================

class RecentActivityCard extends StatelessWidget {
  final List<TimeEntry> recentEntries;
  final List<TaskModel> todayTasks;

  const RecentActivityCard({
    super.key,
    required this.recentEntries,
    required this.todayTasks,
  });

  @override
  Widget build(BuildContext context) {
    final activities = <_ActivityData>[];

    for (final entry in recentEntries) {
      activities.add(_ActivityData(
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFF3B82F6),
        title: 'Logged ${_formatHours(entry.hoursWorked)}',
        subtitle: entry.description ?? 'Time entry',
        time: _formatDate(entry.date),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(20),
        border: _isDark() ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: _isDark()
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    BoxShadow(color: const Color(0xFF4C1D95).withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: Icon(Icons.history_rounded, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 12),
              Text('Recent Activity', style: TextStyle(color: _textPrimary(), fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.inbox_rounded, color: const Color(0xFF8B5CF6).withOpacity(0.3), size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text('No recent activity', style: TextStyle(color: const Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )
          else
            ...activities.map((a) => _buildActivityRow(a)),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = date.toLocal();
    final dateDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dateDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return '${d.month}/${d.day}';
  }

  Widget _buildActivityRow(_ActivityData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceBg(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor()),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: item.color.withOpacity(_isDark() ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Icon(item.icon, color: item.color, size: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: TextStyle(color: _textPrimary(), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(item.subtitle, style: TextStyle(color: _textTertiary(), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(item.time, style: TextStyle(color: _textTertiary(), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActivityData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  _ActivityData({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});
}

// Dark mode helpers for dashboard widgets
bool _isDark() => ThemeProvider().isDarkMode;
Color _cardBg() => _isDark() ? const Color(0xFF1A1D2E) : Colors.white;
Color _textPrimary() => _isDark() ? Colors.white : const Color(0xFF1F2937);
Color _textSecondary() => _isDark() ? Colors.white70 : const Color(0xFF6B7280);
Color _textTertiary() => _isDark() ? Colors.white54 : const Color(0xFF9CA3AF);
Color _surfaceBg() => _isDark() ? const Color(0xFF232738) : const Color(0xFFF9FAFB);
Color _borderColor() => _isDark() ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB);