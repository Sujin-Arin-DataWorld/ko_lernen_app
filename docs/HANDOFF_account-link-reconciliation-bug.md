# HANDOFF — Google 계정 연동 무한 루프 (reconciliationPending)

**작성:** 2026-08-10 (Claude, 실기기 디버그 세션 말미)
**갱신:** 2026-08-10 (Claude, /debug 세션 — 원인 지점 특정 + 진단 계측)
**해결:** 2026-08-11 (Claude — **근본 원인 확정 + 수정 + 재현 테스트**)

---

## 🟢 RESOLVED (2026-08-11) — 이것부터 읽기

**근본 원인 (실기기 데이터로 재현 확정):**
커스텀 팩이 **없는** 계정(= 대부분의 사용자)에서 `CloudSync.buildBackupPayload` 가
`custom_packs_json: ''`(**빈 문자열**)을 실어 보냈다. 소비자
`CustomPackService.decodePortableRemote('')` 가 `jsonDecode('')` 로 **던져** →
`invalid` 반환 → `AccountReconciliationSnapshot.decodeCloudDocument` invalid →
`LocalAccountReconciliationStore.load()` 가 `FormatException('Invalid local
reconciliation data.')` (account_reconciliation.dart:~614) → 조정 러너 `invalid`
반환 → 코디네이터가 `reconciliationPending` 으로 뭉갬 → **무한 루프.**
커스텀 팩이 없는 거의 모든 계정에서 **결정적으로** 재현 → "신규 계정마다 재현"과 정확히 일치.

실기기 로그(진단 계측 덕분에 특정됨):
```
klAccount: link.reconcile.loadLocal.invalid format
klAccount: link.reconcile.pending status=invalid conflicts=none
```

**수정 (프로덕션 동작 변경은 이 한 곳뿐):**
`lib/services/custom_pack_service.dart` `decodePortableRemote` 가 빈/공백 문자열을
`invalid` 이 아니라 **`absent`** 로 취급한다(형제 디코더 `_decodeSrs`·
`_decodeCourseMastery` 와 동일). 실데이터 엄격 검증은 그대로.

**검증:** 실기기 shared_prefs 원문으로 `load()` 실패를 재현 →수정 후 통과
(`test/services/account/loadlocal_device_repro_test.dart`). 기존 142개 + 분석기 클린.

**아직 안 한 것:** 새 빌드로 **실기기 연동 최종 확인**(리빌드·설치 완료, 사용자 탭 대기).
**주의(2차 관찰):** 재개 시도에서 `link.reconcile.readRemote.state=unavailable` 이
찍혔음 — loadLocal 실패의 부수효과일 가능성이 크나, 연동이 그래도 안 되면 이걸 조사.

> 아래 "제 1순위 가설(merge/course)" 은 **틀렸다** — 병합/코스마스터리는 정상이었다.
> `_dropUnvalidatableEvidence` 로 course_mastery 를 건드렸던 변경은 **되돌렸다.**

---

## ✅ 2026-08-10 /debug 세션 결론 (먼저 읽기)

정적 분석으로 아래를 **확정/배제**했다:

- **확정:** UI 가 `reconciliationPending` 에 도달했다는 사실 자체가 → `attachTarget` **성공** + `reconcile()` 가 **실제로 돌았고** `{blocked, unavailable, invalid, tooLarge, stale}` 중 하나를 반환했음을 **증명**한다.
  - 근거: attachTarget 실패면 `blocked` 반환(pending 아님). attachTarget 예외면 `link.confirm.threw` 로그. reconcile 예외도 마찬가지. → pending 은 오직 `reconcile 정상 반환 & status != completed` 경로뿐.
  - 즉 이전 핸드오프의 "조정 러너가 안 돈다" 는 **추론이 틀렸다**. 러너는 돈다. 문제는 **어느 하위 단계가 non-completed 를 뱉느냐**.
