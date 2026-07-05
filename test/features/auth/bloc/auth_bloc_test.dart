import 'package:anchor/core/failures.dart';
import 'package:anchor/domain/entities/auth_user.dart';
import 'package:anchor/domain/repositories/auth_repository.dart';
import 'package:anchor/features/auth/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository authRepository;

  const user = AuthUser(uid: 'uid-1');

  setUp(() {
    authRepository = _MockAuthRepository();
  });

  group('AuthBloc', () {
    test('initial state is unknown', () {
      when(
        authRepository.authStateChanges,
      ).thenAnswer((_) => const Stream.empty());
      expect(AuthBloc(authRepository).state, const AuthState.unknown());
    });

    blocTest<AuthBloc, AuthState>(
      'emits authenticated when the auth stream reports a user',
      setUp: () {
        when(
          authRepository.authStateChanges,
        ).thenAnswer((_) => Stream.value(user));
      },
      build: () => AuthBloc(authRepository),
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [const AuthState.authenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when the auth stream reports null',
      setUp: () {
        when(
          authRepository.authStateChanges,
        ).thenAnswer((_) => Stream.value(null));
      },
      build: () => AuthBloc(authRepository),
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [const AuthState.unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'sign-in success emits nothing itself; the stream drives the transition',
      setUp: () {
        when(
          authRepository.authStateChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(authRepository.signInWithGoogle).thenAnswer((_) async {});
      },
      build: () => AuthBloc(authRepository),
      act: (bloc) => bloc.add(const AuthSignInRequested()),
      expect: () => <AuthState>[],
      verify: (_) => verify(authRepository.signInWithGoogle).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'sign-in failure emits unauthenticated with signInFailed',
      setUp: () {
        when(
          authRepository.authStateChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          authRepository.signInWithGoogle,
        ).thenThrow(const NetworkFailure());
      },
      build: () => AuthBloc(authRepository),
      act: (bloc) => bloc.add(const AuthSignInRequested()),
      expect: () => [const AuthState.unauthenticated(signInFailed: true)],
    );

    blocTest<AuthBloc, AuthState>(
      'sign-out delegates to the repository',
      setUp: () {
        when(
          authRepository.authStateChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(authRepository.signOut).thenAnswer((_) async {});
      },
      build: () => AuthBloc(authRepository),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      verify: (_) => verify(authRepository.signOut).called(1),
    );
  });
}
