# 한글소리 — 상용화 개선 구현 계획 (Detailed Roadmap)

> 작성: 2026-06-03 · 짝 문서: [`COMMERCIALIZATION_ASSESSMENT_2026-06-03.md`](COMMERCIALIZATION_ASSESSMENT_2026-06-03.md)
> 원칙: 모든 작업은 **실제 파일 경로·함수·실측 수치**에 근거. 추측 구현은 "권고/설계"로 표기.
> 담당 표기: **[운영]** = Jin의 콘솔/빌드/비즈니스 · **[코드]** = 소스 변경 · **[자산]** = 이미지/콘텐츠 · **[검증]** = 테스트.

---

## 0. 트랙 개요 & 의존성

```
TRACK 0  출시 차단 해제 ─────────────┐ (1-2주, 거의 운영)
                                     ├─► 무료 베타 출시 가능
TRACK 4  안정성/CI ──────────────────┘
                                     
TRACK 1  결제 상용화 ────────────────► 유료 출시 가능 (2-4주)
TRACK 3  콘텐츠 증량 (병행) ─────────► 유료 정당화
TRACK 2  리텐션/도파민 (코드) ───────► 듀오 경쟁력 (4-8주)
TRACK 5  웹사이트 ───────────────────► 전환율
TRACK 6  확장 v3+ (출시 후)
```

**권장 실행 순서**: TRACK 0 + 4 → 무료 베타 → 피드백 1주 → TRACK 1 + 3 → 유료 출시 → TRACK 2 + 5 → 리텐션 최적화 → TRACK 6.

---

## TRACK 0 — 출시 차단 해제 (무료 베타까지)
> 목표: 새 기능 없이, "지금 있는 앱"을 스토어에 올린다. 대부분 [운영], 코드는 소수.

### 0.1 [운영] 빌드 파이프라인 재실행
신규 l10n 키·`path_provider`·`purchases_flutter` 추가 후 stale 가능성. 순서 고정:
```bash
flutter clean && flutter pub get && flutter gen-l10n
flutter analyze            # 기대: No issues found!
flutter test               # 기대: 218 passed
flutter build appbundle --release --obfuscate \
  --split-debug-info=build/app/outputs/symbols
```
- **검증**: 위 4개 전부 통과. 실패 시 그 로그를 우선 처리(다른 트랙 진행 금지).

### 0.2 [운영] Cloud Function 배포 — 책 한 컷 활성화 (P0)
근거: [book_analysis_service.dart](lib/services/book_analysis_service.dart) endpoint 미배포 시 단어/번역 빈 값. `docs/store/cloud-function-deploy.md` 런북 존재.
```bash
cd functions/analyze_korean_text
# .env 의 DEEPL_API_KEY / URIMALSAEM_API_KEY 확인 (gitignored)
gcloud functions deploy analyze_korean_text \
  --gen2 --runtime=python312 --region=europe-west3 \
  --trigger-http --allow-unauthenticated --source=.
```
- 앱 기본 endpoint가 이미 `europe-west3-ko-lernen-app.cloudfunctions.net/analyze_korean_text`([main.dart:65](lib/main.dart))라 **배포만 하면 코드 수정 불필요**.
- **검증**: 실기기에서 한국어 교재 1장 촬영 → 단어 리스트 + 독일어 번역 + 뜻풀이가 채워지는지. 빈 값이면 endpoint/키 문제.
- ⚠️ **DeepL 키 재발급**(대화 평문 노출). 배포 후 즉시.
- 대안(배포 못 하면): 출시 카피에서 "자동 번역"을 "단어 추출 + 직접 단어장화"로 톤 다운하여 광고-실제 불일치 방지.

### 0.3 [운영] Firestore rules 배포
```bash
firebase deploy --only firestore:rules
```
- 근거: [firestore.rules](firestore.rules)는 SECURE하나 **배포돼야** 공유(`shared_packs`)·동기화(`users/{uid}`)가 동작.
- **검증**: 두 기기에서 친구코드 공유→수령 round-trip 1회.

### 0.4 [자산] 스토어 필수 이미지 (P0 — 없으면 등록 불가)
- feature graphic **1024×500** ×1
- 스크린샷 **8장** (가이드: `docs/store/screenshot-shotlist.md`)
- 권고 샷리스트: 인트로 게이트 / 홈(한옥) / 책 한 컷 결과 / 단어팩 보스 / 시나리오+퀘스트 / 한옥 성장 / 끝말잇기 / 통계
- **검증**: Play Console 그래픽 요구 규격(JPG/PNG, 24bit) 충족.

