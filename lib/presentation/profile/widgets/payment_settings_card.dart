import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/user_repository.dart';

class PaymentSettingsCard extends StatefulWidget {
  const PaymentSettingsCard({super.key});

  @override
  State<PaymentSettingsCard> createState() => _PaymentSettingsCardState();
}

class _PaymentSettingsCardState extends State<PaymentSettingsCard> {
  final UserRepository _userRepo = getIt<UserRepository>();

  String? _wiseEmail;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayoutInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutInfo() async {
    try {
      final user = await _userRepo.getCurrentUser();
      if (mounted) {
        setState(() {
          _wiseEmail = user.wiseEmail;
          _emailController.text = user.wiseEmail ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWiseEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await _userRepo.updateProfile(wiseEmail: email);
      if (mounted) {
        setState(() { _wiseEmail = email; _isEditing = false; _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wise tag saved successfully'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeProvider().isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1D2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: dark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                      BoxShadow(color: const Color(0xFF047857).withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 12),
                Text('Payout Settings', style: TextStyle(color: ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                const Spacer(),
                _buildStatusBadge(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (_isLoading) return const SizedBox.shrink();
    final bool hasWise = _wiseEmail != null && _wiseEmail!.isNotEmpty;
    final dark = ThemeProvider().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasWise ? const Color(0xFF10B981).withOpacity(dark ? 0.15 : 0.08) : (dark ? Colors.white.withOpacity(0.08) : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasWise ? const Color(0xFF10B981).withOpacity(0.2) : (dark ? Colors.white.withOpacity(0.12) : const Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasWise ? Icons.check_circle : Icons.link_off, color: hasWise ? const Color(0xFF10B981) : const Color(0xFF9CA3AF), size: 14),
          const SizedBox(width: 6),
          Text(
            hasWise ? 'Set Up' : 'Not Set',
            style: TextStyle(color: hasWise ? const Color(0xFF059669) : const Color(0xFF6B7280), fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2)),
    );
  }

  Widget _buildContent() {
    final bool hasWise = _wiseEmail != null && _wiseEmail!.isNotEmpty;
    final dark = ThemeProvider().isDarkMode;
    if (_isEditing || !hasWise) return _buildEditState(dark);
    return _buildViewState(dark);
  }

  Widget _buildViewState(bool dark) {
    return Column(
      children: [
        // Wise info row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(dark ? 0.2 : 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    BoxShadow(color: const Color(0xFF047857).withOpacity(0.4), blurRadius: 0, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: Icon(Icons.public, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wise Tag', style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 3),
                    Text(_wiseEmail!, style: TextStyle(color: dark ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Center(child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Info text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: dark ? Colors.white54 : const Color(0xFF9CA3AF), size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('Payouts are sent to this Wise tag.', style: TextStyle(color: dark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Edit button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              width: double.infinity, height: 48,
              decoration: BoxDecoration(
                color: dark ? Colors.white.withOpacity(0.08) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: dark ? Colors.white.withOpacity(0.12) : const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: dark ? Colors.white70 : const Color(0xFF6B7280), size: 18),
                    const SizedBox(width: 8),
                    Text('Update Wise Tag', style: TextStyle(color: dark ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditState(bool dark) {
    return Column(
      children: [
        // Instruction
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(dark ? 0.2 : 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    BoxShadow(color: const Color(0xFF047857).withOpacity(0.4), blurRadius: 0, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: Icon(Icons.public, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Enter your Wise tag (e.g. @yourname). Payouts will be sent here.',
                    style: TextStyle(color: dark ? Colors.white60 : const Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Wise Tag input
        TextField(
          controller: _emailController,
          style: TextStyle(color: dark ? Colors.white : const Color(0xFF1F2937), fontWeight: FontWeight.w700, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'yourwisetag',
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4), fontWeight: FontWeight.w600),
            prefixIcon: Container(
              width: 48,
              alignment: Alignment.center,
              child: const Text('@', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w900, fontSize: 18)),
            ),
            filled: true,
            fillColor: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: dark ? Colors.white.withOpacity(0.12) : const Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: dark ? Colors.white.withOpacity(0.12) : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 18),
        // Save / Cancel buttons
        Row(
          children: [
            if (_wiseEmail != null && _wiseEmail!.isNotEmpty)
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() { _isEditing = false; _emailController.text = _wiseEmail ?? ''; }),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withOpacity(0.08) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: dark ? Colors.white.withOpacity(0.12) : const Color(0xFFE5E7EB)),
                      ),
                      child: Center(child: Text('Cancel', style: TextStyle(color: dark ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w700, fontSize: 13))),
                    ),
                  ),
                ),
              ),
            if (_wiseEmail != null && _wiseEmail!.isNotEmpty) const SizedBox(width: 12),
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isSaving ? null : _saveWiseEmail,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF047857).withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 2)),
                        BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}