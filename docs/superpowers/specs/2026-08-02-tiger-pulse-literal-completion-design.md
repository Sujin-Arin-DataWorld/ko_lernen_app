# Tiger Pulse와 모든 완료 화면 피드백 설계

상태: 구현 승인 기준 초안
기준 작업공간: `codex/content-feedback-design-2026-07-31`
출시 범위: 현재 Android 내부 테스터. 데이터 계약과 UI 구조는 iOS TestFlight에도 재사용 가능하되, iOS 노출은 Firebase/App Check 준비 뒤 별도 릴리스 결정으로 한다.

## 1. 문제와 결정

현재 완료 화면의 선택형 피드백은 버그·콘텐츠·기타를 기록하고 베타 여권 도장으로 참여를 유도한다. 그러나 일반 콘텐츠 피드백은 `Just right` 한 탭만으로도 제출할 수 있어 개선 원인이 약하고, 버그 제보는 재현에 필요한 기대값·실제값·빈도·영향도를 구조적으로 받지 못한다. 또한 문자 그대로의 완료/결과 경험 중 Book Result, Quest 완료 축하, Home milestone 축하에는 피드백 입구가 없다.

결정은 다음과 같다.

1. 모든 실제 완료/결과 경험에는 선택적 `Tiger Pulse` 입구를 제공한다.
2. 학습 콘텐츠는 `신호 → 이유`의 두 번 선택으로 유용한 정형 데이터를 얻는다.
3. 버그 신고는 별도의 짧은 구조 폼으로 재현 가능한 정보를 받는다.
4. Book Result, Quest, milestone은 난이도 문항을 재사용하지 않고 해당 경험에 맞는 `경험 신호 → 이유`를 사용한다.
5. Passport는 학습 콘텐츠군을 넓게 경험하게 하는 보상으로만 유지한다. 피드백을 제출해도 다음 수업, 구독, CEFR 레벨, 보상 접근성은 절대 잠기거나 해제되지 않는다.

## 2. 범위

### 2.1 이미 연결된 학습 완료 변형

기존의 20개 학습·게임 완료 변형은 공통 `ContentFeedbackCard` 또는 전용 결과 카드로 유지한다. Cloze, Daily Challenge, Satz Arcade, Speed Match, Custom Pack Quiz/Matching/Typing, Chosung, Wordle, Kkeunmari, Daily Hangul, Grammar, Hangul Cards/Writing, Scenario, Listening, Review, Legacy Due, Custom Pack Play, Vocab Pack Result가 여기에 포함된다.

### 2.2 새로 연결할 문자 그대로의 완료/결과 경험

| 경험 | 표시 시점 | 안전한 컨텍스트 | Passport |
| --- | --- | --- | --- |
| Book Result | 분석 성공 또는 오프라인 결과가 표시된 뒤 | `book_analysis`, 결과 개수, 온라인/오프라인/속도제한 상태 | 없음 |
| Quest completion | 새 퀘스트 축하 애니메이션 뒤, 사용자가 Continue하기 전 | `quest_reward`, 카탈로그 quest ID, quest type/target의 정규화 요약 | 없음 |
| Home milestone | 실제로 화면에 표시한 streak/level/vocab milestone 시트 안 | `milestone`, milestone ID/type/value | 없음 |

다음은 결과 화면이 아니므로 자동 피드백 대상에서 제외한다: 책장·통계·학습 경로·Smalltalk·Hard Words 목록·온보딩·로그인·결제·설정·계정 삭제. Hard Words의 실제 학습 종료는 Review Session에 이미 포함된다.

## 3. 경험 설계

### 3.1 공통 원칙

- 결과 화면의 Continue, Next, Retry, Close는 먼저 보이고 언제나 사용 가능하다.
- Tiger Pulse는 자동으로 열리지 않는 보조 카드다. 단, Quest의 기존 자동 종료 다이얼로그는 애니메이션 뒤 명시적 Continue 단계로 바꿔 카드가 읽힐 시간을 보장한다.
- 카드의 주 제목은 `Tiger Pulse` / `Tiger-Check`, CTA는 `Give the tiger a clue` / `Gib dem Tiger einen Hinweis`로 현지화한다.
- 칩은 단일 선택, 최소 44dp 터치 높이, 색상 외 선택 상태, 긴 독일어 문자열이 잘리지 않는 Wrap/스크롤 레이아웃을 사용한다.
- 모든 앱 UI 문자열은 독일어와 영어만 ARB에 둔다. 화면 코드에 문자열을 직접 쓰지 않는다.
- 자유 텍스트에는 연락처·정답·개인정보·스크린샷을 쓰지 말라는 현지화 안내를 보이고, 앱은 원문 답안·OCR 텍스트·이미지 경로·단어 목록을 자동으로 붙이지 않는다.

