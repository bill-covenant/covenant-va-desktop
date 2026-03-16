import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

class ActionButtons3D extends StatefulWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const ActionButtons3D({
    super.key,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  State<ActionButtons3D> createState() => _ActionButtons3DState();
}

class _ActionButtons3DState extends State<ActionButtons3D> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() { _isHovered = false; _isPressed = false; }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onChangePassword,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 70,
          transform: Matrix4.translationValues(
            0, _isPressed ? 2 : (_isHovered ? -2 : 0), 0,
          ),
          decoration: BoxDecoration(
            color: ThemeProvider().isDarkMode ? const Color(0xFF1A1D2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: ThemeProvider().isDarkMode ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
            boxShadow: _isPressed
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ]
                : [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: _isHovered ? 24 : 20, offset: const Offset(0, 6)),
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                      BoxShadow(color: const Color(0xFF4C1D95).withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 14),
                Text(
                  'Change Password',
                  style: TextStyle(
                    color: ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _isHovered ? const Color(0xFF8B5CF6).withOpacity(0.08) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _isHovered ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF),
                    ),
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