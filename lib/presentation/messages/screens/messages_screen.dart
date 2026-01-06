import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import '../widgets/conversation_list_panel.dart';
import '../widgets/chat_panel.dart';
import '../widgets/messages_error_state.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/models/conversation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  final StorageProvider _storageProvider = StorageProvider();
  String? _currentUserId;
  ConversationModel? _selectedConversation;
  late AnimationController _refreshAnimationController;
  bool _isRefreshing = false;
  
  List<ConversationModel> _conversations = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadCurrentUser();
    _loadCachedConversations();
    _loadConversations();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _storageProvider.getUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _loadCachedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_conversations');
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final cachedConversations = jsonList
            .map((json) => ConversationModel.fromJson(json))
            .toList();
        
        if (mounted) {
          setState(() {
            _conversations = cachedConversations;
            _isInitialized = true;
          });
          print('✅ Loaded ${cachedConversations.length} cached conversations');
        }
      }
    } catch (e) {
      print('⚠️ Failed to load cached conversations: $e');
    }
  }

  Future<void> _saveCachedConversations(List<ConversationModel> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await prefs.setString('cached_conversations', json.encode(jsonList));
      print('✅ Cached ${conversations.length} conversations');
    } catch (e) {
      print('⚠️ Failed to cache conversations: $e');
    }
  }

  void _loadConversations() {
    context.read<MessagesBloc>().add(const MessagesLoadRequested());
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshAnimationController.repeat();
    _loadConversations();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _onConversationSelected(ConversationModel conversation) {
    print('🎯 Conversation selected: ${conversation.id}');
    if (!mounted) return;
    
    setState(() {
      _selectedConversation = conversation;
    });
    
    if (!conversation.id.startsWith('new_')) {
      print('📨 Dispatching ConversationMessagesLoadRequested');
      context.read<MessagesBloc>().add(
        ConversationMessagesLoadRequested(conversation.id),
      );
    } else {
      print('✨ New conversation - skipping message load');
    }
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8F7FC),
                    Color(0xFFFCFAFF),
                  ],
                ),
              ),
              child: BlocConsumer<MessagesBloc, MessagesState>(
                listener: (context, state) {
                  if (state is MessagesLoaded) {
                    setState(() {
                      _conversations = state.conversations;
                      _isInitialized = true;
                    });
                    _saveCachedConversations(state.conversations);
                  } else if (state is ConversationMessagesLoaded) {
                    setState(() {
                      _conversations = state.conversations;
                    });
                    _saveCachedConversations(state.conversations);
                  } else if (state is MessageSent) {
                    setState(() {
                      _conversations = state.conversations;
                    });
                    _saveCachedConversations(state.conversations);
                  } else if (state is MessageSending) {
                    setState(() {
                      _conversations = state.conversations;
                    });
                  }
                },
                builder: (context, state) {
                  print('🔄 MessagesBloc state: ${state.runtimeType}');
                  
                  if (state is MessagesError && _conversations.isEmpty && _isInitialized) {
                    return MessagesErrorState(
                      error: state.message,
                      onRetry: _loadConversations,
                    );
                  }
                  
                  return _buildTwoPanelLayout(_conversations);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(50, 24, 48, 24), // ✅ Added bottom padding (24)
    child: Row(
      children: [
        // 3D Icon Container
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981),
                Color(0xFF059669),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.5),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                offset: const Offset(-2, -2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine effect
              Positioned(
                top: 4,
                left: 4,
                right: 20,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Icon
              const Center(
                child: Icon(
                  Icons.message,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 3D Text with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFE0E7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const Spacer(),
        // Refresh Button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _handleRefresh,
            child: AnimatedBuilder(
              animation: _refreshAnimationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshAnimationController.value * 2 * 3.14159,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF3F4F6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          offset: const Offset(-2, -2),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(4, 4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          color: _isRefreshing 
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTwoPanelLayout(List<ConversationModel> conversations) {
    if (_currentUserId == null) {
      return const SizedBox();
    }

    return Row(
      children: [
        SizedBox(
          width: 380,
          child: ConversationListPanel(
            conversations: conversations,
            currentUserId: _currentUserId!,
            selectedConversation: _selectedConversation,
            onConversationSelected: _onConversationSelected,
            onRefresh: _loadConversations,
          ),
        ),
        Expanded(
          child: ChatPanel(
            conversation: _selectedConversation,
            currentUserId: _currentUserId!,
          ),
        ),
      ],
    );
  }
}