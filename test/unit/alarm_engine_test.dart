import 'package:flutter_test/flutter_test.dart';

import 'package:smart_wake/domain/entities/alarm.dart';

void main() {
  test('armedStatusFor returns armed when enabled alarms exist', () {
    final alarms = [
      Alarm(
        id: '1',
        label: 'Test',
        earliestWakeTime: DateTime(2026, 1, 1, 6, 30),
        latestWakeTime: DateTime(2026, 1, 1, 6, 45),
        repeatDays: [1, 2, 3, 4, 5],
        isEnabled: true,
      ),
    ];
    expect(armedStatusFor(alarms), AlarmArmedStatus.armed);
  });

  test('armedStatusFor returns noAlarms when empty', () {
    expect(armedStatusFor([]), AlarmArmedStatus.noAlarms);
  });

  test('armedStatusFor returns disabled when all disabled', () {
    final alarms = [
      Alarm(
        id: '1',
        label: 'Test',
        earliestWakeTime: DateTime(2026, 1, 1, 6, 30),
        latestWakeTime: DateTime(2026, 1, 1, 6, 45),
        repeatDays: [1],
        isEnabled: false,
      ),
    ];
    expect(armedStatusFor(alarms), AlarmArmedStatus.disabled);
  });
}
