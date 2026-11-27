# C3 Batch 43 B1 Jin review packet

상태: **초안 64단어 / 빈칸 64세트 / 문장 조립 64세트** — 승인 전, 앱 데이터(`assets/data/**`) 무수정.

## 범위와 산술

- 국립국어원 3급 표제어(접사 제외) **1593**개 중 앱에 있는 것 **230**, 없는 것 **1363**.
- 이번 배치 **64**개를 더하면 남는 결손은 **1299**.
- 고른 기준: 국립국어원 기초 어휘(2023) 1등급, 집안일·몸 상태·감정·한국어 공부처럼 B1 학습자가 바로 쓰는 말. 하다/되다 형태가 이미 앱에 있는 명사는 뺐다.
- 예문: B1 상한(16어절·3절·3급 문법) 안에서 짧게. 표제어 말고는 3급 이하이거나 앱에 이미 있는 단어만 쓴다.
- 오답 보기는 정답의 조사·어미를 그대로 두고, DE/EN 뜻과 함께 읽으면 틀린 것으로 골랐다. 문장 조립 타일은 빈칸 오답 앞의 두 개.

## 팩

| 팩 | 구분 | 단어 |
|---|---|---|
| `b1_verbs_daily_1` | 빈 자리 채움 (fills empty pack_order 3 (11 -> 12)) | 챙기다 |
| `b1_time_life_1` | 빈 자리 채움 (fills empty pack_order 7 (11 -> 12)) | 추억 |
| `b1_health_education` | 빈 자리 채움 (fills empty pack_order 2 (10 -> 11)) | 예방 |
| `b1_communication_lang_1` | 빈 자리 채움 (fills empty pack_order 1, 3, 5, 8, 9 (8 -> 13)) | 알아듣다, 한자, 읽기, 쓰기, 한국말 |
| `b1_daily_4` | 새 팩 (12단어) | 먼지, 걸레, 세제, 다리미, 커튼, 베란다, 전자레인지, 봉지, 도시락, 볼일, 배터리, 사용법 |
| `b1_verbs_daily_2` | 새 팩 (12단어) | 아끼다, 옮기다, 잠그다, 널다, 쏟다, 깨지다, 묶다, 덮다, 채우다, 밀리다, 놓치다, 사라지다 |
| `b1_emotions_relations_4` | 새 팩 (12단어) | 속상하다, 아쉽다, 창피, 실망, 안심, 다행히, 혼나다, 부러워하다, 불만, 존경, 우정, 진심 |
| `b1_health_hospital_2` | 새 팩 (12단어) | 가렵다, 어지럽다, 붓다, 코피, 멀미, 체하다, 소화, 발목, 몸살, 독감, 진찰, 응급실 |
| `b1_descriptions_adj_2` | 새 팩 (8단어) | 낡다, 깔끔하다, 지저분하다, 싱싱하다, 낯설다, 신기하다, 멋지다, 대단하다 |

새 팩 5개는 모두 기존 B1 팩 계열이라 팩 제목(packDisplayMap) 등록은 필요 없지만, 승격 때 content authority·cluster·vocabPackUnitMap·coverage 등록이 먼저 있어야 한다.

판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가 ③ B1 안인가.

## Jin 표본 7행

### vocab_b1_0490 — 챙기다

- KO: 여행 가기 전에 여권을 꼭 챙기세요.
- DE: Denken Sie vor der Reise unbedingt an Ihren Reisepass.
- EN: Make sure to pack your passport before the trip.
- Cloze `cloze_b1_0292`: 여행 가기 전에 여권을 꼭 ＿＿＿. → `챙기세요` · ['버리세요', '고치세요', '닦으세요']
- Satz `satz_b1_0485`: 여행 가기 전에 여권을 꼭 챙기세요. · ['버리세요', '고치세요']

### vocab_b1_0499 — 걸레

- KO: 바닥이 더러워서 걸레로 깨끗하게 닦았어요.
- DE: Der Boden war schmutzig, deshalb habe ich ihn mit dem Lappen gewischt.
- EN: The floor was dirty, so I wiped it clean with a rag.
- Cloze `cloze_b1_0301`: 바닥이 더러워서 ＿＿＿ 깨끗하게 닦았어요. → `걸레로` · ['치마로', '모자로', '가위로']
- Satz `satz_b1_0494`: 바닥이 더러워서 걸레로 깨끗하게 닦았어요. · ['치마로', '모자로']

