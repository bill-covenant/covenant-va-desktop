class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String audience;
  final String priority;
  final DateTime? publishedAt;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.audience,
    required this.priority,
    this.publishedAt,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      audience: json['audience'] ?? 'ALL',
      priority: json['priority'] ?? 'MEDIUM',
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}