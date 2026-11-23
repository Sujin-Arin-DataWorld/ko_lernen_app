# 전체 원고 교차 검토 — 고정 범위와 산출물

2026-11-15 사용자가 여기까지 압축·커밋하고 전체 검증 및 한영·한독 교차 재검토를 계획해 실행하도록 요청했다. 기존 앱과 음성 변경 금지는 유지된다. 이 지시는 과거 AUTHORING_BRIEF의 artifact 전용 경로를 이번 docs 전용 worktree까지 확장한다.

## 읽을 대상과 기준

- 이 패키지의 `manuscripts/*.md` 100편을 모두 읽는다. 이전의 성공 보고를 이번 읽기의 대체물로 쓰지 않는다.
- `AUTHORING_BRIEF.md`, `TERM_AND_TRANSLATION_NOTES.md`, `SERIES_EDITORIAL_MAP.md`, `READER_INTRODUCTION.md`, `CURRICULUM_REUSE_NOTES.md`, `README.md`.
- `sources/LEVEL_STORY_100.json` 해당 단원의 `spoiler_gate`와 장면, `FOUNDATION.psv`, `UNITS.psv`, `WORLD_AND_STORY_BIBLE.md`.
- 저장소 `docs/CONTENT_LEVEL_BIBLE.md` §B·§C·§D. 원고 과제의 수용/산출 범위와 개별 단원 배정을 우선 세밀하게 대조한다. 입문 서사의 한국어 전문을 곧바로 읽기 평가 범위로 세지 않는다.
- 필요한 정본 대사: 읽기 전용 `C:/dev/hangulsori/ko_lernen_app_worktrees/season1-runtime-integration-20261103/docs/learning/ildu-season1-content-20261030/reference/STORY_V3_5.md` 및 `reference/curriculum/BAND_CONTRACTS.md`, `GRAMMAR_ALLOCATION.csv`.
- 첫 책 정본 인용 9개, 1회 각성, 도움/독립 수행 분리; E06 이름·가족, E07 익명씨앗, E08 분산보관, E11 보호동기·평생발신인 공개 조건. 새 소유·보상·엔딩 조건 금지.

## 역할과 쓰기 경계

모델은 모두 gpt-6-astra, effort max. `ko-en`, `ko-de`, `curriculum`은 각자의 검토 폴더에만 쓴다. 원고는 검토 중 고정한다. Root만 통합 교정한다. 다른 에이전트를 추가로 만들지 않는다. Beyond Humanizer 사용 금지. DE 검토는 du/Sie-check를 관계별로 적용할 수 있으나 학습자 안내의 du와 등장인물 간 호칭을 혼동하지 않는다.

한영: KO↔EN 모든 단어 뜻·품사·예문·자료·지시·대본·문답·스몰토크·평가 기준. 한독: 같은 범위의 KO↔DE, 문체·관계·자연스러움. 두 역할은 문제를 답안보다 먼저 텍스트로 풀고 명시된 답과 비교한다. 청취 대신 대본 풀이임을 표시한다. 서사 역할: 100개 연결표와 과제 자료의 실질 정합, 난도·선행학습, 정답 유일성/열린 허용, 사실 공개와 현대 대안.

## 검토의 단위

16구간을 한 구간씩 처리하고 결과를 즉시 저장한다. 3–11편을 한 번에 통째 출력하지 말고 1–2편씩 읽어 맥락을 보존한다. 요약만 보고 전편 검토라고 하지 않는다. 근거를 짧게 저장하며 끝까지 계속한다. 구간 순서는 F0.1, F0.2, F0.3, F0.4, A1.1, A1.2, A2.1, A2.2, B1.1, B1.2, B2.1, B2.2, C1.1, C1.2, C2.1, C2.2이다.

각 구간 `<band>.md`에는 단원별 판정, 과제별 실제 답/허용답과 근거, 오류 위치·이유·수정안, 수준/언어/이야기 경계를 기록한다. 표현 취향만으로 일괄 재작성하지 않는다. 고택 이야기는 읽는 콘텐츠이며 현대 듣기와 구별한다. 자연스러운 다른 답을 억지로 오답 처리하지 않는다.

각 구간 `<band>.json`:

```json
{
  "role": "ko-en",
  "model": "gpt-6-astra",
  "effort": "max",
  "units": [{"unitId":"...","sha256":"...","fullTextRead":true,"tasksSolvedAsText":true,"verdict":"PASS or NEEDS_FIX","findingIds":[]}],
  "findings": [{"id":"EN-F01-01","unitId":"...","severity":"required or optional","location":"heading and exact phrase","problem":"concrete mismatch","proposal":"exact replacement or full replacement section","affectedLanguages":["KO","EN","DE"]}]
}
```

`COMMON.md/json`는 6개 공통 문서의 검토를 별도로 기록한다. 마지막 `SUMMARY.md`에는 읽은 100개와 아직 못 읽은 파일을 정확히 구별한다. 종료 전 100개 ID를 원본 연결표와 대조한다. 수정은 제안이며 반영·재검토 전 PASS로 승격하지 않는다. Root가 교정 후 재검토를 다시 요청한다.

## 완료의 의미

100단원 전체에 두 언어의 현재 SHA 검토와 과제 풀이가 있어야 모델 원고 교차 검토 완료다. 이는 인간 통번역가 인증, 원어민 청취, 앱 실행, 학생 난이도 검증이 아니다. 실제 음성은 재생/합성하지 않는다. 기계 검사로 의미·교수 품질을 대체하지 않는다.
