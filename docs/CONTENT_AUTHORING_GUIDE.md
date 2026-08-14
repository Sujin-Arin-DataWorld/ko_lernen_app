# 레벨별 콘텐츠 DB 작성·검수 안내서

> **상태:** C0 정본 · 2026-08-14
>
> 이 문서는 Hangul Sori의 새 학습 콘텐츠를 작성하는 사람·AI 세션·검수자가 함께 쓰는
> 실행 매뉴얼이다. 앱 UI를 바꾸는 문서가 아니다. 코드 기준 정본은
> `tools/content_factory/validate_content.py`, `apply_review.py`,
> `plan_pack_assignments.py`, `validate_batch_01.py`이며, 이 문서와 충돌하면 코드의
> fail-closed 규칙을 따른다.

## 0. 시작 전: 무엇을 어디에 쓰는가

새 콘텐츠를 쓸 때는 다음 세 층을 절대 섞지 않는다.

| 층 | 위치 | 역할 | 직접 편집 가능 여부 |
| --- | --- | --- | --- |
| **초안 원문** | `tools/content_factory/drafts/` | 실제 병합될 모든 필드를 갖춘 schema-complete 콘텐츠 | 예. 작성자가 편집하는 곳 |
| **승인 원장** | `tools/content_factory/review/` | Jin이 ID별 승인 상태를 남기는 CSV | 원칙적으로 `상태`와 `jin_memo`만 편집 |
| **앱 본문** | `assets/data/` | Flutter 앱이 실제로 읽는 정본 | 승인 전 직접 편집 금지 |

새로운 B1/B2 문장을 쓰는 일은 UI/UX v2, Sori Stage, Today 추천, 페이월 카피, 신규
motif/에셋 작업과 별개다. 이 가이드의 범위에는 실제 TTS 합성·Firebase Storage 업로드도
없다.

새 세션에게 일을 맡길 때는 먼저 아래 순서를 지시한다.

1. `AGENTS.md`와 이 문서를 전부 읽는다.
2. 현재 앱 자산을 `python3 tools/content_factory/validate_content.py`로 읽기 전용 검사한다.
3. `assets/data/`가 아니라 새/기존 `drafts/` 파일만 수정한다.
4. 독일어와 영어를 함께 작성하고, 같은 의미인지 검수한다.
5. review 원장을 draft와 동기화하고, Jin 승인 전에는 `--apply`, 실제 TTS, 커밋을 하지 않는다.

## 1. 가장 중요한 규칙 12개

1. **모든 새 학습 본문에는 DE와 EN가 모두 필요하다.** 독일어는 주 학습자 언어이고,
   영어는 동등한 대체 UI 언어다. 영어를 독일어의 직역으로 만들지 말고, 한국어 원문의
   같은 뜻을 자연스럽게 전달한다.
2. **한국어가 원문이다.** `de`/`en`은 한국어 문장의 뜻·존대·관계·정보량을 보존한다.
   번역에서 질문을 진술문으로, 공적 요청을 친한 말로 바꾸지 않는다.
3. **ID·레벨·행 순서는 콘텐츠 문구가 아니다.** 검수가 시작된 뒤에는 재번호·재정렬·ID
   교체를 하지 않는다. 문구를 고칠 때도 참조와 review 원장을 같이 갱신한다.
4. **앱 본문을 손으로 append하지 않는다.** 승인된 ID만 `apply_review.py`를 통해 병합한다.
   이 도구는 manifest와 전체 validator를 함께 실행하고 실패 시 원복한다.
5. **CSV 헤더·열 순서는 API다.** 열을 추가·삭제·번역·재배열하지 않는다. 쉼표, 큰따옴표,
   줄바꿈이 있는 값은 RFC CSV quoting으로 저장한다.
6. **레벨 표기 대소문자는 파일마다 다르다.** “보기 좋게 통일”하면 validator가 깨진다.
   아래 §3 표를 그대로 사용한다.
7. **한 단어팩은 분할 승인할 수 없다.** 새 `pack_id`는 11–12개가 모두 준비되고 모두
   승인된 경우에만 병합할 수 있다.
8. **게임 문장은 단어 예문에서 파생한다.** Cloze/Satz는 같은 레벨의 vocab 예문·표제어를
   참조해야 한다. 단어보다 게임을 먼저 앱에 넣지 않는다.
9. **커리큘럼 연결 없이 새 콘텐츠를 병합하지 않는다.** vocab pack, grammar, smalltalk,
   cloze, scenario에는 미래의 전용 통합 변경에서 대응 `curriculum_manifest.json` mapping이
   필요하다. 현재 C0의 `apply_review.py`만으로 그 multi-file 통합을 시도하지 않는다.
10. **Batch 01은 고정 검수 계약이다.** 96개 행에 새 행을 추가하지 않는다. 더 많은 양은
    Batch 02를 새로 만든다.
11. **생성 스크립트가 항상 안전한 것은 아니다.** 특히 `scripts/build_vocab_packs.py`는
    절대 실행하지 않는다. §15의 금지 목록을 따른다.
12. **placeholder를 넣지 않는다.** `TODO`, `TBD`, 빈 번역, 임시 영문, 추측한 번역,
    Markdown/HTML, 줄바꿈이 든 CSV 셀은 검수 대상이 아니다.

## 2. 언어·난이도 작성 원칙

### 2.1 KO / DE / EN 품질 계약

| 필드 | 반드시 지킬 점 |
| --- | --- |
| `ko`, `korean`, `example_korean`, `targetKo`, `fullKo` | 실제 한국어 화자가 해당 관계·상황에서 쓸 문장. 표제어는 사전형, 문장 안에서는 자연스러운 활용형을 쓴다. |
| `de`, `german`, `example_german`, `promptDe` | 독일어권 성인 학습자에게 자연스러운 독일어. 존대·법률/서비스 톤·정보량을 보존한다. |
| `en`, `english`, `example_english`, `promptEn` | 자연스러운 영어. 독일어 문장 구조를 복사하지 않는다. |
| `focus`, `quiz_focus_*` | 추상적인 설명이 아니라 문장 안에서 실제로 찾을 수 있는 정확한 문자열. |

새 문장은 모두 KO/DE/EN를 채운다. 일부 시나리오 메타데이터의 `ko`는 런타임상 빈 값이
허용되지만, 새 콘텐츠에서는 비워 두지 않는 것이 원칙이다. 의도적으로 빈 값이 꼭 필요하면
왜 필요한지 review `field_notes`에 적고 Jin이 확인해야 한다.

### 2.2 현재 언어 지원의 실제 경계

대부분의 새 B1/B2 작성 대상은 DE와 EN를 모두 지원하지만, 모든 기존 게임 schema가 이미
영어 필드를 갖는 것은 아니다. 존재하지 않는 필드를 content-only batch에서 임의로 추가하면
앱이 읽지 않거나 validator/loader 계약이 어긋난다.

