# 살아 있는 한옥 V1 출처·권리 원장

**상태:** active · 2026-08-16
**기계 판독 정본:** `docs/assets/HANOK_V1_ASSET_PROVENANCE.json`

이 원장은 한옥 V1의 사실 확인 자료, 프로젝트 소유 입력 자산, 외부 참고물의
사용 경계를 고정한다. 학습 콘텐츠 수, CourseUnit 수, can-do segment 수 또는
보상 분모를 자산 계약에 연결하지 않는다.

## 사실 확인 자료

| ID | 출처 | 확인 범위 | 앱 반영 방식 |
|---|---|---|---|
| `hanokdb_construction` | 국가한옥센터 `https://www.hanokdb.kr/theology/sub_04` | 터잡기, 설계, 기초, 초석, 치목, 조립, 지붕, 수장·흙벽, 마감, 주변 가꾸기의 공정 | 독립 문구와 독립 도식 |
| `seoul_hanok_structure` | 서울한옥포털 `https://hanok.seoul.go.kr/front/kor/info/infoHanok.do?tab=2` | 기둥·보·도리·서까래와 지역·기후에 따른 구조 차이 | 독립 문구와 독립 도식 |
| `iksi_curriculum` | 온라인 세종학당 `https://www.iksi.or.kr/lms/main/curriculum.do` | 목표·연습·통합 과제·평가라는 교육 구조 | Hangul Sori 고유 학습 루프 |
| `iksi_roadmap` | 누리 세종학당 `https://nuri.iksi.or.kr/front/page/siteguide/learning/roadmap/main.do?language=ko` | 수준별 기능 범위 | 자체 A1–C2 목표와 순서 |
| `ksif_assessment` | 세종학당재단 `https://www.ksif.or.kr/com/cmm/EgovContentView.do?menuNo=20102100` | 네 기능 평가 원칙 | 자체 생산 증거와 rubric |

원문의 문장, 예문, 단원 배열, 이미지와 도식을 복사하지 않는다. 확인한 사실은
중립 brief로 분리한 뒤 원문을 닫고 KO/DE/EN 문구와 학습 활동을 독자 작성한다.

## 사용자 제공 화면과 비바샘

이번 기획에 첨부된 `codex-clipboard-*`, `Screenshot 2026-08-16*.png` 화면과
비바샘 페이지는 모두 다음 경계로만 취급한다.

```text
classification: reference_only_user_supplied
runtime: not_shipped
modelInput: forbidden
copy: forbidden
trace: forbidden
recolor: forbidden
```

앱 번들 포함, crop, 복사, tracing, 재채색, 문구 번역·의역, BBANANA 또는 다른
생성 모델의 reference 업로드를 금지한다. 주제 색인으로만 사용하고 건축 사실은
위 공공기관 자료에서 독립적으로 확인한다.

## 일두고택 현장 사진 묶음 (Jin 제공 2026-08-24)

`ildu_site_photos_jin_2026` — 유튜브 캡처(이음한옥 / 박석문 한옥컨설턴트)와 사진 다수.
위 `reference_only_user_supplied` 경계를 **그대로** 적용한다. BBANANA를 포함한 어떤
생성 모델에도 업로드하지 않았고, 앞으로도 하지 않는다.

여기서 읽어 로스터에 등재한 사실 — 전부 중립 문장으로 재기술했다:

| 사실 | 등재 위치 | 교차확인 |
|---|---|---|
| 안채 좌우 마루 끝 처리가 다르다 | `ildu_anchae.kan.note` | 보고서 보방향 좌 3,800 / 우 4,525㎜ (`measured`) |
| 사랑채 배면 기단이 낮다 | `ildu_sarangchae.rearPodiumMm` | 보고서 p61 배면 245㎜ (`measured`). ⚠ 사랑채는 우물에 면하지 않는다 — 안마당 노출 여부는 도면으로 확정 |
| 시렁 — 처마 밑 대나무 장대에 광주리 보관 | `ildu_anchae.elements` | 사진만 (`documented`) |
| 대청 배면 판문 | `ildu_anchae.elements` | 사진만 (`documented`) |
| 아궁이가 마당 쪽으로 노출 | `ildu_anchae.elements` | 사진만 (`documented`) |
| 우물에 안채·아래채·**곳간채**가 면한다 | `ildu_umul.adjacentBuildings` | 사진만, 방위는 미확정 |
| 곳간채 옆이 바로 중문채 | `ildu_gokganchae.adjacentBuildings` | 사진만 |
| 곳간채는 판벽 지배, 안채·아래채는 회벽 지배 | `ildu_gokganchae.materialNote` | 로스터 기존 기술과 일치 |
| 굴뚝(원통 석조)이 독립해 선다 | `ildu_jungmunganchae.elements` | 사진만, 귀속 채 미정 |
| 중문 통과 시 레벨 변화 | `ildu_jungmunganchae.levelChangeNote` | 사진만, 방향 미확정 |

