import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state (checking if user is logged in)
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Loading state (during login/logout)
class AuthLoading extends AuthState {
  const AuthLoading();
}

// Authenticated state (user is logged in)
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

// Unauthenticated state (user not logged in)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// Error state (login failed)
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}