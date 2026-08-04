# 세션 인수인계 — 디자인 개편 통합·마감 세션 전체 기록 (2026-08-04)

> **독자**: 이 레포를 건드리는 모든 다른 세션(Claude·Codex·stamps·Joy/에셋·백엔드·로컬 Flutter).
> **목적**: 이 문서 하나로 "통합 세션"이 한 일·현재 레포 상태·디자인 계약·운영 레시피를 100% 재구성한다.
> **SSoT는 `AGENTS.md` 세션 로그다.** 이 문서는 그 항목들의 종합 해설판이며, 충돌 시 AGENTS.md·소스코드가 이긴다.
> 계획 원본: `docs/DESIGN_OVERHAUL_PLAN_2026-08-02.md`(v1.2, §1~§12) · 결산: `docs/DESIGN_R7_CLOSEOUT_2026-08-04.md`(§1~§6).

---

## 0. 30초 스냅샷

- **디자인 개편 R1~R7 + 감사 후속 P1~P9 전부 구현·머지 완료.** 다크모드는 **취소**(Jin, 08-04).
- **refs**: `main` = `feat/stamps-14-2026-08` (본 문서 커밋 직전 기준 `14681dc`). 두 브랜치는 항상 같이 전진시킨다.
- **게이트 기대치**: `flutter analyze` 경고 1건(mascot `_magpiePerched` — Joy 세션 WIP 몫) · `flutter test` red 1건(도장 PNG 6종 미착 — stamps 몫). **이 둘은 예정된 상태다. 고치려 들지 말 것.**
- **push는 세션 VM에서 불가**(네트워크 차단) — Jin이 로컬에서 `git push origin main feat/stamps-14-2026-08`.
- `feat/design-r3-r7-2026-08`은 완전 머지됨(72513e2의 2번째 부모) — 삭제는 Jin 로컬 `git branch -d`만 가능(VM은 ref 파일 unlink 불가).
- 이 레포는 **여러 세션이 같은 워크트리·같은 인덱스를 공유**한다. §6의 git 레시피를 안 지키면 남의 작업을 부순다.

## 1. 지금 레포 상태 (2026-08-04 마감 기준)

| 항목 | 상태 |
|---|---|
| 브랜치 체인 | `… → d9c8325(1차 통합 마감) → 72513e2(stamps e1247a5 머지) → af9dec6(Jin 약국 포스터) → 7639cb9(§12 결산) → 14681dc(테스트 구문 수리)` |
| main ↔ feat/stamps-14-2026-08 | 동일 커밋 (이후에도 동기 유지 원칙) |
| 워크트리 | clean (단, 루트 `deco_sheet.jpg` 미추적 — 작업 중 파일로 보고 무접촉) |
| magpie_front / magpie_tiger_together | **배경 제거판 확정** — 64,198 / 146,284 bytes. 배경 있는 구판(515,285/1,463,122)으로 되돌리는 커밋 금지 |
| 도장 | `DancheongMotif` 14종 중 PNG 8종 존재. **미착 6종: chilbo·gwigap·peony·taegeuk·vine·wave** |
| 장면 포스터 | 12종(11종 + pharmacy). `scenario.dart:441` `pharmacy_headache→market` 배선을 pharmacy로 갱신할지는 stamps 세션 결정 |
| 정적 선검증 | closeout §6: 래칫 180/40·105, 매트 리포트 24/24 드리프트 0, 클립·루프 참조 무결, ARB DE/EN 대칭·금지어 0 |

## 2. 커밋 지도 (R1 착수 → 마감, 시간순 오름)

"세션"열: 통합=이 세션(클라우드 통합·마감 세션), 대행=타 세션 산출물을 이 세션이 커밋만 대행.

