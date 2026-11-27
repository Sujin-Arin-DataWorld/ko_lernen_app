# 자연성 검수 W1 · A2 어휘 — Jin 표본 (2026-11-27)

A2 기존 어휘 455행 전수 판정(최근 검수·승인된 배치 32~34·42·45의 336행은 제외). 변경 110행, 이 중 **18행**을 표본으로 싣는다 (Opus 직접 수정 3행 전부 + 무작위 15행, 시드 20261127).

원장: `docs/data/naturalness_v2/W1_A2_final.csv` · 미러 로그: `W1_A2_mirror_log.csv` · 레벨 이동 제안: `W1_A2_relevel_proposals.csv`.

**판정 규칙**: A2 문법 상한(2급) 초과 제거(-다니·오늘따라·-냐고/-지 말라고 간접 인용 → 직접형), 2어절 예문은 3어절로(문장 조립 계약), DE/EN 이중 성별·우회 표현 제거, 번역쌍 R3/R4 통과, 뜻풀이는 이번에 바꾸지 않음.

사용법: 각 항목 ✍️ 칸에 ✅ 또는 원하는 문장. "검수 끝"이라고 알려주면 반영.

## 1. `vocab_a2_0233` — 가수 · Opus 직접 수정
- example_german: Diese Person singt wirklich gut.  
  → **Die Lieder von diesem Sänger gefallen mir sehr.**
- example_english: That person sings really well.  
  → **I really like that singer's songs.**
- 이유: Opus 직접 수정 / DE/EN이 가수·노래를 잃은 오역
- ✍️ 

## 2. `vocab_a2_0270` — 한국어 잘하시네요 · Opus 직접 수정
- example_korean: 한국어 잘하시네요 소리를 들으니 오히려 더 긴장됐어요.  
  → **한국어 잘하시네요! 어디에서 배웠어요?**
- example_german: Das Lob für mein Koreanisch machte mich eher noch nervöser.  
  → **Sie sprechen aber gut Koreanisch! Wo haben Sie es gelernt?**
- example_english: Hearing that my Korean is good made me even more nervous.  
  → **Your Korean is really good! Where did you learn it?**
- 이유: Opus 직접 수정 / 구두점 없는 비문·7어절
- ✍️ 

## 3. `vocab_a1_0367` — 준비됐나요 · Opus 직접 수정
- example_korean: 수업 시작 전에 준비됐나요?  
  → **곧 수업이 시작돼요. 준비됐나요?**
- example_german: Sind Sie bereit, bevor der Unterricht beginnt?  
  → **Der Unterricht fängt gleich an. Seid ihr bereit?**
- example_english: Are you ready before class starts?  
  → **Class is about to start. Are you ready?**
- 이유: Opus 직접 수정 / 원문 "수업 시작 전에 준비됐나요?"가 어색, DE도 직역
- ✍️ 

## 4. `vocab_a1_0305` — 안부
- example_korean: 다음 날 안부를 짧게 물었어요.  
  → **다음 날 할머니께 안부 전화를 드렸어요.**
- example_german: Am nächsten Tag fragte ich kurz nach ihrem Befinden.  
  → **Am nächsten Tag habe ich bei meiner Großmutter angerufen und gefragt, wie es ihr geht.**
- example_english: The next day I asked briefly how they were doing.  
  → **The next day, I called my grandmother to see how she was doing.**
- 이유: DE "ihrem Befinden" 대상 불명(N5); 안부 전화 연어로 교체
- ✍️ 

## 5. `vocab_a1_0362` — 준비물
- example_german: Ich packe die Sachen für den Unterricht in die Tasche.  
  → **Ich packe die Sachen für den morgigen Unterricht in die Tasche.**
- example_english: I'm putting what I need for class in my bag.  
  → **I'm putting what I need for tomorrow's class in my bag.**
- 이유: 내일 누락
- ✍️ 

## 6. `vocab_a1_0382` — 일기예보
- example_german: Ich schaue den Wetterbericht und wähle die Kleidung.  
  → **Ich schaue den Wetterbericht an und wähle Kleidung.**
- 이유: DE 'wähle die Kleidung' hölzern.
- ✍️ 

## 7. `vocab_a1_0385` — 두꺼운 옷
- example_german: Nachts trug ich dicke Kleidung.  
  → **Nachts habe ich dicke Kleidung angezogen.**
