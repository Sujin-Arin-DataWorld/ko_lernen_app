# 오디오·영상·릴리스 전수 검수 — 다음 세션 인수인계 SSoT (2026-08-02)

> **대상 독자: 사운드 후속 작업(마스터 토글·AudioPolicy·게인테이블·growl 배선)을 실행할 다음 fable5 ultracode 세션.**
> 기준 커밋: `bf33ddb` == origin/main. 검수 방법: ultracode 워크플로우 `wf_a4c2effe-6d6` — 읽기 전용 감사 에이전트 4(sound/video/tts/release) + 각 감사에 대한 독립 적대적 검증 에이전트 4. 주장 56건 중 55 CONFIRMED, 1 REFUTED(정정 반영, §7-4). 모든 수치는 grep/git/unzip 실측이며 추정치 없음.
> ⚠️ 이 문서보다 낡은 문서들(`docs/AUDIO_HANDOFF_2026-07-31.md`, ADR-002 §1-5 일부, AGENTS.md 구 세션로그의 "26곳" 등)과 상충하면 **이 문서가 우선**. 정정 목록은 §7.

---

## §0. 한눈 요약

| 질문 | 판정 |
|---|---|
| 핑크(마젠타) 화면 배경 정리됐나? | ✅ **완료** — 매트 검사 16/16 ok, tiger_sitting2 순백 재출력, magpie_moon 번들 완전 제거 (§3) |
| 오디오 v3 전부 적용됐나? | ✅ **TTS v3 코드 4자 일치 + 캐릭터 SFX mp3 4종 v3(모델 생성)** — 갭 2건(§4-3)만 남음. **서버 업로드도 완결 실측**: female 1,211 + male 103 = 1,314/1,314 (Jin gsutil, §4-4) |
| AAB 재빌드 필요한가? | ❌ **불필요** — 마지막 빌드 이후 델타가 문서뿐, growl_tiger.mp3도 이미 기존 AAB에 포함(§5-3). 기존 AAB(246,845,826B, SHA `BB20DC29…6A8D019`) 유효 |
| AAB 업로드 전 남은 것? | 코드측 신규 차단 항목 **0** (게이트 실측 §5-4: analyze 0 · test 1,293 통과) — 남은 건 전부 Jin/기기·콘솔측(§5-2) |
| 사운드 끌 수 있나? | ❌ **불가능** — `SoundService.enabled` 대입 0곳, 인트로가 0.8로 소리 내는데 끌 방법 없음. **다음 세션 1순위**(§6-ⓐ) |

---

## §1. 배선된 영상 전체 리스트 (번들 mp4 30개 — 고아 0 · 깨진 참조 0)

pubspec 등록: `pubspec.yaml:127-129` (`assets/video/` · `loops/` · `character/`). `assets_unused/`·`masters/`는 미등록 = 비번들.

| 에셋 | 사용처 (파일:라인) | 내장 오디오 | 재생 볼륨 |
|---|---|---|---|
| `intro_gate_to_madang.mp4` | intro_gate_screen:24, 381-387 | ✅ | **0.8** — `setVolume(SoundService.enabled ? 0.8 : 0)` (:384). **앱에서 유일하게 소리 켜진 영상** |
| character 16종 (아래) | `character_clip.dart:25-54` `CharacterClips` 카탈로그 → 소비처 9파일 + 홈 히어로(tiger_video.dart:72-83 — tiger_rise/rest·magpie_greet_chirp/perched) + quick_onboarding:161(TigerGreetClip) | 14종 ❌ / `tiger_greet_pawflash`·`magpie_perched` ✅(재출력본) | **전부 0** (character_clip:218, tiger_video:173·421) — 소리는 별도 SFX mp3 0.7이 담당 |
| `loops/porch` | practice_hub:45(명시) · wordle:407(png 이름 유도) | ✅ | 0 |
| `loops/hanok_jongga` | scenarios_list:161 | ✅ | 0 |
| `loops/hanok_construction` | onboarding_preview:108 | ✅ | 0 |
| `loops/welcome-hero` | onboarding_level:73 · character_selection:124(**animate:false** — 디코더 충돌 회피 의도) | ✅ | 0 |
| `loops/kkeunmari_hero` · `listening_hero` | kkeunmari:322 · listening:218 (png 유도) | ✅ | 0 |
| `loops/study_scholar` | grammar:223 · learn_hub:53 · settings:482 | ✅ | 0 |
| `loops/study_classroom` | legacy_vocab:356 · vocab_packs:186 · wordbook_hub:55 | ✅ | 0 |
| `loops/scene_*` 5종 (cafe/directions/hotel/market/restaurant) | scenario_player:1303 ← scene_asset_resolver:66-76 | ❌ (오디오 트랙 없음) | 0 |

