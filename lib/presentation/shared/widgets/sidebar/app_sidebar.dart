import 'package:flutter/material.dart';
import 'sidebar_header.dart';
import 'sidebar_nav_item.dart';
import 'sidebar_notification_item.dart';
import 'sidebar_footer.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final Function(String)? onNavigate;

  const AppSidebar({
    super.key,
    this.currentRoute = 'dashboard',
    this.onNavigate,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  late String _selectedRoute;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.currentRoute;
  }

  void _handleNavigation(String route) {
    setState(() {
      _selectedRoute = route;
    });
    widget.onNavigate?.call(route);
  }

  @override
  Widget build(BuildContext context) {
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
          const SidebarHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: _buildNavigation(),
          ),
          const SidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SidebarNavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: _selectedRoute == 'dashboard',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          const SizedBox(height: 8),
          SidebarNavItem(
            icon: Icons.task_alt,
            label: 'My Tasks',
            isSelected: _selectedRoute == 'tasks',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/tasks');
            },
          ),
          const SizedBox(height: 8),
          SidebarNavItem(
            icon: Icons.message,
            label: 'Messages',
            isSelected: _selectedRoute == 'messages',
            badge: 3,
            onTap: () {
              Navigator.pushReplacementNamed(context, '/messages');
            },
          ),
          const SizedBox(height: 8),
          SidebarNotificationItem(
            isSelected: _selectedRoute == 'notifications',
          ),
          const SizedBox(height: 8),
          SidebarNavItem(
            icon: Icons.person,
            label: 'Profile',
            isSelected: _selectedRoute == 'profile',
            onTap: () => _handleNavigation('profile'),
          ),
        ],
      ),
    );
  }
}