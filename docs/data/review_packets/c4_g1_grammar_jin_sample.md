# C4-G1 문법 저작 검토 패킷

상태: **MODEL_QA_PASS, HUMAN_APPROVED 아님**

범위: V2 문법 저작 대기열 우선순위 1~4

예문 규약: 한국어·독일어·영어 셀을 ` / `로 나누며 같은 위치의 예문끼리 대응

## 근거와 판정

- 간접화법: `docs/data/level_bible/V2_grammar_gaps.csv`, 세종학당 한국어
  3B(영어) p.231. 기존 `grammar_b1_indirect_speech`를 평서형 정본으로
  유지하고 B1에 없던 의문·명령·청유만 분리 저작했다.
- `-거든1`: `tools/content_factory/lexicon/nikl_kiiq_2017_grammar.csv`의
  공식 의미 `조건`을 우선했다. 이유를 덧붙이는 종결어미 `-거든요`와
  분리했다. 대기열의 이유 설명은 이 카드에 적용하지 않았다.
- `-다가1(1)`: 같은 NIKL 자료의 의미 `중단`과 기존
  `grammar_a2_interrupted_action`이 일치하므로 새 카드를 만들지 않았다.
- `-지`: 기존 `grammar_a2_tag_confirmation`은 확인·상기와 공손형
  `-지요/-죠`만 다룬다. NIKL의 명령·요청 용법은 아직 근거가 없어
  `observed_syntactic_candidate`로 남겼고 전체 대응으로 세지 않는다.
- `-을 것1`: 같은 NIKL 자료의 공식 의미 `명령/지시`만 적용했다.
  미래 추측·명사화 일반이나 모든 사용 설명서 문장으로 넓히지 않았다.
- `-는 만큼`: `V2_grammar_gaps.csv`의 B1 항목과 대기열 결정을 따랐다.
  이번 카드는 구어의 정도·비례만 다룬다.

## 카드별 검토

