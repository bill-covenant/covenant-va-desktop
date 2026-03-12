import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'messages_event.dart';
import 'messages_state.dart';
import '../../../data/repositories/firebase_message_repository.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final FirebaseMessageRepository _messageRepository;

  List<ConversationModel> _cachedConversations = [];
  String? _currentConversationId;
  String _currentUserId = '';

  MessagesBloc({required FirebaseMessageRepository messageRepository})
      : _messageRepository = messageRepository,
        super(const MessagesInitial()) {
    on<MessagesLoadRequested>(_onMessagesLoadRequested);
    on<MessagesRefreshRequested>(_onMessagesRefreshRequested);
    on<ConversationMessagesLoadRequested>(_onConversationMessagesLoadRequested);
    on<MessageSendRequested>(_onMessageSendRequested);
    on<MessageDeleteRequested>(_onMessageDeleteRequested);
    on<UnreadCountLoadRequested>(_onUnreadCountLoadRequested);
    on<SocketMessageReceived>(_onSocketMessageReceived);
  }

  Future<void> _onMessagesLoadRequested(
    MessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    _currentUserId = event.userId;
    if (_cachedConversations.isEmpty) emit(const MessagesLoading());

    try {
      await emit.forEach<List<ConversationModel>>(
        _messageRepository.conversationsStream(_currentUserId),
        onData: (conversations) {
          _cachedConversations = conversations;
          return MessagesLoaded(conversations);
        },
        onError: (error, _) {
          print('❌ Conversations stream error: $error');
          return _cachedConversations.isNotEmpty
              ? MessagesLoaded(_cachedConversations)
              : MessagesError(error.toString());
        },
      );
    } catch (e) {
      print('❌ MessagesLoadRequested error: $e');
      emit(_cachedConversations.isNotEmpty
          ? MessagesLoaded(_cachedConversations)
          : MessagesError(e.toString()));
    }
  }

  Future<void> _onMessagesRefreshRequested(
    MessagesRefreshRequested event,
    Emitter<MessagesState> emit,
  ) async {
    if (_cachedConversations.isNotEmpty) {
      emit(MessagesLoaded(_cachedConversations));
    }
  }

  Future<void> _onConversationMessagesLoadRequested(
    ConversationMessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    _currentConversationId = event.conversationId;
    emit(ConversationMessagesLoading(event.conversationId));

    try {
      await _messageRepository.markConversationRead(
          event.conversationId, _currentUserId);

      await emit.forEach<List<MessageModel>>(
        _messageRepository.messagesStream(event.conversationId),
        onData: (messages) => ConversationMessagesLoaded(
          conversationId: event.conversationId,
          messages: messages,
          conversations: _cachedConversations,
        ),
        onError: (error, _) => ConversationMessagesError(
          conversationId: event.conversationId,
          message: error.toString(),
          conversations: _cachedConversations,
        ),
      );
    } catch (e) {
      print('❌ ConversationMessagesLoadRequested error: $e');
      emit(ConversationMessagesError(
        conversationId: event.conversationId,
        message: e.toString(),
        conversations: _cachedConversations,
      ));
    }
  }

  Future<void> _onMessageSendRequested(
    MessageSendRequested event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      String conversationId = event.conversationId;

      // If this is a new conversation placeholder, create it in Firestore first
      if (conversationId.startsWith('new_')) {
        final clientId = conversationId.substring(4);
        final vaId = event.senderId;
        conversationId = await _messageRepository.getOrCreateConversation(
          clientId: clientId,
          vaId: vaId,
          clientName: event.clientName,
          vaName: event.vaName,
        );
      }

      await _messageRepository.sendMessage(
        conversationId: conversationId,
        senderId: event.senderId,
        content: event.content,
        senderName: '',
      );
    } catch (error) {
      print('❌ Failed to send message: $error');
      emit(MessageSendError(
        conversationId: event.conversationId,
        message: error.toString(),
        messages: const [],
        conversations: _cachedConversations,
      ));
    }
  }

  Future<void> _onMessageDeleteRequested(
    MessageDeleteRequested event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      await _messageRepository.deleteMessage(
        conversationId: event.conversationId,
        messageId: event.messageId,
      );
    } catch (error) {
      print('❌ Failed to delete message: $error');
    }
  }

  Future<void> _onUnreadCountLoadRequested(
    UnreadCountLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    // Derived from conversation stream — no separate call needed
  }

  Future<void> _onSocketMessageReceived(
    SocketMessageReceived event,
    Emitter<MessagesState> emit,
  ) async {
    // No-op: Firestore real-time streams replace socket-based message delivery
  }
}
