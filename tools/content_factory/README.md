# Content Factory (M5 — 오프라인 콘텐츠 생성)

> 앱 런타임 비용 0. 콘텐츠는 **빌드타임에 한 번** 생성·검수해 정적 자산으로 넣는다.
> 런타임(개인화 코스/복습/게임)은 이 정적 콘텐츠를 **로컬에서 고르기만** 한다.
> §0: 추측·환각 콘텐츠 금지. 생성물은 **원어민 검수**를 거친 것만 커밋.

---

## (a) `fill_kkeunmari_german.py` — 끝말잇기 독일어 채우기

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

현재 정확히 채워진 것: CSV 39 + 큐레이트 30 = **69개** (+ 기존 323 = 392).

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
1. 생성(이 대화/스크립트) → 2. `--write` 병합 → 3. `flutter test` 게이트 →
4. **원어민 샘플 검수** → 5. 커밋. 검수 없이 출시 금지.
