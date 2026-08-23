# CLAUDE.md → AGENTS.md

이 프로젝트의 상시 지침·파일 맵·규칙·지속 메모리는 저장소 루트의 **`AGENTS.md`** 에 있다.

**세션 시작:** `AGENTS.md`(간결) + `.claude/handoffs/` 최신 파일 하나.
`docs/SESSION_LOG.md`는 자동으로 읽거나 매 변경에 쓰지 않는다. 세션이 끝나면
`.claude/skills/session-handoff`로 짧은 인수인계를 남긴다.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
