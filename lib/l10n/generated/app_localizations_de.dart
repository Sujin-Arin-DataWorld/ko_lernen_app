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
  String get paywallSubtitle => 'Lern Koreanisch ohne Grenzen.';

  @override
  String get paywallBenefit1 => 'Alle Vokabel-Packs (A2 · B1 · B2)';

  @override
  String get paywallBenefit2 => 'Alle Gesprächs-Szenarien';

  @override
  String get paywallBenefit3 => 'Unbegrenzte Wiederholungen (SRS)';

  @override
  String get paywallBenefit4 => 'Dein persönlicher KI-Kurs — jeden Tag neu';

  @override
  String get paywallBenefit5 => 'Buchschnappschuss ohne Tageslimit';

  @override
  String get paywallPriceFallback => '5 € / Monat';

  @override
  String get paywallPricePerMonth => '/ Monat';

  @override
  String get paywallCtaStart => 'Premium starten';

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
  String get paywallSuccess => 'Premium ist aktiv. Viel Spaß! 🎉';

  @override
  String get paywallFailed => 'Kauf nicht abgeschlossen.';

  @override
  String get paywallRestoreNone => 'Keine früheren Käufe gefunden.';

  @override
  String get reviewTitle => 'Heute lernen';

  @override
  String get reviewEmptyTitle => 'Alles erledigt!';

  @override
  String get reviewEmptyBody =>
      'Für heute sind keine Karten fällig. Spiel eine Runde oder lern ein neues Pack — die Wörter tauchen hier zur Wiederholung auf.';

  @override
  String get reviewDoneTitle => 'Stark! 🎉';

  @override
  String get reviewDoneBody => 'Du hast deine fälligen Karten wiederholt.';

  @override
  String get reviewBonusLabel => 'Satz des Tages';

  @override
  String get homeReviewTitle => 'Heute lernen';

  @override
  String homeReviewDue(int n) {
    return '$n Wörter fällig';
  }

  @override
  String get homeReviewDone => 'Heute alles wiederholt 🎉';

  @override
  String get settingsNotifSection => 'Erinnerung';

  @override
  String get settingsNotifTitle => 'Tägliche Erinnerung';

  @override
  String get settingsNotifSubtitle => 'Der Tiger erinnert dich ans Lernen';

  @override
  String get settingsNotifTime => 'Uhrzeit';

  @override
  String get settingsNotifDenied =>
      'Benachrichtigungen sind deaktiviert. Erlaube sie in den Systemeinstellungen.';

  @override
  String get notificationTitle => 'Hangul Sori';

  @override
  String get notificationBody => 'Der Tiger wartet — Zeit für Koreanisch! 🐯';

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
  String get welcomeMsg => 'Hallo! Viel Erfolg heute 💪';

  @override
  String get footerCheer => 'Viel Erfolg beim Lernen 🌟';

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
  String get gameWordleTitle => 'Wordle';

  @override
  String get gameWordleDesc => '2–3 Silben · 6 Versuche';

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
  String get navWordle => 'Wordle';

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
      'Knipse deine erste Lehrbuchseite — die analysierten Wörter landen hier.';

  @override
  String get bookshelfEmptyCta => 'Seite einlesen';

  @override
  String get bookshelfSectionPages => 'Seiten';

  @override
  String get bookshelfSectionCustomPacks => 'Eigene Packs';

  @override
  String bookshelfTileMeta(int words, int grammar, String date) {
    return '$words Wörter · $grammar Grammatik · $date';
  }

  @override
  String bookshelfPackMeta(int n) {
    return '$n Wörter';
  }

  @override
  String get bookshelfPageTitle => 'Seite';

  @override
  String get bookshelfPageNotFoundTitle => 'Seite nicht gefunden';

  @override
  String get bookshelfPageNotFoundBody => 'Möglicherweise wurde sie gelöscht.';

  @override
  String get bookshelfCreatePackCta => 'Custom-Pack aus dieser Seite';

  @override
  String get bookshelfCreatePackTitle => 'Neuer Custom-Pack';

  @override
  String get bookshelfCreatePackName => 'Name';

  @override
  String get bookshelfCreatePackSaved => 'Pack gespeichert.';

  @override
  String get bookshelfDeletePageTitle => 'Seite löschen?';

  @override
  String get bookshelfDeletePageBody => 'Die Seite wird endgültig entfernt.';

  @override
  String get bookshelfDeletePackTitle => 'Pack löschen?';

  @override
  String bookshelfDeletePackBody(Object name) {
    return 'Soll \"$name\" gelöscht werden?';
  }

  @override
  String get customPackPlayTitle => 'Custom-Pack üben';

  @override
  String get customPackNotFoundTitle => 'Pack nicht gefunden';

  @override
  String get customPackNotFoundBody => 'Möglicherweise wurde es gelöscht.';

  @override
  String get customPackEmptyTitle => 'Pack ist leer';

  @override
  String get customPackEmptyBody => 'Dieser Pack enthält noch keine Wörter.';

  @override
  String get customPackResultTitle => 'Geschafft';

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
  String get homeBookCardDesc => 'Knipsen → Wörter & Grammatik';

  @override
  String get homeBookshelfCardTitle => 'Mein Bücherregal';

  @override
  String get homeBookshelfCardDesc => 'Gespeicherte Seiten & Custom-Packs';

  @override
  String get homeQuestsCardTitle => 'Quests';

  @override
  String get homeQuestsCardDesc => 'Mehr Hanok-Dekoration freischalten';

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
  String get wordleResultWin => '🎉 Geschafft!';

  @override
  String get wordleResultLose => '😢 Daneben';

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
  String get settingsReset => 'Alle Daten zurücksetzen';

  @override
  String get settingsResetConfirm =>
      'Wirklich alle Lernfortschritte löschen? Das kann nicht rückgängig gemacht werden.';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String settingsVersion(Object v) {
    return 'Version $v';
  }

  @override
  String get settingsPrivacyTitle => 'Datenschutz';

  @override
  String get settingsPrivacySubtitle => 'URL kopieren';

  @override
  String settingsPrivacyCopied(Object url) {
    return 'URL kopiert: $url';
  }

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
  String get statsWordleWins => 'Wordle Siege';

  @override
  String get statsWordleStreak => 'Wordle Streak';

  @override
  String get screenVocabTitle => 'Vokabeln';

  @override
  String get screenGrammarTitle => 'Grammatik';

  @override
  String get screenWordleTitle => 'Wordle';

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
  String get hangulRulesTitle => '✏️ Hangul-Schreibregeln';

  @override
  String get hangulRulesBody =>
      '① Oben → Unten   ② Horizontal → Vertikal   ③ Links → Rechts';

  @override
  String get hangulStrokeOrderTitle => '📽 Strichreihenfolge (tippe für neu)';

  @override
  String get hangulTraceTitle => '✍️ mit dem Finger nachzeichnen';

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
    return '$n Silben eingeben…';
  }

  @override
  String get wordleLegendCorrect => 'Richtige Stelle';

  @override
  String get wordleLegendPresent => 'Falsche Stelle';

  @override
  String get wordleLegendAbsent => 'Nicht da';

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
    return 'Schöne Übung — bleib bei Stufe $level.';
  }

  @override
  String chosungRoundReview(Object level) {
    return 'Übe Stufe $level ruhig nochmal.';
  }

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsSubtitle => 'Dein Lernfortschritt';

  @override
  String get statsDays => 'Tage';

  @override
  String get statsCards => 'Karten';

  @override
  String get statsPercent => 'Genauigkeit';

  @override
  String get statsWins => 'Siege';

  @override
  String get statsEmpty => 'Noch keine Daten — leg los! 🚀';

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
    return '🔥 $n fällig';
  }

  @override
  String vocabTodayBadge(int newCount, int reviewCount) {
    return '🔥 Heute ($newCount neu · $reviewCount Wdh.)';
  }

  @override
  String get vocabDueEmpty => '🎉 Heute alles erledigt!\nKomm morgen wieder.';

  @override
  String get vocabDueEmptyAction => 'Trotzdem üben';

  @override
  String get vocabPacksTitle => 'Vokabel-Packs';

  @override
  String get vocabPacksLevelMenu => 'Level wechseln';

  @override
  String vocabPacksProgressLabel(int cleared, int total) {
    return '$cleared/$total Packs geklärt';
  }

  @override
  String get vocabPacksEmptyTitle => 'Noch keine Packs';

  @override
  String get vocabPacksEmptyBody =>
      'Für dieses Level sind noch keine Vokabeln vorbereitet.';

  @override
  String get vocabPackLockedNoPrev => '🔒 Dieses Pack ist noch gesperrt.';

  @override
  String vocabPackLockedHint(Object prev) {
    return '🔒 Schaffe zuerst \"$prev\" mit ≥ 70 % Bossen.';
  }

  @override
  String get bookCaptureTitle => 'Buchseite einlesen';

  @override
  String get bookCaptureHero => 'Knipse eine Lehrbuchseite';

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
      'Kein Koreanisch erkannt — bitte eine deutlichere Aufnahme.';

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
    return '$count Textblöcke erkannt — bei Bedarf korrigieren.';
  }

  @override
  String get bookPreviewAnalyze => 'Analysieren';

  @override
  String get bookPreviewRetake => 'Neu aufnehmen';

  @override
  String get bookResultTitle => 'Ergebnis';

  @override
  String get bookResultAnalyzing => 'Wörter & Grammatik werden untersucht …';

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
      'Schließe Vokabelpakete ab, um Dancheong-Stempel zu sammeln.';

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
  String get gyeNicknameHint => 'Wird Gye-Mitgliedern angezeigt';

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
  String get gyeErrAgeRestricted => 'Gye ist ab 16 Jahren verfügbar (DSGVO).';

  @override
  String get gyeAgeYearTitle => 'Geburtsjahr';

  @override
  String get gyeAgeYearBody =>
      'Gye ist ab 16 Jahren verfügbar (DSGVO). Bitte gib dein Geburtsjahr ein.';

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
  String get gyeDureEmpty => 'Noch leer — knack ein Pack und mach den Anfang!';

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
      'Noch keine Aktivität. Schließt gemeinsam Pakete ab!';

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
  String get gyeFeedGoalAchieved =>
      'Wochenziel erreicht! 🎉 Euer Hanok wächst.';

  @override
  String get gyeStickerSend => 'Sticker senden';

  @override
  String get gyeStickerRateLimited => 'Zu viele Sticker — kurz langsamer.';

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
  String get bookResultOfflineNotice =>
      'Server nicht erreichbar — nur Grammatikmuster offline erkannt.';

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
      'Beginne ein Pack — die ersten Quest-Fortschritte erscheinen hier.';

  @override
  String get questsSectionInProgress => 'Läuft';

  @override
  String get questsSectionAvailable => 'Verfügbar';

  @override
  String get questsSectionCompleted => 'Geklärt';

  @override
  String get questsSectionSeasonalLocked => 'Saisonal (gesperrt)';

  @override
  String get questsSeasonalBadge => 'Saison';

  @override
  String get questsCompletionCelebration => 'Neue Hofmöbel freigeschaltet!';

  @override
  String get hanokCinematicIntro => 'Dein Hanok wächst —';

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
  String get vocabPackPlayTitle => 'Pack-Übung';

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
  String get vocabPackResultCleared => '🎉 Pack geklärt!';

  @override
  String get vocabPackResultClearedAgain => 'Bereits geklärt — gut wiederholt!';

  @override
  String get vocabPackResultRetry => 'Fast geschafft — nochmal probieren!';

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
  String get vocabPackResultBackToGrid => 'Zurück zu den Packs';

  @override
  String get vocabPackResultGeschafft =>
      'Geschafft! Du hast diesen Wortschatz-Pack gemeistert.';

  @override
  String get moduleStatsTitle => 'Statistik';

  @override
  String get moduleStatsDesc => 'Streak, Karten, Genauigkeit';

  @override
  String get settingsCloudSection => 'Cloud-Backup';

  @override
  String settingsCloudSignedIn(Object name) {
    return 'Eingeloggt: $name';
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
      'Dadurch wird das Cloud-Backup für das aktuelle Firebase-Konto gelöscht. Lokale Fortschritte auf diesem Gerät werden nicht gelöscht.';

  @override
  String get settingsCloudDeleteDataSuccess => 'Cloud-Daten gelöscht';

  @override
  String get settingsAccountDelete => 'Konto und alle Daten löschen';

  @override
  String get settingsAccountDeleteDesc =>
      'Löscht dein Firebase-Konto, Cloud-Backup und lokale Fortschritte.';

  @override
  String get settingsAccountDeleteConfirmTitle => 'Konto dauerhaft löschen?';

  @override
  String get settingsAccountDeleteConfirmBody =>
      'Dadurch werden dein Firebase-Konto, die Google-Verknüpfung, das Firestore-Cloud-Backup und lokale Lerndaten auf diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden. Google kann dich zur Bestätigung erneut anmelden lassen.';

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
      'Info-URL zur Löschung kopieren';

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
  String get onboardingTitle => 'Was ist dein Level?';

  @override
  String get onboardingSubtitle =>
      'Wir fangen bei dir an. Frühere Levels bleiben offen, spätere schaltest du frei.';

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
      'Tippe dein Level — du kannst es in den Einstellungen ändern.';

  @override
  String get onboardingTigerGreeting => '환영해요!\n어떤 레벨부터 시작할까요?';

  @override
  String get homeHeroGreetingMorning => 'Guten Morgen!';

  @override
  String get homeHeroGreetingAfternoon => 'Hallo!';

  @override
  String get homeHeroGreetingEvening => 'Guten Abend!';

  @override
  String get homeTigerBubbleStart => 'Sollen wir 5 Minuten lernen? 📖';

  @override
  String get homeTigerBubbleStreak => 'Streak hält! Weiter so 🔥';

  @override
  String get homeTigerBubbleResume => 'Willkommen zurück!';

  @override
  String get homeShieldLabel => 'Schild';

  @override
  String get homePathSection => 'Dein Pfad';

  @override
  String get homePathLocked => 'Verschlossen';

  @override
  String get homePathCurrent => 'Jetzt';

  @override
  String get homePathDone => 'Erledigt';

  @override
  String get scenariosListTitle => 'Szenarien';

  @override
  String get scenariosListSubtitle => 'Lerne durch echte Situationen';

  @override
  String scenariosLocked(Object level) {
    return 'Erreiche $level um freizuschalten';
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
  String get scenariosEmptyBody =>
      'Wir bereiten neue Szenarien mit Sorgfalt vor.';

  @override
  String get scenariosLoadFailedTitle => 'Hmm, etwas ist schiefgelaufen';

  @override
  String get statsFirstEntryTitle => 'Deine Reise beginnt';

  @override
  String get statsFirstEntryBody =>
      'Starte ein Szenario — danach füllt sich diese Seite mit deinem Fortschritt.';

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
      'Lerne wie ein Koreaner lebt — Café, Flughafen, Vorstellung…';

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
  String get scenarioStartBtn => 'Los geht\'s';

  @override
  String get scenarioNextBtn => 'Weiter';

  @override
  String get scenarioCompleteBtn => 'Abschließen';

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
    return '$count Wörter geübt';
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
  String get statsNoBadges => 'Noch keine — schließe Szenarien ab! 🚀';

  @override
  String get homeRecommended => 'Heute empfohlen ✨';

  @override
  String get homeAllDone => 'Alle Szenarien geschafft! 🎉';

  @override
  String get homeNoScenario => 'Bald gibt es Szenarien für dein Level';

  @override
  String get homeGreetingLearn => 'Lerne Koreanisch wie ein Local';

  @override
  String get homeTodaySection => 'Heute';

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
  String get dailyCharSubtitle => '1 Min nachzeichnen';

  @override
  String get dailyCharDoneToday => 'Heute geschafft ✓';

  @override
  String get dailyCharFinish => 'Fertig';

  @override
  String dailyCharStreak(int n) {
    return '$n Tage gesamt';
  }

  @override
  String get dailyCharGreatJob => 'Super!';

  @override
  String get vocabModeFavorites => 'Favoriten';

  @override
  String vocabFavoritesBadge(int n) {
    return '⭐ $n';
  }

  @override
  String get vocabHearExample => 'Beispiel hören';

  @override
  String get vocabSlowHint => 'Lang drücken: langsam';

  @override
  String get vocabEmptyFavorites =>
      'Noch keine Favoriten ⭐\nMarkiere schwierige Wörter mit dem Stern';

  @override
  String get listeningTitle => 'Hören';

  @override
  String get listeningSubtitle => 'Hör ein Szenario in echtem Tempo';

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
  String get listeningPickFirst =>
      'Wähle oben ein Szenario aus, um zu starten.';

  @override
  String get listeningEmptyTitle => 'Noch keine Szenarien';

  @override
  String get listeningEmptyBody =>
      'Sobald neue Szenarien geladen sind, kannst du sie hier anhören.';

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
  String get kkeunmariNotInPool =>
      'Kenn ich noch nicht — versuch ein anderes 🐯';

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
  String get kkeunmariDeadEnd => '한방단어 — die Kette endet hier';

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
    return 'Du hast $n Wörter verkettet.';
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
  String get shareTitle => 'Pack teilen';

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
  String get shareEmpty => 'Dieser Pack hat keine Wörter.';

  @override
  String sharePackBody(Object name, int count, Object code) {
    return 'Ich teile mit dir den Vokabel-Pack „$name“ ($count Wörter) aus Hangul Sori! Gib in der App den Code $code ein, um ihn zu importieren. hangul-sori.com';
  }

  @override
  String get redeemTooltip => 'Mit Code importieren';

  @override
  String get redeemTitle => 'Pack importieren';

  @override
  String get redeemHint => '6-stelligen Code eingeben';

  @override
  String get redeemAction => 'Importieren';

  @override
  String redeemSuccess(Object name, int count) {
    return '„$name“ importiert ($count Wörter)';
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
      'Füge dein erstes Wort hinzu — oder lass die Übersetzung automatisch ausfüllen.';

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
      'Auto-Ausfüllen gerade nicht verfügbar — bitte manuell eintragen.';

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
    return '$count Wörter importiert';
  }

  @override
  String get wbPhotoCamera => 'Kamera';

  @override
  String get wbPhotoGallery => 'Galerie';

  @override
  String get wbPhotoRemove => 'Foto entfernen';

  @override
  String get hardWordsTitle => 'Schwierige Wörter';

  @override
  String hardWordsSubtitle(int count) {
    return '$count Wörter wollen einfach nicht sitzen';
  }

  @override
  String get hardWordsEmptyTitle => 'Keine Sorgenkinder 🎉';

  @override
  String get hardWordsEmptyBody =>
      'Im Moment gibt es keine besonders schwierigen Wörter. Lern weiter — falls eins hakt, taucht es hier auf.';

  @override
  String get hardWordsStudyCta => 'Gezielt wiederholen';

  @override
  String get wbMatching => 'Paare finden';

  @override
  String get wbMatchingHint =>
      'Tippe ein koreanisches Wort, dann seine Bedeutung.';

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
    return '$count Wörter';
  }

  @override
  String get wbPosAll => 'Alle';

  @override
  String get wbSearchCta => 'Meine Wörter durchsuchen';

  @override
  String comboPop(int count) {
    return '${count}er-Combo! 🔥';
  }

  @override
  String get pathTitle => 'Lernpfad';

  @override
  String pathHanokStage(int n) {
    return 'Hanok · Stufe $n/12';
  }

  @override
  String get pathHanokSub => 'Dein Hof wächst mit jedem gemeisterten Pack.';

  @override
  String pathLevelPacks(int done, int total) {
    return '$done/$total Packs';
  }

  @override
  String get pathNodeNow => 'Jetzt';

  @override
  String get pathLockedHint => 'Schließe zuerst das vorherige Pack ab.';

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
      'Eine kurze Lektion reicht, um dranzubleiben.';

  @override
  String notifDailyStreakBody(int days) {
    return '🔥 $days Tage am Stück — heute weiter?';
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
  String get profileGuestBadge => 'Gast-Modus';

  @override
  String get profileGuestDesc =>
      'Dein Fortschritt liegt nur auf diesem Gerät. Sichere ihn mit Google, damit er einen Handywechsel übersteht.';

  @override
  String get profileConnectedBadge => 'Mit Google verbunden';

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
  String get profileSignOut => 'Abmelden';

  @override
  String get accountNudgeTitle => 'Speichere deinen Fortschritt';

  @override
  String get accountNudgeBody =>
      'Verbinde dich mit Google, damit dein Streak und deine Vokabeln einen Handywechsel überstehen.';

  @override
  String get accountNudgeConnect => 'Mit Google verbinden';

  @override
  String get accountNudgeLater => 'Später';

  @override
  String get authAppleSignIn => 'Mit Apple anmelden';

  @override
  String get consentTitle => 'Willkommen bei Hangul Sori';

  @override
  String get consentBody =>
      'Bevor du loslegst — Hangul Sori speichert deinen Lernfortschritt standardmäßig nur auf deinem Gerät. Bitte sieh kurz, wie wir mit deinen Daten umgehen.';

  @override
  String get consentPrivacyCta => 'Datenschutzerklärung lesen';

  @override
  String get consentAgreeCta => 'Zustimmen & loslegen';

  @override
  String get consentFootnote =>
      'Mit dem Fortfahren stimmst du unserer Datenschutzerklärung zu.';

  @override
  String get grammarEasy => 'Verstanden';

  @override
  String get grammarHard => 'Schwierig';
}
