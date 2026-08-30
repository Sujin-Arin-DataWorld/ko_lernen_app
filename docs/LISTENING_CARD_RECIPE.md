# 듣기 카드 확정 레시피 (2026-08-17, Jin 승인)

> **⛔ 범위(2026-08-30 lock):** 이 레시피는 듣기 카드만이 아니라 정물 카드 계열 전체
> (`packs/` 14 · `activities/` · `listening/`)의 생성 정본이다. 이 계열의 새 이미지는
> 예외 없이 이 문서의 고정 프롬프트({SUBJECT}만 교체)·후처리·검수로만 만든다. 실측
> 불변값(팔레트·그레인 대역·정본 해시)은 `docs/assets/STYLE_LOCK.json` families
> `F-E-cards` 가 정본이며 수치가 충돌하면 그쪽이 이긴다. 픽셀 게이트:
> `tool/check_card_style.py` (후처리 스크립트가 자동 실행; 실패 = 번들 금지).
> `docs/ASSET_GENERATION_BIBLE.md` §1.2-3(면내 그라데이션 금지)은 이 계열에 적용
> 금지 — 적용하면 평면 벡터가 나온다(2026-08-30 C1/C2 23장 전량 폐기 실측).

이 문서 하나로 다음 세션이 첫 장부터 같은 품질을 뽑는다.
**정본 샘플**: `assets/illustrations/packs/plum.webp`(화풍 제1정본 — Jin 2026-08-30) ·
`assets/illustrations/packs/bamboo.webp`(원조·현행 생성 앵커) ·
`assets/illustrations/listening/A1Arrival.webp`(한지 질감 정본).
새 카드를 뽑기 전에 이 석 장을 반드시 눈으로 열어볼 것.

## 생성 파라미터

| 항목 | 값 |
|---|---|
| 플랫폼 | BBANANA MCP |
| 모델 | **Seedream V4.5** (Nano Banana Pro 아님) |
| resolution | **2K** — 1K 는 디테일이 뭉개진다 |
| aspect_ratio | `4:3` |
| image_urls (앵커) | `docs/assets/STYLE_LOCK.json` families `F-E-cards`.`anchorImageUrl` 한 곳이 정본 (현행 bamboo 업로드본 — plum 교체는 Jin 미결, 임의 변경 금지). |
| 비용 | 장당 1~2크레딧 |

앵커 URL 이 죽으면 `packs/bamboo.webp` 를 `upload_image` 로 다시 올리고 STYLE_LOCK 의 `anchorImageUrl` 한 곳만 갱신한다.

## 프롬프트 (`{SUBJECT}` 만 교체, 나머지 한 글자도 바꾸지 말 것)

```
Create a NEW illustration in exactly the same illustrated-set style as the reference image
(same geometric faceted background diamonds, same hanji cream palette, same paper grain,
same dancheong dot clusters, same flat no-outline planes), but with this subject instead:
{SUBJECT}. COMPOSE IT EXACTLY LIKE THE REFERENCE: the objects form a small quiet still-life
group resting in the LOWER portion of the frame, taking up only about one third of the image
height, with generous empty cream space above them. Soft muted desaturated colours and gentle
soft shading exactly like the reference — absolutely NO black outlines, NO ink linework, NO
drawn contours around any object. EVERY colour plane carries a subtle hanji paper-fibre grain
and slight tonal variation across it — never a perfectly flat digital fill; object edges are
very slightly irregular, like shapes printed on handmade paper, not machine-straight vectors.
Keep the cream diamond-faceted background — do NOT draw a full room or landscape.
ABSOLUTELY AVOID: outlines, cute style, animals, people, hands, arms, fingers, readable text
or letters, 3D render, photorealism. This must look like part of the same illustrated set as
the reference image.
```

`{SUBJECT}` 은 **짧게, 사물 2~3개**. 한 문장을 넘기면 모델이 "설명 삽화" 모드로 빠져 검은
윤곽선이 생긴다. 좋은 예: `a stethoscope and a small prescription clipboard lying on a
consultation desk, with an empty chair behind the desk`.

## 질감 규약 (Jin 2026-08-17 — `A1Arrival` 이 정본)

- 색면 안에 **한지 섬유 결**이 보여야 한다. 매끈한 단색 채움 = 실패.
- 직선·모서리가 자로 그은 듯 반듯하면 안 된다. 손으로 찍은 인쇄물처럼 미세하게 흔들려야 한다.
- 생성 단계 문구 + `scripts/apply_paper_grain.py` 후처리 **둘 다** 있어야 이 느낌이 나온다.
  후처리만으로는 부족하고, 프롬프트만으로도 부족하다.

## 실패 원인 (전부 이번 세션 실측 — 되풀이 금지)

