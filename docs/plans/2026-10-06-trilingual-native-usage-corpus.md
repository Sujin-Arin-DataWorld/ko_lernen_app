# Hangul Sori Trilingual Native-Usage Corpus Program

Date: 2026-10-06

Status: **COMPLETE — active maintenance/freshness mode**

## Scope

This research program covers **all Hangul Sori content regardless of approval
state**:
- live
- reviewed
- approved
- unreviewed
- draft

Content approval and language-usage research are separate axes. A topic may be
researched deeply even when its current learner-facing copy is unreviewed.

Canonical registry:
`tools/content_factory/canonical_scenarios/trilingual_native_usage_registry_20261006.json`

Canonical topic axis:
`tools/content_factory/cefr_matrix/taxonomy.json` — **32 topics**

Current content surfaces sampled by the program include:
- live scenarios: 191
- canonical authored scenarios: 120
- smalltalk lessons: 209
- listening lessons: 191
- cloze items: 2365
- sentence-building items: 2885
- plus reviewed and unreviewed content-factory drafts

## Research goal

For every canonical topic, collect independently evidenced native usage in:

1. Korean
2. English
3. German

The corpus is **not** a translation memory. It records how native speakers
actually frame the topic in each language.

Each language profile should capture:
- high-frequency everyday labels
- natural collocations
- discourse markers and fillers
- request / refusal / agreement / disagreement formulas
- relationship and formality range
- humor / understatement / complaint style
- everyday ↔ professional ↔ academic register transitions
- phrases that sound translated even when grammatically correct
- category shifts where the same Korean concept is normally named differently
  in EN or DE
- community usage versus authoritative terminology

## Source policy

Community sources such as Reddit, TheQoo, public Blind mirrors and other public
native-language discussions are used for:
- wording
- collocation
- tone
- discourse rhythm
- stance
- humor
- common category labels

They are **not** factual authorities for:
- law
- medicine
- public policy
- safety
- statistics

Those factual claims continue to use official or high-quality authoritative
sources.

Do not store long community quotations. Abstract recurring patterns into
phrase banks and register notes.

## Research architecture

### Layer 1 — 32-topic native-usage profile

Every taxonomy topic gets:
- KO native profile
- EN native profile
- DE native profile
- false-friend / category-shift risks
- translationese avoid-list
- pedagogical alignment notes

All Hangul Sori content reuses these profiles.

### Layer 2 — scenario/subtopic profiles

When a scenario requires narrower language, add a subtopic profile rather than
creating a new global topic.

Examples:
- `technology_digital_ai / delivery phishing`
- `work_career / shorter working week`
- `house_home / roommate chores`
- `arts_literature_history / heritage fieldwork`
- `money_finance_contracts / repair-price notice`

### Layer 3 — localization spine

Approved Korean dialogue later references the topic/subtopic profile while
preserving:
- semantic core
- speech act
- relationship
- authority
- tone
- human beat
- must-preserve learning meaning

DE and EN are then authored independently from KO + spine + native-usage
profile. They are never generated from each other.

## First corpus observations already confirmed

### Digital fraud / phishing
- KO commonly uses umbrella labels such as `보이스피싱`, `피싱 문자`.
- EN everyday parcel-text contexts commonly prefer category-specific labels
  such as `scam text`, `fake delivery text`, `phishing link` rather than
  literal `voice phishing`.
- DE everyday contexts commonly use `Phishing-SMS`, `Betrugs-SMS`,
  `Phishing-Link`; literal `Voice-Phishing` is not the default family-chat
  label.

### Work / workload
- EN community language strongly favors concrete experience:
  `same workload`, `crammed into four days`, `extra day off`,
  `mental load`, `shared calendar`.
- DE often stays compact and concrete:
  `weniger Stunden`, `gleiche Arbeit`, `Feierabend`,
  `Arbeitslast`, `nicht ausgelastet`.
- Avoid turning relationship dialogue into HR/legal prose merely because the
  topic is work.

### Neighbours / housing
- EN common formulas include `keep it down`, `shared space`,
  `thin walls`, `take turns`, `choose your battles`.
- DE common concepts include `WG`, `Hausordnung`, `Treppenhaus`,
  `Lärm`, `Rücksicht`, with direct but socially calibrated requests.
- KO community wording is highly interactional and often mixes practical facts
  with affective reactions rather than abstract housing terminology.

### Security / accounts
- KO community usage includes `2단계 인증`, `모든 장치에서 로그아웃`,
  `계정 털리다`, showing a strong casual↔technical register shift.
- EN common user-security language includes `account compromised`,
  `reset/change your password`, `sign out everywhere`, `2FA`.
- DE uses both casual `Account gehackt/übernommen` and more technical
  `kompromittiert`, depending on speaker/domain.

### Research / evidence
- Academic register should be available without leaking into every friend
  conversation.
- The same persona may say an everyday equivalent to a friend and switch to
  `field notes / documented sources / Stichprobe / Quellen` only when the
  task actually becomes methodological.

## Work plan

### R-0 Inventory
Status: **complete**
- all content approval states included
- 32 canonical taxonomy topics established as SSoT

### R-1 Broad + deep corpus pass
Status: **complete**

For all 32 topics:
- native Korean community research
- native English community research
- native German community research
- recurring patterns normalized rather than storing isolated clever phrases
- written/chat versus spoken/TTS surface notes retained separately

Current progress (2026-10-06):
- **32/32 canonical topics deep-pass complete**
- **96/96 language profiles (32 topics × KO/EN/DE) broad-pass complete**
- **96/96 language profiles deep-pass complete**
- Tier 1: **13/13 deep-pass complete**
- Tier 2: **12/12 deep-pass complete**
- Tier 3: **7/7 deep-pass complete**
- every deep profile has at least 4 independent source contexts
- every deep profile has at least 15 normalized usage patterns
- required register-lane, translationese, research-date and high-risk
  authoritative-term gates are satisfied

Each completion is computed from evidence rather than handwritten status:
`tools/content_factory/audit_trilingual_native_usage_progress.py` checks
source-context count, phrase-pattern count, register lanes, translationese
warnings, research date and (for high-risk profiles) authoritative terminology
checks. The generated report is
`tools/content_factory/review/trilingual_native_usage_progress_20261006.json`.

### R-2 Topic phrase-bank normalization
Status: **complete for all 96 language profiles**

For each language/topic classify candidates as:
- everyday core
- colloquial
- relationship-specific
- service/public
- work/professional
- academic/formal
- risky/slang/dated
- translationese avoid

### R-3 Cross-language category-shift + pedagogical alignment audit
Status: **complete for all 32 topics**

Every topic now has:
- non-empty `categoryShiftRisks`
- non-empty `pedagogicalAlignmentNotes`
- language-specific translationese warnings
- display/spoken/TTS notes in each KO/EN/DE profile

Examples:
- `보이스피싱` does not map to the same casual umbrella label in English
- Korean honorific speech does not map mechanically to German `Sie`
- Korean omitted subjects cannot be mechanically restored as English `we`
- German modal particles have pragmatic value but no 1:1 Korean source token
- `한류` is suitable as a culture-card term, while casual EN/DE may prefer
  concrete `K-pop / K-dramas / Korean food / koreanische Serien`

### R-4 Content → topic coverage
Status: **baseline ledger complete; manual review/adapters remain**

Canonical generated ledger:
`tools/content_factory/review/trilingual_content_topic_coverage_20261006.json`

Generator:
`tools/content_factory/build_trilingual_content_topic_coverage.py`

Current baseline (2026-10-06, draft-adapter pass 1):
- tracked item rows: **19,776**
- confidently mapped: **17,244**
- explicit item-level unmapped/manual-review debt: **2,532**
  - live: **945**
  - canonical review-only: **18**
  - draft/review artifacts: **1,569**
- legacy/batch draft files still tracked only at file level: **70**
- Living Korea scenes: **23/23 mapped**
- all **32/32 canonical topics** have at least one mapped content item
- there are **zero silent unmapped rows**: each mapped row has a canonical topic,
  and each non-mapped row carries `unmappedReason`

Tracked item surfaces currently include:
- live scenarios
- listening
- smalltalk
- cloze
- sentence building
- vocab
- canonical 120 review-only scenario briefs
- live scenario-culture links / culture-story arcs
- Living Korea user-reviewed/not-live scenes
- repeatable draft/review schemas for vocab, cloze, Satz, scenarios, listening,
  and smalltalk (including W10 scenario lists)

The first draft-schema adapter pass moved **127** previously file-level draft
sources into conservative item-level tracking without changing their approval
state. This expanded the visible research scope from 8,960 to 19,776 rows, so
the item-level manual-review count rose because previously hidden draft
ambiguities are now explicit rather than because live coverage regressed.

The remaining 2,532 item-level ambiguities are deliberately not force-mapped.
The remaining 70 file-level sources are mostly manifests/metadata plus
grammar/pronunciation and a few one-off schemas; they remain explicit until a
surface-specific adapter is justified.

Mapping status is independent from learner-content approval. Research never
promotes a draft/review artifact to live.

For mapped content retain:
- canonical topic profile
- optional subtopic profile
- register lane
- mapping evidence / confidence path
- original approval state

For uncertain content retain:
- explicit `unmappedReason`
- manual-review status instead of a guessed topic

### R-5 Localization contract integration
Status: **complete**

Canonical contract:
`tools/content_factory/canonical_scenarios/dialogue_localization_contract_20261006.json`

The contract now requires:
- Korean as semantic/pragmatic source of truth
- EN authored directly from Korean
- DE authored directly from Korean
- no EN↔DE translation chain
- canonical topic/subtopic native-usage profile as an input
- relationship/persona and pedagogical alignment
- separate display and spoken/TTS surfaces
- per-content localization spine fields before localized copy is promoted

The corpus program owns the contract/schema and native-usage dependency. The
actual per-scene localization spine is generated when that approved Korean
content enters localization; it is not fabricated globally in advance.

### R-6 Regression + promotion gates
Status: **complete for future promotions**

Validators now reject:
- localization contract drift from KO-direct independent EN/DE authoring
- any of the 32 topics losing KO/EN/DE `deep_pass_complete`
- empty cross-language category-shift or pedagogical-alignment notes
- missing research date / translationese warning
- missing authoritative terminology check on high-risk topics
- future scenario promotion batch **39+** without
  `localizationContract + nativeUsageTopicIds`
- batch 39+ promotion when any declared native-usage topic fails its deep-pass
  gate

Legacy batches 1–38 are grandfathered and are not retroactively blocked.


## Operational protocol for completing all 32 topics

The 32-topic program is complete only when each topic has useful, independently
researched KO/EN/DE usage profiles and every tracked content item can reuse one
of those profiles or an explicit subtopic profile.

### A. Research lanes per language

For each topic, search native usage separately in KO, EN, and DE. Do not use
one language as the source corpus for another.

Collect across the lanes that actually exist for the topic:

1. **everyday / casual**
   - friends, family, roommates, customers, travellers, ordinary users
2. **relationship / service**
   - requests, refusals, apologies, complaints, negotiation, customer service
3. **work / professional**
   - team talk, scheduling, handoffs, email, workplace disagreement
4. **academic / institutional**
   - research, legal, policy, medical, technical, public-information register
5. **online / chat**
   - shorthand, fillers, reaction language, community labels, joking style

Not every topic needs all five lanes. Mark a lane `not_applicable` rather than
forcing artificial evidence.

### B. Minimum evidence before a topic-language profile can leave broad-pass

Hard minimum per topic **per language**:
- at least **3 independent source contexts**
- at least **8 normalized usage patterns**
- at least **2 register lanes**
- at least **1 translationese/unnatural-literal warning**

Deep-pass target:
- **15–25 normalized patterns**
- **4+ independent source contexts**
- **3+ register lanes** when the topic genuinely supports them
- enough evidence to distinguish stable core language from slang or one-off
  clever phrasing

No single Reddit thread, post, article, or community should dominate a profile.

### C. What one normalized phrase-bank entry should record

Recommended entry fields:

- `patternId`
- `surfacePattern`
- `function` — request / disagreement / reassurance / complaint / etc.
- `registerLane`
- `relationshipLane`
- `tone`
- `domainTermStatus` — everyday / professional / academic / slang-risk
- `sourceRefs`
- `sourceContextCount`
- `freshness`
- `confidence`
- `avoidLiteral`
- `notes`
- `speechSurfaceNote` when display text should not be read literally by TTS

Store **patterns**, not long quotations.

### D. Display surface vs spoken surface

Native-usage research must also capture whether a form is primarily written
chat language.

Examples:
- KO: `ㅋㅋ / ㅎㅎ`
- EN: `lol / lmao` in contexts where people type it but would not literally
  say the letters in ordinary spoken dialogue
- DE: chat abbreviations/reaction spelling that should not be read mechanically

The topic-language profile has `speechSurfaceNotes` for this purpose.

This does **not** generate TTS. It only records what a future spoken-surface
review must decide. TTS remains Jin-owned.

### E. Cross-language comparison only after independent research

After KO, EN and DE broad passes are independently complete, run a comparison
pass and record:

- category-shift risks
- false-friend risks
- honorific/formality mismatches
- discourse-marker differences
- humor-equivalence notes
- subject/pronoun restoration risks
- terminology that belongs in culture cards but sounds unnatural in casual
  dialogue
- expressions that are natural in writing but not speech

Examples already identified:
- `보이스피싱` -> casual EN often `scam text/fake delivery text`; DE often
  `Phishing-SMS/Betrugs-SMS`
- Korean haeyo does not mechanically imply German `Sie`
- `한류` is useful as a label, but casual EN/DE often names the concrete
  domain instead
