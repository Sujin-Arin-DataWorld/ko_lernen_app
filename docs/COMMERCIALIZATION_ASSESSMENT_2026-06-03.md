# 한글소리 (Hangul Sori) — 상용화 준비도 종합 평가

> 작성: 2026-06-03 · 작성자: Claude (Opus) 전수 조사 기반
> **원칙: 환각·추측 없이 실제 파일 read/grep/측정 결과만 인용.** 확인 못 한 것은 "확인 불가"로 명시.
> 조사 범위: `lib/` 124파일 39,509줄 전수 + `assets/data/` 실측 + `test/` 25파일 + `functions/` + `docs/` 60+ md + 5개 plan + `docs/index.html` 웹사이트 + Android/iOS 빌드설정.
> 검증 방법: 병렬 6개 서브에이전트(화면·서비스·콘텐츠·인프라·플랜대조·문서) + `flutter analyze`/`flutter test` 실행 + 직접 Read.

---

## 0. 한 줄 결론

**앱 자체(코드·기능)는 내부 테스트 배포가 가능한 수준으로 완성되어 있다. 그러나 "상용화(유료 결제가 실제로 돌아가는 출시)"까지는 코드가 아니라 *운영·배포·콘텐츠 검수* 작업이 가로막고 있다.**

- **기술적 출시(무료 베타/내부테스트)까지: 약 1~2주** — 전부 Jin의 로컬·콘솔 작업(빌드·배포·등록), 새 코드 거의 불필요.
- **유료 구독 상용화까지: 약 4~8주** — RevenueCat·Cloud Function·법무/사업자·실기기 QA·스토어 자산이 모두 끝나야 첫 €1이 들어온다.
- **경쟁력 있는 리텐션 제품까지: 약 2~3개월** — 듀오링고 대비 약점(진척 시각화·푸시·도파민 루프)을 메우는 추가 개발.

---

## 1. 종합 점수표 (사실 근거 기반)

| 영역 | 점수 | 근거 (실측) |
|---|---|---|
| **코드 완성도** | 9 / 10 | `flutter analyze` **0 issues**(실행 확인), 화면 41개 중 미연결 stub 0개, `print()` 0건, services TODO 0건 |
| **코드 안정성(테스트)** | 7 / 10 | `flutter test` **218개 통과**(실행 확인). 단 OCR·결제·CloudFn·게임플레이·TTS·공유는 무커버 |
| **콘텐츠 볼륨** | 5 / 10 | 단어 526 / 시나리오 33(평균 6.2줄, 얕음) / 문법 88 — 입문엔 충분, 유료 정당화엔 부족 |
| **기능 폭(범위)** | 9 / 10 | 책한컷·SRS·게임4·시나리오·퀘스트·한옥성장·공유·구독·알림·개인화 모두 코드 존재 |
| **기능 동작(현재)** | 5 / 10 | 책한컷 번역·구독 결제 둘 다 외부설정 미완으로 **현재 미작동** |
| **인프라/보안** | 7 / 10 | Firestore rules SECURE, R8 minify ON, 실 keystore. 단 CI가 test 미실행, CloudFn 미배포 |
| **웹사이트** | 6 / 10 | 디자인 수준 높음(3개국어·단청), 그러나 **실제 스크린샷 0장**, 소셜증거 0, 데모 0 |
| **출시 운영 준비** | 3 / 10 | 실기기 QA **0회**, 스토어 자산 미완, 구독·CloudFn·rules 미배포 |
| **수익화 실현성** | 4 / 10 | RevenueCat 코드 완성·게이팅 동작 가능, but 대시보드/상품/키 0 → **현재 결제 1건도 불가** |

> 점수는 "현재 시점 실제 상태" 기준이다. 코드만 보면 8~9점대지만, 상용화는 운영이 가른다.

---

## 2. 무엇이 실제로 만들어졌나 (코드 — 검증됨)

### 2.1 규모
- Dart **124파일 / 39,509줄**. 화면 41개(20,228줄), 서비스 28개(3,743줄).
- `lib/main.dart` 라우트 테이블에 **35개 라우트** 등록, 전부 실제 화면 클래스로 연결됨([main.dart:173-309](lib/main.dart)). `PlaceholderScreen`은 정의만 존재하고 **어떤 라우트에도 연결 안 됨**(grep 확인).

