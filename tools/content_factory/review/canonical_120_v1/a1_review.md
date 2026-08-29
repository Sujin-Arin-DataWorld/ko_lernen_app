# A1 정본 시나리오 검토

> 자동 검사는 승인 증거가 아닙니다. 아래 20개를 모두 읽은 뒤 Jin이 결정합니다.

## 1. 공항에서 첫 인사 (`airport_arrival`)

- 수행 목표: 처음 만난 담당자에게 인사하고 짧게 확인할 수 있다
- 관계·사건: 처음 만난 입국 담당자와 여행자 / 담당자가 여권을 보고 한국 방문이 처음인지 짧게 확인한다
- 단원: `a1_01_greetings_hangul`

**담당자**  
KO: 안녕하세요. 여권 주세요.  
DE: Guten Tag. Ihren Reisepass, bitte.  
EN: Hello. Your passport, please.

**크리스티안 (나)**  
KO: 네, 여기 있어요.  
DE: Ja, hier bitte.  
EN: Yes, here you are.

**담당자**  
KO: 한국은 처음이세요?  
DE: Sind Sie zum ersten Mal in Korea?  
EN: Is this your first time in Korea?

**크리스티안 (나)**  
KO: 죄송해요. 다시 말씀해 주세요.  
DE: Entschuldigung. Bitte sagen Sie das noch einmal.  
EN: Sorry. Could you say that again?

**담당자**  
KO: 한국이 처음이에요?  
DE: Ist es Ihr erstes Mal in Korea?  
EN: Is this your first time in Korea?

**크리스티안 (나)**  
KO: 네, 한국이 처음이에요.  
DE: Ja, ich bin zum ersten Mal in Korea.  
EN: Yes, this is my first time in Korea.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 2. 빵집에서 봉투 묻고 답하기 (`bakery_payment_bag`)

- 수행 목표: 가게에서 필요한 것과 필요 없는 것을 말할 수 있다
- 관계·사건: 손님과 직원 / 직원이 봉투가 필요한지 묻고 크리스티안이 필요 없다고 답한다
- 단원: `a1_14_payment_delivery`

**직원**  
KO: 봉투 필요하세요?  
DE: Brauchen Sie eine Tüte?  
EN: Do you need a bag?

**크리스티안 (나)**  
KO: 아니요, 괜찮아요.  
DE: Nein, danke.  
EN: No, thank you.

**직원**  
KO: 빵 두 개 맞으세요?  
DE: Das sind zwei Brötchen, richtig?  
EN: That's two pastries, right?

**크리스티안 (나)**  
KO: 네, 두 개 맞아요.  
DE: Ja, zwei.  
EN: Yes, two.

**크리스티안 (나)**  
KO: 이 빵만 바로 먹을게요.  
DE: Nur dieses hier esse ich gleich.  
EN: I'll eat just this one now.

**직원**  
KO: 그럼 이건 따로 드릴게요.  
DE: Dann gebe ich Ihnen dieses separat.  
EN: Then I'll keep this one separate.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 3. 빵집에서 줄을 잘못 섰을 때 (`bakery_queue`)

- 수행 목표: 줄을 잘못 섰을 때 짧게 사과하고 뒤로 갈 수 있다
- 관계·사건: 처음 보는 크리스티안과 수진 / 크리스티안이 줄인지 모르고 계산대 앞으로 간다
- 단원: `a1_08_clarify_repair`

**크리스티안 (나)**  
KO: 이 빵 계산해 주세요.  
DE: Ich möchte dieses Brot bezahlen.  
EN: I'd like to pay for this bread.

**수진**  
KO: 저기요, 여기 줄 서 있는데요.  
DE: Entschuldigung, wir stehen hier an.  
EN: Excuse me, there's a line here.

**크리스티안 (나)**  
KO: 아, 죄송합니다. 줄 서 계신지 몰랐어요.
DE: Oh, Entschuldigung. Ich habe nicht gesehen, dass Sie anstehen.
EN: Oh, sorry. I didn't realize you were in line.

**수진**  
KO: 괜찮아요. 줄은 저 뒤예요.  
DE: Kein Problem. Das Ende ist dort hinten.  
EN: No problem. The end is back there.

**크리스티안 (나)**  
KO: 네, 뒤에 설게요.  
DE: Okay, ich stelle mich hinten an.  
EN: Okay, I'll join at the back.

