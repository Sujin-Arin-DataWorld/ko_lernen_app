# F1b — 국제통용 1급/2급 문법 ↔ 앱 문법 수기 매핑 (LCP PR-L2b phase 1)

> 생성: 수기 검토 (Sonnet, 2026-09-07). `F1_grammar_map.md`(정규식 매처, T1.4)를
> 리드만으로 쓰지 않고, NIKL 1급 45 + 2급 45 = 90항목 전부를
> `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv`와
> `assets/data/grammar.csv`를 직접 읽어 재검증했다. F1은 리드 제너레이션(후보
> 탐색)으로만 쓰고, 최종 verdict는 문법적 판단으로 확정했다. **이 표 자체는
> 아무 이동도 적용하지 않는다 — Fable 룰링 전까지 grammar.csv/ledger는 그대로.**

verdict ∈ `match`(레벨 일치) · `move_app_row_to:<A1|A2>`(같은 문법이나 레벨
불일치, 이동 후보) · `missing`(앱에 대응 행 없음) · 두 표 모두에서 자유
서술로 부연.

## 0. 자동 매처(F1) 대비 정정한 오류

F1이 "missing_in_app"으로 오분류했지만 실제로는 앱에 존재하는 항목(과제
브리프가 지적한 3건 + 수기 검토로 추가 발견한 3건):

| nikl 항목 | F1 판정 | 실제 | 원인 |
|---|---|---|---|
| 표현 `이 아니다` (1급) | missing_in_app | `grammar_a1_copula_negation`(A1) 매치 | 매처가 `이` 단독 조사 행에 엉뚱하게 흡수 |
| 조사 `이다` (1급) | missing_in_app | `grammar_a1_copula_polite`(A1) 매치 | 매처가 `이에요/예요` 패턴을 `이` 토큰과 연결 못함 |
| 표현 `-지 않다` (1급) | missing_in_app | `grammar_a1_long_negation`(A1) 매치 | 매처가 `V-지 않아요` 표면형을 원형과 매칭 못함 |
| 선어말어미 `-겠-` (1급) | missing_in_app | `grammar_a2_intention_guess`(A2, `V-겠어요`) 매치 — **레벨 불일치** | 매처가 `-겠-`(양쪽 하이픈)을 표면형과 매칭 못함 |
| 연결어미 `-고 나다`(3급, 참고) | missing_in_app | `grammar_a2_after_finishing`(A2, `V-고 나서`) 매치 | 동일 원인. 3급이라 이 표 범위 밖이지만 향후 B1 정본화 때 참고 |
| 표현 `-으면 좋겠다`(3급, 참고) | missing_in_app | `grammar_a2_preference_soft_batch20`(A2, `V-(으)면 좋겠어요`) 매치 | 동일 원인. 3급이라 범위 밖 |

F1이 "app_only"로 오분류했지만 실제로는 1급/2급에 대응하는 항목: 위 표의
`grammar_a1_copula_negation`·`grammar_a1_copula_polite`·
`grammar_a2_intention_guess`·`grammar_a2_after_finishing`이 F1의 app_only
목록에도 잘못 올라 있었다(F1.md 352행대).

F1이 동음이의 한글 음절 하나만 겹쳐도 교차 매치를 만드는 경우가 많다(예:
조사 `은1`이 전성어미 `-은2/-은3`용 앱 행까지 끌어옴, `조사 을1`이
`-을 뿐이다`류 B2/C1/C2 표현까지 끌어옴). 아래 표는 이런 가짜 교차를 모두
제거하고 문법적으로 진짜 같은 형태만 연결했다.

---

## 1. NIKL 1급 (45개) ↔ 앱

nikl csv 원래 순서(선어말어미 3·연결어미 6·조사 19·종결어미 8·표현 9)를
그대로 따른다.

