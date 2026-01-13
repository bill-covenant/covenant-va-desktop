import 'package:flutter/material.dart';
import '../../../data/models/time_entry.dart';
import 'time_entry_card.dart';
import 'timecard_empty_state.dart';

class TimeEntriesList extends StatelessWidget {
  final List<TimeEntry> entries;
  final Function(String) onDelete; // ← Changed back to Function(String)

  const TimeEntriesList({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Entries',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        if (entries.isEmpty)
          const TimecardEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return TimeEntryCard(
                entry: entries[index],
                onDelete: onDelete,
              );
            },
          ),
      ],
    );
  }
}