# 살아 있는 한옥 V1 PR3 인수인계 — 2026-08-16

상태: **PR3 로컬 구현·검증 완료; commit/push/PR lifecycle 진행 전**
다음 세션의 첫 목표: 아래 수정 완료분을 재검증하고 PR3를 exact-head CI 통과 후 `main`에 병합한다.
프로덕션 배포·스토어 제출·Firebase 배포는 이 인수인계의 승인 범위가 아니다.

## 1. 작업 위치와 Git 기준

- 정본 저장소: `C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app`
- PR3 독립 worktree: `C:\Users\vjinn\.codex\worktrees\ko_lernen_app-hanok-v1-pr3`
- 브랜치: `codex/hanok-v1-state-20260816`
- 현재 base/HEAD: `82afdcde8ffdbc978499f4dd1cc20bf2944e20ed`
- 현재 `origin/main`: `82afdcde8ffdbc978499f4dd1cc20bf2944e20ed`
- base commit: `fix(ci): constrain Android release memory`
- PR2 merge: PR #31, `90613738f7725cf38be08d1f3cdf9bb2520b62bc`
- PR2 exact head: `8db0415d350a1255482ed83dfb3a577575e6a7a3`
- PR2 exact-head CI run: `31970454213`, green

`main`과 공유 checkout을 수정하지 않는다. 모든 PR3 변경은 위 독립 worktree에만 있다.
현재 PR3는 base 위의 **uncommitted working tree**다. `git reset --hard`, broad
`git add .`, shared checkout에서의 cherry-pick을 사용하지 않는다.

다음 세션 시작 즉시 실행:

```powershell
Set-Location 'C:\Users\vjinn\.codex\worktrees\ko_lernen_app-hanok-v1-pr3'
git status --short --branch
git rev-parse HEAD
git fetch origin main
git rev-parse origin/main
git diff --check
```

원격이 이동했으면 먼저 변경 경로를 확인한다. dirty 상태에서 무작정 rebase하지 않는다.
이번 세션에서는 `git rebase --autostash origin/main`으로 `82afdcde`까지 안전하게
흡수했고 autostash가 정상 재적용됐다. Git이 과거 PR2 worktree metadata 삭제에서
permission warning을 한 번 냈지만 PR3 rebase와 파일에는 영향이 없었다.

## 2. 최종 제품 계약

### 2.1 학습 권한과 한옥 권한

```text
completedUnitIds - bypassedPrerequisiteUnitIds
  -> 완료 단원의 재평가 자격만 제공

trusted ProductiveMasteryEvidence
  + exact ProductiveAssessmentDefinition fingerprint
  + required project-step receipts
  + published CanDoSegment allOf policy
  -> verifiedCanDoSegmentIds
  -> immutable Hanok grant slot
  -> HanokExperienceProjection
```

- CourseUnit 완료만으로 집, 부재, 디자인, 방, 도장을 주지 않는다.
- 단어팩, XP, browse, bypass, recognition, Cloze, Satz, Gye도 개인 한옥 권한이 아니다.
- 영구 보상 권한은 검증된 productive `CanDoSegment`만 가진다.
- 기존 CourseUnit 완료자는 재평가 자격은 열리지만 신뢰 가능한 생산 증거가 없으면
  새 한옥은 빈 터에서 시작한다.
- legacy `HanokStage`, 단어팩 ratio, 7 milestone, safe-scene beam, 과거 reveal 기록을
  새 집의 학습 권한으로 가져오지 않는다.
- room-v3 배치, 장식 소유권, Gye, CourseMastery, SRS, XP, stamp는 보존한다.
- PR3는 상태·projection 기반만 구현하며 사용자 기본 route에는 노출하지 않는다.

### 2.2 계속 늘어나는 콘텐츠

- core denominator는 `core_2026_v1`의 86개다.
- 레벨별 `A1/A2/B1/B2/C1/C2 = 16/16/18/20/8/8`이다.
- 같은 능력의 새 연습 콘텐츠는 `ContentCluster.revision`만 올린다.
- 진짜 새 can-do는 기존 core에 삽입하지 않고 뒤쪽 additive extension track에 발행한다.
- 평가 교체는 기존 segment를 retire하고 같은 construct lineage의 successor를 분모 0인
  replacement track에 발행한다.
