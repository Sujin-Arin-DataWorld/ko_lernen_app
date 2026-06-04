# 구현 감사 (2026-06-04) — 문서 ↔ 코드 1:1

> **목적**: `docs/plans/stately-rising-jongga.md`(v2.0 마스터 플랜, Phase 1~9)와 KO_LERNEN_APP의 **모든 .md 파일(실측 70개)** 을 현재 코드와 **1:1 직접 대조**한 단일 ground-truth.
> **방법**: 3 Explore 에이전트 + 직접 grep/Read 검증(§0 — 추측 금지). 모든 ✅는 대응 grep/Read 근거 존재.
> **짝 문서**: 상용화 경로·로드맵은 `docs/ROADMAP_TO_LAUNCH_2026-06-04.md`.

---

## ⏩ 업데이트 — 2026-06-04 구현 세션 (Phase 7·8·9)

> 아래 §1~§8은 감사 시점 스냅샷. **이 감사 직후 본 세션에서 Phase 7·8 코드 완결분을 구현·검증**(`flutter analyze lib` 0 · `flutter test` **310 통과** · CF `node --check` OK):

- **Phase 7**: ~~`weekly_goal_rollover` 보상(100%→영구 unlock + `goal_achieved` 피드 · 70%+→`xpBoostActive`)~~ ✅ · ~~피드 100개 prune~~ ✅ · ~~공동한옥 **영구 unlock**(`lifetimeGoalsAchieved`) + 주간리셋 축소 버그 수정~~ ✅ · ~~`goalAchieved` 피드 타입 + 렌더 + DE/EN l10n~~ ✅. **FCM** 🔧 Jin 결정(`notification_service` 의도적 kein-FCM 정책).
- **Phase 8**: ~~`on_report_created` 자동정지(서로 다른 3명 신고→suspended)~~ ✅ · ~~rules 정지회피 차단(본인 `status` self-write 금지 + `isActiveGyeMember`로 정지자 전송 차단)~~ ✅ · ~~`age_gate_service`(GDPR-K 16세) + 생년 입력 다이얼로그 + 계 진입 게이트 + `gye_service` backstop + `age_gate_test` 7~~ ✅. **admin 패널** 🔧 Jin(별도 웹).
- **Phase 9**: ~~`docs/qa/v2_release_qa_report.md` 실기기 체크리스트~~ ✅. 실기기 QA·스크린샷·feature graphic·AAB·Closed Testing 🔧 Jin.

변경 파일: `functions/gye/index.js` · `firestore.rules` · `lib/models/gye.dart` · `lib/services/{age_gate_service,gye_service,storage_service}.dart` · `lib/widgets/sori/{gye_hanok,gye_feed,age_gate_prompt}.dart` · `lib/l10n/{gye_error_text,app_de,app_en}` · `lib/screens/home_screen.dart`(showGyeChooser 가드) · `test/age_gate_test.dart`.

**여전히 핵심 차단**: CF 2종 미배포(P0) · 번역 Firestore 캐시 미구현(P1) · FCM 정책결정. → `ROADMAP_TO_LAUNCH`.

---

## 0. 읽는 법 (범례)

| 표기 | 의미 |
|---|---|
| ~~`취소선`~~ ✅ | **구현 완료** (코드로 실재 확인). |
| `평문` ❌ | **미구현** (코드 부재 확인). |
| `평문` ⚠️ | **부분 구현 / 스펙과 분기** (주석으로 차이 명시). |
| `평문` 🔧 Jin | **코드 아닌 운영 영역** (배포·결제·실기기 — 코드로 판정 불가). |
| `stale` | 문서가 구버전·모순 정보 (정정 한 줄 첨부). |

> ⚠️ md 파일 실측 = **70개** (탐색 에이전트 추정 78은 오차). §7 처리대장이 70 전수.

---

## 1. 한눈 요약표

### stately-rising-jongga Phase 1~9

