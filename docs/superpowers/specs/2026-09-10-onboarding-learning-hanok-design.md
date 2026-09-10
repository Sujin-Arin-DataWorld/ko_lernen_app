# Korean learning and Hanok growth onboarding

The user approved implementation, commit, push and merge on 2026-09-10 after reviewing the connected seven-screen proposal. This replaces the disconnected feature demonstrations and the earlier decision to replace the choose-video gestures.

## Experience

The promise is that growing Korean ability leaves a visible record in the learner's Hanok. The demonstration follows one Korean word, `문` (door), from assembly through sound, recall, a growth demonstration and Korean architectural context.

1. Invite the learner to see the Hanok that can grow alongside Korean learning.
2. Assemble `ㅁ + ㅜ + ㄴ → 문`, then hear the word in the same interaction.
3. Recall the same word with a `문` / `Tür` or `door` card.
4. Recognize the word, reveal the before/after Hanok window-and-door construction scene, then unwrap a Bojagi with an animated gift burst. Wrong answers offer retry. All of this is clearly a demonstration and grants no XP, items, mastery or permanent construction progress.
5. Connect `문` to the Ildu main gate and open its existing image, explanation and sources in a real preview. Returning preserves the onboarding state.
6. Keep purpose and starting-level selection, with readable examples and the existing persistence contract.
7. Show Taego left and Joy right, labels underneath. Tapping each plays that character's `tiger_choose` or `magpie_choose` signature gesture; the last tap wins. Confirming and continuing never wait for video completion.

The first-entry preview carries the Hanok and first actual learning goal forward. Actual app progression continues to use its existing verified-learning authority. Onboarding does not invent permanent grants or alter the server/storage schema.

## Presentation and media

- Center headings, supporting copy and companion descriptions. Keep primary screens within the measured viewport with fixed safe-area actions. Secondary detail dialogs may scroll.
- Keep the existing tested 320x640, 360x640, 390x844, 720x1152 at DPR 2.5, and 1152x720 layouts; DE/EN and text scales 1.0, 1.3, 2.0. Touch actions remain at least 48 logical pixels.
- Use existing approved Hanok construction assets (`14_ondol_maru.webp` and `15_changho_finish.webp`) as a before/after demonstration. Preserve all of the featured building and its aspect ratio; do not inflate a low-resolution card into a tall panel.
- The original choose clips remain unchanged. They are H264 without alpha: tiger 1080x1080 and magpie 1920x1080. Preserve their movement and natural proportions in any app-optimized derivative. Do not treat an RGB checkerboard as transparency, erase white feathers/fur, or darken the character with multiply compositing.
- Onboarding-only media keeps `OnboardingCharacterMedia(characterId, motion, active, replayToken, size)` as the rendering boundary. Selected and confirmed states use the choose gesture. Inactive, reduced-motion, failed and background states show a valid poster; only the selected character animates.
- Media output and visual validation must state real alpha/edge quality truthfully. No missing-asset icons or unqualified generated checkerboards may ship as character artwork.

## Verification and integration

Preserve stable onboarding IDs, purpose/level saving, last-intent-wins companion selection, failure recovery, restart recovery and home-entry behavior. Test the shared word, growth/reward retry and replay, gate preview, both choose gestures, motion reduction and lifecycle cleanup. Run the existing 41-case strengthened widget regression plus the viewport matrix and media tests. Verify the private Site after publishing the validated source. Build Android and attempt authorized device validation without overwriting product data or bypassing device restrictions. Device-only performance or installation gates must be reported separately if unavailable.

Use the isolated onboarding worktree. Review the final diff, run required CI/Playwright for the exact PR head, merge the approved change, then verify the exact merge SHA on main. Follow the repository's safe merged-worktree cleanup audit and preserve unique originals, review assets and tool records outside a removed worktree.
