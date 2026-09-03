# 구독 운영 셋업 런북 — Hangul Sori €5/월 Premium (RevenueCat)

> 갱신: 2026-09-03 · 대상: Jin (운영) · 무료 공개 후 유료 전환용 운영 계약.
> 소스 구현·CI·백엔드 배포·스토어 처리·실기기 검증은 서로 다른 증거다.
> 아래 설정만으로 결제 완료를 주장하지 않는다. 모든 출시 게이트 통과 전에는 판매를 켜지 않는다.

---

## 0. 출시 순서와 권한 계약

소스 검증 대상(실제 운영 상태가 아님):

| 요소 | 위치 | 비고 |
|---|---|---|
| 구독 서비스 | `lib/services/premium_service.dart` | RevenueCat SDK는 구매를 처리하고 서버 스냅샷이 권한을 결정. 키/검증 누락 시 구매 비활성 |
| 페이월 UI | `lib/screens/paywall_screen.dart` | 스토어의 월간 상품·현지 가격, 구매/복원/대기 상태, DE/EN |
| 게이팅 | 단어팩 비A1·시나리오 비A1·홈 | `PremiumService.gate(context)` → 무료면 `/paywall` |
| Dev 토글 | `lib/screens/settings_screen.dart` (Debug) | 로컬 콘텐츠 게이트만 테스트; 회원권·AI 권한은 부여하지 않음 |

무료 공개 빌드는 `FREE_LAUNCH=true`로 번들 콘텐츠를 개방하며 구독 판매는 비활성이다.
무료 공개 후 실제 14일 운영 관찰, 아래 실기기·비용·정책 게이트를 통과한 뒤에만 유료로 전환한다.
유료 단계는 A1 무료, A2–C2 Premium이다. 일반 사용자 AI는 책3회/발음5회,
구독자와 Jin 승인 평생 테스터는 책20회/발음50회(UTC 하루)다. 로그인·복원·등급 변경은
이미 사용한 한도를 초기화하지 않는다. 빌드 플래그나 피드백 제출은 테스터 승인 증거가 아니다.

**대시보드와 서버가 일치해야 하는 고정값**:

- Entitlement ID = **`premium`** (서버 `RC_ENTITLEMENT_ID`와 동일)
- 패키지 = **Monthly**. 월간 상품이 없으면 구매 비활성; 연간/첫 상품 폴백 금지.
- 가격 표시 = 스토어 상품의 `priceString`와 실제 월간 주기. €5/월은 승인 대기 초안이며 비용 검증 전 판매하지 않는다.
- 키 주입 = `--dart-define=RC_ANDROID_KEY=goog_…` / `RC_IOS_KEY=appl_…` (공개 SDK 키, **시크릿 키 아님**)
- 앱 패키지명 = **`com.sujinarin.ko_lernen_app`**

---

## STEP 1 — Play Console: 구독 상품 만들기

> 전제: 앱이 **내부 테스트 트랙에 1회 이상 업로드**돼 있어야 상품이 활성화된다 (AAB 먼저 올려둘 것).

1. Play Console → 앱 선택 → **수익 창출 > 상품 > 구독**.
2. **구독 만들기**:
   - 제품 ID: `premium_monthly` (예시 — 자유지만 한번 정하면 변경 불가, RevenueCat에서 이걸 연결)
   - 이름: `Hangul Sori Premium`
3. **기본 요금제(Base plan) 추가**:
   - 기본 요금제 ID: `monthly`
   - 유형: **자동 갱신**
   - 결제 주기: **매월(P1M)**
   - 가격: **€5.00** (독일 기준 → 다른 나라는 자동 환산, 필요시 조정)
4. 샌드박스 검증에 필요한 상태와 실제 판매 활성화는 구분한다. 실제 판매 활성화는 최종 출시 승인 뒤에만 한다.
5. (선택) 무료 체험/할인은 **혜택(Offer)**로 나중에 추가 가능 — 지금은 스킵.

> ⚠️ 상품·기본 요금제와 RevenueCat 연결 상태를 확인한다. 월간 offering이 없으면 가격을 만들어 표시하지 않고 구매를 비활성화한다.

---

## STEP 2 — RevenueCat 대시보드 설정

### 2-1. 프로젝트 + 앱 연결
1. https://app.revenuecat.com 가입 → **새 프로젝트** (`Hangul Sori`).
2. **Project settings > Apps > + Google Play**:
   - Package name: `com.sujinarin.ko_lernen_app`
   - **Service Account credentials JSON 업로드** ← 핵심 게이트 (아래 2-2)
3. 여기서 발급되는 **Public SDK Key** (`goog_…`) 를 복사 → STEP 3에서 사용.