**수진**  
KO: 네, 괜찮아요.  
DE: Alles gut.  
EN: It's okay.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 4. 실수로 잔을 깨뜨렸을 때 (`break_glass_apology`)

- 수행 목표: 작은 실수에 사과하고 괜찮은지 물을 수 있다
- 관계·사건: 아직 조심스러운 친구 크리스티안과 수진 / 크리스티안이 물을 따르다 잔을 떨어뜨린다
- 단원: `a1_10_health_safety`

**크리스티안 (나)**  
KO: 죄송해요. 잔을 깼어요.  
DE: Tut mir leid. Ich habe ein Glas zerbrochen.  
EN: I'm sorry. I broke a glass.

**수진**  
KO: 괜찮아요. 손대지 마세요.  
DE: Schon gut. Fass die Scherben nicht an.  
EN: It's okay. Don't touch the glass.

**크리스티안 (나)**  
KO: 괜찮아요? 안 다쳤어요?  
DE: Alles okay? Du hast dich nicht verletzt, oder?  
EN: Are you okay? You didn't get hurt, did you?

**수진**  
KO: 네, 안 다쳤어요.  
DE: Ja, ich habe mich nicht verletzt.  
EN: Yes, I'm not hurt.

**크리스티안 (나)**  
KO: 빗자루 어디 있어요? 같이 치울게요.  
DE: Wo ist der Besen? Ich helfe beim Aufräumen.  
EN: Where's the broom? I'll help clean up.

**수진**  
KO: 그럼 빗자루로 큰 조각만 모아 주세요.  
DE: Dann kehr bitte nur die großen Stücke zusammen.  
EN: Then please sweep up just the large pieces.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 5. 분식집에서 떡볶이 주문하기 (`bunshik_tteokbokki`)

- 수행 목표: 음식과 원하는 맛을 말해 주문할 수 있다
- 관계·사건: 손님과 식당 직원 / 레나가 떡볶이를 주문하고 매운 정도를 묻는다
- 단원: `a1_04_order_request_object`

**식당 직원**  
KO: 주문하시겠어요?  
DE: Möchten Sie bestellen?  
EN: Are you ready to order?

**레나 (나)**  
KO: 떡볶이 하나 주세요.  
DE: Einmal Tteokbokki, bitte.  
EN: One tteokbokki, please.

**레나 (나)**  
KO: 많이 매워요?  
DE: Ist es sehr scharf?  
EN: Is it very spicy?

**식당 직원**  
KO: 조금 매워요. 순한 맛도 있어요.  
DE: Ein bisschen. Es gibt auch eine milde Variante.  
EN: A little. We also have a mild version.

**레나 (나)**  
KO: 그럼 순한 맛으로 주세요.  
DE: Dann bitte die milde Variante.  
EN: Then I'll have the mild version, please.

**식당 직원**  
KO: 네, 순한 맛으로 드릴게요.  
DE: Gern, dann die milde Variante.  
EN: Sure, I'll make it mild.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 6. 카페 디저트가 없을 때 (`cafe_dessert_sold_out`)

- 수행 목표: 메뉴가 있는지 묻고 다른 것을 선택할 수 있다
- 관계·사건: 손님과 카페 직원 / 원한 케이크가 다 팔려 직원이 다른 디저트를 알려 준다
- 단원: `a1_12_daily_negation`

**레나 (나)**  
KO: 딸기 케이크 있어요?  
DE: Gibt es Erdbeerkuchen?  
EN: Do you have strawberry cake?

**직원**  
KO: 죄송해요. 오늘은 없어요.  
DE: Tut mir leid. Heute ist er ausverkauft.  
EN: Sorry, we're out today.

**레나 (나)**  
KO: 그럼 푸딩은 있어요?  
DE: Gibt es dann Pudding?  
EN: Do you have pudding instead?

**직원**  
KO: 네, 푸딩은 있어요.  
DE: Ja, Pudding haben wir.  
EN: Yes, we have pudding.

**레나 (나)**  
KO: 푸딩 하나 주세요.  
DE: Dann einmal Pudding, bitte.  
EN: One pudding, please.

**직원**  
KO: 네, 준비해 드릴게요.  
DE: Gern, ich mache ihn fertig.  
EN: Sure, I'll get that ready.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 7. 지하철 출구를 다시 묻기 (`clarify_repeat`)

- 수행 목표: 못 들었을 때 다시 말해 달라고 할 수 있다
- 관계·사건: 여행자와 역 직원 / 직원이 출구 번호를 말했지만 크리스티안이 잘 못 듣는다
- 단원: `a1_08_clarify_repair`

