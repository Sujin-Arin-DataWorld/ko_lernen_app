# 한글소리 전세계 정식 출시 준비 설계

기준: 2026-09-10, 앱 `2.0.9+37`. 시작 기준은 `aa0d932f69f6f738cb3ecd4847656edc0e7a09ff`.
작업 중 PR #290–#293 및 Graphify 운영 규칙 반영을 확인해 전용 브랜치를 메인
`7e844d1b7d751a31f3a666769224da68989523be`로 fast-forward했다. 기존 수정 파일의 SHA256을
전후 대조해 보존을 확인했다. Flutter·웹 검증은 `92353147`과 미커밋 수정의 조합에서 수행했으며,
이후 #293까지는 미사용 자산 보관·Graphify만 바뀌었다. `lib/assets/web/pubspec/test/tests` 등의
Git 객체와 수정 파일 해시가 동일하므로 앱 빌드 입력과 검증한 코드가 유지된다.

## 판단과 제품 방향

현재 판단은 **정식 출시 보류, 검증된 수정 후 출시 후보 검수 진행**이다. 시작 기준의 CI와
브라우저 검사는 성공했고 #290 병합 메인의 CI와 브라우저 검사도 모두 성공했다.
#291 병합 메인의 CI와 브라우저 검사도 모두 성공했다. `92353147`의 CI는 취소되었고 브라우저
검사는 성공했다. 현재 `7e844d1b`의 CI와 브라우저 검사는 모두 성공했다. 이 작업은
`24a77f79`로 커밋·푸시해 PR #294를 만들었다. 첫 PR CI의 Flutter 선택 검사에서
2686 성공·13 실패·7 skip을 확인했고, 로딩 위젯의 내재 높이 호환성과 소비 화면의 중복
Semantics 선언을 Task 7에서 수정한다. Playwright 6개와 나머지 선택된 gate는 성공했다.
이 기록은 최신 코드의 스토어 배포·실기기 안정성·운영 설정까지 증명하지는
않는다. 기능 수를 늘리기보다 학습 완료까지의 신뢰성을 먼저 확보한다.

이 계획의 네 가지 국소 수정은 구현과 실패 재현·회귀 검증을 마쳤다. 작업별 리뷰 이후 최종
독립 Standards/Spec 리뷰도 각각 APPROVED, 행동 가능한 지적 0건이다. Jin은 후속으로
커밋·푸시 → PR·CI → 서명 후보의 실기기 검수를 승인했다. 해당 후보의 CI·서명·스토어·
실기기 검증은 실제 결과에 따라 완료 판단한다.
추가로 기존 Android 심볼 도구 네 버전의 실행 파일 해시를 공식 배포 근거로 채웠고,
설정 반영 후 릴리스 계약 검사 78개를 통과했다. 추가 변경과 갱신된 근거도 독립
Standards/Spec 리뷰를 통과했고, correctness/security 검토의 행동 가능한 지적은 0건이다.

첫 공개 제품은 현재의 무료 학습 정책과 DE/EN UI, 한국어 학습 콘텐츠를 기준으로 한다.
전세계 배포 가능 지역과 UI 번역 언어 수는 별도 결정이다. 결제·광고·유료 잠금은 이번 작업에서
재도입하지 않는다. 상용 운영은 수익화뿐 아니라 비용 통제, 지원, 개인정보 처리, 복구 가능성을
포함한다. Sori Stage 5탭, 단청·한지·민화의 시각 정체성, 승인된 한옥·카드 원본을 유지한다.

## 확인한 근거

