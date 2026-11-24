# Next Spiele candidate: Wortkette / 끝말잇기

Date: 2026-11-04. Scope: three image-generation proposals only. No app source, Figma, native interaction or physical-device work.

Latest presentation revision: `wortkette-a-five-tabs-candidate.png`, `wortkette-b-five-tabs-candidate.png`, `wortkette-c-five-tabs-candidate.png`. These supersede the earlier blank-dock PNGs for user review. The final images show the full five-tab navigation, with Spiele selected, using approved screenshot/source PNG references. Their generated navigation drawings are **visual mockup glyphs, not byte-exact canonical assets**. See `FIVE_TAB_MANIFEST.json` and the final revision in `CANDIDATE_REVIEW.md`.

## Selection and distinct interaction

The next review set develops the existing Kkeunmari word-chain game, not another selection or flip-card layout. A learner reads the current word, identifies its last syllable, types a new Korean word beginning with that syllable, and submits. The opponent then supplies the next word. The visual proposal is a shallow wooden word-chain workbench with fixed syllable blocks and an inset typing trough; these blocks are information, not draggable controls.

The 2026-10-18 historical preview plan already mentions Kkeunmari. This set is a new short/medium/long-content treatment after Karten, not a claim that the game or all its mockups were previously absent.

## Current primary sources

Checkout: `C:/dev/hangulsori/ko_lernen_app_worktrees/quiz-matching-figma-20261104`.
Observed HEAD at investigation: `d14668e907705e312a8c8633182c3e9deff6d5aa`.

- `lib/screens/kkeunmari_screen.dart:281`: initial chain contains the selected starting word; user starts; time resets to the configured turn limit.
- `lib/screens/kkeunmari_screen.dart:431`: validate typed word, required first syllable, and used words; online dictionary is consulted only when needed.
- `lib/screens/kkeunmari_screen.dart:539`: a valid answer stops the clock, persists applicable study evidence, appends the actual word, and enters the opponent turn; no invented XP or completion state.
- `lib/screens/kkeunmari_screen.dart:607`: opponent selects a valid next word, appends it, and starts the next user turn.
- `lib/screens/kkeunmari_screen.dart:760`: title, leave/home recovery and TTS speed action.
- `lib/screens/kkeunmari_screen.dart:835`: current word, actual meaning, audio, required syllable, Korean input (20-character limit), and Senden action.
- `lib/screens/kkeunmari_screen.dart:972`: scrollable actual chain, not a fixed three-word maximum.
- `lib/screens/kkeunmari_screen.dart:1105`: each syllable displayed separately; final syllable emphasized; actual German gloss and a 48dp audio control.
- `lib/services/kkeunmari_engine.dart`: pool validation and legal chain transitions. A/B/C are review fixtures, not CEFR selector labels.
- `assets/data/kkeunmari_pool.json`: all visible Korean words and German meanings below.
- `lib/l10n/app_de.arb`: Wortkette; Letzte Silbe → nächstes Wort; Du bist dran; Beginne mit »{syl}«; Wort auf Koreanisch …; Senden; Kette: {n}; {n}s.
- Historical scope: `C:/dev/hangulsori/ko_lernen_app_worktrees/spiele-figma-first-20261018/docs/design/spiele-figma-first-20261018/EINLEITUNG_VORSCHAU_SCOPE_PLAN.md`.

## Deterministic content snapshots

All three show the user turn. These are authored review fixtures using actual source vocabulary and legal transitions, not a real learner's history, scores or elapsed-time evidence. No rewards, lesson progress or completion badges are shown.

| Fixture | Visible chain | Current word and exact gloss | Required syllable | Draft in input | Snapshot timer/count |
|---|---|---|---|---|---|
| A short | 가방 | 가방 · Tasche | 방 | empty; placeholder Wort auf Koreanisch … | 30s / Kette: 1 |
| B medium | 커피 → 피자 → 자전거 | 자전거 · Fahrrad | 거 | 거울 | 24s / Kette: 3 |
| C long | 운동 → 동의 → 의사결정권 | 의사결정권 · Entscheidungsrecht | 권 | 권리 | 18s / Kette: 3 |

Exact source levels: 가방 A1; 커피 A1; 피자 A1; 자전거 A2; 거울 A1; 운동 A1; 동의 A1; 의사결정권 C2; 권리 A1. Do not relabel A/B/C as difficulty levels. Current screen loads the full pool when no selected-word source is supplied. Each chain has unique words, and adjacent last/first syllables match. Typed B/C drafts are not yet appended to their chain count.

The pool has no separate record-ID field: the `word` string is the source key. Exact zero-based record locators in the hashed pool are: 가방 `words[296]`; 커피 `words[191]`; 피자 `words[666]`; 자전거 `words[2455]`; 거울 `words[758]`; 운동 `words[834]`; 동의 `words[1145]`; 의사결정권 `words[2594]`; 권리 `words[1383]`. A/B/C mean **short/medium/long current-word length** (2/3/5 syllables), not A1/B1/C1 or complete CEFR coverage. Only these three specific fixtures were verified.

