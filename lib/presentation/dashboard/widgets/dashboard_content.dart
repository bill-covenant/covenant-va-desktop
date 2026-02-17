import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'stat_card.dart';
import 'my_clients_section.dart';
import 'stripe_connect_banner.dart'; // ← NEW

class DashboardContent extends StatelessWidget {
  final DashboardLoaded? cachedState;

  const DashboardContent({
    super.key,
    this.cachedState,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final displayState = (cachedState != null && state is DashboardLoading)
            ? cachedState!
            : state;

        if (displayState is DashboardLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(50, 32, 48, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonStatsCards(),
                      const SizedBox(height: 40),
                      _buildSkeletonClientsSection(),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (displayState is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                Text(
                  displayState.message,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<DashboardBloc>()
                        .add(const DashboardRefreshRequested());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (displayState is DashboardLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<DashboardBloc>()
                        .add(const DashboardRefreshRequested());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(50, 32, 48, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ NEW: Stripe Connect Banner
                        const StripeConnectBanner(),

                        _buildStatsCards(displayState),
                        const SizedBox(height: 40),
                        const MyClientsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 24, 48, 0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF2563EB),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.5),
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
                Positioned(
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
                ),
                const Center(
                  child: Icon(
                    Icons.dashboard,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFE0E7FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildSkeletonStatCard()),
        const SizedBox(width: 20),
        Expanded(child: _buildSkeletonStatCard()),
        const SizedBox(width: 20),
        Expanded(child: _buildSkeletonStatCard()),
        const SizedBox(width: 20),
        Expanded(child: _buildSkeletonStatCard()),
      ],
    );
  }

  Widget _buildSkeletonStatCard() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          padding: const EdgeInsets.all(24),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1 * value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1 * value),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1 * value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonClientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Clients',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildSkeletonClientCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildSkeletonClientCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildSkeletonClientCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonClientCard() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05 * value),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1 * value),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1 * value),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1 * value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 14,
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

  Widget _buildStatsCards(DashboardLoaded state) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total',
            value: state.stats.total.toString(),
            icon: Icons.task_alt,
            gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: StatCard(
            title: 'Pending',
            value: state.stats.pending.toString(),
            icon: Icons.pending_actions,
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: StatCard(
            title: 'In Progress',
            value: state.stats.inProgress.toString(),
            icon: Icons.hourglass_empty,
            gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: StatCard(
            title: 'Completed',
            value: state.stats.completed.toString(),
            icon: Icons.check_circle,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
      ],
    );
  }
}