# build_kkeunmari_pool.py

> 17 nodes · cohesion 0.21

## Key Concepts

- **build_kkeunmari_pool.py** (10 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **main()** (9 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **assemble_pool()** (6 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **self_test()** (5 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **freq_level()** (4 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **deepl_fill()** (3 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **graph_stats()** (3 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **load_seed()** (3 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **load_vocab_gloss()** (3 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **stdict_is_common_noun()** (3 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **write_pool()** (2 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **표제어 정확 일치 + 품사==명사 면 True. 동음이의어 다수면 신중히 통과 (명사 sense 가 하나라도 있으면 끝말잇기엔 충분 — 뜻은…** (1 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **korean_vocab.csv → {korean: (german, level, topic)} (사람 검수 글로스).** (1 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **빈도 순위 → 학습 레벨 휴리스틱(vocab 매칭이 있으면 그쪽이 우선).** (1 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **남은 명사를 DeepL ko→de 로 번역(기계 — 검수 권장). 키 없으면 {}.** (1 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **검증된 명사 리스트 → 풀 엔트리. next_count/is_dead_end 최종집합 기준 계산.** (1 connections) — `tools/content_factory/build_kkeunmari_pool.py`
- **빈도순 한글 단어 리스트. seed_file 없으면 ko_50k 다운로드+캐시.** (1 connections) — `tools/content_factory/build_kkeunmari_pool.py`

## Relationships

- [Counter](Counter.md) (1 shared connections)

## Source Files

- `tools/content_factory/build_kkeunmari_pool.py`

## Audit Trail

- EXTRACTED: 28 (97%)
- INFERRED: 1 (3%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*
