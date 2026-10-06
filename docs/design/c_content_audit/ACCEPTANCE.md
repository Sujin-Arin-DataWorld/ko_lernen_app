# C 수용조건과 검증 경계

이 문서는 ID/해시/경로 감사의 결과와 아직 요구되는 UI 수용조건을 구분합니다.

라이브48유닛/30phase/902task, Lernen13+Spiele8, Small Talk209/듣기186과 authoring/history 확장 원장을 구분합니다.

소스 검사 결과: **source_integrity_passed_with_declared_gaps**. 검사항목 14,948개; hard error 0개; 명시된 gap 556개.

## 실행 증거가 있는 subset

각 열은 독립적인 검증 층입니다. 테스트 통과와 실제 렌더 관찰, 원본 에셋 승인, 최종 화면 인간 승인을 서로 대체하지 않습니다. 개별 로그/캡처 경로·범위는 JSON의 module validation 원문에 있습니다.

| module | 소스 관찰 | 자동검사 | 렌더 증거 | 인간 승인 |
|---|---|---|---|---|
| foundation | 소스/hash 연결, C refs 3 | passed_for_named_scope | observed_for_named_scope | pending |
| course | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| talsunbi_context | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| games | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| onboarding | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| hanok | 소스/hash 연결, C refs 1 | passed_for_named_scope | observed_for_named_scope | pending |
| rewards | 소스/hash 연결, C refs 1 | passed_for_named_scope | observed_for_named_scope | pending |
| gye | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| support | 소스/hash 연결, C refs 0 | passed_for_named_scope | observed_for_named_scope | pending |
| c_roots | 소스/hash 연결, C refs 3 | passed_for_named_scope | observed_for_named_scope | pending |

## 남은 범위와 승인 경계

| 범위 | 남은 조건 |
|---|---|
| foundation | Physical Android/iOS verification not run: no connected Android device; Windows host.; 12 starter tasks do not imply full Hangul mastery. |
| course | Physical Android/iOS verification not run: no connected Android device; Windows host.; Productive authoring stays behind existing runtimeContentApproved=false gate. |
| talsunbi_context | Physical Android/iOS verification not run: no connected Android device; Windows host. |
| games | Physical Android/iOS verification not run: no connected Android device; Windows host.; Physical contact, timer/background and input QA remain. |
| onboarding | Physical Android/iOS verification not run: no connected Android device; Windows host.; Flattened German lettering has no transparent language/text layer; full EN and200% image-letter adaptation is not claimed. |
| hanok | Physical Android/iOS verification not run: no connected Android device; Windows host. |
| rewards | Physical Android/iOS verification not run: no connected Android device; Windows host.; Physical haptics/interruption QA remain; original canonical opening has no invented SFX. |
| gye | Physical Android/iOS verification not run: no connected Android device; Windows host.; Live authenticated backend group validation not performed. |
| support | Physical Android/iOS verification not run: no connected Android device; Windows host.; Live account services and final secondary-popup visual review remain separate. |
| c_roots | Physical Android/iOS verification not run: no connected Android device; Windows host. |
| Intro baked DE | 승인 원화의 독일어 baked 영역은 native EN/200% 대응으로 바뀌지 않음. 원본 bytes를 보존하고 별도 해결. |
| 실기기 | physical Android devices0 보고. Android/iOS 실기기 QA 미실행; web 캡처와 Flutter 테스트로 대체하지 않음. |
| 인간 승인 | 기존 C 스타일/원본 에셋 승인은 현재 모든 runtime 화면의 최종 인간 승인과 별개. |
| Foundation 범위 | 12 starter 과제는 전체 자모·받침·문장 해독 평가가 아님. 부족 범위와 기존 학습 경로 유지. |
| canonical lineage | lost_phone/bank_account authority의 현재 대상 누락과 과거 기록 migration 결정 대기. |
| productive catalog | per-ID review 미완료, runtimeContentApproved=false. 구조 검사를 학습 평가 승인으로 바꾸지 않음. |

## 전체 수용조건

위 검증 subset이 모든 조건 충족을 뜻하지 않습니다. 소스 감사 완료와 아직 남은 UI/기기/승인 조건을 구분합니다.

체크박스는 최종 수용 여부입니다. 미체크를 미구현 또는 자동검사 미실행으로 해석하지 않습니다. 구현·자동검사·로컬 렌더의 완료 범위는 위 module별 실행 증거와 영수증의 실제 로그를 따르며, 기기 검수와 최종 인간 승인까지 충족했을 때 최종 체크합니다.

