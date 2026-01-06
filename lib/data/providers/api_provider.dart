import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class ApiProvider {
  final http.Client _client = http.Client();
  String? _token;

  // Set token for authenticated requests
  void setToken(String token) {
    _token = token;
  }

  // Clear token on logout
  void clearToken() {
    _token = null;
  }

  // Get headers with auth token
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Build full URL from endpoint
  String _buildUrl(String endpoint) {
    // If endpoint already has full URL, use it
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }
    // Otherwise, prepend base URL
    return '${ApiConstants.baseUrl}$endpoint';
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response);
    } catch (e) {
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
      final response = await _client.put(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse(_buildUrl(endpoint)),
        headers: _getHeaders(includeAuth: requiresAuth),
      );

      return _handleResponse(response);
    } catch (e) {
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