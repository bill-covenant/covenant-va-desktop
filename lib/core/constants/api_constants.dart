class ApiConstants {
  // Toggle this for dev/production
  static const bool isProduction = true; // ✅ PRODUCTION
  
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
  static String get conversations => '$baseUrl/conversations';
  static String conversationMessages(String conversationId) =>
      '$conversations/$conversationId/messages';
  static String get unreadCount => '$baseUrl/unread-count';
  static String deleteMessage(String messageId) => '$baseUrl/messages/$messageId';

  // Announcement endpoints
  static String get announcements => '$baseUrl/announcements';
  static String get publishedAnnouncements => '$announcements/published';
  static String dismissAnnouncement(String id) => '$announcements/$id/dismiss';
}