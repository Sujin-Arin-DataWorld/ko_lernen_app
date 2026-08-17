# Hanok V1 A1-10 roof base — 2026-08-17

## 입력과 목표

- input:
  `assets_unused/pending_review/a1_layers/raw/09_rafters_roof_frame_recraft_20260817.png`
- input SHA-256:
  `89661c1d1c2d29896cccd5e449f3e4f93d1e177a048e682a5f9278d693cbddec`
- target stage: `10_roof_base`
- status: `approved_qa` (runtime/pubspec 미승격)

## 호출 프롬프트

```text
Edit this approved project-owned transparent A1-09 Korean hanok construction layer into the next cumulative state, A1-10 roof base. Preserve exactly the 2172×724 canvas, genuine transparent background, full stone foundation and front steps, seven cornerstone bases, exactly seven primary upright columns, every existing beam and changbang, the full purlin/dori system and central ridge purlin/jongdori, every open common rafter and corner hip rafter/chunyeo, all timber stacks and carts, column spacing, foundation footprint, object position, perspective, scale, colors, faceted-minhwa material treatment, and top-left lighting. Add only the unfinished roof-base construction above the rafters: a thin, accurately sloped layer of fitted wooden roof sheathing boards/gaepan that follows both roof planes, with a restrained dark brown-charcoal waterproof underlayer visible only as a narrow unfinished construction edge. Keep the projecting ends of the rafters and chunyeo visible below the new base so the prior frame remains legible. This must read as a bare roof substrate awaiting its final covering, not as a finished roof. Do not add, remove, duplicate, or move any of the seven primary columns or any existing timber frame. Do not add soil, clay buildup, thatch, straw bundles, roof tiles, ridge tiles, decorative ridge, finished eaves, plaster, walls, mid-height wall rails, ondol, maru, doors, windows, furniture, landscape, ground plane, people, animals, tools, text, labels, UI, border, watermark, shadow plane, matte, chroma, or illustrated checkerboard. Output exactly one 2172×724 RGBA PNG with real alpha to every edge. The foundation and lower 80-pixel footprint must remain pixel-consistent with A1-09 with zero additional horizontal drift. The only visible new construction is the thin wooden roof sheathing/gaepan and narrow waterproof roof-base layer above the existing rafters.
```

## 수락 조건

- A1-09와 동일한 wide canvas·기단·계단·목재·초석·7개 기둥·전체 상부 골조
- 새 구조는 얇은 개판/지붕 바탕과 좁게 드러난 방수 밑층뿐
- 서까래·추녀 끝이 아래에서 계속 보이고 완성 지붕처럼 보이지 않음
- 흙·보토·초가·볏짚·기와·용마루·벽·수장·창호 없음
- true RGBA alpha; checkerboard/matte/chroma 없음
- normalize 시 A1-09 대비 foundation IoU `>=0.94`, edge drift `<=12px`; 목표 `0px`
- 854×309 normalized RGBA, 1536×1152 RGB WebP `<=350000` bytes
- socket 밖 source 변경 0, decoded 밖 평균 오차 `<=5.0`
- 최종 육안 검수 전 QA-only, runtime/pubspec 승격 금지

## 생성·수정 결과

1. OpenAI ImageGen `exec-9b97a6d4-d5b7-4cea-b2e2-8703cbfd6880`
   (`2026-08-17T00:56:07Z`)은 기존 7개 기둥과 전체 골조를 유지하고 얇은 목재
   개판/지붕 바탕만 추가해 공정 의미를 통과했다. 그러나 배경을 실제 RGB
   체크무늬로 구워 거절했다.
   - rejected SHA-256:
     `e948b861ffbc22bed902c8f18e12e7b44f2b59349d158a4a9733a0ca00f047ed`
   - 2172×724 RGB, 1,790,898 bytes
2. 위 exact rejected SHA만 입력한 BBANANA Recraft Remove Background
   `cc7aed7530b5ceab8a695ae4aa8bb320`
   (`2026-08-17T00:56:53.366371Z`, 0.3 credit)로 geometry를 바꾸지 않고 true alpha만
   복구했다.
   - approved raw SHA-256:
     `25c0dfd28424dd90e34c783bf15f7352173e134663cda01b3ded58d724cafe79`
   - 2172×724 RGBA, 2,009,588 bytes

## 승인 산출물과 계측

- normalized layer:
  `assets_unused/pending_review/a1_layers/10_roof_base_layer.png`
  - SHA-256 `1ac3706b14c6da0b5491417096093b88b497aeea557a092b2c2fe5fa3bfcc40e`
  - 854×309 RGBA, 330,893 bytes, alpha 51.483%, anchor 1,011, chroma 0
- QA composite:
  `assets_unused/pending_review/a1_states/10_roof_base.webp`
  - SHA-256 `99157f9bf60a40a5534914cbb3007e47925b71f484f6d0753d01012f466ec20d`
  - 1536×1152 RGB WebP, 289,664 bytes
- A1-09 대비 foundation alpha IoU `0.9882462913`, edge drift `2px`
- source socket 밖 변경 `0px`, decoded 밖 평균 오차 `3.3375795205`
- 육안 검수: 정확히 7개 주기둥과 기존 골조가 유지되고 새 구조는 얇은 목재
  개판/지붕 바탕과 좁은 밑층뿐이다. 서까래 끝은 계속 보이며 흙·초가·기와·용마루·
  벽·수장·창호·문자·UI는 없다.
- 합성 WebP는 350,000-byte hard limit을 통과한다.
