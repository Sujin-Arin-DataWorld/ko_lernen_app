# 앱스토어 업로드 절차 (한국어) — Hangul Sori

> **이 문서는 "맥 앞에 앉은 Jin"용 순서표다.** 자격증명 세부 설정의 정본은
> [`ios-external-setup.md`](ios-external-setup.md)(영문), 스토어 등재 문구·개인정보
> 항목은 [`app-store-connect-v2.0.5.md`](app-store-connect-v2.0.5.md) 를 본다.
> 이 문서는 그 둘을 "무엇을 먼저 하고 무엇을 나중에 하는가" 순서로 꿴 것이다.

---

## 0. 먼저 알아둘 것 — 흔한 오해

**"파일을 못 올려서 앱 등록을 못 했다"는 순서가 거꾸로다.**
App Store Connect 의 앱 레코드는 **빌드 파일 없이** 먼저 만든다. 이름과 번들 ID만
있으면 빈 껍데기가 생기고, 그 껍데기가 있어야 비로소 빌드를 받아준다. 레코드가
없으면 업로드는 `No suitable application record was found` 로 거부된다.

```
① Bundle ID 등록      (developer.apple.com · 파일 불필요)
② 앱 레코드 생성      (appstoreconnect.apple.com · 파일 불필요)   ← 지금 여기가 비어 있다
③ 맥에서 .ipa 빌드    (scripts/build_ios_ipa.sh)
④ 업로드              (Transporter 또는 스크립트 자동)
⑤ TestFlight 확인 → 심사 제출
```

**빌드는 반드시 맥에서 한다.** `.ipa` 는 Xcode 코드사인이 필요해서 리눅스·윈도우나
클라우드 AI 세션에서는 만들 수 없다. (Claude 세션은 원격 리눅스 컨테이너에서 돌기
때문에, 맥에서 창을 열었더라도 Claude 쪽 셸은 Jin의 맥이 아니다.)

---

## 1. 준비물 체크

| 항목 | 어디서 | 없으면 |
|---|---|---|
| Apple Developer Program 멤버십 | developer.apple.com | 가입 필요 ($99/년, 승인 최대 48시간) |
| Xcode (최신) | Mac App Store | 설치 후 한 번 실행해 라이선스 동의 |
| CocoaPods | `sudo gem install cocoapods` | pod install 실패 |
| Flutter SDK | 프로젝트 핀: **3.44.0** (`.github/workflows/ci.yml` 기준) | 버전 차이로 빌드 흔들림 |
| Apple Team ID (10자) | 저장소의 Xcode 프로젝트 값과 developer.apple.com Membership details가 일치하는지 확인 | 팀 소유권·서명 불가 |
| `ios/Runner/GoogleService-Info.plist` | Xcode Cloud clean clone용 **추적 파일** — Firebase 프로젝트·Bundle ID 일치 확인 | 검증 게이트에서 중단 |

> `GoogleService-Info.plist`와 Team ID는 Xcode Cloud가 새 clone에서도 archive할 수
> 있도록 비밀이 아닌 식별자로 의도적으로 추적한다(`6c49eeb1`). 소유자 승인 없이
> 교체하지 않는다. 인증서 `.p12`, provisioning profile, App Store Connect API private
> key, APNs private key, 서비스 계정 키 같은 실제 비밀은 저장소에 커밋하지 않는다.
> 검증·회전 절차는 `ios-external-setup.md` §1.

---

## 2. ① Bundle ID 등록

developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → **+**

- Type: **App IDs → App**
- Bundle ID: **Explicit** → `com.sujinarin.koLernenApp`
  - ⚠️ **대소문자까지 정확히.** `koLernenApp` 의 대문자 L·A 가 살아 있어야 한다.
    소문자 변형으로 만들면 나중에 되돌릴 수 없다.
- Capabilities 에서 체크:
  - **Push Notifications**
  - **Sign in with Apple** (Primary App ID 로 둔다)

## 3. ② App Store Connect 앱 레코드 생성

appstoreconnect.apple.com → 나의 앱 → **+** → 신규 앱

| 필드 | 값 |
|---|---|
| 플랫폼 | iOS |
| 이름 | `Hangul Sori` (스토어에 보이는 이름, 30자 제한) |
| 기본 언어 | 독일어 또는 영어 (주 타깃이 독일어권) |
| 번들 ID | 방금 만든 `com.sujinarin.koLernenApp` |
| SKU | 아무 내부 식별자 (예: `hangulsori-ios`) |
| 사용자 액세스 | 전체 액세스 |

여기까지 하면 앱 레코드가 생긴다. **아직 아무 파일도 필요 없다.**

## 4. ③ 맥에서 빌드

Xcode 에서 서명 팀을 한 번 지정해 준다:

```bash
open ios/Runner.xcworkspace
```
Runner 타깃 → **Signing & Capabilities** → Debug/Profile/Release 각각 **Team** 선택,
**Automatically manage signing** 체크. Push Notifications 와 Sign in with Apple 이
목록에 보이는지 확인.

현재 빌드는 모든 학습 콘텐츠를 열고 결제를 초기화하지 않는다.