| 커밋 | 세션 | 내용 (계획 근거) |
|---|---|---|
| `8b815ac` | 통합 | R1-a SoriCard 표면 v2 — 라이트 테두리→그림자, selectable·accent 바 (§4.1·§4.2·§10.3) |
| `e48b5b2` | 통합 | R1-b 진단 선택지 selectable — 선택 신호 primary 2px (§10.3) |
| `1c02ca6` | 통합 | R1-c/d 잠금·비활성 톤 — 죽은 회색 제거 (§4.4-3) |
| `a637e67` | 통합 | R1-e 온보딩 raw TextStyle 17곳 → SoriTextTheme, w800 래칫 189 복원 (§4.3·§12) |
| `45edfc4` | 통합 | R2-a 홈 미션 히어로 — 단일 CTA 추천 엔진 (§6.1 블록3·§10.1) |
| `16adaf2` | 통합 | R2-b 홈 경로 미리보기 — 임베드 전량 노출 종료 (§6.1 블록4·§10.2) |
| `9c5209a`+`3705e42` | 통합 | R2-c 홈 헤더 통합·발화 단일화(H-4) + 죽은 import 정리 |
| `529c48e` | 통합 | R2-d 블록5 조건화 + Tageskurs Q2 반영 (§6.1·§11 Q2) |
| `ddc8304`+`fa52164` | 통합 | R3 /path 개편 — 자동 스크롤·점프 버튼·사계 챕터 헤더·챕터 0 (§6.2) |
| `625986f` | 통합 | R4-a Üben 허브 — 섹션 순서·복습 단일 소스·색 수렴 (§6.3·§4.4-2) |
| `68d6a99` | 통합 | R4-b Lerngruppe 빈 상태 — 조이·한옥 미리보기 (§6.4) |
| `d85deeb` | 통합 | R4-c Profil 검증 + gye 로딩 AppLoading 표준화 (§8.1) |
| `0ab9314`+`249884f`+`c93a0b3` | 통합 | R5 문구 일괄 — plural 23키·Paket 38키·Silben-Rätsel·Café·Taego + ARB 감사 래칫 신설 (§7·§11 Q3/Q5/Q6/Q8) |
| `b78da8c`+`a5190fb` | 통합 | R7 상태·타이포 잔여 스윕(AppLoading 8곳) + §12 결산 문서·배포 체크리스트 (§8.1·§9) |
| `614a26b` | 통합 | P2~P4 — cardTitle 15/w700·게스트 혜택 문구·errorOffline (§4.3·§7.3·§8.1) |
| `12a2c73` | 통합 | P1 온보딩 템플릿 v2 — 다크 풀블리드 → 한지 라이트 (§6.5·§10.4) |
| `c7c136b` | 통합 | P5+P6 — 추천엔진·±1 슬라이스 순수 함수 추출 + 테스트 18케이스, `ensurePackAccess` 게이트 단일화 |
| `0cdad23` | 통합 | P7~P9 — 골든 기준선·홈 다이어트(week_progress 분리)·래칫 실측 하향(180/40) |
| `891f8e6` | 통합 | P5·P8 후속 — `PackStatus.available` 오기 등 analyze 5건 해소 |
| `91dd549` | 통합 | 골든 기준선 PNG 3종 커밋 (P7 활성화) |
| `b372e2f`·`8fa0eac` | 계정삭제 세션 | pending deletion retry 복구 + 기록 |
| `f14e186` | 대행(백엔드) | preflight cp949 수정 + AAB 감사·submitTesterFeedback 세션 로그 |
| `02d17fa` | 통합 | **1차 통합 머지** — 디자인 22커밋+계정삭제+백엔드를 main으로 (임시 인덱스 플럼빙, 워크트리 무접촉) |
| `d9c8325` | 통합 | AGENTS 마감 로그 (P1~P9+통합) |
| `e1247a5` | stamps | 장면 포스터 11종 단청 회화체 + 도장 8→14종 + 배선 재분배 (커밋은 stamps 세션이 자체 수행) |
| `72513e2` | 통합 | **2차 통합 머지** — e1247a5를 흡수. 충돌 3건 해소: magpie 2종=**배경 제거판(theirs) 채택**, AGENTS=3-way 유니온(손실 0) |
| `af9dec6` | Jin | 약국 포스터 pharmacy.png (레이스 발생 — CAS 덕에 무손실, 아래 §6-7) |
| `7639cb9` | 통합 | §12 최종 결산 — closeout §4 현행화·§6 신설(정적 전수 재검증) |
| `14681dc` | 통합 | dancheong_stamp_test 구문 수리 — 가드 `group`을 `_Harness` 클래스 밖 `main()`으로 이동(내용 무변경) |

## 3. 디자인 시스템 계약 — 표면 v2 (이 세션이 구축·전 화면 적용)

**정확한 수치의 SSoT는 `lib/widgets/sori/tokens.dart`다.** 아래는 계약(불변 규칙)이다.

