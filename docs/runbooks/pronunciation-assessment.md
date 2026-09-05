# Pronunciation assessment runbook

This runbook verifies the optional pronunciation assessment path without
printing speech audio, Korean reference text, account identifiers, or secret
values. It does not authorize a deploy. Run deployment and physical-device
checks only in their separately approved release step.

## Beta cost policy

Beta builds default to local recording practice. The Dart define
`ENABLE_FREE_PRONUNCIATION_ASSESSMENT` defaults to `false`. It controls only
whether scored assessment is offered; it does not change content access or the
common server quota. Stopping a recording does not upload it. Learners can replay
their recording on the device and continue without a scored result. Temporary
recording playback files, where required by the platform, are separate from
the model-voice cache and are removed when the recording is discarded.
Existing model-voice TTS is unchanged; it is the user's explicit cost exception.

The callable also defaults to disabled. Unless
`PRONUNCIATION_ASSESSMENT_MODE=azure_f0`, it rejects requests before accessing
Auth, Firestore or a secret and before contacting Azure. It has no warm instances,
at most one instance, and one concurrent request. Disabled deployments bind no
secret, including at cold start. Redeploy when changing this server mode so
the secret binding matches it. There is no paid fallback.

Free assessment must remain disabled until all of the following are verified:

1. The Azure resource associated with `AZURE_SPEECH_KEY` is a dedicated
   `SpeechServices` resource with SKU **F0** in **germanywestcentral**. Verify
   the resource itself, not a key's name or the presence of trial credit. For
   example, with the resource owner signed in to Azure CLI:

   ```powershell
   az cognitiveservices account show --resource-group <resource-group> `
     --name <speech-resource> `
     --query '{name:name,kind:kind,location:location,sku:sku.name}' --output json
   ```

2. The secret is bound to that verified F0 resource through the approved
   secret-management process. Never copy it into the app, a Dart define, Git,
   screenshots, or command output. The application mode is an activation
   switch, not a live Azure SKU check. Recheck the resource after any key,
   resource, or billing-tier change; an S0 resource is not approved for beta.
3. Verify the existing server-owned `service_cost_controls/ai_v1` approval
   and daily reservation budget. The F0 switch does not bypass the shared AI
   cost gate or the same server-owned per-user quota applied to every
   authenticated learner. Missing, malformed, unapproved, or exhausted cost
   controls still block assessment.
   Do not create or raise this approval merely to make a smoke test pass.
4. Only then set `PRONUNCIATION_ASSESSMENT_MODE=azure_f0` in the pronunciation
   codebase's deployment environment and build the approved client with
   `--dart-define=ENABLE_FREE_PRONUNCIATION_ASSESSMENT=true`. Missing or
   unverified settings stay disabled. The normal release approval, exact-SHA
   CI, consent, Auth, App Check, and signed-device gates still apply.

The server reserves rounded-up audio seconds in the private document
`service_usage/pronunciation_free_YYYY-MM` in the same Firestore transaction
that commits the receipt's `claimed` to `pending` dispatch transition, before
sending audio. A reclaimed, undispatched request uses the UTC month of its
actual dispatch. The shared
limit is 18,000 seconds per UTC calendar month across all learners, in addition
to the existing per-user limits. The document contains aggregate usage and an
update timestamp, never audio, reference text, or learner identifiers. The
default-deny Firestore rule keeps it inaccessible to clients. A failed or
timed-out provider call does not refund this monthly reservation because the
audio might already have been processed. A completed replay costs no further
audio allowance; an in-flight duplicate is not sent again.

## Auth, authority, and request receipts

An enabled request validates Auth and an unused App Check token, then reads
the current Auth user once outside the retryable Firestore transaction.
Missing, disabled, or mismatched users are rejected. Server Auth creation
time fences entitlement documents against reuse after account recreation.
The `account_deletions` marker is checked on receipt claim and every
transition, including completed-result retrieval. Client tier flags never
grant authority. Free users receive five assessments per UTC day and server
approved testers or verified subscribers receive fifty; all retain the
five-per-minute limit. These limits are additional to the F0 monthly cap.

