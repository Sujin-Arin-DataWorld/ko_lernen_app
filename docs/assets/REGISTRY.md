# Asset Registry — Hangul Sori

> Single source of truth for which PNG fills which slot in the app.
> Generated 2026-05-28 (Phase 4). Refresh whenever a new `Image.asset(...)`
> or `HanokHeader(asset: ...)` call site is added.
>
> All consumer PNGs have an `errorBuilder` (or `HanokHeader` gradient
> fallback). A missing file degrades to icon/gradient — it does not crash.
>
> Stylistic baseline for **new** illustrations: see
> `~/Downloads/HANGUL_SORI_STYLE_GUIDE.md` (Faceted Minhwa).

---

## `assets/illustrations/hanok/` — module headers + intro gate parts

Recommended dimensions: **1200 × 360** (10:3 aspect) for header banners;
**1024 × 1024** for square/composable scene art. RGB PNG palette-quantized
where possible (see Phase 4 compression notes).

| Filename | Slot purpose | Aspect / size | Consumer | Fallback |
|---|---|---|---|---|
| `madang(light).png` | Light-mode home backdrop (Ken Burns) + scenarios list header | 4:3 photo-like | [home_screen.dart:93-96](../../lib/screens/home_screen.dart#L93-L96), [scenarios_list_screen.dart:117-118](../../lib/screens/scenarios_list_screen.dart#L117-L118), [intro_gate_screen.dart:120-121](../../lib/screens/intro_gate_screen.dart#L120-L121) | HanokHeader gradient + `travel_explore_outlined` |
| `madang(dark).png` | Dark-mode home backdrop (Ken Burns) | 4:3 photo-like | [home_screen.dart:93-96](../../lib/screens/home_screen.dart#L93-L96) | (Image.asset `errorBuilder` returns SizedBox) |
| `study_classroom.png` | Vocab module header | 10:3 banner | [vocab_screen.dart:279-280](../../lib/screens/vocab_screen.dart#L279-L280) | HanokHeader gradient + `menu_book_outlined` |
| `study_scholar.png` | Grammar + Settings header | 10:3 banner | [grammar_screen.dart:166-167](../../lib/screens/grammar_screen.dart#L166-L167), [settings_screen.dart:56-57](../../lib/screens/settings_screen.dart#L56-L57) | HanokHeader gradient + `auto_stories_outlined` |
| `calligraphy.png` | Hangul overview tab header | 10:3 banner | [hangul_screen.dart:87-88](../../lib/screens/hangul_screen.dart#L87-L88) | HanokHeader gradient + `draw_outlined` |
| `porch.png` | Chosung + Wordle + Kkeunmari header (shared, Phase 4b: split into unique art) | 10:3 banner | [chosung_quiz_screen.dart:286-287](../../lib/screens/chosung_quiz_screen.dart#L286-L287), [wordle_screen.dart:324-325](../../lib/screens/wordle_screen.dart#L324-L325), [kkeunmari_screen.dart:236-237](../../lib/screens/kkeunmari_screen.dart#L236-L237) | HanokHeader gradient + module-specific icon |
| `achievements.png` | Stats screen header | 10:3 banner | [stats_screen.dart:73-74](../../lib/screens/stats_screen.dart#L73-L74) | HanokHeader gradient + `bar_chart_rounded` |
| `listening_hero.png` | Listening screen header | 10:3 banner | [listening_screen.dart:167-168](../../lib/screens/listening_screen.dart#L167-L168) | HanokHeader gradient + `headphones_rounded` |
| `kkeunmari_hero.png` | Reserved for future Kkeunmari unique banner | 10:3 banner | _(unused, will replace porch.png)_ | — |
| `gate_frame.png` | Intro gate — outer 단청 frame layer | square 1024² | [gate_art.dart:21](../../lib/widgets/sori/hanok/gate_art.dart#L21) | painter fallback in GateArt |
| `gate_door_left.png` | Intro gate — left door (animated open) | half-frame | [gate_art.dart:22](../../lib/widgets/sori/hanok/gate_art.dart#L22) | painter fallback |
| `gate_door_right.png` | Intro gate — right door (animated open) | half-frame | [gate_art.dart:24](../../lib/widgets/sori/hanok/gate_art.dart#L24) | painter fallback |
| `gate.png` | Combined gate composite (homepage final-cta, unused in app currently) | 1024² | — | — |
| `welcome-hero.png` | Tiger+magpie hero composite (homepage mascot-strip; unused in app currently) | 1024² | — | — |
| `studyroom_wating.png` | (legacy / typo) — superseded by `empty/studyroom_waiting.png` | — | — | not referenced; safe to remove |

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
| `tiger_happy.png` | `surprised` | wide eyes |
| `tiger_celebrate.png` | `celebrate` | arms up / confetti |
| `tiger_sad.png` | `worry` | downturned mouth |
| `tiger_smile.png` | `smile` (default) | gentle smile, hero pose |
| `tiger_neutral.png` | `neutral` (default), alias for `thinking` | facing forward |

### Magpie (`MascotKind.magpie`) — [mascot.dart:103-111](../../lib/widgets/sori/mascot.dart#L103-L111)

| Filename | Emotion(s) mapped | Notes |
|---|---|---|
| `magpie_perched.png` | `sleepy`, default idle | resting on branch |
| `magpie_wingup.png` | (animate cycle for `smile`/`neutral`/`thinking`/`surprised`) + FlyingMagpie | wing raised |
| `magpie_wingdown.png` | (animate cycle, alternating with wingup) + FlyingMagpie | wing lowered |
| `magpie_celebrate.png` | `celebrate` | wings spread |
| `magpie_perched_alt.png` | `worry` (mapped via `_magpieWorry`) | alt pose for fallback variety |

**Speaker → mascot kind mapping** (see `Mascot.forSpeaker`): `tiger` /
`horangi` / `호랑이` / `jieun` / `minsu` → tiger; `kkachi` / `magpie` /
`까치` → magpie. Unknown speaker → `null` (caller must `?? Mascot.tiger(...)`
to guarantee a widget).

---

## `assets/illustrations/scenes/` — scenario backdrops

Recommended size: **1024 × 1024** (or 4:3) RGB PNG. Rendered at
`Opacity(0.08)` behind the scenario player ([scenario_player_screen.dart:1039-1051](../../lib/screens/scenario_player_screen.dart#L1039-L1051))
and again sharper inside `_ScenarioIntroArt` ([scenario_player_screen.dart:1131-1146](../../lib/screens/scenario_player_screen.dart#L1131-L1146)).

| Filename | Mapped scenario keywords | Source |
|---|---|---|
| `cafe.png` | `cafe`, `starbucks`, `introduce`, `encouragement`, `warm`, `couple`, `argument` | [scenario_player_screen.dart:80-108](../../lib/screens/scenario_player_screen.dart#L80-L108) |
| `restaurant.png` | `bunshik`, `bunsik`, `tteokbokki`, `dinner`, `hoeshik` | same |
| `market.png` | `market`, `shopping`, `myeongdong`, `convenience`, `store`, `pharmacy` | same |
| `hotel.png` | `hotel` | same |
| `directions.png` | `directions`, `airport`, `arrival`, `taxi`, `subway`, `transfer` | same |

A scenario whose ID matches none of the keywords renders no backdrop
(returns `null` from `_backdropKey`). Phase 5 candidates for new backdrops:
`hospital`, `office`, `home`, `park`.

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
`web/icons/Icon-512.png`, Android `mipmap-*`, iOS `Assets.xcassets/AppIcon`,
`docs/store/feature_graphic_v1_draft.png`.

---

## Adding a new asset — quick playbook

1. Decide which folder it belongs to (header / mascot pose / scene / empty
   / error / icon).
2. Generate at the recommended dimensions above, save as PNG.
   Use Faceted Minhwa style (`HANGUL_SORI_STYLE_GUIDE.md`).
3. Drop into the matching folder under `assets/illustrations/...`.
   `pubspec.yaml` already declares all 5 illustration subfolders + `icons/`
   — no manifest edit needed.
4. Wire it into the consumer screen. Prefer `HanokHeader(asset: ...)` for
   banners; `SoriEmptyState(asset: ...)` for empty/error.
5. Add a row to the table above (filename, slot, consumer file:line,
   fallback) so the next session can find it.
6. Run `flutter analyze` + `flutter test` — the smoke tests render every
   screen, so a busted asset path will surface immediately.