### 3.1 레이어·표면 규칙 ("한지 위 백자", 계획 §4.1·§4.2)

- 라이트 기본: 배경 `SoriColors.lightBg`(한지) 위 표면 `lightSurfaceRaised` — **테두리 없음 + 그림자(SoriElevation.low)**. "테두리 다이어트"가 개편 1번 수술이었다. 카드에 테두리를 다시 넣는 변경은 회귀다.
- pressed: `SoriElevation.medium` (`SoriPressable.onPressedChanged` 콜백으로 전달).
- selectable/선택됨: primary 2px 테두리가 **유일한** 선택 신호 문법.
- accent 변형: **좌측 4px 컬러 바**(Stack+Positioned). 배경 틴트로 강조하지 않는다.
- 다크 토큰(darkBorderStrong 1.5 등)은 코드에 남아 있으나 **다크모드 자체가 취소**됨 — 다크 경로에 신규 투자 금지.

### 3.2 타이포 (§4.3)

- raw `TextStyle` 직접 생성 금지 — `SoriTextTheme.of(ctx)` 프리셋만. (래칫 테스트가 개수를 잠근다.)
- 본문 위계는 프리셋 이름으로 말한다: display/h1/h2/h3/body/bodySmall/caption/label/cardTitle. **cardTitle은 P2에서 15/w700로 확정**(w800 금지 해소) — 전역 시각 변화라 실기기 대조 항목.
- `FontWeight.w800`·`w900` 신규 추가는 즉시 래칫 red(여유 0). 'Pretendard' 리터럴 지정도 래칫 관리 대상.

### 3.3 이 세션이 추가한 컴포넌트·함수 인벤토리

| 파일 | 공개 API | 역할 |
|---|---|---|
| `widgets/sori/card.dart` | `SoriCard`(selectable/selected/accent, EavesCorner 유지) | 표면 v2 본체. `resolvedBackground` 계약 불변 |
| `widgets/sori/pressable.dart` | `SoriPressable.onPressedChanged` | pressed 고도 연동 |
| `widgets/sori/mission_hero_card.dart` | `MissionHeroKind/Content/Card`, 진행 링(56dp, -π/2 시작, stroke 6), `_AllDoneCard`, Tageskurs 배지 | 홈 블록3 히어로 |
| `widgets/sori/path_preview_row.dart` | `PathPreviewRow(stops, onSeeAll)` | 홈 블록4 — /path 미리보기 3노드 |
| `widgets/sori/path_trail.dart` | `SoriPathNodeDisc(stop, liveNow:)` 공개 래퍼, 라벨 2줄 | /path·미리보기 공용 노드 |
| `widgets/sori/level_chip.dart` | `SoriLevelChip(code, {color})` | 히어로·챕터·"0"잉크 칩 공용 |
| `widgets/sori/week_progress.dart` | `WeekSteppingStonesRow`, `DailyGoalCard` | 홈에서 분리(−190줄), 요일 2자+Semantics 전체명 |
| `services/mission_recommender.dart` | sealed `MissionPick`(Course/Pack/Review/Scenario), `recommendMission(...)`, `previewWindow<T>()` | 홈 CTA 추천 순수 함수 — **UI에서 분리, 테스트 18케이스** |
| `services/pack_access.dart` | `ensurePackAccess(context, {level})` | A1 무료/프리미엄 게이트 단일 진입점(3곳 수렴) |

홈(`home_screen.dart`)은 5블록: TopBar 칩(스트릭 탭=주간 시트) → 히어로(MissionPick resolver) → 미리보기(previewWindow) → 조건부 블록5. Lernpfad 전량 노출은 `/path` 전용으로 이관(§6.2, 자동 스크롤+점프 버튼).

### 3.4 Do / Don't (다른 세션이 제일 자주 틀리는 것)

| ✅ Do | ❌ Don't |
|---|---|
| 프리셋·토큰 경유(`SoriTextTheme`, `SoriColors`, `SoriSurfaces.of`) | raw TextStyle·hex 하드코딩·w800 신규 |
| 상태 표현: AppLoading/AppError/SoriEmptyState 표준 위젯 | 풀스크린 맨 스피너·설명 없는 스피너 |
| 팩 진입은 `ensurePackAccess()` 경유 | 화면별 자체 프리미엄 게이트 재발명 |
| 문구는 ARB(DE/EN 대칭·plural)로 | 하드코딩 문자열, "Starbucks"/"Wordle" 값 사용(가드 red) |
| 도장·문양 추가 시 enum+PNG+매핑 3종 세트 | 문양만 추가(PNG 실재 가드 red) |

