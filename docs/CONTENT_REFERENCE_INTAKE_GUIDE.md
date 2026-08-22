# 외부 참고 자료 판독과 콘텐츠 자산화 작업지침서

> **상태:** 콘텐츠 수집 정본, 2026-08-16
>
> 이 문서는 PDF, 스캔 이미지, 표, OCR 결과에서 교육 설계 신호를 확인하되 제3자 표현을
> Hangul Sori 학습 본문에 유입시키지 않고, 기존 콘텐츠 ID와 커리큘럼 계약에 정확히 맞는
> 독립 작성 데이터를 만드는 절차를 고정한다. 실제 문장과 게임 스키마는
> `CONTENT_AUTHORING_GUIDE.md`, 권리 경계는 `CONTENT_SOURCE_POLICY.md`, 코드 검증은
> `tools/content_factory/validate_content.py`가 최종 기준이다.

## 1. 결과물과 절대 경계

참고 자료 판독과 앱 콘텐츠 작성은 한 작업처럼 보여도 서로 다른 두 구역이다.

| 구역 | 허용 위치 | 들어갈 수 있는 것 | 들어가면 안 되는 것 |
| --- | --- | --- | --- |
| 참고 자료 격리 구역 | `tools/content_factory/reference_intake/`와 커밋하지 않는 임시 폴더 | 파일 식별자, 해시, 쪽수, 추출 방식, 판독 품질, 일반화한 교육 신호 | 앱 문장, 번역, 문제, 정답, source 순서를 보존한 목록 |
| 독립 작성 구역 | `content_briefs.csv`, `seed_bundle_plan.csv`, `drafts/`, `review/` | 제품 공백, 기존 live ID, 새 독립 문장, 파생 관계, 승인 상태 | PDF 파일명, source ID, 쪽수, OCR 원문, 표 셀, 원문 요약 |

다음 규칙은 예외가 없다.

1. PDF, OCR, 페이지 이미지, 추출 Markdown은 생성 프롬프트, draft, review, app asset에 넣지 않는다.
2. 참고 자료의 단원 순서, 어휘 묶음, 예문 관계, 문제 흐름을 그대로 brief로 옮기지 않는다.
3. 작성자는 `content_briefs.csv`만 보고 새 한국어 원문을 독립 집필한다.
4. 새 데이터는 기존 `courseUnitId`, `conceptIds`, vocab ID, grammar ID를 먼저 확인한 뒤 쓴다.
5. 승인 전에는 `assets/data/`, 실제 TTS, Firebase, 앱 UI를 변경하지 않는다.
6. exact 또는 near-match 대조용 추출 텍스트는 로컬 임시 파일로만 만들고 커밋하지 않는다.

## 2. 전체 처리 흐름

한 자료 묶음은 아래 8개 게이트를 순서대로 통과한다.

1. **기준점 고정:** 최신 `main` SHA와 live 콘텐츠 수량을 기록한다.
2. **인벤토리:** 파일명, SHA-256, 쪽수, 중복 관계, 권리 상태만 `source_inventory.csv`에 기록한다.
3. **추출 모드 판정:** text, mixed, image 중 하나로 분류한다.
4. **페이지 감사:** 텍스트 추출과 실제 렌더를 함께 확인하고 `page_audit.csv`에 수치와 판정만 남긴다.
5. **중립 관찰:** 표현을 제거한 교육 기능 신호만 `reference_observations.csv`에 적는다.
6. **clean-room brief:** source와 페이지 정보를 완전히 제거하고 제품 공백 중심의 `content_briefs.csv`를 만든다.
7. **동기화 계획:** 사용할 live ID와 새 draft ID를 `seed_bundle_plan.csv`에 고정한다.
8. **독립 작성과 검수:** schema-complete draft, review 원장, preview validator, Jin 승인, 승인 통합 순으로 진행한다.

앞 단계가 실패하면 뒤 단계로 넘어가지 않는다. 특히 4번의 OCR 성공은 6번의 콘텐츠 사용
허가가 아니다. 판독 가능성과 이용 가능성은 별개다.

## 3. 세션 시작 체크

새 세션은 작업 전에 다음을 수행한다.

