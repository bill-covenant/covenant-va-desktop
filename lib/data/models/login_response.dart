import 'user_model.dart';

class LoginResponse {
  final String token;
  final UserModel user;
  final String? firebaseToken;

  LoginResponse({
    required this.token,
    required this.user,
    this.firebaseToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      firebaseToken: json['firebaseToken'] as String?,
    );
  }
}