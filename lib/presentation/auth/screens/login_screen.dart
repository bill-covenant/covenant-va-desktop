import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/cross_hatch_pattern.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0520),
                Color(0xFF1A0A35),
                Color(0xFF12082A),
              ],
            ),
          ),
          child: CrossHatchPatternOverlay(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _rotateController]),
              builder: (context, _) {
                return Stack(
                  children: [
                    // Background orbs (like splash)
                    ..._buildBackgroundOrbs(),

                    // Floating particles
                    ..._buildFloatingParticles(),

                    // Login card
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Stack(
                          children: [
                            // Card shadow
                            Positioned.fill(
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                                      blurRadius: 80,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFEC4899).withOpacity(0.2),
                                      blurRadius: 60,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Card with spinning border
                            SizedBox(
                              width: 484,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(34),
                                ),
                                child: CustomPaint(
                                  painter: _SpinningBorderPainter(
                                    angle: _rotateController.value * 2 * math.pi,
                                    borderRadius: 34,
                                    strokeWidth: 4,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(31),
                                        color: const Color(0xFF1A1030),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                                            blurRadius: 40,
                                            offset: const Offset(0, 12),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.5),
                                            blurRadius: 28,
                                            offset: const Offset(12, 12),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(31),
                                        child: Container(
                                          padding: const EdgeInsets.all(48),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Logo with rotating ring + pulse
                                      SizedBox(
                                        width: 160,
                                        height: 160,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Rotating ring
                                            Transform.rotate(
                                              angle: _rotateController.value * 2 * math.pi,
                                              child: Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: SweepGradient(
                                                    colors: [
                                                      const Color(0xFF7C3AED).withOpacity(0.0),
                                                      const Color(0xFF7C3AED).withOpacity(0.5),
                                                      const Color(0xFFEC4899).withOpacity(0.5),
                                                      const Color(0xFFEC4899).withOpacity(0.0),
                                                    ],
                                                    stops: const [0.0, 0.3, 0.7, 1.0],
                                                  ),
                                                ),
                                                child: Container(
                                                  margin: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xFF1A1030),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Glow behind logo
                                            Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                    blurRadius: 40,
                                                    spreadRadius: 10,
                                                  ),
                                                  BoxShadow(
                                                    color: const Color(0xFFEC4899).withOpacity(0.15),
                                                    blurRadius: 50,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Logo with pulse
                                            Transform.scale(
                                              scale: _pulseScale.value,
                                              child: Container(
                                                width: 130,
                                                height: 130,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white.withOpacity(0.9),
                                                      Colors.white.withOpacity(0.6),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.6),
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.primary.withOpacity(0.4),
                                                      blurRadius: 40,
                                                      spreadRadius: 5,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                    BoxShadow(
                                                      color: const Color(0xFFEC4899).withOpacity(0.2),
                                                      blurRadius: 30,
                                                      spreadRadius: 2,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(18),
                                                  child: Image.asset(
                                                    'assets/images/fav.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.secondary,
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          'Covenant VA',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        'Virtual Assistant Portal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.5),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 48),

                                          const LoginForm(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundOrbs() {
    return [
      // Top-left — deep purple glow
      Positioned(
        top: -120,
        left: -100,
        child: Container(
          width: 450,
          height: 450,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF7C3AED).withOpacity(0.25),
                const Color(0xFF5B21B6).withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Top-right — soft indigo
      Positioned(
        top: -80,
        right: -120,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4F46E5).withOpacity(0.2),
                const Color(0xFF6366F1).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Bottom-left — fuchsia accent
      Positioned(
        bottom: -100,
        left: -60,
        child: Container(
          width: 380,
          height: 380,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFA855F7).withOpacity(0.15),
                const Color(0xFFC084FC).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Bottom-right — subtle blue
      Positioned(
        bottom: -80,
        right: -80,
        child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF3B82F6).withOpacity(0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Center — subtle warm glow behind card
      Positioned.fill(
        child: Center(
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFloatingParticles() {
    final random = math.Random(42);
    final size = MediaQuery.of(context).size;
    return List.generate(25, (index) {
      final dotSize = 2.5 + random.nextDouble() * 4.5;
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = 0.3 + random.nextDouble() * 0.5;

      return Positioned(
        left: x,
        top: y,
        child: Transform.scale(
          scale: _pulseScale.value,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index % 3 == 0
                  ? Colors.white.withOpacity(opacity)
                  : index % 3 == 1
                      ? const Color(0xFFF0ABFC).withOpacity(opacity * 0.7)
                      : const Color(0xFFC4B5FD).withOpacity(opacity * 0.7),
              boxShadow: [
                BoxShadow(
                  color: (index % 3 == 0
                          ? Colors.white
                          : index % 3 == 1
                              ? const Color(0xFFF0ABFC)
                              : const Color(0xFFC4B5FD))
                      .withOpacity(opacity * 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SpinningBorderPainter extends CustomPainter {
  final double angle;
  final double borderRadius;
  final double strokeWidth;

  _SpinningBorderPainter({
    required this.angle,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(angle),
        colors: const [
          Color(0x00FFFFFF), // transparent
          Color(0xFFFFFFFF), // white
          Color(0xFFE9D5FF), // purple-200
          Color(0xFFF0ABFC), // fuchsia-300
          Color(0x00F0ABFC), // transparent
          Color(0x00F0ABFC), // transparent
          Color(0xFFF0ABFC), // fuchsia-300
          Color(0xFFE9D5FF), // purple-200
          Color(0xFFFFFFFF), // white
          Color(0x00FFFFFF), // transparent
        ],
        stops: const [0.0, 0.1, 0.15, 0.2, 0.3, 0.7, 0.8, 0.85, 0.9, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpinningBorderPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
