# Batch 23 (PR-L3a) — Jin 10% 표본 패킷

> 생성 2026-09-08 · 대상: A1 보강 Batch 23의 교체·신규·이동 15건 전부(Fable 전수 직독 완료).
> F8 D-4 절차: 새 문안 12건 중 **표본** 2건(무작위, seed 23)을 우선 보고 ok/반려를 적는다. 이동 3건은 문안이 바뀌지 않았다(레벨·팩만 이동).
> 나머지는 참고용 전체 목록. 반려 항목은 해당 ID만 재작업 → Fable 재검사 → 표본 재발췌.

판정 3항목(F8): ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(A1 = 국제통용 1급 어휘·문법, 문화어 1개 예외).

| 표본 | 구분 | ID | 표제어 | 팩 | KO | DE | EN | Jin 판정 |
|---|---|---|---|---|---|---|---|---|
|  | 교체(동일 ID, 새 문안) | `vocab_a1_0395` | 양해 → 잘못 | `a1_sorry_thanks_1` | 죄송해요, 제 잘못이에요. | Entschuldigung, das war mein Fehler. | Sorry, that was my mistake. |  |
| **표본** | 교체(동일 ID, 새 문안) | `vocab_a1_0310` | 등기 → 편지 | `a1_post_office_1` | 이 편지를 독일로 보내 주세요. | Bitte schicken Sie diesen Brief nach Deutschland. | Please send this letter to Germany. |  |
|  | 교체(동일 ID, 새 문안) | `vocab_a1_0317` | 도착 문자 → 며칠 | `a1_post_office_1` | 독일까지 며칠 걸려요? | Wie viele Tage dauert es bis Deutschland? | How many days does it take to Germany? |  |
|  | 교체(동일 ID, 새 문안) | `vocab_a1_0318` | 포장지 → 가격 | `a1_post_office_1` | 우표 가격이 얼마예요? | Was kostet die Briefmarke? | How much is the stamp? |  |
| **표본** | 신규(새 문안) | `vocab_a1_0428` | 한국 | `a1_particles_in_use_1` | 한국은 지금 가을이에요. | In Korea ist jetzt Herbst. | It's autumn in Korea now. |  |
|  | 신규(새 문안) | `vocab_a1_0429` | 독일 | `a1_particles_in_use_1` | 독일에서 한국까지 비행기로 열 시간 걸려요. | Von Deutschland nach Korea dauert es zehn Stunden mit dem Flugzeug. | From Germany to Korea it takes ten hours by plane. |  |
|  | 신규(새 문안) | `vocab_a1_0430` | 사람 | `a1_particles_in_use_1` | 한국 사람이 정말 친절해요. | Die Menschen in Korea sind wirklich freundlich. | People in Korea are really friendly. |  |
|  | 신규(새 문안) | `vocab_a1_0431` | 외국인 | `a1_particles_in_use_1` | 이 학교에는 외국인이 많아요. | An dieser Schule gibt es viele Ausländer. | There are many foreigners at this school. |  |
|  | 신규(새 문안) | `vocab_a1_0432` | 한국어 | `a1_particles_in_use_1` | 한국어는 어렵지만 재미있어요. | Koreanisch ist schwer, aber es macht Spaß. | Korean is hard, but it's fun. |  |
|  | 신규(새 문안) | `vocab_a1_0433` | 독일어 | `a1_particles_in_use_1` | 선생님도 독일어를 하세요? | Sprechen Sie auch Deutsch? | Do you speak German too? |  |
|  | 신규(새 문안) | `vocab_a1_0434` | 영어 | `a1_particles_in_use_1` | 영어는 조금만 해요. | Englisch spreche ich nur ein bisschen. | I only speak a little English. |  |
|  | 신규(새 문안) | `vocab_a1_0435` | 살다 | `a1_particles_in_use_1` | 부모님은 독일에 사세요. | Meine Eltern leben in Deutschland. | My parents live in Germany. |  |
|  | 하향 이동 B1→A1(문안 불변) | `vocab_b1_0190` | 문장 | `a1_repair_language_1` | 이 문장은 조금 어려워요. | Dieser Satz ist etwas schwierig. | This sentence is a bit difficult. |  |
|  | 하향 이동 B1→A1(문안 불변) | `vocab_b1_0188` | 표현 | `a1_repair_language_1` | 이 표현은 자주 써요. | Diesen Ausdruck benutzt man oft. | This expression is used often. |  |
|  | 하향 이동 B1→A1(문안 불변) | `vocab_b1_0196` | 대답하다 | `a1_repair_language_1` | 질문에 대답해 주세요. | Antworten Sie bitte auf die Frage. | Please answer the question. |  |

