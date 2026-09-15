# C2b-1 — A1 DE/EN Translation Refinement — Jin Sample (2026-09-15)

## Scope note on sampling

The brief asks for a deterministic 10% sample of changed rows (cap 40).
This pass's full manual read of all 402 A1 vocab rows found only **10**
rows that actually needed a change (see `docs/data/
translation_scan_a1_2026-09-15.md` and `docs/data/
c2b1_a1_translation_changes.csv` for the complete lint scan and change
ledger) — the corpus was already high quality. 10% of 10 rounds to ~1 row,
which would not give Jin anything meaningful to check, so this packet
lists **all 10** changed rows instead (still well under the 40-row cap).

For each row: `Jin 판정:` is left blank for you to fill in (승인 / 반려 +
사유).

---

## Part 1 — the 6 most consequential changes

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

392 of the 402 A1 vocab rows were read and judged correct as-is — no
mistranslation, calque, missing headword, idiom error, register error, or
mixed-language leak found against `docs/CONTENT_LEVEL_BIBLE.md` §B.1 and
the audit's 8 defect categories. The lint scanner's remaining 49 flagged
rows (26 headword-substring false positives from Korean irregular
conjugation, 24 natural KO->DE/EN length-expansion false positives) are
documented and justified in `tools/content_factory/scan_translation_pairs.py`
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

## Out-of-scope finding (not fixed here, flagged separately)

While reading, I found a distinct, real defect cluster **outside this
task's DE/EN-only scope**: several non-Batch-25 A1 `example_korean`
sentences insert a headword's bare dictionary form (`-다`) into a slot that
1급 grammar requires nominalized/quotative (`-기 전에`, `-다고 하다`), e.g.
`vocab_a1_0312` "소포를 부치다 전에..." (should be 부치**기** 전에),
`vocab_a1_0392` "죄송하다 말하고..." (should be 죄송하다**고** 말하고). The
DE/EN translations for these rows are actually fine (they translate the
*intended* meaning, not the KO bug), so no DE/EN action was needed, but the
underlying KO is ungrammatical. This is a KO-editing task outside this
PR's scope (KO changes are restricted to Batch 25 here) — see the spawned
follow-up task for the full id list.