```bash
git fetch origin main
git rev-parse origin/main
python3 tools/content_factory/validate_content.py --json
python3 tools/content_factory/validate_reference_intake.py
```

그리고 다음 파일을 전부 읽는다.

1. `AGENTS.md`
2. `docs/CONTENT_AUTHORING_GUIDE.md`
3. `docs/CONTENT_SOURCE_POLICY.md`
4. 이 문서
5. `tools/content_factory/reference_intake/README.md`
6. 대상 batch manifest와 관련 draft, review 원장

웹사이트나 다른 기능 커밋이 `main`에 추가됐더라도 콘텐츠 이력으로 오해하지 않는다. 항상
최신 `main`에서 새 `agent/content-*` 브랜치를 만들고 콘텐츠 변경만 포함한다.

## 4. PDF와 표 판독 규칙

### 4.1 추출 모드 분류

| 값 | 판정 | 필수 확인 |
| --- | --- | --- |
| `text` | 대부분의 본문이 선택 가능한 텍스트 레이어로 존재 | 앞, 중간, 뒤 표본 페이지의 추출문과 렌더가 일치하는지 확인 |
| `mixed` | 텍스트와 이미지형 표 또는 스캔 페이지가 섞임 | 일반 추출과 페이지 렌더를 함께 확인하고 누락된 표 영역 표시 |
| `image` | 본문 또는 표가 이미지이며 일반 추출 결과가 거의 없음 | 페이지 렌더 또는 Library 판독을 필수로 사용하고 OCR 필요 표시 |

파일의 제목과 전체 쪽수만 확인하고 `text`로 판정하지 않는다. 최소한 앞부분, 중간 부분,
뒷부분을 표본으로 본다. 페이지마다 추출 방식이 바뀌면 파일 전체는 `mixed`로 기록한다.

### 4.2 표와 스캔 이미지 확인

표는 일반 PDF 텍스트 추출에서 열 순서가 섞이거나 셀 전체가 사라질 수 있다. 다음 신호가
하나라도 있으면 렌더 확인이 필수다.

- 텍스트 행 수가 비정상적으로 적다.
- 제목만 나오고 본문이 없다.
- 같은 페이지에 이미지 object가 많다.
- 렌더에는 표가 보이는데 추출문에는 셀 내용이 없다.
- 페이지 번호는 연속인데 추출 내용이 여러 쪽 비어 있다.

Library 페이지 판독과 로컬 렌더를 함께 쓸 때는 서로를 대체하지 않는다. Library는 이미지형
본문의 존재와 대략적 구조를 확인하고, 로컬 렌더는 표, 칸, 병합 셀, 각주와 시각적 누락을
확인한다. `page_audit.csv`에는 원문을 쓰지 않고 행 수, 이미지 수, 표 존재 여부, 신뢰도,
추가 시각 검수 필요 여부만 기록한다.

### 4.3 OCR 임시 산출물

OCR 원문, 페이지 PNG, 표 셀 덤프, 추출 Markdown은 다음 조건을 모두 지킨다.

- 작업 전용 임시 디렉터리에 둔다.
- 저장소에 추가하지 않는다.
- 파일명이나 로그에 인증 정보 또는 개인 정보를 넣지 않는다.
- 중복 검사와 판독 품질 확인이 끝나면 삭제한다.
- 콘텐츠 작성 세션에 전달하지 않는다.

OCR 오류를 사람이 보정해 원문 복제본을 만드는 작업은 하지 않는다. 필요한 것은 자료의
표현 복원이 아니라 페이지가 image형인지, 표가 누락됐는지, 어떤 일반 학습 기능이 반복되는지에
대한 감사다.

## 5. 수집 데이터베이스 5종

모든 CSV는 UTF-8, comma-separated, LF newline로 저장한다. 헤더와 열 순서는 API이므로
임의로 번역, 추가, 삭제, 재배열하지 않는다. 값에 쉼표나 큰따옴표가 있으면 정상 CSV quoting을
사용한다.

### 5.1 `source_inventory.csv`

