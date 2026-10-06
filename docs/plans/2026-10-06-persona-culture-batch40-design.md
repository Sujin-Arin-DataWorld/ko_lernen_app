# Batch 40 — social-language and everyday-culture expansion

> Status: review-only authoring design. No live promotion, mastery, reward, or TTS change.

## Goal

Expand the culture world through everyday Korean social life and practical use.

Batch 40 follows the Batch 39 editorial rule:

```text
real situation
  -> natural dialogue
  -> key vocabulary extraction
  -> CEFR/live-vocab audit
  -> glossary support
  -> listening
  -> integration preview
  -> human review
```

Do not start from a culture definition and invent a scene around it.

## Scene set

| ID | Level | People | Real task | Culture terms |
| --- | --- | --- | --- | --- |
| `b1_jun_coding_club_speech_switch` | B1 | Jun + student(support) | coding-club senior says they can speak more casually; Jun confirms how to address the senior and what speech level is comfortable | `sunbae_hubae`, `jondaetmal_banmal` |
| `b1_minho_coworker_hoesik_leave_early` | B1 | Minho + coworker(support) | coworker says they must leave the team dinner early; Minho confirms timing without pressuring attendance | `hoesik` |
| `a2_dongsun_christian_maehwa_gift` | A2 | Christian × Dongsun | Christian chooses a small gift for Sujin in Dongsun's shop and asks about a plum-blossom motif | `maehwa` |
| `b1_dongsun_customer_maedeup_repair` | B1 | Dongsun + customer(support) | a customer brings in an item with a loosened decorative knot; Dongsun clarifies what she can and cannot repair | `maedeup` |
| `b1_byeongcheol_hyuna_daecheong_rest` | B1 | Hyuna × Byeongcheol | while visiting an old house, they sit briefly in the daecheong and talk about the airflow and the sign they just read | `daecheong` |

## Why these scenes

### Jun — school relationship language, not a lecture

The learner sees the social-language culture through an actual club interaction:
- same club,
- older student,
- how to address the other person,
- whether switching to banmal is comfortable.

Rules:
- "sunbae" is not automatic authority;
- being older or senior does not automatically authorize banmal;
- the characters explicitly negotiate speech style;
- Jun remains a sixteen-year-old first-year high-school student.

### Minho — workplace boundary-setting

Hoesik is used as a real scheduling problem, not as "Korean people always drink after work."

Rules:
- coworker can leave early;
- Minho is a team lead but does not pressure attendance;
- no alcohol requirement;
- no stereotype that hoesik is mandatory;
- organization-specific norms remain variable.

### Dongsun × Christian — small gift, real shop

Christian does not go to a "traditional culture store."
He is in Dongsun's normal jewellery/repair shop and notices a small plum-blossom motif.

Rules:
- Dongsun may identify a motif, but she is not rewritten as an art historian;
- Christian asks about suitability and Sujin's taste;
- the scene stays focused on choosing a gift.

### Dongsun + customer — repair scope

Maedeup appears because a decorative knot has loosened.

Rules:
- Dongsun can repair or re-tie only what fits her shop's actual scope;
- she does not claim to be a designated traditional maedeup craft master;
- if a repair exceeds her scope, she says so clearly;
- the task is service communication.

### Byeongcheol × Hyuna — space through observation

They visit an old house open to visitors and sit in the daecheong after walking.

Rules:
- neither character invents architectural history;
- the term is visible on a sign/guide, so no one has to pretend expertise;
- Byeongcheol can notice airflow/structure from practical experience;
- Hyuna can connect the sign to the space without becoming a universal culture narrator.

## Course alignment

| Scene | Unit | Concept | Grammar |
| --- | --- | --- | --- |
| Jun / coding club | `b1_04_relationships` | `concept_b1_relationships` | `grammar_a2_permission` |
| Minho / hoesik | `b1_04_relationships` | `concept_b1_relationships` | `grammar_b1_background_contrast` |
| Dongsun / maehwa gift | `a2_01_haeyo_transition` | `concept_action_polite` | `grammar_a2_preference_soft_batch20` |
| Dongsun / maedeup repair | `b1_03_work_softening` | `concept_b1_softening` | `grammar_b1_background_contrast` |
| Byeongcheol / daecheong | `b1_01_experience_reasons` | `concept_b1_reasons_experience` | `grammar_b1_as_kept_doing` |

Lower-level grammar inside a B1 scenario is intentional when it is the most natural form for the task.

## Shelf / backdrop plan

| Scene | Shelf | Backdrop |
| --- | --- | --- |
| Jun / coding club | `b1_friends` | `office` |
| Minho / hoesik | `b1_team` | `restaurant` |
| Dongsun / maehwa gift | `a2_buy` | `market` |
| Dongsun / maedeup repair | `b1_repair` | `market` |
| Byeongcheol / daecheong | `b1_neighbor` | `home` |

## Story-arc draft

### `relationship_language_in_daily_life`

Steps:
1. Jun + club senior — `sunbae_hubae`, `jondaetmal_banmal`
2. Minho + coworker — `hoesik`

Theme:
- social relationship language,
- negotiated boundaries,
- practical scheduling,
- no hierarchy stereotype.

### `patterns_repairs_and_spaces`

Steps:
1. Christian + Dongsun — `maehwa`
2. Dongsun + customer — `maedeup`
3. Hyuna + Byeongcheol — `daecheong`

Theme:
- culture encountered through an object, repair, and space already in use.

Both arcs remain `derived_read_only` and own no mastery/reward/progress.

## Non-goals

- no new top-level culture subsystem;
- no culture-specific persistence ledger;
- no forced heritage exposition;
- no TTS generation;
- no automatic live-vocab mutation;
- no new recurring persona;
- no promotion before learner-facing review.
