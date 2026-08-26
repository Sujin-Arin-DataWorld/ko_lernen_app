# Pre-V3 Hanok archive locator

The authoritative Ildugotaek source set is:

`assets_unused/pending_review/personal_hanok_v3/`

On 2026-08-26, ignored local V3 PNGs from the `ildu-roster` worktree were added to Git so the directory is reproducible from main.

Legacy candidates and experiments removed from main remain recoverable on the remote branch `archive/hanok-pre-v3-20260826` at commit `05076e9ead324d4a3c7ed5d2e73b4d21b99a9712`.

- Recovered local candidates: `hanok_archive_20260826/l/`
- Extra worktree candidates: `hanok_archive_20260826/x/`
- Five Ildugotaek candidate outputs in one archive: `hanok_archive_20260826/ildoo_candidates_5_20260823.zip`
- ZIP SHA-256: `A295514C9A3BBE621C2BF6401F8050B1FD8ED3091CFEB4056051054C49239E40`

The current runtime still references `assets/illustrations/personal_hanok_v2/`. Those 40 bundled files are intentionally retained until the V3 runtime catalog and cutover are implemented; deleting them earlier would break current Hanok screens and tests.
