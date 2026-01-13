import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class ApiProvider {
  final http.Client _client = http.Client();
  String? _token;

  // Set token for authenticated requests
  void setToken(String token) {
    _token = token;
    print('🔑 ApiProvider: Token set, length: ${token.length}'); // ← DEBUG
  }

  // Clear token on logout
  void clearToken() {
    _token = null;
    print('🔑 ApiProvider: Token cleared'); // ← DEBUG
  }

  // Get headers with auth token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
      print('🔑 ApiProvider: Adding auth header'); // ← DEBUG
    } else if (includeAuth && _token == null) {
      print('⚠️ ApiProvider: Auth required but no token available!'); // ← DEBUG
    }

    return headers;
  }

  // Build full URL from endpoint with query parameters
  String _buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    String url;
    
    // If endpoint already has full URL, use it
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      url = endpoint;
    } else {
      // Otherwise, prepend base URL
      url = '${ApiConstants.baseUrl}$endpoint';
    }

    // Add query parameters if provided
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final newUri = uri.replace(queryParameters: queryParams);
      return newUri.toString();
    }

    return url;
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      print('🌐 API POST: $endpoint'); // ← DEBUG
      print('🔑 Auth required: $requiresAuth'); // ← DEBUG
      print('🔑 Token exists: ${_token != null}'); // ← DEBUG
      
      final response = await _client.post(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}'); // ← DEBUG
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e'); // ← DEBUG
      throw Exception('Network error: $e');
    }
  }

  // GET request with query parameters support
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
  }) async {
    try {
      print('🌐 API GET: $endpoint'); // ← DEBUG
      print('🔑 Auth required: $requiresAuth'); // ← DEBUG
      print('🔑 Token exists: ${_token != null}'); // ← DEBUG
      
      final response = await _client.get(
        Uri.parse(_buildUrl(endpoint, queryParams: queryParams)),
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      print('📥 Response status: ${response.statusCode}'); // ← DEBUG
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e'); // ← DEBUG
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      print('🌐 API PUT: $endpoint'); // ← DEBUG
      print('🔑 Auth required: $requiresAuth'); // ← DEBUG
      print('🔑 Token exists: ${_token != null}'); // ← DEBUG
      
      final response = await _client.put(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}'); // ← DEBUG
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e'); // ← DEBUG
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      print('🌐 API DELETE: $endpoint'); // ← DEBUG
      print('🔑 Auth required: $requiresAuth'); // ← DEBUG
      print('🔑 Token exists: ${_token != null}'); // ← DEBUG
      
      final response = await _client.delete(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      print('📥 Response status: ${response.statusCode}'); // ← DEBUG
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e'); // ← DEBUG
      throw Exception('Network error: $e');
    }
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else if (response.statusCode == 404) {
      throw Exception('Resource not found');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Request failed');
    }
  }

  // Dispose
  void dispose() {
    _client.close();
  }
}