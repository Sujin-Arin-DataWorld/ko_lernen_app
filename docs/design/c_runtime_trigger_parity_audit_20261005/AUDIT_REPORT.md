# C Runtime / Trigger Parity Audit — 2026-10-05

승인 C 시안 → 목업 → 현재 C WIP Flutter → `origin/main` → 기존 source audit를
분리해서 비교한다. 이 감사에서는 제품 로직을 수정하지 않는다.

## 최종 판정

**100% trigger parity: FAIL.** 콘텐츠 inventory와 루트 route 보존은 강하지만,
모든 live 콘텐츠를 새 C 목업/네이티브 화면에서 실제로 실행하는 증거는 아직 없다.

- source audit: `source_integrity_passed_with_declared_gaps` / checks 14,948 / hard errors 0 / declared gaps 556.
- C WIP HEAD `a1d798bda6`, origin/main `44727c1921`, ahead/behind `0	1`.
- dirty WIP entries: 274. C 디자인 통합은 아직 clean merged main이 아니다.
- Sori catalog WIP/main exact parity: `True` (21 entries).
- free-learning live counts match: `True`; ledger 8,514 rows / structural invalid 0.
- free-learning `app.mjs` exists: `False` (screen.html references it: `True`).
- direct Review trigger rows: 0.
- Settings/Profile old anchors current/main: 70/71 and 70/71; moved P12: `True`.

## Trigger Parity Matrix

| 범위 | 라이브 분모 | 디자인 | 목업 | Native | Trigger | 판정 |
|---|---|---|---|---|---|---|
| C root five tabs | 5 tabs / 13 Learn / 8 Games | approved | rendered | C WIP integrated | 21/21 root IDs/routes | **YELLOW** |
| Einleitung 7 | 7 stages | approved | rendered | integrated with current visual deltas | journey IDs preserved | **ORANGE** |
| Comprehensive course | 48 units / 30 phases / 902 tasks | 4 core scenes ready_for_review | standalone HTML | C entry only; inner integration followup | source mapped; task execution sampled | **ORANGE** |
| Foundation starter | 4 steps / 12 tasks (WIP only) | 8 screens | reviewed | C WIP imports | WIP route/task coverage | **YELLOW** |
| Whole Hangul | 34 letters + cards/writing | 8 inner screens | reviewed | existing live screen; no direct C inner import | route exists; C inner parity not proven | **ORANGE** |
| Free learning universal | 7 modules / 8,514 ledger rows | planned/data-bound | BROKEN: missing app.mjs | separate from catalog | structural rows only; UI execution impossible | **RED** |
| Vocabulary packs | 2,968 words / 254 packs | free-learning | data complete; app broken | live existing flow | all IDs structurally mapped | **RED** |
| Review / SRS / My Words | 2,968 base words + user data / 10 My Words routes | review-card subset | no direct review ledger rows | live existing flows | per-ID review proof incomplete | **RED** |
| Grammar | 264 records + 43 pattern notes | free-learning | data complete; app broken | live existing flow | 264 IDs mapped | **RED** |
| Pronunciation | 84 phrases | free-learning | data complete; app broken | live existing flow | 84 IDs mapped | **RED** |
| Listening | 186 lessons / 744 questions | free-learning | data complete; app broken | live existing flow | lesson/question rows mapped | **RED** |
| Scenarios | 186 scenarios / 579 quests | free-learning | data complete; app broken | live existing flow | scenario/child rows mapped | **RED** |
| Word relations | 114 clusters | free-learning | data complete; app broken | live existing flow | cluster/child rows mapped | **RED** |
| Small Talk / TalSunbi | 209 lessons / 590 phrases | separate tactile/TalSunbi work | not in universal free-learning | live existing/tactile flow | root route only in C catalog | **ORANGE** |
| Book capture / notebook | 8 registered routes | Einleitung sample only | no full C flow | live existing flow | root/full routes exist; not C-mocked | **ORANGE** |
| Daily calligraphy | 34 Hangul records | no dedicated inner C mockup found | not in free-learning | live existing flow | root route only | **ORANGE** |
| Games root + interiors | 8 entries; cloze 2365 / Satz 2885 + other pools | C root approved; Silben dedicated | no all-game content ledger | 8 roots preserved | 8/8 root routes; internal parity incomplete | **ORANGE** |
| Silben + Dokkaebi | 120 puzzles / 415 word occurrences | 12-plan -> 14 reviewed scene kinds | state images exist | help/motion exists; exact C inner parity open | /wordle preserved | **ORANGE** |
| Settings + Profile | 71 existing anchors + 1 proposed iOS action | 16 PNG screens | gallery/contract only | mockup runtimeIntegration=false | 70 old anchors + moved P12; iOS proposal not live | **ORANGE** |
| Hanok / Gye / Rewards | stateful live services | approved C root + reward assets | representative states | C WIP integrated/reported tests | route/state contracts; backend/device proof pending | **YELLOW** |
| Productive authoring drafts | 118 definitions / 8 projects / 32 snippets / 16 bundles | not runtime | must stay excluded | runtimeContentApproved=false | correctly blocked | **OUT_OF_RUNTIME** |

