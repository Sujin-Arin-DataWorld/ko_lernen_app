# 계정 연동·삭제 근본 수정 설계 (2026-09-05)

브랜치 `claude/account-fix-20260905` · 워크트리 `C:/dev/hangulsori/ko_lernen_app_worktrees/account-fix-20260905` · 기준 `origin/main ef0f0cec`

## 0. 조사로 확정한 근본 원인 (증거 포함)

| # | 원인 | 증거 | 영향 |
|---|---|---|---|
| R1 | **Firebase Auth에 Apple 제공자 미설정** | `identitytoolkit defaultSupportedIdpConfigs` = `google.com`만 존재 | Apple 연동이 iOS·Android 모두에서 `operation-not-allowed`로 즉사 |
| R2 | Android Play 빌드에 `APPLE_SERVICES_ID`/`APPLE_REDIRECT_URI` dart-define 없음 + `appleOAuthCallback` 함수 미배포 | `.github/workflows/play_closed.yml:143-146`, `ci.yml:539-543`; `firebase functions:list`에 없음 | Android에서 Apple 버튼 → `AppleOAuthConfigurationMissing` 즉시 실패 |
| R3 | **삭제 설계 결함**: 서버 워커(5분 주기)는 한 틱에 한 단계만 진행해 최소 5틱(≥20분)인데 클라이언트는 60초(30×2s)만 기다림 (`auth_service.dart:921-1004`, `functions/gye/index.js:405-430`, runtime 1796-2084) | 로그: 08-13·08-17 삭제 요청 각 1회 → 상태조회 30회 → 포기; ack 호출 0건; Firestore에는 서버측 `completed` | 첫 시도는 **구조적으로 항상 실패**로 표시, 로컬 저널이 남아 모든 계정 액션 잠금 |
| R4 | **연동 충돌(이미 쓰인 Google 계정) 경로 설계 결함**: 격리 앱 검증 → 서버 6단계 → 동일 워커 5틱 → 재검증 → 활성화. Google 선택창 3회, 각 콜러블 5분 auth 신선도, `blocked` 종단 없음 | runtime 2317-2328(300s), 2414-2425; 로그: 08-11 이후 replacement 콜러블 호출 0건 (실패가 서버 도달 전에 끝남) | "Kontowechsel fortsetzen" 무한 루프, 저널이 삭제까지 잠금 |
| R5 | **서버 함수 배포본이 08-12 것**: 08-16 `8f78aa9d`(link/delete 복구), 08-17 `2c5e5bb0`, 09-03 `e35ea785`, `deleteCloudBackup`·`appleOAuthCallback`·rules 83줄 미배포 | Cloud Functions v2 `updateTime` 2026-08-12T23:18 | 클라(09-05)와 서버 계약 불일치 위험, "Cloud-Daten löschen"은 not-found |
| R6 | 계정 실패 진단이 `debugPrint`뿐 (`account_failure_diagnostics.dart:87`) | Crashlytics 비치명 0건 | 운영 실패 원인 관측 불가 |
| R7 | `deleteCloudBackup` 미배포 상태에서 "Cloud-Daten löschen"을 누르면 저널이 남아 연동·삭제 전부 `blocked` (`account_ui_operations.dart:_readPendingState`) | 코드 경로 | 정리 잡 하나가 계정 UI 전체를 잠금 |

확정된 정상 사실: Google 제공자 활성, Android SHA-1 3종(디버그·업로드·Play 서명 추정)+SHA-256 1종 등록, App Check Play Integrity 등록·UNENFORCED, 계정 콜러블 `enforceAppCheck:false`, 삭제 워커 스케줄러 정상(5분마다 200 OK), 필요한 Firestore 인덱스 READY.

## 1. 설계 원칙

