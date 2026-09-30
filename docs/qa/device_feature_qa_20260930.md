# Hangul Sori 실기기 기능 검사와 수정 — 2026-09-30

## 범위와 버전

사용자가 다른 세션에서 수행한 1번 앱 전반 자동 검사는 제외했다. 이 문서는 실제 설치본의 기능 경로 검사와 이번 수정의 로컬 검증을 분리해 기록한다.

| 대상 | 확인한 빌드 | 검사 방식 |
| --- | --- | --- |
| Xiaomi Redmi Note 10 Pro (Android 12) | Play 2.0.9 (`7680`) | ADB 화면·접근성 트리 조작, 완료 화면 캡처 |
| Xiaomi Pad 6 | Play 2.0.9 (`7680`), 별도 QA 앱 2.0.9 (`7698`) 설치 확인 | ADB 연결·설치 확인. 패턴 잠금 때문에 화면 내부 검사 보류 |
| iPhone 16 | TestFlight 2.0.9 (`255`) | 사용자가 제공한 `IMG_8041.PNG`–`IMG_8043.PNG` 시각 검토 |
| 로컬 수정본 | 검사 당시 기준 커밋 `832477d9e8d47de101a4553a7883e2b590685c5e` + 이번 변경 | Flutter 위젯 검사, 실제 서체 렌더링, 정적 분석, Android 디버그 빌드 |

이 문서는 수정 전 실기기 검사와 로컬 수정 검증의 스냅샷이다. 검사 당시 기기에 설치된 빌드에는 이 문서의 수정이 포함되지 않았다. 수정본을 기기에 설치하거나 TestFlight로 배포하지 않았다. 아래 캡처와 XML 증거는 작업 중 로컬 QA 아티팩트에 보관했으며 이 저장소에는 포함하지 않았다.

## Xiaomi 폰에서 실제로 확인한 경로

| 경로 | 결과 | 증거 |
| --- | --- | --- |
| Heute · Lernen · Spiele · Hanok · Gye 탭 | 이동 후 화면 표시와 복귀 정상 | `phone-home.png`, `phone-learn.png`, `phone-games.png`, `phone-hanok.png`, `phone-gye.png` |
| 첫 학습 카드 | 카드 뒤집기, 음성 버튼, 정답 처리, 다음 카드 이동 확인 | `phone-flashcard.png`, `phone-flashcard-back.png`, `phone-flashcard-next.xml` |
| Tages-Challenge | 10문항 완료, 결과·보상 `+70 XP`, 연속 학습 1일 확인 | `phone-daily.png`, `phone-daily-result.png` |
| 복습 | 6장 완료, 뒤집기 전 정답 버튼 차단, 완료 `+12 XP` 확인 | `phone-review-final-afterflip.png`, `phone-review-completion2.png` |
| Spiele / Anlaut-Quiz | 안내·건너뛰기·종료 경로 정상. 기존 `Überspringen` 버튼 줄바꿈 관찰 | `phone-anlaut.png`, `phone-anlaut-after-skip.xml` |
| Spiele / Silben-Rätsel | 퍼즐 1개 해결, 1/20 진행·`+30 XP` 확인 | `phone-syllable.png`, `phone-syllable-complete.xml` |
| Spiele / Lückentext | 첫 문항 정답 처리와 2/10 자동 진행, 종료 확인 | `phone-cloze-answer.png`, `phone-cloze-next.xml`, `phone-games-postcloze.xml` |
| Spiele / Blitz-Paare | 단어·뜻 2쌍 인정, 종료 결과 `+6 XP` 확인 | `phone-blitz-match.xml`, `phone-blitz-multi.xml` |
| Spiele / Satz-Arcade | 첫 문장 순서 정답 처리와 2/8 진행, 종료 확인 | `phone-satz-start.xml`, `phone-satz-answer.xml`, `phone-satz-exit.xml` |
| Spiele / Kkeunmari | 튜토리얼과 타이머 종료 결과 `Kette: 1`, `20 XP` 확인. 실제 단어 입력은 미검사 | `phone-kkeunmari-coach3.xml` |
| Meine Wörter | 목록 진입·복귀 확인. 저장 단어 0개라 개인 단어 퀴즈는 실행 불가 | `phone-customwords2.xml` |
| Hangul | 개요, 카드 뒤집기, 쓰기 획 판정·다음 글자·완료 확인 | `phone-hangul.png`, `phone-hangul-cards.png`, `phone-hangul-finish.png` |
| 오늘의 글자 | `ㅕ` 3획 수용, 완료·보상·연습일 저장 확인 | `phone-dailychar.png`, `phone-dailychar-complete.xml` |
| 설정 | DE↔EN 즉시 전환·복귀, 개인정보 옵션과 버전 화면 표시 확인. 데이터 삭제 동작은 실행하지 않음 | `phone-settings.png`, `phone-settings-en.png`, `phone-settings-about.png` |
| Gye 연령 제한 | 제한 화면과 선택지 표시 확인. 우회하지 않음 | `phone-gye-options.png` |