### 2-2. Google 서비스 계정 (RevenueCat ↔ Play 연결) — 흔히 막히는 곳
RevenueCat이 구매 상태를 서버에서 검증하려면 Play Developer API 권한이 필요하다:
1. Google Cloud Console → 프로젝트(ko-lernen-app) → **서비스 계정 생성** → JSON 키 다운로드.
2. Google Play Console → **설정 > API 액세스** → 그 서비스 계정 연결 → **금융 데이터/주문 보기** 권한 부여.
3. 다운로드한 JSON을 RevenueCat 앱 설정에 업로드.
> 권한 전파에 최대 24~36시간 걸릴 수 있음(구글 안내). 결제 테스트가 "상품 없음"이면 이게 원인일 때가 많다.

### 2-3. Entitlement + Offering
1. **Entitlements > + New**: ID = **`premium`** (이름 정확히! 코드가 이 문자열로 검사).
2. **Products > + Import** → Play의 `premium_monthly:monthly` 가져오기 → entitlement `premium`에 연결.
3. **Offerings > Default offering** → **Package 추가** → 타입 **Monthly ($rc_monthly)** → 위 상품 연결.
   - **Monthly 패키지가 필수**다. 다른 기간의 상품을 대신 표시하지 않는다.

### 2-4. 서버 연결과 계정 소유권

- RevenueCat Restore Behavior는 **Keep with original App User ID**로 확인하고 콘솔 증거를 보존한다.
  `BILLING_RESTORE_POLICY=keep_original` 문자열만으로 콘솔 설정을 증명할 수 없다.
- 구매/복원은 Google 또는 Apple이 연결된 Firebase UID와 완료된 RevenueCat 바인딩을 요구한다.
  두 제공자를 추가 연결해도 UID는 그대로다. 이메일·Apple 비공개 이메일·RevenueCat alias는 자동 계정 병합 근거가 아니다.
- Gye 코드베이스의 `revenueCatWebhook`, `processRevenueCatEvent`, `refreshRevenueCatAccess`와
  `getAccessSnapshot`을 exact-SHA로 검증한다. 서버 기본 `BILLING_ENABLED=false`를 유지하다가
  승인된 샌드박스 설정에서 먼저 켠다. `ACCESS_ENVIRONMENT`는 PRODUCTION/SANDBOX를 명시한다.
- Secret Manager의 `RC_SERVER_API_KEY`, `RC_WEBHOOK_AUTHORIZATION`, `RC_WEBHOOK_SIGNING_SECRET`을
  역할별로 바인딩한다. 두 웹훅 인증 방식이 설정되면 둘 다 일치해야 한다. 값은 로그/문서에 남기지 않는다.
- 웹훅은 최소 작업을 영속화한 뒤 응답하고 최신 구독자를 다시 조회한다. 취소 의사만으로
  아직 유효한 구독을 박탈하지 않지만 만료·환불·철회는 최신 검증 결과로 반영한다.
- 테스트와 운영 권한은 분리한다. TestFlight 구매는 sandbox다. 계정 삭제는 구독 취소가 아니다.
  사용자에게 원래 구매한 스토어의 관리 경로와 별도 취소 필요성을 안내한다.

---

## STEP 3 — 키 주입 + 빌드

### Production subscription AAB (feedback disabled)

이 명령은 **유료 전환 승인 후**의 빌드 예시이며 현재 판매 허가가 아니다.
공개 SDK 키는 repo에 커밋하지 말고 저장소 루트의 PowerShell 세션에만 주입한다.
아래 guard는 키가 없거나 형식이 틀리면 빌드 전에 중단한다. 이 production 명령에는
테스터 피드백 define을 넣지 않는다.

```powershell
$env:RC_ANDROID_KEY = '<paste-live-RevenueCat-Android-SDK-key>'
if ([string]::IsNullOrWhiteSpace($env:RC_ANDROID_KEY) -or $env:RC_ANDROID_KEY -notmatch '^goog_[A-Za-z0-9_-]{8,}$') { throw 'Set RC_ANDROID_KEY to the live RevenueCat Android SDK key before building.' }
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=RC_ANDROID_KEY=$env:RC_ANDROID_KEY --dart-define=BETA_UNLOCK_ALL=false --dart-define=FREE_LAUNCH=false --dart-define=ACCESS_ENVIRONMENT=PRODUCTION
# iOS 추가 시: --dart-define=RC_IOS_KEY=appl_xxxxxxxxxxxx
```

- 키 없이 빌드하면 스토어 구매/복원은 비활성이다. 서버 회원권 확인과 승인된 무료 콘텐츠 접근은 별개로 동작한다. 유료 전환 빌드에는 올바른 SDK 키가 필요하다.
- `--dart-define`은 컴파일 타임 상수 → AAB마다 들어간다. CI 쓰면 환경변수로.
- Play Billing 권한(`com.android.vending.BILLING`)은 `purchases_flutter`가 매니페스트 머지로 **자동 추가**(수동 선언 불필요). 빌드 후 merged manifest에서 한 번 확인하면 안심.
- 빌드가 `minSdk` 관련 에러를 내면 `android/app/build.gradle.kts`의 `minSdk`를 명시적으로 올려 (현재 `flutter.minSdkVersion` 상속).

---

## STEP 4 — 샌드박스 결제 테스트 (실제 청구 X)

