# Sotdae-mun (솟을대문) Gate — Layered Decomposition Prompt

**Reference Image:** `gate.png` — Complete hanok gate composition
**Canvas:** 1080 × 1920 px (normalized registration space)
**Style:** Faceted Minhwa (모던 면 분할 민화)
**Purpose:** 3D door opening animation (left door rotates on left hinge, right door rotates on right hinge)

---

## THREE-LAYER DECOMPOSITION

The complete gate.png must be split into **three separate PNG files**, each 1080×1920 px, with precise alpha transparency:

### 1. **gate_frame.png** — Static Architectural Frame
**Content (all alpha-opaque on layer):**
- **Sky background** — `#FAF6EC` hanji cream (top 60%)
- **Mountains & landscape** — Faceted teal/sage greens (`#3D9A7F`, `#5C7060`) left/right lower corners with hard-edged faceted planes
- **Decorative accents** — Moon (`#2C3E94` indigo circle, upper right), scattered earth-tone dots (`#A0524A`, `#8E6646`)
- **Roof (기와)** — Curved dark slate tile (`#2A3340` primary, `#1A2028` shadow facets) with upturned eave horns (처마끝). Include individual semicircle tile facets across top edge
- **Roof cap flowers** — Tiny chrysanthemum discs in cream + gold at horn tips
- **Rafter ends (서까래)** — Row of small uniform warm-walnut (`#8E6646`) rectangles along full eave drip line
- **Decorative dancheong band (단청)** — Horizontal band immediately below roof, teal base (`#3D9A7F`) with alternating squares in red (`#C24A45`), gold (`#DFA951`), cream (`#FAF6EC`). Each square contains tiny geometric or floral motif (4-pointed star, flower cross, hexagon)
- **Wooden structural frame** — Outer pillars (`#8E6646` primary, `#5C4028` shadow on inner edge) wrapping left/right sides and top edges, approximately 80 px wide
- **Horizontal beam (상방) above doors** — Warm walnut (`#8E6646`) with darker wood shadow facet beneath
- **Stone foundation (초석) / Base step** — `#8B8478` stone gray, lower 100 px, slightly trapezoid perspective
- **Magpie with gat** — Black silhouette magpie wearing gat hat (flat gold-band brim, tall cylindrical crown), positioned upper-center atop roof, 60–80 px scale

**What is NOT on frame:**
- ❌ Door panels themselves
- ❌ Door knocker / handle
- ❌ Door studs/bosses (금고정)
- ❌ Any content within the door panels

---

### 2. **gate_door_left.png** — Left Hinged Door Panel
**Content & Transform:**
- **Door panel** — Vermillion red (`#C24A45` saturated, or `#A8332E` if shadow variant), occupies left half of door opening
  - Positioned: left `195 px` (18% of 1080), top `615 px` (32% of 1920)
  - Size: `345 px` wide × `1000 px` tall (32% × 52% of canvas)
  - **Hinge edge:** LEFT edge (at `x=195`) — rotation pivot is here
  - **Inner edge toward center:** RIGHT edge (at `x=540`) — opens outward to negative angle (rotateY(-theta))

- **Door surface detail:**
  - **Vertical stud rows** — Gold circular bosses (`#DFA951` ochre) in 4 columns × 6 rows across door face, evenly spaced ~40 px apart
  - **Center ring knocker mount** — Gold lion-head or ring handle mounted at door center (but knocker itself separate, see note below)
  - No seams, cracks, or weathering — clean flat minhwa aesthetic

- **Surrounding woodwork on left door layer (optional depth):** 
  - Left pillar/edge (`~80 px` walnut) where door meets frame (helps with closure)

**Alpha:**
- Fully opaque on door + left frame trim
- Transparent outside door rect to allow frame to show through

**Note on Knocker:**
- Knocker (쌍고리 or lion-head handle) can be on EITHER left/right door, or centered on frame — **specify which when generating.** For simplicity, recommend placing on frame layer (center between doors).

---

