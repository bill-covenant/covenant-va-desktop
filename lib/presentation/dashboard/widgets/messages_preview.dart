import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/card_decoration.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/providers/api_provider.dart';

class MessagesPreview extends StatefulWidget {
  const MessagesPreview({super.key});

  @override
  State<MessagesPreview> createState() => _MessagesPreviewState();
}

class _MessagesPreviewState extends State<MessagesPreview> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  static List<dynamic>? _cached;

  @override
  void initState() {
    super.initState();
    if (_cached != null) {
      _conversations = _cached!;
      _isLoading = false;
    }
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final apiProvider = getIt<ApiProvider>();
      final response = await apiProvider.get(
        ApiConstants.conversations,
        requiresAuth: true,
      );
      final conversationsJson = response['conversations'] as List;
      final convos = conversationsJson
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
      print('📬 Dashboard: Loaded ${convos.length} conversations');
      if (mounted) {
        _cached = convos;
        setState(() {
          _conversations = convos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('📬 Dashboard: Failed to load conversations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  static const _avatarColors = [
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode();
    final cardBg = cardBgColor();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: dark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: dark
            ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary())),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/messages'),
                child: const Text('View all', style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else if (_conversations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 32, color: textTertiary()),
                    const SizedBox(height: 8),
                    Text('No messages yet', style: TextStyle(color: textTertiary(), fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...(_conversations.take(3).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final convo = entry.value;
              final clientName = (convo as dynamic).client != null
                  ? '${convo.client.firstName} ${convo.client.lastName}'
                  : 'Client';
              final initials = clientName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
              final colors = _avatarColors[i % _avatarColors.length];
              final lastMsg = (convo as dynamic).lastMessage ?? '';
              final lastTime = (convo as dynamic).lastMessageAt as DateTime?;

              return Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clientName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary())),
                          const SizedBox(height: 2),
                          Text(
                            lastMsg.isNotEmpty ? lastMsg : 'No messages',
                            style: TextStyle(fontSize: 11, color: textSecondary()),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (lastTime != null)
                      Text(_formatTime(lastTime), style: TextStyle(fontSize: 10, color: textTertiary(), fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }
}
