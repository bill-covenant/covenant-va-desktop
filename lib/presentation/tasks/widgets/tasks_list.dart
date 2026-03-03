import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task_model.dart';
import '../../../core/di/service_locator.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/bloc/dashboard_event.dart';
import '../../dashboard/bloc/dashboard_state.dart';
import 'task_detail_modal.dart';

const _priorityOrder = ['URGENT', 'HIGH', 'MEDIUM', 'LOW'];

const _priorityConfig = {
  'URGENT': _PriorityStyle(
    label: 'Urgent',
    emoji: '🔴',
    color: Color(0xFFDC2626),
    gradientStart: Color(0xFFDC2626),
    gradientEnd: Color(0xFFEF4444),
    bgTint: Color(0xFFFEF2F2),
  ),
  'HIGH': _PriorityStyle(
    label: 'High',
    emoji: '🟠',
    color: Color(0xFFEA580C),
    gradientStart: Color(0xFFEA580C),
    gradientEnd: Color(0xFFF97316),
    bgTint: Color(0xFFFFF7ED),
  ),
  'MEDIUM': _PriorityStyle(
    label: 'Medium',
    emoji: '🟡',
    color: Color(0xFFD97706),
    gradientStart: Color(0xFFD97706),
    gradientEnd: Color(0xFFF59E0B),
    bgTint: Color(0xFFFFFBEB),
  ),
  'LOW': _PriorityStyle(
    label: 'Low',
    emoji: '🔵',
    color: Color(0xFF2563EB),
    gradientStart: Color(0xFF2563EB),
    gradientEnd: Color(0xFF3B82F6),
    bgTint: Color(0xFFEFF6FF),
  ),
};

class _PriorityStyle {
  final String label;
  final String emoji;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;
  final Color bgTint;

  const _PriorityStyle({
    required this.label,
    required this.emoji,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
    required this.bgTint,
  });
}

class TasksList extends StatelessWidget {
  final List<TaskModel> tasks;
  final VoidCallback onTaskUpdated;

  const TasksList({
    super.key,
    required this.tasks,
    required this.onTaskUpdated,
  });

