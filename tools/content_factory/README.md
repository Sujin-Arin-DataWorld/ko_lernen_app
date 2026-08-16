# Content Factory (M5 — 오프라인 콘텐츠 생성)

> 앱 런타임 비용 0. 콘텐츠는 **빌드타임에 한 번** 생성·검수해 정적 자산으로 넣는다.
> 런타임(개인화 코스/복습/게임)은 이 정적 콘텐츠를 **로컬에서 고르기만** 한다.
> §0: 추측·환각 콘텐츠 금지. 생성물은 **원어민 검수**를 거친 것만 커밋.

---

## C0 정본: 생성 → Jin 검수 → 승인 병합

새 콘텐츠의 정본 워크플로는 기존 개별 `add_*`/`build_*` 스크립트가 아니라
`validate_content.py`, `apply_review.py`, 그리고 여러 asset을 함께 다루는
`integrate_review_batches.py`/`integrate_scenario_batch.py`다. 생성 draft는 앱이 읽는 완전한
CSV/JSON 스키마를 보존하고, 리뷰 CSV는 `id`와 `상태`/`status`만으로 승인 여부를
기록한다. Batch 01의 고정 계약은 `validate_batch_01.py`로, 이후 batch의 manifest
계약은 `validate_review_batch.py --manifest …`로 검사한다. 공통 헤더·상태 규칙·시나리오 전문 검수 규칙은
[`review/README.md`](review/README.md)에 있다.

PDF, OCR, 표 또는 Library 페이지 판독이 선행되는 작업은 먼저
[`docs/CONTENT_REFERENCE_INTAKE_GUIDE.md`](../../docs/CONTENT_REFERENCE_INTAKE_GUIDE.md)와
[`reference_intake/README.md`](reference_intake/README.md)를 따른다. source 원문은 draft로
넘기지 않으며, `validate_reference_intake.py`가 격리 CSV와 live ID 연결을 검사한다.

> **2026-08-15 live baseline.** Batch 01–04와 B2/C1/C2 Batch 05는 Jin 승인 뒤
> `assets/data/`에 이미 승격됐다. 다음 작성 번호는 Batch 06이며 새
> manifest/draft/review로 시작한다. 새 vocab·grammar·smalltalk·Cloze·Satz에는
> `apply_review.py` 단독 append가 아니라 아래의 multi-asset 통합기를 사용한다.

> **신규 작성자는 먼저 [`docs/CONTENT_AUTHORING_GUIDE.md`](../../docs/CONTENT_AUTHORING_GUIDE.md)를
> 전부 읽는다.** 이 문서는 KO/DE/EN 병기, 모든 draft 열·JSON field, Batch 01 고정
> 경계, 커리큘럼 동반 mapping, preview/승인 순서를 한곳에 고정한다. 이 README 아래의
> 개별 `add_*`/`build_*` 스크립트 설명은 기존 자산의 역사적 유지보수 참고일 뿐이며,
> 신규 B1–C2 batch의 직접 작성·`--write` 지시로 사용하지 않는다.

```bash
# 현재 자산의 빠른 실패 게이트
python3 tools/content_factory/validate_content.py

# source 격리, clean-room brief, live curriculum/vocab/grammar 참조 검사
python3 tools/content_factory/validate_reference_intake.py

# review-only batch의 schema, review projection, companion mapping, 이전 미병합
# batch 예약, 그리고 disposable app-data overlay를 모두 검사한다. 어떤 source도 쓰지 않는다.
python3 tools/content_factory/validate_review_batch.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json

# 기본값: preview만. 파일을 쓰지 않는다.
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/<phase>_<type>.csv \
  --draft /absolute/path/<schema-complete-draft>.json \
  --target assets/data/<target>.json

# 기존 asset 하나만 변경하는 유지보수에서 Jin이 approved ID를 확인한 뒤에만 병합한다.
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/<phase>_<type>.csv \
  --draft /absolute/path/<schema-complete-draft>.json \
  --target assets/data/<target>.json --apply

# 새 review-only batch의 vocab·grammar·smalltalk·Cloze·Satz와 동반 curriculum/UI map을
# validator/rollback과 하나의 transaction으로 병합한다. --manifest를 명시한 기본은 preview다.
python3 tools/content_factory/integrate_review_batches.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json

# Jin의 명시 승인 뒤에만 쓴다. --approve-all은 review 원장의 완전 pack 승인만 허용한다.
python3 tools/content_factory/integrate_review_batches.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json --apply --approve-all

# scenario-only batch는 scenario data·curriculum·backdrop을 함께 다룬다.
python3 tools/content_factory/integrate_scenario_batch.py \
  --manifest tools/content_factory/drafts/batch_XX_manifest.json --apply
```

