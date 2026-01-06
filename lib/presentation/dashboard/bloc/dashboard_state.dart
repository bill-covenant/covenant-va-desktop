import 'package:equatable/equatable.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/task_stats_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

// Initial state
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

// Loading state
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

// Loaded state
class DashboardLoaded extends DashboardState {
  final TaskStatsModel stats;
  final List<TaskModel> todayTasks;
  final List<TaskModel> upcomingTasks;

  const DashboardLoaded({
    required this.stats,
    required this.todayTasks,
    required this.upcomingTasks,
  });

  @override
  List<Object?> get props => [stats, todayTasks, upcomingTasks];

  DashboardLoaded copyWith({
    TaskStatsModel? stats,
    List<TaskModel>? todayTasks,
    List<TaskModel>? upcomingTasks,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      todayTasks: todayTasks ?? this.todayTasks,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
    );
  }
}

// Error state
class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}