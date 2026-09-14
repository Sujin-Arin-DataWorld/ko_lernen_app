# Alert policy metric sources

Every metric type used under `tool/ops/alert_policies/*.json` is listed here with
the Google Cloud docs page fetched (via WebFetch) and, where the docs page itself
could not be scraped in full (several `docs.cloud.google.com/monitoring/api/metrics_gcp_*`
reference pages are too large for automatic text extraction), the **live**
verification performed against the real `ko-lernen-app` GCP project on
**2026-09-14** using `gcloud auth print-access-token` + a read-only
`GET https://monitoring.googleapis.com/v3/projects/ko-lernen-app/metricDescriptors`
call (no resources were created, updated, or deleted). Live introspection against
the actual project is at least as authoritative as the docs for confirming a
metric type/label exists and is spelled correctly.

## 01_functions_5xx_rate.json — `run.googleapis.com/request_count`

- **Status:** VERIFIED
- **Docs fetched:** `https://cloud.google.com/monitoring/api/metrics_gcp` (redirects
  to `docs.cloud.google.com/monitoring/api/metrics_gcp`, points to the per-letter
  Cloud Run reference) and `https://cloud.google.com/functions/docs/monitoring/metrics`
  (confirms 2nd-gen Cloud Functions execution is recorded via Cloud Run metrics:
  "Cloud Monitoring records metrics regarding the execution of Cloud Run").
- **Live confirmation:** `metricDescriptors.list` filtered to
  `metric.type=starts_with("run.googleapis.com/request")` returned
  `run.googleapis.com/request_count` (metricKind `DELTA`, valueType `INT64`) with
  labels `response_code`, `response_code_class`, `route`, on monitored resource
  types `cloud_run_instance` and `cloud_run_revision`. `resource.label.service_name`
  is the per-service grouping field used in the alert's `groupByFields`.
- **Ratio-alert schema:** `https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.alertPolicies#MetricThreshold`
  — confirms `denominatorFilter` + `denominatorAggregations` are the documented way
  to alert on a ratio (numerator filter = 5xx subset, denominator filter = all
  requests, matching aggregation alignment/labels on both sides).
- **Applies to:** gye-firebase-functions, tts-firebase-functions,
  pronunciation-firebase-functions and analyze-korean-text (all 2nd-gen, deployed
  as Cloud Run services in europe-west3 — confirmed via
  `gcloud run services list --project=ko-lernen-app --region=europe-west3`).

## 02_appcheck_rejections.json — `firebaseappcheck.googleapis.com/services/verification_count`

- **Status:** VERIFIED (live API; docs page text extraction was not feasible)
- **Docs fetched:** `https://cloud.google.com/monitoring/api/metrics_gcp` →
  points to the D–H reference page for `firebaseappcheck.googleapis.com`; that
  page (`docs.cloud.google.com/monitoring/api/metrics_gcp_d_h`) is too large for
  WebFetch's extraction step to reach the "F" section (confirmed with an explicit
  "search for the literal string" request, which returned "NOT FOUND IN CONTENT").
  `https://firebase.google.com/docs/app-check/monitor-metrics` was also fetched;
  it documents the Firebase console's App Check metrics UI (buckets: Verified,
  Outdated client, Unknown origin, Invalid, Reused token) but does not surface the
  underlying Cloud Monitoring metric type string.
- **Live confirmation:** `metricDescriptors.list` filtered to
  `metric.type=starts_with("firebaseappcheck")` returned
  `firebaseappcheck.googleapis.com/services/verification_count` (and
  `.../services/verdict_count`, `.../resources/verification_count`) with labels
  `result` (one of `ALLOW`, `DENY`) and `security` (one of `VALID`, `CONSUMED`,
  `INVALID`, `MISSING...`), on monitored resource type
  `firebaseappcheck.googleapis.com/Service`. The alert filters on `result="DENY"`.

## 03_ai_cost_breaker_unavailable.json — two custom log-based metrics

- **Status:** VERIFIED (these are metrics *this PR defines*, not built-in GCP metrics)
- **Docs fetched:** `https://cloud.google.com/logging/docs/logs-based-metrics/counter-metrics`
  (redirects to `docs.cloud.google.com/logging/docs/logs-based-metrics/counter-metrics`)
  — confirms `gcloud logging metrics create METRIC_NAME --description=... --log-filter=...`
  syntax and that a user-defined counter metric is addressed in Cloud Monitoring as
  `logging.googleapis.com/user/METRIC_ID`.