### 3. **gate_door_right.png** — Right Hinged Door Panel
**Content & Transform:**
- **Door panel** — Vermillion red (same as left, `#C24A45` or `#A8332E`)
  - Positioned: left `540 px` (50% center line), top `615 px` (same as left door)
  - Size: `345 px` wide × `1000 px` tall (same as left)
  - **Hinge edge:** RIGHT edge (at `x=885`, i.e., `540 + 345`) — rotation pivot is here
  - **Inner edge toward center:** LEFT edge (at `x=540`) — opens outward to positive angle (rotateY(+theta))

- **Door surface detail** — Identical stud pattern as left door (4 cols × 6 rows)

- **Surrounding woodwork on right door layer (optional depth):**
  - Right pillar/edge (`~80 px` walnut) where door meets frame

**Alpha:**
- Fully opaque on door + right frame trim
- Transparent outside to show frame

---

## TECHNICAL SPECIFICATIONS

### Canvas & Export
- **Format:** PNG with alpha channel (RGBA)
- **Canvas size:** 1080 × 1920 px (pixel-perfect registration)
- **DPI / Resolution:** 72 dpi (web/screen standard)
- **Color mode:** sRGB
- **Compression:** PNG lossless, no optimization (preserve quality)

### Alignment Reference
The original `gate.png` shows the complete composition. Each layer maintains the same 1080×1920 bounding box, with transparent areas outside the relevant content zones. This allows the three PNGs to stack (frame bottom, then left door on top, then right door on top) and still register perfectly.

**Door hinge pivot lines (for reference):**
- Left door rotates around `x = 195 px` (left edge)
- Right door rotates around `x = 885 px` (right edge)
- Both doors pivot around the same Y axis (standard 3D door animation)

---

## STYLE DIRECTIVES (Non-negotiable)

✅ **DO:**
- Use **hard-edged faceted planes** (no soft gradients within shapes, except 1 intentional soft glow if desired)
- Maintain **Dancheong color bands** with geometric precision (squares align, not random)
- Keep **minhwa iconography** authentic: gat-wearing magpie, upturned eaves, wooden pillars, stone base
- Preserve **hanji paper grain texture overlay** (subtle, aged mulberry paper look)
- Use **flat opaque colors** from the reference palette (saturated but muted jewel tones, no candy colors)

❌ **DON'T:**
- Add black outlines or strokes around objects (no outlines at all)
- Smooth gradients within individual shapes (hard facet transitions only)
- Include weathering, cracks, rust, or photorealistic details
- Change door color or surface material
- Add elements not in the reference frame (random flowers, creatures, etc.)

---

## ADDITIONAL NOTES

### For Door Closing Animation (reverse):
When `openAmount = 0` (doors fully closed), the three layers should appear as a single seamless gate image identical to `gate.png` — no visible seams between frame and doors.

### Accessibility:
All three layers use the same hanji-cream background (`#FAF6EC`) where transparent, ensuring no visual "jarring" when layered in code.

### Future Variants (out of scope, but note):
- **Dark mode madang variant:** Would swap hanji cream for dark earth (`#15201A`) and adjust all colors accordingly (separate dark-mode triple layer set)
- **Seasonal / Festive variants:** e.g., plum blossoms for spring, would swap decorative elements but keep structure

---

## PROMPT FOR IMAGE GENERATION

**Use this English prompt with your image generation tool:**

---

### ⬇️ COPY BELOW FOR IMAGE GEN ⬇️

