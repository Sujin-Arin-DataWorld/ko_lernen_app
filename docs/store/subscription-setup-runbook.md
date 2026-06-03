# 구독 운영 셋업 런북 — Hangul Sori €5/월 Premium (RevenueCat)

> 작성: 2026-06-03 · 대상: Jin (운영) · 코드 상태: **완료** (M4, `58c3c76`)
> 이 문서는 **코드가 아니라 대시보드 작업**이다. 아래 5단계만 끝내면 결제가 실제로 작동한다.

---

## 0. 지금 상태 (왜 코드는 안 건드려도 되나)

코드에 이미 있는 것 (검증함):

| 요소 | 위치 | 비고 |
|---|---|---|
| 구독 서비스 | `lib/services/premium_service.dart` | RevenueCat `purchases_flutter ^10.2.0`. 키 없으면 **무료 모드**(크래시 X) |
| 페이월 UI | `lib/screens/paywall_screen.dart` | €5/월 단일 플랜, 구매/복원, l10n DE/EN |
| 게이팅 | 단어팩 비A1·시나리오 비A1·홈 | `PremiumService.gate(context)` → 무료면 `/paywall` |
| Dev 토글 | `lib/screens/settings_screen.dart` (Debug) | 대시보드 없이 무료↔프리미엄 전환 테스트 |

**코드가 기대하는 고정값** (대시보드에서 이 이름 그대로 써야 함):

- Entitlement ID = **`premium`** (`premium_service.dart:29`)
- 패키지 = **Monthly** (`o.monthly` 우선, 없으면 첫 패키지로 폴백)
- 가격 표시 = 스토어 상품의 `priceString` → **€5는 코드가 아니라 Play Console 상품에서 설정**
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
4. 기본 요금제를 **활성화**.
5. (선택) 무료 체험/할인은 **혜택(Offer)**로 나중에 추가 가능 — 지금은 스킵.

> ⚠️ 상품은 활성 상태여야 RevenueCat·앱에서 보인다. "초안"이면 offering이 비어 페이월이 폴백 가격만 표시.

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
   - 코드가 `offering.monthly`를 먼저 보므로 **Monthly 패키지로** 넣는 게 가장 깔끔.

---

## STEP 3 — 키 주입 + 빌드

공개 SDK 키는 repo에 커밋하지 말고 빌드 시 주입:

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/app/outputs/symbols \
  --dart-define=RC_ANDROID_KEY=goog_xxxxxxxxxxxxxxxx
# iOS 추가 시: --dart-define=RC_IOS_KEY=appl_xxxxxxxxxxxx
```

- 키 없이 빌드하면 `PremiumService`가 조용히 무료 모드 → 크래시 안 나지만 **결제도 안 됨**. 실제 출시 빌드엔 반드시 키 주입.
- `--dart-define`은 컴파일 타임 상수 → AAB마다 들어간다. CI 쓰면 환경변수로.
- Play Billing 권한(`com.android.vending.BILLING`)은 `purchases_flutter`가 매니페스트 머지로 **자동 추가**(수동 선언 불필요). 빌드 후 merged manifest에서 한 번 확인하면 안심.
- 빌드가 `minSdk` 관련 에러를 내면 `android/app/build.gradle.kts`의 `minSdk`를 명시적으로 올려 (현재 `flutter.minSdkVersion` 상속).

---

## STEP 4 — 샌드박스 결제 테스트 (실제 청구 X)

1. Play Console → **설정 > 라이선스 테스트** → 테스트할 Google 계정(Gmail) 추가.
2. 그 계정이 로그인된 실기기에 **내부 테스트 트랙**으로 배포된 앱 설치 (사이드로드 APK는 결제 안 됨 — Play 경유 필수).
3. 앱에서 비A1 단어팩/시나리오 진입 → 페이월 → 구매 → "테스트 카드"로 결제(청구 안 됨).
4. 결제 후 게이팅이 풀리는지 + RevenueCat 대시보드 **Overview**에 이벤트 뜨는지 확인.
5. **복원** 버튼 → 앱 재설치 후에도 프리미엄 복구되는지 (스토어 심사 필수 항목).

---

## STEP 5 — 검증 체크리스트

대시보드 없이 **먼저** 게이팅부터 검증 (가장 빠름):

- [ ] 설정 → Debug → **Dev Premium 토글 ON** → 비A1 팩/시나리오 잠금 해제되는지
- [ ] 토글 OFF → 다시 페이월 뜨는지
- [ ] 페이월에 가격이 `€5,00 / Monat`처럼 뜨는지 (offering 연결됐을 때) / 아니면 폴백 문구

그 다음 실결제:

- [ ] 라이선스 테스터 계정으로 샌드박스 구매 성공
- [ ] 구매 후 앱 재시작해도 프리미엄 유지 (오프라인 캐시)
- [ ] 복원 동작
- [ ] RevenueCat Overview에 구매/갱신 이벤트 수신

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
| 페이월이 폴백 가격만, 구매 버튼 "이용 불가" | offering/패키지 미연결, 또는 STEP 2-2 서비스계정 권한 미전파(최대 36h) |
| 샌드박스에서 "상품을 찾을 수 없음" | 앱이 Play 트랙에 업로드 안 됨 / 상품 "초안" 상태 / 테스터 계정 미등록 |
| 구매했는데 프리미엄 안 풀림 | entitlement ID가 `premium`이 아님 (대소문자·철자) → 코드는 정확히 `premium`만 검사 |
| 결제 화면 자체가 안 뜸 | 키 미주입(무료 모드) → `--dart-define=RC_ANDROID_KEY=` 확인 |

---

## 주의 (보안)

- **공개 SDK 키**(`goog_`/`appl_`)는 앱에 들어가도 되는 값이지만, repo 평문 커밋은 지양 → `--dart-define` 또는 CI 시크릿.
- RevenueCat **Secret API Key**(`sk_…`)와 Google **서비스계정 JSON**은 절대 앱/`repo`에 넣지 말 것 (서버/대시보드 전용).
- 기존 `.gitignore`가 `.env*` 처리 중 — 키 메모는 거기 두면 안전.