- 이유: Präteritum im Gespräch; Perfekt.
- ✍️ 

## 8. `vocab_a2_0033` — 열쇠
- example_korean: 열쇠를 잃어버렸어요.  
  → **집 열쇠를 잃어버렸어요.**
- example_german: Ich habe den Schlüssel verloren.  
  → **Ich habe meinen Hausschlüssel verloren.**
- example_english: I lost the key.  
  → **I lost my house key.**
- 이유: 2어절이라 3어절로 확장
- ✍️ 

## 9. `vocab_a2_0062` — 피곤하다
- example_korean: 오늘따라 좀 피곤하네요.  
  → **오늘은 좀 피곤하네요.**
- example_german: Heute bin ich irgendwie etwas müde.  
  → **Heute bin ich ein bisschen müde.**
- example_english: For some reason I'm a bit tired today.  
  → **I'm a bit tired today.**
- 이유: 오늘따라는 A2 밖 표현
- ✍️ 

## 10. `vocab_a2_0115` — 놀라다
- example_korean: 깜짝 놀랐어요!  
  → **큰 소리에 깜짝 놀랐어요!**
- example_german: Ich bin total erschrocken!  
  → **Von dem lauten Geräusch bin ich total erschrocken!**
- example_english: I was so startled!  
  → **The loud noise really startled me!**
- 이유: 2어절이라 3어절로 확장
- ✍️ 

## 11. `vocab_a2_0116` — 기쁘다
- example_korean: 합격했다니 정말 기뻐요.  
  → **시험에 합격해서 정말 기뻐요.**
- example_german: Ich freue mich wirklich, dass Sie bestanden haben.  
  → **Ich bin so froh, dass ich die Prüfung bestanden habe.**
- example_english: I'm so happy to hear you passed.  
  → **I'm so happy that I passed the exam.**
- 이유: -다니는 A2 문법 초과
- ✍️ 

## 12. `vocab_a2_0200` — 칫솔
- example_german: Ich habe eine neue Zahnbürste genommen.  
  → **Ich habe auf eine neue Zahnbürste gewechselt.**
- 이유: 바꿨다=전환의 뜻
- ✍️ 

## 13. `vocab_a2_0289` — 명절 음식
- example_german: Für die Feiertage bereitete ich Jeon zu.  
  → **Als Festtagsessen habe ich Jeon zubereitet.**
- 이유: DE Präteritum "bereitete" 문어체
- ✍️ 

## 14. `vocab_a2_0321` — 일찍 일어나다
- example_korean: 일찍 일어나려고 알람을 네 개 맞췄어요.  
  → **일찍 일어나야 해서 알람을 네 개 맞췄어요.**
- example_german: Um früh aufzustehen, stellte ich vier Wecker.  
  → **Ich muss früh aufstehen, deshalb habe ich vier Wecker gestellt.**
- example_english: I set four alarms to get up early.  
  → **I have to get up early, so I set four alarms.**
- 이유: -(으)려고는 A2 문법표 밖; -어야 해서로 교체
- ✍️ 

## 15. `vocab_a2_0327` — 문 닫기
- example_korean: 문 닫기 소리가 너무 커서 저도 깜짝 놀랐어요.  
  → **문 닫기 전에 가방을 한 번 확인했어요.**
- example_german: Die Tür fiel so laut zu, dass ich selbst erschrak.  
  → **Bevor ich die Tür geschlossen habe, habe ich noch einmal meine Tasche kontrolliert.**
- example_english: The door shut so loudly that I startled myself.  
  → **Before closing the door, I checked my bag once more.**
- 이유: "문 닫기 소리"는 부자연스럽고 대표 용법도 아님; -기 전에 용법으로 교체
- ✍️ 

## 16. `vocab_a2_0345` — 짐 부치다
- example_korean: 기차를 타기 전에 큰 짐을 택배로 부쳤어요.  
  → **큰 짐은 택배로 미리 부쳤어요.**
- example_german: Vor der Zugfahrt schickte ich mein großes Gepäck per Paketdienst voraus.  
  → **Das große Gepäck habe ich vorab per Paketdienst geschickt.**
- example_english: Before taking the train, I sent my large bag ahead by courier.  
  → **I sent my big bags ahead by courier.**
- 이유: 7어절 초과로 단축
- ✍️ 

