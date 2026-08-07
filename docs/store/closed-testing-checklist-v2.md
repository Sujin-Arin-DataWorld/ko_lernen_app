# Closed Testing Readiness Checklist — v2.0.0-alpha

> ⚠️ **이 문서는 인프라 배포 절차(Firestore rules · Cloud Functions · AAB 업로드)의 정본이다.**
> 기기·화면·접근성·네트워크·데이터 안전 등 **수동 QA 는
> `docs/store/RELEASE_QA_CHECKLIST.md`** 로 옮겼다(2026-08-06). 두 문서를 함께 쓴다.

> Phase 1-5.2 코드 작성 끝. 이 문서는 **Jin이 Closed Testing 출시까지 직접 실행할 작업** 전체 목록.
> 작성: 2026-06-01

---

## 0. 직전 세션 검증 결과

- ✅ `flutter analyze`: **0 issues**
- ✅ `flutter test`: **197/197** 통과 (Phase 1-5 + 회귀)
- ✅ 마스코트 백업 복원 완료 (직전 세션, tiger 12개 모두 원본 사이즈)
- ✅ 새 코드 라우트 모두 등록 + 홈 진입로 + Settings endpoint UI

---

## 1. 인프라 (배포)

### 1.1 Firestore Rules
```bash
cd /Users/sujinpark/Developer/ko_lernen_app
firebase deploy --only firestore:rules
```
**기대**: `✔ Deploy complete!` + console URL.
**실패 시**: `.firebaserc` 활성 프로젝트 확인 (`firebase use`).

### 1.2 Cloud Function (선택 — 권장)

