#!/usr/bin/env python3
import math
import struct
import wave
import random
from pathlib import Path

SAMPLE_RATE = 44100

def write_wav(path: Path, samples: list[float]):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'w') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        int_samples = []
        for s in samples:
            val = max(-1.0, min(1.0, s))
            int_samples.append(int(val * 32767.0))
        data = struct.pack(f'<{len(int_samples)}h', *int_samples)
        wav.writeframes(data)
    print(f"Generated {path.name} ({len(samples)/SAMPLE_RATE:.2f}s)")

def gen_chop():
    # Knife impact on wooden board: punchy low-mid thud + sharp transient + wood resonance
    duration = 0.18
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 35.0)
        # Low thud
        f1 = 120.0 * math.exp(-t * 20.0)
        thud = math.sin(2.0 * math.pi * f1 * t)
        # Sharp click/transient
        click = (random.random() * 2.0 - 1.0) * math.exp(-t * 120.0)
        # Wood resonance
        res = math.sin(2.0 * math.pi * 380.0 * t) * math.exp(-t * 40.0) * 0.4
        samples.append((thud * 0.7 + click * 0.6 + res * 0.3) * env)
    return samples

def gen_sizzle():
    # Sizzling frying pan: continuous filtered white noise with randomized crackles
    duration = 2.5
    n = int(SAMPLE_RATE * duration)
    samples = []
    last_noise = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        env = min(1.0, t * 10.0) * min(1.0, (duration - t) * 10.0)
        # High pass / band pass filtered noise
        noise = (random.random() * 2.0 - 1.0)
        # Simple IIR low-pass + high-pass combination
        filtered = 0.4 * noise + 0.6 * (noise - last_noise)
        last_noise = noise
        # Pop crackles
        crackle = 0.0
        if random.random() < 0.003:
            crackle = (random.random() * 2.0 - 1.0) * 0.9
        samples.append((filtered * 0.35 + crackle) * env)
    return samples

def gen_ding():
    # Service bell / order complete: bright crystalline chime (bell partials: 1.0, 2.76, 5.4, 8.9)
    duration = 1.6
    n = int(SAMPLE_RATE * duration)
    samples = []
    base_f = 1760.0 # A6 bell
    partials = [(1.0, 0.7, 4.0), (2.76, 0.4, 6.0), (5.4, 0.25, 9.0), (8.9, 0.15, 12.0)]
    for i in range(n):
        t = i / SAMPLE_RATE
        s = 0.0
        for ratio, amp, decay in partials:
            s += amp * math.sin(2.0 * math.pi * base_f * ratio * t) * math.exp(-t * decay)
        # initial attack strike
        strike = (random.random() * 2.0 - 1.0) * math.exp(-t * 200.0) * 0.3
        samples.append((s + strike) * 0.8)
    return samples

def gen_pickup():
    # Light upward whoosh-pop when picking up an ingredient
    duration = 0.12
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration)) ** 1.5
        f = 300.0 + (t / duration) * 450.0
        samples.append(math.sin(2.0 * math.pi * f * t) * env * 0.6)
    return samples

def gen_drop():
    # Gentle counter placement sound
    duration = 0.14
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 40.0)
        f = 220.0 * math.exp(-t * 15.0)
        click = (random.random() * 2.0 - 1.0) * math.exp(-t * 150.0) * 0.4
        samples.append((math.sin(2.0 * math.pi * f * t) * 0.6 + click) * env)
    return samples

def gen_trash():
    # Trash dump / disposal sound
    duration = 0.25
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 18.0)
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 25.0)
        thud = math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-t * 20.0)
        samples.append((noise * 0.5 + thud * 0.6) * env)
    return samples

def gen_burn():
    # Warning buzzer / smoke alarm beep
    duration = 0.5
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = 1.0 if (t % 0.12 < 0.08) else 0.0
        f = 880.0
        # Square wave for alarm tone
        sq = 1.0 if math.sin(2.0 * math.pi * f * t) > 0 else -1.0
        samples.append(sq * env * 0.4)
    return samples

def gen_click():
    # UI click
    duration = 0.05
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 100.0)
        f = 900.0
        samples.append(math.sin(2.0 * math.pi * f * t) * env * 0.5)
    return samples

def gen_hover():
    # Subtle UI hover tick
    duration = 0.03
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 160.0)
        f = 1400.0
        samples.append(math.sin(2.0 * math.pi * f * t) * env * 0.3)
    return samples

def gen_back():
    # UI back / cancel
    duration = 0.08
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 50.0)
        f = 500.0 - (t / duration) * 200.0
        samples.append(math.sin(2.0 * math.pi * f * t) * env * 0.4)
    return samples

