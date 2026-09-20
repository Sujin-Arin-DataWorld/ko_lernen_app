# Dynamic TTS quotas

Fresh synthesis reserves four request counters and the existing service-cost
budget in one Firestore transaction:

| Counter | Limit | Window |
|---|---:|---|
| Installation | 30 | UTC day |
| Account | 50 | UTC day |
| Project | 300 | UTC day |
| Project | 25 | UTC hour |

The hourly cap is additive. A UTC-hour rollover does not reset the daily caps.
All reads, including cost approval, finish before any writes. A blocked or
malformed counter prevents every request counter and cost reservation from being
written. Cached audio does not consume these synthesis counters.

The new document is `usage/tts_global_hour_YYYY-MM-DDTHH`. It shares the existing
`kind: tts` and `expiresAt` retention fields, with `scope: global_hour` and an
explicit `hour` field. Daily document IDs remain unchanged. Installation/account
identifiers remain hashed. Expiry metadata alone does not prove live TTL policy
execution.

The callable captures one reservation time and uses it for both refund paths:
a cache object appearing after reservation, and a failed synthesis/save. This
prevents an operation crossing an hour or midnight from reducing another bucket.
Request-counter refunds never refund uncertain service-cost reservations.

## Error response compatibility

New app requests include `errorReasonVersion: "1"`. For an hourly denial they
receive `resource-exhausted` with `details.reason: quota_global_hour`. The app
shows the hourly message and does not retry synthesis. Daily denials keep their
existing classification; missing or unknown details do not imply an hourly cap.

Older clients call all `resource-exhausted` responses a daily limit. On an hourly
denial they therefore receive the existing `unavailable` / `TTS audio is not
available.` response, which stops retries and uses their general audio-unavailable
message. The version field affects only the error response, never quota
enforcement, cache scope, account checks, App Check, or cost approval.

## Remaining CP2026 B3 work

These changes cover hourly quotas and quota-specific reasons. Session versus
policy reasons, anonymous account-creation observation and B1 metric integration
remain separate requirements. Anonymous TTS request counts are not account
creation counts. Code and local tests do not establish a live deployment or
operational observation period.
