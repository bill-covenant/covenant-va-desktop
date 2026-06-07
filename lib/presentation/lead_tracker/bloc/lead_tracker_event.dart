import 'package:equatable/equatable.dart';

abstract class LeadTrackerEvent extends Equatable {
  const LeadTrackerEvent();
  @override
  List<Object?> get props => [];
}

class LeadTrackerLoadRequested extends LeadTrackerEvent {
  const LeadTrackerLoadRequested();
}

class LeadTrackerCreateRequested extends LeadTrackerEvent {
  final String name;
  final String company;
  final String? industry;
  final String? department;
  final String phone;
  final String? email;
  final String status;

  const LeadTrackerCreateRequested({
    required this.name,
    required this.company,
    this.industry,
    this.department,
    required this.phone,
    this.email,
    this.status = 'New',
  });

  @override
  List<Object?> get props => [name, company, industry, department, phone, email, status];
}

class LeadTrackerUpdateRequested extends LeadTrackerEvent {
  final String id;
  final Map<String, dynamic> data;

  const LeadTrackerUpdateRequested({required this.id, required this.data});

  @override
  List<Object?> get props => [id, data];
}

class LeadTrackerDeleteRequested extends LeadTrackerEvent {
  final String id;
  const LeadTrackerDeleteRequested({required this.id});
  @override
  List<Object?> get props => [id];
}
