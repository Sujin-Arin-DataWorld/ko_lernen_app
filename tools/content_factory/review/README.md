# 콘텐츠 리뷰 병합 규칙

이 폴더의 CSV는 콘텐츠 본문이 아니라 **Jin의 승인 원장**입니다. `apply_review.py`는
리뷰 시트에서 `id`와 `상태`(또는 `status`)만 읽습니다. 나머지 열은 검수 맥락과
감사 기록용이며, 그 값을 앱 자산으로 변환하거나 보완하지 않습니다.

Batch 01-05의 모든 ledger는 2026-08-15 live 승격을 기록하는 `approved` 상태다. 새
Batch 06+는 모든 행을 `draft`로 시작한다. 여러 asset·curriculum·pack UI map이 필요한
새 vocab/grammar/game batch는 `apply_review.py` 단독 `--apply`가 아니라
`integrate_review_batches.py --manifest ...`로, scenario 중심 cross-game bundle은
`integrate_scenario_batch.py --manifest ...`로 원자적으로 승격한다.

Batch 06 review 원장 5개는 2026-08-17에 Jin 승인 뒤 `approved`로 닫혔고, manifest
상태는 `merged`다. 이후 검사는 `validate_review_batch.py`가 아니라
`validate_promoted_batch.py --manifest tools/content_factory/drafts/batch_06_manifest.json`
이다. 새 Batch 07+는 다시 모든 행을 `draft`로 시작한다.

## 공통 헤더와 상태

최소 헤더는 아래 둘 중 하나입니다. 두 상태 열을 한 파일에 함께 넣으면 모호하므로
실패합니다.

```csv
id,level,ko,de,en,field_notes,상태,jin_memo
```

```csv
id,level,ko,de,en,field_notes,status,jin_memo
```

| 상태 | 병합 | 의미 |
| --- | --- | --- |
| `ok`, `approved` | 예 | 해당 `id`의 draft 레코드를 append |
| `draft` 또는 빈 값 | 아니오 | 아직 검수 전 |
| `fix: <메모>` | 아니오 | 수정 후 재검수 필요 |
| `no`, `rejected` | 아니오 | 거절 |

한 리뷰 시트에서는 상태와 무관하게 `id`가 한 번만 나와야 합니다. 같은 `id`가
`ok`와 `no`로 함께 있으면 병합 의도를 추측하지 않고 실패합니다.

## Draft와 실행

승인 원장은 축약된 표이므로, 실제 콘텐츠는 별도의 **schema-complete draft**에 둡니다.

- CSV draft는 대상 자산과 정확히 같은 헤더와 모든 열을 가져야 합니다.
- JSON draft는 대상의 정식 배열(`scenarios`, `items`, `phrases`, 또는 root array)에
  완전한 object 레코드를 둡니다.
- 승인된 ID는 draft에 존재해야 하고, 대상 자산의 기존 ID와 중복될 수 없습니다.
- `kkeunmari_pool.json`은 안정적인 `id`가 없으므로 이 도구 대상이 아닙니다. 전용
  생성·검수 흐름을 사용합니다.
- `grammar_patterns.json`은 Cloud Function 사본과 원자적으로 동기화해야 하므로 이
  asset-only 도구 대상이 아닙니다. C4의 paired mirror/deployment 흐름에서만 병합합니다.
- 새 `korean_vocab.csv` pack은 11–12개 연속 `pack_order`, 마지막 2–3개의 Boss,
  그리고 pack 전체 승인이라는 구조를 preview부터 통과해야 합니다. 실제 `--apply`에는
  Batch manifest를 `--pack-metadata`로 넘겨 read-only pack-assignment 사전검사까지
  통과해야 합니다. 기존 pack에 대한 명시적 유지보수 append는 이 metadata 요건 밖입니다.

검수할 때는 8열 원장만 보지 않습니다. 아래 명령으로 draft의 모든 field, reply/follow-up,
answer/distractor와 원장 상태를 한 packet으로 렌더링합니다. 수정은 항상 draft에서 하고,
packet은 다시 생성합니다.

```bash
python3 tools/content_factory/render_review_packet.py \
  --manifest tools/content_factory/drafts/batch_02_manifest.json \
  --output tools/content_factory/review/batch_02_review_packet.md
```

먼저 항상 preview를 실행합니다. 기본 실행은 어떤 자산도 쓰지 않습니다.

```bash
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/c3_vocab.csv \
  --draft /absolute/path/c3_vocab_draft.csv \
  --target assets/data/korean_vocab.csv
```

Jin이 preview와 draft를 확인한 뒤에만, 기존 한 asset의 유지보수에는 `--apply`를 추가합니다.

```bash
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/c3_vocab.csv \
  --draft /absolute/path/c3_vocab_draft.csv \
  --target assets/data/korean_vocab.csv \
  --apply
```

`--target`은 지원되는 정확한 `assets/data/` 정본 파일만 허용합니다. 적용 시에는
대상 자산 append → 해당 audit manifest count 갱신 → 전체 `validate_content.py` 순으로
검사합니다. 어느 단계든 실패하면 대상 자산과 manifest를 모두 원래 내용으로 되돌립니다.
`--no-manifest` 우회는 지원하지 않습니다.

새 vocab pack·grammar·smalltalk·Cloze·Satz를 묶는 review batch는 preview 뒤 전체
ledger와 companion mapping을 다음처럼 함께 적용한다.

```bash
python3 tools/content_factory/integrate_review_batches.py \
  --manifest tools/content_factory/drafts/batch_05_manifest.json \
  --apply
```
