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

생성 모델은 전체 대지를 완성본으로 납품하지 않는다. 승인 raw 후보는 RGBA PNG의
실제 투명 레이어여야 한다. raw가 socket보다 크면 `tool/compose_hanok_a1_state.py`가
thresholded alpha bbox를 비율 유지 축소해 정확히 854×309인 투명 레이어로 정규화하고,
SHA로 고정된 빈 대지에만 합성한다. 정규화 레이어는 local anchor `(427,309)`에
닿아야 하며 투명 모서리·실제 alpha·chroma 부재를 통과해야 한다. source 합성 단계에서 socket
밖 픽셀은 0개 변경이어야 한다. 최종 lossy WebP는 provenance에 고정한 Pillow
quality 82/method 6으로 만들고 RGB·1536×1152·350,000 bytes와 socket 밖 decode
평균 오차 상한 5.0을 재검증한다.

기단이 처음 완성된 03 다음인 누적 상태 04–16은 직전 승인 normalized layer를
`--previous-layer`로 반드시 넘긴다. 01–03은 집터·평면·새 기단 자체가 단계 변화이므로
이 foundation mask 비교를 적용하지 않고 각 단계의 authored socket/semantic QA를 쓴다.
도구는 socket 아래 80px의 foundation alpha mask를 비교해 IoU 0.94 이상, 좌우
footprint edge drift 12px 이하를 요구한다. 이 gate를 통과하지 못하면 모델이 기단의
폭·위치·scale을 바꾼 것이므로 alpha가 정상이어도 다음 공정으로 승인하지 않는다.

## 생성 모델 입력 allowlist

외부 생성 서비스에는 현재 SHA-256과 파일 metadata가 정본과 일치하는 아래
프로젝트 자산만 입력할 수 있다.

| 역할 | 경로 | 용도 |
|---|---|---|
| 빈 대지 | `assets/illustrations/personal_hanok_v2/map/site_base_light.png` | 표준 입력 |
| 완성 사랑채 | `assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png` | 완성 집 geometry 입력 |
| 완성 전경 QA 합성물 | `assets_unused/pending_review/reference_full_estate.png` | 꼭 필요한 QA 문맥에만 선택적 입력, 런타임 금지 |

경로가 같아도 SHA-256이 달라지면 다시 권리를 확인하고 정본을 갱신하기 전에는
업로드하지 않는다. allowlist에 없는 프로젝트 파일, 사용자 화면, 비바샘,
Gye 자산, legacy 개인 한옥 자산은 기본 거부한다.

승인된 생성 출력에서 다음 누적 공정을 만들거나, 생성기가 잘못 구운 matte만 제거하는
수정 호출은 예외적으로 허용한다. 이때 입력은 반드시 같은 generation ledger의 더 앞선
record가 SHA-고정한 출력이어야 하고, 최초 조상은 위 프로젝트 allowlist까지 끊김 없이
추적되어야 한다. 임의 로컬 파일, 기록되지 않은 URL, 후행 record, SHA가 다른 복사본은
파생 입력으로 인정하지 않는다. rejected 출력은 그 거절 원인만 고치는 한 번의 명시적
수정에 사용할 수 있지만, 결과는 새 record와 새 육안·자동 QA 없이는 승인할 수 없다.

## 생성 기록

모든 생성 호출은 provider, model, UTC 호출 시각, 사용 credit, prompt SHA-256,
입력 경로와 SHA-256, 출력 경로와 SHA-256, 승인·탈락 결정을 기계 판독 ledger에
남긴다. PR4의 A1-06 파일럿은 허용된 프로젝트 자산 두 장만 입력으로 사용해
Nano Banana Pro 2K 세 안을 생성했으며, 총 12 credit을 사용했다. 세 출력 모두
socket 바깥 대지를 다시 그려 `rejected`로 기록했고 런타임에는 포함하지 않는다.
이후 투명 socket 파이프라인에서 A1-05·06·07·08·09 QA 상태를 승인했다. A1-07의 두
Recraft 배경 제거에는 각각 0.3 credit, 합계 0.6 credit을 사용했고 중간 벽선이 있는
첫 결과는 의미상 거절했다. A1-08은 공정 의미를 통과한 ImageGen 출력의 구운
checkerboard만 Recraft 0.3 credit으로 제거했다. A1-09도 공정 의미를 통과한 출력의
checkerboard만 Recraft 0.3 credit으로 제거했다. 현재 BBANANA 정적 ledger 합계는
13.2 credit이다.
추가 생성 전 allowlist와 누적 ledger를 확인하는 것이 fail-closed 시작 조건이다.
ledger는 정적 이미지 200 credit, 선택 영상 10.4 credit, 합계 210.4 credit 상한을
각각 검사한다. 미래 기록도 입력 SHA와 최초 allowlist 또는 이전 ledger 출력까지의
순방향 lineage, canonical UTC, media kind, 호출별 credit, 출력 SHA와 승인 결정을 모두
만족해야 한다.

구조·공정·지붕·공포·마루·창호·문·평면·용도 지식 카드는 텍스트 없는 원본
SVG로 제작한다. 명칭과 설명은 Flutter KO/DE/EN 문자열로 렌더링하고 제3자
화면을 tracing하지 않는다.
