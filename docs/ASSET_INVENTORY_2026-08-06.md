# 에셋 전수 목록 — 2026-08-06

> `docs/ASSET_FILE_TRIGGER_MAP.md`(2026-07-30)와 `ASSET_TRIGGER_AUDIT_2026-07-30.md`는
> tiger_anim 44장 폐지·magpie 영상 교체·사랑방 실내 장식 신설 이전 기준이라 현재
> 상태와 맞지 않는다. 이 문서가 최신 전수 목록이다.
>
> **판정 기준 2축**
> - **번들**: `pubspec.yaml` 의 `flutter: assets:` 에 등록된 디렉터리에 **직접** 들어 있는가.
>   Flutter 의 디렉터리 등록은 **비재귀**라 하위 폴더(`_raw/` 등)는 자동으로 안 들어간다.
> - **참조**: `lib/` 코드 또는 `assets/data/*.json` 이 그 파일을 가리키는가.
>   동적 조립 경로 7종은 아래 "동적 참조" 절에서 별도 검증했다.

| 구분 | 개수 | 용량 |
|---|---:|---:|
| 번들 O · 사용 O | 229 | 156.5MB |
| **번들 O · 사용 X** (앱에 들어가지만 안 씀) | **7** | **8.6MB** |
| 번들 X (원본·작업 파일, 앱에 안 들어감) | 39 | 47.4MB |
| **합계** | **275** | **212.5MB** |

> **판정 방법 (2026-08-06 2차 개정).** 1차는 파일명 문자열 매칭이라 오탐이 났다.
> 지금 수치는 **각 폴더를 실제로 결정하는 카탈로그를 파싱해** 판정한 것이다:
> `kAvailableDecorations` · `DancheongMotif` · `HanokStage.assetSlug` ·
> `sticker_catalog.dart` · `CharacterClips`+`TigerStageVideo.greetFor/paceFor` ·
> `HanokHeader.kLoopAssets` · `lib/models/scenario.dart` 의 씬 카테고리 맵 11종.
> 카탈로그가 없는 폴더만 경로/파일명 매칭으로 본다(sfx 는 `assets/` 접두사 없이
> `AssetSource('sfx/x.mp3')` 로 참조되므로 부분경로도 함께 본다).

---

## 1. 지금 쓰이는 것 — 번들 O · 사용 O (230개 / 158.4MB)

| 디렉터리 | 개수 | 용량 | 쓰임 |
|---|---:|---:|---|
| `video/character/` | 22 | 32.7MB | 홈 히어로·프로필·선택/확정·축하 — `CharacterClipPlayer` |
| `video/loops/` | 14 | 26.3MB | 시나리오 인트로·헤더 루프 — `HanokHeader.kLoopAssets` |
| `illustrations/decorations/` | 23 | 14.0MB | 마당·사랑방 장식 — `kAvailableDecorations` |
| `illustrations/hanok/` | 15 | 12.4MB | 인트로 대문·마당·학습 히어로 |
| `illustrations/hanok_stages/` | 12 | 10.4MB | 학습경로 12단계 — 동적 |
| `illustrations/hanok_compound/` | 7 | 10.3MB | 공동 한옥(계) |
| `stickers/` | 30 | 9.0MB | 스티커 — `sticker_catalog.dart` |
| `illustrations/scenes/` | 11 | 6.6MB | 시나리오 배경 — `scenario.dart` 카테고리 맵 11종 (`pharmacy` 제외) |
| `illustrations/stamps/` | 14 | 3.7MB | 단청 도장 14문양 — 동적 |
| `video/intro_gate_to_madang.mp4` | 1 | 5.9MB | 인트로 전환 |
| `illustrations/mascot/` | 26 | 3.4MB | 호랑이·까치 정지컷 (영상 폴백 포함) |
| `illustrations/personal_hanok_v2/` | 10 | 9.9MB | 개인 한옥 지도·구조물·실내 3종 |
| `illustrations/gye/` | 8 | 2.6MB | 계 커뮤니티 |
| `illustrations/reward/` | 2 | 2.5MB | 보자기 개봉 |
| `data/` | 8 | 1.2MB | 커리큘럼·시나리오 매니페스트 |
| 기타 (`empty`·`onboarding`·`book`·`sfx`·`burst`·`error`·`icons`) | 26 | 5.8MB | |

### 영상 40편 상세 (번들 기준)

**호랑이 12** — `tiger_rise`(홈 히어로 루프)·`tiger_rest`·`tiger_walking_front`·`tiger_choose`·
`tiger_greet_pawflash`·`tiger_celebrate_hifive`·`tiger_roar`·`tiger_sitting2`·
`tiger_stretch`·`tiger_thinking`·`tiger_walking_front`(프로필) — **전부 사용**.
※ 2026-08-06 폐지한 `tiger_anim` 프레임 44장의 역할을 이 12편이 그대로 흡수한다.

