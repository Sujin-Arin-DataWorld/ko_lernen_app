# Localization Deep-Dive — DE/EN Native Pass (2026-06-09)

> SSoT for the German/English native-quality improvement project (pre-internal-test).
> Jin scope: **all surfaces** (UI ARB + scenarios + German learning content + hardcoded gaps),
> **add English learning content** (German first → English), **aggressive nuance elevation**.
> Every edit follows the locked decisions below for consistency.

---

## 1. Locked decisions (style sheet)

### Register & voice
- **German**: informal **du** everywhere (already consistent — keep). Warm, motivating, concise. Avoid stiff/"teacherly" or translationese phrasing.
- **English**: friendly, encouraging, Duolingo-like. Contractions OK (US English). Parallel in *meaning + tone* to the German for the same key.
- **Scenarios**: keep situation-appropriate formality (Sie / 존댓말 for formal contexts, casual for friends).

### Locked loanword gender / translation (decide once, use everywhere)
| Term | German treatment | Notes |
|---|---|---|
| **Hanok** | **das Hanok** → always "**Dein** Hanok" | NEVER "Deine Hanok". Bug found: `previewPage2Title` had "Deine". |
| Hangul | das Hangul (proper noun) | keep as-is |
| Dancheong | das Dancheong | decorative painting |
| Gye (契) | das Gye / "Lern-Gye" | study group |
| Jongga | das Jongga | head house |
| Dure / Dureh | keep romanized | |
| Kkeunmari | "Wortkette" (DE) / "Word Chain" (EN) | already used |

### German typography
- Proper-noun + German noun compounds take a hyphen: **Wordle-Siege**, **Wordle-Streak** (KI-Kurs already correct).
- **Subordinate-clause / Vorfeld commas are mandatory**: "Ja, das stimmt." · "Ich esse, weil …" · "Wenn …, …" · "Es scheint, als …".

### Invariants (must hold after every edit)
- ARB: keys unchanged, placeholders unchanged, **DE key set == EN key set** (parity).
- CSV: column count uniform per file; `data_integrity_test` header assertions updated in lockstep.
- JSON (scenarios, grammar_patterns): valid, Korean lines untouched, structure/keys preserved.
- English learning content: translate from the **Korean source** (German as cross-reference only — no DE→EN re-translation drift).

---

## 2. Confirmed findings (verified by direct read, §0)

| # | Key / location | Issue | Fix |
|---|---|---|---|
| 1 | `reviewTitle` (de:37), `homeReviewTitle` (de:43) | DE "Heute lernen" (=learn) ≠ EN "Today's review" (=review) | DE → "Heute wiederholen" |
| 2 | `hanokCinematicIntro` (de:512) vs `previewPage2Title` (de:984) | "Dein Hanok" vs "Deine Hanok" — gender contradiction | → "Dein Hanok" everywhere |
| 3 | `welcomeMsg` (en:75) | "All the best today" sounds like a farewell | → "You've got this today" |
| 4 | `statsWordleWins` (de:259), `statsWordleStreak` (de:260) | missing compound hyphen | → "Wordle-Siege", "Wordle-Streak" |
| 5 | `onboardingPage3Subtitle` (de:598 / en:597) | "Je öfter du kommst" / "The more you come" — ambiguous | reword both |
| 6 | `korean_vocab.csv` rows (e.g. csv:9, 10) | missing commas "Ja das stimmt" / "Nein das ist falsch" | comma sweep all rows |
| 7 | vocab/grammar CSV | no English columns → EN-UI users learn in German | add EN columns + locale wiring |

---

## 3. Change log

> Appended per phase as edits land. Format: `key/file — old → new (reason)`.

### Phase 0 — style sheet
- This document created.

### Phase 1 — UI ARB (DE+EN) ✅
~115 strings edited across `app_de.arb` + `app_en.arb` (two-lens cross-check: DE-native + DE↔EN-parity/EN-native; Opus adjudicated). Categories:
- **DE/EN semantic mismatch**: `reviewTitle`/`homeReviewTitle` "Heute lernen"→"Heute wiederholen" (matches EN "Today's review").
- **Gender bug**: `previewPage2Title` "Deine Hanok"→"Dein Hanok" (das Hanok).
- **Compounds**: `statsWordleWins`→"Wordle-Siege", `statsWordleStreak`→"Wordle-Streak".
- **EN non-native**: `welcomeMsg` "All the best today"→"You've got this today"; `chosungRoundLevelUp` "Strong!"→"Awesome!"; `createWordbookCta` "Own word list"→"My word list"; `homeTigerBubbleStart` "Shall we study…"→"Up for 5 minutes of Korean?".
- **Nuance elevation (both langs)**: footerCheer, paywallCtaStart/"freischalten", streakDialog*, gye* (Sie/Pakete→Packs, "Wir vermissen dich"→"Du fehlst uns"), book "knipsen"→"fotografieren" (consistency), URL→Link, "geklärt"→"geschafft/abgeschlossen", onboarding/consent/profile warmth, +more.
- Parity held (839=839), `flutter gen-l10n` OK.

