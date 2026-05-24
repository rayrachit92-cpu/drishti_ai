import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_ai/main.dart';

void main() {
  testWidgets('App loads auth screen', (tester) async {
    await tester.pumpWidget(const DrishtiApp());
    expect(find.text('DRISHTI'), findsOneWidget);
  });
}