  Map<String, List<TaskModel>> _groupByPriority() {
    final grouped = <String, List<TaskModel>>{};
    for (final p in _priorityOrder) {
      final t = tasks.where((t) => t.priority == p).toList();
      if (t.isNotEmpty) grouped[p] = t;
    }
    final known = _priorityOrder.toSet();
    final other = tasks.where((t) => !known.contains(t.priority)).toList();
    if (other.isNotEmpty) grouped['OTHER'] = other;
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByPriority();

    return BlocProvider(
      create: (context) => getIt<DashboardBloc>(),
      child: Column(
        children: groups.entries.map((entry) {
          final priority = entry.key;
          final tasks = entry.value;
          final style = _priorityConfig[priority] ??
              const _PriorityStyle(
                label: 'Other',
                emoji: '⚪',
                color: Color(0xFF6B7280),
                gradientStart: Color(0xFF6B7280),
                gradientEnd: Color(0xFF9CA3AF),
                bgTint: Color(0xFFF9FAFB),
              );

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _PriorityGroupTable(
              style: style,
              tasks: tasks,
              onTaskUpdated: onTaskUpdated,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PriorityGroupTable extends StatelessWidget {
  final _PriorityStyle style;
  final List<TaskModel> tasks;
  final VoidCallback onTaskUpdated;

  const _PriorityGroupTable({
    required this.style,
    required this.tasks,
    required this.onTaskUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: style.color.withOpacity(0.12),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.5),
            child: Column(
              children: [
                _buildPriorityBanner(),
                _buildColumnHeaders(),
                ...List.generate(tasks.length, (i) {
                  return _TaskRow(
                    task: tasks[i],
                    index: i + 1,
                    isLast: i == tasks.length - 1,
                    priorityColor: style.color,
                    bgTint: style.bgTint,
                    onStatusChanged: onTaskUpdated,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            style.gradientStart,
            style.gradientEnd,
            style.gradientEnd.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: Text(style.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Text(
                style.label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 1), blurRadius: 3)],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: style.color.withOpacity(0.08), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(width: 48, child: _ColHeader(label: '#', color: style.color)),
          Expanded(flex: 3, child: _ColHeader(label: 'Task', color: style.color)),
          Expanded(flex: 2, child: _ColHeader(label: 'Status', color: style.color)),
          Expanded(flex: 3, child: _ColHeader(label: 'Due Date', color: style.color)),
          SizedBox(width: 64, child: _ColHeader(label: 'View', color: style.color, center: true)),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final Color color;
  final bool center;

  const _ColHeader({required this.label, required this.color, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(color: color.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
    );
  }
}

class _TaskRow extends StatefulWidget {
  final TaskModel task;
  final int index;
  final bool isLast;
  final Color priorityColor;
  final Color bgTint;
  final VoidCallback onStatusChanged;

  const _TaskRow({
    required this.task,
    required this.index,
    required this.isLast,
    required this.priorityColor,
    required this.bgTint,
    required this.onStatusChanged,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> with SingleTickerProviderStateMixin {
  String? _optimisticStatus;
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _elevationAnim;

  String get _displayStatus => _optimisticStatus ?? widget.task.status;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _elevationAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color _rowBgColor() {
    return Colors.white;
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
        onEnter: (_) { setState(() => _isHovered = true); _hoverController.forward(); },
        onExit: (_) { setState(() => _isHovered = false); _hoverController.reverse(); },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showTaskDetails(context),
          child: AnimatedBuilder(
            animation: _elevationAnim,
            builder: (context, _) {
              return Container(
                color: _rowBgColor(),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          // Priority accent bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isHovered ? 5 : 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  widget.priorityColor.withOpacity(_isHovered ? 1.0 : 0.7),
                                  widget.priorityColor.withOpacity(_isHovered ? 0.7 : 0.3),
                                ],
                              ),
                              boxShadow: _isHovered
                                  ? [BoxShadow(color: widget.priorityColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(2, 0))]
                                  : [],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  // # Column
                                  SizedBox(
                                    width: 48,
                                    child: Container(
                                      width: 28, height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _isHovered ? widget.priorityColor.withOpacity(0.1) : widget.priorityColor.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(color: _isHovered ? widget.priorityColor.withOpacity(0.2) : widget.priorityColor.withOpacity(0.08)),
                                      ),
                                      child: Text(
                                        '${widget.index}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _isHovered ? widget.priorityColor : widget.priorityColor.withOpacity(0.5)),
                                      ),
                                    ),
                                  ),
                                  // Task Name
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        widget.task.title,
                                        style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827), letterSpacing: -0.2,
                                          shadows: [Shadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 1), blurRadius: 1)],
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Status Dropdown
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                                            colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.06)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _displayStatus,
                                          underline: const SizedBox(),
                                          isDense: true,
                                          dropdownColor: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 20),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
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
                                  // Due Date
                                  Expanded(
                                    flex: 3,
                                    child: widget.task.dueDate != null
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: isOverdue ? const Color(0xFFDC2626).withOpacity(0.08) : widget.priorityColor.withOpacity(0.06),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(Icons.calendar_today, size: 13, color: isOverdue ? const Color(0xFFDC2626) : Colors.grey[500]),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat('MMM dd, yyyy').format(widget.task.dueDate!),
                                                style: TextStyle(fontSize: 13, fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w600, color: isOverdue ? const Color(0xFFDC2626) : Colors.grey[600]),
                                              ),
                                              if (isOverdue) ...[
                                                const SizedBox(width: 10),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                                                    borderRadius: BorderRadius.circular(7),
                                                    boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                                                  ),
                                                  child: const Text('OVERDUE', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                                                ),
                                              ],
                                            ],
                                          )
                                        : Text('No date', style: TextStyle(fontSize: 13, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                                  ),
                                  // View Button
                                  SizedBox(
                                    width: 64,
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () => _showTaskDetails(context),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                                              colors: _isHovered
                                                  ? [widget.priorityColor.withOpacity(0.15), widget.priorityColor.withOpacity(0.05)]
                                                  : [widget.priorityColor.withOpacity(0.05), widget.priorityColor.withOpacity(0.02)],
                                            ),
                                            borderRadius: BorderRadius.circular(11),
                                            border: Border.all(
                                              color: _isHovered ? widget.priorityColor.withOpacity(0.25) : widget.priorityColor.withOpacity(0.1),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(Icons.visibility_outlined, size: 17, color: _isHovered ? widget.priorityColor : widget.priorityColor.withOpacity(0.4)),
                                        ),
                                      ),
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
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: widget.priorityColor.withOpacity(0.06),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(context: context, builder: (context) => TaskDetailModal(task: widget.task));
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