| 유형 | 현재 learner-facing 언어 필드 | 새 콘텐츠 작성 규칙 |
| --- | --- | --- |
| vocab, grammar, scenario, smalltalk, Cloze, Satzbau, pronunciation | KO + DE + EN | 세 언어를 모두 채운다. 이것이 현재 B1/B2 확장 기본값이다. |
| `grammar_patterns.json` | DE + EN 설명/이름, KO regex 대상 | DE/EN를 모두 채우고 Cloud Function mirror도 함께 갱신한다. |
| 실벤 `silben_puzzles.json` | Korean answer/example + `german`, `exampleDe` | **현재 EN field가 없다.** 임의 `english`/`exampleEn`을 추가하지 않는다. 영어 지원은 loader·UI·tests를 포함한 별도 schema 변경이다. |
| 끝말잇기 `kkeunmari_pool.json` | Korean word + `german` | **현재 EN gloss field가 없다.** EN를 가짜/미사용 필드로 넣지 않는다. 별도 앱 schema 작업이 필요하다. |

따라서 “모든 콘텐츠를 영어/독일어로”라는 제품 목표와 “현재 파일이 실제로 지원하는
field”를 구분한다. 이번 Batch 01의 다섯 작성 대상은 모두 DE/EN를 갖는다. 실벤·끝말잇기의
영어 확장은 콘텐츠만의 일이 아니므로 별도 코드/UX 계획으로 분리한다.

### 2.3 B1/B2의 교육적 경계

| 레벨 | 쓰는 상황 | 언어적 목표 | 피해야 할 것 |
| --- | --- | --- | --- |
| B1 | 주거, 직장, 서비스 문제, 건강, 일상 행정, 관계 조율 | 이유·대조, 완곡한 요청, 경험·계획 설명, 실제 문제 해결 | A1 단어를 희귀 전문용어로 치환해 난도만 올리는 방식 |
| B2 | 격식 문의, 합의·협상, 행정·민원, 추상 논의, 간접·문어적 설명 | 등록(register), 조건·양보·근거, 정확한 요청, 협의·의무 표현 | 현실에서 쓰지 않는 법률어/한자어 나열, 번역투 공문체 |

독일어/영어 번역은 한 언어에서 자연스럽고 다른 언어에서 어색할 수 있다. 따라서 다음을
각각 확인한다.

- 한국어의 존대와 관계(`service`, `coworker`, `peer` 등)가 DE/EN의 높임·거리감과 맞는가.
- 질문·선택지·정답이 번역에서 정답을 노골적으로 누설하지 않는가.
- 하나의 한국어 단어가 여러 뜻이면 이 레코드가 가르치는 뜻 하나만 번역했는가.
- 문화/제도 설명이 사실 확인 없이 단정적이지 않은가.

## 3. 레벨·ID·문자 인코딩 공통 규칙

### 3.1 레벨 표기

| 파일/유형 | 허용 값 | 표기 |
| --- | --- | --- |
| `korean_vocab.csv`, `grammar.csv`, review 원장 | `A1`, `A2`, `B1`, `B2` | **대문자** |
| smalltalk, cloze, Satzbau, scenario, pronunciation JSON | `a1`, `a2`, `b1`, `b2` | **소문자** |
| `silben_puzzles.json`의 `levels` key, 끝말잇기, grammar patterns | `A1`, `A2`, `B1`, `B2` | **대문자** |
| Storage의 학습자 레벨 | `a1`, `a2`, `b1`, `b2` | 앱 코드가 소문자로 저장 |

ID의 level segment와 본문 level은 반드시 일치해야 한다. 예: `cloze_b1_0070`은
`"level": "b1"`이어야 하고, `vocab_b2_0217`은 CSV `level`이 `B2`여야 한다.

### 3.2 ID 규칙

| 유형 | 패턴 | 예 |
| --- | --- | --- |
| vocab | `vocab_(a1|a2|b1|b2)_####` | `vocab_b1_0248` |
| grammar | `grammar_(a1|a2|b1|b2)_lowercase_slug` | `grammar_b2_formal_reason` |
| smalltalk | `smalltalk_(a1|a2|b1|b2)_####` | `smalltalk_b1_0037` |
| Cloze | `cloze_(a1|a2|b1|b2)_####` | `cloze_b2_0058` |
| Satzbau | `satz_(a1|a2|b1|b2)_####` | `satz_b1_0050` |
| pronunciation | `pronunciation_(a1|a2|b1|b2)_####` | `pronunciation_a2_0002` |
| 실벤 | `skz_<lowercase-level>_###` | `skz_b1_021` |
| OCR grammar pattern | `g_lowercase_slug` | `g_progressive` |
| scenario | lowercase ASCII letters, digits, underscore only | `formal_contract_inquiry` |

`####`는 자릿수를 보존한다. 다음 번호는 **현재 앱 자산과 아직 병합되지 않은 모든 draft를
함께 보고** 잡는다. Batch 01의 예약 번호를 다음 배치에서 재사용하면 안 된다.

### 3.3 CSV 저장 규칙

- UTF-8 comma-separated CSV를 쓴다. 스프레드시트가 지역 설정 때문에 세미콜론 CSV를
  내보내지 않는지 확인한다.
- 열 이름·열 순서·대소문자를 한 글자도 바꾸지 않는다.
- 값 안에 쉼표, 큰따옴표, 줄바꿈이 있으면 CSV writer/Google Sheets의 정상 export를 쓴다.
  사람이 직접 쉼표로 join하지 않는다.
- 값 안의 큰따옴표는 CSV 규칙에 따라 `""`로 escape한다. 가능하면 embedded line break는
  쓰지 않는다.
- 한국어·독일어·영어 모두 앞뒤 공백을 남기지 않는다.

## 4. Batch 01: 지금 보강 가능한 범위와 잠금

현재 Batch 01은 아래 다섯 초안과 다섯 review 원장으로 구성된 **고정 96-record 계약**이다.

| Draft | 앱 병합 대상 | B1 | B2 | 합계 |
| --- | --- | ---: | ---: | ---: |
| `c3_batch01_vocab_b1_b2.csv` | `assets/data/korean_vocab.csv` | 12 | 12 | 24 |
| `c4_batch01_grammar_b1_b2.csv` | `assets/data/grammar.csv` | 4 | 4 | 8 |
| `c2_batch01_smalltalk_b1_b2.json` | `assets/data/smalltalk.json`의 `phrases` | 8 | 8 | 16 |
| `c2_batch01_cloze_b1_b2.json` | `assets/data/cloze.json`의 `items` | 12 | 12 | 24 |
| `c2_batch01_satz_b1_b2.json` | `assets/data/satz_sentences.json`의 `items` | 12 | 12 | 24 |

### 4.1 가능: 기존 96개 항목의 품질 보강

다음은 기존 ID·level·순서·개수를 유지하는 한 가능하다.