- **배제(다시 조사 금지):**
  1. `CloudWriteSession` 동일성 — 값 기반 `==` 이라 저널 JSON 왕복 후에도 동치(문제 아님).
  2. operationId 형식 — 서버는 UUID(`crypto.randomUUID()`), 클라이언트 `_validOperationId` 통과(문제 아님).
  3. `reconciliationOperationId` 유실 — `copyWith` 가 `?? this.x` 로 보존, `_validate()` 불변식과 일치(문제 아님).
  4. 원격 쓰기/composite 해시 불일치 — `_payloadHash` 를 write/validate 가 동일 `rootData` 로 계산(항상 revisionConflict 아님).

### 진짜 결함: **관측 불가(silent failure)**
- `AccountReconciliationCoordinator.reconcile` 이 모든 오류를 `catch (_)` 로 삼키고 상태 enum 만 반환.
- `AccountTransitionCoordinator._continue` 가 5가지 non-completed 상태를 **전부 하나의 `reconciliationPending`** 으로 뭉갬(로그 0줄).
- → **그래서 3세션 동안 원인 판별이 불가능**했다. 이번에 이걸 고쳤다(동작은 그대로, 로그만 추가).

### 이번 커밋에서 추가한 진단 (동작 불변, 로그 전용)
- `lib/services/account/account_reconciliation.dart` — `reconcile()` 의 각 조기 반환에 `klAccount: link.reconcile.<step>` 로그. `catch (_)` → `catch (error)` 로 바꿔 **삼켜지던 Firestore/IO 오류 코드**를 안전하게(describe) 남김.
- `lib/services/account/account_transition_coordinator.dart` — collapse 지점에 `klAccount: link.reconcile.pending status=<X> conflicts=<종류:개수>`.
- 검증: `account_reconciliation_test.dart` + `account_transition_coordinator_test.dart` 84개 그대로 통과, `flutter analyze` 클린.

### ▶ 다음 세션이 할 일 — 실기기 1회 실행이면 끝
1. 재현(아래 셋업)하고 `adb -s 9053622f logcat | grep klAccount` 로 다음 두 줄을 캡처:
   - `link.reconcile.<step> <errorCode>`  (러너 내부 — 어느 단계가 실패했나)
   - `link.reconcile.pending status=<X> conflicts=<...>` (최종 상태)
2. 그 한 줄로 **아래 표에서 원인·수정을 즉시 확정**한다:

| 로그가 이렇게 나오면 | 근본 원인 | 타깃 수정 |
|---|---|---|
| `readRemote.threw firebase:cloud_firestore/permission-denied` | 격리(2차) 앱의 **타깃 문서 Firestore 읽기**가 규칙/App Check 로 거부 | 2차 앱 App Check 토큰 등록 확인 / 규칙에서 타깃 self-read 확인 |
| `readRemote.threw firebase:cloud_firestore/unavailable` 또는 `firebase:*/unauthenticated` | 2차 앱 인증/네트워크 | 2차 앱 `signInWithCredential` 세션·토큰 확인 |
| `readRemote.state state=invalid`/`tooLarge` | 타깃 원격 문서가 파싱 불가/과대 | 디코더(`decodeCloudDocument`) 또는 데이터 정리 |
| `loadLocal.invalid format` | **로컬** 스냅샷 파싱 실패(`LocalAccountReconciliationStore.load`) | 어느 로컬 소스가 깨졌는지(srs/customPacks/course) 좁히기 |
| `loadLocal.unavailable other:<Type>` | 로컬 캡처 중 예외(예: courseMastery capture) | 해당 서비스 초기화/캡처 경로 |
| `writeRemote.threw firebase:*/permission-denied` | 타깃에 **reconciled 쓰기**가 규칙 위반(pack `validPackProgress`/membership) | 병합 결과 shape 대 규칙 대조 |
| `merge.blocked conflicts=N:<종류>` | **병합 충돌**(예: courseMasteryVersion) — 신규 소스+타깃 조합에서 결정적 | 해당 종류 merge 정책 완화/해소 규칙 |
| `pending status=blocked conflicts=none` & 위 로그 없음 | 저널 쓰기 실패 or CAS 3회 소진 | `_writeJournal` 실패 or writeRemote 지속 revisionConflict |

> 주의: `status=stale` 는 조정 도중 세션이 바뀐 것 → 계정연동과 **동시에 다른 계정 작업**이 끼어들었는지 확인.

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
