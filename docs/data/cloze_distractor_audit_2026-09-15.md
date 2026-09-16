# Cloze distractor hygiene audit -- 2026-09-15 (C2c)

Live corpus: `assets/data/cloze.json`, 2215 items, 6 levels. Rules D1-D6 per `tools/content_factory/cloze_distractor_rules.py`. D5 is detection only (needs a human/LLM read); D7 is the umbrella judgement rule, not separately audited.

**Total items with >=1 mechanical (D1/D2/D3/D4/D6) violation: 0**

D3 answer POS unresolved by the suffix-stripping heuristic (not flagged, excluded from D3): 103

## Counts per rule per level

| level | D1 | D2 | D3 | D4 | D5_open_slot(detect-only) | D6_exposed | D6_duplicate | D6_equals_answer | items |
|---|---|---|---|---|---|---|---|---|---|
| a1 | 0 | 0 | 0 | 0 | 63 | 0 | 0 | 0 | 590 |
| a2 | 0 | 0 | 0 | 0 | 22 | 0 | 0 | 0 | 275 |
| b1 | 0 | 0 | 0 | 0 | 19 | 0 | 0 | 0 | 436 |
| b2 | 0 | 0 | 0 | 0 | 27 | 0 | 0 | 0 | 414 |
| c1 | 0 | 0 | 0 | 0 | 6 | 0 | 0 | 0 | 250 |
| c2 | 0 | 0 | 0 | 0 | 8 | 0 | 0 | 0 | 250 |
| **all** | 0 | 0 | 0 | 0 | 145 | 0 | 0 | 0 | 2215 |

## D6 reuse-cap violations (>6 uses of one distractor word within a level)

- a1: `가끔` used 10x
- a1: `가다` used 12x
- a1: `고르다` used 13x
- a1: `과` used 9x
- a1: `끝나다` used 13x
- a1: `다니다` used 17x
- a1: `돕다` used 10x
- a1: `랑` used 10x
- a1: `마셔요` used 9x
- a1: `먹다` used 11x
- a1: `먹어요` used 8x
- a1: `모르다` used 13x
- a1: `보다` used 12x
- a1: `빌리다` used 13x
- a1: `빨리` used 9x
- a1: `소포` used 9x
- a1: `쓰다` used 15x
- a1: `알다` used 11x
- a1: `에게` used 9x
- a1: `에서` used 16x
- a1: `여기` used 8x
- a1: `오다` used 16x
- a1: `와` used 13x
- a1: `우표` used 12x
- a1: `으로` used 7x
- a1: `이름` used 7x
- a1: `읽다` used 17x
- a1: `읽어요` used 16x
- a1: `입다` used 8x
- a1: `자다` used 12x
- a1: `책상` used 10x
- a1: `타다` used 13x
- a1: `팔다` used 18x
- a1: `편지` used 9x
- a1: `학교` used 7x
- a1: `한테` used 11x
- a1: `항상` used 10x
- a2: `계산대` used 7x
- a2: `러닝머신` used 13x
- a2: `승강장` used 7x
- a2: `에게` used 9x
- a2: `연고` used 7x
- a2: `운동복` used 13x
- a2: `읽다` used 8x
- a2: `출구` used 8x
- a2: `커트` used 8x
- a2: `헬스장` used 10x
- a2: `환승` used 7x
- b1: `공과금 정산` used 8x
- b1: `공용 선반` used 8x
- b1: `교차로` used 7x
- b1: `끝나다` used 8x
- b1: `랑` used 9x
- b1: `보관함` used 7x
- b1: `보안카드` used 8x
- b1: `복도` used 7x
- b1: `부스` used 7x
- b1: `상담 시간` used 7x
- b1: `습득하다` used 8x
- b1: `시급` used 8x
- b1: `알림장` used 7x
- b1: `야간수당` used 9x
- b1: `와` used 9x
- b1: `이웃집` used 7x
- b1: `이체하다` used 10x
- b1: `인증서` used 7x
- b1: `입주민` used 8x
- b1: `청소 당번` used 8x
- b1: `초인종` used 8x
- b1: `학부모 면담` used 7x
- b2: `내용증명` used 7x
- b2: `발언권` used 7x
- c1: `권고` used 8x
- c1: `선별` used 8x
- c1: `위임` used 7x
- c1: `편향` used 7x
- c2: `구제` used 7x
- c2: `변경 이력` used 9x
- c2: `시정` used 7x
- c2: `우세` used 8x
- c2: `적발` used 9x
- c2: `접근 기록` used 9x
- c2: `정당화` used 7x
- c2: `추적 가능성` used 9x