### 0.5 [운영] Play Console 등록
- Privacy URL: `https://hangul-sori.com/privacy.html` (이미 라이브)
- Data Safety: `docs/store/data-safety.md` 표 그대로 입력 (**인앱결제 항목 추가** — `purchases_flutter` 있음)
- 카테고리 Education / IARC 13+ / 타깃연령 13+
- AAB + native debug symbols 업로드 → Closed Testing 트랙 → 테스터 5-10명

### 0.6 [코드] 출시 전 소규모 정리 (반나절)
| 항목 | 파일 | 변경 |
|---|---|---|
| iOS 표시명 | `ios/Runner/Info.plist` | `CFBundleDisplayName` → `Hangul Sori` |
| 의존성 고정 | [pubspec.yaml](pubspec.yaml) | `intl: any` → 명시 버전(예 `^0.20.2`, flutter pin과 호환 확인) |
| 릴리스 노트 | `docs/store/listing-{de,en}.md` | v1.0 표기 → v2.0(책한컷·단어장·게임·시나리오 33) |
- **검증**: `flutter analyze` 재통과.

### 0.7 [운영] 실기기 QA 체크리스트 (Android 1대 필수) — 현재 **0회**
`docs/store/closed-testing-checklist-v2.md` §3 8단계 + 추가:
- [ ] 인트로→온보딩→홈 진입, 라이트모드(다크 폐지 확인)
- [ ] 책 한 컷: 촬영→OCR→**번역 채워짐**(0.2 검증)
- [ ] 단어팩 Learn→Quiz→Boss→다음팩 언락
- [ ] 게임 4종 + **TTS 실발화**(OS ko 음성 필요)
- [ ] 커스텀 단어장 4모드 + 사진 첨부
- [ ] 공유 코드 round-trip
- [ ] 알림 예약 → 실제 수신
- [ ] paywall 진입 시 크래시 없음(무료모드라 "상품없음" 정상)

**TRACK 0 완료 = 무료 베타 출시 가능.**

---

## TRACK 1 — 결제 상용화
> 목표: 첫 €1. 코드는 완성([premium_service.dart](lib/services/premium_service.dart))이므로 **운영·비즈니스**가 전부.

### 1.1 [운영] RevenueCat + Play 구독 (런북: `docs/store/subscription-setup-runbook.md`)
고정값(코드에 박힘): Entitlement `premium`, 패키지 Monthly(`o.monthly`), 앱 `com.sujinarin.ko_lernen_app`.
1. Play Console → 구독 상품 `premium_monthly` (€5.00/월, 또는 monetization-plan의 €4.99) 생성
2. RevenueCat 프로젝트 + Google 서비스계정 연결 + entitlement `premium` 매핑
3. 빌드: `flutter build appbundle --release --dart-define=RC_ANDROID_KEY=goog_xxx ...`
4. 샌드박스 라이선스 계정으로 실결제 1회 → entitlement 활성 확인
- ⚠️ AAB가 Play에 1회 업로드돼야 상품 활성. 서비스계정 권한 전파 최대 36h.
- **검증**: 샌드박스 구매 후 A2 단어팩([vocab_packs_screen.dart:86](lib/screens/vocab_packs_screen.dart))·A2 시나리오([scenario_player_screen.dart:69](lib/screens/scenario_player_screen.dart)) 잠금 해제.

### 1.2 [운영/결정] 가격·티어 확정
`docs/monetization-plan.md` 초안: 월 €4.99 / 연 €39.99 / 평생 €49.99 / 7일 체험.
- **결정 필요**: 연간·평생 SKU도 만들지(현재 코드는 monthly만 참조). 추가 시 [premium_service.dart](lib/services/premium_service.dart)·[paywall_screen.dart](lib/screens/paywall_screen.dart)에 패키지 분기 [코드] 소량 추가.

### 1.3 [운영] 비즈니스 리드타임 (가장 긴 항목)
사업자등록 / EUR 은행계좌 / 세무(VAT) / 약관·환불정책 법무 검토. → **이게 사실상 유료 출시 일정을 지배**. 병행 착수 권장.

### 1.4 [코드, 선택] Free/Plus 경계 정밀화
`docs/monetization-plan.md` §2 무료 한도(하루 10 SRS·문법 30·A1 시나리오·게임 1세션)가 실제 게이팅과 일치하는지 점검. 현재 게이팅 3곳([home_screen.dart:131](lib/screens/home_screen.dart), vocab_packs:86, scenario_player:69) 확인됨 — 나머지 한도는 미구현일 수 있으니 정책과 코드 대조 후 보완.

---

## TRACK 2 — 리텐션 / 도파민 (듀오링고 격차 해소)
> 목표: `docs/UIUX_DUOLINGO_GAP_AND_PLAN.md` P0 갭 해소. **전부 [코드]**, 자산 의존 최소.

