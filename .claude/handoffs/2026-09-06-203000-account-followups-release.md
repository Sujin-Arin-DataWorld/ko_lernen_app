# 2026-09-06 계정 후속 3건 + 릴리스 인수인계

> Jin 지시: "이 세션 작업한 것들 전부 메인에 있는지 다시 확인, 후속작업 전부 Fable 5.1이 작업해서 메인에 넣고, 최종 앱스토어·안드로이드 배포." 이번엔 Fable이 코드를 직접 썼다(Jin 명시).
> 이전 인수인계 `2026-09-06-013000-account-link-delete-fix.md`(원인 표·T1~T8)를 잇는다. 설계 SSoT: `docs/superpowers/plans/2026-09-05-account-link-delete-fix.md` §2 T9·§3.

## 지금 상태 (한 줄)
계정 수정(#275)과 W10 PR-C(#274)는 main에 있고, 후속 3건은 `claude/account-followups-20260906` 브랜치로 PR → squash 병합 → gye 함수 11종 재배포 → `play_closed` dispatch 순서로 진행했다(실행 결과·run ID는 세션 최종 보고). iOS는 윈도우에서 빌드 불가 — 아래 맥 절차.

## main 반영 확인 (2026-09-06)
| 항목 | 상태 |
|---|---|
| PR #275 계정 근본 수정 | main `c3f5a71f` (squash) |
| PR #274 W10 PR-C Hören 카드 그리드 | main `3ce134be` (squash, 체크 전부 성공, 워크트리 깨끗·원격 동일 확인 후 병합) |
| 다른 세션의 릴리스 | `ad0e01de` versionCode 34 내부, `ce422fe1` versionCode 35 비공개(Play 업로드 성공 run 34054850596) |
| 서버 | rules + gye 함수 11종 2026-09-06 12:42 UTC 배포본 ACTIVE(REST 실측) |
| Firebase Apple 제공자 | **아직 없음**(REST 실측 `google.com`만) — Jin 콘솔 작업 |
| `PLAY_INTERNAL_RELEASE_ENABLED` | 다른 세션이 true로 방치 → **false 원복**(main push마다 내부 업로드가 versionCode를 소모하는 것 방지) |
| 열린 PR | #272(W10 PR-S 시나리오 52편, 콘텐츠 — Jin 문장 검수 게이트), #246, #232 |

## 후속 3건 (T9, 커밋 1개)
1. **거부·유실된 삭제 요청 뒤 세션 재획득** — `lib/services/auth_service.dart` `AccountDeletionCoordinator`: 서버 수락 전 실패 → `_reacquireSourceSessionAfterRejectedRequest`(blocked → `acquire(sourceUid)` + `rebindPush`). 수락 후 실패는 blocked 유지. 같은 세션 재시도가 이제 된다.
2. **워커 `appleRevocationPending` 스킵** — `functions/gye/account_operations.js` `nextPhases(op, {appleRevocationComplete})` + `transitionOperation` + runtime `checkpointDeletionWork`/워커 분기. 조기 해지 뒤 1틱(≤5분) 대기 제거. **함수 재배포 필요**(같은 11종).
3. **레거시 replacement 저널 키 소비처 정리** — `MediaCleanupGate` 리더·`Storage` 리셋 펜스가 전환 저널 키 2종(`AccountSwitchJournal.storageKey`, `AccountTransitionJournal.switchReconciliationStorageKey`)을 본다. 전환 병합 중 미디어 정리·로컬 리셋 차단이 실제로 동작. 레거시 키는 리셋 시 보존하지 않음.
- pubspec `2.0.8+36`(표시용; 실제 versionCode는 `git rev-list --count`).

## 검증
- `flutter analyze` 0. gye `npm test` 443 통과 / 0 todo(T3 todo가 실테스트로 전환).
- 대상 11파일 `flutter test` 190 통과. 전체 스위트 1회 실행 결과는 세션 최종 보고(로그 스크래치패드 `full-followups.log`).
- Fable이 diff 전문을 직접 썼고 직독 재검토.

## 릴리스 절차 (Android, 윈도우에서 gh로)
1. PR 병합 → main push CI(`ci.yml`) success 대기(iOS simulator 잡이 40분+ 걸릴 수 있음).
2. `gh workflow run play_closed.yml -f expected_sha=<병합 sha 40자>` → "Signed AAB to Play Closed Testing" success 확인.
3. **프로덕션 승격은 Play Console에서 Jin이**(GH 워크플로 없음).

## iOS (맥 전용 — Jin)
`docs/store/APPSTORE_UPLOAD_KO.md` 순서. 요약: `open ios/Runner.xcworkspace`로 Team 확인 → `FREE_LAUNCH=1 bash scripts/build_ios_ipa.sh` → Transporter 업로드 → TestFlight → 심사 제출. Xcode Cloud가 main 푸시 트리거로 설정돼 있으면 병합만으로 빌드가 시작된다(설정은 App Store Connect UI에만 있어 여기서 확인 불가).
**심사 주의**: Apple 제공자가 Firebase에 없으면 앱의 Apple 버튼이 "미설정" 안내를 띄운다. Google 로그인을 제공하는 앱은 Sign in with Apple이 실제로 동작해야 심사(가이드라인 4.8)를 통과하므로, **App Store 제출 전 Apple 제공자 설정을 끝내는 것을 권장**한다.

## Jin이 해야 할 것
1. Apple Developer + Firebase 콘솔 Apple 제공자(`docs/store/apple-sign-in-setup.md` §1~§4) → `.env.ko-lernen-app`·GitHub variables 채우고 `completeAppleRevocation`·`appleOAuthCallback` 재배포(§5).
2. 실기기 검증(이전 인수인계 체크리스트 + 이번 추가: 비행기 모드에서 삭제 시도 → 실패 → 온라인 복귀 후 **재시작 없이** 재시도 성공).
3. 결정 2건: (a) 익명 자동 삭제는 **켜지 않기를 권장**(활동 중 익명 사용자 데이터 손실), (b) 구 replacement 함수 5종 배포 삭제 여부.
4. #272(시나리오 52편) 병합 여부 — 병합 전까지 Hören 카드 그리드에 빈 칸("noch nicht bestückt")이 남는다.

## 읽지 말 것
- `docs/HANDOFF_account-link-reconciliation-bug.md`, `docs/ACCOUNT_SYSTEM_AUDIT_2026-06-03.md` — 대체됨.