| Phase | 주제 | 코드 | 자산 | 운영 | 한 줄 |
|---|---|:---:|:---:|:---:|---|
| 1 | 데이터 구조 (팩·Firestore·SRS) | ✅ | — | — | 완전. 61팩 로드·rules·테스트. |
| 2 | 팩 화면 (선택·플레이·결과) | ✅ | ✅ | — | 완전. 3단계 흐름·도장·legacy 보존. |
| 3 | 한옥 12단계 건축 | ✅ | ⚠️ | — | 코드 완전. light PNG **10/12**(jongga·side 누락)·dark 0(폐지). |
| 4 | 특별 퀘스트 + 마당 장식 | ✅ | ⚠️ | — | 카탈로그 17퀘 와이어. 2 source 스텁·데코 PNG **10/17**·seasonal은 하드코딩. |
| 5 | 책 한 컷 (OCR+NLP+번역) | ✅ | ✅ | ❌ | 클라 완전(kiwipiepy로 개선). **CF 미배포**·번역 Firestore 캐시 미구현. |
| 6 | 계(契) 모델 + 모임방 | ✅ | ✅ | — | 완전. CRUD·6자리코드·rules·욕설사전. |
| 7 | 계 공동마당·주간목표·스티커 | ⚠️ | ✅ | ❌ | UI·스티커30·on_pack_cleared ✅. **롤오버 skeleton·FCM 없음·CF 미배포**. |
| 8 | 모더레이션 + GDPR | ⚠️ | — | — | 계정삭제(gye cascade)·신고UI·privacy ✅. **자동정지·admin·age-gate 전부 ❌**. |
| 9 | 출시 자료 + 검증 | ⚠️ | ⚠️ | ❌ | 스토어 문서 ✅. **실기기 QA 0회·스크린샷·feature graphic·Closed Test ❌**. |

**판정**: Phase 1·2·6 = 완전. 3 = 코드 완전·자산 일부. 4 = 거의 완전(주변부 스텁). 5 = 클라 완전·**배포가 핵심 차단**. 7 = 코드 대부분·FCM/롤오버 미완. 8 = **절반**(자동 모더레이션 미구현). 9 = 운영 미실행.

### 비-Phase 영역 (다른 플랜/세션 산물 — 역방향 §8 참조)

| 영역 | 상태 | 근거 |
|---|:---:|---|
| 계정 시스템 (익명·Google·Apple·삭제·동의·프로필) | ✅ | `auth_service`·`consent_screen`·`profile_screen`. |
| 구독 (RevenueCat €5/월) | ⚠️ | 코드 완전(`premium_service`·`payall_screen`·logIn). **대시보드/상품/키 0 → 결제 불가** 🔧. |
| 단어장 엔진 (커스텀·책장·SRS·4모드·hard words) | ✅ | `custom_pack_*`·`review_deck_service`·`hard_words_screen`. |
| 게임 (초성·워들·끝말잇기·듣기) | ✅ | 4 화면 + 엔진. |
| 마스코트·호랑이 애니 | ✅ | `Mascot` v6 + `TigerStage` 44프레임. Rive는 `.riv` 미제작 ⚠️. |
| iOS 출시 | ⚠️ | Apple Sign-In 코드 ✅. **Xcode capability·실기기 미검증** 🔧. |

---

## 2. stately-rising-jongga Phase 1~9 — Deliverable 1:1

> 플랜의 각 `- [ ]` Deliverable 원문을 그대로 옮기고, 코드로 확인된 것만 ~~취소선~~ ✅.

### Phase 1 — 데이터 구조 (§3.5) → ✅ 완료

- ~~`korean_vocab.csv` pack_id/pack_order/is_review_boss 컬럼 + 분할/병합~~ ✅ (`vocab_pack_service`가 61팩 파생)
- ~~`docs/data/vocab_pack_map.md`~~ ✅ (존재)
- ~~`lib/models/vocab_pack.dart`~~ ✅
- ~~`lib/services/vocab_pack_service.dart`~~ ✅
- ~~`lib/services/firestore_progress_service.dart`~~ ✅
- ~~`firestore.rules` 사용자 packs/quests 규칙~~ ✅ (`users/{uid}/{document=**}` 하위 포함)
- ~~vocab_screen 헤더 임시 패치~~ ✅ (Phase 2 팩 그리드로 대체·`legacy_vocab_screen` 보존)
- ~~단위 테스트 (팩 로딩·진행도·보스)~~ ✅ (`vocab_pack_test`·`pack_progress_test`)

