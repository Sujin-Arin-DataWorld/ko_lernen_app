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
  String get paywallBenefit3 => 'Unbegrenzte Wiederholungen (SRS)';

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
  String get characterTraitMagpie => 'Fröhlich & lebendig';

  @override
  String get characterDescMagpie =>
      'In Korea gilt die Elster als Glücksbotin, die gute Nachrichten bringt. Joy feiert jeden Erfolg mit dir und bringt gute Laune in jede Lektion.';

  @override
  String get characterSelectedTiger => '태고가 선택되었습니다.';

  @override
  String get characterSelectedMagpie => '조이가 선택되었습니다.';

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
  String get moduleVocabDesc => '500+ Karten · A1 → B2 · TTS';

  @override
  String get moduleGrammarTitle => 'Grammatik';

  @override
  String get moduleGrammarDesc => '85+ Muster · auf Deutsch erklärt';

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
  String get settingsTtsRateSlow => 'Langsam';

  @override
  String get settingsTtsRateNormal => 'Normal';

  @override
  String get settingsTtsRateFast => 'Schnell';

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
  String get screenVocabTitle => 'Vokabeln';

  @override
  String get screenGrammarTitle => 'Grammatik';

  @override
  String get screenWordleTitle => 'Silben-Rätsel';

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
  String get hangulStrokeOrderTitle => '📽 Strichreihenfolge (tippe für neu)';

  @override
  String get hangulTraceTitle => 'Mit dem Finger nachzeichnen';

  @override
  String get hangulClearBtn => 'Löschen';

  @override
  String hangulPronounceLetter(Object letter) {
    return '$letter aussprechen';
  }

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
      'Das Bild bleibt auf deinem Gerät. Nur erkannter Text wird analysiert.';

  @override
  String get bookCaptureCamera => 'Kamera';

  @override
  String get bookCaptureGallery => 'Aus Galerie';

  @override
  String get bookCaptureLoading => 'Texterkennung läuft …';

  @override
  String get bookCaptureErrorNoKorean =>
      'Kein Koreanisch erkannt. Bitte mach ein schärferes Foto.';

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
    return '$count Textblöcke erkannt. Korrigiere sie bei Bedarf.';
  }

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
  String dojangProgress(int earned, int total) {
    return '$earned von $total Stempeln gesammelt';
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
  String get gyeCreatedTitle => 'Gye erstellt!';

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
    return '$name beigetreten!';
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
  String get bookResultSectionWords => 'Wörter';

  @override
  String get bookResultSectionGrammar => 'Grammatik';

  @override
  String get bookResultSectionSentences => 'Sätze';

  @override
  String get bookResultSave => 'In meinem Bücherregal speichern';

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
      'Diese Stempel sind Andenken an geschaffte Wortpakete. Um deine Hanok-Stuben einzurichten, schließe Quests ab und öffne die Bündel, die du dabei bekommst.';

  @override
  String get dojangDecorHintCta => 'Zu den Quests';

  @override
  String get hanokCinematicIntro => 'Dein Hanok wächst.';

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
  String get vocabPackLearnHint => 'Tippen zum Umdrehen';

  @override
  String get vocabPackDontKnow => 'Weiß ich nicht';

  @override
  String get vocabPackGotIt => 'Gewusst';

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
  String get vocabPackResultCleared => 'Paket geschafft!';

  @override
  String get vocabPackResultClearedAgain => 'Schon gemeistert. Gut wiederholt!';

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
  String get vocabPackResultBackToGrid => 'Zurück zu den Paketen';

  @override
  String get vocabPackResultGeschafft =>
      'Geschafft! Du hast dieses Vokabelpaket gemeistert.';

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
  String get onboardingPage1Title => 'Treffe deinen Lernfreund';

  @override
  String get onboardingPage1Subtitle => 'Taego begleitet dich beim Lernen';

  @override
  String get onboardingPage2Title => '5 Minuten pro Tag';

  @override
  String get onboardingPage2Subtitle =>
      'Kurz und leicht in den Alltag einzubauen';

  @override
  String get onboardingPage3Title => 'Streaks zählen';

  @override
  String get onboardingPage3Subtitle =>
      'Mit regelmäßigem Lernen sammelst du Belohnungen.';

  @override
  String get onboardingPage4Title => 'Wie viel Zeit hast du?';

  @override
  String get onboardingGoal5min => '5 Minuten';

  @override
  String get onboardingGoal10min => '10 Minuten';

  @override
  String get onboardingGoal15min => '15 Minuten';

  @override
  String get onboardingStartEyebrow => 'Dein erster Weg';

  @override
  String get onboardingStartTitle => 'Wofür willst du Koreanisch sprechen?';

  @override
  String get onboardingStartBody =>
      'Wir beginnen mit einer Situation aus deinem Alltag, nicht mit einem Test.';

  @override
  String get onboardingStartTravelTitle => 'In Korea unterwegs sein';

  @override
  String get onboardingStartTravelBody => 'Café, Weg, Einkaufen und Hilfe';

  @override
  String get onboardingStartPeopleTitle => 'Mit Menschen sprechen';

  @override
  String get onboardingStartPeopleBody => 'Freunde, Familie und Alltag';

  @override
  String get onboardingStartWorkTitle => 'Studium oder Arbeit';

  @override
  String get onboardingStartWorkBody => 'Höflich fragen und verstehen';

  @override
  String get onboardingStartPoint => 'Startpunkt';

  @override
  String get onboardingStartNewTitle => 'Ich beginne neu';

  @override
  String get onboardingStartNewBody => 'Direkt mit Hören und Sprechen';

  @override
  String get onboardingStartExistingTitle => 'Ich kann schon etwas';

  @override
  String get onboardingStartExistingBody =>
      'Level wählen oder 8–10 Fragen testen';

  @override
  String get onboardingStartPrimary => 'Meine erste Szene öffnen';

  @override
  String get onboardingStartChooseLevel => 'Level wählen';

  @override
  String get onboardingStartLoading => 'Deine erste Szene wird vorbereitet …';

  @override
  String get onboardingCompanionChoose => 'Lernfreund wählen';

  @override
  String get onboardingCompanionSkip => 'Jetzt nicht';

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
  String get onboardingLevelB1Desc => 'Alltagsgespräche möglich';

  @override
  String get onboardingLevelB2 => 'Fortgeschritten';

  @override
  String get onboardingLevelB2Desc => 'Fließend, auch Nuancen';

  @override
  String get onboardingExampleA1Trans => 'Hallo / Guten Tag.';

  @override
  String get onboardingExampleA2Trans => 'Einen Iced Americano in Tall, bitte.';

  @override
  String get onboardingExampleB1Trans =>
      'Gestern war ich mit einem Freund im Kino. Hat richtig Spaß gemacht.';

  @override
  String get onboardingExampleB2Trans =>
      'Das Meeting zieht sich, ich komme wohl etwas später.';

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
  String get onboardingCompareClose => 'Verstanden';

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
      'Beruf und Nachrichten, Nuancen, Redewendungen, Ehrerbietung.';

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
  String get scenariosListSubtitle => 'Lerne durch echte Situationen';

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
  String get particlePopHint => 'Zieh die richtige Partikel in den Slot.';

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
      'Stark! Morgen warten neue Missionen auf dich.';

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
  String get vocabModeFavorites => 'Favoriten';

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
      'Noch keine Favoriten\nMarkiere schwierige Wörter mit dem Stern';

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
  String get listeningPickFirst => 'Wähl oben ein Szenario, um zu starten.';

  @override
  String get listeningEmptyTitle => 'Noch keine Szenarien';

  @override
  String get listeningEmptyBody =>
      'Sobald Szenarien verfügbar sind, kannst du sie hier anhören.';

  @override
  String get kkeunmariTitle => 'Wortkette';

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
    return 'Bester: $count Versuche';
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
  String get clozeLevelAll => 'Alle';

  @override
  String get speedMatchTitle => 'Blitz-Paare';

  @override
  String get speedMatchDesc => 'Auf Zeit zuordnen';

  @override
  String get speedMatchInstruction =>
      'Tippe ein koreanisches Wort, dann die passende Bedeutung.';

  @override
  String speedMatchScore(int count) {
    return '$count Paare';
  }

  @override
  String speedMatchBest(int count) {
    return 'Bester: $count Paare';
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
    return '${count}er-Combo!';
  }

  @override
  String get pathTitle => 'Lernpfad';

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
  String get gyeEmptyHeadline =>
      'Allein lernen ist vollständig. Zusammen kann es wärmer sein.';

  @override
  String get gyeEmptyPreviewCaption =>
      'Eine Vorschau auf einen gemeinsamen Hof — nie Voraussetzung für deinen Lernweg';

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
  String get navProfile => 'Profil';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileGuestName => 'Gast';

  @override
  String get profileGuestBadge => 'Behalte Streak, XP & Hanok';

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
  String get profileLearningGoal => 'Mein Ziel';

  @override
  String get profileLearningGoalNotSet =>
      'Wähle, was dich zum Koreanischen bringt';

  @override
  String get profileLearningStartPoint => 'Mein Startpunkt';

  @override
  String get profileLearningCompanion => 'Lernbegleitung';

  @override
  String get profileSpaceSection => 'Mein Raum';

  @override
  String get profilePrivacyAccount => 'Datenschutz & Konto';

  @override
  String get profilePrivacyAccountDescription =>
      'Daten, Sicherung und Kontosteuerung';

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
  String get grammarEasy => 'Verstanden';

  @override
  String get grammarHard => 'Schwierig';

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
      'Scanne, schlage etwas nach, höre zu oder mach eine kurze Übungspause. Entdecken ersetzt nie deinen heutigen Lernschritt.';

  @override
  String get discoverSearchHint => 'Suchen: Aussprache, Buch, OCR …';

  @override
  String get discoverStartHere => 'Starte mit deiner Buchseite';

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
  String get discoverCategoryWords => 'Wörter & Bücher';

  @override
  String get discoverCategoryProgress => 'Dein Weg';

  @override
  String get navLearn => 'Lernen';

  @override
  String get navPractice => 'Üben';

  @override
  String get navWordbook => 'Wörter';

  @override
  String get navGye => 'Gruppe';

  @override
  String get gyeTabSubtitle => 'Zusammen lernen · Gye';

  @override
  String get gyeExplainWhat =>
      'Ein Gye ist eine freiwillige kleine Gruppe zum Koreanischlernen. Allein zu lernen ist genauso vollständig.';

  @override
  String get gyeExplainWhy =>
      'Ein gemeinsames Hanok macht Ermutigung sichtbar. Es ist nie ein Wettbewerb und nie Voraussetzung für deinen Lernweg.';

  @override
  String get gyeExplainHow =>
      'Gründe eine Gruppe oder tritt mit einem 6-stelligen Code bei, wenn du bereit bist.';

  @override
  String get gyePrivacyTitle => 'Was andere sehen können';

  @override
  String get gyePrivacyBody =>
      'Nur dass du in der Gruppe ein Paket abgeschlossen hast — niemals deine Antworten, gespeicherten Wörter oder Prüfungsergebnisse.';

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
  String get gyePromiseEyebrow => 'Diese Woche zusammen';

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
      'Eine Laterne leuchtet nach einer kursgebundenen Szene mit mindestens 70 %. Antworten, Punkte und Mitwirkende bleiben privat.';

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
  String get gyeOpenToday => 'Heutiges Lernen öffnen';

  @override
  String get gyeCourtyardEyebrow => 'Euer Hof';

  @override
  String get gyeCourtyardTitle =>
      'Ein gemeinsamer Ort für kleine, sichere Ermutigung.';

  @override
  String get gyeCourtyardBody =>
      'Die Hofansicht folgt den vorhandenen Wochenziel-Daten. Sie ändert weder einen persönlichen Kurs noch ein persönliches Hanok.';

  @override
  String get gyeSafeMessage => 'Sichere Ermutigung senden';

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
  String get practiceEyebrow => 'Üben nach deinem Bedarf';

  @override
  String get practiceTitle => 'Was möchtest du gerade festigen?';

  @override
  String get practiceSubtitle =>
      'Wähle zuerst ein Bedürfnis. Dein einziger nächster Lernschritt bleibt auf Start.';

  @override
  String get practiceDueTitle => 'Fällige Wörter wiederholen';

  @override
  String get practiceDueEmpty => 'Öffne eine Wiederholung, wann du möchtest';

  @override
  String get practiceSecLearn => 'Etwas gezielt üben';

  @override
  String get practiceSecGames => 'Frei spielen';

  @override
  String get practiceSecWords => 'Deine Wörter';

  @override
  String get practiceSecSpace => 'Dein Lernraum';

  @override
  String get pathEvidenceTitle => 'Woran du echten Fortschritt erkennst';

  @override
  String get pathEvidenceBody =>
      'Freies Ansehen speichert nur Verlauf. Ein Kursabschnitt wird erst durch seine aktive Prüfung und mindestens 70 % in jeder verknüpften Szenenprüfung bestätigt.';

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
      'Schritt 1 · Lernen: Karten umdrehen und einprägen';

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
  String get coachChosungStep1Title => 'Silben-Puzzle';

  @override
  String get coachChosungStep1Body =>
      'Füll die gepunkteten Felder aus und vervollständige das Wort';

  @override
  String get coachChosungStep2Title => 'Niveau & Schwierigkeit';

  @override
  String get coachChosungStep2Body =>
      'Wähle dein Level von A1 bis B2 und ob Vokale angezeigt werden';

  @override
  String get coachChosungStep3Title => 'Antwort eingeben';

  @override
  String get coachChosungStep3Body =>
      'Gib das vollständige koreanische Wort ein und bestätige';

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
  String get coachListeningStep2Title => 'Tempo & Untertitel';

  @override
  String get coachListeningStep2Body =>
      'Stelle die Geschwindigkeit von 0,75× bis 1,25× und den Untertitelmodus ein';

  @override
  String get coachListeningStep3Title => 'Zeile für Zeile';

  @override
  String get coachListeningStep3Body =>
      'Hör zu und tippe ⟳ zum Wiederholen oder Weiter zur nächsten Zeile';

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
      '\"Gewusst\" verlängert das Intervall · \"Nicht gewusst\" bringt die Karte früher zurück';

  @override
  String get coachLegacyVocabTitle => 'Karteikarte';

  @override
  String get coachLegacyVocabBody =>
      'Antippen = umdrehen · lang halten = langsam vorlesen lassen';

  @override
  String get coachLearningPathTitle => 'Dein Lernpfad';

  @override
  String get coachLearningPathBody =>
      'Starte beim orangen \"Jetzt\"-Knoten und arbeite dich Schritt für Schritt vor';

  @override
  String get coachBookshelfStep1Title => 'Wörterbuch erstellen';

  @override
  String get coachBookshelfStep1Body =>
      'Tippe auf ＋ oben rechts, um ein eigenes Wörterbuch anzulegen';

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
      'Antippen = Karte umdrehen · \"Gewusst\" = Wort zum SRS-System hinzufügen';

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
      'Schließe Vokabelpacks ab, um alle 8 Dancheong-Muster freizuschalten';

  @override
  String get coachGyeStep1Title => 'Wochenziel';

  @override
  String get coachGyeStep1Body =>
      'Hier seht ihr euren gemeinsamen Fortschritt. Zusammen bleibt ihr leichter dran.';

  @override
  String get coachGyeStep2Title => 'Sticker senden';

  @override
  String get coachGyeStep2Body =>
      'Tippe auf den Smiley-Button, um ein Sticker zur Motivation zu senden';

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
  String get questCheckAnswer => 'Überprüfen';

  @override
  String get diktatInstruction => 'Hör zu und tippe, was du hörst';

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
      'Jetzt bist du dran. Formuliere deine eigene Antwort.';

  @override
  String get scenarioRoleplayTurn => 'Deine Antwort';

  @override
  String get scenarioRoleplayDoneTitle => 'Rollenspiel geschafft!';

  @override
  String get scenarioRoleplayDoneBody => 'Du hast das Gespräch selbst geführt.';

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
  String get courseMissionNow => 'jetzt';

  @override
  String get courseMissionPreviewTag => 'Vorschau';

  @override
  String get courseMissionStartPractice => 'Übung starten';

  @override
  String get courseMissionPreviewNotice =>
      'Du kannst diese Mission ansehen. Punkte und Fortschritt zählen erst, wenn sie aktiv ist.';

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
  String get homeTodayMissionStart => 'Diese Szene beginnen';

  @override
  String get homeTodayCourseAction => 'Diese Handlung üben';

  @override
  String get homeTodayPackAction => 'Diese Wörter üben';

  @override
  String get homeTodayReviewAction => 'Jetzt wiederholen';

  @override
  String get homeTodayScenarioAction => 'Diese Szene üben';

  @override
  String get homeTodayPackDescription =>
      'Übe die Wörter, die du als Nächstes brauchst.';

  @override
  String get homeTodayReviewDescription =>
      'Damit der Satz in deiner nächsten Szene bereit ist.';

  @override
  String get homeTodayReviewReasonTitle => 'Warum heute wiederholen?';

  @override
  String get homeTodayReviewReason =>
      'Damit Begrüßungen, Bitten und Antworten in deiner nächsten Szene bereit sind.';

  @override
  String get homeTodayReviewTime =>
      'Etwa 3 Minuten · dann geht dein Weg weiter.';

  @override
  String get homeUnavailableTitle =>
      'Dein Weg konnte nicht aktualisiert werden.';

  @override
  String get homeUnavailableDescription =>
      'Gespeicherte Wiederholungen und bereits gelernte Inhalte bleiben auf diesem Gerät verfügbar.';

  @override
  String get homeUnavailableCta => 'Gespeicherte Wörter wiederholen';

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
  String get sarangbangHubDesc =>
      'Dein nächster Lernschritt beginnt im Sarangbang.';

  @override
  String get bojagiTitle => 'Bojagi-Bündel';

  @override
  String get bojagiOpenHint => 'Tippe auf den Knoten, um das Bündel zu öffnen.';

  @override
  String get bojagiPickTitle => 'Such dir eins aus';

  @override
  String get bojagiPickBody =>
      'Was du liegen lässt, bleibt im Beutel und kann in einem späteren Bündel wiederkommen.';

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
  String get hanokWorldIntro =>
      'Lerne dort weiter, wo deine Hanok wächst. Jeder fertige Ort führt zu einem vertrauten Teil von Hangul Sori.';

  @override
  String get hanokWorldLegacyTitle => 'Dein Hof nimmt Gestalt an';

  @override
  String get hanokWorldLegacyBody =>
      'Schließe deinen A1- und A2-Weg ab. Mit deinem ersten B1-Fortschritt öffnet sich das Tor zur großen Hanok-Karte.';

  @override
  String get hanokWorldMapHint =>
      'Tippe auf ein fertig gebautes Gebäude, um dort weiterzulernen.';

  @override
  String get hanokWorldOpenSarangbang => 'Im Sarangbang lernen';

  @override
  String get hanokWorldProgress => 'Baufortschritt deiner Hanok';

  @override
  String get hanokWorldGyeBridgeTitle => 'Der Gye-Hof';

  @override
  String get hanokWorldGyeBridgeBody =>
      'Deine private Hanok und der gemeinsame Gye-Hof wachsen nebeneinander. Triff deine Lerngruppe dort.';

  @override
  String get hanokWorldGyeBridgeOpen => 'Gye-Hof besuchen';

  @override
  String get hanokWorldPlacesTitle => 'Orte in deiner Hanok';

  @override
  String get hanokWorldPlacesBody =>
      'Wähle hier einen fertig gebauten Ort aus.';

  @override
  String get hanokZoneSarangbang => 'Sarangbang · heutiges Lernen';

  @override
  String get hanokZoneDaecheong => 'Daecheongmaru · Lernpfad';

  @override
  String get hanokZoneHaengrang => 'Haengrangchae · Üben';

  @override
  String get hanokZoneAnchae => 'Anchae · meine Sammlung';

  @override
  String get hanokZoneHuwon => 'Huwon · Tagesziel';

  @override
  String get hanokZoneSadang => 'Sadang · Erfolge';

  @override
  String get hanokWorldSelectPlaceTitle => 'Einen fertigen Ort wählen';

  @override
  String get hanokWorldSelectPlaceBody =>
      'Tippe auf ein Gebäude in der Karte oder wähle es aus der zugänglichen Liste.';

  @override
  String hanokWorldPlaceReadyBody(String place) {
    return '$place ist bereit für deinen nächsten Lernschritt.';
  }

  @override
  String hanokWorldOpenPlace(String place) {
    return 'Nach $place gehen';
  }

  @override
  String get hanokWorldTodayMarker => 'Heutiges Lernen';

  @override
  String hanokWorldRevealTitle(String place) {
    return '$place ist fertig';
  }

  @override
  String get hanokWorldRevealBody =>
      'Holz, Staub und Dancheong: Ein neuer Teil deiner Hanok ist entstanden.';

  @override
  String get hanokWorldRevealContinue => 'Weiter zur Karte';

  @override
  String get hanokVenueFurnishRoom => 'Diesen Raum einrichten';

  @override
  String get hanokVenueAnbangBody =>
      'Im ruhigen inneren Raum bewahrst du Wörter, Seiten und eigene Lernsammlungen.';

  @override
  String get hanokVenueDaecheongBody =>
      'Auf dem offenen Maru setzt du deinen Lernweg fort oder richtest den Raum ein.';

  @override
  String get hanokVenueHaengrangBody =>
      'Im Eingangsflügel wartet dein Übungsatelier auf eine weitere Runde.';

  @override
  String get hanokVenueHuwonBody =>
      'Im hinteren Garten wartet ein ruhiger Moment für dein Zeichen des Tages oder eine neue Quest.';

  @override
  String get hanokVenueSadangBody =>
      'Im Ahnenschrein sammelst du sichtbare Spuren deines Lernwegs.';

  @override
  String get sarangbangStudyTitle => 'Sarangbang';

  @override
  String get sarangbangStudyIntroTitle => 'Dein nächster Lernschritt wartet';

  @override
  String get sarangbangStudyIntroBody =>
      'Hier beginnt genau die Übung, die heute zu deinem Fortschritt passt.';

  @override
  String get sarangbangStudySceneLabel => 'Deine Studierstube';

  @override
  String get sarangbangStudyFurnish => 'Studierstube einrichten';

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
}
