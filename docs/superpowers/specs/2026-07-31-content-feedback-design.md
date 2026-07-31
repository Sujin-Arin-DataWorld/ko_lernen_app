# 콘텐츠 완료 피드백과 베타 테스터 여권 설계

상태: 검토용 초안
기준 커밋: `origin/main` `c5d1415`
대상: Hangul Sori Android 내부 테스트, 이후 iOS/App Store 출시 준비

## 1. 결정과 목표

학습 콘텐츠의 **모든 실제 완료 화면**에 선택형 `호랑이에게 한마디` 피드백
입구를 제공한다. 테스터는 버그, 난이도·콘텐츠 품질, 기타 의견 중 하나를
골라 직접 작성할 수 있다. 제출은 학습 완료·다음 이동을 절대 막지 않는다.

테스터 참여를 재미있게 만들기 위해, 피드백을 제출하면 `베타 테스터 여권`
도장을 하나 얻고 다음 **베타 미션**을 연다. 베타 미션은 검증 우선순위가 높은
추천 콘텐츠 경로일 뿐이다. 프리미엄 entitlement, 실제 CEFR 레벨, 일반 학습
콘텐츠의 접근성은 피드백으로 잠그지 않는다.

성공 기준은 다음과 같다.

1. 완료 화면에서 피드백을 찾고 보내는 데 10초 이내가 걸린다.
2. 개발자는 피드백 하나만 보고도 어떤 콘텐츠·어떤 앱 빌드·어떤 플랫폼에서
   발생했는지 판단할 수 있다.
3. 테스터가 피드백을 보내지 않아도 학습을 계속하거나 나갈 수 있다.
4. 자유 입력은 최소한의 데이터만 안전하게 보관되고, 계정 삭제 시 함께 삭제된다.
5. 베타 피드백과 여권은 내부 테스트에만 켜지며 정식 출시에서는 일반 학습 흐름을
   바꾸지 않는다.

## 2. 사용자 경험

### 2.1 완료 화면의 기본 상태

각 결과 화면의 기존 `다음`, `완료`, `다시 하기` 동작 아래에 작은 보조 카드가
나온다.

```text
🐯 이 콘텐츠에 한마디 남기기          테스터 여권 2 / 5
10초면 다음 베타 미션에 도장을 찍을 수 있어요.
```

카드는 자동으로 열리지 않는다. 이미 보냈으면 같은 카드가 다음 상태로 바뀐다.

```text
✓ 의견을 기록했어요                    테스터 여권 3 / 5
다음 베타 미션: 공항 입국 시나리오
```

`MediaQuery.disableAnimations`가 켜진 경우 정적 도장과 텍스트만 표시한다.
그 외에는 기존 `Mascot`의 호랑이·까치 포즈와 `SoriCelebration`의 짧은 연출을
재사용한다. 새로운 일러스트, XP, 코인, 재화를 만들거나 지급하지 않는다.

### 2.2 피드백 시트

카드를 누르면 결과 화면 위에 바텀시트가 열린다. 첫 단계는 세 개의 같은 크기
선택 버튼이다.

| 종류 | 사용자 문구 | 구조화된 정보 | 직접 입력 안내 |
| --- | --- | --- | --- |
| `bug` | `여기 이상해요` | 화면, 정답, 소리, 번역, 진행 중 하나 | `무엇이 어떻게 이상했나요?` |
| `content` | `난이도와 내용을 알려 주세요` | 너무 쉬움, 딱 좋아요, 너무 어려움, 이해가 안 됨 중 하나와 설명, 예시, 문제, 속도, 번역 중 하나 | `어떤 부분이 더 좋아지면 좋을까요?` |
| `other` | `다른 의견 남기기` | 없음 | `떠오른 의견을 자유롭게 적어 주세요.` |

세 경우 모두 텍스트 입력란을 제공한다. `bug`와 `other`는 1자 이상 입력해야
보낼 수 있고, `content`는 구조화된 선택만으로도 보낼 수 있다. 모든 입력은
1,000자로 제한한다. 입력란 바로 위에는 다음 안내를 현지화해 표시한다.

> 연락처, 비밀번호, 민감한 개인정보는 쓰지 말아 주세요.

제출 후에는 바텀시트 안에서 `호랑이가 메모를 여권에 붙였어요.`라는 확인과
작은 도장 반응을 표시한 뒤 닫는다. 실패 시에는 실패 이유를 기술적으로 노출하지
않고 `아직 보내지 못했어요. 연결되면 다시 시도할게요.`를 표시한다. 완료 결과와
다음 학습 버튼은 그 상태에서도 항상 사용할 수 있다.

