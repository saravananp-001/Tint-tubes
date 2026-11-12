"""Regenerates assets/audio/pour.wav. Run from the project root:

    python3 tool/generate_pour_sound.py

The sound is synthesised, so it has no licence attached: many tiny "bubble"
chirps whose pitch rises as the tube fills, over a soft hiss.
"""
import math
import random
import struct
import wave

SAMPLE_RATE = 44100
DURATION = 0.55  # seconds

random.seed(7)
n = int(SAMPLE_RATE * DURATION)
buf = [0.0] * n

for _ in range(46):
    start = random.uniform(0, DURATION - 0.08)
    length = random.uniform(0.018, 0.06)
    f0 = random.uniform(420, 1500) * (1 + 0.7 * start / DURATION)
    amp = random.uniform(0.25, 0.7)
    phase = 0.0
    s0 = int(start * SAMPLE_RATE)
    m = int(length * SAMPLE_RATE)
    for i in range(m):
        t = i / m
        phase += 2 * math.pi * f0 * (1 + 0.45 * t) / SAMPLE_RATE
        env = math.sin(math.pi * min(1, t * 6) / 2) * math.exp(-4.5 * t)
        buf[s0 + i] += amp * env * math.sin(phase)

# Band-limited noise for the stream itself.
lp = hp = prev = 0.0
for i in range(n):
    lp += 0.25 * (random.uniform(-1, 1) - lp)
    hp = 0.9 * (hp + lp - prev)
    prev = lp
    buf[i] += 0.10 * hp

peak = max(abs(x) for x in buf)
frames = bytearray()
for i, x in enumerate(buf):
    t = i / SAMPLE_RATE
    fade = min(1, t / 0.03) * min(1, (DURATION - t) / 0.14)
    frames += struct.pack('<h', int(0.8 * 32767 * fade * x / peak))

with wave.open('assets/audio/pour.wav', 'wb') as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(SAMPLE_RATE)
    f.writeframes(bytes(frames))
