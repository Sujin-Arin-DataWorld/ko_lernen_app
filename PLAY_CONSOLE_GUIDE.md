# 🚀 Google Play Console — 단계별 출시 가이드 (Hangul Sori v1.0)

> **현재 상태 (2026-05-20):**
> - ✅ `.aab` 생성됨 (`build/app/outputs/bundle/release/app-release.aab`, 56MB)
> - ✅ 업로드 keystore 서명됨 (SHA1: `C0:81:AA:E0:...:78:AA:2E`)
> - ✅ Firebase Auth + Firestore 작동 확인
> - ✅ Store description DE/EN/KO 작성 완료 (`STORE_LISTING.md`)
> - ✅ Privacy Policy 초안 완료 (`PRIVACY_POLICY.md`)
> - ⏳ Play Console 계정 등록 — **본인 작업**
> - ⏳ Privacy Policy 호스팅 — **본인 작업**
> - ⏳ Feature graphic + 스크린샷 8장 — **본인 작업**

---

## STEP 1: Play Console 계정 등록 ($25)

### 절차 (10분)

1. https://play.google.com/console 접속
2. 사용할 Google 계정으로 로그인 (**vjinny2@gmail.com 추천 — Firebase와 동일**)
3. "Get started" → **개인 계정** 선택 (조직 = D-U-N-S 번호 필요해서 복잡)
4. $25 USD 결제 (신용/체크카드, 평생 1회)
5. **본인 확인 절차**:
   - 정부 발급 ID 사진 업로드 (여권 또는 신분증)
   - 셀카 1장
   - Google에서 **1–3 영업일** 내 검토 (이메일 알림)
6. 결제 프로파일 설정 (무료 앱이라도 필수)
   - 주소: 베를린 (DE 거주)
   - 세금: 개인 = 자동 처리

### ⚠️ 주의
- Google Play Console은 **DUNS 없이도 개인 등록 가능** (2024년부터 정책 변경)
- 단, **20명 테스터로 14일 closed testing 완료 후에만** Production 가능 (2023년 신규 정책)
  - → 그래서 **Internal Testing → Closed Testing → Production** 순서로 진행

---

## STEP 2: 앱 생성 (검토 통과 후)

1. Play Console 좌측 **"Create app"**
2. **App details:**
   ```
   App name (default):    Hangul Sori: Learn Korean
   Default language:      English (United States) — en-US
   App or game:           App
   Free or paid:          Free
   ```
3. **Declarations** (체크박스):
   - [x] My app meets Developer Program Policies
   - [x] I accept the US export laws
4. "Create app" 클릭

---

## STEP 3: 앱 콘텐츠 설정 (필수 — 모두 완료해야 출시 가능)

좌측 메뉴 **"Policy" → "App content"** 에서 각 섹션 완료:

### 3.1 Privacy Policy
- URL: `https://[YOUR-HOSTING]/privacy` (Termly 또는 GitHub Pages)
- → `PRIVACY_POLICY.md`를 HTML로 변환 후 호스팅

### 3.2 App access
- ✅ "All functionality available without special access"
  (로그인 강제 없음, 익명 사용 가능)

### 3.3 Ads
- ⚠️ "No, my app does not contain ads"
  (현재 AdMob stub만 있음 — 광고 표시 안 됨)
- → 나중에 AdMob 활성화 시 변경 필요

### 3.4 Content rating
- Questionnaire 작성 (약 5분)
- 답변 가이드:
  - Violence: **None**
  - Sexuality: **None**
  - Profanity: **None**
  - Drugs/gambling: **None**
  - User-generated content: **None** (사용자가 콘텐츠 작성 불가)
  - Shares user info: **Yes** (Google 로그인 시 이메일 — 옵션)
  - Shares location: **No**
  - 결과: **Everyone** (모든 연령) 예상

### 3.5 Target audience
- Target age: **13+** (Google Sign-In 정책상 13세 미만 불가)
- Appeal to children: **No**

### 3.6 News app
- **No** (뉴스 앱 아님)

### 3.7 COVID-19 contact tracing
- **No**

### 3.8 Data safety (★ 중요 — Privacy Policy와 일치해야 함)

