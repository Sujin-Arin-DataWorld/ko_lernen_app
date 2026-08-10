import type { Metadata } from "next";
import { LegalShell } from "../legal";

export const metadata: Metadata = { title: "Alle Funktionen", description: "Hangul, SRS-Wortschatz, Grammatik, Szenarien, Spiele, eigene Lernpakete und die wachsende Hanok-Welt im Überblick.", alternates: { canonical: "/features" } };

const groups = [
  ["Hangul lernen", "19 Konsonanten, 21 Vokale, Batchim, animierte Strichreihenfolge, Finger-Nachzeichnen und Erkennen, Schreiben sowie Hören."],
  ["Vokabeln A1 bis B2", "526 Wörter in 61 kleinen Packs, koreanische Aussprache, deutsche und englische Übersetzung, Karten und SM-2-Wiederholungsplan."],
  ["Eigene Wortlisten", "Wörter selbst ergänzen, Übersetzungen erstellen lassen, Fotos anhängen, CSV-Listen importieren und als Karten oder Quiz üben."],
  ["Grammatik", "88 Muster von den Grundlagen bis B2, verständliche Erklärungen, Audio und natürliche Beispielsätze."],
  ["Szenarien", "Dialoge, Wortschatz, Mini-Quests und Kulturhinweise für Café, Markt, Hotel, U-Bahn, Taxi, Apotheke und weitere Alltagssituationen."],
  ["책 한 컷", "Buchseite fotografieren, lokal zuschneiden und per On-Device-OCR erkennen. Auf Wunsch wird der extrahierte Text analysiert, übersetzt und als eigenes Lernpaket gespeichert."],
  ["Spiele", "Anlaut-Quiz, Hangul Wordle, 끝말잇기 Wortkette, Lückentexte, Hör- und Übersetzungsaufgaben mit unmittelbarem Feedback."],
  ["Hörmodus und Aussprache", "Szenario-Audio mit Untertiteln und Tempi, integrierte Aussprache sowie dynamische TTS-Ausgabe für unterstützte Texte."],
  ["Hanok und Fortschritt", "Stufenweiser Ausbau vom leeren Hof bis zum Jongga-Anwesen, Verzierungen, Streaks, Quests, Level, Belohnungen und saisonale Inhalte."],
  ["Teilen, Sync und Gye", "Optionale Pack-Freigabe, Google- oder Apple-Verknüpfung für angebotene Backups sowie Lerngruppen ab 16 Jahren mit festen Reaktionen, Stickern und Moderation."],
  ["Erinnerungen und Feedback", "Optionale Lern-Erinnerungen, Push-Mitteilungen für unterstützte Community-Aktionen und freiwilliges strukturiertes Tester-Feedback."],
  ["Local-first und Kontrolle", "Lernstand und Fotos bleiben lokal maßgeblich. Analytics, Crashlytics und Benachrichtigungen sind getrennt wählbar. Konto, Backup und lokale Daten haben eigene Löschwege."],
];

export default function Features(){return <LegalShell eyebrow="Produktübersicht" title="Alle Funktionen von Hangul Sori" intro="Die vollständige, nach aktuellem Projektstand belegte Funktionsübersicht. Die endgültige Store-Freigabe einzelner Online-Funktionen hängt vom signierten Release-Build und der produktiven Konfiguration ab."><div className="support-grid">{groups.map((g,i)=><article key={g[0]}><span>{String(i+1).padStart(2,"0")}</span><h3>{g[0]}</h3><p>{g[1]}</p></article>)}</div></LegalShell>}
