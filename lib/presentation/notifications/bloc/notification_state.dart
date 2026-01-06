import '../../../data/models/notification_model.dart';

abstract class NotificationState {}

/// Initial state
class NotificationInitial extends NotificationState {}

/// Loading state
class NotificationLoading extends NotificationState {}

/// Loaded state
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });
}

/// Error state
class NotificationError extends NotificationState {
  final String message;

  NotificationError(this.message);
}

/// Action success state (for mark as read, delete, etc.)
class NotificationActionSuccess extends NotificationState {
  final String message;

  NotificationActionSuccess(this.message);
}