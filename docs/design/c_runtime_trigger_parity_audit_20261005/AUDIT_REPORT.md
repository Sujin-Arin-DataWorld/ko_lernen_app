# C Runtime / Trigger Parity Audit — 2026-10-06

승인 C 시안, HTML 목업, Flutter WIP, `origin/main`, source audit를 서로 다른 증거 층으로 분리해 검증한다.

## 현재 판정

**RUNTIME_TRIGGER_PASS_PIXEL_PARITY_PENDING**

런타임 trigger 층은 통과했다. 다만 이것은 모든 화면의 픽셀 100% 일치나 실기기 최종 승인까지 끝났다는 뜻이 아니다.

- source audit: `source_integrity_passed_with_declared_gaps` / checks 14,948 / hard errors 0 / declared gaps 556.
- C WIP HEAD `711be6a3dd`, origin/main `44727c1921`, ahead/behind `1	0`.
- Sori catalog exact parity: `True` (21 entries = 13 Learn + 8 Games).
- free-learning content counts match live source: `True`; ledger 8,514 rows / structural invalid 0.
- free-learning app entrypoint present: `True`.
- real Chrome ledger audit: `PASS` / tested 8,514 / failed 0 / zero-text 0.
- native C: free=True, course path+mission=True, Hangul=True, settings hub=True, settings details=True, profile=True, Silben=True.
- Silben golden evidence: `True`.
- Settings/Profile original action anchors: current 70/71, origin/main 70/71; moved P12 verified `True`.

## Trigger / Design Matrix

| 범위 | 라이브 분모 | 디자인 | 목업 증거 | Flutter | Trigger | 판정 |
|---|---|---|---|---|---|---|
| C root five tabs | 5 tabs / 13 Learn / 8 Games | approved | rendered | C WIP integrated | 21/21 root IDs/routes | **YELLOW** |
| Einleitung 7 | 7 stages | approved | rendered | integrated with known visual deltas | journey IDs preserved | **ORANGE** |
| Comprehensive course | 48 units / 30 phases / 902 tasks | 4 core scenes | standalone HTML | C path + mission native | source mapped; inner learn/result pixel parity pending | **YELLOW** |
| Foundation starter | 4 steps / 12 tasks (WIP only) | 8 screens | reviewed | C components imported | WIP route/task coverage | **YELLOW** |
| Whole Hangul | 34 letters + cards/writing | 8 inner screens | reviewed | C shell + existing live internals | all existing Hangul behaviors retained; exact inner pixel parity pending | **YELLOW** |
| Free learning universal | 7 designed modules / 8,514 ledger rows | data-bound C mockup | 8,514/8,514 real-Chrome PASS | native C landing wired | all ledger URLs render in Chrome; native deep screens reuse production routes | **YELLOW** |
| Vocabulary packs | 2,968 words / 254 packs | free-learning | all IDs browser-rendered | C landing -> live existing flow | 2,968 word + 254 pack URLs pass | **YELLOW** |
| Review / SRS / My Words | 2,968 base words + user data / My Words routes | review-card subset + native C landing | base-word review UI works; direct review ledger remains separate | C landing -> live SRS/My Words | user/custom runtime parity still requires account-state tests | **ORANGE** |
| Grammar | 264 records + 43 pattern notes | free-learning | 264 IDs + extras render | C landing -> live grammar | browser ID coverage PASS | **YELLOW** |
| Pronunciation | 84 phrases | free-learning | 84 IDs render | C landing -> live pronunciation | browser ID coverage PASS | **YELLOW** |
| Listening | 186 lessons / 744 questions | free-learning | 930 lesson/question URLs render | C landing -> live listening | browser ID coverage PASS | **YELLOW** |
| Scenarios | 186 scenarios / 579 quests | free-learning | scenario/child URLs render | C landing -> live scenarios | browser ID coverage PASS | **YELLOW** |
| Word relations | 114 clusters | free-learning | cluster/child URLs render | C landing -> live word web | browser ID coverage PASS | **YELLOW** |
| Small Talk / TalSunbi | 209 lessons / 590 phrases | separate tactile/TalSunbi work | not in universal per-ID ledger | C landing -> live tactile flow | root route preserved; per-ID C parity pending | **ORANGE** |
| Book capture / notebook | 8 registered routes | Einleitung sample + C landing | no full C deep-flow mockup | C landing invokes production capture chooser | live route/choice preserved | **ORANGE** |
| Daily calligraphy | 34 Hangul records | C landing only | no dedicated inner C mockup | C landing -> live calligraphy | root route preserved | **ORANGE** |
| Games root + interiors | 8 entries; cloze 2365 / Satz 2885 + other pools | C root approved; Silben dedicated | no all-game per-content ledger | 8 roots preserved | 8/8 root routes; internal pixel parity incomplete | **ORANGE** |
| Silben + Dokkaebi | 120 puzzles / 415 word occurrences | 12-plan -> 14 reviewed scene kinds | approved state images + 390 golden | C jade/paper/oak shell + Dokkaebi help/motion | /wordle preserved; core behavior tests pass; golden present | **YELLOW** |
| Settings + Profile | 71 existing anchors + 1 proposed iOS action | 16 PNG screens | approved gallery | C hub=True, C details=True, profile overview=True | typed section routing + legacy callbacks preserved; device pixel sign-off pending | **YELLOW** |
| Hanok / Gye / Rewards | stateful live services | approved C root + reward assets | representative states | C WIP integrated/reported tests | route/state contracts; backend/device proof pending | **YELLOW** |
| Productive authoring drafts | 118 definitions / 8 projects / 32 snippets / 16 bundles | not runtime | must stay excluded | runtimeContentApproved=false | correctly blocked | **OUT_OF_RUNTIME** |

