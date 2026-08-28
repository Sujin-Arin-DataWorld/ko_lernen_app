# W4 통합부터 W6 비영상 범위까지 완료 설계

**상태:** 2026-08-28 채팅 설계 승인 후 작성된 실행 사양

**대상 저장소:** Hangul Sori Flutter 앱

**실행 원칙:** 현재 `origin/main`에서 시작하는 순차 PR 열차, 사용자 실기기 검수는 마지막 게이트

## 1. 목표와 완료 정의

이 작업의 목표는 이미 구현·검증된 W4 브랜치를 현재 `origin/main`에 안전하게 통합하고, W3.5 잔여 하드닝 5건, W5 화면 수술, W6의 비영상 범위를 순서대로 구현·검증해 `main`에 반영하는 것이다.

“W6까지 완료”는 다음을 모두 만족한 상태를 뜻한다.

1. W4, W3.5, W5, W6 변경이 서로 앞선 웨이브가 병합된 최신 `origin/main`을 기준으로 순차 반영된다.
2. 각 PR의 현재 head SHA에 필요한 CI run이 실제로 존재하고 성공한 것이 확인된다.
3. 각 웨이브는 관련 테스트, `flutter analyze --no-pub`, 전체 Flutter 스위트를 통과한다.
4. 최종 `main` push의 전체 스위트와 web build 결과를 확인한다.
5. 정적 에셋·오디오·콘텐츠 감사 결과가 기계 판독 가능한 보고서와 가드 테스트로 남는다.
6. 자동화로 판단할 수 없는 실기기 항목은 구현 완료와 섞어 말하지 않고 별도 체크리스트로 Jin에게 인계한다.

실기기 승인 전에는 `FeedPhysics.snap` 기본 승격과 legacy 삭제를 완료로 부르지 않는다. 이 한 항목은 코드·테스트·화면별 후보 판정까지 준비하되, Jin의 마지막 실기기 합격 이후 별도 PR로만 병합한다.

## 2. 근거와 권위 순서

범위와 계약은 아래 자료를 위에서 아래 순서로 해석한다.

1. `AGENTS.md`의 현재 저장소·워크트리·PR/CI·Graphify 규칙
2. `docs/HANDOFF-2026-08-27-waves.md`의 현재 브랜치 상태와 살아 있는 계약
3. `docs/superpowers/plans/2026-08-27-w3-global-systems.md`의 “W5 필수 이행 목록”
4. `C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-fizzy-marshmallow.md`의 6웨이브 마스터 계획
5. `docs/Hangul Sori 앱 점검 후 개선 사항 지시서.md`의 원 요구사항
6. 시각 에셋은 `docs/ASSET_GENERATION_BIBLE.md`; 한옥·장식 계열이면 `docs/assets/STYLE_LOCK.json`과 인벤토리가 우선
7. 오디오 처리는 `docs/ADR-002-audio-policy.md`

설계 작성 시점에 직접 검증한 기준선은 다음과 같다.

- 통합 워크트리: `feat/w4-integration-20260828`
- 기준 HEAD: `930d3a1c75f1106bd5136db66b8ef86fad67559b` (`origin/main`)
- 기준 정적 분석: `No issues found`
- 기준 전체 스위트: `5,075 passed / 14 skipped / 0 failed`
- 14 skip: 디자인 컴포넌트 Linux 골든 3, 화면 배치 Linux 골든 9, 명시적 시각 증거 캡처 2
- W4 원 브랜치: `feat/w4-progress-review`의 로컬 head `b6b3150b3bac41b2accc5adc73bac9260c47c72b`
- W4 원 브랜치 최종 독립 검증: `5,178 passed / 14 skipped / 0 failed`, analyze clean, 최종 독립 리뷰 clean

이 수치는 서로 다른 HEAD의 증거다. 기준선 5,075건과 W4 브랜치 5,178건을 합치거나 현재 통합 결과로 오인하지 않는다.

## 3. 범위 경계

### 포함

- W4 Task 1–18의 현재 `origin/main` 통합과 충돌 해결
- W4의 남은 소규모 보완: 책장 빌드 중 `learnedWordCount` 중복 호출 제거, 재출제 `+2` 누적 계약 재검증
- W3.5에서 이월된 비동기·오류 상태·dispose 안전성 5건
- W5 필수 계약 6개와 마스터 계획의 나머지 화면 수술
- W6 시나리오별 정적 이미지, 오디오 게인 감사·파이프라인, cloze 주제 8그룹, 에셋 감사 자동화
- 시나리오 첫 문장 번들 TTS 티어의 저장소 계약 조사와, 승인된 로컬 음원 공급원이 존재할 때의 구현
- 모든 관련 테스트·가드·CI·로컬 빌드 검증