- KO/DE/EN 문장을 더 자연스럽게 고치기
- 문법 설명·용법 노트·quiz focus를 정확하게 고치기
- smalltalk의 안전한 대안 질문·reply·follow-up을 더 현실적으로 고치기
- Cloze/Satz distractor를 더 공정하고 자연스럽게 고치기
- `field_notes`를 더 명확하게 고치기

단, 다음 변경은 **연쇄 수정**이 필요하다.

| 바꾼 값 | 반드시 함께 확인/수정할 값 |
| --- | --- |
| vocab `korean` 또는 `example_korean` | Cloze `answer/fullKo/sentenceKo`, Satz `vocabKo/targetKo`, 관련 DE/EN, review projection |
| vocab `pack_id/order/boss` | batch manifest `vocabPacks`, planner, review notes; 원칙적으로 변경 금지 |
| grammar `id` | 모든 `quiz_distractor_ids`, `grammarIntents`, 이후 scenario `grammarIds`, curriculum map; 원칙적으로 변경 금지 |
| smalltalk `category/level/id` | review, smalltalk category map, Batch manifest; 원칙적으로 변경 금지 |
| Cloze `answer/fullKo/topic` | `sentenceKo`, review, cloze topic map |
| Satz `vocabKo/level` | 실제 같은 레벨 vocab reference, review, batch manifest dependency |

### 4.2 금지: Batch 01에 새 행 추가

`validate_batch_01.py`는 Batch 01의 정확한 ID 집합, 순서, level별 개수, review 행 수를
하드코딩해 검증한다. 따라서 다음은 하지 않는다.

- 97번째 행 추가
- 기존 행 삭제
- ID 재번호 또는 순서 변경
- 새 draft/review 파일을 Batch 01 manifest에 임의 추가
- Batch 01의 `recordCount`만 늘리기

더 풍성한 새 콘텐츠는 `batch_02_manifest.json`과 `c2/c3/c4_batch02_*` 파일을 별도로
만든다. Batch 02에는 Batch 01 validator를 복사해 숫자만 바꾸지 말고, 별도 batch-specific
preflight/test 또는 일반화된 검증 계약을 먼저 추가한다. 이미 검수 중인 Batch 01을
느슨하게 만들어서는 안 된다.

### 4.3 Batch 01 review 동기화

Batch 01 review header는 정확히 아래와 같아야 한다.

```csv
id,level,ko,de,en,field_notes,상태,jin_memo
```

| review 열 | 규칙 |
| --- | --- |
| `id` | draft ID와 동일, 한 번만, draft와 같은 순서 |
| `level` | draft level의 대문자 표기 |
| `ko`, `de`, `en` | 아래 projection과 **한 글자까지** 동일한 읽기 전용 snapshot |
| `field_notes` | 비어 있으면 안 됨. 검수자가 봐야 할 relation, source, answer, pack 정보 |
| `상태` | Jin 검수 전에는 정확히 `draft`; Jin은 `ok` 또는 `approved`로만 승인 |
| `jin_memo` | 선택. 승인/수정 사유를 기록 |

Batch 01의 review projection은 다음과 같다.

| Draft 유형 | review `ko` | review `de` | review `en` |
| --- | --- | --- | --- |
| vocab | `korean` | `german` | `english` |
| grammar | `pattern` | `type_de` | `type_en` |
| smalltalk | `ko` | `de` | `en` |
| Cloze | `fullKo` | `de` | `en` |
| Satzbau | `targetKo` | `promptDe` | `promptEn` |

문구를 draft에서 고쳤다면 review의 해당 projection도 꼭 같이 고친다. 반대로 review CSV에서
문구만 고치면 실제 병합 원문은 바뀌지 않으므로 잘못된 수정이다.

`validate_batch_01.py`는 **Jin 검수 전**에만 실행한다. 모든 `상태`가 `draft`인 것을
검사하므로 Jin이 `approved`를 입력한 뒤에는 실패하는 것이 정상이다. 승인 후에는
`apply_review.py` preview를 사용한다.

## 5. Vocabulary — 15열 CSV 전체 명세

정확한 헤더 순서:

```csv
korean,romanization,german,level,pos_de,example_korean,example_german,topic,pack_id,pack_order,is_review_boss,english,pos_en,example_english,id
```

모든 15개 열은 앱 본문에서 nonempty다.

| 열 | 값 규칙 | 작성 품질 |
| --- | --- | --- |
| `korean` | 하나의 한국어 표제어, 전역 중복 불가 | 동사는 사전형(`-다`), 명사는 표제형. 예문/게임의 참조와 철자까지 일치 |
| `romanization` | 소문자 RR 스타일, 필요 시 단어 사이 공백 | IPA, 독일어식 표기, 숫자, 한글, diacritic을 넣지 않음. 기존 표기와 일관성 유지 |
| `german` | 비어 있지 않은 짧고 자연스러운 뜻 | 이 레코드의 뜻 하나를 명확히. 성별이 중요한 직업명은 자연스럽게 표기 |
| `level` | `A1`/`A2`/`B1`/`B2` 대문자 | ID·pack prefix와 일치 |
| `pos_de` | `Nomen`, `Verb`, `Adjektiv`, `Adverb`, `Ausdruck`, `Pronomen` 중 기존 taxonomy | 한국어 표제형과 뜻에 맞춤 |
| `example_korean` | 완결된 자연스러운 한국어 예문 | 표제어 또는 자연스러운 활용형을 반드시 포함. 이후 Cloze/Satz의 원문 |
| `example_german` | 예문의 자연스러운 독일어 번역 | 표제어 gloss가 아니라 전체 문장 번역 |
| `topic` | 안정적인 사람이 읽는 토픽 라벨 | 같은 주제의 Cloze/manifest에서 철자·대소문자·`&` 사용을 정확히 재사용 |
| `pack_id` | level prefix가 맞는 snake_case ID | **새 pack은 반드시** `<level>_<ascii_slug>_<양의 숫자 suffix>`; 예 `b1_housing_contract_1`. 같은 pack의 모든 행이 동일 |
| `pack_order` | 양의 정수 | 새 pack은 `1..11` 또는 `1..12`가 끊김 없이 연속 |
| `is_review_boss` | 소문자 literal `true` 또는 `false` | 새 pack 마지막 2–3개만 `true`, 앞 행은 모두 `false` |
| `english` | 표제어의 자연스러운 영어 뜻 | 독일어 gloss의 기계적 직역 금지 |
| `pos_en` | `Noun`, `Verb`, `Adjective`, `Adverb`, `Expression`, `Pronoun` 중 기존 taxonomy | `pos_de`와 품사 의미를 맞춤 |
| `example_english` | 예문의 자연스러운 영어 번역 | `example_korean`와 동일한 정보·시제·공손함 |
| `id` | `vocab_<level>_####` | 전역 유일. level segment와 CSV level 일치 |

