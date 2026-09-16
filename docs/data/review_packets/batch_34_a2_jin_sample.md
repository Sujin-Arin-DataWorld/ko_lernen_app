# C3 Batch 34 A2 Jin review packet

상태: `MODEL_QA_PASS`, `HUMAN_APPROVED` 아님. 모든 review ledger는 `pending`이다.

## 범위와 산술

- Raw NIKL 2급 non-affix exact headword-string set: **1085**.
- Raw gap after subtracting live + draft headword strings through Batch 33: **599**.
- Batch 34 raw unique claim: **64**; raw gap after live + drafts through Batch 34: **535**.
- Canonical normalized live F2 coverage: total **1070**, present **412**, missing **658**. No normalized draft-overlay count is claimed.
- Artifacts: vocab 64 + cloze 64 + satz 64 = **192** draft records.

## Pack table

| pack | before | added | after | boss total |
|---|---:|---:|---:|---:|
| a2_events_1 | 8 | 4 | 12 | 3 |
| a2_messenger_phone_1 | 6 | 6 | 12 | 3 |
| a2_problems_help_1 | 0 | 12 | 12 | 3 |
| a2_dishes_1 | 0 | 12 | 12 | 3 |
| a2_home_routines_1 | 0 | 12 | 12 | 3 |
| a2_time_span_1 | 0 | 12 | 12 | 3 |
| a2_weather_sky_1 | 0 | 6 | 6 | 2 |

## Persona attribution

11 rows use a leading vocative or a canon-exclusive cue; no persona appears more than twice. The manifest carries the exact ID mapping and banmal relationship basis.

## Jin 표본 7행

### vocab_a2_0702 — 잔치

- KO: 다음 주에 잔치를 열어요.
- DE: Nächste Woche findet ein Fest statt.
- EN: A celebration will take place next week.
- Cloze `cloze_a2_0509`: 다음 주에 ＿＿＿ 열어요. → `잔치를` · ['양말을', '연필을', '감기를']
- Satz `satz_a2_0694`: 다음 주에 잔치를 열어요. · ['양말을', '연필을']

### vocab_a2_0701 — 물어보다

- KO: 길을 모르면 지나가는 사람에게 물어보세요.
- DE: Wenn Sie den Weg nicht kennen, fragen Sie jemanden, der vorbeikommt.
- EN: If you do not know the way, ask someone passing by.
- Cloze `cloze_a2_0508`: 길을 모르면 지나가는 사람에게 ＿＿＿. → `물어보세요` · ['앉으세요', '서세요', '웃으세요']
- Satz `satz_a2_0693`: 길을 모르면 지나가는 사람에게 물어보세요. · ['앉으세요', '서세요']

### vocab_a2_0714 — 안전

- KO: 안전 운전을 꼭 하세요.
- DE: Fahren Sie bitte unbedingt vorsichtig.
- EN: Please be sure to drive safely.
- Cloze `cloze_a2_0521`: ＿＿＿ 운전을 꼭 하세요. → `안전` · ['도서관', '만두', '연필']
- Satz `satz_a2_0706`: 안전 운전을 꼭 하세요. · ['도서관', '만두']

### vocab_a2_0723 — 자장면

- KO: 이사하는 날에는 자장면을 시켜요.
- DE: Am Umzugstag bestelle ich Jajangmyeon.
- EN: On moving day, I order jajangmyeon.
- Cloze `cloze_a2_0530`: 이사하는 날에는 ＿＿＿ 시켜요. → `자장면을` · ['구름을', '하늘을', '햇빛을']
- Satz `satz_a2_0715`: 이사하는 날에는 자장면을 시켜요. · ['구름을', '하늘을']

### vocab_a2_0732 — 빨다

- KO: 더러운 양말을 손으로 빨았어요.
- DE: Ich habe die schmutzigen Socken mit der Hand gewaschen.
- EN: I washed the dirty socks by hand.
- Cloze `cloze_a2_0539`: 더러운 양말을 손으로 ＿＿＿. → `빨았어요` · ['앉았어요', '누웠어요', '뛰었어요']
- Satz `satz_a2_0724`: 더러운 양말을 손으로 빨았어요. · ['앉았어요', '누웠어요']

### vocab_a2_0741 — 냄비

- KO: 냄비에 물을 넣고 끓이세요.
- DE: Geben Sie Wasser in den Topf und bringen Sie es zum Kochen.
- EN: Put water in the pot and boil it.
- Cloze `cloze_a2_0548`: ＿＿＿ 물을 넣고 끓이세요. → `냄비에` · ['고장에', '연결에', '서비스에']
- Satz `satz_a2_0733`: 냄비에 물을 넣고 끓이세요. · ['고장에', '연결에']

### vocab_a2_0750 — 최근

- KO: 최근에 회사 근처로 이사했어요.
- DE: Vor Kurzem bin ich in die Nähe der Firma gezogen.
- EN: I recently moved near the office.
- Cloze `cloze_a2_0557`: ＿＿＿ 회사 근처로 이사했어요. → `최근에` · ['지갑에', '신발에', '편지에']
- Satz `satz_a2_0742`: 최근에 회사 근처로 이사했어요. · ['지갑에', '신발에']

## 전체 64행 삼언어 감사

각 행은 같은 사건, 극성, 시점, 행위자/대상, 화행을 유지한다. DE와 EN은 KO 정본의 독립 현지화다.