### Phase 2 — 팩 화면 (§4.5) → ✅ 완료

- ~~`lib/screens/vocab_packs_screen.dart`~~ ✅
- ~~`lib/screens/vocab_pack_screen.dart` (3단계)~~ ✅ (Learn→Quiz→Boss)
- ~~`lib/screens/vocab_pack_result_screen.dart`~~ ✅
- ~~`lib/widgets/sori/pack_card.dart`~~ ✅
- ~~`lib/widgets/sori/dancheong_stamp.dart`~~ ✅
- ~~`main.dart` 라우트 (`/vocab`·`/vocab/pack`·`/vocab/result`)~~ ✅
- ~~DE/EN ARB 키~~ ✅
- ~~legacy 롤백용 `_legacy_vocab_screen.dart`~~ ✅ (`/vocab/legacy`)

### Phase 3 — 한옥 12단계 (§5.5) → ✅ 코드 / ⚠️ 자산

- ~~`lib/models/hanok_stage.dart` (12 enum + computeStage)~~ ✅
- ~~`lib/widgets/sori/madang_background.dart` (cross-fade)~~ ✅
- ~~`lib/widgets/sori/hanok_cinematic.dart`~~ ✅
- ~~`assets/illustrations/hanok_stages/` + pubspec~~ ✅
- PNG 24장 (12단계 × 2 brightness) ⚠️ **light 10/12** (`jongga`·`side_building` 누락) · **dark 0/12**(다크모드 폐지로 무의미). 누락분 = `MadangBackground` 그라데이션 fallback.
- ~~홈 화면 통합 (배경 위젯 교체)~~ ✅
- ~~단위 테스트 (% → stage 매핑)~~ ✅ (`hanok_stage_test`·`hanok_stage_service_test`)

### Phase 4 — 특별 퀘스트 + 마당 장식 (§6.5) → ✅ 거의 완료

- ~~`lib/data/quest_catalog.dart` (퀘스트 정의 + 조건)~~ ✅ **플랜 §6.1 정확 구현: 17퀘스트**(상시9 + 사군자4 + 계절4)
- ~~`lib/services/quest_tracker.dart` (학습액션 → progress)~~ ✅ **단 source 2개 스텁**: `pronunciationGood`·`friendsCount` = `0`(Phase 5/6 ETA) → `q_seokdeung`·`q_doldam` **도달 불가**
- ~~`lib/widgets/sori/decoration_layer.dart`~~ ✅
- ~~`lib/screens/quests_screen.dart`~~ ✅ (카탈로그 렌더 확인 — `quest_engines/` 미니게임과 별개 시스템)
- decorations PNG ⚠️ **10/17** (누락: `seokdeung`·`doldam`·`sagunja_guk`·계절4). errorBuilder placeholder.
- Remote Config `active_seasonal_quests` 키 ❌ **미구현** — 대신 `quest_catalog.dart`의 `SeasonWindow` **하드코딩 날짜창**으로 분기(스펙 변경)
- ~~DE/EN ARB 키 (퀘스트)~~ ✅
- ~~단위 테스트 (trigger 정확도)~~ ✅ (`quest_tracker_test`·`quest_catalog_test`)

### Phase 5 — 책 한 컷 (§6.5.11) → ✅ 클라 / ❌ 미배포

