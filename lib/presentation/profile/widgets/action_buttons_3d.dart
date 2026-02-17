import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/stripe_repository.dart';

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
  final StripeRepository _stripeRepo = getIt<StripeRepository>();
  bool _isConnectingStripe = false;

  Future<void> _handleStripe() async {
    setState(() => _isConnectingStripe = true);

    try {
      // Try dashboard link first (for connected accounts)
      String url;
      try {
        final status = await _stripeRepo.getStripeStatus();
        if (status.isActive) {
          url = await _stripeRepo.getDashboardLink();
        } else {
          url = await _stripeRepo.getConnectLink();
        }
      } catch (_) {
        url = await _stripeRepo.getConnectLink();
      }

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stripe error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingStripe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _build3DButton(
            onTap: widget.onChangePassword,
            icon: Icons.lock,
            label: 'Change Password',
            gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
            glowColor: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _build3DButton(
            onTap: _isConnectingStripe ? () {} : _handleStripe,
            icon: Icons.account_balance_wallet,
            label: _isConnectingStripe ? 'Loading...' : 'Stripe',
            gradient: const [Color(0xFF635BFF), Color(0xFF4F46E5)],
            glowColor: const Color(0xFF635BFF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _build3DButton(
            onTap: widget.onLogout,
            icon: Icons.logout,
            label: 'Logout',
            gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            glowColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _build3DButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required Color glowColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(4, 4),
                blurRadius: 12,
              ),
              BoxShadow(
                color: glowColor.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient[0].withOpacity(0.9),
                  gradient[1].withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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