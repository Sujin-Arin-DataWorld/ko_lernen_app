# 결함 사냥 (defect-hunt) — 2026-07-01

> 다차원 finder → **적대적 verify(기본 REJECTED, 구체적 트리거 있어야 CONFIRMED)** 워크플로우 2회 + Opus 직접 결정적 데이터/패턴 검사.
> §0: 코드/데이터 결함만 위임(언어 자연스러움은 직접). 각 CONFIRMED는 실제 코드 대조 완료.

## 요약

| 라운드 | raw | CONFIRMED | 수정 | 비고 |
|---|---|---|---|---|
| 신규 게임 코드 (4차원) | 3 | 1 | ✅ | daily_challenge 크래시 |
| 코어+gye+결제 (5차원) | 17 | 13 | 6 ✅ / 7 보고 | 아래 |
| 데이터 무결성 (직접) | — | 0 | — | cloze/satz/kkeunmari/vocab/scenarios 결함 0 |

**총 CONFIRMED 14 → 수정 7(커밋) · 보고 7(Jin/후속).** 거짓양성은 적대적 verify가 전부 기각.

### 진행 갱신 (후속 커밋)
- **#6 매칭 소프트락 · #12 all-in 주경계** → ✅ 수정·푸시 (`b65e6d4`).
- **#2 memberCount ±1 제약 · #10 feed type 화이트리스트** → firestore.rules에 **diff 반영**(아래 커밋). ⚠️ **미테스트 — Jin이 `firebase emulators` 검증 후 `firebase deploy --only firestore:rules`**. 절대 10명 상한(#2)·연령(#7)·계 상한(#11)은 여전히 **CF 필요**.
- **#3 정지멤버 자가해제** → 순수 rules로 완결 불가(삭제 후 재생성). 권장 설계 = **CF/owner만 쓰는 `bans/{uid}` doc + `isActiveGyeMember`가 확인** (rules+CF 동반, Jin). 미반영.

## ✅ 수정 완료 (커밋·푸시)

| # | 심각도 | 위치 | 결함 | 커밋 |
|---|---|---|---|---|
| A | HIGH | daily_challenge_screen.dart | 완료 시 RangeError(`_idx==length && _outcome==null` 창) | `6e0cdec` |
| 1 | 🔴 CRIT | learning_path_screen.dart:123 | 프리미엄 게이트 우회(경로가 A2/B1/B2 게이트 없이 오픈) | `4e07b74` |
| 4 | 🔴 HIGH | home_screen.dart:502 | 홈 경로노드 프리미엄 우회 | `4e07b74` |
| 8 | MED | premium_service.dart:80 | 로그아웃 시 `_boundUid` 미리셋 → 이전 계정 프리미엄 잔존 | `4e07b74` |
| 5 | MED | kkeunmari_screen.dart:119 | 빈 풀 pickStart RangeError(무한 스피너) | `4e07b74` |
| 9 | MED | book_capture_screen.dart:87 | await 후 setState 4곳 mounted 가드 없음(dispose 크래시) | `4e07b74` |
| 13 | LOW | book_result_screen.dart:256 | 다이얼로그 TextEditingController 미dispose 누수 | `4e07b74` |

## 🔧 보고 — 미수정 (Jin 영역: 배포/에뮬레이터/CF, 또는 후속 클라 수정)

### 보안 — firestore.rules (Jin: `firebase emulators` 테스트 후 배포 필수. 미테스트 rules는 배포 금지)

**#2 (HIGH) — 10명 상한 서버 미강제 · memberCount 임의 조작 (line 53)**
- 현: `allow update: if isGyeOwner || (auth!=null && affectedKeys.hasOnly(['memberCount']) && memberCount is int)` → **아무 인증자나** memberCount를 임의값으로. 멤버 `create`(63-66)는 nickname만 검증 → 11번째+ 가입 가능. "3e Cloud Function이 강제"라는 주석과 달리 그런 CF 없음.
- 제안: memberCount 쓰기를 **CF/owner 전용**으로 축소(멤버 클라가 직접 못 씀). **10명 상한은 rules로 카운트 불가 → CF 트랜잭션(on member create)으로 강제** 필요.