**사진에 찍힌 현대 설비는 고증 대상이 아니다** — 소화기, 흰 소화배관, 안내판, 전선,
조명기구. 생성 프롬프트의 NOT 목록에 상시 명시한다(모델이 부재로 오독한 전례 있음).

## 프로젝트 소유 자산의 도메인 경계

- `assets/illustrations/gye/**`와 `assets/video/gye/**`는 Gye 런타임에서 계속
  사용할 수 있다. 개인 한옥 V1 런타임과 생성 모델 입력에는 사용할 수 없다.
- `assets/illustrations/hanok_stages/**`는 PR7 원자적 cutover 전까지 현재 앱에
  포함된 superseded 자산이다. PR1에서 `not_shipped`라고 허위 표시하지 않으며,
  한옥 V1 생성 입력과 신규 파생 작업에는 사용하지 않는다.
- 개인 한옥 V1의 런타임 정본은
  `assets/illustrations/personal_hanok_v2/` 아래로 제한한다. QA 합성물은
  `assets_unused/`에 두고 런타임에서 선택하지 않는다.

## 카메라와 A1 상태 계약

카메라는 `personal_map_north_up_oblique_v2`, 1536×1152, 북쪽 위,
좌상단 광원으로 고정한다. 주 건물 socket은 `x=160, y=614, w=854, h=309`,
절대 canvas anchor는 `(587,923)`, z-group은 `22`다.

A1 `01_site_setout`부터 `16_landscape_move_in`까지의 기대 산출물은 같은
카메라로 만든 1536×1152 RGB WebP다. 각 파일은 350,000 bytes 이하여야 하며
텍스트, UI, 캐릭터 라벨, 워터마크를 굽지 않는다. 아직 만들어지지 않은 파일을
PR1에서 존재한다고 기록하지 않고, 기대 파일명과 형식만 provenance 정본에 둔다.

## 생성 모델 입력 allowlist

외부 생성 서비스에는 현재 SHA-256과 파일 metadata가 정본과 일치하는 아래
프로젝트 자산만 입력할 수 있다.

| 역할 | 경로 | 용도 |
|---|---|---|
| 빈 대지 | `assets/illustrations/personal_hanok_v2/map/site_base_light.png` | 표준 입력 |
| 완성 사랑채 | `assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png` | 완성 집 geometry 입력 |
| 완성 전경 QA 합성물 | `assets_unused/pending_review/reference_full_estate.png` | 꼭 필요한 QA 문맥에만 선택적 입력, 런타임 금지 |
| 완성 솟을대문 | `assets/illustrations/personal_hanok_v2/map/structures/sotdaeulmun.png` | 완성 건물 geometry 입력(B1/B2 단계 역분해) |
| 완성 행랑채 | `assets/illustrations/personal_hanok_v2/map/structures/haengrangchae.png` | 완성 건물 geometry 입력(B1/B2 단계 역분해) |
| 완성 안채 | `assets/illustrations/personal_hanok_v2/map/structures/anchae.png` | 완성 건물 geometry 입력(B1/B2 단계 역분해) |
| 완성 대청마루 | `assets/illustrations/personal_hanok_v2/map/structures/daecheongmaru.png` | 완성 건물 geometry 입력(B1/B2 단계 역분해) |
| 완성 사당 | `assets/illustrations/personal_hanok_v2/map/structures/sadang.png` | 완성 건물 geometry 입력(B1/B2 단계 역분해) |
| 완성 후원 | `assets/illustrations/personal_hanok_v2/map/landscape/rear_garden.png` | 완성 조경 geometry 입력(B1/B2 단계 역분해) |

경로가 같아도 SHA-256이 달라지면 다시 권리를 확인하고 정본을 갱신하기 전에는
업로드하지 않는다. allowlist에 없는 프로젝트 파일, 사용자 화면, 비바샘,
Gye 자산, legacy 개인 한옥 자산은 기본 거부한다.

## 생성 기록

모든 생성 호출은 provider, model, UTC 호출 시각, 사용 credit, prompt SHA-256,
입력 경로와 SHA-256, 출력 경로와 SHA-256, 승인·탈락 결정을 기계 판독 ledger에
남긴다. 현재 PR4 코드 파이프라인은 생성 결과를 runtime에 넣지 않으므로
`records`는 빈 배열이다. 실제 생성 전 이 빈 배열과 allowlist를 확인하는 것이
fail-closed 시작 조건이다. 이후 승인된 ledger 출력 SHA만 다음 레이어의 파생
입력이 될 수 있다. ledger는 정적 이미지 200 credit, 선택 영상 10.4 credit,
합계 210.4 credit 상한을 각각 검사한다.