1. Play Console → **설정 > 라이선스 테스트** → 테스트할 Google 계정(Gmail) 추가.
2. 그 계정이 로그인된 실기기에 내부 테스트 후보를 설치한다. 라이선스 테스터는 조건에 맞는
   사이드로드 빌드도 사용할 수 있지만, 최종 게이트는 실제 스토어 배포 후보로 확인한다.
3. 앱에서 비A1 단어팩/시나리오 진입 → 페이월 → 구매 → "테스트 카드"로 결제(청구 안 됨).
4. 결제 후 게이팅이 풀리는지 + RevenueCat 대시보드 **Overview**에 이벤트 뜨는지 확인.
5. **복원** 버튼 → 앱 재설치 후에도 프리미엄 복구되는지 (스토어 심사 필수 항목).

---

## STEP 5 — 검증 체크리스트

대시보드 없이 **먼저** 게이팅부터 검증 (가장 빠름):

- [ ] 설정 → Debug → **Dev Premium 토글 ON** → 비A1 팩/시나리오 잠금 해제되는지
- [ ] 토글 OFF → 다시 페이월 뜨는지
- [ ] 월간 offering이 있을 때 실제 현지 가격/주기를 표시하고, 없을 때는 가격을 만들지 않고 구매를 막는지

그 다음 실제 기기의 샌드박스 결제(테스트 결제 수단 확인 후):

- [ ] 라이선스 테스터 계정으로 샌드박스 구매 성공
- [ ] 구매 후 앱 재시작해도 프리미엄 유지 (오프라인 캐시)
- [ ] 복원 동작
- [ ] RevenueCat Overview에 구매/갱신 이벤트 수신
- [ ] 두 스토어 각각 신규 구매·복원·재설치·갱신·해지·만료·환불/철회·결제 보류·유예를 확인
- [ ] Google→Apple 추가 연결 및 iOS→Android 왕복에서 UID/학습 기록/구독 소유권 유지
- [ ] 기존 두 계정 충돌은 병합·교체 없이 안전하게 종료
- [ ] 늦은 웹훅/구매 완료가 계정 전환·삭제 후 다른 UID를 활성화하지 않음
- [ ] 오프라인 구독은 최대72시간 및 알려진 만료일까지, 테스터는 최대30일 뒤 재검증
- [ ] 원문/음성/토큰 없이 pending 최장 시간·실패율·비용·삭제 큐 적체 관측 및 운영자 알림 확인
- [ ] [백엔드 출시 게이트](firebase-backend-release-gates.md)의 비용 승인과 개인정보 마이그레이션 완료

---

## iOS (나중 — App Store Connect)

- App Store Connect → 자동 갱신 구독 그룹 + €5/월 상품 생성.
- RevenueCat에 **+ App Store** 앱 추가 → App-Specific Shared Secret 등록 → `appl_…` 공개 키 발급.
- 빌드에 `--dart-define=RC_IOS_KEY=appl_…` 추가.
- Sandbox 테스터(App Store Connect > 사용자 및 액세스 > Sandbox)로 결제 테스트.
- Apple은 심사 시 **복원 버튼 + 가격/약관 명시**를 요구 — 페이월에 이미 복원·`paywallLegal` 있음.

---

## 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| 가격이 없고 구매 버튼 "이용 불가" | 월간 offering/패키지/주기, SDK 키, 서비스계정 권한과 전파 상태 확인 |
| 샌드박스에서 "상품을 찾을 수 없음" | 앱이 Play 트랙에 업로드 안 됨 / 상품 "초안" 상태 / 테스터 계정 미등록 |
| 구매했는데 프리미엄 안 풀림 | Firebase/RevenueCat UID, entitlement 매핑, 환경, 웹훅·작업 큐와 getAccessSnapshot 검증 상태를 순서대로 확인; SDK 구매 성공만으로 권한을 부여하지 않음 |
| 결제 화면 자체가 안 뜸 | 무료 빌드 여부, durable 로그인·UID 바인딩, SDK 키·월간 offering 확인 |

---

## 주의 (보안)

- **공개 SDK 키**(`goog_`/`appl_`)는 앱에 들어가도 되는 값이지만, repo 평문 커밋은 지양 → `--dart-define` 또는 CI 시크릿.
- RevenueCat **Secret API Key**(`sk_…`)와 Google **서비스계정 JSON**은 절대 앱/`repo`에 넣지 말 것 (서버/대시보드 전용).
- `.gitignore`는 유출 방지 저장소가 아니다. Secret Manager와 승인된 자격 증명 전달 경로를 사용하고 키를 로컬 메모로 남기지 않는다.

공식 검증 참고: [고객 식별](https://www.revenuecat.com/docs/customers/identifying-customers),
[웹훅](https://www.revenuecat.com/docs/integrations/webhooks),
[Google 결제 테스트](https://developer.android.com/google/play/billing/test),
[TestFlight sandbox](https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store).
무시 파일도 보안 저장소는 아니다. Secret payload를 작업 디렉터리에 메모하지 않는다.
