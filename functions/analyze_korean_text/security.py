"""Authentication and quota guards for the book-analysis HTTP function.

All verification dependencies are imported lazily so policy tests can run
without Google credentials. Production calls fail closed if either Firebase
verification or the Firestore transaction is unavailable.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import math
import os
from dataclasses import dataclass
from typing import Any, Callable, Mapping


DEFAULT_ALLOWED_APP_IDS = frozenset(
    {"1:573567222361:android:38d26a50001ee64c356748"}
)
QUOTA_COLLECTION = "service_quotas"
QUOTA_SCOPE = "book_analysis_v1"
DAILY_LIMIT = 20
BURST_LIMIT = 3
BURST_WINDOW_SECONDS = 60
KKEUNMARI_QUOTA_SCOPE = "kkeunmari_dictionary_v1"


@dataclass(frozen=True)
class QuotaPolicy:
    daily_limit: int
    burst_limit: int
    burst_window_seconds: int


BOOK_ANALYSIS_QUOTA_POLICY = QuotaPolicy(
    daily_limit=DAILY_LIMIT,
    burst_limit=BURST_LIMIT,
    burst_window_seconds=BURST_WINDOW_SECONDS,
)
KKEUNMARI_DICTIONARY_QUOTA_POLICY = QuotaPolicy(
    daily_limit=120,
    burst_limit=12,
    burst_window_seconds=60,
)


class AuthenticationFailed(Exception):
    """The request did not have verified Firebase Auth and App Check tokens."""


class QuotaStoreUnavailable(Exception):
    """The quota transaction could not be completed safely."""


class QuotaExceeded(Exception):
    def __init__(self, retry_after_seconds: int):
        super().__init__("quota exceeded")
        self.retry_after_seconds = max(1, retry_after_seconds)


@dataclass(frozen=True)
class Caller:
    uid: str
    app_id: str


@dataclass(frozen=True)
class QuotaState:
    day: str
    daily_count: int
    burst_window_started_at: float
    burst_count: int


def allowed_firebase_app_ids() -> frozenset[str]:
    """Reads a comma-separated allowlist; defaults to the released Android app."""
    configured = {
        item.strip()
        for item in os.environ.get("ALLOWED_FIREBASE_APP_IDS", "").split(",")
        if item.strip()
    }
    return frozenset(configured) if configured else DEFAULT_ALLOWED_APP_IDS


def _header(request: Any, name: str) -> str:
    headers = getattr(request, "headers", {})
    value = headers.get(name, "") if headers is not None else ""
    return str(value).strip()


def _bearer_token(request: Any) -> str:
    value = _header(request, "Authorization")
    scheme, separator, token = value.partition(" ")
    if scheme.lower() != "bearer" or not separator or not token.strip():
        raise AuthenticationFailed()
    return token.strip()


def _firebase_app() -> Any:
    import firebase_admin  # type: ignore

    try:
        return firebase_admin.get_app()
    except ValueError:
        return firebase_admin.initialize_app()


def _verify_app_check(token: str) -> Mapping[str, Any]:
    _firebase_app()
    from firebase_admin import app_check  # type: ignore

    return app_check.verify_token(token)


def _verify_auth(token: str, *, check_revoked: bool) -> Mapping[str, Any]:
    _firebase_app()
    from firebase_admin import auth  # type: ignore

    return auth.verify_id_token(token, check_revoked=check_revoked)


def verify_caller(
    request: Any,
    *,
    verify_app_check: Callable[[str], Mapping[str, Any]] | None = None,
    verify_auth: Callable[..., Mapping[str, Any]] | None = None,
    allowed_app_ids: set[str] | frozenset[str] | None = None,
) -> Caller:
    """Returns a caller only after both Firebase token types are verified."""
    app_check_token = _header(request, "X-Firebase-AppCheck")
    if not app_check_token:
        raise AuthenticationFailed()

    try:
        app_check_claims = (verify_app_check or _verify_app_check)(app_check_token)
        app_id = str(app_check_claims.get("sub", "")).strip()
        allowed = (
            frozenset(allowed_app_ids)
            if allowed_app_ids is not None
            else allowed_firebase_app_ids()
        )
        if not app_id or app_id not in allowed:
            raise AuthenticationFailed()

        auth_claims = (verify_auth or _verify_auth)(
            _bearer_token(request), check_revoked=True
        )
        uid = str(auth_claims.get("uid") or auth_claims.get("sub") or "").strip()
        if not uid:
            raise AuthenticationFailed()
        return Caller(uid=uid, app_id=app_id)
    except AuthenticationFailed:
        raise
    except Exception as error:
        raise AuthenticationFailed() from error


def quota_document_id(uid: str, *, scope: str = QUOTA_SCOPE) -> str:
    return hashlib.sha256(f"{scope}\0{uid}".encode("utf-8")).hexdigest()


def _as_nonnegative_int(value: Any) -> int:
    try:
        return max(0, int(value))
    except (TypeError, ValueError):
        return 0


def _retry_after_next_day(now: dt.datetime) -> int:
    next_day = dt.datetime.combine(
        now.date() + dt.timedelta(days=1), dt.time.min, tzinfo=dt.timezone.utc
    )
    return max(1, math.ceil((next_day - now).total_seconds()))


def consume_quota_state(
    state: QuotaState,
    now: dt.datetime,
    *,
    policy: QuotaPolicy = BOOK_ANALYSIS_QUOTA_POLICY,
) -> QuotaState:
    """Pure quota policy used inside the Firestore transaction and unit tests."""
    utc_now = now.astimezone(dt.timezone.utc)
    day = utc_now.date().isoformat()
    daily_count = state.daily_count if state.day == day else 0
    elapsed = utc_now.timestamp() - state.burst_window_started_at
    burst_count = (
        state.burst_count if 0 <= elapsed < policy.burst_window_seconds else 0
    )
    burst_started_at = (
        state.burst_window_started_at if burst_count else utc_now.timestamp()
    )

    if daily_count >= policy.daily_limit:
        raise QuotaExceeded(_retry_after_next_day(utc_now))
    if burst_count >= policy.burst_limit:
        raise QuotaExceeded(math.ceil(policy.burst_window_seconds - elapsed))

    return QuotaState(
        day=day,
        daily_count=daily_count + 1,
        burst_window_started_at=burst_started_at,
        burst_count=burst_count + 1,
    )


def _quota_state_from_document(data: Mapping[str, Any] | None) -> QuotaState:
    values = data or {}
    return QuotaState(
        day=str(values.get("day", "")),
        daily_count=_as_nonnegative_int(values.get("dailyCount")),
        burst_window_started_at=float(values.get("burstWindowStartedAt", 0) or 0),
        burst_count=_as_nonnegative_int(values.get("burstCount")),
    )


class FirestoreQuotaGate:
    """Consumes quota through a Firestore transaction, never a client counter."""

    def __init__(
        self,
        *,
        firestore_client: Any | None = None,
        now: Callable[[], dt.datetime] | None = None,
        scope: str = QUOTA_SCOPE,
        policy: QuotaPolicy = BOOK_ANALYSIS_QUOTA_POLICY,
    ):
        self._firestore_client = firestore_client
        self._now = now or (lambda: dt.datetime.now(dt.timezone.utc))
        self._scope = scope
        self._policy = policy

    def _client(self) -> Any:
        if self._firestore_client is not None:
            return self._firestore_client
        from google.cloud import firestore  # type: ignore

        self._firestore_client = firestore.Client()
        return self._firestore_client

    def consume(self, uid: str) -> QuotaState:
        """Atomically consumes one quota unit or raises without allowing work."""
        try:
            from google.cloud import firestore  # type: ignore

            client = self._client()
            reference = (
                client.collection(QUOTA_COLLECTION)
                .document(self._scope)
                .collection("users")
                .document(quota_document_id(uid, scope=self._scope))
            )
            transaction = client.transaction()
            now = self._now().astimezone(dt.timezone.utc)

            @firestore.transactional
            def consume_in_transaction(transaction: Any) -> QuotaState:
                snapshot = reference.get(transaction=transaction)
                current = _quota_state_from_document(
                    snapshot.to_dict() if snapshot.exists else None
                )
                updated = consume_quota_state(current, now, policy=self._policy)
                transaction.set(
                    reference,
                    {
                        "day": updated.day,
                        "dailyCount": updated.daily_count,
                        "burstWindowStartedAt": updated.burst_window_started_at,
                        "burstCount": updated.burst_count,
                        "updatedAtUnix": int(now.timestamp()),
                    },
                )
                return updated

            return consume_in_transaction(transaction)
        except QuotaExceeded:
            raise
        except Exception as error:
            raise QuotaStoreUnavailable() from error