### 제외

- welcome hero, greet/celebrate/magpie, taego-joy-duo 등 모든 비디오 재생성
- `tiger_choose` 영상 재생성 또는 교체
- App Store, TestFlight, Google Play, Firebase 프로덕션 배포
- Jin 파이프라인용 97건 재작성분의 런타임 승격
- 승인 대기 에셋을 runtime/catalog/Firebase에 올리는 일
- Android 12 실기기 스플래시, 콜드스타트 실측, 10분 세션 ANR, 4방향 피드 손맛의 합격 판정
- Jin의 제품 기준 결정이 필요한 “커스텀팩 오답도 학습함인가” 정책 변경

제외 항목은 누락이 아니라 명시적인 권한 또는 실기기 게이트다. 자동화로 대신 통과시켰다고 주장하지 않는다.

## 4. 브랜치와 PR 구조

작업은 하나의 장기 브랜치에 누적하지 않고 아래 순서로 직렬화한다.

1. W4 통합 PR
2. W3.5 하드닝 PR
3. W5-A 공통 계약 롤아웃 PR 묶음
4. W5-B 학습 화면 수술 PR 묶음
5. W5-C 정보 구조·인트로 아트 PR 묶음
6. W6 정적 에셋·오디오·cloze·감사 PR 묶음
7. Jin 실기기 합격 후에만 FeedPhysics 승격·legacy 삭제 PR

각 PR 또는 결합도가 높은 작은 PR 묶음은 직전 PR이 `main`에 병합되고 `origin/main`이 갱신된 뒤 새 전용 워크트리에서 시작한다. 동일 워크트리에서 구현을 동시에 수행하지 않으며, 전체 테스트가 실행되는 동안 파일을 수정하지 않는다.

W4는 이미 리뷰된 커밋 역사를 보존하기 위해 로컬 `feat/w4-progress-review` head를 원격 feature branch에 먼저 정확히 push한 뒤, 현재 통합 브랜치에서 merge한다. rebase나 squash로 기존 태스크·수정 라운드의 경계를 지우지 않는다.

W4와 현재 main의 공통 변경 파일 8개는 자동 병합 결과를 신뢰하지 않고 파일별 계약을 확인한다.

- `docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/generated/app_localizations*.dart`
- `lib/main.dart`
- `test/uiux_bible_closeout_inventory_test.dart`

ARB는 원문 두 파일을 의미 기준으로 병합한 뒤 저장소 표준 명령으로 generated localizations를 재생성한다. generated 파일을 수동으로 짜깁기하지 않는다. `main.dart`는 W4의 `/review/hub` 및 grammar route와 현재 main의 온보딩·미디어 라우트를 모두 보존한다.

## 5. W4 통합 설계

### 5.1 원 브랜치 동결과 출처 증명

- 기존 W4 워크트리에서 non-Graphify 변경과 staged 변경이 없음을 다시 확인한다.
- branch head, merge-base, `origin/main`과의 좌우 커밋 수, 원격 feature branch와의 좌우 커밋 수를 기록한다.
- 원 브랜치 head를 push한 뒤 원격 SHA가 로컬 SHA와 같은지 확인한다.
- `.superpowers/sdd/**`는 운영 스크래치로 계속 ignore한다. 신규 세션 일지나 handoff 문서를 만들지 않고, 영속해야 하는 이유·검증 결과는 커밋 메시지와 PR 본문에 남긴다. 기존 추적 인수인계서는 역사 자료로 보존하되 덧붙이지 않는다.
- 무시된 SDD 원자료가 있는 기존 W4 워크트리는 W4 병합과 PR 증거 보존이 끝나기 전에 제거하지 않는다.

### 5.2 통합과 소규모 보완

- 통합 브랜치에서 W4를 `--no-ff` merge하고 공통 8개 파일을 계약 기준으로 해결한다.
- `bookshelf_screen.dart`의 같은 build 경로에서 `learnedWordCount(pack)`를 한 번만 계산해 재사용한다. 화면 값과 커스텀팩 의미는 바꾸지 않는다.
- 기존 재출제 카운터 테스트가 `+2` 누적을 실제로 고정하는지 확인한다. 이미 정확히 덮으면 중복 테스트를 만들지 않고, 덮지 않으면 가장 작은 회귀 테스트를 추가한다.

