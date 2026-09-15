# C2d A1 Grammar Rewrite -- Jin 10% Sample

Deterministic pick: 70 rewritten rows (vocab/cloze/satz) sorted by (kind, id), every 10th row.
Reflects FINAL text after Fable R8 review (2026-09-15): greetings-pack completeness fixes, headword preservation (vocab_a1_0341), persona canon (현우->수진), tense naturalness (vocab_a1_0252).
Full list: docs/data/a1_grammar_scan_2026-09-15.md (scan) + PR diff (all 70 rows).

## cloze:cloze_a1_0109

- **Before KO:** 할머니가 웃으면서 몇 살이세요 하고 물으셨어요.
- **Before DE:** Die Großmutter fragte lächelnd, wie alt ich sei.
- **Before EN:** Grandmother smiled and asked how old I was.
- **After KO:** 할머니, 몇 살이세요?
- **After DE:** Oma, wie alt sind Sie?
- **After EN:** Grandma, how old are you?

Jin 판정: ______

## cloze:cloze_a1_0157

- **Before KO:** 차례상 앞에서는 사진을 찍지 말라고 하셨어요.
- **Before DE:** Vor dem Ahnentisch sollte ich nicht fotografieren.
- **Before EN:** They told me not to take pictures in front of the ancestral table.
- **After KO:** 차례상 앞에서는 사진을 찍지 않아요.
- **After DE:** Vor dem Ahnentisch macht man keine Fotos.
- **After EN:** In front of the ancestral table, you don't take pictures.

Jin 판정: ______

## cloze:cloze_a1_0296

- **Before KO:** 가게를 나가는 손님께 안녕히 가세요라고 해요.
- **Before DE:** Zu einem Gast, der geht, sage ich höflich auf Wiedersehen.
- **Before EN:** I politely say goodbye to a guest who is leaving.
- **After KO:** 손님이 나가요. 안녕히 가세요.
- **After DE:** Ein Gast geht hinaus. Auf Wiedersehen!
- **After EN:** A guest leaves. Goodbye!

Jin 판정: ______

## satz:satz_a1_0075

- **Before KO:** 댁에 처음 와서 신발을 어디에 둘지 몰랐어요.
- **Before DE:** Ich war zum ersten Mal bei ihnen zu Hause und wusste nicht, wohin mit den Schuhen.
- **Before EN:** It was my first time at their home and I didn't know where to put my shoes.
- **After KO:** 댁에 처음 와서 신발을 여기에 뒀어요.
- **After DE:** Ich bin zum ersten Mal bei Ihnen zu Hause und habe die Schuhe hier hingestellt.
- **After EN:** I came to your home for the first time and put my shoes here.

Jin 판정: ______

## satz:satz_a1_0187

- **Before KO:** 비가 오면 산책을 취소하다 결정해요.
- **Before DE:** Wenn es regnet, entscheide ich, den Spaziergang abzusagen.
- **Before EN:** If it rains, I decide to cancel the walk.
- **After KO:** 비가 와서 산책을 취소했어요.
- **After DE:** Es hat geregnet, deshalb habe ich den Spaziergang abgesagt.
- **After EN:** It rained, so I canceled the walk.

Jin 판정: ______

## vocab:vocab_a1_0009

- **Before KO:** 아니요, 저는 안 갈래요.
- **Before DE:** Nein, ich möchte nicht gehen.
- **Before EN:** No, I don't want to go.
- **After KO:** 아니요, 저는 안 가요.
- **After DE:** Nein, ich gehe nicht.
- **After EN:** No, I'm not going.

Jin 판정: ______

## vocab:vocab_a1_0259

- **Before KO:** 설거지를 도우려고 일어섰더니 앉으라고 하셨어요.
- **Before DE:** Ich stand auf, um abzuwaschen, und sie sagten, ich solle mich setzen.
- **Before EN:** I got up to wash the dishes and they told me to sit back down.
- **After KO:** 설거지를 도우려고 일어섰어요.
- **After DE:** Ich bin aufgestanden, um beim Abwasch zu helfen.
- **After EN:** I stood up to help with the dishes.

Jin 판정: ______

---

전체 70건 변경 요약: vocab 20 (a1_partner_meet_names_1/table_basic_1/seollal_basic_1 11건, a1_weekend_promise_1/a1_sorry_thanks_1 6건, 단독 3건), cloze 28 (위 가족팩 11건 미러 + a1_01_greetings_hangul 인사말 팩 9건[인용 래퍼 제거] + weekend_promise 6건 미러 + 단독 2건), satz 22 (가족팩 11건 미러 + weekend_promise 6건 미러 + 단독 5건).

## Fable R8 (2026-09-15) follow-up fixes applied on this same PR

- **A. Greetings pack completeness** (cloze_a1_0294/0295/0296/0299/0344): removed 관형사형(-는/-ㄴ)+명사 (전성어미, grade 2 -- "만난 분"/"가는 친구"/"나가는 손님") and register-mixed clauses via the situation+greeting two-sentence pattern; DE/EN rewritten to match literally; cloze_a1_0344 restored the missing answer/headword 화이팅 into fullKo. Detector gained an explicit ATTRIBUTIVE_NOUN_PATTERNS check (GrammarIndex never covered 전성어미 rows).
- **B. Headword preservation** (vocab_a1_0341/cloze_a1_0229/satz_a1_0193): headword "늦을 것 같다" restored verbatim ("버스가 막혀서 늦을 것 같아요.") since its own lexical form embeds -을 것 같다 (grade 2) -- registered in scan_a1_grammar.py's new HEADWORD_EMBEDDED_GRAMMAR exception list and the scan doc's LCP §F9 relevel follow-up table, not silently exempted.
- **C. Persona canon** (vocab_a1_0253/cloze_a1_0141/satz_a1_0105): 현우 (not one of the 11 canonical personas) replaced with 수진 (this pack = 크리스티안 visiting 수진's parents). Grep of the full A1 corpus found 3 further 현우 occurrences NOT touched by C2d (report-only, out of scope for grammar-level work): vocab_a1_0218/cloze_a1_0106/satz_a1_0070, vocab_a1_0220/cloze_a1_0108/satz_a1_0072, vocab_a1_0261/cloze_a1_0149/satz_a1_0113 -- flagged for a separate persona-canon cleanup pass.
- **D. Naturalness** (vocab_a1_0252/cloze_a1_0140/satz_a1_0104): tense clash (배불러요=present vs 먹었어요=past) fixed to both-present ("배불러요. 하지만 과일은 먹어요.").
