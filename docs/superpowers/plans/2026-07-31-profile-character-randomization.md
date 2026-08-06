# Profile Character Randomization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the user's chosen mascot in the profile and choose one requested pose per profile visit without changing it during that visit.

**Architecture:** Keep the requested clip sets in `CharacterClips`, where a pure selector turns a bounded random index into the matching asset path. `_Avatar` owns its chosen index in `initState`, so normal rebuilds do not change the visible pose. The user-selected `Storage.preferredMascot` takes precedence over an account photo.

**Tech Stack:** Flutter/Dart, `video_player`, `shared_preferences`, Flutter widget/unit tests.

## Global Constraints

- Use only existing assets under `assets/video/character/`; do not create or rename media.
- Tiger profile candidates are `tiger_stretch`, `tiger_sitting2`, `tiger_rest`, `tiger_walking_front`, and `tiger_choose`.
- Magpie profile candidates are `magpie_perched`, `magpie_choose`, and `magpie_flight`.
- A profile pose is random on screen creation, not every widget rebuild.
- The chosen mascot overrides a Google/Apple profile photo on this screen.
- Keep `CharacterClipPlayer`'s white-background multiply behavior unchanged. A magenta-background H.264 source requires re-export with a white matte; a color filter cannot safely chroma-key a video texture.
- Do not commit or push without Jin's explicit request.

---

### Task 1: Testable profile clip catalogue

**Files:**
- Modify: `lib/widgets/sori/character_clip.dart`
- Create: `test/character_clip_test.dart`

**Interfaces:**
- Produces: `CharacterClips.profileClipCountFor(MascotKind kind) -> int`
- Produces: `CharacterClips.profileClipFor(MascotKind kind, int choice) -> String`

- [x] **Step 1: Write the failing test**

```dart
test('selects every requested tiger profile clip by bounded choice', () {
  expect(CharacterClips.profileClipFor(MascotKind.tiger, 0),
      CharacterClips.tigerStretch);
  expect(CharacterClips.profileClipFor(MascotKind.tiger, 4),
      CharacterClips.tigerChoose);
});

test('selects every requested magpie profile clip by bounded choice', () {
  expect(CharacterClips.profileClipFor(MascotKind.magpie, 0),
      CharacterClips.magpiePerched);
  expect(CharacterClips.profileClipFor(MascotKind.magpie, 2),
      CharacterClips.magpieFlight);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/character_clip_test.dart`

Expected: compilation failure because the profile selector methods do not exist.

- [x] **Step 3: Write minimal implementation**

```dart
static int profileClipCountFor(MascotKind kind) =>
    kind == MascotKind.magpie ? 3 : 5;

static String profileClipFor(MascotKind kind, int choice) {
  final clips = kind == MascotKind.magpie ? _magpieProfileClips : _tigerProfileClips;
  return clips[choice];
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/character_clip_test.dart`

Expected: PASS with the requested tiger and magpie paths.

### Task 2: Stable per-visit profile portrait

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Test: `test/character_clip_test.dart`

**Interfaces:**
- Consumes: `Storage.preferredMascot`, `CharacterClips.profileClipCountFor`, and `CharacterClips.profileClipFor`.
- Produces: a `StatefulWidget` avatar that keeps the initial random selection for its lifetime.

- [x] **Step 1: Extend the failing test**

```dart
test('uses the user-selected mascot profile catalogue', () {
  expect(CharacterClips.profileClipCountFor(MascotKind.tiger), 5);
  expect(CharacterClips.profileClipCountFor(MascotKind.magpie), 3);
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/character_clip_test.dart`

Expected: FAIL until both catalogues expose their intended counts.

- [x] **Step 3: Write minimal implementation**

```dart
class _AvatarState extends State<_Avatar> {
  late final MascotKind _kind;
  late final String _asset;

  @override
  void initState() {
    super.initState();
    _kind = Storage.preferredMascot == 'magpie'
        ? MascotKind.magpie
        : MascotKind.tiger;
    _asset = CharacterClips.profileClipFor(
      _kind,
      Random().nextInt(CharacterClips.profileClipCountFor(_kind)),
    );
  }
}
```

Remove the account-photo branch from the profile avatar so the stored mascot choice is always visible. Pass `_asset` and `_kind` to the existing `CharacterClipPlayer`; retain the medallion's existing cream blend color and static mascot fallback.

- [x] **Step 4: Run focused tests**

Run: `flutter test test/character_clip_test.dart test/profile_screen_test.dart test/widgets/profile_screen_test.dart`

Expected: PASS; account-status and guest-profile flows continue to build.

### Task 3: Verify and document the source-matte limitation

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:**
- Documents: profile selection behavior, automated verification, and the required white-matte media re-export for any pink source clips.

- [x] **Step 1: Run static analysis and the full relevant test group**

Run: `flutter analyze lib/screens/profile_screen.dart lib/widgets/sori/character_clip.dart test/character_clip_test.dart && flutter test test/character_clip_test.dart test/profile_screen_test.dart test/widgets/profile_screen_test.dart`

Expected: no analyzer issues and all focused tests pass.

- [ ] **Step 2: Perform device verification after rebuilding the app**

Check: enter Profile repeatedly as tiger and magpie; each entry chooses only the specified clips, a pose does not change while the page remains open, and a white-matte source has no colored rectangle. If a clip remains pink, replace that same MP4 with a pure-white-background export; do not attempt a color-matrix workaround.

- [x] **Step 3: Add the session-log entry**

Record the modified files, selected clip sets, test results, and the white-matte source requirement in `CLAUDE.md` without touching the pre-existing uncommitted session entry.
