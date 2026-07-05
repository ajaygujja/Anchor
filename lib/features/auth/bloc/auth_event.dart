part of 'auth_bloc.dart';

/// Base type for [AuthBloc] events.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to [AuthRepository.authStateChanges]. Dispatched once at
/// bloc creation.
final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

/// The user tapped "Continue with Google".
final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested();
}

/// The user asked to sign out.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Internal: the auth stream reported a new session (or its absence).
final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}