- character 16종: tiger — bob·celebrate_hifive·choose·greet_pawflash·rest·rise·roar·sitting2·stretch·thinking / magpie — celebrate·choose·flight·greet_chirp·perched·worry. 별칭 1: `tigerRoarSeatedBonus = tigerRoar`(character_clip:45, 깨진 참조 해소 이력 주석 :40-44).
- 프로필 랜덤 풀: 호랑이 5(stretch/sitting2/rest/bob/choose) · 까치 3(perched/choose/flight) — character_clip:58-69.
- CharacterClipPlayer 소비처 11곳: character_selection ×3 · game_reward:187 · kkeunmari:419 · listening:595 · profile:314 · milestone_celebration:44 · review_session:211 · scenario_player:1653 · path_trail:431.
- `HanokHeader` 실호출 **17곳** + `SoriPosterLoop` 실호출 **4곳**(hanok_header:122 내부 + onboarding_level:441 + onboarding_preview:273 + scenario_player:1303). ⚠️ 구 감사의 "26곳=21+5"는 grep 라인 수 오류 — 주석·생성자 선언·`learning_path_screen.dart`의 **별개 private `_HanokHeader`** 오탐 포함 (§7-1).
- **`volume`을 넘기는 호출부 0곳.** `SoriPosterLoop.volume` 기본 0(hanok_header:151), 적용식 `setVolume(SoundService.enabled ? widget.volume : 0)`(:172). **HanokHeader 위젯에는 volume 파라미터 자체가 없음**(필드 :28-56) → 앰비언스 켜려면 HanokHeader에 파라미터 신설 필요(§6-ⓑ).
- 오디오 트랙 유무는 ADR-002 §1-4 ffmpeg 실측 기록 인용(본 검수에서 ffmpeg 재실행 안 함). 루프 8종에 트랙 있음, 평균 편차 29dB(−19.6 hanok_construction ~ −48.6 porch) → 플랫 볼륨 불가, 게인테이블 필수.

**디코더 구조(중요 불변식):** 살아있는 `VideoPlayerController`는 `soriVideoLease` 전역 싱글턴이 **동시 1개**로 강제(video_lease.dart:16-24, 486-491 — eligible 최신 요청만 승자, dispose-await-then-create 직렬 핸드오프, generation 가드). `VideoPlayerController.asset` 직접 생성은 **video_lease.dart:476 단 한 곳**이고 `test/sori_video_lease_test.dart:732` 가드 테스트가 lib 소스를 스캔해 위반을 잡음. **새 영상 코드는 반드시 lease 경유** — 직접 생성하면 테스트가 막는다.

## §2. 배선된 음성·SFX 전체 리스트

### 실제로 소리 나는 채널 — 4개뿐

| # | 채널 | 파일 | 볼륨 | 게이트 | 근거 |
|---|---|---|---|---|---|
| 1 | 게임 피드백 SFX | `sfx/correct.wav`·`wrong.wav`(0.55) · `combo.wav`(0.6) · `complete.wav`(0.65) | 0.55~0.65 | `enabled && !kIsWeb` (웹 무음) | sound_service.dart:19-42 |
| 2 | 캐릭터 원샷 SFX | `sfx/greet_tiger·greet_magpie·celebrate_tiger·celebrate_magpie.mp3` | **0.7 하드코딩** | `SoundService.enabled` — reduce-motion·영상 폴백 경로에서도 재생(character_clip:232-237) | character_clip.dart:261, 270 |
| 3 | 대문 인트로 내장 오디오 | `intro_gate_to_madang.mp4` | **0.8 하드코딩** | `SoundService.enabled` — 단 영상 미재생(리스 실패·reduce-motion) 시 오디오도 소실 | intro_gate_screen.dart:384 |
| 4 | TTS | 캐시 mp3 / flutter_tts 폴백 | **1.0** (미지정) | 게이트 없음(사용자 명시 탭) | tts_service.dart:447, 560 |

- SoundService 호출부 실측: `correct()` 9곳 · `wrong()` 9곳 · `combo()` 3곳 · `complete()` 1곳(game_reward:69 공용 헬퍼) — 합 22곳.
- 캐릭터 SFX 매핑 `CharacterClips.sfxFor()`(character_clip:131-148): greet_pawflash·rise→greet_tiger / greet_chirp→greet_magpie / hifive·roar·stretch→celebrate_tiger / celebrate·flight→celebrate_magpie / 루프 계열→null(무SFX).

