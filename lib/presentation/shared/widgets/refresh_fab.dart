import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';

/// A consistent refresh button used across all screens.
/// Place it inline in a header Row — not positioned/floating.
class RefreshFAB extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const RefreshFAB({
    super.key,
    required this.onRefresh,
  });

  @override
  State<RefreshFAB> createState() => _RefreshFABState();
}

class _RefreshFABState extends State<RefreshFAB>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  bool _isHovered = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _rotationController.repeat();

    // Run refresh and minimum animation duration in parallel
    await Future.wait([
      widget.onRefresh(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    if (!mounted) return;
    _rotationController.stop();
    _rotationController.reset();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;
    final accentColor = const Color(0xFF8B5CF6);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleRefresh,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered || _isRefreshing
                  ? [accentColor, const Color(0xFF6366F1)]
                  : isDark
                      ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                      : [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered || _isRefreshing
                  ? accentColor.withOpacity(0.5)
                  : Colors.white.withOpacity(isDark ? 0.15 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered || _isRefreshing
                    ? accentColor.withOpacity(0.35)
                    : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
              if (_isHovered || _isRefreshing)
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 24,
                ),
            ],
          ),
          child: Center(
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.refresh_rounded,
                color: _isHovered || _isRefreshing
                    ? Colors.white
                    : Colors.white.withOpacity(isDark ? 0.7 : 0.9),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
