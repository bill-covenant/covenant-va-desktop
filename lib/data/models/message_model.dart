class MessageAttachment {
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;

  MessageAttachment({
    required this.fileName,
    required this.fileUrl,
    this.fileSize = 0,
    this.mimeType = '',
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      fileName: map['fileName'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: map['mimeType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'fileUrl': fileUrl,
    'fileSize': fileSize,
    'mimeType': mimeType,
  };

  bool get isImage => mimeType.startsWith('image/');
}

class MessageReaction {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({required this.emoji, required this.userIds});

  factory MessageReaction.fromEntry(String emoji, dynamic userIds) {
    return MessageReaction(
      emoji: emoji,
      userIds: List<String>.from(userIds as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {emoji: userIds};
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MessageAttachment> attachments;
  final Map<String, List<String>> reactions; // emoji -> list of userIds

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.reactions = const {},
  });

  factory MessageModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'];
    DateTime createdAtDate = DateTime.now();
    if (createdAt != null) {
      try {
        createdAtDate = (createdAt as dynamic).toDate() as DateTime;
      } catch (_) {}
    }
    // Firestore messages are in a subcollection — conversationId is the parent doc id
    final convId = doc.reference.parent.parent?.id as String? ?? '';
    final rawAttachments = data['attachments'] as List<dynamic>? ?? [];
    if (rawAttachments.isNotEmpty) {
      print('📎 Message ${doc.id} has ${rawAttachments.length} attachments: $rawAttachments');
    }
    final attachments = rawAttachments
        .map((a) => MessageAttachment.fromMap(Map<String, dynamic>.from(a as Map)))
        .toList();

    // Parse reactions: { "👍": ["userId1", "userId2"], "❤️": ["userId3"] }
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = rawReactions.map<String, List<String>>(
      (key, value) => MapEntry(key, List<String>.from(value as List? ?? [])),
    );

    return MessageModel(
      id: doc.id as String,
      conversationId: convId,
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: createdAtDate,
      updatedAt: createdAtDate,
      attachments: attachments,
      reactions: reactions,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? [];
    final rawReactions = json['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = rawReactions.map<String, List<String>>(
      (key, value) => MapEntry(key, List<String>.from(value as List? ?? [])),
    );
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attachments: rawAttachments
          .map((a) => MessageAttachment.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList(),
      reactions: reactions,
    );
  }

  bool isSentByMe(String currentUserId) {
    return senderId == currentUserId;
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MessageAttachment>? attachments,
    Map<String, List<String>>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'reactions': reactions,
    };
  }

  // ADDED: Convenience getter for readAt (returns null if not read)
  DateTime? get readAt => isRead ? updatedAt : null;

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}..., isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is MessageModel &&
      other.id == id &&
      other.conversationId == conversationId &&
      other.senderId == senderId &&
      other.content == content &&
      other.isRead == isRead &&
      other.reactions.length == reactions.length;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      conversationId.hashCode ^
      senderId.hashCode ^
      content.hashCode ^
      isRead.hashCode ^
      reactions.length.hashCode;
  }
}