## Controls and follow-through

- Back/leave; current-word audio; TTS speed (1× shown); Korean text input; Senden; five-tab navigation visible in the final image proposals. Exact original PNG composition remains required in Figma/runtime.
- No answer choices, matching columns, flip gestures, correctness self-ratings, fake hint buttons, automatic answer display, draggable word blocks, or invented settings.
- Preserve checking, dictionary-unavailable, invalid/duplicate word, opponent-thinking, timeout, dead-end, result and persistence-recovery states in later design/implementation. The opponent state replaces the input controls, as the source does.
- Keyboard is dismissed for the full-content review snapshots. Current runtime autofocus and keyboard-inset behavior require their own later Figma/native variant; these PNGs are not proof that a keyboard and every control fit simultaneously.
- At nominal 402×874, reserve 82dp at the bottom for the approved shared navigation. Preserve at least 16dp between the lowest interactive face/shadow and that dock. Native touch regions must be at least 48dp; text scaling, semantics, focus, reduced motion and insets remain unproven by images.

## Material and canonical ownership

Reference: `C:/dev/hangulsori/_codex_artifacts/spiele-quiz-matching-figma-20261103/quiz-a-figma-v3.png` supplies the approved emerald, hanji, restrained warm gold, depth and typography hierarchy. The new layout is a chain workbench, not a copy of the Quiz answer stack or Karten card holder.

The initial candidates reserved a blank bottom dock; that presentation was superseded because five tabs must remain visible in mockups. The final three imagegen edits show the approved Wörter-Quiz icon designs in this exact order: `nav_heute.png`, `nav_open_book.png`, `nav_spiele.png` (selected), `nav_hanok.png`, `nav_gye.png`, under `assets/illustrations/approved_games/`. The actual PNG files and approved screenshot were visually inspected and used as generation references. The resulting glyphs are not substitutes for original assets: later Figma/runtime composition must use the exact PNG bytes, not crops from these generated screens. The optional cloud was not generated or redrawn.

Related runtime distinction, checked against current source: the earlier “Meine Wörter Karten” mockup refers to route `/custom_pack/play`, screen `CustomPackPlayScreen`, not the `/my_words` search hub `MyWordsScreen`. Current `lib/screens/custom_pack_play_screen.dart:428` uses shared `ApprovedGameNavigation`. `docs/design/karten_navigation_20261104/PROVENANCE.json` records its original navigation assets and front/back footer captures. This review independently verified all four supplied canonical source PNG hashes against their runtime copies and the retained open-book hash. That document records a null RGB difference bounding box for front/back footer rectangle `[0,792,402,874]`; the image agent did not rerun those runtime captures. This runtime evidence is separate from generated Wortkette proposals and from physical-device QA.

`C:/Users/vjinn/.codex/generated_images/공통UI정본/CANONICAL_UI.json` requires exact common-UI bytes. Cloud SHA-256: `c728baced6dd3bff2729bf2a28dbf62e3954ad91a04594e04dc923fbd530f6a5`; settings gear: `bee0e7a48115fe34c1a1a6f3fba17d022c0bd978470004ae5e92a2bf378c068d`; yeopjeon: `c187032485925a52d6a6148fdeea11382a95648f0c37eecdfd1cd5654959f40f`. They are not redrawn in this candidate set. No new character portrait is generated. Later opponent-state design must use the actual selected companion media and preserve companion-off behavior.

## Applied review guidance

Read and applied imagegen (including prompting reference), mobile-app-ui, ux-audit-critique, accessibility and critique-typography skills. Decisions: action-aligned material grouping, readable Korean syllable sequence and German gloss, a single clear submit action, no counterfeit canonical graphics, and explicit image-only proof boundaries.

Official references checked 2026-11-04: https://developer.android.com/guide/topics/ui/accessibility/apps (48dp targets, contrast and semantics), https://design.google/library/expressive-material-design-google-research (expression to support hierarchy/action, not gratuitous decoration). These source principles are translated into Hangul Sori's already-approved material identity; they do not authorize replacing its assets.

Apple official HIG also checked live on 2026-11-04: https://developer.apple.com/design/human-interface-guidelines/accessibility and https://developer.apple.com/design/human-interface-guidelines/motion . Their official `.md` representations were read because the HTML requires JavaScript. Applied design decisions: large-text adaptability remains a separate requirement; contrast and feedback cannot rely solely on color/audio; later press/turn feedback should be brief, purposeful and optional with Reduce Motion. These PNGs do not demonstrate any motion or accessibility implementation. The Google official Material 3 Expressive research article above was read live; the separate M3 states overview was JavaScript-only and is not used as evidence for unobserved page contents. Check date is not a claim that these articles were first published in 2026.
