"""Check the selected reactions' actual waveform and measured level."""
import array
import json
import math
import shutil
import subprocess
import wave
from pathlib import Path

assets = Path(__file__).resolve().parents[1] / "Assets"
report = json.loads((assets / "JERSEY-LEVELS.json").read_text())
assert {s["file"] for s in report["samples"]} == {
    "jersey-laugh.wav", "jersey-shy.wav", "jersey-attitude.wav", "jersey-pleased.wav"
}
for sample in report["samples"]:
    assert sample["source"].startswith("Drip ")
    path = assets / sample["file"]
    with wave.open(str(path), "rb") as wav:
        assert wav.getnchannels() == 2 and wav.getframerate() == 44100 and wav.getsampwidth() == 2
        assert abs(wav.getnframes() / wav.getframerate() - sample["duration_seconds"]) < 0.00001
        assert 0.1 < sample["duration_seconds"] < 0.6
        pcm = array.array("h", wav.readframes(wav.getnframes()))
    peak = max(abs(value) for value in pcm)
    assert 0 < peak < 32767
    assert 20 * math.log10(peak / 32768) < -3
    assert abs(sample["balanced_lufs"] - report["target_lufs"]) < 0.15 and sample["true_peak_db"] < -3
    if shutil.which("ffmpeg"):
        result = subprocess.run(["ffmpeg", "-hide_banner", "-stream_loop", "15", "-i", str(path),
            "-af", "loudnorm=I=-23:TP=-3:LRA=11:print_format=json", "-f", "null", "-"],
            capture_output=True, text=True, check=True)
        measured = json.JSONDecoder().raw_decode(result.stderr[result.stderr.rindex("{"):])[0]
        assert abs(float(measured["input_i"]) - report["target_lufs"]) < 0.15
        assert float(measured["input_tp"]) < -3
print("PASS: four short reactions, actual PCM has no clipping, matching -23 LUFS and safe true peaks")
