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
  
  // ✅ NEW: Cache messages per conversation so they survive navigation
  final Map<String, List<MessageModel>> _messageCache = {};
  
  // ✅ NEW: Track request IDs to prevent stale responses
  int _loadRequestId = 0;

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

    // ✅ Always add to message cache, regardless of current view
    final cachedMessages = _messageCache[message.conversationId] ?? [];
    if (!cachedMessages.any((m) => m.id == message.id)) {
      _messageCache[message.conversationId] = [...cachedMessages, message];
      print('✅ Message cached for conversation: ${message.conversationId}');
    } else {
      print('⚠️ Duplicate message ignored: ${message.id}');
      return;
    }

    // ✅ If viewing this conversation, update UI instantly
    if (_currentConversationId == message.conversationId && 
        state is ConversationMessagesLoaded) {
      emit(ConversationMessagesLoaded(
        conversationId: message.conversationId,
        messages: _messageCache[message.conversationId]!,
        conversations: _cachedConversations,
      ));
      print('✅ Message added to current conversation view INSTANTLY');
    }

    // ✅ BACKGROUND: Refresh conversation list
    _messageRepository.getConversations().then((conversations) {
      _cachedConversations = conversations;
      if (state is ConversationMessagesLoaded) {
        final currentState = state as ConversationMessagesLoaded;
        add(MessagesRefreshRequested());
      } else if (state is MessagesLoaded) {
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
    // ✅ Don't show loading if we have cached conversations
    if (_cachedConversations.isEmpty) {
      emit(const MessagesLoading());
    }
    
    try {
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      emit(MessagesLoaded(conversations));
    } catch (e) {
      // ✅ If we have cache, use it instead of showing error
      if (_cachedConversations.isNotEmpty) {
        emit(MessagesLoaded(_cachedConversations));
      } else {
        emit(MessagesError(e.toString()));
      }
    }
  }

  Future<void> _onMessagesRefreshRequested(
    MessagesRefreshRequested event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      final conversations = await _messageRepository.getConversations();
      _cachedConversations = conversations;
      
      // ✅ Preserve current conversation view if we're in one
      if (_currentConversationId != null && 
          _messageCache.containsKey(_currentConversationId)) {
        emit(ConversationMessagesLoaded(
          conversationId: _currentConversationId!,
          messages: _messageCache[_currentConversationId]!,
          conversations: conversations,
        ));
      } else {
        emit(MessagesLoaded(conversations));
      }
    } catch (e) {
      print('⚠️ Refresh failed: $e');
    }
  }

  Future<void> _onConversationMessagesLoadRequested(
    ConversationMessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    final requestConversationId = event.conversationId;
    print('🚀 BLoC: Loading messages for conversation $requestConversationId');
    
    _currentConversationId = requestConversationId;
    
    // ✅ NEW: Increment request ID to track this specific request
    final thisRequestId = ++_loadRequestId;
    
    // ✅ Show cached messages immediately if available (no loading spinner)
    if (_messageCache.containsKey(requestConversationId)) {
      emit(ConversationMessagesLoaded(
        conversationId: requestConversationId,
        messages: _messageCache[requestConversationId]!,
        conversations: _cachedConversations,
      ));
    } else {
      emit(ConversationMessagesLoading(requestConversationId));
    }
    
    try {
      final results = await Future.wait([
        _messageRepository.getMessagesForConversation(requestConversationId),
        _messageRepository.getConversations(),
      ]);
      
      // ✅ NEW: Guard against stale responses — if user switched conversations
      // while we were loading, discard this response
      if (thisRequestId != _loadRequestId || 
          _currentConversationId != requestConversationId) {
        print('⚠️ BLoC: Discarding stale response for $requestConversationId (current: $_currentConversationId)');
        return;
      }
      
      final apiMessages = results[0] as List<MessageModel>;
      final conversations = results[1] as List<ConversationModel>;
      _cachedConversations = conversations;
      
      // ✅ Merge: keep any socket messages that arrived while we were fetching
      final existingCache = _messageCache[requestConversationId] ?? [];
      final apiMessageIds = apiMessages.map((m) => m.id).toSet();
      final socketOnlyMessages = existingCache.where(
        (m) => !apiMessageIds.contains(m.id) && !m.id.startsWith('temp-'),
      ).toList();
      
      final mergedMessages = [...apiMessages, ...socketOnlyMessages];
      mergedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      _messageCache[requestConversationId] = mergedMessages;
      
      print('✅ BLoC: Got ${apiMessages.length} from API + ${socketOnlyMessages.length} socket-only = ${mergedMessages.length} total');
      
      emit(ConversationMessagesLoaded(
        conversationId: requestConversationId,
        messages: mergedMessages,
        conversations: conversations,
      ));
    } catch (e) {
      // ✅ Guard stale errors too
      if (thisRequestId != _loadRequestId) return;
      
      print('❌ BLoC: Error loading messages: $e');
      emit(ConversationMessagesError(
        conversationId: requestConversationId,
        message: e.toString(),
        conversations: _cachedConversations,
      ));
    }
  }

  Future<void> _onMessageSendRequested(
    MessageSendRequested event,
    Emitter<MessagesState> emit,
  ) async {
    List<MessageModel> currentMessages = 
        _messageCache[event.conversationId] ?? [];
    
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
    _messageCache[event.conversationId] = optimisticMessages;
    
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
      
      _messageCache[event.conversationId] = updatedMessages;
      
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
      
      // ✅ Restore cache without the optimistic message
      _messageCache[event.conversationId] = currentMessages;
      
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
    List<MessageModel> currentMessages = 
        _messageCache[event.conversationId] ?? [];

    final updatedMessages = currentMessages
        .where((msg) => msg.id != event.messageId)
        .toList();

    _messageCache[event.conversationId] = updatedMessages;

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

      _messageCache[event.conversationId] = currentMessages;

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