"""A failed compiler or missing asset must preserve the previous working app."""
import hashlib
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
for failure in ["compiler", "asset"]:
    with tempfile.TemporaryDirectory(prefix="velvet-build-failure-") as directory:
        root = Path(directory)
        shutil.copy2(repo / "build.sh", root / "build.sh")
        shutil.copy2(repo / "Info.plist", root / "Info.plist")
        old = root / "build/Velvet.app/Contents/MacOS/Velvet"
        old.parent.mkdir(parents=True)
        old.write_bytes(b"previous working app stays here")
        digest = hashlib.sha256(old.read_bytes()).hexdigest()
        fake = root / "fake-bin"
        fake.mkdir()
        compiler = fake / "swiftc"
        if failure == "compiler":
            compiler.write_text("#!/bin/sh\nexit 42\n")
        else:
            compiler.write_text("#!/bin/sh\nwhile [ $# -gt 0 ]; do\n"
                "if [ \"$1\" = -o ]; then shift; printf fake > \"$1\"; exit 0; fi\nshift\ndone\nexit 1\n")
        compiler.chmod(0o755)
        env = os.environ.copy()
        env["PATH"] = str(fake) + os.pathsep + env["PATH"]
        result = subprocess.run(["zsh", "build.sh"], cwd=root, env=env, capture_output=True)
        assert result.returncode != 0, failure
        assert hashlib.sha256(old.read_bytes()).hexdigest() == digest, failure
        assert not list((root / "build").glob(".Velvet-build.*")), failure
print("PASS: compiler and missing-asset failures preserve the old executable and remove incomplete staging bundles")