### 5.1 새 vocab pack의 추가 계약

새로운 `pack_id`는 일반 행 묶음이 아니라 학습 루프의 단위다. 다음을 모두 만족해야 한다.

- 정확히 11 또는 12개 단어
- 한 CEFR level만 포함
- 새 `pack_id`는 예를 들어 `b2_formal_agreement_1`처럼 level prefix와 양의 numeric
  sub-pack suffix를 모두 가져야 함
- `pack_order`는 1부터 n까지 빈틈 없이 연속
- Boss는 정확히 2 또는 3개이며 마지막 2–3개의 order
- 어떤 한 행만 승인할 수 없음. 하나가 `ok/approved`라면 pack의 모든 행이 승인되어야 함
- 새 Korean headword와 ID는 기존 앱 데이터·같은 draft 양쪽에서 중복되면 안 됨
- 실제 병합 때 `--pack-metadata`와 `plan_pack_assignments.py` preflight가 필요

새 pack metadata의 필수 모양:

```json
{
  "packId": "b1_topic_name_1",
  "level": "b1",
  "orderInLevel": 19,
  "orderRange": [1, 12],
  "reviewBossOrders": [10, 11, 12],
  "displayLabel": {
    "ko": "한국어 팩 이름",
    "de": "Deutscher Packname",
    "en": "English pack name"
  },
  "motif": "gwigap",
  "curriculum": {
    "courseUnitId": "b1_05_complaint_resolution",
    "conceptIds": ["concept_b1_complaint_resolution"]
  }
}
```

`motif`는 기존 Dart `DancheongMotif` 값이어야 한다. 새 UI asset를 만들지 않는다.
`courseUnitId`는 실제 존재하는 동일 레벨 unit이고, `conceptIds`는 그 unit의
`requiredConceptIds` 안에 있어야 한다. `packId`의 숫자 suffix를 뺀 base ID가
`vocabPackUnitMap`의 key가 된다.

## 6. Grammar — 16열 CSV 전체 명세

정확한 헤더 순서:

```csv
pattern,level,type_de,explanation_de,example_korean,example_german,note,type_en,explanation_en,example_en,note_en,id,quiz_focus_de,quiz_focus_en,quiz_enabled,quiz_distractor_ids
```

| 열 | 값 규칙 |
| --- | --- |
| `pattern` | 정확한 한국어 문법 표기. 품사/형태를 명시: 예 `V-아/어 놓다`, `A/V-(으)ㄴ/는 편이다` |
| `level` | `A1`/`A2`/`B1`/`B2` 대문자 |
| `type_de` | 짧은 독일어 범주명 |
| `explanation_de` | 의미·용법·제약을 설명하는 자연스러운 독일어 |
| `example_korean` | 해당 문법의 목표 용법을 한 번 분명히 보이는 자연스러운 문장 |
| `example_german` | 위 한국어 문장의 독일어 번역 |
| `note` | 독일어 사용 주의/대조/형태 노트 |
| `type_en` | 짧은 영어 범주명 |
| `explanation_en` | `explanation_de`의 영어 대응 설명 |
| `example_en` | 위 한국어 문장의 영어 번역 |
| `note_en` | 영어 사용 주의/대조/형태 노트 |
| `id` | `grammar_<level>_<lowercase_ascii_slug>`; 예 `grammar_b2_formal_reason` |
| `quiz_focus_de` | `example_german` 안에 정확히 한 번 나타나는 nonempty 연속 문자열 |
| `quiz_focus_en` | `example_en` 안에 정확히 한 번 나타나는 nonempty 연속 문자열 |
| `quiz_enabled` | 소문자 literal `true` 또는 `false` |
| `quiz_distractor_ids` | quiz 활성 시 `|`로 연결한 정확히 3개 grammar ID; 비활성 시 빈 값 |

`quiz_enabled=true`의 추가 규칙:

- distractor는 정확히 3개, 서로 달라야 하고 자기 ID를 포함하면 안 된다.
- 모든 distractor는 실제 존재하거나 같은 draft에서 함께 승인될 grammar ID여야 한다.
- 정답과 distractor는 같은 CEFR level이고 모두 `quiz_enabled=true`여야 한다.
- DE/EN focus는 해당 예문에 0회 또는 2회 나타나면 실패한다. 번역 문장을 수정했다면
  focus도 다시 찾는다.

`quiz_enabled=false`라면 `quiz_distractor_ids`는 빈 값이어야 한다. false를 사용해
불확실한 문법을 우회하지 말고, quiz-ready 품질이 될 때까지 draft 상태로 둔다.

## 7. Smalltalk — `phrases` JSON 전체 명세

Draft root는 아래 형태다. live asset의 `categories`는 정본이므로 draft에 복사하거나
교체하지 않는다.

```json
{
  "version": 1,
  "_comment": "작성 메모는 선택",
  "phrases": []
}
```

각 phrase의 완전한 형태:

```json
{
  "id": "smalltalk_b1_0045",
  "category": "transport",
  "level": "b1",
  "kind": "question",
  "ko": "…",
  "de": "…",
  "en": "…",
  "reply": { "ko": "…", "de": "…", "en": "…" },
  "relationshipContext": "service",
  "safeAlternativeQuestions": [
    { "turnKind": "question", "ko": "…", "de": "…", "en": "…" }
  ],
  "followUp": { "turnKind": "reaction", "ko": "…", "de": "…", "en": "…" }
}
```

| 필드 | 허용 값/규칙 |
| --- | --- |
| `id` | `smalltalk_<level>_####`, 전역 유일 |
| `category` | live `categories[].id` 중 하나. 현재: `weather`, `mood`, `weekend`, `food`, `daily`, `screen`, `music`, `hobby`, `travel`, `work_study`, `family`, `health`, `kpop`, `dating`, `interview`, `job_hunting`, `moving`, `hospital`, `transport`, `shopping`, `phone`, `emergency` |
| `level` | 소문자 `a1`/`a2`/`b1`/`b2` |
| `kind` | 정확히 `opener`, `question`, `reaction` 중 하나 |
| `ko`, `de`, `en` | 모두 nonempty. 주 문장 하나의 정확한 삼언어 대응 |
| `relationshipContext` | 정확히 `peer`, `classmate`, `coworker`, `close_friend`, `family`, `service` 중 하나 |
| `reply` | primary `kind: "question"`이면 필수. `{ko,de,en}` 모두 nonempty. non-question에는 보통 생략 |
| `safeAlternativeQuestions` | 비어 있지 않은 배열. 각 원소는 `turnKind: "question"` 및 `{ko,de,en}` 모두 필요 |
| `followUp` | 한 개의 `{turnKind,ko,de,en}` object. `turnKind`는 `question`, `response`, `reaction` 중 하나 |

