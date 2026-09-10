# 한국어 Learning Phase 체계 — PART 5 · B2

생성물이다. `python tool/audit_learning_phases.py` 로 다시 만든다. 정본은 `tools/content_factory/cefr_matrix/phases.json`.
전체 색인은 `korean_learning_phases_part5_phases.md`.

Phase 30개 · 레벨당 A1 4 · A2 4 · B1 5 · B2 5 · C1 6 · C2 6

각 Phase 는 16개 필드를 모두 채운다. 문법의 `[OFFICIAL]` 표시는 국립국어원 국제 통용 한국어 표준 교육과정(2017)
문법 목록(저장소 CSV, 공공누리 제1유형)에 그 형태가 그대로 있다는 뜻이다. 336개 급·형태 쌍 전부가 어느 Phase 에 새로
도입되는지 기계 검사로 고정되어 있다 — 누락·중복이 있으면 빌드가 실패한다.
기능 설명·예문·Phase 배치는 PEDAGOGICAL이며, OFFICIAL 표지가 이 저작 부분까지 검증하지 않는다.

## 목차

| # | Phase | 레벨 | 핵심 목표 |
|---|---|---|---|
| 14 | `KP14` B2.1 — 자료·정의·역할을 설명하기 | B2 | 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. |
| 15 | `KP15` B2.2 — 원인과 영향을 평가해 보고하기 | B2 | 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. |
| 16 | `KP16` B2.3 — 가정·양보·선택 범위를 논의하기 | B2 | 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. |
| 17 | `KP17` B2.4 — 인용을 확인하고 오해를 바로잡기 | B2 | 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. |
| 18 | `KP18` B2.5 — 논거를 종합하고 결론의 강도를 조절하기 | B2 | 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. |

## B2

사회적 주제를 논리적으로 토론한다. 왜 그런지 설명하고, 다른 관점과 비교하고, 자신의 입장을 방어한다. 복합 비교·판단·원인 평가·정도 표현·논증 표현과 피동·사동을 본격적으로 쓴다.

### 14. KP14 · B2.1 — 자료·정의·역할을 설명하기

- **EN** Explain data, definitions and roles · **DE** Daten, Begriffe und Rollen erklären
- **핵심 의사소통 목표** 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다.
  - EN: Explain the basis, comparisons and definitions in information and distinguish an actor's capacity from the means used.
  - DE: Grundlagen, Vergleiche und Definitionen in Materialien erläutern und Rolle und eingesetztes Mittel unterscheiden.
- **배치 근거** 336 원 인벤토리의 급을 유지한 프로젝트 Phase 배정이다. 내부 순서는 의존 노트를 검토한 교수 판단이며 CEFR·TOPIK의 공식 환산을 뜻하지 않는다.

**1 주제 (Topics)**
- 기술·디지털·AI·데이터 (`technology_digital_ai`) — 기술·AI 생성물·개인정보
- 교육·학교·학습 (`education_study`) — 교육제도
- 과학·연구·근거·통계 (`science_research_evidence`) — 과학·근거·지표 해석 기초
- 정치·법·제도·행정 (`politics_law_institutions`) — 제도·법적 절차·과태료 이의·행정
- 돈·요금·계약·보험 (`money_finance_contracts`) — 계약 범위·환불 협의·수리비 책임
- 공공 서비스·관공서·은행·우체국 (`services_public_admin`) — 공식 문의·민원·관공서

**2 한국어 문법 (실제 형태)**

| 형태 | 범주 | 기능 | 예문 | 근거 | 앱 문법 id |
|---|---|---|---|---|---|
| -는지 | 연결어미 | 의문 내용을 문장 안에 넣기 | 어떤 방법이 적절한지 함께 검토합시다. — Let us examine together which method is appropriate. | [OFFICIAL] | — |
| -듯이 | 연결어미 | 행동·모습을 다른 것에 빗대기 | 앞에서 설명했듯이 조건을 먼저 확인해야 합니다. — As explained earlier, we need to check the conditions first. | [OFFICIAL] | — |
| -으며 | 연결어미 | 격식 있게 동시성·나열을 연결하기 | 이 자료는 무료이며 누구나 이용할 수 있습니다. — These materials are free and available to everyone. | [OFFICIAL] | — |
| 이며 | 조사 | 명사들을 격식 있게 나열하기 | 회의에는 학생이며 교사며 모두 참여했습니다. — Students and teachers alike took part in the meeting. | [OFFICIAL] | — |
| 으로서 | 조사 | 행위자의 자격·역할을 밝히기 | 담당자로서 결과를 설명드리겠습니다. — I will explain the results in my capacity as the person responsible. | [OFFICIAL] | — |
| 으로써 | 조사 | 결과를 이루는 수단·방법을 밝히기 | 대화로써 갈등을 줄일 수 있습니다. — We can reduce conflict through dialogue. | [OFFICIAL] | — |
| 이란 | 조사 | 용어의 뜻·범위를 정의하기 | 협력이란 서로의 역할을 존중하는 일입니다. — Cooperation means respecting each other's roles. | [OFFICIAL] | — |
| 에 따라 | 표현 | 기준·조건에 따라 달라짐을 설명하기 | 참가 인원에 따라 장소를 바꿉니다. — We change the venue depending on the number of participants. | [OFFICIAL] | — |
| 에 비하여 | 표현 | 격식 있게 비교 기준을 제시하기 | 지난해에 비하여 참여가 늘었습니다. — Participation has increased compared with last year. | [OFFICIAL] | — |
| -을수록 | 연결어미 | 변화의 정도에 비례하는 경향을 설명하기 | 자세히 살펴볼수록 차이가 분명해집니다. — The closer we look, the clearer the differences become. | [OFFICIAL] | — |

**3 의사소통 기능 (Sprachhandlungen)**
- 용어 정의·개념 구분하기 (`define_distinguish_terms`) — 개념의 경계·포함·제외 기준을 정하고 유사 개념과 구별한다.
- 대화 열고 닫기·범위 정하기 (`structure_discourse_open_close_scope`) — 논의의 범위·순서·전환·결론을 독자나 청자에게 표시한다.
- 비교·대조·대안 검토하기 (`compare_contrast_alternatives`) — 같은 기준으로 두 대안을 비교하고 빠진 기준을 확인한다.
- 요청·부탁하기 (`request_ask_someone_to_do`) — 요청 대상·부담·조건을 명확히 하고 상대가 응답할 여지를 남긴다.

**4 어휘 영역**
- 사회·경제·추상 명사 (`society_economy_abstract_nouns`) — 제도(), 고용(), 소비(), 격차() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다.
- 제도·법률·행정 담화 어휘 (`institutional_legal_lexis`) — 권한(), 책임(), 조항(), 예외() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다.
- 논증·평가·근거 어휘 (`argumentation_evaluation_lexis`) — 근거(), 반론(), 타당성(), 한계() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다.

**5 텍스트 유형 (Textsorten)**
- 보고서·제안서·공식 문서 (`report_proposal_official`, R/P) — 수용: 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. 산출: 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. 판정: 확인된 결과와 권고·예측을 구별한다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 계약서·약관·법률 텍스트 (`contract_terms_legal_text`, R) — 수용: 계약·약관의 적용 대상·권리·의무·예외를 대조한다. 판정: 법적 효력을 새로 판단하지 않고 주어진 문언 범위를 설명한다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 발표·브리핑 (`presentation_briefing_talk`, P) — 산출: 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. 판정: 질문에서 모르는 정보는 확인 과제로 남긴다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다.

**6 듣기**
- 자료 설명을 듣고 정의·역할·방법·변수 간 변화를 구분한다. — *evidence_sorting* · 으로서와 으로써, 비례와 단순 동시 발생을 구별한다.

**7 말하기**
- 표의 기준을 정의하고 자료를 만든 방법을 설명한 뒤 모르는 부분을 질문한다. — *scene_roleplay* · 정의의 범위를 유지하고 수치 관계를 인과로 과장하지 않는다.
- 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. — *genre_production* · 질문에서 모르는 정보는 확인 과제로 남긴다.

**8 읽기**
- 보고서와 약관의 용어 정의를 읽고 적용 대상·수단·예외를 표시한다. — *genre_analysis* · 같은 명사의 역할과 수단 용법을 근거 문장으로 설명한다.
- 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. — *genre_reception* · 확인된 결과와 권고·예측을 구별한다.
- 계약·약관의 적용 대상·권리·의무·예외를 대조한다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. — *genre_reception* · 법적 효력을 새로 판단하지 않고 주어진 문언 범위를 설명한다.

**9 쓰기**
- 자료의 정의·수집 방법·비교 결과를 소제목이 있는 설명으로 작성한다. — *genre_production* · 용어 정의를 일관되게 사용하고 자료로 알 수 없는 점을 밝힌다.
- 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. Phase 연결: 자료의 기준·비교·정의를 설명하고 행위자의 자격과 사용한 수단을 구별한다. — *genre_production* · 확인된 결과와 권고·예측을 구별한다.