### vocab_b1_0508 — 배터리

- KO: 휴대폰 배터리가 다 돼서 전화를 못 받았어요.
- DE: Mein Handyakku war leer, deshalb konnte ich nicht rangehen.
- EN: My phone battery died, so I couldn't answer the call.
- Cloze `cloze_b1_0310`: 휴대폰 ＿＿＿ 다 돼서 전화를 못 받았어요. → `배터리가` · ['카메라가', '라디오가', '주스가']
- Satz `satz_b1_0503`: 휴대폰 배터리가 다 돼서 전화를 못 받았어요. · ['카메라가', '라디오가']

### vocab_b1_0517 — 덮다

- KO: 밤에는 추워서 두꺼운 이불을 덮고 자요.
- DE: Nachts ist es kalt, deshalb schlafe ich unter einer dicken Decke.
- EN: It's cold at night, so I sleep under a thick blanket.
- Cloze `cloze_b1_0319`: 밤에는 추워서 두꺼운 이불을 ＿＿＿ 자요. → `덮고` · ['팔고', '찾고', '빌리고']
- Satz `satz_b1_0512`: 밤에는 추워서 두꺼운 이불을 덮고 자요. · ['팔고', '찾고']

### vocab_b1_0526 — 안심

- KO: 아이한테서 잘 도착했다고 문자가 와서 안심했어요.
- DE: Mein Kind hat geschrieben, dass es gut angekommen ist, da war ich erleichtert.
- EN: My kid texted that they'd arrived safely, so I felt relieved.
- Cloze `cloze_b1_0328`: 아이한테서 잘 도착했다고 문자가 와서 ＿＿＿. → `안심했어요` · ['실수했어요', '결석했어요', '운전했어요']
- Satz `satz_b1_0521`: 아이한테서 잘 도착했다고 문자가 와서 안심했어요. · ['실수했어요', '결석했어요']

### vocab_b1_0535 — 어지럽다

- KO: 잠을 못 자서 머리가 좀 어지러워요.
- DE: Ich habe nicht geschlafen, deshalb ist mir etwas schwindlig.
- EN: I didn't sleep, so I feel a bit dizzy.
- Cloze `cloze_b1_0337`: 잠을 못 자서 머리가 좀 ＿＿＿. → `어지러워요` · ['가까워요', '부드러워요', '시끄러워요']
- Satz `satz_b1_0530`: 잠을 못 자서 머리가 좀 어지러워요. · ['가까워요', '부드러워요']

### vocab_b1_0544 — 진찰

- KO: 열이 계속 나서 병원에서 진찰을 받았어요.
- DE: Ich hatte immer noch Fieber, deshalb habe ich mich im Krankenhaus untersuchen lassen.
- EN: My fever wouldn't go away, so I got examined at the hospital.
- Cloze `cloze_b1_0346`: 열이 계속 나서 병원에서 ＿＿＿ 받았어요. → `진찰을` · ['월급을', '선물을', '장학금을']
- Satz `satz_b1_0539`: 열이 계속 나서 병원에서 진찰을 받았어요. · ['월급을', '선물을']

## 전체 64행

