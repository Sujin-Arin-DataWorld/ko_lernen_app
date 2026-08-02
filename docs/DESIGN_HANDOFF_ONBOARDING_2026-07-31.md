# 디자인 핸드오프 — 온보딩 레벨 선택 v4 「마당의 아침」

- 날짜: 2026-07-31
- 진단 문서: `docs/DESIGN_CRITIQUE_ONBOARDING_2026-07-31.md`
- 구현 파일: `lib/screens/onboarding_level_screen.dart`

---

## 1. 변경 파일 목록

| 파일 | 변경 | 비고 |
|------|------|------|
| `lib/screens/onboarding_level_screen.dart` | **전면 재작성** (565 → 약 800줄) | v3 백업은 git |
| `lib/widgets/sori/hanok_tokens.dart` | `HanokLevelPalette` 신설 (+74줄) | 기존 토큰 변경 없음 |
| `lib/l10n/app_de.arb` | 1개 값 교체 + 16개 키 추가 | |
| `lib/l10n/app_en.arb` | 1개 값 교체 + 16개 키 추가 | |
| `lib/l10n/generated/app_localizations.dart` | 추상 getter 16개 | `gen-l10n` 대체 (수동) |
| `lib/l10n/generated/app_localizations_de.dart` | override 16개 | |
| `lib/l10n/generated/app_localizations_en.dart` | override 16개 | |

**에셋 변경 없음.** `pubspec.yaml`도 그대로 (`assets/video/loops/`가 이미 선언됨).

---

## 2. 화면 구조

```
Scaffold (bg: 한지 크림 #FAF6EC)
└ AnnotatedRegion<SystemUiOverlayStyle>   ← 상태바 아이콘 dark 강제
  └ Stack
    1. 아침 마당 그라데이션   #ECDDCD(0~32%) → #FAF6EC(62~100%)
    2. HanjiTexture          알파 0 크림 base + noiseAlpha 0.09  (닥 섬유)
    3. AmbientParticles(12)  라이트 모드 → 벚꽃잎
    4. SafeArea > LayoutBuilder > SingleChildScrollView(soriClampPadding 480)
       ├ _WelcomeHero          [정사각 영상] ─ [말풍선]        Row, 충돌 0
       ├ GiwaPattern           기와 처마 한 줄 (황토 α0.5)
       ├ 타이틀 26 / 부제 14
       ├ _LevelCard × 4        세로 사다리
       ├ _CompareCta           「Unsicher? Level vergleichen」 48dp
       └ 안내문 12.5 + 스킵 48dp
```

### 히어로 이음매를 지우는 방법 (중요)

히어로 영상은 배경이 투명이 아니라 **크림 `#ECDDCD`** 다. 그래서
`_heroBackdrop = Color(0xFFECDDCD)` 로 페이지 상단 32%를 **같은 색으로 평평하게**
깔았다. 영상 사각형과 페이지 배경이 같은 색이라 경계선이 보이지 않는다.
따라서 **영상을 자르지 않는다** — 원 구도가 그대로 나온다.

> ⚠️ 영상을 교체하면 새 영상의 가장자리 색을 실측해 `_heroBackdrop`을 맞출 것.
> 안 맞추면 히어로 주변에 옅은 사각 테두리가 드러난다.

### 한지 결 base color 함정

`HanjiTexture`의 `_HanjiPainter`는 `baseColor.computeLuminance() > 0.5`로
라이트/다크 섬유색을 고른다. `Colors.transparent`(RGB 0,0,0)를 주면 **다크 모드
섬유색(거의 흰색)이 선택돼 결이 통째로 사라진다.** 그래서 알파만 0인
`Color(0x00FAF6EC)`(RGB는 크림)를 넘긴다.

---

## 3. 디자인 토큰

### 신설 — `HanokLevelPalette` (`hanok_tokens.dart`)

