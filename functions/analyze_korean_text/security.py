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
import time
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import TimeoutError as FuturesTimeout
from dataclasses import dataclass
from typing import Any, Callable, Mapping, Sequence


DEFAULT_ALLOWED_APP_IDS = frozenset(
    {
        "1:573567222361:android:38d26a50001ee64c356748",
        "1:573567222361:ios:0f8c0734410bb6cc356748",
    }
)
QUOTA_COLLECTION = "service_quotas"
QUOTA_LEDGER_COLLECTION = "service_quota_ledgers"
IDEMPOTENCY_COLLECTION = "service_idempotency"
QUOTA_SCOPE = "book_analysis_v1"
DAILY_LIMIT = 20
BURST_LIMIT = 3
BURST_WINDOW_SECONDS = 60
KKEUNMARI_QUOTA_SCOPE = "kkeunmari_dictionary_v1"
QUOTA_LEDGER_TTL_DAYS = 2
IDEMPOTENCY_TTL_MINUTES = 15
DEEPL_HTTP_TIMEOUT_SECONDS = 6.0
DEEPL_HTTP_MAX_RETRIES = 0
DEEPL_CALL_DEADLINE_SECONDS = 8.0
DEEPL_MIN_CALL_SECONDS = 0.25
_DEADLINE_EXECUTOR: ThreadPoolExecutor | None = None


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


class CircuitBreaker:
    """In-process fail-fast guard for DeepL, Azure, and Cloud TTS."""

    def __init__(
        self,
        *,
        failure_threshold: int = 5,
        cooldown_seconds: float = 30.0,
        clock: Callable[[], float] | None = None,
    ):
        self.failure_threshold = failure_threshold
        self.cooldown_seconds = cooldown_seconds
        self._clock = clock or (
            lambda: dt.datetime.now(dt.timezone.utc).timestamp()
        )
        self._failures = 0
        self._opened_at: float | None = None

    def allow(self) -> bool:
        if self._opened_at is None:
            return True
        return self._clock() - self._opened_at >= self.cooldown_seconds

    def record_success(self) -> None:
        self._failures = 0
        self._opened_at = None

    def record_failure(self) -> None:
        now = self._clock()
        if (
            self._opened_at is not None
            and now - self._opened_at >= self.cooldown_seconds
        ):
            self._failures = self.failure_threshold
            self._opened_at = now
            return
        self._failures += 1
        if self._failures >= self.failure_threshold:
            self._opened_at = now


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
    """Reads a comma-separated allowlist for the configured Android/iOS apps."""
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


def quota_expires_at(now: dt.datetime) -> dt.datetime:
    """Keep daily ledgers just long enough for UTC rollover, then TTL them."""
    utc_now = now.astimezone(dt.timezone.utc)
    return dt.datetime.combine(
        utc_now.date() + dt.timedelta(days=QUOTA_LEDGER_TTL_DAYS),
        dt.time.min,
        tzinfo=dt.timezone.utc,
    )


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


