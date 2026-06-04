class LeadModel {
  final String id;
  final String name;
  final String company;
  final String? department;
  final String phone;
  final String? email;
  final String status;
  final String? callDisposition;
  final DateTime? followUpDate;
  final DateTime? lastContacted;
  final String? painPoints;
  final String? objections;
  final String? additionalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeadModel({
    required this.id,
    required this.name,
    required this.company,
    this.department,
    required this.phone,
    this.email,
    required this.status,
    this.callDisposition,
    this.followUpDate,
    this.lastContacted,
    this.painPoints,
    this.objections,
    this.additionalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      company: json['company'] as String? ?? '',
      department: json['department'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      status: json['status'] as String? ?? 'New',
      callDisposition: json['callDisposition'] as String?,
      followUpDate: json['followUpDate'] != null ? DateTime.tryParse(json['followUpDate'].toString()) : null,
      lastContacted: json['lastContacted'] != null ? DateTime.tryParse(json['lastContacted'].toString()) : null,
      painPoints: json['painPoints'] as String?,
      objections: json['objections'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'company': company,
    'department': department,
    'phone': phone,
    'email': email,
    'status': status,
    'callDisposition': callDisposition,
    'followUpDate': followUpDate?.toIso8601String(),
    'lastContacted': lastContacted?.toIso8601String(),
    'painPoints': painPoints,
    'objections': objections,
    'additionalNotes': additionalNotes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
