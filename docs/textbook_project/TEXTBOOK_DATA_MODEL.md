# Textbook Publishing Data Model

The data model must support books, app content and future reverse-direction EN/DE learning without rebuilding semantics.

## Core identity
- conceptId
- itemId
- unitId
- koreanLevel: 1..6
- book: 1A..6B
- canonicalTopicId
- optional subtopicId
- communicativeFunction[]
- canDo[]
- approvalState

## Korean language layer
- lemma / senseId
- grammarId[]
- coreKo
- displaySurfaceKo
- spokenSurfaceKo
- performanceCue[]
- registerLane
- relationshipLane
- speechLevel
- pragmatics[]
- pronunciationTargets[]
- morphologyNotes[]
- CEFR/LCP audit
- sourceIds[]

## EN learner layer
- explanationEn
- naturalEquivalentEn[]
- avoidLiteralEn[]
- predictedErrorsEn[]
- contrastiveNotesEn[]
- displaySurfaceEn
- spokenSurfaceEn
- speechSurfaceNoteEn
- nativeUsageProfileRef

## DE learner layer
- explanationDe
- naturalEquivalentDe[]
- avoidLiteralDe[]
- predictedErrorsDe[]
- contrastiveNotesDe[]
- displaySurfaceDe
- spokenSurfaceDe
- speechSurfaceNoteDe
- nativeUsageProfileRef

## Evidence / provenance
- rightsStatus
- provenanceSources[]
- corpusSourceCount
- evidenceTier
- confidence
- researchDate
- lastVerified
- freshnessClass
- nativeReviewStatus
- pedagogyReviewStatus

## Trend layer
Never mix trend vocabulary into the durable core without an explicit status.
- core_stable
- current_stable
- slang_watch
- domain_term
- dated_or_avoid

## Reverse-direction readiness
A concept must not be stored as KO=EN=DE single gloss.
Store language-specific realizations under the shared conceptId so the same graph can later power:
- Korean for English speakers
- Korean for German speakers
- English for Korean speakers
- German for Korean speakers
