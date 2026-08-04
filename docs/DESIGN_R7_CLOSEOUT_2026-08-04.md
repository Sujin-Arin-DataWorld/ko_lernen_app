# 디자인 개편 R7 마감 결산 — §12 전 항목 (2026-08-04)

> 기준: `docs/DESIGN_OVERHAUL_PLAN_2026-08-02.md` v1.2 §12. 구현 브랜치 `feat/design-r3-r7-2026-08`
> (R1·R2는 main 기반영). 상태: ✅ 코드·테스트로 닫힘 / 📱 Jin 실기기 확인 필요 / ⏭ 이관.

## 1. §12 체크리스트 결산

| 항목 | 상태 | 근거 |
|---|---|---|
| R1 SoriCard 38파일(계획 34) 시각 회귀 | ✅+📱 | 표면 v2 코드 반영, responsive 4폭+×1.3 스위트 green — 라이트 실기기 최종 육안만 |
| R1 대비 자동 테스트(본문 4.5/UI 3.0) | ✅ | 기존 contrast 스위트 green 유지, onFill/fillOutline 가드 경유 |
| R1 raw TextStyle 17 → 래칫 189 복원 | ✅ | 실측 188/189, typography_guard green |
| R2 홈 filled CTA 1개·임베드 0 | ✅+📱 | 구 주 CTA 제거, 히어로가 유일 filled — 육안 확인만 |
| R2 홈 스크롤 ≤2.5화면 | 📱 | 코드상 5블록+조건부 — 실측 필요 |
| R2 R-REC(A1 계정 A2 추천 미노출) | ✅+📱 | 시나리오 소스 레벨 가드 구현 — 신규 계정 시나리오 확인 |
| R2 헤더 발화 1개(H-4) | ✅ | 서브카피·_heroSubline 삭제 |
| R3 /path 진입 시 현재 노드 가시 | ✅+📱 | ensureVisible + 점프 버튼, reduce-motion 존중 |
| R3 76노드 전부 탭·tap_test 9/9 | ✅ | path_trail_tap_test green(무접촉) |
| R2 히어로+미리보기 동시 재생 0 | ✅+📱 | 미리보기 정적 고정(구조적) — adb reclaim 로그 스팟 확인 |
| R5 streak=1 "1 Tag in Folge" | ✅+📱 | plural 23키 — 실기기 문구 확인 |
| R5 요일 2자+스크린리더 전체명 | ✅ | Mo Di Mi… + Semantics(EEEE) |
| R5 ARB 감사 CI | ✅ | arb_l10n_guard_test 신설: plural 0·키 대칭·금지어 — 전부 green |
| R6 클립·매트 | ✅ | 매트 리포트 18/18 (magpie_play 순백 수정분 포함 재검은 Jin 플로우) |
| R6 온보딩 에셋 4건 | ⏭ Jin | book_scan 등 — Jin 제작 대기(BIBLE 프롬프트·무문자 원칙) |
| R6 승패 연출 9곳(<50% 태고/≥50% 조이) | 📱 | 코드 무접촉 — 회귀 스팟 확인 |
| R4·R7 상태 표준 위젯 체크리스트 | ✅ | 풀스크린 스피너 8곳 AppLoading화, SoriEmptyState 10+화면 기적용, Lerngruppe 재설계 |
| R7 시스템 글꼴 큰 글씨 잘림 0 | ✅+📱 | 360px×1.3 전 화면 자동 스위트 green — 200% 스크린샷 세트만 실기기 |
| R7 H-7(가입 2일차·XP 0 문구 정합) | ✅ | 복구 카드 xp>0 게이트(기반영) 확인 |
| R7 릴리스 스크린샷(FPS OFF·상태바) | ✅+📱 | showPerformanceOverlay 코드 0건 — 촬영은 Jin |

## 2. 실기기 확인 목록 (한 바퀴 순서)

1. 온보딩: 레벨 화면 타이포(17곳 교체 여파) → 진단 선택지 selectable 테두리.
2. 홈: 5블록 구조·스크롤 길이 · 헤더 칩(스트릭 탭=주간 시트) · 미션 히어로 상태(코스 진행 링·CTA 라벨·Tageskurs 배지) · 미리보기 3노드 탭(현재=팩·그 외=/path 스크롤).
3. /path: 진입 자동 스크롤 · 챕터 헤더 사계 리듬 · 점프 버튼.
4. Üben: 순서(이어하기→Lernen→Wörter→Spiele) · 섹션 색 수렴 · Paket/Silben-Rätsel 표기.
5. Lerngruppe 빈 상태: 조이+헤드라인+한옥 미리보기 램프.
6. 문구: streak=1 "1 Tag in Folge" · 디딤돌 Mo Di Mi · Café 시나리오 · Taego 알림.
7. 시스템 글꼴 200% 한 바퀴(잘림 0) + 승패 연출 태고/조이 스팟.

## 3. 이관·보류 (의도적 미포함)

- 코치 문구 소문자 "der Tiger" 2키 — 마스코트 조건부 카피 문제(조이 유저에게 호랑이 문구): 별도 이슈.
- SoriButton 라벨 maxLines:1 전수 — 컴포넌트 공통 정책이라 별도 검토.
- bookshelf 공유 시트 스피너 — 설명문 동반(§8.1 "단독 금지" 비해당) 존치.
- Quests→Missionen(§7.2) — "검토" 단계, 미확정.
- ~~다크모드~~ — **취소**(Jin 결정 2026-08-04, "다크모드 안할거야"). §4.5 보류였던 항목을 이관 목록에서 제외 — 잔여 이관 4건.

