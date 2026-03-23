import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';

class ChatInput extends StatefulWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const ChatInput({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  bool _isFocused = false;
  bool _hasText = false;
  bool _showEmojiPicker = false;

  // Key for positioning the popup relative to the input bar
  final GlobalKey _inputBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendButtonScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _sendButtonController, curve: Curves.easeOutBack),
    );

    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });

    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        if (hasText) {
          _sendButtonController.forward();
        } else {
          _sendButtonController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _dismissEmojiPicker();
    _messageController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    context.read<MessagesBloc>().add(
          MessageSendRequested(
            conversationId: widget.conversation.id,
            content: message,
            senderId: widget.currentUserId,
            clientName: widget.conversation.client?.fullName ?? '',
            vaName: widget.conversation.va?.fullName ?? '',
          ),
        );

    _focusNode.requestFocus();
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _dismissEmojiPicker();
    } else {
      _showEmojiPickerModal();
    }
  }

  void _showEmojiPickerModal() {
    setState(() => _showEmojiPicker = true);

    final RenderBox? renderBox =
        _inputBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final inputBarTop = position.dy;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate popup position: above the input bar, right-aligned with emoji button
    const double popupWidth = 380.0;
    const double popupHeight = 360.0;
    const double gap = 8.0;

    // Position it to the right side of the chat area
    final double right = screenWidth - position.dx - renderBox.size.width + 16;

    showDialog(
      context: context,
      barrierColor: Colors.transparent, // No dimming
      barrierDismissible: true,
      builder: (dialogContext) {
        return Stack(
          children: [
            // Tap anywhere outside to dismiss
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            // Emoji picker popup
            Positioned(
              bottom: MediaQuery.of(context).size.height - inputBarTop + gap,
              right: right,
              child: Material(
                color: Colors.transparent,
                child: _buildEmojiPopup(dialogContext),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  void _dismissEmojiPicker() {
    if (_showEmojiPicker && mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      setState(() => _showEmojiPicker = false);
    }
  }

  Widget _buildEmojiPopup(BuildContext dialogContext) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 380,
        height: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: EmojiPicker(
            textEditingController: _messageController,
            onBackspacePressed: () {
              _messageController
                ..text = _messageController.text.characters
                    .skipLast(1)
                    .toString()
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length),
                );
            },
            onEmojiSelected: (category, emoji) {
              // Keep the popup open — user might want multiple emojis
              // Text is auto-inserted via textEditingController
            },
            config: Config(
              height: 360,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28 *
                    (foundation.defaultTargetPlatform == TargetPlatform.iOS
                        ? 1.20
                        : 1.0),
              ),
              skinToneConfig: const SkinToneConfig(),
              // Put search bar on top, categories in middle, emojis below
              viewOrderConfig: const ViewOrderConfig(
                top: EmojiPickerItem.searchBar,
                middle: EmojiPickerItem.categoryBar,
                bottom: EmojiPickerItem.emojiView,
              ),
              categoryViewConfig: CategoryViewConfig(
                indicatorColor: const Color(0xFF7C3AED),
                iconColorSelected: const Color(0xFF7C3AED),
                iconColor: const Color(0xFFB4A3CC),
                dividerColor: const Color(0xFF7C3AED).withOpacity(0.06),
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                showBackspaceButton: false,
                showSearchViewButton: false,
              ),
              searchViewConfig: SearchViewConfig(
                buttonIconColor: const Color(0xFF7C3AED),
                hintText: 'Search emoji...',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessagesBloc, MessagesState>(
      listener: (context, state) {
        if (state is MessageSendError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to send message',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      // Input bar only — no emoji panel below
      child: ClipRect(
        key: _inputBarKey,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: BoxDecoration(
              gradient: ThemeProvider().isDarkMode
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF1A1230),
                        Color(0xFF1E1535),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFFEC4899),
                      ],
                    ),
              border: Border(
                top: BorderSide(
                  color: ThemeProvider().isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(
                      ThemeProvider().isDarkMode ? 0.1 : 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Main input container
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: ThemeProvider().isDarkMode
                            ? (_isFocused
                                ? Colors.white.withOpacity(0.15)
                                : Colors.white.withOpacity(0.1))
                            : (_isFocused
                                ? Colors.white.withOpacity(0.97)
                                : Colors.white.withOpacity(0.9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ThemeProvider().isDarkMode
                              ? (_isFocused
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.15))
                              : (_isFocused
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6)),
                          width: _isFocused ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: _isFocused ? 16 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 6, bottom: 4),
                            child: _buildInlineButton(
                              Icons.attach_file_rounded,
                              onTap: () {},
                            ),
                          ),
                          Expanded(
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (KeyEvent event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.enter &&
                                    !HardwareKeyboard
                                        .instance.isShiftPressed) {
                                  _sendMessage();
                                }
                              },
                              child: TextField(
                                controller: _messageController,
                                focusNode: _focusNode,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.send,
                                style: TextStyle(
                                  color: ThemeProvider().isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF2D2252),
                                  fontSize: 14.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(
                                    color: ThemeProvider().isDarkMode
                                        ? Colors.white.withOpacity(0.5)
                                        : const Color(0xFF9CA3AF)
                                            .withOpacity(0.8),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 6, bottom: 4),
                            child: _buildInlineButton(
                              _showEmojiPicker
                                  ? Icons.keyboard_rounded
                                  : Icons.emoji_emotions_outlined,
                              onTap: _toggleEmojiPicker,
                              isActive: _showEmojiPicker,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Send button
                  AnimatedBuilder(
                    animation: _sendButtonScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _hasText ? _sendButtonScale.value : 0.85,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: _hasText
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF7C3AED),
                                    ],
                                  )
                                : null,
                            color: _hasText
                                ? null
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _hasText
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED)
                                          .withOpacity(0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED)
                                          .withOpacity(0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _hasText ? _sendMessage : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: AnimatedRotation(
                                  turns: _hasText ? -0.05 : 0,
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: _hasText
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineButton(
    IconData icon, {
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Icon(
              icon,
              color: isActive
                  ? (ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF7C3AED))
                  : (ThemeProvider().isDarkMode
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFFA78BFA).withOpacity(0.7)),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}