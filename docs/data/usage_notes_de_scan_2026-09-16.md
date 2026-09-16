# usage_notes.json DE orthography scan

> Two passes: (1) ASCII ae/oe/ue substitution leftovers + ss-for-ß candidates, checked against an allowlist of genuinely-correct German words -- treat every hit here as a real bug to fix. (2) a 'manual judgment' list of homograph pairs where the stripped ASCII form is ALSO a real word (druckt/drückt, schon/schön, ...) -- these cannot be pattern-matched as bugs; read each sentence and judge whether the umlaut was actually intended before changing anything.

- ASCII-umlaut leftovers (pass 1): **0**
- ss-for-ß candidates (pass 1): **0**
- homograph-pair hits for manual judgment (pass 2): **15**

## Pass 1 -- ASCII-umlaut leftovers (fix these)

(none)

## Pass 1b -- ss-for-ß candidates (fix these)

(none)

## Pass 2 -- homograph pairs (manual judgment, do NOT bulk-replace)

| id | field | stripped form | check if this should be | sentence |
|---|---|---|---|---|
| `vocab_b1_0050` | examples[0] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Wir haben mehrmals verhandelt, aber am Ende wurde der Preis nicht angepasst. |
| `vocab_b1_0137` | nuance | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 지불 ist ein eher formelles Wort für den Akt des Bezahlens selbst; 결제 beschreibt konkret, mit welcher Methode die Zahlung abgewickelt wurde. |
| `vocab_b1_0268` | examples[1] | `schon` | `schön` (schon = already (adverb); schön = beautiful/nice (adjective)) | Hast du die Hausaufgaben schon wieder aufgeschoben? Diesmal gibt's echt Ärger. |
| `vocab_a2_0367` | contrasts[0] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 무제한 heißt, ein konkretes Limit wurde aufgehoben, 무한 beschreibt ein von vornherein endloses, abstraktes Konzept. |
| `vocab_b1_0111` | nuance | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 전통 bezeichnet eine Kultur oder Weise, die in einer Gesellschaft über mehrere Generationen weitergegeben wurde; man findet es oft in Texten über Feiertage oder lokale Feste. |
| `vocab_b1_0187` | examples[1] | `schon` | `schön` (schon = already (adverb); schön = beautiful/nice (adjective)) | Diese Woche war ich schon dreimal auswärts essen. |
| `vocab_b1_0314` | examples[1] | `Bruder` | `Brüder` (Bruder = brother (singular); Brüder = brothers (plural)) | Mein großer Bruder wirkte etwas betrunken, also habe ich ihm Wasser gebracht. |
| `vocab_b1_0348` | situation | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Man benutzt es in Gruppenchats, wenn man prüft, ob eine Nachricht gelesen wurde. |
| `vocab_b1_0348` | contrasts[0] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 읽음 표시 zeigt an, ob eine Nachricht gelesen wurde, 수신 확인 bestätigt den Empfang einer E-Mail oder eines Dokuments. |
| `vocab_b1_0379` | contrasts[0] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 수신 확인 bestätigt, dass eine E-Mail angekommen ist, 읽음 표시 zeigt an, dass sie gelesen wurde. |
| `vocab_b1_0445` | nuance | `konnte` | `könnte` (konnte = could (Präteritum); könnte = could (Konjunktiv II)) | 재방문 bedeutet, dass ein Techniker oder Zuständiger denselben Ort noch einmal aufsucht; man benutzt es, wenn eine Angelegenheit nicht beim ersten Mal erledigt werden konnte. |
| `vocab_b1_0445` | situation | `konnte` | `könnte` (konnte = could (Präteritum); könnte = could (Konjunktiv II)) | Man benutzt es, wenn eine Reparatur oder ein Service nicht beim ersten Mal abgeschlossen werden konnte und ein weiterer Termin nötig ist. |
| `vocab_b1_0471` | examples[1] | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | Als ich die SMS zum Vorstellungstermin bekam, wurde ich etwas nervös. |
| `vocab_b1_0480` | examples[1] | `schon` | `schön` (schon = already (adverb); schön = beautiful/nice (adjective)) | Bei diesem Preis ist es für mich schon eine Belastung. |
| `vocab_b1_0488` | nuance | `wurde` | `würde` (wurde = became/was (Präteritum passive); würde = would (Konjunktiv II)) | 오해 bezeichnet den bedauerlichen Zustand, in dem etwas anders aufgefasst wurde, obwohl es niemand so gemeint hatte. |
