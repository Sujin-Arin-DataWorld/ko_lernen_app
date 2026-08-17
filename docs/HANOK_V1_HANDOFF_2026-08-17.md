# 한옥 V1 진행 인수인계 (세션 2026-08-17 기준)

이 문서는 다음 세션에서 이어서 바로 작업할 수 있도록, 현재 상태·위험·다음 실행순서를
기술적으로 고정한 문서입니다.

## 0) 현재 기준(명확한 버전 고정)

- 작업 루트: `C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app`
- `git status --short --branch` (현재):  
  - 브랜치 `main`, `## main...origin/main [behind 15]`
  - 커밋 `db9413c9` (`main` HEAD)
- `origin/main` HEAD: `a6c2eae5`
- 존재하는 로컬 작업 브랜치:
  - `codex/hanok-v1-a1-assets-20260817` → `aaf6d969`  
  - `codex/hanok-v1-state-20260816` → `64b7e24a` (`origin/codex/hanok-v1-state-20260816` 대비 1개 뒤처짐)
  - `origin/cursor/hanok-v1-pr4-pipeline-ef56` (원격 추적 브랜치) → `9e317d8e`

참고: 과거 대화에서 언급된 `39dff9df`는 현재 `main`이 아니라 일부 로컬/브랜치 상의
중간 커밋이며, 최신 기준 SHA와 다릅니다.

## 1) 지금까지 완성된 핵심 범위 (이미 실질적 계약 반영됨)

### PR2 계열 (생산형 학습 증거/문항)
- `account_reconciliation.dart`, `cloud_sync.dart`, `hanok_cutover_service.dart`,
  `hanok_state_service.dart`, `hanok_experience_projector.dart` 등으로
  productive evidence 기반 프로젝션/재평가 경로까지 선적(요건별 추적)
- `lib/models/hanok_growth.dart` 중심으로 한옥 상태를 한 번의 canonical 스냅샷으로
  파생 계산.
- 테스트: `hanok_*` 테스트군, `hanok_state_service_test`, `hanok_experience_projector_test`,
  `hanok_account_reconciliation_test`, `hanok_cloud_sync_test`를 통한 로컬 검증 경로 정착.

### PR4 계열 (A1 렌더/에셋 파이프라인)
- `a1_hanok_construction_map` 렌더 경로, 4:3 뷰어/소켓 조정, 상태 노출 맵 테스트
- `tool/compose_hanok_a1_state.py`, `promote_hanok_a1_states.py`,
  `check_personal_hanok_assets.py`, `hanok_v1_asset_contract.py`
- `docs/HANOK_V1_ASSET_PROVENANCE.json`에 카메라/앵커/런타임 정책/권리 제한/생성원장 스키마 고정
- 하지만 **runtime 상태 자산은 미승격 상태**

## 2) 현재 Blocking 포인트(다음 세션 즉시 처리 필요)

1. **A1 상태 자산 미승격(가장 중요)**
   - `assets_unused/pending_review/a1_states/`에는 `05~10`만 존재(로컬 main/브랜치 모두)
   - `assets/illustrations/personal_hanok_v2` 런타임에 A1 `01~16` 상태 WebP가 없음
   - `python tool/check_personal_hanok_assets.py` 출력:  
     `A1 runtime states are absent and were not promoted`
   - `a1ConstructionStates.expectedFiles`에는 `01~16` 모두 정의됨(총 16개)
   - 즉 11~16(및 일부 00 기준 상태)는 아직 생성/승격이 필요함

2. **hanok 권장/구조 정합성은 완성되었으나, 계정 재조정 race 리스크 잔류**
   - `lib/services/account/account_reconciliation.dart`의 `_assertHanokGeneration`은 존재하나,
     `LocalReconciliationGenerationConflict` 발생 시 재시도/원자성 타이밍 경계가 더 엄격할 필요가 있음.
   - 하위 이슈 포인트:  
     `cloud_sync.dart`의 `buildBackupPayload`/`expectedGeneration` 전달 + 재시도 루프에서
     local write 중간 단계에서의 snapshot-raw 순서 불일치.

3. **main과 origin sync 불일치**
   - 현재 main이 `origin/main` 대비 15커밋 뒤처짐.
   - `origin/cursor/hanok-v1-pr4-pipeline-ef56` 커밋군(예: `0398bc5c`, `9e317d8e`)은
     아직 main에 그대로 통합되지 않은 채 분리되어 있음.

## 3) 다음 세션 1차 실행 순서 (권장)

### 1순위: git 상태 정리 & 기준 고정
```bash
git -C "C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app" fetch --all --prune
git -C ... status --short --branch
git -C ... log --oneline --decorate -n 12 origin/main
git -C ... branch -vv
git -C ... rev-parse HEAD origin/main
```

### 2순위: PR4 파이프라인 복구(필수)
- `assets_unused/pending_review/a1_states/`에서 누락분 생성
- `compose_hanok_a1_state.py` 및 `promote_hanok_a1_states.py`로 `01~16` 채움
- `hanok_v1_asset_contract.py` 기준 검증
- `tool/check_personal_hanok_assets.py` 통과 + `test/a1_hanok_construction_map_test.dart` 통과

### 3순위: 계정 재조정 race hardening
- `lib/services/account/account_reconciliation.dart`와 `cloud_sync.dart`의 동시성 경로를
  아래 케이스 기준으로 회귀 테스트 강화:
  - local write 단계에서 hanok generation 변경 후 remote write race
  - `LocalReconciliationGenerationConflict` 3회 재시도 이상
  - session mode 전환 후 stale 종료
- `hanok_account_reconciliation_test.dart`에 새 회귀 케이스 추가

### 4순위: PR3/PR4 통합 진입점 재검증
- `origin/cursor/hanok-v1-pr4-pipeline-ef56` 기준 필요한 커밋을 base로 cherry-pick 또는 branch 재기반화
- `flutter test` 범위를 다음으로 분할 실행:
  - `flutter test test/hanok_*_test.dart`
  - `flutter test test/hanok*`  
  - `flutter test test/a1_hanok_construction_*_test.dart`

## 4) 기술적 기준(누수/회귀 방지)

- 카메라/소켓/앵커/소스 해시/생성원장은 현재 문서 기준 그대로 유지  
  (`docs/assets/HANOK_V1_ASSET_PROVENANCE.json`, `docs/HANOK_V1_SOURCE_REGISTRY.md` 경로)
- 런타임에는 `reference_only_user_supplied`, `vivasam`, `stage_beams_light` 등 미승인 산출물 금지
- A1은 기존 legacy 구조를 대체하지 않는 방식이 아니라 V1 projection 기준으로 표시되도록 유지

## 5) 사용자 커뮤니케이션용 단축 요약

현재 상태는 “코드 본체는 90% 이상 준비”, “A1 에셋 승격만 남음”, “동기화 경합 방어만 hardening”입니다.  
즉, **남은 임팩트는 에셋/승격 + 동시성 미세 패치 + 통합 기준 동기화**입니다.

## 6) 크레딧/세션 전환 운영 전략 (중요)

- 다음 세션에서 5회 이내 재현성 확인 후 바로 commit 가능한 형태:
  1) 기준 고정 커맨드 실행  
  2) A1 16개 상태 파일 존재성/체크 통과  
  3) 한옥 재조정 테스트 1개(충돌 재시도) 추가  
  4) `flutter test` 핵심 3개 묶음 통과  
- 위 4단계를 통과하면 작업이 중단 없이 다음 단계(PR5/PR6/PR7)로 넘어갈 수 있습니다.

