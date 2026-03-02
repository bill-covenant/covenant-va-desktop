class NoteCategory {
  final String id;
  final String name;
  final String color;
  final int sortOrder;
  final int noteCount;

  NoteCategory({
    required this.id,
    required this.name,
    required this.color,
    this.sortOrder = 0,
    this.noteCount = 0,
  });

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'],
      name: json['name'],
      color: json['color'] ?? '#8B5CF6',
      sortOrder: json['sortOrder'] ?? 0,
      noteCount: json['_count']?['notes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'sortOrder': sortOrder,
  };
}

class NoteModel {
  final String id;
  final String? categoryId;
  final String title;
  final String content;
  final bool isPinned;
  final NoteCategory? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    this.categoryId,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      categoryId: json['categoryId'],
      title: json['title'],
      content: json['content'] ?? '',
      isPinned: json['isPinned'] ?? false,
      category: json['category'] != null
          ? NoteCategory.fromJson(json['category'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'title': title,
    'content': content,
    'isPinned': isPinned,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  NoteModel copyWith({
    String? title,
    String? content,
    String? categoryId,
    bool? isPinned,
    NoteCategory? category,
  }) {
    return NoteModel(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}