# 콘텐츠 자연성 심사 리포트 — 1차 (2026-08-26)

## 개요

프리필터(`tool/audit_content_naturalness.py`) 스캔 결과 총 **1,119건**의 후보가 8개
결정적 마커(정규식·문자열 포함·받침 유무 기반)로 잡혔다(`docs/data/naturalness_candidates.md`
"## 요약" 참조). 마커별 분포: `dangling_stem` 16 / `particle_mismatch` 834 /
`josa_dup` 36 / `formality_mix` 225 / `level_length` 8 (그 외 `passive_pileup`·
`e_daehae`·`answer_repeat`는 0건).

**1차 심사 범위**(이 리포트):

- `dangling_stem` 16건 — 전수
- `level_length` 8건 — 전수
- `josa_dup` 36건 — 전수
- `formality_mix` 225건 — 표본 30건(13.3%)

`particle_mismatch` 834건은 이번 1차 심사 범위에 포함하지 않는다 — 건수가 크고
결함 패턴이 기계적으로 재현 가능해 개별 LLM 심사보다 결정적 재생성 파이프라인이
효율적이라고 판단했다. 상세 제안은 아래 "particle_mismatch 834건 — 기계적 처리
제안" 참조.

입력 파일 5개(`nat-review-dangling-level.md`, `nat-review-josa-a.md`,
`nat-review-josa-b.md`, `nat-review-formality-a.md`, `nat-review-formality-b.md`)
모두 확인됨 — 누락 없음.

### 승인 → 반영 흐름

1. Jin이 아래 배치별 "승인 (Jin)" 체크박스로 배치 단위 승인.
2. 승인된 배치의 판정·최종안을 `patch.json`으로 변환.
3. `python tool/apply_naturalness_patch.py --patch <file>` 실행 — 원본 콘텐츠
   파일에 반영.
4. `flutter test test/cloze_content_guard_test.dart` 실행 — 회귀 확인.
5. `python tool/generate_tts.py` 재실행 — 변경된 KO/DE/EN 텍스트의 TTS 오디오
   재생성.

---

## 배치 A — dangling_stem·level_length

- [ ] 승인 (Jin)

`dangling_stem` 마커 자체("answer가 어간만 남은 형태")는 코퍼스의 의도된 설계다 —
B1~C2급 문법/연어 cloze는 문장에 어미(-니/-자/-지 않아도/-기 전에/-는 게)가 이미
박혀 있고 답은 그 앞에 붙는 어간이다. 따라서 이 마커의 "결함"은 대부분 오탐이며,
실제 심사는 (a) 완성 문장이 자연스러운가, (b) 오답 배분어가 해당 어미와 문법적으로
결합 가능한가(특히 자음어간+"니"는 "으" 연결모음이 없어 비문이 됨), (c) DE/EN
번역이 화행·격·어순을 보존하는가 세 가지로 진행했다.

### cloze.json — dangling_stem (16건)

