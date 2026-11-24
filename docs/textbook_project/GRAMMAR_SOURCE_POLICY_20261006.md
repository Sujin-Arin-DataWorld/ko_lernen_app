# Grammar Source Policy — 2026-10-06

Status: **OFFICIAL_GRAMMAR_ONLY**

This policy applies to all Korean grammar explanations in the textbook project.

## 1. What counts as a grammar claim

The following may only be stated when an official source is attached:

- grammatical category;
- grammatical function;
- attachment/conjugation conditions;
- allomorphy;
- sentence-pattern constraints;
- honorific classification;
- meaning distinctions between grammar forms;
- claims that a form is omitted, required, optional, interchangeable, or ungrammatical;
- claims about productive grammar level or teaching scope when presented as a grammar fact.

## 2. Allowed grammar sources

Primary sources:

1. **National Institute of Korean Language (국립국어원)**
   - official research reports
   - official teacher guides / Sejong Korean guides
2. **한국어기초사전 / Korean Basic Dictionary**
   - official electronic-government learning dictionary
3. Other official NIKL dictionary/report material when a stronger source is not available.

Allowed grammar-source domains in the registry:
- `korean.go.kr`
- `www.korean.go.kr`
- `krdict.korean.go.kr`

## 3. Sources that are NOT grammar authorities

The following may be used for usage/register evidence, but not for grammar definition:

- Naver blogs
- news articles
- Reddit
- community posts
- reviews
- social media
- general language blogs
- AI-generated explanations

They can answer:
- “Do people actually say this?”
- “In what setting?”
- “What register/genre does it occur in?”

They cannot answer in our canonical grammar layer:
- “What does this grammar form mean?”
- “When is it omitted?”
- “What is its grammatical category?”
- “What are its attachment constraints?”

## 4. Localization is a separate layer

English and German translations are not Korean grammar definitions.

Example:

Korean:
`아메리카노 한 잔 주세요.`

Official grammar:
- `주세요` is treated through official request grammar around `주다 + -(으)세요`.

Possible English localization:
- Can I get an Americano, please?
- Can I have an Americano, please?
- I'll have an Americano, please.
- close compositional gloss: Please give me an Americano.

Possible German localization:
- Ich hätte gern einen Americano.
- Einmal einen Americano, bitte.
- Ich nehme einen Americano.
- close compositional gloss: Bitte geben Sie mir einen Americano.

The EN/DE lines are **contextual translations**, not definitions of `주세요`.

## 5. Learner-error research is also separate

Peer-reviewed EN-L1 / DE-L1 learner research may inform:
- predicted learner errors;
- sequencing;
- explanation design;
- diagnostic tasks.

It may **not redefine Korean grammar**.

## 6. No-source rule

If an item has no verified official grammar source:

- it may remain a fixed chunk;
- it may remain recognition-only;
- it may appear in authentic dialogue;

but the textbook must not invent a generalized grammar rule for it.

Machine marker:
`chunkOnlyNoGrammarExplanation: true`

## 7. Conflict rule

If official sources appear to conflict or the relevant sense cannot be resolved:

- do not choose a rule by assistant intuition;
- mark the item HOLD_FOR_GRAMMAR_REVIEW;
- cite both sources;
- require Korean educator/editor review.

## 8. Rendering rule

Learner-facing grammar explanations must be rendered from:

`data/ONE_A_OFFICIAL_GRAMMAR_REGISTRY_20261006.json`

They must not be generated from:
- native-usage evidence packs;
- arbitrary `function` labels in unit contracts;
- EN/DE localization notes.

## 9. Auditability

Every productive grammar item must have:
- `grammarRefs`
- `grammarSourcePolicy: official_only`

Every formulaic/recognition item must have either:
- verified `grammarRefs`, or
- `chunkOnlyNoGrammarExplanation: true`

The validator fails otherwise.
