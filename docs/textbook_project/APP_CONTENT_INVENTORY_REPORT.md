# App Content Inventory Report

Tracked items: **5,961**
Mapped to canonical 32-topic axis: **5,634**
Unmapped / ambiguous: **327**

## Surface counts

| Surface | Actual | Expected | Check | Unmapped |
|---|---:|---:|---|---:|
| live_scenario | 191 | 191 | PASS | 86 |
| canonical_scenario | 120 | 120 | PASS | 49 |
| smalltalk_lesson | 209 | 209 | PASS | 24 |
| listening_lesson | 191 | 191 | PASS | 85 |
| cloze | 2,365 | 2,365 | PASS | 83 |
| sentence_building | 2,885 | 2,885 | PASS | 0 |

## Rule

An automatic topic match is research metadata, not textbook approval.
Items with no confident match keep an explicit unmapped reason and must be reviewed manually.

Outputs:
- docs/textbook_project/data/APP_CONTENT_INVENTORY.csv
- docs/textbook_project/data/APP_CONTENT_INVENTORY_SUMMARY.json