- [x] 모든 조사 대상 표·소스 파일의 SHA-256, 개별 ID/행·revision·record hash를 원장에 기록.
- [x] native Small Talk/듣기의 실제 lesson -> source ID -> question binding 검사.
- [x] phase/task/hash/prerequisite/objective binding 및 코스의 개별 checkpoint/graph link 검사.
- [x] 모든 조사 대상 에셋 파일과 rejected/pending/legacy/외부 자료의 상태·해시 보존.
- [ ] 실제 UI에서 현재 runtime 학습 기록이 loader/filter/typed args로 선택·재생·평가·저장·복귀됨을 확인. authoring/archive 행은 라이브 UI에 승격하지 않음.
- [ ] 자유연습과 scoped assessment를 분리하고 레벨/이전 기록/계정 전환으로 잘못된 evidence를 만들지 않음.
- [ ] 한글 미독해 신규 사용자의 입문 진행·재개·읽기 준비도를 방문 이력과 분리하여 확인.
- [ ] production 새 일일 카드10개가 입문을 숨기지 않음. dueCount=new+review 공개 계약을 보존하고 실제 예약 복습 수만 입문 admission 판단에 사용.
- [ ] Foundation12 starter 과제 완료를 전체 한글 문해력 인증으로 표시하지 않음. 쌍자음·복합모음·받침·문장 독해 등 부족 범위와 기존 Hangul/발음/오늘의 글자 경로를 구분.
- [ ] 86 canonical segment/118 productive definition/8project/32snippet/16bundle는 draft/runtime gate 상태를 표시. source 구조 검사를 콘텐츠 승인이나 실행 가능한 평가/XP로 바꾸지 않음.
- [ ] 첫 실행7페이지는 기존 draft/final journal·이전/재개·오류 재시도 유지. 소개 예시는 실제 경제/학습을 지급하지 않음.
- [ ] exact intro baked German 글자 영역은 native EN/200% 대응 완료로 주장하지 않음. 기존 승인 bytes를 보존하고 제한을 별도 해결.
- [ ] TalSunbi 6포즈는 상황→관계/의도→표현→효과→후속문장→실제 저장/사랑방. 209레슨을 가리지 않음.
- [ ] Silben은 실제 음절 크로스워드, 같은 카드의 도깨비/격자, 힌트3단계, 사용자 직접 타일 배치. 실제 접촉에만100+150+900ms 파랑1→3dp.
- [ ] 소개의 큰 고정 액자16불꽃/기존영상은 게임 테두리 효과와 구분. media fail/hidden/reduced motion은 정적 폴백.
- [ ] 상자 개봉→단일 아이템 확대→설명·저장 XP·CTA→문화 이야기. 3후보/이중 개봉 없음; busy/error/retry/skip/account lifetime/중복 claim 검사.
- [ ] C 녹청·한지·원목·황동, Paperlogy UI/Noto Sans KR 학습, 이미지 nav5개와 승인 원화/비율/접지 유지.
- [ ] 320/390dp·100/130/200%·DE/EN·OS safe area·48dp target·스크린리더/키보드·reduced motion·Android/iOS 기기 QA.
- [ ] 실제 잔액·가격·소유권·그룹/서버 등불·저장 팩만 사용. loading/error 상태를 샘플 숫자로 대체하지 않음.
- [ ] A→B 계정 변경 시 active/hidden 탭의 오래된 데이터 무효화. done&&!error 전에는 현재 데이터 표시/보상 CTA를 허용하지 않음. pending/error에서 이전 계정 값이 남지 않는 실제 회귀 검사.
- [ ] opened-but-unacknowledged 보상은 unopened count와 분리한 실제 receipt로 Today/Hanok에서 재개. 같은 아이템·동일 claim·추가 XP 없음.
- [ ] Smalltalk 제목은 스크린리더에 한 번만 발표하고 typed route·저장·XP 계약 유지.
- [ ] 승인 이미지/정적 시제품/소스 연결/로컬 자동검사/정확한 SHA CI/실기기/배포/최종 인간 승인 구분.

## 병렬 소유 세션의 실행 검사

아래 실행 receipt의 suite별 결과·로그와 소유 세션 보고를 그대로 구분합니다. 서로 겹칠 수 있는 묶음이므로 합산 총검사 수를 만들지 않으며, 이전 수치가 최종 실행 결과를 덮어쓰지 않습니다.