### 3.2 학습 콘텐츠 Pulse

카드를 누르면 기본 진입은 카테고리 선택이 아니라 콘텐츠 품질의 빠른 두 단계다.

1. `How did this activity feel?` / `Wie war diese Übung für dich?`
   - `Too easy`, `Just right`, `Too hard`, `Not clear`
   - `Zu leicht`, `Genau richtig`, `Zu schwer`, `Unklar`
2. `What made it feel that way?` 또는 긍정 신호면 `What worked well?` / `Woran lag es?` 또는 `Was hat gut funktioniert?`
   - Explanation, Examples, Tasks, Pace, Audio, Translation
   - Erklärung, Beispiele, Aufgaben, Tempo, Audio, Übersetzung
3. 선택 메모와 명시적 `Send pulse` / `Check senden` 버튼

카드에는 작게 `Report a problem` / `Fehler melden`, `Something else` / `Etwas anderes` 링크를 두어 사용자가 필요한 흐름으로 바로 전환할 수 있다. 기존의 세 카테고리는 서버 데이터의 `bug`, `content`, `other`로 유지한다.

### 3.3 버그 신고

버그 경로는 다음의 작은 구조 폼이다.

1. 영역: Display, Answer, Audio, Translation, Navigation, Other
2. `What should have happened?` / `Was sollte passieren?`
3. `What happened instead?` / `Was ist stattdessen passiert?`
4. 빈도: Every time, Sometimes, Once / Jedes Mal, Manchmal, Einmal
5. 영향: I could continue, It slowed me down, I couldn't continue / Ich konnte weitermachen, Es hat mich aufgehalten, Ich konnte nicht weitermachen
6. 선택 메모

새 UI에서 2~5는 필수다. 이미 기기에 저장된 이전 형식의 버그 draft는 메시지만 있어도 재전송할 수 있어야 하며, 새 UI가 기존 outbox를 무효화하지 않는다.

### 3.4 기타 의견

`Something else` / `Etwas anderes`는 짧은 자유 입력만 필수로 한다. 기존 1,000자 상한을 유지한다.

### 3.5 비학습 결과 Pulse

| 경험 | 첫 질문 | 신호 | 두 번째 이유 |
| --- | --- | --- | --- |
| Book Result | How reliable did this result feel? / Wie zuverlässig wirkte dieses Ergebnis? | Looks right, Partly right, Doesn't look right, Not sure / Wirkt richtig, Teilweise richtig, Wirkt nicht richtig, Nicht sicher | Korean text, Word meanings, Grammar, Translation, Missing result / Koreanischer Text, Wortbedeutungen, Grammatik, Übersetzung, Ergebnis fehlt |
| Quest | Did this quest feel worth completing? / Hat sich diese Quest gelohnt? | Very motivating, A nice extra, Not motivating, I didn't understand it / Sehr motivierend, Nettes Extra, Nicht motivierend, Nicht verstanden | Goal, Difficulty, Reward, Instructions, Length / Ziel, Schwierigkeit, Belohnung, Anleitung, Dauer |
| Milestone | Did this celebration motivate you? / Hat dich diese Feier motiviert? | Loved it, Nice, Too much, Not meaningful / Hat mich gefreut, Schön, Zu viel, Nicht bedeutsam | Timing, Visuals, Reward, Message, Frequency / Zeitpunkt, Optik, Belohnung, Text, Häufigkeit |

이 세 경로는 유효한 피드백이지만 학습 콘텐츠군 Passport 도장을 받지 않는다. Passport가 단순 클릭 보상이 되거나 meta UX 의견 때문에 학습 커버리지 의미를 잃지 않게 한다.

### 3.6 성공·대기·실패 상태

- 서버 수락으로 확인된 경우에만 `Stamp earned!` / `Stempel gesammelt!`와 작은 버스트를 보여 준다.
- Passport 대상이 아닌 meta 피드백은 `Thanks — your pulse helps us improve.` / `Danke — dein Check hilft uns, besser zu werden.`만 보여 준다.
- 오프라인 또는 일시적 실패 후 로컬 outbox에 안전하게 저장되면 `Saved on this device. We'll send it when you're online.` / `Auf diesem Gerät gespeichert. Wir senden es, sobald du wieder online bist.`를 표시한다.
- pending 카드에는 `Try now` / `Jetzt senden`을 제공하며, 기존 `feedbackId`만 재전송한다. 새 draft나 두 번째 도장을 만들지 않는다.
- 자동 재전송은 앱 시작과 앱 resume에서 한 번씩 직렬화해 실행한다. 계정 삭제/비활성화/대기열 포화/검증 실패에는 재시도 CTA를 보이지 않는다.

