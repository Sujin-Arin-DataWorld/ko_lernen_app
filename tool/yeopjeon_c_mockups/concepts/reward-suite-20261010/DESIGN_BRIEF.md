# C-selected reward suite — 2026-10-10

The user selected C-spatial-jade-de.png as the visual direction, then requested other Yeopjeon reward mockups. This suite extends that selection with four non-Dokkaebi screens in German and English. It is static design exploration. Existing Flutter/HTML implementation and original movie are kept.

## Source-grounded screen data

| Screen | Confirmed or proposed state | Review fixture | Main action |
|---|---|---|---|
| Second lesson receipt | Confirmed new daily completion claim | wallet20 + daily second10 =30; eligible0/owned0 | Keep learning |
| Construction milestone receipt | Confirmed newly reconciled milestone claim | wallet30 + milestone40 =70; eligible1/owned0 | Visit Ildu house |
| Wallet summary | Proposed read-only summary derived from the existing wallet model | earned70, spent0, balance70; eligible1/owned0 | Visit Ildu house |
| Construction confirmation | Pre-spend confirmation of an eligible step | current70, cost40, expected remainder30; eligible1/owned0 | Build for40 |

These fixtures form a valid example ledger, not a guarantee that every second lesson unlocks construction. A later confirmed course completion can reconcile a milestone after both daily completion bonuses have already been received. A single actual receipt may instead combine daily and milestone awards; its displayed amount must be the sum of its actual newly added claim entries. In screen01, Gesammelt30 is the cumulative confirmed claim sum, while the header30 is the current wallet balance; these happen to match because no construction has been paid for. Never bind the cumulative label to a later remaining balance.

Source anchors:
- lib/services/yeopjeon_service.dart:603–636: first verified daily completion20, second10, subsequent daily completion0; verified completion/source deduplication.
- lib/services/yeopjeon_service.dart:493–522: each newly eligible construction stage creates its own milestone claim40.
- lib/models/yeopjeon_wallet.dart:31,271–287,304–309: next construction cost40; all eligibility grants and earned−spent=balance are validated.
- lib/services/yeopjeon_service.dart:351 onward: buildNext checks eligibility and funds, writes the next owned stage and subtracts40.
- lib/services/sori_stage_reward_receipt_service.dart:128 onward: new positive wallet claims become Yeopjeon receipt items. XP, quest progress and Dancheong rewards remain separate kinds.
- lib/widgets/sori/yeopjeon_wallet_card.dart: header wallet badge currently opens /rewards/ildu-house. The independent wallet summary is a new proposal, not an existing shipped route.
- lib/services/yeopjeon_service.dart:299–348: due-review10 requires trusted verification; no current UI caller was found. This suite does not present it as an active reward flow.

A valid eligibility1/owned0 wallet cannot have only30 funds under this model: the unbuilt stage's40 grant remains in the balance. Consequently, the second-lesson fixture shows learning-based access rather than a false ready check or a promise that10 more coins alone unlocks construction.

## Shared visual and layout contract

The selected C image is a material/component reference: deep jade lacquer, shallow relief clouds, warm hanji, aged brass, consistent upper-left key light, large dimensional amounts, one paper information card and bottom gold/jade actions. The actual square-hole coin_face.png and yupjeon.png assets guide the currency imagery.

Target402×874 logical viewport at100% text. System area0–62, brand/wallet66–112, title124–184, main scene196–702, primary714–770, secondary778–826, bottom safe area840–874. Target geometry is a later implementation contract, not proof that generated raster typography has exact native coordinates. Preview frames are measured separately.

The two receipts carry the visual emphasis and finite reward effects. Wallet and construction are calmer, with no plus sign or fake new reward. No future Hanok art, stages, roof silhouettes, blueprint, fabric cover, chest or fixed Sarangchae label appears.

## Skill application and cross-review

- ui-ux-designer / high-fidelity-mockups: one focal scene per screen, realistic copy, a material family inherited from the user-selected C.
- user-flows / information-architecture: separate receipt, stored balance and pre-spend confirmation; verified actual award sources before choosing sample figures.
- mobile-app-ui / layout-grid-hierarchy: one-screen target, small related gaps, safe areas, low48dp-or-greater actions with a reserved arrow zone.
- design-system-builder / ui-styling: shared jade/hanji/brass components, upper-left illumination, material thickness and consistent pressed-state contract.
- motion-patterns / motion-media review: receipt-owned count-up, static wallet, durable-write-owned build result, reduced-motion and lifecycle exits.
- ux-audit-critique / accessibility-audit: source/copy, state meaning, CTA internal collision and localized text checks. Raster inspection cannot prove semantic accessibility or native Dynamic Type behavior.

Three existing designer agents review source/visual direction, mobile layout/accessibility and motion/media. The built-in image_gen tool creates each screen and localization independently; exact prompts are saved alongside the images. Project copies preserve generated bytes. Original video colors, complete movie canvas and current runtime files are not changed.

## State variants for implementation

NoReward/daily cap and already-claimed states show the confirmed current balance and honest learning completion without +0 celebration. A daily-capped completion still consumes its source identity; do not promise that repeating the same completed lesson tomorrow earns coins. Pending/error states show the last known balance and retry/status copy; no unsupported credited amount or readiness. unknown means unresolved storage outcome, not proof of zero credited funds. Build failure retains the original balance, permits retry and never displays a completed spend. A saving state is transient; only durable built success may settle70→30 and show a saved receipt. In the current runtime, positive receipts route to /rewards/yeopjeon; first daily grants show the original movie, other positive grants use a coin scene. Failure/duplicate/zero statuses are not separate reward-screen routes.

Normal100% text is the single-screen composition. Actual large-text accessibility is separate QA and may adapt by scrolling; do not shrink text to fake compliance.