- replacement는 기존 영구 보상 slot을 만족할 수 있지만 새 grant를 만들지 않는다.
- Batch 06은 review-only다. 사람 검수 0/68인 상태에서는 assessment/grant authority가 아니다.

정본 문서:

- `docs/ADR-003-can-do-segment-authority.md`
- `docs/plans/2026-08-16-living-hanok-v1-execution.md`
- `docs/CONTENT_ARCHITECTURE.md`
- `docs/HANOK_V1_SOURCE_REGISTRY.md`

## 3. 현재 PR3에서 구현된 코드

### 3.0 2축 리뷰 후 blocker 수정 현황

2026-08-16 독립 Spec/Standards 리뷰에서 나온 P1 8건은 코드와 회귀 테스트로 모두
수정했다. 아직 commit 전이므로 “완료”는 로컬 구현 상태를 뜻하며, 아래 최종 전체 gate와
exact-head CI가 끝나기 전에는 병합 완료로 간주하지 않는다.

- 같은 clock 충돌은 payload까지 포함한 total order로 결정해 merge가 교환·결합 가능하다.
- 모든 Hanok 저장은 process-wide static queue와 generation fence를 함께 사용한다.
- direct save와 cloud union 모두 256KB를 넘으면 기존 local을 보존하고 fail closed한다.
- A1 평가·grant 2–16은 바로 앞 단계 prerequisite를 가져 한 번에 한 공정만 열린다.
- 16단계 밖 extension은 명시적인 authored row 없이는 generator가 실패한다.
- published grant는 별도 append-only release ledger가 mutation/deletion을 차단한다.
- 미승인 86 grant plan은 tools draft에만 있고 Flutter runtime asset/loader에는 없다.
- 새 eligible activity는 알림 cycle을 초기화하고, stale 기기 ID는 새 cycle로 부활하지 않는다.

### 3.1 Domain model

신규 `lib/models/hanok_growth.dart`:

- `HanokGrowthEra`: build/live/connect/share/care/transmit
- `HanokGrantKind`: constructionPiece/designOption/venue/ambience/credential
- `HanokDesignSlot`: roofMaterial/roofForm/changho/door/wallFinish/signboard/
  courtyard/ambience/regionClimate
- `HanokOptionProvenance`: commonResidential/contextPlausible/
  ceremonialImaginative
- `HanokWeatheringTier`: fresh/livedIn/patina
- `HanokGrantDefinition`
- `HanokLwwClock`, `HanokLoadoutSelection`, `HanokCareState`
- `HanokState` schema v1, cutover version 2
- `HanokTrackProgress`, `HanokRoomLayoutProjection`, `HanokExperienceProjection`
- `HanokGrantReceipt`

중요: `HanokState`에는 `earnedGrantIds`가 없다. 다음만 저장한다.

- `schemaVersion`, `manifestVersion`, `cutoverVersion`
- `seenRevealIds`
- 외관 `activeLoadout`과 slot별 LWW clock
- `careState`

이번 세션에서 top-level/state/care/loadout/clock JSON에 strict exact-key 검사를 추가했다.
같은 schema에 권한 필드를 몰래 추가하면 fail closed한다. 알 수 없는 미래 reveal ID와
미래 slot key 자체는 sync 보존을 위해 허용한다.

### 3.2 State persistence and sync

신규 `lib/services/hanok_state_service.dart`:

- strict JSON decode
- decode 256KB 상한
- generation fence
- deterministic cloud merge
- `beforeRead`/`beforeWrite` session test hooks

수정 `lib/services/storage_service.dart`:

- `kl_hanok_state_v1`
- `kl_hanok_cutover_v2`
- strict raw getter/setter
- legacy reveal ledger만 제거하는 `clearLegacyHanokPresentationState()`

수정 `lib/services/cloud_sync.dart`:

- root restorable field `hanok_state_json`
- schema-valid local Hanok만 backup
- invalid local state로 valid remote를 덮지 않음
- restore 시 typed merge

수정 `lib/services/account/account_reconciliation.dart`:

- typed `HanokState? hanokState`
- `localHanokGeneration`
- generic root-field merge가 `hanok_state_json`을 만지지 못함
- local/cloud typed merge 및 session/generation-fenced write

