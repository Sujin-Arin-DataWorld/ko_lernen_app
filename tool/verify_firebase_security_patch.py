#!/usr/bin/env python3
"""Reject builds predating the October 2026 eMudhra security fixes.

Source: https://firebase.google.com/support/guides/compromised-emudhra-intermediate-ca
Checks resolved dependencies and the running SDK, not only pubspec constraints.
"""

import argparse
import json
from pathlib import Path
import re
import subprocess


def version(value):
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:\+\d+)?", value):
        raise ValueError(f"Expected a stable release version, got {value!r}")
    return tuple(map(int, value.split("+", 1)[0].split(".")))


def verify(root, runtime, *, ios_lock=False):
    errors = []
    for key, minimum in (("frameworkVersion", "3.47.8"), ("dartSdkVersion", "3.13.7")):
        if version(runtime[key]) < version(minimum):
            errors.append(f"{key} {runtime[key]} is below {minimum}")
    lock = (root / "pubspec.lock").read_text(encoding="utf-8")
    # Keep the supported backport line; the next major's initial release is affected.
    for name, floor, next_floor in (
        ("cloud_firestore", "6.10.2", "7.1.0"),
        ("firebase_core", "4.15.2", "5.1.0"),
        ("firebase_auth", "6.7.1", "7.0.1"),
        ("firebase_analytics", "12.6.1", "13.0.1"),
        ("firebase_app_check", "0.4.9", "0.5.1"),
    ):
        match = re.search(rf"^  {name}:\n(?:(?:    .*|)\n)*?    version: \"([^\"]+)\"", lock, re.M)
        if not match:
            errors.append(f"Missing resolved package: {name}")
            continue
        current = version(match[1])
        lower, upper = version(floor), version(next_floor)
        # App Check is still 0.x: its compatibility boundary is the minor version.
        boundary = (lower[0], lower[1] + 1, 0) if name == "firebase_app_check" else (lower[0] + 1, 0, 0)
        if not (lower <= current < boundary or current >= upper):
            errors.append(f"{name} {match[1]} is outside the patched release ranges")
    if ios_lock:
        native = (root / "ios/Podfile.lock").read_text(encoding="utf-8")
        match = re.search(r"^  - FirebaseFirestore \(([^)]+)\):", native, re.M)
        if not match or not ((12, 19, 3) <= version(match[1]) < (13, 0, 0) or version(match[1]) >= (13, 1, 1)):
            errors.append("Resolved iOS FirebaseFirestore must be 12.19.3 or >=13.1.1")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--ios-lock", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    runtime = json.loads(subprocess.check_output([args.flutter, "--version", "--machine"], text=True))
    errors = verify(root, runtime, ios_lock=args.ios_lock)
    if errors:
        raise SystemExit("Security patch verification failed:\n" + "\n".join(errors))
    print(f"Security patch verified: Flutter {runtime['frameworkVersion']}, Dart {runtime['dartSdkVersion']}, resolved FlutterFire" + (", iOS Firestore" if args.ios_lock else ""))


if __name__ == "__main__":
    main()
