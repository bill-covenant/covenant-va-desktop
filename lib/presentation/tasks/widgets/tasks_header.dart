import 'package:flutter/material.dart';

class TasksHeader extends StatelessWidget {
  final Widget? trailing;
  const TasksHeader({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
      child: Row(
        children: [
          _build3DIcon(),
          const SizedBox(width: 16),
          _build3DText(),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _build3DIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.5),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            offset: const Offset(-2, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildShineEffect(),
          _buildIcon(),
        ],
      ),
    );
  }

  Widget _buildShineEffect() {
    return Positioned(
      top: 4,
      left: 4,
      right: 20,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.0),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: Icon(
        Icons.task_alt,
        color: Colors.white,
        size: 28,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _build3DText() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Colors.white,
          Color(0xFFE0E7FF),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'My Tasks',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
            Shadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.5),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}