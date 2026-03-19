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

  // Contact
  final String? secondaryEmail;
  final String? whatsapp;

  // Demographics
  final DateTime? dateOfBirth;
  final String? gender;
  final String? nationality;

  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

  // Professional
  final String? bio;
  final List<String> skills;
  final List<String> languages;
  final Map<String, dynamic>? deviceSpecs;

  UserProfile({
    this.phone,
    this.company,
    this.timezone,
    this.avatar,
    this.secondaryEmail,
    this.whatsapp,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.bio,
    this.skills = const [],
    this.languages = const [],
    this.deviceSpecs,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      timezone: json['timezone'] as String?,
      avatar: json['avatar'] as String?,
      secondaryEmail: json['secondaryEmail'] as String?,
      whatsapp: json['whatsapp'] as String?,
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth'].toString()) : null,
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      emergencyContactRelationship: json['emergencyContactRelationship'] as String?,
      bio: json['bio'] as String?,
      skills: List<String>.from(json['skills'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      deviceSpecs: json['deviceSpecs'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'company': company,
      'timezone': timezone,
      'avatar': avatar,
      'secondaryEmail': secondaryEmail,
      'whatsapp': whatsapp,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'nationality': nationality,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelationship': emergencyContactRelationship,
      'bio': bio,
      'skills': skills,
      'languages': languages,
      'deviceSpecs': deviceSpecs,
    };
  }
}