**까치 11** — `magpie_bob`·`bob2`·`bob3`(홈 히어로)·`celebrate`·`choose`·`flight`·
`full10`·`greet_chirp`·`perched`·`right_walking_flying`·`worry` — 사용.
`magpie_walking_forward` 는 **미사용**(아래 2절).

**루프 14** — `hanok_construction`·`hanok_jongga`·`kkeunmari_hero`·`listening_hero`·
`porch`·`scene_cafe`·`scene_directions`·`scene_hotel`·`scene_market`·
`scene_restaurant`·`study_classroom`·`study_scholar`·`taego-joy-duo`·`welcome-hero`
— 전부 `HanokHeader.kLoopAssets` 계약으로 고정(테스트가 양방향 대조).

### 동적 참조 7종 (문자열 grep 으로는 안 잡히는 것들)

| 조립 패턴 | 실제 대상 | 근거 |
|---|---|---|
| `stamps/${_assetSlug(motif)}.png` | `stamp_*` 14장 | `DancheongMotif` 14값, `dancheong_stamp_test` 전수 검사 |
| `hanok_stages/stage_${assetSlug}_light.png` | `stage_*_light` 12장 | `HanokStage` 12값 |
| `decorations/$slug.png` | `kAvailableDecorations` 23종 | `decoration_slot_test` 양방향 대조(단, 접두사 필터 구멍 있음) |
| `stickers/$slug.png` | 30장 | `sticker_catalog.dart` 의 `StickerDef` |
| `scenes/$key.png` · `scenes/${s.id}.png` | **11장** | `lib/models/scenario.dart` 의 시나리오→카테고리 맵. `scenarios.json` 이 아니다 — 씬 키는 코드가 정한다 |
| `video/character/*.mp4` | 22편 | `CharacterClips` 상수 + `TigerStageVideo.greetFor/paceFor` |
| `video/loops/*.mp4` | 14편 | `HanokHeader.kLoopAssets` (양방향 검사) |
| `sfx/*` | 11개 | `AssetSource('sfx/x.mp3')` — **`assets/` 접두사 없이** 참조된다 |

---

## 2. 안 쓰이는데 앱에 들어가는 것 — 번들 O · 사용 X (7개 / 8.6MB)

> **2026-08-07 전량 처리 완료. 아래 표는 처리 전 기준이고, 처분은 다음과 같다.**
> 확인 과정에서 이 표의 **판정 오류 3건**도 드러났다 — 원인은 grep 범위를
> `lib/` 로만 잡은 것과, 그 사이 동시 세션이 정리한 것을 반영 못 한 것이다.
>
> | 파일 | 처분 | 근거 |
> |---|---|---|
> | `scenes/pharmacy.png` | ✅ **배선** (`736348b`) | `pharmacy` 씬 카테고리 신설, `pharmacy_headache` 이동 |
> | `decorations/dokkaebi_fire.png` | ✅ **배선** (`5e48fa9`) | `decoration_dokkaebi_fire.png` 로 개명 + `q_dokkaebi_fire` 상시 퀘스트 |
> | `personal_hanok_v2/map/reference_full_estate.png` | 📦 **격리** | `assets_unused/pending_review/` — QA 대조용, 런타임 경로 아님 |
> | `video/character/tiger_magpie_play.mp4` | 📦 **격리** | `assets_unused/pending_review/` — `CharacterClips` 에 없음 |
> | `mascot/joy_magpie_full_960_1.mp4` | ⚠️ **판정 오류 — 이미 없음** | 동시 세션 `5927ae6`(클립 에셋 재배선·통합)에서 정리됨 |
> | `video/character/magpie_walking_forward.mp4` | ⚠️ **판정 오류 — 이미 없음** | 같은 커밋에서 통합. 현재 남은 건 `character_clip.dart:63` 의 설명 주석뿐 |
> | `data/content_audit_manifest.json` | ⚠️ **판정 오류 — 고아 아님** | "참조 0건" 은 틀렸다. `test/content_audit_manifest_test.dart:20` 이 콘텐츠 수량 기준선으로 읽는 살아있는 가드다. 1KB 이므로 그대로 둔다 |
>
> **실제 AAB 절감은 8.6MB 가 아니라 4.2MB** 다(격리 2건). 배선된 2건(2.4MB)은
> 용량이 줄어드는 게 아니라 이미 내던 값이 제 일을 하게 된 것이고, 나머지
> 2MB 는 애초에 이 표가 만들어진 뒤 다른 세션이 이미 치웠다.

**여기가 실제 정리 대상이다.** APK/AAB 용량만 먹고 코드가 부르지 않는다.

