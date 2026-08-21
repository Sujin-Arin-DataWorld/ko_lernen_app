# 콘텐츠 텍스트 정합화 작업 원장

이 원장은 PDF 참고자료를 복제하지 않고, 현재 앱이 실제로 읽는 학습 텍스트를
KO·DE·EN의 같은 의사소통 사건으로 검수하기 위한 작업 기준이다.

## 범위와 정본 확인

`python tools/content_factory/audit_content_text.py --check`는
`assets/data`의 22개 파일을 모두 명시적으로 분류한다. 새 파일이 추가되면
분류되지 않은 파일로 실패한다. 이 도구가 다루는 것은 런타임 정본이며,
draft·review·generator는 해당 레코드의 출처를 확인하기 위한 동반 자료다.

각 변경 전 다음을 확인한다.

- [x] ID, level, courseUnitId, conceptIds, quiz 정답, 배열 순서, TTS 대상 KO가 보존되는가.
- [x] 생성기 또는 review-only draft가 현재 정본이면 source → draft → runtime asset을 함께 바꾸는가.
- [x] KO 문장이 실제 한국어 발화로 자연스러운가. 목표 문법·어휘는 유지되는가.
- [x] DE와 EN은 서로 번역하지 않고 KO의 동일 PIVOT(사실·화행·관계·문화·학습 목표)에서 재작성했는가.
- [x] Cloze는 정답이 정확히 하나인가. Satz는 targetKo·promptDe·promptEn·distractors 조립 계약이 유지되는가.
- [x] 이미 승인된 live 문구를 고치면 과거 review 행을 덮어쓰지 않고, 변경 사유와 before/after를 별도 revision review에 남겼는가.

## 레벨 선택 계약

학습자가 지금 하는 활동의 난이도는 콘텐츠 파일의 총량과 별개의 런타임 계약이다.

- [x] `DailyChallengeScreen`은 user level이 있으면 정확히 같은 level의 Cloze만 선택한다. 해당 level의 문항이 10개보다 적어도 하위 level로 보충하지 않는다.
- [x] `ReviewDeckService.todaySelectionForLevel`과 `PersonalizedLessonService`의 오늘 어휘는 신규와 SRS 복습 모두 정확 level만 쓴다. 따라서 C1/C2의 오늘 덱에 A1 `안녕하세요`가 오래된 복습 일정만으로 다시 들어오지 않는다.
- [ ] 누적 노출이 학습 설계상 필요한 게임(예: 끝말잇기)은 UI에 누적임을 표시하고, exact-level 활동처럼 보이게 하지 않는다.

`오늘의 복습`에서 하위 레벨을 다시 복습시키려면 현 덱에 조용히 섞지 말고, 사용자가 명시적으로 선택한 별도 복습 경로로 설계한다.

## 2026-08-21 revision overlay

`tools/content_factory/review/content_humanization_20260821.json`은 이미 승격된
Smalltalk의 과거 승인 원장을 다시 쓰지 않기 위한 append-only 수정 계층이다. 60개
레코드, 104개 DE/EN 필드의 before/after와 결함 분류를 보관한다.

- `python tools/content_factory/apply_content_humanization.py`는 before 값이 정확히
  일치할 때만 overlay를 적용한다.
- `python tools/content_factory/apply_content_humanization.py --check`와
  `validate_content.py`는 runtime이 overlay와 다르면 실패한다.
- A1-B2에서 수정된 42개 레코드는 can-do 의미 경로를 바꾸지 않고 현재·직전 문구
  fingerprint와 `nativeReviewRequired` copy gate를 함께 기록한다.
- `humanReviewStatus`는 `required_before_native-quality-claim`로 고정한다. 이 기계
  검수는 독일어·영어 원어민 또는 한국어교육 전문가의 최종 승인을 대신하지 않는다.
- 과거 draft/review는 당시 승인 증거이므로 수정하지 않는다. 현재 runtime 수정의
  정본은 원문 계보 + 이 revision overlay의 조합이다.

## 우선순위