## 발견과 수정

| 발견 | 원인·수정 | 검증 |
| --- | --- | --- |
| Korean 빈칸 뒤 조사, 일부 낱말이 줄 사이에서 분리 | `ClozePromptCard`가 음절 단위 줄바꿈을 허용했다. 시각적 word joiner로 어절과 강조 빈칸·조사만 결합하고 공백에서는 자연스럽게 줄바꿈하도록 변경 | `cloze_prompt_wrap_test.dart`, 반응형 검사 |
| Anlaut-Quiz의 `Überspringen` 버튼이 두 줄로 표시 | 가용 폭 비율을 균등하게 하고 버튼 텍스트를 한 줄로 설정 | 320dp–1280dp 반응형 검사 |
| 오늘의 글자 경로에서 제목 중복 | 경로 본문 제목을 실제 글자로 변경 | `daily_calligraphy_route_ui_test.dart` |
| `ㄷ`의 기존 TTS가 ‘뜨’처럼 들린다는 사용자 피드백 | 사용자가 직접 녹음한 `ㄷ.m4a`의 두 번째 발음 구간을 정규화해 자모 수업에 연결 | 자산 해시·복호화·로컬 TTS 해석 검사. 자연스러움은 사용자 청취 판단 |
| 기존 `ㅡ`·`ㅢ` TTS 발음이 이상하다는 피드백 | A/B 파일의 앞소리(기존 TTS)는 틀리고 뒷소리(직접 녹음한 `으`·`의`)는 맞다고 사용자가 확인했다. 승인된 세 녹음을 자모 화면에 연결했고, 10모음 조합표에 있는 `드`·`으` 셀에도 해당 녹음을 연결 | 세 MP3의 SHA-256 확인, 로컬 오디오 해석 검사, APK 안의 실제 자산 확인 |
| 한글 음절 조합표 요청 | 14개 초성 × 10개 모음, 140개 음절. 셀을 누르면 선택 음절을 읽고 다시 듣기 가능. 휴대폰은 가로 스크롤, 패드는 10개 열 표시 | `hangul_syllable_table_test.dart`, `syllable-chart-main-390.png`, `syllable-chart-main-720.png` |
| 사용자 녹음 첫 재생에 AI 음성 고지가 뜰 수 있음 | 사람 녹음에는 고지를 미루고 실제 TTS를 처음 사용할 때 고지. 유휴 화면의 예약 콜백에도 프레임 요청 | `ai_voice_notice_test.dart` 6개 통과 |
| iPhone에서 바뀐 서체가 보이지 않음 | TestFlight 빌드 `255`는 새 통합 서체 변경 전 버전. Noto Sans KR 통합은 2026-09-30 커밋 `3e4973838`로 메인에 반영됨 | 최신 메인 기준 `pubspec.yaml`, `SoriFonts`, 실제 서체 렌더 캡처 확인 |