최종 실행 receipt가 있으면 JSON 원장의 execution_evidence에 원문·파일 해시를 보존합니다. 생성기는 Flutter 검사/실행/build/렌더/기기 QA를 재실행하지 않으며 source fidelity를 시각 승인으로 바꾸지 않습니다.

최종 execution evidence:

```json
{
  "source_id": "handoff:current-C-verification-status",
  "source_sha256": "5804aaf4659a4435d3c7bedfef204c05391670cbd2629aaf3c07c2b132e23618",
  "independently_executed_by_generator": false,
  "receipt": {
    "schema_version": 2,
    "status": "local_implementation_and_named_automated_checks_complete",
    "date": "2026-10-05",
    "workspace": "C:/dev/hangulsori/ko_lernen_app_worktrees/canonical-reward-onboarding-20261004",
    "head": "a1d798bda6a36ff4dd95faa16e14484ad7b1a2f5",
    "source_state": "HEAD plus preserved concurrent C WIP; source snapshot records current bytes, not a commit or exact-SHA CI result.",
    "source_hash_receipt": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/current-source-hashes.json",
    "source_files": 1842,
    "count_policy": "Suite scopes overlap. Do not sum these runner counts as independent tests, visual approval, device QA or CI.",
    "suites": [
      {
        "suite": "Foundation, approved fixed-frame introduction, clip and strict receipt projection",
        "status": "passed",
        "tests": 96,
        "log": "C:/dev/hangulsori/_codex_artifacts/foundation-20261005/final_foundation_receipt_regression_96.log",
        "log_sha256": "2c34dbb29aed5722ef47b2a01a1500c42142d9c30b4183c4ca4a10cae9e3c29e"
      },
      {
        "suite": "Learning entry, content, Silben, Heute admission and keyboard",
        "status": "passed",
        "tests": 113,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/content-game-flow-frozen-tests.log",
        "log_sha256": "d4f07d8527982694b3b86e1827c75f7ee5cfa575477e00452543388dcae99636"
      },
      {
        "suite": "Individual game controls and results",
        "status": "passed",
        "tests": 336,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/games-mechanics-final-tests.log",
        "log_sha256": "871901adafa5fd8299dd6bb65d57621ff1b886c90ae9c0ff592b6471a39d3763"
      },
      {
        "suite": "Course and learning path",
        "status": "passed",
        "tests": 89,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/cross-course-learning-path-final-tests.log",
        "log_sha256": "30d3036030927dec7d4b3e2e99bb9ac5608b2da7c00efd807aff1d179c7a64ea"
      },
      {
        "suite": "TalSunbi revision history and Sarangbang",
        "status": "passed",
        "tests": 16,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/scholar-history-final-tests.log",
        "log_sha256": "b16ae2d6730b6089413c1a1a21bfe0aebd680004c37983a0c7a6d852caa516b5"
      },
      {
        "suite": "Smalltalk accessibility, typed launch and history",
        "status": "passed",
        "tests": 23,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/smalltalk-accessibility-history-final-tests.log",
        "log_sha256": "c471bf9122bbaa34391f3850b4caa7759ed85788aa6a05126302bcf86b22f916"
      },
      {
        "suite": "Reward, pack, account, cloud, reset and recovery",
        "status": "passed",
        "tests": 272,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/reward-pack-account-cloud-frozen-tests.log",
        "log_sha256": "5e4f1254e9714da220bc1192ab9c6517283dfd0cad7eec0c5a4608bcdda45f0c"
      },
      {
        "suite": "Reward UI, runtime, startup and reveal",
        "status": "passed",
        "tests": 30,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/reward-ui-runtime-frozen-tests.log",
        "log_sha256": "0287287253cd5d240a981f037f715275c0fa953837dc24ca18fa2ef0f901c04e"
      },
      {
        "suite": "Latest C surfaces, native eight-game launch, wallet, guide, culture and Dancheong",
        "status": "passed",
        "tests": 236,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/c-surfaces-final-tests.log",
        "log_sha256": "258f0e3404dfa272beee5d69c7255b3fc035929d216c720c8bd27e901ffac65d"
      },
      {
        "suite": "Einleitung seven source test files, independently rerun serially",
        "status": "passed",
        "tests": 93,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/c-einleitung-frozen-179-tests.log",
        "log_sha256": "36ebfd590c310930223c8e3532d9106a1f8c79ce4cc3a00479b3ebf71d8223ad"
      },
      {
        "suite": "Real five-tab parent, DE and EN render captures",
        "status": "passed",
        "tests": 10,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/c-content-shell-render-evidence.log",
        "log_sha256": "e8cdd259d24893fdde0b641bd0048e30765eeeedcf569d17ec71fa4e62a2a7bb"
      },
      {
        "suite": "Real single decoration receipt DE and EN render",
        "status": "passed",
        "tests": 2,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/reward-receipt-render-frozen-evidence.log",
        "log_sha256": "cde94c13582111849f3a6fdf01da71c545adc411bc48b54bf164ee6941a318e9"
      },
      {
        "suite": "Settings and focus",
        "status": "passed",
        "tests": 5,
        "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/cross-settings-support-final-tests.log",
        "log_sha256": "cc7583429f5a8ee69c1c70ee63e25df16e2747285d48f256c123eb615073d50e"
      }
    ],
    "build": {
      "status": "passed",
      "target": "tool/c_content_flow_preview.dart",
      "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/real-route-web-build-final-c-surfaces.log",
      "log_sha256": "ebecb090905d07b6c5f473bb6770d36be5458179371cc1ef66b246ad030ce5a1",
      "main_js_sha256": "79102fa1bce028fdbb83a8f014e0453a5e28723570ed2ac104618f627707c4a2",
      "preview": "http://127.0.0.1:8261/",
      "original_and_actual_comparison": "http://127.0.0.1:8253/c-live.html",
      "boundary": "Local development origin; production routes/loaders, actual empty placement when no history exists, no Firebase initialization or upload."
    },
    "analysis": {
      "status": "passed",
      "errors": 0,
      "warnings": 0,
      "baseline_infos": 2,
      "log": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/validation/full-analyze-frozen.log"
    },
    "rendered_visual": {
      "status": "named_scope_verified",
      "parent_captures": [
        {
          "tab": "today",
          "locale": "de",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-today-de-390x844.png",
          "png_sha256": "24444a6a891f7d6f7623cc2090db6ccdc925de3ceb17affbf88da6dcad067064",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-today-de-390x844.json",
          "provenance_sha256": "6dc500c11ff49b025e54a0cffc228a3ca5cbcc4c9058c9f4e666a1407ca73b60"
        },
        {
          "tab": "learn",
          "locale": "de",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-learn-de-390x844.png",
          "png_sha256": "49abe2e9f7fd289d1f25a43d213cd5b4facbe2a5e15055a083220234b18134c0",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-learn-de-390x844.json",
          "provenance_sha256": "a58ecba22d9779bd4e2f6260669a86626895808d7e732e2c022fc13f9b45d1eb"
        },
        {
          "tab": "games",
          "locale": "de",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-games-de-390x844.png",
          "png_sha256": "12b1e46d5b2cf959281aa0581f6ee1451e5af76d83b403df772f2f33faefa4ac",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-games-de-390x844.json",
          "provenance_sha256": "025547b1f71ae03756b6d6d95d8d132aadc9318dc5fa622b8b76579d8d223fb8"
        },
        {
          "tab": "hanok",
          "locale": "de",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-hanok-de-390x844.png",
          "png_sha256": "8a7b04131c2f696d07fb72664bd32e1732cd2c61c202bbba0bdc09aae94f475c",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-hanok-de-390x844.json",
          "provenance_sha256": "1fc6b0a9d47917619085971ab7cdff55ff44167ae74188f0960a7dd1a81bdfd7"
        },
        {
          "tab": "gye",
          "locale": "de",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-gye-de-390x844.png",
          "png_sha256": "0e7aa841c9e525b199a871d1865534bbfda9b082dc41d45d0f89519e8d6fd731",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-gye-de-390x844.json",
          "provenance_sha256": "70f47aa134aa7209a179df8c8f581f99cdce32449cbec2257a2fead17a6ef9d3"
        },
        {
          "tab": "today",
          "locale": "en",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-today-en-390x844.png",
          "png_sha256": "fa0c0677d1fea1bb410837fa068d67c8ad1242b8a9da703282234bb350380732",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-today-en-390x844.json",
          "provenance_sha256": "007fe16cddc18c0618d1ce86f972697597811cca811b3410760bfa24744f5ce0"
        },
        {
          "tab": "learn",
          "locale": "en",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-learn-en-390x844.png",
          "png_sha256": "facb3130bb90fc9834ca87d8d6c5dfb838f677268d5c692e686cacef1927df7d",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-learn-en-390x844.json",
          "provenance_sha256": "064e0071e1caa6d6b3448153375af169dac409bd6d1d9ede03d408f8da1e9dce"
        },
        {
          "tab": "games",
          "locale": "en",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-games-en-390x844.png",
          "png_sha256": "d4c45b8ba812f22a862da63cfb09f460d4fcd19ae21e66f9458a4ff8a2359d01",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-games-en-390x844.json",
          "provenance_sha256": "0b60f8fa00ebd45f9a20eab0698e2035524e30df773fc37870bc7432adc118b7"
        },
        {
          "tab": "hanok",
          "locale": "en",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-hanok-en-390x844.png",
          "png_sha256": "35901286816db44032ff86e17f19a1b8f3855b4cce0ae4cc6833c5babd9c3c10",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-hanok-en-390x844.json",
          "provenance_sha256": "5a8c7f3a58ba525b4cc912a9daf06fc0c2f6667a91d424a78c6fd0f961eb8930"
        },
        {
          "tab": "gye",
          "locale": "en",
          "png": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-gye-en-390x844.png",
          "png_sha256": "b9a93378a6f439c5c12c8d758250063650033de012b8c94da6f4041d607305d7",
          "provenance": "C:/dev/hangulsori/_codex_artifacts/c-implementation-20261005/visual-shell/c-content-shell-gye-en-390x844.json",
          "provenance_sha256": "349e6c536e3d91e0d46507877bc3744ee5e3df4a519950e5ebcb12e8f001dba5"
        }
      ],
      "final_interactive_captures": [
        {
          "path": "C:/dev/hangulsori/_codex_artifacts/einleitung-reward-abc-20261004/assets/c-live-heute-hanok-en-200-final.png",
          "sha256": "ff416a5b7f07bf2d928c9e61cddafe8159e7e0b3e59f0031de318c7a6a977d49",
          "scope": "Final native Today EN390x844 at200%: complete construction word, unchanged image/route/value.",
          "method": "C owner and root actual IAB review; final human approval not inferred"
        },
        {
          "path": "C:/dev/hangulsori/_codex_artifacts/einleitung-reward-abc-20261004/assets/c-live-game-details-final-390.png",
          "sha256": "7fa21417df4a73611bd60e9c88310f4485ebb5f122a7f9bc5e1d760373d57d31",
          "scope": "Final native C game detail390; original artwork and guarded Start.",
          "method": "C owner and root actual IAB review; final human approval not inferred"
        },
        {
          "path": "C:/dev/hangulsori/_codex_artifacts/einleitung-reward-abc-20261004/assets/c-live-game-start-final-390.png",
          "sha256": "f704db10bbf4400a3c4bac53fe1d54b55bfbe9409bc9cf1bd89802097ec5f2f6",
          "scope": "Final native /wordle launch and return without completion; no claim of every game interior matching original board pixels.",
          "method": "C owner and root actual IAB review; final human approval not inferred"
        }
      ],
      "foundation_directory": "C:/dev/hangulsori/_codex_artifacts/foundation-20261005/screenshots",
      "introduction_directory": "C:/dev/hangulsori/_codex_artifacts/foundation-20261005/dokkaebi-intro",
      "reward_files": [
        "docs/screenshots/sori-bojagi-receipt-de-390.png",
        "docs/screenshots/sori-bojagi-receipt-en-390.png"
      ],
      "boundary": "Real rendered widgets and original asset bytes, not final user approval or physical-device proof."
    },
    "device": {
      "status": "not_run_no_connected_device",
      "connected_android_devices": 0,
      "inventory_log": "validation/android-connected-devices.log",
      "ios": "not_run_on_Windows"
    },
    "final_user_approval": "pending",
    "external_connectors_and_generation": {
      "design_connector_calls": 0,
      "generated_images_or_videos": 0
    },
    "commit_push_merge_deploy": "not_performed; active shared worktree retained",
    "module_validation": {
      "foundation": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "Final 96 group includes Foundation61, intro15, clip12, initial deep-link3 and strict receipt projection5. Content113 also tests actual Today admission, explicit A1 choice and account refresh."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Real fonts: DE/EN Foundation hub390, approved dark introduction390 and actual EN320 at200% native practice launch."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "12 starter tasks do not imply full Hangul mastery."
        ]
      },
      "course": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "89 course/path cases; native scope, assessment, read-only guards, existing graph and typed course launches."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Actual C Lernen entry, 48-unit source graph and existing course destination; no blanket approval of every secondary lesson."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "Productive authoring stays behind existing runtimeContentApproved=false gate."
        ]
      },
      "games": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "336 mechanics/results cases, Content113 Silben/keyboard cases, final C236 includes all eight exact routes/arguments with no award during launch and C details/locks."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Actual C Spiele DE/EN390 and native Silben help1/2/3; no tile insertion by a hint."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "Physical contact, timer/background and input QA remain."
        ]
      },
      "talsunbi_context": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "23 Smalltalk accessibility/history cases and 16 scholar/history cases; legacy invite_friend revision remains separate, typed launch and real room history preserved."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Native 209-lesson/590-phrase main hub and supplemental intent/relation context inspected; approved six poses and muted existing video preserved."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host."
        ]
      },
      "rewards": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "272 reward/pack/account/cloud cases, 30 UI/runtime/startup/reveal cases, strict receipt projection5 within96; native failures, account fencing, duplicate admission and durable replay preserved."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "DE/EN real single-receipt390 PNG, actual same-item reload and culture-popup return, DE844x390 at200% CTA accessibility; no replay award."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "Physical haptics/interruption QA remain; original canonical opening has no invented SFX."
        ]
      },
      "onboarding": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "Current seven actual test files rerun serially:93. Initial-route/consent3 in final96; original46 exact-crop hashes preserved. Historic179 is superseded as a final count."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Seven approved native Einleitung pages and independent preview; existing approvals apply to source artwork, final integration approval remains pending."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "Flattened German lettering has no transparent language/text layer; full EN and200% image-letter adaptation is not claimed."
        ]
      },
      "c_roots": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "C236 and actual-parent10: five image tabs, selected/48dp input semantics, confirmed-state wallet, account remount/late response, C busy/disabled/error/retry, responsive real-font controls and whole localized Hanok progress words at320/390dp200%."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "DE/EN five-tab parent390x844 captures use actual local public services, isolated preferences, pristine wallet bootstrap and optional home/Gye tours marked seen; not a live backend account."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host."
        ]
      },
      "hanok": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "C236 includes protected construction history, real shortcut arguments, wallet40-cost contract, draft ID, whole localized progress words at320/390dp200%, account transitions and no extra reward."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Approved complete Hanok art, Dancheong and actual first/scroll states; architectural history remains separate from presentation art."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host."
        ]
      },
      "gye": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "C236 preserves loading/error-not-unjoined, membership/group IDs, joining/create/solo, age/form and weekly-promise provenance; aggregate account checks included."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Actual signed-out empty Gye and native DE/EN parent390; no fabricated four-member or lantern values."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "Live authenticated backend group validation not performed."
        ]
      },
      "support": {
        "automation": {
          "status": "passed_for_named_scope",
          "scope": "Guide contracts/UI/default+C dispatch, cultural term close, daily-goal midnight read/no-write/retry, Dancheong drafts in C236; settings5 and existing account recovery in272."
        },
        "rendered_visual": {
          "status": "observed_for_named_scope",
          "scope": "Profile/settings/library and recovery entrances retained. Independent spotlight and weekly-statistics popups retain their existing common appearance; no blanket secondary-screen visual approval."
        },
        "human_approval": {
          "status": "pending"
        },
        "remaining": [
          "Physical Android/iOS verification not run: no connected Android device; Windows host.",
          "Live account services and final secondary-popup visual review remain separate."
        ]
      }
    },
    "remaining_acceptance": [
      "Physical Android/iOS verification not run: no connected Android device; Windows host.",
      "Final human design approval is not inferred.",
      "Baked German image text is not declared complete native EN/200% support.",
      "Starter Hangul corpus remains19 consonants,15 vowels,16 syllable examples; gaps are declared, not invented.",
      "Historical lost_phone/bank_account exact bytes and invite_friend revision1 are retained without adding old completion to current revision.",
      "Productive authoring and legacy/internal/held assets remain explicitly classified, not silently enabled or deleted.",
      "Independent spotlight/weekly-statistics common popup appearance is preserved and recorded separately."
    ]
  },
  "boundary": "Owner's reported executions retain distinct source/test/UI/build/visual/device/approval states; generator verifies receipt bytes, not rerun outcomes."
}
```