A1 합성은 전체 대지를 모델로 편집하지 않는다. 모델 출력은 투명 socket 레이어만
허용하고, `tool/compose_hanok_a1_state.py`가 정본 `site_base_light.png`에
결정론적으로 합성한다. 이전 승인 레이어와 footprint recall/edge drift가 깨지면
다음 단계를 승격하지 않는다. 16개 QA WebP가 모두 통과하기 전에는
`tool/promote_hanok_a1_states.py`가 runtime/pubspec을 열지 않는다.

**누적 stack 모드 (2026-08-17).** 생성 모델은 전 단계 구조를 다시 그리며 흔들린다
(Codex A1-06→07은 기둥이 얇아져 recall 0.858). `--stack-on-previous`는 승인된 직전
레이어의 픽셀을 전부 그대로 두고, 후보는 "직전 레이어가 투명하고 직전 상단보다 위
(+`--stack-margin-px`, 기본 8px)"인 곳에서만 받는다. 아래쪽에 다시 그린 중복 기둥은
버려지고, recall 1.0·drift 0은 구성상 보장된다. 위로 쌓이는 공정(05–11)에 쓰고, 벽·바닥·
창호처럼 구조 안쪽을 채우는 12–16은 별도 규칙이 정해질 때까지 기본 검사만 쓴다.

**Codex A1 파일럿 기록 (2026-08-17, 병합 `9958a458`).** 병렬 로컬 브랜치
`codex/hanok-v1-a1-assets-20260817`(`aaf6d969`)이 A1-05~10의 raw·정규화 레이어·
QA WebP를 `assets_unused/pending_review/a1_layers/`·`a1_states/`에 만들었고,
BBANANA/Nano Banana Pro·ImageGen·Recraft 호출 19건, 정적 13.5 credit을 자체
ledger에 남겼다. 그 브랜치의 렌더러·합성기·checker·테스트·provenance JSON은
위 PR4 계약과 별개 구현이라 병합 시 `main` 버전을 유지했고, ledger 19건과
`a1TransparentPilot`·`a1ApprovedQaStates` 절은 `aaf6d969:docs/assets/HANOK_V1_ASSET_PROVENANCE.json`
에서 그대로 복구할 수 있다. 이 JSON의 `records`는 그래서 아직 빈 배열이다.
그 19건 중 11건은 credit 0(ImageGen 등 BBANANA 밖 호출), 9건은 rejected 출력을
입력으로 쓴 수정 호출, 3건은 출력이 외부 Supabase URL이라 트리에서 SHA 검증 불가,
1건은 출력이 비어 있어 "credit > 0·approved lineage·트리 검증"을 모두 만족하는 기록은
0건이다(2026-08-17 재집계; 앞선 "4건"은 오기).

**결정 (2026-08-17, Jin): 19건을 이관하지 않는다. 계약도 완화하지 않는다.** 근거는 둘이다.
① **이관해도 승격이 열리지 않는다.** `tool/promote_hanok_a1_states.py`가 부르는
`tool/hanok_v1_asset_contract.py`의 `a1_approved_state_digests()`는 ledger 출력 중
**basename이 16개 기대 `NN_*.webp` 중 하나이고 `decision == "approved"`인 것만** 집계한다.
19건의 출력은 전부 raw/rejected PNG이거나 외부 URL이라 이 필터에서 탈락하므로, 옮겨도
`--apply`는 여전히 거부되고 approved 집합만 오염된다.
② **05~10 계보 자체가 교체된다.** Codex 06이 앞줄 기둥 7개만 그려 07~10에 뒷줄·옆보가 없고,
완성 사랑채는 앞기둥 8개(7칸)라 칸수도 어긋난다. 옛 승인 6건은 어차피 효력이 없다.
13.5 credit 지출의 감사 증적은 `aaf6d969` 커밋과 이 절로 충분하다. 새 계보에서 게이트를
통과한 QA WebP의 SHA만 그때 `approved`로 새로 적는다.

pending_review의 6개 상태는 승격이
아니며, 승격 전에 `tool/compose_hanok_a1_state.py`로 raw를 다시 합성해 recall 0.97·
drift 2px 게이트를 통과한 SHA만 ledger에 `approved`로 적는다.

구조·공정·지붕·공포·마루·창호·문·평면·용도 지식 카드는 텍스트 없는 원본
SVG로 제작한다. 명칭과 설명은 Flutter KO/DE/EN 문자열로 렌더링하고 제3자
화면을 tracing하지 않는다.