| 데이터 종류 | 수집? | 공유? | 목적 | 선택 사항? |
|---|---|---|---|---|
| Email address | ✅ (Google 로그인 시) | ❌ | App functionality, Account management | ✅ |
| Name | ✅ (Google 로그인 시) | ❌ | App functionality | ✅ |
| User IDs (Firebase UID) | ✅ | ❌ | App functionality, Analytics | ❌ |
| App activity (학습 진도) | ✅ (선택 — Cloud Sync 시) | ❌ | App functionality | ✅ |
| App info and performance | ❌ | ❌ | — | — |

암호화 in transit: ✅ Yes (TLS)
사용자가 데이터 삭제 요청 가능: ✅ Yes (Settings → "Delete cloud data")

### 3.9 Government apps
- **No**

### 3.10 Financial features
- **No**

### 3.11 Health
- **No**

---

## STEP 4: Main store listing 작성

좌측 **"Grow" → "Store presence" → "Main store listing"**

`STORE_LISTING.md` 참고하여 입력:

### 4.1 Default (English)
- **App name**: `Hangul Sori: Learn Korean`
- **Short description**: (80자 텍스트 복사)
- **Full description**: (4000자 텍스트 복사)
- **App icon**: `assets/icons/icon-512.png` 업로드
- **Feature graphic**: 1024×500 (제작 필요)
- **Phone screenshots**: 최소 2장, 권장 8장

### 4.2 독일어 추가 (de-DE)
"Manage translations" → "Add your own translations" → German (Germany)
- 위 4.1과 동일하게 독일어 텍스트 입력

### 4.3 (선택) 한국어 추가
ko-KR 추가하면 한국 검색 노출 ↑

---

## STEP 5: .aab 업로드 — Internal Testing 트랙

좌측 **"Test and release" → "Testing" → "Internal testing"**

### 5.1 새 릴리스 만들기
1. "Create new release" 클릭
2. **Play App Signing 활성화** (Google이 권장 — 무료, keystore 분실 시 도움됨)
   - Upload key는 우리 keystore (이미 등록됨)
   - App signing key는 Google이 관리 (사용자가 보는 SHA는 다름)
3. **App bundle 업로드**: `build/app/outputs/bundle/release/app-release.aab`
4. **Release name**: `1.0.0 (1) - Initial release`
5. **Release notes** (en-US):
   ```
   🎉 Hangul Sori is here! Welcome to your Korean learning journey.

   • Animated Hangul stroke order
   • Vocabulary by CEFR level (A1–B2)
   • Grammar flashcards
   • Korean games (Hangul Wordle, Initial Consonant Quiz)
   • Native pronunciation (offline TTS)
   • Multilingual UI: English / Deutsch / 한국어

   Made with ❤️ in Berlin.
   ```
6. (de-DE):
   ```
   🎉 Hangul Sori ist da! Willkommen auf deiner Koreanisch-Lernreise.

   • Animierte Hangul-Strichreihenfolge
   • Vokabeln nach Niveau (A1–B2)
   • Grammatik-Karteikarten
   • Koreanische Spiele (Hangul Wordle, 초성 퀴즈)
   • Native Aussprache (offline TTS)
   • Mehrsprachige UI: Deutsch / English / 한국어

   Mit ❤️ in Berlin gemacht.
   ```

### 5.2 테스터 추가
"Testers" 탭 → "Create email list":
- 본인 이메일 (vjinny2@gmail.com)
- 남친 이메일
- 친한 친구 5–10명 (한국어 학습에 관심 있는 독일/한국 친구)

→ 최대 100명까지 즉시 테스트 가능. **14일간 활성 사용자 12명** 모이면 Closed Testing 자격 충족.

### 5.3 검토 + 출시
1. "Review release" → 모든 경고 해결
2. "Start rollout to Internal testing"
3. **Google 검토 시간: 1–3시간** (Internal은 빠름)
4. 승인되면 테스터에게 공유 링크 전송 가능

---

## STEP 6: 다음 단계 (Internal → Closed → Production)

### 6.1 Internal Testing 단계 (지금 ~ 2주)
- 본인 + 남친 + 친구들이 실제 폰에 설치
- 버그/UX 피드백 수집
- 14일간 활성 사용자 12명 채우기

### 6.2 Closed Testing 단계 (2–4주)
- "Closed testing" 트랙 새로 생성
- 20명 이상 옵트인 테스터 필요 (Google 자체 정책)
- 14일간 활성 사용자 20명 유지
- → **Production 자격 획득**

