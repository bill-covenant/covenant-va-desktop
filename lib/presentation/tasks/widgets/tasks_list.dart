import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/task_model.dart';
import '../../../core/di/service_locator.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/widgets/task_card.dart';

class TasksList extends StatelessWidget {
  final List<TaskModel> tasks;
  final VoidCallback onTaskUpdated;

  const TasksList({
    super.key,
    required this.tasks,
    required this.onTaskUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DashboardBloc>(),
      child: Column(
        children: tasks
            .map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TaskCard(
                    task: task,
                    onStatusChanged: onTaskUpdated,
                  ),
                ))
            .toList(),
      ),
    );
  }
}