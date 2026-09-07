"""Python mirror of the universal access policy in both Node backends.

Deployment stays self-contained; shared cross-language tests guard semantic
parity. Every authenticated learner receives the same content and AI limits.
"""
import datetime as dt
import hashlib
import json
import math
import re

DAY_MILLIS = 86400000
ACCESS_ENVIRONMENTS = {"PRODUCTION", "SANDBOX"}


def safe_int(value):
    return type(value) in (int, float) and math.isfinite(value) and int(value) == value and 0 <= value <= 9007199254740991


def millis(value):
    if isinstance(value, dt.datetime):
        if value.tzinfo is None:
            return None
        epoch = dt.datetime(1970, 1, 1, tzinfo=dt.timezone.utc)
        delta = value.astimezone(dt.timezone.utc) - epoch
        value = (delta.days * DAY_MILLIS + delta.seconds * 1000 +
                 delta.microseconds // 1000)
    return int(value) if safe_int(value) else None


def bounded_text(value, maximum):
    return isinstance(value, str) and bool(value.strip()) and len(value.encode("utf-8")) <= maximum and not re.search(r"[\x00-\x1f\x7f]", value)


def valid_uid(uid):
    return isinstance(uid, str) and 0 < len(uid.encode("utf-8")) <= 128 and uid not in {".", ".."} and not re.search(r"[\x00-\x20\x7f/]", uid)


def resolve_access(*, uid, environment, now):
    if not valid_uid(uid) or environment not in ACCESS_ENVIRONMENTS or millis(now) is None:
        raise ValueError("invalid_access_context")
    now = millis(now)
    source = "universal"
    ai_policy_id = "universal_v1"
    revision_input = json.dumps(
        [2, uid, environment, source, ai_policy_id],
        ensure_ascii=False,
        separators=(",", ":"),
    )
    return {
        "schemaVersion": 2,
        "ownerUid": uid,
        "environment": environment,
        "revision": hashlib.sha256(revision_input.encode("utf-8")).hexdigest(),
        "source": source,
        "contentAccess": "all",
        "aiPolicyId": ai_policy_id,
        "bookDailyLimit": 20,
        "pronunciationDailyLimit": 50,
        "serverNow": now,
        "nextResetAt": (now // DAY_MILLIS + 1) * DAY_MILLIS,
    }