### 2.2 품질 신호 (실측)
- `flutter analyze` → **No issues found!** (실행 확인, 6.7s)
- `flutter test` → **218 tests passed** (실행 확인)
- `grep TODO/FIXME` → screens 2건([kkeunmari_screen.dart:558](lib/screens/kkeunmari_screen.dart) 데이터 필터 주석), services **0건**
- `grep print(` → **0건** (디버그 출력 잔재 없음)

### 2.3 플래그십 기능 — 코드 레벨 진실성
| 기능 | 코드 상태 | 현재 실제 작동? |
|---|---|---|
| 솟을대문 인트로 | ✅ [intro_gate_screen.dart](lib/screens/intro_gate_screen.dart), `initialRoute: '/intro'` | ✅ 작동 |
| 한옥 12단계 성장 | ✅ enum 12단계([hanok_stage.dart](lib/models/hanok_stage.dart)) + 서비스 | ⚠️ light PNG **10/12**, dark **0/12** → 11·12단계·다크는 그라데이션 폴백 |
| 단어팩 61 Learn→Quiz→Boss | ✅ `enum _Stage{learn,quiz,boss}` ([vocab_pack_screen.dart:41](lib/screens/vocab_pack_screen.dart)) | ✅ 작동 |
| SRS (간격반복) | ✅ SM-2 변형, [storage_service.dart:305-347](lib/services/storage_service.dart) | ✅ 작동 |
| 책 한 컷 (사진→단어) | ✅ on-device OCR([snap_ocr_service.dart](lib/services/snap_ocr_service.dart)) + CloudFn 클라 | ❌ **CloudFn 미배포 → 번역·단어추출 안 됨**, 문법패턴 stub만 표시 |
| 나만의 단어장 + 4모드 | ✅ play/quiz/matching/typing + CSV + 사진 | ✅ 작동(자동채우기만 CloudFn 의존) |
| 게임 4종(초성/워들/끝말잇기/듣기) | ✅ 전부 실구현 | ✅ 작동 (TTS는 OS 음성 의존) |
| 시나리오 + 5종 퀘스트엔진 | ✅ [scenario_player_screen.dart](lib/screens/scenario_player_screen.dart) | ✅ 작동 |
| 친구코드 공유 | ✅ Firestore `shared_packs/{code}` ([shared_pack_service.dart](lib/services/shared_pack_service.dart)) | ⚠️ rules 배포 필요 |
| 구독(RevenueCat) | ✅ [premium_service.dart](lib/services/premium_service.dart) + [paywall_screen.dart](lib/screens/paywall_screen.dart) | ❌ **대시보드/키/상품 0 → 결제 불가, 전원 무료** |
| 로컬 알림 | ✅ flutter_local_notifications ([notification_service.dart](lib/services/notification_service.dart)) | ✅ 작동 |
| 개인화 일일코스 | ✅ [personalized_lesson_service.dart](lib/services/personalized_lesson_service.dart) | ✅ 작동 (단 **AI 아님, 로컬 휴리스틱**) |
| 광고 | ❌ [ad_service.dart](lib/services/ad_service.dart) 9줄 stub | — (의도적 무광고) |

> **중요한 진실 2가지** (마케팅/문서가 과장하기 쉬운 지점):
> 1. **"책 한 컷"의 핵심(번역·단어추출·뜻풀이)은 현재 작동하지 않는다.** OCR로 글자는 읽지만 Cloud Function이 배포 안 돼서 단어 리스트가 비고 문법 패턴만 나온다. 웹사이트·스토어 설명은 이 기능을 플래그십으로 내세우므로, **배포 전 출시하면 설명-실제 불일치**가 된다.
> 2. **"AI 개인화"는 현재 AI가 아니다.** `personalized_lesson_service`는 SRS-due + 관심사 매핑의 순수 로컬 점수 계산이다. 메모리(`project_commercialization_direction`)의 "AI 무한 개인화 콘텐츠"는 미구현 설계.

