# Play Console — "앱 타겟층 및 콘텐츠" + 향후 광고 도입 가이드

> Source-of-truth for the Play Console *"Target audience and content"* section
> (5 steps) **and** the policy-safe roadmap for turning ads back on in a later version.
> Last updated: 2026-05-27.

---

## TL;DR — 결정된 값

| 단계 | Play Console 질문 | 한글소리 답변 |
|---|---|---|
| 1 | 대상 연령대 | **13–15세 + 16–17세 + 18세 이상** (모두 선택) |
| 2 | 앱 세부정보 | 어린이를 의도치 않게 끌어들이지 않는다고 보증 (Hangul Sori는 K-pop/K-drama 영향 받은 청소년+성인 대상) |
| 3 | 광고 | **광고 없음** (v1.0.0 기준 — `google_mobile_ads` 미활성, AdMob 매니페스트 잔재 모두 제거) |
| 4 | 앱 정보 | Google Family Programme 미참여, COPPA 적용 안 됨 |
| 5 | 요약 | 위 답변 그대로 |

---

## Step 1 — 대상 연령대 결정 근거

### 왜 13세 이상인가

1. **시장 현실**: 한국어 학습 앱의 핵심 타겟은 K-pop/K-drama 노출된 14–35세 (Sensor Tower 2024 K-learning 카테고리 보고서)
2. **콘텐츠 적합성**: 한글소리 콘텐츠 자체는 G-rated (욕설·폭력·성적 콘텐츠 없음). 단순 적합성만 따지면 더 어린 연령도 포함 가능
3. **법적 부담 회피**: 13세 미만을 타겟에 포함하면 **즉시 발생하는 정책 부담**:
   - **COPPA** (미국): Verifiable Parental Consent 필요. Firebase Auth의 익명 로그인도 데이터 수집으로 간주
   - **GDPR-K** (EU, 한글소리 주 시장): 회원국별로 13~16세 데이터 처리 동의 연령 다름. 독일은 16세. 즉 독일에서 13~15세도 부모 동의 필요
   - **Google Families Programme**: 가입 시 *모든* 광고 SDK가 "Designed for Families" 인증 받은 것만 사용 가능 (AdMob의 Families program 안에서만 — eCPM 절반 이하)
4. **CLAUDE.md 일관성**: `docs/store/data-safety.md`와 이전 결정 모두 13+ 기준. 변경 시 5개 문서 일괄 수정 필요

### 왜 18세 이상만 선택하지 않는가

- K-pop 학습 동기 사용자의 약 30%가 14–17세 (Statista 2024 K-content consumption Germany)
- "18+ only"로 좁히면 Google Play에서 **추가 노출 제한** 걸림 (system-level age gate 화면 노출 ↓)
- 한글소리 콘텐츠는 13–17세에게 완전히 안전

### Play Console UI 입력 순서

```
대상 연령대 → ✅ 13–15세 / ✅ 16–17세 / ✅ 만 18세 이상 (3개 모두 체크)
```

⚠️ "9–12세" 절대 체크 금지 — 체크하는 순간 Family Policy 전면 적용.

---

## Step 2 — 앱 세부정보 (어린이 끌림 방지 보증)

Play Console이 묻는 핵심: "13세 미만 어린이가 이 앱을 의도치 않게 사용하지 않는가?"

**한글소리 답변 근거**:
- ✅ 앱 아이콘: 갓+한 (역사적/문화적 모티프, 만화·캐릭터 IP 아님)
- ✅ 스크린샷: 한옥·단청·호랑이·까치 — 전통 민화 스타일. 픽사/디즈니 캐릭터 스타일 아님
- ✅ 설명문 (`listing-de.md`, `listing-en.md`): "Anfänger und Fortgeschrittene", "TOPIK", "Smalltalk im Café in Seoul" — 청소년·성인 톤
- ✅ 마스코트 호랑이/까치는 *민화* 스타일 (Faceted Minhwa) — 동요·유아 그림책 톤이 아님
- ✅ 게임 요소(Wordle, 끝말잇기, 초성)는 텍스트 기반, 어린이 게임 UI(큰 버튼·과장된 효과음·캐릭터 음성) 아님

이 모든 게 **자연스럽게 13+ 타겟임을 시각적으로 신호**한다. Play Console reviewer가 이의 제기할 가능성 매우 낮음.

---

## Step 3 — 광고 (v1.0.0: 없음)

### 현재 상태 (2026-05-27 확정)

