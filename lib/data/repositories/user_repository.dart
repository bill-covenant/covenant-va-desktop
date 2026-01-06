import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../providers/api_config.dart';
import '../providers/storage_provider.dart';

class UserRepository {
  final StorageProvider _storageProvider;

  UserRepository({StorageProvider? storageProvider})
      : _storageProvider = storageProvider ?? StorageProvider();

  // ============================================
  // PROFILE MANAGEMENT
  // ============================================

  /// Get current user profile
  Future<UserModel> getCurrentUser() async {
    final token = await _storageProvider.getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch user profile');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? company,
    String? timezone,
  }) async {
    final token = await _storageProvider.getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final Map<String, dynamic> body = {};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (company != null) body['company'] = company;
    if (timezone != null) body['timezone'] = timezone;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      
      // Update stored user data
      await _storageProvider.saveUser(user);
      
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _storageProvider.getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to change password');
    }
  }

  /// Upload avatar (base64) - WITH DETAILED LOGGING
  Future<UserModel> uploadAvatar(String base64Image) async {
    print('🔵 [UserRepository] uploadAvatar called');
    
    final token = await _storageProvider.getToken();
    print('🔵 [UserRepository] Token retrieved: ${token != null ? "YES" : "NO"}');
    
    if (token == null) {
      print('❌ [UserRepository] No token found!');
      throw Exception('Not authenticated');
    }

    final url = '${ApiConfig.baseUrl}/auth/upload-avatar';
    print('🔵 [UserRepository] URL: $url');
    print('🔵 [UserRepository] Image size: ${base64Image.length} chars');
    
    try {
      print('🔵 [UserRepository] Making HTTP POST request...');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'avatar': base64Image,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ [UserRepository] Request timed out!');
          throw Exception('Request timed out');
        },
      );

      print('🔵 [UserRepository] Response received');
      print('🔵 [UserRepository] Status code: ${response.statusCode}');
      print('🔵 [UserRepository] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromJson(data['user']);
        
        // Update stored user data
        await _storageProvider.saveUser(user);
        
        print('✅ [UserRepository] Avatar uploaded successfully!');
        return user;
      } else {
        print('❌ [UserRepository] Upload failed with status: ${response.statusCode}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload avatar');
      }
    } catch (e) {
      print('❌ [UserRepository] Exception caught: $e');
      print('❌ [UserRepository] Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    final token = await _storageProvider.getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stats'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch statistics');
    }
  }
}