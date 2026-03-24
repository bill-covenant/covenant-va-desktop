import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/di/service_locator.dart';
import '../widgets/task_detail_modal.dart';
import 'package:intl/intl.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  /// Allow other screens to pre-warm the archive cache
  static void updateCache(List<TaskModel> tasks) {
    _ArchiveScreenState._cachedArchive = tasks;
    _ArchiveScreenState._lastFetchTime = DateTime.now();
  }

  /// Get current archive cache
  static List<TaskModel>? getCache() => _ArchiveScreenState._cachedArchive;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  bool _isLoading = false;
  List<TaskModel> _archivedTasks = [];
  String? _error;
  String _searchQuery = '';

  static List<TaskModel>? _cachedArchive;
  static DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    if (_cachedArchive != null) {
      _archivedTasks = _cachedArchive!;
      if (_lastFetchTime == null ||
          DateTime.now().difference(_lastFetchTime!) > const Duration(seconds: 30)) {
        _loadArchivedTasks(showLoading: false);
      }
    } else {
      _loadArchivedTasks(showLoading: false);
    }
  }

  Future<void> _loadArchivedTasks({bool showLoading = false}) async {
    if (!mounted) return;
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final taskRepository = getIt<TaskRepository>();
      final tasks = await taskRepository.getAllTasks(status: 'ARCHIVED');

      if (!mounted) return;
      _cachedArchive = tasks;
      _lastFetchTime = DateTime.now();
      setState(() {
        _archivedTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_archivedTasks.isEmpty) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unarchiveTask(TaskModel task) async {
    try {
      final taskRepository = getIt<TaskRepository>();
      await taskRepository.updateTaskStatus(task.id, 'COMPLETED');
      setState(() {
        _archivedTasks.removeWhere((t) => t.id == task.id);
        _cachedArchive = List.from(_archivedTasks);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task restored to completed'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  List<TaskModel> get _filteredTasks {
    if (_searchQuery.isEmpty) return _archivedTasks;
    final query = _searchQuery.toLowerCase();
    return _archivedTasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
          (task.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        final isDark = ThemeProvider().isDarkMode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildContent(isDark)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(50, 36, 48, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.archive_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 18),
          Text(
            'Archive',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Failed to load archived tasks', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600])),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadArchivedTasks, child: const Text('Retry')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(50, 24, 48, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search archived tasks...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400]),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.grey[400], size: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Count
          Text(
            '${_filteredTasks.length} archived ${_filteredTasks.length == 1 ? 'task' : 'tasks'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          // Task list
          if (_filteredTasks.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildTaskList(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.archive_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No archived tasks' : 'No matching archived tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isEmpty
                ? 'Completed tasks you archive will appear here'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -8),
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
              ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1535), const Color(0xFF1A1230)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.08)]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.archive_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Archived Tasks', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                      SizedBox(height: 2),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Text(
                      '${_filteredTasks.length} ${_filteredTasks.length == 1 ? 'task' : 'tasks'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF232738), const Color(0xFF1A1D2E)]
                      : [const Color(0xFFF5F3FF), Colors.white.withOpacity(0.9)],
                ),
                border: Border(bottom: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 44, child: _ColLabel(label: '#')),
                  const Expanded(flex: 4, child: _ColLabel(label: 'TASK')),
                  const Expanded(flex: 2, child: _ColLabel(label: 'PRIORITY')),
                  const Expanded(flex: 3, child: _ColLabel(label: 'COMPLETED')),
                  SizedBox(width: 120, child: Center(child: _ColLabel(label: 'ACTIONS'))),
                ],
              ),
            ),
            // Rows
            ...List.generate(_filteredTasks.length, (i) {
              final task = _filteredTasks[i];
              return _ArchiveRow(
                task: task,
                index: i + 1,
                isLast: i == _filteredTasks.length - 1,
                onUnarchive: () => _unarchiveTask(task),
                onTap: () => showDialog(context: context, builder: (_) => TaskDetailModal(task: task)),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  final String label;
  const _ColLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: const Color(0xFF7C3AED).withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ArchiveRow extends StatefulWidget {
  final TaskModel task;
  final int index;
  final bool isLast;
  final VoidCallback onUnarchive;
  final VoidCallback onTap;

  const _ArchiveRow({
    required this.task,
    required this.index,
    required this.isLast,
    required this.onUnarchive,
    required this.onTap,
  });

  @override
  State<_ArchiveRow> createState() => _ArchiveRowState();
}

class _ArchiveRowState extends State<_ArchiveRow> {
  bool _isHovered = false;

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 'URGENT': return const Color(0xFFDC2626);
      case 'HIGH': return const Color(0xFFEA580C);
      case 'MEDIUM': return const Color(0xFFD97706);
      case 'LOW': return const Color(0xFF2563EB);
      default: return const Color(0xFF6B7280);
    }
  }

  String get _priorityLabel {
    switch (widget.task.priority) {
      case 'URGENT': return 'Urgent';
      case 'HIGH': return 'High';
      case 'MEDIUM': return 'Medium';
      case 'LOW': return 'Low';
      default: return widget.task.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF232738) : const Color(0xFFFAF5FF))
                : (isDark ? const Color(0xFF1A1D2E) : Colors.white),
          ),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Priority accent bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isHovered ? 4 : 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _priorityColor.withOpacity(_isHovered ? 1.0 : 0.3),
                            _priorityColor.withOpacity(_isHovered ? 0.4 : 0.08),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          children: [
                            // Index
                            SizedBox(
                              width: 44,
                              child: Container(
                                width: 34, height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${widget.index}',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Title
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.task.title,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF111827)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.task.description!,
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400]),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Priority
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _priorityColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _priorityColor.withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _priorityColor, shape: BoxShape.circle)),
                                      const SizedBox(width: 7),
                                      Text(_priorityLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _priorityColor)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Completed date
                            Expanded(
                              flex: 3,
                              child: widget.task.completedAt != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          child: Icon(Icons.check_circle_outline, size: 14, color: isDark ? Colors.white54 : const Color(0xFF10B981)),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            DateFormat('MMM dd, yyyy').format(widget.task.completedAt!),
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.grey[600]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text('—', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey[400])),
                            ),
                            // Actions
                            SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tooltip(
                                    message: 'Restore to completed',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: widget.onUnarchive,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                                        ),
                                        child: const Icon(Icons.unarchive_rounded, size: 18, color: Color(0xFF10B981)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isLast)
                Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.06)),
            ],
          ),
        ),
      ),
    );
  }
}