1. **사용자에게 보이는 결과는 동기적으로 끝낸다.** 삭제 = Firebase Auth 사용자 즉시 소멸 + 기기 초기화. 연동 = 즉시 그 계정으로 로그인 + 이 기기 진행 병합. 서버 데이터 정리는 백그라운드(워커)이며 UI에 절대 노출·잠금하지 않는다.
2. **어떤 로컬 저널도 계정 UI를 영구 잠그지 못한다.** 저널은 크래시 복구용이며, 서버가 종단/부재를 말하거나 소유 UID가 바뀌면 폐기한다.
3. 서버 코드는 유지·재사용한다(삭제 워커, Apple 해지). 서버 변경은 Apple 조기 해지 허용 1건뿐.
4. 표준 Firebase 패턴: 충돌 시 `signInWithCredential(동일 credential)`로 기존 계정 전환. 격리 Firebase 앱·서버 replacement 오퍼레이션·활성화 저널은 제거한다.

## 2. 태스크 (§8 형식)

### T1 진단 → Crashlytics 비치명 기록
- 파일: `lib/services/account/account_failure_diagnostics.dart` (107줄), 테스트 `test/services/account/account_failure_diagnostics_test.dart`
- 인터페이스(구현본 8f5d8849 기준): `@immutable class AccountFailureRecord implements Exception {stage, code, detail?}`; `typedef AccountDiagnosticsSink = void Function(String line, AccountFailureRecord record)`; `AccountFailureDiagnostics.sink`(주입 가능) + `resetSinkForTesting()`; 기본 sink = `debugPrint(line)` → `kIsWeb || Firebase.apps.isEmpty`면 종료 → try/catch 안에서 `FirebaseCrashlytics.instance.log(line)` + `recordError(record, null, reason: stage, fatal: false)`. **원문 예외 텍스트는 절대 전달하지 않는다**(`code`는 기존 `describe()` 결과만).
- 먼저 실패시킬 테스트: sink 주입 시 `log('link.failed', FirebaseAuthException(code:'x'))`가 redacted line 한 줄 + `AccountFailureRecord('link.failed','firebase:x')`를 수신; 실 예외 메시지 문자열은 sink 인자 어디에도 없음.
- 완료: analyze 0, 해당 테스트 green, 기존 diagnostics 테스트 green.
- ⚠ 함정: `firebase_crashlytics` 미초기화 시 `FirebaseCrashlytics.instance`가 던짐 → 반드시 try/catch. 테스트에서 Firebase 초기화 불가 → 기본 sink는 테스트에서 호출되지 않도록 주입 경로 사용.

### T2 Apple 설정 배선 + 운영 런북
- 파일: `.github/workflows/play_closed.yml:143-146`, `.github/workflows/ci.yml:539-543`, `.github/scripts/test_play_closed_workflow.py`, 신규 `docs/store/apple-sign-in-setup.md`
- 변경: 두 appbundle 빌드에 `--dart-define=APPLE_SERVICES_ID=${{ vars.APPLE_SERVICES_ID }}`·`--dart-define=APPLE_REDIRECT_URI=${{ vars.APPLE_REDIRECT_URI }}` 추가(미설정이면 빈 값 → 현행과 동일하게 "미설정" 안내). 런북에 Apple Developer(App ID capability, Services ID+Return URLs, Sign in with Apple Key), Firebase 콘솔 Apple 제공자 활성(Services ID·Team ID·Key ID·.p8), `functions/gye/.env.ko-lernen-app`(`APPLE_SERVICES_ID`, `APPLE_REDIRECT_URI=https://europe-west3-ko-lernen-app.cloudfunctions.net/appleOAuthCallback`), `APPLE_REVOKE_*` 시크릿 실값 교체, 배포 명령, 검증 절차.
- 먼저 실패시킬 테스트: `test_play_closed_workflow.py`에 두 define 존재 단언 추가.
- ⚠ 함정: Services ID Return URL은 Firebase 핸들러 `https://ko-lernen-app.firebaseapp.com/__/auth/handler`와 콜백 함수 URL **둘 다** 등록. 네이티브 iOS는 Services ID 불필요(제공자 활성만).