### 죽은 경로 · 미배선 · 미호출

| 항목 | 상태 | 근거 |
|---|---|---|
| `sfx/tiger_greet.mp3` (구본 46KB) | **런타임 죽은 경로** — 재생 코드는 tiger_video:509-515에 있으나 유일 호출부 quick_onboarding:161-164가 `playAudio: false`(주석 "음성 제거 — Jin 요청 2026-07-31"), 기본값도 false. 번들 용량만 차지 | 검증 에이전트가 독립 확정(§7-4) |
| `sfx/growl_tiger.mp3` (26KB) | **참조 0곳 — 그러나 이미 tracked(bf33ddb)·번들 포함.** Jin 의도: "사운드 설정에서 유저가 세밀하게 조정하게 하려고 만든 것" → §6-ⓒ에서 배선 | grep growl → lib/test 0매치 |
| `SoundService.levelUp()` | 정의만(sound_service:41), **호출 0곳** | grep 0매치 |
| `SoriPosterLoop.volume` | 파라미터만 존재, 전달 0곳 → 루프 내장 오디오 전부 무음(의도된 기본 — hanok_header:141-144) | §1 |
| `SoundService.enabled` | 읽기 4곳(sound_service:20·character_clip:261·intro_gate:384·hanok_header:172), **대입 0곳 → 사실상 상수 true** | grep `SoundService.enabled *=` → 0 |

### 사운드 제어 구조 — 전부 부재 (다음 세션이 만들 것)

```
SoundService.enabled 대입        0곳   ← 끄는 방법 없음
Storage 사운드 키                0개   (storage_service.dart에 sound/audio/mute/volume 키 0건)
lib/services/audio_policy.dart   없음  (설계는 docs/ADR-002-audio-policy.md에 완성돼 있음)
SoundChannel                     없음
settings_screen 사운드 섹션      0건   (grep 매치 4건은 전부 SoriColors.*TextMuted 색 토큰명)
게인 정규화 테이블               없음  (볼륨 리터럴 산재: 0.55/0.6/0.65/0.7/0.8/0/1.0 — 6개 파일)
TTS 더킹                         없음  (tts_service에 lease/VideoPlayer 참조 0)
```

### v3 SFX 에셋 검증

- 캐릭터 mp3 4종(greet/celebrate × tiger/magpie): **각각 git 이력이 단일 커밋 `eda4c37`(2026-08-01)** — "소 같다"던 DSP 합성 구본은 히스토리에 아예 없음(커밋 전 폐기). `assets/sfx/README.md:30-39`가 출처(모델 생성 오디오 잘라냄)·loudnorm I=-16/TP=-1.5 기록. **현재 tracked 본 = v3 확정.**
- wav 5종(correct/wrong/combo/levelup/complete): `ad1ceff`(2026-06-03) 자작 합성 — **의도적 유지**(README:18-24, 저작권 제약 0).
- 실제 파형·청감은 코드로 검증 불가 — Jin 실기기 청취.

## §3. 핑크(마젠타) 매트 판정 — ✅ 완료

| 검증 항목 | 결과 |
|---|---|
| 매트 검사 리포트 | **16/16 ok** — `tool/clip_matte_report.json`, `tiger_sitting2.mp4` = `#FFFFFF`·white_ratio 1.0·121프레임(:123-129). 검사기 `tool/check_clip_matte.py`: 전 프레임 64×64 → 네 모서리 픽셀 WHITE_MIN=248, 흰 비율 ≥0.75 다수결 + 자홍 판정 휴리스틱 |
| 테스트 래칫 | `test/character_clip_matte_test.dart:38-64` — 디스크 16개 ↔ 리포트 16개 일치 + 전 클립 ok 강제. `kLoopAssets` 13종 ↔ 디스크 양방향 일치도 강제(:88-89) |
| 자홍 원본 | `assets_unused/clip_matte_backup_2026-08-01/tiger_sitting2.magenta.original.mp4` 백업(비번들·현재 gitignored) |
| `magpie_moon.mp4` | 번들 완전 제거 — character/ 폴더 부재·pubspec 참조 0·lib 참조 0. git 추적본은 비번들 `assets_unused/video/magpie_moon.dark.mp4`뿐 |
| lib 내 pink/magenta 하드코딩 | 3건 전부 무해(ambient_particles:137-138 매화 꽃잎색, tokens:119 주석) |
| masters/ | `.gitignore:103` + git 미추적 + pubspec 미등록 ✅ |

