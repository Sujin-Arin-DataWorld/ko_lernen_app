# 📚 docs/ 파일 감사 & 정리 계획 (2026-06-04)

> **목표**: 50+ md 파일을 구현 상태별로 분류 → 현행 문서/폐지 후보 명시  
> **방법**: IMPLEMENTATION_AUDIT_2026-06-04.md 기준 + 실제 코드 상태 반영  
> **스냅샷**: 2026-06-04 17:00 (Phase 7·8·9 완결 직후)

---

## 📋 카테고리 1 — 현행 핵심 문서 (삭제 금지)

> **이 그룹만 유지하고 나머지는 정리 또는 archive 이동 권고**

| 파일 | 역할 | 상태 | 보관처 |
|---|---|:---:|:---:|
| `ASSET_GENERATION_BIBLE.md` | 🖼️ 모든 이미지 생성의 마스터 | ✅ 최종 | 루트 |
| `IMAGES_TO_CREATE.md` | 📝 무엇을 만들지 + 우선순위 | ✅ 최신 | 루트 |
| `IMPLEMENTATION_AUDIT_2026-06-04.md` | 🔍 Code ↔ Doc 1:1 검증 | ✅ 최종 | 루트 |
| `ROADMAP_TO_LAUNCH_2026-06-04.md` | 🚀 출시 필수·선택·P0 항목 | ✅ 최종 | 루트 |
| `HANGUL_SORI_DESIGN_TOKENS.md` | 🎨 UI 토큰 (spacing/color/motion) | ✅ 최신 | 루트 |
| `assets/REGISTRY.md` | 🎯 "어떤 PNG가 어느 코드에" | ✅ 최신 | `assets/` |
| `plans/stately-rising-jongga.md` | 📐 v2.0 마스터 플랜 (Phase 1~9) | ✅ 완결 | `plans/` |
| `plans/stately-rising-jongga-assets.md` | 🖼️ 낱장 95장 개별 프롬프트 부록 | ✅ 완결 | `plans/` |

---

## 📋 카테고리 2 — 부분 구현 / 선택적 유지

> **아직 진행 중이거나 특정 주제에 깊이 있는 문서들**

| 파일 | 역할 | 상태 | 권고 |
|---|---|:---:|---|
| `FEATURE_ROADMAP_2026-06-02.md` | 🔮 장기 로드맵 (v2.0·v3.0 방향) | ⚠️ 부분 실현 | ✅ 유지 (향후 계획용) |
| `ACCOUNT_SYSTEM_AUDIT_2026-06-03.md` | 👤 계정시스템 전수 진단 | ✅ 완료 | ✅ 유지 (감사 기록) |
| `COMMERCIALIZATION_ASSESSMENT_2026-06-03.md` | 💰 상용화 방향 (구독·수익화) | ✅ 진단 | ✅ 유지 (경영 기록) |
| `IMPROVEMENT_PLAN_2026-06-03.md` | 📊 성능·안정성 개선 plan | ⚠️ 부분 | ✅ 유지 (향후 실행용) |
| `data/vocab_pack_map.md` | 📖 61팩 단어 맵 (참고용) | ✅ 최신 | ✅ 유지 (학습 콘텐츠 맵) |
| `TIGER_ANIMATION_SPEC.md` | 🐯 호랑이 프레임 애니 명세 | ✅ 완결 | ✅ 유지 (기술 명세) |
| `TIGER_RIVE_RIG_SPEC.md` | 🐯 호랑이 Rive 리깅 명세 | ⚠️ spec만 | ✅ 유지 (외주용) |
| `monetization-plan.md` | 💳 수익화 플랜 (A/B 테스트·가격 정책) | ⚠️ 스펙 | ✅ 유지 (운영용) |
| `release-readiness-2026-06-02.md` | ✅ 릴리즈 준비도 진단 (v2.0 출시 직전) | ✅ 완료 | 📦 ARCHIVE (히스토리) |
| `LAUNCH_READINESS_2026-06-02.md` | 🎯 출시 자료 체크리스트 | ✅ 완료 | 📦 ARCHIVE (히스토리) |
| `JIN_VERIFY_CHECKLIST.md` | ✅ Jin 실기기 검증 항목 | ✅ 완료 | 📦 ARCHIVE (히스토리) |
| `QUALITY_DIAGNOSIS_AND_UPDATE_PLAN.md` | 🔍 v1.0.0 품질 진단 | ✅ 완료 | 📦 ARCHIVE (히스토리) |