### 1.1 선어말어미 (3)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -겠- | `grammar_a2_intention_guess` (V-겠어요, A2) | move_app_row_to:A1 | 의도·추측 기능이 A1치고 다소 무겁다는 반론 가능 — Fable 재검토 권장 |
| -었- (-았-,-였-) | `grammar_a1_polite_past` (V-았/었어요, A1) | match | |
| -으시- (-시-) | `grammar_b1_honorific_si` (V-(으)시-, B1) | move_app_row_to:A1 | 바이블 §B.1①이 "높임 기초(-으시-, 께서)를 인지·산출"을 A1 can-do로 명시 — 강한 근거 |

### 1.2 연결어미 (6)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -고3(나열) | `grammar_a1_sequence_connector` (V-고, A1) | match | nikl은 "나열" 의미만 표제, 앱은 "그리고 나서"(순서) 의미로 예시 — 동일 형태소, 화용 차이만 있음 |
| -어서(-아서,-여서,-어2,-아2,-여1,-라서,-라4) | `grammar_a2_cause_sequence` (V-아/어서, A2) | move_app_row_to:A1 | 바이블 §B.1⑤ "어조" 박스가 -고/-지만/-어서를 A1 상한 연결어미로 명시 |
| -으니까(-니까) | `grammar_a2_cause_nikka` (V-(으)니까, A2) | move_app_row_to:A1 | |
| -으러(-러) | `grammar_a1_motion_purpose` (V-(으)러, A1) | match | |
| -으려고1(-려고1,으려,려) | `grammar_b1_intention` (V-(으)려고, B1) | move_app_row_to:A1 | |
| -지만 | `grammar_a2_contrast` (V-지만, A2) | move_app_row_to:A1 | §B.1⑤ "어조" 박스 근거(위와 동일) |

### 1.3 조사 (19)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| 과(와) | `grammar_a1_with_connector` (N과/와/N(이)랑/N하고, A1) | match | |
| 까지 | `grammar_a1_from_to`(N에서 N까지)·`grammar_a1_from_until`(N부터 N까지), 둘 다 A1 | match | |
| 께서 | `grammar_b1_honorific_subject_kkeyseo` (N께서, B1) | move_app_row_to:A1 | §B.1①(위 -으시- 참고), -으시-와 짝 이동 |
| 도 | `grammar_a1_also_particle` (N도, A1) | match | |
| 만(단독) | `grammar_a1_only_particle` (N만, A1) | match | |
| 보다 | `grammar_a2_comparative` (N보다, A2) | move_app_row_to:A1 | 형태는 1급이나 비교문 구성이 A1치고 부담 — 재고 여지, Fable 판단 |
| 부터(에서부터/서부터 포함 표기) | `grammar_a1_from_until` (N부터 N까지, A1) | match | 이형태 "에서부터(서부터)"는 2급에도 별도 행으로 존재 — §2.3 참고 |
| 에 | `grammar_a1_direction_time_particle` (N에, A1) | match | |
| 에게 | `grammar_a2_dative_person` (N한테/에게, A2) | move_app_row_to:A1 | 한테(아래)와 같은 앱 행에 통합돼 있음 — 이동 시 둘 다 A1 |
| 에서 | `grammar_a1_action_location_particle` (N에서, A1) | match | |
| 으로(로) | `grammar_a1_direction_means` (N(으)로, A1) | match | |
| 은1(대조, 는1/ㄴ1) | `grammar_a1_topic_particle` (N은/는, A1) | match | `grammar_a1_topic_contrast`·`grammar_a1_service_location_question`은 같은 조사의 파생 활용이지 별도 nikl 항목 아님(표4 참고) |
| 을1(를/ㄹ1) | `grammar_a1_object_particle` (N을/를, A1) | match | `grammar_a1_service_request`는 파생 활용(표4 참고) |
| 의 | `grammar_a1_possessive_particle` (N의, A1) | match | |
| 이(가) | `grammar_a1_subject_particle` (N이/가, A1) | match | `grammar_a1_subject_new`는 파생 활용(표4 참고) |
| 이다(지정사) | `grammar_a1_copula_polite` (N이에요/예요, A1) | match | §0 정정 항목 |
| 이랑(랑) | `grammar_a1_with_connector` (포함, A1) | match | |
| 하고 | `grammar_a1_with_connector` (포함, A1) | match | |
| 한테 | `grammar_a1_spoken_dative` (N한테, A1) | match | `grammar_a2_dative_person`에도 중복 포함(에게 항목 참고) — 이동 시 중복 정리 검토 |

