# Data Licenses & Attribution

> Hangul Sori 앱은 공개된 한국어/외국어 데이터를 활용합니다.
> 각 출처별 라이선스 및 의무 사항을 아래에 명시합니다.

---

## 1. 국립국어원 우리말샘 (NIKL)

- **Source**: https://opendict.korean.go.kr
- **License**: [CC BY-SA 2.0 KR](https://creativecommons.org/licenses/by-sa/2.0/kr/)
- **Used for**: 한국어 단어 정의, 영어 번역, 품사 정보
- **Required obligations** (한국어 원문 발췌):
  - **저작자 표시**: 자료를 사용할 때 저작자를 필수로 표시 → 앱 Settings → "데이터 출처" 화면 + `kkeunmari_pool.json` 메타에 명시 ✓
  - **동일조건변경허락**: 우리말샘에서 가져온 텍스트를 변경·재배포할 때 동일 라이선스(CC BY-SA 2.0 KR)로 공개 → `assets/data/kkeunmari_pool.json` 자체를 CC BY-SA 2.0 KR로 표시 ✓
  - **상업적 이용**: 허용됨 (저작자 표시 + 동일조건변경허락 지킬 시)
- **주의**: 텍스트만 적용. 다중매체 파일(이미지·음성)은 개별 라이선스를 따로 확인해야 함. 우리는 텍스트만 사용.

### 출전이 있는 용례(example) — 별도 처리
NIKL view API 응답의 example_sentence 중 `origin` 필드가 있는 용례는 원저작자가 별도 저작권 보유. 현재 우리는 example_sentence를 **수집하지 않음**. 향후 사용 시 origin 있는 것 제외 필터 필요.

## 2. hermitdave / FrequencyWords

- **Source**: https://github.com/hermitdave/FrequencyWords
- **License**: CC BY-SA 4.0 (OpenSubtitles 기반)
- **Used for**: 한국어 단어 빈도 ranking
- **Obligation**: Attribution + ShareAlike. 우리는 frequency rank 숫자만 derive해서 사용 → 가공된 단어 list만 배포 시에도 CC BY-SA 적용 안전.

## 3. open-korean-text

- **Source**: https://github.com/open-korean-text/open-korean-text
- **License**: Apache 2.0
- **Used for**: 한국어 명사 검증 (noun dictionary)
- **Obligation**: License notice + NOTICE 파일 포함. SHAREALIKE 조항 없음 → 우리 derivative에 자유롭게 라이선스 부여 가능.

## 4. DeepL Translation API

- **Source**: https://www.deepl.com
- **License (translation output)**: 번역 결과물은 사실 데이터로 간주, attribution 의무 없음 (DeepL ToS).
- **Used for**: 한국어 → 독일어 번역 (1차)
- **Obligation**: ToS 준수만. API 키는 비공개 보관.

## 5. ko.wiktionary (MediaWiki Action API)

- **Source**: https://ko.wiktionary.org
- **License**: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) (Wikimedia Foundation)
- **Used for**: DeepL 번역 실패/TODO 항목의 독일어 보충 (fallback)
- **API**: 무료, 키 불필요. User-Agent 헤더 필수.
- **Obligation**: Attribution + ShareAlike. `kkeunmari_pool.json`이 이미 CC BY-SA 2.0 KR(우리말샘 의무)으로 배포되므로 호환 (BY-SA 4.0과 BY-SA 2.0 KR은 ShareAlike 호환 라이선스).

---

## License Compatibility Matrix

| 데이터 | License | 재배포 시 적용 라이선스 |
|---|---|---|
| 우리말샘 단어 정의 | CC BY-SA 2.0 KR | **CC BY-SA 2.0 KR** (강제) |
| FrequencyWords 빈도 | CC BY-SA 4.0 | **CC BY-SA 4.0 or compatible** |
| OKT 명사 list | Apache 2.0 | 자유 |
| DeepL 번역 | sui generis | 자유 |
| **`assets/data/kkeunmari_pool.json` (결합)** | — | **CC BY-SA 2.0 KR** (가장 엄격 조항 적용) |

→ **결론**: `kkeunmari_pool.json`은 **CC BY-SA 2.0 KR**로 배포. 앱 자체(코드, 일러스트, UI)는 별도 라이선스 가능.

---

## App-side compliance (이미 적용됨)

1. ✓ `kkeunmari_pool.json` meta 필드에 license + attribution 명시
2. ✓ `Settings → 데이터 출처` (`_showDataSources`) — 4개 데이터 출처 카드 + CC BY-SA 2.0 KR 안내
3. ✓ 본 문서 (`docs/DATA_LICENSES.md`)
4. ✓ `scripts/build_pool.py` 결과 JSON에도 동일 메타 자동 삽입
5. ⏳ **Play Store 배포 시 추가 확인 필요**: 데이터 라이선스를 앱 설명에 명시 (선택), 또는 Settings 화면으로 충분

---

## 자주 묻는 질문

### Q. 앱 전체가 CC BY-SA가 되어야 하나?
A. 아니요. **데이터 부분(`kkeunmari_pool.json`)만** CC BY-SA 2.0 KR 적용. 코드/일러스트/UI는 별도. CC BY-SA의 "동일조건변경허락"은 derivative 데이터에 한정.

### Q. 사용자가 데이터를 export하면?
A. 사용자 export 기능은 현재 없음. 추가 시 사용자에게 "이 데이터는 CC BY-SA 2.0 KR입니다" 안내 + 라이선스 텍스트 동봉 필요.

### Q. 향후 NIKL 데이터를 빼면 라이선스 의무도 사라지나?
A. 네. NIKL 데이터를 모두 제거한 derivative만 배포 시 ShareAlike 의무 해소. 단, 이력상 NIKL을 사용한 시점의 derivative는 계속 CC BY-SA 적용.

### Q. 상업적 판매 가능한가?
A. **네, 가능합니다.** CC BY-SA 2.0 KR은 상업적 이용 허용. 단:
- 저작자 표시 (Settings → 데이터 출처 ✓)
- 동일조건변경허락 (JSON에 license 메타 ✓)
- 두 조건 충족 시 유료 앱 / 인앱 결제 / 광고 모두 가능

### Q. 다른 사람이 우리 JSON을 사용하면?
A. CC BY-SA 2.0 KR 라이선스에 따라 자유롭게 사용 가능. 단:
- Hangul Sori + NIKL 출처 명시
- 그들의 derivative도 CC BY-SA 2.0 KR 적용