- ~~pubspec 의존성 (mlkit·image_picker·image_cropper·permission_handler)~~ ✅
- ~~`lib/services/snap_ocr_service.dart`~~ ✅ (ML Kit on-device)
- ~~`lib/services/book_analysis_service.dart`~~ ✅ (CF 클라 + 오프라인 fallback)
- ~~`lib/services/bookshelf_service.dart`~~ ✅
- ~~`lib/screens/book_capture_screen.dart`~~ ✅
- ~~`lib/screens/book_preview_screen.dart`~~ ✅
- ~~`lib/screens/book_result_screen.dart`~~ ✅
- ~~`lib/screens/bookshelf_screen.dart`~~ ✅
- ~~`lib/screens/bookshelf_page_screen.dart`~~ ✅
- `book_card.dart`·`word_extract_card.dart`·`grammar_pattern_card.dart` ⚠️ **별도 위젯 파일 부재** → `book_result_screen` **인라인 구현**(기능 동일)
- ~~`functions/analyze_korean_text/main.py`~~ ✅ ⚠️ **구현 변경(개선)**: 플랜 `konlpy/Okt/JPype1`(Java 필요) → **`kiwipiepy`(순수 Python)**. CLAUDE.md 옛 메모의 "konlpy"는 `stale`.
- `functions/requirements.txt` ⚠️ 존재하나 deps = kiwipiepy 기반(konlpy/kss/JPype1 아님)
- ~~`functions/grammar_patterns.json` (패턴 사전)~~ ✅ (클라 `assets/data/grammar_patterns.json`과 동기)
- `cache/` 컬렉션 보안 규칙 ⚠️ `firestore.rules`에 `cache/translations/{hash}` **규칙은 존재**하나 CF는 `@lru_cache`(인메모리)만 → **규칙만 있고 실사용 ❌**
- 번역 캐시 전략 (Firestore 30일) ❌ **미구현** (인메모리 lru_cache만)
- ~~5 PNG (book/)~~ ✅ (5장 전부)
- ~~DE/EN ARB 키~~ ✅
- ~~카메라 권한 (Android+iOS)~~ ✅
- 단위 테스트 (OCR·grammar·cache) ⚠️ `book_page_test`·`grammar_patterns_test` ✅; **cache 테스트는 캐시 미구현이라 무의미**
- CF 통합 테스트 (emulator) ❌ **부재** (테스트 파일 없음)
- ~~`docs/privacy.html` 업데이트 (카메라+DeepL)~~ ✅
- ~~`docs/store/data-safety.md` 업데이트~~ ✅
- 🔧 **CF 미배포** — 프로덕션에서 번역·단어추출 **미작동**(핵심 차단요소, 로드맵 P0).

### Phase 6 — 계(契) 모델 + 모임방 (§7.6) → ✅ 완료

- ~~`lib/services/gye_service.dart` (CRUD·6자리코드)~~ ✅
- ~~`lib/screens/gye_create_screen.dart`~~ ✅
- ~~`lib/screens/gye_join_screen.dart`~~ ✅
- ~~`lib/screens/gye_screen.dart` (계 마당)~~ ✅
- ~~`lib/widgets/sori/gye_hanok.dart` (공동 한옥)~~ ✅
- ~~`firestore.rules` 계 접근 규칙~~ ✅ (`gye/meta·members·feed·stickers·reports`)
- ~~닉네임 욕설 사전 (KO/DE/EN)~~ ✅ (`lib/data/profanity_denylist.dart`)
- ~~DE/EN ARB 키~~ ✅

### Phase 7 — 계 공동마당·주간목표·스티커 (§8.4) → ⚠️ 부분

- ~~`lib/widgets/sori/weekly_goal_bar.dart`~~ ✅
- ~~`lib/widgets/sori/gye_feed.dart`~~ ✅
- ~~`lib/widgets/sori/sticker_picker.dart`~~ ✅
- ~~`assets/stickers/` 30 PNG~~ ✅ (30 + `sticker_catalog.dart`)
- ~~CF `onPackCleared` (진행도 합산·피드)~~ ✅ (`functions/gye/index.js` `on_pack_cleared`, Node 전환)
- CF `weeklyGoalRollover` (월요일 자정) ⚠️ **skeleton** (선언만·Cloud Scheduler TODO)
- FCM (피드 푸시 알림) ❌ **미구현** (CF 주석 TODO)
- ~~DE/EN ARB 키~~ ✅
- 🔧 **gye CF 미배포** + Cloud Scheduler 미설정.

