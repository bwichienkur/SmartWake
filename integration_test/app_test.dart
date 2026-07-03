import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:smart_wake/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows onboarding or alarms', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // App should show either onboarding or main alarms screen
    final hasOnboarding = find.text('Get Started').evaluate().isNotEmpty;
    final hasAlarms = find.text('SmartWake').evaluate().isNotEmpty;

    expect(hasOnboarding || hasAlarms, isTrue);
  });
}
