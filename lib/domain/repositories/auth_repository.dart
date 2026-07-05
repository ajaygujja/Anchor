import 'package:anchor/domain/entities/auth_user.dart';

/// Authentication boundary for the app.
///
/// The single v1 implementation is Firebase Auth with Google Sign-In; a future
/// mobile implementation swaps in without touching presentation (spec §5.1).
/// Mutating methods throw a sealed `Failure` (never a raw platform exception)
/// so the UI layer never sees provider types.
abstract interface class AuthRepository {
  /// Emits the current [AuthUser], or `null` when signed out.
  ///
  /// Fires immediately with the restored session on startup (Firebase `LOCAL`
  /// persistence) and on every subsequent sign-in/sign-out.
  Stream<AuthUser?> authStateChanges();

  /// Signs in with Google.
  ///
  /// Returns normally without a session when the user dismisses the provider
  /// prompt (a cancellation is not an error). Throws a `Failure` on a genuine
  /// failure.
  Future<void> signInWithGoogle();

  /// Signs the current user out.
  Future<void> signOut();
}