## 원장에 남아 있는 gap/error

세부 경로·참조 source/line·현재 해시는 content-ledger.json의 validation.issues에서 확인합니다.

| code | 건수 |
|---|---:|
| canonical_authority_without_current_library_record | 2 |
| productive_catalog_authoring_draft_not_runtime | 1 |
| unresolved_asset_literal | 553 |

## 승인 대기인 productive catalog

tools/content_factory/drafts/productive_assessments.json에118 definition,8project,32source snippet,16bundle가 있습니다. ProductiveAssessmentCatalog.runtimeContentApproved=false이고 CanonicalCourseSegmentLoader.load는 승인 catalog 주입 없이는 차단됩니다. draft를 자동으로 Flutter assets에 넣거나 UI 평가 완료/문화·학습 보상으로 부르지 않습니다.

canonical의 project8종 개별 ID:

- `project_c1_accessibility_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c1_evidence_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c1_risk_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c1_sustainability_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c2_framing_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c2_institution_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c2_narrative_v1` — authoring source에 존재; current learner runtime은 닫힘.
- `project_c2_technology_v1` — authoring source에 존재; current learner runtime은 닫힘.

조치: 콘텐츠 담당자가 각 ID의 review ledger와 필요한 TTS/평가·provenance를 검토한 뒤 명시적으로 catalog를 승격/주입해야 합니다. 현재 감사는 원본과 source 구조만 보존하며 승인 gate를 변경하지 않습니다.


