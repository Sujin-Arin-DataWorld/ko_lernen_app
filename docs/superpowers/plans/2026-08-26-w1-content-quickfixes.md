# W1 데이터·즉효 버그 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 지시서 데이터·즉효 버그 항목(2.1, 2.5-2.8, 2.10 시드, 1.5/1.9 등 네이밍, 1.13/1.17, 4.17)을 콘텐츠 자연성 파이프라인·가드 테스트와 함께 랜딩한다.

**Architecture:** 데이터 교정은 CSV(원본)+cloze.json+satz_sentences.json 3파일 동기, 가드 테스트가 정합을 상시 검증. 자연성 검사는 결정적 프리필터(Python) → LLM 심사 → Jin 승인 → id-키 패치 4단 파이프라인.

**Tech Stack:** Flutter/Dart (flutter_test), Python 3 (tool/ 스크립트, 외부 의존성 금지 — stdlib만)

**Spec:** `C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-fizzy-marshmallow.md` (승인된 마스터 플랜 — W1 행, "콘텐츠 자연성 시스템", "전역 네이밍·카피 개편", 검수 보강 12·16번)

## Global Constraints

- 브랜치: `feat/w1-content-quickfixes` (이미 체크아웃됨). 태스크당 1커밋, 커밋 푸터: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- `tools/content_factory/build_cloze.py --write` **절대 실행 금지** (전체 덮어쓰기 — 수기 교정 소실)
- arb 수정은 `app_de.arb`+`app_en.arb` **동시** + `flutter gen-l10n` 실행 (arb_l10n_guard 계약)
- 볼륨/게인 리터럴 신규 0 (audio_policy_guard 래칫)
- raw `TextStyle(` 신규 0 — typography_guard 래칫은 감소만 허용
- Python 스크립트는 stdlib만, 결정적(정렬된 출력), `python tool/<name>.py` 로 리포지토리 루트에서 실행 가능해야 함
- 각 태스크 종료 시 `flutter analyze` 신규 이슈 0
- 데이터 파일 인코딩 UTF-8(BOM 없음), JSON은 기존 들여쓰기(2칸) 유지

---

### Task 1: cloze 콘텐츠 가드 테스트

**Files:**
- Create: `test/cloze_content_guard_test.dart`

**Interfaces:**
- Produces: 가드 3종 — ① 빈칸 복원(sentenceKo의 `＿＿＿`→answer == fullKo) ② fullKo↔CSV example_korean 동기+레벨 일치 ③ distractor 위생. Task 2의 데이터 교정이 이 테스트를 통과해야 함.

- [ ] **Step 1: 실패하는 테스트 작성** — CSV는 따옴표 필드가 있으므로 미니 파서 포함:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// 트리아지 결과 (첫 실행에서 검출된 기존 비동기 항목). 늘리기 금지 — 래칫.
const Set<String> knownUnsyncedIds = {};
const int knownUnsyncedCap = 0; // 첫 실행 후 실측값으로 고정

List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var field = StringBuffer(), row = <String>[], inQuotes = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString().replaceAll('\r', ''));
      rows.add(row);
      row = <String>[];
      field = StringBuffer();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

