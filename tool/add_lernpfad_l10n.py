"""Add the path's interface strings without changing existing translations."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STRINGS = {
    'pathV2Title': ('Dein Lernpfad', 'Your learning path'),
    'pathV2ChooseBand': ('Dein Lernziel', 'Your learning goal'),
    'pathV2Goal': ('Danach kannst du …', 'What you will be able to do'),
    'pathV2Progress': ('{done} von {total} verfügbaren Pflichtaktivitäten bearbeitet', '{done} of {total} available required activities completed'),
    'pathV2Partial': ('Dieser Abschnitt wird noch ergänzt. Bearbeitete Aktivitäten bestätigen noch nicht das gesamte Lernziel.', 'This section is still being expanded. Completing its available activities does not yet confirm the whole learning goal.'),
    'pathV2Today': ('Dein nächster Schritt', 'Your next step'),
    'pathV2Start': ('Loslegen', 'Begin'),
    'pathV2Resume': ('Weiterlernen', 'Resume learning'),
    'pathV2Retry': ('Erneut versuchen', 'Try again'),
    'pathV2Error': ('Dein Lernpfad konnte nicht geladen oder gespeichert werden. Deine bisherigen Daten werden beibehalten.', 'Your path could not be loaded or saved. Your previous data is preserved.'),
    'pathV2PrepareTitle': ('Was brauchst du für diese Aufgabe?', 'What do you need for this activity?'),
    'pathV2PrepareBody': ('Hier kommen koreanische Wörter und Sätze vor. Du kannst zuerst Zeichen üben, mit den Erklärungen weiterlernen oder die Vorbereitung später nachholen. Dein gewähltes Lernziel bleibt gleich.', 'This activity contains Korean words and sentences. Practise letters first, continue with explanations, or prepare later. Your chosen goal stays the same.'),
    'pathV2Prepare': ('Zeichen kurz vorbereiten', 'Prepare with letters'),
    'pathV2PrepareRelated': ('Eine Grundlage kurz üben', 'Practise a related foundation'),
    'pathV2Supported': ('Mit Erklärungen weiter', 'Continue with explanations'),
    'pathV2Later': ('Vorbereitung später', 'Prepare later'),
    'pathV2All': ('Alle Lernabschnitte', 'All learning sections'),
    'pathV2Activities': ('Aktivitäten in diesem Abschnitt', 'Activities in this section'),
    'pathV2Free': ('Frei üben', 'Free practice'),
    'pathV2Hanok': ('Zum Ildu-Haus', 'Visit Ildu House'),
    'pathV2Legacy': ('Bisherigen Lernpfad öffnen', 'Open the previous learning path'),
    'pathV2Listening': ('Hören', 'Listening'),
    'pathV2Speaking': ('Sprechen', 'Speaking'),
    'pathV2Reading': ('Lesen', 'Reading'),
    'pathV2Writing': ('Schreiben', 'Writing'),
    'pathV2Unchecked': ('Noch nicht bestätigt', 'Not yet confirmed'),
    'pathV2Confirmed': ('{count} begrenzte Aufgaben bestätigt', '{count} bounded tasks confirmed'),
    'pathV2Pending': ('Weitere Lern- und Transferaufgaben werden vorbereitet.', 'Further teaching and transfer activities are being prepared.'),
    'pathV2Episode': ('Ein kleiner Vorfall im Hof', 'A small incident in the courtyard'),
    'pathV2Continue': ('Weiter', 'Continue'),
    'pathV2ChooseSign': ('Welcher Silbenblock passt zu diesen Zeichen?', 'Which syllable block matches these letters?'),
    'pathV2Practice': ('Mit Hilfe üben', 'Practise with support'),
    'pathV2Check': ('Jetzt selbst ausprobieren', 'Try it independently'),
    'pathV2Help': ('Zeig mir einen Hinweis', 'Show me a hint'),
    'pathV2Hint': ('Diese Zeichen ergeben {answer}. Mit dem Hinweis kannst du die Geschichte fortsetzen.', 'These letters make {answer}. The hint lets you continue the story.'),
    'pathV2Wrong': ('Schau noch einmal auf den kurzen Strich. Du kannst einen Hinweis verwenden.', 'Look at the short stroke again. You can use a hint.'),
    'pathV2ResultSupported': ('Die Schilder sind zurück! Du hast die Aufgabe mit Unterstützung gelöst.', 'The signs are back! You solved the activity with support.'),
    'pathV2ResultIndependent': ('Die Schilder sind zurück! Du hast 아 und 어 in dieser Aufgabe selbst zugeordnet.', 'The signs are back! You matched 아 and 어 independently in this activity.'),
    'pathV2FirstGoal': ('Heute lernst du die Zeichen 아 und 어 kennen und bringst sie an ihren Platz. Du kannst auch ohne Ton mitmachen.', 'Today you will learn 아 and 어 and put their signs in place. You can take part without audio too.'),
    'pathV2Scope': ('Ein erster Schritt beim Lesen: 아 und 어 zuordnen. Hören, Sprechen und freies Schreiben sind noch offen.', 'A first step in reading: matching 아 and 어. Listening, speaking and free writing are still to come.'),
    'pathV2Return': ('Zurück zu meinen Lernzielen', 'Back to my learning goals'),
    'pathV2Listen': ('Laut anhören', 'Listen to the sound'),
    'pathV2AudioUnavailable': ('Der Ton ist gerade nicht verfügbar. Du kannst die Zeichen weiter üben; das zählt nicht als Hörnachweis.', 'Audio is unavailable right now. You can continue practising the signs; this does not count as listening evidence.'),
    'pathV2Recheck': ('Der Inhalt wurde überarbeitet. Beginne einen neuen Versuch; bisherige Ergebnisse bleiben erhalten.', 'This content has changed. Start a new attempt; previous results are kept.'),
    'pathV2Restart': ('Neuen Versuch starten', 'Start a new attempt'),
    'pathV2Local': ('Neue Fortschritte dieses Lernpfads werden vorerst auf diesem Gerät gespeichert.', 'New progress in this path is currently saved on this device.'),
    'pathV2Foundation': ('Einstieg', 'Foundation'),
    'pathV2Review': ('Noch einmal üben', 'Practise again'),
    'pathV2TaskContext': ('Wende das Gelernte in einer kurzen Aufgabe an. Erklärungen und Beispiele stehen dir zuerst zur Verfügung.', 'Use what you have learned in a short activity. Explanations and examples come first.'),
}
PLACEHOLDERS = {'pathV2Progress': ['done', 'total'], 'pathV2Confirmed': ['count'], 'pathV2Hint': ['answer']}

for index, language in enumerate(('de', 'en')):
    path = ROOT / f'lib/l10n/app_{language}.arb'
    data = json.loads(path.read_text(encoding='utf-8'))
    for key, values in STRINGS.items():
        data[key] = values[index]
        if key in PLACEHOLDERS:
            data['@' + key] = {'placeholders': {name: {'type': 'String' if name == 'answer' else 'int'} for name in PLACEHOLDERS[key]}}
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
