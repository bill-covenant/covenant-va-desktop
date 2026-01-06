import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'message_bubble.dart';
import 'messages_empty_state.dart';  // ✅ FIXED: Changed from empty_messages_state
import 'messages_error_state.dart';  // ✅ FIXED: Changed from error_messages_state

class ChatMessagesArea extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const ChatMessagesArea({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatMessagesArea> createState() => _ChatMessagesAreaState();
}

class _ChatMessagesAreaState extends State<ChatMessagesArea> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  
  List<MessageModel> _messages = [];
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCachedMessages();
    _loadMessages();
  }

  @override
  void didUpdateWidget(ChatMessagesArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _loadCachedMessages();
      _loadMessages();
    }
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.conversation.id}';
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final cachedMessages = jsonList
            .map((json) => MessageModel.fromJson(json))
            .toList();
        
        if (mounted) {
          setState(() {
            _messages = cachedMessages;
            _isLoaded = true;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('⚠️ Failed to load cached messages: $e');
    }
  }

  Future<void> _saveCachedMessages(List<MessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.conversation.id}';
      final jsonList = messages.map((m) => m.toJson()).toList();
      await prefs.setString(cacheKey, json.encode(jsonList));
    } catch (e) {
      print('⚠️ Failed to cache messages: $e');
    }
  }

  void _loadMessages() {
    context.read<MessagesBloc>().add(
          ConversationMessagesLoadRequested(widget.conversation.id),
        );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagesBloc, MessagesState>(
      listener: (context, state) {
        if (state is ConversationMessagesLoaded) {
          if (state.conversationId == widget.conversation.id) {
            setState(() {
              _messages = state.messages;
              _isLoaded = true;
            });
            _saveCachedMessages(state.messages);
            _scrollToBottom();
            _animationController.forward(from: 0.0);
          }
        }
      },
      builder: (context, state) {
        if (state is ConversationMessagesError) {
          if (state.conversationId == widget.conversation.id && _messages.isEmpty && _isLoaded) {
            return MessagesErrorState(  // ✅ FIXED: Changed from ErrorMessagesState
              error: state.message,
              onRetry: _loadMessages,
            );
          }
        }

        if (_messages.isEmpty) {
          return const MessagesEmptyState();  // ✅ FIXED: Changed from EmptyMessagesState
        }
        
        return _buildMessagesList(_messages);
      },
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    return Container(
      decoration: _buildBackgroundDecoration(),
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<MessagesBloc>().add(
                ConversationMessagesRefreshRequested(widget.conversation.id),
              );
        },
        color: const Color(0xFF7C3AED),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == widget.currentUserId;
            
            return MessageBubble(
              message: message,
              isMe: isMe,
              conversationId: widget.conversation.id,  // ✅ Already correct!
            );
          },
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFDFDFD),
          const Color(0xFFFAFAFA),
        ],
      ),
      image: DecorationImage(
        image: _buildPatternImage(),
        repeat: ImageRepeat.repeat,
        opacity: 0.03,
      ),
    );
  }

  ImageProvider _buildPatternImage() {
    return const NetworkImage(
      'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGNpcmNsZSBjeD0iMSIgY3k9IjEiIHI9IjEiIGZpbGw9IiM3QzNBRUQiLz48L3N2Zz4=',
    );
  }
}