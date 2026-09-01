---
type: "project"
date: "2026-09-01T19:50:00+00:00"
name: "handoff-2026-08-27-verification-and-release-record"
contributor: "claude-remote-session"
description: "인수인계서(2026-08-27) 1:1 검수 종결·main 병합·릴리스 트랙 기록"
source_nodes: ["HANDOFF-2026-08-27-waves.md", "2026-09-01-handoff-verification-matrix.md", "2026-08-28-w4-w6-completion-design.md"]
---

# 인수인계 2026-08-27 검수 종결 및 릴리스 기록 (2026-09-01)

## 검수 결론

`docs/HANDOFF-2026-08-27-waves.md` 전 조항을 원자 주장 56건으로 분해해 origin/main 대비 1:1
판정했다 — **반영 50 · 의도적 보류 2 · 미반영 0 · 불일치 4**(전부 "인계서가 현재보다 낡음" 방향).
근거 전문: `docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md` (H-01~H-56).

- W4 18/18(PR #209) · W3.5 이월 5/5(PR #210) · W5 계약 5/6(PR #211/#217/#218) · W6 비영상(#219/#220/#222) 전부 main 반영.
- 의도적 보류 2: FeedPhysics.snap 기본 전환(Jin 실기기 게이트), tiger_choose 매트 예산 그랜드파더(0.06→0.25, 수리 아님).
- 불일치 4: 재작성 대기 97→84건(13건은 2faef696으로 기적용) / Play versionCode 실체는 커밋 수(2174/2186) /
  AGENTS #100 골든 게이트 stale(92ffd22e로 기수리→게이트 종결) / §8 "sdd는 gitignore" 전제 거짓(원장은 커밋으로 보존 가능·이번 세션 원장 커밋됨).
- closed §0 플립게이트(ae024af6) 모순은 해소로 판정: 실질은 08a77fd6→abf9e3ff→c917d777+01bd8849(08-15~19)로
  수정·구조 제거돼 CI 상시 강제 중, 문서만 지연 — 체크리스트에 후속 판정 추기됨.

## 병합 기록

- 검수 PR **#247** → main `01af91a0` (PR CI 1016/1017/1018 success, main 전체 스위트 run 1019 success).
- graphify 기록 PR **#248** (이 커밋 포함). 병합 중 Codex의 `c82a7bef`(TTS 즉시재생 복구)와 manifest 충돌 → main 판 기준 해소.
- Codex 리뷰 반영: 신규 문서를 추출 없이 manifest 스탬프하면 미래 update가 영구 건너뜀 → 스탬프 전면 철회,
  기록은 이 memory 노드로 이관(다음 `graphify update .`가 14개 변경 파일과 이 노드를 정상 추출).

## 릴리스 트랙

- Jin 룰링(2026-09-01): 릴리스는 **Codex 오디오 수정(무음 버그 등) main 랜딩 후** 자른다 → c82a7bef 랜딩 확인 후 착수.
- 릴리스 PR **#249**(pubspec `2.0.8+29`→`+30` 단일 커밋) → squash 병합 `1175c4f9`.
  main push CI **run 1029 success**(전체 스위트) → **내부테스트 업로드 성공**(vC **2215**,
  `Build signed internal-testing bundle`·`Upload to Google Play Internal Testing` 전 스텝 success).
- **비공개(alpha) 업로드는 같은 SHA에서 실패**: `Version code 2215 has already been used.`
  같은 커밋으로 두 트랙을 올리면 versionCode(=commit count)가 충돌한다 — 내부 업로드가 2215를 먼저 소비했다.
  빌드·서명·정확-SHA 게이트는 전부 통과, 업로드 API 호출만 거부(run 33563121115).
  → 재발 방지 규칙을 `docs/store/closed-testing-checklist-v2.md` §2.2에 명문화.
  → 해소 경로: `PLAY_INTERNAL_RELEASE_ENABLED`를 끈 뒤 새 커밋으로 main tip을 올리고(commit count 2216+)
  그 SHA로 play_closed 재디스패치.
- 대조 사실: 비공개 트랙이 이미 보유한 빌드(vC2208, Codex가 c82a7bef에서 업로드)와 `1175c4f9` 사이의 차분은
  ci.yml·문서·웹사이트 lockfile·pubspec 버전 줄뿐 — **앱 바이너리에 영향을 주는 변경 0**.
- iOS는 CI 자동화 금지 계약 + 컨테이너 한계로 수동 런북 인계(`.superpowers/sdd/2026-09-01-handoff-verification-and-release/ios-manual-runbook.md`).
