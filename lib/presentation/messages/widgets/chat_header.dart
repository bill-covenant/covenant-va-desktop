import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../shared/widgets/avatar_image.dart';

class ChatHeader extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final bool isOtherUserOnline;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;

  const ChatHeader({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.isOtherUserOnline = false,
    this.onAudioCall,
    this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final otherUserName = conversation.getOtherParticipantName(currentUserId);
    final initials = _getInitials(otherUserName);
    final avatar = conversation.getOtherParticipantAvatar(currentUserId);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: ThemeProvider().isDarkMode ? const Color(0xFF1A1D2E).withOpacity(0.85) : Colors.white.withOpacity(0.65),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF7C3AED).withOpacity(0.06),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with ring glow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: avatar == null ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ) : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                  ),
                  child: avatar != null
                      ? AvatarImage(
                          source: avatar,
                          size: 46,
                          fallback: Center(
                            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otherUserName,
                      style: TextStyle(
                        color: ThemeProvider().isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isOtherUserOnline
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF9CA3AF),
                            shape: BoxShape.circle,
                            boxShadow: isOtherUserOnline
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOtherUserOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: isOtherUserOnline
                                ? const Color(0xFF22C55E).withOpacity(0.9)
                                : const Color(0xFF9CA3AF).withOpacity(0.9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3D Action buttons
              _build3DActionButton(
                icon: Icons.phone_rounded,
                gradientColors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ],
                shadowColor: const Color(0xFF10B981),
                onTap: onAudioCall,
              ),
              const SizedBox(width: 10),
              _build3DActionButton(
                icon: Icons.videocam_rounded,
                gradientColors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED),
                ],
                shadowColor: const Color(0xFF7C3AED),
                onTap: onVideoCall,
              ),
              const SizedBox(width: 10),
              _build3DActionButton(
                icon: Icons.more_vert_rounded,
                gradientColors: [
                  const Color(0xFF64748B),
                  const Color(0xFF475569),
                ],
                shadowColor: const Color(0xFF475569),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DActionButton({
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          // Main drop shadow
          BoxShadow(
            color: shadowColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // Softer ambient shadow
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          // Top-left highlight for 3D raised effect
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(-1, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner highlight / gloss overlay
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Icon
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? () {},
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
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
}