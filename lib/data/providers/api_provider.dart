import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration maxAge) =>
      DateTime.now().difference(timestamp) > maxAge;
}

class ApiProvider {
  final http.Client _client = http.Client();
  String? _token;

  // In-memory cache
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultCacheDuration = Duration(seconds: 60);

  // Deduplicate in-flight requests
  final Map<String, Future<Map<String, dynamic>>> _pendingRequests = {};

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
    _cache.clear();
    _pendingRequests.clear();
  }

  /// Clear cache for a specific endpoint or all cache
  void clearCache([String? endpoint]) {
    if (endpoint != null) {
      _cache.removeWhere((key, _) => key.contains(endpoint));
    } else {
      _cache.clear();
    }
  }

  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Connection': 'keep-alive',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String _buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    String url;
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      url = endpoint;
    } else {
      url = '${ApiConstants.baseUrl}$endpoint';
    }
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final newUri = uri.replace(queryParameters: queryParams);
      return newUri.toString();
    }
    return url;
  }

  /// GET request with caching and deduplication
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    final fullUrl = _buildUrl(endpoint, queryParams: queryParams);
    final cacheKey = fullUrl;
    final ttl = cacheDuration ?? _defaultCacheDuration;

    // 1. Return cached data if valid and not forcing refresh
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired(ttl)) {
        return entry.data;
      }
      _cache.remove(cacheKey);
    }

    // 2. Deduplicate: if same request is already in-flight, return that future
    if (_pendingRequests.containsKey(cacheKey)) {
      return _pendingRequests[cacheKey]!;
    }

    // 3. Make the actual request
    final future = _doGet(fullUrl, requiresAuth: requiresAuth);
    _pendingRequests[cacheKey] = future;

    try {
      final result = await future;
      _cache[cacheKey] = _CacheEntry(result);
      return result;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  Future<Map<String, dynamic>> _doGet(
    String fullUrl, {
    required bool requiresAuth,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(fullUrl),
            headers: _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// POST request (clears related cache)
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final fullUrl = _buildUrl(endpoint);

      final response = await _client
          .post(
            Uri.parse(fullUrl),
            headers: _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      // Invalidate related cache on mutations
      _invalidateRelatedCache(endpoint);

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// PUT request (clears related cache)
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final fullUrl = _buildUrl(endpoint);

      final response = await _client
          .put(
            Uri.parse(fullUrl),
            headers: _getHeaders(includeAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      _invalidateRelatedCache(endpoint);

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request (clears related cache)
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final fullUrl = _buildUrl(endpoint);

      final response = await _client
          .delete(
            Uri.parse(fullUrl),
            headers: _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(const Duration(seconds: 15));

      _invalidateRelatedCache(endpoint);

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Invalidate cache for related endpoints after mutations
  void _invalidateRelatedCache(String endpoint) {
    // Extract the base resource path (e.g., /tasks, /timecard, /messages)
    final parts = endpoint.split('/');
    if (parts.length >= 2) {
      final resource = '/${parts[1]}';
      _cache.removeWhere((key, _) => key.contains(resource));
    }
  }

  /// Fetch multiple endpoints in parallel
  Future<List<Map<String, dynamic>>> getAll(
    List<String> endpoints, {
    bool requiresAuth = false,
    Duration? cacheDuration,
  }) async {
    final futures = endpoints.map((ep) => get(
          ep,
          requiresAuth: requiresAuth,
          cacheDuration: cacheDuration,
        ));
    return Future.wait(futures);
  }

  /// Warm up: pre-fetch commonly used endpoints
  Future<void> warmUp(List<String> endpoints, {bool requiresAuth = true}) async {
    // Fire all requests in parallel, don't await — let them cache in background
    for (final ep in endpoints) {
      get(ep, requiresAuth: requiresAuth).catchError((_) => <String, dynamic>{});
    }
  }

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
        if (e is Exception) rethrow;
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }

  void dispose() {
    _client.close();
    _cache.clear();
    _pendingRequests.clear();
  }
}