import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowIntensity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _progressOpacity;
  late Animation<double> _progressWidth;
  late Animation<double> _pulseScale;
  late Animation<double> _particleOpacity;

  @override
  void initState() {
    super.initState();

    // Main sequence controller (3.5 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Continuous pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Slow rotation for ring
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Glow animation
    _glowIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );

    // Particle fade in
    _particleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Title animations
    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.55, curve: Curves.easeOut),
      ),
    );

    // Subtitle animations
    _subtitleSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.65, curve: Curves.easeOut),
      ),
    );

    // Progress bar
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.7, curve: Curves.easeOut),
      ),
    );

    _progressWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.95, curve: Curves.easeInOut),
      ),
    );

    // Pulse scale
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController, _rotateController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0533),
                  Color(0xFF2d1b69),
                  Color(0xFF1a0533),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background orbs
                ..._buildBackgroundOrbs(),

                // Floating particles
                if (_particleOpacity.value > 0)
                  ..._buildFloatingParticles(),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rotating ring + Logo
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating ring
                            Transform.rotate(
                              angle: _rotateController.value * 2 * math.pi,
                              child: Opacity(
                                opacity: _glowIntensity.value * 0.6,
                                child: Container(
                                  width: 230,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 2,
                                    ),
                                    gradient: SweepGradient(
                                      colors: [
                                        const Color(0xFF7C3AED).withOpacity(0.0),
                                        const Color(0xFF7C3AED).withOpacity(0.8),
                                        const Color(0xFFEC4899).withOpacity(0.8),
                                        const Color(0xFFEC4899).withOpacity(0.0),
                                      ],
                                      stops: const [0.0, 0.3, 0.7, 1.0],
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Glow behind logo
                            Container(
                              width: 180 * _glowIntensity.value,
                              height: 180 * _glowIntensity.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.5 * _glowIntensity.value),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFEC4899).withOpacity(0.3 * _glowIntensity.value),
                                    blurRadius: 80,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),

                            // Logo with scale + pulse
                            Transform.scale(
                              scale: _logoScale.value * _pulseScale.value,
                              child: Opacity(
                                opacity: _logoOpacity.value,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Image.asset(
                                      'assets/images/fav3.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Title
                      Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFE0D0FF),
                                Colors.white,
                                Color(0xFFFFD0E8),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'CVA Desktop',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Transform.translate(
                        offset: Offset(0, _subtitleSlide.value),
                        child: Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Text(
                            'Virtual Assistant Portal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Progress bar
                      Opacity(
                        opacity: _progressOpacity.value,
                        child: SizedBox(
                          width: 200,
                          child: Column(
                            children: [
                              Container(
                                height: 3,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _progressWidth.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF7C3AED),
                                            Color(0xFFEC4899),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withOpacity(0.6),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.3),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Version at bottom
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _progressOpacity.value,
                    child: Text(
                      'v1.0.29',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBackgroundOrbs() {
    return [
      // Top-right orb
      Positioned(
        top: -80,
        right: -80,
        child: Opacity(
          opacity: _glowIntensity.value * 0.5,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      // Bottom-left orb
      Positioned(
        bottom: -100,
        left: -100,
        child: Opacity(
          opacity: _glowIntensity.value * 0.4,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEC4899).withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      // Center ambient
      Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: MediaQuery.of(context).size.width * 0.3,
        child: Opacity(
          opacity: _glowIntensity.value * 0.2,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.15),
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
    return List.generate(15, (index) {
      final size = 2.0 + random.nextDouble() * 3;
      final x = random.nextDouble() * MediaQuery.of(context).size.width;
      final y = random.nextDouble() * MediaQuery.of(context).size.height;
      final opacity = 0.1 + random.nextDouble() * 0.3;

      return Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: _particleOpacity.value * opacity,
          child: Transform.scale(
            scale: _pulseScale.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 2 == 0
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFFEC4899),
                boxShadow: [
                  BoxShadow(
                    color: (index % 2 == 0
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFEC4899))
                        .withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}