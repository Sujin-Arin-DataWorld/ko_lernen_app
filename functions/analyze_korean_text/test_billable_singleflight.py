"""Real HTTP/receipt/quota logic; only Firestore transport and paid work are fake."""
import copy
import datetime as dt
import hashlib
import threading
import time
import unittest
from types import SimpleNamespace
from concurrent.futures import ThreadPoolExecutor
from unittest import mock

from flask import Flask, request
import main as endpoint
from security import Caller, FirestoreIdempotencyGate, FirestoreQuotaGate, quota_document_id, QuotaPolicy, QuotaExceeded


class MemoryFirestore:
    def __init__(self):
        self.store = {"service_cost_controls/ai_v1": {
            "schemaVersion": 1, "approvedBy": "Jin", "approvalRef": "local-test-only", "approvedAt": 0,
            "dailyUnitLimit": 10000, "bookReservationUnits": 10, "pronunciationReservationUnits": 2, "ttsReservationUnits": 3}}
        self.lock = threading.RLock()
        self.outage = False
        self.fail_completed = False

    def collection(self, name):
        client = self
        class Collection:
            def document(self, key):
                return Reference(client, name + "/" + key)
        return Collection()

    def transaction(self):
        return Transaction(self)


class Reference:
    def __init__(self, client, key):
        self.client, self.key = client, key

    def get(self, transaction=None):
        if self.client.outage:
            raise RuntimeError("storage unavailable")
        if transaction is not None:
            assert not transaction.writes, "Firestore forbids read after write"
        data = copy.deepcopy(self.client.store.get(self.key))
        class Snapshot:
            exists = data is not None
            def to_dict(self):
                return data
        return Snapshot()

    def set(self, data):
        self.client.store[self.key] = copy.deepcopy(data)

    def delete(self):
        self.client.store.pop(self.key, None)


class Transaction:
    def __init__(self, client):
        self.client = client
        self.writes = []

    def set(self, reference, payload):
        self.writes.append((reference.key, copy.deepcopy(payload)))

    def delete(self, reference):
        self.writes.append((reference.key, None))


def transactional(fn):
    def run(transaction):
        client = transaction.client
        with client.lock:
            if client.outage:
                raise RuntimeError("storage unavailable")
            result = fn(transaction)
            if client.fail_completed and any(data and data.get("state") == "completed" for _, data in transaction.writes):
                raise RuntimeError("receipt save failed")
            for key, data in transaction.writes:
                if data is None:
                    client.store.pop(key, None)
                else:
                    client.store[key] = data
            return result
    return run