수정 `functions/gye/cloud_backup_deletion_runtime.js` 및 test:

- 계정 cloud 삭제 whitelist에 `hanok_state_json` 포함
- Gye 자체 진행과 개인 한옥 권한은 연결하지 않음

이번 세션에서 빈 문자열 generation도 “저장값이 없던 정확한 세대”로 전달하도록
cutover/cloud/account caller를 수정했다. `null`은 fence 생략이고 `''`는 absent 상태 CAS다.

### 3.3 Catalog and projection

현재 신규 파일:

- `tools/content_factory/build_hanok_grants.py`
- `tools/content_factory/drafts/hanok_grants.json` — 미승인·비런타임 설계 fixture
- `tools/content_factory/release_ledgers/hanok_grants_v1.json` — 승인된 row만 append
- `lib/services/hanok_grant_catalog.dart`
- `lib/services/hanok_experience_projector.dart`
- `lib/services/hanok_cutover_service.dart`

현재 grant generator는 published additive denominator slot 86개에 각각 한 reward를 만든다.
A1 stable ID 16개는 다음과 같다.

1. `hanok_a1_01_site_setout`
2. `hanok_a1_02_plan_layout`
3. `hanok_a1_03_foundation_gidan`
4. `hanok_a1_04_cornerstones_choseok`
5. `hanok_a1_05_timber_preparation`
6. `hanok_a1_06_columns`
7. `hanok_a1_07_beams_changbang`
8. `hanok_a1_08_purlins_sangnyang`
9. `hanok_a1_09_rafters_roof_frame`
10. `hanok_a1_10_roof_base`
11. `hanok_a1_11_choga_roof` (2026-08-17 D1 rename → `hanok_a1_11_giwa_roof`)
12. `hanok_a1_12_wall_frame_sujang`
13. `hanok_a1_13_earth_walls`
14. `hanok_a1_14_ondol_maru`
15. `hanok_a1_15_changho_finish`
16. `hanok_a1_16_landscape_move_in`

`HanokExperienceProjector` 현재 동작:

- canonical `verifiedCanDoSegmentIds` 사용
- CourseUnit completion은 reassessment eligibility만 생성
- replacement successor proof가 기존 slot을 만족
- earned grant/track progress/next grant/design options/venues/care tier 계산
- room-v3를 active/dormant로 비파괴 partition
- exact evidence 기반 영수증 생성, raw answer 없음

`HanokCutoverService` 현재 동작:

1. CourseMastery에서 projection 재계산
2. 이미 획득한 reveal을 baseline seen으로 기록해 과거 애니메이션 폭주 방지
3. canonical state 저장
4. legacy reveal ledger만 제거
5. marker를 마지막에 저장
6. 중단 시 재실행 가능

## 4. 현재 변경 파일

tracked modifications:

- `.github/workflows/ci.yml`
- `AGENTS.md`
- `docs/SESSION_LOG.md`
- `docs/plans/2026-08-16-living-hanok-v1-execution.md`
- `functions/gye/cloud_backup_deletion_runtime.js`
- `functions/gye/cloud_backup_deletion_runtime.test.js`
- `lib/services/account/account_reconciliation.dart`
- `lib/services/cloud_sync.dart`
- `lib/services/storage_service.dart`
- `tools/content_factory/build_productive_assessments.py`
- `tools/content_factory/drafts/productive_assessments.json`

untracked/new:

- `tools/content_factory/drafts/hanok_grants.json`
- `tools/content_factory/release_ledgers/hanok_grants_v1.json`
- `test/support/hanok_grant_fixture.dart`
- `lib/models/hanok_growth.dart`
- `lib/services/hanok_cutover_service.dart`
- `lib/services/hanok_experience_projector.dart`
- `lib/services/hanok_grant_catalog.dart`
- `lib/services/hanok_state_service.dart`
- `test/hanok_account_reconciliation_test.dart`
- `test/hanok_cloud_sync_test.dart`
- `test/hanok_cutover_service_test.dart`
- `test/hanok_experience_projector_test.dart`
- `test/hanok_grant_catalog_test.dart`
- `test/hanok_state_service_test.dart`
- `test/hanok_v1_source_guard_test.dart`
- `tools/content_factory/build_hanok_grants.py`
- `tools/content_factory/test_build_hanok_grants.py`
- 이 인수인계 문서

