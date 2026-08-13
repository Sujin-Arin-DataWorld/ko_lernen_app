# Analytics & Privacy Plan — Hangul Sori

> 2026-08-13 작성 (Claude). 두 갈래 리서치(EU/독일 법률 · GA4/Firebase 베스트프랙티스)와
> 실제 구현을 합친 단일 참조. **재디자인된 UI가 이벤트를 어디에 물릴지**와 **법적으로 안전한
> 데이터 활용**의 정본. ⚠️ 표시는 변호사/DPO 최종 검토 필요(엔지니어링 가이드이지 법률 자문 아님).

## 0. 원칙 (모든 결정의 기준)

1. **동의 시에만 수집** — 기본 OFF. 켜기 전엔 어떤 이벤트도 기기를 떠나지 않는다.
2. **PII 절대 금지** — 이름·이메일·OCR 원문·자유 텍스트·팩 이름·정밀 식별자를 param/키에 넣지 않는다. id·레벨코드·enum·버킷 카운트만.
3. **저카디널리티** — 기능마다 이벤트를 만들지 말고 enum discriminator를 쓴다(`feature_used`+`feature_name`). GA4의 500 이벤트명 상한은 영구다.
4. **미성년자(16세 미만) 완전 차단** — 자기신고 <16이면 동의를 저장해도 수집하지 않는다(DSGVO Art. 8).
5. **철회는 부여만큼 쉽게** — 설정 토글로 즉시 OFF(Art. 7(3)).

**법적 근거**: DSGVO **Art. 6(1)(a) 동의** + **§25 TDDDG**(구 TTDSG, 2024-05-14 개명·실질 동일 — 단말기 저장/접근 동의). 행동 분석에 정당한 이익 경로는 없다. EDPB Guidelines 2/2023이 스마트폰=단말기·앱 SDK 식별자=동의 대상임을 확인.

## 1. 지금 코드로 구현된 것 (이 저장소)

| 영역 | 상태 | 위치 |
|---|---|---|
| Hard gate (기본 OFF) | ✅ | Android manifest `firebase_analytics_collection_enabled=false`, iOS `FIREBASE_ANALYTICS_COLLECTION_ENABLED=NO`, Crashlytics 동일. `PrivacyConsentService.applyStored()`가 시작 시 저장 동의 적용 |
| 미성년자 backstop | ✅ | `PrivacyConsentService.setAnalytics/setCrash` + `Analytics._consentActive()`가 `AgeGateService.isUnderMinAge`면 강제 OFF·persist false |
| 광고 식별자 제거 | ✅ | Android: `AD_ID` 권한 `tools:node=remove` + `adid=false`(기존). iOS: `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED=NO` + ad-personalization 기본 거부(신규) → **ATT 프롬프트 불필요** |
| 동의 UX | ✅ | 첫 실행 `consent_screen`에 granular 토글(Analytics·Crash, 기본 OFF) + 설정 철회 토글. **⚠️ 재디자인 시: <16 사용자에겐 토글을 숨겨라**(backstop이 있지만 UX상으로도) |
| Analytics 서비스 | ✅ | `lib/services/analytics_service.dart` — 동의+미성년 게이트 no-op 래퍼(주입식·테스트가능), `screen_view` 옵저버, 타입드 이벤트, `setUserProperty`·`syncUserProperties()` |
| 배선된 이벤트 | ✅ | `screen_view`(자동), `pack_completed`, `onboarding_level_selected`, `book_capture_analyzed`, `custom_pack_created`, `gye_created/joined` |
| user property (startup 동기화) | ✅ | `learner_level`, `ui_language`, `notif_opt_in`, `streak_bucket` — `main.dart`에서 `Analytics.syncUserProperties()` |
| Consent Mode v2 | ⬜ 불필요 | 광고 없는 분석-전용 앱엔 hard gate가 더 깔끔. **광고(AdMob) 도입 시** 추가 |

## 2. 이벤트 & user property 스키마 (재디자인 UI가 호출)

새 화면에서 아래 타입드 메서드만 호출하면 된다(전부 `Analytics.xxx()`로 이미 존재, 동의 없으면 no-op). **저카디널리티·PII 금지** 규칙을 지킬 것.

