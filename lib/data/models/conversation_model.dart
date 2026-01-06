class ConversationModel {
  final String id;
  final String clientId;
  final String vaId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserInfo? client;
  final UserInfo? va;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.clientId,
    required this.vaId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.client,
    this.va,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      vaId: json['vaId'] as String,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      client: json['client'] != null
          ? UserInfo.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      va: json['va'] != null
          ? UserInfo.fromJson(json['va'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  // Get the other user (client sees VA, VA sees client)
  UserInfo? getOtherUser(String currentUserId) {
    if (currentUserId == clientId) {
      return va;
    } else {
      return client;
    }
  }

  // Get other user ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == clientId ? vaId : clientId;
  }

  // ADDED: Getter for other participant name (for messages_screen.dart)
  // This will be used by passing current user ID from storage
  String get otherParticipantName {
    // This is a fallback - you should use getOtherParticipantName() with currentUserId
    // But for compile-time, we'll return a default
    return va?.fullName ?? client?.fullName ?? 'Unknown User';
  }

  // ADDED: Get other participant name based on current user
  String getOtherParticipantName(String currentUserId) {
    final otherUser = getOtherUser(currentUserId);
    return otherUser?.fullName ?? 'Unknown User';
  }

  // ADDED: Get other participant avatar (for future use)
  String? getOtherParticipantAvatar(String currentUserId) {
    // Currently UserInfo doesn't have avatar, but we'll add support
    return null;
  }

  // ADDED: copyWith method for state updates
  ConversationModel copyWith({
    String? id,
    String? clientId,
    String? vaId,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserInfo? client,
    UserInfo? va,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      vaId: vaId ?? this.vaId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      va: va ?? this.va,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  // ADDED: toJson for potential future use
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'vaId': vaId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'client': client?.toJson(),
      'va': va?.toJson(),
      'unreadCount': unreadCount,
    };
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, clientId: $clientId, vaId: $vaId, unreadCount: $unreadCount)';
  }
}

class UserInfo {
  final String id;
  final String email;
  final String firstName;
  final String lastName;

  UserInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }

  // ADDED: toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  @override
  String toString() {
    return 'UserInfo(id: $id, name: $fullName, email: $email)';
  }
}