void main() {
  final cloze =
      jsonDecode(File('assets/data/cloze.json').readAsStringSync())
          as Map<String, dynamic>;
  final items = (cloze['items'] as List).cast<Map<String, dynamic>>();
  final csvRows = parseCsv(
    File('assets/data/korean_vocab.csv').readAsStringSync(),
  );
  final header = csvRows.first;
  final iKo = header.indexOf('example_korean');
  final iLevel = header.indexOf('level');
  final exampleLevel = <String, String>{
    for (final r in csvRows.skip(1))
      if (r.length > iKo) r[iKo]: r[iLevel],
  };

  test('빈칸 복원: sentenceKo(＿＿＿→answer) == fullKo', () {
    for (final it in items) {
      final rebuilt = (it['sentenceKo'] as String)
          .replaceFirst('＿＿＿', it['answer'] as String);
      expect(rebuilt, it['fullKo'], reason: it['id'] as String);
    }
  });

  test('fullKo 는 CSV example_korean 에 존재하고 레벨이 일치한다', () {
    final unsynced = <String>[];
    for (final it in items) {
      final id = it['id'] as String;
      final level = exampleLevel[it['fullKo'] as String];
      if (level == null || level.toLowerCase() != it['level']) {
        if (!knownUnsyncedIds.contains(id)) unsynced.add(id);
      }
    }
    expect(unsynced, isEmpty,
        reason: '신규 비동기 항목 — CSV/cloze 3파일 동기 규칙 위반');
    expect(knownUnsyncedIds.length, lessThanOrEqualTo(knownUnsyncedCap));
  });

  test('distractor 위생: 정답과 다르고, 문장 잔여부에 노출되지 않는다', () {
    for (final it in items) {
      final id = it['id'] as String;
      final answer = it['answer'] as String;
      final sentence = it['sentenceKo'] as String;
      for (final d in (it['distractors'] as List).cast<String>()) {
        expect(d.trim(), isNotEmpty, reason: id);
        expect(d, isNot(answer), reason: id);
        expect(sentence.contains(d), isFalse,
            reason: '$id: distractor "$d" 가 문장에 노출됨');
      }
    }
  });
}
```

- [ ] **Step 2: 실행해 실패 확인** — `flutter test test/cloze_content_guard_test.dart`. 예상: 동기 테스트에서 다수 검출(배치 생성기 파생 항목), distractor 위생에서 `cloze_a1_0104`(현관) 등 검출.
- [ ] **Step 3: 트리아지** — 실패 id 전량을 분류: (a) Task 2 시드 5건이 고치는 것 → allowlist 제외 (b) 그 외 기존 비동기 → `knownUnsyncedIds` 에 등재 + `knownUnsyncedCap` 실측 고정. distractor 위생 실패 중 시드 외 항목도 allowlist 방식으로 `knownDistractorIds` 상수를 같은 패턴으로 추가(래칫 캡 포함)해 테스트 GREEN.
- [ ] **Step 4: GREEN 확인 후 커밋** — `git add test/cloze_content_guard_test.dart && git commit -m "test: cloze 콘텐츠 가드(복원·CSV동기·distractor) + 트리아지 래칫"`

---

### Task 2: 시드 5건 데이터 교정 (CSV+cloze+satz 3파일 동기)

**Files:**
- Modify: `assets/data/korean_vocab.csv` (행 1194, 1244, 1282, 1470, 1665)
- Modify: `assets/data/cloze.json` (cloze_a1_0104 :8111, cloze_a1_0154 :8861, cloze_a1_0192 :9431, cloze_b1_0172 :12251, cloze_a1_0239 :15176)
- Modify: `assets/data/satz_sentences.json` (satz_a1_0068 :5507, satz_a1_0156 :6563, satz_a1_0203 :11159 + `일정 충돌`/`절하는 타이밍` targetKo 검색 결과)

**Interfaces:**
- Consumes: Task 1 가드 테스트 (교정 후 allowlist에서 시드 제거)
- Produces: Task 6 TTS 재생성 대상 문자열 (신규 fullKo/targetKo/example_korean)

- [ ] **Step 1: 지시서 원문 대조** — `docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md` 의 Spiele 2.1, 2.6-2.8, 2.10 항목을 읽고 아래 교정안이 Jin의 지적 취지와 일치하는지 확인. 불일치 시 beyond-humanizer 계약(`.agents/skills/beyond-humanizer/SKILL.md` — PIVOT: 사실·화행·존대 잠금, 한국어 정본 판정 후 DE/EN 독립 재구성)으로 조정.
- [ ] **Step 2: 교정 적용.** 각 항목의 확정안 (CSV example_korean/example_german/example_english ↔ cloze fullKo·sentenceKo·de·en ↔ satz targetKo·promptDe·promptEn 동일 문자열로 동기):

**(2.1) 층간소음 — vocab_a1_0351 / cloze_a1_0239 / satz_a1_0203**
- KO: `밤에는 층간소음이 나지 않게 조심해야 돼요.` (sentenceKo: `밤에는 ＿＿＿이 나지 않게 조심해야 돼요.`)
- DE: `Nachts sind wir leise, damit die Nachbarn unten nichts hören.`
- EN: `At night we keep quiet so the neighbors below don't hear us.`
- distractors: `초인종`·`이웃집` 유지, `복도`(모음 끝 — `＿＿＿이` 과 조사 불합치) → CSV Nachbarschaft 팩의 받침 있는 표제어(예: `택배함`, CSV에 존재 확인 후)로 교체.

