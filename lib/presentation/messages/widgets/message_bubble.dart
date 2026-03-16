import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
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
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.conversationId,
    this.showAvatar = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;

  // Adaptive border radius based on position in a consecutive group.
  // The "tail" corner (small radius) only appears on the last message.
  // Middle messages get fully rounded corners.
  BorderRadius get _bubbleRadius {
    const double full = 20.0;
    const double tail = 5.0;
    const double mid = 14.0; // slightly less rounded for middle messages

    if (widget.isMe) {
      // Sent messages — tail is bottom-right
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        // Solo message
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(tail),
        );
      } else if (widget.isFirstInGroup) {
        // First in group — rounded top, rounded bottom-right
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(mid),
        );
      } else if (widget.isLastInGroup) {
        // Last in group — slightly less rounded top, tail bottom-right
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(mid),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(tail),
        );
      } else {
        // Middle message
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(mid),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(mid),
        );
      }
    } else {
      // Received messages — tail is bottom-left
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(tail),
          bottomRight: Radius.circular(full),
        );
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(mid),
          bottomRight: Radius.circular(full),
        );
      } else if (widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(mid),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(tail),
          bottomRight: Radius.circular(full),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(mid),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(mid),
          bottomRight: Radius.circular(full),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tighter spacing between grouped messages, more space at group boundaries
    final bottomPadding = widget.isLastInGroup ? 14.0 : 3.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -1.0 : 0, 0),
          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // No avatar for received messages
              if (!widget.isMe) ...[
                const SizedBox(width: 8),
              ],

              // Menu button left (received)
              if (!widget.isMe && _isHovered)
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 4),
                  child: MessageMenu(
                    message: widget.message,
                    isMe: widget.isMe,
                    conversationId: widget.conversationId,
                  ),
                ),

              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Bubble
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        gradient: widget.isMe
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF7C3AED),
                                ],
                              )
                            : null,
                        color: widget.isMe
                            ? null
                            : ThemeProvider().isDarkMode
                                ? const Color(0xFF1A1D2E)
                                : Colors.white.withOpacity(0.95),
                        borderRadius: _bubbleRadius,
                        border: widget.isMe
                            ? null
                            : Border.all(
                                color:
                                    const Color(0xFF7C3AED).withOpacity(0.06),
                              ),
                        boxShadow: [
                          if (widget.isMe) ...[
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withOpacity(_isHovered ? 0.35 : 0.22),
                              blurRadius: _isHovered ? 20 : 14,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withOpacity(_isHovered ? 0.15 : 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                              spreadRadius: -4,
                            ),
                          ] else ...[
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(_isHovered ? 0.07 : 0.04),
                              blurRadius: _isHovered ? 14 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ],
                      ),
                      child: Text(
                        widget.message.content,
                        style: TextStyle(
                          color: widget.isMe
                              ? Colors.white
                              : ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF2D2252),
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    // Timestamp — only shown on the last message in a group
                    if (widget.isLastInGroup) ...[
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.65,
                          duration: const Duration(milliseconds: 200),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(widget.message.createdAt),
                                style: TextStyle(
                                  color: const Color(0xFFA78BFA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.isMe) ...[
                                const SizedBox(width: 5),
                                Icon(
                                  widget.message.isRead
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  size: 14,
                                  color: widget.message.isRead
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFB4A3CC),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Menu button right (sent)
              if (widget.isMe && _isHovered)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 4),
                  child: MessageMenu(
                    message: widget.message,
                    isMe: widget.isMe,
                    conversationId: widget.conversationId,
                  ),
                ),

              // No avatar for sent messages
              if (widget.isMe) ...[
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final colors = widget.isMe
        ? [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
        : [const Color(0xFF10B981), const Color(0xFF059669)];

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
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