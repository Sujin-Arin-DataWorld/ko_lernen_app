# 도깨비불(Will-o'-the-Wisp) 프롬프트

**용도**: `assets/illustrations/dokkaebi_fire.png` (온보딩 page2 호랑이 우상단 뱃지)  
**크기**: 72×72px (정사각), 투명 배경  
**스타일**: Faceted Minhwa (모던 면 분할 민화)

---

## 비주얼 요구사항

### 1. 핵심 요소
- **중앙 불빛 구체**: 따뜻한 황색-주홍색 그라데이션(단 1개만 허용) — 신비로운 호불림
- **면분할 기하 장식**: 불 주위를 감싸는 각진 소용돌이 띠 (별 · 먹빛 · 쪽빛 면들)
- **투명도 건축**: 불빛은 100% 불투명, 주변 장식은 투명도 0-40% 오버레이로 신비감 강조
- **한지 그레인**: 전체에 은은한 닥종이 텍스처

### 2. 색상 (팔레트 hex만 사용)
| 요소 | Hex | 용도 |
|---|---|---|
| 불빛 (중심) | `#DFA951` | Dancheong Gold (황) |
| 불빛 (테두리) | `#E87830` | Burnt Orange (호랑이 주색) |
| 소용돌이 (밝음) | `#C99935` | Dancheong Gold (muted) |
| 소용돌이 (어두움) | `#A8332E` | Dancheong Red (muted) |
| 별·장식 (깊음) | `#1F2E5C` | Muted Indigo (쪽빛) |
| 가장 어두운 악센트 | `#1A1410` | Stripe Black |

### 3. 구성 지침

#### 불빛 (중심, 지름 48px)
- **구체 기본 형태**: 6~8개 각진 면으로 구성 (원형이 아닌 기하 분할)
- **황색 면**: 상단·중앙 3~4개 (Dancheong Gold `#DFA951`)
- **주홍 면**: 하단·측면 2~3개 (Burnt Orange `#E87830`)
- **면 경계**: hard-edge (NO 그라데이션·NO 복셀화). 색이 맞닿은 경계로 정의.
- **내부 1개 그라데이션만**: 불 가운데 제일 밝은 부분에서 halo로 희미한 황→크림 그라데이션 (10px 정도)

#### 신비로운 소용돌이 (지름 60-68px 링)
- **별 5~7개**: Muted Indigo 또는 Black으로 각진 별(★) 모양, 불 주위 원형 배열
- **배경 면들**: 불 주위 2~3개 층으로 각진 호 모양 띠
  - 바깥층: Muted Indigo `#1F2E5C` (투명도 20%)
  - 중층: Burnt Orange 또는 Gold (투명도 15%)
  - 안쪽: Black (투명도 10%)
- **흐름감**: 시계방향 소용돌이로 팽이 도는 느낌 (각진 면들이 점진적으로 회전)

#### 테두리
- 외곽 1px margin은 투명 (72px 캔버스 안에서 66×66px 이내로 구성)

### 4. DO & DON'T

#### ✅ DO
- 평면 색면만 (벡터·스테인드글라스 느낌)
- 한지 그레인 오버레이 (은은하게)
- 각진 기하로 호불림 표현 (부드러운 곡선 금지)
- 투명도 차이로 층감 만들기
- 팔레트 hex 코드만 정확히

#### ❌ DON'T
- 검은 외곽선 (형태는 색면 경계로만)
- 복셀 아트 / 픽셀화
- 그라데이션 남발 (불빛 halo 1개만)
- 네온/사탕톤 (muted 보석톤만)
- 유기곡선·부드러운 둥근 모양

---

## 프롬프트 (AI 에이전트용)

