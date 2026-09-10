# Global Launch Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 취소·네트워크·저장 공간 장애가 음성 학습을 방해하는 경로와 공통 로딩 접근성 결손을 고치고, 개인정보 없는 서버 오류 진단과 정식 출시 조건을 준비한다.

**Architecture:** 기존 TTS generation과 정본/개인 캐시 경계를 유지해 국소 수정한다. AppLoading 한 곳에서 의미 라벨과 제약 대응을 개선한다. 새 SDK와 새 원격 설정은 추가하지 않는다.

**Tech Stack:** Flutter 3.44 / Dart 3.12, audioplayers, Firebase, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-09-global-launch-readiness-design.md`

## Global Constraints

- 최종 통합 기준 SHA `7e844d1b7d751a31f3a666769224da68989523be` (#293 포함), 시작 기준 `aa0d932f`. 웹/Flutter 검증 기준 `92353147` 이후 변경은 미사용 자산 보관과 Graphify뿐이며 런타임·테스트 Git 객체 및 수정 파일 해시가 동일함을 확인했다. 전용 `global-launch-readiness-20260909` 작업 공간만 수정.
- 커밋/푸시는 Jin이 명시적으로 요청할 때만. 구현자는 커밋하지 않고 diff와 테스트 증거를 남긴다.
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
- [ ] **Step 5: Verify the published PR head.** 검증한 파일만 커밋·푸시하고 PR을 만든다.
  자동 CI가 있으면 재사용하며 정확한 head SHA의 필수 검사와 Playwright 결과를 확인한다.
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
- [ ] **Step 3: Verify and integrate.** 한옥·계 소비 화면 회귀, 분석·형식 검사와 독립
  Standards/Spec 리뷰 후 같은 PR #294에 반영한다. 기존 서명 후보 2280(`2373b1d3`)에는
  이 후속 수정이 없으므로 새 커밋의 CI와 서명 후보를 구분해 확인한다.

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
