import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 1000),
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

    await widget.onRefresh();

    _rotationController.stop();
    _rotationController.reset();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleRefresh,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          const Color(0xFF8B5CF6),
                          const Color(0xFF6366F1),
                        ]
                      : [
                          Colors.white,
                          Colors.white.withOpacity(0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? const Color(0xFF8B5CF6).withOpacity(0.5)
                      : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  // Main shadow
                  BoxShadow(
                    color: _isHovered
                        ? const Color(0xFF8B5CF6).withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: _isHovered ? 20 : 15,
                    offset: Offset(0, _isHovered ? 8 : 6),
                    spreadRadius: 0,
                  ),
                  // Inner glow
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(-2, -2),
                    spreadRadius: 0,
                  ),
                  // Ambient glow
                  if (_isHovered)
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 0),
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _rotationController,
                    child: Icon(
                      Icons.refresh,
                      color: _isHovered
                          ? Colors.white
                          : const Color(0xFF8B5CF6),
                      size: 20,
                      shadows: _isHovered
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: _isHovered
                          ? Colors.white
                          : const Color(0xFF8B5CF6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: _isHovered
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}