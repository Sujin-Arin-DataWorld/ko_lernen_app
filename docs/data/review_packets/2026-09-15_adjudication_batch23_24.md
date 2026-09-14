# Batch 23/24 표본 10건 판정 패킷 (C1-T1)

생성일: 2026-09-15
총 개수: 10
출처: docs/data/review_packets/batch_23_jin_sample.md (2026-09-08/09, F8 표본 Jin 판정 빈칸)
> 판정 전에는 어떤 자산도 수정하지 않는다.

F8 판정 3항목: ① 한국인이 봐도 자연스러운가 ② DE·EN이 같은 사건인가(정답 누설 없음) ③ 레벨 안인가(레벨 통용 어휘·문법, 문화어 1개 예외).

> 원문 칸은 `assets/data/korean_vocab.csv`·`assets/data/satz_sentences.json`을 이 패킷 생성 시점에 다시 읽은 라이브 문구다. 각 행에서 소스 문서가 적어둔 표본 문구와 라이브 문구를 자동 대조해 일치 여부를 '제안' 칸에 표시했다(전부 이미 main에 병합·배포된 항목이라 표본은 F8 3기준 확인용이지, 결함 지적이 아니다).

| # | id | 레벨 | 원문(KO / DE / EN 현재 라이브) | 문제(기존 리뷰 지적 요약) | 제안(Sonnet 초안 — Fable 검토 전) | Jin 판정(승인 / 수정안 / 반려) |
|---|---|---|---|---|---|---|
| 1 | `vocab_a1_0310` | A1 | 표제어: 편지 (`a1_post_office_1`)<br>KO: 이 편지를 독일로 보내 주세요.<br>DE: Bitte schicken Sie diesen Brief nach Deutschland.<br>EN: Please send this letter to Germany. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 23 (1차, 2026-09-08) · 교체(동일 ID, 새 문안) — 등기 → 편지. Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 2 | `vocab_a1_0428` | A1 | 표제어: 한국 (`a1_particles_in_use_1`)<br>KO: 한국은 지금 가을이에요.<br>DE: In Korea ist jetzt Herbst.<br>EN: It's autumn in Korea now. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 23 (1차, 2026-09-08) · 신규(새 문안) — 한국. Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 3 | `vocab_a1_0442` | A1 | 표제어: 공부 (`a1_first_class_1`)<br>KO: 저는 매일 한국어 공부를 해요.<br>DE: Ich lerne jeden Tag Koreanisch.<br>EN: I study Korean every day. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 23 (2차, 2026-09-09) · 신규(새 문안) — 공부. Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 4 | `satz_a1_0348` | A1 | 표제어: 코 (`a1_body`)<br>KO: 코가 많이 아파요.<br>DE: Meine Nase tut sehr weh.<br>EN: My nose hurts a lot. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 23 (2차, 2026-09-09) · 신규 satz(새 문장) — 코. Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 5 | `vocab_a1_0445` | A1 | 표제어: 자동차 (`a1_transport`)<br>KO: 저는 자동차로 회사에 가요.<br>DE: Ich fahre mit dem Auto zur Arbeit.<br>EN: I go to work by car. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 24 (2026-09-09) · 신규 — 자동차 (NIKL 표제어 보충). Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 6 | `vocab_a2_0487` | A2 | 표제어: 상자 (`a2_shopping_1`)<br>KO: 이 상자에 다 넣어 주세요.<br>DE: Bitte legen Sie alles in diesen Karton.<br>EN: Please put everything in this box. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 24 (2026-09-09) · 신규 — 상자 (NIKL 표제어 보충). Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 7 | `vocab_b1_0488` | B1 | 표제어: 오해 (`b1_emotions_relations_3`)<br>KO: 서로 오해가 있었던 것 같아요.<br>DE: Ich glaube, wir hatten ein Missverständnis.<br>EN: I think there was a misunderstanding between us. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 24 (2026-09-09) · 신규 — 오해 (NIKL 표제어 보충). Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 8 | `vocab_b2_0649` | B2 | 표제어: 원리 (`b2_abstract_concepts_1`)<br>KO: 원리를 알면 응용은 어렵지 않아요.<br>DE: Wenn man das Prinzip versteht, ist die Anwendung nicht schwer.<br>EN: Once you know the principle, applying it isn't hard. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 24 (2026-09-09) · 신규 — 원리 (NIKL 표제어 보충). Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 9 | `vocab_b2_0654` | B2 | 표제어: 강의 (`b2_education`)<br>KO: 그 교수님 강의는 항상 자리가 없어요.<br>DE: In der Vorlesung von diesem Professor sind die Plätze immer voll.<br>EN: That professor's lectures are always full. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 24 (2026-09-09) · 신규 — 강의 (NIKL 표제어 보충). Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
| 10 | `vocab_b2_0655` | B2 | 표제어: 지식 (`b2_education`)<br>KO: 지식보다 경험이 더 중요할 때도 있어요.<br>DE: Manchmal ist Erfahrung wichtiger als Wissen.<br>EN: Sometimes experience matters more than knowledge. | F8 표본 검수 대상 — 소스 문서에 개별 결함 지적 없음(무작위 표본 확인 절차). | Batch 24 (2026-09-09) · 신규 — 지식 (NIKL 표제어 보충). Sonnet 1차 판단: F8 ①②③ 기준 통과로 보임 (사건 일치·정답 누설 없음·레벨 안 어휘). [자동 대조] 라이브 문구가 소스 표본과 완전히 일치. Jin 최종 승인 필요. |   |
