import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from tool import collect_android_coldstart as target


def launch(ms=2000, state="COLD"):
    return (f"Status: ok\nLaunchState: {state}\nActivity: {target.PACKAGE}/.MainActivity\n"
            f"TotalTime: {ms}\nWaitTime: {ms + 10}\nComplete\n")


class FakeAdb:
    def __init__(self):
        self.calls = []
        self.launches = [launch(ms) for ms in (9000, 1000, 2500, 4000, 2000, 3000)]
        self.identity = ("versionCode=7653 minSdk=23\nversionName=2.0.9\nflags=[ HAS_CODE ]"
                         "\nlastUpdateTime=2026-09-23 21:36:15")
        self.pid = ""
        self.launch_error = None

    def run(self, *args, **kwargs):
        self.calls.append(args)
        if args == ("get-state",):
            return "device"
        if args[1:3] == ("dumpsys", "package"):
            return self.identity
        if args[1:3] == ("am", "start"):
            if self.launch_error:
                raise self.launch_error
            return self.launches.pop(0)
        if args[1] == "pidof":
            return self.pid
        if args[1] == "getprop":
            return {"ro.product.model": "fixture only", "ro.build.version.release": "13",
                    "ro.build.version.sdk": "33", "ro.kernel.qemu": "1"}[args[2]]
        return ""


