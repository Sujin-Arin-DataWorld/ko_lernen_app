# iOS·iPad App Store Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a credential-free iOS/iPad App Store readiness pack that keeps runtime version information, iPad native configuration, screenshot validation, and Store metadata current.

**Architecture:** A small `AppVersionReader` owns PackageInfo formatting and is injected into Settings. A static Dart checker inspects committed iOS resources without pretending that Apple signing or Firebase is configured. Store documents carry the live content facts and a Python PNG validator checks only real post-capture files.

**Tech Stack:** Flutter/Dart 3, `package_info_plus`, Xcode project text resources, Python 3 standard library, Markdown.

## Global Constraints

- Keep version truth in native `PackageInfo`; never add another hard-coded UI release value.
- Preserve `com.sujinarin.koLernenApp`, iOS 13.0, and `TARGETED_DEVICE_FAMILY = "1,2"`.
- Do not commit `GoogleService-Info.plist`, team IDs, provisioning profiles, APNs keys, RevenueCat keys, or a guessed privacy manifest.
- Require real alpha-free iPhone/iPad captures; generated imagery and web screenshots are not App Store submission media.
- Windows validates source only. macOS/Xcode, Apple credentials, Firebase iOS config, privacy report, signed archive, TestFlight, App Store Connect, and real iPad proof remain external gates.
- The project policy permits commits/pushes only after Jin explicitly asks; update `AGENTS.md` in the same pending change set, but do not autonomously commit.

---

### Task 1: Runtime app-version reader and Settings display

**Files:**
- Create: `lib/services/app_version_service.dart`
- Modify: `lib/screens/settings_screen.dart`
- Create: `test/app_version_service_test.dart`
- Modify: `test/widgets/settings_screen_test.dart`

**Interfaces:**
- Produces `abstract interface class AppVersionReader { Future<String> readVersion(); }`.
- Produces `PackageAppVersionReader`, which turns `PackageInfo(version: '2.0.5', buildNumber: '11')` into `2.0.5 (11)` and throws for blank native values.
- `SettingsScreen` accepts `AppVersionReader? appVersionReader`; production uses `const PackageAppVersionReader()`.

- [x] **Step 1: Write the failing pure-service tests**

```dart
expect(
  formatAppVersion(const PackageInfo(appName: 'Hangul Sori', packageName: 'x', version: '2.0.5', buildNumber: '11')),
  '2.0.5 (11)',
);
expect(() => formatAppVersion(const PackageInfo(appName: '', packageName: '', version: '', buildNumber: '11')), throwsStateError);
```

- [x] **Step 2: Run the service test and confirm the missing implementation fails**

Run: `flutter test test/app_version_service_test.dart`

Expected: compile failure until `app_version_service.dart` exists.

- [x] **Step 3: Implement the minimal reader**

```dart
String formatAppVersion(PackageInfo info) {
  final version = info.version.trim();
  final build = info.buildNumber.trim();
  if (version.isEmpty || build.isEmpty) throw StateError('Package version is unavailable.');
  return '$version ($build)';
}
```

`PackageAppVersionReader.readVersion()` awaits `PackageInfo.fromPlatform()` and delegates to `formatAppVersion`.

- [x] **Step 4: Inject and render the reader in SettingsScreen**

Add a `String _appVersion = '—';` state field and load `widget.appVersionReader.readVersion()` in `initState`. After a successful mounted check, call `setState`; on an error retain `—`. Use that field for both the About tile and `showLicensePage`. Remove `_appVersion() => '2.0.3'`.

- [x] **Step 5: Add a widget regression test**

Pass a fake reader returning `2.0.5 (11)`, pump twice, and assert `find.textContaining('2.0.5 (11)')`. Add a throwing fake and assert the neutral `—` state without an uncaught async error.

- [x] **Step 6: Verify task 1**

Run: `flutter test test/app_version_service_test.dart test/widgets/settings_screen_test.dart`

Expected: all selected tests pass.

### Task 2: Localized iOS permission resources and static iPad contract

