// lib/presentation/timecard/widgets/time_card_widgets/time_field.dart

import 'package:flutter/material.dart';

class TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback? onTap;
  final bool isActive;

  const TimeField({
    Key? key,
    required this.label,
    required this.time,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTime = time != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF10B981).withOpacity(0.9)
                    : Colors.white.withOpacity(0.7),
                letterSpacing: 0.3,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isActive
                    ? [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF059669).withOpacity(0.1),
                      ]
                    : hasTime
                        ? [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.08),
                          ]
                        : [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
              ),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : hasTime
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white.withOpacity(0.1),
                width: isActive ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.access_time_rounded,
                  size: 16,
                  color: isActive
                      ? const Color(0xFF10B981)
                      : hasTime
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  time == null ? '--:-- --' : _formatTime(time!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF10B981)
                        : hasTime
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.4),
                  ),
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}