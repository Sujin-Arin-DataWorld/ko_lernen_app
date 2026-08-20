# 개인 한옥 정본 에셋 계약

**상태:** 런타임 정본 · 2026-08-05

> **Legacy runtime only / 새 개발에 사용 금지.** 이 문서는 현재 사용자에게 노출되는
> 4:3 개인 한옥 지도의 회귀 계약만 설명한다. 목표 제품과 V2 masterplan은
> [`2026-08-20-hanok-level-proof-and-skip-recovery-design.md`](superpowers/specs/2026-08-20-hanok-level-proof-and-skip-recovery-design.md)가 정본이다.
> 아래 `daecheongmaru`와 `rear_garden` 행은 현 renderer inventory일 뿐 V2 설계·생성
> 입력이 아니다. V2 cutover 전까지 현재 런타임 사실을 거짓으로 바꾸지 않기 위해
> 이 문서를 유지한다.

개인 한옥 지도는 `assets/illustrations/personal_hanok_v2/` 하나의 얕은
3/4 시점 세계만 사용한다. `hanok_compound/`는 과거 프로토타입이고,
`gye/`는 공동 마당 전용이다. 두 폴더의 PNG를 개인 지도에 섞지 않는다.

## 8장 런타임 패키지 + QA 합성물 1장

| 역할 | 경로 | 런타임 |
|---|---|---|
| 바탕 마당 | `map/site_base_light.png` | 항상 |
| 솟을대문 | `map/structures/sotdaeulmun.png` | B1 25% |
| 행랑채 | `map/structures/haengrangchae.png` | B1 50% |
| 사랑채 | `map/structures/sarangchae.png` | B1 100% |
| 안채 | `map/structures/anchae.png` | B2 25% |
| 대청마루 | `map/structures/daecheongmaru.png` | B2 50% |
| 사당 | `map/structures/sadang.png` | B2 75% |
| 후원 | `map/landscape/rear_garden.png` | B2 100% |
| 완성 검수 전경 | `assets_unused/pending_review/reference_full_estate.png` | QA 전용·번들 제외 |

후원은 연못·다리·정자·장독대·등·식재가 이미 한 장에 맺힌 레이어다.
따라서 다리는 반드시 물 위를 가로지르고, 별도의 계 연못이나 다리 파일을
합성하지 않는다.

## 고정 시각 계약

- 모든 지도 파일은 정확히 **1536×1152 (4:3)** 이다.
- 북쪽은 화면 위, 남쪽은 화면 아래이며 동서 지붕마루는 같은 수평 축을
  따른다.
- 상단 왼쪽 광원, 한지 질감, 고밀도 Faceted Minhwa, 같은 지붕 원근을
  유지한다.
- 바탕은 불투명 RGB이고, 구조·후원 레이어는 full-canvas RGBA이며 네 모서리
  alpha가 0이다.
- 새로운 문구·사람·라벨·마커를 PNG에 굽지 않는다. 지도 선택·오늘의 학습
  표시는 Flutter 레이어가 담당한다.

## 합성·교체 절차

`assets_unused/pending_review/reference_full_estate.png`는 독립 아트가 아니라,
현재 런타임 paint 순서로 합성한 완성 상태다. Flutter asset leaf인 `map/`에
복사하지 않는다. 구조·후원 중 한 장이라도 바꾸면 아래 순서를 같은 변경에 포함한다.

```powershell
python tool/check_personal_hanok_assets.py --write-reference
python tool/check_personal_hanok_assets.py
flutter test test/personal_hanok_asset_bundle_test.dart test/goldens/personal_hanok_map_golden_test.dart
```

검사기는 canvas, alpha, chroma-key, 투명 모서리뿐 아니라 완성 참조 전경이
실제 런타임 합성과 픽셀 단위로 일치하는지도 확인한다. 골든 3장은 빈터/중간/
완성 상태를 고정한다.

```powershell
flutter test --update-goldens test/goldens/personal_hanok_map_golden_test.dart
```

골든을 갱신하는 행위는 의도적인 아트 변경 승인이다. 단순 코드 수정으로는
갱신하지 않는다.
