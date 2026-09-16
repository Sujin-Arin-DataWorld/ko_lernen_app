# usage_notes.json DE orthography triage (advisory)

> Two passes: (1) ASCII ae/oe/ue substitution leftovers + ss-for-ß candidates, checked against an allowlist of genuinely-correct German words. Every hit requires contextual review; correct words may be flagged. (2) a 'manual judgment' list of homograph pairs where the stripped ASCII form is ALSO a real word (druckt/drückt, schon/schön, ...) -- these cannot be pattern-matched as bugs; read each sentence and judge whether the umlaut was actually intended before changing anything.
> A zero count is not German language approval. This scanner cannot establish meaning, grammar, register, or translation accuracy.

- ASCII-umlaut leftovers (pass 1): **4**
- ss-for-ß candidates (pass 1): **0**
- homograph-pair hits for manual judgment (pass 2): **16**

## Pass 1 -- ASCII-umlaut candidates (review in context)

| id | field | token | sentence |
|---|---|---|---|
| `vocab_b1_0240` | contrasts[0] | 'Dauer' | 세월 betont vergehende Tage und den Lauf der Zeit, 시간 umfasst auch Uhrzeit und Dauer; die emotionale Färbung hängt vom Kontext ab. |
| `vocab_b1_0430` | nuance | 'Dauer' | 상담 시간 bezeichnet die angebotenen Beratungszeiten oder die Dauer eines Beratungsgesprächs. |
| `vocab_b1_0430` | situation | 'Dauer' | Man verwendet es etwa bei Schule, Praxis oder Servicezentrum, um eine Beratung zu vereinbaren oder nach ihrer Dauer zu fragen. |
| `vocab_b1_0430` | contrasts[0] | 'Dauer' | 상담 시간 betont Zeitpunkt oder Dauer der Beratung, 면담 das persönliche Gespräch selbst. |

## Pass 1b -- ss-for-ß candidates (review in context)

(none)

## Pass 2 -- homograph pairs (manual judgment, do NOT bulk-replace)

| id | field | stripped form | check if this should be | sentence |
|---|---|---|---|---|
| `vocab_b1_0050` | examples[0] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Wir haben mehrmals verhandelt, aber am Ende wurde der Preis nicht angepasst. |
| `vocab_b1_0137` | nuance | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 지불 ist ein eher formelles Wort für den Akt des Bezahlens selbst; 결제 beschreibt konkret, mit welcher Methode die Zahlung abgewickelt wurde. |
| `vocab_b1_0268` | examples[1] | `schon` | `schön` (schon = already (adverb); schön = beautiful/nice (adjective)) | Hast du die Hausaufgaben schon wieder aufgeschoben? Diesmal gibt's echt Ärger. |
| `vocab_b1_0111` | nuance | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 전통 bezeichnet eine Kultur oder Weise, die in einer Gesellschaft über mehrere Generationen weitergegeben wurde; man findet es oft in Texten über Feiertage oder lokale Feste. |
| `vocab_b1_0165` | examples[0] | `wurden` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Bei dieser Personalrunde wurden Sie in den Rang 과장 (Gwajang) befördert. |
| `vocab_b1_0187` | examples[1] | `schon` | `schön` (schon = already (adverb); schön = beautiful/nice (adjective)) | Diese Woche war ich schon dreimal auswärts essen. |
| `vocab_b1_0314` | examples[1] | `Bruder` | `Brüder` (Bruder = brother (singular); Brüder = brothers (plural)) | Mein großer Bruder wirkte etwas betrunken, also habe ich ihm Wasser gebracht. |
| `vocab_b1_0321` | examples[0] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | In der Umfrage wurde nach der Kontakthäufigkeit zu Freunden anderen Geschlechts gefragt. |
| `vocab_b1_0348` | nuance | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 읽음 표시 zeigt in einer App an, dass eine Nachricht geöffnet oder gelesen wurde; eine Antwort oder Reaktion lässt sich daraus nicht ableiten. |
| `vocab_b1_0348` | situation | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Man benutzt es in Gruppenchats, wenn man prüft, ob eine Nachricht gelesen wurde. |
| `vocab_b1_0445` | contrasts[0] | `schon` | `schön` (schon = already (adverb); schön = beautiful/nice (adjective)) | 재방문 bezeichnet einen erneuten Besuch am selben Ort, 방문 einen Besuch unabhängig davon, ob man schon dort war. |
| `vocab_b1_0471` | nuance | `wurden` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Dieser Ausdruck bezeichnet das konkrete Datum und die Uhrzeit, die für ein Vorstellungsgespräch festgelegt wurden; er wird oft mit 잡다 (festlegen), 조율하다 (abstimmen) oder 변경하다 (ändern) kombiniert. |
| `vocab_b1_0471` | examples[1] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Als ich die SMS zum Vorstellungstermin bekam, wurde ich etwas nervös. |
| `vocab_b1_0480` | nuance | `Druck` | `drückt` (druckt = prints; drückt ... aus = expresses) | 부담 bezeichnet zu tragende Kosten oder Verantwortung sowie den dadurch empfundenen Druck. |
| `vocab_b1_0480` | collocations[0] | `Druck` | `drückt` (druckt = prints; drückt ... aus = expresses) | sich unter Druck fühlen |
| `vocab_b1_0480` | collocations[1] | `Druck` | `drückt` (druckt = prints; drückt ... aus = expresses) | ohne Druck |
