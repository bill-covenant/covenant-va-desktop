import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/task_model.dart';
import 'announcements_section.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'clients_preview.dart';
import 'dashboard_widgets.dart';
import 'greeting_header.dart';
import 'live_timer_card.dart';

class DashboardContent extends StatelessWidget {
  final DashboardLoaded? cachedState;

  const DashboardContent({
    super.key,
    this.cachedState,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final displayState = (cachedState != null && state is DashboardLoading)
            ? cachedState!
            : state;

        if (displayState is DashboardLoading) {
          return const SizedBox();
        }

        if (displayState is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(displayState.message, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<DashboardBloc>().add(const DashboardRefreshRequested()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (displayState is DashboardLoaded) {
          return _buildDashboard(context, displayState);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardLoaded state) {
    return Column(
      children: [
        const GreetingHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(const DashboardRefreshRequested());
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnnouncementsSection(),
                  _buildTopRow(state),
                  const SizedBox(height: 24),
                  _buildBottomRow(state),
                ],
              ),
            )),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // TOP ROW: Stats + Clients + Timer
  // ═══════════════════════════════════════

  Widget _buildTopRow(DashboardLoaded state) {
    return SizedBox(
      height: 210,
      child: Row(
        children: [
          Expanded(flex: 4, child: _buildStatsCard(state)),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _buildClientsPreviewCard()),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _buildTimerCard(state)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(DashboardLoaded state) {
    final total = state.stats.total;
    final completed = state.stats.completed;
    final inProgress = state.stats.inProgress;
    final completedPct = total > 0 ? completed / total : 0.0;
    final inProgressPct = total > 0 ? inProgress / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildCircularStat(
            value: completed, label: 'Completed', percentage: completedPct,
            color: const Color(0xFF8B5CF6), bgColor: const Color(0xFFF3E8FF),
          ),
          const SizedBox(width: 24),
          _buildCircularStat(
            value: inProgress, label: 'In Progress', percentage: inProgressPct,
            color: const Color(0xFF3B82F6), bgColor: const Color(0xFFDBEAFE),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: List.generate(
                  total.clamp(0, 5),
                  (i) => Container(
                    width: 12, height: 12,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 4)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('$total', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _textPrimary())),
              Text('Total Tasks', style: TextStyle(fontSize: 12, color: _textSecondary(), fontWeight: FontWeight.w600)),
              if (state.stats.pending > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: Text('${state.stats.pending} pending', style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularStat({
    required int value, required String label, required double percentage,
    required Color color, required Color bgColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 90, height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90, height: 90,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: _isDark() ? bgColor.withOpacity(0.2) : bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: _textSecondary(), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildClientsPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const CompactClientsPreview(),
    );
  }

  Widget _buildTimerCard(DashboardLoaded state) {
    return LiveTimerCard(
      activeClockIn: state.activeClockIn,
      todayHoursWorked: state.todayHoursWorked,
      todayEntriesCount: state.todayEntriesCount,
      todayTasksCount: state.todayTasks.length,
    );
  }

  // ═══════════════════════════════════════
  // BOTTOM ROW: Tasks + Calendar/Activity
  // ═══════════════════════════════════════

  Widget _buildBottomRow(DashboardLoaded state) {
    // Show all tasks sorted: non-completed first, then by priority
    final priorityOrder = ['URGENT', 'HIGH', 'MEDIUM', 'LOW'];
    final sorted = List<TaskModel>.from(state.allTasks);
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final ai = priorityOrder.indexOf(a.priority);
      final bi = priorityOrder.indexOf(b.priority);
      return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
    });

    return Column(
      children: [
        // Row 1: Calendar + Recent Activity side by side (matched height)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCalendarCard()),
              const SizedBox(width: 20),
              Expanded(child: RecentActivityCard(recentEntries: state.recentEntries, todayTasks: state.todayTasks)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Row 2: Recent Tasks full width
        _buildRecentTasksSection(sorted),
        if (false) ...[
          // Recent Activity moved to row 1
        ],
      ],
    );
  }

  Widget _buildRecentTasksSection(List<TaskModel> tasks) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.task_alt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Recent Tasks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: DashboardContent._textPrimary())),
              const Spacer(),
              const Text('View all', style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: DashboardContent._textTertiary()),
                    const SizedBox(height: 12),
                    Text("No tasks assigned yet", style: TextStyle(color: DashboardContent._textTertiary(), fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 800 ? 3 : 2;
                final cardWidth = (constraints.maxWidth - (16.0 * (cols - 1))) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: tasks.take(6).map((task) => SizedBox(
                    width: cardWidth,
                    child: _buildTaskCard(task, fullWidth: true),
                  )).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, {bool fullWidth = false}) {
    final pColor = _getPriorityColor(task.priority);
    final statusLabel = task.isCompleted ? 'Completed' : task.isInProgress ? 'In Progress' : 'Pending';
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted;
    final progress = task.isCompleted ? 1.0 : task.isInProgress ? 0.5 : 0.1;

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _isDark() ? Colors.white.withOpacity(0.08) : pColor.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(color: pColor.withOpacity(_isDark() ? 0.15 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(_isDark() ? 0.2 : 0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? const Color(0xFFEF4444)
                        : _getStatusColor(task.status).withOpacity(0.1),
                    gradient: isOverdue ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]) : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOverdue ? 'Overdue' : statusLabel,
                    style: TextStyle(
                      color: isOverdue ? Colors.white : _getStatusColor(task.status),
                      fontSize: 9, fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: pColor, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: pColor.withOpacity(0.4), blurRadius: 4)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _textPrimary()), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description!, style: TextStyle(fontSize: 11, color: _textSecondary()), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            if (task.dueDate != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: DashboardContent._textTertiary()),
                  const SizedBox(width: 4),
                  Text(_formatDate(task.dueDate!), style: TextStyle(fontSize: 11, color: DashboardContent._textSecondary(), fontWeight: FontWeight.w500)),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: pColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(pColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 11, color: DashboardContent._textSecondary(), fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
    );
  }

  // ═══════════════════════════════════════
  // CALENDAR
  // ═══════════════════════════════════════

  Widget _buildCalendarCard() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${months[now.month - 1]} ${now.year}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary())),
              Row(
                children: [
                  Icon(Icons.chevron_left, size: 20, color: _textTertiary()),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: _textTertiary()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => SizedBox(width: 32, child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: _textTertiary(), fontWeight: FontWeight.w700)))))
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(6, (week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (wd) {
                  final dayNum = week * 7 + wd - startWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(width: 32, height: 32);
                  final isToday = dayNum == now.day;
                  return Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: isToday ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]) : null,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isToday ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: isToday ? Colors.white : _textPrimary()),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════

  static bool _isDark() => ThemeProvider().isDarkMode;
  static Color _cardBg() => _isDark() ? const Color(0xFF1A1D2E) : Colors.white;
  static Color _textPrimary() => _isDark() ? Colors.white : const Color(0xFF1F2937);
  static Color _textSecondary() => _isDark() ? Colors.white70 : const Color(0xFF6B7280);
  static Color _textTertiary() => _isDark() ? Colors.white54 : const Color(0xFF9CA3AF);

  BoxDecoration _cardDecoration() => DashboardContent._cardDecorationStatic();


  static BoxDecoration _cardDecorationStatic() {
    final dark = ThemeProvider().isDarkMode;
    final cardBg = dark ? const Color(0xFF1A1D2E) : Colors.white;
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(24),
      border: dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
      boxShadow: dark
          ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
          : [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
            ],
    );
  }


  Widget _buildPillBadge(String text, Color bg, Color fg) => DashboardContent._buildPillBadgeStatic(text, bg, fg);

  static Widget _buildPillBadgeStatic(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT': return const Color(0xFFDC2626);
      case 'HIGH': return const Color(0xFFEF4444);
      case 'MEDIUM': return const Color(0xFFF59E0B);
      case 'LOW': return const Color(0xFF3B82F6);
      default: return const Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return const Color(0xFF10B981);
      case 'IN_PROGRESS': return const Color(0xFF8B5CF6);
      case 'PENDING': return const Color(0xFFF59E0B);
      default: return const Color(0xFF6B7280);
    }
  }

  // ═══════════════════════════════════════
  // LOADING SKELETONS
  // ═══════════════════════════════════════

  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 12),
          child: Container(width: 200, height: 32, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8))),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Column(
              children: [
                SizedBox(
                  height: 210,
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: _buildSkeletonBox()),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _buildSkeletonBox()),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _buildSkeletonBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildSkeletonBox(height: 300)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildSkeletonBox(height: 300)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBox({double? height}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05 * value),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1 * value)),
          ),
        );
      },
    );
  }
}
