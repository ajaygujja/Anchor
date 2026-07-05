import 'dart:async';

import 'package:anchor/core/failures.dart';
import 'package:anchor/domain/entities/auth_user.dart';
import 'package:anchor/domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the app's authentication status by subscribing to
/// [AuthRepository.authStateChanges] and translating sign-in/out intents.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState.unknown()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onUserChanged);
  }

  final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    _subscription ??= _authRepository.authStateChanges().listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signInWithGoogle();
    } on Failure {
      emit(const AuthState.unauthenticated(signInFailed: true));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    emit(
      user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user),
    );
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
