class ApiConstants {
  // Base URL - LOCAL DEVELOPMENT
  static const String baseUrl = 'http://localhost:5000/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';
  
  // Task endpoints
  static const String tasks = '$baseUrl/tasks';
  static String taskById(String id) => '$tasks/$id';
  static const String taskStats = '$tasks/stats';
  
  // Message endpoints
  static const String messages = '$baseUrl/messages';
  static const String conversations = '$baseUrl/conversations';
  static String conversationMessages(String conversationId) => 
      '$conversations/$conversationId/messages';
  static const String unreadCount = '$messages/unread-count';
}