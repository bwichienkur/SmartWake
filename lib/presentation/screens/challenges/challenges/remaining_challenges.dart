import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class MemoryChallenge extends StatefulWidget {
  const MemoryChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<MemoryChallenge> createState() => _MemoryChallengeState();
}

class _MemoryChallengeState extends State<MemoryChallenge> {
  late List<int> _sequence;
  late List<int> _userInput;
  int _showIndex = 0;
  bool _showing = true;
  bool _inputPhase = false;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _sequence = List.generate(4, (_) => Random().nextInt(4));
    _userInput = [];
    _showIndex = 0;
    _showing = true;
    _inputPhase = false;
    _showNext();
  }

  Future<void> _showNext() async {
    for (var i = 0; i < _sequence.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _showIndex = i);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _showIndex = -1);
    }
    setState(() {
      _showing = false;
      _inputPhase = true;
    });
  }

  void _onTap(int index) {
    if (!_inputPhase) return;
    _userInput.add(index);
    if (_userInput.length == _sequence.length) {
      if (_listEquals(_userInput, _sequence)) {
        widget.onComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong sequence. Try again.')),
        );
        _startRound();
      }
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static const _colors = [
    AppColors.error,
    AppColors.primary,
    AppColors.success,
    AppColors.accent,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _inputPhase ? 'Repeat the sequence' : 'Watch carefully...',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(4, (i) {
            final isLit = _showing && _showIndex == i;
            return GestureDetector(
              onTap: () => _onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isLit ? _colors[i] : _colors[i].withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PatternChallenge extends StatefulWidget {
  const PatternChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<PatternChallenge> createState() => _PatternChallengeState();
}

class _PatternChallengeState extends State<PatternChallenge> {
  late List<int> _pattern;
  final _selected = <int>[];

  @override
  void initState() {
    super.initState();
    _pattern = List.generate(5, (_) => Random().nextInt(9));
  }

  void _onTap(int index) {
    _selected.add(index);
    if (_selected.length == _pattern.length) {
      if (_listEquals(_selected, _pattern)) {
        widget.onComplete();
      } else {
        setState(() {
          _selected.clear();
          _pattern = List.generate(5, (_) => Random().nextInt(9));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong pattern. Try again.')),
        );
      }
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Tap the pattern', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          _pattern.map((i) => i + 1).join(' → '),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _onTap(i),
            child: Container(
              decoration: BoxDecoration(
                color: _selected.contains(i)
                    ? AppColors.primary
                    : AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('${i + 1}', style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TypingChallenge extends StatefulWidget {
  const TypingChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<TypingChallenge> createState() => _TypingChallengeState();
}

class _TypingChallengeState extends State<TypingChallenge> {
  static const _phrases = [
    'I am awake and ready',
    'Good morning sunshine',
    'Rise and shine today',
  ];
  late String _phrase;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phrase = _phrases[Random().nextInt(_phrases.length)];
  }

  void _check() {
    if (_controller.text.trim().toLowerCase() == _phrase.toLowerCase()) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Type this phrase', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('"$_phrase"', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          onChanged: (_) => _check(),
          decoration: const InputDecoration(hintText: 'Start typing...'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class StepsChallenge extends StatefulWidget {
  const StepsChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<StepsChallenge> createState() => _StepsChallengeState();
}

class _StepsChallengeState extends State<StepsChallenge> {
  int _steps = 0;
  static const _required = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.directions_walk, size: 64),
        const SizedBox(height: 16),
        Text('Take $_required steps', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('$_steps / $_required', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            setState(() {
              _steps++;
              if (_steps >= _required) widget.onComplete();
            });
          },
          child: const Text('+ Step (simulated)'),
        ),
      ],
    );
  }
}

class BrightnessChallenge extends StatefulWidget {
  const BrightnessChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<BrightnessChallenge> createState() => _BrightnessChallengeState();
}

class _BrightnessChallengeState extends State<BrightnessChallenge> {
  bool _brightEnough = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _brightEnough ? Icons.light_mode : Icons.light_mode_outlined,
          size: 64,
          color: _brightEnough ? AppColors.accent : null,
        ),
        const SizedBox(height: 16),
        Text(
          'Turn on the lights or go to a bright area',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            setState(() => _brightEnough = true);
            widget.onComplete();
          },
          child: const Text("I'm in a bright area"),
        ),
      ],
    );
  }
}

class FaceChallenge extends StatelessWidget {
  const FaceChallenge({
    super.key,
    required this.requireSmile,
    required this.onComplete,
  });

  final bool requireSmile;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          requireSmile ? Icons.sentiment_satisfied : Icons.face,
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          requireSmile ? 'Smile at the camera' : 'Verify your face',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Camera-based verification requires device permissions',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onComplete,
          child: Text(requireSmile ? 'I smiled!' : 'Verified'),
        ),
      ],
    );
  }
}

class PuzzleChallenge extends StatefulWidget {
  const PuzzleChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<PuzzleChallenge> createState() => _PuzzleChallengeState();
}

class _PuzzleChallengeState extends State<PuzzleChallenge> {
  late List<int> _tiles;

  @override
  void initState() {
    super.initState();
    _tiles = List.generate(8, (i) => i + 1)..add(0);
    _tiles.shuffle();
  }

  bool get _solved {
    for (var i = 0; i < 8; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles[8] == 0;
  }

  void _move(int index) {
    final emptyIndex = _tiles.indexOf(0);
    final row = index ~/ 3;
    final col = index % 3;
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    if ((row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1)) {
      setState(() {
        _tiles[emptyIndex] = _tiles[index];
        _tiles[index] = 0;
        if (_solved) widget.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Solve the puzzle', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          width: 240,
          height: 240,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: 9,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _move(i),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _tiles[i] == 0
                      ? Colors.transparent
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _tiles[i] == 0 ? '' : '${_tiles[i]}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CaptchaChallenge extends StatefulWidget {
  const CaptchaChallenge({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<CaptchaChallenge> createState() => _CaptchaChallengeState();
}

class _CaptchaChallengeState extends State<CaptchaChallenge> {
  late int _a;
  late int _b;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = Random();
    _a = r.nextInt(10) + 1;
    _b = r.nextInt(10) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Verify you\'re human', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'What is $_a + $_b?',
            style: const TextStyle(fontSize: 24, letterSpacing: 4),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: 'Answer'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            if (int.tryParse(_controller.text) == _a + _b) {
              widget.onComplete();
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
