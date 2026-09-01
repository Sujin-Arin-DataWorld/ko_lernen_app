# 출시 QA 체크리스트 — Hangul Sori

> **이 문서가 출시 전 수동 검증의 정본이다.**
> 자동화된 것은 CI가 매번 돌린다(§0). 여기 남은 항목은 **사람과 실기기만 할 수 있는 것**이다.
>
> 학습 루프 Phase 5의 Android Closed Testing 운영·후보 기록·14일 종료 조건은
> `docs/store/closed-testing-checklist-v2.md`가 정본이다. 이 문서는 그 절차에서
> 참조하는 실기기 QA 매트릭스다.
>
> 작성 2026-08-06 · 현재 후보의 commit/versionCode는 closed-testing 정본에서 실제
> 검증 뒤 기록한다. iOS 항목은 장기 QA로 유지하지만 이번 Android beta의 종료 게이트는 아니다.

---

## Phase 5 학습 루프 Android beta acceptance

이 절은 `docs/store/closed-testing-checklist-v2.md`의 §3–§6과 함께만 완료 처리한다.

- [ ] Play Internal testing에서 설치한 release build로 App Check, update 보존, release-only
  asset/minify/crash를 확인했다.
- [ ] 첫 pack에서 모든 Learn 카드 노출 → Quiz/Boss shuffled order → 70% clear → 다음 pack
  unlock → 재실행 보존을 확인했다.
- [ ] 적용 대상 계정은 12명 이상이 14일 연속 opt-in했고 P0/P1/P2 트리아지가 진행 중이다.
- [ ] Boss를 recognition assessment로, typing recall을 optional practice로 안내한다.

---

## Onboarding V2 Android/iOS beta acceptance

자동 테스트가 상태 머신과 레이아웃 계약을 검증하더라도 실제 디코더, OS process-death,
권한 시트, TalkBack/VoiceOver, Remote Config 콘솔은 기기에서 확인해야 한다. 아래 항목은
신규 설치 사용자에게 V2를 켜기 전의 별도 출시 게이트다.

### 신규 설치와 중단 복구

- [ ] 새 설치에서 `법적 동의 → 필수 설명 5장 → 목적+레벨 → Taego/Joy → 선택 영상+확인
  → 솟을대문 → Today` 순서로 도달한다.
- [ ] 첫 실행 중 강제 진단 문제, 첫 성공 화면, 시나리오 완료, XP·배지·보상 지급이 한 번도
  발생하지 않는다.
- [ ] 설명 1~5장, 목적+레벨, 캐릭터, 확인/커밋에서 각각 앱을 강제 종료해도 정확한 단계로
  복구되며 선택이나 보상이 중복되지 않는다.
- [ ] 솟을대문 재생 중 앱을 종료하면 다음 실행은 Today로 가며 영상을 반복하지 않는다.
- [ ] 기존 완료 사용자는 강제 재온보딩 없이 Today로 가고 `새 앱 가이드`만 선택적으로 본다.
- [ ] 레거시 partial 사용자(`userLevelCode`만 존재)는 홈으로 우회하지 않고 V2 setup에서
  기존 값을 확인한 뒤 완료한다.

### 화면, 접근성, 영상 실패

- [ ] 320×640·시스템 글자 200%·독일어에서 5장, 목적+레벨, 캐릭터, 확인 화면의 본문을
  끝까지 스크롤할 수 있고 고정 CTA가 가려지지 않는다.
- [ ] 일반 대형폰과 태블릿, 세로/가로, 100%·130%·200% 글자에서 같은 흐름을 완료한다.
- [ ] TalkBack/VoiceOver 포커스가 시각 순서와 맞고, 캐릭터 확인 제목과 저장 실패 안내가
  한 번만 낭독되며 초점이 사라지거나 갇히지 않는다.
- [ ] Reduce Motion에서 설명 전환과 대문 연출이 정적으로 대체되고 진행은 막히지 않는다.
- [ ] Taego/Joy MP4가 Android와 iOS에서 각각 재생되며, 초기화 실패·stall·decoder 오류를
  강제로 만들어도 정적 이미지와 `함께 시작하기`로 진행한다.