**(시아버지) vocab_a1_0216 / cloze_a1_0104 / satz_a1_0068**
- KO: `남편 집에 가니까 시아버지께서 현관까지 나오셨어요.` (sentenceKo: `남편 집에 가니까 ＿＿＿께서 현관까지 나오셨어요.` — 문맥 없이는 어떤 웃어른도 답이 되는 문제를 `남편 집` 장면으로 해소)
- DE: `Als wir bei der Familie meines Mannes ankamen, kam mein Schwiegervater bis zur Tür.`
- EN: `When we arrived at my husband's family's home, my father-in-law came out to the door.`
- distractors: 문장 속 노출 `현관` 과 무작위 `햇과일` 제거 → 처가/타관계 남성 존칭 표제어로 교체(`장인어른`·`이모부` 등 — CSV 표제어 존재 확인, 없으면 CSV의 Partnerschaft 팩에서 `께서` 가 자연스럽고 `남편 집` 장면과 모순되는 인물 명사 선택). `형부` 는 존치 가능(처가 측 — 문맥상 배제됨).

**(절하) vocab_a1_0266 / cloze_a1_0154 + `절하는 타이밍` 을 targetKo 로 갖는 satz 항목(grep 로 확인)**
- KO 예문 자체는 자연스러움 — 문제는 cloze answer `절하` 절단. answer 를 완결 어절로: answer `절하는`, sentenceKo `＿＿＿ 타이밍을 놓쳐서 한 박자 늦었어요.`, fullKo 불변 `절하는 타이밍을 놓쳐서 한 박자 늦었어요.` CSV·satz 불변.
- distractors `친해`·`성함을 묻`·`세배 드리`(전부 조각) → 같은 관형형 완결 어절로: `인사드리는` 은 문맥상 그럴듯하므로 금지. `요리하는`·`출발하는`·`포장하는` 중 어간이 CSV 표제어(요리하다 등)로 존재하는 3개 선택.

**(이모티콘) vocab_a1_0304 / cloze_a1_0192 / satz_a1_0156**
- KO: `이모티콘은 절하는 토끼로 했어요.` (`~로 골랐어요` 의 조사 충돌 해소; sentenceKo: `＿＿＿은 절하는 토끼로 했어요.`)
- DE: `Als Sticker habe ich das verbeugende Häschen genommen.`
- EN: `For the sticker, I went with the bowing rabbit.`
- distractors: `형부`(모음 끝 — `＿＿＿은` 불합치) 교체, `햇과일` 교체 → 받침 있는 CSV 표제어 중 문맥상 배제되는 것(예: `현관` 유지 + `달력`·`답장` 등 CSV 존재 확인 후 2개).

**(일정 충돌) vocab_b1_0360 / cloze_b1_0172 (+ satz 에 동일 targetKo 있으면 동기)**
- KO: `일정 충돌이 생겨서 현우가 어머니께 먼저 전화드렸어요.` (`충돌이 나자` → `충돌이 생겨서` 자연 연어; `전화했어요`→`전화드렸어요` 존대 일관. sentenceKo: `＿＿＿이 생겨서 현우가 어머니께 먼저 전화드렸어요.`)
- DE: `Wegen einer Terminüberschneidung rief Hyunwoo zuerst seine Mutter an.`
- EN: `When schedules clashed, Hyunwoo called his mother first.`
- distractors `명절 예산`·`방 배정`·`방문 순서` 유지(형태 가능·문맥 불가 충족).

- [ ] **Step 3: 가드 GREEN + allowlist 축소** — `flutter test test/cloze_content_guard_test.dart` 실행. 시드 5건이 allowlist 없이 통과해야 하고, Task 1에서 시드가 allowlist에 있었다면 제거 + 캡 하향.
- [ ] **Step 4: 전체 영향 확인** — `flutter test` (satz/cloze 를 읽는 다른 테스트 회귀 확인).
- [ ] **Step 5: 커밋** — `git commit -m "fix(content): 시드 5건 자연성 교정 — CSV·cloze·satz 3파일 동기 (지시서 2.1/2.6-2.8/2.10)"`

---

### Task 3: 자연성 프리필터 `tool/audit_content_naturalness.py`

**Files:**
- Create: `tool/audit_content_naturalness.py`
- Create(출력): `docs/data/naturalness_candidates.md` (실행 산출물, 커밋함)

**Interfaces:**
- Produces: `main(argv)` — 코퍼스 7종을 스캔해 후보를 `docs/data/naturalness_candidates.md` 로 출력(id·소스파일·문장·검출 마커). Task 12의 LLM 심사 입력.

