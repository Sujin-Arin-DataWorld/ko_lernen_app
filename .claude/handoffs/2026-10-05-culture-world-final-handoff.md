# 인수인계 — 문화세계 롤아웃 9/9 완료 + Batch 38 정본 승격 2026-10-05

> 이 문서는 Jin이 2026-10-05 세션에서 명시적으로 요청한 최종 인수인계서다.
> 구현 이력의 정본은 git log, 구조 인덱스는 Graphify, 상세 롤아웃 상태는
> `docs/plans/2026-10-05-culture-world-progress.md`를 우선한다.

## 상태 한 줄

문화세계 초기 계획 **Phase 1~9 전부 완료**. Batch 38의 5개 persona-culture 시나리오와
listening/culture-link/story-arc가 사용자 명시 승인 후 **정본 live 승격 완료**되었고,
현재 rollout branch의 시나리오 corpus는 **191개**다.

## 작업 브랜치

- branch: `session/culture-links-20261005-2026-10-05`
- worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\culture-links-20261005`
- remote: `origin/session/culture-links-20261005-2026-10-05`

최종 핵심 커밋:
- `080f6b036 feat(culture): promote batch 38 canonically`
- `376b88799 content(levels): align civic meeting vocabulary with B2`
- `79a84ffd3 docs(culture): close promoted rollout`

## 원래 문화세계 계획 기준 완료 상태

1. Scenario ↔ culture registry — 완료
2. CulturalGlossary expansion — 완료
3. Persona culture scenes — 완료 + live 승격
4. Scenario result culture card — 완료
5. Hanok Culture Stories — 완료
6. Tiger/Magpie presentation — 완료
7. Hahoe/Dokkaebi bridge — 완료
8. Existing reward/item reuse contract — 완료
9. Culture story arcs — 완료 + live 승격

두 번째 progression system은 만들지 않았다.
Culture metadata는 CanDo/XP/Yeopjeon/Bojagi/Hanok progression의 owner가 아니다.

## Batch 38 live 정본

승격된 5개 scenario:
- `b1_dongsun_norigae_shop_post`
- `b1_byeongcheol_hwaseong_memory_check`
- `a2_jun_hwaseong_school_slide`
- `c1_maya_hyuna_daniel_talchum_shortform`
- `b2_daniel_hyuna_hanji_filming_scope`

함께 승격된 것:
- scenario 5개
- scenario quest 15개
- listening lesson 5개
- listening question 20개
- scenario-culture link 5개
- curriculum links
- content audit metadata
- culture story arc `found_around_nammun`

현재:
- scenario corpus: **191**
- scenario quests: **594**
- Batch 38 audit: **5/5 live_verified_modern**
- Batch 38 manifest: **merged**
- review ledger: **5/5 approved**
- live story arcs: **1** (`found_around_nammun`)

## 최종 콘텐츠/레벨 검수

사용자 요청대로 단순 CEFR 단어 체크만 하지 않고 다음을 함께 감사했다:
- 어휘 레벨
- 문장 길이
- 문법 난이도
- 과업 복잡도
- 말투 / 인물 관계
- distractor 난이도
- listening 부담
- culture-anchor 예외 처리

증거:
- `tools/content_factory/review/persona_culture_level_fit_judgments_20261005.json`
- `tools/content_factory/review/persona_culture_vocab_leveling_20261005.json`

Batch 38 최종 vocab 결과:
- total: 30
- culture anchor: 6
- at/below target: 24
- above target: 0
- unmapped: 0

각 장면의 task complexity / register-relationship / distractor difficulty /
listening burden / culture exception은 모두 PASS.

사용자 승인 provenance는 기록하되 **native-speaker QA claim은 하지 않는다**.

## 전체 검증

최종 확인된 결과:
- Python/content/CEFR regression: **247/247 PASS**
- `validate_content.py`: PASS
- all-batch live-promotion audit: PASS
- Batch 38: **5/5 live**
- targeted Flutter analyze: **0 issues**
- culture UI/discovery/story-arc Flutter tests: **43/43 PASS**
- Graphify `check-update`: exit 0

## 레벨 감사 중 추가로 고친 기존 B2 부채

전체 191-scenario corpus 레벨 감사에서 기존 `회의 정족수`가 C2 fallback으로 잡혔다.
cap을 완화하지 않고 B2 학습자에게 더 직접적인 `참석자` 중심 표현으로 바꾸고
vocab / cloze / Satz를 함께 동기화했다.

결과:
- vocab fallback-over2 cap은 기존 **66** 유지
- 해당 표현으로 인한 새 regression 없음

관련 커밋:
- `376b88799 content(levels): align civic meeting vocabulary with B2`

## 핵심 문서

반드시 먼저 볼 것:
- `docs/plans/2026-10-05-culture-world-roadmap.md`
- `docs/plans/2026-10-05-culture-world-progress.md`
- `AGENTS.md`
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/manifest.json`

Batch 38 관련:
- `tools/content_factory/drafts/batch_38_persona_culture_manifest.json`
- `tools/content_factory/review/persona_culture_scenarios_20261005.csv`
- `tools/content_factory/review/batch_38_persona_culture_review_packet.md`
- `tools/content_factory/review/persona_culture_level_fit_judgments_20261005.json`

## TTS — 이번 세션에서 더 하지 않음

Jin이 **TTS는 VS Code에서 직접 작업**하기로 했다.

따라서 이 세션 종료 시점에는:
- 새 TTS 생성 작업 없음
- TTS 파일 일괄 덮어쓰기 없음
- voice mapping 변경 없음
- audio manifest 변경 없음

후속 세션은 TTS 작업을 자동으로 재개하지 말 것.
Jin이 직접 만든/확정한 TTS 산출물이 생기면 그때 별도 검증만 수행한다.

## TCC — 이번 마감 범위 밖

대화 중 TCC 후속작업 언급이 있었지만, 현재 repository 텍스트/branch/history에서
`TCC` 약어의 정본 정의를 찾지 못했다. 임의로 의미를 추정해 작업하지 않았다.

따라서:
- 이 문화세계 롤아웃 마감에는 TCC 변경 없음
- 다음 세션에서 TCC를 다시 시작하려면 먼저 정확한 plan/definition/source를 식별할 것

## 다음 세션에서 하지 말 것

- Batch 38을 다시 review-only로 되돌리지 말 것
- live scenario count를 186으로 되돌리지 말 것
- `culture_story_arcs.json`을 빈 catalog로 되돌리지 말 것
- culture 자체가 mastery/reward를 소유하도록 새 persistence를 만들지 말 것
- 사용자 승인 기록을 native-speaker QA로 과장하지 말 것
- TTS를 자동 생성/덮어쓰기 하지 말 것

## 종료 판정

이 인수인계 기준 문화세계 작업은 **완료**다.
후속은 별도 scope(TTS, TCC, device QA, broader level-normalization 등)로만 시작한다.
