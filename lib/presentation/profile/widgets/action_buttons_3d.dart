import 'package:flutter/material.dart';

class ActionButtons3D extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const ActionButtons3D({
    super.key,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _build3DButton(
            onTap: onChangePassword,
            icon: Icons.lock,
            label: 'Change Password',
            gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
            glowColor: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _build3DButton(
            onTap: onLogout,
            icon: Icons.logout,
            label: 'Logout',
            gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            glowColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _build3DButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required Color glowColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(4, 4),
                blurRadius: 12,
              ),
              BoxShadow(
                color: glowColor.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient[0].withOpacity(0.9),
                  gradient[1].withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}