- [ ] **Step 1: 스크립트 작성.** 검출 마커(전부 결정적, stdlib만):
  - `dangling_stem`: cloze answer 가 `하`/`되` 로 끝나고 대응 CSV 표제어가 `하다`/`되다` 로 끝남 (절하-형 절단)
  - `particle_mismatch`: `＿＿＿` 바로 뒤 조사(이/가·은/는·을/를)와 각 distractor 의 받침 유무 불합치
  - `passive_pileup`: `되어지`·`지게 되` 포함
  - `e_daehae`: 한 문장에 `에 대해` 2회 이상
  - `josa_dup`: `을를`·`이가`·`은는` 연쇄
  - `formality_mix`: 한 문장 안에 `~습니다` 와 `~요` 종결 혼재
  - `level_length`: a1 문장 40자 초과, a2 60자 초과
  - `answer_repeat`: fullKo 에 answer 가 2회 이상 등장
  - 대상: `korean_vocab.csv`(example_korean), `cloze.json`, `satz_sentences.json`, `smalltalk.json`(phrases 내 모든 ko — generate_tts.py:258-269 의 `_walk_ko` 로직 재사용), `scenarios_*.json`(대화·퀘스트 ko 필드), `silben_puzzles.json`(exampleKo — ◯ 는 answer 로 복원 후 검사), `grammar.csv`(예문 열)
  - 출력: 파일별 섹션, 항목당 `| id | 마커 | 문장 |` 표. 마지막에 `## 요약` (파일별 건수). 정렬: 파일명→id.
- [ ] **Step 2: 실행** — `python tool/audit_content_naturalness.py` → `docs/data/naturalness_candidates.md` 생성. 시드 5건(교정 전 상태 기준으로 작성했다면 교정 후 재실행)이 잡히는 마커였는지 회고 노트를 요약 섹션에 1줄 기재.
- [ ] **Step 3: 결정성 검증** — 2회 실행해 diff 0 확인.
- [ ] **Step 4: 커밋** — `git commit -m "feat(tool): 콘텐츠 자연성 프리필터 + 1차 후보 리포트"`

---

### Task 4: 생성기 게이트 — pick_answer 폴백 → 예외

**Files:**
- Modify: `tools/content_factory/build_batch_07_partner_family.py:192-217`
- Modify: 동일 `pick_answer` 를 가진 다른 `tools/content_factory/build_batch_*.py` (`grep -l "def pick_answer" tools/content_factory/`)

**Interfaces:**
- Produces: `pick_answer(head, sentence)` — 표제어(또는 사전형 어미 제거 스템)가 문장에 안 보이면 **즉시 ValueError**. 접두어 축소·한글 런 추측 폴백 삭제.

- [ ] **Step 1: 폴백 삭제.** `build_batch_07_partner_family.py:204-216` 에서 두 폴백(길이 축소 `for length in range(...)` 루프의 `stem` 반환, `_hangul_runs` 시드 추측)을 삭제하고 정확 매치만 남긴다:

```python
def pick_answer(head: str, sentence: str) -> str:
    candidates = [head, head.replace(" ", "")]
    for ending in ("하다", "되다", "이다", "다"):
        if head.endswith(ending) and len(head) > len(ending):
            candidates.append(head[: -len(ending)])
            candidates.append(head[: -len(ending)].replace(" ", ""))
    seen: set[str] = set()
    ordered: list[str] = []
    for item in candidates:
        if item and item not in seen:
            seen.add(item)
            ordered.append(item)
    for item in sorted(ordered, key=len, reverse=True):
        if item in sentence:
            return item
    raise ValueError(
        f"headword {head!r} not visible in {sentence!r} — "
        "예문을 표제어가 그대로 보이게 고쳐라 (조각 답 생성 금지)"
    )
```

