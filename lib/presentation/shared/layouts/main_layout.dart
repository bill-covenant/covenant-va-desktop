import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covenant_va_desktop/presentation/shared/widgets/cross_hatch_pattern.dart';
import 'package:covenant_va_desktop/services/update_banner.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/socket_service.dart';
import '../../../services/update_service.dart';
import '../../../core/constants/api_constants.dart';
import '../widgets/layout/layout_sidebar_header.dart';
import '../widgets/layout/layout_sidebar_nav_item.dart';
import '../widgets/layout/layout_sidebar_footer.dart';
import '../widgets/layout/layout_notification_overlay.dart';

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
  UpdateInfo? _updateInfo;
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  // Badge counts
  int _messagesBadge = 0;
  int _tasksBadge = 0;
  int _timecardBadge = 0;
  int _announcementBadge = 0;
  Timer? _badgeTimer;

  static final String _apiBaseUrl = ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute;

    print('🔔 MainLayout: Setting up notification callback');
    SocketService().onNotification = _showNotificationBanner;

    _fetchBadgeCounts();
    _badgeTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchBadgeCounts());
    _checkForUpdate();
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

  @override
  void dispose() {
    _badgeTimer?.cancel();
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

      // Messages: unread count from Firestore
      try {
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final userData = json.decode(userJson);
          final userId = userData['id']?.toString() ?? '';
          if (userId.isNotEmpty) {
            final snapshot = await FirebaseFirestore.instance
                .collection('conversations')
                .where('participants', arrayContains: userId)
                .get();
            int totalUnread = 0;
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final unreadCounts = data['unreadCounts'] as Map<String, dynamic>?;
              if (unreadCounts != null) {
                totalUnread += (unreadCounts[userId] as int? ?? 0);
              }
            }
            if (mounted) setState(() => _messagesBadge = totalUnread);
          }
        }
      } catch (_) {}

      // Tasks: total count vs last seen
      try {
        final res = await http.get(
          Uri.parse('$_apiBaseUrl/tasks'),
          headers: headers,
        );
        if (res.statusCode == 200 && mounted) {
          final data = json.decode(res.body);
          final tasks = (data['tasks'] as List?) ?? [];
          final total = tasks.length;
          final lastSeen = prefs.getInt('badge_lastSeen_tasks') ?? 0;
          setState(() => _tasksBadge = (total - lastSeen).clamp(0, 999));
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
      if (mounted) setState(() => _messagesBadge = 0);
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
        // ── Wrap the entire body in the pattern overlay ──
        child: CrossHatchPatternOverlay(
          // You can tweak these values to taste:
          // lineSpacing: 18.0,  // distance between lines (smaller = denser)
          // strokeWidth: 0.5,   // line thickness
          // opacity: 0.04,      // 0.0–1.0 (keep it low for subtlety)
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
          _buildUpdateButton(),
          const SizedBox(height: 8),
          // Dark mode toggle
          _buildDarkModeToggle(),
          const SizedBox(height: 8),
          const LayoutSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
        Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (_isDownloading || _updateInfo == null) ? null : _checkForUpdate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _updateInfo != null
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _updateInfo != null
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: _isDownloading
                ? _buildDownloadProgress()
                : _updateInfo != null
                    ? _buildUpdateAvailable()
                    : _buildCheckForUpdates(),
          ),
        ),
      ),
      // Badge dot when update is available
      if (_updateInfo != null)
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0xFFEF4444), blurRadius: 6, spreadRadius: 0)],
            ),
            child: const Center(
              child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildCheckForUpdates() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CVA Desktop',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text('v${UpdateService.currentVersion}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateAvailable() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update v${_updateInfo!.version}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w700)),
              if (_updateInfo!.releaseNotes.isNotEmpty)
                Text(_updateInfo!.releaseNotes, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Downloading... ${(_downloadProgress * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final info = await UpdateService.checkForUpdate(_apiBaseUrl);
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
          _updateInfo = info?.updateAvailable == true ? info : null;
        });
        if (info == null || !info.updateAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('You\'re up to date! (v${UpdateService.currentVersion})'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ));
        } else {
          // Auto-start download for direct links
          _downloadAndInstall(info);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to check for updates'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    if (info.downloadUrl.isEmpty) return;

    final url = info.downloadUrl;
    // Direct installer download
    if (url.endsWith('.exe') || url.endsWith('.msi') || url.endsWith('.zip')) {
      setState(() { _isDownloading = true; _downloadProgress = 0; });
      try {
        final tempDir = await getTemporaryDirectory();
        final fileName = url.split('/').last;
        final filePath = '${tempDir.path}${Platform.pathSeparator}$fileName';
        final file = File(filePath);

        final request = http.Request('GET', Uri.parse(url));
        final response = await http.Client().send(request);
        final totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        final sink = file.openWrite();

        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalBytes > 0 && mounted) {
              setState(() => _downloadProgress = receivedBytes / totalBytes);
            }
          },
          onDone: () async {
            await sink.close();
            if (mounted) {
              setState(() { _isDownloading = false; _updateInfo = null; });
              await Process.start(filePath, [], mode: ProcessStartMode.detached);
              exit(0);
            }
          },
          onError: (e) async {
            await sink.close();
            if (mounted) setState(() { _isDownloading = false; _downloadProgress = 0; });
          },
        ).asFuture();
      } catch (e) {
        if (mounted) setState(() { _isDownloading = false; _downloadProgress = 0; });
      }
    } else {
      // Open browser for GitHub releases page etc.
      await UpdateService.openDownloadLink(url);
    }
  }

  Widget _buildDarkModeToggle() {
    final themeProvider = ThemeProvider();
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(themeProvider.isDarkMode ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(themeProvider.isDarkMode ? 0.2 : 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeProvider.isDarkMode
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (themeProvider.isDarkMode
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFF59E0B))
                          .withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dark Mode',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => themeProvider.toggleTheme(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: themeProvider.isDarkMode
                        ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                        : null,
                    color: themeProvider.isDarkMode ? null : Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.15),
                    ),
                    boxShadow: themeProvider.isDarkMode
                        ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8)]
                        : null,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: themeProvider.isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateTo(String route) {
    setState(() => _selectedRoute = route);
    _clearBadge(route);
    Navigator.pushReplacementNamed(context, '/$route');
  }
}