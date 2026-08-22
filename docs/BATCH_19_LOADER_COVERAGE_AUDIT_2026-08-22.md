# Batch 19 A1–C2 로더 공백 감사

- 기준 SHA: `caebe3e408d4dcab6502835ae430c5e64feb167d`
- 작업 브랜치: `codex/batch-live-coverage-20260822`
- 승인: Jin, 2026-08-22
- 문체 계약: Beyond Humanizer v2
- 권리 계약: original clean-room

## 결과

Batch 19는 raw 수량을 균등하게 늘리는 배치가 아니라 실제 앱 로더의 부족량을 채우는
gap-targeted 배치다. 교재 PDF는 난이도·기능·활동 구조의 일반 신호에만 사용하며 원문,
표 셀, 대화, 문제, 선택지, 단원 순서와 source/page 식별자는 앱 draft에 전달하지 않았다.

| 산출물 | 추가 수량 |
| --- | ---: |
| vocab / grammar | 20 / 6 |
| scenario / embedded quest | 3 / 15 |
| smalltalk / cloze / Satzbau | 57 / 63 / 38 |
| pronunciation | 16 |
| media phrase / word relation | 32 / 24 |
| grammar pattern | 6 |
| C1/C2 끝말잇기 / 음절 퍼즐 | 40 / 40 |

표준 manifest 레코드는 203개, supplemental artifact는 142개로 총 345개다. Batch 01–19
전체 manifest 감사 결과는 5,947/5,947 live다.

## 로더 완료 조건

- [x] scenario: A1–C2 모든 코스 unit에 1개 이상
- [x] smalltalk: A1–C2 모든 코스 unit에 2개 이상, 23개 category마다 2개 이상
- [x] cloze: 모든 코스 unit에 round 10 이상
- [x] Satzbau: 모든 코스 unit에 round 8 이상
- [x] pronunciation: A1/A2/B1 exact 8, B2/C1/C2 exact 16
- [x] Silben: A1–C2 exact 20 및 화면 선택 가능
- [x] media phrase: A1–C2 exact-level 선택, Discover와 연습 허브 도달 가능
- [x] can-do: raw vocab/grammar/scenario/smalltalk/cloze/Satzbau 전부 direct 또는 inherited route
- [x] 오늘의 단어: C1 deck에서 A1 starter와 overdue A1 card 제외

## 검증 증거

- `validate_content.py`: passed
- `audit_batch_live_promotion.py --check`: 5,947/5,947 live
- `audit_game_loader_coverage.py --check`: `coverageErrors=[]`
- `build_can_do_segments.py --check`: no drift
- Beyond Humanizer v2 Unicode/rejected phrase validators: passed
- `flutter analyze`: no issues
- targeted Flutter content/loader/UI tests: passed after count and route contract updates
- TTS Storage: expected 12,060, missing 0, stale 304; stale cache는 삭제하지 않음

## 파생 데이터 안정성

기존 공개 can-do 소유권은 이후 category 또는 curriculum 재분류로 이동하지 않는다. 생성기는
현재 공개 cluster를 안정 권한으로 읽고, 새 C1/C2 콘텐츠만 코스 unit별 기본 담화 기능 또는
더 구체적인 승인 route에 연결한다. 콘텐츠 수량 테스트는 `content_audit_manifest.json`을
정본으로 사용해 새 배치 때 하드코딩 수량이 뒤처지지 않게 했다.

## 남은 비승격 작업

추가 PDF 고유 자료 19개·3,278쪽의 전체 페이지 구조 감사는 별도 reference-intake 큐다.
이는 이번 live 콘텐츠의 문구 근거가 아니며, 완료 전까지 `sampled`를 `fully_audited`로
표시하지 않는다.
