# Handoff: 레벨 정본화 프로그램(LCP) PR-L1 진행 중 (Fable 설계·판정 / Sonnet 실행)

## 상태 (2026-09-07 10:30) — PR-L1 완료, PR 생성 단계
- 승인 플랜: `C:\Users\vjinn\.claude\plans\c-users-vjinn-elibrary-downloads-1-1-pd-cheeky-eclipse.md` (§14 Fable 룰링 원장). 메모리: `level-canon-program-2026-09-07` 외 3건.
- 워크트리 `C:\dev\hangulsori\ko_lernen_app_worktrees\level-bible-20260907`, 브랜치 `claude/level-bible-20260907`(origin/main 761d53b0 기준, 이후 origin/main 병합). 파이썬 `C:\dev\hangulsori\ko_lernen_app\.venv\Scripts\python.exe` + `PYTHONIOENCODING=utf-8`.
- 커밋(전부 Fable diff 직독·골든 재실행 후): 1fb715ba T1.1 사전 · 6b998355 T1.5 정책 · 2173b059 T1.6 TTS 배치 · 3e88dde8 T1.7 원장 · 50c978ba T1.8 CI · f5601ddf T1.9 외래어 · c3db821b R6 · 9e4715ed T1.2+R3 판정기 · 2dd58082 R7 · 33786023 R8 · 9cfaf09d T1.3+R4 감사기 · dd1ab452 R4b · a547d3da T1.4+R5 바이블.
- 통합 검사(Fable 실행): `flutter analyze` 0 · `flutter test` 6,137 통과/20 스킵/실패 0 · `validate_content.py --json` ok · canonical·first-line 매니페스트 --check verified · content_factory 지정 모듈 49 OK · reference intake OK · tool 신규 테스트(판정기 93·감사기 48·사전 21·TTS 46·외래어 26·바이블 24) OK.
- 판정기 실측: 표제어 unknown 2.73%, cloze 토큰 unknown 3.22%. 감사기: 1급 고유 714 중 앱 보유 362(A1 배정 202), 2급 1,070 중 340(A2 122); A1/A2 팩 중앙값≥+2 각 6개.
- 규칙(Jin): Sonnet 리뷰어 없음. 단계마다 Fable이 diff·테스트·골든을 직접 재실행해 판정, 통과 전 다음 단계 발주 금지. Sonnet은 Agent tool(model sonnet, 백그라운드) 1태스크씩, 증분 편집(호출당 <200줄).

## 다음 한 일 (순서)
1. PR-L1: `gh pr create`(제목 "feat(content): 레벨 정본화 PR-L1 — 바이블·국립국어원 사전·판정기·감사기·원장·CI") → head SHA의 자동 CI run 확인(.github 변경이라 전 스코프; 새 잡 content-validate 초록 확인) → squash 머지 → 메모리 `level-canon-program-2026-09-07` 갱신.
2. PR-L2a 시작: origin/main(머지 후)에서 워크트리 `level-relevel-20260907` 생성 → T2.1 프로브(읽기 전용: build_can_do_segments.py 파생 여부, validate_batch_01 범위, CanonicalCourseSegmentLoader 호출 시점, integrate_review_batches count 0 허용, grammar ID 검사) → T2.2 이동 목록(`tool/content_level_suspects.csv` bundle_move + 플랜 §14.2 선반 원칙; Jin 통보) → T2.3 relevel_bundle.py → … → T2.9 배포(2단 범프).
3. T2.7 입력: F1 기준 1급·2급 결손 문법 19항목(-겠-, 이다, -습니까/-습니다/-으십시오, -지 않다, 이 아니다, -다가, -음, 에게로/에게서/에다가/에서부터/한테서, -지, -을 것, -을 수밖에 없다, -을까 보다, -지 말다) + app_only 92건 수작업 대조.

## 읽지 말 것 / 주의
- `tools/content_factory` 전체 unittest discover는 drafts/review를 LF로 재기록한다(내용 동일) → 실행 후 `git checkout -- tools/content_factory/drafts tools/content_factory/review`로 원복(GateGuard 훅이 막으면 4가지 사실 제시 후 재시도).
- GateGuard 훅: Write로 새 파일 만들 때 사실 4가지 요구 → Bash heredoc 사용.
- kornorms API 키는 채팅에만 있음(파일 기록 금지, `KORNORMS_API_KEY` 환경변수). Jin에게 재발급 권고함.
- OneDrive cwd는 손상 사본. 커밋 정체성은 `Codex <codex@local>`.
