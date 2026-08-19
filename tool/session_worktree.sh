#!/usr/bin/env bash
# 세션마다 자기 워킹트리를 준다.
#
# **왜.** Jin 은 앱을 빨리 끝내려고 AI 세션을 여러 개 동시에 돌린다. 그런데
# 세션들이 전부 메인 체크아웃(~/Developer/ko_lernen_app) 안에서 작업하면 한
# 폴더를 여럿이 쓴다. 2026-08-19 에 이걸로 세 번 사고가 났다:
#   ① 한 세션이 쓴 파일을 다른 세션이 덮어써서 작업이 조용히 사라졌다
#   ② 한 세션이 브랜치를 갈아타 다른 세션의 HEAD 가 발밑에서 바뀌었다
#   ③ `flutter test` 실행 도중 파일이 갈려 실패 3건이 유령으로 떴다
# 커밋 전 작업은 워킹트리에만 있으므로, 워킹트리를 공유하면 서로의 미커밋
# 변경을 지운다. git 은 이걸 막아 주지 않는다.
#
# **규칙.** 메인 체크아웃은 Jin 것이다. 세션은 여기서 자기 워킹트리를 받아
# 그 안에서만 일한다.
#
# 사용:
#   tool/session_worktree.sh <슬러그>            # origin/main 기준 새 브랜치
#   tool/session_worktree.sh <슬러그> <베이스>   # 다른 베이스에서
#
# 예:
#   tool/session_worktree.sh audio-fix
#   → 워킹트리 ../ko_lernen_worktrees/audio-fix
#     브랜치  session/audio-fix-2026-08-19
#
# 이미 있으면 만들지 않고 그 경로를 알려 준다(재실행 안전).

set -euo pipefail

slug="${1:-}"
base="${2:-origin/main}"

if [[ -z "$slug" ]]; then
  echo "사용법: tool/session_worktree.sh <슬러그> [베이스ref]" >&2
  echo "  예:   tool/session_worktree.sh audio-fix" >&2
  exit 2
fi

if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
  echo "슬러그는 소문자·숫자·. _ - 만 쓴다: $slug" >&2
  exit 2
fi

# 링크된 워크트리에서 불러도 항상 저장소의 메인 체크아웃을 기준으로 잡는다.
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
main_root="$(dirname "$common_dir")"
parent="$(dirname "$main_root")"
repo_name="$(basename "$main_root")"

trees_root="$parent/${repo_name}_worktrees"
target="$trees_root/$slug"

if [[ -d "$target" ]]; then
  echo "이미 있다 — 그대로 쓴다:"
  echo "  cd $target"
  exit 0
fi

# 브랜치 이름에 날짜를 붙여 세션끼리 겹치지 않게 한다.
branch="session/$slug-$(date +%Y-%m-%d)"
if git show-ref --verify --quiet "refs/heads/$branch"; then
  suffix=2
  while git show-ref --verify --quiet "refs/heads/$branch-$suffix"; do
    suffix=$((suffix + 1))
  done
  branch="$branch-$suffix"
fi

# 베이스를 최신으로. 네트워크가 없으면 로컬 ref 로 계속 간다.
if [[ "$base" == origin/* ]]; then
  git fetch --quiet origin "${base#origin/}" 2>/dev/null || {
    echo "⚠️  origin fetch 실패 — 로컬 $base 로 진행한다" >&2
  }
fi

mkdir -p "$trees_root"
git worktree add -b "$branch" "$target" "$base"

cat <<EOF

✅ 워킹트리 준비 완료
   경로   $target
   브랜치 $branch
   베이스 $base

이제 여기서만 작업한다:
   cd $target

끝나면 정리:
   git worktree remove $target
EOF