## 4. 가드·래칫 현황 — 뭘 건드리면 red가 나나

| 테스트 | 잠그는 것 | 현재 실측 | red 조건 |
|---|---|---|---|
| `typography_guard_test` | w800 ≤**180**·w900 ≤**40**·'Pretendard' ≤119(현 105) | 180/40/105 | 신규 w800·w900 1개라도 추가 |
| `arb_l10n_guard_test` | plural 미처리 0·DE/EN 키 대칭·값 내 Starbucks/Wordle 금지 | all green | 키 비대칭·금지어. **키 이름의 "Wordle"(`gameWordleTitle` 등)은 가드 범위 밖 — 정상** |
| `character_clip_matte_test` | 매트 리포트 커버리지·바이트 드리프트·순백 매트 | 24/24, 드리프트 0 | 클립 교체 후 `python tool/check_clip_matte.py` 미실행 |
| `dancheong_stamp_test` | 팩→문양 매핑 전수 명시 + **문양별 PNG 실재** | **red 1건(예정)** | 미착 6종 PNG가 올 때까지 red. 다른 수정으로 "고치지" 말 것 — 8장 다운로드→`tool/stamp_normalize.py`가 정답 |
| `test/goldens/…` | 표면 v2·사계 칩·미션 히어로 기준선 3 PNG | 기준선 커밋됨(`91dd549`) | 의도 변경 시 `flutter test --update-goldens test/goldens` 후 PNG 동반 커밋 |
| `literal_completion_feedback_coverage_test` | 완료 피드백 인벤토리('Silben-Rätsel' 표기 포함) | green | 게임 라벨 문자열 변경 |

## 5. 에셋·영상 계약 + 절대 규칙 (요약 재확인 — 원문은 AGENTS.md 최상단)

- 캐릭터 클립 = **순백 배경 H.264 mp4** + 앱에서 `ColorFiltered(BlendMode.multiply)` 흡수. 규격 960×960/24fps/CRF19/faststart/무음. 배경이 #FFFFFF가 아니면 잔상이 남는다.
- **tiger_roar는 이미지·영상 절대 불변경**(소리만). 캐논 호랑이 = `tiger_idle.png` faceted 저폴리·종이결·외곽선 없음. 평면 벡터풍 거부. 신규 마스코트 이미지는 Jin 명시 위임 없이 생성 금지.
- magpie_front·magpie_tiger_together = 배경 제거판이 정본(§1 표의 바이트 수로 식별).
- UI 문구는 기기 언어(de/en) — 인터페이스에 한글 고정 금지. 첫 인사에 사람 목소리·한국어 TTS 금지.

## 6. 이 VM에서 git 쓰는 법 — 레시피 전문 (안 지키면 사고)

**전제**: device_bash 마운트는 **파일 unlink(삭제) 금지**다. 생성·덮어쓰기·rename(mv)은 된다. 여기서 모든 git 특이사항이 나온다. (stamps 세션 로그의 "커밋은 윈도우에서만 가능"은 그 세션 관찰일 뿐 — 이 레시피대로면 커밋·ref 갱신 전부 가능하다. 안 되는 건 파일/브랜치 **삭제**뿐.)

1. **락 청소를 모든 git 호출 앞뒤에 넣는다** (남는 `*.lock`은 mv로 무덤에 치운다):
   ```bash
   clearlocks() { mkdir -p _to_delete/git-locks-2026-08-03; for f in $(find .git -maxdepth 4 -name '*.lock' 2>/dev/null); do mv "$f" "_to_delete/git-locks-2026-08-03/$(basename $f).$(date +%s%N)"; done; return 0; }
   ```
   그리고 **호출(명령 블록)의 마지막을 git 명령으로 끝내지 않는다** — 반드시 `clearlocks; echo OK`로 마감.
