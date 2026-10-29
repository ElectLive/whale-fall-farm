#!/usr/bin/env python3
"""Procedural chiptune music and sound effects for Whale Fall Farm.

Everything is synthesised from scratch with numpy: square/triangle/noise
voices, ADSR envelopes, simple filtering and delay. Output is 16-bit mono WAV
at 22050 Hz, which Godot imports natively.

    python tools/gen_audio.py
"""
from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "generated" / "audio"
SR = 22050

NOTE_BASE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5,
             "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name: str) -> int:
    letter = name[:-1]
    octave = int(name[-1])
    return 12 * (octave + 1) + NOTE_BASE[letter]


def freq(name_or_midi) -> float:
    m = midi(name_or_midi) if isinstance(name_or_midi, str) else name_or_midi
    return 440.0 * 2 ** ((m - 69) / 12)


def env(n: int, attack=0.01, decay=0.05, sustain=0.7, release=0.08, sr=SR) -> np.ndarray:
    a = max(1, int(attack * sr))
    d = max(1, int(decay * sr))
    r = max(1, int(release * sr))
    if a + d + r > n:
        a, d, r = max(1, n // 6), max(1, n // 6), max(1, n // 6)
    s = max(0, n - a - d - r)
    e = np.concatenate([
        np.linspace(0, 1, a, endpoint=False),
        np.linspace(1, sustain, d, endpoint=False),
        np.full(s, sustain),
        np.linspace(sustain, 0, r),
    ])
    return e[:n]


def square(f, dur, duty=0.5, vol=0.2, detune=0.0, sr=SR) -> np.ndarray:
    t = np.arange(int(dur * sr)) / sr
    f = f * (1 + detune)
    phase = (t * f) % 1.0
    wave_ = np.where(phase < duty, 1.0, -1.0)
    return wave_ * vol


def triangle(f, dur, vol=0.2, sr=SR) -> np.ndarray:
    t = np.arange(int(dur * sr)) / sr
    phase = (t * f) % 1.0
    wave_ = 2 * np.abs(2 * phase - 1) - 1
    return wave_ * vol


def sine(f, dur, vol=0.2, sr=SR) -> np.ndarray:
    t = np.arange(int(dur * sr)) / sr
    return np.sin(2 * np.pi * f * t) * vol


def noise(dur, vol=0.2, lowpass=0.2, sr=SR, seed=1) -> np.ndarray:
    rng = np.random.default_rng(seed)
    x = rng.uniform(-1, 1, int(dur * sr))
    # one-pole lowpass; lowpass in (0,1], 1 = wide open
    a = 0.02 + 0.98 * lowpass
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += a * (v - acc)
        y[i] = acc
    return y * vol * 2.5


def place(buf: np.ndarray, start: float, sig: np.ndarray, gain=1.0) -> None:
    i = int(start * SR)
    if i >= len(buf):
        return
    n = min(len(sig), len(buf) - i)
    buf[i:i + n] += sig[:n] * gain


def normalize(x: np.ndarray, peak=0.82) -> np.ndarray:
    m = float(np.max(np.abs(x))) if len(x) else 0.0
    if m > 0:
        x = x * (peak / m)
    return x


def save_wav(name: str, data: np.ndarray, peak=0.82, fade_out=0.0) -> None:
    data = normalize(data, peak)
    if fade_out > 0:
        n = min(int(fade_out * SR), len(data))
        data[-n:] *= np.linspace(1, 0, n)
    pcm = np.clip(data, -1, 1)
    pcm = (pcm * 32767).astype("<i2")
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"  {name}: {len(data)/SR:.1f}s")


CHORDS = {
    "C": ["C4", "E4", "G4"], "G": ["G3", "B3", "D4"], "Am": ["A3", "C4", "E4"],
    "F": ["F3", "A3", "C4"], "Dm": ["D4", "F4", "A4"], "Em": ["E4", "G4", "B4"],
    "Cmaj7": ["C4", "E4", "G4", "B4"], "Fmaj7": ["F3", "A3", "C4", "E4"],
    "Am7": ["A3", "C4", "E4", "G4"], "G7": ["G3", "B3", "D4", "F4"],
    "D": ["D4", "F#4", "A4"], "E": ["E4", "G#4", "B4"],
}
ROOT_NOTE = {"C": "C2", "G": "G2", "Am": "A2", "F": "F2", "Dm": "D2", "Em": "E2",
             "Cmaj7": "C2", "Fmaj7": "F2", "Am7": "A2", "G7": "G2", "D": "D2", "E": "E2"}


