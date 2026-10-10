# C reward movie production brief

## Decision

For a final scene that keeps the large, sharp actor of the user-selected C mockup AND preserves the complete uncropped movie frame, produce a new framed performance. The current making_money.mp4 remains useful as an acting/timing prototype. It is not rejected or overwritten.

Live source:960×960,24fps,121frames,5.0417s; SHA2566e850b717ec285fd1d9be057da361fed629c178e750a15c77b592cbda6f91ff5. Source start, preparation, money-burst and end frames were compared with C. Costume/headband/club identity continues, but the source uses softer diffuse lighting and includes blurred coins/blue shards in the actor clip. At336dp full-frame containment, the visible actor/club occupies roughly233dp, versus about344dp in the C poster. These are visual measurements; native layout/device behavior is not approved by them.

The color-preserving native conversion report records visible RGB delta0 across121frames, and its source hash matches the current MP4. Motion blur at the money burst is visible in source-frame-090.png from the original MP4 itself. It was not created by grayscale or alpha-only conversion.

## New master requirements

- Use the selected C character identity: same face, hair, flower headband, white sleeves, patterned red/teal vest, blue waist ties, teal trousers, straw sandals and carved wooden club. Do not invent horns or a different guardian.
- A portrait hero composition, approximately3:4 (e.g.1080×1440) at30fps for4–5seconds is a production target. The later approved stage bounds determine the exact final export ratio.
- Transparent alpha, with character, club tip, both feet and all emitted artwork remaining inside the frame for every frame. Meaningful safe padding10–12%; avoid the source's large empty borders.
- Render the actor close enough to fill most of the hero height. Fixed camera, no camera shake, no unrequested zoom/crop; retain consistent size and contact plane.
- Match C's material sharpness and upper-left warm lighting. Preserve cloth/skin/brass colors. A subtle cool rim can be authored locally; never apply a gray/cyan filter to the whole performance.
- Prefer separate outputs: actor/club performance; gold square-hole Yeopjeon emission; blue Dokkaebi fire; contact-shadow pass; one clean end poster. This lets the app synchronize reward numbers without embedding text in a movie.
- Use the supplied authentic coin_face asset as currency reference, including square hole and brass relief. The master has NO labels, balances, CTA, app background, logo or system status bar.
- Deliver an editing master as alpha PNG frame sequence or ProRes4444-with-alpha plus a reference playback. Runtime formats are derived and tested for each target; the production master is not a claim of direct Flutter codec support.

Apple's ProRes white paper describes4444 alpha support: https://www.apple.com/support/assets/docs/products/finalcutpro/Apple_ProRes_June_2014.pdf

## Suggested acting sequence

0–0.6s: anticipation and friendly eye contact.
0.6–1.5s: club swing, body follows with grounded feet.
~1.5s: one identifiable reward-burst cue.
1.5–2.5s: finite coins and blue fire, clear smiling face.
2.5–4.5s: settle into the selected raised-club pose and hold a clean final beat.

Record the actual cue timestamp/frame in export metadata. The old clip's3.583s cue must not be blindly reused for a new movie.

## App-side animation

The movie supplies body/face/club acting. Separate Flutter layers supply coin sprites, one blue flame, actual numeric text, hanji card and tactile CTA. Use a shared AnimationController for synchronized numeric/stagger timing; isolate expensive static art where profiling demonstrates benefit. Official Flutter references:
- https://docs.flutter.dev/ui/animations/staggered-animations
- https://docs.flutter.dev/perf/ui-performance

On an actual positive confirmed receipt, roll earned0→receipt amount and walletBefore→walletAfter on one840ms clock at the actual movie cue, followed by200ms settle. Several claim kinds can sum in one receipt;20 is just the selected C sample. Do not add a second coin shower over a source movie that already has it baked in.

The wallet's new single blue flame can respond once on entrance/touch for500–620ms with2–3dp drift and a restrained light pulse, then rest. Existing wallet70/earned70/spent0/cost40 stay unchanged. This does not create a reward or count-up.

Use coin_face or properly authored multi-angle/3D sprites for local coin rotation. A whole flattened UI PNG cannot independently animate arms, face, numbers or coins. Do not shake the full screenshot, fake a facial rig from a single bitmap, or animate every surface simultaneously.

Reduced motion settles confirmed numeric values, shows the final actor/poster and suppresses decorative travel/rotation. Off-screen/background and navigation cancel visual work and never reissue grants. Actual save/receipt ownership and immediate actions remain intact.

## Copy-ready video prompt

Use the approved Hangul Sori C-design Dokkaebi as the sole character identity reference. Create a4–5second portrait3:4,30fps character performance on a genuinely transparent background. Keep the same face, hair, flower headband, white sleeves, red-and-teal patterned vest, teal trousers, blue waist ties, straw sandals and carved wooden club. No horns, no costume/face changes. Fixed camera, close framing with full body and entire club always visible,10–12% safe padding. Warm upper-left key light, detailed materials and a subtle local cool rim; natural saturated colors.

He looks at the viewer, anticipates, swings the club with a grounded body motion, then smiles and settles into the approved raised-club pose. Keep the feet stable on one contact plane, no body sliding. Output the actor/club performance as a clean layer WITHOUT money or magic; export the square-hole brass Yeopjeon shower and ONE blue Dokkaebi-fire effect as separate passes if possible. No UI text, plus signs, balances, logo, cards, buttons, camera movement, white backdrop, crop or effects covering the face. Provide a clean final poster, transparent master frames and the exact reward-burst cue frame.

