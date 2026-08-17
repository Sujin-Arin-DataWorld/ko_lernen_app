# Hanok V1 A1-09 rafters/roof frame — 2026-08-17

## 입력과 목표

- input:
  `assets_unused/pending_review/a1_layers/raw/08_purlins_sangnyang_recraft_20260817.png`
- input SHA-256:
  `e7937f32ebc940de46c03f06240d2902c10abf6eadaa3b4303e5a60636d8f188`
- target stage: `09_rafters_roof_frame`
- status: `approved_qa` (runtime/pubspec 미승격)

## 호출 프롬프트

```text
Edit this approved project-owned transparent A1-08 Korean hanok construction layer into the next cumulative state, A1-09 rafters and roof frame. Preserve exactly the 2172×724 canvas, genuine transparent background, full stone foundation and front steps, seven cornerstone bases, exactly seven primary upright columns, every existing upper beam and changbang, the full purlin/dori system and central ridge purlin/jongdori, all timber stacks and carts, column spacing, foundation footprint, object position, perspective, scale, colors, faceted-minhwa material treatment, and top-left lighting. Add only the unfinished timber rafter frame: clearly separate parallel common rafters running down both roof slopes from the central ridge purlin across the existing purlins, plus structurally legible projecting corner hip rafters/chunyeo at the roof ends. Keep open air visible between every rafter so this reads as a bare skeletal roof frame. The rafters may create the future eave outline but must not create any continuous roof surface. Do not add, remove, duplicate, or move any of the seven primary columns, beams, changbang, purlins, or central jongdori. Do not add mid-height wall rails, wall framing, roof boards, roof decking, waterproofing, soil, thatch, roof tiles, ridge tiles, plaster, walls, ondol, maru, doors, windows, furniture, landscape, ground plane, people, animals, tools, text, labels, UI, border, watermark, shadow plane, matte, chroma, or illustrated checkerboard. Output exactly one 2172×724 RGBA PNG with real alpha to every edge. The foundation and lower 80-pixel footprint must remain pixel-consistent with A1-08. The only visible new construction is the separate common rafters and corner hip rafters/chunyeo above the existing purlins.
```

## 수락 조건

- A1-08과 동일한 wide canvas·기단·계단·목재·초석·7개 기둥·보·창방·도리·종도리
- 새 구조는 열린 간격의 평서까래와 끝 추녀뿐
- 개판·지붕 바탕·방수·흙·초가·기와·용마루·벽·수장 없음
- true RGBA alpha; checkerboard/matte/chroma 없음
- normalize 시 A1-08 대비 foundation IoU `>=0.94`, edge drift `<=12px`
- 854×309 normalized RGBA, 1536×1152 RGB WebP `<=350000` bytes
- socket 밖 source 변경 0, decoded 밖 평균 오차 `<=5.0`
- 최종 육안 검수 전 QA-only, runtime/pubspec 승격 금지

## 생성·수정 결과

1. OpenAI ImageGen `exec-87ba101c-75a6-4c27-8fb8-85dcc2c09011`
   (`2026-08-17T00:41:02Z`)은 기존 7개 기둥·보·창방·도리·종도리를 보존하고 열린
   평서까래와 끝 추녀만 추가해 공정 의미를 통과했다. 그러나 배경을 실제 RGB
   체크무늬로 구워 거절했다.
   - rejected SHA-256:
     `b0bd94cdbab621c95a6ae5a96e782c644cfd8376bcc2b3400ddebe3eff9a8810`
   - 2172×724 RGB, 1,705,744 bytes
2. 위 exact rejected SHA만 입력한 BBANANA Recraft Remove Background
   `6bca4ceed4988b469f76cfe1a8034fad`
   (`2026-08-17T00:43:14.045444Z`, 0.3 credit)로 geometry를 바꾸지 않고 true alpha만
   복구했다.
   - approved raw SHA-256:
     `89661c1d1c2d29896cccd5e449f3e4f93d1e177a048e682a5f9278d693cbddec`
   - 2172×724 RGBA, 1,948,122 bytes

## 승인 산출물과 계측

- normalized layer:
  `assets_unused/pending_review/a1_layers/09_rafters_roof_frame_layer.png`
  - SHA-256 `302e56c988e4ffeff73d5fc6d3ea75907f00758e3844f84781c2080aa017b16e`
  - 854×309 RGBA, 334,169 bytes, alpha 48.173%, anchor 1,011, chroma 0
- QA composite:
  `assets_unused/pending_review/a1_states/09_rafters_roof_frame.webp`
  - SHA-256 `c804e3666971c05d4300e5f7c4484006e353a6d075b3d6965b7ddd8b23c90bb8`
  - 1536×1152 RGB WebP, 294,896 bytes
- A1-08 대비 foundation alpha IoU `0.9723770087`, edge drift `12px`
- source socket 밖 변경 `0px`, decoded 밖 평균 오차 `3.3211533582`
- 육안 검수: 정확히 7개 주기둥과 기존 보·창방·도리·종도리가 유지되며, 새
  구조는 열린 평서까래와 양 끝 추녀뿐이다. 지붕 바탕·방수·초가·기와·벽·수장·
  문자·UI는 없다.
- edge drift는 계약 상한 `12px`와 정확히 같고 IoU는 최소 `0.94`를 통과한다.
  합성 WebP는 350,000-byte hard limit을 통과한다.