**10 발음·음운**
- 정의·목록·비례 구조의 억양구 — 대조: 전문 용어마다 끊어 논항과 술어의 관계를 잃지 않는다. · 연습: A란/…이며/…에 따라 달라진다의 정보 단위를 표시해 발표한다.
- 의미 단위와 청자 반응을 보존하는 억양 — 대조: 모어의 강세·휴지 패턴을 한국어의 필수 규칙으로 투사하지 않는다. · 연습: 해당 Phase 말하기 과제를 녹음해 의미가 달라지는 휴지·말끝을 표시하고, 원래 화행을 유지하도록 다시 말한다.

**11 화용·문체 (Pragmatics & Register)**
- 문체: 합쇼체·업무 격식, 해요체(공손 비격식)
- 공손: 전문가가 동료·비전문 청중에게 자료를 설명한다. 정의와 요청의 청중은 별도 표시한다.
- 체면 관리: 상대의 선택권·확인 기회를 보존한다. 내용의 출처·책임과 공손한 말끝을 별개로 판단한다.
- 담화표지: 제 생각에는, 다만
- ⚠️ 말끝만 바꾸며 사실·확신·의무 강도까지 바꾸지 않는다.
- ⚠️ 관계가 명시되지 않은 사람의 성별·나이·직위를 새로 정하지 않는다.

**12 선수 조건 (Prerequisites)**
- 선행 Phase: KP13
- 선행 형태: —
- 이유: 직전 Phase의 숙달 과제를 바탕으로 정보·관계·출처를 유지하며 다음 과제로 확장한다. 별도 문법 파생 관계를 주장하지 않는다.

**13 EN → KO 브리지**
- 영어 CEFR 레벨: B2
- 앵커: `whether/what; as if; while; and` · 내포 의문에 직접 질문 도치를 복사하지 않고 -는지가 묻는 변수를 찾는다.
- 앵커: `as; by means of; is defined as` · as 하나로 자격과 비유를 합치지 않고 방법은 by means of와 비교한다.
- 앵커: `depending on; compared with; the more` · the more 구조의 반복 형식을 한국어에 그대로 복사하지 않고 두 변수의 방향을 확인한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. 내포 의문에 직접 질문 도치를 복사하지 않고 -는지가 묻는 변수를 찾는다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**14 DE → KO 브리지**
- 독일어 CEFR 레벨: B2
- 앵커: `ob/was; wie; während; und` · ob절의 동사 후치는 참고점이지만 한국어의 모든 종속절 구조가 독일어와 같은 것은 아니다.
- 앵커: `als; mittels; wird definiert als` · als와 mittels의 기능 차이를 발판으로 삼고 이란을 독일어 관사로 풀이하지 않는다.
- 앵커: `je nach; im Vergleich; je mehr` · je…desto는 좋은 기능 비교점이나 독일어 비교급 형태를 한국어 -을수록에 붙이지 않는다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. ob절의 동사 후치는 참고점이지만 한국어의 모든 종속절 구조가 독일어와 같은 것은 아니다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**15 전이 경고 (Transfer Warning)**
- **EN** [partial] 의문 내용의 내포와 명사·술어 목록의 결합 대상을 구별한다. 내포 의문에 직접 질문 도치를 복사하지 않고 -는지가 묻는 변수를 찾는다.
- **DE** [partial] 의문 내용의 내포와 명사·술어 목록의 결합 대상을 구별한다. ob절의 동사 후치는 참고점이지만 한국어의 모든 종속절 구조가 독일어와 같은 것은 아니다.
- **EN** [partial] 으로서의 자격과 으로써의 수단, 이란의 정의를 분리한다. as 하나로 자격과 비유를 합치지 않고 방법은 by means of와 비교한다.
- **DE** [partial] 으로서의 자격과 으로써의 수단, 이란의 정의를 분리한다. als와 mittels의 기능 차이를 발판으로 삼고 이란을 독일어 관사로 풀이하지 않는다.
- **EN** [positive] 비례는 인과를 자동 보증하지 않고 에 따라는 분류 기준이나 변화를 표시한다. the more 구조의 반복 형식을 한국어에 그대로 복사하지 않고 두 변수의 방향을 확인한다.
- **DE** [positive] 비례는 인과를 자동 보증하지 않고 에 따라는 분류 기준이나 변화를 표시한다. je…desto는 좋은 기능 비교점이나 독일어 비교급 형태를 한국어 -을수록에 붙이지 않는다.

**16 숙달 점검 (Mastery Check)**
1. [듣기] 자료 설명을 듣고 정의·역할·방법·변수 간 변화를 구분한다.
   - 합격 기준: 으로서와 으로써, 비례와 단순 동시 발생을 구별한다.
2. [말하기] 표의 기준을 정의하고 자료를 만든 방법을 설명한 뒤 모르는 부분을 질문한다.
   - 합격 기준: 정의의 범위를 유지하고 수치 관계를 인과로 과장하지 않는다.
3. [읽기] 보고서와 약관의 용어 정의를 읽고 적용 대상·수단·예외를 표시한다.
   - 합격 기준: 같은 명사의 역할과 수단 용법을 근거 문장으로 설명한다.
4. [쓰기] 자료의 정의·수집 방법·비교 결과를 소제목이 있는 설명으로 작성한다.
   - 합격 기준: 용어 정의를 일관되게 사용하고 자료로 알 수 없는 점을 밝힌다.

---

### 15. KP15 · B2.2 — 원인과 영향을 평가해 보고하기

- **EN** Assess and report causes and consequences · **DE** Ursachen und Folgen bewerten und darstellen
- **핵심 의사소통 목표** 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다.
  - EN: Reconstruct sequences and unintended outcomes and distinguish responsibility and evaluation encoded in causal expressions.
  - DE: Abläufe und unbeabsichtigte Folgen rekonstruieren und Verantwortung und Wertung in Kausalausdrücken unterscheiden.
- **배치 근거** 336 원 인벤토리의 급을 유지한 프로젝트 Phase 배정이다. 내부 순서는 의존 노트를 검토한 교수 판단이며 CEFR·TOPIK의 공식 환산을 뜻하지 않는다.

**1 주제 (Topics)**
- 환경·기후·지속가능성 (`environment_sustainability`) — 환경·기후·자원
- 경제·기업·노동시장 (`economy_business_labour`) — 경제생활·소비문화·프리랜서 단가
- 직업·직장·취업 (`work_career`) — 직업과 노동·면접·회의·협상
- 건강·신체·병원·약국 (`health_body`) — 건강정책·약 부작용·건강 시스템
- 동네·이웃·주변 환경 (`neighbourhood_environment`) — 동네 행사 소음·공용 공간 갈등
- 주거·집 (`house_home`) — 퇴거·수리비 협의

**2 한국어 문법 (실제 형태)**

| 형태 | 범주 | 기능 | 예문 | 근거 | 앱 문법 id |
|---|---|---|---|---|---|
| -더니 | 연결어미 | 관찰한 변화·앞뒤 결과를 이어 말하기 | 아침에는 비가 오더니 오후에는 맑아졌어요. — It was raining in the morning, but the afternoon cleared up. | [OFFICIAL] | — |
| -고서 | 연결어미 | 앞 행동의 완료 뒤 다음 일을 연결하기 | 자료를 확인하고서 의견을 냈어요. — I checked the materials before giving my opinion. | [OFFICIAL] | — |
| -기에 | 연결어미 | 판단·행동을 하게 한 이유를 제시하기 | 설명이 부족하기에 다시 물었습니다. — The explanation was insufficient, so I asked again. | [OFFICIAL] | — |
| -는 바람에 | 표현 | 뜻밖의 원인이 초래한 결과를 말하기 | 기차가 늦는 바람에 약속에 늦었어요. — The train was delayed, which made me late for the appointment. | [OFFICIAL] | — |
| -는 탓에 | 표현 | 부정적 결과의 책임·원인을 부여하기 | 준비가 부족한 탓에 진행이 늦어졌어요. — The proceedings were delayed because preparation was inadequate. | [OFFICIAL] | — |
| -는 통에 | 표현 | 어수선한 원인이 초래한 결과를 말하기 | 모두 한꺼번에 말하는 통에 들을 수가 없었어요. — Everyone was talking at once, so I could not hear. | [OFFICIAL] | — |
| 으로 인하여 | 표현 | 격식적으로 원인과 결과를 연결하기 | 폭우로 인하여 행사가 연기되었습니다. — The event was postponed due to heavy rain. | [OFFICIAL] | — |
| -는 사이에 | 표현 | 한 행동·상태가 이어지는 사이의 변화를 말하기 | 잠깐 자리를 비운 사이에 회의가 끝났어요. — The meeting ended while I was briefly away. | [OFFICIAL] | — |
| -는 김에 | 표현 | 기존 행동을 다른 행동의 기회로 삼기 | 시내에 가는 김에 서류도 내고 왔어요. — While I was going downtown, I also handed in the documents. | [OFFICIAL] | — |
| -어 대다 | 표현 | 행동의 반복에 대한 평가를 드러내기 | 모두 질문을 해 대서 설명이 끊겼어요. — Everyone kept firing questions, interrupting the explanation. | [OFFICIAL] | — |
| -어 버리다 | 표현 | 행동의 완결과 화자의 감정을 드러내기 | 필요한 메모를 지워 버렸어요. — I ended up deleting the notes I needed. | [OFFICIAL] | — |
| -을 뻔하다 | 표현 | 실제로 일어나지 않은 아슬아슬한 일을 말하기 | 길이 미끄러워 넘어질 뻔했어요. — The path was slippery and I almost fell. | [OFFICIAL] | — |
| -어서인지 | 표현 | 원인을 확정하지 않고 결과를 설명하기 | 밤을 새워서인지 집중이 잘 안 돼요. — Perhaps because I stayed up all night, I cannot concentrate well. | [OFFICIAL] | — |

