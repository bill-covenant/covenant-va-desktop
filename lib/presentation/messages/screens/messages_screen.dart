import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_provider.dart';
import '../bloc/messages_bloc.dart';
import '../bloc/messages_event.dart';
import '../bloc/messages_state.dart';
import '../widgets/conversation_list_panel.dart';
import '../widgets/chat_panel.dart';
import '../widgets/messages_error_state.dart';
import '../../../data/providers/storage_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../services/call_service.dart';
import '../../shared/widgets/refresh_fab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/debounced_json_cache.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  final StorageProvider _storageProvider = StorageProvider();
  final DebouncedJsonCache _conversationCache = DebouncedJsonCache();
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
    
    // ✅ Only fetch from API if BLoC doesn't already have conversations
    final currentState = context.read<MessagesBloc>().state;
    if (currentState is MessagesLoaded) {
      // BLoC already has data — just use it, no API call
      setState(() {
        _conversations = currentState.conversations;
        _isInitialized = true;
      });
    } else if (currentState is ConversationMessagesLoaded) {
      // User was viewing a conversation — restore it
      setState(() {
        _conversations = currentState.conversations;
        _isInitialized = true;
        // ✅ Restore the previously selected conversation
        _selectedConversation = _conversations.firstWhere(
          (c) => c.id == currentState.conversationId,
          orElse: () => _conversations.first,
        );
      });
    }
    // _loadConversations() is called from _loadCurrentUser() once userId is ready
  }

  Future<void> _loadCurrentUser() async {
    final user = await _storageProvider.getUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.id;
      });
      _loadConversations();
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
        
        if (mounted && _conversations.isEmpty) {
          setState(() {
            _conversations = cachedConversations;
            _isInitialized = true;
          });
          debugPrint('✅ Loaded ${cachedConversations.length} cached conversations');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cached conversations: $e');
    }
  }

  /// Debounced (≈2s) cache write; JSON encoding moves off the UI thread for
  /// large lists.
  void _saveCachedConversations(List<ConversationModel> conversations) {
    _conversationCache.schedule(
      'cached_conversations',
      () => conversations.map((c) => c.toJson()).toList(),
    );
  }

  /// Applies conversations from bloc state, skipping the rebuild + cache write
  /// when the list instance hasn't changed (message snapshots re-send the
  /// same conversations list).
  void _applyConversations(
    List<ConversationModel> conversations, {
    bool cache = true,
    bool markInitialized = false,
  }) {
    if (identical(conversations, _conversations) &&
        (!markInitialized || _isInitialized)) {
      return;
    }
    setState(() {
      _conversations = conversations;
      if (markInitialized) _isInitialized = true;
    });
    if (cache) _saveCachedConversations(conversations);
  }

  void _loadConversations() {
    if (_currentUserId == null) return;
    context.read<MessagesBloc>().add(MessagesLoadRequested(userId: _currentUserId!));
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
    debugPrint('🎯 Conversation selected: ${conversation.id}');
    if (!mounted) return;

    final isSameConversation = _selectedConversation?.id == conversation.id;

    // Always update the conversation (to pick up enriched avatar data).
    // Message loading is dispatched by ChatMessagesArea (initState /
    // didUpdateWidget) — the single place that subscribes to a conversation.
    setState(() {
      _selectedConversation = conversation;
    });

    if (isSameConversation) {
      debugPrint('⏭️ Same conversation, updated data only');
    }
  }

  @override
  void dispose() {
    // Write any pending conversation cache now; never touches widget state.
    _conversationCache.flush();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, _) {
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF0F1117), const Color(0xFF151822)]
                      : [const Color(0xFFF8F7FC), const Color(0xFFFCFAFF)],
                ),
              ),
              child: BlocConsumer<MessagesBloc, MessagesState>(
                listener: (context, state) {
                  if (state is MessagesLoaded) {
                    _applyConversations(state.conversations, markInitialized: true);
                  } else if (state is ConversationMessagesLoaded) {
                    _applyConversations(state.conversations);
                  } else if (state is MessageSent) {
                    _applyConversations(state.conversations);
                  } else if (state is MessageSending) {
                    _applyConversations(state.conversations, cache: false);
                  }
                },
                // The builder only depends on the error state; conversation
                // changes rebuild via setState in the listener.
                buildWhen: (previous, current) =>
                    current is MessagesError || previous is MessagesError,
                builder: (context, state) {
                  debugPrint('🔄 MessagesBloc state: ${state.runtimeType}');
                  
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
      },
    );
  }

  Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(50, 24, 48, 24),
    child: Row(
      children: [
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
        RefreshFAB(onRefresh: () async => _handleRefresh()),
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
            callService: CallService(),
          ),
        ),
      ],
    );
  }
}