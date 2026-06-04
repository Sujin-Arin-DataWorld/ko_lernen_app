# 📋 Archive 추천 10개 파일 — 구현 상태 분석

> **범위**: Archive 추천 10개 파일(2026-05-28~06-02 작성)의 모든 항목을 분석  
> **목적**: 각 파일별 구현된 것(✅) vs 미구현된 것(❌) 분류  
> **기준**: 2026-06-04 코드 기준 (`IMPLEMENTATION_AUDIT_2026-06-04.md` 참조)

---

## 📊 파일별 분석 요약

| 파일 | 작성일 | 구현율 | 이미지 필요 | 상태 |
|---|---|:---:|:---:|---|
| **1. ASSET_AUDIT_AND_INTRO_PLAN.md** | 2026-06-02 | 70% | 14장 | 자산 투명도 70% + 인트로 30% |
| **2. living-app-audit-2026-05-29.md** | 2026-05-29 | 40% | 18장 | Retention 14개 gap 중 5개 구현 |
| **3. ux-radical-redesign-2026-05-29.md** | 2026-05-29 | 50% | 1장 | 3가지 옵션 제안, 선택 미정 |
| **4. QUALITY_DIAGNOSIS_AND_UPDATE_PLAN.md** | 2026-05-28 | 60% | 0장 | 5가지 phase 중 1~2 완료 |
| **5. UIUX_DUOLINGO_GAP_AND_PLAN.md** | 2026-06-02 | 30% | — | Duolingo 비교 진단만 |
| **6. LAUNCH_READINESS_2026-06-02.md** | 2026-06-02 | 65% | — | 출시 준비 진단 (이후 갱신됨) |
| **7. JIN_VERIFY_CHECKLIST.md** | 2026-06-02 | 50% | — | 실기기 검증 체크리스트 |
| **8. release-readiness-2026-06-02.md** | 2026-06-02 | 70% | — | 출시 준비도 (대부분 해결) |
| **9. qa/v2_release_qa_report.md** | 2026-06-04 | — | — | 실기기 QA 체크리스트 (미검증) |
| **10. TIGER_RIVE_DIY_WALKTHROUGH.md** | 미확인 | 0% | 1개 | Rive 리깅 가이드만 (미제작) |

---

## 🔍 파일 1: ASSET_AUDIT_AND_INTRO_PLAN.md

### ✅ 구현된 것 (70%)

**자산 현황:**
- ✅ 마스코트 idle/blink/happy/wingup/wingdown (5개 투명수정 완료, Faceted 통일)
- ✅ 한옥 공간 madang(light) + 6개 헤더(calligraphy·porch·study·achievements·listening·kkeunmari)
- ✅ 한옥 단계 10개 (empty~windows, light 버전)
- ✅ 시나리오 백드롭 5개 (scenes/)
- ✅ 빈/오류 상태 4개 (empty/error/)
- ✅ 게이트 에셋 (gate_door_left/right/frame, 압축 완료)

**인트로:**
- ✅ intro_gate_screen.dart 기본 동작 (게이트 open, push-in)
- ✅ madang(light) 도착점 통합

### ❌ 미구현된 것 (30%)

**자산 투명도:**
- ❌ 마스코트 celebrate/neutral/sad/smile (4개, 회색 체커 배경)
- ❌ 마스코트 sleepy/thinking (2개, 다른 화풍)
- ❌ 까치 perched/celebrate/worry (3개, 옛 화풍)
- ❌ 장식 10개 (decorations/, 모두 흰배경 → 오버레이 시 흰 사각형)
- ❌ 도장 6개 (stamps/, 투명수정 필수)
- ❌ 스티커 11개 (stickers/, v3.0까지 미사용)

**한옥 단계:**
- ❌ stage_sidebuilding_light (11단계, B2 50%)
- ❌ stage_jongga_light (12단계, B2 100%)

**인트로:**
- ❌ 경로 B (faceted gate PNG 생성 — 경로 A 벡터로 현재 동작 중)
- ❌ 화면 외부 크림 마스킹 (선택사항)

### 액션 플랜

| Phase | 작업 | 상태 |
|---|---|:---:|
| **P1 즉시** | 마스코트9+장식10+도장6 투명수정 | ⏳ 대기 |
| **P1.5** | backup 15장 제거 | ⏳ 대기 |
| **P2 인트로** | 경로 A(벡터) 안정화 또는 경로 B(PNG) 생성 | 🔧 현재 경로 A 동작 |
| **P3** | 마스코트 재생성 6개 | ⏳ 대기 |
| **P3** | 한옥 단계 2개 (sidebuilding, jongga) | ⏳ 필수 |

---

## 🔍 파일 2: living-app-audit-2026-05-29.md

### ✅ 구현된 것 (40%)