### T3 서버: Apple 해지를 `deletionRequested`/`userTreeDeleting` 단계에서도 접수
- 파일: `functions/gye/account_operations_runtime.js:2503-2632` (`completeAppleRevocation`), 워커 1995-2032, 테스트 `account_operations_runtime.test.js`
- 현행: phase가 `appleRevocationPending`이고 version 일치할 때만 해지 → Auth 삭제 → `authDeleted`. 워커는 트리 완료 후 `appleRevocationRequired`면 `appleRevocationPending`으로 이동(1995-1997), 그 단계에서 `progress.appleRevocationComplete`가 true면 Auth 삭제 후 `authDeleted`(2017-2032).
- 변경: phase ∈ {`deletionRequested`,`userTreeDeleting`}이고 version 일치면 **해지만 수행하고** `checkpoint({progress:{appleRevocationComplete:true, statusCode: revocationUnavailable ? 'apple-revocation-unavailable' : null}})` 후 `operationResult` 반환(phase 전이 없음). 워커의 트리 완료 분기(1995-1997)는 `appleRevocationRequired && !claim.progress.appleRevocationComplete`일 때만 `appleRevocationPending`으로 가고, 이미 complete면 바로 Auth 삭제 → `authDeleted`. 기존 `appleRevocationPending` 경로는 그대로.
- 먼저 실패시킬 테스트: (a) `deletionRequested` v0에서 completeAppleRevocation → 200, phase 그대로, `appleRevocationComplete:true`; (b) 이후 워커 틱이 트리 완료 시 `appleRevocationPending`을 건너뛰고 `authDeleted`; (c) 실패(네트워크)면 `apple-revocation-pending` + `statusCode:'apple-revocation-retryable'`, phase 그대로.
- 완료: `npm test` 전부 green (functions/gye, node 24 로컬 OK).
- ⚠ 함정: `claimDeletionWork({allowAppleRevocationInput:true})`가 phase를 검사할 수 있음 — 확인 후 필요하면 허용 phase 확장. 리스 해제 경로 유지.
- **구현 결과(68d783cb)**: 조기 접수(`deletionRequested`/`userTreeDeleting`)·진행만 기록·리스 즉시 만료(`checkpointDeletionWork`가 `leaseUntilMillis=now`)·재시도/설정불가 분기 모두 적용, gye 스위트 442 통과/1 todo. 워커의 `appleRevocationPending` 건너뛰기는 `account_operations.js nextPhases()`가 `deletionProgress`를 보지 못해 `userTreeDeleting→authDeleted` 직행을 거부하므로 **미적용** — 기존 분기가 다음 틱에 Apple 호출 없이 `authDeleted`로 넘어가므로 지연 1틱(≤5분)뿐, 클라이언트는 기다리지 않음. 상태머신 변경은 후속 과제(test.todo로 표시).

### T4 연동 충돌 → 클라이언트 계정 전환 (replacement 제거)
- 새 파일: `lib/services/account/account_switch_coordinator.dart` (+ 테스트)
- 인터페이스:
  ```dart
  enum AccountSwitchStatus { completed, mergeDeferred, failed }
  class AccountSwitchResult { final AccountSwitchStatus status; final String? targetUid; }
  class AccountSwitchCoordinator {
    AccountSwitchCoordinator({required CloudWriteSessionController sessions, required AccountSwitchIdentity identity,
      required AccountSwitchJournalStore journalStore, required AccountSwitchReconciler reconcile,
      required Future<void> Function(String uid) activateBackfill});
    Future<AccountSwitchResult> switchToExisting({required AccountLinkProvider provider, required AuthCredential credential,
      required String sourceUid, required Map<String, PackCatalogEntry> catalog});
    Future<AccountSwitchResult> resume({required String liveUid, required Map<String, PackCatalogEntry> catalog});
  }
  abstract interface class AccountSwitchIdentity { String? get currentUid; bool get currentIsAnonymous;
    Future<String> signInWithCredential(AuthCredential c); }
  ```
