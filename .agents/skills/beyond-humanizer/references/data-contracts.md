# 한글소리 데이터 계약

## 먼저 확인

저장소의 `AGENTS.md`와 해당 파일을 생성하는 loader/builder/test를 먼저 확인한다. 이 문서는 저장소 규칙을 대체하지 않는다.

## 정본

| 데이터 | 정본·주의 |
|---|---|
| UI | `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`; generated 파일 직접 편집 금지 |
| 어휘·문법 | `assets/data/korean_vocab.csv`, `assets/data/grammar.csv`와 연결 builder |
| Cloze | `assets/data/cloze.json`; answer/fullKo/sentenceKo/distractors 계약 |
| Satz | `assets/data/satz_sentences.json`; targetKo/promptDe/promptEn/distractors 계약 |
| Smalltalk | `assets/data/smalltalk.json`와 생성 source 동시 확인 |
| 시나리오 | `assets/data/scenarios_*.json`; 쓰기는 `tools/content_factory/scenario_store.py` 경유 |
| 문화 | `assets/data/culture_notes.json`, `docs/data/cultural_glossary.json` 등 실제 consumer 확인 |
| Factory | `tools/content_factory/`; generated 산출물만 고치지 말고 source와 동기화 |

## 구조 preflight

언어 편집 전:

```bash
python3 .agents/skills/beyond-humanizer/scripts/validate-unicode.py
python3 .agents/skills/beyond-humanizer/scripts/validate-rejected-phrases.py
python3 tools/content_factory/validate_content.py
```

작업 범위에 맞지 않는 명령은 loader·test를 확인해 대체한다. validator가 실패하면 문장 교정 전에 손상 원인과 canonical source를 찾는다.

## 보존 계약

- 기존 ID, key, 배열 순서 계약, count, level, topic, unit 연결을 임의 변경하지 않는다.
- ARB placeholder, `@key` metadata, ICU plural/select, 따옴표 escaping을 보존한다.
- 한국어 target을 바꾸면 DE/EN, cloze, satz, factory source, TTS/reference linkage를 검색해 함께 판정한다.
- gloss만 고쳐도 같은 한국어 문장을 공유하는 파생 데이터가 있는지 찾는다.
- 중복 JSON key는 parser가 마지막 값을 읽더라도 hard fail이다.
- U+FFFD `�`는 데이터 손실 신호다. 같은 ID의 정상본, git history, source file로만 복구한다.
- PDF·교재 기반 작업은 교육적 신호만 일반화하고 원문 문장·ID·페이지·단원 순서를 복제하지 않는다.

## 변경 후

ARB:

```bash
flutter gen-l10n
flutter test test/l10n_parity_test.dart test/arb_l10n_guard_test.dart
```

학습 데이터는 최소한 관련 loader·contract test와 builder validator를 실행한다. 예:

```bash
flutter test test/cloze_test.dart test/scenario_loader_test.dart
python3 -m unittest tools.content_factory.test_validate_content
```

실제 파일명과 테스트 모듈은 현재 checkout에서 확인한다. 좁은 테스트 통과를 전체 콘텐츠의 원어민 품질 증거로 확대하지 않는다.

## Source Authority

| 상태 | 동작 |
|---|---|
| canonical / Jin-locked | KO를 변경하지 않고 문제와 대안을 보고 |
| human-editable | 목표를 보존하며 필요한 최소 교정 |
| generated | KO를 먼저 독립 검수한 뒤 DE/EN 생성 |
| unknown | source를 고정하지 말고 provenance 확인 또는 flag |

승인·review ledger가 있는 콘텐츠는 그 gate를 우회해 runtime/Firebase/TTS로 올리지 않는다.
