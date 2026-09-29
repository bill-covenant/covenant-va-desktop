import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../data/models/task_model.dart';
import '../../dashboard/widgets/task_filter.dart';
import 'tasks_list.dart';
import 'tasks_empty_state.dart';

class TasksContent extends StatefulWidget {
  final List<TaskModel> filteredTasks;
  final String statusFilter;
  final String priorityFilter;
  final String searchQuery;
  final Function(String) onStatusChanged;
  final Function(String) onPriorityChanged;
  final Function(String) onSearchChanged;
  final VoidCallback onTaskUpdated;
  final Future<void> Function() onRefresh;
  final void Function(TaskModel task)? onArchiveTask;

  const TasksContent({
    super.key,
    required this.filteredTasks,
    required this.statusFilter,
    required this.priorityFilter,
    required this.searchQuery,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSearchChanged,
    required this.onTaskUpdated,
    required this.onRefresh,
    this.onArchiveTask,
  });

  @override
  State<TasksContent> createState() => _TasksContentState();
}

class _TasksContentState extends State<TasksContent> {
  // Grouped once per new task list (not on every build) so TasksList can
  // memoize its sorting by list identity.
  late List<TaskModel> _ongoingTasks;
  late List<TaskModel> _deadlineTasks;

  List<TaskModel> get filteredTasks => widget.filteredTasks;
  String get statusFilter => widget.statusFilter;
  String get priorityFilter => widget.priorityFilter;
  String get searchQuery => widget.searchQuery;

  @override
  void initState() {
    super.initState();
    _groupTasks();
  }

  @override
  void didUpdateWidget(TasksContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.filteredTasks, widget.filteredTasks)) {
      _groupTasks();
    }
  }

  void _groupTasks() {
    _ongoingTasks = filteredTasks.where((t) => t.dueDate == null).toList();
    _deadlineTasks = filteredTasks.where((t) => t.dueDate != null).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(48, 32, 48, 40),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TaskFilterBar(
                          statusFilter: statusFilter,
                          priorityFilter: priorityFilter,
                          searchQuery: searchQuery,
                          onStatusChanged: widget.onStatusChanged,
                          onPriorityChanged: widget.onPriorityChanged,
                          onSearchChanged: widget.onSearchChanged,
                        ),
                        const SizedBox(height: 20),
                        _buildTaskCount(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ..._buildTasksList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCount() {
    return Text(
      '${filteredTasks.length} ${filteredTasks.length == 1 ? 'task' : 'tasks'}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Returns slivers.
  List<Widget> _buildTasksList() {
    if (filteredTasks.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: TasksEmptyState(
            searchQuery: searchQuery,
            statusFilter: statusFilter,
            priorityFilter: priorityFilter,
          ),
        ),
      ];
    }

    final ongoingTasks = _ongoingTasks;
    final deadlineTasks = _deadlineTasks;

    return [
      // On-going Tasks
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSectionHeader(
            icon: Icons.access_time_rounded,
            title: 'On-going Tasks',
            subtitle: 'Tasks without a deadline',
            count: ongoingTasks.length,
            color: const Color(0xFF7C3AED),
          ),
        ),
      ),
      if (ongoingTasks.isEmpty)
        SliverToBoxAdapter(child: _buildEmptySection('No on-going tasks'))
      else
        TasksList(
          key: const ValueKey('ongoing-tasks'),
          tasks: ongoingTasks,
          onTaskUpdated: widget.onTaskUpdated,
          onArchiveTask: widget.onArchiveTask,
        ),

      // Deadline Tasks
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 12),
          child: _buildSectionHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Deadline Tasks',
            subtitle: 'Tasks with a due date',
            count: deadlineTasks.length,
            color: const Color(0xFFF97316),
          ),
        ),
      ),
      if (deadlineTasks.isEmpty)
        SliverToBoxAdapter(child: _buildEmptySection('No deadline tasks'))
      else
        TasksList(
          key: const ValueKey('deadline-tasks'),
          tasks: deadlineTasks,
          onTaskUpdated: widget.onTaskUpdated,
          onArchiveTask: widget.onArchiveTask,
        ),
    ];
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}