**Files:**
- Create: `ios/Runner/de.lproj/InfoPlist.strings`
- Create: `ios/Runner/en.lproj/InfoPlist.strings`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Create: `tool/verify_ios_store_contract.dart`
- Create: `test/ios_store_contract_test.dart`

**Interfaces:**
- Produces `IosStoreContractResult(List<String> violations)` and `bool get isValid`.
- `inspectIosStoreContract({required String projectSource, required String infoPlistSource, required String appIconSource, required String deStringsSource, required String enStringsSource})` returns a violation for every missing invariant.
- CLI reads committed files, prints violations to stderr, and exits 1 only for static-contract failures. It does not call the credentialed Firebase gate.

- [x] **Step 1: Write failing fixture tests for native invariants**

```dart
final result = inspectIosStoreContract(
  projectSource: validProject.replaceFirst('TARGETED_DEVICE_FAMILY = "1,2";', 'TARGETED_DEVICE_FAMILY = "1";'),
  infoPlistSource: validInfoPlist,
  appIconSource: validAppIcon,
  deStringsSource: validStrings,
  enStringsSource: validStrings,
);
expect(result.violations, contains('iPad target family is missing'));
```

Cover bundle ID, iOS 13.0, target family, four iPad orientations, camera/photo purpose keys, Runner resource membership, both locale files, `83.5x83.5` iPad icon, and the 1024 marketing icon.

- [x] **Step 2: Run the checker test and confirm it fails before implementation**

Run: `flutter test test/ios_store_contract_test.dart`

Expected: import/compile failure before the checker exists.

- [x] **Step 3: Add the localized strings and Xcode resource references**

Use these exact keys in each locale file:

```text
"NSCameraUsageDescription" = "…";
"NSPhotoLibraryUsageDescription" = "…";
```

Register the `de` and `en` file references in an `InfoPlist.strings` PBXVariantGroup, add that group to Runner, and add it once to Runner Resources. Add `de` to `knownRegions`. Do not alter signing, entitlements, bundle identifier, or capability settings.

- [x] **Step 4: Implement the static checker and CLI**

Use exact token checks and aggregate every violation. The successful CLI output must be `iOS/iPad static store contract passed.`; malformed/missing inputs must produce readable violations, not a stack trace.

- [x] **Step 5: Verify task 2**

Run:

```powershell
flutter test test/ios_store_contract_test.dart
dart run tool/verify_ios_store_contract.dart
```

Expected: test and static checker pass. Separately run `dart run tool/verify_ios_firebase_config.dart` and retain its expected credential-free failure as an external-gate record.

### Task 3: App Store metadata and iPad screenshot capture contract

**Files:**
- Modify: `docs/store/listing-de.md`
- Modify: `docs/store/listing-en.md`
- Create: `docs/store/app-store-connect-v2.0.5.md`
- Modify: `docs/store/screenshot-shotlist.md`
- Modify: `docs/store/README.md`
- Create: `test/store_submission_material_test.dart`

**Interfaces:**
- The DE/EN listing files remain copy-ready product-page source.
- `app-store-connect-v2.0.5.md` is the single operational handoff for version `2.0.5 (11)`.
- Screenshot directories are reserved as `docs/store/captures/app-store-ios/<locale>/<device>/` and are valid only when populated with actual iOS captures.

- [x] **Step 1: Write failing source-of-truth tests**

```dart
expect(englishListing, contains('558 vocabulary entries'));
expect(englishListing, contains('64 themed packs'));
expect(englishListing, contains('39 real-life scenarios'));
expect(germanListing, contains('558 Vokabeleinträge'));
expect(shotList, contains('2752 × 2064'));
expect(shotList, contains('real iOS simulator or device capture'));
```

- [x] **Step 2: Run the material test and confirm the stale files fail**

Run: `flutter test test/store_submission_material_test.dart`

Expected: assertion failure on the old 526/61/13+ claims.

- [x] **Step 3: Refresh both listings**

Provide 30-character-safe localized app name/subtitle, promotional text, full description, keywords, and version `2.0.5` What's New copy. State the verified facts exactly: 558 vocabulary entries, 64 themed packs, 39 real-life scenarios, 17 quests. Describe the interactive personal hanok, rooms, Bojagi rewards, and tablet support without promising undeployed services.

