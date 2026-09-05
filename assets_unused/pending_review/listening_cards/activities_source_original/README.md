# activities 원본 아카이브

`assets/illustrations/activities/` 로 가는 카드의 **원본**을 보관한다.
런타임 자산이 아니며 앱에 번들되지 않는다. 기계가 읽는 계약은 `MANIFEST.json`.

## 상태

| 원본 | 상태 |
|---|---|
| `scenarios_source_1448x1086.png` | **승격됨** → `activities/scenarios.webp` (q91, 103.8KB) |
| `Lernaktivität.png` | **보류** — 소비처 없음 |

`Lernaktivität` 는 독일어 UI 문자열(`lib/l10n/app_de.arb`)일 뿐 이미지 자산을
참조하는 코드가 없다. 지금 승격하면 소비처 없는 고아 자산이 된다. 이 그림을 쓰는
화면이 생기면 아래 절차로 올린다.

## 승격 절차

이 계보는 F-E-cards 의 `C1-source-original` 편차 프로파일을 따른다. 공급된 PNG
팔레트와 원본 종이 질감을 그대로 두고 합성 아이보리 패치·그레인을 얹지 않는다.

```
supplied PNG -> RGB -> LANCZOS 800x600 -> WebP per-asset quality method6
```

파일 크기가 하드 밴드 `[65, 111]KB` 에 들도록 품질을 자산별로 고른다(문서 계약
`[85, 105]KB` 는 경고 등급). 그 다음:

```
python tool/check_card_style.py --register <파일> --profile C1-source-original
```

`--profile` 을 빼면 레거시 아이보리 레시피 기준으로 판정해 떨어진다 — 이 계보는
아이보리 패치 색과 그레인 SD 를 만족하지 않는 것이 정상이다. 등록이 통과하면
사이드카(`CARD_STYLE_BASELINE.json`)와 `STYLE_LOCK.json` 의 가족 members·편차
members 가 함께 갱신되고, 이후 스윕이 편차 경로로 재게 된다.

**면제되는 것**: `ivoryFracMin` `ivoryPatchWindow` `fineGrainSD` `coarseGrainSD`
**유지되는 것**: format · mode · dimensions · fileKB · palettePresence ·
`uniqueColorsMin` · sha256 원장

밴드는 승인된 실측이다. 통과시키려고 넓히지 말 것 — 새 계보가 필요하면 편차
프로파일을 선언하는 것이 이 저장소의 방식이다.