- [ ] 솟을대문 영상은 자연 완료와 탭 skip 모두 Today로 한 번만 이동하고, 저사양 기기에서
  디코더가 실패해도 정적 폴백으로 진행한다.

### 권한, 개인정보, 실제 기능 연결

- [ ] 필수 설명 5장만 보는 동안 카메라·사진·마이크·알림 권한 시트, TTS, 녹음, OCR,
  분석 서버 호출이 발생하지 않는다.
- [ ] `내 책`에서 카메라/갤러리 → crop → 온디바이스 OCR → preview → 사용자가 선택한 분석
  → 근거형 질문까지 완료하며, OCR 텍스트의 EU 분석 서버 전송 가능성을 분석 전에 알린다.
- [ ] 발음 평가 전에 별도 동의, 마이크 권한, 음성 전송 안내가 나타나며 거부 후 대체 경로가
  유지된다.
- [ ] 하트는 찜에만 나타나고 복습 큐를 바꾸지 않으며, 북마크는 실제 저장 대상에 나타난다.
  단어·문법·문장 타입이 학습 보관함에서 보존되고 오늘 복습은 지원되는 단어만 제시한다.
- [ ] 목적별 시작 가이드 순서만 달라지고 동일 레벨의 난이도·콘텐츠·XP·보상은 바뀌지 않는다.
- [ ] 설정에서 코스 시작점과 둘러보기 레벨, 캐릭터와 동행자 표시, 음성 속도, 앱 가이드,
  `레벨 다시 확인` 8문항을 각각 독립적으로 열고 변경할 수 있다.

### Rollout, 분석, 복구 스위치

- [ ] Remote Config의 신규 설치 beta 대상을 실제 콘솔에서 확인하고, 기존 사용자가 대상에
  포함되지 않음을 확인한다.
- [ ] `minimal`/kill switch에서 `동의 → 목적+레벨 → 캐릭터 → 홈`으로 진행하며 강제 문제
  흐름으로 돌아가지 않는다. 잘못된 값·fetch timeout에서도 앱이 멈추지 않는다.
- [ ] 동의 전과 연령 게이트 전에는 온보딩 분석 이벤트가 기록되지 않는다.
- [ ] 실제 Analytics DebugView에서 완료 이벤트가 AppShell 첫 정상 프레임에 한 번만 기록되고,
  이벤트에 책 텍스트·문장·녹음·정답·단어가 들어가지 않는다.
- [ ] 오프라인, 느린 저장소, background/restore에서 무반응 버튼이나 중복 커밋 없이 재시도
  안내가 보인다.

실기기 자동 흐름은 각 플랫폼에서 profile로 실행한다:

```bash
flutter test integration_test/app_flows_test.dart -d <기기ID> --profile
```

---

## 0. 자동화된 것 (사람이 다시 하지 않아도 되는 것)

CI(`.github/workflows/ci.yml`)가 push/PR마다 강제한다. **아래가 빨간불이면 수동 검증을 시작하지 말 것.**

