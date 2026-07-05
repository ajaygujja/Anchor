import 'package:anchor/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnchorApp renders the philosophy line', (tester) async {
    await tester.pumpWidget(const AnchorApp());

    expect(find.text('Anchor — never miss twice.'), findsOneWidget);
  });
}