## 이번 패스에서 닫힌 항목

- 누락됐던 free-learning `app.mjs`를 복원하고 기존 model/catalog/detail/word 모듈을 실제 앱으로 조립했다.
- `catalog.mjs`의 `size(module, model)` 런타임 오류를 수정했다.
- 실제 Chrome에서 trigger ledger **8,514/8,514 URL**, 실패 0, 빈 텍스트 0을 확인했다.
- Flutter `/free-learning` C landing과 production Learn 12개 비-course entry 연결을 검증했다.
- Settings C hub + C detail 화면을 실제 `/settings/detail` 경로에 연결하면서 기존 callback/저장 로직을 유지했다.
- Silben 기본 플레이 화면을 C 녹청/한지/원목 shell로 재배치하고 단서 번호·방향, 4×2 음절 타일, 도깨비 help/motion, C Hint CTA를 유지했다.
- Silben 핵심 회귀 테스트와 390×844 golden evidence를 추가했다.

## 아직 100% pixel parity라고 부르지 않는 이유

1. Einleitung 승인 원본과 현재 C onboarding 사이의 알려진 시각 차이(헤더/preview CTA/page별 continue/07 details)를 닫아야 한다.
2. Course path/mission은 C native지만 learn/result 내부 상태의 승인 PNG 대비 픽셀 검증이 남아 있다.
3. Whole Hangul은 C shell이 연결됐지만 8개 내부 상태를 승인 목업과 상태별 golden으로 닫아야 한다.
4. Review/SRS/My Words의 사용자 상태, Small Talk, Book/Notebook, Calligraphy, 나머지 Games 내부 콘텐츠는 root trigger와 별개로 화면별 C pixel parity가 남아 있다.
5. Android/iOS safe area, 200% text, 스크린리더, 실제 asset/video 렌더는 최종 실기기 승인 게이트가 필요하다.

## 재실행

```powershell
python -X utf8 tool/verify_c_free_learning_urls.py
python -X utf8 tool/audit_c_runtime_trigger_parity.py
python -X utf8 tool/content_screen_audit.py check
flutter test test/widgets/c_settings_profile_hub_test.dart test/widgets/c_settings_detail_test.dart test/widgets/c_free_learning_screen_test.dart test/foundation_learning_screen_test.dart test/silben_dokkaebi_screen_test.dart test/silben_grid_clue_sync_test.dart
graphify update .
```

기계 판독 원장: `TRIGGER_PARITY_MATRIX.json`; 실제 브라우저 증거: `FREE_LEARNING_BROWSER_AUDIT.json`.
