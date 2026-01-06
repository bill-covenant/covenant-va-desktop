import 'package:flutter/material.dart';
import '../../../data/models/task_model.dart';
import '../../dashboard/widgets/task_filter.dart';
import 'tasks_list.dart';
import 'tasks_empty_state.dart';

class TasksContent extends StatelessWidget {
  final List<TaskModel> filteredTasks;
  final String statusFilter;
  final String priorityFilter;
  final String searchQuery;
  final Function(String) onStatusChanged;
  final Function(String) onPriorityChanged;
  final Function(String) onSearchChanged;
  final VoidCallback onTaskUpdated;
  final Future<void> Function() onRefresh;

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
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(48, 32, 48, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskFilterBar(
              statusFilter: statusFilter,
              priorityFilter: priorityFilter,
              searchQuery: searchQuery,
              onStatusChanged: onStatusChanged,
              onPriorityChanged: onPriorityChanged,
              onSearchChanged: onSearchChanged,
            ),
            const SizedBox(height: 20),
            _buildTaskCount(),
            const SizedBox(height: 20),
            _buildTasksList(),
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

  Widget _buildTasksList() {
    if (filteredTasks.isEmpty) {
      return TasksEmptyState(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
        priorityFilter: priorityFilter,
      );
    }

    return TasksList(
      tasks: filteredTasks,
      onTaskUpdated: onTaskUpdated,
    );
  }
}