| ID · 레벨 · 유닛 | 패턴 · 의미 | 예문 1 KO / DE / EN | 예문 2 KO / DE / EN | 같은 레벨 오답 3개 |
|---|---|---|---|---|
| `grammar_b1_indirect_speech` · B1 · `b1_02_indirect_speech` | `V-(ㄴ/는)다고 하다 / A-다고 하다 / N(이)라고 하다` · 평서 간접화법 | 선생님이 내일 시험이 있다고 말씀하셨습니다.<br>Die Lehrkraft sagte, morgen finde eine Prüfung statt.<br>The teacher said there would be a test tomorrow. | 친구들 중 한 명이 조금 늦는다고 했어.<br>Jemand aus meinem Freundeskreis kündigte an, etwas später zu kommen.<br>One of my friends said they would be a little late. | `grammar_b1_indirect_question`<br>`grammar_b1_indirect_command`<br>`grammar_b1_indirect_suggestion` |
| `grammar_b1_indirect_question` · B1 · `b1_02_indirect_speech` | `A/V-냐고 하다` · 의문 간접화법 | 선생님이 숙제를 했냐고 물으셨습니다.<br>Die Lehrkraft fragte, ob ich die Hausaufgaben gemacht hatte.<br>The teacher asked whether I had done the homework. | 친구가 내일 시간이 있냐고 물었어.<br>Jemand aus meinem Freundeskreis fragte, ob ich morgen Zeit hätte.<br>A friend asked whether I had time tomorrow. | `grammar_b1_indirect_speech`<br>`grammar_b1_indirect_command`<br>`grammar_b1_indirect_suggestion` |
| `grammar_b1_indirect_command` · B1 · `b1_02_indirect_speech` | `V-(으)라고 하다` · 명령·요청 간접화법 | 의사 선생님이 물을 많이 마시라고 하셨습니다.<br>Die ärztliche Anweisung lautete, viel Wasser zu trinken.<br>The doctor told me to drink plenty of water. | 엄마가 일찍 오라고 했어.<br>Meine Mutter sagte, ich solle früh nach Hause kommen.<br>My mother told me to come home early. | `grammar_b1_indirect_speech`<br>`grammar_b1_indirect_question`<br>`grammar_b1_indirect_suggestion` |
| `grammar_b1_indirect_suggestion` · B1 · `b1_02_indirect_speech` | `V-자고 하다` · 청유·제안 간접화법 | 팀장이 내일 다시 만나자고 제안했습니다.<br>Die Teamleitung schlug vor, uns morgen noch einmal zu treffen.<br>The team leader suggested meeting again tomorrow. | 친구가 같이 영화를 보자고 했어.<br>Jemand aus meinem Freundeskreis schlug vor, zusammen einen Film anzusehen.<br>A friend suggested watching a film together. | `grammar_b1_indirect_speech`<br>`grammar_b1_indirect_question`<br>`grammar_b1_indirect_command` |
| `grammar_b1_conditional_geodeun` · B1 · `b1_03_work_softening` | `V-거든` · 뒤따르는 부탁·제안의 조건 | 서류가 준비되거든 연락해 주십시오.<br>Bitte kontaktieren Sie mich, sobald die Unterlagen fertig sind.<br>Please contact me once the documents are ready. | 집에 도착하거든 전화해 줘.<br>Ruf mich an, sobald du zu Hause ankommst.<br>Call me once you get home. | `grammar_b1_explanatory_reason`<br>`grammar_b1_expectation`<br>`grammar_b1_even_if_light` |
| `grammar_b1_proportional_mankeum` · B1 · `b1_01_experience_reasons` | `V-는 만큼 / A-(으)ㄴ 만큼` · 대응하는 정도·비례 | 연습한 만큼 발음이 좋아졌습니다.<br>Je mehr ich übte, desto besser wurde meine Aussprache.<br>The more I practised, the better my pronunciation became. | 먹는 만큼 운동도 해야 해.<br>Je mehr du isst, desto mehr solltest du dich auch bewegen.<br>The more you eat, the more you should exercise. | `grammar_b1_tendency`<br>`grammar_b1_consequence`<br>`grammar_b1_takes_time` |
| `grammar_a2_interrupted_action` · A2 · `a2_06_study_work` | `V-다가` · 진행 중 동작의 중단·전환 | 숙제를 하다가 텔레비전을 봤습니다.<br>Mitten in den Hausaufgaben begann ich fernzusehen.<br>I was doing homework and switched to watching television. | 집에 가다가 친구를 만났어.<br>Auf dem Heimweg traf ich jemanden aus meinem Freundeskreis.<br>I met a friend while I was going home. | `grammar_a2_busy_cause`<br>`grammar_a2_after_finishing`<br>`grammar_a2_simultaneous` |
| `grammar_a2_toward_person` · A2 · `a2_03_chat_relationships` | `N에게로` · 사람·동물을 향한 이동 | 아이가 엄마에게로 걸어갔습니다.<br>Das Kind ging auf seine Mutter zu.<br>The child walked toward their mother. | 강아지가 내게로 왔어.<br>Der Hund kam auf mich zu.<br>The dog came toward me. | `grammar_a2_from_person`<br>`grammar_a2_additive_location`<br>`grammar_a2_starting_point` |
| `grammar_a2_additive_location` · A2 · `a2_08_home_money` | `N에다가 / N에다` · 놓거나 더하는 위치 강조 | 냉장고에다가 우유를 넣었습니다.<br>Ich stellte die Milch in den Kühlschrank.<br>I put the milk in the fridge. | 여기다 이름을 써 줘.<br>Schreib bitte hier den Namen hin.<br>Write the name here for me. | `grammar_a2_toward_person`<br>`grammar_a2_starting_point`<br>`grammar_a2_from_person` |
| `grammar_a2_starting_point` · A2 · `a2_07_travel_repair` | `N에서부터 / N서부터` · 공간·순서의 시작점 | 역에서부터 학교까지 걸었습니다.<br>Ich ging vom Bahnhof bis zur Schule zu Fuß.<br>I walked from the station to the school. | 여기서부터 천천히 읽어 봐.<br>Lies ab hier langsam weiter.<br>Read slowly from here. | `grammar_a2_toward_person`<br>`grammar_a2_additive_location`<br>`grammar_a2_from_person` |
| `grammar_a2_tag_confirmation` · A2 · `a2_02_plans_proposals` | `A/V-지 / -지요(-죠)` · 공유 정보 확인·상기 | 이 노래가 정말 좋지요?<br>Dieses Lied ist wirklich gut, nicht wahr?<br>This song is really good, isn't it? | 그건 내가 어제 말했지.<br>Das habe ich dir doch gestern gesagt.<br>I told you that yesterday, remember. | `grammar_a2_exclamation`<br>`grammar_a2_gentle_question`<br>`grammar_a2_spoken_result` |
| `grammar_a2_written_directive` · A2 · `a2_06_study_work` | `V-(으)ㄹ 것` · 규칙·메모의 짧은 문어 지시 | 내일까지 신청서를 낼 것.<br>Den Antrag bis morgen abgeben.<br>Submit the application by tomorrow. | 교실에서는 음식을 먹지 말 것.<br>Im Klassenraum nicht essen.<br>No eating in the classroom. | `grammar_b1_nominalization`<br>`grammar_a2_future_intention`<br>`grammar_a1_polite_prohibition` |

## 삼언어 감사

- KO 정본은 각 형태의 화행과 격식 차이를 보존한다. `/` 앞은 합쇼체 또는
  공손형, 뒤는 친한 사이의 반말이다. 문어 지시형은 대인 높임이 없는
  표지·메모 장르라 형식/친근 대립을 만들지 않았다.
- EN과 de-DE는 KO의 행위자, 시간, 극성, 인용 화행을 각각 직접
  재구성했다. 간접화법에서 보고자를 추가하지 않았고, `-거든`을 이유로,
  `-(으)ㄹ 것`을 미래로 바꾸지 않았다.
- 독일어 간접화법 예문의 역할어는 `Lehrkraft`, `Teamleitung`,
  `Freundeskreis`, `ärztliche Anweisung`으로 성별을 새로 단정하지 않는다.
  자동·모델 검수 상태만 기록하며 사람 승인 상태는 열어 둔다.