| 영역 | 현재 직접 확인 | 아직 필요한 근거 |
| --- | --- | --- |
| 기준 코드 | `7e844d1b`, 전용 작업 공간. 기본 main은 사용자 소유이며 이번 작업에서 수정하지 않음 | 통합 후 새 main SHA 검증 |
| 자동 검증 | PR #294 첫 head 24a77f79의 CI [34440487223](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34440487223)는 로딩 회귀 13개로 실패. Playwright [34440487213](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34440487213)는 6/6 성공 | Task 7 수정 이후 정확한 PR head의 필수 검사. 최신 결과는 PR 및 외부 영수증 확인 |
| 로컬 후보 검증 | Flutter 관련 24파일 207/207, Node 22 TTS 64/64, 전체 분석 무문제 및 후속 수정 3파일 재분석 성공. release 웹 빌드와 기존 6브라우저 시작·그리기 검사 성공(3.4분). 선언된 에셋·글꼴 887개가 웹 산출물에 모두 존재 | 수정 후보의 원격 CI, 실기기 음성·계정·진척 저장 검증 |
| 수동 웹 화면 | DE 동의 화면·Today·미션 데모를 1280×720 / 320×640에서 직접 확인. 좁은 화면의 본문·CTA가 표시되고 데모 뒤로 가기·닫기가 동작함. 임시 viewport 복원 | fixture 데이터의 무동작 학습 콜백은 실제 사용자 전체 학습 여정·음성 출력·진척 저장 검수를 대신하지 않음 |
| Android 배포 | Play Console 직접 확인: Alpha는 `16 · closed · 43769596`, versionCode 2266 / 2.0.9, 9월 7일 테스터에게 전체 출시, 177/177개 국가. CI [34155908835](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34155908835)와 SHA 일치 | 새 후보 AAB의 versionCode, 트랙 처리·설치 증거. 로컬 pubspec의 +37은 스토어 versionCode가 아님 |
| 최신 Android 업로드 | 다른 작업의 7e844d1b Closed Testing [34414481048](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34414481048) 성공, 중복 [34414496994](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/actions/runs/34414496994) 취소. Console에서 `18 · closed · 7e844d1b`, versionCode 2278, 177개 국가, 검토 중 확인. 기존 Alpha 16은 계속 테스터에게 제공 중 | 심사 완료와 2278 실제 설치·업데이트 검증. 이 작업의 미커밋 수정은 포함되지 않음. 다른 작업의 main 보류는 해제됨 |
| Google Play 공개 권한 | 프로덕션 액세스 승인됨. 프로덕션은 비활성, 생성·게시 1/5 완료. 국가/지역은 177개 타겟팅됨. 공개 테스트 임시 트랙은 프로덕션 국가와 동기화됨 | 권한 재신청이 아니라 최종 후보 버전 생성·검수·심사·게시가 남음. 국가 변경 시 공개 테스트에 미치는 영향 확인 |
| 기존 제공 AAB | Console의 2266.aab 표시: 신규 설치 크기 291MB, 다운로드 시간 추정 2분 52초, 업데이트 5.88MB. API 24+, target 36, 16KB 지원 표시. 관리형 게시 사용 중지 | 이 값은 43769596 배포본의 Console 표시값이다. 새 2278과 이 작업의 수정 후보를 대신하지 않음 |
| 새 2278 AAB | 성공한 CI artifact의 AAB 386,314,757 bytes. 제공된 SHA256 일치, `jarsigner -verify` 및 bundletool 1.18.3 validate 성공. 실제 manifest versionCode 2278 / 2.0.9, minSDK 24 / target 36, debuggable false, 진단·광고 ID 수집 manifest 기본값 false | Play 인증서와 서명 주체 대조·동의 후 런타임 수집 동작·실기기 설치는 별도. AAB의 native debug metadata는 기기 설치 자료와 구별 |
| 2278 다운로드·16KB | Console 신규 설치 크기 296MB, 다운로드 시간 추정 2분 54초, 업데이트 11.1MB, 16KB 지원 표시. 수동 설정 arm64/API36/DE/480dpi 예상 다운로드 295,347,057 bytes, armv7/API24/EN/320dpi 293,645,333 bytes. 64비트 native 12개 LOAD 정렬과 생성 split APK 10개의 `zipalign -P 16` 검사 성공, bundle config는 `PAGE_ALIGNMENT_16K` | Console 표시값·bundletool 추정·정적 검사다. unsigned split은 크기 분석 전용이며 실제 다운로드나 16KB 기기 실행 증거가 아님 |
| Android 코드 최적화 | 2278의 R8 9.0.32, 최적화·난독화·축소 켜짐, full mode. AAB ZIP 기준 에셋 269,450,300 bytes, DEX 6,487,261 bytes. 중복 에셋 제거로 줄일 수 있는 ZIP bytes는 91,914뿐 | 큰 비용은 에셋 전달·사용 시점부터 조사. broad keep 축소는 서명 release의 인증·App Check·OCR·알림·음성·비디오 검수를 전제로 판단. R8 비율은 앱 완성도나 Flutter 프레임 성능 수치가 아님 |
| Android 심볼 검증 | 2278 workflow의 gate 단계는 비활성. 9월 10일 GitHub 저장소와 google-play-internal 환경 메타데이터 조회에서 심볼 전용 credential 및 두 변수가 조회되지 않음. 기존 도구 네 버전의 publisher archive와 실행 파일 해시를 검증해 로컬 pin·provenance 준비, 계약 검사 78/78 | credential·앱 ID·gate 활성화 후 정확한 SHA의 CI가 도구와 심볼 검증 영수증을 확인해야 완료. 현재 조회 결과는 실제 심볼 업로드 실패의 증거가 아님 |
| 공개 정책 페이지 | `/privacy`, `/terms`, `/account-deletion`, `/impressum` GET 200, CSP 존재, no-store 응답 | 삭제 요청의 실제 완료, 데이터 처리 선언과 배포 서버의 일치 |
| UI | Sori Stage 반응형·큰 글자 기존 검사 및 공통 상태 위젯 소스 확인 | TalkBack/VoiceOver, 실제 저사양 폰·iPhone의 최종 화면 |
| 시작·동의 | 시작·계정 저널·동의 관련 기존 테스트 성공 | 실제 계정 연결·삭제·재설치 복구 시나리오 |
| 병행 작업 | PR #289 CEFR 내용 감사 OPEN (`03437a6f`), #290 끝말잇기·#291 표기 감사·#292 B2 카드·#293 한옥 보관 MERGED; #285 배포/업데이트 알림은 별개의 과거 OPEN PR | #289 작업과 충돌 여부, #285 필요 변경의 별도 검토. 이번 심볼 pin·runbook·provenance는 #285 파일과 겹치지 않음 |
| 기기 | `adb devices` 연결 기기 없음. emulator 실행 파일은 있으나 AVD와 system image 없음 | 실기기 설치, cold start, 음성·녹음·권한·백그라운드 전환 |
| 로컬 빌드 환경 | Flutter 3.44.8/Dart 3.12.2, Android SDK 36, NDK 28.2, JDK 21 확인. 기존 로컬 release key의 unlock과 2278 업로드 인증서 일치를 확인했으며 원본 설정·키는 수정하지 않음. 일부 SDK 라이선스는 미수락 | CI 고정 Flutter 3.44.0의 최종 SHA 검사 후 임시 ignored 설정으로 서명 빌드·검증. 업로드 인증서와 Play 설치 인증서는 구별하며 실제 설치·업데이트는 기기에서 확인 |
| 운영 함수 | 9월 9일 조회에서 Gen2 33개 ACTIVE 확인. 9월 8일 15:46–15:47 UTC에 `synthesize-tts` HTTP 500 5건 | 해당 500의 원인과 수정/배포 후 정상 호출. 현재 로그는 `internal`만 남아 원인 구별 불가 |
| 설치 용량 | #292 반영 후 pubspec 직접 선언 에셋·글꼴 887개, 원본 280,386,448 bytes. 회전 이미지 44.5MB, 장면 배경 38.8MB, 캐릭터 영상 23.3MB | 생성된 asset manifest와 AAB/IPA의 실제 압축 다운로드·설치 크기, 화면별 이미지 decode 메모리 |