**크리스티안 (나)**  
KO: 시청은 몇 번 출구예요?  
DE: Welcher Ausgang führt zum Rathaus?  
EN: Which exit is for City Hall?

**직원**  
KO: 13번 출구예요.  
DE: Ausgang 13.  
EN: Exit 13.

**크리스티안 (나)**  
KO: 3번 출구요?  
DE: Ausgang 3?  
EN: Exit 3?

**직원**  
KO: 아니요, 13번이요.  
DE: Nein, Ausgang 13.  
EN: No, exit 13.

**크리스티안 (나)**  
KO: 다시 말씀해 주세요.  
DE: Bitte sagen Sie das noch einmal.  
EN: Could you say that again?

**직원**  
KO: 십삼 번 출구예요.  
DE: Ausgang dreizehn.  
EN: Exit thirteen.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 8. 댄스 수업에서 말투 알아듣기 (`dance_class_register`)

- 수행 목표: 같은 뜻의 해요체와 친한 말투를 구별해 들을 수 있다
- 관계·사건: 강사와 처음 온 레나, 친한 마야 / 강사는 존댓말로 안내하고 마야는 레나에게 반말로 자리를 알려 준다
- 단원: `a1_13_register_switching`

**강사**  
KO: 레나, 여기 서세요.  
DE: Lena, stell dich bitte hierhin.  
EN: Lena, please stand here.

**레나 (나)**  
KO: 네. 여기요?  
DE: Ja. Hier?  
EN: Okay. Here?

**강사**  
KO: 네, 마야 옆에 서세요.  
DE: Ja, neben Maya.  
EN: Yes, next to Maya.

**마야**  
KO: 레나, 여기 서.  
DE: Lena, stell dich hierhin.  
EN: Lena, stand here.

**레나 (나)**  
KO: ‘여기 서’도 맞아?  
DE: Ist „여기 서“ auch richtig?  
EN: Is '여기 서' right too?

**마야**  
KO: 응. 친구한테는 이렇게 말해.  
DE: Ja. So sage ich es zu Freunden.  
EN: Yes. That's how I say it to friends.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 9. 좋아하는 한국 음악 묻기 (`favorite_korean_music`)

- 수행 목표: 좋아하는 음악과 가수를 짧게 말할 수 있다
- 관계·사건: 막 친해지기 시작한 레나와 마야 / 공연 음악이 들리자 서로 좋아하는 가수를 묻는다
- 단원: `a1_11_titles_relationships`

**마야**  
KO: 한국 음악도 좋아해요?  
DE: Magst du auch koreanische Musik?  
EN: Do you like Korean music too?

**레나 (나)**  
KO: 네, 아주 좋아해요.  
DE: Ja, sehr sogar.  
EN: Yes, very much.

**마야**  
KO: 어떤 가수 좋아해요?  
DE: Welche Sängerin oder welchen Sänger magst du?  
EN: Which singer do you like?

**레나 (나)**  
KO: 저는 유나를 좋아해요.  
DE: Ich mag Yuna.  
EN: I like Yuna.

**마야**  
KO: 저도 좋아해요. 새 노래도 좋아해요?  
DE: Ich mag sie auch. Magst du ihr neues Lied auch?  
EN: I like her too. Do you like her new song too?

**레나 (나)**  
KO: 네, 요즘 그 노래만 들어요.  
DE: Ja, im Moment höre ich fast nur dieses Lied.  
EN: Yes, that's almost all I listen to these days.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 10. 첫 수업에서 옆자리 학생 만나기 (`first_class_meeting`)

- 수행 목표: 첫 수업에서 옆 사람에게 인사하고 기본 정보를 말할 수 있다
- 관계·사건: 처음 만난 크리스티안과 레나 / 두 사람이 어느 나라에서 왔는지 말하고 교재가 맞는지 확인한다
- 단원: `a1_15_first_class_work`

**레나**  
KO: 안녕하세요. 오늘 첫 수업이에요?  
DE: Hallo. Ist das heute dein erster Kurs?  
EN: Hi. Is this your first class today?

**크리스티안 (나)**  
KO: 네, 첫 수업이에요.  
DE: Ja, mein erster.  
EN: Yes, it's my first one.

**레나**  
KO: 어디에서 왔어요?  
DE: Woher kommst du?  
EN: Where are you from?

**크리스티안 (나)**  
KO: 독일에서 왔어요.  
DE: Ich komme aus Deutschland.  
EN: I'm from Germany.

