# Hangul Sori — PNG Asset Prompt Sheet
## Plan: stately-rising-jongga (v2.0 한옥 퀘스트 업데이트)

> **작성일**: 2026-05-31
> **대상**: Jin (Hangul Sori 일러스트 양산)
> **역할**: `docs/ASSET_GENERATION_BIBLE.md`의 **상세 부록(낱장 95장 개별 프롬프트)**. 스타일 시스템·마스코트는 BIBLE이 최종, 이 파일은 한옥 12단계·장식·도장·스티커의 개별 정확 프롬프트 보관용.
> **스타일 기준**: `docs/ASSET_GENERATION_BIBLE.md` §1 (Faceted Minhwa — 모던 면 분할 민화)
> **참고 자료**: 첨부한 Pinterest 무드보드 12장 + 북촌 한옥마을 실사 사진 2장 + 솟을대문 일러스트 1장
> **총 자산 수**: ~95 PNG (한옥 24 + 퀘스트 17 + 도장 8 + 스티커 30 + 계 8 + 책 한 컷 5 + 출시 3)

---

## 0. 개요 & 사용 방법

### 0.1 워크플로우

1. **AI 생성기 선택**: Midjourney v6 / DALL-E 3 / Imagen 3 / Nano Banana 2 중 하나
2. **첨부 자료** (필수):
   - `docs/HANGUL_SORI_STYLE_GUIDE.md` 또는 그 핵심 섹션 텍스트
   - 기존 자산 1~2장 (예: `welcome-hero.png`, `madang(light).png`, `gate_final.png`)
3. **프롬프트 복붙**: 각 항목의 "영문 프롬프트" 그대로 복사 → 생성기에 붙여넣기
4. **반드시 마지막에 추가**: `IMPORTANT: match the geometric faceted style, color palette, paper grain texture, and overall mood of the attached reference images exactly. This must look like part of the same illustrated set.`
5. **3~5장 변주 생성** → 가장 일관성 있는 것 선택
6. **후처리**: 필요 시 Photoshop/Affinity Designer로 정리 (배경 투명화, 색상 미세 조정)

### 0.2 공통 규칙

- **포맷**: PNG-24, 알파 채널 O (배경 투명, 명시된 경우만 채움)
- **색 팔레트**: 디자인 가이드의 hex 값 엄수
- **압축**: Jin은 원본으로 두면 됨 — `pngquant` 후처리는 코드 통합 시 자동
- **저장 경로**: 각 항목에 명시
- **명명 규칙**: snake_case, 영문, 의미 명확 (예: `stage_empty_light.png`)

### 0.3 첨부 이미지 ID (Pinterest 무드보드 12장)

이 문서에서 "참고 이미지 #N"이라 적힌 것은 다음을 가리킴:

| # | 내용 | 사용처 |
|---|------|--------|
| 1 | 북촌 마을 실사 사진 + 한옥 마당 with pine | 한옥 12단계의 분위기·구도 reference |
| 2 | 솟을대문 일러스트 (chinese characters) | Stage 10 (솟을대문) + 가운데 plaque |
| 3 | 다양한 hanok 일러스트 (Booking.com, isometric pixel) | 통합 분위기 참고 |
| 4 | 사군자 패턴 + 보자기 + 노리개 | 사군자 퀘스트 + 단청 도장 |
| 5 | 야경 한옥 + 매화 + 한복 | 다크 모드 한옥 + 매화 퀘스트 |
| 6 | 한복 + 갓 + 부채 | 캐릭터 디테일 (까치의 갓 등) |
| 7 | 단청 패턴 detail + 한복 jeogori + 빗 | 단청 도장 + 풍경 |
| 8 | 단청 패턴 + 기와 line drawing | 단청 도장 base |
| 9 | 통영포립 갓 close-up | 까치 갓 디테일 |
| 10 | 한국 전통 소품 모음 | 스티커 소품군 (떡·차·부채·매듭) |
| 11 | 솟을대문 close-up + hanok illustrations | Stage 10 detail |
| 12 | 단청 패턴 collection (붉은/녹청/황 반복) | 단청 도장 색상 매핑 |

---

## 1. 표준 프롬프트 템플릿 (Faceted Minhwa)

각 자산 프롬프트는 다음 구조를 따른다. 변수 `[...]` 채우면 됨.

```
A [horizontal/vertical/square] editorial illustration of [SUBJECT/SCENE].
[ONE-SENTENCE MOOD/CONTEXT].

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial quality.

Composition layered front to back:

LAYER 1 — [Top zone / sky / framing]
- [Specific element with hex code]
- [Construction notes]

LAYER 2 — [Mid zone]
- [Element details]

LAYER 3 — [Foreground / focal point]
- [Element details]

ATMOSPHERIC DETAILS:
- Dancheong dots scattered sparsely in 2 loose groupings
  (red #C24A45, gold #DFA951, teal #3D9A7F)
- [Specific exclusions: NO crane / NO mixed seasons / etc.]

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT [one allowed gradient]
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette (hex): [list 8-12 key hex codes used]
- Clear silhouette readability at thumbnail size (100px)

Aspect ratio: [W:H] ([WIDTHxHEIGHT] pixels)

ABSOLUTELY AVOID:
- [Asset-specific exclusions]

This is editorial illustration for a premium Korean learning app —
[mood summary], magazine-cover quality.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 2. 카테고리 1 — 한옥 12단계 배경 (24 PNG)

> 사용자 마당이 학습 진행도에 따라 단계별로 자라난다.
> 12 단계 × light/dark 2 brightness = 24 PNG
> 모든 단계는 동일한 카메라 각도·구도 — 마당을 약간 위에서 바라보는 3/4 perspective.
> 사용자가 단계 전환 시 cross-fade 만 일어남 → **구도·시점 절대 통일** 중요.

### 2.0 단계 별 공통 사양

- **치수**: 1236×2700 (9:20, 기존 madang와 동일)
- **포맷**: PNG-24, 알파 X (배경 채움)
- **경로**: `assets/illustrations/hanok_stages/stage_{N}_{light|dark}.png`
- **카메라**: 3/4 view, 마당 정면에서 약 30도 위
- **하늘 영역**: 상단 30~40% (낮: cream → celadon 그라데이션 / 밤: deep navy → muted indigo)
- **마당 영역**: 중간 30%
- **건물·지면**: 하단 30~40%
- **참고 이미지**: #1 (북촌 한옥 마당), #5 (야경 한옥)

### 2.1 Stage 0 — Empty (빈 터) — `stage_empty_light.png` / `stage_empty_dark.png`

**참고 이미지**: #1 (마당 사진의 빈 공간 부분), #2 (대문 없이 빈 터)

**컴포지션 (front to back)**:
- **LAYER 1 — Sky** (상단 35%): 한지 cream `#FAF6EC` → sky celadon `#D8E5DC` 부드러운 단방향 그라데이션 (다크 모드: deep navy `#0A2E3A` → deeper navy `#061F28`). 작은 muted indigo 초승달 `#1F2E5C` 또는 vermillion 해 `#C24A45` 오른쪽 상단
- **LAYER 2 — Distant mountains** (중간 25%): irworobongdo 양식 산봉우리 3겹 — 가장 먼 산 cool neutral gray `#9A938C`, 중간 산 pale sage `#9BB0A0`, 가까운 산 mountain sage `#5C7060`. 모두 각진 평면 실루엣
- **LAYER 3 — Empty plot** (하단 40%): 흙바닥 stone gray `#8B8478`. 잡초 3~5 묶음 (작은 sage 풀잎). 경계선 stone gray 작은 자갈 4~6개로 표시 (앞으로 주춧돌이 놓일 위치 hint)
- **마당 중앙**: 8개 자리표시 작은 원 (희미한 dancheong gold `#DFA951` 30% opacity) — 다음 단계 주춧돌이 놓일 자리

**핵심 색상**: `#FAF6EC, #D8E5DC, #9A938C, #9BB0A0, #5C7060, #8B8478, #DFA951`
**다크 색상**: `#0A2E3A, #061F28, #1F2E5C, #15201A` (어둠 깔린 빈 터)

**영문 프롬프트**:
```
A vertical 9:20 editorial illustration of an empty Korean traditional
courtyard plot, ready to be built upon. Quiet contemplative dawn, a
sense of beginning.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper
era) crossed with Korean minhwa folk painting iconography. NOT cute,
NOT cartoonish — confident, contemporary, premium editorial quality.

Composition layered front to back:

LAYER 1 — Sky (top 35%)
- Hanji cream #FAF6EC at upper edge fading to sky celadon #D8E5DC at
  horizon (single soft gradient — only one allowed)
- A small muted-indigo crescent moon #1F2E5C in upper right
- Optional: 3-4 cloud-scroll motifs (구름문양) in pale ivory, clustered
  in upper-right

LAYER 2 — Distant mountains (middle 25%)
- Irworobongdo-style overlapping peaks, 3 receding layers
- Farthest peak cool neutral gray #9A938C
- Mid peak pale sage #9BB0A0
- Nearest peak mountain sage #5C7060
- All flat angular silhouettes, no detail

LAYER 3 — Empty earth plot (bottom 40%)
- Bare dirt courtyard in stone gray #8B8478 with subtle warmer ochre
  facets
- 3-5 small grass tufts in sage green, clustered NOT scattered
- A loose rectangular boundary marked by 6-8 small stones
- 8 faint dancheong-gold dots (#DFA951 at 30% opacity) inside the
  rectangle — placeholder marks for future foundation stones
- One small persimmon tree silhouette at far-left edge, bare branches

ATMOSPHERIC DETAILS:
- Two loose groupings of small dancheong color dots (red #C24A45,
  gold #DFA951, teal #3D9A7F): one near horizon, one near foreground
  stones
- NO buildings, NO animals, NO people
- NO crane, NO tiger, NO magpie
- NO outlines on subjects — pure color planes only

Style discipline (CRITICAL):
- NO smooth gradients within shapes EXCEPT the sky atmosphere gradient
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette (hex): #FAF6EC #F4E8D0 #D8E5DC #9A938C #9BB0A0
  #5C7060 #8B8478 #DFA951 #1F2E5C #C24A45
- Clear silhouette readability — the empty plot must read clearly even
  at thumbnail size

Aspect ratio: 9:20 vertical (1236x2700 pixels)

ABSOLUTELY AVOID:
- Any building, gate, wall, or roof
- Cute cartoon style
- Scattered random elements
- Sepia wash without cool anchors
- Modern objects (cars, wires, signs)

This is editorial illustration for a premium Korean learning app — a
quiet, hopeful beginning, magazine-cover quality.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

**다크 변형 추가 지시**: "Render the same scene at twilight/night: sky becomes deep navy #0A2E3A fading to deeper navy #061F28 at top, with pale ivory full moon #F4E8D0 at 30% opacity. Mountains become darker silhouettes. Earth becomes dark earth #15201A. Add tiny scattered star dots in upper sky. Persimmon tree silhouette becomes cool dark slate #1F2A2E."

**DO**: 빈 터의 가능성·기대감 표현. Negative space 풍부. 자갈은 클러스터 2 그룹.
**DON'T**: 건물·문·동물·사람 그리지 말 것. 너무 황량하지 말 것 (잡초·달·산이 따뜻함 줌).

---

### 2.2 Stage 1 — Foundation (주춧돌) — `stage_foundation_{light|dark}.png`

**참고 이미지**: #1 (마당 사진)

**변화점 (Stage 0과 비교)**: 마당 중앙 자리표시 8개 자리에 **실제 주춧돌** (cut granite blocks) 8개가 놓임. 정사각형으로 배치 (4개씩 2열). 잡초는 사라짐 (마당 다듬어짐).

**컴포지션** (front to back): Sky / Mountains 동일. 차이는 LAYER 3:
- **마당 중앙**: 8개 주춧돌 — 각각 가로 60px / 세로 30px / 높이 20px 정도, 3D 입체감을 facet으로 표현 (상단 stone gray `#8B8478`, 측면 shadow `#5C4028`)
- 주춧돌 사이 거리: 가로 4개 간격 일정, 세로 2열
- 흙바닥은 다듬어진 sandy earth `#9A938C` (조금 더 밝아짐)
- 자갈 경계선은 더 정돈됨

**핵심 색상 추가**: stone gray `#8B8478`, walnut shadow `#5C4028`

**영문 프롬프트** (Stage 0 변형):
```
Same as Stage 0 (empty plot) but with the following changes in LAYER 3:

LAYER 3 — Foundation laid (bottom 40%)
- 8 cut granite foundation stones (주춧돌) arranged in a rectangle:
  4 stones across × 2 rows (representing future column positions)
- Each stone: rectangular block, top face stone gray #8B8478,
  shadow facet walnut shadow #5C4028 on right edge — 3D volume via
  hard-edged facet shift
- Stones evenly spaced, NOT random
- Sandy earth courtyard #9A938C (cleaner than Stage 0)
- Grass tufts removed — earth is now leveled and prepared
- Faint dancheong-gold placeholder dots REMOVED — stones replace them
- Stone boundary markers remain at courtyard edges

Everything else (sky, mountains, persimmon tree silhouette) remains
identical to Stage 0 reference.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line as Stage 0]
```

**DO**: 주춧돌의 무게감·견고함. 직선적 배치.
**DON'T**: 주춧돌을 둥글게 그리지 말 것 (각진 직육면체). 너무 크지 말 것 (마당 풍경의 1/3 차지하지 않게).

---

### 2.3 Stage 2 — Pillars (기둥 세우기) — `stage_pillars_{light|dark}.png`

**변화점**: 주춧돌 위에 **4개 굵은 나무 기둥** (기둥) 세워짐. 기둥 모서리에 위치.

**컴포지션 변화**:
- **LAYER 3**: 8개 주춧돌 중 모서리 4개 위에만 기둥 (4 corners). 안쪽 4개는 주춧돌만.
- 기둥: 가로 30px / 세로 600~700px / facet 입체 (앞면 warm walnut `#8E6646`, 안쪽 그림자 walnut shadow `#5C4028`)
- 기둥 상단은 캔버스 끝까지 닿지 않게 — 윗부분은 아직 비어있음 (다음 단계에서 보를 얹음)
- 작은 까치 한 마리 — 가장 왼쪽 기둥 꼭대기에 perched (selectively appear from this stage onwards as a witness/companion)

**핵심 색상 추가**: warm walnut `#8E6646`, walnut shadow `#5C4028`, deep walnut `#3E3024`

**영문 프롬프트** (Stage 1 변형):
```
Same composition as Stage 1 (foundation stones) but with the following
addition in LAYER 3:

LAYER 3 ADDITION — Wooden pillars rising
- 4 thick wooden pillars (기둥) raised on the 4 CORNER foundation
  stones only — inner 4 stones remain empty for now
- Each pillar: vertical rectangle, primary face warm walnut #8E6646,
  inner-edge shadow facet walnut shadow #5C4028
- Pillars rise to roughly 60% of canvas height — tops do NOT meet
  any horizontal element yet (skeleton phase, awaiting beam)
- A small gat-wearing magpie (갓 까치) perches on the top of the
  leftmost pillar — black + white body, gold-amber beak, tiny tilted
  flat oval brim + tall cylindrical crown gat hat with thin gold band
- The magpie is a witness/companion figure — small, deliberate placement

Everything else (sky, mountains, distant persimmon tree, sandy earth,
foundation stones) remains identical to Stage 1.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 기둥의 수직성 강조. 까치는 작지만 인상적이게.
**DON'T**: 기둥 위에 뭔가 얹지 말 것 (다음 단계에서 추가). 까치 머리 위 갓 비율 정확히 (#9 참고).

---

### 2.4 Stage 3 — Beams + Rafters (대들보·서까래) — `stage_beams_{light|dark}.png`

**변화점**: 기둥 위에 **가로 대들보** + 그 위로 **서까래** 줄지어 얹힘. 한옥 구조 골조 완성.

**컴포지션 변화**:
- **LAYER 3 ADDITION**:
  - **대들보 (main beam)**: 4개 기둥을 가로지르는 굵은 walnut 수평 빔
  - **서까래 (rafters)**: 대들보 위에서 부채꼴로 펼쳐지는 좁은 walnut 막대들 (10~12개), 끝부분이 캔버스 위쪽으로 향함 (지붕 곡선 hint)
  - 까치는 대들보 위로 이동 (or 가운데 기둥에 새 까치 추가)

**영문 프롬프트** (Stage 2 변형):
```
Same composition as Stage 2 (pillars) but with the following addition
in LAYER 3:

LAYER 3 ADDITION — Skeletal roof structure
- A single thick horizontal main beam (대들보) spans the tops of all
  4 corner pillars — primary face warm walnut #8E6646, bottom shadow
  facet deep walnut #3E3024
- 10-12 narrow rafter sticks (서까래) emerge from the beam, fanning
  upward and outward in a slight curve — each rafter a thin walnut
  rectangle, top edges suggesting a future roof line
- Rafter ends visible as small uniform brown rectangles in cherry
  wood #7E5A3D, like dark teeth lining the eaves
- The magpie now perches on the main beam (center-left position),
  same gat hat as before
- Sky-gradient still visible behind/between rafters

Everything else (mountains, foundation stones, earth) remains identical.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 골조의 기하학적 아름다움. 부채꼴로 펼쳐지는 서까래의 리듬.
**DON'T**: 지붕 덮개를 그리지 말 것 (다음 단계). 서까래가 너무 빽빽하지 말 것 (사이로 하늘 보여야 함).

---

### 2.5 Stage 4 — Thatch Roof (초가지붕) — `stage_thatch_{light|dark}.png`

**변화점**: 서까래 위에 **초가지붕** (황금 짚) 얹힘. 첫 집 완성 — 소박하지만 따뜻한 시골 정서.

**컴포지션 변화**:
- 골조 위에 부드러운 dome 모양 thatch 지붕 — color: ochre gold `#DFA951` + warm walnut shadow `#8E6646` (앞부분 highlight, 아래 그림자)
- 처마 끝 약간 처짐 (한국 초가 특유의 형태)
- 마당 양쪽에 작은 낮은 벽 (white wall + stone base 시작 — Stage 8에서 완성될 외벽 hint)
- 까치 두 마리 — 하나는 지붕 위, 하나는 마당 가운데

**영문 프롬프트**:
```
A vertical 9:20 editorial illustration of a humble first hanok with
golden thatched roof, freshly built, sitting in a Korean courtyard
with distant irworobongdo mountains. A sense of warm accomplishment.

[Standard Layer 1 sky + Layer 2 mountains as before]

LAYER 3 — Thatched roof house complete
- The wooden skeleton from prior stages is now covered with a
  rounded, slightly-domed golden thatch roof
- Primary thatch color: dancheong gold #DFA951 with strong warm
  walnut #8E6646 shadow facets on the underside and right edge
- Eaves slightly drooping at corners (Korean thatch character, NOT
  Chinese pagoda style)
- 4 wooden pillars still visible in primary face warm walnut #8E6646
- Foundation stones (granite gray #8B8478) still visible at base
- Sandy courtyard earth #9A938C
- 2 magpies (갓 까치): one perched on roof ridge, one in the
  courtyard ground — both with tiny flat-oval-brim cylindrical-crown
  gat hats with gold band

ATMOSPHERIC DETAILS:
- Small clusters of golden grass tufts at house base, 2 groupings
- Persimmon tree at far left now has 2-3 small ochre persimmon discs
  hanging
- Two loose dancheong dot groupings: one in the sky, one near the
  house base

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 초가지붕의 둥근 곡선 (Korean style — NOT Chinese pagoda 뾰족함).
**DON'T**: 검정 기와 그리지 말 것 (다음 단계). 너무 크지 말 것 (작고 소박한 첫 집).

---

### 2.6 Stage 5 — Tile Roof Partial (기와 부분) — `stage_tile_partial_{light|dark}.png`

**변화점**: 초가지붕이 **부분적으로 검정 기와로 교체** 중. 절반은 짚, 절반은 기와.

**컴포지션 변화**:
- 지붕 한쪽 (왼쪽 또는 오른쪽 50%): 검정 곡면 기와 (curved tile) — hanok slate `#2A3340` + deep slate `#1A2028` shadow facet, 작은 반원 facet 줄지어 정렬
- 나머지 절반: 황금 짚 그대로
- 처마 끝 망와 (tile cap) cream-ochre 작은 원 1~2개

**영문 프롬프트**:
```
Same scene as Stage 4 (thatch roof complete) but with the LEFT HALF
of the roof now replaced by traditional Korean curved black-clay
tiles (기와). The transition shows clear progress — half thatch
(dancheong gold #DFA951), half tile (hanok slate #2A3340 with deep
slate #1A2028 shadow facets).

Tile row construction:
- Curved tiles arranged in rows along the slope
- Each tile a small semicircle facet, hanok slate primary, deeper
  slate shadow on underside
- Strong upturned eave horns (처마끝) on the tiled left side
- Right side still soft golden thatch
- Eave tip on tiled side shows 1-2 small chrysanthemum-disc tile
  caps (망와) in cream #F4E8D0 + ochre #DFA951
- Magpie perches on the boundary line between thatch and tile

Everything else remains identical to Stage 4.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 한국 기와의 특징 강조 — 처마 끝이 위로 살짝 들림 (upturned horn). 곡면 기와 facet으로 표현.
**DON'T**: 일본/중국식 지붕 그리지 말 것 (처마 곡선 다름).

---

### 2.7 Stage 6 — Tile Roof Complete (기와 완성) — `stage_tile_complete_{light|dark}.png`

**변화점**: 전체 지붕이 검정 기와. 짚은 사라짐.

**컴포지션 변화**:
- 지붕 전체 hanok slate `#2A3340`
- 강한 upturned eaves 양쪽
- 망와 (chrysanthemum disc tile caps) 양쪽 처마 끝에
- 까치 두 마리 — 양쪽 처마 끝에 각각

**영문 프롬프트**:
```
Same scene as Stage 5 but with the ENTIRE roof now covered in
traditional Korean curved black-clay tiles (기와). No thatch
remaining. Strong dignified hanok presence emerging.

Roof construction:
- Full curved black tile coverage, hanok slate #2A3340 primary,
  deep slate #1A2028 shadow facets
- Strong upturned eave horns on BOTH sides (처마끝) — confident
  Korean curve, NOT Chinese pagoda
- Both eave tips show chrysanthemum-disc tile caps (망와) in cream
  + ochre — small details, 2 per side
- Rafter ends (서까래) visible as a row of small uniform brown
  rectangles (cherry wood #7E5A3D) tucked under the eaves on both
  sides, like teeth following the eave curve
- Underside of eaves in deeper hanok slate / dark slate facet for
  depth

2 magpies on each upturned eave horn, facing slightly inward —
balanced composition.

Everything else (pillars, foundation, sandy courtyard, mountains,
sky) remains identical.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 한옥 지붕의 위엄. 양쪽 대칭 (까치 균형).
**DON'T**: 너무 어둡지 말 것 (slate에 충분한 highlight).

---

### 2.8 Stage 7 — Dancheong (단청) — `stage_dancheong_{light|dark}.png`

**참고 이미지**: #7, #8, #12 (단청 패턴 detail)

**변화점**: 처마 아래에 **단청 색띠** 추가 — teal base + alternating geometric color squares.

**컴포지션 변화**:
- 처마 underside에 dancheong band: teal `#3D9A7F` base + 작은 사각형 안에 red/gold/cream 교대 + 작은 lotus motif
- 기둥 상단에도 dancheong 색띠 작게

