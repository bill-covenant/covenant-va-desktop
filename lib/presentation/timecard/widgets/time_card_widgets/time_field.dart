// lib/presentation/timecard/widgets/time_card_widgets/time_field.dart

import 'package:flutter/material.dart';

class TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback? onTap;

  const TimeField({
    Key? key,
    required this.label,
    required this.time,
    required this.onTap,
  }) : super(key: key);

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: onTap == null
                    ? [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                      ]
                    : [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ],
              ),
              border: Border.all(
                color: onTap == null
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: onTap == null 
                      ? Colors.white.withOpacity(0.3) 
                      : Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 10),
                Text(
                  time == null ? '--:-- --' : _formatTime(time!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onTap == null 
                        ? Colors.white.withOpacity(0.4) 
                        : Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}