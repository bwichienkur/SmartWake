import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/challenge_config.dart';
import '../../../../domain/entities/challenge_difficulty.dart';

class ShakeChallenge extends StatefulWidget {
  const ShakeChallenge({
    super.key,
    required this.onComplete,
    this.difficulty = ChallengeDifficulty.normal,
    this.easyMode = false,
  });

  final VoidCallback onComplete;
  final ChallengeDifficulty difficulty;
  final bool easyMode;

  @override
  State<ShakeChallenge> createState() => _ShakeChallengeState();
}

class _ShakeChallengeState extends State<ShakeChallenge> {
  int _shakeCount = 0;
  late int _requiredShakes;
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.now();

  @override
  void initState() {
    super.initState();
    _requiredShakes = ChallengeConfig(
      difficulty: widget.difficulty,
      easyMode: widget.easyMode,
    ).shakeCount;
    _sub = accelerometerEventStream().listen((event) {
      final magnitude =
          (event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 120 &&
          DateTime.now().difference(_lastShake).inMilliseconds > 300) {
        _lastShake = DateTime.now();
        setState(() {
          _shakeCount++;
          if (_shakeCount >= _requiredShakes) widget.onComplete();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.vibration,
          size: 64,
          color: AppColors.accent
              .withValues(alpha: 0.5 + _shakeCount / _requiredShakes * 0.5),
        ),
        const SizedBox(height: 24),
        Text('Shake your phone!', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(
          '$_shakeCount / $_requiredShakes',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _shakeCount / _requiredShakes),
      ],
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
