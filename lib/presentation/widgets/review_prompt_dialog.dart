import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

Future<void> showReviewPromptDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Enjoying SmartWake?'),
      content: const Text(
        'You\'ve woken up successfully several times. '
        'A quick review helps others discover Smart Wake.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final uri = Uri.parse(
              'mailto:${AppConstants.supportEmail}?subject=SmartWake%20Feedback',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          child: const Text('Send feedback'),
        ),
      ],
    ),
  );
}
