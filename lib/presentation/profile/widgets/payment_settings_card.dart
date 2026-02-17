import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/stripe_repository.dart';

class PaymentSettingsCard extends StatefulWidget {
  const PaymentSettingsCard({super.key});

  @override
  State<PaymentSettingsCard> createState() => _PaymentSettingsCardState();
}

class _PaymentSettingsCardState extends State<PaymentSettingsCard> {
  final StripeRepository _stripeRepo = getIt<StripeRepository>();

  StripeStatus? _status;
  bool _isLoading = true;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await _stripeRepo.getStripeStatus();
      if (mounted) setState(() { _status = status; _isLoading = false; });
    } catch (e) {
      print('❌ PaymentSettingsCard: Error - $e');
      if (mounted) setState(() => _isLoading = false);
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.03),
            offset: const Offset(-2, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (_status != null) _buildStatusBadge(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (_status == null) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (_status!.isActive) {
      bgColor = const Color(0xFF10B981).withOpacity(0.15);
      textColor = const Color(0xFF10B981);
      label = 'Connected';
      icon = Icons.check_circle;
    } else if (_status!.isPending) {
      bgColor = const Color(0xFFF59E0B).withOpacity(0.15);
      textColor = const Color(0xFFF59E0B);
      label = 'Pending';
      icon = Icons.hourglass_top;
    } else if (_status!.needsAction) {
      bgColor = const Color(0xFFEF4444).withOpacity(0.15);
      textColor = const Color(0xFFEF4444);
      label = 'Action Required';
      icon = Icons.warning_amber;
    } else {
      bgColor = Colors.white.withOpacity(0.08);
      textColor = Colors.white.withOpacity(0.5);
      label = 'Not Connected';
      icon = Icons.link_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == null) return _buildNotConnected();
    if (_status!.isActive) return _buildConnectedState();
    if (_status!.isPending) return _buildPendingState();
    if (_status!.needsAction) return _buildActionRequired();
    return _buildNotConnected();
  }

  Widget _buildConnectedState() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.check_circle,
          iconColor: const Color(0xFF10B981),
          label: 'Account Status',
          value: 'Verified & Active',
          valueColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.account_balance,
          iconColor: const Color(0xFF3B82F6),
          label: 'Payouts',
          value: _status!.payoutsEnabled ? 'Enabled' : 'Disabled',
          valueColor: _status!.payoutsEnabled
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        _buildSecondaryButton(
          label: 'Manage Stripe Account',
          icon: Icons.open_in_new,
          onTap: _handleConnect,
        ),
      ],
    );
  }

  Widget _buildPendingState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top,
                  color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification in Progress',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stripe is verifying your identity. This typically takes 1-2 business days.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSecondaryButton(
          label: 'Check Status',
          icon: Icons.refresh,
          onTap: () async {
            setState(() => _isLoading = true);
            await _checkStatus();
          },
        ),
      ],
    );
  }

  Widget _buildActionRequired() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber,
                  color: Color(0xFFEF4444), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Info Needed',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stripe needs more information to complete your verification.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: 'Complete Verification',
          icon: Icons.open_in_new,
          gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          glowColor: const Color(0xFFEF4444),
          onTap: _handleConnect,
        ),
      ],
    );
  }

  Widget _buildNotConnected() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.white.withOpacity(0.4), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stripe Not Connected',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connect your Stripe account to receive payments directly to your bank.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: 'Connect to Stripe',
          icon: Icons.link,
          gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
          glowColor: const Color(0xFF8B5CF6),
          onTap: _handleConnect,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isConnecting ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 52,
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
          child: Center(
            child: _isConnecting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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