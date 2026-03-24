import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../data/providers/api_provider.dart';
import 'announcements_section.dart';
import '../../../core/di/service_locator.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'dashboard_widgets.dart';

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
        _buildGreetingHeader(),
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
  // HEADER
  // ═══════════════════════════════════════

  Widget _buildGreetingHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 12),
      child: Row(
        children: [
          FutureBuilder<String>(
            future: _getVAName(),
            builder: (context, snapshot) {
              final name = snapshot.data ?? 'there';
              final firstName = name.split(' ').first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $firstName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getGreetingSubtitle(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          // Profile avatar
          FutureBuilder<String>(
            future: _getVAName(),
            builder: (context, snapshot) {
              final name = snapshot.data ?? 'VA';
              final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
              return Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              );
            },
          ),
        ],
      ),
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
      child: _CompactClientsPreview(),
    );
  }

  Widget _buildTimerCard(DashboardLoaded state) {
    return _LiveTimerCard(
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

  String _getGreetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! Ready to be productive?';
    if (hour < 17) return 'Good afternoon! Keep up the great work.';
    return 'Good evening! Wrapping up for the day?';
  }

  Future<String> _getVAName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        final data = Map<String, dynamic>.from(
          const JsonCodec().decode(userJson) as Map,
        );
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        if (firstName.isNotEmpty) return '$firstName $lastName'.trim();
      }
      return 'there';
    } catch (_) {
      return 'there';
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

// ═══════════════════════════════════════════════
// Compact Clients Preview (fits in 210px card)
// ═══════════════════════════════════════════���═══

// ═════════════════════════════════════════��═════
// Messages Preview (recent conversations)
// ══���════════════════════════════════════════════

class _MessagesPreview extends StatefulWidget {
  const _MessagesPreview();

  @override
  State<_MessagesPreview> createState() => _MessagesPreviewState();
}

class _MessagesPreviewState extends State<_MessagesPreview> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  static List<dynamic>? _cached;

  @override
  void initState() {
    super.initState();
    if (_cached != null) {
      _conversations = _cached!;
      _isLoading = false;
    }
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final apiProvider = getIt<ApiProvider>();
      final repo = MessageRepository(apiProvider: apiProvider);
      final convos = await repo.getConversations();
      print('📬 Dashboard: Loaded ${convos.length} conversations');
      if (mounted) {
        _cached = convos;
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('📬 Dashboard: Failed to load conversations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  static const _avatarColors = [
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  ];

  @override
  Widget build(BuildContext context) {
    final dark = DashboardContent._isDark();
    final cardBg = DashboardContent._cardBg();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: dark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DashboardContent._textPrimary())),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/messages'),
                child: const Text('View all', style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else if (_conversations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 32, color: DashboardContent._textTertiary()),
                    const SizedBox(height: 8),
                    Text('No messages yet', style: TextStyle(color: DashboardContent._textTertiary(), fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...(_conversations.take(3).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final convo = entry.value;
              final clientName = (convo as dynamic).client != null
                  ? '${convo.client.firstName} ${convo.client.lastName}'
                  : 'Client';
              final initials = clientName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
              final colors = _avatarColors[i % _avatarColors.length];
              final lastMsg = (convo as dynamic).lastMessage ?? '';
              final lastTime = (convo as dynamic).lastMessageAt as DateTime?;

              return Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clientName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DashboardContent._textPrimary())),
                          const SizedBox(height: 2),
                          Text(
                            lastMsg.isNotEmpty ? lastMsg : 'No messages',
                            style: TextStyle(fontSize: 11, color: DashboardContent._textSecondary()),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (lastTime != null)
                      Text(_formatTime(lastTime), style: TextStyle(fontSize: 10, color: DashboardContent._textTertiary(), fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }
}

class _CompactClientsPreview extends StatefulWidget {
  const _CompactClientsPreview();

  @override
  State<_CompactClientsPreview> createState() => _CompactClientsPreviewState();
}

class _CompactClientsPreviewState extends State<_CompactClientsPreview> {
  List<dynamic> _clients = [];
  bool _isLoading = true;

  static List<dynamic>? _cached;

  static const _avatarColors = [
    [Color(0xFF7C3AED), Color(0xFF9333EA)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
  ];

  @override
  void initState() {
    super.initState();
    if (_cached != null) {
      _clients = _cached!;
      _isLoading = false;
    }
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final repo = getIt<ClientRepository>();
      final clients = await repo.getAssignedClients();
      if (mounted) {
        _cached = clients;
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('My Clients', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DashboardContent._textPrimary())),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_clients.length} ${_clients.length == 1 ? 'Client' : 'Clients'}',
                style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Client avatars row
        if (_isLoading)
          const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
        else if (_clients.isEmpty)
          Center(
            child: Text('No clients yet', style: TextStyle(color: DashboardContent._textTertiary(), fontSize: 12)),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _clients.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final client = entry.value;
              final firstName = (client as dynamic).firstName ?? '';
              final lastName = (client as dynamic).lastName ?? '';
              final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
              final colors = _avatarColors[i % _avatarColors.length];

              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: Column(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Center(
                        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 52,
                      child: Text(
                        firstName,
                        style: TextStyle(fontSize: 10, color: DashboardContent._textSecondary(), fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const Spacer(),
      ],
    );
  }
}

// ═══════════════════════════════════════
// LIVE TIMER CARD — ticks every second when clocked in
// ═══════════════════════════════════════
class _LiveTimerCard extends StatefulWidget {
  final DateTime? activeClockIn;
  final double todayHoursWorked;
  final int todayEntriesCount;
  final int todayTasksCount;

  const _LiveTimerCard({
    required this.activeClockIn,
    required this.todayHoursWorked,
    required this.todayEntriesCount,
    required this.todayTasksCount,
  });

  @override
  State<_LiveTimerCard> createState() => _LiveTimerCardState();
}

class _LiveTimerCardState extends State<_LiveTimerCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LiveTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeClockIn != oldWidget.activeClockIn) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.activeClockIn != null) {
      _updateElapsed();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
    } else {
      _elapsed = Duration.zero;
    }
  }

  void _updateElapsed() {
    if (widget.activeClockIn != null && mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.activeClockIn!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatStaticHours(double hrs) {
    final h = hrs.floor();
    final m = ((hrs - h) * 60).floor();
    final s = (((hrs - h) * 60 - m) * 60).floor();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    final isLive = widget.activeClockIn != null;
    final timeStr = isLive ? _formatDuration(_elapsed) : _formatStaticHours(widget.todayHoursWorked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: DashboardContent._cardDecorationStatic(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isLive
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [BoxShadow(
                    color: (isLive ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)).withOpacity(0.3),
                    blurRadius: 6, offset: const Offset(0, 2),
                  )],
                ),
                child: Icon(isLive ? Icons.play_arrow_rounded : Icons.timer, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                isLive ? 'Live' : 'Timer',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: isLive ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.6), blurRadius: 6)],
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w900,
              color: isLive ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLive ? 'Currently clocked in' : 'Hours worked today',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DashboardContent._buildPillBadgeStatic('${widget.todayEntriesCount} entries', const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              DashboardContent._buildPillBadgeStatic('${widget.todayTasksCount} tasks', const Color(0xFFDBEAFE), const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }
}