한계: 매트 검사는 `assets/video/character/` 전용(설계 의도 — loops는 multiply 블렌드 안 함). **클립 파일을 교체하면 `python tool/check_clip_matte.py` 재실행 필수**(리포트 stale이면 테스트가 잡음).

## §4. TTS v3 일관성 — ✅ 코드 4자 일치

### §4-1. 클라 ↔ CF ↔ 생성기 ↔ 테스트 대조표

| 계약 | 클라 tts_service.dart | CF functions/tts/ | 생성기 tool/generate_tts.py | 테스트 |
|---|---|---|---|---|
| 리비전 | `currentRevision='v3'` (:31) | `TTS_CACHE_REVISION="v3"` (tts_contract.js:3) | 동일 (:37) | Dart·JS·Py 3중 리터럴 고정 |
| voice 정규화 | male 외 전부 female (:37) | 동일 | 동일 (:94-95) | unknown→female 고정 |
| sha1 입력 | `'$voice\|$text'` (:39-41) | 동일 | 동일 (:101) | **동일 벡터 `d84734f7…` 3개 언어 테스트 공유 + 검수 중 sha1sum 독립 재계산 일치** |
| Storage 경로 | `tts/v3/{voice}/{hash}.mp3` (:53) | 동일 (tts_contract.js:20) | 동일 + rsync도 v3 경로 (:225-232) | 고정 |
| 로컬 캐시 파일명 | `tts_v3_{voice}_{hash}.mp3` (:54) — 기기 캐시도 리비전 무효화 | — | — | 고정 |
| Google 음성 | 클라는 'female'/'male'만 전송 | **Zephyr / Enceladus** (index.js:42-45) | 동일 (:41) | — |
| 보안 | callable + `limitedUseAppCheckToken` (:318-319) | `enforceAppCheck`+`consumeAppCheckToken` (tts_request_guard.js:3-9) | — | guard test 4건 |

CF는 계약을 `tts_contract.js` 단일 모듈로 공유(index.js:24 require) — 내부 분열 여지 없음. 폴백 체인: 로컬 캐시 → Storage → CF 합성(합성 전 Storage 재확인으로 중복 방지) → flutter_tts.

### §4-2. 잔재 = 코드 0건

`Aoede`/`Neural2` 히트는 문서뿐(AGENTS.md 세션로그=역사, docs/SESSION_* = 과거 기록 명시). AGENTS.md:90 파일맵의 stale 표기는 **본 검수에서 정정 완료**. v2 리비전 잔재도 추적 코드 0건(히트는 node_modules·pycache 등 미추적물과 무관 항목뿐).

### §4-3. 갭 2건 (다음 세션 처리)

1. 🟡 **listening_screen.dart:136 voice 미지정** — 시나리오 대사(`line.ko`)를 기본 female로 재생. 사전생성은 NPC/narrator 대사를 **male**로 만들었으므로(generate_tts.py:130-133, scenario_player:600-602와 동일 규칙) 듣기 화면 NPC 대사는 v3 캐시 미스 → CF가 female로 재합성(Storage 중복 적재) + scenario_player와 화자 불일치. **수정 = scenario_player:600-602의 화자→voice 규칙을 listening에 이식** (§6-ⓓ).
2. ⚪ intro_gate_screen.dart:21 문서 주석 "무음" ↔ 실제 0.8 재생 — 코드가 맞고 주석이 낡음. AudioPolicy 작업 때 같이 정리.

### §4-4. 코드로 검증 불가 — Jin/배포측 확인 명령

> **2026-08-02 갱신: Storage 업로드는 닫힘.** Jin이 gsutil로 실측 — **female 1,211 + male 103 = 1,314/1,314 전부 업로드됨**(기대값은 `generate_tts.py collect()` 재현으로 교차 확인, 병렬 세션 HANDOFF §0-A). 사전생성 TTS 커버리지 100%, CF 폴백은 설계대로 동적 콘텐츠(사용자 입력·책 OCR)에만. 아래 표의 나머지 항목은 여전히 미확인.

| 항목 | 확인 방법 |
|---|---|
| CF `synthesize_tts` 배포본이 v3인지 | `gcloud functions describe synthesize_tts --region=europe-west3 --project=ko-lernen-app --gen2 --format="value(updateTime,serviceConfig.revision)"` — updateTime이 fc1d865(2026-07-31 18:03) 이후인지 |
| ~~Storage `tts/v3/` 업로드 여부~~ | ✅ **완결** — 1,314/1,314 실측 (위 갱신 참조) |
| 구 `tts/v2/`·무리비전 잔존 객체 | `gcloud storage ls gs://ko-lernen-app.firebasestorage.app/tts/` — 남아 있어도 클라는 v3만 읽어 무해, 비용만. 삭제는 Jin 판단 |
| App Check enforce 콘솔 상태 · 실기기 Zephyr 청감 | Firebase 콘솔 / 실기기 |

