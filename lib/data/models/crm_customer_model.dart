import 'crm_branch_model.dart';

class CrmCustomerModel {
  final String id;
  final String vaId;
  final String? branchId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? orderDetails;
  final String? notes;
  final DateTime? notifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CrmBranchModel? branch;

  CrmCustomerModel({
    required this.id,
    required this.vaId,
    this.branchId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
    this.orderDetails,
    this.notes,
    this.notifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.branch,
  });

  String get fullName => '$firstName $lastName';

  factory CrmCustomerModel.fromJson(Map<String, dynamic> json) {
    return CrmCustomerModel(
      id: json['id'] as String,
      vaId: json['vaId'] as String,
      branchId: json['branchId'] as String?,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      orderDetails: json['orderDetails'] as String?,
      notes: json['notes'] as String?,
      notifiedAt: json['notifiedAt'] != null ? DateTime.tryParse(json['notifiedAt'].toString()) : null,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      branch: json['branch'] != null ? CrmBranchModel.fromJson(json['branch'] as Map<String, dynamic>) : null,
    );
  }
}