새 category는 phrase만으로 만들 수 없다. 미래의 전용 통합 변경에서 live `categories`에
`{id, emoji, label:{ko,de,en}}`를 추가하고, level/category의 curriculum mapping도
준비해야 한다. 이것은 현재 target-local `apply_review.py`가 함께 쓰지 못하는 파일이므로
C0의 preview/apply로 우회하지 않는다. 관계 맥락과 맞지 않는 질문, 민감한 개인정보 요구,
답을 강요하는 질문을 쓰지 않는다. 각 항목에는 자연스러운 safe alternative와 follow-up을 둔다.

## 8. Cloze — `items` JSON 전체 명세

```json
{
  "items": [
    {
      "id": "cloze_b1_0068",
      "level": "b1",
      "sentenceKo": "＿＿＿에 인터넷 요금도 포함되어 있나요?",
      "answer": "관리비",
      "fullKo": "관리비에 인터넷 요금도 포함되어 있나요?",
      "de": "Sind die Internetkosten in den Nebenkosten enthalten?",
      "en": "Are the internet charges included in the maintenance fee?",
      "distractors": ["계약서", "수리비", "난방"],
      "topic": "Wohnen & Vertrag"
    }
  ]
}
```

| 필드 | 규칙 |
| --- | --- |
| `id` / `level` | `cloze_<level>_####`, 소문자 level과 일치 |
| `fullKo` | 완전한 한국어 문장. 가능하면 같은 vocab row의 `example_korean`을 그대로 사용 |
| `answer` | `fullKo` 안에서 첫 번째로 치환할 정확한 한국어 문자열. 같은 레벨 vocab의 표제어/자연스러운 활용형 |
| `sentenceKo` | `fullKo.replace(answer, "＿＿＿", 1)`과 정확히 같아야 함. ASCII `___`가 아니라 full-width `＿＿＿` 사용 |
| `de`, `en` | 빈칸 문장이 아닌 **완전한** `fullKo`의 번역 |
| `distractors` | validator 최저 2개지만 새 콘텐츠는 정확히 3개, 서로 다르고 answer가 아니며 같은 레벨·형태상 그럴듯한 오답 |
| `topic` | nonempty 안정 라벨. `clozeTopicUnitMap` key는 `<level>:<topic.lower()>`이므로 spelling/case를 동반 mapping과 맞춤 |

답은 문맥으로 하나만 정해져야 한다. compound의 일부만 지우거나, 불필요하게 활용 어미만
지워서 문법 퍼즐로 바꾸지 않는다. 보통 `answer`가 `fullKo`에 한 번만 나타나는 문장을
쓴다.

## 9. Satzbau — `items` JSON 전체 명세

```json
{
  "items": [
    {
      "id": "satz_b1_0062",
      "level": "b1",
      "targetKo": "관리비에 인터넷 요금도 포함되어 있나요?",
      "promptDe": "Sind die Internetkosten in den Nebenkosten enthalten?",
      "promptEn": "Are the internet charges included in the maintenance fee?",
      "distractors": ["계약서를", "수리비가"],
      "vocabKo": "관리비"
    }
  ]
}
```

| 필드 | 규칙 |
| --- | --- |
| `id` / `level` | `satz_<level>_####`, 소문자 level과 일치 |
| `targetKo` | 완전한 자연스러운 한국어 문장. 같은 vocab row `example_korean`을 그대로 재사용하는 것이 원칙 |
| `promptDe`, `promptEn` | `targetKo`의 자연스러운 독일어·영어 번역 |
| `distractors` | 최소 2개지만 새 콘텐츠는 정확히 2개, 서로 다르고 target token이 아니며 자연스럽게 유혹적이어야 함 |
| `vocabKo` | 실제 `korean_vocab.csv`의 Korean headword 하나와 철자까지 정확히 일치, 같은 level이어야 함 |

`vocabKo`는 Satz의 SRS/커리큘럼 연결 키다. 문장 전체, 활용형, 번역을 넣지 않는다. target은
최소 세 eojeol로 만들고, 공백 분절이 어색하지 않은지 확인한다. 문장부호 `?`/`!`는 tile
처리에 특별하므로 target 끝에만 자연스럽게 쓴다.

## 10. Scenario — `scenarios` JSON 전체 명세

시나리오는 C1 이후에 실제 신규 vocab·grammar·course mapping이 존재할 때만 만든다.
Batch 01에는 아직 scenario를 넣지 않는다. 새 scenario는 아래 필드를 갖는 완전 object다.

```json
{
  "id": "formal_contract_inquiry",
  "level": "b2",
  "emoji": "📄",
  "register": "business",
  "speechStyle": "business",
  "relationshipContext": "customer_and_service_staff",
  "intent": "request_clarification",
  "courseUnitId": "b2_03_precise_requests",
  "conceptIds": ["concept_b2_precise_requests"],
  "surfaceFormIds": ["surface_example"],
  "sidekick": "minsu",
  "xpReward": 140,
  "title": { "ko": "…", "de": "…", "en": "…" },
  "intro": { "ko": "…", "de": "…", "en": "…" },
  "vocab": [],
  "grammarIds": ["grammar_b2_formal_reason"],
  "grammarBlock": {
    "title": { "ko": "…", "de": "…", "en": "…" },
    "explanation": { "ko": "…", "de": "…", "en": "…" }
  },
  "dialog": [],
  "quests": [],
  "culturalNote": {
    "title": { "ko": "…", "de": "…", "en": "…" },
    "body": { "ko": "…", "de": "…", "en": "…" }
  }
}
```

### 10.1 Scenario 필드 규칙

| 필드 | 규칙 |
| --- | --- |
| `id` | lowercase ASCII `[a-z0-9_]+`, 전역 유일 |
| `level` | 소문자 CEFR |
| `emoji` | nonempty 한 개의 상황을 나타내는 emoji |
| `register`, `speechStyle` | canonical `polite`, `casual`, `business`, `intimate` 중 하나. legacy `formal`은 새 콘텐츠에 쓰지 않음 |
| `relationshipContext`, `intent` | nonempty, 기존 scenario/curriculum 용어와 일관된 snake_case 의미값 |
| `courseUnitId` | 실제 존재하는 같은 level course unit |
| `conceptIds` | nonempty, 해당 unit의 `requiredConceptIds`에 속하는 실제 concept ID |
| `surfaceFormIds` | 실제 curriculum surface form ID만 사용 |
| `sidekick` | 새 항목은 `minsu`/`jieun`, 또는 기존 corpus에서 검증된 speaker/sidekick code를 재사용하거나 생략. 새 code는 avatar fallback을 실제 확인 |
| `xpReward` | 양의 정수. 비슷한 기존 scenario의 범위를 따름 |
| `title`, `intro` | `{ko,de,en}`. 새 항목은 세 언어 모두 채움 |
| `vocab` | 최소 6개 object. 각 object의 `korean` nonempty; 선택 `aliases`/`variants`는 nonempty string 배열, 선택 `note`는 `{ko,de,en}` |
| `grammarIds` | 최소 1개. `grammar.csv`에 이미 존재하는 ID만 사용 |
| `grammarBlock` | **필수 object.** `title`/`explanation` 모두 `{ko,de,en}`. runtime validator는 DE/EN를 필수로 보고, 새 작성 원칙은 KO도 채움 |
| `dialog` | 최소 6줄. 각 줄 `{speaker,ko,de,en}` 모두 nonempty |
| `quests` | 최소 3개. 새 scenario에는 `hoerverstehen` 1개 이상 필수 |
| `culturalNote` | 선택. 있으면 `title`/`body` 모두 `{ko,de,en}` |