## 4. 데이터 계약과 개인정보

### 4.1 기존 학습 콘텐츠 필드

기존 `contentSignal`과 `contentFocus`는 유지한다. 새 학습 UI는 두 필드를 모두 보내지만, 과거 outbox draft 호환을 위해 서버와 클라이언트는 기존의 부분 입력 또는 텍스트만 담긴 content draft를 계속 받아들인다. `contentFocus`에 `audio`를 추가한다.

### 4.2 버그 필드

`ContentFeedbackDraft`와 서버 payload에 아래 optional 필드를 additively 추가한다.

```text
expectedOutcome: string (0..500)
actualOutcome: string (0..500)
bugFrequency: every_time | sometimes | once | null
bugImpact: can_continue | slows_learning | blocks_learning | null
```

새 UI가 만든 bug draft는 issue area, expected outcome, actual outcome, frequency, impact를 모두 가진다. 이전 outbox는 message-only bug를 보존한다. 새로운 구조 필드가 하나라도 있는 draft는 전부가 유효해야 한다.

### 4.3 비학습 경험 필드

세 feedback-only content type에만 다음 optional 필드를 쓴다.

```text
experienceSignal: positive | mixed | negative | unsure | null
experienceFocus: korean_text | word_meanings | grammar | translation | result_missing |
                 goal | difficulty | reward | instructions | length |
                 timing | visuals | message | frequency | other | null
```

허용 조합은 content type별로 고정한다. Book Analysis는 reliability focus, Quest Reward는 motivation focus, Milestone은 celebration focus만 받는다. 기존 학습 콘텐츠는 experience 필드를, meta 콘텐츠는 learning difficulty 필드를 받지 않는다.

### 4.4 불변성과 전달

- local outbox schema version은 `1`로 유지한다. 모든 새 wire 필드는 선택사항이므로 기존 큐를 마이그레이션하거나 버리지 않는다.
- callable schema version은 `2`를 유지하며 allow-list에 새 선택 필드를 추가한다.
- document 경로와 `completionId` 기반 idempotency를 유지한다. 같은 completion은 최초로 수락된 feedback을 덮어쓰지 않으며 Passport 도장을 두 번 찍지 않는다.
- `book_analysis`, `quest_reward`, `milestone`은 server의 feedback-only allow-list에 넣되 mission allow-list에는 넣지 않는다.
- Book context에는 OCR 원문, 사진/이미지 lease, 추출 단어·문장·번역, page ID를 넣지 않는다. 개수와 결과 상태만 `scoreSummary`에 넣는다.
- Quest context에는 사용자 활동 이력이나 표시 이름을 넣지 않고 catalog ID/type/target의 정규화 값만 넣는다.
- Milestone context에는 displayed milestone의 ID/type/value만 넣는다. 전체 streak history 또는 단어 목록을 넣지 않는다.

## 5. 완료 상태 수명

`FeedbackCompletionSlot`은 UI rebuild에서 새 completion ID가 생기지 않게 한다.

- Book Result: analysis generation이 새로 시작되면 slot을 reset하고, 해당 generation의 성공 결과가 화면에 표시될 때만 하나 생성한다.
- Quest: 실제 새 quest 하나의 celebration마다 하나를 만들고, animation 이후 같은 dialog의 Pulse 카드에 넘긴다.
- Milestone: 실제로 표시하는 top milestone 하나에만 하나를 만들고 sheet로 넘긴다. 현재 모든 새 milestone을 미리 celebrated 처리한 뒤 하나만 표시하는 동작은 고친다. top 하나만 mark하고, 나머지는 다음 적절한 홈 진입에서 별도 시트로 표시한다.

## 6. 검증 기준

1. 기존 20개 학습 완료 변형과 Book Result, Quest completion, Milestone sheet에서 선택적 Pulse 입구가 보인다.
2. 학습 콘텐츠는 `signal + focus`, Book/Quest/Milestone은 `experience signal + focus`, bug는 재현 구조 필드를 전송한다.
3. 서버가 context type과 필드 조합을 검증하고, 직접 Firestore client write/read는 계속 거부된다.
4. 중복·오프라인·계정 삭제·구 소프트웨어 outbox draft가 현재 안전성을 깨지 않는다.
5. Passport는 server-accepted 학습 콘텐츠 feedback에서만 한 번 증가한다.
6. Flutter widget/route/model/outbox tests, Functions tests, Firestore rules tests, `flutter analyze`, `flutter test`, `git diff --check`가 통과한다.
7. 메인 branch를 수정·merge·push·deploy·AAB build하지 않는다. 실제 Android/iOS 수동 smoke는 코드 검증 후 별도 사용자 실행으로 남긴다.
