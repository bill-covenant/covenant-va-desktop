class TaskAttachment {
  final String id;
  final String taskId;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final String uploadedById;
  final String? uploaderName;
  final DateTime createdAt;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedById,
    this.uploaderName,
    required this.createdAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['uploadedBy'] != null) {
      final ub = json['uploadedBy'] as Map<String, dynamic>;
      name = '${ub['firstName'] ?? ''} ${ub['lastName'] ?? ''}'.trim();
    }
    return TaskAttachment(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String,
      uploadedById: json['uploadedById'] as String,
      uploaderName: name,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType.contains('pdf');
  bool get isSpreadsheet => mimeType.contains('spreadsheet') || mimeType.contains('excel') || mimeType.contains('csv');
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? assignedToId;
  final List<TaskAttachment> attachments;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.assignedToId,
    this.attachments = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final attachmentsList = json['attachments'] as List?;
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'] as String,
      assignedToId: json['assignedToId'] as String?,
      attachments: attachmentsList != null
          ? attachmentsList.map((a) => TaskAttachment.fromJson(a as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'assignedToId': assignedToId,
    };
  }

  // Helper getters
  bool get isPending => status == 'PENDING';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  
  bool get isHighPriority => priority == 'HIGH' || priority == 'URGENT';
  bool get isMediumPriority => priority == 'MEDIUM';
  bool get isLowPriority => priority == 'LOW';
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}