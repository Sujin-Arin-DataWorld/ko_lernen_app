# Image-first design authority

Jin reaffirmed on 2026-11-04: generate app-screen mockups in the approved Hangul Sori style, obtain visual approval, fit editable Figma, then implement Flutter. Existing functional code is not visual design authority. Flutter-only layouts must not replace approved generated mockups.

The latest explicit approval authorizes the new Grammatik daily plan and all four Nuancen boards for Figma/native integration, followed by committing and pushing the task branch. It does not claim store publication or physical-device validation.

## Approved source images

| Image | SHA-256 |
|---|---|
| Grammatik daily plan v2 | 6facec09d27e9b4ff01873f4a301a4550d47c7bd8f41f0784a1a78c113c16129 |
| Nuancen 01 catalog/study | 7a3d6cfe0d572f57415f047c8a2e43f7248140ba2b557b200598f4300c539666 |
| Nuancen 02 quiz/feedback/result | 1fa296a16c64e0c3f7db4bbb2583f7319c232bbea8b82ec1d43b54d11697c9a1 |
| Nuancen 03 loading/empty/error | e85a38408a4643b7006d6423760feb502edd960ab6d1a90fe96e9e276147cf84 |
| Nuancen 04 reduced motion/speed/exit | a85617542d765d4591c842de3ed998023de2ade42a02f77433045b29d098628c |

Source folders: `C:/dev/hangulsori/_codex_artifacts/grammatik-c-complete-20261104/plan-image-revision` and `C:/dev/hangulsori/_codex_artifacts/nuancen-c-mockups-20261104`.

The earlier flat Figma plan at 104:160 was rejected. Its updated contents now follow approved v2; historical captures named figma-plan-setup.png are not authority.

## Editable implementation

[Figma Grammatik](https://www.figma.com/design/zhJY0ZY4gl4VNg8vaaNIXw?node-id=102-160) and [Figma Nuancen](https://www.figma.com/design/zhJY0ZY4gl4VNg8vaaNIXw?node-id=111-192) separate material art from editable text, controls and state variants. The plan is a full-screen modal; scrolling adapts to small or enlarged-text viewports. Nuancen uses its own knot/cord relationship composition.

Runtime material objects are independent blank assets. Whole app screenshots are not interactive screen backgrounds. Original cloud/settings/yeopjeon/home and existing Hören artwork remain independent canonical PNGs.

Nuancen preserves the learned/all-levels scope, four relationship groups, real corpus, TTS presets and result-close-to-list flow. Automatic advancement now waits for both 850 ms and owned speech completion; interruption yields an explicit next action. This fixes the old timing/lifecycle defect recorded by the source audit. Reduced motion uses manual continuation. Quiz practice does not invent persisted scores, rewards, or a save state.

## Motion and validation basis

Official material checked 2026-11-04: [Apple reduced motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria) and [Material motion](https://github.com/material-components/material-components-android/blob/master/docs/theming/Motion.md). Use brief event-driven pressure/selection changes, stable learning text, and background/route speech cancellation. Reduced motion retains the same results.

Next content is Alltagsszenen. Its mockups require separate visual review before native implementation. Approved Aussprache C2 and another worktree's existing implementation are preserved.