| 영역 | 자동 검사 | 파일 |
|---|---|---|
| 정적 분석 | `flutter analyze` error 0 | CI |
| 창 크기 분류 | 경계값·내비 전환·SoriBreakpoints 대응 | `test/window_class_test.dart` |
| 분류 통일 | 플랫폼 분기 금지·숫자 리터럴 폭 비교 래칫 | `test/window_class_guard_test.dart` |
| 오버플로 (폭) | 35화면 × 308–1280dp × 글자 1.3배 | `test/responsive_test.dart` |
| 오버플로 (낮은 높이) | 35화면 × 360×400·800×360·800×600·1280×500·740×360·640×480 + 800×600×1.3배 | `test/responsive_short_height_test.dart` |
| 상태 변형 | 코스 모드(문법·스몰토크)·팩 인자 화면 × 6뷰포트 — 인자가 렌더 구조를 바꾸는 변형 | `test/responsive_short_height_test.dart` |
| 배치 픽셀 | 4화면 × compact/medium/expanded 골든 | `test/goldens/screen_layout_golden_test.dart` |
| 접근성 | 터치 영역·대비·라벨 (6화면 × 5조건) | `test/accessibility_guideline_test.dart` |
| 핵심 흐름 | 시작 분기·재시작 진도 유지·손상 데이터·초기화 | `test/e2e/app_flows_e2e_test.dart` |
| Onboarding V2 | 5장·24 목적/레벨 조합·2 캐릭터·중단 복구·멱등 커밋·kill switch·320×640/200% | `test/features/onboarding_v2/`, `test/onboarding_v2_accessibility_gate_test.dart` |
| 앱 가이드·보관함 | typed destination·찜/저장/복습 분리·DE/EN 스크롤·설정 저장 실패 복구 | `test/features/guide/`, `test/features/study_library/` |
| 영상 디코더 | 동시 1개 상한·회수/복귀·실패 복구 | `test/video_lease_contract_test.dart`, `test/sori_video_lease_test.dart` |
| 학습 데이터 복구 | SRS·팩 진행도 손상 격리, 덮어쓰기 금지 | `test/learning_data_recovery_test.dart` |
| 스키마 | 멱등·롤백·다운그레이드 fail-closed | `test/data_migration_test.dart` |
| 진단 PII | 키 봉인·값 길이 제한·동의 게이트 | `test/diagnostics_service_test.dart` |
| 클라우드 백업 안전 | 손상 덱을 업로드하지 않음 | `test/learning_data_recovery_test.dart` |
| 계정 오류 표시 | 취소/불가/실패 3갈래가 서로 다른 화면 | `test/account_link_failure_visibility_test.dart` |

> ⚠️ **E2E 파일의 전체 앱 pump 는 6회로 묶여 있다.** 한 파일에서 `KoLernenApp` 을 ~12회 넘게
> pump 하면 테스트 프로세스가 종료되지 않아 CI 잡이 통째로 타임아웃된다(2026-08-06 실측).
> 새 E2E 를 더할 때 `test/e2e/app_flows_e2e_test.dart` 상단 주석을 먼저 읽을 것.
>
> 단 **원인을 "자원 누수"로 단정하지 말 것.** 반응형 쪽에서 같은 종류의 hang 을 쫓았더니
> pump 횟수와 무관한 `rootBundle`(`CachingAssetBundle`) 의 Future 캐시 오염이었다 —
> fake-async 존에서 시작돼 미완료로 남은 에셋 로드를 이후 `tester.runAsync` 가 그대로
> 받아 영원히 기다린다. `setUp` 의 `rootBundle.clear()` 한 줄로 10분 타임아웃이 16초
> 완주가 됐다. E2E 상한도 같은 원인인지 확인되지 않았다 — 이슈 #9 참조.

**골든 기준선은 Linux(CI) 정본이다.** 로컬(Windows/macOS)에서 `--update-goldens` 금지 —
Actions → CI → "Run workflow" → `Regenerate goldens (manual)` 아티팩트를 받아 커밋한다.

---

## 1. 릴리스 빌드로 검증 (debug 빌드로 판단 금지)

```bash
flutter run --debug   -d <기기ID>   # 개발용
flutter run --profile -d <기기ID>   # 성능 측정용
flutter run --release -d <기기ID>   # 출시와 같은 코드 경로
```

- [ ] release 에서만 나는 minify/tree-shaking 문제 없음
- [ ] 자산 누락 없음 (영상·PNG·CSV·JSON — errorBuilder 폴백이 뜨는 곳이 있는지)
- [ ] Firebase 설정이 release 서명에 물려 있음
- [ ] Google 로그인 동작 (release 서명 SHA-1/SHA-256 이 Firebase 콘솔에 등록돼 있어야 함)
- [ ] 결제·구독 (RevenueCat + Play Billing / StoreKit)
- [ ] 알림 도달
- [ ] deep link
- [ ] 기존 설치 위에 업데이트해도 **학습 데이터 유지** (§8)

⚠️ **App Check / Play Integrity 는 배포 경로에 따라 달라진다.** 사이드로드한 release APK 가 아니라
**Play 내부 테스트에서 설치한 빌드**로만 검증한다. Cloud Logging 에서 `app=VALID` 확인.

---

## 2. 회전·창 크기 변경 (§Android 적응형 품질 요건)

앱은 4방향을 모두 허용한다(`kAppSupportedOrientations`, `lib/main.dart`). 고정 방향에 기대지 않는다.

