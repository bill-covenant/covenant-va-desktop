import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covenant_va_desktop/presentation/shared/widgets/cross_hatch_pattern.dart';
import 'package:covenant_va_desktop/services/update_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/socket_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/providers/api_provider.dart';
import '../widgets/layout/layout_sidebar_header.dart';
import '../widgets/layout/layout_sidebar_nav_item.dart';
import '../widgets/layout/layout_sidebar_footer.dart';
import '../widgets/layout/layout_notification_overlay.dart';
import '../widgets/layout/layout_dark_mode_toggle.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../tasks/screens/my_tasks_screen.dart';
import '../../tasks/screens/archive_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../notes/bloc/notes_bloc.dart';
import '../../profile/screens/profile_screen.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../timecard/bloc/timecard_bloc.dart';
import '../../timecard/screens/timecard_screen.dart';
import '../../crm/screens/crm_screen.dart';
import '../../crm/bloc/crm_bloc.dart';
import '../../lead_tracker/screens/lead_tracker_screen.dart';
import '../../lead_tracker/bloc/lead_tracker_bloc.dart';

/// The persistent app shell: sidebar + content area.
///
/// One MainLayout stays mounted while the user moves between screens — the
/// sidebar only swaps the content widget (via [MainLayout.navigateTo]) instead
/// of pushing a new route. That keeps the Firestore unread listener, socket
/// callbacks, badge timer and sidebar state alive across navigations, so a
/// click no longer re-subscribes / re-fetches everything.
///
/// Named routes (`/tasks`, `/messages`, …) still exist for deep links and for
/// restoring the last screen; each simply opens a shell on that screen.
class MainLayout extends StatefulWidget {
  /// The screen shown when the shell is first mounted.
  final String currentRoute;

  const MainLayout({
    super.key,
    this.currentRoute = 'dashboard',
  });

  /// Screens the shell can show (route names without the leading slash).
  static const List<String> routes = [
    'dashboard', 'tasks', 'notes', 'messages', 'timecard', 'crm',
    'lead-tracker', 'archive', 'announcements', 'profile',
  ];

  /// Switch the shell's content to [route] (e.g. `'messages'`).
  /// Falls back to a named-route replacement when called outside a shell.
  static void navigateTo(BuildContext context, String route) {
    final shell = context.findAncestorStateOfType<_MainLayoutState>();
    if (shell != null) {
      shell._navigateTo(route);
    } else {
      Navigator.pushReplacementNamed(context, '/$route');
    }
  }

  /// Builds the content widget for [route], including any screen-scoped
  /// BLoC it needs. Called once per visit (not on every shell rebuild).
  static Widget buildPage(String route) {
    switch (route) {
      case 'tasks':
        return const MyTasksScreen();
      case 'notes':
        // Global singleton BLoC — cache persists across navigations.
        return BlocProvider.value(
          value: getIt<NotesBloc>(),
          child: const NotesScreen(),
        );
      case 'messages':
        return const MessagesScreen();
      case 'timecard':
        return BlocProvider(
          create: (context) => getIt<TimecardBloc>(),
          child: const TimecardScreen(clientId: ''),
        );
      case 'profile':
        return const ProfileScreen();
      case 'archive':
        return const ArchiveScreen();
      case 'announcements':
        return const AnnouncementsScreen();
      case 'crm':
        return BlocProvider(
          create: (context) => getIt<CrmBloc>(),
          child: const CrmScreen(),
        );
      case 'lead-tracker':
        return BlocProvider(
          create: (context) => getIt<LeadTrackerBloc>(),
          child: const LeadTrackerScreen(),
        );
      case 'dashboard':
      default:
        // DashboardScreen decides whether to load (30s throttle) — the
        // bloc is created idle so a quick revisit shows the cached dashboard.
        return BlocProvider(
          create: (context) => getIt<DashboardBloc>(),
          child: const DashboardScreen(),
        );
    }
  }

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedRoute = 'dashboard';

  // Current content. Built only when the route changes, so shell rebuilds
  // (badges, theme, auth refresh) don't rebuild the whole screen subtree.
  late Widget _page;
  // Bumped on every navigation so re-selecting the current item reloads it
  // (same as the old pushReplacementNamed behaviour).
  int _pageSerial = 0;

  // Badge counts
  int _messagesBadge = 0;
  int _tasksBadge = 0;
  int _timecardBadge = 0;
  int _announcementBadge = 0;
  Timer? _badgeTimer;
  StreamSubscription? _messagesStreamSub;
  static int _lastKnownUnread = -1; // -1 means first load, don't trigger notification

  // Last /me/badge-counts response (totals used for the "last seen" marks).
  _BadgeTotals? _lastTotals;