### 5.3 W4 불변 계약

다음 네 가지는 통합 충돌 해결이나 정리 명목으로 바꾸지 않는다.

1. `LearnSessionQueue.servedPosition` 계산과 큐 조작 순서
2. `recordScenarioCheckpoint` 내부의 course context 자가 유도 금지
3. `/review`는 플레이어 라우트로 유지하고 허브는 `/review/hub`로 분리
4. 신규 저장 키는 같은 PR에서 cloud backup/restore/export 화이트리스트에 등록

추가로 T16과 T17은 하나의 런타임 계약이다. grammar plan 화면이 호출하는 `/grammar_choice_quiz` 등록 없이 분리 병합하지 않는다.

## 6. W3.5 하드닝 설계

W4가 main에 병합된 다음 최신 main에서 아래 5건을 TDD로 처리한다.

### 6.1 단어팩 완료 원자성

`vocab_pack_screen.dart`의 `_finish()`를 await 가능한 단일 완료 작업으로 만든다. 중복 탭을 막는 `_finishing` 상태, try/catch, mounted 확인, 재시도 가능한 사용자 오류 상태를 둔다. XP·클리어·도장 저장 중 하나가 실패했는데 결과 화면으로 성공 이동하거나 흔적 없이 멈추지 않도록 테스트한다.

### 6.2 복습 로드 상태 분리

`review_session_screen.dart`의 로드 상태를 loading, ready, empty, error로 분리한다. 저장소/덱 로드 실패는 “복습 없음” 축하 화면이 아니라 현지화된 오류와 retry를 보여준다. raw 예외 문자열은 UI에 노출하지 않는다.

### 6.3 문화 노트 비동기 실패 컨테인

`CultureNotesService.load()`의 미청취 Future를 제거한다. 호출자가 명시적으로 await하거나 오류 상태를 소유하게 하고, 위젯 dispose 이후 setState와 unhandled asynchronous error가 발생하지 않도록 한다.

### 6.4 grammar 체크포인트 시트 수명

시트 내부 갱신은 부모 `mounted`가 아니라 `sheetContext.mounted`를 확인한다. 제출 중 상태를 시트가 소유해 중복 제출을 막고, 닫힌 시트의 `setLocal` 호출이 없음을 테스트한다.

### 6.5 단어팩 지연 작업 취소

850ms `Future.delayed`를 수명 관리 가능한 `Timer` 또는 동등한 취소 가능한 seam으로 교체한다. 새 문제 시작·완료·dispose 때 이전 예약 작업을 취소하고, 화면 종료 후 `_advanceQuiz`가 호출되지 않음을 fake time 또는 widget test로 고정한다.

## 7. W5 화면 수술 설계

W5는 파일 교집합과 사용자 여정에 따라 세 묶음으로 나눈다. 각 묶음 안에서도 테스트가 먼저 실패하는 것을 확인한 뒤 구현한다.

### 7.1 W5-A: 공통 계약 롤아웃

1. 남은 11개 레벨 선택 표면을 `SoriLevelFilterBar`로 이관한다. browse 표면은 인라인, play 표면은 `SoriChromeRow` 시트 패턴을 사용한다. 이관 후 `level_filter_guard`를 추가해 허용 목록이 증가하지 않고 최종 0이 되게 한다.
2. `speakable.dart` 기반 오디오를 남은 6개 flip 표면과 quest/cloze/scenario 비-flip 표면에 배선한다. 모든 호출은 중복 탭, 화면 dispose, 현재 발화 취소, 로컬 캐시 실패와 네트워크 실패를 구분하는 기존 TTS 계약을 따른다.
3. `/review`의 이전 카드 동작은 현재 배열 index가 아니라 실제로 사용자에게 제공된 카드 id 이력을 기준으로 설계한다. SRS 오답 재삽입 뒤에도 “이전”이 직전에 본 카드를 가리키는 회귀 테스트를 먼저 만든다.
4. kkeunmari 외 학습 화면의 홈 탈출 동선을 전수 조사한다. 자체 close/leading 버튼이 있는 화면은 중복 버튼을 만들지 않고 `SoriHomeAction` 대체 또는 병존 이유를 화면별 테스트에 고정한다.
5. `hero_placement_guard`의 네 화면과 실제 추가 부채를 모두 정리하고 allowlist를 0으로 낮춘다. `chrome_stack_guard`의 다중 Wrap 부채 5화면도 `SoriChromeRow` 또는 `SoriLevelFilterBar` 단일 행으로 바꾸고 allowlist를 0으로 낮춘다.
6. `FeedPhysics.snap` 후보 화면은 자동 테스트와 화면별 manifest로 준비하지만 기본 승격과 legacy 삭제는 하지 않는다.

### 7.2 W5-B: 학습·게임 표면

- Kalligrafie: 공용 `trace_canvas.dart`를 추출하고 획 입력, 초기화, 성공 판정, 접근성 대체 동작을 테스트한다.
- Quest feedback: `SoriWordTile`의 불필요한 아이콘을 제거하고 정답 효과·간격·live region을 통일한다. 즉시 판정은 `hoerverstehen`만 허용하며 다른 quest 유형은 확인 버튼과 기존 시도 규칙을 유지한다.
- Diktat: `promptKo`를 권위 텍스트로 사용하고 재생 상태, 다시 듣기, 입력, 오류·재시도 UI를 분리한다.
- Scenario grammar/writing: grammar는 복수 카드, writing은 단계적 힌트를 제공하되 기존 점수·SRS·course checkpoint 계약을 유지한다.
- Anlaut: 학습 크롬을 압축하고 작은 화면·큰 글자에서 내용 영역이 가려지지 않게 한다.
- Silben: 셀 색상만으로 상태를 전달하지 않고 선택·정답·오답을 의미와 아이콘/텍스트로 함께 표현한다.
- Aussprache: 호랑이 장식을 제거하고 5범주 진단 피드로 재구축한다. 권한 거절, 녹음 실패, 분석 실패, 재시도를 서로 다른 상태로 처리한다.

`hoerverstehen` 즉시 판정의 고정 범위는 `dedicated_feedback_route`, `scenario_can_do_result_flow`, `scenario_srs_persistence_flow`, `quest_engines_uiux` 테스트에서 함께 검증한다.

### 7.3 W5-C: 허브와 인트로 아트

- `/my_words`에 bookshelf, word search, hard words를 탭 프리셀렉트 가능한 허브로 통합한다.
- 기존 named route와 `settings.name`은 삭제하지 않는다. 기존 8개 의존 경로는 새 허브의 초기 탭 인자로 매핑한다.
- 시나리오 인트로 아트는 안정적인 scenario id 기반 해시 선택과 결정적 crop/focal point 계약을 사용한다. 동일 scenario가 실행마다 다른 아트를 고르지 않게 한다.
- W5 종료 시 Spiele 1–12의 자동화 가능한 여정을 전수 점검하고, 실기기에서만 판단 가능한 항목을 Jin 체크리스트로 분리한다.

## 8. W6 비영상 설계

### 8.1 시나리오별 정적 이미지

먼저 canonical scenario id와 현재 이미지 참조를 inventory로 만든다. 파일명은 scenario id를 포함해 loader가 자동 인식하게 하고, 출력 규격은 1536×1024로 고정한다. 우선순위는 office, home, 그다음 inventory에서 사용자 노출 빈도와 결손 여부로 결정한다.

신규 이미지는 `ASSET_GENERATION_BIBLE`의 Faceted Minhwa 방향과 실제 화면 crop을 함께 만족해야 한다. 생성 후 다음을 자동·시각 검증한다.

- 정확한 픽셀 크기, 포맷, 알파/색공간, 파일명과 scenario id 일치
- 중복 해시, orphan asset, 누락 참조, 잘못된 fallback
- compact/medium/expanded 화면 crop과 텍스트 안전 영역
- pending-review 자산과 runtime 자산의 경계

자동 검사를 통과하지 못한 이미지는 runtime manifest에 넣지 않는다. 사람의 미감 승인과 실기기 crop은 자동 검사와 별도 표기한다.

### 8.2 오디오 게인 스윕

ADR-002를 기준으로 모든 runtime 오디오를 측정하는 `tool/measure_audio_gain.py`와 기계 판독 가능한 보고서를 둔다. 최소한 integrated loudness, true peak 또는 저장소 도구가 지원하는 동등한 지표, duration, decoder/read 실패를 기록한다.

원본을 직접 덮어쓰지 않는다. 정규화가 필요한 파일은 기존 파이프라인이 정의한 파생 경로로 만들고, before/after 수치와 source hash를 남긴다. 허용 범위를 벗어난 새 파일이 추가되면 실패하는 contract test를 CI에 연결한다. 측정 도구나 decoder가 없는 환경에서는 성공으로 처리하지 않고 명시적 실패로 끝낸다.

### 8.3 Cloze 주제 8그룹

W5의 레벨 필터 이관이 main에 병합된 뒤 시작한다. canonical cloze 항목을 8개 주제로 분류하고, 항목 id는 한 권위 데이터셋에서만 정의한다. 그룹은 UI 표시 순서, 현지화 label key, 허용 level, 항목 id 목록을 가진다.

가드는 다음을 검증한다.

- 정확히 8개 주제와 고유 id
- dangling/duplicate 항목 id 없음
- level filter 적용 뒤 빈 주제가 생길 때의 명시적 처리
- 기존 all-level 여정과 deep link 보존
- 독일어·영어 ARB parity

### 8.4 에셋 감사 자동화

기존 `tool/audit_scene_assets.py`와 `tool/audit_scenario_quests.py`를 재사용하고 필요한 검사를 확장한다. 동일 목적의 새 감사기를 중복 작성하지 않는다. 감사 결과가 0 issue일 때만 성공하며, 보고서가 코드 변경 없이 불안정하게 재작성되지 않도록 정렬과 줄바꿈을 결정적으로 유지한다.

### 8.5 시나리오 첫 문장 번들 TTS 티어

먼저 첫 문장 목록, 현재 cache key, locale/voice, 기존 라이선스·생성 파이프라인을 조사한다. 저장소가 승인된 음원 또는 재현 가능한 승인 voice pipeline을 이미 제공하면 첫 문장 번들 manifest, source hash, fallback 순서를 구현하고 startup/introduction prefetch 테스트를 추가한다.

승인된 음원 공급원이 없으면 임의 OS voice나 새 외부 voice를 정본으로 생성하지 않는다. 이 경우에도 누락 inventory, manifest contract, 네트워크 TTS fallback, 로딩·실패 UI, 향후 음원을 넣을 정확한 경로까지 구현해 자동화 가능한 부분을 끝낸다. 생성되지 않은 음원을 생성했다고 보고하지 않는다.

## 9. 오류 처리와 상태 계약

모든 새 비동기 화면은 loading, content, empty, recoverable error를 구분한다. empty를 오류 fallback으로 쓰지 않는다. 사용자 UI에는 raw exception, Firebase code, 파일 경로를 표시하지 않고 현지화된 설명과 재시도 동작을 제공한다.

fire-and-forget은 다음 셋 중 하나만 허용한다.

1. 호출자가 성공 여부를 필요로 하지 않고,
2. 오류가 명시적으로 수집·격리되며,
3. dispose 이후 UI 갱신이 불가능하다는 테스트가 있을 때

저장·백업·내보내기·course progression은 조용한 실패를 허용하지 않는다. 성공 UI는 권위 저장이 완료된 뒤에만 표시한다. 단, 기존 계약이 fail-soft 재생을 요구하는 course context 추론 같은 보조 기능은 실패를 null로 강등하되 핵심 학습 흐름을 계속한다.

## 10. 테스트와 검증 매트릭스

### 모든 구현 태스크

1. 실패하는 최소 테스트를 먼저 실행해 실제 실패 원인을 확인한다.
2. 필요한 최소 변경만 적용한다.
3. 변경 파일만 format하고 `git diff --check`를 실행한다.
4. 관련 테스트를 통과시킨다.
5. 인접 계약 테스트와 관련 guard를 실행한다.
6. 커밋 전 `flutter analyze --no-pub`를 실행한다.

### 모든 웨이브 종료

- `flutter analyze --no-pub`
- `flutter test --no-pub --reporter failures-only`
- 전체 스위트 중 파일 수정 금지
- 실패 0 확인
- skip이 14보다 늘면 원인을 조사하고 승인 없는 skip 추가를 차단
- 14개 기존 skip은 Linux 전용 골든 12개와 opt-in 캡처 2개로 계속 분류
- 변경된 audit script를 UTF-8 모드로 실행하고 exit code와 issue count 확인
- 최종 `git status`, staged 파일, diff, HEAD 확인

### UI와 접근성

영향 화면은 최소 360×640, 390×844, 430×932, 800×1280에서 검사한다. text scale 2.0, reduce motion, keyboard/focus, 48dp hit target, semantic label/live region을 확인한다. 픽셀 골든은 Linux CI 정본이며 Windows에서 skip된 것을 통과로 오인하지 않는다.

### 빌드와 CI

- 로컬에서 가능한 Android debug 또는 저장소 표준 비서명 빌드를 수행한다.
- Windows에서 iOS 실기기·서명 빌드를 검증했다고 주장하지 않는다.
- PR 생성·갱신 후 현재 head SHA를 확인한다.
- 같은 SHA의 자동 CI가 있으면 추가 dispatch하지 않는다.
- 자동 run이 없을 때만 `ci.yml`을 기본 `task=ci`로 한 번 dispatch한다.
- cross-layer 위험이 크거나 최종 전수 점검일 때만 `task=full`을 사용한다.
- 필요한 Analyze/Test/Build와 변경 영역 잡의 실제 결론을 확인한다.
- merge 뒤 `main` push의 전체 suite와 web build가 끝날 때까지 최종 완료로 보고하지 않는다.

## 11. 리뷰와 래칫

각 PR은 구현과 별도로 다음 관점에서 검토한다.

- Flutter/Dart 정확성, widget lifecycle, async 수명
- 접근성, 큰 글자, 좁은 화면, semantics
- 저장·백업·내보내기·silent failure
- 기존 계약과 요구사항의 누락 여부

가드 상한과 allowlist는 내려가기만 한다. 기존 항목을 제거한 PR에서 상한을 다시 올리거나 새 화면을 grandfather 목록에 넣지 않는다. 테스트 단언을 구현에 맞춰 약화하는 수정은 허용하지 않으며, 단언이 틀렸다고 판단하면 먼저 계약 근거와 재현 증거를 제시한다.

## 12. 산출물과 기록 정책

- 설계와 구현 계획: `docs/superpowers/specs/`, `docs/superpowers/plans/`
- 코드·테스트·audit report: 해당 권위 디렉터리
- 이유와 실행 증거: 커밋 메시지와 PR 본문
- 구조 갱신: 작업 종료 시 `graphify update .`

신규 `SESSION_LOG`, 수기 handoff, `.claude/handoffs`를 만들지 않는다. SDD scratch 원장은 로컬 실행 보조 자료이며 소스 권위가 아니다. 장기 계약은 테스트·가드·코드 주석·설계 문서 중 가장 가까운 권위 위치에만 둔다.

## 13. 롤백과 복구

웨이브와 고결합 묶음을 분리 PR로 유지해 문제 발생 시 해당 merge만 되돌릴 수 있게 한다. 정적 에셋, 오디오 파생물, 데이터 모델 변경은 가능한 한 별도 커밋으로 나눠 원인과 용량 변화를 추적한다.

저장 키 또는 복구 포맷을 바꿀 때는 backward read, forward write, backup/restore/export를 같은 PR에서 검증한다. migration 실패 시 기존 데이터를 보존하고 쓰기를 잠그는 현재 fail-closed 정책을 유지한다.

`FeedPhysics.snap`은 실기기 불합격 시 코드 롤백이 아니라 기존 legacy 기본값을 그대로 유지한다. 실기기 합격 후 승격 PR에서도 화면별로 되돌릴 수 있는 커밋 경계를 둔다.

## 14. 최종 Jin 실기기 체크리스트

자동화 완료 뒤 Jin에게 다음만 남긴다.

- Android 12 실제 설치 스플래시와 첫 프레임
- 콜드스타트 시간 실측
- snap 후보 화면의 4방향 제스처, 시스템 edge 충돌, 10분 세션 ANR 0
- `tiger_choose` 그림자 잔존과 신규 클립 1920×1080 규격 확인
- 시나리오 이미지의 실제 기기 crop, 텍스트 가독성, 화면 전환 체감
- 첫 문장 TTS의 첫 발화 지연·음량·자연스러움
- 커스텀팩 오답을 “학습함”으로 셀지 제품 기준 확정
- Linux 골든의 실제 CI diff 확인

이 목록의 합격 전에도 자동화 가능한 W4–W6 구현·테스트·CI는 완료할 수 있다. 다만 해당 결과를 실기기 합격이나 FeedPhysics 최종 승격으로 표현하지 않는다.
