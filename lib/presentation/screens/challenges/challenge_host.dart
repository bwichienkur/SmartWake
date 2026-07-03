import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/alarm.dart';
import '../../../domain/entities/challenge_type.dart';
import 'challenges/barcode_challenge.dart';
import 'challenges/math_challenge.dart';
import 'challenges/remaining_challenges.dart';
import 'challenges/shake_challenge.dart';

class ChallengeHost extends ConsumerWidget {
  const ChallengeHost({
    super.key,
    required this.challengeType,
    required this.alarm,
    required this.onComplete,
  });

  final ChallengeType challengeType;
  final Alarm alarm;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(userProvider).maybeWhen(
          data: (user) => user?.preferences.easyChallengeMode ?? false,
          orElse: () => false,
        );

    final barcodeValue =
        alarm.challengeBarcodeValue ?? ref.watch(userProvider).maybeWhen(
              data: (user) => user?.preferences.registeredBarcode,
              orElse: () => null,
            );

    final qrValue = alarm.challengeQrValue ?? ref.watch(userProvider).maybeWhen(
          data: (user) => user?.preferences.registeredQrCode,
          orElse: () => null,
        );

    return switch (challengeType) {
      ChallengeType.barcodeScan => BarcodeChallenge(
          expectedValue: barcodeValue,
          onComplete: onComplete,
        ),
      ChallengeType.qrCode => QrChallenge(
          expectedValue: qrValue,
          onComplete: onComplete,
        ),
      ChallengeType.mathProblem => MathChallenge(
          onComplete: onComplete,
          difficulty: alarm.challengeDifficulty,
          easyMode: easyMode,
        ),
      ChallengeType.memoryGame => MemoryChallenge(onComplete: onComplete),
      ChallengeType.patternMatch => PatternChallenge(onComplete: onComplete),
      ChallengeType.typingChallenge => TypingChallenge(onComplete: onComplete),
      ChallengeType.shakePhone => ShakeChallenge(onComplete: onComplete),
      ChallengeType.stepCounter => StepsChallenge(onComplete: onComplete),
      ChallengeType.brightnessDetection =>
        BrightnessChallenge(onComplete: onComplete),
      ChallengeType.faceVerification => FaceChallenge(
          requireSmile: false,
          onComplete: onComplete,
        ),
      ChallengeType.smileDetection => FaceChallenge(
          requireSmile: true,
          onComplete: onComplete,
        ),
      ChallengeType.slidingPuzzle => PuzzleChallenge(onComplete: onComplete),
      ChallengeType.captcha => CaptchaChallenge(onComplete: onComplete),
    };
  }
}
