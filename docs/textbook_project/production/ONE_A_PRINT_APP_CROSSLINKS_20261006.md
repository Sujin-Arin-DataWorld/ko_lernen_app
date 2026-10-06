# Korean 1A Print ↔ App Cross-links — 2026-10-06

Status: **CONTENT_IDS_VERIFIED_APP_ROUTE_PENDING**

## Result

Generated cross-links: **29**

Every 1A unit has:
- 1 core-dialogue link;
- 1 listening link;
- 1 recycling/practice link.

Some units also have optional extension links.

## Rule

The book must remain usable without the app.

Therefore:
- a QR code is never required to understand the core dialogue;
- an app link is never required to perform the printed Can-do;
- audio can be distributed through the app, but the printed task/transcript remains understandable;
- extension content is optional.

## Current resolver

The map stores **stable content IDs**, not invented routes.

Current mode:

`CONTENT_ID_LOOKUP`

The Flutter/app layer should later resolve those IDs to the current route/screen.

No fake deep link was added.

## Roles

### core_dialogue
The canonical/live scenario anchoring the printed unit.

### listening
The matching listening asset.

### recycling
A small set of existing cloze/sentence-building items that can support app practice.

These are app-practice links, not automatic print-selection decisions.

### extension
Optional extra scene/content for learners who want more practice.

## Version rule

If app IDs or routes change:

1. regenerate the cross-link map;
2. validate all IDs;
3. verify routes in Flutter;
4. only then change status to `app_route_verified`.

Machine-readable map:

`ONE_A_PRINT_APP_CROSSLINKS_20261006.json`

Generator:

`tools/textbook_project/build_one_a_print_app_crosslinks.py`
