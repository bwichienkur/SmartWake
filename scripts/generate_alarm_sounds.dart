import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates alarm WAV files. Run: dart run scripts/generate_alarm_sounds.dart
void main() {
  const sampleRate = 44100;
  final outDir = Directory('assets/sounds');
  outDir.createSync(recursive: true);

  final sounds = <String, List<double> Function()>{
    'gentle_chime': _gentleChime,
    'morning_birds': _morningBirds,
    'soft_piano': _softPiano,
    'ocean_waves': _oceanWaves,
    'sunrise': _sunrise,
  };

  for (final entry in sounds.entries) {
    final path = File('${outDir.path}/${entry.key}.wav');
    _writeWav(path, entry.value(), sampleRate);
    stdout.writeln('Wrote ${path.path}');
  }
}

void _writeWav(File path, List<double> samples, int sampleRate) {
  final data = BytesBuilder();
  for (final sample in samples) {
    final clamped = sample.clamp(-1.0, 1.0);
    final int16 = (clamped * 32767).round().clamp(-32768, 32767);
    data.addByte(int16 & 0xFF);
    data.addByte((int16 >> 8) & 0xFF);
  }
  final pcm = data.toBytes();
  final header = _wavHeader(pcm.length, sampleRate);
  path.writeAsBytesSync([...header, ...pcm]);
}

List<int> _wavHeader(int dataLength, int sampleRate) {
  final byteRate = sampleRate * 2;
  final blockAlign = 2;
  final chunkSize = 36 + dataLength;
  final buffer = BytesBuilder();
  void writeString(String s) => buffer.add(s.codeUnits);
  void writeInt32(int v) => buffer.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  void writeInt16(int v) => buffer.add([v & 0xFF, (v >> 8) & 0xFF]);

  writeString('RIFF');
  writeInt32(chunkSize);
  writeString('WAVE');
  writeString('fmt ');
  writeInt32(16);
  writeInt16(1);
  writeInt16(1);
  writeInt32(sampleRate);
  writeInt32(byteRate);
  writeInt16(blockAlign);
  writeInt16(16);
  writeString('data');
  writeInt32(dataLength);
  return buffer.toBytes();
}

List<double> _sine(double freq, double duration, {double volume = 0.35, int sampleRate = 44100}) {
  final total = (sampleRate * duration).round();
  return List.generate(total, (i) => volume * sin(2 * pi * freq * i / sampleRate));
}

List<double> _envelope(List<double> samples, {double attack = 0.02, double release = 0.15, int sampleRate = 44100}) {
  final out = List<double>.from(samples);
  final attackSamples = (sampleRate * attack).round();
  final releaseSamples = (sampleRate * release).round();
  for (var i = 0; i < min(attackSamples, out.length); i++) {
    out[i] *= i / max(1, attackSamples);
  }
  for (var i = 0; i < min(releaseSamples, out.length); i++) {
    final idx = out.length - 1 - i;
    out[idx] *= i / max(1, releaseSamples);
  }
  return out;
}

List<double> _silence(double duration, {int sampleRate = 44100}) =>
    List.filled((sampleRate * duration).round(), 0.0);

List<double> _gentleChime() {
  final audio = <double>[];
  for (final freq in [523.25, 659.25, 783.99]) {
    audio.addAll(_envelope(_sine(freq, 0.55, volume: 0.28)));
    audio.addAll(_silence(0.08));
  }
  return audio;
}

List<double> _morningBirds() {
  final audio = <double>[];
  const pattern = [(880.0, 0.12), (1175.0, 0.1), (988.0, 0.14), (1319.0, 0.11)];
  for (var r = 0; r < 6; r++) {
    for (final (freq, duration) in pattern) {
      audio.addAll(_envelope(_sine(freq, duration, volume: 0.22)));
      audio.addAll(_silence(0.05));
    }
    audio.addAll(_silence(0.2));
  }
  return audio;
}

List<double> _softPiano() {
  final audio = <double>[];
  for (final freq in [261.63, 329.63, 392.0, 523.25]) {
    final tone = _sine(freq, 0.45, volume: 0.24);
    final harmonic = _sine(freq * 2, 0.45, volume: 0.08);
    final mixed = List<double>.generate(tone.length, (i) => tone[i] + harmonic[i]);
    audio.addAll(_envelope(mixed));
    audio.addAll(_silence(0.06));
  }
  return audio;
}

List<double> _oceanWaves() {
  const duration = 4.0;
  const sampleRate = 44100;
  final total = (sampleRate * duration).round();
  return _envelope(List.generate(total, (i) {
    final t = i / sampleRate;
    final low = sin(2 * pi * 0.25 * t);
    final mid = sin(2 * pi * 0.6 * t + sin(t));
    final noise = sin(2 * pi * (3 + (i % 17) / 17) * t) * 0.08;
    return 0.18 * low + 0.12 * mid + noise;
  }), attack: 0.4, release: 0.4);
}

List<double> _sunrise() {
  const duration = 3.5;
  const sampleRate = 44100;
  final total = (sampleRate * duration).round();
  return _envelope(List.generate(total, (i) {
    final t = i / sampleRate;
    final progress = t / duration;
    final freq = 220 + progress * 440;
    return 0.3 * sin(2 * pi * freq * t);
  }), attack: 0.5, release: 0.25);
}
