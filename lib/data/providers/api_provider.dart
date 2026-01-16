import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class ApiProvider {
  final http.Client _client = http.Client();
  String? _token;

  // Set token for authenticated requests
  void setToken(String token) {
    _token = token;
    print('🔑 ApiProvider: Token set, length: ${token.length}');
  }

  // Clear token on logout
  void clearToken() {
    _token = null;
    print('🔑 ApiProvider: Token cleared');
  }

  // Get headers with auth token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
      print('🔑 ApiProvider: Adding auth header');
    } else if (includeAuth && _token == null) {
      print('⚠️ ApiProvider: Auth required but no token available!');
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
      final fullUrl = _buildUrl(endpoint);
      
      print('🌐 API POST endpoint: $endpoint');
      print('🌐 API POST full URL: $fullUrl');
      print('🔑 Auth required: $requiresAuth');
      print('🔑 Token exists: ${_token != null}');
      
      final response = await _client.post(
        Uri.parse(fullUrl),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 500) {
        print('❌ 500 Error Response: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
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
      final fullUrl = _buildUrl(endpoint, queryParams: queryParams);
      
      print('🌐 API GET endpoint: $endpoint');
      print('🌐 API GET full URL: $fullUrl'); // ✅ NOW SHOWS FULL URL
      print('🔑 Auth required: $requiresAuth');
      print('🔑 Token exists: ${_token != null}');
      
      final response = await _client.get(
        Uri.parse(fullUrl),
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      print('📥 Response status: ${response.statusCode}');
      
      // ✅ Log 500 errors for debugging
      if (response.statusCode == 500) {
        print('❌ 500 Error Response: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
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
      final fullUrl = _buildUrl(endpoint);
      
      print('🌐 API PUT endpoint: $endpoint');
      print('🌐 API PUT full URL: $fullUrl');
      print('🔑 Auth required: $requiresAuth');
      print('🔑 Token exists: ${_token != null}');
      
      final response = await _client.put(
        Uri.parse(fullUrl),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 500) {
        print('❌ 500 Error Response: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final fullUrl = _buildUrl(endpoint);
      
      print('🌐 API DELETE endpoint: $endpoint');
      print('🌐 API DELETE full URL: $fullUrl');
      print('🔑 Auth required: $requiresAuth');
      print('🔑 Token exists: ${_token != null}');
      
      final response = await _client.delete(
        Uri.parse(fullUrl),
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 500) {
        print('❌ 500 Error Response: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API Error: $e');
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
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Request failed');
      } catch (e) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }

  // Dispose
  void dispose() {
    _client.close();
  }
}