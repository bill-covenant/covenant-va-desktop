import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/time_entry.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/timecard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final TaskRepository _taskRepository;
  final TimecardRepository _timecardRepository;

  // Last successful load — used to keep timecard info when a refresh fails.
  DashboardLoaded? _lastLoaded;

  DashboardBloc({
    required TaskRepository taskRepository,
    required TimecardRepository timecardRepository,
  })  : _taskRepository = taskRepository,
        _timecardRepository = timecardRepository,
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
      await _taskRepository.updateTaskStatus(event.taskId, event.newStatus);
      await _loadDashboardData(emit);
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _loadDashboardData(Emitter<DashboardState> emit) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekFromNow = today.add(const Duration(days: 8));
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Fetch everything in parallel. A failed clock/entries request keeps the
      // last known values instead of pretending the VA isn't clocked in.
      List<TimeEntry> monthEntries = const [];
      DateTime? activeClockIn = _lastLoaded?.activeClockIn;
      bool entriesFailed = false;
      await Future.wait<void>([
        () async {
          try {
            activeClockIn = await _timecardRepository.getActiveClock();
          } catch (_) {/* keep last known */}
        }(),
        () async {
          try {
            monthEntries = await _timecardRepository.getTimeEntries(month: currentMonth);
          } catch (_) {
            entriesFailed = true;
          }
        }(),
      ]);

      final results = await Future.wait([
        _taskRepository.getTaskStats(),
        _taskRepository.getAllTasks(),
      ]);

      final stats = results[0] as dynamic;
      final allTasks = results[1] as List<TaskModel>;

      // Filter today's tasks
      final todayTasks = allTasks.where((task) {
        if (task.isCompleted) return false;
        if (task.dueDate == null) return false;
        final dueDate = task.dueDate!.toLocal();
        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return taskDate.isAtSameMomentAs(today);
      }).toList();

      // Filter upcoming tasks (tomorrow to next 7 days)
      final upcomingTasks = allTasks.where((task) {
        if (task.isCompleted) return false;
        if (task.dueDate == null) return false;
        final dueDate = task.dueDate!.toLocal();
        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return taskDate.isAfter(today) && taskDate.isBefore(weekFromNow);
      }).toList();

      // Also include overdue tasks in upcoming
      final overdueTasks = allTasks.where((task) {
        if (task.isCompleted) return false;
        if (task.dueDate == null) return false;
        final dueDate = task.dueDate!.toLocal();
        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return taskDate.isBefore(today);
      }).toList();

      todayTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      upcomingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      overdueTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

      // Combine overdue + upcoming
      final combinedUpcoming = [...overdueTasks, ...upcomingTasks];

      // Calculate today's hours from time entries
      double todayHours = 0.0;
      int todayCount = 0;
      for (final entry in monthEntries) {
        final entryDate = entry.date.toLocal();
        final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
        if (entryDay.isAtSameMomentAs(today)) {
          todayHours += entry.hoursWorked;
          todayCount++;
        }
      }

      // Get recent entries (last 5)
      final sortedEntries = List<TimeEntry>.from(monthEntries)
        ..sort((a, b) => b.date.compareTo(a.date));
      final recentEntries = sortedEntries.take(5).toList();

      final last = _lastLoaded;
      final loaded = DashboardLoaded(
        stats: stats,
        allTasks: allTasks,
        todayTasks: todayTasks,
        upcomingTasks: combinedUpcoming.take(5).toList(),
        todayHoursWorked: entriesFailed && last != null ? last.todayHoursWorked : todayHours,
        todayEntriesCount: entriesFailed && last != null ? last.todayEntriesCount : todayCount,
        recentEntries: entriesFailed && last != null ? last.recentEntries : recentEntries,
        activeClockIn: activeClockIn,
      );
      _lastLoaded = loaded;
      emit(loaded);
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}