class BillableEndpointTest(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.db = MemoryFirestore()
        self.now = dt.datetime(2026, 9, 3, 12, tzinfo=dt.timezone.utc)
        self.receipts = FirestoreIdempotencyGate(firestore_client=self.db, now=lambda: self.now)
        self.quota = FirestoreQuotaGate(firestore_client=self.db, now=lambda: self.now)
        self.calls = 0
        self.auth_user = SimpleNamespace(uid="user-1", disabled=False,
                                        user_metadata=SimpleNamespace(creation_timestamp=0))
        self.provider = lambda **kwargs: endpoint._analysis_response("de")
        self.patches = [
            mock.patch("google.cloud.firestore.transactional", transactional),
            mock.patch("firebase_admin.auth.get_user", side_effect=lambda uid: self.auth_user),
            mock.patch.object(endpoint, "verify_caller", return_value=Caller("user-1", "app-1")),
            mock.patch.object(endpoint, "_idempotency_gate", return_value=self.receipts),
            mock.patch.object(endpoint, "_quota_gate", return_value=self.quota),
            mock.patch.object(endpoint, "_complete_book_analysis", side_effect=self.analyze),
        ]
        for patch in self.patches:
            patch.start()
            self.addCleanup(patch.stop)

    def analyze(self, **kwargs):
        with self.db.lock:
            self.calls += 1
        return self.provider(**kwargs)

    def run_request(self, **overrides):
        with self.app.test_request_context("/", method="POST", json={"text": "학생이에요.", "lang": "de", **overrides}):
            return endpoint.analyze_korean_text(request)

    def ledger(self):
        return next(value for key, value in self.db.store.items() if key.startswith("service_quota_ledgers/"))

    def seed_daily(self, count):
        self.db.store["service_quota_ledgers/" + quota_document_id("user-1")] = {
            "day": "2026-09-03", "dailyCount": count,
            "burstWindowStartedAt": self.now.timestamp(), "burstCount": 0}

    def grant(self, **overrides):
        return {"schemaVersion": 1, "ownerUid": "user-1", "environment": "PRODUCTION", "revision": 1,
                "accountCreatedAt": 0,
                "kind": "closed_tester_lifetime", "status": "active", "approvedBy": "Jin", "approvedAt": 0,
                "grantId": "local-test-grant", "approvalRef": "local-test-roster", **overrides}

    def test_forged_client_premium_never_exceeds_universal_book_limit(self):
        self.seed_daily(20)
        self.assertEqual(self.run_request(tier="premium", isPremium=True, FREE_LAUNCH=True,
                                         premiumGrant=self.grant(), feedbackPassport=True).status_code, 429)
        self.assertEqual(self.calls, 0)

    def test_legacy_premium_authority_cannot_change_universal_limit_across_uid_recreation(self):
        for source in ["tester", "subscription"]:
            with self.subTest(source=source):
                # Node Admin exposes creationTime via UTC strings (seconds);
                # Python exposes the same account's original millisecond value.
                self.auth_user.user_metadata.creation_timestamp = 999
                self.seed_daily(19)
                key = ("premium_grants/user-1" if source == "tester" else
                       "customer_entitlements/PRODUCTION_" + hashlib.sha256(b"user-1").hexdigest())
                self.db.store[key] = {**self.grant(), "accountCreatedAt": 0,
                    "providerCheckedAt": int(self.now.timestamp() * 1000),
                    "accessUntil": int(self.now.timestamp() * 1000) + 60000}
                before = self.calls
                self.assertEqual(self.run_request(requestId="before-" + source).status_code, 200)
                self.auth_user.user_metadata.creation_timestamp = 1000
                self.assertEqual(self.run_request(requestId="recreated-" + source,
                                                 accountCreatedAt=0).status_code, 429)
                self.assertEqual(self.calls, before + 1)
                self.assertEqual(self.ledger()["dailyCount"], 20)
                self.db.store.pop(key)

    def test_book_disabled_missing_or_wrong_auth_user_never_dispatches(self):
        for user in [SimpleNamespace(uid="user-1", disabled=True),
                     SimpleNamespace(uid="other", disabled=False)]:
            self.auth_user = user
            self.assertEqual(self.run_request().status_code, 403)
            self.assertEqual(self.calls, 0)
        with mock.patch("firebase_admin.auth.get_user", side_effect=ValueError("missing")):
            self.assertEqual(self.run_request().status_code, 403)
        self.assertFalse(any(k.startswith("service_quota_ledgers/") for k in self.db.store))

    def test_server_tester_subscription_and_tier_transitions_preserve_count(self):
        for source in ["tester", "subscription"]:
            with self.subTest(source=source):
                self.seed_daily(19)
                if source == "tester":
                    key = "premium_grants/user-1"
                    self.db.store[key] = self.grant()
                else:
                    key = "customer_entitlements/PRODUCTION_" + hashlib.sha256(b"user-1").hexdigest()
                    self.db.store[key] = {"schemaVersion": 1, "ownerUid": "user-1", "environment": "PRODUCTION",
                        "accountCreatedAt": 0,
                        "revision": 1, "status": "active", "providerCheckedAt": int(self.now.timestamp() * 1000),
                        "accessUntil": int(self.now.timestamp() * 1000) + 60000}
                self.assertEqual(self.run_request(requestId="request-" + source).status_code, 200)
                self.assertEqual(self.run_request(requestId="last-slot-" + source).status_code, 429)
                self.db.store.pop(key)
                self.assertEqual(self.run_request(requestId="downgraded-" + source).status_code, 429)
                self.assertEqual(self.ledger()["dailyCount"], 20)

    def test_malformed_environment_uid_and_stale_authority_do_not_raise_quota(self):
        self.seed_daily(20)
        for patch in [{"ownerUid": "other"}, {"environment": "SANDBOX"}, {"status": "revoked"},
                      {"schemaVersion": 2}, {"approvedAt": int(self.now.timestamp() * 1000) + 60000}]:
            self.db.store["premium_grants/user-1"] = self.grant(**patch)
            self.assertEqual(self.run_request().status_code, 429)
        self.db.store.pop("premium_grants/user-1")
        key = "customer_entitlements/PRODUCTION_" + hashlib.sha256(b"user-1").hexdigest()
        self.db.store[key] = {"schemaVersion": 1, "ownerUid": "user-1", "environment": "PRODUCTION", "revision": 1,
            "accountCreatedAt": 0,
            "status": "active", "providerCheckedAt": int((self.now - dt.timedelta(days=4)).timestamp() * 1000),
            "accessUntil": int(self.now.timestamp() * 1000) + 60000}
        self.assertEqual(self.run_request().status_code, 429)
        self.assertEqual(self.calls, 0)

    def test_missing_unapproved_or_zero_cap_fails_before_provider_or_user_quota(self):
        original = self.db.store["service_cost_controls/ai_v1"]
        for patch in [None, {"approvedBy": "self"}, {"dailyUnitLimit": 0}, {"bookReservationUnits": 0},
                      {"approvedAt": int(self.now.timestamp() * 1000) + 60000}]:
            self.db.store["service_cost_controls/ai_v1"] = {**original, **(patch or {})}
            if patch is None:
                self.db.store.pop("service_cost_controls/ai_v1")
            self.assertIn(self.run_request().status_code, [429, 503])
            self.assertEqual(self.calls, 0)
            self.assertFalse(any(k.startswith("service_quota_ledgers/") for k in self.db.store))

    def test_atomic_global_cap_last_slot_and_uncertain_retains_cost(self):
        self.db.store["service_cost_controls/ai_v1"]["dailyUnitLimit"] = 10
        def fail(**kwargs):
            raise TimeoutError("uncertain")
        self.provider = fail
        with ThreadPoolExecutor(max_workers=10) as pool:
            results = list(pool.map(lambda i: self.run_request(requestId=f"unique-request-{i}").status_code, range(10)))
        self.assertEqual(results.count(429), 9)
        self.assertEqual(self.calls, 1)
        self.assertEqual(self.db.store["service_cost_ledgers/2026-09-03"]["reservedUnits"], 10)

    def test_lowered_nonzero_cap_fences_dispatch_of_existing_claim(self):
        owner = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.db.store["service_cost_controls/ai_v1"]["dailyUnitLimit"] = 9
        with self.assertRaises(QuotaExceeded):
            self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="pending")
        self.assertEqual(self.db.store["service_idempotency/request"]["state"], "claimed")

    def test_ten_concurrent_http_requests_invoke_expensive_analysis_once(self):
        release = threading.Event()
        def block(**kwargs):
            release.wait(5)
            return endpoint._analysis_response("de")
        self.provider = block
        barrier = threading.Barrier(11)
        def invoke():
            barrier.wait()
            return self.run_request()
        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(invoke) for _ in range(10)]
            barrier.wait()
            time.sleep(0.1)
            release.set()
            results = [future.result() for future in futures]
        self.assertEqual(self.calls, 1)
        self.assertEqual(self.ledger()["dailyCount"], 1)
        self.assertEqual(sorted(r.status_code for r in results), [200] + [409] * 9)

    def test_completed_replay_never_reanalyzes(self):
        first = self.run_request()
        second = self.run_request()
        self.assertEqual(first.get_json(), second.get_json())
        self.assertEqual(self.calls, 1)

    def test_request_id_content_mismatch_is_rejected(self):
        self.assertEqual(self.run_request(requestId="request-123").status_code, 200)
        self.assertEqual(self.run_request(requestId="request-123", text="안녕하세요.").status_code, 409)
        self.assertEqual(self.calls, 1)

    def test_storage_outage_prevents_paid_work(self):
        self.db.outage = True
        self.assertEqual(self.run_request().status_code, 503)
        self.assertEqual(self.calls, 0)

    def test_provider_failure_retains_reservation_and_blocks_retry(self):
        def fail(**kwargs):
            raise TimeoutError("may have processed")
        self.provider = fail
        self.assertEqual(self.run_request().status_code, 503)
        self.assertEqual(self.run_request().get_json()["warnings"], ["analysis_uncertain"])
        self.assertEqual(self.calls, 1)
        self.assertEqual(self.ledger()["dailyCount"], 1)

    def test_degraded_provider_timeout_result_is_uncertain_not_completed(self):
        self.provider = lambda **kwargs: endpoint._analysis_response("de", warnings=["translation_unavailable"])
        self.assertEqual(self.run_request().status_code, 503)
        self.assertEqual(self.run_request().get_json()["warnings"], ["analysis_uncertain"])
        self.assertEqual(self.calls, 1)
        self.assertEqual(self.ledger()["dailyCount"], 1)

    def test_success_before_save_failure_blocks_retry(self):
        self.db.fail_completed = True
        self.assertEqual(self.run_request().status_code, 503)
        self.assertEqual(self.run_request().status_code, 503)
        self.assertEqual(self.calls, 1)

    def test_expired_response_is_not_replayed_or_reprocessed(self):
        self.assertEqual(self.run_request().status_code, 200)
        self.now += dt.timedelta(minutes=16)
        self.assertEqual(self.run_request().get_json()["warnings"], ["analysis_uncertain"])
        self.assertEqual(self.calls, 1)

    def test_deletion_marker_prevents_replay(self):
        self.run_request()
        self.db.store["account_deletions/user-1"] = {"state": "pending"}
        self.assertEqual(self.run_request().status_code, 403)
        self.assertEqual(self.calls, 1)

    def test_quota_denial_has_no_partial_receipt_or_expensive_call(self):
        self.db.store["service_quota_ledgers/" + quota_document_id("user-1")] = {
            "day": "2026-09-03", "dailyCount": 20,
            "burstWindowStartedAt": self.now.timestamp(), "burstCount": 0}
        response = self.run_request()
        self.assertEqual(response.status_code, 429)
        self.assertEqual(response.get_json(), {"warnings": ["rate_limited"]})
        self.assertGreater(int(response.headers["Retry-After"]), 0)
        self.assertEqual(self.calls, 0)
        self.assertFalse(any(key.startswith("service_idempotency/") for key in self.db.store))

    def test_expired_pending_owner_cannot_settle_or_refund(self):
        owner = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.assertFalse(self.receipts.transition("request", uid="user-1", owner_token="other", target="pending"))
        self.assertTrue(self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="pending"))
        self.now += dt.timedelta(seconds=61)
        self.assertEqual(self.receipts.claim("request", uid="user-1", fingerprint="hash")["state"], "uncertain")
        self.assertFalse(self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="completed", result={}))
        self.assertFalse(self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="refunded"))
        self.assertEqual(self.ledger()["dailyCount"], 1)

    def test_reclaimed_undispatched_owner_and_duplicate_refund_are_fenced(self):
        old = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.now += dt.timedelta(seconds=61)
        current = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.assertNotEqual(current["ownerToken"], old["ownerToken"])
        self.assertEqual(self.ledger()["dailyCount"], 1)
        self.assertFalse(self.receipts.transition("request", uid="user-1", owner_token=old["ownerToken"], target="refunded"))
        self.assertTrue(self.receipts.transition("request", uid="user-1", owner_token=current["ownerToken"], target="refunded"))
        self.assertFalse(self.receipts.transition("request", uid="user-1", owner_token=current["ownerToken"], target="refunded"))
        self.assertEqual(self.ledger()["dailyCount"], 0)

    def test_duplicate_settle_cannot_replace_completed_result(self):
        owner = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="pending")
        self.assertTrue(self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="completed", result={"warnings": ["first"]}))
        self.assertFalse(self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="completed", result={"warnings": ["second"]}))
        self.assertEqual(self.receipts.claim("request", uid="user-1", fingerprint="hash")["result"]["warnings"], ["first"])

    def test_midnight_refund_never_refunds_another_day(self):
        self.now = dt.datetime(2026, 9, 3, 23, 59, 59, tzinfo=dt.timezone.utc)
        owner = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.now += dt.timedelta(seconds=1)
        self.receipts.claim("request-2", uid="user-1", fingerprint="hash2")
        self.assertTrue(self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="refunded"))
        self.assertEqual(self.ledger()["dailyCount"], 1)
        # The rolling burst window spans midnight; refund only this reservation.
        self.assertEqual(self.ledger()["burstCount"], 1)

    def test_receipt_contains_no_derived_result_and_replay_is_allowlisted(self):
        self.provider = lambda **kwargs: endpoint.Response(
            '{"words":[{"korean":"학생","translation":"Student","token":"secret"}],"audio":"secret","uid":"secret"}',
            mimetype="application/json")
        first = self.run_request()
        replay = self.run_request()
        self.assertEqual(first.get_json(), replay.get_json())
        self.assertNotIn("secret", replay.get_data(as_text=True))
        receipt = next(value for key, value in self.db.store.items() if key.startswith("service_idempotency/"))
        result = next(value for key, value in self.db.store.items() if key.startswith("service_idempotency_results/"))
        self.assertNotIn("result", receipt)
        self.assertEqual(result["expiresAt"], self.now + dt.timedelta(minutes=15))
        self.assertEqual(receipt["expiresAt"], self.now + dt.timedelta(hours=24))

    def test_server_policy_resolver_overrides_client_tier(self):
        self.receipts._resolve_policy = lambda uid, transaction, now: QuotaPolicy(1, 3, 60)
        self.assertEqual(self.run_request(tier="premium").status_code, 200)
        self.assertEqual(self.run_request(text="안녕하세요.", tier="premium").status_code, 429)
        self.assertEqual(self.calls, 1)

    def test_recovery_window_end_requires_new_reservation(self):
        self.run_request()
        self.now += dt.timedelta(hours=24, seconds=1)
        self.assertEqual(self.run_request().status_code, 200)
        self.assertEqual(self.calls, 2)
        self.assertEqual(self.ledger()["dailyCount"], 1)

    def test_late_reclaimed_dispatch_has_full_recovery_window(self):
        self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.now += dt.timedelta(hours=24, seconds=-1)
        owner = self.receipts.claim("request", uid="user-1", fingerprint="hash")
        self.receipts.transition("request", uid="user-1", owner_token=owner["ownerToken"], target="pending")
        self.now += dt.timedelta(seconds=2)
        self.assertEqual(self.receipts.claim("request", uid="user-1", fingerprint="hash")["state"], "pending")


if __name__ == "__main__":
    unittest.main()
