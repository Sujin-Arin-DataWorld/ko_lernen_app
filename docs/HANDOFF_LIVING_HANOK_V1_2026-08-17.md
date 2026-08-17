# 인수인계 + 계획 — 살아 있는 한옥 V1

작성 2026-08-17 (Claude 세션 `faab7a9b`) · 수신: 다음 세션 · 범위: 학습경로 ↔ 한옥 외관·사랑방
내부 매핑 / 만들 이미지 목록 / "같은 기초 위에 스타일 변화 없이 쌓기" 파이프라인 / 에셋 생성 절차

> 이 문서는 **무엇을 왜 어떤 순서로 만들고 어떤 게이트를 통과해야 하는지**만 다룬다.
> 그림의 화풍 판단은 이 문서의 소관이 아니다 — §6.3의 확인 절차만 따른다.

---

## 1. 한 장 요약 — 지금 어디까지 왔나

| 블록 | 상태 |
|---|---|
| **A1 짓다 (16단계 외관)** | **완료.** 16장 생성·게이트 통과·Jin 승인·런타임 승격·pubspec 등록·main 병합 |
| A2 살다 (사랑방 내부 12 + 외관 4) | **미착수.** 자산 0장. 12종 목록·등록 규약은 확정(§4.2, §7) |
| B1 잇다 (18) | 미착수. allowlist 확장(§5.3) 선행 필요 |
| B2 나누다 (20) | 미착수 |
| C1 돌보다 (8) · C2 전하다 (8) | 미착수 |
| 86 grant 배선(코드) | A1만 실제 자산 연결. 나머지 70은 placeholder |

- 브랜치: `claude/a2-sarangbang-furnishing-20260817` (이 문서 외 변경 없음). main에 이미 A1 전부 반영.
- BBANANA 크레딧 **848.7**. A1에 24 소진, A2 중단된 시도에 28 소진(§6.2).
- A1 런타임 자산: `assets/illustrations/personal_hanok_v2/a1/states/*.webp` 16장.

---

## 2. 설계 원칙 (변하지 않는 것 3개)

1. **6시대 = 6공간층.** A1 짓다=사랑채 외관 / A2 살다=사랑방 내부 / B1 잇다=대문·행랑채·안채 /
   B2 나누다=대청·사당·후원·마당 구조물 / C1 돌보다=계절·돌봄 / C2 전하다=벽감 서가·증표.
2. **생성 모델은 그림이 아니라 부품만 만든다.** 기하는 승인된 완성 자산에서 역분해하고,
   조립은 Python 컴포지터가 manifest 좌표대로 결정론적으로 한다(A1에서 검증 완료 — §3).
3. **86 grant는 CanDoSegment에 매핑된다**(CourseUnit·단어팩 수가 아니라). 학습 콘텐츠를 더 넣어도
   매핑은 흔들리지 않는다. 진짜 새 can-do가 생기면 segment마다 grant 1행을 함께 authoring한다.

---

## 3. "같은 기초 위에 스타일 변화 없이 쌓기" — 검증된 파이프라인

A1 이전 25회 시도가 전부 실패한 원인은 하나였다: **모델에게 단계 그림을 통째로 그리게 했다.**
그러면 매번 기둥 굵기·칸 수·카메라·기단 크기가 흔들린다. A1은 순서를 뒤집어 성공했다.

```
승인된 완성 자산 1장
   └─ derive → geometry JSON(구간·밴드·폴리곤·원근 상수) + 파생 부품 PNG      ← 크레딧 0
모델 호출은 "없는 부재"만
   └─ align → 우리 좌표로 affine 정렬 + 완성 실루엣 안쪽으로 클립             ← 부품당 4cr
manifest(부품·좌표·z·transient·prop) + 이전 단계 레이어
   └─ compose --kit → 게이트 → WebP                                          ← 재합성은 0cr
```

**핵심 도구 (이미 있고 테스트로 잠겨 있다)**

