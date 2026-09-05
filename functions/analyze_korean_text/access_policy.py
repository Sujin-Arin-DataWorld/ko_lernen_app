"""Python mirror of Gye access_policy.js, guarded by shared cross-language tests.

Deployment stays self-contained; no runtime import from sibling codebases.
Only server-read authority documents may be passed to this resolver.
"""
import datetime as dt
import hashlib
import json
import math
import re

DAY_MILLIS = 86400000
PAID_OFFLINE_MILLIS = 3 * DAY_MILLIS
TESTER_OFFLINE_MILLIS = 30 * DAY_MILLIS


def safe_int(value):
    return type(value) in (int, float) and math.isfinite(value) and int(value) == value and 0 <= value <= 9007199254740991


def millis(value):
    if isinstance(value, dt.datetime):
        value = value.timestamp() * 1000
    return int(value) if safe_int(value) else None


def bounded_text(value, maximum):
    return isinstance(value, str) and bool(value.strip()) and len(value.encode("utf-8")) <= maximum and not re.search(r"[\x00-\x1f\x7f]", value)


def valid_uid(uid):
    return isinstance(uid, str) and 0 < len(uid.encode("utf-8")) <= 128 and uid not in {".", ".."} and not re.search(r"[\x00-\x20\x7f/]", uid)


def entitlement_document_id(uid, environment):
    if not valid_uid(uid) or environment not in {"PRODUCTION", "SANDBOX"}:
        raise ValueError("invalid_access_context")
    return environment + "_" + hashlib.sha256(uid.encode("utf-8")).hexdigest()


def _matches(value, uid, environment, account_created_at):
    return (isinstance(value, dict) and type(value.get("schemaVersion")) in (int, float) and
            millis(account_created_at) is not None and millis(value.get("accountCreatedAt")) == account_created_at and
            value.get("schemaVersion") == 1 and value.get("ownerUid") == uid and
            value.get("environment") == environment and safe_int(value.get("revision")) and value["revision"] > 0)


def resolve_access(*, uid, environment, phase, now, grant=None, entitlement=None, account_created_at=None):
    if not valid_uid(uid) or environment not in {"PRODUCTION", "SANDBOX"} or phase not in {"free_launch", "paid"} or millis(now) is None:
        raise ValueError("invalid_access_context")
    now = millis(now)
    account_created_at = millis(account_created_at)
    if account_created_at is not None and account_created_at > now:
        account_created_at = None
    grant = grant if isinstance(grant, dict) else {}
    entitlement = entitlement if isinstance(entitlement, dict) else {}
    approved_at = millis(grant.get("approvedAt"))
    checked_at = millis(entitlement.get("providerCheckedAt"))
    until = millis(entitlement.get("accessUntil"))
    tester = (_matches(grant, uid, environment, account_created_at) and grant.get("kind") == "closed_tester_lifetime" and
              grant.get("status") == "active" and bounded_text(grant.get("grantId"), 128) and
              grant.get("approvedBy") == "Jin" and bounded_text(grant.get("approvalRef"), 512) and
              approved_at is not None and approved_at <= now)
    subscriber = (_matches(entitlement, uid, environment, account_created_at) and entitlement.get("status") == "active" and
                  checked_at is not None and checked_at <= now and checked_at + PAID_OFFLINE_MILLIS > now and
                  until is not None and until > now)
    premium = tester or subscriber
    source = "closed_tester_lifetime" if tester else "subscription" if subscriber else "free_launch" if phase == "free_launch" else "free"
    access_until = until if subscriber and not tester else None
    offline_until = now + TESTER_OFFLINE_MILLIS if tester else min(until, checked_at + PAID_OFFLINE_MILLIS) if subscriber else now
    authority_revision = int(grant["revision"]) if tester else int(entitlement["revision"]) if subscriber else 0
    revision_input = json.dumps([1, uid, environment, phase, source, authority_revision, access_until, account_created_at], ensure_ascii=False, separators=(",", ":"))
    return {"schemaVersion": 1, "ownerUid": uid, "environment": environment,
            "revision": hashlib.sha256(revision_input.encode("utf-8")).hexdigest(), "source": source,
            # Subscription sales are disabled. Every authenticated learner
            # receives the former highest access tier.
            "contentAccess": "all", "aiPolicyId": "premium_v1",
            "bookDailyLimit": 20, "pronunciationDailyLimit": 50,
            "serverNow": now, "accessUntil": access_until, "offlineUntil": offline_until,
            "nextResetAt": (now // DAY_MILLIS + 1) * DAY_MILLIS}
