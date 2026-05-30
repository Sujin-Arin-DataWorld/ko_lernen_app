# Cache directory

This directory stores cached responses from external sources so the build pipeline is reproducible and resumable.

## Structure

- `sources/` — **committed** snapshots of public word lists (small, stable)
  - `hermitdave_ko_50k.txt` — Korean frequency list (OpenSubtitles 50k, CC-BY-SA)
  - `okt_nouns.txt` — open-korean-text noun dictionary (~140k verified nouns, Apache 2.0)
- `nikl/` — **gitignored** per-word NIKL responses (regenerable)
- `deepl_de.json` — **gitignored** accumulated DeepL translations (regenerable, costs $)

## Refresh

To re-fetch all external sources:

```bash
rm scripts/cache/sources/*.txt
python3 scripts/build_pool.py --target 1500 --merge
```

To run fully offline (no network calls, cache only):

```bash
python3 scripts/build_pool.py --target 1500 --offline --merge
```
