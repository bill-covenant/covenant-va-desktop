import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_exception.dart';
import 'storage_provider.dart';

export '../../core/errors/api_exception.dart';

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration maxAge) =>
      DateTime.now().difference(timestamp) > maxAge;
}

class ApiProvider {
  final http.Client _client = http.Client();
  final StorageProvider _storageProvider;
  String? _token;

  ApiProvider({StorageProvider? storageProvider})
      : _storageProvider = storageProvider ?? StorageProvider();

  static const Duration _requestTimeout = Duration(seconds: 30);

  // In-memory cache
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultCacheDuration = Duration(seconds: 60);

  // Deduplicate in-flight requests
  final Map<String, Future<Map<String, dynamic>>> _pendingRequests = {};

  /// True while the first request of the session has been waiting > 3s for
  /// the server (e.g. a Render cold start). Drives the small
  /// "Connecting to server…" banner; goes false on the first response.
  final ValueNotifier<bool> isConnectingSlowly = ValueNotifier(false);
  bool _serverResponded = false;
  Timer? _slowStartTimer;
  static const Duration _slowStartThreshold = Duration(seconds: 3);

  void _armSlowStartTimer() {
    if (_serverResponded || _slowStartTimer != null) return;
    _slowStartTimer = Timer(_slowStartThreshold, () {
      if (!_serverResponded) isConnectingSlowly.value = true;
    });
  }

  void _markServerResponded() {
    if (_serverResponded) return;
    _serverResponded = true;
    _slowStartTimer?.cancel();
    _slowStartTimer = null;
    isConnectingSlowly.value = false;
  }

  String? get authToken => _token;

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
    final future = _send(
      (headers) => _client.get(Uri.parse(fullUrl), headers: headers),
      requiresAuth: requiresAuth,
    );
    _pendingRequests[cacheKey] = future;

    try {
      final result = await future;
      _cache[cacheKey] = _CacheEntry(result);
      return result;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// POST request (clears related cache)
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final fullUrl = _buildUrl(endpoint);
    try {
      return await _send(
        (headers) => _client.post(
          Uri.parse(fullUrl),
          headers: headers,
          body: jsonEncode(body),
        ),
        requiresAuth: requiresAuth,
      );
    } finally {
      // Invalidate related cache on mutations
      _invalidateRelatedCache(endpoint);
    }
  }

  /// PUT request (clears related cache)
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final fullUrl = _buildUrl(endpoint);
    try {
      return await _send(
        (headers) => _client.put(
          Uri.parse(fullUrl),
          headers: headers,
          body: jsonEncode(body),
        ),
        requiresAuth: requiresAuth,
      );
    } finally {
      _invalidateRelatedCache(endpoint);
    }
  }

  /// DELETE request (clears related cache)
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final fullUrl = _buildUrl(endpoint);
    try {
      return await _send(
        (headers) => _client.delete(Uri.parse(fullUrl), headers: headers),
        requiresAuth: requiresAuth,
      );
    } finally {
      _invalidateRelatedCache(endpoint);
    }
  }

  /// Performs a request and normalizes every failure into an [ApiException]:
  /// transport failures (offline, DNS/TLS, timeout) have `statusCode == null`,
  /// HTTP errors carry the status code and the server's message.
  ///
  /// On a 401, if storage holds a *different* token than the one just sent
  /// (e.g. the in-memory token is stale after a re-login), the request is
  /// retried once with the stored token. Otherwise the 401 is surfaced.
  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    required bool requiresAuth,
  }) async {
    try {
      // If auth required but no token, try restoring from storage first
      if (requiresAuth && _token == null) {
        await _restoreStoredToken();
      }

      _armSlowStartTimer();
      final usedToken = _token;
      var response = await request(_getHeaders(includeAuth: requiresAuth))
          .timeout(_requestTimeout);
      _markServerResponded();

      if (response.statusCode == 401 && requiresAuth) {
        final stored = await _storageProvider.getToken();
        if (stored != null && stored != usedToken) {
          _token = stored;
          response = await request(_getHeaders(includeAuth: true))
              .timeout(_requestTimeout);
        }
      }

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.',
          isTimeout: true);
    } catch (e) {
      // SocketException / http.ClientException / HandshakeException etc.
      if (kDebugMode) debugPrint('⚠️ ApiProvider transport error: $e');
      throw const ApiException(
          'Network error: could not reach the server. Check your connection and try again.');
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

  /// Load the token from (secure) storage when none is held in memory.
  Future<void> _restoreStoredToken() async {
    if (_token != null) return;
    try {
      final storedToken = await _storageProvider.getToken();
      if (storedToken != null) _token = storedToken;
    } catch (_) {}
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException('Unexpected response from server.', statusCode: status);
      }
    }

    // Backend errors use { error: ... } or { message: ... }
    String? serverMessage;
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final m = body['message'] ?? body['error'];
        if (m != null) serverMessage = m.toString();
      }
    } catch (_) {}

    if (status == 401) {
      throw ApiException(
        serverMessage ?? 'Unauthorized - Please login again',
        statusCode: status,
      );
    }
    if (status == 404) {
      throw ApiException(serverMessage ?? 'Resource not found', statusCode: status);
    }
    throw ApiException(
      serverMessage ?? 'Request failed with status $status',
      statusCode: status,
    );
  }

  void dispose() {
    _slowStartTimer?.cancel();
    isConnectingSlowly.dispose();
    _client.close();
    _cache.clear();
    _pendingRequests.clear();
  }
}
