class ApiConfig {
  // Base URL for the API - Production
  static const String baseUrl = 'https://covenant-va-backend.onrender.com/api';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}