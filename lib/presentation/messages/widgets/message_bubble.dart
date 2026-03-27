import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final String currentUserId;
  final bool showAvatar;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.conversationId,
    required this.currentUserId,
    this.showAvatar = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.onReply,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;

  BorderRadius get _bubbleRadius {
    const double full = 20.0;
    const double tail = 5.0;
    const double mid = 14.0;

    if (widget.isMe) {
      if (widget.isFirstInGroup && widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(tail),
        );
      } else if (widget.isFirstInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(full),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(mid),
        );
      } else if (widget.isLastInGroup) {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(mid),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(tail),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(full),
          topRight: Radius.circular(mid),
          bottomLeft: Radius.circular(full),
          bottomRight: Radius.circular(mid),
        );
      }
    } else {
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

  void _onRightClick(TapDownDetails details) {
    showMessageContextMenu(
      context: context,
      tapPosition: details.globalPosition,
      message: widget.message,
      isMe: widget.isMe,
      conversationId: widget.conversationId,
      currentUserId: widget.currentUserId,
      onReply: widget.onReply,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasReactions = widget.message.reactions.isNotEmpty;
    // Extra bottom space when reactions are shown so they don't overlap next message
    final reactionExtra = hasReactions ? 20.0 : 0.0;
    final bottomPadding = (widget.isLastInGroup ? 14.0 : 3.0) + reactionExtra;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: GestureDetector(
        onSecondaryTapDown: _onRightClick,
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
                if (!widget.isMe) ...[
                  const SizedBox(width: 8),
                ],

                Flexible(
                  child: Column(
                    crossAxisAlignment: widget.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Bubble + reactions stack
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The bubble itself
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            constraints: const BoxConstraints(maxWidth: 480),
                            padding: widget.message.attachments.any((a) => a.isImage)
                                ? const EdgeInsets.all(4)
                                : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                                      color: const Color(0xFF7C3AED).withOpacity(0.06),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Quoted reply block
                                if (widget.message.replyTo != null)
                                  Container(
                                    margin: widget.message.attachments.any((a) => a.isImage)
                                        ? const EdgeInsets.fromLTRB(4, 4, 4, 0)
                                        : const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: widget.isMe
                                          ? Colors.white.withOpacity(0.12)
                                          : const Color(0xFF7C3AED).withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border(
                                        left: BorderSide(
                                          color: widget.isMe ? Colors.white54 : const Color(0xFF7C3AED),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.message.replyTo!.senderName.isNotEmpty
                                              ? widget.message.replyTo!.senderName
                                              : 'Unknown',
                                          style: TextStyle(
                                            color: widget.isMe ? Colors.white70 : const Color(0xFF7C3AED),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.message.replyTo!.content.isNotEmpty
                                              ? widget.message.replyTo!.content
                                              : 'Attachment',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: widget.isMe ? Colors.white54 : Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Image attachments
                                ...widget.message.attachments.where((a) => a.isImage).map((att) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: GestureDetector(
                                      onTap: () => _showImageDialog(context, att.fileUrl),
                                      child: SizedBox(
                                        width: 260,
                                        height: 180,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            att.fileUrl,
                                            width: 260,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (ctx, child, progress) {
                                              if (progress == null) return child;
                                              return Container(
                                                width: 260, height: 180,
                                                decoration: BoxDecoration(
                                                  color: widget.isMe ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              );
                                            },
                                            errorBuilder: (ctx, err, stack) {
                                              return Container(
                                                width: 260, height: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.broken_image, color: Colors.red),
                                                      const SizedBox(height: 4),
                                                      Text(att.fileName, style: TextStyle(fontSize: 10, color: Colors.red.shade300)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // File attachments (non-image)
                                ...widget.message.attachments.where((a) => !a.isImage).map((att) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: GestureDetector(
                                      onTap: () => launchUrl(Uri.parse(att.fileUrl), mode: LaunchMode.externalApplication),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: widget.isMe ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.insert_drive_file, size: 18,
                                              color: widget.isMe ? Colors.white70 : const Color(0xFF7C3AED)),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                att.fileName,
                                                style: TextStyle(
                                                  color: widget.isMe ? Colors.white : const Color(0xFF2D2252),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(Icons.download, size: 14,
                                              color: widget.isMe ? Colors.white54 : Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Text content (with clickable links)
                                if (widget.message.content.isNotEmpty)
                                  Padding(
                                    padding: widget.message.attachments.any((a) => a.isImage)
                                        ? const EdgeInsets.fromLTRB(12, 6, 12, 6)
                                        : EdgeInsets.zero,
                                    child: _buildLinkifiedText(
                                      widget.message.content,
                                      widget.isMe,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Reaction badges — floating below the bubble
                          if (hasReactions)
                            Positioned(
                              bottom: -16,
                              left: widget.isMe ? null : 12,
                              right: widget.isMe ? 12 : null,
                              child: _ReactionBadges(
                                reactions: widget.message.reactions,
                                currentUserId: widget.currentUserId,
                                onTap: (emoji) {
                                  context.read<MessagesBloc>().add(
                                    MessageReactionToggled(
                                      conversationId: widget.conversationId,
                                      messageId: widget.message.id,
                                      emoji: emoji,
                                      userId: widget.currentUserId,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
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
                                  style: const TextStyle(
                                    color: Color(0xFFA78BFA),
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

                if (widget.isMe) ...[
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<]+',
    caseSensitive: false,
  );

  Widget _buildLinkifiedText(String text, bool isMe) {
    final matches = _urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: _textStyle(isMe),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before the link
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _textStyle(isMe),
        ));
      }
      // The link itself
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: _textStyle(isMe).copyWith(
          decoration: TextDecoration.underline,
          decorationColor: isMe ? Colors.white70 : const Color(0xFF7C3AED),
          color: isMe ? Colors.white : const Color(0xFF7C3AED),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ));
      lastEnd = match.end;
    }

    // Remaining text after last link
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: _textStyle(isMe),
      ));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  TextStyle _textStyle(bool isMe) {
    return TextStyle(
      color: isMe
          ? Colors.white
          : ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF2D2252),
      fontSize: 14.5,
      height: 1.45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}

/// Compact row of reaction badges shown below a message bubble.
class _ReactionBadges extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final void Function(String emoji) onTap;

  const _ReactionBadges({
    required this.reactions,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        final iMeReacted = users.contains(currentUserId);

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => onTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: iMeReacted
                    ? const Color(0xFF7C3AED).withOpacity(isDark ? 0.35 : 0.15)
                    : isDark
                        ? const Color(0xFF252838)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iMeReacted
                      ? const Color(0xFF7C3AED).withOpacity(0.5)
                      : isDark
                          ? const Color(0xFF353848)
                          : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  if (users.length > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '${users.length}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: iMeReacted
                            ? const Color(0xFF7C3AED)
                            : isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