| 증상 | 원인 | 교정 |
|---|---|---|
| 검은 윤곽선, 초등학생 그림체 | 소재 설명이 길고 구체적 | `{SUBJECT}` 를 사물 2~3개 짧은 구로 |
| packs 특유의 여백감 소실 | 사물을 화면 중앙에 크게 배치 | "LOWER portion, one third, generous empty cream space above" 문구 유지 |
| 디테일 뭉개짐 | 1K 해상도 | 반드시 `resolution: 2K` |
| 손·팔이 튀어나옴 | 금지 목록에 hands 누락 | `hands, arms, fingers` 항상 포함 |
| 이미지 안에 글자 | 금지 목록에 letters 누락 | `readable text or letters` 항상 포함. 예외는 Jin 이 명시할 때만(예: `B1Insurance` 의 "INSURANCE") |
| 벽돌 패턴이 배경에 등장 | 프롬프트에 `brick-red` 사용 | 색은 `vermilion red` 로 표기 |
| 카드가 무슨 카테고리인지 안 읽힘 | 은유적 소재(저울·두루마리 등) | 누구나 아는 **실물**로. 배송=문 앞 택배 상자, 지연=역 시계+전철, 계약=서명란 있는 계약서+펜 |
| 장소가 어딘지 안 읽힘 | 도구만 그림(청진기·서류) | **장소 표식을 크게 하나** 넣는다. 병원=벽에 걸린 적십자 간판, 관공서=번호표 기계 |

## 후처리 (필수)

```
finish.sh {key} {url}
  → curl 다운로드 → sips -Z 800 → apply_paper_grain.py(fine 5.0 / coarse 4.0)
  → cwebp -q 84 → assets/illustrations/listening/{key}.webp
```

산출물 크기 85~105KB 가 정상(그레인이 엔트로피를 올린다). 기존 packs/activities 39장과 같은 계약.
하드 게이트는 STYLE_LOCK `gates.fileKB` (전수 실측 기반, 대략 65~110KB) — 85~105KB 는
그레인 신규 카드의 정상 대역이고, 게이트 대역 밖이면 번들 자체가 차단된다.
`scripts/apply_paper_grain.py` 는 저장소에 있고, venv 는 `.grain-venv`(pillow·numpy, gitignore됨).

## 검수 체크리스트 (번들 전 매 장)

1. 검은 윤곽선이 없는가
2. 사물이 아래 1/3, 위가 비어 있는가
3. 색면에 한지 결이 보이는가 (매끈하면 탈락)
4. 배경 아이보리·모서리 삼각(적/적/청)이 원본과 같은가
5. 글자·손·사람이 없는가
6. **100px 썸네일로 줄여도 무슨 카테고리인지 읽히는가**

여섯 개 다 통과해야 번들. 하나라도 걸리면 재생성한다.

## 진행 상황 (2026-08-30 기준)

번들 완료 **75장 — 코드가 요구하는 75키 전부 충족** (2026-08-30 저녁) —
A1 12/12 · A2 12/12 · B1 12/12 · B2 12/12 · C1 12/12 · C2 12/12 · Social 3/3.
C1/C2 22장은 이 레시피 그대로(Seedream V4.5 · bamboo 앵커 · {SUBJECT}만 교체) 생성했고
전량 `tool/check_card_style.py` 게이트 통과 후 반입됐다. 재생성 사례(다음 세션 참고):
`{SUBJECT}` 의 "seal"은 물개로, "marked ruler"는 숫자 눈금으로, "consent letter"는
실제 글자로 오역된다 — **stone stamp block · unmarked/plain · blank envelope** 로 쓸 것.

남은 작업:
- 신규 6칸 중 뒤 3개(숫자와 시간·전화&메시지·길과 표지판)는 `A1Numbers` `A1Phone`
  `A1Wayfinding` 와 중복이므로 교체할지 별도 레벨로 둘지 여전히 Jin 확인 필요(미해결).

크레딧 잔액 약 27 (2026-08-30 저녁 실측 — 22장 본생성 + 9장 재생성 = 31크레딧 소요).

## 코드 배선 (아직 안 함)

듣기 화면은 아직 알약 리스트다. 카드 그리드 전환이 남아 있다:

| 파일 | 변경 |
|---|---|
| `lib/screens/listening_library_view.dart` | 알약 리스트 → `SoriIllustratedCard` 그리드 (Spiele 탭과 동일 구조) |
| `pubspec.yaml` | `- assets/illustrations/listening/` 등록 |
| `test/asset_orphan_guard_test.dart` | `dynamicDirs` 에 `'assets/illustrations/listening/': 'illustrations/listening/'` 추가 |

이미지에는 `errorBuilder` 폴백을 단다(자산 없어도 화면이 뜨게 — `PackCard` 와 같은 규약).

## 행동 계약 (모든 세션 필수 — 2026-08-30 lock)

1. 이 계열 작업은 이 문서를 처음부터 끝까지 읽은 뒤 시작한다. 프롬프트를 새로 쓰지 않는다 —
   `{SUBJECT}` 만 바꾼다.
2. 스타일을 다른 문서(BIBLE·ART_SPEC 프롬프트 골격·핸드오프)에서 재유도하지 않는다.
3. 생성 전 정본 석 장(plum·bamboo·A1Arrival)을 연다. 생성 후 정본과 나란히 놓고 검수
   체크리스트 + 픽셀 게이트(`tool/check_card_style.py`)를 통과해야 번들.
4. 앵커·팔레트·그레인 수치 변경은 Jin 승인 + STYLE_LOCK 갱신이 먼저다 — 문서 여러 곳을
   따로 고치는 순간 드리프트가 시작된다.
