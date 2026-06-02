# Hangul Sori — 마스코트 포즈 프롬프트 시트 v2 (Faceted 통일판)

> **작성일**: 2026-06-02
> **목적**: 업로드된 고품질 마스코트(앉은 호랑이 + 갓 까치 2종)를 **마스터**로 삼아,
> 앱 `Mascot` 위젯의 emotion enum에 필요한 나머지 포즈를 **같은 캐릭터·같은 그림체**로 양산.
> **스타일 기준**: `docs/HANGUL_SORI_STYLE_GUIDE.md` (Faceted Minhwa)
> **마스터 레퍼런스**: `assets/illustrations/mascot/tiger_idle.png` (호랑이),
> `magpie_wingup.png` / `magpie_wingdown.png` (까치)

---

## 0. 현재 상태 (2026-06-02 기준)

| 분류 | 파일 | 상태 |
|---|---|---|
| ✅ 통일된 faceted 세트 | `tiger_idle`, `tiger_blink`, `tiger_happy`, `magpie_wingup`, `magpie_wingdown` | **마스터 — 그대로 유지** |
| ♻️ 재생성 필요 (옛 그림체) | `tiger_smile`, `tiger_neutral`, `tiger_celebrate`, `tiger_sad`, `tiger_thinking`, `tiger_sleepy` | idle 기준으로 다시 뽑기 |
| ♻️ 재생성 필요 (옛 그림체) | `magpie_perched`, `magpie_celebrate`, `magpie_worry` | wingup/wingdown 기준으로 다시 뽑기 |

> `tiger_sleepy` / `tiger_thinking` 는 **다른 화풍의 호랑이**다. idle 옆에 두면 이질감이 크므로 우선순위 1순위 교체.

---

## 1. 워크플로우 (캐릭터 고정이 핵심)

1. **도구**: Nano Banana (Gemini 2.5 Flash Image) 권장 — "내 캐릭터 유지, 포즈만 변경"에 최강.
   대안: Midjourney omni-reference(`--cref`).
2. **모든 생성에 마스터 이미지 첨부**: 호랑이 포즈 → `tiger_idle.png` 첨부. 까치 → `magpie_wingup.png` 첨부.
3. **얼굴만 바뀌는 포즈는 생성 금지, 국소 편집**: `blink`(완료), `smile`, `neutral` 은
   idle에서 눈/입만 수정 → 몸이 픽셀 동일 → 애니메이션이 매끄럽다.
4. **몸 포즈가 바뀌는 것만 AI 생성**: `surprised`, `celebrate`, `sad`, `thinking`, `sleepy`.
5. **포즈당 4장 변주 → 1장 선택** (가장 idle과 같은 호랑이로 읽히는 것).
6. **후처리**: 배경 투명화 → 동일 정사각 캔버스(1024×1024 권장, idle과 같은 프레이밍) →
   `pngquant`로 ~300KB 압축 (idle/blink/happy와 용량 맞추기).

### 고정 3요소 (모든 호랑이 프롬프트에 필수)
- **색**: coat `#E87830`, shadow `#C25420`, belly/chin `#F4E8D0`, stripes `#1A1410`
- **표정 친근함**: soft almond amber-gold eyes + 살짝 올라간 입꼬리
- **금지**: cute / chibi / cartoon / outline / smooth gradient (dignified guardian 유지)

---

## 2. 공통 프롬프트 헤더 (복붙용)

```
[ATTACH: tiger_idle.png as character reference]

Identical low-poly faceted Korean tiger character from the attached
reference — SAME face, SAME fur colors, SAME geometric facet style,
SAME friendly-yet-dignified expression. Do not redesign the character.

Fixed palette (do not change): coat burnt orange #E87830, shadow facet
rust orange #C25420, belly/chin/inner-ear tiger cream #F4E8D0, angular
stripes #1A1410. Soft almond-shaped amber-gold eyes, slight upward
mouth corners (friendly). White/transparent background, same camera
distance and framing as the reference.

Style discipline: NO outlines, pure flat color planes, hard-edged
facet shadows only, subtle hanji paper grain. NOT cute, NOT chibi,
NOT cartoon.

NEW POSE: <<<여기에 아래 포즈 설명>>>
```

---

## 3. 호랑이 포즈 (emotion enum 매핑)

### 3.1 `tiger_smile` — emotion: smile *(기본값 — 국소 편집 권장)*
idle에서 **입꼬리를 조금 더 올리고 눈을 살짝 가늘게**. 몸은 그대로.
- 생성으로 갈 경우 NEW POSE:
  `Same seated pose, warmer gentle smile — mouth corners lifted a bit
  more, eyes slightly softened/narrowed in a kind expression.`

