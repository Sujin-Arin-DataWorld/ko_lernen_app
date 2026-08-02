# Release Notes — v2.0.1 (Closed Testing, Build 2.0.1+7)

> Closed-Testing Notes für Play Console + App Store Connect.
> Sprache: DE + EN — beide in die Console eintragen.
> v1.0 → v2.0 ist der "**stately-rising-jongga**" Update — Pack-System,
> Hanok-Visualisierung, Special Quests, Snap-and-Learn.

---

## Deutsch (max. 500 Zeichen)

```
Hangul Sori v2.0 — neu denken, neu lernen 🏯

Neu:
• Vokabel-Packs — 526 Wörter in 61 thematische Packs (A1–B2)
• Hanok-System — dein Hof wächst mit deinem Fortschritt 🏠
• 17 Spezial-Quests — Pflaumenbaum, Steinmauer, Mondnacht …
• 📷 Snap-and-Learn — Lehrbuchseite fotografieren → Wörter + Grammatik automatisch
• Eigenes Bücherregal mit selbst erstellten Custom-Packs

Alles weiter:
• Hangul-Drills · 21 Szenarien · Wordle · Anlaut-Quiz · Hörverstehen · Kkeunmari
• Tag/Nacht · DE/EN · offline-fähig · optional Google-Backup

Viel Erfolg beim Bau deines Hanok!
```

(ca. 495 Zeichen)

---

## English (max. 500 chars)

```
Hangul Sori v2.0 — rethink, relearn 🏯

New:
• Vocab packs — 526 words in 61 themed packs (A1–B2)
• Hanok system — your courtyard grows as you learn 🏠
• 17 special quests — plum tree, stone wall, moonlit night …
• 📷 Snap-and-Learn — photograph a textbook page → automatic word & grammar
• Personal bookshelf with custom packs

Everything else:
• Hangul drills · 21 scenarios · Wordle · chosung quiz · listening · kkeunmari
• Light/dark · DE/EN · offline · optional Google backup

Enjoy building your hanok!
```

(ca. 470 chars)

---

## 이번 내부 테스트 릴리스 노트 — Build 2.0.1+7 (2026-08-02)

> Play Console 내부 테스트 "새 릴리스" 노트 필드에 **언어 태그 포함 통째로** 붙여넣기.
> (규칙: em-dash·마크다운·한국어 혼입 금지 — memory jin-no-em-dash-copy)

```text
<de-DE>
Neu in diesem Build:
• Ton-Einstellungen: Master-Schalter und 5 Kategorien (Spiel-Feedback, Lernfreunde, Hintergrundklänge, Intro, Aussprache) mit Lautstärke-Reglern und Vorhören
• Lernpfad jetzt auch auf dem Startbildschirm im neuen Zickzack-Design mit Stempel-Stationen
• Hören-Screen: NPC-Zeilen jetzt mit männlicher Stimme, wie in den Szenarien
• Feinschliff: Charakter-Videos passen exakt zur Kartenfarbe
</de-DE>
<en-US>
New in this build:
• Sound settings: master switch and 5 categories (game feedback, study buddies, background ambience, intro, pronunciation) with volume sliders and preview
• The learning path now uses the new zigzag design with stamp stations on the home screen too
• Listening screen: NPC lines now use the male voice, matching the scenarios
• Polish: character videos blend exactly with card colors
</en-US>
```

---

## Internal Notes (do not paste into store)

### v1 → v2 highlights

- **Phase 1**: 526 vocab split into 61 packs (A1×24, A2×17, B1×12, B2×8), 127 boss words
- **Phase 2**: Pack-grid screen + 3-stage play (learn → quiz → boss), Dancheong stamps
- **Phase 3**: 12 hanok build stages (empty → jongga) + cinematic transitions
- **Phase 4**: 17 special quests (13 standing + 4 seasonal) with passive QuestTracker
- **Phase 5**: 책 한 컷 — ML Kit OCR + DeepL Cloud Function + 31 grammar patterns
- **Phase 5.1**: Bookshelf list + page detail + Custom Pack play
- **Phase 5.2**: Home navigation cards + Settings endpoint UI

### Release prep

- Build tag: **v2.0.1+7** — matches `pubspec.yaml` `version: 2.0.1+7` (2026-08-02)
- Branch: `main` after Phase 5.2 verification
- Track: **Closed Testing** (5-10 testers from v1.0 user pool)
- Rollout: 100% to Closed track, monitor 1 week before considering Production
- Crash gate: < 0.3% sessions before promoting to Production
- Cloud Function: must be deployed before testers receive build, OR testers
  see "offline grammar only" banner (intended fallback)
- Privacy + Data Safety updates pushed before AAB upload (see
  `docs/privacy.html` v2026-06-12 — Analytics/Crashlytics opt-in, FCM/TTS/
  RevenueCat processors, `docs/store/data-safety.md`)

### Testing scope for Closed Alpha

Each tester should verify at least:
1. Vocab pack flow (open A1 first pack → learn → quiz → boss → stamp)
2. Hanok cinematic on first pack-cleared milestone
3. Snap-and-Learn (camera permission → OCR → analyze → save → bookshelf)
4. Custom pack creation from a bookshelf page
5. /quests screen renders without crash
6. Settings → Cloud endpoint save persists across restart