def gen_victory():
    # Cheerful ascending fanfare (C5, E5, G5, C6)
    notes = [523.25, 659.25, 783.99, 1046.50]
    duration = 1.4
    n = int(SAMPLE_RATE * duration)
    samples = [0.0] * n
    for idx, f in enumerate(notes):
        start_t = idx * 0.18
        note_n = int(start_t * SAMPLE_RATE)
        for i in range(note_n, n):
            t = (i - note_n) / SAMPLE_RATE
            env = math.exp(-t * 4.5) * (1.0 if idx < 3 else math.exp(-t * 2.0))
            # Clarinet/flute like bell tone
            val = (math.sin(2.0 * math.pi * f * t) * 0.6 +
                   math.sin(4.0 * math.pi * f * t) * 0.25 +
                   math.sin(6.0 * math.pi * f * t) * 0.1) * env * 0.4
            samples[i] += val
    return samples

def gen_defeat():
    # Sad descending trombone/wah-wah (G4 -> F4 -> Eb4 -> D4)
    notes = [392.0, 349.23, 311.13, 293.66]
    duration = 1.5
    n = int(SAMPLE_RATE * duration)
    samples = [0.0] * n
    for idx, f in enumerate(notes):
        start_t = idx * 0.28
        note_n = int(start_t * SAMPLE_RATE)
        for i in range(note_n, n):
            t = (i - note_n) / SAMPLE_RATE
            env = math.exp(-t * 3.5)
            # Sawtooth-like brass buzz
            saw = (2.0 * ((f * t) % 1.0) - 1.0)
            samples[i] += saw * env * 0.25
    return samples

