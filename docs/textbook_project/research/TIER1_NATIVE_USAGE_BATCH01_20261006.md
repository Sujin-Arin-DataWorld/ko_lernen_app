# Tier 1 Native-Usage Research — Batch 01

Date: 2026-10-06

Scope:
- family_relationships
- house_home
- food_drink

This is the first **evidence pack** for the textbook/native-usage layer. It does not directly overwrite the canonical 32-topic registry. Promotion comes only after the evidence pack passes validation and editorial review.

## Completion criteria used

Per topic and per language:
- at least 3 source contexts;
- at least 8 normalized usage patterns;
- at least 2 register lanes;
- at least 1 translationese warning;
- spoken/display note where chat-only behavior matters.

All three topics meet the broad-pass threshold in KO, EN and DE.

## What this batch adds

### Family & relationships
The central cross-language issue is not vocabulary but **how boundaries and rescheduling are softened**.

Korean frequently does pragmatic work through omission, endings and phrases such as:
- 오늘은 좀 쉬고 싶어.
- 이번에는 좀 어려울 것 같아.
- 다음에 보자.
- 조금 생각할 시간이 필요해.

English commonly lexicalizes the boundary more explicitly:
- I need some space.
- I need some time to myself.
- Sorry, I can't make it.
- Maybe next time.

German similarly favors explicit propositions:
- Ich brauche etwas Zeit für mich.
- Ich brauche gerade ein bisschen Freiraum.
- Ich muss leider absagen.
- Lass uns das nächste Woche machen.

Pedagogical consequence: do not teach one dictionary mapping for `거리/공간/시간이 필요하다`; teach relationship intensity and speech-act function.

### House & home
The key category shift is **who the responsible building actor is**.

Korean:
- 관리실 / 관리사무소
- 집주인
- 수리 기사
- 연락하다 / 문의하다 / 수리 요청하다

English may require:
- maintenance
- apartment office
- property manager / property management
- landlord

German may require:
- Hausverwaltung
- Vermieter/Vermieterin
- Hausmeister
- Handwerker/Fachfirma

Pedagogical consequence: never translate `관리실` mechanically. The learner needs a role map.

### Food & drink
All three languages have short natural order formulas, but the grammar differs.

Korean:
- 아메리카노 한 잔 주세요.
- 이거 하나 주세요.
- 포장해 주세요.
- 덜 맵게 해 주세요.

English:
- Can I get ...?
- Could I please get ...?
- I'll have ... please.
- Could I get that to go?

German:
- Ich hätte gern ...
- Einmal ..., bitte.
- Ich nehme ...
- Zum Mitnehmen, bitte.

Pedagogical consequence: `주세요` should not be taught as a single fixed translation. English and German need several natural request frames by register and setting.

## Surface/TTS note

The batch inherits the project-wide rule:

**display surface != spoken surface != performance cue**

Examples:
- KO `ㅋㅋ/ㅎㅎ`
- EN `lol/lmao`
- DE typed reaction spellings / emoji

These can mark stance in chat while remaining absent from spoken/TTS text.

## Evidence caution

Community sources are evidence for wording, collocation, tone and register—not for legal/medical/safety claims.

Housing sources are therefore used only to identify naturally recurring language such as:
- report the damage;
- contact management;
- ask for an update;
- describe a leak;
- document with photos.

They are not treated as legal authority.

## Files

Machine-readable evidence:
`research/TIER1_NATIVE_USAGE_BATCH01_20261006.json`

Validator:
`tools/textbook_project/validate_tier1_native_usage_batch.py`

## Next batch

Recommended Tier 1 continuation:
1. shopping_consumption
2. transport_wayfinding
3. health_body
4. work_career

High-risk factual domains such as health, contracts and public administration should pair community wording with authoritative terminology sources.