```bash
export APPLE_TEAM_ID=ABCDE12345          # 본인 10자 Team ID
bash scripts/build_ios_ipa.sh
```

스크립트가 순서대로 한다:
1. 도구·환경변수·`GoogleService-Info.plist` 확인
2. `flutter pub get` + `pod install`  (한국어 OCR Pod 존재 검사 포함)
3. 검증 게이트 2종 (`verify_ios_firebase_config` · `verify_ios_store_contract`)
4. `ExportOptions.plist` 임시 복사본에 Team ID 주입 — **커밋본은 안 건드린다**
5. `flutter build ipa --release` (커밋 SHA 주입, 전체 콘텐츠 접근)
6. 결과 경로 출력 → `build/ios/ipa/*.ipa`

## 5. ④ 업로드

**A. Transporter (처음이면 이게 제일 쉽다)**
Mac App Store 에서 `Transporter` 설치 → Apple ID 로그인 → `.ipa` 를 창에 끌어다 놓기 → **Deliver**

**B. 스크립트 자동 업로드**
App Store Connect → Users and Access → Integrations → App Store Connect API 에서
키 생성 후 `.p8` 다운로드(한 번만 받을 수 있다):

```bash
export ASC_KEY_ID=XXXXXXXXXX
export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export ASC_KEY_PATH=~/Downloads/AuthKey_XXXXXXXXXX.p8
bash scripts/build_ios_ipa.sh
```
세 변수가 다 있으면 빌드 후 `validate-app` → `upload-app` 까지 이어서 돈다.

**C. Xcode Organizer**
`ios/ExportOptions.plist`의 `destination=export`는 먼저 IPA 파일을 만든다는 뜻이다.
ASC 변수 세 개가 하나라도 없으면 스크립트는 export에서 끝나지만, 세 개가 모두
있으면 §B처럼 그 IPA를 검증한 뒤 자동 업로드한다. Xcode에서 직접 Archive했다면
Organizer → Distribute App으로도 올릴 수 있다.

업로드 후 App Store Connect 에 빌드가 나타나기까지 **10~30분** 걸린다. 처리 중
이메일로 경고/거부가 올 수 있으니 확인할 것.

## 6. ⑤ TestFlight → 심사 제출

1. TestFlight 탭에서 빌드 확인 → **수출 규정 준수** 질문에 답 (아래 참고)
2. 실기기에서 최소 한 번 설치해 확인 — 특히 Google 로그인·Apple 로그인·구독 복원·푸시
3. 스토어 등재 정보 채우기: [`listing-de.md`](listing-de.md) / [`listing-en.md`](listing-en.md)
4. 스크린샷 업로드: [`screenshot-shotlist.md`](screenshot-shotlist.md) · `tool/check_app_store_screenshots.py` 로 규격 검사
5. 개인정보 설문: [`data-safety.md`](data-safety.md) — Google Play 것과 별도 문서다
6. 연령 등급 설문은 **최종 빌드의 실제 콘텐츠 기준으로 직접** 답한다
7. URL 3종이 실제로 살아 있는지 확인 후 입력 (support / privacy / account-deletion)
8. 심사 제출

---

## 7. 자주 막히는 지점

| 증상 | 원인 / 해결 |
|---|---|
| `No suitable application record was found` | ② 앱 레코드 미생성. 먼저 만들 것 |
| `The bundle version must be higher than...` | iOS 빌드번호 중복. `pubspec.yaml`의 `version:` 뒷자리 또는 `flutter build ipa --build-number=N`을 이전 App Store Connect 업로드보다 크게 잡고 재빌드한다. Android `versionCode`는 release commit count로 별도 관리하므로 두 스토어의 숫자가 같을 필요는 없다. |
| ipa 가 안 나오고 서명 오류 | Xcode 에서 Team 미선택. §4 앞부분 다시 |
| `verify_ios_firebase_config` 실패 | 추적된 `GoogleService-Info.plist`의 프로젝트·Bundle ID·URL scheme 불일치 또는 Runner 타깃 멤버십 누락. **게이트를 우회하지 말 것** |
| Podfile.lock 에 GoogleMLKit 없음 | `cd ios && pod install --repo-update` 재실행 |
| 수출 규정 준수 질문이 매번 뜬다 | `ios/Runner/Info.plist` 에 `ITSAppUsesNonExemptEncryption` 키가 없어서다. HTTPS만 쓰는 앱은 `false` 를 넣어두면 매번 안 묻는다 — 다만 이건 **법적 신고**라 Jin이 직접 판단해 넣을 것 |

## 8. 맥 없이 빌드해야 할 때

지금은 맥이 있으니 로컬 빌드가 가장 빠르고 공짜다. 나중에 맥 없이 굴려야 하면
GitHub Actions `macos-latest` 러너로 같은 스크립트를 돌릴 수 있다 — 추적된
`GoogleService-Info.plist`는 checkout에서 검증하고, 인증서(.p12)·프로비저닝
프로파일·ASC API private key만 리포지토리 Secrets에서 복원한다. 필요해지면 그때
워크플로를 추가한다.
