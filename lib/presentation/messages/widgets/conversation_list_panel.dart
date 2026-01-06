import 'package:flutter/material.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../core/di/service_locator.dart';
import 'conversation_list_item.dart';

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
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showNewMessageDialog() async {
    try {
      // Fetch assigned clients
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'No Clients Assigned',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You don\'t have any clients assigned yet. Please contact your administrator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'New Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // Client list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final initials = '${client.firstName[0]}${client.lastName[0]}'.toUpperCase();
                    
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
                              // Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Client info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${client.firstName} ${client.lastName}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      client.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
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
    // Check if conversation already exists with this client
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

    // If conversation exists, select it
    if (!existingConversation.id.startsWith('temp_')) {
      widget.onConversationSelected(existingConversation);
    } else {
      // Create a temporary conversation to start chatting
      // The actual conversation will be created when the first message is sent
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
        va: null,
        unreadCount: 0,
      );
      
      widget.onConversationSelected(tempConversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _buildConversationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
      child: Row(
        children: [
          const Text(
            'Conversations',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // New Message Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showNewMessageDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.refresh_rounded,
                  color: Colors.black.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.black.withOpacity(0.4),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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

  Widget _buildConversationList() {
    var filteredConversations = widget.conversations;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredConversations = filteredConversations.where((conv) {
        final searchLower = _searchQuery.toLowerCase();
        final otherUserName = conv.getOtherParticipantName(widget.currentUserId).toLowerCase();
        return otherUserName.contains(searchLower) ||
            (conv.lastMessage?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // Show empty state
    if (filteredConversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        final isSelected = widget.selectedConversation?.id == conversation.id;

        return ConversationListItem(
          conversation: conversation,
          currentUserId: widget.currentUserId,
          isSelected: isSelected,
          onTap: () => widget.onConversationSelected(conversation),
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
                color: const Color(0xFFF5F5F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty 
                  ? 'No conversations yet' 
                  : 'No results found',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
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
                color: Colors.black.withOpacity(0.4),
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