### 2.1 홈 "선택 과부하" → 단일 다음-한-걸음 (P0)
- 현황(실측): [home_screen.dart](lib/screens/home_screen.dart)에 **19개 `pushNamed`** 분기 + 모듈 그리드.
- 설계: 최상단에 **"오늘 할 것" 단일 큰 CTA 카드** 1개(= SRS due 또는 다음 팩 또는 일일코스). 나머지 모듈은 접이식/하단 보조로 강등. due 카드 수는 이미 `Storage.todayGoalIds()`로 계산됨.
- 검증: 홈 첫 화면에서 시각적으로 1개 CTA가 지배. 탭 1회로 학습 시작.

### 2.2 학습 경로(스킬트리) 격상
- 현황: SkillPathRail이 하단 가로 1줄(문서 지적).
- 설계: 단어팩 61개 + 한옥 12단계를 세로 스크롤 "길"로 시각화(잠금/현재/완료 노드). 데이터는 [pack_progress_service.dart](lib/services/pack_progress_service.dart) + [hanok_stage_service.dart](lib/services/hanok_stage_service.dart)에 이미 존재 → **UI 위젯 신규**가 핵심.
- 검증: 사용자가 "내가 어디 있고 다음이 뭔지" 한눈에.

### 2.3 정답 순간 도파민 루프
- 현황: XP/스트릭 표시는 있으나 SFX 없음(TTS만), 정답 연출 약함.
- 설계: (a) 경량 SFX(정답/오답/콤보/레벨업) — 신규 `SoundService` + 짧은 오디오 에셋. (b) 정답 즉시 햅틱(`HapticFeedback`) + 점수 팝 + 콤보 카운터. quiz/boss/게임 정답 경로에 공통 훅.
- 검증: 정답 시 0.2s 내 청각+촉각+시각 피드백.

### 2.4 마스코트 반응형
- 현황: 자산 mascot 15종 존재, [mascot.dart](lib/widgets/sori/mascot.dart) emotion 매핑 있음. 그러나 호랑이=정적 hero.
- 설계: 정답/오답/연속정답/유휴에 따라 emotion 전환 + 작은 모션. 자산은 대부분 있으니 **트리거 로직** 추가.

### 2.5 첫 세션 마찰 제거
- 현황: 인트로→레벨선택→홈→카드선택해야 시작.
- 설계: 온보딩 직후 "60초 첫 레슨"을 바로 띄워 첫 정답 경험을 가입 전에 제공(듀오 패턴). 기존 vocab_pack/chosung 재사용.

---

## TRACK 3 — 콘텐츠 증량 (병행, 유료 정당화)
> 목표: 유료를 정당화할 볼륨. `tools/content_factory/` 인프라 활용. **§0: 손번역 금지, DeepL/큐레이션 + 인간 검수.**

### 3.1 단어 526 → 1,000+ (A2-B2 보강)
- 현황: A1:211/A2:140/B1:103/B2:72. 상위로 갈수록 얇음.
- 작업: `assets/data/korean_vocab.csv` 스키마(11컬럼) 유지하며 팩별 8-12단어로 증량. `pack_id`/`pack_order`/`is_review_boss` 규칙 준수.
- 검증: `test/data_integrity_test.dart`·`test/vocab_pack_test.dart` 통과(헤더·고유키·필드 빈값 검사).

### 3.2 시나리오 깊이 (평균 6.2줄 → 12+)
- 현황: 33개 204줄. 개수는 좋으나 교환 얕음.
- 작업: 기존 시나리오 대화 라인 증량 + 분기 응답. `culturalNote`/`grammarBlock` 스키마(`{title,body}`) 준수 — **`{ko,de,en}`로 쓰면 로드 실패**([scenario_loader.dart](lib/services/scenario_loader.dart) 회귀 이력, `test/scenario_loader_test.dart`).
- 검증: `test/data_integrity_test.dart` + 앱 시나리오 리스트 33개 정상 로드.

### 3.3 끝말잇기 독일어 번역 (~2,000개)
- 현황: 풀 2,453단어 중 독일어 일부만(대화 로그 ~69). 힌트 비어 보임.
- 작업: `assets/data/kkeunmari_pool.json` `german` 필드를 DeepL 배치로 채우고 인간 스팟체크. `cdce7c9` 커밋이 "미번역 힌트 숨김" 처리했으니 채우면 자동 노출.

### 3.4 콘텐츠 인간 검수 (출시 전 1회)
- 문법 자연스러움·존댓말 일관성·독일어 번역 품질. `docs/QUALITY_DIAGNOSIS_AND_UPDATE_PLAN.md` Phase 5(미완)와 동일.

