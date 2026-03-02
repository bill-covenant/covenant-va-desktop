import 'package:covenant_va_desktop/services/update_banner.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
            ],
          ),
        ),
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
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.2),
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
          const LayoutSidebarFooter(),
        ],
      ),
    );
  }

  void _navigateTo(String route) {
    setState(() {
      _selectedRoute = route;
    });
    Navigator.pushReplacementNamed(context, '/$route');
  }
}