## 4. 머지·릴리스 절차 (현행화 2026-08-04 3차)

1. ~~브랜치 → main 머지~~ **완료**: 1차 통합 `02d17fa`(디자인 22커밋+계정삭제+백엔드) → 마감 로그 `d9c8325` → 2차 stamps 통합 `72513e2`(e1247a5: 장면 포스터 11종·도장 8→14종·배선 재분배). 현재 **main = feat/stamps-14-2026-08** — `72513e2` 이후 약국 포스터 `af9dec6`(Jin, pharmacy.png)·본 결산 커밋까지 동기화.
2. Jin 게이트 **재실행**(통합 머지 후 필수): `flutter gen-l10n` → `flutter analyze --no-pub` → `flutter test`.
   ⚠ 예상 red 1건: `dancheong_stamp_test` "모든 DancheongMotif 에 도장 PNG 실재" — 신규 6종(chilbo·gwigap·peony·taegeuk·vine·wave) PNG 미착. stamps 세션 8장 다운로드 → `python3 tool/stamp_normalize.py` 후 green. 그 외는 정적 선검증 all green(§6).
3. `git push origin main feat/stamps-14-2026-08`(Jin) + 로컬 `git branch -d feat/design-r3-r7-2026-08`(VM은 ref 삭제 불가).
4. §2 실기기 한 바퀴(+P 추가 2건: 온보딩 라이트 템플릿 3장·cardTitle 15/w700 전역 인상) → 이상 시 feat/stamps-14 위 수정.
5. 릴리스 스크린샷 재촬영(FPS OFF) → **+11 빌드 = 디자인 개편 최초 포함 빌드** (런북 절차).

---

## 5. 감사 후속 P1~P9 결산 (2026-08-04 2차)

analyze·test 전부 green 후 자체 감사에서 나온 미구현·부족 9건을 전부 처리:

| P | 내용 | 커밋 |
|---|---|---|
| P1 | 온보딩 템플릿 v2 — 다크 풀블리드 폐지, 한지 라이트·정사각 슬롯 55%·헤드라인 26 w800·CTA 고정 하단·상태바 다크(§6.5·§10.4). 에셋 교체는 Jin 4종 후속 | `12a2c73` |
| P2 | `cardTitle` 프리셋 14/w800 → **15/w700** — §4.3 "w800 금지" 전역 해소. **전역 시각 변화 — 실기기 대조 필수** | `614a26b` |
| P3 | 게스트 유도 카드 혜택 중심 문구("Behalte Streak, XP & Hanok") DE/EN (§7.3) | 〃 |
| P4 | `errorOffline` 카피 신설 + AppError 사용 규정(§8.1) | 〃 |
| P5 | 추천 엔진·±1 슬라이스 **순수 함수 추출**(`mission_recommender.dart`) + 단위 테스트 18케이스(우선순위·R-REC·경계) | `c7c136b` |
| P6 | `ensurePackAccess()` — 프리미엄 게이트 3곳 수렴 | 〃 |
| P7 | 골든 기준선 테스트 신설(`test/goldens/`) — **Jin 1회: `flutter test --update-goldens test/goldens`** 로 기준 생성(그 전까지 자동 skip) | 이번 커밋 |
| P8 | 홈 다이어트: 주간 위젯 3종 → `week_progress.dart` 분리(홈 −190줄, 1,821줄) | 〃 |
| P9 | 타이포 래칫 실측 재하향: w800 189→**180**, w900 45→**40** | 〃 |

게이트: `flutter gen-l10n`(P3·P4 키) → analyze → test → **골든 기준 1회 생성** → 실기기(§2 목록에 +2: 온보딩 라이트 템플릿 3장, 카드 제목 전역 15/w700 인상).
---

## 6. 최종 마감 — 통합 머지 후 정적 재검증 (2026-08-04 3차)

`72513e2` 기준, 클라우드 세션이 Flutter 없이 소스·에셋을 정적 전수 측정한 결과:

- 타이포 래칫: w800 **180/상한 180** · w900 **40/40** · 'Pretendard' 105/119 — w800·w900 여유 0 은 의도된 락(신규 추가 즉시 red).
- 클립 매트: 리포트 **24/24** 커버리지 정확 · 바이트 드리프트 0 · 비순백 매트 0 (tiger_magpie_play 드리프트 해소 확인).
- 참조 무결: `CharacterClips` mp4 참조 결손 0 · `HanokHeader.kLoopAssets` ↔ `video/loops/` 완전 대칭.
- ARB: DE/EN 키 대칭 0차이 · 값 내 Starbucks/Wordle 0 — "Wordle"은 키 이름(`gameWordleTitle` 등)에만 잔존, 가드 범위 밖·사용자 노출 0.
- 도장: enum 14종 중 PNG 8종 — 미착 6종은 §4-2의 유일한 예상 red.
- Q7 잔여(계획 §11) 확인: `tiger_video.dart` 죽은 경로 구식 가드는 **2026-08-03 기정리**(소스 주석 근거) — 남은 건 실기기 소리 확인뿐.
- 다크모드: §3 대로 **취소**(Jin 2026-08-04) — §12 "라이트/다크 시각 회귀"는 라이트 단독으로 종결.

이로써 §12 전 항목의 세션(클라우드) 몫은 종료. 잔여는 전부 Jin 트랙 — push · 게이트 재실행 · §2 실기기 · 스크린샷 · +11 빌드.