`service_idempotency` stores a UID-scoped request receipt with an audio/text
fingerprint hash, owner token, state, quota reservations, a 60-second lease,
and a 24-hour duplicate-recovery window. It does not store recording bytes
or reference text. Aggregate score responses are held separately in
`service_idempotency_results` for 15 minutes, with matching owner tokens;
expired results are not replayed. Firestore TTL cleanup is asynchronous, so
the server checks expiration before use. Existing deletion and server-only
access controls apply to both collections.

Only an expired `claimed` receipt that was never dispatched can be reclaimed
by a new owner. A durable `pending` marker is committed before Azure is
called; a timeout, crash, or result-save failure remains `pending` or
`uncertain` and cannot trigger another provider call during the recovery
window. Completed replay also performs no new reservation. After the
15-minute result window, the same request remains blocked from re-dispatch
until its 24-hour recovery window ends. Do not delete pending receipts or
issue replacement IDs as an operational retry workaround.

A circuit-breaker rejection before dispatch may refund the user's reserved
quota, but shared cost units remain conservatively reserved. Provider failures
after dispatch refund neither the user's quota nor the monthly audio
reservation. Budget or deletion checks that reject the dispatch transaction
leave the dispatch marker and monthly usage uncommitted.

Azure's own F0 quota still applies, including any usage outside this callable.
An exhausted quota or unavailable provider must preserve local replay and
unscored practice. Do not upgrade to S0, switch providers, or use paid credits
automatically. These controls limit assessment costs; they do not claim that
all existing Firebase or TTS services are free.

## Fixed contract

- Firebase project: `ko-lernen-app` (from `.firebaserc`).
- Callable: `assessPronunciation`.
- Callable region: `europe-west3`.
- Azure Speech region: `germanywestcentral`.
- The callable requires both Firebase Authentication and App Check.
- App Check enforcement and limited-use token consumption are enabled.
- The client sends mono 16 kHz PCM16 and reuses one `assessmentId` when it
  retries the same captured recording.
- The enabled callable secret binding is `AZURE_SPEECH_KEY`; disabled
  deployments have an empty secret binding.

The callable region and Azure provider region are different concepts. Do not
change one to make it look like the other.

## Source and unit checks

From the repository root:

```powershell
npm test --prefix functions/pronunciation
flutter test --no-pub test/pronunciation_assessment_client_test.dart
flutter test --no-pub test/pronunciation_studio_screen_test.dart test/pronunciation_studio_ui_test.dart
```

Also confirm the source contract before a release:

```powershell
rg -n 'region: "europe-west3"|enforceAppCheck: true|consumeAppCheckToken: true|secrets: freeTierAssessmentEnabled' functions/pronunciation/index.js
rg -n 'limitedUseAppCheckToken: true|_functionRegion = .europe-west3.' lib/services/pronunciation_assessment_client.dart
```

These checks prove local request validation, mapping, idempotency helpers, and
screen behavior. They do not prove that the deployed callable, App Check
registration, Firebase Auth configuration, Azure account, or a device
microphone currently works.

## Secret presence without reading the value

Use metadata-only Secret Manager inspection. This prints the secret resource
name, never its payload:

```powershell
$secretResource = gcloud secrets describe AZURE_SPEECH_KEY `
  --project=ko-lernen-app `
  --format='value(name)' 2>$null
if ($LASTEXITCODE -eq 0 -and $secretResource) {
  'AZURE_SPEECH_KEY: present (value not read)'
} else {
  'AZURE_SPEECH_KEY: presence not verified'
}
```

Do not run a secret-access command for this check, paste a secret value into a
terminal, or capture it in CI logs. Presence is not proof that the value is
current or that Azure accepts it.

## App Check debug-token verification

Debug builds use the Firebase App Check debug provider. Release builds use
Play Integrity on Android and App Attest with DeviceCheck fallback on Apple
platforms.

1. Use a local debug build only. Obtain its App Check debug token from the
   local device/debug log or provide a previously registered token through the
   `FIREBASE_APPCHECK_DEBUG_TOKEN` Dart define.
2. Register that token under the exact Android or Apple app in Firebase
   Console > App Check > Manage debug tokens.