| 도구 | 역할 |
|---|---|
| `tool/derive_hanok_a1_kit.py` | 완성 자산을 측정해 geometry JSON + 파생 부품으로 분해(픽셀 전부 분할) |
| `tool/hanok_a1_kit.py` | manifest 렌더러 + 게이트(anchor·포함·구조 연속성·계보) |
| `tool/align_model_frame.py` | 생성물을 키트 기하로 affine 정렬(`--clip-dilate-px 0` 기본) |
| `tool/cut_prop_sheet.py` | 시트 1장을 오브젝트별 컷아웃(chroma→alpha, 디스필) |
| `tool/make_kit_parts.py` | 모델 없이 만드는 부품(소품 배치·부재 도색·텍스처 타일링) |
| `tool/compose_hanok_a1_state.py` | `--kit-manifest` 결정론 합성 + 크기·용량·chroma 게이트 |
| `tool/promote_hanok_a1_states.py` | 16장 원자 승격(승인 SHA 없으면 거절) |
| `tool/decoration_normalize.py` | 장식 컷아웃·트림·긴 변 1254 정규화 |
| `tool/check_personal_hanok_assets.py` | 런타임 자산 계약 검사(`--require-a1-states`) |

**게이트 (A1 16장이 실제로 통과한 값)**
- kit anchor: alpha bbox가 x=427 포함, bottom ≥ 293(01·02) / 307(03~16)
- 포함: 모든 픽셀 ⊆ dilate(완성 alpha, 1) ∪ propsZone → 위반 **0**
- 구조 연속성: 이전 단계의 비-transient 픽셀 recall **1.0**, edge drift **0**
- 용량 ≤ 350,000 B(최대 285,696) · chroma 잔여 0 · 소켓 밖 변경 0
- 15·16은 소품 제외 시 `base ⊕ sarangchae.png` 와 **픽셀 동일**

**전체 체인을 순서대로 한 번 돌려야만 잡히는 결함 2종 (실측)**
1. 생성 부품을 **누적**으로 쌓지 않으면 다음 단계에서 수백 px이 사라진다(09에서 387px).
2. 정렬 클립이 완성 실루엣 +1px이면 다음 단계가 그 픽셀을 덮지 못한다(11에서 26px).
→ B1·B2 건물 단계에도 같은 두 규칙을 그대로 적용한다.

---

## 4. 학습경로 ↔ 한옥 매핑 (86 grant)

kind = constructionPiece(구조) / furnishing(사랑방 가구, **신설 필요**) / designOption(택일) /
venue(방 개방) / ambience(겹침 가능) / credential(증표).

### 4.1 A1 짓다 16 — **완료**

01 터잡기 · 02 설계 · 03 기초·기단 · 04 초석 · 05 치목 · 06 기둥 · 07 창방·보 · 08 도리·상량 ·
09 서까래·추녀 · 10 개판·보토 · 11 기와 · 12 수장 · 13 흙벽 · 14 온돌 · 15 창호 · 16 입택.
hanokdb 공사 12단계와 정합. 파일명은 `NN_<id>.webp`(11은 `11_giwa_roof.webp`).

### 4.2 A2 살다 16 = 사랑방 가구 12 + 외관 흔적 4

**가구 12종 (기존 24장과 겹치지 않게 확정).** `decorations/` 에 이미 실내 11종이 있어 원안 5개
(찻상소반·경상·연상·머릿장·서가)는 폐기했다 — 각각 `soban`·`seoan`·`munbangsau`·`jagae_mungap`·
`chaekgado` 와 겹친다.

| # | slug | 한글 | cat | scale | DE | EN |
|---|---|---|---|---|---|---|
| 1 | `decoration_sabangtakja` | 사방탁자 | floor | 1.00 | `Regal (사방탁자)` | `Open shelf stand (사방탁자)` |
| 2 | `decoration_boryo_set` | 보료·장침·안석 | floor | 0.95 | `Sitzpolster-Set (보료)` | `Master's floor seat (보료)` |
| 3 | `decoration_bangseok_pair` | 방석 2장 | floor | 0.50 | `Sitzkissen (방석)` | `Floor cushions (방석)` |
| 4 | `decoration_bandaji` | 반닫이 | floor | 0.88 | `Klapptruhe (반닫이)` | `Front-opening chest (반닫이)` |
| 5 | `decoration_hwaro` | 화로 | floor | 0.38 | `Kohlebecken (화로)` | `Charcoal brazier (화로)` |
| 6 | `decoration_deungjan` | 등잔대 | floor | 0.30 | `Öllampe (등잔대)` | `Oil lamp stand (등잔대)` |
| 7 | `decoration_geomungo` | 거문고 | floor | 0.98 | `Geomungo-Zither (거문고)` | `Geomungo zither (거문고)` |
| 8 | `decoration_baduk` | 바둑판·바둑통 | floor | 0.58 | `Baduk-Brett (바둑판)` | `Baduk board (바둑판)` |
| 9 | `decoration_mokchim` | 목침 | floor | 0.22 | `Holzkissen (목침)` | `Wooden pillow (목침)` |
| 10 | `decoration_byeongpung_small` | 소병풍 2폭 | wall | 0.55 | `Kleiner Wandschirm (소병풍)` | `Two-panel screen (소병풍)` |
| 11 | `decoration_gobi` | 고비 | wall | 0.26 | `Briefhalter (고비)` | `Letter rack (고비)` |
| 12 | `decoration_hyangno` | 향로·향합 | shelf | 0.52 | `Räuchergefäß (향로)` | `Incense burner (향로)` |