*나선형 재방문 (이전 레벨 형태를 더 깊은 기능으로)*
- -고 있다 — 진행·반복·완료의 네 축 중 진행을 사실 보고에서 분리한다.
- -어 있다 — 결과 상태를 책임·원인 평가와 분리해 보고한다.

**3 의사소통 기능 (Sprachhandlungen)**
- 평가·비판·한계 지적하기 (`evaluate_assess_critique`) — 구체적 기준과 증거를 제시해 평가하고 다른 해석의 여지를 남긴다.
- 불만 제기·이의 신청하기 (`complain_object_appeal`) — 문제 사실·영향·원하는 조치를 분리해 이의를 제기한다.
- 확신·의심·완곡 표현하기 (`express_certainty_doubt_hedging`) — 사실·추론·전언의 근거와 확신 정도를 따로 밝힌다.
- 대화 열고 닫기·범위 정하기 (`structure_discourse_open_close_scope`) — 논의의 범위·순서·전환·결론을 독자나 청자에게 표시한다.

**4 어휘 영역**
- 사회·경제·추상 명사 (`society_economy_abstract_nouns`) — 제도(), 고용(), 소비(), 격차() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다.
- 논증·평가·근거 어휘 (`argumentation_evaluation_lexis`) — 근거(), 반론(), 타당성(), 한계() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다.
- 직업·직장 어휘 (`professions_workplace`) — 직업(), 회사(), 동료(), 업무() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다.

**5 텍스트 유형 (Textsorten)**
- 신문 기사·보도문 (`news_article_report`, R) — 수용: 기사에서 사건 사실·인용·기자의 해석을 나눈다. 판정: 전언과 확인된 사실의 보증 수준을 구별한다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 보고서·제안서·공식 문서 (`report_proposal_official`, R/P) — 수용: 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. 산출: 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. 판정: 확인된 결과와 권고·예측을 구별한다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 격식 이메일·공문 (`email_letter_formal`, P) — 산출: 수신자와 책임 범위가 명확한 격식 이메일을 작성한다. 판정: 용건·조건·후속 조치와 공손함을 함께 유지한다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑

**6 듣기**
- 사업·환경 문제의 보고를 듣고 원인 주장과 화자의 부정적 평가를 분리한다. — *evidence_sorting* · -탓에·-바람에·-통에를 평가 중립인 인하여와 구별한다.

**7 말하기**
- 동료에게 문제의 영향을 설명하고 반복 행위·완료·아슬아슬한 미실현을 구분한다. — *scene_roleplay* · -을 뻔하다를 실제 발생으로 보고하지 않고 책임 범위를 과장하지 않는다.

**8 읽기**
- 기사와 보고서를 대조해 시간 경과·추정 원인·확인된 영향을 나눈다. — *genre_analysis* · 출처별 주장과 평가 어휘를 표시해 비교한다.
- 기사에서 사건 사실·인용·기자의 해석을 나눈다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. — *genre_reception* · 전언과 확인된 사실의 보증 수준을 구별한다.
- 보고서·제안서의 목적·자료·결론·실행 조건을 읽는다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. — *genre_reception* · 확인된 결과와 권고·예측을 구별한다.

**9 쓰기**
- 문제 보고서와 관계자에게 보낼 이메일에 같은 사실을 서로 다른 문체로 쓴다. — *genre_production* · 문체를 바꾸어도 책임·사실·추정의 강도가 유지된다.
- 제공된 자료를 목적·근거·결론·실행 조건이 있는 보고서나 제안서로 쓴다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. — *genre_production* · 확인된 결과와 권고·예측을 구별한다.
- 수신자와 책임 범위가 명확한 격식 이메일을 작성한다. Phase 연결: 사건의 연속과 우연한 결과를 재구성하고 원인 표현이 담는 책임·평가를 구분한다. — *genre_production* · 용건·조건·후속 조치와 공손함을 함께 유지한다.

**10 발음·음운**
- 원인 표현의 평가와 휴지 — 대조: 인하여와 탓에의 평가 차이를 소리의 세기만으로 판정하지 않는다. · 연습: 같은 사건의 평가적 보고와 중립적 보고를 듣고 근거 표현을 찾는다.
- 의미 단위와 청자 반응을 보존하는 억양 — 대조: 모어의 강세·휴지 패턴을 한국어의 필수 규칙으로 투사하지 않는다. · 연습: 해당 Phase 말하기 과제를 녹음해 의미가 달라지는 휴지·말끝을 표시하고, 원래 화행을 유지하도록 다시 말한다.

**11 화용·문체 (Pragmatics & Register)**
- 문체: 합쇼체·업무 격식, 해요체(공손 비격식)
- 공손: 문제의 경위를 동료에게 설명한 뒤 공식 보고로 정리한다. 책임 소재는 주어진 증거만 따른다.
- 체면 관리: 상대의 선택권·확인 기회를 보존한다. 내용의 출처·책임과 공손한 말끝을 별개로 판단한다.
- 담화표지: 제 생각에는, 다만
- ⚠️ 말끝만 바꾸며 사실·확신·의무 강도까지 바꾸지 않는다.
- ⚠️ 관계가 명시되지 않은 사람의 성별·나이·직위를 새로 정하지 않는다.

**12 선수 조건 (Prerequisites)**
- 선행 Phase: KP07, KP09, KP08
- 선행 형태: -기 때문에, -던-, -어 있다
- 이유: 의존 지도에서 이 Phase의 새 기능과 직접 연결되는, 이미 배운 동일 급·의미의 형태를 다시 확인한다.

**13 EN → KO 브리지**
- 영어 CEFR 레벨: B2
- 앵커: `observed then; after; since/because` · past tense만으로 -더니의 관점 조건이 전달되지 않으면 관찰 맥락을 별도로 보여 준다.
- 앵커: `because of; due to; thanks to versus blame` · due to로 네 형태를 평탄화하지 않고 사건의 불리함·책임 암시·문어성을 분리한다.
- 앵커: `while; while at it; keep; end up; nearly` · end up를 accident로 자동 좁히지 않고 -어 버리다의 평가를 맥락에서 정한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. past tense만으로 -더니의 관점 조건이 전달되지 않으면 관찰 맥락을 별도로 보여 준다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**14 DE → KO 브리지**
- 독일어 CEFR 레벨: B2
- 앵커: `beobachtet dann; nachdem; da/weil` · nachdem은 순서 자원이지만 -더니의 직접 관찰·대조까지 자동 포함하지 않는다.
- 앵커: `wegen; aufgrund; dank versus Schuld` · wegen 자체가 탓에의 책임 평가를 항상 담는 것은 아니므로 평가 여부를 문장별로 확인한다.
- 앵커: `während; bei der Gelegenheit; ständig; fast` · fast의 미실현을 명시하고 ständig의 빈도·평가를 -어 대다의 과도 반복과 비교한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. nachdem은 순서 자원이지만 -더니의 직접 관찰·대조까지 자동 포함하지 않는다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**15 전이 경고 (Transfer Warning)**
- **EN** [partial] 더니의 관찰 근거와 사건 순서·판단의 근거를 나눈다. past tense만으로 -더니의 관점 조건이 전달되지 않으면 관찰 맥락을 별도로 보여 준다.
- **DE** [partial] 더니의 관찰 근거와 사건 순서·판단의 근거를 나눈다. nachdem은 순서 자원이지만 -더니의 직접 관찰·대조까지 자동 포함하지 않는다.
- **EN** [partial] 바람에·탓에·통에는 평가 차이가 있고 인하여는 문어 원인 연결이다. due to로 네 형태를 평탄화하지 않고 사건의 불리함·책임 암시·문어성을 분리한다.
- **DE** [partial] 바람에·탓에·통에는 평가 차이가 있고 인하여는 문어 원인 연결이다. wegen 자체가 탓에의 책임 평가를 항상 담는 것은 아니므로 평가 여부를 문장별로 확인한다.
- **EN** [partial] 사이에의 동시와 김에의 기회, 실제 완료와 뻔한 미실현을 구별한다. end up를 accident로 자동 좁히지 않고 -어 버리다의 평가를 맥락에서 정한다.
- **DE** [partial] 사이에의 동시와 김에의 기회, 실제 완료와 뻔한 미실현을 구별한다. fast의 미실현을 명시하고 ständig의 빈도·평가를 -어 대다의 과도 반복과 비교한다.

