# Android Crashlytics symbol-evidence gate (R4)

Before Play upload in `ci.yml` (internal) and `play_closed.yml` (alpha/beta),
`tool/android_release_evidence.py` verifies the actual built AAB and its native
symbols, invokes the pinned publisher, independently verifies its receipt and
archives the evidence. The gate remains off until explicitly enabled.

## What is verified

- Actual AAB manifest package/version and SHA-256, the configured Firebase
  Android app ID, and ELF build IDs for all three Dart symbol architectures.
- Exact source SHA, GitHub run ID and attempt in the local receipt.
- Reviewed SHA-256 pins for bundletool, Java, the standalone Firebase CLI **and
  its child Crashlytics buildtools JAR**, before execution. The child's Java
  executable name and permissions are checked; its directory is the only PATH
  entry and `CRASHLYTICS_LOCAL_JAR` is set to the
  pinned JAR, preventing the CLI's implicit download/cache fallback.
- The child tools are checked again after upload. A tool or artifact mutation,
  upload failure, stale receipt or incomplete archive prevents Play publication.

The internal lane preserves the original AAB, checksum and symbols before
upload. The receipt and matching release artifacts are retained for 90 days.
A local success receipt proves the publisher command completed for those
inputs; it is not signed provenance or evidence that a device crash was received
and symbolicated. Device ingestion remains a separate acceptance check.

## Authentication correction

The pinned `firebase-tools` 15.29.0 native-symbol command has no `requireAuth`
hook. It invokes buildtools 3.0.3 with `-uploadNativeSymbols -googleAppId`; its
native symbol service uploads using app ID/build ID without an IAM bearer key.
The previous dedicated `FIREBASE_SYMBOLS_SA_JSON` requirement did not protect
that endpoint and must not be provisioned just for this command.

Use an isolated runner without cached Firebase login. The gate rejects supplied
`FIREBASE_TOKEN`, `GOOGLE_APPLICATION_CREDENTIALS`, `NODE_OPTIONS` and Java runtime
injection options. It does not read or grant account credentials, create keys,
change IAM, weaken App Check or alter app collection consent. The Play publisher
secret remains separate and is used only by the existing Play upload action.

Upstream evidence:
- [Pinned CLI command](https://github.com/firebase/firebase-tools/blob/v15.29.0/src/commands/crashlytics-symbols-upload.ts)
- [Pinned CLI child-tool resolution](https://github.com/firebase/firebase-tools/blob/v15.29.0/src/crashlytics/buildToolsJarHelper.ts)
- [Google Maven buildtools SHA-256](https://dl.google.com/android/maven2/com/google/firebase/firebase-crashlytics-buildtools/3.0.3/firebase-crashlytics-buildtools-3.0.3.jar.sha256)

## Configuration and activation

- `ANDROID_SYMBOL_EVIDENCE_GATE` repository variable: exact `true` enables the
  gate. Unset/false remains unverified; internal releases emit a warning.
- `FIREBASE_ANDROID_APP_ID` repository variable: the `mobilesdk_app_id` for
  `com.sujinarin.ko_lernen_app` in `android/app/google-services.json`.
- Existing `PLAY_INTERNAL_RELEASE_ENABLED`, main-only environment and internal
  track remain independent. Enabling symbol verification does not dispatch any
  release or publish to another track.

Enable only after code review, exact-main checks and all four tool pins are
verified. Automation is operational only after an enabled exact-build run
records upload, independent verification and archive success before Play upload.
A previous manual upload is not a substitute. Disabling the variable skips the
symbol gate and returns to an explicitly unverified publication path.

## Updating pins

`tool/android_release_tools.json` and
`docs/runbooks/android-release-tools-provenance.json` record the versions,
platforms, exact publisher URLs, independent publisher digests and executable
hashes. The Java pin is the Linux x64 executable, not a developer workstation
hash. The Crashlytics JAR pin covers its embedded native symbol generators.
Download from the exact publisher URL, compare its official digest, and update
both files through review; never trust a newly harvested hash on first use.

Run `python -m unittest tool.test_release_integrity tool.test_android_release_evidence tool.test_android_release_tools_config tool.test_internal_symbol_workflow`.
Keep the gate disabled during pin replacement, then verify a new exact build.
This code change alone neither enables the gate nor proves device crash reports.