## 5. 이미 통과한 검증

최신 base `82afdcde`에서 실행했다.

### 5.1 집중 Flutter 회귀

```powershell
flutter test --no-pub `
  test/hanok_state_service_test.dart `
  test/hanok_grant_catalog_test.dart `
  test/hanok_experience_projector_test.dart `
  test/hanok_cutover_service_test.dart `
  test/hanok_cloud_sync_test.dart `
  test/hanok_account_reconciliation_test.dart `
  test/hanok_v1_source_guard_test.dart `
  test/cloud_sync_test.dart `
  test/services/account/account_reconciliation_test.dart `
  --reporter compact
```

최신 결과: **146/146 PASS**

### 5.2 전체 Flutter 회귀

```powershell
flutter test --no-pub --reporter compact
```

최신 결과: **3,749 PASS, 14 intentional skip, 실패 0**

### 5.3 정적 분석

```powershell
flutter analyze --no-pub --fatal-infos
```

최신 결과: **No issues found**, 최종 재실행 59.5초

### 5.4 Python/Node

```powershell
python -m unittest tools.content_factory.test_build_hanok_grants
python tools/content_factory/build_hanok_grants.py --check --verify-git-history --base-revision HEAD
python tools/content_factory/build_productive_assessments.py --check
node --test functions/gye/cloud_backup_deletion_runtime.test.js
```

결과:

- grant generator **9/9 PASS**
- Git baseline ledger check와 productive generator check PASS
- `.github/scripts` CI 계약 **17/17 PASS**
- cloud backup deletion **18/18 PASS**

이 결과는 아래 P1 수정 **이후** 결과다. Python/CI 보강 뒤 해당 계약을 다시 실행했고,
마지막 Dart 동시성 수정 뒤 전체 Flutter와 analyze도 다시 통과했다.

### 5.5 Web 및 독립 재감사

- `flutter build web --release --no-pub`: PASS. 외부 `flutter_tts 4.2.5`의 기존
  Wasm dry-run 경고 3건만 존재한다.
- 최종 Spec 리뷰: P0/P1 0
- 최종 Standards 리뷰: P0/P1 0
- 최종 Hanok 집중 회귀: 35/35 PASS

## 6. 2축 리뷰 P1과 적용한 해결책

두 개의 독립 read-only 리뷰(`pr3_standards_review`, `pr3_spec_review`)가 확인했다.

### P1-1. 동일 clock의 LWW merge가 교환법칙을 깨뜨림 — 해결

현재 같은 `(counter, actorId)`인데 grant/settings 값이 다르면 왼쪽 값을 선택한다.
따라서 `merge(A,B) != merge(B,A)`가 가능하다.

수정 설계:

- loadout winner total order를 `(clock.counter, clock.actorId, grantId)`로 만든다.
- care settings winner total order를 `(settingsClock, canonical settings value key)`로 만든다.
- settings value key는 vacation/display/notifications bool을 고정 순서로 직렬화한다.
- `merge(A,B) == merge(B,A)`, associativity, idempotence 테스트를 추가한다.
- 같은 clock·다른 payload를 조용히 local 우선으로 두지 않는다.

### P1-2. Hanok save의 앱 전역 직렬화가 없음 — 해결

같은 absent generation 또는 같은 raw generation을 읽은 두 save가 모두 검사 후 비동기
write에 들어가면 마지막 write가 첫 reveal/loadout을 덮을 수 있다. 서비스가 여러 곳에서
`const HanokStateService()`로 생성되므로 instance queue만으로 부족하다.

수정 설계:

- `HanokStateService`에 process-wide static mutation tail을 둔다.
- 모든 save를 static queue로 직렬화하고 rejection이 queue를 poison하지 않게 한다.
- queued second write가 첫 write 뒤 generation mismatch로 실패하는 테스트를 추가한다.
- cloud/account/cutover caller가 계속 captured raw generation을 전달하게 한다.
- merge read-modify-write도 같은 직렬 경계 안에서 수행하거나, read 후 queued CAS 실패를
  명시적으로 caller retry로 처리한다. 조용한 overwrite는 금지한다.

### P1-3. 256KB 초과 상태를 저장해 놓고 다시 읽지 못할 수 있음 — 해결