**#3 (HIGH) — 정지 멤버 자가 해제 (line 73)**
- 현: 멤버 `delete`는 본인 허용 + `create`는 status 미검증 → 정지된 사용자가 leaveGye(자기 doc 삭제)→joinGye(status:'active'로 재생성)로 **모더레이션 정지 무력화**.
- 제안: 정지 기록을 **오프너/CF만 쓰는 별도 doc**(`gye/{id}/suspended/{uid}`)에 저장하고 `isActiveGyeMember`가 그걸 확인(자기 member doc 삭제/재생성으로 못 지움). rules+CF 조합.

**#10 (LOW) — feed create 무검증 → 임의 콘텐츠 주입 (line 79)**
- 현: 모든 스티커/응원/반응이 `feed`에 add. create 규칙은 `isActiveGyeMember && actorUid==auth.uid`만 검증 — `type`/`payload`/`stickerCode` 무검증. `stickers` 컬렉션의 1-30 검증은 **死코드**(아무도 안 씀). 활성 멤버가 가짜 `goal_achieved`/`all_in`·범위 밖 code·임의 텍스트 주입 가능.
- 제안: feed `create`에서 `type`를 **허용 enum**(pack_cleared·quest·level_up·sticker·cheer·reaction·goal_achieved·all_in)으로 제한 + sticker code 범위·payload 크기 검증. (⚠️ 정당 타입 누락 시 기능 파손 → 에뮬레이터 검증 필수.)

### CF 강제 필요 (Jin)

**#7 (MED) — 16+ 연령게이트 클라이언트-only (gye_service.dart:159)** — rules/CF가 나이를 모름. 생년 미설정(birthYear==0 → isUnderMinAge=false) 또는 수정된 클라로 우회. 현실적 통제 = 클라 게이트 + 스토어 연령등급. 완전 서버강제는 DOB 저장(민감) 필요 → **문서화 + 스토어 등급으로 관리** 권장.

**#11 (LOW) — 유저당 계 3개 상한 클라이언트-only (gye_service.dart:174)** — 로컬 캐시 검사뿐. rules에 per-user 한도 없음 → 수정 클라로 무제한 가입. **CF로 gyeIds 카운트 강제** 필요(#2와 동류).

### 후속 클라 수정 (내가 할 수 있음 — 원하면 진행)

**#6 (MED) — 짝맞추기 소프트락 (custom_pack_matching_screen.dart:225)**
- 같은 뜻 단어 2개(예: 가다·오다 → "gehen")가 한 라운드에 들어오면, 하나 매칭 시 **같은 뜻 오른쪽 타일 전부 비활성**(predicate가 gloss 문자열로 판정) → 나머지 단어 매칭 불가 → `_roundDone` 영원히 false → 라운드 완료 불가(닫기로만 탈출). quickAdd는 한국어로만 dedup → 동일 뜻 흔함.
- 제안: 오른쪽 타일 disable을 **gloss 문자열이 아니라 매칭된 특정 페어(인스턴스) 기준**으로. 또는 `_newRound`가 **동일 translationDe 중복을 라운드에서 배제**.

**#12 (LOW) — all-in 주(週) 경계 불일치 (gye_service.dart:445)**
- `_weekKey`는 Jan1 기준 7일 floor인데 `weekly_goal_rollover`는 매주 월요일(`0 0 * * 1`) 리셋 → 경계 어긋나 같은 버킷 내 두 번째 정당 all-in이 dedup docId 충돌로 조용히 누락(feed update:if false).
- 제안: `_weekKey`를 **월요일 기준 ISO 주**로 바꿔 CF 롤오버와 정렬.

## 방법론 노트
- 적대적 verify가 raw 20건 중 6건을 REJECTED(거짓양성) → 신뢰도 높은 CONFIRMED만 남김.
- firestore.rules/CF는 **에뮬레이터 미실행**(§0: 코드/CLI로 판정 불가) → 실동작 검증은 Jin. 위 제안은 코드 대조 기반.