def make_music(name: str, bpm: int, chords: list[str], melody_seed: int, style: str,
               bars_per_chord=1, peak=0.8) -> None:
    beats_per_bar = 4
    beat = 60.0 / bpm
    total_beats = len(chords) * beats_per_bar * bars_per_chord
    total = total_beats * beat + 0.5
    buf = np.zeros(int(total * SR) + 1)

    rng = np.random.default_rng(melody_seed)
    # pad / bass
    for ci, ch in enumerate(chords):
        start = ci * beats_per_bar * bars_per_chord * beat
        dur = beats_per_bar * bars_per_chord * beat - 0.02
        if style == "day":
            bass = triangle(freq(ROOT_NOTE[ch]), dur, 0.20)
            pad = square(freq(CHORDS[ch][0]), dur, 0.12, 0.035, detune=0.001)
        elif style == "night":
            bass = sine(freq(ROOT_NOTE[ch]), dur, 0.26)
            pad = triangle(freq(CHORDS[ch][1]) / 2, dur, 0.05)
        else:
            bass = sine(freq(ROOT_NOTE[ch]), dur, 0.18)
            pad = triangle(freq(CHORDS[ch][1]), dur, 0.045)
        place(buf, start, bass * env(len(bass), 0.02, 0.1, 0.8, 0.25))
        place(buf, start, pad * env(len(pad), 0.3, 0.2, 0.6, 0.5))

    # chord arpeggio
    arp_step = beat / 2
    for ci, ch in enumerate(chords):
        tones = CHORDS[ch]
        for k in range(beats_per_bar * bars_per_chord * 2):
            t = ci * beats_per_bar * bars_per_chord * beat + k * arp_step
            note = tones[k % len(tones)]
            sig = square(freq(note) * 2, arp_step * 0.9, 0.25, 0.045 if style != "night" else 0.03)
            place(buf, t, sig * env(len(sig), 0.005, 0.04, 0.25, 0.05))

    # melody
    scale = ["C5", "D5", "E5", "G5", "A5", "C6"] if style == "day" else ["A4", "C5", "D5", "E5", "G5", "A5"]
    for ci, ch in enumerate(chords):
        base_t = ci * beats_per_bar * bars_per_chord * beat
        n_notes = beats_per_bar * bars_per_chord * (2 if style == "day" else 1)
        step = (beats_per_bar * bars_per_chord * beat) / n_notes
        idx = rng.integers(0, len(scale))
        for k in range(n_notes):
            if style == "day" and rng.random() < 0.18:
                continue
            if style == "night" and rng.random() < 0.35:
                continue
            idx = min(max(0, idx + int(rng.integers(-1, 2))), len(scale) - 1)
            note = scale[idx]
            dur = step * (0.55 if style == "day" else 0.9)
            if style == "day":
                sig = square(freq(note), dur, 0.5, 0.085)
            elif style == "night":
                sig = triangle(freq(note), dur, 0.09)
            else:
                sig = sine(freq(note), dur, 0.10)
            place(buf, base_t + k * step, sig * env(len(sig), 0.01, 0.06, 0.45, 0.12))

    # drums
    if style in ("day", "night"):
        for b in range(total_beats):
            t = b * beat
            if b % 4 == 0 or b % 4 == 1:
                kick = sine(60, 0.12, 0.5) * np.exp(-np.linspace(0, 8, int(0.12 * SR)))
                place(buf, t, kick)
            if b % 4 == 2:
                snare = noise(0.09, 0.14, 0.7, seed=b + 3) * env(int(0.09 * SR), 0.001, 0.02, 0.1, 0.05)
                place(buf, t, snare)
            # hats
            hat = noise(0.03, 0.05, 0.9, seed=b + 11) * np.exp(-np.linspace(0, 6, int(0.03 * SR)))
            place(buf, t + beat / 2, hat)
            if style == "night" and b % 2 == 1:
                place(buf, t, noise(0.5, 0.02, 0.15, seed=b + 21))

    # gentle delay
    d = int(beat * 0.75 * SR)
    echo = np.zeros_like(buf)
    echo[d:] = buf[:-d] * 0.18
    buf = buf + echo
    save_wav(name, buf, peak)


