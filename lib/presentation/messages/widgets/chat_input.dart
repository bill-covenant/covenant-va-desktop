import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
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
          ),
        );
    
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MessagesBloc, MessagesState>(
      listener: (context, state) {
        if (state is MessageSendError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to send message',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text input
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    gradient: _isFocused
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8B5CF6).withOpacity(0.05),
                              const Color(0xFFEC4899).withOpacity(0.05),
                            ],
                          )
                        : null,
                    color: _isFocused ? null : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isFocused 
                          ? const Color(0xFF7C3AED).withOpacity(0.3)
                          : const Color(0xFFE5E7EB),
                      width: _isFocused ? 2 : 1,
                    ),
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (KeyEvent event) {
                      // ✅ FIX: Prevent Enter from adding newline
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _sendMessage();
                      }
                    },
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send, // ✅ Changed from newline to send
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      // ✅ FIX: Prevent default Enter behavior and send message instead
                      onSubmitted: (value) {
                        _sendMessage();
                      },
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Send button with animation
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final hasText = _messageController.text.trim().isNotEmpty;
                  
                  return Transform.scale(
                    scale: hasText ? _pulseAnimation.value : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: hasText
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
                        color: hasText ? null : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withOpacity(0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: hasText ? _sendMessage : null,
                          borderRadius: BorderRadius.circular(26),
                          child: Center(
                            child: Icon(
                              Icons.send_rounded,
                              color: hasText 
                                  ? Colors.white 
                                  : const Color(0xFF9CA3AF),
                              size: 22,
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
    );
  }
}