현재 decode만 256KB를 검사하고 save는 검사하지 않는다. reveal union이 커지면 저장 성공
직후 load가 실패할 수 있다.

수정 설계:

- save에서 `jsonEncode`를 정확히 한 번 수행한다.
- UTF-8 byte length를 동일한 256KB 상한으로 검사한 뒤에만 strict write한다.
- local+remote merge 결과가 상한을 넘으면 기존 local을 보존하고 fail closed하는 테스트를
  추가한다.
- 크기를 맞추려고 알 수 없는 미래 ID를 임의 삭제하지 않는다.

### P1-4. A1 out-of-order proof가 변화 0회/다단계 점프를 만들 수 있음 — 해결

현재 A1 stage는 verified grant의 연속 prefix만 센다. A1-16 proof가 먼저 있으면 변화가
없고 A1-15가 나중에 들어왔을 때 여러 단계가 동시에 열릴 수 있다.

수정 설계:

- PR2 draft productive generator에서 A1 assessment 2–16에 직전 A1 assessment를 exact
  prerequisite로 넣는다. 이 copy/평가는 아직 미승인·비노출이므로 migration 대상 사용자가 없다.
- A1 grant 2–16에도 직전 grant ID를 `prerequisiteGrantIds`로 넣는다.
- projector는 해당 grant의 prerequisite가 이미 earned일 때만 grant를 추가한다.
- out-of-order forged/remote proof는 canonical trust chain을 통과하지 못해야 한다.
- 테스트: A1-16 단독 evidence 0 grant, 1→2 순차 evidence는 호출당 한 state, all 16은 16.
- 정상 경로에서 영수증 한 번에 A1 construction grant가 둘 이상 나오면 fail closed한다.

### P1-5. 미래 A1 extension이 tuple index로 crash — 해결

현재 `_grant_id`와 `_reveal_asset_ids`가 모든 A1 order를 16칸 tuple에 색인한다.
A1 order 17 extension은 `IndexError`다.

수정 설계:

- A1 1–16 core construction만 exact authored mapping을 쓴다.
- 미래 extension은 자동 construction stage를 만들지 않는다.
- 더 근본적으로 order/switch 추론을 제거하고, 86개 provisional reward plan을 명시적인
  draft manifest로 둔다.
- 새 additive segment는 authored grant row가 없으면 generator가 fail closed한다.
- 미래 extension fixture를 넣어 “명시 row 없이는 실패, 명시 row가 있으면 generic additive
  grant로 성공”을 테스트한다.

### P1-6. append-only guard가 실제 CI baseline에 연결되지 않음 — 해결

`HanokGrantCatalog.validateEvolutionFrom()`은 있으나 현재 파일을 자기 자신과만 비교하는
테스트여서 generator가 과거 ID를 바꾸고 재생성해도 CI가 통과한다.

수정 설계:

- published release ledger를 별도 파일로 둔다. 권장 경로:
  `tools/content_factory/release_ledgers/hanok_grants_v1.json`
- 현재 assessment/content는 미승인이므로 ledger의 published grants는 빈 목록이어야 한다.
- 승인 PR에서만 reviewed draft rows를 ledger에 append한다.
- generator `--check`는 ledger의 모든 기존 row가 현재 candidate에 byte-semantic 동일하게
  존재하는지 검사한다.
- 삭제/rename/segment 변경/reveal 변경/kind·slot·provenance 변경을 모두 실패시킨다.
- 새 row append는 허용한다.
- synthetic previous-ledger mutation 테스트로 실제 guard가 호출됨을 증명한다.

### P1-7. 승인 전 영구 ID를 Flutter asset으로 ship하면 ADR 위반 — 해결

ADR-003은 assessment와 learner content 승인 전 grant ID를 만들지 않는다고 정했다.
초기 구현은 `assets/data/hanok_grants.json`에 86개 미승인 ID를 두려 했으나, 수정 후
해당 runtime asset은 존재하지 않는다.

수정 설계:

- `assets/data/hanok_grants.json`을 커밋하지 않는다.
- provisional catalog를 `tools/content_factory/drafts/hanok_grants.json`으로 이동한다.
- production `HanokGrantCatalog.load()`/`rootBundle` 자동 loader를 제거한다.
- `HanokGrantCatalog.fromJson()`은 strict decoder로 유지한다.
- 테스트 전용 helper가 filesystem의 draft를 명시적으로 읽어 주입한다.
- source guard에 `assets/data/hanok_grants.json` 부재와 production auto-loader 부재를 고정한다.
- 실제 콘텐츠 승인 PR에서만 release ledger append + approved runtime asset + production loader를
  같은 원자적 변경으로 추가한다.

### P1-8. 돌봄 알림 ID가 다음 학습 주기에 재무장되지 않음 — 해결

현재 `notifiedTierIds`가 영구 union이다. 새 학습으로 care timestamp가 갱신돼도 과거 7일/
14일 notification ID가 남아 다음 주기에 알림을 다시 예약하지 못한다.

수정 설계:

- notified IDs를 `lastEligibleActivityAt`가 나타내는 care cycle에 귀속한다.
- copyWith로 더 최신 eligible activity를 기록할 때 caller가 별도 값을 주지 않으면 notified
  set을 비운다.
- merge는 가장 최신 activity cycle의 notified IDs만 채택한다.
- 양쪽 activity timestamp가 같을 때만 union한다.
- 오래된 offline 기기의 notification IDs가 새 cycle로 부활하지 않는 테스트를 추가한다.
- 알 수 없는 미래 tier ID는 같은 cycle 안에서는 보존한다.

## 7. 권장 수정 순서

1. LWW total order와 care-cycle merge/copyWith 테스트
2. static write serialization + save-size guard 테스트
3. provisional grant catalog를 draft 경로로 이동하고 production loader 제거
4. explicit authored grant plan + empty published release ledger + generator enforcement
5. A1 productive prerequisite chain + grant prerequisite chain + projector guard
6. source guard/fixture imports 갱신
7. focused tests
8. full analyze + full Flutter tests + Python + Node
9. `docs/SESSION_LOG.md` 최상단 기록
10. latest `origin/main` 확인·통합
11. 명시적 staging, commit, push, PR, exact-head CI, merge, cleanup

## 8. 테스트 파일과 추가해야 할 회귀

기존 PR3 tests:

- `test/hanok_state_service_test.dart`
- `test/hanok_grant_catalog_test.dart`
- `test/hanok_experience_projector_test.dart`
- `test/hanok_cutover_service_test.dart`
- `test/hanok_cloud_sync_test.dart`
- `test/hanok_account_reconciliation_test.dart`
- `test/hanok_v1_source_guard_test.dart`
- `tools/content_factory/test_build_hanok_grants.py`

추가 완료된 회귀:

- same-clock/different-grant merge commutative
- same-clock/different-care-settings merge commutative
- three-way merge associative
- two concurrent saves from `''`: first wins, second generation conflict, no lost union
- oversize direct save rejected before write
- oversize cloud merge preserves previous local
- care activity renewal clears notification generation
- stale device notification IDs cannot reappear after newer activity
- A1 out-of-order proof cannot earn later construction
- A1 sequential proof adds exactly one construction state
- future A1 extension does not index 16-state array
- release ledger deletion/rename/mutation fails generator
- runtime assets contain no unapproved Hanok grant catalog

추가로 CI의 changes job이 PR base/push-before SHA에서 이전 release ledger를 읽고 현재
ledger가 정확한 prefix를 보존하는지 검사한다. ledger와 candidate를 같은 PR에서 함께
삭제·수정해도 과거 Git row와 달라지므로 실패한다. A1 extension 테스트는 명시 row가
없을 때 실패하고, authored `ambience` row를 추가했을 때 성공하는 양쪽 경계를 고정한다.

## 9. 최종 검증 명령

먼저 focused:

```powershell
dart format <수정한 Dart 파일들>
python -m unittest tools.content_factory.test_build_hanok_grants
python tools/content_factory/build_hanok_grants.py --check --verify-git-history --base-revision HEAD
python tools/content_factory/build_productive_assessments.py --check
flutter test --no-pub `
  test/hanok_state_service_test.dart `
  test/hanok_grant_catalog_test.dart `
  test/hanok_experience_projector_test.dart `
  test/hanok_cutover_service_test.dart `
  test/hanok_cloud_sync_test.dart `
  test/hanok_account_reconciliation_test.dart `
  test/hanok_v1_source_guard_test.dart `
  test/cloud_sync_test.dart `
  test/services/account/account_reconciliation_test.dart `
  --reporter compact
node --test functions/gye/cloud_backup_deletion_runtime.test.js
```

