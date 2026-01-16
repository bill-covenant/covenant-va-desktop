import 'package:covenant_va_desktop/presentation/profile/widgets/action_buttons_3d.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/change_password_dialog_3d.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/edit_profile_dialog.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/logout_dialog_3d.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/profile_card.dart';
import 'package:covenant_va_desktop/presentation/profile/widgets/stats_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      
      // ✅ Check if it's an authentication error
      final errorString = e.toString();
      final isUnauthorizedException = e.runtimeType.toString() == 'UnauthorizedException';
      final isAuthError = isUnauthorizedException ||
                          errorString.contains('Invalid token') || 
                          errorString.contains('Not authenticated') ||
                          errorString.contains('Unauthorized');
      
      print('🔍 Is auth error? $isAuthError');
      
      if (isAuthError) {
        print('🔐 Auth error detected, logging out...');
        // Clear storage and logout
        await _storageProvider.clearAll();
        if (mounted) {
          context.read<AuthBloc>().add(const LogoutRequested());
        }
        return; // Don't show error state, just logout
      }
      
      // For non-auth errors, show error state
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
      // ✅ NEW: Handle auth errors in password change
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

  @override
  Widget build(BuildContext context) {
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
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileCard(
            user: _user!,
            onEdit: _handleEditProfile,
            onAvatarUpload: () => _loadUserData(showLoading: false),
          ),
          const SizedBox(height: 24),
          if (_stats != null) StatsGrid(stats: _stats!),
          const SizedBox(height: 24),
          ActionButtons3D(
            onChangePassword: _handleChangePassword,
            onLogout: _handleLogout,
          ),
        ],
      ),
    );
  }
}