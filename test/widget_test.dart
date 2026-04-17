import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ngo_support_app/main.dart';

void main() {
  testWidgets('NGO Support App loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NGOSupportApp());

    // Trigger one frame
    await tester.pump();

    // Verify that our app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
