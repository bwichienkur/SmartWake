import 'package:flutter/material.dart';

/// Dims the UI during the 30-minute wind-down window before bedtime.
class WindDownOverlay extends StatelessWidget {
  const WindDownOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Text(
            'Wind-down mode — relax and prepare for sleep',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