**이미 살아있는 부분:**
- ✅ 인트로 시네마틱 (3s, gate+parallax push-in)
- ✅ 홈 배경 호흡 (Ken Burns)
- ✅ Ambient 입자 (매화/불씨)
- ✅ 비행 까치
- ✅ 마스코트 11종 (emotion 기반)
- ✅ Celebration burst (단청 별/다이아)
- ✅ MascotPop (정답 팝업)
- ✅ 햅틱 피드백
- ✅ Streak + freeze shield
- ✅ Reduce-motion 대응

**일부 구현된 Gap:**
- ⚠️ G6 로딩 화면 — tiger_thinking 사용 시작 (기존 spinner에서 전환)
- ⚠️ G7 streak 0 회복 메시지 — 부분 (sad PNG는 있으나 메시지 미완성)

### ❌ 미구현된 것 (60%)

**P0 Gap (code-only, 이미지 불필요):**
- ❌ **G1** 홈 상단 호랑이 + 말풍선 (페르소나 확립)
- ❌ **G4** streak shield chip 홈에 표시
- ❌ **G3-1/2** 결과 화면 3단 시퀀스 (호랑이+까치 박수, XP bar fill)
- ❌ **G5** 모듈 카드 mini ribbon (새 콘텐츠/진척/due)

**P1 Gap (이미지 필요, 5장):**
- ❌ **G2** lesson path (수평 길, 5노드) — `lesson_path_road.png` 필요
- ❌ **G8** 첫날 환영 모달 — `welcome_first_day.png` 필요
- ❌ **G3-3** 까치 편지 — `magpie_letter.png` 필요
- ❌ **G10** 모듈 hero 2개 — `hangul_calligraphy_table.png` + `chosung_drum.png`
- ❌ **G11** 마스코트 신규 4개 — tiger_cheering·tiger_reading·magpie_flag·magpie_letter

**P2 Gap (앱 밖 retention, 9장):**
- ❌ **G12** 로컬 푸시 (streak warning, daily 챌린지) + notif_tiger_glyph.png
- ❌ **G13** SFX (정답·오답·level up·streak·page swoosh)
- ❌ **G14** 시즌별 마당 8장 (spring/summer/autumn/winter × light/dark)

### 우선순위

**Tier 1 (즉시, 이미지 0장)**: G1·G4·G5·G6·G7 → 홈 페르소나·streak 시각화·로딩 개선 → retention 상승
**Tier 2 (1주, 이미지 8장)**: G2·G8·G3-3·G10·G11 → lesson path + 마스코트 + 헤더 완성
**Tier 3 (1개월, 이미지 9장)**: G12·G13·G14 → 푸시+SFX+시즌 (최종형)

---

## 🔍 파일 3: ux-radical-redesign-2026-05-29.md

### ✅ 구현된 것 (50%)

**진단:**
- ✅ 인트로 분석 완료 (90% OK)
- ✅ 홈 문제 진단 (madang dark에 호랑이 baked-in, hero 부족)
- ✅ 온보딩 문제 진단 (gate 덩그러니, 정보성 0)

**선택 옵션 제시:**
- ✅ 3가지 옵션 상세 제안 (Option 1/2/3 각각 구현 복잡도·효과 명시)

### ❌ 미구현된 것 (50%)

**온보딩 (HanokGateArt 제거 필수):**
- ❌ **Option 1 (추천, 보수)** — gate_final을 hero header로 (30분 작업)
- ❌ **Option 2** — 호랑이 + scroll (신규 PNG 1장, 1d 작업)
- ❌ **Option 3 (과감)** — gate_final fullbleed + 호랑이 환영 (추가 PNG 0, 1.5d)

**홈 재설계 (5개 영역):**
- ❌ 시간대별 인사 + 큰 호랑이 + 말풍선 hero
- ❌ stats inline chip row (현재 큰 카드)
- ❌ skill path (5노드 수평, 단청 점 + 길)
- ❌ 다음 한 발 CTA (현재 hero scenario 섞임)
- ❌ 모듈 horizontal scroll (현재 2×2 grid)

### 상태

**Jin 결정 대기:** Option 1/2/3 중 어떤 방향으로 갈지 미정. 각 option의 Pro/Con 상세히 제시됨.

---

## 🔍 파일 4: QUALITY_DIAGNOSIS_AND_UPDATE_PLAN.md

### ✅ 구현된 것 (60%)

**Phase 1 — Pre-Beta Polish (이미 대부분 완료):**
- ✅ Emoji 홈 모듈 카드 → 일부 개선됨
- ✅ 로컬라이제이션 일부 교정
- ✅ 장면 백드롭 일부 적용
- ✅ deleted `study.png` 참조 제거 완료
- ✅ `flutter analyze` 0 issues · `flutter test` 310 통과

### ❌ 미구현된 것 (40%)

