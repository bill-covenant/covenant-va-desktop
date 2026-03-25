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
    String? wiseEmail,
    // Contact
    String? secondaryEmail,
    String? whatsapp,
    // Demographics
    DateTime? dateOfBirth,
    String? gender,
    String? nationality,
    // Emergency Contact
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    // Professional
    String? bio,
    List<String>? skills,
    List<String>? languages,
    Map<String, dynamic>? deviceSpecs,
  }) async {
    print('📋 UserRepository: updateProfile called');

    final Map<String, dynamic> body = {};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (company != null) body['company'] = company;
    if (timezone != null) body['timezone'] = timezone;
    if (wiseEmail != null) body['wiseEmail'] = wiseEmail;
    if (secondaryEmail != null) body['secondaryEmail'] = secondaryEmail;
    if (whatsapp != null) body['whatsapp'] = whatsapp;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth.toIso8601String();
    if (gender != null) body['gender'] = gender;
    if (nationality != null) body['nationality'] = nationality;
    if (emergencyContactName != null) body['emergencyContactName'] = emergencyContactName;
    if (emergencyContactPhone != null) body['emergencyContactPhone'] = emergencyContactPhone;
    if (emergencyContactRelationship != null) body['emergencyContactRelationship'] = emergencyContactRelationship;
    if (bio != null) body['bio'] = bio;
    if (skills != null) body['skills'] = skills;
    if (languages != null) body['languages'] = languages;
    if (deviceSpecs != null) body['deviceSpecs'] = deviceSpecs;

    // Retry once on timeout/network errors (handles Render cold starts)
    Exception? lastError;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _apiProvider.put(
          '/auth/profile',
          body,
          requiresAuth: true,
        );

        final user = UserModel.fromJson(response['user']);
        await _storageProvider.saveUser(user);

        print('✅ UserRepository: Profile updated${attempt > 0 ? ' (retry)' : ''}');
        return user;
      } catch (e) {
        print('❌ UserRepository: Error (attempt ${attempt + 1}) - $e');

        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('401')) {
          throw UnauthorizedException('Invalid token');
        }

        lastError = e is Exception ? e : Exception(e.toString());

        // Only retry on timeout/network errors
        if (attempt == 0 && (e.toString().contains('timed out') || e.toString().contains('Network error'))) {
          print('🔄 Retrying profile update...');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        rethrow;
      }
    }
    throw lastError ?? Exception('Failed to update profile');
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