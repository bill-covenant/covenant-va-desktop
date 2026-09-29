import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/time_entry.dart';
import 'time_entry_card.dart';
import 'timecard_empty_state.dart';

/// Card listing the time entries, built lazily.
///
/// This widget is a SLIVER — place it inside a [CustomScrollView] (or a
/// [SliverMainAxisGroup]), not in a Column / box widget.
class TimeEntriesList extends StatelessWidget {
  final List<TimeEntry> entries;
  final Function(String) onDelete;

  const TimeEntriesList({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 16), spreadRadius: -8),
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
              ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.08)),
      ),
      // Inset by the border width, like a Container with this decoration.
      sliver: SliverPadding(
        padding: const EdgeInsets.all(1),
        sliver: SliverMainAxisGroup(
          slivers: [
            // Header
            SliverToBoxAdapter(
              // Rounded top like the card; the clip extends below the header so
              // its drop shadow still shows over the card body.
              child: ClipRRect(
                clipper: const _CardTopClipper(radius: _radius),
                child: _buildHeader(isDark),
              ),
            ),
            // Content
            if (entries.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: TimecardEmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  itemBuilder: (context, i) => TimeEntryCard(
                    key: ValueKey(entries[i].id),
                    entry: entries[i],
                    onDelete: onDelete,
                  ),
                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [const Color(0xFF1E1535), const Color(0xFF1A1230)]
              : [const Color(0xFF7C3AED), const Color(0xFF6366F1)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(isDark ? 0.1 : 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time Entries',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(
                'Sorted by most recent',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500),
              ),
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
              '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
              style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips to the card's rounded top corners and side edges, extending
/// [overflow] px below the child so its drop shadow isn't cut off.
class _CardTopClipper extends CustomClipper<RRect> {
  final double radius;
  static const double overflow = 24;

  const _CardTopClipper({required this.radius});

  @override
  RRect getClip(Size size) {
    return RRect.fromLTRBAndCorners(
      0,
      0,
      size.width,
      size.height + overflow,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  @override
  bool shouldReclip(_CardTopClipper oldClipper) =>
      oldClipper.radius != radius;
}