**16 숙달 점검 (Mastery Check)**
1. [듣기] 사업·환경 문제의 보고를 듣고 원인 주장과 화자의 부정적 평가를 분리한다.
   - 합격 기준: -탓에·-바람에·-통에를 평가 중립인 인하여와 구별한다.
2. [말하기] 동료에게 문제의 영향을 설명하고 반복 행위·완료·아슬아슬한 미실현을 구분한다.
   - 합격 기준: -을 뻔하다를 실제 발생으로 보고하지 않고 책임 범위를 과장하지 않는다.
3. [읽기] 기사와 보고서를 대조해 시간 경과·추정 원인·확인된 영향을 나눈다.
   - 합격 기준: 출처별 주장과 평가 어휘를 표시해 비교한다.
4. [쓰기] 문제 보고서와 관계자에게 보낼 이메일에 같은 사실을 서로 다른 문체로 쓴다.
   - 합격 기준: 문체를 바꾸어도 책임·사실·추정의 강도가 유지된다.

---

### 16. KP16 · B2.3 — 가정·양보·선택 범위를 논의하기

- **EN** Discuss hypotheses, concessions and options · **DE** Annahmen, Zugeständnisse und Spielräume diskutieren
- **핵심 의사소통 목표** 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다.
  - EN: Explore alternatives under changed conditions and explain conclusions maintained despite concessions and constrained choices.
  - DE: Alternativen unter veränderten Bedingungen prüfen und trotz Zugeständnissen geltende Schlüsse sowie eingeschränkte Wahlmöglichkeiten erklären.
- **배치 근거** 336 원 인벤토리의 급을 유지한 프로젝트 Phase 배정이다. 내부 순서는 의존 노트를 검토한 교수 판단이며 CEFR·TOPIK의 공식 환산을 뜻하지 않는다.

**1 주제 (Topics)**
- 사회 문제·시사·공동체 (`society_current_affairs`) — 사회 문제·세대·도시생활·사회 변화
- 정치·법·제도·행정 (`politics_law_institutions`) — 제도·법적 절차·과태료 이의·행정
- 문화 차이·세계화·이주 (`intercultural_globalisation_migration`) — 국제문화·비자·체류
- 돈·요금·계약·보험 (`money_finance_contracts`) — 계약 범위·환불 협의·수리비 책임
- 여행·숙박 (`travel_accommodation`) — 결항·지연 escalation

**2 한국어 문법 (실제 형태)**

| 형태 | 범주 | 기능 | 예문 | 근거 | 앱 문법 id |
|---|---|---|---|---|---|
| -는다면1 | 연결어미 | 가정한 상황을 전제로 논의하기 | 지원이 늘어난다면 더 많은 사람이 참여할 수 있어요. — If support increases, more people will be able to participate. | [OFFICIAL] | — |
| 만 같아도 | 표현 | 가정한 최소 수준을 비교 기준으로 제시하기 | 지난번만 같아도 충분히 만족하겠어요. — I would be satisfied if it were even as good as last time. | [OFFICIAL] | — |
| -더라도 | 연결어미 | 가정을 양보해도 결론이 유지됨을 말하기 | 시간이 더 걸리더라도 정확히 확인하겠습니다. — I will check carefully even if it takes longer. | [OFFICIAL] | — |
| -을래야 | 연결어미 | 구어의 -을래야를 알아듣고 표준형 -으려야로 바꾸기 | 구어: 시간이 없어서 도울래야 도울 수가 없었어요. → 표준형: 시간이 없어서 도우려야 도울 수가 없었어요. — I had no time and could not help even though I wanted to. | [OFFICIAL] | — |
| -든지2 | 연결어미 | 어느 선택이든 가능함을 말하기 | 메일을 보내든지 직접 전화해 주세요. — Please either email or call directly. | [OFFICIAL] | — |
| 이든 | 조사 | 명사 선택에 제약이 없음을 말하기 | 어떤 방식이든 먼저 이야기해 봅시다. — Whatever the approach, let us discuss it first. | [OFFICIAL] | — |
| 이나마 | 조사 | 충분하지 않아도 있는 것을 인정하기 | 작은 도움이나마 보태고 싶어요. — I would like to contribute even a little help. | [OFFICIAL] | — |
| 이라도 | 조사 | 선호보다 낮은 대안도 수용함을 말하기 | 오늘이 어렵다면 내일이라도 괜찮아요. — If today is difficult, tomorrow will do. | [OFFICIAL] | — |
| 이면 | 조사 | 특정 범주의 대상을 지정해 일반화하기 | 주말이면 이곳은 사람들로 붐벼요. — At weekends this place is crowded. | [OFFICIAL] | — |
| 치고 | 조사 | 범주에 대한 기대와 실제를 비교하기 | 처음 만든 것치고 꽤 잘했어요. — It is quite good for a first attempt. | [OFFICIAL] | — |
| -는 한 | 표현 | 결론을 유지하는 조건의 범위를 한정하기 | 자료가 부족한 한 단정할 수 없습니다. — As long as the evidence is insufficient, we cannot be certain. | [OFFICIAL] | — |
| -는다거나2 | 표현 | 인용한 행동·제안 중 대안을 제시하기 | 직접 만난다거나 전화로 이야기하는 방법이 있어요. — We could meet in person or talk by phone. | [OFFICIAL] | — |

**3 의사소통 기능 (Sprachhandlungen)**
- 협상·절충·조건 조율하기 (`negotiate_compromise_conditions`) — 각자의 조건을 나누어 수락 범위·양보·차선책을 협의한다.
- 거절하고 경계 정하기 (`refuse_set_boundaries`) — 어려운 점과 가능한 대안을 밝혀 경계를 설정한다.
- 설득·논증·정당화하기 (`persuade_argue_justify`) — 주장·근거·반론·응답을 연결해 입장을 정당화한다.
- 비교·대조·대안 검토하기 (`compare_contrast_alternatives`) — 같은 기준으로 두 대안을 비교하고 빠진 기준을 확인한다.

**4 어휘 영역**
- 제도·법률·행정 담화 어휘 (`institutional_legal_lexis`) — 권한(), 책임(), 조항(), 예외() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다.
- 논증·평가·근거 어휘 (`argumentation_evaluation_lexis`) — 근거(), 반론(), 타당성(), 한계() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다.
- 관용 표현·연어·담화 표지(품사=표현) (`fixed_expressions_collocations`) — 마음에 들다(), 도움이 되다(), 약속을 지키다(), 의견을 나누다() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다.

**5 텍스트 유형 (Textsorten)**
- 계약서·약관·법률 텍스트 (`contract_terms_legal_text`, R) — 수용: 계약·약관의 적용 대상·권리·의무·예외를 대조한다. 판정: 법적 효력을 새로 판단하지 않고 주어진 문언 범위를 설명한다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 논설문·의견문(에세이) (`essay_opinion_argumentative`, R/P) — 수용: 논설문의 주장·근거·반론·응답을 표시한다. 산출: 제시된 쟁점에 대해 근거와 반론을 갖춘 의견문을 쓴다. 판정: 상대 입장을 약화하지 않고 반론 범위를 일치시킨다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 회의·공식 토론 (`meeting_formal_discussion`, P) — 산출: 역할별 조건을 바탕으로 토론하고 결정·미합의점을 함께 정리한다. 판정: 발언자의 책임과 결정 권한을 바꾸지 않는다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다.

**6 듣기**
- 협상에서 제시된 조건·양보·차선책·최소 보장 범위를 정리한다. — *evidence_sorting* · 실제 조건과 비현실 가정을 구별하고 양보를 동의로 바꾸지 않는다.

**7 말하기**
- 두 이해관계가 충돌하는 모임에서 수락 조건과 양보 가능한 부분을 협의한다. — *scene_roleplay* · 양보·거절·차선책을 분리하고 상대의 선택권을 유지한다.
- 역할별 조건을 바탕으로 토론하고 결정·미합의점을 함께 정리한다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. — *genre_production* · 발언자의 책임과 결정 권한을 바꾸지 않는다.

**8 읽기**
- 약관과 의견문을 읽고 조건이 달라질 때 결론이 유지되는 범위를 따진다. — *genre_analysis* · -는 한의 제한 범위와 -더라도의 양보를 명시한다.
- 계약·약관의 적용 대상·권리·의무·예외를 대조한다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. — *genre_reception* · 법적 효력을 새로 판단하지 않고 주어진 문언 범위를 설명한다.
- 논설문의 주장·근거·반론·응답을 표시한다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. — *genre_reception* · 상대 입장을 약화하지 않고 반론 범위를 일치시킨다.

**9 쓰기**
- 조건과 반론을 포함하는 의견문을 쓰고 차선책을 근거와 함께 제안한다. — *genre_production* · 예외·적용 범위·결론이 서로 모순되지 않는다.
- 제시된 쟁점에 대해 근거와 반론을 갖춘 의견문을 쓴다. Phase 연결: 조건을 바꿔 대안을 검토하고 양보가 성립해도 유지되는 결론과 제한된 선택의 의미를 설명한다. — *genre_production* · 상대 입장을 약화하지 않고 반론 범위를 일치시킨다.

