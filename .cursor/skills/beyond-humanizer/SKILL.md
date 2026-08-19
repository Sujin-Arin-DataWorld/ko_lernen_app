---
name: beyond-humanizer
description: Audit and rewrite Hangul Sori KO↔DE/EN learner copy so naturalness never invents roles, process, or authority. Use for vocab, cloze, satz, scenarios, smalltalk, factory sources, and any Korean–German/English translation QA.
---

# Beyond Humanizer

Naturalness is not enough. Watch whether **who, what, why, by what authority, to whom, by what process** changed.

> 암시된 기능은 풀어 쓸 수 있다. 암시되지 않은 조직 구조는 창작하지 않는다.

## When to use

Any DE/EN (or generated KO) edit in `assets/data/` or `tools/content_factory/`.
This skill beats a generic humanizer for learner content.

## Workflow (mandatory order)

1. **Structural Validation** — U+FFFD, duplicate JSON keys, IDs unchanged, cloze answer in `fullKo`, 3 unique distractors, satz ≥3 tokens + 2 unused distractors. Run `scripts/validate-unicode.py` and `scripts/validate-rejected-phrases.py` first.
2. **Intent Lock** — extract the slots before rewriting:
   - DOMAIN: workplace / complaint / approval / physical space / upload / meter
   - ACTION: forward / consult / approve / decide / report / post
   - AUTHORITY: same level / higher level / unknown
   - RECIPIENT_ROLE: named / inferable / unknown
   - OBLIGATION: must / should / may
   - OUTCOME: review / approval / decision / awareness
3. **Source Authority**
   - `canonical` (textbook / Jin-locked): do not mutate KO; report only.
   - `editable` / `generated`: awkward KO may be fixed first if it does not erase the pedagogical target.
4. **Inference Budget**
   - GREEN: grammar-needed (tense, article, honorific mapping).
   - YELLOW: licensed explicitation (위로 올리다 → Freigabe weiterleiten when workplace + amount + authority).
   - RED: invented role / process / emotion / org chart. Forbidden.
5. **Native Synthesis** — write DE and EN from the locked frame, not by polishing a calque.
6. **Register Vector** — speech style, addressee, referent honorific, address term are separate. UI is **du**. Shop/stranger 하세요 may keep **Sie**. Do not sprinkle `halt`/`mal` just to sound native.
7. **Domain Anchor** — keep scene-true terms (`Taxameter` in a taxi, `검침기`/`Zähler` for utilities, `점장`/`Filialleitung`). Do not generalize to a hypernym for “naturalness”.
8. **Triangular Reprojection** — KO, DE, EN must keep the same slots. Fluent + semantic drift = fail.
9. **Pedagogical QA** — if the item teaches `맞장구`, `위임`, `통역 눈짓`, `수거`, do not rewrite KO so the target disappears. Cloze blank must stay in `sentenceKo`.
10. **Semantic Diff** — reject if a role, sign-off, manager, spatial *oben*, or prohibition (`darf ich nicht`) appeared that the source did not license.

## Do not invent

Unless the Korean or metadata names them: `manager`, `supervisor`, `Leitung`, `director`, sign-off, org chart.

Role-neutral defaults:

| Frame | DE | EN |
|---|---|---|
| forward to whoever handles it | `an die zuständige Stelle weiterleiten` | `pass this on to the appropriate person` |
| higher decision | `höhere Entscheidungsebene` | `next decision-making level` |
| send for approval | `zur Freigabe weiterleiten` | `send it up for approval` |

## Process frame for `위로` / `위에`

| Frame | Example | Accept |
|---|---|---|
| space | 책을 위에 올려 / 문장 위에 | `oben stehen` / `at the top` |
| upload / post | 명단은 언제 올라가요? | `eingestellt` / `posted` (not organizational *up*) |
| upstairs | 위층 / 직접 올라가다 | `oben` / `upstairs` — do not invent “my place” |
| complaint handoff | 위에 전해 주세요 | `zuständige Stelle` — no supervisor |
| approval | 위로 올려야 해요 | `zur Freigabe weiterleiten` — no manager |
| higher decision | 제 권한 밖이라 위에서 | `höhere Entscheidungsebene` |

## Accepted regressions (keep these)

```text
금액이 제 권한을 넘어서 위로 올려야 해요.
DE Der Betrag liegt außerhalb meiner Entscheidungsbefugnis. Ich muss ihn zur Freigabe weiterleiten.
EN This amount is beyond my approval authority, so I need to send it up for approval.

언제 위로 올라가요?  (approval scene)
DE Wann wird das zur Freigabe weitergeleitet?
EN When will it be sent up for approval?

미터기가 멈춘 채로 요금이 올랐어요. 위에 전해 주세요.
DE Das Taxameter zeigte nicht weiter an, aber der Fahrpreis stieg trotzdem. Bitte leiten Sie das an die zuständige Stelle weiter.
EN The meter wasn't moving, but the fare kept increasing. Please pass this on to the appropriate person.

가격을 정하는 일은 제 위임 밖이에요. 위로 가야 합니다.
DE Die Entscheidung über den Preis liegt außerhalb meiner Zuständigkeit und muss auf der nächsthöheren Ebene getroffen werden.
EN The pricing decision falls outside my authority and has to be made at the next decision-making level.
Keep KO: 위임 is the teaching word. Gloss 위임 범위 = Zuständigkeitsgrenze / scope of authority. Not Mandat / Mandatsgrenze.

대응하는 표현이 없습니다. 풀어 쓸 수밖에 없습니다.
DE Für dieses Wort gibt es keine Entsprechung. Ich muss es umschreiben.
EN There's no direct equivalent for this word, so I'll have to paraphrase it.
Not: spell it out.

이 주의 문장을 위에 넣을까요?
DE Soll dieser Warnsatz oben stehen?
EN Shall this caution sentence go at the top?
```

## House locks (Jin)

- `위에 전해주세요` ≠ spatial *oben* / “pass it up”.
- `잘 부탁드려요` ≠ Zusammenarbeit / please look after me.
- 편의점 = Spätkauf / Mini-Markt.
- `수고했어` ≠ great job.
- 감기 `병원` ≠ Krankenhaus → Arzt/Klinik.
- 눈짓/눈치: `Blicke austauschen` / `sich mit Blicken verständigen`. No *Übersetzungsblick* / *Augenbitte*.
- `편하게 말씀하세요` → `Sie können mir ruhig sagen`.
- `수거` in A1 trash-sort is Müll, not DHL Paketabholung.
- UI **du**. Formal 하세요 to strangers/shops may keep Sie.
- Do not `--write` cloze/satz builders. IDs and counts stay put.
- After gloss changes, sync cloze/satz/factory that share the Korean sentence.

## Do not “fix”

- Named roles in KO: `상사`, `점장`, `부장님`, `현장 책임자` → translate the named role.
- Utility `검침기` / `Zähler`.
- Spatial desk/page/upstairs `위에`.
- Fan-community `Mandat` when KO is 위임받은 사람.

## Score

```text
Naturalness 95 / Fidelity 70  → fail
Naturalness 90 / Fidelity 98  → ship
```

## Scripts

```bash
python3 .cursor/skills/beyond-humanizer/scripts/validate-unicode.py
python3 .cursor/skills/beyond-humanizer/scripts/validate-rejected-phrases.py
```
