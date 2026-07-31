# 세션 변경 목록 — 2026-07-31 (까치 정답 연출 + Rollenspiel 축하 영상)

**브랜치** `codex/recover-scene-tts-work-2026-07-31`
**HEAD** `971b582` · **버전** `2.0.1+5`
**작업 트리** clean (전부 커밋됨)

> ⚠️ 이 브랜치엔 **다른 세션의 TTS/씬/보안 리팩터가 같은 커밋에 섞여** 있다.
> 아래 목록은 이 세션(까치·버스트·축하영상)이 건드린 것만이다.

---

## 1. 신규 에셋 (번들 +316KB)

| 파일 | 크기 | 용도 |
|---|---|---|
| `assets/illustrations/burst/burst_pouches.png` | 145 KB | 복주머니 4색(적·청·황·흑) 시트, 900×600 RGBA |
| `assets/illustrations/burst/burst_coins.png` | 171 KB | 엽전 시트, 900×600 RGBA |

- 원본(1536×1024, 2.2MB×2)을 900×600으로 축소해 넣었다. 화면엔 300dp로 그려지므로 충분.
- 알파 실측 완료: `alpha 0-255`, 완전투명 92%/91%, 반투명(글로우) 6.3%/6.5%.
- 이전에 시도했던 분리 스프라이트 5장(`burst_pouch_*.png`·`burst_coin.png`)은 **삭제**됨.

**영상은 신규 추가 없음** — `tiger_celebrate_hifive.mp4` / `magpie_celebrate.mp4`는
이미 번들에 있고 `CharacterClips`가 이미 참조 중이었다. **번들 델타 0.**

## 2. `pubspec.yaml`

- `assets/illustrations/burst/` 폴더 등록 (116행)
- **신규 의존성 없음** → `flutter pub get` 외 네이티브 빌드 영향 없음

## 3. 신규 위젯

### `lib/widgets/sori/dancheong_burst.dart` (신규)

복주머니·엽전 시트가 "파-박" 두 번 터지는 정답 축하.

| | 발사 | 최종 배율 | 회전 |
|---|---|---|---|
| 복주머니 | 0ms | 1.06× | −0.06 rad |
| 엽전 | 70ms 뒤 | 1.26× | +0.07 rad |

- `easeOutExpo` 확산 + 780ms 후 자동 제거. `SoriCelebration`과 동일한 Overlay 구조라
  카드 경계에 잘리지 않는다.
- 폴백: 시트 미디코딩/PNG 부재 → 절차적 `SoriCelebration.burst`.
- `SoriMotion.reduceMotion` 시 no-op.
- ⚠️ 이 파일에 **다른 세션이 `DancheongBurstLayout`/`DancheongBurstPlacement`
  (뷰포트 클램프 헬퍼)를 추가**했다. 현재 `fire()`는 아직 그걸 쓰지 않는다.

## 4. 수정된 위젯

### `lib/widgets/sori/mascot_pop.dart` (전면 재작성)

`MascotPop` → **`MascotPartner`**. API도 바뀜: `visible:` → `celebrating:`.

- **사라졌다 나타나길 반복하지 않고 자세만 전환**한다 → 시나리오당 4~6회
  재등장하던 "중복" 체감이 구조적으로 제거됨.
- 대기 = `perched`(링 opacity 0.35) / 정답 = `celebrate` + 링 점등.
- 연출: 스냅 스케일(0.85→1.28→0.94→1.0) + 링 충격파 3개(녹청·황·주황) +
  `DancheongBurst` 1회 + 햅틱 2연타(0/70ms).
- **`SoundService.correct()` 배선 추가** — 기존 7개 퀘스트 엔진은 전부 무음이었다.
- `reduceMotion` 게이트 추가 (기존 `MascotPop`엔 아예 없었음).

## 5. 퀘스트 엔진 7종

