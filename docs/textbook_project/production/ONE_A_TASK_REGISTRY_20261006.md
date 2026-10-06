# Korean 1A Stable Task Registry — 2026-10-06

Status: **MODEL_REVIEWED_STABLE_TASK_IDS**

## Result

Stable task IDs: **190**

Breakdown:
- 8 units × 20 task blocks = **160**
- 4 pair reviews × 6 tasks = **24**
- final transfer review = **6**

## ID rule

Examples:
- `1A.U01.SB.T01` — Unit 01 student-book task 01
- `1A.U04.WB.T08` — Unit 04 workbook delayed-retrieval task
- `1A.R34.RV.T05` — Units 3–4 review interaction task
- `1A.FINAL.RV.T03` — final transfer-review task

The task ID does **not** contain a physical page number.

Page placement is stored separately in:
`plannedPageSlot`

Therefore a layout shift from page 13 to page 14 does not break:
- answer keys;
- learner-pilot logs;
- app links;
- analytics;
- teacher records.

## Standard per-unit task inventory

### Student book — 11 tasks
1. scene meaning
2. core-chunk noticing
3. controlled form
4. native-use / transfer contrast
5. pronunciation
6. listening
7. reading
8. guided speaking
9. short writing
10. interaction
11. exit retrieval

### Workbook — 9 tasks
1. meaning/function
2. rebuild chunk
3. controlled variation
4. recognition-only check
5. listening grid
6. L1 transfer diagnostic
7. free interaction
8. delayed retrieval
9. self-check

## Review tasks

Each pair review contains:
- deterministic closed tasks;
- one integrated productive task;
- one retrieval/transfer task.

The final review deliberately removes unit labels.

## Page map

Machine-readable registry:
`ONE_A_TASK_REGISTRY_20261006.json`

Production-friendly flat map:
`ONE_A_PAGE_TASK_MAP_20261006.csv`

Task schema:
`schemas/TASK_REGISTRY_ENTRY.schema.json`

## Stability rule

Once a task ID has appeared in:
- a pilot log;
- an answer key;
- a published print edition;
- app analytics;

it must never be silently reassigned to a different pedagogical task.

If the task changes materially:
- create a new task ID;
- deprecate the old one;
- retain migration metadata.