3. Keep the token out of Git, screenshots, issue trackers, test fixtures, and
   shared shell history. Do not put a debug provider or token in a release
   build.
4. Restart the app so App Check initializes before the anonymous sign-in and
   callable request.
5. Verify one assessment request no longer returns the app-verification path.
   The server requires `request.app`, and the client uses a limited-use App
   Check token because the callable consumes tokens.

A successful debug-token request verifies only the registered debug app. It
does not prove Play Integrity, App Attest, or DeviceCheck on a release build.

## Anonymous-auth gate

The app startup coordinator calls `AuthService.ensureSignedIn()`, and the
callable rejects a request without `request.auth.uid`. These checks apply to
optional online assessment; local recording and replay do not require cloud
authentication or upload consent.

1. In Firebase Console > Authentication > Sign-in method, confirm Anonymous is
   enabled for `ko-lernen-app`.
2. Launch the app online and wait for cloud startup to finish before opening
   the pronunciation studio.
3. If the screen shows **Secure sign-in is not ready** / **Sichere Anmeldung
   noch nicht bereit**, verify Auth and App Check first. The same recording is
   retained in memory for an idempotent retry; do not record again unless the
   UI explicitly says a new recording is needed.
4. Do not log or paste the anonymous UID. A Firebase Authentication user entry
   and a successful callable request are sufficient operational evidence.

## Emulator versus production

`FirebasePronunciationAssessmentGateway.production()` targets
`europe-west3`. The repository does not currently call
`useFunctionsEmulator`, so starting Firebase emulators alone does not redirect
the app. The default debug build does not request assessment. A debug build
explicitly enabling free assessment still targets production.

- `npm test --prefix functions/pronunciation` is a local unit/contract test. It
  does not contact Azure or a deployed callable.
- A Functions emulator needs explicit temporary client wiring plus local Auth,
  App Check, Firestore, and secret configuration. Emulator acceptance is not
  production acceptance, and such wiring must not be committed as a release
  default.
- A production check must use the deployed `europe-west3` callable, a valid
  registered app, App Check, anonymous Auth, and an explicit learner consent.
- Never use a production recording merely to test an emulator configuration.

## Expected client diagnosis

| Client category | Typical source code | EN diagnosis | Learner action |
| --- | --- | --- | --- |
| `invalidRequest` | `invalid-argument` or rejected local payload | New recording needed | Record again; the rejected PCM is not retried. |
| `authenticationRequired` | `unauthenticated`, `permission-denied`, or `failed-precondition` | Secure sign-in is not ready | Fix Auth/App Check, then retry the same recording and `assessmentId`. |
| `unavailable` | `unavailable`, `deadline-exceeded`, `internal`, malformed score response | Assessment service is unavailable | Retry the same recording and `assessmentId`. |
| `rateLimited` | `resource-exhausted` | Assessment limit reached | Retry the same recording later, or continue without a score. |
| `unknown` | `aborted` (same request still pending), or another unmapped failure | Assessment could not be completed | Wait or continue without a score; any manual retry keeps the same recording and `assessmentId`. |

German builds show the corresponding localized diagnosis and the same action
contract. Only a successful, current-generation result may persist a passing
score. Navigation, retry replacement, and disposal must suppress stale results.

## Physical-device release handoff

The final device pass remains a human/device gate. Record separately:

- platform, OS version, build number, and debug or release mode;
- microphone consent accepted and declined paths;
- OS microphone permission denied and accepted paths;
- model voice, record, stop, replay/stop own recording, optional explicit score,
  retry-same-recording, and continue-without-score;
- default build: recording, replay, and unscored practice make no assessment
  callable request and never display a fabricated passing score;
- F0-enabled build: upload consent occurs only at the explicit score action;
- free quota exhaustion: local replay and unscored practice remain available;
- backgrounding or leaving while recording and while awaiting a score;
- App Check provider used and whether the request reached the deployed
  `europe-west3` callable;
- no audio/reference text in app, Functions, Analytics, or crash logs.

Do not mark this gate complete from widget tests, unit tests, emulator results,
or source inspection.
