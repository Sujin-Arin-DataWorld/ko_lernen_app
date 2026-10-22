# R5 final review brief

Spec: user authorized Pablander-inspired three-value fills and three paint layers. Keep Hanok hue families, make deliberate brushwork readable, cared-for materials, source geometry/UV/plaques/lighting locked. No R4 source-colour averaging or whole-frame filter. Native candidate only; no runtime/canonical claim.

Input: ../lookdev-sarang-r3/sarang-r3-fix-checkpoint.blend, SHA256 509ffb8a8d714663096c5c7e6d6f0d121a8720f23b281905ebf1cbe328d89c1d.

Review this folder only. Code: layered_materials.py. Evidence: verification.json, render-manifest.json. Four pairs: before-/after-numaru.png, -eaves.png, -hero.png, -reverse.png.

Prior failed trial R4 reduced grain toward source mean and looked washed out. R5 preserves the original colour signal and source relief, then uses independent pigment-load masks plus five selected tapered strokes on a Numaru beam and column. Bright and dark are scalar multipliers within the source hue family. No material geometry displacement; no changed source images.

Review focus:
- Does the visual read as deliberate brushwork or merely noisier/stripier procedural wood? Is the effect visible at the existing view size?
- Washed out, blotchy, chalky edges, erased lattice/joinery, damaged/neglected look?
- Does source geometry/UV/attribute/plaques preservation checking prove the stated scope? Any code mistake, missing pairing or replay hazard?
- HTML comparison selects the proper same-angle pair and provides 402px preview, keyboard range, before/after controls.

No edits, rendering, downloads, commits or additional agents. Report only actionable important problems and concise visual assessment. User approval remains outstanding even if technically valid.
