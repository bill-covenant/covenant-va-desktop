import 'package:covenant_va_desktop/presentation/profile/widgets/change_password_dialog_3d.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/edit_profile_dialog.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/logout_dialog_3d.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/profile_card.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/extended_profile_card.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/device_specs_card.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/skills_experience_card.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../core/di/service_locator.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = getIt<UserRepository>();
  final StorageProvider _storageProvider = getIt<StorageProvider>();
  
  UserModel? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _error;

  static UserModel? _cachedUser;
  static Map<String, dynamic>? _cachedStats;
  static DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    
    if (_cachedUser != null && _cachedStats != null) {
      _user = _cachedUser;
      _stats = _cachedStats;
      _isInitialLoad = false;
      _isLoading = false;
      
      if (_lastFetchTime == null || 
          DateTime.now().difference(_lastFetchTime!) > const Duration(seconds: 30)) {
        _loadUserData(showLoading: false);
      }
    } else {
      _isLoading = true;
      _loadUserData(showLoading: true);
    }
  }

  Future<void> _loadUserData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('📋 ProfileScreen: Starting to load user data...');
      
      final results = await Future.wait([
        _userRepository.getCurrentUser(),
        _userRepository.getUserStats(),
      ]);

      print('📋 ProfileScreen: Data loaded successfully');
      
      if (!mounted) return;

      _cachedUser = results[0] as UserModel;
      _cachedStats = results[1] as Map<String, dynamic>;
      _lastFetchTime = DateTime.now();

      setState(() {
        _user = _cachedUser;
        _stats = _cachedStats;
        _isLoading = false;
        _isInitialLoad = false;
      });
      
      print('✅ ProfileScreen: UI updated successfully');
    } catch (e) {
      print('❌ ProfileScreen: Error caught - $e');
      print('❌ ProfileScreen: Error type - ${e.runtimeType}');
      
      if (!mounted) return;
      
      final errorString = e.toString();
      final isUnauthorizedException = e.runtimeType.toString() == 'UnauthorizedException';
      final isAuthError = isUnauthorizedException ||
                          errorString.contains('Invalid token') || 
                          errorString.contains('Not authenticated') ||
                          errorString.contains('Unauthorized');
      
      print('🔍 Is auth error? $isAuthError');
      
      if (isAuthError) {
        print('🔐 Auth error detected, logging out...');
        await _storageProvider.clearAll();
        if (mounted) {
          context.read<AuthBloc>().add(const LogoutRequested());
        }
        return;
      }
      
      print('❌ Non-auth error, showing error state: $errorString');
      setState(() {
        _error = errorString;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEditProfile() async {
    if (_user == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProfileDialog(user: _user!),
    );

    if (result == true) {
      _loadUserData(showLoading: false);
    }
  }

  Future<void> _handleChangePassword() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const ChangePasswordDialog3D(),
      );

      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      final isAuthError = e.toString().contains('Invalid token') || 
                          e.toString().contains('Not authenticated') ||
                          e.toString().contains('Unauthorized');
      
      if (isAuthError && mounted) {
        await _storageProvider.clearAll();
        if (mounted) {
          context.read<AuthBloc>().add(const LogoutRequested());
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutDialog3D(),
    );

    if (confirmed == true) {
      await _storageProvider.clearAll();
      
      if (mounted) {
        context.read<AuthBloc>().add(const LogoutRequested());
      }
    }
  }

  Future<void> _showWiseTagDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _WiseTagDialog(currentTag: _user?.wiseEmail ?? ''),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _userRepository.updateProfile(wiseEmail: result);
        _loadUserData(showLoading: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Wise tag saved'), backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)),
          );
        }
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final dark = ThemeProvider().isDarkMode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(dark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(dark ? 0.2 : 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCompletion() {
    if (_user == null) return 0;
    final p = _user!.profile;
    final fields = [
      _user!.firstName.isNotEmpty,
      _user!.lastName.isNotEmpty,
      _user!.email.isNotEmpty,
      p?.phone != null && p!.phone!.isNotEmpty,
      p?.avatar != null && p!.avatar!.isNotEmpty,
      p?.secondaryEmail != null && p!.secondaryEmail!.isNotEmpty,
      p?.whatsapp != null && p!.whatsapp!.isNotEmpty,
      p?.dateOfBirth != null,
      p?.gender != null && p!.gender!.isNotEmpty,
      p?.nationality != null && p!.nationality!.isNotEmpty,
      p?.emergencyContactName != null && p!.emergencyContactName!.isNotEmpty,
      p?.emergencyContactPhone != null && p!.emergencyContactPhone!.isNotEmpty,
      p?.emergencyContactRelationship != null && p!.emergencyContactRelationship!.isNotEmpty,
      p?.bio != null && p!.bio!.isNotEmpty,
      p?.skills != null && p!.skills.isNotEmpty,
      p?.languages != null && p!.languages.isNotEmpty,
      p?.deviceSpecs != null && p!.deviceSpecs!.values.any((v) => v != null && v.toString().isNotEmpty),
    ];
    final filled = fields.where((f) => f).length;
    return (filled / fields.length * 100).round();
  }

  Widget _buildProfileProgress() {
    final dark = ThemeProvider().isDarkMode;
    final pct = _calculateCompletion();
    final color = pct >= 80
        ? const Color(0xFF4ADE80)
        : pct >= 50
            ? const Color(0xFFFBBF24)
            : const Color(0xFFF87171);
    final glowColor = color.withOpacity(0.4);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)]
              : [Colors.white, const Color(0xFFF9FAFB)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? color.withOpacity(0.2) : color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(
            color: dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 6,
                      backgroundColor: dark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : const Color(0xFF1F2937),
                      shadows: [Shadow(color: glowColor, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white.withOpacity(0.7) : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: (_isLoading && _isInitialLoad)
                  ? _buildLoadingState()
                  : _error != null && _user == null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
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
                  Color(0xFFEC4899),
                  Color(0xFFDB2777),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.5),
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
                    Icons.person,
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
              'Profile',
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

  Widget _buildLoadingState() {
    return const SizedBox();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadUserData(showLoading: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_user == null) return const SizedBox();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with Payout + Actions inline
          Container(
            decoration: BoxDecoration(
              color: ThemeProvider().isDarkMode ? const Color(0xFF1A1D2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: ThemeProvider().isDarkMode ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
              boxShadow: [
                BoxShadow(
                  color: ThemeProvider().isDarkMode ? Colors.black.withOpacity(0.3) : const Color(0xFF7C3AED).withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ProfileCard(
              user: _user!,
              onEdit: _handleEditProfile,
              onAvatarUpload: () => _loadUserData(showLoading: false),
              actions: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Buttons column
                    Expanded(
                      child: Column(
                        children: [
                          _buildActionButton(
                            icon: Icons.account_balance_wallet_rounded,
                            label: _user?.wiseEmail != null && _user!.wiseEmail!.isNotEmpty
                                ? '@${_user!.wiseEmail}'
                                : 'Set Up Wise Tag',
                            color: const Color(0xFF10B981),
                            onTap: _showWiseTagDialog,
                          ),
                          const SizedBox(height: 10),
                          _buildActionButton(
                            icon: Icons.lock_rounded,
                            label: 'Change Password',
                            color: const Color(0xFF8B5CF6),
                            onTap: _handleChangePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Circular progress — matches buttons height
                    Expanded(child: _buildProfileProgress()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ExtendedProfileCard(
            user: _user!,
            onUpdated: () => _loadUserData(showLoading: false),
          ),
          const SizedBox(height: 24),
          SkillsExperienceCard(
            user: _user!,
            onUpdated: () => _loadUserData(showLoading: false),
          ),
          const SizedBox(height: 24),
          DeviceSpecsCard(
            user: _user!,
            onUpdated: () => _loadUserData(showLoading: false),
          ),
        ],
      ),
    ));
  }
}

class _WiseTagDialog extends StatefulWidget {
  final String currentTag;
  const _WiseTagDialog({required this.currentTag});

  @override
  State<_WiseTagDialog> createState() => _WiseTagDialogState();
}

class _WiseTagDialogState extends State<_WiseTagDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTag);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF4), Color(0xFFF7FEE7)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Set Up Wise Tag',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your Wise tag (e.g. @yourname). Payouts will be sent here.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: const Text('@', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 20)),
                        ),
                        hintText: 'yourwisetag',
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4), fontWeight: FontWeight.w600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: const Color(0xFF9CA3AF).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 6))],
                              ),
                              child: const Center(
                                child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              final tag = _controller.text.trim();
                              if (tag.isNotEmpty) Navigator.pop(context, tag);
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 6))],
                              ),
                              child: const Center(
                                child: Text('Save Wise Tag', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}