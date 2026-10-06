# Hangul Sori Trilingual Native-Usage Corpus Program

Date: 2026-10-06

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

### R-1 Broad corpus pass
Status: **broad-pass complete — deep-pass pending**

For all 32 topics:
- native Korean community search
- native English community search
- native German community search
- record recurring patterns, not isolated clever phrases

Current progress (2026-10-06):
- **Broad pass complete across the full 32-topic taxonomy**
- **96/96 language profiles (32 topics × KO/EN/DE) broad-pass complete**
- Tier 1: **13/13 topics**
- Tier 2: **12/12 topics**
- Tier 3: **7/7 topics**
- deep-pass: **0/96 profiles, 0/32 topics** — not claimed yet
- next stage is evidence-deepening, not missing-topic coverage

Tier-1 completed topics:
`family_relationships`, `house_home`, `food_drink`,
`shopping_consumption`, `transport_wayfinding`, `health_body`,
`work_career`, `services_public_admin`,
`communication_phone_digital`, `social_etiquette_customs`,
`language_learning_communication_repair`,
`money_finance_contracts`, `technology_digital_ai`.

Each completion is computed from evidence rather than handwritten status:
`tools/content_factory/audit_trilingual_native_usage_progress.py` checks
source-context count, phrase-pattern count, register lanes, translationese
warnings, research date and (for deep pass) authoritative terminology checks.

### R-2 Topic phrase-bank normalization
For each language/topic classify candidates as:
- everyday core
- colloquial
- relationship-specific
- service/public
- work/professional
- academic/formal
- risky/slang/dated
- translationese avoid

### R-3 Cross-language category-shift audit
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

Current baseline (2026-10-06):
- tracked item rows: **8,960**
- confidently mapped: **7,997**
- explicit item-level unmapped/manual-review debt: **963**
- legacy/batch draft files explicitly tracked at file level pending schema adapters: **197**
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

The remaining 963 item-level ambiguities are deliberately not force-mapped. The
197 legacy/batch draft files remain in research scope with an explicit
file-level unmapped reason until an item-level schema adapter exists.

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
Localization cannot begin at scale until:
- topic profile exists
- Korean copy is frozen when relevant
- localization spine is frozen
- DE/EN independent authoring lanes are defined

### R-6 Regression gates
Future validators should reject:
- localization produced through DE↔EN translation chains
- missing topic native-usage profile for promoted content
- literal category labels marked as translationese risks
- stale research where dated slang/current-community language is used without
  review


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

The program is complete only when:
- **32/32** canonical topics are deep-pass complete
- KO/EN/DE profiles are independently evidenced for every topic
- all tracked content is mapped or has an explicit `unmappedReason`
- localization can request a topic/subtopic profile without searching ad hoc
- the localization contract consumes these profiles
- CI can detect missing native-usage coverage for content promoted to live
- research freshness/recheck dates are tracked

Until then, localization may pilot selected approved content, but large-scale
DE/EN promotion should not assume the corpus is complete.
