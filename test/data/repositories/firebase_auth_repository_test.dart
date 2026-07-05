import 'package:anchor/core/failures.dart';
import 'package:anchor/data/repositories/firebase_auth_repository.dart';
import 'package:anchor/domain/entities/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth auth;
  late FirebaseAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(GoogleAuthProvider());
  });

  setUp(() {
    auth = _MockFirebaseAuth();
    repository = FirebaseAuthRepository(auth);
  });

  group('authStateChanges', () {
    test('maps a Firebase user to an AuthUser carrying its uid', () {
      final user = _MockUser();
      when(() => user.uid).thenReturn('uid-1');
      when(auth.authStateChanges).thenAnswer((_) => Stream.value(user));

      expect(
        repository.authStateChanges(),
        emits(const AuthUser(uid: 'uid-1')),
      );
    });

    test('maps null to null', () {
      when(auth.authStateChanges).thenAnswer((_) => Stream.value(null));

      expect(repository.authStateChanges(), emits(null));
    });
  });

  group('signInWithGoogle', () {
    test('swallows a dismissed popup (not an error)', () async {
      when(() => auth.signInWithPopup(any())).thenThrow(
        FirebaseAuthException(code: 'popup-closed-by-user'),
      );

      await expectLater(repository.signInWithGoogle(), completes);
    });

    test('maps a network error to NetworkFailure', () async {
      when(() => auth.signInWithPopup(any())).thenThrow(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('maps an unclassified error to UnknownFailure', () async {
      when(() => auth.signInWithPopup(any())).thenThrow(
        FirebaseAuthException(code: 'internal-error'),
      );

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('signOut', () {
    test('delegates to FirebaseAuth', () async {
      when(auth.signOut).thenAnswer((_) async {});

      await repository.signOut();

      verify(auth.signOut).called(1);
    });
  });
}
