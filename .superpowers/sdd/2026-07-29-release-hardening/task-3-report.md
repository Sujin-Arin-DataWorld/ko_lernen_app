# Task 3 Report: Android picker policy, signing safety, notification icon, and manifest privacy

## Status

Implemented and verified with focused Android build/merged-manifest evidence,
Dart analysis, and the full Flutter test suite.

## Files changed

- `lib/screens/book_capture_screen.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `lib/services/notification_service.dart`
- `android/app/src/main/res/drawable/ic_stat_hangul_sori.xml`
- `.superpowers/sdd/2026-07-29-release-hardening/task-3-report.md`

No real `android/key.properties` or upload keystore was created or committed.

## Pre-change evidence

Command:

```powershell
java.exe -classpath gradle-launcher-9.1.0.jar `
  org.gradle.launcher.GradleMain `
  :app:processDebugMainManifest :app:signingReport `
  --rerun-tasks --console=plain
```

Result: exit 0. The generated merged debug manifest contained:

```text
com.google.android.gms.permission.AD_ID
android.permission.READ_MEDIA_IMAGES
android.permission.READ_EXTERNAL_STORAGE
android.permission.ACCESS_ADSERVICES_AD_ID
firebase_analytics_collection_enabled=false
```

The same command's signing report showed the unsafe fallback:

```text
Variant: release
Config: debug
Store: C:\Users\vjinn\.android\debug.keystore
Alias: AndroidDebugKey
```

This restates the ledger's earlier diagnostic finding that the release artifact
was signed by Android Debug when no release credentials existed.

## Implementation

- Gallery selection now goes directly to `image_picker_android`, which uses the
  Android system picker. Only camera capture requests contextual
  `Permission.camera`; the gallery path requests no media-library permission.
- The app manifest retains `CAMERA` and uses manifest-merger removal markers for
  `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE`, GMS `AD_ID`, and AdServices
  `ACCESS_ADSERVICES_AD_ID`, preventing transitive reintroduction.
- Native FCM auto-init and Firebase Analytics advertising-ID collection default
  to off through `firebase_messaging_auto_init_enabled=false` and
  `google_analytics_adid_collection_enabled=false`. Existing Analytics and
  Crashlytics collection defaults remain off for runtime consent handling.
- `NotificationService` references `ic_stat_hangul_sori`. The new drawable is a
  transparent Android vector whose only fill is opaque white (`#FFFFFFFF`), as
  required for a notification small icon.
- Release signing no longer assigns the debug signing config. A release task
  fails clearly when `android/key.properties` is absent, any required property
  is blank/missing, or the configured keystore file does not exist. Debug tasks
  do not trigger that failure.

## Validation evidence

### Dart

```text
flutter analyze lib/screens/book_capture_screen.dart lib/services/notification_service.dart
Analyzing 2 items...
No issues found!
```

All changed Dart control-flow branches in the capture flow use braces.

### Debug manifest merge and vector resource

Command:

```powershell
java.exe -classpath gradle-launcher-9.1.0.jar `
  org.gradle.launcher.GradleMain `
  :app:processDebugMainManifest :app:processDebugResources `
  --console=plain
```

Result: exit 0. `processDebugResources` exercises AAPT against the new vector.
Parsing the generated
`build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`
returned:

```text
CAMERA_PRESENT=True
READ_MEDIA_IMAGES_PRESENT=False
READ_EXTERNAL_STORAGE_PRESENT=False
GMS_AD_ID_PRESENT=False
ADSERVICES_AD_ID_PRESENT=False
FCM_AUTO_INIT=false
ANALYTICS_ADID_COLLECTION=false
ANALYTICS_COLLECTION=false
ICON_FILL_COLORS=#FFFFFFFF
```

### Signing behavior without real credentials

Absent `android/key.properties`:

```text
java.exe ... org.gradle.launcher.GradleMain :app:validateSigningRelease --console=plain
Release signing configuration is invalid. android/key.properties is missing.
Provide a complete android/key.properties and an existing non-debug upload keystore.
BUILD FAILED
```

Result: intended exit 1.

An ignored, temporary incomplete `android/key.properties` containing only
`storeFile=task3-missing-keystore.jks`:

```text
Release signing configuration is invalid. android/key.properties is missing
required values: storePassword, keyAlias, keyPassword.
BUILD FAILED
```

Result: intended exit 1.

The same ignored temporary file with all four property names but a nonexistent
keystore:

```text
Release signing configuration is invalid. The configured release keystore does
not exist: ...\android\app\task3-missing-keystore.jks
BUILD FAILED
```

Result: intended exit 1. The temporary properties file was then deleted.

Final signing report with no credentials:

```text
Variant: debug
Config: debug
Store: C:\Users\vjinn\.android\debug.keystore

Variant: release
Config: null
Store: null
Alias: null
```

Result: exit 0. Debug remains configured while release no longer inherits the
debug key.

### Regression suite and whitespace

```text
flutter test
00:43 +562: All tests passed!
```

`git diff --check` is run again immediately before commit.

## Self-review

- Re-read every Task 3 checklist item and mapped it to either merged-manifest,
  Gradle task, AAPT resource, analyzer, or Flutter test evidence.
- Confirmed the system-picker change removes only manual gallery permission;
  contextual camera permission and the manifest `CAMERA` declaration remain.
- Confirmed manifest privacy from the generated merged XML rather than brittle
  source grep assertions.
- Confirmed the notification drawable has no colored/background pixels and was
  accepted by Android resource processing.
- Confirmed the release build type has no debug signing fallback and exercised
  absent, incomplete, and missing-keystore failure messages.
- Confirmed the temporary ignored signing file is absent and no keystore was
  generated.
- Removed Gradle's generated problems-report change so only Task 3 files remain.

## Concerns

- A full `:app:assembleDebug` attempt exceeded the four-minute command timeout
  and has no completion claim. The bounded debug configuration, merged-manifest,
  and AAPT resource tasks all exited 0, and the complete Flutter suite passed.
- Per coordinator direction, no fabricated/test keystore and no full release AAB
  were used. Release compilation must be verified later with an explicitly
  identified CI/test keystore, and production signing must use the real Play
  upload key.
- Gradle reports existing Android plugin/Kotlin deprecation warnings and a
  command-line-tools SDK XML version warning; these are outside Task 3.
- Device QA should still visually confirm the small notification icon and both
  camera and system-gallery picker flows across supported Android versions.
