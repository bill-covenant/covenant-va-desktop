import 'package:covenant_va_desktop/presentation/shared/widgets/cross_hatch_pattern.dart';
import 'package:covenant_va_desktop/services/update_banner.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/socket_service.dart';
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

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute;

    print('🔔 MainLayout: Setting up notification callback');
    SocketService().onNotification = _showNotificationBanner;
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
    LayoutNotificationOverlay.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    onTap: () => _navigateTo('messages'),
                  ),
                  const SizedBox(height: 8),
                  LayoutSidebarNavItem(
                    icon: Icons.access_time_rounded,
                    label: 'Timecard',
                    route: 'timecard',
                    isSelected: _selectedRoute == 'timecard',
                    onTap: () => _navigateTo('timecard'),
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
          // Dark mode toggle
          _buildDarkModeToggle(),
          const SizedBox(height: 8),
          const LayoutSidebarFooter(),
        ],
      ),
    );
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
    setState(() {
      _selectedRoute = route;
    });
    Navigator.pushReplacementNamed(context, '/$route');
  }
}