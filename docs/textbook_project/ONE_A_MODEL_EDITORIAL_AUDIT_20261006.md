# Korean 1A Model Editorial Pass — 2026-10-06

Status: **MODEL_EDITORIAL_PASS_COMPLETE_HUMAN_REVIEW_OPEN**

Scope:
- Unit 01
- Unit 02
- Unit 03
- Unit 05
- Unit 06
- Unit 07
- Unit 08

Unit 04 remains the reference vertical slice with its own model editorial audit.

## Quality boundary

Completed:
- model editorial pass;
- contract/load reduction decisions;
- productive vs formulaic vs recognition-only separation;
- EN/DE learner-facing localization architecture;
- native-usage evidence linkage.

Not claimed:
- human Korean educator approval;
- native EN pedagogy approval;
- native DE pedagogy approval;
- adult learner pilot;
- final typography/layout;
- final TTS/audio.

---

## Unit 01 — first greetings and asking again

### Decisions

- Hangul Zero is now an explicit prerequisite.
- `이에요/예요` may appear in authentic airport input, but active copula teaching begins in Unit 02.
- `감사합니다` is treated as **formulaic production**: learners may use the fixed expression without being told they now control the entire 합니다체 system.
- The first unit stays narrow: greeting + short response + one repair request + thanks.

### Why

A first unit should reward successful interaction, not front-load the whole Korean speech-level system.

---

## Unit 02 — name and origin

### Decisions

- Productive learner frame: `어디에서 왔어요?`
- Authentic source may still contain the more socially marked `어디에서 오셨어요?`.
- Origin is taught as `N에서 왔어요`, a useful lexical frame.
- Self-introduction remains a short exchange, not a memorized résumé paragraph.

### Why

This preserves authentic Korean input while keeping active A1 morphology manageable.

---

## Unit 03 — finding something in a shop

### Decisions

- `저기요` promoted to a core service-attention chunk.
- `이/가` now appears in actual learner production:
  - `___가 여기 있어요.`
- `은/는` and `이/가` are taught through context and information structure, not through English-subject or German-case equivalence.

### Why

A unit called topic/subject particles must assess both, but without turning A1 into an abstract linguistics lecture.

---

## Unit 05 — checking time and plans

### Decisions

- Added a dedicated KO/EN/DE **numbers_time_dates native-usage pass**.
- Scheduling is modeled as:
  1. ask;
  2. propose;
  3. confirm/correct;
  4. repeat important information.
- `오후 한 시 어때요?` is formulaic production.
- Delay-message chunks are recycled in Unit 07 instead of overloading the numbers unit.

### Why

Real appointment language is not a number chart. It is negotiation and confirmation.

---

## Unit 06 — transport and directions

### Decisions

Initial draft overloaded:
- 에
- 에서
- (으)로

as simultaneous productive grammar.

Revised:
- **에** = active productive spatial marker;
- `어디서 갈아타요?` = formulaic production;
- full 에서 contrast = recycled later;
- (으)로 is not forced into this unit merely for symmetry;
- `이 버스 ___에 가요?` makes the destination marker explicit.

### Why

A coherent spiral is better than covering the full spatial-particle system in one lesson.

---

## Unit 07 — contact and messaging

### Major architecture improvement

The project now uses three pedagogical layers:

### 1. Productive grammar

The learner can generalize the rule now.

### 2. Formulaic production

The learner may **use the chunk now**, but full grammar analysis is deliberately deferred.

Current Unit 07 formulaic set:
- `-세요?` → 카톡 하세요?
- `-(으)ㄹ까요?` → 카카오톡으로 연락할까요?
- `-ㄹ게요` → 제가 카톡 보낼게요 / 도착하면 연락할게요
- `-(으)ㄹ 것 같아요` → 10분 정도 늦을 것 같아요

### 3. Recognition only

- `-(으)실래요?`

### Why

This solves a recurring textbook problem: a useful real-life sentence should not force the teacher to introduce its entire grammatical paradigm immediately.

---

## Unit 08 — communication repair

### Productive core

- 다시 말씀해 주세요.
- 한 번만 더 말씀해 주세요.
- 천천히 말씀해 주세요.
- 잘 못 들었어요.
- 무슨 뜻이에요?
- 13번이요?

### Recognition / extension

- 뭐라고요?
- 제가 잘 이해한 게 맞아요?
- -는데요
- 계신지
- 몰랐어요
- -ㄹ게요

### Why

The unit now cleanly distinguishes:
- did not hear;
- did not know the meaning;
- wanted confirmation.

Repair becomes a learner-autonomy skill rather than a random phrase list.

---

# System-wide conclusion

The editorial pass confirms an important principle for the whole textbook series:

> **Authentic input complexity and learner production complexity are allowed to be different.**

A natural Korean dialogue does not need to be artificially simplified until every morpheme belongs to the current lesson.

Instead, each item is classified as:

1. productive grammar;
2. formulaic production;
3. recognition/context only.

This framework should be propagated to 1B–6B.

Machine-readable decisions:
`data/ONE_A_MODEL_EDITORIAL_AUDIT_20261006.json`