def sfx(name: str, fn) -> None:
    sig = fn()
    save_wav(name, sig, 0.7)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    print("music")
    make_music("day_theme.wav", 112, ["C", "G", "Am", "F", "C", "G", "F", "G"], 11, "day", peak=0.7)
    make_music("night_theme.wav", 92, ["Am", "F", "C", "G", "Am", "Dm", "F", "G7"], 23, "night", peak=0.62)
    make_music("title_theme.wav", 76, ["Cmaj7", "Am7", "Fmaj7", "G7"], 7, "title", peak=0.52)
    make_music("boss_theme.wav", 140, ["Em", "C", "G", "D", "Em", "C", "D", "Em"], 51, "night", peak=0.66)

    print("sfx")

    def hoe():
        b = np.zeros(int(0.22 * SR))
        thud = sine(90, 0.12, 0.6) * np.exp(-np.linspace(0, 10, int(0.12 * SR)))
        place(b, 0, thud)
        place(b, 0.01, noise(0.16, 0.25, 0.3, seed=1) * env(int(0.16 * SR), 0.001, 0.02, 0.2, 0.06))
        return b

    def plant():
        b = np.zeros(int(0.2 * SR))
        place(b, 0, square(freq("E5"), 0.07, 0.5, 0.3) * env(int(0.07 * SR), 0.002, 0.02, 0.3, 0.02))
        place(b, 0.06, square(freq("A5"), 0.1, 0.5, 0.28) * env(int(0.1 * SR), 0.002, 0.02, 0.3, 0.03))
        return b

    def water():
        b = np.zeros(int(0.5 * SR))
        for i in range(4):
            n = noise(0.5 - i * 0.08, 0.10, 0.5, seed=i + 2)
            place(b, i * 0.055, n * np.exp(-np.linspace(0, 4, len(n))))
        return b

    def harvest():
        b = np.zeros(int(0.4 * SR))
        for i, n in enumerate(["C5", "E5", "G5", "C6"]):
            sig = square(freq(n), 0.12, 0.5, 0.25)
            place(b, i * 0.06, sig * env(len(sig), 0.002, 0.03, 0.4, 0.05))
        return b

    def hit():
        b = np.zeros(int(0.18 * SR))
        place(b, 0, noise(0.12, 0.35, 0.8, seed=3) * env(int(0.12 * SR), 0.001, 0.01, 0.2, 0.04))
        place(b, 0, square(180, 0.09, 0.5, 0.2) * np.exp(-np.linspace(0, 12, int(0.09 * SR))))
        return b

    def hurt():
        b = np.zeros(int(0.32 * SR))
        for i, n in enumerate(["E4", "C4", "A3"]):
            sig = square(freq(n), 0.12, 0.5, 0.3)
            place(b, i * 0.07, sig * env(len(sig), 0.002, 0.02, 0.5, 0.05))
        return b

    def die():
        b = np.zeros(int(0.35 * SR))
        place(b, 0, noise(0.3, 0.3, 0.4, seed=5) * np.exp(-np.linspace(0, 6, int(0.3 * SR))))
        for i, n in enumerate(["G4", "E4", "C4"]):
            sig = triangle(freq(n), 0.1, 0.3)
            place(b, i * 0.05, sig * env(len(sig), 0.002, 0.02, 0.3, 0.04))
        return b

    def coin():
        b = np.zeros(int(0.22 * SR))
        for i, n in enumerate(["B5", "E6"]):
            sig = square(freq(n), 0.1, 0.25, 0.22)
            place(b, i * 0.06, sig * env(len(sig), 0.002, 0.02, 0.4, 0.04))
        return b

    def click():
        b = np.zeros(int(0.08 * SR))
        sig = square(freq("A5"), 0.05, 0.5, 0.2)
        place(b, 0, sig * env(len(sig), 0.001, 0.01, 0.2, 0.02))
        return b

    def dawn():
        b = np.zeros(int(1.2 * SR))
        for i, n in enumerate(["C4", "E4", "G4", "C5", "E5", "G5"]):
            sig = triangle(freq(n), 0.5, 0.16)
            place(b, i * 0.09, sig * env(len(sig), 0.01, 0.1, 0.4, 0.3))
        return b

    def horn():
        b = np.zeros(int(1.0 * SR))
        for n, off in (("A2", 0.0), ("E3", 0.0)):
            sig = square(freq(n), 0.9, 0.5, 0.18)
            place(b, off, sig * env(len(sig), 0.05, 0.2, 0.6, 0.4))
        return b

    def buy():
        b = np.zeros(int(0.3 * SR))
        for i, n in enumerate(["E5", "A5", "C6"]):
            sig = square(freq(n), 0.09, 0.25, 0.25)
            place(b, i * 0.05, sig * env(len(sig), 0.002, 0.02, 0.3, 0.03))
        return b

    def boss_roar():
        b = np.zeros(int(1.4 * SR))
        t = np.arange(int(1.4 * SR)) / SR
        growl = np.sin(2 * np.pi * (52 + 6 * np.sin(2 * np.pi * 3.0 * t)) * t) * 0.5
        growl *= env(len(growl), 0.08, 0.2, 0.7, 0.5)
        place(b, 0, growl)
        for i in range(5):
            place(b, 0.05 + i * 0.12, noise(0.3, 0.12, 0.25, seed=40 + i) *
                  env(int(0.3 * SR), 0.005, 0.05, 0.4, 0.15))
        return b

    def explosion():
        b = np.zeros(int(0.9 * SR))
        place(b, 0, noise(0.9, 0.4, 0.35, seed=71) * env(int(0.9 * SR), 0.002, 0.08, 0.3, 0.5))
        bass = sine(90, 0.7, 0.6) * np.exp(-np.linspace(0, 6, int(0.7 * SR)))
        place(b, 0, bass)
        return b

    def seed():
        b = np.zeros(int(0.16 * SR))
        sig = square(freq("A5") * 0.7, 0.06, 0.25, 0.22)
        place(b, 0, sig * env(len(sig), 0.002, 0.01, 0.3, 0.02))
        sig2 = square(freq("E5") * 0.7, 0.08, 0.25, 0.18)
        place(b, 0.05, sig2 * env(len(sig2), 0.002, 0.02, 0.3, 0.03))
        return b

    def victory_sting():
        b = np.zeros(int(4.8 * SR))
        for i, n in enumerate(["C4", "E4", "G4", "C5"]):
            sig = square(freq(n), 0.35, 0.25, 0.22)
            place(b, 0.0 + i * 0.12, sig * env(len(sig), 0.005, 0.05, 0.5, 0.2))
        for i, n in enumerate(["C4", "E4", "G4", "C5", "E5"]):
            sig = triangle(freq(n), 3.2, 0.12)
            place(b, 0.7, sig * env(len(sig), 0.05, 0.4, 0.5, 1.2))
        for i in range(6):
            sig = square(freq(["C5", "E5", "G5", "C6"][i % 4]), 0.25, 0.25, 0.12)
            place(b, 2.4 + i * 0.16, sig * env(len(sig), 0.003, 0.04, 0.35, 0.08))
        return b

    def gameover_sting():
        b = np.zeros(int(4.6 * SR))
        for i, n in enumerate(["A3", "G3", "F3", "E3"]):
            sig = triangle(freq(n), 1.4, 0.2)
            place(b, i * 0.55, sig * env(len(sig), 0.02, 0.2, 0.5, 0.5))
        for i, n in enumerate(["A2", "E3", "A3"]):
            sig = sine(freq(n), 3.5, 0.10)
            place(b, 2.0, sig * env(len(sig), 0.1, 0.5, 0.4, 1.5))
        return b

    sfx("hoe.wav", hoe)
    sfx("plant.wav", plant)
    sfx("water.wav", water)
    sfx("harvest.wav", harvest)
    sfx("hit.wav", hit)
    sfx("hurt.wav", hurt)
    sfx("die.wav", die)
    sfx("coin.wav", coin)
    sfx("click.wav", click)
    sfx("dawn.wav", dawn)
    sfx("horn.wav", horn)
    sfx("buy.wav", buy)
    sfx("boss_roar.wav", boss_roar)
    sfx("explosion.wav", explosion)
    sfx("seed.wav", seed)
    sfx("victory.wav", victory_sting)
    sfx("gameover.wav", gameover_sting)
    total = sum(p.stat().st_size for p in OUT.glob("*.wav"))
    print(f"audio -> {OUT} ({total/1048576:.1f} MB)")


if __name__ == "__main__":
    main()