**레나**  
KO: 저도 독일에서 왔어요.  
DE: Ich auch.  
EN: So am I.

**크리스티안 (나)**  
KO: 정말요? 반가워요.  
DE: Echt? Freut mich.  
EN: Really? Nice to meet you.

**레나**  
KO: 이 책 맞아요?  
DE: Ist das das richtige Buch?  
EN: Is this the right book?

**크리스티안 (나)**  
KO: 네, 맞아요.  
DE: Ja, genau.  
EN: Yes, it is.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 11. 아침 준비하며 물건 찾기 (`home_morning_routine`)

- 수행 목표: 집에서 물건의 위치를 묻고 답할 수 있다
- 관계·사건: 친한 교환학생 친구 크리스티안과 레나 / 나갈 시간이 됐는데 크리스티안이 교통카드를 찾지 못한다
- 단원: `a1_09_home_daily_life`

**크리스티안 (나)**  
KO: 교통카드 어디 있어?  
DE: Wo ist meine Fahrkarte?  
EN: Where's my transit card?

**레나**  
KO: 책 아래에 있어.  
DE: Sie liegt unter dem Buch.  
EN: It's under the book.

**크리스티안 (나)**  
KO: 여기 없어.  
DE: Hier ist sie nicht.  
EN: It's not here.

**레나**  
KO: 그 책 말고 큰 책.  
DE: Nicht das Buch. Das große.  
EN: Not that book. The big one.

**크리스티안 (나)**  
KO: 아, 여기 있다.  
DE: Ah, hier ist sie.  
EN: Oh, here it is.

**레나**  
KO: 찾았어? 빨리 가자.  
DE: Gefunden? Dann los.  
EN: Found it? Let's go.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 12. 처음 만나 자기소개하기 (`introduce_yourself`)

- 수행 목표: 이름과 출신을 말하고 상대 이름을 확인할 수 있다
- 관계·사건: 처음 만난 크리스티안과 수진 / 두 사람이 이름과 온 곳을 짧게 소개한다
- 단원: `a1_02_self_intro_identity`

**수진**  
KO: 안녕하세요. 저는 수진이에요.  
DE: Hallo. Ich bin Sujin.  
EN: Hi. I'm Sujin.

**크리스티안 (나)**  
KO: 안녕하세요. 저는 크리스티안이에요.  
DE: Hallo. Ich bin Christian.  
EN: Hi. I'm Christian.

**수진**  
KO: 어디에서 왔어요?  
DE: Woher kommst du?  
EN: Where are you from?

**크리스티안 (나)**  
KO: 독일에서 왔어요.  
DE: Ich komme aus Deutschland.  
EN: I'm from Germany.

**크리스티안 (나)**  
KO: 죄송해요. 이름을 다시 말해 주세요.  
DE: Entschuldigung, sag deinen Namen bitte noch einmal.  
EN: Sorry, please say your name again.

**수진**  
KO: 네, 수진이에요. 수진.  
DE: Ja, Sujin. Su-jin.  
EN: Yes, Sujin. Su-jin.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 13. 수업 뒤 카카오톡으로 연락하기 (`kakao_contact_after_class`)

- 수행 목표: 자연스러운 연락 방법을 묻고 간단히 확인할 수 있다
- 관계·사건: 처음 친해진 레나와 마야 / 마야가 같이 과제를 하려고 카카오톡으로 연락하자고 한다
- 단원: `a1_07_contact_address`

**마야**  
KO: 우리 과제 같이 해요.  
DE: Lass uns die Aufgabe zusammen machen.  
EN: Let's work on the assignment together.

**마야**  
KO: 카카오톡으로 연락할까요?  
DE: Wollen wir über KakaoTalk schreiben?  
EN: Shall we message each other on KakaoTalk?

**레나 (나)**  
KO: 네, 좋아요.  
DE: Ja, gern.  
EN: Yes, sounds good.

**마야**  
KO: 여기에 QR 코드가 있어요.  
DE: Hier ist mein QR-Code.  
EN: My QR code is right here.

**레나 (나)**  
KO: 이거 찍으면 돼요?  
DE: Soll ich den hier scannen?  
EN: Do I scan this?

**마야**  
KO: 네. 여기 눌러 보세요.  
DE: Ja. Tippe dann hier.  
EN: Yes. Then tap here.

