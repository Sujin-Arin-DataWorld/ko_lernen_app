# Asset Registry — Hangul Sori

> Single source of truth for which PNG fills which slot in the app.
> Generated 2026-05-28 (Phase 4). Last refreshed 2026-06-01 for the Jongga
> asset import. Refresh whenever a new `Image.asset(...)` or
> `HanokHeader(asset: ...)` call site is added.
>
> All consumer PNGs have an `errorBuilder` (or `HanokHeader` gradient
> fallback). A missing file degrades to icon/gradient — it does not crash.
>
> Stylistic baseline for **new** illustrations: see
> `~/Downloads/HANGUL_SORI_STYLE_GUIDE.md` (Faceted Minhwa).

## 2026-06-01 Jongga Import

Source folder: `~/Downloads/종가이미지`.

Imported into app asset folders:

- Gate intro layers -> `assets/illustrations/hanok/`
- Living hanok stage backgrounds -> `assets/illustrations/hanok_stages/`
- Quest reward decorations -> `assets/illustrations/decorations/`
- Mascot replacements -> `assets/illustrations/mascot/`
- Stamp motifs -> `assets/illustrations/stamps/`
- Sticker/reward extras -> `assets/stickers/`

Composable PNGs that arrived with baked checkerboard backgrounds were converted
to true RGBA alpha after import. Full-scene backgrounds such as
`gate_entrance.png`, `gate_final.png`, and `stage_*_light.png` keep their RGB
backgrounds. `stage_beams.light.DE.png` and `stage_beams.light.EN.png` were
not imported because they are full app UI mockups, not pure stage backdrops.

---

## `assets/illustrations/hanok/` — module headers + intro gate parts

Recommended dimensions: **1200 × 360** (10:3 aspect) for header banners;
**1024 × 1024** for square/composable scene art. RGB PNG palette-quantized
where possible (see Phase 4 compression notes).

