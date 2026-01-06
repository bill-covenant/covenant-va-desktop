import 'package:flutter/material.dart';

class TasksSkeletonLoading extends StatelessWidget {
  const TasksSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonFilterBar(),
          const SizedBox(height: 20),
          _buildSkeletonBox(width: 100, height: 20),
          const SizedBox(height: 20),
          _buildSkeletonTaskCard(),
          const SizedBox(height: 16),
          _buildSkeletonTaskCard(),
          const SizedBox(height: 16),
          _buildSkeletonTaskCard(),
        ],
      ),
    );
  }

  Widget _buildSkeletonFilterBar() {
    return Row(
      children: [
        _buildSkeletonBox(width: 150, height: 40),
        const SizedBox(width: 12),
        _buildSkeletonBox(width: 150, height: 40),
        const SizedBox(width: 12),
        Expanded(child: _buildSkeletonBox(height: 40)),
      ],
    );
  }

  Widget _buildSkeletonBox({double? width, required double height}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1 * value),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonTaskCard() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05 * value),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1 * value),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1 * value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1 * value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1 * value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05 * value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05 * value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}