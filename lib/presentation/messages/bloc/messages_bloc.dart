import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
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

  // ── Active conversation subscription ──
  static const int _pageSize = FirebaseMessageRepository.messagesPageSize;
  bool _isMessagesSubscribed = false;
  int _subscriptionToken = 0;
  int _messageLimit = _pageSize;
  List<MessageModel> _currentMessages = const [];
  bool _hasMoreMessages = true;
  Completer<void>? _olderLoadCompleter;

  MessagesBloc({required FirebaseMessageRepository messageRepository})
      : _messageRepository = messageRepository,
        super(const MessagesInitial()) {
    on<MessagesLoadRequested>(
      _onMessagesLoadRequested,
      transformer: restartable(),
    );
    on<MessagesRefreshRequested>(_onMessagesRefreshRequested);
    on<ConversationMessagesLoadRequested>(
      _onConversationMessagesLoadRequested,
      transformer: _conversationSubscriptionTransformer(),
    );
    on<OlderMessagesLoadRequested>(
      _onOlderMessagesLoadRequested,
      transformer: droppable(),
    );
    on<MessageSendRequested>(_onMessageSendRequested);
    on<MessageDeleteRequested>(_onMessageDeleteRequested);
    on<UnreadCountLoadRequested>(_onUnreadCountLoadRequested);
    on<MessageReactionToggled>(_onMessageReactionToggled);
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
          debugPrint('❌ Conversations stream error: $error');
          return _cachedConversations.isNotEmpty
              ? MessagesLoaded(_cachedConversations)
              : MessagesError(error.toString());
        },
      );
    } catch (e) {
      debugPrint('❌ MessagesLoadRequested error: $e');
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

  /// Latest messages of the active subscription for [conversationId], or null
  /// when that conversation isn't the one currently subscribed. Lets a newly
  /// mounted chat view render immediately when the load request is skipped
  /// because the subscription is already live.
  List<MessageModel>? currentMessagesFor(String conversationId) {
    if (conversationId != _currentConversationId || _currentMessages.isEmpty) {
      return null;
    }
    return _currentMessages;
  }

  /// Whether older messages may exist for the active conversation.
  bool get hasMoreMessages => _hasMoreMessages;

  /// Drops load requests for the conversation that is already subscribed
  /// (unless forced), and restarts the subscription for everything else so a
  /// conversation switch cancels the previous stream.
  EventTransformer<ConversationMessagesLoadRequested>
      _conversationSubscriptionTransformer() {
    final restart = restartable<ConversationMessagesLoadRequested>();
    return (events, mapper) => restart(
          events.where((event) {
            final alreadySubscribed = !event.force &&
                _isMessagesSubscribed &&
                event.conversationId == _currentConversationId;
            if (alreadySubscribed) {
              debugPrint(
                  '⏭️ Already subscribed to ${event.conversationId}, skipping reload');
              // Still clear unread messages that arrived while the chat was
              // off-screen (the full load used to do this on every open).
              _messageRepository
                  .markConversationRead(event.conversationId, _currentUserId)
                  .catchError((Object e) {
                debugPrint('⚠️ markConversationRead failed: $e');
              });
            }
            return !alreadySubscribed;
          }),
          mapper,
        );
  }

  void _completeOlderLoad() {
    final completer = _olderLoadCompleter;
    _olderLoadCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<void> _onConversationMessagesLoadRequested(
    ConversationMessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    final conversationId = event.conversationId;
    final isSameConversation = conversationId == _currentConversationId;
    final token = ++_subscriptionToken;
    _currentConversationId = conversationId;
    _isMessagesSubscribed = true;

    if (!isSameConversation) {
      _messageLimit = _pageSize;
      _currentMessages = const [];
      _hasMoreMessages = true;
      _completeOlderLoad();
    }

    // Resubscribing with a larger limit to page in older messages: keep the
    // current messages on screen and don't re-mark the conversation as read.
    final isPagingOlder = isSameConversation && _olderLoadCompleter != null;
    final limit = _messageLimit;

    if (!isPagingOlder) {
      emit(ConversationMessagesLoading(conversationId));
    }

    try {
      if (!isPagingOlder) {
        await _messageRepository.markConversationRead(
            conversationId, _currentUserId);
      }

      await emit.forEach<List<MessageModel>>(
        _messageRepository.messagesStream(conversationId, limit: limit),
        onData: (messages) {
          _currentMessages = messages;
          _hasMoreMessages = messages.length >= limit;
          if (limit == _messageLimit) _completeOlderLoad();
          return ConversationMessagesLoaded(
            conversationId: conversationId,
            messages: messages,
            conversations: _cachedConversations,
            hasMoreMessages: _hasMoreMessages,
          );
        },
        onError: (error, _) {
          _completeOlderLoad();
          return ConversationMessagesError(
            conversationId: conversationId,
            message: error.toString(),
            conversations: _cachedConversations,
          );
        },
      );
    } catch (e) {
      debugPrint('❌ ConversationMessagesLoadRequested error: $e');
      _completeOlderLoad();
      emit(ConversationMessagesError(
        conversationId: conversationId,
        message: e.toString(),
        conversations: _cachedConversations,
      ));
    } finally {
      // Only the latest subscription may clear the flag — a cancelled
      // (restarted) handler finishing late must not mark the new one inactive.
      if (token == _subscriptionToken) _isMessagesSubscribed = false;
    }
  }

  Future<void> _onOlderMessagesLoadRequested(
    OlderMessagesLoadRequested event,
    Emitter<MessagesState> emit,
  ) async {
    if (event.conversationId != _currentConversationId ||
        !_isMessagesSubscribed ||
        !_hasMoreMessages ||
        _olderLoadCompleter != null) {
      return;
    }

    final completer = Completer<void>();
    _olderLoadCompleter = completer;
    _messageLimit += _pageSize;

    emit(ConversationMessagesLoaded(
      conversationId: event.conversationId,
      messages: _currentMessages,
      conversations: _cachedConversations,
      hasMoreMessages: true,
      isLoadingOlder: true,
    ));

    // Resubscribe with the larger limit; restartable() cancels the old stream.
    add(ConversationMessagesLoadRequested(event.conversationId, force: true));

    // Hold this handler until the bigger page arrives so droppable() ignores
    // repeated scroll-to-top triggers in the meantime.
    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );
    if (identical(_olderLoadCompleter, completer)) _olderLoadCompleter = null;
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
        attachments: event.attachments,
        replyTo: event.replyTo,
      );
    } catch (error) {
      debugPrint('❌ Failed to send message: $error');
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
      debugPrint('❌ Failed to delete message: $error');
    }
  }

  Future<void> _onMessageReactionToggled(
    MessageReactionToggled event,
    Emitter<MessagesState> emit,
  ) async {
    try {
      await _messageRepository.toggleReaction(
        conversationId: event.conversationId,
        messageId: event.messageId,
        emoji: event.emoji,
        userId: event.userId,
      );
    } catch (error) {
      debugPrint('❌ Failed to toggle reaction: $error');
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