시나리오는 권장 8–10 dialog turns와 4–6 quests로 하나의 실제 목적(문의→정보 확인→
해결)을 끝낸다. 시나리오 전용 배경을 만들지 않으면 먼저 existing scene category mapping을
확인한다. **새 scenario ID는 dedicated
`assets/illustrations/scenes/<id>.png`가 없으면** `lib/models/scenario.dart`의
`ScenarioBackdrop._categoryById`에 반드시 등록해 기존 backdrop key(airport, cafe,
convenience, directions, home, hotel, market, office, pharmacy, restaurant, station, taxi) 중
하나를 가리켜야 한다. 이 mapping이 빠지면 poster가 null이 되어 마스코트 fallback으로
떨어진다. 새 scene key/asset 자체를 만드는 일은 UI/asset track으로 분리한다.

### 10.2 Quest별 `data` 규칙

| `type` | 필수 `data` | 옵션/정답 규칙 |
| --- | --- | --- |
| `hoerverstehen` | `audioKo`, `options` | options는 최소 4개 `{de,en}` object, `correctIndex`는 유효 index |
| `uebersetzen` | `promptDe`, `promptEn`, `options` | options는 최소 4개 `{ko}` object, 유효 `correctIndex` |
| `luecken` | `sentence` | ASCII `___`가 한 번 이상 포함, options는 최소 4개 nonempty string, 유효 `correctIndex` |
| `particlePop` | `prefix` 또는 `suffix`, `explanationDe`, `explanationEn` | options 최소 4개 nonempty string, 유효 `correctIndex` |
| `batchimDrop` | `audioKo`, `targetWord`, `targetSyllableIndex`, `explanationDe`, `explanationEn` | index는 target word 범위 안, options 최소 4개, 유효 `correctIndex` |
| `satzBauen` | `targetKo`, `promptDe`, `promptEn`, `distractors` | distractors는 list. target의 실제 순서를 하나만 만들 수 있게 작성 |
| `diktat` | `targetKo`, `promptDe`, `promptEn` | TTS로 들을 자연스러운 target |
| `schreiben` | nonempty `data` | 해당 handwriting engine이 읽는 실제 데이터만 사용 |

Quest가 concept evidence로 쓰이면 안정적인 `id`와 `conceptIds`를 추가하고 curriculum
`contentLinks`에서 정확한 source/role을 선언한다. index 기반의 임시 링크를 새로 만들지
않는다.

## 11. Pronunciation, 실벤, 끝말잇기, OCR 문법 패턴

이 네 유형은 일반 `apply_review.py` append만으로는 안전하지 않거나 별도 파이프라인을
가진다. schema를 알아도 이번 Batch 01에 임의로 추가하지 않는다.

### 11.1 Pronunciation — `pronunciation_phrases.json`

```json
{
  "version": 1,
  "phrases": [
    {
      "id": "pronunciation_b1_0001",
      "level": "b1",
      "ko": "…",
      "de": "…",
      "en": "…",
      "focus": "연음"
    }
  ]
}
```

| 필드 | 규칙 |
| --- | --- |
| root `version` | 양의 integer |
| `id` | `pronunciation_<level>_####` |
| `level` | 소문자 CEFR, ID와 일치 |
| `ko`, `de`, `en` | 모두 nonempty |
| `focus` | 짧고 검수 가능한 발음 현상 태그. 예: `연음`, `비음화`, `경음화` |

새 문장은 승인·병합된 뒤에만 TTS 후보가 된다. 작성·검수 단계에서는
`python3 tool/generate_tts.py --dry-run`으로 수량만 본다. 인증, 합성, 로컬 write,
Firebase Storage upload는 Jin의 별도 명시 허가 전까지 금지다.

### 11.2 실벤 — `silben_puzzles.json`

```json
{
  "version": 1,
  "levels": {
    "B1": [
      {
        "id": "skz_b1_021",
        "rows": 3,
        "cols": 4,
        "words": [
          {
            "dir": "h",
            "row": 0,
            "col": 0,
            "answer": "…",
            "german": "…",
            "exampleKo": "…",
            "exampleDe": "…"
          }
        ],
        "pool": ["…"]
      }
    ]
  }
}
```

- root `levels`에는 `A1`, `A2`, `B1`, `B2` 네 key가 모두 필요하다.
- puzzle ID는 `skz_<lowercase level>_###`, 전역 유일이다.
- `rows`/`cols`는 양의 integer다.
- word `dir`은 `h` 또는 `v`; `row`/`col`은 integer; `answer`, `german`, `exampleKo`,
  `exampleDe`는 모두 nonempty다.
- 모든 answer는 한 puzzle 안에서 유일하고, 각 글자는 격자 경계를 넘지 않아야 하며,
  교차 셀의 음절은 서로 같아야 한다.
- `pool`은 nonempty list이고, 완성 격자의 각 점유 음절을 필요한 횟수만큼 포함해야 한다.

이 파일은 생성기 기반 데이터다. 전용 실벤 작업 계획·생성기·퍼즐 테스트 없이 직접
hand-edit하거나 전체 generator를 다시 돌리지 않는다.

### 11.3 끝말잇기 — `kkeunmari_pool.json`

각 word object:

```json
{
  "word": "…",
  "first": "첫 음절",
  "last": "끝 음절",
  "level": "B1",
  "german": "…",
  "topic": "…",
  "next_count": 12,
  "is_dead_end": false
}
```

`word`는 전역 유일이고, `first`/`last`는 문자열의 실제 첫/끝 한글 음절이어야 한다.
`next_count`는 임의 수가 아니라 **전체 pool**에서 다음 첫 음절이 `last`인 단어 수(자기
loop 제외)로 재계산한 값이고, `is_dead_end == (next_count == 0)`이어야 한다. 이 파일은
stable ID가 없어 generic review append 대상이 아니다. 사전 검증·풀 재계산·체인 품질을
포함한 전용 batch에서만 변경한다.

### 11.4 OCR grammar pattern — `grammar_patterns.json`

```json
{
  "id": "g_formal_reason",
  "regex": "…",
  "name_de": "…",
  "name_en": "…",
  "level": "B2",
  "explanation_de": "…",
  "explanation_en": "…"
}
```

