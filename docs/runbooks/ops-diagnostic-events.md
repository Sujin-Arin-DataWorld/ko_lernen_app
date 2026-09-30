# Fixed operational diagnostics

These events connect existing request failures to the counters in
`tool/ops/log_metrics.sh`. They do not change approval, quota, App Check,
authentication, retry, or account-deletion decisions. Logging failure must not
change the response or interrupt a deletion checkpoint.

| Boundary | Fixed message | Bounded metadata | Trigger |
|---|---|---|---|
| TTS / pronunciation callable catch, outside transaction retries | `AI cost approval unavailable.` | `event=ai_cost_approval_unavailable`, `service=tts` or `pronunciation`, `schemaVersion=1` | Typed `ServiceCostError` with the internal `approval_unavailable` reason from approval validation |
| Early or pending Apple revocation callable catch | `apple/revocation-config-invalid` | `event=apple_revocation_config_invalid`, `schemaVersion=1` | Existing configuration error that leads to the manual-revocation-required checkpoint |

Each matching callable execution emits at most one diagnostic. Counts represent
error occurrences, not distinct users, unique incidents or unique accounts.
Repeated client calls can produce repeated entries. Normal service-budget
exhaustion, a corrupt cost ledger, successful calls and generic provider errors
do not produce an approval-unavailable event. Apple network/provider failures
retain their existing resumable behavior and do not become configuration alarms.

Never attach the error object or message, UID, email, IP, token, authorization
code, account/operation ID, cost-control document, reference text or audio. Only
the fixed message and listed metadata are emitted. The internal cost reason is
not added to the client API response: existing TTS `service_policy` details and
other response contracts stay unchanged.

## Validation and rollout boundary

Regression tests exercise the actual callable entrypoints with in-memory
Firestore/Auth/provider adapters. Missing and invalid approval must both reject
before a paid call and emit the fixed event. Valid approval, budget exhaustion
and corrupt ledgers must not emit a false approval alarm. Early and late Apple
paths must retain truthful `appleManualRevocationRequired` state without claiming
revocation; a broken log sink must not prevent the checkpoint.

Source tests alone do not prove live log delivery. The focused function changes
still need exact-head and merged-main checks, a reviewed function rollout and
actual structured/text log evidence before policy 03 is enabled. Follow the
readiness checks in `ops-alerts.md`. Preserve existing notification settings and
cost approvals. Do not trigger real account deletion or disable a production
approval document to manufacture an error signal.
