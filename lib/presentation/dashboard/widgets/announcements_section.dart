import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';

class AnnouncementsSection extends StatefulWidget {
  const AnnouncementsSection({super.key});

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  List<AnnouncementModel> _announcements = [];
  final Set<String> _dismissed = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final repo = GetIt.I<AnnouncementRepository>();
      final announcements = await repo.getPublishedAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _loaded = true;
        });
      }
    } catch (e) {
      // Silently fail — announcements are non-critical
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _dismiss(String id) {
    setState(() => _dismissed.add(id));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final visible = _announcements.where((a) => !_dismissed.contains(a.id)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: visible.map((a) => _buildAnnouncementCard(a)).toList(),
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final colors = _priorityColors(announcement.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.bgStart, colors.bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.border.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(colors.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.text,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (announcement.publishedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(announcement.publishedAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.text.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _dismiss(announcement.id),
              child: Icon(
                Icons.close,
                size: 16,
                color: colors.text.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  _PriorityColors _priorityColors(String priority) {
    switch (priority) {
      case 'URGENT':
        return _PriorityColors(
          bgStart: const Color(0xFFFEF2F2),
          bgEnd: const Color(0xFFFEE2E2),
          border: const Color(0xFFFCA5A5),
          iconBg: const Color(0xFFEF4444),
          icon: Icons.warning_rounded,
          title: const Color(0xFF991B1B),
          text: const Color(0xFFDC2626),
        );
      case 'HIGH':
        return _PriorityColors(
          bgStart: const Color(0xFFFFFBEB),
          bgEnd: const Color(0xFFFEF3C7),
          border: const Color(0xFFFCD34D),
          iconBg: const Color(0xFFF59E0B),
          icon: Icons.notifications_active_rounded,
          title: const Color(0xFF92400E),
          text: const Color(0xFFD97706),
        );
      case 'LOW':
        return _PriorityColors(
          bgStart: const Color(0xFFF9FAFB),
          bgEnd: const Color(0xFFF3F4F6),
          border: const Color(0xFFD1D5DB),
          iconBg: const Color(0xFF6B7280),
          icon: Icons.info_outline_rounded,
          title: const Color(0xFF374151),
          text: const Color(0xFF6B7280),
        );
      default: // MEDIUM
        return _PriorityColors(
          bgStart: const Color(0xFFEFF6FF),
          bgEnd: const Color(0xFFDBEAFE),
          border: const Color(0xFF93C5FD),
          iconBg: const Color(0xFF3B82F6),
          icon: Icons.campaign_rounded,
          title: const Color(0xFF1E3A5F),
          text: const Color(0xFF2563EB),
        );
    }
  }
}

class _PriorityColors {
  final Color bgStart;
  final Color bgEnd;
  final Color border;
  final Color iconBg;
  final IconData icon;
  final Color title;
  final Color text;

  _PriorityColors({
    required this.bgStart,
    required this.bgEnd,
    required this.border,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.text,
  });
}