- [ ] 세로 → 가로 회전
- [ ] 앱 실행 중 창 크기 변경 (자유 형식 창)
- [ ] 화면 분할 (split screen)
- [ ] 태블릿 멀티윈도우
- [ ] 폴더블 펼침·접힘
- [ ] 백그라운드 → 복귀

**회전 직후 아래가 유지되는지 항목별로 본다** (한 화면이라도 깨지면 기록):

- [ ] 현재 학습 단계가 초기화되지 않는다
- [ ] 동영상이 처음부터 다시 재생되지 않는다
- [ ] 음성이 중복 재생되지 않는다
- [ ] 선택한 답이 사라지지 않는다
- [ ] 다이얼로그가 중복으로 뜨지 않는다
- [ ] 하단 탭 ↔ 세로 레일 전환(600dp)에서 현재 탭이 유지된다

---

## 3. 텍스트 확대·굵은 글씨·고대비

CI 는 1.3배까지 자동 검사한다. **최대 배율은 사람이 본다.**

- [ ] 기본 글자 크기
- [ ] 130~150%
- [ ] 시스템 최대 글자 크기
- [ ] 굵은 텍스트(Bold text)
- [ ] 고대비(Increase Contrast)

보는 곳: 버튼 라벨 줄바꿈 · 카드 제목 두 줄 · 하단 내비 라벨 · 다이얼로그 높이 · 학습 카드 정답 버튼.

