import 'package:anchor/data/repositories/firebase_auth_repository.dart';
import 'package:anchor/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Composition root: the one place concrete implementations are chosen and
/// wired (spec §5.2). Constructor injection only — no service locator.
///
/// Blocs receive these repository interfaces through their constructors; the
/// app never reaches for a global.
class AppDependencies {
  const AppDependencies({required this.authRepository});

  /// Wires the production Firebase-backed dependencies.
  factory AppDependencies.production() {
    return AppDependencies(
      authRepository: FirebaseAuthRepository(FirebaseAuth.instance),
    );
  }

  final AuthRepository authRepository;
}
