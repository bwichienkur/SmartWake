import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/alarm_sound.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/alarm.dart';
import '../../../domain/entities/challenge_difficulty.dart';
import '../../../domain/entities/challenge_type.dart';
import '../../widgets/premium_badge.dart';
import '../challenges/challenge_host.dart';

class AlarmEditorScreen extends ConsumerStatefulWidget {
  const AlarmEditorScreen({super.key, this.alarmId});

  final String? alarmId;

  @override
  ConsumerState<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends ConsumerState<AlarmEditorScreen> {
  final _labelController = TextEditingController(text: 'Alarm');
  final _previewPlayer = AudioPlayer();
  TimeOfDay _earliest = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _latest = const TimeOfDay(hour: 6, minute: 45);
  bool _smartWake = true;
  bool _vibration = true;
  bool _snooze = true;
  bool _skipHolidays = false;
  int _snoozeMinutes = 9;
  double _volume = 0.8;
  int _fadeIn = 30;
  String _soundId = 'gentle_chime';
  String? _iconName;
  List<int> _repeatDays = [1, 2, 3, 4, 5, 6, 7];
  ChallengeMode _challengeMode = ChallengeMode.single;
  ChallengeDifficulty _challengeDifficulty = ChallengeDifficulty.normal;
  List<ChallengeType> _challenges = [ChallengeType.mathProblem];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarm();
  }

  Future<void> _loadAlarm() async {
    if (widget.alarmId != null) {
      final alarm =
          await ref.read(alarmRepositoryProvider).getAlarmById(widget.alarmId!);
      if (alarm != null && mounted) {
        _labelController.text = alarm.label;
        _earliest = TimeOfDay.fromDateTime(alarm.earliestWakeTime);
        _latest = TimeOfDay.fromDateTime(alarm.latestWakeTime);
        _smartWake = alarm.isSmartWake;
        _vibration = alarm.vibrationEnabled;
        _snooze = alarm.snoozeEnabled;
        _skipHolidays = alarm.skipHolidays;
        _snoozeMinutes = alarm.snoozeMinutes;
        _volume = alarm.volume;
        _fadeIn = alarm.fadeInSeconds;
        _soundId = alarm.soundId;
        _iconName = alarm.iconName;
        _repeatDays = alarm.repeatDays;
        _challengeMode = alarm.challengeMode;
        _challengeDifficulty = alarm.challengeDifficulty;
        _challenges = alarm.challenges;
      }
    }
    setState(() => _loading = false);
  }

  int get _windowMinutes {
    final e = _earliest.hour * 60 + _earliest.minute;
    final l = _latest.hour * 60 + _latest.minute;
    return l >= e ? l - e : (24 * 60 - e) + l;
  }

  Future<void> _previewSound() async {
    try {
      await _previewPlayer.stop();
      await _previewPlayer.setVolume(_volume);
      await _previewPlayer.play(AssetSource(alarmSoundAssetPath(_soundId)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play alarm sound')),
        );
      }
    }
  }

