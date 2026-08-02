# Deploy Checklist: 한글소리 에셋 배치 (신규 영상·이미지 트리거 검수)
**날짜:** 2026-07-30 | **검수:** Claude | **범위:** 배치 계획 2026-07-29 전체

---

## 0. 오늘 새로 한 것 (요약)

- ⚠️ **결함 발견 → 전량 재생성**: character 알파 webm 16종을 전 프레임 스캔한 결과,
  다수 프레임에 **마젠타 잔광(halo)** 이 남아 있었음 (크로마키가 배경의 밝기 변화를
  못 걸러냄 — 특히 `magpie_greet_chirp` 최악 프레임은 화면의 19%가 마젠타).
  → 디스필(despill) + 잔광 제거 파이프라인으로 **16종 전부 흰배경 mp4로 재생성**,
  전 프레임 재검증 **잔여 마젠타 0px** 확인 후 `assets/video/character/`에 배치 완료.
  **예전에 보낸 part10 zip은 같은 결함이 있으니 사용하지 마세요 — 오늘 레포에 들어간 것이 최종본입니다.**
- 코드 5파일 추가 배선(아래 §2) 커밋 완료.

## 1. Pre-Deploy — 사용자 액션 (순서대로)

- [ ] **① webm 16개 삭제**: `assets\video\character\*.webm` 전부 삭제
      (pubspec이 폴더째 번들하므로 안 지우면 APK +38MB. mp4만 남기면 됨.
      로컬 VM이 안 떠서 제가 대신 못 지웠어요.)
- [ ] **② 빌드 검증**: `flutter pub get` → `flutter analyze` → 에러 있으면 저에게 붙여넣기
- [ ] **③ 실행 스모크 테스트**: 첫 실행 온보딩(캐릭터 선택 인사), 홈 호랑이, 시나리오 목록 헤더, 듣기 완료, 게임 1판 종료 카드
- [ ] **④ git 커밋·머지·푸시** (VM 다운으로 제가 실행 불가 — 아래 붙여넣기):

```powershell
cd C:\Users\vjinn\ELibrary\Downloads\DataSet\hangulsori\ko_lernen_app
git status                # 변경 확인 (webm 삭제를 ①에서 먼저!)
git branch --show-current # 현재 브랜치 확인
git add -A
git commit -m "feat: 캐논 캐릭터 클립 16종 배선 + 마젠타 잔광 수정본 교체 (홈 히어로·첫인사·게임피드백·듣기완료·종가루프)"
# main이 아니면:
git checkout main && git merge -           # 직전 브랜치를 main에 머지
git push
```

## 2. 트리거 검수 결과 — 지금 라이브 ✓ (앱 실행 시 실제 재생)

| 에셋 | 트리거 위치 |
|---|---|
| `intro_gate_to_madang.mp4` | 인트로 — 대문이 열리며 마당 진입 (`intro_gate_screen`, 탭 스킵/실패 시 기존 코드 씬 폴백) |
| `character/tiger_rise.mp4` | **홈 히어로 인사**(launch당 1회) + **퀵 온보딩 첫 만남** (`tiger_video.dart` 상수 교체 — 캐논 엎드림→기상) |
| `character/tiger_rest.mp4` | 홈 히어로 아이들 루프 (인사 후 150ms 크로스페이드) |
| `character/tiger_greet_pawflash.mp4` | 캐릭터 선택 → 호랑이 첫 인사 (앞발 번쩍, 무언, 끝나면 자동 진행) |
| `character/magpie_greet_chirp.mp4` | 캐릭터 선택 → 까치 첫 인사 (짹짹 몸짓) |
| `character/tiger_celebrate_hifive.mp4` | 게임 종료 카드(GameOverCard) 기본 축하 |
| `character/tiger_roar_seated_bonus.mp4` | 게임 종료 카드 — **신기록(isNewBest)** 일 때 포효로 승격 |
| `character/magpie_celebrate.mp4` | **듣기 완료 카드** + GameOverCard에 까치 지정 시 |
| `loops/listening_hero.mp4` | 듣기 화면 헤더 (HanokHeader 자동 유도) |
| `loops/kkeunmari_hero.mp4` | 끝말잇기 헤더 |
| `loops/porch.mp4` | 스몰토크·문법 헤더 (2곳) — 포스터·루프 모두 Jin 배치본 |
| `loops/study_scholar.mp4` | 학습 허브·복습 헤더 (2곳) |
| `loops/study_classroom.mp4` | 단어장 허브·어휘·단어팩 헤더 (3곳) |
| `loops/hanok_jongga.mp4` | **시나리오 목록 헤더** — 마당 포스터 위 종가 루프 (오늘 배선) |

