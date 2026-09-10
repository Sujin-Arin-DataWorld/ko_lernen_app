# CLAUDE.md → AGENTS.md

이 프로젝트의 상시 지침·파일 맵·규칙·지속 메모리는 저장소 루트의 **`AGENTS.md`** 에 있다.

**세션 시작:** `AGENTS.md`(간결) + `graphify query "<질문>"`.
**세션 종료:** `Stop` 훅이 `graphify update .` 와 정리를 자동 실행한다 (2026-09-09).
변경사항을 수기 문서로 남기지 않는다 — 이유·이력은 `git log`/PR 본문, 구조는 graphify.
`docs/SESSION_LOG.md`와 `.claude/handoffs/`는 과거 검색용 — 자동 로드·신규 작성 금지.

## graphify

규칙 전문은 **`AGENTS.md` 의 "## graphify — 운영 규칙 바이블"** 에 있다. 여기에 복제하지 않는다
(두 곳에 두면 한 곳이 낡는다). 조회·커밋·정리 규칙, 세션 북엔드, 금지 목록이 모두 거기 있다.

가장 자주 틀리는 두 가지만 옮겨둔다:

- 코드베이스 질문은 `graphify query "<질문>"` 이 grep 보다 먼저다.
- `graph.json`·`cache/ast/`·날짜 스냅샷은 **ignore 대상이다. 커밋하지 않는다.**