def gen_music_loop():
    # Upbeat, cheerful cooking game music loop (~8 bars at 128 BPM, ~15 seconds)
    # Marimba / Pizzicato melody, bouncy upright bass, kick and shaker
    bpm = 128.0
    beat_dur = 60.0 / bpm
    total_beats = 32
    duration = total_beats * beat_dur # ~15.0s
    n = int(SAMPLE_RATE * duration)
    samples = [0.0] * n

    # Melody notes in C major (C4, D4, E4, F4, G4, A4, B4, C5, etc.)
    scale = {
        'C3': 130.81, 'G3': 196.0, 'A3': 220.0, 'B3': 246.94,
        'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.0,
        'A4': 440.0, 'B4': 493.88, 'C5': 523.25, 'D5': 587.33, 'E5': 659.25,
        'F5': 698.46, 'G5': 783.99, 'A5': 880.0
    }

    # Bass line pattern (root-fifth bouncy groove)
    bass_chords = [
        ('C3', 'G3'), ('C3', 'G3'), ('F3' if 'F3' in scale else 'A3', 'C4'), ('G3', 'D4'),
        ('C3', 'G3'), ('A3', 'E4'), ('F4' if 'F4' in scale else 'D4', 'G3'), ('C3', 'G3')
    ]

    for bar in range(8):
        c1, c2 = bass_chords[bar % len(bass_chords)]
        f1 = scale.get(c1, 130.81)
        f2 = scale.get(c2, 196.0)
        # Beats in bar: 0, 1, 2, 3
        bar_start_beat = bar * 4
        for beat_idx, f_note in [(0, f1), (1, f2), (2, f1), (3, f2)]:
            start_t = (bar_start_beat + beat_idx) * beat_dur
            start_i = int(start_t * SAMPLE_RATE)
            for i in range(start_i, min(n, start_i + int(beat_dur * 0.9 * SAMPLE_RATE))):
                t = (i - start_i) / SAMPLE_RATE
                env = math.exp(-t * 9.0)
                val = math.sin(2.0 * math.pi * f_note * t) * env * 0.35
                samples[i] += val

    # Upbeat Marimba melody
    melody = [
        # Bar 1
        (0.0, 'E5', 0.5), (0.5, 'G5', 0.5), (1.0, 'C6' if 'C6' in scale else 'C5', 0.5), (1.5, 'E5', 0.5),
        (2.0, 'D5', 0.5), (2.5, 'C5', 0.5), (3.0, 'D5', 1.0),
        # Bar 2
        (4.0, 'E5', 0.5), (4.5, 'G5', 0.5), (5.0, 'A5', 0.5), (5.5, 'G5', 0.5),
        (6.0, 'E5', 0.5), (6.5, 'D5', 0.5), (7.0, 'C5', 1.0),
        # Bar 3
        (8.0, 'A4', 0.5), (8.5, 'C5', 0.5), (9.0, 'E5', 0.5), (9.5, 'G5', 0.5),
        (10.0, 'F5', 0.5), (10.5, 'E5', 0.5), (11.0, 'D5', 1.0),
        # Bar 4
        (12.0, 'G4', 0.5), (12.5, 'B4', 0.5), (13.0, 'D5', 0.5), (13.5, 'F5', 0.5),
        (14.0, 'E5', 0.5), (14.5, 'D5', 0.5), (15.0, 'C5', 1.0),
        # Bar 5-8 variations (repeat octave/accent)
        (16.0, 'E5', 0.5), (16.5, 'G5', 0.5), (17.0, 'C5', 0.5), (17.5, 'E5', 0.5),
        (18.0, 'D5', 0.5), (18.5, 'C5', 0.5), (19.0, 'D5', 1.0),
        (20.0, 'E5', 0.5), (20.5, 'G5', 0.5), (21.0, 'A5', 0.5), (21.5, 'C5', 0.5),
        (22.0, 'B4', 0.5), (22.5, 'A4', 0.5), (23.0, 'G4', 1.0),
        (24.0, 'A4', 0.5), (24.5, 'C5', 0.5), (25.0, 'E5', 0.5), (25.5, 'G5', 0.5),
        (26.0, 'A5', 0.5), (26.5, 'G5', 0.5), (27.0, 'E5', 0.5), (27.5, 'D5', 0.5),
        (28.0, 'C5', 1.0), (29.0, 'E5', 0.5), (29.5, 'G5', 0.5), (30.0, 'C5', 2.0)
    ]

    for beat_offset, note_name, dur_beats in melody:
        f = scale.get(note_name, 523.25)
        start_t = beat_offset * beat_dur
        start_i = int(start_t * SAMPLE_RATE)
        dur_s = dur_beats * beat_dur
        for i in range(start_i, min(n, start_i + int(dur_s * SAMPLE_RATE))):
            t = (i - start_i) / SAMPLE_RATE
            env = math.exp(-t * 6.5)
            # Marimba wood sound: fundamental + 4th harmonic
            marimba = (math.sin(2.0 * math.pi * f * t) * 0.7 +
                       math.sin(6.0 * math.pi * f * t) * 0.15 +
                       math.sin(8.0 * math.pi * f * t) * 0.08) * env * 0.32
            samples[i] += marimba

    # Shaker / hi-hat on every 8th note
    for beat_half in range(total_beats * 2):
        start_t = beat_half * (beat_dur / 2.0)
        start_i = int(start_t * SAMPLE_RATE)
        accent = 1.0 if beat_half % 2 == 1 else 0.5
        for i in range(start_i, min(n, start_i + int(0.04 * SAMPLE_RATE))):
            t = (i - start_i) / SAMPLE_RATE
            env = math.exp(-t * 120.0)
            noise = (random.random() * 2.0 - 1.0) * env * 0.12 * accent
            samples[i] += noise

    # Light woodblock percussion on beats 2 and 4
    for beat in range(total_beats):
        if beat % 4 in (1, 3):
            start_t = beat * beat_dur
            start_i = int(start_t * SAMPLE_RATE)
            for i in range(start_i, min(n, start_i + int(0.06 * SAMPLE_RATE))):
                t = (i - start_i) / SAMPLE_RATE
                env = math.exp(-t * 80.0)
                wb = math.sin(2.0 * math.pi * 950.0 * t) * env * 0.2
                samples[i] += wb

    # Loop smoothing (fade in/out 0.02s at ends)
    fade_len = int(SAMPLE_RATE * 0.02)
    for i in range(fade_len):
        frac = i / fade_len
        samples[i] *= frac
        samples[n - 1 - i] *= frac

    return samples

def main():
    out_dir = Path("/home/zerker24/TesseraProjects/BistroBlitz/src/Audio")
    out_dir.mkdir(parents=True, exist_ok=True)

    write_wav(out_dir / "chop.wav", gen_chop())
    write_wav(out_dir / "sizzle.wav", gen_sizzle())
    write_wav(out_dir / "ding.wav", gen_ding())
    write_wav(out_dir / "pickup.wav", gen_pickup())
    write_wav(out_dir / "drop.wav", gen_drop())
    write_wav(out_dir / "trash.wav", gen_trash())
    write_wav(out_dir / "burn.wav", gen_burn())
    write_wav(out_dir / "click.wav", gen_click())
    write_wav(out_dir / "hover.wav", gen_hover())
    write_wav(out_dir / "back.wav", gen_back())
    write_wav(out_dir / "victory.wav", gen_victory())
    write_wav(out_dir / "defeat.wav", gen_defeat())
    write_wav(out_dir / "music.wav", gen_music_loop())
    print("All audio files generated successfully!")

if __name__ == "__main__":
    main()
