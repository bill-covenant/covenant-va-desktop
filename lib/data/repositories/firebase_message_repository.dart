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
            .map((doc) => ConversationModel.fromFirestore(doc, currentUserId: userId))
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

  /// Send a message to a conversation, optionally with attachments.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String senderName,
    List<Map<String, dynamic>> attachments = const [],
    Map<String, dynamic>? replyTo,
  }) async {
    if (content.trim().isEmpty && attachments.isEmpty) {
      throw Exception('Message cannot be empty');
    }

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

    final messageData = <String, dynamic>{
      'senderId': senderId,
      'senderName': senderName,
      'content': content.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (attachments.isNotEmpty) {
      messageData['attachments'] = attachments;
    }

    if (replyTo != null) {
      messageData['replyTo'] = replyTo;
    }

    await messagesRef.add(messageData);

    // Build last message preview
    String lastMessage = content.trim();
    if (lastMessage.isEmpty && attachments.isNotEmpty) {
      final count = attachments.length;
      lastMessage = count == 1
          ? '📎 ${attachments.first['fileName']}'
          : '📎 $count files';
    }

    await convRef.update({
      'lastMessage': lastMessage.length > 100
          ? '${lastMessage.substring(0, 100)}...'
          : lastMessage,
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

  /// Toggle a reaction on a message. Adds if not present, removes if already reacted.
  Future<void> toggleReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final docRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final reactions = Map<String, dynamic>.from(data['reactions'] as Map? ?? {});
    final users = List<String>.from(reactions[emoji] as List? ?? []);

    if (users.contains(userId)) {
      users.remove(userId);
      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }
    } else {
      users.add(userId);
      reactions[emoji] = users;
    }

    await docRef.update({'reactions': reactions});
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