주의: `하다` 어미 제거 스템(`절하`)은 여전히 후보다 — 절단 위험은 프리필터 `dangling_stem` 마커가 생성 후 잡는다. 같은 함수가 있는 다른 batch 파일 전부 동일 적용, `_hangul_runs` 가 다른 곳에서 안 쓰이면 함께 삭제.
- [ ] **Step 2: 게이트 내장** — 각 batch 스크립트의 아이템 생성 직후에 `tool/audit_content_naturalness.py` 의 마커 함수를 import 해 `dangling_stem`·`answer_repeat` 검출 시 예외로 중단하는 호출 1곳 추가 (`sys.path` 조작 대신 상대 import 가 안 되면 마커 로직을 `tools/content_factory/naturalness_gate.py` 로 추출하고 audit 스크립트가 그것을 import 하는 구조로).
- [ ] **Step 3: 스모크** — `python -c` 로 pick_answer 정상/예외 케이스 2개 실행 확인 (배치 스크립트 전체는 실행하지 않는다 — cloze.json 추가 쓰기 금지).
- [ ] **Step 4: 커밋** — `git commit -m "feat(content-factory): pick_answer 조각 폴백 제거 + 생성 시점 자연성 게이트"`

---

### Task 5: Silben 전체 문장 TTS (지시서 2.5)

**Files:**
- Modify: `lib/models/silben_puzzle.dart` (SilbenWord 에 게터 추가)
- Modify: `lib/screens/silben_kreuz_screen.dart:297`
- Create: `test/silben_puzzle_spoken_test.dart`

**Interfaces:**
- Produces: `SilbenWord.exampleKoSpoken` → `String` (◯ 마스킹 복원). Task 6 이 같은 복원 규칙을 Python 으로 미러링.

- [ ] **Step 1: 실패하는 테스트:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';

void main() {
  SilbenWord word(String answer, String exampleKo) => SilbenWord(
    dir: 'h', row: 0, col: 0, answer: answer,
    german: '', exampleKo: exampleKo, exampleDe: '',
  );

  test('◯ 런을 정답으로 복원한다', () {
    expect(word('다섯', '◯◯ 명이 왔어요.').exampleKoSpoken, '다섯 명이 왔어요.');
  });
  test('정답이 두 번 나와도 전부 복원한다', () {
    expect(word('눈', '◯이 오면 ◯사람을 만들어요.').exampleKoSpoken,
        '눈이 오면 눈사람을 만들어요.');
  });
  test('예문이 없으면 빈 문자열', () {
    expect(word('다섯', '').exampleKoSpoken, '');
  });
}
```

(패키지명이 `ko_lernen_app` 이 아니면 pubspec.yaml 의 `name:` 을 확인해 import 수정.)
- [ ] **Step 2: 실행 → FAIL 확인** — `flutter test test/silben_puzzle_spoken_test.dart`
- [ ] **Step 3: 구현** — `SilbenWord` 에:

```dart
  /// exampleKo 의 ◯ 마스킹을 정답으로 복원한 발화용 문장.
  /// tool/generate_tts.py 의 silben 수집 규칙과 동일해야 TTS 캐시가 맞는다.
  String get exampleKoSpoken =>
      exampleKo.isEmpty ? '' : exampleKo.replaceAll(RegExp('◯+'), answer);
```

- [ ] **Step 4: 화면 배선** — `silben_kreuz_screen.dart:297` 의 `TtsService.speak(w.answer);` 를:

```dart
          TtsService.speak(
            w.exampleKo.isEmpty ? w.answer : '${w.answer}. ${w.exampleKoSpoken}',
          );
```

- [ ] **Step 5: GREEN + analyze 후 커밋** — `git commit -m "feat(silben): 정답 시 전체 예문 발화 — exampleKoSpoken 복원 게터 (지시서 2.5)"`

---

### Task 6: generate_tts.py 확장 + 코퍼스 재생성 (W1 종료 게이트)

**Files:**
- Modify: `tool/generate_tts.py:410-421` (silben 수집 확장)

**Interfaces:**
- Consumes: Task 2 의 신규 문장(fullKo 는 :273 의 cloze 수집이 자동 포함), Task 5 의 합성 발화 규칙 `'{answer}. {복원된 exampleKo}'`

- [ ] **Step 1: silben 수집 확장** — :418-420 의 word 루프를:

```python
                for word in puzzle.get("words", []):
                    if not isinstance(word, dict):
                        continue
                    answer = word.get("answer")
                    add_auto(answer)
                    # silben_kreuz_screen 은 정답 확정 시
                    # "{answer}. {◯복원 예문}" 을 발화한다 (SilbenWord.exampleKoSpoken).
                    example = word.get("exampleKo") or ""
                    if answer and example:
                        add_auto(f"{answer}. {re.sub('◯+', answer, example)}")