- 흐름 `switchToExisting`: (1) 전제: `currentUid==sourceUid && anonymous`, 세션 ready·uid 일치; (2) `LocalAccountReconciliationStore.load()`로 로컬 스냅샷 유효성 선검사(FormatException → `failed`, 신원 변경 없음); (3) `PushOwnershipTransitionCoordinator.run(oldUid: sourceUid, transition: signInWithCredential)` — `push_service.dart:571-` 계약대로 세션은 quiesced로 전이됨; 실패 시 rethrow(익명 세션 유지); (4) 결과 uid=target(비익명, ≠source) 확인 후 `sessions.acquire(target)` → `transition(reconciling)`; (5) 전환 저널 `AccountSwitchJournal{sourceUid,targetUid,provider,operationId(UUID v4 로컬 생성)}`을 **로그인 직후 즉시** SharedPreferences(신규 키 `kl_account_switch_journal_v1`)에 기록; (6) `AccountReconciliationCoordinator`(기존)로 병합: adapter = `FirebaseAccountReconciliationAdapter(uid:target, fenceUid:target, session:reconciling, sessions:, remote: FirebaseAccountReconciliationRemote.firestore(firestore: FirebaseFirestore.instance, fenceUid: target))`; journalStore는 `SharedPreferencesAccountTransitionJournalStore`에 **storageKey 파라미터 추가**해 별도 키 `kl_account_switch_reconciliation_v1` 사용; (7) `completed` → `transition(ready)`, 전환 저널·조정 저널 삭제, `activateBackfill(target)`(= `FirstDurableLinkActivation.activate(sourceUid:target, linkedUid:target, linkedIsAnonymous:false)`), 반환 `completed`; `blocked`(충돌) → 저널 삭제·ready 전이·`AccountFailureDiagnostics.log('switch.mergeBlocked')`·반환 `completed`(클라우드 우선, 로컬은 유지); `unavailable/invalid/tooLarge/stale` → 세션 reconciling 유지, 저널 유지, 반환 `mergeDeferred`.
- `resume(liveUid)`: 저널 있고 `liveUid==targetUid`·비익명 → (4)~(7) 재실행; `liveUid!=targetUid` → 저널 2종 삭제, 반환 `failed`(조용히).
- `auth_service.dart`: `linkWithGoogle/linkWithApple`은 conflict를 `ExistingAccountLinkConflict(provider, credential)`로 던지도록 클래스에 `credential` 필드 추가(`account_transition_coordinator.dart:29`). `_linkAdditionalProvider`·`attemptAnonymousCredentialLink`·`AccountLinkUnavailable` 등 유지. **삭제**: `TemporaryFirebaseUser`~`FirebaseAccountTransitionIdentity`(1760-2130), `replacementAccountOperations()`, `_acquireGoogleActivationCredentialSilently`, `_acquireAppleActivationCredentialExplicitly`. `AccountStartupJournalResolver._restoreReplacement`: 레거시 replacement 저널(`kl_account_transition_journal_v1`에 `replacementPhase!=null`)은 **읽는 즉시 삭제**하고 `none`으로 계속(로그 `startup.legacyReplacementJournalDiscarded`); 전환 저널은 새 `AccountStartupRestorationKind.switchPending` → `AppStartupCoordinator`가 `ensureSignedIn` 후 `resumeAccountSwitch()` 호출(실패해도 부팅 계속).
- `account_transition_coordinator.dart`: `AccountTransitionCoordinator`, `IsolatedTargetVerifier`, `VerifiedTargetContext`류, `ReplacementAccountOperations`, `CallableReplacementAccountOperations`, `ReplacementTransitionJournalStore`, `AccountTransitionStatus/Result` 삭제. 남길 것: `AccountLinkProvider`, `AnonymousCredentialLinkResult` 계열, `ExistingAccountLinkConflict`, `DurableAccountTransitionNotSupported`, `AccountLinkSafetyFailure`, `AccountLinkUnavailable`, `attemptAnonymousCredentialLink`. `FirebaseTargetReconciliationFactory`는 T4에서 `FirebaseAccountReconciliationAdapter` 직접 사용으로 대체 후 삭제.
- `account_operation_client.dart`: replacement 5종 콜러블(`prepareAnonymousReplacement`…`cancelAnonymousReplacement`)과 `AnonymousReplacementPrepareRequest`, `ReplacementAdvanceRequest` 삭제; `getAccountOperation`·`FreshAnonymousAccountOperationGateway`는 삭제 흐름이 쓰므로 유지.
- `account_ui_operations.dart`: `confirmReplacement/resumeReplacement/cancelReplacement` → `Future<AccountSwitchResult> switchToExisting(ExistingAccountLinkConflict)`; `AccountUiPendingState`에서 `replacementCancellable/replacementResumable` 제거, `_readPendingState`에서 replacement 분기 제거. `createReplacementComposition`의 catalog/courseMasteryMerger 로딩은 재사용.
- `account_operation_ui.dart`: `AccountUiLinkConflict` 분기 → 전환 확인 다이얼로그(새 l10n `accountSwitchTitle/Body/Confirm`, de+en) → `switchToExisting` → `completed`: 기존 `onCompleted`+`CloudSync.backup()`; `mergeDeferred`: `accountSwitchMergeDeferredBody` 안내 후 `onCompleted`; `failed`: `showSafeAccountFailure`. `_presentTransitionResult/_resume/_showResume/_retryCancel/_showBlocked` 삭제; `showAccountActionLocked`의 replacement 케이스 삭제.
- 먼저 실패시킬 테스트: `account_switch_coordinator_test.dart` — (a) happy path: signIn 호출 1회, 저널이 signIn 직후 기록됨, reconcile completed → 저널 삭제·세션 ready·backfill 호출; (b) signIn 실패 → 저널 없음, 세션 uid=source 유지, 예외 전파; (c) reconcile unavailable → mergeDeferred, 세션 reconciling 유지, 저널 유지; (d) resume with liveUid==target → completed; liveUid≠target → 저널 삭제; (e) 로컬 스냅샷 FormatException → failed, signIn 미호출. 시작 리졸버 테스트: 레거시 replacement 저널 → 삭제됨 + `none`. UI 테스트(`account_transition_ui_test.dart` 개편): 충돌 → 확인 → completed 경로.
- 완료: analyze 0, `test/services/account/`·`test/widgets/account_transition_ui_test.dart`·`test/account_hardening_test.dart`·`test/account_link_failure_visibility_test.dart`·`test/profile_screen_test.dart`·`test/widgets/settings_screen_test.dart` green. 삭제 코드의 테스트(`account_transition_coordinator_test.dart` 등)는 함께 삭제.
- ⚠ 함정: (1) `credential-already-in-use` 예외의 credential은 Google이면 재사용 가능, Apple도 동일 idToken+rawNonce 재사용(10분 내). (2) `PushOwnershipTransitionCoordinator.run`은 `readySnapshot(oldUid)` 없으면 `blocked` 반환 — 이 경우 `AccountUiLinkBlocked`가 아니라 재시도 안내. (3) `premium_service.dart:595` `userChanges` 리스너가 uid 변경에 반응 — 전환 중 프리미엄 갱신은 허용. (4) `runDurableAccountAdmission` 안에서 실행(기존 link와 동일 레인). (5) `CloudSync.backup()`은 병합 후에만(UI에서 completed 시) — mergeDeferred일 때는 호출 금지(클라우드 덮어쓰기 방지).