모든 영상은 `videoReady && !reduce-motion` 게이트 + 로드 실패 시 기존 PNG/Rive/마스코트로
자동 폴백 → **회귀 리스크 없음** (영상이 없어도 앱은 기존 모습 그대로).

## 3. API 배선 완료 — 호출부가 넘기면 즉시 재생

| 에셋 | 상태 |
|---|---|
| `magpie_worry.mp4` | `feedbackFor` 매핑 완료 — 게임이 `mascotEmotion: worry` + 까치를 넘기면 재생 |
| `tiger_thinking.mp4` | `feedbackFor` 매핑 완료 — `thinking` 전달 시 재생 |
| `tiger_choose` / `magpie_choose.mp4` | `CharacterClips.chooseFor()` 준비 — 현재 선택 화면은 인사 클립이 우선이라 미사용 |

> 참고: 현재 게임들은 GameOverCard에 mascotKind를 안 넘겨서 **항상 호랑이**가 나옵니다.
> 선택 캐릭터를 반영하려면 각 게임에서 `mascotKind: Storage.preferredMascot…` 한 줄이면 됩니다 (원하면 다음에 배선해 드림).

## 4. 미배선 (파일만 존재 — 의도적 보류)

| 에셋 | 사유 / 권장 배치 |
|---|---|
| `loops/scene_*.mp4` ×5 (cafe·market·hotel·restaurant·directions) | 시나리오 플레이어 배경은 **투명도 8%** 라 영상 효과가 안 보이는데 디코더만 계속 돌아 배터리 낭비 → 보류. 권장: 시나리오 **인트로 스테이지**에 1회 재생 |
| `loops/welcome_hero.mp4` | 대응하는 화면/포스터가 코드에 없음. 권장: 온보딩 프리뷰 상단 배너 |
| `loops/hanok_construction.mp4` | 학습 경로 헤더는 "현재 단계별 한옥"이라 완공 영상과 충돌 → 보류. 권장: 한옥 **단계 상승 축하** 오버레이 |
| `character/magpie_flight.mp4` | 인트로는 이미 대문 영상이 대체. 권장: 코드 씬 폴백의 까치 위젯 업그레이드 |
| `character/magpie_perched.mp4` | 듣기 화면 재생 중 대기 슬롯이 현재 없음 (완료 카드는 celebrate 사용) |
| `character/tiger_bob.mp4` | 게임 대기 화면 슬롯 미정 |
| `character/tiger_stretch.mp4` | 세션 완료 화면(복습/단어팩 결과) 배선 후보 |
| `character/tiger_roar.mp4` | 레벨업 연출 지점 확정 필요 (`levelup.wav` 재생 위치와 함께 배선 권장) |

## 5. 이미지 (Jin 배치본 — 코드 트리거 확인만)

- `hanok/porch.png`·`kkeunmari_hero.png`·`listening_hero.png`: 기존 HanokHeader 콜사이트가 그대로 로드 ✓ (파일 교체라 코드 변경 불필요)

## 6. 오디오 훅 (선택)

- 선택 인사 SFX 훅: `assets/sfx/greet_tiger.mp3` / `greet_magpie.mp3` — **파일이 아직 없음** → 현재는 조용히 무음(정상). 동물 소리 mp3를 그 이름으로 넣으면 자동 재생.
  (기존 `tiger_greet.mp3`는 사람 목소리 인사라 첫인사 무보이스 원칙에 따라 연결 안 함.)

## 7. Rollback

- 홈 호랑이: `tiger_video.dart` 상수 2줄을 `assets/video/tiger_greet.mp4`/`tiger_pace.mp4`로 되돌리면 즉시 구버전 (구 파일 레포에 유지됨)
- 그 외 전부: 영상 파일 제거만으로 자동 폴백 (코드 롤백 불필요)

## 8. 변경 파일 (이번 커밋 대상)

- 코드: `character_clip.dart`(+feedbackFor), `game_reward.dart`(클립 배선), `tiger_video.dart`(캐논 상수), `scenarios_list_screen.dart`(종가 루프), `listening_screen.dart`(완료 축하) — 어제 커밋분(선택 화면·인트로·헤더·pubspec 등 6파일) 포함
- 에셋: `assets/video/character/*.mp4` 16종 신규(마젠타 수정본), webm 16종 삭제 예정(①)
