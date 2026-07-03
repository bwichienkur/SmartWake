enum ChallengeType {
  barcodeScan,
  qrCode,
  mathProblem,
  memoryGame,
  patternMatch,
  typingChallenge,
  shakePhone,
  stepCounter,
  brightnessDetection,
  faceVerification,
  smileDetection,
  slidingPuzzle,
  captcha;

  String get id => name;

  String get displayName => switch (this) {
        ChallengeType.barcodeScan => 'Barcode Scan',
        ChallengeType.qrCode => 'QR Code',
        ChallengeType.mathProblem => 'Math Problem',
        ChallengeType.memoryGame => 'Memory Game',
        ChallengeType.patternMatch => 'Pattern Match',
        ChallengeType.typingChallenge => 'Typing Challenge',
        ChallengeType.shakePhone => 'Shake Phone',
        ChallengeType.stepCounter => 'Step Counter',
        ChallengeType.brightnessDetection => 'Brightness Check',
        ChallengeType.faceVerification => 'Face Verification',
        ChallengeType.smileDetection => 'Smile Detection',
        ChallengeType.slidingPuzzle => 'Sliding Puzzle',
        ChallengeType.captcha => 'Captcha',
      };

  String get iconName => switch (this) {
        ChallengeType.barcodeScan => 'barcode',
        ChallengeType.qrCode => 'qr_code',
        ChallengeType.mathProblem => 'calculate',
        ChallengeType.memoryGame => 'psychology',
        ChallengeType.patternMatch => 'grid_view',
        ChallengeType.typingChallenge => 'keyboard',
        ChallengeType.shakePhone => 'vibration',
        ChallengeType.stepCounter => 'directions_walk',
        ChallengeType.brightnessDetection => 'light_mode',
        ChallengeType.faceVerification => 'face',
        ChallengeType.smileDetection => 'sentiment_satisfied',
        ChallengeType.slidingPuzzle => 'extension',
        ChallengeType.captcha => 'security',
      };

  bool get isFree => switch (this) {
        ChallengeType.mathProblem ||
        ChallengeType.shakePhone ||
        ChallengeType.barcodeScan =>
          true,
        _ => false,
      };
}

enum ChallengeMode {
  single,
  sequence,
  random;

  String get displayName => switch (this) {
        ChallengeMode.single => 'Single Challenge',
        ChallengeMode.sequence => 'Challenge Sequence',
        ChallengeMode.random => 'Random Challenge',
      };
}
