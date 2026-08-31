# build_pool.py

> 30 nodes

## Key Concepts

- **build_pool.py** (18 connections) — `scripts/build_pool.py`
- **main()** (10 connections) — `scripts/build_pool.py`
- **wiktionary_fill_todos()** (6 connections) — `scripts/build_pool.py`
- **deepl_translate_batch()** (5 connections) — `scripts/build_pool.py`
- **fetch_with_cache()** (5 connections) — `scripts/build_pool.py`
- **wiktionary_translate_de()** (5 connections) — `scripts/build_pool.py`
- **build_entry()** (4 connections) — `scripts/build_pool.py`
- **load_frequency()** (4 connections) — `scripts/build_pool.py`
- **load_okt_nouns()** (4 connections) — `scripts/build_pool.py`
- **recompute_chain_meta()** (4 connections) — `scripts/build_pool.py`
- **is_clean_noun()** (3 connections) — `scripts/build_pool.py`
- **nikl_enrich()** (3 connections) — `scripts/build_pool.py`
- **_clean_wiki_markup()** (2 connections) — `scripts/build_pool.py`
- **estimate_level()** (2 connections) — `scripts/build_pool.py`
- **guess_topic()** (2 connections) — `scripts/build_pool.py`
- **load_deepl_cache()** (2 connections) — `scripts/build_pool.py`
- **load_wikt_cache()** (2 connections) — `scripts/build_pool.py`
- **save_deepl_cache()** (2 connections) — `scripts/build_pool.py`
- **save_wikt_cache()** (2 connections) — `scripts/build_pool.py`
- **Path** (2 connections)
- **Session** (1 connections)
- **Returns list of (word, freq_rank) — most frequent first.** (1 connections) — `scripts/build_pool.py`
- **Returns set of verified Korean nouns from open-korean-text.** (1 connections) — `scripts/build_pool.py`
- **Layered filter: OKT membership + format + length + verb-ending blocklist.** (1 connections) — `scripts/build_pool.py`
- **Returns dict {definition, en, examples} or None.** (1 connections) — `scripts/build_pool.py`
- *... and 5 more nodes in this community*

## Relationships

- [Counter](Counter.md) (1 shared connections)

## Source Files

- `scripts/build_pool.py`

## Audit Trail

- EXTRACTED: 48 (98%)
- INFERRED: 1 (2%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*