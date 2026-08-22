# Batch 01-18 라이브 승격 감사

감사일: 2026-08-22
실행 정본: `python tools/content_factory/audit_batch_live_promotion.py --check`

## 결론

활성 Batch 매니페스트가 추적하는 안정 ID 5,602개 중 5,602개가 앱의
`assets/data`에 존재한다. 시나리오는 ID 존재만 보지 않고 `shelf`, `backdrop`,
`curriculum_manifest.json`의 `contentLink`까지 확인했다. `superseded` 두 파일과
조합용 `index` 두 파일은 라이브 승격 대상에서 의도적으로 제외했다.

| 매니페스트 | 추적 ID | 라이브 ID | 판정 |
|---|---:|---:|---|
| Batch 01 | 96 | 96 | live verified |
| Batch 02 | 96 | 96 | live verified |
| Batch 03 | 126 | 126 | live verified |
| Batch 04 | 16 | 16 | live verified |
| Batch 05 | 504 | 504 | live verified |
| Batch 06 | 68 | 68 | live verified |
| Batch 07 partner/family | 1,374 | 1,374 | live verified |
| Batch 08 partner/family | 28 | 28 | live verified |
| Batch 09 4x | 1,764 | 1,764 | live verified |
| Batch 10 4x | 814 | 814 | live verified |
| Batch 11 | 36 | 36 | live verified; 생성형 매니페스트 상태 표기만 stale |
| Batch 12 | 312 | 312 | live verified |
| Batch 13 | 12 | 12 | live verified; 생성형 매니페스트 상태 표기만 stale |
| Batch 14 | 28 | 28 | live verified; 생성형 매니페스트 상태 표기만 stale |
| Batch 15 | 28 | 28 | live verified; 생성형 매니페스트 상태 표기만 stale |
| Batch 16 | 24 | 24 | live verified |
| Batch 17 | 144 | 144 | live verified; merged |
| Batch 18 | 132 | 132 | live verified; merged |

`batch_07_4x_manifest.json`과 `batch_08_4x_manifest.json`은 후속 Batch 09·10으로
대체된 `superseded` 기록이다. `batch_07_manifest.json`과
`batch_08_manifest.json`은 두 작업 계보를 묶는 `index`라 자체 레코드가 없다.

## 바로잡은 계보 결함

- Batch 07 어휘 초안의 쉼표 포함 예문 3개에 CSV 인용부호를 복원했다.
- Batch 12 어휘 초안의 쉼표 포함 예문 1개에 CSV 인용부호를 복원했다.
- Batch 12 `vocab_c2_0215` 리뷰 원장을 실제 초안·라이브 정본인
  `비난 / Vorwurf / criticism`과 동기화했다.
- 시나리오 승격 때만 붙는 `shelf`·`backdrop`을 승인 초안과의 텍스트 차이로
  오판하던 승격 검증기를 수정했다.

## Batch 17-18 로더 결과

| 유형 | B2 | C1 | C2 | 라이브 전체 |
|---|---:|---:|---:|---:|
| 시나리오 | 72 | 49 | 45 | 404 |
| 스몰톡 | 112 | 44 | 44 | 429 |
| 빈칸 | 385 | 244 | 244 | 1,706 |
| 문장 만들기 | 543 | 246 | 246 | 2,259 |
| 발음 원문 | 16 | 16 | 16 | 56 |

Batch 18 승격 뒤 어휘는 B2 533개·C1 228개·C2 228개, 문법은
B2 55개·C1 21개·C2 21개다. 새 어휘팩은 코스 단원, 카드 표시명·순서,
단청 문양까지 원자적 승격 경로로 연결했다.

코스 로더의 B2-C2 시나리오·스몰톡·빈칸·문장 만들기에는 미연결 ID가 없다.
오늘의 단어는 현재 `ReviewDeckService.todaySelectionForLevel`이 번들 단어를
정확히 현재 CEFR 레벨로 제한한다. C1 학습자에게 A1 `안녕하세요`가 신규 또는
연체 복습으로 섞이지 않는 회귀 테스트도 별도로 유지한다.

## 판정 경계

과거 초안과 현재 라이브 문구가 다를 수 있는 것은 승인 후 자연성 교정 이력이다.
이 감사는 과거 문구를 라이브에 덮어쓰지 않고, 안정 ID의 존재와 현재 로더 연결을
정본으로 삼는다. 텍스트 스키마·중복·수량은 `validate_content.py`, Batch 17·18의
승인 초안 일치는 `validate_promoted_batch.py`가 별도로 검사한다.