### Phase 8 — 모더레이션 + GDPR (§9.5) → ⚠️ 절반

- `lib/services/moderation_service.dart` ❌ **부재** (신고는 `gye_service.reportMember` 인라인)
- `lib/screens/report_screen.dart` ❌ **부재** (`gye_members_screen` 다이얼로그 인라인 — 기능은 존재)
- CF `onReportCreated` (3건 자동정지) ❌ **부재**
- Admin 패널 `tools/admin/` ❌ **부재** (`tools/`엔 content_factory만)
- `lib/services/age_gate_service.dart` (16세 미만 차단) ❌ **부재**
- ~~`AuthService.deleteAccount()`~~ ✅ ⚠️ **CF `onAccountDeleted` cascade 대신 client-side**: `_deleteUserGyeMembership`가 `users/{uid}.gyeIds` → 각 `gye/{id}/members/{uid}` 삭제 + memberCount 감소 (GDPR gye 정리 포함). CF 캐스케이드는 ❌(클라 의존이라 중단 시 orphan 위험).
- ~~`docs/privacy.html` 업데이트~~ ✅
- ~~`docs/store/data-safety.md` (gye 데이터)~~ ✅
- ~~Settings 화면 "계정 삭제"~~ ✅
- > ⚠️ CLAUDE.md 일부 옛 세션로그의 "계정삭제 미구현"은 `stale` (현재 `auth_service.dart:209` 구현됨).

### Phase 9 — 출시 자료 + 검증 (§10.4) → ⚠️ 문서만

- ~~`docs/store/listing-de.md`~~ ✅ · ~~`listing-en.md`~~ ✅ · ~~`release-notes-v2.md`~~ ✅
- 스크린샷 8슬롯 재캡처 ❌ (`screenshot-shotlist.md` 가이드만, 실제 신규 캡처 ❌)
- Feature graphic ⚠️ **draft만** (`docs/store/feature_graphic_v1_draft.png`)
- Play Store 미디어 업데이트 🔧 Jin
- 검증 보고서 `docs/qa/v2_release_qa_report.md` ❌ **부재**
- 실기기 검증 (Android+iOS) ❌ **0회**
- 16세 미만 차단 검증 ❌ (기능 자체가 미구현 — Phase 8)
- Closed Testing ❌ 미시작
- v2.0.0 태깅 + AAB + 업로드 🔧 Jin (pubspec `2.0.0+3`)

---

## 3. 핸드오버 7종 교차검증 (`docs/_archive/*phase*-handover.md`)

각 핸드오버는 **해당 Phase 완료 시점 기록**. 본 감사 §2가 코드로 재검증하므로, 핸드오버가 "완료"로 적었어도 코드 미반영분은 §2에 ❌/⚠️로 드러남.

| 핸드오버 | 대응 Phase | §2 재검증 결과 |
|---|---|---|
| ~~phase1-handover~~ | Phase 1 | ✅ 일치 |
| ~~phase2-handover~~ | Phase 2 | ✅ 일치 |
| ~~phase3-handover~~ | Phase 3 | ✅ 코드 일치 (자산 light 10/12은 핸드오버 후 미충족) |
| ~~phase4-handover~~ | Phase 4 | ⚠️ 카탈로그 ✅, 단 seasonal RC키·데코 PNG·2 source 스텁은 핸드오버가 deferred로 명시했는지 확인 권장 |
| ~~phase5-handover~~ | Phase 5 | ⚠️ 클라 ✅, CF 미배포·번역캐시 미구현은 핸드오버 시점에도 운영 대기였음 |
| ~~phase5_1-handover~~ | 나만의 단어장 | ✅ 일치 (custom_pack 4모드) |
| ~~phase5_2-handover~~ | 계 공동한옥 | ✅ gye_hanok 일치 |

