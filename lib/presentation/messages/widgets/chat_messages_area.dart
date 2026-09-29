import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/debounced_json_cache.dart';
import 'message_bubble.dart';
import 'messages_empty_state.dart';
import 'messages_error_state.dart';

class ChatMessagesArea extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final void Function(MessageModel)? onReply;

  const ChatMessagesArea({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.onReply,
  });

  @override
  State<ChatMessagesArea> createState() => _ChatMessagesAreaState();
}

class _ChatMessagesAreaState extends State<ChatMessagesArea>
    with SingleTickerProviderStateMixin {
  /// Auto-scroll to newly arrived messages only when the user is this close
  /// to the bottom (offset 0 in the reversed list).
  static const double _autoScrollThreshold = 150;

  /// Start loading older messages when this close to the top
  /// (maxScrollExtent in the reversed list).
  static const double _loadOlderThreshold = 200;

  /// Only the most recent messages are persisted to the local cache.
  static const int _cachedMessageLimit = 50;

  final ScrollController _scrollController = ScrollController();
  final DebouncedJsonCache _cache = DebouncedJsonCache();
  late AnimationController _animationController;
  late final MessagesBloc _messagesBloc;

  /// Chronological order (oldest first); rendered reversed.
  List<MessageModel> _messages = [];
  bool _isLoaded = false;
  bool _hasMoreMessages = true;
  bool _isLoadingOlder = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _messagesBloc = context.read<MessagesBloc>();
    _scrollController.addListener(_onScroll);
    _restoreMessages();
    _loadMessages();
  }

  @override
  void didUpdateWidget(ChatMessagesArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      // Persist whatever was pending for the previous conversation.
      _cache.flush();
      _messages = [];
      _isLoaded = false;
      _hasMoreMessages = true;
      _isLoadingOlder = false;
      _scrollToBottom(animate: false);
      _restoreMessages();
      _loadMessages();
    }
  }

  /// Shows messages immediately when switching back to a conversation: from
  /// the bloc's live subscription if it's still active, otherwise from the
  /// local cache.
  void _restoreMessages() {
    final live = _messagesBloc.currentMessagesFor(widget.conversation.id);
    if (live != null) {
      _messages = live;
      _isLoaded = true;
      _hasMoreMessages = _messagesBloc.hasMoreMessages;
      return;
    }
    _loadCachedMessages();
  }

  Future<void> _loadCachedMessages() async {
    final conversationId = widget.conversation.id;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_$conversationId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final cachedMessages =
            jsonList.map((json) => MessageModel.fromJson(json)).toList();

        // Don't clobber live data that arrived first, or apply a stale read
        // after the user switched conversations.
        if (mounted &&
            widget.conversation.id == conversationId &&
            _messages.isEmpty) {
          setState(() {
            _messages = cachedMessages;
            _isLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cached messages: $e');
    }
  }

  /// Debounced (≈2s) write of the most recent messages to the local cache.
  void _saveCachedMessages(List<MessageModel> messages) {
    final cacheKey = 'messages_${widget.conversation.id}';
    _cache.schedule(cacheKey, () {
      final recent = messages.length > _cachedMessageLimit
          ? messages.sublist(messages.length - _cachedMessageLimit)
          : messages;
      return recent.map((m) => m.toJson()).toList();
    });
  }

  /// The single place that requests the conversation's message subscription
  /// (initial open, conversation switch, re-entering the screen). The bloc
  /// ignores the request when that conversation is already subscribed.
  void _loadMessages({bool force = false}) {
    _messagesBloc.add(
      ConversationMessagesLoadRequested(widget.conversation.id, force: force),
    );
  }

  void _retryLoadMessages() => _loadMessages(force: true);

  bool get _isNearBottom =>
      !_scrollController.hasClients ||
      _scrollController.position.pixels <= _autoScrollThreshold;

  /// Scrolls to the newest message (offset 0 in the reversed list).
  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _onScroll() {
    if (!_shouldLoadOlder()) return;
    // Scroll offsets can be corrected during layout; never setState mid-frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestOlderMessages());
    } else {
      _requestOlderMessages();
    }
  }

  bool _shouldLoadOlder() {
    if (!mounted || !_scrollController.hasClients) return false;
    if (!_hasMoreMessages || _isLoadingOlder || _messages.isEmpty) return false;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - _loadOlderThreshold;
  }

  void _requestOlderMessages() {
    if (!_shouldLoadOlder()) return;
    setState(() => _isLoadingOlder = true);
    _messagesBloc.add(OlderMessagesLoadRequested(widget.conversation.id));
    // Safety net: if the bloc ignores the request (e.g. not subscribed yet),
    // no loaded state follows — don't leave the spinner up forever.
    Future.delayed(const Duration(seconds: 16), () {
      if (mounted && _isLoadingOlder) setState(() => _isLoadingOlder = false);
    });
  }

  void _onMessagesLoaded(ConversationMessagesLoaded state) {
    final previous = _messages;
    final hasNewestMessage = state.messages.isNotEmpty &&
        (previous.isEmpty || state.messages.last.id != previous.last.id);
    final wasNearBottom = _isNearBottom;
    final messagesChanged = !identical(state.messages, previous);

    // Always update messages to pick up attachment/field changes
    setState(() {
      _messages = state.messages;
      _isLoaded = true;
      _hasMoreMessages = state.hasMoreMessages;
      _isLoadingOlder = state.isLoadingOlder;
    });
    if (messagesChanged) _saveCachedMessages(state.messages);

    if (hasNewestMessage && previous.isNotEmpty) {
      final sentByMe = state.messages.last.senderId == widget.currentUserId;
      if (wasNearBottom || sentByMe) _scrollToBottom();
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    // Flush pending cache writes; the writer never touches widget state.
    _cache.flush();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessagesBloc, MessagesState>(
      listenWhen: (previous, current) =>
          current is ConversationMessagesLoaded &&
          current.conversationId == widget.conversation.id,
      listener: (context, state) {
        if (state is ConversationMessagesLoaded) _onMessagesLoaded(state);
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Only rebuild on this conversation's error changes — message updates
    // arrive through the listener above (local state), not a whole-bloc watch.
    return BlocSelector<MessagesBloc, MessagesState, String?>(
      key: ValueKey(widget.conversation.id),
      selector: (state) => state is ConversationMessagesError &&
              state.conversationId == widget.conversation.id
          ? state.message
          : null,
      builder: (context, error) {
        if (error != null && _messages.isEmpty && _isLoaded) {
          return MessagesErrorState(
            error: error,
            onRetry: _retryLoadMessages,
          );
        }

        if (_messages.isEmpty) {
          // Avoid flashing the empty state while switching conversations.
          return _isLoaded ? const MessagesEmptyState() : const SizedBox.expand();
        }

        return _buildMessagesList(_messages);
      },
    );
  }

  Widget _buildMessagesList(List<MessageModel> messages) {
    final count = messages.length;
    final indexById = <String, int>{
      for (var i = 0; i < count; i++) messages[i].id: i,
    };

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
        // reverse: true keeps the view anchored to the newest message without
        // per-build jumps. Item 0 is the newest message; the date divider (and
        // the older-messages loader) sit after the oldest message, i.e. on top.
        ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: count + 1 + (_isLoadingOlder ? 1 : 0), // +1 for date divider
          findChildIndexCallback: (key) {
            if (key is ValueKey<String>) {
              final msgIndex = indexById[key.value];
              if (msgIndex != null) return count - 1 - msgIndex;
            }
            return null;
          },
          itemBuilder: (context, index) {
            if (index == count) {
              return _buildDateDivider();
            }
            if (index > count) {
              return _buildOlderMessagesLoader();
            }

            // Map reversed list index back to chronological order.
            final msgIndex = count - 1 - index;
            final message = messages[msgIndex];
            final isMe = message.senderId == widget.currentUserId;

            final isLastInGroup = msgIndex == count - 1 ||
                messages[msgIndex + 1].senderId != message.senderId;

            final isFirstInGroup = msgIndex == 0 ||
                messages[msgIndex - 1].senderId != message.senderId;

            return MessageBubble(
              key: ValueKey<String>(message.id),
              message: message,
              isMe: isMe,
              conversationId: widget.conversation.id,
              currentUserId: widget.currentUserId,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
              onReply: widget.onReply != null ? () => widget.onReply!(message) : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOlderMessagesLoader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFA78BFA),
          ),
        ),
      ),
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