## 17. `vocab_a2_0346` — 도착 연락
- example_korean: 역에 도착해서 가족에게 도착 연락을 했어요.  
  → **역에 내려서 가족에게 도착 연락을 했어요.**
- example_german: Nach meiner Ankunft am Bahnhof gab ich meiner Familie Bescheid.  
  → **Nach dem Aussteigen am Bahnhof habe ich meiner Familie Bescheid gegeben, dass ich angekommen bin.**
- example_english: When I arrived at the station, I let my family know.  
  → **After getting off at the station, I let my family know I had arrived.**
- 이유: 도착해서 도착 연락 중복
- ✍️ 

## 18. `vocab_a2_0390` — 운동복
- example_korean: 운동복을 락커에 넣어 두어요.  
  → **운동복을 락커에 넣어 둬요.**
- 이유: 구어는 두어요보다 둬요; 락커 등급 미확인
- ✍️ 

## 반려한 검수 제안 (원문 유지)

- `vocab_a2_0029` 문자: SMS-Antwort 어색, 원래 번역 자연스러움 — 원문 유지
- `vocab_a1_0274` 송편 빚다: 새 문장의 cloze 정답(빚었는데) 품사를 감사기가 판정 못해 D3 위반 — A2 문법 안의 원문 유지
- `vocab_a1_0278` 송편 찌다: 새 문장에 표제어 어간이 빠져 번역쌍 R3 위반 — 원문 유지
- `vocab_a2_0294` 송편 맛: 새 문장(송편 맛은 깨가 제일 좋아요)이 원문보다 어색 — 원문 유지
- `vocab_a2_0056` 걷다: 30분은 TTS가 바르게 읽고 학습자에게 숫자 표기가 필요 — 원문 유지

## Jin 판단 필요: 레벨 이동 제안 (이번 PR에서는 이동하지 않음)

A2는 3급까지 허용. 아래는 NIKL 4급 이상이라 검수자가 상향 이동을 제안한 표제어다. 이동하려면 `relevel_vocab.py`와 그 게이트(목표 레벨 문장 재검)를 별도 PR로 거쳐야 한다.

- `vocab_a2_0096` 매콤하다 (NIKL 5급): NIKL 5급; B2 권장
- `vocab_a2_0218` 땅콩 (NIKL 4급): NIKL 4급; B1 권장
- `vocab_a2_0399` 근력 (NIKL 6급): nikl 6급: B2 권장. 문장은 자연스러움
- `vocab_a2_0400` 유산소 (NIKL 4급): nikl 4급: B1 권장. 예문 숨이 고르게 돌아와요도 어색
- `vocab_a2_0348` 마을 버스 (NIKL 4급): nikl 4급: B1 권장
- `vocab_a2_0350` 밤참 (NIKL 6급): nikl 6급: B2 권장
- `vocab_a1_0239` 윗목 (NIKL 6급): nikl 6급: B2 권장. DE 윗목 설명도 불명확
- `vocab_a1_0240` 아랫목 (NIKL 6급): nikl 6급: B2 권장
- `vocab_a2_0319` 세면 도구 (NIKL 5급): nikl 5급: B2 권장. Bürste는 칫솔 누락
- `vocab_a1_0306` 사진 전송 (NIKL 5급): nikl 5급; 제안 B2 (예문 7어절도 A2 밴드 초과)
- `vocab_a2_0243` 왕자 (NIKL 5급): nikl 5급; 제안 B2
- `vocab_a1_0324` 일회용 밴드 (NIKL 4급): nikl 4급; 제안 B1
- `vocab_a1_0329` 무처방 (NIKL 4급): nikl 4급; 제안 B1. 실제론 "처방전 없이/일반의약품"이 자연스러움
- `vocab_a2_0464` 만날 곳을 정하다 (NIKL 5급): nikl 5급 표기, 구성 어휘(만나다·곳·정하다)는 모두 저등급이라 등급 데이터 재확인 권고
- `vocab_a2_0403` 염색 (NIKL 4급): nikl 4급; 제안 B1
- `vocab_a2_0412` 손질 (NIKL 4급): nikl 4급; 제안 B1
- `vocab_a1_0366` 필기하다 (NIKL 4급): nikl 4급; 제안 B1

- ✍️ 이동할 것 / 그대로 둘 것:

