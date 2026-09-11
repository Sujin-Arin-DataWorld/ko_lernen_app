# Global Launch Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 취소·네트워크·저장 공간 장애가 음성 학습을 방해하는 경로와 공통 로딩 접근성 결손을 고치고, 학습 데이터의 중복 해석·초기화 경합을 줄인다. 개인정보 없는 서버 오류 진단과 정식 출시 조건을 준비한다.

**Architecture:** 기존 TTS generation과 정본/개인 캐시 경계를 유지해 국소 수정한다. AppLoading에서 의미 라벨과 제약 대응을 개선하고, DataLoader·ScenarioLoader에서 진행 중 해석 공유와 초기화 세대 검사를 적용한다. 새 SDK와 새 원격 설정은 추가하지 않는다.

**Tech Stack:** Flutter 3.44 / Dart 3.12, audioplayers, Firebase, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-09-global-launch-readiness-design.md`

## Global Constraints

- 초기 통합 기준 SHA는 `7e844d1b7d751a31f3a666769224da68989523be` (#293 포함), 시작 기준은 `aa0d932f`다. Task 15에서 main `cf1599ee` (#289·#295), Task 17에서 `f2cd1568` (#296), Task 21에서 `8185cca7334348e52edac8464ddac6de49b97b81` (#297)까지 통합해 로컬 검증했다. 이전 웹/Flutter 증거와 현재 통합 검증의 기준을 구분한다. 전용 `global-launch-readiness-20260909` 작업 공간만 수정.
- 커밋/푸시는 Jin이 명시적으로 요청할 때만. 구현자는 커밋하지 않고 diff와 테스트 증거를 남긴다.
- Jin이 앞서 승인한 커밋 범위로 누적 최적화와 main 통합을 로컬에 기록한다. 이후 배포 보류 지시에 따라 푸시·원격 CI·스토어 작업은 보류한다. 커밋 직전 해시 대조와 커밋 후 트리·부모·작업 공간 검증 결과는 외부 `local-commit-20260910/verification.json`이 정본이다. 아래 각 Task의 HEAD·미커밋 표기는 해당 검증 시점의 기록이다.
- 무료 학습 정책, 계정 삭제/전환 fencing, 개인 음성 캐시 격리, `allowSynthesis: false` prefetch 유지.
- DE/EN 기존 지역화와 Sori 토큰 사용. 신규 그림, SDK, 결제, 서버 배포, workflow 변경 없음.
- 실제 글꼴로 레이아웃 검사. 무한 애니메이션에서 pumpAndSettle 금지.
- Task 1과 2가 같은 파일을 쓰므로 순차 구현한다. 각 작업은 실패 재현 → 수정 → 관련 테스트 → 직접 diff 리뷰 순서다.
- spec의 생산/기기/콘솔 확인은 실제 증거가 생길 때만 완료 표시한다.

### Task 1: Cancelled speech must not publish stale failures

**Files:**
- Modify: `lib/services/tts_service.dart`
- Test: `test/tts_request_rate_test.dart`, 필요한 기존 private/public TTS 테스트

**Interfaces:**
- Consumes: `TtsPlaybackEngine.speak`, `stop`, `dispose`, resolver Future 및 기존 generation/session 소유권.
- Produces: 기존 public signatures 유지. 활성 요청만 실패 콜백/공용 unavailable 상태를 게시한다.

- [x] **Step 1: Add and run failure-first regression tests.** 기존 `_FakePlatform`과 Completer를 사용한다.

```dart
final pending = Completer<TtsAudio?>();
final failures = <String>[];
final engine = TtsPlaybackEngine(
  resolveAudio: (_, __) => pending.future,
  platform: _FakePlatform(),
  errorReporter: failures.add,
  onResolutionFailed: failures.add,
);
final result = engine.speak(text: '안녕하세요', voice: 'female', baseRate: 0.42);
await Future<void>.delayed(Duration.zero);
await engine.stop();
pending.completeError(StateError('late failure'));
expect(await result, isFalse);
await Future<void>.delayed(Duration.zero);
expect(failures, isEmpty);
await engine.dispose();
```

또한 dispose 뒤 실패, 성공한 B 뒤 A 실패, 활성 A 실패는 정상 진단되는 경우를 검사한다.
resolver 내부에서 직접 `_reportUnavailable`하는 경로에도 같은 소유권 규칙을 검사한다.
Run: `flutter test --no-pub test/tts_request_rate_test.dart --reporter expanded`.
Expected before fix: late failure callback assertions fail, not setup/import errors.

- [x] **Step 2: Fence failure publication at the existing ownership seam.**

```dart
if (!_disposed && generation == _generation) {
  errorReporter?.call(message);
  onResolutionFailed?.call(message);
}
```

이 가드는 engine 내부의 현재 필드에 적용한다. service resolver가 직접 공용 상태를 바꾸는
경로는 기존 재생 요청 generation과 연결하거나 실패 사유를 요청 결과로 전달해, prefetch/이전
resolve가 활성 배너를 바꾸지 않게 한다. private 세션 검증을 우회하는 global boolean은 쓰지 않는다.

- [x] **Step 3: Verify focused protection tests and review.**
Run: `flutter test --no-pub test/tts_request_rate_test.dart test/tts_playback_contract_test.dart test/tts_private_cache_test.dart --reporter expanded`.
존재하는 관련 private 테스트를 `rg --files test -g '*tts*'`로 확인해 실제 파일명을 쓴다.
현재 요청의 quota/offline/device 안내 및 stop completion이 유지되는지 diff를 직접 읽는다.
자동 테스트 성공은 실기기 음성 출력 증거가 아니다.

### Task 2: Recover canonical speech when prefetch or disk caching fails

**Files:**
- Modify: `lib/services/tts_service.dart`
- Test: 기존 TTS disk/prefetch 테스트 또는 `test/tts_cache_recovery_test.dart`

**Interfaces:**
- Consumes: `TtsService.prefetch`, `resolveAudioForTesting`, 기존 cache directory setter,
  `TtsAudio.bytes`, `_memoryCacheEntries = 64`, Task 1의 요청 소유권.
- Produces: null prefetch 재시도와 정본 음성의 best-effort disk cache. 개인 텍스트는 기존 private 경로.

- [x] **Step 1: Prove failed-prefetch and cache-write cases.** null → success 재시도,
  success 중복 억제, concurrent 중복 억제, exception 뒤 재시도를 검사한다.
  캐시 파일의 `.part` 자리에 디렉터리를 만들어 쓰기 실패를 결정적으로 재현한다.

```dart
final blockedPart = Directory('${target.path}.part');
await blockedPart.create();
// Existing resolver/cache test seam receives a valid canonical MP3 fixture.
// Assert returned TtsAudio carries the same bytes and callable count remains 0.
```

검사는 실제 production SDK/네트워크를 호출하지 않는다. 현재 테스트 시임을 먼저 사용하고,
직접 시임이 없으면 캐시 변환 함수에만 좁은 visibleForTesting 접근을 추가한다.

- [x] **Step 2: Make a miss retryable and a cache write optional.**

```dart
final audio = await _resolveAudio(trimmed, resolvedVoice, allowSynthesis: false);
if (audio == null) {
  _prefetchAttempted.remove(key);
}
```

캐시 폴더를 만들 수 없으면 공용 정본의 기존 메모리/Storage 경로를 계속한다.
디스크 write 실패는 다운로드 바이트를 반환한다. 파일 저장 성공 시 기존 path 반환 및 prune을
유지한다. 메모리 상한과 MPEG 검사, 정본 manifest 검증을 유지하고 개인 텍스트를 디스크에 넣지 않는다.

- [x] **Step 3: Verify recovery and privacy protection.**
Run: `flutter test --no-pub test/tts_cache_recovery_test.dart test/tts_request_rate_test.dart test/tts_playback_contract_test.dart --reporter expanded` 및 실제 관련 cache/canonical/private 테스트.
테스트 임시 폴더 외 파일을 지우지 않는다. 코드/테스트를 리뷰한 후 Task 3으로 진행한다.

### Task 3: Make shared loading states accessible and resilient

**Files:**
- Modify: `lib/widgets/app_loading.dart`
- Test: `test/app_loading_reduced_motion_test.dart`, `test/app_loading_accessibility_test.dart`

**Interfaces:**
- Consumes: 기존 `AppLoading({message, asset, assetSize})`, AppL10n 기존 `speechIndicatorResolving`, Sori text/surface 토큰.
- Produces: 같은 constructor. message 또는 기존 localized 로딩 라벨 한 개, 이미지 제외 의미 트리,
  bounded/unbounded-height 양쪽에서 안전한 레이아웃.

- [x] **Step 1: Write semantic and real-font layout regressions.**

```dart
setUpAll(loadSoriRealFonts);
// MaterialApp with AppL10n delegates, DE/EN locale, 320dp width,
// textScaler: TextScaler.linear(2), disableAnimations: true.
// For no message: exactly one liveRegion contains speechIndicatorResolving.
// For an explicit message: exactly one liveRegion contains that message.
// At height 160 with assetSize 124 + pronunciationPhrasesLoading:
expect(tester.takeException(), isNull);
```

320×160은 키보드/가로 화면/임베디드 영역의 제약 검사이며 전체 앱 최소 지원 높이 선언이 아니다.
일반 화면 크기에서는 기존 크기·가운데 배치를 유지한다. 별도 스크롤 안에서도 render 오류가 없어야 한다.
Run: `flutter test --no-pub test/app_loading_accessibility_test.dart --reporter expanded`.

- [x] **Step 2: Add a single status and scroll-safe layout.**

```dart
Semantics(
  liveRegion: true,
  label: widget.message ?? AppL10n.of(context).speechIndicatorResolving,
  child: ExcludeSemantics(child: visualContent),
)
```

기존 tests/isolated caller에 AppL10n 또는 MediaQuery가 없으면 crash를 새로 만들지 않도록
nullable lookup을 사용한다. 실제 앱에는 DE/EN 라벨이 항상 제공된다. visible copy를 추가하지 않는다.
LayoutBuilder + 필요시 scroll/minHeight 처리는 AppError의 기존 패턴을 참고한다.
Motion은 기존 정책대로 멈추고 런타임 preference 변경 시 다시 적용한다.

- [x] **Step 3: Verify consumer regressions and review.**
Run: `flutter test --no-pub test/app_loading_accessibility_test.dart test/app_loading_reduced_motion_test.dart test/app_error_sori_button_test.dart test/review_session_loading_state_test.dart test/sori_stage_responsive_accessibility_test.dart --reporter expanded`.
직접 diff 리뷰에서 장식 그림 변경·새 하드코딩·스크롤 위치 오염·무한 ticker를 점검한다.

### Task 4: Identify server TTS failure stages without logging user data

**Files:**
- Modify: `functions/tts/index.js`, `functions/tts/tts_request_guard.js`
- Test: `functions/tts/private_tts.test.js`, `functions/tts/tts_request_guard.test.js`

**Interfaces:**
- Consumes: `synthesizeTts(request)`, `ttsLogErrorCode(error)`, existing vm harness and `logs` capture.
- Produces: fixed processing-stage field plus allowlisted code in unexpected-error diagnostics only.
  Public callable errors, request shape and all data mutations stay identical.

- [x] **Step 1: Prove safe classification and production handler logging.**

```js
assert.equal(ttsLogErrorCode({code: 7}), "permission-denied");
assert.equal(ttsLogErrorCode({code: 14}), "unavailable");
assert.equal(ttsLogErrorCode({code: "PRIVATE_CANARY_7193"}), "internal");
const h = harness({duringSynthesis: async () => {
  throw Object.assign(new Error("PRIVATE_CANARY_7193"), {code: 7});
}});
await assert.rejects(h.invoke(), {code: "internal"});
const serialized = JSON.stringify(h.logs);
assert.equal(serialized.includes("PRIVATE_CANARY_7193"), false);
assert.equal(serialized.includes("permission-denied"), true);
assert.equal(serialized.includes("provider"), true);
```

같은 handler harness에서 account read, Storage read/save, provider 오류의 단계가 구분되는지
검사한다. success는 오류 로그가 없고 기존 알려진 HttpsError 응답은 바뀌지 않아야 한다.
Run: `node --test functions/tts/tts_request_guard.test.js functions/tts/private_tts.test.js`.

- [x] **Step 2: Add fixed stage tags and allowlisted error mapping.**

```js
let stage = "validation";
// Assign literal stages at the actual awaited operation, not from request data.
// At the unexpected-error catch only:
console.error("synthesize_tts error", {stage, code: ttsLogErrorCode(e)});
```

`stage`는 source의 literal만 허용하고 error 메시지·stack·request는 넘기지 않는다.
오류 코드 string은 Firebase/gRPC의 명시적 allowlist를 사용하고 알 수 없는 값은 `internal`로
분류한다. gRPC 0–16 정수는 알려진 이름으로 변환하되 범위 밖/소수/숫자 문자열은 fallback한다.
실패 뒤 cleanup/refund가 원래 실패 단계를 덮어쓰지 않도록 원래 operation stage를 유지한다.
새 모듈이나 runtime dependency는 추가하지 않는다.

- [x] **Step 3: Verify TTS server suite and review.**
Node 22에서 `node --test`를 `functions/tts` cwd로 실행한다. handler fault tests가
실제 log call을 검사하는지, 모든 public/private/quota/idempotency 테스트가 유지되는지 리뷰한다.
local logging 개선은 production 500 해결/서버 배포로 표시하지 않는다.

### Task 5: Release-candidate verification and reviewable evidence

**Files:**
- Update: 본 계획의 체크박스 및 설계의 현재 근거 표
- Generated: `graphify-out/` (저장소 종료 규칙)
- Evidence outside source: `C:/dev/hangulsori/_codex_artifacts/global-launch-*`

**Interfaces:**
- Consumes: Task 1–4의 미커밋 diff, 최신 공식 스토어 기준, 기존 CI/릴리스 도구.
- Produces: 로컬 검증 결과, 디자인/구조 전후 설명, 통합할 diff, 미해결 production 게이트.

- [x] **Step 1: Run targeted complete regression set and analyzer.** 위 세 작업의 합집합을 한 번
  실행하고 5축 리뷰 및 저장소 표준/스펙 리뷰를 통과시킨다. formatter와 `git diff --check` 실행.
- [x] **Step 2: Build the release web candidate.** `flutter build web --release --no-web-resources-cdn`.
  기존 Playwright 6환경을 사용한다. 자동 브라우저는 production 요청을 차단하는 기존 규칙을 유지한다.
  자동 실패가 있으면 원인을 고치고 재검증한다. 기기 부재는 별도 open gate로 남긴다.
- [x] **Step 3: Verify store contracts.** `dart run tool/verify_ios_firebase_config.dart` 및
  `dart run tool/verify_ios_store_contract.dart`, 기존 release integrity tests 실행.
  컴파일/설정 성공과 iOS 서명 업로드를 혼동하지 않는다.
- [x] **Step 4: Present the reviewed result and integration decision.** 직접 본 UI/코드 근거와
  외부 게이트를 설계에 연결하고 `graphify update .` 실행. main/병행 작업을 보존했는지 확인.
  커밋·푸시·병합·실제 스토어 제출은 준비된 후보에 대한 승인 후 진행한다.
  **후속 실행 승인:** Jin이 커밋·푸시 → PR·CI → 서명 후보의 실기기 검수를 요청했다.
  로컬 구현·검증·독립 리뷰를 통과한 수정본으로 진행한다. 다른 작업의
  Closed Testing 2278 업로드는 성공했고 main 작업 보류도 해제되었다. Play Console에서는
  새 Alpha 18이 검토 중이고 기존 Alpha 16이 테스터에게 제공 중이다. 이 수정본의
  커밋·푸시와 PR 생성은 승인되었다. 추가 배포 전 기존 실행과 중복 여부를 확인한다.
- [x] **Step 5: Verify the published PR head.** 검증한 파일만 커밋·푸시하고 PR을 만든다.
  자동 CI가 있으면 재사용하며 정확한 head SHA의 필수 검사와 Playwright 결과를 확인한다.
  #294 `520bc7d1`의 CI 34475850346 성공(Flutter 2707 성공·7 skip), Playwright
  34475850257 성공(6/6)을 확인했다. 이후 로컬 최적화는 이 CI 결과에 포함하지 않는다.
- [ ] **Step 6: Verify the signed candidate on a device.** 기존 보호된 서명 경로의 조건과
  트랙 영향을 확인하고 후보의 SHA·versionCode·checksum·서명·설치를 연결한다.
  실제 연결 기기에서 새 설치/업데이트, 음성, 진척 저장, 앱 복귀·오프라인을 검수한다.
  기기 부재나 서명 경로의 충족되지 않은 조건은 완료로 표시하지 않는다.

### Task 6: Prepare verified Android symbol-tool pins

**Trigger:** main `7e844d1b`의 Closed Testing 실행 34414481048은 versionCode 2278을
성공적으로 업로드했지만 심볼 검증 단계는 비활성이었다. 착수 시 설정의 네 SHA256 필드는
harvest placeholder였다. GitHub 저장소/릴리스 환경에서 심볼 전용 secret 및 두 변수가
조회되지 않았다. 실제 Crashlytics 심볼 업로드 성공을 추정하지 않는다.

**Files:** `tool/android_release_tools.json`, `docs/runbooks/android-symbol-evidence.md`,
새 `docs/runbooks/android-release-tools-provenance.json`.

- [x] **Step 1: Establish publisher-backed provenance.** 기존 고정 버전을 유지한다.
  bundletool은 Google GitHub release digest, Temurin은 Adoptium release digest,
  Node는 공식 SHASUMS256, firebase-tools는 npm 배포본의 SHA512 integrity와 대조한다.
  검증한 압축 파일 안의 정확한 Linux x64 `bin/java` / `bin/node` 및 `lib/bin/firebase.js`
  SHA256을 계산한다. Java는 이번 CI harvest와도 일치한다. CI의 기본 Node와 이후 설치할
  고정 Node의 해시는 다르므로 기본 Node harvest를 그대로 복사하지 않는다.
- [x] **Step 2: Fill the four pins and document the remaining gate.** 네 placeholder만
  검증한 해시로 채우고 출처와 archive/member 연결을 기록한다. runbook은 최초 준비가
  완료된 항목과 앞으로 버전 변경 시 다시 수행할 절차를 구분한다. workflow·secret·변수·IAM을
  수정하거나 심볼 업로드를 실행하지 않는다.
- [x] **Step 3: Verify existing contracts and independent review.** 기존 release integrity,
  Android evidence 및 tool config 검사 실행. 리뷰에서 버전·플랫폼·archive 검증·member 해시를
  대조하고, 사용 준비와 실제 gate 활성화/서버 업로드를 구분한다. 앱 코드 12파일은 유지한다.

### Task 7: Repair loading regressions found by PR CI

**Trigger:** PR #294의 첫 head `24a77f79`에서 선택된 Flutter 225파일은
2686 성공·13 실패·7 skip이었다. Playwright 6개와 나머지 선택된 CI gate는 성공했다.
실패한 네 파일의 로컬 재현도 103 성공·13 실패로 일치했다. 단어장의 `SoriMinHeightScroll`
내부 `IntrinsicHeight`가 `AppLoading`의 `LayoutBuilder`에 내재 높이를 요청했고,
온보딩은 소비 화면과 공통 위젯 양쪽에 동일한 Semantics label이 선언되어 있었다.
이는 두 번의 실제 TalkBack 발화를 관측했다는 뜻은 아니다.

**Files:** `lib/widgets/app_loading.dart`, 실제 온보딩·단어장 소비 화면,
`test/app_loading_accessibility_test.dart`.

- [x] **Step 1: Reproduce the CI failures and intrinsic-layout regression.** 실패 화면을
  그대로 재현하고 공통 로딩의 `SoriMinHeightScroll` 회귀 검사를 먼저 실패시킨다.
- [x] **Step 2: Preserve single-owner semantics and intrinsic-compatible loading.** 기존
  세로 스크롤을 재사용하고 독립 로딩은 짧은 화면에서 스크롤한다. 애니메이션의 자연 높이,
  reduced motion, DE/EN 큰 글자, Today의 중첩 스크롤 계약을 보존한다.
- [x] **Step 3: Verify and independently review the delta.** 실패 화면과 관련 로딩·반응형·Today
  13파일 830개 검사와 수정 4파일 분석·형식 검사를 통과했다. Standards/Spec 및 correctness
  리뷰 모두 승인, 행동 가능한 지적 0건이다. 같은 PR에 추가할 수정본이며 이후 원격 head의
  CI 결과와 서명 후보·기기 결과는 PR 및 외부 검증 영수증에 정확한 SHA로 연결한다.

### Task 8: Remove duplicate Hanok/Gye maintenance semantics

**Trigger:** 연결된 Redmi의 기존 Play 2265에서 한옥 안내 문장이 하나의 접근성 label에
두 번 들어가는 것을 UI hierarchy로 확인했다. 현재 `SoriUpdatingScene`도 외부 label과
내부 Text의 의미 정보가 합쳐지는 구조였다. 실제 TalkBack 음성을 들었다는 뜻은 아니다.
9월 3일 승인된 시각 재작업 플래그와 기존 그림·안내 문구·레이아웃은 유지한다.

- [x] **Step 1: Reproduce the effective semantics.** 기존 위젯 속성 검사 대신 실제
  SemanticsNode의 전체 label과 image 역할을 검증한다. DE/EN 모두 중복 label로 실패했다.
- [x] **Step 2: Keep one accessible message.** 외부 Semantics가 안내 문장을 소유하고
  내부 장식과 Text의 의미 정보를 제외한다. 보이는 Text는 그대로 검사한다.
- [x] **Step 3: Verify and integrate.** 한옥·계 소비 화면 회귀, 분석·형식 검사와 독립
  Standards/Spec 리뷰 후 같은 PR #294에 반영한다. 기존 서명 후보 2280(`2373b1d3`)에는
  이 후속 수정이 없으므로 새 커밋의 CI와 서명 후보를 구분해 확인한다.
  23개 로컬 회귀와 두 축 리뷰를 통과해 `520bc7d1`로 반영했고 해당 PR CI도 성공했다.
  실기기 후보 검수는 Jin의 최신 배포 보류 지시에 따라 열린 상태로 둔다.

### Task 9: Share learning-data decoding and fence reset races

**Execution scope:** Jin의 최신 지시로 배포·스토어 업로드·서명 후보 반복 생성은 보류한다.
로컬 최적화와 관련 검증을 묶어 진행하며 변경마다 원격 CI를 새로 실행하지 않는다.
온보딩 디자인과 커리큘럼 작성은 해당 진행 작업에 맡기고 런타임 로더에 집중한다.

**Trigger:** 코스·복습·퀘스트가 같은 DataLoader 파일을 동시에 요청하면 문자열 읽기만
공유하고 CSV/JSON 해석·모델 목록은 각각 생성했다. 문법 재시도와 전체 초기화는 bundle
문자열을 비우지 않았고, 초기화 전에 시작한 요청이 새 결과·오류 상태를 덮을 수 있었다.

**Files:** `lib/services/data_loader.dart`, `test/data_loader_test.dart`.

- [x] **Step 1: Reproduce duplicate decoding and reset races.** 세 콘텐츠 종류의 동시 호출,
  재시도·전체 초기화·늦은 성공/실패를 제어하는 회귀 검사: 수정 전 5 성공·17 실패.
- [x] **Step 2: Share each pending decoded result and fence its publication.** 파일별 요청을
  공유하고 초기화 세대로 오래된 완료를 차단한다. 명시적 재시도는 해당 bundle 캐시도
  비운다. 기존 API·파서·오류 문구·빈 실패 캐시와 다른 콘텐츠 캐시는 보존한다.
- [x] **Step 3: Verify consumers and independent Standards/Spec review.** 실제 2,499개 단어와
  인용 CSV 필드 검사, 화면 재시도·복습·커리큘럼 소비자, 분석·형식 검사를 로컬에서 실행한다.
  동시 호출의 같은 객체 공유는 중복 해석 제거 근거이며, 실기기 시작 지연이나 메모리 절감량을
  측정한 결과로 보고하지 않는다. 기존 PR의 520bc7d1 CI는 이 미커밋 수정의 검증이 아니다.
  여섯 파일 93/93 성공(로더 25개 포함), 수정 소스 분석 무문제. Standards/Spec 모두
  APPROVED, 행동 가능한 지적 0건. 로컬 수정으로 보관한다.

### Task 10: Share pending scenario parsing and protect retry state

**Trigger:** 전체 코퍼스·레벨 단위 동시 호출이 같은 시나리오를 반복해서 해석했다.
초기화가 bundle 캐시와 진행 중 요청을 분리하지 않아 실패가 재사용되거나 이전 완료가
새 캐시·오류·LRU를 덮을 수 있었다.

**Files:** `lib/services/scenario_loader.dart`, `test/scenario_loader_shard_test.dart`.

- [x] **Step 1: Reproduce through asset-channel gates.** 전체/레벨 동시 호출, 실패 후 재시도,
  초기화 뒤 늦은 성공/실패, 전체와 레벨 요청의 겹치는 샤드 해석: 수정 전 5 성공·9 실패.
- [x] **Step 2: Coalesce pending work and fence publication.** 전체 코퍼스 요청을 공유하고
  같은 세대의 진행 중 샤드 해석을 전체·레벨 소비자가 함께 사용한다. reset은 기존 요청의
  결과·오류·LRU·새 pending 변경을 막고 여섯 bundle 항목을 비운다. 기존 compute,
  전체 코퍼스 순차 처리, 레벨 캐시 2개 제한, 손상 항목 건너뛰기와 공개 API를 유지한다.
  이미 완료된 전체 코퍼스와 레벨 캐시를 합치는 구조 변경은 이번 범위에 포함하지 않는다.
- [x] **Step 3: Verify dependent learning flows and independent reviews.** 실제 시나리오 178개,
  손상 항목·우선 레벨 찾기·LRU 및 재시도 회귀 21개 통과. 관련 코스·복습·퀘스트·학습 저장
  소비자 검사와 분석·형식 검사 후 Standards/Spec 리뷰를 완료한다. 새 배포나 기기 상태 변경 없이
  로컬 검증 증거를 남기고 Graphify를 이번 묶음 종료 시 한 번 갱신한다.
  리뷰에서 발견한 findById의 검색 중 초기화 경합을 0/1 실패로 재현하고 검색 전체에 시작
  세대를 유지하도록 수정했다. 수정 후 소비자 10파일 75/75, 추가 pending 합류 2개를 포함한
  shard 검사 17/17, 수정 4파일 분석·형식 검사가 성공했다. Task 9와 중복을 제거한 로컬
  검증은 16파일의 서로 다른 검사 170개다. Standards와 재검토 Spec 모두 APPROVED,
  남은 행동 가능한 지적 0건이다. 커밋·푸시·배포는 추가 실행하지 않았다.

### Task 11: Bound personal-image decoding and preserve image ownership

**Trigger:** ManagedMediaImage는 44/56dp 목록 썸네일에도 원본 파일을 디코딩하고, 부모
rebuild마다 같은 파일의 경로·심볼릭 링크 검증을 반복한다. FutureBuilder가 교체 전 데이터를
보존하므로 참조 변경 중에는 이전 단어의 사진이 남을 수 있다.

**Files:** `lib/widgets/managed_media_image.dart`, 새 `test/managed_media_image_test.dart`.

- [x] **Step 1: Reproduce with synthetic images and controlled file reads.** 실제 PNG 디코더로
  가로·세로 사진의 출력 크기와 비율을 확인하고, 부모 rebuild·사진 교체·늦은 완료·앱 복귀를
  재현한다. 테스트 전용 ManagedMediaStore와 임시 파일만 사용한다.
- [x] **Step 2: Reuse each view's lookup and decode for its displayed size.** 같은 참조의 일반
  rebuild는 조회를 재사용하되 참조 교체·앱 resume·계정 세대 변경은 재검증한다. 이전 참조의
  이미지가 새 단어에 나타나지 않게 한다. 계정 전환 중에는 개인 사진을 숨기고 진행 중 조회를
  무효화한다. 원본 파일과 기존 containment 검사는 변경하지 않는다. 디코딩은 표시 크기와
  DPR·BoxFit에 맞추되 종횡비·cover 선명도를 유지하고 원본보다 확대하지 않는다.
- [x] **Step 3: Verify widget, consumer, and media boundaries.** 실제 디코드 크기·부모 조회 횟수,
  참고 사진 교체·실패·늦은 완료·resume·계정 변경을 검증하고 편집/학습/퀴즈와 기존 미디어
  보관·삭제 경계 검사를 실행한다. 분석·형식·표준/스펙 리뷰 후 로컬 수정으로 보관한다.
  합성 PNG의 디코드 메모리 수치와 실제 앱 전체 메모리·실기기 성능은 구분한다.
  초기 행동 검사 3 성공·9 실패 및 더 엄격한 계정 clear 검사 0/1 실패로 결손을 재현했다.
  빠른 resume에서 구독 전에 교체된 조회의 처리되지 않은 오류도 0/1 실패로 확인하고,
  조회 생성 즉시 기존 null fallback으로 처리하도록 보완했다. 최종 7파일 104/104 성공
  (위젯 14개 포함), 변경 Dart 2파일 분석 무문제·형식 일치. Standards/Spec r1 모두
  APPROVED, 지적 0건이다. 1200×600 PNG의 44dp/DPR3 cover는 실제 264×132로 디코드했다.
  Flutter ImageInfo의 4bytes/pixel 기준 2,880,000→139,392bytes(95.16% 감소)이며
  특정 합성 사진의 디코드 비트맵 비교다. 원본 파일·실기기·전체 앱 메모리 변화는 아니다.

### Task 12: Decode book previews within their displayed bounds

**Trigger:** 책 사진 미리보기는 조회 Future를 이미 재사용하지만, 160dp 높이의 contain
미리보기에도 촬영 이미지 전체를 디코딩한다. 개인 원본과 OCR 입력을 변경하지 않고
화면 표시용 이미지의 픽셀 수를 제한한다.

**Files:** `lib/screens/book_preview_screen.dart`, `lib/widgets/managed_media_image.dart`,
새 `lib/widgets/display_sized_file_image.dart`, 새 `test/book_preview_image_decode_test.dart`.

- [x] **Step 1: Reproduce excess decoding.** 합성 PNG를 실제 Flutter 디코더로 읽어
  세로·가로·넓은 사진의 디코드 크기를 확인한다. 작은 사진은 확대하지 않으며, DPR와
  표시 폭 변경·OCR 편집 중 기존 1회 조회 및 원본 보존을 검사한다. 실제 프레임의 테두리
  2dp를 제외한 158dp 표시 영역으로 기대값을 정정한 후 수정 전 1 성공·6 실패를 확인했다.
- [x] **Step 2: Fit decoding to the existing preview.** 실제 레이아웃 제약과 DPR에 맞춘
  디코드 크기를 사용한다. Task 11에서 검증한 FileImage provider를 공유하여 contain/cover,
  극단적으로 얇은 사진의 최소 1픽셀·작은 원본 확대 금지·캐시 키 동작을 한 곳에서 유지한다.
  기존 160dp 프레임·contain·누락/오류 fallback 및 pending lease의 인계·해제 동작은 유지한다.
- [x] **Step 3: Verify book flow and review.** 디코딩 검사와 기존 지역화·접근성·미디어
  경계·소유권·복구 검사를 실행하고 두 축 리뷰를 수행한다. 원본 bytes와 표시 비트맵,
  실기기 전체 앱 메모리를 구분한다. 새 빌드·푸시·원격 CI·배포 없이 로컬로 보관한다.
  최종 12파일 156/156 성공(새 책 사진 검사 7개와 기존 단어 사진 14개 포함), 변경 Dart
  분석 무문제·형식 일치. Standards/Spec 모두 APPROVED, 지적 0건. 2400×3600 합성 PNG의
  158dp/DPR3 contain 출력은 실제 316×474이며 디코드 비트맵은
  34,560,000→599,136bytes(98.27% 감소)다. 특정 합성 이미지의 비교이며 앱 전체 RAM이나
  실기기 검수 결과가 아니다. 원본 사진·OCR·lease 소유권 로직은 변경하지 않았다.

### Task 13: Distinguish curriculum gaps from notation mismatches

**Trigger:** main 5b76f23e의 매트릭스 검사를 고정 사본에서 재실행하면 539개 검토 항목이
재현된다. 코스 연결·진척·시나리오 문법 표시 관련 7파일 47개는 통과했다. A1의 실제
`V-습니까?/-ㅂ니까?` 카드가 슬래시 분기별 문장부호·하이픈 처리 누락으로 문법 없음으로
판정되는 결함을 찾았다. A2 `V/A-음`도 결합 슬롯 표기가 본문으로 남아 오탐이었다.
나머지 사전형/활용형 차이는 자동으로 같은 형태로 승인하지 않는다.

**Files:** `tool/build_level_bible_tables.py`, `tool/test_build_level_bible_tables.py`,
`docs/data/level_bible/F1_grammar_map.md`, `F9_exceptions.md` 및 최신 main 매트릭스의 검증 사본 산출물.

- [x] **Step 1: Reproduce the incorrect gap.** 각 slash 분기의 표기 정규화와 F1의 질문형
  매칭을 실패로 재현한다. 질문/평서 구분, 기존 모음 교체와 조사/어미 경계는 유지한다.
  선택형의 빈 분기와 결합 슬롯 `V/A-`도 별도 실패로 재현했다.
- [x] **Step 2: Normalize notation at each alternative.** 슬롯 접두·구분 하이픈·문장 끝
  물음표만 제거한다. 새 문법 대응 규칙·콘텐츠·레벨 변경으로 감사 수치를 낮추지 않는다.
- [x] **Step 3: Verify the generator and the current main audit together.** 기존 생성기 전체
  검사, 새 main의 matrix 검사와 F1 결과를 대조하고 변경 항목을 직접 리뷰한다. 현재 브랜치의
  F1·F9와 최신 main 기준의 매트릭스 산출물을 함께 준비한다. 병합·푸시·배포는 보류한다.
  최종 생성기 33/33, main 5b76f23e 고정 사본의 matrix 21/21 및 산출물 최신성 검사가
  성공했다. 앞선 실제 코스 연결 검사 47/47도 통과했다. 검토 항목은 539→537로
  위 두 표기 오탐만 제거됐고 추가된 행은 없다. F9의 기존 `service_request` 수동 판정은
  재생성 안내에 따라 보존했다(자동 92 + 수동 1 = 93개). Standards/Correctness 및
  Spec 재검토 모두 APPROVED, 남은 지적 0건이다. 현재 브랜치의 F1·F9와 최신 main
  기준 산출물 6개는 기준 lexicon 차이 때문에 분리해 준비했다. main 통합 후 산출물은
  다시 생성·대조해야 한다. 감사 오탐 수정이며 실제 콘텐츠 확충이나 출시 준비 완료의
  증거는 아니다. 런타임 원문·레벨·기기 상태는 변경하지 않았다.

### Task 14: Recover course initialization without losing later progress

**Trigger:** CourseProgressService가 실패한 초기화 Future를 계속 보관하면 이후의 코스
표시·학습 증거 저장도 같은 오류로 실패한다. CurriculumCatalog의 manifest 문자열 캐시와
cloze/satz의 문자열 캐시도 읽기 실패를 보존하며, 병렬로 시작한 Future를 차례로 await해
앞선 오류가 처리되지 않을 수 있다. 여러 화면은 코스 그래프를 각각 중복 생성한다.

**Files:** `lib/services/course_progress_service.dart`, `curriculum_catalog.dart`,
`data_loader.dart`, `scenario_loader.dart`, `cloze_loader.dart`, `satz_loader.dart` 및 해당 로딩·진척 검사.

- [x] **Step 1: Reproduce production-path recovery failures.** 실패 주입 후 다음 호출의
  진척 기록·기존 스냅샷 복구를 검증한다. 실제 번들 자료를 읽는 asset 채널에서 manifest와
  각 의존 자료의 일시적 읽기 실패, 동시 코스 조회, 형식 오류를 재현한다.
- [x] **Step 2: Make later attempts recover safely.** 실패한 서비스 Future를 해제하고
  성공한 서비스는 재사용한다. 그래프의 동시 요청은 한 번의 생성으로 합치며 모든 의존
  Future의 오류를 즉시 관찰한다. 실패한 번들 캐시만 다음 로딩 때 다시 읽는다. 잘못된
  그래프를 저장하거나 임의로 대체하지 않는다. 첫 실패를 성공으로 숨기거나 같은 학습
  결과를 자동 재실행하지 않으며, 기존 큐·삭제 장벽·진척 저장 규칙은 유지한다.
- [x] **Step 3: Verify recovery and existing learner boundaries.** 실제 소스 그래프와 진척·
  삭제 장벽·동기화·소비 화면 검사를 실행한다. 표준/요구사항 독립 리뷰 후 로컬로 보관한다.
  main cf1599ee의 #295 시나리오 정체성 변경과 대상 코스 서비스의 겹침도 확인한다.
  병합·새 빌드·푸시·원격 CI·배포는 보류한다.
  초기 코스 로딩 9개와 진척 복구 1개가 RED였고, 독립 리뷰에서 발견한 전체/레벨
  시나리오 오류 경합도 0/1 실패로 재현했다. 전체 코퍼스 전용 오류 상태를 분리한 뒤
  최종 21파일 295/295 성공(새 카탈로그 12개·진척 1개 포함), 수정 Dart 8파일 분석
  무문제·형식 변경 0건이다. 기존 저장된 진척을 유지한 채 다음 학습 증거가 저장되고
  새 서비스 인스턴스에서도 복원됨을 확인했다. 동시 4요청은 동일한 검증 그래프 하나를
  공유한다. Standards/Correctness 및 Spec 재검토 모두 APPROVED, 남은 지적 0건.
  실제 asset 채널과 번들 원문을 사용하는 실패 주입 검사이며 물리 기기의 강제 종료나
  앱 전체 성능 측정은 아니다. #295 전후 대상 서비스·기존 테스트 Git 객체는 동일했다.
  최신 main 전체와의 통합·원격 CI는 별도다.

### Task 15: Integrate current main locally and verify one optimization candidate

**Trigger:** 현재 최적화의 기준 HEAD는 `520bc7d1`이고 main은 #289 커리큘럼 매트릭스와
#295 시나리오 역할 변경이 포함된 `cf1599ee`다. 오래된 기준에 수정만 쌓이지 않도록
이 전용 작업 공간에 최신 main을 로컬 통합하고 누적 최적화와 함께 검증한다.
배포·새 서명 빌드·푸시·원격 CI는 실행하지 않는다.

- [x] **Step 1: Preserve and integrate.** merge-base 양방향 및 미커밋 변경을 대조했다.
  겹치는 경로는 Graphify 생성 파일 4개뿐이다. 수정·신규 파일과 ignored Superpowers
  검토 기록 총 59개를 외부 증거 폴더에 바이트 단위로 보존했다. `--no-commit --no-ff`
  로 main을 가져왔고 소스 충돌은 없었다. Git이 재작성한 줄바꿈도 원래 바이트로 복구했다.
  생성 파일 충돌은 보존한 로컬 그래프를 기준으로 해소하고 통합 소스에서 다시 갱신한다.
  아직 로컬 병합 커밋을 만들지 않았으며, 원격 PR 병합과 배포는 별개다.
- [x] **Step 2: Regenerate against integrated inputs.** 통합 검증에서 F1 생성 함수가
  `root` 인수를 무시하는 결함을 발견했다. Task 13의 최신 main용 F1 사본도 원래 작업
  폴더 자료로 생성돼 일부 행이 낡아 있었다. 다른 루트의 두 독립 자료 및 없는 루트의
  실패 검사를 RED로 재현하고, 두 입력 경로를 전달받은 루트에서 읽도록 수정했다.
  새 검사 2개가 통과했다. 통합 후 F1과 매트릭스를 재생성했고 최신 main 대비 제거된
  갭은 기존 표기 오탐 2개뿐이다(539→537, 추가 0). F9의 수동 `service_request`
  예외·근거는 원래 바이트 그대로 보존했다. 과거 F1 사본은 현재 통합 검증으로 대체한다.
- [x] **Step 3: Verify the combined candidate.** main의 시나리오·30 Phase 계약과 이
  세션의 진척 복구·자료 로더·이미지 디코딩·TTS·로딩 접근성 회귀를 함께 실행한다.
  기존 승인된 앱 코드의 바이트와 들어온 main 소스를 직접 대조하고 두 축 독립 리뷰,
  Graphify 갱신·보존 검증을 마친다. 실제 기기 성능·서명·배포 완료로 해석하지 않는다.
  통합 후보의 Flutter 58파일 598/598 및 전체 analyze가 성공했다. F1 생성기·매트릭스·
  Phase 최종 115/115, 변경되지 않은 시나리오 파이프라인 21/21, 두 감사기의 최신성
  검사도 성공했다. Standards/Correctness 및 Spec 리뷰 APPROVED, 남은 지적 0건이다.
  기존 앱·테스트 수정 15개는 원래 SHA256 그대로이며, main에서 들어온 앱·테스트
  11개는 cf1599ee와 일치한다. 최신 main 기준 수정분의 공백 검사도 성공했다.
  Graphify와 전체 보존 대조의 최종 결과는 외부 `launch-integration-verification.json`에
  기록한다. 이 검증 시점은 HEAD 520bc7d1 / MERGE_HEAD cf1599ee의 미커밋 통합 상태다.

### Task 16: Measure Android screen flows on the connected phone

**Trigger:** 통합 후보는 호스트 테스트를 통과했지만 기기의 렌더러·미디어 플러그인과
화면 전환 프레임 측정이 빠져 있다. 스토어 배포 보류를 유지하고 USB로 연결된
Redmi M2101K6G(Android API 31)에 로컬 profile 통합 테스트를 실행한다.

- [x] **Step 1: Pin the device and measurement scope.** 9053622f에 앱이 없는 상태와
  연결·여유 공간을 확인했다. 기존 앱이 설치된 Pad 6은 대상으로 삼지 않는다.
  기존 `app_flows_test.dart`는 SharedPreferences mock backend와 앱 위젯을 사용한다.
  실제 Firebase bootstrap·네이티브 프로세스 시작·디스크 내구성의 검증으로 해석하지 않는다.
- [x] **Step 2: Collect renderer evidence from real flows.** profile 모드에서 신규/기존
  진입·온보딩·화면 크기 변경·5탭 20회 전환의 FrameTiming을 수집하고 호스트 driver가
  실패 시에도 JSON을 보존하도록 한다. 기존 디버그 통합 테스트 동작은 유지한다.
- [ ] **Step 3: Run, diagnose, and verify.** 정확한 소스 해시·기기 상태·빌드 모드와
  결과를 함께 기록한다. 실패나 긴 프레임이 있으면 원인을 재현해 수정하고 필요한 검사만
  다시 실행한다. 실제 앱 전체 cold-start p95와 영구 저장·계정·결제 증거는 별도로 남긴다.
  측정 코드 2파일 분석 및 Standards/Correctness·Spec 리뷰는 승인됐다. profile APK
  2.0.9(2281), minSDK 24 / target 36, Android Debug 서명 v2·ZIP CRC 검증이 성공했다.
  빌드 전후 입력 1,556파일 해시는 동일하다. Redmi의 현재 화면은 60Hz다.
  Flutter 도구가 설치를 3회 시도했지만 Android가 모두
  `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`로 거부했다. 도구는 실패
  종료했고 앱은 미설치 상태다. **실제 실행된 테스트 0개, 성능 수치 없음**으로 기록한다.
  휴대폰의 USB 설치 허용과 사용자 재시도 응답을 기다린다. 같은 APK를 보존했으므로
  재개 시 `--use-application-binary`로 빌드 없이 실행한다. 스토어 업로드·원격 CI는 없다.

### Task 17: Integrate the live 30 Phase entry and verify real loader recovery

**Trigger:** main `f2cd1568` (#296) adds Phase goals and links to existing practice.
Integrate it with local optimization commit `6b085929`, then verify the combined
learning path, catalog, progress boundaries, and new routes. No push, remote CI,
new build, store upload, or device installation retry is part of this task.

- [x] **Step 1: Preserve and integrate.** Compare both sides of merge-base
  `cf1599ee`; only the four Graphify metadata files overlap. Preserve both sets
  and all 1,095 wiki/semantic hashes. After local merge, verify 45 owned files
  byte-for-byte and 19 incoming files against #296. Resolve only generated graph
  conflicts and rebuild the graph after source verification.
- [x] **Step 2: Exercise real Phase loader failure and retry.** The incoming
  screen retry test injects a loader and cannot prove recovery of its actual
  bundle read. Reproduce a transient missing asset through `flutter/assets`,
  retry without clearing application caches, and fix a demonstrated failure
  at the existing read boundary. Preserve all 30 goals, existing practice
  routing, translations, and saved progress. No new completion authority.
  Both transient missing reads and malformed JSON remained cached in the
  incoming loader (RED 0/2). `cache: false` at this read boundary makes the next
  call recover without clearing caches. The two new tests and eleven existing
  Phase tests passed. This rereads 35,077 bytes of packaged metadata per opening;
  the validated curriculum graph remains shared.
- [x] **Step 3: Verify the integrated paths.** Run Phase, learning path, catalog,
  progress, shell/navigation, and affected UI contract tests plus whole-project
  analysis. Check Phase generation and curriculum/Phase audit freshness. Review
  standards/correctness and spec independently, then commit the verified local
  integration and preserve its exact source evidence.
  The 33-file run passed 260 tests; only the new route fixture failed. Its real
  catalog compute work must finish outside the widget fake clock, and its
  scroll finder must distinguish the vertical list from horizontal level chips.
  After those test-only corrections, that final test passed 1/1. The other 260
  tests are unchanged. Whole-project analysis passed; the corrected test is
  reanalyzed separately with no issues. Python generation/matrix/Phase tests passed 87/87 and
  generation/audit freshness checks passed. This proves warmed app routes with
  mock preferences, not native cold-start, audio, or durable storage.
  The earlier profile APK does not contain #296 or this recovery fix; preserve
  it as historical baseline evidence. A current device candidate requires a
  later build after the source is fixed and device installation is permitted.
  Standards/Correctness and Spec approved the final fixture and implementation.
  The exact local commit, source hashes, Graphify preservation, and clean-tree
  verification are recorded in external `phase-integration-20260910/verification.json`.

### Task 18: Make visible pronunciation, smalltalk, and word-web retries recover

**Trigger:** Following the Phase failure, inspect remaining visible retry paths.
Pronunciation and smalltalk reset their own decoded state without evicting the
bundle string; word-web retries the same cached bundle read after an exception.
Reproduce those paths against the real asset channel before changing behavior.
Kkeunmari, syllable puzzles, DataLoader, and ScenarioLoader already evict their
assets on explicit reset; retain those implementations.

- [x] **Step 1: Reproduce and fix pronunciation retry.** A transient missing read
  and malformed metadata must fail closed, then a screen retry must reload the
  bundled phrases and restore practice controls. Preserve normal successful
  caching, phrases, local recording, consent, and disabled cloud assessment.
- [x] **Step 2: Reproduce and fix smalltalk and word-web retries.** Put bundle
  invalidation at each owning service boundary so all actual callers recover;
  remove redundant caller-only invalidation if the service now owns it. Keep
  course progress, filtering, translations and existing injected loaders intact.
  No global bundle clearing or new retry abstraction.
- [x] **Step 2b: Verify the dependent notebook retry.** Its visible retry calls
  `CustomPackCorpusResolver.forWords` again, but failed pronunciation, smalltalk,
  vocabulary, and scenario snapshots remain cached. Reproduce with the real
  asset channel, then reset only failed sources at that consumer boundary.
  Use source-specific vocabulary/scenario errors so an unrelated catalog error
  cannot mislabel healthy notebook content. Preserve successful corpora, the
  learner's selected rows, saved pack, and practice progress. Verify the actual
  notebook retry opens the recovered pronunciation subset.
- [x] **Step 3: Verify together and preserve evidence.** Check real load failures,
  malformed text, successful retry, unaffected success caching, visible screen
  retry, and related curriculum/custom-pack consumers. Run appropriate tests,
  changed-file analysis, two-axis independent review, and Graphify preservation.
  Record the verified local commit. No push, CI dispatch, new build, deployment,
  device retry, content changes, paid API fallback, or production call.

Verified locally: the three direct loader regressions failed for both missing
and malformed responses before their fixes. Nine notebook regressions also
failed before its consumer fix, including an unrelated grammar error and
the actual visible retry. After improving the generated-manifest and real
async widget fixtures, the final combined 28-file suite passed 207/207
(22 new recovery/cache tests). Changed-file analysis passed for seven Dart
files; formatting changed zero files. Both independent review axes approved
the implementation and final test additions. These are widget/service tests
with real bundled content and simulated platform failures, not native phone
or production-server evidence. Final source/Graphify preservation and the
local commit are recorded in external `visible-retry-20260910/verification.json`.

### Task 19: Keep loading-image failures inside their visual bounds

**Trigger:** Task 18's first generated-manifest fixture error exposed an 8px
overflow in `AppLoading`'s dot fallback. The default logo box is 58px wide;
three 12px dots plus their horizontal padding need 66px. Isolate a real image
read failure with the rest of the asset bundle healthy before changing code.

- [x] **Step 1: Reproduce the image-error fallback.** Use a scoped asset bundle
  that delegates healthy manifests/fonts/images and fails only the chosen logo
  or illustration. Verify the default 58px logo and small custom illustration
  sizes; the fallback must not emit a layout error. Exercise DE/EN, light/dark,
  reduced motion and normal animation, preserving the single localized live
  status. Capture the failure before the production fix.
- [x] **Step 2: Fit the existing dots without redesigning loading.** Limit the
  change to the failing visual boundary in `lib/widgets/app_loading.dart`.
  Preserve successful images, layout/scroll constraints, intrinsic parents,
  tokens, reduced-motion behavior, translations, and screen-reader semantics.
  Do not add assets, SDKs, global error suppression, new loading states, or
  unrelated screen/layout changes.
- [x] **Step 3: Verify and preserve the local candidate.** Run the new failure
  tests with existing loading accessibility/motion/short-height checks and
  affected learning-screen tests. Analyze changed files, obtain independent
  Standards/Spec reviews, update Graphify while preserving paid records, and
  record the local commit. No push, remote CI, build, device retry or deployment.

Local evidence: the isolated image-failure test first passed two controls
and failed the default and small double-failure cases with 8px/42px
RenderFlex overflows. The fix is confined to the logo error builder.
Four new tests cover 13 configurations: default failures 8, custom-only
failures 2, double failures 2, and healthy custom image 1. The combined
12-file suite passed 387/387 with the actual app themes; final analysis
passed after removing two unnecessary test imports, followed by a passing
rerun of all four new image-failure tests. Both review axes
approved the implementation. These are component/consumer checks, not
native device performance evidence. Final source/Graphify preservation
and the local commit are recorded in external
`loading-image-fallback-20260910/verification.json`.

### Task 20: Finish accepted Apple deletions when no revocation token remains

**Trigger:** At local base `c0cd721653cbcb4d9c1ce951428530a038a9f4e7`,
the client catches early Apple revocation errors, deletes Firebase Auth, and
finishes locally. The scheduled query and lease admission exclude unresolved
`appleRevocationPending` operations. The Auth deletion bridge deletes the user
tree but cannot resume the server-owned community/processor operation.

**Contract:** Apple's TN3194 requires account-data deletion even without an
access/refresh token or authorization code, with directions to revoke the
Apple connection manually. Keep successful transient revocation before Auth
deletion, without storing tokens or introducing a new user gate. A cancelled
or failed reauthentication must still prevent a new deletion request; a
successful reauthentication returning no authorization code must not.

**Files:** `functions/gye/account_operations_runtime.js` and related focused
tests; `lib/services/auth_service.dart`, `lib/screens/settings_screen.dart`,
DE/EN ARB and generated localization files, related service/widget tests;
`docs/release-readiness.md` for the remaining live verification boundary.
Change other production files only if the verified contract requires it.

- [x] **Step 1: Prove the full failure path locally.** Reproduce early
  provider failure, Firebase Auth removal, server-owned Auth bridge behavior,
  excluded scheduled work, and a still-pending receipt with the real repository
  and worker fakes. Also cover an accepted request whose client exits before
  supplying the code. Preserve the failed expectations before fixing.
- [x] **Step 2: Complete server cleanup truthfully.** Include pending Apple
  work in the existing separate/fair scheduled queue and admit its lease.
  Reuse the existing `kind, phase, nextAttemptAtMillis, updatedAtMillis`
  composite index by selecting deletion kind; avoid a new deployed index.
  On unavailable revocation input, persist a safe manual-revocation-required
  disposition and continue Auth, community, and processor deletion to the
  terminal receipt. `appleRevocationComplete` means actual successful
  provider revocation only, including the existing config-invalid branch.
  Preserve lease/version checks, bounded work, retry scheduling, idempotent
  Auth removal, successful early revocation, fair queues and tombstones.
  No account authorization, App Check policy, token persistence or public
  endpoint access changes. Current App Check enforcement remains a separate
  open release gate; do not describe advisory checks as enforcement.
- [x] **Step 3: Align client acceptance and user guidance.** Keep successful
  Apple/Firebase reauthentication mandatory, but allow its null/blank code
  result to reach the durable deletion request. Preserve cancellation,
  wrong-owner, blocked/cancelled results, journals, secure receipts and local
  cleanup/consent restart. Correct comments claiming the worker independently
  revokes tokens. In the existing account-delete confirmation, show Apple
  users (including Google+Apple) localized instructions to remove Hangul Sori
  under Apple Account > Sign-In & Security > Sign in with Apple if it remains
  listed, with the existing external-link helper opening Apple's official
  instructions. The help action must not delete, confirm, or block deletion.
  Reuse existing Sori dialog patterns and make guidance/confirmation usable
  at 320dp, 200% text, DE/EN. The success message must distinguish an accepted
  deletion/local cleanup from still-running server cleanup; do not claim
  that Apple's external authorization was revoked when it was not.
- [x] **Step 4: Verify the coherent candidate.** Test missing-code acceptance
  versus cancelled/failed reauth; early success/failure and abandoned request;
  scheduler selection and fairness; lease race/retry/idempotency; terminal
  receipt and cleanup completion; old pending records; guidance for Apple and
  mixed providers, help-only and cancel actions, and normal non-Apple flows.
  Run changed-file analysis plus relevant existing account/startup tests,
  independent Standards/Spec reviews, and Graphify update/prune with retained
  paid records. Record only a local commit. No pushes, remote CI, builds,
  device retries, secrets, live account mutations or deployment.

**Local implementation verification (2026-09-10):** Three independent
characterizations reproduced the inherited stalled-deletion/false-revocation
behavior. Meaningful regression runs failed before the fixes: server 0/3,
missing-code client 0/3, Apple guidance 0/4, and legacy disposition 1/2.
The final Node 22.23.2 run passed 109/109. One broader Flutter run passed
465/465 across 33 files; narrower runs overlap and are not added to that
total. Apple-only and mixed-provider guidance was checked in DE/EN at 320dp
and 200% text with real fonts. Changed-file analysis found no issues.
Independent Standards and Spec reviewers approved the frozen candidate with
no actionable findings, and all 12 reviewed source hashes matched the tested
bytes. Final source/asset/paid-Graphify preservation and the local commit are
recorded in external `apple-deletion-recovery-20260910/verification.json`.
These results do not prove real Apple revocation, deployed cleanup, existing
installed-client guidance delivery or device behavior.

**Sources checked 2026-09-10:**
[Apple TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple),
[Apple connection management](https://support.apple.com/en-us/102571),
[Firebase Flutter reauthentication/revocation](https://firebase.google.com/docs/auth/flutter/federated-auth#apple).
Local tests cannot close the real Apple/provider, deployed worker, App Check,
privacy-retention or device verification gates. Older installed clients have
not necessarily displayed the new manual instructions.

### Task 21: Integrate the current onboarding without losing launch fixes

**Trigger:** The current remote main advanced to
`8185cca7334348e52edac8464ddac6de49b97b81` (PR #297) while the local
launch candidate reached `b655dc0413ad3700f9e0ee2508327bc543e1028c`.
Validate one candidate containing both the approved onboarding and the
existing loading, retry, speech and account-deletion fixes.

**Scope:** Import the 44 paths changed by #297. Preserve its already-approved
four companion assets exactly; generate no new artwork. Keep both sets of
DE/EN messages and the local journey loading semantic fix. Do not alter the
unrelated website while its public deletion-path audit is still running.

- [x] Capture the clean local base, exact remote main, previous merge base,
  source and paid Graphify hashes before integration. Preserve both parents'
  Graphify records before rebuilding derived metadata.
- [x] Merge the exact main revision locally without committing. Resolve only
  generated Graphify conflicts; review the automatically combined journey and
  localization changes. Regenerate localization from the merged ARB files.
- [x] Verify onboarding presentation, learning preview, companion save/retry,
  motion/lifecycle and bundle contracts together with account/startup/loading,
  localization and adaptive-layout guards. Compare source/assets against the
  correct parent and analyze changed Dart. Obtain independent Standards/Spec
  reviews of the integration, not a repeat review of all inherited code.
- [x] Update/prune Graphify, retain paid records, and commit the verified merge
  locally with both parents. Keep exact upstream CI observations separate from
  local checks. No push, remote CI dispatch, mobile/site build, device retry,
  support message, store action or deployment.

**Evidence:** External `onboarding-integration-20260910/` records the baseline,
composition checks, focused test paths/results, reviews and final merge tree.
The existing profile APK predates this candidate and cannot verify it.

**Local verification (2026-09-10):** One combined run passed 462/462 across
48 test files; the Python media contract passed 5/5 and changed Dart analysis
passed for 24 files. Both independent reviews approved the composition and
matched all 40 incoming source hashes. There are 34 exact-main files plus six
shared localization/journey files, and 2,349 untouched prior source files.
The reviewed journey differs from main only by retaining the single loading
semantic owner. An initial test-list import-path error was corrected; its
accidental default test run was stopped at +0 and is not passing evidence.
Current main's existing CI/Playwright observations are stored separately;
they do not prove remote CI for this unpushed merge candidate.

### Task 22: Make the active public deletion path understandable and testable

**Trigger:** At `f78b24acf99eb1c25ca9fdb9c77013f27ea76439`, Settings says
"Copy link" while opening the browser, English users reach German deletion
instructions, and release checks protect a heading rather than the actual
email request action. The current website is the Cloudflare source under
`hangul-sori-site-local/`; the proof HTML/Firebase Hosting path is retained
legacy code with no current Flutter issuance reference.

**Contract:** Keep `/account-deletion` and the existing
`hello@hangul-sori.com` email request path. Google's checked
[account-deletion FAQ](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
explicitly permits a customer-service email. Users must be able to initiate
the request without reinstalling the app. A source change cannot prove live
mail receipt, account ownership, cleanup completion, retention, or crawler
accessibility. Add no automated proof wiring, backend service, secret, email
sender or new dependency.

- [x] **App:** Reuse the existing external-link helper and clipboard fallback.
  Make privacy/deletion row icons, DE/EN subtitles and private callback names
  describe opening a page. German keeps the canonical path; English opens
  `?lang=en` for these two already-localized legal resources. Keep deletion
  confirmation/workflow untouched. Prove real Settings taps deliver the
  correct external URL and preserve the clipboard fallback, at 320dp/200%
  with real fonts where layout is affected. Regenerate localization.
- [x] **Website:** Reuse `LegalShell`'s existing DE/EN/KO selection pattern,
  including invalid-language fallback to German. Put a clear email deletion
  request action and readable mailbox in the first content card; opening the
  page sends nothing. Give app-independent instructions with minimal account
  identification, then describe in-app deletion and local-reset/cloud-backup/
  uninstall differences accurately. Preserve asynchronous-cleanup wording and
  avoid invented completion promises, SLA, retention periods or support
  results. Keep DE default URL and existing visual language. Preserve the
  locale in English/Korean privacy-page deletion links.
- [x] **Release checks:** Exercise current source rendering for DE/EN/KO and
  invalid-language fallback without a full site build. Protect the request
  action's real mailto destination, meaningful subject, visible mailbox,
  language and app identification. Include negative fixtures proving missing
  or wrong request actions fail. Reuse the same small contract in existing
  built-route tests and the live verifier; do not invoke live verification.
  Include new tests in the existing unit-test command; change no dependencies.
- [x] **Documentation:** Make the current Cloudflare/email path authoritative
  in `docs/release-readiness.md`; remove the absent-CNAME claim, label retained
  proof/Hosting checks as conditional legacy gates, and keep current live URL,
  mailbox/handling, signed client, provider and retention checks open.
- [x] **Verify and record:** Run focused Flutter tests/analyze, source-rendered
  website and related release contract tests, no-emit TypeScript and scoped
  lint using already-installed matching dependencies. Obtain independent
  Standards/Spec reviews, preserve existing source/assets/paid Graphify,
  update/prune Graphify and commit locally. No push, remote CI dispatch, app
  or site release build, email, live deletion request, device retry or deploy.

**Ownership/consistency:** App worker owns Settings, DE/EN ARBs/generated files
and its widget test. Website worker owns the deletion page, two privacy links,
small route contract/tests and unit-test script. Root owns readiness docs,
this plan and external evidence. Their shared interface is the fixed
`/account-deletion?lang=en` URL with the same language whitelist as LegalShell.
Docs distinguish local source from live service. No worker edits another
worker's files or runs root's Flutter suite. Evidence lives in external
`public-deletion-guidance-20260910/`.

**Task 22 local verification (2026-09-10):** Flutter 7 files / **78 tests**
passed, including real-font Settings taps at 320dp/200% and the failed-browser
clipboard path. Changed Dart analysis: **5 files, no issues**. Website source
and release contracts: **16 tests passed**; after the test loader's local
variable was renamed for ESLint, the affected **8 tests passed again**.
TypeScript checked all **26 candidate files with zero diagnostics**, without
emitting a build. The first external typecheck configuration could not resolve
dependencies; the corrected compiler host exposes the matching installed
modules read-only and uses the current candidate's tsconfig and sources.
Scoped ESLint is clean after the one helper naming correction. Both independent
Standards and Spec reviews approved the final diff.

The source-render test uses the real page and LegalShell, with unrelated
Header/Footer and next/link stubs; it does not establish full-router or browser
behavior. Existing **2,383 files**, **962 assets**, and **1,095 paid Graphify
records** were preserved. Free Graphify update/prune completed. The local
commit's exact parent/tree and clean-worktree checks are recorded in external
`public-deletion-guidance-20260910/verification.json` after committing. No push,
remote CI dispatch, new app/site build, store upload, email, paid API call or
device retry was performed. Current public routing, mailbox handling, store
checker access and signed-candidate device acceptance remain open.

### Task 23: Recover the learning path without caching a failed vocabulary catalog

**Trigger at `071a7ec121c56b09e37453a093434c264ea2310d`:**
`DataLoader.loadVocab()` reports a failed corpus through `vocabError` and an
empty list. `VocabPackService.loadAll()` currently caches that list as a valid
empty catalog. A later successful corpus retry by CurriculumCatalog cannot
replace the cached pack list. Its reset also has no protection against an
older in-flight load republishing a cache. LearningPathScreen reads the legacy
projection and all six pack levels before its guarded course read; pack/store
exceptions escape, while corpus failures can look like zero available packs.
There is no actionable error/retry for those unavailable sections.

**Contract:** Keep the existing canonical course and optional additional
practice hierarchy, free access, selected-course versus independent browse
level, local progress and coaching behavior. An unavailable source is neither
a successful empty catalog nor evidence of zero progress. Do not introduce a
new framework, backend call, data migration, storage reset or asset change.

- [x] **Reproduce:** Use actual asset-channel failure/recovery for the pack
  cache and production LearningPathScreen entry where feasible. Prove a failed
  vocabulary read followed by recovery can repopulate packs without restarting
  the app. Prove reset during a pending load prevents stale cache publication.
  Cover a legacy failure without losing a usable course path, a course failure
  with usable legacy practice, and a visible retry that makes a real new read.
- [x] **Pack cache:** Keep the existing `Future<List<VocabPack>>` and fallback
  behavior for other consumers. Cache only successful corpus results, share
  concurrent grouping, and fence pending/cache ownership across `reset()`.
  Do not turn previously tolerated corpus failures into new uncaught exceptions
  for other screens. Distinguish a valid empty corpus from a failed read.
- [x] **Learning path:** Handle course and legacy availability explicitly.
  Render a resolved usable course while additional practice is still loading
  or unavailable. Catch pack/store failures, show localized retry feedback in
  the affected section, and avoid publishing partial/zero metrics as success.
  Use existing Sori components and ARB copy where suitable. Retry only failed
  vocabulary caches and display reads; never erase progress or initialize a
  replacement course. Keep raw error/private canaries out of UI. Older refresh
  completions and disposed screens must not publish stale data or errors.
- [x] **Layout and behavior:** Preserve default collapsing, legacy focus/jump,
  canonical course navigation, preview purity, scroll position, and coach
  ownership. Exercise DE/EN at 320dp/200% with real fonts and light/dark for
  affected error/recovery states. Do not put LayoutBuilder-based loading/error
  widgets under the existing collapsed IntrinsicHeight path without resolving
  that constraint. Use bounded pumps for animated states.
- [x] **Verify and record:** Run relevant service, screen, navigation and
  localization tests plus changed Dart analysis. Read the final diff and obtain
  independent Standards/Spec reviews. Preserve prior source/assets/paid graph
  records, run the free Graphify update/prune and commit only this local change.
  No push, remote CI dispatch, new app/site build, email, paid API call, device
  retry or deployment. Signed-device and real operational gates remain open.

**Ownership/consistency:** One implementer owns VocabPackService,
LearningPathScreen and focused tests; existing localization is reused unless a
specific missing user-facing message needs DE/EN ARBs and generated output.
Root owns this plan, evidence and integration verification. The service API's
empty-on-corpus-failure compatibility must be retained for inherited consumers;
the path checks availability before presenting metrics. Task 9's DataLoader
generation contract stays unchanged. A small read-only DataLoader result or
generation check is allowed to fence a vocabulary-only reset by another caller;
it must not change the existing load/reset behavior. No second implementation
edits these files.
Evidence lives in external `learning-path-recovery-20260910/`.

**Task 23 local verification (2026-09-10):** The final related Flutter
run passed **175 tests across 21 files**. Changed Dart analysis:
**5 files, no issues**. Actual asset-channel and controlled UI tests
cover failure/recovery, cache/reset ownership and usable learning-path sections;
the detailed RED/GREEN evidence and final source hashes are in external
`learning-path-recovery-20260910/worker-summary.json`. Independent Standards
and Spec reviews approved the final diff. The source checks do not establish
physical cold-start latency, memory use or signed-device behavior.

Existing **2,396 files**, **962 assets**, and **1,095 paid Graphify
records** were preserved. Free Graphify update/prune completed. The local
commit's exact parent/tree and clean-worktree checks are recorded in external
`learning-path-recovery-20260910/verification.json` after committing. No push,
remote CI dispatch, app/site release build, store upload, paid API call,
email or device retry was performed. Signed-device and operational release
gates remain open.

### Task 24: Publish only confirmed course progress after a failed write

**Trigger at `e467e21d29b4d4692c53b5cc2bac609d5bfb2b43`:** A real catalog,
the existing PreferenceStringStore boundary, and CourseProgressService's
serialized public API reproduced two failures: a rejected vocabulary write
remains visible in CourseMasteryService.snapshot; the next successful queued
write persists that rejected evidence too. Storage's strict rollback protects
its own values, but several CourseMasteryService paths assign `_snapshot`
before validation/persistence. The baseline's two tests failed behaviorally,
not during setup (`course-write-recovery-20260910/baseline-red.log`).

**Contract:** A failed write is not confirmed mastery. Keep the published
snapshot, current unit, completion and remediation state consistent with
confirmed durable evidence. A later learner action must not silently carry a
rejected answer into storage. Preserve the established course semantics and
strict persistence boundary; do not introduce a new storage format or journal.

- [x] **Reproduce and audit:** Retain the real two-case baseline and add
  focused service/queue tests for rejected/throwing writes, pending writes,
  normal recovery, and failures around validation. Inspect all mutating entry
  points: content attempts, scenario checkpoints/unlocks, course selection,
  productive evidence/project steps, empty initialization and migrations.
  Cover affected paths with meaningful public behavior assertions.
- [x] **Confirmed publication:** Validate and persist a candidate before
  publishing its snapshot or derived progress. A refused write must leave
  prior confirmed evidence/current unit/completed units/remediation intact.
  Successful writes still publish exactly the intended candidate. Failed
  initialization/migration must not leave a falsely loaded in-memory state.
- [x] **Recovery and ownership:** Keep the serialized queue usable after an
  error. Do not overwrite or treat an uncertain storage result as confirmed;
  exercise unknown-outcome/reload failure and recovery at the existing strict
  storage boundary. Require confirmation before later mutation when needed.
  Preserve account/wipe barriers and canonical-generation fences. A small
  storage recovery helper is allowed if existing APIs cannot establish the
  confirmed value; do not use test-only reset methods in production code.
- [x] **Existing contracts:** Keep typed mission eligibility, thresholds,
  evidence identity/caps, reconciliation rules, productive-proof non-unlock
  semantics, course/browse separation, read-only display and free learning.
  Do not change vocabulary SRS, XP, awards, user assets or content. Preserve
  the original error for callers; do not replace a failed write with success
  or silently retry a learner action as new evidence.
- [x] **Verify and record:** Run relevant mastery, progress, productive,
  reconciliation, storage, wipe and consumer tests with changed Dart analysis.
  Read the final diff and obtain independent Standards/Spec reviews. Preserve
  prior sources/assets/paid graph records, run free Graphify update/prune, and
  commit only this local optimization. No push, remote CI, build, paid API,
  email, device retry or deployment. Operational/device gates remain open.

**Ownership/consistency:** One implementer owns CourseMasteryService and
focused tests. CourseProgressService/Storage may change only where the
confirmed-recovery contract requires them; report the need before editing.
Root owns this plan, external evidence and final integration. Existing
strict storage rollback, generation guards and the Task14 service-loader
recovery remain authoritative. No concurrent edits to these source files.
Evidence is external under `course-write-recovery-20260910/`.

**Review ruling:** The first candidate passed 550 scoped tests, but independent
Spec review and a new real onboarding-gateway test showed that a synchronous
unknown-state assertion blocked read-before-write retries even after durable
reads recovered. Confirm through the owning service within serialized capture
and repair before reading; preserve read-only behavior and the normal empty
capture fast path. First-candidate source, tests and reviews are retained in
external `course-write-recovery-20260910/revision1/`; fix and re-review this
recovery requirement before committing.

**Task 24 local verification (2026-09-10):** The original two public
queue tests failed on the unchanged `e467e21d` baseline and passed with the
final source. The related Flutter run passed **556 tests
across 60 files**; changed Dart analysis checked
**6 files with no issues**. Candidate publication,
strict write failure/recovery, uncertain durable state, course advancement,
productive non-unlock, read-only capture, reconciliation and wipe boundaries
are covered by the recorded scoped regression suite. This is not full CI or
signed-device evidence. Independent Standards and Spec reviews approved the
final diff. Exact tests and source hashes are recorded externally under
`course-write-recovery-20260910/`.

Existing **2,397 files**, **962 assets**,
and **1,095 paid Graphify records** were preserved.
Free Graphify update/prune completed. The local commit's parent/tree and
clean-worktree checks are in `course-write-recovery-20260910/verification.json`.
No push, remote CI dispatch, app/site release build, store upload, paid API
call, email or device retry was performed. Operational and signed-device
release gates remain open.

### Task 25: Integrate approved Phase and pack artwork with local recovery fixes

**Fixed inputs:** Local `e8b12cd7bd350e0e84ea57246414c8d1681aa008`
contains verified course and onboarding write recovery through Task24.
Incoming main `7af0c01e8b5532cc17d8da63a01c9ac735778eca` is merged PR #298;
the common ancestor is `8185cca7334348e52edac8464ddac6de49b97b81`.
The primary checkout has concurrent artwork cleanup and other user work.
Integrate only the committed incoming state in this isolated worktree.

- [x] **Pin and preserve:** Capture both parents and their Graphify records,
  prior source/asset hashes and paid graph records. Confirm PR #298 merge and
  the existing exact-main CI/Playwright results without starting any workflow.
  Preserve primary-checkout work and earlier local commits.
- [x] **Compose the changes:** Merge the 30 dedicated Phase and 22 dedicated
  pack images, mappings, manifests and validators from #298. Keep incoming
  files byte-identical except the shared LearningPhaseCatalog, which must also
  retain the local `cache: false` failed-read recovery. Preserve course storage,
  onboarding retry, free learning and all unrelated local stabilization.
  Rebuild only free Graphify metadata after preserving both parent versions.
- [x] **Verify the image contract:** Confirm all 52 runtime image hashes,
  dimensions and declared paths against the incoming production records.
  Verify Phase metadata changes only its artwork paths, pack mappings retain
  existing coverage, and new assets are registered. Inspect the existing
  contact sheets and representative runtime files without generating or editing
  images; distinguish inherited design approval from this integration check.
- [x] **Verify behavior and integration:** Run relevant asset/Phase/pack,
  learning-path, cache recovery and course/onboarding recovery tests, the
  incoming Python content/visual-contract checks, and changed Dart analysis.
  Obtain independent Standards and Spec reviews of the composition and fix
  actionable findings before committing. Do not call a scoped suite full CI.
- [x] **Record the exact local result:** Finish free Graphify update/prune,
  verify the two-parent merge and clean worktree, and update the local readiness
  artifact. No push, remote CI dispatch, new app/site release build, store
  upload, provider/paid API call, image generation, email or device retry.
  Signed-device and operational readiness gates remain open.

**Ownership:** Root owns the local merge, composition checks, plan and evidence.
Reviewers read frozen files independently. Evidence is external under
`phase-artwork-integration-20260910/`. Existing source and image approvals are
preserved; this task does not authorize unrelated asset promotion or cleanup.


### Verification evidence

2026-09-10 로컬 후보의 검증 결과다. 서로 겹치는 실행 횟수는 더하지 않는다.

| 검사 | 결과 | 범위와 한계 |
| --- | --- | --- |
| PR 이전 Flutter 회귀 | 24파일 207/207 | TTS와 일부 로딩·소비 화면·시작·동의 보호 검사. PR의 더 넓은 225파일 검사에서 발견된 13개 회귀는 Task 7에서 수정 |
| Task 7 로딩 회귀 | 13파일 830/830, 수정 4파일 분석 무문제·형식 변경 0건 | 실제 intrinsic-parent 검사 RED 0/-1 후 GREEN 1/1. 후속 수정은 두 축 및 correctness 독립 리뷰 승인. 새 PR head의 원격 검사는 별도 |
| 정적 분석·형식 | 전체 analyze 무문제, 후속 로딩 수정 3파일 재분석 성공, 수정 Dart 8파일 형식 일치, diff 공백 검사 성공 | 로컬 Flutter 3.44.8 / Dart 3.12.2. CI는 Flutter 3.44.0 |
| 서버 TTS | Node 22.23.2 전체 64/64 | handler 오류 주입과 개인정보 canary, quota·재실행·계정 경계 포함 |
| 릴리스 웹 | 빌드 성공, Playwright 6/6 | Chromium·Firefox·WebKit 각각 390×844 / 1440×960의 동의 화면 시작·그리기. production 요청 차단 |
| 수동 화면 | DE 동의·Today·미션 데모, 1280×720 및 320×640 관찰. 데모 뒤로 가기·닫기 확인 | fixture 데이터와 무동작 학습 콜백. 실제 음성·학습 완료·계정·진척 저장 증거가 아님. 임시 viewport 복원 |
| 릴리스 도구 | Python release integrity / Android evidence / tools config 78/78, iOS 설정·스토어 계약 2종 성공 | 서명 AAB/IPA 생성이나 업로드 검사가 아님 |
| 심볼 도구 pin | 기존 네 버전의 publisher archive 검증 및 정확한 실행 파일 SHA256 대조 성공. 설정 반영 후 기존 Python 검사 78/78 | Linux x64 Java/Node와 npm firebase-tools entry, Google bundletool JAR. gate 활성화·심볼 업로드는 별도 |
| 기존 Android 2278 | 7e844d1b 업로드 실행 34414481048 성공. AAB checksum·서명 검증·bundletool validate 성공. Console Alpha 18 검토 중, 기존 16 제공 중 | 이 작업의 미커밋 수정은 포함되지 않음. 서명 인증서를 Play 인증서와 대조하거나 기기에 설치한 검사는 아님 |
| 2278 크기·정렬 | Console 신규 설치 296MB·업데이트 11.1MB·16KB 지원 표시. 두 수동 기기 설정의 예상 다운로드 293,645,333 / 295,347,057 bytes. 64비트 native 12개 LOAD 정렬 및 생성 split APK 10개 zipalign 성공 | Console 표시값·bundletool 추정값과 정적 16KB 검사. 실제 다운로드·기기 실행을 측정한 결과가 아님 |
| 빌드 입력 | #293 반영 전후 런타임·테스트 Git 객체와 수정 파일 SHA256 동일 | `post-293-runtime-equivalence.json`. 웹 선언 에셋·글꼴 887개 누락 없음 |
| 최종 독립 리뷰 | 기존 구현과 추가 Task 6 모두 Standards APPROVED / Spec APPROVED, 각각 행동 가능한 지적 0건 | 기존 14파일 승인 뒤 추가 3파일·갱신된 계획/설계/HTML을 직접 대조. 앱·테스트 12파일 해시는 유지됨. 추가 도구 pin의 correctness/security도 승인 |

검증 로그·빌드 지문·시각 보고서는
`C:/dev/hangulsori/_codex_artifacts/global-launch-readiness-20260909/`에 보존했다.
기존 릴리스 계약 로그는 상위 `_codex_artifacts/global-launch-release-contracts-20260909.log`다.
PR #294의 첫 커밋은 `24a77f79`다. Task 7 이후 최신 head의 원격 CI와 서명·기기 검증 결과는
해당 PR 및 외부 검증 영수증을 확인한다. 기존 main CI와 2278 업로드는 이 후보의 증거가 아니다.

**Task 25 local verification (2026-09-10):** Approved incoming bytes for
all 30 Phase and 22 pack images match their production records (RGB WebP,
800x600). Phase semantics are unchanged except artwork paths; dedicated
pack coverage is 184 of 224, with 40 shared images remaining. Existing
contact sheets and two runtime samples were inspected; this does not
re-certify inherited semantic design approval or original source archives.

The combined local candidate passed 351 Flutter tests
in 37 files, 15 Python contract tests,
the card-style gate, and analysis of 6 changed Dart files.
Independent Standards and Spec reviews approved the frozen source. The
sole shared-file composition retains cache:false recovery. All 2,467 frozen
source files and 1,095 paid Graphify records were verified; both parent
Graphify records were preserved before free update/prune. Existing upstream
#298/main CI success is separate from this scoped local verification.

Exact merge parents, clean-tree proof and checks are recorded externally
in phase-artwork-integration-20260910/verification.json after the local commit.
No push, remote CI dispatch, new release build, upload, paid call, image
generation or device retry. Signed-device and operational gates remain open.


### Task 26: Keep failed course scenario completion retryable

**Baseline:** `c144bcf1be70faced1047beb8f79023223cf1606`, clean isolated
worktree after Task25. The production player called the best-effort course
reporter after reward writes and accepted its null failure as a saved result.
A real player test reproduced a completion callback after a failed typed
course checkpoint; unlinked free practice is the passing control.

- [x] Preserve the baseline, source/asset and paid Graphify hashes. Reproduce
  the failed course checkpoint in the real player with no result-persister
  replacement; keep free browsing functional without a course graph.
- [x] Prepare course evidence and the result projection before writing XP,
  stars or completion. Require a saved update when an explicit or inferred
  course context exists. Retain a successful checkpoint if result projection
  fails, share concurrent preparation, and retry failed preparation. Mark
  lesson tracking complete and give success haptics only after persistence.
- [x] Verify failed completion exposes retry without success callback/reward;
  recovering the course write completes once. Verify projection retry does
  not duplicate the saved checkpoint, and preserve free practice, scoring,
  onboarding callbacks and course eligibility rules.
- [x] Run focused and related scenario/course/onboarding tests and changed
  Dart analysis; obtain independent Standards and Spec reviews of frozen
  source and address actionable findings. Do not call scoped tests full CI.
- [x] Finish free Graphify update/prune and an authorized local commit;
  verify the exact parent/tree, preservation hashes and clean worktree, then
  update the local readiness artifact. No push, remote CI, new app/site build,
  upload, paid API, image generation, secret operation or device retry.

**Remaining launch scope:** This fixes the course/result preparation boundary.
The legacy reward writes still use separate XP, stars, badge and SRS writes;
rejected or indeterminate writes inside those operations require a separate
durability audit. This task does not claim whole-result atomicity or device
validation, and does not change reward policy or storage schema.

**Validation follow-up:** The expanded speech-stub guard exposed two existing
loader-recovery tests missing complete speech stubs. Add the standard speech
stub to their setup and include both files in the regression run; preserve
the guard and its existing allowlist.

**Ownership:** Root owns the two production files, four regression files and
plan. Independent reviewers read frozen source. External evidence is under
`scenario-completion-recovery-20260910/`. Primary-checkout work remains untouched.

**Task 26 local verification (2026-09-11):** The baseline real-player
test called completion after a failed typed course checkpoint (actual 1,
expected 0); the unlinked free-practice control passed. The final player
keeps failed course completion retryable and recovery grants the result
once. Preparation tests cover failed checkpoint retry, projection retry
without a second checkpoint, concurrent calls and free practice.

The scoped suite passed 446 Flutter tests in
57 files. Analysis of 6
changed Dart files reported no issues. Standards and Spec approved all six
frozen Dart files. The initial wider run caught missing speech stubs in two
earlier loader-recovery tests; the standard helper was added and the guard
passed unchanged on rerun. Initial failure evidence is preserved in revision1/.

All 2,470 frozen source files, 1014 existing assets,
and 1,095 paid Graphify records were verified.
Free Graphify update/prune completed. Exact local commit/parent/tree and
clean-worktree proof are recorded externally in
scenario-completion-recovery-20260910/verification.json after the commit.
No push, remote CI, release build, upload, paid call or device retry.
Remaining reward-write durability and signed-device/operational gates stay open.

### Task 27: Recover rejected and unknown scenario reward writes

**Baseline:** `57c7f120650af371188fda13a4bccdfb795204c8` in the isolated
worktree. Native preferences can reject a write after the plugin updates its
optimistic cache. Baseline tests reproduced stars, completion and badges
returning success despite native rejection.

- [x] Preserve baseline source, assets and paid Graphify records and reproduce
  native rejection through the real preferences platform boundary.
- [x] Serialize and strictly confirm stars, completed-scenario and badge writes.
  Add an optional scenario-attempt receipt map to the existing XP ledger so
  retrying the same result pays once. Preserve genuine replay rewards, zero XP,
  older ledger compatibility, listening claims and daily XP accounting.
- [x] Keep unknown writes unpublished until reload confirms their outcome.
  Fence reset against admitted and newly arriving reward writes. Reuse the
  player attempt identity on retry, check local-data lifetime between stages,
  and avoid repeating successful failed-quest SRS updates within that attempt.
- [x] Verify rejected/unknown outcomes, concurrency, reset and real-player retry;
  run related storage, deletion, migration, scenario and course regression tests,
  changed Dart analysis and independent Standards and Spec reviews.
- [x] Finish free Graphify update/prune and an authorized local commit, verify
  parent/tree and preservation, and update the existing local readiness artifact.
  No push, remote CI, build, upload, paid call, secret operation or device retry.

**Limits:** This is sequential recovery, not whole-result atomicity. Scenario
attempt IDs live with the player; process-death resumption is not introduced.
Existing best-effort SRS false/unknown outcomes and ordinary addXp daily-counter
atomicity remain separate audit work. Learning stays free and cloud scoring off.

**Ownership:** Root owns storage_service.dart, scenario_player_screen.dart,
five regression tests, the test preferences platform and this plan.
Reviewers read frozen source only. Evidence: scenario-reward-durability-20260911/.

**Task 27 local verification (2026-09-11):** Native rejection initially
returned success for stars, completed scenarios and badges (three failures).
Review regressions reproduced pending list publication, delayed successful
writes surviving reset, and unknown completion suppressing listening reward
(five failures). All were fixed. The first broad run also caught two cache
tests resetting Storage without reinitializing it; their setup was corrected.
Initial evidence remains in revision1/ and review-regressions-red.log.

Final scoped verification passed 803 Flutter tests
in 86 files; 8 changed
Dart files analyzed without issues. Both independent review axes approved the
frozen files. All 2,473 frozen source files, 1014
assets and 1,095 paid Graphify records were checked.
Free Graphify update/prune completed. Exact commit/parent/tree and clean-state
proof are external in scenario-reward-durability-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. Best-effort SRS
unknown outcomes, ordinary XP daily-counter atomicity and signed-device and
operational launch gates remain open.

### Task 28: Keep failed scenario SRS evidence retryable

**Baseline:** `595240723d49741baa35e89f3d22419fb6914e52`. Scenario
completion ignores a false SRS save result. Successful entries are remembered,
but unknown native outcomes cannot be reliably classified by that set.

- [x] Preserve the clean baseline and source/asset/paid Graphify records;
  reproduce failed-quest SRS rejection being treated as saved completion.
- [x] Introduce a reusable, session-local SRS review attempt. Remember its
  confirmed primary write separately from the optional daily log. Retain the
  exact before/candidate snapshot for an unknown write; resolve it against
  native storage before another SRS mutation, preserving unrelated cards.
- [x] Require failed-quest SRS persistence before the player's success callback
  and XP. Reuse attempts on retry. Drain SRS alongside rewards during reset,
  reject new admissions, and invalidate old attempts after reset/restore.
  Preserve SM-2, direct-target-only negative evidence and legacy boolean calls.
- [x] Verify rejection, committed/uncommitted lost replies, delayed resets,
  genuine repeated judgments, daily-log retry and real-player recovery; run
  related regression tests, changed Dart analysis and independent reviews.
- [x] Complete free Graphify update/prune, local commit and exact evidence,
  retaining the deployment hold. No push, remote CI, build, upload, paid call,
  secret operation or device retry.

**Limits:** Attempts are session-local and do not introduce process-death
resumption or a whole-result transaction. Ordinary XP daily accounting and
signed-device/operational readiness remain separate open requirements.
Evidence: scenario-srs-durability-20260911/. Root owns implementation/tests;
independent reviewers inspect frozen source. Primary checkout is untouched.

**Task 28 local verification (2026-09-11):** The baseline helper ignored
native SRS rejection and returned successful completion (one failing test).
Review reproduced two unknown daily-log outcomes and three delayed-write
restore races (five failures), then a rejected-restore cache resurrection
(one failure). All reproduced failures were corrected. Earlier frozen runs
and independent review findings remain in revision1/ and revision2/.

Final scoped verification passed 912 Flutter tests
in 90 files (842 in the main scoped run plus 70
additional quarantine-recovery and account-reconciliation caller tests); 5 changed
Dart files analyzed without issues. Both independent review axes approved.
SRS attempts retain primary-save state, recover indeterminate writes before
new judgments, and retry daily logs without repeating primary evidence.
Deck replacement and quarantine reset share the SRS queue; failed replacement
cannot publish a retired cached review. Explicit raw setters now confirm writes.
All 2,474 frozen source files, 1014 assets and
1,095 paid Graphify records were checked. Free
Graphify update/prune completed. Exact commit/parent/tree and clean-state proof
are external in scenario-srs-durability-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. Ordinary XP daily
accounting, process-death attempt resumption and signed-device/operational
readiness remain open; this is not whole-result atomicity or full CI.

### Task 29: Commit ordinary XP and its daily total together

**Baseline:** `f96169a723514b97d860401bc6baf4c2b2ba84e0`. Ordinary
awards persist total XP and daily counters separately. A rejected daily write
leaves an apparently successful award with mismatched durable totals.

- [x] Preserve the clean baseline and source/asset/paid Graphify hashes;
  reproduce native rejection leaving total XP updated but daily XP unchanged.
- [x] Extend the existing XP ledger with an optional bounded ordinary-day
  snapshot. Commit total and daily delta in one confirmed value, read older
  legacy counters until migrated, preserve listening/scenario claims and
  zero/negative adjustments, and treat the ledger as authority over mirrors.
- [x] Provide a session-local XP award attempt that resolves unknown native
  outcomes before retry or another mutation. Retain the earned date without
  allowing an older retry to replace a newer day's total. Reuse one attempt
  for the default vocab-pack finish adapter's immutable request. Preserve
  reset/restore lifetime fences and avoid a growing per-award receipt map.
- [x] Verify rejection, lost replies, retry, rollover, concurrent awards,
  migration, mirrors, reset and the production vocab adapter. Run related
  regression tests, changed Dart analysis and independent Spec/Standards review.
- [x] Complete free Graphify update/prune, local commit, preservation proof
  and local readiness evidence. No push, remote CI, build, upload, paid call,
  secret operation or device retry.

**Remaining scope:** General game-result error/retry presentation and
process-death session resumption need separate validation. This task proves
the XP storage boundary and vocab adapter retry, not whole-result atomicity,
full CI or signed-device/operational readiness. Evidence is under
ordinary-xp-durability-20260911/; primary checkout remains untouched.

**Task 29 local verification (2026-09-11):** The baseline returned success
with total XP 110 but daily XP 5 instead of 15 after a rejected daily write.
The final optional ordinary-day snapshot commits the daily amount and total
in the same XP ledger value. Legacy counters seed the first ordinary award;
existing listening/scenario claims remain independent daily contributors.
Reusable session attempts resolve unknown native writes without duplicate
awards, including the production vocab-pack adapter. The confirmed ledger
outranks failed legacy mirrors, and daily state stays bounded to one snapshot.

Final scoped verification passed 1283 Flutter tests
in 148 files. Analysis of 4
changed Dart files had no issues; independent Standards and Spec approved.
All 2,475 frozen source files, 1014 assets and
1,095 paid Graphify records were preserved. Free
Graphify update/prune completed; exact local commit/parent/tree and clean-state
proof are external in ordinary-xp-durability-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. General game
result error/retry presentation and process-death session resumption remain
separate work, alongside signed-device and operational readiness.

### Task 30: Confirm review judgments and XP before advancing the screen

Baseline: `fb68409cde9b8ce0086e8320556c1ae30ae14e91`. ReviewSessionScreen
discards SRS and XP futures and announces completion even when native storage
rejects the judgment. Apply the existing retryable storage attempts to this
production learning flow, preserving deck order and one bounded wrong repeat.

- [x] Reproduce rejected SRS showing false completion in the real screen.
- [x] Await confirmed SRS/study-log evidence before advancing; retain the same
  judgment and final XP attempt across retry. Only show completion and feedback
  after XP confirmation. Prevent double taps, stale callbacks and post-exit work.
- [x] Show localized, accessible saving/failure states using existing Sori
  components. Keep close/home exits, respect reset lifetime, and preserve
  existing bounded repeats, history navigation and reward amount.
- [x] Test native rejection, lost acknowledgement, retry, daily-log failure,
  double input, route exit and reset plus related review/storage regressions.
  Run analysis and independent Spec/Standards reviews of the final source.
- [x] Update free Graphify, verify preservation and commit locally. No push,
  new build, deployment, paid calls or device retry.

Wrong-count diagnostics retain their existing best-effort storage contract;
they are attempted once per judgment, never retried as primary SRS evidence.
General game screens and process-death session resumption remain open work.

**Task 30 local verification (2026-09-11):** The real review screen
showed no failure state after native SRS rejection. It now waits for confirmed
SRS and daily-log evidence before advancing and confirmed XP before completion
or feedback. Retained attempts resume the same judgment and XP award. Native
lost replies, rejected writes, double input, leave/reset and bounded repeats
are covered. Independent Spec review exposed an old feed callback targeting
the next card; its failing reproduction is preserved and presentation-bound
callbacks now reject it, including after the next card is revealed.

Final scoped verification passed 280 Flutter tests
in 28 files. Analysis of 2
Dart files had no issues; both independent review axes approved the final
source. All 2,476 frozen source files, 1014 assets
and 1,095 paid Graphify records were checked.
Free Graphify update/prune completed. Exact commit/parent/tree and clean-state
proof are in review-session-durability-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. Wrong-count
diagnostics retain their best-effort storage contract. General game-result
recovery, process-death resumption and signed-device/operational readiness
remain open; this does not prove whole-session atomicity or commercial readiness.

### Task 31: Recover shared game completion and daily rewards

Baseline: c1a90ec5a4c6ea26be710e50e3f97894d5595f8b. Native rejection was
ignored by personal-best writes, and daily completion used separate markers.
Eight callers of recordGameResult lacked a common save/retry presentation.

- [x] Preserve baseline and reproduce false personal-best success and lost
  daily completion after rejected native writes.
- [x] Retain XP and personal-best attempts per round, hide pending best values,
  serialize writes/reset, and resolve unknown native outcomes before retry.
  Store daily bonus, completion date, streak and XP in the same bounded ledger
  snapshot; preserve prior listening/scenario claims and legacy daily state.
- [x] Use a shared saving/retry frame in all eight recordGameResult callers:
  cloze, satz arcade, speed match, custom quiz/typing/matching, chosung and
  daily challenge. Confirm persistence before feedback/celebration/results.
  Preserve reward amounts, new-round ownership, accessible Sori exits and
  cancellation of downstream work after leaving/resetting.
- [x] Test native failure/unknown outcomes, concurrent retries/daily awards,
  legacy migration, reset/exit, real screen completion and replay, plus related
  regressions; analyze final changes and get independent Spec/Standards review.
- [x] Update free Graphify, verify preservation, commit and refresh local
  evidence. No push, build, remote CI, paid call, deployment or device retry.

The separate hard-choice, kkeunmari and silben award paths, per-question SRS
and diagnostic writes, and process-death round resumption remain subsequent
work. XP and best confirmation are ordered stages, not one whole-game atomic
transaction; daily bonus and its completion receipt are one atomic value.

**Task 31 local verification (2026-09-11):** Native best rejection
returned a successful record; separate daily markers could lose completion.
Shared GameResultAttempt and recovery UI now retain XP/best stages across retry
in all eight prior recordGameResult callers. Daily base XP, first-day bonus,
completion date and streak commit in the same bounded XP ledger snapshot.
Existing listening/scenario claims and legacy state remain readable.

Further reproductions caught unknown and definitely rejected best attempts
falsely claiming records after being overtaken, spring-DST streak reset,
late completion after reset and missing normal-frame exit retirement. The
corrected source preserves record ownership, uses calendar yesterday, captures
the screen's data lifetime and retires every normal/recovery study-frame exit.
Earlier sources, review findings and logs remain under revision1/.

Final scoped verification passed 1352 Flutter tests
in 153 files; 13 changed
Dart files analyzed without issues. Standards and Spec approved final source.
All 2,479 frozen source files, 1014 assets and
1,095 paid Graphify records were checked. Free
Graphify update/prune completed. Exact commit/parent/tree and clean-state proof
are external in game-result-durability-20260911/verification.json.
No push, remote CI, new build, upload, paid call or device retry. Separate
hard-choice/kkeunmari/silben award paths, per-question SRS/diagnostic durability,
process-death resumption and signed-device/operational readiness remain open.
XP/best are ordered stages, not one whole-game atomic transaction.

### Task 32: Confirm remaining standalone game rewards before completion

Baseline: 099bb80927f6ae0d62a9ea630a44f0a1297ecdee. Hard-choice,
kkeunmari and silben still fire-and-forget their completion rewards.

- [x] Reproduce real-screen completion after native XP rejection and preserve
  the clean baseline, previous source and paid Graphify records.
- [x] Connect all three screens to retained game-result saving/retry. Preserve
  reward amounts, puzzle progress, new-round ownership, accessible exits,
  feedback timing and reject stale input after exit/reset or presentation change.
- [x] Store kkeunmari wins with the same XP ledger snapshot, preserving legacy
  counts and other reward claims. Retries must not duplicate wins or XP;
  losses earn existing XP without a win increment.
- [x] Verify real screen rejection/unknown writes, best/progress failure,
  repeated input, replay, loss, reset/exit and retained stale callbacks. Run
  related regressions, analysis and independent Standards/Spec review.
- [x] Complete free Graphify update/prune, preservation checks and local commit.
  Keep push, remote CI, new builds, uploads, paid calls and device retries held.

Per-question SRS and diagnostic durability, process-death round resumption,
signed-device and operational readiness remain distinct unfinished work.
XP/win count are atomic; personal-best/puzzle-progress confirmation remains
an ordered second stage with retry, not an atomic whole-game transaction.

**Task 32 local verification (2026-09-11):** All three real screens
failed the native-XP rejection reproduction. Hard-choice, kkeunmari and silben
now retain saving/retry attempts and confirm persistence before publishing
completion, feedback or navigation. Existing reward amounts are preserved.
Kkeunmari win counts and XP commit together, including legacy migration,
lost native acknowledgement, concurrent wins and compatibility increments.
Personal-best and puzzle progress remain a confirmed second stage.

Retained input is rejected after exit/reset or a new question/puzzle/round.
Replay admits a fresh award while repeated old navigation cannot skip rounds.
Tests cover real screens, rejection, unknown writes, best/progress failure,
loss, replay, stale input, legacy and malformed state, plus quest/UI regressions.
Standards review found unbound old load-retry callbacks in both loader screens;
two failing real-screen reproductions are preserved in load-retry-red.log.
Retry admission and late load success/error now require the current error
generation and local-data lifetime. Earlier reviewed source and evidence are
retained under revision1; final reviews apply to the corrected frozen source.
Final scoped verification passed 1410 Flutter tests
in 157 files; 8 changed
Dart files analyzed without issues. Standards and Spec approved final hashes.
All 2,481 frozen source files, 1014 assets and
1,095 paid Graphify records were checked.
Free Graphify update/prune completed. Exact local commit/parent/tree proof is
external in separate-game-rewards-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. Per-question
SRS/diagnostics, process-death resumption and signed-device/operational readiness
remain open; this does not prove whole-game atomicity or commercial readiness.

### Task 33: Confirm vocabulary-pack SRS evidence before advancing

Baseline: 83b3674e8819a72586a064a9741fbbfc73abdf7e. The main pack
learn/recognition path discards SRS futures; typed recall exposes Next before
the write completes. Both reserve session evidence before durable success.

- [x] Preserve the current source and reproduce native SRS rejection in both
  real screens, including missing recovery and premature session evidence.
- [x] Retain one SRS attempt per accepted judgment and update the session
  coalescing ledger only after SRS plus daily study-log confirmation. Preserve
  first-positive/terminal-negative rules, route ownership and practice-only
  behavior; recover unresolved writes before later session judgments.
- [x] Add accessible saving/retry to pack learn/recognition and typed recall.
  Gate advancement/feedback, retained callbacks, load retries and exit/reset.
  Preserve card reveal/defer, hint/no-evidence, grading and reward rules.
- [x] Test native false/unknown writes, study-log failure, retries, session
  coalescing, stale controls, practice-only routes, load ownership and exit/reset.
  Run related regressions, analysis and independent Standards/Spec reviews.
- [x] Complete free Graphify/preservation checks, update local evidence and
  commit locally. Keep push, CI dispatch, build, deployment and paid calls held.

Other game/custom/legacy question-level SRS callers, seen-word and wrong-count
diagnostics, recognition-course attempt persistence, process-death resumption
and signed-device/operational readiness remain separate unfinished work.

**Task 33 local verification (2026-09-11):** Main pack learning and
typed recall failed the native-SRS rejection reproduction. Both now retain a
judgment until its SRS card and daily study log are confirmed, then publish
session coalescing state. Unknown outcomes are reconciled before another
judgment; retries preserve first-positive and terminal-negative semantics.
Main recognition also waits before feedback, scoring and its advance timer.
Practice-only/mismatched routes and hint-only answers retain no-evidence rules.

Shared saving/retry UI holds input and allows exit. Presentation and load
generations reject old answer, Next, flip, defer and load-retry callbacks.
Local-data lifetime and screen retirement reject continuation after reset
or exit. Spec review found that real system pop bypasses the frame leave
callback while the route remains mounted during its reverse transition.
Four failing real-route reproductions are retained in route-pop-red.log.
The shared recovery mixin now captures the route and checks isActive for
admission/currentness and retries, without blocking temporarily covered routes.
The corrected focused run passed 36 tests; the final suite also includes two
pending-write route-pop cases. Prior source/reviews are preserved in revision1.
Both reviewers then identified a partial-Learn cleanup regression: the route
check also suppressed the preexisting dispose flush. A real two-word pack test
failed with missing progress after learning one card and popping. A separate
cleanup-only lifetime guard preserves already accepted progress while keeping
new judgment admission route-bound and reset-safe. The focused run passed 39
tests; partial-progress-red.log and revision2 preserve the intermediate evidence.
Known/unknown native failures, daily-log failures, coalescing,
concurrent/repeated retries, recognition timers and stale controls were tested.
Three prior timer tests were updated to wait for asynchronous confirmation;
their cancellation and scheduling assertions are unchanged.
Final scoped verification passed 800 Flutter tests
in 70 files; 7 changed
Dart files analyzed without issues. Standards and Spec approved final hashes.
All 2,484 frozen source files, 1014 assets and
1,095 paid Graphify records were checked.
Free Graphify update/prune completed. Exact local commit/parent/tree proof is
external in pack-srs-durability-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. Other question
SRS callers, seen/wrong diagnostics, recognition-course attempt durability,
process-death resumption and signed-device/operational readiness remain open.
This does not establish whole-lesson atomicity or commercial readiness.

### Task 34: Preserve custom-wordbook learning evidence through storage recovery

Baseline: a97d94e6c9dd5e99e9753150fdbb08688fe59af3. Custom play, quiz,
typing and matching discard SRS persistence futures. Matching reserves its
negative-evidence marker before confirmation, suppressing later retries.

- [x] Preserve current source/assets and reproduce native SRS rejection in all
  four real custom-pack screens before introducing recovery.
- [x] Retain each accepted SRS attempt until both card and daily log are
  confirmed, then publish feedback, score, advancement and matching evidence.
  Preserve matching first-negative/no-later-positive rules, flip/reveal/defer,
  locale grading, wrong-count semantics and existing game reward amounts.
- [x] Reuse accessible study-evidence recovery; gate old question/selection/
  round callbacks, delayed advancement, replay, editing, exit and data reset.
  Keep game-result and per-answer recovery coherent. Apply the verified
  popped-route/retry-ownership guards to their shared game reward recovery.
- [x] Test false/unknown card/log writes, repeated retries, matching mistakes,
  replay, stale input, system pop, exit/reset, existing layout and game rewards.
  Fix the observed stale matching highlight and the three existing viewport
  guard failures in kkeunmari/chosung using the shared scroll/fill layout.
  Keep short-screen and keyboard controls reachable without relaxing guards.
  Run scoped regression, analysis and independent Standards/Spec reviews.
- [x] Complete free Graphify/preservation checks, update local readiness
  evidence and commit locally. Keep push/CI/build/deployment/paid calls held.

Other game/legacy question SRS callers, seen/wrong diagnostics, process-death
resumption and signed-device/operational readiness remain separate unfinished
work. This task does not establish whole-session transactional atomicity.

**Task 34 local verification (2026-09-11):** All four custom-pack
screens failed native-SRS rejection reproductions. Play, quiz, typing and
matching now retain accepted SRS attempts through retry and confirm the card
and daily study log before feedback, scores or advancement. Matching publishes
its first-negative marker only after confirmation and retains the rule that
later correction cannot overwrite that round's negative evidence.

Presentation and round guards reject stale judgments, selection, automatic
advance, replay and old result navigation. Exit/reset and popped-route tests
cover accepted pending writes and retired input. Editor return immediately
uses the saved target; optional catalog enrichment is generation-bound and
does not hold input locked. Four shared reward reproductions also failed on
system-pop admission/publication and old-round retry ownership. The shared
reward mixin now checks its captured route and binds retry to its attempt;
temporary dialogs do not retire an accepted completion.

Tests include native false/unknown card and log writes, unavailable reloads,
double retries, matching coalescing, two complete rounds, editor return,
retained result navigation and previous layout/locale/reward contracts.
The first focused run passed 54 cases. Standards review then reproduced a
stale red matching tile after an immediate new selection; clearing the old
feedback on selection passed the new regression. The broader suite exposed
three vertical-fill failures in kkeunmari/chosung. Shared viewport-filling,
scrollable centered content fixed them without relaxing the existing guards.
All five focused feedback/layout cases passed. Final scoped verification passed
1738 Flutter tests in 104 files;
9 changed Dart files analyzed without issues.
Independent Standards and Spec approved the final source hashes.
All 2,486 frozen source files, 1014 assets and
1,095 paid Graphify records were checked.
Free Graphify update/prune completed. Exact local commit/parent/tree proof is
external in custom-pack-srs-durability-20260911/verification.json.
No push, remote CI, build, upload, paid call or device retry. Other game/legacy
question SRS callers, seen/wrong diagnostics, process-death resumption and
signed-device/operational readiness remain unfinished. Previously admitted
native operations may complete after exit; this is not a transactional
rollback or whole-session commercial-readiness claim.

### Task 35: Confirm quiz answer evidence before feedback and advancement

Baseline: 443a2727ad55f9cb5d3ce0f2016026bc6463a3d1. Chosung, cloze,
daily challenge and hard-choice quizzes discard the SRS persistence result.

- [x] Preserve current source/assets and reproduce native SRS rejection on
  all four real screens, including chosung skip.
- [x] Retain the accepted SrsReviewAttempt and confirm both card and daily log
  before score, speech, feedback, diagnostics and automatic advancement.
  Reuse StudyEvidenceRecovery and preserve exact grading, rewards and the
  cloze/daily first-attempt-only rule. Chosung duration measures the answer
  time captured before disk I/O; retries do not inflate duration or counts.
- [x] Bind judgments, skip/next, delayed feedback, replay/close, level/group
  and mode/input callbacks to their current question/round. Respect pending
  evidence, game rewards, exit/reset and popped routes. Late loads/sheet
  returns must not replace the current round or admit retired input.
- [x] Verify false/unknown card/log writes, repeated retry, correction after
  first failure, lifecycle/retained callback races, replay, grading, audio,
  course reporter cardinality and existing small/large-screen layout.
  Run appropriate related regression and independent Standards/Spec reviews.
- [x] Complete free Graphify and preservation checks, update local readiness
  evidence and commit locally. Keep push/CI/build/deployment/paid calls held.

Scope: these four screen adapters and meaningful tests; shared persistence
primitives already verified in Tasks 28/33/34 stay unchanged unless a new
failure proves a shared defect. Cloze's existing course reporter is invoked
once after confirmed first-attempt SRS, but transactional course-mastery
recovery remains a separate open audit alongside satz/other callers.
Timed games, legacy flashcards, best-effort diagnostic persistence,
process-death recovery and signed-device/operational readiness remain open.
This is not a whole-session atomicity or commercial-readiness claim.

**Task 35 local verification (2026-09-11):** Native SRS rejection failed
five reproductions on chosung answer/skip, cloze, daily and hard-choice quiz.
Each accepted judgment now retains its SRS attempt and confirms card plus
daily log before score, feedback, speech and advancement. Retry does not
repeat confirmed evidence or promote a corrected first-negative answer.

Question/round guards reject stale input, skip, next, replay, filters and
result navigation; popped routes, pending writes and data reset remain
fenced. Chosung captures answer duration before disk I/O. Cloze's existing
course reporter remains once per first accepted answer after confirmed SRS.
This preserves its cardinality, not transactional course-mastery recovery.

The focused failure/recovery/lifecycle suite passed 62 cases. The existing
audio harness now initializes storage and waits for the actual answer reveal;
its original speech-count, placement and tap assertions remain intact.
The combined recovery/audio suite passed 65 cases. Final scoped
verification passed 1701 Flutter tests
in 91 files; 6 changed
Dart files analyzed without issues. Independent Standards and Spec approved
the final actual source hashes. All 2,487 frozen source files,
1014 assets and 1,095 paid Graphify
records were checked. Free Graphify update/prune completed; exact local
commit/parent/tree proof is external in
game-answer-srs-durability-20260911/verification.json.

No push, remote CI, build, upload, paid API call or device retry. Timed games,
legacy flashcards, transactional course/diagnostic persistence, process-death
resumption and signed-device/operational readiness remain unfinished.
Previously admitted native writes may complete after exit; no whole-session
rollback or full commercial-readiness claim is made.

### Task 36: Preserve timed-game answers through storage recovery

Baseline: 8aca95fe137c8961a90a28220df5f618ac286af0. Speed Match correct
and first-wrong pairs and vocabulary-backed Kkeunmari answers discard SRS
write results before publishing progress.

- [x] Preserve current sources/assets and reproduce native rejection on
  Speed Match correct/wrong and a real vocabulary-backed Kkeunmari answer.
- [x] Retain each admitted SrsReviewAttempt through card plus daily log,
  confirming before score, feedback, speech, chain changes or turn completion.
  Preserve Speed Match first-negative evidence on later correction and
  Kkeunmari's vocabulary-only SRS rule; do not create ghost cards.
- [x] Hold countdown while evidence is pending/failed, without restarting
  the remaining round duration on each answer. Preserve the existing
  one-second countdown resolution and lifecycle pause contract. Dictionary
  waiting must not consume learner time; failed validation resumes the
  existing remaining time. No millisecond-precision timing claim is made.
- [x] Fence timers, delayed feedback/tiger moves, resize, filters, loads,
  dictionary completions, retained answer/replay/result callbacks and exit,
  reset or popped routes. Verify unknown native outcomes, duplicate retry,
  expiry boundaries, first-attempt semantics, vocabulary eligibility and
  existing grading/reward/layout behavior with independent two-axis review.
- [x] Complete scoped regression/analysis, free Graphify/preservation checks
  and local commit/evidence. Keep push, CI, builds, paid calls and deployment held.

Scope: these two timed-game screen adapters and meaningful tests. Shared
storage/recovery primitives remain unchanged unless new evidence requires it.
Legacy flashcards, transactional course/diagnostic persistence, process-death
resumption and signed-device/operational readiness remain open; this task
does not establish full commercial readiness or durable whole-round resumes.

**Task 36 local verification (2026-09-11):** Three native SRS rejection
reproductions failed before recovery on Speed Match correct/wrong and a real
vocabulary-backed Kkeunmari answer. Both screen adapters retain their SRS
attempt through card plus daily-log confirmation before publishing progress.
Speed Match preserves first-negative evidence after correction; Kkeunmari
keeps its vocabulary-only eligibility. Waiting for storage or dictionary
responses no longer consumes countdown ticks. Remaining time is preserved
at the existing one-second resolution, without a millisecond-precision claim.

The focused timed-game recovery/lifecycle suite passed 55 cases.
The combined timed-game and terminal-feedback suite passed 62 cases; its
existing Speed test now renders the selected pair and awaits saved results
while preserving the original feedback assertions.
Final scoped verification passed 1625 Flutter tests
in 78 files; 4 changed
Dart files analyzed without issues. Independent Standards and Spec approved
the actual final source hashes. All 2,488 frozen source files,
1014 assets and 1,095 paid Graphify
records were checked. Free Graphify update/prune completed; exact local
commit/parent/tree evidence is in timed-game-srs-durability-20260911/verification.json.

No push, remote CI, build, upload, paid API call or device retry. Sentence-game
and legacy-card SRS adapters,
transactional course/diagnostic persistence, process-death resumption and
signed-device/operational readiness remain unfinished. Previously admitted
native writes may complete after exit; this is not a whole-round rollback
or a full commercial-readiness claim.
