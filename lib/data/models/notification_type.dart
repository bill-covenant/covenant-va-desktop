enum NotificationType {
  assignmentCreated,
  assignmentRemoved,
  taskAssigned,
  taskCompleted,
  taskOverdue,
  messageReceived,
  paymentReceived,
  systemAlert,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.assignmentCreated:
        return 'ASSIGNMENT_CREATED';
      case NotificationType.assignmentRemoved:
        return 'ASSIGNMENT_REMOVED';
      case NotificationType.taskAssigned:
        return 'TASK_ASSIGNED';
      case NotificationType.taskCompleted:
        return 'TASK_COMPLETED';
      case NotificationType.taskOverdue:
        return 'TASK_OVERDUE';
      case NotificationType.messageReceived:
        return 'MESSAGE_RECEIVED';
      case NotificationType.paymentReceived:
        return 'PAYMENT_RECEIVED';
      case NotificationType.systemAlert:
        return 'SYSTEM_ALERT';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'ASSIGNMENT_CREATED':
        return NotificationType.assignmentCreated;
      case 'ASSIGNMENT_REMOVED':
        return NotificationType.assignmentRemoved;
      case 'TASK_ASSIGNED':
        return NotificationType.taskAssigned;
      case 'TASK_COMPLETED':
        return NotificationType.taskCompleted;
      case 'TASK_OVERDUE':
        return NotificationType.taskOverdue;
      case 'MESSAGE_RECEIVED':
        return NotificationType.messageReceived;
      case 'PAYMENT_RECEIVED':
        return NotificationType.paymentReceived;
      case 'SYSTEM_ALERT':
        return NotificationType.systemAlert;
      default:
        return NotificationType.systemAlert;
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.assignmentCreated:
        return '🔗';
      case NotificationType.assignmentRemoved:
        return '⛓️‍💥';
      case NotificationType.taskAssigned:
        return '📋';
      case NotificationType.taskCompleted:
        return '✅';
      case NotificationType.taskOverdue:
        return '⚠️';
      case NotificationType.messageReceived:
        return '💬';
      case NotificationType.paymentReceived:
        return '💰';
      case NotificationType.systemAlert:
        return '🔔';
    }
  }
}