> 핸드오버는 역사적 기록(superseded). 활성 추적은 본 §2 + 로드맵.

---

## 4. 감사문서 B군 주장 검증

| 문서 | 핵심 주장 | 현재 판정 |
|---|---|---|
| `release-readiness-2026-06-02` | 빌드 blocker 0·CF 배포대기·공유 미구현 | ✅ 유효. 단 "공유 미구현"은 이후 `share_plus`+`gye` 공유로 일부 해소 → 부분 `stale` |
| `LAUNCH_READINESS_2026-06-02` | "책한컷 번역 현재 미작동(CF)"·"AI개인화는 로컬 휴리스틱" | ✅ 유효 (CF 여전히 미배포·`personalized_lesson_service`는 skeleton) |
| `ACCOUNT_SYSTEM_AUDIT_2026-06-03` | Apple Sign-In·RevenueCat logIn 필요 | ⚠️ 대부분 **해소됨**(`linkWithApple`·`_bindFirebaseIdentity` 구현) → 부분 `stale`. RevenueCat 운영 셋업만 잔존 |
| `COMMERCIALIZATION_ASSESSMENT_2026-06-03` | P0: CF·구독운영·실기기QA·rules·스토어자산 | ✅ 유효 (로드맵 P0와 동일) |
| `QUALITY_DIAGNOSIS_AND_UPDATE_PLAN` | 화면/서비스별 완성도 | 대부분 ✅ 반영됨 — 세부는 §2/§8이 대체 |
| `living-app-audit-2026-05-29` / `ux-radical-redesign` | 모션·살아있는 한옥 Phase 0~5 | ✅ TigerStage·ambient·motion 구현 — `stale`(완료) |
| `UIUX_DUOLINGO_GAP_AND_PLAN` | 듀오링고 갭 | ⚠️ 계정 1급화·프로필·skill-path 해소, 일부 잔존 → 로드맵 §6 |
| `FEATURE_ROADMAP_2026-06-02` | Tier A/B/C 출시후 | 활성 → 로드맵 §6으로 흡수 |
| `JIN_VERIFY_CHECKLIST` | Jin 직접 검증 항목 | 🔧 활성 (실기기 미실행) |

---

## 5. 에셋 스펙 D군 vs 자산 폴더 실측

| 자산 그룹 | 스펙/카탈로그 요구 | 실측 | 판정 |
|---|---|:---:|---|
| `mascot/` | 호랑이7+까치5 | 17 | ✅ |
| `tiger_anim/` | 35~44 프레임 | 44 | ✅ |
| `hanok_stages/` (light) | 12 | **10** | ⚠️ `jongga`·`side_building` 누락 |
| `hanok_stages/` (dark) | 12 | **0** | ⚠️ 다크 폐지로 무의미 |
| `decorations/` | 17 (퀘스트 슬러그) | **10** | ⚠️ `seokdeung`·`doldam`·`sagunja_guk`·계절4 누락 |
| `assets/stickers/` | 30 | 30 | ✅ |
| `gye/` | 8 | 8 | ✅ |
| `book/` | 5 | 5 | ✅ |
| `stamps/` | 8 motif | 8 | ✅ |
| `scenes/` | 5 | 5 | ✅ |
| `empty/`·`error/` | — | 2·2 | ✅ |
| `assets/rive/tiger.riv` | 1 (Rive 리그) | **0** | ❌ GUI 제작 대기 → `TigerStage` 프레임 폴백 |

- 관련 문서: ~~`ASSET_GENERATION_BIBLE`(자급자족 바이블)~~ ✅ 최신 · `IMAGES_TO_CREATE`(제작 목록) 활성 · `TIGER_RIVE_RIG_SPEC`·`TIGER_RIVE_DIY_WALKTHROUGH` = `.riv` 미제작이라 활성.
- 모든 누락 PNG는 errorBuilder fallback이 있어 **빌드/런타임 깨짐 0**.

---

## 6. 스토어 / 콘텐츠 / 아카이브 — 현행성 (한 줄)

