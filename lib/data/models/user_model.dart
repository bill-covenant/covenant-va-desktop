class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final String? wiseEmail; // ← NEW
  final UserProfile? profile;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.wiseEmail,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      wiseEmail: json['wiseEmail'] as String?, // ← NEW
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'status': status,
      'wiseEmail': wiseEmail,
      'profile': profile?.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();
}

class UserProfile {
  final String? phone;
  final String? company;
  final String? timezone;
  final String? avatar;

  UserProfile({
    this.phone,
    this.company,
    this.timezone,
    this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      timezone: json['timezone'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'company': company,
      'timezone': timezone,
      'avatar': avatar,
    };
  }
}