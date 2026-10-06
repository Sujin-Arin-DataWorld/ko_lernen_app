# Display / Spoken / TTS Surface Policy

Canonical source: `dialogue_authoring_contract_20261006.json -> ttsSurfacePolicy`

## Three surfaces
Every dialogue line may have three distinct representations:

1. **displaySurface** — what the learner sees in print/app/chat simulation.
2. **spokenSurface** — what a human would naturally say aloud.
3. **performanceCue** — non-lexical direction such as natural laughter, hesitation, sigh, whisper, emphasis.

TTS must consume the reviewed spoken surface, not blindly read the display surface.

## Korean
Display-only markers can include `ㅋㅋ`, `ㅎㅎ`, emoji and repeated punctuation.
Default: omit pure chat laughter from spoken text when the warmth/joke already exists in wording and delivery.
Forbidden mechanical conversion:
- ㅋㅋ -> "크크"
- ㅎㅎ -> "흐흐"
- ㅋㅋ -> automatic "하하"
- ㅎㅎ -> automatic "호호"

If audible laughter matters, author an explicit performance cue.

## English
Chat forms such as `lol`, `lmao`, emoji or reaction spelling are not automatically spoken as letters/words.
The EN native-usage profile decides whether the spoken equivalent is omission, rewording, intonation or a real laugh.

## German
Chat abbreviations, reaction spelling, emoji and repeated punctuation are likewise reviewed separately from spoken dialogue.
Do not mechanically vocalize typed internet forms.

## Textbook implications
Printed chat examples may preserve authentic display markers.
Audio scripts must store a separate spoken surface.
Teacher notes may explain the pragmatic function without teaching a fake spoken pronunciation.

## Required metadata
- displaySurface
- spokenSurface
- performanceCue[]
- displayOnlyMarkers[]
- speechSurfaceNote
- spokenSurfaceReviewStatus
- ttsOwner
- source/review date

## Ownership
TTS generation remains Jin-owned.
The textbook/content factory may prepare reviewed spoken surfaces but must not synthesize or overwrite final TTS assets.
