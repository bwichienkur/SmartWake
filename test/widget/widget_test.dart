import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_wake/core/theme/app_theme.dart';
import 'package:smart_wake/presentation/widgets/alarm_card.dart';
import 'package:smart_wake/presentation/widgets/empty_state.dart';
import 'package:smart_wake/presentation/widgets/sleep_score_ring.dart';
import 'package:smart_wake/domain/entities/alarm.dart';
import 'package:smart_wake/domain/entities/challenge_type.dart';
import 'package:intl/intl.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('EmptyState displays title and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        EmptyState(
          icon: Icons.alarm,
          title: 'No alarms',
          subtitle: 'Add one',
          actionLabel: 'Add',
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('No alarms'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('SleepScoreRing displays score', (tester) async {
    await tester.pumpWidget(wrap(const SleepScoreRing(score: 85)));
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Sleep Score'), findsOneWidget);
  });

  testWidgets('AlarmCard shows alarm details', (tester) async {
    final alarm = Alarm(
      id: '1',
      label: 'Work',
      earliestWakeTime: DateTime(2026, 1, 1, 6, 30),
      latestWakeTime: DateTime(2026, 1, 1, 6, 45),
      repeatDays: [1, 2, 3, 4, 5],
      isSmartWake: true,
      challenges: [ChallengeType.mathProblem],
    );

    await tester.pumpWidget(
      wrap(
        AlarmCard(
          alarm: alarm,
          timeFormat: DateFormat.jm(),
          onToggle: (_) {},
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Smart 15min'), findsOneWidget);
  });
}