## 핵심 발견

### P0 — 자유학습 universal mockup은 현재 부팅 불가

`c_free_learning_mockup_20261005/screen.html`은 `app.mjs?v=1`을 로드하지만 그 파일이 없다.
따라서 8,514개의 URL ledger가 정확해도 실제 UI trigger 증거가 될 수 없다.

### P0 — 21/21 루트 진입과 콘텐츠 100% 진입은 별개

13 Learn + 8 Games 루트 ID/route는 WIP와 main에서 일치한다. 그러나 Small Talk 209/590,
Cloze 2,365, Satz 2,885, Book/Notebook 8 routes, Calligraphy, My Words 사용자 데이터 등
내부 live corpus 전수에 대한 새 C mockup trigger 증거는 없다.

### P0 — source audit hard error 0은 UI parity 100%가 아니다

기존 `c_content_audit/ACCEPTANCE.md`도 실제 UI 선택→재생→평가→저장→복귀를
최종 미체크 수용조건으로 남긴다. source/hash/binding 무결성과 실행 UI는 다른 층이다.

### P1 — Course / Whole Hangul / Settings·Profile은 내부 C parity가 아직 부분적

Course는 48 units / 30 phases / 902 tasks를 보존하지만 task 실행은 대표 표본이다.
Whole Hangul의 새 내부 8화면은 기존 `/hangul` 내부에 직접 C 통합됐다는 증거가 없다.
Settings/Profile 16장도 artifact 자체가 `runtimeIntegration=false`다.

### P1 — Einleitung 승인 시안 차이가 현재 코드에도 남음

현재 `c_onboarding.dart`에는 HANGUL SORI 헤더, 02–06 preview CTA, 페이지별 continue label,
07 Details가 남아 있어 승인 비트맵과 100% 외형 일치가 아니다.

## 신뢰 가능한 부분

- live 데이터 분모(2,968/254/264/84/186/744/186/579/114)는 현재 소스와 일치한다.
- 8,514 ledger row의 parent/child 구조는 이 감사기의 독립 검사를 통과한다.
- Sori catalog 21개 ID/route는 WIP와 `origin/main`에서 같다.
- Productive draft는 `runtimeContentApproved=false`로 live 분모에서 제외된다.

## 100% 완료 조건

1. `app.mjs` 구현/복구 후 8,514 URL 전수 headless navigation/render 검증.
2. Review/SRS의 per-ID 직접 trigger 계약을 별도로 증명.
3. 13 Learn + 8 Games 각각 root뿐 아니라 내부 live corpus까지 coverage 원장화.
4. Small Talk, Calligraphy, Book/Notebook, My Words user/custom, Cloze/Satz 누락 범위 보강.
5. Course 902 task와 Whole Hangul 내부 화면을 C native UI와 연결해 전수 ID 계약 검사.
6. Settings/Profile 16장 native callback wiring + 기존 71동작 보존 + iOS 제안 분리.
7. Einleitung 승인 시안 차이 해소.
8. latest `origin/main`으로 WIP 재조정 후 source audit + parity audit 재실행.
9. Android/iOS 실기기·스크린리더·최종 인간 디자인 승인 후에만 100%/ship-ready 판정.

## 재실행

```powershell
python -X utf8 tool/audit_c_runtime_trigger_parity.py
python -X utf8 tool/content_screen_audit.py check
graphify update .
```

기계 판독 원장: `TRIGGER_PARITY_MATRIX.json`.
