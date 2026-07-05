import 'package:anchor/core/failures.dart';
import 'package:anchor/domain/entities/auth_user.dart';
import 'package:anchor/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth implementation of [AuthRepository] using Google Sign-In.
///
/// Web sign-in uses `signInWithPopup` (spec §2.2A); the popup must be opened
/// from a user gesture or the browser blocks it. Raw [FirebaseAuthException]s
/// are translated to sealed [Failure]s at this boundary.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  /// Provider prompt dismissals reported by Firebase; these are not failures.
  static const _cancellationCodes = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'user-cancelled',
    'web-context-cancelled',
  };

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : AuthUser(uid: user.uid),
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _auth.signInWithPopup(GoogleAuthProvider());
    } on FirebaseAuthException catch (e) {
      if (_cancellationCodes.contains(e.code)) return;
      throw _mapAuthException(e);
    } on Object catch (e) {
      throw UnknownFailure(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } on Object catch (e) {
      throw UnknownFailure(e);
    }
  }

  Failure _mapAuthException(FirebaseAuthException e) {
    return switch (e.code) {
      'network-request-failed' => const NetworkFailure(),
      _ => UnknownFailure(e),
    };
  }
}
