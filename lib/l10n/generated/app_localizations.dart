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

  /// No description provided for @paywallTitle.
  ///
  /// In de, this message translates to:
  /// **'Hangul Sori Premium'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch lernen, wann du willst.'**
  String get paywallSubtitle;

  /// No description provided for @paywallBenefit1.
  ///
  /// In de, this message translates to:
  /// **'Alle Vokabel-Pakete (A2 · B1 · B2)'**
  String get paywallBenefit1;

  /// No description provided for @paywallBenefit2.
  ///
  /// In de, this message translates to:
  /// **'Alle Gesprächs-Szenarien'**
  String get paywallBenefit2;

  /// No description provided for @paywallBenefit3.
  ///
  /// In de, this message translates to:
  /// **'Unbegrenzte Wiederholungen (SRS)'**
  String get paywallBenefit3;

  /// No description provided for @paywallBenefit4.
  ///
  /// In de, this message translates to:
  /// **'Dein persönlicher KI-Kurs mit neuen Inhalten jeden Tag'**
  String get paywallBenefit4;

  /// No description provided for @paywallBenefit5.
  ///
  /// In de, this message translates to:
  /// **'Buchschnappschuss ohne Tageslimit'**
  String get paywallBenefit5;

  /// No description provided for @paywallPriceFallback.
  ///
  /// In de, this message translates to:
  /// **'5 € / Monat'**
  String get paywallPriceFallback;

  /// No description provided for @paywallPricePerMonth.
  ///
  /// In de, this message translates to:
  /// **'/ Monat'**
  String get paywallPricePerMonth;

  /// No description provided for @paywallCtaStart.
  ///
  /// In de, this message translates to:
  /// **'Premium freischalten'**
  String get paywallCtaStart;

  /// No description provided for @paywallCtaRestore.
  ///
  /// In de, this message translates to:
  /// **'Käufe wiederherstellen'**
  String get paywallCtaRestore;

  /// No description provided for @paywallClose.
  ///
  /// In de, this message translates to:
  /// **'Vielleicht später'**
  String get paywallClose;

  /// No description provided for @paywallLegal.
  ///
  /// In de, this message translates to:
  /// **'Jederzeit kündbar. Das Abo verlängert sich automatisch, bis du kündigst.'**
  String get paywallLegal;

  /// No description provided for @paywallNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Abos sind in dieser Version noch nicht verfügbar.'**
  String get paywallNotAvailable;

  /// No description provided for @paywallProcessing.
  ///
  /// In de, this message translates to:
  /// **'Einen Moment …'**
  String get paywallProcessing;

  /// No description provided for @paywallSuccess.
  ///
  /// In de, this message translates to:
  /// **'Premium ist aktiv. Viel Spaß!'**
  String get paywallSuccess;

  /// No description provided for @paywallFailed.
  ///
  /// In de, this message translates to:
  /// **'Kauf nicht abgeschlossen.'**
  String get paywallFailed;

  /// No description provided for @paywallRestoreNone.
  ///
  /// In de, this message translates to:
  /// **'Keine früheren Käufe gefunden.'**
  String get paywallRestoreNone;

  /// No description provided for @streakDisplay.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, one{1 Tag} other{{days} Tage}}'**
  String streakDisplay(int days);

  /// No description provided for @streakDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Deinen Streak halten'**
  String get streakDialogTitle;

  /// No description provided for @streakDialogSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Lern jeden Tag. So wächst dein Streak.'**
  String get streakDialogSubtitle;

  /// No description provided for @streakDialogEarned.
  ///
  /// In de, this message translates to:
  /// **'Dranbleiben lohnt sich'**
  String get streakDialogEarned;

  /// No description provided for @streakDialogCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Streak: {days, plural, one{1 Tag} other{{days} Tage}}'**
  String streakDialogCurrent(int days);

  /// No description provided for @streakDialogLastActivity.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt aktiv: {time}'**
  String streakDialogLastActivity(Object time);

  /// No description provided for @streakDialogLearnNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt lernen'**
  String get streakDialogLearnNow;

  /// No description provided for @characterSelectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer ist dein Lernfreund?'**
  String get characterSelectionTitle;

  /// No description provided for @homeMagpieBubbleStart.
  ///
  /// In de, this message translates to:
  /// **'Wir fangen ganz in Ruhe an, Zeichen für Zeichen.'**
  String get homeMagpieBubbleStart;

  /// No description provided for @homeMagpieBubbleResume.
  ///
  /// In de, this message translates to:
  /// **'Schön, dich zu sehen. Sollen wir kurz wiederholen?'**
  String get homeMagpieBubbleResume;

  /// No description provided for @homeLearnNowCtaMagpie.
  ///
  /// In de, this message translates to:
  /// **'In Ruhe weiter'**
  String get homeLearnNowCtaMagpie;

  /// No description provided for @homeFirstWeekTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine erste Woche'**
  String get homeFirstWeekTitle;

  /// No description provided for @characterNameTiger.
  ///
  /// In de, this message translates to:
  /// **'태고'**
  String get characterNameTiger;

  /// No description provided for @characterRomanTiger.
  ///
  /// In de, this message translates to:
  /// **'Taego'**
  String get characterRomanTiger;

  /// No description provided for @characterTraitTiger.
  ///
  /// In de, this message translates to:
  /// **'Verlässlich & mutig'**
  String get characterTraitTiger;

  /// No description provided for @characterDescTiger.
  ///
  /// In de, this message translates to:
  /// **'In der koreanischen Volkskunst ist der Tiger der Herr der Berge. Taego steht für ruhige, uralte Kraft. Er begleitet dich Schritt für Schritt und macht dir Mut, wenn es schwer wird.'**
  String get characterDescTiger;

  /// No description provided for @characterNameMagpie.
  ///
  /// In de, this message translates to:
  /// **'조이'**
  String get characterNameMagpie;

  /// No description provided for @characterRomanMagpie.
  ///
  /// In de, this message translates to:
  /// **'Joy'**
  String get characterRomanMagpie;

  /// No description provided for @characterTraitMagpie.
  ///
  /// In de, this message translates to:
  /// **'Fröhlich & lebendig'**
  String get characterTraitMagpie;

  /// No description provided for @characterDescMagpie.
  ///
  /// In de, this message translates to:
  /// **'In Korea gilt die Elster als Glücksbotin, die gute Nachrichten bringt. Joy feiert jeden Erfolg mit dir und bringt gute Laune in jede Lektion.'**
  String get characterDescMagpie;

  /// No description provided for @characterSelectedTiger.
  ///
  /// In de, this message translates to:
  /// **'태고가 선택되었습니다.'**
  String get characterSelectedTiger;

  /// No description provided for @characterSelectedMagpie.
  ///
  /// In de, this message translates to:
  /// **'조이가 선택되었습니다.'**
  String get characterSelectedMagpie;

  /// No description provided for @characterSelectionHint.
  ///
  /// In de, this message translates to:
  /// **'Tipp deinen Lernfreund an'**
  String get characterSelectionHint;

  /// No description provided for @reviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute wiederholen'**
  String get reviewTitle;

  /// No description provided for @reviewEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles erledigt!'**
  String get reviewEmptyTitle;

  /// No description provided for @reviewEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für heute sind keine Karten fällig. Spiel eine Runde oder lern ein neues Paket. Die Wörter kommen später zur Wiederholung wieder.'**
  String get reviewEmptyBody;

  /// No description provided for @reviewDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Stark!'**
  String get reviewDoneTitle;

  /// No description provided for @reviewDoneBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast deine fälligen Karten wiederholt.'**
  String get reviewDoneBody;

  /// No description provided for @reviewBonusLabel.
  ///
  /// In de, this message translates to:
  /// **'Satz des Tages'**
  String get reviewBonusLabel;

  /// No description provided for @homeReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute wiederholen'**
  String get homeReviewTitle;

  /// No description provided for @homeReviewDue.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort fällig} other{{n} Wörter fällig}}'**
  String homeReviewDue(int n);

  /// No description provided for @homeReviewDone.
  ///
  /// In de, this message translates to:
  /// **'Heute alles wiederholt'**
  String get homeReviewDone;

  /// No description provided for @settingsNotifSection.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung'**
  String get settingsNotifSection;

  /// No description provided for @settingsNotifTitle.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get settingsNotifTitle;

  /// No description provided for @settingsNotifSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Taego erinnert dich ans Lernen'**
  String get settingsNotifSubtitle;

  /// No description provided for @settingsNotifTime.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit'**
  String get settingsNotifTime;

  /// No description provided for @settingsNotifDenied.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen sind deaktiviert. Erlaube sie in den Systemeinstellungen.'**
  String get settingsNotifDenied;

  /// No description provided for @notificationTitle.
  ///
  /// In de, this message translates to:
  /// **'Hangul Sori'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In de, this message translates to:
  /// **'Taego wartet schon. Zeit für Koreanisch! 🐯'**
  String get notificationBody;

  /// No description provided for @homeCourseTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Tageskurs'**
  String get homeCourseTitle;

  /// No description provided for @homeCourseDesc.
  ///
  /// In de, this message translates to:
  /// **'Auf deine Schwächen & Interessen zugeschnitten'**
  String get homeCourseDesc;

  /// No description provided for @settingsInterestsTitle.
  ///
  /// In de, this message translates to:
  /// **'Interessen'**
  String get settingsInterestsTitle;

  /// No description provided for @settingsInterestsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Themen für deinen Tageskurs'**
  String get settingsInterestsSubtitle;

  /// No description provided for @interestsSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Was interessiert dich?'**
  String get interestsSheetTitle;

  /// No description provided for @interestEveryday.
  ///
  /// In de, this message translates to:
  /// **'Alltag'**
  String get interestEveryday;

  /// No description provided for @interestFoodShopping.
  ///
  /// In de, this message translates to:
  /// **'Essen & Einkaufen'**
  String get interestFoodShopping;

  /// No description provided for @interestWorkStudy.
  ///
  /// In de, this message translates to:
  /// **'Beruf & Bildung'**
  String get interestWorkStudy;

  /// No description provided for @interestTravel.
  ///
  /// In de, this message translates to:
  /// **'Reisen & Verkehr'**
  String get interestTravel;

  /// No description provided for @interestFeelingsPeople.
  ///
  /// In de, this message translates to:
  /// **'Gefühle & Menschen'**
  String get interestFeelingsPeople;

  /// No description provided for @interestHealthBody.
  ///
  /// In de, this message translates to:
  /// **'Gesundheit & Körper'**
  String get interestHealthBody;

  /// No description provided for @smalltalkTitle.
  ///
  /// In de, this message translates to:
  /// **'Small Talk'**
  String get smalltalkTitle;

  /// No description provided for @smalltalkEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Sätze für diese Auswahl.'**
  String get smalltalkEmpty;

  /// No description provided for @smalltalkReply.
  ///
  /// In de, this message translates to:
  /// **'Beispielantwort'**
  String get smalltalkReply;

  /// No description provided for @smalltalkPickCategory.
  ///
  /// In de, this message translates to:
  /// **'Thema wählen'**
  String get smalltalkPickCategory;

  /// No description provided for @homeSmalltalkCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Small Talk'**
  String get homeSmalltalkCardTitle;

  /// No description provided for @homeSmalltalkCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Gesprächseinstiege nach Thema'**
  String get homeSmalltalkCardDesc;

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch lernen'**
  String get appTitle;

  /// No description provided for @welcomeMsg.
  ///
  /// In de, this message translates to:
  /// **'Hallo! Du schaffst das heute 💪'**
  String get welcomeMsg;

  /// No description provided for @footerCheer.
  ///
  /// In de, this message translates to:
  /// **'Bleib dran, läuft super! 🌟'**
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
  /// **'Silben-Rätsel'**
  String get gameWordleTitle;

  /// No description provided for @gameWordleDesc.
  ///
  /// In de, this message translates to:
  /// **'2-3 Silben · 6 Versuche'**
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
  /// **'Silben-Rätsel'**
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

  /// No description provided for @btnClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get btnClose;

  /// No description provided for @btnApply.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get btnApply;

  /// No description provided for @btnPlay.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get btnPlay;

  /// No description provided for @btnDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get btnDelete;

  /// No description provided for @bookshelfTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Bücherregal'**
  String get bookshelfTitle;

  /// No description provided for @bookshelfAddPage.
  ///
  /// In de, this message translates to:
  /// **'Seite hinzufügen'**
  String get bookshelfAddPage;

  /// No description provided for @bookshelfEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Seite'**
  String get bookshelfEmptyTitle;

  /// No description provided for @bookshelfEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere deine erste Lehrbuchseite. Erkannte Wörter erscheinen dann hier.'**
  String get bookshelfEmptyBody;

  /// No description provided for @bookshelfEmptyCta.
  ///
  /// In de, this message translates to:
  /// **'Seite einlesen'**
  String get bookshelfEmptyCta;

  /// No description provided for @bookshelfSectionPages.
  ///
  /// In de, this message translates to:
  /// **'Seiten'**
  String get bookshelfSectionPages;

  /// No description provided for @bookshelfSectionCustomPacks.
  ///
  /// In de, this message translates to:
  /// **'Eigene Pakete'**
  String get bookshelfSectionCustomPacks;

  /// No description provided for @bookshelfTileMeta.
  ///
  /// In de, this message translates to:
  /// **'{words, plural, one{1 Wort} other{{words} Wörter}} · {grammar} Grammatik · {date}'**
  String bookshelfTileMeta(int words, int grammar, String date);

  /// No description provided for @bookshelfPackMeta.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort} other{{n} Wörter}}'**
  String bookshelfPackMeta(int n);

  /// No description provided for @bookshelfPageTitle.
  ///
  /// In de, this message translates to:
  /// **'Seite'**
  String get bookshelfPageTitle;

  /// No description provided for @bookshelfPageNotFoundTitle.
  ///
  /// In de, this message translates to:
  /// **'Seite nicht gefunden'**
  String get bookshelfPageNotFoundTitle;

  /// No description provided for @bookshelfPageNotFoundBody.
  ///
  /// In de, this message translates to:
  /// **'Möglicherweise wurde sie gelöscht.'**
  String get bookshelfPageNotFoundBody;

  /// No description provided for @bookshelfCreatePackCta.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Paket aus dieser Seite'**
  String get bookshelfCreatePackCta;

  /// No description provided for @bookshelfCreatePackTitle.
  ///
  /// In de, this message translates to:
  /// **'Neues eigenes Paket'**
  String get bookshelfCreatePackTitle;

  /// No description provided for @bookshelfCreatePackName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get bookshelfCreatePackName;

  /// No description provided for @bookshelfCreatePackSaved.
  ///
  /// In de, this message translates to:
  /// **'Paket gespeichert.'**
  String get bookshelfCreatePackSaved;

  /// No description provided for @bookshelfDeletePageTitle.
  ///
  /// In de, this message translates to:
  /// **'Seite löschen?'**
  String get bookshelfDeletePageTitle;

  /// No description provided for @bookshelfDeletePageBody.
  ///
  /// In de, this message translates to:
  /// **'Die Seite wird endgültig entfernt.'**
  String get bookshelfDeletePageBody;

  /// No description provided for @bookshelfDeletePackTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket löschen?'**
  String get bookshelfDeletePackTitle;

  /// No description provided for @bookshelfDeletePackBody.
  ///
  /// In de, this message translates to:
  /// **'Soll \"{name}\" gelöscht werden?'**
  String bookshelfDeletePackBody(Object name);

  /// No description provided for @customPackPlayTitle.
  ///
  /// In de, this message translates to:
  /// **'Eigenes Paket üben'**
  String get customPackPlayTitle;

  /// No description provided for @customPackNotFoundTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket nicht gefunden'**
  String get customPackNotFoundTitle;

  /// No description provided for @customPackNotFoundBody.
  ///
  /// In de, this message translates to:
  /// **'Möglicherweise wurde es gelöscht.'**
  String get customPackNotFoundBody;

  /// No description provided for @customPackEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket ist leer'**
  String get customPackEmptyTitle;

  /// No description provided for @customPackEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Paket enthält noch keine Wörter.'**
  String get customPackEmptyBody;

  /// No description provided for @customPackResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get customPackResultTitle;

  /// No description provided for @customPackResultDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Karten durchgegangen!'**
  String get customPackResultDone;

  /// No description provided for @customPackResultStats.
  ///
  /// In de, this message translates to:
  /// **'{learned} von {total} als gewusst markiert'**
  String customPackResultStats(int learned, int total);

  /// No description provided for @customPackResultAgain.
  ///
  /// In de, this message translates to:
  /// **'Nochmal durchgehen'**
  String get customPackResultAgain;

  /// No description provided for @customPackResultBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Bücherregal'**
  String get customPackResultBack;

  /// No description provided for @homeBookCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Buchseite'**
  String get homeBookCardTitle;

  /// No description provided for @homeBookCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Foto machen → Wörter & Grammatik'**
  String get homeBookCardDesc;

  /// No description provided for @homeBookshelfCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Bücherregal'**
  String get homeBookshelfCardTitle;

  /// No description provided for @homeBookshelfCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Seiten & Eigene Pakete'**
  String get homeBookshelfCardDesc;

  /// No description provided for @homeQuestsCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Quests'**
  String get homeQuestsCardTitle;

  /// No description provided for @homeQuestsCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Schalte mehr Hanok-Dekoration frei'**
  String get homeQuestsCardDesc;

  /// No description provided for @settingsBookEndpointSection.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Analyse-Endpoint'**
  String get settingsBookEndpointSection;

  /// No description provided for @settingsBookEndpointHint.
  ///
  /// In de, this message translates to:
  /// **'URL der Cloud Function (DeepL + OKT). Leer = nur Offline-Grammatik.'**
  String get settingsBookEndpointHint;

  /// No description provided for @settingsBookEndpointSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get settingsBookEndpointSave;

  /// No description provided for @settingsBookEndpointSaved.
  ///
  /// In de, this message translates to:
  /// **'Endpoint gespeichert.'**
  String get settingsBookEndpointSaved;

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
  /// **'Geschafft!'**
  String get wordleResultWin;

  /// No description provided for @wordleResultLose.
  ///
  /// In de, this message translates to:
  /// **'😢 Leider daneben'**
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

  /// No description provided for @settingsSoundSection.
  ///
  /// In de, this message translates to:
  /// **'Ton'**
  String get settingsSoundSection;

  /// No description provided for @settingsSoundMaster.
  ///
  /// In de, this message translates to:
  /// **'Ton'**
  String get settingsSoundMaster;

  /// No description provided for @settingsSoundMasterDesc.
  ///
  /// In de, this message translates to:
  /// **'Schaltet alle Töne der App ein oder aus'**
  String get settingsSoundMasterDesc;

  /// No description provided for @settingsSoundMasterVolume.
  ///
  /// In de, this message translates to:
  /// **'Gesamtlautstärke'**
  String get settingsSoundMasterVolume;

  /// No description provided for @settingsSoundGame.
  ///
  /// In de, this message translates to:
  /// **'Spiel-Feedback'**
  String get settingsSoundGame;

  /// No description provided for @settingsSoundGameDesc.
  ///
  /// In de, this message translates to:
  /// **'Richtig, falsch, Combo, Level-up'**
  String get settingsSoundGameDesc;

  /// No description provided for @settingsSoundCompanion.
  ///
  /// In de, this message translates to:
  /// **'Lernfreunde'**
  String get settingsSoundCompanion;

  /// No description provided for @settingsSoundCompanionDesc.
  ///
  /// In de, this message translates to:
  /// **'Tiger und Elster: Begrüßung und Jubel'**
  String get settingsSoundCompanionDesc;

  /// No description provided for @settingsSoundAmbience.
  ///
  /// In de, this message translates to:
  /// **'Hintergrundklänge'**
  String get settingsSoundAmbience;

  /// No description provided for @settingsSoundAmbienceDesc.
  ///
  /// In de, this message translates to:
  /// **'Leise Hanok-Atmosphäre auf manchen Bildschirmen'**
  String get settingsSoundAmbienceDesc;

  /// No description provided for @settingsSoundCinematic.
  ///
  /// In de, this message translates to:
  /// **'Intro beim Start'**
  String get settingsSoundCinematic;

  /// No description provided for @settingsSoundCinematicDesc.
  ///
  /// In de, this message translates to:
  /// **'Der Klang des Hoftors beim Öffnen der App'**
  String get settingsSoundCinematicDesc;

  /// No description provided for @settingsSoundSpeech.
  ///
  /// In de, this message translates to:
  /// **'Koreanische Aussprache'**
  String get settingsSoundSpeech;

  /// No description provided for @settingsSoundSpeechDesc.
  ///
  /// In de, this message translates to:
  /// **'Vorlesen der koreanischen Wörter'**
  String get settingsSoundSpeechDesc;

  /// No description provided for @settingsSoundSpeechWarn.
  ///
  /// In de, this message translates to:
  /// **'Ohne diesen Ton hörst du keine Aussprache'**
  String get settingsSoundSpeechWarn;

  /// No description provided for @settingsSoundDuck.
  ///
  /// In de, this message translates to:
  /// **'Bei Aussprache leiser'**
  String get settingsSoundDuck;

  /// No description provided for @settingsSoundDuckDesc.
  ///
  /// In de, this message translates to:
  /// **'Hintergrundklänge werden leiser, während Koreanisch vorgelesen wird'**
  String get settingsSoundDuckDesc;

  /// No description provided for @settingsSoundRespectSilent.
  ///
  /// In de, this message translates to:
  /// **'Stumm-Schalter beachten'**
  String get settingsSoundRespectSilent;

  /// No description provided for @settingsSoundRespectSilentDesc.
  ///
  /// In de, this message translates to:
  /// **'Kein Ton, wenn das Gerät stumm geschaltet ist'**
  String get settingsSoundRespectSilentDesc;

  /// No description provided for @settingsReset.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten zurücksetzen'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In de, this message translates to:
  /// **'Wirklich alle Lernfortschritte löschen? Das lässt sich nicht rückgängig machen.'**
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

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsPrivacyCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert: {url}'**
  String settingsPrivacyCopied(Object url);

  /// No description provided for @settingsPrivacySection.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsPrivacySection;

  /// No description provided for @settingsAnalyticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsstatistiken'**
  String get settingsAnalyticsTitle;

  /// No description provided for @settingsAnalyticsDesc.
  ///
  /// In de, this message translates to:
  /// **'Anonyme App-Nutzung teilen (Firebase Analytics)'**
  String get settingsAnalyticsDesc;

  /// No description provided for @settingsCrashTitle.
  ///
  /// In de, this message translates to:
  /// **'Absturzberichte'**
  String get settingsCrashTitle;

  /// No description provided for @settingsCrashDesc.
  ///
  /// In de, this message translates to:
  /// **'Hilft uns, Fehler schneller zu beheben (Crashlytics)'**
  String get settingsCrashDesc;

  /// No description provided for @settingsTermsTitle.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get settingsTermsTitle;

  /// No description provided for @settingsImpressumTitle.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get settingsImpressumTitle;

  /// No description provided for @settingsLicensesTitle.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get settingsLicensesTitle;

  /// No description provided for @settingsLicensesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Verwendete Bibliotheken'**
  String get settingsLicensesSubtitle;

  /// No description provided for @settingsDataSourcesTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenquellen'**
  String get settingsDataSourcesTitle;

  /// No description provided for @settingsDataSourcesSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wörterbücher, Frequenzlisten, Übersetzungen'**
  String get settingsDataSourcesSubtitle;

  /// No description provided for @settingsDataSourcesIntro.
  ///
  /// In de, this message translates to:
  /// **'Die Inhalte dieser App bauen auf öffentlich zugänglichen Sprachdaten auf. Jede Quelle ist hier mit Lizenz und Attribution genannt.'**
  String get settingsDataSourcesIntro;

  /// No description provided for @settingsDataLicenseNote.
  ///
  /// In de, this message translates to:
  /// **'CC BY-SA 2.0 KR Hinweis'**
  String get settingsDataLicenseNote;

  /// No description provided for @settingsDataLicenseBody.
  ///
  /// In de, this message translates to:
  /// **'Korea-Wörterbuchdaten (Definitionen, Übersetzungen) stammen aus 우리말샘 (National Institute of Korean Language) und stehen unter CC BY-SA 2.0 KR. Abgeleitete Inhalte (z. B. die in dieser App enthaltenen JSON-Dateien) werden unter derselben Lizenz weitergegeben.'**
  String get settingsDataLicenseBody;

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

  /// No description provided for @statsStreakShield.
  ///
  /// In de, this message translates to:
  /// **'Streak-Schutz'**
  String get statsStreakShield;

  /// No description provided for @statsStreakShieldHint.
  ///
  /// In de, this message translates to:
  /// **'Schützt einen verpassten Tag.'**
  String get statsStreakShieldHint;

  /// No description provided for @statsWordleWins.
  ///
  /// In de, this message translates to:
  /// **'Silben-Rätsel-Siege'**
  String get statsWordleWins;

  /// No description provided for @statsWordleStreak.
  ///
  /// In de, this message translates to:
  /// **'Silben-Rätsel-Streak'**
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
  /// **'Silben-Rätsel'**
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
  /// **'Hangul-Schreibregeln'**
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
  /// **'Mit dem Finger nachzeichnen'**
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
  /// **'{n} Silben eingeben …'**
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
  /// **'Nicht enthalten'**
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

  /// No description provided for @chosungRoundDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Runde abgeschlossen!'**
  String get chosungRoundDoneTitle;

  /// No description provided for @chosungRoundAccuracy.
  ///
  /// In de, this message translates to:
  /// **'{percent}% richtig'**
  String chosungRoundAccuracy(int percent);

  /// No description provided for @chosungRoundAvgTime.
  ///
  /// In de, this message translates to:
  /// **'Ø {seconds}s pro Frage'**
  String chosungRoundAvgTime(Object seconds);

  /// No description provided for @chosungRoundContinue.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get chosungRoundContinue;

  /// No description provided for @chosungRoundLevelUp.
  ///
  /// In de, this message translates to:
  /// **'Stark! Probier Stufe {level} aus.'**
  String chosungRoundLevelUp(Object level);

  /// No description provided for @chosungRoundKeepLevel.
  ///
  /// In de, this message translates to:
  /// **'Gut gemacht. Bleib noch bei Stufe {level}.'**
  String chosungRoundKeepLevel(Object level);

  /// No description provided for @chosungRoundReview.
  ///
  /// In de, this message translates to:
  /// **'Kein Problem. Üb Stufe {level} noch einmal.'**
  String chosungRoundReview(Object level);

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

  /// No description provided for @statsThisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get statsThisWeek;

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
  /// **'Noch keine Daten. Starte mit deiner ersten Übung. 🚀'**
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
  /// **'{n} fällig'**
  String vocabDueBadge(int n);

  /// Tagesziel Chip — N neue Karten + M Wiederholungen (Phase 1 SRS-UX-Patch, stately-rising-jongga).
  ///
  /// In de, this message translates to:
  /// **'Heute ({newCount} neu · {reviewCount} Wdh.)'**
  String vocabTodayBadge(int newCount, int reviewCount);

  /// No description provided for @vocabDueEmpty.
  ///
  /// In de, this message translates to:
  /// **'Heute alles erledigt!\nKomm morgen wieder.'**
  String get vocabDueEmpty;

  /// No description provided for @vocabDueEmptyAction.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem üben'**
  String get vocabDueEmptyAction;

  /// No description provided for @vocabPacksTitle.
  ///
  /// In de, this message translates to:
  /// **'Vokabel-Pakete'**
  String get vocabPacksTitle;

  /// No description provided for @vocabPacksLevelMenu.
  ///
  /// In de, this message translates to:
  /// **'Level wechseln'**
  String get vocabPacksLevelMenu;

  /// No description provided for @vocabPacksScopedHint.
  ///
  /// In de, this message translates to:
  /// **'Nur Pakete für deine aktuelle Mission.'**
  String get vocabPacksScopedHint;

  /// No description provided for @vocabPacksBrowseAllCta.
  ///
  /// In de, this message translates to:
  /// **'Alle Vokabel-Pakete ansehen'**
  String get vocabPacksBrowseAllCta;

  /// No description provided for @vocabPacksProgressLabel.
  ///
  /// In de, this message translates to:
  /// **'{cleared}/{total} Pakete geschafft'**
  String vocabPacksProgressLabel(int cleared, int total);

  /// No description provided for @vocabPacksEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Pakete'**
  String get vocabPacksEmptyTitle;

  /// No description provided for @vocabPacksEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Level sind noch keine Vokabeln vorbereitet.'**
  String get vocabPacksEmptyBody;

  /// No description provided for @vocabPackLockedNoPrev.
  ///
  /// In de, this message translates to:
  /// **'Dieses Paket ist noch gesperrt.'**
  String get vocabPackLockedNoPrev;

  /// No description provided for @vocabPackLockedHint.
  ///
  /// In de, this message translates to:
  /// **'Schließe zuerst „{prev}“ mit ≥ 70 % ab.'**
  String vocabPackLockedHint(Object prev);

  /// No description provided for @bookCaptureTitle.
  ///
  /// In de, this message translates to:
  /// **'Buchseite einlesen'**
  String get bookCaptureTitle;

  /// No description provided for @bookCaptureHero.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere eine Lehrbuchseite'**
  String get bookCaptureHero;

  /// No description provided for @bookCaptureSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Das Bild bleibt auf deinem Gerät. Nur erkannter Text wird analysiert.'**
  String get bookCaptureSubtitle;

  /// No description provided for @bookCaptureCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get bookCaptureCamera;

  /// No description provided for @bookCaptureGallery.
  ///
  /// In de, this message translates to:
  /// **'Aus Galerie'**
  String get bookCaptureGallery;

  /// No description provided for @bookCaptureLoading.
  ///
  /// In de, this message translates to:
  /// **'Texterkennung läuft …'**
  String get bookCaptureLoading;

  /// No description provided for @bookCaptureErrorNoKorean.
  ///
  /// In de, this message translates to:
  /// **'Kein Koreanisch erkannt. Bitte mach ein schärferes Foto.'**
  String get bookCaptureErrorNoKorean;

  /// No description provided for @bookCaptureErrorPermission.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung verweigert. Du kannst es in den Einstellungen erlauben.'**
  String get bookCaptureErrorPermission;

  /// No description provided for @bookCaptureErrorQuota.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Limit erreicht (20 Seiten). Komm morgen wieder.'**
  String get bookCaptureErrorQuota;

  /// No description provided for @bookCaptureErrorOcr.
  ///
  /// In de, this message translates to:
  /// **'Texterkennung fehlgeschlagen.'**
  String get bookCaptureErrorOcr;

  /// No description provided for @bookCaptureErrorUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unerwarteter Fehler.'**
  String get bookCaptureErrorUnknown;

  /// No description provided for @bookCropTitle.
  ///
  /// In de, this message translates to:
  /// **'Bereich zuschneiden'**
  String get bookCropTitle;

  /// No description provided for @bookPreviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Text prüfen'**
  String get bookPreviewTitle;

  /// No description provided for @bookPreviewHint.
  ///
  /// In de, this message translates to:
  /// **'{count} Textblöcke erkannt. Korrigiere sie bei Bedarf.'**
  String bookPreviewHint(int count);

  /// No description provided for @bookPreviewAnalyze.
  ///
  /// In de, this message translates to:
  /// **'Analysieren'**
  String get bookPreviewAnalyze;

  /// No description provided for @bookPreviewRetake.
  ///
  /// In de, this message translates to:
  /// **'Neu aufnehmen'**
  String get bookPreviewRetake;

  /// No description provided for @bookResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis'**
  String get bookResultTitle;

  /// No description provided for @loadErrorTryAgain.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte versuche es erneut.'**
  String get loadErrorTryAgain;

  /// No description provided for @bookResultAnalyzing.
  ///
  /// In de, this message translates to:
  /// **'Wörter & Grammatik werden analysiert …'**
  String get bookResultAnalyzing;

  /// No description provided for @bookResultFoundN.
  ///
  /// In de, this message translates to:
  /// **'{n} neue Wörter gefunden'**
  String bookResultFoundN(int n);

  /// No description provided for @dojangTitle.
  ///
  /// In de, this message translates to:
  /// **'Stempelbuch'**
  String get dojangTitle;

  /// No description provided for @dojangEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Stempel'**
  String get dojangEmptyTitle;

  /// No description provided for @dojangEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Schließ Vokabelpakete ab und sammle Dancheong-Stempel.'**
  String get dojangEmptyBody;

  /// No description provided for @dojangProgress.
  ///
  /// In de, this message translates to:
  /// **'{earned} von {total} Stempeln gesammelt'**
  String dojangProgress(int earned, int total);

  /// No description provided for @gyeEntryTitle.
  ///
  /// In de, this message translates to:
  /// **'Lern-Gye'**
  String get gyeEntryTitle;

  /// No description provided for @gyeEntryDesc.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam ein Hanok bauen'**
  String get gyeEntryDesc;

  /// No description provided for @gyeChooserTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye (Lerngruppe)'**
  String get gyeChooserTitle;

  /// No description provided for @gyeChooserCreate.
  ///
  /// In de, this message translates to:
  /// **'Gye erstellen'**
  String get gyeChooserCreate;

  /// No description provided for @gyeChooserJoin.
  ///
  /// In de, this message translates to:
  /// **'Mit Code beitreten'**
  String get gyeChooserJoin;

  /// No description provided for @gyeCreateTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye erstellen'**
  String get gyeCreateTitle;

  /// No description provided for @gyeJoinTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye beitreten'**
  String get gyeJoinTitle;

  /// No description provided for @gyeNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Gye-Name'**
  String get gyeNameLabel;

  /// No description provided for @gyeNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Morgentiger'**
  String get gyeNameHint;

  /// No description provided for @gyeNicknameLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein Spitzname'**
  String get gyeNicknameLabel;

  /// No description provided for @gyeNicknameHint.
  ///
  /// In de, this message translates to:
  /// **'Für alle im Gye sichtbar'**
  String get gyeNicknameHint;

  /// No description provided for @gyeCodeLabel.
  ///
  /// In de, this message translates to:
  /// **'Beitrittscode'**
  String get gyeCodeLabel;

  /// No description provided for @gyeCodeInputLabel.
  ///
  /// In de, this message translates to:
  /// **'6-stelliger Code'**
  String get gyeCodeInputLabel;

  /// No description provided for @gyeCreateCta.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get gyeCreateCta;

  /// No description provided for @gyeJoinCta.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get gyeJoinCta;

  /// No description provided for @gyeCreatedTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye erstellt!'**
  String get gyeCreatedTitle;

  /// No description provided for @gyeShareCode.
  ///
  /// In de, this message translates to:
  /// **'Code teilen'**
  String get gyeShareCode;

  /// No description provided for @gyeInviteTitle.
  ///
  /// In de, this message translates to:
  /// **'Lade Freunde ein'**
  String get gyeInviteTitle;

  /// No description provided for @gyeInviteBody.
  ///
  /// In de, this message translates to:
  /// **'Teile den Code mit Freunden, damit sie deinem Gye beitreten können.'**
  String get gyeInviteBody;

  /// No description provided for @gyeCopyCode.
  ///
  /// In de, this message translates to:
  /// **'Code kopieren'**
  String get gyeCopyCode;

  /// No description provided for @gyeCodeCopied.
  ///
  /// In de, this message translates to:
  /// **'Code kopiert'**
  String get gyeCodeCopied;

  /// No description provided for @gyeShareMessage.
  ///
  /// In de, this message translates to:
  /// **'Tritt meinem Hangul-Sori-Gye bei! Code: {code}'**
  String gyeShareMessage(Object code);

  /// No description provided for @gyeJoinedSnack.
  ///
  /// In de, this message translates to:
  /// **'{name} beigetreten!'**
  String gyeJoinedSnack(Object name);

  /// No description provided for @gyeErrNetwork.
  ///
  /// In de, this message translates to:
  /// **'Netzwerkfehler. Bitte erneut versuchen.'**
  String get gyeErrNetwork;

  /// No description provided for @gyeErrNotFound.
  ///
  /// In de, this message translates to:
  /// **'Kein Gye für diesen Code gefunden.'**
  String get gyeErrNotFound;

  /// No description provided for @gyeErrFull.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gye ist voll (max. 10).'**
  String get gyeErrFull;

  /// No description provided for @gyeErrTooMany.
  ///
  /// In de, this message translates to:
  /// **'Du kannst höchstens 3 Gye beitreten.'**
  String get gyeErrTooMany;

  /// No description provided for @gyeErrName.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Gye-Namen ein.'**
  String get gyeErrName;

  /// No description provided for @gyeErrNickname.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Spitznamen ein.'**
  String get gyeErrNickname;

  /// No description provided for @gyeErrProfanity.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle ein anderes Wort.'**
  String get gyeErrProfanity;

  /// No description provided for @gyeErrAgeRestricted.
  ///
  /// In de, this message translates to:
  /// **'Gye ist ab 16 Jahren nutzbar. Da nur dein lokal selbst angegebenes Geburtsjahr gespeichert wird, prüft die App konservativ und schaltet erst bei mindestens 17 Jahren Jahresdifferenz frei.'**
  String get gyeErrAgeRestricted;

  /// No description provided for @gyeAgeYearTitle.
  ///
  /// In de, this message translates to:
  /// **'Geburtsjahr'**
  String get gyeAgeYearTitle;

  /// No description provided for @gyeAgeYearBody.
  ///
  /// In de, this message translates to:
  /// **'Gye ist ab 16 Jahren nutzbar. Dein Geburtsjahr ist eine Selbstauskunft, wird nur auf diesem Gerät gespeichert und ist keine Identitätsprüfung. Ohne Monat und Tag wird konservativ erst bei mindestens 17 Jahren Jahresdifferenz freigeschaltet.'**
  String get gyeAgeYearBody;

  /// No description provided for @gyeAgeYearHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. 2005'**
  String get gyeAgeYearHint;

  /// No description provided for @gyeOpenCta.
  ///
  /// In de, this message translates to:
  /// **'Gye öffnen'**
  String get gyeOpenCta;

  /// No description provided for @gyeTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye'**
  String get gyeTitle;

  /// No description provided for @gyeNotFoundTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye nicht gefunden'**
  String get gyeNotFoundTitle;

  /// No description provided for @gyeNotFoundBody.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gye wurde möglicherweise entfernt.'**
  String get gyeNotFoundBody;

  /// No description provided for @gyeMembersN.
  ///
  /// In de, this message translates to:
  /// **'{count} Mitglieder'**
  String gyeMembersN(int count);

  /// No description provided for @gyeWeeklyGoal.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel'**
  String get gyeWeeklyGoal;

  /// No description provided for @gyeNoGoal.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Wochenziel'**
  String get gyeNoGoal;

  /// No description provided for @gyeDureTitle.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche zusammen'**
  String get gyeDureTitle;

  /// No description provided for @gyeDureMe.
  ///
  /// In de, this message translates to:
  /// **'Ich'**
  String get gyeDureMe;

  /// No description provided for @gyeDureEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch leer. Schließ ein Paket ab und mach den Anfang.'**
  String get gyeDureEmpty;

  /// No description provided for @gyeChallengeTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle dabei?'**
  String get gyeChallengeTitle;

  /// No description provided for @gyeChallengeDone.
  ///
  /// In de, this message translates to:
  /// **'Alle dabei!'**
  String get gyeChallengeDone;

  /// No description provided for @dureTitleDuru.
  ///
  /// In de, this message translates to:
  /// **'Stütze'**
  String get dureTitleDuru;

  /// No description provided for @dureTitleNewcomer.
  ///
  /// In de, this message translates to:
  /// **'Neu dabei'**
  String get dureTitleNewcomer;

  /// No description provided for @dureTitleSprout.
  ///
  /// In de, this message translates to:
  /// **'Spross'**
  String get dureTitleSprout;

  /// No description provided for @dureTitleHelper.
  ///
  /// In de, this message translates to:
  /// **'Mit dabei'**
  String get dureTitleHelper;

  /// No description provided for @gyeFeedTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get gyeFeedTitle;

  /// No description provided for @gyeFeedEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Aktivität. Schließt gemeinsam ein Paket ab.'**
  String get gyeFeedEmpty;

  /// No description provided for @gyeFeedPackCleared.
  ///
  /// In de, this message translates to:
  /// **'{name} hat ein Paket abgeschlossen'**
  String gyeFeedPackCleared(Object name);

  /// No description provided for @gyeFeedQuest.
  ///
  /// In de, this message translates to:
  /// **'{name} hat eine Quest abgeschlossen'**
  String gyeFeedQuest(Object name);

  /// No description provided for @gyeFeedLevelUp.
  ///
  /// In de, this message translates to:
  /// **'{name} ist aufgestiegen'**
  String gyeFeedLevelUp(Object name);

  /// No description provided for @gyeFeedSticker.
  ///
  /// In de, this message translates to:
  /// **'{name} hat einen Sticker gesendet'**
  String gyeFeedSticker(Object name);

  /// No description provided for @gyeCheer1.
  ///
  /// In de, this message translates to:
  /// **'Zusammen!'**
  String get gyeCheer1;

  /// No description provided for @gyeCheer2.
  ///
  /// In de, this message translates to:
  /// **'Du schaffst das!'**
  String get gyeCheer2;

  /// No description provided for @gyeCheer3.
  ///
  /// In de, this message translates to:
  /// **'Du fehlst uns!'**
  String get gyeCheer3;

  /// No description provided for @gyeCheer4.
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft!'**
  String get gyeCheer4;

  /// No description provided for @gyeCheer5.
  ///
  /// In de, this message translates to:
  /// **'Auf geht\'s!'**
  String get gyeCheer5;

  /// No description provided for @gyeCheerTitle.
  ///
  /// In de, this message translates to:
  /// **'Anfeuern'**
  String get gyeCheerTitle;

  /// No description provided for @gyeFeedGoalAchieved.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel erreicht! Euer Hanok wächst.'**
  String get gyeFeedGoalAchieved;

  /// No description provided for @gyeFeedAllIn.
  ///
  /// In de, this message translates to:
  /// **'Alle haben diese Woche beigetragen!'**
  String get gyeFeedAllIn;

  /// No description provided for @gyeFeedGoalAchievedMvp.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel erreicht! {packs, plural, one{1 Paket} other{{packs} Pakete}} · MVP {mvp}'**
  String gyeFeedGoalAchievedMvp(int packs, Object mvp);

  /// No description provided for @gyeStickerSend.
  ///
  /// In de, this message translates to:
  /// **'Sticker senden'**
  String get gyeStickerSend;

  /// No description provided for @gyeStickerRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Sticker auf einmal. Versuch es gleich noch einmal.'**
  String get gyeStickerRateLimited;

  /// No description provided for @gyeStickerCatTiger.
  ///
  /// In de, this message translates to:
  /// **'Tiger'**
  String get gyeStickerCatTiger;

  /// No description provided for @gyeStickerCatMagpie.
  ///
  /// In de, this message translates to:
  /// **'Elster'**
  String get gyeStickerCatMagpie;

  /// No description provided for @gyeStickerCatDancheong.
  ///
  /// In de, this message translates to:
  /// **'Dancheong'**
  String get gyeStickerCatDancheong;

  /// No description provided for @gyeStickerCatHangul.
  ///
  /// In de, this message translates to:
  /// **'Hangul'**
  String get gyeStickerCatHangul;

  /// No description provided for @gyeStickerCatFood.
  ///
  /// In de, this message translates to:
  /// **'Essen'**
  String get gyeStickerCatFood;

  /// No description provided for @gyeStickerCatStamp.
  ///
  /// In de, this message translates to:
  /// **'Stempel'**
  String get gyeStickerCatStamp;

  /// No description provided for @gyeLeave.
  ///
  /// In de, this message translates to:
  /// **'Gye verlassen'**
  String get gyeLeave;

  /// No description provided for @gyeLeaveConfirm.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gye verlassen?'**
  String get gyeLeaveConfirm;

  /// No description provided for @gyeOwnerLeaveUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Als Leitung kannst du das Gye erst nach einer Übertragung oder Löschung verlassen.'**
  String get gyeOwnerLeaveUnavailable;

  /// No description provided for @gyeMembersTitle.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder'**
  String get gyeMembersTitle;

  /// No description provided for @gyeMemberSelf.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get gyeMemberSelf;

  /// No description provided for @gyeRoleOwner.
  ///
  /// In de, this message translates to:
  /// **'Leiter'**
  String get gyeRoleOwner;

  /// No description provided for @gyeReportTitle.
  ///
  /// In de, this message translates to:
  /// **'Mitglied melden'**
  String get gyeReportTitle;

  /// No description provided for @gyeReportReasonSpam.
  ///
  /// In de, this message translates to:
  /// **'Spam'**
  String get gyeReportReasonSpam;

  /// No description provided for @gyeReportReasonInappropriate.
  ///
  /// In de, this message translates to:
  /// **'Unangemessener Inhalt'**
  String get gyeReportReasonInappropriate;

  /// No description provided for @gyeReportReasonHarassment.
  ///
  /// In de, this message translates to:
  /// **'Belästigung'**
  String get gyeReportReasonHarassment;

  /// No description provided for @gyeReportReasonOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get gyeReportReasonOther;

  /// No description provided for @gyeReportNoteHint.
  ///
  /// In de, this message translates to:
  /// **'Notiz (optional)'**
  String get gyeReportNoteHint;

  /// No description provided for @gyeReportSubmit.
  ///
  /// In de, this message translates to:
  /// **'Melden'**
  String get gyeReportSubmit;

  /// No description provided for @gyeReportSent.
  ///
  /// In de, this message translates to:
  /// **'Meldung gesendet. Danke.'**
  String get gyeReportSent;

  /// No description provided for @gyeBlockTitle.
  ///
  /// In de, this message translates to:
  /// **'Mitglied blockieren?'**
  String get gyeBlockTitle;

  /// No description provided for @gyeBlockBody.
  ///
  /// In de, this message translates to:
  /// **'Du siehst keine Sticker, Anfeuerungen oder Beiträge dieser Person mehr. Du kannst die Blockierung jederzeit in der Mitgliederliste aufheben.'**
  String get gyeBlockBody;

  /// No description provided for @gyeBlockConfirm.
  ///
  /// In de, this message translates to:
  /// **'Blockieren'**
  String get gyeBlockConfirm;

  /// No description provided for @gyeUnblock.
  ///
  /// In de, this message translates to:
  /// **'Blockierung aufheben'**
  String get gyeUnblock;

  /// No description provided for @gyeBlockedLabel.
  ///
  /// In de, this message translates to:
  /// **'Blockiert'**
  String get gyeBlockedLabel;

  /// No description provided for @gyeBlockedSnack.
  ///
  /// In de, this message translates to:
  /// **'Mitglied blockiert. Beiträge werden ausgeblendet.'**
  String get gyeBlockedSnack;

  /// No description provided for @gyeMvpCard.
  ///
  /// In de, this message translates to:
  /// **'Applaus für {name}: {packs, plural, one{1 Paket} other{{packs} Pakete}} letzte Woche! 👏'**
  String gyeMvpCard(Object name, int packs);

  /// No description provided for @gyeProfileLevel.
  ///
  /// In de, this message translates to:
  /// **'Level {level}'**
  String gyeProfileLevel(Object level);

  /// No description provided for @gyeProfileStreak.
  ///
  /// In de, this message translates to:
  /// **'{days, plural, one{1 Tag Streak} other{{days} Tage Streak}}'**
  String gyeProfileStreak(int days);

  /// No description provided for @gyeProfileWeekly.
  ///
  /// In de, this message translates to:
  /// **'{packs, plural, one{1 Paket diese Woche} other{{packs} Pakete diese Woche}}'**
  String gyeProfileWeekly(int packs);

  /// No description provided for @gyeAllInCelebrate.
  ///
  /// In de, this message translates to:
  /// **'Alle haben diese Woche beigetragen!'**
  String get gyeAllInCelebrate;

  /// No description provided for @gyeReactTooltip.
  ///
  /// In de, this message translates to:
  /// **'Reagieren'**
  String get gyeReactTooltip;

  /// No description provided for @bookResultOfflineNotice.
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar. Es wurden nur Grammatikmuster offline erkannt.'**
  String get bookResultOfflineNotice;

  /// No description provided for @bookResultCredentialsNotice.
  ///
  /// In de, this message translates to:
  /// **'Die geschützte Analyse ist auf diesem Gerät nicht verfügbar. Melde dich an, prüfe die Verbindung und versuche es erneut.'**
  String get bookResultCredentialsNotice;

  /// No description provided for @bookResultRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Analyse-Limit erreicht. Bitte versuche es in einer Minute erneut.'**
  String get bookResultRateLimited;

  /// No description provided for @bookResultSectionWords.
  ///
  /// In de, this message translates to:
  /// **'Wörter'**
  String get bookResultSectionWords;

  /// No description provided for @bookResultSectionGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get bookResultSectionGrammar;

  /// No description provided for @bookResultSectionSentences.
  ///
  /// In de, this message translates to:
  /// **'Sätze'**
  String get bookResultSectionSentences;

  /// No description provided for @bookResultSave.
  ///
  /// In de, this message translates to:
  /// **'In meinem Bücherregal speichern'**
  String get bookResultSave;

  /// No description provided for @bookResultSaved.
  ///
  /// In de, this message translates to:
  /// **'Seite gespeichert.'**
  String get bookResultSaved;

  /// No description provided for @bookResultBackToCapture.
  ///
  /// In de, this message translates to:
  /// **'Weitere Seite einlesen'**
  String get bookResultBackToCapture;

  /// No description provided for @questsTitle.
  ///
  /// In de, this message translates to:
  /// **'Spezial-Quests'**
  String get questsTitle;

  /// No description provided for @questsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Quests'**
  String get questsEmptyTitle;

  /// No description provided for @questsEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Beginne ein Paket. Dein Quest-Fortschritt erscheint dann hier.'**
  String get questsEmptyBody;

  /// No description provided for @questsSectionInProgress.
  ///
  /// In de, this message translates to:
  /// **'Läuft'**
  String get questsSectionInProgress;

  /// No description provided for @questsSectionAvailable.
  ///
  /// In de, this message translates to:
  /// **'Verfügbar'**
  String get questsSectionAvailable;

  /// No description provided for @questsSectionCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get questsSectionCompleted;

  /// No description provided for @questsSectionSeasonalLocked.
  ///
  /// In de, this message translates to:
  /// **'Saisonal (gesperrt)'**
  String get questsSectionSeasonalLocked;

  /// No description provided for @questsSeasonalBadge.
  ///
  /// In de, this message translates to:
  /// **'Saison'**
  String get questsSeasonalBadge;

  /// No description provided for @questsCompletionCelebration.
  ///
  /// In de, this message translates to:
  /// **'Neue Dekoration für deine Stube freigeschaltet!'**
  String get questsCompletionCelebration;

  /// No description provided for @questsOpenGiftCta.
  ///
  /// In de, this message translates to:
  /// **'Bündel öffnen'**
  String get questsOpenGiftCta;

  /// No description provided for @homeBojagiTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein Geschenk wartet'**
  String get homeBojagiTitle;

  /// No description provided for @homeBojagiBody.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Ein Bündel wartet. Öffne es und richte deine Stube ein.} other{{count} Bündel warten. Öffne sie und richte deine Stube ein.}}'**
  String homeBojagiBody(int count);

  /// No description provided for @dojangDecorHintBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Stempel sind Andenken an geschaffte Wortpakete. Um deine Hanok-Stuben einzurichten, schließe Quests ab und öffne die Bündel, die du dabei bekommst.'**
  String get dojangDecorHintBody;

  /// No description provided for @dojangDecorHintCta.
  ///
  /// In de, this message translates to:
  /// **'Zu den Quests'**
  String get dojangDecorHintCta;

  /// No description provided for @hanokCinematicIntro.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok wächst.'**
  String get hanokCinematicIntro;

  /// No description provided for @hanokStageEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bauplatz vorbereiten'**
  String get hanokStageEmpty;

  /// No description provided for @hanokStageFoundation.
  ///
  /// In de, this message translates to:
  /// **'Sockel legen'**
  String get hanokStageFoundation;

  /// No description provided for @hanokStagePillars.
  ///
  /// In de, this message translates to:
  /// **'Säulen aufstellen'**
  String get hanokStagePillars;

  /// No description provided for @hanokStageBeams.
  ///
  /// In de, this message translates to:
  /// **'Dachstuhl bauen'**
  String get hanokStageBeams;

  /// No description provided for @hanokStageThatch.
  ///
  /// In de, this message translates to:
  /// **'Strohdach gedeckt'**
  String get hanokStageThatch;

  /// No description provided for @hanokStageTilePartial.
  ///
  /// In de, this message translates to:
  /// **'Ziegel auflegen'**
  String get hanokStageTilePartial;

  /// No description provided for @hanokStageTileComplete.
  ///
  /// In de, this message translates to:
  /// **'Ziegeldach fertig'**
  String get hanokStageTileComplete;

  /// No description provided for @hanokStageDancheong.
  ///
  /// In de, this message translates to:
  /// **'Dancheong gemalt'**
  String get hanokStageDancheong;

  /// No description provided for @hanokStageGate.
  ///
  /// In de, this message translates to:
  /// **'Tor errichtet'**
  String get hanokStageGate;

  /// No description provided for @hanokStageWindows.
  ///
  /// In de, this message translates to:
  /// **'Gitterfenster eingebaut'**
  String get hanokStageWindows;

  /// No description provided for @hanokStageSideBuilding.
  ///
  /// In de, this message translates to:
  /// **'Nebengebäude angebaut'**
  String get hanokStageSideBuilding;

  /// No description provided for @hanokStageJongga.
  ///
  /// In de, this message translates to:
  /// **'Jongga vollendet'**
  String get hanokStageJongga;

  /// No description provided for @vocabPackPlayTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket-Übung'**
  String get vocabPackPlayTitle;

  /// No description provided for @vocabPackLearnHint.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Umdrehen'**
  String get vocabPackLearnHint;

  /// No description provided for @vocabPackDontKnow.
  ///
  /// In de, this message translates to:
  /// **'Weiß ich nicht'**
  String get vocabPackDontKnow;

  /// No description provided for @vocabPackGotIt.
  ///
  /// In de, this message translates to:
  /// **'Gewusst'**
  String get vocabPackGotIt;

  /// No description provided for @vocabPackStageLearn.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get vocabPackStageLearn;

  /// No description provided for @vocabPackStageQuiz.
  ///
  /// In de, this message translates to:
  /// **'Quiz'**
  String get vocabPackStageQuiz;

  /// No description provided for @vocabPackStageBoss.
  ///
  /// In de, this message translates to:
  /// **'Boss'**
  String get vocabPackStageBoss;

  /// No description provided for @vocabPackQuizHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle die richtige Übersetzung'**
  String get vocabPackQuizHint;

  /// No description provided for @vocabPackBossHint.
  ///
  /// In de, this message translates to:
  /// **'Hör zu und wähle'**
  String get vocabPackBossHint;

  /// No description provided for @vocabPackBossReplayAudio.
  ///
  /// In de, this message translates to:
  /// **'Erneut anhören'**
  String get vocabPackBossReplayAudio;

  /// No description provided for @vocabPackTapToFlip.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Umdrehen'**
  String get vocabPackTapToFlip;

  /// No description provided for @vocabPackResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis'**
  String get vocabPackResultTitle;

  /// No description provided for @vocabPackResultCleared.
  ///
  /// In de, this message translates to:
  /// **'Paket geschafft!'**
  String get vocabPackResultCleared;

  /// No description provided for @vocabPackResultClearedAgain.
  ///
  /// In de, this message translates to:
  /// **'Schon gemeistert. Gut wiederholt!'**
  String get vocabPackResultClearedAgain;

  /// No description provided for @vocabPackResultRetry.
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft. Versuch es noch einmal!'**
  String get vocabPackResultRetry;

  /// No description provided for @vocabPackResultBossLabel.
  ///
  /// In de, this message translates to:
  /// **'Boss-Genauigkeit'**
  String get vocabPackResultBossLabel;

  /// No description provided for @vocabPackResultQuizLabel.
  ///
  /// In de, this message translates to:
  /// **'Quiz'**
  String get vocabPackResultQuizLabel;

  /// No description provided for @vocabPackResultXpLabel.
  ///
  /// In de, this message translates to:
  /// **'Belohnung'**
  String get vocabPackResultXpLabel;

  /// No description provided for @vocabPackResultNextPack.
  ///
  /// In de, this message translates to:
  /// **'Weiter zu \"{next}\"'**
  String vocabPackResultNextPack(Object next);

  /// No description provided for @vocabPackResultRetryCta.
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get vocabPackResultRetryCta;

  /// No description provided for @vocabPackResultBackToGrid.
  ///
  /// In de, this message translates to:
  /// **'Zurück zu den Paketen'**
  String get vocabPackResultBackToGrid;

  /// No description provided for @vocabPackResultGeschafft.
  ///
  /// In de, this message translates to:
  /// **'Geschafft! Du hast dieses Vokabelpaket gemeistert.'**
  String get vocabPackResultGeschafft;

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
  /// **'Angemeldet: {name}'**
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

  /// No description provided for @settingsCloudDeleteData.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Daten löschen'**
  String get settingsCloudDeleteData;

  /// No description provided for @settingsCloudDeleteDataDesc.
  ///
  /// In de, this message translates to:
  /// **'Löscht dein Firestore-Backup. Lokale Fortschritte auf diesem Gerät bleiben erhalten.'**
  String get settingsCloudDeleteDataDesc;

  /// No description provided for @settingsCloudDeleteDataConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Daten löschen?'**
  String get settingsCloudDeleteDataConfirmTitle;

  /// No description provided for @settingsCloudDeleteDataConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Dadurch wird das Cloud-Backup deines Firebase-Kontos gelöscht. Deine lokalen Fortschritte auf diesem Gerät bleiben erhalten.'**
  String get settingsCloudDeleteDataConfirmBody;

  /// No description provided for @settingsCloudDeleteDataSuccess.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Daten gelöscht'**
  String get settingsCloudDeleteDataSuccess;

  /// No description provided for @settingsCloudDeleteDataFailed.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Daten konnten nicht gelöscht werden.'**
  String get settingsCloudDeleteDataFailed;

  /// No description provided for @settingsAccountDelete.
  ///
  /// In de, this message translates to:
  /// **'Konto und alle Daten löschen'**
  String get settingsAccountDelete;

  /// No description provided for @settingsAccountDeleteDesc.
  ///
  /// In de, this message translates to:
  /// **'Löscht dein Firebase-Konto, Cloud-Backup und lokale Fortschritte.'**
  String get settingsAccountDeleteDesc;

  /// No description provided for @settingsAccountDeleteConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto dauerhaft löschen?'**
  String get settingsAccountDeleteConfirmTitle;

  /// No description provided for @settingsAccountDeleteConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Dadurch werden dein Firebase-Konto, deine Google- und Apple-Verknüpfungen, das Firestore-Cloud-Backup und lokale Lerndaten auf diesem Gerät gelöscht. Das lässt sich nicht rückgängig machen. Google oder Apple bitten dich zur Bestätigung eventuell um eine erneute Anmeldung.'**
  String get settingsAccountDeleteConfirmBody;

  /// No description provided for @settingsAccountDeleteSubscriptionWarning.
  ///
  /// In de, this message translates to:
  /// **'Ein App-Store- oder Play-Store-Abo wird dadurch nicht gekündigt.'**
  String get settingsAccountDeleteSubscriptionWarning;

  /// No description provided for @settingsManageSubscription.
  ///
  /// In de, this message translates to:
  /// **'Store-Abo verwalten'**
  String get settingsManageSubscription;

  /// No description provided for @settingsManageSubscriptionFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Aboverwaltung konnte nicht geöffnet werden.'**
  String get settingsManageSubscriptionFailed;

  /// No description provided for @settingsAccountDeleteSuccess.
  ///
  /// In de, this message translates to:
  /// **'Konto und Daten gelöscht'**
  String get settingsAccountDeleteSuccess;

  /// No description provided for @settingsAccountDeleteFailed.
  ///
  /// In de, this message translates to:
  /// **'Löschung fehlgeschlagen: {error}'**
  String settingsAccountDeleteFailed(Object error);

  /// No description provided for @settingsAccountDeletionTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto- und Datenlöschung'**
  String get settingsAccountDeletionTitle;

  /// No description provided for @settingsAccountDeletionSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Link zur Kontolöschung kopieren'**
  String get settingsAccountDeletionSubtitle;

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

  /// No description provided for @onboardingPage1Title.
  ///
  /// In de, this message translates to:
  /// **'Treffe deinen Lernfreund'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Taego begleitet dich beim Lernen'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In de, this message translates to:
  /// **'5 Minuten pro Tag'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Kurz und leicht in den Alltag einzubauen'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In de, this message translates to:
  /// **'Streaks zählen'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Mit regelmäßigem Lernen sammelst du Belohnungen.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In de, this message translates to:
  /// **'Wie viel Zeit hast du?'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingGoal5min.
  ///
  /// In de, this message translates to:
  /// **'5 Minuten'**
  String get onboardingGoal5min;

  /// No description provided for @onboardingGoal10min.
  ///
  /// In de, this message translates to:
  /// **'10 Minuten'**
  String get onboardingGoal10min;

  /// No description provided for @onboardingGoal15min.
  ///
  /// In de, this message translates to:
  /// **'15 Minuten'**
  String get onboardingGoal15min;

  /// No description provided for @onboardingStartEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dein erster Weg'**
  String get onboardingStartEyebrow;

  /// No description provided for @onboardingStartTitle.
  ///
  /// In de, this message translates to:
  /// **'Wofür willst du Koreanisch sprechen?'**
  String get onboardingStartTitle;

  /// No description provided for @onboardingStartBody.
  ///
  /// In de, this message translates to:
  /// **'Wir beginnen mit einer Situation aus deinem Alltag, nicht mit einem Test.'**
  String get onboardingStartBody;

  /// No description provided for @onboardingStartTravelTitle.
  ///
  /// In de, this message translates to:
  /// **'In Korea unterwegs sein'**
  String get onboardingStartTravelTitle;

  /// No description provided for @onboardingStartTravelBody.
  ///
  /// In de, this message translates to:
  /// **'Café, Weg, Einkaufen und Hilfe'**
  String get onboardingStartTravelBody;

  /// No description provided for @onboardingStartPeopleTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit Menschen sprechen'**
  String get onboardingStartPeopleTitle;

  /// No description provided for @onboardingStartPeopleBody.
  ///
  /// In de, this message translates to:
  /// **'Freunde, Familie und Alltag'**
  String get onboardingStartPeopleBody;

  /// No description provided for @onboardingStartWorkTitle.
  ///
  /// In de, this message translates to:
  /// **'Studium oder Arbeit'**
  String get onboardingStartWorkTitle;

  /// No description provided for @onboardingStartWorkBody.
  ///
  /// In de, this message translates to:
  /// **'Höflich fragen und verstehen'**
  String get onboardingStartWorkBody;

  /// No description provided for @onboardingStartPoint.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt'**
  String get onboardingStartPoint;

  /// No description provided for @onboardingStartNewTitle.
  ///
  /// In de, this message translates to:
  /// **'Ich beginne neu'**
  String get onboardingStartNewTitle;

  /// No description provided for @onboardingStartNewBody.
  ///
  /// In de, this message translates to:
  /// **'Direkt mit Hören und Sprechen'**
  String get onboardingStartNewBody;

  /// No description provided for @onboardingStartExistingTitle.
  ///
  /// In de, this message translates to:
  /// **'Ich kann schon etwas'**
  String get onboardingStartExistingTitle;

  /// No description provided for @onboardingStartExistingBody.
  ///
  /// In de, this message translates to:
  /// **'Level wählen oder 8–10 Fragen testen'**
  String get onboardingStartExistingBody;

  /// No description provided for @onboardingStartPrimary.
  ///
  /// In de, this message translates to:
  /// **'Meine erste Szene öffnen'**
  String get onboardingStartPrimary;

  /// No description provided for @onboardingStartChooseLevel.
  ///
  /// In de, this message translates to:
  /// **'Level wählen'**
  String get onboardingStartChooseLevel;

  /// No description provided for @onboardingStartLoading.
  ///
  /// In de, this message translates to:
  /// **'Deine erste Szene wird vorbereitet …'**
  String get onboardingStartLoading;

  /// No description provided for @onboardingCompanionChoose.
  ///
  /// In de, this message translates to:
  /// **'Lernfreund wählen'**
  String get onboardingCompanionChoose;

  /// No description provided for @onboardingCompanionSkip.
  ///
  /// In de, this message translates to:
  /// **'Jetzt nicht'**
  String get onboardingCompanionSkip;

  /// No description provided for @missionContextLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Mission'**
  String get missionContextLabel;

  /// No description provided for @courseMissionPath.
  ///
  /// In de, this message translates to:
  /// **'Dein Missionsweg'**
  String get courseMissionPath;

  /// No description provided for @courseMissionDetails.
  ///
  /// In de, this message translates to:
  /// **'Missionsdetails'**
  String get courseMissionDetails;

  /// No description provided for @courseMissionCheck.
  ///
  /// In de, this message translates to:
  /// **'Verständnis prüfen'**
  String get courseMissionCheck;

  /// No description provided for @missionContextStep.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String missionContextStep(int current, int total);

  /// No description provided for @onboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ist dein Level?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wir fangen dort an, wo du stehst. Frühere Level bleiben offen, spätere schaltest du frei.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingLevelA1.
  ///
  /// In de, this message translates to:
  /// **'Anfänger'**
  String get onboardingLevelA1;

  /// No description provided for @onboardingLevelA1Desc.
  ///
  /// In de, this message translates to:
  /// **'Ich fange gerade an'**
  String get onboardingLevelA1Desc;

  /// No description provided for @onboardingLevelA2.
  ///
  /// In de, this message translates to:
  /// **'Grundkenntnisse'**
  String get onboardingLevelA2;

  /// No description provided for @onboardingLevelA2Desc.
  ///
  /// In de, this message translates to:
  /// **'Begrüßungen, einfache Bestellungen'**
  String get onboardingLevelA2Desc;

  /// No description provided for @onboardingLevelB1.
  ///
  /// In de, this message translates to:
  /// **'Mittelstufe'**
  String get onboardingLevelB1;

  /// No description provided for @onboardingLevelB1Desc.
  ///
  /// In de, this message translates to:
  /// **'Alltagsgespräche möglich'**
  String get onboardingLevelB1Desc;

  /// No description provided for @onboardingLevelB2.
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get onboardingLevelB2;

  /// No description provided for @onboardingLevelB2Desc.
  ///
  /// In de, this message translates to:
  /// **'Fließend, auch Nuancen'**
  String get onboardingLevelB2Desc;

  /// No description provided for @onboardingExampleA1Trans.
  ///
  /// In de, this message translates to:
  /// **'Hallo / Guten Tag.'**
  String get onboardingExampleA1Trans;

  /// No description provided for @onboardingExampleA2Trans.
  ///
  /// In de, this message translates to:
  /// **'Einen Iced Americano in Tall, bitte.'**
  String get onboardingExampleA2Trans;

  /// No description provided for @onboardingExampleB1Trans.
  ///
  /// In de, this message translates to:
  /// **'Gestern war ich mit einem Freund im Kino. Hat richtig Spaß gemacht.'**
  String get onboardingExampleB1Trans;

  /// No description provided for @onboardingExampleB2Trans.
  ///
  /// In de, this message translates to:
  /// **'Das Meeting zieht sich, ich komme wohl etwas später.'**
  String get onboardingExampleB2Trans;

  /// No description provided for @onboardingSkip.
  ///
  /// In de, this message translates to:
  /// **'Später entscheiden (A1 als Start)'**
  String get onboardingSkip;

  /// No description provided for @onboardingPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Level. Du kannst es später in den Einstellungen ändern.'**
  String get onboardingPrompt;

  /// No description provided for @onboardingTigerGreeting.
  ///
  /// In de, this message translates to:
  /// **'Willkommen!\nWo möchtest du starten?'**
  String get onboardingTigerGreeting;

  /// No description provided for @onboardingDifficulty.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get onboardingDifficulty;

  /// No description provided for @onboardingExampleLabel.
  ///
  /// In de, this message translates to:
  /// **'So klingt dieses Level'**
  String get onboardingExampleLabel;

  /// No description provided for @onboardingCompareCta.
  ///
  /// In de, this message translates to:
  /// **'Unsicher? Level vergleichen'**
  String get onboardingCompareCta;

  /// No description provided for @onboardingCompareTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ändert sich pro Level?'**
  String get onboardingCompareTitle;

  /// No description provided for @onboardingCompareIntro.
  ///
  /// In de, this message translates to:
  /// **'Frühere Level bleiben offen. Dein Level kannst du jederzeit in den Einstellungen ändern.'**
  String get onboardingCompareIntro;

  /// No description provided for @onboardingCompareColCan.
  ///
  /// In de, this message translates to:
  /// **'Das kannst du schon'**
  String get onboardingCompareColCan;

  /// No description provided for @onboardingCompareColLearn.
  ///
  /// In de, this message translates to:
  /// **'Das lernst du hier'**
  String get onboardingCompareColLearn;

  /// No description provided for @onboardingCompareClose.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get onboardingCompareClose;

  /// No description provided for @onboardingLevelA1Can.
  ///
  /// In de, this message translates to:
  /// **'Du kennst vielleicht ein paar Wörter.'**
  String get onboardingLevelA1Can;

  /// No description provided for @onboardingLevelA1Learn.
  ///
  /// In de, this message translates to:
  /// **'Hangeul lesen und schreiben, dich vorstellen, Zahlen.'**
  String get onboardingLevelA1Learn;

  /// No description provided for @onboardingLevelA2Can.
  ///
  /// In de, this message translates to:
  /// **'Du liest Hangeul und kennst einfache Begrüßungen.'**
  String get onboardingLevelA2Can;

  /// No description provided for @onboardingLevelA2Learn.
  ///
  /// In de, this message translates to:
  /// **'Bestellen, einkaufen, nach dem Weg fragen, die Höflichkeitsform -요.'**
  String get onboardingLevelA2Learn;

  /// No description provided for @onboardingLevelB1Can.
  ///
  /// In de, this message translates to:
  /// **'Du führst einfache Gespräche über den Alltag.'**
  String get onboardingLevelB1Can;

  /// No description provided for @onboardingLevelB1Learn.
  ///
  /// In de, this message translates to:
  /// **'Erzählen, Meinung äußern, Sätze verbinden, Vergangenheit.'**
  String get onboardingLevelB1Learn;

  /// No description provided for @onboardingLevelB2Can.
  ///
  /// In de, this message translates to:
  /// **'Du sprichst flüssig über Alltagsthemen.'**
  String get onboardingLevelB2Can;

  /// No description provided for @onboardingLevelB2Learn.
  ///
  /// In de, this message translates to:
  /// **'Beruf und Nachrichten, Nuancen, Redewendungen, Ehrerbietung.'**
  String get onboardingLevelB2Learn;

  /// No description provided for @homeHeroGreetingMorning.
  ///
  /// In de, this message translates to:
  /// **'Guten Morgen!'**
  String get homeHeroGreetingMorning;

  /// No description provided for @homeHeroGreetingAfternoon.
  ///
  /// In de, this message translates to:
  /// **'Hallo!'**
  String get homeHeroGreetingAfternoon;

  /// No description provided for @homeHeroGreetingEvening.
  ///
  /// In de, this message translates to:
  /// **'Guten Abend!'**
  String get homeHeroGreetingEvening;

  /// No description provided for @homeTigerBubbleStart.
  ///
  /// In de, this message translates to:
  /// **'Lust auf 5 Minuten Koreanisch?'**
  String get homeTigerBubbleStart;

  /// No description provided for @homeTigerBubbleStreak.
  ///
  /// In de, this message translates to:
  /// **'Dein Streak hält! Weiter so'**
  String get homeTigerBubbleStreak;

  /// No description provided for @homeTigerBubbleResume.
  ///
  /// In de, this message translates to:
  /// **'Willkommen zurück!'**
  String get homeTigerBubbleResume;

  /// No description provided for @homeHeroActionContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiterlernen'**
  String get homeHeroActionContinue;

  /// No description provided for @homeHeroActionStart.
  ///
  /// In de, this message translates to:
  /// **'Neues Paket'**
  String get homeHeroActionStart;

  /// No description provided for @homeShieldLabel.
  ///
  /// In de, this message translates to:
  /// **'Schild'**
  String get homeShieldLabel;

  /// No description provided for @homePathSection.
  ///
  /// In de, this message translates to:
  /// **'Dein Pfad'**
  String get homePathSection;

  /// No description provided for @homePathLocked.
  ///
  /// In de, this message translates to:
  /// **'Verschlossen'**
  String get homePathLocked;

  /// No description provided for @homePathCurrent.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get homePathCurrent;

  /// No description provided for @homeLearnNowCta.
  ///
  /// In de, this message translates to:
  /// **'Jetzt lernen'**
  String get homeLearnNowCta;

  /// No description provided for @homeTigerBubbleResumeSub.
  ///
  /// In de, this message translates to:
  /// **'5 Minuten reichen schon!'**
  String get homeTigerBubbleResumeSub;

  /// No description provided for @homePathDone.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get homePathDone;

  /// No description provided for @scenariosListTitle.
  ///
  /// In de, this message translates to:
  /// **'Szenarien'**
  String get scenariosListTitle;

  /// No description provided for @scenariosListSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Lerne durch echte Situationen'**
  String get scenariosListSubtitle;

  /// No description provided for @scenariosLocked.
  ///
  /// In de, this message translates to:
  /// **'Erreiche {level}, um freizuschalten'**
  String scenariosLocked(Object level);

  /// No description provided for @scenariosLevelBadge.
  ///
  /// In de, this message translates to:
  /// **'Stufe {level}'**
  String scenariosLevelBadge(Object level);

  /// No description provided for @scenariosEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bald verfügbar 🚧'**
  String get scenariosEmpty;

  /// No description provided for @scenariosEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Bald verfügbar'**
  String get scenariosEmptyTitle;

  /// No description provided for @scenariosEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Neue Szenarien folgen bald.'**
  String get scenariosEmptyBody;

  /// No description provided for @scenariosLoadFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Hm, da ist etwas schiefgelaufen'**
  String get scenariosLoadFailedTitle;

  /// No description provided for @statsFirstEntryTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt beginnt hier'**
  String get statsFirstEntryTitle;

  /// No description provided for @statsFirstEntryBody.
  ///
  /// In de, this message translates to:
  /// **'Schließ ein Szenario ab. Danach siehst du deinen Fortschritt hier.'**
  String get statsFirstEntryBody;

  /// No description provided for @statsFirstEntryCta.
  ///
  /// In de, this message translates to:
  /// **'Erstes Szenario starten'**
  String get statsFirstEntryCta;

  /// No description provided for @settingsOfflineTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get settingsOfflineTitle;

  /// No description provided for @settingsOfflineBody.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync braucht eine aktive Internetverbindung. Du kannst es später erneut versuchen.'**
  String get settingsOfflineBody;

  /// No description provided for @vocabDueEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute alles erledigt!'**
  String get vocabDueEmptyTitle;

  /// No description provided for @vocabDueEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast deine fälligen Karten geschafft. Komm morgen wieder oder lerne neue Wörter.'**
  String get vocabDueEmptyBody;

  /// No description provided for @moduleScenariosTitle.
  ///
  /// In de, this message translates to:
  /// **'Szenarien'**
  String get moduleScenariosTitle;

  /// No description provided for @moduleScenariosDesc.
  ///
  /// In de, this message translates to:
  /// **'Übe Alltagssituationen: Café, Flughafen, Vorstellung …'**
  String get moduleScenariosDesc;

  /// No description provided for @scenarioIntroTitle.
  ///
  /// In de, this message translates to:
  /// **'Einleitung'**
  String get scenarioIntroTitle;

  /// No description provided for @scenarioVocabTitle.
  ///
  /// In de, this message translates to:
  /// **'Wortschatz'**
  String get scenarioVocabTitle;

  /// No description provided for @scenarioDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Dialog'**
  String get scenarioDialogTitle;

  /// No description provided for @scenarioGrammarTitle.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get scenarioGrammarTitle;

  /// No description provided for @scenarioQuestsTitle.
  ///
  /// In de, this message translates to:
  /// **'Mini-Spiele'**
  String get scenarioQuestsTitle;

  /// No description provided for @scenarioCulturalNote.
  ///
  /// In de, this message translates to:
  /// **'Kulturnotiz'**
  String get scenarioCulturalNote;

  /// No description provided for @scenarioStartBtn.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s!'**
  String get scenarioStartBtn;

  /// No description provided for @scenarioNextBtn.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get scenarioNextBtn;

  /// No description provided for @scenarioCompleteBtn.
  ///
  /// In de, this message translates to:
  /// **'Abschließen'**
  String get scenarioCompleteBtn;

  /// No description provided for @scenarioResultReturnBtn.
  ///
  /// In de, this message translates to:
  /// **'Zurück zu meinem Weg'**
  String get scenarioResultReturnBtn;

  /// No description provided for @scenarioCanDoVerifiedTitle.
  ///
  /// In de, this message translates to:
  /// **'Das kannst du jetzt.'**
  String get scenarioCanDoVerifiedTitle;

  /// No description provided for @scenarioCanDoVerifiedBody.
  ///
  /// In de, this message translates to:
  /// **'Der Checkpoint dieser Szene wurde selbstständig gespeichert.'**
  String get scenarioCanDoVerifiedBody;

  /// No description provided for @scenarioCanDoReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht sicher.'**
  String get scenarioCanDoReviewTitle;

  /// No description provided for @scenarioCanDoReviewBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Checkpoint wurde gespeichert, liegt aber unter der bestätigten Schwelle dieser Mission. Übe die Szene noch einmal.'**
  String get scenarioCanDoReviewBody;

  /// No description provided for @scenarioCanDoPracticeTitle.
  ///
  /// In de, this message translates to:
  /// **'Übung gespeichert.'**
  String get scenarioCanDoPracticeTitle;

  /// No description provided for @scenarioCanDoPracticeBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Szene ist als Übung gespeichert und verändert deinen Kurs-Schritt nicht.'**
  String get scenarioCanDoPracticeBody;

  /// No description provided for @scenarioXpEarned.
  ///
  /// In de, this message translates to:
  /// **'+{xp} XP'**
  String scenarioXpEarned(int xp);

  /// No description provided for @scenarioStarsLabel.
  ///
  /// In de, this message translates to:
  /// **'{stars} von 3 Sternen'**
  String scenarioStarsLabel(int stars);

  /// No description provided for @scenarioRecapTitle.
  ///
  /// In de, this message translates to:
  /// **'Das hast du gelernt'**
  String get scenarioRecapTitle;

  /// No description provided for @scenarioRecapWordsLine.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort geübt} other{{count} Wörter geübt}}'**
  String scenarioRecapWordsLine(int count);

  /// No description provided for @scenarioRecapAccuracyLine.
  ///
  /// In de, this message translates to:
  /// **'{passed} von {total} Quests im ersten Versuch'**
  String scenarioRecapAccuracyLine(int passed, int total);

  /// No description provided for @scenarioRecapGrammarLine.
  ///
  /// In de, this message translates to:
  /// **'Grammatik-Fokus: {pattern}'**
  String scenarioRecapGrammarLine(String pattern);

  /// No description provided for @scenarioNextRecommendedTitle.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes empfohlen'**
  String get scenarioNextRecommendedTitle;

  /// No description provided for @scenarioNextRecommendedCta.
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get scenarioNextRecommendedCta;

  /// No description provided for @scenarioNextRecommendedAllDone.
  ///
  /// In de, this message translates to:
  /// **'Alle {level}-Szenarien abgeschlossen.'**
  String scenarioNextRecommendedAllDone(String level);

  /// No description provided for @questCorrect.
  ///
  /// In de, this message translates to:
  /// **'Richtig!'**
  String get questCorrect;

  /// No description provided for @questWrong.
  ///
  /// In de, this message translates to:
  /// **'Nicht ganz'**
  String get questWrong;

  /// No description provided for @questNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get questNext;

  /// No description provided for @questRetry.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get questRetry;

  /// No description provided for @particlePopHint.
  ///
  /// In de, this message translates to:
  /// **'Zieh die richtige Partikel in den Slot.'**
  String get particlePopHint;

  /// No description provided for @particlePopExplanation.
  ///
  /// In de, this message translates to:
  /// **'Nach Konsonant: 은/이/을 · Nach Vokal: 는/가/를'**
  String get particlePopExplanation;

  /// No description provided for @settingsUserLevel.
  ///
  /// In de, this message translates to:
  /// **'Mein Level'**
  String get settingsUserLevel;

  /// No description provided for @settingsUserLevelChange.
  ///
  /// In de, this message translates to:
  /// **'Level ändern'**
  String get settingsUserLevelChange;

  /// No description provided for @statsXpTitle.
  ///
  /// In de, this message translates to:
  /// **'Szenario-Fortschritt'**
  String get statsXpTitle;

  /// No description provided for @statsXp.
  ///
  /// In de, this message translates to:
  /// **'XP'**
  String get statsXp;

  /// No description provided for @statsLevelLabel.
  ///
  /// In de, this message translates to:
  /// **'Level {n}'**
  String statsLevelLabel(int n);

  /// No description provided for @statsToNextLevel.
  ///
  /// In de, this message translates to:
  /// **'{n} XP bis Level {next}'**
  String statsToNextLevel(int n, int next);

  /// No description provided for @statsScenariosCompleted.
  ///
  /// In de, this message translates to:
  /// **'Szenarien geschafft'**
  String get statsScenariosCompleted;

  /// No description provided for @statsBadgesTitle.
  ///
  /// In de, this message translates to:
  /// **'Auszeichnungen'**
  String get statsBadgesTitle;

  /// No description provided for @statsNoBadges.
  ///
  /// In de, this message translates to:
  /// **'Noch keine. Schließ ein Szenario ab und hol dir die erste! 🚀'**
  String get statsNoBadges;

  /// No description provided for @homeRecommended.
  ///
  /// In de, this message translates to:
  /// **'Heute empfohlen'**
  String get homeRecommended;

  /// No description provided for @homeAllDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Szenarien geschafft!'**
  String get homeAllDone;

  /// No description provided for @homeNoScenario.
  ///
  /// In de, this message translates to:
  /// **'Bald gibt es Szenarien für dein Level'**
  String get homeNoScenario;

  /// No description provided for @homeGreetingLearn.
  ///
  /// In de, this message translates to:
  /// **'Übe Koreanisch für echte Alltagssituationen'**
  String get homeGreetingLearn;

  /// No description provided for @homeTodaySection.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get homeTodaySection;

  /// No description provided for @missionHeroCtaStart.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get missionHeroCtaStart;

  /// No description provided for @missionHeroCtaContinue.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get missionHeroCtaContinue;

  /// No description provided for @missionHeroCourseMeta.
  ///
  /// In de, this message translates to:
  /// **'Mission {n} von {total}'**
  String missionHeroCourseMeta(int n, int total);

  /// No description provided for @missionHeroPackMeta.
  ///
  /// In de, this message translates to:
  /// **'Wortschatz-Paket · Level {level}'**
  String missionHeroPackMeta(Object level);

  /// No description provided for @missionHeroReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort wiederholen} other{{n} Wörter wiederholen}}'**
  String missionHeroReviewTitle(int n);

  /// No description provided for @missionHeroReviewMeta.
  ///
  /// In de, this message translates to:
  /// **'Heutige Wiederholung'**
  String get missionHeroReviewMeta;

  /// No description provided for @missionHeroScenarioMeta.
  ///
  /// In de, this message translates to:
  /// **'Szenario · Level {level}'**
  String missionHeroScenarioMeta(Object level);

  /// No description provided for @missionHeroAllDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Für heute geschafft'**
  String get missionHeroAllDoneTitle;

  /// No description provided for @missionHeroAllDoneBody.
  ///
  /// In de, this message translates to:
  /// **'Stark! Morgen warten neue Missionen auf dich.'**
  String get missionHeroAllDoneBody;

  /// No description provided for @missionHeroAnotherRound.
  ///
  /// In de, this message translates to:
  /// **'Noch eine Runde'**
  String get missionHeroAnotherRound;

  /// No description provided for @missionHeroSemantics.
  ///
  /// In de, this message translates to:
  /// **'Nächste Mission: {title}, Level {level}'**
  String missionHeroSemantics(Object title, Object level);

  /// No description provided for @settingsThemeTitle.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In de, this message translates to:
  /// **'Systemvorgabe'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get settingsThemeDark;

  /// No description provided for @dailyCharTitle.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe des Tages'**
  String get dailyCharTitle;

  /// No description provided for @dailyCharSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Strichfolge ansehen'**
  String get dailyCharSubtitle;

  /// No description provided for @dailyCharFallbackSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Buchstaben des Tages ansehen'**
  String get dailyCharFallbackSubtitle;

  /// No description provided for @dailyCharGuideHint.
  ///
  /// In de, this message translates to:
  /// **'Fertig wird nach der vollständigen Strichfolge freigeschaltet.'**
  String get dailyCharGuideHint;

  /// No description provided for @dailyCharDoneToday.
  ///
  /// In de, this message translates to:
  /// **'Heute geschafft ✓'**
  String get dailyCharDoneToday;

  /// No description provided for @dailyCharFinish.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get dailyCharFinish;

  /// No description provided for @dailyCharStreak.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Tag gesamt} other{{n} Tage gesamt}}'**
  String dailyCharStreak(int n);

  /// No description provided for @dailyCharGreatJob.
  ///
  /// In de, this message translates to:
  /// **'Super!'**
  String get dailyCharGreatJob;

  /// No description provided for @vocabModeFavorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get vocabModeFavorites;

  /// No description provided for @vocabFavoritesBadge.
  ///
  /// In de, this message translates to:
  /// **'{n}'**
  String vocabFavoritesBadge(int n);

  /// No description provided for @vocabHearExample.
  ///
  /// In de, this message translates to:
  /// **'Beispiel hören'**
  String get vocabHearExample;

  /// No description provided for @vocabSlowHint.
  ///
  /// In de, this message translates to:
  /// **'Lang drücken: langsam'**
  String get vocabSlowHint;

  /// No description provided for @vocabEmptyFavorites.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Favoriten\nMarkiere schwierige Wörter mit dem Stern'**
  String get vocabEmptyFavorites;

  /// No description provided for @listeningTitle.
  ///
  /// In de, this message translates to:
  /// **'Hören'**
  String get listeningTitle;

  /// No description provided for @listeningSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Hör ein Szenario in natürlichem Tempo'**
  String get listeningSubtitle;

  /// No description provided for @listeningSelectScenario.
  ///
  /// In de, this message translates to:
  /// **'Szenario wählen'**
  String get listeningSelectScenario;

  /// No description provided for @listeningSpeedLabel.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get listeningSpeedLabel;

  /// No description provided for @listeningSubtitleLabel.
  ///
  /// In de, this message translates to:
  /// **'Untertitel'**
  String get listeningSubtitleLabel;

  /// No description provided for @listeningSubtitleKo.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch'**
  String get listeningSubtitleKo;

  /// No description provided for @listeningSubtitleNative.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung'**
  String get listeningSubtitleNative;

  /// No description provided for @listeningSubtitleBoth.
  ///
  /// In de, this message translates to:
  /// **'Beides'**
  String get listeningSubtitleBoth;

  /// No description provided for @listeningSubtitleOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get listeningSubtitleOff;

  /// No description provided for @listeningReplay.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get listeningReplay;

  /// No description provided for @listeningGotIt.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get listeningGotIt;

  /// No description provided for @listeningPrev.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get listeningPrev;

  /// No description provided for @listeningNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get listeningNext;

  /// No description provided for @listeningProgress.
  ///
  /// In de, this message translates to:
  /// **'{i}/{n}'**
  String listeningProgress(int i, int n);

  /// No description provided for @listeningCompleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get listeningCompleteTitle;

  /// No description provided for @listeningCompleteBody.
  ///
  /// In de, this message translates to:
  /// **'{n} Zeilen gehört · +{xp} XP'**
  String listeningCompleteBody(int n, int xp);

  /// No description provided for @listeningPickFirst.
  ///
  /// In de, this message translates to:
  /// **'Wähl oben ein Szenario, um zu starten.'**
  String get listeningPickFirst;

  /// No description provided for @listeningEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Szenarien'**
  String get listeningEmptyTitle;

  /// No description provided for @listeningEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Sobald Szenarien verfügbar sind, kannst du sie hier anhören.'**
  String get listeningEmptyBody;

  /// No description provided for @kkeunmariTitle.
  ///
  /// In de, this message translates to:
  /// **'Wortkette'**
  String get kkeunmariTitle;

  /// No description provided for @kkeunmariSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Letzte Silbe → nächstes Wort'**
  String get kkeunmariSubtitle;

  /// No description provided for @kkeunmariYourTurn.
  ///
  /// In de, this message translates to:
  /// **'Du bist dran'**
  String get kkeunmariYourTurn;

  /// No description provided for @kkeunmariTigerTurn.
  ///
  /// In de, this message translates to:
  /// **'Tiger denkt …'**
  String get kkeunmariTigerTurn;

  /// No description provided for @kkeunmariStartHint.
  ///
  /// In de, this message translates to:
  /// **'Beginne mit »{syl}«'**
  String kkeunmariStartHint(Object syl);

  /// No description provided for @kkeunmariInputHint.
  ///
  /// In de, this message translates to:
  /// **'Wort auf Koreanisch …'**
  String get kkeunmariInputHint;

  /// No description provided for @kkeunmariSubmit.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get kkeunmariSubmit;

  /// No description provided for @kkeunmariDictionaryChecking.
  ///
  /// In de, this message translates to:
  /// **'Wörterbuch wird geprüft…'**
  String get kkeunmariDictionaryChecking;

  /// No description provided for @kkeunmariNotDictionaryWord.
  ///
  /// In de, this message translates to:
  /// **'Dieses Wort ist kein gültiges Wörterbuch-Stichwort für das Spiel.'**
  String get kkeunmariNotDictionaryWord;

  /// No description provided for @kkeunmariDictionaryUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Das Wörterbuch kann gerade nicht geprüft werden. Versuche ein bekanntes Wort oder probiere es gleich noch einmal.'**
  String get kkeunmariDictionaryUnavailable;

  /// No description provided for @kkeunmariNotInPool.
  ///
  /// In de, this message translates to:
  /// **'Das kenne ich noch nicht. Versuch ein anderes Wort. 🐯'**
  String get kkeunmariNotInPool;

  /// No description provided for @kkeunmariNotKorean.
  ///
  /// In de, this message translates to:
  /// **'Nur Hangul-Wörter, bitte'**
  String get kkeunmariNotKorean;

  /// No description provided for @kkeunmariWrongStart.
  ///
  /// In de, this message translates to:
  /// **'Muss mit »{syl}« anfangen'**
  String kkeunmariWrongStart(Object syl);

  /// No description provided for @kkeunmariAlreadyUsed.
  ///
  /// In de, this message translates to:
  /// **'Bereits genutzt'**
  String get kkeunmariAlreadyUsed;

  /// No description provided for @kkeunmariTimeUp.
  ///
  /// In de, this message translates to:
  /// **'Zeit abgelaufen!'**
  String get kkeunmariTimeUp;

  /// No description provided for @kkeunmariDeadEnd.
  ///
  /// In de, this message translates to:
  /// **'한방단어 (Sackgasse): Die Kette endet hier.'**
  String get kkeunmariDeadEnd;

  /// No description provided for @kkeunmariChainLength.
  ///
  /// In de, this message translates to:
  /// **'Kette: {n}'**
  String kkeunmariChainLength(int n);

  /// No description provided for @kkeunmariFinalScore.
  ///
  /// In de, this message translates to:
  /// **'+{xp} XP'**
  String kkeunmariFinalScore(int xp);

  /// No description provided for @kkeunmariPlayAgain.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get kkeunmariPlayAgain;

  /// No description provided for @kkeunmariBackHome.
  ///
  /// In de, this message translates to:
  /// **'Startseite'**
  String get kkeunmariBackHome;

  /// No description provided for @kkeunmariTimerSeconds.
  ///
  /// In de, this message translates to:
  /// **'{n}s'**
  String kkeunmariTimerSeconds(int n);

  /// No description provided for @kkeunmariResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Spiel vorbei'**
  String get kkeunmariResultTitle;

  /// No description provided for @kkeunmariResultBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast {n, plural, one{1 Wort} other{{n} Wörter}} verkettet.'**
  String kkeunmariResultBody(int n);

  /// No description provided for @gameKkeunmariTitle.
  ///
  /// In de, this message translates to:
  /// **'Wortkette'**
  String get gameKkeunmariTitle;

  /// No description provided for @gameKkeunmariDesc.
  ///
  /// In de, this message translates to:
  /// **'Letzte Silbe → nächstes Wort'**
  String get gameKkeunmariDesc;

  /// No description provided for @vocabMasteryFresh.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get vocabMasteryFresh;

  /// No description provided for @vocabMasteryLearning.
  ///
  /// In de, this message translates to:
  /// **'Im Aufbau'**
  String get vocabMasteryLearning;

  /// No description provided for @vocabMasteryReviewDue.
  ///
  /// In de, this message translates to:
  /// **'Fällig'**
  String get vocabMasteryReviewDue;

  /// No description provided for @vocabMasteryStrong.
  ///
  /// In de, this message translates to:
  /// **'Gefestigt'**
  String get vocabMasteryStrong;

  /// No description provided for @scenariosPathTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Pfad'**
  String get scenariosPathTitle;

  /// No description provided for @scenariosPathProgress.
  ///
  /// In de, this message translates to:
  /// **'{done}/{total} freigeschaltet'**
  String scenariosPathProgress(int done, int total);

  /// No description provided for @scenariosPathNextLabel.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes'**
  String get scenariosPathNextLabel;

  /// No description provided for @scenariosPathStartCta.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get scenariosPathStartCta;

  /// No description provided for @scenariosPathAllDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Szenarien abgeschlossen'**
  String get scenariosPathAllDone;

  /// No description provided for @scenariosPathLevelProgress.
  ///
  /// In de, this message translates to:
  /// **'{level}: {done}/{total} ★'**
  String scenariosPathLevelProgress(Object level, int done, int total);

  /// No description provided for @shareTooltip.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get shareTooltip;

  /// No description provided for @shareTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket teilen'**
  String get shareTitle;

  /// No description provided for @shareGenerating.
  ///
  /// In de, this message translates to:
  /// **'Code wird erstellt …'**
  String get shareGenerating;

  /// No description provided for @shareCodeLabel.
  ///
  /// In de, this message translates to:
  /// **'Freundes-Code'**
  String get shareCodeLabel;

  /// No description provided for @shareCopyCode.
  ///
  /// In de, this message translates to:
  /// **'Code kopieren'**
  String get shareCopyCode;

  /// No description provided for @shareCodeCopied.
  ///
  /// In de, this message translates to:
  /// **'Code kopiert'**
  String get shareCodeCopied;

  /// No description provided for @shareViaApp.
  ///
  /// In de, this message translates to:
  /// **'Über App teilen'**
  String get shareViaApp;

  /// No description provided for @shareExpiryNote.
  ///
  /// In de, this message translates to:
  /// **'Code gilt 30 Tage.'**
  String get shareExpiryNote;

  /// No description provided for @shareError.
  ///
  /// In de, this message translates to:
  /// **'Teilen fehlgeschlagen. Bist du online?'**
  String get shareError;

  /// No description provided for @shareEmpty.
  ///
  /// In de, this message translates to:
  /// **'Dieser Paket hat keine Wörter.'**
  String get shareEmpty;

  /// No description provided for @sharePackBody.
  ///
  /// In de, this message translates to:
  /// **'Ich teile mit dir das Vokabel-Paket „{name}“ ({count, plural, one{1 Wort} other{{count} Wörter}}) aus Hangul Sori! Gib in der App den Code {code} ein, um es zu importieren. hangul-sori.com'**
  String sharePackBody(Object name, int count, Object code);

  /// No description provided for @redeemTooltip.
  ///
  /// In de, this message translates to:
  /// **'Mit Code importieren'**
  String get redeemTooltip;

  /// No description provided for @redeemTitle.
  ///
  /// In de, this message translates to:
  /// **'Paket importieren'**
  String get redeemTitle;

  /// No description provided for @redeemHint.
  ///
  /// In de, this message translates to:
  /// **'6-stelligen Code eingeben'**
  String get redeemHint;

  /// No description provided for @redeemAction.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get redeemAction;

  /// No description provided for @redeemSuccess.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ importiert ({count, plural, one{1 Wort} other{{count} Wörter}})'**
  String redeemSuccess(Object name, int count);

  /// No description provided for @redeemNotFound.
  ///
  /// In de, this message translates to:
  /// **'Code nicht gefunden.'**
  String get redeemNotFound;

  /// No description provided for @redeemExpired.
  ///
  /// In de, this message translates to:
  /// **'Dieser Code ist abgelaufen.'**
  String get redeemExpired;

  /// No description provided for @redeemError.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen. Bist du online?'**
  String get redeemError;

  /// No description provided for @createWordbookCta.
  ///
  /// In de, this message translates to:
  /// **'Eigene Wortliste'**
  String get createWordbookCta;

  /// No description provided for @createWordbookTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Wortliste'**
  String get createWordbookTitle;

  /// No description provided for @createWordbookHint.
  ///
  /// In de, this message translates to:
  /// **'Gib deiner Wortliste einen Namen.'**
  String get createWordbookHint;

  /// No description provided for @wbEditTooltip.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get wbEditTooltip;

  /// No description provided for @wbEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Wortliste bearbeiten'**
  String get wbEditTitle;

  /// No description provided for @wbAddWord.
  ///
  /// In de, this message translates to:
  /// **'Wort hinzufügen'**
  String get wbAddWord;

  /// No description provided for @wbEditWordTitle.
  ///
  /// In de, this message translates to:
  /// **'Wort bearbeiten'**
  String get wbEditWordTitle;

  /// No description provided for @wbEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Wörter'**
  String get wbEmptyTitle;

  /// No description provided for @wbEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Füge dein erstes Wort hinzu oder lass die Übersetzung automatisch ausfüllen.'**
  String get wbEmptyBody;

  /// No description provided for @wbFieldKorean.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch'**
  String get wbFieldKorean;

  /// No description provided for @wbFieldMeaning.
  ///
  /// In de, this message translates to:
  /// **'Bedeutung'**
  String get wbFieldMeaning;

  /// No description provided for @wbFieldExample.
  ///
  /// In de, this message translates to:
  /// **'Beispielsatz (optional)'**
  String get wbFieldExample;

  /// No description provided for @wbAutoFill.
  ///
  /// In de, this message translates to:
  /// **'Automatisch ausfüllen'**
  String get wbAutoFill;

  /// No description provided for @wbAutoFillRunning.
  ///
  /// In de, this message translates to:
  /// **'Suche Übersetzung …'**
  String get wbAutoFillRunning;

  /// No description provided for @wbAutoFillOffline.
  ///
  /// In de, this message translates to:
  /// **'Automatisches Ausfüllen ist gerade nicht möglich. Bitte trag die Übersetzung selbst ein.'**
  String get wbAutoFillOffline;

  /// No description provided for @wbSaveWord.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get wbSaveWord;

  /// No description provided for @wbNeedKorean.
  ///
  /// In de, this message translates to:
  /// **'Bitte ein koreanisches Wort eingeben.'**
  String get wbNeedKorean;

  /// No description provided for @wbDeleteWordTitle.
  ///
  /// In de, this message translates to:
  /// **'Wort löschen?'**
  String get wbDeleteWordTitle;

  /// No description provided for @wbDeleteWordBody.
  ///
  /// In de, this message translates to:
  /// **'Dieses Wort wird aus der Liste entfernt.'**
  String get wbDeleteWordBody;

  /// No description provided for @wbRenameTitle.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get wbRenameTitle;

  /// No description provided for @wbRenameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get wbRenameLabel;

  /// No description provided for @wbStudyCards.
  ///
  /// In de, this message translates to:
  /// **'Karten lernen'**
  String get wbStudyCards;

  /// No description provided for @wbQuiz.
  ///
  /// In de, this message translates to:
  /// **'Quiz'**
  String get wbQuiz;

  /// No description provided for @quizNeedMore.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 4 Wörter mit Bedeutung nötig.'**
  String get quizNeedMore;

  /// No description provided for @quizQuestion.
  ///
  /// In de, this message translates to:
  /// **'Was bedeutet dieses Wort?'**
  String get quizQuestion;

  /// No description provided for @quizScore.
  ///
  /// In de, this message translates to:
  /// **'{correct} / {total} richtig'**
  String quizScore(int correct, int total);

  /// No description provided for @quizResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Quiz beendet'**
  String get quizResultTitle;

  /// No description provided for @quizResultBody.
  ///
  /// In de, this message translates to:
  /// **'Gut gemacht! Wiederhole die Liste, um dich zu verbessern.'**
  String get quizResultBody;

  /// No description provided for @quizAgain.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get quizAgain;

  /// No description provided for @gameNewBest.
  ///
  /// In de, this message translates to:
  /// **'Neuer Rekord!'**
  String get gameNewBest;

  /// No description provided for @gameBestAccuracy.
  ///
  /// In de, this message translates to:
  /// **'Beste Genauigkeit: {percent}%'**
  String gameBestAccuracy(int percent);

  /// No description provided for @gameBestTries.
  ///
  /// In de, this message translates to:
  /// **'Bester: {count} Versuche'**
  String gameBestTries(int count);

  /// No description provided for @clozeTitle.
  ///
  /// In de, this message translates to:
  /// **'Lückentext'**
  String get clozeTitle;

  /// No description provided for @clozeDesc.
  ///
  /// In de, this message translates to:
  /// **'Das fehlende Wort im Satz'**
  String get clozeDesc;

  /// No description provided for @clozeInstruction.
  ///
  /// In de, this message translates to:
  /// **'Wähle das fehlende Wort.'**
  String get clozeInstruction;

  /// No description provided for @clozeEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Level gibt es noch keine Sätze. Wähle ein anderes Level.'**
  String get clozeEmptyBody;

  /// No description provided for @clozeLevelAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get clozeLevelAll;

  /// No description provided for @speedMatchTitle.
  ///
  /// In de, this message translates to:
  /// **'Blitz-Paare'**
  String get speedMatchTitle;

  /// No description provided for @speedMatchDesc.
  ///
  /// In de, this message translates to:
  /// **'Auf Zeit zuordnen'**
  String get speedMatchDesc;

  /// No description provided for @speedMatchInstruction.
  ///
  /// In de, this message translates to:
  /// **'Tippe ein koreanisches Wort, dann die passende Bedeutung.'**
  String get speedMatchInstruction;

  /// No description provided for @speedMatchScore.
  ///
  /// In de, this message translates to:
  /// **'{count} Paare'**
  String speedMatchScore(int count);

  /// No description provided for @speedMatchBest.
  ///
  /// In de, this message translates to:
  /// **'Bester: {count} Paare'**
  String speedMatchBest(int count);

  /// No description provided for @dailyTitle.
  ///
  /// In de, this message translates to:
  /// **'Tages-Challenge'**
  String get dailyTitle;

  /// No description provided for @dailyDesc.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Rätsel · Streak'**
  String get dailyDesc;

  /// No description provided for @dailyAlreadyDone.
  ///
  /// In de, this message translates to:
  /// **'Heute schon erledigt. Jetzt im Übungsmodus.'**
  String get dailyAlreadyDone;

  /// No description provided for @dailyStreak.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Tag in Folge} other{{count} Tage in Folge}}'**
  String dailyStreak(int count);

  /// No description provided for @satzArcadeTitle.
  ///
  /// In de, this message translates to:
  /// **'Satz bauen'**
  String get satzArcadeTitle;

  /// No description provided for @satzArcadeDesc.
  ///
  /// In de, this message translates to:
  /// **'Wörter zum Satz ordnen'**
  String get satzArcadeDesc;

  /// No description provided for @homeWordbookCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Eigene Wortliste'**
  String get homeWordbookCardTitle;

  /// No description provided for @homeWordbookCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Selbst erstellen & üben'**
  String get homeWordbookCardDesc;

  /// No description provided for @csvImportTitle.
  ///
  /// In de, this message translates to:
  /// **'CSV importieren'**
  String get csvImportTitle;

  /// No description provided for @csvImportHint.
  ///
  /// In de, this message translates to:
  /// **'Eine Zeile pro Wort: Koreanisch, Bedeutung, Beispiel (optional). Mit Komma getrennt.'**
  String get csvImportHint;

  /// No description provided for @csvImportButton.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get csvImportButton;

  /// No description provided for @csvImportEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine gültigen Zeilen gefunden.'**
  String get csvImportEmpty;

  /// No description provided for @csvImportResult.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort importiert} other{{count} Wörter importiert}}'**
  String csvImportResult(int count);

  /// No description provided for @wbPhotoCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get wbPhotoCamera;

  /// No description provided for @wbPhotoGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get wbPhotoGallery;

  /// No description provided for @wbPhotoRemove.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get wbPhotoRemove;

  /// No description provided for @hardWordsTitle.
  ///
  /// In de, this message translates to:
  /// **'Knifflige Wörter'**
  String get hardWordsTitle;

  /// No description provided for @hardWordsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort, das einfach nicht sitzen will} other{{count} Wörter, die einfach nicht sitzen wollen}}'**
  String hardWordsSubtitle(int count);

  /// No description provided for @hardWordsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Sorgenkinder'**
  String get hardWordsEmptyTitle;

  /// No description provided for @hardWordsEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Im Moment gibt es keine besonders schwierigen Wörter. Wenn dir eins immer wieder schwerfällt, erscheint es hier.'**
  String get hardWordsEmptyBody;

  /// No description provided for @hardWordsStudyCta.
  ///
  /// In de, this message translates to:
  /// **'Gezielt wiederholen'**
  String get hardWordsStudyCta;

  /// No description provided for @wbMatching.
  ///
  /// In de, this message translates to:
  /// **'Paare finden'**
  String get wbMatching;

  /// No description provided for @wbMatchingHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein koreanisches Wort, dann auf seine Bedeutung.'**
  String get wbMatchingHint;

  /// No description provided for @wbMatchingNeedMore.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 2 Wörter mit Bedeutung nötig.'**
  String get wbMatchingNeedMore;

  /// No description provided for @wbMatchingDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Paare gefunden!'**
  String get wbMatchingDone;

  /// No description provided for @wbMatchingDoneBody.
  ///
  /// In de, this message translates to:
  /// **'Noch eine Runde?'**
  String get wbMatchingDoneBody;

  /// No description provided for @wbTyping.
  ///
  /// In de, this message translates to:
  /// **'Schreiben'**
  String get wbTyping;

  /// No description provided for @wbTypingNeedMore.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 1 Wort mit Bedeutung nötig.'**
  String get wbTypingNeedMore;

  /// No description provided for @wbTypingPrompt.
  ///
  /// In de, this message translates to:
  /// **'Schreib das koreanische Wort:'**
  String get wbTypingPrompt;

  /// No description provided for @wbTypingHint.
  ///
  /// In de, this message translates to:
  /// **'Auf Koreanisch …'**
  String get wbTypingHint;

  /// No description provided for @wbTypingAnswer.
  ///
  /// In de, this message translates to:
  /// **'Richtig: {answer}'**
  String wbTypingAnswer(Object answer);

  /// No description provided for @wbQuickPackName.
  ///
  /// In de, this message translates to:
  /// **'⭐ Schnellspeicher'**
  String get wbQuickPackName;

  /// No description provided for @wbAddTooltip.
  ///
  /// In de, this message translates to:
  /// **'Zur Wortliste hinzufügen'**
  String get wbAddTooltip;

  /// No description provided for @wbCoachTitle.
  ///
  /// In de, this message translates to:
  /// **'Wörter hier speichern'**
  String get wbCoachTitle;

  /// No description provided for @wbCoachBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf das Lesezeichen, um ein Wort zu speichern und täglich zu wiederholen. Aus deiner Wortliste kannst du auch eigene Lernkarten erstellen.'**
  String get wbCoachBody;

  /// No description provided for @wbAdded.
  ///
  /// In de, this message translates to:
  /// **'{word} zur Wortliste hinzugefügt'**
  String wbAdded(Object word);

  /// No description provided for @wbAlreadyAdded.
  ///
  /// In de, this message translates to:
  /// **'{word} ist schon in deiner Wortliste'**
  String wbAlreadyAdded(Object word);

  /// No description provided for @wbAddFailed.
  ///
  /// In de, this message translates to:
  /// **'Konnte nicht hinzugefügt werden'**
  String get wbAddFailed;

  /// No description provided for @wbViewAction.
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get wbViewAction;

  /// No description provided for @wbSearchTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Wörter'**
  String get wbSearchTitle;

  /// No description provided for @wbSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Wort oder Bedeutung suchen …'**
  String get wbSearchHint;

  /// No description provided for @wbSearchEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer'**
  String get wbSearchEmpty;

  /// No description provided for @wbSearchNoWords.
  ///
  /// In de, this message translates to:
  /// **'Noch keine gespeicherten Wörter. Tippe beim Lernen auf das Lesezeichen-Symbol.'**
  String get wbSearchNoWords;

  /// No description provided for @wbSearchCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort} other{{count} Wörter}}'**
  String wbSearchCount(int count);

  /// No description provided for @wbPosAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get wbPosAll;

  /// No description provided for @wbSearchCta.
  ///
  /// In de, this message translates to:
  /// **'Meine Wörter durchsuchen'**
  String get wbSearchCta;

  /// No description provided for @comboPop.
  ///
  /// In de, this message translates to:
  /// **'{count}er-Combo!'**
  String comboPop(int count);

  /// No description provided for @pathTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernpfad'**
  String get pathTitle;

  /// No description provided for @pathHanokStage.
  ///
  /// In de, this message translates to:
  /// **'Hanok · Stufe {n}/12'**
  String pathHanokStage(int n);

  /// No description provided for @pathHanokSub.
  ///
  /// In de, this message translates to:
  /// **'Dein Hof wächst mit jedem gemeisterten Paket.'**
  String get pathHanokSub;

  /// No description provided for @pathLevelPacks.
  ///
  /// In de, this message translates to:
  /// **'{done}/{total} Pakete'**
  String pathLevelPacks(int done, int total);

  /// No description provided for @pathNodeNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get pathNodeNow;

  /// No description provided for @pathLockedHint.
  ///
  /// In de, this message translates to:
  /// **'Schließe zuerst das vorherige Paket ab.'**
  String get pathLockedHint;

  /// No description provided for @pathSeeAll.
  ///
  /// In de, this message translates to:
  /// **'Ganzer Pfad'**
  String get pathSeeAll;

  /// No description provided for @pathJumpToNow.
  ///
  /// In de, this message translates to:
  /// **'Zum aktuellen Schritt'**
  String get pathJumpToNow;

  /// No description provided for @gyeEmptyHeadline.
  ///
  /// In de, this message translates to:
  /// **'Allein lernen ist vollständig. Zusammen kann es wärmer sein.'**
  String get gyeEmptyHeadline;

  /// No description provided for @gyeEmptyPreviewCaption.
  ///
  /// In de, this message translates to:
  /// **'Eine Vorschau auf einen gemeinsamen Hof — nie Voraussetzung für deinen Lernweg'**
  String get gyeEmptyPreviewCaption;

  /// No description provided for @homePathCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernpfad'**
  String get homePathCardTitle;

  /// No description provided for @homePathCardSub.
  ///
  /// In de, this message translates to:
  /// **'Sieh, wo du stehst'**
  String get homePathCardSub;

  /// No description provided for @homeBrowseTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles entdecken'**
  String get homeBrowseTitle;

  /// No description provided for @homeBrowseSub.
  ///
  /// In de, this message translates to:
  /// **'Module & Spiele'**
  String get homeBrowseSub;

  /// No description provided for @notifStreakSaverTitle.
  ///
  /// In de, this message translates to:
  /// **'🔥 Streak nicht verlieren!'**
  String get notifStreakSaverTitle;

  /// No description provided for @notifStreakSaverBody.
  ///
  /// In de, this message translates to:
  /// **'Eine kurze Runde reicht, um dranzubleiben.'**
  String get notifStreakSaverBody;

  /// No description provided for @notifDailyStreakBody.
  ///
  /// In de, this message translates to:
  /// **'🔥 {days, plural, one{1 Tag am Stück} other{{days} Tage am Stück}}. Machst du heute weiter?'**
  String notifDailyStreakBody(int days);

  /// No description provided for @ttsListen.
  ///
  /// In de, this message translates to:
  /// **'Aussprache'**
  String get ttsListen;

  /// No description provided for @navProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileGuestName.
  ///
  /// In de, this message translates to:
  /// **'Gast'**
  String get profileGuestName;

  /// No description provided for @profileGuestBadge.
  ///
  /// In de, this message translates to:
  /// **'Behalte Streak, XP & Hanok'**
  String get profileGuestBadge;

  /// No description provided for @profileGuestDesc.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt ist bisher nur auf diesem Gerät. Mit Google-Backup bleibt er auch auf einem neuen Handy erhalten.'**
  String get profileGuestDesc;

  /// No description provided for @profileConnectedBadge.
  ///
  /// In de, this message translates to:
  /// **'Konto verbunden'**
  String get profileConnectedBadge;

  /// No description provided for @profileConnectedProviderBadge.
  ///
  /// In de, this message translates to:
  /// **'Mit {provider} verbunden'**
  String profileConnectedProviderBadge(Object provider);

  /// No description provided for @profileConnectedDesc.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt kann jetzt in der Cloud gesichert werden.'**
  String get profileConnectedDesc;

  /// No description provided for @profileStatStreak.
  ///
  /// In de, this message translates to:
  /// **'Tage-Streak'**
  String get profileStatStreak;

  /// No description provided for @profileStatLevel.
  ///
  /// In de, this message translates to:
  /// **'Level'**
  String get profileStatLevel;

  /// No description provided for @profileStatWords.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln'**
  String get profileStatWords;

  /// No description provided for @profileViewStats.
  ///
  /// In de, this message translates to:
  /// **'Alle Statistiken ansehen'**
  String get profileViewStats;

  /// No description provided for @profileLearningSection.
  ///
  /// In de, this message translates to:
  /// **'Mein Lernen'**
  String get profileLearningSection;

  /// No description provided for @profileLearningGoal.
  ///
  /// In de, this message translates to:
  /// **'Mein Ziel'**
  String get profileLearningGoal;

  /// No description provided for @profileLearningGoalNotSet.
  ///
  /// In de, this message translates to:
  /// **'Wähle, was dich zum Koreanischen bringt'**
  String get profileLearningGoalNotSet;

  /// No description provided for @profileLearningStartPoint.
  ///
  /// In de, this message translates to:
  /// **'Mein Startpunkt'**
  String get profileLearningStartPoint;

  /// No description provided for @profileLearningCompanion.
  ///
  /// In de, this message translates to:
  /// **'Lernbegleitung'**
  String get profileLearningCompanion;

  /// No description provided for @profileSpaceSection.
  ///
  /// In de, this message translates to:
  /// **'Mein Raum'**
  String get profileSpaceSection;

  /// No description provided for @profilePrivacyAccount.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Konto'**
  String get profilePrivacyAccount;

  /// No description provided for @profilePrivacyAccountDescription.
  ///
  /// In de, this message translates to:
  /// **'Daten, Sicherung und Kontosteuerung'**
  String get profilePrivacyAccountDescription;

  /// No description provided for @profileProgressSection.
  ///
  /// In de, this message translates to:
  /// **'Mein Fortschritt'**
  String get profileProgressSection;

  /// No description provided for @profileSignOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get profileSignOut;

  /// No description provided for @accountNudgeTitle.
  ///
  /// In de, this message translates to:
  /// **'Speichere deinen Fortschritt'**
  String get accountNudgeTitle;

  /// No description provided for @accountNudgeBody.
  ///
  /// In de, this message translates to:
  /// **'Verbinde dich mit Google, damit dein Streak und deine Vokabeln bei einem Handywechsel erhalten bleiben.'**
  String get accountNudgeBody;

  /// No description provided for @accountNudgeConnect.
  ///
  /// In de, this message translates to:
  /// **'Mit Google verbinden'**
  String get accountNudgeConnect;

  /// No description provided for @accountNudgeLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get accountNudgeLater;

  /// No description provided for @accountSafeConnectTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto sicher verbinden?'**
  String get accountSafeConnectTitle;

  /// No description provided for @errorOffline.
  ///
  /// In de, this message translates to:
  /// **'Kein Internet. Dein Fortschritt ist auf diesem Gerät sicher.'**
  String get errorOffline;

  /// No description provided for @accountSafeConnectExplain.
  ///
  /// In de, this message translates to:
  /// **'Deine lokalen und Cloud-Daten werden geprüft, bevor etwas ersetzt wird. Ein bestehendes Konto wird nie automatisch überschrieben.'**
  String get accountSafeConnectExplain;

  /// No description provided for @accountSafeConnectConfirm.
  ///
  /// In de, this message translates to:
  /// **'Sicher verbinden'**
  String get accountSafeConnectConfirm;

  /// No description provided for @accountOperationInProgress.
  ///
  /// In de, this message translates to:
  /// **'Konto und Lernfortschritt werden sicher geprüft …'**
  String get accountOperationInProgress;

  /// No description provided for @accountOperationResumeTitle.
  ///
  /// In de, this message translates to:
  /// **'Kontowechsel fortsetzen'**
  String get accountOperationResumeTitle;

  /// No description provided for @accountOperationResumeBody.
  ///
  /// In de, this message translates to:
  /// **'Der sichere Kontowechsel ist gespeichert. Deine Daten bleiben geschützt, bis alle Schritte abgeschlossen sind.'**
  String get accountOperationResumeBody;

  /// No description provided for @accountOperationResume.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get accountOperationResume;

  /// No description provided for @accountOperationCancel.
  ///
  /// In de, this message translates to:
  /// **'Wechsel abbrechen'**
  String get accountOperationCancel;

  /// No description provided for @accountOperationBlockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto ist geschützt'**
  String get accountOperationBlockedTitle;

  /// No description provided for @accountOperationBlockedBody.
  ///
  /// In de, this message translates to:
  /// **'Der Wechsel wurde angehalten. Deine bisherigen Daten bleiben unverändert. Du kannst es später erneut versuchen.'**
  String get accountOperationBlockedBody;

  /// No description provided for @accountOperationRetryTitle.
  ///
  /// In de, this message translates to:
  /// **'Verbindung nicht abgeschlossen'**
  String get accountOperationRetryTitle;

  /// No description provided for @accountOperationRetryBody.
  ///
  /// In de, this message translates to:
  /// **'Die sichere Prüfung konnte nicht abgeschlossen werden. Du kannst denselben Vorgang erneut versuchen.'**
  String get accountOperationRetryBody;

  /// No description provided for @accountOperationSupportBody.
  ///
  /// In de, this message translates to:
  /// **'Wenn der Vorgang weiter blockiert bleibt, wende dich an den Support. Teile keine Anmeldecodes oder Wiederherstellungsschlüssel.'**
  String get accountOperationSupportBody;

  /// No description provided for @accountDeletionPendingTitle.
  ///
  /// In de, this message translates to:
  /// **'Löschung wird fortgesetzt'**
  String get accountDeletionPendingTitle;

  /// No description provided for @accountDeletionPendingBody.
  ///
  /// In de, this message translates to:
  /// **'Der sichere Löschvorgang ist noch nicht abgeschlossen. Versuche denselben Vorgang erneut; deine Anfrage wird nicht doppelt angelegt.'**
  String get accountDeletionPendingBody;

  /// No description provided for @accountLockedCloudDeletionTitle.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Löschung wird fortgesetzt'**
  String get accountLockedCloudDeletionTitle;

  /// No description provided for @accountLockedCloudDeletionBody.
  ///
  /// In de, this message translates to:
  /// **'Eine gespeicherte Cloud-Datenlöschung ist noch nicht abgeschlossen. Bis dahin sind Kontoaktionen gesperrt. Du kannst die Löschung jetzt fortsetzen; sie wird nicht doppelt angelegt.'**
  String get accountLockedCloudDeletionBody;

  /// No description provided for @accountLockedResumeNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt fortsetzen'**
  String get accountLockedResumeNow;

  /// No description provided for @accountLockedRefresh.
  ///
  /// In de, this message translates to:
  /// **'Status aktualisieren'**
  String get accountLockedRefresh;

  /// No description provided for @accountFailureReasonAppCheck.
  ///
  /// In de, this message translates to:
  /// **'Die App-Integritätsprüfung ist fehlgeschlagen. Aktualisiere die App oder versuche es später erneut.'**
  String get accountFailureReasonAppCheck;

  /// No description provided for @accountFailureReasonOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung. Prüfe dein Netzwerk und versuche es erneut.'**
  String get accountFailureReasonOffline;

  /// No description provided for @accountFailureReasonAuth.
  ///
  /// In de, this message translates to:
  /// **'Die Anmeldung muss bestätigt werden. Melde dich erneut an und versuche es noch einmal.'**
  String get accountFailureReasonAuth;

  /// No description provided for @accountFailureReasonServer.
  ///
  /// In de, this message translates to:
  /// **'Der Server ist vorübergehend nicht erreichbar. Versuche es in ein paar Minuten erneut.'**
  String get accountFailureReasonServer;

  /// No description provided for @settingsCloudResumeDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Löschung fortsetzen'**
  String get settingsCloudResumeDeleteTitle;

  /// No description provided for @settingsCloudResumeDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'Die gespeicherte Löschanfrage wird fortgesetzt. Sie wird nicht doppelt angelegt.'**
  String get settingsCloudResumeDeleteBody;

  /// No description provided for @settingsCloudLastBackup.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gesichert: {time}'**
  String settingsCloudLastBackup(String time);

  /// No description provided for @settingsCloudLastBackupNever.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sicherung'**
  String get settingsCloudLastBackupNever;

  /// No description provided for @settingsResetDoneJournalKept.
  ///
  /// In de, this message translates to:
  /// **'Zurückgesetzt. Eine offene Konto-Aufgabe wurde beibehalten und wird automatisch fortgesetzt.'**
  String get settingsResetDoneJournalKept;

  /// No description provided for @gyeAccountTransitionPaused.
  ///
  /// In de, this message translates to:
  /// **'Kontoänderung läuft. Gruppenaktionen sind geschützt pausiert und werden nach Abschluss wieder verfügbar.'**
  String get gyeAccountTransitionPaused;

  /// No description provided for @authAppleSignIn.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple anmelden'**
  String get authAppleSignIn;

  /// No description provided for @authProviderGoogle.
  ///
  /// In de, this message translates to:
  /// **'Google'**
  String get authProviderGoogle;

  /// No description provided for @authProviderApple.
  ///
  /// In de, this message translates to:
  /// **'Apple'**
  String get authProviderApple;

  /// No description provided for @authProviderGoogleAndApple.
  ///
  /// In de, this message translates to:
  /// **'Google und Apple'**
  String get authProviderGoogleAndApple;

  /// No description provided for @consentTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Hangul Sori'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernfortschritt bleibt zunächst auf deinem Gerät. Optionale Funktionen wie Cloud-Backup, Lerngruppen, Foto-Worterkennung und Aussprache-Audio verarbeiten einzelne Daten auf EU-Servern. Details findest du in der Datenschutzerklärung.'**
  String get consentBody;

  /// No description provided for @consentPrivacyCta.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get consentPrivacyCta;

  /// No description provided for @consentTermsCta.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get consentTermsCta;

  /// No description provided for @consentAgreeCta.
  ///
  /// In de, this message translates to:
  /// **'Zustimmen & loslegen'**
  String get consentAgreeCta;

  /// No description provided for @consentFootnote.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Fortfahren stimmst du unseren Nutzungsbedingungen und unserer Datenschutzerklärung zu.'**
  String get consentFootnote;

  /// No description provided for @consentAnalyticsOptIn.
  ///
  /// In de, this message translates to:
  /// **'Anonyme Nutzungsstatistiken teilen (optional)'**
  String get consentAnalyticsOptIn;

  /// No description provided for @consentCrashOptIn.
  ///
  /// In de, this message translates to:
  /// **'Anonyme Absturzberichte teilen (optional)'**
  String get consentCrashOptIn;

  /// No description provided for @consentOptionalHint.
  ///
  /// In de, this message translates to:
  /// **'Beides ist freiwillig und jederzeit in den Einstellungen änderbar.'**
  String get consentOptionalHint;

  /// No description provided for @grammarEasy.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get grammarEasy;

  /// No description provided for @grammarHard.
  ///
  /// In de, this message translates to:
  /// **'Schwierig'**
  String get grammarHard;

  /// No description provided for @navHome.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get navHome;

  /// No description provided for @navDiscover.
  ///
  /// In de, this message translates to:
  /// **'Entdecken'**
  String get navDiscover;

  /// No description provided for @discoverEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Werkzeuge & Kultur'**
  String get discoverEyebrow;

  /// No description provided for @discoverTitle.
  ///
  /// In de, this message translates to:
  /// **'Finde genau, was du brauchst.'**
  String get discoverTitle;

  /// No description provided for @discoverSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Scanne, schlage etwas nach, höre zu oder mach eine kurze Übungspause. Entdecken ersetzt nie deinen heutigen Lernschritt.'**
  String get discoverSubtitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Suchen: Aussprache, Buch, OCR …'**
  String get discoverSearchHint;

  /// No description provided for @discoverStartHere.
  ///
  /// In de, this message translates to:
  /// **'Starte mit deiner Buchseite'**
  String get discoverStartHere;

  /// No description provided for @discoverAllTools.
  ///
  /// In de, this message translates to:
  /// **'Alle Funktionen'**
  String get discoverAllTools;

  /// No description provided for @discoverNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine passende Funktion gefunden.'**
  String get discoverNoResults;

  /// No description provided for @discoverNoResultsHint.
  ///
  /// In de, this message translates to:
  /// **'Versuche ein Bedürfnis wie Aussprache, Buch, Wiederholen oder Gespräch.'**
  String get discoverNoResultsHint;

  /// No description provided for @discoverCategoryAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get discoverCategoryAll;

  /// No description provided for @discoverCategoryLearn.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get discoverCategoryLearn;

  /// No description provided for @discoverCategoryPractice.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get discoverCategoryPractice;

  /// No description provided for @discoverCategoryWords.
  ///
  /// In de, this message translates to:
  /// **'Wörter & Bücher'**
  String get discoverCategoryWords;

  /// No description provided for @discoverCategoryProgress.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg'**
  String get discoverCategoryProgress;

  /// No description provided for @navLearn.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get navLearn;

  /// No description provided for @navPractice.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get navPractice;

  /// No description provided for @navWordbook.
  ///
  /// In de, this message translates to:
  /// **'Wörter'**
  String get navWordbook;

  /// No description provided for @navGye.
  ///
  /// In de, this message translates to:
  /// **'Gruppe'**
  String get navGye;

  /// No description provided for @gyeTabSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Zusammen lernen · Gye'**
  String get gyeTabSubtitle;

  /// No description provided for @gyeExplainWhat.
  ///
  /// In de, this message translates to:
  /// **'Ein Gye ist eine freiwillige kleine Gruppe zum Koreanischlernen. Allein zu lernen ist genauso vollständig.'**
  String get gyeExplainWhat;

  /// No description provided for @gyeExplainWhy.
  ///
  /// In de, this message translates to:
  /// **'Ein gemeinsames Hanok macht Ermutigung sichtbar. Es ist nie ein Wettbewerb und nie Voraussetzung für deinen Lernweg.'**
  String get gyeExplainWhy;

  /// No description provided for @gyeExplainHow.
  ///
  /// In de, this message translates to:
  /// **'Gründe eine Gruppe oder tritt mit einem 6-stelligen Code bei, wenn du bereit bist.'**
  String get gyeExplainHow;

  /// No description provided for @gyePrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Was andere sehen können'**
  String get gyePrivacyTitle;

  /// No description provided for @gyePrivacyBody.
  ///
  /// In de, this message translates to:
  /// **'Nur dass du in der Gruppe ein Paket abgeschlossen hast — niemals deine Antworten, gespeicherten Wörter oder Prüfungsergebnisse.'**
  String get gyePrivacyBody;

  /// No description provided for @gyeWeeklyEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche zusammen'**
  String get gyeWeeklyEyebrow;

  /// No description provided for @gyeWeeklyTitle.
  ///
  /// In de, this message translates to:
  /// **'Haltet gemeinsam die Lichter im Hof an.'**
  String get gyeWeeklyTitle;

  /// No description provided for @gyeWeeklyBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Zahl zeigt abgeschlossene Pakete in eurem aktuellen Gye. Sie ist kein Punktestand, keine Rangliste und kein Antwortprotokoll.'**
  String get gyeWeeklyBody;

  /// No description provided for @gyePromisePickerLabel.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Alltagsszene dieser Woche'**
  String get gyePromisePickerLabel;

  /// No description provided for @gyePromiseCafeOrder.
  ///
  /// In de, this message translates to:
  /// **'Drei Personen üben, höflich zu bestellen'**
  String get gyePromiseCafeOrder;

  /// No description provided for @gyePromiseDirections.
  ///
  /// In de, this message translates to:
  /// **'Drei Personen üben, nach dem Weg zu fragen'**
  String get gyePromiseDirections;

  /// No description provided for @gyePromiseSelfIntroduction.
  ///
  /// In de, this message translates to:
  /// **'Drei Personen üben, sich vorzustellen'**
  String get gyePromiseSelfIntroduction;

  /// No description provided for @gyePromiseEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche zusammen'**
  String get gyePromiseEyebrow;

  /// No description provided for @gyePromiseCafeOrderTitle.
  ///
  /// In de, this message translates to:
  /// **'Lasst drei Personen höflich bestellen üben.'**
  String get gyePromiseCafeOrderTitle;

  /// No description provided for @gyePromiseDirectionsTitle.
  ///
  /// In de, this message translates to:
  /// **'Lasst drei Personen nach dem Weg fragen üben.'**
  String get gyePromiseDirectionsTitle;

  /// No description provided for @gyePromiseSelfIntroductionTitle.
  ///
  /// In de, this message translates to:
  /// **'Lasst drei Personen sich vorstellen üben.'**
  String get gyePromiseSelfIntroductionTitle;

  /// No description provided for @gyePromiseBody.
  ///
  /// In de, this message translates to:
  /// **'Eine Laterne leuchtet nach einer kursgebundenen Szene mit mindestens 70 %. Antworten, Punkte und Mitwirkende bleiben privat.'**
  String get gyePromiseBody;

  /// No description provided for @gyePromiseProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {target} Laternen leuchten'**
  String gyePromiseProgress(int done, int target);

  /// No description provided for @gyePromiseRemaining.
  ///
  /// In de, this message translates to:
  /// **'Noch {count} {count, plural, =1{kursgebundener Szenenbeitrag} other{kursgebundene Szenenbeiträge}} diese Woche'**
  String gyePromiseRemaining(int count);

  /// No description provided for @gyeOpenToday.
  ///
  /// In de, this message translates to:
  /// **'Heutiges Lernen öffnen'**
  String get gyeOpenToday;

  /// No description provided for @gyeCourtyardEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Euer Hof'**
  String get gyeCourtyardEyebrow;

  /// No description provided for @gyeCourtyardTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein gemeinsamer Ort für kleine, sichere Ermutigung.'**
  String get gyeCourtyardTitle;

  /// No description provided for @gyeCourtyardBody.
  ///
  /// In de, this message translates to:
  /// **'Die Hofansicht folgt den vorhandenen Wochenziel-Daten. Sie ändert weder einen persönlichen Kurs noch ein persönliches Hanok.'**
  String get gyeCourtyardBody;

  /// No description provided for @gyeSafeMessage.
  ///
  /// In de, this message translates to:
  /// **'Sichere Ermutigung senden'**
  String get gyeSafeMessage;

  /// No description provided for @coachGyeTabTitle.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam lernen'**
  String get coachGyeTabTitle;

  /// No description provided for @coachGyeTabBody.
  ///
  /// In de, this message translates to:
  /// **'Eine Lerngruppe (Gye) ist eine kleine, nicht-kompetitive Gruppe. Euer Lernfortschritt lässt ein gemeinsames Hanok wachsen.'**
  String get coachGyeTabBody;

  /// No description provided for @motivationSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Warum lernst du Koreanisch?'**
  String get motivationSheetTitle;

  /// No description provided for @motivationSheetSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle deinen Grund. Dann können wir dich passend motivieren.'**
  String get motivationSheetSubtitle;

  /// No description provided for @motivationKpop.
  ///
  /// In de, this message translates to:
  /// **'K-Pop'**
  String get motivationKpop;

  /// No description provided for @motivationKdrama.
  ///
  /// In de, this message translates to:
  /// **'K-Dramas & Filme'**
  String get motivationKdrama;

  /// No description provided for @motivationTravel.
  ///
  /// In de, this message translates to:
  /// **'Reise nach Korea'**
  String get motivationTravel;

  /// No description provided for @motivationCulture.
  ///
  /// In de, this message translates to:
  /// **'Kultur & Sprache'**
  String get motivationCulture;

  /// No description provided for @motivationLoved.
  ///
  /// In de, this message translates to:
  /// **'Freunde & Familie'**
  String get motivationLoved;

  /// No description provided for @motivationCareer.
  ///
  /// In de, this message translates to:
  /// **'Beruf & Studium'**
  String get motivationCareer;

  /// No description provided for @motivationCurious.
  ///
  /// In de, this message translates to:
  /// **'Einfach neugierig'**
  String get motivationCurious;

  /// No description provided for @motivationLineKpop.
  ///
  /// In de, this message translates to:
  /// **'Bald verstehst du deine Lieblingssongs!'**
  String get motivationLineKpop;

  /// No description provided for @motivationLineKdrama.
  ///
  /// In de, this message translates to:
  /// **'Bald schaust du ohne Untertitel!'**
  String get motivationLineKdrama;

  /// No description provided for @motivationLineTravel.
  ///
  /// In de, this message translates to:
  /// **'Bald bestellst du in Seoul wie ein Local!'**
  String get motivationLineTravel;

  /// No description provided for @motivationLineCulture.
  ///
  /// In de, this message translates to:
  /// **'Jedes Wort öffnet eine neue Welt.'**
  String get motivationLineCulture;

  /// No description provided for @motivationLineLoved.
  ///
  /// In de, this message translates to:
  /// **'Sprich bald von Herzen mit ihnen!'**
  String get motivationLineLoved;

  /// No description provided for @motivationLineCareer.
  ///
  /// In de, this message translates to:
  /// **'Koreanisch öffnet neue Türen.'**
  String get motivationLineCareer;

  /// No description provided for @motivationLineCurious.
  ///
  /// In de, this message translates to:
  /// **'Neugier ist der beste Lehrer!'**
  String get motivationLineCurious;

  /// No description provided for @motivationChangeLabel.
  ///
  /// In de, this message translates to:
  /// **'Warum ich lerne'**
  String get motivationChangeLabel;

  /// No description provided for @homeDailyGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Tagesziel'**
  String get homeDailyGoalLabel;

  /// No description provided for @homeDailyGoalDone.
  ///
  /// In de, this message translates to:
  /// **'Tagesziel erreicht!'**
  String get homeDailyGoalDone;

  /// No description provided for @cultureNoteTitle.
  ///
  /// In de, this message translates to:
  /// **'K-Kultur'**
  String get cultureNoteTitle;

  /// No description provided for @milestoneStreakTitle.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Tag in Folge!} other{{count} Tage in Folge!}}'**
  String milestoneStreakTitle(int count);

  /// No description provided for @milestoneLevelTitle.
  ///
  /// In de, this message translates to:
  /// **'Level {count} erreicht!'**
  String milestoneLevelTitle(int count);

  /// No description provided for @milestoneVocabTitle.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort gelernt!} other{{count} Wörter gelernt!}}'**
  String milestoneVocabTitle(int count);

  /// No description provided for @milestoneStreakBody.
  ///
  /// In de, this message translates to:
  /// **'Regelmäßiges Lernen zahlt sich aus. Weiter so!'**
  String get milestoneStreakBody;

  /// No description provided for @milestoneLevelBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Koreanisch wächst mit jedem Tag.'**
  String get milestoneLevelBody;

  /// No description provided for @milestoneVocabBody.
  ///
  /// In de, this message translates to:
  /// **'Wort für Wort kommst du ans Ziel!'**
  String get milestoneVocabBody;

  /// No description provided for @milestoneCta.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get milestoneCta;

  /// No description provided for @feedbackCompletionContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get feedbackCompletionContinue;

  /// No description provided for @practiceEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Üben nach deinem Bedarf'**
  String get practiceEyebrow;

  /// No description provided for @practiceTitle.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du gerade festigen?'**
  String get practiceTitle;

  /// No description provided for @practiceSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle zuerst ein Bedürfnis. Dein einziger nächster Lernschritt bleibt auf Start.'**
  String get practiceSubtitle;

  /// No description provided for @practiceDueTitle.
  ///
  /// In de, this message translates to:
  /// **'Fällige Wörter wiederholen'**
  String get practiceDueTitle;

  /// No description provided for @practiceDueEmpty.
  ///
  /// In de, this message translates to:
  /// **'Öffne eine Wiederholung, wann du möchtest'**
  String get practiceDueEmpty;

  /// No description provided for @practiceSecLearn.
  ///
  /// In de, this message translates to:
  /// **'Etwas gezielt üben'**
  String get practiceSecLearn;

  /// No description provided for @practiceSecGames.
  ///
  /// In de, this message translates to:
  /// **'Frei spielen'**
  String get practiceSecGames;

  /// No description provided for @practiceSecWords.
  ///
  /// In de, this message translates to:
  /// **'Deine Wörter'**
  String get practiceSecWords;

  /// No description provided for @practiceSecSpace.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernraum'**
  String get practiceSecSpace;

  /// No description provided for @pathEvidenceTitle.
  ///
  /// In de, this message translates to:
  /// **'Woran du echten Fortschritt erkennst'**
  String get pathEvidenceTitle;

  /// No description provided for @pathEvidenceBody.
  ///
  /// In de, this message translates to:
  /// **'Freies Ansehen speichert nur Verlauf. Ein Kursabschnitt wird erst durch seine aktive Prüfung und mindestens 70 % in jeder verknüpften Szenenprüfung bestätigt.'**
  String get pathEvidenceBody;

  /// No description provided for @coachBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Buchseite einlesen'**
  String get coachBookTitle;

  /// No description provided for @coachBookStep1.
  ///
  /// In de, this message translates to:
  /// **'📸 Mach ein Foto von deinem Lehrbuch oder einer Speisekarte'**
  String get coachBookStep1;

  /// No description provided for @coachBookStep2.
  ///
  /// In de, this message translates to:
  /// **'🔍 Der Text wird automatisch erkannt und analysiert'**
  String get coachBookStep2;

  /// No description provided for @coachBookStep3.
  ///
  /// In de, this message translates to:
  /// **'Neue Wörter landen direkt in deiner Wortliste'**
  String get coachBookStep3;

  /// No description provided for @coachBookLimitNote.
  ///
  /// In de, this message translates to:
  /// **'Tageslimit: 20 Seiten'**
  String get coachBookLimitNote;

  /// No description provided for @coachVocabPackTitle.
  ///
  /// In de, this message translates to:
  /// **'In 3 Schritten lernen'**
  String get coachVocabPackTitle;

  /// No description provided for @coachVocabPackStep1.
  ///
  /// In de, this message translates to:
  /// **'Schritt 1 · Lernen: Karten umdrehen und einprägen'**
  String get coachVocabPackStep1;

  /// No description provided for @coachVocabPackStep2.
  ///
  /// In de, this message translates to:
  /// **'Schritt 2 · Quiz: Wähle die richtige Übersetzung'**
  String get coachVocabPackStep2;

  /// No description provided for @coachVocabPackStep3.
  ///
  /// In de, this message translates to:
  /// **'Schritt 3 · Boss: Hör zu und wähle die Bedeutung'**
  String get coachVocabPackStep3;

  /// No description provided for @coachPackStageQuiz.
  ///
  /// In de, this message translates to:
  /// **'Jetzt das Quiz! Wähle die richtige Übersetzung.'**
  String get coachPackStageQuiz;

  /// No description provided for @coachPackStageBoss.
  ///
  /// In de, this message translates to:
  /// **'Jetzt kommt der Boss. Hör genau hin!'**
  String get coachPackStageBoss;

  /// No description provided for @coachBtnGotIt.
  ///
  /// In de, this message translates to:
  /// **'Alles klar!'**
  String get coachBtnGotIt;

  /// No description provided for @previewSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get previewSkip;

  /// No description provided for @previewNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get previewNext;

  /// No description provided for @previewStart.
  ///
  /// In de, this message translates to:
  /// **'Loslegen'**
  String get previewStart;

  /// No description provided for @previewPage1Title.
  ///
  /// In de, this message translates to:
  /// **'Ein Foto statt 30-mal tippen'**
  String get previewPage1Title;

  /// No description provided for @previewPage1Body.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere eine Lehrbuchseite oder Speisekarte. Sori erkennt Wörter, Grammatik und Sätze und legt sie in dein Bücherregal. Das Bild bleibt auf deinem Gerät.'**
  String get previewPage1Body;

  /// No description provided for @previewPage2Title.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok wächst'**
  String get previewPage2Title;

  /// No description provided for @previewPage2Body.
  ///
  /// In de, this message translates to:
  /// **'Mit jedem gemeisterten Paket wächst dein Hanok: vom Sockel über die Säulen bis zum Ziegeldach und eigenen Jongga-Hof. Es gibt 12 Stufen.'**
  String get previewPage2Body;

  /// No description provided for @previewPage3Title.
  ///
  /// In de, this message translates to:
  /// **'5 Minuten am Tag genügen'**
  String get previewPage3Title;

  /// No description provided for @previewPage3Body.
  ///
  /// In de, this message translates to:
  /// **'Taego meldet sich einmal täglich und hält deinen Streak am Laufen. Und wenn ein Tag mal untergeht, fängt ihn der Streak-Schutz ab.'**
  String get previewPage3Body;

  /// No description provided for @hubLearnLevel.
  ///
  /// In de, this message translates to:
  /// **'Level {level}'**
  String hubLearnLevel(int level);

  /// No description provided for @hubLearnNextPack.
  ///
  /// In de, this message translates to:
  /// **'Weiter: {name}'**
  String hubLearnNextPack(String name);

  /// No description provided for @hubLearnAllDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Pakete abgeschlossen!'**
  String get hubLearnAllDone;

  /// No description provided for @hubPracticeStreak.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Tag in Folge} other{{n} Tage in Folge}}'**
  String hubPracticeStreak(int n);

  /// No description provided for @hubPracticeStreakZero.
  ///
  /// In de, this message translates to:
  /// **'Fang noch heute an!'**
  String get hubPracticeStreakZero;

  /// No description provided for @hubWordbookSaved.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort gespeichert} other{{n} Wörter gespeichert}}'**
  String hubWordbookSaved(int n);

  /// No description provided for @hubWordbookEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Wörter gespeichert'**
  String get hubWordbookEmpty;

  /// No description provided for @settingsTutorialResetSection.
  ///
  /// In de, this message translates to:
  /// **'Einführung'**
  String get settingsTutorialResetSection;

  /// No description provided for @settingsTutorialResetTitle.
  ///
  /// In de, this message translates to:
  /// **'Einführung zurücksetzen'**
  String get settingsTutorialResetTitle;

  /// No description provided for @settingsTutorialResetSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Karussell & Tipp-Hinweise beim nächsten Start neu anzeigen'**
  String get settingsTutorialResetSubtitle;

  /// No description provided for @settingsTutorialResetDone.
  ///
  /// In de, this message translates to:
  /// **'Einführung zurückgesetzt'**
  String get settingsTutorialResetDone;

  /// No description provided for @navTourNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get navTourNext;

  /// No description provided for @navTourSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get navTourSkip;

  /// No description provided for @navTourDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get navTourDone;

  /// No description provided for @coachHomeMissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Hier beginnt deine erste Mission'**
  String get coachHomeMissionTitle;

  /// No description provided for @coachHomeMissionBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf diese Karte. Hangul Sori sucht dir jeden Tag eine passende Aufgabe aus.'**
  String get coachHomeMissionBody;

  /// No description provided for @coachPracticeHubTitle.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get coachPracticeHubTitle;

  /// No description provided for @coachPracticeHubBody.
  ///
  /// In de, this message translates to:
  /// **'Hier findest du Spiele, Wörter und Grammatik zum Wiederholen.'**
  String get coachPracticeHubBody;

  /// No description provided for @coachHomeTab0Title.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get coachHomeTab0Title;

  /// No description provided for @coachHomeTab0Body.
  ///
  /// In de, this message translates to:
  /// **'Lernpfad & heutige Aufgaben an einem Ort'**
  String get coachHomeTab0Body;

  /// No description provided for @coachHomeTab1Title.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get coachHomeTab1Title;

  /// No description provided for @coachHomeTab1Body.
  ///
  /// In de, this message translates to:
  /// **'Spiele, Wörter & Grammatik zum Wiederholen'**
  String get coachHomeTab1Body;

  /// No description provided for @coachHomeTab2Title.
  ///
  /// In de, this message translates to:
  /// **'Gye'**
  String get coachHomeTab2Title;

  /// No description provided for @coachHomeTab2Body.
  ///
  /// In de, this message translates to:
  /// **'Erreicht gemeinsam eure Lernziele'**
  String get coachHomeTab2Body;

  /// No description provided for @coachHomeTab3Title.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get coachHomeTab3Title;

  /// No description provided for @coachHomeTab3Body.
  ///
  /// In de, this message translates to:
  /// **'Statistiken, Einstellungen & Konto'**
  String get coachHomeTab3Body;

  /// No description provided for @coachHomePathTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernpfad'**
  String get coachHomePathTitle;

  /// No description provided for @coachHomePathBody.
  ///
  /// In de, this message translates to:
  /// **'Schließ die Pakete der Reihe nach ab. Der Tiger wächst mit dir.'**
  String get coachHomePathBody;

  /// No description provided for @coachHomeBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Buchschnappschuss'**
  String get coachHomeBookTitle;

  /// No description provided for @coachHomeBookBody.
  ///
  /// In de, this message translates to:
  /// **'Foto von deinem Lehrbuch direkt in die Wortliste'**
  String get coachHomeBookBody;

  /// No description provided for @introSkipHint.
  ///
  /// In de, this message translates to:
  /// **'Zum Überspringen tippen'**
  String get introSkipHint;

  /// No description provided for @bookCaptureWebNotice.
  ///
  /// In de, this message translates to:
  /// **'📱 „Buchseite einlesen“ funktioniert nur in der mobilen App (Kamera + Texterkennung auf dem Gerät).'**
  String get bookCaptureWebNotice;

  /// No description provided for @bookshelfCreatePackNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Schritt 1: Lektion 5'**
  String get bookshelfCreatePackNameHint;

  /// No description provided for @settingsMadeWith.
  ///
  /// In de, this message translates to:
  /// **'Mit ❤ in Deutschland gemacht'**
  String get settingsMadeWith;

  /// No description provided for @coachChosungStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Silben-Puzzle'**
  String get coachChosungStep1Title;

  /// No description provided for @coachChosungStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Füll die gepunkteten Felder aus und vervollständige das Wort'**
  String get coachChosungStep1Body;

  /// No description provided for @coachChosungStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Niveau & Schwierigkeit'**
  String get coachChosungStep2Title;

  /// No description provided for @coachChosungStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Level von A1 bis B2 und ob Vokale angezeigt werden'**
  String get coachChosungStep2Body;

  /// No description provided for @coachChosungStep3Title.
  ///
  /// In de, this message translates to:
  /// **'Antwort eingeben'**
  String get coachChosungStep3Title;

  /// No description provided for @coachChosungStep3Body.
  ///
  /// In de, this message translates to:
  /// **'Gib das vollständige koreanische Wort ein und bestätige'**
  String get coachChosungStep3Body;

  /// No description provided for @coachWordleStep1Title.
  ///
  /// In de, this message translates to:
  /// **'6 Versuche'**
  String get coachWordleStep1Title;

  /// No description provided for @coachWordleStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Rate das gesuchte Wort. Du hast 6 Versuche.'**
  String get coachWordleStep1Body;

  /// No description provided for @coachWordleStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Hinweise nutzen'**
  String get coachWordleStep2Title;

  /// No description provided for @coachWordleStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Silbenzahl, Wortart und Bedeutung helfen dir beim Raten'**
  String get coachWordleStep2Body;

  /// No description provided for @coachWordleStep3Title.
  ///
  /// In de, this message translates to:
  /// **'Eingabe & Farben'**
  String get coachWordleStep3Title;

  /// No description provided for @coachWordleStep3Body.
  ///
  /// In de, this message translates to:
  /// **'Eingabe → Enter · 🟩 richtig · 🟨 falsche Position · ⬜ nicht enthalten'**
  String get coachWordleStep3Body;

  /// No description provided for @coachKkeunmariStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Letzter Buchstabe zählt'**
  String get coachKkeunmariStep1Title;

  /// No description provided for @coachKkeunmariStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Fang dein Wort mit der hervorgehobenen Endsilbe an'**
  String get coachKkeunmariStep1Body;

  /// No description provided for @coachKkeunmariStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Zug & Timer'**
  String get coachKkeunmariStep2Title;

  /// No description provided for @coachKkeunmariStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Du hast 30 Sekunden pro Zug. Kannst du den Tiger schlagen?'**
  String get coachKkeunmariStep2Body;

  /// No description provided for @coachKkeunmariStep3Title.
  ///
  /// In de, this message translates to:
  /// **'Wort eingeben'**
  String get coachKkeunmariStep3Title;

  /// No description provided for @coachKkeunmariStep3Body.
  ///
  /// In de, this message translates to:
  /// **'Gib ein gültiges koreanisches Wort ein. Der Tiger antwortet automatisch.'**
  String get coachKkeunmariStep3Body;

  /// No description provided for @coachListeningStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Situation wählen'**
  String get coachListeningStep1Title;

  /// No description provided for @coachListeningStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Karte, um die passende Situation auszuwählen'**
  String get coachListeningStep1Body;

  /// No description provided for @coachListeningStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Tempo & Untertitel'**
  String get coachListeningStep2Title;

  /// No description provided for @coachListeningStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Stelle die Geschwindigkeit von 0,75× bis 1,25× und den Untertitelmodus ein'**
  String get coachListeningStep2Body;

  /// No description provided for @coachListeningStep3Title.
  ///
  /// In de, this message translates to:
  /// **'Zeile für Zeile'**
  String get coachListeningStep3Title;

  /// No description provided for @coachListeningStep3Body.
  ///
  /// In de, this message translates to:
  /// **'Hör zu und tippe ⟳ zum Wiederholen oder Weiter zur nächsten Zeile'**
  String get coachListeningStep3Body;

  /// No description provided for @coachHangulTitle.
  ///
  /// In de, this message translates to:
  /// **'Drei Tabs zum Hangul-Lernen'**
  String get coachHangulTitle;

  /// No description provided for @coachHangulBody.
  ///
  /// In de, this message translates to:
  /// **'Übersicht zeigt alle Zeichen · Karten helfen beim Üben · Schreiben trainiert den Strich'**
  String get coachHangulBody;

  /// No description provided for @coachGrammarStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Karte umdrehen'**
  String get coachGrammarStep1Title;

  /// No description provided for @coachGrammarStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte, um Erklärung und Beispiele zu sehen'**
  String get coachGrammarStep1Body;

  /// No description provided for @coachGrammarStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Filtern & markieren'**
  String get coachGrammarStep2Title;

  /// No description provided for @coachGrammarStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Wähle Niveau oder Typ. Markiere schwierige Karten mit 🤔 als schwer.'**
  String get coachGrammarStep2Body;

  /// No description provided for @coachSmalltalkStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Thema auswählen'**
  String get coachSmalltalkStep1Title;

  /// No description provided for @coachSmalltalkStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf das Themenfeld, um aus 18 Kategorien zu wählen'**
  String get coachSmalltalkStep1Body;

  /// No description provided for @coachSmalltalkStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Aussprache & Wörterbuch'**
  String get coachSmalltalkStep2Title;

  /// No description provided for @coachSmalltalkStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Karte, um sie anzuhören. Mit ＋ speicherst du den Ausdruck in deiner Wortliste.'**
  String get coachSmalltalkStep2Body;

  /// No description provided for @coachScenarioStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Schritt für Schritt'**
  String get coachScenarioStep1Title;

  /// No description provided for @coachScenarioStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Vokabeln → Dialog → Grammatik → Quests → Ergebnis. Geh diese Schritte der Reihe nach durch.'**
  String get coachScenarioStep1Body;

  /// No description provided for @coachScenarioStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Weiter & Fortschritt'**
  String get coachScenarioStep2Title;

  /// No description provided for @coachScenarioStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe Weiter zum nächsten Schritt · der Balken oben zeigt deinen Fortschritt'**
  String get coachScenarioStep2Body;

  /// No description provided for @coachReviewStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Karte aufdecken'**
  String get coachReviewStep1Title;

  /// No description provided for @coachReviewStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Denk zuerst an die Bedeutung. Tippe dann auf die Karte, um die Antwort zu sehen.'**
  String get coachReviewStep1Body;

  /// No description provided for @coachReviewStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Gewusst oder nicht?'**
  String get coachReviewStep2Title;

  /// No description provided for @coachReviewStep2Body.
  ///
  /// In de, this message translates to:
  /// **'\"Gewusst\" verlängert das Intervall · \"Nicht gewusst\" bringt die Karte früher zurück'**
  String get coachReviewStep2Body;

  /// No description provided for @coachLegacyVocabTitle.
  ///
  /// In de, this message translates to:
  /// **'Karteikarte'**
  String get coachLegacyVocabTitle;

  /// No description provided for @coachLegacyVocabBody.
  ///
  /// In de, this message translates to:
  /// **'Antippen = umdrehen · lang halten = langsam vorlesen lassen'**
  String get coachLegacyVocabBody;

  /// No description provided for @coachLearningPathTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernpfad'**
  String get coachLearningPathTitle;

  /// No description provided for @coachLearningPathBody.
  ///
  /// In de, this message translates to:
  /// **'Starte beim orangen \"Jetzt\"-Knoten und arbeite dich Schritt für Schritt vor'**
  String get coachLearningPathBody;

  /// No description provided for @coachBookshelfStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Wörterbuch erstellen'**
  String get coachBookshelfStep1Title;

  /// No description provided for @coachBookshelfStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ＋ oben rechts, um ein eigenes Wörterbuch anzulegen'**
  String get coachBookshelfStep1Body;

  /// No description provided for @coachBookshelfStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter suchen'**
  String get coachBookshelfStep2Title;

  /// No description provided for @coachBookshelfStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf 🔍, um alle gespeicherten Wörter zu durchsuchen und nach Wortart zu filtern'**
  String get coachBookshelfStep2Body;

  /// No description provided for @coachCpEditStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Wörter hinzufügen'**
  String get coachCpEditStep1Title;

  /// No description provided for @coachCpEditStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ＋ Wort hinzufügen · oder importiere per CSV · Foto · Auto-Ausfüllen'**
  String get coachCpEditStep1Body;

  /// No description provided for @coachCpEditStep2Title.
  ///
  /// In de, this message translates to:
  /// **'4 Lernmodi'**
  String get coachCpEditStep2Title;

  /// No description provided for @coachCpEditStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Karten · Zuordnen · Schreiben · Quiz. Wähle den Modus, der zu dir passt.'**
  String get coachCpEditStep2Body;

  /// No description provided for @coachCpPlayTitle.
  ///
  /// In de, this message translates to:
  /// **'Karteikarten lernen'**
  String get coachCpPlayTitle;

  /// No description provided for @coachCpPlayBody.
  ///
  /// In de, this message translates to:
  /// **'Antippen = Karte umdrehen · \"Gewusst\" = Wort zum SRS-System hinzufügen'**
  String get coachCpPlayBody;

  /// No description provided for @coachCpQuizTitle.
  ///
  /// In de, this message translates to:
  /// **'Bedeutung erraten'**
  String get coachCpQuizTitle;

  /// No description provided for @coachCpQuizBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle die richtige Bedeutung. Dein Ergebnis wird für die Wiederholung gespeichert.'**
  String get coachCpQuizBody;

  /// No description provided for @coachCpMatchingTitle.
  ///
  /// In de, this message translates to:
  /// **'Paare zuordnen'**
  String get coachCpMatchingTitle;

  /// No description provided for @coachCpMatchingBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe links ein koreanisches Wort an, dann rechts die passende Bedeutung'**
  String get coachCpMatchingBody;

  /// No description provided for @coachCpTypingTitle.
  ///
  /// In de, this message translates to:
  /// **'Wort eintippen'**
  String get coachCpTypingTitle;

  /// No description provided for @coachCpTypingBody.
  ///
  /// In de, this message translates to:
  /// **'Sieh die Bedeutung und tippe das koreanische Wort ein. Das trainiert mehr als bloßes Wiedererkennen.'**
  String get coachCpTypingBody;

  /// No description provided for @coachHardWordsTitle.
  ///
  /// In de, this message translates to:
  /// **'Hartnäckige Wörter'**
  String get coachHardWordsTitle;

  /// No description provided for @coachHardWordsBody.
  ///
  /// In de, this message translates to:
  /// **'Hier findest du Wörter, die dir noch schwerfallen. Du kannst sie gezielt wiederholen.'**
  String get coachHardWordsBody;

  /// No description provided for @coachDojangTitle.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Stempel sammeln'**
  String get coachDojangTitle;

  /// No description provided for @coachDojangBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe Vokabelpacks ab, um alle 8 Dancheong-Muster freizuschalten'**
  String get coachDojangBody;

  /// No description provided for @coachGyeStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Wochenziel'**
  String get coachGyeStep1Title;

  /// No description provided for @coachGyeStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Hier seht ihr euren gemeinsamen Fortschritt. Zusammen bleibt ihr leichter dran.'**
  String get coachGyeStep1Body;

  /// No description provided for @coachGyeStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Sticker senden'**
  String get coachGyeStep2Title;

  /// No description provided for @coachGyeStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf den Smiley-Button, um ein Sticker zur Motivation zu senden'**
  String get coachGyeStep2Body;

  /// No description provided for @coachProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Konto'**
  String get coachProfileTitle;

  /// No description provided for @coachProfileBody.
  ///
  /// In de, this message translates to:
  /// **'Verbinde dich mit Google. So bleiben Streak und Vokabeln bei einem Handywechsel erhalten.'**
  String get coachProfileBody;

  /// No description provided for @coachStatsTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernstatistiken'**
  String get coachStatsTitle;

  /// No description provided for @coachStatsBody.
  ///
  /// In de, this message translates to:
  /// **'Streak, XP und Trefferquote zeigen, wie weit du schon gekommen bist'**
  String get coachStatsBody;

  /// No description provided for @coachQuestsTitle.
  ///
  /// In de, this message translates to:
  /// **'Quests & Belohnungen'**
  String get coachQuestsTitle;

  /// No description provided for @coachQuestsBody.
  ///
  /// In de, this message translates to:
  /// **'Erledige Quests und erhalte Dekorationen für deine Hanok-Stuben'**
  String get coachQuestsBody;

  /// No description provided for @coachScenariosTitle.
  ///
  /// In de, this message translates to:
  /// **'Situationsgespräche'**
  String get coachScenariosTitle;

  /// No description provided for @coachScenariosBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein Szenario und übe echte Alltagssituationen. Sie werden ab A2 freigeschaltet.'**
  String get coachScenariosBody;

  /// No description provided for @questSatzBauenInstruction.
  ///
  /// In de, this message translates to:
  /// **'Tippe die Wörter in der richtigen Reihenfolge an'**
  String get questSatzBauenInstruction;

  /// No description provided for @questCheckAnswer.
  ///
  /// In de, this message translates to:
  /// **'Überprüfen'**
  String get questCheckAnswer;

  /// No description provided for @diktatInstruction.
  ///
  /// In de, this message translates to:
  /// **'Hör zu und tippe, was du hörst'**
  String get diktatInstruction;

  /// No description provided for @diktatSpacingHint.
  ///
  /// In de, this message translates to:
  /// **'Fast! Achte auf die Wortabstände'**
  String get diktatSpacingHint;

  /// No description provided for @diktatShowMeaning.
  ///
  /// In de, this message translates to:
  /// **'Bedeutung zeigen'**
  String get diktatShowMeaning;

  /// No description provided for @diktatSpellingHint.
  ///
  /// In de, this message translates to:
  /// **'Fast richtig. Achte auf die Schreibweise.'**
  String get diktatSpellingHint;

  /// No description provided for @questDiagOrder.
  ///
  /// In de, this message translates to:
  /// **'Die Wörter stimmen, aber die Reihenfolge noch nicht.'**
  String get questDiagOrder;

  /// No description provided for @questDiagParticle.
  ///
  /// In de, this message translates to:
  /// **'Fast! Achte auf die Partikel (조사)'**
  String get questDiagParticle;

  /// No description provided for @questDiagCount.
  ///
  /// In de, this message translates to:
  /// **'Achte auf die Anzahl der Wörter'**
  String get questDiagCount;

  /// No description provided for @questDiagWord.
  ///
  /// In de, this message translates to:
  /// **'Ein Wort passt nicht. Schau dir das markierte Wort an.'**
  String get questDiagWord;

  /// No description provided for @scenarioRoleplayTitle.
  ///
  /// In de, this message translates to:
  /// **'Rollenspiel'**
  String get scenarioRoleplayTitle;

  /// No description provided for @scenarioRoleplayHint.
  ///
  /// In de, this message translates to:
  /// **'Jetzt bist du dran. Formuliere deine eigene Antwort.'**
  String get scenarioRoleplayHint;

  /// No description provided for @scenarioRoleplayTurn.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort'**
  String get scenarioRoleplayTurn;

  /// No description provided for @scenarioRoleplayDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Rollenspiel geschafft!'**
  String get scenarioRoleplayDoneTitle;

  /// No description provided for @scenarioRoleplayDoneBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast das Gespräch selbst geführt.'**
  String get scenarioRoleplayDoneBody;

  /// No description provided for @testerFeedbackCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Tiger-Check'**
  String get testerFeedbackCardTitle;

  /// No description provided for @testerFeedbackCardBody.
  ///
  /// In de, this message translates to:
  /// **'Zwei kurze Auswahlen helfen uns, Hangul Sori besser zu machen.'**
  String get testerFeedbackCardBody;

  /// No description provided for @testerFeedbackCardCta.
  ///
  /// In de, this message translates to:
  /// **'Gib dem Tiger einen Hinweis'**
  String get testerFeedbackCardCta;

  /// No description provided for @testerFeedbackCategoryBug.
  ///
  /// In de, this message translates to:
  /// **'Fehler melden'**
  String get testerFeedbackCategoryBug;

  /// No description provided for @testerFeedbackCategoryContent.
  ///
  /// In de, this message translates to:
  /// **'Lerninhalt bewerten'**
  String get testerFeedbackCategoryContent;

  /// No description provided for @testerFeedbackCategoryOther.
  ///
  /// In de, this message translates to:
  /// **'Etwas anderes'**
  String get testerFeedbackCategoryOther;

  /// No description provided for @testerFeedbackIssueAreaLabel.
  ///
  /// In de, this message translates to:
  /// **'Was betrifft das Problem?'**
  String get testerFeedbackIssueAreaLabel;

  /// No description provided for @testerFeedbackIssueAreaUi.
  ///
  /// In de, this message translates to:
  /// **'Anzeige'**
  String get testerFeedbackIssueAreaUi;

  /// No description provided for @testerFeedbackIssueAreaAnswer.
  ///
  /// In de, this message translates to:
  /// **'Antwort'**
  String get testerFeedbackIssueAreaAnswer;

  /// No description provided for @testerFeedbackIssueAreaAudio.
  ///
  /// In de, this message translates to:
  /// **'Audio'**
  String get testerFeedbackIssueAreaAudio;

  /// No description provided for @testerFeedbackIssueAreaTranslation.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung'**
  String get testerFeedbackIssueAreaTranslation;

  /// No description provided for @testerFeedbackIssueAreaNavigation.
  ///
  /// In de, this message translates to:
  /// **'Navigation'**
  String get testerFeedbackIssueAreaNavigation;

  /// No description provided for @testerFeedbackIssueAreaOther.
  ///
  /// In de, this message translates to:
  /// **'Etwas anderes'**
  String get testerFeedbackIssueAreaOther;

  /// No description provided for @testerFeedbackContentSignalLabel.
  ///
  /// In de, this message translates to:
  /// **'Wie war diese Übung für dich?'**
  String get testerFeedbackContentSignalLabel;

  /// No description provided for @testerFeedbackContentSignalTooEasy.
  ///
  /// In de, this message translates to:
  /// **'Zu leicht'**
  String get testerFeedbackContentSignalTooEasy;

  /// No description provided for @testerFeedbackContentSignalRight.
  ///
  /// In de, this message translates to:
  /// **'Genau richtig'**
  String get testerFeedbackContentSignalRight;

  /// No description provided for @testerFeedbackContentSignalTooHard.
  ///
  /// In de, this message translates to:
  /// **'Zu schwer'**
  String get testerFeedbackContentSignalTooHard;

  /// No description provided for @testerFeedbackContentSignalUnclear.
  ///
  /// In de, this message translates to:
  /// **'Unklar'**
  String get testerFeedbackContentSignalUnclear;

  /// No description provided for @testerFeedbackContentFocusLabel.
  ///
  /// In de, this message translates to:
  /// **'Woran lag es?'**
  String get testerFeedbackContentFocusLabel;

  /// No description provided for @testerFeedbackContentFocusExplanation.
  ///
  /// In de, this message translates to:
  /// **'Erklärung'**
  String get testerFeedbackContentFocusExplanation;

  /// No description provided for @testerFeedbackContentFocusExamples.
  ///
  /// In de, this message translates to:
  /// **'Beispiele'**
  String get testerFeedbackContentFocusExamples;

  /// No description provided for @testerFeedbackContentFocusQuestions.
  ///
  /// In de, this message translates to:
  /// **'Aufgaben'**
  String get testerFeedbackContentFocusQuestions;

  /// No description provided for @testerFeedbackContentFocusPace.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get testerFeedbackContentFocusPace;

  /// No description provided for @testerFeedbackContentFocusAudio.
  ///
  /// In de, this message translates to:
  /// **'Audio'**
  String get testerFeedbackContentFocusAudio;

  /// No description provided for @testerFeedbackContentFocusTranslation.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung'**
  String get testerFeedbackContentFocusTranslation;

  /// No description provided for @testerFeedbackContentFocusOther.
  ///
  /// In de, this message translates to:
  /// **'Etwas anderes'**
  String get testerFeedbackContentFocusOther;

  /// No description provided for @testerFeedbackPulseLearningPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wie war diese Übung für dich?'**
  String get testerFeedbackPulseLearningPrompt;

  /// No description provided for @testerFeedbackPulseBookPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wie zuverlässig wirkte dieses Ergebnis?'**
  String get testerFeedbackPulseBookPrompt;

  /// No description provided for @testerFeedbackPulseQuestPrompt.
  ///
  /// In de, this message translates to:
  /// **'Hat sich diese Quest gelohnt?'**
  String get testerFeedbackPulseQuestPrompt;

  /// No description provided for @testerFeedbackPulseMilestonePrompt.
  ///
  /// In de, this message translates to:
  /// **'Hat dich diese Feier motiviert?'**
  String get testerFeedbackPulseMilestonePrompt;

  /// No description provided for @testerFeedbackPulseReasonPrompt.
  ///
  /// In de, this message translates to:
  /// **'Woran lag es?'**
  String get testerFeedbackPulseReasonPrompt;

  /// No description provided for @testerFeedbackPulsePositiveReasonPrompt.
  ///
  /// In de, this message translates to:
  /// **'Was hat gut funktioniert?'**
  String get testerFeedbackPulsePositiveReasonPrompt;

  /// No description provided for @testerFeedbackExperienceReasonPrompt.
  ///
  /// In de, this message translates to:
  /// **'Was hat deine Einschätzung beeinflusst?'**
  String get testerFeedbackExperienceReasonPrompt;

  /// No description provided for @testerFeedbackBookSignalPositive.
  ///
  /// In de, this message translates to:
  /// **'Wirkt richtig'**
  String get testerFeedbackBookSignalPositive;

  /// No description provided for @testerFeedbackBookSignalMixed.
  ///
  /// In de, this message translates to:
  /// **'Teilweise richtig'**
  String get testerFeedbackBookSignalMixed;

  /// No description provided for @testerFeedbackBookSignalNegative.
  ///
  /// In de, this message translates to:
  /// **'Wirkt nicht richtig'**
  String get testerFeedbackBookSignalNegative;

  /// No description provided for @testerFeedbackBookSignalUnsure.
  ///
  /// In de, this message translates to:
  /// **'Nicht sicher'**
  String get testerFeedbackBookSignalUnsure;

  /// No description provided for @testerFeedbackQuestSignalPositive.
  ///
  /// In de, this message translates to:
  /// **'Sehr motivierend'**
  String get testerFeedbackQuestSignalPositive;

  /// No description provided for @testerFeedbackQuestSignalMixed.
  ///
  /// In de, this message translates to:
  /// **'Nettes Extra'**
  String get testerFeedbackQuestSignalMixed;

  /// No description provided for @testerFeedbackQuestSignalNegative.
  ///
  /// In de, this message translates to:
  /// **'Nicht motivierend'**
  String get testerFeedbackQuestSignalNegative;

  /// No description provided for @testerFeedbackQuestSignalUnsure.
  ///
  /// In de, this message translates to:
  /// **'Nicht verstanden'**
  String get testerFeedbackQuestSignalUnsure;

  /// No description provided for @testerFeedbackMilestoneSignalPositive.
  ///
  /// In de, this message translates to:
  /// **'Hat mich gefreut'**
  String get testerFeedbackMilestoneSignalPositive;

  /// No description provided for @testerFeedbackMilestoneSignalMixed.
  ///
  /// In de, this message translates to:
  /// **'Schön'**
  String get testerFeedbackMilestoneSignalMixed;

  /// No description provided for @testerFeedbackMilestoneSignalNegative.
  ///
  /// In de, this message translates to:
  /// **'Zu viel'**
  String get testerFeedbackMilestoneSignalNegative;

  /// No description provided for @testerFeedbackMilestoneSignalUnsure.
  ///
  /// In de, this message translates to:
  /// **'Nicht bedeutsam'**
  String get testerFeedbackMilestoneSignalUnsure;

  /// No description provided for @testerFeedbackExperienceFocusKoreanText.
  ///
  /// In de, this message translates to:
  /// **'Koreanischer Text'**
  String get testerFeedbackExperienceFocusKoreanText;

  /// No description provided for @testerFeedbackExperienceFocusWordMeanings.
  ///
  /// In de, this message translates to:
  /// **'Wortbedeutungen'**
  String get testerFeedbackExperienceFocusWordMeanings;

  /// No description provided for @testerFeedbackExperienceFocusGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get testerFeedbackExperienceFocusGrammar;

  /// No description provided for @testerFeedbackExperienceFocusTranslation.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung'**
  String get testerFeedbackExperienceFocusTranslation;

  /// No description provided for @testerFeedbackExperienceFocusResultMissing.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis fehlt'**
  String get testerFeedbackExperienceFocusResultMissing;

  /// No description provided for @testerFeedbackExperienceFocusGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get testerFeedbackExperienceFocusGoal;

  /// No description provided for @testerFeedbackExperienceFocusDifficulty.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get testerFeedbackExperienceFocusDifficulty;

  /// No description provided for @testerFeedbackExperienceFocusReward.
  ///
  /// In de, this message translates to:
  /// **'Belohnung'**
  String get testerFeedbackExperienceFocusReward;

  /// No description provided for @testerFeedbackExperienceFocusInstructions.
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get testerFeedbackExperienceFocusInstructions;

  /// No description provided for @testerFeedbackExperienceFocusLength.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get testerFeedbackExperienceFocusLength;

  /// No description provided for @testerFeedbackExperienceFocusTiming.
  ///
  /// In de, this message translates to:
  /// **'Zeitpunkt'**
  String get testerFeedbackExperienceFocusTiming;

  /// No description provided for @testerFeedbackExperienceFocusVisuals.
  ///
  /// In de, this message translates to:
  /// **'Optik'**
  String get testerFeedbackExperienceFocusVisuals;

  /// No description provided for @testerFeedbackExperienceFocusMessage.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get testerFeedbackExperienceFocusMessage;

  /// No description provided for @testerFeedbackExperienceFocusFrequency.
  ///
  /// In de, this message translates to:
  /// **'Häufigkeit'**
  String get testerFeedbackExperienceFocusFrequency;

  /// No description provided for @testerFeedbackExperienceFocusOther.
  ///
  /// In de, this message translates to:
  /// **'Etwas anderes'**
  String get testerFeedbackExperienceFocusOther;

  /// No description provided for @testerFeedbackBugExpectedLabel.
  ///
  /// In de, this message translates to:
  /// **'Was sollte passieren?'**
  String get testerFeedbackBugExpectedLabel;

  /// No description provided for @testerFeedbackBugExpectedHint.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe kurz das erwartete Verhalten.'**
  String get testerFeedbackBugExpectedHint;

  /// No description provided for @testerFeedbackBugActualLabel.
  ///
  /// In de, this message translates to:
  /// **'Was ist stattdessen passiert?'**
  String get testerFeedbackBugActualLabel;

  /// No description provided for @testerFeedbackBugActualHint.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe kurz das tatsächliche Verhalten.'**
  String get testerFeedbackBugActualHint;

  /// No description provided for @testerFeedbackBugFrequencyLabel.
  ///
  /// In de, this message translates to:
  /// **'Wie oft ist das passiert?'**
  String get testerFeedbackBugFrequencyLabel;

  /// No description provided for @testerFeedbackBugFrequencyEveryTime.
  ///
  /// In de, this message translates to:
  /// **'Jedes Mal'**
  String get testerFeedbackBugFrequencyEveryTime;

  /// No description provided for @testerFeedbackBugFrequencySometimes.
  ///
  /// In de, this message translates to:
  /// **'Manchmal'**
  String get testerFeedbackBugFrequencySometimes;

  /// No description provided for @testerFeedbackBugFrequencyOnce.
  ///
  /// In de, this message translates to:
  /// **'Einmal'**
  String get testerFeedbackBugFrequencyOnce;

  /// No description provided for @testerFeedbackBugImpactLabel.
  ///
  /// In de, this message translates to:
  /// **'Wie stark hat es dich beeinträchtigt?'**
  String get testerFeedbackBugImpactLabel;

  /// No description provided for @testerFeedbackBugImpactCanContinue.
  ///
  /// In de, this message translates to:
  /// **'Ich konnte weitermachen'**
  String get testerFeedbackBugImpactCanContinue;

  /// No description provided for @testerFeedbackBugImpactSlowsLearning.
  ///
  /// In de, this message translates to:
  /// **'Es hat mich aufgehalten'**
  String get testerFeedbackBugImpactSlowsLearning;

  /// No description provided for @testerFeedbackBugImpactBlocksLearning.
  ///
  /// In de, this message translates to:
  /// **'Ich konnte nicht weitermachen'**
  String get testerFeedbackBugImpactBlocksLearning;

  /// No description provided for @testerFeedbackBugRequired.
  ///
  /// In de, this message translates to:
  /// **'Fülle bitte alle Pflichtfelder des Fehlerberichts aus.'**
  String get testerFeedbackBugRequired;

  /// No description provided for @testerFeedbackMessageLabel.
  ///
  /// In de, this message translates to:
  /// **'Optionaler Hinweis'**
  String get testerFeedbackMessageLabel;

  /// No description provided for @testerFeedbackMessageHint.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du noch etwas ergänzen?'**
  String get testerFeedbackMessageHint;

  /// No description provided for @testerFeedbackOtherMessageLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein Hinweis'**
  String get testerFeedbackOtherMessageLabel;

  /// No description provided for @testerFeedbackOtherMessageHint.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du uns noch sagen?'**
  String get testerFeedbackOtherMessageHint;

  /// No description provided for @testerFeedbackMessageRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte schreibe eine kurze Nachricht.'**
  String get testerFeedbackMessageRequired;

  /// No description provided for @testerFeedbackContentFeedbackRequired.
  ///
  /// In de, this message translates to:
  /// **'Wähle bitte ein Signal und einen Schwerpunkt aus.'**
  String get testerFeedbackContentFeedbackRequired;

  /// No description provided for @testerFeedbackMessageTooLong.
  ///
  /// In de, this message translates to:
  /// **'Deine Nachricht darf höchstens 1.000 Zeichen lang sein.'**
  String get testerFeedbackMessageTooLong;

  /// No description provided for @testerFeedbackSubmit.
  ///
  /// In de, this message translates to:
  /// **'Check senden'**
  String get testerFeedbackSubmit;

  /// No description provided for @testerFeedbackCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get testerFeedbackCancel;

  /// No description provided for @testerFeedbackBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get testerFeedbackBack;

  /// No description provided for @testerFeedbackSubmitting.
  ///
  /// In de, this message translates to:
  /// **'Feedback wird gesendet …'**
  String get testerFeedbackSubmitting;

  /// No description provided for @testerFeedbackSubmitted.
  ///
  /// In de, this message translates to:
  /// **'Danke. Dein Feedback hilft uns, besser zu werden.'**
  String get testerFeedbackSubmitted;

  /// No description provided for @testerFeedbackStampAccepted.
  ///
  /// In de, this message translates to:
  /// **'Stempel gesammelt!'**
  String get testerFeedbackStampAccepted;

  /// No description provided for @testerFeedbackPending.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät gespeichert. Wir senden es, sobald du wieder online bist.'**
  String get testerFeedbackPending;

  /// No description provided for @testerFeedbackSubmitFailed.
  ///
  /// In de, this message translates to:
  /// **'Feedback konnte noch nicht gesendet werden.'**
  String get testerFeedbackSubmitFailed;

  /// No description provided for @testerFeedbackRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get testerFeedbackRetry;

  /// No description provided for @testerFeedbackPrivacyReminder.
  ///
  /// In de, this message translates to:
  /// **'Nenne bitte keine Kontaktdaten, Antworten, persönlichen Daten oder Screenshots.'**
  String get testerFeedbackPrivacyReminder;

  /// No description provided for @testerFeedbackMissionScenario.
  ///
  /// In de, this message translates to:
  /// **'Ein Szenario abschließen'**
  String get testerFeedbackMissionScenario;

  /// No description provided for @testerFeedbackMissionWordWork.
  ///
  /// In de, this message translates to:
  /// **'Mit Wörtern üben'**
  String get testerFeedbackMissionWordWork;

  /// No description provided for @testerFeedbackMissionListening.
  ///
  /// In de, this message translates to:
  /// **'Eine Hörübung abschließen'**
  String get testerFeedbackMissionListening;

  /// No description provided for @testerFeedbackMissionGames.
  ///
  /// In de, this message translates to:
  /// **'Eine Spielrunde abschließen'**
  String get testerFeedbackMissionGames;

  /// No description provided for @testerFeedbackMissionLanguageForm.
  ///
  /// In de, this message translates to:
  /// **'Grammatik oder Hangul üben'**
  String get testerFeedbackMissionLanguageForm;

  /// No description provided for @testerFeedbackCompleteGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatikübung abschließen'**
  String get testerFeedbackCompleteGrammar;

  /// No description provided for @testerFeedbackCompleteHangul.
  ///
  /// In de, this message translates to:
  /// **'Hangul-Übung abschließen'**
  String get testerFeedbackCompleteHangul;

  /// No description provided for @testerFeedbackCompleteDailyHangul.
  ///
  /// In de, this message translates to:
  /// **'Heutiges Zeichen abschließen'**
  String get testerFeedbackCompleteDailyHangul;

  /// No description provided for @testerFeedbackPromptScenario.
  ///
  /// In de, this message translates to:
  /// **'Gab es eine Stelle, die du in dieser Situation wirklich sagen würdest?'**
  String get testerFeedbackPromptScenario;

  /// No description provided for @testerFeedbackPromptWordWork.
  ///
  /// In de, this message translates to:
  /// **'Fühlen sich diese Wörter nützlich und einprägsam an?'**
  String get testerFeedbackPromptWordWork;

  /// No description provided for @testerFeedbackPromptGrammar.
  ///
  /// In de, this message translates to:
  /// **'Machen Erklärung und Beispiele die Regel verständlich?'**
  String get testerFeedbackPromptGrammar;

  /// No description provided for @testerFeedbackPromptHangul.
  ///
  /// In de, this message translates to:
  /// **'Fühlt sich die Verbindung zwischen Buchstabenform und Laut natürlich an?'**
  String get testerFeedbackPromptHangul;

  /// No description provided for @testerFeedbackPromptGame.
  ///
  /// In de, this message translates to:
  /// **'Würdest du dieses Spiel noch einmal spielen? Was würdest du ändern?'**
  String get testerFeedbackPromptGame;

  /// No description provided for @testerFeedbackPromptListening.
  ///
  /// In de, this message translates to:
  /// **'Sind Tempo und Stimmen gut verständlich?'**
  String get testerFeedbackPromptListening;

  /// No description provided for @testerFeedbackPromptGeneric.
  ///
  /// In de, this message translates to:
  /// **'Was würde diese Lernaktivität besser machen?'**
  String get testerFeedbackPromptGeneric;

  /// No description provided for @testerFeedbackPassportProgress.
  ///
  /// In de, this message translates to:
  /// **'Testerpass {completed} / {total}'**
  String testerFeedbackPassportProgress(int completed, int total);

  /// No description provided for @testerFeedbackNextMission.
  ///
  /// In de, this message translates to:
  /// **'Nächste Beta-Mission: {mission}'**
  String testerFeedbackNextMission(String mission);

  /// No description provided for @onboardingDiagnosticCta.
  ///
  /// In de, this message translates to:
  /// **'Unsicher? 8 Fragen beantworten'**
  String get onboardingDiagnosticCta;

  /// No description provided for @placementTitle.
  ///
  /// In de, this message translates to:
  /// **'Kurzer Einstufungscheck'**
  String get placementTitle;

  /// No description provided for @placementProgress.
  ///
  /// In de, this message translates to:
  /// **'Frage {current} von {total}'**
  String placementProgress(Object current, Object total);

  /// No description provided for @placementNoRecording.
  ///
  /// In de, this message translates to:
  /// **'Keine Aufnahme. Wähle einfach die beste Antwort.'**
  String get placementNoRecording;

  /// No description provided for @placementSeeRecommendation.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung ansehen'**
  String get placementSeeRecommendation;

  /// No description provided for @placementRecommendedStart.
  ///
  /// In de, this message translates to:
  /// **'Empfohlener Start'**
  String get placementRecommendedStart;

  /// No description provided for @placementScoreSummary.
  ///
  /// In de, this message translates to:
  /// **'Du hattest {correct} von {total} richtig. Das ist nur eine Empfehlung: Du kannst jede Stufe wählen.'**
  String placementScoreSummary(Object correct, Object total);

  /// No description provided for @placementStartAt.
  ///
  /// In de, this message translates to:
  /// **'Mit {level} starten'**
  String placementStartAt(Object level);

  /// No description provided for @placementChooseYourself.
  ///
  /// In de, this message translates to:
  /// **'Oder selbst wählen'**
  String get placementChooseYourself;

  /// No description provided for @courseMissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine nächste Mission'**
  String get courseMissionTitle;

  /// No description provided for @courseMissionTitleShort.
  ///
  /// In de, this message translates to:
  /// **'Kursmission'**
  String get courseMissionTitleShort;

  /// No description provided for @courseMissionLoadError.
  ///
  /// In de, this message translates to:
  /// **'Die Kursdaten konnten nicht geladen werden.'**
  String get courseMissionLoadError;

  /// No description provided for @courseMissionNow.
  ///
  /// In de, this message translates to:
  /// **'jetzt'**
  String get courseMissionNow;

  /// No description provided for @courseMissionPreviewTag.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get courseMissionPreviewTag;

  /// No description provided for @courseMissionStartPractice.
  ///
  /// In de, this message translates to:
  /// **'Übung starten'**
  String get courseMissionStartPractice;

  /// No description provided for @courseMissionPreviewNotice.
  ///
  /// In de, this message translates to:
  /// **'Du kannst diese Mission ansehen. Punkte und Fortschritt zählen erst, wenn sie aktiv ist.'**
  String get courseMissionPreviewNotice;

  /// No description provided for @courseSectionToday.
  ///
  /// In de, this message translates to:
  /// **'Was heute zählt'**
  String get courseSectionToday;

  /// No description provided for @courseSectionFamilies.
  ///
  /// In de, this message translates to:
  /// **'Ausdrucksfamilien'**
  String get courseSectionFamilies;

  /// No description provided for @courseSectionSurfaces.
  ///
  /// In de, this message translates to:
  /// **'Karten aus dem echten Alltag'**
  String get courseSectionSurfaces;

  /// No description provided for @courseSectionRepair.
  ///
  /// In de, this message translates to:
  /// **'Kurz korrigieren'**
  String get courseSectionRepair;

  /// No description provided for @courseSectionPractice.
  ///
  /// In de, this message translates to:
  /// **'Missionsübungen'**
  String get courseSectionPractice;

  /// No description provided for @coursePracticeVocab.
  ///
  /// In de, this message translates to:
  /// **'Wortschatz üben'**
  String get coursePracticeVocab;

  /// No description provided for @coursePracticeGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatikkarten'**
  String get coursePracticeGrammar;

  /// No description provided for @coursePracticeCloze.
  ///
  /// In de, this message translates to:
  /// **'Lückentext'**
  String get coursePracticeCloze;

  /// No description provided for @coursePracticeSatz.
  ///
  /// In de, this message translates to:
  /// **'Satz bauen'**
  String get coursePracticeSatz;

  /// No description provided for @coursePracticeScenario.
  ///
  /// In de, this message translates to:
  /// **'Szenario-Checkpoint'**
  String get coursePracticeScenario;

  /// No description provided for @coursePracticeSmalltalk.
  ///
  /// In de, this message translates to:
  /// **'Small Talk'**
  String get coursePracticeSmalltalk;

  /// No description provided for @courseCheckpointCheck.
  ///
  /// In de, this message translates to:
  /// **'Kurz prüfen'**
  String get courseCheckpointCheck;

  /// No description provided for @courseCheckpointGrammarPrompt.
  ///
  /// In de, this message translates to:
  /// **'Welches Muster passt zu diesem Beispiel?'**
  String get courseCheckpointGrammarPrompt;

  /// No description provided for @courseCheckpointSmalltalkPrompt.
  ///
  /// In de, this message translates to:
  /// **'Für welche Beziehung ist dieser Satz sicher?'**
  String get courseCheckpointSmalltalkPrompt;

  /// No description provided for @courseCheckpointCorrect.
  ///
  /// In de, this message translates to:
  /// **'Richtig. Diese Mission hat einen Nachweis erhalten.'**
  String get courseCheckpointCorrect;

  /// No description provided for @courseCheckpointIncorrect.
  ///
  /// In de, this message translates to:
  /// **'Noch einmal ansehen. Die sichere Wahl ist markiert.'**
  String get courseCheckpointIncorrect;

  /// No description provided for @courseCheckpointSaved.
  ///
  /// In de, this message translates to:
  /// **'In dieser Sitzung bereits gespeichert.'**
  String get courseCheckpointSaved;

  /// No description provided for @courseCheckpointSaveError.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt konnte nicht gespeichert werden. Bitte versuche es noch einmal.'**
  String get courseCheckpointSaveError;

  /// No description provided for @courseStatePreview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get courseStatePreview;

  /// No description provided for @courseStateIntroduced.
  ///
  /// In de, this message translates to:
  /// **'Eingeführt'**
  String get courseStateIntroduced;

  /// No description provided for @courseStatePractice.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get courseStatePractice;

  /// No description provided for @courseStateCheckpointPassed.
  ///
  /// In de, this message translates to:
  /// **'Checkpoint geschafft'**
  String get courseStateCheckpointPassed;

  /// No description provided for @courseStateReviewDue.
  ///
  /// In de, this message translates to:
  /// **'Kurz korrigieren'**
  String get courseStateReviewDue;

  /// No description provided for @courseStateStable.
  ///
  /// In de, this message translates to:
  /// **'Sicher'**
  String get courseStateStable;

  /// No description provided for @courseAxisBatchim.
  ///
  /// In de, this message translates to:
  /// **'Endkonsonant (받침)'**
  String get courseAxisBatchim;

  /// No description provided for @courseAxisSentenceRole.
  ///
  /// In de, this message translates to:
  /// **'Satzrolle'**
  String get courseAxisSentenceRole;

  /// No description provided for @courseAxisRelationship.
  ///
  /// In de, this message translates to:
  /// **'Beziehung und Situation'**
  String get courseAxisRelationship;

  /// No description provided for @courseAxisSetting.
  ///
  /// In de, this message translates to:
  /// **'Ort und Anlass'**
  String get courseAxisSetting;

  /// No description provided for @courseUsageOfficial.
  ///
  /// In de, this message translates to:
  /// **'offizieller Rahmen'**
  String get courseUsageOfficial;

  /// No description provided for @courseUsageEverydayPolite.
  ///
  /// In de, this message translates to:
  /// **'höflicher Alltag'**
  String get courseUsageEverydayPolite;

  /// No description provided for @courseUsageCloseOnly.
  ///
  /// In de, this message translates to:
  /// **'nur bei enger Beziehung'**
  String get courseUsageCloseOnly;

  /// No description provided for @courseUsageOfficialOrService.
  ///
  /// In de, this message translates to:
  /// **'offiziell oder im Service'**
  String get courseUsageOfficialOrService;

  /// No description provided for @courseUsageFriendlyPolite.
  ///
  /// In de, this message translates to:
  /// **'freundlich und höflich'**
  String get courseUsageFriendlyPolite;

  /// No description provided for @courseUsageServiceRequest.
  ///
  /// In de, this message translates to:
  /// **'Service-Anfrage'**
  String get courseUsageServiceRequest;

  /// No description provided for @courseUsagePaymentNotice.
  ///
  /// In de, this message translates to:
  /// **'Zahlungshinweis'**
  String get courseUsagePaymentNotice;

  /// No description provided for @moduleBadgeNew.
  ///
  /// In de, this message translates to:
  /// **'NEU'**
  String get moduleBadgeNew;

  /// No description provided for @moduleBadgeDue.
  ///
  /// In de, this message translates to:
  /// **'FÄLLIG'**
  String get moduleBadgeDue;

  /// No description provided for @homeMadangEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Heute im Sarangbang'**
  String get homeMadangEyebrow;

  /// No description provided for @homeSarangbangCta.
  ///
  /// In de, this message translates to:
  /// **'Im Sarangbang lernen'**
  String get homeSarangbangCta;

  /// No description provided for @homeTodayEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Deine Handlung für heute'**
  String get homeTodayEyebrow;

  /// No description provided for @homeTodayMissionStart.
  ///
  /// In de, this message translates to:
  /// **'Diese Szene beginnen'**
  String get homeTodayMissionStart;

  /// No description provided for @homeTodayCourseAction.
  ///
  /// In de, this message translates to:
  /// **'Diese Handlung üben'**
  String get homeTodayCourseAction;

  /// No description provided for @homeTodayPackAction.
  ///
  /// In de, this message translates to:
  /// **'Diese Wörter üben'**
  String get homeTodayPackAction;

  /// No description provided for @homeTodayReviewAction.
  ///
  /// In de, this message translates to:
  /// **'Jetzt wiederholen'**
  String get homeTodayReviewAction;

  /// No description provided for @homeTodayScenarioAction.
  ///
  /// In de, this message translates to:
  /// **'Diese Szene üben'**
  String get homeTodayScenarioAction;

  /// No description provided for @homeTodayPackDescription.
  ///
  /// In de, this message translates to:
  /// **'Übe die Wörter, die du als Nächstes brauchst.'**
  String get homeTodayPackDescription;

  /// No description provided for @homeTodayReviewDescription.
  ///
  /// In de, this message translates to:
  /// **'Damit der Satz in deiner nächsten Szene bereit ist.'**
  String get homeTodayReviewDescription;

  /// No description provided for @homeTodayReviewReasonTitle.
  ///
  /// In de, this message translates to:
  /// **'Warum heute wiederholen?'**
  String get homeTodayReviewReasonTitle;

  /// No description provided for @homeTodayReviewReason.
  ///
  /// In de, this message translates to:
  /// **'Damit Begrüßungen, Bitten und Antworten in deiner nächsten Szene bereit sind.'**
  String get homeTodayReviewReason;

  /// No description provided for @homeTodayReviewTime.
  ///
  /// In de, this message translates to:
  /// **'Etwa 3 Minuten · dann geht dein Weg weiter.'**
  String get homeTodayReviewTime;

  /// No description provided for @homeUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg konnte nicht aktualisiert werden.'**
  String get homeUnavailableTitle;

  /// No description provided for @homeUnavailableDescription.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wiederholungen und bereits gelernte Inhalte bleiben auf diesem Gerät verfügbar.'**
  String get homeUnavailableDescription;

  /// No description provided for @homeUnavailableCta.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter wiederholen'**
  String get homeUnavailableCta;

  /// No description provided for @homeTodayScenarioDescription.
  ///
  /// In de, this message translates to:
  /// **'Höre zu, wähle und sprich die Szene.'**
  String get homeTodayScenarioDescription;

  /// No description provided for @homeHanokPreviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Hanok'**
  String get homeHanokPreviewTitle;

  /// No description provided for @homeHanokPreviewBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernen lässt deinen Hanok wachsen.'**
  String get homeHanokPreviewBody;

  /// No description provided for @homeHanokPreviewCta.
  ///
  /// In de, this message translates to:
  /// **'Mein Hanok öffnen'**
  String get homeHanokPreviewCta;

  /// No description provided for @hanokNarrativeVerified.
  ///
  /// In de, this message translates to:
  /// **'Bau: {stage}. Bestätigt: {canDo}'**
  String hanokNarrativeVerified(String stage, String canDo);

  /// No description provided for @hanokNarrativeNext.
  ///
  /// In de, this message translates to:
  /// **'Bau: {stage}. Als Nächstes: {canDo}'**
  String hanokNarrativeNext(String stage, String canDo);

  /// No description provided for @hanokNarrativeStarting.
  ///
  /// In de, this message translates to:
  /// **'Bau: {stage}. Beginne mit deiner ersten Szene.'**
  String hanokNarrativeStarting(String stage);

  /// No description provided for @hanokNarrativeMaterialSource.
  ///
  /// In de, this message translates to:
  /// **'Kursszenen formen die Struktur. Pakete, Wiederholungen und Quests fügen Material und Dekor hinzu.'**
  String get hanokNarrativeMaterialSource;

  /// No description provided for @sarangbangTitle.
  ///
  /// In de, this message translates to:
  /// **'Studierstube'**
  String get sarangbangTitle;

  /// No description provided for @sarangbangEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts zum Einrichten'**
  String get sarangbangEmptyTitle;

  /// No description provided for @sarangbangEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe Quests ab und öffne dein Bojagi-Bündel. Danach kannst du die Stube einrichten.'**
  String get sarangbangEmptyBody;

  /// No description provided for @sarangbangPickTitle.
  ///
  /// In de, this message translates to:
  /// **'Was soll hierhin?'**
  String get sarangbangPickTitle;

  /// No description provided for @sarangbangClear.
  ///
  /// In de, this message translates to:
  /// **'Platz frei lassen'**
  String get sarangbangClear;

  /// No description provided for @sarangbangHubDesc.
  ///
  /// In de, this message translates to:
  /// **'Dein nächster Lernschritt beginnt im Sarangbang.'**
  String get sarangbangHubDesc;

  /// No description provided for @bojagiTitle.
  ///
  /// In de, this message translates to:
  /// **'Bojagi-Bündel'**
  String get bojagiTitle;

  /// No description provided for @bojagiOpenHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf den Knoten, um das Bündel zu öffnen.'**
  String get bojagiOpenHint;

  /// No description provided for @bojagiPickTitle.
  ///
  /// In de, this message translates to:
  /// **'Such dir eins aus'**
  String get bojagiPickTitle;

  /// No description provided for @bojagiPickBody.
  ///
  /// In de, this message translates to:
  /// **'Was du liegen lässt, bleibt im Beutel und kann in einem späteren Bündel wiederkommen.'**
  String get bojagiPickBody;

  /// No description provided for @bojagiEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Bündel wartet'**
  String get bojagiEmptyTitle;

  /// No description provided for @bojagiEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe eine Quest ab. Dafür bekommst du ein Bündel.'**
  String get bojagiEmptyBody;

  /// No description provided for @bojagiAllOwnedTitle.
  ///
  /// In de, this message translates to:
  /// **'Nichts Neues drin'**
  String get bojagiAllOwnedTitle;

  /// No description provided for @bojagiAllOwnedBody.
  ///
  /// In de, this message translates to:
  /// **'Alle drei Stücke aus diesem Bündel hast du schon.'**
  String get bojagiAllOwnedBody;

  /// No description provided for @bojagiProblemTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Bündel lässt sich gerade nicht öffnen'**
  String get bojagiProblemTitle;

  /// No description provided for @bojagiProblemBody.
  ///
  /// In de, this message translates to:
  /// **'Versuch es gleich noch einmal. Dein Bündel geht dabei nicht verloren.'**
  String get bojagiProblemBody;

  /// No description provided for @bojagiRetry.
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get bojagiRetry;

  /// No description provided for @bojagiClaimedTitle.
  ///
  /// In de, this message translates to:
  /// **'Bekommen!'**
  String get bojagiClaimedTitle;

  /// No description provided for @bojagiGoToRoom.
  ///
  /// In de, this message translates to:
  /// **'In der Stube aufstellen'**
  String get bojagiGoToRoom;

  /// No description provided for @bojagiNext.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Bündel öffnen'**
  String get bojagiNext;

  /// No description provided for @bojagiCollectionCompleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Sammlung vollständig'**
  String get bojagiCollectionCompleteTitle;

  /// No description provided for @bojagiCollectionCompleteBody.
  ///
  /// In de, this message translates to:
  /// **'Du besitzt bereits alle Einrichtungsstücke. Lege dieses Bündel ab, um weiterzumachen.'**
  String get bojagiCollectionCompleteBody;

  /// No description provided for @bojagiArchiveComplete.
  ///
  /// In de, this message translates to:
  /// **'Bündel ablegen'**
  String get bojagiArchiveComplete;

  /// No description provided for @hanokWorldTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Hanok-Welt'**
  String get hanokWorldTitle;

  /// No description provided for @hanokWorldIntro.
  ///
  /// In de, this message translates to:
  /// **'Lerne dort weiter, wo deine Hanok wächst. Jeder fertige Ort führt zu einem vertrauten Teil von Hangul Sori.'**
  String get hanokWorldIntro;

  /// No description provided for @hanokWorldLegacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Hof nimmt Gestalt an'**
  String get hanokWorldLegacyTitle;

  /// No description provided for @hanokWorldLegacyBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe deinen A1- und A2-Weg ab. Mit deinem ersten B1-Fortschritt öffnet sich das Tor zur großen Hanok-Karte.'**
  String get hanokWorldLegacyBody;

  /// No description provided for @hanokWorldMapHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein fertig gebautes Gebäude, um dort weiterzulernen.'**
  String get hanokWorldMapHint;

  /// No description provided for @hanokWorldOpenSarangbang.
  ///
  /// In de, this message translates to:
  /// **'Im Sarangbang lernen'**
  String get hanokWorldOpenSarangbang;

  /// No description provided for @hanokWorldProgress.
  ///
  /// In de, this message translates to:
  /// **'Baufortschritt deiner Hanok'**
  String get hanokWorldProgress;

  /// No description provided for @hanokWorldGyeBridgeTitle.
  ///
  /// In de, this message translates to:
  /// **'Der Gye-Hof'**
  String get hanokWorldGyeBridgeTitle;

  /// No description provided for @hanokWorldGyeBridgeBody.
  ///
  /// In de, this message translates to:
  /// **'Deine private Hanok und der gemeinsame Gye-Hof wachsen nebeneinander. Triff deine Lerngruppe dort.'**
  String get hanokWorldGyeBridgeBody;

  /// No description provided for @hanokWorldGyeBridgeOpen.
  ///
  /// In de, this message translates to:
  /// **'Gye-Hof besuchen'**
  String get hanokWorldGyeBridgeOpen;

  /// No description provided for @hanokWorldPlacesTitle.
  ///
  /// In de, this message translates to:
  /// **'Orte in deiner Hanok'**
  String get hanokWorldPlacesTitle;

  /// No description provided for @hanokWorldPlacesBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle hier einen fertig gebauten Ort aus.'**
  String get hanokWorldPlacesBody;

  /// No description provided for @hanokZoneSarangbang.
  ///
  /// In de, this message translates to:
  /// **'Sarangbang · heutiges Lernen'**
  String get hanokZoneSarangbang;

  /// No description provided for @hanokZoneDaecheong.
  ///
  /// In de, this message translates to:
  /// **'Daecheongmaru · Lernpfad'**
  String get hanokZoneDaecheong;

  /// No description provided for @hanokZoneHaengrang.
  ///
  /// In de, this message translates to:
  /// **'Haengrangchae · Üben'**
  String get hanokZoneHaengrang;

  /// No description provided for @hanokZoneAnchae.
  ///
  /// In de, this message translates to:
  /// **'Anchae · meine Sammlung'**
  String get hanokZoneAnchae;

  /// No description provided for @hanokZoneHuwon.
  ///
  /// In de, this message translates to:
  /// **'Huwon · Tagesziel'**
  String get hanokZoneHuwon;

  /// No description provided for @hanokZoneSadang.
  ///
  /// In de, this message translates to:
  /// **'Sadang · Erfolge'**
  String get hanokZoneSadang;

  /// No description provided for @hanokWorldSelectPlaceTitle.
  ///
  /// In de, this message translates to:
  /// **'Einen fertigen Ort wählen'**
  String get hanokWorldSelectPlaceTitle;

  /// No description provided for @hanokWorldSelectPlaceBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein Gebäude in der Karte oder wähle es aus der zugänglichen Liste.'**
  String get hanokWorldSelectPlaceBody;

  /// No description provided for @hanokWorldPlaceReadyBody.
  ///
  /// In de, this message translates to:
  /// **'{place} ist bereit für deinen nächsten Lernschritt.'**
  String hanokWorldPlaceReadyBody(String place);

  /// No description provided for @hanokWorldOpenPlace.
  ///
  /// In de, this message translates to:
  /// **'Nach {place} gehen'**
  String hanokWorldOpenPlace(String place);

  /// No description provided for @hanokWorldTodayMarker.
  ///
  /// In de, this message translates to:
  /// **'Heutiges Lernen'**
  String get hanokWorldTodayMarker;

  /// No description provided for @hanokWorldRevealTitle.
  ///
  /// In de, this message translates to:
  /// **'{place} ist fertig'**
  String hanokWorldRevealTitle(String place);

  /// No description provided for @hanokWorldRevealBody.
  ///
  /// In de, this message translates to:
  /// **'Holz, Staub und Dancheong: Ein neuer Teil deiner Hanok ist entstanden.'**
  String get hanokWorldRevealBody;

  /// No description provided for @hanokWorldRevealContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Karte'**
  String get hanokWorldRevealContinue;

  /// No description provided for @hanokVenueFurnishRoom.
  ///
  /// In de, this message translates to:
  /// **'Diesen Raum einrichten'**
  String get hanokVenueFurnishRoom;

  /// No description provided for @hanokVenueAnbangBody.
  ///
  /// In de, this message translates to:
  /// **'Im ruhigen inneren Raum bewahrst du Wörter, Seiten und eigene Lernsammlungen.'**
  String get hanokVenueAnbangBody;

  /// No description provided for @hanokVenueDaecheongBody.
  ///
  /// In de, this message translates to:
  /// **'Auf dem offenen Maru setzt du deinen Lernweg fort oder richtest den Raum ein.'**
  String get hanokVenueDaecheongBody;

  /// No description provided for @hanokVenueHaengrangBody.
  ///
  /// In de, this message translates to:
  /// **'Im Eingangsflügel wartet dein Übungsatelier auf eine weitere Runde.'**
  String get hanokVenueHaengrangBody;

  /// No description provided for @hanokVenueHuwonBody.
  ///
  /// In de, this message translates to:
  /// **'Im hinteren Garten wartet ein ruhiger Moment für dein Zeichen des Tages oder eine neue Quest.'**
  String get hanokVenueHuwonBody;

  /// No description provided for @hanokVenueSadangBody.
  ///
  /// In de, this message translates to:
  /// **'Im Ahnenschrein sammelst du sichtbare Spuren deines Lernwegs.'**
  String get hanokVenueSadangBody;

  /// No description provided for @sarangbangStudyTitle.
  ///
  /// In de, this message translates to:
  /// **'Sarangbang'**
  String get sarangbangStudyTitle;

  /// No description provided for @sarangbangStudyIntroTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein nächster Lernschritt wartet'**
  String get sarangbangStudyIntroTitle;

  /// No description provided for @sarangbangStudyIntroBody.
  ///
  /// In de, this message translates to:
  /// **'Hier beginnt genau die Übung, die heute zu deinem Fortschritt passt.'**
  String get sarangbangStudyIntroBody;

  /// No description provided for @sarangbangStudySceneLabel.
  ///
  /// In de, this message translates to:
  /// **'Deine Studierstube'**
  String get sarangbangStudySceneLabel;

  /// No description provided for @sarangbangStudyFurnish.
  ///
  /// In de, this message translates to:
  /// **'Studierstube einrichten'**
  String get sarangbangStudyFurnish;

  /// No description provided for @personalRoomAnbangTitle.
  ///
  /// In de, this message translates to:
  /// **'Anbang'**
  String get personalRoomAnbangTitle;

  /// No description provided for @personalRoomDaecheongTitle.
  ///
  /// In de, this message translates to:
  /// **'Daecheongmaru'**
  String get personalRoomDaecheongTitle;

  /// No description provided for @personalRoomAnbangBody.
  ///
  /// In de, this message translates to:
  /// **'Ein ruhiger Innenraum für die Wörter und Momente, die du bewahrst.'**
  String get personalRoomAnbangBody;

  /// No description provided for @personalRoomDaecheongBody.
  ///
  /// In de, this message translates to:
  /// **'Eine offene Halle, in der dein Lernweg weitergeht.'**
  String get personalRoomDaecheongBody;

  /// No description provided for @personalRoomEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Öffne ein Bojagi-Bündel, um dein erstes Einrichtungsstück zu erhalten.'**
  String get personalRoomEmptyHint;

  /// No description provided for @personalRoomLockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Dieser Raum wird noch gebaut'**
  String get personalRoomLockedTitle;

  /// No description provided for @personalRoomLockedBody.
  ///
  /// In de, this message translates to:
  /// **'Lerne auf deinem Lernweg weiter, um diesen Teil deiner Hanok zu öffnen.'**
  String get personalRoomLockedBody;

  /// No description provided for @personalRoomReturnToMap.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Hanok-Karte'**
  String get personalRoomReturnToMap;

  /// No description provided for @personalRoomAnbangStudy.
  ///
  /// In de, this message translates to:
  /// **'Meine Sammlung entdecken'**
  String get personalRoomAnbangStudy;

  /// No description provided for @personalRoomDaecheongStudy.
  ///
  /// In de, this message translates to:
  /// **'Lernweg fortsetzen'**
  String get personalRoomDaecheongStudy;

  /// No description provided for @gyeDedicationTitle.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Ausstellung'**
  String get gyeDedicationTitle;

  /// No description provided for @gyeDedicationAction.
  ///
  /// In de, this message translates to:
  /// **'Ausstellen'**
  String get gyeDedicationAction;

  /// No description provided for @gyeDedicationPickerBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Zimmerdekoration für den gemeinsamen Hof. Sie bleibt in deiner privaten Sammlung.'**
  String get gyeDedicationPickerBody;

  /// No description provided for @gyeDedicationEmpty.
  ///
  /// In de, this message translates to:
  /// **'Öffne zuerst ein Bojagi-Bündel, um eine Zimmerdekoration zu erhalten.'**
  String get gyeDedicationEmpty;

  /// No description provided for @gyeDedicationWithdraw.
  ///
  /// In de, this message translates to:
  /// **'Aus der Ausstellung nehmen'**
  String get gyeDedicationWithdraw;

  /// No description provided for @gyeDedicationKeepOwned.
  ///
  /// In de, this message translates to:
  /// **'Deine Dekoration bleibt in deinem privaten Raum.'**
  String get gyeDedicationKeepOwned;

  /// No description provided for @gyeDedicationConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Diese Dekoration im Hof zeigen?'**
  String get gyeDedicationConfirmTitle;

  /// No description provided for @gyeDedicationConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Alle in diesem Gye können {decoration} im gemeinsamen Hof sehen. Deine private Sammlung und dein Raum bleiben unverändert.'**
  String gyeDedicationConfirmBody(String decoration);

  /// No description provided for @gyeDedicationWithdrawConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Dieses Ausstellungsstück aus dem gemeinsamen Hof nehmen? Deine private Dekoration bleibt dir erhalten.'**
  String get gyeDedicationWithdrawConfirmBody;

  /// No description provided for @gyeDedicationConfirm.
  ///
  /// In de, this message translates to:
  /// **'Im Hof zeigen'**
  String get gyeDedicationConfirm;

  /// No description provided for @gyeDedicationUpdateFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Ausstellung konnte nicht aktualisiert werden. Versuche es gleich noch einmal.'**
  String get gyeDedicationUpdateFailed;

  /// No description provided for @gyeDedicationConflict.
  ///
  /// In de, this message translates to:
  /// **'Die Ausstellung wurde an anderer Stelle geändert. Hier ist der aktuelle Stand.'**
  String get gyeDedicationConflict;

  /// No description provided for @gyeDedicationRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get gyeDedicationRetry;

  /// Title when account linking cannot start because Firebase is unavailable
  ///
  /// In de, this message translates to:
  /// **'Verbindung derzeit nicht möglich'**
  String get accountLinkUnavailableTitle;

  /// Body explaining that cloud services are unavailable and local progress is safe
  ///
  /// In de, this message translates to:
  /// **'Die Cloud-Dienste sind auf diesem Gerät nicht verfügbar, deshalb konnte die Anmeldung nicht gestartet werden. Dein Lernfortschritt bleibt lokal gespeichert. Prüfe deine Internetverbindung und starte die App neu.'**
  String get accountLinkUnavailableBody;

  /// Title when account linking failed because the device is offline
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung'**
  String get accountLinkOfflineTitle;

  /// Body explaining that linking needs internet and local progress is safe
  ///
  /// In de, this message translates to:
  /// **'Für das Verbinden eines Kontos wird Internet benötigt. Dein Fortschritt bleibt auf diesem Gerät gespeichert.'**
  String get accountLinkOfflineBody;

  /// Title when account linking failed for a transient reason
  ///
  /// In de, this message translates to:
  /// **'Verbinden fehlgeschlagen'**
  String get accountLinkFailedTitle;

  /// Body asking the user to retry the account link in a moment
  ///
  /// In de, this message translates to:
  /// **'Der Vorgang konnte nicht abgeschlossen werden. Bitte versuche es in einem Moment erneut.'**
  String get accountLinkFailedBody;
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