### 2.3 콘텐츠별 질문

같은 양식이 반복되는 느낌을 줄이기 위해, `contentType`에 따라 제목과 보조 질문만
바꾼다. 데이터 필드와 제출 흐름은 공통이다.

| 콘텐츠 | 예시 질문 |
| --- | --- |
| 시나리오 | `이 상황에서 실제로 가장 막힌 부분이 있었나요?` |
| 어휘·복습 | `이 단어들이 기억에 남을 것 같나요?` |
| 문법 | `설명과 예시가 규칙을 이해하는 데 충분했나요?` |
| 한글·쓰기 | `글자 모양과 발음 연결이 자연스러웠나요?` |
| 게임 | `다음에도 이 게임을 하고 싶나요? 무엇이 어려웠나요?` |
| 듣기 | `속도와 음성이 이해하기 좋았나요?` |

앱의 현재 언어가 독일어 또는 영어이므로 모든 문구는 기존 `app_de.arb`와
`app_en.arb`에 추가한다. 문자열을 화면 코드에 직접 쓰지 않는다.

## 3. 베타 테스터 여권

### 3.1 동작 원칙

`BetaTesterPassport`는 내부 테스트 전용 진단 경로다.

- 피드백 제출은 한 번의 완료 실행(`completionId`)에 한 번만 인정한다.
- 서버가 피드백을 수신하고 확인 응답을 보냈을 때만 도장을 찍는다. 오프라인 큐에
  들어간 피드백은 `도장을 전달 중`으로 보이며, 일반 학습은 계속할 수 있다.
- 각 도장은 다음 `BetaMission`을 열거나 홈 화면의 다음 추천 미션으로 설정한다.
- 일반 콘텐츠, 구독 entitlement, 레벨 잠금, 연속 학습에는 영향을 주지 않는다.
- 내부 테스트 플래그가 꺼진 빌드에서는 여권 카드·미션 잠금·도장이 모두 보이지
  않고, 피드백 카드는 선택적으로 유지할 수 있다.

초기 베타 미션 수는 다섯 개로 고정한다. `시나리오 → 어휘 팩 → 듣기 → 게임 →
문법/한글 세션` 순으로 서로 다른 콘텐츠 유형을 한 번 이상 통과하도록 큐레이션한다.
각 미션의 대상 콘텐츠 ID, 제목, 질문은 코드에 하드코딩하지 않고 작은 로컬 카탈로그로
관리한다. 카탈로그 밖의 콘텐츠에서 보낸 피드백도 기록되지만 여권 도장은 중복해서
늘지 않는다. 서버는 `users/{uid}/tester_passport/state`에 이미 인정된
`betaMissionId`와 마지막 갱신 시각을 저장한다. 클라이언트는 이 문서를 본인만 읽을 수
있고 쓰지는 못한다. 따라서 앱 재설치·재로그인 뒤에도 여권 진행도를 복원할 수 있다.

### 3.2 정식 출시 안전장치

베타 피드백과 여권은 `--dart-define=ENABLE_TESTER_FEEDBACK=true`일 때만 켠다.
정식 출시와 일반 개발 빌드의 기본값은 `false`다. 플래그가 없거나 `false`이면
피드백 카드·여권·베타 미션을 모두 숨기며, `PremiumService` 또는 기존 콘텐츠 잠금
규칙을 변경하지 않는다. 이 기능을 공개 출시에서 유지하려면 별도 제품·개인정보
검토와 새 설계 승인이 필요하다.

## 4. 완료 화면 적용 범위

전역 `NavigatorObserver`로 완료를 추측하지 않는다. 뒤로 가기, 재시작, 다음 콘텐츠
이동을 완료로 오인할 수 있기 때문이다. 각 실제 결과 화면이 공통
`ContentFeedbackCard`에 명시적인 `ContentFeedbackContext`를 전달한다.

| 적용 방식 | 화면 또는 공통 구성 요소 | 포함되는 콘텐츠 |
| --- | --- | --- |
| 공통 연결 | `widgets/sori/game_reward.dart`의 `GameOverCard` | Cloze, 일일 도전, Satz Arcade, Speed Match, 내 단어장 퀴즈·매칭·타이핑 |
| 전용 결과 | `scenario_player_screen.dart` | 모든 시나리오 종료 |
| 전용 결과 | `vocab_pack_result_screen.dart` | 어휘 팩 학습과 보스 결과 |
| 전용 결과 | `listening_screen.dart` | 듣기 라운드 |
| 전용 결과 | `review_session_screen.dart` | 복습 세션 |
| 전용 결과 | `custom_pack_play_screen.dart`, `legacy_vocab_screen.dart` | 내 단어장·기존 단어장 오늘 학습 종료. 기존 단어장의 경우 이번 세션에서 카드를 하나 이상 처리한 뒤 due가 0개가 되었을 때만 카드가 나온다. |
| 전용 결과 | `daily_char_sheet.dart` | 오늘의 글자 연습 종료. 기존 자동 종료는 카드가 보일 수 있도록 명시적 완료 상태로 바꾼다. |
| 전용 결과 | `chosung_quiz_screen.dart`, `wordle_screen.dart`, `kkeunmari_screen.dart` | 자체 결과 카드가 있는 게임 |
| 새 세션 결과 | `grammar_screen.dart`, `hangul_screen.dart` | 순환형 카드에 `이번 학습 마치기`를 추가하고 그 버튼에서만 결과와 피드백을 연다. |

온보딩, 로그인, 결제, 설정, 계정 삭제, 사진 캡처 자체, 단순 목록 탐색은 학습
콘텐츠 완료가 아니므로 피드백 여권 범위에서 제외한다.

Smalltalk, 기존 단어장의 전체/즐겨찾기 순환 모드, 책장 페이지도 현재는 자연스러운
완료 상태가 없다. 이 흐름에 자동 피드백을 억지로 넣지 않는다. 이후 해당 화면에
명시적인 세션 종료와 학습 성과가 추가될 때 같은 공통 결과 카드를 연결한다. 책
OCR/분석 결과는 학습 난이도 피드백과 섞지 않으며, 필요하면 별도 `분석 결과 신고`
기능으로 다룬다.

## 5. 데이터와 보안 설계

### 5.1 클라이언트 계약

각 제출에는 클라이언트가 만든 불투명 UUID `feedbackId`와 `completionId`를 포함한다.
한 번 큐에 넣은 이벤트는 같은 `feedbackId`로 재시도한다.

```text
schemaVersion: 1
feedbackId: UUID
completionId: UUID
category: bug | content | other
message: string (0..1000, bug/other는 1자 이상)
issueArea: ui | answer | audio | translation | navigation | other | null
contentSignal: too_easy | right | too_hard | unclear | null
contentFocus: explanation | examples | questions | pace | translation | other | null
contentType: string (1..48)
contentId: string (1..128)
contentLabel: string (0..120)
level: A1 | A2 | B1 | B2 | null
scoreSummary: string (0..64)
betaMissionId: string | null
appVersion: version+build string (1..64)
platform: android | ios
locale: de | en
```

`appVersion`은 설정 화면의 표시 문자열을 재사용하거나 하드코딩하지 않는다.
`package_info_plus`로 빌드 시 실제 버전과 빌드 번호를 읽는다. 사용자 답안, 이메일,
표시 이름, 광고 ID, FCM 토큰, 기기 모델, 전체 학습 이력, 스크린샷은 계약에 넣지
않는다.

### 5.2 제출 경로

클라이언트가 Firestore에 직접 쓰지 않는다. `functions/gye` 코드베이스에
`submitTesterFeedback` Callable Function을 추가한다. 이 코드베이스는 기존 인증·계정
삭제 흐름과 분리되어 있으며, 현재 TTS Functions 의존성 업그레이드 작업을 기다리지
않는다.

Callable Function은 다음을 보장한다.

1. 인증된 Firebase 사용자와 유효한 App Check 토큰을 요구한다.
2. 호출자가 보낸 UID를 신뢰하지 않고 인증 컨텍스트의 UID만 사용한다.
3. 위 허용 필드, enum, 길이, 카테고리별 조건을 서버에서 검증한다.
4. `users/{authenticatedUid}/tester_feedback/{feedbackId}`에 서버 타임스탬프와
   `status: new`를 추가해 저장하고, 유효한 새 `betaMissionId`인 경우 같은
   transaction에서 `tester_passport/state`를 갱신한다.
5. 같은 UID·같은 `feedbackId`가 재시도되면 기존 문서를 덮어쓰지 않고 성공적인
   idempotent 응답을 반환한다.

Firestore 규칙은 `tester_feedback` 하위 컬렉션에 대해 클라이언트의 read, create,
update, delete를 모두 거부한다. `tester_passport/state`는 본인만 읽고 클라이언트는
쓰지 못한다. 기존 넓은 `users/{uid}/{collectionName}/{document=**}` 규칙에서도 두
컬렉션을 명시적으로 제외한다. 서버 관리자 SDK만 이 경로를 쓴다. 기존 계정 삭제
워커는 사용자 루트 하위 컬렉션을 순회하므로 두 문서도 계정 삭제와 함께 제거된다.

### 5.3 오프라인과 재시도

제출 전에 `FeedbackOutbox`가 기존 `flutter_secure_storage`에 최대 20개의 검증된
payload를 저장한다. 큐 저장이 성공하면 카드에는 `도장을 전달 중`이 표시되고, 앱 시작 후
Firebase 인증과 App Check가 준비될 때와 네트워크 복구 뒤에 순서대로 전송한다.
서버가 수신하면 해당 이벤트를 제거하고 여권 상태를 새로 읽어 도장을 반영한다.
20개가 찬 경우 새 제출은 자동 삭제하지 않고, 사용자에게
`전송 대기 의견이 많아요. 연결 후 다시 시도해 주세요.`를 보여 준다.

테스터가 계정 삭제를 시작한 상태라면 큐를 전송하지 않고 즉시 지운다. 이 기능은
Analytics/Crashlytics 동의와 묶지 않는다. 피드백은 사용자가 명시적으로 누르는
전송 행위로만 수집된다.

## 6. 개인정보·스토어 준비

공개 `docs/privacy.html`의 독일어·영어·한국어 정책에 다음을 추가한다.

- 선택적 제품 피드백의 목적과 Firebase 처리
- 자유 텍스트와 익명 Firebase UID의 연결 가능성
- 자동 첨부되는 최소 기술 맥락
- 피드백을 포함한 계정 삭제 경로와 보존 원칙

Closed/Production 전환 전에 Google Play Data Safety의 자유 입력 사용자 콘텐츠와
User ID 연계 여부, Apple App Privacy의 Other User Content 항목을 재검토한다.
iOS에는 아직 Firebase 옵션이 없으므로, App Store 빌드에서 이 기능을 켜기 전
Firebase iOS 앱 등록과 `GoogleService-Info.plist` 구성이 선행되어야 한다.

## 7. 검증 계획

### 자동 테스트

1. Dart: payload 모델의 enum·길이·카테고리 조건, `completionId` 중복 방지,
   outbox 저장·재시도·20개 한도, 베타 여권 도장 계산을 단위 테스트한다.
2. Flutter: 피드백 카드는 자동으로 시트를 열지 않고, 세 종류 모두 입력·검증·제출
   상태를 올바르게 보여 주며 reduce-motion에서도 기능한다.
3. 화면: 위 적용표의 공통 및 전용 결과 화면이 정확한 `ContentFeedbackContext`를
   하나씩 전달하는지 테스트한다. 게임 공통 카드 변경이 모든 게임에 적용되는지도
   확인한다.
4. Node Callable: 인증/App Check 부재, 잘못된 enum, 초과 길이, 위조 UID,
   idempotent 재시도, 서버 시간과 경로를 테스트한다.
5. Firestore Emulator: 클라이언트가 `tester_feedback`을 읽거나 쓰거나 수정·삭제할
   수 없고, 기존 사용자 하위 컬렉션 동작은 회귀하지 않는지 테스트한다.

### 수동 내부 테스트

1. Android 기기에서 각 결과 화면을 완료하고 제출·건너뛰기·다시 하기·다음 이동을
   검증한다.
2. 비행기 모드에서 피드백을 보내고 앱을 재시작한 뒤, 연결 복구 후 한 번만 수신되는지
   검증한다.
3. Firebase Console/Admin 조회에서 콘텐츠·빌드·플랫폼과 도장이 일치하는지 확인한다.
4. 접근성에서 글자 크기, 스크린 리더 라벨, OS reduce-motion을 확인한다.
5. 베타 플래그를 끈 빌드에서 여권 미션 잠금이 완전히 사라지고 일반 콘텐츠가 모두
   접근 가능한지 확인한다.

## 8. 배포 순서

1. Flutter·Functions·규칙·정책 변경을 단위/에뮬레이터 테스트한다.
2. Functions와 Firestore rules를 배포하고 callable/App Check를 Android 내부 테스트
   기기에서 확인한다.
3. 베타 플래그가 켜진 Android AAB를 생성해 내부 테스터에게 배포한다.
4. Firebase Console에서 첫 피드백과 outbox 재시도를 확인한다.
5. iOS Firebase 구성·정책·App Privacy 갱신 뒤 같은 플래그를 TestFlight에서 검증한다.
6. 정식 출시 AAB/App Store archive에서는 `ENABLE_TESTER_FEEDBACK`를 지정하지 않아
   카드·여권·베타 미션이 모두 꺼졌는지 확인한다.
