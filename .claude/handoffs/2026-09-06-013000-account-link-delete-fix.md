# 2026-09-06 계정 연동·삭제 근본 수정 인수인계

> Jin 요청: "계정삭제 안 되고, 구글·애플 연동 안 되는 문제를 완벽히 해결." Fable 설계·Sonnet 구현 체제.
> 브랜치 `claude/account-fix-20260905` · 워크트리 `C:/dev/hangulsori/ko_lernen_app_worktrees/account-fix-20260905` · 기준 `origin/main ef0f0cec` · ~~로컬 커밋 10개, 미푸시, PR 미생성.~~
> **→ 2026-09-06 갱신: PR #275로 main에 squash 병합(`c3f5a71f`), rules+함수 11종 배포 완료. 후속 3건·릴리스 상태는 `2026-09-06-203000-account-followups-release.md`가 최신이다.**
> 설계 SSoT(원인 표·증거·태스크별 구현 결과·편차·외부 작업): `docs/superpowers/plans/2026-09-05-account-link-delete-fix.md`.

## 지금 상태 (한 줄)
코드 쪽 수정은 끝났고 통합 검증까지 마쳤다. 남은 것은 **Jin만 할 수 있는 외부 작업 3개**(Apple 제공자 활성, 서버 함수 배포, 익명 자동삭제 설정)와 **실기기 검증**, 그리고 푸시·PR 결정이다.

## 근본 원인 (조사로 확정, 전부 증거 있음)
| # | 원인 | 결과 |
|---|---|---|
| R1 | **Firebase Auth에 Apple 제공자가 없음**(Identity Toolkit API 실측: `google.com`만 존재) | Apple 연동은 iOS·Android 모두 `operation-not-allowed`. 코드가 아니라 콘솔 설정 문제 |
| R2 | Android Play 빌드에 Apple 웹 플로우 dart-define 없음 + `appleOAuthCallback` 미배포 | Android Apple 버튼 즉시 "미설정" |
| R3 | 삭제 후처리 워커는 5분 틱당 1단계(≥5틱=20분+)인데 클라이언트는 60초만 폴링 | 첫 시도가 구조적으로 항상 실패 + 저널이 모든 계정 액션 잠금(로그: ack 호출 0건) |
| R4 | 충돌 연동(이미 쓰인 Google 계정)이 격리 앱+서버 replacement 6단계+같은 워커에 의존 | "Kontowechsel fortsetzen" 루프; 08-11 이후 서버에 도달한 시도 0건 |
| R5 | 서버 함수 배포본이 **2026-08-12** — 08-16/17 수정·`deleteCloudBackup`·`appleOAuthCallback`·rules 미배포 | 클라/서버 계약 불일치, "Cloud-Daten löschen"은 not-found |
| R6 | 계정 실패 로그가 `debugPrint`뿐 | 운영 실패 관측 불가 |
| R7 | 미배포 `deleteCloudBackup` 호출 실패 저널이 연동·삭제까지 잠금 | 정리 잡 하나가 계정 UI 전체 잠금 |

정상으로 확인된 것: Google 제공자 활성, Android SHA-1 3종+SHA-256 1종 등록, App Check Play Integrity 등록(UNENFORCED), 계정 콜러블 `enforceAppCheck:false`, 워커 스케줄러 정상, Firestore 인덱스 READY.

## 고친 것 (커밋 순)
| 커밋 | 내용 |
|---|---|
| `7a0ea98f` | T2 Play/CI 빌드에 `APPLE_SERVICES_ID`/`APPLE_REDIRECT_URI` dart-define(repo variable) + Jin용 런북 `docs/store/apple-sign-in-setup.md` |
| `8f5d8849` | T1 `AccountFailureDiagnostics` → Crashlytics 비치명 `AccountFailureRecord`(코드만, 원문 예외 없음) |
| `68d783cb` | T3 서버 `completeAppleRevocation`이 `deletionRequested/userTreeDeleting`에서도 해지 접수(진행만 기록, 리스 즉시 만료). gye 스위트 442 통과/1 todo |
| `e8c9344a` | T4a `AccountSwitchCoordinator`: 충돌 시 `signInWithCredential`로 기존 계정 전환 + 기존 병합 코드 재사용, 전환 저널·크래시 재개 |
| `0bbb7527` | T4b 배선 + **서버 replacement 흐름 전부 삭제**(격리 앱·콜러블 5종·resume/cancel UI·저널 상태), 레거시 replacement 저널은 시작 시 폐기, l10n 5키. 26파일 +978/−5643 |
| `46b5c0a4` | T5 삭제: 접수 즉시 Apple 해지(best-effort)→`user.delete()`→로컬 완료 체크포인트→익명 복귀. `_pollToTerminal` 삭제. 영수증은 시작 시 조용히 검증(부팅 비차단). 삭제/클라우드 저널이 연동·삭제를 잠그지 않음 |
| `c3484db7` | 설계 문서 |
| `e778fa2a` | T7 전체 스위트 실패 5건 수정(en dash 제거, 폐기된 저널 전제 테스트 갱신, 클라우드 저널 **읽기 실패**는 여전히 fail-closed) |
| `8929c266` | T8 UI 테스트가 옛 en dash 리터럴 대신 l10n 값을 단언 |

