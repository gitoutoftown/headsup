// Basic Flutter widget test for HeadsUp

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:headsup_app/main.dart';

void main() {
  testWidgets('HeadsUp app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: HeadsUpApp()));

    // Verify the app loads with basic elements
    expect(find.text('Posture Score'), findsOneWidget);
    expect(find.text('Start Tracking'), findsOneWidget);
  });
}
