# tool/ test profile (2026-09-03, Windows, throwaway venv py3.13 + pyyaml)

| Module | Run 1 | Run 2 | Tests |
|---|---|---|---|
| tool.test_release_integrity (R3) | 6.43s | 6.38s | 27 |
| tool.test_android_release_evidence (R4) | 63.54s | 66.86s | 44 |

R4 slowest: test_failed_upload_is_sanitized_and_can_retry_same_files 7.0s, test_receipt_strict_fields_and_types_cannot_open_gate 6.3s, test_timeout_stops_upload_children_not_only_parent 4.7s (intentional 0.5s timeout + 2.2s sleep to prove grandchild kill), test_archived_payload_is_verified_and_different_archive_not_overwritten 4.0s, test_cli_round_trip_and_strict_numeric_inputs 3.4s.
Cause: real interpreter spawns — `_run()` (android_release_evidence.py:211-247) per `_identity()`; `upload_symbols` calls `_identity` up to 3x + `firebase --version` + upload = up to 5 spawns per round-trip test.
Hang risk: none unbounded — `_run` validates 0<timeout<=600 (L214), `process.wait(timeout)` (L230), `_stop_process_tree` (L250: taskkill/killpg + wait(5)), `_receipt_lock` O_EXCL raises receipt_busy immediately (L469-483); worst case ≈ timeout + 5s (Linux).
CI observation: "Asset pipeline gates" tool-test step 5m09s (#256) / 5m21s (#259 run 33776119223); run 33786334363 spent 6 min in checkout/setup on a congested runner and hit the 10-minute job cap.
Follow-up candidate (not in this package): cache bundletool `dump manifest` per fixture or stub Popen in non-lifecycle R4 tests.