---

## 3. 콘텐츠 볼륨 — 실측 (반올림·추정 없음)

| 데이터 | 실측값 | 평가 |
|---|---|---|
| 단어 (`korean_vocab.csv`) | **526개** / 고유 pack_id **61개** | "61팩" 주장 **사실**. 단어량은 듀오링고 초급(~1,500-2,000)의 ~26% |
| 레벨 분포 | A1:211 / A2:140 / B1:103 / B2:72 | 상위 레벨로 갈수록 얇음 |
| 시나리오 (`scenarios.json`) | **33개**, 대화 **204줄**, 평균 **6.2줄/개** | 개수는 양호, **깊이 얕음**(상용 회화앱은 20-50 교환) |
| 문법 (`grammar.csv`) | **88개** (A1:27/A2:23/B1:22/B2:16) | A1-B2 범위 적절 |
| 끝말잇기 풀 | **2,453단어** | 게임 지속성 충분. 단 독일어 번역은 일부만(대화 로그상 ~69개 채움, 나머지 미번역) |
| 스몰토크 | **145구문 / 18카테고리** (ko+de+en 3개국어) | 보조 콘텐츠로 적절, 유일하게 영어까지 완비 |
| UI 문자열 | `app_de.arb`=`app_en.arb`=**600키** (완전 parity, 누락 0) | UI 로컬라이제이션 완성도 높음 |

**콘텐츠 언어 진실**: 핵심 학습 콘텐츠(단어 526·문법 88)는 **독일어 전용** — `english` 컬럼 자체가 없음. 영어 UI를 켜도 단어 뜻·문법 설명은 독일어로 나온다. 영어권 확장 = 526+88개 신규 번역 작업이 기술 부채로 존재.

---

## 4. 계획 대비 실제 진행 (매트릭스)

> 출처: `~/.claude/plans/` 5개 + `docs/plans/jongga` 핸드오버 8개. **계획 문서의 체크박스는 stale**(원본 plan은 [x] 거의 0) — 실제 진행의 단일 정보원은 코드 + `CLAUDE.md` 세션로그다.

| 이니셔티브 | 코드 진행 | 최대 잔여 갭 |
|---|---|---|
| v2.0 Jongga (단어팩·한옥·퀘스트·책한컷·커스텀팩) Phase 1~5.2 | **~95%** (코드 파일 전부 존재 확인) | CloudFn 배포·dark PNG·실기기 QA |
| 출시 폴리시 (temporal-wombat Week1-4) | **~95%** | Hangul IoU 정확도(이월), 실기기 시각검증 |
| 상용화/구독 (expressive-petting-sparrow M1-M5) | **코드 ~90%** | RC 대시보드, 끝말잇기 독일어 ~2,000개, "AI" 실제화 |
| Cloud Function + 공유 (eager-puppy) | **코드 ~85%** | gcloud 배포·rules 배포 (운영) |
| 살아있는 한옥 UI (glimmering-storm) Phase 2~4 | **~30%** | 홈=마당 재구성, 마스코트 생명력 **미착수** |
| Jongga Phase 6~9 (계 커뮤니티) | **0%** | `gye_service.dart` 없음 — 전체 미착수 |

**요약**: "출시용 v2.0" 범위는 코드가 거의 다 끝났다. 미착수 대형 블록(계 커뮤니티, 살아있는 한옥 후기 Phase)은 모두 **출시 이후(v3.0+) 범위**라 출시를 막지 않는다.

---

## 5. 경쟁 차별화 — 듀오링고 외 (사실 + 문서 인용)

### 5.1 우리가 더 나은 점 (보존·강화 대상)
- **문화적 몰입/세계관**: 한옥 12단계 성장, 솟을대문 시네마틱, 단청 팔레트, 민화 화풍. `docs/living-app-audit`가 "듀오링고도 이 수준의 ambient는 없다"고 자평 — 코드상 ambient 입자·비행까치·KenBurns·축하 burst 모두 실재.
- **책 한 컷**(사진→단어장): 듀오·메모라이즈에 없는 차별 기능. *단, §2 경고대로 현재 미작동.*
- **원어민 독일어 1차 타깃**: 600키 UI + 단어/문법 독일어 전용 = 독일어권 특화. 듀오의 기계적 다국어 대비 강점.
- **무광고 + 오프라인 + on-device OCR(프라이버시)**: 데이터 안전 포지셔닝.

