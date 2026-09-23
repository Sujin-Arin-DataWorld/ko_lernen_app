#!/usr/bin/env python3
"""Collect six process-cold launches without clearing app data or consent.

The first launch is retained but excluded from the five-sample median. This
measures am start -W TotalTime (initial display), not fully usable Flutter UI.
No connected device is selected implicitly. Reports omit device serials and
raw package dumps. A report never declares the complete CP2026 gate passed.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import statistics
import subprocess
import time

PACKAGE = "com.sujinarin.ko_lernen_app"
ACTIVITY = f"{PACKAGE}/{PACKAGE}.MainActivity"
SAMPLE_COUNT = 6
THRESHOLD_MS = 2500


class MeasurementError(Exception):
    """A measurement cannot be used; do not replace it with a faster retry."""


class Adb:
    def __init__(self, executable: str, serial: str):
        self.executable = executable
        self.serial = serial

    def run(self, *args: str, allow_absent: bool = False) -> str:
        try:
            result = subprocess.run(
                [self.executable, "-s", self.serial, *args],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
                timeout=60, check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise MeasurementError("adb command timed out") from exc
        except OSError as exc:
            raise MeasurementError("adb could not be executed") from exc
        if result.returncode != 0:
            # pidof returns 1 for an absent process. A transport/permission error
            # must not become evidence that the process was stopped.
            if allow_absent and result.returncode == 1 and not (
                result.stdout.strip() or result.stderr.strip()
            ):
                return ""
            raise MeasurementError("adb command failed")
        return result.stdout.strip()


def package_identity(raw: str) -> dict:
    code = re.search(r"\bversionCode=(\d+)\b", raw)
    name = re.search(r"\bversionName=([^\r\n]+)", raw)
    if code is None or name is None or name.group(1).strip() in ("", "null"):
        raise MeasurementError("installed package version is unavailable")
    if re.search(r"\bDEBUGGABLE\b", raw):
        raise MeasurementError("debuggable builds are not benchmark candidates")
    # Reinstalling a different APK can retain the version code/name. Android's
    # package update timestamp is a continuity marker, not an artifact hash.
    updates = re.findall(r"^[ \t]*lastUpdateTime=([^\r\n]*)", raw, flags=re.MULTILINE)
    if len(updates) != 1:
        raise MeasurementError("installed package installation marker is unavailable")
    updated = updates[0].strip()
    try:
        datetime.strptime(updated, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        raise MeasurementError("installed package installation marker is invalid") from None
    return {"versionCode": int(code.group(1)), "versionName": name.group(1).strip(),
            "lastUpdateTime": updated}


def parse_launch(raw: str) -> dict:
    fields = {}
    for line in raw.splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            key, value = key.strip(), value.strip()
            if key in ("Status", "Activity", "LaunchState", "TotalTime", "WaitTime"):
                if key in fields:
                    raise MeasurementError("ambiguous launch output")
                fields[key] = value
    activity = fields.get("Activity", "").replace(f"{PACKAGE}/.", f"{PACKAGE}/{PACKAGE}.")
    if fields.get("Status") != "ok" or activity != ACTIVITY:
        raise MeasurementError("launch did not reach the expected activity")
    if "Complete" not in {line.strip() for line in raw.splitlines()}:
        raise MeasurementError("launch did not complete")
    launch_state = fields.get("LaunchState")
    if launch_state is not None and launch_state != "COLD":
        raise MeasurementError("launch was not cold")
    if re.search(r"\b(?:Warning|Error)\b", raw, flags=re.IGNORECASE):
        raise MeasurementError("launch returned a warning or error")
    value = fields.get("TotalTime", "")
    if not value.isdecimal() or int(value) <= 0:
        raise MeasurementError("launch has no positive TotalTime")
    return {"totalTimeMs": int(value), "reportedLaunchState": launch_state}


def collect(adb: Adb, expected_version_code: int, settle=time.sleep) -> dict:
    report = {
        "schemaVersion": 1,
        "startedAt": datetime.now(timezone.utc).isoformat(),
        "package": PACKAGE,
        "metric": "am start -W TotalTime (initial display; not fully interactive)",
        "protocol": "six process-cold launches; retain and exclude first; median of last five",
        "expectedVersionCode": expected_version_code,
        "samples": [],
        "measurementComplete": False,
        "cp2026Gate": "unverified",
        "unverified": ["low-end device qualification", "release artifact/source SHA linkage",
                       "fully usable Flutter screen", "physical-device visual checks"],
    }
    try:
        if expected_version_code <= 0:
            raise MeasurementError("expected version code must be positive")
        if adb.run("get-state") != "device":
            raise MeasurementError("selected device is not ready")
        identity = package_identity(adb.run("shell", "dumpsys", "package", PACKAGE))
        if identity["versionCode"] != expected_version_code:
            raise MeasurementError("installed build differs from expected version code")
        report["installedBuild"] = identity
        report["device"] = {
            "model": adb.run("shell", "getprop", "ro.product.model"),
            "androidVersion": adb.run("shell", "getprop", "ro.build.version.release"),
            "sdk": adb.run("shell", "getprop", "ro.build.version.sdk"),
            "emulatorProperty": adb.run("shell", "getprop", "ro.kernel.qemu"),
        }
        for index in range(SAMPLE_COUNT):
            if package_identity(adb.run("shell", "dumpsys", "package", PACKAGE)) != identity:
                raise MeasurementError("installed build changed during collection")
            adb.run("shell", "am", "force-stop", PACKAGE)
            if adb.run("shell", "pidof", PACKAGE, allow_absent=True):
                raise MeasurementError("app process survived force-stop")
            sample = parse_launch(adb.run("shell", "am", "start", "-W", "-n", ACTIVITY))
            sample.update({"index": index + 1, "includedInMedian": index != 0,
                           "processAbsentBeforeLaunch": True})
            report["samples"].append(sample)
            if package_identity(adb.run("shell", "dumpsys", "package", PACKAGE)) != identity:
                raise MeasurementError("installed build changed during collection")
            # Let startup settle before the next force-stop. No data reset,
            # account mutation, permission grant, or measurement-consent change.
            if index + 1 < SAMPLE_COUNT:
                settle(5)
        values = [sample["totalTimeMs"] for sample in report["samples"][1:]]
        median = statistics.median(values)
        report.update({"measurementComplete": True, "measuredValuesMs": values,
                       "medianMs": median, "numericThresholdMs": THRESHOLD_MS,
                       "numericThresholdMet": median <= THRESHOLD_MS})
    except MeasurementError as exc:
        report["failure"] = str(exc)
    report["finishedAt"] = datetime.now(timezone.utc).isoformat()
    return report


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb", help="Path to Android SDK adb")
    parser.add_argument("--serial", required=True, help="Explicit connected test device; not saved")
    parser.add_argument("--expected-version-code", type=int, required=True)
    parser.add_argument("--output", type=Path, required=True, help="New evidence JSON; never overwritten")
    args = parser.parse_args(argv)
    if args.expected_version_code <= 0 or not args.serial.strip() or args.serial.startswith("-"):
        parser.error("a device serial and positive expected version code are required")
    # Reserve the evidence file before interacting with a device. Refuse to
    # overwrite a previous run or silently append new measurements to it.
    try:
        with args.output.open("x", encoding="utf-8") as handle:
            report = collect(Adb(args.adb, args.serial), args.expected_version_code)
            json.dump(report, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
    except OSError:
        parser.exit(2, "Cannot create a new evidence file at --output.\n")
    print("Measurement recorded; CP2026 gate remains unverified." if report["measurementComplete"]
          else "Measurement incomplete; inspect the evidence failure field.")
    return 0 if report["measurementComplete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
