# Hangul Sori — €5/월 구독 전략 + 4주 로드맵 (2026-05-29)

> 목표: Hangul Sori Plus = **€4.99/월** (yearly €39.99, lifetime €49.99 일회)
> 무료 사용자에게도 충분히 가치 제공 + Plus 사용자가 "안 사면 손해" 느끼게.

---

## 1. 가격 전략

### 1.1 추천 가격
| 옵션 | 가격 | 비고 |
|---|---|---|
| **Plus 월간** | €4.99/월 | 부담 적은 진입 가격 |
| **Plus 연간** | €39.99/년 | 월 €3.33 — 33% 할인 (가장 인기) |
| **Plus 평생** | €49.99 일회 | 1년 미만에 본전, "팬" 사용자 lock-in |
| **Family Plus** | €7.99/월 (5인) | v1.2 이후 |

### 1.2 경쟁 비교 (월간 기준)
| 앱 | 월간 | 연간 | 비고 |
|---|---|---|---|
| **Duolingo Super** | €6.99 | €83.99 | global 1위, AI Plus 추가 €13.99 |
| **Memrise** | €8.49 | €59.99 | |
| **HelloTalk VIP** | €6.99 | €69.99 | |
| **Talk to Me in Korean** | $19/월 | — | premium niche |
| **🎯 Hangul Sori** | **€4.99** | **€39.99** | **경쟁 대비 30% 저렴 = 한국어 특화 USP** |

### 1.3 가격 심리학 (German 시장)
- €4.99 = "5유로 안" 심리 (€5보다 강함)
- €39.99 연간 = 월 €3.33 — €5보다 명백히 싸 보임 (33% 할인 표시)
- 첫 진입 시 **7일 무료 trial** (App Store/Play Store 표준, conversion 30-40% 보장)

---

## 2. Free vs Plus 기능 분리

### 2.1 무료 (Forever Free)
**핵심 학습 흐름은 모두 무료** — Duolingo 모델 (가치 우선, 광고 X)
- ✅ Hangul (자모 학습 완전)
- ✅ 단어장 — 하루 **10 카드** SRS due (Plus는 무제한)
- ✅ 문법 카드 — 처음 30개
- ✅ 시나리오 — A1만 (현재 6개)
- ✅ 게임 4종 — 각 하루 1세션 (Plus는 무제한)
- ✅ Streak + XP + Stats
- ✅ TTS 표준 음성

### 2.2 Plus 전용 (Subscription)
**감정·심도·확장**에 집중
- 🌟 **모든 시나리오 잠금 해제** (A2/B1/B2 전체)
- 🌟 **단어장·게임 무제한** — 일일 제한 없음
- 🌟 **NIKL 정의 + 영어 번역** (vocab 모듈)
- 🌟 **Offline mode** — 비행기/지하철 학습
- 🌟 **Streak shields** 무제한 (무료는 7일에 1개)
- 🌟 **테마 — 단청 4색 변형 + 다크모드 매당 시즌**
- 🌟 **개인 학습 stats — 주간 리포트**
- 🌟 **Premium TTS** (Neural Korean voice, 더 자연스러움)
- 🌟 **광고 0** (애초에 무료에도 광고 없음, 하지만 미래 보장)
- 🌟 **빠른 신기능 우선 access** — beta 모듈 (받아쓰기·발음)

### 2.3 절대 잠그면 안 되는 것
- 🚫 Hangul 자모 학습 — 한국어 입문자는 반드시 무료
- 🚫 Streak — 게임화 핵심
- 🚫 첫 7일은 모든 기능 trial — buyer's remorse 방지

---

## 3. 기술 스택 — RevenueCat 추천 (vs 직접 IAP)

### 3.1 옵션 비교
| 방식 | 장점 | 단점 | 추천? |
|---|---|---|---|
| **RevenueCat** | iOS+Android+Web 통합, 분석 dashboard, A/B 테스트, paywall 위젯 무료 | $10k MRR까지 무료, 이후 1% | ⭐ 추천 |
| **`in_app_purchase` Flutter plugin** | 의존성 0, 수수료 0 (외부) | 백엔드 직접, 정산·해지·환불 복잡 | ❌ 1.0엔 비추 |
| **Stripe Checkout** | 카드 결제, 약한 수수료 | iOS 정책 위반 (App Store는 IAP 강제) | ❌ 모바일 불가 |

### 3.2 RevenueCat 통합 (pubspec)
```yaml
dependencies:
  purchases_flutter: ^7.0.0
```