> **알려진 부채**: `SoriColors.lightTextDim`(#8B948E)은 한지 배경 위 대비가 **2.89**로 WCAG AA(4.5)에
> 못 미친다. 2026-08-06 에 동의 화면 두 곳만 `textMuted`(5.52)로 올렸다. 나머지 사용처는 전역 토큰
> 변경이 필요해 별도 트랙이다 — 작은 보조 문구를 읽을 수 없다는 보고가 오면 우선순위를 올린다.

---

## 4. 접근성 보조 기술 (실기기 전용)

자동 검사는 크기·대비·라벨 **존재**만 본다. 아래는 기계가 볼 수 없다.

- [ ] Android TalkBack — 낭독 순서가 시각 순서와 맞는지, 초점이 갇히지 않는지
- [ ] iPhone VoiceOver — 같은 항목
- [ ] 색상 반전
- [ ] Reduce Motion — 화면 전환·입자·진입 애니메이션이 정적으로 대체되는지
  - ⚠️ **캐릭터 클립은 의도적으로 reduce-motion 을 따르지 않는다**(MIUI 배터리 절약이 같은 플래그를
    쓰기 때문). `lib/widgets/sori/video_lease.dart` 주석 참조. 이게 불편하다는 보고가 오면 설정에
    명시적 "캐릭터 애니메이션" 토글을 넣는다.
- [ ] Reduce Transparency

---

## 5. 다크 모드·시스템 UI 충돌

앱은 라이트 고정(`themeMode: ThemeMode.light`)이다. 다크를 지원하지 않더라도 **충돌은 확인해야 한다.**

- [ ] 시스템 다크에서 상태바·내비게이션바 아이콘이 보이는지
- [ ] 키보드가 앱 배경과 부딪히지 않는지
- [ ] 시스템 다이얼로그(권한·공유·결제)가 읽히는지

> **알려진 미결**: `CharacterClipPlayer` 에는 다크 게이트가 있지만 `TigerGreetClip`·`TigerStageVideo`
> 에는 없다(AGENTS.md 2026-08-06). 다크 배경에서 `ColorFiltered`+`multiply` 매트는 밝은 배경 전용이라
> 영상이 어색해질 수 있다. 다크 테스트 커버리지는 저장소 전체에 0건이다.

---

## 6. 현지화 (DE/EN) — UI 파손

독일어는 영어보다 길다. 예: `Delete account` → `Konto endgültig löschen`.

- [ ] 버튼 텍스트 줄바꿈
- [ ] 제목 두 줄 처리
- [ ] 다이얼로그 높이
- [ ] 탭 이름 / 하단 내비 라벨 (`Lerngruppe` 계열 긴 복합명사)
- [ ] 한국어 조합형 글자 렌더링 (받침·겹받침)
- [ ] 긴 독일어 복합명사가 카드 밖으로 나가지 않는지
- [ ] 숫자·날짜·통화 표시
- [ ] **언어 전환 직후 화면이 즉시 갱신되는지**

문자열은 전부 `lib/l10n/app_de.arb` + `app_en.arb` 에 있어야 한다. 위젯 안 하드코딩 금지
(`test/arb_l10n_guard_test.dart` 가 일부를 강제한다).

---

## 7. 네트워크 실패를 정상 상태로 취급

- [ ] 요청 **직전** 인터넷 끊기
- [ ] 요청 **중** 인터넷 끊기
- [ ] Wi-Fi → 모바일 데이터 전환
- [ ] 서버 timeout
- [ ] 버튼 중복 탭
- [ ] 요청 중 앱 백그라운드 이동
- [ ] 응답 직전 앱 강제 종료 → 재실행 후 pending 작업 복원

**"아무 일도 일어나지 않는 버튼"이 하나도 없어야 한다.** 실패는 반드시 화면에 나타난다:
인터넷 없음 · 서버 일시 오류 · Firebase 미초기화 · App Check 실패 · 로그인 만료 · 권한 거부 ·
저장 공간 부족 · 파일 형식 오류 · 사용자 직접 취소 — 이 아홉 가지가 **서로 구별되게** 보여야 한다.

> 계정 연동 3갈래(취소/불가/실패)는 2026-08-06 에 분리했고 CI가 고정한다. **나머지 비동기 작업은
> 아직 감사되지 않았다** — 이번 라운드에서 화면별로 훑고 발견한 것을 여기 적는다.

중요 작업(계정 삭제·결제)은 버튼 잠금만으로 부족하다. **서버가 같은 요청을 두 번 받아도 한 번만
처리되는 idempotent 구조**여야 한다. 확인 지점: 계정 삭제 journal(`kl_account_deletion_journal_v1`),
클라우드 백업 삭제 journal, RevenueCat 복원.

---

## 8. 데이터 안전 (업데이트·마이그레이션)

- [ ] **이전 버전 위에 업데이트 설치** → 학습 기록·SRS·단어장·팩 진행도 유지
- [ ] 업데이트 직후 첫 실행에서 크래시 없음
- [ ] 기기 교체/계정 병합 후 데이터 합류
- [ ] 계정 삭제 → 재가입 시 잔재 없음

로컬 스키마는 `DataMigrationService`(`kl_schema_version`)가 관리한다. 원칙: 멱등 · 중간 실패 재시도 가능 ·
마이그레이션 전 백업 · **완료 후에만 버전 상승** · 삭제/초기화와 같은 흐름에 섞지 않기.
다운그레이드(옛 APK 재설치)는 읽기만 허용하고 학습 쓰기를 잠근다.

- [ ] 신버전 설치 → 구버전 재설치 → 데이터가 **망가지지 않고** 읽히는지 (쓰기는 잠긴 상태가 정상)

---

## 9. 권한 (시작 시 일괄 요청 금지)

카메라·마이크·알림을 앱 시작 즉시 요청하지 않는다. 흐름은:
**사용자가 기능을 누름 → 왜 필요한지 앱 화면에서 설명 → 시스템 권한 요청 → 거부 시 대체 경로 제공.**

각 권한(카메라 / 사진 / 알림)마다 6상태를 본다:

- [ ] 최초 허용
- [ ] 최초 거부
- [ ] 다시 요청
- [ ] "다시 묻지 않음"
- [ ] 설정에서 권한 제거 후 복귀
- [ ] 앱 사용 중 권한 회수

---

## 10. 플랫폼 관례 (브랜드는 같게, 시스템 동작은 각자답게)

| 항목 | Android | iOS |
|---|---|---|
| 뒤로가기 | 시스템 Back 지원 필수 | swipe back 고려 |
| 권한 안내 | 요청 직전 설명 | 요청 목적 명확화 |
| 선택 UI | Material 계열 | 필요하면 Cupertino 계열 |
| 공유 | 시스템 share sheet | 시스템 share sheet |
| 설정 이동 | Android 설정 구조 | iOS 설정 구조 |
| 결제·구독 | Google Play Billing | StoreKit |

- [ ] Android 시스템 Back 이 모든 화면에서 기대대로 동작 (특히 다이얼로그·바텀시트·게임 중)
- [ ] iOS 스와이프 백이 학습 진행을 날리지 않음

색상·캐릭터·브랜드 경험은 동일하게 유지한다.

---

## 11. 영상·오디오 리소스 (실기기 전용)

CI 는 lease 코디네이터의 **논리**를 검증한다. 실제 디코더는 기기에서만 볼 수 있다.

- [ ] 화면 전환을 빠르게 반복해도 영상이 검게 죽지 않음
- [ ] 홈 ↔ 상세 왕복 후 캐릭터가 다시 재생됨
- [ ] 백그라운드 진입 시 음성이 멈춤
- [ ] 같은 음성이 중복 재생되지 않음
- [ ] 태블릿에서 메모리 급증 없음
- [ ] 저사양 기기(구형 Android)에서 영상이 정적 폴백으로 떨어지더라도 **앱은 정상**

관련: `docs/ADR-001-video-decoder-budget.md`, `docs/ADR-002-audio-policy.md`.

---

## 12. 자산·시작 성능 (감사 항목 — 이번 라운드는 실측·목록화)

- [ ] `Image.asset` 에 `cacheWidth` 가 없는 큰 이미지 목록화
      (표시 폭의 약 2배로 디코딩하는 것이 기준)
- [ ] 4K/고비트레이트 영상, 중복 자산, 미사용 자산 목록화
      (참고: `docs/ASSET_INVENTORY_2026-08-06.md`)
- [ ] 앱 시작 시 **선행 필요**(로컬 설정·언어·최소 DB·테마)와
      **지연 가능**(Analytics·비필수 캐시·추천·preload·대용량 manifest)이 실제로 나뉘어 있는지
- [ ] cold start 시간 측정 (`--profile` 빌드)

> 현재 `main()` 은 Firebase·인증·결제·FCM 을 `unawaited(_startCloudServices())` 로 뒤로 미루고,
> 로컬 스키마 점검만 동기로 한다. **Firebase 실패가 앱 시작을 막지 않되 실패 사실은
> `DiagnosticKey.firebaseReady` 로 기록된다.**

---

## 13. Crashlytics 진단 (수집 동의 켠 상태로)

- [ ] 테스트 크래시를 내고 콘솔에서 아래 키가 보이는지:
      `appVersion` · `buildNumber` · `gitCommit` · `windowClass` · `orientation` ·
      `currentRoute` · `lastLessonStep` · `lastClipId` · `firebaseReady` · `networkState` · `schemaVersion`
- [ ] breadcrumb 에 라우트 이동이 남는지 (`route_push /vocab/pack`)
- [ ] **개인정보가 없는지 직접 확인** — 이름·이메일·학습 답변·토큰·파일 경로·uid

`gitCommit` 은 빌드 시 주입한다:
```bash
flutter build appbundle --release --dart-define=GIT_COMMIT=$(git rev-parse --short HEAD)
```

---

## 14. 기기 매트릭스 (대표군)

기기를 무한히 볼 수 없다. 아래 조합을 대표로 삼는다.

| 구분 | 대표 환경 |
|---|---|
| 소형 Android | 좁은 화면(≤360dp), 낮은 RAM |
| 일반 Android | Xiaomi 또는 Samsung 휴대폰 (예: Redmi M2101K6G / Android 12) |
| Android 태블릿 | 샤오미 패드 · Galaxy Tab |
| 최신 Android | 최신 API 에뮬레이터 |
| 구형 지원 하한 | 최소 지원 API 기기/에뮬레이터 |
| 일반 iPhone | 현재 주력 iPhone |
| 소형 iPhone | SE급 좁은 화면 |
| iPad | 일반 iPad 또는 Simulator (13-inch 포함) |

교차 조건: 네트워크(정상 / 느림 / 오프라인) × 글자 크기(기본 / 최대) × 방향(세로 / 가로) ×
테마(밝게 / 어둡게). 폴더블·ChromeOS 도 같은 품질 기준으로 본다.

실기기에서 `integration_test` 를 함께 돌린다:
```bash
flutter test integration_test/app_flows_test.dart -d <기기ID> --profile
```

---

## 15. 스토어 출시 트랙 (단계적으로)

### Google Play
```
내부 테스트 → 비공개 테스트 → 공개 테스트 또는 소규모 production rollout → 전체 배포
```
- [ ] 첫 production 은 **100% 가 아니라 staged rollout**

### Apple
```
로컬 실기기 → TestFlight 내부 테스터 → TestFlight 외부 테스터 → App Store phased release
```

배포 절차·인프라(Firestore rules, Cloud Functions, AAB 업로드)는
`docs/store/closed-testing-checklist-v2.md` 와 `docs/store/app-store-connect-v2.0.5.md` 참조.

---

## 16. 테스터에게 받을 정보 (버그 리포트 템플릿)

```
기기 모델:
OS 버전:
앱 버전 (설정 화면 하단):
문제가 난 화면:
재현 단계:
  1.
  2.
  3.
기대한 동작:
실제 동작:
화면 녹화/스크린샷:
발생 시간 (대략):
네트워크 상태 (Wi-Fi / 모바일 / 오프라인):
시스템 글자 크기 (기본 / 크게):
```

---

## 부록. 이번 라운드에서 발견한 것

> 검증하며 찾은 문제를 여기 누적한다. 고친 것은 커밋 해시를, 미룬 것은 이유를 적는다.

| 발견 | 상태 | 비고 |
|---|---|---|
| `kl_srs_v1` 손상 시 복습 1회로 학습 이력 전체 소실 | 고침 (2026-08-06) | 격리 + write 잠금 |
| `kl_pack_progress_v1` 동일 결함 | 고침 (2026-08-06) | 같은 정책 |
| 팩 진행도를 읽기 전에 쓰면 기존 진행도 전멸 | 고침 (2026-08-06) | write 전 load |
| 손상된 SRS 덱이 클라우드 백업을 덮어써 모든 기기로 번짐 | 고침 (2026-08-06) | 격리 중엔 `srs_json` 미전송(merge:true) |
| Firebase 불가가 "사용자 취소"로 표시(무반응 버튼) | 고침 (2026-08-06) | 3갈래 분리 |
| 단어팩 헤더가 800dp에서 51px 오버플로 | 고침 (2026-08-06) | Expanded + ellipsis |
| 코치마크 "건너뛰기" 터치 영역 13dp | 고침 (2026-08-06) | minimumSize 48 |
| 동의 화면 체크박스 32dp·라벨 없음 | 고침 (2026-08-06) | 행이 tap target |
| `textDim` 전역 대비 2.89 | 부분 (동의 화면만) | §3 참조 |
| `TigerGreetClip`/`TigerStageVideo` 다크 게이트 없음 | 미결 | §5 참조 |
| 코스 문법 Quick check 가 **짧은 높이**(800×600)에서 37px 세로 오버플로 | 미결 (main 선행) | 아래 참조 |
| 반응형 매트릭스에 **짧은 높이 뷰포트가 없다** | 미결 | 아래 참조 |

### 짧은 높이(가로 폰) 뷰포트 — ✅ 해결됨 (2026-08-07)

위에 적혀 있던 "아직 그물이 없다"는 해소됐다. `test/responsive_short_height_test.dart` 가
낮은 높이 6조건 × 35화면 + 상태 변형(코스 모드·팩 인자) × 6뷰포트를 상설 회귀로 건다.

그때 드러난 오버플로는 화면별 땜질이 아니라 **공유 위젯 4곳**에서 한 번씩 고쳤다 —
`SoriEmptyState`(일러스트 상한 + 스크롤) · `HanokHeader`(배너가 뷰포트의 22% 를 넘고
높이 700 미만일 때만 접힘) · `FlipCard`(카드 면이 상자보다 크면 스크롤) ·
`SoriMinHeightScroll` 신규(고정 헤더 + `Expanded` + 고정 액션 바 구조가 짧은 화면에서
넘치는 대신 스크롤).

`course_practice_screen_test` 의 800×600 37px 오버플로도 해소됐다 — 다만 그건 main 의
`if (!canRecordCheckpoint)` 가드(체크포인트에서 SRS 오기록 차단, 데이터 정합성)와
`SoriMinHeightScroll`(일반 모드 포함 레이아웃) **둘이 각각** 맡는다. 가드만으로는 일반 문법
모드 360×400 에서 70px 가 남는다(실측).