| id | 파일 | 원문 | 판정 | 최종안(KO) | DE | EN | 코드/근거 |
|---|---|---|---|---|---|---|---|
| cloze_a2_0082 | cloze.json | 유창하지 않아도 천천히 말하면 통해요. (answer="유창하") | FP | | | | 어간+"지 않아도" 결합 정상, 완성 문장 자연스러움 |
| cloze_b1_0109 | cloze.json | 긴 이야기는 요약해서 전하니 핵심만 남았어요. (answer="요약해서 전하") | DEFECT-ITEM | 배분어 수정: "끼어들"→"끼어드", "다시 확인"→"다시 확인하" | | | ITEM — 두 배분어 모두 템플릿 "＿＿＿니"(연결모음 없음)와 결합 시 비문(끼어들니/다시 확인니) 생성. ㄹ탈락 미반영 + "하" 누락 |
| cloze_b1_0118 | cloze.json | 대충 하지 말라고 현우가 귓속말로 했어요. (answer="대충 하") | AWKWARD | 대충 하지 말라고 현우가 귓속말로 했어요. (KO 변경 없음) | Hyunwoo flüsterte mir zu, ich solle es nicht schludrig machen. | Hyunwoo whispered that I shouldn't do it carelessly. | PRAG, NAT — 기존 DE("Mach es nicht zu ungenau, flüsterte Hyunwoo.")가 KO의 간접 인용(-라고 했어요)을 직접 인용문으로 바꿔 화행/증거성 왜곡. EN은 간접형 유지, DE만 불일치 |
| cloze_b1_0119 | cloze.json | 쉬운 질문은 직접 대답하니 표정이 밝아졌어요. (answer="직접 대답하") | DEFECT-ITEM | 배분어 수정: "물로 받"→"물로 받으"(또는 모음어간 대체어) | | | ITEM — "받다"(자음어간 ㄷ)+"니"(연결모음 없음)="받니"는 비문. 이 어미대 정답은 전부 하다류(모음어간)인데 이 배분어만 자음어간 |
| cloze_b1_0126 | cloze.json | 취하기 전에 자리에서 일어나 물을 마셨어요. (answer="취하") | FP | | | | 어간+"기 전에" 결합 정상, 배분어 전부 호환 |
| cloze_b1_0131 | cloze.json | 취하신 분 옆에서는 자리 피하는 게 안전했어요. (answer="자리 피하") | FP | | | | 어간+"는 게" 결합 정상, 배분어 전부 모음어간으로 호환 |
| cloze_b1_0153 | cloze.json | 잠자리 경계 다시 정하니 둘이 편해졌어요. (answer="경계 다시 정하") | DEFECT-ITEM | 배분어 수정: "통역을 맡"→"통역을 맡으"(또는 모음어간 대체어) | | | ITEM — "맡다"(자음어간 ㅌ)+"니"="맡니"는 비문. "잠자리"는 맥락(파트너 가족 방문/취침 배정)상 자연스러움, 완곡어 오독 우려는 낮음 |
| cloze_b2_0264 | cloze.json | 관계부터 말하니 악수 타이밍이 맞았어요. (answer="관계부터 말하") | AWKWARD | 관계부터 말하니 악수 타이밍이 맞았어요. (KO 변경 없음) | Weil ich zuerst die Beziehung nannte, passte der Zeitpunkt für den Handschlag. | Naming the relationship first got the handshake timing right. | NAT — 기존 DE("...traf den Moment zum Handschlag")는 "Moment zum Handschlag" 연어가 부자연스러움 |
| cloze_c1_0064 | cloze.json | 자리를 재협상하자 다음 명절 표가 달라졌어요. (answer="자리를 재협상하") | FP | | | | 어간+"자" 결합 정상, 배분어 전부 호환, DE/EN 정확 |
| cloze_c1_0075 | cloze.json | 노동을 보이게 하자 감사의 대상이 달라졌어요. (answer="노동을 보이게 하") | DEFECT-ITEM | 배분어 수정: "다시 명명"→"다시 명명하" | | | ITEM — "하" 누락으로 동사 미완성, "다시 명명"+"자"="다시 명명자"는 비문 |
| cloze_c1_0076 | cloze.json | 공평을 설계하니 감정이 아니라 표가 남았어요. (answer="공평을 설계하") | AWKWARD | 공평을 설계하니 감정이 아니라 표가 남았어요. (KO 변경 없음) | Fairness zu entwerfen hinterließ eine Tabelle statt nur Gefühle. | Designing fairness left a chart, not only feelings. | NAT — 기존 DE의 "ließ eine Tabelle"(허용하다)는 오용, "hinterließ"(남기다)가 필요 |
| cloze_c2_0062 | cloze.json | 권력을 호명하니 방이 잠시 조용해졌다가 다시 숨이 돌아왔어요. (answer="권력을 호명하") | DEFECT-ITEM | 배분어 수정: "이름을 되찾"→"이름을 되찾으"(또는 모음어간 대체어) | | | ITEM — "되찾다"(자음어간 ㅈ)+"니"="되찾니"는 비문. (부차: 기존 DE "machte die Raumstille kurz" 연어도 부자연) |
| cloze_c2_0063 | cloze.json | 기분이 아니라 절차를 요구하니 다음 결정이 투명해졌어요. (answer="절차를 요구하") | DEFECT-ITEM | 배분어 수정: "이름을 되찾"→"이름을 되찾으"(또는 모음어간 대체어) | | | ITEM — c2_0062와 동일 배분어 결함. (부차: 기존 DE "Nicht Stimmung, ein Verfahren zu verlangen..."에 "sondern" 누락 — comma splice) |
| cloze_c2_0064 | cloze.json | 자리를 문서화하자 기억 싸움이 줄었어요. (answer="자리를 문서화하") | FP | | | | 어간+"자" 결합 정상, 배분어("이름을 되찾" 포함) 이 어미에서는 호환, DE/EN 정확 |
| cloze_c2_0075 | cloze.json | 기억을 재배치하자 내가 손님만은 아니게 됐어요. (answer="기억을 재배치하") | AWKWARD | 기억을 재배치하자 내가 손님만은 아니게 됐어요. (KO 변경 없음) | Erinnerung neu zu ordnen machte mich zu mehr als nur einem Gast. | Rearranging memory made me more than only a guest. | NAT — 기존 DE에서 "zu"가 요구하는 여격 관사 "einem" 누락("zu mehr als nur Gast") |
| cloze_c2_0076 | cloze.json | 서사를 공유하자 한 사람의 농담이 모두의 역사가 되지 않았어요. (answer="서사를 공유하") | AWKWARD | 서사를 공유하자 한 사람의 농담이 모두의 역사가 되지 않았어요. (KO 변경 없음) | Die Erzählung zu teilen verhinderte, dass der Scherz einer Person zur Geschichte aller wurde. | Sharing authorship stopped one person's joke from becoming everyone's history. | NAT — 기존 DE "aller Geschichte zu werden"은 격/어순 오류, "zur Geschichte aller werden"이 자연스러움 |

**소계 — dangling_stem (16건):** FP 5 / AWKWARD 5 / DEFECT-ITEM 6

### scenarios_a1.json — level_length (8건)

`level_length` 마커는 원문 글자수 임계값 기반 오탐지가 대부분이다. 8건 모두 확인
결과: (1) 실제 전화번호·주소 등 필수 정보로 길이가 늘어난 경우, (2) `uebersetzen`형
퀘스트가 프롬프트 자체를 여러 문장으로 명시한 경우, (3) capstone 퀘스트가 이전에
배운 여러 A1 기능을 의도적으로 한 응답에 연결한 경우 — 모두 A1 수행 과제상 정당한
길이이며 문법·어휘 자체는 A1 수준을 벗어나지 않는다.

| id | 파일 | 원문 | 판정 | 최종안(KO) | DE | EN | 코드/근거 |
|---|---|---|---|---|---|---|---|
| clinic_safety#quest_clinic_safety_06.options[0].ko | scenarios_a1.json | 열이 있고 머리가 많이 아파요. 도움이 필요해요. 의사 선생님을 불러 주세요. | FP | | | | uebersetzen 퀘스트, promptDe/En도 동일하게 3문장 — 필수 응급 메시지 전체를 산출하는 게 과제 목표 |
| delivery_address_confirmation#dialog[00] | scenarios_a1.json | 안녕하세요. 배달 기사입니다. 주소가 서울시 마포구 성산로 15, 302호 맞으세요? | FP | | | | 실제 주소(도로명+동/호수)가 길이를 늘림, 문법은 인사+자기소개+예/아니오 질문으로 A1 수준 |
| phone_messenger_reply#dialog[01] | scenarios_a1.json | 안녕하세요, 현우 씨. 반가워요. 제 전화번호는 010-3764-8291이에요. | FP | | | | 전화번호 숫자열이 길이를 늘림, 절 구조는 단순(인사+통성명+정보 제공) |
| phone_messenger_reply#quest_phone_messenger_reply_06.options[0].ko | scenarios_a1.json | 제 전화번호는 010-3764-8291이고 주소는 성산로 15, 302호예요. 천천히 확인해 주세요. | FP | | | | promptDe/En이 "전화번호+주소+요청을 천천히 확인"을 명시적으로 요구, "-이고" 연결은 A1 기초 접속어미 |
| survival_day_capstone#quest_survival_day_capstone_05.options[0].ko | scenarios_a1.json | 안녕하세요. 저는 레나입니다. / 떡볶이 한 인분 주세요. / 지하철역에 어떻게 가요? / 잘 못 알아들었어요. 천천히 다시 말씀해 주세요. | FP | | | | capstone 퀘스트, 4개 기존 학습 기능(인사·주문·길묻기·재요청)을 의도적으로 연결 — promptDe/En도 "vollständige Folge/complete sequence" 명시 |
| survival_day_capstone#quest_survival_day_capstone_05.options[1].ko | scenarios_a1.json | 안녕. 나는 레나야. / 떡볶이 먹자. / 지하철역에 가. / 빨리 말해 줘. | FP | | | | 반말 대조 오답지, 정답과 동일한 4절 구조로 존비법 대조 학습 목적 |
| survival_day_capstone#quest_survival_day_capstone_05.options[2].ko | scenarios_a1.json | 저는 레나예요. / 주문하지 않을게요. / 택시를 탔어요. / 잘 알아들었어요. | FP | | | | 각 절이 목표 기능의 반대 내용인 오답지(형태상 가능/문맥상 오답), 길이는 정답과 대칭 |
| survival_day_capstone#quest_survival_day_capstone_05.options[3].ko | scenarios_a1.json | 처음 뵙겠습니다. / 계산했어요. / 길을 알아요. / 다시 말하지 마세요. | FP | | | | 각 절이 목표 기능의 반대 내용인 오답지, 길이는 정답과 대칭 |

**소계 — level_length (8건):** FP 8 / AWKWARD 0 / DEFECT-ITEM 0

### 배치 A 소계 (24건)

FP 13 / AWKWARD 5 / DEFECT-ITEM 6

---

## 배치 B — josa_dup

- [ ] 승인 (Jin)

`josa_dup` 36건 전수. beyond-humanizer 보존 계약 적용: 사실·화행·존대·관계·시제를
고정하고 한국어 원문을 판정 기준(canonical)으로 삼음. 36건 전부가 이 마커의 알려진
오탐 패턴에 해당한다 — 마커는 `이가`를 단순 부분 문자열로 검사하는데, "이"로 끝나는
명사(나이·시누이·맏이·차이·넥타이·아이·길이·와이파이·손잡이·사이) 또는 자음받침
이름+구어체 연결 "이"(예: "수진이")에 주격 조사 `가`가 정상적으로 결합하면 오타
없이도 문자열 `이가`가 나타난다. 즉 조사 중복이 아니라 정상적인 명사(또는 이름)+조사
결합이며, `docs/data/naturalness_candidates.md`(1247–1255행)도 이 유형을 사전에
경고하고 있다. scenarios 항목 중 distractor/옵션으로 쓰인 문장(`b1_incident_lost_item_desk`
tr options, `a2_gaming_cant_connect` tr option)도 형태상 가능·문맥상 오답이라는
정상적인 오답 설계를 유지해 결함 없음. `a1_youtube_shorts_last_night`의 particlePop
항목은 "고양이가"를 이미 완성된 prefix로 두고 "냉장고＿＿＿" 빈칸의 목적격 조사(를)만
묻는 정상 설계로 "이가" 재검사와는 무관하다. `satz_c2_0225`와
`c2_moving_affordability_definition_hearing`의 dict 항목은 원문이 동일하며, DE는
"Erst..."로 한국어 "-어야"의 필요조건 뉘앙스를 보존하는 반면 EN은 다소 평서문으로
단순화했으나 사실·극성·인과 관계가 뒤집히지 않는 경미한 스타일 차이로 FP 유지(수정
필요 시 별도 스타일 패스 권장).

| id | 파일 | 원문 | 판정 | 최종안(KO) | DE | EN | 코드/근거 |
|---|---|---|---|---|---|---|---|
| cloze_a1_0003 | cloze.json | 나이가 몇 살이에요? | FP | | | | "나이"(이-종결 명사)+가 → `이가` 오탐, 조사 중복 아님 |
| cloze_a1_0174 | cloze.json | 시누이가 옷걸이를 찾아 줬어요. | FP | | | | "시누이"+가 → `이가` 오탐 |
| cloze_a1_0179 | cloze.json | 맏이가 자리 배치를 조용히 정했어요. | FP | | | | "맏이"+가 → `이가` 오탐 |
| cloze_b1_0050 | cloze.json | 두 나라의 차이가 커요. | FP | | | | "차이"+가 → `이가` 오탐 |
| cloze_c1_0024 | cloze.json | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. | FP | | | | "차이"+가 → `이가` 오탐; DE/EN PIVOT 일치, formal 유지 |
| cloze_c1_0249 | cloze.json | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. | FP | | | | "길이"+가 → `이가` 오탐; DE/EN PIVOT 일치 |
| cloze_c2_0223 | cloze.json | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. | FP | | | | "차이"+가 → `이가` 오탐; DE/EN PIVOT 일치 |
| vocab_a1_0011 | korean_vocab.csv | 나이가 어떻게 되세요? | FP | | | | "나이"+가 → `이가` 오탐; 존대(되세요) DE(Sie) 일치 |
| vocab_a1_0286 | korean_vocab.csv | 시누이가 옷걸이를 찾아 줬어요. | FP | | | | "시누이"+가 → `이가` 오탐 |
| vocab_a1_0291 | korean_vocab.csv | 맏이가 자리 배치를 조용히 정했어요. | FP | | | | "맏이"+가 → `이가` 오탐 |
| vocab_a2_0171 | korean_vocab.csv | 파란 넥타이가 잘 어울려요. | FP | | | | "넥타이"+가 → `이가` 오탐 |
| vocab_a2_0244 | korean_vocab.csv | 아이가 공주 그림을 그렸어요. | FP | | | | "아이"+가 → `이가` 오탐 |
| vocab_b1_0086 | korean_vocab.csv | 한국이랑 독일 문화 차이가 진짜 커요. | FP | | | | "차이"+가 → `이가` 오탐; 캐주얼 register DE(echt)/EN 일치 |
| vocab_c1_0024 | korean_vocab.csv | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. | FP | | | | cloze_c1_0024와 동일 원문, "차이"+가 → `이가` 오탐 |
| vocab_c1_0233 | korean_vocab.csv | 설명 가능성은 기술 문서의 길이가 아니라 이의 제기에 쓸 수 있는 정보로 평가해야 합니다. | FP | | | | cloze_c1_0249와 동일 원문, "길이"+가 → `이가` 오탐 |
| satz_a1_0002 | satz_sentences.json | 나이가 몇 살이에요? | FP | | | | "나이"+가 → `이가` 오탐 |
| satz_a1_0138 | satz_sentences.json | 시누이가 옷걸이를 찾아 줬어요. | FP | | | | "시누이"+가 → `이가` 오탐 |
| satz_a1_0143 | satz_sentences.json | 맏이가 자리 배치를 조용히 정했어요. | FP | | | | "맏이"+가 → `이가` 오탐 |
| satz_a2_0362 | satz_sentences.json | 파란 넥타이가 잘 어울려요. | FP | | | | "넥타이"+가 → `이가` 오탐; DE/EN 일치 |
| satz_a2_0432 | satz_sentences.json | 아이가 공주 그림을 그렸어요. | FP | | | | "아이"+가 → `이가` 오탐; DE/EN 일치 |
| satz_b1_0042 | satz_sentences.json | 두 나라의 차이가 커요. | FP | | | | "차이"+가 → `이가` 오탐; DE/EN 일치 |
| satz_c1_0024 | satz_sentences.json | 인터뷰 내용과 실제 이용 기록을 대조하니 기억과 행동 사이에 차이가 보였습니다. | FP | | | | "차이"+가 → `이가` 오탐; formal 유지, DE/EN PIVOT 일치 |
| satz_c2_0225 | satz_sentences.json | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. | FP | | | | "차이"+가 → `이가` 오탐; DE는 "Erst"로 -어야 보존, EN은 경미하게 평서문화(스타일, 사실관계 무변) |
| a1_youtube_shorts_last_night#dialog[02] | scenarios_a1.json | 고양이가 냉장고를 열었어. | FP | | | | "고양이"+가 → `이가` 오탐; DE/EN 일치, 캐주얼 어투 |
| a1_youtube_shorts_last_night#quest_a1_youtube_shorts_last_night_hear.audioKo | scenarios_a1.json | 고양이가 냉장고를 열었어. | FP | | | | dialog와 동일 문장, `이가` 오탐; hoerverstehen 오답지 모두 형태상 정상 |
| a1_youtube_shorts_last_night#quest_a1_youtube_shorts_last_night_particle.particlePop | scenarios_a1.json | 고양이가 냉장고를 열었어. | FP | | | | prefix="고양이가 냉장고"(완성된 주어부), 이 항목은 냉장고+를 목적격 조사만 검증; 이가는 재검사 대상 아님, 설명(냉장고 endet auf ㅗ→를) 정확 |
| a2_gaming_cant_connect#quest_a2_gaming_cant_connect_tr.options[3].ko | scenarios_a2.json | 와이파이가 아예 안 돼. | FP | | | | "와이파이"+가 → `이가` 오탐; uebersetzen 오답지로 형태 가능·문맥 오답 정상 설계 |
| b1_friends_he_said_that#dialog[00] | scenarios_b1.json | 어제 수진이가 너 화났다고 했는데, 진짜야? | FP | | | | 자음받침 이름 "수진"+이(구어체 연결)+가 → `이가` 오탐, 조사 중복 아님; DE Konjunktiv(wärst)로 간접화법 정확 |
| b1_incident_lost_item_desk#quest_b1_incident_lost_item_desk_tr.options[1].ko | scenarios_b1.json | 갈색 가방이고 손잡이가 길어요. | FP | | | | "손잡이"+가 → `이가` 오탐; uebersetzen 오답지로 형태 가능·문맥 오답 정상 |
| b1_incident_lost_item_desk#quest_b1_incident_lost_item_desk_tr.options[3].ko | scenarios_b1.json | 파란 우산이고 손잡이가 굽었어요. | FP | | | | 동일 사유, 오답지로 정상 |
| c2_moving_affordability_definition_hearing#quest_c2_moving_affordability_definition_hearing_dict.targetKo | scenarios_c2.json | 소득 구간별 부담의 분포를 공개해야 평균이 가리는 차이가 드러납니다. | FP | | | | satz_c2_0225와 동일 원문·DE/EN; "차이"+가 → `이가` 오탐 |
| skz_a2_006#v00 | silben_puzzles.json | 아이가 공주 그림을 그렸어요. | FP | | | | "아이"+가 → `이가` 오탐; exampleDe 일치 |
| skz_a2_019#h20 | silben_puzzles.json | 파란 넥타이가 잘 어울려요. | FP | | | | "넥타이"+가 → `이가` 오탐; exampleDe 일치 |
| skz_b1_006#h21 | silben_puzzles.json | 한국이랑 독일 문화 차이가 진짜 커요. | FP | | | | "차이"+가 → `이가` 오탐; 캐주얼 register exampleDe(echt) 일치 |
| smalltalk_b2_0095 | smalltalk.json | 선을 긋고도 사이가 나빠지지 않으려면 어떻게 말해야 할까요? | FP | | | | "사이"+가 → `이가` 오탐; 관용구 "사이가 나빠지다" 정상, DE/EN 일치 |
| smalltalk_c1_0063#reply | smalltalk.json | 평균 하나로는 긴급도와 지역 차이가 가려져요. | FP | | | | "차이"+가 → `이가` 오탐; DE/EN PIVOT 일치 |

**소계 — 배치 B (36건):** FP 36 / AWKWARD 0 / DEFECT-ITEM 0

---

## 배치 C — formality_mix 표본(30/225)

- [ ] 승인 (Jin)

`formality_mix` 전체 225건 중 (source file, id) 오름차순 표본 30건(1–30번째)을
심사했다. 계약: `.agents/skills/beyond-humanizer/SKILL.md` 보존 계약 + PIVOT.
FP 원인 분류 및 전수 심사 권고는 아래 "formality_mix 보정" 절 참조.

| id | 파일 | 원문 | 판정 | 최종안(KO) | DE | EN | 코드/근거 |
|---|---|---|---|---|---|---|---|
| cloze_a1_0077 | cloze.json | 실례합니다 잠깐만요. | FP | | | | 고정 관용구 조합("실례합니다"+"잠깐만요"), 답/오답 모두 자연 |
| cloze_a1_0188 | cloze.json | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. | FP | | | | "잘 먹었습니다"=고정 인용 인사, 캐주얼 서술이 감쌈, 자연 |
| vocab_a1_0169 | korean_vocab.csv | 처음 뵙겠습니다. 잘 부탁드려요. | FP | | | | "처음 뵙겠습니다"=고정 인사말, 뒤 -요체 자연스러운 조합 |
| vocab_a1_0300 | korean_vocab.csv | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. | FP | | | | cloze_a1_0188과 동일 문장, 동일 사유 |
| satz_a1_0152 | satz_sentences.json | 상을 물릴 때 잘 먹었습니다 하고 크게 인사했어요. | FP | | | | cloze_a1_0188과 동일 문장, 동일 사유 |
| satz_a1_0294 | satz_sentences.json | 처음 뵙겠습니다. 잘 부탁드려요. | FP | | | | vocab_a1_0169와 동일 문장, 동일 사유 |
| a1_airport_cart#dialog[07] | scenarios_a1.json | 감사합니다. 수고하세요. | FP | | | | 손님→직원 표준 작별 인사 조합, 어색함 없음 |
| a1_card_topup#dialog[07] | scenarios_a1.json | 네, 알겠어요. 고맙습니다. | FP | | | | "-어요."+"고맙습니다." 종결 인사, 실생활 흔함 |
| a1_city_service_route_batch20#dialog[00] | scenarios_a1.json | 실례합니다. 우체국은 어디에 있어요? | FP | | | | 낯선 사람에게 길 묻는 표준 화법("실례합니다"+질문) |
| a1_city_service_route_batch20#quest…_hear.options[0].ko | scenarios_a1.json | 실례합니다. 우체국은 어디에 있어요? | FP | | | | 위와 동일 문장(청해 퀘스트 오답 선택지), 자연 |
| a1_city_service_route_batch20#quest…_translate.options[0].ko | scenarios_a1.json | 실례합니다. 우체국은 어디에 있어요? | FP | | | | 위와 동일 문장(번역 퀘스트 오답 선택지), 자연 |
| a1_class_pencil#dialog[07] | scenarios_a1.json | 감사합니다. 그럼 그렇게 부탁드려요. | FP | | | | 대여 요청을 재확인하는 종결구, "그렇게"=원 요청 지칭 |
| a1_dust_mask#dialog[07] | scenarios_a1.json | 네, 알겠어요. 고맙습니다. | FP | | | | a1_card_topup#dialog[07]과 동일 패턴, 자연 |
| a1_excuse_pass#dialog[01] | scenarios_a1.json | 실례합니다. 지나갈게요. | FP | | | | "실례합니다"+양해 표현, 표준적인 양해-통과 화법 |
| a1_excuse_pass#dialog[07] | scenarios_a1.json | 네, 알겠어요. 고맙습니다. | FP | | | | a1_card_topup#dialog[07]과 동일 패턴, 자연 |
| a1_excuse_pass#quest_a1_excuse_pass_tr.options[0].ko | scenarios_a1.json | 실례합니다. 지나갈게요. | FP | | | | 합쇼체 고정 인사구(실례합니다)+해요체 서술, 접객·통행 상황 표준 혼용 |
| a1_gate_code#dialog[04] | scenarios_a1.json | 알겠습니다. 그렇게 하세요. | FP | | | | 습니다체 응답+해요체 지시, 응대 관용구로 완전 자연 |
| a1_gate_code#dialog[07] | scenarios_a1.json | 네, 알겠어요. 고맙습니다. | FP | | | | 해요체 확인+고맙습니다 종결, 종결 관용구 자연 |
| a1_hall_shoes#dialog[04] | scenarios_a1.json | 알겠습니다. 바로 그렇게 할게요. | FP | | | | 습니다체+해요체 혼용, 이웃 응대 관용구 |
| a1_hotel_key#dialog[07] | scenarios_a1.json | 감사합니다. 그럼 그렇게 부탁드려요. | FP | | | | 접객 종결 관용구, 매우 흔한 혼용 패턴 |
| a1_last_train#dialog[07] | scenarios_a1.json | 네, 알겠어요. 고맙습니다. | FP | | | | a1_gate_code#dialog[07]과 동일 패턴, 자연 |
| a1_market_bag#dialog[07] | scenarios_a1.json | 감사합니다. 그럼 그렇게 부탁드려요. | FP | | | | 접객 종결 관용구, 자연 |
| a1_neighbor_box#dialog[07] | scenarios_a1.json | 감사합니다. 그럼 그렇게 부탁드려요. | FP | | | | 이웃 간 정중 종결, 자연 |
| a1_numbers_floor_and_room#dialog[06] | scenarios_a1.json | 아, 여기 있네요. 고맙습니다. | FP | | | | 해요체 발견 감탄(-네요)+고맙습니다, 자연 |
| a1_numbers_total_price#dialog[05] | scenarios_a1.json | 삼천 원이요. 여기 있습니다. | FP | | | | 계산대 발화 특유의 -이요 단편+습니다체 혼용, 자연 |
| a1_numbers_total_price#dialog[06] | scenarios_a1.json | 네, 삼천 원 받았어요. 감사합니다. | FP | | | | 해요체 확인+감사합니다 종결, 자연 |
| a1_numbers_total_price#quest_a1_numbers_total_price_hear.audioKo | scenarios_a1.json | 삼천 원이요. 여기 있습니다. | FP | | | | dialog[05]와 동일 문장, 자연 |
| a1_office_print#dialog[07] | scenarios_a1.json | 감사합니다. 수고하세요. | FP | | | | 한국어 최빈출 작별 인사 쌍(감사합니다+수고하세요), 완전 자연 |
| a1_parcel_weight#dialog[07] | scenarios_a1.json | 감사합니다. 수고하세요. | FP | | | | 위와 동일, 완전 자연 |
| a1_partner_first_door#dialog[00] | scenarios_a1.json | 안녕하세요. 처음 뵙겠습니다. 현우의 친구입니다. | FP | | | | 교재 표준 첫 대면 인사 정형구(안녕하세요+처음 뵙겠습니다), 완전 자연 |

