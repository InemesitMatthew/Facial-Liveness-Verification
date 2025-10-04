// Widget test for the Facial Liveness Detection example app

import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/main.dart';

void main() {
  testWidgets('Liveness Detection Demo smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ExampleApp());

    // Verify that the main title is displayed
    expect(find.text('Facial Liveness Detection Package Demo'), findsOneWidget);
    
    // Verify that verification buttons are present
    expect(find.text('Basic Verification'), findsOneWidget);
    expect(find.text('Quick Verification'), findsOneWidget);
    expect(find.text('Secure Verification'), findsOneWidget);
    expect(find.text('Custom Theme'), findsOneWidget);
  });
}
