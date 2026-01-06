import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TaskRepository _taskRepository;

  DashboardBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onDashboardLoadRequested);
    on<DashboardRefreshRequested>(_onDashboardRefreshRequested);
    on<TaskStatusUpdated>(_onTaskStatusUpdated);
  }

  Future<void> _onDashboardLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _loadDashboardData(emit);
  }

  Future<void> _onDashboardRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadDashboardData(emit);
  }

  Future<void> _onTaskStatusUpdated(
    TaskStatusUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Update task status
      await _taskRepository.updateTaskStatus(event.taskId, event.newStatus);

      // Refresh dashboard data
      await _loadDashboardData(emit);
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _loadDashboardData(Emitter<DashboardState> emit) async {
    try {
      // Fetch stats and tasks in parallel
      final results = await Future.wait([
        _taskRepository.getTaskStats(),
        _taskRepository.getAllTasks(),
      ]);

      final stats = results[0] as dynamic;
      final allTasks = results[1] as List<TaskModel>;

      // Get current date at midnight (LOCAL TIME)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekFromNow = today.add(const Duration(days: 8));

      // Filter today's tasks
      final todayTasks = allTasks.where((task) {
        if (task.isCompleted) return false;
        if (task.dueDate == null) return false;
        
        // Convert UTC date to local date for comparison
        final dueDate = task.dueDate!.toLocal();
        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        
        return taskDate.isAtSameMomentAs(today);
      }).toList();

      // Filter upcoming tasks (tomorrow to next 7 days)
      final upcomingTasks = allTasks.where((task) {
        if (task.isCompleted) return false;
        if (task.dueDate == null) return false;
        
        // Convert UTC date to local date for comparison
        final dueDate = task.dueDate!.toLocal();
        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        
        return taskDate.isAfter(today) && taskDate.isBefore(weekFromNow);
      }).toList();

      // Sort by due date
      todayTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      upcomingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

      emit(DashboardLoaded(
        stats: stats,
        todayTasks: todayTasks,
        upcomingTasks: upcomingTasks.take(5).toList(),
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}