```
TITLE: Sotdae-mun (솟을대문) Gate — Three-Layer Decomposition for 3D Door Animation

STYLE: Faceted Minhwa (모던 면 분할 민화)
A modern editorial illustration fusing mid-century geometric reduction (Saul Bass, Charley Harper) 
with Korean Joseon folk painting iconography. Every element is built from clean, angular flat 
color planes (facets) with NO outlines, NO smooth gradients within shapes. Volume emerges 
exclusively through hard-edged transitions between adjacent facets (light plane meeting shadow plane 
at sharp boundaries, like cut paper or stained glass). The entire image carries a subtle, aged 
hanji (Korean mulberry paper) grain texture overlay — essential for authentic warmth and tactile 
presence; without this detail, the image risks looking sterile and digital.

PROJECT CONTEXT:
This is a Korean language learning app for German-speaking users. The Sotdae-mun gate is the 
opening cinematic sequence. The three-layer PNG decomposition enables a 3D door-opening animation 
in Flutter (left door rotates on left hinge, right door rotates on right hinge, frame remains static).

---

REFERENCE COMPOSITION:
The final composite gate.png shows a Sotdae-mun (raised ceremonial gateway) dominating a 1080×1920px 
vertical canvas. The composition is balanced between architecture and landscape, with generous 
negative space above and below. The style is editorial, refined, sophisticated — premium magazine 
cover quality.

Upper region (30%): Dark-slate curved tile roof with dramatic upturned eave horns (처마끝), 
accented by a row of individual semicircular tile facets along the top edge. Sitting proudly atop 
the roof's peak is a silhouette magpie wearing an ornate gat (갓) hat. Lower roof area features 
a decorative dancheong band with precise geometric squares in alternating teal, red, gold, and cream, 
each square containing a tiny flower or geometric motif.

Middle region (40%): Two heavy wooden door panels in deep vermillion-red dominate the center. 
Each door is studded with 4 columns × 6 rows of gold circular bosses (금고정), evenly spaced 
to suggest traditional Korean craftsmanship. The surrounding frame is built from warm-walnut wooden 
pillars and beams, each pillar showing a darker shadow facet on its inner edge for three-dimensional 
depth.

Lower region (30%): Landscape foundation. Foreground consists of a stone base (초석, trapezoid 
perspective in stone-gray). Left and right background feature faceted mountains in receding teal 
and sage greens (Irworobongdo style layering). Scattered decorative accents include a muted 
indigo crescent moon (upper right), subtle warm earth-tone dots (seal stamps), and the overall 
ground blending into the hanji cream background.

---

CRITICAL STYLE DIRECTIVES (Do NOT deviate):

✅ DO — Faceted Geometric Structure:
  - Every shape (roof tiles, pillars, door panels, mountains, leaves, details) is constructed 
    from clean angular flat color planes.
  - NO curves unless essential (mountain horizons may have subtle curves, but must be hard-edged facet lines).
  - Think: cut colored paper stacked to create depth, or stained glass windows — not smooth 3D rendering.
  - Each facet is a distinct fill color, meeting its neighbors at sharp, clean boundaries.

✅ DO — Hard-Edged Facet Transitions for Volume:
  - Volume emerges ONLY through value shifts between adjacent facets.
  - Light facet meets darker shadow facet at a hard edge — NO soft blending, NO gradient blur.
  - Example: Pillar primary face is warm-walnut #8E6646, inner shadow edge is walnut-shadow #5C4028. 
    The edge between them is SHARP, creating the illusion of 3D depth.
  - Same principle applies to roof planes, door studding, mountain ranges, etc.

✅ DO — NO Outlines, NO Strokes:
  - Shapes are defined entirely by their fill color meeting adjacent shapes' fill colors.
  - If you're tempted to add a thin black line around an object edge — STOP. Delete it.
  - If a door stud needs definition, define it through facet color shifts, not a circle outline.
  - Exception: Interior details within objects (e.g., tiny geometric motif inside dancheong squares) 
    may use a thin 1-2px dark accent line only if absolutely necessary for legibility.

✅ DO — ONE Optional Soft Gradient per Image:
  - Permitted soft gradient zones: Sky atmosphere (cream #FAF6EC fading to pale celadon #D8E5DC at horizon), 
    or a single warm glow halo around the moon.
  - Everything else: HARD edges. FLAT facets.

✅ DO — Hanji Paper Grain Texture Overlay:
  - CRITICAL DETAIL. Apply a subtle, aged Korean mulberry paper grain texture across 100% of the final image.
  - Texture should feel like old handmade paper with organic weave marks and micro-irregularities.
  - Opacity: ~3-8% so it's present but not overwhelming; it should feel like the image IS printed on aged paper.
  - Optional: Scatter 2-4 tiny aged spots (faint brown, 1-2% opacity) to suggest age and authenticity.
  - This texture is what lifts the image from "clean digital vector" to "premium editorial illustration."

✅ DO — Authentic Korean Iconography (Not Decorative):
  - Magpie with gat (갓) hat: The gat is NOT random. It has three precise components: 
    (1) flat oval brim (가운데), (2) tall cylindrical crown (울), (3) thin gold metal band where brim meets crown.
    The magpie's body is pure black, beak is amber-gold, and the gat is positioned slightly tilted at a dignified angle.
  - Upturned eave horns (처마끝): Curved but faceted, dark-slate primary color, with individual 
    semicircular roof tile facets running along the top perimeter.
  - Dancheong band (단청): Teal base #3D9A7F with alternating geometric color squares. 
    Squares in sequence: red #C24A45 → gold #DFA951 → cream #FAF6EC, repeating. 
    Each square contains a tiny motif (4-pointed star, small lotus cross, or hexagon) in complementary color.
  - Wooden structure: All wood must use warm-walnut #8E6646 for primary planes, with shadow facets in 
    walnut-shadow #5C4028 or deep-walnut #3E3024 for maximum value contrast.

✅ DO — Color Palette Fidelity:
  Use ONLY these hex values. No variations, no approximations:
  
  Foundation:
  - Hanji Cream (sky, background): #FAF6EC
  - Hanji Ivory (paper surface): #F4E8D0
  - Hanji Light (palest cream): #FFFCF2
  
  Architecture (Roof, Slate):
  - Hanok Slate (eave primary): #2A3340
  - Deep Slate (shadow facets): #1A2028
  - Stone Gray (base, foundation): #8B8478
  
  Wood (Pillars, Beams, Rafters):
  - Warm Walnut (primary wood): #8E6646
  - Cherry Wood (rafter accents): #7E5A3D
  - Walnut Shadow (shadow facets): #5C4028
  - Deep Walnut (darkest shadow): #3E3024
  
  Doors & Accents (Dancheong):
  - Dancheong Red (door primary): #C24A45
  - Dancheong Gold (studs, accents): #DFA951
  - Dancheong Teal (mountain, band): #3D9A7F
  - Mountain Sage (mid-range mountain): #5C7060
  - Muted Indigo (moon): #1F2E5C
  
  Do NOT use any color outside this palette. This constraint ensures cohesion across all app assets.

---

TECHNICAL SPECIFICATIONS — LAYER DECOMPOSITION:

Each PNG is 1080 × 1920 pixels, RGBA color mode, sRGB, 72 DPI.
Alpha channel used: Fully opaque on content, fully transparent outside content zones.
All three layers register to the exact same 1080×1920 canvas — they stack perfectly in code.

---

### LAYER 1: GATE_FRAME.png
**Role:** Static architectural foundation. All elements except the two door panels.
**Content (opaque on this layer):**

1. **Sky Background (Top 60%)**
   - Solid fill hanji cream #FAF6EC
   - Optional: Subtle soft gradient fade to pale celadon #D8E5DC at horizon line (soft gradient exception)
   - NO objects, pure negative space — breathing room is essential

2. **Roof (기와지붕) — Top 15% of image**
   - Primary curved tile roof in hanok-slate #2A3340
   - Roof shape: Graceful upturned eave horns (처마끝) at left and right edges, curving upward in faceted planes
   - Eave underside (inner curve, shadow): Deep-slate #1A2028 — hard-edged facet beneath the curve
   - Top perimeter: Individual semicircular tile facets (like a row of shells), 40-60px wide each, 
     alternating between hanok-slate #2A3340 (light facet) and deep-slate #1A2028 (shadow facet) 
     to suggest curvature and volume. NO shading gradient; each tile is a distinct flat rectangle or semicircle.
   - Roof tile caps (망와, tiny chrysanthemums) at eave horn tips: 8-10px cream discs with tiny ochre gold center

3. **Magpie with Gat Hat — Atop Roof Peak (Upper Center)**
   - Position: Center-top, silhouette style on roof ridge
   - Body: Pure black #1A1410
   - Beak: Small amber-gold #DFA951
   - Gat hat (갓): Precisely structured:
     * Flat oval brim in black, approximately 50-60px wide, tilted slightly
     * Tall cylindrical crown (울) rising from brim center, approximately 30px tall, in black
     * Metal band (where brim meets crown): Thin gold line #DFA951, 1-2px
   - Wings folded, confident upright pose
   - Scale: 60-80px total height
   - NO cute/chibi proportions; dignified, guardian energy

4. **Dancheong Band (단청) — Below Roof (Horizontal, 40-60px tall)**
   - Positioned: Immediately below roof, spanning full width
   - Background: Teal base #3D9A7F, flat fill
   - Geometric squares: 6-8 repeating squares across width, each 120-150px wide
   - Square colors in sequence: red #C24A45 → gold #DFA951 → cream #FAF6EC, repeating
   - Each square has a tiny interior motif (4-pointed star, lotus cross, or hexagon) 
     in complementary color (dark charcoal or deep teal), 15-20px scale
   - Edges between squares: HARD lines, no blending
   - Edges between teal and squares: HARD lines
   - The band is perfectly flat, no perspective distortion

5. **Rafter Ends (서까래) — Below Dancheong Band (Horizontal Row)**
   - Small uniform rectangles (approximately 20-30px wide × 8-12px tall)
   - Color: Cherry-wood #7E5A3D, alternating with walnut-shadow #5C4028 for visual rhythm
   - Spacing: Even gaps between each (5-8px), creating a "dark teeth" effect along the curve
   - Positioned to follow the eave curve (subtle perspective, but faceted, not smooth)
   - Total row height: 15-20px

6. **Wooden Pillars & Structural Frame (기둥)**
   - Left and right pillars: Positioned at left and right edges of the door opening
   - Each pillar: Approximately 80-100px wide, full door height, in warm-walnut #8E6646
   - Pillar faceting: 
     * Primary face (facing forward): Warm-walnut #8E6646
     * Inner shadow facet (facing inward, toward door center): Walnut-shadow #5C4028 — creates depth illusion
     * Edge between facets: SHARP, hard boundary — no gradient
   - Horizontal beam (상방, above doors): Warm-walnut #8E6646, approximately 60-80px tall
   - Beam shadow facet (underside): Deep-walnut #3E3024, hard-edged transition
   - Top horizontal bar (connecting pillar tops): Walnut #8E6646

7. **Stone Foundation Base (초석) — Bottom 80-120px**
   - Shape: Trapezoidal (wider at bottom, slightly narrower at top, suggesting perspective)
   - Color: Stone-gray #8B8478
   - Faceting: 
     * Top surface (facing up, catches light): Stone-gray #8B8478
     * Shadow facet (front-facing side): Darker value of stone (approximately #6D5D4F or blend with charcoal #3E3A38)
   - Edge definition: HARD facet transitions
   - NO weathering, cracks, or photorealistic texture; flat faceted planes only

8. **Landscape (Mountains, Lower Left & Right)**
   - Lower corners (left and right background): Faceted mountain peaks in Irworobongdo style
   - Foreground mountain (closest): Mountain-teal #3D9A7F, primary facet
   - Mid-range mountain (middle layer): Mountain-sage #5C7060
   - Distant mountain (background, barely visible): Pale-sage #9BB0A0, faded
   - Each mountain is constructed from 3-6 faceted planes, overlapping left-to-right (atmospheric perspective)
   - Mountain edges: ALL hard facet lines, NO soft slopes
   - Tip: The magpie and moon may partially overlap mountains for compositional balance

9. **Decorative Accents**
   - Muted indigo crescent moon (#1F2E5C): Upper right area, approximately 30-40px scale, flat semicircle or crescent shape
   - Scattered seal stamp accents: 3-5 tiny squares or circles in earth-tone (#A0524A or #8E6646), 
     6-10px scale, scattered in upper right and lower left — suggests traditional ink seal stamps
   - Optional: Tiny golden dots (3-4px, #DFA951) scattered in sky for visual interest

**What is NOT on gate_frame.png:**
- ❌ Door panels (left and right)
- ❌ Door studs / bosses (금고정)
- ❌ Door knocker or handle
- ❌ Any content within the door opening area

---

### LAYER 2: GATE_DOOR_LEFT.png
**Role:** Left half of the hinged door, rotates on its left edge.
**Position & Dimensions:**
- Left edge (hinge): x = 195px (18% of 1080)
- Top edge: y = 615px (32% of 1920)
- Width: 345px (32% of canvas)
- Height: 1000px (52% of canvas)
- Right edge (inner): x = 540px (center of canvas)

**Content (opaque within door boundary):**

1. **Door Panel (Left Half)**
   - Color: Dancheong-red #C24A45 (saturated, primary face)
   - Shape: Vertical rectangle, clean edges
   - Surface finish: Flat, no shading gradient; entire panel is one facet

2. **Shadow Facet on Door (Optional Depth)**
   - If including 3D depth effect: Apply a thin vertical shadow facet on the RIGHT inner edge of the door 
     (the edge closest to the center). This facet would be darker red #A8332E.
   - Shadow facet width: 5-10px, hard-edged transition from primary red #C24A45
   - This creates subtle depth illusion without breaking the flat-plane aesthetic

3. **Door Studs (금고정) — Circular Bosses**
   - Grid layout: 4 columns × 6 rows, evenly distributed across door face
   - Stud scale: Each stud approximately 25-35px diameter
   - Stud color (primary face): Dancheong-gold #DFA951
   - Stud shadow facet (right and bottom edge of each circle): Darker gold #C99935 or ochre-yellow, 2-4px wide
   - Shadow facet positioning: Creates rounded 3D illusion (light hitting from top-left)
   - Spacing: Even vertical and horizontal gaps (approximately 60-80px center-to-center)
   - Grid starts approximately 40px from left door edge, ends approximately 40px from right door edge

4. **Surrounding Left-Side Pillar/Trim (where door meets frame)**
   - Left edge pillar integration: Approximately 30-40px of warm-walnut (#8E6646) trim extending from left 
     door edge, connecting to frame pillar
   - This trim should match the frame pillar's primary color but NOT include shadow facets 
     (or keep shadow minimal) to avoid visual confusion
   - Optional: If the frame pillar's inner shadow facet (#5C4028) is visible at door edge, 
     ensure HARD transition between door red and pillar shadow

**Alpha Channel (Transparency):**
- Fully opaque: Door panel (entire rectangular zone including studs, inner pillar trim)
- Fully transparent: All areas outside the door boundary
- This allows frame layer to show through around the door edges

**Hinge Behavior (Code Reference, Not Part of Image):**
- Left edge (x = 195px) is the rotation pivot point in Flutter code
- When animated, this door rotates outward/leftward (negative Y rotation in 3D space)

---

### LAYER 3: GATE_DOOR_RIGHT.png
**Role:** Right half of the hinged door, rotates on its right edge.
**Position & Dimensions:**
- Left edge (inner): x = 540px (center of canvas)
- Top edge: y = 615px (same as left door)
- Width: 345px (same as left door)
- Height: 1000px (same as left door)
- Right edge (hinge): x = 885px (82% of 1080)

**Content (opaque within door boundary):**

1. **Door Panel (Right Half)**
   - Color: Dancheong-red #C24A45 (identical to left door)
   - Shape: Vertical rectangle, clean edges
   - Surface: Flat, one facet

2. **Shadow Facet on Door (Optional Depth)**
   - If including 3D depth: Apply a thin vertical shadow facet on the LEFT inner edge of the door 
     (edge closest to center). This facet would be #A8332E.
   - Shadow facet width: 5-10px, hard-edged transition from primary red
   - This creates subtle depth without breaking flat aesthetics

3. **Door Studs (金고정) — Circular Bosses**
   - Grid layout: 4 columns × 6 rows, identical to left door
   - Stud scale: 25-35px diameter each
   - Stud color (primary): Dancheong-gold #DFA951
   - Stud shadow facet: Darker gold #C99935, positioned right and bottom of each stud (2-4px)
   - Spacing: Even distribution, approximately 60-80px center-to-center
   - Grid alignment: Should visually align with left door studs when doors are closed (seamless center line)

4. **Surrounding Right-Side Pillar/Trim**
   - Right edge pillar integration: Approximately 30-40px of warm-walnut (#8E6646) trim extending 
     from right door edge, connecting to frame pillar
   - Consistency: Match frame pillar primary color and shadow treatment
   - Inner facet: If frame pillar has shadow facet (#5C4028), ensure HARD transition between door red 
     and pillar shadow where they meet

**Alpha Channel (Transparency):**
- Fully opaque: Door panel (entire rectangular zone including studs, right pillar trim)
- Fully transparent: All areas outside door boundary

**Hinge Behavior (Code Reference):**
- Right edge (x = 885px) is the rotation pivot point
- When animated, this door rotates outward/rightward (positive Y rotation in 3D space)

---

COMPOSITE VERIFICATION:
When all three layers are stacked (frame bottom, left door on top, right door on top), 
the result should be visually identical to a single complete gate.png with:
- NO visible seams between frame and doors
- Doors appearing fully closed when openAmount = 0
- Seamless 3D illusion when doors begin to rotate open

---

EXPORT REQUIREMENTS:

Format: PNG (Portable Network Graphics)
Color Mode: RGBA (Red, Green, Blue, Alpha)
ICC Profile: sRGB (web-standard color space)
Bit Depth: 8-bit per channel (standard for PNG)
Resolution: 72 DPI (web/screen standard)
Compression: PNG lossless compression (no special optimization; preserve quality)
Filename Format:
  - gate_frame.png
  - gate_door_left.png
  - gate_door_right.png
File Size Constraint: Each PNG should be <200 KB (Faceted Minhwa style with flat planes compresses well)

---

CRITICAL REMINDERS — Do NOT Skip:

⚠️ NO OUTLINES: Every shape you create, ask yourself: "Is this defined by a stroke/outline, 
or by color-plane fill edges?" If it's an outline, delete it. Planes only.

⚠️ HARD EDGES: Every transition between two different colors must be a SHARP, CLEAN boundary. 
No blur, no feathering, no anti-aliasing softness (unless absolutely necessary for 1px edges). 
Facets are FACETS — angular, confident, distinct.

⚠️ HANJI TEXTURE: This is NOT optional. Apply the paper grain overlay to all three final PNGs. 
Without it, the images risk looking digital and sterile. The texture is what makes these 
illustrations feel authentic and premium.

⚠️ COLOR PALETTE FIDELITY: Use ONLY the hex values specified above. No "close enough" colors. 
The palette is intentional and limited for brand cohesion across the entire app.

⚠️ PERSPECTIVE & COMPOSITION: Depth is achieved through overlapping planes and atmospheric 
value shifts, NOT through linear perspective or realistic shading. Imagine the entire image 
is constructed from colored paper cut and layered — that's the mental model.

---

ARTISTIC REFERENCE POINTS (For Tone/Style):
- Charley Harper's mid-century wildlife illustration (geometric, flat color, playful precision)
- Saul Bass's poster design language (bold shapes, restricted palette, cinematic impact)
- Korean minhwa folk painting (iconography, cultural authenticity, symbolic color)
- Contemporary editorial design (premium magazine cover sophistication, balanced composition)

The result should feel like a museum-quality print—bold, confident, culturally authentic, 
and instantly recognizable as premium design. NOT digital, NOT cute, NOT generic anime-style.
```

---

### ⬆️ END PROMPT ⬆️