root는 array다. `id`는 `g_<lowercase_ascii_slug>`, level은 대문자 CEFR, `regex`는
Python 정규식으로 컴파일되어야 하며 나머지 DE/EN 필드는 모두 nonempty다.

반드시 다음 파일을 **byte-for-byte 동일하게** 같은 변경에 갱신한다.

```text
assets/data/grammar_patterns.json
functions/analyze_korean_text/grammar_patterns.json
```

따라서 이 파일도 generic `apply_review.py` 대상이 아니다. Cloud Function mirror와 배포
계획이 있는 C4 paired change에서만 바꾼다.

## 12. Batch manifest와 curriculum 동반 데이터

`batch_01_manifest.json`은 새 학습 본문이 later integration에서 어디와 연결될지를
선언한다. 핵심 root fields는 아래와 같다.

| field | 역할 |
| --- | --- |
| `version` | 양의 integer schema version |
| `batch` | 사람이 읽는 batch 번호 |
| `status` | 검수 전 `review_only_draft` |
| `provenance` | scope, 날짜, 원 계획, Jin 검수 필요 여부 |
| `artifacts` | kind/draft/review/count/level별 count의 정확한 목록 |
| `recordCount` | artifacts count 합계 |
| `vocabPacks` | pack metadata, label, motif, curriculum 의도 |
| `grammarIntents` | grammar ID → unit/concept 의도 |
| `smalltalkCategoryMappings` | `(level, category)` → unit/concept 의도 |
| `clozeTopicMappings` | `(level, topic)` → unit/concept 의도 |
| `satzDependencies` | Satz가 의존하는 same-level vocab pack과 count |
| `mergeOrder` | 실제 asset 병합 순서 |
| `nonMergeGuards` | 승인 전 금지 조건 |

새 콘텐츠를 실제로 앱 본문에 넣을 때, 아래 대응 mapping이 필요하다. 단, **현재 C0의
`apply_review.py` 트랜잭션은 target asset과 audit manifest만 쓴다.**
`curriculum_manifest.json`이나 Dart pack map을 함께 원자적으로 쓰는 통합기는 아직 없다.
따라서 approval만으로 이 mapping들을 미리 손편집하거나 `--apply`를 시도하면 전체
validator가 rollback시키는 것이 정상이다. 먼저 아래 동반 변경을 함께 검토·검증하는
전용 통합 작업을 구현한 뒤에만 실제 병합을 계획한다.

| 새 콘텐츠 | `curriculum_manifest.json` 동반 변경 |
| --- | --- |
| 새 vocab pack | `vocabPackUnitMap` (numeric suffix를 뺀 base pack ID → course unit) |
| 새 grammar | `grammarRuleMap` (grammar ID → course unit + concept IDs) |
| 새 smalltalk level/category | `smalltalkCategoryUnitMap` (`b1:category` 같은 key → unit + concepts) |
| 새 cloze level/topic | `clozeTopicUnitMap` (`b1:topic` → unit) |
| scenario, 평가/학습 연계 콘텐츠 | 필요할 때만 정확한 `contentLinks` source/role |
| Satz | 직접 map이 아니라 same-level `vocabKo` → vocab pack mapping에서 파생 |

unit는 존재하고 같은 CEFR level이어야 하며, concept은 그 unit의 `requiredConceptIds`에
들어 있어야 한다. `contentLinks`를 만능 연결표처럼 남용하지 않는다. 명시적인
introduce/practice/assess/review 근거가 있을 때만 추가한다.

새 vocab pack에는 `curriculum_manifest.json` 외에도 Dart
`VocabPackService.packDisplayMap`과 `packOrderInLevel`의 동반 항목이 필요하다. 새
scenario에는 위 §10의 `ScenarioBackdrop._categoryById` 동반 항목도 필요하다. 이것들은
현재 `apply_review.py`가 쓰지 않는 파일이다. **직접 선편집으로 우회하지 말고**, C1/C3
통합 세션에서 multi-file transaction·회귀 테스트를 갖춘 뒤 함께 처리한다.

`content_audit_manifest.json`은 초안 카운터가 아니라 **실제 앱 자산 inventory**다.
draft를 만들 때 수치를 올리지 않는다. `apply_review.py --apply`가 지원하는 target은
성공한 트랜잭션 안에서 해당 수치를 갱신한다.

## 13. 작성 → 검수 → 병합 순서

### 13.1 Jin 검수 전: 쓰기 없는 단계

```bash
# 현재 live asset의 빠른 실패 검사
python3 tools/content_factory/validate_content.py

# Batch 01의 96 record + review snapshot + overlay 검사
python3 tools/content_factory/validate_batch_01.py

# 새 vocab pack의 label/motif/order/curriculum 읽기 전용 사전검사
python3 tools/content_factory/plan_pack_assignments.py \
  --draft tools/content_factory/drafts/c3_batch01_vocab_b1_b2.csv \
  --metadata tools/content_factory/drafts/batch_01_manifest.json

# review preview: 어떤 파일도 쓰지 않음
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/c3_batch01_vocab.csv \
  --draft tools/content_factory/drafts/c3_batch01_vocab_b1_b2.csv \
  --target assets/data/korean_vocab.csv \
  --pack-metadata tools/content_factory/drafts/batch_01_manifest.json
```

다른 asset도 같은 모양으로 preview한다.

```text
grammar     → assets/data/grammar.csv
smalltalk   → assets/data/smalltalk.json
cloze       → assets/data/cloze.json
satz        → assets/data/satz_sentences.json
scenario    → assets/data/scenarios.json
pronunciation → assets/data/pronunciation_phrases.json
```

preview에서 `0 approved record(s)`가 보이는 것은 모든 상태가 `draft`인 현재로서는 정상이다.

### 13.2 Jin 검수 후: 승인 상태와 preview

Jin은 review 원장에서 `상태`를 `ok` 또는 `approved`로 바꾸고, 필요한 이유를
`jin_memo`에 남긴다. `fix: …`, `no`, `rejected`, 빈 상태, 알 수 없는 상태는 병합되지
않는다. 동일 ID가 두 번 있으면 상태가 달라도 실패한다.

승인 후에는 먼저 다시 preview하고, 그 결과가 Jin이 승인한 ID와 정확히 맞는지 확인한다.
새 vocab pack은 한 행이라도 pending이면 preview 자체가 실패하는 것이 정상이다.

### 13.3 실제 병합: 별도 통합 구현과 Jin 명시 지시 뒤에만

Jin이 `--apply`와 커밋을 명시하더라도, 새 vocab/grammar/smalltalk/cloze/scenario에는
현재 C0에 없는 multi-file integration transaction이 먼저 필요하다. 그 통합기가
curriculum mapping, 새 vocab의 Dart pack maps, 새 scenario의 backdrop mapping을 함께
검증·원자적으로 다루지 못하면 `apply_review.py --apply`를 실행하지 않는다. 직접 asset을
선편집해 validator를 통과시키는 것은 금지다.