## 이번 실행의 수용 조건

### 1. 취소된 음성이 현재 화면에 오류를 남기지 않는다

`TtsPlaybackEngine`의 이전 resolve Future가 stop/dispose/다음 재생 뒤에 실패해도
이전 요청의 진단 콜백과 `unavailable` 상태를 새 요청에 게시하지 않는다. 활성 요청의
offline/quota/device 실패 안내는 유지한다. 엔진 바깥 resolver의 직접 상태 변경도 점검한다.
이미 사용 중인 generation/session 소유권을 확장하며 계정 전환·삭제 방어는 유지한다.

### 2. 캐시는 재생의 필수 조건이 아니다

정본 한국어 콘텐츠에 한해, 사용할 수 있는 다운로드 음성 바이트는 캐시 폴더/쓰기 실패에도
재생할 수 있어야 한다. 디스크 성공은 기존 파일 재생을 유지하고 실패는 기존 바이트 재생을
사용한다. 메모리는 기존 64항목 상한을 지킨다. 개인 문장에는 공용 디스크·Storage 경로를 열지 않는다.
prefetch의 null/예외 결과는 다음 호출에서 다시 시도할 수 있어야 하며, 동시 중복 요청과 성공한
요청은 억제한다. prefetch는 계속 `allowSynthesis: false`다.
검증 범위는 반환된 폴더 오류·쓰기 실패다. 기존 폴더 생성/쓰기 함수에는 작업 시한이 없어,
영구적으로 정체된 파일시스템까지 이 수정으로 복구됐다고 주장하지 않는다. 기기 지연 검수에서
이 조건을 따로 확인한다.

