"""Generate the small audio pack shipped with Project Bastion."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22_050
ROOT = Path(__file__).resolve().parents[2] / "assets" / "audio"
RNG = random.Random(71)


def midi(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def blank(seconds: float) -> list[float]:
    return [0.0] * round(seconds * SAMPLE_RATE)


def oscillator(phase: float, shape: str) -> float:
    if shape == "triangle":
        return 2.0 / math.pi * math.asin(math.sin(phase))
    if shape == "square":
        return 1.0 if math.sin(phase) >= 0.0 else -1.0
    return math.sin(phase)


def add_note(
    output: list[float],
    start: float,
    duration: float,
    frequency: float,
    volume: float,
    shape: str = "sine",
    attack: float = 0.008,
    release: float = 0.08,
) -> None:
    start_frame = round(start * SAMPLE_RATE)
    frame_count = min(round(duration * SAMPLE_RATE), len(output) - start_frame)
    for index in range(max(0, frame_count)):
        time = index / SAMPLE_RATE
        envelope = min(1.0, time / max(attack, 0.0001))
        envelope *= min(1.0, (duration - time) / max(release, 0.0001))
        output[start_frame + index] += oscillator(math.tau * frequency * time, shape) * volume * max(0.0, envelope)


def add_sweep(
    output: list[float],
    start_frequency: float,
    end_frequency: float,
    volume: float,
    noise: float = 0.0,
) -> None:
    phase = 0.0
    duration = len(output) / SAMPLE_RATE
    for index in range(len(output)):
        progress = index / max(1, len(output) - 1)
        frequency = start_frequency + (end_frequency - start_frequency) * progress
        phase += math.tau * frequency / SAMPLE_RATE
        envelope = (1.0 - progress) ** 2
        sample = math.sin(phase) * (1.0 - noise) + RNG.uniform(-1.0, 1.0) * noise
        output[index] += sample * volume * envelope * min(1.0, index / (SAMPLE_RATE * min(0.01, duration)))


def add_percussion(output: list[float], start: float, kind: str, volume: float) -> None:
    start_frame = round(start * SAMPLE_RATE)
    duration = 0.18 if kind == "kick" else 0.12
    frame_count = min(round(duration * SAMPLE_RATE), len(output) - start_frame)
    phase = 0.0
    for index in range(max(0, frame_count)):
        progress = index / max(1, frame_count - 1)
        if kind == "kick":
            frequency = 110.0 - 70.0 * progress
            phase += math.tau * frequency / SAMPLE_RATE
            sample = math.sin(phase)
        else:
            sample = RNG.uniform(-1.0, 1.0)
        output[start_frame + index] += sample * volume * (1.0 - progress) ** 3


def normalize(output: list[float], peak: float = 0.82) -> list[float]:
    loudest = max((abs(sample) for sample in output), default=1.0)
    scale = peak / max(loudest, 0.0001)
    return [max(-1.0, min(1.0, sample * scale)) for sample in output]


def write_wav(path: Path, output: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    samples = normalize(output)
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        target.writeframes(b"".join(struct.pack("<h", round(sample * 32_767)) for sample in samples))


def make_menu_music() -> list[float]:
    output = blank(12.0)
    chords = [(48, 51, 55), (46, 50, 53), (43, 48, 51), (46, 50, 55)]
    for bar, chord in enumerate(chords):
        start = bar * 3.0
        for note in chord:
            add_note(output, start, 2.9, midi(note), 0.12, "sine", 0.18, 0.3)
        for step in range(6):
            note = chord[step % len(chord)] + 12
            add_note(output, start + step * 0.5, 0.38, midi(note), 0.09, "triangle", 0.015, 0.12)
    return output


def make_build_music() -> list[float]:
    output = blank(12.0)
    chords = [(48, 55, 60), (53, 57, 60), (46, 53, 58), (43, 50, 55)]
    for bar, chord in enumerate(chords):
        start = bar * 3.0
        add_note(output, start, 2.85, midi(chord[0] - 12), 0.13, "triangle", 0.04, 0.2)
        for step in range(12):
            note = chord[(step * 2 + bar) % len(chord)] + 12
            add_note(output, start + step * 0.25, 0.18, midi(note), 0.11, "triangle", 0.006, 0.07)
        add_percussion(output, start, "kick", 0.13)
        add_percussion(output, start + 1.5, "snare", 0.055)
    return output


def make_defense_music() -> list[float]:
    output = blank(8.0)
    roots = [36, 36, 34, 31]
    for bar, root in enumerate(roots):
        start = bar * 2.0
        for beat in range(4):
            add_note(output, start + beat * 0.5, 0.38, midi(root), 0.2, "square", 0.005, 0.1)
            add_percussion(output, start + beat * 0.5, "kick", 0.22)
            if beat % 2 == 1:
                add_percussion(output, start + beat * 0.5, "snare", 0.12)
        pattern = [0, 7, 3, 10, 7, 12, 10, 7]
        for step, offset in enumerate(pattern):
            add_note(output, start + step * 0.25, 0.17, midi(root + 24 + offset), 0.12, "triangle", 0.004, 0.06)
    return output


def make_stinger(notes: list[int], descending: bool = False) -> list[float]:
    output = blank(2.4)
    for index, note in enumerate(notes):
        start = index * 0.28
        add_note(output, start, 0.55, midi(note), 0.3, "triangle", 0.008, 0.2)
        add_note(output, start, 0.75, midi(note - 12), 0.15, "sine", 0.012, 0.25)
    final_note = notes[-1]
    add_note(output, len(notes) * 0.28, 1.2, midi(final_note + (-12 if descending else 12)), 0.22, "sine", 0.03, 0.4)
    return output


def make_effect(duration: float, start: float, end: float, volume: float, noise: float = 0.0) -> list[float]:
    output = blank(duration)
    add_sweep(output, start, end, volume, noise)
    return output


def generate_music() -> None:
    write_wav(ROOT / "music" / "menu.wav", make_menu_music())
    write_wav(ROOT / "music" / "build.wav", make_build_music())
    write_wav(ROOT / "music" / "defense.wav", make_defense_music())
    write_wav(ROOT / "music" / "victory.wav", make_stinger([60, 64, 67, 72]))
    write_wav(ROOT / "music" / "defeat.wav", make_stinger([55, 51, 48, 43], True))


def generate_effects() -> None:
    effects = {
        "ui_click.wav": make_effect(0.10, 520.0, 760.0, 0.35),
        "place.wav": make_effect(0.20, 180.0, 330.0, 0.42, 0.12),
        "remove.wav": make_effect(0.18, 380.0, 150.0, 0.38, 0.08),
        "invalid.wav": make_effect(0.22, 170.0, 120.0, 0.42),
        "wave_start.wav": make_effect(0.52, 190.0, 680.0, 0.46, 0.05),
        "player_attack.wav": make_effect(0.16, 720.0, 260.0, 0.5, 0.1),
        "repair.wav": make_effect(0.14, 420.0, 620.0, 0.27, 0.08),
        "turret_fire.wav": make_effect(0.12, 980.0, 360.0, 0.48, 0.14),
        "hit.wav": make_effect(0.10, 260.0, 110.0, 0.5, 0.4),
        "raider_death.wav": make_effect(0.34, 330.0, 75.0, 0.48, 0.25),
        "structure_break.wav": make_effect(0.48, 210.0, 55.0, 0.55, 0.5),
        "core_hit.wav": make_effect(0.42, 130.0, 62.0, 0.58, 0.22),
    }
    for filename, output in effects.items():
        write_wav(ROOT / "sfx" / filename, output)


def main() -> None:
    generate_music()
    generate_effects()
    print(f"Generated audio in {ROOT}")


if __name__ == "__main__":
    main()