**Phase 2 — Tester Build Hardening:**
- ❌ 스크린샷 테스트 (widget/golden tests)
- ❌ 데이터 검증 스크립트 (scenario schema, 누락 자산, 퀘스트 답, vocab 중복)
- ❌ 베타 피드백 route

**Phase 3 — Duolingo-Level Learning Loop:**
- ❌ Visible lesson path (daily recommendation, 다음 unlock/lock)
- ❌ Mastery 상태 (new/learning/review-due/strong)
- ❌ Error-aware review (실패한 패턴 재등장)
- ❌ Post-lesson recap (단어·문법·실수 집중)
- ❌ Streak protection & gentle return

**Phase 4 — Illustration System:**
- ❌ 통일 헤더/scene 컴포넌트
- ❌ 추가 시나리오별 백드롭
- ❌ 이모지 제거 (마스코트·아이콘으로 대체)
- ❌ PNG 크기 최적화 (레지스트리 문서화)

**Phase 5 — Content Quality Audit:**
- ❌ 21개 시나리오 인문학적 검토 (자연성·레벨 맞춤·register·문화·TTS)
- ❌ B2 확장 (3→8-10개)
- ❌ 시나리오별 학습 목표·전제 문법

---

## 🔍 파일 5-10: 기타 (UIUX_GAP·LAUNCH·VERIFY·RELEASE·QA·RIVE)

### 요약

| 파일 | 주요 내용 | 구현율 | 상태 |
|---|---|:---:|---|
| UIUX_DUOLINGO_GAP | Duolingo 경쟁 분석 (진단만) | 30% | 정기 갱신 필요 |
| LAUNCH_READINESS | 출시 준비 진단 (대부분 해결됨) | 70% | ROADMAP_TO_LAUNCH로 대체됨 |
| JIN_VERIFY_CHECKLIST | 실기기 검증 항목 | 50% | 미검증 (Jin 로컬에서만 가능) |
| release-readiness | 출시 준비도 (이후 갱신) | 70% | ROADMAP_TO_LAUNCH로 대체됨 |
| qa/v2_release_qa_report | QA 체크리스트 | — | 실기기 검증 필요 |
| TIGER_RIVE_DIY | Rive 리깅 가이드 | 0% | `.riv` 파일 미제작 (외부 작업 필요) |

---

## 📈 통합 분석

### 카테고리별 구현율

| 영역 | 구현율 | 주요 차단 |
|---|:---:|---|
| **자산 품질** | 70% | 투명도 수정 + 단계 2개 + 신규 18-32개 이미지 |
| **UX/Retention** | 40% | P0 코드 작업 5개 + P1 이미지 8-9개 + P2 시즌 8개 |
| **화면 디자인** | 50% | 온보딩/홈 옵션 선택 + 재구현 |
| **품질 진단** | 60% | Phase 2-5 (테스트·loop·illustrate·content 감시) |
| **출시 준비** | 65-70% | 실기기 QA + CF 배포 + RevenueCat |

### 즉시 필요한 작업 (P0)

**코드 작업 (Jin 불필요):**
1. G1 홈 호랑이 + 말풍선 (1d)
2. G4 streak shield chip (0.5d)
3. G5 모듈 카드 ribbon (0.5d)
4. 자산 투명도 일괄 수정 (2d 샌드박스 작업)

**이미지 작업 (Jin 필요):**
1. 자산 투명도 14-32개 (우선순위: 마스코트9 + 장식10 + 도장6 = 25개)
2. 한옥 단계 2개 (stage_sidebuilding + stage_jongga)
3. Rive 리깅 `.riv` 파일 (GUI 작업, 외부 가능)

### 후속 작업 (P1~P3)

- P1 (1-2주): lesson path + 마스코트 4개 + 헤더 2개 (이미지 8-10개)
- P2 (선택): 온보딩 재설계 (이미지 0-1개, 코드만)
- P3 (1개월+): 로컬 푸시 + SFX + 시즌 변화 (이미지 9개)

---

## ✅ 권고

1. **현행 기준 문서로 전환**: `ROADMAP_TO_LAUNCH_2026-06-04.md` + `IMPLEMENTATION_AUDIT_2026-06-04.md`
2. **이 10개 파일은 Archive 상태로 유지** (참고 용도, 실행 지침은 현행 문서 참조)
3. **Action Board 작성 권고**:
   - P0 (즉시, 1-2주)
   - P1 (1-2주 후)
   - P2/P3 (백로그)

---

## 📝 참조

- **현행 기준**: `docs/ROADMAP_TO_LAUNCH_2026-06-04.md`
- **구현 현황**: `docs/IMPLEMENTATION_AUDIT_2026-06-04.md`
- **이미지 가이드**: `docs/ASSET_GENERATION_BIBLE.md`
- **우선순위 맵**: `docs/IMAGES_TO_CREATE.md`