```dart
HanokLevelPalette.a1        // #2E7D68  봄 · 청
HanokLevelPalette.a2        // #8F6C14  여름 · 황
HanokLevelPalette.b1        // #A0403C  가을 · 적
HanokLevelPalette.b2        // #44607F  겨울 · 청금
HanokLevelPalette.of('a2')      // → Color
HanokLevelPalette.rankOf('b1')  // → 3
HanokLevelPalette.rankCount     // → 4
```

**기능색(`success`/`warning`/`danger`)과 의도적으로 분리된 서열색.**
`SoriColors.success == SoriColors.primary == #1F7A6B` 이라 v3에서 A1·A2가
같은 색이던 버그가 원인.

> **색만으로 서열을 전달하지 말 것.** 네 색의 상호 명도 대비는 1.02~1.34:1.
> 반드시 `rankOf()` 기반 채움 도트를 함께 쓴다.

### 타이포 스케일 (이 화면 확정값)

| 역할 | 크기 / 굵기 | 색 | 대비 |
|------|-----------|-----|------|
| 화면 타이틀 | 26 / w800 / ls −0.4 | `lightText` | 15.47:1 |
| 부제 | 14 / w500 / lh 1.45 | `lightTextMuted` | 5.52:1 |
| 말풍선 | 15 / w700 | `hanjiInk` on `baek` | 13.6:1 |
| 카드 제목 | 17 / w800 / ls −0.2 | `lightText` | 15.47:1 |
| 카드 설명 | 13.5 / w500 / lh 1.35 | `lightTextMuted` | 5.52:1 |
| 한국어 예문 | **16 / w700** | `lightText` | 15.47:1 |
| 모국어 뜻 | 12.5 / w500 | `lightTextMuted` | 5.52:1 |
| 레벨 배지 | 13 / w900 / ls 0.6 | white on 사계색 | ≥4.86:1 |
| 비교 CTA | 14 / w700 | `primaryDark` on `primarySoft` | 9.9:1 |
| 시트 타이틀 | 20 / w800 | `lightText` | — |
| 시트 라벨 | 10.5 / w800 / ls 0.7 / UPPER | 사계색 or muted | ≥4.5:1 |
| 안내문 | 12.5 / w500 | `lightTextMuted` | 5.52:1 |
| 스킵 | 13 / w700 | `primary` | 4.8:1 |

**규칙 2가지**
1. 이 화면 최소 글자 **12.5px**. 11px 이하 금지.
2. **어떤 텍스트에도 `maxLines`를 걸지 않는다** — 시스템 글자 배율 200%에서도
   문장이 온전해야 한다. (v3 최대 결함이 잘린 설명이었다.)

### 스페이싱 · 형태

| 항목 | 값 | 토큰 |
|------|-----|------|
| 페이지 좌우 padding | 16 | `Spacing.lg` |
| 콘텐츠 폭 클램프 | 480 | `SoriBreakpoints.content` |
| 히어로 한 변 | `clamp(108, min(h×0.21, 200, contentW×0.50))` | — |
| 히어로 ↔ 말풍선 간격 | 12 | `Spacing.md` |
| 카드 간격 | 12 | `Spacing.md` |
| 카드 모서리 | 상단 24 / 하단 16 (처마 곡선) | `SoriRadius.md + HanokSizing.eavesBoostTop` |
| 카드 색띠 | width 6, 카드 전체 높이 | `Positioned(top·bottom)` |
| 카드 테두리 | `lightBorderStrong` α0.55 | 크림 대비 3:1↑ (SC 1.4.11) |
| 최소 터치 타깃 | 48dp | 비교 CTA · 스킵 |

**색띠는 `IntrinsicHeight`가 아니라 `Stack + Positioned(top:0, bottom:0)`.**
`IntrinsicHeight`는 여러 줄 `Text`의 intrinsic 측정을 매 프레임 두 번 돌고
글자 배율이 커질수록 오차가 생긴다.

---

## 4. 신규 문자열 (16개 + 1개 교체)

### 교체

| 키 | de | en |
|----|-----|-----|
| `onboardingTigerGreeting` | `Willkommen!\nWo möchtest du starten?` | `Welcome!\nWhere do you want to start?` |

