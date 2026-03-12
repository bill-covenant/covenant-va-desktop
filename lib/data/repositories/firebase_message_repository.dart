import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class FirebaseMessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseMessageRepository();

  /// Stream of conversations for the given user.
  Stream<List<ConversationModel>> conversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of messages for a specific conversation.
  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Send a message to a conversation.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String senderName,
  }) async {
    if (content.trim().isEmpty) throw Exception('Message cannot be empty');

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final messagesRef = convRef.collection('messages');

    final convSnap = await convRef.get();
    if (!convSnap.exists) throw Exception('Conversation not found');

    final data = convSnap.data()!;
    final participants = List<String>.from(data['participants'] ?? []);
    final recipientId = participants.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );

    await messagesRef.add({
      'senderId': senderId,
      'senderName': senderName,
      'content': content.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await convRef.update({
      'lastMessage': content.trim().length > 100
          ? '${content.trim().substring(0, 100)}...'
          : content.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      if (recipientId.isNotEmpty)
        'unreadCounts.$recipientId': FieldValue.increment(1),
    });
  }

  /// Delete a message.
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Mark all messages in a conversation as read for the given user.
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({'unreadCounts.$userId': 0});
  }

  /// Get or create a conversation between client and VA.
  Future<String> getOrCreateConversation({
    required String clientId,
    required String vaId,
    required String clientName,
    required String vaName,
  }) async {
    final convId = '${clientId}_$vaId';
    final convRef = _firestore.collection('conversations').doc(convId);
    final convSnap = await convRef.get();

    if (!convSnap.exists) {
      await convRef.set({
        'clientId': clientId,
        'vaId': vaId,
        'clientName': clientName,
        'vaName': vaName,
        'participants': [clientId, vaId],
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCounts': {clientId: 0, vaId: 0},
      });
    }

    return convId;
  }

  /// Total unread count for the given user across all conversations.
  Stream<int> unreadCountStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts =
            data['unreadCounts'] as Map<String, dynamic>? ?? {};
        total += (unreadCounts[userId] as num?)?.toInt() ?? 0;
      }
      return total;
    });
  }
}
