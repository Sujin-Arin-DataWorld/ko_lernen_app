# App -> Textbook Mapping Plan

Goal: reuse all valid Hangul Sori research/content without treating every app item as automatically publishable.

## Inventory classes
Map:
- live
- approved
- reviewed
- unreviewed
- draft

Research coverage and publication approval remain independent axes.

## Required mapping output per item
- sourcePath / sourceId
- approvalState
- current level
- proposed textbook level/book
- canonicalTopicId
- optional subtopicId
- registerLane
- relationshipLane
- grammarIds
- vocabIds
- culture/pragmatics links
- native-usage coverage status
- rights/provenance status
- keep / rewrite / relevel / reject
- reason

## Audit order
1. Current level authority: `CONTENT_LEVEL_BIBLE.md`
2. Source/rights gate: `CONTENT_SOURCE_POLICY.md`
3. Korean naturalness / relationship register
4. Grammar and vocabulary ceiling
5. 32-topic native-usage coverage
6. EN/DE localization readiness
7. display/spoken surface readiness
8. assessment/recycling value
9. publication decision

## Do not force mapping
If taxonomy is uncertain, store `unmappedReason` and queue manual review.
Wrong confident mapping is worse than an explicit unresolved state.

## First migration priority
Tier 1 native-usage topics:
family/relationships, home, food, shopping, transport, health, work, public services, phone/digital communication, etiquette, repair, money/contracts, technology/AI.

These are both high-frequency and high-risk for translationese.