  static const _badgeCountsTimeout = Duration(seconds: 15);
  static const _lastSeenTasksKey = 'badge_lastSeen_tasks';
  // New key: the value is now the total entry count (was the approved count).
  static const _lastSeenTimeEntriesKey = 'badge_lastSeen_timeEntries';
  static const _lastSeenAnnouncementsKey = 'badge_lastSeen_announcements';

  static final String _apiBaseUrl = ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _selectedRoute = MainLayout.routes.contains(widget.currentRoute)
        ? widget.currentRoute
        : 'dashboard';
    _page = _buildPage();

    debugPrint('🔔 MainLayout: Setting up notification callback');
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

    // Keep task update callback always active for real-time task refresh
    socketService.onTaskUpdate = () {
      if (mounted) {
        _fetchBadgeCounts();
        // Clear task cache so next visit to My Tasks shows fresh data
        MyTasksScreen.clearCache();
      }
    };

    _fetchBadgeCounts();
    _listenToMessagesStream();
    _badgeTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchBadgeCounts());
  }

  Widget _buildPage() {
    return KeyedSubtree(
      key: ValueKey('$_selectedRoute#$_pageSerial'),
      child: MainLayout.buildPage(_selectedRoute),
    );
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
      if (!mounted) return;

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
        if (mounted && _messagesBadge != totalUnread) {
          setState(() => _messagesBadge = totalUnread);
        }
      }, onError: (e) {
        // Silently handle permission errors during logout
        debugPrint('⚠️ Firestore stream error (expected during logout): $e');
      });
    } catch (e) {
      debugPrint('⚠️ Failed to listen to messages stream: $e');
    }
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _messagesStreamSub?.cancel();
    LayoutNotificationOverlay.dismiss();
    super.dispose();
  }

  /// One cheap request (GET /me/badge-counts) instead of downloading the full
  /// task, time-entry and announcement lists just to count them.
  Future<_BadgeTotals?> _requestBadgeTotals() async {
    try {
      final data = await getIt<ApiProvider>()
          .get('/me/badge-counts', requiresAuth: true, forceRefresh: true)
          .timeout(_badgeCountsTimeout);
      final totals = _BadgeTotals.fromJson(data);
      _lastTotals = totals;
      return totals;
    } catch (e) {
      debugPrint('⚠️ Badge counts request failed: $e');
      return null;
    }
  }

  Future<void> _fetchBadgeCounts() async {
    // Messages: handled by real-time Firestore stream (_listenToMessagesStream)
    final totals = await _requestBadgeTotals();
    if (totals == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      // Tasks: active (non-archived) total vs last seen
      final lastSeenTasks = prefs.getInt(_lastSeenTasksKey) ?? 0;
      final tasksBadge = (totals.activeTasks - lastSeenTasks).clamp(0, 999);

      // Timecard: total entries vs last seen. First run with the new key —
      // take the current total as the baseline instead of badging everything.
      var lastSeenEntries = prefs.getInt(_lastSeenTimeEntriesKey);
      if (lastSeenEntries == null) {
        lastSeenEntries = totals.timeEntries;
        await prefs.setInt(_lastSeenTimeEntriesKey, lastSeenEntries);
      }
      final timecardBadge = (totals.timeEntries - lastSeenEntries).clamp(0, 999);

      // Announcements: published total vs last seen
      final lastSeenAnnouncements = prefs.getInt(_lastSeenAnnouncementsKey) ?? 0;
      final announcementBadge =
          (totals.announcements - lastSeenAnnouncements).clamp(0, 999);

      if (!mounted) return;
      // Keep the higher task value — socket events may have incremented it.
      final newTasksBadge = tasksBadge > _tasksBadge ? tasksBadge : _tasksBadge;
      if (newTasksBadge != _tasksBadge ||
          timecardBadge != _timecardBadge ||
          announcementBadge != _announcementBadge) {
        setState(() {
          _tasksBadge = newTasksBadge;
          _timecardBadge = timecardBadge;
          _announcementBadge = announcementBadge;
        });
      }
    } catch (_) {}
  }

  /// Marks the current totals as "seen" for [route]. Uses the (cheap) badge
  /// counts endpoint — never re-downloads the lists.
  Future<void> _clearBadge(String route) async {
    String? key;
    int Function(_BadgeTotals t)? pick;

    // Messages: the Firestore stream updates the badge as conversations are read.
    if (route == 'tasks') {
      if (mounted && _tasksBadge != 0) setState(() => _tasksBadge = 0);
      key = _lastSeenTasksKey;
      pick = (t) => t.activeTasks;
    } else if (route == 'timecard') {
      if (mounted && _timecardBadge != 0) setState(() => _timecardBadge = 0);
      key = _lastSeenTimeEntriesKey;
      pick = (t) => t.timeEntries;
    } else if (route == 'announcements') {
      if (mounted && _announcementBadge != 0) setState(() => _announcementBadge = 0);
      key = _lastSeenAnnouncementsKey;
      pick = (t) => t.announcements;
    }
    if (key == null || pick == null) return;

    try {
      // Prefer fresh totals (something may have arrived since the last poll);
      // fall back to the last known ones if the request fails.
      final totals = await _requestBadgeTotals() ?? _lastTotals;
      if (totals == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, pick(totals));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Auth guard: redirect to login if not authenticated
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
    final isDark = ThemeProvider().isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    final gradient = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF0F1117), const Color(0xFF1A1025)]
            : [const Color(0xFF7C3AED), const Color(0xFFEC4899)],
      ),
    );

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          width: 280,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F1117), const Color(0xFF1A1025)]
                    : [const Color(0xFF7C3AED), const Color(0xFFEC4899)],
              ),
            ),
            child: _buildSidebarContent(),
          ),
        ),
        body: Container(
          decoration: gradient,
          child: CrossHatchPatternOverlay(
            child: Column(
              children: [
                // Mobile top bar
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    right: 12,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getRouteLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                UpdateBanner(apiBaseUrl: _apiBaseUrl),
                Expanded(child: _page),
              ],
            ),
          ),
        ),
      );
    }

    // Desktop layout — fixed sidebar
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: gradient,
        child: CrossHatchPatternOverlay(
          child: Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    UpdateBanner(apiBaseUrl: _apiBaseUrl),
                    Expanded(child: _page),
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

  String _getRouteLabel() {
    const labels = {
      'dashboard': 'Dashboard',
      'tasks': 'My Tasks',
      'notes': 'Notes',
      'messages': 'Messages',
      'timecard': 'Timecard',
      'archive': 'Archive',
      'announcements': 'Announcements',
      'profile': 'Profile',
      'crm': 'Flooring Liquidators',
      'lead-tracker': 'Lead Tracker',
    };
    return labels[_selectedRoute] ?? 'Dashboard';
  }

  Widget _buildSidebarContent() {
    final authState = context.read<AuthBloc>().state;
    final hasCrmAccess = authState is AuthAuthenticated && authState.user.hasCrmAccess;
    final hasLeadTrackerAccess = authState is AuthAuthenticated && authState.user.hasLeadTrackerAccess;

    return Column(
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
                if (hasCrmAccess) ...[
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.people_rounded,
                    label: 'Flooring Liquidators',
                    route: 'crm',
                    isSelected: _selectedRoute == 'crm',
                    onTap: () => _navigateTo('crm'),
                  ),
                ],
                if (hasLeadTrackerAccess) ...[
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Lead Tracker',
                    route: 'lead-tracker',
                    isSelected: _selectedRoute == 'lead-tracker',
                    onTap: () => _navigateTo('lead-tracker'),
                  ),
                ],
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
        const LayoutDarkModeToggle(),
        const SizedBox(height: 8),
        const LayoutSidebarFooter(),
      ],
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
              ? [const Color(0xFF0F1117), const Color(0xFF1A1025)]
              : [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: _buildSidebarContent(),
    );
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    if (!MainLayout.routes.contains(route)) route = 'dashboard';

    // Close drawer on mobile before switching content
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
    _clearBadge(route);
    _saveLastRoute(route);
    setState(() {
      _selectedRoute = route;
      _pageSerial++;
      _page = _buildPage();
    });
  }

  Future<void> _saveLastRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_route', route);
    } catch (_) {}
  }
}

/// Totals from GET /me/badge-counts that the sidebar badges compare against
/// their stored "last seen" values.
class _BadgeTotals {
  final int activeTasks;
  final int timeEntries;
  final int announcements;

  const _BadgeTotals({
    required this.activeTasks,
    required this.timeEntries,
    required this.announcements,
  });

  static int _int(dynamic v) => v is num ? v.toInt() : 0;

  factory _BadgeTotals.fromJson(Map<String, dynamic> json) {
    final tasks = json['tasks'] is Map ? json['tasks'] as Map : const {};
    final byStatus = tasks['byStatus'] is Map ? tasks['byStatus'] as Map : const {};
    final timeEntries = json['timeEntries'] is Map ? json['timeEntries'] as Map : const {};
    final announcements = json['announcements'] is Map ? json['announcements'] as Map : const {};
    // The sidebar counts active tasks only (archived ones don't badge).
    final activeTasks = _int(tasks['total']) - _int(byStatus['ARCHIVED']);
    return _BadgeTotals(
      activeTasks: activeTasks < 0 ? 0 : activeTasks,
      timeEntries: _int(timeEntries['total']),
      announcements: _int(announcements['published']),
    );
  }
}
