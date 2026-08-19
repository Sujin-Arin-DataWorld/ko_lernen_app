# Hangul Sori — 3일 main 전수 감사 + 권장 해결

| 항목 | 값 |
|---|---|
| HEAD | `6fad2bab` (2026-08-19, `feat(hanok): 사랑채를 40px 올려 사랑마당을 되찾는다`) |
| 범위 | `2026-08-16` 00:00 UTC ~ `2026-08-19` HEAD. first-parent 135 · non-merge 258 · 전체 346 커밋 |
| 방법 | 최신 `origin/main` fast-forward 후 커밋을 날짜·주제로 전수 분류하고, 치명 경로는 **현재 파일**을 읽음. 추정은 적고 실측만 적는다. |
| 이 문서가 하는 일 | 오류·누락·앱 미반영·치명 이슈 + 권장 해결. **코드는 고치지 않는다.** |
| 이 문서가 안 하는 일 | 배포, 크레딧 소모, 에셋 승격, PR 머지 |

사용한 스킬·도구: `AGENTS.md` SSoT, `review-changes`, `explore-codebase`, `debug-issue`, `refactor-safely`(죽은 `SoriSwipeCard`), `frontend-design`/`CONTENT_UI_BIBLE.md`(콘텐츠 크롬), GitHub MCP(열린 PR), `tool/generate_tts.py --dry-run`, `tools/content_factory/validate_content.py --json`.  
`code-review-graph` MCP는 저장소 `.mcp.json`에만 있고 이 Cursor Cloud 세션에는 붙어 있지 않다. 그래프 도구 대신 파일 실독 + 병렬 탐색으로 대체했다.

---

## 0. 한 줄 결론

3일 동안 **콘텐츠·한옥·콘텐츠 UI·백엔드 하드닝이 한꺼번에 main에 들어왔다.**  
지금 학습자가 맞는 치명 구멍은 **코드 부재가 아니라 (1) TTS/책분석이 live에 안 올라간 것, (2) 새 클라 + 구 서버 조합의 무음, (3) 생성된 한옥 자산이 앱 화면에 안 붙은 것, (4) `AGENTS.md` 숫자가 배치 10에서 멈춘 것**이다.

