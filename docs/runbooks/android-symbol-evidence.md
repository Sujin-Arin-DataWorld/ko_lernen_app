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

## Verified tool pins

`tool/android_release_tools.json` contains verified executable SHA-256 values
for the four pinned versions. The public verification chain is recorded in
`docs/runbooks/android-release-tools-provenance.json`: exact publisher artifact
URL, publisher digest metadata, archive SHA-256 or npm integrity, exact archive
member, platform, and the executable SHA-256 consumed by the gate.

Java and Node hashes are for the **Linux x64** binaries installed by the gated
`setup-java` and `setup-node` steps. They are not hashes of a Windows developer
runtime. The disabled gate's status step reports the runner's preinstalled
`java` and `node` only as harvest diagnostics. A baseline runner may contain a
different Node version, so its hash cannot be reused for pinned Node 24.20.0.
Binary hashes also vary by version, platform, architecture, and publisher
packaging even when the command name is the same.

## Refreshing a pin

1. Keep `ANDROID_SYMBOL_EVIDENCE_GATE` disabled while choosing the new exact
   tool version. Do not copy a baseline runner hash into the pin.
2. Obtain the artifact from the exact publisher URL and verify its archive
   SHA-256 against independent publisher metadata. For an npm package, verify
   the tarball against the version metadata's `dist.integrity` value.
3. Extract the exact member used by CI and compute its SHA-256. For bundletool,
   the downloaded JAR is itself the verified executable artifact.
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
