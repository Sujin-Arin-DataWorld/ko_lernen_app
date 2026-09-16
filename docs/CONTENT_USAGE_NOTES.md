# B1+ 단어 심화 노트 (usage_notes.json)

> C9-T0 (2026-09-16). Fable 설계, Jin이 범위 승인(B1 전량 + B2 유의어 클러스터
> ×20; 카드 뒷면 전용 확장 -- D-5 shell freeze 예외는 flip-card BACK에 한정).
> 배경 조사: `docs/data/level_depth_audit_2026-09-16.md` (Q-C) -- 현재 카드는
> 뜻 1개 + 예문 1개뿐이고, 뉘앙스·연어·유의어 대비·격식 표시·예문 2개(격식/
> 비격식) 중 어느 것도 학습 흐름에서 보이지 않는다는 것을 실측했다.

## 1. 스키마

`assets/data/usage_notes.json`:

```json
{
  "schemaVersion": 1,
  "notes": [
    {
      "id": "vocab_b1_0481",
      "level": "B1",
      "nuance": {"ko": "...", "de": "...", "en": "..."},
      "situation": {"ko": "...", "de": "...", "en": "..."},
      "patterns": [{"ko": "...", "de": "...", "en": "..."}],
      "collocations": [{"ko": "...", "de": "...", "en": "..."}, {"ko": "...", "de": "...", "en": "..."}],
      "contrasts": [{"headword": "협업", "vocabId": "vocab_b2_0042", "ko": "...", "de": "...", "en": "..."}],
      "register": "formal",
      "examples": [
        {"ko": "...", "de": "...", "en": "...", "register": "written"},
        {"ko": "...", "de": "...", "en": "...", "register": "casual"}
      ]
    }
  ]
}
```

필드 규칙:

- `id` -- 반드시 살아있는 `korean_vocab.csv` 행의 id. id는 불변이라 (plan
  "ID는 불변") relevel 후에도 그대로 유지된다.
- `level` -- B1 이상만 (A1/A2는 이번 프로그램 범위 밖, `docs/data/
  level_depth_audit_2026-09-16.md` 참고). 노트 자체의 `level`은 그 vocab
  행의 현재 `level`과 반드시 일치해야 한다(검증됨).
- `nuance`/`situation` -- 3언어(ko/de/en) 1문장씩, 전부 비어 있으면 안 된다.
- `patterns` -- 1~2개. 조사·문형(예: "N에 대해", "-겠다고 약속하다") 위주.
- `collocations` -- 2~3개. headword와 자주 붙는 실제 연어.
- `contrasts` -- 1~2개. `vocabId`는 그 대조어가 `korean_vocab.csv`에 실재하면
  그 id, 없으면 `null`(둘 다 유효 -- 검증기가 null은 통과시키고, 값이 있으면
  살아있는 id인지 확인한다).
- `register` -- 허용값은 정확히 4개, `formal | neutral | casual | written`
  중 하나(표제어 전체의 대표 격식). 다른 문자열(예: `informal`, `polite`)은
  검증기가 거부한다.
- `examples` -- **정확히 2개**, register는 항상 `casual` 1개 + 나머지 3값
  중 하나(`formal`/`written`/`neutral`) 1개 -- `casual`이 0개나 2개면
  검증 실패다. 같은 단어의 격식 차이를 보여주는 것이 목적이라 두 예문의
  register가 달라야 의미가 있다. KO는 그 레벨 문법/어휘를
  넘지 않고(NIKL 기준 자기 레벨+1까지), 어절 상한은 B1 ≤14, B2+ ≤18
  (일반 B1 문장 규칙 ≤16보다 이 기능 한정으로 더 엄격 -- 카드 뒷면 접이식
  구획이라 화면 공간이 좁다). 편집용 dash 문자 금지 -- 하이픈(-)이나 쉼표로
  대체한다. 페르소나 화자(크리스티안·수진 등, `docs/CONTENT_PERSONA_VOICE.md`)
  를 예문 화자로 써도 된다.

### 검증

`tools/content_factory/validate_content.py`의 `validate_usage_notes()`가
파일이 존재할 때만(없으면 조용히 스킵 -- 점진적 롤아웃) 아래를 확인한다:

- id가 살아있는 vocab 행인지, level이 B1 이상이고 그 행의 실제 level과
  일치하는지
- `nuance`/`situation`/`patterns`/`collocations`/`contrasts`의 ko/de/en이
  전부 비어 있지 않은지, em/en dash가 없는지
- `patterns` 1~2개, `collocations` 2~3개, `contrasts` 1~2개
- `examples`가 정확히 2개이고 각각 register가 유효한 값인지
- `contrasts[].vocabId`가 null이거나 살아있는 vocab id인지

## 2. 파이프라인

### TTS 수집

`tool/generate_tts.py`의 `collect()`가 §15로 `usage_notes.json`의 모든
`examples[].ko`를 자동 균형 음성(`add_auto`)으로 수집한다(§13
word_relations.json 패턴과 동일). 파일이 없거나 파싱에 실패해도 조용히
빈 목록으로 넘어간다(다른 필수 소스와 달리 사이드카이므로). 새 노트를
추가한 뒤에는:

```
PYTHONIOENCODING=utf-8 python functions/tts/build_canonical_manifest.py
PYTHONIOENCODING=utf-8 python -X utf8 tool/generate_tts.py --missing-from-storage --workers 8
```