- **Metric 1:** `logging.googleapis.com/user/ai_cost_breaker_unavailable` — counts
  log entries matching `AI cost approval unavailable`, thrown as
  `ServiceCostError('unavailable', 'AI cost approval unavailable.')` in
  `functions/pronunciation/service_cost_policy.js:23` and
  `functions/tts/service_cost_policy.js:23` (confirmed by grep against this repo
  on 2026-09-14).
- **Metric 2:** `logging.googleapis.com/user/apple_revocation_config_invalid` —
  counts log entries matching `apple/revocation-config-invalid`, the error code
  thrown by `functions/gye/apple_revocation_adapter.js` and consumed in
  `functions/gye/account_operations_runtime.js` (confirmed by grep against this
  repo on 2026-09-14).
- Both log filters match `textPayload` and `jsonPayload.message` (structured vs.
  unstructured logging is not verified per-callsite in this PR — the filter is
  intentionally broad; see `docs/runbooks/ops-alerts.md#03` for the caveat).

## 04_deletion_worker_stalled.json — `cloudscheduler.googleapis.com/job/execution_count`

- **Status:** `_unverified: true` — kept per the "keep the policy but flag the gap"
  instruction.
- **Docs attempted:** `https://cloud.google.com/scheduler/docs/monitoring` (redirects
  to `docs.cloud.google.com/scheduler/docs/monitoring`, which returned **HTTP 404**
  on 2026-09-14) and `docs.cloud.google.com/monitoring/api/metrics_gcp_c` (an
  explicit "search for the literal string cloudscheduler.googleapis.com" request
  returned "NOT FOUND IN CONTENT" — the page's extracted content ends inside the
  Cloud SQL section).
- **Live check gap:** `metricDescriptors.list` filtered to
  `metric.type=starts_with("cloudscheduler.googleapis.com")` and to
  `metric.type=has_substring("scheduler")` both returned **zero**
  `cloudscheduler.googleapis.com/*` descriptors for `ko-lernen-app` on 2026-09-14,
  even though `cloudscheduler.googleapis.com` is an enabled API
  (`gcloud services list --enabled`) and
  `firebase-schedule-account_deletion_worker-europe-west3` is an ENABLED job
  running every 5 minutes (`gcloud scheduler jobs list --location=europe-west3`).
  `metricDescriptors.list` for this namespace appears to only register once a
  time series has actually been written under that exact type in this project's
  Monitoring backend, and the query attempts here were not sufficient to surface
  it.
- **What's used anyway:** `cloudscheduler.googleapis.com/job/execution_count` is
  Google's publicly documented, widely-used metric name for job execution counts
  (Cloud Scheduler's own console alerting recipe references it), with monitored
  resource `cloud_scheduler_job` (labels `project_id`, `job_id`, `location`) — but
  this PR could not independently re-derive that from a fetched doc page or a live
  descriptor for this specific project. **Jin: before relying on this alert, run
  `gcloud alpha monitoring policies create --dry-run` (see `apply_alerts.sh`) or
  open Metrics Explorer and search "Cloud Scheduler Job" to confirm the metric
  resolves for `ko-lernen-app`.**

## 05_firestore_write_surge.json — `firestore.googleapis.com/document/write_count`

- **Status:** VERIFIED
- **Docs fetched:** `https://cloud.google.com/firestore/docs/monitor-usage`
  (redirects to `docs.cloud.google.com/firestore/docs/monitor-usage`) — documents
  "Document Writes" as "The number of successful document writes. You can break
  the metric down by the type of write: CREATE or UPDATE," on monitored resource
  `firestore.googleapis.com/Database`.
- **Live confirmation:** `metricDescriptors.list` filtered to
  `metric.type=starts_with("firestore.googleapis.com/document")` returned
  `firestore.googleapis.com/document/write_count` ("The number of successful
  document writes") with labels `module`, `version`, `op` (`CREATE`/`UPDATE`), plus
  the related `write_ops_count`, `read_count`, `delete_count` siblings.
- **Daily-target vs. alert-window note:** the plan's target is >200,000 writes/day;
  this policy alerts on a >10,000/15-min proxy instead (see the policy's own
  `documentation.content` for the arithmetic). This is a deliberate simplification,
  not a verification gap.
