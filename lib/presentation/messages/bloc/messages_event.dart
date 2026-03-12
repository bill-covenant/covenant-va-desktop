import 'package:equatable/equatable.dart';
import '../../../data/models/message_model.dart';

abstract class MessagesEvent extends Equatable {
  const MessagesEvent();

  @override
  List<Object?> get props => [];
}

// ============================================
// CONVERSATIONS EVENTS
// ============================================

class MessagesLoadRequested extends MessagesEvent {
  final String userId;
  const MessagesLoadRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MessagesRefreshRequested extends MessagesEvent {
  const MessagesRefreshRequested();
}

// ============================================
// CONVERSATION MESSAGES EVENTS
// ============================================

class ConversationMessagesLoadRequested extends MessagesEvent {
  final String conversationId;

  const ConversationMessagesLoadRequested(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class ConversationMessagesRefreshRequested extends MessagesEvent {
  final String conversationId;

  const ConversationMessagesRefreshRequested(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

// ============================================
// SEND MESSAGE EVENT
// ============================================

class MessageSendRequested extends MessagesEvent {
  final String conversationId;
  final String content;
  final String senderId;

  const MessageSendRequested({
    required this.conversationId,
    required this.content,
    required this.senderId,
  });

  @override
  List<Object> get props => [conversationId, content, senderId];
}

// ============================================
// DELETE MESSAGE EVENT
// ============================================

class MessageDeleteRequested extends MessagesEvent {
  final String conversationId;
  final String messageId;

  const MessageDeleteRequested({
    required this.conversationId,
    required this.messageId,
  });

  @override
  List<Object> get props => [conversationId, messageId];
}

// ============================================
// UNREAD COUNT EVENT
// ============================================

class UnreadCountLoadRequested extends MessagesEvent {
  const UnreadCountLoadRequested();
}

// ============================================
// ✅ REAL-TIME SOCKET EVENT
// ============================================

class SocketMessageReceived extends MessagesEvent {
  final MessageModel message;

  const SocketMessageReceived(this.message);

  @override
  List<Object> get props => [message];
}