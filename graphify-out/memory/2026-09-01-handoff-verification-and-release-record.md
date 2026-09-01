---
type: "project"
date: "2026-09-01T19:50:00+00:00"
name: "handoff-2026-08-27-verification-and-release-record"
contributor: "claude-remote-session"
description: "인수인계서(2026-08-27) 반영 상태와 Play 두 트랙 릴리스 기계장치의 구조적 사실"
source_nodes: ["HANDOFF-2026-08-27-waves.md", "2026-09-01-handoff-verification-matrix.md", "2026-08-28-w4-w6-completion-design.md"]
---

# 인수인계 2026-08-27 반영 상태 · Play 릴리스 구조

> 이 노드는 **지금 무엇이 참인가**만 담는다. 언제·왜·어떤 run에서 그렇게 됐는지는
> `git log`와 PR 본문(#247·#248·#249·#250·#251)에 있다 — AGENTS.md "graphify 북엔드" 규칙.

## 인수인계서 2026-08-27의 현재 상태

전 조항을 원자 주장 56건으로 분해해 1:1 판정한 결과 **미반영 0**이다. 근거 전문은
`docs/superpowers/specs/2026-09-01-handoff-verification-matrix.md`(H-01~H-56)가 정본이며,
인계서 본문은 이미 낡았으므로 그것을 현재 상태로 읽으면 안 된다(문서 상단 배너 참조).

- W4 T1-T18 · W3.5 이월 5건 · W6 비영상 전부 main 반영. W5 계약은 6건 중 5건 반영.
- 남은 2건은 코드 작업이 아니라 **Jin 게이트**다: `FeedPhysics.snap` 기본 전환(실기기 승인 전 금지),
  tiger_choose 매트 예산 그랜드파더(0.06→0.25 완화로 통과 중 — 수리된 것이 아니다).
- 검수의 함정 3종: 인계서 프로즈는 stale · W5 a/b/e는 간접 구현(sheet·정적 API·프레임 주입)이라
  심볼 카운트 검증이 거짓 음성을 낳음 · W4 T10/T18은 raw 키가 아니라 `Storage.*` 접근자 경유.

## Play 두 트랙은 서로 다른 빌드다

이 저장소에서 internal과 alpha(비공개)는 **같은 산출물이 아니다**. 한쪽을 다른 쪽으로
승격하면 안 된다.

- 내부 빌드(`ci.yml`)는 `--dart-define=BETA_UNLOCK_ALL=true`를 넣는다 —
  `lib/services/premium_service.dart`의 프리미엄 entitlement 게이팅을 통째로 여는 테스터 전용 오버라이드.
- 비공개 빌드(`play_closed.yml`)는 그 define이 없고, `test/tester_build_release_contract_test.dart`가
  `isNot(contains('BETA_UNLOCK_ALL'))`로 이를 강제한다.
- 그래서 "내부에 올라간 번들을 alpha로 승격"하는 방안은 계약 위반이다(테스터에게 프리미엄이 풀린다).
  `docs/store/closed-testing-checklist-v2.md` §3은 Internal 통과 후 **exact main SHA로 Closed 전용
  workflow를 실행**하라고 지시하고, `AGENTS.md`는 트랙 승격이 수동임을 명시한다.

## versionCode는 커밋 수이고, 트랙마다 다른 커밋이 필요하다

- 계산 주체는 워크플로가 아니라 `android/app/build.gradle.kts`의 `autoVersionCode`
  (= `git rev-list --count HEAD`, 실패 시 폴백 21). pubspec의 `+N`은 Flutter build-number로
  iOS CFBundleVersion에만 반영되고 Android에서는 덮어써진다.
- 따라서 같은 커밋으로 두 트랙을 올리면 두 번째 업로드가 Play에서 거부된다
  (`Version code N has already been used.`). 두 트랙은 서로 다른 커밋에서 자른다.
- `PLAY_INTERNAL_RELEASE_ENABLED=true`인 동안에는 main push마다 내부 업로드가 그 커밋의 번호를
  먼저 소비하므로, 비공개 후보를 자르기 전에 변수를 끈다. 재발 방지 규칙은 체크리스트 §2.2에 있다.

## 배포 경계

CI가 하는 일은 **트랙에 번들을 올리는 것까지**다. Play Console 처리·게시, 테스터 설치,
트랙 승격은 전부 수동이며 CI 증거로 대체되지 않는다. iOS(TestFlight/App Store)는 계약 테스트가
CI 자동화를 금지하므로 Mac/Xcode Cloud 수동 절차뿐이다 —
런북: `.superpowers/sdd/2026-09-01-handoff-verification-and-release/ios-manual-runbook.md`.
