import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/socket_service.dart';
import '../widgets/tasks_header.dart';
import '../widgets/tasks_skeleton_loading.dart';
import '../widgets/tasks_content.dart';
import '../widgets/tasks_error_state.dart';
import '../widgets/refresh_fab.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _statusFilter = 'ALL';
  String _priorityFilter = 'ALL';
  String _searchQuery = '';
  
  bool _isLoading = false; // ✅ Changed to false
  bool _isInitialLoad = true; // ✅ Track first load
  List<TaskModel> _allTasks = [];
  String? _error;

  // ✅ Static cache to persist data across navigations
  static List<TaskModel>? _cachedTasks;
  static DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    
    // ✅ Load from cache immediately if available
    if (_cachedTasks != null && _cachedTasks!.isNotEmpty) {
      _allTasks = _cachedTasks!;
      _isInitialLoad = false;
      _isLoading = false;
      
      // ✅ Refresh in background if cache is old (older than 30 seconds)
      if (_lastFetchTime == null || 
          DateTime.now().difference(_lastFetchTime!) > const Duration(seconds: 30)) {
        _loadAllTasks(showLoading: false);
      }
    } else {
      // ✅ No cache, show loading
      _isLoading = true;
      _loadAllTasks(showLoading: true);
    }
    
    SocketService().onTaskUpdate = _handleTaskUpdate;
  }

  @override
  void dispose() {
    SocketService().onTaskUpdate = null;
    super.dispose();
  }

  void _handleTaskUpdate() {
    _loadAllTasks(showLoading: false); // ✅ Background refresh
  }

  Future<void> _loadAllTasks({bool showLoading = true}) async {
    if (!mounted) return;
    
    // ✅ Only show loading if explicitly requested
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final taskRepository = getIt<TaskRepository>();
      final tasks = await taskRepository.getAllTasks();
      
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      if (!mounted) return;
      
      // ✅ Update cache
      _cachedTasks = tasks;
      _lastFetchTime = DateTime.now();
      
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    return tasks.where((task) {
      if (_statusFilter != 'ALL') {
        if (_statusFilter == 'PENDING' && !task.isPending) return false;
        if (_statusFilter == 'IN_PROGRESS' && !task.isInProgress) return false;
        if (_statusFilter == 'COMPLETED' && !task.isCompleted) return false;
      }

      if (_priorityFilter != 'ALL' && task.priority != _priorityFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDescription =
            task.description?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDescription) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TasksHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildContent(),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: RefreshFAB(
                      onRefresh: () => _loadAllTasks(showLoading: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    // ✅ Only show skeleton on initial load with no cache
    if (_isLoading && _isInitialLoad) {
      return const TasksSkeletonLoading();
    }

    if (_error != null && _allTasks.isEmpty) {
      return TasksErrorState(
        error: _error!,
        onRetry: () => _loadAllTasks(showLoading: true),
      );
    }

    final filteredTasks = _filterTasks(_allTasks);

    return TasksContent(
      filteredTasks: filteredTasks,
      statusFilter: _statusFilter,
      priorityFilter: _priorityFilter,
      searchQuery: _searchQuery,
      onStatusChanged: (value) {
        if (!mounted) return;
        setState(() => _statusFilter = value);
      },
      onPriorityChanged: (value) {
        if (!mounted) return;
        setState(() => _priorityFilter = value);
      },
      onSearchChanged: (value) {
        if (!mounted) return;
        setState(() => _searchQuery = value);
      },
      onTaskUpdated: () => _loadAllTasks(showLoading: false),
      onRefresh: () => _loadAllTasks(showLoading: false),
    );
  }
}