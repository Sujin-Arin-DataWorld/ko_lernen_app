# 타이포 코어 구현 계획 (Wanted Sans · 단일 램프 · 배율 하나 · 간격 · 잘림 가드)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 한국어가 OS 폴백 폰트로 그려지던 결함을 Wanted Sans 번들로 고치고, 글자 램프·배율 권한을 하나로 합치고, 간격 토큰과 잘림 가드를 세워 모든 기기에서 읽히는 타이포 코어를 만든다.

**Architecture:** `lib/widgets/sori/tokens.dart`의 `SoriTypeRamp`(정적 상수)가 유일한 램프 → `SoriTextTheme`(색 입힘)과 `lib/theme.dart`(Material 슬롯)가 둘 다 그걸 읽는다. 배율은 `lib/main.dart` `MaterialApp.builder`의 `SoriTypeScale`(OS × comfort) 하나. 잘림은 `RenderParagraph.didExceedMaxLines`를 보는 테스트 헬퍼가 뷰포트×배율 매트릭스로 감시한다.

**Tech Stack:** Flutter 3.44 / Dart 3, `flutter_test`(위젯·골든), Wanted Sans v1.0.3 OTF(OFL), 파이썬 없음(가드는 순수 Dart).

**Spec:** `docs/superpowers/specs/2026-08-19-typography-core-design.md`

