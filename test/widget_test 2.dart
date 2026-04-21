import 'package:flutter_test/flutter_test.dart';

import 'package:ngo_support_app/main.dart';
import 'package:ngo_support_app/services/accessibility_service.dart';

void main() {
  testWidgets('NGO Support App loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(NGOSupportApp(accessibilityService: AccessibilityService()));

    // Verify that our app loads with the correct title
    expect(find.text('Beacon of New Beginnings'), findsOneWidget);
  });
}
