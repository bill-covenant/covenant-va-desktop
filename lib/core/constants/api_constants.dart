class ApiConstants {
  // Toggle this for dev/production
  static const bool isProduction = false; // ⚠️ SWITCHED TO LOCAL FOR TESTING
  
  // Base URL - switches based on environment
  static String get baseUrl => isProduction 
      ? 'https://covenant-va-backend.onrender.com/api'
      : 'http://localhost:5000/api';
  
  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';
  
  // Task endpoints
  static String get tasks => '$baseUrl/tasks';
  static String taskById(String id) => '$tasks/$id';
  static String get taskStats => '$tasks/stats';
  
  // Message endpoints
  static String get messages => '$baseUrl/messages';
  static String get conversations => '$baseUrl/conversations';
  static String conversationMessages(String conversationId) => 
      '$conversations/$conversationId/messages';
  static String get unreadCount => '$messages/unread-count';
}