1. 레벨 전달: 선택기가 C1/C2에 A1 항목을 섞지 않아야 한다.
2. 시나리오: 대화, 퀘스트, 문화 노트의 관계·높임·화행을 한 장면 단위로 함께 검수한다.
3. 문항: cloze·satz·발음은 정답 유일성과 DE/EN 목적어/대명사 추론을 먼저 본다.
4. 카탈로그: 어휘·문법·can-do·문화·관계망은 짧은 설명이 학습자 오해를 만들지 않는지 검수한다.
5. 보조 게임: 끝말잇기·음절 퍼즐·미디어 문구는 빈 번역, 활용형 조각, 가짜 단일 글로스를 금지한다.

## 현재 B1–C2 런타임 기준선

`LoaderCoverageAudit`로 앱이 실제 읽는 route를 확인한 결과다. 아래 수는 단순 파일
행 수가 아니라 course loader가 연결한 수이며, 네 핵심 활동에는 B1–C2 zero-unit가 없다.

| level | scenario | smalltalk | cloze | Satzbau |
| --- | ---: | ---: | ---: | ---: |
| B1 | 73 | 72 | 275 | 468 |
| B2 | 68 | 100 | 361 | 519 |
| C1 | 45 | 32 | 220 | 222 |
| C2 | 41 | 32 | 220 | 222 |

따라서 이 레벨의 빈 화면은 총량 부족이라고 단정하면 안 된다. 우선 exact-level 선택,
course-unit route, 화면의 필터/empty state를 각각 분리해 확인한다. C1/C2의 6개 unit도
scenario·smalltalk·cloze·Satz target을 모두 충족한다. 이후 확장은 수량을 무작정
늘리기보다, 같은 unit 안의 상황·관계·화행 다양성을 늘리는 방식으로 잡는다.

## 변경 단위

한 단위는 단어만, 또는 독일어만이 아니다. 아래 중 하나를 하나의 PIVOT 묶음으로
관리한다.

- 어휘 1개: 표제어 + KO 예문 + DE/EN 예문 + 파생 cloze/satz/smalltalk 검색 결과
- 문법 1개: KO 예문 + DE/EN 설명·예문 + quiz focus·distractors
- 시나리오 1개: title/intro + vocab + grammar block + 모든 dialog/quest/cultural note
- 게임 문항 1개: KO prompt + 정답 + 오답 + DE/EN 설명 또는 prompt

자동 검사는 범위 누락, 깨진 Unicode, 금칙 표현, 빈 marker, schema/그래프/ID만
막는다. Accuracy·relationship·culture·CEFR의 최종 native-speaker/한국어교육
전문가 검수는 별도 gate로 남긴다.

## 실행 게이트

```powershell
python C:\Users\vjinn\.agents\skills\beyond-humanizer\scripts\validate-unicode.py
python C:\Users\vjinn\.agents\skills\beyond-humanizer\scripts\validate-rejected-phrases.py
python tools/content_factory/audit_content_text.py --check
python tools/content_factory/validate_content.py
python -m unittest discover -s tools/content_factory -p "test_*.py"
```

콘텐츠 변경 뒤에는 해당 Flutter loader/contract 테스트와 TTS dry-run도 추가한다.
실제 TTS 합성·Storage 업로드·Firebase 배포는 이 원장의 범위가 아니다.

## 기준선과 열린 정합성 부채 (2026-08-21)

`origin/main`의 별도 임시 worktree와 이 작업 브랜치에서 각각 전체 factory 스위트를
실행했다. clean `origin/main`은 **4 failures / 20 errors**, 최종 작업 트리는
**3 failures / 20 errors**다. Batch 10 문구 검사가 하나 개선됐고, 남은 항목은 이
원장의 문구·레벨 변경이 만든 회귀가 아니다. 다만 아래 항목은 정합성 전용 작업에서
수정해야 하며, 이 상태를 green이라고 부르면 안 된다.

- Batch 06 merged overlay와 현재 live scenario가 byte-exact하지 않다.
- can-do 생성기의 published history가 현재 smalltalk seed cluster와 맞지 않는다.
- Batch 09/10, review-batch validators가 오래된 course/grammar/route reference를 active draft처럼 다시 검증한다.
- Batch 10의 장면별 문법·오답·반복 검사는 이번 작업에서 통과하도록 고쳤다.
- reference intake validator는 review-only draft까지 한 content pool에 합쳐 duplicate ID를 보고한다.

이번 배치의 개별 콘텐츠/loader 검사는 통과해도 위 전체 gate가 해결되기 전에는
"전체 콘텐츠 팩토리 green"이라고 주장하지 않는다.
