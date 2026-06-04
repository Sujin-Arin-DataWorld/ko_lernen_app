# 상용화 로드맵 (2026-06-04)

> **짝 문서**: 구현 현황 1:1 분류 = `docs/IMPLEMENTATION_AUDIT_2026-06-04.md`. 본 문서는 **"무엇이 남았고 어떻게 출시하는가"**.
> **통합 출처**(중복 생성 X): `COMMERCIALIZATION_ASSESSMENT_2026-06-03` · `release-readiness-2026-06-02` · `ACCOUNT_SYSTEM_AUDIT_2026-06-03` · `monetization-plan` · `FEATURE_ROADMAP_2026-06-02`.
> **표기**: ~~취소선~~✅ 완료 · ❌ 남음 · 🔧 Jin 운영영역(코드로 판정 불가).

---

## 1. 현재 위치 (한 줄)

> **코드는 출시 가능 수준(Phase 1~9 ~85%). 막는 건 코드가 아니라 배포·결제·검증.**
> 안드로이드 **무료 내부테스트는 1~2주(운영 위주)**, 유료 구독 상용은 4~8주(비즈/법무 병목), 듀오링고급 리텐션은 2~3개월.

---

## 2. 상용화 필수 항목 전수 (체크리스트)

| # | 항목 | 담당 | 상태 |
|---|---|:---:|:---:|
| 1 | ~~릴리즈 빌드 설정 (R8·ProGuard·keystore·서명)~~ | 코드 | ✅ |
| 2 | ~~Data Safety / Privacy / 계정삭제 URL~~ | 코드 | ✅ (`data-safety.md`·`privacy.html`) |
| 3 | ~~익명·Google·Apple 로그인 + 계정삭제(GDPR cascade)~~ | 코드 | ✅ |
| 4 | AAB 빌드 + native symbols 업로드 | 운영 | 🔧 |
| 5 | **Firestore rules 배포** (`firestore.rules` 작성됨) | 운영 | 🔧 |
| 6 | **Cloud Function 배포** `analyze_korean_text`(Python) | 운영 | 🔧 ❌ |
| 7 | **Cloud Function 배포** `gye`(Node) + Cloud Scheduler | 운영 | 🔧 ❌ |
| 8 | DeepL·우리말샘 API 키 주입 + **DeepL 키 재발급**(대화 노출) | 운영 | 🔧 |
| 9 | **RevenueCat**: 대시보드·구독상품·API 키 | 운영 | ❌ |
| 10 | Play Console 구독 상품(€4.99/월 등) 등록 | 운영 | ❌ |
| 11 | iOS Xcode "Sign in with Apple" capability | 운영 | 🔧 |
| 12 | **Feature graphic 1024×500** (draft만 존재) | 자산 | ❌ |
| 13 | **스크린샷 8슬롯** 재캡처 | 자산 | ❌ |
| 14 | **실기기 QA** (Android+iOS, 카메라·TTS·결제·시각) | 검증 | ❌ |
| 15 | Closed Testing 5~10명 1주 | 운영 | ❌ |

> 1~3은 완료. **출시를 막는 건 4~15(거의 운영/검증)**. 신규 코드 작업은 거의 없음(예외: Phase 7·8 트랙 §5).

---

## 3. P0 차단요소 (이거 없으면 상용 불가)

