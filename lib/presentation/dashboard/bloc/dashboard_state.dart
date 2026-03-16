import 'package:equatable/equatable.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/task_stats_model.dart';
import '../../../data/models/time_entry.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final TaskStatsModel stats;
  final List<TaskModel> allTasks;
  final List<TaskModel> todayTasks;
  final List<TaskModel> upcomingTasks;
  final double todayHoursWorked;
  final int todayEntriesCount;
  final List<TimeEntry> recentEntries;

  const DashboardLoaded({
    required this.stats,
    this.allTasks = const [],
    required this.todayTasks,
    required this.upcomingTasks,
    this.todayHoursWorked = 0.0,
    this.todayEntriesCount = 0,
    this.recentEntries = const [],
  });

  @override
  List<Object?> get props => [stats, allTasks, todayTasks, upcomingTasks, todayHoursWorked, todayEntriesCount, recentEntries];

  DashboardLoaded copyWith({
    TaskStatsModel? stats,
    List<TaskModel>? allTasks,
    List<TaskModel>? todayTasks,
    List<TaskModel>? upcomingTasks,
    double? todayHoursWorked,
    int? todayEntriesCount,
    List<TimeEntry>? recentEntries,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      allTasks: allTasks ?? this.allTasks,
      todayTasks: todayTasks ?? this.todayTasks,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
      todayHoursWorked: todayHoursWorked ?? this.todayHoursWorked,
      todayEntriesCount: todayEntriesCount ?? this.todayEntriesCount,
      recentEntries: recentEntries ?? this.recentEntries,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}