### 우선 배선(임팩트순)
1. `lessonStarted` / `lessonCompleted` `{lesson_type, lesson_id?, level?, first_time}` — 핵심 학습 루프·활성화 정의
2. `quizCompleted` `{quiz_type, accuracy_pct, accuracy_band, level?, pass?}` — 학습 성과 1순위 신호(난이도 튜닝)
3. `onboardingStarted` / `onboardingCompleted` / `placementCompleted` — 활성화 퍼널 완성(배치가 리텐션에 도움되는지 측정)
4. `streakExtended` / `streakMilestone` / `dailyGoalMet` — 리텐션 레버(`daily_goal_met`은 D7 강력 예측)
5. `gameStarted` / `gameCompleted` `{game_type}` — 5개 미니게임을 이벤트 2개로(이름 예산 절약)
6. `ttsPlayed` `{content_type}` — 차별화 기능 사용률
7. `wordbookAdded` `{source, count}`, `featureUsed(feature_name, surface?)` — 기능 채택
8. `paywallViewed` / `subscribeStarted` — 구독 출시 전 baseline 확보(수익은 RevenueCat 서버사이드 `purchase`가 정본, 여기 금지)

### user property (≤24자, ≤25개, 예약접두사 금지)
`learner_level`(선택 레벨) · `ui_language` · `notif_opt_in` · `streak_bucket` — **구현됨**.
추가 권장: `has_placement`, `placement_level`(측정 레벨, 선택과 분리 = 인사이트), `hanok_stage`, `gye_member`, `subscription_status`(구독 시). PII 금지.

### GA4 하드 리밋 (지킬 것)
이벤트명 ≤40자·문자시작 · param ≤25/event · param값 ≤100자 · 이벤트명 ≤500종 · user property ≤25 · 커스텀 디멘전 50 event/25 user. 예약접두사 `firebase_`·`google_`·`ga_` 금지. 고카디널리티 param(원시 id·타임스탬프 체인)은 "(other)"로 뭉개짐 → BigQuery로 우회.

## 3. 콘솔/스토어 설정 (Jin — 코드 아님)

- **GA4**: 데이터 보존 **2개월**(기본 14 아님), **Google signals OFF**, **BigQuery export 연결**(무샘플링·무임계 심층분석·Firestore 조인), Key event 지정(첫 `lesson_completed`, 추후 `purchase`).
- **커스텀 디멘전 등록**: `level`·`pack_id`·`game_type`·`lesson_type`·`accuracy_band`·`feature_name`(안 하면 GA4 UI에 안 보임). `streak_length`·raw `gye_id`·`transaction_id`는 등록 금지(고카디널리티).
- **Apple App Privacy**: Identifiers(Device ID)·Usage(Product Interaction)·Diagnostics 선언, **"Data Not Used to Track You"**(IDFA/광고 없음). **Google Play Data Safety** 동일하게.
- **개인정보처리방침**: Firebase Analytics(사용측정)·Crashlytics(크래시진단) 명시, 근거 Art. 6(1)(a)+§25 TDDDG, 수신자 Google Ireland+Google LLC(US, processor), 전송 안전장치 **SCC + DPF**, 보존(GA4 2개월+Crashlytics 90일), 권리·철회(Art. 7(3))·감독기관 신고권.

## 4. 데이터로 앱 개선하기

- **Funnel exploration**: 활성화 퍼널(`first_open→onboarding_start→level_selected→placement→onboarding_completed→첫 완료`)·페이월 퍼널의 이탈 지점.
- **Audiences**: `activated`·`at_risk`(7일 미접속)·`placement_takers`·`paywall_viewed_no_purchase` → A/B 타깃·Remote Config 조건.
- **Retention report**: D1/D7/D30 곡선(자동, 커스텀 이벤트 불필요). `learner_level`·`has_placement` 코호트 비교로 배치의 효과 증명.
- **Remote Config + A/B Testing**: 실험을 지표에 묶는다(온보딩 순서→활성화율, 페이월 위치→`subscribe_started`, 스트릭 알림 문구→D7). 상관이 아닌 인과 결정.
- **DebugView**: 새 이벤트/param/property는 배포 전 여기서 초 단위 QA(표준 리포트는 ~24h 지연).

## 5. 액션 체크리스트 (⚠️ = 변호사/DPO)

**P0 — 법적 필수**
- [x] 첫 실행 hard gate(Analytics+Crashlytics 기본 OFF), 미성년 backstop
- [x] per-purpose 동의 화면(토글 OFF·Analytics/Crash 분리·거부해도 앱 사용), 설정 철회 패리티
- [ ] **기술적 진실 검증**(Jin): 새 설치에서 네트워크 캡처(Charles/mitmproxy)로 토글 전 Google/Firebase 트래픽 0 확인
- [ ] **개인정보처리방침 갱신**(Jin): §3 항목 전부
- [ ] **⚠️ 재디자인 시**: <16 사용자에게 동의 토글 미노출(backstop은 이미 있음)