그 통합 구현과 Jin의 명시 지시가 모두 갖춰진 뒤에만, 아래 target-local transaction을
실행한다.

```bash
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/c3_batch01_vocab.csv \
  --draft tools/content_factory/drafts/c3_batch01_vocab_b1_b2.csv \
  --target assets/data/korean_vocab.csv \
  --pack-metadata tools/content_factory/drafts/batch_01_manifest.json \
  --apply
```

`--apply`는 target write → audit manifest 갱신 → 전체 `validate_content.py`를 하나의
트랜잭션으로 처리한다. 중간 validator 실패 시 target과 manifest를 원상복구한다.
`--no-manifest` 우회는 존재하지 않는다.

병합의 정본 순서는 다음이다.

```text
vocab pack + 동반 mapping
→ 필요한 grammar + 동반 mapping
→ smalltalk / Cloze / Satz
→ scenario + course/checkpoint
→ game pool
→ pronunciation / TTS
```

## 14. 제출 전 체크리스트

### 모든 draft

- [ ] 내용이 B1/B2 목표와 맞고 실제 상황에서 자연스럽다.
- [ ] KO, DE, EN가 모두 있고 서로 같은 의미·관계·register를 가진다.
- [ ] ID가 유일하고 level 표기/ID prefix가 맞다.
- [ ] 기존 live asset과 모든 pending draft에서 duplicate headword/ID를 확인했다.
- [ ] CSV header/order/quoting 또는 JSON root/collection이 정확하다.
- [ ] `TODO`, placeholder, 빈 번역, 임시 category/ID가 없다.

### vocab / grammar

- [ ] vocab은 15열 전부 nonempty, 새 pack은 11–12개·연속 order·마지막 2–3 Boss다.
- [ ] grammar는 16열이며 `quiz_enabled=true` 행마다 동레벨 3 distractor와 DE/EN focus
  각각 정확히 1회가 있다.
- [ ] 새 pack의 KO/DE/EN label, existing motif, same-level unit/concept metadata가 있다.

### smalltalk / 게임 문장

- [ ] smalltalk은 실제 category와 유효 relationship/kind, reply, safe alternative, follow-up을 갖는다.
- [ ] Cloze blank가 full-width `＿＿＿`이고 `fullKo`의 첫 answer 치환과 정확히 일치한다.
- [ ] Cloze/Satz은 same-level vocab에서 파생했고 DE/EN가 원문 문장을 번역한다.
- [ ] Satz `vocabKo`가 정확히 하나의 same-level live/pending vocab headword를 가리킨다.

### review / 검증

- [ ] review header, ID 순서, row count, level, projection copy가 draft와 맞다.
- [ ] Jin 검수 전 모든 Batch 01 `상태`가 정확히 `draft`다.
- [ ] `validate_batch_01.py`와 `plan_pack_assignments.py`가 통과했다.
- [ ] `validate_content.py`가 통과했다.
- [ ] `apply_review.py`는 `--apply` 없는 preview만 실행했다.
- [ ] 실제 새 발화를 넣었다면 TTS는 `--dry-run`만 실행했다.

## 15. 절대 하지 말 것

| 금지 행동 | 이유/대안 |
| --- | --- |
| `scripts/build_vocab_packs.py` 실행 | 오래된 11열 migration 도구라 현재 15열 CSV의 EN/ID를 훼손할 수 있음. 완전 draft + `apply_review.py` 사용 |
| review CSV만 수정해 본문을 고침 | 실제 병합 원문은 draft다. draft와 review projection을 함께 수정 |
| `assets/data/`에 직접 append | audit/validator/rollback/graph 계약을 건너뜀 |
| `--no-manifest` 같은 우회 시도 | 지원하지 않으며 콘텐츠 count 정합성을 깨뜨림 |
| `build_cloze.py --write`, `build_satzbauen.py --write`, 실벤 전체 generator를 무계획 실행 | 전체 asset을 재생성해 authored ID/문장/검수 상태를 덮을 수 있음. 전용 regeneration 계획이 있을 때만 |
| `kkeunmari_pool.json`에 임의 행 삽입 | `next_count`/dead-end와 체인 품질이 전역 재계산 필요 |
| grammar pattern 한쪽만 수정 | Cloud Function mirror와 byte-for-byte 계약 위반 |
| 실제 `generate_tts.py` 실행 | 인증·합성·write·Storage upload가 발생. 검수 중에는 `--dry-run`만 |
| 오래된 개별 `add_*`/`build_*` 문서의 `--write` 예시를 신규 batch 정본으로 사용 | C0 draft/review/transaction 규칙보다 오래된 workflow일 수 있음 |

`tools/content_factory/README.md`의 C0 섹션과 이 문서가 신규 콘텐츠 정본이다. 그 아래의
historical maintenance script 설명은 기존 자산 유지보수 참고용이며, 신규 B1/B2 batch의
작성·승인·병합 지시로 해석하지 않는다.

## 16. 새 세션에 그대로 줄 수 있는 요청문

```text
AGENTS.md와 docs/CONTENT_AUTHORING_GUIDE.md를 먼저 전부 읽어.
UI/Sori Stage/실제 TTS/커밋은 건드리지 말고, 콘텐츠 draft만 작업해.

대상: [B1 또는 B2] / [유형: vocab|grammar|smalltalk|cloze|satz|scenario]
주제: [주제]
수량: [수량]

- assets/data에는 직접 쓰지 말고 tools/content_factory/drafts에 schema-complete draft를 만들어.
- KO/DE/EN를 모두 자연스럽게 채워. 독일어와 영어를 서로 직역하지 마.
- 기존 ID/표제어/pack/category/curriculum을 먼저 읽어 중복과 참조 오류를 피해.
- 새 vocab pack이면 11~12행, 연속 pack_order, 마지막 2~3 Boss, metadata와 planner를 준비해.
- review CSV는 공통 header와 draft projection을 정확히 맞추고 모든 상태를 draft로 둬.
- Batch 01에는 행을 추가하지 말고, 추가 수량은 Batch 02로 분리해.
- validate_content.py, 필요한 preflight, apply_review preview까지만 실행하고 --apply는 실행하지 마.
- 마지막에 변경 파일, 미병합 수량, 검증 결과, Jin이 검수할 review 파일을 보고해.
```

## 17. 참고 정본

- 구조/레벨 소유권: `docs/CONTENT_ARCHITECTURE.md`
- B1/B2 제작 순서와 품질 기준: `docs/CONTENT_PRODUCTION_TRACK_2026-08-14.md`
- Batch 01 파일·수량·mapping 의도: `tools/content_factory/drafts/README.md`, `batch_01_manifest.json`
- review 상태와 transactional 병합: `tools/content_factory/review/README.md`
- 기계 검증: `tools/content_factory/validate_content.py`, `validate_batch_01.py`,
  `plan_pack_assignments.py`, `apply_review.py`
