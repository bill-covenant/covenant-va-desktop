import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/stripe_repository.dart';

class StripeConnectBanner extends StatefulWidget {
  const StripeConnectBanner({super.key});

  @override
  State<StripeConnectBanner> createState() => _StripeConnectBannerState();
}

class _StripeConnectBannerState extends State<StripeConnectBanner>
    with SingleTickerProviderStateMixin {
  final StripeRepository _stripeRepo = getIt<StripeRepository>();

  StripeStatus? _status;
  bool _isLoading = true;
  bool _isConnecting = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _checkStatus();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await _stripeRepo.getStripeStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ StripeConnectBanner: Error checking status - $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleConnect() async {
    setState(() => _isConnecting = true);

    try {
      final url = await _stripeRepo.getConnectLink();

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if loading or already connected
    if (_isLoading) return const SizedBox.shrink();
    if (_status == null) return const SizedBox.shrink();
    if (_status!.isActive) return _buildConnectedBadge();

    // Show banner for not_started, pending, or action_required
    return _buildBanner();
  }

  Widget _buildConnectedBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.15),
            const Color(0xFF059669).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Stripe Connected',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            'Payouts Active',
            style: TextStyle(
              color: const Color(0xFF10B981).withOpacity(0.6),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final bool isPending = _status!.isPending;
    final bool needsAction = _status!.needsAction;

    // Choose colors based on state
    final List<Color> gradientColors = needsAction
        ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
        : isPending
            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
            : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];

    final Color glowColor = gradientColors[0];

    final String title = needsAction
        ? 'Action Required'
        : isPending
            ? 'Stripe Verification Pending'
            : 'Set Up Your Payouts';

    final String subtitle = needsAction
        ? 'Stripe needs additional information to verify your account'
        : isPending
            ? 'Your account is being verified by Stripe. This usually takes 1-2 business days.'
            : 'Connect your Stripe account to receive payments directly to your bank';

    final String buttonText = needsAction
        ? 'Complete Verification'
        : isPending
            ? 'Check Status'
            : 'Connect to Stripe';

    final IconData iconData = needsAction
        ? Icons.warning_amber_rounded
        : isPending
            ? Icons.hourglass_top_rounded
            : Icons.account_balance_wallet;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glass highlight
                  Positioned(
                    top: 3,
                    left: 3,
                    right: 16,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(iconData, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _isConnecting ? null : _handleConnect,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        offset: const Offset(-2, -2),
                        blurRadius: 6,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(2, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}