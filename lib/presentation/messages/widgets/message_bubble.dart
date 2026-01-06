import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/message_model.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import 'package:intl/intl.dart';
import 'message_menu.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String conversationId;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.conversationId,
    this.showAvatar = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Row(
          mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar on left for received messages
            if (!widget.isMe && widget.showAvatar) ...[
              _buildAvatar(),
              const SizedBox(width: 12),
            ] else if (!widget.isMe && !widget.showAvatar) ...[
              const SizedBox(width: 52),
            ],
            
            // Menu button on left (for received messages)
            if (!widget.isMe && _isHovered)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: MessageMenu(
                  message: widget.message,
                  isMe: widget.isMe,
                  conversationId: widget.conversationId,
                ),
              ),
            
            Flexible(
              child: Column(
                crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: widget.isMe
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF7C3AED),
                                Color(0xFFEC4899),
                              ],
                            )
                          : null,
                      color: widget.isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isMe
                              ? const Color(0xFF7C3AED).withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: widget.isMe
                              ? const Color(0xFFEC4899).withOpacity(0.2)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message.content,
                      style: TextStyle(
                        color: widget.isMe ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(widget.message.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.isMe && widget.message.isRead) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.done_all_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ] else if (widget.isMe && !widget.message.isRead) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.done_rounded,
                            size: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu button on right (for sent messages)
            if (widget.isMe && _isHovered)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: MessageMenu(
                  message: widget.message,
                  isMe: widget.isMe,
                  conversationId: widget.conversationId,
                ),
              ),
            
            // Avatar on right for sent messages
            if (widget.isMe && widget.showAvatar) ...[
              const SizedBox(width: 12),
              _buildAvatar(),
            ] else if (widget.isMe && !widget.showAvatar) ...[
              const SizedBox(width: 52),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isMe
              ? [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED),
                  const Color(0xFFEC4899),
                ]
              : [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.isMe
                ? const Color(0xFF7C3AED).withOpacity(0.4)
                : const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.isMe ? 'VA' : 'CL',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}