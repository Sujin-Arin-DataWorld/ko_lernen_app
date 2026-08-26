# Pre-V3 Hanok asset archive (2026-08-26)

This branch is an archival snapshot, not a Flutter runtime asset source.

## Contents

- `l/`: 37 Hanok-related files recovered from the former local-main WIP archive. Buckets `a`, `m`, `p`, and `r` shorten Windows paths; the original locations remain documented in that archive's README and in Git history.
- `x/s/`: one untracked Sarangchae/Anchae review PNG.
- `x/w/`: three untracked wall-correction review PNGs.
- `ildoo_candidates_5_20260823.zip`: exactly five Ildugotaek candidate PNG outputs from `ildoo-vertical-minhwa-20260823`, stored together as requested.

The branch starts at main commit `f1068f3b38484e276d498ca7798a7ed8a1c95f48`, so all pre-removal tracked Hanok candidate and prototype assets are also recoverable from its history.

## Five-image ZIP integrity

- File count: 5
- ZIP size: 14,888,797 bytes
- SHA-256: `A295514C9A3BBE621C2BF6401F8050B1FD8ED3091CFEB4056051054C49239E40`

This archive must not be added to `pubspec.yaml`, asset catalogs, Firebase, or generation inputs. The authoritative V3 source remains `assets_unused/pending_review/personal_hanok_v3/` on main.
