// lib/presentation/timecard/widgets/time_card_widgets/clock_dialog/clock_button.dart

import 'package:flutter/material.dart';

class ClockButton extends StatelessWidget {
  final TimeOfDay? clockInTime;
  final TimeOfDay? clockOutTime;
  final bool isClockedIn;
  final bool isClockedOut;
  final double totalHours;
  final String Function(TimeOfDay) formatTime;
  final VoidCallback onTap;

  const ClockButton({
    Key? key,
    required this.clockInTime,
    required this.clockOutTime,
    required this.isClockedIn,
    required this.isClockedOut,
    required this.totalHours,
    required this.formatTime,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isClockIn = clockInTime == null;
    final bool isDone = isClockedOut;

    final List<Color> colors;
    final IconData icon;
    final String label;

    if (isClockIn) {
      colors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      icon = Icons.play_arrow_rounded;
      label = 'Clock In';
    } else if (isClockedIn) {
      colors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      icon = Icons.stop_rounded;
      label = 'Clock Out';
    } else {
      colors = [const Color(0xFF10B981), const Color(0xFF059669)];
      icon = Icons.check_circle_rounded;
      label = 'Completed — ${formatTime(clockInTime!)} to ${formatTime(clockOutTime!)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      child: Column(
        children: [
          InkWell(
            onTap: isDone ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDone
                      ? colors.map((c) => c.withOpacity(0.7)).toList()
                      : colors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(isDone ? 0.2 : 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  if (!isDone)
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(-5, -5),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: isDone ? 14 : 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isClockedIn) ...[
                    const SizedBox(width: 12),
                    _buildLiveIndicator(),
                  ],
                ],
              ),
            ),
          ),
          if (isDone) ...[
            const SizedBox(height: 12),
            _buildHoursSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: const Color(0xFF10B981).withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Text(
            'Total: ${totalHours.toStringAsFixed(2)} hours',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}