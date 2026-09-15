# C2b-1 — A1 DE/EN Translation Refinement — Jin Sample (2026-09-15)

## Scope note on sampling

The brief asks for a deterministic 10% sample of changed rows (cap 40).
This pass's full manual read of all 402 A1 vocab rows found only **10**
rows that needed a DE/EN-only change (see `docs/data/
translation_scan_a1_2026-09-15.md` and `docs/data/
c2b1_a1_translation_changes.csv` for the complete lint scan and change
ledger) — the corpus was already high quality. Fable's round-2 review then
put a further **10 rows** back in scope (a KO grammar-bug cluster this
pass had found but left unfixed as "out of scope", plus 2 new Fable
finds), for **20 changed rows total**. Fable's round-3 re-read of those 10
then sent 3 back for a further fix (see Part -1). 10% of 20 rounds to 2
rows, which would not give Jin anything meaningful to check, so this
packet lists **all 20** changed rows instead (still well under the
40-row cap).

For each row: `Jin 판정:` is left blank for you to fill in (승인 / 반려 +
사유).

## Part -1 — round 3 (Fable's second read) — read this part FIRST

Fable read the round-2 KO fixes (Part 0) and accepted 7/10
(`vocab_a1_0312/0337/0342/0392/0396/0398/0319`) — those rows in Part 0
below are final. 3 needed one more pass:

| id | headword | round-2 KO (superseded) | round-3 KO (final) | why |
|---|---|---|---|---|
| `vocab_a1_0393` | 감사하다 | 도와주셔서 정말 감사해요. | 안드레아 씨, 정말 감사해요. | still contained a contracted `-아/어 주시-` honorific-benefactive (도와주**셔서**) that `tool/cefr_lexicon.py`'s `GrammarIndex` does not detect — a known gap; even `scan_a1_grammar.py`'s own `AUX_GIVE_RE` regex (re-run over every KO sentence this PR touched, see below) does not catch this specific conjugated form. Fable caught it by reading. Dropped "도와주셔서" entirely and added a persona vocative (Andrea, per `docs/CONTENT_PERSONA_VOICE.md`'s Sie/direct/short-sentences marker). |
| `vocab_a1_0394` | 실례하다 | 지나가기 전에 잠깐 실례해요. | 잠깐 실례해요, 화장실이 어디예요? | round-2's version was stilted; rewritten into a real situation (asking for directions) — same pattern already established at `vocab_a1_0174`. |
| `vocab_a1_0400` | 다시 말하다 | 잘 못 들어서 다시 말해요. | 잘 못 들었어요. 다시 말하세요. | round-2 still shifted the meaning (learner repeats themselves instead of asking someone else to repeat); restored via an `-으세요` 1급 request across two short sentences. |

New DE/EN for the 3:

### vocab_a1_0393 (감사하다) — round 3 final
- DE: `Andrea, vielen Dank!`
- EN: `Andrea, thank you so much!`

Jin 판정:

### vocab_a1_0394 (실례하다) — round 3 final
- DE: `Entschuldigung, wo ist die Toilette?`
- EN: `Excuse me, where's the bathroom?`

Jin 판정:

### vocab_a1_0400 (다시 말하다) — round 3 final
- DE: `Ich habe es nicht gut verstanden. Sagen Sie es bitte noch einmal.`
- EN: `I didn't catch that. Please say it again.`

Jin 판정:

**Verification requested by Fable**: `tools/content_factory/scan_a1_grammar.py`'s
own checking functions (`_grammar_hits_ge2`, `_contracted_aux_hits`,
`_attributive_noun_hits`, the explicit-quote regexes) were run directly —
not just `GrammarIndex` — over every `example_korean` this whole PR
changed (all 15 KO-changed rows across rounds 2-3: the 8-row cluster + 3
Fable finds + Batch 25's 5 liveliness rows). Result: **0 flags** on all 15
after the round-3 fixes (the round-3 script run is what caught that
`AUX_GIVE_RE` itself does *not* match `주셔서`, confirming Fable's finding
was from reading, not from a gap the automated tool would have caught
either — see the amendment note in `promoted_copy_revisions_20260822.json`
for the exact commands run).

**One related observation, not fixed here (out of the 3-row scope
given)**: `vocab_a1_0402` 정말 감사해요 ("자리를 양보해 주셔서 정말
감사해요.") has the *same* `주셔서` construction Fable flagged in
`vocab_a1_0393`, but it's pre-existing content this PR never touched, so
round 3 left it alone. Flag if you want it swept into this PR or a
follow-up.

## Part 0 — round 2 (Fable review, KO changes)

Fable spot-checked 14 of the round-1 rows on commit `1ff473db` and
accepted all 10 DE/EN-only fixes as-is (see Part 1/2 below, unchanged).
Fable then put 8 rows this pass's own reading had found — but left
unfixed as "KO editing is out of scope for a DE/EN task" — back in scope,
plus flagged 2 more (`vocab_a1_0398`, `vocab_a1_0319`). All 10 are fixed
here under strict 1급 grammar: every new `example_korean` was verified
against `tool/cefr_lexicon.py`'s `GrammarIndex` (0 grade>=2 hits) before
being applied, the headword is preserved (in its natural conjugated
form), and none exceed 8 어절. **3 of these 10 (0393/0394/0400) were
superseded in round 3 above — the table below is kept for history; use
Part -1's versions.**

### The bug, in one sentence

8 rows inserted a headword's bare dictionary form (ending in plain `-다`)
into a slot that needs `-기` (nominalizer, itself 1급 `표현`) or a
quotative (`-다고`, which is nikl **grade 3** — not usable at A1 at all).
Two rows only needed the nominalizer; the rest needed the whole sentence
redesigned to drop the quotative-request framing entirely (e.g. "asked
someone to close the window" -> "ask a friend a favor, generically")
since no 1급-only rewording preserves a "reported request" meaning
without `-다고`.

### KO changes, old -> new

| id | headword | old KO | new KO |
|---|---|---|---|
| `vocab_a1_0312` | 부치다 | 소포를 부치다 전에 주소를 확인해요. | 소포를 부치기 전에 주소를 확인해요. |
| `vocab_a1_0337` | 시간 맞추다 | 내일 오후에 시간 맞추다 문자를 보냈어요. | 내일 친구와 시간을 맞춰요. |
| `vocab_a1_0342` | 같이 걷다 | 한강에서 같이 걷다 제안했어요. | 저녁에 한강에서 같이 걸어요. |
| `vocab_a1_0392` | 죄송하다 | 늦게 와서 죄송하다 말하고 앉았어요. | 늦게 와서 정말 죄송해요. |
| `vocab_a1_0393` | 감사하다 | 도와주셔서 감사하다 인사를 했어요. | 도와주셔서 정말 감사해요. |
| `vocab_a1_0394` | 실례하다 | 잠깐 실례하다 하고 지나갔어요. | 지나가기 전에 잠깐 실례해요. |
| `vocab_a1_0396` | 부탁하다 | 창문을 닫아 달라고 부탁하다 전에 먼저 인사해요. | 친구에게 부탁하기 전에 먼저 인사해요. |
| `vocab_a1_0400` | 다시 말하다 | 못 들어서 다시 말하다 부탁했어요. | 잘 못 들어서 다시 말해요. |
| `vocab_a1_0398` | 제가 더요 | 도와줘서 고맙다는 말에 제가 더요. (Fable: `-다는` 인용 관형 + `-아/어 주다`, unusable at A1) | 정말 고마워요! 제가 더요! |
| `vocab_a1_0319` | 창구 | 세 번 창구에서 기다리세요. (Fable: native 세 = "three TIMES", not a label numeral) | 삼 번 창구에서 기다리세요. |

DE/EN for each (unchanged where the meaning didn't shift — `vocab_a1_0312`
and `vocab_a1_0319` needed no DE/EN change at all):

### vocab_a1_0312 (부치다)
- DE/EN unchanged (already said "before I mail the parcel" — matches the fixed KO exactly)

Jin 판정:

### vocab_a1_0337 (시간 맞추다)
- DE new: `Morgen stimme ich die Zeit mit einem Freund ab.`
- EN new: `Tomorrow I coordinate the time with a friend.`

Jin 판정:

### vocab_a1_0342 (같이 걷다)
- DE new: `Abends gehen wir zusammen am Hangang spazieren.`
- EN new: `In the evening we walk together along the Hangang.`

Jin 판정:

### vocab_a1_0392 (죄송하다)
- DE new: `Es tut mir wirklich leid, dass ich zu spät gekommen bin.`
- EN new: `I'm really sorry that I came late.`

Jin 판정:

### vocab_a1_0393 (감사하다) — SUPERSEDED, see Part -1 for the final version
- (round-2 DE/EN, no longer live: `Vielen Dank, dass Sie mir geholfen haben.` / `Thank you so much for helping me.`)

### vocab_a1_0394 (실례하다) — SUPERSEDED, see Part -1 for the final version
- (round-2 DE/EN, no longer live: `Bevor ich vorbeigehe, sage ich kurz Entschuldigung.` / `Before I pass by, I briefly say excuse me.`)

### vocab_a1_0396 (부탁하다) — meaning simplified (window-closing request dropped, see note below) — final, accepted round 3
- DE new: `Bevor ich einen Freund um einen Gefallen bitte, grüße ich zuerst.`
- EN new: `Before I ask a friend a favor, I greet them first.`

Jin 판정:

### vocab_a1_0400 (다시 말하다) — SUPERSEDED, see Part -1 for the final version
- (round-2 DE/EN, no longer live: `Ich habe nicht gut gehört, also sage ich es noch einmal.` / `I didn't hear well, so I say it again.`)

### vocab_a1_0398 (제가 더요)
- DE new: `Danke schön! Ich habe zu danken.`
- EN new: `Thank you! I should thank you.`

Jin 판정:

### vocab_a1_0319 (창구)
- DE/EN unchanged (already said "Schalter drei"/"counter number three" — Sino-Korean-consistent, only the KO's own numeral was wrong)

Jin 판정:

### Ambiguities / meaning shifts to flag (round 2 — 0400 resolved in round 3, see Part -1)

- `vocab_a1_0396`: the ORIGINAL sentence depended on a quotative-request
  construction (`닫아 달라고`) that is nikl grade 3 (not usable at A1
  under the "1급 grammar/vocab" instruction for this fix). I could not
  find a 1급-only way to keep "asking someone else to close THE WINDOW"
  as the sentence's meaning, so I simplified to a plain 1급 sentence
  instead — 0396 now means "I ask a friend a favor" (generic, the window
  is gone). If you want the original window-specific meaning kept even at
  the cost of allowing `-다고`-class grammar for this one row, say so and
  I'll redo it (already pervasive elsewhere in the live A1 corpus per
  C2d's own findings — see the "pending -아/어 주세요 decision" census
  below). `vocab_a1_0400`'s equivalent issue was resolved in round 3 via
  an `-으세요` request instead of a quotative, restoring the original
  "ask them to repeat" meaning without needing grade-3 grammar — see
  Part -1.
- Found but NOT fixed (out of A1 scope): `vocab_a1_0391` 겹쳐 입다 (level
  **A2**) has the identical bare-다 bug ("옷을 겹쳐 입다 해요") — flag for
  a C2b-2 (A2) pass.

## Round-2 scanner additions

- **R9** (numeral-label lint, `scan_translation_pairs.py`): flags a
  native-Korean numeral immediately before a counter-label noun
  (창구/출구/버스/교실/문/층/호) — 0 hits now that `vocab_a1_0319` is fixed.
- **Report-only census** (Fable's ask, NOT auto-fixed): across all A1
  `example_korean` (vocab) + `fullKo` (cloze) + `targetKo` (satz) —
  - `-다는`/`-라는` quotative-attributive (nikl grade 3): **0 rows** in
    any of the three corpora.
  - contracted `줘서`/`줘요`/`줬어요`/`드려서`: **1 row each** in vocab/
    cloze/satz, and all three are the SAME row: `vocab_a1_0508`
    (도와주다) / `cloze_a1_0442` / `satz_a1_0423` — "언니가 저를
    도와줘요." This is **not** productively-applied `-아/어 주다` grammar;
    도와주다 is itself a single lexicalized A1 headword (vocab_a1_0508),
    so "도와줘요" is just that one word's own normal conjugation, the
    same class of false positive as R3's irregular-conjugation set, not
    a new instance of the pending grammar question.

---

## Part 1 — the 6 most consequential changes (round 1)

| id | headword | what changed | why |
|---|---|---|---|
| `vocab_a1_0471` | 한 | KO+DE+EN rewritten | Batch 25 liveliness: "친구가 한 명 있어요" was 1 of 4 near-identical "X가 N명 있어요" rows (>3x repeat, Jin's threshold) |
| `vocab_a1_0472` | 두 | KO+DE+EN rewritten | same flat-frame family as 0471 |
| `vocab_a1_0517` | 사십 | KO+DE+EN rewritten | same flat-frame family (existential "있어요" repeated 4x across Batch 25) |
| `vocab_a1_0518` | 오십 | KO+DE+EN rewritten | same flat-frame family; also switched to honorific -으세요 for 선생님 (pedagogically nicer) |
| `vocab_a1_0481` | 와 | KO+DE+EN rewritten | Jin ruling: 와 only admires something *present*; "와, 정말 좋아요!" had no referent — added a concrete object (가방) |
| `vocab_a1_0171` | 잘 부탁드려요 | example_german + example_english trimmed | was two redundant sentences ("Schön, dass wir uns kennen. Ich freu mich." / "Great to meet you. Hope we get along.") for one KO clause; trimmed to one natural sentence each, same idiom, same meaning |

The remaining 4 changes (`vocab_a1_0410/0411/0412/0414`) are minor EN-gloss
punctuation-of-form fixes (missing "to " prefix on a verb-phrase gloss,
inconsistent with sibling headwords) — listed in Part 2 but not meaning
changes.

---

## Part 2 — every changed row, old -> new

### vocab_a1_0410 (적어 주다 — "to write down")
- EN gloss: `write down` -> `to write down`
- (example_korean/example_german/example_english unchanged)

Jin 판정:

### vocab_a1_0411 (뜻을 묻다 — "to ask the meaning")
- EN gloss: `ask the meaning` -> `to ask the meaning`

Jin 판정:

### vocab_a1_0412 (결제하다 — "to pay")
- EN gloss: `pay` -> `to pay`

Jin 판정:

### vocab_a1_0414 (주소를 확인하다 — "to check the address")
- EN gloss: `check the address` -> `to check the address`

Jin 판정:

### vocab_a1_0171 (잘 부탁드려요)
- KO (unchanged): 앞으로 잘 부탁드려요.
- DE old: `Schön, dass wir uns kennen. Ich freu mich.`
- DE new: `Ich hoffe, wir kommen ab jetzt gut miteinander aus.`
- EN old: `Great to meet you. Hope we get along.`
- EN new: `I hope we get along well from now on.`

Jin 판정:

### vocab_a1_0471 (한)
- KO old: 친구가 한 명 있어요.
- KO new: 오늘 친구를 한 명 만났어요.
- DE old: `Ich habe einen Freund.` -> new: `Heute habe ich einen Freund getroffen.`
- EN old: `I have one friend.` -> new: `I met one friend today.`
- Mirrors updated: `cloze_a1_0405`, `satz_a1_0386`

Jin 판정:

### vocab_a1_0472 (두)
- KO old: 친구가 두 명 있어요.
- KO new: 지난주에 친구를 두 명 만났어요.
- DE old: `Ich habe zwei Freunde.` -> new: `Letzte Woche habe ich zwei Freunde getroffen.`
- EN old: `I have two friends.` -> new: `I met two friends last week.`
- Mirrors updated: `cloze_a1_0406`, `satz_a1_0387`

Jin 판정:

### vocab_a1_0481 (와)
- KO old: 와, 정말 좋아요!
- KO new: 와, 이 가방 정말 예뻐요!
- DE old: `Wow, das ist wirklich toll!` -> new: `Wow, diese Tasche ist wirklich hübsch!`
- EN old: `Wow, that's really great!` -> new: `Wow, this bag is really pretty!`
- Mirrors updated: `cloze_a1_0415` (answer also changed: 좋아요 -> 예뻐요), `satz_a1_0396`

Jin 판정:

### vocab_a1_0517 (사십)
- KO old: 우리 학교에는 학생이 사십 명 있어요.
- KO new: 오늘 우리 학교에 학생이 사십 명 왔어요.
- DE old: `An unserer Schule gibt es vierzig Schüler.` -> new: `Heute sind vierzig Schüler in unsere Schule gekommen.`
- EN old: `There are forty students at our school.` -> new: `Forty students came to our school today.`
- Mirrors updated: `cloze_a1_0451`, `satz_a1_0432`

Jin 판정:

### vocab_a1_0518 (오십)
- KO old: 이 학교에는 선생님이 오십 명 있어요.
- KO new: 이 학교에서 선생님이 오십 명 일하세요.
- DE old: `An dieser Schule gibt es fünfzig Lehrer.` -> new: `An dieser Schule arbeiten fünfzig Lehrer.`
- EN old: `This school has fifty teachers.` -> new: `Fifty teachers work at this school.`
- Mirrors updated: `cloze_a1_0452`, `satz_a1_0433`

Jin 판정:

---

## What did NOT change (read but judged correct)

382 of the 402 A1 vocab rows were read and judged correct as-is (20
changed across both rounds: 10 DE/EN-only in round 1, 10 KO+DE/EN in
round 2) — no mistranslation, calque, missing headword, idiom error,
register error, or mixed-language leak found against `docs/
CONTENT_LEVEL_BIBLE.md` §B.1 and the audit's 8 defect categories. The
lint scanner's remaining 50 flagged rows (28 headword-substring false
positives from Korean irregular conjugation, 24 natural KO->DE/EN
length-expansion false positives — 2 more R3 false positives were found
while fixing 0337/0342 in round 2) are documented and justified in
`tools/content_factory/scan_translation_pairs.py`
(`DOCUMENTED_FALSE_POSITIVES`) and ratcheted by
`tools/content_factory/test_scan_translation_pairs.py`.

## Ambiguities / low-confidence calls (flag if you disagree)

- `vocab_a1_0171`'s new DE "Ich hoffe, wir kommen ab jetzt gut miteinander
  aus." intentionally echoes `vocab_a1_0222`'s formal-register twin ("Ich
  hoffe, wir kommen von jetzt an gut miteinander aus.") — both A1 rows
  teach the same 잘 부탁드려요 idiom at two politeness levels (해요체 vs
  합쇼체) that German cannot distinguish the same way; if you want the two
  DE examples to read as more clearly *different* sentences, say so and
  I'll diversify wording.
- `vocab_a1_0518`'s rewrite switched the predicate from 있어요 (existential)
  to honorific 일하세요 (아/어/여 + 으세요) for 선생님 — pedagogically I
  think this is a nice touch (models honorific verb conjugation, still 1급
  grammar), but it does change the sentence's grammatical shape more than
  the other 3 flat-frame rewrites (which kept the existential-count
  structure and only changed the surrounding context). Flag if you'd
  rather keep all 4 in the same "X를 N명 만났어요/왔어요" shape for
  consistency.

## Out-of-scope finding — UPDATE: fixed in round 2, see Part 0

Round 1 found a bare-다-form KO grammar bug in 8 non-Batch-25 rows and
left it unfixed as out of this DE/EN-only task's scope (see the git
history of this file for the original note). Fable's round-2 review put
it back in scope; all 8 rows (plus 2 more Fable finds) are now fixed —
see **Part 0** above for the full id list, old->new KO, and the two
meaning-shift ambiguities to confirm.

One related row remains genuinely out of scope: `vocab_a1_0391` 겹쳐 입다
has the identical bug but is level **A2**, not A1, so it's left for a
C2b-2 pass (see Part 0's "Found but NOT fixed" note).
