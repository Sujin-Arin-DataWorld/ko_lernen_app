# 한옥 V1 / 배포준비 연속 인수인계 (2026-08-17 최신 기준)

요청하신 대로 다음 세션에서 이어서 바로 작업할 수 있도록 현재 상태를 “사실 기반”으로 고정했습니다.  
다음 항목은 이 문서 기준으로만 실행하면 됩니다.

## 1) 현재 Git 기준(현실 우선)

- 작업 루트: `C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app`
- 현재 브랜치: `main`
- `git status --short --branch`: `## main...origin/main [behind 15]`
- `main` HEAD: `db9413c9`
- `origin/main` HEAD: `a6c2eae5`
- 현재 `main`은 remote보다 **15 commit 뒤처짐**입니다.
- 현재 untracked: `.mvn/`, `docs/HANOK_V1_HANDOFF_2026-08-17.md` (우리가 방금 본 handoff 문서 포함)

### 분기/병합 상태 요약

- `origin/main`에 포함되지 않은 커밋이 아니라, **`main` 자체가 뒤처진 상태**입니다.
- `39dff9df`는 과거 tag(`android-2.0.5+1121`)이며 현재 기준 pin이 아닙니다.
- `ff27b1b4`~`e8dada25`, `ffadc8e3`, `4033cd8e` 계열은 현재 `origin/main` 계열에도 모두 포함된 내력입니다.
- 다만 아래 local branch는 `origin/main`에서 아직 흡수되지 않았음(별도 병합 필요):
  - `codex/hanok-v1-a1-assets-20260817` (`aaf6d969` ... `67f3ce02` 일련)
  - `codex/hanok-v1-state-20260816` (`64b7e24a` ... `7a084227` 상위 remote 커밋 대비 낡음)

## 2) “site-runtime이 트랙 안됨” 질문에 대한 정답

`site-runtime` 이라는 브랜치/트래킹이 여기서는 보이지 않습니다.  
실제로 점검 결과는 다음 중 하나에 가깝습니다.

1) **`A1` 런타임 상태 자산이 Git에 승격되지 않음**(가장 강한 원인)  
   - `python tool/check_personal_hanok_assets.py` 결과:  
     `A1 runtime states are absent and were not promoted`
   - `assets_unused/pending_review/a1_states`는 `.gitkeep`만 있음.

2) **main이 원격보다 뒤쳐진 상태**에서 Mac에서 `origin/main`만 pull한 경우  
   - 로컬 `main`이 `origin/main` 기반이 아니라 과거 SHA 위에 있기 때문에,
     원하는 변경이 안 보이거나 branch tracking이 깨진 것처럼 보일 수 있음.

요약: “깃에 안 올린 적이 있나?”에 대한 답은  
- 원격에는 핵심 기본 기능 커밋이 대부분 있지만,  
- A1 렌더/승격(런타임 WebP) 커밋은 아직 **공유/배포 기준(`origin/main`)에 안 올라와 있거나 승격 단계가 안 끝남**입니다.

## 3) 지금 왜 오래 걸리나 (진행 지연 이유)

현재 작업은 단순 기능 하나가 아니라 다음이 동시 결합되어 있어서 시간이 걸립니다.

- PR2/PR3/PR4 계약(생산형 증거 모델, 재조정 동기화, 한옥 projection)
- 계정 동기화 race 방어(Cloud/Local generation CAS)
- 새 86개 can-do와 16개 A1 construction 단계의 정확한 증거 의존성
- A1 런타임 에셋 생성/승격(자체 생성 원본/권한/검증 가드)
- full-suite + focused + Python + Node 병렬 테스트가 섞인 CI 게이트

오래 걸린 건 ‘버그’만 아니라 **분기 통합 + 증거 무결성 보장 + 대량 회귀 검증**이 동시 병행되었기 때문입니다.

## 4) 바로 이어서 할 작업(우선순위)

### P0. Mac/Windows Git 기준 동기화 (오늘 가장 먼저)
```bash
cd "C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app"
git fetch --all --prune
git status --short --branch
git rev-parse main
git rev-parse origin/main
git log --oneline --decorate -n 20 origin/main
```

`main`이 뒤쳐졌으면:
```bash
git checkout main
git pull --ff-only origin main
git status --short
```

> 새로 올릴 변경이 필요하면 `main`에서 바로 작업하지 말고 아래 방식 권장

```bash
git checkout -b codex/hanok-v1-sync-fix origin/main
git cherry-pick <필요한 로컬 커밋들>
```

### P1. A1 런타임 에셋 승격 (실질 완성 블로커)
- 현재 상태: `assets/illustrations/personal_hanok_v2`에 A1 누적 16단계 WebP 없음
- `assets_unused/pending_review/a1_states`도 비어 있음
- 실행 절차:
  1) `A1` 레이어 산출물 생성
  2) `compose_hanok_a1_state.py`로 합성
  3) `promote_hanok_a1_states.py --apply`로 런타임 승격
  4) `python tool/check_personal_hanok_assets.py` 재확인(이제 A1 absense 경고 없어야 함)

### P2. 동기화 race hardening(잔여)
- `lib/services/account/account_reconciliation.dart`와 `cloud_sync.dart` 결합 경로에서
  `LocalAccountReconciliationGenerationConflict` 경합 대응(재시도/전파)을 재검증.
- 실패 케이스에서 local write가 remote overwrite로 덮이는지 회귀.
- 관련 테스트: `test/services/account/account_reconciliation_test.dart`, `test/hanok_account_reconciliation_test.dart`

### P3. PR4/PR5 진입점 일치 확인
- `codex/hanok-v1-a1-assets-20260817` 브랜치의 A1 렌더 코드/커밋이 기준 브랜치에 반영되었는지 확인
- PR3 계열에서 만든 `hanok_state/production projection`는 유지(재기반 시 원자성 유지)
- `main`로 병합 전 항상 `flutter test --no-pub --reporter compact` focused 묶음 + `flutter analyze --no-pub --fatal-infos` 통과

## 5) 지금 실행 가능한 검증 명령(최소 1차)

```bash
python "C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app\tool\check_personal_hanok_assets.py"
python -m unittest tools.content_factory.test_build_hanok_grants
python tools/content_factory/build_productive_assessments.py --check
flutter test --no-pub --reporter compact `
  test/services/account/account_reconciliation_test.dart `
  test/hanok_account_reconciliation_test.dart `
  test/hanok_state_service_test.dart `
  test/hanok_cloud_sync_test.dart `
  test/hanok_v1_source_guard_test.dart
flutter analyze --no-pub --fatal-infos
git diff --check
```

## 6) 다음 PR/커밋 전략 (크레딧 3% 세이프)

- 작업 완료를 “세션 단위 기능”이 아니라 **게이트 단위**로 잘라서 진행:
  1) 동기화 정합(merge-safe)
  2) A1 승인/승격
  3) 한옥 상태/합성 테스트
  4) 앱스토어용 정리
- 각 단계에서 **모든 테스트 green이면 즉시 `git add`(경로 지정), 커밋, 푸시**.
- 현재 상태에서는 `site-runtime` 이슈가 branch/tracking이 아니라 “누락된 승격 아티팩트 + main 동기화”가 핵심입니다.

## 7) 추천 모델/추론 모드(남은 단계)
- 남은 단계는 아키텍처/동기화/게이트 통합이 뒤섞인 고위험 작업입니다.
- 5.6 Sol + High가 가장 안정적입니다.
- 작업량이 폭증할 때는 세션 분할(한 번에 하나 PR, 하나 큰 테스트 묶음)로 진행하면 실패 비용이 낮아집니다.
