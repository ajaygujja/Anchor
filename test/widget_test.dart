import 'package:anchor/app/app.dart';
import 'package:anchor/app/di.dart';
import 'package:anchor/core/copy.dart';
import 'package:anchor/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('routes an unauthenticated user to the sign-in screen', (
    tester,
  ) async {
    final authRepository = _MockAuthRepository();
    when(
      authRepository.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      AnchorApp(dependencies: AppDependencies(authRepository: authRepository)),
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.continueWithGoogle), findsOneWidget);
    expect(find.text(Copy.philosophy), findsOneWidget);
  });
}
