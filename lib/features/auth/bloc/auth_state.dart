part of 'auth_bloc.dart';

/// Authentication status driving the router redirect (spec §5.3).
enum AuthStatus { unknown, authenticated, unauthenticated }

/// State of [AuthBloc].
///
/// [AuthStatus.unknown] holds until the first auth-stream event resolves the
/// restored session, so a returning user never flashes the sign-in screen.
final class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this.signInFailed = false,
  });

  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(AuthUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({bool signInFailed = false})
    : this._(status: AuthStatus.unauthenticated, signInFailed: signInFailed);

  final AuthStatus status;
  final AuthUser? user;

  /// Whether the last sign-in attempt failed for a non-cancellation reason.
  /// Drives a single quiet retry line; a dismissed prompt leaves this `false`.
  final bool signInFailed;

  @override
  List<Object?> get props => [status, user, signInFailed];
}
