# Android Crashlytics symbol-evidence gate (R4)

Before the Play upload in `play_closed.yml`, `tool/android_release_evidence.py`
can independently verify that the exact built AAB's native symbols were
uploaded to Crashlytics, using a fail-closed receipt (no trust-on-first-use
for any tool it runs). The gate is off by default; nothing about the Play
release path changes until it is provisioned and enabled below.

## What the gate does

When enabled, the workflow prepares pinned bundletool, Java and the standalone
Firebase CLI before restoring Android signing secrets. The entire Firebase
publisher executable (including its runtime and dependencies) is SHA-256 checked
before it becomes executable. No npm package resolution or lifecycle scripts run.
After "Record bundle identity", the gate uploads the AAB's symbols, independently
re-verifies the receipt (`upload` then `verify`), and archives the receipt and
symbols as a 90-day artifact. Any non-zero exit fails the job, so the Play upload
step never runs on unverified symbols.

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

## Verified tool pins

`tool/android_release_tools.json` contains verified executable SHA-256 values
for the three pinned versions. The public verification chain is recorded in
`docs/runbooks/android-release-tools-provenance.json`: exact publisher artifact
URL, publisher digest metadata, archive SHA-256, exact archive
member, platform, and the executable SHA-256 consumed by the gate.

The Java hash is for the **Linux x64** binary installed by the gated `setup-java`
step. Firebase uses the official Linux x64 standalone release; the recorded
hash covers the whole artifact, not only a JavaScript entry point. The disabled
gate's status step reports the runner's preinstalled `java` and `node` only as
harvest diagnostics. Those values are not release-tool trust anchors.
Binary hashes also vary by version, platform, architecture, and publisher
packaging even when the command name is the same.

## Refreshing a pin

1. Keep `ANDROID_SYMBOL_EVIDENCE_GATE` disabled while choosing the new exact
   tool version. Do not copy a baseline runner hash into the pin.
2. Obtain the artifact from the exact publisher URL and verify its archive
   SHA-256 against independent publisher metadata.
3. Extract the exact Java member used by CI and compute its SHA-256. For
   bundletool and Firebase, the entire downloaded artifact is the verified
   executable. Do not substitute npm entry-point hashes for the standalone CLI.
4. Update both `tool/android_release_tools.json` and
   `docs/runbooks/android-release-tools-provenance.json`, then run:

   ```text
   python -m unittest tool.test_release_integrity tool.test_android_release_evidence tool.test_android_release_tools_config
   ```

5. Review the publisher URLs, versions, archive verification, member names,
   platforms, and executable hashes before enabling a release candidate.

## Enabling and rolling back

- Enable only after `FIREBASE_SYMBOLS_SA_JSON` is provisioned as a dedicated
  symbol-upload credential, `FIREBASE_ANDROID_APP_ID` is set, the verified
  pins above are complete, and `ANDROID_SYMBOL_EVIDENCE_GATE` is set to `true`.
  Activation is complete only when an enabled CI run for the exact source SHA
  verifies the pinned tools and the upload/verification receipt before Play
  upload.
- Roll back: set `ANDROID_SYMBOL_EVIDENCE_GATE` back to `false` (or delete
  it). The gated steps are skipped again and the release path returns to
  exactly its current, unverified-by-this-gate behavior. No code revert
  needed.

Repository and environment metadata checks did not expose the required app ID,
gate variable, or symbol-only credential. No setting was created or changed.
That metadata result does not prove that any actual Crashlytics symbol upload
failed; it only means there is no enabled, exact-SHA gate evidence yet. This
configuration and documentation update does not activate the gate.