**10 발음·음운**
- 양보·조건·선택의 초점 — 대조: -더라도의 양보와 -든지의 선택을 휴지 하나로 합치지 않는다. · 연습: 조건 뒤에도 유지되는 결론을 듣고 결론 앞 휴지를 조절한다.
- 의미 단위와 청자 반응을 보존하는 억양 — 대조: 모어의 강세·휴지 패턴을 한국어의 필수 규칙으로 투사하지 않는다. · 연습: 해당 Phase 말하기 과제를 녹음해 의미가 달라지는 휴지·말끝을 표시하고, 원래 화행을 유지하도록 다시 말한다.

**11 화용·문체 (Pragmatics & Register)**
- 문체: 해요체(공손 비격식), 합쇼체·업무 격식
- 공손: 동등한 협상 참여자. 개인 의지·기관의 권한·실행 가능성을 별도 조건으로 준다.
- 체면 관리: 상대의 선택권·확인 기회를 보존한다. 내용의 출처·책임과 공손한 말끝을 별개로 판단한다.
- 담화표지: 제 생각에는, 다만
- ⚠️ 말끝만 바꾸며 사실·확신·의무 강도까지 바꾸지 않는다.
- ⚠️ 관계가 명시되지 않은 사람의 성별·나이·직위를 새로 정하지 않는다.

**12 선수 조건 (Prerequisites)**
- 선행 Phase: KP05, KP07, KP11
- 선행 형태: -으면, -을래, -어도
- 이유: 의존 지도에서 이 Phase의 새 기능과 직접 연결되는, 이미 배운 동일 급·의미의 형태를 다시 확인한다.

**13 EN → KO 브리지**
- 영어 CEFR 레벨: B2
- 앵커: `if; even a little; even if; cannot despite trying` · if를 보고 모든 조건을 같은 가능성으로 읽지 않고 -더라도의 결론 유지 범위를 표시한다.
- 앵커: `whichever; at least; even an alternative` · any와 at least를 한 의미로 묶지 않고 선택 제한이 있는지 확인한다.
- 앵커: `if it is; for a member of; as long as; alternatives` · for a를 인구 집단 고정관념으로 확대하지 않고 주어진 비교 범주만 해석한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. if를 보고 모든 조건을 같은 가능성으로 읽지 않고 -더라도의 결론 유지 범위를 표시한다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**14 DE → KO 브리지**
- 독일어 CEFR 레벨: B2
- 앵커: `wenn; schon wenn; selbst wenn; trotz Absicht nicht können` · selbst wenn의 발판을 쓰되 구어 -을래야를 표준 규범이라고 하지 않고 -으려야로 재구성한다.
- 앵커: `egal welche; wenigstens; zur Not` · egal와 wenigstens의 차이를 활용하면서 이나마·이라도의 화자 평가를 문맥에 연결한다.
- 앵커: `wenn es; für ein; solange; Alternativen` · solange의 시간 지속과 조건 범위를 구분해 한국어 후행 결론이 유효한 범위를 확인한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. selbst wenn의 발판을 쓰되 구어 -을래야를 표준 규범이라고 하지 않고 -으려야로 재구성한다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**15 전이 경고 (Transfer Warning)**
- **EN** [partial] 현실성·최소 기준·양보 강도와 표준형의 구별을 함께 본다. if를 보고 모든 조건을 같은 가능성으로 읽지 않고 -더라도의 결론 유지 범위를 표시한다.
- **DE** [partial] 현실성·최소 기준·양보 강도와 표준형의 구별을 함께 본다. selbst wenn의 발판을 쓰되 구어 -을래야를 표준 규범이라고 하지 않고 -으려야로 재구성한다.
- **EN** [positive] 어느 것이든 자유 선택과 마지못한 차선 수용을 구별한다. any와 at least를 한 의미로 묶지 않고 선택 제한이 있는지 확인한다.
- **DE** [positive] 어느 것이든 자유 선택과 마지못한 차선 수용을 구별한다. egal와 wenigstens의 차이를 활용하면서 이나마·이라도의 화자 평가를 문맥에 연결한다.
- **EN** [partial] 치고의 일반화와 -는 한의 한계, 선택 나열의 조건을 구별한다. for a를 인구 집단 고정관념으로 확대하지 않고 주어진 비교 범주만 해석한다.
- **DE** [partial] 치고의 일반화와 -는 한의 한계, 선택 나열의 조건을 구별한다. solange의 시간 지속과 조건 범위를 구분해 한국어 후행 결론이 유효한 범위를 확인한다.

**16 숙달 점검 (Mastery Check)**
1. [듣기] 협상에서 제시된 조건·양보·차선책·최소 보장 범위를 정리한다.
   - 합격 기준: 실제 조건과 비현실 가정을 구별하고 양보를 동의로 바꾸지 않는다.
2. [말하기] 두 이해관계가 충돌하는 모임에서 수락 조건과 양보 가능한 부분을 협의한다.
   - 합격 기준: 양보·거절·차선책을 분리하고 상대의 선택권을 유지한다.
3. [읽기] 약관과 의견문을 읽고 조건이 달라질 때 결론이 유지되는 범위를 따진다.
   - 합격 기준: -는 한의 제한 범위와 -더라도의 양보를 명시한다.
4. [쓰기] 조건과 반론을 포함하는 의견문을 쓰고 차선책을 근거와 함께 제안한다.
   - 합격 기준: 예외·적용 범위·결론이 서로 모순되지 않는다.

---

### 17. KP17 · B2.4 — 인용을 확인하고 오해를 바로잡기

- **EN** Check reported speech and repair misunderstandings · **DE** Wiedergegebene Aussagen prüfen und Missverständnisse klären
- **핵심 의사소통 목표** 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다.
  - EN: Use contracted reported speech, checking questions and witnessed evidence to clarify content, stance and misunderstandings.
  - DE: Mit verkürzter Redewiedergabe, Rückfragen und Beobachtungsbelegen Inhalt und Haltung klären und Missverständnisse beheben.
- **배치 근거** 336 원 인벤토리의 급을 유지한 프로젝트 Phase 배정이다. 내부 순서는 의존 노트를 검토한 교수 판단이며 CEFR·TOPIK의 공식 환산을 뜻하지 않는다.

**1 주제 (Topics)**
- 가족·인간관계 (`family_relationships`) — 인간관계·가족 경계·결혼식 초대
- 미디어·대중문화(K-pop·드라마·SNS) (`media_entertainment_culture_pop`) — 미디어·조회 수·콘텐츠 촬영 허락
- 예절·관습·명절·호칭 (`social_etiquette_customs`) — 호칭 정하기·격식 예절
- 예술·문학·역사·기억 (`arts_literature_history`) — 문화·예술·전통의 현대화

**2 한국어 문법 (실제 형태)**

| 형태 | 범주 | 기능 | 예문 | 근거 | 앱 문법 id |
|---|---|---|---|---|---|
| -어라1 | 종결어미 | 관계가 허용하는 직접 명령형을 구별하기 | 먼저 자료를 읽어라. — Read the materials first. | [OFFICIAL] | — |
| -는대2 | 표현 | 들어서 전하는 내용을 축약 인용하기 | 친구가 오늘 회의는 없대요. — My friend says there is no meeting today. | [OFFICIAL] | — |
| -고4 | 종결어미 | 상대의 말에 관련 질문을 덧붙이기 | 주말에도 일한다고요? 그럼 쉬는 날은 없고요? — You work at weekends too? Then you do not have any days off? | [OFFICIAL] | — |
| -게5 | 종결어미 | 행동의 의도를 반말 질문으로 확인하기 | 이 많은 짐을 어디로 가져가게? — Where are you planning to take all this luggage? | [OFFICIAL] | — |
| -나3 | 종결어미 | 문장 안·혼잣말에서 의문을 완곡하게 제시하기 | 내가 잘못 들었나 다시 생각했어요. — I wondered again whether I had misheard. | [OFFICIAL] | — |
| -는다니2 | 종결어미 | 전달된 내용에 대해 확인 질문하기 | 내일 회의를 한다니? 시간이 바뀐 거야? — Are you saying the meeting is tomorrow? Has the time changed? | [OFFICIAL] | — |
| -는다면서1 | 종결어미 | 들은 말을 상대에게 확인하기 | 다음 달에 이사한다면서요? — I hear you are moving next month; is that right? | [OFFICIAL] | — |
| -다니1 | 종결어미 | 뜻밖의 소식에 놀라며 재확인하기 | 벌써 끝났다니? 정말이에요? — Finished already? Is that really true? | [OFFICIAL] | — |
| -더군 | 종결어미 | 직접 경험해 알게 된 사실에 반응하기 | 직접 가 보니 생각보다 멀더군요. — When I went there, I found it was farther than expected. | [OFFICIAL] | — |
| -더라 | 종결어미 | 자신이 경험한 사실을 회상해 전달하기 | 어제 가 보니 문이 닫혀 있더라. — I went there yesterday and found it was closed. | [OFFICIAL] | — |
| -던데1 | 연결어미 | 경험을 배경으로 다른 정보를 덧붙이기 | 어제는 문이 닫혀 있던데 오늘은 여나요? — It was closed yesterday; is it open today? | [OFFICIAL] | — |
| -는 줄 | 표현 | 사실과 달랐던 자신의 믿음을 정정하기 | 회의가 내일인 줄 알았어요. — I thought the meeting was tomorrow. | [OFFICIAL] | — |
| -어야지2 | 종결어미 | 친밀한 상대에게 당위를 강조하기 | 힘들면 미리 말해야지. — You should tell me beforehand if it is difficult. | [OFFICIAL] | — |

