# Approved Sarangchae: sixteen construction lessons in the live learning flow

Status: implementation authorized by Jin on 2026-09-14 with approval of the sixteen-stage mockup, runtime promotion, replacement of other Sarangchae artwork, and main merge.

## Visual and learning contract

The sixteen approved PNGs are the only current Sarangchae construction artwork. Their camera, geometry, room depth, roof junction, outer eave supports and materials remain as approved. Stage 16 has SHA-256 `f917724120d4080d7c004b65dc51a9c336fcfbccdb9997e830de06ead1bcfc1a`. Display uses the complete image with contain sizing and no color filter. This is a single authored view; old eight-direction artwork must not appear when a learner inspects the new building.

The stages remain: site, stone base, foundation stones, fitting timber to stone, posts, beams, purlins and ridge, rafters, roof underlayer, earth roof bed, tiles, walls, ondol, wooden floors and railing, lattice doors, completed house with both plaques. The four chapters and Korean, English and German lessons come from the approved mockup. Concealed ondol and roof structures are explained as principles, without claiming a measured reconstruction.

## Earned progress

Use the existing durable `HanokCompetenceProjection.completedUnitCount` as the authority. Clamp its value to 0–16. Zero means no earned construction stage; a completed learning unit reveals one stage. Replaying a completed unit, placement bypass, onboarding practice, viewing the house and reading its explanation never award another stage. Sixteen or more completed units reveal the exact approved final image. Existing users retain their completed units without a new counter or destructive migration.

The decoration quests retain their current Bojagi reward contract. The new construction reveal appears in the existing learning activity return receipt only when the durable unit count increases. If several stages are earned together, the receipt identifies the range and lets the learner inspect the gained steps. No second XP or item award is created by the reveal.

## Delivery of the lesson

The Hanok tab and `/hanok` routes show the learner's earned stage, a Korean construction term, a concise localized insight and progress out of sixteen. A chapter/stage history makes earned lessons available again. Unbuilt stages are clearly distinguished from earned progress.

After a qualifying learning activity, the reward receipt shows the before/after building change, the new stage number, Korean term and one sentence explaining what changed. Longer explanation is optional. The learner can continue without an additional quiz or waiting through a compulsory animation. Reduced motion, 320-pixel layouts, large text and KO/EN/DE must remain usable.

## Asset replacement and release

Runtime originals live in `assets/illustrations/personal_hanok_v3/sarangchae/`; `assets/data/sarangchae_construction_v3.json` supplies ordered artwork and localized lessons. The mockup points to these same bytes. Superseded isolated Sarangchae artwork is removed after checking references. Ansarangchae, Sarangbang room artwork, other buildings and concurrent work are outside that deletion scope. Historical provenance may retain hashes and retired filenames, never an active runtime pointer to deleted art.

Merge requires catalog hash checks, projection/receipt tests, relevant existing widget and inventory guards, actual rendered desktop/mobile inspection, PR checks and the merged main checks. Release evidence must distinguish bundled runtime functionality from an uploaded store build. The existing approved mockup URL must continue working while its server is in use.
