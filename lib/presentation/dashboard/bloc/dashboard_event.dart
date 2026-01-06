import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

// Load dashboard data
class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

// Refresh dashboard
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

// Update task status
class TaskStatusUpdated extends DashboardEvent {
  final String taskId;
  final String newStatus;

  const TaskStatusUpdated({
    required this.taskId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [taskId, newStatus];
}