### 6.3 Production 단계 (출시!)
- "Production" 트랙으로 promote
- 국가/지역 선택: **All countries available** (전 세계)
- 우선순위 마케팅: DE/AT/CH/KR/US/FR
- 가격: **Free**
- IAP: 없음
- 검토 시간: **3–7일** (첫 출시는 더 오래 걸림)

---

## STEP 7: Firebase에 Release SHA 등록 (★ 잊으면 Google 로그인 깨짐)

### 왜 필요한가
Play App Signing을 활성화하면 Google이 **새 SHA1**을 생성한다. Google Sign-In은 SHA1로 앱을 식별하므로 등록 안 하면 production에서 로그인 안 됨.

### 절차
1. Play Console → 좌측 **"Setup" → "App integrity"**
2. "App signing" 섹션에서 **SHA-1 certificate fingerprint** 복사 (Google 관리 키)
3. 또한 **SHA-256** 복사
4. https://console.firebase.google.com → **ko-lernen-app** 프로젝트
5. ⚙️ Settings → **General** → 아래로 스크롤 → Android 앱
6. **"Add fingerprint"** → SHA1 추가
7. 다시 **"Add fingerprint"** → SHA256 추가
8. **`google-services.json` 재다운로드**:
   - 다운로드 버튼 클릭
   - `/Users/sujinpark/Developer/ko_lernen_app/android/app/google-services.json` 덮어쓰기
9. .aab 재빌드 → 다음 릴리스에 업로드

⚠️ 우리 upload key SHA도 추가하면 좋음 (Internal 테스트에서 작동):
- SHA1: `C0:81:AA:E0:C9:5D:9F:11:05:45:44:5B:64:CA:39:41:3C:78:AA:2E`

---

## ✅ 출시 전 최종 체크리스트

- [ ] Play Console 계정 등록 + 본인 확인 통과
- [ ] Privacy Policy HTML 호스팅 + URL 확보
- [ ] Feature graphic 1024×500 제작
- [ ] 스크린샷 8장 (에뮬레이터)
- [ ] App content 모든 섹션 완료 (특히 Data safety)
- [ ] Internal testing에 .aab 업로드 + 통과
- [ ] Firebase에 Play App Signing SHA 등록
- [ ] google-services.json 재다운로드 + 재빌드
- [ ] 본인이 테스트 링크로 다운로드 + 정상 동작 확인
- [ ] Closed testing 트랙 20명 채우기 (2–4주)
- [ ] Production 출시 🚀

---

## 🆘 문제 발생 시

| 문제 | 해결 |
|---|---|
| **본인 확인 거부** | 다른 ID 사진 재제출 (밝게, 모서리 다 보이게) |
| **앱 검토 거부** | 거부 사유 이메일 확인 → Privacy Policy/Data Safety 일치 여부 확인 |
| **Closed Testing 12명 못 채움** | Reddit r/korean, KakaoTalk 한국어 학습 오픈채팅 등에서 모집 |
| **Google 로그인 안 됨 (production)** | STEP 7 — Play App Signing SHA를 Firebase에 등록 안 함 |
| **Upload 시 "versionCode already used"** | `pubspec.yaml`의 `version: 1.0.0+2` 로 빌드 번호 증가 |

---

## 📅 예상 일정

| 단계 | 기간 | 작업 |
|---|---|---|
| Play Console 등록 + 본인 확인 | 1–3일 | Google 검토 |
| 자산 준비 (graphic, screenshots, privacy) | 2–4시간 | 본인 작업 |
| Internal Testing 업로드 | 1시간 | Console 입력 |
| Internal 검토 | 1–3시간 | Google 자동 |
| Internal Testing 활성 사용자 12명 14일 | 2–4주 | 자연 누적 |
| Closed Testing 20명 14일 | 2–4주 | 모집 + 대기 |
| Production 검토 | 3–7일 | Google 수동 |
| **총합** | **6–10주** | 첫 앱 기준 |

→ 이미 다른 앱을 낸 적 있는 개발자라면 Closed Testing 의무 면제됨 (하지만 본인은 첫 앱)

---

*가이드 작성: 2026-05-20*
*다음 작업: STEP 1 — Play Console $25 결제 → 검토 통과 알림 받으면 STEP 2부터 진행*