### 3. 공통 로딩 상태를 누구나 인지할 수 있다

약 40개 학습 화면에서 쓰는 `AppLoading`은 전달된 메시지 또는 기존 DE/EN 로딩 문구를
한 번만 화면 읽기에 노출한다. 장식 이미지에는 중복 음성 라벨을 붙이지 않는다. 320dp 폭,
200% 글자, 짧은 가로 화면에서 메시지/이미지가 RenderFlex overflow를 만들지 않아야 한다.
기존 로고와 일러스트, reduced-motion 동작은 보존한다. 작은 로딩 위젯을 새로운 전면 화면으로
확대하지 않으며, 바깥 스크롤 안의 unbounded-height 호출도 지원한다.

### 4. 운영 오류를 개인정보 없이 구별한다

실제 TTS 500 5건(2026-09-08 15:46–15:47 UTC)의 앱 로그는 모두
`synthesize_tts error internal`이다. 오류율의 분모나 근본 원인은 이 기록으로 알 수 없다.
기존 예외 로그에 코드가 정한 처리 단계와 allowlist 기반 SDK 오류 분류만 남긴다.
오류 메시지/stack/사용자 문장/UID/음성 경로/토큰은 기록하지 않는다. gRPC 정수 오류 코드는
정해진 문자열로 변환한다. 외부 응답과 quota/refund/계정 삭제 정책은 바꾸지 않는다.
이 개선은 진단 준비이며 관측된 production 500을 해결했다는 의미가 아니다.

### 5. 심볼 검증 도구의 출처가 재현 가능하다

기존 bundletool·firebase-tools·Temurin·Node 버전을 유지하고 공식 배포 archive의 digest 또는
npm integrity를 먼저 대조한 다음 CI가 실행하는 정확한 member의 SHA256을 계산한다.
Java/Node는 Linux x64 기준이며 Windows 개발 런타임이나 CI의 pin 설치 전 기본 Node 해시를
재사용하지 않는다. 공개 provenance에는 배포 URL·독립 digest 근거·member·해시를 기록한다.
이 준비는 gate 활성화·실제 심볼 업로드·난독화된 crash의 복원 검증과 구별한다.

## 출시까지의 우선순위와 완료 기준

