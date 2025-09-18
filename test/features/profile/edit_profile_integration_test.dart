import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/profile/presentation/edit_profile_page.dart';

void main() {
  testWidgets('EditProfilePage renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: EditProfilePage())),
    );

    // Should find the Edit Profile title
    expect(find.text('Edit Profile'), findsOneWidget);

    // Should find the back button
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Pump for a moment to let async operations start
    await tester.pump(Duration(milliseconds: 100));
  });
}
