import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/card_decoration.dart';
import '../../../core/theme/theme_provider.dart';
import '../../shared/widgets/pill_badge.dart';

class LiveTimerCard extends StatefulWidget {
  final DateTime? activeClockIn;
  final double todayHoursWorked;
  final int todayEntriesCount;
  final int todayTasksCount;

  const LiveTimerCard({
    super.key,
    required this.activeClockIn,
    required this.todayHoursWorked,
    required this.todayEntriesCount,
    required this.todayTasksCount,
  });

  @override
  State<LiveTimerCard> createState() => _LiveTimerCardState();
}

class _LiveTimerCardState extends State<LiveTimerCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LiveTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeClockIn != oldWidget.activeClockIn) {
      _timer?.cancel();
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.activeClockIn != null) {
      _updateElapsed();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
    } else {
      _elapsed = Duration.zero;
    }
  }

  void _updateElapsed() {
    if (widget.activeClockIn != null && mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.activeClockIn!);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatStaticHours(double hrs) {
    final h = hrs.floor();
    final m = ((hrs - h) * 60).floor();
    final s = (((hrs - h) * 60 - m) * 60).floor();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    final isLive = widget.activeClockIn != null;
    final timeStr = isLive ? _formatDuration(_elapsed) : _formatStaticHours(widget.todayHoursWorked);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: buildCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isLive
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [BoxShadow(
                    color: (isLive ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)).withOpacity(0.3),
                    blurRadius: 6, offset: const Offset(0, 2),
                  )],
                ),
                child: Icon(isLive ? Icons.play_arrow_rounded : Icons.timer, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                isLive ? 'Live' : 'Timer',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: isLive ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.6), blurRadius: 6)],
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w900,
              color: isLive ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLive ? 'Currently clocked in' : 'Hours worked today',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PillBadge(text: '${widget.todayEntriesCount} entries', backgroundColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7C3AED)),
              const SizedBox(width: 6),
              PillBadge(text: '${widget.todayTasksCount} tasks', backgroundColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }
}
