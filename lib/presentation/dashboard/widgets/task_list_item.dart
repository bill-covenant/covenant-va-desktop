import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';

class TaskListItem extends StatelessWidget {
  final TaskModel task;

  const TaskListItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPriorityColor().withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Meta info row
                      Row(
                        children: [
                          // Priority badge
                          _buildBadge(
                            _getPriorityLabel(),
                            _getPriorityColor(),
                          ),
                          const SizedBox(width: 8),

                          // Status badge
                          _buildBadge(
                            _getStatusLabel(),
                            _getStatusColor(),
                          ),
                          const SizedBox(width: 8),

                          // Due date
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: task.isOverdue
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd').format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: task.isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Status dropdown
                _buildStatusDropdown(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor().withOpacity(0.2),
            _getStatusColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: DropdownButton<String>(
        value: task.status,
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: _getStatusColor(),
        ),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(),
        ),
        items: const [
          DropdownMenuItem(
            value: 'PENDING',
            child: Text('Pending'),
          ),
          DropdownMenuItem(
            value: 'IN_PROGRESS',
            child: Text('In Progress'),
          ),
          DropdownMenuItem(
            value: 'COMPLETED',
            child: Text('Completed'),
          ),
        ],
        onChanged: (newStatus) {
          if (newStatus != null && newStatus != task.status) {
            context.read<DashboardBloc>().add(
                  TaskStatusUpdated(
                    taskId: task.id,
                    newStatus: newStatus,
                  ),
                );
          }
        },
      ),
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'URGENT':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFF59E0B);
      case 'MEDIUM':
        return const Color(0xFF3B82F6);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return AppColors.textSecondary;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'URGENT':
        return 'URGENT';
      case 'HIGH':
        return 'HIGH';
      case 'MEDIUM':
        return 'MEDIUM';
      case 'LOW':
        return 'LOW';
      default:
        return task.priority;
    }
  }

  Color _getStatusColor() {
    switch (task.status) {
      case 'COMPLETED':
        return const Color(0xFF10B981);
      case 'IN_PROGRESS':
        return const Color(0xFF8B5CF6);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel() {
    switch (task.status) {
      case 'COMPLETED':
        return 'Done';
      case 'IN_PROGRESS':
        return 'Working';
      case 'PENDING':
        return 'To Do';
      default:
        return task.status;
    }
  }
}