### 기초 프롬프트
```
Create a mystical will-o'-the-wisp badge (72×72px, square, transparent background) in the "Faceted Minhwa" style:

**Core elements:**
- Central glowing orb (48px diameter): Geometric facets of Dancheong Gold (#DFA951) and Burnt Orange (#E87830), 
  with a single subtle halo gradient (gold-to-cream, 10px soft blur inside the shape)
- Swirling mystique ring (60–68px): 5–7 angular stars in Muted Indigo (#1F2E5C, 20% alpha) 
  + 2–3 layered arc bands rotating clockwise (each band 15–20% alpha, alternating Indigo/Burnt Orange/Black)
- Hanji paper grain texture: subtle woven paper overlay across the entire image
- Stroke: NO outlines, NO smooth curves. All shapes defined by hard-edge color adjacency.

**Color palette (hex only):**
- Gold: #DFA951
- Burnt Orange: #E87830
- Muted Indigo: #1F2E5C
- Black: #1A1410
- (Background: transparent)

**Style:** Mid-century geometric facets (Saul Bass / Charley Harper), Korean folk-painting iconography, 
aged hanji paper texture. Mystical, glowing, otherworldly—but grounded in angular geometry, not soft gradients.

**Finalization:**
- Canvas: 72×72px, 1px transparent margin
- Format: PNG with alpha channel
- No compression artifacts; high FilterQuality
```

### 세부 프롬프트 (첫 출력이 부족할 경우)
```
Will-o'-the-wisp in Faceted Minhwa style (72×72px, transparent):

**Central glowing orb (NOT round—faceted):**
- 6–8 angular planar facets of warm gold/orange
- Gold facets (#DFA951) dominate upper/center regions
- Orange facets (#E87830) in lower/side regions
- Single soft glow halo inside (gold→cream, feathered to 10px blur radius)
- NO outer stroke, NO curved edges
- All shapes built from hard-edge color blocks

**Mystical swirl halo (concentric rings):**
- Innermost: 5 angular stars (Muted Indigo #1F2E5C, rotated 45°, ~12px each), 20% alpha, arranged around orb
- Middle layer: 2 curved arc bands (Burnt Orange/Black alternating, 15% alpha each), clockwise rotation
- Outer layer: 1 thin arc (Indigo again, 10% alpha)
- NO smooth curves—all arcs built from linked angular segments (3–5 sided shapes per arc)

**Texture & finish:**
- Hanji paper grain overlay (subtle diagonal weave, <5% opacity, warm tan color)
- Finalize at 72×72px, RGBA, 1px transparent margin
- No antialiasing artifacts; clean geometric edges

**Inspiration:** Mystical Korean folk-fire from 18th-century minhwa paintings, 
reinterpreted through Saul Bass geometric abstraction.
```

---

## 생성 & 후처리 체크리스트

- [ ] **생성**: 위 프롬프트로 3–5장 생성 (AI 모델: Gemini Image, Midjourney, DALL·E 권장)
- [ ] **선택**: 1장 선택 (면분할 정도, 신비감, 한지 그레인 품질 기준)
- [ ] **검증**:
  - [ ] 72×72px 정사각
  - [ ] 투명 배경 (RGB 아님, RGBA)
  - [ ] 외곽선 0개 (hard-edge color만)
  - [ ] 6 color hex만 사용 (자유로운 중간톤 없음)
  - [ ] 한지 그레인 보임
- [ ] **투명화** (배경 완벽): floodfill으로 테두리 근백색 제거
- [ ] **압축**: P+alpha palette(256색) 양자화, lossless
- [ ] **경로**: `assets/illustrations/dokkaebi_fire.png` 저장
- [ ] **pubspec.yaml**: `assets/illustrations/` 이미 등록됨 (재등록 불필요)

---

## 참고: 온보딩 page2 맥락

```dart
// onboarding_preview_screen.dart:284–316
if (useDokkaebi)
  Positioned(
    top: 0,
    right: 4,  // 호랑이 우상단
    child: Image.asset(
      'assets/illustrations/dokkaebi_fire.png',
      width: 72,
      height: 72,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        // PNG 미존재 시 폴백: 불 아이콘 + 글로우
        decoration: BoxDecoration(
          color: accentColor,  // #A0524A (석간주 적)
          boxShadow: [BoxShadow(blurRadius: 16, ...)]
        ),
        child: Icon(Icons.local_fire_department_rounded, ...),
      ),
    ),
  ),
```

→ 호랑이 축하 표정(celebrate) 옆, 우상단에 신비로운 도깨비불 뱃지로 나타남.  
→ 온보딩 완료 축하 분위기 강화 (호랑이 celebrate + 도깨비불 glow).

---

## 이전 시도 (참고용 아님)

X 부드러운 원형 불빛 (스타일 위반)  
X 밝은 네온 노란색 (팔레트 위반)  
X 검은 외곽선 (스타일 위반)  
X 그라데이션 남발 (halo만 허용)  
