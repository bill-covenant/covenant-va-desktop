import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'message_bubble.dart';
import 'messages_empty_state.dart';
import 'messages_error_state.dart';

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

class _ChatMessagesAreaState extends State<ChatMessagesArea>
    with SingleTickerProviderStateMixin {
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
        final cachedMessages =
            jsonList.map((json) => MessageModel.fromJson(json)).toList();

        if (mounted) {
          setState(() {
            _messages = cachedMessages;
            _isLoaded = true;
          });
          _scrollToBottom(animate: false);
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

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessagesBloc, MessagesState>(
      listener: (context, state) {
        if (state is ConversationMessagesLoaded) {
          if (state.conversationId == widget.conversation.id) {
            final hasNewMessages = state.messages.length != _messages.length ||
                (state.messages.isNotEmpty &&
                    _messages.isNotEmpty &&
                    state.messages.last.id != _messages.last.id);
            // Always update messages to pick up attachment/field changes
            setState(() {
              _messages = state.messages;
              _isLoaded = true;
            });
            _saveCachedMessages(state.messages);
            if (hasNewMessages) {
              _scrollToBottom();
              _animationController.forward(from: 0.0);
            }
          }
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final state = context.watch<MessagesBloc>().state;

    if (state is ConversationMessagesError) {
      if (state.conversationId == widget.conversation.id &&
          _messages.isEmpty &&
          _isLoaded) {
        return MessagesErrorState(
          error: state.message,
          onRetry: _loadMessages,
        );
      }
    }

    if (_messages.isEmpty) {
      return const MessagesEmptyState();
    }

    return _buildMessagesList(_messages);
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Stack(
      children: [
        // ── Layer 1: Gradient background ──
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ThemeProvider().isDarkMode
                    ? [const Color(0xFF0F1117), const Color(0xFF151822), const Color(0xFF1A1D2E), const Color(0xFF151822)]
                    : [const Color(0xFFE8DEFF), const Color(0xFFDDD0FC), const Color(0xFFE0D2FB), const Color(0xFFEDD8FC)],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // ── Layer 2: Subtle pattern overlay ──
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ChatBackgroundPatternPainter(),
            ),
          ),
        ),

        // ── Layer 3: Soft ambient light blobs ──
        Positioned(
          top: -80,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -40,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: 100,
          child: IgnorePointer(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Layer 4: Messages list ──
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: messages.length + 1, // +1 for date divider
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildDateDivider();
            }

            final msgIndex = index - 1;
            final message = messages[msgIndex];
            final isMe = message.senderId == widget.currentUserId;

            final isLastInGroup = msgIndex == messages.length - 1 ||
                messages[msgIndex + 1].senderId != message.senderId;

            final isFirstInGroup = msgIndex == 0 ||
                messages[msgIndex - 1].senderId != message.senderId;

            return MessageBubble(
              message: message,
              isMe: isMe,
              conversationId: widget.conversation.id,
              currentUserId: widget.currentUserId,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF7C3AED).withOpacity(0.08),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA78BFA),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF7C3AED).withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a subtle repeating pattern of small shapes for the chat background.
/// Uses tiny circles, dots, and plus signs in very low opacity
/// to create a WhatsApp/Telegram-style themed wallpaper feel.
class _ChatBackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 40.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Offset every other row for a honeycomb-like stagger
        final double offsetX = (row % 2 == 0) ? 0 : spacing / 2;
        final double x = col * spacing + offsetX;
        final double y = row * spacing;

        // Use position to deterministically pick a shape
        final int shapeIndex = (row * 7 + col * 13) % 5;

        // Clearly visible but still tasteful (12% - 18%)
        final double opacity = 0.12 + ((row * 3 + col * 5) % 4) * 0.02;
        paint.color = const Color(0xFF8B5CF6).withOpacity(opacity);

        switch (shapeIndex) {
          case 0:
            // Small circle
            canvas.drawCircle(Offset(x, y), 5.0, paint);
            break;
          case 1:
            // Dot (filled)
            paint.style = PaintingStyle.fill;
            paint.color = const Color(0xFF8B5CF6).withOpacity(opacity * 0.7);
            canvas.drawCircle(Offset(x, y), 2.5, paint);
            paint.style = PaintingStyle.stroke;
            paint.color = const Color(0xFF8B5CF6).withOpacity(opacity);
            break;
          case 2:
            // Plus / cross
            canvas.drawLine(
              Offset(x - 5, y),
              Offset(x + 5, y),
              paint,
            );
            canvas.drawLine(
              Offset(x, y - 5),
              Offset(x, y + 5),
              paint,
            );
            break;
          case 3:
            // Small diamond
            final path = Path()
              ..moveTo(x, y - 5)
              ..lineTo(x + 4.5, y)
              ..lineTo(x, y + 5)
              ..lineTo(x - 4.5, y)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case 4:
            // Small square (slightly rotated)
            canvas.save();
            canvas.translate(x, y);
            canvas.rotate(math.pi / 6);
            canvas.drawRect(
              const Rect.fromLTWH(-4, -4, 8, 8),
              paint,
            );
            canvas.restore();
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}