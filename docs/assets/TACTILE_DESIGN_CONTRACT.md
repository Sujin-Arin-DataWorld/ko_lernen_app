# Hangul Sori tactile illustration and interaction contract

Approved scope: bright native Flutter UI, existing NotoSansKR typography, five
root tabs, all 13 learning activities, eight games and the authored Packs.
Art provenance and SHA-256 values are in `TACTILE_UI_ASSETS.json`.

## Materials and illustration

Keep actual object detail: mineral-speckled glaze, linen weave, wood pores,
pitted brass, carved-stone relief, feather structure and horsehair. Use broad
upper-left soft lighting and modest contact shadows. Do not blur, smooth,
repaint or recompress the approved PNGs. Do not add grain over unrelated
original Hanok or card art. No plastic, jelly, gummy limbs or toy-like guardians.

Tiger retains mature proportions, muscular chest, forceful paws and sober
gaze. Magpie remains upright in its gat with readable black-white feathers.
Haechi has a weighty seated body and carved-stone relief. Hahoe is a standalone
wooden Yangban mask with a separate jaw, visible grain and gently carved curves;
it has no wearer, body or speaking persona. Dokkaebi follows the newly approved
soft persona references: small dark oval eyes, a simple adult smile, rounded
matte skin, textured hair, linen and a wooden bangmangi. Keep wood grain on the
club, not the face or hands. Fine material texture and broad soft light connect
the figure and mask without forcing every material into carved wood. This is
an original modern folk-spirit interpretation. Its requested identity details
are exactly two small textured forehead horns, subtly blue-grey small oval eyes,
a Dancheong-embroidered linen headband and circular brushed-gold hoop earrings.
Do not add more horns, fangs, a scary
expression or tiger-skin costume. Reference bytes and exact prompts are preserved in
`TACTILE_CULTURAL_PROMPTS.json`; the earlier faceted performer is archived.

Sujin, Christian, Dongsun, Byeongcheol and Jun appear only when the real scenario
names them. Show a single small participant group in the introduction; do not
repeat full portraits in every speech bubble. `speaker:user`, the learner's
assigned role and the speaker's voice are resolved by the existing scenario
contract. Jun follows the reviewed 16-year-old, first-year high-school proposal. His
parents and male voice remain the same; no university/workplace role is added.

## Cultural roles and density

| Character | Personality and relationship | Current appearance |
|---|---|---|
| Tiger | Proud, loyal, competitive; Magpie's friendly rival | Small home greeting and existing selected-mascot slots |
| Magpie | Quick observer who checks Tiger's eagerness | Existing selected-mascot slots; gentle movement |
| Haechi | Steady mediator with quiet humour | One compact result comment |
| Hahoe mask | Wooden cultural object, no dialogue identity | Smalltalk introduction beside a neutral hint about tone and context |
| Dokkaebi | Curious, playful and warm | Compact puzzle introduction |

A culture figure is 64 by 88 logical pixels and the mask object is 64 by 64,
both with readable text. The mask does not appear in generic cloze practice.
A culture comment is never a
new reward, opponent, selectable role or substitute for the actual dialogue
partner. The small commentary uses directly written Korean with English and
German meaning, without transliteration or literal word-for-word copy.

## Layout and colour

Use existing Sori colour/radius/type tokens. Background remains bright hanji;
focal learning surfaces use green `#247567`, principal contrast actions use
warm gold `#F5CF78`, and Bojagi uses pale blue `#DFEBF3`. Primary titles are
26 logical pixels with 1.3 line height. Normal body and German action labels
retain NotoSansKR and reflow naturally at large system text sizes.

Object-led filled actions are at least 64 high, ordinary primary actions keep
their established 56-pixel minimum, and secondary/small actions are at least
48. Use 8/12/16/24 spacing from the existing tokens. The first catalog area
has four image-first shortcuts in two columns; it becomes one column at large
text sizes or below 260 available pixels. Full descriptions and category
navigation remain below. All art is contained without silhouette cropping;
4:3 card content stays recognisable in the existing 16:10 display slot.

## State and motion

Desktop hover and keyboard focus raise a surface by 2 pixels. Touch contact
starts pressure immediately; release restores it, and scrolling/cancellation
never launches an action. Filled CTA depth is 4 pixels and pressure scale .99.
Actions run on the accepted tap, without waiting for their release animation.
Focus retains the existing contrast ring. Small speech controls switch between
the actual resolving, speaking and idle states; no fake sound or completion
animation is used. Reward art appears only for an observed receipt.

Reduce Motion removes translation, scaling and animated icon transitions while
retaining state information, touch targets, focus and keyboard activation.
The guardian has no exaggerated jump, jelly deformation or baby-like pose.

## Catalog history

Recommendations are device-local presentation history. Only accepted routes
count; visits, Details and cancelled taps award no course, XP or coin progress.
Events retain at most 90 days/1,400 entries, use a 28-day frequency window with
seven-day half-life, cap each activity's daily contribution at three, and
deduplicate launches within 30 seconds. Four positions remain fixed for a
local calendar day. Unused content can appear after three spaced visits, at
most once daily; dismissal hides it for seven days. Account UID, local-data
lifetime and the existing catalog queue fence asynchronous mutations. A
foreign/stale account's history is never used to populate another account.
