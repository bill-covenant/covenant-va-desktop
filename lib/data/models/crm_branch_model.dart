class CrmBranchModel {
  final String id;
  final String name;
  final String email;
  final String? location;
  final String? phone;
  final bool isActive;

  CrmBranchModel({
    required this.id,
    required this.name,
    required this.email,
    this.location,
    this.phone,
    this.isActive = true,
  });

  factory CrmBranchModel.fromJson(Map<String, dynamic> json) {
    return CrmBranchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      location: json['location'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