- **구현 결과(T4a e8c9344a, T4b 0bbb7527)**: `AccountSwitchCoordinator`(488줄, 테스트 17건) + 배선·제거(26파일, +978/−5643; 브랜치 누계 lib/test +2249/−5627). 삭제된 심볼: 격리 앱 검증기·전환 아이덴티티·`AccountTransitionCoordinator`·replacement 콜러블 5종·resume/cancel 다이얼로그·`replacementCancellable/Resumable` 상태. 시작 시 레거시 replacement 저널은 무조건 폐기(`startup.legacyReplacementJournalDiscarded`), 전환 저널은 `switchPending`으로 부팅 비차단 재개. 승인된 편차: 병합 `blocked`(충돌)에서도 백필 실행(멱등), `account_ui_durable_admission_test`는 전환이 단일 호출이 되어 1건으로 축소(전환 admission은 `account_switch_coordinator_test`·`auth_service_test`가 커버), 미사용 l10n 4키 제거. 검증: analyze 0, 대상 테스트 553 green.

### T5 삭제: 접수 즉시 완료 + 저널 비잠금 + 클라우드삭제 잠금 해제
- 파일: `auth_service.dart` `AccountDeletionCoordinator`(643-1124)·`AccountDeletionOperations`(93-127)·`_FirebaseAccountDeletionOperations`(1450-1636)·`AccountStartupJournalResolver._restoreDeletion`(2201-2250)·`runDurableAccountAdmission`(2846-2868); `account_ui_operations.dart:_readPendingState`; `app_startup_coordinator.dart`; `settings_screen.dart:1835-`; 테스트 `account_deletion_checkpoint_test.dart`, `account_deletion_receipt_recovery_test.dart`, `account_startup_journal_resolver_test.dart`, `account_ui_pending_state_test.dart`, `auth_service_test.dart`(삭제 부분).
- 새 흐름 `_deleteAccount`: reauth(기존) → 저널 pending 기록 → `requestAccountDeletion`(기존) → 결과 phase가 `deletionRequested/userTreeDeleting/appleRevocationPending`(비종단) 또는 `completed`면 **접수 성공**: (a) Apple 연동 계정이면 `completeAppleRevocation(operationId, version, code, clientKind)` 즉시 호출(T3 서버 반영 전제; 실패는 로그만, 진행 계속); (b) `operations.deleteFirebaseUser()` = `user.delete()` 시도 — `requires-recent-login`·`user-not-found`·네트워크 실패는 로그만(워커가 ≤2틱 내 삭제); (c) 저널을 `operation` 포함으로 갱신하되 **곧바로 `clearCompleted`로 삭제**하고 영수증(receipt)만 남김; (d) `_recoverDeletedIdentity()`(기존: Google signOut + auth.signOut + 익명 로그인); 반환. `_pollToTerminal` 삭제. `resumePendingDeletion`: 저널이 있고 `operation!=null`이면 (b)~(d)만 재실행; `operation==null`(서버 미도달)이면 저널 삭제 후 `deleteAccount` 재실행.
- 영수증 백그라운드 ack: `AccountDeletionReceiptRecoveryCoordinator`를 "저널 없이 영수증만"으로도 동작하게(저널 null이면 `blocked` 대신 상태 조회 → `completed`면 ack+영수증 삭제, `not-found`면 영수증 삭제, 그 외 유지). 시작 시 `AccountStartupRestorationKind.deletionReceiptPending`은 **부팅을 막지 않고** `ensureSignedIn` 뒤 best-effort로 실행. 절대 OAuth를 띄우지 않음.
- 잠금 해제: `_readPendingState`에서 deletion 저널은 `operation?.phase==completed && 로컬 정리 미완`일 때만 `deletionLocalCleanup`(재시도 안내), 그 외 저널은 **정보 없이 `none`**(레거시 저널은 시작 시 정리: `operation==null` 또는 `session.uid!=liveUid`면 삭제). `runDurableAccountAdmission`: link/delete 레인은 `cloudBackupDeletion` 저널로 잠그지 않음(`runCloudBackupDeletionAdmission`는 클라우드 데이터 작업에만). `_hasAnyOtherDurableAccountJournal`도 동일 규칙.
- 먼저 실패시킬 테스트: (a) request 성공 후 `deleteFirebaseUser` 1회 호출, 저널 삭제, 영수증 유지, identity 복구 호출, 총 소요에 pollDelay 0회; (b) `deleteFirebaseUser`가 `requires-recent-login` 던져도 성공 종료; (c) Apple 연동이면 `completeAppleRevocation`이 request 직후 호출; (d) 영수증만 있는 시작 → 상태 `completed`면 ack+삭제, `not-found`면 삭제, `pending`이면 유지·부팅 계속; (e) `_readPendingState`: 레거시 deletion 저널(operation 있음, 미완료) → `none`; cloudBackupDeletion 저널만 있음 → `none`.
- 완료: analyze 0, 위 테스트 파일 + `test/widgets/settings_screen_test.dart` green.
- ⚠ 함정: (1) `ownershipTransitions.run` 안에서 `sessions.current.mode==quiesced` 검사 유지. (2) `closeFeedback` 호출 시점(피드백 아웃박스 종료)은 request 성공 직후로 유지. (3) `CompletedDeletionFeedbackActivationCoordinator`(테스터 피드백 핸드오프)는 건드리지 않음 — 다만 저널 삭제 시점이 앞당겨지므로 `completeLocalAccountDeletionCleanup`이 저널 부재를 정상으로 처리하는지 확인. (4) `user.delete()` 뒤 `auth.currentUser`는 null — `_recoverDeletedIdentity`의 `auth.signOut()`은 null-safe여야 함.