| # | id | word | KO | DE | EN |
|---:|---|---|---|---|---|
| 1 | vocab_a2_0702 | 잔치 | 다음 주에 잔치를 열어요. | Nächste Woche findet ein Fest statt. | A celebration will take place next week. |
| 2 | vocab_a2_0703 | 결혼 | 대박, 두 사람이 다음 달에 결혼을 해요! | Wahnsinn, die beiden heiraten nächsten Monat! | Wow, the two of them are getting married next month! |
| 3 | vocab_a2_0704 | 환영 | 레나 씨, 우리 팀에 온 것을 환영해요. | Lena, willkommen in unserem Team. | Lena, welcome to our team. |
| 4 | vocab_a2_0705 | 연말 | 마야 씨, 연말에는 회사 일이 많아요? | Maya, gibt es zum Jahresende viel Arbeit in der Firma? | Maya, is there a lot of work at the company toward the end of the year? |
| 5 | vocab_a2_0696 | 메일 | 안드레아 씨, 사진을 메일로 친구에게 보냈어요. | Andrea, ich habe das Foto per E-Mail an einen Freund geschickt. | Andrea, I sent the photo to a friend by email. |
| 6 | vocab_a2_0697 | 연결 | 지하철에서는 인터넷 연결이 잘 안 돼요. | In der U-Bahn funktioniert die Internetverbindung nicht gut. | The internet connection does not work well on the subway. |
| 7 | vocab_a2_0698 | 전화기 | 전화기를 집에 두고 나왔어요. | Ich habe das Telefon zu Hause liegen lassen. | I left the telephone at home. |
| 8 | vocab_a2_0699 | 들리다 | 크리스티안, 내 목소리 잘 들려? | Christian, kannst du mich gut hören? | Christian, can you hear me clearly? |
| 9 | vocab_a2_0700 | 소식 | 친구한테서 결혼 소식을 듣고 정말 기뻤어요. | Jemand aus meinem Freundeskreis erzählte mir von der Hochzeit, und ich habe mich sehr gefreut. | I heard the news about the wedding from a friend and was very happy. |
| 10 | vocab_a2_0701 | 물어보다 | 길을 모르면 지나가는 사람에게 물어보세요. | Wenn Sie den Weg nicht kennen, fragen Sie jemanden, der vorbeikommt. | If you do not know the way, ask someone passing by. |
| 11 | vocab_a2_0706 | 도움 | 다니엘 씨, 어제 설명이 정말 도움이 됐어요. | Daniel, Ihre Erklärung gestern war wirklich hilfreich. | Daniel, your explanation yesterday was really helpful. |
| 12 | vocab_a2_0707 | 고장 | 크리스티안, 컴퓨터가 또 고장이 났어? | Christian, ist dein Computer schon wieder kaputt? | Christian, did your computer break down again? |
| 13 | vocab_a2_0708 | 잃다 | 어제 지하철에서 지갑을 잃었어요. | Gestern habe ich in der U-Bahn meine Brieftasche verloren. | Yesterday I lost my wallet on the subway. |
| 14 | vocab_a2_0709 | 막히다 | 길이 많이 막혀서 회의에 늦었어요. | Die Straße war stark verstopft, deshalb kam ich zu spät zur Besprechung. | The road was very congested, so I was late for the meeting. |
| 15 | vocab_a2_0710 | 전기 | 갑자기 전기가 나가서 방이 어두웠어요. | Plötzlich fiel der Strom aus und das Zimmer war dunkel. | The power suddenly went out, and the room was dark. |
| 16 | vocab_a2_0711 | 유리 | 창문 유리를 깨끗이 닦았어요. | Ich habe das Fensterglas sauber gewischt. | I wiped the window glass clean. |
| 17 | vocab_a2_0712 | 센터 | 서비스 센터에 전화해서 물어봤어요. | Ich habe beim Servicecenter angerufen und nachgefragt. | I called the service center and asked. |
| 18 | vocab_a2_0713 | 서비스 | 이 호텔에서 친절한 서비스를 받았어요. | In diesem Hotel habe ich freundlichen Service bekommen. | I received friendly service at this hotel. |
| 19 | vocab_a2_0714 | 안전 | 안전 운전을 꼭 하세요. | Fahren Sie bitte unbedingt vorsichtig. | Please be sure to drive safely. |
| 20 | vocab_a2_0715 | 급하다 | 급한 일이 있어서 먼저 가요. | Ich habe etwas Dringendes zu erledigen und gehe deshalb zuerst. | I have something urgent to do, so I am leaving first. |
| 21 | vocab_a2_0716 | 알아보다 | 인터넷으로 기차 시간을 알아봤어요. | Ich habe die Zugzeiten im Internet nachgesehen. | I checked the train times online. |
| 22 | vocab_a2_0717 | 잘못하다 | 제가 계산을 잘못해서 죄송해요. | Es tut mir leid, dass ich mich verrechnet habe. | I am sorry I calculated it incorrectly. |
| 23 | vocab_a2_0718 | 만두 | 명절에 가족과 함께 만두를 먹었어요. | Am Feiertag habe ich mit meiner Familie Mandu gegessen. | I ate mandu with my family for the holiday. |
| 24 | vocab_a2_0719 | 떡 | 엄마, 나 3학년 친구들하고 떡을 먹었어! | Mama, ich habe mit meinen Freunden aus der dritten Klasse Reiskuchen gegessen! | Mom, I ate rice cakes with my third-grade friends! |
| 25 | vocab_a2_0720 | 김 | 한국 김은 짜지 않고 맛있어요. | Koreanischer Seetang ist nicht salzig und schmeckt gut. | Korean dried seaweed is not salty and tastes good. |
| 26 | vocab_a2_0721 | 찌개 | 추운 날에는 뜨거운 찌개가 최고예요. | An kalten Tagen ist ein heißer Eintopf das Beste. | On cold days, hot stew is the best. |
| 27 | vocab_a2_0722 | 튀김 | 시장에서 튀김을 사서 먹었어요. | Auf dem Markt habe ich Frittiertes gekauft und gegessen. | I bought and ate fried food at the market. |
| 28 | vocab_a2_0723 | 자장면 | 이사하는 날에는 자장면을 시켜요. | Am Umzugstag bestelle ich Jajangmyeon. | On moving day, I order jajangmyeon. |
| 29 | vocab_a2_0724 | 짬뽕 | 매운 짬뽕을 먹고 땀이 많이 났어요. | Nach der scharfen Jjamppong-Suppe habe ich stark geschwitzt. | I sweated a lot after eating spicy jjamppong. |
| 30 | vocab_a2_0725 | 탕수육 | 중국집에서 탕수육을 하나 더 주문했어요. | Im chinesischen Restaurant habe ich noch eine Portion Tangsuyuk bestellt. | I ordered one more serving of tangsuyuk at the Chinese restaurant. |
| 31 | vocab_a2_0726 | 칼국수 | 비 오는 날에는 따뜻한 칼국수가 먹고 싶어요. | An Regentagen möchte ich warme Kalguksu essen. | On rainy days, I want to eat warm kalguksu. |
| 32 | vocab_a2_0727 | 돈가스 | 학교 식당 돈가스는 값이 싸고 맛있어요. | Das Donkatsu in der Schulkantine ist günstig und lecker. | The donkatsu in the school cafeteria is inexpensive and tasty. |
| 33 | vocab_a2_0728 | 카레 | 저녁에 감자를 넣은 카레를 만들었어요. | Zum Abendessen habe ich Curry mit Kartoffeln gemacht. | I made curry with potatoes for dinner. |
| 34 | vocab_a2_0729 | 미역국 | 한국에서는 생일에 미역국을 먹어요. | In Korea isst man am Geburtstag Miyeokguk. | In Korea, people eat seaweed soup on birthdays. |
| 35 | vocab_a2_0730 | 집안일 | 민호 씨, 주말에는 누가 집안일을 해요? | Minho, wer macht am Wochenende die Hausarbeit? | Minho, who does the housework on weekends? |
| 36 | vocab_a2_0731 | 세탁 | 이 코트는 집에서 세탁을 하면 안 돼요. | Diesen Mantel darf man nicht zu Hause waschen. | You must not wash this coat at home. |
| 37 | vocab_a2_0732 | 빨다 | 더러운 양말을 손으로 빨았어요. | Ich habe die schmutzigen Socken mit der Hand gewaschen. | I washed the dirty socks by hand. |
| 38 | vocab_a2_0733 | 쓰레기통 | 다 마신 컵은 쓰레기통에 버리세요. | Werfen Sie den leeren Becher in den Mülleimer. | Throw the empty cup in the trash can. |
| 39 | vocab_a2_0734 | 휴지 | 화장실에 휴지가 없어서 불편했어요. | Es gab kein Toilettenpapier, deshalb war es unangenehm. | There was no toilet paper in the restroom, so it was inconvenient. |
| 40 | vocab_a2_0735 | 목욕 | 자기 전에 따뜻한 물로 목욕을 해요. | Vor dem Schlafengehen bade ich in warmem Wasser. | I take a warm bath before going to bed. |
| 41 | vocab_a2_0736 | 양치질 | 식사 후에는 꼭 양치질을 하세요. | Putzen Sie sich nach dem Essen unbedingt die Zähne. | Make sure to brush your teeth after meals. |
| 42 | vocab_a2_0737 | 치약 | 치약이 다 떨어져서 마트에서 샀어요. | Die Zahnpasta war aufgebraucht, deshalb habe ich neue im Supermarkt gekauft. | I ran out of toothpaste, so I bought some at the supermarket. |
| 43 | vocab_a2_0738 | 선풍기 | 더워서 선풍기를 켜고 잤어요. | Weil es heiß war, habe ich den Ventilator eingeschaltet und geschlafen. | It was hot, so I turned on the fan and went to sleep. |
| 44 | vocab_a2_0739 | 식탁 | 저녁 준비가 끝나서 식탁에 그릇을 놓았어요. | Als das Abendessen fertig war, stellte ich das Geschirr auf den Esstisch. | When dinner was ready, I put the dishes on the dining table. |
| 45 | vocab_a2_0740 | 바닥 | 청소기로 바닥을 깨끗하게 청소했어요. | Ich habe den Boden mit dem Staubsauger gründlich gereinigt. | I cleaned the floor thoroughly with a vacuum cleaner. |
| 46 | vocab_a2_0741 | 냄비 | 냄비에 물을 넣고 끓이세요. | Geben Sie Wasser in den Topf und bringen Sie es zum Kochen. | Put water in the pot and boil it. |
| 47 | vocab_a2_0742 | 이틀 | 현아 씨, 이틀 동안 어디에 있었어요? | Hyuna, wo waren Sie zwei Tage lang? | Hyuna, where were you for two days? |
| 48 | vocab_a2_0743 | 사흘 | 감기로 사흘 동안 학교에 못 갔어요. | Wegen einer Erkältung konnte ich drei Tage lang nicht zur Schule gehen. | I could not go to school for three days because of a cold. |
| 49 | vocab_a2_0744 | 나흘 | 비가 나흘 동안 계속 왔어요. | Es hat vier Tage lang ununterbrochen geregnet. | It rained continuously for four days. |
| 50 | vocab_a2_0745 | 열흘 | 열흘 후에 독일에서 부모님이 오세요. | In zehn Tagen kommen meine Eltern aus Deutschland. | My parents are coming from Germany in ten days. |
| 51 | vocab_a2_0746 | 개월 | 저는 삼 개월 전에 한국에 왔어요. | Ich bin vor drei Monaten nach Korea gekommen. | I came to Korea three months ago. |
| 52 | vocab_a2_0747 | 그동안 | 그동안 연락을 못 해서 미안해요. | Es tut mir leid, dass ich mich in der Zwischenzeit nicht gemeldet habe. | I am sorry I could not get in touch during that time. |
| 53 | vocab_a2_0748 | 오랜만 | 오랜만에 고향 친구를 만나서 반가웠어요. | Ich habe nach langer Zeit jemanden aus meiner Heimat wiedergetroffen und mich sehr gefreut. | I was glad to meet a friend from my hometown after a long time. |
| 54 | vocab_a2_0749 | 마지막 | 이번 학기 수업은 오늘이 마지막이에요. | Heute ist der letzte Unterrichtstag dieses Semesters. | Today is the last day of class this semester. |
| 55 | vocab_a2_0750 | 최근 | 최근에 회사 근처로 이사했어요. | Vor Kurzem bin ich in die Nähe der Firma gezogen. | I recently moved near the office. |
| 56 | vocab_a2_0751 | 다음날 | 늦게 자서 다음날 아침에 못 일어났어요. | Ich ging spät schlafen und konnte am nächsten Morgen nicht aufstehen. | I went to bed late and could not get up the next morning. |
| 57 | vocab_a2_0752 | 어젯밤 | 어젯밤에 이상한 꿈을 꿨어요. | Letzte Nacht hatte ich einen seltsamen Traum. | I had a strange dream last night. |
| 58 | vocab_a2_0753 | 점심시간 | 수진 씨, 점심시간에 같이 밥 먹어요? | Sujin, essen wir in der Mittagspause zusammen? | Sujin, shall we eat together during lunch break? |
| 59 | vocab_a2_0754 | 구름 | 구름이 많아서 하늘이 어두워요. | Es gibt viele Wolken, deshalb ist der Himmel dunkel. | There are many clouds, so the sky is dark. |
| 60 | vocab_a2_0755 | 하늘 | 비가 그치고 하늘이 정말 맑아요. | Der Regen hat aufgehört und der Himmel ist richtig klar. | The rain stopped and the sky is really clear. |
| 61 | vocab_a2_0756 | 햇빛 | 햇빛이 너무 강해서 모자를 썼어요. | Das Sonnenlicht war so stark, dass ich einen Hut aufgesetzt habe. | The sunlight was so strong that I put on a hat. |
| 62 | vocab_a2_0757 | 기온 | 내일은 기온이 5도까지 내려가요. | Morgen sinkt die Temperatur auf fünf Grad. | The temperature will drop to five degrees tomorrow. |
| 63 | vocab_a2_0758 | 영하 | 오늘 아침에는 영하 5도까지 내려갔어요. | Heute Morgen sank die Temperatur auf minus fünf Grad. | This morning, the temperature fell to five degrees below zero. |
| 64 | vocab_a2_0759 | 얼음 | 물에 얼음을 넣어서 마셨어요. | Ich habe Eis ins Wasser gegeben und es getrunken. | I put ice in the water and drank it. |

