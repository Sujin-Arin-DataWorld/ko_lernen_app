# C2d A1 Grammar Rewrite -- Jin 10% Sample

Deterministic pick: 79 rewritten rows (vocab/cloze/satz) sorted by (kind, id), every 10th row.
Reflects FINAL text after Fable round 3 (2026-09-15): the 3 remaining 현우 rows fixed (persona canon + embedded grade>=2 grammar the detector had missed), detector extended for contracted -아/어 보다 / -아/어 주다 / -는 법 / -는 게. That extension surfaced 38 further rows (one large '-아/어 주세요' benefactive-request family spanning many packs) -- reported, NOT rewritten, per the coordinator's >30-hits stop-and-report threshold; see the scan doc and PR body for the full list and current status.
Full list: docs/data/a1_grammar_scan_2026-09-15.md (scan) + PR diff.

## cloze:cloze_a1_0106

- **Before KO:** 호칭이 어려워서 현우에게 물어봤어요.
- **Before DE:** Die Anrede war schwierig, also habe ich Hyunwoo gefragt.
- **Before EN:** I wasn't sure how to address them, so I asked Hyunwoo.
- **After KO:** 호칭이 어려워서 수진 씨에게 물었어요.
- **After DE:** Die Anrede war schwierig, also habe ich Sujin gefragt.
- **After EN:** I wasn't sure how to address them, so I asked Sujin.

Jin 판정: ______

## cloze:cloze_a1_0149

- **Before KO:** 세배하는 법을 현우가 거실에서 알려 줬어요.
- **Before DE:** Wie man den Neujahrsgruß macht, zeigte mir Hyunwoo im Wohnzimmer.
- **Before EN:** Hyunwoo showed me how to do the New Year bow in the living room.
- **After KO:** 수진 씨가 거실에서 세배를 가르쳤어요.
- **After DE:** Sujin brachte mir im Wohnzimmer den Neujahrsgruß bei.
- **After EN:** Sujin taught me the New Year's bow in the living room.

Jin 판정: ______

## cloze:cloze_a1_0293

- **Before KO:** 친구를 만나서 반가워라고 말해요.
- **Before DE:** Ich sage einem Freund, dass ich mich freue, ihn zu sehen.
- **Before EN:** I tell a friend I'm glad to see them.
- **After KO:** 친구를 만나서 반가워요.
- **After DE:** Ich treffe einen Freund und freue mich.
- **After EN:** I meet a friend and I'm glad.

Jin 판정: ______

## cloze:cloze_a1_0378

- **Before KO:** 오늘 눈이 좀 피곤하네요.
- **Before DE:** Meine Augen sind heute etwas müde.
- **Before EN:** My eyes are a bit tired today.
- **After KO:** 오늘 눈이 좀 피곤해요.
- **After DE:** Meine Augen sind heute etwas müde.
- **After EN:** My eyes are a bit tired today.

Jin 판정: ______

## satz:satz_a1_0110

- **Before KO:** 이야기를 들을 때는 수저 놓고 고개를 끄덕였어요.
- **Before DE:** Beim Zuhören legte ich das Besteck ab und nickte.
- **Before EN:** While they talked I put my spoon down and nodded.
- **After KO:** 이야기를 듣고 수저를 놓았어요.
- **After DE:** Ich habe zugehört und das Besteck abgelegt.
- **After EN:** I listened, and I put my spoon down.

Jin 판정: ______

## satz:satz_a1_0195

- **Before KO:** 저는 먼저 가다 자리를 잡을게요.
- **Before DE:** Ich gehe schon voraus und sichere uns Plätze.
- **Before EN:** I'll go ahead first and hold seats.
- **After KO:** 저는 먼저 가서 자리를 잡겠어요.
- **After DE:** Ich gehe zuerst und sichere die Plätze.
- **After EN:** I'll go ahead and grab the seats.

Jin 판정: ______

## vocab:vocab_a1_0220

- **Before KO:** 성함을 묻기 전에 현우가 눈짓을 했어요.
- **Before DE:** Bevor ich nach dem Namen fragte, gab mir Hyunwoo ein Zeichen.
- **Before EN:** Before I asked their name, Hyunwoo shot me a look.
- **After KO:** 성함을 묻기 전에 수진 씨가 저를 봤어요.
- **After DE:** Bevor ich nach dem Namen fragte, sah mich Sujin an.
- **After EN:** Before I asked their name, Sujin looked at me.

Jin 판정: ______

## vocab:vocab_a1_0264

- **Before KO:** 한복 고름을 매는데 현우 어머니가 도와주셨어요.
- **Before DE:** Beim Binden der Hanbok-Schleife half mir Hyunwoos Mutter.
- **Before EN:** Hyunwoo's mother helped me tie the hanbok ribbon.
- **After KO:** 한복을 입고 고름을 맸어요.
- **After DE:** Ich habe den Hanbok angezogen und die Schleife gebunden.
- **After EN:** I put on the hanbok and tied the ribbon.

Jin 판정: ______

---

전체 79건 변경 요약: vocab 23, cloze 31, satz 25 -- a1_partner_meet_names_1/table_basic_1/seollal_basic_1 가족팩(인용문+는데+으면서+을 때+전성어미+aux 등), a1_01_greetings_hangul 인사말 팩(인용 래퍼 제거), a1_weekend_promise_1/a1_sorry_thanks_1(깨진 사전형 삽입+문법), 단독 다수.

## Round history

1. **C2d initial (70 rows)**: scan_a1_grammar.py's original detector (GrammarIndex reuse + explicit 인용 regex) found and fixed 20 vocab + 28 cloze + 22 satz rows.
2. **Fable R8 (9 sentences)**: greetings-pack completeness (cloze_a1_0294/0295/0296/0299/0344), headword preservation (vocab_a1_0341, registered in HEADWORD_EMBEDDED_GRAMMAR), persona canon (vocab_a1_0253: 현우->수진), tense naturalness (vocab_a1_0252). Detector gained ATTRIBUTIVE_NOUN_PATTERNS (관형사형+noun, grade 2).
3. **Coordinator round 3 (3 rows + detector extension)**: the last 3 현우 rows fixed (vocab_a1_0218/0220/0261 -> 수진, each also carrying grade>=2 grammar the detector missed: 물어봤어요/-아 어보다, 는 법, 알려 줬어요/-아 어주다). Detector extended for contracted/batched -아/어 보다 and -아/어 주다 (expand_contractions only undoes unbatched vowel fusion, e.g. 봐<-보아, not a batched -았/었- fusion like 봤/줬) plus -는 법 and -는 게. Re-scan found 38 further rows, almost all the SAME '-아/어 주세요' benefactive-request pattern spanning many packs (phone/address exchange, pronunciation repair, postal requests, borrowing money) -- exceeds the coordinator's 30-hit stop threshold, so these are reported (see PR body) but NOT rewritten in this PR; tracked as a documented, deliberate exception list in test_scan_a1_grammar.py pending a rewrite-strategy decision.

## Persona-canon grep (report only, not fixed in this PR)

No further 현우 occurrences remain in the A1 corpus after this round (all confirmed instances fixed).
