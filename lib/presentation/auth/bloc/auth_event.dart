import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Login event
class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

// Check if user is already logged in (on app start)
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

// Logout event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}