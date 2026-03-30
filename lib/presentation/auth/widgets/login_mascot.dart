import 'package:flutter/material.dart';
import 'dart:math' as math;

enum MascotState { idle, typing, loading, success, error }

class LoginMascot extends StatefulWidget {
  final MascotState state;
  final bool obscurePassword;

  const LoginMascot({
    super.key,
    this.state = MascotState.idle,
    this.obscurePassword = true,
  });

  @override
  State<LoginMascot> createState() => _LoginMascotState();
}

class _LoginMascotState extends State<LoginMascot>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late AnimationController _popController;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(LoginMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == MascotState.error) {
        _shakeController.forward(from: 0);
      }
      if (widget.state == MascotState.success) {
        _popController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    _popController.dispose();
    super.dispose();
  }

  String _getAssetPath() {
    switch (widget.state) {
      case MascotState.idle:
        return 'assets/images/mascot/idle.png';
      case MascotState.typing:
        return widget.obscurePassword
            ? 'assets/images/mascot/typing.png'
            : 'assets/images/mascot/peeking.png';
      case MascotState.loading:
        return 'assets/images/mascot/loading.png';
      case MascotState.success:
        return 'assets/images/mascot/success.png';
      case MascotState.error:
        return 'assets/images/mascot/error.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceController, _shakeController, _popController]),
      builder: (context, _) {
        // Shake for error
        final shakeOffset = _shakeController.isAnimating
            ? math.sin(_shakeController.value * math.pi * 6) * 10
            : 0.0;

        // Gentle bounce for idle
        final bounceOffset = widget.state == MascotState.idle
            ? math.sin(_bounceController.value * math.pi) * 4
            : 0.0;

        // Pop scale for success
        final popScale = widget.state == MascotState.success && _popController.isAnimating
            ? 1.0 + math.sin(_popController.value * math.pi) * 0.15
            : 1.0;

        return Transform.translate(
          offset: Offset(shakeOffset, -bounceOffset),
          child: Transform.scale(
            scale: popScale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Image.asset(
                _getAssetPath(),
                key: ValueKey(_getAssetPath()),
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
