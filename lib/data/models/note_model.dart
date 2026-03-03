class NoteModel {
  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  NoteModel copyWith({String? title, String? content, bool? isPinned}) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}