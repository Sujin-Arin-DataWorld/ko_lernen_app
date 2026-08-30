# Pronunciation assessment runbook

This runbook verifies the optional pronunciation assessment path without
printing speech audio, Korean reference text, account identifiers, or secret
values. It does not authorize a deploy. Run deployment and physical-device
checks only in their separately approved release step.

## Fixed contract

- Firebase project: `ko-lernen-app` (from `.firebaserc`).
- Callable: `assessPronunciation`.
- Callable region: `europe-west3`.
- Azure Speech region: `germanywestcentral`.
- The callable requires both Firebase Authentication and App Check.
- App Check enforcement and limited-use token consumption are enabled.
- The client sends mono 16 kHz PCM16 and reuses one `assessmentId` when it
  retries the same captured recording.
- The callable secret binding is `AZURE_SPEECH_KEY`.

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
rg -n 'region: "europe-west3"|enforceAppCheck: true|consumeAppCheckToken: true|secrets: \[AZURE_SPEECH_KEY\]' functions/pronunciation/index.js
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
callable rejects a request without `request.auth.uid`.

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
the app; an ordinary debug build still calls production.

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
| `unknown` | Any unmapped client/provider failure | Assessment could not be completed | Retry the same recording and `assessmentId`. |

German builds show the corresponding localized diagnosis and the same action
contract. Only a successful, current-generation result may persist a passing
score. Navigation, retry replacement, and disposal must suppress stale results.

## Physical-device release handoff

The final device pass remains a human/device gate. Record separately:

- platform, OS version, build number, and debug or release mode;
- microphone consent accepted and declined paths;
- OS microphone permission denied and accepted paths;
- listen, record, stop, score, retry-same-recording, and continue-without-score;
- backgrounding or leaving while recording and while awaiting a score;
- App Check provider used and whether the request reached the deployed
  `europe-west3` callable;
- no audio/reference text in app, Functions, Analytics, or crash logs.

Do not mark this gate complete from widget tests, unit tests, emulator results,
or source inspection.
