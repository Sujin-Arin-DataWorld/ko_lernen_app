# C2d-2 A1 '-아/어 주세요' -> '-으세요' Rewrite -- Jin 10% Sample

Deterministic pick: 39 rewritten rows (vocab/cloze/satz) sorted by (kind, id), every 10th row. Jin's 2026-09-16 ruling (option a): rewrite the '-아/어 주세요' benefactive-request family with 1급 -으세요 (honorific imperative), or a softened first-person '-을 수 있어요?' question where a bare imperative loses too much without the benefactive nuance ('lend me'/'show me'/'let me hear'/'tell me' -- no clean -(으)세요 form exists once -아/어 주다 is removed). Noun + lexical 주다 ('물 주세요') is out of scope (주다 is itself a 1급 main verb); none of these rows are that shape.

Scope: the 38 DOCUMENTED_EXCEPTIONS rows C2d (PR #339) deferred, plus vocab_a1_0402 (+ its 2 mirrors cloze_a1_0290/satz_a1_0254, found by exact-text match) = 41 rows total (39 actually changed -- vocab_a1_0410 excluded, see below).

## cloze:cloze_a1_0094

- **Before KO:** 천천히 말해 주세요.
- **Before DE:** Bitte sprechen Sie langsam.
- **Before EN:** Please speak slowly.
- **After KO:** 다시 천천히 말하세요.
- **After DE:** Bitte sagen Sie es noch einmal langsam.
- **After EN:** Please say it again, slowly.

Jin 판정: ______

## cloze:cloze_a1_0331

- **Before KO:** 문 앞에 놓아 주세요.
- **Before DE:** Bitte stellen Sie es vor die Tür.
- **Before EN:** Please leave it at the door.
- **After KO:** 문 앞에 놓으세요.
- **After DE:** Bitte stellen Sie es vor die Tür.
- **After EN:** Please leave it at the door.

Jin 판정: ______

## satz:satz_a1_0300

- **Before KO:** 잠깐만 기다려 주세요.
- **Before DE:** Warten Sie bitte einen Moment.
- **Before EN:** Please wait a moment.
- **After KO:** 잠깐만 여기서 기다리세요.
- **After DE:** Warten Sie bitte hier einen Moment.
- **After EN:** Please wait here for a moment.

Jin 판정: ______

## vocab:vocab_a1_0217

- **Before KO:** 시어머니께서 웃어 주셨어요.
- **Before DE:** Meine Schwiegermutter hat mich angelächelt.
- **Before EN:** My mother-in-law smiled at me.
- **After KO:** 시어머니께서 저를 보고 웃으셨어요.
- **After DE:** Meine Schwiegermutter hat mich angesehen und gelächelt.
- **After EN:** My mother-in-law looked at me and smiled.

Jin 판정: ______

---

전체 39건 변경: vocab 12, cloze 14, satz 13 -- phone/address exchange (a1_first_class_1), pronunciation repair (a1_repair_language_1), postal requests (a1_post_office_1), borrowing money (a1_numbers_2), waiting (a1_time_3), speaking slowly (a1_daily_4), mother-in-law smiling (a1_partner_meet_names_1), answering a question (a1_repair_language_1, b1-id/a1-level row), giving up a seat (a1_sorry_thanks_1), plus several standalone cloze/satz rows with no vocab source.

## Headword-embedded grammar (NOT rewritten -- relevel-to-A2 candidates)

These headwords themselves are a lexicalized -아/어 주다 compound (적어 주다, 도와주다), so no example sentence can bring them inside the 45-item 1급 table without dropping the headword. Kept verbatim, registered in scan_a1_grammar.py's HEADWORD_EMBEDDED_GRAMMAR, flagged here for a future relevel decision (LCP §F9), same treatment as C2d's own vocab_a1_0341 precedent.

| kind | id | headword | example (unchanged) | embedded item |
|---|---|---|---|---|
| cloze | `cloze_a1_0442` | | | mirrors vocab_a1_0508 |
| satz | `satz_a1_0317` | | | mirrors vocab_a1_0410 |
| satz | `satz_a1_0423` | | | mirrors vocab_a1_0508 |
| vocab | `vocab_a1_0410` | | | 적어 주다 embeds -아/어 주다 (nikl grade 2, 표현); relevel-to-A2 candidate (C2d-2, LCP F9) |
| vocab | `vocab_a1_0508` | | | 도와주다 embeds -아/어 주다 (nikl grade 2, 표현); relevel-to-A2 candidate (C2d-2, LCP F9) |

