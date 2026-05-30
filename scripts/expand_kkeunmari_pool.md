# Kkeunmari 단어 풀 자동 확장 — 장기형 4-소스 파이프라인

> 최종 결정: **`scripts/build_pool.py`** — 4 소스 통합, 캐시, resumable, 단일 소스 의존 X.

---

## 설계 원칙 (왜 4-소스인가?)

| 원칙 | 해결책 |
|---|---|
| **외부 repo 사라짐 위험** (이전 hingston/korean처럼) | 소스 4개 — 1개 죽어도 계속 가동 |
| **자막 noise** (verb·particle·colloquial 다수) | OpenKoreanText 명사 사전과 교집합 |
| **빈도 = 난이도 ≠ 학습 난이도** | NIKL로 정의·예문·CEFR 보강 (선택) |
| **재실행 비용** (API 호출 반복) | 로컬 캐시 — 한 번 받으면 평생 |
| **중단 시 손실** | 모든 응답 즉시 disk 저장, `--merge`로 이어서 |

---

## 4 소스 역할 분담

| 소스 | 역할 | 라이선스 | 필수? |
|---|---|---|---|
| **hermitdave/FrequencyWords** | 빈도순 50k 단어 | CC-BY-SA | ✅ 필수 |
| **open-korean-text** | 검증된 명사 사전 (~140k) | Apache 2.0 | ✅ 필수 |
| **NIKL 우리말샘 API** | 권위 있는 정의 + 영어 번역 | 정부 데이터 (무료) | 선택 (`--enrich`) |
| **DeepL Free** | KO → DE 번역 | 무료 tier 500k자/월 | 선택 (없으면 TODO) |

---

## 캐시 구조 (resumable의 핵심)

```
scripts/cache/
  sources/                    # 외부 word list 스냅샷 (committed)
    hermitdave_ko_50k.txt     # ~1 MB
    okt_nouns.txt             # ~500 KB
  nikl/                       # NIKL 응답 per-word (gitignored)
    {단어}.json
  deepl_de.json               # 누적 DeepL 번역 (gitignored)
```

캐시 덕분에:
- **2회차 실행은 빈도 list 다운로드 0회**
- **DeepL 번역 0회 재요청** → 무료 tier 절약 + 속도 5배
- **중간에 crash해도 다음 실행에서 이어감**
- **`--offline` 모드** — 네트워크 0 호출, 캐시만으로 rebuild

---

## 사용법

### 0. 환경 변수
```bash
# DE 번역 (선택, 없으면 TODO 마커)
export DEEPL_API_KEY="247e8dfc-..."

# 권위 있는 정의·영어 보강 (선택)
export NIKL_API_KEY="..."  # https://opendict.korean.go.kr/service/openApiInfo
```

### 1. 최소 구성 (DeepL만, 가장 일반적)
```bash
python3 scripts/build_pool.py --target 1500 --merge
```
→ 기존 323단어 + 빈도순 1200개 신규 → 총 ~1500

### 2. 풀 enrichment (NIKL 정의 + 영어 + DeepL)
```bash
python3 scripts/build_pool.py --target 1500 --merge --enrich
```
→ 각 단어에 `meaning_ko` + `english` 추가 (Vocab 모듈에서 활용 가능)

### 3. Offline rebuild (캐시만 사용)
```bash
python3 scripts/build_pool.py --target 1500 --offline --merge
```
→ 네트워크 호출 0. 이전에 다운받은 sources + nikl 캐시로 재계산.

### 4. 스모크 테스트 (50단어, 5분)
```bash
python3 scripts/build_pool.py --target 50
```

---

## 출력 JSON 구조

```json
{
  "meta": {
    "source": "hermitdave/FrequencyWords + open-korean-text + DeepL DE + NIKL 우리말샘",
    "generated": "2026-05-29",
    "total": 1500,
    "okt_verified": 1487
  },
  "words": [
    {
      "word": "가족",
      "first": "가",
      "last": "족",
      "level": "A1",
      "german": "Familie",
      "topic": "family",
      "next_count": 12,
      "is_dead_end": false,
      "meaning_ko": "주로 부부를 중심으로 한 친족 관계에 있는 사람들의 집단.",
      "english": "family"
    },
    ...
  ]
}
```

- 기존 필드 (`word`/`first`/`last`/`level`/`german`/`topic`/`next_count`/`is_dead_end`) 완벽 호환
- **추가 필드** (`meaning_ko`/`english`) — NIKL enrichment 시에만 생성. v1.1 Vocab 모듈에서 풍부한 단어장 가능

---

## Pipeline 상세

```
[1/5] Load frequency list  ────→ 50000 words (cached)
[2/5] Load OKT noun dict    ────→ ~140000 verified nouns (cached)
[3/5] Intersection filter   ────→ top-N frequency-ranked clean nouns
       │
       ├─ in OKT? → accept (strongest signal)
       ├─ 2-syllable & not verb-ending? → accept (frequency confidence)
       └─ else → reject

[4/5] DeepL batch translate ────→ {ko: de} cached
      (optional) NIKL enrich  ────→ {definition, en} per word, cached

[5/5] Build entries + meta  ────→ next_count + is_dead_end (re-computed
                                   against entire pool to handle merge)
```

---

## 옵션 비교 — 왜 이 조합인가?

| 조합 | 안정성 | 품질 | 비용 | 추천? |
|---|---|---|---|---|
| hermitdave only | 🟡 단일 source | 🔴 자막 noise | $0 | ❌ |
| hermitdave + DeepL | 🟡 | 🟡 | $0 | 🟡 (구 expand_pool.py) |
| **hermitdave + OKT + DeepL** | 🟢 2 소스 fallback | 🟢 OKT 검증 | $0 | ✅ |
| **hermitdave + OKT + NIKL + DeepL** | 🟢🟢 3 소스 + 정부 | 🟢🟢 정의·예문 포함 | $0 | ⭐ 추천 |
| Wiktionary dump only | 🟢 offline | 🟡 parsing 복잡 | $0 | ❌ overkill |

---

## 추후 개선 (v1.1+)

1. **Vocab 모듈 통합** — NIKL `meaning_ko` + `english` 활용해 한국어 정의 + 영문 번역 카드
2. **예문 추가** — NIKL view API의 `example_sentence` 필드 추출
3. **TOPIK 시험 어휘 머지** — `--source topik` 플래그로 시험 대비 모드
4. **Anki export** — `--format anki` 로 사용자가 자신만의 deck 만들기
5. **사용자 입력 학습** — Kkeunmari에서 사용자가 입력했지만 풀에 없던 단어를 모아 주간 PR 자동 생성

---

## 트러블슈팅

**"requests not found"**
```bash
pip3 install requests --break-system-packages
```

**"python: command not found"** (macOS 기본)
```bash
python3 scripts/build_pool.py ...
```

**모든 외부 소스가 죽었다면** — `--offline` + 이전 캐시. 캐시도 없으면 위 소스 4개 중 1개라도 살아 있을 때 다운로드.

**DeepL 무료 한도 초과** — 캐시가 누적 저장되니까 다음 달 1일에 이어서 실행 가능.

**NIKL rate limit (일 25000건)** — 캐시 덕분에 두 번째 실행부터 0건 호출.