**P1 — 데이터 최소화**
- [x] adid/IDFV OFF, ad-personalization 기본 거부
- [ ] GA4 보존 2개월·Google signals OFF(Jin)
- [x] 코드 PII 금지 준수(이벤트 param에 id·enum·카운트만)

**P2 — 스토어**
- [x] 최신 Firebase SDK → `PrivacyInfo.xcprivacy` 존재(앱·팟)
- [ ] Apple App Privacy + Play Data Safety 선언 일치(Jin)

**P3 — 거버넌스 ⚠️**
- [ ] Crashlytics 법적 근거(동의 vs 정당이익) 문서화
- [ ] DPIA 필요성 평가(미성년+체계적 모니터링 → 권장)
- [ ] Google DPF 인증 현황·정확한 SCC 모듈 문구 확인
- [ ] DPO 필요성·연령검증(자기신고) 강건성 판단

## 6. 남은 구현 (2026-08-13 Windows 세션 인수인계)

이 절은 Windows 세션에서 별도로 세운 계측 스펙을 이 문서로 흡수한 것이다. 중복 문서를
남기지 않기 위해 여기로 합쳤고 원본 스펙/계획 파일은 삭제했다. **이 문서가 정본이다.**

**전제 — UI는 레거시 셸로 되돌렸다.** `SoriStageFeatureGate`의 기본값이 `false`가 되어
앱은 `LegacyAppShell`(태고가 먼저 보이는 홈)로 뜬다. §2의 타입드 이벤트를 배선할 대상은
Sori Stage 5탭이 아니라 **레거시 셸의 화면들**이다. Sori Stage 화면은 코드에 그대로 남아
있고 `--dart-define=ENABLE_SORI_STAGE=true`로만 보인다.

- [ ] **타입드 이벤트 16종 배선.** §2에 정의만 되어 있고 호출부가 없다. 실제로 호출되는
      것은 `pack_completed`·`onboarding_level_selected`·`book_capture_analyzed`·
      `custom_pack_created`·`gye_created/joined` 6개뿐이다. 레거시 화면 기준으로 물린다.
- [ ] **파라미터 허용 목록 + 택소노미 계약 테스트.** §0 원칙 2("PII 절대 금지")가 지금은
      **규칙으로만** 존재한다. `Analytics.logEvent(name, parameters: {...})`가 public이라
      호출부에서 임의의 키·값을 넘길 수 있다. 허용 키 집합을 상수로 두고, 전체 이벤트를
      순회하며 키 허용 여부·이름 40자·값 100자 상한을 검증하는 테스트로 고정한다.
- [ ] **개인정보 센터 화면.** 개인정보 토글 3종(Analytics·Crash·발음 녹음)이
      `settings_screen.dart` 1011행 부근, 계정 섹션과 "안내 다시 보기" 다음에 묻혀 있다.
      Art. 7(3)의 "철회는 부여만큼 쉽게"에 비추어 약하다. 전용 화면으로 승격하고 설정에는
      진입 항목 하나만 남긴다(토글 복제 금지). 수집하지 않는 항목을 평문으로 명시한다.
- [ ] **철회 시 `resetAnalyticsData()`.** 분석 동의를 끌 때 앱 인스턴스 ID를 재발급하면
      이후 데이터가 철회 이전 사용자와 연결되지 않는다. 웹에서 `_ga` 쿠키를 지우는 동작과
      대칭이며 Art. 17 방어층이다. `PrivacyConsentService`의 분석 끄기 경로에 둔다.
- [ ] **동의 변경 시각 기록.** Art. 7 Abs. 1 증빙. `kl_analytics_consent_at` 등 ISO 8601
      문자열로 저장하고 개인정보 센터에 표시한다.
- [ ] **개인정보처리방침 4곳 갱신** (§5 P0의 항목과 동일). 앱 안 문구와 같은 사실을 말해야
      한다: `hangul-sori-site-local/app/privacy/page.tsx`(de/en/ko),
      `docs/store/privacy-en.md`, `docs/privacy.html`, `docs/store/data-safety.md`.

---

### 참고 (근거 출처 요약)
- §25 TDDDG / EDPB Guidelines 2/2023(스마트폰=단말기) / Planet49(pre-ticked 금지) / EDPB 05/2020(freely given·granular·withdrawal) / DSGVO Art. 8(독일 16세).
- Firebase data-collection 설정 플래그, GA4 자동수집 이벤트·리밋, RevenueCat→Firebase 통합(서버사이드 `purchase`), Apple Privacy Manifest.
