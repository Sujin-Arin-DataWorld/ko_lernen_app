# CP2026 portable evidence snapshot

This directory travels with the Git checkout on macOS, Windows and Linux. It is the
portable evidence root **E** used by [the handover](../../CP2026_HANDOVER_20260925.md).
The legacy **A** paths refer to the original Windows archive, not a required local
checkout path. Files here are historical observations, not assertions about a
later release or later main.

The local `.gitattributes` fixes LF line endings in this evidence directory.
The manifest records both original source hashes and portable receipt hashes;
line-ending normalization is recorded separately from any selected-field copy.

- `pr412` through `pr416`, plus `pr424`, `pr425` and `pr426`, merge preflight/proof files bind the PR HEAD, base,
  review-thread gate, squash SHA and equal trees. `mainN-live.json` records the
  exact merged SHA's **push** CI and Playwright, including GitHub URLs. Read the
  `gateCompleted` field: a running receipt does not establish a successful gate.
- `pr426-native-success.json` records three passing RunnerTests and the verified
  artifact/log digests for PR HEAD `7854e3ff`. Its ZIP/log filenames refer to the
  original archive A; the raw files are not copied here. The receipt links the
  run by ID; it does not prove the later merged-main result.
- `final-content-coverage.json` is the audit rerun after #416. Denominator repair
  adds neither content nor human approvals.
- `public-test-preflight.json` observes the **old Android 7680** open-test release.
  The Android/iOS publication receipts describe the earlier 7680/254 distributions.
  Their nested local log references were not copied; these are observation receipts,
  not a complete raw console/log archive. These receipts do not prove installation
  or functional verification on a device.
- `release-coordination.json` contains the confirmed authorization scope with the
  private session transcript path removed and the original receipt digest retained.
- `main411-live.json` records the successful retried #411 main gate.
- `website-log-92d28823-findings.md` separates the failed website verification,
  rollback and successful retry; the small retry verification output is included.
- `review-checklist-snapshot.md` carries the dated C01–C09, D01–D08 and L01–L03
  instructions. Candidate content linked by local paths is still archive-only.

## Verification from any checkout

Run from this directory (no third-party packages):

```sh
python3 -c "import hashlib,json,pathlib; p=pathlib.Path('.'); m=json.loads((p/'manifest.json').read_text()); assert all(hashlib.sha256((p/r['file']).read_bytes()).hexdigest()==r['sha256'] for r in m['files']); print('all receipt hashes match')"
```

GitHub Actions URLs in the receipts allow repository collaborators to recheck the
source evidence. Hashes establish copy integrity, not independent console truth.
For a newer SHA or current store availability, rerun the relevant check.

## Deliberately unfinished / archive-only material

The #425 handover, #424 Pad 6 changes and #426 Java release-input repair have been
merged. Their exact-head and merged-main results are kept distinct in the receipts.
This documentation correction's merge, the new Android release and final cleanup
decision happen after this snapshot. No future completion receipt is asserted here.
The [#425 closing description](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/pull/425)
will link the actual final PR/Actions/Play Console evidence. Four worktrees were
removed by this session; the #416 post-check limitation and the two held worktrees
are explained in the dated handover. These observations do not authorize removal.

Large Graphify originals, ignored files, user review packets, source media, raw
console logs and local draft candidates remain in A. They are not included or
claimed accessible on another machine. To resume work that requires those bytes,
first copy the relevant archive from the original host and verify its preservation
manifest; if unavailable, mark that evidence missing and regenerate/audit from source.
Do not delete another worktree using this historical snapshot. A fresh filesystem,
process, ownership and byte-preservation audit on its actual host is mandatory.