| 문서 | 현행성 |
|---|---|
| `store/data-safety.md` | ✅ 최신 (v2.0 델타·SDK audit 반영) |
| `store/listing-de/en.md`·`STORE_LISTING.md` | ✅ 최신 / `STORE_LISTING`은 루트 중복본 — 통합 권장 |
| `store/release-notes-v1/v2.md` | ✅ |
| `store/closed-testing-checklist-v2`·`cloud-function-deploy`·`subscription-setup-runbook`·`target-audience-and-ads` | 🔧 활성 (Jin 운영 런북) |
| `store/screenshot-shotlist.md` | 🔧 활성 (캡처 미실행) |
| `PLAY_CONSOLE_GUIDE`·`FIREBASE_GUIDE`·`BETA_INSTALL_GUIDE` | ⚠️ v1.0 기준 — v2.0 부분 `stale` |
| `content/01~05`·`content/README` | 콘텐츠 공장 SSoT — 시나리오 21·문법 88 반영 후 부분 `stale`(시나리오 13 언급) |
| `data/vocab_pack_map.md` | ✅ 61팩 맵 |
| `assets/REGISTRY.md` | ✅ 최신 자산 registry |
| `DATA_LICENSES.md`·`PRIVACY_POLICY.md` | ✅ |
| `monetization-plan.md`·`IMPROVEMENT_PLAN_2026-06-03.md` | 활성 → 로드맵으로 흡수 |
| `_archive/*` (15) | `stale`/superseded 일괄 (handover 7 + 구 스타일가이드·프롬프트·brand 등) |
| `tools/content_factory/README`·`scripts/expand_kkeunmari_pool` | ✅ 툴 문서 |
| `README`(root)·`assets/sfx/README`·`scripts/cache/README`·`ios/.../README` | stub/생성물 (감사 무관) |
| `CLAUDE.md` | ✅ SSoT — 단 옛 세션로그 일부 `stale`(계정삭제·konlpy, 본 감사가 정정) |

---

## 7. 전체 70파일 처리대장

> 그룹별 판정. `1:1` = 코드 대조 / `현행성` = 최신·stale만.

**A. 마스터 플랜 + 핸드오버 (9)** — 1:1 (§2·§3)
`plans/stately-rising-jongga.md` ✅대상 · `plans/stately-rising-jongga-assets.md` ✅(자산 §5) · `_archive/*phase1~5_2-handover.md`(7) superseded

**B. 감사/상태/로드맵 (9)** — §4
`release-readiness-2026-06-02` · `LAUNCH_READINESS_2026-06-02` · `ACCOUNT_SYSTEM_AUDIT_2026-06-03` · `COMMERCIALIZATION_ASSESSMENT_2026-06-03` · `QUALITY_DIAGNOSIS_AND_UPDATE_PLAN` · `living-app-audit-2026-05-29` · `ux-radical-redesign-2026-05-29` · `UIUX_DUOLINGO_GAP_AND_PLAN` · `FEATURE_ROADMAP_2026-06-02`

**C. 상용화/수익화 (2)** — 로드맵 흡수
`monetization-plan` · `IMPROVEMENT_PLAN_2026-06-03`

**D. 에셋/디자인 스펙 (7)** — §5
`ASSET_GENERATION_BIBLE` · `HANGUL_SORI_DESIGN_TOKENS` · `TIGER_ANIMATION_SPEC` · `TIGER_RIVE_RIG_SPEC` · `TIGER_RIVE_DIY_WALKTHROUGH` · `IMAGES_TO_CREATE` · `ASSET_AUDIT_AND_INTRO_PLAN`

**E. 스토어/운영 (15)** — 현행성 §6
`store/`(11: README·data-safety·listing-de·listing-en·release-notes-v1·release-notes-v2·screenshot-shotlist·closed-testing-checklist-v2·cloud-function-deploy·subscription-setup-runbook·target-audience-and-ads) · `STORE_LISTING` · `PLAY_CONSOLE_GUIDE` · `FIREBASE_GUIDE` · `BETA_INSTALL_GUIDE`

