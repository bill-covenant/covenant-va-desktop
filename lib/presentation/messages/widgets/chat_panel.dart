import 'package:flutter/material.dart';
import '../../../data/models/conversation_model.dart';
import 'chat_header.dart';
import 'chat_messages_area.dart';
import 'chat_input.dart';

class ChatPanel extends StatelessWidget {
  final ConversationModel? conversation;
  final String currentUserId;

  const ChatPanel({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return _buildEmptyState();
    }

    // Check if this is a new conversation (temporary ID)
    final isNewConversation = conversation!.id.startsWith('new_');

    return Column(
      children: [
        // Header with participant info
        ChatHeader(
          conversation: conversation!,
          currentUserId: currentUserId,
        ),

        // Messages area (will be empty for new conversations)
        Expanded(
          child: isNewConversation 
              ? _buildNewConversationState()
              : ChatMessagesArea(
                  conversation: conversation!,
                  currentUserId: currentUserId,
                ),
        ),

        // Message input (always show, even for new conversations)
        ChatInput(
          conversation: conversation!,
          currentUserId: currentUserId,
        ),
      ],
    );
  }

  Widget _buildNewConversationState() {
    final clientName = conversation!.client?.fullName ?? 'Client';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
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
                (conversation!.client?.firstName.isNotEmpty == true
                    ? conversation!.client!.firstName[0].toUpperCase()
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
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Start a conversation',
            style: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.black.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Type a message below to begin',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
          // 3D Glassmorphic icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB24FE0), // Lighter purple
                  Color(0xFF8B2FC9), // Darker purple
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                // Main shadow
                BoxShadow(
                  color: const Color(0xFF8B2FC9).withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
                ),
                // Secondary glow
                BoxShadow(
                  color: const Color(0xFFB24FE0).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
                // Inner highlight (simulated with white)
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(-2, -2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inner glow
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Icon
                const Center(
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title with bold weight
          const Text(
            'No Conversation Selected',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Choose a conversation from the list to start chatting',
            style: TextStyle(
              color: Colors.black.withOpacity(0.5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}