| 위치 | 상태 |
|---|---|
| `pubspec.yaml` | `google_mobile_ads: 5.2.0` 주석 처리 |
| `lib/services/ad_service.dart` | Stub (no-op 메소드만) |
| `android/app/src/main/AndroidManifest.xml` | `APPLICATION_ID` meta-data 제거 |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier` + `SKAdNetworkItems` 제거 (2026-05-27) |

**Play Console 답변**: "아니요, 이 앱에는 광고가 포함되어 있지 않습니다."

이 답변은 Data-Safety form, Privacy Policy, 실제 빌드 4곳에서 일관됨.

---

## Step 4 — 앱 정보

| Play Console 항목 | 답변 |
|---|---|
| Google Family Programme 참여? | **아니요** |
| 어린이 대상 (Primarily Child-Directed)? | **아니요** |
| 혼합 타겟 (Mixed Audience)? | **아니요** (13+ only) |
| Designed for Families 인증 요청? | **아니요** |
| Teacher Approved 제출? | **아니요** (선택사항, v1.1+에서 고려 가능) |

---

## Step 5 — 요약 확인

위 4단계 답변이 일관되는지 Play Console이 자동 검증한다. 한글소리는:
- 콘텐츠 등급(IARC) **13+** ↔ 타겟 연령 **13+** ↔ "광고 없음" ↔ "어린이 미타겟" — 4축 모두 정합.

→ 제출 가능 상태.

---

# Part 2 — 향후 광고 도입 로드맵 (v1.1+)

> v1.0.0 출시 후 DAU/retention 데이터를 보고 광고 도입 여부 판단.
> 이 섹션은 그 시점에 **그대로 따라가면 정책 위반 0인 체크리스트**.

---

## 광고 도입 조건 (충족 전 켜지 말 것)

- [ ] DAU ≥ 2,000명 (그 미만이면 eCPM이 통계적 노이즈)
- [ ] 30일 retention ≥ 25% (그 미만이면 광고가 retention 더 떨어뜨림)
- [ ] 유료 대안 마련 — "광고 제거 €4.99 one-time" 또는 "Premium €2.99/월" (학습 앱 유료 전환율 3~7% 정상)
- [ ] Crashlytics 안정화 (crash-free users ≥ 99.5%) — 광고 SDK는 crash 원인 1순위

---

## 광고 도입 시 정책 위반 0 체크리스트 (순서대로)

> ⚠️ **선행 0번 — Play Console 광고 ID 선언 복원 (2026-08-02 추가).**
> 내부 테스트 업로드 때 매니페스트(AD_ID 제거)와 콘솔 선언("사용함")이 충돌해
> 선언을 **"아니요"로 내려서** 해소했다. 광고를 실제로 켜는 시점에:
> ① 콘솔 → 정책 → 앱 콘텐츠 → 광고 ID → **"예"** 로 복원
> ② `AndroidManifest.xml` 의 AD_ID `tools:node="remove"` 줄 제거(복원 주석 참조)
> ③ 아래 E(Data Safety) 와 같은 릴리스에서 반영 — 셋 중 하나만 빠져도 콘솔 오류.

### A. SDK 선택

| 추천 순위 | 네트워크 | 이유 |
|---|---|---|
| 1 | **Google AdMob** (`google_mobile_ads`) | Flutter 공식, Firebase 통합, UMP 동의 기본 제공 |
| 2 | AppLovin MAX (mediation 통해) | DAU 5k 이상 시 eCPM 향상 |
| ❌ | 자체 광고 서버 / 우회 SDK | Play Disruptive Ads 정책 위반 위험 ↑ |

### B. 코드 복원 절차

```bash
# 1. pubspec.yaml에서 주석 해제
#    google_mobile_ads: 5.2.0  →  google_mobile_ads: 5.2.0 (주석 제거)

# 2. AndroidManifest.xml에 production APPLICATION_ID 복원
#    <meta-data
#        android:name="com.google.android.gms.ads.APPLICATION_ID"
#        android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX" />

# 3. iOS Info.plist에 GADApplicationIdentifier + SKAdNetworkItems 복원
#    (이 파일의 헤더 주석 참고)

# 4. ad_service.dart를 git history에서 복원
git log --all --oneline -- lib/services/ad_service.dart
git show <commit-before-stub>:lib/services/ad_service.dart > lib/services/ad_service.dart

