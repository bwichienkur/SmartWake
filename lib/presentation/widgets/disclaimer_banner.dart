import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppConstants.sleepStageDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