- **구현 결과(T5 46b5c0a4)**: 16파일 +1307/−1011. `_pollToTerminal` 삭제 → `_acceptAndFinishDeletion`(거부 phase 검사 → Apple 조기 해지 best-effort → `user.delete()` best-effort → 로컬 완료 체크포인트). 완료 저널의 세션 모드 불변식(`completed`는 `cleanupPending` 세션 필요) 때문에 내구 기록은 소유권 전환 종료 후 `_persistCurrentOwnedSession`에서 수행(브리프 B.3.c의 즉시 기록은 크래시 시 읽기 불가 저널을 만들므로 편차 승인). 영수증 코디네이터는 저널 없이도 동작(completed→ack·삭제, not-found→삭제, blocked/cancelled→조용히 삭제, 진행 중→유지); 시작 시 `deletionReceiptPending`은 부팅 비차단. `AccountUiPendingState`는 `loading/none/deletionLocalCleanup/blocked`만 남고, 클라우드 백업 삭제 저널은 link/switch/delete를 잠그지 않음(`allowCloudBackupDeletionJournal`). 검증: analyze 0, 대상 9파일 179 green.
- **알려진 제한(후속)**: (1) 삭제 요청이 네트워크 오류로 실패하면 세션이 `blocked`로 남아 같은 세션 재시도가 막힘 — 앱 재시작 후 정상(기존 동작과 동일; 전환 흐름처럼 실패 시 세션 재획득을 추가하면 해소). (2) 첫 삭제 시도에서 `closeFeedback`이 실패하면 제출 중이던 테스터 피드백 1건이 아웃박스에 남을 수 있음(유출 없음).

