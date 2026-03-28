import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covenant_va_desktop/presentation/shared/widgets/cross_hatch_pattern.dart';
import 'package:covenant_va_desktop/services/update_banner.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/socket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../widgets/layout/layout_sidebar_header.dart';
import '../widgets/layout/layout_sidebar_nav_item.dart';
import '../widgets/layout/layout_sidebar_footer.dart';
import '../widgets/layout/layout_notification_overlay.dart';
import '../widgets/layout/layout_update_section.dart';
import '../widgets/layout/layout_dark_mode_toggle.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    this.currentRoute = 'dashboard',
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _selectedRoute = 'dashboard';

  // Badge counts
  int _messagesBadge = 0;
  int _tasksBadge = 0;
  int _timecardBadge = 0;
  int _announcementBadge = 0;
  Timer? _badgeTimer;
  StreamSubscription? _messagesStreamSub;
  static int _lastKnownUnread = -1; // -1 means first load, don't trigger notification

  static final String _apiBaseUrl = ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute;

    print('🔔 MainLayout: Setting up notification callback');
    final socketService = SocketService();
    socketService.onNotification = (title, body) {
      _showNotificationBanner(title, body);
      // If it's a task notification, increment badge immediately
      if (title.contains('Task') && _selectedRoute != 'tasks') {
        if (mounted) setState(() => _tasksBadge++);
      }
      // Refresh other badges
      if (mounted) _fetchBadgeCounts();
    };

    // Refresh badges when announcements arrive via socket
    socketService.onAnnouncementUpdate = () {
      if (mounted) _fetchBadgeCounts();
    };

    _fetchBadgeCounts();
    _listenToMessagesStream();
    _badgeTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchBadgeCounts());
  }

  void _showNotificationBanner(String title, String body) {
    if (mounted) {
      LayoutNotificationOverlay.show(
        context,
        title: title,
        body: body,
      );
    }
  }

  /// Listen to Firestore conversations for real-time message notifications
  Future<void> _listenToMessagesStream() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson == null) return;

      final userData = json.decode(userJson);
      final userId = userData['id']?.toString() ?? '';
      if (userId.isEmpty) return;

      _messagesStreamSub = FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .snapshots()
          .listen((snapshot) {
        int totalUnread = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final unreadCounts = data['unreadCounts'] as Map<String, dynamic>? ?? {};
          totalUnread += (unreadCounts[userId] as num?)?.toInt() ?? 0;
        }

        // Show notification if unread count increased (new message arrived)
        if (totalUnread > _lastKnownUnread && _lastKnownUnread >= 0) {
          // Don't show notification if we're on the messages screen
          if (_selectedRoute != 'messages') {
            _showNotificationBanner('New Message 💬', 'You have a new message');
          }
        }

        _lastKnownUnread = totalUnread;
        if (mounted) setState(() => _messagesBadge = totalUnread);
      }, onError: (e) {
        // Silently handle permission errors during logout
        print('⚠️ Firestore stream error (expected during logout): $e');
      });
    } catch (e) {
      print('⚠️ Failed to listen to messages stream: $e');
    }
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _messagesStreamSub?.cancel();
    LayoutNotificationOverlay.dismiss();
    super.dispose();
  }

  Future<void> _fetchBadgeCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Messages: handled by real-time Firestore stream (_listenToMessagesStream)

      // Tasks: total count vs last seen
      try {
        final res = await http.get(
          Uri.parse('$_apiBaseUrl/tasks'),
          headers: headers,
        );
        if (res.statusCode == 200 && mounted) {
          final data = json.decode(res.body);
          final tasks = (data['tasks'] as List?) ?? [];
          final activeTasks = tasks.where((t) => t['status'] != 'ARCHIVED').toList();
          final total = activeTasks.length;
          final lastSeen = prefs.getInt('badge_lastSeen_tasks') ?? 0;
          final countBadge = (total - lastSeen).clamp(0, 999);
          // Keep the higher value — socket events may have incremented it
          if (countBadge > _tasksBadge) {
            setState(() => _tasksBadge = countBadge);
          }
        }
      } catch (_) {}

      // Timecard: approved entries vs last seen
      try {
        final res = await http.get(
          Uri.parse('$_apiBaseUrl/timecard/entries'),
          headers: headers,
        );
        if (res.statusCode == 200 && mounted) {
          final data = json.decode(res.body);
          final entries = (data['entries'] as List?) ?? [];
          final approvedCount = entries.where((e) => e['status'] == 'APPROVED').length;
          final lastSeen = prefs.getInt('badge_lastSeen_timecard') ?? 0;
          setState(() => _timecardBadge = (approvedCount - lastSeen).clamp(0, 999));
        }
      } catch (_) {}

      // Announcements: total count vs last seen
      try {
        final res = await http.get(
          Uri.parse('$_apiBaseUrl/announcements/published'),
          headers: headers,
        );
        if (res.statusCode == 200 && mounted) {
          final data = json.decode(res.body);
          final announcements = (data['announcements'] as List?) ?? [];
          final total = announcements.length;
          final lastSeen = prefs.getInt('badge_lastSeen_announcements') ?? 0;
          setState(() => _announcementBadge = (total - lastSeen).clamp(0, 999));
        }
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _clearBadge(String route) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };

    if (route == 'messages') {
      // Don't force to 0 — re-fetch after a short delay to reflect
      // conversations that get marked as read when opened
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _fetchBadgeCounts();
      });
    }

    if (route == 'tasks') {
      if (mounted) setState(() => _tasksBadge = 0);
      try {
        final res = await http.get(Uri.parse('$_apiBaseUrl/tasks'), headers: headers);
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final total = ((data['tasks'] as List?) ?? []).length;
          await prefs.setInt('badge_lastSeen_tasks', total);
        }
      } catch (_) {}
    }

    if (route == 'timecard') {
      if (mounted) setState(() => _timecardBadge = 0);
      try {
        final res = await http.get(Uri.parse('$_apiBaseUrl/timecard/entries'), headers: headers);
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final entries = (data['entries'] as List?) ?? [];
          final approvedCount = entries.where((e) => e['status'] == 'APPROVED').length;
          await prefs.setInt('badge_lastSeen_timecard', approvedCount);
        }
      } catch (_) {}
    }

    if (route == 'announcements') {
      if (mounted) setState(() => _announcementBadge = 0);
      try {
        final res = await http.get(Uri.parse('$_apiBaseUrl/announcements/published'), headers: headers);
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final total = ((data['announcements'] as List?) ?? []).length;
          await prefs.setInt('badge_lastSeen_announcements', total);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
    final isDark = ThemeProvider().isDarkMode;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1117), const Color(0xFF1A1025)]
                : [const Color(0xFF7C3AED), const Color(0xFFEC4899)],
          ),
        ),
        child: CrossHatchPatternOverlay(
          child: Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    UpdateBanner(apiBaseUrl: _apiBaseUrl),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildSidebar() {
    final isDark = ThemeProvider().isDarkMode;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF0F1117),
                  const Color(0xFF1A1025),
                ]
              : [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const LayoutSidebarHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  LayoutSidebarNavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: 'dashboard',
                    isSelected: _selectedRoute == 'dashboard',
                    onTap: () => _navigateTo('dashboard'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.task_alt,
                    label: 'My Tasks',
                    route: 'tasks',
                    isSelected: _selectedRoute == 'tasks',
                    badge: _tasksBadge > 0 ? _tasksBadge : null,
                    onTap: () => _navigateTo('tasks'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Notes',
                    route: 'notes',
                    isSelected: _selectedRoute == 'notes',
                    onTap: () => _navigateTo('notes'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.message,
                    label: 'Messages',
                    route: 'messages',
                    isSelected: _selectedRoute == 'messages',
                    badge: _messagesBadge > 0 ? _messagesBadge : null,
                    onTap: () => _navigateTo('messages'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.access_time_rounded,
                    label: 'Timecard',
                    route: 'timecard',
                    isSelected: _selectedRoute == 'timecard',
                    badge: _timecardBadge > 0 ? _timecardBadge : null,
                    onTap: () => _navigateTo('timecard'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.archive_rounded,
                    label: 'Archive',
                    route: 'archive',
                    isSelected: _selectedRoute == 'archive',
                    onTap: () => _navigateTo('archive'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.campaign_rounded,
                    label: 'Announcements',
                    route: 'announcements',
                    isSelected: _selectedRoute == 'announcements',
                    badge: _announcementBadge > 0 ? _announcementBadge : null,
                    onTap: () => _navigateTo('announcements'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    route: 'profile',
                    isSelected: _selectedRoute == 'profile',
                    onTap: () => _navigateTo('profile'),
                  ),
                ],
              ),
            ),
          ),
          // Update button
          LayoutUpdateSection(apiBaseUrl: _apiBaseUrl),
          const SizedBox(height: 8),
          // Dark mode toggle
          const LayoutDarkModeToggle(),
          const SizedBox(height: 8),
          const LayoutSidebarFooter(),
        ],
      ),
    );
  }

  void _navigateTo(String route) {
    setState(() => _selectedRoute = route);
    _clearBadge(route);
    Navigator.pushReplacementNamed(context, '/$route');
  }
}
