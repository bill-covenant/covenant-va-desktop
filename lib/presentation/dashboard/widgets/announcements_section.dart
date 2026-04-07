import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';

class AnnouncementsSection extends StatefulWidget {
  const AnnouncementsSection({super.key});

  @override
  State<AnnouncementsSection> createState() => _AnnouncementsSectionState();
}

class _AnnouncementsSectionState extends State<AnnouncementsSection> {
  List<AnnouncementModel> _announcements = [];
  Set<String> _dismissed = {};
  bool _loaded = false;
  bool _dismissedLoaded = false;

  // Shared key with AnnouncementsScreen so dismissals stay in sync
  static const _dismissedKey = 'hidden_announcement_ids';

  @override
  void initState() {
    super.initState();
    _loadDismissedAndFetch();
  }

  Future<void> _loadDismissedAndFetch() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate from old key if it exists
    const oldKey = 'dismissed_announcements';
    final oldDismissed = prefs.getStringList(oldKey);
    if (oldDismissed != null && oldDismissed.isNotEmpty) {
      final existing = prefs.getStringList(_dismissedKey) ?? [];
      final merged = {...existing, ...oldDismissed}.toList();
      await prefs.setStringList(_dismissedKey, merged);
      await prefs.remove(oldKey);
    }

    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    _dismissed = dismissed.toSet();
    _dismissedLoaded = true;
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
      print('❌ AnnouncementsSection: Failed to fetch announcements: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _dismiss(String id) async {
    setState(() => _dismissed.add(id));
    final prefs = await SharedPreferences.getInstance();
    // Reload existing list first to avoid overwriting dismissals from AnnouncementsScreen
    final existing = prefs.getStringList(_dismissedKey) ?? [];
    final merged = {...existing, id}.toList();
    await prefs.setStringList(_dismissedKey, merged);
  }

  @override
  Widget build(BuildContext context) {
    // Wait for both dismissed list AND announcements before rendering
    if (!_loaded || !_dismissedLoaded) return const SizedBox.shrink();

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
    final dark = ThemeProvider().isDarkMode;
    final colors = _priorityColors(announcement.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? colors.accent.withOpacity(0.3) : colors.accent.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
                color: colors.accent.withOpacity(dark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(colors.icon, color: colors.accent, size: 18),
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
                      color: dark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.white.withOpacity(0.7) : const Color(0xFF4B5563),
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
                        color: dark ? Colors.white.withOpacity(0.35) : const Color(0xFF9CA3AF),
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
                color: dark ? Colors.white.withOpacity(0.4) : const Color(0xFF9CA3AF),
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

  _PriorityStyle _priorityColors(String priority) {
    switch (priority) {
      case 'URGENT':
        return _PriorityStyle(accent: const Color(0xFFEF4444), icon: Icons.warning_rounded);
      case 'HIGH':
        return _PriorityStyle(accent: const Color(0xFFF59E0B), icon: Icons.notifications_active_rounded);
      case 'LOW':
        return _PriorityStyle(accent: const Color(0xFF6B7280), icon: Icons.info_outline_rounded);
      default:
        return _PriorityStyle(accent: const Color(0xFF6366F1), icon: Icons.campaign_rounded);
    }
  }
}

class _PriorityStyle {
  final Color accent;
  final IconData icon;
  _PriorityStyle({required this.accent, required this.icon});
}
