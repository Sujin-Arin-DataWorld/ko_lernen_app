# R5 canonical and standalone final review — 2026-10-22

Independent read-only reviewer checked native hashes, transfer bindings, catalog authority, app reference paths and publication/LFS selection. All 17 promoted native hashes and eight standalone render hashes matched. All 3,952 transferred material slots use existing R5/PAINT R5 references. All original 829/605 meshes were preserved; Sarang reuses the already approved concealed seam backing. The accepted connected Sarang remains cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8.

Reviewer found one P2 display issue: automatic standalone-to-connected switch for an earlier construction stage did not refresh the R5 reference/source metadata. Fixed app.js setStage by calling refreshR5Reference at the switch. Actual browser verification exercised standalone Sarang at stage16, then stage13: variant returned to connected, reference image changed to lookdev-sarang-r5/after-hero.png, and source SHA returned to cab144… . Passed.

Gallery browser verification: 17 entries, all 68 before/after images decoded, all 34 native/receipt links returned HTTP200. Initial split=0 (R5 AFTER only). Standalone Sarang detail and its native link select the current full-roof R5 source. JavaScript syntax and AST parsing of 11 Python files passed.

GLB surfaces and Flutter are explicitly marked not updated. Current human canonical authority is MATERIAL_CANONICAL_PROMOTION_R5.json; historical candidate filenames do not override that manifest.

Publication first preparation stored full LFS bytes, then Git add hit Windows filename length limits. No commit or push occurred in that attempt. Resume uses core.longpaths=true per command, the exact prepared path list, verifies all indexed text/image bytes and LFS pointers/object bytes, and preserves unrelated app checkout WIP. Publication completion is recorded separately after remote SHA verification.