## 누락된 canonical 시나리오의 실제 계보

native 듣기186개와 질문/TTS 연결 검사는 현재 corpus의 무결성입니다. 다음 두 canonical authority의 현재 대상 누락을 해결한 증거가 아닙니다.

- `lost_phone`: `37afe400`의 `assets/data/scenarios_a2.json`에 실제 원본 존재; `ca00acad` corpus 승격 후 현재 ID 없음.
  과거 `a2` / `a2_07_travel_repair`. 원본 byte SHA-256 `0458b38ac04edfc0b4c19fb37084f16488c79ee0715689cd515716c134b6f09b`; lineage-records.json에 정확한 UTF-8 record bytes 보존.
  현재 같은 유닛 항목: `jeju_bus_missed`, `taxi_slow_down`, `train_seat_swap`, `a2_byeongcheol_walk_break`. 이 항목들은 ID 대체 계약이 아닙니다.
  현재 선언된 동일 주제 대체/ID alias를 찾지 못했습니다.
  조치: 코스/authority 담당자가 원본 복원, 명시적 lineage migration, authority의 archive 전환 중 하나를 검토해야 합니다. 과거 저장 ID/revision을 보존하며 새 평가·TTS·레벨 검토 없이 alias나 새 콘텐츠를 만들지 않습니다.

