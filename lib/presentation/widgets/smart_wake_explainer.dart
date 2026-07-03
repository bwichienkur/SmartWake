import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

Future<void> showSmartWakeExplainer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.paddingOf(ctx).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How Smart Wake works', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          const _Step(
            icon: Icons.sensors,
            title: 'We estimate sleep stages',
            body: 'From your wearable or phone sensors — never medical-grade.',
          ),
          const _Step(
            icon: Icons.schedule,
            title: 'We watch your wake window',
            body: 'Between earliest and latest wake, we look for light sleep.',
          ),
          const _Step(
            icon: Icons.alarm,
            title: 'We wake you gently',
            body: 'Alarm triggers when light sleep is detected, or at latest wake.',
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.sleepStageDisclaimer,
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
