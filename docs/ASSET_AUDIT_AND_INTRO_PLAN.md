# Hangul Sori — 에셋 전수 감사 + 인트로 재설계 계획

> 작성: 2026-06-02 · 범위: `assets/` 전 이미지 117장 실측(치수·투명도·코드 사용처) + 인트로 재설계.
> 판정 키: ✅재사용 / 🔧투명수정 / ♻️재생성(스타일·품질) / ❌불필요(앱) / ➕신규제작
> 스타일·프롬프트 기준: `docs/ASSET_GENERATION_BIBLE.md`

---

## 0. 한눈 요약 (가장 중요한 3가지)

1. **투명도 깨짐이 광범위함** — 마스코트뿐 아니라 **장식 10·도장 6·스티커 11·게이트 문 3 + 마스코트 9 = 약 39장**이 흰/회색 배경 박힌 불투명. 오버레이로 합성되는 자산(장식·도장·마스코트·문)은 투명이 **필수**라 전부 사각형으로 보임.
2. **인트로가 스타일 충돌 + 불투명으로 깨짐** — 사진풍 `gate_entrance/gate_final` + 불투명 문짝이 뒤엉켜 "문 없는 빈 대문 + 흰 화면". → faceted로 단순화 재설계 필요.
3. **앱에 안 쓰는데 빌드에 포함되는 낭비** — `mascot/backup`·`hanok/backup`(15장, 수 MB), `madang(dark)`(다크폐지), `welcome-hero`·`gate.png`(미참조) 등 → assets 밖으로.

---

## 1. 폴더별 전수 분류

### 1.1 마스코트 `assets/illustrations/mascot/` — 코드: `mascot.dart`가 emotion별 참조

| 파일 | 치수 | 투명 | 화풍 | 판정 |
|---|---|---|---|---|
| `tiger_idle` | 1254² | ❌흰배경 | ✅faceted 마스터 | 🔧투명수정 → 재사용 |
| `tiger_blink` | 1254² | ❌흰배경 | ✅faceted | 🔧투명수정 (또는 idle에서 눈만) |
| `tiger_happy` | 1254² | ❌흰배경 | ✅faceted | 🔧투명수정 |
| `magpie_wingup` | 1254² | ❌흰배경 | ✅faceted 마스터 | 🔧투명수정 |
| `magpie_wingdown` | 1254² | ❌흰배경 | ✅faceted 마스터 | 🔧투명수정 |
| `tiger_celebrate` | 1024² | ❌회색체커 | ✗옛 회화풍 | ♻️재생성(BIBLE §2.4.5) |
| `tiger_neutral` | 1024² | ❌회색체커 | ✗옛 | ♻️재생성 (또는 idle 복제) |
| `tiger_sad` | 1024² | ❌회색체커 | ✗옛 | ♻️재생성 |
| `tiger_smile` | 1024² | ❌회색체커 | ✗옛 | ♻️재생성 (또는 idle 편집) |
| `tiger_sleepy` | 1254² | ✅ | ✗다른 화풍 | ♻️재생성 |
| `tiger_thinking` | 1254² | ✅ | ✗다른 화풍 | ♻️재생성 |
| `magpie_perched` | 1024² | ✅ | △옛(1.4MB) | ♻️재생성 권장(임시 재사용 가능) |
| `magpie_celebrate` | 1024² | ✅ | △옛(1.5MB) | ♻️재생성 권장 |
| `magpie_worry` | 1024² | ✅ | △옛(1.5MB) | ♻️재생성 권장 |
| `mascot/backup/*` (9) | — | — | — | ❌assets 밖으로 이동 |

> 결론: **faceted 통일 세트 = idle/blink/happy/wingup/wingdown(투명수정만)**, 나머지 호랑이 6 + 까치 3은 BIBLE §2 기준 재생성. backup 9장은 빌드 제외.

### 1.2 한옥 공간 `assets/illustrations/hanok/`

| 파일 | 용도(코드) | 투명/스타일 | 판정 |
|---|---|---|---|
| `madang(light)` | 홈 배경·인트로 도착점 | 불투명 full-bg(정상) | ✅재사용 (인트로 도착 마당) |
| `madang(dark)` | (다크모드) | 불투명 | ❌불필요(다크 폐지) → 아카이브 |
| `calligraphy` | Hangul 헤더 | full-bleed 불투명(정상) | ✅재사용 |
| `porch` | Chosung/Wordle 헤더 | 〃 | ✅재사용 |
| `study_classroom` | Vocab 헤더 | 〃 | ✅재사용 |
| `study_scholar` | Grammar 헤더 | 〃 | ✅재사용 |
| `achievements` | Stats 헤더 | 〃 | ✅재사용 |
| `listening_hero` | Listening 헤더 | 〃 | ✅재사용 |
| `kkeunmari_hero` | Kkeunmari 헤더 | 〃 | ✅재사용 |
| `gate_frame` | 인트로 대문 프레임 | ❌불투명·사진풍 | ♻️faceted 재생성 (또는 벡터 대체, §3) |
| `gate_door_left/right` | 인트로 문짝 | ❌불투명·사진풍 | ♻️faceted 재생성 (또는 벡터) |
| `gate_entrance` | 인트로 establishing | ❌사진풍 full | ❌인트로서 제거(홈페이지만) |
| `gate_final` | 인트로 마당 컷 | ❌사진풍 full | ❌제거 → madang으로 대체 |
| `gate.png` | (미참조, 홈페이지) | 불투명 | ❌앱 불필요 |
| `welcome-hero` | (미참조) | 불투명 | ❌앱 불필요(홈페이지 사본만) |
| `dancheong_frame` | (미참조) | 투명 | ❌사용처 없음 → 보류/제거 |
| `hanok/backup/*` (6) | — | — | ❌assets 밖으로 이동 |