`lib/screens/quest_engines/` 아래:
`satz_bauen` · `hoerverstehen` · `uebersetzen` · `luecken` · `particle_pop` ·
`batchim_drop` · `diktat` `_quest.dart`

- `MascotPop(visible:)` → `MascotPartner(celebrating:)`
- 앵커 `Positioned(top: 0, right: 0)` → `top: -12, right: 12`
  → 맨 구석이 아니라 **프롬프트 카드 테두리에 걸터앉은** 모양
- **`hoerverstehen_quest.dart`만 다르게**: 코너 배치를 없애고 까치를
  **스피커 버튼과 한 `Row`로 묶음** (`[🔊] 🐦` / 아래 "Tap to play")
- `hoerverstehen`·`luecken`·`uebersetzen`: 중괄호 없는 `if` 6건 수정
  (CLAUDE.md "if/else 반드시 중괄호" 규칙, 동작 변화 없음)

## 6. `lib/screens/scenario_player_screen.dart`

Rollenspiel 완료 카드에 **캐릭터별 축하 영상** 도입.

- **캐릭터 선택 반영**: `Storage.preferredMascot == 'magpie'` → 까치,
  그 외/미설정(`''`) → 호랑이. `CharacterClips.feedbackFor(kind, celebrate)`로 클립 선택.
  (이 값을 읽는 곳은 그동안 `milestone_celebration.dart` 한 곳뿐이었다.)
- **신규 `_RollenspielDoneCard`**: 영상이 히어로, 텍스트는 그 아래 2단(제목+본문).
  기존은 `Row(마스코트 48px + 텍스트)`라 영상을 넣기엔 너무 작았다.
- **흰 배경 처리**: 영상을 `s.surface` 색 "한지 창(well)"에 넣고 **같은 변수를
  `blendColor`로** 전달 → multiply가 `out = dst`로 딱 떨어져 잔상 0.
- **`_StageScroll`에 opt-in `fill` 추가**: 완료 패널이 스테이지를 세로로 채우고
  중앙 정렬. `minHeight`만 주므로 오버플로 구조적 불가. 기본 `false`라
  나머지 6개 스테이지는 트리 그대로 → 회귀 0.
- **헤더를 스테이지 안으로 이동**: 완료되면 "Jetzt bist du dran"이 함께 사라진다.
- 마지막 턴 완료 시 `SoriCelebration.burst` 1회 (턴 없는 시나리오는 발화 안 함).
- import 추가: `character_clip.dart`, `motion.dart`(SoriEntrance).

## 7. l10n

`lib/l10n/app_de.arb` · `app_en.arb` + `lib/l10n/generated/*`

- `scenarioRoleplayDone` → `scenarioRoleplayDoneTitle` + `scenarioRoleplayDoneBody`
  기존 원어민 검수 문장을 마침표에서 그대로 자른 것 → **신규 번역 0**
- DE/EN 각 **1015키 parity 확인**
- ⚠️ `flutter gen-l10n` 실행 중 **`bookResultRateLimited`도 함께 생성**됐다.
  ARB엔 있었는데 커밋된 생성 파일엔 빠져 있던 키다(HEAD의 생성 l10n이 stale이었음).

## 8. `lib/main.dart`

- `DancheongBurst.preload()` 1줄 + import — 첫 정답에서 폴백이 뜨는 걸 막는다.
  실패해도 조용히 넘어감, `runApp` 무지연.

---

## 빌드 절차 (VS Code 터미널)

l10n 키가 바뀌었으므로 `gen-l10n`을 반드시 먼저 돌릴 것.

```bash
flutter pub get
```

```bash
flutter gen-l10n
```

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

산출물: `build/app/outputs/bundle/release/app-release.aab`
심볼: `build/app/outputs/symbols/` → Play Console "Native debug symbols"에 별도 업로드

> **버전 주의**: `2.0.1+5`. `+5`를 이미 Play Console에 올렸다면 `pubspec.yaml`의
> `version:` 뒤 빌드번호를 `+6`으로 올려야 업로드가 거부된다.

