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

생성 모델은 전체 대지를 완성본으로 납품하지 않는다. 승인 후보는 먼저 정확히
854×309인 RGBA PNG 투명 레이어여야 하고, `tool/compose_hanok_a1_state.py`가
SHA로 고정된 빈 대지에만 합성한다. 레이어는 local anchor `(427,309)`에 닿아야 하며
투명 모서리·실제 alpha·chroma 부재를 통과해야 한다. source 합성 단계에서 socket
밖 픽셀은 0개 변경이어야 한다. 최종 lossy WebP는 provenance에 고정한 Pillow
quality 82/method 6으로 만들고 RGB·1536×1152·350,000 bytes와 socket 밖 decode
평균 오차 상한 5.0을 재검증한다.

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

## 생성 기록

모든 생성 호출은 provider, model, UTC 호출 시각, 사용 credit, prompt SHA-256,
입력 경로와 SHA-256, 출력 경로와 SHA-256, 승인·탈락 결정을 기계 판독 ledger에
남긴다. PR4의 A1-06 파일럿은 허용된 프로젝트 자산 두 장만 입력으로 사용해
Nano Banana Pro 2K 세 안을 생성했으며, 총 12 credit을 사용했다. 세 출력 모두
socket 바깥 대지를 다시 그려 `rejected`로 기록했고 런타임에는 포함하지 않는다.
추가 생성 전 allowlist와 누적 ledger를 확인하는 것이 fail-closed 시작 조건이다.
ledger는 정적 이미지 200 credit, 선택 영상 10.4 credit, 합계 210.4 credit 상한을
각각 검사한다. 미래 기록도 입력 SHA와 allowlist, canonical UTC, media kind,
호출별 credit, 출력 SHA와 승인 결정을 모두 만족해야 한다.

구조·공정·지붕·공포·마루·창호·문·평면·용도 지식 카드는 텍스트 없는 원본
SVG로 제작한다. 명칭과 설명은 Flutter KO/DE/EN 문자열로 렌더링하고 제3자
화면을 tracing하지 않는다.
