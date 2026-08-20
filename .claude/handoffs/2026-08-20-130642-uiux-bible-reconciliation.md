# Handoff: UI/UX 디자인 바이블 정합화와 반응형 접근성 이식

## Session Metadata
- Created: 2026-08-20 13:06:42
- Project: `C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app_worktrees\uiux-bible-reconcile-20260820`
- Branch: `codex/uiux-bible-reconcile-20260820`
- Base: `origin/main` at `9ba9af4befd2860da60544153d3d568348ac364a`
- Session duration: 약 4시간

## Handoff Chain

- **Continues from**: [2026-08-20-052546-session-rules-skills.md](./2026-08-20-052546-session-rules-skills.md)
  - Previous title: SESSION_LOG 폐지 + DE/EN 스킬 설치
- **Supersedes**: None

## Current State Summary

`UIUX_Audit_DesignBible_Idea.md`와 `origin/cursor/main-home-critique-b6be`를 최신 UI 정본과 대조했다. Cursor 브랜치는 통째로 병합하지 않았고, 최신 `main`에서 SafeArea 내부 높이 계산, 320dp/200% 텍스트의 문구·행동 도달성, 허브/월드 의미 폭 토큰을 기존 `Sori*` 체계로 다시 구현했다. 원 제안서는 감사 아이디어로만 취급하며 SSoT로 승격하지 않는다. `flutter analyze`는 오류 0개, 타깃 72개와 가드 781개는 통과했으며 전체 테스트는 4,108개 통과·플랫폼 전용 14개 skip·실패 0이다. PR CI만 남았다.

## Codebase Understanding

### Architecture Overview

- UI/UX 구현 정본은 `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`이며 새 감사 문서가 이를 대체하지 않는다.
- 공용 UI 계층은 `lib/widgets/sori`이다. 새 `hs_ui` 패키지를 만들지 않는다.
- 창 분류는 `compact/medium/expanded`를 유지하고, 화면 의미 폭은 `SoriMaxWidth`로 명명한다.
- `SafeArea` 바깥의 `MediaQuery.height`가 아니라 내부 `LayoutBuilder` 제약이 실사용 높이의 기준이다.

### Critical Files

| File | Purpose | Relevance |
|------|---------|-----------|
| `lib/screens/sori_stage/sori_stage_common.dart` | Sori Stage 공용 viewport | SafeArea 내부 최소 높이와 스크롤 계약 |
| `lib/screens/sori_stage/sori_stage_hanok_screen.dart` | Hanok 탭 | 큰 글자에서 세로 스크롤과 shortcut 재배치 |
| `lib/screens/sori_stage/sori_stage_today_screen.dart` | Today 탭 | 보자기 CTA 문구·Semantics·도달성 |
| `lib/widgets/sori/stats_top_bar.dart` | 상단 상태 영역 | 320dp/200%에서도 로고, 레벨, 연속 학습 행동 보존 |
| `lib/widgets/sori/window_class.dart` | 반응형 토큰 | hub/world 의미 폭 880/960 |
| `test/sori_stage_adaptive_chrome_test.dart` | 적응형 회귀 | 크기·언어·배율·SafeArea 매트릭스 |

### Key Patterns Discovered

- 고정 높이는 표준 390x844 시각 계약을 위한 최소값일 뿐이며, 짧은 화면과 큰 글자에서는 `SoriMinHeightScroll`로 도달성을 보장한다.
- 핵심 CTA 문구는 `ellipsis`로 숨기지 않고 필요 시 세로 배치한다.
- DE/EN은 UI 로케일이고 한국어는 학습 콘텐츠이므로 KO UI 추가를 전제로 하지 않는다.

## Work Completed

### Tasks Finished

- [x] 모든 기존 작업트리 WIP를 독립 원격 브랜치로 보존하고 SHA-256 목록을 생성했다.
- [x] 사용자 main 작업트리를 `origin/main`과 동일하고 clean한 상태로 맞췄다.
- [x] Cursor 브랜치의 문서 SSoT 충돌, SESSION_LOG 위반, SafeArea 오류와 텍스트 절단을 검토했다.
- [x] 선택 가능한 반응형·접근성 아이디어를 최신 main에서 다시 구현했다.
- [x] 타깃 테스트 72개를 통과했다.
- [x] `flutter analyze`와 전체 `flutter test`를 통과했다.

### Files Modified

| File | Changes | Rationale |
|------|---------|-----------|
| `lib/widgets/sori/button.dart` | 핵심 CTA에 무제한 줄바꿈 선택지 추가 | 문구 ellipsis 금지 |
| `lib/widgets/sori/window_class.dart` | `hub`, `world` 의미 폭 추가 | 화면별 raw 숫자 제거 |
| `lib/screens/sori_stage/sori_stage_common.dart` | `SoriStageSafeViewport` 추가 | SafeArea 내부 높이 계산 |
| `lib/screens/sori_stage/sori_stage_gye_screen.dart` | 공용 viewport와 hub 폭 사용 | 공통 계약 재사용 |
| `lib/screens/sori_stage/sori_stage_hanok_screen.dart` | 큰 글자 스크롤 및 shortcut 세로 배치 | 200% 접근성 |
| `lib/screens/sori_stage/sori_stage_today_screen.dart` | 보자기 CTA 적응형 배치와 Semantics | 전체 문구·행동 도달성 |
| `lib/widgets/sori/stats_top_bar.dart` | 좁은 화면/큰 글자 2행 상태바 | 상태 행동 숨김 방지 |
| `lib/screens/gye_tab_screen.dart` | hub 폭과 다중행 CTA | 의미 폭/문구 보존 |
| `lib/screens/hanok_world_screen.dart` | world 폭 토큰 | raw 폭 제거 |
| `lib/services/word_relation_service.dart` | null-aware lint 정리 | 전체 analyze 초록 준비 |
| `test/sori_stage_adaptive_chrome_test.dart` | 신규 매트릭스 회귀 | 계획의 직접 증거 |
| 기존 반응형/window 테스트 | 크기·배율 및 의미 폭 케이스 확장 | 회귀 범위 확대 |