a. DeepL Free 키 발급 (https://www.deepl.com/pro-api/free) — 월 500K 문자.

b. Firebase Functions config 설정:
```bash
firebase functions:config:set deepl.api_key="YOUR_DEEPL_KEY_HERE"
```

c. 의존성 + 배포:
```bash
cd functions/analyze_korean_text/
pip install -t . -r requirements.txt   # 또는 firebase가 처리
cd ../..
# 이 repo의 함수 소스는 functions/analyze_korean_text입니다.
# root firebase.json에 functions 코드베이스 설정이 없으면 다음 명령이 실패할 수 있습니다.
firebase deploy --only functions
```
**기대**: 함수 URL 출력 — 형식 `https://us-central1-ko-lernen-app.cloudfunctions.net/analyze_korean_text`.

> 참고: `firebase deploy --only functions:analyze_korean_text`는 현재 `firebase.json`에 해당 named target이 정의되어 있지 않으면 실패합니다.

d. URL 을 앱 Settings 의 "Cloud-Analyse-Endpoint" 에 붙여넣기.

**배포 안 한 상태에서도 동작**: 책 한 컷이 "Server nicht erreichbar — nur Grammatikmuster offline" 배너 + 31개 grammar pattern 만 표시. Closed Testing v1 에는 OK.

---

## 2. 코드 빌드 검증 (Jin 로컬)

```bash
cd /Users/sujinpark/Developer/ko_lernen_app
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```
**기대**: 0 errors, 0 info (chosung known issue 1건만), 197+ 케이스 통과.

---

## 3. 실기기 시각 검증 (SIM unlock 후)

```bash
flutter run -d 9053622f   # M2101K6G (Redmi Note 10)
```

### 3.1 핵심 시나리오 (8 단계)

1. **온보딩** — 솟을대문 인트로 → 레벨 A1 선택 → 홈
2. **홈 진입로 신규 카드 확인** — 책 한 컷 / 책장 / 퀘스트 카드 3개 보임
3. **단어팩 흐름** — `/vocab` → 첫 팩 (a1_greetings_1) 만 available, 나머지 잠김
4. **첫 팩 학습** — learn → quiz → boss → ≥70% → 도장 + 다음 팩 unlock 토스트
5. **한옥 시네마틱** — 홈 진입 시 "Sockel legen" 등 토스트 (첫 stage 전환)
6. **책 한 컷** — `/book` → 카메라 권한 → 사진 → 자르기 → OCR → 분석 → 결과
7. **커스텀 팩 생성** — 결과 화면 "Create Custom Pack" → 이름 입력 → SnackBar "Play" → flip cards
8. **Settings endpoint** — Settings → "Cloud-Analyse-Endpoint" 섹션 → URL 입력 → Save → 재실행 후 보존 확인

### 3.2 회귀 체크 (기존 기능)

- [ ] Hangul drill 화면 정상
- [ ] Grammar 화면 정상
- [ ] Wordle / Anlaut Quiz / Kkeunmari 정상
- [ ] Stats 화면 정상
- [ ] Settings 다른 옵션 (TTS 속도, 언어, Cloud Backup) 정상
- [ ] 다크 모드 전환 — 모든 화면 가독성

---

## 4. 출시 자료 (이번 세션 완료)

- ✅ `docs/privacy.html` v2 (2026-06-01) — Camera + DeepL 명시 (EN/DE/KO)
- ✅ `docs/store/data-safety.md` v2 — SDK audit + User-generated text + Photos stay on device
- ✅ `docs/store/release-notes-v2.md` — DE/EN release notes (500자 한도 내)
- ✅ `docs/store/listing-de.md` — 짧은 설명 + 프로모 텍스트 + 전체 설명 v2.0 업데이트
- ✅ `docs/store/listing-en.md` — 동일

### 4.1 Privacy URL 활성화

```bash
# docs/privacy.html 이 github-pages 로 자동 배포됨 (docs/CNAME 활용)
# 변경 사항 커밋 + push 만 하면 됨
git add docs/privacy.html docs/store/
git commit -m "v2.0: privacy + data-safety + listing update"
git push origin main
```
배포 확인: <https://hangul-sori.com/privacy.html> 에서 "Zuletzt aktualisiert: 2026-06-01" 확인.

---

## 5. AAB 빌드

### Internal closed-testing AAB (feedback enabled)

Run this exact command from the repository root for Play Console internal and
closed testers.

```bash
# Check pubspec.yaml before building. Its build number must be higher than the
# highest build number already uploaded to Play Console; never reset it to an
# older value.

flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=ENABLE_TESTER_FEEDBACK=true --dart-define=BETA_UNLOCK_ALL=true
```

### Production AAB (feedback disabled)

Run this separate PowerShell command from the repository root for an Android
production release with payments. Set `RC_ANDROID_KEY` to the live public
Android SDK key from the production RevenueCat project; the guard stops before
building when it is absent or malformed. Do not add an
`ENABLE_TESTER_FEEDBACK` define.

```powershell
$env:RC_ANDROID_KEY = '<paste-live-RevenueCat-Android-SDK-key>'
if ([string]::IsNullOrWhiteSpace($env:RC_ANDROID_KEY) -or $env:RC_ANDROID_KEY -notmatch '^goog_[A-Za-z0-9_-]{8,}$') { throw 'Set RC_ANDROID_KEY to the live RevenueCat Android SDK key before building.' }
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=RC_ANDROID_KEY=$env:RC_ANDROID_KEY --dart-define=BETA_UNLOCK_ALL=false
```

**산출물**:
- `build/app/outputs/bundle/release/app-release.aab` (~55~70MB 추정)
- `build/app/outputs/symbols/` (난독화 심볼 — Crashlytics 스택 trace 복원용)

빌드 검증:
```bash
Get-Item build/app/outputs/bundle/release/app-release.aab | Select-Object Name, Length
# < 100MB 기대 (Play Store limit 200MB AAB)
```

---

## 6. Play Console — Closed Testing 트랙

### 6.1 사전 준비 (Console)

- [ ] Privacy URL: `https://hangul-sori.com/privacy.html` 등록
- [ ] App Access: "All functionality is available without special access"
- [ ] Data Safety 폼 — `docs/store/data-safety.md` Table 그대로 옮기기
- [ ] Content Rating IARC 13+
- [ ] Target Audience: 13–15 + 16–17 + 18+ (3개 체크)
- [ ] App Category: Education
- [ ] Contact email: `hello@hangul-sori.com`

### 6.2 Closed Testing 트랙 생성

1. Play Console → 테스트 → **Closed Testing**
2. 트랙 이름: "v2.0-alpha"
3. AAB 업로드 + Native debug symbols 업로드
4. Release Notes (DE + EN) 붙여넣기 (`release-notes-v2.md`)
5. Tester 이메일 그룹 만들기 → 5-10명
6. "Save → Review → Start rollout to Closed Testing"

### 6.3 Tester 초대 템플릿

```
Hi [Name],

Wir haben ein größeres Update für Hangul Sori — v2.0-alpha.
Würdest du als Closed Tester die neuen Funktionen ausprobieren?

Neu:
• Vokabel-Packs (526 Wörter, 61 Packs)
• Hanok-System — dein Hof wächst mit dir
• 17 Spezial-Quests
• 📷 Snap-and-Learn — Lehrbuchseite fotografieren → automatische Analyse

Mit dieser E-Mail-Adresse kannst du die Tester-Version installieren:
[Opt-in Link aus Play Console kopieren]

Wir würden uns über Feedback freuen — gerne per E-Mail oder direkt im "About"-Screen den Daumen-runter-Knopf nutzen.

Vielen Dank!
Sujin
```

---

## 7. 모니터링 (출시 후 1주)

### 7.1 Crashlytics
- Firebase Console → Crashlytics → ko-lernen-app
- v2.0 crash rate 목표: < 0.5% sessions

### 7.2 Analytics
- Firebase Console → Analytics
- Active users, screen flow
- 새 화면 (book_capture, bookshelf, custom_pack_play) 의 retention 관찰

### 7.3 Tester 피드백
- Email 또는 Play Console feedback
- 우선순위 분류:
  - **Sev 1 (즉시 patch)**: 크래시, 데이터 손실, 권한 거부 후 회복 불가
  - **Sev 2 (v2.0.1)**: UX 혼란, 잘못된 번역, OCR 정확도 낮음
  - **Sev 3 (백로그)**: 디자인 호불호, 추가 기능 요청

---

## 8. v2.0.1 가능성 (Closed Testing 피드백 기반)

- 책 한 컷 OCR 정확도 낮으면 → 이미지 전처리 (Adaptive threshold) 추가
- 사용자가 q_jangdokdae (50개 음식 단어) 목표 비현실적 의견 → 목표 25 로 조정
- In-app account deletion (Play 정책 2024 권장 사항) — Phase 8 v2 후보

---

## 9. v3.0 Roadmap (Closed Testing 안정화 후)

- **Phase 6** — 계 (커뮤니티) 데이터 모델 + 모임방 + 주간 목표 + 스티커 (3주)
- **Phase 7** — 모더레이션 + GDPR-K (16세 미만 가드)
- **v3.0 Public Release**

---

**작성**: Claude
**검토 대기**: Jin
**커밋 권한**: Jin 명시 요청 시