---

## 📋 카테고리 3 — 출시 관련 (운영 문서)

> **Play Console·App Store·내부테스트 준비 문서들. 정기 갱신 필요.**

| 파일 | 역할 | 상태 | 권고 |
|---|---|:---:|---|
| `store/README.md` | 📋 스토어 제출 pre-flight 체크리스트 | ✅ 현행 | ✅ 유지 |
| `store/data-safety.md` | 🔒 Privacy·Data Safety 양식 | ✅ 최신 | ✅ 유지 |
| `store/listing-de.md` | 🇩🇪 독일어 스토어 설명 | ✅ 최신 | ✅ 유지 |
| `store/listing-en.md` | 🇬🇧 영어 스토어 설명 | ✅ 최신 | ✅ 유지 |
| `store/release-notes-v1.md` | 📝 v1.0.0 릴리즈 노트 | ✅ 완료 | 📦 ARCHIVE (릴리스 기록) |
| `store/release-notes-v2.md` | 📝 v2.0.0 릴리즈 노트 | ✅ 완료 | ✅ 유지 (다음 배포용) |
| `store/screenshot-shotlist.md` | 📸 스크린샷 8슬롯 가이드 | ✅ 규격 | ✅ 유지 |
| `store/closed-testing-checklist-v2.md` | ✅ 내부테스트 체크리스트 | ✅ 완료 | ✅ 유지 (배포용) |
| `store/cloud-function-deploy.md` | 🚀 CF 배포 런북 | ✅ 가이드 | ✅ 유지 (운영용) |
| `store/subscription-setup-runbook.md` | 💳 RevenueCat 셋업 가이드 | ✅ 가이드 | ✅ 유지 (운영용) |
| `store/target-audience-and-ads.md` | 👥 타겟 연령·광고 정책 | ✅ 완료 | ✅ 유지 |

---

## 📋 카테고리 4 — 콘텐츠 계획 (게임/시나리오)

> **학습 콘텐츠 로드맵. 특정 세션의 산물로 가능성 O.**

| 파일 | 역할 | 상태 | 권고 |
|---|---|:---:|---|
| `content/README.md` | 📖 콘텐츠 4 트랙 개요 | ⚠️ 개요 | ✅ 유지 (계획용) |
| `content/01-llm-scenario-prompt.md` | 🤖 LLM 시나리오 생성 프롬프트 | ⚠️ 부분 | ✅ 유지 (참고용) |
| `content/02-scenario-roadmap.md` | 🗺️ 시나리오 21 + 영어 콘텐츠 | ⚠️ 부분 | ✅ 유지 (계획용) |
| `content/03-module-integration.md` | 🧩 모듈별 단어 제약·통합 | ⚠️ 초안 | ✅ 유지 (참고용) |
| `content/04-onboarding-and-5min.md` | 🎓 온보딩·5분 빠른코스 플랜 | ⚠️ 스펙 | ✅ 유지 (향후용) |
| `content/05-season1-and-kkeunmari.md` | 🎮 시즌1·끝말잇기 게임 | ⚠️ 스펙 | ✅ 유지 (향후용) |

---

## 📋 카테고리 5 — 역사·진단 문서 (Archive 권고)

> **특정 날짜의 전수조사 또는 피드백. 시간이 지나면 stale할 가능성 높음.**

