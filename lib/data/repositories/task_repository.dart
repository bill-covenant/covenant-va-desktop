import '../../core/constants/api_constants.dart';
import '../models/task_model.dart';
import '../models/task_stats_model.dart';
import '../providers/api_provider.dart';

class TaskRepository {
  final ApiProvider _apiProvider;

  TaskRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  // Get all tasks
  Future<List<TaskModel>> getAllTasks({
    String? status,
    String? priority,
    String? search,
    bool forceRefresh = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (search != null) queryParams['search'] = search;

      String endpoint = ApiConstants.tasks;
      if (queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$query';
      }

      final response = await _apiProvider.get(
        endpoint,
        requiresAuth: true,
        forceRefresh: forceRefresh,
      );

      final tasksJson = response['tasks'] as List;
      return tasksJson
          .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  // Get task statistics
  Future<TaskStatsModel> getTaskStats() async {
    try {
      final response = await _apiProvider.get(
        ApiConstants.taskStats,
        requiresAuth: true,
      );

      return TaskStatsModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch task stats: $e');
    }
  }

  // Update task status
  Future<TaskModel> updateTaskStatus(String taskId, String status) async {
    try {
      final response = await _apiProvider.put(
        ApiConstants.taskById(taskId),
        {'status': status},
        requiresAuth: true,
      );

      return TaskModel.fromJson(response['task'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }
}