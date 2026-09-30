# Small Talk lesson catalog content QA

## Scope and result

`assets/data/smalltalk_lessons.json` contains **207 lessons and 789 questions**.
All **582** canonical expressions occur in exactly one lesson. All **24 topics ×
6 levels** are present. Lesson counts by level are A1 33, A2 29, B1 32, B2 41,
C1 36 and C2 36. The caps are 6/6/5/5/4/4 expressions. Theme park A1 is exactly
91–94, 95–98 and 99–100 (4/4/2).

Structural validation: **PASS**. Linguistic review status: **FLAG — independent
review of the complete corpus remains required**. This is authored model work,
not a claim of native-speaker, educator or human approval. The author inspected
the Korean corpus, authored all lesson scenes, Korean scene contrasts and the
nuance cases below, and repaired five identified source translation defects.
Automated checks cannot prove that every inherited source translation or every
contrast is pedagogically optimal.

## Authoring contract

- Mode: beyond-humanizer `AUTHOR+AUDIT`. Korean source utterances are semantic
  authority. No Korean utterance, source ID, ordering, topic or level was changed.
- `tool/author_smalltalk_lessons_20260922.py` contains explicit ID groups, stable
  semantic slugs, trilingual lesson titles and scenes. It does not chunk arrays.
- Expanded topics are split by communicative activity: taxi versus public
  transport; viewing a home versus checking the lease; family arrival, speech,
  privacy, room arrangements and invisible work; theme park rides, breaks,
  belongings, shared choices and reflection. Existing source categories are
  retained even when an added expression is only loosely connected to its shelf.
- Each expression has one meaning question. Nineteen of these are separately
  authored inference/pragmatics questions: C1 reported information, competing
  possibilities, jokes, self-interpretation, sample bias and correlation; C2
  hypothetical motives, wishes, retrospective framing, empathy with preferences,
  consent and review; B2 source of a safety instruction and declining a photo.
- Other meaning questions ask for the **whole quoted utterance's meaning**.
  Correct options come directly from the source, with source-based alternatives
  ranked within the same or adjacent semantic topic and nearby level. These are
  meaning contrasts, not allegedly impossible conversational replies. A lexical
  guard and explicit equivalence sets exclude duplicate or near-equivalent
  translations, including the repeated rent questions. This generated selection
  still needs independent item-quality review; it is not represented as 563
  individually human-authored distractor sets.
- Every lesson has one separately authored situation question. All **414**
  distractors for these questions are authored Korean utterances in the same
  scene, differing in intention, referent, time, condition, evidence or force.
  They are not random category labels or generic follow-ups.
- Situation choices intentionally contain Korean in all three locale slots:
  the DE/EN task explains the scene, then the learner chooses a Korean utterance.
  Meaning questions show Korean in the prompt and DE/EN meanings in the options.
- Relationship metadata is never used to infer the only permissible audience.
  No generic `followUp` or `safeAlternativeQuestions` field is used as an answer.
- `audioKo` and `evidenceKo` are exact canonical utterances. No new Korean audio
  recordings are needed; new distractors are reading choices, not TTS inputs.

## Source translation repairs and regeneration provenance

The parent approved these eight DE/EN string repairs in five expressions, and
their exact synchronization to executable/current draft sources. The catalog
uses the updated source directly and asserts these repaired values, so the
learning screen and quiz do not disagree. Historical review CSVs remain intact.

| ID | Locale | Before | After / reason |
|---|---|---|---|
| `smalltalk_a1_0003` | DE | `Mir geht's heute gut.` | `Ich bin heute gut gelaunt.` — specifically good mood, not general well-being. |
| `smalltalk_c1_0005` | DE | `Der Aufzug ist außer Betrieb. Welche Alternative bieten wir einer Person an, die die Treppe nicht nutzen kann?` | `Der Aufzug ist außer Betrieb. Welche Alternative sollten wir jemandem nennen, dem Treppensteigen schwerfällt?` — difficulty, not categorical inability; retains the deliberative question. |
| `smalltalk_c1_0005` | EN | `The elevator is out of service. What alternative should we offer someone who cannot use the stairs?` | `The elevator has stopped. What alternative should we suggest to someone who has difficulty using the stairs?` |
| `smalltalk_c2_0049` | DE | `Wessen Einkommen und Zeitkosten setzt ein angemessener Preis voraus?` | `Wessen Einkommen und Zeitkosten setzt ein als angemessen bezeichneter Preis voraus?` — examining the label's assumptions. |
| `smalltalk_c2_0049` | EN | `Whose income and time costs does an affordable price assume?` | `Whose income and time costs does a price described as reasonable assume?` — reasonable price is not automatically affordable price. |
| `smalltalk_c2_0067` | DE | `Verschwindet Diskriminierung, wenn personalisierte Preise individuelle Vorteile heißen?` | `Verschwindet die Möglichkeit von Diskriminierung, wenn personalisierte Preise als maßgeschneiderte Vorteile bezeichnet werden?` — retains possibility, not an assertion of established discrimination. |
| `smalltalk_c2_0067` | EN | `Does discrimination disappear when personalized pricing is called a tailored benefit?` | `Does the possibility of discrimination disappear when personalized pricing is called a tailored benefit?` |
| `smalltalk_c2_0077` | EN | `The more I think about it, the more I understand why people love coming to amusement parks. The place is full of laughter, and everyone looks excited and happy.` | `Thinking it over, I feel I can understand why people like coming to amusement parks. There is laughter everywhere, and everyone looks excited and happy.` — preserves the tentative understanding in 알 것 같아. |

Synchronized provenance:

- `tools/content_factory/build_smalltalk.py`: A1 mood.
- `tools/content_factory/data/theme_park_date_records.py` and
  `tools/content_factory/drafts/theme_park_date_smalltalk_v1.json`: C2 theme park.
- `tools/content_factory/promote_batch_19_loader_coverage.py`: C2 price and
  discrimination. The existing `drafts/batch19_smalltalk.json` is frozen evidence
  in `review/batch_19_reconciliation_20260917.json`; a scoped test caught the
  attempted draft synchronization, and that draft was restored byte-for-byte.
  Its original text remains historical. The new catalog's source-value assertions
  reject any replay that would reintroduce these superseded meanings.
- `tools/content_factory/drafts/c2_batch05_smalltalk_b2_c1_c2.json`: C1 stairs.

Original source SHA-256:
`190c30a8811b0de7569d72a28d213feab9bd5c78fe9bc4fb42045eedeaf24284`.
Repaired source SHA-256:
`5e54bd2cad9157f8663df1b7e38123945bb1044aa50c97537ff960a5a8d9aad1`.

## Validation and limitations

Run `python -X utf8 tool/author_smalltalk_lessons_20260922.py --check` for
reproducibility, full source coverage, IDs, levels, topics, caps, exact A1 park
grouping, nonempty localized strings, option uniqueness, valid answer indices,
source membership, exact evidence/audio and one expression question plus one
situation question per lesson. `--review <path>` exports all answer contrasts as
TSV for independent inspection. A full source comparison with Git HEAD confirmed
exactly eight changed translation fields and unchanged Korean, IDs and ordering.
The focused Theme Park Date builder and Batch 19 reconciliation tests cover
regeneration and the protected historical evidence. The latter initially caught
the frozen draft rewrite described above; no receipt or historical hash was
updated to hide that failure.

Existing source repetition is preserved rather than silently dropping content:
for example C1 rent questions 41/62 and C2 affordability questions 41/62 are
near-equivalent and share a lesson; they cannot be each other's distractors.
Existing CEFR labels and occasional broad source shelves were not reclassified.
Some meaning questions remain translation recognition rather than open spoken
production. No assertion is made that this catalog measures spontaneous speaking
or all C1/C2 abilities. Independent language review and rendered UI verification
remain separate from the structural validation recorded here.

## Independent model review follow-up

An independent reviewer read the Korean answer contrasts for all 582 expression
questions and all 207 situation questions. The 19 separately authored nuance
questions received a complete KO/DE/EN prompt, option, evidence and explanation
review. Locale checks for the remaining meaning questions were targeted at
similar answer pairs; this was not a complete independent translation audit of
all inherited source strings and is not human or educator approval.

The review found that opposite-polarity questions can still express the same
communicative intention. In addition to the empathy and personalized-pricing
repairs, six situation foils were replaced with explicit incompatible claims:
`c1.mood.responsibility`, `c1.weekend.access`, `c1.hospital.access`,
`c2.mood.housing`, `c2.daily.fairness` and `c2.travel.limits` (each prefixed by
`smalltalk.` and suffixed by `.situation` in the catalog). These choices remain
Korean reading choices in all locale slots. Their prompts and canonical correct
answers are unchanged.

The `smalltalk.b2.theme_park_date.belongings` scene was corrected in all three
languages: the speaker had coffee outside and now cannot find the wallet; the
source does not establish where or when it was lost. This updates the lesson
intro and situation prompt without changing the source utterance, evidence,
audio or ID. The authored catalog was regenerated and checked for exact source
reproducibility and unchanged 207/789/582 coverage.
