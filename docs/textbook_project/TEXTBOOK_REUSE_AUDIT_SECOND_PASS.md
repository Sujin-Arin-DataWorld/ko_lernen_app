# Textbook Reuse Audit — Second Pass Resolution

Date: 2026-10-06

Total rows resolved: **5,961**

## Final second-pass decisions

| Decision | Count |
|---|---:|
| KEEP | 5,914 |
| REWRITE | 37 |
| RELEVEL | 2 |
| REJECT | 8 |

## What changed from first pass

- First-pass false positives closed into KEEP: **101**
- Actual rewrite rows with prepared textbook overrides: **37**
- Actual level moves: **2**
- Retired original rows with replacement concepts ready: **8**

## Key rules confirmed

- Historical audit notes do not override current repaired copy.
- A phrase is not rejected merely because it is multiword.
- Lexical string equality does not imply sense identity.
- A1 survival chunks and narrow situational vocabulary may precede the general deck level.
- Easier vocabulary at a higher level is normal spiral recycling.
- App live assets were not overwritten; textbook overrides are maintained separately.

## Override sources

- data/TEXTBOOK_REJECT_REPLACEMENTS_20261006.json
- data/TEXTBOOK_LEXICAL_OVERRIDES_20261006.json
- data/TEXTBOOK_SMALLTALK_OVERRIDES_20261006.json
- data/TEXTBOOK_SCENARIO_OVERRIDES_20261006.json
- data/TEXTBOOK_RELEVEL_RESOLUTION_20261006.csv