원본 사용자 녹음은 제공받은 위치에 그대로 두었다. 앱에는 사용자가 청취해 선택한 `ㄷ`, `으`, `의` 세 가공 클립만 넣었다. 기존 `모음.m4a`에서 뽑은 미승인 15개 클립은 저장소 밖 로컬 QA 아티팩트에 보관했다. A/B 비교 파일에서는 각각 뒤의 직접 녹음만 채택했다. 승인 녹음을 읽을 수 없을 때 기존 TTS로 돌아가지 않도록 했다.

## 로컬 수정본 검증

- 최신 수정 기준 자모 오디오·음절표·한글 상호작용·줄바꿈·오늘의 글자·AI 고지 검사 32개 통과. 폰트 번들 가드도 앞선 최신 메인 검사에서 통과.
- 휴대폰·패드 폭/글자 크기 반응형 검사 164개 통과.
- AI 음성 고지 검사 6개는 위 32개에 포함됨.
- 변경 파일 정적 분석 문제 0개, `git diff --check` 통과.
- 최신 메인 기반 Android 디버그 APK 빌드 성공. SHA-256 `65DD4144096FF79B73E248ECE67742240D714601DE03429618C875992B8D82B3`. APK 내부에서 `recorded_jamo/de.mp3`, `eu.mp3`, `ui.mp3` 세 개만 확인했고 소스와 해시가 같았다.
- 저장소 규칙의 `graphify update .` 완료. 이후 Git 병합 여부와 별개로, 설치본의 새 발음·UI 확인은 새 빌드가 필요하다.

## 최신 메인과 병합 전 재검증

- 메인 `42734bca0545382ad7301c9d73fc1044213b8c3c` 위로 이번 변경을 옮긴 뒤 관련 화면·음성 중복 처리 검사 52개 통과. `flutter gen-l10n` 재실행에도 추가 변경 없음.
- 전체 `flutter analyze --no-pub`에는 이번 변경 밖의 기존 테스트 파일 두 개에서 정보 수준 경고 3개가 남아 있다. 저장소 CI는 `--no-fatal-warnings --no-fatal-infos`로 분석하며, 이 브랜치의 실제 CI 결과는 PR 검사에서 별도로 확인한다.
- 해당 기준으로 Android 디버그 APK를 다시 빌드했다. SHA-256 `E85EAF2C9B38EB77A26B646037986C43564AE2734E5801A8BA923574E9F8194E`. APK 안의 승인된 세 음원은 소스와 바이트 해시가 같다.

## 아직 확인하지 못한 것

- Pad 6은 ADB에 연결됐지만 패턴 잠금이 표시된다. 사용자가 직접 잠금을 풀면 기존 Play 설치본에서 기능 경로를 이어서 검사해야 한다.
- Windows에서 iPhone TestFlight 앱을 원격 조작할 수 없다. 제공받은 세 장의 스크린샷만 확인했다. 새 서체·줄바꿈을 iPhone 실기기에 확인하려면 이 수정이 포함된 새 TestFlight 빌드가 필요하다.
- 이번에 사용자가 확인한 ‘으·의’ 직접 녹음은 로컬 수정본에만 연결돼 있다. 실제 Android·iPhone 설치본에서 청취 검사는 새 빌드가 설치된 뒤 필요하다. 다른 자모의 기존 TTS 발음까지 전체 승인된 것은 아니다.
- 계정 삭제, 클라우드 백업·복원, 결제, 외부 링크, 오프라인 전체 경로, Gye 연령 인증 이후 경로는 이번 실기기 검사에서 실행하지 않았다. 데이터나 계정 상태를 바꿀 수 있는 동작을 검사 완료로 표시하지 않았다.
- 검사 당시 설치된 Android/iOS 빌드에는 이 변경이 들어가지 않았다.
