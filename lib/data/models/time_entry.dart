// lib/data/models/time_entry.dart

class TimeEntry {
  final String id;
  final String vaId;
  final String clientId;
  final String assignmentId;
  final DateTime date;
  final double hoursWorked;
  final String? description;
  final String status; // SUBMITTED, APPROVED, REJECTED
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeEntry({
    required this.id,
    required this.vaId,
    required this.clientId,
    required this.assignmentId,
    required this.date,
    required this.hoursWorked,
    this.description,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String,
      vaId: json['vaId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      assignmentId: json['assignmentId'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      hoursWorked: (json['hoursWorked'] as num).toDouble(),
      description: json['description'] as String?,
      status: json['status'] as String,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt'] as String) 
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vaId': vaId,
      'clientId': clientId,
      'assignmentId': assignmentId,
      'date': date.toIso8601String(),
      'hoursWorked': hoursWorked,
      'description': description,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper to get status color
  String getStatusColor() {
    switch (status) {
      case 'APPROVED':
        return 'green';
      case 'REJECTED':
        return 'red';
      case 'SUBMITTED':
      default:
        return 'orange';
    }
  }

  // Helper to get status icon
  String getStatusIcon() {
    switch (status) {
      case 'APPROVED':
        return '✓';
      case 'REJECTED':
        return '✗';
      case 'SUBMITTED':
      default:
        return '⏳';
    }
  }
}

class MonthlySummary {
  final String month;
  final double totalHours;
  final int daysLogged;
  final double avgPerDay;
  final double estimatedEarnings;
  final List<TimeEntry> entries;

  MonthlySummary({
    required this.month,
    required this.totalHours,
    required this.daysLogged,
    required this.avgPerDay,
    required this.estimatedEarnings,
    required this.entries,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      daysLogged: json['daysLogged'] as int,
      avgPerDay: (json['avgPerDay'] as num).toDouble(),
      estimatedEarnings: (json['estimatedEarnings'] as num).toDouble(),
      entries: (json['entries'] as List)
          .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'totalHours': totalHours,
      'daysLogged': daysLogged,
      'avgPerDay': avgPerDay,
      'estimatedEarnings': estimatedEarnings,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}