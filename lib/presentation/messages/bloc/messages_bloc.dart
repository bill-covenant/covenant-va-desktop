import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'messages_event.dart';
import 'messages_state.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';

class MessagesBloc extends Bloc<MessagesEvent, MessagesState> {
  final MessageRepository _messageRepository;
  
  List<ConversationModel> _cachedConversations = [];
  Timer? _autoRefreshTimer;
  String? _currentConversationId;

  MessagesBloc({required MessageRepository messageRepository})
      : _messageRepository = messageRepository,
        super(const MessagesInitial()) {
    
    on<MessagesLoadRequested>(_onMessagesLoadRequested);
    on<MessagesRefreshRequested>(_onMessagesRefreshRequested);
    on<ConversationMessagesLoadRequested>(_onConversationMessagesLoadRequested);
    on<ConversationMessagesRefreshRequested>(_onConversationMessagesRefreshRequested);
    on<MessageSendRequested>(_onMessageSendRequested);
    on<MessageDeleteRequested>(_onMessageDeleteRequested); // ✅ ADDED
    on<UnreadCountLoadRequested>(_onUnreadCountLoadRequested);
  }

  void _startAutoRefresh(String conversationId) {
    _autoRefreshTimer?.cancel();
    _currentConversationId = conversationId;
    
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentConversationId != null) {
        add(ConversationMessagesRefreshRequested(_currentConversationId!));
      }
    });
    
    print('🔄 Auto-refresh started for conversation $conversationId');
  }
  
  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    _currentConversationId = null;
    print('⏹️ Auto-refresh stopped');
  }

  @override
  Future<void> close() {
    _stopAutoRefresh();
    return super.close();
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
    
    _startAutoRefresh(event.conversationId);
    
    emit(ConversationMessagesLoading(event.conversationId));
    
    try {
      print('📡 BLoC: Calling API getMessagesForConversation...');
      final messages = await _messageRepository.getMessagesForConversation(
        event.conversationId,
      );
      print('✅ BLoC: Got ${messages.length} messages from API');
      
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      
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

  Future<void> _onConversationMessagesRefreshRequested(
    ConversationMessagesRefreshRequested event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final messages = await _messageRepository.getMessagesForConversation(
        event.conversationId,
      );
      
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      
      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: messages,
        conversations: conversations,
      ));
      
      print('🔄 Auto-refreshed: ${messages.length} messages');
    } catch (e) {
      print('⚠️ Auto-refresh error: $e');
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
    
    print('📤 Creating optimistic message with senderId: ${event.senderId}');
    
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
      
      print('✅ Message sent successfully. Server senderId: ${newMessage.senderId}');
      
      final updatedMessages = [...currentMessages, newMessage];
      
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      
      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: updatedMessages,
        conversations: conversations,
      ));
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

  // ✅ DELETE MESSAGE HANDLER (NEW)
  Future<void> _onMessageDeleteRequested(
    MessageDeleteRequested event,
    Emitter<MessagesState> emit,
  ) async {
    List<MessageModel> currentMessages = [];
    if (state is ConversationMessagesLoaded) {
      currentMessages = (state as ConversationMessagesLoaded).messages;
    }

    // ✅ Optimistic delete - remove immediately
    final updatedMessages = currentMessages
        .where((msg) => msg.id != event.messageId)
        .toList();

    emit(ConversationMessagesLoaded(
      conversationId: event.conversationId,
      messages: updatedMessages,
      conversations: _cachedConversations,
    ));

    try {
      // Delete from server
      await _messageRepository.deleteMessage(event.messageId);
      print('✅ Message deleted: ${event.messageId}');

      // Refresh conversations (update last message if needed)
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;

      emit(ConversationMessagesLoaded(
        conversationId: event.conversationId,
        messages: updatedMessages,
        conversations: conversations,
      ));
    } catch (error) {
      print('❌ Failed to delete message: $error');

      // Restore message on error
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