### 1.4 종결어미 (8)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -고4(덧붙여 서술, -고요) | (없음) | missing | 문장 종결 트레일링 -고요 전용 행 없음(연결어미 -고3과 형태소는 같지만 화용 다름). 저빈도 — 초안 우선순위 낮음 |
| -습니까(-ㅂ니까) | (없음) | missing | TASK3 초안 대상(공식 의문형, formal_statement의 짝) |
| -습니다(-ㅂ니다) | (없음) | missing | **TASK3 골든 샘플 `grammar_a1_formal_statement`가 이 항목** |
| -어2(반말,-아2,-여2,-야3,-어요,-아요,-여요,-에요) | `grammar_a1_polite_present` (V-아/어요, A1) | match | nikl 이형태에 반말(가./먹어.)까지 포함되나 §B.1⑥은 "반말은 A1에서 인지 안 함(A2 도입)"이라 정책 충돌 — 존댓말 하위형만 match 처리, 반말 하위형은 Fable 판단 필요 |
| -으세요(-세요 등) | `grammar_a1_polite_request` (V-(으)세요, A1) | match | |
| -으십시오(-십시오) | (없음) | missing | §B.1⑥ "인지만, 산출 보류" 정책 — TASK3 초안 대상 아님 |
| -을까(-ㄹ까,을까요,-ㄹ까요) | `grammar_a2_polite_proposal` (V-(으)ㄹ까요?, A2) | move_app_row_to:A1 | 브리프 명시 등가(-을까요=-을까). `grammar_a2_shall_we_time`도 같은 형태의 중복 앱 행(표4) — 같이 이동 검토 |
| -읍시다(-ㅂ시다) | `grammar_a2_lets_formal` (V-(으)ㅂ시다, A2) | move_app_row_to:A1 | 브리프 명시 등가 |

### 1.5 표현 (9)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -고 싶다 | `grammar_a1_want` (A1) | match | |
| -고 있다 | `grammar_a2_progressive` (V-고 있다, A2) | move_app_row_to:A1 | nikl 1급 명시 — 강한 이동 후보 |
| -기 전에(-기 전) | `grammar_b1_before` (B1) | move_app_row_to:A1 | |
| -어야 되다(-아야 되다 등, 유의 -어야 하다) | `grammar_b1_obligation` (V-아/어야 하다, B1) | move_app_row_to:A1 | 하다/되다 유의어 관계 — app_variant_of 관계이자 레벨 이동 |
| -은 후에(-은 후 등) | `grammar_b1_after` (B1) | move_app_row_to:A1 | |
| -을 수 있다(-ㄹ 수 있다, 반의 -을 수 없다) | `grammar_a2_ability` (A2) | move_app_row_to:A1 | |
| -지 못하다 | `grammar_a2_inability` (A2) | move_app_row_to:A1 | |
| -지 않다 | `grammar_a1_long_negation` (A1) | match | §0 정정 항목 |
| 이 아니다(가 아니다) | `grammar_a1_copula_negation` (A1) | match | §0 정정 항목 |

**1급 소계 — match 24 · move_app_row_to:A1 17 · missing 4 (계 45)**

---

## 2. NIKL 2급 (45개) ↔ 앱

nikl csv 원래 순서(연결어미 6·전성어미 6·조사 10·종결어미 6·표현 17).

