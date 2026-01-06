class ClientModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? company;

  ClientModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.company,
  });

  String get fullName => '$firstName $lastName';

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['profile']?['phone'] as String?,
      company: json['profile']?['company'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profile': {
        'phone': phone,
        'company': company,
      },
    };
  }
}