# 5. UMP (User Messaging Platform) 통합 — GDPR 필수
#    AdMob 콘솔에서 "Privacy & messaging" → "GDPR/EEA & UK" 메시지 생성
#    앱 첫 실행 시 ConsentInformation.requestConsentInfoUpdate() 호출
```

### C. 광고 슬롯 설계 (한글소리 권장)

| 위치 | 형식 | 정책 위반 위험 |
|---|---|---|
| ✅ 단어장/문법 리스트 하단 | Banner (anchored) | 0 — 학습 흐름 안 끊음 |
| ✅ Wordle 결과 카드 → "다시" 누를 때 | Interstitial | 0 — 자연 경계 |
| ✅ "힌트 보기" / "한 번 더 시도" | Rewarded | 0 — 가치 교환, 사용자 명시 동의 |
| ⚠️ 시나리오 step 사이 | Interstitial | **금지** — critical flow 차단 |
| ⚠️ Hangul 그리기 캔버스 위 | 모든 형식 | **금지** — input 방해 |
| ⚠️ 인트로 시퀀스 (`/intro`) | 모든 형식 | **금지** — 첫 인상 망침 |
| ⚠️ 앱 첫 30초 | 모든 형식 | **금지** — 신규 사용자 churn ↑ |

### D. Google Play Disruptive Ads 정책 — 9개 금지 항목

링크: https://support.google.com/googleplay/android-developer/answer/9857753

| # | 금지 행동 | 한글소리 위험도 |
|---|---|---|
| 1 | 앱 밖 표시 (lock screen, notification panel, system overlay) | 0 — AdMob 표준 사용 시 발생 안 함 |
| 2 | 가짜 시스템 UI / 가짜 X 버튼 | 0 — AdMob 표준 close 사용 |
| 3 | 사용자 클릭 없이 자동 리다이렉트 | 0 — AdMob 정책 자체 차단 |
| 4 | Critical interaction 차단 | **주의** — interstitial은 "결과 카드 → 다시"처럼 *자연 경계*에서만 |
| 5 | 광고를 콘텐츠로 위장 | 0 — 명시적 "Werbung / Ad" 라벨 |
| 6 | 게임 중 풀스크린 차단 | **주의** — Wordle/Chosung **진행 중** interstitial 금지 |
| 7 | 13세 미만 광고 (가족 정책) | 0 — 타겟이 13+ |
| 8 | 알림 영역 광고 | 0 — AdMob 표준만 사용 |
| 9 | Mediation도 동일 규칙 | AppLovin 등 추가 시 동일 규정 적용 |

### E. Data Safety form 업데이트 (광고 켤 때 필수)

`docs/store/data-safety.md`의 SDK-Audit 표에서:
- `google_mobile_ads`: ❌ → **✅ ja (Banner + Interstitial + Rewarded)**

Data collected 표에 추가:
- **Personal info → Email** (no change — Google Sign-In만)
- **Device or other IDs → Advertising ID** ← **광고용으로 사용됨** 표시 (현재는 Analytics용으로만)
- **App activity → Other user-generated content**: ad interaction events

Privacy Policy도 업데이트:
- Google AdMob 데이터 처리 명시
- 사용자 광고 ID 재설정 방법 안내 (Android: 설정 → Google → 광고)
- EEA 사용자에게 UMP 동의 화면 표시 사실 명시

### F. iOS App Tracking Transparency (ATT)

iOS 14.5+ — 사용자에게 "Allow App to Track" 프롬프트 필요한 경우:
- 한글소리는 **cross-app tracking 안 함** (광고 켜더라도 contextual만 사용 권장)
- ATT 프롬프트 **불필요**. `NSUserTrackingUsageDescription` 키 추가하지 말 것
- 단 SKAdNetwork ID 추가는 필요 (AdMob 콘솔에서 제공하는 list 그대로 복사)

### G. 광고주 직접 영업 (DAU 10k 이후 옵션)

| 후보 카테고리 | 후보 브랜드 (독일/유럽) | 접근 채널 |
|---|---|---|
| K-beauty | Yepoda, Mixsoon EU, Sweet Korea Skincare | Instagram DM + LinkedIn |
| K-travel | 한국관광공사 프랑크푸르트 지사 | imkto.org/de 공식 채널 |
| K-food | Hankook Mart, Korea Markt, Pulmuone Europe | B2B 부서 직접 메일 |
| 한국어 교육 (보완재) | 세종학당재단, 주독한국문화원 | 후원/스폰서십 형태 (광고 아님) |
| 항공 | 대한항공/아시아나 유럽 노선 | 미디어 에이전시 통해야 함 (직접 접근 어려움) |

**Media kit에 들어가야 할 데이터**:
- DAU / MAU / 30-day retention
- 사용자 인구통계: 국가 (DE/AT/CH 비율), 연령대 (Analytics에서 13-17 / 18-24 / 25-34 / 35+ 분포), 성별
- 평균 세션 길이 + 일일 세션 수
- 학습 레벨 분포 (A1 / A2 / B1 / B2)
- 가장 인기 있는 모듈 (시나리오 / Wordle / 어휘 등)

→ Firebase Analytics 자동 수집 데이터로 모두 추출 가능. Looker Studio 대시보드 1개로 정리.

---

## 변경 이력

- **2026-05-27**: 초안 작성. iOS Info.plist의 AdMob 잔재 제거 결정 반영.