| 파일 | 용량 | 왜 안 쓰이나 |
|---|---:|---|
| `illustrations/personal_hanok_v2/map/reference_full_estate.png` | 3.1MB | **완성 QA 대조용 참조 이미지.** 런타임 렌더 경로 아님 — `docs/` 나 `assets_unused/` 로 빼야 한다 |
| `illustrations/scenes/pharmacy.png` | 1.6MB | `lib/models/scenario.dart` 의 씬 카테고리 맵은 11종(airport·cafe·convenience·directions·home·hotel·market·office·restaurant·station·taxi)이고 **pharmacy 는 없다**. 파일만 있고 어떤 시나리오도 이 배경을 고르지 않는다 |
| `illustrations/mascot/joy_magpie_full_960_1.mp4` | 1.3MB | `9ee22ac` 에서 추가됐지만 **배선된 곳이 없다**. `mascot/` 은 정지컷 폴더라 위치도 어긋남 |
| `video/character/tiger_magpie_play.mp4` | 1.1MB | `CharacterClips` 상수에 없음 |
| `illustrations/decorations/dokkaebi_fire.png` | 786KB | `kAvailableDecorations` 화이트리스트에 **없다**. `013ddd9` 가 파일만 추가하고 `placed_decoration.dart` 는 건드리지 않았다 — 추가된 날부터 한 번도 렌더된 적이 없다 |
| `video/character/magpie_walking_forward.mp4` | 675KB | `CharacterClips` 상수에 없음. 홈 인사는 `magpie_right_walking_flying` 을 쓴다 |
| `data/content_audit_manifest.json` | 1KB | 참조 0건 (과거 감사 산출물로 보임) |

> 정리하면 AAB 에서 **약 8.6MB** 가 빠진다. AAB 기기별 다운로드가 190MB/200MB 라
> 여유가 10MB 뿐이므로 무시할 크기가 아니다.

### 왜 이런 게 생기나 — 가드 사각지대

에셋 폴더 22 개 중 **디렉터리를 스캔하는 테스트가 있는 것은 3 개뿐**이다.

| 폴더 | 가드 | 방향 | 결과 |
|---|---|---|---|
| `video/loops` | `character_clip_matte_test.dart:88-89` | **양방향** | 고아 0 개 |
| `video/character` | `character_clip_matte_test.dart:77` | **단방향**(참조→디스크) | 고아 2 개 통과 |
| `illustrations/decorations` | `decoration_slot_test.dart` | 양방향이나 `.startsWith('decoration_')` 필터 | `dokkaebi_fire` 검사 제외 |
| 나머지 19 개 | 없음 | — | 무방비 |

`video/loops` 가 유일하게 고아 0 개인 것은 우연이 아니다 — 양방향 검사가 있는
유일한 폴더다. 이 형태를 전 폴더로 확장하는 것이 근본 대책이다.

---

## 3. 원본·작업 파일 — 번들 X (39개 / 47.4MB)

앱에 **안 들어간다**(pubspec 비재귀 규칙 덕에 자동 제외). 저장소 용량만 차지하므로
그대로 둬도 배포에 영향 없다.

| 디렉터리 | 개수 | 용량 | 성격 |
|---|---:|---:|---|
| `illustrations/scenes/_raw/` | 11 | 14.6MB | 시나리오 배경 원본 |
| `illustrations/stamps/_raw/` | 6 | 12.5MB | 도장 원본 |
| `illustrations/decorations/_raw/` | 6 | 5.8MB | 장식 원본 |
| `illustrations/.asset_intake_2026-08-04/decorations/raw/` | 6 | 5.8MB | 반입 원본 |
| `illustrations/.asset_intake_2026-08-04/decorations/normalized/` | 6 | 4.5MB | 반입 정규화본 (이미 `decorations/` 에 반영됨) |
| `illustrations/.asset_intake_2026-08-04/reward/raw/` | 2 | 2.1MB | 보자기 원본 |
| `illustrations/.asset_intake_2026-08-04/hanok/raw/` | 1 | 1.4MB | 사랑방 배경 원본 |
| `illustrations/mascot/_to_delete/` | 1 | 568KB | 이름 그대로 삭제 예정 |

`.asset_intake_2026-08-04/` 는 반입이 끝나 `decorations/`·`reward/`·`hanok/` 에
정규화본이 들어가 있으므로 **13.8MB 를 통째로 지워도 앱은 영향 없다**(원본 보존이
필요하면 `assets_unused/` 관례를 따를 것).

---

## 4. 별도 — `assets_unused/`

pubspec 에 아예 없는 보관 폴더. `assets_unused/README.md` 가 항목별 이동 사유와
복원법을 관리한다. 2026-08-06 에 `illustrations/tiger_anim/` 44장이 여기로 왔다
(대체 클립 매핑은 그 README 참조).

---

## 재실행

이 문서는 수기 갱신본이다. 판정 기준(번들 × 참조)은 기계적으로 다시 뽑을 수 있으니,
에셋을 크게 손댄 뒤에는 다시 계산해 이 표를 갱신할 것. 동적 조립 경로 7종은 자동
판정이 불가능하므로 위 "동적 참조" 표를 함께 확인해야 한다.
