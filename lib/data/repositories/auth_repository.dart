import '../../core/constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class AuthRepository {
  final ApiProvider _apiProvider;
  final StorageProvider _storageProvider;

  AuthRepository({
    required ApiProvider apiProvider,
    required StorageProvider storageProvider,
  })  : _apiProvider = apiProvider,
        _storageProvider = storageProvider;

  // Login
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.login,
        request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response);

      // Save token and user to local storage
      await _storageProvider.saveToken(loginResponse.token);
      await _storageProvider.saveUser(loginResponse.user);
      
      // Set token in API provider for future requests
      _apiProvider.setToken(loginResponse.token);

      return loginResponse;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get current user (from API)
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiProvider.get(
        ApiConstants.me,
        requiresAuth: true,
      );

      return UserModel.fromJson(response['user'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get cached user (from local storage)
  Future<UserModel?> getCachedUser() async {
    return await _storageProvider.getUser();
  }

  // Get cached token
  Future<String?> getCachedToken() async {
    return await _storageProvider.getToken();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    return await _storageProvider.isLoggedIn();
  }

  // Logout
  Future<void> logout() async {
    await _storageProvider.clearAll();
    _apiProvider.clearToken();
  }

  // Initialize (restore session)
  Future<void> initialize() async {
    final token = await _storageProvider.getToken();
    if (token != null) {
      _apiProvider.setToken(token);
    }
  }
}