# Manuscript recovery — 2026-11-21

All 100 manuscript files match the original `codex/season1-manuscript-review-20261115` branch at `42a3d8539e921b08723c0f6b7098539aca673207` byte for byte. Its review reports, source files and open human/audio/learner validation limitations are preserved. No application code or audio is changed by this recovery.

The recovery is based on main at `afc57a7b995bb731adebb9ef0994b286ae104c9a`. The packaged validator retains its historical default base for old authoring records. For this recovered branch, run:

```sh
python docs/learning/ildu-season1-manuscripts-20261105/reviews/full-cross-review-20261115/validate_package.py --require-reviews --base-ref origin/main
```

The scope check examines committed, staged and unstaged changes separately and disables rename detection, so moving a runtime file into the documentation directory or hiding staged changes cannot pass as documentation-only work. This mechanical validation does not replace language, teaching, audio or learner review.
