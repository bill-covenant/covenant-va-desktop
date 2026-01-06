import 'package:flutter/material.dart';

class TasksEmptyState extends StatelessWidget {
  final String searchQuery;
  final String statusFilter;
  final String priorityFilter;

  const TasksEmptyState({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.priorityFilter,
  });

  @override
  Widget build(BuildContext context) {
    String message = 'No tasks assigned yet';
    if (searchQuery.isNotEmpty) {
      message = 'No tasks match your search';
    } else if (statusFilter != 'ALL' || priorityFilter != 'ALL') {
      message = 'No tasks match your filters';
    }

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}