### 2.1 연결어미 (6)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -거나 | `grammar_a2_or_verbs` (V-거나, A2) | match | |
| -게2(목적) | `grammar_a2_adverbial` (A-게, A2) | match | nikl "목적"(동사+게, ~하게) 의미는 부분적으로만 겹침 — 앱 행은 형용사→부사 파생(짧게) 위주. 형태소 동일, 저빈도 갭이라 새 행 불필요 |
| -는데1(대립·배경) | `grammar_b1_background_contrast` (V-는데, B1) | move_app_row_to:A2 | 종결어미 -는데2(§2.4)와 같은 앱 행으로 통합 처리됨 |
| -다가1(1)(중단) | (없음) | missing | TASK3 초안 후보 |
| -으면(가정) | `grammar_a2_conditional` (A2) | match | `grammar_a2_available_if`는 중복 앱 행(표4) |
| -으면서 | `grammar_a2_simultaneous` (A2) | match | |

### 2.2 전성어미 (6)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -기(명사형) | `grammar_b1_nominalizer_gi` (V-기, B1) | move_app_row_to:A2 | |
| -는2(관형사형 현재, -은3/ㄴ3) | `grammar_a1_present_modifier` (V-는 N, **A1**) | move_app_row_to:A2 | **move-up** — 브리프 명시. §3 시나리오 영향 없음 |
| -은2(관형사형 과거, ㄴ4) | `grammar_a1_past_modifier` (V-(으)ㄴ N, **A1**) | move_app_row_to:A2 | **move-up** — 브리프 명시. §3 시나리오 영향 없음 |
| -은3(과거, 뜻풀이 공란) | 〃 `grammar_a1_past_modifier`와 동일 앱 행 | move_app_row_to:A2 | nikl이 -은2와 별도 표제어로 등재했으나 기능은 동일 — 앱은 이미 한 행으로 통합 |
| -을2(관형사형, ㄹ2) | `grammar_a1_future_modifier` (V-(으)ㄹ N, **A1**) | move_app_row_to:A2 | **move-up** — 브리프 명시. §3 시나리오 영향 없음 |
| -음(명사형, ㅁ) | (없음) | missing | TASK3 초안 후보(단, A2치고 체감 난도 높음 — 빈도 낮게 취급) |

### 2.3 조사 (10)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| 께 | `grammar_a1_honorific_kke` (N께, **A1**) | move_app_row_to:A2 | **move-up** — 브리프 명시. §3 시나리오 영향 있음(`a1_w10_partner`) |
| 마다 | `grammar_a2_each` (A2) | match | |
| 밖에 | `grammar_a2_only_negative` (A2) | match | |
| 에게로 | (없음) | missing | 저빈도(문어체) — 초안 우선순위 낮음 |
| 에게서 | (없음) | missing | 한테서(아래)와 묶어 TASK3에 1행으로 초안 |
| 에다가(에다) | (없음) | missing | 저빈도 — 초안 우선순위 낮음 |
| 에서부터(서부터) | (없음, 근사) | missing | `grammar_a1_from_until`(부터...까지)과 기능 근접 — 신규 행보다는 기존 부터 항목의 이형태 언급으로 충분, 초안 비권장 |
| 이나(나1) | `grammar_a1_or_particle` (N(이)나, **A1**) | move_app_row_to:A2 | **move-up** — 브리프 명시. §3 시나리오 영향 있음(`a1_w10_fandom`) |
| 처럼 | `grammar_a2_like` (N처럼/같이, A2) | match | |
| 한테서 | (없음) | missing | 에게서(위)와 묶어 TASK3에 1행으로 초안(`N한테서/에게서`, 기존 `grammar_a2_dative_person`의 한테/에게 통합 방식과 동일 패턴) |

### 2.4 종결어미 (6)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -네(감탄, -네요) | `grammar_a2_exclamation` (V-네요, A2) | match | |
| -는군(-군,-는군요 등) | `grammar_b1_realization` (V-군요/는군요, B1) | move_app_row_to:A2 | |
| -는데2(감탄, 종결 -는데요 등) | `grammar_b1_background_contrast`(위 2.1과 동일 앱 행) | move_app_row_to:A2 | 연결어미 -는데1과 앱에서 한 행으로 통합 — 이동은 1회로 양쪽 다 해결 |
| -을게(-ㄹ게 등) | `grammar_a2_promise` (A2) | match | |
| -을래(-을래요 등) | `grammar_a2_preference_question` (A2) | match | |
| -지(서술/물음/명령/요청, -지요) | `grammar_a2_tag_confirmation` (V-지요?, A2) | match | "물음"(확인 질문) 의미만 모델링됨 — 평서·명령 의미의 -지는 갭이나 구어 등급이 낮아 신규 행 비권장 |