한 행은 실제 파일 하나다. 실질 중복 파일도 삭제하지 않고 별도 행으로 남긴 뒤
`duplicate_of`와 같은 `content_group_id`로 묶는다.

| 열 | 계약 |
| --- | --- |
| `source_id` | `ref####` 형식의 안정 ID |
| `file_name` | 파일 식별용 이름, 학습 draft에는 전달 금지 |
| `sha256` | 정확히 64자리 소문자 hex |
| `page_count` | 1 이상의 정수 |
| `content_group_id` | 실질 내용 단위 ID, 중복 사본은 동일 값 |
| `duplicate_of` | 원본 `source_id` 또는 빈 값 |
| `text_layer_mode` | `text`, `mixed`, `image` |
| `ocr_required` | `yes` 또는 `no` |
| `library_page_review` | `yes` 또는 `no` |
| `local_render_review` | `yes` 또는 `no` |
| `rights_status` | `reference_only`, `licensed`, `owned`, `public_domain`, `unknown` |
| `allowed_use` | `coverage_audit_only`, `licensed_transform`, `original_source` |
| `review_status` | `inventory_only`, `sampled`, `fully_audited`, `blocked` |
| `last_reviewed` | `YYYY-MM-DD` |
| `notes` | 짧은 운영 메모, 원문 문장 금지 |

### 5.2 `page_audit.csv`

한 행은 연속된 표본 페이지 범위와 한 판독 방법이다. 같은 페이지를 Library와 로컬 렌더로
각각 확인했으면 별도 행을 만들 수 있다.

| 열 | 계약 |
| --- | --- |
| `audit_id` | `audit_<source_id>_####` |
| `source_id` | inventory에 존재하는 ID |
| `page_start`, `page_end` | 1 이상의 정수, 시작은 끝보다 크지 않음 |
| `method` | `pdf_text`, `library_page_read`, `local_render`, `combined` |
| `text_line_count` | 판독된 줄 수, 모르면 빈 값 |
| `page_image_count` | 확인한 page image 수, 모르면 빈 값 |
| `table_detected`, `layout_detected` | `yes`, `no`, `unknown` |
| `extraction_confidence` | `high`, `medium`, `low`, `none` |
| `visual_review_required` | `yes` 또는 `no` |
| `audit_status` | `sampled`, `complete`, `needs_followup`, `blocked` |
| `notes` | 추출 상태 메모, 원문과 표 셀 금지 |

### 5.3 `reference_observations.csv`

원자료를 본 세션만 작성한다. 한 행은 보호 표현을 제거한 하나의 일반 교육 신호다.

| 열 | 계약 |
| --- | --- |
| `observation_id` | `obs_####` |
| `source_id`, `audit_id` | 근거 추적용, 이 파일 밖으로 전달 금지 |
| `observation_type` | `coverage_gap`, `interaction_pattern`, `skill_progression`, `layout_risk`, `language_fact` |
| `neutral_signal` | 180자 이하의 일반화된 기능 설명, 문장·제목·목록 복제 금지 |
| `cefr_candidate` | `A1`부터 `C2` 또는 `UNSET` |
| `skill_axis` | `listening`, `reading`, `speaking`, `writing`, `interaction`, `mediation`, `form` |
| `interaction_mode` | 일반화한 활동 방식, source 고유 지시문 금지 |
| `register_hint` | `casual`, `polite`, `business`, `mixed`, `unset` |
| `grammar_fact` | 개별 언어 사실 하나 또는 빈 값 |
| `confidence` | `high`, `medium`, `low` |
| `rights_gate` | `pass_fact_only`, `pass_abstract_only`, `blocked` |
| `status` | `candidate`, `accepted`, `rejected` |

`reference_observations.csv`는 콘텐츠 생성 입력이 아니다. 다음 단계에서 source 추적 열을 제거하고
제품 자체 요구로 다시 정의해야 한다.

### 5.4 `content_briefs.csv`

이 파일이 독립 작성자가 볼 수 있는 유일한 기초 brief다. 다음 열만 허용하며 source, book,
file, page, OCR 관련 열은 금지한다.

