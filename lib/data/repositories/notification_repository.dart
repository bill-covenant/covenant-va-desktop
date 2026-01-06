import '../models/notification_model.dart';
import '../providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

class NotificationRepository {
  final ApiProvider _apiProvider;

  NotificationRepository(this._apiProvider);

  /// Get all notifications
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = unreadOnly ? '?unreadOnly=true&limit=$limit' : '?limit=$limit';
      
      final response = await _apiProvider.get(
        '${ApiConstants.baseUrl}/notifications$queryParams',
        requiresAuth: true,
      );

      final notifications = (response['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      return notifications;
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiProvider.get(
        '${ApiConstants.baseUrl}/notifications/unread-count',
        requiresAuth: true,
      );

      return response['count'] as int;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiProvider.put(
        '${ApiConstants.baseUrl}/notifications/$notificationId/read',
        {},
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _apiProvider.put(
        '${ApiConstants.baseUrl}/notifications/read-all',
        {},
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiProvider.delete(
        '${ApiConstants.baseUrl}/notifications/$notificationId',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllRead() async {
    try {
      await _apiProvider.delete(
        '${ApiConstants.baseUrl}/notifications/read',
        requiresAuth: true,
      );
    } catch (e) {
      throw Exception('Failed to delete read notifications: $e');
    }
  }

  /// Create test notification (for testing)
  Future<NotificationModel> createTestNotification() async {
    try {
      final response = await _apiProvider.post(
        '${ApiConstants.baseUrl}/notifications/test',
        {},
        requiresAuth: true,
      );

      return NotificationModel.fromJson(response['notification']);
    } catch (e) {
      throw Exception('Failed to create test notification: $e');
    }
  }
}