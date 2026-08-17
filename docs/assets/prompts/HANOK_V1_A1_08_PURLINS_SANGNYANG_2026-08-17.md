# Hanok V1 A1-08 purlins/sangnyang — 2026-08-17

## 입력과 목표

- input:
  `assets_unused/pending_review/a1_layers/raw/07_beams_changbang_semantic_recraft_20260817.png`
- input SHA-256:
  `7d5bafe5720a2f6de555c2540eff326ee7352237495d997b6818aba09f32d0c0`
- target stage: `08_purlins_sangnyang`
- status: `approved_qa` (runtime/pubspec 미승격)

## 호출 프롬프트

```text
Edit this approved project-owned transparent A1-07 Korean hanok construction layer into the next cumulative state, A1-08 purlins and sangnyang. Preserve exactly the 2172×724 canvas, genuine transparent background, full stone foundation and front steps, seven cornerstone bases, exactly seven primary upright columns, all existing upper beams and changbang, every timber stack and cart, column spacing, foundation footprint, object position, perspective, scale, colors, faceted-minhwa material treatment, and top-left lighting. Add only the traditional roof-support purlin system above the existing beam line: short upper timber supports where structurally necessary, clearly joined longitudinal purlins/dori, and one visually legible central ridge purlin/jongdori that marks the sangnyang stage. These new timbers may establish the future roof slope but must remain an unfinished open timber skeleton. Do not add, remove, duplicate, or move any of the seven primary columns. Do not add mid-height wall rails, wall framing, rafters, corner rafters, eaves, roof decking, waterproofing, thatch, roof tiles, walls, plaster, ondol, maru, doors, windows, furniture, landscape, ground plane, people, animals, tools, text, labels, UI, border, watermark, shadow plane, matte, chroma, or illustrated checkerboard. Output exactly one 2172×724 RGBA PNG with real alpha to every edge. The foundation and lower 80-pixel footprint must remain pixel-consistent with A1-07. The only visible new construction is the purlins/dori and central ridge purlin/jongdori above the existing beams.
```

## 수락 조건

- source와 동일한 wide canvas·기단·계단·7개 기둥·상부 보/창방
- 새 구조는 도리와 종도리뿐
- 중간 벽선, 서까래, 추녀, 지붕 바탕, 초가/기와, 벽 없음
- true RGBA alpha; checkerboard/matte/chroma 없음
- normalize 시 A1-07 대비 foundation IoU `>=0.94`, edge drift `<=12px`
- 854×309 normalized RGBA, 1536×1152 RGB WebP `<=350000` bytes
- socket 밖 source 변경 0, decoded 밖 평균 오차 `<=5.0`
- 최종 육안 검수 전 QA-only, runtime/pubspec 승격 금지

## 생성·수정 결과

1. OpenAI ImageGen `exec-2a797766-fe18-4947-aa7a-44a979a07431`
   (`2026-08-17T00:23:51Z`)은 기둥 7개와 기존 보·창방을 유지하고 도리·종도리만
   추가해 공정 의미는 통과했다. 그러나 출력이 실제 alpha가 아닌 회색 체크무늬를
   구운 RGB여서 거절했다.
   - rejected SHA-256:
     `4f1d8dc0d096c5a4287f205b651665a3ac8a874d29a8648589218833dbce11a3`
   - 2172×724 RGB, 1,515,250 bytes
2. 위 exact rejected SHA만 입력한 BBANANA Recraft Remove Background
   `8df1f4be8afe1cb7f02e013ca8379e11`
   (`2026-08-17T00:24:41.217404Z`, 0.3 credit)로 의미 geometry는 바꾸지 않고
   true alpha만 복구했다.
   - approved raw SHA-256:
     `e7937f32ebc940de46c03f06240d2902c10abf6eadaa3b4303e5a60636d8f188`
   - 2172×724 RGBA, 1,704,489 bytes

## 승인 산출물과 계측

- normalized layer:
  `assets_unused/pending_review/a1_layers/08_purlins_sangnyang_layer.png`
  - SHA-256 `55cacd7ce2e8dc0ec43fb087a2a07fae76de31096437b60ae423af8be8fed8f5`
  - 854×309 RGBA, 264,817 bytes, alpha 41.873%, anchor 1,005, chroma 0
- QA composite:
  `assets_unused/pending_review/a1_states/08_purlins_sangnyang.webp`
  - SHA-256 `7155f41aaee633eaba177f934ed49c468383bea165753fadbea703f466dc54e9`
  - 1536×1152 RGB WebP, 280,338 bytes
- A1-07 대비 foundation alpha IoU `0.9971081451`, edge drift `0px`
- source socket 밖 변경 `0px`, decoded 밖 평균 오차 `3.3900208955`
- 육안 검수: 정확히 7개 주기둥, 기존 보·창방, 새 도리·종도리만 존재한다.
  중간 벽선·보조 기둥·서까래·지붕·벽·문자·UI는 없다.
- 280KB는 최적화 목표이고 350,000-byte hard limit이 정본 계약이다. 이 상태는
  고정 quality 82에서 280,338 bytes로 hard limit을 통과했다.