`scale` 은 같은 카테고리 안에서 값이 서로 달라야 한다(테스트가 검사). 위 값이 그 조건을 만족한다.

**외관 흔적 4**: 굴뚝 연기 · 처마 등롱 켜짐 · 용마루 까치 · 장독 첫 항아리 2개.
좌표는 A1의 `props_14_ondol`·`props_16_movein` 위치에 앵커한다.

### 4.3 B1 잇다 18
솟을대문 3단계(기단·문설주 → 지붕 → 문짝·편액) · 행랑채 4단계(기단 → 골조 → 지붕 → 벽·창) ·
안채 4단계(기단 → 골조 → 지붕 → 벽·창호) + ambience 6(석등·소나무·빨랫줄·매화·대문 열림·장독대) +
venue 1(안방 개방). 건물 단계는 **prerequisite 체인**으로 순서를 강제한다.

### 4.4 B2 나누다 20
대청 3 · 사당 3 · 후원 3 · 마당 구조물 3(우물·석등·담장 장식) + designOption 4(창호·굴뚝·벽 마감·
지붕 재료 — 진짜 택일) + credential 3 + venue 1(대청 개방).

### 4.5 C1 돌보다 8 = credential 4 + 계절 designOption 4 / C2 전하다 8 = credential 8
계절은 slot 하나에 택일(봄꽃과 눈이 동시에 뜨면 안 된다). C2는 사랑방 벽감 선반에 문집이 한 권씩
꽂힌다. 증표 15개는 다른 grant·장식 소유에 기대지 않는다(도장첩 증표 탭 + 벽감 레이어).

---

## 5. 만들 이미지 목록 (남은 것)

| 블록 | 새로 만들 것 | 방법 | 예상 크레딧 |
|---|---|---|---|
| A2 가구 12 | 12장 | 개별 생성 → `decoration_normalize.py` | 48 |
| A2 외관 흔적 4 | 4장 | overlay(부분 alpha), A1 소품 좌표에 앵커 | 16 |
| B1 건물 3채 | 골조 3장 | 완성 PNG 역분해 + 골조만 생성 → 단계 조립 | ~27 |
| B1 ambience 6 | 6장 | overlay | 24 |
| B2 건물·구조물 | 골조 2 + sprite 3 | 후원은 alpha 3분할(생성 0) | ~30 |
| B2 designOption 4 | ~6장 | overlay·mask | 25 |
| C1 계절 4 + 돌봄 2 | 6장 | overlay(후원 영역 한정) | 24 |
| C2 문집 | 2장 색 변형 | sprite | 8 |
| **합계** | **≈45장** | | **≈200** (잔액 848.7) |

건물 역분해용 신규 도구 `tool/derive_estate_building_stages.py` 는 **아직 없다** — B1 착수 시 만든다.

### 5.3 선행 조건 — allowlist 확장 (B1·B2 착수 전 필수)

`docs/assets/HANOK_V1_ASSET_PROVENANCE.json` 의 `allowedModelInputs` 는 지금 **3개뿐**이고 Dart
테스트가 그 집합을 정확히 검사한다. 건물 PNG(`sotdaeulmun`·`haengrangchae`·`anchae`·
`daecheongmaru`·`sadang`·`rear_garden`)를 모델 입력으로 쓰려면 SHA·파일 메타·권리 근거와 함께
먼저 편입해야 한다. **편입 전에는 그 파일로 생성 호출을 하지 않는다.**
(장식 계열은 provenance `scope: "hanok_v1_assets_only"` 밖이라 이 제약을 받지 않는다.)