## 함께 바뀐 파생 항목

- 교체 4건의 cloze(`cloze_a1_0198`·`0205`·`0206`·`0283`)와 satz(`satz_a1_0162`·`0169`·`0170`·`0247`)는 같은 문장·DE/EN으로 갱신, 배분어는 빈칸 뒤 조사(받침) 정합 기준으로 재선정.
- 옛 표제어(등기·양해 등)를 배분어로 쓰던 cloze 12건·satz 3건은 새 표제어로 치환.
- 신규 8건의 cloze(`cloze_a1_0351`~`0358`)·satz(`satz_a1_0339`~`0346`)는 예문 재사용(TTS 키 공유). `tools/content_factory/drafts/c*_batch23_*`·`review/c*_batch23_*.csv` 참고.
- 이동 3건의 satz(`satz_b1_0401`·`0403`·`0407`)는 레벨만 a1로 이동(원장 `relevel_batch_004`).

## TTS

- 새 발화 키 18건(표제어·예문)은 로컬(Windows 랩탑)에서 `python3 tool/generate_tts.py --missing-from-storage --workers 8` 로 합성·업로드 후 `--verify-storage` missing 0 확인(이 컨테이너에는 GCP 자격 증명 없음).

## 2차 (2026-09-09) — a1_10·a1_15 로더 커버리지 보강 + 결함 수정

> 대상: 새 문안 14건(신규 팩 `a1_first_class_1` 예문 9 + 전공 예문 교체 1 + `a1_body` satz 새 문장 4). **표본** 2건(무작위, seed 24). 이동 2건(사귀다·졸업하다)은 문안 불변, 값→가격 교체(`vocab_a1_0318`)는 1차 표에 반영했다.

| 표본 | 구분 | ID | 표제어/vocabKo | 팩 | KO | DE | EN | Jin 판정 |
|---|---|---|---|---|---|---|---|---|
|  | 신규(새 문안) | `vocab_a1_0436` | 수업 | `a1_first_class_1` | 한국어 수업은 월요일에 있어요. | Der Koreanischunterricht ist am Montag. | Korean class is on Monday. |  |
|  | 신규(새 문안) | `vocab_a1_0437` | 처음 | `a1_first_class_1` | 한국어 수업은 처음이에요. | Koreanischunterricht habe ich zum ersten Mal. | It's my first time taking a Korean class. |  |
|  | 신규(새 문안) | `vocab_a1_0438` | 전화번호 | `a1_first_class_1` | 전화번호를 알려 주세요. | Sagen Sie mir bitte Ihre Telefonnummer. | Please tell me your phone number. |  |
|  | 신규(새 문안) | `vocab_a1_0439` | 대학 | `a1_first_class_1` | 무슨 대학에 다녀요? | An welcher Universität studieren Sie? | Which university do you go to? |  |
|  | 신규(새 문안) | `vocab_a1_0440` | 책상 | `a1_first_class_1` | 책상 위에 책이 있어요. | Auf dem Schreibtisch liegt ein Buch. | There is a book on the desk. |  |
|  | 신규(새 문안) | `vocab_a1_0441` | 연필 | `a1_first_class_1` | 연필로 이름을 써요. | Ich schreibe meinen Namen mit Bleistift. | I write my name with a pencil. |  |
| **표본** | 신규(새 문안) | `vocab_a1_0442` | 공부 | `a1_first_class_1` | 저는 매일 한국어 공부를 해요. | Ich lerne jeden Tag Koreanisch. | I study Korean every day. |  |
|  | 신규(새 문안) | `vocab_a1_0443` | 연습 | `a1_first_class_1` | 매일 발음 연습을 해요. | Ich übe jeden Tag die Aussprache. | I practice pronunciation every day. |  |
|  | 신규(새 문안) | `vocab_a1_0444` | 시작하다 | `a1_first_class_1` | 수업은 아홉 시에 시작해요. | Der Unterricht beginnt um neun Uhr. | Class starts at nine o'clock. |  |
|  | 하향 이동 B2→A1(예문 교체) | `vocab_b2_0060` | 전공 | `a1_first_class_1` | 제 전공은 음악이에요. | Mein Studienfach ist Musik. | My major is music. |  |
|  | 신규 satz(새 문장) | `satz_a1_0347` | 머리 | `a1_body` | 어제부터 머리가 아파요. | Seit gestern habe ich Kopfschmerzen. | I've had a headache since yesterday. |  |
| **표본** | 신규 satz(새 문장) | `satz_a1_0348` | 코 | `a1_body` | 코가 많이 아파요. | Meine Nase tut sehr weh. | My nose hurts a lot. |  |
|  | 신규 satz(새 문장) | `satz_a1_0349` | 손 | `a1_body` | 먼저 손을 씻으세요. | Waschen Sie sich zuerst die Hände. | Please wash your hands first. |  |
|  | 신규 satz(새 문장) | `satz_a1_0350` | 발 | `a1_body` | 많이 걸어서 발이 아파요. | Ich bin viel gelaufen, deshalb tun mir die Füße weh. | My feet hurt because I walked a lot. |  |

