import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/challenge_difficulty.dart';

class MathChallenge extends StatefulWidget {
  const MathChallenge({
    super.key,
    required this.onComplete,
    this.difficulty = ChallengeDifficulty.normal,
    this.easyMode = false,
  });

  final VoidCallback onComplete;
  final ChallengeDifficulty difficulty;
  final bool easyMode;

  @override
  State<MathChallenge> createState() => _MathChallengeState();
}

class _MathChallengeState extends State<MathChallenge> {
  late int _a;
  late int _b;
  late String _operator;
  late int _answer;
  final _controller = TextEditingController();
  String? _error;

  ChallengeDifficulty get _effectiveDifficulty {
    if (widget.easyMode) return ChallengeDifficulty.easy;
    return widget.difficulty;
  }

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final random = Random();
    switch (_effectiveDifficulty) {
      case ChallengeDifficulty.easy:
        _a = random.nextInt(9) + 1;
        _b = random.nextInt(9) + 1;
        _operator = '+';
        _answer = _a + _b;
      case ChallengeDifficulty.hard:
        _a = random.nextInt(90) + 10;
        _b = random.nextInt(50) + 10;
        _operator = random.nextBool() ? '+' : '×';
        _answer = _operator == '+' ? _a + _b : _a * _b;
      case ChallengeDifficulty.normal:
        _a = random.nextInt(50) + 10;
        _b = random.nextInt(30) + 5;
        _operator = random.nextBool() ? '+' : '×';
        _answer = _operator == '+' ? _a + _b : _a * _b;
    }
  }

  void _check() {
    final input = int.tryParse(_controller.text);
    if (input == _answer) {
      widget.onComplete();
    } else {
      setState(() {
        _error = 'Incorrect. Try again.';
        _generateProblem();
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Solve to dismiss', style: Theme.of(context).textTheme.titleLarge),
        if (widget.easyMode)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Easy mode',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 32),
        Text(
          '$_a $_operator $_b = ?',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32),
            decoration: const InputDecoration(hintText: '?'),
            onSubmitted: (_) => _check(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.error)),
          ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _check, child: const Text('Submit')),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