## §5. AAB 전 완성 목록

### §5-1. 코드측 (우선순위) — 신규 차단 항목 0

| 순위 | 항목 | 상태 |
|---|---|---|
| P0 | 재빌드하는 경우에만: `flutter analyze --no-fatal-warnings --no-fatal-infos` + `flutter test` 재실행 (DEPLOY_CHECKLIST §1 공식 절차) | 본 검수 실측 통과 — §5-4 |
| P0 주의 | **래칫 여유 0 두 개** — `FontWeight.w800` **193/193** · 금지 글리프(`▶◀`) **2/2** (typography_guard_test:52, no_emoji_glyph_test:52). w900은 45/46(여유 1). **Dart 코드를 한 줄이라도 추가하는 세션은 이 래칫부터 의식할 것** | 통과 중, 여유 0 |
| P1 | 사운드 설정 UI 부재(§6-ⓐ) — 이번 배포에서 **알고 빼는** 항목(AGENTS.md·DEPLOY_CHECKLIST:195 명시) | 다음 사이클 1순위 |
| P1 | growl_tiger.mp3 미배선(§6-ⓒ) — 26KB 사장 자산으로 번들 중 | 사운드 사이클에 처리 |
| P2 | 온보딩 raw TextStyle 17개 → SoriTextTheme 이행 후 w800 상한 193→**189 복구** (typography_guard_test:41-52 주석에 명시) | 임시 상향 상태 |
| P2 | `release.ps1` 부재 — AGENTS.md:411 기록만 있고 **git 히스토리 전체에 존재한 적 없음**(유실 추정). 실질 게이트 SSoT = `docs/DEPLOY_CHECKLIST.md` §1 | 재작성 or 기록 정정 |
| P3 | 에셋 용량 감축(136MB, AAB 235.4MB) | 다음 사이클 |

### §5-2. Jin / 기기·콘솔측 (코드로 불가)

1. **Redmi 설치 승인** — MIUI `INSTALL_FAILED_USER_RESTRICTED` 2회. 잠금 해제 + USB 설치 승인 후 기존 APK(`FDCAE3E1…D2AF1C`)로 재개.
2. **스모크 10항목**(DEPLOY_CHECKLIST §5) — 인트로 영상+소리·온보딩 대비·캐릭터 선택 2종·프로필 핑크 사각형 부재·Lernpfad 전 노드 탭·게임 결과 마스코트·TTS·로그인/클라우드·알림 권한·재실행 진행도.
3. **디코더 logcat** — `adb logcat | findstr "ExoPlayerImpl reclaim CodecException"` (ADR-001).
4. Play Console versionCode 6 소비 확인(소비 시 +7) · 태그 `v2.0.1` 생성(현재 v1.0.1뿐) · 내부 테스트 트랙 먼저 · data-safety 권한 4종 재확인 · 배포 후 24h Crashlytics 감시 + 롤백 레버(ADR-001 §7).
5. TTS 배포측 확인 3종(§4-4).

### §5-3. 재빌드 불필요 판정 근거 (중요 정정)

마지막 매니페스트(7979bc8) 이후 커밋 2개(`2edbdb3`·`bf33ddb`)는 **문서 + growl_tiger.mp3 tracked화**뿐, Dart 무변경. 그리고 **"growl이 기존 AAB에 없다"는 가설은 반증됨**: Flutter는 git이 아니라 **디스크**에서 번들하는데 growl_tiger.mp3는 2026-08-01 빌드 시점에 이미 디스크에 있었고(untracked였을 뿐) pubspec:125가 `assets/sfx/` 폴더째 선언 → `unzip -l`로 기존 AAB 안에 `base/assets/flutter_assets/assets/sfx/growl_tiger.mp3` 26,270B 엔트리 **실존 확인**. → **재빌드 델타 0. 기존 `build/app/outputs/bundle/release/app-release.aab`(246,845,826B, Aug 1 04:10, SHA `BB20DC29…6A8D019`)가 여전히 유효한 업로드 후보.** 코드를 만지지 않는 한 재빌드는 선택.

### §5-4. 본 검수 게이트 실측 (2026-08-02, HEAD bf33ddb)

