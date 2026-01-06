import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/task_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../tasks/widgets/task_detail_modal.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.onStatusChanged,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  String? _optimisticStatus;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final displayStatus = _optimisticStatus ?? widget.task.status;
    final isOverdue = widget.task.isOverdue;
    final priorityColor = _getPriorityColor(widget.task.priority);

    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is DashboardLoaded) {
          if (mounted) {
            setState(() {
              _optimisticStatus = null;
            });
          }
          print('✅ Task status updated successfully');
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => _showTaskDetails(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -4.0 : 0.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered 
                    ? priorityColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                // Main shadow
                BoxShadow(
                  color: priorityColor.withOpacity(_isHovered ? 0.3 : 0.15),
                  blurRadius: _isHovered ? 20 : 15,
                  offset: Offset(0, _isHovered ? 12 : 8),
                  spreadRadius: 0,
                ),
                // Inner glow
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(-2, -2),
                  spreadRadius: 0,
                ),
                // Ambient shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Shimmer effect overlay
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              priorityColor.withOpacity(0.03),
                              Colors.transparent,
                              priorityColor.withOpacity(0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  Row(
                    children: [
                      // 3D Priority indicator bar
                      Container(
                        width: 6,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              priorityColor,
                              priorityColor.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: priorityColor.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Task info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title with 3D effect
                                    Text(
                                      widget.task.title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                        letterSpacing: -0.3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.1),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),

                                    // 3D Badges row
                                    Row(
                                      children: [
                                        _build3DBadge(
                                          label: widget.task.priority,
                                          color: priorityColor,
                                        ),
                                        const SizedBox(width: 8),
                                        _build3DBadge(
                                          label: _formatStatus(displayStatus),
                                          color: _getStatusColor(displayStatus),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Due date with icon
                                    if (widget.task.dueDate != null)
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: isOverdue
                                                  ? Colors.red.withOpacity(0.1)
                                                  : const Color(0xFF6B7280).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: isOverdue
                                                  ? Colors.red
                                                  : const Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('MMM dd, yyyy')
                                                .format(widget.task.dueDate!),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isOverdue
                                                  ? Colors.red
                                                  : const Color(0xFF6B7280),
                                              fontWeight: isOverdue
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                          if (isOverdue) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFDC2626),
                                                    Color(0xFFEF4444),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Text(
                                                'OVERDUE',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                  ],
                                ),
                              ),

                              // Status dropdown with 3D effect
                              const SizedBox(width: 16),
                              _build3DStatusDropdown(context, displayStatus),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _build3DStatusDropdown(BuildContext context, String displayStatus) {
    final statusColor = _getStatusColor(displayStatus);
    
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.15),
              statusColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: DropdownButton<String>(
          value: displayStatus,
          underline: const SizedBox(),
          isDense: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: statusColor,
            size: 20,
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: statusColor,
            letterSpacing: 0.3,
          ),
          items: const [
            DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
            DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
          ],
          onChanged: (String? newStatus) {
            if (newStatus != null && newStatus != widget.task.status) {
              print('🔄 Optimistically updating status to $newStatus');
              
              setState(() {
                _optimisticStatus = newStatus;
              });
              
              context.read<DashboardBloc>().add(
                    TaskStatusUpdated(
                      taskId: widget.task.id,
                      newStatus: newStatus,
                    ),
                  );
            }
          },
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailModal(task: widget.task),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'IN_PROGRESS':
        return const Color(0xFF8B5CF6);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'Working';
      case 'COMPLETED':
        return 'Done';
      case 'PENDING':
        return 'Pending';
      default:
        return status;
    }
  }
}