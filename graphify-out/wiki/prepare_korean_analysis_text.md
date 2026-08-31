# prepare_korean_analysis_text

> 26 nodes

## Key Concepts

- **prepare_korean_analysis_text()** (18 connections) — `functions/analyze_korean_text/text_quality.py`
- **text_quality.py** (11 connections) — `functions/analyze_korean_text/text_quality.py`
- **KoreanAnalysisTextQualityTest** (8 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **split_korean_sentences()** (8 connections) — `functions/analyze_korean_text/text_quality.py`
- **test_text_quality.py** (6 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **contains_hangul()** (5 connections) — `functions/analyze_korean_text/text_quality.py`
- **_filter_supported_characters()** (4 connections) — `functions/analyze_korean_text/text_quality.py`
- **_trim_non_korean_affixes()** (4 connections) — `functions/analyze_korean_text/text_quality.py`
- **PreparedKoreanText** (3 connections) — `functions/analyze_korean_text/text_quality.py`
- **.test_reflows_ocr_lines_and_only_splits_terminal_sentences()** (3 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **_is_supported_character()** (3 connections) — `functions/analyze_korean_text/text_quality.py`
- **.test_filters_unexpected_script_inside_a_korean_sentence()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_keeps_korean_and_removes_separate_german_and_arabic_lines()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_keeps_latin_names_embedded_inside_a_korean_sentence()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_removes_same_line_translation_but_keeps_embedded_latin()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_reports_when_no_korean_remains()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **.test_shared_dart_python_golden_contract()** (2 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **_is_forbidden_format_character()** (2 connections) — `functions/analyze_korean_text/text_quality.py`
- **Regression tests for bilingual OCR text preparation.** (1 connections) — `functions/analyze_korean_text/test_text_quality.py`
- **Deterministic quality gate for mixed-language textbook OCR. The book scanner is…** (1 connections) — `functions/analyze_korean_text/text_quality.py`
- **Remove clear translated labels around an otherwise Korean segment.** (1 connections) — `functions/analyze_korean_text/text_quality.py`
- **Prepare OCR text for Korean-only linguistic analysis. Pure German/English lines…** (1 connections) — `functions/analyze_korean_text/text_quality.py`
- **Split reflowed Korean source without treating every OCR line as a sentence.** (1 connections) — `functions/analyze_korean_text/text_quality.py`
- **Korean analysis input and stable machine-readable quality warnings.** (1 connections) — `functions/analyze_korean_text/text_quality.py`
- **Return whether NFC text contains an analysable Hangul syllable.** (1 connections) — `functions/analyze_korean_text/text_quality.py`
- *... and 1 more nodes in this community*

## Relationships

- [main.py](main.py.md) (6 shared connections)
- [SimpleNamespace](SimpleNamespace.md) (1 shared connections)

## Source Files

- `functions/analyze_korean_text/test_text_quality.py`
- `functions/analyze_korean_text/text_quality.py`

## Audit Trail

- EXTRACTED: 51 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*