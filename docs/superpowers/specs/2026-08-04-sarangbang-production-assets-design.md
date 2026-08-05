# Sarangbang Production Assets Design

## Goal

Replace the intentional P1 fallbacks with a coherent, production-quality
Sarangbang asset set while leaving the room-placement and reward contracts
unchanged. Remove the one harmless analyzer warning without changing mascot
selection behavior.

## Scope

1. Remove the unused _magpiePerched asset constant from
   lib/widgets/sori/mascot.dart. It is not selected by any current magpie
   emotion, so this is a zero-behavior warning fix.
2. Produce and integrate these nine assets:
   - assets/illustrations/hanok/sarangbang_empty.png
   - assets/illustrations/reward/reward_bojagi_closed.png
   - assets/illustrations/reward/reward_bojagi_open.png
   - assets/illustrations/decorations/decoration_munbangsau.png
   - assets/illustrations/decorations/decoration_seoan.png
   - assets/illustrations/decorations/decoration_chaekgado.png
   - assets/illustrations/decorations/decoration_jagae_mungap.png
   - assets/illustrations/decorations/decoration_gat_buchae.png
   - assets/illustrations/decorations/decoration_soban.png
3. Remove the three P1 fallback paths from data_integrity_test.dart and add
   the six decoration slugs to kAvailableDecorations.

## Visual Contract

Every image follows ASSET_GENERATION_BIBLE.md:

- Faceted Minhwa: angular colour planes, no drawn outlines, muted palette,
  subtle hanji grain, no watercolour wash, and no unrelated characters/text.
- The Sarangbang background is a 3:4 opaque interior in the existing
  left-alcove / upper-left peg-rail composition. It leaves the wall_back,
  floor_center, alcove_top, alcove_bottom, and peg_rail areas readable and
  contains no coloured slot markers.
- Closed and open bojagi are matching one-to-one transparent sprites. The
  closed sprite has one clear knot; the open sprite is an empty, unfolded
  bundle rather than a preview of a selectable reward.
- Decorations are true alpha cut-outs. Their categories remain fixed:
  chaekgado=wall; seoan, jagae_mungap, soban=floor; munbangsau=shelf;
  gat_buchae=peg.

## Generation and Processing

- Use existing hanok/gate.png and accepted decoration PNGs only as style
  references. Generate each deliverable separately so each has a deliberate
  silhouette and composition.
- Generate transparent-bound assets against a flat #00FF00 chroma-key
  background, then use the project-approved imagegen chroma-key process to
  produce RGBA PNGs. Never ship the source key colour or a white canvas.
- Run tool/decoration_normalize.py for the six decoration files. It trims,
  retains their natural aspect ratio, and applies the room renderer's
  established three-percent breathing room.
- Keep the background opaque and crop or resize it to the exact 3:4 aspect
  ratio without moving its architectural anchors.

## Acceptance Checks

1. Manual contact-sheet inspection at thumbnail and intended screen scale:
   no marker dots, checkerboard, white rectangle, visible chroma fringe,
   outline, text, or cross-style asset.
2. Alpha inspection: transparent corners and plausible opaque coverage for
   bojagi and all six decorations.
3. flutter analyze --no-pub has no remaining analyzer issue.
4. flutter test test/dancheong_stamp_test.dart
   test/decoration_slot_test.dart test/data_integrity_test.dart
   test/bojagi_screen_test.dart test/sarangbang_picker_test.dart
   test/room_layer_test.dart passes.
5. A screen-level smoke confirms the room renders its background, bundled
   fallback states use bojagi art, and each category is eligible only for its
   matching slot.

## Non-goals

- No changes to reward selection, journal recovery, storage, slot coordinates,
  translations, or animation behavior.
- No reuse of the rejected 2026-08-04 source download bundle.
- No generated mascot pose or unrelated UI redesign.