카드에서는 `SoriSpeechIndicator(text: example.ko)`가 이 캐시를 그대로
재생한다(기존 예문 음성과 같은 SHA-1 키 규칙).

### 카피 리비전 원장(copy-revision ledger)

`tools/content_factory/validate_promoted_batch.py`의 `TARGETS`에
`"usage_note": ("usage_notes.json", "notes")`가 새 kind로 추가됐다 --
다른 kind(vocab/grammar/...)와 완전히 같은 draft→review→live fingerprint
계약을 그대로 물려받는다(`promoted_copy_revisions_20260822.json`의
per-row entries, before/afterSha256). 별도 로직 없음 -- 표 한 줄만 추가.

### 레벨 스캐너

`tools/content_factory/scan_grammar_level.py --level B1|B2 --source
usage_notes`가 그 레벨의 노트 예문만 스캔해 상한 문법(B1은 grade≤3, B2는
grade≤4)을 넘는지 본다. `--source corpus`(기본값, A1/A2 기존 동작)와 완전히
분리된 경로 -- 기존 A1/A2 스캔은 바이트 단위로 그대로다
(`test_scan_grammar_level.py`가 A1 패리티를 계속 지킨다).

## 3. 카드 UI (뒷면 전용)

`lib/screens/vocab_pack_screen.dart`의 `_FlipBack`이 예문 블록 아래에
`usageNote != null`일 때만 접이식 `_UsageNoteExpander`를 그린다(A1/A2 등
노트 없는 표제어는 완전히 그대로 -- 위젯 테스트로 고정). 기본은 접힘, 헤더
탭(또는 스크린리더 액션)으로 펼치면:

1. 뉘앙스(라벨 없음, 강조 텍스트)
2. `usageNoteSituation`
3. `usageNotePatterns` (1~2개, KO 줄 + 번역 줄)
4. `usageNoteCollocations` (2~3개)
5. `usageNoteContrast` + 대조어 표제어 (1~2개)
6. `usageNoteExamples` -- 예문 2개, 각각 `SoriSpeechIndicator`(기존
   예문-재생 위젯 재사용)로 탭하면 발음

ARB 키(`lib/l10n/app_de.arb`/`app_en.arb`, KO 텍스트는 전부 데이터에서
옴): `usageNoteTitle`, `usageNoteNuance`, `usageNoteSituation`,
`usageNotePatterns`, `usageNoteCollocations`, `usageNoteContrast`,
`usageNoteExamples`.

로더: `DataLoader.loadUsageNotes()`/`loadUsageNotesById()` -- 다른
`_BundledContentCache` 소스와 동일한 계약(동시 요청 공유, 명시적 retry,
자산 없음/파싱 실패 시 빈 리스트로 안전하게 수렴). `VocabPackScreen`은
`culture_notes.json`의 `_loadCultureNotes()`와 같은 패턴으로 `initState`에서
`unawaited(_loadUsageNotes())` 후 도착하면 `setState` 한 번.

접근성: `SoriBreakpoints`/`kMinInteractiveDimension`(48dp) 헤더 탭 영역,
`Semantics(button: true, expanded: _expanded)`, `SoriMotion.reduceMotion`로
펼침 애니메이션 시간 제어(0ms로 스킵), 텍스트 스케일 1.6에서도 오버플로
없음(위젯 테스트로 고정), 새 `Color(0x...)` 리터럴 없음(기존 `SoriColors`
토큰만 사용).

## 4. 배치 계획

1급 파일럿(이 PR): B1 20단어 -- `docs/data/review_packets/
   c9_pilot_usage_notes_jin_sample.md`에서 Jin 판정.
2. B1 전량 보강: 남은 ~630단어를 100단어 배치로 (약 6~7 배치). 우선순위는
   `level_depth_audit_2026-09-16.md` PART 3의 클러스터 우선 원칙 -- 이미
   이름 붙은 근접-유의어 클러스터(지불/결제, 협조/협력/협업,
   확보하다/보장하다/마련하다, 권한/권리, 정당화/합리화, 형식적/공식적,
   인과 단정/인과 추론, 의사결정권/재량권/결정권 등)를 먼저 묶어서 쓴다 --
   한 클러스터 노트 작성으로 여러 표제어의 대조 항목을 동시에 채울 수 있다.
3. B2 유의어 클러스터 ×20: B1 전량 완료 후. B2는 이미 여러 클러스터가
   B1과 겹쳐 있으므로(예: 협업↔협조) 상호 참조가 자연스럽다.
4. C1/C2는 이번 프로그램 범위 밖 -- 감사 문서가 별도 우선순위(§3 "권한 vs
   권리"·"정당화 vs 합리화" 등 고가치 대조)를 이미 식별해 뒀으니, 후속
   프로그램에서 이 파일 형식을 그대로 재사용한다.

각 배치는: 초안(`tools/content_factory/drafts/`) → Jin 10%(또는 소량이면
전량) 표본 검수 → `assets/data/usage_notes.json`에 병합 → TTS 수집/합성 →
`scan_grammar_level.py --source usage_notes`로 레벨 스캔 → `validate_content.py`
재실행, 기존 배치 콘텐츠 파이프라인(예: batch_29 등)과 같은 절차.