| 열 | 계약 |
| --- | --- |
| `brief_id` | `brief_<level>_<slug>` |
| `level` | 대문자 CEFR |
| `domain` | 제품이 새로 정한 일반 상황 |
| `communicative_goal` | 학습자가 실제로 달성할 한 가지 목적 |
| `learner_outcome` | 관찰 가능한 can-do 문장 |
| `register` | scenario canonical register |
| `relationship_context` | snake_case 관계 |
| `interaction_mode` | scenario, smalltalk, cloze, satz, pronunciation 등을 `|`로 구분한 값 |
| `grammar_targets` | live grammar ID, `|`로 구분 |
| `game_targets` | 만들 게임 유형, `|`로 구분 |
| `course_unit_id` | 같은 level의 live unit ID |
| `concept_ids` | live concept ID, `|`로 구분 |
| `priority` | `P0`, `P1`, `P2` |
| `gap_evidence` | 앱 내부 count와 coverage 공백만 기술 |
| `rights_basis` | 새 항목은 `original_clean_room` |
| `status` | `draft`, `ready`, `used`, `retired` |

### 5.5 `seed_bundle_plan.csv`

한 행은 한 brief에서 만들 콘텐츠 묶음이다. 이 표는 데이터 간 참조를 작성 전에 고정해
draft와 기존 자산이 어긋나는 것을 막는다.

| 열 | 계약 |
| --- | --- |
| `seed_id` | `seed_<level>_<slug>` |
| `brief_id`, `level` | brief와 정확히 일치 |
| `course_unit_id`, `concept_ids` | live curriculum과 정확히 일치 |
| `vocab_ids`, `grammar_ids` | live 또는 같은 승인 transaction의 ID |
| `scenario_ids`, `scenario_quest_ids` | 새 안정 ID, `|`로 구분 |
| `smalltalk_ids`, `cloze_ids`, `satz_ids`, `pronunciation_ids` | 만들지 않으면 빈 값, 만들면 예약 ID |
| `canonical_scenario_id`, `canonical_dialog_turn` | 모든 파생 게임이 공유할 scenario와 1-based 대화 turn |
| `scenario_count`, `scenario_quest_count`, `smalltalk_count`, `cloze_count`, `satz_count`, `pronunciation_count` | 예약 ID 개수와 정확히 일치하는 정수 |
| `course_exposure` | 각 게임 loader가 어떤 curriculum map 또는 exact-level route로 노출하는지 기록 |
| `derivation_contract` | 어떤 canonical KO 문장에서 어떤 게임이 파생되는지 간단히 기록 |
| `review_status` | 처음에는 `draft`, Jin 승인 뒤 `approved` |

## 6. 기존 데이터와 100% 동기화하는 방법

여기서 100% 동기화란 번역 문구가 비슷하다는 뜻이 아니라 모든 참조가 현재 정본에 존재하고,
한 원문을 바꾸면 모든 파생 데이터가 함께 바뀌며, validator가 전체 asset overlay를 통과한다는
뜻이다.

### 6.1 작성 전 고정할 값

- 최신 `main` SHA
- live asset별 record count
- 대상 level의 `courseUnitId`와 `requiredConceptIds`
- 사용할 vocab ID와 정확한 한국어 표제어
- 사용할 grammar ID와 정확한 pattern
- 새 ID의 전역 중복 여부
- scenario backdrop category
- review 원장의 행 순서와 draft의 record 순서

### 6.2 canonical sentence 파생 계약

같은 학습 목표에서 여러 게임을 만들 때 한국어 원문을 따로 다시 쓰지 않는다.

1. scenario dialog 또는 live vocab `example_korean` 중 하나를 canonical KO로 정한다.
2. Cloze는 그 문장에서 답 하나만 `＿＿＿` 또는 해당 schema의 blank token으로 바꾼다.
3. Satzbau `targetKo`는 canonical KO와 정확히 같게 둔다.
4. scenario의 받아쓰기 `targetKo`와 듣기 `audioKo`도 같은 문장을 재사용한다.
5. standalone pronunciation `ko`, Cloze `fullKo`, Satzbau `targetKo`에는 씨앗당 정확히
   하나의 canonical 파생 레코드를 두고 `canonicalScenarioId`로 연결한다.