| # | 단어 | 팩 | 예문 | DE | EN | 빈칸 정답 | 오답 보기 |
|---|---|---|---|---|---|---|---|
| 1 | 챙기다 | `b1_verbs_daily_1` 3 | 여행 가기 전에 여권을 꼭 챙기세요. | Denken Sie vor der Reise unbedingt an Ihren Reisepass. | Make sure to pack your passport before the trip. | `챙기세요` | 버리세요, 고치세요, 닦으세요 |
| 2 | 추억 | `b1_time_life_1` 7 | 친구들하고 간 제주도 여행은 정말 좋은 추억이에요. | Die Jeju-Reise mit meinen Freunden ist eine wirklich schöne Erinnerung. | The trip to Jeju with my friends is a really good memory. | `추억이에요` | 습관이에요, 직업이에요, 약속이에요 |
| 3 | 예방 | `b1_health_education` 2 | 감기 예방에는 손을 자주 씻는 게 제일 좋아요. | Um Erkältungen vorzubeugen, wäscht man sich am besten oft die Hände. | The best way to prevent colds is to wash your hands often. | `예방에는` | 검사에는, 주사에는, 수술에는 |
| 4 | 알아듣다 | `b1_communication_lang_1` 1 | 선생님이 너무 빨리 말씀하셔서 잘 못 알아들었어요. | Die Lehrerin hat so schnell gesprochen, dass ich sie kaum verstanden habe. | The teacher spoke so fast that I couldn't really understand. | `알아들었어요` | 들어왔어요, 돌아왔어요, 일어났어요 |
| 5 | 한자 | `b1_communication_lang_1` 3 | 한국어 단어 중에는 한자로 된 말이 많아요. | Viele koreanische Wörter gehen auf chinesische Schriftzeichen zurück. | Many Korean words come from Chinese characters. | `한자로` | 숫자로, 모자로, 의자로 |
| 6 | 읽기 | `b1_communication_lang_1` 5 | 저는 읽기는 괜찮은데 듣기가 아직 어려워요. | Lesen klappt bei mir ganz gut, aber Hören fällt mir noch schwer. | Reading is fine for me, but listening is still hard. | `읽기는` | 노래는, 요리는, 축구는 |
| 7 | 쓰기 | `b1_communication_lang_1` 8 | 오늘 한국어 쓰기 숙제로 일기를 썼어요. | Heute habe ich als Schreibaufgabe für Koreanisch einen Tagebucheintrag geschrieben. | Today I wrote a diary entry for my Korean writing homework. | `쓰기` | 듣기, 수학, 미술 |
| 8 | 한국말 | `b1_communication_lang_1` 9 | 레나 씨, 한국말 정말 많이 늘었네요! | Lena, dein Koreanisch ist echt viel besser geworden! | Lena, your Korean has really improved a lot! | `한국말` | 노래, 운전, 수영 |
| 9 | 먼지 | `b1_daily_4` 1 | 오랫동안 청소를 안 해서 책상 위에 먼지가 많아요. | Ich habe lange nicht geputzt, deshalb liegt viel Staub auf dem Schreibtisch. | I haven't cleaned in a long time, so there's a lot of dust on the desk. | `먼지가` | 우유가, 의자가, 시계가 |
| 10 | 걸레 | `b1_daily_4` 2 | 바닥이 더러워서 걸레로 깨끗하게 닦았어요. | Der Boden war schmutzig, deshalb habe ich ihn mit dem Lappen gewischt. | The floor was dirty, so I wiped it clean with a rag. | `걸레로` | 치마로, 모자로, 가위로 |
| 11 | 세제 | `b1_daily_4` 3 | 빨래할 때 세제를 조금만 넣어도 깨끗해져요. | Beim Waschen wird die Wäsche schon mit wenig Waschmittel sauber. | When you do laundry, even a little detergent gets things clean. | `세제를` | 주스를, 커피를, 우유를 |
| 12 | 다리미 | `b1_daily_4` 4 | 다리미가 아직 뜨거우니까 만지지 마세요. | Fassen Sie das Bügeleisen nicht an, es ist noch heiß. | Don't touch the iron, it's still hot. | `다리미가` | 치마가, 카메라가, 모자가 |
| 13 | 커튼 | `b1_daily_4` 5 | 아침에 햇빛이 너무 강해서 커튼을 쳤어요. | Morgens war die Sonne so grell, dass ich die Vorhänge zugezogen habe. | The morning sun was so bright that I closed the curtains. | `커튼을` | 신발을, 선물을, 교실을 |
| 14 | 베란다 | `b1_daily_4` 6 | 저는 베란다에서 토마토를 키워요. | Ich ziehe auf dem Balkon Tomaten. | I grow tomatoes on the balcony. | `베란다에서` | 교실에서, 지하철에서, 은행에서 |
| 15 | 전자레인지 | `b1_daily_4` 7 | 밥이 식어서 전자레인지에 1분 정도 돌렸어요. | Der Reis war kalt, also habe ich ihn etwa eine Minute in die Mikrowelle gestellt. | The rice had gone cold, so I microwaved it for about a minute. | `전자레인지에` | 세탁기에, 가방에, 냉장고에 |
| 16 | 봉지 | `b1_daily_4` 8 | 봉지는 괜찮아요. 그냥 가방에 넣어 갈게요. | Ich brauche keine Tüte. Ich packe es einfach in meine Tasche. | I don't need a plastic bag. I'll just put it in my own bag. | `봉지는` | 의자는, 치마는, 우유는 |
| 17 | 도시락 | `b1_daily_4` 9 | 회사 근처 식당이 비싸서 요즘 도시락을 싸 가요. | Die Restaurants bei der Firma sind teuer, deshalb nehme ich mir zurzeit Essen mit. | The restaurants near work are expensive, so these days I bring a packed lunch. | `도시락을` | 책상을, 신발을, 우산을 |
| 18 | 볼일 | `b1_daily_4` 10 | 잠깐 볼일이 있어서 은행에 다녀올게요. | Ich muss kurz etwas erledigen und gehe schnell zur Bank. | I have a quick errand, so I'll pop over to the bank. | `볼일이` | 음식이, 선물이, 가족이 |
| 19 | 배터리 | `b1_daily_4` 11 | 휴대폰 배터리가 다 돼서 전화를 못 받았어요. | Mein Handyakku war leer, deshalb konnte ich nicht rangehen. | My phone battery died, so I couldn't answer the call. | `배터리가` | 카메라가, 라디오가, 주스가 |
| 20 | 사용법 | `b1_daily_4` 12 | 새로 산 세탁기 사용법을 잘 모르겠어요. | Ich weiß nicht so recht, wie die neue Waschmaschine funktioniert. | I'm not really sure how to use the new washing machine. | `사용법을` | 이름을, 색깔을, 모양을 |
| 21 | 아끼다 | `b1_verbs_daily_2` 1 | 돈을 아끼려고 요즘 집에서 밥을 해 먹어요. | Um Geld zu sparen, koche ich zurzeit zu Hause. | I've been cooking at home lately to save money. | `아끼려고` | 버리려고, 빌리려고, 보내려고 |
| 22 | 옮기다 | `b1_verbs_daily_2` 2 | 크리스티안 씨, 이 상자 좀 같이 옮겨 줄 수 있어요? | Christian, kannst du mir helfen, diese Kiste zu tragen? | Christian, could you help me carry this box? | `옮겨` | 입어, 읽어, 먹어 |
| 23 | 잠그다 | `b1_verbs_daily_2` 3 | 집에서 나갈 때 문을 꼭 잠가 주세요. | Bitte schließen Sie die Tür ab, wenn Sie aus dem Haus gehen. | Please make sure to lock the door when you leave the house. | `잠가` | 팔아, 찾아, 앉아 |
| 24 | 널다 | `b1_verbs_daily_2` 4 | 날씨가 좋아서 베란다에 빨래를 널었어요. | Bei dem schönen Wetter habe ich die Wäsche auf dem Balkon aufgehängt. | The weather was nice, so I hung laundry on the balcony. | `널었어요` | 먹었어요, 읽었어요, 입었어요 |
| 25 | 쏟다 | `b1_verbs_daily_2` 5 | 아침에 급하게 나가다가 커피를 쏟았어요. | Als ich morgens in Eile losging, habe ich meinen Kaffee verschüttet. | I spilled my coffee while rushing out this morning. | `쏟았어요` | 팔았어요, 닫았어요, 앉았어요 |
| 26 | 깨지다 | `b1_verbs_daily_2` 6 | 어제 설거지하다가 접시가 하나 깨졌어요. | Gestern ist mir beim Abwaschen ein Teller zerbrochen. | Yesterday a plate broke while I was doing the dishes. | `깨졌어요` | 커졌어요, 길어졌어요, 많아졌어요 |
| 27 | 묶다 | `b1_verbs_daily_2` 7 | 저는 운동할 때 머리를 뒤로 묶어요. | Beim Sport binde ich mir die Haare zurück. | When I work out, I tie my hair back. | `묶어요` | 씻어요, 그려요, 닦아요 |
| 28 | 덮다 | `b1_verbs_daily_2` 8 | 밤에는 추워서 두꺼운 이불을 덮고 자요. | Nachts ist es kalt, deshalb schlafe ich unter einer dicken Decke. | It's cold at night, so I sleep under a thick blanket. | `덮고` | 팔고, 찾고, 빌리고 |
| 29 | 채우다 | `b1_verbs_daily_2` 9 | 냉장고를 채우려고 마트에서 장을 많이 봤어요. | Ich habe im Supermarkt groß eingekauft, um den Kühlschrank zu füllen. | I did a big grocery run to fill up the fridge. | `채우려고` | 고치려고, 버리려고, 바꾸려고 |
| 30 | 밀리다 | `b1_verbs_daily_2` 10 | 퇴근 시간이라 길이 많이 밀려요. | Es ist Feierabendverkehr, deshalb staut es sich ziemlich. | It's rush hour, so traffic is really backed up. | `밀려요` | 열려요, 팔려요, 닫혀요 |
| 31 | 놓치다 | `b1_verbs_daily_2` 11 | 늦잠을 자서 버스를 놓쳤어요. | Ich habe verschlafen und den Bus verpasst. | I overslept and missed the bus. | `놓쳤어요` | 고쳤어요, 가르쳤어요, 그렸어요 |
| 32 | 사라지다 | `b1_verbs_daily_2` 12 | 집 앞에 세워 둔 자전거가 사라졌어요. | Das Fahrrad, das ich vor dem Haus abgestellt hatte, ist verschwunden. | The bike I'd left in front of the house has disappeared. | `사라졌어요` | 열렸어요, 닫혔어요, 끝났어요 |
| 33 | 속상하다 | `b1_emotions_relations_4` 1 | 열심히 준비했는데 시험에 떨어져서 너무 속상해요. | Ich habe mich so gut vorbereitet und bin trotzdem durchgefallen, ich bin total geknickt. | I prepared so hard and still failed the exam, so I'm really upset. | `속상해요` | 행복해요, 편해요, 조용해요 |
| 34 | 아쉽다 | `b1_emotions_relations_4` 2 | 벌써 여행이 끝나서 정말 아쉬워요. | Wirklich schade, dass die Reise schon vorbei ist. | It's a real shame the trip is already over. | `아쉬워요` | 가벼워요, 무거워요, 가까워요 |
| 35 | 창피 | `b1_emotions_relations_4` 3 | 사람들 앞에서 넘어져서 너무 창피했어요. | Ich bin vor allen Leuten hingefallen, das war mir total peinlich. | I fell over in front of everyone, and it was so embarrassing. | `창피했어요` | 시원했어요, 깨끗했어요, 조용했어요 |
| 36 | 실망 | `b1_emotions_relations_4` 4 | 기대를 많이 했는데 결과가 안 좋아서 실망했어요. | Ich hatte mir viel erhofft, aber das Ergebnis war schlecht, deshalb war ich enttäuscht. | I had high hopes, but the result was bad, so I was disappointed. | `실망했어요` | 졸업했어요, 출발했어요, 도착했어요 |
| 37 | 안심 | `b1_emotions_relations_4` 5 | 아이한테서 잘 도착했다고 문자가 와서 안심했어요. | Mein Kind hat geschrieben, dass es gut angekommen ist, da war ich erleichtert. | My kid texted that they'd arrived safely, so I felt relieved. | `안심했어요` | 실수했어요, 결석했어요, 운전했어요 |
| 38 | 다행히 | `b1_emotions_relations_4` 6 | 지갑을 잃어버렸는데 다행히 누가 경찰서에 맡겨 줬어요. | Ich hatte meinen Geldbeutel verloren, aber zum Glück hat ihn jemand bei der Polizei abgegeben. | I lost my wallet, but luckily someone handed it in to the police. | `다행히` | 천천히, 조용히, 열심히 |
| 39 | 혼나다 | `b1_emotions_relations_4` 7 | 어릴 때 동생이랑 싸워서 엄마한테 많이 혼났어요. | Als Kind hat mich meine Mutter oft ausgeschimpft, weil ich mich mit meinem Bruder gestritten habe. | As a kid, I often got scolded by my mom for fighting with my brother. | `혼났어요` | 만났어요, 끝났어요, 일어났어요 |
| 40 | 부러워하다 | `b1_emotions_relations_4` 8 | 동생은 제가 해외에서 공부하는 걸 많이 부러워해요. | Mein jüngerer Bruder beneidet mich sehr darum, dass ich im Ausland studiere. | My younger brother really envies me for studying abroad. | `부러워해요` | 무서워해요, 어려워해요, 귀여워해요 |
| 41 | 불만 | `b1_emotions_relations_4` 9 | 손님이 음식이 늦게 나왔다고 불만을 이야기했어요. | Ein Gast hat sich beschwert, dass das Essen zu spät kam. | A customer complained that the food came out late. | `불만을` | 이름을, 선물을, 약속을 |
| 42 | 존경 | `b1_emotions_relations_4` 10 | 저는 어려운 사람을 늘 돕는 할머니를 존경해요. | Ich habe großen Respekt vor meiner Oma, weil sie immer Bedürftigen hilft. | I respect my grandmother, who always helps people in need. | `존경해요` | 졸업해요, 출발해요, 청소해요 |
| 43 | 우정 | `b1_emotions_relations_4` 11 | 앞으로도 우리 우정이 변하지 않았으면 좋겠어요. | Ich hoffe, dass sich unsere Freundschaft auch in Zukunft nicht ändert. | I hope our friendship never changes. | `우정이` | 시험이, 수업이, 기침이 |
| 44 | 진심 | `b1_emotions_relations_4` 12 | 수진 씨, 진심으로 고마워요. 덕분에 이사를 잘 끝냈어요. | Sujin, ich danke dir von Herzen. Dank dir hat der Umzug gut geklappt. | Sujin, I'm truly grateful. Thanks to you, the move went smoothly. | `진심으로` | 오른쪽으로, 왼쪽으로, 처음으로 |
| 45 | 가렵다 | `b1_health_hospital_2` 1 | 이 약을 먹은 후부터 몸이 계속 가려워요. | Seit ich dieses Medikament nehme, juckt es mich am ganzen Körper. | Ever since I took this medicine, my body has been itching. | `가려워요` | 쉬워요, 귀여워요, 가까워요 |
| 46 | 어지럽다 | `b1_health_hospital_2` 2 | 잠을 못 자서 머리가 좀 어지러워요. | Ich habe nicht geschlafen, deshalb ist mir etwas schwindlig. | I didn't sleep, so I feel a bit dizzy. | `어지러워요` | 가까워요, 부드러워요, 시끄러워요 |
| 47 | 붓다 | `b1_health_hospital_2` 3 | 어제 라면을 먹고 자서 얼굴이 많이 부었어요. | Ich habe gestern vor dem Schlafen Ramyeon gegessen, jetzt ist mein Gesicht ganz geschwollen. | I ate ramyeon right before bed last night, so my face is really puffy. | `부었어요` | 웃었어요, 씻었어요, 걸었어요 |
| 48 | 코피 | `b1_health_hospital_2` 4 | 너무 피곤해서 아침에 코피가 났어요. | Ich war so müde, dass ich heute Morgen Nasenbluten hatte. | I was so tired that I got a nosebleed this morning. | `코피가` | 주스가, 커피가, 카메라가 |
| 49 | 멀미 | `b1_health_hospital_2` 5 | 버스를 오래 타면 멀미가 나요. | Wenn ich lange Bus fahre, wird mir schlecht. | I get carsick on long bus rides. | `멀미가` | 허리가, 모자가, 바지가 |
| 50 | 체하다 | `b1_health_hospital_2` 6 | 점심을 너무 빨리 먹어서 체한 것 같아요. | Ich habe mittags zu schnell gegessen und habe wohl eine Magenverstimmung. | I ate lunch too fast, and I think I have indigestion. | `체한` | 운동한, 청소한, 공부한 |
| 51 | 소화 | `b1_health_hospital_2` 7 | 저녁을 많이 먹어서 소화가 잘 안 돼요. | Ich habe abends zu viel gegessen, jetzt liegt es mir schwer im Magen. | I ate a lot for dinner, and it's not digesting well. | `소화가` | 시계가, 치마가, 라디오가 |
| 52 | 발목 | `b1_health_hospital_2` 8 | 어제 계단에서 넘어져서 발목을 다쳤어요. | Ich bin gestern die Treppe hinuntergefallen und habe mir den Knöchel verletzt. | I fell on the stairs yesterday and hurt my ankle. | `발목을` | 가방을, 책상을, 창문을 |
| 53 | 몸살 | `b1_health_hospital_2` 9 | 요즘 일이 많아서 몸살이 났어요. | Ich hatte zurzeit so viel Arbeit, dass ich jetzt Gliederschmerzen habe. | I've had so much work lately that I've got body aches. | `몸살이` | 시험이, 약속이, 수업이 |
| 54 | 독감 | `b1_health_hospital_2` 10 | 독감 예방 주사를 맞으러 병원에 갔어요. | Ich bin zum Arzt gegangen, um mich gegen Grippe impfen zu lassen. | I went to the clinic to get a flu shot. | `독감` | 치과, 두통, 수술 |
| 55 | 진찰 | `b1_health_hospital_2` 11 | 열이 계속 나서 병원에서 진찰을 받았어요. | Ich hatte immer noch Fieber, deshalb habe ich mich im Krankenhaus untersuchen lassen. | My fever wouldn't go away, so I got examined at the hospital. | `진찰을` | 월급을, 선물을, 장학금을 |
| 56 | 응급실 | `b1_health_hospital_2` 12 | 밤에 배가 너무 아파서 응급실에 갔어요. | Nachts hatte ich so starke Bauchschmerzen, dass ich in die Notaufnahme gegangen bin. | My stomach hurt so badly at night that I went to the emergency room. | `응급실에` | 도서관에, 영화관에, 미용실에 |
| 57 | 낡다 | `b1_descriptions_adj_2` 1 | 신발이 너무 낡아서 새로 하나 샀어요. | Meine Schuhe waren völlig abgelaufen, deshalb habe ich mir neue gekauft. | My shoes were really worn out, so I bought a new pair. | `낡아서` | 좋아서, 괜찮아서, 많아서 |
| 58 | 깔끔하다 | `b1_descriptions_adj_2` 2 | 새로 이사한 방은 작지만 깔끔해서 마음에 들어요. | Mein neues Zimmer ist klein, aber ordentlich, das gefällt mir. | My new room is small but neat, and I like it. | `깔끔해서` | 복잡해서, 불편해서, 답답해서 |
| 59 | 지저분하다 | `b1_descriptions_adj_2` 3 | 동생 방이 너무 지저분해서 같이 청소했어요. | Das Zimmer meines jüngeren Bruders war total unordentlich, deshalb haben wir zusammen aufgeräumt. | My younger brother's room was so messy that we cleaned it together. | `지저분해서` | 따뜻해서, 편해서, 심심해서 |
| 60 | 싱싱하다 | `b1_descriptions_adj_2` 4 | 시장에서 산 생선이 정말 싱싱해요. | Der Fisch vom Markt ist wirklich frisch. | The fish I bought at the market is really fresh. | `싱싱해요` | 똑똑해요, 친절해요, 불편해요 |
| 61 | 낯설다 | `b1_descriptions_adj_2` 5 | 한국에 처음 왔을 때 모든 것이 낯설었어요. | Als ich zum ersten Mal nach Korea kam, war mir alles fremd. | When I first came to Korea, everything felt unfamiliar. | `낯설었어요` | 길었어요, 멀었어요, 달았어요 |
| 62 | 신기하다 | `b1_descriptions_adj_2` 6 | 한국에서는 밤늦게도 음식을 배달해 줘서 정말 신기했어요. | Ich fand es echt erstaunlich, dass man sich in Korea auch spätabends Essen liefern lassen kann. | I was really amazed that in Korea you can get food delivered even late at night. | `신기했어요` | 심심했어요, 피곤했어요, 시원했어요 |
| 63 | 멋지다 | `b1_descriptions_adj_2` 7 | 마야 씨, 오늘 입은 재킷 정말 멋지네요! | Maya, deine Jacke heute sieht echt toll aus! | Maya, the jacket you're wearing today looks really great! | `멋지네요` | 시끄럽네요, 짜네요, 맵네요 |
| 64 | 대단하다 | `b1_descriptions_adj_2` 8 | 다니엘 씨, 매일 아침 10킬로미터씩 뛰어요? 정말 대단해요! | Daniel, du läufst jeden Morgen zehn Kilometer? Echt beeindruckend! | Daniel, you run ten kilometers every morning? That's really impressive! | `대단해요` | 심심해요, 답답해요, 불편해요 |

_Draft only; Jin sample approval pending (level-canon D-4). Examples, translations and distractors authored by Claude 2026-11-26; MODEL_QA only, no human-language QA claim._