---

## TRACK 4 — 안정성 / CI (신뢰)
> 목표: 218 테스트를 회귀 자동화 + 플래그십 무테스트 메우기.

### 4.1 [코드] CI에 test 추가
- 현황: [.github/workflows/ci.yml](.github/workflows/ci.yml) = analyze + build web만.
- 변경: `flutter test` 단계 추가(push/PR). 선택적으로 AAB 빌드 잡.
- 검증: PR에서 218 테스트 자동 실행.

### 4.2 [검증] 플래그십 테스트 보강
무커버 목록(인프라 에이전트 확인): OCR 흐름·결제·CloudFn HTTP·시나리오 게임플레이·TTS·공유팩·CSV/사진.
- 우선: (a) `book_analysis_service` HTTP 응답 파싱 단위테스트(mock JSON), (b) `premium_service` 게이팅 분기(키 없을 때 무료) 테스트, (c) `shared_pack_service` 코드 생성 엔트로피/충돌 테스트, (d) scenario quest 정답 판정 로직.
- 검증: 신규 테스트 그린 + 총 케이스 수 증가.

---

## TRACK 5 — 웹사이트 (`docs/index.html`, 전환율)
> 목표: "예쁘지만 증거 없음" → "신뢰+행동". 현황: 971줄, 디자인 양호, **스크린샷 0장**.

| # | 작업 | 변경 |
|---|---|---|
| 5.1 | 실제 스크린샷 6-8장 | `index.html:864-871` placeholder → 실제 `<img>` (TRACK 0.4 산출물 재사용) |
| 5.2 | 데모 GIF/짧은 영상 | 살아있는 한옥·정답 연출 30s 루프 (강점 시각화) |
| 5.3 | 기능 그리드 압축 | 큰 7 + mini 4 = 11개 → 핵심 4개 강조 + 나머지 접기(문서 권고) |
| 5.4 | 출시 시 CTA 교체 | `mailto:` → Play Store 링크(`index.html:616`) |
| 5.5 | OG 이미지 | `og:image`가 logo.png → 책한컷/한옥 대표 이미지로 |

---

## TRACK 6 — 확장 (출시 후, v3.0+)
- **영어권 콘텐츠**: `korean_vocab.csv`·`grammar.csv`에 `english`/`*_en` 컬럼 추가(526+88 번역). 현재 0.
- **AI 개인화 실제화**: 메모리 `project_commercialization_direction`의 배치 사전생성. 현재 [personalized_lesson_service.dart](lib/services/personalized_lesson_service.dart)는 로컬 휴리스틱 → Cloud 배치 콘텐츠 풀 + 동일 선택 알고리즘.
- **계(契) 커뮤니티**: jongga Phase 6-9, 현재 `gye_service.dart` 없음(0%). firestore.rules에 `gye/{gyeId}` deny 자리만 존재.
- **STT 발음 평가 / TOPIK 모드 / 원어민 음성**: `docs/FEATURE_ROADMAP_2026-06-02.md` Tier C.
- **다크모드 부활**(현재 `ThemeMode.light` 고정, [main.dart:160](lib/main.dart)) + hanok_stages dark 12장.

---

## 부록 A — "지금 당장 하면 좋은" 코드 작업 Top 5 (저비용·고효과)
1. **[코드] CI에 `flutter test` 추가** (4.1) — 5분, 회귀 안전망.
2. **[코드] iOS `CFBundleDisplayName` 수정** (0.6) — 1분, 스토어 정합성.
3. **[코드] `intl` 버전 고정** (0.6) — 1분, 빌드 리스크 제거.
4. **[코드] 홈 단일 CTA 카드** (2.1) — 반나절, 듀오 격차 최대 항목.
5. **[검증] premium 게이팅 + book_analysis 파싱 테스트** (4.2) — 반나절, 수익화/플래그십 안전.

## 부록 B — 의존성 주의 (실측)
- 콘텐츠 작업 시 스키마 엄수: scenarios `culturalNote/grammarBlock = {title,body}` (`{ko,de,en}` 금지 — 로드 실패 회귀 이력).
- l10n 신규 키는 `app_de.arb` + `app_en.arb` 양쪽(현재 600=600 parity) + `flutter gen-l10n` 재실행.
- `assets/illustrations/` 신규 PNG는 `pubspec.yaml` 등록 + errorBuilder 폴백 유지.

---

> 이 계획의 "코드 작업"은 모두 실재 확인된 파일/구조를 가리킨다. 단, TRACK 2의 UI 설계 세부(위젯 트리)는 구현 시 해당 화면을 다시 Read하고 확정할 것 — 코드는 변한다(§0).
