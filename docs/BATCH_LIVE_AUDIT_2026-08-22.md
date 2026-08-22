# Batch 01–20 라이브 승격 감사

감사일: 2026-08-22

실행 정본: `python tools/content_factory/audit_batch_live_promotion.py --check`

기계 판독 원장: `tools/content_factory/review/batch_live_projection_20260822.json`

## 결론

활성 Batch 매니페스트가 추적하는 안정 ID **6,265개 중 6,265개**가 앱의
`assets/data` 실데이터에 존재한다. 감사기는 초안과 리뷰 CSV의 ID 집합도 서로
같은지 검사하며, 인용하지 않은 쉼표로 생기는 숨은 CSV 열도 오류로 처리한다.
시나리오는 ID뿐 아니라 `shelf`, `backdrop`, `curriculum_manifest.json`의
`contentLink`까지 확인한다. 보조 콘텐츠는 media phrase, word relation,
grammar pattern, Kkeunmari, Silben, culture note의 각 정본 키로 추적한다.

| 매니페스트 | 추적 ID | 라이브 ID | 승인 계보 |
|---|---:|---:|---|
| Batch 01 | 96 | 96 | structured Jin approval |
| Batch 02 | 96 | 96 | structured Jin approval |
| Batch 03 | 126 | 126 | structured Jin approval |
| Batch 04 | 16 | 16 | structured Jin approval |
| Batch 05 | 504 | 504 | structured Jin approval |
| Batch 06 | 68 | 68 | structured Jin approval |
| Batch 07 partner/family | 1,374 | 1,374 | structured Jin approval |
| Batch 08 partner/family | 28 | 28 | structured Jin approval |
| Batch 09 4x | 1,764 | 1,764 | structured Jin approval |
| Batch 10 4x | 814 | 814 | structured Jin approval |
| Batch 11 | 36 | 36 | legacy `promotedAt` evidence |
| Batch 12 | 312 | 312 | structured Jin approval |
| Batch 13 | 12 | 12 | legacy `promotedAt` evidence |
| Batch 14 | 28 | 28 | legacy `promotedAt` evidence |
| Batch 15 | 28 | 28 | legacy `promotedAt` evidence |
| Batch 16 | 24 | 24 | legacy `promotedAt` evidence |
| Batch 17 | 144 | 144 | structured Jin approval |
| Batch 18 | 132 | 132 | structured Jin approval |
| Batch 19 | 345 | 345 | structured Jin approval |
| Batch 20 | 318 | 318 | structured Jin approval |

`batch_07_4x_manifest.json`과 `batch_08_4x_manifest.json`은 후속 Batch 09·10으로
대체된 `superseded` 기록이다. `batch_07_manifest.json`과
`batch_08_manifest.json`은 두 작업 계보를 묶는 `index`라 자체 레코드가 없다.

## 현재 앱 실데이터와 로더 결과

| 유형 | A1 | A2 | B1 | B2 | C1 | C2 | 전체 |
|---|---:|---:|---:|---:|---:|---:|---:|
| 어휘 카드 | 427 | 479 | 489 | 545 | 240 | 240 | 2,420 |
| 문법 카드 | 41 | 50 | 50 | 57 | 23 | 23 | 244 |
| 시나리오 | 87 | 82 | 75 | 73 | 50 | 46 | 413 |
| 스몰토크 | 90 | 83 | 78 | 118 | 77 | 76 | 522 |
| 빈칸 | 350 | 283 | 281 | 391 | 250 | 250 | 1,805 |
| 문장 만들기 | 338 | 468 | 474 | 549 | 252 | 252 | 2,333 |
| 발음 원문 | 10 | 10 | 10 | 18 | 18 | 18 | 84 |
| 미디어 표현 | 35 | 53 | 12 | 12 | 12 | 12 | 136 |
| 단어 관계 | 50 | 16 | 16 | 16 | 8 | 8 | 114 |
| 문법 패턴 | 11 | 16 | 7 | 3 | 3 | 3 | 43 |
| 음절 퍼즐 | 20 | 20 | 20 | 20 | 20 | 20 | 120 |

끝말잇기는 정확 레벨 기준 A1 1,491, A2 1,051, B1 61, B2 69, C1 28,
C2 28개이며 누적 로더로 C2 학습자에게 2,728개가 보인다. 문화 노트 36개는
모두 실제 어휘 표제어와 결합되며 레벨마다 최소 1개가 있다.

`audit_game_loader_coverage.py --check`는 위 수량 외에도 다음을 검사한다.

- 시나리오·스몰토크·빈칸·문장 만들기의 코스 단원별 최소 수량과 미연결 ID 0개
- 스몰토크의 레벨·카테고리별 최소 2개
- 발음의 정확 레벨 최소 8개와 누적 노출
- 어휘·문법·음절·끝말잇기·미디어·단어 관계·책 분석 문법 패턴·문화 노트의 실제 Dart 로더/화면 호출 지점
- 문화 노트 표제어와 라이브 어휘의 정확 결합

오늘의 단어는 `ReviewDeckService.todaySelectionForLevel`이 번들 어휘를 현재
CEFR 레벨로 제한한다. C1 학습자에게 A1 `안녕하세요`가 신규·연체 복습으로
섞이지 않는 회귀 테스트도 유지한다.

## 계보와 문구 판정 경계

Batch 11·13·14·15는 생성 스크립트가 매니페스트를 다시 만들 때
`review_only_draft`를 보존하는 옛 형식이지만, `promotedAt`과 기존 승격 커밋이
남아 있으므로 이를 `live_verified_legacy_authorized`로 분리한다. Batch 16도
동일한 옛 승인 증거를 사용한다. 이를 새 형식처럼 보이도록 과거 리뷰 원장을
소급 조작하지 않는다.

과거 승인 초안과 현재 라이브 문구가 다른 경우는 후속 자연성 교정일 수 있다.
이번 감사는 각 Batch가 현재 가리키는 라이브 레코드를 정규 JSON으로 직렬화한
SHA-256 지문을 남긴다. 따라서 안정 ID와 현재 앱 투영은 재현할 수 있지만,
과거 리뷰 문구를 라이브에 덮어쓰지는 않는다. 현대식 Batch의 승인 초안 일치는
`validate_promoted_batch.py`, 전체 스키마·중복·번역·수량은
`validate_content.py`가 별도로 검사한다.

## 이번에 바로잡은 결함

- Batch 07 리뷰 원장 2개에서 문장 내부 쉼표 때문에 열이 하나 더 생기던 4개 행을 올바르게 인용했다.
- 모든 리뷰 CSV를 초안 ID 집합과 대조하는 검사를 감사기에 추가했다.
- Batch별 현재 라이브 투영 지문과 현대식/레거시 승인 계보를 원장에 기록했다.
- Batch 20의 culture note를 포함해 보조 콘텐츠 추적 범위를 완성했다.

독립 한국어·독일어 원어민 검수가 끝나기 전에는 이 결과를 “원어민 품질 100%”로
표현하지 않는다. 이 감사가 증명하는 것은 승인 계보, 스키마, ID, 앱 실데이터,
라우팅과 자동화 검증 범위다.
