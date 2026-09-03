"""One fixture contract and exact cross-language wire response parity."""
import json
from pathlib import Path
import subprocess
import unittest
import datetime as dt

from access_policy import resolve_access
from ai_policy import read_cost_control, prepare_cost_reservation
from security import QuotaExceeded

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "test/fixtures/access_policy/v1.json"


class AccessContractTest(unittest.TestCase):
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
                    with self.assertRaises(QuotaExceeded if case["wantCode"] == "resource-exhausted" else ValueError):
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
process.stdout.write(JSON.stringify(f.cases.map(c => resolveAccess({
  uid:f.uid, now:f.now, environment:c.environment || 'PRODUCTION', phase:c.phase || 'free_launch',
  grant:c.grant ? {...f.grant,...c.grant} : null,
  entitlement:c.entitlement ? {...f.entitlement,...c.entitlement} : null}))));
'''
        canonical = json.loads(subprocess.check_output(
            ["node", "-e", script, str(FIXTURE), str(ROOT / "functions/gye/access_policy.js")], text=True))
        for case, expected in zip(fixture["cases"], canonical):
            with self.subTest(case=case["name"]):
                actual = resolve_access(uid=fixture["uid"], now=fixture["now"],
                    environment=case.get("environment", "PRODUCTION"), phase=case.get("phase", "free_launch"),
                    grant={**fixture["grant"], **case["grant"]} if "grant" in case else None,
                    entitlement={**fixture["entitlement"], **case["entitlement"]} if "entitlement" in case else None)
                self.assertEqual(actual["source"], case["wantSource"])
                self.assertEqual(actual["contentAccess"], case["wantContent"])
                self.assertEqual(actual["bookDailyLimit"], case["wantBook"])
                self.assertEqual(actual["pronunciationDailyLimit"], case["wantPronunciation"])
                self.assertEqual(actual, expected)
                self.assertEqual(actual, fixture["expectedSnapshots"][case["name"]])


if __name__ == "__main__":
    unittest.main()
