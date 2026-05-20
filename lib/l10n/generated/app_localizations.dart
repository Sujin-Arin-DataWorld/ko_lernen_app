import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch lernen'**
  String get appTitle;

  /// No description provided for @welcomeMsg.
  ///
  /// In de, this message translates to:
  /// **'Hallo! Viel Erfolg heute 💪'**
  String get welcomeMsg;

  /// No description provided for @footerCheer.
  ///
  /// In de, this message translates to:
  /// **'Viel Erfolg beim Lernen 🌟'**
  String get footerCheer;

  /// No description provided for @sectionModules.
  ///
  /// In de, this message translates to:
  /// **'Lernmodule'**
  String get sectionModules;

  /// No description provided for @sectionGames.
  ///
  /// In de, this message translates to:
  /// **'Spiele'**
  String get sectionGames;

  /// No description provided for @sectionStats.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get sectionStats;

  /// No description provided for @moduleHangulTitle.
  ///
  /// In de, this message translates to:
  /// **'Hangul'**
  String get moduleHangulTitle;

  /// No description provided for @moduleHangulDesc.
  ///
  /// In de, this message translates to:
  /// **'14 Konsonanten + 10 Vokale'**
  String get moduleHangulDesc;

  /// No description provided for @moduleVocabTitle.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln'**
  String get moduleVocabTitle;

  /// No description provided for @moduleVocabDesc.
  ///
  /// In de, this message translates to:
  /// **'500+ Karten · A1 → B2 · TTS'**
  String get moduleVocabDesc;

  /// No description provided for @moduleGrammarTitle.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get moduleGrammarTitle;

  /// No description provided for @moduleGrammarDesc.
  ///
  /// In de, this message translates to:
  /// **'85+ Muster · auf Deutsch erklärt'**
  String get moduleGrammarDesc;

  /// No description provided for @moduleListenTitle.
  ///
  /// In de, this message translates to:
  /// **'Hören'**
  String get moduleListenTitle;

  /// No description provided for @moduleListenDesc.
  ///
  /// In de, this message translates to:
  /// **'Sätze hören und verstehen'**
  String get moduleListenDesc;

  /// No description provided for @gameChosungTitle.
  ///
  /// In de, this message translates to:
  /// **'Anlaut-Quiz'**
  String get gameChosungTitle;

  /// No description provided for @gameChosungDesc.
  ///
  /// In de, this message translates to:
  /// **'Errate das Wort anhand der Anfangsbuchstaben'**
  String get gameChosungDesc;

  /// No description provided for @gameWordleTitle.
  ///
  /// In de, this message translates to:
  /// **'Wordle'**
  String get gameWordleTitle;

  /// No description provided for @gameWordleDesc.
  ///
  /// In de, this message translates to:
  /// **'2–3 Silben · 6 Versuche'**
  String get gameWordleDesc;

  /// No description provided for @navVocab.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln'**
  String get navVocab;

  /// No description provided for @navGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get navGrammar;

  /// No description provided for @navListen.
  ///
  /// In de, this message translates to:
  /// **'Hören'**
  String get navListen;

  /// No description provided for @navHangul.
  ///
  /// In de, this message translates to:
  /// **'Hangul'**
  String get navHangul;

  /// No description provided for @navChosung.
  ///
  /// In de, this message translates to:
  /// **'Anlaut-Quiz'**
  String get navChosung;

  /// No description provided for @navWordle.
  ///
  /// In de, this message translates to:
  /// **'Wordle'**
  String get navWordle;

  /// No description provided for @navSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @navStats.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get navStats;

  /// No description provided for @btnHoeren.
  ///
  /// In de, this message translates to:
  /// **'Hören'**
  String get btnHoeren;

  /// No description provided for @btnSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get btnSkip;

  /// No description provided for @btnSubmit.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get btnSubmit;

  /// No description provided for @btnNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get btnNext;

  /// No description provided for @btnPrev.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get btnPrev;

  /// No description provided for @btnRandom.
  ///
  /// In de, this message translates to:
  /// **'Zufällig'**
  String get btnRandom;

  /// No description provided for @btnGewusst.
  ///
  /// In de, this message translates to:
  /// **'Gewusst!'**
  String get btnGewusst;

  /// No description provided for @btnNichtGewusst.
  ///
  /// In de, this message translates to:
  /// **'Nicht gewusst'**
  String get btnNichtGewusst;

  /// No description provided for @btnNewGame.
  ///
  /// In de, this message translates to:
  /// **'Neues Spiel'**
  String get btnNewGame;

  /// No description provided for @btnConfirm.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get btnConfirm;

  /// No description provided for @btnCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get btnCancel;

  /// No description provided for @btnRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get btnRetry;

  /// No description provided for @btnApply.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get btnApply;

  /// No description provided for @filterTitle.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterLevel.
  ///
  /// In de, this message translates to:
  /// **'Level'**
  String get filterLevel;

  /// No description provided for @filterTheme.
  ///
  /// In de, this message translates to:
  /// **'Thema'**
  String get filterTheme;

  /// No description provided for @filterType.
  ///
  /// In de, this message translates to:
  /// **'Typ'**
  String get filterType;

  /// No description provided for @filterDirection.
  ///
  /// In de, this message translates to:
  /// **'Vorderseite zeigt'**
  String get filterDirection;

  /// No description provided for @filterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// No description provided for @filterDirKoDe.
  ///
  /// In de, this message translates to:
  /// **'🇰🇷 Koreanisch → 🇩🇪 Deutsch'**
  String get filterDirKoDe;

  /// No description provided for @filterDirDeKo.
  ///
  /// In de, this message translates to:
  /// **'🇩🇪 Deutsch → 🇰🇷 Koreanisch'**
  String get filterDirDeKo;

  /// No description provided for @emptyVocab.
  ///
  /// In de, this message translates to:
  /// **'Keine Vokabeln für diesen Filter.\nPasse die Auswahl an.'**
  String get emptyVocab;

  /// No description provided for @emptyGrammar.
  ///
  /// In de, this message translates to:
  /// **'Keine Muster für diesen Filter.'**
  String get emptyGrammar;

  /// No description provided for @loadingVocab.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln laden …'**
  String get loadingVocab;

  /// No description provided for @loadingGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatik laden …'**
  String get loadingGrammar;

  /// No description provided for @hintTapToFlip.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Umdrehen'**
  String get hintTapToFlip;

  /// No description provided for @hintTapForExplanation.
  ///
  /// In de, this message translates to:
  /// **'Tippen für Erklärung'**
  String get hintTapForExplanation;

  /// No description provided for @chosungQuestion.
  ///
  /// In de, this message translates to:
  /// **'Welches Wort?'**
  String get chosungQuestion;

  /// No description provided for @chosungInputHint.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch eingeben …'**
  String get chosungInputHint;

  /// No description provided for @chosungShowHint.
  ///
  /// In de, this message translates to:
  /// **'Hören (Tipp)'**
  String get chosungShowHint;

  /// No description provided for @chosungCorrect.
  ///
  /// In de, this message translates to:
  /// **'✓ Richtig!'**
  String get chosungCorrect;

  /// No description provided for @chosungAnswer.
  ///
  /// In de, this message translates to:
  /// **'Antwort'**
  String get chosungAnswer;

  /// No description provided for @wordleHowTitle.
  ///
  /// In de, this message translates to:
  /// **'Spielanleitung'**
  String get wordleHowTitle;

  /// No description provided for @wordleHowIntro.
  ///
  /// In de, this message translates to:
  /// **'Errate das koreanische Wort in 6 Versuchen. Die Farben geben Hinweise.'**
  String get wordleHowIntro;

  /// No description provided for @wordleHowExact.
  ///
  /// In de, this message translates to:
  /// **'Richtig'**
  String get wordleHowExact;

  /// No description provided for @wordleHowExactDesc.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe an der richtigen Position'**
  String get wordleHowExactDesc;

  /// No description provided for @wordleHowWrong.
  ///
  /// In de, this message translates to:
  /// **'Falsche Position'**
  String get wordleHowWrong;

  /// No description provided for @wordleHowWrongDesc.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe ist im Wort, aber anders platziert'**
  String get wordleHowWrongDesc;

  /// No description provided for @wordleHowAbsent.
  ///
  /// In de, this message translates to:
  /// **'Nicht vorhanden'**
  String get wordleHowAbsent;

  /// No description provided for @wordleHowAbsentDesc.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe kommt im Wort nicht vor'**
  String get wordleHowAbsentDesc;

  /// No description provided for @wordleHowOutro.
  ///
  /// In de, this message translates to:
  /// **'Jeden Tag ein neues Wort.\nShuffle für ein zufälliges Wort.'**
  String get wordleHowOutro;

  /// No description provided for @wordleErrorLength.
  ///
  /// In de, this message translates to:
  /// **'Bitte {n} Silben eingeben'**
  String wordleErrorLength(int n);

  /// No description provided for @wordleErrorHangul.
  ///
  /// In de, this message translates to:
  /// **'Bitte nur Hangul eingeben'**
  String get wordleErrorHangul;

  /// No description provided for @wordleResultWin.
  ///
  /// In de, this message translates to:
  /// **'🎉 Geschafft!'**
  String get wordleResultWin;

  /// No description provided for @wordleResultLose.
  ///
  /// In de, this message translates to:
  /// **'😢 Daneben'**
  String get wordleResultLose;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In de, this message translates to:
  /// **'Systemsprache'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageDe.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get settingsLanguageDe;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsTtsRate.
  ///
  /// In de, this message translates to:
  /// **'Sprechtempo'**
  String get settingsTtsRate;

  /// No description provided for @settingsTtsRateSlow.
  ///
  /// In de, this message translates to:
  /// **'Langsam'**
  String get settingsTtsRateSlow;

  /// No description provided for @settingsTtsRateNormal.
  ///
  /// In de, this message translates to:
  /// **'Normal'**
  String get settingsTtsRateNormal;

  /// No description provided for @settingsTtsRateFast.
  ///
  /// In de, this message translates to:
  /// **'Schnell'**
  String get settingsTtsRateFast;

  /// No description provided for @settingsReset.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten zurücksetzen'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In de, this message translates to:
  /// **'Wirklich alle Lernfortschritte löschen? Das kann nicht rückgängig gemacht werden.'**
  String get settingsResetConfirm;

  /// No description provided for @settingsAbout.
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {v}'**
  String settingsVersion(Object v);

  /// No description provided for @statsHeader.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt'**
  String get statsHeader;

  /// No description provided for @statsCardsLearned.
  ///
  /// In de, this message translates to:
  /// **'Karten gelernt'**
  String get statsCardsLearned;

  /// No description provided for @statsAccuracy.
  ///
  /// In de, this message translates to:
  /// **'Genauigkeit'**
  String get statsAccuracy;

  /// No description provided for @statsStreak.
  ///
  /// In de, this message translates to:
  /// **'Streak'**
  String get statsStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In de, this message translates to:
  /// **'Bester Streak'**
  String get statsBestStreak;

  /// No description provided for @statsWordleWins.
  ///
  /// In de, this message translates to:
  /// **'Wordle Siege'**
  String get statsWordleWins;

  /// No description provided for @statsWordleStreak.
  ///
  /// In de, this message translates to:
  /// **'Wordle Streak'**
  String get statsWordleStreak;

  /// No description provided for @screenVocabTitle.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln'**
  String get screenVocabTitle;

  /// No description provided for @screenGrammarTitle.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get screenGrammarTitle;

  /// No description provided for @screenWordleTitle.
  ///
  /// In de, this message translates to:
  /// **'Wordle'**
  String get screenWordleTitle;

  /// No description provided for @screenHangulTitle.
  ///
  /// In de, this message translates to:
  /// **'Hangul'**
  String get screenHangulTitle;

  /// No description provided for @filterOpenBtn.
  ///
  /// In de, this message translates to:
  /// **'Filter öffnen'**
  String get filterOpenBtn;

  /// No description provided for @hangulTabOverview.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get hangulTabOverview;

  /// No description provided for @hangulTabCards.
  ///
  /// In de, this message translates to:
  /// **'Karten'**
  String get hangulTabCards;

  /// No description provided for @hangulTabWrite.
  ///
  /// In de, this message translates to:
  /// **'Schreiben'**
  String get hangulTabWrite;

  /// No description provided for @hangulConsonantsLabel.
  ///
  /// In de, this message translates to:
  /// **'자음 · Konsonanten'**
  String get hangulConsonantsLabel;

  /// No description provided for @hangulVowelsLabel.
  ///
  /// In de, this message translates to:
  /// **'모음 · Vokale'**
  String get hangulVowelsLabel;

  /// No description provided for @hangulSyllableLabel.
  ///
  /// In de, this message translates to:
  /// **'🧩 음절 구조 · Silbenaufbau'**
  String get hangulSyllableLabel;

  /// No description provided for @hangulPronounceBtn.
  ///
  /// In de, this message translates to:
  /// **'Aussprechen'**
  String get hangulPronounceBtn;

  /// No description provided for @hangulRulesTitle.
  ///
  /// In de, this message translates to:
  /// **'✏️ Hangul-Schreibregeln'**
  String get hangulRulesTitle;

  /// No description provided for @hangulRulesBody.
  ///
  /// In de, this message translates to:
  /// **'① Oben → Unten   ② Horizontal → Vertikal   ③ Links → Rechts'**
  String get hangulRulesBody;

  /// No description provided for @hangulStrokeOrderTitle.
  ///
  /// In de, this message translates to:
  /// **'📽 Strichreihenfolge (tippe für neu)'**
  String get hangulStrokeOrderTitle;

  /// No description provided for @hangulTraceTitle.
  ///
  /// In de, this message translates to:
  /// **'✍️ mit dem Finger nachzeichnen'**
  String get hangulTraceTitle;

  /// No description provided for @hangulClearBtn.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get hangulClearBtn;

  /// No description provided for @hangulPronounceLetter.
  ///
  /// In de, this message translates to:
  /// **'{letter} aussprechen'**
  String hangulPronounceLetter(Object letter);

  /// No description provided for @wordleSyllableCount.
  ///
  /// In de, this message translates to:
  /// **'{n}-Silben-Wort · 6 Versuche'**
  String wordleSyllableCount(int n);

  /// No description provided for @wordleMeaning.
  ///
  /// In de, this message translates to:
  /// **'Bedeutung: {german}'**
  String wordleMeaning(Object german);

  /// No description provided for @wordleAnswerLabel.
  ///
  /// In de, this message translates to:
  /// **'Antwort: {target}'**
  String wordleAnswerLabel(Object target);

  /// No description provided for @wordleInputHint.
  ///
  /// In de, this message translates to:
  /// **'{n} Silben eingeben…'**
  String wordleInputHint(int n);

  /// No description provided for @wordleLegendCorrect.
  ///
  /// In de, this message translates to:
  /// **'Richtige Stelle'**
  String get wordleLegendCorrect;

  /// No description provided for @wordleLegendPresent.
  ///
  /// In de, this message translates to:
  /// **'Falsche Stelle'**
  String get wordleLegendPresent;

  /// No description provided for @wordleLegendAbsent.
  ///
  /// In de, this message translates to:
  /// **'Nicht da'**
  String get wordleLegendAbsent;

  /// No description provided for @wordleSubmitBtn.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get wordleSubmitBtn;

  /// No description provided for @wordleNewWordBtn.
  ///
  /// In de, this message translates to:
  /// **'Neues Wort'**
  String get wordleNewWordBtn;

  /// No description provided for @wordleHelpTooltip.
  ///
  /// In de, this message translates to:
  /// **'Spielanleitung'**
  String get wordleHelpTooltip;

  /// No description provided for @wordleShuffleTooltip.
  ///
  /// In de, this message translates to:
  /// **'Neues Wort'**
  String get wordleShuffleTooltip;

  /// No description provided for @settingsAdsSection.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get settingsAdsSection;

  /// No description provided for @settingsShowAds.
  ///
  /// In de, this message translates to:
  /// **'Werbung anzeigen'**
  String get settingsShowAds;

  /// No description provided for @settingsShowAdsDesc.
  ///
  /// In de, this message translates to:
  /// **'Hilft beim Erhalten der App'**
  String get settingsShowAdsDesc;

  /// No description provided for @placeholderComingSoon.
  ///
  /// In de, this message translates to:
  /// **'Bald verfügbar 🚧'**
  String get placeholderComingSoon;

  /// No description provided for @chosungSubmitBtn.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get chosungSubmitBtn;

  /// No description provided for @chosungHintBtn.
  ///
  /// In de, this message translates to:
  /// **'Hinweis'**
  String get chosungHintBtn;

  /// No description provided for @chosungAnswerLabel.
  ///
  /// In de, this message translates to:
  /// **'Antwort: {word}'**
  String chosungAnswerLabel(Object word);

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statsTitle;

  /// No description provided for @statsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernfortschritt'**
  String get statsSubtitle;

  /// No description provided for @statsDays.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get statsDays;

  /// No description provided for @statsCards.
  ///
  /// In de, this message translates to:
  /// **'Karten'**
  String get statsCards;

  /// No description provided for @statsPercent.
  ///
  /// In de, this message translates to:
  /// **'Genauigkeit'**
  String get statsPercent;

  /// No description provided for @statsWins.
  ///
  /// In de, this message translates to:
  /// **'Siege'**
  String get statsWins;

  /// No description provided for @statsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten — leg los! 🚀'**
  String get statsEmpty;

  /// No description provided for @statsVokSection.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln'**
  String get statsVokSection;

  /// No description provided for @statsGamesSection.
  ///
  /// In de, this message translates to:
  /// **'Spiele'**
  String get statsGamesSection;

  /// No description provided for @statsStreakSection.
  ///
  /// In de, this message translates to:
  /// **'Streak'**
  String get statsStreakSection;

  /// No description provided for @statsBestLabel.
  ///
  /// In de, this message translates to:
  /// **'Bester: {n}'**
  String statsBestLabel(int n);

  /// No description provided for @vocabModeAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get vocabModeAll;

  /// No description provided for @vocabModeDue.
  ///
  /// In de, this message translates to:
  /// **'Heute fällig'**
  String get vocabModeDue;

  /// No description provided for @vocabDueBadge.
  ///
  /// In de, this message translates to:
  /// **'🔥 {n} fällig'**
  String vocabDueBadge(int n);

  /// No description provided for @vocabDueEmpty.
  ///
  /// In de, this message translates to:
  /// **'🎉 Heute alles erledigt!\nKomm morgen wieder.'**
  String get vocabDueEmpty;

  /// No description provided for @vocabDueEmptyAction.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem üben'**
  String get vocabDueEmptyAction;

  /// No description provided for @moduleStatsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get moduleStatsTitle;

  /// No description provided for @moduleStatsDesc.
  ///
  /// In de, this message translates to:
  /// **'Streak, Karten, Genauigkeit'**
  String get moduleStatsDesc;

  /// No description provided for @settingsCloudSection.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Backup'**
  String get settingsCloudSection;

  /// No description provided for @settingsCloudSignedIn.
  ///
  /// In de, this message translates to:
  /// **'Eingeloggt: {name}'**
  String settingsCloudSignedIn(Object name);

  /// No description provided for @settingsCloudSignInPrompt.
  ///
  /// In de, this message translates to:
  /// **'Mit Google sichern'**
  String get settingsCloudSignInPrompt;

  /// No description provided for @settingsCloudSignedInDesc.
  ///
  /// In de, this message translates to:
  /// **'Daten werden in der Cloud gesichert'**
  String get settingsCloudSignedInDesc;

  /// No description provided for @settingsCloudSignInDesc.
  ///
  /// In de, this message translates to:
  /// **'Damit überlebt dein Fortschritt einen Handywechsel'**
  String get settingsCloudSignInDesc;

  /// No description provided for @settingsCloudBackupNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt sichern'**
  String get settingsCloudBackupNow;

  /// No description provided for @settingsCloudRestore.
  ///
  /// In de, this message translates to:
  /// **'Von Cloud wiederherstellen'**
  String get settingsCloudRestore;

  /// No description provided for @settingsCloudBackupSuccess.
  ///
  /// In de, this message translates to:
  /// **'Backup erfolgreich ✓'**
  String get settingsCloudBackupSuccess;

  /// No description provided for @settingsCloudRestoreSuccess.
  ///
  /// In de, this message translates to:
  /// **'Wiederhergestellt ✓'**
  String get settingsCloudRestoreSuccess;

  /// No description provided for @settingsCloudRestoreEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Cloud-Daten'**
  String get settingsCloudRestoreEmpty;

  /// No description provided for @settingsCloudAuthFailed.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung fehlgeschlagen: {error}'**
  String settingsCloudAuthFailed(Object error);

  /// No description provided for @statsGotIt.
  ///
  /// In de, this message translates to:
  /// **'Gewusst'**
  String get statsGotIt;

  /// No description provided for @statsNotGotIt.
  ///
  /// In de, this message translates to:
  /// **'Nicht gewusst'**
  String get statsNotGotIt;

  /// No description provided for @statsSkipped.
  ///
  /// In de, this message translates to:
  /// **'Übersprungen'**
  String get statsSkipped;

  /// No description provided for @statsCorrect.
  ///
  /// In de, this message translates to:
  /// **'Richtig'**
  String get statsCorrect;

  /// No description provided for @statsWrong.
  ///
  /// In de, this message translates to:
  /// **'Falsch'**
  String get statsWrong;

  /// No description provided for @statsLosses.
  ///
  /// In de, this message translates to:
  /// **'Verloren'**
  String get statsLosses;

  /// No description provided for @statsBestShort.
  ///
  /// In de, this message translates to:
  /// **'Beste'**
  String get statsBestShort;

  /// No description provided for @statsWinRate.
  ///
  /// In de, this message translates to:
  /// **'Quote'**
  String get statsWinRate;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppL10nDe();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
