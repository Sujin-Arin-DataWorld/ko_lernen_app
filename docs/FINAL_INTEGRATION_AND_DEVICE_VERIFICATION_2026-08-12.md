# 2026-08-12 최종 통합·실기기 검증표

> 원칙: 커밋 존재, 테스트 통과, 실기기 정상은 서로 다른 증거다. 아래 상태는
> 확인한 범위만 표시하며, 청감·외부 토큰·스토어 환경은 코드 검증으로 대체하지 않는다.

## 통합 기준

- Claude 최종 기준: `78fa742` (`하` 무음 검출용 TTS 음량 게이트 포함)
- Codex 통합: `2be3af2` (`78fa742` 위 Hangul 음성 carrier·즉시 재생·쓰기 포인터 수정)
- 검증표·format 포함 검증 HEAD: `34dc299`
- 통합 브랜치: `codex/final-integration-on-78fa742`
- 사용자 소유 사이트 WIP와 별도 저장소 커밋은 이 Flutter 통합에서 건드리지 않았다.
- 푸시는 이 세션의 권한 범위가 아니므로 하지 않는다.

## Worktree·브랜치 전수 판정

| 대상 | 판정 | 근거·처리 |
|---|---|---|
| `codex/ux-mockup-01-06-complete` (`85fa940`) | 이미 흡수 | `78fa742`의 조상이며 30커밋 뒤. 추가 병합 없음. |
| `codex/post-merge-p2-fixes` (`90d2561`) | 이미 흡수 | `78fa742`의 조상이며 27커밋 뒤. onboarding 후속까지 main에 존재. |
| `integration/2026-08-12` (`601b158`) | 이미 흡수 | `78fa742`의 조상이며 10커밋 뒤. |
| UX 01–02 (`6a8db8b`) | 병합 금지 | 별도 계보 6커밋이 남지만 최신 main보다 74커밋 뒤. 완성 브랜치에 대체 구현이 있으며 병합 시 최신 course/no-write 계약을 되돌린다. |
| UX 03–04 (`9d978e1`) | 병합 금지 | 별도 계보 6커밋, 최신 main보다 74커밋 뒤. 완성 브랜치가 대체. |
| UX 05–06 (`f3c6648`) | 병합 금지 | 별도 계보 4커밋, 최신 main보다 74커밋 뒤. 최신 Gye·Profile 계약이 후속 구현으로 대체. |
| Gallery (`f0950f8`) | 병합 금지 | 별도 계보 4커밋, 최신 main보다 53커밋 뒤. production preview가 후속 완성 브랜치에 존재. |
| detached account worktrees (`69de017`) | 제외 | 최신 main 이전 계보이며 현재 Gye/course 기능을 제거하는 역방향 차이가 포함된다. |
| 예전 Codex 통합 브랜치 (`305b814`, `35f4bd0`) | 대체됨 | Claude 기준이 `78fa742`로 갱신되어 새 브랜치에서 다시 통합했다. |

## 디자인 01A–06C 실제 코드 확인

`lib/screens/ux_preview_app.dart`와 `test/ux_preview_app_test.dart`의 20개 패널을
대조했다. 모든 ID가 production widget 또는 명시적 no-write preview seam으로 등록돼 있다.

| 묶음 | 패널 | 현재 production/preview 표면 | 상태 |
|---|---|---|---|
| 01 | 01A–01D | Consent, OnboardingStart, FirstVoiceSuccess, CharacterSelection | 코드·레지스트리 존재 |
| 02 | 02A–02D | Home, CourseMission, Scenario action/result | 코드·연속 fixture·no-write 회귀 존재 |
| 03 | 03A–03C | HanokWorld early/map, Sarangbang | 코드 존재; 한옥 월드 실기기 진입 확인 |
| 04 | 04A–04C | PracticeHub, Discover, LearningPath | 코드·직접 route 회귀 존재 |
| 05 | 05A–05C | Gye landing, exact scene, reactable feed | 최신 exact provenance/no-write 구현 존재 |
| 06 | 06A–06C | Profile, offline Today, review-first Home | deterministic preview·offline 상태 구현 존재 |

결론: 한옥 월드는 main에서 빠진 것이 아니었다. `/hanok`, `/hanok/anbang`,
`/hanok/daecheong` route와 `HanokWorldScreen`, personal-hanok 모델·자산·테스트·골든이
모두 있다. 오래된 UX 브랜치를 합치는 대신 현재 완성 계보를 유지하는 것이 맞다.

## 이번에 실제로 추가·수정한 누락

| 항목 | 수정 | 자동 검증 | 실기기 상태 |
|---|---|---|---|
| `ㅃ` 기계음 | 단독 낱자 대신 `빵` carrier | carrier 매핑 회귀 | 즉시 새 `female\|빵` cache 요청 확인; 자연스러움 최종 청감 필요 |
| `ㄷ`가 “뜨” | `다리` carrier | carrier 매핑 회귀 | 코드·자동검증 통과; 최종 청감 필요 |
| `ㅏ` 무음 | `아빠` carrier | carrier 매핑 회귀 + Claude 음량 게이트 보존 | 코드·자동검증 통과; 최종 청감 필요 |
| `ㅠ`가 “육” | `유리` carrier | carrier 매핑 회귀 | 코드·자동검증 통과; 최종 청감 필요 |
| `ㅢ`가 “에” | `의자` carrier | carrier 매핑 회귀 | 코드·자동검증 통과; 최종 청감 필요 |
| 낱자 탭 즉시 재생 | overview cell과 카드 본체 탭에서 즉시 TTS | widget interaction 회귀 | `ㅃ` 탭→요청 213ms·새 cache hash 확인 |
| Schreiben 1·2획 미표시/스크롤 | 캔버스가 raw pointer를 선점하고 revision repaint | widget interaction 회귀 | `ㄱ` 첫 획·둘째 획 즉시 표시, 페이지 미스크롤 |
| `ㄴ` 쓰기 불가 | 글자 변경 시 획수 초기화, 기존 ㄴ 획 경로 사용 | widget interaction 회귀 | `ㄴ` 세로+가로 획 즉시 표시 |
| Flughafen 중간 공백 | 무한 높이에서 `Spacer`를 만들지 않음 | production `airport_arrival` roleplay 회귀 테스트 | 첫 roleplay 화면·단어 타일 렌더 확인; Claude는 2/3까지 확인 |

