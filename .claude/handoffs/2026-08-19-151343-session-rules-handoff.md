# Handoff: SESSION_LOG 의무 폐지 · handoff 규칙

## Session Metadata
- Created: 2026-08-19 15:13
- Branch: `cursor/session-handoff-rules-4772` (이 규칙 패치)
- `origin/main`: `d7488bcd` (#95 #96 #97 흡수 완료)

## Current State Summary
Wanted Sans가 앱 글씨체다. PretendardStd/GowunBatang 삭제는 맞다(한글 0글리프).
Windows `git pull`이 GowunBatang 삭제에서 멈춘 것은 OneDrive 잠금이지 폰트 손실이 아니다. `n` → OneDrive pause → 폴더 삭제 → `git reset --hard origin/main`.

## Important Context
Jin 결정: 변경마다 SESSION_LOG 쓰지 말 것. 세션 끝나면 `.claude/handoffs/` 한 장.

## 이 브랜치에서 한 일
- `AGENTS.md`: SESSION_LOG 의무 삭제, 완료 `[x]` 전부 삭제, 미완료 게이트 8개만.
- `CLAUDE.md`, `docs/README.md`, `session-handoff` 스킬을 같은 규칙으로 맞춤.
- SESSION_LOG 파일은 지우지 않음(검색용).

## 다른 열린 작업
- `#100` / `cursor/fix-tablet-goldens-4772`: #96 태블릿 골든 6장 + `SoriTypeScale` 하니스. Linux에서 재생성함. CI 확인 후 main.
- main Analyze `32266371980`은 그 6장 때문에 빨강. pub outdated는 실패 아님.

## Immediate Next
1. 이 규칙 PR을 main에 넣기.
2. #100 CI 초록이면 골든도 main.
3. Windows는 OneDrive 멈추고 pull만. 폰트 다시 고르지 말 것.

## 읽지 말 것
`docs/SESSION_LOG.md` 전체, 한옥 감사 handoff 3장(한옥 작업 아니면).