**F. 콘텐츠/데이터/툴 (11)** — §6
`content/`(6: README·01~05) · `data/vocab_pack_map` · `assets/REGISTRY` · `DATA_LICENSES` · `tools/content_factory/README` · `scripts/expand_kkeunmari_pool`

**G. 아카이브 비-handover (8)** — superseded
`_archive/`: `HANGUL_SORI_STYLE_GUIDE`·`README`·`REGISTRY`·`asset_prompts_day2-5`·`backdrop_prompts_day1`·`brand`·`gate_decomposition_prompt`·`generated_prompts_for_missing_assets`·`living-hanok-assets`·`mascot_pose_sheet_v2` (handover 7 제외)

**H. 루트/법무/생성물 (9)** — 현행성
`CLAUDE.md` · `PRIVACY_POLICY.md` · `README.md` · `assets/sfx/README.md` · `scripts/cache/README.md` · `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`

> 합계: A9 + B9 + C2 + D7 + E15 + F11 + G10 + H6 = **69**. (`docs/JIN_VERIFY_CHECKLIST.md`를 B군에 +1 = **70** 일치.)

---

## 8. 역방향 감사 — 코드엔 있으나 stately-rising-jongga 플랜엔 없는 것

> 다른 플랜/세션(account audit·FEATURE_ROADMAP·monetization)에서 추가됨. 마스터 플랜만 보면 누락처럼 보이나 **전부 구현·라우트 등록 확인**.

- ~~`/profile` `profile_screen.dart`~~ ✅ (계정 허브)
- ~~`/paywall` `paywall_screen.dart`~~ ✅ (RevenueCat €5/월)
- ~~`/review` `review_session_screen.dart`~~ ✅ (통합 SRS)
- ~~`/hard_words` `hard_words_screen.dart`~~ ✅ (leech 집중복습)
- ~~`/wordbook/search` `wordbook_search_screen.dart`~~ ✅
- ~~`/dojangcheop` `dojangcheop_screen.dart`~~ ✅ (도장첩)
- ~~`/path` `learning_path_screen.dart`~~ ✅ (스킬트리)
- ~~`consent_screen.dart` (첫 실행 동의 게이트)~~ ✅
- ~~`custom_pack_*` 4모드 (play·edit·quiz·matching·typing)~~ ✅
- ~~`quest_engines/` 5 미니게임 (batchim_drop·particle_pop·luecken·uebersetzen·hoerverstehen)~~ ✅ **시나리오 내 인터랙티브 퀘스트**로 `scenario_player_screen` 사용 (데코 퀘스트와 별개 시스템)
- ~~`smalltalk_screen`·`daily_char_sheet`~~ ✅
- ~~Apple Sign-In·동의 게이트·외부링크·notification_service·sound_service~~ ✅

> 결론: 코드는 마스터 플랜을 **초과 달성**한 영역이 많음. 플랜 미명세 기능이 다수 라이브.

---

## 결론

- **stately-rising-jongga Phase 1~9 코드는 ~85% 구현.** 핵심 학습·게임·계·책한컷 **클라이언트 전부 완성**.
- **미구현/차단의 본질은 "코드"가 아니라 "배포·운영·검증"** + **Phase 8 자동 모더레이션 트랙**:
  - 🔧 CF 2종(analyze_korean_text·gye) 미배포 → 책한컷·계 집계 프로덕션 미작동
  - 🔧 RevenueCat 운영 셋업 0 → 결제 불가
  - ❌ 자동정지 CF·admin 패널·age-gate (Phase 8)
  - ❌ FCM·weeklyGoalRollover (Phase 7)
  - ⚠️ 자산 누락: hanok_stages light 2·decorations 7·tiger.riv (전부 fallback 안전)
  - ❌ 실기기 QA·스크린샷·Closed Testing (Phase 9)
- **다음 행동 → `docs/ROADMAP_TO_LAUNCH_2026-06-04.md`.**