- [x] **Step 4: Add the App Store Connect handoff and rewrite the shot list**

The handoff includes: bundle ID, version/build, category recommendation, support/privacy/deletion URLs marked for live-host validation, App Privacy worksheet pointer, guest-review instructions, and Mac-only archive/TestFlight gates. The shot list uses 1–10 alpha-free PNGs; it calls for both 13-inch iPad `2064 × 2752` portrait and `2752 × 2064` landscape capture, plus a 6.9-inch iPhone set. The first iPad image is the interactive personal Hanok map in landscape.

- [x] **Step 5: Verify task 3**

Run: `flutter test test/store_submission_material_test.dart`

Expected: all material assertions pass.

### Task 4: Dependency-free App Store screenshot validator

**Files:**
- Create: `tool/check_app_store_screenshots.py`
- Create: `tool/test_check_app_store_screenshots.py`

**Interfaces:**
- `validate_directory(path: Path, target: str) -> list[str]` returns validation messages.
- Supported targets: `ipad-13` and `iphone-6.9`.
- CLI: `python tool/check_app_store_screenshots.py --target ipad-13 docs/store/captures/app-store-ios/en-US/ipad-13`.

- [x] **Step 1: Write the Python unit tests with standard-library PNG fixtures**

Create a minimal PNG with `struct` and `zlib`; test an accepted opaque `2752 × 2064` iPad image, a transparent PNG rejection, a wrong-dimension rejection, and rejection for zero or eleven files.

- [x] **Step 2: Run the unit test and confirm it fails before implementation**

Run: `python tool/test_check_app_store_screenshots.py`

Expected: import failure before `check_app_store_screenshots.py` exists.

- [x] **Step 3: Implement PNG inspection without third-party packages**

Read only the PNG signature and IHDR chunk. Reject color types 4/6 and a `tRNS` chunk. Validate all dimensions against the accepted target set and require 1–10 `.png` files. Return all failures in one run.

- [x] **Step 4: Verify task 4**

Run: `python tool/test_check_app_store_screenshots.py`

Expected: all validator cases pass.

### Task 5: Integration record and release checks

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-08-05-ios-ipad-app-store-readiness-design.md`
- Modify: `docs/superpowers/plans/2026-08-05-ios-ipad-app-store-readiness.md`

**Interfaces:**
- `AGENTS.md` records exactly what local checks passed and labels external macOS/Apple gates as pending.

- [x] **Step 1: Update plan checkboxes and design status**

Mark only executed tasks complete. Record the static source checks, known expected Firebase gate failure, and the precise external owner gates.

- [x] **Step 2: Record the mandatory AGENTS session log and current-work checklist**

Include changed files, why they changed, test results, expected `verify_ios_firebase_config.dart` failure, and `commit: not created` unless Jin explicitly requests a commit.

- [x] **Step 3: Run integrated local verification**

Run:

```powershell
dart format --output=none --set-exit-if-changed lib/services/app_version_service.dart lib/screens/settings_screen.dart tool/verify_ios_store_contract.dart test/app_version_service_test.dart test/ios_store_contract_test.dart test/store_submission_material_test.dart
flutter test test/app_version_service_test.dart test/ios_store_contract_test.dart test/store_submission_material_test.dart test/widgets/settings_screen_test.dart test/responsive_test.dart test/sori_tablet_responsive_contract_test.dart
dart analyze --fatal-infos
python tool/test_check_app_store_screenshots.py
git diff --check
```

- [x] **Step 4: Keep the external release boundary explicit**

Do not call App Store Connect, Firebase, Apple Developer, RevenueCat, or a macOS build service. Hand off the exact macOS commands from `docs/store/app-store-connect-v2.0.5.md` after local checks pass.

- [ ] **Step 5: Commit only on explicit request**

If Jin requests a commit, stage only the files listed in Tasks 1–5 plus the already requested `2.0.5+11` version/release-note files, review `git diff --check`, and make one focused commit. Do not push unless separately requested.
