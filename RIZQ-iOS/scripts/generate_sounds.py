#!/usr/bin/env python3
"""Generate the two placeholder sound files used for habit completion feedback.

Outputs to RIZQ/Resources/Sounds/:
  - bead_tap.wav        (tasbih-bead click, ~40 ms)
  - completion_chime.wav (soft warm bell, ~650 ms)

After running, convert to .caf with afconvert (see Makefile target / the
companion shell snippet at the bottom of this file).

These are placeholders — replace the .caf files with curated CC0 recordings
when available. Re-running this script overwrites them.
"""

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
OUT_DIR = Path(__file__).resolve().parent.parent / "RIZQ" / "Resources" / "Sounds"


def _write_wav(path: Path, samples: list[float]) -> None:
    """Write a mono 16-bit PCM WAV file. Samples are floats in [-1, 1]."""
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(abs(s) for s in samples) or 1.0
    norm = 0.85 / peak  # leave ~1.4 dB headroom
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * norm)) * 32767)) for s in samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(frames)


def bead_tap() -> list[float]:
    """A short wooden tasbih bead click.

    Construction:
      - Noise burst with very fast decay (the "attack" / impact transient)
      - 620 Hz resonant body (the "wood")
      - 1800 Hz secondary partial for the bright edge
    """
    duration_s = 0.045
    n = int(SAMPLE_RATE * duration_s)
    out = [0.0] * n
    random.seed(7)

    body_freq = 620.0
    edge_freq = 1800.0
    body_tau = 0.010    # 10 ms body decay
    edge_tau = 0.004    # 4 ms edge decay
    noise_tau = 0.003   # 3 ms noise decay (very impact-like)

    for i in range(n):
        t = i / SAMPLE_RATE
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t / noise_tau)
        body = math.sin(2 * math.pi * body_freq * t) * math.exp(-t / body_tau)
        edge = math.sin(2 * math.pi * edge_freq * t) * math.exp(-t / edge_tau) * 0.35
        out[i] = 0.55 * body + 0.30 * noise + 0.15 * edge

    # Soft attack (1 ms linear ramp) prevents a click on playback start
    ramp_samples = int(SAMPLE_RATE * 0.001)
    for i in range(ramp_samples):
        out[i] *= i / ramp_samples
    return out


def completion_chime() -> list[float]:
    """A soft warm bell-like chime — single tone with bell partials.

    Bell partials follow inharmonic ratios approximating a real cast bell:
      hum (0.5), prime (1.0), tierce-minor-third (1.2), quint (1.5),
      nominal (2.0), and a faint deciem (2.5).
    Each partial has its own decay time, with higher partials decaying
    faster (mimicking energy loss in a metal bell).
    """
    duration_s = 0.85
    n = int(SAMPLE_RATE * duration_s)
    out = [0.0] * n

    fundamental = 528.0  # C5-ish, warm

    # (ratio_to_fundamental, amplitude, decay_tau_seconds)
    partials = [
        (0.5, 0.25, 0.60),  # hum tone
        (1.0, 0.50, 0.55),  # prime
        (1.2, 0.20, 0.40),  # minor-third tierce (gives bell character)
        (1.5, 0.30, 0.45),  # quint (perfect fifth)
        (2.0, 0.18, 0.30),  # nominal
        (2.504, 0.08, 0.22),
    ]

    for i in range(n):
        t = i / SAMPLE_RATE
        sample = 0.0
        for ratio, amp, tau in partials:
            sample += amp * math.sin(2 * math.pi * fundamental * ratio * t) * math.exp(-t / tau)
        out[i] = sample

    # 5 ms attack ramp for a soft strike
    ramp_samples = int(SAMPLE_RATE * 0.005)
    for i in range(ramp_samples):
        out[i] *= i / ramp_samples
    return out


def main() -> None:
    bead_path = OUT_DIR / "bead_tap.wav"
    chime_path = OUT_DIR / "completion_chime.wav"
    _write_wav(bead_path, bead_tap())
    _write_wav(chime_path, completion_chime())
    print(f"wrote {bead_path}")
    print(f"wrote {chime_path}")
    print()
    print("Next: convert to .caf with afconvert:")
    print(f"  afconvert -f caff -d LEI16@44100 {bead_path} {bead_path.with_suffix('.caf')}")
    print(f"  afconvert -f caff -d LEI16@44100 {chime_path} {chime_path.with_suffix('.caf')}")


if __name__ == "__main__":
    main()
