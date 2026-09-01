# build_vocab_packs.py

> 14 nodes · cohesion 0.30

## Key Concepts

- **build_vocab_packs.py** (8 connections) — `scripts/build_vocab_packs.py`
- **Row** (7 connections) — `scripts/build_vocab_packs.py`
- **main()** (7 connections) — `scripts/build_vocab_packs.py`
- **write_csv()** (5 connections) — `scripts/build_vocab_packs.py`
- **assign_pack_ids()** (4 connections) — `scripts/build_vocab_packs.py`
- **assign_pack_order_and_boss()** (4 connections) — `scripts/build_vocab_packs.py`
- **load_rows()** (4 connections) — `scripts/build_vocab_packs.py`
- **split_oversize_packs()** (4 connections) — `scripts/build_vocab_packs.py`
- **write_pack_map()** (4 connections) — `scripts/build_vocab_packs.py`
- **Path** (3 connections)
- **1차: (level, topic) → pack_id_base** (1 connections) — `scripts/build_vocab_packs.py`
- **2차: 같은 pack_id 단어 수가 PACK_SPLIT_THRESHOLD 초과 시 sub-pack 으로 분할. 분할은 row 순서 유지 —…** (1 connections) — `scripts/build_vocab_packs.py`
- **역사적 3차: pack 내 order 부여 + current-pack Boss 멤버십 마킹. 현재 정본 CSV는 relevel 작업 뒤…** (1 connections) — `scripts/build_vocab_packs.py`
- **11 컬럼 CSV 작성. CRLF 회피, UTF-8.** (1 connections) — `scripts/build_vocab_packs.py`

## Relationships

- No strong cross-community connections detected

## Source Files

- `scripts/build_vocab_packs.py`

## Audit Trail

- EXTRACTED: 27 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