- `주민 동선` should not become literal EN `resident circulation`

### F. Subtopic rule

Do not create a new top-level topic whenever wording becomes specific.

Use a subtopic profile when the same canonical topic needs narrower language.

Examples:
- `technology_digital_ai / delivery_phishing`
- `work_career / shorter_working_week`
- `house_home / roommate_chores`
- `arts_literature_history / heritage_fieldwork`
- `money_finance_contracts / repair_price_notice`

A subtopic inherits the parent topic's core phrase bank and adds only what is
domain-specific.

### G. Content mapping

Build a coverage map across:
- live scenarios
- canonical authored scenarios
- smalltalk
- listening
- cloze
- sentence-building
- reviewed drafts
- unreviewed drafts

Each tracked item must have:
- `approvalState`
- `canonicalTopicId`
- optional `subtopicId`
- `registerLane`
- `researchCoverageStatus`

If automatic taxonomy matching is uncertain, use `unmappedReason` and send it
to manual review rather than forcing a wrong topic.

Research coverage must never upgrade an item's approval status.

### H. Priority order for the 32-topic deep pass

Prioritize by **content volume + localization risk + learner frequency**, not
alphabetically.

#### Tier 1 — high-frequency / high-localization-risk
- family_relationships
- house_home
- food_drink
- shopping_consumption
- transport_wayfinding
- health_body
- work_career
- services_public_admin
- communication_phone_digital
- social_etiquette_customs
- language_learning_communication_repair
- money_finance_contracts
- technology_digital_ai

#### Tier 2 — frequent social/cultural usage
- personal_identification
- neighbourhood_environment
- daily_life_routines
- numbers_time_dates
- travel_accommodation
- free_time_hobbies_sport
- media_entertainment_culture_pop
- education_study
- weather_nature_climate
- feelings_character
- intercultural_globalisation_migration
- arts_literature_history

#### Tier 3 — advanced / abstract / domain-heavy
- environment_sustainability
- society_current_affairs
- politics_law_institutions
- economy_business_labour
- science_research_evidence
- ethics_philosophy_abstract
- professional_specialised_fields

Tier 3 still needs casual language where it exists; it should not become a
dictionary of institutional prose.

### I. Freshness classes

Each usage pattern should eventually be classed as:
- `core_stable` — durable everyday language
- `current_stable` — contemporary but not obviously fleeting
- `slang_watch` — current/slang, requires periodic recheck
- `domain_term` — technical/professional terminology
- `dated_or_avoid`

Recheck `slang_watch` and fast-moving technology/media terms more frequently
than stable everyday language.

### J. Definition of done for one canonical topic

A topic is **deep-pass complete** only when:

1. KO broad/deep profile meets evidence minimums.
2. EN broad/deep profile meets evidence minimums.
3. DE broad/deep profile meets evidence minimums.
4. Each language has register notes and translationese warnings.
5. Display-vs-spoken/TTS notes exist where chat-only forms matter.
6. Cross-language category-shift audit is non-empty when meaningful.
7. App content mapping has no silent unmapped items for that topic.
8. High-risk legal/medical/safety terminology is checked against authoritative
   sources in addition to community usage.
9. Sources and research date are recorded.
10. Research completion does not alter learner-content approval status.

### K. Definition of done for the whole 32-topic program
Status: **COMPLETE — 2026-10-06**

Completion evidence:
- **32/32** canonical topics deep-pass complete
- **96/96** KO/EN/DE language profiles deep-pass complete
- independently evidenced native usage in every language/topic
- every profile meets source/pattern/register/translationese/research-date gates
- every high-risk profile carries an authoritative-term check
- **32/32** topics have category-shift and pedagogical-alignment notes
- display/spoken/TTS notes exist across all 96 profiles
- content coverage ledger tracks **19,776** item rows with zero silent unmapped
  rows: **17,244 mapped + 2,532 explicit manual-review unmapped**
- first draft-schema adapter pass moved **127** repeatable draft sources to
  item-level tracking; **70** unsupported/metadata sources remain explicitly
  file-level unmapped rather than being falsely auto-classified
- Living Korea **23/23** scenes are mapped
- localization contract consumes the registry
- future scenario promotion batch **39+** fails closed without the contract,
  native topic ids, and deep-pass coverage
- progress and content-topic ledgers are generator/auditor checked in CI
- research dates and per-pattern freshness classes are stored

This completes the **native-usage research infrastructure and 32-topic corpus**.
It does not mean every existing learner-facing DE/EN translation is
automatically approved. Existing/live/unreviewed content approval remains a
separate axis; localized copy still requires per-content localization spine,
native-language QA and explicit promotion review.
