// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppL10nDe extends AppL10n {
  AppL10nDe([String locale = 'de']) : super(locale);

  @override
  String get paywallTitle => 'Hangul Sori Premium';

  @override
  String get paywallSubtitle => 'Koreanisch lernen, wann du willst.';

  @override
  String get paywallBenefit1 => 'Alle Vokabel-Pakete (A2 · B1 · B2)';

  @override
  String get paywallBenefit2 => 'Alle Gesprächs-Szenarien';

  @override
  String get paywallBenefit3 => 'Unbegrenzte Wiederholungen';

  @override
  String get paywallBenefit4 =>
      'Dein persönlicher KI-Kurs mit neuen Inhalten jeden Tag';

  @override
  String get paywallBenefit5 => 'Buchschnappschuss ohne Tageslimit';

  @override
  String get paywallPriceFallback => '5 € / Monat';

  @override
  String get paywallPricePerMonth => '/ Monat';

  @override
  String get paywallEyebrow => 'Premium';

  @override
  String get paywallCtaStart => 'Premium freischalten';

  @override
  String get paywallCtaRestore => 'Käufe wiederherstellen';

  @override
  String get paywallClose => 'Vielleicht später';

  @override
  String get paywallLegal =>
      'Jederzeit kündbar. Das Abo verlängert sich automatisch, bis du kündigst.';

  @override
  String get paywallNotAvailable =>
      'Abos sind in dieser Version noch nicht verfügbar.';

  @override
  String get paywallProcessing => 'Einen Moment …';

  @override
  String get paywallSuccess => 'Premium ist aktiv. Viel Spaß!';

  @override
  String get paywallFailed => 'Kauf nicht abgeschlossen.';

  @override
  String get paywallRestoreNone => 'Keine früheren Käufe gefunden.';

  @override
  String get paywallRestoreFailed =>
      'Käufe konnten nicht wiederhergestellt werden. Versuche es erneut.';

  @override
  String streakDisplay(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get streakDialogTitle => 'Deinen Streak halten';

  @override
  String get streakDialogSubtitle => 'Lern jeden Tag. So wächst dein Streak.';

  @override
  String get streakDialogEarned => 'Dranbleiben lohnt sich';

  @override
  String streakDialogCurrent(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return 'Aktueller Streak: $_temp0';
  }

  @override
  String streakDialogLastActivity(Object time) {
    return 'Zuletzt aktiv: $time';
  }

  @override
  String get streakDialogLearnNow => 'Jetzt lernen';

  @override
  String get characterSelectionTitle => 'Wer ist dein Lernfreund?';

  @override
  String get companionNoneName => 'Keine Lernbegleitung';

  @override
  String get companionNoneDescription =>
      'Du kannst später jederzeit 태고 oder Joy wählen.';

  @override
  String get companionNeutralThinking => 'Die nächste Runde wird vorbereitet …';

  @override
  String get homeMagpieBubbleStart =>
      'Wir fangen ganz in Ruhe an, Zeichen für Zeichen.';

  @override
  String get homeMagpieBubbleResume =>
      'Schön, dich zu sehen. Sollen wir kurz wiederholen?';

  @override
  String get homeLearnNowCtaMagpie => 'In Ruhe weiter';

  @override
  String get homeFirstWeekTitle => 'Deine erste Woche';

  @override
  String get characterNameTiger => '태고';

  @override
  String get characterRomanTiger => 'Taego';

  @override
  String get characterTraitTiger => 'Verlässlich & mutig';

  @override
  String get characterDescTiger =>
      'In der koreanischen Volkskunst ist der Tiger der Herr der Berge. Taego steht für ruhige, uralte Kraft. Er begleitet dich Schritt für Schritt und macht dir Mut, wenn es schwer wird.';

  @override
  String get characterNameMagpie => '조이';

  @override
  String get characterRomanMagpie => 'Joy';

  @override
  String get characterTraitMagpie => 'Fröhlich & lebhaft';

  @override
  String get characterDescMagpie =>
      'In Korea gilt die Elster als Glücksbotin, die gute Nachrichten bringt. Joy feiert jeden Erfolg mit dir und bringt gute Laune in jede Lektion.';

  @override
  String get characterSelectedTiger => 'Du hast Taego ausgewählt.';

  @override
  String get characterSelectedMagpie => 'Du hast Joy ausgewählt.';

  @override
  String get characterSelectionHint => 'Tipp deinen Lernfreund an';

  @override
  String get reviewTitle => 'Heute wiederholen';

  @override
  String get reviewEmptyTitle => 'Alles erledigt!';

  @override
  String get reviewEmptyBody =>
      'Für heute sind keine Karten fällig. Spiel eine Runde oder lern ein neues Paket. Die Wörter kommen später zur Wiederholung wieder.';

  @override
  String get reviewDoneTitle => 'Stark!';

  @override
  String get reviewDoneBody => 'Du hast deine fälligen Karten wiederholt.';

  @override
  String get reviewBonusLabel => 'Satz des Tages';

  @override
  String get reviewHubTitle => 'Wiederholen';

  @override
  String get reviewHubTodayHeadline => 'Heute gelernt';

  @override
  String get reviewHubEmptyToday =>
      'Heute noch nichts gelernt? Starte eine Lektion.';

  @override
  String reviewHubStartSelected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter üben',
      one: '1 Wort üben',
    );
    return '$_temp0';
  }

  @override
  String get reviewHubCalendarTooltip => 'Kalender';

  @override
  String reviewHubDeckLabel(int words) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get homeReviewTitle => 'Heute wiederholen';

  @override
  String homeReviewDue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter fällig',
      one: '1 Wort fällig',
    );
    return '$_temp0';
  }

  @override
  String get homeReviewDone => 'Heute alles wiederholt';

  @override
  String get settingsNotifSection => 'Erinnerung';

  @override
  String get settingsNotifTitle => 'Tägliche Erinnerung';

  @override
  String get settingsNotifSubtitle => 'Taego erinnert dich ans Lernen';

  @override
  String get settingsNotifTime => 'Uhrzeit';

  @override
  String get settingsNotifDenied =>
      'Benachrichtigungen sind deaktiviert. Erlaube sie in den Systemeinstellungen.';

  @override
  String get notificationTitle => 'Hangul Sori';

  @override
  String get notificationBody => 'Taego wartet schon. Zeit für Koreanisch! 🐯';

  @override
  String get homeCourseTitle => 'Dein Tageskurs';

  @override
  String get homeCourseDesc => 'Auf deine Schwächen & Interessen zugeschnitten';

  @override
  String get settingsInterestsTitle => 'Interessen';

  @override
  String get settingsInterestsSubtitle => 'Themen für deinen Tageskurs';

  @override
  String get interestsSheetTitle => 'Was interessiert dich?';

  @override
  String get interestEveryday => 'Alltag';

  @override
  String get interestFoodShopping => 'Essen & Einkaufen';

  @override
  String get interestWorkStudy => 'Beruf & Bildung';

  @override
  String get interestTravel => 'Reisen & Verkehr';

  @override
  String get interestFeelingsPeople => 'Gefühle & Menschen';

  @override
  String get interestHealthBody => 'Gesundheit & Körper';

  @override
  String get smalltalkTitle => 'Small Talk';

  @override
  String get smalltalkEmpty => 'Keine Sätze für diese Auswahl.';

  @override
  String get smalltalkReply => 'Beispielantwort';

  @override
  String get smalltalkPickCategory => 'Thema wählen';

  @override
  String get homeSmalltalkCardTitle => 'Small Talk';

  @override
  String get homeSmalltalkCardDesc => 'Gesprächseinstiege nach Thema';

  @override
  String get appTitle => 'Koreanisch lernen';

  @override
  String get welcomeMsg => 'Hallo! Du schaffst das heute 💪';

  @override
  String get footerCheer => 'Bleib dran, läuft super! 🌟';

  @override
  String get sectionModules => 'Lernmodule';

  @override
  String get sectionGames => 'Spiele';

  @override
  String get sectionStats => 'Statistik';

  @override
  String get moduleHangulTitle => 'Hangul';

  @override
  String get moduleHangulDesc => '14 Konsonanten + 10 Vokale';

  @override
  String get moduleVocabTitle => 'Vokabeln';

  @override
  String get moduleVocabDesc => '1.188 Karten · A1 → C2 · TTS';

  @override
  String get moduleGrammarTitle => 'Grammatik';

  @override
  String get moduleGrammarDesc => '176 Muster · A1 → C2';

  @override
  String get moduleListenTitle => 'Hören';

  @override
  String get moduleListenDesc => 'Sätze hören und verstehen';

  @override
  String get gameChosungTitle => 'Anlaut-Quiz';

  @override
  String get gameChosungDesc => 'Errate das Wort anhand der Anfangsbuchstaben';

  @override
  String get gameWordleTitle => 'Silben-Rätsel';

  @override
  String get gameWordleDesc => '2-3 Silben · 6 Versuche';

  @override
  String get navVocab => 'Vokabeln';

  @override
  String get navGrammar => 'Grammatik';

  @override
  String get navListen => 'Hören';

  @override
  String get navHangul => 'Hangul';

  @override
  String get navChosung => 'Anlaut-Quiz';

  @override
  String get navWordle => 'Silben-Rätsel';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navStats => 'Statistik';

  @override
  String get btnHoeren => 'Hören';

  @override
  String get btnSkip => 'Überspringen';

  @override
  String get btnSubmit => 'Prüfen';

  @override
  String get btnNext => 'Weiter';

  @override
  String get btnPrev => 'Zurück';

  @override
  String get legacyVocabPrevious => 'Vorherige Karte';

  @override
  String get btnRandom => 'Zufällig';

  @override
  String get btnGewusst => 'Gewusst!';

  @override
  String get btnNichtGewusst => 'Nicht gewusst';

  @override
  String get btnNewGame => 'Neues Spiel';

  @override
  String get btnConfirm => 'OK';

  @override
  String get btnCancel => 'Abbrechen';

  @override
  String get btnRetry => 'Erneut versuchen';

  @override
  String get btnClose => 'Schließen';

  @override
  String get btnApply => 'Übernehmen';

  @override
  String get btnPlay => 'Üben';

  @override
  String get btnDelete => 'Löschen';

  @override
  String get gameLoading => 'Spiel wird vorbereitet …';

  @override
  String gameRoundProgress(int current, int total) {
    return 'Runde $current von $total';
  }

  @override
  String get bookshelfTitle => 'Mein Bücherregal';

  @override
  String get bookshelfAddPage => 'Seite hinzufügen';

  @override
  String get bookshelfEmptyTitle => 'Noch keine Seite';

  @override
  String get bookshelfEmptyBody =>
      'Fotografiere deine erste Lehrbuchseite. Erkannte Wörter erscheinen dann hier.';

  @override
  String get bookshelfEmptyCta => 'Seite einlesen';

  @override
  String get bookshelfEmptyPreview => 'Leere Seite';

  @override
  String get bookshelfSectionPages => 'Seiten';

  @override
  String get bookshelfSectionCustomPacks => 'Eigene Pakete';

  @override
  String bookshelfTileMeta(int words, int grammar, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words Wörter',
      one: '1 Wort',
    );
    return '$_temp0 · $grammar Grammatik · $date';
  }

  @override
  String bookshelfPackMeta(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String bookshelfPackLearnedMeta(int learned, int total) {
    return '$learned von $total gelernt';
  }

  @override
  String get bookshelfPageTitle => 'Seite';

  @override
  String get bookshelfPageNotFoundTitle => 'Seite nicht gefunden';

  @override
  String get bookshelfPageNotFoundBody => 'Möglicherweise wurde sie gelöscht.';

  @override
  String get bookshelfCreatePackCta => 'Eigenes Paket aus dieser Seite';

  @override
  String get bookshelfCreatePackTitle => 'Neues eigenes Paket';

  @override
  String get bookshelfCreatePackName => 'Name';

  @override
  String bookshelfDefaultPackName(Object date) {
    return 'Paket $date';
  }

  @override
  String get bookshelfCreatePackSaved => 'Paket gespeichert.';

  @override
  String get bookshelfDeletePageTitle => 'Seite löschen?';

  @override
  String get bookshelfDeletePageBody => 'Die Seite wird endgültig entfernt.';

  @override
  String get bookshelfDeletePackTitle => 'Paket löschen?';

  @override
  String bookshelfDeletePackBody(Object name) {
    return 'Soll \"$name\" gelöscht werden?';
  }

  @override
  String get customPackPlayTitle => 'Eigenes Paket üben';

  @override
  String get customPackNotFoundTitle => 'Paket nicht gefunden';

  @override
  String get customPackNotFoundBody => 'Möglicherweise wurde es gelöscht.';

  @override
  String get customPackEmptyTitle => 'Paket ist leer';

  @override
  String get customPackEmptyBody => 'Dieser Paket enthält noch keine Wörter.';

  @override
  String get customPackResultTitle => 'Geschafft!';

  @override
  String get customPackResultDone => 'Alle Karten durchgegangen!';

  @override
  String customPackResultStats(int learned, int total) {
    return '$learned von $total als gewusst markiert';
  }

  @override
  String get customPackResultAgain => 'Nochmal durchgehen';

  @override
  String get customPackResultBack => 'Zurück zum Bücherregal';

  @override
  String get homeBookCardTitle => 'Buchseite';

  @override
  String get homeBookCardDesc => 'Foto machen → Wörter & Grammatik';

  @override
  String get homeBookshelfCardTitle => 'Mein Bücherregal';

  @override
  String get homeBookshelfCardDesc => 'Gespeicherte Seiten & Eigene Pakete';

  @override
  String get homeQuestsCardTitle => 'Quests';

  @override
  String get homeQuestsCardDesc => 'Schalte mehr Hanok-Dekoration frei';

  @override
  String get settingsBookEndpointSection => 'Cloud-Analyse-Endpoint';

  @override
  String get settingsBookEndpointHint =>
      'URL der Cloud Function (DeepL + OKT). Leer = nur Offline-Grammatik.';

  @override
  String get settingsBookEndpointSave => 'Speichern';

  @override
  String get settingsBookEndpointSaved => 'Endpoint gespeichert.';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterLevel => 'Level';

  @override
  String get filterTheme => 'Thema';

  @override
  String get filterType => 'Typ';

  @override
  String get filterDifficulty => 'Schwierigkeit';

  @override
  String get filterDirection => 'Vorderseite zeigt';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterDirKoDe => '🇰🇷 Koreanisch → 🇩🇪 Deutsch';

  @override
  String get filterDirDeKo => '🇩🇪 Deutsch → 🇰🇷 Koreanisch';

  @override
  String get emptyVocab =>
      'Keine Vokabeln für diesen Filter.\nPasse die Auswahl an.';

  @override
  String get emptyGrammar => 'Keine Muster für diesen Filter.';

  @override
  String get loadingVocab => 'Vokabeln laden …';

  @override
  String get loadingGrammar => 'Grammatik laden …';

  @override
  String get hintTapToFlip => 'Tippen zum Umdrehen';

  @override
  String get hintTapForExplanation => 'Tippen für Erklärung';

  @override
  String get chosungQuestion => 'Welches Wort?';

  @override
  String get chosungInputHint => 'Koreanisch eingeben …';

  @override
  String get chosungShowHint => 'Hören (Tipp)';

  @override
  String get chosungCorrect => '✓ Richtig!';

  @override
  String get chosungAnswer => 'Antwort';

  @override
  String get chosungEmptyBody =>
      'Für diese Lernstufe sind noch keine passenden Wörter vorbereitet.';

  @override
  String get chosungBackspace => 'Letztes Zeichen löschen';

  @override
  String chosungCorrectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count richtige Antworten',
      one: '1 richtige Antwort',
    );
    return '$_temp0';
  }

  @override
  String chosungWrongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count falsche Antworten',
      one: '1 falsche Antwort',
    );
    return '$_temp0';
  }

  @override
  String get chosungPadHiddenNote =>
      'Ab B1 gibt es keine Tastenhilfe mehr. Tippe das Wort mit deiner koreanischen Tastatur.';

  @override
  String get wordleHowTitle => 'Spielanleitung';

  @override
  String get wordleHowIntro =>
      'Errate das koreanische Wort in 6 Versuchen. Die Farben geben Hinweise.';

  @override
  String get wordleHowExact => 'Richtig';

  @override
  String get wordleHowExactDesc => 'Buchstabe an der richtigen Position';

  @override
  String get wordleHowWrong => 'Falsche Position';

  @override
  String get wordleHowWrongDesc =>
      'Buchstabe ist im Wort, aber anders platziert';

  @override
  String get wordleHowAbsent => 'Nicht vorhanden';

  @override
  String get wordleHowAbsentDesc => 'Buchstabe kommt im Wort nicht vor';

  @override
  String get wordleHowOutro =>
      'Jeden Tag ein neues Wort.\nShuffle für ein zufälliges Wort.';

  @override
  String wordleErrorLength(int n) {
    return 'Bitte $n Silben eingeben';
  }

  @override
  String get wordleErrorHangul => 'Bitte nur Hangul eingeben';

  @override
  String get wordleResultWin => 'Geschafft!';

  @override
  String get wordleResultLose => '😢 Leider daneben';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemsprache';

  @override
  String get settingsLanguageDe => 'Deutsch';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTtsRate => 'Sprechtempo';

  @override
  String get ttsSpeedLabel => 'Tempo';

  @override
  String ttsSpeedChip(String speed) {
    return '$speed×';
  }

  @override
  String get ttsSpeedSheetTitle => 'Sprechtempo';

  @override
  String get settingsSoundSection => 'Ton';

  @override
  String get settingsSoundMaster => 'Ton';

  @override
  String get settingsSoundMasterDesc =>
      'Schaltet alle Töne der App ein oder aus';

  @override
  String get settingsSoundMasterVolume => 'Gesamtlautstärke';

  @override
  String get settingsSoundGame => 'Spiel-Feedback';

  @override
  String get settingsSoundGameDesc => 'Richtig, falsch, Combo, Level-up';

  @override
  String get settingsSoundCompanion => 'Lernfreunde';

  @override
  String get settingsSoundCompanionDesc =>
      'Tiger und Elster: Begrüßung und Jubel';

  @override
  String get settingsSoundAmbience => 'Hintergrundklänge';

  @override
  String get settingsSoundAmbienceDesc =>
      'Leise Hanok-Atmosphäre auf manchen Bildschirmen';

  @override
  String get settingsSoundCinematic => 'Intro beim Start';

  @override
  String get settingsSoundCinematicDesc =>
      'Der Klang des Hoftors beim Öffnen der App';

  @override
  String get settingsSoundSpeech => 'Koreanische Aussprache';

  @override
  String get settingsSoundSpeechDesc => 'Vorlesen der koreanischen Wörter';

  @override
  String get settingsSoundSpeechWarn =>
      'Ohne diesen Ton hörst du keine Aussprache';

  @override
  String get settingsSoundDuck => 'Bei Aussprache leiser';

  @override
  String get settingsSoundDuckDesc =>
      'Hintergrundklänge werden leiser, während Koreanisch vorgelesen wird';

  @override
  String get settingsSoundRespectSilent => 'Stumm-Schalter beachten';

  @override
  String get settingsSoundRespectSilentDesc =>
      'Kein Ton, wenn das Gerät stumm geschaltet ist';

  @override
  String get settingsReset => 'Alle Daten zurücksetzen';

  @override
  String get settingsResetConfirm =>
      'Wirklich alle Lernfortschritte löschen? Das lässt sich nicht rückgängig machen.';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsOriginStoryTitle => 'Warum Hangul Sori entstand';

  @override
  String get settingsOriginStorySubtitle => 'Die Idee hinter der App';

  @override
  String get settingsOriginStoryBody =>
      'Gründerin Sujin Park hat Hangul Sori aus einem praktischen Gedanken heraus entwickelt: Koreanischlernen soll Klang, Schrift, Alltagssituationen und die Bücher verbinden, mit denen du bereits lernst. Die App führt diese Teile in einem Lernweg zusammen, von den Hangul-Grundlagen über stufengerechte Szenarien bis zu Aussprache und Wiederholung.';

  @override
  String get settingsOriginStoryFounder =>
      'Sujin Park · Gründerin von Hangul Sori';

  @override
  String settingsVersion(Object v) {
    return 'Version $v';
  }

  @override
  String get settingsPrivacyTitle => 'Datenschutzerklärung';

  @override
  String get settingsPrivacySubtitle => 'Link kopieren';

  @override
  String settingsPrivacyCopied(Object url) {
    return 'Link kopiert: $url';
  }

  @override
  String get settingsPrivacySection => 'Datenschutz';

  @override
  String get settingsAnalyticsTitle => 'Nutzungsstatistiken';

  @override
  String get settingsAnalyticsDesc =>
      'Anonyme App-Nutzung teilen (Firebase Analytics)';

  @override
  String get settingsCrashTitle => 'Absturzberichte';

  @override
  String get settingsCrashDesc =>
      'Hilft uns, Fehler schneller zu beheben (Crashlytics)';

  @override
  String get settingsTermsTitle => 'Nutzungsbedingungen';

  @override
  String get settingsImpressumTitle => 'Impressum';

  @override
  String get settingsLicensesTitle => 'Open-Source-Lizenzen';

  @override
  String get settingsLicensesSubtitle => 'Verwendete Bibliotheken';

  @override
  String get settingsDataSourcesTitle => 'Datenquellen';

  @override
  String get settingsDataSourcesSubtitle =>
      'Wörterbücher, Frequenzlisten, Übersetzungen';

  @override
  String get settingsDataSourcesIntro =>
      'Die Inhalte dieser App bauen auf öffentlich zugänglichen Sprachdaten auf. Jede Quelle ist hier mit Lizenz und Attribution genannt.';

  @override
  String get settingsDataLicenseNote => 'CC BY-SA 2.0 KR Hinweis';

  @override
  String get settingsDataLicenseBody =>
      'Korea-Wörterbuchdaten (Definitionen, Übersetzungen) stammen aus 우리말샘 (National Institute of Korean Language) und stehen unter CC BY-SA 2.0 KR. Abgeleitete Inhalte (z. B. die in dieser App enthaltenen JSON-Dateien) werden unter derselben Lizenz weitergegeben.';

  @override
  String get statsHeader => 'Dein Fortschritt';

  @override
  String get statsCardsLearned => 'Karten gelernt';

  @override
  String get statsAccuracy => 'Genauigkeit';

  @override
  String get statsStreak => 'Streak';

  @override
  String get statsBestStreak => 'Bester Streak';

  @override
  String get statsStreakShield => 'Streak-Schutz';

  @override
  String get statsStreakShieldHint => 'Schützt einen verpassten Tag.';

  @override
  String get statsWordleWins => 'Silben-Rätsel-Siege';

  @override
  String get statsWordleStreak => 'Silben-Rätsel-Streak';

  @override
  String get screenVocabTitle => 'Karteikarten';

  @override
  String get screenGrammarTitle => 'Grammatik';

  @override
  String get screenWordleTitle => 'Silben-Rätsel';

  @override
  String get silbenEmptyBody =>
      'Für deine Lernstufe sind noch keine Silben-Rätsel vorbereitet.';

  @override
  String get screenHangulTitle => 'Hangul';

  @override
  String get filterOpenBtn => 'Filter öffnen';

  @override
  String get hangulTabOverview => 'Übersicht';

  @override
  String get hangulTabCards => 'Karten';

  @override
  String get hangulTabWrite => 'Schreiben';

  @override
  String get hangulConsonantsLabel => '자음 · Konsonanten';

  @override
  String get hangulVowelsLabel => '모음 · Vokale';

  @override
  String get hangulSyllableLabel => '🧩 음절 구조 · Silbenaufbau';

  @override
  String get hangulPronounceBtn => 'Aussprechen';

  @override
  String get hangulRulesTitle => 'Hangul-Schreibregeln';

  @override
  String get hangulRulesBody =>
      '① Oben → Unten   ② Horizontal → Vertikal   ③ Links → Rechts';

  @override
  String get hangulStrokeOrderTitle =>
      '📽 Strichreihenfolge (zum Wiederholen tippen)';

  @override
  String get hangulTraceTitle => 'Mit dem Finger nachzeichnen';

  @override
  String get hangulClearBtn => 'Löschen';

  @override
  String hangulPronounceLetter(Object letter) {
    return '$letter aussprechen';
  }

  @override
  String get hangulChipConsonants => 'Konsonanten';

  @override
  String get hangulChipVowels => 'Vokale';

  @override
  String get hangulChipSyllables => 'Silben';

  @override
  String get hangulCheckModeLabel => 'Strichprüfung';

  @override
  String get hangulCheckModePractice => 'Frei üben';

  @override
  String get hangulCheckModeExam => 'Streng';

  @override
  String get hangulCheckModePracticeHint =>
      'Du bekommst Hinweise, aber nichts wird gelöscht.';

  @override
  String get hangulCheckModeExamHint =>
      'Reihenfolge und Richtung müssen stimmen.';

  @override
  String hangulStrokeProgress(int current, int total) {
    return 'Strich $current / $total';
  }

  @override
  String hangulStrokeNextHint(int index) {
    return 'Jetzt Strich $index zeichnen.';
  }

  @override
  String hangulStrokeWrongOrder(int drawn, int expected) {
    return 'Das ist Strich $drawn. Zeichne zuerst Strich $expected.';
  }

  @override
  String hangulStrokeWrongDirection(int index) {
    return 'Richtige Linie, falsche Richtung. Strich $index läuft andersherum.';
  }

  @override
  String hangulStrokeWrongShape(int index) {
    return 'Das passt zu keinem Strich. Sieh dir Strich $index links an.';
  }

  @override
  String get hangulStrokeTooShort => 'Zu kurz. Zieh den Strich in einem Zug.';

  @override
  String hangulStrokeLetterDone(Object letter) {
    return '$letter sitzt! Weiter zum nächsten.';
  }

  @override
  String hangulLettersDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Buchstaben fertig',
      one: '1 Buchstabe fertig',
    );
    return '$_temp0';
  }

  @override
  String get hangulHardOnly => 'Nur schwierige';

  @override
  String get chosungModeWithVowels => 'Anlaut + Vokal';

  @override
  String get chosungModeInitialsOnly => 'Nur Anlaute';

  @override
  String get chosungSlotVowel => 'Vokal';

  @override
  String get chosungSlotBatchim => 'Batchim';

  @override
  String get errorUnknown => 'Unbekannter Fehler';

  @override
  String questTypeUnsupported(Object type) {
    return 'Quest-Typ \"$type\" ist noch nicht verfügbar.';
  }

  @override
  String get customPackCsvHint => '안녕하세요, Hallo\\n사과, Apfel';

  @override
  String get packStateLocked => 'gesperrt';

  @override
  String get packStatePremium => 'Premium';

  @override
  String get packStateCleared => 'geschafft';

  @override
  String get packStateAvailable => 'verfügbar';

  @override
  String packSemantics(Object title, Object state, int learned, int total) {
    return 'Paket $title, $state, $learned von $total gelernt';
  }

  @override
  String get packLockedHintShort => 'Vorher freischalten';

  @override
  String smalltalkUseWith(Object context) {
    return 'Passend für: $context';
  }

  @override
  String get smalltalkSaferAlternativeAndNext =>
      'Sichere Alternative und nächster Schritt';

  @override
  String get smalltalkSaferAlternative => 'Sichere Alternative';

  @override
  String get smalltalkNextTurn => 'Nächster Gesprächsschritt';

  @override
  String get smalltalkNextPhrase => 'Nächster Ausdruck';

  @override
  String get smalltalkPreviousPhrase => 'Vorheriger Ausdruck';

  @override
  String wordleSyllableCount(int n) {
    return '$n-Silben-Wort · 6 Versuche';
  }

  @override
  String wordleMeaning(Object german) {
    return 'Bedeutung: $german';
  }

  @override
  String wordleAnswerLabel(Object target) {
    return 'Antwort: $target';
  }

  @override
  String wordleInputHint(int n) {
    return '$n Silben eingeben …';
  }

  @override
  String get wordleLegendCorrect => 'Richtige Stelle';

  @override
  String get wordleLegendPresent => 'Falsche Stelle';

  @override
  String get wordleLegendAbsent => 'Nicht enthalten';

  @override
  String get wordleSubmitBtn => 'Prüfen';

  @override
  String get wordleNewWordBtn => 'Neues Wort';

  @override
  String get wordleHelpTooltip => 'Spielanleitung';

  @override
  String get wordleShuffleTooltip => 'Neues Wort';

  @override
  String get settingsAdsSection => 'Anzeigen';

  @override
  String get settingsShowAds => 'Werbung anzeigen';

  @override
  String get settingsShowAdsDesc => 'Hilft beim Erhalten der App';

  @override
  String get placeholderComingSoon => 'Bald verfügbar 🚧';

  @override
  String get chosungSubmitBtn => 'Bestätigen';

  @override
  String get chosungHintBtn => 'Hinweis';

  @override
  String chosungAnswerLabel(Object word) {
    return 'Antwort: $word';
  }

  @override
  String get chosungRoundDoneTitle => 'Runde abgeschlossen!';

  @override
  String chosungRoundAccuracy(int percent) {
    return '$percent% richtig';
  }

  @override
  String chosungRoundAvgTime(Object seconds) {
    return 'Ø ${seconds}s pro Frage';
  }

  @override
  String get chosungRoundContinue => 'Weitermachen';

  @override
  String chosungRoundLevelUp(Object level) {
    return 'Stark! Probier Stufe $level aus.';
  }

  @override
  String chosungRoundKeepLevel(Object level) {
    return 'Gut gemacht. Bleib noch bei Stufe $level.';
  }

  @override
  String chosungRoundReview(Object level) {
    return 'Kein Problem. Üb Stufe $level noch einmal.';
  }

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsSubtitle => 'Dein Lernfortschritt';

  @override
  String get statsDays => 'Tage';

  @override
  String get statsThisWeek => 'Diese Woche';

  @override
  String get statsCards => 'Karten';

  @override
  String get statsPercent => 'Genauigkeit';

  @override
  String get statsWins => 'Siege';

  @override
  String get statsEmpty =>
      'Noch keine Daten. Starte mit deiner ersten Übung. 🚀';

  @override
  String get statsVokSection => 'Vokabeln';

  @override
  String get statsGamesSection => 'Spiele';

  @override
  String get statsStreakSection => 'Streak';

  @override
  String statsBestLabel(int n) {
    return 'Bester: $n';
  }

  @override
  String get vocabModeAll => 'Alle';

  @override
  String get vocabModeDue => 'Heute fällig';

  @override
  String vocabDueBadge(int n) {
    return '$n fällig';
  }

  @override
  String vocabTodayBadge(int newCount, int reviewCount) {
    return 'Heute ($newCount neu · $reviewCount Wdh.)';
  }

  @override
  String get vocabDueEmpty => 'Heute alles erledigt!\nKomm morgen wieder.';

  @override
  String get vocabDueEmptyAction => 'Trotzdem üben';

  @override
  String get vocabPacksTitle => 'Vokabel-Pakete';

  @override
  String get vocabPacksLevelMenu => 'Level wechseln';

  @override
  String get vocabPacksScopedHint => 'Nur Pakete für deine aktuelle Mission.';

  @override
  String get vocabPacksBrowseAllCta => 'Alle Vokabel-Pakete ansehen';

  @override
  String vocabPacksProgressLabel(int cleared, int total) {
    return '$cleared/$total Pakete geschafft';
  }

  @override
  String get vocabPacksEmptyTitle => 'Noch keine Pakete';

  @override
  String get vocabPacksEmptyBody =>
      'Für dieses Level sind noch keine Vokabeln vorbereitet.';

  @override
  String get vocabPackLockedNoPrev => 'Dieses Paket ist noch gesperrt.';

  @override
  String vocabPackLockedHint(Object prev) {
    return 'Schließe zuerst „$prev“ mit ≥ 70 % ab.';
  }

  @override
  String get bookCaptureTitle => 'Buchseite einlesen';

  @override
  String get bookCaptureHero => 'Fotografiere eine Lehrbuchseite';

  @override
  String get bookCaptureSubtitle =>
      'Seite gerade, scharf und eng zugeschnitten aufnehmen. Das Bild bleibt auf deinem Gerät; nur erkannter Text wird analysiert.';

  @override
  String get bookCaptureCamera => 'Kamera';

  @override
  String get bookCaptureGallery => 'Aus Galerie';

  @override
  String get bookCaptureLoading => 'Texterkennung läuft …';

  @override
  String get bookCaptureErrorNoKorean =>
      'Kein verlässliches Koreanisch erkannt. Fotografiere die Seite gerade, scharf und näher.';

  @override
  String get bookCaptureErrorPermission =>
      'Berechtigung verweigert. Du kannst es in den Einstellungen erlauben.';

  @override
  String get bookCaptureErrorQuota =>
      'Tägliches Limit erreicht (20 Seiten). Komm morgen wieder.';

  @override
  String get bookCaptureErrorOcr => 'Texterkennung fehlgeschlagen.';

  @override
  String get bookCaptureErrorUnknown => 'Unerwarteter Fehler.';

  @override
  String get bookCropTitle => 'Bereich zuschneiden';

  @override
  String get bookPreviewTitle => 'Text prüfen';

  @override
  String bookPreviewHint(int count) {
    return '$count Textzeilen erkannt. Vergleiche und korrigiere sie bei Bedarf.';
  }

  @override
  String get bookPreviewTextFieldHint => 'Koreanischer Text …';

  @override
  String get bookPreviewEditorLabel => 'Erkannter Text';

  @override
  String get bookPreviewQualityWarning =>
      'Unsichere oder nicht unterstützte Schrift wurde entfernt. Prüfe den koreanischen Text vor der Analyse sorgfältig.';

  @override
  String get bookPreviewSevereQualityWarning =>
      'Die Aufnahme oder Texterkennung ist zu unsicher. Nimm das Foto am besten neu auf. Wenn du trotzdem fortfahren möchtest, korrigiere zuerst selbst den OCR-Text.';

  @override
  String get bookPreviewAnalyze => 'Analysieren';

  @override
  String get bookPreviewRetake => 'Neu aufnehmen';

  @override
  String get bookResultTitle => 'Ergebnis';

  @override
  String get loadErrorTryAgain =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get bookResultAnalyzing => 'Wörter & Grammatik werden analysiert …';

  @override
  String bookResultFoundN(int n) {
    return '$n neue Wörter gefunden';
  }

  @override
  String get dojangTitle => 'Stempelbuch';

  @override
  String get dojangEmptyTitle => 'Noch keine Stempel';

  @override
  String get dojangEmptyBody =>
      'Schließ Vokabelpakete ab und sammle Dancheong-Stempel.';

  @override
  String get dojangEmptyCta => 'Vokabelpakete öffnen';

  @override
  String dojangProgress(int earned, int total) {
    return '$earned von $total Stempeln gesammelt';
  }

  @override
  String get dojangSeriesDancheongTitle => 'Dancheong-Muster';

  @override
  String get dojangSeriesDancheongBody =>
      'Traditionelle Farb- und Ornamentmotive aus der bisherigen Sammlung.';

  @override
  String get dojangSeriesLivingCultureTitle => 'Koreanische Alltagskultur';

  @override
  String get dojangSeriesLivingCultureBody =>
      'Gegenstände, Zeichen und Glücksmotive aus Lernen, Wohnen, Essen und Alltag.';

  @override
  String dojangReconciled(int count) {
    return 'In deinen Abschlüssen wurden $count neue Stempel gefunden.';
  }

  @override
  String get gyeEntryTitle => 'Lern-Gye';

  @override
  String get gyeEntryDesc => 'Gemeinsam ein Hanok bauen';

  @override
  String get gyeChooserTitle => 'Gye (Lerngruppe)';

  @override
  String get gyeChooserCreate => 'Gye erstellen';

  @override
  String get gyeChooserJoin => 'Mit Code beitreten';

  @override
  String get gyeCreateTitle => 'Gye erstellen';

  @override
  String get gyeJoinTitle => 'Gye beitreten';

  @override
  String get gyeNameLabel => 'Gye-Name';

  @override
  String get gyeNameHint => 'z. B. Morgentiger';

  @override
  String get gyeNicknameLabel => 'Dein Spitzname';

  @override
  String get gyeNicknameHint => 'Für alle im Gye sichtbar';

  @override
  String get gyeCodeLabel => 'Beitrittscode';

  @override
  String get gyeCodeInputLabel => '6-stelliger Code';

  @override
  String get gyeCreateCta => 'Erstellen';

  @override
  String get gyeJoinCta => 'Beitreten';

  @override
  String get gyeCreatingLoading => 'Gye wird erstellt…';

  @override
  String get gyeJoiningLoading => 'Gye-Beitritt läuft…';

  @override
  String get gyeCreatedTitle => 'Gye erstellt!';

  @override
  String gyeCreatedAnnouncement(Object name, Object code) {
    return 'Gye $name wurde erstellt. Beitrittscode: $code.';
  }

  @override
  String get gyeShareCode => 'Code teilen';

  @override
  String get gyeInviteTitle => 'Lade Freunde ein';

  @override
  String get gyeInviteBody =>
      'Teile den Code mit Freunden, damit sie deinem Gye beitreten können.';

  @override
  String get gyeCopyCode => 'Code kopieren';

  @override
  String get gyeCodeCopied => 'Code kopiert';

  @override
  String gyeShareMessage(Object code) {
    return 'Tritt meinem Hangul-Sori-Gye bei! Code: $code';
  }

  @override
  String gyeJoinedSnack(Object name) {
    return '$name ist beigetreten!';
  }

  @override
  String get gyeErrNetwork => 'Netzwerkfehler. Bitte erneut versuchen.';

  @override
  String get gyeErrNotFound => 'Kein Gye für diesen Code gefunden.';

  @override
  String get gyeErrFull => 'Dieses Gye ist voll (max. 10).';

  @override
  String get gyeErrTooMany => 'Du kannst höchstens 3 Gye beitreten.';

  @override
  String get gyeErrName => 'Bitte gib einen gültigen Gye-Namen ein.';

  @override
  String get gyeErrNickname => 'Bitte gib einen gültigen Spitznamen ein.';

  @override
  String get gyeErrProfanity => 'Bitte wähle ein anderes Wort.';

  @override
  String get gyeErrAgeRestricted =>
      'Gye ist ab 16 Jahren nutzbar. Da nur dein lokal selbst angegebenes Geburtsjahr gespeichert wird, prüft die App konservativ und schaltet erst bei mindestens 17 Jahren Jahresdifferenz frei.';

  @override
  String get gyeAgeYearTitle => 'Geburtsjahr';

  @override
  String get gyeAgeYearBody =>
      'Gye ist ab 16 Jahren nutzbar. Dein Geburtsjahr ist eine Selbstauskunft, wird nur auf diesem Gerät gespeichert und ist keine Identitätsprüfung. Ohne Monat und Tag wird konservativ erst bei mindestens 17 Jahren Jahresdifferenz freigeschaltet.';

  @override
  String get gyeAgeYearHint => 'z. B. 2005';

  @override
  String get gyeOpenCta => 'Gye öffnen';

  @override
  String get gyeTitle => 'Gye';

  @override
  String get gyeNotFoundTitle => 'Gye nicht gefunden';

  @override
  String get gyeNotFoundBody => 'Dieses Gye wurde möglicherweise entfernt.';

  @override
  String gyeMembersN(int count) {
    return '$count Mitglieder';
  }

  @override
  String get gyeWeeklyGoal => 'Wochenziel';

  @override
  String get gyeNoGoal => 'Noch kein Wochenziel';

  @override
  String get gyeDureTitle => 'Diese Woche zusammen';

  @override
  String get gyeDureMe => 'Ich';

  @override
  String get gyeDureEmpty =>
      'Noch leer. Schließ ein Paket ab und mach den Anfang.';

  @override
  String get gyeChallengeTitle => 'Alle dabei?';

  @override
  String get gyeChallengeDone => 'Alle dabei!';

  @override
  String get dureTitleDuru => 'Stütze';

  @override
  String get dureTitleNewcomer => 'Neu dabei';

  @override
  String get dureTitleSprout => 'Spross';

  @override
  String get dureTitleHelper => 'Mit dabei';

  @override
  String get gyeFeedTitle => 'Aktivität';

  @override
  String get gyeFeedEmpty =>
      'Noch keine Aktivität. Schließt gemeinsam ein Paket ab.';

  @override
  String gyeFeedPackCleared(Object name) {
    return '$name hat ein Paket abgeschlossen';
  }

  @override
  String gyeFeedQuest(Object name) {
    return '$name hat eine Quest abgeschlossen';
  }

  @override
  String gyeFeedLevelUp(Object name) {
    return '$name ist aufgestiegen';
  }

  @override
  String gyeFeedSticker(Object name) {
    return '$name hat einen Sticker gesendet';
  }

  @override
  String get gyeCheer1 => 'Zusammen!';

  @override
  String get gyeCheer2 => 'Du schaffst das!';

  @override
  String get gyeCheer3 => 'Du fehlst uns!';

  @override
  String get gyeCheer4 => 'Fast geschafft!';

  @override
  String get gyeCheer5 => 'Auf geht\'s!';

  @override
  String get gyeCheerTitle => 'Anfeuern';

  @override
  String get gyeFeedGoalAchieved => 'Wochenziel erreicht! Euer Hanok wächst.';

  @override
  String get gyeFeedAllIn => 'Alle haben diese Woche beigetragen!';

  @override
  String gyeFeedGoalAchievedMvp(int packs, Object mvp) {
    String _temp0 = intl.Intl.pluralLogic(
      packs,
      locale: localeName,
      other: '$packs Pakete',
      one: '1 Paket',
    );
    return 'Wochenziel erreicht! $_temp0 · MVP $mvp';
  }

  @override
  String get gyeStickerSend => 'Sticker senden';

  @override
  String get gyeStickerRateLimited =>
      'Zu viele Sticker auf einmal. Versuch es gleich noch einmal.';

  @override
  String get gyeStickerCatTiger => 'Tiger';

  @override
  String get gyeStickerCatMagpie => 'Elster';

  @override
  String get gyeStickerCatDancheong => 'Dancheong';

  @override
  String get gyeStickerCatHangul => 'Hangul';

  @override
  String get gyeStickerCatFood => 'Essen';

  @override
  String get gyeStickerCatStamp => 'Stempel';

  @override
  String get gyeLeave => 'Gye verlassen';

  @override
  String get gyeLeaveConfirm => 'Dieses Gye verlassen?';

  @override
  String get gyeOwnerLeaveUnavailable =>
      'Als Leitung kannst du das Gye erst nach einer Übertragung oder Löschung verlassen.';

  @override
  String get gyeMembersTitle => 'Mitglieder';

  @override
  String get gyeMemberSelf => 'Du';

  @override
  String get gyeRoleOwner => 'Leiter';

  @override
  String get gyeReportTitle => 'Mitglied melden';

  @override
  String get gyeReportReasonSpam => 'Spam';

  @override
  String get gyeReportReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get gyeReportReasonHarassment => 'Belästigung';

  @override
  String get gyeReportReasonOther => 'Sonstiges';

  @override
  String get gyeReportNoteHint => 'Notiz (optional)';

  @override
  String get gyeReportSubmit => 'Melden';

  @override
  String get gyeReportSent => 'Meldung gesendet. Danke.';

  @override
  String get gyeBlockTitle => 'Mitglied blockieren?';

  @override
  String get gyeBlockBody =>
      'Du siehst keine Sticker, Anfeuerungen oder Beiträge dieser Person mehr. Du kannst die Blockierung jederzeit in der Mitgliederliste aufheben.';

  @override
  String get gyeBlockConfirm => 'Blockieren';

  @override
  String get gyeUnblock => 'Blockierung aufheben';

  @override
  String get gyeBlockedLabel => 'Blockiert';

  @override
  String get gyeBlockedSnack =>
      'Mitglied blockiert. Beiträge werden ausgeblendet.';

  @override
  String gyeMvpCard(Object name, int packs) {
    String _temp0 = intl.Intl.pluralLogic(
      packs,
      locale: localeName,
      other: '$packs Pakete',
      one: '1 Paket',
    );
    return 'Applaus für $name: $_temp0 letzte Woche! 👏';
  }

  @override
  String gyeProfileLevel(Object level) {
    return 'Level $level';
  }

  @override
  String gyeProfileStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage Streak',
      one: '1 Tag Streak',
    );
    return '$_temp0';
  }

  @override
  String gyeProfileWeekly(int packs) {
    String _temp0 = intl.Intl.pluralLogic(
      packs,
      locale: localeName,
      other: '$packs Pakete diese Woche',
      one: '1 Paket diese Woche',
    );
    return '$_temp0';
  }

  @override
  String get gyeAllInCelebrate => 'Alle haben diese Woche beigetragen!';

  @override
  String get gyeReactTooltip => 'Reagieren';

  @override
  String get bookResultOfflineNotice =>
      'Server nicht erreichbar. Es wurden nur Grammatikmuster offline erkannt.';

  @override
  String get bookResultCredentialsNotice =>
      'Die geschützte Analyse ist auf diesem Gerät nicht verfügbar. Melde dich an, prüfe die Verbindung und versuche es erneut.';

  @override
  String get bookResultRateLimited =>
      'Cloud-Analyse-Limit erreicht. Bitte versuche es in einer Minute erneut.';

  @override
  String get bookResultQualityNotice =>
      'Unsichere oder nicht-koreanische Inhalte wurden nicht in Wörter, Grammatik oder Audio übernommen.';

  @override
  String get bookResultTranslationUnavailable =>
      'Der Übersetzungsdienst hat nicht alle Bedeutungen geliefert. Prüfe das Ergebnis vor dem Speichern oder versuche es erneut.';

  @override
  String get bookResultNoKoreanNotice =>
      'Es blieb kein verlässlicher koreanischer Text übrig. Bitte prüfe den Text oder nimm die Seite neu auf.';

  @override
  String get bookResultSectionWords => 'Wörter';

  @override
  String get bookResultSectionExpressions => 'Ausdrücke';

  @override
  String get bookResultSectionGrammar => 'Grammatik';

  @override
  String get bookResultSectionSentences => 'Sätze';

  @override
  String bookStudyAskTitle(String name) {
    return 'Frag $name zu diesem Eintrag';
  }

  @override
  String get bookStudyAskGenericTitle => 'Fragen zu diesem Eintrag';

  @override
  String get bookStudyAskButton => 'Begleiter fragen';

  @override
  String get bookStudyAskWhyForm => 'Warum sieht diese Form so aus?';

  @override
  String get bookStudyAskExample => 'Zeig ein Beispiel von dieser Seite';

  @override
  String get bookStudyAskCompare => 'Mit ähnlicher Grammatik vergleichen';

  @override
  String get bookStudyAskQuiz => 'Stell mir eine kurze Aufgabe';

  @override
  String get bookStudyAskMeaning => 'Was bedeutet das?';

  @override
  String get bookStudyAskGrammarInSentence =>
      'Welche Grammatik wird hier verwendet?';

  @override
  String get bookStudyNoEvidence =>
      'Dafür habe ich in der Analyse dieser Seite keinen Beleg gefunden.';

  @override
  String get bookStudyAdditionalExample => 'Weiteres belegtes Beispiel';

  @override
  String get bookStudyQuizPrompt =>
      'Antworte nur mit den Belegen auf dieser Seite.';

  @override
  String get bookStudyShowAnswer => 'Antwort zeigen';

  @override
  String get bookStudyTaegoAnswerLead => 'Prüfen wir es Schritt für Schritt.';

  @override
  String get bookStudyJoyAnswerLead => 'Hier ist die Kurzfassung!';

  @override
  String get bookStudyTaegoIntro => 'Ich zeige dir genau die belegte Stelle.';

  @override
  String get bookStudyJoyIntro =>
      'Schauen wir uns die belegte Stelle gemeinsam an!';

  @override
  String get bookStudyGenericIntro =>
      'Die Antwort stammt nur aus dem geprüften Analyseergebnis.';

  @override
  String get bookStudyEvidenceLabel => 'Beleg aus dieser Seite';

  @override
  String get bookResultSave => 'In meinem Bücherregal speichern';

  @override
  String get bookResultSaving => 'Seite wird gespeichert…';

  @override
  String get bookResultSaveUnresolved =>
      'Speicherstatus konnte nicht bestätigt werden';

  @override
  String get bookResultSaveUnresolvedBody =>
      'Prüfe dein Bücherregal, bevor du erneut versuchst, diese Seite zu speichern.';

  @override
  String get bookResultSaved => 'Seite gespeichert.';

  @override
  String get bookResultBackToCapture => 'Weitere Seite einlesen';

  @override
  String get questsTitle => 'Spezial-Quests';

  @override
  String get questsEmptyTitle => 'Noch keine Quests';

  @override
  String get questsEmptyBody =>
      'Beginne ein Paket. Dein Quest-Fortschritt erscheint dann hier.';

  @override
  String get questsSectionInProgress => 'Läuft';

  @override
  String questsInProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Quests laufen',
      one: '1 Quest läuft',
    );
    return '$_temp0';
  }

  @override
  String questsRewardSemantics(String reward) {
    return 'Belohnung: $reward';
  }

  @override
  String get questsSectionAvailable => 'Verfügbar';

  @override
  String get questsSectionCompleted => 'Abgeschlossen';

  @override
  String get questsSectionSeasonalLocked => 'Saisonal (gesperrt)';

  @override
  String get questsSeasonalBadge => 'Saison';

  @override
  String get questsCompletionCelebration =>
      'Neue Dekoration für deine Stube freigeschaltet!';

  @override
  String get questsOpenGiftCta => 'Bündel öffnen';

  @override
  String get homeBojagiTitle => 'Ein Geschenk wartet';

  @override
  String homeBojagiBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bündel warten. Öffne sie und richte deine Stube ein.',
      one: 'Ein Bündel wartet. Öffne es und richte deine Stube ein.',
    );
    return '$_temp0';
  }

  @override
  String get dojangDecorHintBody =>
      'Deine gesammelten Dancheong-Stempel sind jetzt auch Gestaltungselemente. Platziere sie frei in deiner Sarangbang; im Stempelbuch bleiben sie weiterhin sichtbar.';

  @override
  String get dojangDecorHintCta => 'Sarangbang gestalten';

  @override
  String dojangStampEarned(String stamp) {
    return '$stamp, gesammelt';
  }

  @override
  String dojangStampLocked(String stamp) {
    return '$stamp, noch nicht gesammelt';
  }

  @override
  String get hanokCinematicIntro => 'Dein Hanok wächst.';

  @override
  String get hanokA1MapLabel => 'Dein Hanok im Bau';

  @override
  String get hanokA1MapUnavailable => 'Hanok-Illustration nicht verfügbar';

  @override
  String get hanokStageEmpty => 'Bauplatz vorbereiten';

  @override
  String get hanokStageFoundation => 'Sockel legen';

  @override
  String get hanokStagePillars => 'Säulen aufstellen';

  @override
  String get hanokStageBeams => 'Dachstuhl bauen';

  @override
  String get hanokStageThatch => 'Strohdach gedeckt';

  @override
  String get hanokStageTilePartial => 'Ziegel auflegen';

  @override
  String get hanokStageTileComplete => 'Ziegeldach fertig';

  @override
  String get hanokStageDancheong => 'Dancheong gemalt';

  @override
  String get hanokStageGate => 'Tor errichtet';

  @override
  String get hanokStageWindows => 'Gitterfenster eingebaut';

  @override
  String get hanokStageSideBuilding => 'Nebengebäude angebaut';

  @override
  String get hanokStageJongga => 'Jongga vollendet';

  @override
  String get vocabPackPlayTitle => 'Paket-Übung';

  @override
  String get vocabPackFinishSaveError =>
      'Dein Fortschritt konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get vocabPackLearnHint => 'Tippen zum Umdrehen';

  @override
  String vocabPackLearnRepeatSuffix(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wdh.',
      one: '1 Wdh.',
    );
    return ' · +$_temp0';
  }

  @override
  String get vocabPackDontKnow => 'Weiß ich nicht';

  @override
  String get vocabPackGotIt => 'Gewusst';

  @override
  String get deckActionSave => 'Merken';

  @override
  String get contentActionFlip => 'Umdrehen';

  @override
  String get contentActionLike => 'Gefällt mir';

  @override
  String get contentActionShare => 'Teilen';

  @override
  String get contentActionBookmark => 'Merken';

  @override
  String get contentActionBookmarkSaved => 'Gemerkt';

  @override
  String get contentActionBookmarkUnsaved => 'Nicht gemerkt';

  @override
  String get contentActionLikeLiked => 'Gelikt';

  @override
  String get contentActionLikeNotLiked => 'Nicht gelikt';

  @override
  String get speechIndicatorLabel => 'Vorlesen';

  @override
  String get speechIndicatorSpeaking => 'Wird vorgelesen';

  @override
  String get speechIndicatorIdle => 'Nicht aktiv';

  @override
  String contentShareBody(String korean, String gloss) {
    return '$korean\n$gloss\nhangul-sori.com';
  }

  @override
  String get contentShareFailedTitle => 'Das Bild konnte nicht geteilt werden';

  @override
  String get contentShareFailedBody =>
      'Versuche es erneut oder kopiere stattdessen den Text.';

  @override
  String get contentShareRetry => 'Erneut versuchen';

  @override
  String get contentShareCopyText => 'Text kopieren';

  @override
  String get contentShareCopied => 'Text kopiert';

  @override
  String get contentShareCopyFailed => 'Der Text konnte nicht kopiert werden.';

  @override
  String get deckFlipFirstHint => 'Erst antippen und umdrehen';

  @override
  String get coachSoriDeckTitle => 'Karte weiterwischen';

  @override
  String get coachSoriDeckBody =>
      'Wische nach oben oder unten zur nächsten Karte. ? dreht um, Herz merkt für später, Lesezeichen legt ins Wörterbuch.';

  @override
  String get coachSoriDeckBodyNoSave =>
      'Wische nach oben oder unten zur nächsten Karte. ? dreht um, Herz merkt für später.';

  @override
  String get vocabPackStageLearn => 'Lernen';

  @override
  String get vocabPackStageQuiz => 'Quiz';

  @override
  String get vocabPackStageBoss => 'Boss';

  @override
  String get vocabPackQuizHint => 'Wähle die richtige Übersetzung';

  @override
  String get vocabPackBossHint => 'Hör zu und wähle';

  @override
  String get vocabPackBossReplayAudio => 'Erneut anhören';

  @override
  String get vocabPackTapToFlip => 'Tippen zum Umdrehen';

  @override
  String get vocabPackResultTitle => 'Ergebnis';

  @override
  String get vocabPackResultCleared => 'Paket abgeschlossen!';

  @override
  String get vocabPackResultClearedAgain =>
      'Schon abgeschlossen. Gut wiederholt!';

  @override
  String get vocabPackResultRetry => 'Fast geschafft. Versuch es noch einmal!';

  @override
  String get vocabPackResultBossLabel => 'Boss-Genauigkeit';

  @override
  String get vocabPackResultQuizLabel => 'Quiz';

  @override
  String get vocabPackResultXpLabel => 'Belohnung';

  @override
  String vocabPackResultNextPack(Object next) {
    return 'Weiter zu \"$next\"';
  }

  @override
  String get vocabPackResultRetryCta => 'Nochmal versuchen';

  @override
  String get vocabPackResultRecallCta => 'Auf Koreanisch abrufen';

  @override
  String get vocabPackResultHardWordsCta => 'Schwierige Wörter üben';

  @override
  String get vocabPackResultBackToGrid => 'Zurück zu den Paketen';

  @override
  String get vocabPackResultGeschafft =>
      'Geschafft! Wiederhole diese Wörter später noch einmal.';

  @override
  String get vocabPackRecallTitle => 'Aus dem Gedächtnis';

  @override
  String get vocabPackRecallIntro =>
      'Optional: Sieh die Bedeutung und tippe das koreanische Wort.';

  @override
  String get vocabPackRecallPrompt => 'Wie heißt das auf Koreanisch?';

  @override
  String get vocabPackRecallInputHint => 'Auf Koreanisch eingeben …';

  @override
  String get vocabPackRecallHintCta => 'Erste Silbe zeigen';

  @override
  String vocabPackRecallHintLabel(Object hint) {
    return 'Beginnt mit „$hint“';
  }

  @override
  String get vocabPackRecallShowAnswerCta => 'Antwort zeigen';

  @override
  String get vocabPackRecallCorrect => 'Richtig. Direkt erinnert.';

  @override
  String get vocabPackRecallCorrectWithHint => 'Richtig, mit Hinweis.';

  @override
  String get vocabPackRecallIncorrect => 'Nicht ganz.';

  @override
  String get vocabPackRecallRevealed => 'Antwort gezeigt.';

  @override
  String vocabPackRecallAnswer(Object answer) {
    return 'Richtig: $answer';
  }

  @override
  String get vocabPackRecallDoneTitle => 'Abrufübung beendet';

  @override
  String vocabPackRecallDoneScore(int correct, int total) {
    return '$correct von $total direkt erinnert';
  }

  @override
  String get vocabPackRecallReviewLater =>
      'Wiederhole diese Wörter später noch einmal.';

  @override
  String get vocabPackRecallBackToResult => 'Zurück zum Ergebnis';

  @override
  String get vocabPackRecallNoBossWords =>
      'Dieses Paket hat keine Boss-Wörter für die Tippübung.';

  @override
  String get moduleStatsTitle => 'Statistik';

  @override
  String get moduleStatsDesc => 'Streak, Karten, Genauigkeit';

  @override
  String get settingsCloudSection => 'Cloud-Backup';

  @override
  String settingsCloudSignedIn(Object name) {
    return 'Angemeldet: $name';
  }

  @override
  String get settingsCloudSignInPrompt => 'Mit Google sichern';

  @override
  String get settingsCloudSignedInDesc => 'Daten werden in der Cloud gesichert';

  @override
  String get settingsCloudSignInDesc =>
      'Damit überlebt dein Fortschritt einen Handywechsel';

  @override
  String get settingsCloudBackupNow => 'Jetzt sichern';

  @override
  String get settingsCloudRestore => 'Von Cloud wiederherstellen';

  @override
  String get settingsCloudBackupSuccess => 'Backup erfolgreich ✓';

  @override
  String get settingsCloudRestoreSuccess => 'Wiederhergestellt ✓';

  @override
  String get settingsCloudRestoreEmpty => 'Keine Cloud-Daten';

  @override
  String settingsCloudAuthFailed(Object error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get settingsCloudDeleteData => 'Cloud-Daten löschen';

  @override
  String get settingsCloudDeleteDataDesc =>
      'Löscht dein Firestore-Backup. Lokale Fortschritte auf diesem Gerät bleiben erhalten.';

  @override
  String get settingsCloudDeleteDataConfirmTitle => 'Cloud-Daten löschen?';

  @override
  String get settingsCloudDeleteDataConfirmBody =>
      'Dadurch wird das Cloud-Backup deines Firebase-Kontos gelöscht. Deine lokalen Fortschritte auf diesem Gerät bleiben erhalten.';

  @override
  String get settingsCloudDeleteDataSuccess => 'Cloud-Daten gelöscht';

  @override
  String get settingsCloudDeleteDataFailed =>
      'Cloud-Daten konnten nicht gelöscht werden.';

  @override
  String get settingsAccountDelete => 'Konto und alle Daten löschen';

  @override
  String get settingsAccountDeleteDesc =>
      'Löscht dein Firebase-Konto, Cloud-Backup und lokale Fortschritte.';

  @override
  String get settingsAccountDeleteConfirmTitle => 'Konto dauerhaft löschen?';

  @override
  String get settingsAccountDeleteConfirmBody =>
      'Dadurch werden dein Firebase-Konto, deine Google- und Apple-Verknüpfungen, das Firestore-Cloud-Backup und lokale Lerndaten auf diesem Gerät gelöscht. Das lässt sich nicht rückgängig machen. Google oder Apple bitten dich zur Bestätigung eventuell um eine erneute Anmeldung.';

  @override
  String get settingsAccountDeleteSubscriptionWarning =>
      'Ein App-Store- oder Play-Store-Abo wird dadurch nicht gekündigt.';

  @override
  String get settingsManageSubscription => 'Store-Abo verwalten';

  @override
  String get settingsManageSubscriptionFailed =>
      'Die Aboverwaltung konnte nicht geöffnet werden.';

  @override
  String get settingsAccountDeleteSuccess => 'Konto und Daten gelöscht';

  @override
  String settingsAccountDeleteFailed(Object error) {
    return 'Löschung fehlgeschlagen: $error';
  }

  @override
  String get settingsAccountDeletionTitle => 'Konto- und Datenlöschung';

  @override
  String get settingsAccountDeletionSubtitle =>
      'Link zur Kontolöschung kopieren';

  @override
  String get statsGotIt => 'Gewusst';

  @override
  String get statsNotGotIt => 'Nicht gewusst';

  @override
  String get statsSkipped => 'Übersprungen';

  @override
  String get statsCorrect => 'Richtig';

  @override
  String get statsWrong => 'Falsch';

  @override
  String get statsLosses => 'Verloren';

  @override
  String get statsBestShort => 'Beste';

  @override
  String get statsWinRate => 'Quote';

  @override
  String get onboardingPage1Title => 'Triff deinen Lernfreund';

  @override
  String get onboardingPage1Subtitle => 'Taego begleitet dich beim Lernen';

  @override
  String get onboardingPage2Title => '5 Minuten pro Tag';

  @override
  String get onboardingPage2Subtitle => 'Kurz genug für zwischendurch';

  @override
  String get onboardingPage3Title => 'Dranbleiben zählt';

  @override
  String get onboardingPage3Subtitle =>
      'Wenn du regelmäßig lernst, gibt\'s Belohnungen.';

  @override
  String get onboardingPage4Title => 'Wie viel Zeit hast du?';

  @override
  String get onboardingGoal5min => '5 Minuten';

  @override
  String get onboardingGoal10min => '10 Minuten';

  @override
  String get onboardingGoal15min => '15 Minuten';

  @override
  String get onboardingStartEyebrow => 'Dein Einstieg';

  @override
  String get onboardingStartTitle => 'Wofür willst du Koreanisch können?';

  @override
  String get onboardingStartBody =>
      'So merken wir uns, womit du anfängst. Das ist kein Test.';

  @override
  String get onboardingStartTravelTitle => 'Unterwegs in Korea';

  @override
  String get onboardingStartTravelBody =>
      'Café, Weg fragen, einkaufen, Hilfe holen';

  @override
  String get onboardingStartPeopleTitle => 'Mit Menschen sprechen';

  @override
  String get onboardingStartPeopleBody => 'Freunde, Familie und Alltag';

  @override
  String get onboardingStartWorkTitle => 'Studium oder Arbeit';

  @override
  String get onboardingStartWorkBody => 'Höflich fragen und mitkommen';

  @override
  String get onboardingStartPoint => 'Startpunkt';

  @override
  String get onboardingStartNewTitle => 'Ich fange neu an';

  @override
  String get onboardingStartNewBody => 'Gleich mit Hören und Sprechen';

  @override
  String get onboardingStartExistingTitle => 'Ich kann schon etwas';

  @override
  String get onboardingStartExistingBody =>
      'Level wählen oder acht bis zehn Fragen beantworten';

  @override
  String get onboardingStartPrimary => 'Meine erste Szene starten';

  @override
  String get onboardingStartChooseLevel => 'Level wählen';

  @override
  String get onboardingStartLoading => 'Deine erste Szene wird vorbereitet …';

  @override
  String get onboardingStartChangePoint => 'Startpunkt ändern';

  @override
  String get onboardingFirstSceneTravelCanDo =>
      'Ich kann bei der Einreise höflich antworten.';

  @override
  String get onboardingFirstScenePeopleCanDo =>
      'Ich kann mich freundlich vorstellen.';

  @override
  String get onboardingFirstSceneWorkCanDo =>
      'Ich kann mich im Kurs oder auf der Arbeit kurz vorstellen.';

  @override
  String get onboardingCompanionChoose => 'Lernfreund wählen';

  @override
  String get onboardingCompanionSkip => 'Jetzt nicht';

  @override
  String get onboardingCompanionEyebrow => 'Dein Lernfreund';

  @override
  String get onboardingCompanionPrompt =>
      'Wähle Taego oder Joy. Beide helfen dir, und du kannst dich auch später entscheiden.';

  @override
  String get onboardingCompanionSelectedTiger => 'Taego kommt mit.';

  @override
  String get onboardingCompanionSelectedMagpie => 'Joy kommt mit.';

  @override
  String get onboardingCompanionSelectionBody =>
      'Im Profil kannst du das später ändern.';

  @override
  String get onboardingCompanionContinue => 'Mit Begleitung weiter zu Heute';

  @override
  String get onboardingCompanionChange => 'Anders wählen';

  @override
  String get firstVoiceStamp => 'ERSTE\nSTIMME';

  @override
  String get firstVoiceTitle => 'Du hast dein erstes Koreanisch verstanden.';

  @override
  String get firstVoiceBody =>
      'Du hast einen koreanischen Ausdruck verstanden und kannst ihn in der Szene brauchen.';

  @override
  String get firstVoicePhraseBody =>
      'ein Satz, den du jetzt hören und erwidern kannst.';

  @override
  String firstVoiceSceneSummary(int completed, int total) {
    return '$completed von $total Aufgaben abgeschlossen';
  }

  @override
  String get firstVoiceCanDo => 'Ich kann jemanden freundlich begrüßen.';

  @override
  String get firstVoiceCanDoBody => 'Dein A1-Weg beginnt mit dieser Szene.';

  @override
  String get firstVoiceCompanionTitle => 'Möchtest du eine Lernbegleitung?';

  @override
  String get firstVoiceCompanionBody =>
      'Taego oder Joy feiert mit und erklärt Hinweise. Die Wahl kannst du auch später treffen.';

  @override
  String get firstVoiceSkip => 'Direkt zu Heute';

  @override
  String get missionContextLabel => 'Aktuelle Mission';

  @override
  String get courseMissionPath => 'Dein Missionsweg';

  @override
  String get courseMissionDetails => 'Missionsdetails';

  @override
  String get courseMissionCheck => 'Verständnis prüfen';

  @override
  String missionContextStep(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get onboardingTitle => 'Was ist dein Level?';

  @override
  String get onboardingSubtitle =>
      'Wir fangen dort an, wo du stehst. Frühere Level bleiben offen, spätere schaltest du frei.';

  @override
  String get onboardingLevelA1 => 'Anfänger';

  @override
  String get onboardingLevelA1Desc => 'Ich fange gerade an';

  @override
  String get onboardingLevelA2 => 'Grundkenntnisse';

  @override
  String get onboardingLevelA2Desc => 'Begrüßungen, einfache Bestellungen';

  @override
  String get onboardingLevelB1 => 'Mittelstufe';

  @override
  String get onboardingLevelB1Desc => 'Alltagsgespräche klappen schon';

  @override
  String get onboardingLevelB2 => 'Fortgeschritten';

  @override
  String get onboardingLevelB2Desc => 'Flüssig, auch mit Nuancen';

  @override
  String get onboardingLevelC1 => 'Kompetent';

  @override
  String get onboardingLevelC1Desc => 'Belege, Behörden, feine Unterschiede';

  @override
  String get onboardingLevelC2 => 'Expertenniveau';

  @override
  String get onboardingLevelC2Desc => 'Texte zerlegen und bewusst formulieren';

  @override
  String get onboardingExampleA1Trans => 'Hallo / Guten Tag.';

  @override
  String get onboardingExampleA2Trans => 'Einen Americano, bitte.';

  @override
  String get onboardingExampleB1Trans =>
      'Gestern habe ich mit einem Freund einen Film gesehen.';

  @override
  String get onboardingExampleB2Trans =>
      'Das Meeting zieht sich, ich komme wohl etwas später.';

  @override
  String get onboardingExampleC1Trans =>
      'Ich erkläre bestätigte Fakten und unsere jetzige Deutung getrennt.';

  @override
  String get onboardingExampleC2Trans =>
      'Wer Schweigen als Zustimmung wertet, kann schon durch den Rahmen einer Frage Beteiligung einschränken.';

  @override
  String get onboardingSkip => 'Später entscheiden (A1 als Start)';

  @override
  String get onboardingPrompt =>
      'Wähle dein Level. Du kannst es später in den Einstellungen ändern.';

  @override
  String get onboardingTigerGreeting => 'Willkommen!\nWo möchtest du starten?';

  @override
  String get onboardingDifficulty => 'Schwierigkeit';

  @override
  String get onboardingExampleLabel => 'So klingt dieses Level';

  @override
  String get onboardingCompareCta => 'Unsicher? Level vergleichen';

  @override
  String get onboardingCompareTitle => 'Was ändert sich pro Level?';

  @override
  String get onboardingCompareIntro =>
      'Frühere Level bleiben offen. Dein Level kannst du jederzeit in den Einstellungen ändern.';

  @override
  String get onboardingCompareColCan => 'Das kannst du schon';

  @override
  String get onboardingCompareColLearn => 'Das lernst du hier';

  @override
  String get onboardingCompareClose => 'Alles klar';

  @override
  String get onboardingLevelA1Can => 'Du kennst vielleicht ein paar Wörter.';

  @override
  String get onboardingLevelA1Learn =>
      'Hangeul lesen und schreiben, dich vorstellen, Zahlen.';

  @override
  String get onboardingLevelA2Can =>
      'Du liest Hangeul und kennst einfache Begrüßungen.';

  @override
  String get onboardingLevelA2Learn =>
      'Bestellen, einkaufen, nach dem Weg fragen, die Höflichkeitsform -요.';

  @override
  String get onboardingLevelB1Can =>
      'Du führst einfache Gespräche über den Alltag.';

  @override
  String get onboardingLevelB1Learn =>
      'Erzählen, Meinung äußern, Sätze verbinden, Vergangenheit.';

  @override
  String get onboardingLevelB2Can => 'Du sprichst flüssig über Alltagsthemen.';

  @override
  String get onboardingLevelB2Learn =>
      'Beruf und Nachrichten, Nuancen, Redewendungen, Höflichkeitsformen.';

  @override
  String get onboardingLevelC1Can =>
      'Du kannst schwierige Themen besprechen und sagen, wie sicher du dir bist.';

  @override
  String get onboardingLevelC1Learn =>
      'Belege, Unsicherheit, inklusive Systeme, öffentliche Erklärungen.';

  @override
  String get onboardingLevelC2Can =>
      'Du kannst Annahmen, Frage-Rahmen und Behördensprache auseinandernehmen.';

  @override
  String get onboardingLevelC2Learn =>
      'Diskurs, Deutung, Technikethik, verantwortliche Entscheidungen.';

  @override
  String get homeHeroGreetingMorning => 'Guten Morgen!';

  @override
  String get homeHeroGreetingAfternoon => 'Hallo!';

  @override
  String get homeHeroGreetingEvening => 'Guten Abend!';

  @override
  String get homeTigerBubbleStart => 'Lust auf 5 Minuten Koreanisch?';

  @override
  String get homeTigerBubbleStreak => 'Dein Streak hält! Weiter so';

  @override
  String get homeTigerBubbleResume => 'Willkommen zurück!';

  @override
  String get homeHeroActionContinue => 'Weiterlernen';

  @override
  String get homeHeroActionStart => 'Neues Paket';

  @override
  String get homeShieldLabel => 'Schild';

  @override
  String get homePathSection => 'Dein Pfad';

  @override
  String get homePathLocked => 'Verschlossen';

  @override
  String get homePathCurrent => 'Jetzt';

  @override
  String get homeLearnNowCta => 'Jetzt lernen';

  @override
  String get homeTigerBubbleResumeSub => '5 Minuten reichen schon!';

  @override
  String get homePathDone => 'Erledigt';

  @override
  String get scenariosListTitle => 'Szenarien';

  @override
  String get scenariosListSubtitle => 'Übe mit echten Alltagssituationen';

  @override
  String scenariosCardMeta(int xp) {
    return '5 bis 7 Minuten · +$xp XP';
  }

  @override
  String scenariosLocked(Object level) {
    return 'Erreiche $level, um freizuschalten';
  }

  @override
  String scenariosLevelBadge(Object level) {
    return 'Stufe $level';
  }

  @override
  String get scenariosEmpty => 'Bald verfügbar 🚧';

  @override
  String get scenariosEmptyTitle => 'Bald verfügbar';

  @override
  String get scenariosEmptyBody => 'Neue Szenarien folgen bald.';

  @override
  String get scenariosLoadFailedTitle => 'Hm, da ist etwas schiefgelaufen';

  @override
  String get statsFirstEntryTitle => 'Dein Fortschritt beginnt hier';

  @override
  String get statsFirstEntryBody =>
      'Schließ ein Szenario ab. Danach siehst du deinen Fortschritt hier.';

  @override
  String get statsFirstEntryCta => 'Erstes Szenario starten';

  @override
  String get settingsOfflineTitle => 'Keine Verbindung';

  @override
  String get settingsOfflineBody =>
      'Cloud-Sync braucht eine aktive Internetverbindung. Du kannst es später erneut versuchen.';

  @override
  String get vocabDueEmptyTitle => 'Heute alles erledigt!';

  @override
  String get vocabDueEmptyBody =>
      'Du hast deine fälligen Karten geschafft. Komm morgen wieder oder lerne neue Wörter.';

  @override
  String get moduleScenariosTitle => 'Szenarien';

  @override
  String get moduleScenariosDesc =>
      'Übe Alltagssituationen: Café, Flughafen, Vorstellung …';

  @override
  String get scenarioIntroTitle => 'Einleitung';

  @override
  String get scenarioVocabTitle => 'Wortschatz';

  @override
  String get scenarioDialogTitle => 'Dialog';

  @override
  String get scenarioGrammarTitle => 'Grammatik';

  @override
  String get scenarioQuestsTitle => 'Mini-Spiele';

  @override
  String scenarioQuestProgress(int current, int total) {
    return '$current von $total';
  }

  @override
  String get scenarioCulturalNote => 'Kulturnotiz';

  @override
  String get scenarioStartBtn => 'Los geht\'s!';

  @override
  String get scenarioNextBtn => 'Weiter';

  @override
  String get scenarioCompleteBtn => 'Abschließen';

  @override
  String get scenarioResultReturnBtn => 'Zurück zu meinem Weg';

  @override
  String get scenarioSavedEyebrow => 'DEINE SZENE IST GESPEICHERT';

  @override
  String get scenarioSavedTitle => 'Du kannst jetzt zum Hanok zurück.';

  @override
  String get scenarioSavedPhrase => 'Ein Satz für deine nächste Szene';

  @override
  String get scenarioSavedStructure => 'Struktur für diese Szene';

  @override
  String get scenarioSavedEmpty =>
      'Deine Übung ist gespeichert und steht für die Wiederholung bereit.';

  @override
  String get scenarioSavedReturnHanok => 'Zurück zum Hanok';

  @override
  String get scenarioSavedRepeat => 'Diese Szene noch einmal üben';

  @override
  String get scenarioResultSaving =>
      'Diese abgeschlossene Szene wird gespeichert…';

  @override
  String get scenarioResultSaveRetry => 'Speichern erneut versuchen';

  @override
  String get scenarioStructureChangedTitle => 'Dein Hanok hat sich verändert.';

  @override
  String scenarioStructureChangedBody(String stage) {
    return 'Neue Struktur: $stage';
  }

  @override
  String get scenarioStructureUnchangedTitle =>
      'Dein Hanok behält seine aktuelle Struktur.';

  @override
  String get scenarioStructureUnchangedBody =>
      'Dieser Checkpoint hat noch keine neue Struktur freigeschaltet.';

  @override
  String get scenarioStructureUnavailableTitle => 'Die Struktur deines Hanoks';

  @override
  String get scenarioStructureUnavailableBody =>
      'Öffne dein Hanok, um den aktuell bestätigten Bau zu sehen.';

  @override
  String get scenarioCanDoVerifiedTitle => 'Das kannst du jetzt.';

  @override
  String get scenarioCanDoVerifiedBody =>
      'Der Checkpoint dieser Szene wurde selbstständig gespeichert.';

  @override
  String get scenarioCanDoReviewTitle => 'Noch nicht sicher.';

  @override
  String get scenarioCanDoReviewBody =>
      'Dieser Checkpoint wurde gespeichert, liegt aber unter der bestätigten Schwelle dieser Mission. Übe die Szene noch einmal.';

  @override
  String get scenarioCanDoPracticeTitle => 'Übung gespeichert.';

  @override
  String get scenarioCanDoPracticeBody =>
      'Diese Szene ist als Übung gespeichert und verändert deinen Kurs-Schritt nicht.';

  @override
  String scenarioXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String scenarioStarsLabel(int stars) {
    return '$stars von 3 Sternen';
  }

  @override
  String get scenarioRecapTitle => 'Das hast du gelernt';

  @override
  String scenarioRecapWordsLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter geübt',
      one: '1 Wort geübt',
    );
    return '$_temp0';
  }

  @override
  String scenarioRecapAccuracyLine(int passed, int total) {
    return '$passed von $total Quests im ersten Versuch';
  }

  @override
  String scenarioRecapGrammarLine(String pattern) {
    return 'Grammatik-Fokus: $pattern';
  }

  @override
  String get scenarioNextRecommendedTitle => 'Als Nächstes empfohlen';

  @override
  String get scenarioNextRecommendedCta => 'Öffnen';

  @override
  String scenarioNextRecommendedAllDone(String level) {
    return 'Alle $level-Szenarien abgeschlossen.';
  }

  @override
  String get questCorrect => 'Richtig!';

  @override
  String get questWrong => 'Nicht ganz';

  @override
  String get questNext => 'Weiter';

  @override
  String get questRetry => 'Nochmal';

  @override
  String get questAnswerSelected => 'Ausgewählt';

  @override
  String get questAnswerRevealed => 'Die richtige Antwort wird angezeigt.';

  @override
  String get questTryAgainHint => 'Fast. Versuch es noch einmal.';

  @override
  String get questViewResult => 'Ergebnis ansehen';

  @override
  String get questDontKnowYet => 'Weiß ich noch nicht';

  @override
  String get questListeningQuestion => 'Was bedeutet dieser Satz?';

  @override
  String get questTypeListening => 'Hören';

  @override
  String get questTypeTranslation => 'Übersetzen';

  @override
  String get questTypeCloze => 'Lücke füllen';

  @override
  String get questTypeParticle => 'Partikel wählen';

  @override
  String get questTypeBatchim => 'Batchim ergänzen';

  @override
  String get questTypeSentence => 'Satz bauen';

  @override
  String get questTypeDictation => 'Diktat';

  @override
  String get questTypeWriting => 'Schreiben';

  @override
  String get diktatUseWordBlocks =>
      'Keine koreanische Tastatur? Wortblöcke verwenden';

  @override
  String get diktatUseKeyboard => 'Mit der Tastatur schreiben';

  @override
  String get particlePopHint => 'Wähle die richtige Partikel für den Satz.';

  @override
  String get particlePopExplanation =>
      'Nach Konsonant: 은/이/을 · Nach Vokal: 는/가/를';

  @override
  String get settingsUserLevel => 'Mein Level';

  @override
  String get settingsUserLevelChange => 'Level ändern';

  @override
  String get statsXpTitle => 'Szenario-Fortschritt';

  @override
  String get statsXp => 'XP';

  @override
  String statsLevelLabel(int n) {
    return 'Level $n';
  }

  @override
  String statsToNextLevel(int n, int next) {
    return '$n XP bis Level $next';
  }

  @override
  String get statsScenariosCompleted => 'Szenarien geschafft';

  @override
  String get statsBadgesTitle => 'Auszeichnungen';

  @override
  String get statsNoBadges =>
      'Noch keine. Schließ ein Szenario ab und hol dir die erste! 🚀';

  @override
  String statsWeekDaySemantics(String weekday, String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'todayCompleted': 'heute, geschafft',
      'today': 'heute',
      'completed': 'geschafft',
      'pending': 'noch offen',
      'other': 'noch offen',
    });
    return '$weekday: $_temp0';
  }

  @override
  String get homeRecommended => 'Heute empfohlen';

  @override
  String get homeAllDone => 'Alle Szenarien geschafft!';

  @override
  String get homeNoScenario => 'Bald gibt es Szenarien für dein Level';

  @override
  String get homeGreetingLearn => 'Übe Koreanisch für echte Alltagssituationen';

  @override
  String get homeTodaySection => 'Heute';

  @override
  String get missionHeroCtaStart => 'Los geht\'s';

  @override
  String get missionHeroCtaContinue => 'Weitermachen';

  @override
  String missionHeroCourseMeta(int n, int total) {
    return 'Mission $n von $total';
  }

  @override
  String missionHeroPackMeta(Object level) {
    return 'Wortschatz-Paket · Level $level';
  }

  @override
  String missionHeroReviewTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter wiederholen',
      one: '1 Wort wiederholen',
    );
    return '$_temp0';
  }

  @override
  String get missionHeroReviewMeta => 'Heutige Wiederholung';

  @override
  String missionHeroScenarioMeta(Object level) {
    return 'Szenario · Level $level';
  }

  @override
  String get missionHeroAllDoneTitle => 'Für heute geschafft';

  @override
  String get missionHeroAllDoneBody =>
      'Für heute bist du fertig. Morgen gibt es neue Missionen.';

  @override
  String get missionHeroAnotherRound => 'Noch eine Runde';

  @override
  String missionHeroSemantics(Object title, Object level) {
    return 'Nächste Mission: $title, Level $level';
  }

  @override
  String get settingsThemeTitle => 'Erscheinungsbild';

  @override
  String get settingsThemeSystem => 'Systemvorgabe';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get dailyCharTitle => 'Buchstabe des Tages';

  @override
  String get dailyCharSubtitle => 'Strichfolge ansehen';

  @override
  String get dailyCharFallbackSubtitle => 'Buchstaben des Tages ansehen';

  @override
  String get dailyCharGuideHint =>
      'Fertig wird nach der vollständigen Strichfolge freigeschaltet.';

  @override
  String get dailyCharDoneToday => 'Heute geschafft ✓';

  @override
  String get dailyCharFinish => 'Fertig';

  @override
  String dailyCharStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage gesamt',
      one: '1 Tag gesamt',
    );
    return '$_temp0';
  }

  @override
  String get dailyCharGreatJob => 'Super!';

  @override
  String get vocabModeFavorites => 'Gemerkt';

  @override
  String vocabFavoritesBadge(int n) {
    return '$n';
  }

  @override
  String get vocabHearExample => 'Beispiel hören';

  @override
  String get vocabSlowHint => 'Lang drücken: langsam';

  @override
  String get vocabEmptyFavorites =>
      'Noch nichts gemerkt\nTippe auf das Lesezeichen, um Wörter zu speichern.';

  @override
  String get listeningTitle => 'Hören';

  @override
  String get listeningSubtitle => 'Hör ein Szenario in natürlichem Tempo';

  @override
  String get listeningSelectScenario => 'Szenario wählen';

  @override
  String get listeningSpeedLabel => 'Tempo';

  @override
  String get listeningSubtitleLabel => 'Untertitel';

  @override
  String get listeningSubtitleKo => 'Koreanisch';

  @override
  String get listeningSubtitleNative => 'Übersetzung';

  @override
  String get listeningSubtitleBoth => 'Beides';

  @override
  String get listeningSubtitleOff => 'Aus';

  @override
  String get listeningReplay => 'Wiederholen';

  @override
  String get listeningDialogueStart => 'Dialog anhören';

  @override
  String get listeningSceneIntro => 'Szene';

  @override
  String get listeningParticipants => 'Sprechende';

  @override
  String listeningLineCount(int n) {
    return '$n Zeilen';
  }

  @override
  String get listeningPause => 'Pause';

  @override
  String get listeningResume => 'Weiterhören';

  @override
  String get listeningShowTranslation => 'Übersetzung zeigen';

  @override
  String get listeningHideTranslation => 'Übersetzung ausblenden';

  @override
  String get listeningNarrator => 'Erzählstimme';

  @override
  String get listeningSpeakerYou => 'Du';

  @override
  String get scenarioPlayerSelfSuffix => '(나)';

  @override
  String get listeningReviewTitle => 'Zeile für Zeile wiederholen';

  @override
  String get listeningReviewBody =>
      'Hör einzelne Zeilen erneut und öffne die Übersetzung nur bei Bedarf.';

  @override
  String get listeningReviewCta => 'Zeile für Zeile wiederholen';

  @override
  String get listeningBackToScroll => 'Zurück zur Schriftrolle';

  @override
  String get listeningNextStory => 'Nächste Geschichte';

  @override
  String get listeningTtsFailedTitle =>
      'Diese Zeile konnte nicht abgespielt werden.';

  @override
  String get listeningTtsFailedBody =>
      'Versuch es erneut oder lerne mit dem koreanischen Text weiter.';

  @override
  String get listeningRetry => 'Erneut versuchen';

  @override
  String get listeningGotIt => 'Verstanden';

  @override
  String get listeningPrev => 'Zurück';

  @override
  String get listeningNext => 'Weiter';

  @override
  String listeningProgress(int i, int n) {
    return '$i/$n';
  }

  @override
  String get listeningCompleteTitle => 'Geschafft!';

  @override
  String listeningCompleteBody(int n, int xp) {
    return '$n Zeilen gehört · +$xp XP';
  }

  @override
  String listeningCompleteReplayBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Zeilen gehört · Belohnung bereits erhalten',
      one: '1 Zeile gehört · Belohnung bereits erhalten',
    );
    return '$_temp0';
  }

  @override
  String get listeningPickFirst => 'Tippe ein Fach an, um zu starten.';

  @override
  String get listeningEmptyTitle => 'Noch keine Szenarien';

  @override
  String get listeningEmptyBody =>
      'Sobald Szenarien verfügbar sind, kannst du sie hier anhören.';

  @override
  String listeningLevelDrawer(String level, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Level $level, $count Szenarien',
      one: 'Level $level, 1 Szenario',
      zero: 'Level $level, noch nicht bestückt',
    );
    return '$_temp0';
  }

  @override
  String get listeningShelfEmpty => 'noch nicht bestückt';

  @override
  String listeningShelfScenarioCount(int n) {
    return '$n Szenarien';
  }

  @override
  String get listeningShelfA1Transit => 'Einsteigen & aussteigen';

  @override
  String get listeningShelfA1Arrival => 'Taxi, Flughafen & Unterkunft';

  @override
  String get listeningShelfA1Counter => 'Läden & Schalter';

  @override
  String get listeningShelfA1Cafe => 'Café & Imbiss';

  @override
  String get listeningShelfA1Home => 'Zuhause & Haustür';

  @override
  String get listeningShelfA1Greeting => 'Begrüßung & Anrede';

  @override
  String get listeningShelfA1Repair => 'Ich hab\'s nicht verstanden';

  @override
  String get listeningShelfA1Health => 'Apotheke, Wetter & Sicherheit';

  @override
  String get listeningShelfA1Family => 'Erster Besuch bei der Partnerfamilie';

  @override
  String get listeningShelfA1Numbers => 'Zahlen & Uhrzeit hören';

  @override
  String get listeningShelfA1Phone => 'Anrufe & Nachrichten';

  @override
  String get listeningShelfA1Wayfinding => 'Wege & Schilder';

  @override
  String get listeningShelfA2Travel => 'Unterwegs, Unterkunft & Fundsachen';

  @override
  String get listeningShelfA2Bank => 'Bank, Mobilfunk & Gebühren';

  @override
  String get listeningShelfA2Shopping => 'Kaufen & abrechnen';

  @override
  String get listeningShelfA2Cafe => 'Café & Restaurant';

  @override
  String get listeningShelfA2Body => 'Körper, Arzt & Sport';

  @override
  String get listeningShelfA2Neighbourhood => 'Wohnanlage & Nachbarn';

  @override
  String get listeningShelfA2Work => 'Erste Schritte im Job';

  @override
  String get listeningShelfA2Plans => 'Verabredungen & Kontakt';

  @override
  String get listeningShelfA2Family => 'Partnerfamilie & Feiertage';

  @override
  String get listeningShelfA2Delivery => 'Lieferung & Annahme';

  @override
  String get listeningShelfA2Enrolment => 'Anmeldung & Unterricht';

  @override
  String get listeningShelfA2Booking => 'Buchen & Umbuchen';

  @override
  String get listeningShelfB1Repairs => 'Reparaturen & Mängel';

  @override
  String get listeningShelfB1Refund => 'Rückerstattung & Garantie';

  @override
  String get listeningShelfB1Receipts => 'Belege & Abrechnung';

  @override
  String get listeningShelfB1Delay => 'Terminänderung & Verspätung';

  @override
  String get listeningShelfB1Paperwork => 'Unterlagen & Vollmacht';

  @override
  String get listeningShelfB1Team => 'Team & Übergabe';

  @override
  String get listeningShelfB1Neighbours => 'Nachbarn & Gemeinschaftsräume';

  @override
  String get listeningShelfB1Feelings => 'Gefühle & Beziehung';

  @override
  String get listeningShelfB1Family => 'Nähe & Distanz in der Partnerfamilie';

  @override
  String get listeningShelfB1Insurance => 'Behandlung & Versicherung';

  @override
  String get listeningShelfB1Incident => 'Unfälle & Anzeigen';

  @override
  String get listeningShelfB1Cancellation => 'Kündigen & Umziehen';

  @override
  String get listeningShelfB2Meetings => 'Besprechungen leiten';

  @override
  String get listeningShelfB2Evidence => 'Belege & Zahlen';

  @override
  String get listeningShelfB2Negotiation => 'Verhandeln & Bedingungen';

  @override
  String get listeningShelfB2Contracts => 'Verträge & Unterschrift';

  @override
  String get listeningShelfB2Notices => 'Formelle Schreiben & Widerspruch';

  @override
  String get listeningShelfB2Escalation => 'Eskalation unterwegs';

  @override
  String get listeningShelfB2Medical => 'Medizin & Abrechnung';

  @override
  String get listeningShelfB2Public => 'Öffentlich sprechen & schreiben';

  @override
  String get listeningShelfB2Family => 'Grenzen in der Partnerfamilie';

  @override
  String get listeningShelfB2Hiring => 'Einstellung & Beurteilung';

  @override
  String get listeningShelfB2Authorities => 'Behörden & Genehmigungen';

  @override
  String get listeningShelfB2Privacy => 'Daten & Einwilligung';

  @override
  String get listeningShelfC1Briefing => 'Briefing & Rederecht';

  @override
  String get listeningShelfC1Uncertainty => 'Unsicherheit & Stichproben';

  @override
  String get listeningShelfC1Access => 'Zugriffsrechte & Fristen';

  @override
  String get listeningShelfC1InvisibleLabor =>
      'Unsichtbare Arbeit in der Familie';

  @override
  String get listeningShelfC1Conflict => 'Interessenkonflikt & Befangenheit';

  @override
  String get listeningShelfC1Policy => 'Auslegung & Ermessen';

  @override
  String get listeningShelfC1Consent => 'Aufklärung & Einwilligung';

  @override
  String get listeningShelfC1Critique => 'Kultur- & Kunstkritik';

  @override
  String get listeningShelfC1Mediation => 'Interkulturelle Vermittlung';

  @override
  String get listeningShelfC1Methodology => 'Methodik & Reproduzierbarkeit';

  @override
  String get listeningShelfC1Facework => 'Widerspruch ohne Gesichtsverlust';

  @override
  String get listeningShelfC1Attribution => 'Zitieren & Quellenverantwortung';

  @override
  String get listeningShelfC2Automation => 'Automatisierte Entscheidungen';

  @override
  String get listeningShelfC2Records => 'Lücken in der Aktenlage';

  @override
  String get listeningShelfC2Discourse => 'Vorannahmen im Diskurs';

  @override
  String get listeningShelfC2Authority => 'Grenzen & Widerruf von Vollmacht';

  @override
  String get listeningShelfC2Impact => 'Ungleiche Auswirkungen';

  @override
  String get listeningShelfC2Memory => 'Orte & Namen erinnern';

  @override
  String get listeningShelfC2Ethics => 'Forschungsethik & Einwilligung';

  @override
  String get listeningShelfC2History => 'Geschichtsschreibung & Versöhnung';

  @override
  String get listeningShelfC2Translation => 'Ästhetik & Unübersetzbarkeit';

  @override
  String get listeningShelfC2Limitation => 'Fristen & Verjährung';

  @override
  String get listeningShelfC2Jurisdiction => 'Zuständigkeit & Grenzen';

  @override
  String get listeningShelfC2Representation => 'Wer spricht für wen';

  @override
  String get listeningShelfSocialFriends => 'Freunde & Zocken';

  @override
  String get listeningShelfSocialDating => 'Dating & Beziehung';

  @override
  String get listeningShelfSocialFandom => 'Fandom & Videos';

  @override
  String get listeningShelfShortA1Transit => 'Bus & Bahn';

  @override
  String get listeningShelfShortA1Arrival => 'Ankunft';

  @override
  String get listeningShelfShortA1Counter => 'Läden & Schalter';

  @override
  String get listeningShelfShortA1Cafe => 'Café & Imbiss';

  @override
  String get listeningShelfShortA1Home => 'Zuhause';

  @override
  String get listeningShelfShortA1Greeting => 'Begrüßung';

  @override
  String get listeningShelfShortA1Repair => 'Nachfragen';

  @override
  String get listeningShelfShortA1Health => 'Apotheke';

  @override
  String get listeningShelfShortA1Family => 'Erster Besuch';

  @override
  String get listeningShelfShortA1Numbers => 'Zahlen & Uhrzeit';

  @override
  String get listeningShelfShortA1Phone => 'Anrufe';

  @override
  String get listeningShelfShortA1Wayfinding => 'Wege & Schilder';

  @override
  String get listeningShelfShortA2Travel => 'Unterwegs';

  @override
  String get listeningShelfShortA2Bank => 'Bank & Handy';

  @override
  String get listeningShelfShortA2Shopping => 'Einkauf';

  @override
  String get listeningShelfShortA2Cafe => 'Restaurant';

  @override
  String get listeningShelfShortA2Body => 'Arzt & Sport';

  @override
  String get listeningShelfShortA2Neighbourhood => 'Nachbarschaft';

  @override
  String get listeningShelfShortA2Work => 'Im Job';

  @override
  String get listeningShelfShortA2Plans => 'Verabredungen';

  @override
  String get listeningShelfShortA2Family => 'Feiertage';

  @override
  String get listeningShelfShortA2Delivery => 'Lieferung';

  @override
  String get listeningShelfShortA2Enrolment => 'Anmeldung';

  @override
  String get listeningShelfShortA2Booking => 'Buchungen';

  @override
  String get listeningShelfShortB1Repairs => 'Reparaturen';

  @override
  String get listeningShelfShortB1Refund => 'Garantie';

  @override
  String get listeningShelfShortB1Receipts => 'Belege';

  @override
  String get listeningShelfShortB1Delay => 'Verspätung';

  @override
  String get listeningShelfShortB1Paperwork => 'Unterlagen';

  @override
  String get listeningShelfShortB1Team => 'Übergabe';

  @override
  String get listeningShelfShortB1Neighbours => 'Nachbarn';

  @override
  String get listeningShelfShortB1Feelings => 'Gefühle';

  @override
  String get listeningShelfShortB1Family => 'Nähe & Distanz';

  @override
  String get listeningShelfShortB1Insurance => 'Versicherung';

  @override
  String get listeningShelfShortB1Incident => 'Unfälle';

  @override
  String get listeningShelfShortB1Cancellation => 'Kündigung';

  @override
  String get listeningShelfShortB2Meetings => 'Besprechungen';

  @override
  String get listeningShelfShortB2Evidence => 'Zahlen & Belege';

  @override
  String get listeningShelfShortB2Negotiation => 'Verhandlungen';

  @override
  String get listeningShelfShortB2Contracts => 'Verträge';

  @override
  String get listeningShelfShortB2Notices => 'Widerspruch';

  @override
  String get listeningShelfShortB2Escalation => 'Eskalation';

  @override
  String get listeningShelfShortB2Medical => 'Medizin';

  @override
  String get listeningShelfShortB2Public => 'Öffentlichkeit';

  @override
  String get listeningShelfShortB2Family => 'Grenzen';

  @override
  String get listeningShelfShortB2Hiring => 'Einstellung';

  @override
  String get listeningShelfShortB2Authorities => 'Behörden';

  @override
  String get listeningShelfShortB2Privacy => 'Datenschutz';

  @override
  String get listeningShelfShortC1Briefing => 'Rederecht';

  @override
  String get listeningShelfShortC1Uncertainty => 'Unsicherheit';

  @override
  String get listeningShelfShortC1Access => 'Zugriffsrechte';

  @override
  String get listeningShelfShortC1InvisibleLabor => 'Unsichtbare Arbeit';

  @override
  String get listeningShelfShortC1Conflict => 'Befangenheit';

  @override
  String get listeningShelfShortC1Policy => 'Auslegung';

  @override
  String get listeningShelfShortC1Consent => 'Einwilligung';

  @override
  String get listeningShelfShortC1Critique => 'Kunstkritik';

  @override
  String get listeningShelfShortC1Mediation => 'Vermittlung';

  @override
  String get listeningShelfShortC1Methodology => 'Methodik';

  @override
  String get listeningShelfShortC1Facework => 'Gesicht wahren';

  @override
  String get listeningShelfShortC1Attribution => 'Zitate & Quellen';

  @override
  String get listeningShelfShortC2Automation => 'Automatisierung';

  @override
  String get listeningShelfShortC2Records => 'Aktenlücken';

  @override
  String get listeningShelfShortC2Discourse => 'Vorannahmen';

  @override
  String get listeningShelfShortC2Authority => 'Vollmacht';

  @override
  String get listeningShelfShortC2Impact => 'Auswirkungen';

  @override
  String get listeningShelfShortC2Memory => 'Erinnerung';

  @override
  String get listeningShelfShortC2Ethics => 'Forschungsethik';

  @override
  String get listeningShelfShortC2History => 'Versöhnung';

  @override
  String get listeningShelfShortC2Translation => 'Ästhetik';

  @override
  String get listeningShelfShortC2Limitation => 'Verjährung';

  @override
  String get listeningShelfShortC2Jurisdiction => 'Zuständigkeit';

  @override
  String get listeningShelfShortC2Representation => 'Repräsentation';

  @override
  String get listeningShelfShortSocialFriends => 'Freunde';

  @override
  String get listeningShelfShortSocialDating => 'Dating';

  @override
  String get listeningShelfShortSocialFandom => 'Fandom';

  @override
  String get kkeunmariTitle => 'Wortkette';

  @override
  String get kkeunmariEmptyBody =>
      'Für dieses Spiel sind gerade keine Wörter vorbereitet.';

  @override
  String get kkeunmariSubtitle => 'Letzte Silbe → nächstes Wort';

  @override
  String get kkeunmariYourTurn => 'Du bist dran';

  @override
  String get kkeunmariTigerTurn => 'Tiger denkt …';

  @override
  String kkeunmariStartHint(Object syl) {
    return 'Beginne mit »$syl«';
  }

  @override
  String get kkeunmariInputHint => 'Wort auf Koreanisch …';

  @override
  String get kkeunmariSubmit => 'Senden';

  @override
  String get kkeunmariDictionaryChecking => 'Wörterbuch wird geprüft…';

  @override
  String get kkeunmariNotDictionaryWord =>
      'Dieses Wort ist kein gültiges Wörterbuch-Stichwort für das Spiel.';

  @override
  String get kkeunmariDictionaryUnavailable =>
      'Das Wörterbuch kann gerade nicht geprüft werden. Versuche ein bekanntes Wort oder probiere es gleich noch einmal.';

  @override
  String get kkeunmariNotInPool =>
      'Das kenne ich noch nicht. Versuch ein anderes Wort. 🐯';

  @override
  String get kkeunmariNotKorean => 'Nur Hangul-Wörter, bitte';

  @override
  String kkeunmariWrongStart(Object syl) {
    return 'Muss mit »$syl« anfangen';
  }

  @override
  String get kkeunmariAlreadyUsed => 'Bereits genutzt';

  @override
  String get kkeunmariTimeUp => 'Zeit abgelaufen!';

  @override
  String get kkeunmariDeadEnd => '한방단어 (Sackgasse): Die Kette endet hier.';

  @override
  String kkeunmariChainLength(int n) {
    return 'Kette: $n';
  }

  @override
  String kkeunmariFinalScore(int xp) {
    return '+$xp XP';
  }

  @override
  String get kkeunmariPlayAgain => 'Nochmal';

  @override
  String get kkeunmariBackHome => 'Startseite';

  @override
  String kkeunmariTimerSeconds(int n) {
    return '${n}s';
  }

  @override
  String get kkeunmariResultTitle => 'Spiel vorbei';

  @override
  String kkeunmariResultBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter',
      one: '1 Wort',
    );
    return 'Du hast $_temp0 verkettet.';
  }

  @override
  String get gameKkeunmariTitle => 'Wortkette';

  @override
  String get gameKkeunmariDesc => 'Letzte Silbe → nächstes Wort';

  @override
  String get vocabMasteryFresh => 'Neu';

  @override
  String get vocabMasteryLearning => 'Im Aufbau';

  @override
  String get vocabMasteryReviewDue => 'Fällig';

  @override
  String get vocabMasteryStrong => 'Gefestigt';

  @override
  String get scenariosPathTitle => 'Dein Pfad';

  @override
  String scenariosPathProgress(int done, int total) {
    return '$done/$total freigeschaltet';
  }

  @override
  String get scenariosPathNextLabel => 'Als Nächstes';

  @override
  String get scenariosPathStartCta => 'Starten';

  @override
  String get scenariosPathAllDone => 'Alle Szenarien abgeschlossen';

  @override
  String scenariosPathLevelProgress(Object level, int done, int total) {
    return '$level: $done/$total ★';
  }

  @override
  String get shareTooltip => 'Teilen';

  @override
  String get shareTitle => 'Paket teilen';

  @override
  String get shareGenerating => 'Code wird erstellt …';

  @override
  String get shareCodeLabel => 'Freundes-Code';

  @override
  String get shareCopyCode => 'Code kopieren';

  @override
  String get shareCodeCopied => 'Code kopiert';

  @override
  String get shareViaApp => 'Über App teilen';

  @override
  String get shareExpiryNote => 'Code gilt 30 Tage.';

  @override
  String get shareError => 'Teilen fehlgeschlagen. Bist du online?';

  @override
  String get shareEmpty => 'Dieser Paket hat keine Wörter.';

  @override
  String sharePackBody(Object name, int count, Object code) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return 'Ich teile mit dir das Vokabel-Paket „$name“ ($_temp0) aus Hangul Sori! Gib in der App den Code $code ein, um es zu importieren. hangul-sori.com';
  }

  @override
  String get redeemTooltip => 'Mit Code importieren';

  @override
  String get redeemTitle => 'Paket importieren';

  @override
  String get redeemHint => '6-stelligen Code eingeben';

  @override
  String get redeemAction => 'Importieren';

  @override
  String get redeemLoading => 'Paket wird importiert …';

  @override
  String redeemSuccess(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return '„$name“ importiert ($_temp0)';
  }

  @override
  String get redeemNotFound => 'Code nicht gefunden.';

  @override
  String get redeemExpired => 'Dieser Code ist abgelaufen.';

  @override
  String get redeemError => 'Import fehlgeschlagen. Bist du online?';

  @override
  String get createWordbookCta => 'Eigene Wortliste';

  @override
  String get createWordbookTitle => 'Neue Wortliste';

  @override
  String get createWordbookHint => 'Gib deiner Wortliste einen Namen.';

  @override
  String get wbEditTooltip => 'Bearbeiten';

  @override
  String get wbEditTitle => 'Wortliste bearbeiten';

  @override
  String get wbAddWord => 'Wort hinzufügen';

  @override
  String get wbEditWordTitle => 'Wort bearbeiten';

  @override
  String get wbEmptyTitle => 'Noch keine Wörter';

  @override
  String get wbEmptyBody =>
      'Füge dein erstes Wort hinzu oder lass die Übersetzung automatisch ausfüllen.';

  @override
  String get wbFieldKorean => 'Koreanisch';

  @override
  String get wbFieldMeaning => 'Bedeutung';

  @override
  String get wbFieldExample => 'Beispielsatz (optional)';

  @override
  String get wbAutoFill => 'Automatisch ausfüllen';

  @override
  String get wbAutoFillRunning => 'Suche Übersetzung …';

  @override
  String get wbAutoFillOffline =>
      'Automatisches Ausfüllen ist gerade nicht möglich. Bitte trag die Übersetzung selbst ein.';

  @override
  String get wbSaveWord => 'Speichern';

  @override
  String get wbNeedKorean => 'Bitte ein koreanisches Wort eingeben.';

  @override
  String get wbDeleteWordTitle => 'Wort löschen?';

  @override
  String get wbDeleteWordBody => 'Dieses Wort wird aus der Liste entfernt.';

  @override
  String get wbRenameTitle => 'Umbenennen';

  @override
  String get wbRenameLabel => 'Name';

  @override
  String get wbStudyCards => 'Karten lernen';

  @override
  String get wbQuiz => 'Quiz';

  @override
  String get quizNeedMore => 'Mindestens 4 Wörter mit Bedeutung nötig.';

  @override
  String get quizQuestion => 'Was bedeutet dieses Wort?';

  @override
  String quizScore(int correct, int total) {
    return '$correct / $total richtig';
  }

  @override
  String get quizResultTitle => 'Quiz beendet';

  @override
  String get quizResultBody =>
      'Gut gemacht! Wiederhole die Liste, um dich zu verbessern.';

  @override
  String get quizAgain => 'Nochmal';

  @override
  String get gameNewBest => 'Neuer Rekord!';

  @override
  String gameBestAccuracy(int percent) {
    return 'Beste Genauigkeit: $percent%';
  }

  @override
  String gameBestTries(int count) {
    return 'Rekord: $count Versuche';
  }

  @override
  String get clozeTitle => 'Lückentext';

  @override
  String get clozeDesc => 'Das fehlende Wort im Satz';

  @override
  String get clozeInstruction => 'Wähle das fehlende Wort.';

  @override
  String get clozeEmptyBody =>
      'Für dieses Level gibt es noch keine Sätze. Wähle ein anderes Level.';

  @override
  String get clozeLevelLabel => 'Lernstufe';

  @override
  String get clozeLevelAll => 'Alle';

  @override
  String get speedMatchTitle => 'Blitz-Paare';

  @override
  String get speedMatchDesc => 'Auf Zeit zuordnen';

  @override
  String get speedMatchInstruction =>
      'Tippe ein koreanisches Wort, dann die passende Bedeutung.';

  @override
  String get speedMatchEmptyBody =>
      'Für diese Lernstufe gibt es noch nicht genug Wortpaare.';

  @override
  String get speedMatchAllLevels => 'Alle Lernstufen verwenden';

  @override
  String speedMatchScore(int count) {
    return '$count Paare';
  }

  @override
  String speedMatchBest(int count) {
    return 'Rekord: $count Paare';
  }

  @override
  String get dailyTitle => 'Tages-Challenge';

  @override
  String get dailyDesc => 'Tägliches Rätsel · Streak';

  @override
  String get dailyAlreadyDone => 'Heute schon erledigt. Jetzt im Übungsmodus.';

  @override
  String dailyStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage in Folge',
      one: '1 Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get satzArcadeTitle => 'Satz bauen';

  @override
  String get satzArcadeDesc => 'Wörter zum Satz ordnen';

  @override
  String get homeWordbookCardTitle => 'Eigene Wortliste';

  @override
  String get homeWordbookCardDesc => 'Selbst erstellen & üben';

  @override
  String get csvImportTitle => 'CSV importieren';

  @override
  String get csvImportHint =>
      'Eine Zeile pro Wort: Koreanisch, Bedeutung, Beispiel (optional). Mit Komma getrennt.';

  @override
  String get csvImportButton => 'Importieren';

  @override
  String get csvImportEmpty => 'Keine gültigen Zeilen gefunden.';

  @override
  String csvImportResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter importiert',
      one: '1 Wort importiert',
    );
    return '$_temp0';
  }

  @override
  String get wbPhotoCamera => 'Kamera';

  @override
  String get wbPhotoGallery => 'Galerie';

  @override
  String get wbPhotoRemove => 'Foto entfernen';

  @override
  String get hardWordsTitle => 'Knifflige Wörter';

  @override
  String hardWordsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter, die einfach nicht sitzen wollen',
      one: '1 Wort, das einfach nicht sitzen will',
    );
    return '$_temp0';
  }

  @override
  String get hardWordsEmptyTitle => 'Keine Sorgenkinder';

  @override
  String get hardWordsEmptyBody =>
      'Im Moment gibt es keine besonders schwierigen Wörter. Wenn dir eins immer wieder schwerfällt, erscheint es hier.';

  @override
  String get hardWordsStudyCta => 'Gezielt wiederholen';

  @override
  String get hardWordsHardQuizCta => 'Schweres Quiz: Schreibweise';

  @override
  String get hardQuizTitle => 'Schweres Quiz';

  @override
  String get hardQuizHint => 'Wähle die richtige Schreibweise.';

  @override
  String hardQuizCorrectFeedback(String word) {
    return 'Richtig: $word';
  }

  @override
  String hardQuizWrongFeedback(String word) {
    return 'Richtig geschrieben: $word';
  }

  @override
  String get hardQuizFinish => 'Ergebnis ansehen';

  @override
  String get hardQuizDoneTitle => 'Runde geschafft!';

  @override
  String hardQuizScore(int correct, int total) {
    return '$correct/$total richtig';
  }

  @override
  String get wordWebTitle => 'Nuancen & Gegenteile';

  @override
  String get wordWebHubDesc =>
      'Synonyme, Gegenteile und Wendungen zu deinen Wörtern';

  @override
  String wordWebSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter mit Nachbarn',
      one: '1 Wort mit Nachbarn',
    );
    return '$_temp0';
  }

  @override
  String get wordWebEmptyTitle => 'Noch kein Netz';

  @override
  String get wordWebEmptyBody =>
      'Lerne Wörter in einem Paket, im Kurs oder in einem Spiel. Dann erscheinen hier Nachbarn, Gegenteile und Wendungen zu genau diesen Wörtern.';

  @override
  String get wordWebLoadErrorTitle => 'Netz nicht geladen';

  @override
  String get wordWebLoadErrorBody =>
      'Die Nuancen-Datei konnte nicht gelesen werden. Das ist kein leerer Lernstand. Versuch es noch einmal.';

  @override
  String get wordWebBrowseLevelCta => 'Wörter auf meinem Niveau ansehen';

  @override
  String get wordWebOpenVocabCta => 'Wortpakete öffnen';

  @override
  String get wordWebQuizCta => 'Diese Wörter üben';

  @override
  String get wordWebLearnedFilter => 'Gelernt';

  @override
  String get wordWebLevelFilter => 'Mein Niveau';

  @override
  String get wordWebSynonymSection => 'Ähnliche Wörter';

  @override
  String get wordWebAntonymSection => 'Gegenteile';

  @override
  String get wordWebRelatedSection => 'Verwandte Wörter';

  @override
  String get wordWebExpressionSection => 'Wendungen';

  @override
  String get wordWebQuizTitle => 'Nuancen-Übung';

  @override
  String get wordWebQuizHintSynonym => 'Welches Wort liegt nah dabei?';

  @override
  String get wordWebQuizHintAntonym => 'Was ist das Gegenteil?';

  @override
  String get wordWebQuizHintRelated => 'Was gehört dazu?';

  @override
  String get wordWebQuizHintExpression => 'Welche Wendung passt zur Bedeutung?';

  @override
  String wordWebQuizCorrectFeedback(String word) {
    return 'Richtig: $word';
  }

  @override
  String wordWebQuizWrongFeedback(String word) {
    return 'Dazu passt: $word';
  }

  @override
  String get wordWebQuizFinish => 'Ergebnis ansehen';

  @override
  String get wordWebQuizDoneTitle => 'Runde geschafft!';

  @override
  String get wordWebQuizEmptyTitle => 'Noch keine Runde';

  @override
  String get wordWebQuizEmptyBody =>
      'Für diese Wörter reichen die Vergleichswörter noch nicht. Schau dir zuerst die Karten an oder lerne ein paar Wörter dazu.';

  @override
  String wordWebQuizScore(int correct, int total) {
    return '$correct/$total richtig';
  }

  @override
  String wordWebClusterCount(
    int synonyms,
    int antonyms,
    int related,
    int expressions,
  ) {
    return '$synonyms ähnlich · $antonyms Gegenteil · $related verwandt · $expressions Wendung';
  }

  @override
  String get wordWebExampleLabel => 'Im Satz';

  @override
  String get wordWebCoachTitle => 'Deine Nuancen & Gegenteile';

  @override
  String get wordWebCoachBody =>
      'Tippe ein Wort aus deinem Lernstand. Das Netz zeigt Nachbarn, Gegenteile und eine Wendung, unabhängig von Hanja und Nuance im Vokabelheft.';

  @override
  String get wbMatching => 'Paare finden';

  @override
  String get wbMatchingHint =>
      'Tippe auf ein koreanisches Wort, dann auf seine Bedeutung.';

  @override
  String get wbMatchingNeedMore => 'Mindestens 2 Wörter mit Bedeutung nötig.';

  @override
  String get wbMatchingDone => 'Alle Paare gefunden!';

  @override
  String get wbMatchingDoneBody => 'Noch eine Runde?';

  @override
  String get wbTyping => 'Schreiben';

  @override
  String get wbTypingNeedMore => 'Mindestens 1 Wort mit Bedeutung nötig.';

  @override
  String get wbTypingPrompt => 'Schreib das koreanische Wort:';

  @override
  String get wbTypingHint => 'Auf Koreanisch …';

  @override
  String wbTypingAnswer(Object answer) {
    return 'Richtig: $answer';
  }

  @override
  String get wbQuickPackName => '⭐ Schnellspeicher';

  @override
  String get wbAddTooltip => 'Zur Wortliste hinzufügen';

  @override
  String get wbCoachTitle => 'Wörter hier speichern';

  @override
  String get wbCoachBody =>
      'Tippe auf das Lesezeichen, um ein Wort zu speichern und täglich zu wiederholen. Aus deiner Wortliste kannst du auch eigene Lernkarten erstellen.';

  @override
  String wbAdded(Object word) {
    return '$word zur Wortliste hinzugefügt';
  }

  @override
  String wbAlreadyAdded(Object word) {
    return '$word ist schon in deiner Wortliste';
  }

  @override
  String get wbAddFailed => 'Konnte nicht hinzugefügt werden';

  @override
  String get wbViewAction => 'Ansehen';

  @override
  String get wbSearchTitle => 'Meine Wörter';

  @override
  String get wbSearchHint => 'Wort oder Bedeutung suchen …';

  @override
  String get wbSearchClear => 'Suche löschen';

  @override
  String get wbSearchEmpty => 'Keine Treffer';

  @override
  String get wbSearchNoWords =>
      'Noch keine gespeicherten Wörter. Tippe beim Lernen auf das Lesezeichen-Symbol.';

  @override
  String wbSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter',
      one: '1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get wbPosAll => 'Alle';

  @override
  String get wbSearchCta => 'Meine Wörter durchsuchen';

  @override
  String comboPop(int count) {
    return '$count in Folge';
  }

  @override
  String get pathTitle => 'Dein Weg';

  @override
  String pathHanokStage(int n) {
    return 'Hanok · Stufe $n/12';
  }

  @override
  String get pathHanokSub => 'Dein Hof wächst mit jedem gemeisterten Paket.';

  @override
  String pathLevelPacks(int done, int total) {
    return '$done/$total Pakete';
  }

  @override
  String get pathNodeNow => 'Jetzt';

  @override
  String get pathLockedHint => 'Schließe zuerst das vorherige Paket ab.';

  @override
  String get pathSeeAll => 'Ganzer Pfad';

  @override
  String get pathJumpToNow => 'Zum aktuellen Schritt';

  @override
  String pathStoryEyebrow(Object level) {
    return '$level · Alltag in Korea';
  }

  @override
  String get pathStoryTitle => 'Du baust vom Begrüßen zum Leben.';

  @override
  String get pathStoryBody =>
      'Jeder Abschnitt endet mit einer Situation, die du selbst lösen kannst.';

  @override
  String get pathOpenCurrentMission => 'Aktuelle Mission öffnen';

  @override
  String get pathCourseMissionsTitle => 'Kursmissionen';

  @override
  String get pathCourseMissionsBody =>
      'Ein klarer nächster Schritt verbindet Wortschatz, Grammatik, Spiele und Szenarien.';

  @override
  String get pathStatusCurrent => 'weiter';

  @override
  String get pathStatusCompleted => 'fertig';

  @override
  String get pathStatusBypassed => 'Startstufe übersprungen';

  @override
  String get pathStatusNext => 'später';

  @override
  String pathCompletedCanDo(Object canDo) {
    return 'Kann ich: $canDo';
  }

  @override
  String pathCurrentCanDo(Object canDo) {
    return 'Jetzt: $canDo';
  }

  @override
  String get pathNextAfterEvidence => 'Als Nächstes nach deinem Beweis';

  @override
  String get pathShowMorePractice => 'Weitere Übungen anzeigen';

  @override
  String get pathHideMorePractice => 'Weitere Übungen ausblenden';

  @override
  String get gyeVoluntaryEyebrow => 'Freiwillige Lerngemeinschaft';

  @override
  String get gyeEmptyHeadline =>
      'Allein lernen ist vollständig. Zusammen kann es wärmer sein.';

  @override
  String get gyeEmptyLead =>
      'Eine 계 ist eine kleine Gruppe, die eine Wochenabsicht miteinander hält.';

  @override
  String get gyeFindOrCreate => 'Eine 계 finden oder gründen';

  @override
  String get gyeContinueSolo => 'Ohne Gruppe weiterlernen';

  @override
  String get gyeEmptyPreviewCaption =>
      'Die Vorschau zeigt den gemeinsamen Hof. Er ist keine Voraussetzung für deinen Lernweg.';

  @override
  String get homePathCardTitle => 'Lernpfad';

  @override
  String get homePathCardSub => 'Sieh, wo du stehst';

  @override
  String get homeBrowseTitle => 'Alles entdecken';

  @override
  String get homeBrowseSub => 'Module & Spiele';

  @override
  String get notifStreakSaverTitle => '🔥 Streak nicht verlieren!';

  @override
  String get notifStreakSaverBody =>
      'Eine kurze Runde reicht, um dranzubleiben.';

  @override
  String notifDailyStreakBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage am Stück',
      one: '1 Tag am Stück',
    );
    return '🔥 $_temp0. Machst du heute weiter?';
  }

  @override
  String get ttsListen => 'Aussprache';

  @override
  String ttsListenTarget(Object target) {
    return 'Aussprache: $target';
  }

  @override
  String get navProfile => 'Profil';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileGuestName => 'Gast';

  @override
  String get profileGuestBadge => 'Behalte Streak, XP & Hanok';

  @override
  String profileJourneyTitle(Object name) {
    return 'Dein Weg, $name';
  }

  @override
  String profileJourneySummary(Object level, Object goal) {
    return '$level · $goal';
  }

  @override
  String get profileGuestDesc =>
      'Dein Fortschritt ist bisher nur auf diesem Gerät. Mit Google-Backup bleibt er auch auf einem neuen Handy erhalten.';

  @override
  String get profileConnectedBadge => 'Konto verbunden';

  @override
  String profileConnectedProviderBadge(Object provider) {
    return 'Mit $provider verbunden';
  }

  @override
  String get profileConnectedDesc =>
      'Dein Fortschritt kann jetzt in der Cloud gesichert werden.';

  @override
  String get profileStatStreak => 'Tage-Streak';

  @override
  String get profileStatLevel => 'Level';

  @override
  String get profileStatWords => 'Vokabeln';

  @override
  String get profileViewStats => 'Alle Statistiken ansehen';

  @override
  String get profileLearningSection => 'Mein Lernen';

  @override
  String get profileEditAction => 'bearbeiten';

  @override
  String get profileLearningGoal => 'Mein Ziel';

  @override
  String get profileLearningGoalNotSet =>
      'Wähle, was dich zum Koreanischen bringt';

  @override
  String get profileLearningStartPoint => 'Mein Startpunkt';

  @override
  String get profileLearningStartPointConfirmTitle => 'Startpunkt ändern?';

  @override
  String get profileLearningStartPointConfirmBody =>
      'Dabei werden dein bisheriger Kursfortschritt, abgeschlossene Einheiten, Übungsnachweise und Szenen-Checks zurückgesetzt. Gespeicherte Vokabeln und Kontodaten bleiben erhalten.';

  @override
  String get profileLearningStartPointConfirmCancel => 'Abbrechen';

  @override
  String get profileLearningStartPointConfirmAction =>
      'Ändern und Kursfortschritt zurücksetzen';

  @override
  String get profileLearningStartPointChangeFailed =>
      'Der Startpunkt konnte nicht geändert werden. Versuche es erneut.';

  @override
  String get profileLearningCompanion => 'Lernbegleitung';

  @override
  String get profileSpaceSection => 'Mein Raum';

  @override
  String get profileGye => 'Gruppe (계)';

  @override
  String get profileGyeDescription => 'Freiwillige Lerngemeinschaft öffnen';

  @override
  String get profileGyeLoading => 'Gruppe wird geladen …';

  @override
  String get profileGyeNone => 'Keine Gruppe gewählt';

  @override
  String get profilePrivacyAccount => 'Datenschutz & Konto';

  @override
  String get profilePrivacyAccountDescription =>
      'Daten, Sicherung und Kontosteuerung';

  @override
  String get profileLearningData => 'Meine Lerndaten';

  @override
  String get profileLearningDataDescription =>
      'Lokalen Lernfortschritt als JSON exportieren';

  @override
  String get profileLearningDataPreparing => 'Export wird vorbereitet …';

  @override
  String get profileLearningDataExportReady =>
      'Deine Lerndaten sind zum Teilen bereit.';

  @override
  String get profileLearningDataExportFailed =>
      'Der Export konnte nicht vorbereitet werden.';

  @override
  String get profileAccountDelete => 'Konto löschen';

  @override
  String get profileAccountDeleteDescription =>
      'Den geschützten Löschablauf öffnen';

  @override
  String profileSafeSituations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sichere Situationen',
      one: '1 sichere Situation',
      zero: 'noch keine sichere Situation',
    );
    return '$_temp0';
  }

  @override
  String get profileProgressSection => 'Mein Fortschritt';

  @override
  String get profileSignOut => 'Abmelden';

  @override
  String get accountNudgeTitle => 'Speichere deinen Fortschritt';

  @override
  String get accountNudgeBody =>
      'Verbinde dich mit Google, damit dein Streak und deine Vokabeln bei einem Handywechsel erhalten bleiben.';

  @override
  String get accountNudgeConnect => 'Mit Google verbinden';

  @override
  String get accountNudgeLater => 'Später';

  @override
  String get accountSafeConnectTitle => 'Konto sicher verbinden?';

  @override
  String get errorOffline =>
      'Kein Internet. Dein Fortschritt ist auf diesem Gerät sicher.';

  @override
  String get accountSafeConnectExplain =>
      'Deine lokalen und Cloud-Daten werden geprüft, bevor etwas ersetzt wird. Ein bestehendes Konto wird nie automatisch überschrieben.';

  @override
  String get accountSafeConnectConfirm => 'Sicher verbinden';

  @override
  String get accountOperationInProgress =>
      'Konto und Lernfortschritt werden sicher geprüft …';

  @override
  String get accountOperationResumeTitle => 'Kontowechsel fortsetzen';

  @override
  String get accountOperationResumeBody =>
      'Der sichere Kontowechsel ist gespeichert. Deine Daten bleiben geschützt, bis alle Schritte abgeschlossen sind.';

  @override
  String get accountOperationResume => 'Fortsetzen';

  @override
  String get accountOperationCancel => 'Wechsel abbrechen';

  @override
  String get accountOperationBlockedTitle => 'Dein Konto ist geschützt';

  @override
  String get accountOperationBlockedBody =>
      'Der Wechsel wurde angehalten. Deine bisherigen Daten bleiben unverändert. Du kannst es später erneut versuchen.';

  @override
  String get accountOperationRetryTitle => 'Verbindung nicht abgeschlossen';

  @override
  String get accountOperationRetryBody =>
      'Die sichere Prüfung konnte nicht abgeschlossen werden. Du kannst denselben Vorgang erneut versuchen.';

  @override
  String get accountOperationSupportBody =>
      'Wenn der Vorgang weiter blockiert bleibt, wende dich an den Support. Teile keine Anmeldecodes oder Wiederherstellungsschlüssel.';

  @override
  String get accountDeletionPendingTitle => 'Löschung wird fortgesetzt';

  @override
  String get accountDeletionPendingBody =>
      'Der sichere Löschvorgang ist noch nicht abgeschlossen. Versuche denselben Vorgang erneut; deine Anfrage wird nicht doppelt angelegt.';

  @override
  String get accountLockedCloudDeletionTitle =>
      'Cloud-Löschung wird fortgesetzt';

  @override
  String get accountLockedCloudDeletionBody =>
      'Eine gespeicherte Cloud-Datenlöschung ist noch nicht abgeschlossen. Bis dahin sind Kontoaktionen gesperrt. Du kannst die Löschung jetzt fortsetzen; sie wird nicht doppelt angelegt.';

  @override
  String get accountLockedResumeNow => 'Jetzt fortsetzen';

  @override
  String get accountLockedRefresh => 'Status aktualisieren';

  @override
  String get accountFailureReasonAppCheck =>
      'Die App-Integritätsprüfung ist fehlgeschlagen. Aktualisiere die App oder versuche es später erneut.';

  @override
  String get accountFailureReasonOffline =>
      'Keine Internetverbindung. Prüfe dein Netzwerk und versuche es erneut.';

  @override
  String get accountFailureReasonAuth =>
      'Die Anmeldung muss bestätigt werden. Melde dich erneut an und versuche es noch einmal.';

  @override
  String get accountFailureReasonServer =>
      'Der Server ist vorübergehend nicht erreichbar. Versuche es in ein paar Minuten erneut.';

  @override
  String get settingsCloudResumeDeleteTitle => 'Cloud-Löschung fortsetzen';

  @override
  String get settingsCloudResumeDeleteBody =>
      'Die gespeicherte Löschanfrage wird fortgesetzt. Sie wird nicht doppelt angelegt.';

  @override
  String settingsCloudLastBackup(String time) {
    return 'Zuletzt gesichert: $time';
  }

  @override
  String get settingsCloudLastBackupNever => 'Noch keine Sicherung';

  @override
  String get settingsResetDoneJournalKept =>
      'Zurückgesetzt. Eine offene Konto-Aufgabe wurde beibehalten und wird automatisch fortgesetzt.';

  @override
  String get gyeAccountTransitionPaused =>
      'Kontoänderung läuft. Gruppenaktionen sind geschützt pausiert und werden nach Abschluss wieder verfügbar.';

  @override
  String get authAppleSignIn => 'Mit Apple anmelden';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authProviderApple => 'Apple';

  @override
  String get authProviderGoogleAndApple => 'Google und Apple';

  @override
  String get consentTitle => 'Willkommen bei Hangul Sori';

  @override
  String get consentBody =>
      'Dein Lernfortschritt bleibt zunächst auf deinem Gerät. Optionale Funktionen wie Cloud-Backup, Lerngruppen, Foto-Worterkennung und Aussprache-Audio verarbeiten einzelne Daten auf EU-Servern. Details findest du in der Datenschutzerklärung.';

  @override
  String get consentEyebrow => 'Bevor du beginnst';

  @override
  String get consentCardTitle => 'Datenschutz & Lernkonto';

  @override
  String get consentCardBody =>
      'Klar erklärt · jederzeit in deinem Profil anpassbar. Gruppen bleiben immer freiwillig.';

  @override
  String get consentDataOptIn =>
      'Optional: Teile anonyme Nutzungsstatistiken und Absturzberichte, damit wir Hangul Sori verbessern können. Standardmäßig aus. Du kannst das hier oder jederzeit in den Einstellungen ändern.';

  @override
  String get consentContinueCta => 'Weiter';

  @override
  String get consentPrivacyCta => 'Datenschutzerklärung';

  @override
  String get consentTermsCta => 'Nutzungsbedingungen';

  @override
  String get consentAgreeCta => 'Zustimmen & loslegen';

  @override
  String get consentFootnote =>
      'Mit dem Fortfahren stimmst du unseren Nutzungsbedingungen und unserer Datenschutzerklärung zu.';

  @override
  String get consentAnalyticsOptIn =>
      'Anonyme Nutzungsstatistiken teilen (optional)';

  @override
  String get consentCrashOptIn => 'Anonyme Absturzberichte teilen (optional)';

  @override
  String get consentOptionalHint =>
      'Beides ist freiwillig und jederzeit in den Einstellungen änderbar.';

  @override
  String get consentInviteTitle => 'Zeig mir, wo\'s hakt';

  @override
  String get consentInviteBody =>
      'Ich sehe nie, was du lernst. Anonyme Zahlen zeigen mir nur, wo viele Lernende an derselben Stelle hängen bleiben, und genau dort bessere ich nach. Dein Name, deine E-Mail und deine Lerninhalte bleiben auf deinem Handy.';

  @override
  String get consentInviteYes => 'Alles erlauben';

  @override
  String get consentInviteNo => 'Nur das Nötigste';

  @override
  String get consentInviteCustomize => 'Einzeln festlegen';

  @override
  String get consentInviteSave => 'Speichern';

  @override
  String get grammarEasy => 'Verstanden';

  @override
  String get grammarHard => 'Schwierig';

  @override
  String get grammarPreviousCard => 'Vorherige Karte';

  @override
  String get grammarChoiceCta => 'Mit Beispielen üben';

  @override
  String get grammarPlanOnboardingTitle => 'Wie viele Muster pro Tag?';

  @override
  String grammarPlanItemsPerDayOption(int n) {
    return '$n pro Tag';
  }

  @override
  String get grammarPlanStartCta => 'Los geht\'s';

  @override
  String grammarPlanDayHeader(int day, int total) {
    return 'Tag $day von $total';
  }

  @override
  String get grammarPlanCompletionTitle => 'Tag geschafft!';

  @override
  String get grammarPlanCompletionBody => 'Mit Beispielen üben?';

  @override
  String get grammarPlanCompletionCta => 'Üben';

  @override
  String get grammarPlanCompletionSkip => 'Später';

  @override
  String get grammarPlanFinishedTitle => 'Alle Muster dieser Stufe geschafft!';

  @override
  String get grammarPlanFinishedRestartCta => 'Neu starten';

  @override
  String get grammarChoiceTitle => 'Grammatik üben';

  @override
  String get grammarChoiceEyebrow => 'Satz erkennen';

  @override
  String get grammarChoiceInstruction =>
      'Welche koreanische Grammatik passt zum hervorgehobenen Teil?';

  @override
  String grammarChoicePromptSemantics(String sentence, String focus) {
    return 'Satz: $sentence. Hervorgehobener Teil: $focus.';
  }

  @override
  String get grammarChoiceCorrect => 'Richtig.';

  @override
  String grammarChoiceIncorrect(String pattern) {
    return 'Passend ist: $pattern';
  }

  @override
  String get grammarChoiceKoreanExampleLabel => 'Beispiel auf Koreanisch';

  @override
  String get grammarChoiceExplanationLabel => 'Warum das passt';

  @override
  String get grammarChoiceNoteLabel => 'Anwendung';

  @override
  String get grammarChoiceFinish => 'Ergebnis ansehen';

  @override
  String get grammarChoiceDoneTitle => 'Runde beendet';

  @override
  String grammarChoiceScore(int correct, int total) {
    return '$correct von $total richtig';
  }

  @override
  String get grammarChoicePracticeOnly =>
      'Diese Übung verändert deinen Kursfortschritt nicht.';

  @override
  String get grammarChoiceAgain => 'Neue Runde';

  @override
  String get grammarChoiceBack => 'Zur Grammatik';

  @override
  String get grammarChoiceUnavailableTitle => 'Noch keine Übung verfügbar';

  @override
  String get grammarChoiceUnavailableBody =>
      'Für diese Stufe gibt es noch nicht genügend geprüfte Beispiele.';

  @override
  String get grammarChoiceSaveError =>
      'Diese Schwierigkeitsmarkierung konnte nicht gespeichert werden. Du kannst trotzdem weitermachen.';

  @override
  String get navHome => 'Start';

  @override
  String get navDiscover => 'Entdecken';

  @override
  String get discoverEyebrow => 'Werkzeuge & Kultur';

  @override
  String get discoverTitle => 'Finde genau, was du brauchst.';

  @override
  String get discoverSubtitle =>
      'Scannen, nachschlagen, hören oder eine kleine Pause machen.';

  @override
  String get discoverSearchHint => 'Suchen: z. B. Aussprache, Buch, OCR …';

  @override
  String get discoverStartHere => 'Direkt zu deinem Ziel';

  @override
  String get discoverAllTools => 'Alle Funktionen';

  @override
  String get discoverNoResults => 'Keine passende Funktion gefunden.';

  @override
  String get discoverNoResultsHint =>
      'Versuche ein Bedürfnis wie Aussprache, Buch, Wiederholen oder Gespräch.';

  @override
  String get discoverCategoryAll => 'Alle';

  @override
  String get discoverCategoryLearn => 'Lernen';

  @override
  String get discoverCategoryPractice => 'Üben';

  @override
  String get discoverCategoryWords => 'Wörter';

  @override
  String get discoverCategoryProgress => 'Dein Weg';

  @override
  String get discoverCategoryForMe => 'Für mich';

  @override
  String get discoverCategoryLanguage => 'Sprache';

  @override
  String get discoverCategoryLeisure => 'Freizeit';

  @override
  String get discoverPriorityBookTitle => 'Buch scannen';

  @override
  String get discoverPriorityBookBody => 'Text aus deinem Lehrbuch verstehen';

  @override
  String get discoverPriorityPronunciationTitle => 'Aussprache hören';

  @override
  String get discoverPriorityPronunciationBody => 'Laute langsam vergleichen';

  @override
  String get discoverPriorityWordsTitle => 'Wörterbuch & Meine Wörter';

  @override
  String get discoverPriorityWordsBody => 'Gespeicherte Wörter wiederfinden';

  @override
  String get navLearn => 'Lernen';

  @override
  String get navPractice => 'Üben';

  @override
  String get navWordbook => 'Wörter';

  @override
  String get navGye => 'Gruppe';

  @override
  String get gyeTabSubtitle => 'Zusammen lernen · 계';

  @override
  String get gyeExplainWhat =>
      'Eine 계 (Gye) ist eine kleine Lerngruppe, ganz freiwillig. Allein zu lernen ist genauso gut.';

  @override
  String get gyeExplainWhy =>
      'Ein gemeinsames Hanok zeigt, wie ihr euch gegenseitig anspornt. Einen Wettbewerb gibt es hier nicht, und für deinen Fortschritt brauchst du die Gruppe nicht.';

  @override
  String get gyeExplainHow =>
      'Gründe eine Gruppe oder tritt mit einem 6-stelligen Code bei, wenn du bereit bist.';

  @override
  String get gyePrivacyTitle => 'Was andere sehen';

  @override
  String get gyePrivacyBody =>
      'Es wird nur angezeigt, dass du beigetragen hast. Antworten, Wörter und Prüfungsergebnisse bleiben privat.';

  @override
  String get gyeExplainWhatShort => 'Eine kleine, freiwillige Lerngruppe.';

  @override
  String get gyeExplainWhyShort => 'Ein gemeinsames Hanok, kein Wettbewerb.';

  @override
  String get gyeExplainHowShort => 'Beitritt mit 6-stelligem Code.';

  @override
  String get gyeShowcaseCaption => 'So kann euer gemeinsames Hanok aussehen';

  @override
  String get gyeExplainMore => 'Mehr erfahren';

  @override
  String get gyeWeeklyEyebrow => 'Diese Woche zusammen';

  @override
  String get gyeWeeklyTitle => 'Haltet gemeinsam die Lichter im Hof an.';

  @override
  String get gyeWeeklyBody =>
      'Diese Zahl zeigt abgeschlossene Pakete in eurem aktuellen Gye. Sie ist kein Punktestand, keine Rangliste und kein Antwortprotokoll.';

  @override
  String get gyePromisePickerLabel => 'Gemeinsame Alltagsszene dieser Woche';

  @override
  String get gyePromiseCafeOrder => 'Drei Personen üben, höflich zu bestellen';

  @override
  String get gyePromiseDirections =>
      'Drei Personen üben, nach dem Weg zu fragen';

  @override
  String get gyePromiseSelfIntroduction =>
      'Drei Personen üben, sich vorzustellen';

  @override
  String get gyePromiseEyebrow => 'Diese Woche gemeinsam';

  @override
  String get gyePromiseCafeOrderTitle =>
      'Lasst drei Personen höflich bestellen üben.';

  @override
  String get gyePromiseDirectionsTitle =>
      'Lasst drei Personen nach dem Weg fragen üben.';

  @override
  String get gyePromiseSelfIntroductionTitle =>
      'Lasst drei Personen sich vorstellen üben.';

  @override
  String get gyePromiseBody =>
      'Jede Person hilft mit einer abgeschlossenen, passenden Lernhandlung.';

  @override
  String get gyePromiseEligibility =>
      'Als Beitrag zählt nur die passende kursgebundene Szene mit mindestens 70 %.';

  @override
  String gyePromiseProgress(int done, int target) {
    return '$done von $target Laternen leuchten';
  }

  @override
  String gyePromiseRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kursgebundene Szenenbeiträge',
      one: 'kursgebundener Szenenbeitrag',
    );
    return 'Noch $count $_temp0 diese Woche';
  }

  @override
  String get gyePromiseContributionCompleteTitle => 'Anonymer Beitrag';

  @override
  String get gyePromiseContributionCompleteBody =>
      'Eine passende Szene wurde abgeschlossen. Identität und Ergebnis bleiben privat.';

  @override
  String get gyePromiseContributionPendingTitle => 'Noch ein Licht wartet';

  @override
  String get gyePromiseContributionPendingBody =>
      'Dein nächster Beitrag kann aus Heute kommen.';

  @override
  String get gyePromisePrivacyRule =>
      'Keine Rangliste. Kein Druck. Niemand kann den Lernweg anderer blockieren.';

  @override
  String get gyePromiseSceneCta => 'Meine heutige Szene öffnen';

  @override
  String get gyeTodayFallbackCta => 'Zu Heute';

  @override
  String get gyeTodayUnavailable =>
      'Heute ist gerade nicht verfügbar. Versuch es gleich noch einmal.';

  @override
  String get gyePromiseIntentionAction => 'Wochenabsicht ansehen';

  @override
  String get gyeRulesAndMembers => 'Regeln & Mitglieder';

  @override
  String get gyeRulesTitle => 'Regeln für einen sicheren Hof';

  @override
  String get gyeRulesBody =>
      'Ermutige ohne Vergleiche. Antworten, Ergebnisse und einzelne Beiträge bleiben privat. Melden und Blockieren sind jederzeit möglich.';

  @override
  String get gyeOpenToday => 'Heutiges Lernen öffnen';

  @override
  String get gyeCourtyardEyebrow => 'Euer Hof';

  @override
  String gyeCourtyardLightsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heute leuchten $count Laternen.',
      one: 'Heute leuchtet eine Laterne.',
      zero: 'Heute wartet die erste Laterne.',
    );
    return '$_temp0';
  }

  @override
  String get gyeCourtyardLightsThree => 'Heute leuchten drei Laternen.';

  @override
  String get gyeCourtyardTitle =>
      'Ein gemeinsamer Ort für kleine, sichere Ermutigung.';

  @override
  String get gyeCourtyardBody =>
      'Die Hofansicht folgt den vorhandenen Wochenziel-Daten. Sie ändert weder einen persönlichen Kurs noch ein persönliches Hanok.';

  @override
  String get gyeSafeMessage => 'Eine sichere Nachricht senden';

  @override
  String get coachGyeTabTitle => 'Gemeinsam lernen';

  @override
  String get coachGyeTabBody =>
      'Eine Lerngruppe (Gye) ist eine kleine, nicht-kompetitive Gruppe. Euer Lernfortschritt lässt ein gemeinsames Hanok wachsen.';

  @override
  String get motivationSheetTitle => 'Warum lernst du Koreanisch?';

  @override
  String get motivationSheetSubtitle =>
      'Wähle deinen Grund. Dann können wir dich passend motivieren.';

  @override
  String get motivationKpop => 'K-Pop';

  @override
  String get motivationKdrama => 'K-Dramas & Filme';

  @override
  String get motivationTravel => 'Reise nach Korea';

  @override
  String get motivationCulture => 'Kultur & Sprache';

  @override
  String get motivationLoved => 'Freunde & Familie';

  @override
  String get motivationCareer => 'Beruf & Studium';

  @override
  String get motivationCurious => 'Einfach neugierig';

  @override
  String get motivationLineKpop => 'Bald verstehst du deine Lieblingssongs!';

  @override
  String get motivationLineKdrama => 'Bald schaust du ohne Untertitel!';

  @override
  String get motivationLineTravel =>
      'Bald bestellst du in Seoul wie ein Local!';

  @override
  String get motivationLineCulture => 'Jedes Wort öffnet eine neue Welt.';

  @override
  String get motivationLineLoved => 'Sprich bald von Herzen mit ihnen!';

  @override
  String get motivationLineCareer => 'Koreanisch öffnet neue Türen.';

  @override
  String get motivationLineCurious => 'Neugier ist der beste Lehrer!';

  @override
  String get motivationChangeLabel => 'Warum ich lerne';

  @override
  String get homeDailyGoalLabel => 'Tagesziel';

  @override
  String get homeDailyGoalDone => 'Tagesziel erreicht!';

  @override
  String get cultureNoteTitle => 'K-Kultur';

  @override
  String milestoneStreakTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage in Folge!',
      one: '1 Tag in Folge!',
    );
    return '$_temp0';
  }

  @override
  String milestoneLevelTitle(int count) {
    return 'Level $count erreicht!';
  }

  @override
  String milestoneVocabTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter gelernt!',
      one: '1 Wort gelernt!',
    );
    return '$_temp0';
  }

  @override
  String get milestoneStreakBody =>
      'Regelmäßiges Lernen zahlt sich aus. Weiter so!';

  @override
  String get milestoneLevelBody => 'Dein Koreanisch wächst mit jedem Tag.';

  @override
  String get milestoneVocabBody => 'Wort für Wort kommst du ans Ziel!';

  @override
  String get milestoneCta => 'Weiter';

  @override
  String get feedbackCompletionContinue => 'Weiter';

  @override
  String get practiceEyebrow => 'Ohne Tagesmission';

  @override
  String get practiceTitle => 'Was willst du gerade festigen?';

  @override
  String get practiceSubtitle => 'Wähle eine Absicht, nicht erst ein Spiel.';

  @override
  String get practiceDueTitle => 'Fällige Wörter wiederholen';

  @override
  String get practiceDueEmpty => 'Öffne eine Wiederholung, wann du möchtest';

  @override
  String practiceDueContext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter warten auf Kontext',
      one: '1 Wort wartet auf Kontext',
      zero: 'Keine Wörter warten auf Kontext',
    );
    return '$_temp0';
  }

  @override
  String get practiceWordsPurposeTitle => 'Meine Wörter öffnen';

  @override
  String get practiceSecLearn => 'Etwas gezielt üben';

  @override
  String get practiceSecGames => 'Spielen';

  @override
  String get practiceSecWords => 'Deine Wörter';

  @override
  String get practiceSecSpace => 'Dein Lernraum';

  @override
  String get practiceFocusedDescription =>
      'Aussprache, Grammatik oder Schreiben';

  @override
  String get practiceFreeDescription => 'Wortkette, Buchstaben, kurze Spiele';

  @override
  String get practiceWordsDescription => 'Gespeicherte Wörter und Bücher';

  @override
  String get practiceAllActivities => 'Alle Aktivitäten anzeigen';

  @override
  String get practiceHideAllActivities => 'Alle Aktivitäten ausblenden';

  @override
  String get pathEvidenceTitle => 'Woran du Fortschritt erkennst';

  @override
  String get pathEvidenceBody =>
      'Freies Ansehen zählt als Verlauf. Sicher wird ein Abschnitt erst durch die passende aktive Prüfung und mindestens 70 % in jeder verknüpften Szenenprüfung.';

  @override
  String get coachBookTitle => 'Buchseite einlesen';

  @override
  String get coachBookStep1 =>
      '📸 Mach ein Foto von deinem Lehrbuch oder einer Speisekarte';

  @override
  String get coachBookStep2 =>
      '🔍 Der Text wird automatisch erkannt und analysiert';

  @override
  String get coachBookStep3 => 'Neue Wörter landen direkt in deiner Wortliste';

  @override
  String get coachBookLimitNote => 'Tageslimit: 20 Seiten';

  @override
  String get coachVocabPackTitle => 'In 3 Schritten lernen';

  @override
  String get coachVocabPackStep1 =>
      'Schritt 1 · Lernen: Karte antippen oder ? zum Umdrehen, dann nach oben wischen. Herz = später üben, Lesezeichen = Wörterbuch';

  @override
  String get coachVocabPackStep2 =>
      'Schritt 2 · Quiz: Wähle die richtige Übersetzung';

  @override
  String get coachVocabPackStep3 =>
      'Schritt 3 · Boss: Hör zu und wähle die Bedeutung';

  @override
  String get coachPackStageQuiz =>
      'Jetzt das Quiz! Wähle die richtige Übersetzung.';

  @override
  String get coachPackStageBoss => 'Jetzt kommt der Boss. Hör genau hin!';

  @override
  String get coachBtnGotIt => 'Alles klar!';

  @override
  String get previewSkip => 'Überspringen';

  @override
  String get previewNext => 'Weiter';

  @override
  String get previewStart => 'Loslegen';

  @override
  String get previewPage1Title => 'Ein Foto statt 30-mal tippen';

  @override
  String get previewPage1Body =>
      'Fotografiere eine Lehrbuchseite oder Speisekarte. Sori erkennt Wörter, Grammatik und Sätze und legt sie in dein Bücherregal. Das Bild bleibt auf deinem Gerät.';

  @override
  String get previewPage2Title => 'Dein Hanok wächst';

  @override
  String get previewPage2Body =>
      'Mit jedem gemeisterten Paket wächst dein Hanok: vom Sockel über die Säulen bis zum Ziegeldach und eigenen Jongga-Hof. Es gibt 12 Stufen.';

  @override
  String get previewPage3Title => '5 Minuten am Tag genügen';

  @override
  String get previewPage3Body =>
      'Taego meldet sich einmal täglich und hält deinen Streak am Laufen. Und wenn ein Tag mal untergeht, fängt ihn der Streak-Schutz ab.';

  @override
  String hubLearnLevel(int level) {
    return 'Level $level';
  }

  @override
  String hubLearnNextPack(String name) {
    return 'Weiter: $name';
  }

  @override
  String get hubLearnAllDone => 'Alle Pakete abgeschlossen!';

  @override
  String hubPracticeStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage in Folge',
      one: '1 Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String get hubPracticeStreakZero => 'Fang noch heute an!';

  @override
  String hubWordbookSaved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter gespeichert',
      one: '1 Wort gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get hubWordbookEmpty => 'Noch keine Wörter gespeichert';

  @override
  String get settingsTutorialResetSection => 'Einführung';

  @override
  String get settingsTutorialResetTitle => 'Einführung zurücksetzen';

  @override
  String get settingsTutorialResetSubtitle =>
      'Karussell & Tipp-Hinweise beim nächsten Start neu anzeigen';

  @override
  String get settingsTutorialResetDone => 'Einführung zurückgesetzt';

  @override
  String get navTourNext => 'Weiter';

  @override
  String get navTourSkip => 'Überspringen';

  @override
  String get navTourDone => 'Fertig';

  @override
  String get coachHomeMissionTitle => 'Hier beginnt deine erste Mission';

  @override
  String get coachHomeMissionBody =>
      'Tippe auf diese Karte. Hangul Sori sucht dir jeden Tag eine passende Aufgabe aus.';

  @override
  String get coachPracticeHubTitle => 'Üben';

  @override
  String get coachPracticeHubBody =>
      'Hier findest du Spiele, Wörter und Grammatik zum Wiederholen.';

  @override
  String get coachHomeTab0Title => 'Start';

  @override
  String get coachHomeTab0Body => 'Lernpfad & heutige Aufgaben an einem Ort';

  @override
  String get coachHomeTab1Title => 'Üben';

  @override
  String get coachHomeTab1Body => 'Spiele, Wörter & Grammatik zum Wiederholen';

  @override
  String get coachHomeTab2Title => 'Gye';

  @override
  String get coachHomeTab2Body => 'Erreicht gemeinsam eure Lernziele';

  @override
  String get coachHomeTab3Title => 'Profil';

  @override
  String get coachHomeTab3Body => 'Statistiken, Einstellungen & Konto';

  @override
  String get coachHomePathTitle => 'Lernpfad';

  @override
  String get coachHomePathBody =>
      'Schließ die Pakete der Reihe nach ab. Der Tiger wächst mit dir.';

  @override
  String get coachHomeBookTitle => 'Buchschnappschuss';

  @override
  String get coachHomeBookBody =>
      'Foto von deinem Lehrbuch direkt in die Wortliste';

  @override
  String get introSkipHint => 'Zum Überspringen tippen';

  @override
  String get bookCaptureWebNotice =>
      '📱 „Buchseite einlesen“ funktioniert nur in der mobilen App (Kamera + Texterkennung auf dem Gerät).';

  @override
  String get bookshelfCreatePackNameHint => 'z. B. Schritt 1: Lektion 5';

  @override
  String get settingsMadeWith => 'Mit ❤ in Deutschland gemacht';

  @override
  String get coachChosungStep1Title => 'Rate mit Anlauten';

  @override
  String get coachChosungStep1Body =>
      'Füll die gepunkteten Felder aus und vervollständige das Wort';

  @override
  String get coachChosungStep2Title => 'Niveau & Schwierigkeit';

  @override
  String get coachChosungStep2Body =>
      'Wähle dein Level von A1 bis C2 und ob Vokale angezeigt werden';

  @override
  String get coachChosungStep3Title => 'Antwort eingeben';

  @override
  String get coachChosungStep3Body =>
      'Gib das vollständige koreanische Wort ein und bestätige';

  @override
  String get coachSilbenStep1Title => 'Silben-Kreuzworträtsel';

  @override
  String get coachSilbenStep1Body =>
      'Fülle das Gitter: Jede Reihe ist ein koreanisches Wort. Wörter kreuzen sich an gemeinsamen Silben. Die rot markierte Zelle ist ausgewählt.';

  @override
  String get coachSilbenStep2Title => 'Hinweise lesen';

  @override
  String get coachSilbenStep2Body =>
      'Der Pfeil zeigt die Richtung im Gitter. Bedeutung und Beispielsatz helfen. ○○ steht für das gesuchte Wort.';

  @override
  String get coachSilbenStep3Title => 'Silben antippen';

  @override
  String get coachSilbenStep3Body =>
      'Tippe unten eine Silbe, um die ausgewählte Zelle zu füllen. Richtige rasten grün ein, falsche schütteln kurz';

  @override
  String get coachWordleStep1Title => '6 Versuche';

  @override
  String get coachWordleStep1Body =>
      'Rate das gesuchte Wort. Du hast 6 Versuche.';

  @override
  String get coachWordleStep2Title => 'Hinweise nutzen';

  @override
  String get coachWordleStep2Body =>
      'Silbenzahl, Wortart und Bedeutung helfen dir beim Raten';

  @override
  String get coachWordleStep3Title => 'Eingabe & Farben';

  @override
  String get coachWordleStep3Body =>
      'Eingabe → Enter · 🟩 richtig · 🟨 falsche Position · ⬜ nicht enthalten';

  @override
  String get coachKkeunmariStep1Title => 'Letzter Buchstabe zählt';

  @override
  String get coachKkeunmariStep1Body =>
      'Fang dein Wort mit der hervorgehobenen Endsilbe an';

  @override
  String get coachKkeunmariStep2Title => 'Zug & Timer';

  @override
  String get coachKkeunmariStep2Body =>
      'Du hast 30 Sekunden pro Zug. Kannst du den Tiger schlagen?';

  @override
  String get coachKkeunmariStep3Title => 'Wort eingeben';

  @override
  String get coachKkeunmariStep3Body =>
      'Gib ein gültiges koreanisches Wort ein. Der Tiger antwortet automatisch.';

  @override
  String get coachListeningStep1Title => 'Situation wählen';

  @override
  String get coachListeningStep1Body =>
      'Tippe auf eine Karte, um die passende Situation auszuwählen';

  @override
  String get coachListeningStep2Title => 'Tempo';

  @override
  String get coachListeningStep2Body =>
      'Oben ein Tempo-Symbol. ? zeigt die Übersetzung auf der Zeile, nicht als Chip-Leiste.';

  @override
  String get coachListeningStep3Title => 'Zeile für Zeile';

  @override
  String get coachListeningStep3Body =>
      'Nach oben wischen für die nächste Zeile. Doppeltipp ist ein Like, nicht die Wortliste.';

  @override
  String get coachHangulTitle => 'Drei Tabs zum Hangul-Lernen';

  @override
  String get coachHangulBody =>
      'Übersicht zeigt alle Zeichen · Karten helfen beim Üben · Schreiben trainiert den Strich';

  @override
  String get coachGrammarStep1Title => 'Karte umdrehen';

  @override
  String get coachGrammarStep1Body =>
      'Tippe auf die Karte, um Erklärung und Beispiele zu sehen';

  @override
  String get coachGrammarStep2Title => 'Filtern & markieren';

  @override
  String get coachGrammarStep2Body =>
      'Wähle Niveau oder Typ. Markiere schwierige Karten mit 🤔 als schwer.';

  @override
  String get coachSmalltalkStep1Title => 'Thema auswählen';

  @override
  String get coachSmalltalkStep1Body =>
      'Tippe auf das Themenfeld, um aus 18 Kategorien zu wählen';

  @override
  String get coachSmalltalkStep2Title => 'Aussprache & Wörterbuch';

  @override
  String get coachSmalltalkStep2Body =>
      'Tippe auf eine Karte, um sie anzuhören. Mit ＋ speicherst du den Ausdruck in deiner Wortliste.';

  @override
  String get coachScenarioStep1Title => 'Schritt für Schritt';

  @override
  String get coachScenarioStep1Body =>
      'Vokabeln → Dialog → Grammatik → Quests → Ergebnis. Geh diese Schritte der Reihe nach durch.';

  @override
  String get coachScenarioStep2Title => 'Weiter & Fortschritt';

  @override
  String get coachScenarioStep2Body =>
      'Tippe Weiter zum nächsten Schritt · der Balken oben zeigt deinen Fortschritt';

  @override
  String get coachReviewStep1Title => 'Karte aufdecken';

  @override
  String get coachReviewStep1Body =>
      'Denk zuerst an die Bedeutung. Tippe dann auf die Karte, um die Antwort zu sehen.';

  @override
  String get coachReviewStep2Title => 'Gewusst oder nicht?';

  @override
  String get coachReviewStep2Body =>
      '\"Gewusst\" verlängert das Intervall · \"Nicht gewusst\" bringt die Karte früher zurück. Nach dem Umdrehen geht auch Wischen: rechts = gewusst, links = nicht gewusst.';

  @override
  String get coachLegacyVocabTitle => 'Karteikarte';

  @override
  String get coachLegacyVocabBody =>
      'Antippen = umdrehen · lang halten = langsam vorlesen lassen';

  @override
  String get coachLearningPathTitle => 'Dein Lernpfad';

  @override
  String get coachLearningPathBody =>
      'Starte beim hervorgehobenen aktuellen Schritt und arbeite dich von dort aus weiter.';

  @override
  String get coachBookshelfStep1Title => 'Wortliste erstellen';

  @override
  String get coachBookshelfStep1Body =>
      'Tippe auf ＋ oben rechts, um eine eigene Wortliste anzulegen';

  @override
  String get coachBookshelfStep2Title => 'Gespeicherte Wörter suchen';

  @override
  String get coachBookshelfStep2Body =>
      'Tippe auf 🔍, um alle gespeicherten Wörter zu durchsuchen und nach Wortart zu filtern';

  @override
  String get coachCpEditStep1Title => 'Wörter hinzufügen';

  @override
  String get coachCpEditStep1Body =>
      'Tippe auf ＋ Wort hinzufügen · oder importiere per CSV · Foto · Auto-Ausfüllen';

  @override
  String get coachCpEditStep2Title => '4 Lernmodi';

  @override
  String get coachCpEditStep2Body =>
      'Karten · Zuordnen · Schreiben · Quiz. Wähle den Modus, der zu dir passt.';

  @override
  String get coachCpPlayTitle => 'Karteikarten lernen';

  @override
  String get coachCpPlayBody =>
      'Antippen = Karte umdrehen · \"Gewusst\" = Wort zum Wiederholen hinzufügen';

  @override
  String get coachCpQuizTitle => 'Bedeutung erraten';

  @override
  String get coachCpQuizBody =>
      'Wähle die richtige Bedeutung. Dein Ergebnis wird für die Wiederholung gespeichert.';

  @override
  String get coachCpMatchingTitle => 'Paare zuordnen';

  @override
  String get coachCpMatchingBody =>
      'Tippe links ein koreanisches Wort an, dann rechts die passende Bedeutung';

  @override
  String get coachCpTypingTitle => 'Wort eintippen';

  @override
  String get coachCpTypingBody =>
      'Sieh die Bedeutung und tippe das koreanische Wort ein. Das trainiert mehr als bloßes Wiedererkennen.';

  @override
  String get coachHardWordsTitle => 'Hartnäckige Wörter';

  @override
  String get coachHardWordsBody =>
      'Hier findest du Wörter, die dir noch schwerfallen. Du kannst sie gezielt wiederholen.';

  @override
  String get coachDojangTitle => 'Dancheong-Stempel sammeln';

  @override
  String get coachDojangBody =>
      'Schließe Vokabelpacks ab, um alle 25 Stempel freizuschalten';

  @override
  String get coachGyeStep1Title => 'Wochenziel';

  @override
  String get coachGyeStep1Body =>
      'Hier seht ihr euren gemeinsamen Fortschritt. Zusammen bleibt ihr leichter dran.';

  @override
  String get coachGyeStep2Title => 'Sticker senden';

  @override
  String get coachGyeStep2Body =>
      'Tippe auf den Smiley-Button, um einen Sticker zur Motivation zu senden';

  @override
  String get coachProfileTitle => 'Dein Konto';

  @override
  String get coachProfileBody =>
      'Verbinde dich mit Google. So bleiben Streak und Vokabeln bei einem Handywechsel erhalten.';

  @override
  String get coachStatsTitle => 'Lernstatistiken';

  @override
  String get coachStatsBody =>
      'Streak, XP und Trefferquote zeigen, wie weit du schon gekommen bist';

  @override
  String get coachQuestsTitle => 'Quests & Belohnungen';

  @override
  String get coachQuestsBody =>
      'Erledige Quests und erhalte Dekorationen für deine Hanok-Stuben';

  @override
  String get coachScenariosTitle => 'Situationsgespräche';

  @override
  String get coachScenariosBody =>
      'Tippe auf ein Szenario und übe echte Alltagssituationen. Sie werden ab A2 freigeschaltet.';

  @override
  String get questSatzBauenInstruction =>
      'Tippe die Wörter in der richtigen Reihenfolge an';

  @override
  String get questCheckAnswer => 'Antwort prüfen';

  @override
  String get questReplayAudio => 'Erneut anhören';

  @override
  String get questListenAudio => 'Audio anhören';

  @override
  String get questBuildAnswerLabel => 'Deine Antwort bauen';

  @override
  String get questEmptyAnswerSlot => 'Leerer Antwortplatz';

  @override
  String get diktatInstruction => 'Hör zu und tippe, was du hörst';

  @override
  String get diktatAnswerLabel => 'Deine koreanische Antwort';

  @override
  String get diktatListenSlow => 'Audio langsam anhören';

  @override
  String get diktatSpacingHint => 'Fast! Achte auf die Wortabstände';

  @override
  String get diktatShowMeaning => 'Bedeutung zeigen';

  @override
  String get diktatSpellingHint => 'Fast richtig. Achte auf die Schreibweise.';

  @override
  String get questDiagOrder =>
      'Die Wörter stimmen, aber die Reihenfolge noch nicht.';

  @override
  String get questDiagParticle => 'Fast! Achte auf die Partikel (조사)';

  @override
  String get questDiagCount => 'Achte auf die Anzahl der Wörter';

  @override
  String get questDiagWord =>
      'Ein Wort passt nicht. Schau dir das markierte Wort an.';

  @override
  String get scenarioRoleplayTitle => 'Rollenspiel';

  @override
  String get scenarioRoleplayHint =>
      'Jetzt bist du dran. Baue die Antwort aus den Kacheln.';

  @override
  String get scenarioRoleplayTurn => 'Deine Antwort';

  @override
  String get scenarioRoleplayDoneTitle => 'Rollenspiel geschafft!';

  @override
  String get scenarioRoleplayDoneBody => 'Du hast das Gespräch selbst geführt.';

  @override
  String get scenarioWriteAfterRoleplayTitle =>
      'Antworte mit deinen eigenen Worten';

  @override
  String get scenarioWriteAfterRoleplayBody =>
      'Schreibe eine kurze koreanische Antwort für diese Situation. Die freiwillige Prüfung beeinflusst deine Punktzahl nicht.';

  @override
  String get scenarioWriteAfterRoleplayInputLabel => 'Dein koreanischer Satz';

  @override
  String get scenarioWriteAfterRoleplayInputHint =>
      'Schreibe eine kurze Antwort auf Koreanisch';

  @override
  String get scenarioWriteAfterRoleplayCheck => 'Satz prüfen';

  @override
  String get scenarioWriteAfterRoleplayChecking => 'Wird geprüft…';

  @override
  String get scenarioWriteAfterRoleplayDownload =>
      'Prüfung auf das Gerät laden';

  @override
  String get scenarioWriteAfterRoleplayDownloading => 'Prüfung wird geladen…';

  @override
  String get scenarioWriteAfterRoleplayOriginalLabel => 'Dein Original';

  @override
  String get scenarioWriteAfterRoleplaySuggestionLabel => 'Vorschlag';

  @override
  String get scenarioWriteAfterRoleplayChangesLabel => 'Geprüfte Änderungen';

  @override
  String get scenarioWriteAfterRoleplayChangeReasonUnavailable =>
      'Die Prüfung auf dem Gerät liefert keinen verifizierten Grund für jede einzelne Änderung.';

  @override
  String get scenarioWriteAfterRoleplaySceneGrammarReference =>
      'Grammatikhilfe aus dieser Szene';

  @override
  String get scenarioWriteAfterRoleplayWhyLabel => 'Grammatik dieser Szene';

  @override
  String get scenarioWriteAfterRoleplayNoChanges =>
      'Keine Änderung vorgeschlagen.';

  @override
  String get scenarioWriteAfterRoleplayFallbackTitle => 'Mit dieser Szene üben';

  @override
  String get scenarioWriteAfterRoleplayFallbackBody =>
      'Die automatische Prüfung ist hier nicht verfügbar. Du kannst deinen Satz trotzdem mit der belegten Szenensprache und Grammatik vergleichen.';

  @override
  String get scenarioWriteAfterRoleplayDownloadRequired =>
      'Lade die Prüfung auf das Gerät, bevor du deinen Satz prüfst.';

  @override
  String get scenarioWriteAfterRoleplayReady =>
      'Die Prüfung ist bereit. Tippe noch einmal auf Satz prüfen.';

  @override
  String get scenarioWriteAfterRoleplayAskCompanion =>
      'Nach der Grammatik dieser Szene fragen';

  @override
  String get scenarioWriteAfterRoleplayCompanionTitle =>
      'Erklärung aus dieser Szene';

  @override
  String get testerFeedbackCardTitle => 'Tiger-Check';

  @override
  String get testerFeedbackCardBody =>
      'Zwei kurze Auswahlen helfen uns, Hangul Sori besser zu machen.';

  @override
  String get testerFeedbackCardCta => 'Gib dem Tiger einen Hinweis';

  @override
  String get testerFeedbackCategoryBug => 'Fehler melden';

  @override
  String get testerFeedbackCategoryContent => 'Lerninhalt bewerten';

  @override
  String get testerFeedbackCategoryOther => 'Etwas anderes';

  @override
  String get testerFeedbackIssueAreaLabel => 'Was betrifft das Problem?';

  @override
  String get testerFeedbackIssueAreaUi => 'Anzeige';

  @override
  String get testerFeedbackIssueAreaAnswer => 'Antwort';

  @override
  String get testerFeedbackIssueAreaAudio => 'Audio';

  @override
  String get testerFeedbackIssueAreaTranslation => 'Übersetzung';

  @override
  String get testerFeedbackIssueAreaNavigation => 'Navigation';

  @override
  String get testerFeedbackIssueAreaOther => 'Etwas anderes';

  @override
  String get testerFeedbackContentSignalLabel =>
      'Wie war diese Übung für dich?';

  @override
  String get testerFeedbackContentSignalTooEasy => 'Zu leicht';

  @override
  String get testerFeedbackContentSignalRight => 'Genau richtig';

  @override
  String get testerFeedbackContentSignalTooHard => 'Zu schwer';

  @override
  String get testerFeedbackContentSignalUnclear => 'Unklar';

  @override
  String get testerFeedbackContentFocusLabel => 'Woran lag es?';

  @override
  String get testerFeedbackContentFocusExplanation => 'Erklärung';

  @override
  String get testerFeedbackContentFocusExamples => 'Beispiele';

  @override
  String get testerFeedbackContentFocusQuestions => 'Aufgaben';

  @override
  String get testerFeedbackContentFocusPace => 'Tempo';

  @override
  String get testerFeedbackContentFocusAudio => 'Audio';

  @override
  String get testerFeedbackContentFocusTranslation => 'Übersetzung';

  @override
  String get testerFeedbackContentFocusOther => 'Etwas anderes';

  @override
  String get testerFeedbackPulseLearningPrompt =>
      'Wie war diese Übung für dich?';

  @override
  String get testerFeedbackPulseBookPrompt =>
      'Wie zuverlässig wirkte dieses Ergebnis?';

  @override
  String get testerFeedbackPulseQuestPrompt => 'Hat sich diese Quest gelohnt?';

  @override
  String get testerFeedbackPulseMilestonePrompt =>
      'Hat dich diese Feier motiviert?';

  @override
  String get testerFeedbackPulseReasonPrompt => 'Woran lag es?';

  @override
  String get testerFeedbackPulsePositiveReasonPrompt =>
      'Was hat gut funktioniert?';

  @override
  String get testerFeedbackExperienceReasonPrompt =>
      'Was hat deine Einschätzung beeinflusst?';

  @override
  String get testerFeedbackBookSignalPositive => 'Wirkt richtig';

  @override
  String get testerFeedbackBookSignalMixed => 'Teilweise richtig';

  @override
  String get testerFeedbackBookSignalNegative => 'Wirkt nicht richtig';

  @override
  String get testerFeedbackBookSignalUnsure => 'Nicht sicher';

  @override
  String get testerFeedbackQuestSignalPositive => 'Sehr motivierend';

  @override
  String get testerFeedbackQuestSignalMixed => 'Nettes Extra';

  @override
  String get testerFeedbackQuestSignalNegative => 'Nicht motivierend';

  @override
  String get testerFeedbackQuestSignalUnsure => 'Nicht verstanden';

  @override
  String get testerFeedbackMilestoneSignalPositive => 'Hat mich gefreut';

  @override
  String get testerFeedbackMilestoneSignalMixed => 'Schön';

  @override
  String get testerFeedbackMilestoneSignalNegative => 'Zu viel';

  @override
  String get testerFeedbackMilestoneSignalUnsure => 'Nicht bedeutsam';

  @override
  String get testerFeedbackExperienceFocusKoreanText => 'Koreanischer Text';

  @override
  String get testerFeedbackExperienceFocusWordMeanings => 'Wortbedeutungen';

  @override
  String get testerFeedbackExperienceFocusGrammar => 'Grammatik';

  @override
  String get testerFeedbackExperienceFocusTranslation => 'Übersetzung';

  @override
  String get testerFeedbackExperienceFocusResultMissing => 'Ergebnis fehlt';

  @override
  String get testerFeedbackExperienceFocusGoal => 'Ziel';

  @override
  String get testerFeedbackExperienceFocusDifficulty => 'Schwierigkeit';

  @override
  String get testerFeedbackExperienceFocusReward => 'Belohnung';

  @override
  String get testerFeedbackExperienceFocusInstructions => 'Anleitung';

  @override
  String get testerFeedbackExperienceFocusLength => 'Dauer';

  @override
  String get testerFeedbackExperienceFocusTiming => 'Zeitpunkt';

  @override
  String get testerFeedbackExperienceFocusVisuals => 'Optik';

  @override
  String get testerFeedbackExperienceFocusMessage => 'Text';

  @override
  String get testerFeedbackExperienceFocusFrequency => 'Häufigkeit';

  @override
  String get testerFeedbackExperienceFocusOther => 'Etwas anderes';

  @override
  String get testerFeedbackBugExpectedLabel => 'Was sollte passieren?';

  @override
  String get testerFeedbackBugExpectedHint =>
      'Beschreibe kurz das erwartete Verhalten.';

  @override
  String get testerFeedbackBugActualLabel => 'Was ist stattdessen passiert?';

  @override
  String get testerFeedbackBugActualHint =>
      'Beschreibe kurz das tatsächliche Verhalten.';

  @override
  String get testerFeedbackBugFrequencyLabel => 'Wie oft ist das passiert?';

  @override
  String get testerFeedbackBugFrequencyEveryTime => 'Jedes Mal';

  @override
  String get testerFeedbackBugFrequencySometimes => 'Manchmal';

  @override
  String get testerFeedbackBugFrequencyOnce => 'Einmal';

  @override
  String get testerFeedbackBugImpactLabel =>
      'Wie stark hat es dich beeinträchtigt?';

  @override
  String get testerFeedbackBugImpactCanContinue => 'Ich konnte weitermachen';

  @override
  String get testerFeedbackBugImpactSlowsLearning => 'Es hat mich aufgehalten';

  @override
  String get testerFeedbackBugImpactBlocksLearning =>
      'Ich konnte nicht weitermachen';

  @override
  String get testerFeedbackBugRequired =>
      'Fülle bitte alle Pflichtfelder des Fehlerberichts aus.';

  @override
  String get testerFeedbackMessageLabel => 'Optionaler Hinweis';

  @override
  String get testerFeedbackMessageHint => 'Möchtest du noch etwas ergänzen?';

  @override
  String get testerFeedbackOtherMessageLabel => 'Dein Hinweis';

  @override
  String get testerFeedbackOtherMessageHint =>
      'Was möchtest du uns noch sagen?';

  @override
  String get testerFeedbackMessageRequired =>
      'Bitte schreibe eine kurze Nachricht.';

  @override
  String get testerFeedbackContentFeedbackRequired =>
      'Wähle bitte ein Signal und einen Schwerpunkt aus.';

  @override
  String get testerFeedbackMessageTooLong =>
      'Deine Nachricht darf höchstens 1.000 Zeichen lang sein.';

  @override
  String get testerFeedbackSubmit => 'Check senden';

  @override
  String get testerFeedbackCancel => 'Abbrechen';

  @override
  String get testerFeedbackBack => 'Zurück';

  @override
  String get testerFeedbackSubmitting => 'Feedback wird gesendet …';

  @override
  String get testerFeedbackSubmitted =>
      'Danke. Dein Feedback hilft uns, besser zu werden.';

  @override
  String get testerFeedbackStampAccepted => 'Stempel gesammelt!';

  @override
  String get testerFeedbackPending =>
      'Auf diesem Gerät gespeichert. Wir senden es, sobald du wieder online bist.';

  @override
  String get testerFeedbackSubmitFailed =>
      'Feedback konnte noch nicht gesendet werden.';

  @override
  String get testerFeedbackRetry => 'Erneut versuchen';

  @override
  String get testerFeedbackPrivacyReminder =>
      'Nenne bitte keine Kontaktdaten, Antworten, persönlichen Daten oder Screenshots.';

  @override
  String get testerFeedbackMissionScenario => 'Ein Szenario abschließen';

  @override
  String get testerFeedbackMissionWordWork => 'Mit Wörtern üben';

  @override
  String get testerFeedbackMissionListening => 'Eine Hörübung abschließen';

  @override
  String get testerFeedbackMissionGames => 'Eine Spielrunde abschließen';

  @override
  String get testerFeedbackMissionLanguageForm => 'Grammatik oder Hangul üben';

  @override
  String get testerFeedbackCompleteGrammar => 'Grammatikübung abschließen';

  @override
  String get testerFeedbackCompleteHangul => 'Hangul-Übung abschließen';

  @override
  String get testerFeedbackCompleteDailyHangul =>
      'Heutiges Zeichen abschließen';

  @override
  String get testerFeedbackPromptScenario =>
      'Gab es eine Stelle, die du in dieser Situation wirklich sagen würdest?';

  @override
  String get testerFeedbackPromptWordWork =>
      'Fühlen sich diese Wörter nützlich und einprägsam an?';

  @override
  String get testerFeedbackPromptGrammar =>
      'Machen Erklärung und Beispiele die Regel verständlich?';

  @override
  String get testerFeedbackPromptHangul =>
      'Fühlt sich die Verbindung zwischen Buchstabenform und Laut natürlich an?';

  @override
  String get testerFeedbackPromptGame =>
      'Würdest du dieses Spiel noch einmal spielen? Was würdest du ändern?';

  @override
  String get testerFeedbackPromptListening =>
      'Sind Tempo und Stimmen gut verständlich?';

  @override
  String get testerFeedbackPromptGeneric =>
      'Was würde diese Lernaktivität besser machen?';

  @override
  String testerFeedbackPassportProgress(int completed, int total) {
    return 'Testerpass $completed / $total';
  }

  @override
  String testerFeedbackNextMission(String mission) {
    return 'Nächste Beta-Mission: $mission';
  }

  @override
  String get onboardingDiagnosticCta => 'Unsicher? 8 Fragen beantworten';

  @override
  String get placementTitle => 'Kurzer Einstufungscheck';

  @override
  String placementProgress(Object current, Object total) {
    return 'Frage $current von $total';
  }

  @override
  String get placementNoRecording =>
      'Keine Aufnahme. Wähle einfach die beste Antwort.';

  @override
  String get placementSeeRecommendation => 'Empfehlung ansehen';

  @override
  String get placementRecommendedStart => 'Empfohlener Start';

  @override
  String placementScoreSummary(Object correct, Object total) {
    return 'Du hattest $correct von $total richtig. Das ist nur eine Empfehlung: Du kannst jede Stufe wählen.';
  }

  @override
  String placementStartAt(Object level) {
    return 'Mit $level starten';
  }

  @override
  String get placementChooseYourself => 'Oder selbst wählen';

  @override
  String get courseMissionTitle => 'Deine nächste Mission';

  @override
  String get courseMissionTitleShort => 'Kursmission';

  @override
  String get courseMissionLoadError =>
      'Die Kursdaten konnten nicht geladen werden.';

  @override
  String get courseMissionCompleteTitle => 'Mission abgeschlossen';

  @override
  String get courseMissionCompleteBody =>
      'Du hast alle Lernschritte dieser Mission abgeschlossen.';

  @override
  String get courseMissionNow => 'jetzt';

  @override
  String get courseMissionPreviewTag => 'Vorschau';

  @override
  String get courseMissionStartPractice => 'Übung starten';

  @override
  String courseMissionBriefScene(String scene) {
    return 'Deine nächste Szene: $scene';
  }

  @override
  String courseMissionBriefTime(int minutes) {
    return '$minutes Min. bis zur Szene';
  }

  @override
  String courseMissionBriefStepMeta(int current, int total, int minutes) {
    return 'Schritt $current von $total · $minutes Min.';
  }

  @override
  String courseMissionBriefRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Schritte bleiben nach diesem Überblick bereit.',
      one: '1 weiterer Schritt bleibt nach diesem Überblick bereit.',
    );
    return '$_temp0';
  }

  @override
  String get courseMissionBriefStart => 'Schritt 1 starten';

  @override
  String get courseMissionBriefWhy => 'Warum diese Szene?';

  @override
  String get courseMissionBriefStepVocab => 'Schlüsselwörter hören';

  @override
  String get courseMissionBriefStepGrammar => 'Den Satz bauen';

  @override
  String get courseMissionBriefStepCloze => 'Fehlende Wörter wählen';

  @override
  String get courseMissionBriefStepSatz => 'Den Satz zusammensetzen';

  @override
  String get courseMissionBriefStepScenario => 'In der Szene sprechen';

  @override
  String get courseMissionBriefStepSmalltalk => 'In der Situation antworten';

  @override
  String get courseMissionBriefListenTitle => 'Höre die Situation';

  @override
  String get courseMissionBriefListenBody => 'Erkenne die höfliche Form';

  @override
  String get courseMissionBriefBuildTitle => 'Baue deinen Satz';

  @override
  String get courseMissionBriefBuildBody => 'Wähle die fehlenden Wörter';

  @override
  String get courseMissionBriefCheckpointTitle => 'Mach den Abschlusscheck';

  @override
  String get courseMissionBriefCheckpointBody =>
      'Löse die letzte Aufgabe dieser Mission';

  @override
  String get courseMissionBriefSceneTitle => 'Sprich in der Szene';

  @override
  String get courseMissionBriefSceneBody => 'Eine echte Antwort, kein Raten';

  @override
  String get courseMissionBriefListenCta => 'Jetzt hören';

  @override
  String get courseMissionBriefBuildCta => 'Jetzt bauen';

  @override
  String get courseMissionBriefCheckpointCta => 'Abschlusscheck starten';

  @override
  String get courseMissionBriefSceneCta => 'Szene beginnen';

  @override
  String courseMissionBriefMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get courseMissionPreviewNotice =>
      'Du kannst diese Mission ansehen. Punkte und Fortschritt zählen erst, wenn sie aktiv ist.';

  @override
  String get courseReassessmentTitle => 'Fähigkeit nachweisen';

  @override
  String get courseReassessmentEyebrow => 'PRODUKTIVER NACHWEIS';

  @override
  String get courseReassessmentLoading => 'Deine Aufgabe wird vorbereitet.';

  @override
  String get courseReassessmentLoadError =>
      'Dieser Nachweis konnte nicht sicher geladen werden.';

  @override
  String get courseReassessmentError =>
      'Der Nachweis konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String courseReassessmentStep(int current, int total) {
    return 'Nachweis $current von $total';
  }

  @override
  String courseReassessmentProjectStep(int current, int total) {
    return 'Projektschritt $current von $total';
  }

  @override
  String get courseReassessmentRole => 'Deine Rolle';

  @override
  String get courseReassessmentPrivacy =>
      'Freie Texte und Notizen werden weder an Firebase noch an Analytics gesendet. Ein verifizierter Sprechnachweis bleibt deaktiviert, bis die gesonderte Einwilligung und der datensparsame Dienst bereit sind.';

  @override
  String get courseReassessmentAnswer => 'Deine koreanische Antwort';

  @override
  String get courseReassessmentAnswerHint =>
      'Schreibe die Aussage in deinen eigenen Worten.';

  @override
  String courseReassessmentLength(int minimum, int maximum) {
    return '$minimum bis $maximum koreanische Zeichen';
  }

  @override
  String courseReassessmentEvidencePoint(int index) {
    return 'Belegpunkt $index';
  }

  @override
  String get courseReassessmentEvidencePointHint =>
      'Formuliere diesen Punkt auf Koreanisch und übernimm ihn in deine Gesamtantwort.';

  @override
  String get courseReassessmentSourceForPoint => 'Quelle für diesen Punkt';

  @override
  String get courseReassessmentSources => 'Materialien vergleichen';

  @override
  String courseReassessmentSource(int index) {
    return 'Quelle $index';
  }

  @override
  String get courseReassessmentProjectReviewTitle =>
      'Quellen vor der Antwort prüfen';

  @override
  String get courseReassessmentProjectReviewBody =>
      'Lies jede neu eingeführte Quelle und öffne ihren Herkunftshinweis. Gespeichert werden nur die Quellen-IDs, nicht deine Notizen.';

  @override
  String get courseReassessmentProjectMarkReviewed =>
      'Ich habe diese Quelle gelesen und verglichen';

  @override
  String get courseReassessmentProjectShowProvenance => 'Herkunft anzeigen';

  @override
  String get courseReassessmentProjectHideProvenance => 'Herkunft ausblenden';

  @override
  String get courseReassessmentProjectCompleteReview =>
      'Quellenprüfung abschließen';

  @override
  String get courseReassessmentProjectReviewing => 'Quellen werden geprüft …';

  @override
  String get courseReassessmentProjectReviewIncomplete =>
      'Lies jede Quelle und öffne jeden Herkunftshinweis, bevor du fortfährst.';

  @override
  String get courseReassessmentConnectSources =>
      'Beziehungen zwischen den Quellen markieren';

  @override
  String get courseReassessmentRelationship => 'Rolle dieser Quelle';

  @override
  String get courseReassessmentSubmit => 'Antwort prüfen';

  @override
  String get courseReassessmentSubmitEvidence => 'Quellenverknüpfung prüfen';

  @override
  String get courseReassessmentChecking => 'Wird geprüft …';

  @override
  String get courseReassessmentOralUnavailableTitle =>
      'Verifizierter Sprechnachweis ist noch nicht verfügbar';

  @override
  String get courseReassessmentOralUnavailableBody =>
      'Die aktuelle zehnsekündige Nachsprechübung trainiert nur die Aussprache und darf dieses Fähigkeitssiegel nicht vergeben. Eine eigene 45- bis 120-sekündige freie Sprechprüfung wird erst nach Prüfung von Einwilligung, Datenschutz und Bewertung freigeschaltet.';

  @override
  String get courseReassessmentPrerequisiteTitle =>
      'Ein früherer Nachweis fehlt noch';

  @override
  String get courseReassessmentPrerequisiteBody =>
      'Schließe zuerst den verknüpften Nachweis ab. Dein Kurszeiger wird dabei nicht zurückgesetzt.';

  @override
  String get courseReassessmentOpenPrerequisite => 'Fehlenden Nachweis öffnen';

  @override
  String get courseReassessmentPassedTitle => 'Nachweis bestanden';

  @override
  String courseReassessmentPassedBody(int score) {
    return '$score %. Nur das Ergebnis und seine genaue Aufgabenherkunft wurden gespeichert.';
  }

  @override
  String get courseReassessmentTryAgainTitle => 'Noch nicht sicher genug';

  @override
  String courseReassessmentTryAgainBody(int score) {
    return '$score %. Deine Antwort wurde nicht gespeichert. Du kannst sie direkt überarbeiten.';
  }

  @override
  String get courseReassessmentContinue => 'Nächsten Nachweis öffnen';

  @override
  String get courseReassessmentRetry => 'Antwort überarbeiten';

  @override
  String get courseReassessmentFinish => 'Fertig';

  @override
  String get courseReassessmentCompleteTitle =>
      'Sprechen und Schreiben bestätigt';

  @override
  String get courseReassessmentCompleteBody =>
      'Alle erforderlichen produktiven Nachweise für diese Fähigkeit sind geprüft. Deine Kursposition ist unverändert geblieben.';

  @override
  String get courseReassessmentModeGuidedProduction =>
      'Geführte eigene Antwort';

  @override
  String get courseReassessmentModeDictation => 'Diktat';

  @override
  String get courseReassessmentModeConnectedProduction =>
      'Zusammenhängend schreiben';

  @override
  String get courseReassessmentModeOpenWriting => 'Offen schreiben';

  @override
  String get courseReassessmentModeOral => 'Mündlich vortragen';

  @override
  String get courseReassessmentModeConnectedEvidence => 'Quellen verknüpfen';

  @override
  String get courseReassessmentRoleSupport => 'stützt die Aussage';

  @override
  String get courseReassessmentRoleContrast => 'zeigt einen Gegensatz';

  @override
  String get courseReassessmentRoleLimitation => 'begrenzt die Aussage';

  @override
  String get courseReassessmentRoleComplement => 'ergänzt die Aussage';

  @override
  String get courseReassessmentRoleContext => 'liefert Kontext';

  @override
  String get courseReassessmentRoleStakeholder =>
      'zeigt eine betroffene Perspektive';

  @override
  String get courseReassessmentRoleCounterexample =>
      'liefert ein Gegenbeispiel';

  @override
  String get courseSectionToday => 'Was heute zählt';

  @override
  String get courseSectionFamilies => 'Ausdrucksfamilien';

  @override
  String get courseSectionSurfaces => 'Karten aus dem echten Alltag';

  @override
  String get courseSectionRepair => 'Kurz korrigieren';

  @override
  String get courseSectionPractice => 'Missionsübungen';

  @override
  String get coursePracticeVocab => 'Wortschatz üben';

  @override
  String get coursePracticeGrammar => 'Grammatikkarten';

  @override
  String get coursePracticeCloze => 'Lückentext';

  @override
  String get coursePracticeSatz => 'Satz bauen';

  @override
  String get coursePracticeScenario => 'Szenario-Checkpoint';

  @override
  String get coursePracticeSmalltalk => 'Small Talk';

  @override
  String get courseCheckpointCheck => 'Kurz prüfen';

  @override
  String get courseCheckpointGrammarPrompt =>
      'Welches Muster passt zu diesem Beispiel?';

  @override
  String get courseCheckpointSmalltalkPrompt =>
      'Für welche Beziehung ist dieser Satz sicher?';

  @override
  String get courseCheckpointCorrect =>
      'Richtig. Diese Mission hat einen Nachweis erhalten.';

  @override
  String get courseCheckpointIncorrect =>
      'Noch einmal ansehen. Die sichere Wahl ist markiert.';

  @override
  String get courseCheckpointSaved => 'In dieser Sitzung bereits gespeichert.';

  @override
  String get courseCheckpointSaveError =>
      'Dein Fortschritt konnte nicht gespeichert werden. Bitte versuche es noch einmal.';

  @override
  String get courseStatePreview => 'Vorschau';

  @override
  String get courseStateIntroduced => 'Eingeführt';

  @override
  String get courseStatePractice => 'Üben';

  @override
  String get courseStateCheckpointPassed => 'Checkpoint geschafft';

  @override
  String get courseStateReviewDue => 'Kurz korrigieren';

  @override
  String get courseStateStable => 'Sicher';

  @override
  String get courseAxisBatchim => 'Endkonsonant (받침)';

  @override
  String get courseAxisSentenceRole => 'Satzrolle';

  @override
  String get courseAxisRelationship => 'Beziehung und Situation';

  @override
  String get courseAxisSetting => 'Ort und Anlass';

  @override
  String get courseUsageOfficial => 'offizieller Rahmen';

  @override
  String get courseUsageEverydayPolite => 'höflicher Alltag';

  @override
  String get courseUsageCloseOnly => 'nur bei enger Beziehung';

  @override
  String get courseUsageOfficialOrService => 'offiziell oder im Service';

  @override
  String get courseUsageFriendlyPolite => 'freundlich und höflich';

  @override
  String get courseUsageServiceRequest => 'Service-Anfrage';

  @override
  String get courseUsagePaymentNotice => 'Zahlungshinweis';

  @override
  String get moduleBadgeNew => 'NEU';

  @override
  String get moduleBadgeDue => 'FÄLLIG';

  @override
  String get homeMadangEyebrow => 'Heute im Sarangbang';

  @override
  String get homeSarangbangCta => 'Im Sarangbang lernen';

  @override
  String get homeTodayEyebrow => 'Deine Handlung für heute';

  @override
  String get homeTodayFirst => 'Heute zuerst';

  @override
  String get homeTodayMissionStart => 'Diese Szene beginnen';

  @override
  String get homeTodayCourseAction => 'Diese Handlung üben';

  @override
  String get homeTodayPackAction => 'Diese Wörter üben';

  @override
  String get homeTodayReviewAction => 'Wiederholen';

  @override
  String get homeTodayScenarioAction => 'Diese Szene üben';

  @override
  String get homeTodayPackDescription =>
      'Übe die Wörter, die du als Nächstes brauchst.';

  @override
  String homeTodayReviewMission(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter im Kontext wiederholen',
      one: '1 Wort im Kontext wiederholen',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayReviewDescription =>
      'Gib deinen sicheren Sätzen eine Stimme.';

  @override
  String homeTodayReviewLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wörter sind bereit, bevor etwas Neues dazukommt.',
      one: '1 Wort ist bereit, bevor etwas Neues dazukommt.',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayNextAction => 'Deine nächste Handlung';

  @override
  String get homeTodayReviewReasonTitle => 'Warum heute wiederholen?';

  @override
  String get homeTodayReviewReason =>
      'Damit Begrüßungen, Bitten und Antworten in der nächsten Szene schneller verfügbar sind.';

  @override
  String get homeTodayReviewTime =>
      'ca. 3 Minuten · danach geht dein Weg weiter';

  @override
  String get homeUnavailableEyebrow => 'Verbindung pausiert';

  @override
  String get homeUnavailableTitle => 'Dein Weg wartet auf dich.';

  @override
  String get homeUnavailableDescription =>
      'Neue Gruppen- und Kontoaktionen brauchen kurz Internet. Deine gespeicherten Wiederholungen sind bereit.';

  @override
  String get homeUnavailableDescriptionNoReview =>
      'Neue Gruppen- und Kontoaktionen brauchen kurz Internet. Versuche die Verbindung erneut.';

  @override
  String get homeUnavailableSafeTitle => 'Jetzt sicher möglich';

  @override
  String get homeUnavailableSafeBody =>
      'Gespeicherte Wörter wiederholen und bisherige Inhalte ansehen.';

  @override
  String get homeUnavailableCta => 'Gespeicherte Wörter wiederholen';

  @override
  String get homeUnavailableRetry => 'Erneut verbinden';

  @override
  String get homeUnavailableRetryGeneric => 'Erneut versuchen';

  @override
  String get homeRemoteUnavailableEyebrow => 'Dienst kurz pausiert';

  @override
  String get homeRemoteUnavailableTitle => 'Dein Weg bleibt erhalten.';

  @override
  String get homeRemoteUnavailableDescription =>
      'Der Onlinedienst antwortet gerade nicht. Deine gespeicherten Wiederholungen sind bereit.';

  @override
  String get homeRemoteUnavailableDescriptionNoReview =>
      'Der Onlinedienst antwortet gerade nicht. Versuche es gleich noch einmal.';

  @override
  String get homeLocalUnavailableEyebrow => 'Heute braucht einen neuen Versuch';

  @override
  String get homeLocalUnavailableTitle =>
      'Dein gespeichertes Lernen bleibt sicher.';

  @override
  String get homeLocalUnavailableDescription =>
      'Heute konnte nicht aus den lokalen Lerndaten vorbereitet werden. Deine gespeicherten Wiederholungen sind weiterhin bereit.';

  @override
  String get homeLocalUnavailableDescriptionNoReview =>
      'Heute konnte nicht aus den lokalen Lerndaten vorbereitet werden. Versuche, es erneut zu laden.';

  @override
  String get homeEmptyCta => 'Gespeicherte Wörter wiederholen';

  @override
  String get homeTodayScenarioDescription =>
      'Höre zu, wähle und sprich die Szene.';

  @override
  String get homeHanokPreviewTitle => 'Mein Hanok';

  @override
  String get homeHanokPreviewBody => 'Dein Lernen lässt deinen Hanok wachsen.';

  @override
  String get homeHanokPreviewCta => 'Mein Hanok öffnen';

  @override
  String homeFocusDate(String weekday) {
    return 'Heute · $weekday';
  }

  @override
  String get homeFocusBuildTitle => 'Dein Haus wächst mit echtem Können.';

  @override
  String get homeFocusMore => 'Weitere Lernmöglichkeiten';

  @override
  String get homeFocusLess => 'Weitere Lernmöglichkeiten ausblenden';

  @override
  String get homeFocusLaterTitle => 'Später heute';

  @override
  String homeFocusLaterBody(int count) {
    return '$count Wiederholungen bleiben nach deiner ersten Handlung bereit.';
  }

  @override
  String hanokNarrativeVerified(String stage, String canDo) {
    return 'Bau: $stage. Bestätigt: $canDo';
  }

  @override
  String hanokNarrativeNext(String stage, String canDo) {
    return 'Bau: $stage. Als Nächstes: $canDo';
  }

  @override
  String hanokNarrativeStarting(String stage) {
    return 'Bau: $stage. Beginne mit deiner ersten Szene.';
  }

  @override
  String get hanokNarrativeMaterialSource =>
      'Kursszenen formen die Struktur. Pakete, Wiederholungen und Quests fügen Material und Dekor hinzu.';

  @override
  String get sarangbangTitle => 'Studierstube';

  @override
  String get sarangbangEmptyTitle => 'Noch nichts zum Einrichten';

  @override
  String get sarangbangEmptyBody =>
      'Schließe Quests ab und öffne dein Bojagi-Bündel. Danach kannst du die Stube einrichten.';

  @override
  String get sarangbangPickTitle => 'Was soll hierhin?';

  @override
  String get sarangbangClear => 'Platz frei lassen';

  @override
  String get sarangbangHubDesc => 'Lerne im Sarangbang weiter.';

  @override
  String get bojagiTitle => 'Bojagi-Bündel';

  @override
  String get bojagiLoading => 'Dein Bündel wird vorbereitet …';

  @override
  String get bojagiOpenHint => 'Tippe auf den Knoten, um das Bündel zu öffnen.';

  @override
  String get bojagiPickTitle => 'Such dir eins aus';

  @override
  String get bojagiPickBody =>
      'Was du liegen lässt, bleibt im Beutel und kann in einem späteren Bündel wiederkommen.';

  @override
  String bojagiChooseDecoration(String name) {
    return '$name auswählen';
  }

  @override
  String get bojagiEmptyTitle => 'Kein Bündel wartet';

  @override
  String get bojagiEmptyBody =>
      'Schließe eine Quest ab. Dafür bekommst du ein Bündel.';

  @override
  String get bojagiAllOwnedTitle => 'Nichts Neues drin';

  @override
  String get bojagiAllOwnedBody =>
      'Alle drei Stücke aus diesem Bündel hast du schon.';

  @override
  String get bojagiProblemTitle => 'Das Bündel lässt sich gerade nicht öffnen';

  @override
  String get bojagiProblemBody =>
      'Versuch es gleich noch einmal. Dein Bündel geht dabei nicht verloren.';

  @override
  String get bojagiRetry => 'Nochmal versuchen';

  @override
  String get bojagiClaimedTitle => 'Bekommen!';

  @override
  String bojagiClaimedAnnouncement(String name) {
    return 'Bekommen: $name';
  }

  @override
  String get bojagiGoToRoom => 'In der Stube aufstellen';

  @override
  String get bojagiNext => 'Nächstes Bündel öffnen';

  @override
  String get bojagiCollectionCompleteTitle => 'Sammlung vollständig';

  @override
  String get bojagiCollectionCompleteBody =>
      'Du besitzt bereits alle Einrichtungsstücke. Lege dieses Bündel ab, um weiterzumachen.';

  @override
  String get bojagiArchiveComplete => 'Bündel ablegen';

  @override
  String get hanokWorldTitle => 'Meine Hanok-Welt';

  @override
  String get ilduWorldTitle => 'Mein Ildu Gotaek';

  @override
  String get ilduWorldPanHint =>
      'Wische seitwärts, um den nächsten Hof zu sehen.';

  @override
  String get ilduWorldRotateBuildingHint =>
      'Ziehe es auf der Karte an seinen Platz; wische über die Vorschau, um es zu drehen.';

  @override
  String get ilduWorldGateHeritageDetail =>
      'Außen bleiben die Spruchtafeln 忠孝傳家 erhalten; innen hängen fünf Jeongnyeo-Gedenktafeln über dem Tor.';

  @override
  String get ilduWorldEvidenceNote =>
      'Nur bestätigtes Lernen lässt Gebäude erscheinen.';

  @override
  String ilduWorldBuiltCount(int built, int total) {
    return '$built von $total Gebäuden';
  }

  @override
  String get ilduWorldOpenState => 'Geöffnet';

  @override
  String get ilduWorldPlannedState => 'Bauplatz';

  @override
  String get ilduWorldRecommended => 'Als Nächstes empfohlen';

  @override
  String get ilduWorldStartRecommended => 'Empfohlene Mission starten';

  @override
  String get ilduWorldExplore => 'Ort erkunden';

  @override
  String get ilduWorldDecorate => 'Hof gestalten';

  @override
  String get ilduWorldCulture => 'Kultureller Kontext';

  @override
  String get ilduWorldLockedEyebrow => 'Eine Levelwahl allein öffnet nichts';

  @override
  String ilduWorldLockedTitle(Object level) {
    return 'Schließe bestätigte Lernschritte auf $level ab.';
  }

  @override
  String get ilduWorldLockedBody =>
      'Bestätigte Lernnachweise machen aus diesem Bauplatz ein vollständiges Gebäude. Einstufung und freies Ansehen zählen nicht.';

  @override
  String get ilduWorldLockedCta => 'Passende Mission ansehen';

  @override
  String get ilduWorldDecorBody =>
      'Größe und Ausrichtung bleiben fest. Ziehe ein Stück frei innerhalb der erlaubten Höfe.';

  @override
  String get ilduWorldDecorDone => 'Fertig';

  @override
  String get ilduWorldDecorPlace => 'Platzieren';

  @override
  String ilduWorldDecorRequires(Object level) {
    return 'Ab $level';
  }

  @override
  String get ilduWorldSaveError =>
      'Die Hofgestaltung konnte nicht lokal gespeichert werden.';

  @override
  String get hanokWorldEarlyEyebrow => 'Dein Hof · A1';

  @override
  String get hanokWorldEarlyTitle =>
      'Deine erste Szene ist der Anfang deines Hanok.';

  @override
  String get hanokWorldEarlyBody =>
      'Jeder Satz aus deinem Alltag, den du sicher kannst, stärkt dein Fundament.';

  @override
  String hanokWorldEarlyVerifiedBody(Object canDo) {
    return 'Dein Fundament steht: $canDo';
  }

  @override
  String get hanokWorldMapEyebrow => 'Dein begehbarer Hof';

  @override
  String get hanokWorldMapTitle => 'Wohin möchtest du gehen?';

  @override
  String get hanokWorldMapBody =>
      'Jedes Gebäude führt zu einem Teil von Hangul Sori.';

  @override
  String get hanokWorldOpenNextScene => 'Nächste Szene ansehen';

  @override
  String get hanokWorldNextBeamTitle => 'Nächster Bauabschnitt';

  @override
  String get hanokWorldExploreHouse => 'Mein Haus erkunden';

  @override
  String hanokWorldSafeSceneProgress(int current, int total) {
    return '$current von $total Szenarien sicher gemeistert';
  }

  @override
  String get hanokWorldIntro =>
      'Setz dein Lernen dort fort, wo dein Hanok wächst. Jedes gebaute Gebäude führt dich zu einem Bereich von Hangul Sori.';

  @override
  String get hanokWorldLegacyTitle => 'Dein Hof wächst';

  @override
  String get hanokWorldLegacyBody =>
      'Schließe A1 und A2 ab. Mit deinem ersten Fortschritt in B1 öffnet sich die große Hanok-Karte.';

  @override
  String get hanokWorldMapHint =>
      'Tippe auf ein gebautes Gebäude, um dort weiterzulernen.';

  @override
  String get hanokWorldOpenSarangbang => 'Im Sarangbang lernen';

  @override
  String get hanokWorldProgress => 'Baufortschritt deiner Hanok';

  @override
  String get hanokWorldGyeBridgeTitle => 'Der Gye-Hof';

  @override
  String get hanokWorldGyeBridgeBody =>
      'Der Gye-Hof ist von deiner privaten Hanok getrennt. Dort triffst du deine Lerngruppe.';

  @override
  String get hanokWorldGyeBridgeOpen => 'Gye-Hof besuchen';

  @override
  String get hanokWorldPlacesTitle => 'Orte als Liste anzeigen';

  @override
  String get hanokWorldPlacesBody => 'Wähle einen verfügbaren Ort aus.';

  @override
  String get hanokMapPlaceSarangbang => '사랑방\nHeute lernen';

  @override
  String get hanokMapPlaceDaecheong => '대청마루\nDein Weg';

  @override
  String get hanokMapPlaceHaengrang => '행랑채\nÜben';

  @override
  String get hanokMapPlaceAnchae => '안채\nWörter';

  @override
  String get hanokMapPlaceHuwon => '후원\nAufgaben';

  @override
  String get hanokMapPlaceSadang => '사당\nErfolge';

  @override
  String get hanokZoneSarangbang => '사랑방 · Deine heutige Szene';

  @override
  String get hanokZoneDaecheong => '대청마루 · Dein Weg';

  @override
  String get hanokZoneHaengrang => '행랑채 · Üben';

  @override
  String get hanokZoneAnchae => '안채 · Meine Wörter';

  @override
  String get hanokZoneHuwon => '후원 · Aufgaben';

  @override
  String get hanokZoneSadang => '사당 · Erfolge';

  @override
  String get hanokWorldPurposeSarangbang =>
      'Kehre zu deiner heutigen Szene und den erarbeiteten Ausdrücken zurück.';

  @override
  String get hanokWorldPurposeDaecheong =>
      'Sieh deinen Lernpfad und wähle die nächste freigeschaltete Mission.';

  @override
  String get hanokWorldPurposeHaengrang =>
      'Wähle eine gezielte Übung oder ein kurzes Spiel.';

  @override
  String get hanokWorldPurposeAnchae =>
      'Öffne gespeicherte Wörter, Bücher und deine persönliche Lernsammlung.';

  @override
  String get hanokWorldPurposeHuwon =>
      'Wähle das Zeichen des Tages oder eine Quest.';

  @override
  String get hanokWorldPurposeSadang =>
      'Sieh dir die Meilensteine deines Lernwegs an.';

  @override
  String get hanokWorldPurposeGyeRoad =>
      'Der gemeinsame Gye-Hof bleibt von deiner privaten Hanok getrennt.';

  @override
  String get hanokWorldSelectPlaceTitle => 'Verfügbaren Ort wählen';

  @override
  String get hanokWorldSelectPlaceBody =>
      'Tippe auf ein Gebäude auf der Karte oder wähle es aus der Liste.';

  @override
  String hanokWorldPlaceReadyBody(String place) {
    return '$place ist jetzt verfügbar.';
  }

  @override
  String hanokWorldOpenPlace(String place) {
    return 'Nach $place gehen';
  }

  @override
  String get hanokWorldTodayMarker => 'Heutiges Lernen';

  @override
  String hanokWorldTodaySceneDetail(int minutes, String expression) {
    return '$minutes Minuten · „$expression“ sagen';
  }

  @override
  String get hanokWorldGoThere => 'Dorthin gehen';

  @override
  String hanokWorldRevealTitle(String place) {
    return '$place ist fertig gebaut';
  }

  @override
  String get hanokWorldRevealBody =>
      'Dein Hanok ist um einen Bereich gewachsen.';

  @override
  String get hanokWorldRevealContinue => 'Weiter zur Karte';

  @override
  String get hanokVenueFurnishRoom => 'Diesen Raum einrichten';

  @override
  String get hanokVenueAnbangBody =>
      'Hier findest du gespeicherte Wörter, Bücher und eigene Lernsammlungen.';

  @override
  String get hanokVenueDaecheongBody =>
      'Setz deinen Lernweg fort oder richte den Raum ein.';

  @override
  String get hanokVenueHaengrangBody =>
      'Im Eingangsflügel kannst du eine weitere Übungsrunde starten.';

  @override
  String get hanokVenueHuwonBody =>
      'Im hinteren Garten findest du das Zeichen des Tages und neue Quests.';

  @override
  String get hanokVenueSadangBody =>
      'Im Ahnenschrein siehst du die Meilensteine deines Lernwegs.';

  @override
  String get sarangbangStudyTitle => 'Sarangbang';

  @override
  String get sarangbangStudyIntroTitle => 'Was du heute gelernt hast';

  @override
  String get sarangbangStudyIntroBody =>
      'Hier findest du deine heutigen Lernfortschritte.';

  @override
  String get sarangbangStudySceneLabel => 'Dein Lernzimmer';

  @override
  String get sarangbangStudyFurnish => 'Studierstube einrichten';

  @override
  String get sarangbangFurnishTitle => 'Einrichten';

  @override
  String get sarangbangFurnishBody =>
      'Du erhältst neue Gegenstände als klar gekennzeichnete Belohnungen.';

  @override
  String get sarangbangStoredTitle => 'Heute gesammelt';

  @override
  String get sarangbangStoredEmpty =>
      'Neue Ausdrücke und gemeisterte Szenen erscheinen hier, sobald du sie freigeschaltet hast.';

  @override
  String sarangbangStoredBody(Object detail) {
    return '$detail · Deine aktuelle Szene bleibt auf der Startseite ausgewählt.';
  }

  @override
  String sarangbangStoredRecord(int expressions, int scenes, int beams) {
    String _temp0 = intl.Intl.pluralLogic(
      expressions,
      locale: localeName,
      other: '$expressions Ausdrücke',
      one: '1 Ausdruck',
      zero: 'Keine Ausdrücke',
    );
    String _temp1 = intl.Intl.pluralLogic(
      scenes,
      locale: localeName,
      other: '$scenes gemeisterte Szenen',
      one: '1 gemeisterte Szene',
      zero: 'keine gemeisterte Szene',
    );
    String _temp2 = intl.Intl.pluralLogic(
      beams,
      locale: localeName,
      other: '$beams Balken im Bauplan',
      one: '1 Balken im Bauplan',
      zero: 'kein Balken im Bauplan',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get sarangbangOpenToday => 'Zur heutigen Szene';

  @override
  String get sarangbangReturnCourtyard => 'Zum Hof';

  @override
  String get personalRoomAnbangTitle => 'Anbang';

  @override
  String get personalRoomDaecheongTitle => 'Daecheongmaru';

  @override
  String get personalRoomAnbangBody =>
      'Ein ruhiger Innenraum für die Wörter und Momente, die du bewahrst.';

  @override
  String get personalRoomDaecheongBody =>
      'Eine offene Halle, in der dein Lernweg weitergeht.';

  @override
  String get personalRoomEmptyHint =>
      'Öffne ein Bojagi-Bündel, um dein erstes Einrichtungsstück zu erhalten.';

  @override
  String get personalRoomLockedTitle => 'Dieser Raum wird noch gebaut';

  @override
  String get personalRoomLockedBody =>
      'Lerne auf deinem Lernweg weiter, um diesen Teil deiner Hanok zu öffnen.';

  @override
  String get personalRoomReturnToMap => 'Zurück zur Hanok-Karte';

  @override
  String get personalRoomAnbangStudy => 'Meine Sammlung entdecken';

  @override
  String get personalRoomDaecheongStudy => 'Lernweg fortsetzen';

  @override
  String get personalRoomEditorHint =>
      'Ziehe ein Stück frei durch den Raum. Mit zwei Fingern kannst du es drehen und vergrößern. Die Werkzeugleiste funktioniert auch ohne Gesten.';

  @override
  String get personalRoomInventoryTitle => 'Meine Gestaltungskiste';

  @override
  String get personalRoomInventoryDecorations => 'Einrichtung';

  @override
  String get personalRoomInventoryStickers => 'Sticker';

  @override
  String get personalRoomInventoryStamps => 'Stempel';

  @override
  String get personalRoomNoDecorations =>
      'Noch keine Einrichtung. Öffne ein Bojagi-Bündel, um ein Stück zu erhalten.';

  @override
  String get personalRoomNoStamps =>
      'Noch keine Dancheong-Stempel. Schließe ein Wortpaket ab, um einen zu erhalten.';

  @override
  String personalRoomSelectedItem(String item) {
    return 'Ausgewählt: $item';
  }

  @override
  String get personalRoomMoveLeft => 'Nach links';

  @override
  String get personalRoomMoveRight => 'Nach rechts';

  @override
  String get personalRoomMoveUp => 'Nach oben';

  @override
  String get personalRoomMoveDown => 'Nach unten';

  @override
  String get personalRoomMakeSmaller => 'Verkleinern';

  @override
  String get personalRoomMakeLarger => 'Vergrößern';

  @override
  String get personalRoomRotateLeft => 'Nach links drehen';

  @override
  String get personalRoomRotateRight => 'Nach rechts drehen';

  @override
  String get personalRoomSendBackward => 'Eine Ebene nach hinten';

  @override
  String get personalRoomBringForward => 'Eine Ebene nach vorn';

  @override
  String get personalRoomRemoveItem => 'In die Kiste zurücklegen';

  @override
  String personalRoomAddItem(String item) {
    return '$item in den Raum stellen';
  }

  @override
  String get personalRoomItemInUse => 'Bereits in einem Zimmer';

  @override
  String get personalRoomStickerLimit =>
      'Hier kann kein weiteres Exemplar platziert werden. Lege zuerst etwas zurück.';

  @override
  String get personalRoomSaveFailed =>
      'Die Anordnung konnte nicht gespeichert werden. Versuch es noch einmal.';

  @override
  String get personalRoomFutureLayout =>
      'Diese Anordnung stammt aus einer neueren App-Version und bleibt schreibgeschützt.';

  @override
  String get personalRoomSelectItemHint => 'Zum Anordnen auswählen';

  @override
  String get personalRoomStickerFallback => 'Sticker';

  @override
  String get personalRoomStampFallback => 'Dancheong-Stempel';

  @override
  String get decorNameMunbangsau => 'Schreibzeug (문방사우)';

  @override
  String get decorNameSeoan => 'Schreibpult (서안)';

  @override
  String get decorNameChaekgado => 'Bücherwand-Wandschirm (책가도)';

  @override
  String get decorNameGatBuchae => 'Hut und Fächer (갓·부채)';

  @override
  String get decorNameJagaeMungap => 'Perlmutt-Truhe (자개 문갑)';

  @override
  String get decorNameSoban => 'Tabletttisch (소반)';

  @override
  String get decorNameSagunjaMaehwa => 'Pflaumenblüten-Bild (매화)';

  @override
  String get decorNameSagunjaNan => 'Orchideen-Bild (난초)';

  @override
  String get decorNameSagunjaGuk => 'Chrysanthemen-Bild (국화)';

  @override
  String get decorNameSagunjaJuk => 'Bambus-Bild (대나무)';

  @override
  String get decorNamePyeonaek => 'Namenstafel (편액)';

  @override
  String get decorNameJangdokdae => 'Jangdokdae (Krugterrasse)';

  @override
  String get decorNameMaehwa => 'Pflaumenbaum (매화)';

  @override
  String get decorNameSonamu => 'Alte Kiefer (노송)';

  @override
  String get decorNamePond => 'Teich & Karpfen (연못)';

  @override
  String get decorNameSeokdeung => 'Steinlaterne (장명등)';

  @override
  String get decorNamePunggyeong => 'Windspiel (풍경)';

  @override
  String get decorNameDoldam => 'Steinmauer (돌담)';

  @override
  String get decorNameKkachiNest => 'Elsternnest (까치 둥지)';

  @override
  String get decorNameDokkaebiFire => 'Irrlicht (도깨비불)';

  @override
  String get decorNameSeollalFlag => 'Seollal-Yutspiel (윷놀이)';

  @override
  String get decorNameChuseokMoon => 'Chuseok-Vollmond (보름달)';

  @override
  String get decorNameHangeuldayPlaque => 'Hangul-Tag Sejong-Tafel (세종 편액)';

  @override
  String get decorNameKite => 'Kinder-Tag Drachen (연)';

  @override
  String get decorNameSabangtakja => 'Regal (사방탁자)';

  @override
  String get decorNameBoryoSet => 'Sitzpolster-Set (보료)';

  @override
  String get decorNameBangseokPair => 'Sitzkissen (방석)';

  @override
  String get decorNameBandaji => 'Klapptruhe (반닫이)';

  @override
  String get decorNameHwaro => 'Kohlebecken (화로)';

  @override
  String get decorNameDeungjan => 'Öllampe (등잔대)';

  @override
  String get decorNameGeomungo => 'Geomungo-Zither (거문고)';

  @override
  String get decorNameBaduk => 'Baduk-Brett (바둑판)';

  @override
  String get decorNameMokchim => 'Holzkissen (목침)';

  @override
  String get decorNameByeongpungSmall => 'Kleiner Wandschirm (소병풍)';

  @override
  String get decorNameGobi => 'Briefhalter (고비)';

  @override
  String get decorNameHyangno => 'Räuchergefäß (향로)';

  @override
  String get decorNameFallback => 'Dekoration';

  @override
  String get stickerNameTigerCheer => 'Jubelnder Tiger';

  @override
  String get stickerNameTigerClap => 'Klatschender Tiger';

  @override
  String get stickerNameTigerSurprised => 'Überraschter Tiger';

  @override
  String get stickerNameTigerSad => 'Trauriger Tiger';

  @override
  String get stickerNameTigerLove => 'Verliebter Tiger';

  @override
  String get stickerNameMagpieDance => 'Tanzende Elster';

  @override
  String get stickerNameMagpieWave => 'Winkende Elster';

  @override
  String get stickerNameMagpieSleep => 'Schlafende Elster';

  @override
  String get stickerNameMagpieSing => 'Singende Elster';

  @override
  String get stickerNameMagpieEncourage => 'Aufmunternde Elster';

  @override
  String get stickerNameDancheongFlower => 'Dancheong-Blüte';

  @override
  String get stickerNameDancheongStar => 'Dancheong-Stern';

  @override
  String get stickerNameDancheongCloud => 'Dancheong-Wolke';

  @override
  String get stickerNameDancheongLantern => 'Dancheong-Laterne';

  @override
  String get stickerNameDancheongHanji => 'Hanji-Papier';

  @override
  String get stickerNameHangulKk => 'ㅋㅋ · Lautes Lachen';

  @override
  String get stickerNameHangulHh => 'ㅎㅎ · Leises Kichern';

  @override
  String get stickerNameHangulFighting => '화이팅! · Du schaffst das';

  @override
  String get stickerNameHangulBest => '최고! · Einfach spitze';

  @override
  String get stickerNameHangulGood => '굿 · Gut gemacht';

  @override
  String get stickerNameFoodTteok => 'Tteok-Reiskuchen';

  @override
  String get stickerNameFoodTea => 'Koreanischer Tee';

  @override
  String get stickerNameFoodKimbap => 'Gimbap';

  @override
  String get stickerNameFoodHotteok => 'Hotteok';

  @override
  String get stickerNameFoodSikhye => 'Sikhye-Reisgetränk';

  @override
  String get stickerNameStampWellDone => 'Stempel · Sehr gut gemacht';

  @override
  String get stickerNameStampFighting => 'Stempel · Du schaffst das';

  @override
  String get stickerNameStampLove => 'Stempel · Mit Liebe';

  @override
  String get stickerNameStampCheer => 'Stempel · Applaus';

  @override
  String get stickerNameStampHappy => 'Stempel · Glücklich';

  @override
  String get stampMotifLotus => 'Lotus-Dancheong';

  @override
  String get stampMotifChrysanthemum => 'Chrysanthemen-Dancheong';

  @override
  String get stampMotifPlum => 'Pflaumenblüten-Dancheong';

  @override
  String get stampMotifBamboo => 'Bambus-Dancheong';

  @override
  String get stampMotifCloud => 'Wolken-Dancheong';

  @override
  String get stampMotifOctagon => 'Achteck-Dancheong';

  @override
  String get stampMotifMountain => 'Berg-Dancheong';

  @override
  String get stampMotifManja => 'Manja-Dancheong';

  @override
  String get stampMotifVine => 'Ranken-Dancheong';

  @override
  String get stampMotifChilbo => 'Chilbo-Dancheong';

  @override
  String get stampMotifGwigap => 'Gwigap-Dancheong';

  @override
  String get stampMotifWave => 'Wellen-Dancheong';

  @override
  String get stampMotifTaegeuk => 'Taegeuk-Dancheong';

  @override
  String get stampMotifPeony => 'Pfingstrosen-Dancheong';

  @override
  String get stampMotifChangsal => 'Fenstergitter-Dancheong';

  @override
  String get stampMotifSuryeon => 'Seerosen-Dancheong';

  @override
  String get stampMotifNoemun => 'Noemun-Dancheong';

  @override
  String get stampMotifMugunghwa => 'Mugunghwa-Dancheong';

  @override
  String get stampMotifMoran => 'Moran-Dancheong';

  @override
  String get stampMotifMunbangsau => 'Vier Schätze des Studierzimmers';

  @override
  String get stampMotifBok => 'Glückszeichen Bok (福)';

  @override
  String get stampMotifCrane => 'Fliegender Kranich';

  @override
  String get stampMotifWadang => 'Lächelnder Dachziegel';

  @override
  String get stampMotifYeopjeon => 'Drei Yeopjeon-Münzen';

  @override
  String get stampMotifSoban => 'Soban-Tisch';

  @override
  String get gyeDedicationTitle => 'Gemeinsame Ausstellung';

  @override
  String get gyeDedicationAction => 'Ausstellen';

  @override
  String get gyeDedicationPickerBody =>
      'Wähle eine Zimmerdekoration für den gemeinsamen Hof. Sie bleibt in deiner privaten Sammlung.';

  @override
  String get gyeDedicationEmpty =>
      'Öffne zuerst ein Bojagi-Bündel, um eine Zimmerdekoration zu erhalten.';

  @override
  String get gyeDedicationWithdraw => 'Aus der Ausstellung nehmen';

  @override
  String get gyeDedicationKeepOwned =>
      'Deine Dekoration bleibt in deinem privaten Raum.';

  @override
  String get gyeDedicationConfirmTitle => 'Diese Dekoration im Hof zeigen?';

  @override
  String gyeDedicationConfirmBody(String decoration) {
    return 'Alle in diesem Gye können $decoration im gemeinsamen Hof sehen. Deine private Sammlung und dein Raum bleiben unverändert.';
  }

  @override
  String get gyeDedicationWithdrawConfirmBody =>
      'Dieses Ausstellungsstück aus dem gemeinsamen Hof nehmen? Deine private Dekoration bleibt dir erhalten.';

  @override
  String get gyeDedicationConfirm => 'Im Hof zeigen';

  @override
  String get gyeDedicationUpdateFailed =>
      'Die Ausstellung konnte nicht aktualisiert werden. Versuche es gleich noch einmal.';

  @override
  String get gyeDedicationConflict =>
      'Die Ausstellung wurde an anderer Stelle geändert. Hier ist der aktuelle Stand.';

  @override
  String get gyeDedicationRetry => 'Erneut versuchen';

  @override
  String get accountLinkUnavailableTitle => 'Verbindung derzeit nicht möglich';

  @override
  String get accountLinkUnavailableBody =>
      'Die Cloud-Dienste sind auf diesem Gerät nicht verfügbar, deshalb konnte die Anmeldung nicht gestartet werden. Dein Lernfortschritt bleibt lokal gespeichert. Prüfe deine Internetverbindung und starte die App neu.';

  @override
  String get accountLinkOfflineTitle => 'Keine Internetverbindung';

  @override
  String get accountLinkOfflineBody =>
      'Für das Verbinden eines Kontos wird Internet benötigt. Dein Fortschritt bleibt auf diesem Gerät gespeichert.';

  @override
  String get accountLinkFailedTitle => 'Verbinden fehlgeschlagen';

  @override
  String get accountLinkFailedBody =>
      'Der Vorgang konnte nicht abgeschlossen werden. Bitte versuche es in einem Moment erneut.';

  @override
  String get soriStageNavToday => 'Heute';

  @override
  String get soriStageNavLearn => 'Lernen';

  @override
  String get soriStageNavGames => 'Spiele';

  @override
  String get soriStageNavHanok => 'Hanok';

  @override
  String get soriStageNavGye => 'Gye';

  @override
  String get soriStageProfileTooltip => 'Profil';

  @override
  String get soriStageTodayEyebrow => 'HEUTE';

  @override
  String get soriStageTodayTitle => 'Ein Satz. Ein Bauteil.';

  @override
  String get soriStageTodayEmpty =>
      'Wähle eine kurze Aktivität und baue an deiner Hanok weiter.';

  @override
  String get soriStageMissionAction => 'Heutige Mission starten';

  @override
  String get soriStageTodayMissionEyebrow => 'HEUTIGE MISSION';

  @override
  String get soriStageMissionStart => 'Starten';

  @override
  String get hanokStageNameEmpty => 'Bauplatz';

  @override
  String get hanokStageNameFoundation => 'Fundament';

  @override
  String get hanokStageNamePillars => 'Säulen';

  @override
  String get hanokStageNameBeams => 'Balken';

  @override
  String get hanokStageNameThatchRoof => 'Strohdach';

  @override
  String get hanokStageNameTileRoofPartial => 'Erste Ziegel';

  @override
  String get hanokStageNameTileRoofComplete => 'Ziegeldach';

  @override
  String get hanokStageNameDancheong => 'Dancheong';

  @override
  String get hanokStageNameGate => 'Tor';

  @override
  String get hanokStageNameWindows => 'Fenster';

  @override
  String get hanokStageNameSideBuilding => 'Sarangchae';

  @override
  String get hanokStageNameJongga => 'Jongga-Haus';

  @override
  String get soriStageBojagiTitle => 'Ein Bojagi wartet';

  @override
  String get soriStageBojagiBody =>
      'Wähle eines von drei Stücken für dein Zimmer.';

  @override
  String get soriStageOpenBojagi => 'Bojagi öffnen';

  @override
  String get soriStageHanokNow => 'Deine Hanok jetzt';

  @override
  String get soriStageNextPiece => 'Nächstes Bauteil';

  @override
  String get soriStageClosestQuests => 'Fast geschafft';

  @override
  String get soriStageLearnTitle => 'Wähle, wie du lernen möchtest.';

  @override
  String get soriStageLearnBody =>
      'Jede Aktivität bleibt mit deinen Quests und deiner Hanok verbunden.';

  @override
  String get soriStageGamesTitle => 'Spiele mit einem klaren Ziel.';

  @override
  String get soriStageGamesBody =>
      'Sieh XP, Bestleistung und passende Quest, bevor du startest.';

  @override
  String soriStageMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get soriStagePossibleReward => 'Mögliche Belohnung';

  @override
  String soriStageOpenActivity(String activity) {
    return '$activity öffnen';
  }

  @override
  String soriStageActivityDetails(String activity) {
    return 'Details zu $activity';
  }

  @override
  String get soriStageHanokTitle => 'Baue ein Zuhause aus dem, was du kannst.';

  @override
  String get soriStageHanokBody =>
      'Sieben dauerhafte Stufen zeigen genau, was gebaut ist und was als Nächstes öffnet.';

  @override
  String get soriStageOpenMap => 'Hanok-Karte öffnen';

  @override
  String get soriStageQuests => 'Quests';

  @override
  String get soriStageDojang => 'Dojang-Heft';

  @override
  String get soriStageBojagi => 'Bojagi';

  @override
  String get soriStageRooms => 'Räume und Einrichtung';

  @override
  String get soriStageGyePromise => 'Versprechen dieser Woche';

  @override
  String get soriStageGyeFlow =>
      'Mission abschließen → Laterne → gemeinsame Hanok';

  @override
  String get pronunciationTitle => 'Aussprache-Studio';

  @override
  String get pronunciationEyebrow => 'MIT DEM TIGER SPRECHEN';

  @override
  String get pronunciationIntro =>
      'Höre zuerst zu. Nimm danach freiwillig bis zu 10 Sekunden für eine Bewertung auf.';

  @override
  String get pronunciationPhrasesLoading =>
      'Ausspracheübungen werden geladen …';

  @override
  String get pronunciationPhrasesUnavailableTitle =>
      'Ausspracheübungen nicht verfügbar';

  @override
  String get pronunciationPhrasesUnavailableBody =>
      'Die Ausspracheübungen konnten nicht geladen werden. Bitte versuche es noch einmal.';

  @override
  String get pronunciationPhrasesEmptyTitle => 'Noch keine Ausspracheübungen';

  @override
  String get pronunciationPhrasesEmptyBody =>
      'Für deinen Lernstand sind gerade keine geprüften Sätze verfügbar.';

  @override
  String get pronunciationListen => 'Anhören';

  @override
  String get pronunciationRecord => 'Meine Stimme aufnehmen';

  @override
  String get pronunciationRecording => 'Aufnahme läuft…';

  @override
  String get pronunciationAssessing => 'Bewertung wird erstellt…';

  @override
  String get pronunciationStop => 'Stoppen und bewerten';

  @override
  String get pronunciationContinueWithoutScore => 'Ohne Bewertung weiter';

  @override
  String get pronunciationNextPhrase => 'Nächster Satz';

  @override
  String get pronunciationConsentTitle => 'Deine Stimme bewerten lassen?';

  @override
  String get pronunciationConsentBody =>
      'Mit deiner gesonderten Einwilligung werden eine Aufnahme von höchstens 10 Sekunden und der angezeigte koreanische Satz sicher an Microsoft Azure Speech in der Region Deutschland West-Mitte gesendet. Hangul Sori speichert weder Aufnahme noch Satz auf seinem Server. Nur die Bewertungen und eine ID gegen Doppelzählung werden auf diesem Gerät gespeichert. Du kannst ohne Bewertung üben und die Einwilligung in den Einstellungen widerrufen.';

  @override
  String get pronunciationConsentAccept =>
      'Ich stimme zu und möchte eine Bewertung';

  @override
  String get pronunciationConsentDecline => 'Ohne Bewertung üben';

  @override
  String get pronunciationPermissionDenied =>
      'Der Mikrofonzugriff wurde nicht erlaubt. Anhören und Nachsprechen bleiben verfügbar.';

  @override
  String get pronunciationAssessmentUnavailable =>
      'Die Bewertung ist gerade nicht verfügbar. Deine normale Übung bleibt möglich.';

  @override
  String get pronunciationRateLimited =>
      'Du hast das Bewertungslimit erreicht. Übe weiter und versuche es später erneut.';

  @override
  String get pronunciationScore => 'Aussprachebewertung';

  @override
  String get pronunciationScorePassed =>
      'Bestanden. Diese Bewertung zählt einmal für deine Aussprache-Quest.';

  @override
  String get pronunciationScoreTryAgain =>
      'Gute Übung. Erreiche beim nächsten Mal mindestens 80, um die Quest fortzusetzen.';

  @override
  String get pronunciationAccuracy => 'Genauigkeit';

  @override
  String get pronunciationFluency => 'Sprechfluss';

  @override
  String get pronunciationCompleteness => 'Vollständigkeit';

  @override
  String get settingsPronunciationConsentTitle =>
      'Einwilligung zur Sprachbewertung';

  @override
  String get settingsPronunciationConsentDesc =>
      'Erlaube freiwillige Aufnahmen von höchstens 10 Sekunden zur Bewertung durch Azure Speech in Deutschland West-Mitte. Ausschalten verhindert weitere Bewertungen.';

  @override
  String get settingsPronunciationConsentOff =>
      'Sprachbewertung ist aus. Anhören und Nachsprechen bleiben verfügbar.';

  @override
  String get soriStageReceiptEyebrow => 'GERADE VERÄNDERT';

  @override
  String get soriStageReceiptTitle => 'Dein Lernen hat den Weg weitergebracht.';

  @override
  String get soriStageReceiptSemantics => 'Erhaltene Belohnungen';

  @override
  String get soriStageReceiptContinue => 'Weiter';

  @override
  String get soriStageActivityReady => 'Jetzt verfügbar';

  @override
  String get soriStageBrandLabel => 'SORI STAGE';

  @override
  String get soriStageActivityInProgress => 'In Arbeit';

  @override
  String get soriStageActivityCompleted => 'Abgeschlossen';

  @override
  String soriStageActivityTitle(String activityId) {
    String _temp0 = intl.Intl.selectLogic(activityId, {
      'course': 'Kurs',
      'hangul': 'Hangul',
      'calligraphy': 'Buchstabe des Tages',
      'pronunciation': 'Aussprache',
      'vocab_packs': 'Wortpakete',
      'srs': 'Wiederholen',
      'hard_words': 'Schwierige Wörter',
      'word_web': 'Nuancen & Gegenteile',
      'grammar': 'Grammatik',
      'listening': 'Hören',
      'scenarios': 'Alltagsszenen',
      'smalltalk': 'Small Talk',
      'book_capture': 'Buch fotografieren',
      'vocab_notebook': 'Vokabelheft',
      'bookshelf': 'Bücherregal',
      'word_search': 'Wortsuche',
      'daily_game': 'Tageschallenge',
      'chosung': 'Anlaut-Quiz',
      'syllable_cross': 'Silben-Rätsel',
      'cloze': 'Lückentext',
      'speed_match': 'Blitz-Paare',
      'sentence_arcade': 'Satz-Arcade',
      'kkeunmari': 'Kkeunmari',
      'custom_quiz': 'Eigenes Quiz',
      'custom_matching': 'Eigenes Matching',
      'custom_typing': 'Eigenes Tippen',
      'other': 'Lernaktivität',
    });
    return '$_temp0';
  }

  @override
  String soriStageActivityDescription(String activityId) {
    String _temp0 = intl.Intl.selectLogic(activityId, {
      'course': 'Dein geführter Weg durch echte Situationen.',
      'hangul': 'Silben bauen und sicher lesen.',
      'calligraphy': 'Jeden Tag ein Schriftzeichen entdecken.',
      'pronunciation': 'Hören, nachsprechen und auf Wunsch bewerten.',
      'vocab_packs': 'Wörter nach Alltagsthema lernen.',
      'srs': 'Wörter genau im richtigen Moment auffrischen.',
      'hard_words': 'Gezielt an deinen Stolperwörtern arbeiten.',
      'word_web': 'Synonyme, Gegenteile und Wendungen zu deinen Wörtern.',
      'grammar': 'Muster verstehen und direkt anwenden.',
      'listening': 'Kurze natürliche Sätze sicher erkennen.',
      'scenarios': 'Café, Verkehr und Gespräche üben.',
      'smalltalk': 'Kurze Gespräche flüssig verbinden.',
      'book_capture': 'Wörter aus deinem Material übernehmen.',
      'vocab_notebook': 'Dein Heft fotografieren und genau diese Wörter üben.',
      'bookshelf': 'Eigene Seiten und Wortlisten verwalten.',
      'word_search': 'Ein Wort und seine Lernwege finden.',
      'daily_game': 'Ein kurzer Mix für heute.',
      'chosung': 'Wörter an ihren Anfangslauten erkennen.',
      'syllable_cross': 'Silben kombinieren und Wörter finden.',
      'cloze': 'Das passende Wort im Satz abrufen.',
      'speed_match': 'Bedeutungen schnell und sicher verbinden.',
      'sentence_arcade': 'Sätze unter Zeitdruck richtig bauen.',
      'kkeunmari': 'Eine Wortkette gegen den Tiger spielen.',
      'custom_quiz': 'Ein Wortpaket im Bücherregal auswählen.',
      'custom_matching': 'Deine Wörter als Paare festigen.',
      'custom_typing': 'Deine Wörter aktiv aus dem Gedächtnis holen.',
      'other': 'Weiterlernen.',
    });
    return '$_temp0';
  }

  @override
  String soriStageCatalogCopy(String copyKey) {
    String _temp0 = intl.Intl.selectLogic(copyKey, {
      'firstCompletion': 'Beim ersten Abschluss',
      'finishSession': 'Wenn du die Runde abschließt',
      'verifiedLearning': 'Nach einem bestätigten Lernerfolg',
      'rewardXp': 'Lern-XP',
      'rewardQuest': 'Passende Quest',
      'rewardHanok': 'Verifizierter Hanok-Baufortschritt',
      'rewardStamp': 'Dojang-Stempel',
      'rewardBest': 'Persönliche Bestleistung',
      'rewardNone': 'Keine direkte Belohnung',
      'rewardQuestProgress': 'Quest-Fortschritt',
      'rewardHanokPiece': 'Neues Hanok-Bauteil',
      'rewardBojagi': 'Bojagi',
      'rewardGyeLantern': 'Gye-Laterne',
      'other': 'Belohnung',
    });
    return '$_temp0';
  }

  @override
  String questActionLabel(String actionKey) {
    String _temp0 = intl.Intl.selectLogic(actionKey, {
      'openQuests': 'Quests öffnen',
      'openVocabulary': 'Wortpakete öffnen',
      'openScenarios': 'Alltagsszenen öffnen',
      'practicePronunciation': 'Aussprache üben',
      'playKkeunmari': 'Kkeunmari spielen',
      'openHangul': 'Hangul öffnen',
      'openCalligraphy': 'Buchstabe des Tages öffnen',
      'openToday': 'Heutige Mission öffnen',
      'openGye': 'Gye öffnen',
      'playChosung': 'Anlaut-Quiz spielen',
      'other': 'Öffnen',
    });
    return '$_temp0';
  }

  @override
  String questSeasonOpens(String date) {
    return 'Öffnet am $date';
  }

  @override
  String soriStagePreviewCopy(String copyKey) {
    String _temp0 = intl.Intl.selectLogic(copyKey, {
      'todayEyebrow': 'HEUTE',
      'todayTitle': 'Ein Satz. Ein Bauteil.',
      'nearComplete': 'Fast geschafft',
      'cafeOrder': 'Im Café bestellen',
      'strongWords': 'Starke Alltagswörter',
      'sevenDayStreak': 'Sieben Tage dranbleiben',
      'lessonEyebrow': 'LEKTION 2 VON 4',
      'lessonPhrase': '덜 맵게 해 주세요',
      'listen': 'Hören',
      'naturalTempo': 'Natürliches Tempo',
      'speak': 'Sprechen',
      'rhythmMouth': 'Rhythmus und Mundbild',
      'remember': 'Erinnern',
      'withoutHelp': 'Ohne Hilfe abrufen',
      'beginListening': 'Mit Hören beginnen',
      'receiptEyebrow': 'GERADE VERÄNDERT',
      'receiptTitle': 'Dein Satz trägt jetzt das Dach.',
      'beamStage': 'DAECHEONG · BALKEN 3',
      'newBeam': '1 neuer Balken im Bauplan',
      'xpEarned': 'Lern-XP +12',
      'completedMission': 'für die abgeschlossene Mission',
      'questEarned': 'Quest-Fortschritt +1',
      'scenarioProgress': 'Alltagsszenen · 4 von 10',
      'hanokEarned': 'Hanok-Bauteil +1',
      'verifiedSpeaking': 'durch bestätigtes Sprechen',
      'continueToday': 'Weiter zu Heute',
      'journeyEyebrow': 'DEIN WEG',
      'journeyTitle': 'Alles Lernen baut am selben Ort.',
      'missionEyebrow': 'WENIGER SCHARF BESTELLEN',
      'missionTitle': 'Hören. Sprechen. Im Alltag anwenden.',
      'missionReward': 'Abschließen → Lern-XP + verifizierter Fortschritt',
      'missionStart': 'Mission starten',
      'bojagiWaiting': '1 Bojagi wartet',
      'bojagiBody': 'Wähle eines von drei Stücken für dein Zimmer.',
      'other': 'Sori-Stage-Vorschau',
    });
    return '$_temp0';
  }

  @override
  String soriStagePreviewProgress(int current, int target) {
    return '$current von $target';
  }

  @override
  String get soriStageActivityStart => 'Starten';

  @override
  String get soriStageActivityLocked => 'Gesperrt';

  @override
  String culturalHelpSemantics(String term) {
    return 'Mehr über $term erfahren';
  }

  @override
  String get culturalMeaningLabel => 'Was ist das?';

  @override
  String get culturalStoryLabel => 'Warum war das wichtig?';

  @override
  String get culturalClose => 'Kulturgeschichte schließen';

  @override
  String get culturalObjectHint => 'Neugierig? Tippe auf einen Gegenstand.';

  @override
  String get culturalObjectHintDismiss => 'Hinweis schließen';

  @override
  String get vocabNotebookTitle => 'Vokabelheft';

  @override
  String get vocabNotebookDesc =>
      'Dein Heft fotografieren und genau diese Wörter üben.';

  @override
  String get vocabNotebookPreviewCta => 'Diese Wörter übernehmen';

  @override
  String vocabNotebookResultHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Wörter aus deinem Heft. Genau diese Wörter übst du danach.',
      one: '1 Wort aus deinem Heft. Genau diese Wörter übst du danach.',
    );
    return '$_temp0';
  }

  @override
  String get vocabNotebookDefaultName => 'Mein Vokabelheft';

  @override
  String get vocabNotebookEmptyTitle => 'Keine Wortpaare gefunden';

  @override
  String get vocabNotebookEmptyBody =>
      'Schreib Koreanisch und die Bedeutung in eine Zeile, zum Beispiel: 학교 - Schule. Dann übernimm genau diese Wörter.';

  @override
  String get vocabNotebookPracticeCta => 'Genau diese Wörter üben';

  @override
  String vocabNotebookPracticeHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Wörter aus deinem Heft. Spiele damit, statt neue Vokabeln zu bekommen.',
      one:
          '1 Wort aus deinem Heft. Spiele damit, statt neue Vokabeln zu bekommen.',
    );
    return '$_temp0';
  }

  @override
  String get vocabNotebookAddPhoto => 'Weitere Seite fotografieren';

  @override
  String get vocabNotebookDropWord => 'Wort weglassen';

  @override
  String get vocabNotebookKeepWord => 'Wort behalten';

  @override
  String get vocabNotebookNuanceCta => 'Hanja und Nuancen';

  @override
  String get vocabNotebookNuanceTitle => 'Ähnlich, aber nicht gleich';

  @override
  String get vocabNotebookNuanceEmptyTitle => 'Noch kein Vergleich';

  @override
  String get vocabNotebookNuanceEmptyBody =>
      'Fotografiere oder importiere Wörter, die nah beieinanderliegen. Hanja zeigt dann die andere Nuance oder die förmlichere Stufe.';

  @override
  String get vocabNotebookSaveFailed =>
      'Die Wörter konnten nicht gespeichert werden. Versuch es noch einmal.';

  @override
  String get vocabNotebookNoHanja => 'kein Hanja';

  @override
  String get vocabNotebookStudioCta => 'Spiel aus diesen Wörtern bauen';

  @override
  String get vocabNotebookStudioTitle => 'Mein Wortspiel';

  @override
  String get vocabNotebookStudioHint =>
      'Wähl die Wörter aus deinem Heft. Danach spielst du nur mit denen, und mit Sätzen, Dialogen und Nuancen-Übungen, die wir dafür schon haben.';

  @override
  String get vocabNotebookStudioSelectAll => 'Alle nehmen';

  @override
  String get vocabNotebookStudioSelectNone => 'Keine';

  @override
  String get vocabNotebookStudioOwnGames => 'Mit deinen Bedeutungen';

  @override
  String get vocabNotebookStudioCorpusGames => 'Mit unseren Sätzen';

  @override
  String get vocabNotebookStudioCorpusHint =>
      'Nur vorhandene Sätze, Dialoge und Nuancen-Übungen. Es kommen keine neuen Wörter dazu.';

  @override
  String get vocabNotebookStudioLoading => 'Vorhandene Spiele laden …';

  @override
  String vocabNotebookStudioCloze(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lückentext · $count Sätze',
      one: 'Lückentext · 1 Satz',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioSatz(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Satz bauen · $count Sätze',
      one: 'Satz bauen · 1 Satz',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioSpeed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Blitz-Paare · $count Wörter',
      one: 'Blitz-Paare · 1 Wort',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioChosung(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Anlaut-Quiz · $count Wörter',
      one: 'Anlaut-Quiz · 1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get vocabNotebookStudioNoCorpus =>
      'Für diese Wörter haben wir noch keinen fertigen Satz. Spiel oben mit deinen eigenen Bedeutungen.';

  @override
  String get vocabNotebookStudioLoadFailed =>
      'Einige unserer Sätze konnten nicht geladen werden. Verbindung prüfen und noch einmal versuchen.';

  @override
  String vocabNotebookStudioSmalltalk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Smalltalk · $count Sätze',
      one: 'Smalltalk · 1 Satz',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioPronunciation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aussprache · $count Sätze',
      one: 'Aussprache · 1 Satz',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioScenarios(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Szenario · $count Szenen',
      one: 'Szenario · 1 Szene',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioWordWeb(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nuancen & Gegenteile · $count Wörter',
      one: 'Nuancen & Gegenteile · 1 Wort',
    );
    return '$_temp0';
  }

  @override
  String get ttsUnavailableChannelOff =>
      'Aussprache ist stumm geschaltet. Einstellungen → Ton';

  @override
  String get ttsUnavailableQuota =>
      'Heutiges Sprachlimit erreicht. Morgen geht es weiter.';

  @override
  String get ttsUnavailablePending =>
      'Die Stimme wird gerade erzeugt. Gleich nochmal antippen.';

  @override
  String get ttsUnavailableOffline =>
      'Aussprache nicht verfügbar. Bist du online?';

  @override
  String get mediaPhraseTitle => 'Medien-Sätze';

  @override
  String get mediaPhraseDesc =>
      'Übe Originalzeilen aus Interview-, Podcast-, Doku- und Debattenregistern auf deinem Niveau.';

  @override
  String get mediaPhraseContext => 'Situation';

  @override
  String get mediaPhraseLoading => 'Medien-Sätze werden geladen …';

  @override
  String get mediaPhraseUnavailable =>
      'Die Medien-Sätze konnten nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get mediaPhraseEmptyTitle => 'Noch kein Satz für dieses Niveau';

  @override
  String get mediaPhraseEmpty =>
      'Für dein Niveau sind gerade keine Medien-Sätze verfügbar.';

  @override
  String mediaPhraseProgress(int current, int total) {
    return '$current von $total';
  }

  @override
  String mediaPhraseListenTarget(String phrase) {
    return '$phrase anhören';
  }

  @override
  String get mediaPhrasePrevious => 'Zurück';

  @override
  String get mediaPhraseNext => 'Weiter';

  @override
  String get onboardingV2BrandLatin => 'Hangeul Sori';

  @override
  String get onboardingV2BrandKorean => '한글소리';

  @override
  String get onboardingV2SyllableGa => '가';

  @override
  String get onboardingV2Back => 'Zurück';

  @override
  String get onboardingV2Next => 'Weiter';

  @override
  String get onboardingV2Loading => 'Deine Anleitung wird vorbereitet …';

  @override
  String get onboardingV2Saving => 'Deine Auswahl wird gespeichert …';

  @override
  String get onboardingV2CourseHistoryConflict =>
      'Zu diesem Kursstart gibt es bereits Lernfortschritt. Behalte zum Abschließen der Einrichtung die aktuelle Stufe; später kannst du den Kurs in den Einstellungen ausdrücklich neu starten.';

  @override
  String get onboardingV2StoryFinish => 'Meinen Start auswählen';

  @override
  String onboardingV2StoryProgress(int current, int total) {
    return 'Seite $current von $total';
  }

  @override
  String get onboardingV2Story1Eyebrow => 'Dein Lernweg';

  @override
  String get onboardingV2Story1Title => 'Vom Buchstaben\nbis zum Gespräch';

  @override
  String get onboardingV2Story1Body =>
      'Hangeul Sori verbindet Schrift, Klang und echte Situationen zu einem klaren Lernweg.';

  @override
  String get onboardingV2Story1Status =>
      'Diese Vorschau legt dein Level noch nicht fest.';

  @override
  String get onboardingV2Story1HeroSemantics =>
      'Vorschau auf den Lernweg von den ersten Buchstaben bis zu Gesprächen auf Stufe C2.';

  @override
  String get onboardingV2Story1Item1Title => 'Stufenweg A1 bis C2';

  @override
  String get onboardingV2Story1Item1Body =>
      'Lernziele und Alltagsszenen bauen aufeinander auf.';

  @override
  String get onboardingV2Story1Item2Title => 'Dein Buch fotografieren';

  @override
  String get onboardingV2Story1Item2Body =>
      'Eine Seite wird erst erfasst, wenn du die Kamera selbst öffnest.';

  @override
  String get onboardingV2Story1Item3Title => 'Text auf dem Gerät erkennen';

  @override
  String get onboardingV2Story1Item3Body =>
      'Die Texterkennung der Aufnahme läuft auf deinem Gerät. Diese Anleitung fragt nicht nach Kamerazugriff.';

  @override
  String get onboardingV2Story1Item4Title => 'Ergebnisse nach Typ';

  @override
  String get onboardingV2Story1Item4Body =>
      'Wählst du Analysieren, kann der erkannte Text an einen Analysedienst in der EU gesendet und nach Wörtern, Ausdrücken, Grammatik und Sätzen aufbereitet werden.';

  @override
  String get onboardingV2Story1CurriculumClaim =>
      'Ein stufenweises Curriculum, das sich an den CEFR-Handlungszielen und am Koreanischen Standardcurriculum des National Institute of Korean Language orientiert.';

  @override
  String get onboardingV2Story1CurriculumSourcesAction =>
      'Curriculum-Grundlage und Quellen';

  @override
  String get onboardingV2Story1CurriculumSourcesTitle =>
      'Grundlage des Stufencurriculums';

  @override
  String get onboardingV2Story1CurriculumSourcesBody =>
      'Die aktuelle Zuordnung ist teilweise. Diese offiziellen Quellen dienen als Orientierung für den Lernweg; sie behaupten weder eine Zertifizierung noch eine vollständige Prüfungsabdeckung.';

  @override
  String get onboardingV2Story1CurriculumCefrAuthority => 'Europarat · CEFR';

  @override
  String get onboardingV2Story1CurriculumNiklAuthority =>
      'National Institute of Korean Language';

  @override
  String get onboardingV2Story1CurriculumDocument => 'Offizielles Dokument';

  @override
  String get onboardingV2Story1CurriculumVersion => 'Version';

  @override
  String get onboardingV2Story1CurriculumCheckedAt => 'Quelle geprüft am';

  @override
  String get onboardingV2Story1CurriculumUrl => 'URL';

  @override
  String onboardingV2Story1CurriculumOpenSource(String sourceTitle) {
    return 'Quelle öffnen: $sourceTitle';
  }

  @override
  String get onboardingV2Story1CurriculumSourcesClose => 'Quellen schließen';

  @override
  String get onboardingV2Story2Eyebrow => 'Klang und Schrift';

  @override
  String get onboardingV2Story2Title => 'Koreanisch wird sichtbar.';

  @override
  String get onboardingV2Story2Body =>
      'Baue Silben, höre ihre Aussprache und verwende sie direkt in kurzen Sätzen.';

  @override
  String get onboardingV2Story2HeroSemantics =>
      'Interaktive Vorschau: Die Zeichen Giyeok und A werden zur Silbe ga zusammengesetzt.';

  @override
  String get onboardingV2Story2Item1Title => 'Hangeul';

  @override
  String get onboardingV2Story2Item1Body =>
      'Konsonanten und Vokale erkennen und zusammensetzen.';

  @override
  String get onboardingV2Story2Item2Title => 'Schreiben';

  @override
  String get onboardingV2Story2Item2Body =>
      'Zeichen nachfahren und anschließend selbst schreiben.';

  @override
  String get onboardingV2Story2Item3Title => 'Hören & Aussprache';

  @override
  String get onboardingV2Story2Item3Body =>
      'Beispiele anhören und die eigene Aufnahme gezielt vergleichen.';

  @override
  String get onboardingV2Story2Item4Title => 'Szenarien nach Level';

  @override
  String get onboardingV2Story2Item4Body =>
      'Alltagssituationen und Kategorien passend zum gewählten Level öffnen.';

  @override
  String get onboardingV2Story3Eyebrow => 'Wiederholen';

  @override
  String get onboardingV2Story3Title => 'Was du lernst, bleibt.';

  @override
  String get onboardingV2Story3Body =>
      'Kurze Wiederholungen erscheinen dann, wenn dein Gedächtnis sie wirklich braucht.';

  @override
  String get onboardingV2Story3HeroSemantics =>
      'Vorschau auf Kartensteuerung, Favoriten, gespeicherte Inhalte mit erhaltenem Inhaltstyp und die heutige Wiederholung unterstützter Wörter.';

  @override
  String get onboardingV2Story3Item1Title => 'Karte wenden';

  @override
  String get onboardingV2Story3Item1Body =>
      'Antippen zeigt die andere Kartenseite.';

  @override
  String get onboardingV2Story3Item2Title => 'Weiterwischen';

  @override
  String get onboardingV2Story3Item2Body =>
      'Eine Wischgeste bewegt dich durch den Stapel.';

  @override
  String get onboardingV2Story3Item3Title => 'Herz = Favorit';

  @override
  String get onboardingV2Story3Item3Body =>
      'Du merkst dir etwas ohne neue Wiederholungsaufgabe.';

  @override
  String get onboardingV2Story3Item4Title =>
      'Lesezeichen = zum Lernen speichern';

  @override
  String get onboardingV2Story3Item4Body =>
      'Auf unterstützten Wortkarten speichert das Lesezeichen das Wort in einem Wortpaket. Andere unterstützte gespeicherte Inhalte behalten in der Lernsammlung ihren echten Typ.';

  @override
  String get onboardingV2Story3Status =>
      'Jetzt verfügbar: Favoriten, gespeicherte Inhalte und heute fällige unterstützte Wörter sind getrennte Ansichten in der Lernsammlung. Die aktuelle Wiederholung unterstützt nur Wörter; Grammatik, Sätze, Ausdrücke und Hangeul bleiben ohne vorgetäuschte Wiederholungsaktion gespeichert.';

  @override
  String get onboardingV2Story4Eyebrow => 'Motivation';

  @override
  String get onboardingV2Story4Title => 'Üben darf sich gut anfühlen.';

  @override
  String get onboardingV2Story4Body =>
      'Quests und persönliche Bestwerte machen Fortschritt sichtbar, ohne dein Lernen zu bestimmen.';

  @override
  String get onboardingV2Story4HeroSemantics =>
      'Vorschau auf Spiele, Hinweise, XP, persönliche Bestwerte, Quests und mögliche Sammelbelohnungen.';

  @override
  String get onboardingV2Story4Status =>
      'Belohnungsbeispiele: Hier wird nichts gutgeschrieben';

  @override
  String get onboardingV2Story4CatalogTitle =>
      'Mögliche Belohnungen aktueller Aktivitäten';

  @override
  String onboardingV2Story4CatalogBody(int count) {
    return 'Schreibgeschützte Beispiele aus $count aktuellen Aktivitäten. Beim Ansehen dieser Seite wird nichts gutgeschrieben oder verändert.';
  }

  @override
  String onboardingV2Story4PossibleReward(String reward) {
    return 'Mögliche Belohnung: $reward';
  }

  @override
  String get onboardingV2Story4Item1Title => 'Beispiel-Quest';

  @override
  String get onboardingV2Story4Item1Body => 'Drei Silben lesen';

  @override
  String get onboardingV2Story4Item2Title => 'XP & persönliche Bestwerte';

  @override
  String get onboardingV2Story4Item2Body =>
      'Sie halten deine Aktivität und eigene Entwicklung fest.';

  @override
  String get onboardingV2Story4Item3Title => 'Quests & Stempel';

  @override
  String get onboardingV2Story4Item3Body =>
      'Nur ausgewiesene Aktivitäten können diese Belohnungen enthalten.';

  @override
  String get onboardingV2Story4Item4Title => 'Bojagi & Accessoires';

  @override
  String get onboardingV2Story4Item4Body =>
      'Sammelobjekte werden später zum Gestalten verwendet.';

  @override
  String get onboardingV2Story5Eyebrow => 'Kulturerbe-Reise';

  @override
  String get onboardingV2Story5Title => 'Mit jedem Kapitel wächst dein Hanok.';

  @override
  String get onboardingV2Story5Body =>
      'Stempel, Bojagi und Räume verbinden deinen Lernfortschritt mit einer langfristigen Kulturerbe-Reise.';

  @override
  String get onboardingV2Story5HeroSemantics =>
      'Vorschau auf die künftige Kulturerbe-Reise mit Stempelbuch, Bojagi, Dekorationen und dem ersten Kapitel Ildu Gotaek.';

  @override
  String get onboardingV2Story5Status =>
      'Erste Reise · Ildu Gotaek · In Vorbereitung';

  @override
  String get onboardingV2Story5Item1Title => 'Ankommen';

  @override
  String get onboardingV2Story5Item1Body =>
      'Hier siehst du gesammelte Stempel und offene Stationen.';

  @override
  String get onboardingV2Story5Item2Title => 'Lernen';

  @override
  String get onboardingV2Story5Item2Body =>
      'Ausgewiesene Belohnungen können Accessoires enthalten.';

  @override
  String get onboardingV2Story5Item3Title => 'Vertiefen';

  @override
  String get onboardingV2Story5Item3Body =>
      'Erhaltene Accessoires werden an dafür vorgesehenen Orten eingesetzt.';

  @override
  String get onboardingV2Story5Item4Title => 'Weitere Kapitel';

  @override
  String get onboardingV2Story5Item4Body =>
      'Die Reise ist erweiterbar; Zahl und Reihenfolge stehen noch nicht fest.';

  @override
  String get onboardingV2Story5PreviewLabel => 'Vorschau';

  @override
  String get onboardingV2Story5InPreparationLabel => 'In Vorbereitung';

  @override
  String get onboardingV2Story5AssetReviewNote =>
      'Diese Vorschau verwendet nur Grafiken, die bereits für die App freigegeben sind. Historische Bezeichnungen und Quellen bleiben klar belegt.';

  @override
  String get onboardingV2Story5SourcesAction => 'Quellen und Angaben';

  @override
  String onboardingV2Story5SourcesTitle(String estateName) {
    return 'Quellen zu $estateName';
  }

  @override
  String get onboardingV2Story5SourcesBody =>
      'Diese Quellen belegen den Namen und den kulturellen Kontext der Vorschau, darunter die Verbindung des Ildu Gotaek zum Gelehrten Jeong Yeo-chang und seine Nutzung als Drehort. Ihr aktueller Registerstatus erlaubt nur das Zitieren; weitergehende Nutzungsrechte werden nicht zugesichert.';

  @override
  String get onboardingV2Story5SourceInstitution => 'Institution';

  @override
  String get onboardingV2Story5SourceYear => 'Jahr';

  @override
  String onboardingV2Story5SourceYearValue(int year, String basis) {
    return '$year ($basis)';
  }

  @override
  String get onboardingV2Story5SourceYearPublished => 'veröffentlicht';

  @override
  String get onboardingV2Story5SourceYearUpdated => 'aktualisiert';

  @override
  String get onboardingV2Story5SourceYearAccessed => 'abgerufen';

  @override
  String get onboardingV2Story5SourceTitle => 'Quellentitel';

  @override
  String get onboardingV2Story5SourceAuthor => 'Urheber';

  @override
  String get onboardingV2Story5SourceLicense => 'Lizenzstatus';

  @override
  String get onboardingV2Story5SourceLicenseKoglType1 => 'KOGL Typ 1';

  @override
  String get onboardingV2Story5SourceLicenseCitationOnly =>
      'Nur Zitat; weitergehende Nutzungsrechte nicht zugesichert';

  @override
  String get onboardingV2Story5SourceLicenseSeparatelyApproved =>
      'Nutzung separat freigegeben';

  @override
  String get onboardingV2Story5SourceUrl => 'URL';

  @override
  String onboardingV2Story5OpenSource(String sourceTitle) {
    return 'Quelle öffnen: $sourceTitle';
  }

  @override
  String get onboardingV2Story5SourcesClose => 'Quellen schließen';

  @override
  String get onboardingV2SetupEyebrow => 'Dein persönlicher Start';

  @override
  String get onboardingV2SetupTitle => 'Dein Ziel und dein Startpunkt';

  @override
  String get onboardingV2SetupBody =>
      'Dein Ziel ändert nur die Reihenfolge von Einstiegstipps und Empfehlungen. Schwierigkeit, Inhalte, Fortschritt und Belohnungen bleiben gleich.';

  @override
  String get onboardingV2SetupPurposeHeading => 'Wofür lernst du?';

  @override
  String get onboardingV2SetupLevelHeading => 'Wo startest du?';

  @override
  String get onboardingV2SetupLevelHelp =>
      'Wähle den Startpunkt, der am besten zu dem passt, was du schon kannst. Du kannst ihn später in den Einstellungen ändern.';

  @override
  String get onboardingV2SetupSelectLevelPrompt =>
      'Wähle ein Level, um ein echtes Beispiel und die Lernziele zu sehen.';

  @override
  String get onboardingV2SetupExampleLabel => 'Beispiel auf diesem Level';

  @override
  String get onboardingV2SetupCanDoLabel => 'Das kannst du ungefähr schon';

  @override
  String get onboardingV2SetupLearnHereLabel => 'Damit beginnst du hier';

  @override
  String get onboardingV2SetupCompareAction => 'Level vergleichen';

  @override
  String get onboardingV2SetupCompareTitle => 'Welcher Startpunkt passt?';

  @override
  String get onboardingV2SetupCompareBody =>
      'Die direkte Auswahl ist dein Lernstart, kein Nachweis deiner Kenntnisse. Deinen Kurs-Startpunkt und dein Level zum Stöbern kannst du später getrennt ändern.';

  @override
  String get onboardingV2SetupCompareClose => 'Vergleich schließen';

  @override
  String get onboardingV2SetupContinue => 'Auswahl übernehmen';

  @override
  String get onboardingV2LevelA1ExampleKo => '안녕하세요.';

  @override
  String get onboardingV2LevelA2ExampleKo => '아메리카노 한 잔 주세요.';

  @override
  String get onboardingV2LevelB1ExampleKo => '어제 친구와 영화를 봤어요.';

  @override
  String get onboardingV2LevelB2ExampleKo => '회의가 길어져서 조금 늦을 것 같아요.';

  @override
  String get onboardingV2LevelC1ExampleKo => '확인된 사실과 현재의 해석을 나누어 설명하겠습니다.';

  @override
  String get onboardingV2LevelC2ExampleKo =>
      '침묵을 동의로 보면 질문의 틀만으로도 참여를 제한할 수 있습니다.';

  @override
  String get onboardingV2PurposeLifeTravelTitle => 'Alltag & Reisen';

  @override
  String get onboardingV2PurposeLifeTravelBody =>
      'Bestellen, Wege finden und tägliche Situationen meistern';

  @override
  String get onboardingV2PurposePeopleCultureTitle => 'Menschen & Kultur';

  @override
  String get onboardingV2PurposePeopleCultureBody =>
      'Gespräche, Beziehungen und kulturelle Zusammenhänge';

  @override
  String get onboardingV2PurposeStudyWorkTitle => 'Studium & Beruf';

  @override
  String get onboardingV2PurposeStudyWorkBody =>
      'Im Kurs, an der Hochschule und bei der Arbeit sicher handeln';

  @override
  String get onboardingV2PurposeKContentTitle => 'K-Content';

  @override
  String get onboardingV2PurposeKContentBody =>
      'Musik, Serien, Filme, Podcasts und Interviews besser verstehen';

  @override
  String get onboardingV2CompanionEyebrow => 'Dein Lernfreund';

  @override
  String get onboardingV2CompanionTitle => 'Wer lernt mit dir?';

  @override
  String get onboardingV2CompanionBody =>
      'Wähle Taego oder Joy. Beide begleiten denselben Lernweg; nur Ton und Rhythmus ihrer Hinweise unterscheiden sich. Du kannst später wechseln.';

  @override
  String get onboardingV2CompanionEqualNote =>
      'Inhalte, Antworten, Hinweisstärke, XP, Fortschritt und Belohnungen sind bei beiden gleich.';

  @override
  String get onboardingV2CompanionContinue => 'Auswahl bestätigen';

  @override
  String get onboardingV2CompanionTaegoRhythm =>
      'Ruhig und Schritt für Schritt';

  @override
  String get onboardingV2CompanionTaegoBody =>
      'Ordnet dieselben Hinweise in eine klare Reihenfolge und zeigt dir den nächsten sinnvollen Schritt.';

  @override
  String get onboardingV2CompanionTaegoSelected => 'Taego wurde ausgewählt.';

  @override
  String get onboardingV2CompanionJoyRhythm => 'Kurz und direkt ins Üben';

  @override
  String get onboardingV2CompanionJoyBody =>
      'Gibt dieselben Hinweise als kurze Anstöße und feiert deinen nächsten Versuch.';

  @override
  String get onboardingV2CompanionJoySelected => 'Joy wurde ausgewählt.';

  @override
  String get onboardingV2ConfirmationEyebrow => 'Bereit für den Start';

  @override
  String get onboardingV2ConfirmationBody =>
      'Das Begrüßungsvideo ist nur eine Vorstellung. Du kannst jederzeit weitergehen, auch wenn es nicht lädt.';

  @override
  String get onboardingV2ConfirmationStart => 'Gemeinsam starten';

  @override
  String get onboardingV2ConfirmationChange => 'Anderen Lernfreund wählen';

  @override
  String get settingsLearningLevelsSection => 'Lernstufen';

  @override
  String get settingsCourseStartTitle => 'Startpunkt im Kurs';

  @override
  String get settingsCourseStartDescription =>
      'Legt fest, wo dein fortlaufender Kurs beginnt. Eine neue Wahl ersetzt den aktuellen Kurspfad; frühere Einheiten gelten dadurch weder als beherrscht noch erhältst du XP oder Belohnungen.';

  @override
  String get settingsBrowseLevelTitle => 'Stufe zum Stöbern';

  @override
  String get settingsBrowseLevelDescription =>
      'Filtert nur Bibliotheken und Szenarien. Dein Kursfortschritt bleibt unverändert.';

  @override
  String get settingsRecheckLevelTitle => 'Mein Level neu einschätzen';

  @override
  String get settingsRecheckLevelDescription =>
      'Mache freiwillig einen Test mit acht Aufgaben. Das Ergebnis ist eine Empfehlung; den Startpunkt wählst weiterhin du.';

  @override
  String get settingsCompanionVisibleTitle => 'Lernfreund anzeigen';

  @override
  String get settingsCompanionVisibleDescription =>
      'Blende deinen Lernfreund ein oder aus, ohne die gewählte Figur zu ändern.';

  @override
  String get settingsGuideSection => 'App-Anleitung';

  @override
  String get settingsGuideTitle => 'Hangul-Sori-Anleitung öffnen';

  @override
  String get settingsGuideDescription =>
      'Sieh jederzeit nach, wie Lernen, Spiele, gespeicherte Inhalte, Belohnungen, dein Buch und wichtige Einstellungen funktionieren.';

  @override
  String get settingsCourseStartConfirmTitle => 'Startpunkt im Kurs ändern?';

  @override
  String settingsCourseStartConfirmDescription(String level) {
    return 'Dein fortlaufender Kurs startet bei $level neu und ersetzt den bisherigen Kursfortschritt. Andere Übungsdaten, XP, Belohnungen und Sammlungen bleiben erhalten; frühere Einheiten gelten nicht als abgeschlossen.';
  }

  @override
  String get settingsCourseStartConfirmAction => 'Startpunkt ändern';

  @override
  String get guideHubAppBarTitle => 'App-Anleitung';

  @override
  String get guideHubEyebrow => 'Sicher loslegen';

  @override
  String get guideHubTitle => 'Finde jede wichtige Funktion';

  @override
  String get guideHubDescription =>
      'Öffne ein Thema genau dann, wenn du es brauchst. Vorschauen und angekündigte Funktionen werden klar gekennzeichnet und verhalten sich nie wie fertige Funktionen.';

  @override
  String get guideCompletedLabel => 'Abgeschlossen';

  @override
  String get guideRestoreTodayCard =>
      'Start-Anleitung wieder auf Heute anzeigen';

  @override
  String get guideTodayCardRestoredStatus =>
      'Die Start-Anleitung wird wieder auf Heute angezeigt.';

  @override
  String get guidePreferenceWriteFailed =>
      'Die Einstellung der Anleitung konnte nicht gespeichert werden. Es wurde nichts geändert. Bitte versuche es erneut.';

  @override
  String get guideFeatureNotAvailable =>
      'Dieses Thema ist als Vorschau oder angekündigte Funktion markiert und lässt sich noch nicht als fertige Funktion öffnen.';

  @override
  String get guideAvailabilityLive => 'Jetzt verfügbar';

  @override
  String get guideAvailabilityPreview => 'Vorschau';

  @override
  String get guideAvailabilityComingSoon => 'In Vorbereitung';

  @override
  String get guideAvailabilityUnavailable => 'Nicht verfügbar';

  @override
  String get guideOpenAction => 'Anleitung ansehen';

  @override
  String get guidePreviewAction => 'Vorschau ansehen';

  @override
  String get guideDetailsAction => 'Status ansehen';

  @override
  String get guideModuleEyebrow => 'Thema im Überblick';

  @override
  String get guideModuleStepsTitle => 'Das solltest du zuerst wissen';

  @override
  String get guideModuleActionsTitle => 'Einen Bereich öffnen';

  @override
  String get guideModulePassiveNotice =>
      'Diese Erklärung fragt nicht nach Kamera- oder Mikrofonzugriff, spielt kein Audio ab, verändert keinen Lernfortschritt und vergibt keine Belohnungen.';

  @override
  String guideScenarioCategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Szenarien',
      one: '1 Szenario',
    );
    return '$_temp0';
  }

  @override
  String get guideModulePersonalizedStartStep1 =>
      'Dein Lernziel ändert die Reihenfolge der Empfehlungen und dieser Startliste. Schwierigkeit, XP und Belohnungen bleiben gleich.';

  @override
  String get guideModulePersonalizedStartStep2 =>
      'Der Kurs-Startpunkt setzt nach deiner Bestätigung fest, wo dein Kurs beginnt. Die Stufe zum Stöbern filtert nur Bibliotheken und Szenarien.';

  @override
  String get guideModuleLearnStep1 =>
      'Hangeul-Übersicht, Karten und Schreiben sind getrennte Reiter. Öffne nur die Übung, die du gerade brauchst.';

  @override
  String get guideModuleLearnStep2 =>
      'Unter Lernen findest du außerdem Hören, Aussprache und Szenarien nach Level. Kategorien stammen aus dem aktuellen Katalog; diese Anleitung erfindet keine Zuordnung.';

  @override
  String get guideModuleLearnStep3 =>
      'Ein Zielbereich kann seinen eigenen kontextbezogenen Hinweis einblenden. Die Anleitung schickt dich nie automatisch durch mehrere Bereiche und setzt bereits abgeschlossene Hinweise nicht zurück.';

  @override
  String get guideModuleMyBookStep1 =>
      'Kamera oder Galerie wählst du erst nach dem Öffnen der Aufnahme. Die Texterkennung läuft auf deinem Gerät; vor der Analyse prüfst du den erkannten koreanischen Text.';

  @override
  String get guideModuleMyBookStep2 =>
      'Wenn du Analysieren wählst, kann der erkannte Text an einen Analysedienst in der EU gesendet werden. Das fotografierte Bild bleibt auf deinem Gerät.';

  @override
  String get guideModuleMyBookStep3 =>
      'Unterstützte Seitenergebnisse, Wörter, Ausdrücke, Grammatik und Sätze lassen sich mit den heutigen Werkzeugen speichern. Diese Anleitung verspricht und erzeugt keine neuen KI-Übungen.';

  @override
  String get guideModuleCardsStep1 =>
      'Tippe auf eine Lernkarte, um sie umzudrehen. Wische, um zur nächsten Karte zu wechseln.';

  @override
  String get guideModuleCardsStep2 =>
      'Ein Herz ist ein unverbindlicher Favorit und startet nie die verteilte Wiederholung. Ein Lesezeichen speichert unterstützte Inhalte in deiner Lernsammlung.';

  @override
  String get guideModuleCardsStep3 =>
      'Die Lernsammlung trennt Favoriten, Gespeichertes und heute Fälliges. Der direkte Wiederholungsweg unterstützt derzeit fällige Wörter; andere gespeicherte Typen bleiben sichtbar und werden nicht als Wortwiederholung ausgegeben.';

  @override
  String get guideModuleGamesStep1 =>
      'Hinweise helfen während eines Spiels. Ihre Nutzung zählt aber nicht als selbstständiger Abruf oder als Beherrschung.';

  @override
  String get guideModuleGamesStep2 =>
      'XP, persönliche Rekorde und Quest-Fortschritt entstehen nur durch unterstützte abgeschlossene Aktivitäten. Das Ansehen dieser Anleitung vergibt nichts.';

  @override
  String get guideModuleGamesStep3 =>
      'Stempel können mit Bojagi und Dekorationen verbunden sein. Im Hanok-Bereich siehst du das derzeit verfügbare Stempelbuch, Inventar und die Raumgestaltung.';

  @override
  String get guideModuleSettingsStep1 =>
      'Kurs-Startpunkt und Stufe zum Stöbern sind getrennte Einstellungen: Die eine ändert den Kurs nach Bestätigung, die andere nur Inhaltsfilter.';

  @override
  String get guideModuleSettingsStep2 =>
      'Ausgewählte Figur und Figurenanzeige sind getrennt. Du kannst Taego oder Joy behalten und die Figur auf dem Bildschirm ausblenden.';

  @override
  String get guideModuleSettingsStep3 =>
      'Lege das allgemeine Sprechtempo in den Einstellungen fest. Unterstützte Audioseiten haben zusätzlich einen Geschwindigkeits-Chip; die App-Anleitung kannst du jederzeit in den Einstellungen erneut öffnen.';

  @override
  String get guideModuleActionCourseStart => 'Kurs-Startpunkt';

  @override
  String get guideModuleActionBrowseLevel => 'Stufe zum Stöbern';

  @override
  String get guideModuleActionHangulOverview => 'Hangeul-Übersicht';

  @override
  String get guideModuleActionHangulCards => 'Hangeul-Karten';

  @override
  String get guideModuleActionHangulWrite => 'Hangeul schreiben üben';

  @override
  String get guideModuleActionLearnStage => 'Lernen öffnen';

  @override
  String get guideModuleActionCaptureTextbook => 'Lehrbuchseite aufnehmen';

  @override
  String get guideModuleActionStudyLibrary => 'Lernsammlung öffnen';

  @override
  String get guideModuleActionGamesStage => 'Spiele öffnen';

  @override
  String get guideModuleActionHanokStage => 'Stempel und Dekoration öffnen';

  @override
  String get guideModuleActionCompanion => 'Figur und Anzeige';

  @override
  String get guideModuleActionVoiceSpeed => 'Sprechtempo';

  @override
  String get guideModuleActionGuideSettings =>
      'App-Anleitung in den Einstellungen';

  @override
  String get guideTopicPersonalizedStartTitle => 'Ein Start, der zu mir passt';

  @override
  String get guideTopicPersonalizedStartDescription =>
      'Erfahre, wie dein Ziel die Startliste und Empfehlungen sortiert und warum Kurs-Startpunkt und Stufe zum Stöbern verschieden sind.';

  @override
  String get guideTopicLearnTitle => 'Lernen';

  @override
  String get guideTopicLearnDescription =>
      'Finde Hangeul-Zeichen, Schreiben, Hören, Aussprache sowie Szenarien und Kategorien für dein Level.';

  @override
  String get guideTopicMyBookTitle => 'Mein Buch';

  @override
  String get guideTopicMyBookDescription =>
      'Fotografiere freiwillig eine Seite. Die Texterkennung läuft auf deinem Gerät. Wählst du Analysieren, kann der erkannte Text an einen Analysedienst in der EU gesendet werden. Unterstützte Ergebnisse kannst du anschließend speichern. Diese Anleitung fragt nicht nach Kamerazugriff.';

  @override
  String get guideTopicCardsAndMemoryTitle => 'Karten und Gedächtnis';

  @override
  String get guideTopicCardsAndMemoryDescription =>
      'Tippe zum Wenden und wische weiter. Ein Herz ist ein unverbindlicher Favorit und startet keine Wiederholung. Ein Lesezeichen hält unterstützte Inhalte in deiner Lernsammlung fest. Dort findest du Favoriten, gespeicherte Wörter, Grammatik, Sätze, Ausdrücke und Hangeul sowie unterstützte Wörter, die zur Wiederholung fällig sind.';

  @override
  String get guideTopicGamesAndRewardsTitle => 'Spielen und Belohnungen';

  @override
  String get guideTopicGamesAndRewardsDescription =>
      'Sieh, wie Hinweise, XP, persönliche Rekorde, Quests, Stempel, Bojagi, Accessoires und Raumgestaltung mit echten Lernaktivitäten zusammenhängen.';

  @override
  String get guideTopicSettingsTitle => 'Meine Einstellungen';

  @override
  String get guideTopicSettingsDescription =>
      'Ändere Kurs-Startpunkt, Stufe zum Stöbern, Figur, Figurenanzeige und Sprechtempo in den Einstellungen. Auf unterstützten Audioseiten kannst du das Tempo außerdem direkt über den Geschwindigkeits-Chip ändern oder diese Anleitung erneut öffnen.';

  @override
  String get studyLibraryAppBarTitle => 'Lernsammlung';

  @override
  String get studyLibraryEyebrow => 'FAVORITEN & GESPEICHERT';

  @override
  String get studyLibraryTitle => 'Alles, was du behalten möchtest';

  @override
  String get studyLibraryDescription =>
      'Favoriten und gespeicherte Lerninhalte bleiben getrennt. So entscheidest du, was nur interessant ist und was in deine Lernsammlung gehört.';

  @override
  String get studyLibraryRefresh => 'Lernsammlung aktualisieren';

  @override
  String get studyLibraryHeartMeaningTitle => 'Herz = Favorit';

  @override
  String get studyLibraryHeartMeaningBody =>
      'Ein Herz hält etwas griffbereit. Es fügt den Inhalt niemals automatisch zur Wiederholung hinzu.';

  @override
  String get studyLibraryBookmarkMeaningTitle =>
      'Lesezeichen = zum Lernen gespeichert';

  @override
  String get studyLibraryBookmarkMeaningBody =>
      'Gespeicherte Inhalte behalten ihren echten Typ: Wort, Grammatik, Satz, Ausdruck oder Hangeul.';

  @override
  String get studyLibraryFavoritesTab => 'Favoriten';

  @override
  String get studyLibrarySavedTab => 'Gespeichert';

  @override
  String get studyLibraryDueTab => 'Heute fällig';

  @override
  String get studyLibraryViewSelectorLabel => 'Ansicht der Lernsammlung wählen';

  @override
  String studyLibraryViewChoice(String view, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$view, $_temp0';
  }

  @override
  String studyLibraryViewSelected(String view, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge angezeigt',
      one: '1 Eintrag angezeigt',
    );
    return '$view. $_temp0';
  }

  @override
  String get studyLibraryFavoritesDescription =>
      'Ein Herz ist ein unverbindlicher Favorit. Favoriten starten von allein keine Wiederholung.';

  @override
  String get studyLibrarySavedDescription =>
      'Gespeicherte Wörter, Grammatik, Sätze, Ausdrücke und Hangeul behalten ihren eigenen Inhaltstyp.';

  @override
  String get studyLibraryDueDescription =>
      'Hier erscheinen nur gespeicherte Wörter, die die aktuelle Wort-Wiederholung sicher unterstützt. Andere Inhalte bleiben gespeichert, bis eine passende Übungsform verfügbar ist.';

  @override
  String get studyLibraryFavoriteStatus => 'Favorit';

  @override
  String get studyLibrarySavedStatus => 'Gespeichert';

  @override
  String get studyLibraryDueStatus => 'Fällig';

  @override
  String get studyLibraryTypeWord => 'Wort';

  @override
  String get studyLibraryTypeGrammar => 'Grammatik';

  @override
  String get studyLibraryTypeSentence => 'Satz';

  @override
  String get studyLibraryTypeExpression => 'Ausdruck';

  @override
  String get studyLibraryTypeHangul => 'Hangeul';

  @override
  String get studyLibraryLoading => 'Deine Lernsammlung wird geladen …';

  @override
  String get studyLibraryLoadErrorTitle =>
      'Die Lernsammlung konnte nicht geladen werden';

  @override
  String get studyLibraryLoadErrorBody =>
      'Es wurde nichts verändert. Versuch noch einmal, deine lokalen Favoriten und gespeicherten Inhalte zu laden.';

  @override
  String get studyLibraryFavoritesEmptyTitle => 'Noch keine Favoriten';

  @override
  String get studyLibraryFavoritesEmptyBody =>
      'Tippe bei unterstützten Inhalten auf ein Herz, um sie hier ohne zusätzliche Wiederholungen griffbereit zu halten.';

  @override
  String get studyLibrarySavedEmptyTitle => 'Noch nichts gespeichert';

  @override
  String get studyLibrarySavedEmptyBody =>
      'Lesezeichen, deine Wortpakete und unterstützte Inhalte aus deinem Buch erscheinen hier mit ihrem echten Inhaltstyp.';

  @override
  String get studyLibraryDueEmptyTitle => 'Für heute ist alles erledigt';

  @override
  String get studyLibraryDueEmptyBody =>
      'Keine unterstützten gespeicherten Wörter sind fällig. Grammatik, Sätze, Ausdrücke und Hangeul bleiben sicher gespeichert, ohne als Wörter ausgegeben zu werden.';

  @override
  String get studyLibraryUnresolvedTitle => 'Quellinhalt nicht verfügbar';

  @override
  String studyLibraryUnresolvedBody(String id) {
    return 'Dieser Favorit bleibt erhalten, aber sein ursprünglicher Inhalt ($id) kann derzeit nicht angezeigt werden.';
  }

  @override
  String get studyLibraryBookmarkUnavailableTitle =>
      'Einige gespeicherte Lesezeichen sind nicht verfügbar';

  @override
  String get studyLibraryBookmarkCorruptBody =>
      'Die Lesezeichendaten konnten nicht gelesen werden und blieben unverändert. Änderungen an Lesezeichen sind gesperrt; Favoriten und andere lokale Quellen werden weiterhin angezeigt.';

  @override
  String get studyLibraryBookmarkFutureBody =>
      'Diese Lesezeichen wurden von einer neueren App-Version geschrieben und blieben unverändert. Änderungen an Lesezeichen sind gesperrt; Favoriten und andere lokale Quellen werden weiterhin angezeigt.';

  @override
  String get studyLibrarySaveBookmark => 'Lesezeichen speichern';

  @override
  String get studyLibraryRemoveBookmark => 'Lesezeichen entfernen';

  @override
  String studyLibrarySaveBookmarkFor(String title) {
    return 'Lesezeichen für $title speichern';
  }

  @override
  String studyLibraryRemoveBookmarkFor(String title) {
    return 'Nur das Lesezeichen für $title entfernen';
  }

  @override
  String get studyLibraryBookmarkSavedStatus =>
      'Lesezeichen gespeichert. Dein Herz und alle Quellsammlungen bleiben unverändert.';

  @override
  String get studyLibraryBookmarkRemovedStatus =>
      'Lesezeichen entfernt. Dein Herz, Bücherregal, deine Wortpakete und der Wiederholungsverlauf bleiben unverändert.';

  @override
  String get studyLibraryBookmarkWriteBlocked =>
      'Solange die Lesezeichendaten nicht verfügbar sind, können Lesezeichen nicht geändert werden. Nichts wurde überschrieben.';

  @override
  String get studyLibraryBookmarkWriteError =>
      'Das Lesezeichen konnte nicht geändert werden. Deine vorhandenen Lerndaten wurden nicht verändert.';

  @override
  String get studyLibraryStartWordReview => 'Heutige Wort-Wiederholung öffnen';

  @override
  String get studyLibraryReviewScopeNote =>
      'Dadurch öffnet sich der bestehende Wort-Wiederholungsstapel. Gespeicherte Grammatik, Sätze, Ausdrücke und Hangeul werden nicht als Wörter ausgegeben.';

  @override
  String get todayGuideTitle => 'Hangul-Sori-Start-Anleitung';

  @override
  String get todayGuideDescription =>
      'Die Anleitungsthemen sind passend zu deinem Lernziel sortiert, damit du mit dem Wichtigsten beginnen kannst.';

  @override
  String todayGuideProgress(int completed, int total) {
    return '$completed von $total Themen abgeschlossen';
  }

  @override
  String get todayGuideOpenHub => 'Vollständige App-Anleitung öffnen';

  @override
  String get todayGuideDismiss => 'Start-Anleitung schließen';

  @override
  String get todayGuideDismissedStatus =>
      'Start-Anleitung geschlossen. Als Nächstes kommt dein heutiges Lernen.';

  @override
  String get homeActionLabel => 'Zur Startseite';

  @override
  String get homeActionConfirmTitle => 'Runde verlassen?';

  @override
  String get homeActionConfirmBody =>
      'Dein Fortschritt in dieser Runde geht verloren, wenn du jetzt zur Startseite gehst.';

  @override
  String get homeActionConfirmLeave => 'Zur Startseite';

  @override
  String get homeActionConfirmStay => 'Weiterspielen';
}
