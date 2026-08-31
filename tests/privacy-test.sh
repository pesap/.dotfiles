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

try:
    tracked_paths = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "-z"],
        stderr=subprocess.DEVNULL,
        text=False,
    ).split(b"\0")
    paths = [root / raw_path.decode() for raw_path in tracked_paths if raw_path]
except subprocess.CalledProcessError:
    # Release archives and disposable local-source copies do not contain Git
    # metadata. In those trees every file outside the private package is part
    # of the public input and must still be checked.
    paths = [
        path
        for path in root.rglob("*")
        if path.is_file()
        and ".git" not in path.relative_to(root).parts
        and "personal" not in path.relative_to(root).parts
    ]

violations: list[tuple[str, str]] = []
for path in paths:
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