### 3.3 백엔드 = RevenueCat 자체 (별도 서버 0)
- App Store Connect / Google Play Console에서 product 정의
- RevenueCat dashboard에서 entitlement ("plus") 매핑
- 앱에서 `Purchases.purchasePackage()` 호출
- 클라이언트 검증: `Purchases.getCustomerInfo()` → `entitlements.active['plus']` 확인
- 서버 사이드 동기화 (선택): Firebase Cloud Function webhook

---

## 4. 4주 구현 로드맵

### Week 1 — Foundation (구조)
- [ ] **RevenueCat 계정 + Apple Developer + Google Play Console 설정**
- [ ] App Store Connect: 3 product (월/연/평생) + 가격 + 7일 trial
- [ ] Google Play Console: 동일 3 product
- [ ] RevenueCat에 mapping → entitlement "plus"
- [ ] Flutter: `purchases_flutter` 추가 + init
- [ ] `lib/services/subscription_service.dart` 신규
  - `PurchasesEntitlement get plus` — null이면 무료
  - `bool get isPlus`
  - `Future<bool> purchase(PackageId)` 
  - `Future<void> restore()`
- [ ] `lib/services/feature_gates.dart` 신규
  - `bool canAccessB2Scenarios()`
  - `int dailyVocabLimit()` // 무료 10, Plus null=무제한
  - `int gameSessionLimit()`

### Week 2 — UI / Paywall
- [ ] **Paywall screen** (`lib/screens/paywall_screen.dart`)
  - hero 시각: 호랑이 + 까치 + 한옥 (welcome-hero 재활용)
  - "Hangul Sori Plus" 타이틀
  - 3 price option (월/연/평생) — 연간을 default 강조
  - 5 핵심 benefit (bullet)
  - "7일 무료" 큰 CTA
  - "Restore purchases" 하단 작은 텍스트
  - "By subscribing, you agree to..." 법적 안내
- [ ] **Paywall 진입 동선**:
  1. Settings → "Hangul Sori Plus" 카드 (가장 안전)
  2. 잠긴 콘텐츠 탭 시 — soft modal (예: B2 시나리오 탭 → "Upgrade to unlock")
  3. 하루 제한 도달 시 — "10개 다 했어요! Plus로 무제한" (한 번만 표시 + dismissible)
- [ ] **잠금 표시** — 잠긴 시나리오/모듈에 🔒 chip + "Plus" 배지
- [ ] **무료 사용자 일일 카운터** — Storage에 `dailyVocabUsed` / `dailyGameSessions`, 자정 reset

### Week 3 — Feature gates 통합
- [ ] `VocabScreen` — 일일 카드 10개 제한 + 다음날까지 카운터
- [ ] `ScenariosListScreen` — A2~B2 시나리오에 🔒, 탭 시 paywall
- [ ] `ChosungQuizScreen` / `WordleScreen` / `KkeunmariScreen` — 하루 1세션 후 paywall
- [ ] `SettingsScreen` — "Plus" 섹션 (Active이면 plan + expiry, 아니면 upgrade CTA)
- [ ] `_TigerHero` 말풍선 컨텍스트 messages — Plus 사용자 전용 message variant (예: "5분만 더 해볼까요? 평생회원이시잖아요 ⭐")
- [ ] **Offline mode (Plus 전용)** — Hive 캐시 + 시나리오/단어 사전 다운로드

### Week 4 — Launch ready
- [ ] **법적 / 컴플라이언스**
  - `docs/store/terms-of-service.md` 작성 (자동 갱신·해지 정책 명시)
  - Privacy policy 업데이트 — RevenueCat data flow
  - GDPR/DSGVO 동의 sheet (구독 시작 전)
  - 한국어 사용자: 회원가입·결제·환불 정책 한국어 버전 (Play Store KR 출시 시)
- [ ] **A/B 테스트 ready** — RevenueCat dashboard에서 paywall 2가지 variant
  - A: 연간 default (현재)
  - B: 월간 default + "save 33% with yearly" badge
- [ ] **분석 — 핵심 지표**
  - Paywall view rate
  - Trial start rate
  - Trial → paid conversion
  - Monthly retention (M1/M3/M6)
  - LTV by source (Settings vs locked-feature vs limit-hit)
- [ ] **Stress test** — 100명 beta 그룹 → 실 결제 5명 이상 + 환불·복구 시나리오 검증
- [ ] Submit App Store / Play Store

---

## 5. 컴플라이언스 체크리스트

### 5.1 App Store / Play Store 필수 (둘 다 강제)
- ✅ **명확한 자동 갱신 disclosure** — "Subscription renews automatically unless cancelled 24h before period end"
- ✅ **가격 + 기간 paywall에 명시** — "Renews €4.99/month"
- ✅ **해지 방법 안내** — "Manage in Settings > Apple ID > Subscriptions" (iOS) / "Play Store > Subscriptions"
- ✅ **무료 trial 명확** — "7-day free trial, then €4.99/month"
- ✅ **"Restore purchases"** 버튼 — 재설치 시 복구
- ✅ **EULA + Privacy 링크** — paywall + Settings