```

(`import re` 가 파일 상단에 없으면 추가.)
- [ ] **Step 2: 수집 스모크** — 스크립트에 dry-run/수집 카운트 출력 모드가 있으면 그것으로, 없으면 `python -c` 로 수집 함수만 호출해 silben 합성문이 포함되는지 확인.
- [ ] **Step 3: 재생성 실행** — `python tool/generate_tts.py` (GCP 자격 증명 필요 — 실패 시 필요한 자격/명령을 정리해 보고하고 이 스텝을 Jin 액션으로 표시) → `--verify-storage` 로 누락 0 확인. **누락 0 = W1 데이터 트랙 종료 조건.**
- [ ] **Step 4: 커밋** — `git commit -m "feat(tts): silben 전체 문장 발화 수집 — 코퍼스 재생성 (검수 12)"`

---

### Task 7: 전역 네이밍·카피 개편 (지시서 1.5, 1.9 + 사용자 추가 요청)

**Files:**
- Modify: `lib/data/sori_activity_catalog.dart` (srs :182-194, word_web :208-222, calligraphy, chosung/syllable_cross/cloze/speed_match :334-465)
- Modify: `lib/l10n/app_de.arb` + `lib/l10n/app_en.arb` (screenVocabTitle :377, vocabModeFavorites :1561, vocabEmptyFavorites :1572 + grep 으로 찾은 구명칭 키)
- Modify: 카피 스냅샷 테스트 (`grep -rl "SRS-Wiederholung" test/` 로 위치 확인 후 재기준)

**Interfaces:**
- Produces: 확정 명칭 (마스터 플랜 "전역 네이밍·카피 개편" 표가 정본):
  - srs: DE `Wiederholen` / EN `Review`, 설명 DE `Wörter genau im richtigen Moment auffrischen.` / EN `Refresh words at just the right moment.`
  - word_web: DE `Nuancen & Gegenteile` / EN `Nuances & opposites`, 설명 DE `Synonyme, Gegenteile und Wendungen zu deinen Wörtern.` / EN `Synonyms, opposites and expressions for your words.` + 아이콘 `search`→`hub` 계열(카탈로그 엔트리의 아이콘 필드 확인 후 word_search 와의 중복 해소)
  - calligraphy: DE `Buchstabe des Tages` / EN `Character of the day`, 설명 DE `Jeden Tag ein Schriftzeichen entdecken.` / EN `Discover one character every day.` (따라쓰기 문구는 W5에서 기능과 함께 추가 — 아직 없는 기능을 약속하지 않는다)
  - chosung: DE `Anlaut-Quiz` / EN `First-sound quiz` · syllable_cross: DE `Silben-Rätsel` / EN `Syllable puzzle` · cloze: DE `Lückentext` / EN `Fill the gap` · speed_match: DE `Blitz-Paare` / EN `Speed pairs`
  - legacy_vocab 화면: `screenVocabTitle` DE `Karteikarten` / EN `Flashcards`; `vocabModeFavorites` DE `Gemerkt` / EN `Saved`; `vocabEmptyFavorites` DE `Noch nichts gemerkt\nTippe auf das Lesezeichen, um Wörter zu speichern.` / EN `Nothing saved yet\nTap the bookmark to save words.` (별/Stern 언급 제거 — §12 하트/보관 이원화 정합)

- [ ] **Step 1: 구명칭 전수 조사** — `grep -rn "SRS\|Wortnetz\|Chosung\|Silben-Kreuz\|Lückensatz\|Speed Match\|Kalligrafie" lib/ --include="*.dart" --include="*.arb"` 로 카탈로그 밖 사용처(화면 제목 arb 키, 코치 문구 등)를 모두 나열. 각각 위 확정 명칭으로 동기 (게임 화면 자체 AppBar 제목 포함).
- [ ] **Step 2: 카탈로그+arb 수정** — 위 Interfaces 값 그대로. de/en 동시.
- [ ] **Step 3: l10n 재생성** — `flutter gen-l10n` 실행, analyze 0.
- [ ] **Step 4: 스냅샷 재기준** — 카피 스냅샷 테스트 실행 → 실패한 기대값을 신명칭으로 갱신(무단 golden 삭제 금지, 값만 갱신).
- [ ] **Step 5: 전체 테스트** — `flutter test` GREEN.
- [ ] **Step 6: 커밋** — `git commit -m "feat(copy): 전역 네이밍 개편 — Wiederholen·Nuancen&Gegenteile·Anlaut-Quiz·Silben-Rätsel·Lückentext·Blitz-Paare·Karteikarten (지시서 1.5/1.9)"`

---

### Task 8: task_alt 테스터 아이콘 전역 스윕 (지시서 1.13, 1.17)

**Files:**
- Modify: `lib/screens/grammar_screen.dart:736-741` (앱바 `task_alt_rounded` 세션종료 IconButton 삭제)
- Modify: `lib/screens/review_session_screen.dart:326,360` / `lib/screens/custom_pack_play_screen.dart:371` (장식용 `Icons.task_alt_rounded` → `Icons.celebration_rounded`)
- Create: `test/tester_icon_sweep_test.dart`

- [ ] **Step 1: 실패하는 가드 테스트:**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task_alt 테스터 아이콘은 lib/ 에서 사라졌다 (지시서 1.13/1.17)', () {
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.readAsStringSync().contains('task_alt')) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
```