**레나 (나)**  
KO: 아, 친구로 추가됐어요.  
DE: Ah, jetzt sind wir verbunden.  
EN: Oh, you're added now.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 14. 한국 생활이 어떤지 묻기 (`korea_stay_smalltalk`)

- 수행 목표: 한국에 온 시기와 생활에 대한 짧은 느낌을 말할 수 있다
- 관계·사건: 막 알게 된 레나와 마야 / 마야가 레나에게 한국에 언제 왔는지와 생활이 어떤지 묻는다
- 단원: `a1_11_titles_relationships`

**마야**  
KO: 한국에 언제 왔어요?  
DE: Wann bist du nach Korea gekommen?  
EN: When did you come to Korea?

**레나 (나)**  
KO: 두 달 전에 왔어요.  
DE: Vor zwei Monaten.  
EN: Two months ago.

**마야**  
KO: 한국 생활은 어때요?  
DE: Wie gefällt dir das Leben in Korea?  
EN: How is life in Korea?

**레나 (나)**  
KO: 재미있어요. 조금 어려워요.  
DE: Es macht Spaß. Manches ist etwas schwierig.  
EN: It's fun. Some things are a little hard.

**마야**  
KO: 한국 드라마도 봐요?  
DE: Schaust du auch koreanische Serien?  
EN: Do you watch Korean dramas too?

**레나 (나)**  
KO: 네, 요즘 매일 봐요.  
DE: Ja, im Moment jeden Tag.  
EN: Yes, every day these days.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 15. 마트에서 두부 찾기 (`mart_grocery`)

- 수행 목표: 물건 이름을 말하고 어디 있는지 물을 수 있다
- 관계·사건: 손님과 마트 직원 / 크리스티안이 두부가 어디 있는지 묻는다
- 단원: `a1_03_topic_subject_particles`

**크리스티안 (나)**  
KO: 저기요. 두부는 어디에 있어요?  
DE: Entschuldigung, wo finde ich Tofu?  
EN: Excuse me, where is the tofu?

**직원**  
KO: 저쪽 냉장고 옆에 있어요.  
DE: Dort drüben, neben dem Kühlregal.  
EN: Over there, next to the refrigerated section.

**크리스티안 (나)**  
KO: 이거 두부예요?  
DE: Ist das Tofu?  
EN: Is this tofu?

**직원**  
KO: 아니요, 그건 치즈예요.  
DE: Nein, das ist Käse.  
EN: No, that's cheese.

**크리스티안 (나)**  
KO: 그럼 이거예요?  
DE: Dann ist es das hier?  
EN: Then is it this one?

**직원**  
KO: 네, 그게 두부예요.  
DE: Ja, das ist Tofu.  
EN: Yes, that's tofu.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 16. 약속 시간을 다시 확인하기 (`meeting_time`)

- 수행 목표: 시간을 묻고 맞는 시간을 확인할 수 있다
- 관계·사건: 아직 존댓말을 쓰는 크리스티안과 수진 / 두 사람이 저녁 약속 시간을 서로 다르게 기억한다
- 단원: `a1_05_numbers_time`

**크리스티안 (나)**  
KO: 오늘 몇 시에 만나요?  
DE: Um wie viel Uhr treffen wir uns heute?  
EN: What time are we meeting today?

**수진**  
KO: 일곱 시에 만나요.  
DE: Um sieben Uhr.  
EN: At seven.

**크리스티안 (나)**  
KO: 여섯 시 아니에요?  
DE: Nicht um sechs?  
EN: Isn't it at six?

**수진**  
KO: 아니요, 일곱 시예요.  
DE: Nein, um sieben.  
EN: No, at seven.

**크리스티안 (나)**  
KO: 아, 일곱 시요.  
DE: Ah, sieben Uhr.  
EN: Oh, seven.

**수진**  
KO: 네. 카페 앞에서 봐요.  
DE: Genau. Bis dann vor dem Café.  
EN: Right. See you in front of the café.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 17. 지하철에서 발을 밟았을 때 (`subway_step_apology`)

- 수행 목표: 가벼운 접촉 실수에 바로 사과할 수 있다
- 관계·사건: 서로 모르는 승객 두 사람 / 열차가 흔들리며 크리스티안이 옆 승객의 발을 밟는다
- 단원: `a1_10_health_safety`

**크리스티안 (나)**  
KO: 앗, 죄송합니다.  
DE: Oh, Entschuldigung.  
EN: Oh, I'm sorry.

**손님**  
KO: 괜찮아요.  
DE: Schon gut.  
EN: It's okay.