### 2.5 표현 (17)

| nikl form(이형태) | app id (pattern, 레벨) | verdict | note |
|---|---|---|---|
| -게 되다 | `grammar_a2_change` (A2) | match | |
| -기 때문에(-기 때문이다) | `grammar_a2_reason_because` (A2) | match | `grammar_a2_noun_cause`(N때문에)는 명사 직결형 파생(표4) |
| -기로 하다 | `grammar_b1_decision` (B1) | move_app_row_to:A2 | |
| -는 것(-은 것 등) | `grammar_b1_nominalization` (V-는 것, B1) | move_app_row_to:A2 | |
| -는 것 같다(-ㄴ/은/을 것 같다) | `grammar_a2_probability` (A2) | match | 미래형 하위 변이는 `grammar_b1_future_probability`(B1)로 별도 존재 — 겹치나 자동 이동 대상 아님, Fable 재량 |
| -는 동안에(-는 동안) | `grammar_b1_duration` (B1) | move_app_row_to:A2 | |
| -어 보다(-아/여 보다) | `grammar_a2_try_experience` (A2) | match | |
| -어 있다(-아/여 있다) | `grammar_b1_resultant_state` (B1) | move_app_row_to:A2 | |
| -어 주다(-아/여 주다) | `grammar_a2_favor` (A2) | match | |
| -어도 되다(-아도/여도 되다) | `grammar_a2_permission` (A2) | match | `grammar_a2_permission_check_batch20`(괜찮아요? 유의어)은 파생(표4) |
| -은 적이 있다(반의 -은 적이 없다) | `grammar_b1_experience` (B1) | move_app_row_to:A2 | |
| -은 지2(-ㄴ 지2) | `grammar_b1_since` (V-(으)ㄴ 지, B1) | move_app_row_to:A2 | |
| -을 것1(명령/지시) | (없음) | missing | 표지판·공문 지시체(격식 문어) — 회화 앱 정체성과 부딪혀 초안 비권장, Fable 판단 |
| -을 때(-ㄹ 때) | `grammar_a2_when` (A2) | match | |
| -을 수밖에 없다 | (없음) | missing | TASK3 초안 후보(체감 빈도·유용성 중간) |
| -을까 보다 | (없음) | missing | TASK3 선택 초안 후보(기존 -겠어요/-을래요와 의미 근접, 우선순위 낮음) |
| -지 말다 | `grammar_a1_polite_prohibition` (V-지 마세요, **A1**) | move_app_row_to:A2 | **move-up** — 브리프 명시. §3 시나리오 영향 없음 |

**2급 소계 — match 18 · move_app_row_to:A2 17 · missing 10 (계 45)**

---

## 3. Move-up 후보(A1→A2)가 걸친 A1 시나리오

`move_app_row_to:A2`이면서 현재 앱 레벨이 A1인 6개 행만 해당(B1→A2 이동은
레벨이 내려가므로 A1 시나리오에 영향 없음). `scenarios_a1.json`
`grammarIds`를 전수 조회한 결과:

| app id | nikl 출처 | 참조하는 A1 시나리오 |
|---|---|---|
| `grammar_a1_present_modifier` | 전성어미 -는2 | (없음) |
| `grammar_a1_past_modifier` | 전성어미 -은2/-은3 | (없음) |
| `grammar_a1_future_modifier` | 전성어미 -을2 | (없음) |
| `grammar_a1_honorific_kke` | 조사 께 | `a1_w10_partner` |
| `grammar_a1_or_particle` | 조사 이나 | `a1_w10_fandom` |
| `grammar_a1_polite_prohibition` | 표현 -지 말다 | (없음) |

