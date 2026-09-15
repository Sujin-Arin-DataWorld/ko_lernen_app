# C2b-2 — A2 DE/EN Translation + KO Grammar Refinement — Jin Sample (2026-09-15)

## Scope note on sampling

The brief asks for a 10% sample of changed rows (cap 40). This pass's full
manual read of all 460 A2 vocab rows, plus the automated grade>=3 grammar
scan and the R1-R9 translation lint (both re-run to 0 unexplained hits),
found **26 vocab rows** that needed a real fix (23 grammar-driven KO
rewrites, 1 KO grammar bug, 2 translation-content mismatches). 10% of 26
would round to 3 rows, which would not give Jin anything meaningful to
check — following the C2b-1 precedent, this packet lists **all 26** rows
(well under the 40-row cap), with the 10 most consequential meaning
changes called out first.

For each row: `Jin 판정:` is left blank for you to fill in (승인 / 반려 +
사유). Full field-by-field diff (including cloze/satz mirrors) is in
`docs/data/c2b2_a2_translation_changes.csv`.

## Part 1 — the 10 most consequential meaning fixes

These either changed what the sentence actually *means*, or fixed a row
that was flatly broken (grammar bug, or KO/DE/EN saying three different
things).

### 1. vocab_a1_0391 (겹쳐 입다) — bare -다 conjugation bug named in this task's brief
- old KO: `일교차가 클 때는 옷을 겹쳐 입다 해요.` (ungrammatical: bare dictionary stem "입다" directly before "해요")
- new KO: `일교차가 클 때는 옷을 겹쳐 입어요.`
- DE/EN unchanged (already matched the intended meaning).

Jin 판정:

### 2. vocab_a2_0159 (통화, "currency") — KO/DE/EN each said something different, headword never used
- old KO: `유로로 계산해도 될까요?` (Can I pay in euros?) / old DE: `Die Währung in Deutschland ist der Euro.` (Germany's currency is the euro.) / old EN: `The currency used in Germany is the euro.`
- new KO: `한국의 통화는 원이에요.` / new DE: `Die Währung in Korea ist der Won.` / new EN: `Korea's currency is the won.`
- All three now agree, and the sentence actually uses the headword 통화.

Jin 판정:

### 3. vocab_a2_0089 (추천하다, "recommend") — example never used the headword at all
- old KO: `여기서 뭐가 제일 맛있어요?` (What's most delicious here?)
- new KO: `여기서 뭐 추천해요?` (What do you recommend here?)
- DE: `Was empfehlen Sie hier?` / EN: `What do you recommend here?`

Jin 판정:

### 4. vocab_a2_0269 (어디서 오셨어요) — quotative reframed as direct Q&A
- old KO: `어디서 오셨어요 하시길래 독일 베를린이라고 했어요.` (grade3 -길래/-라고 했어요, out of A2 level)
- new KO: `어디서 오셨어요? 독일 베를린이에요.`

Jin 판정:

### 5. vocab_a2_0288 (세배 영상) — reported-imperative contraction removed
- old KO: `세배 영상은 가족 앨범에만 두래요.` (grade4 reported "-으래요")
- new KO: `세배 영상은 가족 앨범에만 둬요.`

Jin 판정:

### 6. vocab_a2_0295 (보름달) — reported-imperative contraction removed
- old KO: `보름달을 보며 소원을 말하래요.` (grade4 reported "-래요")
- new KO: `보름달을 보면서 소원을 말해요.`

Jin 판정:

### 7. vocab_a2_0345 (짐 부치다) — grade4 고 해서 + quotative removed
- old KO: `김치를 짐 부치려다 안 된다고 해서 무릎 위에 올렸어요.`
- new KO: `김치는 짐으로 부칠 수 없어서 무릎 위에 올렸어요.`

Jin 판정:

### 8. vocab_a1_0239 (윗목) — quotative -으라고 하셨어요 removed
- old KO: `윗목이 서늘해서 아래로 오라고 하셨어요.`
- new KO: `윗목이 서늘해서 아래로 앉았어요.`
- Note: this drops the "someone told me to" framing (Korean has no A1/A2-legal way to keep reported speech); the situational logic (it was cool, so I moved) is preserved.

Jin 판정:

### 9. vocab_a1_0301 (다음에 또 오세요) — bare-quote 하셔서 removed
- old KO: `다음에 또 오세요 하셔서 신발을 거꾸로 신었어요.`
- new KO: `다음에 또 오세요. 그 말을 듣고 신발을 거꾸로 신었어요.`

Jin 판정:

### 10. vocab_a2_0282 (떡국 먹다) — grade3 -다 보면 + quotative-attributive removed, folk-belief reframed as fact
- old KO: `떡국 먹다 보면 한 살이 는다는 농담을 들었어요.` (I heard the joke that...)
- new KO: `떡국을 먹으면 나이를 한 살 더 먹어요.` (If you eat it, you turn a year older.)
- Tone shift: "I heard a joke that" → stated directly as the belief itself. Flag if you want the "heard a joke" framing kept — it cannot be done at A2 without quotative grammar.

Jin 판정:

## Part 2 — remaining 16 grammar-driven KO simplifications (same defect classes as Part 1)

| id | headword | old KO | new KO | rule |
|---|---|---|---|---|
| `vocab_a1_0242` | 방석 | 방석을 밀어 주셔서 감사하다고 했어요. | 방석을 밀어 주셔서 감사했어요. | grade3 quotative removed |
| `vocab_a1_0243` | 물 드세요 | 물 드세요 하셔서 컵을 두 손으로 받았어요. | 물 드세요. 두 손으로 컵을 받았어요. | grade3 bare-quote removed |
| `vocab_a1_0276` | 성묘 | 성묘 갈 때는 편한 신발을 신으라고 하셨어요. | 성묘 갈 때는 편한 신발을 신었어요. | grade3 quotative removed |
| `vocab_a1_0299` | 잘 다녀오겠습니다 | 나갈 때 잘 다녀오겠습니다라고 했어요. | 나갈 때 인사했어요. 잘 다녀오겠습니다! | grade3 quotative removed |
| `vocab_a1_0366` | 필기하다 | 중요한 문장은 빨리 필기하다 보면 손이 아파요. | 중요한 문장을 빨리 필기하면 손이 아파요. | grade3 -다 보면 → plain -으면 |
| `vocab_a2_0106` | 곧장 | 여기서 곧장 가시면 돼요. | 여기서 곧장 가세요. | grade3 -면 되다 removed |
| `vocab_a2_0115` | 놀라다 | 깜짝 놀랐잖아요! | 깜짝 놀랐어요! | grade3 -잖아요 removed |
| `vocab_a2_0160` | 저축하다 | 매달 조금씩이라도 저축하려고 해요. | 매달 조금씩 저축하려고 해요. | grade3 -이라도 removed |
| `vocab_a2_0272` | 언제 왔어요 | 언제 왔어요 하시길래 재작년이라고 했어요. | 언제 왔어요? 재작년에 왔어요. | grade3 quotative → direct Q&A |
| `vocab_a2_0274` | 소개팅 | 소개팅이 아니라 동아리에서 만났다고 했어요. | 소개팅이 아니라 동아리에서 만났어요. | grade3 quotative removed |
| `vocab_a2_0279` | 음식 취향 | 음식 취향을 묻길래 매운 건 조금 먹는다고 했어요. | 제 음식 취향을 물어봤어요. 매운 건 조금만 먹어요. | grade3 -길래/quotative removed |
| `vocab_a2_0292` | 새해 목표 | 새해 목표를 묻길래 한국어 일기라고 했어요. | 제 새해 목표는 한국어 일기예요. | grade3 quotative removed |
| `vocab_a2_0320` | 아침 인사 | 아침 인사는 일어나자마자 큰 소리로 했어요. | 아침 인사는 일어나서 바로 크게 했어요. | grade3 -자마자 → -아서 |
| `vocab_a2_0349` | 집 마당 | 집 마당에 개가 있어서 그냥 앉아 있으라고 하셨어요. | 집 마당에 개가 있어서 그냥 앉아 있었어요. | grade3 quotative removed |
| `vocab_a2_0350` | 밤참 | 밤참으로 과일만 달라고 했는데 라면이 나왔어요. | 밤참으로 과일만 부탁했는데 라면이 나왔어요. | grade3 quotative removed |
| `vocab_a2_0352` | 안부 전화 | 서울 도착하자마자 안부 전화를 드렸어요. | 서울에 도착해서 바로 안부 전화를 드렸어요. | grade3 -자마자 → -아서 |

Every row above (and Part 1's grammar rows) has its full DE/EN before/after
in `docs/data/c2b2_a2_translation_changes.csv`; the KO rewrites were
verified to score 0 grade>=3 hits by `scan_grammar_level.py --level A2`
(see `docs/data/grammar_scan_a2_2026-09-15.md`).

## Open question for Jin

Ten of these rows (윗목/방석/물 드세요/성묘/잘 다녀오겠습니다/다음에 또
오세요/집 마당, the "someone told me to / I said" family in the
partner-family 추석·설날·방문 packs) lost their reported-speech framing
because Korean has no A1/A2-legal way to keep it. If this pack's whole
premise (a partner explaining what their Korean family told them) matters
pedagogically, the fix is to move these specific vocab items to B1 rather
than rewrite them — flagging for your call rather than deciding
unilaterally.
