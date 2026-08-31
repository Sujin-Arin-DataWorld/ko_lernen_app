# validate_directory

> 36 nodes · cohesion 0.17

## Key Concepts

- **validate_directory()** (23 connections) — `tool/check_app_store_screenshots.py`
- **Path** (20 connections)
- **AppStoreScreenshotValidatorTest** (19 connections) — `tool/test_check_app_store_screenshots.py`
- **write_png()** (13 connections) — `tool/test_check_app_store_screenshots.py`
- **_chunk()** (9 connections) — `tool/test_check_app_store_screenshots.py`
- **ihdr_chunk()** (8 connections) — `tool/test_check_app_store_screenshots.py`
- **write_chunked_png()** (8 connections) — `tool/test_check_app_store_screenshots.py`
- **check_app_store_screenshots.py** (7 connections) — `tool/check_app_store_screenshots.py`
- **_read_png_metadata()** (7 connections) — `tool/check_app_store_screenshots.py`
- **test_check_app_store_screenshots.py** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_indexed_palette_order_and_entry_boundaries()** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_non_contiguous_idat_chunks()** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_plte_for_grayscale_png()** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_png_with_undecodable_idat_stream()** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_reserved_chunk_name_bit()** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_truecolor_plte_after_trns()** (6 connections) — `tool/test_check_app_store_screenshots.py`
- **_read_chunk_payload()** (5 connections) — `tool/check_app_store_screenshots.py`
- **.test_accepts_opaque_13_inch_ipad_landscape_png()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_alpha_color_type()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_illegal_ihdr_bit_depth_for_truecolor()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_png_with_corrupted_chunk_crc()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_png_without_image_data()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_trns_transparency()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_wrong_dimensions()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- **.test_rejects_zero_or_eleven_files()** (4 connections) — `tool/test_check_app_store_screenshots.py`
- *... and 11 more nodes in this community*

## Relationships

- [security.py](security.py.md) (1 shared connections)

## Source Files

- `tool/check_app_store_screenshots.py`
- `tool/test_check_app_store_screenshots.py`

## Audit Trail

- EXTRACTED: 91 (83%)
- INFERRED: 19 (17%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*