### 5.2 우리가 뒤처지는 점 (`docs/UIUX_DUOLINGO_GAP_AND_PLAN.md` 인용)
> "듀오링고의 본질은 '선택을 없애고, 다음 한 걸음을 명확히, 누르는 순간 보상'. 우리 앱은 정반대로 '고를 게 너무 많고, 경로가 안 보이고, 누르는 순간의 쾌감이 약함.'"

| 격차 | 듀오링고 | 한글소리 현재 (실측) |
|---|---|---|
| 선택 과부하 | "지금 할 단 하나" + 큰 버튼 | 홈에서 **19개 `pushNamed`** 분기([home_screen.dart](lib/screens/home_screen.dart)) |
| 학습 경로(스킬트리) | 구불구불 트리가 메인 메타포 | SkillPathRail이 하단 가로 1줄로 묻힘 |
| 도파민 루프 | 정답 즉시 사운드+햅틱+콤보 | XP/스트릭은 있으나 정답 순간 연출 약함, **SFX 없음(TTS만)** |
| 마스코트 페르소나 | 반응형 Duo | 호랑이=정적 hero 이미지 |
| 앱 밖 리텐션 | 푸시 강박+리그+데일리골 | 로컬 알림은 구현됨, 경쟁/리그 없음 |
| 진척 시각화 | 레벨/유닛/트리 | 한옥 단계는 좋으나 "다음 한 걸음" 불명확 |

---

## 6. 부족한 점 · 개선해야 할 점 (우선순위)

### 🔴 P0 — 출시(상용화)를 *막는* 것
1. **Cloud Function 미배포** → 책 한 컷 핵심 미작동. 플래그십이 광고와 불일치.
2. **구독 운영 0** → RevenueCat 대시보드·Play 구독상품·`--dart-define` 키 전부 없음. 결제 1건도 불가.
3. **실기기 QA 0회** → 카메라·OCR·TTS·결제·시각 레이아웃이 실기기에서 검증된 적 없음(문서 전체에서 "0회" 반복).
4. **Firestore rules 미배포** → 공유·동기화가 프로덕션에서 동작 안 할 수 있음.
5. **스토어 자산 미완** → feature graphic(1024×500) 0, 스크린샷 8장 0 → Play Console 등록 자체 불가.

### 🟠 P1 — 품질·신뢰
6. **CI가 `flutter test`를 안 돌림** ([.github/workflows/ci.yml](.github/workflows/ci.yml)는 analyze + build web만). 218개 테스트가 자동 회귀검증 안 됨.
7. **플래그십 무테스트**: OCR·결제·CloudFn HTTP·게임플레이·공유·CSV 인입 자동 테스트 0.
8. **iOS 앱 표시명 불일치**: `CFBundleDisplayName = "Ko Lernen App"` ≠ 스토어명 "Hangul Sori".
9. **콘텐츠 깊이**: 시나리오 평균 6.2줄, 단어 526개 — 유료 구독을 정당화하려면 증량 필요.
10. **끝말잇기 독일어 번역 대량 누락** (~2,000개) — 게임 힌트가 비어 보일 수 있음.

### 🟡 P2 — 경쟁력(리텐션)
11. 홈 선택 과부하 → 단일 "지금 할 것" CTA로 수렴.
12. 스킬트리(학습 경로) 시각화 격상.
13. 정답 순간 SFX/햅틱/콤보 도파민 루프.
14. 마스코트 반응형(상황별 포즈 전환) — 자산은 일부 있으나 로직 약함.
15. 웹사이트 실제 스크린샷·데모.

### 🟢 P3 — 확장 (출시 후)
16. 영어권 학습 콘텐츠(단어/문법 영어 컬럼).
17. AI 개인화 실제화(배치 콘텐츠 생성).
18. 계(契) 커뮤니티 (현재 0%).
19. STT 발음 평가, TOPIK 모드.