class ColdstartTest(unittest.TestCase):
    def test_keeps_warmup_excludes_it_and_reports_only_numeric_threshold(self):
        adb = FakeAdb()
        report = target.collect(adb, 7653, settle=lambda _: None)
        self.assertTrue(report["measurementComplete"])
        self.assertEqual(report["samples"][0]["totalTimeMs"], 9000)
        self.assertFalse(report["samples"][0]["includedInMedian"])
        self.assertEqual(report["measuredValuesMs"], [1000, 2500, 4000, 2000, 3000])
        self.assertEqual(report["medianMs"], 2500)
        self.assertTrue(report["numericThresholdMet"])
        self.assertEqual(report["cp2026Gate"], "unverified")
        self.assertNotIn("sourceSha", report)
        self.assertEqual(sum(call[1:3] == ("am", "force-stop") for call in adb.calls), 6)
        self.assertTrue(all(call[-1] == target.PACKAGE for call in adb.calls
                            if call[1:3] == ("am", "force-stop")))
        self.assertFalse(any("clear" in call or "grant" in call for call in adb.calls))

    def test_median_over_threshold_does_not_pass(self):
        adb = FakeAdb()
        adb.launches = [launch(3000)] * 6
        report = target.collect(adb, 7653, settle=lambda _: None)
        self.assertFalse(report["numericThresholdMet"])

    def test_bad_launches_are_rejected_not_substituted(self):
        bad = [launch(state="WARM"), launch(state="HOT"), launch(0), launch(-1),
               launch().replace("Status: ok", "Status: timeout"),
               launch().replace("Complete", ""),
               launch().replace("TotalTime: 2000", "TotalTime: bad"),
               launch().replace(target.PACKAGE, "com.other.app"),
               launch() + "Warning: Activity not started\n",
               launch() + "TotalTime: 1\n"]
        for raw in bad:
            with self.subTest(raw=raw):
                adb = FakeAdb()
                adb.launches[1] = raw
                report = target.collect(adb, 7653, settle=lambda _: None)
                self.assertFalse(report["measurementComplete"])
                self.assertEqual(len(report["samples"]), 1)
                self.assertNotIn("medianMs", report)
                self.assertEqual(len(adb.launches), 4)

    def test_older_android_without_launchstate_uses_checked_absent_process(self):
        self.assertIsNone(target.parse_launch(launch().replace("LaunchState: COLD\n", ""))
                          ["reportedLaunchState"])

    def test_wrong_build_or_debuggable_or_missing_version_never_force_stops(self):
        base = FakeAdb().identity
        cases = (("", "installed package version is unavailable"),
                 (base.replace("versionCode=7653", "versionCode=249"),
                  "installed build differs from expected version code"),
                 (base.replace("HAS_CODE", "DEBUGGABLE"),
                  "debuggable builds are not benchmark candidates"))
        for identity, failure in cases:
            with self.subTest(identity=identity):
                adb = FakeAdb()
                adb.identity = identity
                report = target.collect(adb, 7653, settle=lambda _: None)
                self.assertFalse(report["measurementComplete"])
                self.assertEqual(report["failure"], failure)
                self.assertFalse(any("force-stop" in call for call in adb.calls))

    def test_surviving_process_never_launches(self):
        adb = FakeAdb()
        adb.pid = "123"
        report = target.collect(adb, 7653, settle=lambda _: None)
        self.assertIn("survived", report["failure"])
        self.assertEqual(len(adb.launches), 6)

    def test_changed_build_invalidates_entire_measurement(self):
        adb = FakeAdb()
        def update_during_settle(_):
            adb.identity = adb.identity.replace("versionCode=7653", "versionCode=7656")
        report = target.collect(adb, 7653, settle=update_during_settle)
        self.assertFalse(report["measurementComplete"])
        self.assertIn("changed", report["failure"])
        self.assertNotIn("numericThresholdMet", report)

    def test_same_version_replacement_between_samples_stops_before_next_launch(self):
        adb = FakeAdb()
        def replace_during_settle(_):
            adb.identity = adb.identity.replace("21:36:15", "21:37:15")
        report = target.collect(adb, 7653, settle=replace_during_settle)
        self.assertFalse(report["measurementComplete"])
        self.assertIn("changed", report["failure"])
        self.assertNotIn("medianMs", report)
        self.assertEqual(len(report["samples"]), 1)
        self.assertEqual(len(adb.launches), 5)

    def test_same_version_replacement_during_launch_invalidates_measurement(self):
        adb = FakeAdb()
        original = adb.run
        def replace_after_launch(*args, **kwargs):
            result = original(*args, **kwargs)
            if args[1:3] == ("am", "start"):
                adb.identity = adb.identity.replace("21:36:15", "21:37:15")
            return result
        adb.run = replace_after_launch
        report = target.collect(adb, 7653, settle=lambda _: None)
        self.assertFalse(report["measurementComplete"])
        self.assertIn("changed", report["failure"])
        self.assertNotIn("numericThresholdMet", report)
        self.assertEqual(len(adb.launches), 5)

    def test_unavailable_or_ambiguous_installation_marker_never_force_stops(self):
        base = FakeAdb().identity.split("\nlastUpdateTime=")[0]
        for marker in ("", "\nlastUpdateTime=null", "\nlastUpdateTime=bad",
                       "\nlastUpdateTime=2026-02-30 21:36:15",
                       "\nlastUpdateTime=2026-09-23 21:36:15\nlastUpdateTime=2026-09-23 21:36:15"):
            with self.subTest(marker=marker):
                adb = FakeAdb()
                adb.identity = base + marker
                report = target.collect(adb, 7653, settle=lambda _: None)
                self.assertFalse(report["measurementComplete"])
                self.assertIn("installation marker", report["failure"])
                self.assertFalse(any("force-stop" in call for call in adb.calls))

    def test_timeout_is_terminal_no_automatic_retry(self):
        adb = FakeAdb()
        adb.launch_error = target.MeasurementError("adb command timed out")
        report = target.collect(adb, 7653, settle=lambda _: None)
        self.assertEqual(report["failure"], "adb command timed out")
        self.assertEqual(sum(call[1:3] == ("am", "start") for call in adb.calls), 1)

    def test_pidof_absence_is_narrow_and_errors_are_sanitized(self):
        adb = target.Adb("adb", "private-serial")
        for code, stdout, stderr, permitted in ((1, "", "", True), (1, "", "offline", False),
                                               (1, "error", "", False), (2, "", "", False)):
            with self.subTest(code=code, stdout=stdout, stderr=stderr):
                with patch.object(target.subprocess, "run", return_value=
                                  subprocess.CompletedProcess([], code, stdout, stderr)) as run:
                    if permitted:
                        self.assertEqual(adb.run("shell", "pidof", target.PACKAGE,
                                                 allow_absent=True), "")
                    else:
                        with self.assertRaisesRegex(target.MeasurementError, "^adb command failed$"):
                            adb.run("shell", "pidof", target.PACKAGE, allow_absent=True)
                    self.assertEqual(run.call_args.args[0][:3], ["adb", "-s", "private-serial"])

    def test_adb_timeout_does_not_expose_serial(self):
        with patch.object(target.subprocess, "run", side_effect=
                          subprocess.TimeoutExpired(["adb", "-s", "private-serial"], 60)):
            with self.assertRaisesRegex(target.MeasurementError, "^adb command timed out$"):
                target.Adb("adb", "private-serial").run("get-state")

    def test_output_refuses_overwrite_before_device_interaction(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "proof.json"
            output.write_text("preserved", encoding="utf-8")
            with patch.object(target, "collect") as collect:
                with self.assertRaises(SystemExit):
                    target.main(["--serial", "private", "--expected-version-code", "7653",
                                 "--output", str(output)])
                collect.assert_not_called()
            self.assertEqual(output.read_text(encoding="utf-8"), "preserved")

    def test_incomplete_run_is_written_and_returns_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "proof.json"
            report = {"measurementComplete": False, "failure": "selected device is not ready"}
            with patch.object(target, "collect", return_value=report):
                self.assertEqual(target.main(["--serial", "private", "--expected-version-code", "7653",
                                              "--output", str(output)]), 1)
            self.assertEqual(json.loads(output.read_text(encoding="utf-8")), report)
            self.assertNotIn("private", output.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