| 순서 | 개선 작업 | 완료 기준 | 담당/의존성 |
| --- | --- | --- | --- |
| P1 지금 | 음성 취소·캐시·prefetch 경합 복구 | 실패를 먼저 재현한 테스트가 수정 후 성공, 기존 개인 음성/계정 경계 검사 유지 | 이 계획의 Task 1–2 |
| P1 지금 | 공통 로딩 접근성·작은 화면 | DE/EN 의미 라벨, 2배 글자, bounded/unbounded 레이아웃, 모션 검사 | Task 3 |
| P1 지금 | TTS 서버 오류 진단 | provider/cache/account 등 단계와 허용된 오류 코드만 기록, 개인정보 canary 비노출 | Task 4, 서버 배포 별도 |
| P1 지금 | Android 심볼 도구 검증 준비 | 고정 버전의 publisher archive·실행 파일 SHA256 일치, 기존 계약 검사와 독립 리뷰 통과 | Task 6, 활성화와 정확한 SHA의 심볼 업로드 검증 별도 |
| P0 공개 전 | 정확한 릴리스 후보 연결 | 소스 SHA → main CI → 서명 AAB/IPA → versionCode/build → 스토어 처리 → 설치를 한 줄로 추적 | PR #285와 중복 구현하지 않고 통합 결과 검사 |
| P0 공개 전 | 개인정보·계정·지원 | 실제 신규 사용자 동의/철회, 계정 연결/삭제/복구, 공개 삭제 요청, App Check 정상·실패, 지원 연락처 확인 | `docs/release-readiness.md`, `docs/store/firebase-backend-release-gates.md` |
| P0 공개 전 | Android/iOS 실제 사용자 여정 | 신규 설치와 업데이트 각각: 동의 → 온보딩 → 첫 학습 → 음성 → 결과 → 진척 → 재시작; 오프라인·권한 거절에서도 데이터 손실 없음 | 서명된 정확한 후보, 테스트 기기 |
| P1 공개 전 | 성능·장애 운영 | 아래 기기별 측정과 경보/복구 리허설을 기록; 미측정값을 성공으로 채우지 않음 | 릴리스 담당/개발 |
| P1 공개 전 | 설치·에셋 비용 | AAB/IPA 설치·다운로드 크기와 실제 화면의 decode 크기를 측정. 상위 용량부터 지연 로드·해상도·번들 범위를 비교하고 시각/오프라인 회귀 검사 | 원본 보존, `declared-assets-92353147.json`은 원본 bytes만 측정 |
| P1 공개 전 | Android keep 규칙 정밀화 | 기존 minify/shrink를 유지하고 `android/app/proguard-rules.pro`의 broad keep를 패키지별로 축소. 변경 전후 AAB 크기·R8 보고서·실기기 release 기능 검사 대조 | 광범위한 일괄 삭제는 하지 않음. 서명 후보와 기기 확보 후 별도 검증 |
| P1 공개 전 | 콘텐츠 및 디자인 완결성 | 각 A1–C2 진입, 듣기/발음/게임의 빈 상태·오류·복귀, DE/EN 긴 문구, 빛/어둠·글자 확대 확인 | PR #289 및 콘텐츠 작업과 조정 |
| P1 확대 전 | 비용·서버 용량 | active learner당 요청·캐시 적중·p95·오류·비용을 실제 측정, 예산/서비스 quota 소유자 확정 | 운영 통계, 새 과금·quota 설정은 소유자 결정 |
| P2 출시 후 | 언어/성장/수익화 | 동의한 사용자의 첫 학습 완료·7일 재방문·지원 이슈를 기준으로 다음 언어/상품 가설 선택 | 무료 공개 정책을 임의로 번복하지 않음 |

### 디자인 실행 기준

- Today의 다음 학습 행동 하나와 결과 후 다음 행동을 쉽게 찾는다. 기존 헤더·탭을 교체하기 전에
  320/390/720dp, DE/EN, light/dark, 100/200% 글자에서 실제 막힘을 증명한다.
- 모든 학습 경로는 loading/empty/offline/error/success/back 상태를 갖고, 재시도는 진척을
  중복 기록하지 않는다. 긴 설명을 새 pill/배지로 늘리지 않는다.
- 48dp 터치 영역과 명확한 화면 읽기 라벨을 검사하고, 음성 재생 상태를 1초 안에 보여 주거나
  재생 준비 중임을 표시한다. 실제 TalkBack/VoiceOver 결과를 자동 테스트와 별도로 기록한다.
- 카드나 한옥 재제작은 별도 자산 승인 절차를 따른다. 이번 안정화에는 새 생성 그림이 필요 없다.

### 성능·운영 측정 기준

아래 값은 **제안하는 내부 출시 기준**이며 현재 달성했다는 수치가 아니다.

- 기기별 신규/기존 설치 cold start 20회, 첫 사용 가능 화면 p95 3초 목표. 오래 걸리면 2초 내
  진행 상태가 보여야 한다. 오프라인 캐시 학습과 온라인 최초 음성의 지연을 분리한다.
- 기준 기기에서 학습/탭 전환/한옥 각 5분 profile: 60Hz 프레임 예산 16.7ms, 긴 멈춤 원인을
  DevTools로 기록한다. 비디오·오디오 객체가 20회 화면 왕복 후 누적되는지 비교한다.
- 에셋 원본 280.4MB를 스토어 다운로드 크기로 표시하지 않는다. release asset manifest와
  bundletool/스토어의 기기별 크기를 대조한다. 첫 학습에 필요한 자료와 한옥 상세 보기의 자료를
  구분해 메모리·네트워크 비용을 측정하고, 원본 보존 및 오프라인 요구를 충족하는 변경만 적용한다.
  `ildu_world_screen.dart`에는 이미 지도/오브젝트별 `cacheWidth` 제한이 있다. 원본 이미지
  크기만으로 런타임 메모리를 단정하거나 같은 최적화를 중복 도입하지 않는다.
