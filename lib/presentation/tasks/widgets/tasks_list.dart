import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/task_model.dart';
import '../../../core/di/service_locator.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/bloc/dashboard_event.dart';
import '../../dashboard/bloc/dashboard_state.dart';
import 'task_detail_modal.dart';

const _priorityOrder = ['URGENT', 'HIGH', 'MEDIUM', 'LOW'];

class TasksList extends StatelessWidget {
  final List<TaskModel> tasks;
  final VoidCallback onTaskUpdated;
  final void Function(TaskModel task)? onArchiveTask;

  const TasksList({
    super.key,
    required this.tasks,
    required this.onTaskUpdated,
    this.onArchiveTask,
  });

  List<TaskModel> get _sortedTasks {
    final sorted = List<TaskModel>.from(tasks);
    sorted.sort((a, b) {
      final ai = _priorityOrder.indexOf(a.priority);
      final bi = _priorityOrder.indexOf(b.priority);
      final pa = ai == -1 ? 99 : ai;
      final pb = bi == -1 ? 99 : bi;
      if (pa != pb) return pa.compareTo(pb);
      if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return a.title.compareTo(b.title);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedTasks;

    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        return BlocProvider(
          create: (context) => getIt<DashboardBloc>(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark
                  ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
                  : [
                      BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -8),
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                      BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 1, offset: const Offset(0, -1)),
                    ],
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _buildHeader(sorted.length),
                  _buildColumnHeaders(),
                  ...List.generate(sorted.length, (i) {
                    return _TaskRow(
                      task: sorted[i],
                      index: i + 1,
                      isLast: i == sorted.length - 1,
                      onStatusChanged: onTaskUpdated,
                      onArchive: onArchiveTask != null ? () => onArchiveTask!(sorted[i]) : null,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    final isDark = ThemeProvider().isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [const Color(0xFF1E1535), const Color(0xFF1A1230)]
              : [const Color(0xFF7C3AED), const Color(0xFF6366F1)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(isDark ? 0.1 : 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.08)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Tasks',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sorted by priority',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  '$count ${count == 1 ? 'task' : 'tasks'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ThemeProvider().isDarkMode
              ? [const Color(0xFF232738), const Color(0xFF1A1D2E)]
              : [const Color(0xFFFAF5FF), Colors.white.withOpacity(0.9)],
        ),
        border: Border(bottom: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.06))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 1, child: _ColHeader(label: '#', center: true)),
          Expanded(flex: 3, child: _ColHeader(label: 'TASK')),
          Expanded(flex: 2, child: _ColHeader(label: 'PRIORITY', center: true)),
          Expanded(flex: 2, child: _ColHeader(label: 'STATUS', center: true)),
          Expanded(flex: 2, child: _ColHeader(label: 'DUE DATE', center: true)),
          Expanded(flex: 1, child: _ColHeader(label: 'VIEW', center: true)),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final bool center;

  const _ColHeader({required this.label, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        color: const Color(0xFF7C3AED).withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Task Row
// ═══════════════════════════════════════════

class _TaskRow extends StatefulWidget {
  final TaskModel task;
  final int index;
  final bool isLast;
  final VoidCallback onStatusChanged;
  final VoidCallback? onArchive;

  const _TaskRow({
    required this.task,
    required this.index,
    required this.isLast,
    required this.onStatusChanged,
    this.onArchive,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  String? _optimisticStatus;
  bool _isHovered = false;

  String get _displayStatus => _optimisticStatus ?? widget.task.status;

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 'URGENT': return const Color(0xFFDC2626);
      case 'HIGH': return const Color(0xFFEA580C);
      case 'MEDIUM': return const Color(0xFFD97706);
      case 'LOW': return const Color(0xFF2563EB);
      default: return const Color(0xFF6B7280);
    }
  }

  String get _priorityLabel {
    switch (widget.task.priority) {
      case 'URGENT': return 'Urgent';
      case 'HIGH': return 'High';
      case 'MEDIUM': return 'Medium';
      case 'LOW': return 'Low';
      default: return widget.task.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_displayStatus);
    final isOverdue = widget.task.isOverdue;

    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardLoaded && mounted) {
          setState(() => _optimisticStatus = null);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => TaskDetailModal(task: widget.task)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (ThemeProvider().isDarkMode ? const Color(0xFF232738) : const Color(0xFFFAF5FF))
                  : (ThemeProvider().isDarkMode ? const Color(0xFF1A1D2E) : Colors.white),
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // Priority accent bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isHovered ? 4 : 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _priorityColor.withOpacity(_isHovered ? 1.0 : 0.6),
                              _priorityColor.withOpacity(_isHovered ? 0.6 : 0.15),
                            ],
                          ),
                          boxShadow: _isHovered
                              ? [BoxShadow(color: _priorityColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(2, 0))]
                              : [],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                            children: [
                              // # badge — centered
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Container(
                                    width: 34, height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _isHovered ? _priorityColor.withOpacity(0.1) : (ThemeProvider().isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${widget.index}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _isHovered ? _priorityColor : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Task title + description — left aligned
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.task.title,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF111827), letterSpacing: -0.2),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.task.description!,
                                        style: TextStyle(fontSize: 13, color: ThemeProvider().isDarkMode ? Colors.white54 : Colors.grey[400]),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Priority badge — centered, fixed width
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    width: 110,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [_priorityColor.withOpacity(0.12), _priorityColor.withOpacity(0.04)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _priorityColor.withOpacity(0.15)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: _priorityColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: _priorityColor.withOpacity(0.4), blurRadius: 3)],
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          _priorityLabel,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _priorityColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Status dropdown — centered
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [statusColor.withOpacity(0.12), statusColor.withOpacity(0.04)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _displayStatus,
                                      underline: const SizedBox(),
                                      isDense: true,
                                      dropdownColor: ThemeProvider().isDarkMode ? const Color(0xFF1A1D2E) : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 20),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
                                      items: const [
                                        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                                        DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                                        DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                                      ],
                                      onChanged: (String? newStatus) {
                                        if (newStatus != null && newStatus != widget.task.status) {
                                          setState(() => _optimisticStatus = newStatus);
                                          context.read<DashboardBloc>().add(TaskStatusUpdated(taskId: widget.task.id, newStatus: newStatus));
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              // Due Date — centered
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: widget.task.dueDate != null
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isOverdue
                                                    ? (ThemeProvider().isDarkMode ? const Color(0xFF3B1515) : const Color(0xFFFEE2E2))
                                                    : (ThemeProvider().isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6)),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: Icon(Icons.calendar_today, size: 14, color: isOverdue ? const Color(0xFFDC2626) : (ThemeProvider().isDarkMode ? Colors.white70 : Colors.grey[500])),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(widget.task.dueDate!),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600,
                                                color: isOverdue ? const Color(0xFFDC2626) : (ThemeProvider().isDarkMode ? Colors.white70 : Colors.grey[600]),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (isOverdue) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                                                ),
                                                child: const Text('LATE', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                              ),
                                            ],
                                          ],
                                        )
                                      : Text('No date', style: TextStyle(fontSize: 14, color: ThemeProvider().isDarkMode ? Colors.white54 : Colors.grey[400], fontStyle: FontStyle.italic)),
                                ),
                              ),
                              // Archive + View buttons — centered
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.task.isCompleted && widget.onArchive != null)
                                      Tooltip(
                                        message: 'Archive task',
                                        child: GestureDetector(
                                          onTap: () {},
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: widget.onArchive,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _isHovered
                                                    ? const Color(0xFF6366F1).withOpacity(0.12)
                                                    : const Color(0xFF6366F1).withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.12)),
                                              ),
                                              child: Icon(
                                                Icons.archive_outlined,
                                                size: 16,
                                                color: const Color(0xFF6366F1).withOpacity(_isHovered ? 0.8 : 0.4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (widget.task.isCompleted && widget.onArchive != null)
                                      const SizedBox(width: 8),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: _isHovered
                                            ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)])
                                            : LinearGradient(colors: [const Color(0xFF7C3AED).withOpacity(0.08), const Color(0xFF6366F1).withOpacity(0.04)]),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(_isHovered ? 0.3 : 0.1)),
                                        boxShadow: _isHovered
                                            ? [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                            : [],
                                      ),
                                      child: Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                        color: _isHovered ? Colors.white : const Color(0xFF7C3AED).withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isLast)
                  Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.06)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return const Color(0xFF10B981);
      case 'IN_PROGRESS': return const Color(0xFF8B5CF6);
      case 'PENDING': return const Color(0xFFF59E0B);
      default: return const Color(0xFF6B7280);
    }
  }
}