## 실기기 검증표

기기: Redmi Note 10 Pro (`M2101K6G`, Android 12, 1080×2400, density 440),
package `com.sujinarin.ko_lernen_app`. 기존 데이터를 지우지 않고 `adb install -r`을 썼다.

| 검증 대상 | 상태 | 실측 근거 | 증명 경계 |
|---|---|---|---|
| APK 설치·실행 | PASS | debug APK `adb install -r` 성공, `MainActivity` foreground | 스토어/release 서명 검증 아님 |
| 홈 호랑이 흰 사각형 | PASS | 화면 안팎 12점과 세로 band가 모두 `#FBF5EB`; 새 화면에서 경계 없음 | 이 Redmi/light theme 기준 |
| Home hero matte 자산 | PASS | magpie 113프레임, tiger 121프레임 100% matte checker | Android 합성과 별도로 checker도 통과 |
| Flughafen 공백 지점 | PASS | `rollenspiel` 1/3에서 문장 타일·검사 UI 렌더, crash/flutter error 없음 | Codex는 첫 화면, Claude는 2/3 진행까지 확인 |
| Hangul `ㅃ` 즉시 요청 | PASS | `female\|빵` SHA-1과 일치하는 신규 cache 파일, 탭 후 213ms | 사람 귀의 자연스러움은 Jin 청감 필요 |
| Hangul 나머지 4 carrier | PARTIAL | 코드·회귀 테스트로 exact carrier 보장 | 실기기 개별 청감 미완료 |
| Schreiben `ㄱ` 1·2획 | PASS | 첫 획과 둘째 획이 각각 즉시 카드 안에 표시, 바깥 ListView 미스크롤 | 해당 기기/현재 gesture 환경 |
| Schreiben `ㄴ` | PASS | 2/19 카드에서 세로·가로 획 표시 | 판정 완료까지는 수행하지 않음 |
| 한옥 월드 진입 | PASS | Discover `Für mich` → `Meine Hanok-Welt`; A1 마당·진행 카드 렌더, crash buffer 비어 있음 | 모든 방/성장 단계 순회는 미수행 |
| 01A–06C 전체 실기기 순회 | NOT RUN | 코드·preview·회귀 테스트로 통합 존재 확인 | 20패널 전부를 기기에서 수동 순회한 것은 아님 |
| Wortkette `병가`, Buchseite 추출 | BLOCKED | App Check 토큰이 필요한 외부 운영 항목 | 코드 병합으로 해결할 수 없음 |

## 최종 자동 게이트·빌드

정확한 검증 HEAD `34dc299`에서 실행했다.

- focused Flutter: **78/78 PASS** — Hangul, production Flughafen, 01A–06C,
  no-write, Hanok World 포함.
- `python -m py_compile tool/generate_tts.py`: PASS.
- Home hero matte: magpie **113/113**, tiger **121/121** frames PASS.
- `flutter analyze --no-pub --fatal-infos`: **No issues found**.
- `flutter test --no-pub --concurrency=1`: exit 0, 실패 0, skip 14.
- `flutter build apk --debug --no-pub --dart-define=FREE_LAUNCH=true`: PASS.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`, 371,064,318 bytes,
  SHA-256 `E26AE675C1C79169928287C810E7B98450DFD68B11E3E70155BF54A6865F29BA`.
- `adb install -r`: **Success**; 설치 뒤 `MainActivity` foreground, PID 11825.

## 보관한 실기기 증거

저장소 바깥 작업 폴더에 보관했으며 제품 asset으로 커밋하지 않았다.

- `C:\Users\vjinn\OneDrive\Desktop\hangulsori\device-final-home-valid.png`
- `C:\Users\vjinn\OneDrive\Desktop\hangulsori\device-airport-roleplay.png`
- `C:\Users\vjinn\OneDrive\Desktop\hangulsori\device-write-one.png`
- `C:\Users\vjinn\OneDrive\Desktop\hangulsori\device-write-two.png`
- `C:\Users\vjinn\OneDrive\Desktop\hangulsori\device-nieun-after.png`
- `C:\Users\vjinn\OneDrive\Desktop\hangulsori\device-hanok-world.png`

## 최종 사용자 확인이 필요한 것

1. 새 APK에서 `ㅃ/ㄷ/ㅏ/ㅠ/ㅢ` 다섯 음성을 사람 귀로 각각 듣고, 단어 carrier가
   자연스러운지 확인한다. 자동 테스트는 요청·파일·문구를 증명하지만 음질 판단은 못 한다.
2. Wortkette와 Buchseite는 App Check 등록 뒤 다시 실기기 검증한다.
3. 이 표의 `NOT RUN`을 `PASS`로 바꾸려면 01A–06C 20패널을 실제 release 후보 빌드에서
   순차 수동 확인해야 한다.
