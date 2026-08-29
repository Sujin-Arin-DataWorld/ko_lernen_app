# A2 정본 시나리오 검토

> 자동 검사는 승인 증거가 아닙니다. 아래 20개를 모두 읽은 뒤 Jin이 결정합니다.

## 1. 옷 사이즈를 바꾸기 (`clothing_refund_size`)

- 수행 목표: 간단한 이유를 말해 상품 교환을 요청할 수 있다
- 관계·사건: 손님과 매장 직원 / 레나가 어제 산 셔츠가 작아서 영수증과 함께 가져온다
- 단원: `a2_05_delivery_services`

**직원**  
KO: 무엇을 도와드릴까요?  
DE: Wie kann ich Ihnen helfen?  
EN: How can I help you?

**레나 (나)**  
KO: 사이즈가 작아서 바꾸고 싶어요.  
DE: Es ist zu klein, deshalb möchte ich es umtauschen.  
EN: It's too small, so I'd like to exchange it.

**직원**  
KO: 영수증 있으세요?  
DE: Haben Sie den Kassenbon?  
EN: Do you have the receipt?

**레나 (나)**  
KO: 네, 여기 있어요.  
DE: Ja, hier.  
EN: Yes, here it is.

**직원**  
KO: 큰 사이즈는 이 색이 없어요.  
DE: In der größeren Größe ist diese Farbe ausverkauft.  
EN: We don't have this color in the larger size.

**레나 (나)**  
KO: 그럼 검은색으로 바꿀게요.  
DE: Dann nehme ich es in Schwarz.  
EN: Then I'll exchange it for the black one.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 2. 편의점 택배 찾기 (`convenience_parcel_pickup`)

- 수행 목표: 알림과 보관 번호를 이용해 택배를 찾을 수 있다
- 관계·사건: 손님과 편의점 직원 / 레나가 도착 알림을 보여 주고 보관된 택배를 찾는다
- 단원: `a2_05_delivery_services`

**직원**  
KO: 어서 오세요.  
DE: Hallo.  
EN: Hello.

**레나 (나)**  
KO: 택배 찾으러 왔어요.  
DE: Ich möchte ein Paket abholen.  
EN: I'm here to pick up a package.

**직원**  
KO: 도착 알림 보여 주세요.  
DE: Zeigen Sie mir bitte die Abholbenachrichtigung.  
EN: Please show me the pickup notice.

**레나 (나)**  
KO: 네, 여기 있어요.  
DE: Ja, hier.  
EN: Yes, here it is.

**직원**  
KO: 보관 번호 2841 맞으세요?  
DE: Ist die Abholnummer 2841?  
EN: Is the pickup number 2841?

**레나 (나)**  
KO: 네, 맞아요.  
DE: Ja, genau.  
EN: Yes, that's right.

**직원**  
KO: 확인됐어요. 여기 있습니다.  
DE: Alles bestätigt. Hier ist das Paket.  
EN: That's confirmed. Here's your package.

**레나 (나)**  
KO: 감사합니다.  
DE: Danke.  
EN: Thank you.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 3. 배달 음식이 너무 매울 때 (`delivery_dinner_spicy`)

- 수행 목표: 음식 상태와 한 가지 이유를 말하고 해결 방법을 고를 수 있다
- 관계·사건: 친구 수진과 크리스티안 / 크리스티안에게 음식이 예상보다 매워 두 사람이 곁들일 것을 찾는다
- 단원: `a2_04_feelings_health`

**크리스티안 (나)**  
KO: 와, 생각보다 너무 매워요.  
DE: Wow, das ist viel schärfer als gedacht.  
EN: Wow, this is much spicier than I expected.

**수진**  
KO: 괜찮아요? 물 줄까요?  
DE: Geht es? Möchtest du Wasser?  
EN: Are you okay? Do you want some water?

**크리스티안 (나)**  
KO: 물보다 밥이 있으면 좋겠어요.  
DE: Reis wäre besser als Wasser.  
EN: Rice would be better than water.

**수진**  
KO: 냉장고에 밥 조금 있어요.  
DE: Im Kühlschrank ist noch etwas Reis.  
EN: There's some rice in the fridge.

**크리스티안 (나)**  
KO: 다음에는 덜 맵게 주문할게요.  
DE: Nächstes Mal bestelle ich es weniger scharf.  
EN: Next time, I'll order it less spicy.

**수진**  
KO: 좋아요. 오늘은 밥이랑 먹어요.  
DE: Gut. Heute essen wir es mit Reis.  
EN: Good idea. Let's eat it with rice today.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 4. 첨부파일을 두 번 빠뜨린 이메일 (`email_attachment_twice`)

- 수행 목표: 반복된 실수를 인정하고 한 가지 해결 행동을 말할 수 있다
- 관계·사건: 신입 마야와 친절하지만 바쁜 동료 / 마야가 첨부했다고 쓴 메일에 파일을 안 붙여 다시 보냈는데 두 번째 메일에도 빠뜨린다
- 단원: `a2_06_study_work`

**동료**  
KO: 마야, 메일에 첨부파일이 없어요.  
DE: Maya, in der Mail ist kein Anhang.  
EN: Maya, there's no attachment in the email.

**마야 (나)**  
KO: 어? 다시 보냈는데요.  
DE: Was? Ich habe sie doch noch einmal geschickt.  
EN: What? I sent it again.

**동료**  
KO: 두 번째 메일에도 없어요.  
DE: Auch in der zweiten Mail fehlt er.  
EN: It's missing from the second email too.

**마야 (나)**  
KO: 아… 첨부파일을 또 안 붙였어요. 죄송해요.  
DE: Oh nein … Ich habe den Anhang schon wieder vergessen. Tut mir leid.  
EN: Oh no… I forgot the attachment again. Sorry.

**동료**  
KO: 이번에는 보내기 전에 첨부파일부터 확인해 봐요.  
DE: Prüf diesmal vor dem Senden zuerst den Anhang.  
EN: This time, check the attachment before you send it.

**마야 (나)**  
KO: 네, 이번에는 붙였어요. 확인하고 다시 보낼게요.  
DE: Ja, diesmal ist die Datei angehängt. Ich prüfe es noch einmal und schicke die Mail neu.  
EN: Yes, it's attached this time. I'll check once more and resend the email.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 5. 한국 생활과 좋아하는 드라마 이야기하기 (`favorite_drama_chat`)

- 수행 목표: 한국 생활과 좋아하는 콘텐츠에 대해 간단한 이유를 말할 수 있다
- 관계·사건: 친해지는 중인 마야와 수진 / 수진이 마야의 한국 생활을 묻다가 요즘 보는 한국 드라마 이야기로 이어진다
- 단원: `a2_01_haeyo_transition`

**수진**  
KO: 한국에 온 지 얼마나 됐어요?  
DE: Wie lange bist du schon in Korea?  
EN: How long have you been in Korea?

**마야 (나)**  
KO: 이제 세 달 됐어요.  
DE: Seit drei Monaten.  
EN: For three months now.

**수진**  
KO: 한국 생활은 어때요?  
DE: Wie gefällt dir das Leben in Korea?  
EN: How do you like life in Korea?

**마야 (나)**  
KO: 재미있어요. 요즘 한국 드라마도 많이 봐요.  
DE: Es gefällt mir. In letzter Zeit schaue ich auch viele koreanische Serien.  
EN: It's fun. I've also been watching a lot of Korean shows lately.

**수진**  
KO: 좋아하는 드라마 있어요?  
DE: Hast du eine Lieblingsserie?  
EN: Do you have a favorite show?

**마야 (나)**  
KO: 네, ‘봄밤’을 보고 있어요. 대화가 자연스러워서 좋아요.  
DE: Ja, ich schaue gerade „Frühlingsnacht“. Ich mag sie, weil die Dialoge natürlich klingen.  
EN: Yes, I'm watching 'One Spring Night.' I like it because the dialogue sounds natural.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 6. 집 열쇠를 두고 나온 날 (`forgot_house_key`)

- 수행 목표: 깜빡한 물건과 그 결과를 말하고 도움을 요청할 수 있다
- 관계·사건: 친한 크리스티안과 레나 / 크리스티안이 방 열쇠를 책상에 두고 나와 레나에게 도움을 청한다
- 단원: `a2_08_home_money`

**크리스티안 (나)**  
KO: 나 큰일 났어. 열쇠를 방에 두고 왔어.  
DE: Ich habe ein Problem. Mein Schlüssel liegt im Zimmer.  
EN: I've got a problem. I left my key in the room.

**레나**  
KO: 가방에도 없어?  
DE: Ist er auch nicht in deiner Tasche?  
EN: It's not in your bag either?

**크리스티안 (나)**  
KO: 응, 책상 위에 있어.  
DE: Nein, er liegt auf dem Schreibtisch.  
EN: No, it's on the desk.

**레나**  
KO: 관리실이 열려 있으면 물어보자.  
DE: Wenn das Büro noch offen ist, fragen wir dort.  
EN: If the office is open, let's ask there.

**크리스티안 (나)**  
KO: 혼자 가기 좀 어려워. 같이 가 줄래?  
DE: Allein ist es etwas schwierig. Kommst du mit?  
EN: It's a little hard to go alone. Will you come with me?

**레나**  
KO: 응, 지금 같이 가자.  
DE: Klar, gehen wir jetzt zusammen.  
EN: Sure, let's go together now.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 7. 발표 케이블을 안 가져왔을 때 (`forgot_presentation_cable`)

- 수행 목표: 빠뜨린 준비물을 말하고 간단한 대안을 제안할 수 있다
- 관계·사건: 조별 과제 동료 크리스티안과 레나 / 크리스티안이 노트북 케이블을 기숙사에 두고 왔다
- 단원: `a2_06_study_work`

**크리스티안 (나)**  
KO: 큰일이야. 케이블을 안 가져왔어.  
DE: Mist. Ich habe das Kabel vergessen.  
EN: This is bad. I forgot the cable.

**레나**  
KO: 기숙사에 있어?  
DE: Liegt es im Wohnheim?  
EN: Is it at the dorm?

**크리스티안 (나)**  
KO: 응. 책상에 두고 왔어.  
DE: Ja. Es liegt auf meinem Schreibtisch.  
EN: Yes. I left it on my desk.

**레나**  
KO: 지금 다녀오면 늦을 거야.  
DE: Wenn du es jetzt holst, kommst du zu spät.  
EN: If you go back now, you'll be late.

**크리스티안 (나)**  
KO: 내가 옆 조에 물어볼게.  
DE: Ich frage die andere Gruppe.  
EN: I'll ask the other group.

**레나**  
KO: 좋아. 나는 발표 파일을 열게.  
DE: Gut. Ich öffne die Präsentation.  
EN: Good. I'll open the presentation file.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 8. 갑자기 약속을 취소했을 때 (`friend_cancelled_plan`)

- 수행 목표: 미안함과 서운함을 간단히 말하고 대화를 이어 갈 수 있다
- 관계·사건: 친한 마야와 레나 / 마야가 당일에 약속을 취소해 레나가 서운해한다
- 단원: `a2_03_chat_relationships`

**마야 (나)**  
KO: 갑자기 취소해서 미안해.  
DE: Tut mir leid, dass ich so kurzfristig absage.  
EN: I'm sorry for canceling so suddenly.

**마야 (나)**  
KO: 집에 일이 생겨서 오늘은 못 갈 것 같아.  
DE: Zu Hause ist etwas passiert. Ich glaube, ich schaffe es heute nicht.  
EN: Something came up at home. I don't think I can make it today.

**레나**  
KO: 알겠어. 그런데 조금 서운했어.  
DE: Okay. Aber ich war schon ein bisschen enttäuscht.  
EN: Okay. But I did feel a little hurt.

**마야 (나)**  
KO: 기다리게 해서 더 미안해.  
DE: Es tut mir umso mehr leid, dass du gewartet hast.  
EN: I'm even more sorry that I kept you waiting.

**레나**  
KO: 오늘은 쉬고 내일 다시 이야기하자.  
DE: Ruh dich heute aus. Wir reden morgen noch einmal.  
EN: Rest today. Let's talk again tomorrow.

**마야 (나)**  
KO: 응, 내일 내가 먼저 연락할게.  
DE: Ja. Ich melde mich morgen zuerst.  
EN: Okay. I'll message you tomorrow.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 9. 단체 사진을 올리기 전에 묻기 (`group_chat_photo_permission`)

- 수행 목표: 사진을 올려도 되는지 묻고 허락하거나 거절할 수 있다
- 관계·사건: 친구 마야와 레나 / 마야가 단체 사진을 인스타그램 스토리에 올리려 한다
- 단원: `a2_03_chat_relationships`

**마야**  
KO: 이 사진 올려도 돼?  
DE: Darf ich dieses Foto posten?  
EN: Can I post this photo?

**레나 (나)**  
KO: 이건 내 얼굴이 이상하게 나왔어.  
DE: Auf dem sehe ich komisch aus.  
EN: I look strange in this one.

**마야**  
KO: 그럼 이 사진은 어때?  
DE: Wie ist dann dieses hier?  
EN: How about this one, then?

**레나 (나)**  
KO: 응, 이 사진은 괜찮아.  
DE: Ja, das ist okay.  
EN: Yes, this one is fine.

**마야**  
KO: 스토리에만 올릴게.  
DE: Ich poste es nur in der Story.  
EN: I'll only post it to my story.

**레나 (나)**  
KO: 응. 올리기 전에 물어봐 줘서 고마워.  
DE: Okay. Danke, dass du vorher gefragt hast.  
EN: Okay. Thanks for asking first.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 10. 운동 수업을 취소하기 (`gym_class_cancel`)

- 수행 목표: 건강 이유를 말해 예약을 취소하거나 변경할 수 있다
- 관계·사건: 회원과 직원 / 레나가 발목이 아파 저녁 수업을 취소하려 한다
- 단원: `a2_04_feelings_health`

**직원**  
KO: 안녕하세요. 무엇을 도와드릴까요?  
DE: Guten Tag. Wie kann ich Ihnen helfen?  
EN: Hello. How can I help you?

**레나 (나)**  
KO: 발목이 아파서 오늘 수업을 못 가요.  
DE: Mein Knöchel tut weh, deshalb kann ich heute nicht zum Kurs kommen.  
EN: My ankle hurts, so I can't make it to class today.

**직원**  
KO: 오늘 수업을 취소할까요?  
DE: Soll ich den heutigen Kurs stornieren?  
EN: Would you like me to cancel today's class?

**레나 (나)**  
KO: 다른 날로 바꿀 수 있어요?  
DE: Kann ich auf einen anderen Tag umbuchen?  
EN: Can I move it to another day?

**직원**  
KO: 네, 금요일 저녁에 자리가 있어요.  
DE: Ja, am Freitagabend ist noch ein Platz frei.  
EN: Yes, there's a spot on Friday evening.

**레나 (나)**  
KO: 그럼 금요일 저녁으로 바꿔 주세요.  
DE: Dann bitte auf Freitagabend.  
EN: Then please move it to Friday evening.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 11. 제주에서 막차를 놓쳤을 때 (`jeju_bus_missed`)

- 수행 목표: 여행 중 놓친 교통편과 다음 계획을 말할 수 있다
- 관계·사건: 여행 중인 레나와 다니엘 / 두 사람이 사진을 찍다 숙소 방향 막차를 놓친다
- 단원: `a2_07_travel_repair`

**레나 (나)**  
KO: 다니엘, 우리 막차를 놓쳤어.  
DE: Daniel, wir haben den letzten Bus verpasst.  
EN: Daniel, we missed the last bus.

**다니엘**  
KO: 사진을 찍어서 시간을 못 봤네.  
DE: Beim Fotografieren habe ich die Zeit ganz vergessen.  
EN: I lost track of time while taking photos.

**레나 (나)**  
KO: 다음 버스는 내일 아침이야.  
DE: Der nächste Bus fährt erst morgen früh.  
EN: The next bus isn't until tomorrow morning.

**다니엘**  
KO: 먼저 숙소에 늦게 도착한다고 연락하자.  
DE: Sagen wir zuerst der Unterkunft, dass wir später ankommen.  
EN: Let's tell the accommodation we'll arrive late first.

**레나 (나)**  
KO: 응. 그다음에 택시를 찾아보자.  
DE: Ja. Danach suchen wir ein Taxi.  
EN: Okay. Then let's look for a taxi.

**다니엘**  
KO: 좋아. 내가 메시지 보낼게.  
DE: Gut. Ich schicke die Nachricht.  
EN: All right. I'll send the message.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 12. 도서관 카드가 인식되지 않을 때 (`library_card_problem`)

- 수행 목표: 공공시설에서 간단한 기기 문제를 설명하고 도움을 받을 수 있다
- 관계·사건: 이용자와 도서관 직원 / 대출 기계에서 카드가 읽히지 않아 레나가 도움을 요청한다
- 단원: `a2_08_home_money`

**레나 (나)**  
KO: 저기요. 카드가 안 돼요.  
DE: Entschuldigung, meine Karte funktioniert nicht.  
EN: Excuse me, my card isn't working.

**직원**  
KO: 한 번 다시 찍어 보세요.  
DE: Versuchen Sie bitte, sie noch einmal zu scannen.  
EN: Please try scanning it again.

**레나 (나)**  
KO: 다시 해도 안 돼요.  
DE: Auch beim zweiten Versuch geht es nicht.  
EN: It still doesn't work when I try again.

**직원**  
KO: 앱 바코드는 있으세요?  
DE: Haben Sie den Barcode in der App?  
EN: Do you have the barcode in the app?

**레나 (나)**  
KO: 네. 앱으로 빌려도 돼요?  
DE: Ja. Kann ich das Buch damit ausleihen?  
EN: Yes. Can I borrow the book with that?

**직원**  
KO: 네, 바코드를 여기 보여 주세요.  
DE: Ja, zeigen Sie den Barcode bitte hier.  
EN: Yes, show the barcode here.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 13. 택배가 옆집 앞에 놓였을 때 (`package_wrong_door`)

- 수행 목표: 배송 위치 문제를 설명하고 물건을 확인할 수 있다
- 관계·사건: 처음 대화하는 이웃과 크리스티안 / 배송 사진 속 문이 옆집이라 크리스티안이 조심스럽게 확인한다
- 단원: `a2_05_delivery_services`

**이웃**  
KO: 네, 무슨 일이세요?  
DE: Ja, was gibt es?  
EN: Hi, what is it?

**크리스티안 (나)**  
KO: 제 택배가 여기 온 것 같아요.  
DE: Ich glaube, mein Paket wurde hier abgestellt.  
EN: I think my package was left here.

**이웃**  
KO: 아, 문 앞에 있던 상자요?  
DE: Ach, das Paket vor der Tür?  
EN: Oh, the box that was by the door?

**크리스티안 (나)**  
KO: 네. 상자에 제 이름이 적혀 있어요.  
DE: Ja. Mein Name steht auf dem Etikett.  
EN: Yes. My name is on the label.

**이웃**  
KO: 크리스티안 맞네요. 여기 있어요.  
DE: Da steht Christian. Hier bitte.  
EN: It says Christian. Here you go.

**크리스티안 (나)**  
KO: 확인해 주셔서 감사합니다.  
DE: Danke fürs Nachsehen.  
EN: Thanks for checking.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 14. 약국에서 감기 증상 말하기 (`pharmacy_cold_medicine`)

- 수행 목표: 익숙한 증상과 약 복용 시간을 확인할 수 있다
- 관계·사건: 손님과 약사 / 크리스티안이 목이 아프고 기침이 난다고 말한다
- 단원: `a2_04_feelings_health`

**약사**  
KO: 어디가 불편하세요?  
DE: Was fehlt Ihnen?  
EN: What symptoms do you have?

**크리스티안 (나)**  
KO: 어제부터 목이 아파요.  
DE: Seit gestern tut mir der Hals weh.  
EN: My throat has hurt since yesterday.

**크리스티안 (나)**  
KO: 기침도 조금 나요.  
DE: Ich habe auch ein bisschen Husten.  
EN: I have a slight cough too.

**약사**  
KO: 이 약을 먹으면 졸릴 수 있어요.  
DE: Dieses Medikament kann müde machen.  
EN: This medicine may make you drowsy.

**크리스티안 (나)**  
KO: 그럼 저녁에 먹어도 돼요?  
DE: Kann ich es dann abends nehmen?  
EN: Can I take it in the evening, then?

**약사**  
KO: 네. 식사 후에 드세요.  
DE: Ja. Nehmen Sie es nach dem Essen.  
EN: Yes. Take it after a meal.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 15. 주말에 전시 보러 가기 (`plans_with_friend`)

- 수행 목표: 제안하고 한 가지 이유를 들은 뒤 계획을 바꿀 수 있다
- 관계·사건: 친구가 된 크리스티안과 수진 / 크리스티안이 주말 전시를 제안하지만 수진은 토요일에 일이 있다
- 단원: `a2_02_plans_proposals`

**크리스티안 (나)**  
KO: 토요일에 이 전시 보러 갈래요?  
DE: Möchtest du am Samstag diese Ausstellung sehen?  
EN: Do you want to see this exhibition on Saturday?

**수진**  
KO: 토요일에는 일이 있어서 안 돼요.  
DE: Am Samstag muss ich arbeiten, da geht es nicht.  
EN: I have work on Saturday, so I can't.

**크리스티안 (나)**  
KO: 그럼 일요일은 어때요?  
DE: Wie wäre es dann mit Sonntag?  
EN: How about Sunday, then?

**수진**  
KO: 일요일 오후는 괜찮아요.  
DE: Sonntagnachmittag passt.  
EN: Sunday afternoon works.

**크리스티안 (나)**  
KO: 두 시에 만날까요?  
DE: Treffen wir uns um zwei?  
EN: Shall we meet at two?

**수진**  
KO: 좋아요. 입구 앞에서 봐요.  
DE: Gern. Wir treffen uns am Eingang.  
EN: Sounds good. See you by the entrance.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 16. 늦는다고 카카오톡 보내기 (`running_late`)

- 수행 목표: 늦는 이유와 예상 도착 시간을 간단히 알릴 수 있다
- 관계·사건: 친한 레나와 마야 / 지하철이 잠깐 멈춰 레나가 약속에 늦게 된다
- 단원: `a2_03_chat_relationships`

**레나 (나)**  
KO: 지하철이 늦어서 십 분쯤 늦을 것 같아.  
DE: Die U-Bahn hat Verspätung. Ich komme wohl etwa zehn Minuten später.  
EN: The subway is delayed. I think I'll be about ten minutes late.

**마야**  
KO: 괜찮아. 나도 아직 가는 중이야.  
DE: Kein Problem. Ich bin auch noch unterwegs.  
EN: No problem. I'm still on my way too.

**레나 (나)**  
KO: 너도 늦어?  
DE: Kommst du auch später?  
EN: Are you running late too?

**마야**  
KO: 아니, 나도 방금 버스에서 내렸어.  
DE: Nein, ich bin auch gerade erst aus dem Bus gestiegen.  
EN: No, I just got off the bus too.

**레나 (나)**  
KO: 그럼 카페 앞에서 만나자.  
DE: Dann treffen wir uns vor dem Café.  
EN: Then let's meet in front of the café.

**마야**  
KO: 응. 천천히 와.  
DE: Ja. Kein Stress.  
EN: Okay. Take your time.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 17. 삼겹살집에서 굽는 순서 묻기 (`samgyeopsal_first_time`)

- 수행 목표: 익숙한 음식 자리에서 방법과 선호를 물을 수 있다
- 관계·사건: 친구 크리스티안과 수진 / 크리스티안이 처음 직접 고기를 구우며 언제 먹어도 되는지 묻는다
- 단원: `a2_01_haeyo_transition`

**크리스티안 (나)**  
KO: 이제 먹어도 돼요?  
DE: Kann man das jetzt schon essen?  
EN: Can we eat it now?

**수진**  
KO: 조금만 더 구워야 돼요. 여기 아직 빨개요.  
DE: Es muss noch ein bisschen länger grillen. Hier ist es noch rot.  
EN: It needs a little longer. It's still red here.

**크리스티안 (나)**  
KO: 이쪽은 괜찮아요?  
DE: Ist dieses Stück fertig?  
EN: Is this side okay?

**수진**  
KO: 네, 이건 먹어도 돼요.  
DE: Ja, das kannst du essen.  
EN: Yes, this one is ready.

**크리스티안 (나)**  
KO: 마늘도 불판에 올릴까요?  
DE: Sollen wir auch Knoblauch auf den Grill legen?  
EN: Shall we put garlic on the grill too?

**수진**  
KO: 저는 생마늘이 좋아요. 반만 구워요.  
DE: Ich mag Knoblauch roh. Grillen wir nur die Hälfte.  
EN: I like raw garlic. Let's grill only half.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 18. 공유 문서의 예전 버전을 고쳤을 때 (`shared_document_old_version`)

- 수행 목표: 잘못된 파일을 사용한 이유와 다음 행동을 말할 수 있다
- 관계·사건: 조별 과제 동료 크리스티안과 레나 / 크리스티안이 공유 문서가 아닌 내려받은 예전 파일을 수정한다
- 단원: `a2_06_study_work`

**크리스티안 (나)**  
KO: 레나, 나 예전 파일을 고쳤어.  
DE: Lena, ich habe die alte Datei bearbeitet.  
EN: Lena, I edited the old file.

**레나**  
KO: 공유 문서가 아니었어?  
DE: Nicht das gemeinsame Dokument?  
EN: Not the shared document?

**크리스티안 (나)**  
KO: 응. 어제 내려받아서 몰랐어.  
DE: Nein. Ich hatte sie gestern heruntergeladen und es nicht bemerkt.  
EN: No. I downloaded it yesterday and didn't realize.

**레나**  
KO: 고친 부분을 복사할 수 있어?  
DE: Kannst du deine Änderungen kopieren?  
EN: Can you copy your changes over?

**크리스티안 (나)**  
KO: 응, 지금 공유 문서로 옮길게.  
DE: Ja, ich übertrage sie jetzt ins gemeinsame Dokument.  
EN: Yes, I'll move them into the shared document now.

**레나**  
KO: 다음부터는 수정하기 전에 공유 문서인지 먼저 확인하자.  
DE: Nächstes Mal prüfen wir vor dem Bearbeiten zuerst, ob es das geteilte Dokument ist.  
EN: Next time, let's check that it's the shared document before editing.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 19. 택시가 무서울 만큼 빠를 때 (`taxi_slow_down`)

- 수행 목표: 불편하거나 불안할 때 공손하게 행동 변화를 요청할 수 있다
- 관계·사건: 승객과 택시 기사 / 차선 변경이 빠르게 이어져 레나가 불안함을 느낀다
- 단원: `a2_07_travel_repair`

**레나 (나)**  
KO: 기사님, 천천히 좀 가 주실 수 있을까요?  
DE: Könnten Sie bitte etwas langsamer fahren?  
EN: Could you please drive a little more slowly?

**기사**  
KO: 아, 네. 죄송합니다.  
DE: Oh, ja. Entschuldigung.  
EN: Oh, yes. Sorry.

**레나 (나)**  
KO: 차선을 자주 바꿔서 조금 무서워요.  
DE: Die vielen Spurwechsel machen mir etwas Angst.  
EN: The frequent lane changes are making me a little nervous.

**기사**  
KO: 알겠습니다. 천천히 갈게요.  
DE: Verstanden. Ich fahre langsamer.  
EN: Understood. I'll slow down.

**레나 (나)**  
KO: 네, 부탁드릴게요.  
DE: Ja, bitte.  
EN: Yes, please.

**기사**  
KO: 네.  
DE: Natürlich.  
EN: Of course.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:

## 20. 기차 좌석을 잘못 앉았을 때 (`train_seat_swap`)

- 수행 목표: 자리 착오를 확인하고 사과하며 옮길 수 있다
- 관계·사건: 서로 모르는 승객과 다니엘 / 다니엘이 좌석 번호를 한 칸 잘못 보고 다른 사람 자리에 앉는다
- 단원: `a2_07_travel_repair`

**손님**  
KO: 죄송한데, 여기 제 자리예요.  
DE: Entschuldigung, das ist mein Platz.  
EN: Excuse me, this is my seat.

**다니엘 (나)**  
KO: 아, 제가 좌석 번호를 잘못 봤어요.  
DE: Oh, ich habe die Sitznummer falsch gelesen.  
EN: Oh, I misread the seat number.

**손님**  
KO: 표에 몇 번이라고 되어 있어요?  
DE: Welche Nummer steht auf Ihrer Fahrkarte?  
EN: What number does your ticket show?

**다니엘 (나)**  
KO: 12A예요. 여기는 12B네요.  
DE: 12A. Das hier ist 12B.  
EN: 12A. This is 12B.

**손님**  
KO: A는 창가 쪽이에요.  
DE: A ist am Fenster.  
EN: A is the window seat.

**다니엘 (나)**  
KO: 알려 주셔서 감사합니다. 바로 옮길게요.  
DE: Danke für den Hinweis. Ich setze mich sofort um.  
EN: Thanks for letting me know. I'll move right away.

검토: [ ] 한국어 자연성  [ ] 레벨 내용 범위  [ ] DE  [ ] EN  [ ] 퀘스트  [ ] 문화 노트

Jin 메모:
