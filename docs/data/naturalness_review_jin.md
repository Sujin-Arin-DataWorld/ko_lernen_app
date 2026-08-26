# 자연성 검수 — Jin 확인 필요 11건 (2026-08-26)

> 사용법: 각 항목의 ✍️ 칸에 원하는 최종 문장을 쓰거나, 제안이 맞으면 ✅만 표시. 다 쓰면 저장 후 "검수 끝"이라고 알려주면 그대로 적용된다.
> (FP 판정 79건은 수정 불요라 이 파일에서 제외)

## 1. cloze_b1_0118 — cloze.json

- **문장(현재)**: 대충 하지 말라고 현우가 귓속말로 했어요. (answer="대충 하")
- **걸린 이유**: PRAG, NAT — 기존 DE("Mach es nicht zu ungenau, flüsterte Hyunwoo.")가 KO의 간접 인용(-라고 했어요)을 직접 인용문으로 바꿔 화행/증거성 왜곡.
- **개선 제안**: 한국어는 변경 없음. 독일어 번역을 간접 인용으로 수정 필요.
  - DE: Hyunwoo flüsterte mir zu, ich solle es nicht schludrig machen. (제안 개선본)
  - EN: Hyunwoo whispered that I shouldn't do it carelessly. (제안 개선본)
- **✍️ Jin 최종안**: 

## 2. cloze_b2_0264 — cloze.json

- **문장(현재)**: 관계부터 말하니 악수 타이밍이 맞았어요. (answer="관계부터 말하")
- **걸린 이유**: NAT — 기존 DE("...traf den Moment zum Handschlag")는 "Moment zum Handschlag" 연어가 부자연스러움.
- **개선 제안**: 한국어는 변경 없음. 독일어 연어 수정.
  - DE: Weil ich zuerst die Beziehung nannte, passte der Zeitpunkt für den Handschlag. (제안 개선본)
  - EN: Naming the relationship first got the handshake timing right. (제안 개선본)
- **✍️ Jin 최종안**: 

## 3. cloze_c1_0076 — cloze.json

- **문장(현재)**: 공평을 설계하니 감정이 아니라 표가 남았어요. (answer="공평을 설계하")
- **걸린 이유**: NAT — 기존 DE의 "ließ eine Tabelle"(허용하다)는 오용, "hinterließ"(남기다)가 필요.
- **개선 제안**: 한국어는 변경 없음. 독일어 동사 수정.
  - DE: Fairness zu entwerfen hinterließ eine Tabelle statt nur Gefühle. (제안 개선본)
  - EN: Designing fairness left a chart, not only feelings. (제안 개선본)
- **✍️ Jin 최종안**: 

## 4. cloze_c2_0075 — cloze.json

- **문장(현재)**: 기억을 재배치하자 내가 손님만은 아니게 됐어요. (answer="기억을 재배치하")
- **걸린 이유**: NAT — 기존 DE에서 "zu"가 요구하는 여격 관사 "einem" 누락("zu mehr als nur Gast").
- **개선 제안**: 한국어는 변경 없음. 독일어 문법(여격 관사) 수정.
  - DE: Erinnerung neu zu ordnen machte mich zu mehr als nur einem Gast. (제안 개선본)
  - EN: Rearranging memory made me more than only a guest. (제안 개선본)
- **✍️ Jin 최종안**: 

## 5. cloze_c2_0076 — cloze.json

- **문장(현재)**: 서사를 공유하자 한 사람의 농담이 모두의 역사가 되지 않았어요. (answer="서사를 공유하")
- **걸린 이유**: NAT — 기존 DE "aller Geschichte zu werden"은 격/어순 오류, "zur Geschichte aller werden"이 자연스러움.
- **개선 제안**: 한국어는 변경 없음. 독일어 어순/격 수정.
  - DE: Die Erzählung zu teilen verhinderte, dass der Scherz einer Person zur Geschichte aller wurde. (제안 개선본)
  - EN: Sharing authorship stopped one person's joke from becoming everyone's history. (제안 개선본)
- **✍️ Jin 최종안**: 

## 6. cloze_b1_0109 — cloze.json

