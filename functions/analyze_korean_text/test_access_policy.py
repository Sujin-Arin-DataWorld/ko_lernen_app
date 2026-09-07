"""Shared v2 fixture and exact Node/Python access response parity."""
import datetime as dt
import json
from pathlib import Path
import subprocess
import unittest

from access_policy import resolve_access
from ai_policy import read_cost_control, prepare_cost_reservation
from security import QuotaExceeded

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "test/fixtures/access_policy/v2.json"


class AccessContractTest(unittest.TestCase):
    def test_runtime_datetime_is_truncated_to_utc_milliseconds(self):
        now = dt.datetime(2026, 9, 3, 12, 0, 0, 123456, tzinfo=dt.timezone.utc)
        actual = resolve_access(uid="user-1", environment="PRODUCTION", now=now)
        self.assertEqual(actual["serverNow"], 1788436800123)
        self.assertEqual(actual["nextResetAt"], 1788480000000)
        with self.assertRaises(ValueError):
            resolve_access(uid="user-1", environment="PRODUCTION", now=now.replace(tzinfo=None))

    def test_shared_service_cost_contract(self):
        from test_billable_singleflight import MemoryFirestore
        fixture = json.loads((FIXTURE.parent / "cost-v1.json").read_text(encoding="utf-8"))
        now = dt.datetime.fromtimestamp(fixture["now"] / 1000, tz=dt.timezone.utc)
        for case in fixture["cases"]:
            if case.get("kind", "book") != "book":
                continue
            with self.subTest(case=case["name"]):
                db = MemoryFirestore()
                db.store["service_cost_controls/ai_v1"] = {**fixture["config"], **case.get("config", {})}
                if case.get("missingControl"):
                    db.store.pop("service_cost_controls/ai_v1")
                if "reservedUnits" in case:
                    db.store["service_cost_ledgers/2026-09-03"] = {"reservedUnits": case["reservedUnits"]}
                transaction = db.transaction()

                def run():
                    config = read_cost_control(db, transaction, now)
                    return prepare_cost_reservation(db, transaction, now, config, case.get("existing"))

                if "wantCode" in case:
                    expected_error = QuotaExceeded if case["wantCode"] == "resource-exhausted" else ValueError
                    with self.assertRaises(expected_error):
                        run()
                else:
                    result = run()
                    self.assertEqual(result.get("payload", {}).get("reservedUnits", case.get("reservedUnits")), case["wantUnits"])
                    self.assertEqual(result["reservation"]["day"], "2026-09-03")
                    if "payload" in result:
                        self.assertEqual(result["payload"]["expiresAt"].isoformat(), "2026-09-05T00:00:00+00:00")

    def test_shared_contract_and_complete_node_python_response_parity(self):
        fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
        names = [case["name"] for case in fixture["cases"]]
        self.assertEqual(len(set(names)), len(names))
        self.assertEqual(set(fixture["expectedSnapshots"]), set(names))
        script = r'''
const f = require(process.argv[1]);
const {resolveAccess} = require(process.argv[2]);
process.stdout.write(JSON.stringify(f.cases.map(c => resolveAccess(c))));
'''
        gye = json.loads(subprocess.check_output(
            ["node", "-e", script, str(FIXTURE), str(ROOT / "functions/gye/access_policy.js")],
            text=True, encoding="utf-8",
        ))
        pronunciation = json.loads(subprocess.check_output(
            ["node", "-e", script, str(FIXTURE), str(ROOT / "functions/pronunciation/access_policy.js")],
            text=True, encoding="utf-8",
        ))
        self.assertEqual(pronunciation, gye)
        for case, expected in zip(fixture["cases"], gye):
            with self.subTest(case=case["name"]):
                actual = resolve_access(
                    uid=case["uid"],
                    environment=case["environment"],
                    now=case["now"],
                )
                self.assertEqual(actual, expected)
                self.assertEqual(actual, fixture["expectedSnapshots"][case["name"]])

    def test_retired_authority_fields_are_not_policy_inputs(self):
        context = {"uid": "account-A", "environment": "PRODUCTION", "now": 1788436800000}
        expected = resolve_access(**context)
        with self.assertRaises(TypeError):
            resolve_access(**context, premium=True)
        self.assertEqual(resolve_access(**context), expected)


if __name__ == "__main__":
    unittest.main()