### Phase 2 — scenarios.json ✅ (German) / ⏸ (English)
13 fixes applied (atomic Python, count==1 guard, JSON-validated). **German real errors** (12): `introduce_yourself` "Ich mich auch."→"Freut mich ebenfalls."; "Ohne dieses Phrase"→"diese Phrase"; `bunshik` "Eine Dose Sprite."→"Limo." (사이다); `hoeshik` du→Sie register (2 lines); **"Direktheit unbeleidigt…"→"…verletzt…"** (unbeleidigt is not a word); `hotel_checkin` 2 lines; `business_meeting` "먼 길 오셨네요" restored; `pharmacy` "Anweisung"→"Erklärung"; `postpone_plans` "yeah~"→"ne?~"; `job_interview` "wachsen"→"weiterentwickeln". + EN `friend_birthday` title "a happy birthday".
- ⚠️ **English scenario dialogue NOT reviewed**: the EN-review subagent hallucinated dialogue lines that don't exist in the file (count==0 guard caught it; §0). Left untouched — needs a reliable re-review.

### Phase 3 — German learning content ✅
48 German correctness fixes (surgical Edits, CSV column-integrity revalidated 14/11 cols, 0 bad rows):
- **`grammar.csv` (34)**: systematic subordinate-/relative-clause & "um…zu" comma insertions (e.g. "Ich esse, weil…", "Der Film, den ich gestern sah, war…", "Sobald…, …"), `sondern`/`aber`/`während`/`als` commas, "zuhause"→"zu Hause", "Ich bemühe mich, mehr zu lernen" (dropped wrong "um"). Opus caught ~11 the agent missed (relative clauses, indirect speech).
- **`korean_vocab.csv` (14)**: answer-particle & vocative commas ("Ja, das stimmt", "Ich liebe dich, Papa", "Danke, Lehrerin"), infinitive commas, redundancy fix (외롭다), elliptical→full ("Ich bitte um gute Zusammenarbeit in Zukunft").
- All comma-bearing fields RFC-quoted so parsing/column-count unchanged.

### Phase 4 — English learning content ⏩ DONE BY CONCURRENT SESSION
Discovered mid-run: a concurrent session already added EN columns to both CSVs + model helpers. **Not duplicated** (avoided conflict).
- `korean_vocab.csv`: 14 cols incl `english,pos_en,example_english` (good quality, verified).
- `grammar.csv`: 11 cols incl `type_en,explanation_en,example_en,note_en`.
- `lib/models/vocab.dart` / `grammar.dart`: EN fields + `meaning(lang)` / `byLang` helpers (`lang=='en' && …isNotEmpty ? en : de`).
- ⚠️ Jin: confirm UI read-sites switched to locale (filterDirKoDe still "Korean→German" in EN ARB — left for that session), data_integrity test header update, and English content native QA.

### Phase 5 — hardcoded l10n gaps ✅
4 new keys (DE+EN) + 6 screens wired; `flutter analyze` (5 screens) = 0 issues:
- `bookCaptureWebNotice` ← `book_capture_screen.dart:61` (was DE+KO hardcoded web notice).
- `introSkipHint` ← `intro_gate_screen.dart:217` (+ added AppL10n import; used State.context in `_scene`).
- `chosung_quiz_screen.dart:375` `const Text('Anlaut-Quiz')` → `AppL10n.of(context).gameChosungTitle`.
- `bookshelfCreatePackNameHint` ← `bookshelf_page_screen.dart:80`; `settingsMadeWith` ← `settings_screen.dart:567`.
- Skipped: `home_screen` 'PRO' badge (universal), settings dev-override (kDebugMode-only).

---

## 4. English learning-content provenance

> Record source/method for generated English (audit trail).
- vocab `english` / `example_english` / `pos_en`: generated from Korean source, German cross-referenced; reviewed by Opus for English nuance.
- grammar `explanation_en` / `example_english` / `type_en`: native English pedagogical rewrite parallel to DE.
- _(chunks + reviewer notes appended during Phase 4)_