### 5.2 EU/GDPR 추가 (Germany 주 시장)
- ✅ **명시적 동의** — 결제 전 "I agree to ToS + Privacy"
- ✅ **14일 회수권 (Widerrufsrecht)** — 디지털 콘텐츠는 사용 시작 시 포기 가능, BUT 명시 필요
- ✅ **VAT** — Apple/Google이 처리 (셀러는 net price만 받음, ~70%)
- ✅ **언어** — paywall + ToS 독일어 필수 (한국어 + 영어는 추가 권장)

### 5.3 Korean 시장 (Play Store KR)
- ✅ **소비자 보호법** — 7일 청약 철회 (단, 사용 시 제한)
- ✅ **신용카드 정보 보호법** — 개인정보 처리방침에 결제 정보 처리 명시
- ✅ **VAT 10%** — Google Play KR이 처리

---

## 6. 예상 매출 (보수적·낙관적)

### 6.1 가정
- DAU 1000명 (보수) — 한국어 학습 독일어권 사용자
- 무료→paid conversion 4% (Duolingo 평균 6%, 우리는 신규)
- Plus 평균 plan 분포: 60% 연간 / 35% 월간 / 5% 평생
- 평균 ARPU/월: (0.6 × €3.33) + (0.35 × €4.99) + (0.05 × €4.17) = **€3.95/월**

### 6.2 시나리오 (월매출)
| DAU | Paid | 월매출 (€) | 연매출 (€) |
|---|---|---|---|
| 500 | 20 | 79 | 948 |
| 1,000 | 40 | 158 | 1,896 |
| 5,000 | 200 | 790 | 9,480 |
| 10,000 | 400 | 1,580 | 18,960 |
| 50,000 | 2,000 | 7,900 | 94,800 |

→ App Store/Play Store **30% 수수료 제외**: 위 금액 × 0.7
→ 한국어 학습 niche에서 DAU 5,000 도달 시 풀타임 작업 가능한 수익

---

## 7. 위험 + 완화

| 위험 | 완화 |
|---|---|
| **사용자가 ‘유료=별로'로 느낌** | 무료 layer 충실 — Hangul/30 vocab/A1 시나리오/하루 1게임 — "무료로도 충분히 배운다" 평판 |
| **App Store 거절** (자동갱신 표기 미흡) | week 4 체크리스트 + 실제 paywall 스크린샷 검수 |
| **환불 폭주** | 7일 trial로 본전 뽑게 + ToS에 사용 시 환불 제한 명시 |
| **경쟁사 가격 인하** (Duolingo €4.99로 따라옴) | yearly bundle + lifetime 옵션 — 단기 가격경쟁 회피 |
| **한국어 콘텐츠 부족** | v1.0 → v1.5에서 시나리오 21 → 50, 단어 2000+ |

---

## 8. 출시 후 첫 30일 액션

1. **Week 1**: 분석 dashboard 매일 체크 — paywall view → trial → paid 깔때기
2. **Week 2**: 트라이얼 만료 즈음 사용자에게 push notification — "끝나기 24시간 전, 1년 plan 할인"
3. **Week 3**: 결제 시도 실패 사용자에게 in-app message (signature: 호랑이 + 까치)
4. **Week 4**: A/B 테스트 결과 분석 → 더 잘 컨버팅한 paywall variant fix

---

## 9. 의존성 / 필요 결정

이번 세션에 답해주면 바로 Week 1 진행 가능:

- [ ] **App Store Developer 계정 등록 상태**? (US$99/년)
- [ ] **Google Play Developer 계정 등록 상태**? (US$25 일회)
- [ ] **법인 / 사업자등록**? (구독 매출 발생 시 필수)
- [ ] **결제 받을 은행 계좌** (EUR 지원)
- [ ] **법무 검토** — 누가 ToS/Privacy 검토? (별도 변호사 vs 템플릿 + DIY)
- [ ] **무료 trial 7일 vs 14일** — 7일 추천 (conversion 더 좋음)
- [ ] **첫 출시 가격 시도** — €4.99 / €5.99 / €6.99 중?
- [ ] **lifetime 옵션 포함 vs skip?** — 포함 추천 (5% 라도 큰 매출 +)
- [ ] **iOS 동시 출시 vs Android 우선?** — Android 우선 + 검증 후 iOS 추천 (현재 코드 기준)

위 답에 따라 Week 1 작업이 결정됨.
