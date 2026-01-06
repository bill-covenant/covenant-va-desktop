abstract class NotificationEvent {}

/// Load notifications
class LoadNotifications extends NotificationEvent {
  final bool unreadOnly;
  final int limit;

  LoadNotifications({
    this.unreadOnly = false,
    this.limit = 50,
  });
}

/// Load unread count
class LoadUnreadCount extends NotificationEvent {}

/// Mark notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  MarkNotificationAsRead(this.notificationId);
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {}

/// Delete notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  DeleteNotification(this.notificationId);
}

/// Delete all read notifications
class DeleteAllReadNotifications extends NotificationEvent {}

/// Create test notification
class CreateTestNotification extends NotificationEvent {}

/// Refresh notifications (pull to refresh)
class RefreshNotifications extends NotificationEvent {}