```
flutter analyze --no-fatal-warnings --no-fatal-infos  →  No issues found! (53.6s)
flutter test --reporter compact                        →  +1293: All tests passed!
```

2026-08-01 릴리스 게이트(analyze 0 · test 1,293 · 매트 16/16)와 동일 수치 재현 — 흡수 커밋 이후에도 게이트 전부 green.

## §6. 다음 세션 작업 스펙 (우선순위순)

> 공통 주의: ① 래칫 여유 0(§5-1) — 새 위젯에 w800·`▶◀` 금지 ② arb 키 추가 시 `flutter gen-l10n` 필수(DE/EN parity) ③ 영상 코드는 lease 경유 강제(§1 불변식) ④ Dart 수정 후 `flutter analyze` + `flutter test` (기준 1,293개).

- **ⓐ 사운드 마스터 토글 (가장 싸고 가장 급함)** — ⚠️ **Storage 키는 임의 이름(`soundEnabled` 등)을 만들지 말고 ADR-002 §3-4의 확정 스킴을 그대로 쓸 것**: `kl_snd_master`(+ 이후 `kl_snd_master_vol`/`kl_snd_$id`/`kl_snd_${id}_vol`/`kl_snd_duck`/`kl_snd_respect_silent`). `SoundService.enabled`는 ADR §3-6대로 **읽기 전용 getter**(`@Deprecated` + `AudioPolicy.instance.masterOn` 위임)로 전환 — 컴파일러가 대입을 막는 구조가 정답. **저장값 없을 때 기본 true 필수**(false로 떨어지면 신규 사용자가 무음 앱을 받음). settings_screen에 SwitchListTile 1개 + arb 2키(DE/EN, gen-l10n). **기존 게이트 읽기 4곳이 이미 배선돼 있어 이 작업만으로 3채널(게임 SFX·캐릭터 SFX·인트로) 동시 커버.** TTS는 ADR §8이 "마스터 밖" 안을 기각(speech 채널로 마스터 안에 + 음소거 시 되돌리기 스낵바 설계 §7-1) — 최소안 단계에서는 현상 유지 가능, AudioPolicy 단계에서 speech 편입.
- **ⓑ AudioPolicy + 게인 정규화 테이블** — `lib/services/audio_policy.dart` 신설(설계 완성본: `docs/ADR-002-audio-policy.md`). 산재한 볼륨 리터럴(0.55/0.6/0.65 sound_service · 0.7 character_clip:270 · 0.8 intro_gate:384)을 `AudioPolicy.volumeFor(channel)`로 이관. 앰비언스 루프 게인표(ADR-002 §1-4: hanok_construction 0.095 ~ porch 1.0, 목표 −40dB)를 에셋별 테이블로. 앰비언스를 실제로 켜려면 **HanokHeader에 volume 파라미터 신설**(현재 없음, §1) 후 SoriPosterLoop로 전달 — 17곳 호출부는 기본값으로 두고 정책 테이블이 결정.
- **ⓒ growl_tiger.mp3 배선** — Jin 의도(2026-08-02 원문): "sound만든거 배선해서 유저가 사운드 설정에서 사운드 세밀하게 조정하게 가능하게하려고 만든거야." 사운드 설정 화면의 카테고리(캐릭터 SFX) 미리듣기 또는 호랑이 roar/스트레치 계열 SFX로 배선. `CharacterClips.sfxFor()`에 추가하는 경우 celebrate_tiger와의 역할 분담을 Jin에게 확인.
- **ⓓ listening voice 갭** — listening_screen.dart:136에 scenario_player:600-602의 화자→voice 규칙 이식(user→female, 그 외→male). 1줄급, 사전생성 캐시 적중 복구.
- **ⓔ TTS 더킹 (선행조건 있음)** — 더킹 훅은 `soriVideoLease` 코디네이터(활성 핸들 1개를 이미 알고 있음)에 볼륨 콜백을 넣는 것이 자연스러운 자리. AudioPolicy(ⓑ)가 선행. 현재 실질 리스크는 낮음(소리 나는 영상 = 인트로 1개 경로, 루프 전부 무음).
- **ⓕ 소소한 정리(묶음)** — `SoundService.levelUp()` 호출 0(레벨업 지점에 배선 or 제거) · `tiger_greet.mp3` 죽은 경로(재활성 여부 Jin 확인, 아니면 번들 제외) · sound_service.dart:6 doc 주석 ".mp3"→".wav" · intro_gate:21 "무음" 주석 정정 · tts_service 폴백 주석 "526 단어+526 예문" → 실제 558/558 · P2 래칫 189 복구(§5-1).
- **ⓖ blendColor 불일치 2건 (핑크 계열 잔여 — 병렬 세션 발견, 본 검수 코드 확인)** — `CharacterClipPlayer`는 자체 배경 없이 multiply만 걸어 blendColor가 실제 카드 배경과 다르면 흰 영상 배경이 그 색으로 수렴: ① kkeunmari_screen(~:425) — blendColor base가 `s.surface`인데 카드 실제 공식(card.dart:108-115)은 라이트에서 `SoriColors.lightSurfaceRaised` base(tinted면 accent@0.08 alphaBlend) → delta RGB (13,16,25) ② listening_screen(~:595) — `const CharacterClipPlayer`가 blendColor 미전달(기본 lightBg) vs 부모 tinted 카드 실배경 → delta (13,3,−1). **산술 delta라 실기기 시인성 미확인 — 성과 부풀리지 말 것.** 근본 픽스 = 카드 배경 공식을 노출하는 헬퍼(예: `SoriCard.resolvedBackground(context, accent:, tinted:)`)를 만들어 양쪽이 같은 함수를 쓰게(재발 방지). 나머지 multiply 호출부는 병렬 세션이 전수 대조해 일치 확인(profile·path_trail·character_selection·scenario_player·milestone·home 전부 ✓).