| Filename | Slot purpose | Aspect / size | Consumer | Fallback |
|---|---|---|---|---|
| `madang(light).png` | Light-mode home backdrop (Ken Burns) + scenarios list header + intro paper base | 848×1854 | [home_screen.dart:93-96](../../lib/screens/home_screen.dart#L93-L96), [scenarios_list_screen.dart:117-118](../../lib/screens/scenarios_list_screen.dart#L117-L118), [intro_gate_screen.dart](../../lib/screens/intro_gate_screen.dart) | HanokHeader gradient + `travel_explore_outlined` |
| `madang(dark).png` | Dark-mode home backdrop (Ken Burns) | 4:3 photo-like | [home_screen.dart:93-96](../../lib/screens/home_screen.dart#L93-L96) | (Image.asset `errorBuilder` returns SizedBox) |
| `study_classroom.png` | Vocab module header | 10:3 banner | [vocab_screen.dart:279-280](../../lib/screens/vocab_screen.dart#L279-L280) | HanokHeader gradient + `menu_book_outlined` |
| `study_scholar.png` | Grammar + Settings header | 10:3 banner | [grammar_screen.dart:166-167](../../lib/screens/grammar_screen.dart#L166-L167), [settings_screen.dart:56-57](../../lib/screens/settings_screen.dart#L56-L57) | HanokHeader gradient + `auto_stories_outlined` |
| `calligraphy.png` | Hangul overview tab header | 10:3 banner | [hangul_screen.dart:87-88](../../lib/screens/hangul_screen.dart#L87-L88) | HanokHeader gradient + `draw_outlined` |
| `porch.png` | Chosung + Wordle header (shared, Phase 4b: split into unique art when PNGs land) | 10:3 banner | [chosung_quiz_screen.dart:286-287](../../lib/screens/chosung_quiz_screen.dart#L286-L287), [wordle_screen.dart:324-325](../../lib/screens/wordle_screen.dart#L324-L325) | HanokHeader gradient + module-specific icon |
| `achievements.png` | Stats screen header | 10:3 banner | [stats_screen.dart:73-74](../../lib/screens/stats_screen.dart#L73-L74) | HanokHeader gradient + `bar_chart_rounded` |
| `listening_hero.png` | Listening screen header | 10:3 banner | [listening_screen.dart:167-168](../../lib/screens/listening_screen.dart#L167-L168) | HanokHeader gradient + `headphones_rounded` |
| `kkeunmari_hero.png` | Kkeunmari screen header | 10:3 banner | [kkeunmari_screen.dart:236-237](../../lib/screens/kkeunmari_screen.dart#L236-L237) | HanokHeader gradient + `link_rounded` |
| `dancheong_frame.png` | Wordle game-board decorative frame (transparent center) | 1024² square RGBA | [wordle_screen.dart:419-429](../../lib/screens/wordle_screen.dart#L419-L429) | `SizedBox.shrink()` — board still gets BoxBorder + 4 corner dots |
| `gate_entrance.png` | Intro gate — wide closed-gate establishing shot | 1024×1536 RGB | [intro_gate_screen.dart](../../lib/screens/intro_gate_screen.dart) | `SizedBox.shrink()` |
| `gate_final.png` | Intro gate — inner courtyard destination + onboarding backdrop | 1024×1536 RGB | [intro_gate_screen.dart](../../lib/screens/intro_gate_screen.dart), [onboarding_level_screen.dart:105](../../lib/screens/onboarding_level_screen.dart#L105) | intro gradient fallback |
| `gate_frame.png` | Intro gate — transparent outer frame layer | 941×1672 RGBA | [gate_art.dart](../../lib/widgets/sori/hanok/gate_art.dart) | `SizedBox.shrink()` |
| `gate_door_left.png` | Intro gate — left door (animated open) | 737×2135 RGBA | [gate_art.dart](../../lib/widgets/sori/hanok/gate_art.dart) | `SizedBox.shrink()` |
| `gate_door_right.png` | Intro gate — right door (animated open) | 737×2135 RGBA | [gate_art.dart](../../lib/widgets/sori/hanok/gate_art.dart) | `SizedBox.shrink()` |
| `gate.png` | Combined gate composite (homepage final-cta, unused in app currently) | 1024² | — | — |
| `welcome-hero.png` | Tiger+magpie hero composite (homepage mascot-strip; unused in app currently) | 1024² | — | — |
| `studyroom_wating.png` | (legacy / typo) — superseded by `empty/studyroom_waiting.png` | — | — | not referenced; safe to remove |

---

## `assets/illustrations/hanok_stages/` — living hanok growth backdrops

Consumed by [madang_background.dart](../../lib/widgets/sori/madang_background.dart).
The widget looks for
`assets/illustrations/hanok_stages/stage_{slug}_{light|dark}.png`, then falls
back to `hanok/madang(light|dark).png` if the stage PNG is missing.

Imported from `~/Downloads/종가이미지` on 2026-06-01. Current batch contains
light-mode backgrounds only; dark variants still fall back to the legacy
`madang(dark).png`.

| Filename | Stage |
|---|---|
| `stage_empty_light.png` | `HanokStage.empty` |
| `stage_foundation_light.png` | `HanokStage.foundation` |
| `stage_pillars_light.png` | `HanokStage.pillars` |
| `stage_thatch_light.png` | `HanokStage.thatchRoof` |
| `stage_tile_partial_light.png` | `HanokStage.tileRoofPartial` |
| `stage_tile_complete_light.png` | `HanokStage.tileRoofComplete` |
| `stage_dancheong_light.png` | `HanokStage.dancheong` |
| `stage_gate_light.png` | `HanokStage.gate` |
| `stage_windows_light.png` | `HanokStage.windows` |

Missing / intentionally skipped: `stage_beams_light.png`,
`stage_side_building_light.png`, `stage_jongga_light.png`, and all dark
variants. The downloaded `stage_beams.light.DE/EN.png` files are app UI mockups,
not pure backdrop art, so they are not registered.

---

## `assets/illustrations/decorations/` — quest reward overlays

Consumed by [decoration_layer.dart](../../lib/widgets/sori/decoration_layer.dart).
Each quest definition in [quest_catalog.dart](../../lib/data/quest_catalog.dart)
stores a `decorationSlug`; the rendered asset path is
`assets/illustrations/decorations/{decorationSlug}.png`.

Imported from `~/Downloads/종가이미지` on 2026-06-01. These PNGs were converted
from generated checkerboard RGB images to real RGBA alpha.

| Filename | Quest |
|---|---|
| `decoration_jangdokdae.png` | `q_jangdokdae` |
| `decoration_maehwa.png` | `q_maehwa` |
| `decoration_sonamu.png` | `q_sonamu` |
| `decoration_pond.png` | `q_pond` |
| `decoration_punggyeong.png` | `q_punggyeong` |
| `decoration_pyeonaek.png` | `q_pyeonaek` |
| `decoration_sagunja_maehwa.png` | `q_sagunja_maehwa` |
| `decoration_kkachi_nest.png` | `q_kkachi_nest` |
| `decoration_sagunja_nan.png` | `q_sagunja_nan` |
| `decoration_sagunja_juk.png` | `q_sagunja_juk` |

Still planned / missing from the 2026-06-01 batch:
`decoration_seokdeung.png`, `decoration_doldam.png`,
`decoration_sagunja_guk.png`, `decoration_seollal_flag.png`,
`decoration_chuseok_moon.png`, `decoration_hangeulday_plaque.png`,
`decoration_kite.png`.

---

## `assets/illustrations/mascot/` — Mascot widget pose PNGs

Recommended size: **512 × 512** RGBA, transparent background. Consumed
exclusively via [mascot.dart](../../lib/widgets/sori/mascot.dart) (do not
hard-code these paths in screens).

### Tiger (`MascotKind.tiger`) — [mascot.dart:90-101](../../lib/widgets/sori/mascot.dart#L90-L101)

| Filename | Emotion(s) mapped | Notes |
|---|---|---|
| `tiger_idle.png` | (animate cycle for `smile`, `neutral` — random idle frame) | base resting pose |
| `tiger_blink.png` | (animate cycle for `smile`, `neutral`, alias for `sleepy`) | eyes closed |
| `tiger_happy.png` | `surprised` | 2026-06-01 full-body moving happy pose, RGBA alpha |
| `tiger_celebrate.png` | `celebrate` | arms up / confetti |
| `tiger_sad.png` | `worry` | downturned mouth |
| `tiger_smile.png` | `smile` (default) | gentle smile, hero pose |
| `tiger_neutral.png` | `neutral` (default) | facing forward |
| `tiger_sleepy.png` | `sleepy` | dedicated drowsy pose (2026-05-28) |
| `tiger_thinking.png` | `thinking` | dedicated pondering pose (2026-05-28) |

### Magpie (`MascotKind.magpie`) — [mascot.dart:103-111](../../lib/widgets/sori/mascot.dart#L103-L111)

| Filename | Emotion(s) mapped | Notes |
|---|---|---|
| `magpie_perched.png` | `sleepy`, default idle | resting on branch |
| `magpie_wingup.png` | (animate cycle for `smile`/`neutral`/`thinking`/`surprised`) + FlyingMagpie | wing raised, refreshed 2026-06-01 |
| `magpie_wingdown.png` | (animate cycle, alternating with wingup) + FlyingMagpie | wing lowered, refreshed 2026-06-01 |
| `magpie_celebrate.png` | `celebrate` | wings spread |
| `magpie_perched_alt.png` | `worry` (mapped via `_magpieWorry`) | alt pose for fallback variety |

**Speaker → mascot kind mapping** (see `Mascot.forSpeaker`): `tiger` /
`horangi` / `호랑이` / `jieun` / `minsu` → tiger; `kkachi` / `magpie` /
`까치` → magpie. Unknown speaker → `null` (caller must `?? Mascot.tiger(...)`
to guarantee a widget).

---

## `assets/illustrations/stamps/` — dancheong stamp motifs

Imported from `~/Downloads/종가이미지` on 2026-06-01 and registered in
`pubspec.yaml`. These are RGBA alpha PNGs intended for future stamp/reward UI
slots. The existing [dancheong_stamp.dart](../../lib/widgets/sori/dancheong_stamp.dart)
widget can accept an `asset` when these are wired in.

| Filename | Motif | Status |
|---|---|---|
| `stamp_lotus.png` | Lotus | imported |
| `stamp_chrysanthemum.png` | Chrysanthemum | imported |
| `stamp_bamboo.png` | Bamboo | imported |
| `stamp_cloud.png` | Cloud scroll | imported |
| `stamp_geometric_octagon.png` | Octagon geometry | imported |
| `stamp_swastika.png` | Manji lattice | imported |

Still planned / missing from the current batch: `stamp_plum.png`,
`stamp_mountain.png`.

---

## `assets/stickers/` — collectible sticker extras

Imported from `~/Downloads/종가이미지` on 2026-06-01 and registered in
`pubspec.yaml`. These are RGBA alpha PNGs. No production UI currently consumes
this folder directly, so wire through a typed asset map before hard-coding
paths in screens.

| Filename | Category | Status |
|---|---|---|
| `dancheong_cloud.png` | Dancheong | imported |
| `dancheong_flower.png` | Dancheong | imported |
| `dancheong_hanji.png` | Dancheong | imported |
| `dancheong_star.png` | Dancheong | imported |
| `food_hotteok.png` | Food | imported |
| `food_kimbap.png` | Food | imported |
| `food_sikhye.png` | Food | imported |
| `food_tea.png` | Food | imported |
| `food_tteok.png` | Food | imported |
| `hangul_fighting.png` | Hangul | imported |
| `hangul_hh.png` | Hangul | imported |

Still planned / missing from the current batch: `dancheong_lantern.png`,
`hangul_heart.png`, `hangul_good.png`, `hangul_wow.png`, and
`stamp_sticker_*.png`.

---

## `assets/illustrations/scenes/` — scenario backdrops

Recommended size: **1024 × 1024** (or 4:3) RGB PNG. Used in three slots:

1. Full-screen at `Opacity(0.08)` behind the scenario player ([scenario_player_screen.dart](../../lib/screens/scenario_player_screen.dart) `_backdropKey`)
2. Sharper inside `_ScenarioIntroArt` (same file)
3. As the 44×44 / 56×56 list tile thumbnail in [scenarios_list_screen.dart](../../lib/screens/scenarios_list_screen.dart) `_ScenarioThumbnail`

Keyword → backdrop mapping is the single source of truth in
[scenario.dart `ScenarioBackdrop` extension](../../lib/models/scenario.dart). Both
consumers go through `scenario.backdropKey` — never duplicate the map.

| Filename | Mapped scenario keywords |
|---|---|
| `cafe.png` | `cafe`, `starbucks`, `introduce`, `encouragement`, `warm`, `couple`, `argument`, `plans`, `postpone`, `cancel` |
| `restaurant.png` | `bunshik`, `bunsik`, `tteokbokki`, `dinner`, `hoeshik` |
| `market.png` | `market`, `shopping`, `myeongdong`, `convenience`, `store`, `pharmacy` |
| `hotel.png` | `hotel` |
| `directions.png` | `directions`, `airport`, `arrival`, `taxi`, `subway`, `transfer`, `late` |

A scenario whose ID matches none of the keywords falls back to a tinted
accent gradient + emoji glyph in the list tile (and renders no backdrop in
the player). Phase 5 candidates for new backdrops: `hospital`, `office`,
`home`, `park`.

---

## `assets/illustrations/empty/` — empty-state illustrations

Recommended size: **800 × 800** RGBA. Each consumer wraps the asset in
[SoriEmptyState](../../lib/widgets/sori/empty_state.dart) or `Image.asset`
with an `errorBuilder` icon fallback.

| Filename | Slot purpose | Consumer | Fallback icon |
|---|---|---|---|
| `celebrate_complete.png` | Vocab — all due cards finished | [vocab_screen.dart:229-230](../../lib/screens/vocab_screen.dart#L229-L230) | `celebration_outlined` |
| `sleeping_tiger_b2.png` | Scenarios list — locked B2 level card | [scenarios_list_screen.dart:799-803](../../lib/screens/scenarios_list_screen.dart#L799-L803) | tiger_blink fallback |
| `studyroom_waiting.png` | Stats — first-time entry (no history yet) | [stats_screen.dart:50-51](../../lib/screens/stats_screen.dart#L50-L51) | `insights_outlined` |

---

## `assets/illustrations/error/` — error-state illustrations

Recommended size: **800 × 800** RGBA. Same fallback pattern as empty/.

| Filename | Slot purpose | Consumer | Fallback icon |
|---|---|---|---|
| `lost_magpie.png` | Scenarios list — load failure | [scenarios_list_screen.dart:81-82](../../lib/screens/scenarios_list_screen.dart#L81-L82) | `error_outline` |
| `offline_lantern.png` | Settings — offline / Firebase unavailable | [settings_screen.dart:405-406](../../lib/screens/settings_screen.dart#L405-L406) | `wifi_off_rounded` |

---

## `assets/icons/` — app launcher icon family

Generated via `flutter pub run flutter_launcher_icons` + sharp-cli (see
[CLAUDE.md](../../CLAUDE.md) "아이콘 재생성").

| Filename | Purpose |
|---|---|
| `HanLogo.png` | **Master 1024×1024** — single source for Android/iOS/web/Play Store icon |
| `icon-192.png` | pubspec-registered 192px buffer |

Derived (do not edit by hand): `web/icons/Icon-192.png`,
`web/icons/Icon-512.png`, Android `mipmap-*`, iOS `Assets.xcassets/AppIcon`.

**Play Store feature graphic** lives at `docs/store/feature_graphic.png`
(1024×500 final, 2:1). Composed from the new hanok-gate illustration +
"한글소리 / Hangul Sori / KOREANISCH LERNEN · KÖNIG SEJONG" text rendered
in 단청 녹청 (#1F7A6B) + 먹 (#0E1A18) + 황 (#C99A2E). Re-generate via the
Pillow recipe captured in commit history if the source art changes.

---

## Adding a new asset — quick playbook

1. Decide which folder it belongs to (header / hanok stage / decoration /
   stamp / sticker / mascot pose / scene / empty / error / icon).
2. Generate at the recommended dimensions above, save as PNG.
   Use Faceted Minhwa style (`HANGUL_SORI_STYLE_GUIDE.md`).
3. Drop into the matching folder under `assets/illustrations/...` or
   `assets/stickers/`. `pubspec.yaml` declares the current asset folders; add a
   new folder there if a future import creates another top-level asset path.
4. Wire it into the consumer screen. Prefer `HanokHeader(asset: ...)` for
   banners; `SoriEmptyState(asset: ...)` for empty/error.
5. Add a row to the table above (filename, slot, consumer file:line,
   fallback) so the next session can find it.
6. Run `flutter analyze` + `flutter test` — the smoke tests render every
   screen, so a busted asset path will surface immediately.
