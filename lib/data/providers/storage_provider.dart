import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Local persistence. The auth token lives in platform secure storage
/// (Windows DPAPI/Credential Manager, macOS Keychain, etc.); non-sensitive
/// data stays in SharedPreferences.
///
/// All token reads in the app must go through [getToken] so the one-time
/// migration out of SharedPreferences happens and the token is never read
/// from plain-text preferences directly.
class StorageProvider {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Save token
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      // Make sure no plain-text copy is left behind.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      // Secure storage unavailable on this platform/config — fall back to
      // preferences so the user can still stay signed in.
      if (kDebugMode) debugPrint('⚠️ Secure storage write failed, using prefs: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
  }

  // Get token (migrates a legacy SharedPreferences token on first read)
  Future<String?> getToken() async {
    String? token;
    var secureAvailable = true;
    try {
      token = await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      secureAvailable = false;
      if (kDebugMode) debugPrint('⚠️ Secure storage read failed: $e');
    }
    if (token != null) return token;

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null && secureAvailable) {
      try {
        await _secureStorage.write(key: _tokenKey, value: legacy);
        await prefs.remove(_tokenKey);
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Token migration to secure storage failed: $e');
      }
    }
    return legacy;
  }

  // Save user data
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get user data
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }

    return null;
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Secure storage delete failed: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