**기존 값은 `환영해요!\n어떤 레벨부터 시작할까요?` 로 두 로케일 모두 한글 고정이었다.**
이제 기기 언어(`localeNotifier` → 없으면 시스템)에 따라 de/en으로 나온다.
`supportedLocales = [de, en]` 이므로 독일어 기기는 독일어, 그 외는 영어다.

### 신규

| 키 | de | en |
|----|-----|-----|
| `onboardingDifficulty` | Schwierigkeit | Difficulty |
| `onboardingExampleLabel` | So klingt dieses Level | What this level sounds like |
| `onboardingCompareCta` | Unsicher? Level vergleichen | Not sure? Compare the levels |
| `onboardingCompareTitle` | Was ändert sich pro Level? | What changes at each level? |
| `onboardingCompareIntro` | Frühere Level bleiben immer offen — … | Earlier levels always stay open — … |
| `onboardingCompareColCan` | Das kannst du schon | What you can already do |
| `onboardingCompareColLearn` | Das lernst du hier | What you'll learn here |
| `onboardingCompareClose` | Verstanden | Got it |
| `onboardingLevelA1Can` | Noch (fast) nichts — vielleicht ein paar Wörter. | Not much yet — maybe a few words. |
| `onboardingLevelA1Learn` | Hangeul lesen und schreiben, dich vorstellen, Zahlen. | Reading and writing Hangeul, introducing yourself, numbers. |
| `onboardingLevelA2Can` | Du liest Hangeul und kennst einfache Begrüßungen. | You read Hangeul and know simple greetings. |
| `onboardingLevelA2Learn` | Bestellen, einkaufen, nach dem Weg fragen, die Höflichkeitsform -요. | Ordering, shopping, asking for directions, the polite -요 form. |
| `onboardingLevelB1Can` | Du führst einfache Gespräche über den Alltag. | You handle simple everyday conversations. |
| `onboardingLevelB1Learn` | Erzählen, Meinung äußern, Sätze verbinden, Vergangenheit. | Telling stories, giving opinions, linking sentences, past tense. |
| `onboardingLevelB2Can` | Du sprichst flüssig über Alltagsthemen. | You speak fluently about everyday topics. |
| `onboardingLevelB2Learn` | Beruf und Nachrichten, Nuancen, Redewendungen, Ehrerbietung. | Work and news, nuance, idioms, honorifics. |

### 되살린 기존 키

`onboardingExampleA1Trans` ~ `onboardingExampleB2Trans` — arb에 있었지만
**코드 어디에서도 쓰이지 않던** 4개. 이제 카드의 예문 아래 뜻으로 표시된다.
값은 사용자가 쓴 그대로 두었다.

### 한국어 예문 (하드코딩, `_exampleKo`)

| 레벨 | v3 | v4 |
|------|-----|-----|
| A1 | 안녕하세요 | 안녕하세요 (유지) |
| A2 | 아메리카노 톨 | **아메리카노 한 잔 주세요** |
| B1 | 영화 봤어요 | **어제 친구랑 영화 봤어요** |
| B2 | 회의가 길어서 | **회의가 길어져서 좀 늦을 것 같아요** |

**왜 바꿨나**: arb의 독일어 번역이 이미 완성 문장을 가리키고 있었다
(`onboardingExampleB1Trans` = "Gestern war ich mit einem Freund im Kino…").
조각 문장은 그 번역과 짝이 안 맞았다. 게다가 **문장 길이 자체가 레벨 차이의
가장 직관적인 신호**다 — 5자 → 12자 → 13자 → 18자로 계단이 보인다.
조각 문장을 의도한 것이었다면 `_exampleKo` 맵 한 곳만 되돌리면 된다.

---

## 5. 접근성 계약

