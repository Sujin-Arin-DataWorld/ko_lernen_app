# 씬 포스터 추가 2종 — `salon` · `bank`

**작성** 2026-08-17 · **대상** `ko_lernen_app`
**상속** `docs/ASSET_PROMPTS_2026-08-03.md` §A (경로·규격·A-0 공통 스타일 블록). 이 문서는 그
A절의 A-8·A-9 로 읽는다.
**규격** `assets/illustrations/scenes/{key}.png` · **1086×1448 (3:4)** · 배경 채움 PNG · 인물 0 ·
문자 0. 루프(`assets/video/loops/scene_{key}.mp4`)는 만들지 않는다 — 정지 포스터만.

## 왜 필요했나

`ScenarioBackdrop._categoryById` 에 미용실·은행 카테고리가 없어서 머리 자르는 장면 3편이
`cafe` 를, 은행 창구 장면 3편이 `office` 를 쓰고 있었다. 카페 배경에서 커트 길이를 말하고
회의실 배경에서 대기번호를 뽑는 그림이라 장소 정체성이 깨진다. 포스터가 생기면서
`cafe` 23→20, `office` 84→81 로 하중도 조금 내려간다.

| 키 | 커버 시나리오 | 이전 배경 |
|---|---|---|
| `salon` | `a2_salon_cut` · `a2_dye_dark` · `a2_hair_time` | `cafe` |
| `bank` | `a2_bank_number` · `bank_account` · `rent_bank_transfer` | `office` |

## 생성 절차

1. 아래 씬 블록 + `ASSET_PROMPTS_2026-08-03.md` **A-0 공통 스타일 블록**을 이어 붙인다.
2. 레퍼런스로 `scenes/cafe.png` + `scenes/hotel.png` 를 첨부한다 (A-0 이 이 두 장을 명시로
   가리킨다 — 첨부 없이 돌리면 팔레트만 맞고 면 분할 화풍이 어긋난다).
3. 모델 `Nano Banana Pro`, 종횡비 `3:4`. 한옥 A1 키트와 같은 조합
   (`docs/assets/prompts/HANOK_V1_A1_KIT_GENERATION_PLAYBOOK.md` §1).
4. 받은 이미지를 정확히 1086×1448 로 리샘플해 저장한다. 기존 12장이 전부 이 치수라
   어긋나면 타일에서 크롭이 달라진다.
5. `flutter test test/scene_asset_resolver_test.dart` — "모든 카테고리 키에 실제 포스터 PNG 가
   있다" 가드가 새 키 2개를 함께 검사한다.

### A-8. `salon` — 미용실 → `scenes/salon.png`

```
A 3:4 vertical editorial illustration of a calm Korean hair salon — bright, tidy, unhurried.
LAYER 1 (top ~35%): soft ceiling light, hanji light #FFFCF2 fading to sky celadon #D8E5DC (the single allowed gradient), a warm ochre #DFA951 glow along a mirror rail.
LAYER 2 (mid): a row of tall BLANK mirrors in hanok slate #2A3340 frames, a styling counter in warm walnut #8E6646 (shadow #5C4028) holding bottles abstracted as small muted planes (teal #3D9A7F / red #C24A45 / cream), a wall shelf grid.
LAYER 3 (foreground): two styling chairs as faceted slate silhouettes, a folded cream cape, a rolling tray, a wash-basin edge in stone gray #9A938C; floor stone gray #9A938C blending hanji cream #FAF6EC. 2 loose dancheong dot groupings (#C24A45, #DFA951, #3D9A7F). Nothing crosses the calm center.
Palette: #FFFCF2 #FAF6EC #D8E5DC #8E6646 #5C4028 #2A3340 #3D9A7F #C24A45 #DFA951 #9A938C
```

### A-9. `bank` — 은행 창구 → `scenes/bank.png`

```
A 3:4 vertical editorial illustration of a quiet Korean bank branch hall — orderly, formal, reassuring.
LAYER 1 (top ~35%): high ceiling with even indirect light, hanji light #FFFCF2 fading to sky celadon #D8E5DC, a BLANK overhead number-display panel in hanok slate #2A3340 (no digits, no letters).
LAYER 2 (mid): a long teller counter in warm walnut #8E6646 (shadow #5C4028) with glass dividers as thin celadon planes, a queue-ticket kiosk as a plain slate box, a wall of blank pigeonhole panels as a cream/walnut grid.
LAYER 3 (foreground): a walnut waiting bench, a rope-and-post queue line, a small potted plant teal #3D9A7F, floor stone gray #9A938C with hanji cream #FAF6EC bands. 1 minimal dancheong dot grouping (#C24A45, #DFA951). Center calm and low-contrast.
Palette: #FFFCF2 #FAF6EC #D8E5DC #8E6646 #5C4028 #2A3340 #3D9A7F #C24A45 #DFA951 #9A938C
```

## 검수 체크

- 인물·동물·문자 0. 거울과 번호 표시판은 **빈 판**이어야 한다 (§7.4 무문자 원칙).
- 중앙 1/3 이 저대비 — 대사가 그 위에 올라간다.
- 100px 로 줄여도 미용실/은행으로 읽히는가 (거울 줄 / 창구 줄).
- 1086×1448 정확히. IHDR 은 `python -c` 로 바로 확인한다.