**3 의사소통 기능 (Sprachhandlungen)**
- 당사자 사이 중재·조정하기 (`mediate_between_parties`) — 양쪽의 목적·조건·이견을 보존해 뜻을 중개하고 남은 모호성을 확인한다.
- 발언권 관리·끼어들기 (`manage_turns_interrupt_hold_floor`) — 발언을 요청·양보·회복하되 상대의 핵심 논점을 끊어 왜곡하지 않는다.
- 말투·존댓말·호칭 조절하기 (`adjust_register_speech_style`) — 같은 사실을 관계·채널에 맞게 바꾸고 주체 높임과 청자 대우를 따로 조절한다.
- 의견 말하고 동의·반대하기 (`express_opinion_agree_disagree`) — 찬성·반대의 범위와 근거를 밝혀 사람 평가와 구분한다.

**4 어휘 영역**
- 미디어·대중문화 어휘 (`media_pop_culture_vocab`) — 기사(), 방송(), 댓글(), 장면() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다.
- 예절·높임·호칭 어휘 (`etiquette_honorific_lexis`) — 호칭(), 높임(), 말씀(), 드리다() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다.
- 관용 표현·연어·담화 표지(품사=표현) (`fixed_expressions_collocations`) — 마음에 들다(), 도움이 되다(), 약속을 지키다(), 의견을 나누다() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다.

**5 텍스트 유형 (Textsorten)**
- 문학 텍스트 (`literary_text`, R) — 수용: 문학 텍스트의 서술 관점·암시·문체 효과를 근거 구절과 연결한다. 판정: 사건의 사실과 관점의 변화를 따로 표시한다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 회의·공식 토론 (`meeting_formal_discussion`, R/P) — 수용: 회의 녹음에서 제안·이견·결정을 구별한다. 산출: 역할별 조건을 바탕으로 토론하고 결정·미합의점을 함께 정리한다. 판정: 발언자의 책임과 결정 권한을 바꾸지 않는다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다.
- 리뷰·비평문 (`review_critique_text`, P) — 산출: 이번 Phase의 자료나 작품을 평가 기준·장점·한계·근거가 있는 리뷰로 쓴다. 판정: 회의 사실 기록과 평가·비평을 구별한다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑

**6 듣기**
- 회의와 극 대사에서 전달·재확인·놀람·관찰 회고를 구별한다. — *evidence_sorting* · -는대의 축약 인용과 -더라의 관찰 근거를 구분한다.
- 회의 녹음에서 제안·이견·결정을 구별한다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. — *genre_reception* · 발언자의 책임과 결정 권한을 바꾸지 않는다.

**7 말하기**
- 갈린 발언을 되묻고 명령을 전한 것인지 자기 요청인지 확인하며 발언 순서를 조정한다. — *scene_roleplay* · 인용 원문의 화행을 보존하고 오해를 비난 없이 수리한다.
- 역할별 조건을 바탕으로 토론하고 결정·미합의점을 함께 정리한다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. — *genre_production* · 발언자의 책임과 결정 권한을 바꾸지 않는다.

**8 읽기**
- 문학 속 대화와 회의 기록을 읽고 말끝이 만드는 거리·확신·기대를 비교한다. — *genre_analysis* · 친밀한 질문을 공식 질문과 구별하고 억양이 필요한 부분을 표시한다.
- 문학 텍스트의 서술 관점·암시·문체 효과를 근거 구절과 연결한다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. — *genre_reception* · 사건의 사실과 관점의 변화를 따로 표시한다.

**9 쓰기**
- 서로 다른 두 발언을 회의 기록으로 정리하고 확인할 질문을 덧붙인다. — *genre_production* · 진술·명령·질문의 인용 유형과 출처를 각각 유지한다.
- 이번 Phase의 자료나 작품을 평가 기준·장점·한계·근거가 있는 리뷰로 쓴다. Phase 연결: 축약 인용·되묻기·목격 근거를 이용해 발언의 내용과 태도를 확인하고 오해를 수정한다. — *genre_production* · 회의 사실 기록과 평가·비평을 구별한다.

**10 발음·음운**
- 축약 인용과 재확인 억양 — 대조: 한대·한데, -더라·-더군의 형태와 태도를 함께 본다. · 연습: 진술 인용과 재확인 질문을 원형으로 풀고 문맥에 맞게 다시 축약한다.
- 의미 단위와 청자 반응을 보존하는 억양 — 대조: 모어의 강세·휴지 패턴을 한국어의 필수 규칙으로 투사하지 않는다. · 연습: 해당 Phase 말하기 과제를 녹음해 의미가 달라지는 휴지·말끝을 표시하고, 원래 화행을 유지하도록 다시 말한다.

**11 화용·문체 (Pragmatics & Register)**
- 문체: 해요체(공손 비격식), 반말(친근·평교), 친밀체(연인·가까운 사이), 합쇼체·업무 격식
- 공손: 친밀한 대화와 공식 회의에서 인용을 확인한다. 같은 말끝도 관계와 이전 발화로 판단한다.
- 체면 관리: 상대의 선택권·확인 기회를 보존한다. 내용의 출처·책임과 공손한 말끝을 별개로 판단한다.
- 담화표지: 제 생각에는, 다만
- ⚠️ 말끝만 바꾸며 사실·확신·의무 강도까지 바꾸지 않는다.
- ⚠️ 관계가 명시되지 않은 사람의 성별·나이·직위를 새로 정하지 않는다.

**12 선수 조건 (Prerequisites)**
- 선행 Phase: KP14, KP13, KP15, KP06, KP04
- 선행 형태: -는지, -는다고3, -더니, -는 것, -고4
- 이유: 의존 지도에서 이 Phase의 새 기능과 직접 연결되는, 이미 배운 동일 급·의미의 형태를 다시 확인한다.

**13 EN → KO 브리지**
- 영어 CEFR 레벨: B2
- 앵커: `told to; said; and what about; checking intent` · said와 told to의 화행 차이를 남기고 명령 -으라고 하다에서 -으래로의 축약을 별도 연습한다.
- 앵커: `wonder; you say; is that so; surprise` · tag question이나 really 하나로 전부 치환하지 않고 질문 내용·놀람·공유 정보의 범위를 비교한다.
- 앵커: `I noticed; background; thought that; should` · thought를 전언으로 바꾸지 않고 -는 줄 알다의 사실 여부는 후행 문맥에서 판단한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. said와 told to의 화행 차이를 남기고 명령 -으라고 하다에서 -으래로의 축약을 별도 연습한다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**14 DE → KO 브리지**
- 독일어 CEFR 레벨: B2
- 앵커: `Aufforderung berichten; hieß es; Rückfrage` · 간접화법의 시제·접속법보다 먼저 명령 수행자와 발언 출처를 찾는다.
- 앵커: `sich fragen; du sagst; stimmt das; Überraschung` · denn/doch를 자동 삽입하지 않고 선행 발화가 호기심·반박·확인 중 무엇을 허가하는지 본다.
- 앵커: `ich bemerkte; Hintergrund; dachte; sollte` · dachte와 soll을 혼동하지 않으며 -어야지2의 자기 지향성과 청자 압박을 맥락으로 평가한다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. 간접화법의 시제·접속법보다 먼저 명령 수행자와 발언 출처를 찾는다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**15 전이 경고 (Transfer Warning)**
- **EN** [negative_risk] 진술·명령의 인용 원형과 덧붙여 묻는 -고4를 분리한다. said와 told to의 화행 차이를 남기고 명령 -으라고 하다에서 -으래로의 축약을 별도 연습한다.
  - ✗ 오개념: told to; said; and what about; checking intent를 -어라1, -는대2, -고4, -게5에 형태별 일대일로 치환한다. → ✓ said와 told to의 화행 차이를 남기고 명령 -으라고 하다에서 -으래로의 축약을 별도 연습한다.
- **DE** [negative_risk] 진술·명령의 인용 원형과 덧붙여 묻는 -고4를 분리한다. 간접화법의 시제·접속법보다 먼저 명령 수행자와 발언 출처를 찾는다.
  - ✗ 오개념: Aufforderung berichten; hieß es; Rückfrage를 -어라1, -는대2, -고4, -게5에 형태별 일대일로 치환한다. → ✓ 간접화법의 시제·접속법보다 먼저 명령 수행자와 발언 출처를 찾는다.