## 배분어 전체 문장(192)

아래는 64×3 치환을 모두 완전한 문장으로 읽은 MODEL_QA 판정이다. 단순 문법 오류가 아니라 가능한 동음이의·연어·은유·환유 읽기까지 확인했다.

| cloze | word | substituted sentence | manual judgment |
|---|---|---|---|
| `cloze_a2_0509` | 잔치 | 다음 주에 양말을 열어요. | ✗ Only an event can be held with 열다; the object and illness substitutes cannot. |
| `cloze_a2_0509` | 잔치 | 다음 주에 연필을 열어요. | ✗ Only an event can be held with 열다; the object and illness substitutes cannot. |
| `cloze_a2_0509` | 잔치 | 다음 주에 감기를 열어요. | ✗ Only an event can be held with 열다; the object and illness substitutes cannot. |
| `cloze_a2_0510` | 결혼 | 대박, 두 사람이 다음 달에 기온을 해요! | ✗ In this two-person life-event frame, only 결혼 forms the intended N을 하다 event; temperature, toothpaste, and socks do not. |
| `cloze_a2_0510` | 결혼 | 대박, 두 사람이 다음 달에 치약을 해요! | ✗ In this two-person life-event frame, only 결혼 forms the intended N을 하다 event; temperature, toothpaste, and socks do not. |
| `cloze_a2_0510` | 결혼 | 대박, 두 사람이 다음 달에 양말을 해요! | ✗ In this two-person life-event frame, only 결혼 forms the intended N을 하다 event; temperature, toothpaste, and socks do not. |
| `cloze_a2_0511` | 환영 | 레나 씨, 우리 팀에 온 것을 피곤해요. | ✗ The object clause 온 것을 requires a transitive predicate; the adjectives cannot govern it. |
| `cloze_a2_0511` | 환영 | 레나 씨, 우리 팀에 온 것을 친절해요. | ✗ The object clause 온 것을 requires a transitive predicate; the adjectives cannot govern it. |
| `cloze_a2_0511` | 환영 | 레나 씨, 우리 팀에 온 것을 건강해요. | ✗ The object clause 온 것을 requires a transitive predicate; the adjectives cannot govern it. |
| `cloze_a2_0512` | 연말 | 마야 씨, 숟가락에는 회사 일이 많아요? | ✗ The marked phrase is a time frame; the object substitutes cannot locate the workload in time. |
| `cloze_a2_0512` | 연말 | 마야 씨, 접시에는 회사 일이 많아요? | ✗ The marked phrase is a time frame; the object substitutes cannot locate the workload in time. |
| `cloze_a2_0512` | 연말 | 마야 씨, 지갑에는 회사 일이 많아요? | ✗ The marked phrase is a time frame; the object substitutes cannot locate the workload in time. |
| `cloze_a2_0503` | 메일 | 안드레아 씨, 사진을 잔치로 친구에게 보냈어요. | ✗ The marked means slot requires a communication channel; the substitutes cannot transmit the photo to the friend. |
| `cloze_a2_0503` | 메일 | 안드레아 씨, 사진을 독서로 친구에게 보냈어요. | ✗ The marked means slot requires a communication channel; the substitutes cannot transmit the photo to the friend. |
| `cloze_a2_0503` | 메일 | 안드레아 씨, 사진을 구름으로 친구에게 보냈어요. | ✗ The marked means slot requires a communication channel; the substitutes cannot transmit the photo to the friend. |
| `cloze_a2_0504` | 연결 | 지하철에서는 인터넷 바닥이 잘 안 돼요. | ✗ Only a connectivity noun can complete the internet compound and fail in this context. |
| `cloze_a2_0504` | 연결 | 지하철에서는 인터넷 목욕이 잘 안 돼요. | ✗ Only a connectivity noun can complete the internet compound and fail in this context. |
| `cloze_a2_0504` | 연결 | 지하철에서는 인터넷 잔치가 잘 안 돼요. | ✗ Only a connectivity noun can complete the internet compound and fail in this context. |
| `cloze_a2_0505` | 전화기 | 소식을 집에 두고 나왔어요. | ✗ The substitutes are abstract events or states and cannot be portable objects left at home. |
| `cloze_a2_0505` | 전화기 | 도움을 집에 두고 나왔어요. | ✗ The substitutes are abstract events or states and cannot be portable objects left at home. |
| `cloze_a2_0505` | 전화기 | 환영을 집에 두고 나왔어요. | ✗ The substitutes are abstract events or states and cannot be portable objects left at home. |
| `cloze_a2_0506` | 들리다 | 크리스티안, 내 목소리 잘 앉아? | ✗ With 목소리 as subject, the substituted human actions have no coherent reading. |
| `cloze_a2_0506` | 들리다 | 크리스티안, 내 목소리 잘 울어? | ✗ With 목소리 as subject, the substituted human actions have no coherent reading. |
| `cloze_a2_0506` | 들리다 | 크리스티안, 내 목소리 잘 웃어? | ✗ With 목소리 as subject, the substituted human actions have no coherent reading. |
| `cloze_a2_0507` | 소식 | 친구한테서 결혼 연필을 듣고 정말 기뻤어요. | ✗ The concrete substitutes cannot be heard as information in the 결혼 N을 듣다 frame. |
| `cloze_a2_0507` | 소식 | 친구한테서 결혼 얼음을 듣고 정말 기뻤어요. | ✗ The concrete substitutes cannot be heard as information in the 결혼 N을 듣다 frame. |
| `cloze_a2_0507` | 소식 | 친구한테서 결혼 구름을 듣고 정말 기뻤어요. | ✗ The concrete substitutes cannot be heard as information in the 결혼 N을 듣다 frame. |
| `cloze_a2_0508` | 물어보다 | 길을 모르면 지나가는 사람에게 앉으세요. | ✗ The 에게 complement selects an asking verb; the intransitive imperatives cannot take it. |
| `cloze_a2_0508` | 물어보다 | 길을 모르면 지나가는 사람에게 서세요. | ✗ The 에게 complement selects an asking verb; the intransitive imperatives cannot take it. |
| `cloze_a2_0508` | 물어보다 | 길을 모르면 지나가는 사람에게 웃으세요. | ✗ The 에게 complement selects an asking verb; the intransitive imperatives cannot take it. |
| `cloze_a2_0513` | 도움 | 다니엘 씨, 어제 설명이 정말 센터가 됐어요. | ✗ The explanation can become help, but it cannot become a center, dumpling, or sky. |
| `cloze_a2_0513` | 도움 | 다니엘 씨, 어제 설명이 정말 만두가 됐어요. | ✗ The explanation can become help, but it cannot become a center, dumpling, or sky. |
| `cloze_a2_0513` | 도움 | 다니엘 씨, 어제 설명이 정말 하늘이 됐어요. | ✗ The explanation can become help, but it cannot become a center, dumpling, or sky. |
| `cloze_a2_0514` | 고장 | 크리스티안, 컴퓨터가 또 식탁이 났어? | ✗ Only 고장 forms the malfunction collocation with 나다; the objects do not. |
| `cloze_a2_0514` | 고장 | 크리스티안, 컴퓨터가 또 유리가 났어? | ✗ Only 고장 forms the malfunction collocation with 나다; the objects do not. |
| `cloze_a2_0514` | 고장 | 크리스티안, 컴퓨터가 또 우표가 났어? | ✗ Only 고장 forms the malfunction collocation with 나다; the objects do not. |
| `cloze_a2_0515` | 잃다 | 어제 지하철에서 지갑을 앉았어요. | ✗ The fixed object 지갑을 makes each intransitive substitute structurally invalid. |
| `cloze_a2_0515` | 잃다 | 어제 지하철에서 지갑을 울었어요. | ✗ The fixed object 지갑을 makes each intransitive substitute structurally invalid. |
| `cloze_a2_0515` | 잃다 | 어제 지하철에서 지갑을 잤어요. | ✗ The fixed object 지갑을 makes each intransitive substitute structurally invalid. |
| `cloze_a2_0516` | 막히다 | 길이 많이 앉아서 회의에 늦었어요. | ✗ A road cannot sit, cry, or laugh; no alternate literal or idiomatic reading fits. |
| `cloze_a2_0516` | 막히다 | 길이 많이 울어서 회의에 늦었어요. | ✗ A road cannot sit, cry, or laugh; no alternate literal or idiomatic reading fits. |
| `cloze_a2_0516` | 막히다 | 길이 많이 웃어서 회의에 늦었어요. | ✗ A road cannot sit, cry, or laugh; no alternate literal or idiomatic reading fits. |
| `cloze_a2_0517` | 전기 | 갑자기 목욕이 나가서 방이 어두웠어요. | ✗ Only electricity has the outage reading of 나가다 that explains why the room was dark. |
| `cloze_a2_0517` | 전기 | 갑자기 양치질이 나가서 방이 어두웠어요. | ✗ Only electricity has the outage reading of 나가다 that explains why the room was dark. |
| `cloze_a2_0517` | 전기 | 갑자기 세탁이 나가서 방이 어두웠어요. | ✗ Only electricity has the outage reading of 나가다 that explains why the room was dark. |
| `cloze_a2_0518` | 유리 | 창문 소식을 깨끗이 닦았어요. | ✗ The abstract substitutes cannot be the physical surface of a window that is wiped. |
| `cloze_a2_0518` | 유리 | 창문 도움을 깨끗이 닦았어요. | ✗ The abstract substitutes cannot be the physical surface of a window that is wiped. |
| `cloze_a2_0518` | 유리 | 창문 결혼을 깨끗이 닦았어요. | ✗ The abstract substitutes cannot be the physical surface of a window that is wiped. |
| `cloze_a2_0519` | 센터 | 서비스 만두에 전화해서 물어봤어요. | ✗ Only an institution can be called; the food nouns cannot be telephone recipients or places here. |
| `cloze_a2_0519` | 센터 | 서비스 떡에 전화해서 물어봤어요. | ✗ Only an institution can be called; the food nouns cannot be telephone recipients or places here. |
| `cloze_a2_0519` | 센터 | 서비스 찌개에 전화해서 물어봤어요. | ✗ Only an institution can be called; the food nouns cannot be telephone recipients or places here. |
| `cloze_a2_0520` | 서비스 | 이 호텔에서 친절한 기온을 받았어요. | ✗ After 친절한, the received object must denote courteous assistance; temperature, ice, and a floor cannot carry that reading. |
| `cloze_a2_0520` | 서비스 | 이 호텔에서 친절한 얼음을 받았어요. | ✗ After 친절한, the received object must denote courteous assistance; temperature, ice, and a floor cannot carry that reading. |
| `cloze_a2_0520` | 서비스 | 이 호텔에서 친절한 바닥을 받았어요. | ✗ After 친절한, the received object must denote courteous assistance; temperature, ice, and a floor cannot carry that reading. |
| `cloze_a2_0521` | 안전 | 도서관 운전을 꼭 하세요. | ✗ Only 안전 forms the established compound 안전 운전; the place, food, and object substitutes do not. |
| `cloze_a2_0521` | 안전 | 만두 운전을 꼭 하세요. | ✗ Only 안전 forms the established compound 안전 운전; the place, food, and object substitutes do not. |
| `cloze_a2_0521` | 안전 | 연필 운전을 꼭 하세요. | ✗ Only 안전 forms the established compound 안전 운전; the place, food, and object substitutes do not. |
| `cloze_a2_0522` | 급하다 | 차가운 일이 있어서 먼저 가요. | ✗ The taste, temperature, and thickness adjectives cannot naturally describe 일이 in this event reading. |
| `cloze_a2_0522` | 급하다 | 맛있는 일이 있어서 먼저 가요. | ✗ The taste, temperature, and thickness adjectives cannot naturally describe 일이 in this event reading. |
| `cloze_a2_0522` | 급하다 | 두꺼운 일이 있어서 먼저 가요. | ✗ The taste, temperature, and thickness adjectives cannot naturally describe 일이 in this event reading. |
| `cloze_a2_0523` | 알아보다 | 인터넷으로 기차 시간을 누웠어요. | ✗ The object 기차 시간을 cannot be governed by the intransitive substitutes. |
| `cloze_a2_0523` | 알아보다 | 인터넷으로 기차 시간을 뛰었어요. | ✗ The object 기차 시간을 cannot be governed by the intransitive substitutes. |
| `cloze_a2_0523` | 알아보다 | 인터넷으로 기차 시간을 웃었어요. | ✗ The object 기차 시간을 cannot be governed by the intransitive substitutes. |
| `cloze_a2_0524` | 잘못하다 | 제가 계산을 앉아서 죄송해요. | ✗ The calculation cannot sit, sleep, or run; the substitutes also fail the intended causal predicate. |
| `cloze_a2_0524` | 잘못하다 | 제가 계산을 자서 죄송해요. | ✗ The calculation cannot sit, sleep, or run; the substitutes also fail the intended causal predicate. |
| `cloze_a2_0524` | 잘못하다 | 제가 계산을 뛰어서 죄송해요. | ✗ The calculation cannot sit, sleep, or run; the substitutes also fail the intended causal predicate. |
| `cloze_a2_0525` | 만두 | 명절에 가족과 함께 기온을 먹었어요. | ✗ The measure and abstract substitutes cannot be food eaten with the family in this scene. |
| `cloze_a2_0525` | 만두 | 명절에 가족과 함께 도움을 먹었어요. | ✗ The measure and abstract substitutes cannot be food eaten with the family in this scene. |
| `cloze_a2_0525` | 만두 | 명절에 가족과 함께 서비스를 먹었어요. | ✗ The measure and abstract substitutes cannot be food eaten with the family in this scene. |
| `cloze_a2_0526` | 떡 | 엄마, 나 3학년 친구들하고 결혼을 먹었어! | ✗ The abstract events and value cannot be edible objects of 먹다. |
| `cloze_a2_0526` | 떡 | 엄마, 나 3학년 친구들하고 세탁을 먹었어! | ✗ The abstract events and value cannot be edible objects of 먹다. |
| `cloze_a2_0526` | 떡 | 엄마, 나 3학년 친구들하고 안전을 먹었어! | ✗ The abstract events and value cannot be edible objects of 먹다. |
| `cloze_a2_0527` | 김 | 한국 휴지는 짜지 않고 맛있어요. | ✗ The substitutes are not foods and cannot be evaluated as salty and tasty. |
| `cloze_a2_0527` | 김 | 한국 선풍기는 짜지 않고 맛있어요. | ✗ The substitutes are not foods and cannot be evaluated as salty and tasty. |
| `cloze_a2_0527` | 김 | 한국 유리는 짜지 않고 맛있어요. | ✗ The substitutes are not foods and cannot be evaluated as salty and tasty. |
| `cloze_a2_0528` | 찌개 | 추운 날에는 뜨거운 얼음이 최고예요. | ✗ Ice contradicts 뜨거운 and the other objects are neither hot dishes nor food. |
| `cloze_a2_0528` | 찌개 | 추운 날에는 뜨거운 치약이 최고예요. | ✗ Ice contradicts 뜨거운 and the other objects are neither hot dishes nor food. |
| `cloze_a2_0528` | 찌개 | 추운 날에는 뜨거운 선풍기가 최고예요. | ✗ Ice contradicts 뜨거운 and the other objects are neither hot dishes nor food. |
| `cloze_a2_0529` | 튀김 | 시장에서 소식을 사서 먹었어요. | ✗ The substitutes cannot be bought as food and then eaten in this scene. |
| `cloze_a2_0529` | 튀김 | 시장에서 도움을 사서 먹었어요. | ✗ The substitutes cannot be bought as food and then eaten in this scene. |
| `cloze_a2_0529` | 튀김 | 시장에서 안전을 사서 먹었어요. | ✗ The substitutes cannot be bought as food and then eaten in this scene. |
| `cloze_a2_0530` | 자장면 | 이사하는 날에는 구름을 시켜요. | ✗ The sky nouns cannot be ordered as a delivered meal. |
| `cloze_a2_0530` | 자장면 | 이사하는 날에는 하늘을 시켜요. | ✗ The sky nouns cannot be ordered as a delivered meal. |
| `cloze_a2_0530` | 자장면 | 이사하는 날에는 햇빛을 시켜요. | ✗ The sky nouns cannot be ordered as a delivered meal. |
| `cloze_a2_0531` | 짬뽕 | 매운 휴지를 먹고 땀이 많이 났어요. | ✗ The concrete objects cannot be a spicy dish one eats. |
| `cloze_a2_0531` | 짬뽕 | 매운 선풍기를 먹고 땀이 많이 났어요. | ✗ The concrete objects cannot be a spicy dish one eats. |
| `cloze_a2_0531` | 짬뽕 | 매운 쓰레기통을 먹고 땀이 많이 났어요. | ✗ The concrete objects cannot be a spicy dish one eats. |
| `cloze_a2_0532` | 탕수육 | 중국집에서 바닥을 하나 더 주문했어요. | ✗ The substitutes are not menu items countable as one more order in a restaurant. |
| `cloze_a2_0532` | 탕수육 | 중국집에서 안전을 하나 더 주문했어요. | ✗ The substitutes are not menu items countable as one more order in a restaurant. |
| `cloze_a2_0532` | 탕수육 | 중국집에서 전기를 하나 더 주문했어요. | ✗ The substitutes are not menu items countable as one more order in a restaurant. |
| `cloze_a2_0533` | 칼국수 | 비 오는 날에는 따뜻한 치약이 먹고 싶어요. | ✗ The substitutes are not warm foods that can be wanted with 먹고 싶다. |
| `cloze_a2_0533` | 칼국수 | 비 오는 날에는 따뜻한 햇빛이 먹고 싶어요. | ✗ The substitutes are not warm foods that can be wanted with 먹고 싶다. |
| `cloze_a2_0533` | 칼국수 | 비 오는 날에는 따뜻한 식탁이 먹고 싶어요. | ✗ The substitutes are not warm foods that can be wanted with 먹고 싶다. |
| `cloze_a2_0534` | 돈가스 | 학교 식당 세탁은 값이 싸고 맛있어요. | ✗ The activity nouns are not cafeteria dishes with a price and taste. |
| `cloze_a2_0534` | 돈가스 | 학교 식당 목욕은 값이 싸고 맛있어요. | ✗ The activity nouns are not cafeteria dishes with a price and taste. |
| `cloze_a2_0534` | 돈가스 | 학교 식당 독서는 값이 싸고 맛있어요. | ✗ The activity nouns are not cafeteria dishes with a price and taste. |
| `cloze_a2_0535` | 카레 | 저녁에 감자를 넣은 사흘을 만들었어요. | ✗ The duration and event substitutes cannot be a potato-containing dinner dish one makes. |
| `cloze_a2_0535` | 카레 | 저녁에 감자를 넣은 나흘을 만들었어요. | ✗ The duration and event substitutes cannot be a potato-containing dinner dish one makes. |
| `cloze_a2_0535` | 카레 | 저녁에 감자를 넣은 환영을 만들었어요. | ✗ The duration and event substitutes cannot be a potato-containing dinner dish one makes. |
| `cloze_a2_0536` | 미역국 | 한국에서는 생일에 세탁을 먹어요. | ✗ The household activities cannot be eaten as the birthday dish. |
| `cloze_a2_0536` | 미역국 | 한국에서는 생일에 목욕을 먹어요. | ✗ The household activities cannot be eaten as the birthday dish. |
| `cloze_a2_0536` | 미역국 | 한국에서는 생일에 집안일을 먹어요. | ✗ The household activities cannot be eaten as the birthday dish. |
| `cloze_a2_0537` | 집안일 | 민호 씨, 주말에는 누가 식탁을 해요? | ✗ The substitutes do not form an activity collocation with 하다 in this question. |
| `cloze_a2_0537` | 집안일 | 민호 씨, 주말에는 누가 전화기를 해요? | ✗ The substitutes do not form an activity collocation with 하다 in this question. |
| `cloze_a2_0537` | 집안일 | 민호 씨, 주말에는 누가 공원을 해요? | ✗ The substitutes do not form an activity collocation with 하다 in this question. |
| `cloze_a2_0538` | 세탁 | 이 코트는 집에서 쓰레기통을 하면 안 돼요. | ✗ The object nouns do not form the prohibited household action N을 하다. |
| `cloze_a2_0538` | 세탁 | 이 코트는 집에서 선풍기를 하면 안 돼요. | ✗ The object nouns do not form the prohibited household action N을 하다. |
| `cloze_a2_0538` | 세탁 | 이 코트는 집에서 전화기를 하면 안 돼요. | ✗ The object nouns do not form the prohibited household action N을 하다. |
| `cloze_a2_0539` | 빨다 | 더러운 양말을 손으로 앉았어요. | ✗ The fixed object 양말을 cannot be governed by the intransitive substitutes. |
| `cloze_a2_0539` | 빨다 | 더러운 양말을 손으로 누웠어요. | ✗ The fixed object 양말을 cannot be governed by the intransitive substitutes. |
| `cloze_a2_0539` | 빨다 | 더러운 양말을 손으로 뛰었어요. | ✗ The fixed object 양말을 cannot be governed by the intransitive substitutes. |
| `cloze_a2_0540` | 쓰레기통 | 다 마신 컵은 결혼에 버리세요. | ✗ The destination of 버리다 must be a disposal place; the abstract substitutes are not places. |
| `cloze_a2_0540` | 쓰레기통 | 다 마신 컵은 환영에 버리세요. | ✗ The destination of 버리다 must be a disposal place; the abstract substitutes are not places. |
| `cloze_a2_0540` | 쓰레기통 | 다 마신 컵은 안전에 버리세요. | ✗ The destination of 버리다 must be a disposal place; the abstract substitutes are not places. |
| `cloze_a2_0541` | 휴지 | 화장실에 나흘이 없어서 불편했어요. | ✗ Durations and an event cannot be restroom supplies whose absence causes this problem. |
| `cloze_a2_0541` | 휴지 | 화장실에 열흘이 없어서 불편했어요. | ✗ Durations and an event cannot be restroom supplies whose absence causes this problem. |
| `cloze_a2_0541` | 휴지 | 화장실에 결혼이 없어서 불편했어요. | ✗ Durations and an event cannot be restroom supplies whose absence causes this problem. |
| `cloze_a2_0542` | 목욕 | 자기 전에 따뜻한 물로 식탁을 해요. | ✗ The substitutes do not form a personal routine with N을 하다. |
| `cloze_a2_0542` | 목욕 | 자기 전에 따뜻한 물로 전화기를 해요. | ✗ The substitutes do not form a personal routine with N을 하다. |
| `cloze_a2_0542` | 목욕 | 자기 전에 따뜻한 물로 햇빛을 해요. | ✗ The substitutes do not form a personal routine with N을 하다. |
| `cloze_a2_0543` | 양치질 | 식사 후에는 꼭 바닥을 하세요. | ✗ The concrete/place nouns do not form the required hygiene activity with 하다. |
| `cloze_a2_0543` | 양치질 | 식사 후에는 꼭 도서관을 하세요. | ✗ The concrete/place nouns do not form the required hygiene activity with 하다. |
| `cloze_a2_0543` | 양치질 | 식사 후에는 꼭 책상을 하세요. | ✗ The concrete/place nouns do not form the required hygiene activity with 하다. |
| `cloze_a2_0544` | 치약 | 잔치가 다 떨어져서 마트에서 샀어요. | ✗ The event and message nouns are not consumable supplies that run out and are replaced at a store. |
| `cloze_a2_0544` | 치약 | 환영이 다 떨어져서 마트에서 샀어요. | ✗ The event and message nouns are not consumable supplies that run out and are replaced at a store. |
| `cloze_a2_0544` | 치약 | 메일이 다 떨어져서 마트에서 샀어요. | ✗ The event and message nouns are not consumable supplies that run out and are replaced at a store. |
| `cloze_a2_0545` | 선풍기 | 더워서 만두를 켜고 잤어요. | ✗ The substitutes cannot be electrical devices switched on for cooling. |
| `cloze_a2_0545` | 선풍기 | 더워서 고장을 켜고 잤어요. | ✗ The substitutes cannot be electrical devices switched on for cooling. |
| `cloze_a2_0545` | 선풍기 | 더워서 연말을 켜고 잤어요. | ✗ The substitutes cannot be electrical devices switched on for cooling. |
| `cloze_a2_0546` | 식탁 | 저녁 준비가 끝나서 고장에 그릇을 놓았어요. | ✗ The location receiving dishes must be a surface; the abstract substitutes are not surfaces. |
| `cloze_a2_0546` | 식탁 | 저녁 준비가 끝나서 서비스에 그릇을 놓았어요. | ✗ The location receiving dishes must be a surface; the abstract substitutes are not surfaces. |
| `cloze_a2_0546` | 식탁 | 저녁 준비가 끝나서 메일에 그릇을 놓았어요. | ✗ The location receiving dishes must be a surface; the abstract substitutes are not surfaces. |
| `cloze_a2_0547` | 바닥 | 청소기로 이틀을 깨끗하게 청소했어요. | ✗ Time spans cannot be physical surfaces cleaned with a vacuum cleaner. |
| `cloze_a2_0547` | 바닥 | 청소기로 사흘을 깨끗하게 청소했어요. | ✗ Time spans cannot be physical surfaces cleaned with a vacuum cleaner. |
| `cloze_a2_0547` | 바닥 | 청소기로 연말을 깨끗하게 청소했어요. | ✗ Time spans cannot be physical surfaces cleaned with a vacuum cleaner. |
| `cloze_a2_0548` | 냄비 | 고장에 물을 넣고 끓이세요. | ✗ The substitutes are not containers that can hold water for boiling. |
| `cloze_a2_0548` | 냄비 | 연결에 물을 넣고 끓이세요. | ✗ The substitutes are not containers that can hold water for boiling. |
| `cloze_a2_0548` | 냄비 | 서비스에 물을 넣고 끓이세요. | ✗ The substitutes are not containers that can hold water for boiling. |
| `cloze_a2_0549` | 이틀 | 현아 씨, 우산 동안 어디에 있었어요? | ✗ The 동안 slot requires a duration; the portable objects cannot measure time. |
| `cloze_a2_0549` | 이틀 | 현아 씨, 지갑 동안 어디에 있었어요? | ✗ The 동안 slot requires a duration; the portable objects cannot measure time. |
| `cloze_a2_0549` | 이틀 | 현아 씨, 열쇠 동안 어디에 있었어요? | ✗ The 동안 slot requires a duration; the portable objects cannot measure time. |
| `cloze_a2_0550` | 사흘 | 감기로 의자 동안 학교에 못 갔어요. | ✗ The 동안 slot requires a duration; furniture cannot measure the absence. |
| `cloze_a2_0550` | 사흘 | 감기로 책상 동안 학교에 못 갔어요. | ✗ The 동안 slot requires a duration; furniture cannot measure the absence. |
| `cloze_a2_0550` | 사흘 | 감기로 침대 동안 학교에 못 갔어요. | ✗ The 동안 slot requires a duration; furniture cannot measure the absence. |
| `cloze_a2_0551` | 나흘 | 비가 지도 동안 계속 왔어요. | ✗ The 동안 slot requires a duration; the objects cannot measure rainfall. |
| `cloze_a2_0551` | 나흘 | 비가 그림 동안 계속 왔어요. | ✗ The 동안 slot requires a duration; the objects cannot measure rainfall. |
| `cloze_a2_0551` | 나흘 | 비가 신발 동안 계속 왔어요. | ✗ The 동안 slot requires a duration; the objects cannot measure rainfall. |
| `cloze_a2_0552` | 열흘 | 숟가락 후에 독일에서 부모님이 오세요. | ✗ The 후에 phrase requires elapsed time; the objects do not supply a time interval. |
| `cloze_a2_0552` | 열흘 | 엽서 후에 독일에서 부모님이 오세요. | ✗ The 후에 phrase requires elapsed time; the objects do not supply a time interval. |
| `cloze_a2_0552` | 열흘 | 의자 후에 독일에서 부모님이 오세요. | ✗ The 후에 phrase requires elapsed time; the objects do not supply a time interval. |
| `cloze_a2_0553` | 개월 | 저는 삼 냄비 전에 한국에 왔어요. | ✗ After the Sino-Korean numeral 삼, only a month counter fits; the nouns cannot be counters. |
| `cloze_a2_0553` | 개월 | 저는 삼 얼음 전에 한국에 왔어요. | ✗ After the Sino-Korean numeral 삼, only a month counter fits; the nouns cannot be counters. |
| `cloze_a2_0553` | 개월 | 저는 삼 하늘 전에 한국에 왔어요. | ✗ After the Sino-Korean numeral 삼, only a month counter fits; the nouns cannot be counters. |
| `cloze_a2_0554` | 그동안 | 우산 연락을 못 해서 미안해요. | ✗ The sentence-initial time adverbial cannot be replaced by unrelated objects. |
| `cloze_a2_0554` | 그동안 | 지도 연락을 못 해서 미안해요. | ✗ The sentence-initial time adverbial cannot be replaced by unrelated objects. |
| `cloze_a2_0554` | 그동안 | 침대 연락을 못 해서 미안해요. | ✗ The sentence-initial time adverbial cannot be replaced by unrelated objects. |
| `cloze_a2_0555` | 오랜만 | 치약에 고향 친구를 만나서 반가웠어요. | ✗ Only the temporal expression can modify the reunion; the substitutes are locatives without a coherent event relation. |
| `cloze_a2_0555` | 오랜만 | 냄비에 고향 친구를 만나서 반가웠어요. | ✗ Only the temporal expression can modify the reunion; the substitutes are locatives without a coherent event relation. |
| `cloze_a2_0555` | 오랜만 | 하늘에 고향 친구를 만나서 반가웠어요. | ✗ Only the temporal expression can modify the reunion; the substitutes are locatives without a coherent event relation. |
| `cloze_a2_0556` | 마지막 | 이번 학기 수업은 오늘이 책상이에요. | ✗ Only 마지막 identifies today's place at the end of the semester; the object copulas cannot describe today in this frame. |
| `cloze_a2_0556` | 마지막 | 이번 학기 수업은 오늘이 연필이에요. | ✗ Only 마지막 identifies today's place at the end of the semester; the object copulas cannot describe today in this frame. |
| `cloze_a2_0556` | 마지막 | 이번 학기 수업은 오늘이 양말이에요. | ✗ Only 마지막 identifies today's place at the end of the semester; the object copulas cannot describe today in this frame. |
| `cloze_a2_0557` | 최근 | 지갑에 회사 근처로 이사했어요. | ✗ The sentence-initial temporal adjunct cannot be replaced by object locatives. |
| `cloze_a2_0557` | 최근 | 신발에 회사 근처로 이사했어요. | ✗ The sentence-initial temporal adjunct cannot be replaced by object locatives. |
| `cloze_a2_0557` | 최근 | 편지에 회사 근처로 이사했어요. | ✗ The sentence-initial temporal adjunct cannot be replaced by object locatives. |
| `cloze_a2_0558` | 다음날 | 늦게 자서 침대 아침에 못 일어났어요. | ✗ Only a day expression can modify 아침; the objects cannot form this temporal compound. |
| `cloze_a2_0558` | 다음날 | 늦게 자서 의자 아침에 못 일어났어요. | ✗ Only a day expression can modify 아침; the objects cannot form this temporal compound. |
| `cloze_a2_0558` | 다음날 | 늦게 자서 가방 아침에 못 일어났어요. | ✗ Only a day expression can modify 아침; the objects cannot form this temporal compound. |
| `cloze_a2_0559` | 어젯밤 | 그림에 이상한 꿈을 꿨어요. | ✗ The dream requires a time adjunct; the object locatives do not provide one. |
| `cloze_a2_0559` | 어젯밤 | 우표에 이상한 꿈을 꿨어요. | ✗ The dream requires a time adjunct; the object locatives do not provide one. |
| `cloze_a2_0559` | 어젯밤 | 엽서에 이상한 꿈을 꿨어요. | ✗ The dream requires a time adjunct; the object locatives do not provide one. |
| `cloze_a2_0560` | 점심시간 | 수진 씨, 고장에 같이 밥 먹어요? | ✗ The invitation needs a time; the abstract substitutes are not time expressions. |
| `cloze_a2_0560` | 점심시간 | 수진 씨, 연결에 같이 밥 먹어요? | ✗ The invitation needs a time; the abstract substitutes are not time expressions. |
| `cloze_a2_0560` | 점심시간 | 수진 씨, 서비스에 같이 밥 먹어요? | ✗ The invitation needs a time; the abstract substitutes are not time expressions. |
| `cloze_a2_0561` | 구름 | 독서가 많아서 하늘이 어두워요. | ✗ Only countable sky matter can be 많다 and darken the sky; the activities and duration cannot. |
| `cloze_a2_0561` | 구름 | 양치질이 많아서 하늘이 어두워요. | ✗ Only countable sky matter can be 많다 and darken the sky; the activities and duration cannot. |
| `cloze_a2_0561` | 구름 | 사흘이 많아서 하늘이 어두워요. | ✗ Only countable sky matter can be 많다 and darken the sky; the activities and duration cannot. |
| `cloze_a2_0562` | 하늘 | 비가 그치고 수업이 정말 맑아요. | ✗ The clear-state subject after rain must be the sky; the activity and duration substitutes do not fit. |
| `cloze_a2_0562` | 하늘 | 비가 그치고 양치질이 정말 맑아요. | ✗ The clear-state subject after rain must be the sky; the activity and duration substitutes do not fit. |
| `cloze_a2_0562` | 하늘 | 비가 그치고 사흘이 정말 맑아요. | ✗ The clear-state subject after rain must be the sky; the activity and duration substitutes do not fit. |
| `cloze_a2_0563` | 햇빛 | 우표가 너무 강해서 모자를 썼어요. | ✗ The objects cannot be an environmental force whose strength motivates wearing a hat. |
| `cloze_a2_0563` | 햇빛 | 엽서가 너무 강해서 모자를 썼어요. | ✗ The objects cannot be an environmental force whose strength motivates wearing a hat. |
| `cloze_a2_0563` | 햇빛 | 침대가 너무 강해서 모자를 썼어요. | ✗ The objects cannot be an environmental force whose strength motivates wearing a hat. |
| `cloze_a2_0564` | 기온 | 내일은 독서가 5도까지 내려가요. | ✗ Only air temperature can fall to a value measured in degrees; the activity nouns cannot. |
| `cloze_a2_0564` | 기온 | 내일은 양치질이 5도까지 내려가요. | ✗ Only air temperature can fall to a value measured in degrees; the activity nouns cannot. |
| `cloze_a2_0564` | 기온 | 내일은 집안일이 5도까지 내려가요. | ✗ Only air temperature can fall to a value measured in degrees; the activity nouns cannot. |
| `cloze_a2_0565` | 영하 | 오늘 아침에는 공원 5도까지 내려갔어요. | ✗ Before 5도, only the below-zero marker fits; the nouns cannot modify a temperature reading. |
| `cloze_a2_0565` | 영하 | 오늘 아침에는 유리 5도까지 내려갔어요. | ✗ Before 5도, only the below-zero marker fits; the nouns cannot modify a temperature reading. |
| `cloze_a2_0565` | 영하 | 오늘 아침에는 이틀 5도까지 내려갔어요. | ✗ Before 5도, only the below-zero marker fits; the nouns cannot modify a temperature reading. |
| `cloze_a2_0566` | 얼음 | 물에 잔치를 넣어서 마셨어요. | ✗ Only ice can be put into drinking water; the event and time nouns cannot. |
| `cloze_a2_0566` | 얼음 | 물에 연말을 넣어서 마셨어요. | ✗ Only ice can be put into drinking water; the event and time nouns cannot. |
| `cloze_a2_0566` | 얼음 | 물에 점심시간을 넣어서 마셨어요. | ✗ Only ice can be put into drinking water; the event and time nouns cannot. |

## 검수 메모

- Surface-form maximum reuse: 4.
- Stem reuse is checked by `a2_draft_rules.distractor_stem_reuse_counts` with cap 4.
- Tier B ratio: 0/64 (0%).
- Jin/native/educator approval remains pending.