- [ ] **Step 2: FAIL 확인** — grammar/review_session/custom_pack_play 3파일 검출.
- [ ] **Step 3: 스윕** — ① grammar_screen: `grammar-finish-session` IconButton 과 그 주석 블록 삭제. `_finishSession`/`_sessionSeen` 이 다른 곳에서 안 쓰이면 함께 삭제(테스터 피드백 세션 종료 경로 제거 — 지시서 1.13 "제거" 확정). 이 Key 를 참조하는 테스트를 `grep -rn "grammar-finish-session" test/` 로 찾아 함께 삭제/수정. ② review_session·custom_pack_play: `Icons.task_alt_rounded` → `Icons.celebration_rounded` (장식 아이콘 — 기능 변화 없음).
- [ ] **Step 4: GREEN + `flutter test`** (grammar 관련 기존 테스트 회귀 확인)
- [ ] **Step 5: 커밋** — `git commit -m "fix(ui): task_alt 테스터 아이콘 전역 제거 + 재발 가드 (지시서 1.13/1.17)"`

---

### Task 9: 보상 영수증 시트 X 버튼 (지시서 4.17)

**Files:**
- Modify: `lib/screens/sori_stage/sori_stage_reward_receipt_sheet.dart:29-37`
- Test: 기존 receipt 시트 테스트 (`grep -rln "SoriStageRewardReceiptSheet" test/` 로 확인, 없으면 `test/sori_stage_reward_receipt_sheet_test.dart` 신설)

- [ ] **Step 1: 실패하는 테스트** — 시트를 pump 후:

```dart
    await tester.tap(find.byKey(const Key('receipt-close')));
    await tester.pumpAndSettle();
    expect(find.byType(SoriStageRewardReceiptSheet), findsNothing);
```

(신설 시: `showSoriStageRewardReceipt` 를 버튼 탭으로 여는 최소 MaterialApp 하네스 + 더미 `RewardReceipt` — `models/sori_stage_progression.dart` 의 생성자 시그니처 확인해 작성. l10n 은 기존 위젯 테스트들의 localizationsDelegates 패턴을 복사.)
- [ ] **Step 2: 구현** — eyebrow Text(:30-37)를 Row 로 감싼다:

```dart
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.soriStageReceiptEyebrow,
                      style: const TextStyle(
                        color: SoriColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('receipt-close'),
                    tooltip: t.btnClose,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
```

(`btnClose` 키는 arb 에 이미 존재 — review_session_screen.dart:329 사용례. raw TextStyle 은 이동만 — 신규 0, typography_guard 래칫 불변.)
- [ ] **Step 3: GREEN + analyze 후 커밋** — `git commit -m "feat(sori-stage): 보상 영수증 시트 X 닫기 버튼 (지시서 4.17)"`

---

### Task 10: 감사 스크립트 2종

**Files:**
- Create: `tool/audit_scenario_quests.py` — 시나리오 JSON(`assets/data/scenarios_*.json`) 전체에서 같은 시나리오 안 중복 퀘스트(동일 type+prompt/정답) 검출 → `docs/data/scenario_quest_report.md` (지시서 4.15 Bau satz 중복의 전수 검출; 수정은 W4 소유 — 여기선 리포트만)
- Create: `tool/audit_scene_assets.py` — 시나리오가 참조하는 씬 에셋 id ↔ `assets/` 실파일 대조, 오타·누락·고아 파일 검출 → `docs/data/scene_asset_report.md`