4/6은 A1 시나리오 참조가 전혀 없어 이동이 자유롭다. 나머지 2건
(`a1_w10_partner`, `a1_w10_fandom`)은 이동 후 grammarIds가 A2를 가리키게
되므로 "시나리오 grammarIds ≤ 시나리오 레벨" 규칙(§D) 위반 — Fable이
① 두 시나리오도 함께 A2로 승격하거나 ② 두 grammarIds만 이동을 보류하거나
③ 두 시나리오의 grammarIds 참조를 제거하는 중 하나를 선택해야 한다.

**Fable 룰링(2026-09-07, F1b):** 두 시나리오 모두 grammarIds를 그대로
유지한다(①·③ 기각). `a1_w10_partner`→`grammar_a1_honorific_kke`,
`a1_w10_fandom`→`grammar_a1_or_particle` 참조는 인지 용도(recognition
use)로 남기고, 시나리오 레벨(A1) 대비 grammarId 레벨(A2)이 +1 앞서는
상태는 감사 도구(`tool/audit_content_levels.py`)가 허용하는 오차 범위로
간주해 그대로 둔다. `relevel_bundle_L2b.json` 적용 시 두 시나리오 모두
경고(WARNING)로만 보고되고 실패하지 않는다 — 의도된 결과.

---

## 4. 앱 A1/A2 행 중 NIKL 1급/2급에 없는 것

91개 앱 A1/A2 행 중 위 두 표에서 이미 다룬 63개(match+move 대상)를 제외한
28개. `keep-as-app-specific`(순수 앱 고유, 유지) / `move_up:<level>`(3급+
근거 있으나 이번 범위 밖) / `app_variant_of:<nikl 2급 이하 형태>`(파생형,
레벨 그대로 유지) 로 분류.

