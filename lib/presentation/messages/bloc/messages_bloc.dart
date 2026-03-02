import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'messages_event.dart';
import 'messages_state.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../services/socket_service.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository _messageRepository;
  final SocketService _socketService = SocketService();
  
  List<ConversationModel> _cachedConversations = [];
  String? _currentConversationId;
  StreamSubscription<MessageModel>? _socketSubscription;

  MessagesBloc({required MessageRepository messageRepository})
      : _messageRepository = messageRepository,
        super(const MessagesInitial()) {
    
    on<MessagesLoadRequested>(_onMessagesLoadRequested);
    on<MessagesRefreshRequested>(_onMessagesRefreshRequested);
    on<ConversationMessagesLoadRequested>(_onConversationMessagesLoadRequested);
    on<MessageSendRequested>(_onMessageSendRequested);
    on<MessageDeleteRequested>(_onMessageDeleteRequested);
    on<UnreadCountLoadRequested>(_onUnreadCountLoadRequested);
    on<SocketMessageReceived>(_onSocketMessageReceived);

    // ✅ Listen for real-time messages from socket
    _socketSubscription = _socketService.onNewMessage.listen((message) {
      print('💬 Socket message received in BLoC: ${message.id}');
      add(SocketMessageReceived(message));
    });
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSocketMessageReceived(
    SocketMessageReceived event,
    Emitter<MessagesState> emit,
  ) async {
    final message = event.message;
    print('🔔 Processing socket message for conversation: ${message.conversationId}');

    // ✅ INSTANT: Add message to current conversation view immediately
    if (_currentConversationId == message.conversationId && 
        state is ConversationMessagesLoaded) {
      final currentState = state as ConversationMessagesLoaded;
      final currentMessages = currentState.messages;

      if (currentMessages.any((m) => m.id == message.id)) {
        print('⚠️ Duplicate message ignored: ${message.id}');
        return;
      }

      final updatedMessages = [...currentMessages, message];

      emit(ConversationMessagesLoaded(
        conversationId: message.conversationId,
        messages: updatedMessages,
        conversations: _cachedConversations,
      ));

      print('✅ Message added to current conversation view INSTANTLY');
    }

    // ✅ BACKGROUND: Refresh conversation list without blocking the UI
    _messageRepository.getConversations().then((conversations) {
      _cachedConversations = conversations;
      // Only update if we're still in a loaded state
      if (state is ConversationMessagesLoaded) {
        add(MessagesRefreshRequested());
      }
    }).catchError((e) {
      print('⚠️ Failed to refresh conversations after socket message: $e');
    });
  }

  Future<void> _onMessagesLoadRequested(
    MessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    emit(const MessagesLoading());
    
    try {
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      emit(MessagesLoaded(conversations));
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }

  Future<void> _onMessagesRefreshRequested(
    MessagesRefreshRequested event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      emit(MessagesLoaded(conversations));
    } catch (e) {
      emit(MessagesError(e.toString()));
    }
  }

  Future<void> _onConversationMessagesLoadRequested(
    ConversationMessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    print('🚀 BLoC: Loading messages for conversation ${event.conversationId}');
    
    _currentConversationId = event.conversationId;
    
    emit(ConversationMessagesLoading(event.conversationId));
    
    try {
      final results = await Future.wait([
        _messageRepository.getMessagesForConversation(event.conversationId),
        _messageRepository.getConversations(),
      ]);
      
      final messages = results[0] as List<MessageModel>;
      final conversations = results[1] as List<ConversationModel>;
      _cachedConversations = conversations;
      
      print('✅ BLoC: Got ${messages.length} messages from API');
      
      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: messages,
        conversations: conversations,
      ));
    } catch (e) {
      print('❌ BLoC: Error loading messages: $e');
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
    List<MessageModel> currentMessages = [];
    if (state is ConversationMessagesLoaded) {
      currentMessages = (state as ConversationMessagesLoaded).messages;
    }
    
    final optimisticMessage = MessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: event.conversationId,
      senderId: event.senderId,
      content: event.content,
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final optimisticMessages = [...currentMessages, optimisticMessage];
    
    emit(ConversationMessagesLoaded(
      conversationId: event.conversationId,
      messages: optimisticMessages,
      conversations: _cachedConversations,
    ));
    
    try {
      final newMessage = await _messageRepository.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
      );
      
      final updatedMessages = optimisticMessages
          .where((m) => !m.id.startsWith('temp-'))
          .toList()
        ..add(newMessage);
      
      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: updatedMessages,
        conversations: _cachedConversations,
      ));

      _messageRepository.getConversations().then((conversations) {
        _cachedConversations = conversations;
      }).catchError((e) {
        print('⚠️ Background conversation refresh failed: $e');
      });
      
    } catch (error) {
      print('❌ Failed to send message: $error');
      
      emit(MessageSendError(
        conversationId: event.conversationId,
        message: error.toString(),
        messages: currentMessages,
        conversations: _cachedConversations,
      ));
      
      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: currentMessages,
        conversations: _cachedConversations,
      ));
    }
  }

  Future<void> _onMessageDeleteRequested(
    MessageDeleteRequested event,
    Emitter<MessagesState> emit,
  ) async {
    List<MessageModel> currentMessages = [];
    if (state is ConversationMessagesLoaded) {
      currentMessages = (state as ConversationMessagesLoaded).messages;
    }

    final updatedMessages = currentMessages
        .where((msg) => msg.id != event.messageId)
        .toList();

    emit(ConversationMessagesLoaded(
      conversationId: event.conversationId,
      messages: updatedMessages,
      conversations: _cachedConversations,
    ));

    try {
      await _messageRepository.deleteMessage(event.messageId);

      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;

      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: updatedMessages,
        conversations: conversations,
      ));
    } catch (error) {
      print('❌ Failed to delete message: $error');

      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: currentMessages,
        conversations: _cachedConversations,
      ));
    }
  }

  Future<void> _onUnreadCountLoadRequested(
    UnreadCountLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final unreadCount = await _messageRepository.getUnreadCount();
      
      emit(UnreadCountLoaded(
        unreadCount: unreadCount,
        conversations: _cachedConversations,
      ));
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }
}