2. **`git add -A` 금지.** 인덱스를 여러 세션이 공유한다 — 명시 경로만 add. (실제로 남의 WIP 7파일이 쓸려 들어가 되돌린 사고가 있었다.)
3. **커밋은 플럼빙으로**: `T=$(git write-tree)` → `C=$(git commit-tree "$T" -p <부모> <<'EOF' … EOF)` → `git update-ref refs/heads/<브랜치> "$C" <이전값>`.
4. **update-ref는 항상 이전값(CAS)을 지정한다.** 레이스가 실제로 났다: 결산 커밋 도중 Jin이 `af9dec6`을 먼저 실었고, CAS가 거부해준 덕에 아무것도 안 덮이고 그 위로 재작성했다. CAS 없이 update-ref 하면 남의 커밋을 유실시킨다.
5. **워크트리 파일 교체는 checkout이 아니라 blob 덮어쓰기로**: `git checkout --theirs -- <파일>`은 unlink가 필요해 **조용히 실패하고 구판이 남는다**(이번 "magpie 회귀 소동"의 원인). 정답: `git cat-file blob <원하는 sha> > <파일>` 후 `git add <파일>`.
6. `git switch`/`merge`의 워크트리 반영도 같은 이유로 반쯤 실패할 수 있다 — 상태가 이상하면 `git diff --name-only`로 워크트리↔인덱스 차이를 보고, 경로별로 (워크트리==HEAD면 stale → blob 덮어쓰기 / 그 외 → 남의 WIP이니 무접촉) 분류한다.
7. **브랜치 삭제·파일 삭제는 VM 불가** — 삭제는 `_to_delete/`로 mv, 브랜치 삭제는 Jin 로컬 몫.
8. 워크트리 무접촉 크로스브랜치 작업(체리픽·머지)은 `GIT_INDEX_FILE=$HOME/임시 + read-tree [-m -i] + update-index --cacheinfo + write-tree + commit-tree` 조합(02d17fa가 이 방식).
9. **모든 변경은 AGENTS.md 세션 로그에 기록**(무엇을·왜·검증·커밋해시) — 기록 없는 커밋 금지.

## 7. 소유권 — 남은 일은 누가

| 몫 | 할 일 |
|---|---|
| **Jin(로컬)** | `git push origin main feat/stamps-14-2026-08` → `git branch -d feat/design-r3-r7-2026-08` → 게이트 재실행 → closeout §2 실기기 한 바퀴(+온보딩 라이트 3장·cardTitle 전역) → 릴리스 스크린샷(FPS OFF) → **+11 빌드 = 디자인 개편 최초 포함** |
| **stamps 세션** | 도장 8장 다운로드 → `python3 tool/stamp_normalize.py` → 가드 4개 green(dancheong red 해소) · `pharmacy_headache` 배선 갱신 여부 결정 · `deco_sheet.jpg` 거취 |
| **Joy/에셋 세션** | mascot `_magpiePerched` unused_field 정리 포함 잔여 WIP 커밋(+l10n generated 동반) |
| **이관 4건(닫힌 결정 아님, closeout §3)** | 코치 "der Tiger" 2키 · SoriButton maxLines 정책 · bookshelf 공유시트 스피너(존치 확정) · Quests→Missionen(결정 대기) |

## 8. 문서 지도

- `AGENTS.md` — **SSoT.** 최상단 절대 규칙 + 세션 로그(모든 커밋의 무엇/왜/검증).
- `docs/DESIGN_OVERHAUL_PLAN_2026-08-02.md` — 계획 v1.2 (§4 시스템·§6 IA·§10 핸드오프 스펙·§11 결정 8건·§12 체크리스트).
- `docs/DESIGN_R7_CLOSEOUT_2026-08-04.md` — §12 결산(§1 표·§2 실기기·§3 이관·§4 절차·§5 P1~P9·§6 정적 재검증).
- `docs/DEPLOY_CHECKLIST.md` — 릴리스 런북 연결.
- 에셋 트랙: `ASSET_FILE_TRIGGER_MAP.md`(트리거 조회)·`ASSET_TRIGGER_AUDIT_*`(배선 서사)·`ASSET_VIDEO_PIPELINE_*`(제작 재현)·`ASSET_GENERATION_BIBLE`(프롬프트 원칙)·`docs/CLIP_REGEN_2026-08-03.md`.
- 이 문서 — 통합·마감 세션 해설판. 갱신 책임: 상태가 바뀌면 **바꾼 세션이** §0·§1·§7을 고친다.