### T6 통합 (Fable)
- 전체 `flutter test`(≈7분) 1회, `flutter analyze`, functions `npm test`, diff 전문 직독, 인수인계 문서, 로컬 커밋(푸시·PR·배포는 Jin 승인 후).
- **결과(2026-09-06)**: analyze 0; gye `npm test` 종료 0(442/1 todo); 전체 스위트 1차(46b5c0a4) 6,008/20/5 실패 → T7(e778fa2a: en dash·폐기 저널 전제 테스트·클라우드 저널 읽기 실패 fail-closed) → 2차 6,015/20/1(옛 리터럴 단언) → T8(8929c266) 파일 17/17. Fable이 T1~T8 diff 전부 직독·승인. 인수인계 `.claude/handoffs/2026-09-06-013000-account-link-delete-fix.md`.
- **병합·배포(2026-09-06)**: PR #275 squash 병합(`c3f5a71f`). Firestore rules + gye 함수 11종 배포(12:42 UTC, 신규 `deleteCloudBackup`·`appleOAuthCallback`·`requestDeletionByProof`). 비대화형 배포를 위해 RC_* 시크릿 3종을 값 `unset` placeholder로 생성하고 워크트리에 gitignored `functions/gye/.env.ko-lernen-app`(코드 기본값, APPLE_* 비어 있음)을 두었다.