> **⚠️ 음성(TTS) 관문 — 빌드 후 음성이 이상하면 앱 버그가 아니다.** 이번 리팩터가
> Storage 경로를 `tts/{voice}/…` → `tts/v2/{voice}/…`로 바꿨다(revision 캐시버스트,
> `tts_service.dart:31,53`). 기존 사전생성 1245개는 옛 경로 `tts/`에 있으므로,
> `gs://ko-lernen-app.firebasestorage.app/tts/v2/`가 비어 있으면 단어·예문·시나리오
> 음성이 전부 Cloud Function(1.0) 또는 오프라인 시 flutter_tts 기계음 폴백으로 나온다
> (사전생성 고품질 캐시가 우회됨). **확인**: `gsutil ls
> gs://ko-lernen-app.firebasestorage.app/tts/v2/ | head` — 비었으면 `python3
> tool/generate_tts.py`(rate 1.0으로 재합성 + v2 업로드) 실행 후 재테스트.
> sha1 키(`{voice}|{text}`)엔 rate가 없어 재실행해도 경로만 새 v2라 정상 재생성된다.

빠르게 실기기만 확인하려면:

```bash
flutter run -d 9053622f
```

---

## 현재 검증 상태 (커밋 `971b582` 실측 — GREEN)

| 항목 | 결과 |
|---|---|
| `flutter analyze lib test` | **0 issues** (미사용 import 제거됨) |
| `flutter test` | **1227 통과 / 0 실패** |
| 생성 l10n ↔ ARB | **동기** (`bookResultRateLimited`·`scenarioRoleplayDoneTitle/Body` drift 0) |

> 이전 초안의 "1 warning / 3 실패"는 **여러 세션이 섞인 미커밋 작업트리** 시점 값이었다.
> 커밋된 `971b582`는 clean checkout에서 재검증 결과 위와 같이 **GREEN**이다
> (`account_hardening`·`crop_recovery`·`book_analysis_language` 3건은 커밋 시 해소됨).
> 이 세션 변경은 이미 **origin/main(`e20b524`)에 전부 흡수**됨 — 로컬 빌드는 동일 코드의
> 실기기 테스트용이다.

---

## 실기기에서 볼 것

1. **까치를 먼저** — 까치가 흰 픽셀 66.2%(호랑이 56.6%)라 multiply로 흰 깃털이
   well 색에 녹을 위험이 가장 크다. 문제 시 `_RollenspielDoneCard`의
   `tinted: true` 한 줄 제거.
2. **영상 마지막 프레임 포즈** — `loop: false`라 4.04초 뒤 96번 프레임에서 멈춘다.
   하이파이브 중간에 멈추면 어색할 수 있다. 처방은 `loop: true` 한 줄이지만
   `PageView`가 페이지를 살려둬 960² 디코더가 계속 도는 대가가 있다.
3. **정답 시 "파박"** — 복주머니가 먼저, 엽전이 70ms 뒤 더 멀리. 햅틱 2연타 체감.
4. **Hörverstehen** 스피커+까치가 한 덩어리로 보이는지 (좁은 폰 308px 포함).
5. **캐릭터 불일치** — 이 카드는 사용자가 고른 캐릭터, 두 화면 뒤 결과 화면은
   `sc.sidekick`(시나리오 지정)을 쓴다. 까치 사용자가 호랑이 시나리오를 하면
   중간에 동물이 바뀐다. 의도적으로 정할 문제.
6. **애니메이션 줄이기 ON** → 영상 대신 정지 마스코트. 단 그 마스코트가 계속
   숨쉰다(기존 결함 — `Mascot._startMotion()`에 `reduceMotion` 가드 없음,
   기존 8곳 전부 해당. 3줄이면 고치지만 모든 마스코트 화면이 바뀌므로 별도 커밋 권장).
