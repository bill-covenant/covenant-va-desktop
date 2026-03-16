import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import 'package:intl/intl.dart';

class ConversationListItem extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ConversationListItem> createState() => _ConversationListItemState();
}

class _ConversationListItemState extends State<ConversationListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final otherUserName =
        widget.conversation.getOtherParticipantName(widget.currentUserId);
    final hasUnread = widget.conversation.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            transform: Matrix4.translationValues(
              _isHovered && !widget.isSelected ? 3.0 : 0,
              0,
              0,
            ),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF7C3AED).withOpacity(0.1),
                        const Color(0xFFA855F7).withOpacity(0.06),
                      ],
                    )
                  : null,
              color: widget.isSelected
                  ? null
                  : _isHovered
                      ? const Color(0xFF7C3AED).withOpacity(0.03)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFF7C3AED).withOpacity(0.12)
                    : Colors.transparent,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                _buildAvatar(otherUserName),
                const SizedBox(width: 13),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName,
                              style: TextStyle(
                                color: widget.isSelected
                                    ? const Color(0xFF5B21B6)
                                    : ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
                                fontSize: 14.5,
                                fontWeight:
                                    hasUnread ? FontWeight.w700 : FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.conversation.lastMessageAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(widget.conversation.lastMessageAt!),
                              style: TextStyle(
                                color: const Color(0xFFA78BFA).withOpacity(0.8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.conversation.lastMessage ??
                                  'No messages yet',
                              style: TextStyle(
                                color: hasUnread
                                    ? (ThemeProvider().isDarkMode ? const Color(0xFFB4A3CC) : const Color(0xFF6D28D9))
                                    : (ThemeProvider().isDarkMode ? Colors.white54 : const Color(0xFF8B7FA8)),
                                fontSize: 13,
                                fontWeight:
                                    hasUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFA855F7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED)
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.conversation.unreadCount > 9
                                      ? '9+'
                                      : widget.conversation.unreadCount
                                          .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (widget.isSelected)
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB24FE0),
                  Color(0xFF8B2FC9),
                ],
              ),
              shape: BoxShape.circle,
              border: widget.isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B2FC9).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Online indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}