**소계 — 배치 C (30건):** FP 30 / AWKWARD 0 / DEFECT-ITEM 0

---

## formality_mix 보정

**측정된 표본 FP율:** 30/30건(100%) — 표본에 포함된 항목 전부가 FP로 판정됐고,
AWKWARD·DEFECT-ITEM은 0건이다.

**FP 원인 분류** (지시서가 지정한 known class: 캐주얼 서술 안에 삽입 인용된 고정
formal 관용구, 예 `"...하고 인사했어요"` — vs. 다른 원인):

- **알려진 클래스(narration-quote)** — 3/30건(10%): `cloze_a1_0188` /
  `vocab_a1_0300` / `satz_a1_0152` — 문장 종류로는 1종("상을 물릴 때 잘
  먹었습니다 하고 크게 인사했어요")이 세 소스 파일에 중복 등재된 것. 배치 A
  원본 파일은 이 클래스를 "2/15건"으로 표기했으나, 같은 문서의 결론부 계산("약
  20%" = 3/15)과 나열된 id 3개는 서로 일치한다 — 후자를 채택했다(라벨 오기로
  판단).
- **다른 원인(other) — 새 서브클래스 "레지스터 독립적 고정 인사/의례 표현"** —
  27/30건(90%): `실례합니다`·`감사합니다`/`고맙습니다`·`처음 뵙겠습니다`·
  `알겠습니다`/`알겠어요` 등은 한국어에서 화행상 거의 감탄사에 가까운 고정 사회적
  관례 표현으로, 뒤따르는 절의 종결형(-요체/-습니다체)과 독립적으로 결합해도
  원어민에게 전혀 어색하지 않다. 배치 B(15건 전부, `scenarios_a1.json`의
  `dialog[]`/`quest[].options[].ko`)는 이 서브클래스가 특히 뚜렷하다 — 인용/서술
  구조가 없는 직접 대화문에서 합쇼체(-습니다/-ㅂ니다)와 해요체(-어요/-아요)가 같은
  존댓말 등급 안에서 자연스럽게 뒤섞이는 접객·인사 화용 패턴이며, 대부분 코퍼스
  전반에 재사용되는 종결 템플릿(예: "감사합니다. 그럼 그렇게 부탁드려요." 10회
  이상 재사용)에서 기인한다. `formality_mix` 마커는 "습니다 계열 vs 요 종결형
  혼재"라는 문자열 수준 규칙만 적용하므로, 반말/존댓말처럼 실제 위계·친밀도를
  바꾸는 혼용이 아니라 같은 존댓말 등급 내부의 문체 변이까지 전부 잡아낸다.

**권고 — 전수 심사(나머지 195건) 필요 여부: 불필요, 조건부 권고.**

표본 30건(전체 225건의 13.3%)은 서로 다른 소스 분포(배치 A: cloze/vocab/satz의
서술 삽입형 혼합, 배치 B: scenarios_a1.json 대화문 전용)에서 뽑혔음에도 FP율이
100%로 동일했고, 두 하위 클래스(인용-서술 / 레지스터 독립적 고정 표현) 모두 마커의
알려진 문자열 수준 한계로 설명된다 — `naturalness_candidates.md`(1256–1263행)의
사전 경고와도 일치한다. 나머지 195건을 사람이 1건씩 재심사하는 것은 낮은 수율이
예상되므로 권장하지 않는다. 대신:

1. 이번 표본에서 확인된 FP 확정 패턴(고정 인사/의례 표현 목록: `처음 뵙겠습니다`,
   `실례합니다`, `감사합니다`/`고맙습니다`, `수고하세요`, `알겠습니다`/`알겠어요`,
   `그렇게 하겠습니다` 등 + narration-quote 패턴 `"...습니다/ㅂ니다 하고 ...했어요"`)를
   화이트리스트로 만들어 나머지 195건에 결정적으로 적용해 자동 FP 처리.
2. 화이트리스트에 걸리지 않는 잔여 항목만 사람/LLM이 개별 심사(예상 잔여량은
   적을 것으로 보이나 정확한 건수는 화이트리스트 적용 후 재계산 필요).
3. 통계적 확증이 필요하면 화이트리스트 적용 전 무작위 15~20건을 추가 표본으로
   뽑아 FP율이 유지되는지 확인하는 정도로 충분하다 — 전수 수작업 심사까지는
   불필요하다고 판단한다.

---

## particle_mismatch 834건 — 기계적 처리 제안

`particle_mismatch` 834건은 개별 서술 결함이 아니라 cloze 문제의 **빈칸 뒤 조사와
distractor(오답 배분어) 말음 받침의 불합치**라는 단일하고 결정적인 패턴이다 —
`tool/audit_content_naturalness.py`의 `find_particle_after_blank`(빈칸 직후 조사
추출) + `has_batchim`(완성형 한글 음절의 종성 유무 판정, 유니코드 분해식
`(코드포인트 - 0xAC00) % 28 == 0`) + `check_particle_mismatch`(둘을 대조)와 정확히
같은 로직으로 재현 가능하다. 즉 이 834건은 개별 자연성 판단이 아니라 "정답 받침
유무에 맞는 조사인데, 오답 distractor의 받침이 그 조사와 맞지 않는" 기계적
재선택(re-pick) 문제다.

**제안하는 처리 방식:**

1. **결정적 재선택기(re-picker)**: `has_batchim`/`find_particle_after_blank`와
   동일한 자모 판정 로직을 사용해, 문제가 된 distractor를 (a) 문장 뒤 조사가
   요구하는 받침 유무를 만족하고, (b) `korean_vocab.csv`(CSV 표제어 풀)에 존재하는
   실제 단어 중, (c) 원 distractor와 토픽/난이도가 가까운(주제 근접성 — 같은
   scenario/level/semantic 카테고리) 대체어로 교체한다.
2. **출력 형식**: 교체 결과를 `tool/apply_naturalness_patch.py`가 소비하는
   `patch.json` 형식으로 산출 — 이번 배치 A/B/C 승인분과 동일한 반영 경로
   (`apply_naturalness_patch.py` → `flutter test test/cloze_content_guard_test.dart`
   → `generate_tts.py`)를 그대로 재사용할 수 있다.
3. **검증 절차**: 전체 834건을 바로 일괄 반영하지 않고, 재선택기가 산출한 교체
   중 **20건 표본**을 Jin이 먼저 검토한다 — 자모 로직 자체의 정확성뿐 아니라
   토픽 근접성 선택이 실제로 자연스러운지(단순 받침 일치만으로는 의미적으로 엉뚱한
   단어가 뽑힐 수 있음) 확인하기 위함이다. 20건 검토가 승인되면 나머지 814건에
   동일 로직을 일괄 적용한다.

- [ ] 접근 승인 (Jin)

---

## 요약

| 배치 | 대상 마커 | 심사 건수 | FP | AWKWARD | DEFECT-ITEM |
|---|---|---|---|---|---|
| A | dangling_stem(16) + level_length(8) | 24 | 13 | 5 | 6 |
| B | josa_dup(36, 전수) | 36 | 36 | 0 | 0 |
| C | formality_mix(표본 30/225) | 30 | 30 | 0 | 0 |
| **합계** | | **90** | **79** | **5** | **6** |

`particle_mismatch`(834건)는 위 합계에 포함하지 않음 — 개별 심사 대상이 아니라
"particle_mismatch 834건 — 기계적 처리 제안" 절의 결정적 파이프라인 승인 대상.
