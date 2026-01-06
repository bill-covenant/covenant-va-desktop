import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/login_request.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    // Handle login
    on<LoginSubmitted>(_onLoginSubmitted);

    // Handle auth check (on app start)
    on<AuthCheckRequested>(_onAuthCheckRequested);

    // Handle logout
    on<LogoutRequested>(_onLogoutRequested);
  }

  // Login handler
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final loginRequest = LoginRequest(
        email: event.email,
        password: event.password,
      );

      final loginResponse = await _authRepository.login(loginRequest);

      emit(AuthAuthenticated(
        user: loginResponse.user,
        token: loginResponse.token,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      // Return to unauthenticated after showing error
      emit(const AuthUnauthenticated());
    }
  }

  // Auth check handler (restore session)
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Initialize repository (restore token)
      await _authRepository.initialize();

      // Check if user is logged in
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authRepository.getCachedUser();
        final token = await _authRepository.getCachedToken();

        if (user != null && token != null) {
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  // Logout handler
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: $e'));
    }
  }
}