그 다음 full:

```powershell
flutter analyze --no-pub --fatal-infos
flutter test --no-pub --reporter compact
git diff --check
```

PR 직전 원격 검증:

```powershell
git fetch origin main
git rev-parse HEAD
git rev-parse origin/main
git log --oneline --decorate HEAD..origin/main
git diff --name-only HEAD..origin/main
```

## 10. commit/PR lifecycle

모든 blocker가 닫히고 전체 gate가 green인 뒤에만 수행한다.

1. `docs/SESSION_LOG.md` 최상단에 PR3 범위·권한·검증 수치 기록
2. `git status --short`로 task 파일만 확인
3. explicit path staging; `git add .` 금지
4. `git diff --cached --check`
5. commit 예시: `feat(hanok): add productive mastery state projection`
6. push: `git push -u origin codex/hanok-v1-state-20260816`
7. PR 생성, base `main`
8. PR remote head SHA를 다시 읽음
9. 그 exact SHA의 필수 CI가 green인지 확인
10. main merge
11. merge SHA와 main CI 확인
12. remote branch와 독립 worktree 정리

CI가 branch 최신 SHA가 아닌 과거 SHA에서 green이면 통과로 간주하지 않는다.

## 11. PR3 이후 계획

### PR4 — A1 실제 건축

- 4:3 fixed camera `personal_map_north_up_oblique_v2`, 1536×1152
- empty site + 16 cumulative states
- 승인 전 third-party screenshot/PDF/model input 금지
- A1 06 columns pilot 3안부터 시작
- 각 WebP hard limit 350KB, decoded active memory 32MB 이하
- camera/socket/OCR/matte/thumbnail SHA/reduced-motion tests
- baked UI가 있는 legacy `stage_beams_light.png`는 소비자 전환 후 제거

### PR5 — A2–C2

- A2 design slots와 provenance 안내
- B1/B2 venue·구조·room-v3 dormant 복원
- C1/C2 8 project/32 step UI
- 7일/14일 care overlay, vacation/display off, opt-in local notifications
- 실제 ㅡ/ㄱ/ㄷ/ㅁ 대지 preset은 V1 밖 장기 항목

### PR6 — entrypoints

- Today, learning path, mission preview, receipt, personal Hanok, rooms
- 하나의 `HanokExperienceProjection`만 UI source로 사용
- 승인된 productive assessment만 reassessment route에서 표시
- raw answer/audio/transcript analytics 금지

### PR7 — atomic cutover

- 모든 소비자를 V1으로 한 번에 전환
- legacy stage/ratio/milestone/build narrative/reveal 삭제
- Gye의 개인 Hanok stage 의존 제거, Gye 데이터와 static art 보존
- 임시 feature gate도 제거해 두 progression system을 남기지 않음

### PR8 — 최종 QA

- 390/600/1024px, text 200%, screen reader, high contrast, reduced motion
- offline completion/reconnect, clock skew, timezone notification, unknown future ID
- web release, rules/emulator, full tests/analyze
- 실기기 QA와 exact main SHA CI
- acceptance 10/10일 때만 전체 goal complete

## 12. 하지 말아야 할 것

- 현재 3,736 PASS만 근거로 blocker를 무시하고 commit하지 않는다.
- 미승인 86 prompt/grant catalog를 Flutter runtime asset으로 ship하지 않는다.
- 기존 집/단어팩/XP/Gye를 새 보상 권한으로 import하지 않는다.
- room-v3 배치나 장식을 삭제하지 않는다.
- 첨부 한옥 screenshot, Vivasam, PDF를 앱 번들 또는 이미지 모델 입력으로 쓰지 않는다.
- PR3에서 BBANANA/Seedance 크레딧을 쓰지 않는다.
- production Firebase 배포나 App Store 업로드를 이 PR의 성공으로 주장하지 않는다.
- shared checkout의 unrelated WIP를 stage/commit하지 않는다.

이 문서는 다음 세션이 대화 요약 없이도 바로 PR3를 이어갈 수 있게 작성한 실행 정본이다.
