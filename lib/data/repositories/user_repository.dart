import 'dart:convert';
import '../models/user_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

// ✅ Custom exception for auth errors
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  
  @override
  String toString() => message;
}

class UserRepository {
  final StorageProvider _storageProvider;
  final ApiProvider _apiProvider;

  UserRepository({
    StorageProvider? storageProvider,
    ApiProvider? apiProvider,
  })  : _storageProvider = storageProvider ?? StorageProvider(),
        _apiProvider = apiProvider ?? ApiProvider();

  // ============================================
  // PROFILE MANAGEMENT
  // ============================================

  /// Get current user profile
  Future<UserModel> getCurrentUser() async {
    print('📋 UserRepository: getCurrentUser called');
    
    try {
      final response = await _apiProvider.get(
        '/auth/me',
        requiresAuth: true,
      );

      print('📋 UserRepository: Response received');
      
      final user = UserModel.fromJson(response['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      print('✅ UserRepository: User data saved');
      return user;
    } catch (e) {
      print('❌ UserRepository: Error - $e');
      
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('401')) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? company,
    String? timezone,
    String? wiseEmail, // ← NEW
  }) async {
    print('📋 UserRepository: updateProfile called');
    
    final Map<String, dynamic> body = {};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (company != null) body['company'] = company;
    if (timezone != null) body['timezone'] = timezone;
    if (wiseEmail != null) body['wiseEmail'] = wiseEmail; // ← NEW

    try {
      final response = await _apiProvider.put(
        '/auth/profile',
        body,
        requiresAuth: true,
      );

      final user = UserModel.fromJson(response['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      print('✅ UserRepository: Profile updated');
      return user;
    } catch (e) {
      print('❌ UserRepository: Error - $e');
      
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('401')) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    print('📋 UserRepository: changePassword called');
    
    try {
      await _apiProvider.put(
        '/auth/change-password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        requiresAuth: true,
      );

      print('✅ UserRepository: Password changed');
    } catch (e) {
      print('❌ UserRepository: Error - $e');
      
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('401')) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  /// Upload avatar (base64)
  Future<UserModel> uploadAvatar(String base64Image) async {
    print('📋 UserRepository: uploadAvatar called');
    print('📋 Image size: ${base64Image.length} chars');
    
    try {
      final response = await _apiProvider.post(
        '/auth/upload-avatar',
        {'avatar': base64Image},
        requiresAuth: true,
      );

      final user = UserModel.fromJson(response['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      print('✅ UserRepository: Avatar uploaded');
      return user;
    } catch (e) {
      print('❌ UserRepository: Error - $e');
      
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('401')) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    print('📋 UserRepository: getUserStats called');
    
    try {
      final response = await _apiProvider.get(
        '/auth/stats',
        requiresAuth: true,
      );

      print('✅ UserRepository: Stats received');
      return response['stats'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ UserRepository: Error - $e');
      
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('401')) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }
}