6. DE/EN는 canonical KO의 같은 의미를 유지한다.
7. canonical KO가 바뀌면 모든 파생 field와 review projection을 같은 변경에서 갱신한다.

### 6.3 병합 전 필수 검사

```bash
python3 tools/content_factory/validate_reference_intake.py
python3 tools/content_factory/validate_content.py --json
python3 tools/content_factory/sync_review_ledgers.py
python3 tools/content_factory/audit_game_loader_coverage.py
python3 tools/content_factory/audit_game_loader_coverage.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json
python3 tools/content_factory/integrate_scenario_batch.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json
```

마지막 두 명령은 batch 유형에 맞는 것만 실행한다. 기본 preview는 repository source를 쓰지
않아야 한다. `--apply`는 Jin이 review 원장의 모든 행을 승인하고 명시적으로 요청한 뒤에만
실행한다.

## 7. 게임 데이터 우선순위

현재 live baseline의 레벨별 공백은 raw count와 실제 loader 노출을 함께 판단한다.
`audit_game_loader_coverage.py`가 direct library, listening fallback, pronunciation 누적 노출,
course unit 연결과 round 부족량을 같은 계산에서 보고한다. 2026-08-16의 확정 계산과 다음
작업량은 `CONTENT_LOADER_GAP_AND_PDF_WORK_PLAN_2026-08-16.md`가 정본이다.

Batch 01–19의 manifest 추적 ID는 2026-08-22 전수 감사에서 live asset과 일치했다. 다음
미사용 번호는 20이다. Batch 06 pilot의 원래 수는 레벨마다
scenario 1개·scenario quest 5개·Smalltalk 2개·Cloze 4개·Satzbau 6개·pronunciation 4개였다.
합계는 standalone record 68개와 scenario 안의 quest 20개다. 이 수는 full-bundle 회귀
표본으로만 읽고, 다음 배치에 같은 수를 모든 seed에 반복하지 않는다. 다음 배치는 loader
공백만 채운다.

1. C1/C2 scenario exact-level 보유를 각 8개까지 올리고, 아직 scenario 0인 unit을 먼저 채운다.
2. C1/C2 Smalltalk는 22 category마다 최소 2개가 되도록 부족한 38개와 37개를 작성한다.
3. B1/B2 Cloze는 unit당 round 10의 부족분 29개만, Satzbau는 round 8의 부족분 14개만 만든다.
4. pronunciation은 exact-level 보유 12개 기준의 부족분 8개씩, 총 32개를 만든다.
5. 한 seed에서 필요 없는 standalone kind는 ID 열을 비우며, 만드는 kind에만 canonical
   derivative를 둔다.

## 8. 금지 패턴

- OCR이 잘됐다는 이유로 추출문을 draft에 복사한다.
- source 파일명을 지운 뒤 원문을 의역해 독립 작성이라고 표시한다.
- 특정 자료의 단원별 어휘와 문법 순서를 그대로 `content_briefs.csv`에 옮긴다.
- source별 추출량을 콘텐츠 품질 점수로 사용한다.
- 중복 PDF를 서로 다른 교육 근거로 두 번 계산한다.
- C1/C2라는 이유만으로 전문용어와 긴 문장을 늘린다.
- 없는 course unit, concept, vocab, grammar ID를 추측해서 쓴다.
- review가 `draft`인데 `--apply`, TTS, Firebase 업로드를 실행한다.
- 앱 asset에 직접 append하고 나중에 manifest를 맞춘다.

## 9. 세션 종료 인수인계

변경한 세션은 `docs/SESSION_LOG.md` 최상단에 다음을 남긴다.

- 시작 기준 `main` SHA와 작업 브랜치
- 새로 판독하거나 갱신한 source ID
- text, mixed, image 판정과 미완료 페이지 범위
- 새 brief와 seed ID
- draft, review, manifest 경로와 record 수
- 실행한 validator와 정확한 결과
- Jin 승인이 필요한 항목
- 커밋 SHA

추출 원문이나 페이지 이미지는 인수인계에 첨부하지 않는다. 다음 세션은 정본 CSV의 상태와
미완료 audit 범위만 이어받는다.