- cloze 20건(`cloze_a1_0359`~`0378`)·satz 9건(`satz_a1_0351`~`0359`)은 위 예문 재사용(TTS 키 공유). 이동 satz 3건(`satz_b2_0383` 문안 교체, `satz_b1_0425`·`0450` 불변)은 레벨만 a1.
- 1차 결함 수정: `vocab_a1_0318` 값→**가격**("우표 가격이 얼마예요?", cloze 1음절 정답 금지 규칙), `cloze_a1_0199`·`0352`·`0353` 배분어 교체(문장 잔여부 노출 금지 규칙). 전부 Flutter `cloze_test`/`cloze_content_guard_test` 통과.
- TTS: main 대비 새 발화 키 34건 — 로컬(Windows 랩탑)에서 `python3 tool/generate_tts.py --missing-from-storage --workers 8` → `--verify-storage` missing 0.

## Batch 24 (2026-09-09) — 레벨별 소형 팩 보충 62단어 + cloze 배분어 위생

> 대상: 8단어 미만 팩 16개(A1 3·A2 8·B1 3·B2 2)에 NIKL 해당 등급 표제어 62개(A1 14·A2 24·B1 10·B2 14)를 예문·DE·EN과 함께 추가. 표제어는 전부 사전 등급 ≤ 팩 레벨+1, 예문은 판정기 추정 레벨 ≤ 팩 레벨·미지 토큰 0. **표본** 6건(무작위, seed 25). 파생 cloze 62·satz 62는 예문 재사용.