## §7. 낡은 정보 정정 목록 (구 문서 대비)

1. **"HanokHeader 21 + SoriPosterLoop 5 = 26곳"** (2026-07-31 감사) → **실호출 17 + 4**. grep 라인 수가 주석·생성자 선언·별개 `_HanokHeader`를 포함했던 오류.
2. **"bf33ddb가 growl을 추가했으므로 기존 AAB에 없음 → 재빌드 필요"** (2026-08-02 흡수 세션 추정) → **반증.** 디스크 기준 번들이라 이미 포함(§5-3). 재빌드 불필요.
3. **"git push origin main 남아 있음 (2edbdb3 미푸시)"** (인계 문서) → **해소.** 2026-08-02 흡수 세션이 `bf33ddb`까지 푸시, CI green.
4. **"sfx/tiger_greet.mp3 참조 0곳"** (ADR-002 §1-5) → 코드 참조는 있으나(tiger_video:515) 유일 호출부가 `playAudio:false`라 **런타임 죽은 경로** — "소리 안 남"은 결과적으로 맞고 이유가 다름.
5. **AGENTS.md:90 파일맵의 TTS 줄(Aoede/Neural2·무리비전 경로)** → stale이었음. 본 검수에서 v3/Zephyr/Enceladus/`tts/v3/`로 정정 완료.
6. **"release.ps1 신규 작성"** (AGENTS.md 2026-08-01 로그) → 워크트리·git 히스토리 어디에도 없음. 유실 추정 — 게이트 SSoT는 DEPLOY_CHECKLIST §1.
7. growl_tiger.mp3 "배선하거나 지울 것"(ADR-002:551) → Jin 결정 반영: **지우지 않는다. 사운드 설정 세밀 조정용으로 배선한다**(§6-ⓒ).

## §8. 병렬 세션 교차 검증 (2026-08-02 오후 추가)

병렬 fable5 세션(디바이스 VM, 에이전트 10)이 같은 검수를 수행해 `~/Downloads/HANDOFF_PROMPT_hangulsori.md`(1,026줄)를 산출했다. 본 세션이 이 Windows 클론(진실 원천)에서 그쪽 주장을 독립 재검증한 결과다. **그 문서를 쓸 다음 세션은 아래 반증 목록을 먼저 읽을 것.**

### §8-1. 그쪽 신규 발견 — 본 클론에서 CONFIRMED (내 §1~§7이 놓쳤던 것)

