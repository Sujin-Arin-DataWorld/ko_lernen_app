# 다음 세션에서 할 것 — 2026-07-31 홈 개편 세션 인계

이 세션은 **컨테이너에서 flutter.dev / pub.dev 가 403** 이라 `flutter analyze` / `flutter test` 를
한 번도 실행하지 못했습니다. 아래 순서로 돌려 주세요.

## 1. 컴파일·테스트 (필수, 최우선)

```bash
cd C:\Users\vjinn\ELibrary\Downloads\DataSet\hangulsori\ko_lernen_app
flutter pub get
flutter analyze
flutter test
```

특히 이번 세션이 손댄 테스트:

```bash
flutter test test/mascot_wiring_test.dart      # 신규 — 캐릭터 배선 가드
flutter test test/data_integrity_test.dart     # 보간 자산 경로 해석 추가
flutter test test/no_emoji_glyph_test.dart     # 래칫 4 → 2
flutter test test/typography_guard_test.dart   # ⚠️ 아래 3번 참조
```

## 2. 되돌리기

수정 전 원본 전량이 있습니다 (경로의 `/` 를 `__` 로 치환한 파일명):

```
docs/_backup_2026-07-31/
```

에셋 원본(다운스케일 전 32장, 37MB):

```
assets_unused/_orig_2026-07-31/      # pubspec 에 없음 → 번들 안 됨
```

한 파일만 되돌리기:

```bash
copy docs\_backup_2026-07-31\lib__widgets__sori__tiger_video.dart lib\widgets\sori\tiger_video.dart
```

## 3. ⚠️ `typography_guard_test` 가 이미 깨져 있습니다 (이 세션 원인 아님)

`FontWeight.w800` 이 래칫 상한 189 를 넘어 **193** 입니다.
20:51 에 병렬 세션이 `onboarding_level_screen.dart` 와 `hanok_tokens.dart` 에서 +4 했습니다.
이 세션이 만든 코드는 전부 w700 이하이고 델타는 0 입니다 (백업 대비 파일별 검증 완료).

→ 그쪽 두 파일에서 w700 이하로 낮추거나, 래칫을 193 으로 올리세요.

## 4. 실기기 확인 (에뮬레이터로는 못 잡음)

### 4-1. 캐릭터 배선
1. 설정 → **새로 생긴 캐릭터 항목**에서 까치 선택
2. 홈 → 히어로 밴드가 까치 영상(`magpie_greet_chirp` → `magpie_perched`)인지
3. 말풍선 테두리가 남색(`highlight`)인지, 문구가 까치 어조인지
4. 게임 하나 완료 → 결과 카드 마스코트가 까치인지
5. 복습 세션 완료 → `magpie_celebrate` 클립인지
6. **승패 연출은 그대로여야 함**: 정답률 50% 미만이면 호랑이(위로), 이상이면 까치(축하)

### 4-2. MediaCodec 디코더 회수 (M2101K6G / SD678 / MIUI)

```bash
adb logcat | findstr /i "reclaim ExoPlayerImpl"
```

- 홈 → Lernpfad 진입 → 경로의 캐릭터가 1초 뒤 사라지지 **않는지**
- 뒤로 → 홈 밴드가 되살아나는지

이번에 홈이 상시 물던 디코더를 2개 → 1개로 줄이고, 다른 화면이 올라오면 0개로 반납하게 했습니다.
그래도 문제가 남으면 `path_trail.dart` 의 `_NowDisc` 클립을 정적 `Mascot` 으로 내리는 게 다음 카드입니다.

### 4-3. 대비 (실기기 밝기에서)
- 홈 주 CTA: 주황 채움 + **먹색** 글씨 + 어두운 주황 테두리 — 흰 글씨면 반영 안 된 것
- 카드가 배경에서 떠 보이는지 (바탕 `#FFFDF8` + 테두리 1.5px)
- 신규 계정으로 첫 진입 시 **"Willkommen zurück!" 이 안 뜨는지**
- 첫날 화면에 0% 진행바 대신 **디딤돌 7칸**이 뜨는지

## 5. 결정이 필요한 것

| # | 항목 | 상태 |
|---|---|---|
| 1 | 까치 인사 SFX (`sfx/magpie_greet.mp3`) | 없음 → 현재 까치는 무음. 만들면 `tiger_video.dart` 의 가드 해제 |
| 2 | `assets_unused/_orig_2026-07-31/` 37MB | 실기기 확인 후 삭제 (브리지에서 `rm` 이 막혀 이동만 해 둠) |
| 3 | 마당 아이콘 6종 | IA 확정 전 발주 금지. Aussprache(마이크)·Kultur 는 앱에 기능이 없음 |
| 4 | 한옥 마당 가로 정경 1024×768 | 기존 `hanok_stages/` 는 841×1870 세로 — 용도가 다르면 별도 제작 |
| 5 | `stickers/` ↔ `mascot/` 동명 6쌍 | 내용이 다른 별개 에셋. 통합할지 유지할지 |

## 6. 커밋

이 세션은 **git 을 건드리지 않았습니다** (작업 트리에 573개가 이미 M 상태였음).

```bash
git switch -c feat/character-wiring-and-contrast
git add -A
git commit -m "feat(mascot): 선택 캐릭터를 홈·게임·완료 화면에 실제로 반영

- MascotPreference(ValueNotifier) 단일 진입점 신설 — 읽기 3곳 → 전역
- 설정에 캐릭터 변경 추가 (이전에는 진입점 0개)
- TigerStageVideo 캐릭터 대응 + 디코더 2개 → 1개 + RouteAware 반납
- SoriColors.onFill/fillOutline — 대비 규칙을 코드로 강제
- 카드 바탕/테두리 대비 1.09 → 3.27, 다크 1.43 → 4.01
- 첫날 0% 게이지 → 디딤돌 7칸 (기준: 가입일이 아니라 스트릭)
- assets 159MB → 138MB (1254px 다운스케일 32장)"
```

---

전체 내역은 `AGENTS.md` 세션 로그 최상단, 조사·판정 근거는 `docs/HOME_REDESIGN_PLAN_2026-07-31.md`.
