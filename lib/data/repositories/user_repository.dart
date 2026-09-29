import 'package:flutter/foundation.dart';
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
  Future<UserModel> getCurrentUser({bool forceRefresh = false}) async {
    debugPrint('📋 UserRepository: getCurrentUser called (forceRefresh: $forceRefresh)');

    try {
      final response = await _apiProvider.get(
        '/auth/me',
        requiresAuth: true,
        forceRefresh: forceRefresh,
      );

      debugPrint('📋 UserRepository: Response received');
      
      final user = UserModel.fromJson(response['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      debugPrint('✅ UserRepository: User data saved');
      return user;
    } catch (e) {
      debugPrint('❌ UserRepository: Error - $e');
      
      if (_isUnauthorized(e)) {
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
    debugPrint('📋 UserRepository: updateProfile called');

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

        debugPrint('✅ UserRepository: Profile updated${attempt > 0 ? ' (retry)' : ''}');
        return user;
      } catch (e) {
        debugPrint('❌ UserRepository: Error (attempt ${attempt + 1}) - $e');

        if (_isUnauthorized(e)) {
          throw UnauthorizedException('Invalid token');
        }

        lastError = e is Exception ? e : Exception(e.toString());

        // Only retry on timeout/network errors
        if (attempt == 0 && (e is ApiException && e.isNetworkError)) {
          debugPrint('🔄 Retrying profile update...');
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
    debugPrint('📋 UserRepository: changePassword called');
    
    try {
      await _apiProvider.put(
        '/auth/change-password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        requiresAuth: true,
      );

      debugPrint('✅ UserRepository: Password changed');
    } catch (e) {
      debugPrint('❌ UserRepository: Error - $e');
      
      if (_isUnauthorized(e)) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  /// Upload avatar (base64)
  Future<UserModel> uploadAvatar(String base64Image) async {
    debugPrint('📋 UserRepository: uploadAvatar called');
    debugPrint('📋 Image size: ${base64Image.length} chars');
    
    try {
      final response = await _apiProvider.post(
        '/auth/upload-avatar',
        {'avatar': base64Image},
        requiresAuth: true,
      );

      final user = UserModel.fromJson(response['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      debugPrint('✅ UserRepository: Avatar uploaded');
      return user;
    } catch (e) {
      debugPrint('❌ UserRepository: Error - $e');
      
      if (_isUnauthorized(e)) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  // ============================================
  // W-8BEN FORM
  // ============================================

  /// Get the current VA's W-8BEN form status
  Future<Map<String, dynamic>?> getW8BenForm() async {
    try {
      final response = await _apiProvider.get('/va/w8ben', requiresAuth: true);
      return response['form'] as Map<String, dynamic>?;
    } catch (e) {
      if (_isUnauthorized(e)) {
        throw UnauthorizedException('Invalid token');
      }
      rethrow;
    }
  }

  /// Submit or update the VA's W-8BEN form
  Future<void> submitW8BenForm(Map<String, dynamic> formData) async {
    try {
      await _apiProvider.post('/va/w8ben', formData, requiresAuth: true);
    } catch (e) {
      if (_isUnauthorized(e)) {
        throw UnauthorizedException('Invalid token');
      }
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
    debugPrint('📋 UserRepository: getUserStats called (forceRefresh: $forceRefresh)');

    try {
      final response = await _apiProvider.get(
        '/auth/stats',
        requiresAuth: true,
        forceRefresh: forceRefresh,
      );

      debugPrint('✅ UserRepository: Stats received');
      return response['stats'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ UserRepository: Error - $e');
      
      if (_isUnauthorized(e)) {
        throw UnauthorizedException('Invalid token');
      }
      
      rethrow;
    }
  }

  static bool _isUnauthorized(Object e) =>
      e is ApiException ? e.isUnauthorized : e is UnauthorizedException;
}