- `bank_account`: `37afe400`의 `assets/data/scenarios_b1.json`에 실제 원본 존재; `ca00acad` corpus 승격 후 현재 ID 없음.
  과거 `b1` / `b1_03_work_softening`. 원본 byte SHA-256 `cdd3c94f99d78d086554a2098102f3e98fe920a4a21f13aefe5d522c430642d3`; lineage-records.json에 정확한 UTF-8 record bytes 보존.
  현재 같은 유닛 항목: `shared_document_old_version`, `community_festival_shift`, `company_instagram_wrong_account`, `work_message_too_direct`, `b1_team_briefing_revised_schedule_2026`. 이 항목들은 ID 대체 계약이 아닙니다.
  현재 유사 주제 `a2_w10_money`는 `a2` / `a2_08_home_money`입니다. B1 은행계좌 기록을 A2 증거로 자동 이전할 수 없습니다.
  조치: 코스/authority 담당자가 원본 복원, 명시적 lineage migration, authority의 archive 전환 중 하나를 검토해야 합니다. 과거 저장 ID/revision을 보존하며 새 평가·TTS·레벨 검토 없이 alias나 새 콘텐츠를 만들지 않습니다.


미해결 literal은 삭제하지 않습니다. 과거 handoff/source 스냅샷·동적 경로·개발/legacy 참조를 함께 보존한 결과이며, 실제 runtime 참조 수를 각 항목에 따로 표시합니다.

동시 구현 중 source가 바뀌면 check는 실패합니다. 최종 구현 뒤 build를 다시 실행하고 check로 같은 ID/해시/바인딩이 남는지 확인합니다.