| 항목 | 구현 |
|------|------|
| 대비 | 전 텍스트 AA 이상 (§3 표). 배경이 결정론적이라 프레임마다 변하지 않음 |
| 색각 | 사계색 + **채움 도트 1~4개** 이중 부호화 |
| 스크린리더 | 카드 1장 = `Semantics` 노드 1개.<br>`"A2 · Grundkenntnisse. Begrüßungen, einfache Bestellungen. Schwierigkeit 2/4."` |
| 터치 타깃 | 카드 ≈110dp / CTA·스킵 48dp 하한 |
| 글자 배율 | `maxLines` 전면 부재 → 200%에서도 문장 온전 |
| reduce-motion | `SoriMotion.reduceMotion` → 영상 대신 포스터 png, `SoriEntrance`는 즉시 표시 |
| 상태바 | `AnnotatedRegion`으로 dark 아이콘 강제 (밝은 배경) |

---

## 6. 폴백 체인

```
영상  assets/video/loops/welcome_hero.mp4
  ↓ !TigerStageVideo.videoReady  ‖  reduce-motion  ‖  초기화 실패
포스터 assets/illustrations/hanok/welcome-hero.png
  ↓ errorBuilder (에셋 없음 / 테스트 환경)
정적  Mascot.tiger(size: side × 0.82)
```

`SoriPosterLoop`(기존 위젯) 재사용 — 포스터를 먼저 깔고 영상 준비되면
400ms 크로스페이드. 영상이 없어도 화면은 정상 동작한다.

---

## 7. 지금 실행할 것 (붙여넣기용)

```powershell
cd C:\Users\vjinn\ELibrary\Downloads\DataSet\hangulsori\ko_lernen_app

# 1) l10n 재생성 — 손으로 넣은 generated 파일을 정식 산출물로 덮어씀
flutter gen-l10n

# 2) 정적 분석
flutter analyze

# 3) 스모크 테스트 (screen_smoke_test 가 이 화면을 렌더한다)
flutter test test/screen_smoke_test.dart

# 4) 실기기 확인 — 온보딩을 다시 보려면 앱 데이터 삭제 후 실행
flutter run
```

`flutter gen-l10n` 결과가 지금 커밋된 `generated/*.dart`와 달라지면
**arb 쪽이 정답**이다 (generated는 산출물).

### 선택 — 히어로 루프 이음새 정제

```powershell
ffmpeg -y -i assets/video/loops/welcome_hero.mp4 `
  -vf "select='between(n\,11\,109)',setpts=PTS-STARTPTS" `
  -an -r 24 -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 19 `
  -movflags +faststart assets/video/loops/welcome_hero_loop.mp4
```

→ 이음새 diff 14.46 → 2.7 (사실상 비가시), AAC 트랙 제거, 4.1초.
만족스러우면 `onboarding_level_screen.dart` 의 `_heroVideo` 상수 한 줄만 교체.

---

## 8. 되돌리기

| 되돌릴 것 | 방법 |
|-----------|------|
| 화면 전체 | `git checkout -- lib/screens/onboarding_level_screen.dart` |
| 한국어 예문만 | `_exampleKo` 맵 4줄 |
| 히어로 영상 | `_heroVideo` 상수 1줄 (+ `_heroBackdrop` 재실측) |
| 사계 팔레트 | `HanokLevelPalette.of()` 호출부 2곳 |
| 말풍선 언어 | arb의 `onboardingTigerGreeting` 2곳 |

---

## 9. 미검증 항목 (정직히)

- **`flutter analyze` / `flutter test`를 돌리지 못했다.** 이 세션 컨테이너에서
  Flutter·Dart SDK 다운로드가 차단되어 있고(403), 사용자 PC의 리눅스 VM에도
  flutter가 없다. 대신 수행한 정적 검증:
  - 괄호·문자열·주석 균형 검사 통과 (5개 파일)
  - 참조한 프로젝트 심볼 38개 전량 정의 대조 통과
  - l10n 추상 getter 938개 ↔ de/en 구현 938개 **완전 일치** (차집합 0)
  - arb 2종 JSON 파싱 + 신규 16키 값 일치 검증
  - import 18개 전부 실사용 확인 (미사용 0)
- **실기기 렌더는 못 봤다.** 히어로 이음매·기와 처마 톤·벚꽃 밀도는
  눈으로 한 번 봐야 한다.
- 루프 이음새(§7)는 미해결 — 판단 대기.
