# HANDOFF — Google 계정 연동 무한 루프 (reconciliationPending)

**작성:** 2026-08-10 (Claude, 실기기 디버그 세션 말미) · **상태:** 미해결, 다음 세션에서 집중 조사

---

## 증상
- 샤오미 M2101K6G(Android 12) 디버그 빌드에서 **Google 계정 연동을 눌러도 완료가 안 됨.**
- UI가 "Kontowechsel fortsetzen"(재개) / "werden sicher geprüft"(확인 중)에서 멈추고, `fortsetzen`을 눌러도 **같은 화면 반복**.
- 계정 **삭제**도 같은 이유로 막힘(미완료 계정 작업이 모든 계정 작업을 잠금).

## 핵심 로그 (재현되는 시퀀스)
```
klAccount: link.confirm.start none
klAccount: link.prepare.start none
klAccount: link.prepare.ok none version=0
klAccount: link.confirm.result none status=reconciliationPending   ← 매번 여기서 멈춤
```
- `confirm`이 **즉시 `reconciliationPending`** 을 반환하고, 그 뒤 **조정(reconciliation) 체크포인트 진행 로그가 전혀 없음**(remoteRead / merged / remoteWritten / localWritten / completed 중 아무것도 안 찍힘).
- 즉 confirm 이후 **실제 reconciliation 러너가 돌지 않거나, 돌아도 조용히 pending으로 되돌아옴** → 무한 루프.

## 확실히 배제된 것 (다시 조사하지 말 것)
1. **App Check 아님.** 디버그 토큰 `cfb3e027-0243-45e2-b359-cee5541e0d98`을 Firebase Console에 등록했고, `link.prepare.ok`가 찍히므로 보호 콜러블은 통과함.
2. **특정 계정이 갇힌 상태 아님(코드 버그임).**
   - Firestore `account_operation_owners`의 소유 문서 2개(그 계정들의 `sha256("account-operation-owner\0"+sourceUid)`)를 삭제해봄 → 효과 없음.
   - `pm clear`로 **완전 새 익명 계정** + **다른 Google uid**로 시도해도 **동일하게 `reconciliationPending`** 재현. → 데이터가 아니라 흐름 버그.

## 조사 진입점
- 클라이언트 UI 흐름: `lib/widgets/sori/account_operation_ui.dart`
  - `_presentTransitionResult()` — `reconciliationPending` → `_showResume()` (canCancel=true)
  - `_resume()` → `operations.resumeReplacement()` → 결과가 또 pending → 루프
  - **의심 1:** `resumeReplacement()`가 reconciliation 러너를 실제로 **호출하는가?** (confirm 상태만 다시 읽고 pending 재반환하는 것 아닌지)
  - **의심 2:** "Abbrechen(취소)"이 서버 취소를 호출하지 않고 **대화상자만 닫음**(로그에 cancel 없음) — 별도 UX 갭.
- 조정 러너: `lib/services/account/account_reconciliation.dart` — `reconcile()`, `ReconciliationCheckpoint`(remoteRead/merged/remoteWritten/localWritten/completed). **왜 completed까지 못 가는가**가 핵심.
- 코디네이터: `lib/services/account/account_transition_coordinator.dart` (상태머신: targetVerified/prepared/reconciliationPending/…)
- 서버(Cloud Functions): `functions/gye/account_operations_runtime.js`
  - Firestore 컬렉션: `account_operations`(문서=operationId), `account_operation_owners`(문서=`sha256("account-operation-owner\0"+sourceUid)` → operationId), `account_operation_requests`, `account_deletions`, `account_deletion_proofs`, …
  - `stableKey(...parts) = sha256(parts.join(NUL))` (pepper 없음). owner 문서 id 계산은 scratchpad `ownerhash.js` 참고.
- 서버 로그 필요: `confirm` 콜러블이 왜 reconciliationPending을 즉시 반환하는지 Cloud Functions 로그 확인(GCP 콘솔).

## 다음 세션 재현/디버그 셋업
- 기기: `adb -s 9053622f` (샤오미 M2101K6G). 앱 데이터 리셋: `adb -s 9053622f shell pm clear com.sujinarin.ko_lernen_app`.
- 실행: `flutter run -d 9053622f --debug --dart-define-from-file=dart_defines/appcheck_debug.json` (App Check 디버그 토큰 주입 필수).
- 로그의 `klAccount:` 프리픽스로 계정 흐름 추적.

## 이번 세션에서 함께 나온 별개 이슈(미해결, 낮은 우선순위)
- **삭제 페이지 URL 불일치:** `docs/*.html`(옛 정적 사이트, `account-deletion.html`) vs `hangul-sori-site-local/`(신 Next.js, `/account-deletion`). Play Console "계정 삭제 URL"이 라이브(신 사이트 `/account-deletion`)를 가리키는지 확인 필요. `docs/`의 `.html` 링크를 일괄 치환하면 옛 사이트가 배포 중일 때 404 위험 → 라이브 확인 후 필요한 곳만.