def release_quota_state(
    state: QuotaState,
    now: dt.datetime,
    *,
    policy: QuotaPolicy = BOOK_ANALYSIS_QUOTA_POLICY,
) -> QuotaState:
    """Undo one successful consume from the same UTC day and burst window."""
    utc_now = now.astimezone(dt.timezone.utc)
    day = utc_now.date().isoformat()
    if state.day != day:
        return state
    elapsed = utc_now.timestamp() - state.burst_window_started_at
    burst_count = (
        state.burst_count if 0 <= elapsed < policy.burst_window_seconds else 0
    )
    return QuotaState(
        day=day,
        daily_count=max(0, state.daily_count - 1),
        burst_window_started_at=state.burst_window_started_at,
        burst_count=max(0, burst_count - 1) if burst_count else 0,
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

    def _ledger_reference(self, uid: str) -> Any:
        return self._client().collection(QUOTA_LEDGER_COLLECTION).document(
            quota_document_id(uid, scope=self._scope)
        )

    def _payload(self, updated: QuotaState, now: dt.datetime) -> dict[str, Any]:
        return {
            "day": updated.day,
            "dailyCount": updated.daily_count,
            "burstWindowStartedAt": updated.burst_window_started_at,
            "burstCount": updated.burst_count,
            "updatedAtUnix": int(now.timestamp()),
            "expiresAt": quota_expires_at(now),
            "scope": self._scope,
        }

    def consume(self, uid: str) -> QuotaState:
        """Atomically consumes one quota unit or raises without allowing work."""
        try:
            from google.cloud import firestore  # type: ignore

            client = self._client()
            reference = self._ledger_reference(uid)
            transaction = client.transaction()
            now = self._now().astimezone(dt.timezone.utc)

            @firestore.transactional
            def consume_in_transaction(transaction: Any) -> QuotaState:
                snapshot = reference.get(transaction=transaction)
                current = _quota_state_from_document(
                    snapshot.to_dict() if snapshot.exists else None
                )
                updated = consume_quota_state(current, now, policy=self._policy)
                transaction.set(reference, self._payload(updated, now))
                return updated

            return consume_in_transaction(transaction)
        except QuotaExceeded:
            raise
        except Exception as error:
            raise QuotaStoreUnavailable() from error

    def release(self, uid: str) -> QuotaState | None:
        """Refund one unit after a paid provider or engine failure."""
        try:
            from google.cloud import firestore  # type: ignore

            client = self._client()
            reference = self._ledger_reference(uid)
            transaction = client.transaction()
            now = self._now().astimezone(dt.timezone.utc)

            @firestore.transactional
            def release_in_transaction(transaction: Any) -> QuotaState | None:
                snapshot = reference.get(transaction=transaction)
                if not snapshot.exists:
                    return None
                current = _quota_state_from_document(snapshot.to_dict())
                updated = release_quota_state(current, now, policy=self._policy)
                transaction.set(reference, self._payload(updated, now))
                return updated

            return release_in_transaction(transaction)
        except Exception as error:
            raise QuotaStoreUnavailable() from error


def analysis_request_id(
    uid: str,
    lang: str,
    text: str,
    units: Sequence[Mapping[str, str]] | None,
) -> str:
    """Hash a retryable book-analysis request without using the raw uid as an id."""

    unit_blob = ""
    if units:
        unit_blob = "\n".join(
            f"{unit.get('id', '')}\t{unit.get('kind', '')}\t{unit.get('korean', '')}"
            for unit in units
        )
    return hashlib.sha256(
        f"book_analysis_v1\0{uid}\0{lang}\0{text}\0{unit_blob}".encode("utf-8")
    ).hexdigest()


def idempotency_expires_at(now: dt.datetime) -> dt.datetime:
    return now.astimezone(dt.timezone.utc) + dt.timedelta(
        minutes=IDEMPOTENCY_TTL_MINUTES
    )


def idempotency_payload(
    kind: str,
    now: dt.datetime,
    *,
    state: str = "completed",
) -> dict[str, Any]:
    """Server-only receipt: kind, state, and TTL. Never source text or scores."""

    return {
        "kind": kind,
        "state": state,
        "expiresAt": idempotency_expires_at(now),
    }


def _as_utc_datetime(value: Any) -> dt.datetime | None:
    if isinstance(value, dt.datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=dt.timezone.utc)
        return value.astimezone(dt.timezone.utc)
    timestamp = getattr(value, "timestamp", None)
    if callable(timestamp):
        try:
            return dt.datetime.fromtimestamp(timestamp(), tz=dt.timezone.utc)
        except (TypeError, ValueError, OSError):
            return None
    return None


def is_current_idempotency(
    data: Mapping[str, Any] | None,
    now: dt.datetime,
    *,
    kind: str,
) -> bool:
    if not data or data.get("kind") != kind:
        return False
    state = str(data.get("state") or "completed")
    if state not in {"pending", "completed"}:
        return False
    expires_at = _as_utc_datetime(data.get("expiresAt"))
    if expires_at is None:
        return False
    return expires_at > now.astimezone(dt.timezone.utc)


class DeadlineBudget:
    """One wall-clock budget shared by every paid provider call in a request."""

    def __init__(
        self,
        seconds: float,
        *,
        clock: Callable[[], float] | None = None,
    ):
        self._clock = clock or time.monotonic
        self._deadline = self._clock() + max(0.0, float(seconds))

    def remaining(self) -> float:
        return max(0.0, self._deadline - self._clock())


def provider_timeout_seconds(budget: DeadlineBudget | None) -> float | None:
    """None means the shared budget is already too small to start another call."""

    if budget is None:
        return DEEPL_CALL_DEADLINE_SECONDS
    remaining = budget.remaining()
    if remaining < DEEPL_MIN_CALL_SECONDS:
        return None
    return min(DEEPL_CALL_DEADLINE_SECONDS, remaining)


def run_with_deadline(
    func: Callable[..., Any],
    *args: Any,
    timeout_seconds: float,
    **kwargs: Any,
) -> Any:
    """Fail a hung provider call so quota refund can still run."""

    global _DEADLINE_EXECUTOR
    if _DEADLINE_EXECUTOR is None:
        _DEADLINE_EXECUTOR = ThreadPoolExecutor(
            max_workers=2,
            thread_name_prefix="provider-deadline",
        )
    future = _DEADLINE_EXECUTOR.submit(func, *args, **kwargs)
    try:
        return future.result(timeout=timeout_seconds)
    except FuturesTimeout as error:
        raise TimeoutError("provider_deadline_exceeded") from error


def configure_deepl_http_deadlines() -> None:
    """Stop DeepL's 10s×5 retry loop from outliving the client timeout."""

    import deepl.http_client as http_client  # type: ignore

    http_client.min_connection_timeout = DEEPL_HTTP_TIMEOUT_SECONDS
    http_client.max_network_retries = DEEPL_HTTP_MAX_RETRIES


class FirestoreIdempotencyGate:
    """Short-lived server-only receipts so identical retries skip a second charge."""

    def __init__(
        self,
        *,
        firestore_client: Any | None = None,
        now: Callable[[], dt.datetime] | None = None,
    ):
        self._firestore_client = firestore_client
        self._now = now or (lambda: dt.datetime.now(dt.timezone.utc))

    def _client(self) -> Any:
        if self._firestore_client is not None:
            return self._firestore_client
        from google.cloud import firestore  # type: ignore

        self._firestore_client = firestore.Client()
        return self._firestore_client

    def _reference(self, document_id: str) -> Any:
        return self._client().collection(IDEMPOTENCY_COLLECTION).document(
            document_id
        )

    def seen(self, document_id: str, *, kind: str) -> bool:
        try:
            snapshot = self._reference(document_id).get()
            if not snapshot.exists:
                return False
            return is_current_idempotency(
                snapshot.to_dict(),
                self._now(),
                kind=kind,
            )
        except Exception:
            return False

    def claim(self, document_id: str, *, kind: str) -> bool:
        """Reserve the receipt before quota. True means this caller must consume."""

        try:
            reference = self._reference(document_id)
            now = self._now().astimezone(dt.timezone.utc)
            client = self._client()
            if getattr(client, "transaction", None) is None:
                return self._claim_once(reference, kind, now)
            from google.cloud import firestore  # type: ignore

            transaction = client.transaction()

            @firestore.transactional
            def claim_in_transaction(transaction: Any) -> bool:
                snapshot = reference.get(transaction=transaction)
                data = snapshot.to_dict() if snapshot.exists else None
                if is_current_idempotency(data, now, kind=kind):
                    return False
                transaction.set(
                    reference,
                    idempotency_payload(kind, now, state="pending"),
                )
                return True

            return claim_in_transaction(transaction)
        except Exception:
            return True

    def _claim_once(self, reference: Any, kind: str, now: dt.datetime) -> bool:
        snapshot = reference.get()
        data = snapshot.to_dict() if snapshot.exists else None
        if is_current_idempotency(data, now, kind=kind):
            return False
        reference.set(idempotency_payload(kind, now, state="pending"))
        return True

    def complete(self, document_id: str, kind: str) -> None:
        try:
            self._reference(document_id).set(
                idempotency_payload(kind, self._now(), state="completed")
            )
        except Exception:
            return

    def remember(self, document_id: str, kind: str) -> None:
        self.complete(document_id, kind)

    def abandon(self, document_id: str, kind: str) -> None:
        """Drop an in-flight pending receipt so a later retry can be charged."""

        try:
            reference = self._reference(document_id)
            snapshot = reference.get()
            if not snapshot.exists:
                return
            data = snapshot.to_dict() or {}
            if data.get("kind") != kind or data.get("state") != "pending":
                return
            delete = getattr(reference, "delete", None)
            if delete is not None:
                delete()
        except Exception:
            return
