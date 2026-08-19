#!/usr/bin/env bash
# SessionStart 훅. 세션이 Jin 의 메인 체크아웃 안에서 시작하면 크게 막아선다.
#
# 여러 AI 세션이 한 워킹트리를 공유하면 서로의 미커밋 변경을 덮어쓰고,
# 브랜치를 갈아타 남의 HEAD 를 바꾸고, 남이 돌리는 테스트를 오염시킨다
# (2026-08-19 실사고 3건 — tool/session_worktree.sh 주석 참조).
#
# 훅은 세션의 cwd 를 바꿀 수 없다. 그래서 막는 대신 **크게 알리고** 모델
# 컨텍스트에도 지시를 넣는다.
set -euo pipefail
cat >/dev/null || true   # 훅 입력 JSON 은 쓰지 않는다

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

git_dir="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || echo x)"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo y)"

# 링크된 워크트리면 둘이 다르다 → 이미 격리돼 있으니 조용히 통과.
[ "$git_dir" = "$common_dir" ] || exit 0

root="$(dirname "$common_dir")"
msg="⛔ 여기는 Jin 의 메인 체크아웃($root)이다. 세션은 여기서 파일을 고치지 않는다.
   먼저 자기 워킹트리를 받아 그리로 옮겨갈 것:
       bash tool/session_worktree.sh <슬러그>
       cd <출력된 경로>
   이유: 세션 여러 개가 한 폴더를 쓰면 서로의 미커밋 변경을 덮어쓰고, 브랜치를
   갈아타 남의 HEAD 를 바꾸고, 남이 돌리는 테스트를 오염시킨다 (2026-08-19 3건)."

python3 - "$msg" <<'PY'
import json, sys
msg = sys.argv[1]
print(json.dumps({
    "systemMessage": msg,
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": msg,
    },
}, ensure_ascii=False))
PY
