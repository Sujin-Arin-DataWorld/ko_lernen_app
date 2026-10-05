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
Status: **in progress**
For all 32 topics:
- native Korean community search
- native English community search
- native German community search
- record recurring patterns, not isolated clever phrases

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

### R-4 Scenario coverage
Map every live/canonical/draft scenario to:
- canonical topic profile
- optional subtopic profile
- register lane
- source coverage confidence

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