| app id (pattern, 레벨) | verdict | note |
|---|---|---|
| `grammar_a1_short_negation` (안+V, A1) | keep-as-app-specific | nikl은 부사 안을 문법 표제어로 안 다룸 |
| `grammar_a1_cannot_short` (못+V, A1) | keep-as-app-specific | 위와 동일 사유, short_negation과 짝 |
| `grammar_a1_which_question` (무슨/어떤, A1) | keep-as-app-specific | 의문사, nikl 문법표 비대상 |
| `grammar_a1_degree_question` (얼마나, A1) | keep-as-app-specific | 위와 동일 |
| `grammar_a1_please_particle` (좀, A1) | keep-as-app-specific | 정도부사, nikl 문법표 비대상 |
| `grammar_a1_approx` (N쯤, A1) | keep-as-app-specific | 접미사성 표현, nikl 비대상 |
| `grammar_a1_duration_span` (N동안, A1) | app_variant_of:`-는 동안에`(2급) | 명사 직결형 파생 — 레벨은 A1 유지해도 무방(단순 명사+명사) |
| `grammar_a1_come_purpose` (V-(으)러 오다, A1) | app_variant_of:`-으러`(1급) | -으러의 예시 collocation, 별도 표제어 아님 |
| `grammar_a1_in_front` (N앞에, A1) | keep-as-app-specific | 명사+조사 조합, nikl 비대상 |
| `grammar_a1_topic_contrast` (N은/는,N은/는, A1) | app_variant_of:`은1`(1급) | 조사 은/는의 대조 나열 활용 |
| `grammar_a1_subject_new` (누가? N이/가, A1) | app_variant_of:`이`(1급) | 조사 이/가의 신정보 활용 |
| `grammar_a1_service_location_question` (N은/는 어디에 있어요?, A1) | app_variant_of:`은1`(1급) | 관용구형 활용 |
| `grammar_a1_service_request` (N을/를 V-아/어 주세요, A1) | keep-as-app-specific(Fable 룰링 2026-09-07) | 표면상 -세요(1급)이나 실질은 -어 주다(2급)의 명령형 — 세종 1 "주세요" 요청 관용구로 A1 유지 확정(F9 app_only 표에 사유 기록) |
| `grammar_a2_future_intention` (V-(으)ㄹ 거예요, A2) | app_variant_of:`을2`(2급)+`이다`(1급) | 전성어미 을2 + 이다의 합성, 별도 표제어 아님. 이미 A2로 을2의 새 레벨과 일치 |
| `grammar_a2_recommendation` (V-아/어 보세요, A2) | app_variant_of:`-어 보다`(2급)+`-으세요`(1급) | 합성형, 이미 A2로 -어 보다 레벨과 일치 |
| `grammar_a2_noun_cause` (N때문에, A2) | app_variant_of:`-기 때문에`(2급) | 명사 직결형, 이미 A2로 레벨 일치 |
| `grammar_a2_in_progress` (N중/V-는 중, A2) | keep-as-app-specific | "중"은 일반명사, nikl 비대상 |
| `grammar_a2_among_set` (N중에서, A2) | app_variant_of:`에서`(1급)+명사 중 | 합성형, nikl 비대상 |
| `grammar_a2_irregular_eu`·`_bieup`·`_digeut`·`_rieul` (4행, A2) | keep-as-app-specific | 불규칙 활용 규칙(맞춤법), nikl 문법 표제어 체계 밖 — 앱 고유 스캐폴딩으로 유지 |
| `grammar_a2_shall_we_time` (같이 V-(으)ㄹ까요?, A2) | app_variant_of:`-을까`(1급) | `grammar_a2_polite_proposal`과 동일 형태 중복 — 그쪽이 A1으로 이동하면 일관성 위해 같이 검토 |
| `grammar_a2_available_if` (V-(으)면, S, A2) | app_variant_of:`-으면`(2급) | `grammar_a2_conditional`과 사실상 중복 — 레벨은 이미 일치, 통합 검토는 선택 사항 |
| `grammar_a2_permission_check_batch20` (V-아/어도 괜찮아요?, A2) | app_variant_of:`-어도 되다`(2급, 유의어) | 레벨 이미 일치 |
| `grammar_a2_purpose` (V-기 위해서, A2) | move_up:B1(참고) | 실제로는 nikl **3급** 항목 — 이번 1~2급 표 범위 밖. A2 배치가 nikl 대비 낮음(단순화된 배치로 보임), 이번 phase에서 손대지 않음 |
| `grammar_a2_prohibition` (V-(으)면 안 되다, A2) | move_up:B1(참고) | nikl 3급 — 범위 밖, 참고만 |
| `grammar_a2_after_finishing` (V-고 나서, A2) | move_up:B1(참고) | nikl 3급 `-고 나다` — §0 정정, 범위 밖 |
| `grammar_a2_gentle_question` (A-(으)ㄴ가요?/V-나요?, A2) | move_up:B2(참고) | nikl 매처가 4급 `-나3`에 연결 — 앱 A2 배치가 nikl 대비 상당히 낮음, 향후 재검토 후보로만 기록 |
| `grammar_a2_become` (A-아/어지다, A2) | move_up:B1(참고) | nikl 3급 — 범위 밖 |
| `grammar_a2_humble_give` (V-아/어 드리다, A2) | move_up:B1(참고) | nikl 3급 — 범위 밖 |
| `grammar_a2_busy_cause` (V-느라고, A2) | move_up:B1(참고) | nikl 3급이나 매처가 이미 "match" 판정(B1 자매 행 `grammar_b1_negative_cause` 존재) — 범위 밖, 조치 불요 |
| `grammar_a2_spoken_result` (V-아/어 가지고, A2) | move_up:B1(참고) | nikl 3급 — 범위 밖 |
| `grammar_a2_preference_soft_batch20` (V-(으)면 좋겠어요, A2) | move_up:B1(참고) | §0 정정, nikl 3급 — 범위 밖 |

---

## 5. 요약