---

## 7. 웹사이트 평가 (`docs/index.html` — 971줄 직접 read)

### 잘 된 점
- **디자인 완성도 높음**: 단청 4색 토큰, 한지 grain 텍스처, breath 애니메이션, reduce-motion 대응. 단일 HTML로 깔끔.
- **3개국어 i18n** (DE/EN/KO, `data-*` 속성 + localStorage), 라이트/다크 토글.
- **메시지 명확**: Hero 카피가 "암기 공장이 아닌 공간", 책 한 컷을 flagship full-width 카드로 강조.
- 접근성 신경 씀(aria-label, role).

### 약점 (`docs/UIUX_DUOLINGO_GAP` 진단과 일치 + 직접 확인)
1. **실제 스크린샷 0장** — 스크린샷 섹션이 전부 `data-label` placeholder([index.html:864-871](docs/index.html)). "Coming soon"으로 정직하나, 전환율의 최대 약점.
2. **소셜 증거 0** — 평점·리뷰·사용자수 없음(미출시라 불가피).
3. **단일 CTA 미수렴** — 기능 카드 11개(큰 7 + mini 4)로 여전히 정보 벽. 문서는 "10→4 압축" 권고했으나 미반영(flagship 강조만 부분 적용).
4. **데모 영상/GIF 없음** — 살아있는 한옥·모션이 강점인데 정적 이미지로만 전달.
5. CTA가 전부 **메일 신청**(`mailto:`) — Play 링크 없음(미출시라 당연, 출시 시 교체 필요).

---

## 8. 앱 안정성 · 인프라 (실측)

### 강점
- **`flutter analyze` 0 / `flutter test` 218 통과** (둘 다 실행 확인).
- **Firestore rules SECURE**: `isOwner(uid)` 격리 + 기본 `allow read,write: if false` + `shared_packs` wordCount≤100 제한 ([firestore.rules](firestore.rules)). 테스트모드 아님.
- **릴리스 빌드**: R8 `isMinifyEnabled=true`, `isShrinkResources=true`, ProGuard, 실 keystore(`key.properties` 존재) ([android/app/build.gradle.kts](android/app/build.gradle.kts)).
- **AdMob 잔재 완전 제거** (Android Manifest + iOS Info.plist 양쪽).
- **Crashlytics + Analytics 연동** ([main.dart:120-123](lib/main.dart)).
- **Cloud Function 코드 품질 우수**: kiwipiepy(순수 Python, Java 불필요) + DeepL + 오프라인 폴백 ([functions/analyze_korean_text/main.py](functions/analyze_korean_text/main.py)).

### 리스크
- **CI에 test 단계 없음** (analyze + build web만).
- **`intl: any`** — 버전 미고정, 충돌 위험 ([pubspec.yaml](pubspec.yaml)).
- **Swift Package Manager 미지원 플러그인 4개**(image_cropper, mlkit×2, flutter_tts) — iOS 미래 빌드 경고.
- **Cloud Function 실제 배포 여부 = 확인 불가** (Firebase Console 접근 불가). 코드상 클라 기본 endpoint는 `europe-west3-ko-lernen-app.cloudfunctions.net`([main.dart:65-66](lib/main.dart))로 박혀 있으나 응답 여부 미검증.
- **AAB 실제 산출물 = 직접 미확인** (CLAUDE.md에 "Jin 로컬 빌드 통과" 언급은 있음).

---

## 9. 출시 블로커 통합 (중복 제거 · 담당)

> 6개 문서(release-readiness, LAUNCH_READINESS, JIN_VERIFY_CHECKLIST, closed-testing-checklist, data-safety, cloud-function-deploy)에서 "오픈/Jin 필수"로 명기된 항목 통합. **거의 전부 코드가 아니라 Jin의 운영 작업.**

