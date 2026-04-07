import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/firebase_message_repository.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../core/di/service_locator.dart';
import 'conversation_list_item.dart';
import '../../../services/socket_service.dart';
import '../../shared/widgets/avatar_image.dart';

class ConversationListPanel extends StatefulWidget {
  final List<ConversationModel> conversations;
  final String currentUserId;
  final ConversationModel? selectedConversation;
  final Function(ConversationModel) onConversationSelected;
  final VoidCallback onRefresh;

  const ConversationListPanel({
    super.key,
    required this.conversations,
    required this.currentUserId,
    required this.selectedConversation,
    required this.onConversationSelected,
    required this.onRefresh,
  });

  @override
  State<ConversationListPanel> createState() => _ConversationListPanelState();
}

class _ConversationListPanelState extends State<ConversationListPanel> {
  final TextEditingController _searchController = TextEditingController();
  final ClientRepository _clientRepository = getIt<ClientRepository>();
  final StorageProvider _storageProvider = StorageProvider();
  String _searchQuery = '';
  String _currentVaFirstName = '';
  String _currentVaLastName = '';
  List<ClientModel> _clients = [];
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _loadCurrentVaName();
    _loadClients();
    // Rebuild conversation list when any user's online status changes
    _statusSub = SocketService().onUserStatusChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentVaName() async {
    final user = await _storageProvider.getUser();
    if (user != null && mounted) {
      setState(() {
        _currentVaFirstName = user.firstName;
        _currentVaLastName = user.lastName;
      });
    }
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _clientRepository.getAssignedClients();
      if (mounted) setState(() => _clients = clients);
    } catch (_) {}
  }

  /// Returns the conversation enriched with the client's real name
  /// when Firestore has an empty clientName (legacy conversations).
  ConversationModel _enrichConversation(ConversationModel conv) {
    final match = _clients.firstWhere(
      (c) => c.id == conv.clientId,
      orElse: () => ClientModel(id: '', firstName: '', lastName: '', email: ''),
    );

    // If we have a matching client, always enrich with avatar (and name if missing)
    if (match.id.isNotEmpty) {
      return conv.copyWith(
        client: UserInfo(
          id: match.id,
          email: match.email,
          firstName: conv.client?.firstName.isNotEmpty == true
              ? conv.client!.firstName
              : match.firstName,
          lastName: conv.client?.lastName.isNotEmpty == true
              ? conv.client!.lastName
              : match.lastName,
          avatar: match.avatar,
        ),
      );
    }

    // CVA Support conversation — use app logo as avatar
    if (conv.clientId == _supportAdminId) {
      return conv.copyWith(
        client: UserInfo(
          id: _supportAdminId,
          email: '',
          firstName: 'CVA',
          lastName: 'Support',
          avatar: 'asset:assets/images/fav3.png',
        ),
      );
    }

    return conv;
  }

  // ──────────────────────────────────────────────
  // NEW MESSAGE DIALOG (kept same logic, updated visuals)
  // ──────────────────────────────────────────────

  Future<void> _showNewMessageDialog() async {
    try {
      final clients = await _clientRepository.getAssignedClients();
      if (!mounted) return;
      if (clients.isEmpty) {
        _showNoClientsDialog();
        return;
      }
      _showClientSelectionDialog(clients);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load clients: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNoClientsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFAF5FF), Color(0xFFFDF2F8)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'No Clients Assigned',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.1)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You don\'t have any clients assigned yet. Please contact your administrator.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OK Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Got it',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientSelectionDialog(List<ClientModel> clients) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('New Message',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final initials =
                        '${client.firstName[0]}${client.lastName[0]}'
                            .toUpperCase();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _startConversationWithClient(client);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: client.avatar == null ? const LinearGradient(colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFFEC4899)
                                  ]) : null,
                                  shape: BoxShape.circle,
                                ),
                                child: client.avatar != null
                                    ? AvatarImage(
                                        source: client.avatar!,
                                        size: 48,
                                        fallback: Center(
                                            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                                      )
                                    : Center(
                                        child: Text(initials,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold))),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${client.firstName} ${client.lastName}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    Text(client.email,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startConversationWithClient(ClientModel client) {
    final existingConversation = widget.conversations.firstWhere(
      (conv) => conv.clientId == client.id,
      orElse: () => ConversationModel(
        id: 'temp_${client.id}',
        clientId: client.id,
        vaId: widget.currentUserId,
        lastMessage: null,
        lastMessageAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        client: UserInfo(
          id: client.id,
          email: client.email,
          firstName: client.firstName,
          lastName: client.lastName,
        ),
        va: null,
        unreadCount: 0,
      ),
    );

    if (!existingConversation.id.startsWith('temp_')) {
      widget.onConversationSelected(existingConversation);
    } else {
      final tempConversation = ConversationModel(
        id: 'new_${client.id}',
        clientId: client.id,
        vaId: widget.currentUserId,
        lastMessage: null,
        lastMessageAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        client: UserInfo(
          id: client.id,
          email: client.email,
          firstName: client.firstName,
          lastName: client.lastName,
        ),
        va: UserInfo(
          id: widget.currentUserId,
          email: '',
          firstName: _currentVaFirstName,
          lastName: _currentVaLastName,
        ),
        unreadCount: 0,
      );
      widget.onConversationSelected(tempConversation);
    }
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = ThemeProvider().isDarkMode;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF1A1D2E), const Color(0xFF1E2030), const Color(0xFF1A1D2E)]
              : [const Color(0xFFE8DEFF), const Color(0xFFDDD0FC), const Color(0xFFE3D6FB)],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Pattern overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConversationListPatternPainter(),
                ),
              ),
            ),
            // Actual content
            Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(child: _buildConversationList()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    height: 1,
                  ),
                ),
                _buildSupportButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            ).createShader(bounds),
            child: const Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          // New message button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showNewMessageDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.06),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: Color(0xFF4A3560),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(
              color: const Color(0xFFA78BFA).withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: const Color(0xFFA78BFA).withOpacity(0.5),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  // CVA Support admin ID — primary support contact
  static const String _supportAdminId = '39108981-7354-4a6c-bf75-665bd8584443';
  static const String _supportAdminName = 'CVA Support';

  Future<void> _openSupportChat() async {
    // First check if support conversation already exists
    final supportConv = widget.conversations.cast<ConversationModel?>().firstWhere(
      (conv) => conv!.clientId == _supportAdminId,
      orElse: () => null,
    );

    if (supportConv != null) {
      widget.onConversationSelected(supportConv);
      return;
    }

    // Create a new support conversation
    try {
      final messageRepo = getIt<FirebaseMessageRepository>();
      final vaName = '$_currentVaFirstName $_currentVaLastName'.trim();

      await messageRepo.getOrCreateConversation(
        clientId: _supportAdminId,
        vaId: widget.currentUserId,
        clientName: _supportAdminName,
        vaName: vaName.isNotEmpty ? vaName : 'VA',
      );

      // Refresh conversations to pick up the new one
      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Support chat created! You can now message CVA Support.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open support chat: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildSupportButton() {
    final dark = ThemeProvider().isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openSupportChat,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: dark
                    ? [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF059669).withOpacity(0.10)]
                    : [const Color(0xFF10B981).withOpacity(0.12), const Color(0xFF059669).withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CVA Support',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Chat with admin support',
                        style: TextStyle(
                          fontSize: 10,
                          color: dark ? Colors.white54 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: dark ? Colors.white30 : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    var filteredConversations = widget.conversations;

    if (_searchQuery.isNotEmpty) {
      filteredConversations = filteredConversations.where((conv) {
        final searchLower = _searchQuery.toLowerCase();
        final otherUserName =
            conv.getOtherParticipantName(widget.currentUserId).toLowerCase();
        return otherUserName.contains(searchLower) ||
            (conv.lastMessage?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    if (filteredConversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        final isSelected =
            widget.selectedConversation?.id == conversation.id;

        final enriched = _enrichConversation(conversation);
        final otherUserId = enriched.getOtherUserId(widget.currentUserId);
        return ConversationListItem(
          conversation: enriched,
          currentUserId: widget.currentUserId,
          isSelected: isSelected,
          isOtherUserOnline: SocketService().isUserOnline(otherUserId),
          onTap: () => widget.onConversationSelected(enriched),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: const Color(0xFFA78BFA).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty
                  ? 'No conversations yet'
                  : 'No results found',
              style: TextStyle(
                color: Colors.black.withOpacity(0.65),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Click "+ New" to start chatting\nwith your clients'
                  : 'Try a different search',
              style: TextStyle(
                color: Colors.black.withOpacity(0.35),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Same pattern style as the chat messages area — small shapes in a
/// staggered grid at low opacity for a themed wallpaper feel.
class _ConversationListPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 40.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double offsetX = (row % 2 == 0) ? 0 : spacing / 2;
        final double x = col * spacing + offsetX;
        final double y = row * spacing;

        final int shapeIndex = (row * 7 + col * 13) % 5;

        final double opacity = 0.12 + ((row * 3 + col * 5) % 4) * 0.02;
        paint.color = const Color(0xFF8B5CF6).withOpacity(opacity);

        switch (shapeIndex) {
          case 0:
            canvas.drawCircle(Offset(x, y), 5.0, paint);
            break;
          case 1:
            paint.style = PaintingStyle.fill;
            paint.color = const Color(0xFF8B5CF6).withOpacity(opacity * 0.7);
            canvas.drawCircle(Offset(x, y), 2.5, paint);
            paint.style = PaintingStyle.stroke;
            paint.color = const Color(0xFF8B5CF6).withOpacity(opacity);
            break;
          case 2:
            canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), paint);
            canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), paint);
            break;
          case 3:
            final path = Path()
              ..moveTo(x, y - 5)
              ..lineTo(x + 4.5, y)
              ..lineTo(x, y + 5)
              ..lineTo(x - 4.5, y)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case 4:
            canvas.save();
            canvas.translate(x, y);
            canvas.rotate(math.pi / 6);
            canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
            canvas.restore();
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}