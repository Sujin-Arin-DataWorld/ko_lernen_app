# Alert policy metric sources

Policy definitions are not deployment or incident-delivery receipts. Read-only
checks on **2026-09-22** in `ko-lernen-app` found zero alert policies and zero
notification channels. No service, metric, policy or channel was changed by
these checks. All three built-in metric descriptors below returned DELTA/INT64.

## 01_functions_5xx_rate.json — Cloud Run request count

**VERIFIED descriptor:** `run.googleapis.com/request_count`; response_code,
response_code_class and route labels. The per-service 5xx/all ratio and 2%/5min
threshold are unchanged. The filter covers Cloud Run revisions in the project;
service list examples in old documentation are not an allowlist.

[Cloud Run metrics](https://docs.cloud.google.com/run/docs/monitoring)
and [ratio condition schema](https://docs.cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.alertPolicies#MetricThreshold).

## 02_appcheck_rejections.json — App Check verification count

**VERIFIED descriptor:** `firebaseappcheck.googleapis.com/services/verification_count`,
with result, security and app_id labels. The DENY >50 / 5min policy is unchanged.
A separate read of the preceding 24h returned ALLOW=589 and no DENY series;
that is a bounded observation, not proof that every app/API is covered.

[App Check monitoring](https://firebase.google.com/docs/app-check/monitor-metrics).

## 03_ai_cost_breaker_unavailable.json — custom log counters

**UNVERIFIED emission; application blocked.** The filters for
`logging.googleapis.com/user/ai_cost_breaker_unavailable` and
`logging.googleapis.com/user/apple_revocation_config_invalid` are definitions,
not evidence of matching events. The previous claim that defining a metric
made it verified was incorrect. TTS catches ServiceCostError before its generic
error logger; a thrown message is not automatically a Cloud Logging entry.
Verify both deployed call sites, privacy-safe event schemas, filter matches
and received metric points before removing `_unverified`. Creating descriptors
alone with `log_metrics.sh` does not satisfy this requirement. Thresholds remain
>0 over 10min; no live cost approvals or limits changed.

[Log-based counter metrics](https://docs.cloud.google.com/logging/docs/logs-based-metrics/counter-metrics).

## 04_deletion_worker_stalled.json — Cloud Run HTTP success liveness

**VERIFIED input metric and observed time series; incident delivery unverified.**
A direct GET for the old `cloudscheduler.googleapis.com/job/execution_count`
descriptor returned HTTP 404 on 2026-09-22. The former claim that this exact
metric was documented was unsupported. It is replaced with
`run.googleapis.com/request_count`, restricted to project `ko-lernen-app`,
location `europe-west3`, service `account-deletion-worker`, response class `2xx`.
A live preceding-24h query returned 288 successful responses; Scheduler was
ENABLED with a five-minute UTC schedule. Request success does not measure
queue completion, individual account erasure or Apple token revocation.

The threshold sums across revisions in 300s windows; <1 success for 89700s
(24h55m) violates. Alignment plus retest is 90000s, within the documented 25h
evaluation limit; a 90000s retest plus 300s alignment would exceed that limit. Missing data evaluates as active after the retest duration.
This catches zero-valued windows as well as missing telemetry, unlike checking
only whether points arrive. Before creation, the operator requires a positive
matching series within 24h. An empty series cannot be treated as a healthy
or armed alert. Alignment/ingestion introduce delay; actual incident delivery
and queue-age monitoring still need operational evidence.

[Alert evaluation quotas](https://docs.cloud.google.com/monitoring/quotas),
[Missing-data and threshold schema](https://docs.cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.alertPolicies#MetricThreshold),
[Scheduler execution logs](https://docs.cloud.google.com/scheduler/docs/viewing-logs).

## 05_firestore_write_surge.json — Firestore writes

**VERIFIED descriptor:** `firestore.googleapis.com/document/write_count`, with
module, version and op labels. >10,000 writes/15min remains a burst proxy for
the 200,000/day target, not a measured rolling daily cap.

On **2026-09-23**, the live descriptor declared only `firestore_instance` as
its monitored resource type. The former `firestore.googleapis.com/Database`
filter returned HTTP 400 (incompatible metric/resource pair). The corrected
filter returned actual write counter points. Preflight now checks every
numerator and denominator resource type against its metric descriptor before
any policy creation. Missing or malformed resource metadata also blocks apply.
This correction does not create a notification channel, deploy a policy or
prove an alert was delivered.

[Firestore usage monitoring](https://docs.cloud.google.com/firestore/docs/monitor-usage).

## Application prerequisites and remaining evidence

The shared Python apply tool performs read-only channel/descriptor/series and
full paginated policy checks before creating any selected policy. Matching
existing policies are skipped; drift/duplicates fail. No automatic retry,
update, delete, channel verification or test incident is sent. Channel
`UNVERIFIED` means non-functioning; an unspecified verification state can be
valid for a type that does not require verification, while disabled channels
always fail preflight.

[Notification channel status](https://docs.cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.notificationChannels).
Actual channel delivery, alert firing/recovery, deletion queue liveness and
14-day quality observations are separate unfinished gates.