## 검증 상태
- `flutter analyze`: 0 issues (각 태스크 후 + T7 후 229.8s).
- 전체 `flutter test`: T7 이전 6,008 통과/20 스킵/5 실패 → T7 후(e778fa2a) 6,015 통과/20 스킵/**1 실패**(T7가 바꾼 문구를 옛 리터럴로 단언한 UI 테스트) → T8로 해당 파일 17/17 green. 최종 코드(8929c266)는 T7 상태에서 테스트 리터럴 1줄만 바뀐 것이므로 스위트 전체 재실행은 생략(재실행 시 6,016/20/0 기대).
- functions/gye `npm test`: 종료 코드 0 (442 통과/1 todo).

## Jin이 해야 할 외부 작업 (코드로 불가)
1. **Apple 제공자 활성** — `docs/store/apple-sign-in-setup.md` §1~§4 (Apple Developer Services ID·키, Firebase 콘솔 Apple 제공자, GitHub variables, `functions/gye/.env.ko-lernen-app`, `APPLE_REVOKE_*` 실값).
2. **서버 배포(승인 필요)** — 런북 §5: `firestore:rules` → gye 함수 11종 지정 배포(RC_* 시크릿이 없으니 billing 함수 제외). 배포 전까지 클라이언트 T5의 Apple 조기 해지는 stale-version으로 로그만 남고 워커 경로로 처리된다.
3. **(권장)** Firebase Auth 익명 사용자 자동 삭제(30일) — 전환 후 버려진 익명 계정 정리.
4. **푸시·PR** — Jin 명시 요청 시. squash 머지 관례.

## 실기기 검증 체크리스트 (아직 안 함)
- Play 빌드: 새 익명 → Google 연동(제자리 link) → 로그아웃 → 같은 Google로 재연동 → "Konto wechseln" 확인 → 즉시 완료·진행 병합 확인.
- 삭제: Google 계정 삭제 → 즉시 완료·스플래시 재시작·익명 복귀; 다음 실행 시 조용한 영수증 검증(로그 `deletion.receipt.*`).
- 기존 기기(Jin 샤오미)에 남은 레거시 저널: 첫 실행에서 `startup.legacyReplacementJournalDiscarded` 로그 후 버튼 활성.
- Crashlytics 비치명에 `AccountFailureRecord` 유입 확인.

## 알려진 제한 / 후속
- 삭제 요청이 네트워크 오류로 실패하면 세션이 `blocked`로 남아 **같은 세션 재시도가 막힘**(재시작 후 정상). 전환 흐름처럼 실패 시 세션 재획득을 넣으면 해소.
- 첫 삭제 시도에서 `closeFeedback` 실패 시 제출 중이던 테스터 피드백 1건이 아웃박스에 남을 수 있음(유출 없음).
- 워커의 `appleRevocationPending` 스킵은 phase 테이블(`account_operations.js nextPhases`) 제약으로 미적용 — 1틱(≤5분) 지연뿐, 클라이언트는 기다리지 않음.
- 병합 `blocked`(충돌)는 클라우드 우선으로 마감하고 백필·백업이 로컬을 올림 — 충돌 종류가 실제로 발생하면 재검토.

## 읽지 말 것
- `docs/HANDOFF_account-link-reconciliation-bug.md`(08-11 진단) — 대체됨. `docs/ACCOUNT_SYSTEM_AUDIT_2026-06-03.md` — 구 설계.
- Sonnet 브리프는 세션 스크래치패드에만 있었다(`brief-T1..T7`); 계약은 설계 문서 §2와 코드 주석에 옮겨져 있다.