  Future<void> _previewChallenge() async {
    final user = ref.read(userProvider).valueOrNull;
    final previewAlarm = Alarm(
      id: 'preview',
      label: 'Preview',
      earliestWakeTime: DateTime.now(),
      latestWakeTime: DateTime.now(),
      repeatDays: const [1],
      challenges: _challenges,
      challengeDifficulty: _challengeDifficulty,
      challengeBarcodeValue: user?.preferences.registeredBarcode,
      challengeQrValue: user?.preferences.registeredQrCode,
    );

    await showModalBottomSheet<void>(
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
          children: [
            Text('Challenge preview', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ChallengeHost(
                challengeType: _challenges.first,
                alarm: previewAlarm,
                onComplete: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final user = await ref.read(userRepositoryProvider).getCurrentUser();
    final isPremium = user?.isPremium ?? false;
    final maxWindow = isPremium
        ? AppConstants.premiumMaxWakeWindowMinutes
        : AppConstants.freeMaxWakeWindowMinutes;

    if (_smartWake && _windowMinutes > maxWindow) {
      if (!mounted) return;
      if (!isPremium) {
        context.push('/premium');
        return;
      }
    }

    final now = DateTime.now();
    final earliest = DateTime(
      now.year, now.month, now.day,
      _earliest.hour, _earliest.minute,
    );
    final latest = DateTime(
      now.year, now.month, now.day,
      _latest.hour, _latest.minute,
    );

    final alarm = Alarm(
      id: widget.alarmId ?? const Uuid().v4(),
      label: _labelController.text,
      earliestWakeTime: earliest,
      latestWakeTime: latest,
      repeatDays: _repeatDays,
      isSmartWake: _smartWake,
      vibrationEnabled: _vibration,
      snoozeEnabled: _snooze,
      skipHolidays: _skipHolidays,
      snoozeMinutes: _snoozeMinutes,
      volume: _volume,
      fadeInSeconds: _fadeIn,
      soundId: _soundId,
      iconName: _iconName,
      challengeMode: _challengeMode,
      challengeDifficulty: _challengeDifficulty,
      challenges: _challenges,
      challengeBarcodeValue: user?.preferences.registeredBarcode,
      challengeQrValue: user?.preferences.registeredQrCode,
      createdAt: now,
    );

    await ref.read(alarmRepositoryProvider).saveAlarm(alarm);
    await ref.read(alarmEngineProvider).scheduleAlarm(alarm);
    ref.read(analyticsProvider).alarmCreated(
          isSmartWake: _smartWake,
          windowMinutes: _windowMinutes,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userAsync = ref.watch(userProvider);
    final isPremium = userAsync.maybeWhen(
      data: (u) => u?.isPremium ?? false,
      orElse: () => false,
    );
    final maxWindow = isPremium
        ? AppConstants.premiumMaxWakeWindowMinutes
        : AppConstants.freeMaxWakeWindowMinutes;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmId == null ? 'New Alarm' : 'Edit Alarm'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_smartWake && _windowMinutes > maxWindow && !isPremium)
            Card(
              color: AppColors.premium.withValues(alpha: 0.12),
              child: ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppColors.premium),
                title: const Text('Extend your Smart Wake window'),
                subtitle: Text(
                  'Free: $maxWindow min. Premium: up to '
                  '${AppConstants.premiumMaxWakeWindowMinutes} min.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/premium'),
              ),
            ),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          const SizedBox(height: 16),
          Text('Icon', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _IconChoice('work', Icons.work_outline, _iconName, (v) => setState(() => _iconName = v)),
              _IconChoice('gym', Icons.fitness_center, _iconName, (v) => setState(() => _iconName = v)),
              _IconChoice('flight', Icons.flight, _iconName, (v) => setState(() => _iconName = v)),
              _IconChoice('school', Icons.school_outlined, _iconName, (v) => setState(() => _iconName = v)),
            ],
          ),
          const SizedBox(height: 24),
          _TimePickerTile(
            label: 'Earliest Wake',
            time: _earliest,
            onChanged: (t) => setState(() => _earliest = t),
          ),
          _TimePickerTile(
            label: 'Latest Wake',
            time: _latest,
            onChanged: (t) => setState(() => _latest = t),
          ),
          if (_smartWake)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Smart Wake window: $_windowMinutes minutes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Smart Wake'),
            subtitle: const Text('Wake during light sleep within window'),
            value: _smartWake,
            onChanged: (v) => setState(() => _smartWake = v),
          ),
          SwitchListTile(
            title: const Text('Skip holidays'),
            subtitle: const Text('Do not ring on US federal holidays'),
            value: _skipHolidays,
            onChanged: (v) => setState(() => _skipHolidays = v),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: _vibration,
            onChanged: (v) => setState(() => _vibration = v),
          ),
          SwitchListTile(
            title: const Text('Snooze'),
            value: _snooze,
            onChanged: (v) => setState(() => _snooze = v),
          ),
          ListTile(
            title: const Text('Alarm sound'),
            subtitle: DropdownButton<String>(
              value: _soundId,
              isExpanded: true,
              items: AppConstants.freeAlarmSounds
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (v) => setState(() => _soundId = v ?? _soundId),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: _previewSound,
            ),
          ),
          ListTile(
            title: const Text('Volume'),
            subtitle: Slider(
              value: _volume,
              onChanged: (v) => setState(() => _volume = v),
            ),
          ),
          ListTile(
            title: const Text('Fade-in (seconds)'),
            subtitle: Slider(
              value: _fadeIn.toDouble(),
              min: 0,
              max: 60,
              divisions: 12,
              label: '$_fadeIn s',
              onChanged: (v) => setState(() => _fadeIn = v.round()),
            ),
          ),
          const Divider(height: 32),
          Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _RepeatDayPicker(
            selected: _repeatDays,
            onChanged: (d) => setState(() => _repeatDays = d),
          ),
          const Divider(height: 32),
          Row(
            children: [
              Text('Wake-up Challenge', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (!isPremium) const PremiumBadge(),
            ],
          ),
          const SizedBox(height: 8),
          ...ChallengeType.values.map((type) {
            final isFree = type.isFree;
            final isSelected = _challenges.contains(type);
            return CheckboxListTile(
              title: Text(type.displayName),
              value: isSelected,
              secondary: !isFree && !isPremium
                  ? const Icon(Icons.lock, size: 18, color: AppColors.premium)
                  : null,
              onChanged: (v) async {
                if (!isFree && !isPremium) {
                  context.push('/premium');
                  return;
                }
                setState(() {
                  if (v == true) {
                    _challenges = [..._challenges, type];
                  } else {
                    _challenges = _challenges.where((c) => c != type).toList();
                    if (_challenges.isEmpty) {
                      _challenges = [ChallengeType.mathProblem];
                    }
                  }
                });
              },
            );
          }),
          ListTile(
            title: const Text('Challenge difficulty'),
            trailing: DropdownButton<ChallengeDifficulty>(
              value: _challengeDifficulty,
              items: ChallengeDifficulty.values
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                  .toList(),
              onChanged: (v) => setState(() => _challengeDifficulty = v ?? _challengeDifficulty),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _previewChallenge,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview challenge'),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ChallengeMode>(
            segments: ChallengeMode.values
                .map((m) => ButtonSegment(value: m, label: Text(m.displayName)))
                .toList(),
            selected: {_challengeMode},
            onSelectionChanged: (s) {
              final mode = s.first;
              if (mode != ChallengeMode.single && !isPremium) {
                context.push('/premium');
                return;
              }
              setState(() => _challengeMode = mode);
            },
          ),
          if (isPremium) ...[
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendar-aware wake'),
              subtitle: const Text('Wake 90 min before first meeting (Premium)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final suggested = await ref
                    .read(calendarAlarmProvider)
                    .suggestedWakeBeforeEvent();
                if (suggested != null && mounted) {
                  setState(() {
                    _earliest = TimeOfDay.fromDateTime(suggested);
                    _latest = TimeOfDay.fromDateTime(
                      suggested.add(const Duration(minutes: 15)),
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Suggested wake: ${TimeOfDay.fromDateTime(suggested).format(context)}',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice(this.id, this.icon, this.selected, this.onSelect);

  final String id;
  final IconData icon;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == id;
    return ChoiceChip(
      selected: isSelected,
      label: Icon(icon),
      onSelected: (_) => onSelect(id),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(context: context, initialTime: time);
          if (picked != null) onChanged(picked);
        },
        child: Text(time.format(context), style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _RepeatDayPicker extends StatelessWidget {
  const _RepeatDayPicker({required this.selected, required this.onChanged});

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selected);
            if (isSelected) {
              updated.remove(day);
            } else {
              updated.add(day);
            }
            onChanged(updated..sort());
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: isSelected
                ? AppColors.primary
                : AppColors.darkCard,
            child: Text(
              labels[i],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }
}
