# Auth account-creation observation

`on_auth_account_created` observes Firebase Auth account-creation events. It is a
generation-1 event function in the existing Gye codebase, bounded to two instances,
128 MB and 30 seconds. It does not run in the sign-in request path or block signup.
Existing generation-2 functions keep their configuration.

Firebase documents creation events for anonymous sessions, provider/email signup
and Admin-created accounts. This observer uses the existing generation-1 Auth
trigger alongside the generation-2 account functions. Firebase now also documents
generation-2 Auth triggers as Preview; this change does not migrate to that API.
Custom-token first sign-in does not emit the generation-1
creation event. [Firebase Auth trigger contract](https://firebase.google.com/docs/functions/1st-gen/auth-events)
[Generation-2 preview](https://firebase.google.com/docs/functions/auth-events)

The log contains only `event`, `schemaVersion` and `accountKind`:

- `anonymous`: a valid record has no linked provider, email or phone. This includes
  Admin-created providerless accounts; it is not proof of a particular client SDK.
- `identified`: the record has a linked provider, email or phone.
- `unknown`: required identity fields are malformed or absent. Missing data must
  not silently increase the anonymous count.

UIDs, email addresses, phone numbers, tokens and raw event payloads are not logged.
The function does not read or write Firestore, send messages or change quotas.

`tool/ops/log_metrics.py` (also exposed through the Bash and PowerShell wrappers)
creates `auth_anonymous_account_created`. Its filter
selects this function's generation-1 resource and the versioned anonymous event.
In Monitoring, use `logging.googleapis.com/user/auth_anonymous_account_created`
with `ALIGN_SUM` over 300 seconds and `REDUCE_SUM` to observe a five-minute count.
The B1 runbook links this signal to App Check and service-usage investigation.
No unmeasured signup-blocking threshold or additional paging policy is enabled.

This counts delivered creation events, not unique users. Duplicates, delivery
delay or log loss can affect the observed rate; do not use it for billing or claim
exactly-once accounting. An empty chart before deployment, metric creation or a
known matching event is missing evidence, not evidence of zero account creation.

## Deployment verification still required

The reviewed source needs a separate deployment and live verification. Deploy only
`functions:gye-firebase-functions:on_auth_account_created` after the Gye codebase's
documented deployment prerequisites. Run the existing metric script, verify the
metric filter, and use an authorized test account to confirm a real anonymous
creation emits one matching event. A provider login, token refresh and TTS call
must not emit another creation event. Retain the runtime resource/trigger, event
and metric evidence without recording personal account attributes.