| 표본 | ID | 표제어 | 팩 | KO | DE | EN | Jin 판정 |
|---|---|---|---|---|---|---|---|
| **표본** | `vocab_a1_0445` | 자동차 | `a1_transport` | 저는 자동차로 회사에 가요. | Ich fahre mit dem Auto zur Arbeit. | I go to work by car. |  |
|  | `vocab_a1_0446` | 역 | `a1_transport` | 역 앞에서 만나요. | Wir treffen uns vor dem Bahnhof. | Let's meet in front of the station. |  |
|  | `vocab_a1_0447` | 공항 | `a1_transport` | 공항까지 버스로 가요. | Zum Flughafen fahre ich mit dem Bus. | I take the bus to the airport. |  |
|  | `vocab_a1_0448` | 출발 | `a1_transport` | 출발 시간이 몇 시예요? | Um wie viel Uhr ist die Abfahrt? | What time is the departure? |  |
|  | `vocab_a1_0449` | 도착 | `a1_transport` | 서울에 도착 후에 전화해요. | Nach der Ankunft in Seoul rufe ich an. | After arriving in Seoul, I'll call. |  |
|  | `vocab_a1_0450` | 타다 | `a1_transport` | 버스를 타고 학교에 가요. | Ich fahre mit dem Bus zur Schule. | I take the bus to school. |  |
|  | `vocab_a1_0451` | 내리다 | `a1_transport` | 다음 역에서 내려요. | Ich steige an der nächsten Station aus. | I get off at the next station. |  |
|  | `vocab_a1_0452` | 돈 | `a1_payment_delivery_1` | 지금 돈이 없어요. | Ich habe gerade kein Geld. | I don't have money right now. |  |
|  | `vocab_a1_0453` | 원 | `a1_payment_delivery_1` | 커피는 사천 원이에요. | Der Kaffee kostet viertausend Won. | The coffee is four thousand won. |  |
|  | `vocab_a1_0454` | 번호 | `a1_payment_delivery_1` | 제 번호는 십오 번이에요. | Meine Nummer ist die Fünfzehn. | My number is fifteen. |  |
|  | `vocab_a1_0455` | 기다리다 | `a1_payment_delivery_1` | 문 앞에서 기다려요. | Ich warte vor der Tür. | I'm waiting in front of the door. |  |
|  | `vocab_a1_0456` | 다시 | `a1_repair_language_1` | 다시 한번 말해 주세요. | Bitte sagen Sie es noch einmal. | Please say it once more. |  |
|  | `vocab_a1_0457` | 단어 | `a1_repair_language_1` | 이 단어는 무슨 뜻이에요? | Was bedeutet dieses Wort? | What does this word mean? |  |
|  | `vocab_a1_0458` | 사전 | `a1_repair_language_1` | 사전에서 단어를 찾아요. | Ich schlage das Wort im Wörterbuch nach. | I look the word up in the dictionary. |  |
|  | `vocab_a2_0477` | 학년 | `a2_education` | 저는 지금 대학교 이 학년이에요. | Ich bin jetzt im zweiten Studienjahr. | I'm in my second year of university now. |  |
|  | `vocab_a2_0478` | 복습 | `a2_education` | 수업 후에 꼭 복습을 해요. | Nach dem Unterricht wiederhole ich den Stoff auf jeden Fall. | I always review after class. |  |
|  | `vocab_a2_0479` | 예습 | `a2_education` | 내일 수업 예습은 벌써 끝냈어요. | Die Vorbereitung für den Unterricht morgen habe ich schon fertig. | I've already finished preparing for tomorrow's class. |  |
|  | `vocab_a2_0480` | 국 | `a2_food_1` | 국이 좀 식었네요. | Die Suppe ist etwas kalt geworden. | The soup has gotten a bit cold. |  |
|  | `vocab_a2_0481` | 접시 | `a2_food_1` | 접시 하나만 더 주세요. | Bitte noch einen Teller. | One more plate, please. |  |
|  | `vocab_a2_0482` | 설탕 | `a2_food_1` | 커피에 설탕은 안 넣어요. | In den Kaffee tue ich keinen Zucker. | I don't put sugar in my coffee. |  |
|  | `vocab_a2_0483` | 끓이다 | `a2_food_2` | 물을 끓여서 차를 마셔요. | Ich koche Wasser und trinke Tee. | I boil water and drink tea. |  |
|  | `vocab_a2_0484` | 볶다 | `a2_food_2` | 고기를 먼저 볶으세요. | Braten Sie zuerst das Fleisch an. | Stir-fry the meat first. |  |
|  | `vocab_a2_0485` | 굽다 | `a2_food_2` | 생선은 굽는 게 제일 맛있어요. | Fisch schmeckt gegrillt am besten. | Fish tastes best grilled. |  |
|  | `vocab_a2_0486` | 마트 | `a2_shopping_1` | 퇴근하고 마트에 들를게요. | Nach der Arbeit gehe ich noch kurz in den Supermarkt. | I'll stop by the supermarket after work. |  |
| **표본** | `vocab_a2_0487` | 상자 | `a2_shopping_1` | 이 상자에 다 넣어 주세요. | Bitte legen Sie alles in diesen Karton. | Please put everything in this box. |  |
|  | `vocab_a2_0488` | 디자인 | `a2_shopping_1` | 디자인은 예쁘지만 좀 비싸요. | Das Design ist schön, aber etwas teuer. | The design is pretty, but it's a bit pricey. |  |
|  | `vocab_a2_0489` | 반바지 | `a2_shopping_2` | 여름이라서 반바지를 샀어요. | Weil Sommer ist, habe ich eine kurze Hose gekauft. | Since it's summer, I bought shorts. |  |
|  | `vocab_a2_0490` | 단추 | `a2_shopping_2` | 단추가 하나 떨어졌어요. | Ein Knopf ist abgegangen. | A button has come off. |  |
|  | `vocab_a2_0491` | 모양 | `a2_shopping_2` | 모양은 마음에 들지만 색이 별로예요. | Die Form gefällt mir, aber die Farbe nicht so. | I like the shape, but the color isn't great. |  |
|  | `vocab_a2_0492` | 심심하다 | `a2_feelings_2` | 주말에 혼자 있으니까 심심해요. | Am Wochenende bin ich allein, deshalb ist mir langweilig. | I'm alone on the weekend, so I'm bored. |  |
|  | `vocab_a2_0493` | 편하다 | `a2_feelings_2` | 이 신발은 정말 편해요. | Diese Schuhe sind wirklich bequem. | These shoes are really comfortable. |  |
|  | `vocab_a2_0494` | 즐겁다 | `a2_feelings_2` | 오늘 하루가 정말 즐거워요. | Der Tag heute ist wirklich schön. | Today is really enjoyable. |  |
|  | `vocab_a2_0495` | 약속 | `a2_plans_proposals_1` | 이번 주말에 약속 있어요? | Hast du am Wochenende schon etwas vor? | Do you have plans this weekend? |  |
|  | `vocab_a2_0496` | 계획 | `a2_plans_proposals_1` | 방학 계획은 세웠어요? | Hast du schon Pläne für die Ferien gemacht? | Have you made plans for the vacation? |  |
|  | `vocab_a2_0497` | 시간표 | `a2_plans_proposals_1` | 시간표를 보고 시간을 정해요. | Wir schauen auf den Stundenplan und legen die Zeit fest. | Let's check the timetable and set a time. |  |
|  | `vocab_a2_0498` | 비다 | `a2_plans_proposals_1` | 목요일 오후는 시간이 비어요. | Donnerstagnachmittag habe ich Zeit. | Thursday afternoon I'm free. |  |
|  | `vocab_a2_0499` | 가능하다 | `a2_plans_proposals_1` | 다음 주로 바꾸는 것도 가능해요. | Man kann es auch auf nächste Woche verschieben. | Changing it to next week is also possible. |  |
|  | `vocab_a2_0500` | 휴일 | `a2_plans_proposals_1` | 휴일에는 보통 늦게 일어나요. | An freien Tagen stehe ich meistens spät auf. | On days off I usually get up late. |  |
|  | `vocab_a2_0501` | 하늘색 | `a2_descriptions_2` | 하늘색 셔츠가 잘 어울려요. | Das hellblaue Hemd steht dir gut. | The light blue shirt suits you. |  |
|  | `vocab_a2_0502` | 진하다 | `a2_descriptions_2` | 커피가 너무 진해요. | Der Kaffee ist zu stark. | The coffee is too strong. |  |
|  | `vocab_a2_0503` | 두껍다 | `a2_descriptions_2` | 코트가 두껍고 따뜻해요. | Der Mantel ist dick und warm. | The coat is thick and warm. |  |
|  | `vocab_b1_0480` | 부담 | `b1_work_softening_1` | 부담 갖지 말고 편하게 말씀해 주세요. | Fühlen Sie sich nicht unter Druck gesetzt, sprechen Sie ganz offen. | Please don't feel pressured; speak freely. |  |
|  | `vocab_b1_0481` | 협조 | `b1_work_softening_1` | 일정 조정에 협조해 주셔서 감사합니다. | Danke, dass Sie bei der Terminabstimmung mitgeholfen haben. | Thank you for cooperating with the schedule change. |  |
|  | `vocab_b1_0482` | 출근 | `b1_work_softening_1` | 내일은 출근이 조금 늦을 것 같아요. | Morgen komme ich wahrscheinlich etwas später zur Arbeit. | I'll probably be a little late to work tomorrow. |  |
|  | `vocab_b1_0483` | 퇴근 | `b1_work_softening_1` | 퇴근 전에 보고서를 보낼게요. | Vor Feierabend schicke ich den Bericht. | I'll send the report before I leave work. |  |
|  | `vocab_b1_0484` | 격려하다 | `b1_emotions_relations_2` | 힘들 때마다 친구가 저를 격려해 줬어요. | Immer wenn es schwer war, hat mich meine Freundin ermutigt. | Whenever things were hard, my friend encouraged me. |  |
|  | `vocab_b1_0485` | 위로하다 | `b1_emotions_relations_2` | 슬퍼하는 친구를 위로했어요. | Ich habe meinen traurigen Freund getröstet. | I comforted my sad friend. |  |
|  | `vocab_b1_0486` | 존중하다 | `b1_emotions_relations_2` | 서로의 의견을 존중하는 게 중요해요. | Es ist wichtig, die Meinung des anderen zu respektieren. | It's important to respect each other's opinions. |  |
|  | `vocab_b1_0487` | 감정 | `b1_emotions_relations_3` | 제 감정을 말로 표현하기가 어려워요. | Es fällt mir schwer, meine Gefühle in Worte zu fassen. | It's hard for me to put my feelings into words. |  |
| **표본** | `vocab_b1_0488` | 오해 | `b1_emotions_relations_3` | 서로 오해가 있었던 것 같아요. | Ich glaube, wir hatten ein Missverständnis. | I think there was a misunderstanding between us. |  |
|  | `vocab_b1_0489` | 화해하다 | `b1_emotions_relations_3` | 싸운 다음 날 바로 화해했어요. | Am Tag nach dem Streit haben wir uns gleich versöhnt. | We made up the day right after the fight. |  |
|  | `vocab_b2_0647` | 개념 | `b2_abstract_concepts_1` | 이 개념은 예를 들어 설명하는 편이 이해하기 쉬워요. | Diesen Begriff versteht man leichter, wenn man ihn mit Beispielen erklärt. | This concept is easier to understand when explained with examples. |  |
|  | `vocab_b2_0648` | 요소 | `b2_abstract_concepts_1` | 성공에는 운도 중요한 요소예요. | Auch Glück ist ein wichtiger Faktor für den Erfolg. | Luck is also an important factor in success. |  |
| **표본** | `vocab_b2_0649` | 원리 | `b2_abstract_concepts_1` | 원리를 알면 응용은 어렵지 않아요. | Wenn man das Prinzip versteht, ist die Anwendung nicht schwer. | Once you know the principle, applying it isn't hard. |  |
|  | `vocab_b2_0650` | 가치 | `b2_abstract_concepts_1` | 이 일의 가치는 돈으로 따질 수 없어요. | Der Wert dieser Arbeit lässt sich nicht in Geld messen. | The value of this work can't be measured in money. |  |
|  | `vocab_b2_0651` | 본질 | `b2_abstract_concepts_1` | 문제의 본질을 먼저 파악해야 해요. | Man muss zuerst den Kern des Problems erfassen. | You have to grasp the essence of the problem first. |  |
|  | `vocab_b2_0652` | 특징 | `b2_abstract_concepts_1` | 이 제품의 가장 큰 특징은 가벼운 무게예요. | Das größte Merkmal dieses Produkts ist sein geringes Gewicht. | This product's biggest feature is its light weight. |  |
|  | `vocab_b2_0653` | 학문 | `b2_education` | 학문의 길은 끝이 없는 것 같아요. | Der Weg der Wissenschaft scheint kein Ende zu haben. | The path of scholarship seems to have no end. |  |
| **표본** | `vocab_b2_0654` | 강의 | `b2_education` | 그 교수님 강의는 항상 자리가 없어요. | In der Vorlesung von diesem Professor sind die Plätze immer voll. | That professor's lectures are always full. |  |
| **표본** | `vocab_b2_0655` | 지식 | `b2_education` | 지식보다 경험이 더 중요할 때도 있어요. | Manchmal ist Erfahrung wichtiger als Wissen. | Sometimes experience matters more than knowledge. |  |
|  | `vocab_b2_0656` | 과제 | `b2_education` | 이번 학기 과제는 팀으로 진행해요. | Die Hausarbeit in diesem Semester machen wir im Team. | This semester's assignment is done in teams. |  |
|  | `vocab_b2_0657` | 성과 | `b2_education` | 일 년 동안의 연구 성과를 발표했어요. | Ich habe die Forschungsergebnisse eines Jahres vorgestellt. | I presented the results of a year's research. |  |

- cloze 배분어 위생(P1): 조사 앞 받침 불일치·문장 잔여부 노출 배분어 1,456칸(834항목)을 같은 레벨·같은 품사·다른 주제의 표제어로 결정적 교체. 정답·문장·DE/EN 불변. `audit_content_naturalness` 후보 897→73(particle_mismatch 824→0), `cloze_content_guard_test` allowlist 0. batch_09 항목 342건은 copy-revision 원장에 기록. 표본은 `git diff 0c67d19..HEAD -- assets/data/cloze.json`에서 무작위로 보면 된다(정답이 아닌 오답 후보만 바뀜).
- TTS: main 대비 새 발화 키 133건 — Jin 로컬(Windows 랩탑)에서 `python3 tool/generate_tts.py --missing-from-storage --workers 8` → `--verify-storage` missing 0.
