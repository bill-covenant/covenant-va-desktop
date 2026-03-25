import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../services/call_service.dart';
import '../../../services/socket_service.dart';
import 'chat_header.dart';
import 'chat_messages_area.dart';
import 'chat_input.dart';

class ChatPanel extends StatefulWidget {
  final ConversationModel? conversation;
  final String currentUserId;
  final CallService? callService;

  const ChatPanel({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.callService,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  MessageModel? _replyingTo;

  @override
  void didUpdateWidget(ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear reply when conversation changes
    if (oldWidget.conversation?.id != widget.conversation?.id) {
      _replyingTo = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.conversation == null) {
      return _buildEmptyState();
    }

    final isNewConversation = widget.conversation!.id.startsWith('new_');

    return Column(
      children: [
        ChatHeader(
          conversation: widget.conversation!,
          currentUserId: widget.currentUserId,
          isOtherUserOnline: SocketService().isUserOnline(widget.conversation!.getOtherUserId(widget.currentUserId)),
          onAudioCall: widget.callService != null ? () {
            final otherUserId = widget.conversation!.getOtherUserId(widget.currentUserId);
            final otherUserName = widget.conversation!.getOtherParticipantName(widget.currentUserId);
            widget.callService!.startCall(otherUserId, otherUserName, 'audio');
          } : null,
          onVideoCall: widget.callService != null ? () {
            final otherUserId = widget.conversation!.getOtherUserId(widget.currentUserId);
            final otherUserName = widget.conversation!.getOtherParticipantName(widget.currentUserId);
            widget.callService!.startCall(otherUserId, otherUserName, 'video');
          } : null,
        ),

        Expanded(
          child: isNewConversation
              ? _buildNewConversationState()
              : ChatMessagesArea(
                  conversation: widget.conversation!,
                  currentUserId: widget.currentUserId,
                  onReply: (message) {
                    setState(() => _replyingTo = message);
                  },
                ),
        ),

        ChatInput(
          conversation: widget.conversation!,
          currentUserId: widget.currentUserId,
          replyingTo: _replyingTo,
          onClearReply: () {
            setState(() => _replyingTo = null);
          },
        ),
      ],
    );
  }

  Widget _buildNewConversationState() {
    final clientName = widget.conversation!.client?.fullName ?? 'Client';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                (widget.conversation!.client?.firstName.isNotEmpty == true
                    ? widget.conversation!.client!.firstName[0].toUpperCase()
                    : 'C'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            clientName,
            style: TextStyle(
              color: ThemeProvider().isDarkMode ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation',
            style: TextStyle(
              color: ThemeProvider().isDarkMode ? Colors.white54 : Colors.black.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: ThemeProvider().isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.black.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  'Type a message below to begin',
                  style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB24FE0), Color(0xFF8B2FC9)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: const Color(0xFF8B2FC9).withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15)),
                BoxShadow(color: const Color(0xFFB24FE0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -5),
                BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 10, offset: const Offset(-2, -2)),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ),
                const Center(child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 56)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Conversation Selected',
            style: TextStyle(
              color: ThemeProvider().isDarkMode ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a conversation from the list to start chatting',
            style: TextStyle(
              color: ThemeProvider().isDarkMode ? Colors.white54 : Colors.black.withOpacity(0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