| 발견 | 상태 |
|---|---|
| blendColor 불일치 2건 (kkeunmari·listening) | ✅ 코드 확인 → §6-ⓖ에 편입 |
| **AudioContext 미설정** — lib grep 0건. SFX가 타 앱 음악을 끊거나 기기 무음 스위치를 무시할 수 있음. ADR-002 §5-3 설계(mixWithOthers/duckOthers/respectSilence) 미구현 | ✅ grep 확인 → AudioPolicy 단계 2로 |
| growl_tiger가 `assets/sfx/README.md` 표에 미등재 (README 자체 규칙: 추가 시 같은 커밋에 표+출처 갱신) | ✅ grep 확인 |
| TTS v3 서버 업로드 완결 1,314/1,314 (Jin gsutil) | ✅ → §4-4 닫힘 |
| 캐릭터선택 호랑이 카드 ~6.4초 주기 인사음 반복 · 프로필 진입 랜덤 축하음(호랑이 1/5·까치 1/3) — "루프 클립엔 소리 안 붙인다"(character_clip:128-130) 설계 주석 위반 | 그쪽 코드 경로 논증 탄탄(미교차검증) — 실기기 확인 항목 |
| magpie_worry.mp4 런타임 도달 불가(GameOverCard 7곳 kind↔emotion 커플링으로 worry는 항상 tiger 짝 → feedbackFor(tiger,worry)=null) + tigerRoarSeatedBonus 동일 | 그쪽 논증(미교차검증) — Jin 결정 필요 |
| TigerStageVideo가 CharacterClips 상수 대신 경로 하드코딩 + 홈 히어로에 SFX 배선 자체가 없음(홈 인사 클립도 캐릭터선택과 다름: tiger_rise vs tiger_greet_pawflash) | 그쪽 실측(미교차검증) — Jin 결정 필요 |
| 단일 lease라 헤더 루프+캐릭터 클립 공존 화면(listening·kkeunmari·wordle·GameOver)에서 루프가 포스터로 폴백 | 구조상 타당(§1 불변식의 귀결) — 실기기 확인 |
| SoriButton 아이콘 래칫 **74/74 여유 0** (내 §5-1 래칫 표에 누락돼 있던 항목) · tiger_greet.mp3 라우드니스 −33 LUFS(기준 −16 대비 17 LU 낮음, 코덱도 구본 89k 2ch) | 그쪽 python 재현/ffmpeg 실측 — 채택 |

### §8-2. 그쪽 주장 — 본 클론 실측으로 반증 (다음 세션은 믿지 말 것)

| 그쪽 주장 | 실측 반증 |
|---|---|
| "l10n de 1181/en 1170, 11키 어긋남 — 델타를 늘리지 마라" | **번역키 1036 = 1036, 델타 0** (그쪽은 `@`메타데이터 항목까지 센 카운트 오류 — DE 템플릿 전용 placeholder 메타 11개는 정상) |
| "assets/rive/ 빈 폴더 → 클론/CI에 없어 빌드 실패 위험 (Q17)" | `.gitkeep`이 **git tracked** — 모든 클론에 폴더 존재. 우려 불성립 |
| "543 dirty + index.lock = 코드 편집 차단 게이트 (P0-2·P0-3)" | **Windows에선 git status 0 clean.** autocrlf가 Windows(시스템 gitconfig)=true / 디바이스 VM=unset이라 같은 디스크가 다르게 보였을 뿐. lock은 그쪽 세션의 `--no-optional-locks` 없는 git 읽기가 남긴 것 — 본 세션이 제거, Windows 조치 불요. **본 커밋에서 `.gitattributes`에 `* text=auto`를 추가해 환경 무관 일관화**(인덱스는 이미 전부 LF — i/crlf 0건이라 renormalize 델타 0) |
| "release.ps1을 무력화·수정하라 (P0-5)" | **이 머신 어디에도 실존 안 함**(레포 루트·Downloads·git 히스토리 전부 0). 그쪽이 인용한 스크립트 내용은 소멸한 컨테이너 산출물로 추정 — 재작성한다면 §5-1 P2대로 신규 작성이며 "수정"이 아님 |
| "git push 남아 있음 (2edbdb3 미푸시)" | 해소 — origin/main은 이미 그 뒤 커밋들까지 반영 |

### §8-3. 상호 보완 (둘 다 읽어야 완전)

- **그쪽에 없는 내 발견**: listening voice 미지정(male 캐시 미스, §4-3/§6-ⓓ — 그쪽 §5-B TTS 배선표가 미작성이라 놓침).
- **내게 없던 그쪽 자산**: §5-A 화면→위젯→에셋→소리 전수 배선맵 · §4 AudioPolicy 단계별 구현 지침(ADR 키 스킴·기본값 함정·테스트 7종) · §7 Jin 질문 17개(차단 5: Q1 versionCode·Q2 TTS서버[닫힘]·Q5 범위·Q12 CRLF[닫힘: renormalize 선택]·Q13 lock[닫힘]).
- **그쪽 문서의 환경 제약(§1)은 디바이스 VM 전용** — 다음 세션이 Jin의 Windows에서 돌면 Flutter/네트워크/rm 전부 가능하므로 해당 제약·우회책은 무시할 것.
