"""Regenerates assets/audio/complete.wav and assets/audio/win.wav. Run from
the project root:

    python3 tool/generate_jingles.py

Both are synthesised bell-like notes, so they have no licence attached.
"""
import math
import struct
import wave

SAMPLE_RATE = 44100


def render(notes, total):
    """notes: (start seconds, frequency Hz, length seconds)."""
    n = int(SAMPLE_RATE * total)
    buf = [0.0] * n
    for start, freq, length in notes:
        s0 = int(start * SAMPLE_RATE)
        for i in range(min(int(length * SAMPLE_RATE), n - s0)):
            t = i / SAMPLE_RATE
            env = min(1, t / 0.005) * math.exp(-5.5 * t / length)
            tone = (math.sin(2 * math.pi * freq * t)
                    + 0.35 * math.sin(2 * math.pi * 2 * freq * t)
                    + 0.12 * math.sin(2 * math.pi * 3 * freq * t))
            buf[s0 + i] += env * tone
    peak = max(abs(x) for x in buf)
    frames = bytearray()
    for i, x in enumerate(buf):
        fade = min(1, (n - i) / (0.05 * SAMPLE_RATE))
        frames += struct.pack('<h', int(0.7 * 32767 * fade * x / peak))
    return bytes(frames)


def write(name, notes, total):
    with wave.open(f'assets/audio/{name}', 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(render(notes, total))


# A tube was completed: two quick rising notes.
write('complete.wav', [(0.0, 880.0, 0.25), (0.09, 1318.5, 0.35)], 0.45)

# Level solved: rising C major arpeggio ending on a held chord.
write('win.wav', [
    (0.00, 523.25, 0.4), (0.12, 659.25, 0.4), (0.24, 783.99, 0.4),
    (0.36, 1046.5, 0.9), (0.36, 783.99, 0.9), (0.36, 659.25, 0.9),
], 1.3)
