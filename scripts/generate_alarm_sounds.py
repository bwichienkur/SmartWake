#!/usr/bin/env python3
"""Generate lightweight alarm sound WAV files for SmartWake."""

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def write_wav(path: Path, samples: list[float], sample_rate: int = SAMPLE_RATE) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = bytearray()
        for sample in samples:
            clamped = max(-1.0, min(1.0, sample))
            frames.extend(struct.pack("<h", int(clamped * 32767)))
        wf.writeframes(frames)


def sine_tone(freq: float, duration: float, volume: float = 0.35) -> list[float]:
    total = int(SAMPLE_RATE * duration)
    return [
        volume * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        for i in range(total)
    ]


def envelope(samples: list[float], attack: float = 0.02, release: float = 0.15) -> list[float]:
    attack_samples = int(SAMPLE_RATE * attack)
    release_samples = int(SAMPLE_RATE * release)
    out = samples[:]
    for i in range(min(attack_samples, len(out))):
        out[i] *= i / max(1, attack_samples)
    for i in range(min(release_samples, len(out))):
        idx = len(out) - 1 - i
        out[idx] *= i / max(1, release_samples)
    return out


def silence(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


def gentle_chime() -> list[float]:
    notes = [523.25, 659.25, 783.99]
    audio: list[float] = []
    for freq in notes:
        audio.extend(envelope(sine_tone(freq, 0.55, 0.28)))
        audio.extend(silence(0.08))
    return audio


def morning_birds() -> list[float]:
    audio: list[float] = []
    pattern = [(880, 0.12), (1175, 0.1), (988, 0.14), (1319, 0.11)]
    for _ in range(6):
        for freq, duration in pattern:
            chirp = envelope(sine_tone(freq, duration, 0.22))
            audio.extend(chirp)
            audio.extend(silence(0.05))
        audio.extend(silence(0.2))
    return audio


def soft_piano() -> list[float]:
    notes = [261.63, 329.63, 392.0, 523.25]
    audio: list[float] = []
    for freq in notes:
        tone = sine_tone(freq, 0.45, 0.24)
        harmonic = sine_tone(freq * 2, 0.45, 0.08)
        mixed = [a + b for a, b in zip(tone, harmonic)]
        audio.extend(envelope(mixed))
        audio.extend(silence(0.06))
    return audio


def ocean_waves() -> list[float]:
    duration = 4.0
    total = int(SAMPLE_RATE * duration)
    audio: list[float] = []
    for i in range(total):
        t = i / SAMPLE_RATE
        low = math.sin(2 * math.pi * 0.25 * t)
        mid = math.sin(2 * math.pi * 0.6 * t + math.sin(t))
        noise = math.sin(2 * math.pi * (3 + (i % 17) / 17) * t) * 0.08
        sample = 0.18 * low + 0.12 * mid + noise
        audio.append(sample)
    return envelope(audio, attack=0.4, release=0.4)


def sunrise() -> list[float]:
    duration = 3.5
    total = int(SAMPLE_RATE * duration)
    audio: list[float] = []
    for i in range(total):
        t = i / SAMPLE_RATE
        progress = t / duration
        freq = 220 + progress * 440
        sample = 0.3 * math.sin(2 * math.pi * freq * t)
        audio.append(sample)
    return envelope(audio, attack=0.5, release=0.25)


SOUNDS = {
    "gentle_chime": gentle_chime,
    "morning_birds": morning_birds,
    "soft_piano": soft_piano,
    "ocean_waves": ocean_waves,
    "sunrise": sunrise,
}


def main() -> None:
    for name, builder in SOUNDS.items():
        path = OUTPUT_DIR / f"{name}.wav"
        write_wav(path, builder())
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