`dc5fa0b8`(#88)이 Android 전역 무음·유닛 편중·문법 Typ 1장 함정을 고쳤다.  
그 직후 **main Analyze가 문법 레벨 칩 탭 1실패로 빨갛다** — 수정은 열린 PR #89에만 있고 HEAD에는 없다.

---

## 1. 지금 당장 (P0)

| # | 증상 | 앱에 보이는가 | 권장 해결 | 담당 |
|---|---|---|---|---|
| P0-1 | TTS 신뢰성 코드는 main에 있고 **live `functions/tts`는 구버전** | 할당량/빈캐시/선점 시 **완전 무음**. 실패 배너 0 | indexes → rules → `firebase deploy --only functions:tts-firebase-functions` → App Check 스모크 | Jin |
| P0-2 | 새 클라 `blockSpeechFallback` + 구 CF | 프리미엄 miss 뒤 OS 폴백까지 차단 → 24시간 무음 | **P0-1과 같이** 배포. 배포 전에는 quota에서 폴백을 막지 말 것 | Jin + 다음 코드 PR |
| P0-3 | 책 한 컷 live Gen2가 구버전. cache ~379건에 원문 | 분석 실패·원문 잔존(프라이버시) | `gcloud functions deploy analyze_korean_text` + `verify_deployed_source.py` → TTL ACTIVE 확인 → Jin 승인 후 legacy cache 삭제 | Jin |
| P0-4 | main CI Analyze 1실패 (`circular_feedback_widget_test` 문법 A2 칩) | 내부테스트 AAB가 quality gate에 막힐 수 있음 | **열린 PR #89를 먼저 머지.** 칩 Key + 테스트가 `onTap`을 직접 호출 | Jin |
| P0-5 | 한옥 V1 생성분 43cr가 원장에 없음 + 앱 미등록 | 별당·서고·소품 9종을 만들어도 학습자는 못 봄 | 먼저 `ledger_append.py --append`(회계). 화면 연결은 Jin 노출 게이트 뒤 | Jin |

---

## 2. 3일 동안 이미 고친 것 (다시 손대지 말 것)

감사 범위 안에서 **끝난 것**. 아래를 재구현하지 않는다.

| 커밋 | 무엇 |
|---|---|
| `dc5fa0b8` #88 | Android `respectSilence` → 벨소리 스트림 제거. `buildAndroidContext()`는 `USAGE_MEDIA`. 설정 토글은 iOS만. 래칫 `test/audio_policy_test.dart` |
| `dc5fa0b8` | 코스 유닛이 레벨 시나리오의 40%를 넘지 못함. 스몰톡/문법 칩에 개수. 빈 카테고리 비활성 |
| `dc5fa0b8` | 문법 Typ는 현재 레벨에 **2장 이상**인 타입만. 1장짜리 함정 드롭다운 숨김 |
| `01bd8849` #83 | 4방향 틴더 덱을 **런타임에서 제거**. 세로 `SoriContentFeed`가 정본. `SoriSwipeCard` import 호출자 0 |
| `58379721` #87 | 스플래시 전 경로에서 마이그레이션·스트릭·오디오·책이미지·클라우드를 `runApp()` 뒤로 |
| `536243c8` #85 | Play 자동업로드는 **내부테스트(`internal`)만** |
| `6c49eeb1` | `ios/Runner/GoogleService-Info.plist` 추적. Xcode Cloud 아카이브 가능. `firebase_options.dart`와 키 일치(공개 앱 식별자) |
| `6fad2bab` / `670f43a6` | 지도 z순서 원근 수정 + 사랑채 `canvasOffsetY: -40` |
| `8bbaf9e7` #81 | 레시피 러너 무단 지출 구멍(DRAFT/Seedream/참조 0장) 차단 |
| `9939727a` + PR-D | A2 가구 전역 누수 수정. `kRoomFurnishingPool`은 사랑방만 |
| 배치 11–16 | 책가도 90칸 시나리오 채움. 카탈로그는 아래 §7 |
| TTS Storage (세션 로그 2026-08-19) | 합성 후 **missing 0**. 로컬 dry-run **11,438쌍** (여 10,234 / 남 1,204) |
| `4b5f5ccf` | 배경 없는 에셋 교체 + 미사용 삭제 |
| `e27bdeb3` #65 | 미용실·은행 포스터로 카페·사무실 대체 종료 |
| 계정/단어장/백엔드 로컬 | Google·Apple 연동, Vokabelheft, 할당량 환급·TTL·선점은 **repo에 있음**(live는 §1) |

---

## 3. 치명·오류 — 코드가 아직 가진 것

심각도: **CRITICAL** = 소리/프라이버시/릴리스 정지. **HIGH** = 학습자가 매일 맞음. **MEDIUM** = 품질·회계·문서.

### C1. TTS 4단 폴백이 독일어로 한국어를 읽는다 — CRITICAL

**근거.** `lib/services/tts_service.dart`

- `_applyFallbackLanguage`는 `setLanguage` **반환값을 보지 않고** 성공으로 메모한다 (`950-952`). ko-KR이 실패해도 `_fallbackLanguage`가 고정되고 재시도가 끊긴다.
- `_trySelectKoreanVoice`는 `getVoices`를 **250ms 한 번**만 다시 본다 (`962-964`). Chrome은 목록을 늦게 채워 빈 목록 → 독일어 기본 음성.
- `setVoice`로 한 번 고정한 음성은 언어가 바뀌어도 풀리지 않는다 (`916`).
- `flutter_tts` 4단은 그대로 (`_startFallback`).

**학습자 증상.** “전부 das”, 웹에서 독일어 기계음.

**권장.** `docs/CONTENT_UIUX_FINISH_PLAN_2026-08-19.md` Phase 1.2를 그대로 실행.

1. `setLanguage`가 성공일 때만 `_fallbackLanguage`를 기록.
2. 언어 변경 시 `setVoice` 해제 후 재발급.
3. `getVoices`를 최대 ~2초 지수 백오프.
4. 코퍼스·Storage가 안정된 뒤에만 4단을 제거(계획 확정: 무음 + 보이는 배너).

### C2. 할당량 소진 = 완전 무음, UI 0 — CRITICAL

**근거.**

- `takeCallableAudio`가 `blockQuota` / `blockUnavailable`에서 `TtsSynthesisBlocked` (`757-765`).
- 재생 경로가 `blockSpeechFallback`이면 OS 폴백을 안 탄다 (`288-290`).
- `TtsService.lastError`는 서비스·테스트만 쓴다. **`lib/screens`·`lib/widgets` 읽기 0.**
- `tts_unavailable_banner.dart` 없음.

한글 탭은 자모 ~40개를 프리페치하고, 듣기 한 편이 수십 줄이다. 한도 30 synth/기기/일이면 한 세션에 하루치가 나간다.

**권장.**

1. **먼저 P0-1 배포** — 새 CF는 빈 캐시 거절·환급·선점이 있다.
2. 배포 전 임시: `resource-exhausted`에서 폴백을 막지 말 것(계획 1.3).
3. `ValueNotifier<TtsUnavailable?>` + 셸 배너 1개. ARB 양쪽에 `ttsUnavailableQuota` / `Offline` / `Pending` / `ChannelOff` / `ttsRetry`.
4. 프리페치는 성공한 키만 `_prefetchAttempted`에 넣고, Storage `getData`에 8초 시한.

### C3. 새 클라 vs 구 서버 — CRITICAL (운영)

레포의 `functions/tts`는 12초 timeout · 7초 합성 · 빈 MPEG 거절 · fail-closed 선점 · 환급이 **테스트 23/23**까지 있다.  
세션 로그(2026-08-17 PR #59) 이후 **deploy 기록이 없다.** `AGENTS.md` 운영 게이트도 그대로다.

**권장 순서 (바꾸지 말 것).**

```
firestore:indexes (TTL ACTIVE 확인)
→ firestore:rules + storage
→ functions:tts-firebase-functions
→ callable 스모크 (auth / App Check / 빈버퍼 / 동시 재시도 / 12s·7s)
→ analyze_korean_text Gen2 + verify_deployed_source.py
→ 책 스모크 DE/EN
→ legacy translation_cache 삭제는 별도 Jin 승인
```

### C4. 책 한 컷 live가 구버전 — CRITICAL (프라이버시)

레포 `functions/analyze_korean_text`는 source-free cache(`ko-source-v3-ttl`, 30일), 선점, 환급, DeepL 8초가 있다.  
`AGENTS.md`: live Gen2는 모듈 빠진 구버전, cache 379건에 `src`, TTL 미확인.

**권장.** C3 순서 5–7. 클라 Rules는 이미 `/cache/**` · `translation_cache` 거절 (`firestore.rules` 604-629). **서버 잔존 문서**가 문제다.

### C5. main CI 1실패 — HIGH (릴리스 정지)

`dc5fa0b8`가 문법 칩을 `A2 · 46`처럼 개수와 붙여, 가로 ListView 끝에서 `ensureVisible`+`tap`이 히트를 못 한다.  
재현: `6c49eeb1` workflow_dispatch. `test/circular_feedback_widget_test.dart` — `grammar level filter resets the current study interaction set`.

**권장.** [PR #89](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/pull/89) 머지. 칩 `Key('grammar-level-$lvl')`, 테스트는 `onTap` 직접 호출. 이 감사는 그 코드를 복사하지 않는다.

---

## 4. 앱 반영 누락 (만들어졌는데 학습자가 못 봄)

### M1. 살아 있는 한옥 V1 — UI 호출자 0 — HIGH (제품 게이트)

| 심볼 | `lib/screens` | `lib/widgets` | 실제 호출 |
|---|---|---|---|
| `HanokStateService` | 0 | 0 | `cloud_sync`, `account_reconciliation` |
| `HanokExperienceProjector` | 0 | 0 | `hanok_cutover_service`만 |
| `HanokCutoverService.ensureCutover` | 0 | 0 | **테스트만** |

학습자가 보는 길: `HanokWorldScreen` → `HanokStageService`(레거시 팩 비율) → B1 25% 전 `MadangBackground` / 이후 `PersonalHanokMap`.  
A1 16장 WebP는 pubspec에 있으나 `A1HanokConstructionMap`은 QA/프리뷰만. grant catalog `publishedGrants: []`.

**권장.** Jin이 “레거시 유지”를 고르면 **코드 변경 없음**. 연결하려면 `HanokWorldScreen`에 cutover + projector를 한 번에 넣고, 레거시 비율과 86 segment 분모가 어긋나지 않는지 골든으로 잠근다. 중간만 열면 집이 갑자기 낮아진다.

### M2. 2026-08-19 생성분 — 앱 0, 원장 0 — HIGH

| 산출 | 위치 | 빠진 곳 |
|---|---|---|
| 별당·서고 완성 PNG | `assets_unused/pending_review/estate_stages/{byeoldang,seogo}/cut/` | 카탈로그, 지도 레이어, pubspec, 원장 |
| 사랑방 소품 9종 | `assets_unused/pending_review/asset_recipe/decoration_*/` | `kAvailableDecorations`, ARB `decorName*`, `assets/illustrations/decorations/`, 원장 |
| A2 외관 오버레이 | `pending_review/estate_overlays/cut/` | `lib/` 렌더러. orphan-guard가 pubspec-only를 막음 |

원장 초안 12개 × **43.0cr**이 `HANOK_V1_ASSET_PROVENANCE.json`에 없다. 러너 `--ingest`는 게이트만 하고 `ledger_append.py --append`는 수동이다.

**권장.**

1. Jin이 cut PNG를 눈으로 본 뒤 `ledger_append.py --append` (회계를 화면보다 먼저).
2. 소품 9: `decorations/` 승격 + 카탈로그 + DE/EN ARB. orphan-guard와 같이.
3. 별당·서고: s1–s4 단계 JSON + 지도 구역(레시피가 경고한 10px 겹침 조정) 후 승격.
4. A2 오버레이: 렌더러와 pubspec을 **같은 커밋**에. 장독 A/B는 Jin 선택.

### M3. 번들에 있는데 안 그리는 한옥 — MEDIUM

- `personal_hanok_v2/map/stages/` 14 PNG — orphan-guard 앵커만, 렌더러 0.
- A1 16 states — 런타임 번들, 생산 화면 0.

**권장.** 노출 게이트 전까지 번들에서 빼거나, 게이트 때 렌더러를 붙인다. 보이지 않는 PNG를 계속 실으면 APK만 커진다.

### M4. 사랑채 40px — 지도만 옮김 — MEDIUM

`personal_hanok_catalog.dart` `canvasOffsetY: -40` + `visualBounds.top` .533→.500.  
`personal_hanok_unlock_reveal.dart`는 같은 PNG를 **오프셋 없이** `Image.asset` (`209-213`). 잠금해제 한 순간 건물이 40px 아래로 보인다.  
A1 시공 화면은 소켓이 원본 좌표라 **의도적으로** 안 옮겼다(세션 로그). `kPersonalHanokZones` 사랑방 히트박스도 그대로.

**권장.** unlock reveal에 `canvasOffsetY`를 같은 비율로 적용. 히트박스는 실기기에서 탭이 빗나가면 그때 `.500`에 맞춘다. A1↔지도 40px는 Jin이 남긴 선택 — 문서에만 남겨도 된다.

### M5. 콘텐츠 UI 계획 vs HEAD — HIGH / MEDIUM

`8e0870ce` 계획서는 `29842a50` 실측이다. 그 뒤 #88이 소리 라우팅·필터·배치만 고쳤다. **아직 열린 것:**

| 이슈 | 심각 | 지금 코드 | 권장 |
|---|---|---|---|
| 피드 더블탭 좋아요가 스피커와 충돌 | HIGH | `content_feed.dart` `Listener(onPointerUp)` 280ms, 카드 전체를 감쌈 (`126-138`, `208-209`) | 좋아요는 하트 히트박스만. 스피커는 arena 참가자. 세로 커밋 64/700 → 계획값 88/850 |
| 웹 TTS/공유 `File` | HIGH (웹 개발) | `tts_service.dart`에 `kIsWeb` 0. `_ensureCacheDir`이 `getApplicationCacheDirectory`. 공유는 `getTemporaryDirectory` 후 `catch (_) {}` | 웹은 메모리 LRU. 공유 실패는 배너. 텍스트 덤프 금지(이미 그렇게 침묵) |
| 책갈피 토스트 큐 | MEDIUM | `wordbook_add.dart` hide 직후 show. `notify:false`는 문법·스몰톡 2곳 | `removeCurrentSnackBar()` + 기본 `notify:false`. 스탬프만 |
| 문법 Listen 키 드리프트 | MEDIUM | `GrammarStudyCopy.speakKorean`은 공백 join. `generate_tts.py`는 CSV ` / ` 원문 해시 | 버튼은 `splitStudyPhrases`의 **보이는 한 줄만**. `speakKorean` 삭제(계획 확정) |
| `word_relations.json` TTS 미수집 | MEDIUM | `generate_tts.py`에 문자열 없음. 클러스터 66 | collector에 한국어 노드만 넣고 합성 |
| 문법 필터 빈 결과 | MEDIUM | 시트가 안 닫히고 스낵바만 (`1106-1115`) | 적용 불가 시 시트 유지 + 칩 비활성. 검색 허브는 Phase 5로 미뤄도 됨 |
| 문법 난이도 `Leicht`/`Schwer` | MEDIUM | 하드코딩 DE, TODO 주석 `1079-1084` | ARB 양쪽 |
| 죽은 덱 위젯 | LOW | `swipe_card.dart`, `deck_action_bar.dart`, `deck_coach.dart` | 호출자 0 확인 뒤 삭제 |
| 타이포 31종 리터럴 | MEDIUM | 계획 Phase 3–4. 화면 raw `TextStyle` 다수 | `soriStudyScale`/`soriFillSize` 제거, ambient `TextScaler` 하나. 바이블 §3 |
| 듣기 “지금 재생 + 교체” | MEDIUM | #88 메시지에 있었으나 listening 파일이 그 커밋에 없음 | 책가도에서 재생 중 바만. 새 플레이어 라우트와 합치지 말 것 |

### M6. 시작 레이스 — MEDIUM

`58379721` 이후 UI가 클라우드보다 먼저 열린다. 스플래시 2초 고정. Storage 공개 mp3는 인증 없이 된다. **동적 합성**은 uid+App Check가 필요하다.  
`ensureSignedIn` 전에 탭하면 C2와 겹쳐 무음이 난다.

**권장.** 동적 TTS 직전에 `ensureSignedIn`을 5초 바운드로 한 번 기다리거나, 배너 `ttsUnavailablePending`. 프리미엄 경로를 스플래시 앞으로 되돌리지는 말 것.

---

## 5. 문서가 앱보다 멈춘 곳 — HIGH (다음 세션이 잘못 움직임)

`AGENTS.md` “현재 진행 중인 작업”이 **배치 10 / 시나리오 264 / TTS 6,321**에서 끝난다. HEAD 실측:

| 항목 | AGENTS.md | HEAD `6fad2bab` |
|---|---|---|
| 다음 배치 | Batch 11 | **Batch 16까지 머지. 다음 번호는 17** |
| scenario | 264 | **392** (A1 85 · A2 80 · B1 73 · B2 68 · C1 45 · C2 41) |
| vocab | 2196 | **2292** |
| grammar | 206 | **214** |
| smalltalk | 377 | **393** |
| cloze | 1538 | **1634** |
| TTS corpus | 6,321 | **11,438** (Storage missing 0, 세션 로그) |
| 한옥 V1 UI | 호출자 0 | **여전히 0** (이건 맞음) |
| TTS/책 live 배포 | 미배포 | **여전히 미배포** (맞음) |

C1/C2 스몰톡은 카테고리 상당수가 비어 칩이 비활성이다. 버그가 아니라 **콘텐츠 공백**.

**권장.** 다음 문서-only 커밋에서 AGENTS 체크리스트 숫자만 맞춘다. 이 감사는 AGENTS를 고치지 않았다(파일만 올리라는 지시).

`CONTENT_UI_BIBLE.md`는 틴더를 폐기했다고 하고, `HANDOFF_UI_OVERHAUL_2` §1-1·§1-2는 아직 4방향을 적는다. 바이블이 이긴다. 핸드오프 상단에 “대체됨” 한 줄이면 충분하다.

---

## 6. 커밋을 하루·주제별로 읽은 결과

346개를 한 줄씩 나열하지 않는다. first-parent와 non-merge를 날짜·주제로 읽고, **문제되거나 앱에 안 붙은 커밋만** 적는다. 무해한 docs/golden/merge는 생략.

### 2026-08-19 (first-parent 12)

| 해시 | 판정 |
|---|---|
| `6fad2bab` 사랑채 40px | 지도는 고침. unlock/A1/히트박스는 §M4 |
| `6c49eeb1` iOS plist | 필요. Firebase 공개 식별자. **Analyze 1실패를 재현한 커밋이기도 함** |
| `dc5fa0b8` #88 | 소리·배치·Typ는 고침. 칩 라벨이 CI 탭을 깨움 → #89 |
| `8e0870ce` UIUX 계획 | 정본. 실행은 거의 남음 |
| `670f43a6` z순서 |  pal. 행랑채 27.9% 가림 해소 |
| `5c2a2ba7` 07/08 + 별당·서고 + 소품 9 | A1 07–10은 승격됨. **건물·소품은 pending_review** |
| `29842a50` Ponytail/graph | 도구. 이 세션 MCP는 미연결 |
| `536243c8` Play internal-only | 계약 맞음. `PLAY_INTERNAL_RELEASE_ENABLED` + 서명 시크릿 없으면 잡은 안 돈다 |
| `01bd8849` 틴더 제거 | 런타임 완료. 죽은 위젯 파일 잔존 |
| `58379721` 시작 지연 | 스플래시는 빨라짐. 동적 TTS 레이스 §M6 |
| `8bbaf9e7` 러너 지출 | 게이트 닫힘. append는 여전히 수동 |
| `d1406210` 한옥 감사 핸드오프 | 문서 |

### 2026-08-18

| 클러스터 | 해시(대표) | 판정 |
|---|---|---|
| 책가도 15칸 + 배치 11–16 | `b25a81b2` … `ad80baea` | **앱 데이터에 있음.** 책가도 UI(`e4ac3464`) 배선됨. C1/C2 스몰톡은 빈 칸이 남음 |
| 배치 12 grammarIntents 키 | `c42d085c` | `grammarId`→`id`. 매니페스트 불일치 해소 |
| Sori Deck 3.0 | `abf9e3ff` | 다음날 #83이 세로 피드로 대체. 물리 코드는 유산 |
| 한옥 PR-B~D + Phase 2 | `e50fd520`…`770bd48b` `145e7928` | 데이터·러너 main. **PR-E/F·Phase 3 생성 없음** |
| A2 가구 12 + 픽커 | `f97def46` `9939727a` | 사랑방 경로 고정. 전역 누수 수정됨 |
| A2 외관 4 | `89ab0582` | 생성만. 렌더러 없음 |
| B1/B2 건물 단계 | `c87a5d77` `81979b39` | allowlist·골조. 라이브 맵 단계 렌더 없음 |
| 사이트 App Store CTA | #77 #79 `68001a76` | 공개 버튼은 `#tester-access` 폼. TestFlight URL은 코드에만 |
| CI concurrency | `a0113ef4` `c4271f75` | workflow_dispatch·website 그룹 분리 |
| 스플래시 로고 크롭 | `1cd2db12` | Android 네이티브 수정 |
| GA4 퍼널 6 | `47fd325c` | 코드. DebugView 실기기는 Jin |
| 배경 없는 에셋 | `4b5f5ccf` | 교체 완료 |
| 골든 vocab_packs | `3541c452` | 테스트만 |

### 2026-08-17 (커밋 212 — 가장 붐빔)

| 클러스터 | 판정 |
|---|---|
| 시나리오 6샤드 + LRU 2 | 앱에 있음. 단일 `scenarios.json` 없음. 정본 |
| 책가도 12→18→15칸 재결정 | 최종은 18일 15칸. 중간 12/18 문서는 stale 가능 |
| 배치 09/10 승격 + Batch 10 문장 재작성 | 앱에 있음 |
| 배치 11+12 시나리오·C1/C2 유닛 | 앱에 있음. 처음엔 `[skip ci]` |
| 문법 스와이프 전용 → 다음날 피드로 재변경 | 최종은 #83 세로 피드 |
| 한옥 A1 16 승격 + D1 rename + PR4 파이프 | A1 states는 번들. **생산 UI 없음** |
| Codex A1 05–10 파일럿 | `pending_review`. 07–10은 19일 재합성으로 대체 |
| TTS 도구 6샤드 (`53595787`) | collector는 샤드 읽음. `word_relations`는 여전히 빠짐 |
| 듣기 카드 50장 | 에셋 확정. 책가도 카드로 연결 |
| TTS wait/quota #59 | **클라+함수 코드만. CF 미배포** |
| 단어망 / 단어장 스튜디오 / 파트너 퀘스트 | 앱 경로 있음 |
| 수많은 no-op 브랜치 머지 | 로그 문구만. 기능 중복 없음으로 확인된 것들이 많음 |
| CI PR 범위 테스트 | draft skip + import 폐포. main은 전체. **선택기 오류는 fail-open** |

### 2026-08-16

| 클러스터 | 판정 |
|---|---|
| 한옥 V1 PR1–PR3 | 계약·생산 코어·dark-launch **코드만**. UI 0 |
| 배치 06 + 07/08 초안→승격 | 앱에 있음 |
| 문화어 사이트 + 모바일 언어 | production 검증 `fc85a997` |
| 시나리오 퀘스트 UI 통일 | 앱에 있음 |
| B2 문법 체크포인트 입력 | 앱에 있음 |
| 책 OCR 하드닝 | 레포 완료. live Gen2는 §C4 |
| 백엔드 신뢰성 1–2 + 유료 4결함 | 레포 완료. live 미배포 |
| 계정 링크/삭제 | 클라 복구. 실기기 SHA·Apple `.p8`는 Jin |
| Sites→소유 Worker | 사이트 전환 완료 |
| Deck 제스처 PR #28 | 이후 Deck 3.0 → 피드로 두 번 뒤집힘. 최종은 세로 피드 |
| Appstore-v24 / Android 1121–1122 | 빌드 번호만. 그 뒤 콘텐츠가 더 들어옴 |

---

## 7. 카탈로그·코퍼스 실측 (이 감사 세션)

```
scenario 392   vocab 2292   grammar 214   smalltalk phrases 393
cloze items 1634
TTS dry-run 11,438  (female 10,234 / male 1,204)
validate_content.py --json  →  ok: true, issues: []
asset_orphan_guard + hanok_v1_asset_provenance  →  하위 에이전트 17/17
```

satz/quest 전체 재집계는 `validate_content.py`가 inventory 플래그를 안 받아 이 세션에서 다시 안 돌렸다. 탐색 에이전트 집계(satz 2187 · scenarioQuest 1629)는 참고. 필요하면 `tools/content_factory` 인벤토리 스크립트를 다음 세션에서 한 번 더 돌린다.

---

## 8. 권장 해결 — 실행 순서

코드 PR과 운영을 섞지 말 것. 크레딧이 드는 생성은 맨 뒤.

### Jin (운영, 코드 없음)

1. **PR #89 머지** — main 초록이 돌아와야 Play 내부테스트 자동업로드가 다시 열린다.
2. **TTS·Rules 배포** — §C3 순서. 배포 전후에 “진동 모드 Android + 오늘의 글자 + 한글 Pronounce”를 미디어 볼륨으로 확인.
3. **책 한 컷 Gen2** — 소스 SHA 검증 후, cache 379 삭제는 별도 승인.
4. **한옥 노출** — 레거시 유지 vs V1 연결. 연결 전에는 별당/서고를 지도에 넣지 말 것.
5. **pending 9+2 그림** — 눈으로 본 뒤 원장 append → 그때만 승격.
6. Play 변수 `PLAY_INTERNAL_RELEASE_ENABLED`와 서명 시크릿 확인. TestFlight는 수동.
7. 실기기: 피드 더블탭×스피커, 사랑채 잠금해제 40px, 문법 필터.

### 다음 코드 PR (작은 것부터)

| PR | 내용 | 이유 |
|---|---|---|
| A | TTS 폴백 정직 + quota에서 침묵 금지 + `kIsWeb` 가드 + 배너 | 매일 소리 |
| B | 피드 좋아요를 하트에만. 세로 커밋 임계 | 스피커가 좋아요를 쏨 |
| C | 책갈피 기본 무토스트. 문법 빈 필터 시트. `Leicht`/`Schwer` ARB | 손맛 |
| D | Listen = 보이는 예문 1개. TTS collector에 `word_relations` | 키 드리프트 |
| E | unlock reveal에 `canvasOffsetY` | 한 프레임 점프 |
| F | 죽은 `SoriSwipeCard` 트리 삭제 | 다음 UI가 다시 틴더를 만지지 못하게 |
| G | AGENTS 체크리스트 숫자 + 바이블/핸드오프 한 줄 정정 | 세션이 Batch 11을 다시 안 만들게 |

한옥 승격·V1 화면 연결은 **Jin 게이트 없이 시작하지 말 것.**

### 하지 말 것

- 레거시 한옥을 임의로 V1 분모에 갈아끼우기
- pending_review를 pubspec만 넣고 올리기 (orphan-guard가 막음)
- TTS 4단을 코퍼스/배포 전에 삭제 (무음만 남음)
- 4방향 틴더를 다시 넣기 (`CONTENT_UI_BIBLE`이 Overhaul 2를 대체)
- `chore/hanok-pr-e-prep` / `chore/hanok-asset-ledger-backfill` 재개
- 이 감사에 적힌 수정을 같은 커밋에 섞기

---

## 9. 열린 PR (감사 시점)

| PR | 제목 | 관계 |
|---|---|---|
| [#89](https://github.com/Sujin-Arin-DataWorld/ko_lernen_app/pull/89) | 문법 레벨 칩 탭 → Analyze 1실패 수정 | **main 빨간불. 먼저 머지** |

다른 열린 수정 PR은 이 조회에서 없음.

---

## 10. 검증 기록 (이 세션)

- `git fetch origin main` → local을 `6fad2bab`로 fast-forward
- `git log --since=2026-08-16` 분류: content 77 · docs 62 · hanok 48 · fix 41 · ops 13 · feat 13 · other 16 (non-merge)
- `python3 tool/generate_tts.py --dry-run` → 11,438쌍
- `python3 tools/content_factory/validate_content.py --json` → `ok: true`
- 시나리오 샤드 파일 카운트 392, vocab CSV 2292, grammar 214
- `TtsService.lastError` 위젯 읽기 0 (`lib/` grep)
- `HanokCutoverService` production 호출 0
- GitHub MCP: open PR #89 only
- 하위 탐색: 콘텐츠 UI 잔여, 한옥 배선, TTS/CI/백엔드 3축

코드·에셋·설정은 이 감사에서 변경하지 않았다.
