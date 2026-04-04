import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../shared/widgets/refresh_fab.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  /// Pre-warm cache from outside
  static void updateCache(List<AnnouncementModel> announcements) {
    _AnnouncementsScreenState._cachedAnnouncements = announcements;
    _AnnouncementsScreenState._lastFetchTime = DateTime.now();
  }

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<AnnouncementModel> _announcements = [];
  Set<String> _hiddenIds = {};
  bool _loading = false;
  String? _error;

  static List<AnnouncementModel>? _cachedAnnouncements;
  static DateTime? _lastFetchTime;
  static const _hiddenKey = 'hidden_announcement_ids';

  @override
  void initState() {
    super.initState();
    _loadHiddenIds();
    if (_cachedAnnouncements != null) {
      _announcements = _cachedAnnouncements!;
      _loading = false;
      if (_lastFetchTime == null ||
          DateTime.now().difference(_lastFetchTime!) > const Duration(seconds: 30)) {
        _fetchAnnouncements(showLoading: false);
      }
    } else {
      _fetchAnnouncements(showLoading: false);
    }
  }

  Future<void> _loadHiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_hiddenKey) ?? [];
    if (mounted) setState(() => _hiddenIds = ids.toSet());
  }

  Future<void> _hideAnnouncement(String id) async {
    setState(() => _hiddenIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenKey, _hiddenIds.toList());
  }

  Future<void> _fetchAnnouncements({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = GetIt.I<AnnouncementRepository>();
      final announcements = await repo.getPublishedAnnouncements();
      if (mounted) {
        _cachedAnnouncements = announcements;
        _lastFetchTime = DateTime.now();
        setState(() {
          _announcements = announcements;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && _announcements.isEmpty) {
        setState(() {
          _error = 'Failed to load announcements';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        return Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final dark = ThemeProvider().isDarkMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 32, 48, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'News & Updates',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white.withOpacity(0.95) : Colors.white,
                  shadows: dark ? [] : [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Latest announcements from Covenant VA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: dark ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.85),
                  shadows: dark ? [] : [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                ),
              ),
            ],
          ),
          const Spacer(),
          RefreshFAB(onRefresh: () => _fetchAnnouncements(showLoading: false)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final dark = ThemeProvider().isDarkMode;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: dark ? Colors.white : const Color(0xFF6366F1),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: dark ? Colors.white.withOpacity(0.4) : const Color(0xFF9CA3AF), size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: dark ? Colors.white.withOpacity(0.6) : const Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchAnnouncements,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_rounded, color: dark ? Colors.white.withOpacity(0.2) : const Color(0xFFD1D5DB), size: 64),
            const SizedBox(height: 16),
            Text(
              'No announcements yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white.withOpacity(0.5) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back later for news and updates',
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(50, 24, 48, 40),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 3;
            const spacing = 20.0;
            final cardWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

            final visible = _announcements.where((a) => !_hiddenIds.contains(a.id)).toList();
            final rows = <Widget>[];
            for (int i = 0; i < visible.length; i += crossAxisCount) {
              final rowItems = <Widget>[];
              for (int j = 0; j < crossAxisCount; j++) {
                if (i + j < visible.length) {
                  rowItems.add(SizedBox(width: cardWidth, child: _buildAnnouncementCard(visible[i + j])));
                } else {
                  rowItems.add(SizedBox(width: cardWidth));
                }
                if (j < crossAxisCount - 1) rowItems.add(const SizedBox(width: spacing));
              }
              rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowItems));
              if (i + crossAxisCount < _announcements.length) rows.add(const SizedBox(height: spacing));
            }

            return Column(children: rows);
          },
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final dark = ThemeProvider().isDarkMode;
    final colors = _priorityColors(announcement.priority);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF1E2235), const Color(0xFF171B2D)]
              : [Colors.white, const Color(0xFFF8F9FB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          if (!dark)
            BoxShadow(
              color: colors.accent.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Accent strip on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.accent, colors.accent.withOpacity(0.4)],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon with glow
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colors.accent, colors.accent.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(colors.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: dark ? Colors.white : const Color(0xFF1F2937),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.accent.withOpacity(dark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.accent.withOpacity(dark ? 0.25 : 0.15),
                          ),
                        ),
                        child: Text(
                          announcement.priority,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hide button
                      GestureDetector(
                        onTap: () => _hideAnnouncement(announcement.id),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: dark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.accent.withOpacity(0.2),
                          dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLinkedContent(
                    announcement.content,
                    TextStyle(
                      fontSize: 14,
                      color: dark ? Colors.white.withOpacity(0.7) : const Color(0xFF4B5563),
                      height: 1.65,
                    ),
                  ),
                  if (announcement.publishedAt != null) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: dark ? Colors.white.withOpacity(0.3) : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(announcement.publishedAt!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: dark ? Colors.white.withOpacity(0.35) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedContent(String text, TextStyle baseStyle) {
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          color: Color(0xFF8B5CF6),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF8B5CF6),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