## Global Constraints
- 작업 트리: `.claude/worktrees/typography-core`, 브랜치 `claude/typography-core-20260819`(base `94bbf68a`). 메인 트리 수정 금지.
- 모든 명령은 PowerShell 문법(`&&` 금지). Python이 필요하면 `.venv\Scripts\python.exe`.
- `if/else`는 반드시 중괄호. UI 문자열 하드코딩 금지(이 계획은 새 문자열을 추가하지 않는다).
- 하한 12.5 예외 없음. 토큰 램프에 w800/w900 없음. 한국어 height ≥ 1.25, 본문 1.5.
- `FittedBox`로 역할 텍스트 축소 금지(신규). `maxLines: 1 + ellipsis`를 문장에 새로 걸지 않는다.
- 폰트 family명 `WantedSans`, `SoriFonts.sans` 상수만 사용. 파일 `assets/fonts/WantedSans/WantedSans-{Regular,Medium,SemiBold,Bold,ExtraBold}.otf`.
- 커밋은 블록별 1개, 메시지 한국어 `feat(typography): …`/`test(typography): …`. `docs/SESSION_LOG.md`는 마지막 Task에서 한 번에.
- `git commit`/`push`는 이 계획 범위 안(Jin 승인됨). **머지는 하지 않는다.**
- 스크래치 다운로드 경로: `C:\Users\vjinn\AppData\Local\Temp\claude\C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\b96aab54-644a-4566-8457-34f2a83ea9ed\scratchpad\wantedsans\extracted\` (이미 받아 둠: `otf/*.otf`, `OFL.txt`).

---

### Task 1: 폰트 교체 — Wanted Sans 번들 + 리터럴 0 + 글리프 가드

**Files:**
- Create: `assets/fonts/WantedSans/WantedSans-Regular.otf` … `-ExtraBold.otf`, `assets/fonts/WantedSans/OFL.txt`
- Delete: `assets/fonts/Pretendard/*`, `assets/fonts/GowunBatang/*`
- Modify: `pubspec.yaml:34`(google_fonts), `pubspec.yaml:185-206`(fonts), `lib/widgets/sori/tokens.dart:476-499`(SoriFonts), `lib/widgets/sori/tokens.dart:661-679`(`_base` serif 분기), `lib/theme.dart`(fontFamily 리터럴 전부), 그 외 `fontFamily: 'Pretendard'` 79곳
- Modify: `test/game_layout_test.dart:37-44`, `test/sori_stage_visual_evidence_test.dart:63-70`, `test/typography_guard_test.dart`(Pretendard 래칫 → 리터럴 0)
- Create: `test/font_bundle_guard_test.dart`

**Interfaces:**
- Produces: `SoriFonts.sans == 'WantedSans'` (유일한 family 상수). `SoriFonts.serif/serifFallback/display` 삭제.

- [ ] **Step 1: 폰트 파일 교체**
```powershell
$wt = "C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app\.claude\worktrees\typography-core"
$src = "C:\Users\vjinn\AppData\Local\Temp\claude\C--Users-vjinn-OneDrive-Desktop-hangulsori-ko-lernen-app\b96aab54-644a-4566-8457-34f2a83ea9ed\scratchpad\wantedsans\extracted"
New-Item -ItemType Directory -Force "$wt\assets\fonts\WantedSans" | Out-Null
foreach ($w in 'Regular','Medium','SemiBold','Bold','ExtraBold') { Copy-Item "$src\otf\WantedSans-$w.otf" "$wt\assets\fonts\WantedSans\" }
Copy-Item "$src\OFL.txt" "$wt\assets\fonts\WantedSans\OFL.txt"
git -C $wt rm -r -q assets/fonts/Pretendard assets/fonts/GowunBatang
Get-ChildItem "$wt\assets\fonts" -Recurse -File | Select-Object FullName, Length
```
Expected: `WantedSans/` 6개 파일, Pretendard/GowunBatang 디렉터리 없음.

- [ ] **Step 2: pubspec.yaml** — `google_fonts: ^6.2.1` 줄 삭제(lib에 `GoogleFonts` 참조 0 — `grep -rn GoogleFonts lib`로 재확인). `fonts:` 블록을 아래로 교체:
```yaml
  # ── Wanted Sans (한글 11,172자 + 라틴/독일어 완비, OFL 1.1, 2026-08-19 교체) ──
  # ⚠️ 이전 PretendardStd 는 라틴 전용 서브셋이라 한글 글리프가 0개였다 — 한국어가
  # 전부 OS 폴백 폰트로 그려졌다. test/font_bundle_guard_test.dart 가 재발을 막는다.
  # WantedSansStd(라틴 전용)는 쓰지 말 것.
  fonts:
    - family: WantedSans
      fonts:
        - asset: assets/fonts/WantedSans/WantedSans-Regular.otf
          weight: 400
        - asset: assets/fonts/WantedSans/WantedSans-Medium.otf
          weight: 500
        - asset: assets/fonts/WantedSans/WantedSans-SemiBold.otf
          weight: 600
        - asset: assets/fonts/WantedSans/WantedSans-Bold.otf
          weight: 700
        - asset: assets/fonts/WantedSans/WantedSans-ExtraBold.otf
          weight: 800
```
Run: `flutter pub get` → Expected: 성공, `pubspec.lock`에서 google_fonts 제거.

- [ ] **Step 3: `SoriFonts` 정리** (`lib/widgets/sori/tokens.dart:476-499`) — 클래스를 아래로 교체하고, `_base()`에서 `serif` 파라미터·`fontFamilyFallback` 줄 삭제(`fontFamily: SoriFonts.sans`만 남김):
```dart
/// 앱 폰트 패밀리 상수 — 한 곳에서 교체 가능.
/// - [sans] Wanted Sans: **앱 전 표면 단일 폰트** (본문·UI·제목·숫자·한국어·독일어).
///   400/500/600/700/800 번들, 한글 11,172자 + 라틴/독일어 완비.
///
/// **2026-08-19 교체**: 이전 PretendardStd 는 라틴 전용 서브셋이라 한글 글리프가
/// 0개였다. 한국어는 전부 OS 폴백(맑은 고딕·제조사 기본·Apple SD Gothic)으로
/// 그려져 한·독 혼용 줄에서 서체·굵기·베이스라인이 갈렸다. "단일 폰트" 전제가
/// 한글에서 처음으로 성립한다. `test/font_bundle_guard_test.dart` 가 번들 폰트의
/// 한글·독일어 글리프를 검사해 재발을 막는다.
class SoriFonts {
  SoriFonts._();
  static const String sans = 'WantedSans';
}
```
`lib/screens/daily_char_sheet.dart`·`lib/widgets/sori/share_slip.dart`·`lib/theme.dart`에서 `SoriFonts.serif*`/`display` 참조가 있으면 `SoriFonts.sans`로.

- [ ] **Step 4: 리터럴 79곳 → 토큰** — 스크립트로 `fontFamily: 'Pretendard'` → `fontFamily: SoriFonts.sans` 치환 + 필요한 상대 import 추가:
```powershell
$wt = "C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app\.claude\worktrees\typography-core"
& "C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app\.venv\Scripts\python.exe" - @'
import io, os, re, glob
wt = r"C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app\.claude\worktrees\typography-core"
tokens = os.path.join(wt, "lib", "widgets", "sori", "tokens.dart")
changed = 0
for p in glob.glob(os.path.join(wt, "lib", "**", "*.dart"), recursive=True):
    s = io.open(p, encoding="utf-8", newline="").read()
    if "fontFamily: 'Pretendard'" not in s:
        continue
    s2 = s.replace("fontFamily: 'Pretendard'", "fontFamily: SoriFonts.sans")
    if "tokens.dart'" not in s2 and not p.endswith("tokens.dart"):
        rel = os.path.relpath(tokens, os.path.dirname(p)).replace("\\", "/")
        nl = "\r\n" if "\r\n" in s2[:300] else "\n"
        # 첫 import 줄 뒤에 끼운다.
        m = re.search(r"^import .*?;\r?\n", s2, re.M)
        ins = f"import '{rel}';{nl}"
        s2 = s2[:m.end()] + ins + s2[m.end():] if m else ins + s2
    io.open(p, "w", encoding="utf-8", newline="").write(s2)
    changed += 1
print("files changed:", changed)
'@
grep -rn "fontFamily: 'Pretendard'" "$wt\lib" | Measure-Object | Select-Object Count
```
Expected: `files changed: ~30`, 잔존 0. 그 뒤 `dart format`은 하지 않는다(diff 최소화), 대신 `flutter analyze` → import 미사용/중복 경고가 있으면 그 파일만 손으로 정리.

- [ ] **Step 5: 테스트 폰트 로더 2곳** — `test/game_layout_test.dart:37-44`, `test/sori_stage_visual_evidence_test.dart:63-70`의 `FontLoader('Pretendard')`+경로 5개를 `FontLoader('WantedSans')` + `assets/fonts/WantedSans/WantedSans-{Regular,Medium,SemiBold,Bold,ExtraBold}.otf`로.

- [ ] **Step 6: 글리프 가드 테스트 작성** — `test/font_bundle_guard_test.dart`:
```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// 번들 폰트가 **한글과 독일어를 실제로 담고 있는지** 검사한다.
///
/// 2026-08-19 발견: `PretendardStd-*.otf` 5개가 라틴 전용 서브셋이라 한글 글리프가
/// 0개였고, 한국어 전부가 OS 폴백 폰트로 그려지고 있었다. pubspec 주석은
/// "한국어 모던 산세리프"라고 적혀 있었다. 의존성 없이 OTF `cmap`(format 4/12)을
/// 직접 읽어 `가`·`힣`·`ㄱ`·`ä`·`ß` 가 있는지 본다.
void main() {
  test('pubspec 에 선언된 모든 폰트 파일이 한글·독일어 글리프를 가진다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset:\s*(assets/fonts/\S+\.(?:otf|ttf))')
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();
    expect(assets, isNotEmpty, reason: 'pubspec fonts: 블록이 비어 있다');
    const required = <String, int>{
      '가': 0xAC00, '힣': 0xD7A3, 'ㄱ': 0x3131, 'ä': 0xE4, 'ß': 0xDF, '€': 0x20AC,
    };
    for (final asset in assets) {
      final cps = _cmapCodepoints(File(asset).readAsBytesSync());
      final missing = required.entries
          .where((e) => !cps.contains(e.value))
          .map((e) => e.key)
          .toList();
      expect(missing, isEmpty, reason: '$asset 에 글리프 없음: $missing');
      final hangul = cps.where((c) => c >= 0xAC00 && c <= 0xD7A3).length;
      expect(hangul, 11172, reason: '$asset 한글 음절 $hangul/11172 — 서브셋 금지');
    }
  });
}

Set<int> _cmapCodepoints(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  final numTables = d.getUint16(4);
  int? cmapOffset;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
    if (tag == 'cmap') {
      cmapOffset = d.getUint32(rec + 8);
    }
  }
  if (cmapOffset == null) {
    throw StateError('cmap 테이블 없음');
  }
  final out = <int>{};
  final n = d.getUint16(cmapOffset + 2);
  for (var i = 0; i < n; i++) {
    final sub = cmapOffset + d.getUint32(cmapOffset + 4 + i * 8 + 4);
    final format = d.getUint16(sub);
    if (format == 4) {
      final segX2 = d.getUint16(sub + 6);
      final ends = sub + 14;
      final starts = ends + segX2 + 2;
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(ends + s * 2);
        final start = d.getUint16(starts + s * 2);
        if (start == 0xFFFF) {
          continue;
        }
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    } else if (format == 12) {
      final nGroups = d.getUint32(sub + 12);
      for (var g = 0; g < nGroups; g++) {
        final base = sub + 16 + g * 12;
        final start = d.getUint32(base);
        final end = d.getUint32(base + 4);
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    }
  }
  return out;
}
```
Run: `flutter test test/font_bundle_guard_test.dart` → Expected: PASS (Wanted Sans). (확인용으로 Step 1 전에 돌리면 Pretendard에서 FAIL — 가드가 진짜 막는지 한 번 보고 넘어가도 좋다.)

- [ ] **Step 7: 래칫** — `test/typography_guard_test.dart`의 `"하드코딩 'Pretendard' 리터럴…"` 테스트를 **`fontFamily: '` 문자열 리터럴 0**으로 바꾼다(패턴 `RegExp("fontFamily: '")`, 상한 0, useRaw: true, 이유 주석 "family 명이 바뀌면 리터럴은 시스템 폴백으로 떨어진다 — 토큰만").

- [ ] **Step 8: 검증·커밋**
Run: `flutter analyze` (클린) · `flutter test test/font_bundle_guard_test.dart test/typography_guard_test.dart test/game_layout_test.dart test/sori_stage_visual_evidence_test.dart`
```powershell
git add -A assets/fonts pubspec.yaml pubspec.lock lib test
git commit -m "feat(typography): Wanted Sans 로 한글 폰트를 복구한다 (PretendardStd 는 한글 0글리프)"
```

---

### Task 2: 배율 권한 하나 — `SoriTypeScale` + `_deviceScale`·`SoriStudyScale` 제거

**Files:**
- Create: `lib/widgets/sori/type_scale.dart`
- Modify: `lib/main.dart:530`(builder), `lib/widgets/sori/tokens.dart`(`SoriTextTheme.of`/`_base`), `lib/widgets/sori/button.dart:120-122,188-194`, `lib/widgets/sori/responsive.dart:17-40,175-216`, `SoriStudyScale` 호출 17곳(`cloze_game_screen:310`, `custom_pack_play_screen:318,355`, `custom_pack_quiz_screen:265`, `custom_pack_typing_screen:244`, `daily_challenge_screen:273`, `grammar_screen:904`, `hangul_screen:1007`, `legacy_vocab_screen:592,728`, `review_session_screen:566,588`, `vocab_pack_recall_screen:348`, `vocab_pack_screen:984,1026,1135`), `lib/screens/quest_engines/satz_bauen_quest.dart:562`
- Test: `test/study_scale_test.dart`(soriStudyScale·SoriStudyScale 그룹 삭제), Create `test/type_scale_test.dart`

**Interfaces:**
- Produces: `class SoriTypeScale extends StatelessWidget({required Widget child})`, `class SoriComfortTextScaler extends TextScaler(TextScaler base, double factor)`. `SoriTextTheme.of(context)`는 더 이상 폭을 읽지 않는다(생성자 `SoriTextTheme._(SoriSurfaces)`).

- [ ] **Step 1: 실패하는 테스트** — `test/type_scale_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  testWidgets('폰(390dp)에서는 배율을 건드리지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late TextScaler seen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => SoriTypeScale(child: child!),
      home: Builder(builder: (c) { seen = MediaQuery.textScalerOf(c); return const SizedBox(); }),
    ));
    expect(seen.scale(10), 10);
  });

  testWidgets('태블릿(720dp)에서는 OS 배율 × 1.10', (tester) async {
    tester.view.physicalSize = const Size(720, 1024);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late TextScaler seen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => SoriTypeScale(child: child!),
      home: Builder(builder: (c) { seen = MediaQuery.textScalerOf(c); return const SizedBox(); }),
    ));
    expect(seen.scale(10), closeTo(10 * 1.3 * 1.10, 1e-6));
  });

  testWidgets('SoriTextTheme 은 폭과 무관하게 같은 fontSize 를 낸다', (tester) async {
    for (final w in [390.0, 1280.0]) {
      tester.view.physicalSize = Size(w, 900);
      tester.view.devicePixelRatio = 1;
      late double size;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        size = SoriTextTheme.of(c).body.fontSize!;
        return const SizedBox();
      })));
      expect(size, 15, reason: 'width $w');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
```
Run: `flutter test test/type_scale_test.dart` → Expected: FAIL (type_scale.dart 없음 / 1280dp에서 16.5).

- [ ] **Step 2: `type_scale.dart` 구현**
```dart
import 'package:flutter/widgets.dart';
import 'tokens.dart';

/// 앱의 **유일한** 글자 배율 권한. `MaterialApp.builder` 에 한 번 설치한다.
///
/// OS 접근성 배율 × [soriComfortScale](폭 600→720dp 에서 1.0→1.10). 예전에는
/// `SoriTextTheme._base` 가 fontSize·letterSpacing 에 comfort 를 직접 곱하고,
/// `SoriStudyScale` 이 학습 카드에 ×1.35 를 또 곱해 태블릿에서 세 배율이
/// 곱해졌다(15 × 1.10 × 1.35 × 2.0 = 44.5px). 이제 여기서 한 번만 곱하고,
/// Material TextTheme 텍스트도 같이 스케일되며 letterSpacing 은 배율을 안 탄다.
class SoriTypeScale extends StatelessWidget {
  const SoriTypeScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final comfort = soriComfortScale(mq.size.width);
    if (comfort <= 1.0) {
      return child;
    }
    return MediaQuery(
      data: mq.copyWith(
        textScaler: SoriComfortTextScaler(mq.textScaler, comfort),
      ),
      child: child,
    );
  }
}

/// ambient [TextScaler] 에 상수 배율을 곱한다(OS 배율과 합성, 대체 아님).
class SoriComfortTextScaler extends TextScaler {
  const SoriComfortTextScaler(this._base, this._factor);
  final TextScaler _base;
  final double _factor;

  @override
  double scale(double fontSize) => _base.scale(fontSize) * _factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is SoriComfortTextScaler &&
      other._base == _base &&
      other._factor == _factor;

  @override
  int get hashCode => Object.hash(_base, _factor);
}
```

- [ ] **Step 3: main.dart builder** — `lib/main.dart:530` `builder: (context, child) => ContentFeedbackControllerScope(` 를 `builder: (context, child) => SoriTypeScale(child: ContentFeedbackControllerScope(` 로 감싸고 닫는 괄호 추가, `import 'widgets/sori/type_scale.dart';` 추가.

- [ ] **Step 4: tokens.dart** — `SoriTextTheme`에서 `_deviceScale` 필드·생성자 인자·`of()`의 `soriComfortScale(...)` 인자 제거, `_base`의 `fontSize: fontSize * _deviceScale` → `fontSize: fontSize`, `letterSpacing: letterSpacing * _deviceScale` → `letterSpacing: letterSpacing`. `SoriBreakpoints.tabletComfortScale`·`soriComfortScale` 주석의 "가산적" 문장을 "SoriTypeScale 이 TextScaler 에 한 번 곱한다"로 고친다.

- [ ] **Step 5: button.dart** — `:122` `final visualFontSize = _fontSize * comfortScale;` → `final visualFontSize = _fontSize;` (높이·패딩·아이콘의 comfort 곱은 유지). `:188` `fontFamily: 'Pretendard'`는 Task 1에서 이미 토큰.

- [ ] **Step 6: SoriStudyScale 제거** — `responsive.dart:17-40`의 `_studyRampStart/_studyRampEnd/_studyProgress/soriStudyScale` 중 `soriStudyScale`만 삭제(`_studyProgress`는 `soriStudyContentMaxWidth`가 쓰므로 유지), `:175-216`의 `SoriStudyScale`·`_StudyTextScaler` 삭제. 호출 17곳은 `SoriStudyScale(child: X)` → `X` (감싼 괄호만 걷는다; 들여쓰기 정리). `satz_bauen_quest.dart:562` `final scale = soriStudyScale(...)` → `const scale = 1.0;` 후 `scale`을 쓰는 식을 따라가 곱을 제거(식이 `x * scale`뿐이면 변수째 삭제). `test/study_scale_test.dart`에서 `soriStudyScale`·`SoriStudyScale` 그룹 삭제(`soriStudyContentMaxWidth`·`SoriStudyClamp` 그룹 유지). `responsive.dart` 상단 주석의 "hero text scale" 문장을 "폭 램프만 남기고 글씨 배율은 SoriTypeScale 로 이관(2026-08-19)"으로.

- [ ] **Step 7: 검증·커밋**
Run: `flutter analyze` · `flutter test test/type_scale_test.dart test/study_scale_test.dart test/sori_tablet_responsive_contract_test.dart test/game_layout_test.dart test/vocab_pack_typography_test.dart test/vocab_pack_uniform_card_test.dart` → PASS
```powershell
git add -A lib test
git commit -m "feat(typography): 글자 배율 권한을 SoriTypeScale 하나로 합친다 (comfort×study 곱 제거)"
```

---

### Task 3: 단일 램프 `SoriTypeRamp` + `SoriTextTheme`·Material `TextTheme` 파생

**Files:**
- Modify: `lib/widgets/sori/tokens.dart`(SoriTextTheme 전체), `lib/theme.dart:35-247`
- Create: `test/type_ramp_test.dart`
- Regenerate: `test/goldens/baselines/*.png` 중 변하는 것

**Interfaces:**
- Produces: `class SoriTypeRole { final String name; final double size; final FontWeight weight; final double spacing; final double height; final bool tabular; }`와 `abstract final class SoriTypeRamp { static const koHero, hero, display, koDisplay, numeral, h1, koDisplaySm, h2, h3, gloss, body, glossSm, cardTitle, bodySmall, label, caption, meta, cardSubtitle, eyebrow; static const List<SoriTypeRole> all; }`. `SoriTextTheme` 새 getter: `koHero`, `koDisplaySm`, `glossSm`. 삭제: `serifDisplay`(호출 0).

- [ ] **Step 1: 실패하는 테스트** — `test/type_ramp_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  test('램프에 w800/w900 이 없고 하한이 12 미만으로 내려가지 않는다', () {
    for (final r in SoriTypeRamp.all) {
      expect(r.weight.index, lessThanOrEqualTo(FontWeight.w700.index), reason: r.name);
      expect(r.size, greaterThanOrEqualTo(12), reason: r.name);
      expect(r.height, greaterThanOrEqualTo(1.1), reason: r.name);
    }
  });
  test('한국어 역할은 height ≥ 1.25, 본문은 1.5', () {
    expect(SoriTypeRamp.koDisplay.height, greaterThanOrEqualTo(1.25));
    expect(SoriTypeRamp.koDisplaySm.height, greaterThanOrEqualTo(1.25));
    expect(SoriTypeRamp.body.height, 1.5);
    expect(SoriTypeRamp.meta.size, 12.5);
    expect(SoriTypeRamp.meta.weight, isNot(SoriTypeRamp.caption.weight));
  });
  test('Material TextTheme 은 램프에서 파생된다', () {
    final tt = AppTheme.light.textTheme;
    expect(tt.displayLarge!.fontSize, SoriTypeRamp.hero.size);
    expect(tt.displayLarge!.fontWeight, FontWeight.w700);
    expect(tt.bodyLarge!.fontSize, SoriTypeRamp.body.size);
    expect(tt.bodyLarge!.height, SoriTypeRamp.body.height);
    expect(tt.labelSmall!.fontSize, greaterThanOrEqualTo(12.5));
    for (final s in [tt.displayLarge, tt.headlineMedium, tt.bodyMedium, tt.labelSmall]) {
      expect(s!.fontFamily, SoriFonts.sans);
    }
  });
  testWidgets('SoriTextTheme 이 램프 값을 그대로 낸다', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Builder(builder: (c) {
      final t = SoriTextTheme.of(c);
      expect(t.koHero.fontSize, 56);
      expect(t.koDisplaySm.fontSize, 24);
      expect(t.glossSm.fontSize, 15);
      expect(t.h1.fontWeight, FontWeight.w700);
      expect(t.label.fontWeight, FontWeight.w600);
      expect(t.cardSubtitle.fontSize, 12.5);
      return const SizedBox();
    })));
  });
}
```
Run → Expected: FAIL (`SoriTypeRamp` 없음).

- [ ] **Step 2: `SoriTypeRamp` + `SoriTextTheme` 재작성** (`tokens.dart`, 기존 `SoriTextTheme` 클래스 자리):
```dart
/// 램프 한 칸 — 색은 없다(색은 SoriTextTheme 가 surface 로 입힌다).
class SoriTypeRole {
  const SoriTypeRole(this.name, this.size, this.weight, {required this.spacing, required this.height, this.tabular = false});
  final String name;
  final double size;
  final FontWeight weight;
  final double spacing;
  final double height;
  final bool tabular;
}

/// **유일한 타이포 램프** (2026-08-19, Wanted Sans 기준). `SoriTextTheme` 과
/// `AppTheme._buildTextTheme` 둘 다 여기서 읽는다 — 값을 두 군데 적지 말 것.
/// 원칙: w800/w900 없음 · 하한 12.5 · 한국어 height ≥ 1.25 · 본문 1.5 ·
/// 자간은 대형만 음수, 본문 이하 0.
abstract final class SoriTypeRamp {
  static const koHero = SoriTypeRole('koHero', 56, FontWeight.w700, spacing: 0, height: 1.10);
  static const hero = SoriTypeRole('hero', 36, FontWeight.w700, spacing: -0.4, height: 1.12);
  static const display = SoriTypeRole('display', 30, FontWeight.w700, spacing: -0.3, height: 1.18);
  static const koDisplay = SoriTypeRole('koDisplay', 30, FontWeight.w700, spacing: -0.2, height: 1.28);
  static const numeral = SoriTypeRole('numeral', 30, FontWeight.w700, spacing: -0.2, height: 1.1, tabular: true);
  static const h1 = SoriTypeRole('h1', 24, FontWeight.w700, spacing: -0.3, height: 1.25);
  static const koDisplaySm = SoriTypeRole('koDisplaySm', 24, FontWeight.w700, spacing: -0.1, height: 1.32);
  static const h2 = SoriTypeRole('h2', 20, FontWeight.w700, spacing: -0.2, height: 1.3);
  static const h3 = SoriTypeRole('h3', 17, FontWeight.w600, spacing: -0.1, height: 1.35);
  static const gloss = SoriTypeRole('gloss', 17, FontWeight.w500, spacing: 0, height: 1.45);
  static const body = SoriTypeRole('body', 15, FontWeight.w500, spacing: 0, height: 1.5);
  static const glossSm = SoriTypeRole('glossSm', 15, FontWeight.w500, spacing: 0, height: 1.45);
  static const cardTitle = SoriTypeRole('cardTitle', 15, FontWeight.w700, spacing: -0.1, height: 1.35);
  static const bodySmall = SoriTypeRole('bodySmall', 14, FontWeight.w500, spacing: 0, height: 1.45);
  static const label = SoriTypeRole('label', 13, FontWeight.w600, spacing: 0.1, height: 1.25);
  static const caption = SoriTypeRole('caption', 12.5, FontWeight.w500, spacing: 0, height: 1.4);
  static const meta = SoriTypeRole('meta', 12.5, FontWeight.w600, spacing: 0, height: 1.35);
  static const cardSubtitle = SoriTypeRole('cardSubtitle', 12.5, FontWeight.w500, spacing: 0, height: 1.4);
  static const eyebrow = SoriTypeRole('eyebrow', 12, FontWeight.w700, spacing: 1.2, height: 1.2);
  static const List<SoriTypeRole> all = [koHero, hero, display, koDisplay, numeral, h1, koDisplaySm, h2, h3, gloss, body, glossSm, cardTitle, bodySmall, label, caption, meta, cardSubtitle, eyebrow];
}

class SoriTextTheme {
  final SoriSurfaces _s;
  const SoriTextTheme._(this._s);
  static SoriTextTheme of(BuildContext context) => SoriTextTheme._(SoriSurfaces.of(context));

  TextStyle get koHero => _style(SoriTypeRamp.koHero);
  TextStyle get hero => _style(SoriTypeRamp.hero);
  TextStyle get display => _style(SoriTypeRamp.display);
  TextStyle get koDisplay => _style(SoriTypeRamp.koDisplay);
  TextStyle get koDisplaySm => _style(SoriTypeRamp.koDisplaySm);
  TextStyle get numeral => _style(SoriTypeRamp.numeral);
  TextStyle get h1 => _style(SoriTypeRamp.h1);
  TextStyle get h2 => _style(SoriTypeRamp.h2);
  TextStyle get h3 => _style(SoriTypeRamp.h3);
  TextStyle get gloss => _style(SoriTypeRamp.gloss, color: _s.textMuted);
  TextStyle get glossSm => _style(SoriTypeRamp.glossSm, color: _s.textMuted);
  TextStyle get body => _style(SoriTypeRamp.body);
  TextStyle get bodySmall => _style(SoriTypeRamp.bodySmall, color: _s.textMuted);
  TextStyle get cardTitle => _style(SoriTypeRamp.cardTitle);
  TextStyle get cardSubtitle => _style(SoriTypeRamp.cardSubtitle, color: _s.textMuted);
  TextStyle get label => _style(SoriTypeRamp.label);
  TextStyle get caption => _style(SoriTypeRamp.caption, color: _s.textMuted);
  TextStyle get meta => _style(SoriTypeRamp.meta, color: _s.textMuted);
  TextStyle get eyebrow => _style(SoriTypeRamp.eyebrow, color: SoriColors.accent);

  TextStyle _style(SoriTypeRole r, {Color? color}) => TextStyle(
    fontFamily: SoriFonts.sans,
    fontSize: r.size,
    fontWeight: r.weight,
    letterSpacing: r.spacing,
    height: r.height,
    color: color ?? _s.text,
    fontFeatures: r.tabular ? const [FontFeature.tabularFigures()] : null,
  );
}
```
기존 getter 주석(eyebrow·koDisplay·meta·cardTitle의 역사 노트)은 해당 getter 위로 옮겨 보존한다. `serifDisplay` 삭제(호출 0 — `grep -rn serifDisplay lib test`로 확인).

- [ ] **Step 3: theme.dart 파생** — `_buildTextTheme(s)`를 아래로 교체하고, 파일 내 `fontFamily: 'Pretendard'`(Task 1에서 토큰화됨)와 컴포넌트 값 갱신: AppBar `titleTextStyle` → `_from(SoriTypeRamp.h2, s.text)`; Chip label/secondaryLabel fontSize 12 → 12.5; ListTile subtitle 12 → 12.5; NavigationBar label 11 → 12.
```dart
  static TextStyle _from(SoriTypeRole r, Color color, {double? spacing}) => TextStyle(
    fontFamily: SoriFonts.sans,
    fontSize: r.size,
    fontWeight: r.weight,
    height: r.height,
    letterSpacing: spacing ?? r.spacing,
    color: color,
  );

  static TextTheme _buildTextTheme(SoriSurfaces s) => TextTheme(
    displayLarge: _from(SoriTypeRamp.hero, s.text),
    displayMedium: _from(SoriTypeRamp.display, s.text),
    displaySmall: _from(SoriTypeRamp.koDisplaySm, s.text),
    headlineLarge: _from(SoriTypeRamp.h1, s.text),
    headlineMedium: _from(SoriTypeRamp.h2, s.text),
    headlineSmall: _from(SoriTypeRamp.h3, s.text),
    titleLarge: _from(SoriTypeRamp.cardTitle, s.text),
    titleMedium: _from(SoriTypeRamp.bodySmall, s.text).copyWith(fontWeight: FontWeight.w600),
    titleSmall: _from(SoriTypeRamp.label, s.textMuted),
    bodyLarge: _from(SoriTypeRamp.body, s.text),
    bodyMedium: _from(SoriTypeRamp.bodySmall, s.text),
    bodySmall: _from(SoriTypeRamp.caption, s.textMuted),
    labelLarge: _from(SoriTypeRamp.label, s.text),
    labelMedium: _from(SoriTypeRamp.meta, s.textMuted),
    labelSmall: _from(SoriTypeRamp.caption, s.textMuted, spacing: 0.3),
  );
```

- [ ] **Step 4: 테스트·골든** — Run: `flutter test test/type_ramp_test.dart test/typography_guard_test.dart` → PASS. 골든: `flutter test test/goldens --update-goldens` 후 `git status`로 바뀐 PNG 확인, 바뀐 것은 before/after를 직접 열어(Read) 글자 크기·굵기 변화만인지 눈으로 확인. 그 다음 `flutter test test/goldens` PASS.
  래칫 `FontWeight.w800`·`w900` 상한을 실측으로 하향(`grep -rc "FontWeight.w800" lib | awk -F: '{s+=$2} END {print s}'` 결과로).

- [ ] **Step 5: 커밋**
```powershell
git add -A lib test
git commit -m "feat(typography): 램프를 SoriTypeRamp 하나로 — SoriTextTheme·Material TextTheme 파생, w800/w900 토큰 제거"
```

---

### Task 4: `SoriKoreanText` / `SoriGlossText` (위젯 + 테스트만)

**Files:**
- Create: `lib/widgets/sori/content_type.dart`, `test/content_type_widgets_test.dart`

**Interfaces:**
- Produces: `SoriKoreanText(String text, {SoriKoreanRole? role, double? fontSize, int? maxLines, TextAlign textAlign = TextAlign.center, Key? key})`, `enum SoriKoreanRole { hero, display, displaySm }`, `SoriKoreanRole soriKoreanRoleFor(String text)`, `SoriGlossText(String text, {int? maxLines, TextAlign textAlign = TextAlign.center})`.

- [ ] **Step 1: 실패하는 테스트** — `test/content_type_widgets_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_type.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';

void main() {
  test('역할 스냅: 1자 → hero, 14자 이하 → display, 그 이상 → displaySm', () {
    expect(soriKoreanRoleFor('가'), SoriKoreanRole.hero);
    expect(soriKoreanRoleFor('안녕하세요'), SoriKoreanRole.display);
    expect(soriKoreanRoleFor('어렵더라도 포기하지 마세요.'), SoriKoreanRole.display); // 공백 제외 13자
    expect(soriKoreanRoleFor('오늘은 날씨가 좋아서 공원에 갔어요.'), SoriKoreanRole.displaySm);
  });
  testWidgets('SoriPhraseWrap 으로 렌더하고 FittedBox 를 쓰지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const Scaffold(body: SoriKoreanText('어렵더라도 포기하지 마세요.'))));
    expect(find.byType(SoriPhraseWrap), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
    final wrap = tester.widget<SoriPhraseWrap>(find.byType(SoriPhraseWrap));
    expect(wrap.style!.fontSize, 30);
  });
  testWidgets('fontSize 오버라이드는 역할 크기보다 우선한다', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const Scaffold(body: SoriKoreanText('가', fontSize: 40))));
    expect(tester.widget<SoriPhraseWrap>(find.byType(SoriPhraseWrap)).style!.fontSize, 40);
  });
  testWidgets('SoriGlossText 는 40자 초과면 glossSm', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const Scaffold(body: Column(children: [
      SoriGlossText('Ich bin Student.'),
      SoriGlossText('Auch wenn es schwierig ist, gib bitte nicht auf und mach weiter.'),
    ]))));
    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts[0].style!.fontSize, 17);
    expect(texts[1].style!.fontSize, 15);
  });
}
```
Run → FAIL.

- [ ] **Step 2: 구현** — `lib/widgets/sori/content_type.dart`:
```dart
import 'package:flutter/material.dart';
import 'ko_wrap.dart';
import 'tokens.dart';

/// 콘텐츠 플레이어 한국어의 단일 진입점. 크기는 연속 배율이 아니라
/// **이산 3단계**(koHero 56 / koDisplay 30 / koDisplaySm 24)로 스냅한다.
/// `FittedBox` 를 쓰지 않는다 — 상자를 키우지 않고 한 단계 내린다(BIBLE §3).
/// 덱 균일 크기(`soriUniformFitSize`)는 [fontSize] 로 넘긴다(Phase 4).
enum SoriKoreanRole { hero, display, displaySm }

SoriKoreanRole soriKoreanRoleFor(String text) {
  final n = text.replaceAll(RegExp(r'\s+'), '').runes.length;
  if (n <= 1) {
    return SoriKoreanRole.hero;
  }
  if (n <= 14) {
    return SoriKoreanRole.display;
  }
  return SoriKoreanRole.displaySm;
}

class SoriKoreanText extends StatelessWidget {
  const SoriKoreanText(this.text, {super.key, this.role, this.fontSize, this.maxLines, this.textAlign = TextAlign.center});
  final String text;
  final SoriKoreanRole? role;
  final double? fontSize;
  final int? maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final base = switch (role ?? soriKoreanRoleFor(text)) {
      SoriKoreanRole.hero => tt.koHero,
      SoriKoreanRole.display => tt.koDisplay,
      SoriKoreanRole.displaySm => tt.koDisplaySm,
    };
    return SoriPhraseWrap(
      text,
      style: fontSize == null ? base : base.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

/// 독일어/영어 뜻. 공백 제외 40자 초과면 한 단계 작은 `glossSm`.
class SoriGlossText extends StatelessWidget {
  const SoriGlossText(this.text, {super.key, this.maxLines, this.textAlign = TextAlign.center});
  final String text;
  final int? maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final long = text.replaceAll(RegExp(r'\s+'), '').runes.length > 40;
    return Text(text, style: long ? tt.glossSm : tt.gloss, textAlign: textAlign, maxLines: maxLines);
  }
}
```
Run: `flutter test test/content_type_widgets_test.dart` → PASS. Commit: `git commit -m "feat(typography): SoriKoreanText/SoriGlossText 단일 진입 위젯 (이산 3단계, FittedBox 없음)"`.

---

### Task 5: 간격 토큰 · 터치 타깃 · 토큰 문서

**Files:**
- Modify: `lib/widgets/sori/tokens.dart:22-39`(Spacing), `lib/widgets/sori/chip.dart:43,74-77,97-103,118-126`, `lib/widgets/sori/button.dart:91-95`, `docs/HANGUL_SORI_DESIGN_TOKENS.md`
- Create: `test/spacing_tokens_test.dart`

**Interfaces:**
- Produces: `Spacing.cardGap = 12`, `Spacing.sectionGap = 24`, `Spacing.gutter = 16`, `Spacing.gutterWide = 24`, `double soriPageGutter(BuildContext)`, `double soriScrollBottomInset(BuildContext)`. 삭제: `Spacing.pageH/cardInner/cardCompact`.

- [ ] **Step 1: 실패하는 테스트** — `test/spacing_tokens_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  test('간격 토큰', () {
    expect(Spacing.cardGap, 12);
    expect(Spacing.sectionGap, 24);
    expect(Spacing.gutter, 16);
    expect(Spacing.gutterWide, 24);
  });
  testWidgets('페이지 거터·하단 인셋은 폭/세이프에어리어를 따른다', (tester) async {
    late double gutter390, bottom;
    await tester.pumpWidget(MediaQuery(data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(bottom: 34)), child: Builder(builder: (c) {
      gutter390 = soriPageGutter(c); bottom = soriScrollBottomInset(c); return const SizedBox();
    })));
    expect(gutter390, 16);
    expect(bottom, 34 + 24);
    late double gutter800, bottom0;
    await tester.pumpWidget(MediaQuery(data: const MediaQueryData(size: Size(800, 1280)), child: Builder(builder: (c) {
      gutter800 = soriPageGutter(c); bottom0 = soriScrollBottomInset(c); return const SizedBox();
    })));
    expect(gutter800, 24);
    expect(bottom0, 32);
  });
  testWidgets('탭 가능한 SoriChip 은 44dp 이상, SoriButton.sm 은 44dp', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: Scaffold(body: Column(children: [
      SoriChip(label: 'A1', onTap: () {}),
      const SoriChip(label: 'static'),
      SoriButton.filled('Los', onTap: () {}, size: SoriButtonSize.sm),
    ]))));
    expect(tester.getSize(find.byType(SoriChip).first).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(find.byType(SoriChip).last).height, lessThan(44));
    expect(tester.getSize(find.byType(SoriButton)).height, greaterThanOrEqualTo(44));
  });
}
```
(`SoriButton.filled`의 실제 생성자 시그니처는 `button.dart` 상단을 읽고 맞춘다 — 라벨 위치 인자/`size:` 이름.) Run → FAIL.

- [ ] **Step 2: Spacing 토큰** — `tokens.dart:22-39`에서 `pageH/cardInner/cardCompact` 삭제(참조 0 재확인 `grep -rn "Spacing\.\(pageH\|cardInner\|cardCompact\)" lib test`), 추가:
```dart
  /// 카드와 카드 사이(세로 리스트·그리드 공통). 2026-08-19 타이포 코어.
  static const double cardGap = 12;
  /// 섹션 사이.
  static const double sectionGap = 24;
  /// 페이지 좌우 거터 — 폰 16, ≥600dp 24 ([soriPageGutter]).
  static const double gutter = 16;
  static const double gutterWide = 24;
```
그리고 `Spacing` 클래스 아래에:
```dart
/// 폭에 따른 페이지 좌우 거터 — 폰 [Spacing.gutter], 600dp 이상 [Spacing.gutterWide].
double soriPageGutter(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= SoriBreakpoints.grid ? Spacing.gutterWide : Spacing.gutter;

/// 스크롤 끝 여유 — 홈 인디케이터·제스처 바(`padding.bottom`) 위로 24, 최소 32.
/// `bottom: 80`/`96`/`150` 리터럴 대신 이걸 쓴다.
double soriScrollBottomInset(BuildContext context) {
  final inset = MediaQuery.paddingOf(context).bottom + Spacing.xl;
  return inset < Spacing.xxl ? Spacing.xxl : inset;
}
```

- [ ] **Step 3: chip.dart** — `this.fontSize = 12` → `12.5`; `final minimumHeight = minInteractiveHeight;` → `final minimumHeight = minInteractiveHeight ?? (onTap != null ? 44.0 : null);` (주석: "탭 가능한 칩은 44dp 터치 타깃 — Material 48/Apple 44 중 Wrap 안 인라인을 유지하는 값"). `fontFamily: 'Pretendard'`는 Task 1에서 토큰.

- [ ] **Step 4: button.dart** — `SoriButtonSize.sm => 40` → `44`.

- [ ] **Step 5: 회귀 확인** — Run: `flutter test test/spacing_tokens_test.dart test/circular_feedback_widget_test.dart test/grammar_type_filter_test.dart test/screen_smoke_test.dart test/visual_layout_regression_test.dart` → PASS (칩 44dp로 문법 필터행 44dp `SizedBox`에 딱 맞는지 — 넘치면 `grammar_screen.dart:777` 행 높이를 `48`로).

- [ ] **Step 6: 토큰 문서** — `docs/HANGUL_SORI_DESIGN_TOKENS.md`: 머리의 `Companion to: HANGUL_SORI_STYLE_GUIDE.md` 줄 삭제(파일 부재), `Last Updated: 2026-08-19`, 새 섹션 **`## TYPOGRAPHY`**(폰트 Wanted Sans 5웨이트 + 한글/독일어 실측, 램프 표 = 스펙 §2.1 표 그대로, 배율 규칙 "SoriTypeScale 하나 — OS × comfort(≤1.10), letterSpacing 불변", 금지 "w800/w900 토큰·12.5 미만·FittedBox 역할 텍스트·maxLines:1+ellipsis 문장"), SPACING 섹션에 `cardGap/sectionGap/gutter/gutterWide/soriPageGutter/soriScrollBottomInset` 추가, 삭제 토큰 3개 제거.

- [ ] **Step 7: 커밋** — `git add -A lib test docs/HANGUL_SORI_DESIGN_TOKENS.md; git commit -m "feat(tokens): 카드/섹션/거터/하단 인셋 간격 토큰 + 칩·sm 버튼 44dp + 토큰 문서 TYPOGRAPHY"`

---

### Task 6: 문장급 잘림 해제 + 고정 높이 수정

**Files (현재 main 라인):**
- `lib/screens/hard_words_screen.dart:184` · `lib/screens/wordbook_search_screen.dart:284` · `lib/widgets/sori/content_feed.dart:521` · `lib/widgets/sori/deck_coach.dart:115` · `lib/widgets/sori/empty_state.dart:141,158` · `lib/screens/scenarios_list_screen.dart:783,882` · `lib/screens/speed_match_screen.dart:342` · `lib/screens/sarangbang_screen.dart:522` · `lib/screens/discover_screen.dart:285` · `lib/screens/learning_path_screen.dart:676,684,688` · `lib/widgets/sori/module_card.dart:174` · `lib/widgets/sori/mission_context_bar.dart:78` · `lib/widgets/sori/illustrated_card.dart:121` · `lib/widgets/sori/pack_card.dart:116`
- 고정 높이: `lib/screens/quest_engines/diktat_quest.dart:508` · `lib/screens/kkeunmari_screen.dart:604` · `lib/screens/legacy_vocab_screen.dart:661` · `lib/screens/vocab_packs_screen.dart:356` · `lib/screens/personal_room_furnish_screen.dart:691`

- [ ] **Step 1: 잘림 해제** — 각 위치에서 해당 `Text`의 `maxLines`/`overflow`를 스펙 §4.1 표대로 바꾼다. 규칙: 문장(뜻·정의·안내·빈 상태·저장 표현) → `maxLines`·`overflow` 둘 다 **삭제**; 제목·CTA·힌트 → `maxLines: 2`(overflow ellipsis 유지); `learning_path_screen.dart:684` `ConstrainedBox(constraints: const BoxConstraints(maxWidth: 72), child:` 제거하고 부모 Row에서 그 자식을 `Flexible(child: …)`로. `content_feed.dart:521` `maxLines: 1` → `2` (`Center` 안이라 2줄이어도 44dp 안에서 가운데). 각 파일에서 바꾼 Text가 **가로 무한 제약(Row 안 비-Flexible)** 안에 있지 않은지 확인 — 있으면 `Expanded/Flexible`로 감싼다(안 그러면 multi-line 이 오버플로).

- [ ] **Step 2: 고정 높이** —
  - `diktat_quest.dart:508` `SizedBox(height: 22, child: …)` → `ConstrainedBox(constraints: const BoxConstraints(minHeight: 22), child: …)`.
  - `kkeunmari_screen.dart:604` `height: 38` → `constraints: const BoxConstraints(minHeight: 44)`(해당 위젯이 `SizedBox`면 `ConstrainedBox`로 교체).
  - `legacy_vocab_screen.dart:661` `Container(height: 44, …)` → `Container(constraints: const BoxConstraints(minHeight: 44), …)`.
  - `vocab_packs_screen.dart:356` — `childAspectRatio: 0.82` 대신 `LayoutBuilder`가 이미 있으면 그 폭으로, 없으면 `SliverLayoutBuilder`로 셀 폭을 구해 `_packCellAspectRatio(context, cellWidth)`를 쓴다. `sori_stage_catalog_screen.dart:305-325`의 `_cellAspectRatio`를 복사해 `pack_card.dart`에 `double soriPackCardAspectRatio(BuildContext context, double cellWidth)`로 옮기고(이미지 16/10, 제목 2줄 `tt.cardTitle`, 부제 1줄 `tt.cardSubtitle`, 패딩 `Spacing.sm + Spacing.md`, 여유 4) 두 화면이 공유한다. 배율 1.0·360dp에서 현재 0.82와 ±0.05 이내인지 `debugPrint`로 한 번 확인.
  - `personal_room_furnish_screen.dart:691` `mainAxisExtent: 126` → `mainAxisExtent: 126 + (MediaQuery.textScalerOf(context).scale(12.5) - 12.5) * 2`(라벨 1~2줄 여유).

- [ ] **Step 3: 검증·커밋** — Run: `flutter analyze` · `flutter test test/screen_smoke_test.dart test/vocab_pack_typography_test.dart test/vocab_pack_uniform_card_test.dart test/deck_card_geometry_test.dart test/responsive_short_height_test.dart test/sori_stage_responsive_accessibility_test.dart` → PASS.
```powershell
git add -A lib
git commit -m "fix(typography): 문장급 잘림 17곳 해제 + 고정 높이 5곳을 배율 반영으로"
```

---

### Task 7: 잘림 가드 — 헬퍼 · 뷰포트×배율 매트릭스 · 래칫

**Files:**
- Create: `test/support/text_clipping.dart`, `test/text_clipping_matrix_test.dart`
- Modify: `test/sori_stage_responsive_accessibility_test.dart:113-133`, `test/typography_guard_test.dart`

- [ ] **Step 1: 헬퍼** — `test/support/text_clipping.dart`:
```dart
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 렌더 트리의 모든 문단이 잘리지 않았음을 단언한다.
///
/// `takeException()` 은 RenderFlex 오버플로만 잡는다 — `maxLines` 초과로
/// `…` 처리된 문장은 예외를 안 던진다. 여기서는 `RenderParagraph.didExceedMaxLines`
/// 를 직접 본다. [allowTexts] 는 **의도된** 한 줄 라벨(URL 등)만 — 문장 금지.
void expectNoClippedText(WidgetTester tester, {Set<String> allowTexts = const {}, String reason = ''}) {
  final clipped = <String>[];
  void visit(RenderObject ro) {
    if (ro is RenderParagraph && ro.didExceedMaxLines) {
      final t = ro.text.toPlainText();
      if (!allowTexts.contains(t)) {
        clipped.add('"${t.length > 60 ? '${t.substring(0, 60)}…' : t}" size=${ro.size}');
      }
    }
    ro.visitChildren(visit);
  }
  for (final root in tester.binding.renderViews) {
    root.visitChildren(visit);
  }
  expect(clipped, isEmpty, reason: '$reason 잘린 문단:\n${clipped.join('\n')}');
  expect(tester.takeException(), isNull, reason: '$reason 레이아웃 예외');
}
```
(`tester.binding.renderViews`가 이 Flutter 버전에 없으면 `tester.binding.renderView`(단수) 사용.)

- [ ] **Step 2: 매트릭스 테스트** — `test/text_clipping_matrix_test.dart`: `screen_smoke_test.dart`의 `setUp`·`_wrap`(onGenerateRoute 포함)을 그대로 복사하고 화면 목록은 **문법·단어팩 그리드·레거시 단어·한글·듣기·끝말잇기·시나리오 목록·설정·학습 경로·연습 허브·통계·온보딩** 12개. 매트릭스:
```dart
const sizes = [Size(360, 640), Size(390, 844), Size(430, 932), Size(800, 1280)];
const scales = [1.0, 1.3, 2.0];
for (final e in screens.entries) for (final size in sizes) for (final scale in scales)
  testWidgets('${e.key} ${size.width}x${size.height} @${scale}x', (tester) async {
    tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_wrap(e.value));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 2000));
    expectNoClippedText(tester, allowTexts: _allow[e.key] ?? const {}, reason: '${e.key} ${size} @$scale');
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pump();
  });
```
`_allow`는 처음엔 빈 맵. Run: `flutter test test/text_clipping_matrix_test.dart` → 실패 목록을 받는다.

- [ ] **Step 3: 실패 처리 규칙** — 1.0×·1.3×에서 잘린 **문장·제목·뜻**은 해당 위젯을 고친다(Task 6과 같은 방식: maxLines 해제/2줄, Row 안이면 Flexible). 2.0×에서만 잘리는 **필 칩·단일 단어 라벨·URL**은 `_allow`에 텍스트를 넣되 항목마다 `// 이유` 주석. 문장은 절대 allow에 넣지 않는다. 고친 뒤 매트릭스 PASS까지 반복.

- [ ] **Step 4: 기존 매트릭스에 연결** — `sori_stage_responsive_accessibility_test.dart:127-131`의 `expect(tester.takeException(), isNull);` 앞에 `expectNoClippedText(tester, reason: '$size @$textScale');` 추가(import `support/text_clipping.dart`). 실패하면 Step 3 규칙으로.

- [ ] **Step 5: 래칫 추가** — `typography_guard_test.dart`에 두 테스트: `maxLines: 1` 개수 ≤ 실측(`grep -rc "maxLines: 1" lib`) , `TextOverflow.ellipsis` ≤ 실측. 주석에 "문장에는 새로 걸지 않는다 — 내려가기만". `w900`·`w800`·`raw TextStyle` 상한도 실측으로 하향.

- [ ] **Step 6: 커밋** — `git add -A test lib; git commit -m "test(typography): didExceedMaxLines 잘림 가드 + 4뷰포트×3배율 매트릭스 + maxLines/ellipsis 래칫"`

---

### Task 8: 문서 · 전체 테스트 · 웹 증빙 · PR

**Files:**
- Modify: `docs/SESSION_LOG.md`(최상단), `docs/CONTENT_UIUX_FINISH_PLAN_2026-08-19.md`(Phase 3 머리 한 줄), `AGENTS.md`(Pretendard 언급이 있으면 Wanted Sans로 — `grep -n Pretendard AGENTS.md`)

- [ ] **Step 1: 전체 테스트** — `flutter analyze`(클린) → `flutter test`(전체). 실패가 있으면 이 계획의 변경 때문인지 확인하고 고친다(골든은 Task 3에서 갱신됨).
- [ ] **Step 2: 웹 증빙** — `.claude/launch.json`에 web-server 설정이 있으면 `preview_start`로 띄우고(없으면 `flutter run -d web-server --web-port 8080` 설정 추가), 360/390/430/800 폭에서 문법·단어팩·듣기 플레이 화면 스크린샷 4장 — 한국어가 Wanted Sans로 렌더되는지(맑은 고딕 아님) 눈으로 확인. 실패(폰트 미적용)면 `flutter clean` 후 재빌드(폰트 매니페스트 캐시).
- [ ] **Step 3: SESSION_LOG** — 최상단에 항목 "2026-08-19 (Claude Fable 5, Windows) — 타이포 코어: Wanted Sans 한글 복구 · 램프 하나 · 배율 하나 · 간격 · 잘림 가드": 무엇을 왜(§0 실측 5건 요약, 특히 한글 0글리프), 고침(Task 1~7 한 줄씩), 검증(테스트 목록·골든 재생성·웹 스크린샷), 커밋해시(PR 브랜치 범위). `CONTENT_UIUX_FINISH_PLAN` Phase 3 제목 아래에 `> 2026-08-19: §3.1·3.2·3.4 는 docs/superpowers/specs/2026-08-19-typography-core-design.md 로 실행됨(PR 링크). §3.3 은 #93.` 한 줄.
- [ ] **Step 4: 커밋·푸시·PR**
```powershell
git add docs AGENTS.md
git commit -m "docs(typography): 세션 로그 + 계획서 Phase 3 표식"
git push -u origin claude/typography-core-20260819
gh pr create --title "feat(typography): Wanted Sans 한글 복구 · 램프/배율 하나 · 간격 토큰 · 잘림 가드" --body-file <요약: §0 실측, 변경 블록, 검증, 스크린샷, 범위 밖(Phase 4 맥)>
```
머지하지 않는다 — Jin 승인 대기. PR 본문 끝에 `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

---

## Self-Review
- 스펙 커버리지: §1 → Task 1 · §2.1/2.2 → Task 3 · §2.3 → Task 2 · §2.4 완료(#93) · §2.5 → Task 4 · §3 → Task 5 · §4.1/4.2 → Task 6 · §4.3 → Task 7 · §6 → Task 8. 누락 없음.
- 타입 일관성: `SoriTypeRole(name,size,weight,{spacing,height,tabular})`·`SoriTypeRamp.all`·`SoriTextTheme.koHero/koDisplaySm/glossSm`·`SoriTypeScale`·`SoriComfortTextScaler`·`soriPageGutter`·`soriScrollBottomInset`·`SoriKoreanRole`·`soriKoreanRoleFor`·`expectNoClippedText` — Task 간 동일 이름.
- 플레이스홀더: 없음(Task 6은 파일:라인과 규칙, Task 7 Step 3은 판정 규칙이 명시됨).
