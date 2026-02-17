// lib/presentation/timecard/widgets/time_card_widgets/clock_dialog/time_log_section.dart

import 'package:flutter/material.dart';
import '../time_field.dart';

class TimeLogSection extends StatelessWidget {
  final TimeOfDay? clockInTime;
  final TimeOfDay? clockOutTime;
  final VoidCallback? onEditClockIn;
  final VoidCallback? onEditClockOut;

  const TimeLogSection({
    Key? key,
    required this.clockInTime,
    required this.clockOutTime,
    this.onEditClockIn,
    this.onEditClockOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Log',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TimeField(
                  label: 'Clock In',
                  time: clockInTime,
                  onTap: onEditClockIn,
                  isActive: clockInTime != null,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    clockOutTime != null ? 0.15 : 0.06,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(
                    clockOutTime != null ? 0.7 : 0.25,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TimeField(
                  label: 'Clock Out',
                  time: clockOutTime,
                  onTap: onEditClockOut,
                  isActive: clockOutTime != null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}