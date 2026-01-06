import 'package:equatable/equatable.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';

abstract class MessagesState extends Equatable {
  const MessagesState();

  @override
  List<Object?> get props => [];
}

// ============================================
// INITIAL STATE
// ============================================

class MessagesInitial extends MessagesState {
  const MessagesInitial();
}

// ============================================
// CONVERSATIONS STATES
// ============================================

class MessagesLoading extends MessagesState {
  const MessagesLoading();
}

class MessagesLoaded extends MessagesState {
  final List<ConversationModel> conversations;

  const MessagesLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class MessagesError extends MessagesState {
  final String message;

  const MessagesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================
// CONVERSATION MESSAGES STATES (NEW)
// ============================================

class ConversationMessagesLoading extends MessagesState {
  final String conversationId;
  final List<MessageModel>? previousMessages; // Keep previous messages while loading

  const ConversationMessagesLoading(
    this.conversationId, {
    this.previousMessages,
  });

  @override
  List<Object?> get props => [conversationId, previousMessages];
}

class ConversationMessagesLoaded extends MessagesState {
  final String conversationId;
  final List<MessageModel> messages;
  final List<ConversationModel> conversations; // Keep conversations in state

  const ConversationMessagesLoaded({
    required this.conversationId,
    required this.messages,
    required this.conversations,
  });

  @override
  List<Object?> get props => [conversationId, messages, conversations];
}

class ConversationMessagesError extends MessagesState {
  final String conversationId;
  final String message;
  final List<ConversationModel> conversations; // Keep conversations in state

  const ConversationMessagesError({
    required this.conversationId,
    required this.message,
    required this.conversations,
  });

  @override
  List<Object?> get props => [conversationId, message, conversations];
}

// ============================================
// SEND MESSAGE STATES (NEW)
// ============================================

class MessageSending extends MessagesState {
  final String conversationId;
  final List<MessageModel> messages; // Current messages
  final List<ConversationModel> conversations;

  const MessageSending({
    required this.conversationId,
    required this.messages,
    required this.conversations,
  });

  @override
  List<Object?> get props => [conversationId, messages, conversations];
}

class MessageSent extends MessagesState {
  final String conversationId;
  final List<MessageModel> messages; // Updated messages with new one
  final List<ConversationModel> conversations;

  const MessageSent({
    required this.conversationId,
    required this.messages,
    required this.conversations,
  });

  @override
  List<Object?> get props => [conversationId, messages, conversations];
}

class MessageSendError extends MessagesState {
  final String conversationId;
  final String message;
  final List<MessageModel> messages; // Keep current messages
  final List<ConversationModel> conversations;

  const MessageSendError({
    required this.conversationId,
    required this.message,
    required this.messages,
    required this.conversations,
  });

  @override
  List<Object?> get props => [conversationId, message, messages, conversations];
}

// ============================================
// UNREAD COUNT STATE (NEW)
// ============================================

class UnreadCountLoaded extends MessagesState {
  final int unreadCount;
  final List<ConversationModel> conversations;

  const UnreadCountLoaded({
    required this.unreadCount,
    required this.conversations,
  });

  @override
  List<Object?> get props => [unreadCount, conversations];
}