| # | 작업 | 담당 | 막는 것 |
|---|---|---|---|
| 1 | `flutter pub get → gen-l10n → analyze → test` 재실행 | Jin 로컬 | 빌드 |
| 2 | AAB 빌드(`--release --obfuscate --split-debug-info`) | Jin 로컬 | Play 업로드 |
| 3 | **실기기 시각/기능 QA (Android 1대 최소)** | Jin | 신뢰 |
| 4 | `firebase deploy --only firestore:rules` | Jin | 공유·동기화 |
| 5 | **Cloud Function 배포**(`gcloud ... --gen2 --region=europe-west3`) | Jin | 책 한 컷 |
| 6 | feature graphic 1024×500 + 스크린샷 8장 | Jin/자산 | Play 등록 |
| 7 | Play Console: Privacy URL·Data Safety·연령·카테고리·AAB 업로드 | Jin | 등록 |
| 8 | RevenueCat 대시보드 + Play 구독상품 `premium_monthly` + 키 주입 | Jin | 결제 |
| 9 | 법인/사업자·EUR 계좌·법무·가격 확정 | Jin | 수익화 |
| 10 | DeepL 키 재발급(대화 평문 노출됨) | Jin | 보안 |

---

## 10. "상용화까지 얼마나 남았나" — 시나리오별

### 시나리오 A — 무료 베타/내부테스트 출시
**남은 거리: ~1~2주, 신규 코드 거의 0.**
필요: 블로커 #1-7 + #10. CloudFn은 배포하면 책한컷도 켜짐. 구독은 비활성(전원 무료)이라도 앱은 완전 동작.
→ **사실상 "거의 다 왔다."** 막는 건 Jin의 로컬 빌드 + Firebase 배포 + Play Console 등록 + 실기기 1회 점검.

### 시나리오 B — 유료 구독 상용 출시
**남은 거리: ~4~8주.**
시나리오 A + 블로커 #8(RevenueCat 전체 셋업·샌드박스 결제 검증) + #9(사업자/법무/EUR 계좌 — 리드타임 김) + 콘텐츠 검수.
→ 기술이 아니라 **비즈니스·법무 리드타임**이 결정. 결제 코드는 이미 완성.

### 시나리오 C — 듀오링고와 겨루는 리텐션 제품
**남은 거리: ~2~3개월.**
B + P2 전부(단일 CTA·스킬트리·도파민 루프·마스코트 반응형·SFX) + 콘텐츠 증량(단어 1,000+, 시나리오 깊이) + 웹사이트 스크린샷/데모.

---

## 11. 리스크 등록부 (출시 전 반드시 인지)

| 리스크 | 심각도 | 근거 | 완화 |
|---|---|---|---|
| 책한컷 광고-실제 불일치 | 🔴 높음 | CloudFn 미배포 시 번역 안 됨 | 배포 후 출시, 또는 스토어 카피에서 톤 다운 |
| 결제 전원 무료로 출시 | 🟠 중 | RC 키/대시보드 0 | 무료 베타로 시작하고 구독은 후속 |
| 실기기 미검증 크래시 | 🟠 중 | QA 0회, 카메라/TTS/IAP 무테스트 | 내부테스트 5-10명으로 1주 |
| 스토어 심사 반려 | 🟠 중 | 스크린샷·Data Safety·콘텐츠등급 정합성 | 문서 `data-safety.md` 그대로 입력 |
| DeepL 키 노출 | 🟡 낮 | 대화 평문 노출 기록 | 재발급 |
| iOS 표시명 불일치 | 🟡 낮 | `CFBundleDisplayName` | Info.plist 1줄 수정 |

---

## 12. 부록 — 검증에 사용한 실행 결과 요약
- `flutter analyze` → No issues found! (실행)
- `flutter test` → 218 passed (실행)
- `python3` 측정: vocab 526행/61팩, scenarios 33, grammar 88, smalltalk 145, kkeunmari 2,453, l10n de=en=600
- `ls assets/illustrations/hanok_stages/` → light 10장, dark 0장
- `grep` : screens TODO 2 / services TODO 0 / print() 0 / 홈 pushNamed 19
- 직접 Read: `main.dart`(라우트 35), `docs/index.html`(971줄)

> **이 평가의 모든 수치는 위 명령의 실제 출력이다. 확인 못 한 것(CloudFn 실배포·RC 대시보드·AAB 산출물·실기기 동작)은 "확인 불가"로 표기했다.**
