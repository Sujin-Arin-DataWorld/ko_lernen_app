# Korean 1A Official Grammar Audit — 2026-10-06

Status: **OFFICIAL-SOURCE REAUDIT INTEGRATED**

## Why this audit was opened

During visual review of Unit 04, the wording around `주세요` mixed two different questions:

1. What is the Korean grammar/function?
2. How should the sentence be translated naturally into English or German?

Those layers are now separated.

The audit also removed grammar generalizations that had been inferred from examples rather than tied to official sources.

## Corrections made

### 1. 주세요

Removed:
- “주세요 is not Give me...”
- “주세요 has no fixed translation” as if that were a grammar explanation.

Official grammar layer:
- the NIKL Sejong Korean 1 teacher guide presents `-(으)세요` for command/request;
- it gives `사과를 주세요`;
- its conjugation table shows `주다 → 주세요`.

Canonical grammar ref:
`G_SERVICE_JUSEYO`

Translation/localization is now a separate box.

### 2. 을/를 in Unit 04

Official grammar layer:
- Korean Basic Dictionary: `을/를` marks an object directly affected by an action.

Removed:
- a generalized particle-omission rule inferred only from comparing
  `저는 떡볶이를 먹어요`
  with
  `떡볶이 하나 주세요`.

The order sentence remains a learned service pattern; the unit does not generalize omission conditions from it.

### 3. 카톡 하세요?

The earlier label `-세요?` could look like a generalized grammar target.

Correction:
- canonical formulaic item is now the exact chunk `카톡 하세요?`;
- it is marked `chunkOnlyNoGrammarExplanation: true`;
- no general `-세요?` rule is introduced from this single expression.

### 4. Formulaic grammar with official support

These retain grammar references:

- `-(으)ㄹ까요?` → official Korean Basic Dictionary
- `-ㄹ게요` → official Korean Basic Dictionary
- `-(으)ㄹ 것 같아요` → official NIKL teacher guide

The learner may use the chunk before learning the full paradigm, but the description of its function comes from official material.

## 1A productive grammar coverage

Officially sourced registry includes, among others:

- `-아/어 주세요`
- `은/는`
- `이/가`
- `을/를`
- `에`
- `에서`
- `(으)로`
- `이다 / 이에요·예요`
- `아니다 / 아니에요`
- `안`
- `있다`
- `무슨`
- `-(으)시-`
- `-(으)ㄹ까요?`
- `-ㄹ게요`
- `-(으)ㄹ 것 같다`
- `-는데요`
- `계시다`
- `-ㄴ지/-은지/-는지`
- `-라고요`

## Evidence separation

### Official grammar
NIKL / Korean Basic Dictionary only.

### Native usage
Naver/news/blog/review/Reddit/community can provide:
- attested wording
- genre
- register
- discourse behavior

but cannot populate grammar definitions.

### Localization
EN/DE equivalents are stored as translation/localization choices and are not presented as Korean grammar definitions.

## Publication gate

No 1A grammar block is publishable unless the official grammar validator passes.

Registry:
`data/ONE_A_OFFICIAL_GRAMMAR_REGISTRY_20261006.json`

Policy:
`GRAMMAR_SOURCE_POLICY_20261006.md`

Validator:
`tools/textbook_project/validate_one_a_official_grammar_sources.py`