| 구분 | match | move_app_row_to | missing | 계 |
|---|---|---|---|---|
| 1급(45) | 24 | 17 (→A1) | 4 | 45 |
| 2급(45) | 18 | 17 (→A2, 그중 move-up 6) | 10 | 45 |
| **1+2급 합계** | **42** | **34** | **14** | **90** |

표4(앱 전용/범위 밖): 28행 — keep-as-app-specific 13 · app_variant_of(레벨
유지) 8 · 판단 보류 1 · move_up 참고(3급+, 이번 범위 밖) 6.

**적용 후(2026-09-07, PR-L2b phase 2 실행 결과 — `relevel_bundle_L2b.json`
32건 이동 + 결손 문법 8행 신규 추가, `docs/data/relevel_L2b_report.md` 참고):**

| 구분 | match | level_mismatch | missing_in_app | 계 |
|---|---|---|---|---|
| 1급(45), 적용 전 | 22 | 16 | 7 | 45 |
| 1급(45), 적용 후 | 40 | **0** | 5 | 45 |
| 2급(45), 적용 전 | 17 | 16 | 12 | 45 |
| 2급(45), 적용 후 | 37 | **0** | 8 | 45 |

이동은 계획한 34건(17+17) 중 32건(17→A1, 15→A2)만 승인됐다 — 나머지는
이번 phase 범위 밖으로 보류(§6.6 저빈도 조사·표현 중 4종은 룰링 (5)로
skip). level_mismatch는 1·2급 모두 0으로 해소. missing_in_app 잔여분
(1급 5·2급 8)은 대부분 §0/F1 매처의 알려진 한계(문자열 교집합 방식이라
동형이의 `다가`처럼 다른 형태소와 오매칭되는 경우 포함) 또는 이번
phase 범위 밖 항목(-겠-, 이다, 이 아니다, -지 않다, 에게로/에다가/
에서부터, -을 것1, -지 말다 등) — F1_grammar_map.md가 최신 상세.

## 6. 열린 질문(Fable 룰링 필요)

1. `-으시-`/`께서` A1 하향(2건)과 `께`/`이나`/관형사형 3종/`-지 말다` A2
   상향(6건, move-up)을 동시에 승인할 것인가 — 특히 상향 2건은 A1 시나리오
   `a1_w10_partner`·`a1_w10_fandom` 처리 방침 결정 필요(§3).
2. `-겠-`(A1 이동), `보다`(A1 이동)은 형태상 1급이나 체감 난도 논쟁 여지 —
   승인/보류/A2 유지 중 선택.
3. `-어2`의 반말 하위형이 §B.1⑥ 정책(반말=A2 도입)과 충돌 — 정책 문구를
   수정할지, nikl 이형태 목록에서 반말을 열외로 각주할지.
   **Fable 룰링(2026-09-07):** 정책 문구는 그대로 유지 — 반말 종결
   -어(NIKL 1급 이형태)는 A1에서 유닛 a1_13(register_switching)에 한해
   **인지**만 다루고, **산출**은 그대로 A2에서 시작한다(docs/
   CONTENT_LEVEL_BIBLE.md §B.1⑥에 동일 각주 반영).
4. `-으십시오`는 정책상 산출 보류(§B.1⑥) — TASK3 초안에서 제외했다. 이대로
   둘지, 인지용 참고 카드로라도 추가할지.
5. `grammar_a1_service_request`(N을/를 V-아/어 주세요)를 A1 관용구 특례로
   유지할지, A2로 옮길지.
   **Fable 룰링(2026-09-07):** A1 유지 — 세종 1급 "주세요" 요청 관용구,
   앱 전용(app-specific)으로 확정(§4, F9 app_only 표 반영).
6. 저빈도 2급 조사 4종(에게로·에게서·에다가·에서부터)과 표현 3종(을 것1·
   을 수밖에 없다·을까 보다)을 TASK3에서 초안할지 — 본 문서는 에게서/한테서
   1건만 병합 초안하고 나머지는 보류 권고.