- **EN** [partial] 모든 확인 질문이 불신·비난을 뜻하지 않고 이전 발화와 억양이 중요하다. tag question이나 really 하나로 전부 치환하지 않고 질문 내용·놀람·공유 정보의 범위를 비교한다.
- **DE** [partial] 모든 확인 질문이 불신·비난을 뜻하지 않고 이전 발화와 억양이 중요하다. denn/doch를 자동 삽입하지 않고 선행 발화가 호기심·반박·확인 중 무엇을 허가하는지 본다.
- **EN** [partial] 관찰한 사실과 알고 있던 기대, 화자의 결심을 나눈다. thought를 전언으로 바꾸지 않고 -는 줄 알다의 사실 여부는 후행 문맥에서 판단한다.
- **DE** [partial] 관찰한 사실과 알고 있던 기대, 화자의 결심을 나눈다. dachte와 soll을 혼동하지 않으며 -어야지2의 자기 지향성과 청자 압박을 맥락으로 평가한다.

**16 숙달 점검 (Mastery Check)**
1. [듣기] 회의와 극 대사에서 전달·재확인·놀람·관찰 회고를 구별한다.
   - 합격 기준: -는대의 축약 인용과 -더라의 관찰 근거를 구분한다.
2. [말하기] 갈린 발언을 되묻고 명령을 전한 것인지 자기 요청인지 확인하며 발언 순서를 조정한다.
   - 합격 기준: 인용 원문의 화행을 보존하고 오해를 비난 없이 수리한다.
3. [읽기] 문학 속 대화와 회의 기록을 읽고 말끝이 만드는 거리·확신·기대를 비교한다.
   - 합격 기준: 친밀한 질문을 공식 질문과 구별하고 억양이 필요한 부분을 표시한다.
4. [쓰기] 서로 다른 두 발언을 회의 기록으로 정리하고 확인할 질문을 덧붙인다.
   - 합격 기준: 진술·명령·질문의 인용 유형과 출처를 각각 유지한다.

---

### 18. KP18 · B2.5 — 논거를 종합하고 결론의 강도를 조절하기

- **EN** Synthesize arguments and calibrate conclusions · **DE** Argumente bündeln und Schlussfolgerungen abstufen
- **핵심 의사소통 목표** 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다.
  - EN: Synthesize arguments across formal evidence and conversational reservation, calibrating emphasis, rebuttal and regret.
  - DE: Argumente mit formellen Belegen und alltäglichen Vorbehalten verbinden und Nachdruck, Widerspruch und Bedauern abstufen.
- **배치 근거** 336 원 인벤토리의 급을 유지한 프로젝트 Phase 배정이다. 내부 순서는 의존 노트를 검토한 교수 판단이며 CEFR·TOPIK의 공식 환산을 뜻하지 않는다.

**1 주제 (Topics)**
- 윤리·철학·추상적 논쟁 (`ethics_philosophy_abstract`) — 가치관·추상적 주제 논의
- 과학·연구·근거·통계 (`science_research_evidence`) — 과학·근거·지표 해석 기초
- 기술·디지털·AI·데이터 (`technology_digital_ai`) — 기술·AI 생성물·개인정보
- 교육·학교·학습 (`education_study`) — 교육제도
- 환경·기후·지속가능성 (`environment_sustainability`) — 환경·기후·자원

**2 한국어 문법 (실제 형태)**

| 형태 | 범주 | 기능 | 예문 | 근거 | 앱 문법 id |
|---|---|---|---|---|---|
| -다시피 | 연결어미 | 이미 알거나 관찰한 내용을 환기하기 | 보시다시피 자료마다 수치가 다릅니다. — As you can see, the figures differ across the materials. | [OFFICIAL] | — |
| -거니와 | 연결어미 | 앞 사실에 논거를 추가하기 | 이 방법은 간단하거니와 비용도 적게 듭니다. — This method is simple and also costs little. | [OFFICIAL] | — |
| 에 의하여 | 표현 | 규정·행위자·근거에 의한 결과를 말하기 | 신청은 정해진 절차에 의하여 처리됩니다. — Applications are processed according to the established procedure. | [OFFICIAL] | — |
| -으므로 | 연결어미 | 격식적인 이유와 결론을 연결하기 | 자료가 충분하지 않으므로 결론을 유보합니다. — There is insufficient evidence, so we reserve judgement. | [OFFICIAL] | — |
| -나 싶다 | 표현 | 주관적인 의문·추측을 유보해서 말하기 | 내 설명이 부족했나 싶어요. — I wonder whether my explanation was insufficient. | [OFFICIAL] | — |
| -는 듯 | 표현 | 문어에서 단정을 낮춰 상태를 묘사하기 | 아무 일도 없었던 듯 조용했습니다. — It was quiet, as though nothing had happened. | [OFFICIAL] | — |
| -을걸 | 종결어미 | 지난 선택에 대한 후회를 말하기 | 조금 더 일찍 출발할걸. — I should have left a little earlier. | [OFFICIAL] | — |
| -을 모양이다 | 표현 | 정황에 근거해 앞으로의 일을 예상하기 | 하늘이 어두운 걸 보니 비가 올 모양이에요. — The sky is dark, so it looks as though it will rain. | [OFFICIAL] | — |
| 까지2 | 조사 | 예상 밖 대상을 척도에 추가하기 | 가장 가까운 친구까지 반대했어요. — Even my closest friend opposed it. | [OFFICIAL] | — |
| 마저 | 조사 | 남은 대상까지 포함됨을 강조하기 | 마지막 기회마저 놓쳤어요. — I lost even the last opportunity. | [OFFICIAL] | — |
| 이야 | 조사 | 대비되는 대상을 특별히 강조하기 | 다른 사람은 몰라도 당신이야 잘 알겠죠. — Others may not know, but you surely do. | [OFFICIAL] | — |
| 커녕 | 조사 | 기대의 낮은 단계조차 부정하며 반박하기 | 쉬기는커녕 밥 먹을 시간도 없었어요. — Far from resting, I did not even have time to eat. | [OFFICIAL] | — |
| -을 따름이다 | 표현 | 격식 있게 행동·감정의 범위를 제한하기 | 저는 확인된 사실을 말씀드렸을 따름입니다. — I have merely stated the verified facts. | [OFFICIAL] | — |
| -고자 | 연결어미 | 공적인 목적·의도를 제시하기 | 문제의 원인을 밝히고자 조사를 시작했습니다. — We began an investigation to identify the cause of the problem. | [OFFICIAL] | — |
| -고도 | 연결어미 | 앞 행동에서 기대되는 결과와 다른 일을 말하기 | 설명을 듣고도 이해하지 못했어요. — I heard the explanation but still did not understand. | [OFFICIAL] | — |
| -고 들다 | 표현 | 상대가 어떤 행동을 계속 밀어붙임을 말하기 | 그는 설명을 듣지도 않고 따지고 들었어요. — He pressed his objections without even hearing the explanation. | [OFFICIAL] | — |
| -고 보다 | 표현 | 다른 판단에 앞서 행동부터 함을 말하기 | 급해서 일단 신청하고 봤어요. — I was in a hurry, so I applied first without thinking further. | [OFFICIAL] | — |
| -고 해서 | 표현 | 여러 이유 중 하나를 들어 설명하기 | 날씨도 춥고 해서 실내에서 만났어요. — It was cold, among other things, so we met indoors. | [OFFICIAL] | — |
| -는 대로 | 표현 | 앞 행동 직후 실행할 일을 말하기 | 확인하는 대로 연락드리겠습니다. — I will contact you as soon as I have checked. | [OFFICIAL] | — |

**3 의사소통 기능 (Sprachhandlungen)**
- 설득·논증·정당화하기 (`persuade_argue_justify`) — 주장·근거·반론·응답을 연결해 입장을 정당화한다.
- 평가·비판·한계 지적하기 (`evaluate_assess_critique`) — 구체적 기준과 증거를 제시해 평가하고 다른 해석의 여지를 남긴다.
- 확신·의심·완곡 표현하기 (`express_certainty_doubt_hedging`) — 사실·추론·전언의 근거와 확신 정도를 따로 밝힌다.
- 대화 열고 닫기·범위 정하기 (`structure_discourse_open_close_scope`) — 논의의 범위·순서·전환·결론을 독자나 청자에게 표시한다.

**4 어휘 영역**
- 사회·경제·추상 명사 (`society_economy_abstract_nouns`) — 제도(), 고용(), 소비(), 격차() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다.
- 논증·평가·근거 어휘 (`argumentation_evaluation_lexis`) — 근거(), 반론(), 타당성(), 한계() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다.
- 관용 표현·연어·담화 표지(품사=표현) (`fixed_expressions_collocations`) — 마음에 들다(), 도움이 되다(), 약속을 지키다(), 의견을 나누다() · 과제용 예시 어휘이며 요구 어휘 전수·빈도·공식 등급 목록이 아니다. 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다.

**5 텍스트 유형 (Textsorten)**
- 논설문·의견문(에세이) (`essay_opinion_argumentative`, R/P) — 수용: 논설문의 주장·근거·반론·응답을 표시한다. 산출: 제시된 쟁점에 대해 근거와 반론을 갖춘 의견문을 쓴다. 판정: 상대 입장을 약화하지 않고 반론 범위를 일치시킨다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 신문 기사·보도문 (`news_article_report`, R) — 수용: 기사에서 사건 사실·인용·기자의 해석을 나눈다. 판정: 전언과 확인된 사실의 보증 수준을 구별한다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. ⛔ 현재 taxonomy에 앱 배치 경로 미매핑
- 발표·브리핑 (`presentation_briefing_talk`, P) — 산출: 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. 판정: 질문에서 모르는 정보는 확인 과제로 남긴다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다.