| P0 | 무엇이 깨지나 | 담당 | 리드타임 |
|---|---|:---:|---|
| **CF 미배포**(#6·#7) | "책 한 컷" 번역·단어추출 0, 계 주간목표 자동집계 0 | 🔧 운영 | 0.5~1일 (`store/cloud-function-deploy.md` 런북) |
| **rules 미배포**(#5) | 동기화·계·공유 프로덕션 권한 미확인 | 🔧 운영 | 0.5일 |
| **RevenueCat 0**(#9·#10) | 결제 불가 → 유료 출시 자체 불가 | 🔧 운영 | 3~7일 (`subscription-setup-runbook.md`) |
| **실기기 QA 0회**(#14) | 카메라·TTS·결제·시각 미검증 → 평점 리스크 | 검증 | 2~3일 |
| **스토어 자산**(#12·#13) | Play Console 등록 미완 | 자산 | 2~4일 |
| **DeepL 키 노출**(#8) | 키 남용·비용 폭증 리스크 | 🔧 운영 | 0.5일 (재발급) |

> CF·rules·키는 코드로 끝낼 수 없음(내 권한 밖). spec/런북은 `docs/store/`에 준비됨.

---

## 4. 시나리오별 경로

### A. 무료 베타 / 내부테스트 (1~2주) — **권장 즉시 경로**
신규 코드 거의 0. **#4·#5·#6·#7·#8·#14 + 스크린샷 일부**만.
- CF 2종 배포 + 키 주입 → 책한컷·계 작동 확인
- rules 배포 → 2계정 계 플로우 실기기 검증
- AAB 빌드 → Play Console **Closed Testing** 업로드
- 결제 비활성(무료) → RevenueCat 없이도 가능
- 산출: 실사용 피드백 수집 시작

### B. 유료 구독 상용 (4~8주)
A + **#9·#10·#11 + 사업자/세무/EUR 계좌 + 환불·약관**.
- 기술 << **비즈니스·법무 리드타임**이 병목 (RevenueCat·Play 결제·VAT)
- `monetization-plan.md`: 월 €4.99 / 년 €39.99 / 평생 €49.99, Free vs Plus 기능분리
- Free/Plus 게이팅 코드(`premium_service.isPremium`)는 ✅ — 운영 셋업만

### C. 듀오링고급 리텐션 경쟁 (2~3개월)
B + **Phase 7·8 완성**(FCM·자동모더레이션·age-gate) + 콘텐츠 증량 + 게이미피케이션 폴리시.
- `FEATURE_ROADMAP` Tier A/B/C + `UIUX_DUOLINGO_GAP_AND_PLAN`
- 핵심: 일일 목표·업적·주간 요약·푸시 알림·단일 CTA

---

## 5. 기능 완성 백로그 (Phase 미완분 — 우선순위)

| 우선 | 항목 | Phase | 종류 |
|:---:|---|:---:|:---:|
| **P1** | CF 2종 배포 + 통합 테스트 | 5·7 | 🔧+검증 |
| **P1** | 번역 Firestore 캐시 (현재 lru 인메모리만 — DeepL 비용 직결) | 5 | 코드 |
| ~~P2~~ | ~~`weekly_goal_rollover` 보상(영구 unlock·xp부스트)~~ ✅ + Scheduler 설정 | 7 | ✅코드 / 🔧배포 |
| ~~P2~~ | ~~`on_report_created` 자동정지 CF (서로 다른 3명)~~ ✅ | 8 | ✅코드 / 🔧배포 |
| ~~P2~~ | ~~`age_gate_service` 16세 미만 차단(GDPR-K) + 생년 UI + 정지회피 rules~~ ✅ | 8 | ✅ |
| ~~P2~~ | ~~FCM 피드 푸시 (`push_service` + CF `pushToGyeMembers`)~~ ✅ 코드 / iOS APNs·enable 🔧 | 7 | ✅코드 |
| ~~P3~~ | ~~Admin 패널 `tools/admin/` (신고 큐·계 관리)~~ ✅ 코드 / claim·인덱스·배포 🔧 | 8 | ✅코드 |
| **P3** | 누락 PNG: hanok_stages `jongga`·`side_building`, decorations 7, `tiger.riv` | 3·4 | 자산 |
| **P3** | `q_seokdeung`(발음평가)·`q_doldam`(친구수) source 와이어 | 4 | 코드 |
| **P3** | CloudSync 범위 완성 (packs·bookshelf·custom·gye 동기화) | — | 코드 |

> 전부 errorBuilder/fallback이 있어 **현재도 빌드·실행 정상**. P1만 출시 전 필수, P2~P3는 출시 후.

---

## 6. 출시 후 방향 (FEATURE_ROADMAP + monetization 통합)

**Tier A — 빠른 고효율 (출시 직후 1~2주)**: 대부분 이미 구현(`review_deck_service`·`hard_words`·custom 4모드·`wordbook_search`). 잔여 = 단어장 폴더/정렬.

**Tier B — 중간 투자 (1~2개월)**: 듣기 받아쓰기 퀘스트 · 한글 생산모드(타이핑/쓰기) · 단어장 CSV/Anki 내보내기 · 게이미피케이션 폴리시(일일목표·업적·주간요약).

**Tier C — 큰 베팅 (분기)**: 말하기·발음 평가(STT, `q_seokdeung` 해금) · TOPIK 시험 모드 · 계 v3.0(자유 텍스트·음성) · 원어민 음성·홈 위젯 · **AI 무한 개인화 콘텐츠**(`personalized_lesson_service` skeleton → €5/월 정당화).

---

## 7. 앞으로 나아가야 할 방향 (Jin 의사결정 필요)

1. **출시 모델 결정** — 무료 베타(A) 먼저 vs 유료 동시(B)? → A 강력 권장(코드 0, 1~2주, 피드백 후 B).
2. **CF 배포 환경** — gcloud gen2 europe-west3 (런북 있음). Blaze 플랜 전환 필요(Cloud Functions).
3. **DeepL 비용** — DAU 100 도달 시 Pro 전환 임계. **번역 캐시(P1)** 먼저 넣으면 Free 수명 연장.
4. **iOS 출시 여부** — Apple 개발자 계정($99/년) + capability. 안드로이드 먼저 vs 동시?
5. **수익화 콘텐츠 정당화** — 현재 콘텐츠(526단어·21시나리오·88문법)는 입문 충분하나 €5/월 정당화엔 증량 필요. 콘텐츠 공장(`tools/content_factory`) 가동 우선순위.
6. **Phase 8 모더레이션 깊이** — 계 기능을 베타에 노출할지(자동정지·admin 미구현). 안 하면 수동 검토 부담. → **베타에선 계 비노출 또는 소수 화이트리스트** 검토.
7. **문서 정리** — 감사문서 60+개 drift. 본 2파일을 SSoT로, 나머지 `_archive` 이동 별도 세션 제안.

---

## 부록: 즉시 실행 순서 (시나리오 A 기준)

```
1. DeepL 키 재발급 + functions/.env 갱신
2. firebase deploy --only firestore:rules
3. firebase deploy --only functions:analyze_korean_text   (Python, gen2)
4. cd functions/gye && firebase deploy --only functions    (Node)
5. 앱 Storage.bookAnalysisEndpoint = 배포 URL 확인
6. flutter build appbundle --release --obfuscate --split-debug-info=...
7. 실기기: 책한컷(번역 작동) · 계 2계정 · TTS · 결제 없음 확인
8. Play Console Closed Testing 업로드 + 스크린샷 8장
```

> 상세 런북: `docs/store/cloud-function-deploy.md` · `closed-testing-checklist-v2.md` · `subscription-setup-runbook.md`.
