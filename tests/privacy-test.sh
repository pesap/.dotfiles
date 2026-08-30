#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

python3 - "$repo_root" <<'PY'
from pathlib import Path
import re
import subprocess
import sys

root = Path(sys.argv[1])
private_ipv4 = re.compile(
    r"(?<![0-9])(?:10\.(?:[0-9]{1,3}\.){2}[0-9]{1,3}|"
    r"172\.(?:1[6-9]|2[0-9]|3[0-1])\.(?:[0-9]{1,3}\.)[0-9]{1,3}|"
    r"192\.168\.(?:[0-9]{1,3}\.)[0-9]{1,3})(?![0-9])"
)

paths = subprocess.check_output(
    ["git", "-C", str(root), "ls-files", "-z"], text=False
).split(b"\0")
violations: list[tuple[str, str]] = []
for raw_path in paths:
    if not raw_path:
        continue
    path = root / raw_path.decode()
    if not path.is_file():
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    match = private_ipv4.search(text)
    if match:
        masked = ".".join(match.group().split(".")[:2] + ["x", "x"])
        violations.append((str(path.relative_to(root)), masked))

if violations:
    for path, masked in violations:
        print(f"private network address in public file: {path} ({masked})", file=sys.stderr)
    raise SystemExit(1)

print("privacy test passed")
PY