### 1.3 한옥 성장 단계 `hanok_stages/` — 코드: `madang_background.dart`가 `stage_{slug}_light.png`

| 상태 | 파일 | 판정 |
|---|---|---|
| ✅있음(10) | empty·foundation·pillars·beams·thatch·tile_partial·tile_complete·dancheong·gate·windows | ✅재사용 (full-bg 불투명 정상) |
| ➕누락(2) | `stage_side_building_light`·`stage_jongga_light` | ➕신규제작 (11·12단계, BIBLE §3) |
| ❌폐지 | 모든 `_dark` 12장 | 다크 폐지로 제작 안 함 |

### 1.4 퀘스트 장식 `decorations/` — 코드: `decoration_layer.dart`가 madang 위 **오버레이 합성**

| 상태 | 파일 | 투명 | 판정 |
|---|---|---|---|
| 🔧있음(10) | jangdokdae·maehwa·sonamu·pond·punggyeong·pyeonaek·sagunja_(maehwa/nan/juk)·kkachi_nest | ❌전부 흰배경 | 🔧**투명수정 필수**(안 하면 마당에 흰 사각형) |
| ➕누락 | sagunja_guk·seokdeung·doldam·seollal_flag·chuseok_moon·hangeulday_plaque·kite | — | ➕신규(P3~P4 백로그) |

### 1.5 단청 도장 `stamps/` — 코드: `dancheong_stamp.dart`

| 상태 | 파일 | 투명 | 판정 |
|---|---|---|---|
| 🔧있음(6) | lotus·chrysanthemum·bamboo·cloud·geometric_octagon·swastika | ❌흰배경 | 🔧투명수정 필수 |
| ➕누락(2) | stamp_mountain·stamp_plum | — | ➕신규 |

### 1.6 스티커 `assets/stickers/` (11장)

| 파일 | 투명 | 판정 |
|---|---|---|
| dancheong_(cloud/flower/hanji/star)·food_(hotteok/kimbap/sikhye/tea/tteok)·hangul_(fighting/hh) | ❌흰배경 | 🔧투명수정 **단 v3.0(계 채팅) 기능 전엔 앱 미사용** → 우선순위 낮음 |

### 1.7 시나리오 백드롭 `scenes/` (5) — 코드: scenario/list가 `scenes/{key}.png`

| 파일 | 판정 |
|---|---|
| cafe·hotel·restaurant·directions·market | ✅재사용 (투명/풍경 정상) |

### 1.8 빈/오류 상태 `empty/` `error/`

| 파일 | 판정 |
|---|---|
| empty: celebrate_complete·sleeping_tiger_b2·studyroom_waiting | ✅재사용(투명) |
| error: lost_magpie | ✅재사용(투명) |
| error: offline_lantern | ✅재사용(자체 어두운 씬, 불투명 OK) |

### 1.9 아이콘/웹/문서 (앱 로직 무관)

| 파일 | 판정 |
|---|---|
| `icons/HanLogo`(1024 소스)·`icons/icon-192`·`web/icons/*`·`web/splash/*` | ✅재사용(앱 아이콘/스플래시) |
| `docs/assets/*`·`docs/store/*` | 홈페이지·문서용 — 앱 무관, 그대로 |

---

## 2. 투명도 일괄 수정 대상 (Phase 1 — 즉시)

**테두리 시드 flood-fill**로 흰/회색 배경만 알파로 (내부 cream `#F4E8D0`은 테두리와 안 이어져 보존). 1장 before/after 승인 후 일괄.

- **마스코트 9**: tiger_idle·blink·happy·celebrate·neutral·sad·smile, magpie_wingup·wingdown
  (celebrate/neutral/sad/smile은 투명수정으로 박스는 사라지나 화풍은 여전히 옛 → 이후 ♻️재생성)
