# Android Crashlytics symbol-evidence gate (R4)

Before the Play upload in `play_closed.yml`, `tool/android_release_evidence.py`
can independently verify that the exact built AAB's native symbols were
uploaded to Crashlytics, using a fail-closed receipt (no trust-on-first-use
for any tool it runs). The gate is off by default; nothing about the Play
release path changes until it is provisioned and enabled below.

## What the gate does

When enabled, three new steps run after "Record bundle identity" and before
"Preserve AAB and Dart symbols": pin an exact bundletool/firebase-tools/
Java/Node toolchain and verify each executable's SHA-256, upload the AAB's
symbols and independently re-verify the receipt (`upload` then `verify`),
then archive the receipt and symbols as a 90-day artifact. Any non-zero exit
fails the job, so the Play upload step never runs on unverified symbols.

## Secrets and variables to create (GitHub repo settings)

- `ANDROID_SYMBOL_EVIDENCE_GATE` (repository **variable**, not secret) — set
  to `true` to turn the gate on. Anything else (including unset) keeps it off.
- `FIREBASE_ANDROID_APP_ID` (repository **variable**) — the
  `mobilesdk_app_id` for `com.sujinarin.ko_lernen_app` from
  `android/app/google-services.json`.
- `FIREBASE_SYMBOLS_SA_JSON` (repository **secret**) — a service-account key
  JSON authorized only for `firebase crashlytics:symbols:upload` (Firebase
  Crashlytics admin/write on this project), scoped to the `google-play-internal`
  environment. Do not reuse the Play upload service account.

## Harvest procedure (one-time, fills the sha256 placeholders)

1. `tool/android_release_tools.json` already pins the `version`/`url` for
   bundletool and firebase-tools (real values) and for java/node (choose the
   exact versions to install). Every `sha256` starts as
   `"<fill from harvest step>"`.
2. With the gate variable still unset, run `play_closed.yml` once (or a
   manual dry run of just the setup steps). The always-on "Symbol evidence
   gate status" step prints the gate state and, if disabled, the SHA-256 of
   the runner's already-installed `java` and `node` binaries — this never
   downloads anything.
3. Separately obtain the SHA-256 of `bundletool-all-<version>.jar` (from the
   GitHub release's published checksum, not a fresh download you trust) and
   of `firebase-tools@<version>`'s `lib/bin/firebase.js` (from the npm
   package's published integrity metadata).
4. Fill all four `sha256` fields in `tool/android_release_tools.json` with
   the verified values, commit, and run `tool/test_android_release_tools_config.py`
   locally to confirm the schema (still requires every non-sha256 field to be
   a real value).

## Enabling and rolling back

- Enable: after both secrets/variables above exist and the harvest is
  complete, set the `ANDROID_SYMBOL_EVIDENCE_GATE` variable to `true`.
- Roll back: set `ANDROID_SYMBOL_EVIDENCE_GATE` back to `false` (or delete
  it). The gated steps are skipped again and the release path returns to
  exactly its current, unverified-by-this-gate behavior. No code revert
  needed.
