class TaskStatsModel {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;

  TaskStatsModel({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
  });

  factory TaskStatsModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    return TaskStatsModel(
      total: stats['total'] as int,
      pending: stats['pending'] as int,
      inProgress: stats['inProgress'] as int,
      completed: stats['completed'] as int,
      overdue: stats['overdue'] as int,
    );
  }
}