- **장식 10**: decorations/*.png 전부
- **도장 6**: stamps/*.png 전부
- **게이트 3**: gate_frame·gate_door_left·gate_door_right (단 인트로 방향에 따라 §3 결정 후)
- **(보류) 스티커 11**: v3.0 전까지 미사용 → 나중에

> 효과: 홈 아바타·시나리오 썸네일·리스트·퀘스트 마당 장식·도장첩의 **사각형 박스 전부 제거**. 코드 변경 0.

---

## 3. 인트로 재설계 — "문 열리며 마당으로 빨려듦"

### 3.1 현재 문제 (intro_gate_screen.dart)
사진풍 `gate_entrance` + 사진풍 `gate_final` + faceted `madang` + 벡터 `HanokGateArt` + 불투명 문짝을 5겹 크로스페이드 → 과설계 + 스타일 충돌 + 흰 박스.

### 3.2 목표 연출
닫힌 솟을대문 → 문짝이 바깥으로 열림 + 문틈 황금빛 → 카메라가 열린 문 사이로 **마당 push-in** → 홈. 까치 1마리 가로지름.

### 3.3 레이어 단순화 (5겹 → 3겹)
1. **배경 = 마당**: `madang(light)` (도착점). 사진풍 gate_final 제거.
2. **대문 프레임 + 문짝** (투명): 가운데서 바깥으로 swing/slide 열림.
3. **연출 오버레이**: 문틈 glow + vignette + 까치.

### 3.4 대문 에셋 — 두 경로
- **경로 A (권장·빠름, 신규 에셋 0)**: 기존 **벡터 `HanokGateArt`(CustomPainter)** 를 faceted 팔레트로 다듬어 프레임+문짝을 그림. 투명·스타일 통일 자동, PNG 의존성 제거. → 먼저 이걸로 동작시키고
- **경로 B (리치·나중)**: BIBLE §3.2 솟을대문 프롬프트로 **문짝 분리 2장 + 프레임 1장(투명 faceted)** 생성해 벡터 대체.
- 어느 쪽이든 사진풍 `gate_entrance/gate_final`은 인트로에서 제거.

### 3.5 타임라인 (첫 실행 ~3.9s / 재실행 ~2.3s)
```
0.00–0.15  닫힌 대문 establishing (한지 하늘 + 닫힌 문짝)
0.15–0.45  문짝 바깥으로 열림(openAmount 0→1) + 문틈 황금 glow(종 모양)
0.30–0.80  까치가 화면을 가로질러 비행 (magpie_wingup/down 교대)
0.45–0.88  카메라 push-in: 대문 scale↑ + 마당 점점 선명·확대(중심 정렬)
0.80–1.00  대문 레이어 페이드아웃 → 마당만 → 홈 fadeScale handoff
```
- reduce-motion: 애니 생략, "열린 대문+마당" 1프레임 → 즉시 홈.
- 탭 = skip(현행 유지).

### 3.6 코드 변경 요약 (intro_gate_screen.dart)
- `_gateEntranceAsset`·`_courtyardAsset`(사진풍) 레이어 **삭제**.
- 배경을 `madang(light)` 단일 + push-in scale.
- 대문 = `HanokGateArt(openAmount)`(경로 A) 또는 투명 PNG 문짝(경로 B).
- 타이밍 함수 5개 → 3~4개로 축소(approach/frameAppear/entranceFade 제거).

---

## 4. 단계별 액션 플랜 (우선순위)

| Phase | 작업 | 누가 | 비고 |
|---|---|---|---|
| **P1 즉시** | 투명도 일괄 수정(마스코트9+장식10+도장6) | 나(샌드박스) | 1장 승인 후 일괄. 코드 무변경. 박스 문제 즉시 해소 |
| **P1.5** | `*/backup` 15장 + `madang(dark)`·`welcome-hero`·`gate.png`·`dancheong_frame` assets 밖으로 | 나 | 빌드 용량↓, 혼선 제거 |
| **P2 인트로** | intro_gate_screen.dart 3겹 재설계(경로 A 벡터) | 나 | 사진풍 제거, 문열림+push-in. 시각검증은 Jin 로컬 |
| **P3 마스코트 재생성** | tiger celebrate/neutral/sad/smile/sleepy/thinking + magpie perched/celebrate/worry | 생성기(BIBLE §2) | idle/wingup·down을 레퍼런스로. 나는 후처리·배치 |
| **P3 한옥 마무리** | stage_side_building·stage_jongga (11·12단계) | 생성기(BIBLE §3) | 없으면 마지막 성장 연출 누락 |
| **P4 백로그** | 게이트 faceted PNG(경로 B)·장식 누락·도장 2·스티커 투명·계절장식 | 생성기 | v2.1~v3.0 |

---

## 5. 즉시 다음 행동
1. **P1 투명도**: `tiger_idle` 1장 변환 → before/after 확인 → 승인 시 마스코트9+장식10+도장6 일괄.
2. 병행 **P2 인트로** 코드 초안(경로 A) 작성.
3. P3 재생성 목록은 BIBLE 프롬프트로 생성기에서 진행(이미지는 외부 생성 필요).