**영문 프롬프트**:
```
Same scene as Stage 6 but with traditional Korean dancheong (단청)
painted decoration now visible on the eave undersides and column
tops. The hanok becomes ornate and ceremonial.

Dancheong band specifications:
- Base color: dancheong teal #3D9A7F covering eave underside
- Small alternating geometric color squares in 2 rows:
  - Dancheong red #C24A45
  - Dancheong gold #DFA951
  - Hanji cream #FAF6EC
- Small flower or lotus motifs inside selected squares
- Same dancheong band reduced size on column tops (capital area)
- Match the visual character of attached dancheong reference images:
  precise geometric grid, jewel tones, no outlines

The hanok now looks ceremonial — dignified, painted, alive.

Everything else remains identical to Stage 6.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 단청 패턴은 attached 참고 #7, #8, #12와 같은 정확한 grid 형태.
**DON'T**: 단청을 너무 화려하게 산만하게 그리지 말 것 (band area에만 절제됨).

---

### 2.9 Stage 8 — Gate (솟을대문) — `stage_gate_{light|dark}.png`

**참고 이미지**: #2 (솟을대문 일러스트), #11 (솟을대문 close-up)

**변화점**: 마당 앞쪽에 **솟을대문** + 양쪽으로 **낮은 외벽** 완성. 한옥 외관 완성.

**컴포지션 변화**:
- **외벽** (전경): 하얀 회벽 `#FAF6EC` 면 + 아래 stone gray `#8B8478` base + 위에 작은 기와 trim
- **솟을대문** (중앙 전경): 두 짝 나무 문 — warm walnut + 검은 쇠 못 (round dots), 위에 작은 기와 지붕 (한옥 본채보다 작음), 上 가운데 작은 plaque (참고 #2의 한자 부분처럼)
- 까치 한 마리 — 대문 지붕에

**영문 프롬프트**:
```
A vertical 9:20 editorial illustration of a complete hanok compound:
the main tile-roof house behind a traditional Korean entrance gate
(솟을대문) with low courtyard walls. Dignified estate emerging.

[Standard Layer 1 sky + Layer 2 mountains as before]

LAYER 3 — Foreground gate and walls
- Left and right of canvas, low white-plaster courtyard walls
  (회벽), top edge capped with small curved tile (hanok slate
  #2A3340), base in stone gray #8B8478 with brick pattern facets
- Centered at the bottom: a 솟을대문 (Korean estate gate):
  - Two heavy wooden doors in warm walnut #8E6646 with deep
    walnut #3E3024 shadow facets
  - Vertical row of round iron studs (stripe black #1A1410) on
    each door — clean grid pattern, ~5x3
  - Small tile roof above gate, smaller than main house, hanok
    slate with upturned eave corners
  - A small horizontal calligraphy plaque (편액) above the doors
    in dark walnut frame with cream paper backing — could show 2-3
    simple Korean/hanja-style decorative characters in subtle ink
  - Stone steps in stone gray leading up to the doors (3 wide steps)

LAYER 4 — Main hanok house (mid-back, behind gate)
- The full tile-roof hanok from Stage 7 (with dancheong) visible
  through/over the gate, slightly receded
- Magpie on the gate's tile roof ridge

ATMOSPHERIC DETAILS:
- Small pine branch silhouette extending in from left edge
- Two dancheong dot clusters as before

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 솟을대문의 위엄·격식. 참고 #2의 디테일 수준 따라가기.
**DON'T**: 대문이 본채 가리지 말 것 (본채가 뒤로 보여야 함).

---

### 2.10 Stage 9 — Windows + Lattice Doors (창호지문) — `stage_windows_{light|dark}.png`

**변화점**: 본채에 **격자 창호지문** + **마루** (porch) 디테일 추가. 안채 공간감 완성.

**컴포지션 변화**:
- 본채 앞면에 격자 창호지문 (lattice paper door) — 작은 사각 grid의 walnut frame + 한지 cream paper backing, 따뜻한 황색 빛이 안쪽에서 새어나옴
- 본채 앞 마루 (raised wooden porch) — warm walnut + 가장자리 deep walnut shadow

**영문 프롬프트**:
```
Same scene as Stage 8 but with the main hanok house now fully
detailed with traditional lattice paper doors (창호지문) and a
raised wooden porch (마루) at the front.

Door details:
- Front-facing wall of the main house now has 3-4 lattice paper
  doors side by side
- Each door: small rectangular grid of panes in warm walnut #8E6646
  frame, hanji cream #FAF6EC paper backing
- Warm interior glow visible through the lattice — pale ochre
  #DFA951 at low opacity, suggesting lamplight inside
- A raised wooden porch (마루) runs along the front of the house,
  warm walnut floor with deep walnut #3E3024 shadow on facing edge
- A pair of folded shoes (small cream + dark facets) on the porch
  step as a homey detail

Magpies: one on porch railing, one on gate roof.

Everything else remains identical to Stage 8.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: 창호지문 안쪽의 따뜻한 빛 (한지 발광).
**DON'T**: 격자 너무 빽빽하지 말 것.

---

### 2.11 Stage 10 — Side Building (사랑채) — `stage_side_building_{light|dark}.png`

**변화점**: 본채 옆에 **사랑채** (별채) 추가. 마당이 ㄱ자 또는 ㄷ자 배치.

**컴포지션 변화**:
- 본채 오른쪽(또는 왼쪽)에 한 단 작은 별채 — 동일 스타일 (slate tile roof + dancheong + walnut pillars + lattice doors), 본채의 약 70% 크기
- 마당이 두 건물 사이 공간으로 확장
- 마당에 작은 디딤돌 (stepping stones) 1~2개

**영문 프롬프트**:
```
Same scene as Stage 9 but now with a second smaller hanok building
(사랑채, side building) annexed perpendicular to the main house,
forming an L-shaped layout around the courtyard.

Side building specifications:
- Smaller than main house (~70% size), same architectural language:
  - Hanok slate #2A3340 curved tile roof with upturned eaves
  - Warm walnut pillars and lattice doors
  - Dancheong band on eaves
  - Raised wooden porch
- Positioned at right edge of canvas (or left), perpendicular to
  main house (L-shape)
- 1-2 flat stepping stones (stone gray #8B8478) in courtyard
  connecting main house to side building

The courtyard now feels enclosed, intimate, three-sided.

Magpies: one on each roof + one in courtyard (3 total)

Everything else remains identical.

[Apply same Style discipline, palette, exclusions, and IMPORTANT
closing line]
```

**DO**: ㄱ/ㄷ자 한옥 배치의 친밀감.
**DON'T**: 별채가 본채와 같은 크기로 그리지 말 것 (subordinate building).

---

### 2.12 Stage 11 — Jongga Complete (종갓집) — `stage_jongga_{light|dark}.png`

**변화점**: **종갓집 완성** — 정원·연못·매화나무·소나무·낙관까지. 사용자 닉네임 편액 추가 (편액 자리만 비워둠).

**컴포지션 변화**:
- 마당에 작은 연못 (작은 청자 색 타원) + 안에 잉어 한 마리
- 마당 한쪽에 매화나무 (꽃 핀 상태)
- 다른 쪽에 노송
- 본채 옆에 장독대 (작게)
- 사랑채 옆에 별당 (작은 정자)
- 솟을대문 plaque에 placeholder 글자 (코드에서 사용자 닉네임으로 overlay 예정)
- 까치 4~5마리 — 곳곳에
- 호랑이 한 마리 — 마당 한쪽에 누워있거나 앉아있음 (수호자)

**영문 프롬프트**:
```
A vertical 9:20 editorial illustration of a complete Korean
jongga (head family estate) — the culmination of the building
journey. Spring season, blooming, peaceful, dignified guardian.

[Standard Layer 1 sky + Layer 2 mountains, but slightly more
celebratory: vermillion sun #C24A45 visible upper-right]

LAYER 3 — Full estate

Main house, side building (Stage 10), gate, walls — all preserved.

ADDITIONS:
- Small oval pond (청자 teal #3D9A7F) in courtyard with one
  orange-red koi carp facet shape
- Plum tree (매화) at left courtyard edge — angular dark walnut
  branches with 5-petal pale plum-pink #E8B5BC blossoms clustered
- Old pine (노송) at right courtyard edge — angular dark green
  triangular needle clusters on warm walnut trunk
- Small jangdokdae (jar terrace) beside main house — 5-7 fermentation
  jars (rounded ochre brown facets) on stone platform
- Small octagonal pavilion (정자) beyond side building — slate tile
  roof on 4 thin pillars
- Calligraphy plaque (편액) on the gate above the doors: SHOW AS
  EMPTY cream paper background with thin walnut frame — placeholder
  for user nickname (will be overlaid by app code)
- One Korean tiger (호랑이) seated in the courtyard — confident
  guardian, NOT cute:
  - Burnt orange #E87830 coat with rust orange #C25420 shadow facets
  - Tiger cream #F4E8D0 belly and chin
  - Stripe black #1A1410 angular stripes
  - 王 character visible on forehead in stripe black
  - Sharp almond-shaped amber-gold eyes
  - Frontal pose with slight 3/4 turn, seated dignified
- 4-5 magpies distributed: on each roof, on plum tree, in courtyard

ATMOSPHERIC DETAILS:
- 2-3 cloud scrolls in sky
- Subtle plum petals drifting (very few, NOT scattered all over)
- Soft pink dawn tint at horizon — one allowed gradient
- Persimmon tree silhouette removed (mature estate has displaced it)

This is the celebratory final state — every element has narrative
purpose, NOT decoration.

ABSOLUTELY AVOID:
- Cute/chibi tiger
- Autumn maple leaves (commit to spring)
- Random scattered petals
- Crowded composition (still leave breathing room)

[Apply same Style discipline, palette, and IMPORTANT closing line]
```

**다크 변형 추가**: "Night version: navy sky with cream-ivory full moon #F4E8D0 at 30% opacity, lattice doors glowing warmly from interior lamplight, dancheong jewels still visible but more muted, tiger silhouette in cool dark slate, magpies visible on illuminated roofs."

**DO**: 모든 요소가 의도적. 호랑이는 위엄 있게 (참고 #1의 dignified energy).
**DON'T**: 한꺼번에 모든 데코 다 그리지 말 것 (사용자 마당은 quest decorations로 별도 추가). Stage 11는 base estate만.

---

## 3. 카테고리 2 — 특별 퀘스트 영구 장식 (17 PNG)

> 사용자가 특별 퀘스트 클리어 시 마당에 영구 추가되는 장식.
> 각각 **transparent PNG**, 마당 배경 위에 stack됨.
> 크기는 마당 캔버스 1236×2700 대비 적정 비율.

### 3.0 공통 사양

- **포맷**: PNG-24, 알파 O (배경 투명 필수)
- **경로**: `assets/illustrations/decorations/{quest_id}.png`
- **카메라 각도**: Stage 0~11와 동일 3/4 view (합성 시 자연스럽게 어울리게)
- **그림자**: 자체 그림자 약간 (밑부분 어두운 facet) — 마당 위에 떠있는 느낌 X
- **참고 자료**: 디자인 가이드 §5 단청 색상 + 각 항목 참고 이미지

### 3.1 장독대 (Jar Terrace) — `decoration_jangdokdae.png`

**조건**: A1+A2 음식 단어 50개 마스터
**위치 (마당 합성)**: 본채 오른쪽 옆 빈 공간
**치수**: 600×400 px (마당 대비 ~30%)

**컴포지션**:
- **돌단 platform** (stone gray `#8B8478`): 직사각형, facet 3개로 입체감
- **항아리 5~7개** 위에 배치:
  - 가장 큰 항아리 가운데: 짙은 ochre brown `#A87E5E`
  - 옆 작은 항아리들: 다양한 brown tones (`#8E6646`, `#7E5A3D`, `#5C4028`)
  - 각 항아리: 둥근 hourglass 실루엣 (입구·바닥 좁고 가운데 풍성), 표면 shadow facet 한쪽
- **뚜껑** (검은 dome): hanok slate `#2A3340`
- 항아리에 김치 빨간 라벨 1~2개 (작은 dancheong red `#C24A45` 점)
- 가장자리에 작은 들풀 2~3 가닥

**영문 프롬프트**:
```
A transparent PNG of a traditional Korean jangdokdae (장독대) —
a stone platform with 5-7 ceramic fermentation jars (옹기), set
for use as a layered decoration over a hanok courtyard scene.

Mid-century modernist faceted style. NO outlines on subjects.

Composition:
- Rectangular stone platform base in stone gray #8B8478 with
  walnut shadow facet on right edge for 3D volume
- 5-7 ceramic jars on platform, varying sizes:
  - Largest jar center-back: ochre brown #A87E5E primary, warm
    walnut #8E6646 shadow facet on right
  - Smaller jars in foreground: varying browns (#8E6646, #7E5A3D)
  - All jars hourglass-shaped (narrow top, narrow bottom, full body)
  - Each jar has a black hanok slate #2A3340 dome lid
- 1-2 jars showing a small red dancheong dot #C24A45 (kimchi marker)
- 2-3 small grass tufts at base
- Subtle hanji paper grain texture
- Subtle ground shadow below platform (very soft, low opacity)

Aspect ratio: 3:2 (600x400 pixels). PNG with full alpha channel
transparency around the jangdokdae — composite over any background.

ABSOLUTELY AVOID:
- Outlines around jars
- Pastel/candy colors
- Modern jar shapes (cylinder)
- Cartoon style

This must match the Faceted Minhwa style of attached reference
illustrations — same palette, same paper grain, same overall feel.

IMPORTANT: render with transparent background so this can be layered
over courtyard scenes.
```

**DO**: 한국 옹기 특유의 hourglass 실루엣.
**DON'T**: 원기둥 항아리 X. 너무 화려한 라벨 X.

---

### 3.2 매화나무 (Plum Tree) — `decoration_maehwa.png`

**조건**: A2 형용사·감정 단어 30개 마스터
**위치**: 마당 왼쪽 빈 공간
**치수**: 500×800 px

**컴포지션**:
- 어두운 각진 줄기 (dark walnut `#3E3024`, walnut shadow `#5C4028` facet)
- 가지가 위로 사방으로 펼쳐짐 — 각진 형태
- 5-petal 매화 꽃송이 클러스터 (plum pink `#E8B5BC` + 가운데 gold dot `#DFA951`)
- 꽃은 가지 끝 + 중간 클러스터 (균등 분포 X, 의도적 클러스터링)

**영문 프롬프트**:
```
A transparent PNG of a Korean plum tree (매화) in full spring
bloom, set for layered composition over a hanok courtyard.

Faceted minhwa style:
- Dark angular trunk in deep walnut #3E3024 with walnut shadow
  facet #5C4028 on right side
- Branches reach upward and outward — angular zigzag character,
  NOT smooth organic curves
- Clustered 5-petal plum blossoms in plum pink #E8B5BC, each with
  a tiny gold #DFA951 center dot
- Blossoms clustered in 2-3 dense groupings, NOT scattered evenly
- A few muted dusty pink #D8B5B5 petals drifting near base (very
  few, 3-5 total)
- Some bare angular branches showing — NOT every twig has flowers

Aspect ratio: roughly 5:8 vertical (500x800 pixels)
Transparent background.

ABSOLUTELY AVOID:
- Soft smooth curves
- Pastel washed-out colors
- Realistic cherry blossom (this is plum, not sakura)
- Outlines

[Same style discipline closing as previous]
```

**DO**: 매화는 각진 가지가 핵심 (참고 #5).
**DON'T**: 일본 벚꽃처럼 그리지 말 것 (꽃 더 크고 산만).

---

### 3.3 노송 (Old Pine) — `decoration_sonamu.png`

**조건**: B1 시나리오 10개 완료
**위치**: 마당 오른쪽 빈 공간
**치수**: 600×900 px

**컴포지션**:
- 굵은 비틀린 줄기 (warm walnut + cherry wood + deep walnut facets — 3톤으로 입체 표현)
- 줄기 표피 facet으로 거친 질감
- 가지가 옆으로 펼쳐짐 (가로지향) — 일본/중국 송보다 한국 송 특유의 layered 형태
- 잎: 각진 삼각형 클러스터 (mountain teal `#3D9A7F` + mountain sage `#5C7060` 어두운 facet)

**영문 프롬프트**:
```
A transparent PNG of an old Korean pine (노송/소나무) for layered
composition over a hanok courtyard. Dignified, ancient.

Faceted minhwa style:
- Thick twisted trunk with multiple wood-tone facets:
  - Primary face warm walnut #8E6646
  - Mid shadow cherry wood #7E5A3D
  - Deep shadow walnut shadow #5C4028
  - Darkest crevices deep walnut #3E3024
- Trunk angular, NOT smooth — segmented facets suggesting bark
- Branches reach horizontally outward in 2-3 layers (Korean pine
  character, NOT Japanese bonsai vertical)
- Foliage clusters: angular triangular needle bundles
  - Primary green mountain teal #3D9A7F
  - Darker shadow facet mountain sage #5C7060
- 3-4 main foliage clusters, NOT a continuous mass
- A single magpie may perch on a branch (optional, can be removed
  if scene has too many magpies)

Aspect ratio: 2:3 vertical (600x900 pixels)
Transparent background.

[Same style discipline closing]
```

**DO**: 한국 노송의 가로 펼침. 줄기의 비틀림.
**DON'T**: 분재처럼 작게 X. Cone형 크리스마스트리 X.

---

### 3.4 연못 + 잉어 (Pond + Carp) — `decoration_pond.png`

**조건**: 자연·날씨 단어 마스터
**위치**: 마당 가운데 또는 한쪽
**치수**: 500×350 px

**컴포지션**:
- 타원형 연못 (mountain teal `#3D9A7F` 표면 + 가장자리 sage `#5C7060` 어두운 facet)
- 표면에 작은 잔물결 facet 2~3줄 (lighter teal)
- 잉어 1~2마리: orange-red `#D8742E` + 몸통 stripe black 패턴
- 가장자리에 연잎 1~2장 (작은 sage 원반)
- 연꽃 한 송이 (plum pink + 가운데 gold)

**영문 프롬프트**:
```
A transparent PNG of a small Korean traditional courtyard pond
with koi carp and a lotus, for layered composition.

Faceted minhwa:
- Oval pond shape, primary surface mountain teal #3D9A7F, edge
  shadow facet mountain sage #5C7060 (darker for water depth)
- 2-3 ripple lines in pale teal #D8E5DC on water surface (very
  subtle facet shifts, not gradients)
- 1-2 koi carp visible: persimmon orange #D8742E body, with a
  few angular stripe black #1A1410 streaks for pattern
- 1-2 round lotus pads (round flat sage circles) on water
- 1 lotus flower bloom: plum pink #E8B5BC petals + gold #DFA951
  center
- Slight cream stone rim at pond edge (stone gray #8B8478) — pebble
  facets, 4-6 stones

Aspect ratio: 10:7 horizontal (500x350 pixels)
Transparent background.

[Same style discipline closing]
```

**DO**: 연꽃·잉어·연잎 균형감 있게.
**DON'T**: 연못에 너무 많은 요소 X (3~4개 element 최대).

---

### 3.5 장명등 (Stone Lantern) — `decoration_seokdeung.png`

**조건**: 발음 평가 80%+ 100회
**위치**: 마당 가장자리 또는 입구
**치수**: 300×650 px

**컴포지션**:
- 다층 석등 (stone gray + 어두운 facet) — 4단 구조:
  1. 받침대 (넓은 base)
  2. 줄기 (narrow column)
  3. 등불칸 (square box with 4 lattice windows)
  4. 지붕 (작은 기와 형태)
- 등불칸 안쪽에서 따뜻한 황색 빛 (dancheong gold `#DFA951` + 작은 halo) — **다크 모드에서 발광**

**영문 프롬프트**:
```
A transparent PNG of a traditional Korean stone lantern (장명등)
for courtyard decoration.

4-tier construction:
1. Wide base block: stone gray #8B8478, shadow facet darker
2. Narrow stone column rising
3. Square lantern box with 4 small lattice windows, paper backing
   in hanji cream #FAF6EC, glowing warm ochre #DFA951 from within
4. Small curved tile roof cap (hanok slate #2A3340) with upturned
   tips

All facets angular, no smooth curves except the tile cap.
The lantern light glow is the ONE allowed soft gradient — small
halo around the lantern box in warm ochre fading to transparent.

Aspect ratio: roughly 6:13 vertical (300x650 pixels)
Transparent background.

For DARK MODE composition: the lantern glow should be MORE
pronounced — the warm ochre halo larger, the surrounding stone
appears in cool dark slate #1F2A2E.

[Same style discipline closing]
```

**DO**: 다크 모드에서 빛나는 효과 강조.
**DON'T**: 일본 토로 (灯籠) 형태 X — 한국 장명등 특유의 사각 lantern box.

---

### 3.6 풍경 (Wind Chime) — `decoration_punggyeong.png`

**조건**: 끝말잇기 10판 승리
**위치**: 본채 처마 끝에 매달림 (small overlay)
**치수**: 150×350 px

**컴포지션**:
- 위에서 매달리는 짧은 chain (cherry wood)
- bronze bell (dancheong gold `#DFA951` + 그림자 ochre)
- bell 아래 물고기 모양 펜던트 (작은 fish silhouette in walnut)
- 작은 빨간 매듭 tassel (dancheong red `#C24A45`)

**영문 프롬프트**:
```
A transparent PNG of a traditional Korean wind chime (풍경) for
hanging from a hanok eave.

Construction from top to bottom:
- Short brass chain link (3-4 segments) in cherry wood / brass
  tone
- Small bronze bell, dome-shaped: dancheong gold #DFA951 primary,
  ochre shadow facet
- Fish-shaped pendant hanging below bell (small carp silhouette
  in walnut brown #8E6646) — Korean fish character motif
- Red cord tassel at very bottom: dancheong red #C24A45 with
  thin strands

Aspect ratio: 1:2.3 vertical (150x350 pixels)
Transparent background.

This is a small accent — when composited over the hanok, it should
appear hanging from an eave corner. Render the top chain link with
slight indication of attachment point.

[Same style discipline closing]
```

**DO**: 작지만 디테일 살리기.
**DON'T**: 너무 크지 말 것 (마당 풍경에서 부차적 요소).

---

### 3.7 편액 (Calligraphy Plaque) — `decoration_pyeonaek.png`

**조건**: 한글 자모 100% 마스터
**위치**: 솟을대문 위 가운데 (Stage 11에서 비워둔 자리)
**치수**: 400×120 px

**컴포지션**:
- 두꺼운 walnut 프레임 (dark walnut + warm walnut facet)
- 안쪽 cream paper background (hanji cream `#FAF6EC`)
- 글자 자리는 비워둠 — 앱 코드에서 사용자 닉네임 한글로 overlay
- 양쪽 작은 dancheong 장식 (small lotus motif in red+gold)

**영문 프롬프트**:
```
A transparent PNG of a traditional Korean calligraphy plaque
(편액/현판) for mounting above a gate. NO TEXT — the center
paper area must be EMPTY (the app will overlay user's nickname
in code).

Construction:
- Horizontal rectangular wooden frame, primary face warm walnut
  #8E6646, deep walnut shadow facet #3E3024 on bottom + right
- Frame thickness ~15% of plaque height
- Inner panel: clean hanji cream #FAF6EC paper backing (this is
  where user nickname will be rendered later)
- Small dancheong lotus motif decoration in each corner of the
  frame (red #C24A45 + gold #DFA951)
- Subtle hanji texture on inner panel

Aspect ratio: 10:3 horizontal (400x120 pixels)
Transparent background.

CRITICAL: do NOT add any Korean or Chinese characters in the
center — that area must remain blank for app overlay.

[Same style discipline closing]
```

**DO**: 가운데를 정확히 비워둘 것. 프레임 질감 살리기.
**DON'T**: 글자 절대 그리지 말 것. Decorative motif 가운데 영역 침범 X.

---

### 3.8 돌담 (Stone Wall) — `decoration_doldam.png`

**조건**: 친구 코드 5명 등록
**위치**: 마당 둘레 (외벽 안쪽, 좀더 친근한 정원 담)
**치수**: 1200×200 px (마당 가로 거의 전체)

**컴포지션**:
- 가로로 긴 돌담 — 자연석 (irregular polygon facets) + 회반죽 (mortar) 사이사이
- 색: stone gray + warm ochre + 일부 작은 dancheong tealish 돌
- 위에 작은 풀 또는 꽃 한두 송이
- 양 끝은 자연스럽게 fade (캔버스 끝 잘림처럼)

**영문 프롬프트**:
```
A transparent PNG of a traditional Korean stone wall (돌담) — a
low garden wall made of irregularly-shaped natural stones with
mortar between them.

Construction:
- Horizontal wall ~200px tall, ~1200px wide
- Made of irregular polygon-shaped stones, NOT bricks — each stone
  a different size and angular shape
- Color variation across stones:
  - Stone gray #8B8478 (most common)
  - Warm ochre #A87E5E (warm accent)
  - Cool dark slate #1F2A2E (occasional dark stone)
  - Pale sage #9BB0A0 (mossy stone, rare)
- Mortar lines: thinner cream facets between stones
- Top edge slightly uneven (natural construction)
- Optional: 1-2 small grass tufts on top of wall, 1 small flower

Aspect ratio: 6:1 horizontal (1200x200 pixels)
Transparent background.

[Same style discipline closing]
```

**DO**: 돌들이 다 다른 모양·색 — 의도적 다양성.
**DON'T**: 정형화된 벽돌처럼 X. 너무 균일하지 말 것.

---

### 3.9~3.12 사군자 4폭 (Plum/Orchid/Chrysanthemum/Bamboo) — `decoration_sagunja_{maehwa|nan|guk|juk}.png`

**조건**: 4종 각각의 단어 묶음 마스터 (sub-quests)
**위치**: 사랑채 벽에 4 패널로 매달림
**치수**: 각각 250×600 px (세로 4폭 시리즈)

**컴포지션 공통**:
- 한지 cream `#FAF6EC` 배경 + walnut frame
- 가운데 사군자 묘사 (해당 식물)
- 우측 하단 작은 한문 도장 (작은 red square + 흰 글자)

**3.9 매화폭 (Plum)** — `decoration_sagunja_maehwa.png`
- 각진 dark walnut 가지 + 5-petal 매화 클러스터

**3.10 난폭 (Orchid)** — `decoration_sagunja_nan.png`
- 가는 mountain teal 잎 (4~5장), 작은 plum pink 꽃 한 송이

**3.11 국폭 (Chrysanthemum)** — `decoration_sagunja_guk.png`
- 둥근 형태의 dancheong gold 국화 + 깊은 ochre 그림자 facet, sage 잎

**3.12 죽폭 (Bamboo)** — `decoration_sagunja_juk.png`
- 수직 mountain teal 대나무 줄기 (segment lines), 각진 잎 클러스터

**영문 프롬프트 템플릿** (각 폭 공통):
```
A transparent PNG of a traditional Korean sagunja (사군자) folding-
screen-style panel featuring [PLUM / ORCHID / CHRYSANTHEMUM / BAMBOO]
for mounting on a hanok wall.

Construction:
- Vertical rectangular panel with walnut frame (warm walnut #8E6646
  + deep walnut shadow #3E3024)
- Inner paper background hanji cream #FAF6EC with subtle paper grain
- Centered subject:
  [PLUM: angular dark walnut branch with clustered 5-petal plum
   pink #E8B5BC blossoms and tiny gold #DFA951 centers]
  [ORCHID: 4-5 long thin curved leaves in mountain teal #3D9A7F
   with 1-2 small plum pink #E8B5BC orchid blooms]
  [CHRYSANTHEMUM: layered round chrysanthemum bloom in dancheong
   gold #DFA951 with ochre shadow facets, sage green leaves]
  [BAMBOO: 3 vertical bamboo stalks in mountain teal #3D9A7F with
   visible segment lines, angular leaf clusters in mountain sage
   #5C7060]
- Small red dancheong stamp (인장) in lower-right corner: small
  red square #C24A45 with a single cream character inside (王 or
  similar simple stylization)

Aspect ratio: 5:12 vertical (250x600 pixels)
Transparent background.

[Same style discipline closing]
```

**DO**: 4폭이 같은 frame 크기 & 색조 — 컬렉션 통일성.
**DON'T**: 4폭 서로 다른 스타일 X (시리즈 일관성 핵심).

---

### 3.13 까치 둥지 (Magpie Nest) — `decoration_kkachi_nest.png`

**조건**: 30일 streak
**위치**: 마당 나무 (소나무·매화 등) 가지에
**치수**: 350×280 px

**컴포지션**:
- 작은 가지 위에 둥근 둥지 (cherry wood + warm walnut 잔가지들)
- 가운데에 까치 가족: 부모 까치 1마리 + 새끼 까치 2~3마리 (작은 black+white 둥글둥글한 chick)
- 부모 까치는 갓 (가족의 어른 표시)
- 둥지 가장자리에 작은 깃털 1~2개

**영문 프롬프트**:
```
A transparent PNG of a magpie family nest in a tree branch, for
composition over a hanok courtyard scene.

Construction:
- Tree branch base (warm walnut #8E6646) extending from upper edge
- Round woven nest made of small twigs (cherry wood #7E5A3D and
  walnut shadow facets) — looks rough but cozy
- 1 adult magpie sitting in/beside nest: black + white body
  (stripe black #1A1410 + cream), gold-amber beak, small flat-oval-
  brim gat hat with gold band — the elder
- 2-3 magpie chicks visible in nest: rounder, fluffier silhouettes,
  smaller scale, NO gat hats (just chicks), beaks open
- 1-2 small feathers near nest edge

Aspect ratio: 5:4 (350x280 pixels)
Transparent background.

[Same style discipline closing]
```

**DO**: 가족애 표현 (어른+새끼).
**DON'T**: 너무 cute하게 (디자인 가이드의 "NOT cute" 원칙 — chick조차 dignified).

---

### 3.14~3.17 계절 이벤트 4종 (Seasonal Quests)

#### 3.14 설날 색동 깃발 (Lunar New Year Flag) — `decoration_seollal_flag.png`

**조건**: 설날 시즌 윷놀이 미니퀴즈 5판
**위치**: 솟을대문 양쪽에 색동 깃발
**치수**: 800×300 px (가로 한쌍)

**컴포지션**:
- 좌우 한쌍의 깃발 (각각 200px wide)
- 깃발은 한국 전통 saekdong (색동) 색띠 패턴 — 빨강/노랑/초록/파랑/흰 가로 줄무늬
- 각진 facet으로 줄무늬 표현
- 깃대는 cherry wood

**영문 프롬프트**:
```
A transparent PNG of a pair of traditional Korean Saekdong
(색동) striped banners for hanging at a gate during Lunar New
Year (설날).

Composition: a matched pair of vertical banners side by side
(can be rendered as one image for placement on both sides of
a gate).

Each banner:
- Vertical rectangular cloth panel
- Horizontal alternating color stripes (Saekdong pattern):
  - Dancheong red #C24A45
  - Dancheong gold #DFA951
  - Mountain teal #3D9A7F
  - Cobalt indigo #2C3E94
  - Hanji cream #FAF6EC
- 5-7 horizontal stripes, each ~15% of banner height
- Cherry wood #7E5A3D pole on inner side
- Tassel at bottom: a few cream + red tassel strands
- Slight asymmetry between left and right banner (one slightly
  taller or different stripe order) — NOT identical mirror

Aspect ratio: 8:3 horizontal pair (800x300 pixels)
Transparent background.

[Same style discipline closing]
```

#### 3.15 추석 보름달 (Chuseok Full Moon) — `decoration_chuseok_moon.png`

**조건**: 추석 시즌 송편 단어 12개 마스터
**위치**: 마당 상공 영구 추가 (sky overlay)
**치수**: 500×500 px

**컴포지션**:
- 둥근 보름달 (hanji ivory `#F4E8D0` 핵심 + 약간 cream halo 그라데이션)
- 달 표면에 미세한 토끼 그림자 (Korean folk motif — 떡 절구 토끼)
- 달 주변 cloud scrolls 2~3개

**영문 프롬프트**:
```
A transparent PNG of a Korean Chuseok harvest full moon for
composition into a hanok night sky.

Composition:
- Large round full moon, primary surface hanji ivory #F4E8D0
- A faint warm cream halo around the moon (one allowed gradient,
  ochre fading to transparent)
- Subtle silhouette inside the moon: a Korean folk rabbit pounding
  rice cake (small rabbit + mortar shape), in slightly darker
  ochre at low opacity
- 2-3 cloud scroll motifs (구름문양) in pale cream nearby, NOT
  obscuring the moon

Aspect ratio: 1:1 square (500x500 pixels)
Transparent background.

CRITICAL: this overlay is meant for night/dark composition. The
moon brightness should be moderate (NOT pure white) so it works
without overwhelming the courtyard scene.

[Same style discipline closing]
```

#### 3.16 한글날 세종 편액 (Hangeul Day Sejong Plaque) — `decoration_hangeulday_plaque.png`

**조건**: 한글날 (10/9) 시즌 훈민정음 28자 미니퀘스트
**위치**: 솟을대문 옆 작은 현판
**치수**: 300×200 px

**컴포지션**:
- 작은 walnut frame + cream paper
- 가운데 "한글" 글자 (Pretendard Bold, dark ink) — 글자는 그대로 그려도 됨 (사용자 닉네임 아닌 commemorative)
- 위에 작은 ㄱ ㄴ ㄷ ㄹ 자모 시퀀스
- 아래 작은 일월오봉도 모티프 (해+달+산)

**영문 프롬프트**:
```
A transparent PNG of a commemorative Korean calligraphy plaque
celebrating Hangeul Day (한글날, October 9).

Construction:
- Small horizontal walnut frame (warm walnut + dark walnut facet)
- Inner cream paper background (hanji cream #FAF6EC)
- Centered Korean text "한글" rendered in clean modern Pretendard
  Bold style in stripe black #1A1410 (NOT brushstroke calligraphy)
- Small row of Korean jamo "ㄱ ㄴ ㄷ ㄹ" above the main text in
  smaller size
- A tiny irworobongdo motif (sun + moon + mountain peaks) at the
  bottom edge of the inner panel — simplified, decorative

Aspect ratio: 3:2 horizontal (300x200 pixels)
Transparent background.

The text "한글" is celebratory and intentional (this is a
commemorative plaque, unlike the user nickname plaque which is
blank).

[Same style discipline closing]
```

#### 3.17 연 (Kite) — `decoration_kite.png`

**조건**: 어린이날 시즌
**위치**: 마당 상공 (sky overlay)
**치수**: 400×400 px (연 + 줄 길이 포함)

**컴포지션**:
- 한국 방패연 (rectangular kite with a center hole) — 흰 바탕 + 빨강/파랑 색동 모서리 + 가운데 검은 원
- 가는 줄 (cherry wood) 위에서 늘어짐
- 약간 비스듬 angle (바람에 흔들리는 느낌)
- 양쪽에 작은 꼬리 (cream tassels)

**영문 프롬프트**:
```
A transparent PNG of a traditional Korean shield kite (방패연)
for sky composition over a hanok courtyard.

Kite specifications:
- Square/rectangular kite body with the iconic CENTER HOLE (this
  is the Korean shield kite — must have the hole)
- White hanji cream #FAF6EC base
- Color blocks at 4 corners: alternating dancheong red #C24A45,
  cobalt indigo #2C3E94, mountain teal #3D9A7F, dancheong gold
  #DFA951
- A black circle around the center hole (stripe black #1A1410)
- A thin cherry wood / tan string extending from the kite upward
  to the canvas edge (suggesting someone holding it from below)
- 2 small cream tassel strips at top corners
- Kite shown at slight tilt as if caught in wind (about 15-20
  degrees from horizontal)

Aspect ratio: 1:1 (400x400 pixels)
Transparent background.

[Same style discipline closing]
```

---

## 4. 카테고리 3 — 단청 도장 (8 PNG)

> 사용자가 팩 클리어 시 도장첩에 찍히는 단청 무늬 도장.
> 8개 base 디자인 — 토픽군별로 다른 무늬 사용 (음식·시간·가족 등).
> 코드에서 색상 변주로 더 다양하게 활용 가능.

### 4.0 공통 사양

- **포맷**: PNG-24, 알파 O (배경 투명)
- **치수**: 256×256
- **경로**: `assets/illustrations/stamps/stamp_{N}.png`
- **참고 이미지**: #4, #7, #8, #12 (단청 패턴 모음)



**구도**: 원형 도장. 빨간 base + 안에 cream + gold 연꽃 도형.

**영문 프롬프트**:
```
A transparent PNG of a circular Korean dancheong-style stamp
featuring a lotus motif. Faceted minhwa style.

Construction:
- Circular stamp outline: dancheong red #C24A45 outer ring
  (thick ~15% of diameter)
- Inner circle background: hanji cream #FAF6EC
- Centered lotus motif: 8 angular petals radiating outward,
  each petal a flat dancheong gold #DFA951 facet with mountain
  teal #3D9A7F shadow facet at base
- Tiny center dot in dancheong red

Aspect ratio: 1:1 (256x256 pixels)
Transparent background outside the stamp circle.

Style: NO outlines on petals (color planes only), subtle paper
grain texture, restricted palette.

[Same style discipline closing]
```

### 4.2~4.8 나머지 도장 7종

각각 다른 단청 모티프 사용. 동일 템플릿, motif만 교체:

| ID | Motif | 토픽 군 매핑 |
|---|---|---|
| `stamp_lotus.png` | 연꽃 | 인사·자기소개·가족 |
| `stamp_chrysanthemum.png` | 국화 | 시간·숫자 |
| `stamp_plum.png` | 매화 | 감정·형용사 |
| `stamp_bamboo.png` | 대나무 격자 | 학교·직장 |
| `stamp_cloud.png` | 구름 (cloud scroll) | 날씨·자연 |
| `stamp_geometric_octagon.png` | 팔각형 기하학 | 음식·쇼핑 |
| `stamp_mountain.png` | 산봉우리 (일월오봉도 mini) | 교통·여행 |
| `stamp_swastika.png` | 만(卍)자 격자 (불교·민속 무늬) | 신체·건강 |

**각 도장 프롬프트** (위 lotus 템플릿 기반):
```
[Same as Stamp 1 template] but replace lotus motif with [MOTIF]:
- [MOTIF DESCRIPTION matching attached reference #4, #7, #8, #12]
- Color scheme: base dancheong red, motif in alternating gold/teal/
  cream facets
```

**중요**: 8개 도장이 시각적으로 **family resemblance** 보여야 함 — 동일 외곽 크기, 동일 ring 두께, 동일 cream paper inner, motif만 차이.

---

## 5. 카테고리 4 — 스티커 (30 PNG)

> 계 모임방에서 채팅 대신 사용. 6 category × 5 sticker = 30개.
> 각각 256×256, transparent, 단순·읽기 쉬워야 함 (작은 사이즈에서도).

### 5.0 공통 사양

- **포맷**: PNG-24, 알파 O
- **치수**: 256×256
- **경로**: `assets/stickers/{category}_{name}.png`
- **스타일**: Faceted minhwa, but slightly more rounded/cute than other assets (스티커는 친밀한 표현용)
  - **예외 허용**: 스티커는 chibi에 가깝게 그려도 OK — 일러스트 메인 자산과 다른 톤. 단 디자인 가이드의 색상 팔레트는 그대로.

### 5.0A 앱 마스코트 재제작용 보강 프롬프트 — Jongga Guardian Style

> 아래 블록은 256px 채팅 스티커가 아니라 앱 내부
> `assets/illustrations/mascot/` 교체용이다. 목표는 귀여운 스티커가 아니라
> `jongga-assets.md`의 한옥/장식 자산과 같은 결의 **웅장한 수호 마스코트**다.
> 호랑이는 두 번째 첨부 이미지처럼 상반신·가슴·앞발이 크게 보이는
> **upper-body guardian portrait**가 기준이다. 까치는 현재 퀄리티가 좋은
> `magpie_wingup.png` / `magpie_wingdown.png`를 기준으로 나머지 포즈를 맞춘다.

#### 5.0A.1 왜 이전 출력이 귀엽게 나왔는가

다음 단어·지시는 모델을 자동으로 cute / sticker / baby 쪽으로 끌고 간다.
마스코트 재생성 프롬프트에서는 쓰지 않는다.

- **금지 단어**: cute, playful, adorable, puppy eye, apologetic,
  vulnerable, shrinking, small, shy, pout, baby, cub, kawaii, chibi,
  sticker border, toy-like, emoji-like.
- **금지 포즈**: waving paw, raised paw near face/chest, paw-to-chin,
  forepaw toes spread for emotion, paws close together to look smaller,
  head tilt for vulnerability, sweat drop, tear drop, confetti-heavy joy.
- **금지 기준 이미지**: `tiger_sleepy.png`를 전체 호랑이 set의 기준으로 쓰지 않는다.
  sleepy는 특수 휴식 포즈라서 전체 set을 눕고 부드러운 방향으로 끌 수 있다.

#### 5.0A.2 출력 사양

- **Master size**: 1254×1254 또는 1536×1536 square PNG.
- **Final app path**: `assets/illustrations/mascot/{filename}.png`
- **Alpha**: true PNG-32 / RGBA transparent background. No baked checkerboard,
  no white square, no beige paper rectangle, no drop-shadow rectangle.
- **Framing**: subject centered, 5-8% transparent padding. The mascot must read
  at 48-64px but still feel premium at 512px.
- **Texture**: subtle hanji grain on the character color planes only, not a
  full background layer.
- **Style references**:
  - Overall app style: current jongga gate, hanok stage, and decoration assets.
  - Tiger target: majestic upper-body guardian portrait, not the cute paw-up
    tiger. After `tiger_idle.png` is approved, it becomes the character design
    source of truth for the active tiger set.
  - Tiger motion references: use tiger expression / movement sheets only for
    anatomical energy cues such as forward lean, crouch, stretch, relaxed rest,
    alert turn, and proud call. Do not copy any reference sheet composition,
    watermark, line style, or exact pose.
  - Real-tiger behavior reference: translate emotions through body height,
    center of gravity, ears, gaze, mouth shape, forepaw rhythm, and tail curve
    when visible. Avoid pasting human facial acting onto a tiger.
  - Active motion reference: for `happy`, `celebrate`, `thinking`, `sad`,
    `sleepy`, and sticker/action variants, prefer a 3/4 diagonal motion sprite
    over a straight frontal portrait when the emotion needs body movement.
  - Magpie target: current `magpie_wingup.png` and `magpie_wingdown.png`.
- **Tiger variant rule**: `tiger_idle.png` is not a pixel prison; it is the
  character-design source of truth. Preserve the Design DNA across every
  variant, while allowing controlled tiger body language for emotional poses.
  `blink`, `neutral`, and `smile` stay near-idle and mostly pixel-stable.
  `happy`, `celebrate`, `sad`, `thinking`, and `sleepy` may change head angle,
  chest energy, ear angle, forepaw weight distribution, body rotation, visible
  torso/hip flow, and tail curve as long as the result is unmistakably the same
  tiger character.

#### 5.0A.3 이번 교체 대상

| 상태 | 파일 | 기준 |
|---|---|---|
| 먼저 재생성 / 새 기준 | `tiger_idle.png` | upper-body guardian portrait anchor |
| near-idle 편집 | `tiger_blink.png` | idle 복제 후 눈만 감김 |
| near-idle 편집 | `tiger_neutral.png` | idle 복제 후 눈/입/눈썹만 더 무표정하게 |
| near-idle 편집 | `tiger_smile.png` | idle 복제 후 눈/입만 미세 조정 |
| expressive motion | `tiger_happy.png` | 3/4 forward walk + soft chuff + visible loose tail |
| expressive motion | `tiger_celebrate.png` | 3/4 proud lift/call + confident S-curve tail, 만세 포즈 금지 |
| expressive motion | `tiger_sad.png` | low grounded pause + lowered body line, puppy-eye/tear 금지 |
| expressive motion | `tiger_thinking.png` | investigative pause + asymmetrical ears + balancing tail |
| expressive rest variant | `tiger_sleepy.png` | 같은 캐릭터 DNA 유지 + 졸린 휴식 body language |
| 기준 유지 | `magpie_wingup.png` | 까치 스타일/해상도 기준 |
| 기준 유지 | `magpie_wingdown.png` | 까치 날갯짓 기준 |
| 재생성 | `magpie_perched.png` | 날개 접고 앉은 기본 포즈 |
| 재생성 | `magpie_perched_alt.png` | 방향만 살짝 다른 앉은 포즈 |
| 재생성 | `magpie_celebrate.png` | 좋은 소식/완료 축하 포즈 |
| 재생성 | `magpie_worry.png` | 침착한 걱정 포즈, round chick 금지 |

#### 5.0A.3.1 호랑이 variant 제작 방식 — Design DNA 고정 + Body Language 허용

`tiger_idle.png`는 픽셀 고정 복제품을 만들기 위한 원본이 아니라
**캐릭터 디자인의 source of truth**다. 목표는 모든 감정 이미지가
"같은 호랑이"로 보이면서도, 실제 호랑이의 body language처럼 자연스럽게
움직이고 반응하는 것이다.

**Design DNA — 모든 variant에서 고정**

- 같은 adult Korean guardian tiger identity.
- 같은 얼굴 구조, muzzle construction, cheek shape, broad head silhouette.
- 같은 낮고 둥근 tiger ears. Cat-like pointed ears 금지.
- 같은 `王` 느낌의 이마 줄무늬 구조와 stripe language.
- 같은 burnt orange / rust-orange / cream / ink-black palette.
- 같은 faceted minhwa planes, subtle hanji grain, no outline finish.
- 같은 dignified guardian personality. Cute/chibi/sticker mascot 금지.
- 같은 square transparent PNG family와 app-size readability.

**Expressive Body Language — 감정에 따라 허용**

- body axis and line of action.
- camera angle and motion direction.
- body height and center of gravity.
- shoulder asymmetry and chest energy.
- forepaw weight transfer, rhythm, and one-forepaw pause/step.
- visible torso/hip/tail flow when motion needs it.
- head height, head turn, chin angle, and nose direction.
- ear angle, including subtle left/right asymmetry.
- eye focus and eyelid tension.
- whisker direction and sensory focus.
- mouth shape as soft chuff / proud call / scent-analysis tiny parting /
  relaxed closed mouth, not human grin.
- tail curve only when it supports the motion and remains readable.
- 몸의 에너지 방향: relaxed walk, investigative pause, scent-analysis pause,
  proud call,
  low grounded pause, resting sphinx, playful paw tap, sudden alert freeze,
  affectionate cheek rub.

**제작 타입**

- **Near-idle variants**: `tiger_blink.png`, `tiger_neutral.png`,
  `tiger_smile.png`.
  - `tiger_idle.png`를 복제하거나 image edit / inpainting으로 만든다.
  - 몸, 귀, 앞발, 줄무늬, 王 mark, whiskers, palette, framing은 거의
    동일하게 둔다.
  - `blink`는 눈만 감겨야 한다.
  - `neutral`은 idle과 거의 같아도 된다. 앱 크기에서 차이가 흐려지면
    exact copy 사용이 더 낫다.

- **Expressive variants**: `tiger_happy.png`, `tiger_celebrate.png`,
  `tiger_sad.png`, `tiger_thinking.png`, `tiger_sleepy.png`.
  - `tiger_idle.png`를 character reference로 넣고 image-to-image /
    reference-guided generation / 넓은 마스크 편집으로 만든다.
  - 픽셀 위치까지 같을 필요는 없다.
  - 정면 upper-body portrait에 묶이지 않는다. 감정이 살아야 할 때는
    torso, hip, hind leg 일부, tail까지 보이는 3/4 motion sprite를 허용한다.
  - 단, character redesign처럼 보이면 실패다. 얼굴 구조, ear type,
    stripe language, 王 mark, palette, faceted style은 반드시 유지한다.
  - 감정은 human gesture가 아니라 tiger anatomy와 body language로 표현한다.

**금지**

- 완전히 다른 tiger 얼굴로 재생성.
- cat-like ears, kitten/cub proportions, plush toy body.
- human-like waving, hooray arms, paw-to-chin thinking pose.
- tears, sweat drops, floating symbols, question marks, speech bubbles.
- tiny static full-body sticker silhouette로 작아지는 것. Active motion은
  허용하지만 얼굴과 동작이 48-64px에서 읽혀야 한다.

#### 5.0A.3.2 Real Tiger Emotion Translation

감정 variant는 "웃는 얼굴"이나 "사람 같은 제스처"가 아니라 실제 호랑이의
몸짓을 앱 마스코트 언어로 번역한다. 참고 이미지는 정확한 포즈 복사용이
아니라, 호랑이가 감정을 몸으로 표현하는 방향성을 잡기 위한 anatomy /
motion reference다.

| 감정 | 실제 호랑이식 표현 | 프롬프트 cue |
|---|---|---|
| 행복 / 만족 | 안전함, 편안함, 친근한 greeting. 몸이 굳지 않고 귀는 중립 또는 살짝 앞으로, 입은 부드러운 chuff 느낌. | relaxed forward walking step, soft eyes, neutral-forward ears, gentle chuffing mouth |
| 생각 / 관찰 | 사람처럼 찡그리는 것이 아니라 냄새를 분석하고, 소리를 듣고, 주변을 평가하는 investigative / scent-analysis pause. 한 발이 멈추고, 귀가 비대칭으로 소리를 탐색. | one forepaw suspended or lightly touching down, asymmetrical ears, focused side glance, nose slightly lifted, whiskers slightly forward, optional very subtle flehmen hint |
| 축하 / 성공 | 인간식 만세가 아니라 가슴을 열고 고개를 들거나 짧은 proud call / energetic step. | proud chest lift, head raised, open tiger-like call, one forepaw stepping forward |
| 슬픔 / 실망 | 눈물이 아니라 낮아진 에너지, 고개 낮춤, 시선 회피, 귀가 옆/뒤로 풀림. | low heavy posture, head lowered, gaze down/away, ears relaxed outward/back, slow grounded pause |
| 자는 중 | 몸을 낮게 내려놓고 앞발을 앞으로 둠. 눈꺼풀 무겁고 호흡이 평온함. | resting sphinx, forepaws forward, heavy eyelids, relaxed shoulders, calm breathing |
| cheer / 응원 | 친근한 chuff와 앞으로 다가오는 동작. | encouraging chuff, forward lean, warm eye contact, one forepaw reaching forward |
| clap / 박수 | 실제 박수 대신 앞발을 땅에 툭 디디는 playful paw tap. | playful double paw tap on ground, weight shift, pleased face |
| 놀람 | 순간적으로 몸이 stiff해지고 고개가 번쩍 들림. 귀는 앞으로/옆으로 반응. | sudden alert freeze, widened eyes, head jerk upward, ears pricked, forepaw paused mid-step |
| 사랑 / 애정 | 하트보다 greeting, cheek rub, slow blink, soft chuff. | affectionate cheek rub, soft chuff, slow blink, head nuzzle, relaxed body |

#### 5.0A.3.3 Active Motion Sprite Framing

`tiger_happy.png`처럼 감정이 몸의 움직임으로 읽히는 파일은 정면
upper-body portrait로 만들지 않는다. `tiger_idle.png`의 캐릭터 DNA를
유지하되, square canvas 안에서 3/4 방향성과 꼬리 곡선을 적극적으로 쓴다.

| 타입 | 파일 | 프레이밍 |
|---|---|---|
| Near-idle portrait | `idle`, `blink`, `neutral`, `smile` | 상반신 / front-half 중심. 얼굴, 가슴, 두 앞발 안정감 우선 |
| Active motion sprite | `happy`, `celebrate`, `thinking`, `sad` | 3/4 diagonal view. 얼굴, 가슴, 앞발, 몸통 일부, tail curve가 읽히게 구성 |
| Rest motion sprite | `sleepy` | resting sphinx / side-rest crop. 앞몸 낮음, 앞발 앞으로, tail 또는 몸통 곡선 일부 허용 |
| Sticker action | `cheer`, `clap`, `surprised`, `love` | 더 작은 캔버스에서도 동작 실루엣이 먼저 읽히게 구성 |

**Active motion composition rules**

- Avoid straight-on symmetrical portrait for expressive variants.
- Use a 25-45 degree 3/4 camera angle: body travels diagonally across the
  square, while the head can still turn toward the viewer.
- Create a clear line of action from tail/hip through spine/chest to head or
  leading forepaw.
- Show enough torso and hip to explain the motion. Do not crop so tightly that
  the tiger looks like only a face and chest.
- Tail is visible by default for `happy`, `celebrate`, `thinking`, `surprised`,
  `cheer`, and `love` unless it hurts 48-64px readability.
- Keep the face large enough to read at app size: face/head should remain about
  24-34% of canvas height in active motion sprites.
- Keep the whole silhouette inside the square with 4-8% transparent padding.
  Do not crop off the tail tip, leading paw, ears, or whisker area.
- Exactly two forepaws are visible and anatomically clear. Full-body motion may
  show hind legs, but never add a third forepaw or make paws look like hands.

**Tail language**

- Happy / cheer / love: loose lifted C-curve or soft S-curve, relaxed and
  friendly.
- Celebrate: higher confident S-curve, energized but not aggressive.
- Thinking / surprised: paused lifted curve, as if the body froze mid-step.
- Sad: low trailing curve or relaxed downward tail, not tucked in fear.
- Sleepy: tail relaxed along the body or softly curled around the resting form.
- Avoid fast whipping tail, bristled tail, or sharp aggressive lash unless an
  explicit anger asset is requested.

**Thinking-specific sensory rules**

`tiger_thinking.png`은 인간식 "thinking face"가 아니라 감각으로 환경을
판독하는 조사 프레임이다. 아래 신호를 조합한다.

- Head is turned slightly to one side, not straight at the viewer.
- Nose is lifted slightly upward as if catching scent on the air.
- Eyes focus sideways and slightly upward, not directly forward.
- One ear points forward while the other angles outward a little, suggesting
  selective listening.
- Whiskers angle slightly forward, as if sensing the space ahead.
- Mouth is mostly closed. A tiny mouth parting or slight upper-lip tension is
  allowed only as a subtle scent-analysis cue.
- Optional subtle flehmen hint only: very slight upper-lip lift or minimal
  mouth parting. Avoid a full flehmen grimace, goofy grin, stink-face,
  cartoon confusion, or cheerful smile.
- Tail, if visible, stays in a restrained calm curve that supports a paused
  attentive state. It should not read as playful excitement or aggression.
- Avoid direct front-facing pose, symmetrical ears, both forepaws planted
  equally in a neutral walk, sad/worried body language, question marks,
  paw-to-chin, or any human "thinking" gesture.

**프롬프트 구조**

Expressive variant를 만들 때는 아래 네 블록을 반드시 포함한다.

```text
MOTION ANCHOR:
[real tiger behavior: relaxed walk / investigative pause / scent-analysis pause /
proud call / low grounded pause / resting sphinx / playful paw tap /
sudden alert freeze / affectionate cheek rub]

BODY AXIS:
Describe the line of action, spine angle, chest height, shoulder asymmetry,
and weight transfer.

FOREPAW LOGIC:
Describe which forepaw is forward, which paw carries weight, and whether
one paw is paused, lightly touching down, or tapping the ground.

FACE / EARS / TAIL:
Describe eyes, eyelid tension, nose direction, mouth as chuff/call/closed mouth
or tiny scent-analysis parting, whiskers, ear angle, and tail curve only if
visible and useful.

CAMERA / FRAMING:
Describe portrait / front-half / 3/4 diagonal motion / resting crop. State
whether the tail must be visible and how much torso/hip should appear.
```

**공통 body-language 블록**

```text
Translate the emotion through real tiger body language, not human acting.
Do not create a human facial expression pasted onto a tiger.

Use these animal-behavior channels:
- body axis and line of action
- camera angle and motion direction
- shoulder asymmetry
- forepaw weight transfer
- head height and head turn
- nose direction and sensory focus
- ear angle
- eye focus and eyelid tension
- whisker direction
- mouth shape as chuff / call / relaxed closed mouth / tiny scent-analysis
  parting
- tail curve only if it supports the motion

The pose must look like one captured animation frame of a living tiger.
Avoid a static seated mascot portrait for expressive variants.
For active motion variants, prefer a 3/4 diagonal view with visible torso,
hip, and tail curve. Do not make every tiger face straight forward.
Avoid human gestures, waving, clapping hands, raised arms, paw-to-chin,
tears, symbols, hearts, speech bubbles, or emoji acting.
```

**프레이밍 규칙**

- Near-idle 앱 마스코트는 upper-body / front-half 중심으로 유지한다.
- Active expressive 앱 마스코트는 정면 상반신에 갇히지 않는다.
  감정이 걸음/정지/꼬리로 읽힐 때는 3/4 front-half 또는 near-full-body
  motion sprite를 우선한다.
- `happy`, `celebrate`, `thinking`은 tail curve와 torso/hip flow가 감정을
  살리므로 active motion sprite에서는 tail을 기본적으로 보이게 한다.
- `sleepy`는 low resting pose가 더 잘 읽히므로 front-half rest,
  side-rest crop, 또는 compact full-body rest를 허용한다.
- rolling, full-body leap, extreme lying full-body처럼 square mascot
  가독성이 떨어지는 큰 동작만 `tiger_special_*.png` 별도 자산으로 만든다.
- 어떤 경우에도 48-64px에서 표정과 실루엣이 읽혀야 한다.

#### 5.0A.4 공통 스타일 문장

```
Create this as a premium Korean learning app mascot sprite in the same
Jongga Faceted Minhwa style as the attached hanok gate, hanok stage, and
quest-decoration assets.

This is NOT a chat sticker and NOT a cute animal icon. It is a dignified
guardian mascot: monumental, calm, editorial, geometric, and rooted in
Joseon minhwa visual language.

Use large clean geometric facets, crisp silhouette, subtle hanji grain,
and a restrained traditional palette. No soft toy feeling, no emoji face,
no chibi proportions, no Western cartoon acting.

Emotion should be expressed through authentic tiger anatomy and body language:
eye shape, brow angle, chin height, ear angle, chest energy, shoulder tension,
forepaw weight distribution, and subtle body rotation. Do not use human
gestures, props, symbols, or mascot-costume acting.

Use true transparent PNG alpha. The exported PNG must contain no baked
checkerboard pixels, no white/cream background box, no beige paper rectangle,
no shadow rectangle, no text, no speech bubble, and no sticker outline.
```

#### 5.0A.5 호랑이 Character Bible — upper-body guardian portrait

```
TIGER IDENTITY:
The tiger is an adult Korean guardian tiger from a modern Jongga minhwa
illustration set. It should feel like a calm mountain guardian sitting at
the entrance of a noble hanok: powerful, composed, and intelligent.

Primary framing:
- `tiger_idle.png`, `tiger_blink.png`, `tiger_neutral.png`, and
  `tiger_smile.png` use upper-body guardian portrait framing.
- Active expressive variants may use front-half or near-full-body motion
  sprite framing when body movement and tail curve are needed.
- Near-idle portrait: head, broad chest, cream belly V, shoulders, and exactly
  two forepaws visible near the lower edge of the canvas.
- Active motion sprite: head, chest, leading forepaw, supporting forepaw,
  torso/hip flow, and tail curve should explain the motion inside the square.
- Avoid tiny full-body sticker silhouette. The head and face must still read
  clearly at 48-64px.
- Near-idle face occupies about 38-45% of character height; active motion face
  occupies about 24-34% of canvas height.
- Near-idle head is forward with a subtle 3/4 turn, about 8-12 degrees to the
  right. Active motion uses a stronger 25-45 degree 3/4 camera angle.
- Chest and shoulders are large and architectural, like a gate guardian, even
  when the body is moving.

Anatomy and silhouette:
- Adult tiger proportions. No cub, no baby-cat head, no plush toy body.
- Broad triangular head, large cheek tufts, thick neck, heavy shoulders,
  grounded chest, and big calm forepaws.
- Ears are slightly lower rounded tiger ears, not cat-like pointed ears.
  They should feel powerful and integrated into the broad head silhouette,
  not tall, sharp, kitten-like, or fox-like.
- Exactly two forepaws visible, left and right, near the lower edge of the
  composition. Near-idle variants keep both planted. Expressive variants may
  shift weight, move one forepaw slightly forward/back, or make one forepaw
  feel lighter, but never add a third paw.
- Expressive variants may show hind legs and tail when the motion needs them,
  but the two forepaws must remain clear and anatomically distinct.
- Do not use waving paws, paws near the face/chest, paw-to-chin gestures, or
  human hand-like posing. Forepaws are tiger anatomy, not hands.
- Forepaws should stay weight-bearing and dignified. Do not use paw pads or
  spread toes as the main emotion cue.

Color and facet construction:
- Coat: burnt orange #E87830 with rust-orange #C25420 and warm ochre
  #A87E5E shadow facets.
- Stripes: deep ink-black #1A1410, drawn as bold angular filled shapes.
- Cream areas: muzzle, cheeks, chin, chest V, belly, and inner ears in
  #F4E8D0.
- Eyes: amber-gold #DFA951, almond-shaped, focused and intelligent.
- Forehead mark: stripe arrangement suggesting 王 through discrete angular
  black stripe shapes, not a typographic Chinese character.
- 45-80 large readable facets. Avoid hundreds of tiny shards and avoid
  smooth airbrushed fur.

Style:
- No outlines around the body or color planes. The dark stripes are filled
  shapes, not outlines.
- Soft upper-left light, deeper lower-right facets, same quiet premium finish
  as the jongga gate/stage/decoration assets.
- Expression is subtle and majestic. No puppy eyes, no tears, no sweat drops,
  no exaggerated smile, no raised arms.
```

#### 5.0A.6 호랑이 포즈별 지시

| 파일 | 추가 지시 |
|---|---|
| `tiger_idle.png` | Anchor image. Calm upper-body guardian portrait. Eyes open and focused, mouth closed, chin level, shoulders broad, slightly lower rounded tiger ears, exactly two forepaws planted. This should resemble the second attached majestic tiger image, not the paw-up cute tiger. |
| `tiger_blink.png` | Duplicate the approved `tiger_idle.png` and edit only the eyes into a relaxed blink. Body, head, stripes, mouth, ears, chest, whiskers, canvas, and forepaws stay identical. |
| `tiger_neutral.png` | Duplicate the approved `tiger_idle.png`. Keep it almost identical; only make the eyes/mouth/brow 1-3% more formal and still. If the difference is not visible at app size, using an exact idle copy is acceptable. |
| `tiger_smile.png` | Near-idle variant. Duplicate `tiger_idle.png` and edit mouth corners plus tiny eye warmth. Very restrained guardian smile. No crescent cartoon eyes, no grin, no paw movement. |
| `tiger_happy.png` | Expressive active motion sprite. Default direction: relaxed 3/4 forward walking step + soft chuff + warm eyes. Show torso/hip and a loose lifted tail curve. One forepaw reaches forward into the foreground, opposite forepaw stays back and weight-bearing, chest leans forward, ears neutral-forward. This should feel like friendly encouragement, not a straight-on human smile pose. |
| `tiger_celebrate.png` | Expressive active motion sprite. Confident success through proud chest lift, controlled tiger-like call, or energetic forward step. Use 3/4 diagonal view, visible torso, higher confident S-curve tail, head raised, chest expanded, ears alert, shoulders energized, one forepaw stepping forward with confident weight transfer. No human "hooray" arms, no paw near face/chest, no mascot costume acting. |
| `tiger_sad.png` | Expressive motion sprite. Low energy and withdrawal through low grounded pause. Use low 3/4 front-half or side-front crop, visible lowered body line, tail low/trailing if visible. Head lowered, chin tucked, gaze down or away, ears relaxed outward/back but not pinned aggressively, shoulders sink, forepaws heavy near the ground. No puppy eyes, tears, sweat, shrinking baby pose, or paws close together to look small. |
| `tiger_thinking.png` | Expressive active motion sprite. Investigating, scenting, evaluating, and listening through slow investigative pause. Use 3/4 diagonal view with enough torso/hip to show the paused step and restrained balancing tail. One forepaw paused just above the ground or lightly touching down, nose slightly lifted, head turned to one side, one ear forward and the other angled outward, eyes focused sideways/upward, whiskers slightly forward. Optional very subtle flehmen hint only; no goofy grin, no question mark prop, no human thinking gesture. |
| `tiger_sleepy.png` | Expressive rest motion sprite. Rest and safety through resting sphinx or side-rest crop. Front body lowered, forepaws stretched forward, head heavy but dignified, tail relaxed along the body or softly curled, eyelids mostly closed, ears relaxed, shoulders soft, breathing calm. No cartoon sleep symbols, no collapsed body, no sick/sad expression. |

#### 5.0A.7 호랑이 프롬프트 템플릿

##### `tiger_idle.png` 생성 템플릿

```
A true-transparent PNG app mascot sprite of an adult Korean guardian tiger,
calm idle expression, in upper-body guardian portrait framing.

Use the attached majestic upper-body tiger reference as the character target:
broad chest, large angular head, cream belly V, two planted forepaws, calm
powerful gaze, and premium Jongga Faceted Minhwa finish.

[Paste TIGER IDENTITY / Primary framing / Anatomy / Color / Style blocks]
[Paste pose-specific sentence]
[Paste common style sentence]

Aspect ratio: 1:1 square, 1254x1254 or 1536x1536 px.
Export as true RGBA transparent PNG.
```

##### near-idle variant 편집 템플릿

```
Use the attached tiger_idle.png as the exact base image.
This is a near-idle image-editing / inpainting task, not a new character
generation.

Do not redraw the character. Preserve the exact canvas size, transparent alpha,
silhouette, ears, head angle, body position, forepaw position, stripe placement,
王-like forehead stripe arrangement, whiskers, nose, cream belly V, colors,
scale, and framing.

Only edit the masked expression area: [eyes / eyelids / brow / mouth].
Target expression: [VARIANT EXPRESSION].

Everything outside the masked expression area must remain identical to
tiger_idle.png. Do not change the body, ears, paws, stripes, chest, lighting,
texture, or character proportions.

Export as true RGBA transparent PNG with no baked checkerboard, no white box,
no paper background, no sticker outline, no text.
```

Use this template for `tiger_blink.png`, `tiger_neutral.png`, and
`tiger_smile.png`.

##### expressive variant 생성 / 편집 템플릿

```
A true-transparent PNG app mascot sprite of the SAME adult Korean guardian
tiger character as tiger_idle.png, in Jongga Faceted Minhwa style.

IMPORTANT SOURCE-OF-TRUTH RULE:
Use tiger_idle.png as the character-design anchor, not as a pixel-locked copy.
This must unmistakably be the same tiger character as tiger_idle.png.
Preserve the Design DNA:
- same adult guardian tiger identity
- same broad head and muzzle construction
- same slightly lower rounded tiger ears, not cat-like pointed ears
- same 王-like forehead stripe arrangement
- same stripe language and placement logic
- same burnt orange / rust-orange / cream / ink-black palette
- same faceted geometric minhwa rendering and subtle hanji grain
- same dignified, premium, not-cute personality
- same mascot family and transparent square PNG format
- near-idle variants stay upper-body; active expressive variants may show
  torso, hip, hind legs, and tail when motion readability needs them

EXPRESSIVE BODY LANGUAGE:
Allow subtle expressive changes in head angle, chin height, ear position,
chest energy, shoulder tension, forepaw weight distribution, and slight body
rotation, but do not redesign the character or change it into a different
tiger. Emotion must come from authentic tiger anatomy and body language,
not human gestures. The pose must look like one captured animation frame of
a living tiger, not a static seated mascot portrait. Use a 25-45 degree 3/4
camera angle for active motion unless the variant explicitly says near-idle.

POSE / EMOTION:
[PASTE VARIANT DELTA HERE]

MOTION ANCHOR:
[relaxed walk / investigative pause / scent-analysis pause / proud call /
low grounded pause / resting sphinx / playful paw tap / sudden alert freeze /
affectionate cheek rub]

BODY AXIS:
[Describe the line of action, spine angle, chest height, shoulder asymmetry,
and weight transfer.]

FOREPAW LOGIC:
[Describe which forepaw is forward, which paw carries weight, and whether
one paw is paused, lightly touching down, or tapping the ground.]

FACE / EARS / TAIL:
[Describe eye focus, eyelid tension, nose direction, mouth as
chuff/call/closed mouth/tiny scent-analysis parting, whiskers, ear angle, and
tail curve only if visible and useful.]

CAMERA / FRAMING:
[Describe portrait / front-half / 3/4 diagonal motion / resting crop. State
whether the tail must be visible and how much torso/hip should appear.]

CONSTRAINTS:
- Exactly two forepaws visible. No third paw.
- Forepaws may shift weight or one may step slightly forward/back near the
  lower edge, but no waving paw, no paw near face/chest, no paw-to-chin pose.
- Hind legs may be visible in active motion sprites, but they must never be
  confused with extra forepaws.
- If the tail is part of the emotion, show the full tail curve inside the
  square. Do not crop off the tail tip.
- No chibi, no cub, no plush toy, no mascot costume acting.
- No tears, sweat drops, hearts, question marks, speech bubbles, text,
  symbols, or confetti-heavy effects.
- Keep square canvas, transparent alpha, clear 48-64px readability, and
  5-8% padding.

Export as true RGBA transparent PNG with no baked checkerboard, no white box,
no paper background, and no sticker outline.
```

Use this template for `tiger_happy.png`, `tiger_celebrate.png`,
`tiger_sad.png`, `tiger_thinking.png`, and `tiger_sleepy.png`.

##### expressive variant delta prompts

```
tiger_happy.png:
Real tiger emotion translation: content, safe, friendly greeting.
Motion anchor: relaxed forward walking step, soft chuff.
Camera / framing: 3/4 diagonal active motion sprite, not straight-on. Show the
head, chest, leading forepaw, supporting forepaw, enough torso/hip to show the
walking direction, and the full loose lifted tail curve inside the square.
Body axis: diagonal line of action from the lifted tail through the back and
chest to the leading forepaw. The body travels across the canvas while the head
turns warmly toward the viewer.
Forepaw logic: one large foreground forepaw reaches forward into the viewer's
space; the opposite forepaw remains back and weight-bearing. Hind legs may be
visible behind, but never read as extra forepaws.
Face / ears / tail: ears neutral-forward, eyes warm and engaged, mouth slightly
open as a soft chuff, not a grin. Tail is a relaxed C-curve or soft S-curve,
showing friendly energy. This should feel like "good job, continue" through
animal body language.

tiger_celebrate.png:
Real tiger emotion translation: confident success, energized presence.
Motion anchor: proud chest lift or controlled tiger call.
Camera / framing: 3/4 diagonal active motion sprite with visible torso and a
higher confident S-curve tail. Avoid straight frontal pose.
Body axis: upward line of action from grounded forepaws through expanded chest
to raised head; shoulders energized, body rotated slightly.
Forepaw logic: one forepaw steps forward with confident weight transfer, the
other braces. Keep both forepaws low and tiger-like.
Face / ears / tail: head raised, ears alert, mouth open in a short powerful
tiger-like call or chuff-roar, not a cartoon scream. Tail is lifted in an
energized S-curve but not aggressive. This is stronger than happy but still
dignified. No human cheering pose, no raised-arms gesture, no waving paw.

tiger_sad.png:
Real tiger emotion translation: low energy, disappointment, withdrawal.
Motion anchor: low grounded pause.
Camera / framing: low 3/4 front-half or side-front crop. Show enough shoulders,
forepaws, and body line to read lowered energy. Tail may be visible as a low
trailing curve.
Body axis: descending line of action; chest less open, shoulders softened and
slightly sunk, center of gravity low.
Forepaw logic: both forepaws heavy and close to the ground; one may sit
slightly ahead but should not look cute or tucked.
Face / ears / tail: head lowered, chin slightly tucked, gaze down or away; ears
relaxed outward/back but not pinned aggressively; mouth closed with subtle
downturned tension. Tail low and relaxed if visible. Dignified and composed,
not helpless or babyish. No tears.

tiger_thinking.png:
Real tiger emotion translation: investigating, scenting, evaluating, and
listening. This is NOT a human-style "thinking face." The tiger should feel
like it has paused mid-step to analyze something in the environment.
Motion anchor: slow investigative pause / scent-analysis pause.
Camera / framing: 3/4 diagonal active motion sprite. Show torso/hip enough to
explain a paused step, with tail visible as a restrained balancing curve if it
fits. Avoid direct front-facing pose.
Body axis: forward but suspended; torso held in a quiet diagonal line of action,
as if the tiger interrupted its walk to examine something. Chest slightly
forward, shoulders controlled and still, with subtle asymmetry.
Forepaw logic: one forepaw paused just above the ground or only lightly touching
down; most body weight stays on the other grounded forepaw and rear support.
This is a real walking pause, not a human thinking pose.
Face / ears / tail: head turned slightly to one side; nose lifted slightly
upward as if catching scent on the air; eyes focused sideways and slightly
upward, not directly forward; one ear points forward while the other angles
outward, suggesting selective listening; whiskers angle slightly forward; mouth
mostly closed or only very slightly parted. Optional scent-analysis detail:
include only a very subtle flehmen hint, such as tiny upper-lip tension or
minimal mouth parting. Do NOT make it look goofy, smiling, like a stink-face,
or cartoon confused. Tail, if visible, stays in a restrained calm curve that
supports a paused attentive state. Emotional read: thoughtful, observant, and
quietly intelligent; more "I am assessing this carefully" than happy,
surprised, sad, or worried.
Avoid: symmetrical ears, both forepaws planted equally in a neutral walk,
cheerful expression, obvious smile, exaggerated flehmen grimace, confused
cartoon face, sad/worried body language, paw-to-chin, props, question marks.

tiger_sleepy.png:
Real tiger emotion translation: rest, safety, low arousal.
Motion anchor: resting sphinx or side-rest crop.
Camera / framing: resting sphinx front-half, side-rest crop, or compact rest
sprite. Show the lowered front body, stretched forepaws, and tail relaxed along
the body or softly curled when visible.
Body axis: horizontal and calm; chest lowered, shoulders soft, neck relaxed.
Forepaw logic: forepaws stretched forward or folded naturally under the chest,
not human-like.
Face / ears / tail: head heavy but dignified; eyelids mostly closed; ears
relaxed; breathing calm; mouth closed or tiny relaxed yawn only if still
elegant. Tail relaxed along the body or softly curled. No cartoon sleep symbols,
no collapsed body, no sick/sad expression.
```

#### 5.0A.8 까치 Character Bible

```
MAGPIE IDENTITY:
Use the attached magpie_wingup and magpie_wingdown images as the exact
quality, anatomy, color, gat, and faceted-feather reference. The result
must look like the same Korean magpie character in a new pose.

Design constants:
- Ink-black / blue-black head and back #101820, with cool slate facets
  #26323A and deep teal tail facets #0E4D58.
- Cream-white belly and wing panels #F4E8D0 with pale gray shadow facets
  #B8B6AE.
- Long elegant tail, visible black beak, small amber-gold eye #DFA951.
- Korean gat must be accurate: black cylindrical crown, wide flat brim,
  thin chin strap tied under the beak / neck. No top hat, no western hat.
- Legs and feet are small burnt-orange facets #C25420.
- Feathers are angular layered planes, not fuzzy realistic feather noise.
- Same body size, head size, gat size, and tail length across all magpie
  poses.

Composition constants:
- One magpie only, centered in a square canvas.
- Transparent background only.
- No round chick body, no cute penguin proportions, no oversized eyes.
- No speech bubble, no sticker border, no extra props unless requested.
- Keep the body center anchored consistently across magpie_perched,
  magpie_perched_alt, magpie_wingup, magpie_wingdown, magpie_celebrate,
  and magpie_worry.
```

#### 5.0A.9 까치 포즈별 지시

| 파일 | 추가 지시 |
|---|---|
| `magpie_wingup.png` | Existing reference. Flying frame 1: both wings raised high in a wide V. |
| `magpie_wingdown.png` | Existing reference. Flying frame 2: both wings lowered and spread outward. |
| `magpie_perched.png` | Calm Joseon messenger pose. Wings folded, feet visible, gat accurate, long tail elegant. Optional tiny branch only if it does not make the asset feel like a sticker. |
| `magpie_perched_alt.png` | Same character, slightly different direction or head angle. Keep body scale and gat size identical. |
| `magpie_celebrate.png` | Elegant good-news pose. Wings open but not cute; beak slightly open. Use at most 2-3 tiny dancheong facets, no heavy confetti. |
| `magpie_worry.png` | Alert concern. Head angle and wing tuck express worry; no tears, no sweat, no round baby-bird face. |

#### 5.0A.10 까치 기본 프롬프트 템플릿

```
A true-transparent PNG app mascot sprite of a Korean magpie wearing a gat,
[POSE / EMOTION].

Use the attached magpie_wingup and magpie_wingdown images as the exact
quality, anatomy, color, gat, and faceted-feather reference. The result must
look like the same dignified Korean magpie character in a new pose.

[Paste MAGPIE IDENTITY / Design constants / Composition constants]
[Paste pose-specific sentence]
[Paste common style sentence]

Aspect ratio: 1:1 square, 1254x1254 or 1536x1536 px.
Export as true RGBA transparent PNG.
```

#### 5.0A.11 생성 순서 추천

1. `tiger_idle.png`를 먼저 만든다. 두 번째 첨부 이미지처럼 웅장한
   upper-body guardian portrait가 나올 때까지 여기서 타협하지 않는다.
2. 확정된 `tiger_idle.png`를 character-design source of truth로 저장한다.
   이후 variant는 이 이미지의 Design DNA를 기준으로 만든다.
3. `blink`, `neutral`, `smile`은 near-idle variant다. `tiger_idle.png`를
   복제한 뒤 image edit / inpainting / 수동 편집으로 눈·눈썹·입만 바꾼다.
4. `blink`는 idle에서 눈만 바뀌어야 한다.
5. `neutral`은 idle과 거의 같아도 된다. 앱 크기에서 차이가 흐려지면
   exact copy 사용이 더 낫다.
6. `happy`, `celebrate`, `sad`, `thinking`, `sleepy`는 expressive variant다.
   `tiger_idle.png`를 reference로 넣되 픽셀 복제에 묶지 말고, 같은 캐릭터
   DNA 안에서 고개·가슴·귀·앞발 무게중심·몸 회전·tail curve를 허용한다.
7. expressive variant를 만들 때는 먼저 Real Tiger Emotion Translation에서
   `MOTION ANCHOR`를 하나 고른다. 한 이미지에 여러 동작을 섞지 않는다.
8. expressive variant도 full redesign은 금지다. 얼굴 구조, 낮고 둥근 귀,
   王 mark, stripe language, palette, faceted style은 유지한다.
9. `happy`/`celebrate`는 human paw-up이 아니라 3/4 diagonal motion,
   leading forepaw, torso flow, visible tail curve로 만든다.
10. `sad`/`thinking`은 puppy-eye, tear, paw-to-chin 없이 낮아진 body energy,
   investigative pause, 시선·고개·귀 각도로 만든다.
11. active motion sprite는 꼬리 끝, leading paw, 귀, 수염이 잘리지 않도록
    square canvas 안에 4-8% padding을 둔다.
12. 구르기, 전신 점프, 과도한 전신 눕기처럼 square mascot 가독성이 떨어지는
    동작만 `tiger_special_*.png`로 분리한다.
13. `magpie_perched.png`를 먼저 만든 뒤 나머지 까치 pose를 variation으로 만든다.
14. 앱에 넣기 전 solid mint / black / cream 배경 위에서 체크무늬 찌꺼기와
   사각 박스가 없는지 확인한다.

### 5.1 호랑이 스티커 5종 (`tiger_*.png`)

#### 5.1.1 `tiger_cheer.png` — 응원
- 친근한 encouragement chuff. 앞으로 다가오는 듯한 forward lean,
  warm eye contact, neutral-forward ears, 한 앞발이 시청자 쪽으로 나아감.
  사람처럼 두 앞발을 들거나 만세하지 않는다.

#### 5.1.2 `tiger_clap.png` — 박수
- 실제 박수 대신 playful double paw tap on ground. 두 앞발은 낮고 땅에
  가까우며, 한 앞발은 방금 "툭" 디딘 듯하고 다른 앞발은 무게를 받침.
  앞발을 사람 손처럼 마주치지 않는다.

#### 5.1.3 `tiger_surprised.png` — 놀람
- sudden alert freeze. 고개가 살짝 위로 번쩍 들리고, 눈이 넓어지며,
  귀가 앞으로 서거나 한쪽 귀가 옆으로 반응. 한 앞발이 mid-step에서
  멈춘 느낌. 별/이모지 효과 없이 몸의 stiff pause로 표현.

#### 5.1.4 `tiger_sad.png` — 슬픔
- low grounded pause. 고개 낮춤, 시선 아래/옆으로 회피, 귀는 옆/뒤로
  편안히 풀림, 어깨가 내려앉고 앞발은 무겁게 지면에 닿음. 눈물 금지.

#### 5.1.5 `tiger_love.png` — 사랑
- affectionate greeting. cheek rub 또는 slow-blink chuff 느낌. 고개가
  부드럽게 기울고, 눈은 half-closed / slow blink, 귀는 relaxed, 몸은
  따뜻하게 앞으로 기대는 듯함. 하트 prop은 명시적으로 sticker-only가
  필요할 때만 아주 작게 허용한다.

**공통 프롬프트 템플릿**:
```
A transparent PNG of the same Korean guardian tiger character showing
[EMOTION/ACTION] for use in a chat-style sticker interface.

Style: faceted minhwa but slightly more rounded/playful than
editorial illustrations — still NOT pure chibi, retain dignified
character and real tiger body language.

Tiger specifications:
- Burnt orange #E87830 coat, rust orange #C25420 shadow facets
- Tiger cream #F4E8D0 belly/chin/inner ears
- Stripe black #1A1410 angular stripes
- 王 character on forehead in stripe black
- Sharp amber-gold eyes ([EXPRESSION DETAIL])
- Square 1:1 framing; use 3/4 action pose when the sticker emotion needs
  movement. Frontal pose only for near-idle sticker expressions.

Translate the sticker emotion through tiger behavior:
- body axis and line of action
- shoulder asymmetry
- forepaw weight transfer
- head height and head turn
- ear angle
- eye focus and eyelid tension
- mouth as chuff / call / relaxed closed mouth
- tail curve if it supports the motion and remains readable at 256px

[ACTION SPECIFIC: e.g., "encouraging chuff with forward lean,
warm eye contact, one forepaw stepping forward, loose lifted tail curve"]

Avoid human gestures, waving, clapping hands, raised arms, paw-to-chin,
tears, symbols, hearts, speech bubbles, or emoji acting unless the sticker
explicitly requires a tiny decorative accent.

Aspect ratio: 1:1 (256x256 pixels)
Transparent background.

[Same style discipline closing]
```

### 5.2 까치 스티커 5종 (`magpie_*.png`)

| ID | 표정·행동 |
|---|---|
| `magpie_dance.png` | 작은 dance pose, 한 날개 들어올림 |
| `magpie_wave.png` | 인사 (날개 흔들기) |
| `magpie_sleep.png` | 자는 모습 (눈 감음, "Z" 표시) |
| `magpie_sing.png` | 노래 (음표 facet 2개) |
| `magpie_encourage.png` | 격려 (날개 두 개 위로) |

각각 동일 템플릿. 까치는 항상 갓 hat 착용.

### 5.3 단청 모티프 5종 (`dancheong_*.png`)

| ID | 모티프 |
|---|---|
| `dancheong_flower.png` | 단청 꽃 (red + gold) |
| `dancheong_star.png` | 단청 별 (gold + teal) |
| `dancheong_cloud.png` | 구름 (cream + teal) |
| `dancheong_lantern.png` | 한지 등롱 (warm glow)ㅈ |
| `dancheong_hanji.png` | 한지 무늬 (cream + 작은 dot pattern) |

장식 모티프 — 그저 예쁜 단청 요소를 send 가능. 캐릭터 X.

### 5.4 한글 자모 5종 (`hangul_*.png`)

| ID | 표현 |
|---|---|
| `hangul_kk.png` | "ㅋㅋ" 큰 글자 + 미소 mouth facet |
| `hangul_hh.png` | "ㅎㅎ" 큰 글자 + 행복 표정 |
| `hangul_fighting.png` | "화이팅!" 큰 글자 + 주먹 |
| `hangul_jjang.png` | "짱!" 큰 글자 + 엄지 |
| `hangul_good.png` | "굿" 큰 글자 + 박수 |

글자는 Pretendard Bold, dancheong red 또는 dark ink. 작은 facet 장식 옆에.

### 5.5 음식 5종 (`food_*.png`)

| ID | 음식 |
|---|---|
| `food_tteok.png` | 떡 (alternating cream + persimmon facets) |
| `food_tea.png` | 청자 찻잔 + 김 |
| `food_kimbap.png` | 김밥 한 조각 (검은 김 + 다양 facet 안쪽) |
| `food_hotteok.png` | 호떡 (둥근 갈색 + 가운데 흑설탕) |
| `food_sikhye.png` | 식혜 (cream 음료 + 위에 잣 facet) |

각각 단순 음식 일러스트, 256×256 안에 잘 보이게.

### 5.6 도장 5종 (`stamp_sticker_*.png`)

| ID | 글자 |
|---|---|
| `stamp_sticker_well_done.png` | "참 잘했어요" 도장 |
| `stamp_sticker_fighting.png` | "화이팅" 도장 |
| `stamp_sticker_love.png` | "사랑" 도장 (작은 하트) |
| `stamp_sticker_cheer.png` | "응원" 도장 |
| `stamp_sticker_happy.png` | "행복" 도장 |

선생님 도장처럼 — 빨간 둥근 도장 + cream 글자.

---

## 6. 카테고리 5 — 계 공동 한옥 추가 요소 (8 PNG)

> 계원 전체 진행도 합산으로 잠금 해제되는 공동 마당 추가 요소.
> 개인 마당보다 큰 종갓집 컨셉.
> 모두 transparent PNG, 합성용.

### 6.1 `gye_haenglangchae.png` — 행랑채 (Servant Quarters)
- 본채 옆 작은 부속 건물 (slate tile roof, 단순한 facade)
- 치수: 700×500 px

### 6.2 `gye_byeoldang.png` — 별당 (Detached Wing)
- 마당 안쪽 작은 별채 (한 칸 짜리, lattice doors)
- 치수: 500×450 px

### 6.3 `gye_jeongja.png` — 정자 (Pavilion)
- 8각 정자 (slate tile roof on 8 thin pillars, 한 칸 마루)
- 치수: 600×500 px

### 6.4 `gye_pond_large.png` — 큰 연못 확장
- 개인 연못 확장 — 더 큰 oval + 잉어 3마리 + 연꽃 3송이
- 치수: 800×500 px

### 6.5 `gye_garden.png` — 정원 (소나무 + 매화 + 국화 combined)
- 계 전체가 가꾼 멋진 정원
- 치수: 900×700 px

### 6.6 `gye_bridge.png` — 작은 돌다리
- 연못 위 작은 아치 다리
- 치수: 400×300 px

### 6.7 `gye_jangmyeongdeung_pair.png` — 장명등 한 쌍
- 솟을대문 양쪽 큰 석등 한 쌍
- 치수: 600×800 px

### 6.8 `gye_gate_grand.png` — 큰 솟을대문 (jongga grade)
- 개인 솟을대문보다 한 단계 큰 grand entrance
- 치수: 900×700 px

**각 항목 프롬프트**: 위 카테고리 2 hanok 단계의 프롬프트 템플릿 + 해당 element 디테일 영문 묘사. 모두 transparent PNG.

---

## 7. 카테고리 6 — 책 한 컷 UI 일러스트 (5 PNG)

> Phase 5 "책 한 컷" 기능의 빈/에러/성공 상태 일러스트.
> 16:9 또는 정사각 권장, transparent.

### 7.1 `book_empty_shelf.png` — 빈 책장
**상황**: "내 책장"이 비어있을 때
**구도**: 빈 한옥식 책장 (warm walnut shelf) + 까치가 빈 칸을 쳐다봄 + cream 한지 배경
**치수**: 1024×768

**영문 프롬프트**:
```
A horizontal editorial illustration of an empty traditional Korean
wooden bookshelf (책장), as an empty-state illustration for a
language learning app's "My Bookshelf" feature.

LAYER 1 — Background
- Hanji cream #FAF6EC background with subtle paper grain

LAYER 2 — Bookshelf
- Centered: traditional Korean shelf in warm walnut #8E6646,
  3 horizontal shelves
- Shelves clearly empty — NO books visible
- Walnut shadow facets for 3D volume

LAYER 3 — Magpie (right side)
- A small gat-wearing magpie perched on top of the shelf, looking
  down at the empty shelves with curious expression
- Subtle question-mark facet floating above magpie (optional, very
  small)

ATMOSPHERIC DETAILS:
- A few floating hanji paper fragments suggesting "waiting for books"
- Soft warm tone overall — inviting, not melancholic

Aspect ratio: 4:3 (1024x768 pixels)
Transparent background.

[Same style discipline closing]
```

### 7.2 `book_camera_guide.png` — 카메라 사용 안내
**상황**: 처음 책 한 컷 사용 시 튜토리얼
**구도**: 한국어 책 한 페이지 + 위에 카메라 뷰파인더 frame + 까치가 안내하는 포즈
**치수**: 1024×768

**영문 프롬프트**:
```
A horizontal editorial illustration showing how to photograph a Korean
textbook page, as a first-use tutorial illustration for a language
learning app's "snap a page" feature.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper
era) crossed with Korean minhwa folk painting. NOT cute, NOT cartoonish
— confident, premium editorial quality.

LAYER 1 — Background
- Hanji cream #FAF6EC background with subtle paper grain

LAYER 2 — Open textbook page (center, slightly tilted)
- An open book / single page in cream #F4E8D0 with warm walnut #8E6646
  spine, a few faceted lines of placeholder Korean text (simple gray
  #8B8478 bars, NOT real letters) and one highlighted line in dancheong
  teal #3D9A7F
- A camera viewfinder frame overlaid on the page: 4 corner brackets in
  dancheong gold #DFA951, suggesting "align the page here"

LAYER 3 — Magpie guide (right)
- A small gat-wearing magpie (black + white body, gold-amber beak, tall
  cylindrical gat hat with gold band) pointing a wing toward the
  viewfinder frame in a friendly guiding pose

ATMOSPHERIC DETAILS:
- Two loose dancheong dot groupings (red #C24A45, gold #DFA951, teal
  #3D9A7F)
- Soft, inviting tone

Aspect ratio: 4:3 (1024x768 pixels). Transparent background.
NO outlines on subjects — pure color planes only. Subtle hanji paper
grain. Restricted palette: #FAF6EC #F4E8D0 #8E6646 #5C4028 #8B8478
#3D9A7F #DFA951 #C24A45 #1A1410.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

### 7.3 `book_analyzing.png` — 분석 중
**상황**: Cloud Function 호출 중 (3~5초)
**구도**: 호랑이가 책을 읽고 있음 + 위에 떠 있는 작은 facet (단어 추출 진행 표현) + 까치가 옆에서 wing up
**치수**: 1024×768

**영문 프롬프트**:
```
A horizontal editorial illustration of a Korean tiger reading a book,
as a "analyzing…" loading illustration for a language learning app.

Mid-century modernist geometric reduction crossed with Korean minhwa.
NOT cute — confident, dignified, premium editorial quality.

LAYER 1 — Background
- Hanji cream #FAF6EC with subtle paper grain

LAYER 2 — Tiger reading (center-left)
- A seated Korean tiger looking down at an open book, calm and focused:
  - Burnt orange #E87830 coat with rust orange #C25420 shadow facets
  - Tiger cream #F4E8D0 belly and chin
  - Stripe black #1A1410 angular stripes, 王 mark on forehead
  - Sharp almond amber-gold eyes
- Open book in cream #F4E8D0 + warm walnut #8E6646 cover held/below

LAYER 3 — Extraction motion (above the book)
- Small word-card facets and dancheong dots rising upward from the page
  (gold #DFA951, teal #3D9A7F, red #C24A45), suggesting words being
  pulled out and processed
- A small gat-wearing magpie beside the tiger with one wing raised
  (wing-up), as if cheering the process on

ATMOSPHERIC DETAILS:
- Sense of gentle motion / progress, NOT chaos
- Two loose dancheong dot groupings

Aspect ratio: 4:3 (1024x768 pixels). Transparent background.
NO outlines — pure color planes. Subtle hanji grain. Restricted palette:
#FAF6EC #F4E8D0 #E87830 #C25420 #1A1410 #8E6646 #3D9A7F #DFA951 #C24A45.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

### 7.4 `book_success.png` — 분석 완료 축하
**상황**: N개 단어 추출 완료
**구도**: 까치 celebrate + 호랑이 smile + 흩어지는 작은 단어 카드 facet + 가운데 cream paper에 "N단어!" placeholder
**치수**: 1024×768

**영문 프롬프트**:
```
A horizontal editorial illustration celebrating a finished analysis,
as a success-state illustration for a language learning app — new words
have been found.

Mid-century modernist geometric reduction crossed with Korean minhwa.
NOT cute — joyful but premium, magazine-cover quality.

LAYER 1 — Background
- Hanji cream #FAF6EC with subtle paper grain

LAYER 2 — Mascots (celebrating)
- A gat-wearing magpie mid-celebration, wings spread upward
  (black + white body, gold-amber beak, gat hat with gold band)
- A Korean tiger with a warm smiling expression beside it:
  - Burnt orange #E87830 coat, rust #C25420 shadow facets, cream
    #F4E8D0 belly, stripe black #1A1410 stripes, 王 mark

LAYER 3 — Scattering word cards (foreground)
- Several small faceted "word cards" (cream #F4E8D0 rectangles with a
  tiny gold #DFA951 or teal #3D9A7F edge) bursting outward and upward
- Center: a clean cream #FAF6EC paper panel with a thin walnut #8E6646
  frame — LEAVE THE CENTER EMPTY (app overlays "N new words" text)

ATMOSPHERIC DETAILS:
- A few celebratory dancheong dots and small star facets (gold #DFA951)
- Energetic but balanced — leave breathing room

Aspect ratio: 4:3 (1024x768 pixels). Transparent background.
CRITICAL: keep the center paper panel BLANK for app text overlay.
NO outlines — pure color planes. Subtle hanji grain. Restricted palette:
#FAF6EC #F4E8D0 #E87830 #C25420 #1A1410 #8E6646 #3D9A7F #DFA951 #C24A45.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

### 7.5 `book_error.png` — 분석 실패
**상황**: OCR 실패 or 분석 실패
**구도**: 호랑이 worry + 까치 worry + 흐릿한 책 페이지 + cream paper에 placeholder "다시 시도"
**치수**: 1024×768

**영문 프롬프트**:
```
A horizontal editorial illustration of a gentle error state for a
language learning app — the page could not be read.

Mid-century modernist geometric reduction crossed with Korean minhwa.
NOT cute, NOT sad-melodramatic — softly apologetic, premium quality.

LAYER 1 — Background
- Hanji cream #FAF6EC with subtle paper grain

LAYER 2 — Blurred page (center)
- A book page rendered with soft, slightly offset/duplicated facets to
  suggest "blurry / unreadable": cream #F4E8D0 with faint gray #8B8478
  smudged text bars, low contrast
- A small dancheong-red #C24A45 soft warning dot (NOT a harsh icon)

LAYER 3 — Mascots (concerned)
- A Korean tiger with a worried but kind expression (brows slightly up):
  burnt orange #E87830, rust #C25420 facets, cream #F4E8D0 belly,
  stripe black #1A1410, 王 mark
- A small gat-wearing magpie tilting its head with mild worry beside it
- Center-bottom: a clean cream #FAF6EC paper panel with thin walnut
  #8E6646 frame — LEAVE EMPTY (app overlays "try again" text)

ATMOSPHERIC DETAILS:
- Calm, reassuring tone — make it feel recoverable, not a failure
- One loose dancheong dot grouping only

Aspect ratio: 4:3 (1024x768 pixels). Transparent background.
CRITICAL: keep the center paper panel BLANK for app text overlay.
NO outlines — pure color planes. Subtle hanji grain. Restricted palette:
#FAF6EC #F4E8D0 #E87830 #C25420 #1A1410 #8E6646 #8B8478 #C24A45 #DFA951.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

> ✅ 5장 모두 바로 복붙 가능한 완전한 영문 프롬프트 보유 (7.1~7.5). 표준 템플릿(§1) + 각 상황 layer 묘사 반영.

---

## 8. 카테고리 7 — 출시 자료 (3 PNG)

### 8.1 `feature_graphic_v2.png` — Play Store Feature Graphic
**치수**: 1024×500
**경로**: `docs/store/feature_graphic_v2.png`

**구도**:
- 왼쪽 1/3: 호랑이 + 까치 마스코트 (응원 자세)
- 가운데 1/3: "함께 짓는 한옥" 한글 + DE/EN 짧은 카피
- 오른쪽 1/3: 한옥 마당 (Stage 6 정도 — 단청 + 기와)
- 단청 색상 strip 상하

**영문 프롬프트**:
```
A horizontal feature graphic for the Google Play Store listing of
"Hangul Sori" — a Korean language learning app for German speakers.

Three-zone composition:

LEFT ZONE (33%)
- Korean tiger and gat-wearing magpie mascot pair, dignified
  guardian energy, both facing right toward the text
- Tiger seated, magpie perched on tiger's shoulder
- Warm cream background

CENTER ZONE (34%)
- Large Korean text "한글소리" (Pretendard Bold) in stripe black
- Below: smaller German text "Koreanisch lernen — gemeinsam ein
  Hanok bauen" (Korean - learn together, build a Hanok)
- Behind text: subtle dancheong gold/red dot pattern in 2 loose
  groupings

RIGHT ZONE (33%)
- Hanok scene with tile roof, dancheong eaves, gate, low wall
- Same style as in-app illustrations (faceted minhwa)
- Distant blue-sage mountains behind

TOP + BOTTOM
- Thin dancheong color band: teal base with alternating red/gold/
  cream squares (~30px tall)

Aspect ratio: 1024x500 px landscape
Solid background, no transparency.

Mood: dignified, inviting, premium, contemporary editorial quality.

[Same style discipline closing]
```

### 8.2 `screenshot_frame.png` — 스크린샷 프레임 (필요 시)
**치수**: 사이즈 미정, Play Console 권장 사이즈 따름
**용도**: 인앱 스크린샷에 단청 frame 씌우기 (optional 마케팅 도구)

### 8.3 `splash_v2.png` — 스플래시 (필요 시 업데이트)
**치수**: 현재 스플래시 유지하면 생략. 업데이트할 경우 1080×1920 (또는 native splash spec).

---

## 9. 참고 이미지 활용 가이드 (사용자 첨부 12장)

각 카테고리별로 어떤 reference 이미지를 첨부하면 좋은지 매핑:

| 카테고리 | 권장 첨부 | 이유 |
|---|---|---|
| 한옥 12단계 | #1 + #5 | 실사 분위기 + 야경 |
| 솟을대문 (Stage 8) | #2 + #11 | 일러스트 디테일 + close-up |
| 단청 (Stage 7) | #7 + #8 + #12 | 단청 패턴 정확도 |
| 매화 퀘스트 | #5 | 매화 + 한옥 분위기 |
| 사군자 4폭 | #4 | 사군자 + 보자기 패턴 |
| 까치 (모든 마스코트) | #6 + #9 | 갓 디테일 |
| 단청 도장 8종 | #4 + #7 + #8 + #12 | 단청 패턴 풍부 |
| 스티커 음식 | #10 | 한국 전통 소품 |
| 스티커 도장 | #4 | 도장 + 보자기 |
| Feature graphic | #1 + #3 | 인상적인 한옥 + 분위기 |

**첨부 방법** (AI 생성기별):
- **Midjourney**: 이미지 URL 또는 업로드 → `--cref` (캐릭터 reference) 또는 일반 image prompt
- **DALL-E 3**: 이미지 첨부 후 "match the style of this attached image" 명시
- **Imagen 3 / Nano Banana**: 첨부 + closing line의 IMPORTANT 마지막 line 추가

---

## 10. 빠른 프롬프트 체크리스트 (Jin 사용)

각 생성 전:

- [ ] **첨부했나?** HANGUL_SORI_STYLE_GUIDE.md 요약 + 기존 자산 1-2장 + 참고 이미지 (위 9 표)
- [ ] **프롬프트에 포함했나?**
  - [ ] Mid-century modernist + Korean minhwa 명시
  - [ ] LAYER 1/2/3 front-to-back 구조
  - [ ] 정확한 hex 색상 7-10개 나열
  - [ ] "NO outlines, NO smooth gradients, subtle hanji paper grain"
  - [ ] Aspect ratio + pixel dimensions 명시
  - [ ] ABSOLUTELY AVOID 섹션
  - [ ] 마지막 IMPORTANT closing line
- [ ] **3-5장 generate** 후 best 선택
- [ ] **첫 시도 실패 시 진단 순서**:
  1. 색 temperature (sepia? icy?) → 색상 hex 다시 강조
  2. Composition (closed? busy?) → negative space 명시
  3. Style (outlines? gradients?) → discipline 다시 강조
  4. Iconography (random animal? wrong season?) → exclusion 추가

각 생성 후:

- [ ] **시각 검수**: thumbnail (100px)에서 silhouette 읽히는지
- [ ] **색 검수**: warm/cool 균형 (sepia 아님 / icy 아님)
- [ ] **단계 일관성** (한옥 시리즈): 다른 단계와 카메라 각도·구도 일치
- [ ] **transparent 검수** (장식): 배경 정말 투명한지

---

## 11. 우선순위 추천 양산 순서

Jin이 양산하면 좋은 순서 (가장 임팩트 큰 것 → 작은 것):

**Sprint 1 (Week 1-2, ~15 PNG)**:
1. 한옥 Stage 0 (empty) + Stage 4 (thatch) + Stage 6 (tile complete) + Stage 8 (gate) + Stage 11 (jongga) light & dark = **10 PNG**
2. 단청 도장 base 디자인 8종 = **8 PNG**

이 단계에서 핵심 분위기 확정. 결과물 보고 색감·구도 조정 → 나머지 한옥 단계는 이걸 base로.

**Sprint 2 (Week 3-4, ~20 PNG)**:
3. 나머지 한옥 stages (1, 2, 3, 5, 7, 9, 10) light & dark = **14 PNG**
4. 특별 퀘스트 핵심 6개 (장독대 / 매화 / 노송 / 연못 / 장명등 / 풍경) = **6 PNG**

**Sprint 3 (Week 5-6, ~15 PNG)**:
5. 사군자 4폭 + 편액 + 돌담 + 까치 둥지 = **8 PNG**
6. 책 한 컷 UI 일러스트 5종 = **5 PNG**

**Sprint 4 (Week 7-8, ~30 PNG)**:
7. 계절 이벤트 4종 = **4 PNG**
8. 스티커 30종 = **30 PNG** (이건 빨라야 함, 단순)

**Sprint 5 (Week 9-10, ~10 PNG)**:
9. 계 공동 한옥 8 PNG
10. Feature graphic 1 PNG

**총 ~100 PNG, 10주, 주당 평균 10장**.

---

## 12. 변경 이력

| 날짜 | 변경 | 작성 |
|---|---|---|
| 2026-05-31 | 최초 작성 | Claude |

---

**검토자**: Jin (pending)
**상위 plan**: `docs/plans/stately-rising-jongga.md`
**스타일 기준**: `docs/HANGUL_SORI_STYLE_GUIDE.md`
