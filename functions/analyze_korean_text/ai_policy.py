"""Server authority and shared atomic worst-case AI cost reservations."""
import datetime as dt
import os

from access_policy import bounded_text, entitlement_document_id, millis, resolve_access, safe_int


def resolve_book_policy(client, uid, transaction, now, account_created_at=None):
    environment = os.environ.get("ACCESS_ENVIRONMENT", "PRODUCTION")
    phase = os.environ.get("ACCESS_PHASE", "free_launch")
    grant = client.collection("premium_grants").document(uid).get(transaction=transaction)
    entitlement = client.collection("customer_entitlements").document(
        entitlement_document_id(uid, environment)).get(transaction=transaction)
    return resolve_access(uid=uid, environment=environment, phase=phase, now=now,
                          account_created_at=account_created_at,
                          grant=grant.to_dict() if grant.exists else None,
                          entitlement=entitlement.to_dict() if entitlement.exists else None)


def read_cost_control(client, transaction, now):
    snapshot = client.collection("service_cost_controls").document("ai_v1").get(transaction=transaction)
    config = snapshot.to_dict() if snapshot.exists else {}
    approved_at = millis(config.get("approvedAt"))
    if (type(config.get("schemaVersion")) not in (int, float) or config.get("schemaVersion") != 1 or
            config.get("approvedBy") != "Jin" or not bounded_text(config.get("approvalRef"), 512) or
            approved_at is None or approved_at > now.timestamp() * 1000 or
            not safe_int(config.get("dailyUnitLimit")) or
            not safe_int(config.get("bookReservationUnits")) or config["bookReservationUnits"] == 0 or
            not safe_int(config.get("pronunciationReservationUnits")) or config["pronunciationReservationUnits"] == 0 or
            not safe_int(config.get("ttsReservationUnits")) or config["ttsReservationUnits"] == 0):
        raise ValueError("ai_cost_approval_unavailable")
    return config


def prepare_cost_reservation(client, transaction, now, config, existing=None):
    day = now.date().isoformat()
    reference = client.collection("service_cost_ledgers").document(day)
    snapshot = reference.get(transaction=transaction)
    previous = snapshot.to_dict() if snapshot.exists else {"reservedUnits": 0}
    if not safe_int(previous.get("reservedUnits")):
        raise ValueError("ai_cost_ledger_unavailable")
    if (existing and existing.get("day") == day and safe_int(existing.get("units")) and
            existing["units"] >= config["bookReservationUnits"] and snapshot.exists):
        if previous["reservedUnits"] > config["dailyUnitLimit"] or previous["reservedUnits"] < existing["units"]:
            from security import QuotaExceeded
            raise QuotaExceeded(60)
        return {"reservation": existing}
    units = config["bookReservationUnits"]
    if previous["reservedUnits"] > config["dailyUnitLimit"] - units:
        # Imported lazily: security also imports this module for its seam.
        from security import QuotaExceeded
        midnight = dt.datetime.combine(now.date() + dt.timedelta(days=1), dt.time.min, tzinfo=dt.timezone.utc)
        raise QuotaExceeded(int((midnight - now).total_seconds()) + 1)
    return {"reservation": {"day": day, "units": units}, "reference": reference,
            "payload": {"schemaVersion": 1, "day": day, "reservedUnits": previous["reservedUnits"] + units,
                        "updatedAt": now, "expiresAt": dt.datetime.combine(
                            now.date() + dt.timedelta(days=2), dt.time.min, tzinfo=dt.timezone.utc)}}