---

## 6. 에셋 생성 절차 (실측 규칙)

### 6.1 요금 — 계획 전에 반드시 반영할 것
- Nano Banana Pro 2K는 표시가 4cr이지만 **참조 이미지 3장을 붙인 호출에서 24cr이 빠졌다**
  (876.7 → 852.7 실측). 참조 1장 호출은 정확히 4cr. ⇒ **참조는 0~1장.**
- 호출 응답의 `remainingCredit` 로 매번 단가를 확인한다. 여러 장 쏘기 전에 1장으로 검증한다.

### 6.2 순서 — 1장 승인 후 나머지
1. 대표 1장만 생성 → **Jin 육안 승인**.
2. 통과하면 남은 장수를 진행. 불합격이면 프롬프트만 고쳐 4cr씩 재시도(전량 재생성 금지).
3. 정규화 → 등록 → QA 대조 시트 → Jin 장별 승인 → 원장 기록 → 승격.

2026-08-17에 A2를 이 순서 없이 2장 연속으로 쏘아 28크레딧을 태우고 중단했다(BBANANA task
`663d7694…`, `4db5dd10…`). 산출물은 저장소에 넣지 않았다. **1장 검증 원칙을 반드시 지킬 것.**

### 6.3 프롬프트 원문 기록은 의무다
기존 사랑방 6종을 만든 프롬프트가 저장소에 남아 있지 않다(`docs/P1_ASSET_DOWNLOAD_2026-08-04.md`
에 결과 링크만 있음). 그래서 재시도가 기존 세트와 어긋났다.

- **A1은 이 실수를 반복하지 않도록** `docs/assets/prompts/a1_kit_prompts.json` 에 원문을 정본으로
  두고 원장 `promptSha256` 을 그 문자열의 해시로 잡았다. A2도 같은 방식으로 남긴다.
- 과거 프롬프트는 복구 가능하다: 결과 파일명이 `gvi_…` 인 것은 그 자체가 task ID라
  `get_status(taskId)` 로 원문이 나온다(무료). 숫자 파일명은 `list_my_generations` 로 찾는다.
  복구 확인된 것: `gvi_1785839371699_kh2ia`(문방사우), `gvi_1785839433358_iy9mit`(소반),
  `gvi_1785839407073_1b2ygb`(갓·부채).
- **착수 전 확인 절차**: 사랑방 실내 세트와 마당 장식 세트는 **서로 다른 규약으로 만들어졌다.**
  `docs/ASSET_GENERATION_BIBLE.md` §3.5는 마당 규약이므로 실내 자산에 그대로 적용하면 어긋난다.
  실내 6종의 원본 프롬프트를 위 방법으로 복구해 그것을 기준으로 삼고, 결과는 대표 1장으로
  Jin에게 확인받은 뒤 나머지를 진행한다.

### 6.4 원장·승격
- A1 상태·부품은 `generationLedger` 에 9레코드 / 승인 출력 32개로 기록되어 있다. 입력은
  **allowlist 또는 앞선 승인 출력**만 참조할 수 있다(모델이 반환한 raw도 출력으로 기록해 다음
  단계의 입력 자격을 만든다).
- 런타임 승격은 원자적이다: 16장 전부 승인 SHA가 있어야 `promote --apply` 가 통과한다.
- 장식은 hanok 원장 관할이 아니다 → 별도 프롬프트 문서에 기록한다.

---

## 7. A2 착수 시 코드 변경 지점 (빠뜨리면 화면에 placeholder가 뜬다)

1. `lib/widgets/sori/placed_decoration.dart` **네 곳**: `kAvailableDecorations`(129행) ·
   `kDecorCategory`(38행) · `kDecorScale`(64행) · `decorName` switch(85행).
2. `lib/l10n/app_de.arb` / `app_en.arb` 에 12키씩 24개(형식 `"<번역> (<한글>)"`, em/en dash 금지)
   → `flutter gen-l10n`.