### 디자인 바이블 대조표

| 제안 | 판정 | 현재 코드 적용 |
|------|------|----------------|
| 인간 중심 계층, semantic token, 스크롤 도달성 | 채택 | 기존 `Sori*`와 회귀 테스트로 적용 |
| DE/EN/KO UI | 수정 | UI는 DE/EN, 한국어는 학습 콘텐츠 테스트 |
| Noto/Pretendard 폰트 | 수정 | Wanted Sans와 현행 라이선스 유지 |
| 별도 `hs_ui` 패키지 | 기각 | `lib/widgets/sori` 재사용 |
| 4단계 breakpoint | 수정 | compact/medium/expanded 유지·확장 |
| raw 값 즉시 전면 금지 | 수정 | 의미 토큰 추가 후 테스트 래칫으로 감소 |
| 새 문서를 SSoT로 선언 | 기각 | 현행 UI Overhaul 2 정본 유지 |
| 고정 높이/ellipsis로 밀도 해결 | 기각 | 세로 배치와 도달 가능한 스크롤 사용 |

종합 판정은 철학·방향 약 80% 적합, 현재 코드 기반 약 60% 존재, 문서 그대로 적용 가능 약 40%다.

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
| Cursor 전체 병합 금지 | merge, cherry-pick, clean-room 이식 | 정본/로그 규칙 위반과 접근성 결함을 함께 들이지 않기 위해 최신 main에서 재구현 |
| 제안서를 비권위 감사자료로 유지 | 새 SSoT, README 포인터 추가, 백업만 보존 | `AGENTS.md`와 UI Overhaul 2의 단일 정본 계약 유지 |
| 기존 Sori 시스템 확장 | 별도 패키지, 화면별 상수 | 중복 디자인 시스템 방지 |

## Pending Work

### Immediate Next Steps

1. 커밋·푸시 후 검증용 PR을 열고 current-head CI가 모두 초록인지 확인한다.
2. CI가 완전히 초록일 때만 `origin/cursor/main-home-critique-b6be`를 삭제한다.
3. PR을 main에 병합하거나 배포하지 않는다.

### Blockers/Open Questions

- [ ] Linux golden은 Windows 로컬에서 skip될 수 있으므로 PR CI 결과가 최종 증거다.
- [ ] 기존 Cursor 브랜치 삭제 조건은 새 PR current-head의 전체 CI 초록이다.

### Deferred Items

- 배포, 스토어 업로드, 프로덕션 변경, main 병합은 범위 밖이다.
- 약 90MB 책가도 원본/런타임 팩과 미승인 감사 문서는 `backup/main-local-wip-20260820`에만 보존했다.

## Context for Resuming Agent

### Important Context

원 감사 문서를 main 또는 이 브랜치에 복원하거나 `docs/README.md`에서 정본으로 연결하지 말 것. 보존본은 원격 `backup/main-local-wip-20260820`에 있다. 기존 Cursor 브랜치는 새 PR current-head CI가 완전히 초록이 되기 전에는 삭제하지 말고, PR도 별도 지시 없이 merge하지 않는다.

### Assumptions Made

- Wanted Sans와 기존 라이선스가 승인된 현행 선택이다.
- DE/EN만 UI 로케일이며 KO는 학습 콘텐츠다.
- compact/medium/expanded 체계는 유지해야 할 호환 계약이다.

### Potential Gotchas

- `MediaQuery.size.height`는 `SafeArea` 내부 가용 높이가 아니다.
- 360x800 기본 배율 골든은 불필요하게 바꾸지 않도록 보자기 폭 임계값을 내부 폭 280으로 제한했다.
- `SoriButton.maxLines == null`은 핵심 문구를 자르지 않는 의도적 선택이다.

## Environment State

### Tools/Services Used

- Flutter/Dart SDK, Git/GitHub CLI, PowerShell, Python handoff validator

### Active Processes

- 없음

### Environment Variables

- 별도 지속 환경 변수 없음

## Related Resources

- `docs/HANDOFF_UI_OVERHAUL_2_2026-08-14.md`
- `.claude/handoffs/2026-08-20-052546-session-rules-skills.md`
- 원 감사 문서 보존 브랜치: `origin/backup/main-local-wip-20260820`
- SHA-256 목록: `C:\Users\vjinn\.codex\visualizations\2026\08\20\01a01e9a-b0f5-7483-818d-c2c4f5f29f35\wip-sha256-manifest-20260820.tsv`

---

**Security Reminder**: 이 문서는 비밀값을 포함하지 않으며 최종 커밋 전에 validator를 다시 실행한다.