| 파일 | 역할 | 상태 | 권고 |
|---|---|:---:|---|
| `ASSET_AUDIT_AND_INTRO_PLAN.md` | 🔍 5/21 자산 감사 + Intro 계획 | ⚠️ 히스토리 | 📦 ARCHIVE |
| `living-app-audit-2026-05-29.md` | 🔍 5/29 "살아있는 앱" 감사 | ⚠️ 히스토리 | 📦 ARCHIVE |
| `ux-radical-redesign-2026-05-29.md` | 🎨 5/29 UX 급진 리디자인 plan | ⚠️ 부분만 실현 | 📦 ARCHIVE |
| `UIUX_DUOLINGO_GAP_AND_PLAN.md` | 📊 Duolingo 격차 분석 | ⚠️ 진단 | 📦 ARCHIVE |
| `qa/v2_release_qa_report.md` | ✅ v2.0 QA 보고서 | ✅ 완료 | 📦 ARCHIVE |
| `DATA_LICENSES.md` | 📜 데이터 라이선스 고지 | ✅ 레퍼런스 | ✅ 유지 (법무용) |
| `TIGER_RIVE_DIY_WALKTHROUGH.md` | 📺 Rive DIY 튜토리얼 | ℹ️ 참고 | ✅ 유지 (선택) |

---

## 📋 카테고리 6 — 아카이브 폴더 (`_archive/`)

> **이미 정리된 레거시 문서들. 삭제 금지 (히스토리).**

✅ **현행 문서 (위 카테고리 1 참조)로 통합됨:**
- `HANGUL_SORI_STYLE_GUIDE.md` → ASSET_GENERATION_BIBLE.md §1
- `mascot_pose_sheet_v2.md` → ASSET_GENERATION_BIBLE.md §2
- `REGISTRY.md` (구) → `assets/REGISTRY.md`
- 기타 프롬프트 / 단계별 핸드오버 문서들

**보관 목적**: 구현 히스토리·결정 추적용. 신규 작업은 이 폴더를 보지 말 것.

---

## 🎯 권고 조치

### 즉시 실행 (1주)
1. **현행 문서 고정 (카테고리 1)**
   - 루트: ASSET_GENERATION_BIBLE, IMAGES_TO_CREATE, IMPLEMENTATION_AUDIT, ROADMAP_TO_LAUNCH, HANGUL_SORI_DESIGN_TOKENS
   - `assets/`, `plans/`: REGISTRY, stately-rising-jongga (2 파일)
   
2. **폐지 후보 → 주석 추가**
   ```markdown
   > ⚠️ **STATUS: ARCHIVED** — 이 문서는 2026-06-02 이전 단계의 진단입니다.
   > 현행 기준은 `docs/ROADMAP_TO_LAUNCH_2026-06-04.md`를 참조하세요.
   ```
   대상: 카테고리 5의 모든 파일

3. **정리 완료 확인**
   - `_archive/README.md` 현행 유지 (이미 정리됨)
   - 루트 파일 개수: 8 (핵심) + 12 (부분) + 11 (출시) + 6 (콘텐츠) = 37개 이내로 정리

### 선택 사항 (정기 갱신)
- 매 스프린트마다 `ROADMAP_TO_LAUNCH` 갱신 (P0·P1 항목 체크)
- 출시 직전: `store/` 디렉토리 모든 파일 재검증

---

## 📊 현황 요약

| 상태 | 개수 | 조치 |
|---|:---:|---|
| ✅ 현행 최신 | **8개** | 삭제 금지 |
| ⚠️ 부분/선택 | **29개** | ✅ 유지 (정기 갱신) |
| 📦 Archive 추천 | **10개** | 주석 추가 후 폴더 이동 권고 |
| 🗂️ 이미 Archive | **15개** | 유지 (히스토리) |
| **전체** | **62개** | — |

---

## 🔗 참조

- **마스터 계획**: `docs/ROADMAP_TO_LAUNCH_2026-06-04.md` (P0~P3)
- **구현 현황**: `docs/IMPLEMENTATION_AUDIT_2026-06-04.md` (Phase 1~9 ✅/❌/⚠️)
- **이미지 가이드**: `docs/ASSET_GENERATION_BIBLE.md` + `docs/IMAGES_TO_CREATE.md`