3. `test/decoration_transparency_test.dart` 의 하드코딩 목록에 신규 12 슬러그 추가.
4. `assets/illustrations/decorations/_raw/` 에 원본(gitignore됨) → `tool/decoration_normalize.py`
   → `decorations/<slug>.png`(RGBA, 긴 변 1254, 사방 3% 여백). pubspec은 디렉터리 선언이라 수정 불필요.
5. 프롬프트 문서 신설 + `docs/SESSION_LOG.md` 최상단 기록.

**손대지 말 것**: `kDecorationRewardPool`(퀘스트 보상 풀 — A2는 grant로 준다) ·
`Storage.ownedDecor` 쓰기 · hanok provenance/원장(장식은 관할 밖) · grant 카탈로그·`HanokGrantKind`.

**⚠️ 방에서 실제로 집으려면 PR5b가 필요하다.** `personal_room_furnish_screen.dart:726` 은
`Storage.ownedDecor ∩ kAvailableDecorations` 만 피커에 보여준다. 등록만으로는 보유가 되지 않으니
A2 grant → 인벤토리 **읽기 합집합**(PR5b)이 붙어야 배치된다. 그 전 검수는 QA 대조 시트로 한다
(배경 `assets/illustrations/hanok/sarangbang_empty.png` 1086×1448 RGB, 산출은
`assets_unused/pending_review/`).

---

## 8. 남은 코드 작업 (PR 분할)

| PR | 내용 |
|---|---|
| PR5a | grant 초안 재생성(prerequisite 체인·venue 재배정) · `HanokGrantKind.furnishing` 신설 · `hanok_grant_catalog.dart:176` venue 검사 확장 · projector `openedVenues` 에 사랑방 기본 포함 · l10n 86×2 + 16 · glossary 24항목 |
| PR5a′ | provenance `allowedModelInputs` 확장(§5.3) + 소스 레지스트리 갱신 — **B1·B2 생성 전 필수** |
| PR5b | 사랑방 가구 등록 · 룸 소유 합집합(순수 함수) · `derive_estate_building_stages.py` · estate 단계·overlay·계절 레이어 카탈로그 · credential motif · `sarangchae_props` 분리 승격 |
| PR6/7 | 진입점·cutover |

---

## 9. 검증 커맨드

```bash
# 장식 계열
python tool/decoration_normalize.py
flutter gen-l10n
flutter test --no-pub test/decoration_slot_test.dart test/decoration_transparency_test.dart \
  test/arb_l10n_guard_test.dart test/l10n_parity_test.dart \
  test/personal_room_furnish_screen_test.dart test/free_room_layer_test.dart

# 한옥 단계 계열
python -m unittest discover -s tool -p "test_*.py"
python tool/promote_hanok_a1_states.py                     # dry-run
python tool/check_personal_hanok_assets.py --require-a1-states

# 전체
flutter analyze --no-pub --fatal-infos
flutter test --no-pub                                      # 현재 기준 3886 통과
```

---

## 10. 참고 파일 지도

| 목적 | 경로 |
|---|---|
| 전체 설계(86 grant 매핑 원문) | `docs/superpowers/specs/2026-08-17-living-hanok-v1-mapping-kit-pipeline-design.md` |
| A1 재현 플레이북 | `docs/assets/prompts/HANOK_V1_A1_KIT_GENERATION_PLAYBOOK.md` |
| A1 프롬프트 원문 정본 | `docs/assets/prompts/a1_kit_prompts.json` |
| A1 계약(게이트 규칙) | `docs/assets/prompts/HANOK_V1_A1_TRANSPARENT_LAYER_CONTRACT.md` |
| 자산 계약·생성 원장 | `docs/assets/HANOK_V1_ASSET_PROVENANCE.json` |
| 키트 기하·stage manifest | `docs/assets/hanok_a1_kit/` |
| 기존 사랑방 6종 결과 링크 | `docs/P1_ASSET_DOWNLOAD_2026-08-04.md` |
| 출처 사용 경계 | `docs/HANOK_V1_SOURCE_REGISTRY.md` |
| 장식 등록 지점 | `lib/widgets/sori/placed_decoration.dart` |
| 방 정의·배경 | `lib/data/personal_room_catalog.dart` |
| 세션 이력 | `docs/SESSION_LOG.md` (최상단이 A1 완료·승격·D1 rename) |
