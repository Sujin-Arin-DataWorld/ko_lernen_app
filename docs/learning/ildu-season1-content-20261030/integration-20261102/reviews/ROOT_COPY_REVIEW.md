# ROOT common copy and 34 inherited goal review

- Reviewer: A2.1 author, independent of ROOT's copy authorship.
- Date: 2026-11-02, Europe/Berlin.
- Scope: all 7 entries in `COMMON_COPY.json`; all 34 EN/de-DE pairs in `build_package.py:GOALS`, compared with the 28 FOUNDATION goals and 6 A1.1 Can-do rows.
- Evidence: current worktree HEAD `646c4658e70f594ab234a172679e29122d0f0e66`.
- Reviewed COMMON_COPY SHA-256: `1adeeb3d91fa793905eb7742b1e2c0b44687fa4bbac511ce5153f8429b1c8194`.
- Reviewed build_package SHA-256: `ab86ca323bc2e664421bc1134dbd5e3642e2fef339dea35d874fb18c3d2313e6`.
- Method: beyond-humanizer scene/function/force checks and independent EN/de-DE naturalness review; no native-speaker, teacher, audio, or runtime approval.

## Changes needed before model-copy pass

### R-COPY-01: resume overstates confirmed storage in EN/de-DE

KO says `놓아 둔 답`; EN `saved response` and DE `gespeicherte Antwort` add a confirmed-save claim. A restored current response may be valid even when the prior save was not confirmed. The existing response condition correctly requires actual restoration, but does not make the storage wording equivalent.

Replace EN with:
> Welcome back. Check your previous response and the help you used, then continue.

Replace DE with:
> Willkommen zurück. Sieh dir deine bisherige Antwort und die verwendete Hilfe an und mach dann weiter.

### R-GOAL-01: F0.1.sound-signs changes the goal

KO requires understanding the role of initial ㅇ and vowels, then distinguishing 아/어. Both translations currently replace role understanding with physically placing ㅇ beside a vowel. Placement can be an activity, but is not an equivalent statement of this goal.

EN:
> Understand the roles of initial ㅇ and vowels, and distinguish 아 from 어.

DE:
> Verstehe die Funktion des anlautenden ㅇ und der Vokale und unterscheide 아 und 어.

### R-GOAL-02: A1.1-02 loses the concrete information scope

KO limits the choice to name, origin, and languages used. Current `information about yourself / Angaben über dich` broadens that to any personal information. Keep the learner's choice and name the three source categories.

EN:
> Choose what to share about your name, where you are from, and the languages you use, and ask others about these details.

DE:
> Entscheide, was du über deinen Namen, deine Herkunft und die von dir verwendeten Sprachen sagen möchtest, und frage andere danach.

### R-GOAL-03: A1.1-06 loses the restrictive request function

Current EN `clarify what you mean` and DE `stelle klar, was du meinst` omit `필요한 범위`. The preserved manuscript's `-만` activity explicitly restricts the requested choice, e.g. asking for water only. Also, DE `Berichtige einen ... Gegenstand` sounds like correcting the physical object rather than a mistaken identification.

EN:
> Correct a mistaken name or identification of an object and specify only what you need.

DE:
> Korrigiere einen falsch verstandenen Namen oder eine falsche Zuordnung eines Gegenstands und sage, was du ausschließlich brauchst.

The slightly longer German is justified by preserving both identity correction and restrictive scope; a shorter alternative is `Korrigiere falsche Angaben zu Namen oder Gegenständen und grenze ein, was du brauchst.`

## Recommended wording improvements

- **A1.1-01 EN:** `introduce a name` is unnatural and `ask for repetition` drops the missed-hearing trigger. Prefer `Greet someone, give a name, and ask someone to repeat what you did not hear.` DE `... bitte um Wiederholung, wenn du etwas nicht gehört hast.`
- **F0.4.closed-endings DE:** `geschlossene Endungen` can suggest grammatical suffixes. Prefer `Lerne den Verschluss bei einfachen Endkonsonanten aus der ㄱ-, ㄷ- und ㅂ-Gruppe kennen.` EN should retain the source's group scope: `Explore closure in simple final consonants from the ㄱ, ㄷ and ㅂ groups.`
- **F0.2.sea-and-bridge:** source explicitly includes spelling. If making source alignment explicit, EN `Connect the sounds and spellings of 바다 and 다리 with their meanings.`; DE `Verbinde die Laute und Schreibweisen von 바다 und 다리 mit ihren Bedeutungen.`
- **F0.3.two-below:** source explicitly names horizontal placement. Optional precision: EN `Distinguish ㅛ and ㅠ in sound and horizontal layout.`; DE `Unterscheide ㅛ und ㅠ nach Laut und waagerechter Anordnung.`

## Other findings and limits

- COMMON assisted/independent copy is appropriate when its existing response conditions are enforced. No full-band or all-modality mastery is claimed.
- COMMON audio alternative and pause/save-failure wording preserve a usable route without adding microphone or pronunciation requirements.
- COMMON revisit wording preserves reward and construction ownership. It is candidate copy; the sentence does not establish runtime duplicate-credit protection.
- All 34 goal pairs were checked against their ordered KO source rows; remaining pairs preserve the main function at this review's level of precision.
- German guidance consistently uses du. Formal relationships in lesson dialogue must still be chosen by scene rather than copied mechanically from this guidance.
- Result at reviewed snapshot: **CORRECTIONS_REQUIRED** for the four named semantic/force issues above. Suggestions are review proposals; ROOT owns any edits to COMMON_COPY/build_package and generated inherited units.
## Final recheck - 2026-11-02 14:25 Europe/Berlin

ROOT's corrected common copy and all 34 GOALS were re-read from disk. R-COPY-01 and R-GOAL-01/02/03 are resolved. The four recommended wording improvements were also verified: hearing-trigger wording, final-consonant closure terminology, 바다/다리 spelling, and ㅛ/ㅠ horizontal placement.

- Current COMMON_COPY SHA-256: `3332d2ecb6f4503aff8fa560c4d15d88e908069ef9e043d9b59cbe52f7588f2a`.
- Current build_package SHA-256: `772d5e1ee7dcf7703bf46afdc84a896fd6aba7307ae8744168f099f08f0e1c2d`.
- Final bounded result: **MODEL_QA_PASS** for the seven common-copy entries and 34 goal translations. No outstanding semantic/force finding remains in that reviewed scope.
- This does not approve other build_package logic, certify the 34 inherited full manuscripts, establish saved-state implementation, or replace native/teacher/audio/Flutter/device verification.
