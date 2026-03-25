import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/message_model.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';

/// Quick-react emojis shown in the floating bar (WhatsApp-style).
const List<String> kQuickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Shows a WhatsApp-style reaction bar + context menu anchored near [anchorRect].
/// Returns when the overlay is dismissed.
void showMessageContextMenu({
  required BuildContext context,
  required Offset tapPosition,
  required MessageModel message,
  required bool isMe,
  required String conversationId,
  required String currentUserId,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => _MessageContextOverlay(
      tapPosition: tapPosition,
      message: message,
      isMe: isMe,
      conversationId: conversationId,
      currentUserId: currentUserId,
      onDismiss: () => entry.remove(),
      parentContext: context,
    ),
  );

  overlay.insert(entry);
}

class _MessageContextOverlay extends StatefulWidget {
  final Offset tapPosition;
  final MessageModel message;
  final bool isMe;
  final String conversationId;
  final String currentUserId;
  final VoidCallback onDismiss;
  final BuildContext parentContext;

  const _MessageContextOverlay({
    required this.tapPosition,
    required this.message,
    required this.isMe,
    required this.conversationId,
    required this.currentUserId,
    required this.onDismiss,
    required this.parentContext,
  });

  @override
  State<_MessageContextOverlay> createState() => _MessageContextOverlayState();
}

class _MessageContextOverlayState extends State<_MessageContextOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animController.reverse().then((_) => widget.onDismiss());
  }

  void _onReaction(String emoji) {
    widget.parentContext.read<MessagesBloc>().add(
      MessageReactionToggled(
        conversationId: widget.conversationId,
        messageId: widget.message.id,
        emoji: emoji,
        userId: widget.currentUserId,
      ),
    );
    _dismiss();
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    _dismiss();
  }

  void _onDelete() {
    _dismiss();
    // Show delete confirmation after overlay is gone
    Future.delayed(const Duration(milliseconds: 250), () {
      _showDeleteConfirmation(widget.parentContext);
    });
  }

  void _onDownload() {
    for (final att in widget.message.attachments) {
      launchUrl(Uri.parse(att.fileUrl), mode: LaunchMode.externalApplication);
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(widget.parentContext).brightness == Brightness.dark;

    // Calculate position for the menu
    // Reaction bar width: ~320, menu width: ~220
    const double barWidth = 340;
    const double menuWidth = 220;
    const double barHeight = 52;
    const double menuItemHeight = 44;

    // Count menu items
    int menuItems = 0;
    if (widget.message.content.isNotEmpty) menuItems++; // Copy
    if (widget.message.attachments.isNotEmpty) menuItems++; // Download
    if (widget.isMe) menuItems++; // Delete
    final double menuHeight = menuItems * menuItemHeight + 16; // padding

    // Position: try to show above the tap, fallback to below
    final double totalHeight = barHeight + 8 + menuHeight;
    final bool showAbove = widget.tapPosition.dy > totalHeight + 20;

    double top;
    if (showAbove) {
      top = widget.tapPosition.dy - totalHeight - 8;
    } else {
      top = widget.tapPosition.dy + 8;
    }

    // Horizontal: center on tap, clamp to screen
    double left = widget.tapPosition.dx - barWidth / 2;
    left = left.clamp(12.0, screenSize.width - barWidth - 12);

    double menuLeft = widget.tapPosition.dx - menuWidth / 2;
    menuLeft = menuLeft.clamp(12.0, screenSize.width - menuWidth - 12);

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.translucent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black.withOpacity(0.15),
          width: screenSize.width,
          height: screenSize.height,
          child: Stack(
            children: [
              // Reaction bar
              Positioned(
                left: left,
                top: showAbove ? top : top,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: showAbove ? Alignment.bottomCenter : Alignment.topCenter,
                  child: _buildReactionBar(isDark),
                ),
              ),
              // Options menu
              Positioned(
                left: menuLeft,
                top: showAbove ? top + barHeight + 8 : top + barHeight + 8,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: showAbove ? Alignment.bottomCenter : Alignment.topCenter,
                  child: _buildOptionsMenu(isDark, menuWidth),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionBar(bool isDark) {
    // Check which emojis the current user already reacted with
    final myReactions = <String>{};
    for (final entry in widget.message.reactions.entries) {
      if (entry.value.contains(widget.currentUserId)) {
        myReactions.add(entry.key);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D3F) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: kQuickReactions.map((emoji) {
          final isSelected = myReactions.contains(emoji);
          return _ReactionButton(
            emoji: emoji,
            isSelected: isSelected,
            onTap: () => _onReaction(emoji),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionsMenu(bool isDark, double width) {
    return Material(
      color: Colors.transparent,
      child: Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2D2D3F) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message.content.isNotEmpty)
            _buildMenuItem(
              icon: Icons.copy_rounded,
              label: 'Copy Text',
              iconColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
              textColor: isDark ? Colors.grey.shade200 : const Color(0xFF1F2937),
              onTap: _onCopy,
              isDark: isDark,
            ),
          if (widget.message.attachments.isNotEmpty)
            _buildMenuItem(
              icon: Icons.download_rounded,
              label: widget.message.attachments.length == 1
                  ? 'Download File'
                  : 'Download Files (${widget.message.attachments.length})',
              iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              textColor: isDark ? Colors.grey.shade200 : const Color(0xFF1F2937),
              onTap: _onDownload,
              isDark: isDark,
            ),
          if (widget.isMe)
            _buildMenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              iconColor: const Color(0xFFEF4444),
              textColor: const Color(0xFFEF4444),
              onTap: _onDelete,
              isDark: isDark,
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bloc = ctx.read<MessagesBloc>();

    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withOpacity(0.2),
                    const Color(0xFFDC2626).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Delete Message?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This message will be permanently deleted. This action cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(
                MessageDeleteRequested(
                  conversationId: widget.conversationId,
                  messageId: widget.message.id,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual emoji reaction button with hover + selected state.
class _ReactionButton extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF7C3AED).withOpacity(0.2)
                : _isHovered
                    ? Colors.grey.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: AnimatedScale(
              scale: _isHovered ? 1.35 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