`ok`와 `approved`만 병합 가능하다. 빈 값·`draft`·`fix: ...`·`no`·`rejected`는
절대 병합하지 않는다. `--apply`는 target과 `content_audit_manifest.json`을 함께
갱신하고 전체 validator가 실패하면 둘 다 복구한다. manifest 갱신을 끄는 우회
경로는 사용하지 않는다. `kkeunmari_pool.json`(stable ID 없음)과
`grammar_patterns.json`(Cloud Function mirror 동기화 필요)은 이 asset-only append
도구의 대상이 아니며 각각 전용 생성/paired C4 흐름을 사용한다.

새 `korean_vocab.csv` pack은 행 단위로 쪼개 병합할 수 없다. draft의 이전에 없던
`pack_id`는 preview와 `--apply` 모두에서 다음을 fail-closed로 확인한다: 11–12행,
연속 `pack_order` 1..n, 마지막 2–3개 Boss, 그리고 하나라도 승인되었으면 그 pack의
모든 draft 행도 `ok`/`approved`. 그래서 미완성 pack이 Learn/Boss 흐름에 들어갈 수
없다. preview는 metadata 없이도 이 구조 검사를 수행하며 파일을 쓰지 않는다.

새 pack을 실제 `--apply` 할 때는 `--pack-metadata`가 필수다. 전달하면 preview에서도
read-only 사전검사를 수행한다. 기존 `pack_id`에 단어를 추가하는 유지보수 흐름은 이
새-pack metadata 요건의 대상이 아니다.

```bash
python3 tools/content_factory/apply_review.py \
  tools/content_factory/review/c3_batch01_vocab.csv \
  --draft tools/content_factory/drafts/c3_batch01_vocab_b1_b2.csv \
  --target assets/data/korean_vocab.csv \
  --pack-metadata tools/content_factory/drafts/batch_01_manifest.json \
  --apply
```

### 새 단어팩: read-only 배정 사전검사

단어 본문을 검수하기 전에 `plan_pack_assignments.py`로 새 pack의 UI/커리큘럼 계약을
확정한다. 이 도구는 **읽기 전용**이다. 앱 데이터·draft·metadata를 쓰지 않으며,
배정 결과를 stdout으로만 표시한다.

```bash
python3 tools/content_factory/plan_pack_assignments.py \
  --draft tools/content_factory/drafts/c3_batch01_vocab_b1_b2.csv \
  --metadata tools/content_factory/drafts/batch_01_manifest.json
```

Batch 01은 아래 `vocabPacks` manifest를 정본으로 쓴다. `packId`는 numeric sub-pack
suffix를 포함하고, 도구가 base와 현재 UI의 다음 `orderInLevel`을 읽기 전용으로
계산한다. 따라서 같은 배정 사실을 별도 JSON에 중복하지 않는다.

```json
{
  "vocabPacks": [{
    "packId": "b1_housing_contract_1",
    "level": "b1",
    "orderRange": [1, 12],
    "reviewBossOrders": [10, 11, 12],
    "displayLabel": {
      "ko": "주거와 계약",
      "de": "Wohnen & Vertrag",
      "en": "Housing & Contracts"
    },
    "motif": "gwigap",
    "curriculum": {
      "courseUnitId": "b1_05_complaint_resolution",
      "conceptIds": ["concept_b1_complaint_resolution"]
    }
  }]
}
```

사전검사는 현재 정본과 대조해 다음을 fail-closed로 확인한다: 정확한 15열 draft,
새 ID/한국어 표제어, pack당 11–12행과 마지막 2–3 Boss, level 일치, 현재 UI 순서의
다음 빈 `orderInLevel`, 비어 있지 않은 KO/DE/EN label, 기존 `DancheongMotif`,
그리고 같은 레벨의 기존 curriculum unit. `orderRange`/`reviewBossOrders`도 draft와
정확히 일치해야 한다. 이전 최소 `packs` metadata 형식도 호환을 위해 읽을 수 있지만,
새 batch에는 쓰지 않는다. 실제 UI map·motif switch·curriculum manifest를 수정하는
것은 콘텐츠 승인 뒤의 별도 동반 변경이다.

### 미병합 predecessor 예약

Batch 02처럼 앞 review-only batch가 아직 `assets/data/`에 들어가지 않았으면, 새 manifest의
`predecessorManifests`에 그 manifest를 repository-relative path로 적는다. 이 필드는 단순한
순번 힌트가 아니다. generic validator는 이전 draft의 모든 ID와 한국어 표제어, 그리고
`vocabPackUnitMap`·`grammarRuleMap`·`smalltalkCategoryUnitMap`·`clozeTopicUnitMap`을
예약한다. 같은 mapping 값의 재사용은 가능하지만, ID·표제어·mapping 값이 충돌하면 fail-closed다.

이전 batch가 실제 다중 파일 integration으로 live asset과 curriculum에 병합된 뒤에는 후속
manifest에서 그 predecessor path를 제거한다. 이미 live인 콘텐츠는 일반 overlay validator가
중복을 검사한다.

### 금지: `scripts/build_vocab_packs.py` 재실행

이 스크립트는 현재 15열 `korean_vocab.csv` 이전의 migration 도구다. 재실행하면
영어 열과 명시적 ID를 포함한 현 스키마를 훼손할 수 있다. B1–C2 확장은 승인된
완전 draft를 승인 원장과 함께 multi-asset 통합기로 병합한다. 기존 pack 행은 불변이다.

### TTS 수집 확인

```bash
python3 tool/generate_tts.py --dry-run
```

`--dry-run`은 현재 정적 자산을 `(voice, Korean text)` 단위로 dedup해 출력할
뿐이며, 인증·합성·로컬 파일 생성·Firebase Storage 업로드를 수행하지 않는다.
2026-08-15의 live corpus는 **6,321개 요청**(female 6,146 / male 175)이다. Batch 05
신규 504개까지 합성·업로드한 뒤 Storage를 `expected 6321, remote 6376, missing 0,
stale 55`로 검증했다. stale 55개는 immutable 과거 캐시이므로 삭제하지 않는다.
과거 문서의 5,288개 또는 약 1,314개 수치는 현재 비용 견적이나 완료 기준으로 쓰지 않는다.
자산에 새 한국어 발화가 들어갈 때마다 dry-run 수량과 목록을 다시 검수한다.
실제 `python3 tool/generate_tts.py` 실행 및 업로드는 Jin의 명시적 권한과 계정으로만
수행한다.

실제 승인 실행에서는 전체 local cache만 보고 재합성하지 않는다. 먼저 아래로 Firebase
Storage와 대조한 뒤, 누락분만 합성한다.

```bash
python3 tool/generate_tts.py --missing-from-storage --workers 4
python3 tool/generate_tts.py --verify-storage
```

Chirp3-HD가 `429 Resource exhausted`를 반환해도 성공한 로컬·원격 파일은 보존된다.
1분 이상 기다린 뒤 `--missing-from-storage --workers 1`로 재실행하면 실제 누락분만
이어 만들 수 있다. `✅ 완료`는 해당 실행의 업로드 종료이고, 전체 완료 판정은 반드시
`--verify-storage`의 `missing 0`으로 한다.

---

## 역사적 유지보수 스크립트 (신규 batch 정본 아님)

> 아래 스크립트는 이미 존재하는 asset의 제한적 유지보수/재생성 이력을 보존한다. 새
> B1–C2 콘텐츠를 만들 때 이 절의 `--write` 예시를 실행하지 않는다. 먼저 위 C0 정본과
> `docs/CONTENT_AUTHORING_GUIDE.md`의 draft → review → preview 계약을 따른다.

### (a) `fill_kkeunmari_german.py` — 끝말잇기 독일어 채우기

`assets/data/kkeunmari_pool.json` 의 `german:"TODO"` 를 **정확한 출처만** 사용해 채운다:
1. `korean_vocab.csv` 와 단어가 정확히 일치 → 큐레이트된 독일어 복사.
2. `CURATED` 딕셔너리 — 사람이 검수한, 모호하지 않은 일반 기능어 글로스.

```bash
python3 tools/content_factory/fill_kkeunmari_german.py          # dry-run
python3 tools/content_factory/fill_kkeunmari_german.py --write   # 저장
```

### ⚠️ 정직한 한계 (중요)
풀의 TODO 2,130개 중 **약 2,061개는 자막 기반 대화체 조각·활용형**이다
(예: `거야`, `있고`, `이름을`[이름+을], `눈이`[目/雪 동음이의], `하지만`).
이들은 **단일 독일어 번역이 불가능하거나 오해를 부른다.** 그래서 이 스크립트는
**추측해서 채우지 않는다** (가짜 번역을 출시 앱에 넣으면 §0 위반).

→ 진짜 해법은 둘 중 하나:
- **풀 큐레이션**: 조각/활용형을 표제어로 정리하거나 제거 (끝말잇기는 음절
  연결 게임이라 독일어 힌트는 부차적 — 없어도 게임은 작동).
- **문맥 기반 번역**: DeepL(기존 Cloud Function에 연동돼 있음, 무료 티어로 충분)을
  문장 문맥과 함께 호출. 단어만 떼서 번역하면 DeepL도 부정확.

## (a2) `build_kkeunmari_pool.py` — 끝말잇기 풀을 **사전에서** 재생성 (정석)

> 2026-06-18 감사에서 자막 조각 TODO 2,061개를 풀에서 제거(→ 큐레이트 392만 남김).
> 이 스크립트는 그 자리를 **실제 사전 명사**로 채운다. (a)의 "진짜 해법"을 도구화한 것.

§0 준수 파이프라인 (전부 실재 소스, 손번역/지어내기 0):
1. **시드** = hermitdave ko_50k(빈도순 → "흔한", 자동 다운로드·캐시).
2. **표준국어대사전(stdict) API** 로 각 후보 검증 → **품사==명사**만 통과
   (조사결합·활용형·부사 등은 자동 탈락 = 조각 문제 근본 해결). 기존
   `functions/analyze_korean_text/main.py` 의 stdict 계약을 그대로 재사용.
3. **독일어 글로스**: `korean_vocab.csv` 정확 일치 → 검수 글로스 복사 ·
   그 외 → DeepL ko→de(`--deepl`, 기계→검수) · 둘 다 없으면 `""`(UI 자동 숨김,
   **"TODO"·가짜 안 씀**).
4. `first/last` 음절 + `next_count/is_dead_end` 를 **최종 집합 기준 재계산**.

```bash
# 0) 오프라인 로직 자가검증 (키·네트워크 불필요)
python3 tools/content_factory/build_kkeunmari_pool.py --self-test
# 1) 소량 시범(검증만, 미저장)
STDICT_API_KEY=… python3 tools/content_factory/build_kkeunmari_pool.py --target 50
# 2) 본 생성 + DeepL 글로스 + 저장
STDICT_API_KEY=… DEEPL_API_KEY=… \
  python3 tools/content_factory/build_kkeunmari_pool.py --target 2500 --deepl --write
```

키: `STDICT_API_KEY`(또는 `URIMALSAEM_API_KEY`) = stdict, `DEEPL_API_KEY` = DeepL.
→ **키 보유한 Jin 이 1회 실행** 후 `flutter test`(data integrity) → 육안(체인 길이) → 커밋.
DeepL 글로스는 기계번역 → **원어민 스팟체크 권장**.

> 옛 (a) `fill_kkeunmari_german.py` 는 기존 풀의 TODO 를 vocab/큐레이트로만 채우는
> 보조 도구(조각은 못 채움). 이제는 (a2)로 **풀 자체를 사전 기반 재생성**하는 게 정석.

## (b) `add_interest_scenarios.py` — 관심사 시나리오 추가 (검증 포함)

원어민 품질로 직접 작성한 시나리오를 **스키마 검증 후** `scenarios.json` 에 병합.
중복 id 는 건너뛴다. 구조 오류(필수 키 누락 등)면 중단.

```bash
python3 tools/content_factory/add_interest_scenarios.py          # 검증만
python3 tools/content_factory/add_interest_scenarios.py --write   # 병합
```

신규 양산: `NEW` 리스트에 같은 스키마로 시나리오를 추가하면 된다.

### 시나리오 스키마 (필수)
`id, level(a1..b2), emoji, register, sidekick, xpReward, title{ko,de,en},
intro{ko,de,en}, vocab[≥6 · {korean, note{ko,de,en}}], grammarIds[],
grammarBlock{title{ko,de,en}, explanation{ko,de,en}}, dialog[{speaker,ko,de,en}],
quests[{type, data}], culturalNote{ko,de,en}`

- **vocab 는 최소 6개** (`test/data_integrity_test.dart` 가 강제).
- quest type: `hoerverstehen` · `particlePop` · `uebersetzen` · `luecken` · `batchimDrop`.
- 추가 후 반드시: `flutter test test/data_integrity_test.dart` (스키마 게이트).

### 생성 프롬프트 (관심사 태그 시나리오)
> 아래를 Claude 에 주고 관심사·레벨별로 양산 (이 대화에서 생성 = 추가 API 비용 0):

```
독일어 사용자용 한국어 학습 시나리오 1개를 위 JSON 스키마로 생성하라.
- 관심사: {everyday|food_shopping|work_study|travel|feelings_people|health_body}
- 레벨: {a1|a2|b1|b2} (CEFR). 어휘·문법을 레벨에 맞춤.
- 한국어는 원어민이 실제로 쓰는 자연스러운 표현. 독/영은 정확한 번역.
- vocab ≥6, dialog 4–6턴, quest 3개(hoerverstehen+particlePop+uebersetzen).
- 기존 id와 중복 금지. culturalNote 는 실제 한국 문화 팁.
- 출력 후 원어민 검수 전제. 불확실하면 만들지 말 것(§0).
```

---

## 워크플로우 요약

1. 완전 스키마 draft 생성 → 2. `validate_content.py` → 3. Jin 리뷰 원장 작성 →
4. `apply_review.py` preview → 5. complete approved batch만 `integrate_review_batches.py --apply`
병합 → 6. validator +
Flutter 콘텐츠/그래프 게이트 → 7. 새 발화가 있으면 TTS dry-run → 8. Jin 커밋
지시 대기.

검수 없는 `--write`/직접 자산 병합과 실제 TTS 업로드는 출시 경로가 아니다.