### T9 후속 3건 (2026-09-06, Fable 직접 구현 — Jin 지시 "후속작업 전부 fable5.1이 작업")
- 브랜치 `claude/account-followups-20260906`(기준 origin/main `3ce134be` = #274 병합 직후). 워크트리 `C:/dev/hangulsori/ko_lernen_app_worktrees/account-followups-20260906`.
- **(1) 거부·유실된 삭제 요청 뒤 세션 재획득** — `AccountDeletionCoordinator._deleteAccount`: 서버가 요청을 내구 수락(`_requireDeletionOperation` 통과, `serverAccepted`)하기 전에 실패하면 `_reacquireSourceSessionAfterRejectedRequest`가 `blocked` 세션을 `sessions.acquire(sourceUid)`로 되돌리고 `rebindPush`(알림 켜진 경우 `pushService.bindCurrentUser`)를 best-effort 호출. 수락 이후 실패는 종전처럼 `blocked` 유지(서버가 삭제를 소유). 생성자 `rebindPush` 주입(기본 no-op), 프로덕션 배선 2곳(`_startOrResumeRemoteAccountDeletion`·resume). 테스트 2건(`auth_service_test.dart`: 재시도 성공, 수락 후 실패는 blocked 유지).
- **(2) 워커 `appleRevocationPending` 스킵** — `account_operations.js nextPhases(operation, {appleRevocationComplete})`: `userTreeDeleting`에서 진행 플래그가 있으면 `authDeleted` 직행 허용(hop도 계속 허용 → 구 워커 호환). `transitionOperation`이 플래그를 받고 `checkpointDeletionWork`가 병합된 `nextProgress.appleRevocationComplete`를 넘긴다. 워커 `userTreeDeleting` 분기는 플래그가 없을 때만 `appleRevocationPending`으로 이동. T3의 `test.todo`가 실테스트로 전환돼 통과(443/0 todo).
- **(3) 레거시 replacement 저널 키 소비처 정리** — `MediaCleanupGate` 리더와 `Storage` 리셋 펜스가 더 이상 기록되지 않는 `kl_account_transition_journal_v1` 대신 전환 저널 키 2종(`AccountSwitchJournal.storageKey`, `AccountTransitionJournal.switchReconciliationStorageKey` = reconciliation 저널)을 본다. 전환 병합 중 미디어 정리·로컬 리셋 차단이 실제로 다시 동작. 레거시 키는 시작 시 폐기 경로에만 남고 리셋 시 보존 대상에서 제외(회귀 테스트: 리셋이 레거시 키를 지운다). `media_lifecycle_test`·펜스 테스트 재조준, 펜스 테스트 2건 추가.
- 검증: analyze 0; gye 443/0; 대상 11파일 190 green; 전체 스위트는 인수인계 문서 참조. pubspec `2.0.8+36`(versionCode 자체는 `android/app/build.gradle.kts`의 `git rev-list --count`로 자동).
- **하지 않은 것(판단)**: (a) Firebase "익명 사용자 자동 삭제(30일)"는 **권장 철회** — 활동 여부와 무관하게 30일 지난 익명 계정을 지우므로, 로그인 없이 쓰는 학습자의 클라우드 백업·커뮤니티 데이터가 고아가 된다. (b) 코드에서 제거된 구 replacement 콜러블 5종(`prepareAnonymousReplacement`·`attachReplacementTarget`·`commitReplacementReconciliation`·`startSourceCleanup`·`cancelAnonymousReplacement`, 08-12 배포본)은 배포 삭제 보류 — 구 버전 클라이언트가 남아 있을 수 있고 되돌리기 어려워 Jin 결정 사항. (c) `closeFeedback` 실패 시 아웃박스 잔존 1건은 유출 없는 무해 케이스라 그대로 둔다.

## 3. Jin이 해야 하는 외부 작업 (코드로 불가)
1. Apple Developer + Firebase 콘솔에서 Apple 제공자 활성 (T2 런북). **2026-09-06 REST 실측: 아직 미설정(`google.com`만 존재).** 설정 뒤 `functions/gye/.env.ko-lernen-app`의 `APPLE_SERVICES_ID`/`APPLE_REDIRECT_URI`와 GitHub variables를 채우고 `completeAppleRevocation`·`appleOAuthCallback` 재배포.
2. 서버 배포 — **완료(2026-09-06)**. T9 병합 뒤 같은 11종을 재배포한다(인수인계 문서). 재배포는 워크트리의 gitignored `.env.ko-lernen-app`가 있어야 비대화형으로 통과한다. 정확한 명령은 `docs/store/apple-sign-in-setup.md` §5.
3. ~~(권장) 익명 사용자 자동 삭제~~ → **권장 철회**(T9 참조). 켜려면 활동 중 익명 사용자 데이터 손실을 감수하는 결정이 필요하다.
4. 구 replacement 함수 5종의 배포 삭제 여부 결정(T9 참조).