**6 듣기**
- 발표를 듣고 주장의 범위·예외·확신 수준과 결론 근거를 기록한다. — *evidence_sorting* · 추측·강조·한정이 결론에 미치는 효과를 구별한다.

**7 말하기**
- 같은 자료로 가능한 두 해석을 비교하고 자신의 결론을 적정 강도로 제시한다. — *scene_roleplay* · 근거 없는 확신을 추가하지 않고 반론 뒤 논지를 회복한다.
- 제공된 자료를 청중에게 요점·근거·한계 순으로 발표한다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. — *genre_production* · 질문에서 모르는 정보는 확인 과제로 남긴다.

**8 읽기**
- 논설문과 기사를 읽고 인과·양보·강조·최소 주장만 남기는 표현을 표시한다. — *genre_analysis* · 마저·커녕의 대안 척도를 문맥에서 복원한다.
- 논설문의 주장·근거·반론·응답을 표시한다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. — *genre_reception* · 상대 입장을 약화하지 않고 반론 범위를 일치시킨다.
- 기사에서 사건 사실·인용·기자의 해석을 나눈다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. — *genre_reception* · 전언과 확인된 사실의 보증 수준을 구별한다.

**9 쓰기**
- 여러 논거와 반론을 종합해 결론의 범위를 명시하는 의견문을 쓴다. — *genre_production* · 근거·반론·예외·결론의 연결이 드러나고 추론이 출처를 넘지 않는다.
- 제시된 쟁점에 대해 근거와 반론을 갖춘 의견문을 쓴다. Phase 연결: 격식적 근거와 일상적 유보를 구별해 논거를 종합하고 강조·반박·후회의 강도를 조정한다. — *genre_production* · 상대 입장을 약화하지 않고 반론 범위를 일치시킨다.

**10 발음·음운**
- 논증의 초점·양보·결론 운율 — 대조: 모든 문장에 같은 강세를 주어 근거 위계를 지우지 않는다. · 연습: 반론 수용·예외·결론의 세 억양구를 표시해 청중용 설명을 한다.
- 의미 단위와 청자 반응을 보존하는 억양 — 대조: 모어의 강세·휴지 패턴을 한국어의 필수 규칙으로 투사하지 않는다. · 연습: 해당 Phase 말하기 과제를 녹음해 의미가 달라지는 휴지·말끝을 표시하고, 원래 화행을 유지하도록 다시 말한다.

**11 화용·문체 (Pragmatics & Register)**
- 문체: 합쇼체·업무 격식, 해요체(공손 비격식)
- 공손: 공개 발표와 동료 토론. 공적 발표의 격식을 일상 대화 전체로 넓히지 않는다.
- 체면 관리: 상대의 선택권·확인 기회를 보존한다. 내용의 출처·책임과 공손한 말끝을 별개로 판단한다.
- 담화표지: 제 생각에는, 다만
- ⚠️ 말끝만 바꾸며 사실·확신·의무 강도까지 바꾸지 않는다.
- ⚠️ 관계가 명시되지 않은 사람의 성별·나이·직위를 새로 정하지 않는다.

**12 선수 조건 (Prerequisites)**
- 선행 Phase: KP14, KP13, KP02, KP11
- 선행 형태: -듯이, -으며, 에 따라, -을 텐데, -는 모양이다, 도, 뿐
- 이유: 의존 지도에서 이 Phase의 새 기능과 직접 연결되는, 이미 배운 동일 급·의미의 형태를 다시 확인한다.

**13 EN → KO 브리지**
- 영어 CEFR 레벨: C1
- 앵커: `as you know; moreover; by; therefore` · as you know를 설명 편의로 추가하지 않고 by가 행위자·수단인지 구분한다.
- 앵커: `I wonder if; as though; I should have; expected` · 후회 -을걸은 I should have와 비교한다. -나 싶다·-는 듯·-을 모양이다는 각각의 근거와 문맥을 따로 확인한다.
- 앵커: `even; not even; as for; merely` · even과 not even이 만드는 대안을 사건 사실과 분리해 쓰고 새로운 기대를 첨가하지 않는다.
- 앵커: `intend; despite doing; insist; on occasion` · intend to와 keep doing으로 전부 옮기지 않고 -고 들다의 집요함과 -고 보다의 선행 실행을 나눈다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. as you know를 설명 편의로 추가하지 않고 by가 행위자·수단인지 구분한다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**14 DE → KO 브리지**
- 독일어 CEFR 레벨: C1
- 앵커: `wie bekannt; außerdem; durch; daher` · durch/von의 모든 차이를 에 의하여 하나로 지우지 않고 공식 글의 출처·수단을 확인한다.
- 앵커: `ich frage mich ob; als ob; hätte ... sollen; Erwartung` · 후회 -을걸은 hätte ... sollen과 비교한다. wohl/scheinen의 추정 기능을 이 후회 용례에 덧씌우지 않는다.
- 앵커: `sogar; nicht einmal; gerade; lediglich` · sogar와 nicht einmal의 긍정·부정 방향을 이용하되 -도와 모든 척도 조사를 등치하지 않는다.
- 앵커: `beabsichtigen; trotz; darauf bestehen; bei Gelegenheit` · beabsichtigen을 -고자의 문어성과 비교하며 -는 대로의 시간·방식 해석은 문맥으로 고른다.
- 활용: 공유 기능을 발판으로 삼되 각 앵커의 다른 구조·관계·근거 범위를 명시한다. durch/von의 모든 차이를 에 의하여 하나로 지우지 않고 공식 글의 출처·수단을 확인한다.
- 주의: 모어 쪽 CEFR 배정은 현재 교수 추정이며 공식 원문 항목의 확정 등급으로 표시하지 않는다. 한국어 등급과 자동으로 맞추지 않는다.

**15 전이 경고 (Transfer Warning)**
- **EN** [partial] 공유 근거를 전제하기 전에 실제 공통 배경을 확인한다. as you know를 설명 편의로 추가하지 않고 by가 행위자·수단인지 구분한다.
- **DE** [partial] 공유 근거를 전제하기 전에 실제 공통 배경을 확인한다. durch/von의 모든 차이를 에 의하여 하나로 지우지 않고 공식 글의 출처·수단을 확인한다.
- **EN** [partial] 이 Phase의 -을걸은 하지 않은 행동에 대한 후회이며 추정 확률 순위에 놓지 않는다. 나머지 추론·인상·예측은 근거와 확신을 구별한다. 후회 -을걸은 I should have와 비교한다. -나 싶다·-는 듯·-을 모양이다는 각각의 근거와 문맥을 따로 확인한다.
- **DE** [partial] 이 Phase의 -을걸은 하지 않은 행동에 대한 후회이며 추정 확률 순위에 놓지 않는다. 나머지 추론·인상·예측은 근거와 확신을 구별한다. 후회 -을걸은 hätte ... sollen과 비교한다. wohl/scheinen의 추정 기능을 이 후회 용례에 덧씌우지 않는다.
- **EN** [partial] 마저·커녕·이야는 대안 척도와 기대를 전제하며 따름은 주장 범위를 낮춘다. even과 not even이 만드는 대안을 사건 사실과 분리해 쓰고 새로운 기대를 첨가하지 않는다.
- **DE** [partial] 마저·커녕·이야는 대안 척도와 기대를 전제하며 따름은 주장 범위를 낮춘다. sogar와 nicht einmal의 긍정·부정 방향을 이용하되 -도와 모든 척도 조사를 등치하지 않는다.
- **EN** [partial] 공적 목적·의도와 행위 후 태도·상황 의존적 계기를 구별한다. intend to와 keep doing으로 전부 옮기지 않고 -고 들다의 집요함과 -고 보다의 선행 실행을 나눈다.
- **DE** [partial] 공적 목적·의도와 행위 후 태도·상황 의존적 계기를 구별한다. beabsichtigen을 -고자의 문어성과 비교하며 -는 대로의 시간·방식 해석은 문맥으로 고른다.

**16 숙달 점검 (Mastery Check)**
1. [듣기] 발표를 듣고 주장의 범위·예외·확신 수준과 결론 근거를 기록한다.
   - 합격 기준: 추측·강조·한정이 결론에 미치는 효과를 구별한다.
2. [말하기] 같은 자료로 가능한 두 해석을 비교하고 자신의 결론을 적정 강도로 제시한다.
   - 합격 기준: 근거 없는 확신을 추가하지 않고 반론 뒤 논지를 회복한다.
3. [읽기] 논설문과 기사를 읽고 인과·양보·강조·최소 주장만 남기는 표현을 표시한다.
   - 합격 기준: 마저·커녕의 대안 척도를 문맥에서 복원한다.
4. [쓰기] 여러 논거와 반론을 종합해 결론의 범위를 명시하는 의견문을 쓴다.
   - 합격 기준: 근거·반론·예외·결론의 연결이 드러나고 추론이 출처를 넘지 않는다.

---