- [ ] **Step 1: 스키마 확인** — `assets/data/scenarios_*.json` 샤드 1개를 열어 퀘스트 배열·씬/에셋 참조 필드명을 확인하고, `lib/services/scene_asset_resolver.dart` (또는 grep `SceneAssetResolver`) 에서 에셋 해석 규칙(파일명 규약)을 확인.
- [ ] **Step 2: 두 스크립트 작성** — stdlib만, 결정적 정렬 출력, exit code 0(리포트 전용). 각 리포트 말미에 `## 요약` 건수.
- [ ] **Step 3: 실행 → 리포트 2개 생성·커밋** — `git commit -m "feat(tool): 시나리오 퀘스트 중복·씬 에셋 감사 스크립트 + 1차 리포트"`

---

### Task 11: audit_vocab_levels.py C1/C2 확장 (지시서 2.2)

**Files:**
- Modify: `tool/audit_vocab_levels.py:38` — `LEVEL_RANK = {"A1": 0, "A2": 1, "B1": 2, "B2": 3, "C1": 4, "C2": 5}`
- Modify(출력): `docs/data/vocab_level_report.md`, `tool/vocab_level_suspects.csv` 재생성

- [ ] **Step 1: LEVEL_RANK 확장** + 스크립트 내 B2 상한 가정(`grep -n "B2" tool/audit_vocab_levels.py`)이 있으면 함께 갱신.
- [ ] **Step 2: 재실행** — `python tool/audit_vocab_levels.py` → 리포트·suspects 재생성. C1/C2 행이 리포트에 나타나는지 확인.
- [ ] **Step 3: 커밋** — `git commit -m "feat(tool): 레벨 감사 C1/C2 확장 + 재감사 리포트 (지시서 2.2)"` — 오분류 재배치는 리포트를 Jin 이 검토한 뒤 Task 12 의 id-키 패치 도구로 적용(레벨 필드만, 검수 16).

---

### Task 12: 전 코퍼스 자연성 심사 + 승인 게이트 + 패치 도구

**Files:**
- Create: `tool/apply_naturalness_patch.py`
- Create(산출): `docs/data/naturalness_report.md`

**Interfaces:**
- Consumes: Task 3 의 `naturalness_candidates.md`
- Produces: `apply_naturalness_patch.py --patch <patch.json>` — `[{id, file, fields:{...}}]` 형식의 id-키 패치를 CSV/JSON 에 적용(구조 불변, 지정 필드만). `--level-only` 모드는 level 필드 외 거부(검수 16). 적용 후 cloze 가드 테스트 실행 안내 출력.

- [ ] **Step 1: 패치 도구 작성 + 자가 테스트** — 임시 사본에 더미 패치 적용→롤백하는 `--self-test` 플래그 포함, 실행해 통과 확인.
- [ ] **Step 2: LLM 심사** — 프리필터 후보를 배치(~30건)로 나눠 병렬 서브에이전트 심사(beyond-humanizer PIVOT 계약: 한국어 정본 판정 → DE/EN 독립 재구성, 영어 중간 정본 금지, cloze 는 정답 1개 유지). 산출: `docs/data/naturalness_report.md` — 항목별 `| id | 원문 | 판정 | 자연 한국어 최종안 | DE | EN | 근거 오류코드 |` + 배치별 승인 체크박스.
- [ ] **Step 3: Jin 승인 게이트** — 리포트를 Jin 에게 제시. **승인 전 코퍼스 적용 금지.** 승인분만 patch.json 으로 변환→적용→가드 GREEN→TTS 재생성(Task 6 스텝 3 재실행) 순서로 별도 커밋.
- [ ] **Step 4: 커밋(도구+리포트)** — `git commit -m "feat(tool): 자연성 id-키 패치 도구 + 전 코퍼스 심사 리포트 (승인 대기)"`

---

## Self-Review 결과

- 스펙 커버: W1 행의 8개 항목 전부 태스크에 대응 (자연성 파이프라인 T3/T12, 시드 T2, 생성기 게이트 T4, 가드 T1, Silben TTS T5, TTS 재생성 T6, 네이밍 T7, task_alt T8, X버튼 T9, 감사 2종 T10, 레벨 감사 T11)
- 실행 순서: T1→T2→(T3→T4)→T12 는 순차. T5→T6 순차. T7/T8/T9/T10/T11 은 상호 독립·병렬 가능 (파일 교집합 0)
- T6 스텝 3(GCP 재생성)과 T12 스텝 3(승인)은 외부 게이트 — 블록 시 나머지 태스크 진행에 영향 없음
