# Cloze distractor hygiene audit -- 2026-09-15 (C2c)

Live corpus: `assets/data/cloze.json`, 1959 items, 6 levels. Rules D1-D6 per `tools/content_factory/cloze_distractor_rules.py`. D5 is detection only (needs a human/LLM read); D7 is the umbrella judgement rule, not separately audited.

**Total items with >=1 mechanical (D1/D2/D3/D4/D6) violation: 0**

D3 answer POS unresolved by the suffix-stripping heuristic (not flagged, excluded from D3): 73

## Counts per rule per level

| level | D1 | D2 | D3 | D4 | D5_open_slot(detect-only) | D6_exposed | D6_duplicate | D6_equals_answer | items |
|---|---|---|---|---|---|---|---|---|---|
| a1 | 0 | 0 | 0 | 0 | 32 | 0 | 0 | 0 | 331 |
| a2 | 0 | 0 | 0 | 0 | 23 | 0 | 0 | 0 | 276 |
| b1 | 0 | 0 | 0 | 0 | 19 | 0 | 0 | 0 | 436 |
| b2 | 0 | 0 | 0 | 0 | 27 | 0 | 0 | 0 | 416 |
| c1 | 0 | 0 | 0 | 0 | 6 | 0 | 0 | 0 | 250 |
| c2 | 0 | 0 | 0 | 0 | 8 | 0 | 0 | 0 | 250 |
| **all** | 0 | 0 | 0 | 0 | 115 | 0 | 0 | 0 | 1959 |

## D6 reuse-cap violations (>6 uses of one distractor word within a level)

- a1: `뒤` used 8x
- a1: `마셔요` used 8x
- a1: `먹어요` used 7x
- a1: `소포` used 9x
- a1: `여기` used 7x
- a1: `오른쪽` used 8x
- a1: `우표` used 12x
- a1: `이름` used 7x
- a1: `읽어요` used 15x
- a1: `편지` used 9x
- a2: `계산대` used 8x
- a2: `러닝머신` used 13x
- a2: `마스크` used 7x
- a2: `승강장` used 9x
- a2: `연고` used 7x
- a2: `운동복` used 12x
- a2: `출구` used 9x
- a2: `커트` used 9x
- a2: `헬스장` used 10x
- a2: `환승` used 9x
- b1: `가능성` used 7x
- b1: `고장 부위` used 7x
- b1: `공과금 정산` used 8x
- b1: `공용 선반` used 8x
- b1: `데이터량` used 7x
- b1: `배정표` used 7x
- b1: `보관함` used 7x
- b1: `보안카드` used 8x
- b1: `보장 범위` used 7x
- b1: `복도` used 8x
- b1: `봉사 시간` used 7x
- b1: `부스` used 8x
- b1: `부품 교체` used 7x
- b1: `사고 접수` used 7x
- b1: `사전 교육` used 8x
- b1: `상담 시간` used 8x
- b1: `습득하다` used 7x
- b1: `시급` used 8x
- b1: `알림장` used 9x
- b1: `야간수당` used 9x
- b1: `이웃집` used 7x
- b1: `이체하다` used 7x
- b1: `인증서` used 7x
- b1: `일정 변경` used 8x
- b1: `입주민` used 8x
- b1: `청소 당번` used 8x
- b1: `초인종` used 8x
- b1: `출장 수리` used 7x
- b1: `학부모 면담` used 8x
- b1: `환불 규정` used 9x
- b1: `회신 기한` used 8x
- b2: `개선 과제` used 7x
- b2: `구비 서류` used 7x
- b2: `내용증명` used 10x
- b2: `목표 대비` used 7x
- b2: `민원실` used 8x
- b2: `발언권` used 10x
- b2: `상위 담당` used 7x
- b2: `성과 면담` used 7x
- b2: `약속 불이행` used 7x
- b2: `원문 대조` used 7x
- b2: `접수증` used 8x
- b2: `주민 의견` used 7x
- b2: `핵심 조건` used 7x
- b2: `후원 표시` used 7x
- c1: `권고` used 7x
- c1: `녹지 보전` used 8x
- c1: `상대 위험` used 7x
- c1: `선별` used 8x
- c1: `완화` used 7x
- c1: `위임` used 7x
- c1: `유지 부담` used 8x
- c1: `잔여 위험` used 7x
- c1: `접근 비용` used 8x
- c1: `지역 여건` used 7x
- c2: `구제` used 7x
- c2: `동의 철회` used 7x
- c2: `변경 이력` used 9x
- c2: `서술 시점` used 7x
- c2: `선택적 기억` used 7x
- c2: `시정` used 8x
- c2: `우세` used 8x
- c2: `적발` used 7x
- c2: `접근 기록` used 9x
- c2: `정당화` used 7x
- c2: `추적 가능성` used 9x
- c2: `파생 데이터` used 7x

## Flagged item list (mechanical, D1/D2/D3/D4/D6)


## D5 open-slot items (need human/LLM read, step 2)

Total: 115

- a1 (32): cloze_a1_0008, cloze_a1_0009, cloze_a1_0013, cloze_a1_0018, cloze_a1_0021, cloze_a1_0022, cloze_a1_0031, cloze_a1_0038, cloze_a1_0040, cloze_a1_0066, cloze_a1_0070, cloze_a1_0079, cloze_a1_0080, cloze_a1_0082, cloze_a1_0088, cloze_a1_0090, cloze_a1_0092, cloze_a1_0098, cloze_a1_0099, cloze_a1_0313, cloze_a1_0333, cloze_a1_0343, cloze_a1_0355, cloze_a1_0365, cloze_a1_0369, cloze_a1_0398, cloze_a1_0399, cloze_a1_0424, cloze_a1_0435, cloze_a1_0436, cloze_a1_0443, cloze_a1_0453
- a2 (23): cloze_a2_0005, cloze_a2_0007, cloze_a2_0018, cloze_a2_0020, cloze_a2_0022, cloze_a2_0030, cloze_a2_0032, cloze_a2_0034, cloze_a2_0037, cloze_a2_0046, cloze_a2_0056, cloze_a2_0057, cloze_a2_0058, cloze_a2_0059, cloze_a2_0064, cloze_a2_0074, cloze_a1_0214, cloze_a1_0217, cloze_a1_0244, cloze_a1_0257, cloze_a2_0215, cloze_a2_0292, cloze_a2_0302
- b1 (19): cloze_b1_0007, cloze_b1_0008, cloze_b1_0009, cloze_b1_0020, cloze_b1_0028, cloze_b1_0030, cloze_b1_0050, cloze_b1_0052, cloze_a1_0120, cloze_a1_0183, cloze_a1_0213, cloze_a1_0241, cloze_a2_0221, cloze_a2_0246, cloze_a2_0257, cloze_b1_0230, cloze_b1_0245, cloze_b1_0255, cloze_b1_0277
- b2 (27): cloze_b2_0002, cloze_b2_0007, cloze_b2_0033, cloze_b2_0034, cloze_b2_0054, cloze_b2_0059, cloze_b2_0087, cloze_b2_0089, cloze_b2_0090, cloze_b2_0091, cloze_b2_0099, cloze_b2_0108, cloze_b2_0109, cloze_b2_0111, cloze_b2_0113, cloze_b2_0114, cloze_b2_0124, cloze_b2_0127, cloze_b2_0132, cloze_b2_0163, cloze_b2_0227, cloze_b1_0220, cloze_b2_0288, cloze_b2_0332, cloze_b2_0363, cloze_b2_0395, cloze_b2_0400
- c1 (6): cloze_c1_0100, cloze_c1_0128, cloze_c1_0151, cloze_c1_0159, cloze_c1_0164, cloze_c1_0168
- c2 (8): cloze_c2_0026, cloze_c2_0030, cloze_c2_0032, cloze_c2_0092, cloze_c2_0099, cloze_c2_0149, cloze_c2_0156, cloze_c2_0166


## Second QA follow-up: headword+particle-fold allomorph check

PR #344 (merged to origin/main mid-sweep, "content(c3): Batch 28 A1
reinforcement... particle-form and activity-noun distractor rules")
landed `a1_draft_rules.distractor_particle_mismatches` -- a more complete
D2 check than this sweep's own `matching_particle_suffix`: it also covers
answers that are a headword + an ALTERNATING particle fold (e.g. "책이",
"오늘은", "커피는"), requiring each distractor to carry the ALLOMORPH
correct for ITS OWN batchim (not literally the same suffix text). Rerunning
that official function against the full post-sweep corpus (excluding
`PREDICATE_SLOT_WAIVER` items, which are correctly exempt) found 3
remaining genuine violations, all pre-existing (not introduced by this
sweep) except `cloze_a1_0314`'s "가방이", which WAS introduced by this
sweep's own D7 hand-patch a few paragraphs above: `cloze_a1_0308`
("오늘을" wrong particle entirely), `cloze_a1_0313` (all 3 distractors were
the SAME headword "책" with a different particle -- a severe form leak),
`cloze_a1_0314` ("가방이" using the wrong particle). All 3 fixed; rerunning
both this sweep's own audit and the official corpus-wide
`distractor_particle_mismatches` scan now report 0 violations. Final total
items changed: **502**.