**크리스티안 (나)**  
KO: 발 괜찮으세요?  
DE: Ist Ihr Fuß in Ordnung?  
EN: Is your foot okay?

**손님**  
KO: 네, 안 아파요.  
DE: Ja, es tut nicht weh.  
EN: Yes, it doesn't hurt.

**크리스티안 (나)**  
KO: 제가 못 봤어요. 조심할게요.  
DE: Ich habe nicht aufgepasst. Ich passe besser auf.  
EN: I didn't see you. I'll be more careful.

**손님**  
KO: 네, 괜찮아요.  
DE: Schon gut, alles in Ordnung.  
EN: It's okay. I'm fine.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 18. 한국에서 보낸 첫 주말 아침 (`survival_day_capstone`)

- 수행 목표: 익숙한 하루 계획에서 시간과 필요한 물건을 확인할 수 있다
- 관계·사건: 친한 교환학생 친구 크리스티안과 레나 / 두 사람이 장을 보러 나가며 필요한 물건과 만날 시간을 확인한다
- 단원: `a1_16_survival_capstone`

**크리스티안 (나)**  
KO: 몇 시에 나가?  
DE: Wann gehen wir los?  
EN: What time are we leaving?

**레나**  
KO: 열 시에 나가자.  
DE: Lass uns um zehn gehen.  
EN: Let's leave at ten.

**크리스티안 (나)**  
KO: 물하고 우유 사자.  
DE: Kaufen wir Wasser und Milch.  
EN: Let's buy water and milk.

**레나**  
KO: 좋아. 우산 있어?  
DE: Gut. Hast du einen Regenschirm?  
EN: Sounds good. Do you have an umbrella?

**크리스티안 (나)**  
KO: 아니, 없어.  
DE: Nein.  
EN: No, I don't.

**레나**  
KO: 밖에 비 와. 같이 쓰자.  
DE: Es regnet. Wir nehmen meinen zusammen.  
EN: It's raining. We can share mine.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 19. 택시에서 여기 세워 달라고 말하기 (`taxi_kakao`)

- 수행 목표: 택시에서 내릴 곳을 짧게 말할 수 있다
- 관계·사건: 승객과 택시 기사 / 앱에 입력한 목적지 근처에 도착해 승객이 편한 곳에 세워 달라고 말한다
- 단원: `a1_06_transport_directions`

**기사**  
KO: 이 근처 맞으시죠?  
DE: Hier in der Nähe, richtig?  
EN: It's around here, right?

**크리스티안 (나)**  
KO: 네. 여기 세워 주세요.  
DE: Ja. Bitte halten Sie hier.  
EN: Yes. Please stop here.

**기사**  
KO: 정문 앞은 차가 많아요.  
DE: Vor dem Haupteingang ist viel Verkehr.  
EN: There's a lot of traffic by the main entrance.

**크리스티안 (나)**  
KO: 그럼 저기 앞에 세워 주세요.  
DE: Dann halten Sie bitte dort vorne.  
EN: Then please stop up there.

**기사**  
KO: 네, 알겠습니다.  
DE: Ja, in Ordnung.  
EN: Sure.

**크리스티안 (나)**  
KO: 감사합니다.  
DE: Danke.  
EN: Thank you.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 20. 비 오는 날 우산 같이 쓰기 (`umbrella_weather`)

- 수행 목표: 날씨를 말하고 간단한 제안에 답할 수 있다
- 관계·사건: 친해지는 중인 크리스티안과 수진 / 갑자기 비가 오는데 크리스티안에게 우산이 없다
- 단원: `a1_09_home_daily_life`

**크리스티안 (나)**  
KO: 비 와요?  
DE: Regnet es?  
EN: Is it raining?

**수진**  
KO: 네, 많이 와요.  
DE: Ja, ziemlich stark.  
EN: Yes, quite hard.

**크리스티안 (나)**  
KO: 저는 우산이 없어요.  
DE: Ich habe keinen Regenschirm.  
EN: I don't have an umbrella.

**수진**  
KO: 제 우산 같이 써요.  
DE: Wir können meinen teilen.  
EN: We can share mine.

**크리스티안 (나)**  
KO: 지하철역에 가요?  
DE: Gehst du zur U-Bahn-Station?  
EN: Are you going to the subway station?

**수진**  
KO: 네, 같이 가요.  
DE: Ja, gehen wir zusammen.  
EN: Yes, let's go together.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:
