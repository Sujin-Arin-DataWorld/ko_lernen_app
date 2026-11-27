# 자연성 검수 W1 · A1 어휘 — Jin 표본 (2026-11-25)

A1 어휘 735행 전수 판정 완료. 변경 173행(예문·번역·뜻풀이), 이 중 **31행**을 표본으로 싣는다 (Opus 직접 수정 11행 전부 + 무작위 20행, 시드 20261125).

전체 판정 원장: `docs/data/naturalness_v2/W1_A1_final.csv` · cloze/satz 동기 로그: `W1_A1_mirror_log.csv`.

**판정 규칙 요약**: 불필요한 "저는" 삭제 · DE/EN 이중 성별 표기 → 자연스러운 한 형태(D1) · 2급 표제어는 A1 유지(검증기 +1 허용), 이동은 3급 이상만 · 숫자 "이"는 TTS가 지시어로 읽을 수 있어 피함 · 한국 1층 = Erdgeschoss(문화 등가) · 문장 조립 게임 3어절 계약 때문에 2어절로 줄어든 예문 18개는 시간·장소를 더해 3~4어절로.

사용법: 각 항목 ✍️ 칸에 ✅ 또는 원하는 문장. "검수 끝"이라고 알려주면 반영.

## 1. `vocab_a1_0130` — 일 · Opus 직접 수정
- example_german: Ich gehe in die erste Etage.  
  → **Ich gehe ins Erdgeschoss.**
- 이유: Opus 직접 수정 / 레벨 유지(2급은 A1 허용, 이동은 3급 이상·구 표제어 제외) / 층 번호 체계: 한국 1층=Erdgeschoss, 2층=1. Stock. 독일어를 리터럴(erste Etage)로 둘지 문화 등가로 바꿀지 결정 필요; 일/이/육/육십 4건 일괄. 추천: 층 예
- ✍️ 

## 2. `vocab_a1_0131` — 이 · Opus 직접 수정
- example_german: Es ist im zweiten Stock.  
  → **Es ist im ersten Stock.**
- 이유: Opus 직접 수정 / 레벨 유지(2급은 A1 허용, 이동은 3급 이상·구 표제어 제외) / 층 번호 체계: 한국 1층=Erdgeschoss, 2층=1. Stock. 독일어를 리터럴(erste Etage)로 둘지 문화 등가로 바꿀지 결정 필요; 일/이/육/육십 4건 일괄. 추천: 층 예
- ✍️ 

## 3. `vocab_a1_0135` — 육 · Opus 직접 수정
- example_korean: 저는 육 층에 살아요.  
  → **한국에서 육 년 살았어요.**
- example_german: Ich wohne im sechsten Stock.  
  → **Ich habe sechs Jahre in Korea gelebt.**
- example_english: I live on the sixth floor.  
  → **I lived in Korea for six years.**
- 이유: Opus 직접 수정 / 레벨 유지(2급은 A1 허용, 이동은 3급 이상·구 표제어 제외) / 층 번호 체계: 한국 1층=Erdgeschoss, 2층=1. Stock. 독일어를 리터럴(erste Etage)로 둘지 문화 등가로 바꿀지 결정 필요; 일/이/육/육십 4건 일괄. 추천: 층 예
- ✍️ 

## 4. `vocab_a1_0138` — 구 · Opus 직접 수정
- example_korean: 새 학기가 구월에 시작해요.  
  → **버스가 구 분 후에 와요.**
- example_german: Das neue Semester fängt im September an.  
  → **Der Bus kommt in neun Minuten.**
- example_english: The new semester starts in September.  
  → **The bus comes in nine minutes.**
- 이유: Opus 직접 수정 / 학기는 2급 가능성 -> 1급 어휘로 교체
- ✍️ 

## 5. `vocab_a1_0223` — 댁에 · Opus 직접 수정
- example_korean: 댁에 처음 와서 신발을 여기에 뒀어요.  
  → **할머니 댁에 가요.**
- example_german: Ich bin zum ersten Mal bei Ihnen zu Hause und habe die Schuhe hier hingestellt.  
  → **Ich fahre zu meiner Oma.**
- example_english: I came to your home for the first time and put my shoes here.  
  → **I'm going to my grandma's place.**
- 이유: Opus 직접 수정 / 레벨 유지(2급은 A1 허용, 이동은 3급 이상·구 표제어 제외) / nikl_grade 2 -> A2 권장; 예문도 6어절로 A1 초과
- ✍️ 

## 6. `vocab_a1_0258` — 수저 놓다 · Opus 직접 수정
- example_german: Ich lege Löffel und Stäbchen hin.  
  → **Ich lege Löffel und Stäbchen auf den Tisch.**
- example_english: I put down my spoon and chopsticks.  
  → **I set out the spoons and chopsticks.**
- german: das Besteck ablegen  
  → **den Tisch decken (Löffel und Stäbchen hinlegen)**
- english: to put utensils down  
  → **to set the table (spoons and chopsticks)**
- 이유: Opus 직접 수정 / 수저 놓다=상차림; 이전 번역은 식후 내려놓기로 오해. 뜻풀이 변경은 단어관계 시드에 영향
- ✍️ 

## 7. `vocab_a1_0519` — 육십 · Opus 직접 수정
- example_korean: 제 방은 육십 층에 있어요.  
  → **한 시간은 육십 분이에요.**
- example_german: Mein Zimmer ist im sechzigsten Stock.  
  → **Eine Stunde hat sechzig Minuten.**
- example_english: My room is on the sixtieth floor.  
  → **An hour has sixty minutes.**
- 이유: Opus 직접 수정 / 레벨 유지(2급은 A1 허용, 이동은 3급 이상·구 표제어 제외) / 층 번호 체계: 한국 1층=Erdgeschoss, 2층=1. Stock. 독일어를 리터럴(erste Etage)로 둘지 문화 등가로 바꿀지 결정 필요; 일/이/육/육십 4건 일괄. 추천: 층 예
- ✍️ 

## 8. `vocab_a1_0606` — 아파트 · Opus 직접 수정
- example_korean: 이 아파트에 몇 명이 살아요?  
  → **친구는 아파트에 살아요.**
- example_german: Wie viele Leute wohnen in dieser Wohnung?  
  → **Mein Freund wohnt in einer Wohnung.**
- example_english: How many people live in this apartment?  
  → **My friend lives in an apartment.**
- 이유: Opus 직접 수정 / 몇 명이 살아요는 부자연. 아파트=Wohnung 뜻풀이 부정확하나 시드 영향 고려해 gloss 유지
- ✍️ 

## 9. `vocab_a1_0698` — 교통 · Opus 직접 수정
- example_german: Ich habe keine Verkehrskarte.  
  → **Ich habe keine Karte für Bus und Bahn.**
- 이유: Opus 직접 수정 / Verkehrskarte는 비실재 단어
- ✍️ 

## 10. `vocab_a1_0772` — 영 · Opus 직접 수정
- example_korean: 사과가 영 개 있어요.  
  → **오늘은 영 도예요.**
- example_german: Es gibt null Äpfel.  
  → **Heute sind es null Grad.**
- example_english: There are zero apples.  
  → **It's zero degrees today.**
- 이유: Opus 직접 수정 / 사과가 영 개 있어요는 비실재 문장; 전화번호 읽기로 교체
- ✍️ 

## 11. `vocab_a1_0775` — 주일 · Opus 직접 수정
- example_korean: 이번 주일에 가족을 만나요.  
  → **한 주일 동안 여행해요.**
- example_german: Ich treffe meine Familie diesen Sonntag.  
  → **Ich reise eine Woche lang.**
- example_english: I see my family this Sunday.  
  → **I'm traveling for a week.**
- german: Sonntag  
  → **Woche**
- english: Sunday  
  → **week**
- 이유: Opus 직접 수정 / 주일은 대표 의미가 week(이번 주일), Sunday는 기독교 용례; gloss·예문 번역 수정(시드 영향, Jin 확인 권장)
- ✍️ 

## 12. `vocab_a1_0195` — 거기
- example_korean: 거기 가 본 적 있어요.  
  → **책이 거기 있어요.**
- example_german: Da war ich schon mal.  
  → **Das Buch ist da.**
- example_english: I've been there before.  
  → **The book is there.**
- 이유: 본 적 있다는 A1 문법 밖
- ✍️ 

## 13. `vocab_a1_0261` — 세배
- example_korean: 세배를 해요.  
  → **설날에 할아버지께 세배를 해요.**
- example_german: Ich verbeuge mich zum Neujahrsfest.  
  → **An Seollal mache ich vor meinem Opa die Neujahrsverbeugung.**
- example_english: I give a New Year's bow.  
  → **At Seollal, I do the New Year's bow to my grandfather.**
- 이유: 세배는 어른께 하는 절 -> 대상 명시
- ✍️ 

## 14. `vocab_a1_0309` — 소포
- example_english: I want to send this parcel to Germany.  
  → **I want to send this package to Germany.**
- 이유: 미국식 package
- ✍️ 

## 15. `vocab_a1_0429` — 독일
- example_korean: 독일에서 한국에 와요.  
  → **독일에서 왔어요.**
- example_german: Ich komme aus Deutschland nach Korea.  
  → **Ich komme aus Deutschland.**
- example_english: I come to Korea from Germany.  
  → **I'm from Germany.**
- 이유: 독일에서 한국에 와요 맥락 불명 -> 출신 표현
- ✍️ 

## 16. `vocab_a1_0431` — 외국인
- example_german: Ich komme aus einem anderen Land.  
  → **Ich bin Ausländer.**
- example_english: I'm from another country.  
  → **I'm a foreigner.**
- german: Person aus einem anderen Land  
  → **Ausländer**
- english: person from another country  
  → **foreigner**
- 이유: 외국인=Ausländer; 예문 DE이 오역(다른 나라 출신 설명) -> 단순화. gloss 변경은 단어망 시드 영향. 성별 이슈는 Jin 확인 권장
- ✍️ 

## 17. `vocab_a1_0460` — 주부
- german: Hausfrau/Hausmann  
  → **Hausfrau, Hausmann**
- 이유: Hausfrau/Hausmann 슬래시 정리. 시드 영향
- ✍️ 

## 18. `vocab_a1_0476` — 바로
- example_korean: 저는 지금 바로 가요.  
  → **지금 바로 가요.**
- 이유: 불필요한 저는 제거
- ✍️ 

## 19. `vocab_a1_0494` — 안경
- example_korean: 저는 안경을 써요.  
  → **책을 볼 때 안경을 써요.**
- example_german: Ich trage eine Brille.  
  → **Beim Lesen trage ich eine Brille.**
- example_english: I wear glasses.  
  → **I wear glasses when I read.**
- 이유: 불필요한 저는 삭제
- ✍️ 

## 20. `vocab_a1_0512` — 고르다
- example_korean: 저는 이 옷을 골랐어요.  
  → **이 옷을 골랐어요.**
- example_german: Ich habe diese Kleidung ausgewählt.  
  → **Ich habe mir diese Sachen ausgesucht.**
- example_english: I chose these clothes.  
  → **I picked out these clothes.**
- 이유: 저는 삭제, 독일어 Kleidung 직역 완화
- ✍️ 

## 21. `vocab_a1_0533` — 오월
- example_korean: 음... 제 생일이 오월이에요.  
  → **오월은 날씨가 좋아요.**
- example_german: Ähm... mein Geburtstag ist im Mai.  
  → **Im Mai ist das Wetter schön.**
- example_english: Um... my birthday is in May.  
  → **The weather is nice in May.**
- 이유: 음... 말줄임 TTS 위험, 일월 예문과 중복
- ✍️ 

## 22. `vocab_a1_0563` — 구경
- example_korean: 이번 주말에 구경 가요.  
  → **같이 서울 구경 갈까요?**
- example_german: Lass uns dieses Wochenende bummeln gehen.  
  → **Sollen wir zusammen Seoul besichtigen?**
- example_english: Let's go sightseeing this weekend.  
  → **Shall we go sightseeing in Seoul together?**
- 이유: 구경 가요 의미 모호·bummeln은 Besichtigung과 불일치; 서울 구경으로 구체화
- ✍️ 

## 23. `vocab_a1_0599` — 잔
- example_english: I drink water from this cup.  
  → **I drink water from this glass.**
- 이유: DE Glas와 EN cup 불일치
- ✍️ 

## 24. `vocab_a1_0626` — 하루
- example_german: Ich bin heute wirklich müde.  
  → **Ich bin heute den ganzen Tag wirklich müde.**
- example_english: I am really tired today.  
  → **I've been really tired all day today.**
- 이유: 하루 의미 누락
- ✍️ 

## 25. `vocab_a1_0705` — 동생
- example_german: Mein jüngeres Geschwister ist neun Jahre alt.  
  → **Mein kleiner Bruder ist neun Jahre alt.**
- example_english: My younger sibling is nine years old.  
  → **My little brother is nine years old.**
- 이유: D1 jüngeres Geschwister/sibling 우회 제거; gloss는 일반 의미로 유지
- ✍️ 

## 26. `vocab_a1_0723` — 시키다
- example_korean: 저는 커피를 시켜요.  
  → **카페에서 커피를 시켜요.**
- example_german: Ich bestelle einen Kaffee.  
  → **Im Café bestelle ich einen Kaffee.**
- example_english: I order a coffee.  
  → **I order a coffee at the café.**
- 이유: 불필요한 저는 제거
- ✍️ 

## 27. `vocab_a1_0759` — 아니다
- example_german: Ich bin kein Student / keine Studentin.  
  → **Ich bin kein Student.**
- example_english: I am not a student.  
  → **I'm not a student.**
- german: nicht Student/in sein  
  → **nicht sein**
- 이유: 슬래시 이중형 제거; 글로스 변경은 단어망 시드에 영향
- ✍️ 

## 28. `vocab_a1_0769` — 말
- example_korean: 저는 선생님 말을 잘 들어요.  
  → **선생님 말을 잘 들어요.**
- example_german: Ich höre der Lehrkraft gut zu.  
  → **Ich höre auf meinen Lehrer.**
- example_english: I listen carefully to the teacher.  
  → **I do what my teacher says.**
- 이유: 저는 삭제, Lehrkraft 우회표현 제거, 말을 듣다=시키는 대로 하다
- ✍️ 

## 29. `vocab_a1_0792` — 얼마나
- example_korean: 이 가방이 얼마나 비싸요?  
  → **학교까지 얼마나 걸려요?**
- example_german: Wie teuer ist diese Tasche?  
  → **Wie lange braucht man bis zur Schule?**
- example_english: How expensive is this bag?  
  → **How long does it take to get to school?**
- 이유: '가방이 얼마나 비싸요' 부자연; 얼마나 대표 용법. 글로스 wie sehr는 wie viel/lange 보강 검토
- ✍️ 

## 30. `vocab_a1_0818` — 살
- example_german: Mein jüngeres Geschwister ist drei Jahre alt.  
  → **Mein kleiner Bruder ist drei Jahre alt.**
- example_english: My younger sibling is three years old.  
  → **My little brother is three years old.**
- 이유: jüngeres Geschwister/younger sibling 우회 제거
- ✍️ 

## 31. `vocab_b2_0431` — 시댁
- example_german: Am Wochenende gehe ich zur Familie meines Mannes.  
  → **Am Wochenende fahre ich zu meinen Schwiegereltern.**
- example_english: I go to my husband's family on the weekend.  
  → **I'm going to my in-laws' place on the weekend.**
- 이유: Familie meines Mannes 우회 -> Schwiegereltern; id가 b2_이므로 레벨 대장 확인 권장
- ✍️ 

## 반려한 검수 제안 (원문 유지)

- `vocab_a1_0426` 출구 번호: Ausgangsnummer 자연스러움, 변경 불요
- `vocab_a1_0007` 괜찮아요: 저는 괜찮아요 = Mir geht es gut; 제안 DE는 의미 변경
- `vocab_a1_0122` 귀엽다: 강아지=Hund 일반 용법; Welpe 과잉
- `vocab_a1_0628` 개: 몇 마리 질문은 자연스러운 A1 문장
- `vocab_a1_0629` 고양이: 몇 마리 질문은 자연스러운 A1 문장
- `vocab_a1_0639` 여자: meine Freundin은 여자친구로 오독됨; eine Freundin von mir 유지

## Jin 판단 필요 (잠긴 문장)

- `vocab_a1_0266` 절하다: "설날에는 친척들이 모여 어른들에게 절을 하는 풍습이 있어요." — Jin이 직접 쓴 문장이라 `directive_content_lock_test`로 잠겨 있어 **원문 유지**. 다만 A1 길이 밴드(2–5어절)를 넘는 8어절이다. 제안: "설날에 할아버지께 절해요." (DE: An Seollal verbeuge ich mich vor meinem Opa.) 바꿀지 알려 주면 잠금 테스트와 함께 고친다.
- ✍️ 
