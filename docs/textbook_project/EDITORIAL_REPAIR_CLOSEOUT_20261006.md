# Editorial Repair Closeout — 2026-10-06

## Scope

This closes the immediate post-audit sequence:

1. replace 8 rejected derived items;
2. resolve 12 first-pass relevel candidates;
3. directly re-read and resolve all 128 first-pass rewrite rows;
4. materialize replacement textbook content for every remaining rewrite row.

No live app asset was overwritten. All changes are isolated to the textbook publishing layer.

## First pass -> second pass

| Decision | First pass | Second pass | Change |
|---|---:|---:|---:|
| KEEP | 5,813 | **5,914** | +101 |
| REWRITE | 128 | **37** | -91 |
| RELEVEL | 12 | **2** | -10 |
| REJECT | 8 | **8** | originals retired; replacements ready |
| Total | 5,961 | **5,961** | stable |

The 101 rows restored to KEEP were not waived casually. They were closed because the current copy or current level canon showed the old flag was stale, overbroad, sense-confused, or normal spiral recycling.

## Rejected originals: replacement complete

The eight retired rows are two exercise derivatives for each of four invented poetic headwords:

- 말의 자리 -> **발언권**
- 전통의 선택 -> **계승하다**
- 말의 위계 -> **위계적 관계**
- 망각의 예절 -> **회피하다**

New KO/EN/DE cloze + sentence-building replacement concepts are stored in:
`data/TEXTBOOK_REJECT_REPLACEMENTS_20261006.json`

## Relevel: only two actual moves

After direct task-level review:

- `smalltalk.c1.theme_park_date.return`: **C1 -> B2**
- `smalltalk.c2.partner_family.decisions`: **C2 -> C1**

The other ten first-pass candidates remain at their current levels.

Important corrections:
- A1 communication-repair chunks may precede full grammar analysis.
- narrow situational survival vocabulary can be introduced before its general deck level;
- easier vocabulary at a higher level is normal recycling;
- surface string equality does not imply the same sense (`좋아요` adjective vs SNS “Like”).

## Lexical rewrite review

The 46 unique lexical targets behind the old rewrite queue were reviewed individually.

Resolution:
- **28** are legitimate lexemes/collocations/domain terms/pragmatic chunks and remain usable;
- **17** are normalized to more natural/transparent Korean;
- **1** (`사위 사랑`) moves to a culture/pragmatics note rather than a standalone lexical target.

Examples:
- 사진 전송 -> 사진을 보내다
- 선물 분배 -> 선물을 나누다
- 선택 보고 -> 선택적 보고
- 문지기 담론 -> 배타적 팬 담론
- 보이지 않는 일 -> 보이지 않는 노동
- 자동 결정 -> 자동화된 결정
- 호칭의 정치 -> 호칭과 권력 관계
- 일회용 밴드 -> 반창고

The 31 derived exercise rows requiring actual rewrite were materialized as:
- cloze: **13**
- sentence-building: **18**

## Smalltalk rewrite review

28 first-pass smalltalk rewrite flags were re-read against current copy:
- **26 KEEP** — the historical note described an already-applied repair or a nonblocking teaching note.
- **2 REWRITE**:
  1. `smalltalk.b2.phone.complaint`: remove invented universal appeal deadline/process.
  2. `smalltalk.b2.partner_family.schedule`: neutralize the core from 시댁/친정 to 배우자 가족/제 가족; teach 시댁/친정 as perspective-specific culture/pragmatics vocabulary.

KO/DE/EN replacement copy is materialized.

## Scenario/listening rewrite review

13 newer scenario roots were directly re-read:
- **11 KEEP**
- **2 REWRITE**
  1. `a1_message_contact_after_class_2026`: remove unreliable display-name-search contact mechanic.
  2. `c2_public_redress_briefing_2026`: replace generic procedural claims with source-bounded language tied to the individual notice/current institutional guidance.

The two linked listening lessons were also rebuilt, producing **4 scenario/listening rewrite rows** total.

## Rewrite materialization coverage

All **37 / 37** second-pass REWRITE rows now have prepared textbook-facing replacement content:

- lexical materialized: 31
- smalltalk override: 2
- scenario override: 2
- listening override: 2

Unprepared rewrite rows: **0**

All **8 / 8** REJECT originals have prepared replacement concepts.

Coverage and SHA-256 are recorded in:
`data/TEXTBOOK_OVERRIDE_MANIFEST_20261006.json`

## Validation

Passed:
- override coverage: 37/37
- reject replacement coverage: 8/8
- second-pass regression
- first-pass regression
- 5,961-item inventory regression
- content validation

## Next publishing phase

The urgent repair queues are now closed for the textbook track.

Next:
1. allocate the resolved 5,961-item source pool into 1A–6B book/unit structure;
2. preserve recycling instead of forcing each item into only one appearance;
3. create book-level core vs recycling vs optional/trend/culture roles;
4. audit unit load against Level Bible ceilings;
5. then start the 1A pilot authoring/print layout from the resolved pool.
