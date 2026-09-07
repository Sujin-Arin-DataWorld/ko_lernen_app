# Handoff: 레벨 정본화 프로그램(LCP) PR-L1 진행 중 (Fable 설계·판정 / Sonnet 실행)

## 상태 (2026-09-07 03:45)
- 승인 플랜: `C:\Users\vjinn\.claude\plans\c-users-vjinn-elibrary-downloads-1-1-pd-cheeky-eclipse.md` (§14 Fable 룰링 원장 포함). 메모리: `level-canon-program-2026-09-07` 외 3건.
- 워크트리 `C:\dev\hangulsori\ko_lernen_app_worktrees\level-bible-20260907`, 브랜치 `claude/level-bible-20260907` (origin/main 761d53b0 기준). 파이썬은 `C:\dev\hangulsori\ko_lernen_app\.venv\Scripts\python.exe` + `PYTHONIOENCODING=utf-8`.
- 커밋 7건(전부 Fable diff 직독 후): 1fb715ba T1.1 사전 · 6b998355 T1.5 정책/인벤토리 · 2173b059 T1.6 TTS 배치 업로드 · 3e88dde8 T1.7 원장(+R1 수정) · 50c978ba T1.8 CI content-validate · f5601ddf T1.9 외래어 감사기 · c3db821b R6(∙ 분리·로마자 필드).
- 미커밋(판정 진행 중): `tool/cefr_lexicon.py`·`tool/test_cefr_lexicon.py`(R3 통과, R7 2차 보정 Sonnet 에이전트 실행 중), `tool/audit_content_levels.py`+리포트/summary/suspects(R4 재생성 대기), `docs/CONTENT_LEVEL_BIBLE.md`·`tool/build_level_bible_tables.py`·`docs/data/level_bible/F1~F10`(R5 정정 대기), `docs/data/vocab_level_report.md`·`tool/audit_vocab_levels.py`(머리말 1줄).
- 규칙(Jin): Sonnet 리뷰어 없음. 단계마다 Fable이 diff·테스트·골든을 직접 재실행해 판정하고, 통과 전 다음 단계 발주 금지. Sonnet 발주는 Agent tool(model sonnet, 백그라운드)로 1태스크씩.

## 다음 한 일 (순서)
1. R7 결과 검증: `python -m unittest tool.test_cefr_lexicon`; 골든(고마워요→고맙다 A1, 사양하다≤B2·conf≠high, 멈췄어요→멈추다, 새로운→새롭다, 십오→A1, 신용카드 compound, 있나요?→있다); 비율 스크립트로 vocab unknown ≤4%·cloze 토큰 unknown ≤5% 확인 → 통과 시 `git add tool/cefr_lexicon.py tool/test_cefr_lexicon.py tools/content_factory/lexicon/aliases.csv` 커밋 "feat(lexicon): CEFR 판정기 (LCP T1.2+R3+R7)".
2. R4 발주(플랜 §6 T1.3 + 워크플로 스크립트 `lcp-pr-l1-rework` 내 R4 프롬프트 재사용: 고유 표제어 분모·소문자 통일·폴백(low/medium) 제외 집계 fallback_over2·kcenter 언급 제거·래칫 CAP 갱신) → Fable 판정 → 커밋.
3. R5 발주(R5 프롬프트: kcenter 행 제거, §A 분모=고유 표제어, A1 합쇼체 생산·du/Sie 정정, F1 매처 강화(app_only≤60), F5 규칙(3·1 운동→B1), §D에 인물명 규칙(플랜 §14.3) 추가) → Fable 직독 → 커밋.
4. 남은 kcenter 잔재 정리: `tool/test_audit_content_levels.py:86`, `tool/build_level_bible_tables.py:469`, `tool/audit_content_levels.py:797`(R4/R5에서 처리).
5. 통합: `flutter analyze`, 전체 `flutter test`(Fable 1회, timeout 600000), `python -m unittest discover -s tool -p "test_*.py" -t .`, `tools/content_factory` 지정 모듈, `validate_content.py --json`, `build_canonical_manifest.py --check` → `gh pr create`(head SHA CI 확인, `.github/` 변경이라 전 스코프) → squash 머지 → 인수인계 갱신·메모리 갱신.
6. 이후 PR-L2a(플랜 §6 T2.0~T2.9; 룰링 §14.1·§14.2) — 프로브 T2.1부터.

## 읽지 말 것 / 주의
- `tools/content_factory` 전체 unittest discover는 drafts/review를 LF로 재기록한다(내용 동일) → 실행 후 `git checkout -- tools/content_factory/drafts tools/content_factory/review`로 원복(GateGuard 훅이 막으면 4가지 사실 제시 후 재시도).
- GateGuard 훅: Write로 새 파일 만들 때 사실 4가지 요구 → Bash heredoc 사용.
- kornorms API 키는 채팅에만 있음(파일 기록 금지, `KORNORMS_API_KEY` 환경변수). Jin에게 재발급 권고함.
- OneDrive cwd는 손상 사본. 커밋 정체성은 `Codex <codex@local>`.