## Flagged item list (mechanical, D1/D2/D3/D4/D6)


## D5 open-slot items (need human/LLM read, step 2)

Total: 145

- a1 (63): cloze_a1_0008, cloze_a1_0009, cloze_a1_0013, cloze_a1_0018, cloze_a1_0021, cloze_a1_0022, cloze_a1_0031, cloze_a1_0038, cloze_a1_0040, cloze_a2_0005, cloze_a1_0066, cloze_a1_0070, cloze_a1_0079, cloze_a1_0080, cloze_a1_0082, cloze_a1_0088, cloze_a1_0090, cloze_a1_0092, cloze_a1_0098, cloze_a1_0099, cloze_a1_0313, cloze_a1_0320, cloze_a1_0331, cloze_a1_0333, cloze_a1_0343, cloze_a1_0355, cloze_a1_0365, cloze_a1_0369, cloze_a1_0398, cloze_a1_0399, cloze_a1_0424, cloze_a1_0435, cloze_a1_0436, cloze_a1_0443, cloze_a1_0453, cloze_a1_0459, cloze_a1_0474, cloze_a1_0480, cloze_a1_0485, cloze_a1_0494, cloze_a1_0496, cloze_a1_0501, cloze_a1_0503, cloze_a1_0506, cloze_a1_0509, cloze_a1_0519, cloze_a1_0521, cloze_a1_0526, cloze_a1_0534, cloze_a1_0544, cloze_a1_0548, cloze_a1_0549, cloze_a1_0562, cloze_a1_0574, cloze_a1_0593, cloze_a1_0619, cloze_a1_0621, cloze_a1_0632, cloze_a1_0638, cloze_a1_0640, cloze_a1_0706, cloze_a1_0708, cloze_a1_0709
- a2 (22): cloze_a2_0007, cloze_a2_0018, cloze_a2_0020, cloze_a2_0022, cloze_a2_0030, cloze_a2_0032, cloze_a2_0034, cloze_a2_0037, cloze_a2_0046, cloze_a2_0056, cloze_a2_0057, cloze_a2_0058, cloze_a2_0059, cloze_a2_0064, cloze_a2_0074, cloze_a1_0214, cloze_a1_0217, cloze_a1_0244, cloze_a1_0257, cloze_a2_0215, cloze_a2_0292, cloze_a2_0302
- b1 (19): cloze_b1_0007, cloze_b1_0008, cloze_b1_0009, cloze_b1_0020, cloze_b1_0028, cloze_b1_0030, cloze_b1_0050, cloze_b1_0052, cloze_a1_0120, cloze_a1_0183, cloze_a1_0213, cloze_a1_0241, cloze_a2_0221, cloze_a2_0246, cloze_a2_0257, cloze_b1_0230, cloze_b1_0245, cloze_b1_0255, cloze_b1_0277
- b2 (27): cloze_b2_0002, cloze_b2_0007, cloze_b2_0033, cloze_b2_0034, cloze_b2_0054, cloze_b2_0059, cloze_b2_0087, cloze_b2_0089, cloze_b2_0090, cloze_b2_0091, cloze_b2_0099, cloze_b2_0108, cloze_b2_0109, cloze_b2_0111, cloze_b2_0113, cloze_b2_0114, cloze_b2_0124, cloze_b2_0127, cloze_b2_0132, cloze_b2_0163, cloze_b2_0227, cloze_b1_0220, cloze_b2_0288, cloze_b2_0332, cloze_b2_0363, cloze_b2_0395, cloze_b2_0400
- c1 (6): cloze_c1_0100, cloze_c1_0128, cloze_c1_0151, cloze_c1_0159, cloze_c1_0164, cloze_c1_0168
- c2 (8): cloze_c2_0026, cloze_c2_0030, cloze_c2_0032, cloze_c2_0092, cloze_c2_0099, cloze_c2_0149, cloze_c2_0156, cloze_c2_0166

