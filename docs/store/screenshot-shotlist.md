# Screenshot Shot List

> Jin macht echte Geräte-Captures. Diese Liste sagt **welcher State** für **welchen Slot**.

---

## Reihenfolge (alle 8 Slots, Android + iOS gleich)

| # | Screen | State (was muss zu sehen sein) | Caption-Vorschlag (DE / EN) |
|---|---|---|---|
| 1 | `/intro` Solsong-Tor | Tor halb geöffnet, Spalt sichtbar, Hintergrund Hanok schimmert | "Willkommen im Hanok" / "Step into the hanok" |
| 2 | `/` Home | Madang-Hintergrund mit Pflaumenblüten + Elster in Flug + heutige Karte sichtbar (Streak ≥ 1) | "Dein Lerngarten" / "Your learning courtyard" |
| 3 | `/hangul` Schreibcanvas | ㄱ wird gerade nachgezeichnet, Geist-Buchstabe sichtbar | "Hangul Schritt für Schritt" / "Hangul, stroke by stroke" |
| 4 | `/vocab` Karten-Flip | Karte mitten im 3D-Flip, koreanische Seite zur Hälfte sichtbar, SRS-Badge sichtbar | "Vokabeln mit SRS" / "Vocab with SRS" |
| 5 | `/wordle` | Reihe 2 abgeschlossen mit 1× richtig (grün), 2× falsche Position (gelb), 1× falsch (grau) + deutsche Hint-Karte sichtbar | "Hangul Wordle" / "Korean Wordle" |
| 6 | `/chosung` Anlaut-Quiz | A2-Level, direkt **nach** richtiger Antwort (grüne ✅ + Wort sichtbar) | "Anlaut-Quiz mit Runden" / "Anlaut quiz with rounds" |
| 7 | `/scenarios` Liste | A1 entsperrt (Sterne sichtbar) + B2 gesperrt (Sleeping-Tiger Empty-State) | "13+ echte Szenarien" / "13+ real scenarios" |
| 8 | `/stats` | XP ≥ 100, Streak ≥ 3 Tage, 3 Badges, Tiger+Magpie-Duo + Hanok-Header sichtbar | "Dein Fortschritt" / "Your progress" |

---

## Capture-Spezifikation

| Plattform | Auflösung | Format | Quelle |
|---|---|---|---|
| Android | 1080×1920 | PNG | `adb shell screencap -p /sdcard/sc.png && adb pull /sdcard/sc.png` |
| iOS 6.7" | 1290×2796 | PNG | Xcode Simulator iPhone 14 Pro Max → ⌘S |
| iOS 5.5" (optional) | 1242×2208 | PNG | Simulator iPhone 8 Plus → ⌘S |

---

## Capture-Vorbereitung (Reproduzierbare States)

Bevor du Screenshots machst, einmal in den App-Storage diese Werte schreiben:

1. **Streak ≥ 3 Tage** für Slot 2 + 8: in `StorageService` manuell setzen oder 3 Tage in Folge eine Übung machen.
2. **XP ≥ 100** für Slot 8: ein Szenario komplett mit 3 Sternen abschließen.
3. **3 Badges** für Slot 8: `cafe_starter`, weitere 2 (Settings → DevTools falls vorhanden, sonst durch Spielen).
4. **A1 abgeschlossen** für Slot 7: alle A1-Szenarien einmal durchspielen.

Alternativ: ein "Demo-User"-State in `StorageService.setDemoState()` vorab vorbereiten (Code-Snippet für später).

---

## Caption-Komposition (außerhalb des Frames)

Captions werden **nicht** im App-Screenshot eingebrannt, sondern oberhalb in einem Marketing-Frame zusammengesetzt:

- Schriftart: Pretendard Bold 64px (DE/EN)
- Farbe: `#0E1A18` auf `#FAF6EC` (Light) oder `#FAF6EC` auf `#0E1A18` (Dark)
- Tool: ChatGPT / Figma / Photopea — Original-Screenshot in Hanji-Cream-Rahmen einbetten, Caption oben drüber

Empfehlung: 4 Light + 4 Dark Slots abwechseln, damit beide Modi sichtbar sind.