- 배포본 2266의 Console 291MB, 소스 원본 에셋 280.4MB, 새 2278의 Console 296MB와
  bundletool 기기별 예상 다운로드 293.6–295.3MB는 측정 기준을 구분한다. AAB 안의 ZIP 기준 에셋은
  269.45MB로 DEX 6.49MB보다 크고 중복 정리 여지는 약 92KB다. 회전 이미지·장면·영상의
  사용 시점과 오프라인 계약을 먼저 확인하고 후보별 전송 bytes와 로딩 지연을 비교한다.
- R8 keep 규칙은 먼저 최종 병합된 configuration/usage/mapping 보고서로 보호 이유를 확인한다.
  `io.flutter.**`, `com.google.firebase.**`, `com.google.android.gms.**` 등을 한 번에 해제하지 않고
  플러그인 하나씩 consumer rules와 reflection 경로를 대조한다. 매 단계에서 서명 release의
  핵심 기능을 재검수하고 실제 DEX/AAB 절감이 확인된 변경만 채택한다. 이 방향은
  [Android R8 최적화 지침](https://developer.android.com/topic/performance/app-optimization/enable-app-optimization)의 keep 규칙 정밀화·최종 release 검증 원칙을 따른다.
- 최소 7일 테스트 구간의 crash-free sessions 99.8% 목표, ANR 0.1% 미만 목표. 표본 수와
  opt-in 진단의 수집 범위를 함께 적고, 표본이 작으면 출시 품질의 확정치로 사용하지 않는다.
- TTS·발음·책 분석은 오류율, latency p50/p95, cache hit, 요청 수와 비용을 구분한다.
  429/timeout은 사용자 안내와 재시도 정책을 확인한다. 비용 절감을 위해 무단 재합성을 하지 않는다.
- 지원 요청 수신 → 재현 → 오류 식별 → 수정 → 재배포 담당과 연락 경로를 확정한다.
  장애 시 해당 기능 중단/기존 검증 후보 재배포 절차를 플랫폼별로 시험한다. 존재하지 않는
  Remote Config 키를 임의로 추가하지 않는다.

### 스토어와 지역 확대

Android/iOS는 별도 완료 판정을 한다. Google Play의 production 접근 권한은 이미 승인되었고
프로덕션 국가 177개가 선택되어 있다. 공개 테스트의 국가도 프로덕션과 동기화되어 있으므로
추후 범위를 변경할 때 두 트랙의 영향을 함께 확인한다. 이번 조회에서 설정을 저장하거나
버전을 생성·제출하지 않았다. Data Safety·대상 연령·pre-launch report와 App Store Connect의
review/build/privacy 상태는 마지막 후보에서 확인한다. 정책 웹페이지 200만으로 처리 동작이나
스토어 선언을 승인하지 않는다. 지원 가능한 최초 공개 범위를 확정한 뒤 내부/비공개 검수 → 가능한 범위의 제한 공개 → 확대 순으로
진행한다. 첫 production 배포에서 percentage rollout이 지원된다고 전제하지 않고 Console이
제공하는 배포 방식을 확인한다. 각 확대는 오류/비용/지원 용량 근거가 생긴 뒤 결정한다.

## 작업 범위와 승인

사용자는 계획 수립 후 실행을 요청했다. 기존 동작의 국소 수정과 로컬 검증은 계속 진행한다.
검증된 diff에 대해 Jin이 커밋·푸시·PR·CI 및 서명 후보의 실기기 검수를 승인했다.
승인한 작업을 계속 진행하며, 실제 병합·스토어 트랙 변경은 해당 동작의 권한과 조건을 확인한다.
생산 서버 변경·스토어 제출은 정확한 후보와 검증 자료가 준비된 단계에서 별도로 확정한다.
타 작업 공간·개인 데이터·진행 중인 PR 변경을 가져오거나 수정하지 않는다.

## 공식 기준

- [Android core app quality](https://developer.android.com/docs/quality-guidelines/core-app-quality)
- [Android vitals](https://developer.android.com/topic/performance/vitals)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

- [Android bundletool](https://developer.android.com/tools/bundletool)
- [Android 16KB page sizes](https://developer.android.com/guide/practices/page-sizes)

2026-09-09–10 공식 문서를 확인했다. 배포 시점에는 Console 상태와 적용 정책을 다시 확인한다.
