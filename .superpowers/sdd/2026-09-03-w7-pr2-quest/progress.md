# SDD ledger — plan: docs/superpowers/plans/2026-09-03-w7-pr2-quest-engines.md
Worktree: C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr2-quest-20260903 (branch claude/w7-pr2-quest-20260903)
BASE: origin/main d120af87
T2.1 dispatched 2026-09-03
T2.1 Fix round 1 (Fable FIX-REQUIRED on be0a7062): entry autoplay removed from luecken/particlePop, post-reveal readback added to particlePop only (canonical-corpus gated, STEP 0) — 2026-09-04
T2.1 APPROVED by Fable direct read (be0a7062 + fix 48dc3247): dialog autoplay, quiz entry silent, particlePop post-reveal readback, luecken/uebersetzen readback blocked on canonical corpus (W9-C).
T2.2 dispatched 2026-09-04 — 정답 효과(burst+sound+haptic) 5엔진 통일 + batchim_drop TtsService→SoriSpeech 이관 (지시서 4.7). hoerverstehen/luecken/uebersetzen/particle_pop/diktat correct 분기에 widget.correctFeedback.play(context) 배선, 기존 HapticFeedback.*Impact() 제거; batchim_drop_quest.dart:161/474 TtsService→SoriSpeech; quest_engines_uiux_test.dart의 burst/sound/haptic 단언을 2엔진→7엔진으로 확장(RED→GREEN 확인) — analyze 0, git grep TtsService -- lib/screens/quest_engines/ 빈 결과.
