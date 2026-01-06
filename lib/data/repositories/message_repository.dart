import '../../core/constants/api_constants.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../providers/api_provider.dart';

class MessageRepository {
  final ApiProvider _apiProvider;

  MessageRepository({required ApiProvider apiProvider})
      : _apiProvider = apiProvider;

  // Get all conversations
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _apiProvider.get(
        ApiConstants.conversations,
        requiresAuth: true,
      );

      final conversationsJson = response['conversations'] as List;
      return conversationsJson
          .map((json) =>
              ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  // Get messages for a conversation
  Future<List<MessageModel>> getMessagesForConversation(
    String conversationId,
  ) async {
    try {
      final response = await _apiProvider.get(
        ApiConstants.conversationMessages(conversationId),
        requiresAuth: true,
      );

      final messagesJson = response['messages'] as List;
      return messagesJson
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw Exception('Message content cannot be empty');
      }

      final response = await _apiProvider.post(
        ApiConstants.conversationMessages(conversationId),
        {'content': content.trim()},
        requiresAuth: true,
      );

      return MessageModel.fromJson(response['message'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ✅ DELETE MESSAGE (NEW)
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await _apiProvider.delete(
        '/messages/$messageId',
        requiresAuth: true,
      );

      if (response['success'] != true) {
        throw Exception('Failed to delete message');
      }
      
      print('✅ Message deleted: $messageId');
    } catch (e) {
      print('❌ Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // Get or create conversation
  Future<ConversationModel> getOrCreateConversation(String otherUserId) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.conversations,
        {'otherUserId': otherUserId},
        requiresAuth: true,
      );

      return ConversationModel.fromJson(
          response['conversation'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiProvider.get(
        ApiConstants.unreadCount,
        requiresAuth: true,
      );

      return response['unreadCount'] as int;
    } catch (e) {
      // Return 0 instead of throwing to avoid breaking UI
      print('Failed to fetch unread count: $e');
      return 0;
    }
  }
}