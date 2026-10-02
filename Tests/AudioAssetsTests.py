"""Validate bundled WAVs and the prepared sip's actual waveform; standard library only."""
import json
import math
import wave
from pathlib import Path

assets = Path(__file__).resolve().parents[1] / "Assets"
levels = json.loads((assets / "AUDIO-LEVELS.json").read_text())
for sample in levels["samples"]:
    with wave.open(str(assets / sample["file"]), "rb") as wav:
        assert abs(wav.getnframes() / wav.getframerate() - sample["duration_seconds"]) < 0.00001
    target = sample.get("target_lufs", -20)
    assert abs(sample["balanced_lufs"] - target) < 0.15
    assert sample["true_peak_db"] < -2
assert abs(next(s["balanced_lufs"] for s in levels["samples"] if s["file"] == "latte-liquor.wav") - next(s["balanced_lufs"] for s in levels["samples"] if s["file"] == "latte-riser.wav") + 8) < 0.15

def pcm(name):
    with wave.open(str(assets / name), "rb") as wav:
        assert wav.getframerate() == 44100 and wav.getnchannels() == 2 and wav.getsampwidth() == 3
        data = wav.readframes(wav.getnframes())
    samples = []
    for offset in range(0, len(data), 3):
        value = data[offset] | data[offset + 1] << 8 | data[offset + 2] << 16
        samples.append(value - (1 << 24) if value & (1 << 23) else value)
    return samples

riser, liquor, nelly, mix = (pcm(name) for name in ["latte-riser.wav", "latte-liquor.wav", "coffee.wav", "latte-sip.wav"])
rate = 44100
# Match the visible sip and approving nod, independent of the saved filter recipe.
nelly_start = round(4.8 * rate)
riser_start = nelly_start - len(riser) // 2
assert len(mix) == 6 * rate * 2
assert levels["latte_mix"]["riser_start_frame"] == levels["latte_mix"]["liquor_start_frame"] == riser_start
assert levels["latte_mix"]["nelly_start_frame"] == nelly_start
assert not any(mix[:riser_start * 2])
gain = math.pow(10, levels["latte_mix"]["mix_gain_db"] / 20)
max_error = 0
for index, actual in enumerate(mix):
    expected = 0
    for clip, first in [(riser, riser_start), (liquor, riser_start), (nelly, nelly_start)]:
        source = index - first * 2
        if 0 <= source < len(clip):
            expected += clip[source]
    max_error = max(max_error, abs(actual - expected * gain))
# Allow integer quantization and float mixer rounding, but no missing/shifted layers.
assert max_error < 4, max_error
assert any(mix[riser_start * 2:nelly_start * 2])
assert any(mix[nelly_start * 2:round(5.55 * rate) * 2])
print(f"PASS: {len(levels['samples'])} bundled assets, balanced levels, quieter Liquor, simultaneous layers, Nelly at 4.8s, exact six-second sip (PCM error {max_error:.2f}).")
