import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/models/notification_model.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  NotificationBloc(this._notificationRepository) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteAllReadNotifications>(_onDeleteAllRead);
    on<CreateTestNotification>(_onCreateTestNotification);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());

      _notifications = await _notificationRepository.getNotifications(
        limit: event.limit,
        unreadOnly: event.unreadOnly,
      );

      _unreadCount = await _notificationRepository.getUnreadCount();

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      _unreadCount = await _notificationRepository.getUnreadCount();

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));
    } catch (e) {
      // Don't emit error, just keep current state
      print('Failed to load unread count: $e');
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAsRead(event.notificationId);

      // Update local state
      _notifications = _notifications.map((notification) {
        if (notification.id == event.notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.markAllAsRead();

      // Update local state
      _notifications = _notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      _unreadCount = 0;

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));

      emit(NotificationActionSuccess('All notifications marked as read'));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteNotification(event.notificationId);

      // Update local state
      final deletedNotification = _notifications.firstWhere(
        (n) => n.id == event.notificationId,
      );

      _notifications = _notifications.where((n) => n.id != event.notificationId).toList();

      if (!deletedNotification.isRead) {
        _unreadCount--;
      }

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onDeleteAllRead(
    DeleteAllReadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationRepository.deleteAllRead();

      // Update local state
      _notifications = _notifications.where((n) => !n.isRead).toList();

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));

      emit(NotificationActionSuccess('All read notifications deleted'));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onCreateTestNotification(
    CreateTestNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notification = await _notificationRepository.createTestNotification();

      _notifications.insert(0, notification);
      _unreadCount++;

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));

      emit(NotificationActionSuccess('Test notification created'));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      _notifications = await _notificationRepository.getNotifications();
      _unreadCount = await _notificationRepository.getUnreadCount();

      emit(NotificationLoaded(
        notifications: _notifications,
        unreadCount: _unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }
}