- **문장(현재)**: 긴 이야기는 요약해서 전하니 핵심만 남았어요. (answer="요약해서 전하")
- **걸린 이유**: ITEM — 두 배분어 모두 템플릿 "＿＿＿니"(연결모음 없음)와 결합 시 비문(끼어들니/다시 확인니) 생성. ㄹ탈락 미반영 + "하" 누락.
- **개선 제안**: 배분어(distractor) 수정: "끼어들"→"끼어드", "다시 확인"→"다시 확인하"
  - 원인: 어미 "니"는 자음어간 뒤 연결모음이 없어서, 자음어간 동사는 비문이 됨. 이 두 배분어가 조사와 맞지 않음.
- **✍️ Jin 최종안**: 

## 7. cloze_b1_0119 — cloze.json

- **문장(현재)**: 쉬운 질문은 직접 대답하니 표정이 밝아졌어요. (answer="직접 대답하")
- **걸린 이유**: ITEM — "받다"(자음어간 ㄷ)+"니"(연결모음 없음)="받니"는 비문. 이 어미대 정답은 전부 하다류(모음어간)인데 이 배분어만 자음어간.
- **개선 제안**: 배분어(distractor) 수정: "물로 받"→"물로 받으"(또는 모음어간 대체어)
- **✍️ Jin 최종안**: 

## 8. cloze_b1_0153 — cloze.json

- **문장(현재)**: 잠자리 경계 다시 정하니 둘이 편해졌어요. (answer="경계 다시 정하")
- **걸린 이유**: ITEM — "맡다"(자음어간 ㅌ)+"니"="맡니"는 비문. "잠자리"는 맥락(파트너 가족 방문/취침 배정)상 자연스러움, 완곡어 오독 우려는 낮음.
- **개선 제안**: 배분어(distractor) 수정: "통역을 맡"→"통역을 맡으"(또는 모음어간 대체어)
- **✍️ Jin 최종안**: 

## 9. cloze_c1_0075 — cloze.json

- **문장(현재)**: 노동을 보이게 하자 감사의 대상이 달라졌어요. (answer="노동을 보이게 하")
- **걸린 이유**: ITEM — "하" 누락으로 동사 미완성, "다시 명명"+"자"="다시 명명자"는 비문.
- **개선 제안**: 배분어(distractor) 수정: "다시 명명"→"다시 명명하"
- **✍️ Jin 최종안**: 

## 10. cloze_c2_0062 — cloze.json

- **문장(현재)**: 권력을 호명하니 방이 잠시 조용해졌다가 다시 숨이 돌아왔어요. (answer="권력을 호명하")
- **걸린 이유**: ITEM — "되찾다"(자음어간 ㅈ)+"니"="되찾니"는 비문. (부차: 기존 DE "machte die Raumstille kurz" 연어도 부자연).
- **개선 제안**: 배분어(distractor) 수정: "이름을 되찾"→"이름을 되찾으"(또는 모음어간 대체어)
- **✍️ Jin 최종안**: 

## 11. cloze_c2_0063 — cloze.json

- **문장(현재)**: 기분이 아니라 절차를 요구하니 다음 결정이 투명해졌어요. (answer="절차를 요구하")
- **걸린 이유**: ITEM — cloze_c2_0062와 동일 배분어 결함. "되찾다"(자음어간 ㅈ)+"니"="되찾니"는 비문. (부차: 기존 DE "Nicht Stimmung, ein Verfahren zu verlangen..."에 "sondern" 누락 — comma splice).
- **개선 제안**: 배분어(distractor) 수정: "이름을 되찾"→"이름을 되찾으"(또는 모음어간 대체어)
- **✍️ Jin 최종안**: 

---

## 요약

- **AWKWARD**: 5건 (cloze_b1_0118, cloze_b2_0264, cloze_c1_0076, cloze_c2_0075, cloze_c2_0076)
- **DEFECT-ITEM**: 6건 (cloze_b1_0109, cloze_b1_0119, cloze_b1_0153, cloze_c1_0075, cloze_c2_0062, cloze_c2_0063)
- **제외된 FP**: 79건

**총 11건 정리 완료**