### 3.2 `tiger_neutral` — emotion: neutral *(국소 편집 권장)*
idle에서 **입꼬리 평평하게, 눈 완전히 뜸**. 차분한 정면.
- NEW POSE: `Same seated pose, calm neutral expression — relaxed mouth,
  eyes fully open and attentive, no smile.`

### 3.3 `tiger_happy` — emotion: surprised ✅ *(이미 보유 — 참고용)*
귀 쫑긋, 눈 크게, 입 살짝 벌림(밝고 놀란 듯). 신규 필요 시:
- NEW POSE: `Same seated pose, alert delighted expression — ears
  perked up, eyes wide and bright, mouth slightly open.`

### 3.4 `tiger_celebrate` — emotion: celebrate
**두 앞발을 위로 들어 환호**하거나 살짝 점프하는 역동 포즈. 눈웃음.
- NEW POSE: `Joyful celebration pose — both front paws raised up in a
  cheer, slight upward bounce in the body, eyes happily curved, mouth
  open in a delighted roar-smile. Energetic but still dignified.`
- 비고: 몸 전체가 바뀌므로 4~6장 변주 권장.

### 3.5 `tiger_sad` — emotion: worry
**귀 아래로, 눈 처짐, 입 살짝 찌푸림.** 앉은 자세 유지, 어깨 살짝 움츠림.
- NEW POSE: `Worried/sad expression — ears drooping down, eyebrows
  angled up in concern, eyes soft and downturned, mouth slightly
  frowning, shoulders a touch hunched. Seated pose.`

### 3.6 `tiger_thinking` — emotion: thinking
**한쪽 앞발을 턱에 대고 위를 올려다봄.** (현재 파일은 화풍이 다름 → 교체)
- NEW POSE: `Thinking pose — one front paw raised to the chin, head
  tilted slightly up, eyes glancing upward in contemplation, calm
  closed mouth.`

### 3.7 `tiger_sleepy` — emotion: sleepy
**눈 반쯤 감김 + 졸린 표정.** 앉은 자세 유지(누운 자세로 바꾸면 idle과 프레이밍이 깨지므로 주의).
- NEW POSE: `Sleepy/drowsy expression — eyes half-closed and heavy,
  relaxed soft mouth (gentle yawn optional), ears slightly lowered.
  Keep the SAME seated framing as the reference, not lying down.`

### 3.8 `tiger_blink` ✅ *(이미 보유)*
idle에서 눈만 감은 프레임. 추가 작업 불필요.

---

## 4. 까치 포즈 (마스터: wingup / wingdown)

> 까치는 **갓(검은 통영갓 + 가는 금띠) + 흑백 몸 + 호박색 부리**가 고정 아이덴티티.
> 비행 2프레임(wingup/wingdown)이 이미 통일돼 있으니 이를 레퍼런스로.

### 4.1 `magpie_perched` — idle / sleepy
나뭇가지나 처마에 **앉은** 자세. 날개 접음, 정면-측면 3/4.
- `[ATTACH: magpie_wingup.png] Same gat-wearing magpie character —
  perched pose, wings folded against body, calm, slight 3/4 turn,
  white/transparent background.`

### 4.2 `magpie_celebrate` — celebrate
**양 날개를 위로 활짝**, 기뻐하는 자세. wingup의 더 역동적 버전.
- `Same magpie — both wings flung up high in joyful celebration,
  head up, lively energy.`

### 4.3 `magpie_worry` — worry
**몸을 움츠리고 고개 숙임**, 날개 살짝 처짐.
- `Same magpie — hunched worried pose, head lowered, wings drooping
  slightly, subdued posture.`

---

## 5. 후처리 체크리스트

- [ ] 배경 투명 (PNG-24 알파)
- [ ] idle과 동일 정사각 캔버스·동일 발 위치(합성 시 흔들림 방지)
- [ ] `pngquant --quality=65-85` → ~300KB 목표 (현 idle/blink/happy 수준)
- [ ] 다크모드 화면에서도 윤곽 readable한지 100px 썸네일 확인
- [ ] `assets/illustrations/mascot/` 에 동일 파일명으로 덮어쓰기 → 코드 수정 불필요
      (위젯이 이미 해당 경로를 참조, errorBuilder fallback 있음)

---

## 6. 우선순위 (추천 순서)

1. `tiger_sleepy`, `tiger_thinking` — 화풍 이질감 가장 큼
2. `tiger_celebrate`, `tiger_sad` — 결과/퀴즈 화면 노출 빈도 높음
3. `tiger_smile`, `tiger_neutral` — **국소 편집**으로 빠르게
4. `magpie_perched`, `magpie_celebrate`, `magpie_worry`
