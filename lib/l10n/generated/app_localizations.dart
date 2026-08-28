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
  /// **'Unbegrenzte Wiederholungen'**
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

  /// No description provided for @paywallEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Premium'**
  String get paywallEyebrow;

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

  /// No description provided for @paywallRestoreFailed.
  ///
  /// In de, this message translates to:
  /// **'Käufe konnten nicht wiederhergestellt werden. Versuche es erneut.'**
  String get paywallRestoreFailed;

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

  /// No description provided for @companionNoneName.
  ///
  /// In de, this message translates to:
  /// **'Keine Lernbegleitung'**
  String get companionNoneName;

  /// No description provided for @companionNoneDescription.
  ///
  /// In de, this message translates to:
  /// **'Du kannst später jederzeit 태고 oder Joy wählen.'**
  String get companionNoneDescription;

  /// No description provided for @companionNeutralThinking.
  ///
  /// In de, this message translates to:
  /// **'Die nächste Runde wird vorbereitet …'**
  String get companionNeutralThinking;

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
  /// **'Fröhlich & lebhaft'**
  String get characterTraitMagpie;

  /// No description provided for @characterDescMagpie.
  ///
  /// In de, this message translates to:
  /// **'In Korea gilt die Elster als Glücksbotin, die gute Nachrichten bringt. Joy feiert jeden Erfolg mit dir und bringt gute Laune in jede Lektion.'**
  String get characterDescMagpie;

  /// No description provided for @characterSelectedTiger.
  ///
  /// In de, this message translates to:
  /// **'Du hast Taego ausgewählt.'**
  String get characterSelectedTiger;

  /// No description provided for @characterSelectedMagpie.
  ///
  /// In de, this message translates to:
  /// **'Du hast Joy ausgewählt.'**
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

  /// No description provided for @reviewHubTitle.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get reviewHubTitle;

  /// No description provided for @reviewHubTodayHeadline.
  ///
  /// In de, this message translates to:
  /// **'Heute gelernt'**
  String get reviewHubTodayHeadline;

  /// No description provided for @reviewHubEmptyToday.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts gelernt heute — starte eine Lektion.'**
  String get reviewHubEmptyToday;

  /// No description provided for @reviewHubStartSelected.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort üben} other{{n} Wörter üben}}'**
  String reviewHubStartSelected(int n);

  /// No description provided for @reviewHubCalendarTooltip.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get reviewHubCalendarTooltip;

  /// No description provided for @reviewHubDeckLabel.
  ///
  /// In de, this message translates to:
  /// **'{words, plural, one{1 Wort} other{{words} Wörter}}'**
  String reviewHubDeckLabel(int words);

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
  /// **'1.188 Karten · A1 → C2 · TTS'**
  String get moduleVocabDesc;

  /// No description provided for @moduleGrammarTitle.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get moduleGrammarTitle;

  /// No description provided for @moduleGrammarDesc.
  ///
  /// In de, this message translates to:
  /// **'176 Muster · A1 → C2'**
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

  /// No description provided for @legacyVocabPrevious.
  ///
  /// In de, this message translates to:
  /// **'Vorherige Karte'**
  String get legacyVocabPrevious;

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

  /// No description provided for @gameLoading.
  ///
  /// In de, this message translates to:
  /// **'Spiel wird vorbereitet …'**
  String get gameLoading;

  /// No description provided for @gameRoundProgress.
  ///
  /// In de, this message translates to:
  /// **'Runde {current} von {total}'**
  String gameRoundProgress(int current, int total);

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

  /// No description provided for @bookshelfEmptyPreview.
  ///
  /// In de, this message translates to:
  /// **'Leere Seite'**
  String get bookshelfEmptyPreview;

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

  /// Custom pack tile progress — words learned of total
  ///
  /// In de, this message translates to:
  /// **'{learned} von {total} gelernt'**
  String bookshelfPackLearnedMeta(int learned, int total);

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

  /// No description provided for @bookshelfDefaultPackName.
  ///
  /// In de, this message translates to:
  /// **'Paket {date}'**
  String bookshelfDefaultPackName(Object date);

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

  /// No description provided for @filterDifficulty.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get filterDifficulty;

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

  /// No description provided for @chosungEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für diese Lernstufe sind noch keine passenden Wörter vorbereitet.'**
  String get chosungEmptyBody;

  /// No description provided for @chosungBackspace.
  ///
  /// In de, this message translates to:
  /// **'Letztes Zeichen löschen'**
  String get chosungBackspace;

  /// No description provided for @chosungCorrectCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 richtige Antwort} other{{count} richtige Antworten}}'**
  String chosungCorrectCount(int count);

  /// No description provided for @chosungWrongCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 falsche Antwort} other{{count} falsche Antworten}}'**
  String chosungWrongCount(int count);

  /// No description provided for @chosungPadHiddenNote.
  ///
  /// In de, this message translates to:
  /// **'Ab B1 gibt es keine Tastenhilfe mehr. Tippe das Wort mit deiner koreanischen Tastatur.'**
  String get chosungPadHiddenNote;

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

  /// No description provided for @ttsSpeedLabel.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get ttsSpeedLabel;

  /// No description provided for @ttsSpeedChip.
  ///
  /// In de, this message translates to:
  /// **'{speed}×'**
  String ttsSpeedChip(String speed);

  /// No description provided for @ttsSpeedSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprechtempo'**
  String get ttsSpeedSheetTitle;

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

  /// No description provided for @settingsOriginStoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Warum Hangul Sori entstand'**
  String get settingsOriginStoryTitle;

  /// No description provided for @settingsOriginStorySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Die Idee hinter der App'**
  String get settingsOriginStorySubtitle;

  /// No description provided for @settingsOriginStoryBody.
  ///
  /// In de, this message translates to:
  /// **'Gründerin Sujin Park hat Hangul Sori aus einem praktischen Gedanken heraus entwickelt: Koreanischlernen soll Klang, Schrift, Alltagssituationen und die Bücher verbinden, mit denen du bereits lernst. Die App führt diese Teile in einem Lernweg zusammen, von den Hangul-Grundlagen über stufengerechte Szenarien bis zu Aussprache und Wiederholung.'**
  String get settingsOriginStoryBody;

  /// No description provided for @settingsOriginStoryFounder.
  ///
  /// In de, this message translates to:
  /// **'Sujin Park · Gründerin von Hangul Sori'**
  String get settingsOriginStoryFounder;

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
  /// **'Karteikarten'**
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

  /// No description provided for @silbenEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für deine Lernstufe sind noch keine Silben-Rätsel vorbereitet.'**
  String get silbenEmptyBody;

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
  /// **'📽 Strichreihenfolge (zum Wiederholen tippen)'**
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

  /// No description provided for @hangulChipConsonants.
  ///
  /// In de, this message translates to:
  /// **'Konsonanten'**
  String get hangulChipConsonants;

  /// No description provided for @hangulChipVowels.
  ///
  /// In de, this message translates to:
  /// **'Vokale'**
  String get hangulChipVowels;

  /// No description provided for @hangulChipSyllables.
  ///
  /// In de, this message translates to:
  /// **'Silben'**
  String get hangulChipSyllables;

  /// No description provided for @hangulCheckModeLabel.
  ///
  /// In de, this message translates to:
  /// **'Strichprüfung'**
  String get hangulCheckModeLabel;

  /// No description provided for @hangulCheckModePractice.
  ///
  /// In de, this message translates to:
  /// **'Frei üben'**
  String get hangulCheckModePractice;

  /// No description provided for @hangulCheckModeExam.
  ///
  /// In de, this message translates to:
  /// **'Streng'**
  String get hangulCheckModeExam;

  /// No description provided for @hangulCheckModePracticeHint.
  ///
  /// In de, this message translates to:
  /// **'Du bekommst Hinweise, aber nichts wird gelöscht.'**
  String get hangulCheckModePracticeHint;

  /// No description provided for @hangulCheckModeExamHint.
  ///
  /// In de, this message translates to:
  /// **'Reihenfolge und Richtung müssen stimmen.'**
  String get hangulCheckModeExamHint;

  /// No description provided for @hangulStrokeProgress.
  ///
  /// In de, this message translates to:
  /// **'Strich {current} / {total}'**
  String hangulStrokeProgress(int current, int total);

  /// No description provided for @hangulStrokeNextHint.
  ///
  /// In de, this message translates to:
  /// **'Jetzt Strich {index} zeichnen.'**
  String hangulStrokeNextHint(int index);

  /// No description provided for @hangulStrokeWrongOrder.
  ///
  /// In de, this message translates to:
  /// **'Das ist Strich {drawn}. Zeichne zuerst Strich {expected}.'**
  String hangulStrokeWrongOrder(int drawn, int expected);

  /// No description provided for @hangulStrokeWrongDirection.
  ///
  /// In de, this message translates to:
  /// **'Richtige Linie, falsche Richtung. Strich {index} läuft andersherum.'**
  String hangulStrokeWrongDirection(int index);

  /// No description provided for @hangulStrokeWrongShape.
  ///
  /// In de, this message translates to:
  /// **'Das passt zu keinem Strich. Sieh dir Strich {index} links an.'**
  String hangulStrokeWrongShape(int index);

  /// No description provided for @hangulStrokeTooShort.
  ///
  /// In de, this message translates to:
  /// **'Zu kurz. Zieh den Strich in einem Zug.'**
  String get hangulStrokeTooShort;

  /// No description provided for @hangulStrokeLetterDone.
  ///
  /// In de, this message translates to:
  /// **'{letter} sitzt! Weiter zum nächsten.'**
  String hangulStrokeLetterDone(Object letter);

  /// No description provided for @hangulLettersDone.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Buchstabe fertig} other{{count} Buchstaben fertig}}'**
  String hangulLettersDone(int count);

  /// No description provided for @hangulHardOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur schwierige'**
  String get hangulHardOnly;

  /// No description provided for @chosungModeWithVowels.
  ///
  /// In de, this message translates to:
  /// **'Anlaut + Vokal'**
  String get chosungModeWithVowels;

  /// No description provided for @chosungModeInitialsOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Anlaute'**
  String get chosungModeInitialsOnly;

  /// No description provided for @chosungSlotVowel.
  ///
  /// In de, this message translates to:
  /// **'Vokal'**
  String get chosungSlotVowel;

  /// No description provided for @chosungSlotBatchim.
  ///
  /// In de, this message translates to:
  /// **'Batchim'**
  String get chosungSlotBatchim;

  /// No description provided for @errorUnknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Fehler'**
  String get errorUnknown;

  /// No description provided for @questTypeUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Quest-Typ \"{type}\" ist noch nicht verfügbar.'**
  String questTypeUnsupported(Object type);

  /// No description provided for @customPackCsvHint.
  ///
  /// In de, this message translates to:
  /// **'안녕하세요, Hallo\\n사과, Apfel'**
  String get customPackCsvHint;

  /// No description provided for @packStateLocked.
  ///
  /// In de, this message translates to:
  /// **'gesperrt'**
  String get packStateLocked;

  /// No description provided for @packStatePremium.
  ///
  /// In de, this message translates to:
  /// **'Premium'**
  String get packStatePremium;

  /// No description provided for @packStateCleared.
  ///
  /// In de, this message translates to:
  /// **'geschafft'**
  String get packStateCleared;

  /// No description provided for @packStateAvailable.
  ///
  /// In de, this message translates to:
  /// **'verfügbar'**
  String get packStateAvailable;

  /// No description provided for @packSemantics.
  ///
  /// In de, this message translates to:
  /// **'Paket {title}, {state}, {learned} von {total} gelernt'**
  String packSemantics(Object title, Object state, int learned, int total);

  /// No description provided for @packLockedHintShort.
  ///
  /// In de, this message translates to:
  /// **'Vorher freischalten'**
  String get packLockedHintShort;

  /// No description provided for @smalltalkUseWith.
  ///
  /// In de, this message translates to:
  /// **'Passend für: {context}'**
  String smalltalkUseWith(Object context);

  /// No description provided for @smalltalkSaferAlternativeAndNext.
  ///
  /// In de, this message translates to:
  /// **'Sichere Alternative und nächster Schritt'**
  String get smalltalkSaferAlternativeAndNext;

  /// No description provided for @smalltalkSaferAlternative.
  ///
  /// In de, this message translates to:
  /// **'Sichere Alternative'**
  String get smalltalkSaferAlternative;

  /// No description provided for @smalltalkNextTurn.
  ///
  /// In de, this message translates to:
  /// **'Nächster Gesprächsschritt'**
  String get smalltalkNextTurn;

  /// No description provided for @smalltalkNextPhrase.
  ///
  /// In de, this message translates to:
  /// **'Nächster Ausdruck'**
  String get smalltalkNextPhrase;

  /// No description provided for @smalltalkPreviousPhrase.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Ausdruck'**
  String get smalltalkPreviousPhrase;

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
  /// **'Seite gerade, scharf und eng zugeschnitten aufnehmen. Das Bild bleibt auf deinem Gerät; nur erkannter Text wird analysiert.'**
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
  /// **'Kein verlässliches Koreanisch erkannt. Fotografiere die Seite gerade, scharf und näher.'**
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
  /// **'{count} Textzeilen erkannt. Vergleiche und korrigiere sie bei Bedarf.'**
  String bookPreviewHint(int count);

  /// No description provided for @bookPreviewTextFieldHint.
  ///
  /// In de, this message translates to:
  /// **'Koreanischer Text …'**
  String get bookPreviewTextFieldHint;

  /// No description provided for @bookPreviewEditorLabel.
  ///
  /// In de, this message translates to:
  /// **'Erkannter Text'**
  String get bookPreviewEditorLabel;

  /// No description provided for @bookPreviewQualityWarning.
  ///
  /// In de, this message translates to:
  /// **'Unsichere oder nicht unterstützte Schrift wurde entfernt. Prüfe den koreanischen Text vor der Analyse sorgfältig.'**
  String get bookPreviewQualityWarning;

  /// No description provided for @bookPreviewSevereQualityWarning.
  ///
  /// In de, this message translates to:
  /// **'Die Aufnahme oder Texterkennung ist zu unsicher. Nimm das Foto am besten neu auf. Wenn du trotzdem fortfahren möchtest, korrigiere zuerst selbst den OCR-Text.'**
  String get bookPreviewSevereQualityWarning;

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

  /// No description provided for @dojangEmptyCta.
  ///
  /// In de, this message translates to:
  /// **'Vokabelpakete öffnen'**
  String get dojangEmptyCta;

  /// No description provided for @dojangProgress.
  ///
  /// In de, this message translates to:
  /// **'{earned} von {total} Stempeln gesammelt'**
  String dojangProgress(int earned, int total);

  /// No description provided for @dojangSeriesDancheongTitle.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Muster'**
  String get dojangSeriesDancheongTitle;

  /// No description provided for @dojangSeriesDancheongBody.
  ///
  /// In de, this message translates to:
  /// **'Traditionelle Farb- und Ornamentmotive aus der bisherigen Sammlung.'**
  String get dojangSeriesDancheongBody;

  /// No description provided for @dojangSeriesLivingCultureTitle.
  ///
  /// In de, this message translates to:
  /// **'Koreanische Alltagskultur'**
  String get dojangSeriesLivingCultureTitle;

  /// No description provided for @dojangSeriesLivingCultureBody.
  ///
  /// In de, this message translates to:
  /// **'Gegenstände, Zeichen und Glücksmotive aus Lernen, Wohnen, Essen und Alltag.'**
  String get dojangSeriesLivingCultureBody;

  /// No description provided for @dojangReconciled.
  ///
  /// In de, this message translates to:
  /// **'In deinen Abschlüssen wurden {count} neue Stempel gefunden.'**
  String dojangReconciled(int count);

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

  /// No description provided for @gyeCreatingLoading.
  ///
  /// In de, this message translates to:
  /// **'Gye wird erstellt…'**
  String get gyeCreatingLoading;

  /// No description provided for @gyeJoiningLoading.
  ///
  /// In de, this message translates to:
  /// **'Gye-Beitritt läuft…'**
  String get gyeJoiningLoading;

  /// No description provided for @gyeCreatedTitle.
  ///
  /// In de, this message translates to:
  /// **'Gye erstellt!'**
  String get gyeCreatedTitle;

  /// No description provided for @gyeCreatedAnnouncement.
  ///
  /// In de, this message translates to:
  /// **'Gye {name} wurde erstellt. Beitrittscode: {code}.'**
  String gyeCreatedAnnouncement(Object name, Object code);

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
  /// **'{name} ist beigetreten!'**
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

  /// No description provided for @bookResultQualityNotice.
  ///
  /// In de, this message translates to:
  /// **'Unsichere oder nicht-koreanische Inhalte wurden nicht in Wörter, Grammatik oder Audio übernommen.'**
  String get bookResultQualityNotice;

  /// No description provided for @bookResultTranslationUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Der Übersetzungsdienst hat nicht alle Bedeutungen geliefert. Prüfe das Ergebnis vor dem Speichern oder versuche es erneut.'**
  String get bookResultTranslationUnavailable;

  /// No description provided for @bookResultNoKoreanNotice.
  ///
  /// In de, this message translates to:
  /// **'Es blieb kein verlässlicher koreanischer Text übrig. Bitte prüfe den Text oder nimm die Seite neu auf.'**
  String get bookResultNoKoreanNotice;

  /// No description provided for @bookResultSectionWords.
  ///
  /// In de, this message translates to:
  /// **'Wörter'**
  String get bookResultSectionWords;

  /// No description provided for @bookResultSectionExpressions.
  ///
  /// In de, this message translates to:
  /// **'Ausdrücke'**
  String get bookResultSectionExpressions;

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

  /// No description provided for @bookStudyAskTitle.
  ///
  /// In de, this message translates to:
  /// **'Frag {name} zu diesem Eintrag'**
  String bookStudyAskTitle(String name);

  /// No description provided for @bookStudyAskGenericTitle.
  ///
  /// In de, this message translates to:
  /// **'Fragen zu diesem Eintrag'**
  String get bookStudyAskGenericTitle;

  /// No description provided for @bookStudyAskButton.
  ///
  /// In de, this message translates to:
  /// **'Begleiter fragen'**
  String get bookStudyAskButton;

  /// No description provided for @bookStudyAskWhyForm.
  ///
  /// In de, this message translates to:
  /// **'Warum sieht diese Form so aus?'**
  String get bookStudyAskWhyForm;

  /// No description provided for @bookStudyAskExample.
  ///
  /// In de, this message translates to:
  /// **'Zeig ein Beispiel von dieser Seite'**
  String get bookStudyAskExample;

  /// No description provided for @bookStudyAskCompare.
  ///
  /// In de, this message translates to:
  /// **'Mit ähnlicher Grammatik vergleichen'**
  String get bookStudyAskCompare;

  /// No description provided for @bookStudyAskQuiz.
  ///
  /// In de, this message translates to:
  /// **'Stell mir eine kurze Aufgabe'**
  String get bookStudyAskQuiz;

  /// No description provided for @bookStudyAskMeaning.
  ///
  /// In de, this message translates to:
  /// **'Was bedeutet das?'**
  String get bookStudyAskMeaning;

  /// No description provided for @bookStudyAskGrammarInSentence.
  ///
  /// In de, this message translates to:
  /// **'Welche Grammatik wird hier verwendet?'**
  String get bookStudyAskGrammarInSentence;

  /// No description provided for @bookStudyNoEvidence.
  ///
  /// In de, this message translates to:
  /// **'Dafür habe ich in der Analyse dieser Seite keinen Beleg gefunden.'**
  String get bookStudyNoEvidence;

  /// No description provided for @bookStudyAdditionalExample.
  ///
  /// In de, this message translates to:
  /// **'Weiteres belegtes Beispiel'**
  String get bookStudyAdditionalExample;

  /// No description provided for @bookStudyQuizPrompt.
  ///
  /// In de, this message translates to:
  /// **'Antworte nur mit den Belegen auf dieser Seite.'**
  String get bookStudyQuizPrompt;

  /// No description provided for @bookStudyShowAnswer.
  ///
  /// In de, this message translates to:
  /// **'Antwort zeigen'**
  String get bookStudyShowAnswer;

  /// No description provided for @bookStudyTaegoAnswerLead.
  ///
  /// In de, this message translates to:
  /// **'Prüfen wir es Schritt für Schritt.'**
  String get bookStudyTaegoAnswerLead;

  /// No description provided for @bookStudyJoyAnswerLead.
  ///
  /// In de, this message translates to:
  /// **'Hier ist die Kurzfassung!'**
  String get bookStudyJoyAnswerLead;

  /// No description provided for @bookStudyTaegoIntro.
  ///
  /// In de, this message translates to:
  /// **'Ich zeige dir genau die belegte Stelle.'**
  String get bookStudyTaegoIntro;

  /// No description provided for @bookStudyJoyIntro.
  ///
  /// In de, this message translates to:
  /// **'Schauen wir uns die belegte Stelle gemeinsam an!'**
  String get bookStudyJoyIntro;

  /// No description provided for @bookStudyGenericIntro.
  ///
  /// In de, this message translates to:
  /// **'Die Antwort stammt nur aus dem geprüften Analyseergebnis.'**
  String get bookStudyGenericIntro;

  /// No description provided for @bookStudyEvidenceLabel.
  ///
  /// In de, this message translates to:
  /// **'Beleg aus dieser Seite'**
  String get bookStudyEvidenceLabel;

  /// No description provided for @bookResultSave.
  ///
  /// In de, this message translates to:
  /// **'In meinem Bücherregal speichern'**
  String get bookResultSave;

  /// No description provided for @bookResultSaving.
  ///
  /// In de, this message translates to:
  /// **'Seite wird gespeichert…'**
  String get bookResultSaving;

  /// No description provided for @bookResultSaveUnresolved.
  ///
  /// In de, this message translates to:
  /// **'Speicherstatus konnte nicht bestätigt werden'**
  String get bookResultSaveUnresolved;

  /// No description provided for @bookResultSaveUnresolvedBody.
  ///
  /// In de, this message translates to:
  /// **'Prüfe dein Bücherregal, bevor du erneut versuchst, diese Seite zu speichern.'**
  String get bookResultSaveUnresolvedBody;

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

  /// No description provided for @questsInProgressCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Quest läuft} other{{count} Quests laufen}}'**
  String questsInProgressCount(int count);

  /// No description provided for @questsRewardSemantics.
  ///
  /// In de, this message translates to:
  /// **'Belohnung: {reward}'**
  String questsRewardSemantics(String reward);

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
  /// **'Deine gesammelten Dancheong-Stempel sind jetzt auch Gestaltungselemente. Platziere sie frei in deiner Sarangbang; im Stempelbuch bleiben sie weiterhin sichtbar.'**
  String get dojangDecorHintBody;

  /// No description provided for @dojangDecorHintCta.
  ///
  /// In de, this message translates to:
  /// **'Sarangbang gestalten'**
  String get dojangDecorHintCta;

  /// No description provided for @dojangStampEarned.
  ///
  /// In de, this message translates to:
  /// **'{stamp}, gesammelt'**
  String dojangStampEarned(String stamp);

  /// No description provided for @dojangStampLocked.
  ///
  /// In de, this message translates to:
  /// **'{stamp}, noch nicht gesammelt'**
  String dojangStampLocked(String stamp);

  /// No description provided for @hanokCinematicIntro.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok wächst.'**
  String get hanokCinematicIntro;

  /// No description provided for @hanokA1MapLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok im Bau'**
  String get hanokA1MapLabel;

  /// No description provided for @hanokA1MapUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Hanok-Illustration nicht verfügbar'**
  String get hanokA1MapUnavailable;

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

  /// Learn stage counter suffix for re-served (missed) cards
  ///
  /// In de, this message translates to:
  /// **' · +{n, plural, one{1 Wdh.} other{{n} Wdh.}}'**
  String vocabPackLearnRepeatSuffix(int n);

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

  /// No description provided for @deckActionSave.
  ///
  /// In de, this message translates to:
  /// **'Merken'**
  String get deckActionSave;

  /// No description provided for @contentActionFlip.
  ///
  /// In de, this message translates to:
  /// **'Umdrehen'**
  String get contentActionFlip;

  /// No description provided for @contentActionLike.
  ///
  /// In de, this message translates to:
  /// **'Gefällt mir'**
  String get contentActionLike;

  /// No description provided for @contentActionShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get contentActionShare;

  /// No description provided for @contentActionBookmark.
  ///
  /// In de, this message translates to:
  /// **'Merken'**
  String get contentActionBookmark;

  /// No description provided for @contentActionBookmarkSaved.
  ///
  /// In de, this message translates to:
  /// **'Gemerkt'**
  String get contentActionBookmarkSaved;

  /// No description provided for @contentActionBookmarkUnsaved.
  ///
  /// In de, this message translates to:
  /// **'Nicht gemerkt'**
  String get contentActionBookmarkUnsaved;

  /// No description provided for @contentActionLikeLiked.
  ///
  /// In de, this message translates to:
  /// **'Gelikt'**
  String get contentActionLikeLiked;

  /// No description provided for @contentActionLikeNotLiked.
  ///
  /// In de, this message translates to:
  /// **'Nicht gelikt'**
  String get contentActionLikeNotLiked;

  /// No description provided for @speechIndicatorLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorlesen'**
  String get speechIndicatorLabel;

  /// No description provided for @speechIndicatorSpeaking.
  ///
  /// In de, this message translates to:
  /// **'Wird vorgelesen'**
  String get speechIndicatorSpeaking;

  /// No description provided for @speechIndicatorIdle.
  ///
  /// In de, this message translates to:
  /// **'Nicht aktiv'**
  String get speechIndicatorIdle;

  /// No description provided for @contentShareBody.
  ///
  /// In de, this message translates to:
  /// **'{korean}\n{gloss}\nhangul-sori.com'**
  String contentShareBody(String korean, String gloss);

  /// No description provided for @contentShareFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Bild konnte nicht geteilt werden'**
  String get contentShareFailedTitle;

  /// No description provided for @contentShareFailedBody.
  ///
  /// In de, this message translates to:
  /// **'Versuche es erneut oder kopiere stattdessen den Text.'**
  String get contentShareFailedBody;

  /// No description provided for @contentShareRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get contentShareRetry;

  /// No description provided for @contentShareCopyText.
  ///
  /// In de, this message translates to:
  /// **'Text kopieren'**
  String get contentShareCopyText;

  /// No description provided for @contentShareCopied.
  ///
  /// In de, this message translates to:
  /// **'Text kopiert'**
  String get contentShareCopied;

  /// No description provided for @contentShareCopyFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Text konnte nicht kopiert werden.'**
  String get contentShareCopyFailed;

  /// No description provided for @deckFlipFirstHint.
  ///
  /// In de, this message translates to:
  /// **'Erst antippen und umdrehen'**
  String get deckFlipFirstHint;

  /// No description provided for @coachSoriDeckTitle.
  ///
  /// In de, this message translates to:
  /// **'Karte weiterwischen'**
  String get coachSoriDeckTitle;

  /// No description provided for @coachSoriDeckBody.
  ///
  /// In de, this message translates to:
  /// **'Wische nach oben oder unten zur nächsten Karte. ? dreht um, Herz merkt für später, Lesezeichen legt ins Wörterbuch.'**
  String get coachSoriDeckBody;

  /// No description provided for @coachSoriDeckBodyNoSave.
  ///
  /// In de, this message translates to:
  /// **'Wische nach oben oder unten zur nächsten Karte. ? dreht um, Herz merkt für später.'**
  String get coachSoriDeckBodyNoSave;

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
  /// **'Paket abgeschlossen!'**
  String get vocabPackResultCleared;

  /// No description provided for @vocabPackResultClearedAgain.
  ///
  /// In de, this message translates to:
  /// **'Schon abgeschlossen. Gut wiederholt!'**
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

  /// No description provided for @vocabPackResultRecallCta.
  ///
  /// In de, this message translates to:
  /// **'Auf Koreanisch abrufen'**
  String get vocabPackResultRecallCta;

  /// No description provided for @vocabPackResultHardWordsCta.
  ///
  /// In de, this message translates to:
  /// **'Schwierige Wörter üben'**
  String get vocabPackResultHardWordsCta;

  /// No description provided for @vocabPackResultBackToGrid.
  ///
  /// In de, this message translates to:
  /// **'Zurück zu den Paketen'**
  String get vocabPackResultBackToGrid;

  /// No description provided for @vocabPackResultGeschafft.
  ///
  /// In de, this message translates to:
  /// **'Geschafft! Wiederhole diese Wörter später noch einmal.'**
  String get vocabPackResultGeschafft;

  /// No description provided for @vocabPackRecallTitle.
  ///
  /// In de, this message translates to:
  /// **'Aus dem Gedächtnis'**
  String get vocabPackRecallTitle;

  /// No description provided for @vocabPackRecallIntro.
  ///
  /// In de, this message translates to:
  /// **'Optional: Sieh die Bedeutung und tippe das koreanische Wort.'**
  String get vocabPackRecallIntro;

  /// No description provided for @vocabPackRecallPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt das auf Koreanisch?'**
  String get vocabPackRecallPrompt;

  /// No description provided for @vocabPackRecallInputHint.
  ///
  /// In de, this message translates to:
  /// **'Auf Koreanisch eingeben …'**
  String get vocabPackRecallInputHint;

  /// No description provided for @vocabPackRecallHintCta.
  ///
  /// In de, this message translates to:
  /// **'Erste Silbe zeigen'**
  String get vocabPackRecallHintCta;

  /// No description provided for @vocabPackRecallHintLabel.
  ///
  /// In de, this message translates to:
  /// **'Beginnt mit „{hint}“'**
  String vocabPackRecallHintLabel(Object hint);

  /// No description provided for @vocabPackRecallShowAnswerCta.
  ///
  /// In de, this message translates to:
  /// **'Antwort zeigen'**
  String get vocabPackRecallShowAnswerCta;

  /// No description provided for @vocabPackRecallCorrect.
  ///
  /// In de, this message translates to:
  /// **'Richtig. Direkt erinnert.'**
  String get vocabPackRecallCorrect;

  /// No description provided for @vocabPackRecallCorrectWithHint.
  ///
  /// In de, this message translates to:
  /// **'Richtig, mit Hinweis.'**
  String get vocabPackRecallCorrectWithHint;

  /// No description provided for @vocabPackRecallIncorrect.
  ///
  /// In de, this message translates to:
  /// **'Nicht ganz.'**
  String get vocabPackRecallIncorrect;

  /// No description provided for @vocabPackRecallRevealed.
  ///
  /// In de, this message translates to:
  /// **'Antwort gezeigt.'**
  String get vocabPackRecallRevealed;

  /// No description provided for @vocabPackRecallAnswer.
  ///
  /// In de, this message translates to:
  /// **'Richtig: {answer}'**
  String vocabPackRecallAnswer(Object answer);

  /// No description provided for @vocabPackRecallDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Abrufübung beendet'**
  String get vocabPackRecallDoneTitle;

  /// No description provided for @vocabPackRecallDoneScore.
  ///
  /// In de, this message translates to:
  /// **'{correct} von {total} direkt erinnert'**
  String vocabPackRecallDoneScore(int correct, int total);

  /// No description provided for @vocabPackRecallReviewLater.
  ///
  /// In de, this message translates to:
  /// **'Wiederhole diese Wörter später noch einmal.'**
  String get vocabPackRecallReviewLater;

  /// No description provided for @vocabPackRecallBackToResult.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Ergebnis'**
  String get vocabPackRecallBackToResult;

  /// No description provided for @vocabPackRecallNoBossWords.
  ///
  /// In de, this message translates to:
  /// **'Dieses Paket hat keine Boss-Wörter für die Tippübung.'**
  String get vocabPackRecallNoBossWords;

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
  /// **'Triff deinen Lernfreund'**
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
  /// **'Kurz genug für zwischendurch'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In de, this message translates to:
  /// **'Dranbleiben zählt'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Wenn du regelmäßig lernst, gibt\'s Belohnungen.'**
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
  /// **'Dein Einstieg'**
  String get onboardingStartEyebrow;

  /// No description provided for @onboardingStartTitle.
  ///
  /// In de, this message translates to:
  /// **'Wofür willst du Koreanisch können?'**
  String get onboardingStartTitle;

  /// No description provided for @onboardingStartBody.
  ///
  /// In de, this message translates to:
  /// **'So merken wir uns, womit du anfängst. Das ist kein Test.'**
  String get onboardingStartBody;

  /// No description provided for @onboardingStartTravelTitle.
  ///
  /// In de, this message translates to:
  /// **'Unterwegs in Korea'**
  String get onboardingStartTravelTitle;

  /// No description provided for @onboardingStartTravelBody.
  ///
  /// In de, this message translates to:
  /// **'Café, Weg fragen, einkaufen, Hilfe holen'**
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
  /// **'Höflich fragen und mitkommen'**
  String get onboardingStartWorkBody;

  /// No description provided for @onboardingStartPoint.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt'**
  String get onboardingStartPoint;

  /// No description provided for @onboardingStartNewTitle.
  ///
  /// In de, this message translates to:
  /// **'Ich fange neu an'**
  String get onboardingStartNewTitle;

  /// No description provided for @onboardingStartNewBody.
  ///
  /// In de, this message translates to:
  /// **'Gleich mit Hören und Sprechen'**
  String get onboardingStartNewBody;

  /// No description provided for @onboardingStartExistingTitle.
  ///
  /// In de, this message translates to:
  /// **'Ich kann schon etwas'**
  String get onboardingStartExistingTitle;

  /// No description provided for @onboardingStartExistingBody.
  ///
  /// In de, this message translates to:
  /// **'Level wählen oder acht bis zehn Fragen beantworten'**
  String get onboardingStartExistingBody;

  /// No description provided for @onboardingStartPrimary.
  ///
  /// In de, this message translates to:
  /// **'Meine erste Szene starten'**
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

  /// No description provided for @onboardingStartChangePoint.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt ändern'**
  String get onboardingStartChangePoint;

  /// No description provided for @onboardingFirstSceneTravelCanDo.
  ///
  /// In de, this message translates to:
  /// **'Ich kann bei der Einreise höflich antworten.'**
  String get onboardingFirstSceneTravelCanDo;

  /// No description provided for @onboardingFirstScenePeopleCanDo.
  ///
  /// In de, this message translates to:
  /// **'Ich kann mich freundlich vorstellen.'**
  String get onboardingFirstScenePeopleCanDo;

  /// No description provided for @onboardingFirstSceneWorkCanDo.
  ///
  /// In de, this message translates to:
  /// **'Ich kann mich im Kurs oder auf der Arbeit kurz vorstellen.'**
  String get onboardingFirstSceneWorkCanDo;

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

  /// No description provided for @onboardingCompanionEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernfreund'**
  String get onboardingCompanionEyebrow;

  /// No description provided for @onboardingCompanionPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wähle Taego oder Joy. Beide helfen dir, und du kannst dich auch später entscheiden.'**
  String get onboardingCompanionPrompt;

  /// No description provided for @onboardingCompanionSelectedTiger.
  ///
  /// In de, this message translates to:
  /// **'Taego kommt mit.'**
  String get onboardingCompanionSelectedTiger;

  /// No description provided for @onboardingCompanionSelectedMagpie.
  ///
  /// In de, this message translates to:
  /// **'Joy kommt mit.'**
  String get onboardingCompanionSelectedMagpie;

  /// No description provided for @onboardingCompanionSelectionBody.
  ///
  /// In de, this message translates to:
  /// **'Im Profil kannst du das später ändern.'**
  String get onboardingCompanionSelectionBody;

  /// No description provided for @onboardingCompanionContinue.
  ///
  /// In de, this message translates to:
  /// **'Mit Begleitung weiter zu Heute'**
  String get onboardingCompanionContinue;

  /// No description provided for @onboardingCompanionChange.
  ///
  /// In de, this message translates to:
  /// **'Anders wählen'**
  String get onboardingCompanionChange;

  /// No description provided for @firstVoiceStamp.
  ///
  /// In de, this message translates to:
  /// **'ERSTE\nSTIMME'**
  String get firstVoiceStamp;

  /// No description provided for @firstVoiceTitle.
  ///
  /// In de, this message translates to:
  /// **'Du hast dein erstes Koreanisch verstanden.'**
  String get firstVoiceTitle;

  /// No description provided for @firstVoiceBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast einen koreanischen Ausdruck verstanden und kannst ihn in der Szene brauchen.'**
  String get firstVoiceBody;

  /// No description provided for @firstVoicePhraseBody.
  ///
  /// In de, this message translates to:
  /// **'ein Satz, den du jetzt hören und erwidern kannst.'**
  String get firstVoicePhraseBody;

  /// No description provided for @firstVoiceSceneSummary.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {total} Aufgaben abgeschlossen'**
  String firstVoiceSceneSummary(int completed, int total);

  /// No description provided for @firstVoiceCanDo.
  ///
  /// In de, this message translates to:
  /// **'Ich kann jemanden freundlich begrüßen.'**
  String get firstVoiceCanDo;

  /// No description provided for @firstVoiceCanDoBody.
  ///
  /// In de, this message translates to:
  /// **'Dein A1-Weg beginnt mit dieser Szene.'**
  String get firstVoiceCanDoBody;

  /// No description provided for @firstVoiceCompanionTitle.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du eine Lernbegleitung?'**
  String get firstVoiceCompanionTitle;

  /// No description provided for @firstVoiceCompanionBody.
  ///
  /// In de, this message translates to:
  /// **'Taego oder Joy feiert mit und erklärt Hinweise. Die Wahl kannst du auch später treffen.'**
  String get firstVoiceCompanionBody;

  /// No description provided for @firstVoiceSkip.
  ///
  /// In de, this message translates to:
  /// **'Direkt zu Heute'**
  String get firstVoiceSkip;

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
  /// **'Alltagsgespräche klappen schon'**
  String get onboardingLevelB1Desc;

  /// No description provided for @onboardingLevelB2.
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get onboardingLevelB2;

  /// No description provided for @onboardingLevelB2Desc.
  ///
  /// In de, this message translates to:
  /// **'Flüssig, auch mit Nuancen'**
  String get onboardingLevelB2Desc;

  /// No description provided for @onboardingLevelC1.
  ///
  /// In de, this message translates to:
  /// **'Kompetent'**
  String get onboardingLevelC1;

  /// No description provided for @onboardingLevelC1Desc.
  ///
  /// In de, this message translates to:
  /// **'Belege, Behörden, feine Unterschiede'**
  String get onboardingLevelC1Desc;

  /// No description provided for @onboardingLevelC2.
  ///
  /// In de, this message translates to:
  /// **'Expertenniveau'**
  String get onboardingLevelC2;

  /// No description provided for @onboardingLevelC2Desc.
  ///
  /// In de, this message translates to:
  /// **'Texte zerlegen und bewusst formulieren'**
  String get onboardingLevelC2Desc;

  /// No description provided for @onboardingExampleA1Trans.
  ///
  /// In de, this message translates to:
  /// **'Hallo / Guten Tag.'**
  String get onboardingExampleA1Trans;

  /// No description provided for @onboardingExampleA2Trans.
  ///
  /// In de, this message translates to:
  /// **'Einen Americano, bitte.'**
  String get onboardingExampleA2Trans;

  /// No description provided for @onboardingExampleB1Trans.
  ///
  /// In de, this message translates to:
  /// **'Gestern habe ich mit einem Freund einen Film gesehen.'**
  String get onboardingExampleB1Trans;

  /// No description provided for @onboardingExampleB2Trans.
  ///
  /// In de, this message translates to:
  /// **'Das Meeting zieht sich, ich komme wohl etwas später.'**
  String get onboardingExampleB2Trans;

  /// No description provided for @onboardingExampleC1Trans.
  ///
  /// In de, this message translates to:
  /// **'Ich erkläre bestätigte Fakten und unsere jetzige Deutung getrennt.'**
  String get onboardingExampleC1Trans;

  /// No description provided for @onboardingExampleC2Trans.
  ///
  /// In de, this message translates to:
  /// **'Wer Schweigen als Zustimmung wertet, kann schon durch den Rahmen einer Frage Beteiligung einschränken.'**
  String get onboardingExampleC2Trans;

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
  /// **'Alles klar'**
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
  /// **'Beruf und Nachrichten, Nuancen, Redewendungen, Höflichkeitsformen.'**
  String get onboardingLevelB2Learn;

  /// No description provided for @onboardingLevelC1Can.
  ///
  /// In de, this message translates to:
  /// **'Du kannst schwierige Themen besprechen und sagen, wie sicher du dir bist.'**
  String get onboardingLevelC1Can;

  /// No description provided for @onboardingLevelC1Learn.
  ///
  /// In de, this message translates to:
  /// **'Belege, Unsicherheit, inklusive Systeme, öffentliche Erklärungen.'**
  String get onboardingLevelC1Learn;

  /// No description provided for @onboardingLevelC2Can.
  ///
  /// In de, this message translates to:
  /// **'Du kannst Annahmen, Frage-Rahmen und Behördensprache auseinandernehmen.'**
  String get onboardingLevelC2Can;

  /// No description provided for @onboardingLevelC2Learn.
  ///
  /// In de, this message translates to:
  /// **'Diskurs, Deutung, Technikethik, verantwortliche Entscheidungen.'**
  String get onboardingLevelC2Learn;

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
  /// **'Übe mit echten Alltagssituationen'**
  String get scenariosListSubtitle;

  /// No description provided for @scenariosCardMeta.
  ///
  /// In de, this message translates to:
  /// **'5 bis 7 Minuten · +{xp} XP'**
  String scenariosCardMeta(int xp);

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

  /// No description provided for @scenarioQuestProgress.
  ///
  /// In de, this message translates to:
  /// **'{current} von {total}'**
  String scenarioQuestProgress(int current, int total);

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

  /// No description provided for @scenarioSavedEyebrow.
  ///
  /// In de, this message translates to:
  /// **'DEINE SZENE IST GESPEICHERT'**
  String get scenarioSavedEyebrow;

  /// No description provided for @scenarioSavedTitle.
  ///
  /// In de, this message translates to:
  /// **'Du kannst jetzt zum Hanok zurück.'**
  String get scenarioSavedTitle;

  /// No description provided for @scenarioSavedPhrase.
  ///
  /// In de, this message translates to:
  /// **'Ein Satz für deine nächste Szene'**
  String get scenarioSavedPhrase;

  /// No description provided for @scenarioSavedStructure.
  ///
  /// In de, this message translates to:
  /// **'Struktur für diese Szene'**
  String get scenarioSavedStructure;

  /// No description provided for @scenarioSavedEmpty.
  ///
  /// In de, this message translates to:
  /// **'Deine Übung ist gespeichert und steht für die Wiederholung bereit.'**
  String get scenarioSavedEmpty;

  /// No description provided for @scenarioSavedReturnHanok.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Hanok'**
  String get scenarioSavedReturnHanok;

  /// No description provided for @scenarioSavedRepeat.
  ///
  /// In de, this message translates to:
  /// **'Diese Szene noch einmal üben'**
  String get scenarioSavedRepeat;

  /// No description provided for @scenarioResultSaving.
  ///
  /// In de, this message translates to:
  /// **'Diese abgeschlossene Szene wird gespeichert…'**
  String get scenarioResultSaving;

  /// No description provided for @scenarioResultSaveRetry.
  ///
  /// In de, this message translates to:
  /// **'Speichern erneut versuchen'**
  String get scenarioResultSaveRetry;

  /// No description provided for @scenarioStructureChangedTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok hat sich verändert.'**
  String get scenarioStructureChangedTitle;

  /// No description provided for @scenarioStructureChangedBody.
  ///
  /// In de, this message translates to:
  /// **'Neue Struktur: {stage}'**
  String scenarioStructureChangedBody(String stage);

  /// No description provided for @scenarioStructureUnchangedTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok behält seine aktuelle Struktur.'**
  String get scenarioStructureUnchangedTitle;

  /// No description provided for @scenarioStructureUnchangedBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Checkpoint hat noch keine neue Struktur freigeschaltet.'**
  String get scenarioStructureUnchangedBody;

  /// No description provided for @scenarioStructureUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Struktur deines Hanoks'**
  String get scenarioStructureUnavailableTitle;

  /// No description provided for @scenarioStructureUnavailableBody.
  ///
  /// In de, this message translates to:
  /// **'Öffne dein Hanok, um den aktuell bestätigten Bau zu sehen.'**
  String get scenarioStructureUnavailableBody;

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

  /// No description provided for @questAnswerSelected.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählt'**
  String get questAnswerSelected;

  /// No description provided for @questAnswerRevealed.
  ///
  /// In de, this message translates to:
  /// **'Die richtige Antwort wird angezeigt.'**
  String get questAnswerRevealed;

  /// No description provided for @questTryAgainHint.
  ///
  /// In de, this message translates to:
  /// **'Fast. Versuch es noch einmal.'**
  String get questTryAgainHint;

  /// No description provided for @questViewResult.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis ansehen'**
  String get questViewResult;

  /// No description provided for @questDontKnowYet.
  ///
  /// In de, this message translates to:
  /// **'Weiß ich noch nicht'**
  String get questDontKnowYet;

  /// No description provided for @questListeningQuestion.
  ///
  /// In de, this message translates to:
  /// **'Was bedeutet dieser Satz?'**
  String get questListeningQuestion;

  /// No description provided for @questTypeListening.
  ///
  /// In de, this message translates to:
  /// **'Hören'**
  String get questTypeListening;

  /// No description provided for @questTypeTranslation.
  ///
  /// In de, this message translates to:
  /// **'Übersetzen'**
  String get questTypeTranslation;

  /// No description provided for @questTypeCloze.
  ///
  /// In de, this message translates to:
  /// **'Lücke füllen'**
  String get questTypeCloze;

  /// No description provided for @questTypeParticle.
  ///
  /// In de, this message translates to:
  /// **'Partikel wählen'**
  String get questTypeParticle;

  /// No description provided for @questTypeBatchim.
  ///
  /// In de, this message translates to:
  /// **'Batchim ergänzen'**
  String get questTypeBatchim;

  /// No description provided for @questTypeSentence.
  ///
  /// In de, this message translates to:
  /// **'Satz bauen'**
  String get questTypeSentence;

  /// No description provided for @questTypeDictation.
  ///
  /// In de, this message translates to:
  /// **'Diktat'**
  String get questTypeDictation;

  /// No description provided for @questTypeWriting.
  ///
  /// In de, this message translates to:
  /// **'Schreiben'**
  String get questTypeWriting;

  /// No description provided for @diktatUseWordBlocks.
  ///
  /// In de, this message translates to:
  /// **'Keine koreanische Tastatur? Wortblöcke verwenden'**
  String get diktatUseWordBlocks;

  /// No description provided for @diktatUseKeyboard.
  ///
  /// In de, this message translates to:
  /// **'Mit der Tastatur schreiben'**
  String get diktatUseKeyboard;

  /// No description provided for @particlePopHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle die richtige Partikel für den Satz.'**
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

  /// No description provided for @statsWeekDaySemantics.
  ///
  /// In de, this message translates to:
  /// **'{weekday}: {status, select, todayCompleted{heute, geschafft} today{heute} completed{geschafft} pending{noch offen} other{noch offen}}'**
  String statsWeekDaySemantics(String weekday, String status);

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
  /// **'Für heute bist du fertig. Morgen gibt es neue Missionen.'**
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
  /// **'Gemerkt'**
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
  /// **'Noch nichts gemerkt\nTippe auf das Lesezeichen, um Wörter zu speichern.'**
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

  /// No description provided for @listeningDialogueStart.
  ///
  /// In de, this message translates to:
  /// **'Dialog anhören'**
  String get listeningDialogueStart;

  /// No description provided for @listeningSceneIntro.
  ///
  /// In de, this message translates to:
  /// **'Szene'**
  String get listeningSceneIntro;

  /// No description provided for @listeningParticipants.
  ///
  /// In de, this message translates to:
  /// **'Sprechende'**
  String get listeningParticipants;

  /// No description provided for @listeningLineCount.
  ///
  /// In de, this message translates to:
  /// **'{n} Zeilen'**
  String listeningLineCount(int n);

  /// No description provided for @listeningPause.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get listeningPause;

  /// No description provided for @listeningResume.
  ///
  /// In de, this message translates to:
  /// **'Weiterhören'**
  String get listeningResume;

  /// No description provided for @listeningShowTranslation.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung zeigen'**
  String get listeningShowTranslation;

  /// No description provided for @listeningHideTranslation.
  ///
  /// In de, this message translates to:
  /// **'Übersetzung ausblenden'**
  String get listeningHideTranslation;

  /// No description provided for @listeningNarrator.
  ///
  /// In de, this message translates to:
  /// **'Erzählstimme'**
  String get listeningNarrator;

  /// No description provided for @listeningSpeakerYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get listeningSpeakerYou;

  /// No description provided for @listeningReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeile für Zeile wiederholen'**
  String get listeningReviewTitle;

  /// No description provided for @listeningReviewBody.
  ///
  /// In de, this message translates to:
  /// **'Hör einzelne Zeilen erneut und öffne die Übersetzung nur bei Bedarf.'**
  String get listeningReviewBody;

  /// No description provided for @listeningReviewCta.
  ///
  /// In de, this message translates to:
  /// **'Zeile für Zeile wiederholen'**
  String get listeningReviewCta;

  /// No description provided for @listeningBackToScroll.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Schriftrolle'**
  String get listeningBackToScroll;

  /// No description provided for @listeningNextStory.
  ///
  /// In de, this message translates to:
  /// **'Nächste Geschichte'**
  String get listeningNextStory;

  /// No description provided for @listeningTtsFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Diese Zeile konnte nicht abgespielt werden.'**
  String get listeningTtsFailedTitle;

  /// No description provided for @listeningTtsFailedBody.
  ///
  /// In de, this message translates to:
  /// **'Versuch es erneut oder lerne mit dem koreanischen Text weiter.'**
  String get listeningTtsFailedBody;

  /// No description provided for @listeningRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get listeningRetry;

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

  /// No description provided for @listeningCompleteReplayBody.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Zeile gehört · Belohnung bereits erhalten} other{{n} Zeilen gehört · Belohnung bereits erhalten}}'**
  String listeningCompleteReplayBody(int n);

  /// No description provided for @listeningPickFirst.
  ///
  /// In de, this message translates to:
  /// **'Tippe ein Fach an, um zu starten.'**
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

  /// Screen reader label for one level drawer under the listening shelf.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Level {level}, noch nicht bestückt} =1{Level {level}, 1 Szenario} other{Level {level}, {count} Szenarien}}'**
  String listeningLevelDrawer(String level, int count);

  /// No description provided for @listeningShelfEmpty.
  ///
  /// In de, this message translates to:
  /// **'noch nicht bestückt'**
  String get listeningShelfEmpty;

  /// No description provided for @listeningShelfScenarioCount.
  ///
  /// In de, this message translates to:
  /// **'{n} Szenarien'**
  String listeningShelfScenarioCount(int n);

  /// No description provided for @listeningShelfA1Transit.
  ///
  /// In de, this message translates to:
  /// **'Einsteigen & aussteigen'**
  String get listeningShelfA1Transit;

  /// No description provided for @listeningShelfA1Arrival.
  ///
  /// In de, this message translates to:
  /// **'Taxi, Flughafen & Unterkunft'**
  String get listeningShelfA1Arrival;

  /// No description provided for @listeningShelfA1Counter.
  ///
  /// In de, this message translates to:
  /// **'Läden & Schalter'**
  String get listeningShelfA1Counter;

  /// No description provided for @listeningShelfA1Cafe.
  ///
  /// In de, this message translates to:
  /// **'Café & Imbiss'**
  String get listeningShelfA1Cafe;

  /// No description provided for @listeningShelfA1Home.
  ///
  /// In de, this message translates to:
  /// **'Zuhause & Haustür'**
  String get listeningShelfA1Home;

  /// No description provided for @listeningShelfA1Greeting.
  ///
  /// In de, this message translates to:
  /// **'Begrüßung & Anrede'**
  String get listeningShelfA1Greeting;

  /// No description provided for @listeningShelfA1Repair.
  ///
  /// In de, this message translates to:
  /// **'Ich hab\'s nicht verstanden'**
  String get listeningShelfA1Repair;

  /// No description provided for @listeningShelfA1Health.
  ///
  /// In de, this message translates to:
  /// **'Apotheke, Wetter & Sicherheit'**
  String get listeningShelfA1Health;

  /// No description provided for @listeningShelfA1Family.
  ///
  /// In de, this message translates to:
  /// **'Erster Besuch bei der Partnerfamilie'**
  String get listeningShelfA1Family;

  /// No description provided for @listeningShelfA1Numbers.
  ///
  /// In de, this message translates to:
  /// **'Zahlen & Uhrzeit hören'**
  String get listeningShelfA1Numbers;

  /// No description provided for @listeningShelfA1Phone.
  ///
  /// In de, this message translates to:
  /// **'Anrufe & Nachrichten'**
  String get listeningShelfA1Phone;

  /// No description provided for @listeningShelfA1Wayfinding.
  ///
  /// In de, this message translates to:
  /// **'Wege & Schilder'**
  String get listeningShelfA1Wayfinding;

  /// No description provided for @listeningShelfA2Travel.
  ///
  /// In de, this message translates to:
  /// **'Unterwegs, Unterkunft & Fundsachen'**
  String get listeningShelfA2Travel;

  /// No description provided for @listeningShelfA2Bank.
  ///
  /// In de, this message translates to:
  /// **'Bank, Mobilfunk & Gebühren'**
  String get listeningShelfA2Bank;

  /// No description provided for @listeningShelfA2Shopping.
  ///
  /// In de, this message translates to:
  /// **'Kaufen & abrechnen'**
  String get listeningShelfA2Shopping;

  /// No description provided for @listeningShelfA2Cafe.
  ///
  /// In de, this message translates to:
  /// **'Café & Restaurant'**
  String get listeningShelfA2Cafe;

  /// No description provided for @listeningShelfA2Body.
  ///
  /// In de, this message translates to:
  /// **'Körper, Arzt & Sport'**
  String get listeningShelfA2Body;

  /// No description provided for @listeningShelfA2Neighbourhood.
  ///
  /// In de, this message translates to:
  /// **'Wohnanlage & Nachbarn'**
  String get listeningShelfA2Neighbourhood;

  /// No description provided for @listeningShelfA2Work.
  ///
  /// In de, this message translates to:
  /// **'Erste Schritte im Job'**
  String get listeningShelfA2Work;

  /// No description provided for @listeningShelfA2Plans.
  ///
  /// In de, this message translates to:
  /// **'Verabredungen & Kontakt'**
  String get listeningShelfA2Plans;

  /// No description provided for @listeningShelfA2Family.
  ///
  /// In de, this message translates to:
  /// **'Partnerfamilie & Feiertage'**
  String get listeningShelfA2Family;

  /// No description provided for @listeningShelfA2Delivery.
  ///
  /// In de, this message translates to:
  /// **'Lieferung & Annahme'**
  String get listeningShelfA2Delivery;

  /// No description provided for @listeningShelfA2Enrolment.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung & Unterricht'**
  String get listeningShelfA2Enrolment;

  /// No description provided for @listeningShelfA2Booking.
  ///
  /// In de, this message translates to:
  /// **'Buchen & Umbuchen'**
  String get listeningShelfA2Booking;

  /// No description provided for @listeningShelfB1Repairs.
  ///
  /// In de, this message translates to:
  /// **'Reparaturen & Mängel'**
  String get listeningShelfB1Repairs;

  /// No description provided for @listeningShelfB1Refund.
  ///
  /// In de, this message translates to:
  /// **'Rückerstattung & Garantie'**
  String get listeningShelfB1Refund;

  /// No description provided for @listeningShelfB1Receipts.
  ///
  /// In de, this message translates to:
  /// **'Belege & Abrechnung'**
  String get listeningShelfB1Receipts;

  /// No description provided for @listeningShelfB1Delay.
  ///
  /// In de, this message translates to:
  /// **'Terminänderung & Verspätung'**
  String get listeningShelfB1Delay;

  /// No description provided for @listeningShelfB1Paperwork.
  ///
  /// In de, this message translates to:
  /// **'Unterlagen & Vollmacht'**
  String get listeningShelfB1Paperwork;

  /// No description provided for @listeningShelfB1Team.
  ///
  /// In de, this message translates to:
  /// **'Team & Übergabe'**
  String get listeningShelfB1Team;

  /// No description provided for @listeningShelfB1Neighbours.
  ///
  /// In de, this message translates to:
  /// **'Nachbarn & Gemeinschaftsräume'**
  String get listeningShelfB1Neighbours;

  /// No description provided for @listeningShelfB1Feelings.
  ///
  /// In de, this message translates to:
  /// **'Gefühle & Beziehung'**
  String get listeningShelfB1Feelings;

  /// No description provided for @listeningShelfB1Family.
  ///
  /// In de, this message translates to:
  /// **'Nähe & Distanz in der Partnerfamilie'**
  String get listeningShelfB1Family;

  /// No description provided for @listeningShelfB1Insurance.
  ///
  /// In de, this message translates to:
  /// **'Behandlung & Versicherung'**
  String get listeningShelfB1Insurance;

  /// No description provided for @listeningShelfB1Incident.
  ///
  /// In de, this message translates to:
  /// **'Unfälle & Anzeigen'**
  String get listeningShelfB1Incident;

  /// No description provided for @listeningShelfB1Cancellation.
  ///
  /// In de, this message translates to:
  /// **'Kündigen & Umziehen'**
  String get listeningShelfB1Cancellation;

  /// No description provided for @listeningShelfB2Meetings.
  ///
  /// In de, this message translates to:
  /// **'Besprechungen leiten'**
  String get listeningShelfB2Meetings;

  /// No description provided for @listeningShelfB2Evidence.
  ///
  /// In de, this message translates to:
  /// **'Belege & Zahlen'**
  String get listeningShelfB2Evidence;

  /// No description provided for @listeningShelfB2Negotiation.
  ///
  /// In de, this message translates to:
  /// **'Verhandeln & Bedingungen'**
  String get listeningShelfB2Negotiation;

  /// No description provided for @listeningShelfB2Contracts.
  ///
  /// In de, this message translates to:
  /// **'Verträge & Unterschrift'**
  String get listeningShelfB2Contracts;

  /// No description provided for @listeningShelfB2Notices.
  ///
  /// In de, this message translates to:
  /// **'Formelle Schreiben & Widerspruch'**
  String get listeningShelfB2Notices;

  /// No description provided for @listeningShelfB2Escalation.
  ///
  /// In de, this message translates to:
  /// **'Eskalation unterwegs'**
  String get listeningShelfB2Escalation;

  /// No description provided for @listeningShelfB2Medical.
  ///
  /// In de, this message translates to:
  /// **'Medizin & Abrechnung'**
  String get listeningShelfB2Medical;

  /// No description provided for @listeningShelfB2Public.
  ///
  /// In de, this message translates to:
  /// **'Öffentlich sprechen & schreiben'**
  String get listeningShelfB2Public;

  /// No description provided for @listeningShelfB2Family.
  ///
  /// In de, this message translates to:
  /// **'Grenzen in der Partnerfamilie'**
  String get listeningShelfB2Family;

  /// No description provided for @listeningShelfB2Hiring.
  ///
  /// In de, this message translates to:
  /// **'Einstellung & Beurteilung'**
  String get listeningShelfB2Hiring;

  /// No description provided for @listeningShelfB2Authorities.
  ///
  /// In de, this message translates to:
  /// **'Behörden & Genehmigungen'**
  String get listeningShelfB2Authorities;

  /// No description provided for @listeningShelfB2Privacy.
  ///
  /// In de, this message translates to:
  /// **'Daten & Einwilligung'**
  String get listeningShelfB2Privacy;

  /// No description provided for @listeningShelfC1Briefing.
  ///
  /// In de, this message translates to:
  /// **'Briefing & Rederecht'**
  String get listeningShelfC1Briefing;

  /// No description provided for @listeningShelfC1Uncertainty.
  ///
  /// In de, this message translates to:
  /// **'Unsicherheit & Stichproben'**
  String get listeningShelfC1Uncertainty;

  /// No description provided for @listeningShelfC1Access.
  ///
  /// In de, this message translates to:
  /// **'Zugriffsrechte & Fristen'**
  String get listeningShelfC1Access;

  /// No description provided for @listeningShelfC1InvisibleLabor.
  ///
  /// In de, this message translates to:
  /// **'Unsichtbare Arbeit in der Familie'**
  String get listeningShelfC1InvisibleLabor;

  /// No description provided for @listeningShelfC1Conflict.
  ///
  /// In de, this message translates to:
  /// **'Interessenkonflikt & Befangenheit'**
  String get listeningShelfC1Conflict;

  /// No description provided for @listeningShelfC1Policy.
  ///
  /// In de, this message translates to:
  /// **'Auslegung & Ermessen'**
  String get listeningShelfC1Policy;

  /// No description provided for @listeningShelfC1Consent.
  ///
  /// In de, this message translates to:
  /// **'Aufklärung & Einwilligung'**
  String get listeningShelfC1Consent;

  /// No description provided for @listeningShelfC1Critique.
  ///
  /// In de, this message translates to:
  /// **'Kultur- & Kunstkritik'**
  String get listeningShelfC1Critique;

  /// No description provided for @listeningShelfC1Mediation.
  ///
  /// In de, this message translates to:
  /// **'Interkulturelle Vermittlung'**
  String get listeningShelfC1Mediation;

  /// No description provided for @listeningShelfC1Methodology.
  ///
  /// In de, this message translates to:
  /// **'Methodik & Reproduzierbarkeit'**
  String get listeningShelfC1Methodology;

  /// No description provided for @listeningShelfC1Facework.
  ///
  /// In de, this message translates to:
  /// **'Widerspruch ohne Gesichtsverlust'**
  String get listeningShelfC1Facework;

  /// No description provided for @listeningShelfC1Attribution.
  ///
  /// In de, this message translates to:
  /// **'Zitieren & Quellenverantwortung'**
  String get listeningShelfC1Attribution;

  /// No description provided for @listeningShelfC2Automation.
  ///
  /// In de, this message translates to:
  /// **'Automatisierte Entscheidungen'**
  String get listeningShelfC2Automation;

  /// No description provided for @listeningShelfC2Records.
  ///
  /// In de, this message translates to:
  /// **'Lücken in der Aktenlage'**
  String get listeningShelfC2Records;

  /// No description provided for @listeningShelfC2Discourse.
  ///
  /// In de, this message translates to:
  /// **'Vorannahmen im Diskurs'**
  String get listeningShelfC2Discourse;

  /// No description provided for @listeningShelfC2Authority.
  ///
  /// In de, this message translates to:
  /// **'Grenzen & Widerruf von Vollmacht'**
  String get listeningShelfC2Authority;

  /// No description provided for @listeningShelfC2Impact.
  ///
  /// In de, this message translates to:
  /// **'Ungleiche Auswirkungen'**
  String get listeningShelfC2Impact;

  /// No description provided for @listeningShelfC2Memory.
  ///
  /// In de, this message translates to:
  /// **'Orte & Namen erinnern'**
  String get listeningShelfC2Memory;

  /// No description provided for @listeningShelfC2Ethics.
  ///
  /// In de, this message translates to:
  /// **'Forschungsethik & Einwilligung'**
  String get listeningShelfC2Ethics;

  /// No description provided for @listeningShelfC2History.
  ///
  /// In de, this message translates to:
  /// **'Geschichtsschreibung & Versöhnung'**
  String get listeningShelfC2History;

  /// No description provided for @listeningShelfC2Translation.
  ///
  /// In de, this message translates to:
  /// **'Ästhetik & Unübersetzbarkeit'**
  String get listeningShelfC2Translation;

  /// No description provided for @listeningShelfC2Limitation.
  ///
  /// In de, this message translates to:
  /// **'Fristen & Verjährung'**
  String get listeningShelfC2Limitation;

  /// No description provided for @listeningShelfC2Jurisdiction.
  ///
  /// In de, this message translates to:
  /// **'Zuständigkeit & Grenzen'**
  String get listeningShelfC2Jurisdiction;

  /// No description provided for @listeningShelfC2Representation.
  ///
  /// In de, this message translates to:
  /// **'Wer spricht für wen'**
  String get listeningShelfC2Representation;

  /// No description provided for @listeningShelfSocialFriends.
  ///
  /// In de, this message translates to:
  /// **'Freunde & Zocken'**
  String get listeningShelfSocialFriends;

  /// No description provided for @listeningShelfSocialDating.
  ///
  /// In de, this message translates to:
  /// **'Dating & Beziehung'**
  String get listeningShelfSocialDating;

  /// No description provided for @listeningShelfSocialFandom.
  ///
  /// In de, this message translates to:
  /// **'Fandom & Videos'**
  String get listeningShelfSocialFandom;

  /// No description provided for @listeningShelfShortA1Transit.
  ///
  /// In de, this message translates to:
  /// **'Bus & Bahn'**
  String get listeningShelfShortA1Transit;

  /// No description provided for @listeningShelfShortA1Arrival.
  ///
  /// In de, this message translates to:
  /// **'Ankunft'**
  String get listeningShelfShortA1Arrival;

  /// No description provided for @listeningShelfShortA1Counter.
  ///
  /// In de, this message translates to:
  /// **'Läden & Schalter'**
  String get listeningShelfShortA1Counter;

  /// No description provided for @listeningShelfShortA1Cafe.
  ///
  /// In de, this message translates to:
  /// **'Café & Imbiss'**
  String get listeningShelfShortA1Cafe;

  /// No description provided for @listeningShelfShortA1Home.
  ///
  /// In de, this message translates to:
  /// **'Zuhause'**
  String get listeningShelfShortA1Home;

  /// No description provided for @listeningShelfShortA1Greeting.
  ///
  /// In de, this message translates to:
  /// **'Begrüßung'**
  String get listeningShelfShortA1Greeting;

  /// No description provided for @listeningShelfShortA1Repair.
  ///
  /// In de, this message translates to:
  /// **'Nachfragen'**
  String get listeningShelfShortA1Repair;

  /// No description provided for @listeningShelfShortA1Health.
  ///
  /// In de, this message translates to:
  /// **'Apotheke'**
  String get listeningShelfShortA1Health;

  /// No description provided for @listeningShelfShortA1Family.
  ///
  /// In de, this message translates to:
  /// **'Erster Besuch'**
  String get listeningShelfShortA1Family;

  /// No description provided for @listeningShelfShortA1Numbers.
  ///
  /// In de, this message translates to:
  /// **'Zahlen & Uhrzeit'**
  String get listeningShelfShortA1Numbers;

  /// No description provided for @listeningShelfShortA1Phone.
  ///
  /// In de, this message translates to:
  /// **'Anrufe'**
  String get listeningShelfShortA1Phone;

  /// No description provided for @listeningShelfShortA1Wayfinding.
  ///
  /// In de, this message translates to:
  /// **'Wege & Schilder'**
  String get listeningShelfShortA1Wayfinding;

  /// No description provided for @listeningShelfShortA2Travel.
  ///
  /// In de, this message translates to:
  /// **'Unterwegs'**
  String get listeningShelfShortA2Travel;

  /// No description provided for @listeningShelfShortA2Bank.
  ///
  /// In de, this message translates to:
  /// **'Bank & Handy'**
  String get listeningShelfShortA2Bank;

  /// No description provided for @listeningShelfShortA2Shopping.
  ///
  /// In de, this message translates to:
  /// **'Einkauf'**
  String get listeningShelfShortA2Shopping;

  /// No description provided for @listeningShelfShortA2Cafe.
  ///
  /// In de, this message translates to:
  /// **'Restaurant'**
  String get listeningShelfShortA2Cafe;

  /// No description provided for @listeningShelfShortA2Body.
  ///
  /// In de, this message translates to:
  /// **'Arzt & Sport'**
  String get listeningShelfShortA2Body;

  /// No description provided for @listeningShelfShortA2Neighbourhood.
  ///
  /// In de, this message translates to:
  /// **'Nachbarschaft'**
  String get listeningShelfShortA2Neighbourhood;

  /// No description provided for @listeningShelfShortA2Work.
  ///
  /// In de, this message translates to:
  /// **'Im Job'**
  String get listeningShelfShortA2Work;

  /// No description provided for @listeningShelfShortA2Plans.
  ///
  /// In de, this message translates to:
  /// **'Verabredungen'**
  String get listeningShelfShortA2Plans;

  /// No description provided for @listeningShelfShortA2Family.
  ///
  /// In de, this message translates to:
  /// **'Feiertage'**
  String get listeningShelfShortA2Family;

  /// No description provided for @listeningShelfShortA2Delivery.
  ///
  /// In de, this message translates to:
  /// **'Lieferung'**
  String get listeningShelfShortA2Delivery;

  /// No description provided for @listeningShelfShortA2Enrolment.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung'**
  String get listeningShelfShortA2Enrolment;

  /// No description provided for @listeningShelfShortA2Booking.
  ///
  /// In de, this message translates to:
  /// **'Buchungen'**
  String get listeningShelfShortA2Booking;

  /// No description provided for @listeningShelfShortB1Repairs.
  ///
  /// In de, this message translates to:
  /// **'Reparaturen'**
  String get listeningShelfShortB1Repairs;

  /// No description provided for @listeningShelfShortB1Refund.
  ///
  /// In de, this message translates to:
  /// **'Garantie'**
  String get listeningShelfShortB1Refund;

  /// No description provided for @listeningShelfShortB1Receipts.
  ///
  /// In de, this message translates to:
  /// **'Belege'**
  String get listeningShelfShortB1Receipts;

  /// No description provided for @listeningShelfShortB1Delay.
  ///
  /// In de, this message translates to:
  /// **'Verspätung'**
  String get listeningShelfShortB1Delay;

  /// No description provided for @listeningShelfShortB1Paperwork.
  ///
  /// In de, this message translates to:
  /// **'Unterlagen'**
  String get listeningShelfShortB1Paperwork;

  /// No description provided for @listeningShelfShortB1Team.
  ///
  /// In de, this message translates to:
  /// **'Übergabe'**
  String get listeningShelfShortB1Team;

  /// No description provided for @listeningShelfShortB1Neighbours.
  ///
  /// In de, this message translates to:
  /// **'Nachbarn'**
  String get listeningShelfShortB1Neighbours;

  /// No description provided for @listeningShelfShortB1Feelings.
  ///
  /// In de, this message translates to:
  /// **'Gefühle'**
  String get listeningShelfShortB1Feelings;

  /// No description provided for @listeningShelfShortB1Family.
  ///
  /// In de, this message translates to:
  /// **'Nähe & Distanz'**
  String get listeningShelfShortB1Family;

  /// No description provided for @listeningShelfShortB1Insurance.
  ///
  /// In de, this message translates to:
  /// **'Versicherung'**
  String get listeningShelfShortB1Insurance;

  /// No description provided for @listeningShelfShortB1Incident.
  ///
  /// In de, this message translates to:
  /// **'Unfälle'**
  String get listeningShelfShortB1Incident;

  /// No description provided for @listeningShelfShortB1Cancellation.
  ///
  /// In de, this message translates to:
  /// **'Kündigung'**
  String get listeningShelfShortB1Cancellation;

  /// No description provided for @listeningShelfShortB2Meetings.
  ///
  /// In de, this message translates to:
  /// **'Besprechungen'**
  String get listeningShelfShortB2Meetings;

  /// No description provided for @listeningShelfShortB2Evidence.
  ///
  /// In de, this message translates to:
  /// **'Zahlen & Belege'**
  String get listeningShelfShortB2Evidence;

  /// No description provided for @listeningShelfShortB2Negotiation.
  ///
  /// In de, this message translates to:
  /// **'Verhandlungen'**
  String get listeningShelfShortB2Negotiation;

  /// No description provided for @listeningShelfShortB2Contracts.
  ///
  /// In de, this message translates to:
  /// **'Verträge'**
  String get listeningShelfShortB2Contracts;

  /// No description provided for @listeningShelfShortB2Notices.
  ///
  /// In de, this message translates to:
  /// **'Widerspruch'**
  String get listeningShelfShortB2Notices;

  /// No description provided for @listeningShelfShortB2Escalation.
  ///
  /// In de, this message translates to:
  /// **'Eskalation'**
  String get listeningShelfShortB2Escalation;

  /// No description provided for @listeningShelfShortB2Medical.
  ///
  /// In de, this message translates to:
  /// **'Medizin'**
  String get listeningShelfShortB2Medical;

  /// No description provided for @listeningShelfShortB2Public.
  ///
  /// In de, this message translates to:
  /// **'Öffentlichkeit'**
  String get listeningShelfShortB2Public;

  /// No description provided for @listeningShelfShortB2Family.
  ///
  /// In de, this message translates to:
  /// **'Grenzen'**
  String get listeningShelfShortB2Family;

  /// No description provided for @listeningShelfShortB2Hiring.
  ///
  /// In de, this message translates to:
  /// **'Einstellung'**
  String get listeningShelfShortB2Hiring;

  /// No description provided for @listeningShelfShortB2Authorities.
  ///
  /// In de, this message translates to:
  /// **'Behörden'**
  String get listeningShelfShortB2Authorities;

  /// No description provided for @listeningShelfShortB2Privacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get listeningShelfShortB2Privacy;

  /// No description provided for @listeningShelfShortC1Briefing.
  ///
  /// In de, this message translates to:
  /// **'Rederecht'**
  String get listeningShelfShortC1Briefing;

  /// No description provided for @listeningShelfShortC1Uncertainty.
  ///
  /// In de, this message translates to:
  /// **'Unsicherheit'**
  String get listeningShelfShortC1Uncertainty;

  /// No description provided for @listeningShelfShortC1Access.
  ///
  /// In de, this message translates to:
  /// **'Zugriffsrechte'**
  String get listeningShelfShortC1Access;

  /// No description provided for @listeningShelfShortC1InvisibleLabor.
  ///
  /// In de, this message translates to:
  /// **'Unsichtbare Arbeit'**
  String get listeningShelfShortC1InvisibleLabor;

  /// No description provided for @listeningShelfShortC1Conflict.
  ///
  /// In de, this message translates to:
  /// **'Befangenheit'**
  String get listeningShelfShortC1Conflict;

  /// No description provided for @listeningShelfShortC1Policy.
  ///
  /// In de, this message translates to:
  /// **'Auslegung'**
  String get listeningShelfShortC1Policy;

  /// No description provided for @listeningShelfShortC1Consent.
  ///
  /// In de, this message translates to:
  /// **'Einwilligung'**
  String get listeningShelfShortC1Consent;

  /// No description provided for @listeningShelfShortC1Critique.
  ///
  /// In de, this message translates to:
  /// **'Kunstkritik'**
  String get listeningShelfShortC1Critique;

  /// No description provided for @listeningShelfShortC1Mediation.
  ///
  /// In de, this message translates to:
  /// **'Vermittlung'**
  String get listeningShelfShortC1Mediation;

  /// No description provided for @listeningShelfShortC1Methodology.
  ///
  /// In de, this message translates to:
  /// **'Methodik'**
  String get listeningShelfShortC1Methodology;

  /// No description provided for @listeningShelfShortC1Facework.
  ///
  /// In de, this message translates to:
  /// **'Gesicht wahren'**
  String get listeningShelfShortC1Facework;

  /// No description provided for @listeningShelfShortC1Attribution.
  ///
  /// In de, this message translates to:
  /// **'Zitate & Quellen'**
  String get listeningShelfShortC1Attribution;

  /// No description provided for @listeningShelfShortC2Automation.
  ///
  /// In de, this message translates to:
  /// **'Automatisierung'**
  String get listeningShelfShortC2Automation;

  /// No description provided for @listeningShelfShortC2Records.
  ///
  /// In de, this message translates to:
  /// **'Aktenlücken'**
  String get listeningShelfShortC2Records;

  /// No description provided for @listeningShelfShortC2Discourse.
  ///
  /// In de, this message translates to:
  /// **'Vorannahmen'**
  String get listeningShelfShortC2Discourse;

  /// No description provided for @listeningShelfShortC2Authority.
  ///
  /// In de, this message translates to:
  /// **'Vollmacht'**
  String get listeningShelfShortC2Authority;

  /// No description provided for @listeningShelfShortC2Impact.
  ///
  /// In de, this message translates to:
  /// **'Auswirkungen'**
  String get listeningShelfShortC2Impact;

  /// No description provided for @listeningShelfShortC2Memory.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung'**
  String get listeningShelfShortC2Memory;

  /// No description provided for @listeningShelfShortC2Ethics.
  ///
  /// In de, this message translates to:
  /// **'Forschungsethik'**
  String get listeningShelfShortC2Ethics;

  /// No description provided for @listeningShelfShortC2History.
  ///
  /// In de, this message translates to:
  /// **'Versöhnung'**
  String get listeningShelfShortC2History;

  /// No description provided for @listeningShelfShortC2Translation.
  ///
  /// In de, this message translates to:
  /// **'Ästhetik'**
  String get listeningShelfShortC2Translation;

  /// No description provided for @listeningShelfShortC2Limitation.
  ///
  /// In de, this message translates to:
  /// **'Verjährung'**
  String get listeningShelfShortC2Limitation;

  /// No description provided for @listeningShelfShortC2Jurisdiction.
  ///
  /// In de, this message translates to:
  /// **'Zuständigkeit'**
  String get listeningShelfShortC2Jurisdiction;

  /// No description provided for @listeningShelfShortC2Representation.
  ///
  /// In de, this message translates to:
  /// **'Repräsentation'**
  String get listeningShelfShortC2Representation;

  /// No description provided for @listeningShelfShortSocialFriends.
  ///
  /// In de, this message translates to:
  /// **'Freunde'**
  String get listeningShelfShortSocialFriends;

  /// No description provided for @listeningShelfShortSocialDating.
  ///
  /// In de, this message translates to:
  /// **'Dating'**
  String get listeningShelfShortSocialDating;

  /// No description provided for @listeningShelfShortSocialFandom.
  ///
  /// In de, this message translates to:
  /// **'Fandom'**
  String get listeningShelfShortSocialFandom;

  /// No description provided for @kkeunmariTitle.
  ///
  /// In de, this message translates to:
  /// **'Wortkette'**
  String get kkeunmariTitle;

  /// No description provided for @kkeunmariEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Spiel sind gerade keine Wörter vorbereitet.'**
  String get kkeunmariEmptyBody;

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

  /// No description provided for @redeemLoading.
  ///
  /// In de, this message translates to:
  /// **'Paket wird importiert …'**
  String get redeemLoading;

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
  /// **'Rekord: {count} Versuche'**
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

  /// No description provided for @clozeLevelLabel.
  ///
  /// In de, this message translates to:
  /// **'Lernstufe'**
  String get clozeLevelLabel;

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

  /// No description provided for @speedMatchEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für diese Lernstufe gibt es noch nicht genug Wortpaare.'**
  String get speedMatchEmptyBody;

  /// No description provided for @speedMatchAllLevels.
  ///
  /// In de, this message translates to:
  /// **'Alle Lernstufen verwenden'**
  String get speedMatchAllLevels;

  /// No description provided for @speedMatchScore.
  ///
  /// In de, this message translates to:
  /// **'{count} Paare'**
  String speedMatchScore(int count);

  /// No description provided for @speedMatchBest.
  ///
  /// In de, this message translates to:
  /// **'Rekord: {count} Paare'**
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

  /// No description provided for @hardWordsHardQuizCta.
  ///
  /// In de, this message translates to:
  /// **'Schweres Quiz: Schreibweise'**
  String get hardWordsHardQuizCta;

  /// No description provided for @hardQuizTitle.
  ///
  /// In de, this message translates to:
  /// **'Schweres Quiz'**
  String get hardQuizTitle;

  /// No description provided for @hardQuizHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle die richtige Schreibweise.'**
  String get hardQuizHint;

  /// No description provided for @hardQuizCorrectFeedback.
  ///
  /// In de, this message translates to:
  /// **'Richtig: {word}'**
  String hardQuizCorrectFeedback(String word);

  /// No description provided for @hardQuizWrongFeedback.
  ///
  /// In de, this message translates to:
  /// **'Richtig geschrieben: {word}'**
  String hardQuizWrongFeedback(String word);

  /// No description provided for @hardQuizFinish.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis ansehen'**
  String get hardQuizFinish;

  /// No description provided for @hardQuizDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Runde geschafft!'**
  String get hardQuizDoneTitle;

  /// No description provided for @hardQuizScore.
  ///
  /// In de, this message translates to:
  /// **'{correct}/{total} richtig'**
  String hardQuizScore(int correct, int total);

  /// No description provided for @wordWebTitle.
  ///
  /// In de, this message translates to:
  /// **'Nuancen & Gegenteile'**
  String get wordWebTitle;

  /// No description provided for @wordWebHubDesc.
  ///
  /// In de, this message translates to:
  /// **'Synonyme, Gegenteile und Wendungen zu deinen Wörtern'**
  String get wordWebHubDesc;

  /// No description provided for @wordWebSubtitle.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort mit Nachbarn} other{{count} Wörter mit Nachbarn}}'**
  String wordWebSubtitle(int count);

  /// No description provided for @wordWebEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Netz'**
  String get wordWebEmptyTitle;

  /// No description provided for @wordWebEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Lerne Wörter in einem Paket, im Kurs oder in einem Spiel. Dann erscheinen hier Nachbarn, Gegenteile und Wendungen zu genau diesen Wörtern.'**
  String get wordWebEmptyBody;

  /// No description provided for @wordWebLoadErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Netz nicht geladen'**
  String get wordWebLoadErrorTitle;

  /// No description provided for @wordWebLoadErrorBody.
  ///
  /// In de, this message translates to:
  /// **'Die Nuancen-Datei konnte nicht gelesen werden. Das ist kein leerer Lernstand. Versuch es noch einmal.'**
  String get wordWebLoadErrorBody;

  /// No description provided for @wordWebBrowseLevelCta.
  ///
  /// In de, this message translates to:
  /// **'Wörter auf meinem Niveau ansehen'**
  String get wordWebBrowseLevelCta;

  /// No description provided for @wordWebOpenVocabCta.
  ///
  /// In de, this message translates to:
  /// **'Wortpakete öffnen'**
  String get wordWebOpenVocabCta;

  /// No description provided for @wordWebQuizCta.
  ///
  /// In de, this message translates to:
  /// **'Diese Wörter üben'**
  String get wordWebQuizCta;

  /// No description provided for @wordWebLearnedFilter.
  ///
  /// In de, this message translates to:
  /// **'Gelernt'**
  String get wordWebLearnedFilter;

  /// No description provided for @wordWebLevelFilter.
  ///
  /// In de, this message translates to:
  /// **'Mein Niveau'**
  String get wordWebLevelFilter;

  /// No description provided for @wordWebSynonymSection.
  ///
  /// In de, this message translates to:
  /// **'Ähnliche Wörter'**
  String get wordWebSynonymSection;

  /// No description provided for @wordWebAntonymSection.
  ///
  /// In de, this message translates to:
  /// **'Gegenteile'**
  String get wordWebAntonymSection;

  /// No description provided for @wordWebRelatedSection.
  ///
  /// In de, this message translates to:
  /// **'Verwandte Wörter'**
  String get wordWebRelatedSection;

  /// No description provided for @wordWebExpressionSection.
  ///
  /// In de, this message translates to:
  /// **'Wendungen'**
  String get wordWebExpressionSection;

  /// No description provided for @wordWebQuizTitle.
  ///
  /// In de, this message translates to:
  /// **'Nuancen-Übung'**
  String get wordWebQuizTitle;

  /// No description provided for @wordWebQuizHintSynonym.
  ///
  /// In de, this message translates to:
  /// **'Welches Wort liegt nah dabei?'**
  String get wordWebQuizHintSynonym;

  /// No description provided for @wordWebQuizHintAntonym.
  ///
  /// In de, this message translates to:
  /// **'Was ist das Gegenteil?'**
  String get wordWebQuizHintAntonym;

  /// No description provided for @wordWebQuizHintRelated.
  ///
  /// In de, this message translates to:
  /// **'Was gehört dazu?'**
  String get wordWebQuizHintRelated;

  /// No description provided for @wordWebQuizHintExpression.
  ///
  /// In de, this message translates to:
  /// **'Welche Wendung passt zur Bedeutung?'**
  String get wordWebQuizHintExpression;

  /// No description provided for @wordWebQuizCorrectFeedback.
  ///
  /// In de, this message translates to:
  /// **'Richtig: {word}'**
  String wordWebQuizCorrectFeedback(String word);

  /// No description provided for @wordWebQuizWrongFeedback.
  ///
  /// In de, this message translates to:
  /// **'Dazu passt: {word}'**
  String wordWebQuizWrongFeedback(String word);

  /// No description provided for @wordWebQuizFinish.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis ansehen'**
  String get wordWebQuizFinish;

  /// No description provided for @wordWebQuizDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Runde geschafft!'**
  String get wordWebQuizDoneTitle;

  /// No description provided for @wordWebQuizEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Runde'**
  String get wordWebQuizEmptyTitle;

  /// No description provided for @wordWebQuizEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für diese Wörter reichen die Vergleichswörter noch nicht. Schau dir zuerst die Karten an oder lerne ein paar Wörter dazu.'**
  String get wordWebQuizEmptyBody;

  /// No description provided for @wordWebQuizScore.
  ///
  /// In de, this message translates to:
  /// **'{correct}/{total} richtig'**
  String wordWebQuizScore(int correct, int total);

  /// No description provided for @wordWebClusterCount.
  ///
  /// In de, this message translates to:
  /// **'{synonyms} ähnlich · {antonyms} Gegenteil · {related} verwandt · {expressions} Wendung'**
  String wordWebClusterCount(
    int synonyms,
    int antonyms,
    int related,
    int expressions,
  );

  /// No description provided for @wordWebExampleLabel.
  ///
  /// In de, this message translates to:
  /// **'Im Satz'**
  String get wordWebExampleLabel;

  /// No description provided for @wordWebCoachTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Nuancen & Gegenteile'**
  String get wordWebCoachTitle;

  /// No description provided for @wordWebCoachBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe ein Wort aus deinem Lernstand. Das Netz zeigt Nachbarn, Gegenteile und eine Wendung, unabhängig von Hanja und Nuance im Vokabelheft.'**
  String get wordWebCoachBody;

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

  /// No description provided for @wbSearchClear.
  ///
  /// In de, this message translates to:
  /// **'Suche löschen'**
  String get wbSearchClear;

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
  /// **'{count} in Folge'**
  String comboPop(int count);

  /// No description provided for @pathTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg'**
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

  /// No description provided for @pathStoryEyebrow.
  ///
  /// In de, this message translates to:
  /// **'{level} · Alltag in Korea'**
  String pathStoryEyebrow(Object level);

  /// No description provided for @pathStoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Du baust vom Begrüßen zum Leben.'**
  String get pathStoryTitle;

  /// No description provided for @pathStoryBody.
  ///
  /// In de, this message translates to:
  /// **'Jeder Abschnitt endet mit einer Situation, die du selbst lösen kannst.'**
  String get pathStoryBody;

  /// No description provided for @pathOpenCurrentMission.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Mission öffnen'**
  String get pathOpenCurrentMission;

  /// No description provided for @pathCourseMissionsTitle.
  ///
  /// In de, this message translates to:
  /// **'Kursmissionen'**
  String get pathCourseMissionsTitle;

  /// No description provided for @pathCourseMissionsBody.
  ///
  /// In de, this message translates to:
  /// **'Ein klarer nächster Schritt verbindet Wortschatz, Grammatik, Spiele und Szenarien.'**
  String get pathCourseMissionsBody;

  /// No description provided for @pathStatusCurrent.
  ///
  /// In de, this message translates to:
  /// **'weiter'**
  String get pathStatusCurrent;

  /// No description provided for @pathStatusCompleted.
  ///
  /// In de, this message translates to:
  /// **'fertig'**
  String get pathStatusCompleted;

  /// No description provided for @pathStatusBypassed.
  ///
  /// In de, this message translates to:
  /// **'Startstufe übersprungen'**
  String get pathStatusBypassed;

  /// No description provided for @pathStatusNext.
  ///
  /// In de, this message translates to:
  /// **'später'**
  String get pathStatusNext;

  /// No description provided for @pathCompletedCanDo.
  ///
  /// In de, this message translates to:
  /// **'Kann ich: {canDo}'**
  String pathCompletedCanDo(Object canDo);

  /// No description provided for @pathCurrentCanDo.
  ///
  /// In de, this message translates to:
  /// **'Jetzt: {canDo}'**
  String pathCurrentCanDo(Object canDo);

  /// No description provided for @pathNextAfterEvidence.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes nach deinem Beweis'**
  String get pathNextAfterEvidence;

  /// No description provided for @pathShowMorePractice.
  ///
  /// In de, this message translates to:
  /// **'Weitere Übungen anzeigen'**
  String get pathShowMorePractice;

  /// No description provided for @pathHideMorePractice.
  ///
  /// In de, this message translates to:
  /// **'Weitere Übungen ausblenden'**
  String get pathHideMorePractice;

  /// No description provided for @gyeVoluntaryEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Freiwillige Lerngemeinschaft'**
  String get gyeVoluntaryEyebrow;

  /// No description provided for @gyeEmptyHeadline.
  ///
  /// In de, this message translates to:
  /// **'Allein lernen ist vollständig. Zusammen kann es wärmer sein.'**
  String get gyeEmptyHeadline;

  /// No description provided for @gyeEmptyLead.
  ///
  /// In de, this message translates to:
  /// **'Eine 계 ist eine kleine Gruppe, die eine Wochenabsicht miteinander hält.'**
  String get gyeEmptyLead;

  /// No description provided for @gyeFindOrCreate.
  ///
  /// In de, this message translates to:
  /// **'Eine 계 finden oder gründen'**
  String get gyeFindOrCreate;

  /// No description provided for @gyeContinueSolo.
  ///
  /// In de, this message translates to:
  /// **'Ohne Gruppe weiterlernen'**
  String get gyeContinueSolo;

  /// No description provided for @gyeEmptyPreviewCaption.
  ///
  /// In de, this message translates to:
  /// **'Die Vorschau zeigt den gemeinsamen Hof. Er ist keine Voraussetzung für deinen Lernweg.'**
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

  /// No description provided for @ttsListenTarget.
  ///
  /// In de, this message translates to:
  /// **'Aussprache: {target}'**
  String ttsListenTarget(Object target);

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

  /// No description provided for @profileJourneyTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg, {name}'**
  String profileJourneyTitle(Object name);

  /// No description provided for @profileJourneySummary.
  ///
  /// In de, this message translates to:
  /// **'{level} · {goal}'**
  String profileJourneySummary(Object level, Object goal);

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

  /// No description provided for @profileEditAction.
  ///
  /// In de, this message translates to:
  /// **'bearbeiten'**
  String get profileEditAction;

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

  /// No description provided for @profileLearningStartPointConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt ändern?'**
  String get profileLearningStartPointConfirmTitle;

  /// No description provided for @profileLearningStartPointConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Dabei werden dein bisheriger Kursfortschritt, abgeschlossene Einheiten, Übungsnachweise und Szenen-Checks zurückgesetzt. Gespeicherte Vokabeln und Kontodaten bleiben erhalten.'**
  String get profileLearningStartPointConfirmBody;

  /// No description provided for @profileLearningStartPointConfirmCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get profileLearningStartPointConfirmCancel;

  /// No description provided for @profileLearningStartPointConfirmAction.
  ///
  /// In de, this message translates to:
  /// **'Ändern und Kursfortschritt zurücksetzen'**
  String get profileLearningStartPointConfirmAction;

  /// No description provided for @profileLearningStartPointChangeFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Startpunkt konnte nicht geändert werden. Versuche es erneut.'**
  String get profileLearningStartPointChangeFailed;

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

  /// No description provided for @profileGye.
  ///
  /// In de, this message translates to:
  /// **'Gruppe (계)'**
  String get profileGye;

  /// No description provided for @profileGyeDescription.
  ///
  /// In de, this message translates to:
  /// **'Freiwillige Lerngemeinschaft öffnen'**
  String get profileGyeDescription;

  /// No description provided for @profileGyeLoading.
  ///
  /// In de, this message translates to:
  /// **'Gruppe wird geladen …'**
  String get profileGyeLoading;

  /// No description provided for @profileGyeNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Gruppe gewählt'**
  String get profileGyeNone;

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

  /// No description provided for @profileLearningData.
  ///
  /// In de, this message translates to:
  /// **'Meine Lerndaten'**
  String get profileLearningData;

  /// No description provided for @profileLearningDataDescription.
  ///
  /// In de, this message translates to:
  /// **'Lokalen Lernfortschritt als JSON exportieren'**
  String get profileLearningDataDescription;

  /// No description provided for @profileLearningDataPreparing.
  ///
  /// In de, this message translates to:
  /// **'Export wird vorbereitet …'**
  String get profileLearningDataPreparing;

  /// No description provided for @profileLearningDataExportReady.
  ///
  /// In de, this message translates to:
  /// **'Deine Lerndaten sind zum Teilen bereit.'**
  String get profileLearningDataExportReady;

  /// No description provided for @profileLearningDataExportFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Export konnte nicht vorbereitet werden.'**
  String get profileLearningDataExportFailed;

  /// No description provided for @profileAccountDelete.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get profileAccountDelete;

  /// No description provided for @profileAccountDeleteDescription.
  ///
  /// In de, this message translates to:
  /// **'Den geschützten Löschablauf öffnen'**
  String get profileAccountDeleteDescription;

  /// No description provided for @profileSafeSituations.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{noch keine sichere Situation} =1{1 sichere Situation} other{{count} sichere Situationen}}'**
  String profileSafeSituations(int count);

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

  /// No description provided for @consentEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Bevor du beginnst'**
  String get consentEyebrow;

  /// No description provided for @consentCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz & Lernkonto'**
  String get consentCardTitle;

  /// No description provided for @consentCardBody.
  ///
  /// In de, this message translates to:
  /// **'Klar erklärt · jederzeit in deinem Profil anpassbar. Gruppen bleiben immer freiwillig.'**
  String get consentCardBody;

  /// No description provided for @consentDataOptIn.
  ///
  /// In de, this message translates to:
  /// **'Optional: Teile anonyme Nutzungsstatistiken und Absturzberichte, damit wir Hangul Sori verbessern können. Standardmäßig aus. Du kannst das hier oder jederzeit in den Einstellungen ändern.'**
  String get consentDataOptIn;

  /// No description provided for @consentContinueCta.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get consentContinueCta;

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

  /// No description provided for @consentInviteTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeig mir, wo\'s hakt'**
  String get consentInviteTitle;

  /// No description provided for @consentInviteBody.
  ///
  /// In de, this message translates to:
  /// **'Ich sehe nie, was du lernst. Anonyme Zahlen zeigen mir nur, wo viele Lernende an derselben Stelle hängen bleiben, und genau dort bessere ich nach. Dein Name, deine E-Mail und deine Lerninhalte bleiben auf deinem Handy.'**
  String get consentInviteBody;

  /// No description provided for @consentInviteYes.
  ///
  /// In de, this message translates to:
  /// **'Alles erlauben'**
  String get consentInviteYes;

  /// No description provided for @consentInviteNo.
  ///
  /// In de, this message translates to:
  /// **'Nur das Nötigste'**
  String get consentInviteNo;

  /// No description provided for @consentInviteCustomize.
  ///
  /// In de, this message translates to:
  /// **'Einzeln festlegen'**
  String get consentInviteCustomize;

  /// No description provided for @consentInviteSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get consentInviteSave;

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

  /// No description provided for @grammarPreviousCard.
  ///
  /// In de, this message translates to:
  /// **'Vorherige Karte'**
  String get grammarPreviousCard;

  /// No description provided for @grammarChoiceCta.
  ///
  /// In de, this message translates to:
  /// **'Mit Beispielen üben'**
  String get grammarChoiceCta;

  /// No description provided for @grammarPlanOnboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie viele Muster pro Tag?'**
  String get grammarPlanOnboardingTitle;

  /// No description provided for @grammarPlanItemsPerDayOption.
  ///
  /// In de, this message translates to:
  /// **'{n} pro Tag'**
  String grammarPlanItemsPerDayOption(int n);

  /// No description provided for @grammarPlanStartCta.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get grammarPlanStartCta;

  /// No description provided for @grammarPlanDayHeader.
  ///
  /// In de, this message translates to:
  /// **'Tag {day} von {total}'**
  String grammarPlanDayHeader(int day, int total);

  /// No description provided for @grammarPlanCompletionTitle.
  ///
  /// In de, this message translates to:
  /// **'Tag geschafft!'**
  String get grammarPlanCompletionTitle;

  /// No description provided for @grammarPlanCompletionBody.
  ///
  /// In de, this message translates to:
  /// **'Mit Beispielen üben?'**
  String get grammarPlanCompletionBody;

  /// No description provided for @grammarPlanCompletionCta.
  ///
  /// In de, this message translates to:
  /// **'Üben'**
  String get grammarPlanCompletionCta;

  /// No description provided for @grammarPlanCompletionSkip.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get grammarPlanCompletionSkip;

  /// No description provided for @grammarPlanFinishedTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Muster dieser Stufe geschafft!'**
  String get grammarPlanFinishedTitle;

  /// No description provided for @grammarPlanFinishedRestartCta.
  ///
  /// In de, this message translates to:
  /// **'Neu starten'**
  String get grammarPlanFinishedRestartCta;

  /// No description provided for @grammarChoiceTitle.
  ///
  /// In de, this message translates to:
  /// **'Grammatik üben'**
  String get grammarChoiceTitle;

  /// No description provided for @grammarChoiceEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Satz erkennen'**
  String get grammarChoiceEyebrow;

  /// No description provided for @grammarChoiceInstruction.
  ///
  /// In de, this message translates to:
  /// **'Welche koreanische Grammatik passt zum hervorgehobenen Teil?'**
  String get grammarChoiceInstruction;

  /// No description provided for @grammarChoicePromptSemantics.
  ///
  /// In de, this message translates to:
  /// **'Satz: {sentence}. Hervorgehobener Teil: {focus}.'**
  String grammarChoicePromptSemantics(String sentence, String focus);

  /// No description provided for @grammarChoiceCorrect.
  ///
  /// In de, this message translates to:
  /// **'Richtig.'**
  String get grammarChoiceCorrect;

  /// No description provided for @grammarChoiceIncorrect.
  ///
  /// In de, this message translates to:
  /// **'Passend ist: {pattern}'**
  String grammarChoiceIncorrect(String pattern);

  /// No description provided for @grammarChoiceKoreanExampleLabel.
  ///
  /// In de, this message translates to:
  /// **'Beispiel auf Koreanisch'**
  String get grammarChoiceKoreanExampleLabel;

  /// No description provided for @grammarChoiceExplanationLabel.
  ///
  /// In de, this message translates to:
  /// **'Warum das passt'**
  String get grammarChoiceExplanationLabel;

  /// No description provided for @grammarChoiceFinish.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis ansehen'**
  String get grammarChoiceFinish;

  /// No description provided for @grammarChoiceDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Runde beendet'**
  String get grammarChoiceDoneTitle;

  /// No description provided for @grammarChoiceScore.
  ///
  /// In de, this message translates to:
  /// **'{correct} von {total} richtig'**
  String grammarChoiceScore(int correct, int total);

  /// No description provided for @grammarChoicePracticeOnly.
  ///
  /// In de, this message translates to:
  /// **'Diese Übung verändert deinen Kursfortschritt nicht.'**
  String get grammarChoicePracticeOnly;

  /// No description provided for @grammarChoiceAgain.
  ///
  /// In de, this message translates to:
  /// **'Neue Runde'**
  String get grammarChoiceAgain;

  /// No description provided for @grammarChoiceBack.
  ///
  /// In de, this message translates to:
  /// **'Zur Grammatik'**
  String get grammarChoiceBack;

  /// No description provided for @grammarChoiceUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Übung verfügbar'**
  String get grammarChoiceUnavailableTitle;

  /// No description provided for @grammarChoiceUnavailableBody.
  ///
  /// In de, this message translates to:
  /// **'Für diese Stufe gibt es noch nicht genügend geprüfte Beispiele.'**
  String get grammarChoiceUnavailableBody;

  /// No description provided for @grammarChoiceSaveError.
  ///
  /// In de, this message translates to:
  /// **'Diese Schwierigkeitsmarkierung konnte nicht gespeichert werden. Du kannst trotzdem weitermachen.'**
  String get grammarChoiceSaveError;

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
  /// **'Scannen, nachschlagen, hören oder eine kleine Pause machen.'**
  String get discoverSubtitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Suchen: z. B. Aussprache, Buch, OCR …'**
  String get discoverSearchHint;

  /// No description provided for @discoverStartHere.
  ///
  /// In de, this message translates to:
  /// **'Direkt zu deinem Ziel'**
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
  /// **'Wörter'**
  String get discoverCategoryWords;

  /// No description provided for @discoverCategoryProgress.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg'**
  String get discoverCategoryProgress;

  /// No description provided for @discoverCategoryForMe.
  ///
  /// In de, this message translates to:
  /// **'Für mich'**
  String get discoverCategoryForMe;

  /// No description provided for @discoverCategoryLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get discoverCategoryLanguage;

  /// No description provided for @discoverCategoryLeisure.
  ///
  /// In de, this message translates to:
  /// **'Freizeit'**
  String get discoverCategoryLeisure;

  /// No description provided for @discoverPriorityBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Buch scannen'**
  String get discoverPriorityBookTitle;

  /// No description provided for @discoverPriorityBookBody.
  ///
  /// In de, this message translates to:
  /// **'Text aus deinem Lehrbuch verstehen'**
  String get discoverPriorityBookBody;

  /// No description provided for @discoverPriorityPronunciationTitle.
  ///
  /// In de, this message translates to:
  /// **'Aussprache hören'**
  String get discoverPriorityPronunciationTitle;

  /// No description provided for @discoverPriorityPronunciationBody.
  ///
  /// In de, this message translates to:
  /// **'Laute langsam vergleichen'**
  String get discoverPriorityPronunciationBody;

  /// No description provided for @discoverPriorityWordsTitle.
  ///
  /// In de, this message translates to:
  /// **'Wörterbuch & Meine Wörter'**
  String get discoverPriorityWordsTitle;

  /// No description provided for @discoverPriorityWordsBody.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter wiederfinden'**
  String get discoverPriorityWordsBody;

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
  /// **'Zusammen lernen · 계'**
  String get gyeTabSubtitle;

  /// No description provided for @gyeExplainWhat.
  ///
  /// In de, this message translates to:
  /// **'Eine 계 (Gye) ist eine kleine Lerngruppe, ganz freiwillig. Allein zu lernen ist genauso gut.'**
  String get gyeExplainWhat;

  /// No description provided for @gyeExplainWhy.
  ///
  /// In de, this message translates to:
  /// **'Ein gemeinsames Hanok zeigt, wie ihr euch gegenseitig anspornt. Einen Wettbewerb gibt es hier nicht, und für deinen Fortschritt brauchst du die Gruppe nicht.'**
  String get gyeExplainWhy;

  /// No description provided for @gyeExplainHow.
  ///
  /// In de, this message translates to:
  /// **'Gründe eine Gruppe oder tritt mit einem 6-stelligen Code bei, wenn du bereit bist.'**
  String get gyeExplainHow;

  /// No description provided for @gyePrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Was andere sehen'**
  String get gyePrivacyTitle;

  /// No description provided for @gyePrivacyBody.
  ///
  /// In de, this message translates to:
  /// **'Es wird nur angezeigt, dass du beigetragen hast. Antworten, Wörter und Prüfungsergebnisse bleiben privat.'**
  String get gyePrivacyBody;

  /// No description provided for @gyeExplainWhatShort.
  ///
  /// In de, this message translates to:
  /// **'Eine kleine, freiwillige Lerngruppe.'**
  String get gyeExplainWhatShort;

  /// No description provided for @gyeExplainWhyShort.
  ///
  /// In de, this message translates to:
  /// **'Ein gemeinsames Hanok, kein Wettbewerb.'**
  String get gyeExplainWhyShort;

  /// No description provided for @gyeExplainHowShort.
  ///
  /// In de, this message translates to:
  /// **'Beitritt mit 6-stelligem Code.'**
  String get gyeExplainHowShort;

  /// No description provided for @gyeShowcaseCaption.
  ///
  /// In de, this message translates to:
  /// **'So kann euer gemeinsames Hanok aussehen'**
  String get gyeShowcaseCaption;

  /// No description provided for @gyeExplainMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr erfahren'**
  String get gyeExplainMore;

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
  /// **'Diese Woche gemeinsam'**
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
  /// **'Jede Person hilft mit einer abgeschlossenen, passenden Lernhandlung.'**
  String get gyePromiseBody;

  /// No description provided for @gyePromiseEligibility.
  ///
  /// In de, this message translates to:
  /// **'Als Beitrag zählt nur die passende kursgebundene Szene mit mindestens 70 %.'**
  String get gyePromiseEligibility;

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

  /// No description provided for @gyePromiseContributionCompleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Anonymer Beitrag'**
  String get gyePromiseContributionCompleteTitle;

  /// No description provided for @gyePromiseContributionCompleteBody.
  ///
  /// In de, this message translates to:
  /// **'Eine passende Szene wurde abgeschlossen. Identität und Ergebnis bleiben privat.'**
  String get gyePromiseContributionCompleteBody;

  /// No description provided for @gyePromiseContributionPendingTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch ein Licht wartet'**
  String get gyePromiseContributionPendingTitle;

  /// No description provided for @gyePromiseContributionPendingBody.
  ///
  /// In de, this message translates to:
  /// **'Dein nächster Beitrag kann aus Heute kommen.'**
  String get gyePromiseContributionPendingBody;

  /// No description provided for @gyePromisePrivacyRule.
  ///
  /// In de, this message translates to:
  /// **'Keine Rangliste. Kein Druck. Niemand kann den Lernweg anderer blockieren.'**
  String get gyePromisePrivacyRule;

  /// No description provided for @gyePromiseSceneCta.
  ///
  /// In de, this message translates to:
  /// **'Meine heutige Szene öffnen'**
  String get gyePromiseSceneCta;

  /// No description provided for @gyeTodayFallbackCta.
  ///
  /// In de, this message translates to:
  /// **'Zu Heute'**
  String get gyeTodayFallbackCta;

  /// No description provided for @gyeTodayUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Heute ist gerade nicht verfügbar. Versuch es gleich noch einmal.'**
  String get gyeTodayUnavailable;

  /// No description provided for @gyePromiseIntentionAction.
  ///
  /// In de, this message translates to:
  /// **'Wochenabsicht ansehen'**
  String get gyePromiseIntentionAction;

  /// No description provided for @gyeRulesAndMembers.
  ///
  /// In de, this message translates to:
  /// **'Regeln & Mitglieder'**
  String get gyeRulesAndMembers;

  /// No description provided for @gyeRulesTitle.
  ///
  /// In de, this message translates to:
  /// **'Regeln für einen sicheren Hof'**
  String get gyeRulesTitle;

  /// No description provided for @gyeRulesBody.
  ///
  /// In de, this message translates to:
  /// **'Ermutige ohne Vergleiche. Antworten, Ergebnisse und einzelne Beiträge bleiben privat. Melden und Blockieren sind jederzeit möglich.'**
  String get gyeRulesBody;

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

  /// No description provided for @gyeCourtyardLightsToday.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Heute wartet die erste Laterne.} one{Heute leuchtet eine Laterne.} other{Heute leuchten {count} Laternen.}}'**
  String gyeCourtyardLightsToday(int count);

  /// No description provided for @gyeCourtyardLightsThree.
  ///
  /// In de, this message translates to:
  /// **'Heute leuchten drei Laternen.'**
  String get gyeCourtyardLightsThree;

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
  /// **'Eine sichere Nachricht senden'**
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
  /// **'Ohne Tagesmission'**
  String get practiceEyebrow;

  /// No description provided for @practiceTitle.
  ///
  /// In de, this message translates to:
  /// **'Was willst du gerade festigen?'**
  String get practiceTitle;

  /// No description provided for @practiceSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Absicht, nicht erst ein Spiel.'**
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

  /// No description provided for @practiceDueContext.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Wörter warten auf Kontext} =1{1 Wort wartet auf Kontext} other{{count} Wörter warten auf Kontext}}'**
  String practiceDueContext(int count);

  /// No description provided for @practiceWordsPurposeTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Wörter öffnen'**
  String get practiceWordsPurposeTitle;

  /// No description provided for @practiceSecLearn.
  ///
  /// In de, this message translates to:
  /// **'Etwas gezielt üben'**
  String get practiceSecLearn;

  /// No description provided for @practiceSecGames.
  ///
  /// In de, this message translates to:
  /// **'Spielen'**
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

  /// No description provided for @practiceFocusedDescription.
  ///
  /// In de, this message translates to:
  /// **'Aussprache, Grammatik oder Schreiben'**
  String get practiceFocusedDescription;

  /// No description provided for @practiceFreeDescription.
  ///
  /// In de, this message translates to:
  /// **'Wortkette, Buchstaben, kurze Spiele'**
  String get practiceFreeDescription;

  /// No description provided for @practiceWordsDescription.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter und Bücher'**
  String get practiceWordsDescription;

  /// No description provided for @practiceAllActivities.
  ///
  /// In de, this message translates to:
  /// **'Alle Aktivitäten anzeigen'**
  String get practiceAllActivities;

  /// No description provided for @practiceHideAllActivities.
  ///
  /// In de, this message translates to:
  /// **'Alle Aktivitäten ausblenden'**
  String get practiceHideAllActivities;

  /// No description provided for @pathEvidenceTitle.
  ///
  /// In de, this message translates to:
  /// **'Woran du Fortschritt erkennst'**
  String get pathEvidenceTitle;

  /// No description provided for @pathEvidenceBody.
  ///
  /// In de, this message translates to:
  /// **'Freies Ansehen zählt als Verlauf. Sicher wird ein Abschnitt erst durch die passende aktive Prüfung und mindestens 70 % in jeder verknüpften Szenenprüfung.'**
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
  /// **'Schritt 1 · Lernen: Karte antippen oder ? zum Umdrehen, dann nach oben wischen. Herz = später üben, Lesezeichen = Wörterbuch'**
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
  /// **'Rate mit Anlauten'**
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
  /// **'Wähle dein Level von A1 bis C2 und ob Vokale angezeigt werden'**
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

  /// No description provided for @coachSilbenStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Silben-Kreuzworträtsel'**
  String get coachSilbenStep1Title;

  /// No description provided for @coachSilbenStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Fülle das Gitter: Jede Reihe ist ein koreanisches Wort. Wörter kreuzen sich an gemeinsamen Silben. Die rot markierte Zelle ist ausgewählt.'**
  String get coachSilbenStep1Body;

  /// No description provided for @coachSilbenStep2Title.
  ///
  /// In de, this message translates to:
  /// **'Hinweise lesen'**
  String get coachSilbenStep2Title;

  /// No description provided for @coachSilbenStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Der Pfeil zeigt die Richtung im Gitter. Bedeutung und Beispielsatz helfen. ○○ steht für das gesuchte Wort.'**
  String get coachSilbenStep2Body;

  /// No description provided for @coachSilbenStep3Title.
  ///
  /// In de, this message translates to:
  /// **'Silben antippen'**
  String get coachSilbenStep3Title;

  /// No description provided for @coachSilbenStep3Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe unten eine Silbe, um die ausgewählte Zelle zu füllen. Richtige rasten grün ein, falsche schütteln kurz'**
  String get coachSilbenStep3Body;

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
  /// **'Tempo'**
  String get coachListeningStep2Title;

  /// No description provided for @coachListeningStep2Body.
  ///
  /// In de, this message translates to:
  /// **'Oben ein Tempo-Symbol. ? zeigt die Übersetzung auf der Zeile, nicht als Chip-Leiste.'**
  String get coachListeningStep2Body;

  /// No description provided for @coachListeningStep3Title.
  ///
  /// In de, this message translates to:
  /// **'Zeile für Zeile'**
  String get coachListeningStep3Title;

  /// No description provided for @coachListeningStep3Body.
  ///
  /// In de, this message translates to:
  /// **'Nach oben wischen für die nächste Zeile. Doppeltipp ist ein Like, nicht die Wortliste.'**
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
  /// **'\"Gewusst\" verlängert das Intervall · \"Nicht gewusst\" bringt die Karte früher zurück. Nach dem Umdrehen geht auch Wischen: rechts = gewusst, links = nicht gewusst.'**
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
  /// **'Starte beim hervorgehobenen aktuellen Schritt und arbeite dich von dort aus weiter.'**
  String get coachLearningPathBody;

  /// No description provided for @coachBookshelfStep1Title.
  ///
  /// In de, this message translates to:
  /// **'Wortliste erstellen'**
  String get coachBookshelfStep1Title;

  /// No description provided for @coachBookshelfStep1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ＋ oben rechts, um eine eigene Wortliste anzulegen'**
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
  /// **'Antippen = Karte umdrehen · \"Gewusst\" = Wort zum Wiederholen hinzufügen'**
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
  /// **'Schließe Vokabelpacks ab, um alle 25 Stempel freizuschalten'**
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
  /// **'Tippe auf den Smiley-Button, um einen Sticker zur Motivation zu senden'**
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
  /// **'Antwort prüfen'**
  String get questCheckAnswer;

  /// No description provided for @questReplayAudio.
  ///
  /// In de, this message translates to:
  /// **'Erneut anhören'**
  String get questReplayAudio;

  /// No description provided for @questListenAudio.
  ///
  /// In de, this message translates to:
  /// **'Audio anhören'**
  String get questListenAudio;

  /// No description provided for @questBuildAnswerLabel.
  ///
  /// In de, this message translates to:
  /// **'Deine Antwort bauen'**
  String get questBuildAnswerLabel;

  /// No description provided for @questEmptyAnswerSlot.
  ///
  /// In de, this message translates to:
  /// **'Leerer Antwortplatz'**
  String get questEmptyAnswerSlot;

  /// No description provided for @diktatInstruction.
  ///
  /// In de, this message translates to:
  /// **'Hör zu und tippe, was du hörst'**
  String get diktatInstruction;

  /// No description provided for @diktatAnswerLabel.
  ///
  /// In de, this message translates to:
  /// **'Deine koreanische Antwort'**
  String get diktatAnswerLabel;

  /// No description provided for @diktatListenSlow.
  ///
  /// In de, this message translates to:
  /// **'Audio langsam anhören'**
  String get diktatListenSlow;

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
  /// **'Jetzt bist du dran. Baue die Antwort aus den Kacheln.'**
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

  /// No description provided for @scenarioWriteAfterRoleplayTitle.
  ///
  /// In de, this message translates to:
  /// **'Antworte mit deinen eigenen Worten'**
  String get scenarioWriteAfterRoleplayTitle;

  /// No description provided for @scenarioWriteAfterRoleplayBody.
  ///
  /// In de, this message translates to:
  /// **'Schreibe eine kurze koreanische Antwort für diese Situation. Die freiwillige Prüfung beeinflusst deine Punktzahl nicht.'**
  String get scenarioWriteAfterRoleplayBody;

  /// No description provided for @scenarioWriteAfterRoleplayInputLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein koreanischer Satz'**
  String get scenarioWriteAfterRoleplayInputLabel;

  /// No description provided for @scenarioWriteAfterRoleplayInputHint.
  ///
  /// In de, this message translates to:
  /// **'Schreibe eine kurze Antwort auf Koreanisch'**
  String get scenarioWriteAfterRoleplayInputHint;

  /// No description provided for @scenarioWriteAfterRoleplayCheck.
  ///
  /// In de, this message translates to:
  /// **'Satz prüfen'**
  String get scenarioWriteAfterRoleplayCheck;

  /// No description provided for @scenarioWriteAfterRoleplayChecking.
  ///
  /// In de, this message translates to:
  /// **'Wird geprüft…'**
  String get scenarioWriteAfterRoleplayChecking;

  /// No description provided for @scenarioWriteAfterRoleplayDownload.
  ///
  /// In de, this message translates to:
  /// **'Prüfung auf das Gerät laden'**
  String get scenarioWriteAfterRoleplayDownload;

  /// No description provided for @scenarioWriteAfterRoleplayDownloading.
  ///
  /// In de, this message translates to:
  /// **'Prüfung wird geladen…'**
  String get scenarioWriteAfterRoleplayDownloading;

  /// No description provided for @scenarioWriteAfterRoleplayOriginalLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein Original'**
  String get scenarioWriteAfterRoleplayOriginalLabel;

  /// No description provided for @scenarioWriteAfterRoleplaySuggestionLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorschlag'**
  String get scenarioWriteAfterRoleplaySuggestionLabel;

  /// No description provided for @scenarioWriteAfterRoleplayChangesLabel.
  ///
  /// In de, this message translates to:
  /// **'Geprüfte Änderungen'**
  String get scenarioWriteAfterRoleplayChangesLabel;

  /// No description provided for @scenarioWriteAfterRoleplayChangeReasonUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Prüfung auf dem Gerät liefert keinen verifizierten Grund für jede einzelne Änderung.'**
  String get scenarioWriteAfterRoleplayChangeReasonUnavailable;

  /// No description provided for @scenarioWriteAfterRoleplaySceneGrammarReference.
  ///
  /// In de, this message translates to:
  /// **'Grammatikhilfe aus dieser Szene'**
  String get scenarioWriteAfterRoleplaySceneGrammarReference;

  /// No description provided for @scenarioWriteAfterRoleplayWhyLabel.
  ///
  /// In de, this message translates to:
  /// **'Grammatik dieser Szene'**
  String get scenarioWriteAfterRoleplayWhyLabel;

  /// No description provided for @scenarioWriteAfterRoleplayNoChanges.
  ///
  /// In de, this message translates to:
  /// **'Keine Änderung vorgeschlagen.'**
  String get scenarioWriteAfterRoleplayNoChanges;

  /// No description provided for @scenarioWriteAfterRoleplayFallbackTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit dieser Szene üben'**
  String get scenarioWriteAfterRoleplayFallbackTitle;

  /// No description provided for @scenarioWriteAfterRoleplayFallbackBody.
  ///
  /// In de, this message translates to:
  /// **'Die automatische Prüfung ist hier nicht verfügbar. Du kannst deinen Satz trotzdem mit der belegten Szenensprache und Grammatik vergleichen.'**
  String get scenarioWriteAfterRoleplayFallbackBody;

  /// No description provided for @scenarioWriteAfterRoleplayDownloadRequired.
  ///
  /// In de, this message translates to:
  /// **'Lade die Prüfung auf das Gerät, bevor du deinen Satz prüfst.'**
  String get scenarioWriteAfterRoleplayDownloadRequired;

  /// No description provided for @scenarioWriteAfterRoleplayReady.
  ///
  /// In de, this message translates to:
  /// **'Die Prüfung ist bereit. Tippe noch einmal auf Satz prüfen.'**
  String get scenarioWriteAfterRoleplayReady;

  /// No description provided for @scenarioWriteAfterRoleplayAskCompanion.
  ///
  /// In de, this message translates to:
  /// **'Nach der Grammatik dieser Szene fragen'**
  String get scenarioWriteAfterRoleplayAskCompanion;

  /// No description provided for @scenarioWriteAfterRoleplayCompanionTitle.
  ///
  /// In de, this message translates to:
  /// **'Erklärung aus dieser Szene'**
  String get scenarioWriteAfterRoleplayCompanionTitle;

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

  /// No description provided for @courseMissionCompleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Mission abgeschlossen'**
  String get courseMissionCompleteTitle;

  /// No description provided for @courseMissionCompleteBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast alle Lernschritte dieser Mission abgeschlossen.'**
  String get courseMissionCompleteBody;

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

  /// No description provided for @courseMissionBriefScene.
  ///
  /// In de, this message translates to:
  /// **'Deine nächste Szene: {scene}'**
  String courseMissionBriefScene(String scene);

  /// No description provided for @courseMissionBriefTime.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min. bis zur Szene'**
  String courseMissionBriefTime(int minutes);

  /// No description provided for @courseMissionBriefStepMeta.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total} · {minutes} Min.'**
  String courseMissionBriefStepMeta(int current, int total, int minutes);

  /// No description provided for @courseMissionBriefRemaining.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 weiterer Schritt bleibt nach diesem Überblick bereit.} other{{count} weitere Schritte bleiben nach diesem Überblick bereit.}}'**
  String courseMissionBriefRemaining(int count);

  /// No description provided for @courseMissionBriefStart.
  ///
  /// In de, this message translates to:
  /// **'Schritt 1 starten'**
  String get courseMissionBriefStart;

  /// No description provided for @courseMissionBriefWhy.
  ///
  /// In de, this message translates to:
  /// **'Warum diese Szene?'**
  String get courseMissionBriefWhy;

  /// No description provided for @courseMissionBriefStepVocab.
  ///
  /// In de, this message translates to:
  /// **'Schlüsselwörter hören'**
  String get courseMissionBriefStepVocab;

  /// No description provided for @courseMissionBriefStepGrammar.
  ///
  /// In de, this message translates to:
  /// **'Den Satz bauen'**
  String get courseMissionBriefStepGrammar;

  /// No description provided for @courseMissionBriefStepCloze.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Wörter wählen'**
  String get courseMissionBriefStepCloze;

  /// No description provided for @courseMissionBriefStepSatz.
  ///
  /// In de, this message translates to:
  /// **'Den Satz zusammensetzen'**
  String get courseMissionBriefStepSatz;

  /// No description provided for @courseMissionBriefStepScenario.
  ///
  /// In de, this message translates to:
  /// **'In der Szene sprechen'**
  String get courseMissionBriefStepScenario;

  /// No description provided for @courseMissionBriefStepSmalltalk.
  ///
  /// In de, this message translates to:
  /// **'In der Situation antworten'**
  String get courseMissionBriefStepSmalltalk;

  /// No description provided for @courseMissionBriefListenTitle.
  ///
  /// In de, this message translates to:
  /// **'Höre die Situation'**
  String get courseMissionBriefListenTitle;

  /// No description provided for @courseMissionBriefListenBody.
  ///
  /// In de, this message translates to:
  /// **'Erkenne die höfliche Form'**
  String get courseMissionBriefListenBody;

  /// No description provided for @courseMissionBriefBuildTitle.
  ///
  /// In de, this message translates to:
  /// **'Baue deinen Satz'**
  String get courseMissionBriefBuildTitle;

  /// No description provided for @courseMissionBriefBuildBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle die fehlenden Wörter'**
  String get courseMissionBriefBuildBody;

  /// No description provided for @courseMissionBriefCheckpointTitle.
  ///
  /// In de, this message translates to:
  /// **'Mach den Abschlusscheck'**
  String get courseMissionBriefCheckpointTitle;

  /// No description provided for @courseMissionBriefCheckpointBody.
  ///
  /// In de, this message translates to:
  /// **'Löse die letzte Aufgabe dieser Mission'**
  String get courseMissionBriefCheckpointBody;

  /// No description provided for @courseMissionBriefSceneTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprich in der Szene'**
  String get courseMissionBriefSceneTitle;

  /// No description provided for @courseMissionBriefSceneBody.
  ///
  /// In de, this message translates to:
  /// **'Eine echte Antwort, kein Raten'**
  String get courseMissionBriefSceneBody;

  /// No description provided for @courseMissionBriefListenCta.
  ///
  /// In de, this message translates to:
  /// **'Jetzt hören'**
  String get courseMissionBriefListenCta;

  /// No description provided for @courseMissionBriefBuildCta.
  ///
  /// In de, this message translates to:
  /// **'Jetzt bauen'**
  String get courseMissionBriefBuildCta;

  /// No description provided for @courseMissionBriefCheckpointCta.
  ///
  /// In de, this message translates to:
  /// **'Abschlusscheck starten'**
  String get courseMissionBriefCheckpointCta;

  /// No description provided for @courseMissionBriefSceneCta.
  ///
  /// In de, this message translates to:
  /// **'Szene beginnen'**
  String get courseMissionBriefSceneCta;

  /// No description provided for @courseMissionBriefMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String courseMissionBriefMinutes(int minutes);

  /// No description provided for @courseMissionPreviewNotice.
  ///
  /// In de, this message translates to:
  /// **'Du kannst diese Mission ansehen. Punkte und Fortschritt zählen erst, wenn sie aktiv ist.'**
  String get courseMissionPreviewNotice;

  /// No description provided for @courseReassessmentTitle.
  ///
  /// In de, this message translates to:
  /// **'Fähigkeit nachweisen'**
  String get courseReassessmentTitle;

  /// No description provided for @courseReassessmentEyebrow.
  ///
  /// In de, this message translates to:
  /// **'PRODUKTIVER NACHWEIS'**
  String get courseReassessmentEyebrow;

  /// No description provided for @courseReassessmentLoading.
  ///
  /// In de, this message translates to:
  /// **'Deine Aufgabe wird vorbereitet.'**
  String get courseReassessmentLoading;

  /// No description provided for @courseReassessmentLoadError.
  ///
  /// In de, this message translates to:
  /// **'Dieser Nachweis konnte nicht sicher geladen werden.'**
  String get courseReassessmentLoadError;

  /// No description provided for @courseReassessmentError.
  ///
  /// In de, this message translates to:
  /// **'Der Nachweis konnte nicht gespeichert werden. Bitte versuche es erneut.'**
  String get courseReassessmentError;

  /// No description provided for @courseReassessmentStep.
  ///
  /// In de, this message translates to:
  /// **'Nachweis {current} von {total}'**
  String courseReassessmentStep(int current, int total);

  /// No description provided for @courseReassessmentProjectStep.
  ///
  /// In de, this message translates to:
  /// **'Projektschritt {current} von {total}'**
  String courseReassessmentProjectStep(int current, int total);

  /// No description provided for @courseReassessmentRole.
  ///
  /// In de, this message translates to:
  /// **'Deine Rolle'**
  String get courseReassessmentRole;

  /// No description provided for @courseReassessmentPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Freie Texte und Notizen werden weder an Firebase noch an Analytics gesendet. Ein verifizierter Sprechnachweis bleibt deaktiviert, bis die gesonderte Einwilligung und der datensparsame Dienst bereit sind.'**
  String get courseReassessmentPrivacy;

  /// No description provided for @courseReassessmentAnswer.
  ///
  /// In de, this message translates to:
  /// **'Deine koreanische Antwort'**
  String get courseReassessmentAnswer;

  /// No description provided for @courseReassessmentAnswerHint.
  ///
  /// In de, this message translates to:
  /// **'Schreibe die Aussage in deinen eigenen Worten.'**
  String get courseReassessmentAnswerHint;

  /// No description provided for @courseReassessmentLength.
  ///
  /// In de, this message translates to:
  /// **'{minimum} bis {maximum} koreanische Zeichen'**
  String courseReassessmentLength(int minimum, int maximum);

  /// No description provided for @courseReassessmentEvidencePoint.
  ///
  /// In de, this message translates to:
  /// **'Belegpunkt {index}'**
  String courseReassessmentEvidencePoint(int index);

  /// No description provided for @courseReassessmentEvidencePointHint.
  ///
  /// In de, this message translates to:
  /// **'Formuliere diesen Punkt auf Koreanisch und übernimm ihn in deine Gesamtantwort.'**
  String get courseReassessmentEvidencePointHint;

  /// No description provided for @courseReassessmentSourceForPoint.
  ///
  /// In de, this message translates to:
  /// **'Quelle für diesen Punkt'**
  String get courseReassessmentSourceForPoint;

  /// No description provided for @courseReassessmentSources.
  ///
  /// In de, this message translates to:
  /// **'Materialien vergleichen'**
  String get courseReassessmentSources;

  /// No description provided for @courseReassessmentSource.
  ///
  /// In de, this message translates to:
  /// **'Quelle {index}'**
  String courseReassessmentSource(int index);

  /// No description provided for @courseReassessmentProjectReviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Quellen vor der Antwort prüfen'**
  String get courseReassessmentProjectReviewTitle;

  /// No description provided for @courseReassessmentProjectReviewBody.
  ///
  /// In de, this message translates to:
  /// **'Lies jede neu eingeführte Quelle und öffne ihren Herkunftshinweis. Gespeichert werden nur die Quellen-IDs, nicht deine Notizen.'**
  String get courseReassessmentProjectReviewBody;

  /// No description provided for @courseReassessmentProjectMarkReviewed.
  ///
  /// In de, this message translates to:
  /// **'Ich habe diese Quelle gelesen und verglichen'**
  String get courseReassessmentProjectMarkReviewed;

  /// No description provided for @courseReassessmentProjectShowProvenance.
  ///
  /// In de, this message translates to:
  /// **'Herkunft anzeigen'**
  String get courseReassessmentProjectShowProvenance;

  /// No description provided for @courseReassessmentProjectHideProvenance.
  ///
  /// In de, this message translates to:
  /// **'Herkunft ausblenden'**
  String get courseReassessmentProjectHideProvenance;

  /// No description provided for @courseReassessmentProjectCompleteReview.
  ///
  /// In de, this message translates to:
  /// **'Quellenprüfung abschließen'**
  String get courseReassessmentProjectCompleteReview;

  /// No description provided for @courseReassessmentProjectReviewing.
  ///
  /// In de, this message translates to:
  /// **'Quellen werden geprüft …'**
  String get courseReassessmentProjectReviewing;

  /// No description provided for @courseReassessmentProjectReviewIncomplete.
  ///
  /// In de, this message translates to:
  /// **'Lies jede Quelle und öffne jeden Herkunftshinweis, bevor du fortfährst.'**
  String get courseReassessmentProjectReviewIncomplete;

  /// No description provided for @courseReassessmentConnectSources.
  ///
  /// In de, this message translates to:
  /// **'Beziehungen zwischen den Quellen markieren'**
  String get courseReassessmentConnectSources;

  /// No description provided for @courseReassessmentRelationship.
  ///
  /// In de, this message translates to:
  /// **'Rolle dieser Quelle'**
  String get courseReassessmentRelationship;

  /// No description provided for @courseReassessmentSubmit.
  ///
  /// In de, this message translates to:
  /// **'Antwort prüfen'**
  String get courseReassessmentSubmit;

  /// No description provided for @courseReassessmentSubmitEvidence.
  ///
  /// In de, this message translates to:
  /// **'Quellenverknüpfung prüfen'**
  String get courseReassessmentSubmitEvidence;

  /// No description provided for @courseReassessmentChecking.
  ///
  /// In de, this message translates to:
  /// **'Wird geprüft …'**
  String get courseReassessmentChecking;

  /// No description provided for @courseReassessmentOralUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Verifizierter Sprechnachweis ist noch nicht verfügbar'**
  String get courseReassessmentOralUnavailableTitle;

  /// No description provided for @courseReassessmentOralUnavailableBody.
  ///
  /// In de, this message translates to:
  /// **'Die aktuelle zehnsekündige Nachsprechübung trainiert nur die Aussprache und darf dieses Fähigkeitssiegel nicht vergeben. Eine eigene 45- bis 120-sekündige freie Sprechprüfung wird erst nach Prüfung von Einwilligung, Datenschutz und Bewertung freigeschaltet.'**
  String get courseReassessmentOralUnavailableBody;

  /// No description provided for @courseReassessmentPrerequisiteTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein früherer Nachweis fehlt noch'**
  String get courseReassessmentPrerequisiteTitle;

  /// No description provided for @courseReassessmentPrerequisiteBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe zuerst den verknüpften Nachweis ab. Dein Kurszeiger wird dabei nicht zurückgesetzt.'**
  String get courseReassessmentPrerequisiteBody;

  /// No description provided for @courseReassessmentOpenPrerequisite.
  ///
  /// In de, this message translates to:
  /// **'Fehlenden Nachweis öffnen'**
  String get courseReassessmentOpenPrerequisite;

  /// No description provided for @courseReassessmentPassedTitle.
  ///
  /// In de, this message translates to:
  /// **'Nachweis bestanden'**
  String get courseReassessmentPassedTitle;

  /// No description provided for @courseReassessmentPassedBody.
  ///
  /// In de, this message translates to:
  /// **'{score} %. Nur das Ergebnis und seine genaue Aufgabenherkunft wurden gespeichert.'**
  String courseReassessmentPassedBody(int score);

  /// No description provided for @courseReassessmentTryAgainTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht sicher genug'**
  String get courseReassessmentTryAgainTitle;

  /// No description provided for @courseReassessmentTryAgainBody.
  ///
  /// In de, this message translates to:
  /// **'{score} %. Deine Antwort wurde nicht gespeichert. Du kannst sie direkt überarbeiten.'**
  String courseReassessmentTryAgainBody(int score);

  /// No description provided for @courseReassessmentContinue.
  ///
  /// In de, this message translates to:
  /// **'Nächsten Nachweis öffnen'**
  String get courseReassessmentContinue;

  /// No description provided for @courseReassessmentRetry.
  ///
  /// In de, this message translates to:
  /// **'Antwort überarbeiten'**
  String get courseReassessmentRetry;

  /// No description provided for @courseReassessmentFinish.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get courseReassessmentFinish;

  /// No description provided for @courseReassessmentCompleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprechen und Schreiben bestätigt'**
  String get courseReassessmentCompleteTitle;

  /// No description provided for @courseReassessmentCompleteBody.
  ///
  /// In de, this message translates to:
  /// **'Alle erforderlichen produktiven Nachweise für diese Fähigkeit sind geprüft. Deine Kursposition ist unverändert geblieben.'**
  String get courseReassessmentCompleteBody;

  /// No description provided for @courseReassessmentModeGuidedProduction.
  ///
  /// In de, this message translates to:
  /// **'Geführte eigene Antwort'**
  String get courseReassessmentModeGuidedProduction;

  /// No description provided for @courseReassessmentModeDictation.
  ///
  /// In de, this message translates to:
  /// **'Diktat'**
  String get courseReassessmentModeDictation;

  /// No description provided for @courseReassessmentModeConnectedProduction.
  ///
  /// In de, this message translates to:
  /// **'Zusammenhängend schreiben'**
  String get courseReassessmentModeConnectedProduction;

  /// No description provided for @courseReassessmentModeOpenWriting.
  ///
  /// In de, this message translates to:
  /// **'Offen schreiben'**
  String get courseReassessmentModeOpenWriting;

  /// No description provided for @courseReassessmentModeOral.
  ///
  /// In de, this message translates to:
  /// **'Mündlich vortragen'**
  String get courseReassessmentModeOral;

  /// No description provided for @courseReassessmentModeConnectedEvidence.
  ///
  /// In de, this message translates to:
  /// **'Quellen verknüpfen'**
  String get courseReassessmentModeConnectedEvidence;

  /// No description provided for @courseReassessmentRoleSupport.
  ///
  /// In de, this message translates to:
  /// **'stützt die Aussage'**
  String get courseReassessmentRoleSupport;

  /// No description provided for @courseReassessmentRoleContrast.
  ///
  /// In de, this message translates to:
  /// **'zeigt einen Gegensatz'**
  String get courseReassessmentRoleContrast;

  /// No description provided for @courseReassessmentRoleLimitation.
  ///
  /// In de, this message translates to:
  /// **'begrenzt die Aussage'**
  String get courseReassessmentRoleLimitation;

  /// No description provided for @courseReassessmentRoleComplement.
  ///
  /// In de, this message translates to:
  /// **'ergänzt die Aussage'**
  String get courseReassessmentRoleComplement;

  /// No description provided for @courseReassessmentRoleContext.
  ///
  /// In de, this message translates to:
  /// **'liefert Kontext'**
  String get courseReassessmentRoleContext;

  /// No description provided for @courseReassessmentRoleStakeholder.
  ///
  /// In de, this message translates to:
  /// **'zeigt eine betroffene Perspektive'**
  String get courseReassessmentRoleStakeholder;

  /// No description provided for @courseReassessmentRoleCounterexample.
  ///
  /// In de, this message translates to:
  /// **'liefert ein Gegenbeispiel'**
  String get courseReassessmentRoleCounterexample;

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

  /// No description provided for @homeTodayFirst.
  ///
  /// In de, this message translates to:
  /// **'Heute zuerst'**
  String get homeTodayFirst;

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
  /// **'Wiederholen'**
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

  /// No description provided for @homeTodayReviewMission.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort im Kontext wiederholen} other{{n} Wörter im Kontext wiederholen}}'**
  String homeTodayReviewMission(int n);

  /// No description provided for @homeTodayReviewDescription.
  ///
  /// In de, this message translates to:
  /// **'Gib deinen sicheren Sätzen eine Stimme.'**
  String get homeTodayReviewDescription;

  /// No description provided for @homeTodayReviewLead.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, one{1 Wort ist bereit, bevor etwas Neues dazukommt.} other{{n} Wörter sind bereit, bevor etwas Neues dazukommt.}}'**
  String homeTodayReviewLead(int n);

  /// No description provided for @homeTodayNextAction.
  ///
  /// In de, this message translates to:
  /// **'Deine nächste Handlung'**
  String get homeTodayNextAction;

  /// No description provided for @homeTodayReviewReasonTitle.
  ///
  /// In de, this message translates to:
  /// **'Warum heute wiederholen?'**
  String get homeTodayReviewReasonTitle;

  /// No description provided for @homeTodayReviewReason.
  ///
  /// In de, this message translates to:
  /// **'Damit Begrüßungen, Bitten und Antworten in der nächsten Szene schneller verfügbar sind.'**
  String get homeTodayReviewReason;

  /// No description provided for @homeTodayReviewTime.
  ///
  /// In de, this message translates to:
  /// **'ca. 3 Minuten · danach geht dein Weg weiter'**
  String get homeTodayReviewTime;

  /// No description provided for @homeUnavailableEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Verbindung pausiert'**
  String get homeUnavailableEyebrow;

  /// No description provided for @homeUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg wartet auf dich.'**
  String get homeUnavailableTitle;

  /// No description provided for @homeUnavailableDescription.
  ///
  /// In de, this message translates to:
  /// **'Neue Gruppen- und Kontoaktionen brauchen kurz Internet. Deine gespeicherten Wiederholungen sind bereit.'**
  String get homeUnavailableDescription;

  /// No description provided for @homeUnavailableDescriptionNoReview.
  ///
  /// In de, this message translates to:
  /// **'Neue Gruppen- und Kontoaktionen brauchen kurz Internet. Versuche die Verbindung erneut.'**
  String get homeUnavailableDescriptionNoReview;

  /// No description provided for @homeUnavailableSafeTitle.
  ///
  /// In de, this message translates to:
  /// **'Jetzt sicher möglich'**
  String get homeUnavailableSafeTitle;

  /// No description provided for @homeUnavailableSafeBody.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter wiederholen und bisherige Inhalte ansehen.'**
  String get homeUnavailableSafeBody;

  /// No description provided for @homeUnavailableCta.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter wiederholen'**
  String get homeUnavailableCta;

  /// No description provided for @homeUnavailableRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut verbinden'**
  String get homeUnavailableRetry;

  /// No description provided for @homeUnavailableRetryGeneric.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get homeUnavailableRetryGeneric;

  /// No description provided for @homeRemoteUnavailableEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dienst kurz pausiert'**
  String get homeRemoteUnavailableEyebrow;

  /// No description provided for @homeRemoteUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Weg bleibt erhalten.'**
  String get homeRemoteUnavailableTitle;

  /// No description provided for @homeRemoteUnavailableDescription.
  ///
  /// In de, this message translates to:
  /// **'Der Onlinedienst antwortet gerade nicht. Deine gespeicherten Wiederholungen sind bereit.'**
  String get homeRemoteUnavailableDescription;

  /// No description provided for @homeRemoteUnavailableDescriptionNoReview.
  ///
  /// In de, this message translates to:
  /// **'Der Onlinedienst antwortet gerade nicht. Versuche es gleich noch einmal.'**
  String get homeRemoteUnavailableDescriptionNoReview;

  /// No description provided for @homeLocalUnavailableEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Heute braucht einen neuen Versuch'**
  String get homeLocalUnavailableEyebrow;

  /// No description provided for @homeLocalUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein gespeichertes Lernen bleibt sicher.'**
  String get homeLocalUnavailableTitle;

  /// No description provided for @homeLocalUnavailableDescription.
  ///
  /// In de, this message translates to:
  /// **'Heute konnte nicht aus den lokalen Lerndaten vorbereitet werden. Deine gespeicherten Wiederholungen sind weiterhin bereit.'**
  String get homeLocalUnavailableDescription;

  /// No description provided for @homeLocalUnavailableDescriptionNoReview.
  ///
  /// In de, this message translates to:
  /// **'Heute konnte nicht aus den lokalen Lerndaten vorbereitet werden. Versuche, es erneut zu laden.'**
  String get homeLocalUnavailableDescriptionNoReview;

  /// No description provided for @homeEmptyCta.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter wiederholen'**
  String get homeEmptyCta;

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

  /// No description provided for @homeFocusDate.
  ///
  /// In de, this message translates to:
  /// **'Heute · {weekday}'**
  String homeFocusDate(String weekday);

  /// No description provided for @homeFocusBuildTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Haus wächst mit echtem Können.'**
  String get homeFocusBuildTitle;

  /// No description provided for @homeFocusMore.
  ///
  /// In de, this message translates to:
  /// **'Weitere Lernmöglichkeiten'**
  String get homeFocusMore;

  /// No description provided for @homeFocusLess.
  ///
  /// In de, this message translates to:
  /// **'Weitere Lernmöglichkeiten ausblenden'**
  String get homeFocusLess;

  /// No description provided for @homeFocusLaterTitle.
  ///
  /// In de, this message translates to:
  /// **'Später heute'**
  String get homeFocusLaterTitle;

  /// No description provided for @homeFocusLaterBody.
  ///
  /// In de, this message translates to:
  /// **'{count} Wiederholungen bleiben nach deiner ersten Handlung bereit.'**
  String homeFocusLaterBody(int count);

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
  /// **'Lerne im Sarangbang weiter.'**
  String get sarangbangHubDesc;

  /// No description provided for @bojagiTitle.
  ///
  /// In de, this message translates to:
  /// **'Bojagi-Bündel'**
  String get bojagiTitle;

  /// No description provided for @bojagiLoading.
  ///
  /// In de, this message translates to:
  /// **'Dein Bündel wird vorbereitet …'**
  String get bojagiLoading;

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

  /// No description provided for @bojagiChooseDecoration.
  ///
  /// In de, this message translates to:
  /// **'{name} auswählen'**
  String bojagiChooseDecoration(String name);

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

  /// No description provided for @bojagiClaimedAnnouncement.
  ///
  /// In de, this message translates to:
  /// **'Bekommen: {name}'**
  String bojagiClaimedAnnouncement(String name);

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

  /// No description provided for @hanokWorldEarlyEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dein Hof · A1'**
  String get hanokWorldEarlyEyebrow;

  /// No description provided for @hanokWorldEarlyTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine erste Szene ist der Anfang deines Hanok.'**
  String get hanokWorldEarlyTitle;

  /// No description provided for @hanokWorldEarlyBody.
  ///
  /// In de, this message translates to:
  /// **'Jeder Satz aus deinem Alltag, den du sicher kannst, stärkt dein Fundament.'**
  String get hanokWorldEarlyBody;

  /// No description provided for @hanokWorldEarlyVerifiedBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Fundament steht: {canDo}'**
  String hanokWorldEarlyVerifiedBody(Object canDo);

  /// No description provided for @hanokWorldMapEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dein begehbarer Hof'**
  String get hanokWorldMapEyebrow;

  /// No description provided for @hanokWorldMapTitle.
  ///
  /// In de, this message translates to:
  /// **'Wohin möchtest du gehen?'**
  String get hanokWorldMapTitle;

  /// No description provided for @hanokWorldMapBody.
  ///
  /// In de, this message translates to:
  /// **'Jedes Gebäude führt zu einem Teil von Hangul Sori.'**
  String get hanokWorldMapBody;

  /// No description provided for @hanokWorldOpenNextScene.
  ///
  /// In de, this message translates to:
  /// **'Nächste Szene ansehen'**
  String get hanokWorldOpenNextScene;

  /// No description provided for @hanokWorldNextBeamTitle.
  ///
  /// In de, this message translates to:
  /// **'Nächster Bauabschnitt'**
  String get hanokWorldNextBeamTitle;

  /// No description provided for @hanokWorldExploreHouse.
  ///
  /// In de, this message translates to:
  /// **'Mein Haus erkunden'**
  String get hanokWorldExploreHouse;

  /// No description provided for @hanokWorldSafeSceneProgress.
  ///
  /// In de, this message translates to:
  /// **'{current} von {total} Szenarien sicher gemeistert'**
  String hanokWorldSafeSceneProgress(int current, int total);

  /// No description provided for @hanokWorldIntro.
  ///
  /// In de, this message translates to:
  /// **'Setz dein Lernen dort fort, wo dein Hanok wächst. Jedes gebaute Gebäude führt dich zu einem Bereich von Hangul Sori.'**
  String get hanokWorldIntro;

  /// No description provided for @hanokWorldLegacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Hof wächst'**
  String get hanokWorldLegacyTitle;

  /// No description provided for @hanokWorldLegacyBody.
  ///
  /// In de, this message translates to:
  /// **'Schließe A1 und A2 ab. Mit deinem ersten Fortschritt in B1 öffnet sich die große Hanok-Karte.'**
  String get hanokWorldLegacyBody;

  /// No description provided for @hanokWorldMapHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein gebautes Gebäude, um dort weiterzulernen.'**
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
  /// **'Der Gye-Hof ist von deiner privaten Hanok getrennt. Dort triffst du deine Lerngruppe.'**
  String get hanokWorldGyeBridgeBody;

  /// No description provided for @hanokWorldGyeBridgeOpen.
  ///
  /// In de, this message translates to:
  /// **'Gye-Hof besuchen'**
  String get hanokWorldGyeBridgeOpen;

  /// No description provided for @hanokWorldPlacesTitle.
  ///
  /// In de, this message translates to:
  /// **'Orte als Liste anzeigen'**
  String get hanokWorldPlacesTitle;

  /// No description provided for @hanokWorldPlacesBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen verfügbaren Ort aus.'**
  String get hanokWorldPlacesBody;

  /// No description provided for @hanokMapPlaceSarangbang.
  ///
  /// In de, this message translates to:
  /// **'사랑방\nHeute lernen'**
  String get hanokMapPlaceSarangbang;

  /// No description provided for @hanokMapPlaceDaecheong.
  ///
  /// In de, this message translates to:
  /// **'대청마루\nDein Weg'**
  String get hanokMapPlaceDaecheong;

  /// No description provided for @hanokMapPlaceHaengrang.
  ///
  /// In de, this message translates to:
  /// **'행랑채\nÜben'**
  String get hanokMapPlaceHaengrang;

  /// No description provided for @hanokMapPlaceAnchae.
  ///
  /// In de, this message translates to:
  /// **'안채\nWörter'**
  String get hanokMapPlaceAnchae;

  /// No description provided for @hanokMapPlaceHuwon.
  ///
  /// In de, this message translates to:
  /// **'후원\nAufgaben'**
  String get hanokMapPlaceHuwon;

  /// No description provided for @hanokMapPlaceSadang.
  ///
  /// In de, this message translates to:
  /// **'사당\nErfolge'**
  String get hanokMapPlaceSadang;

  /// No description provided for @hanokZoneSarangbang.
  ///
  /// In de, this message translates to:
  /// **'사랑방 · Deine heutige Szene'**
  String get hanokZoneSarangbang;

  /// No description provided for @hanokZoneDaecheong.
  ///
  /// In de, this message translates to:
  /// **'대청마루 · Dein Weg'**
  String get hanokZoneDaecheong;

  /// No description provided for @hanokZoneHaengrang.
  ///
  /// In de, this message translates to:
  /// **'행랑채 · Üben'**
  String get hanokZoneHaengrang;

  /// No description provided for @hanokZoneAnchae.
  ///
  /// In de, this message translates to:
  /// **'안채 · Meine Wörter'**
  String get hanokZoneAnchae;

  /// No description provided for @hanokZoneHuwon.
  ///
  /// In de, this message translates to:
  /// **'후원 · Aufgaben'**
  String get hanokZoneHuwon;

  /// No description provided for @hanokZoneSadang.
  ///
  /// In de, this message translates to:
  /// **'사당 · Erfolge'**
  String get hanokZoneSadang;

  /// No description provided for @hanokWorldPurposeSarangbang.
  ///
  /// In de, this message translates to:
  /// **'Kehre zu deiner heutigen Szene und den erarbeiteten Ausdrücken zurück.'**
  String get hanokWorldPurposeSarangbang;

  /// No description provided for @hanokWorldPurposeDaecheong.
  ///
  /// In de, this message translates to:
  /// **'Sieh deinen Lernpfad und wähle die nächste freigeschaltete Mission.'**
  String get hanokWorldPurposeDaecheong;

  /// No description provided for @hanokWorldPurposeHaengrang.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine gezielte Übung oder ein kurzes Spiel.'**
  String get hanokWorldPurposeHaengrang;

  /// No description provided for @hanokWorldPurposeAnchae.
  ///
  /// In de, this message translates to:
  /// **'Öffne gespeicherte Wörter, Bücher und deine persönliche Lernsammlung.'**
  String get hanokWorldPurposeAnchae;

  /// No description provided for @hanokWorldPurposeHuwon.
  ///
  /// In de, this message translates to:
  /// **'Wähle das Zeichen des Tages oder eine Quest.'**
  String get hanokWorldPurposeHuwon;

  /// No description provided for @hanokWorldPurposeSadang.
  ///
  /// In de, this message translates to:
  /// **'Sieh dir die Meilensteine deines Lernwegs an.'**
  String get hanokWorldPurposeSadang;

  /// No description provided for @hanokWorldPurposeGyeRoad.
  ///
  /// In de, this message translates to:
  /// **'Der gemeinsame Gye-Hof bleibt von deiner privaten Hanok getrennt.'**
  String get hanokWorldPurposeGyeRoad;

  /// No description provided for @hanokWorldSelectPlaceTitle.
  ///
  /// In de, this message translates to:
  /// **'Verfügbaren Ort wählen'**
  String get hanokWorldSelectPlaceTitle;

  /// No description provided for @hanokWorldSelectPlaceBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein Gebäude auf der Karte oder wähle es aus der Liste.'**
  String get hanokWorldSelectPlaceBody;

  /// No description provided for @hanokWorldPlaceReadyBody.
  ///
  /// In de, this message translates to:
  /// **'{place} ist jetzt verfügbar.'**
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

  /// No description provided for @hanokWorldTodaySceneDetail.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Minuten · „{expression}“ sagen'**
  String hanokWorldTodaySceneDetail(int minutes, String expression);

  /// No description provided for @hanokWorldGoThere.
  ///
  /// In de, this message translates to:
  /// **'Dorthin gehen'**
  String get hanokWorldGoThere;

  /// No description provided for @hanokWorldRevealTitle.
  ///
  /// In de, this message translates to:
  /// **'{place} ist fertig gebaut'**
  String hanokWorldRevealTitle(String place);

  /// No description provided for @hanokWorldRevealBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok ist um einen Bereich gewachsen.'**
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
  /// **'Hier findest du gespeicherte Wörter, Bücher und eigene Lernsammlungen.'**
  String get hanokVenueAnbangBody;

  /// No description provided for @hanokVenueDaecheongBody.
  ///
  /// In de, this message translates to:
  /// **'Setz deinen Lernweg fort oder richte den Raum ein.'**
  String get hanokVenueDaecheongBody;

  /// No description provided for @hanokVenueHaengrangBody.
  ///
  /// In de, this message translates to:
  /// **'Im Eingangsflügel kannst du eine weitere Übungsrunde starten.'**
  String get hanokVenueHaengrangBody;

  /// No description provided for @hanokVenueHuwonBody.
  ///
  /// In de, this message translates to:
  /// **'Im hinteren Garten findest du das Zeichen des Tages und neue Quests.'**
  String get hanokVenueHuwonBody;

  /// No description provided for @hanokVenueSadangBody.
  ///
  /// In de, this message translates to:
  /// **'Im Ahnenschrein siehst du die Meilensteine deines Lernwegs.'**
  String get hanokVenueSadangBody;

  /// No description provided for @sarangbangStudyTitle.
  ///
  /// In de, this message translates to:
  /// **'Sarangbang'**
  String get sarangbangStudyTitle;

  /// No description provided for @sarangbangStudyIntroTitle.
  ///
  /// In de, this message translates to:
  /// **'Was du heute gelernt hast'**
  String get sarangbangStudyIntroTitle;

  /// No description provided for @sarangbangStudyIntroBody.
  ///
  /// In de, this message translates to:
  /// **'Hier findest du deine heutigen Lernfortschritte.'**
  String get sarangbangStudyIntroBody;

  /// No description provided for @sarangbangStudySceneLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernzimmer'**
  String get sarangbangStudySceneLabel;

  /// No description provided for @sarangbangStudyFurnish.
  ///
  /// In de, this message translates to:
  /// **'Studierstube einrichten'**
  String get sarangbangStudyFurnish;

  /// No description provided for @sarangbangFurnishTitle.
  ///
  /// In de, this message translates to:
  /// **'Einrichten'**
  String get sarangbangFurnishTitle;

  /// No description provided for @sarangbangFurnishBody.
  ///
  /// In de, this message translates to:
  /// **'Du erhältst neue Gegenstände als klar gekennzeichnete Belohnungen.'**
  String get sarangbangFurnishBody;

  /// No description provided for @sarangbangStoredTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute gesammelt'**
  String get sarangbangStoredTitle;

  /// No description provided for @sarangbangStoredEmpty.
  ///
  /// In de, this message translates to:
  /// **'Neue Ausdrücke und gemeisterte Szenen erscheinen hier, sobald du sie freigeschaltet hast.'**
  String get sarangbangStoredEmpty;

  /// No description provided for @sarangbangStoredBody.
  ///
  /// In de, this message translates to:
  /// **'{detail} · Deine aktuelle Szene bleibt auf der Startseite ausgewählt.'**
  String sarangbangStoredBody(Object detail);

  /// No description provided for @sarangbangStoredRecord.
  ///
  /// In de, this message translates to:
  /// **'{expressions, plural, =0{Keine Ausdrücke} =1{1 Ausdruck} other{{expressions} Ausdrücke}} · {scenes, plural, =0{keine gemeisterte Szene} =1{1 gemeisterte Szene} other{{scenes} gemeisterte Szenen}} · {beams, plural, =0{kein Balken im Bauplan} =1{1 Balken im Bauplan} other{{beams} Balken im Bauplan}}'**
  String sarangbangStoredRecord(int expressions, int scenes, int beams);

  /// No description provided for @sarangbangOpenToday.
  ///
  /// In de, this message translates to:
  /// **'Zur heutigen Szene'**
  String get sarangbangOpenToday;

  /// No description provided for @sarangbangReturnCourtyard.
  ///
  /// In de, this message translates to:
  /// **'Zum Hof'**
  String get sarangbangReturnCourtyard;

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

  /// No description provided for @personalRoomEditorHint.
  ///
  /// In de, this message translates to:
  /// **'Ziehe ein Stück frei durch den Raum. Mit zwei Fingern kannst du es drehen und vergrößern. Die Werkzeugleiste funktioniert auch ohne Gesten.'**
  String get personalRoomEditorHint;

  /// No description provided for @personalRoomInventoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Gestaltungskiste'**
  String get personalRoomInventoryTitle;

  /// No description provided for @personalRoomInventoryDecorations.
  ///
  /// In de, this message translates to:
  /// **'Einrichtung'**
  String get personalRoomInventoryDecorations;

  /// No description provided for @personalRoomInventoryStickers.
  ///
  /// In de, this message translates to:
  /// **'Sticker'**
  String get personalRoomInventoryStickers;

  /// No description provided for @personalRoomInventoryStamps.
  ///
  /// In de, this message translates to:
  /// **'Stempel'**
  String get personalRoomInventoryStamps;

  /// No description provided for @personalRoomNoDecorations.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einrichtung. Öffne ein Bojagi-Bündel, um ein Stück zu erhalten.'**
  String get personalRoomNoDecorations;

  /// No description provided for @personalRoomNoStamps.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Dancheong-Stempel. Schließe ein Wortpaket ab, um einen zu erhalten.'**
  String get personalRoomNoStamps;

  /// No description provided for @personalRoomSelectedItem.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählt: {item}'**
  String personalRoomSelectedItem(String item);

  /// No description provided for @personalRoomMoveLeft.
  ///
  /// In de, this message translates to:
  /// **'Nach links'**
  String get personalRoomMoveLeft;

  /// No description provided for @personalRoomMoveRight.
  ///
  /// In de, this message translates to:
  /// **'Nach rechts'**
  String get personalRoomMoveRight;

  /// No description provided for @personalRoomMoveUp.
  ///
  /// In de, this message translates to:
  /// **'Nach oben'**
  String get personalRoomMoveUp;

  /// No description provided for @personalRoomMoveDown.
  ///
  /// In de, this message translates to:
  /// **'Nach unten'**
  String get personalRoomMoveDown;

  /// No description provided for @personalRoomMakeSmaller.
  ///
  /// In de, this message translates to:
  /// **'Verkleinern'**
  String get personalRoomMakeSmaller;

  /// No description provided for @personalRoomMakeLarger.
  ///
  /// In de, this message translates to:
  /// **'Vergrößern'**
  String get personalRoomMakeLarger;

  /// No description provided for @personalRoomRotateLeft.
  ///
  /// In de, this message translates to:
  /// **'Nach links drehen'**
  String get personalRoomRotateLeft;

  /// No description provided for @personalRoomRotateRight.
  ///
  /// In de, this message translates to:
  /// **'Nach rechts drehen'**
  String get personalRoomRotateRight;

  /// No description provided for @personalRoomSendBackward.
  ///
  /// In de, this message translates to:
  /// **'Eine Ebene nach hinten'**
  String get personalRoomSendBackward;

  /// No description provided for @personalRoomBringForward.
  ///
  /// In de, this message translates to:
  /// **'Eine Ebene nach vorn'**
  String get personalRoomBringForward;

  /// No description provided for @personalRoomRemoveItem.
  ///
  /// In de, this message translates to:
  /// **'In die Kiste zurücklegen'**
  String get personalRoomRemoveItem;

  /// No description provided for @personalRoomAddItem.
  ///
  /// In de, this message translates to:
  /// **'{item} in den Raum stellen'**
  String personalRoomAddItem(String item);

  /// No description provided for @personalRoomItemInUse.
  ///
  /// In de, this message translates to:
  /// **'Bereits in einem Zimmer'**
  String get personalRoomItemInUse;

  /// No description provided for @personalRoomStickerLimit.
  ///
  /// In de, this message translates to:
  /// **'Hier kann kein weiteres Exemplar platziert werden. Lege zuerst etwas zurück.'**
  String get personalRoomStickerLimit;

  /// No description provided for @personalRoomSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Anordnung konnte nicht gespeichert werden. Versuch es noch einmal.'**
  String get personalRoomSaveFailed;

  /// No description provided for @personalRoomFutureLayout.
  ///
  /// In de, this message translates to:
  /// **'Diese Anordnung stammt aus einer neueren App-Version und bleibt schreibgeschützt.'**
  String get personalRoomFutureLayout;

  /// No description provided for @personalRoomSelectItemHint.
  ///
  /// In de, this message translates to:
  /// **'Zum Anordnen auswählen'**
  String get personalRoomSelectItemHint;

  /// No description provided for @personalRoomStickerFallback.
  ///
  /// In de, this message translates to:
  /// **'Sticker'**
  String get personalRoomStickerFallback;

  /// No description provided for @personalRoomStampFallback.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Stempel'**
  String get personalRoomStampFallback;

  /// No description provided for @decorNameMunbangsau.
  ///
  /// In de, this message translates to:
  /// **'Schreibzeug (문방사우)'**
  String get decorNameMunbangsau;

  /// No description provided for @decorNameSeoan.
  ///
  /// In de, this message translates to:
  /// **'Schreibpult (서안)'**
  String get decorNameSeoan;

  /// No description provided for @decorNameChaekgado.
  ///
  /// In de, this message translates to:
  /// **'Bücherwand-Wandschirm (책가도)'**
  String get decorNameChaekgado;

  /// No description provided for @decorNameGatBuchae.
  ///
  /// In de, this message translates to:
  /// **'Hut und Fächer (갓·부채)'**
  String get decorNameGatBuchae;

  /// No description provided for @decorNameJagaeMungap.
  ///
  /// In de, this message translates to:
  /// **'Perlmutt-Truhe (자개 문갑)'**
  String get decorNameJagaeMungap;

  /// No description provided for @decorNameSoban.
  ///
  /// In de, this message translates to:
  /// **'Tabletttisch (소반)'**
  String get decorNameSoban;

  /// No description provided for @decorNameSagunjaMaehwa.
  ///
  /// In de, this message translates to:
  /// **'Pflaumenblüten-Bild (매화)'**
  String get decorNameSagunjaMaehwa;

  /// No description provided for @decorNameSagunjaNan.
  ///
  /// In de, this message translates to:
  /// **'Orchideen-Bild (난초)'**
  String get decorNameSagunjaNan;

  /// No description provided for @decorNameSagunjaGuk.
  ///
  /// In de, this message translates to:
  /// **'Chrysanthemen-Bild (국화)'**
  String get decorNameSagunjaGuk;

  /// No description provided for @decorNameSagunjaJuk.
  ///
  /// In de, this message translates to:
  /// **'Bambus-Bild (대나무)'**
  String get decorNameSagunjaJuk;

  /// No description provided for @decorNamePyeonaek.
  ///
  /// In de, this message translates to:
  /// **'Namenstafel (편액)'**
  String get decorNamePyeonaek;

  /// No description provided for @decorNameJangdokdae.
  ///
  /// In de, this message translates to:
  /// **'Jangdokdae (Krugterrasse)'**
  String get decorNameJangdokdae;

  /// No description provided for @decorNameMaehwa.
  ///
  /// In de, this message translates to:
  /// **'Pflaumenbaum (매화)'**
  String get decorNameMaehwa;

  /// No description provided for @decorNameSonamu.
  ///
  /// In de, this message translates to:
  /// **'Alte Kiefer (노송)'**
  String get decorNameSonamu;

  /// No description provided for @decorNamePond.
  ///
  /// In de, this message translates to:
  /// **'Teich & Karpfen (연못)'**
  String get decorNamePond;

  /// No description provided for @decorNameSeokdeung.
  ///
  /// In de, this message translates to:
  /// **'Steinlaterne (장명등)'**
  String get decorNameSeokdeung;

  /// No description provided for @decorNamePunggyeong.
  ///
  /// In de, this message translates to:
  /// **'Windspiel (풍경)'**
  String get decorNamePunggyeong;

  /// No description provided for @decorNameDoldam.
  ///
  /// In de, this message translates to:
  /// **'Steinmauer (돌담)'**
  String get decorNameDoldam;

  /// No description provided for @decorNameKkachiNest.
  ///
  /// In de, this message translates to:
  /// **'Elsternnest (까치 둥지)'**
  String get decorNameKkachiNest;

  /// No description provided for @decorNameDokkaebiFire.
  ///
  /// In de, this message translates to:
  /// **'Irrlicht (도깨비불)'**
  String get decorNameDokkaebiFire;

  /// No description provided for @decorNameSeollalFlag.
  ///
  /// In de, this message translates to:
  /// **'Seollal-Yutspiel (윷놀이)'**
  String get decorNameSeollalFlag;

  /// No description provided for @decorNameChuseokMoon.
  ///
  /// In de, this message translates to:
  /// **'Chuseok-Vollmond (보름달)'**
  String get decorNameChuseokMoon;

  /// No description provided for @decorNameHangeuldayPlaque.
  ///
  /// In de, this message translates to:
  /// **'Hangul-Tag Sejong-Tafel (세종 편액)'**
  String get decorNameHangeuldayPlaque;

  /// No description provided for @decorNameKite.
  ///
  /// In de, this message translates to:
  /// **'Kinder-Tag Drachen (연)'**
  String get decorNameKite;

  /// No description provided for @decorNameSabangtakja.
  ///
  /// In de, this message translates to:
  /// **'Regal (사방탁자)'**
  String get decorNameSabangtakja;

  /// No description provided for @decorNameBoryoSet.
  ///
  /// In de, this message translates to:
  /// **'Sitzpolster-Set (보료)'**
  String get decorNameBoryoSet;

  /// No description provided for @decorNameBangseokPair.
  ///
  /// In de, this message translates to:
  /// **'Sitzkissen (방석)'**
  String get decorNameBangseokPair;

  /// No description provided for @decorNameBandaji.
  ///
  /// In de, this message translates to:
  /// **'Klapptruhe (반닫이)'**
  String get decorNameBandaji;

  /// No description provided for @decorNameHwaro.
  ///
  /// In de, this message translates to:
  /// **'Kohlebecken (화로)'**
  String get decorNameHwaro;

  /// No description provided for @decorNameDeungjan.
  ///
  /// In de, this message translates to:
  /// **'Öllampe (등잔대)'**
  String get decorNameDeungjan;

  /// No description provided for @decorNameGeomungo.
  ///
  /// In de, this message translates to:
  /// **'Geomungo-Zither (거문고)'**
  String get decorNameGeomungo;

  /// No description provided for @decorNameBaduk.
  ///
  /// In de, this message translates to:
  /// **'Baduk-Brett (바둑판)'**
  String get decorNameBaduk;

  /// No description provided for @decorNameMokchim.
  ///
  /// In de, this message translates to:
  /// **'Holzkissen (목침)'**
  String get decorNameMokchim;

  /// No description provided for @decorNameByeongpungSmall.
  ///
  /// In de, this message translates to:
  /// **'Kleiner Wandschirm (소병풍)'**
  String get decorNameByeongpungSmall;

  /// No description provided for @decorNameGobi.
  ///
  /// In de, this message translates to:
  /// **'Briefhalter (고비)'**
  String get decorNameGobi;

  /// No description provided for @decorNameHyangno.
  ///
  /// In de, this message translates to:
  /// **'Räuchergefäß (향로)'**
  String get decorNameHyangno;

  /// No description provided for @decorNameFallback.
  ///
  /// In de, this message translates to:
  /// **'Dekoration'**
  String get decorNameFallback;

  /// No description provided for @stickerNameTigerCheer.
  ///
  /// In de, this message translates to:
  /// **'Jubelnder Tiger'**
  String get stickerNameTigerCheer;

  /// No description provided for @stickerNameTigerClap.
  ///
  /// In de, this message translates to:
  /// **'Klatschender Tiger'**
  String get stickerNameTigerClap;

  /// No description provided for @stickerNameTigerSurprised.
  ///
  /// In de, this message translates to:
  /// **'Überraschter Tiger'**
  String get stickerNameTigerSurprised;

  /// No description provided for @stickerNameTigerSad.
  ///
  /// In de, this message translates to:
  /// **'Trauriger Tiger'**
  String get stickerNameTigerSad;

  /// No description provided for @stickerNameTigerLove.
  ///
  /// In de, this message translates to:
  /// **'Verliebter Tiger'**
  String get stickerNameTigerLove;

  /// No description provided for @stickerNameMagpieDance.
  ///
  /// In de, this message translates to:
  /// **'Tanzende Elster'**
  String get stickerNameMagpieDance;

  /// No description provided for @stickerNameMagpieWave.
  ///
  /// In de, this message translates to:
  /// **'Winkende Elster'**
  String get stickerNameMagpieWave;

  /// No description provided for @stickerNameMagpieSleep.
  ///
  /// In de, this message translates to:
  /// **'Schlafende Elster'**
  String get stickerNameMagpieSleep;

  /// No description provided for @stickerNameMagpieSing.
  ///
  /// In de, this message translates to:
  /// **'Singende Elster'**
  String get stickerNameMagpieSing;

  /// No description provided for @stickerNameMagpieEncourage.
  ///
  /// In de, this message translates to:
  /// **'Aufmunternde Elster'**
  String get stickerNameMagpieEncourage;

  /// No description provided for @stickerNameDancheongFlower.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Blüte'**
  String get stickerNameDancheongFlower;

  /// No description provided for @stickerNameDancheongStar.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Stern'**
  String get stickerNameDancheongStar;

  /// No description provided for @stickerNameDancheongCloud.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Wolke'**
  String get stickerNameDancheongCloud;

  /// No description provided for @stickerNameDancheongLantern.
  ///
  /// In de, this message translates to:
  /// **'Dancheong-Laterne'**
  String get stickerNameDancheongLantern;

  /// No description provided for @stickerNameDancheongHanji.
  ///
  /// In de, this message translates to:
  /// **'Hanji-Papier'**
  String get stickerNameDancheongHanji;

  /// No description provided for @stickerNameHangulKk.
  ///
  /// In de, this message translates to:
  /// **'ㅋㅋ · Lautes Lachen'**
  String get stickerNameHangulKk;

  /// No description provided for @stickerNameHangulHh.
  ///
  /// In de, this message translates to:
  /// **'ㅎㅎ · Leises Kichern'**
  String get stickerNameHangulHh;

  /// No description provided for @stickerNameHangulFighting.
  ///
  /// In de, this message translates to:
  /// **'화이팅! · Du schaffst das'**
  String get stickerNameHangulFighting;

  /// No description provided for @stickerNameHangulBest.
  ///
  /// In de, this message translates to:
  /// **'최고! · Einfach spitze'**
  String get stickerNameHangulBest;

  /// No description provided for @stickerNameHangulGood.
  ///
  /// In de, this message translates to:
  /// **'굿 · Gut gemacht'**
  String get stickerNameHangulGood;

  /// No description provided for @stickerNameFoodTteok.
  ///
  /// In de, this message translates to:
  /// **'Tteok-Reiskuchen'**
  String get stickerNameFoodTteok;

  /// No description provided for @stickerNameFoodTea.
  ///
  /// In de, this message translates to:
  /// **'Koreanischer Tee'**
  String get stickerNameFoodTea;

  /// No description provided for @stickerNameFoodKimbap.
  ///
  /// In de, this message translates to:
  /// **'Gimbap'**
  String get stickerNameFoodKimbap;

  /// No description provided for @stickerNameFoodHotteok.
  ///
  /// In de, this message translates to:
  /// **'Hotteok'**
  String get stickerNameFoodHotteok;

  /// No description provided for @stickerNameFoodSikhye.
  ///
  /// In de, this message translates to:
  /// **'Sikhye-Reisgetränk'**
  String get stickerNameFoodSikhye;

  /// No description provided for @stickerNameStampWellDone.
  ///
  /// In de, this message translates to:
  /// **'Stempel · Sehr gut gemacht'**
  String get stickerNameStampWellDone;

  /// No description provided for @stickerNameStampFighting.
  ///
  /// In de, this message translates to:
  /// **'Stempel · Du schaffst das'**
  String get stickerNameStampFighting;

  /// No description provided for @stickerNameStampLove.
  ///
  /// In de, this message translates to:
  /// **'Stempel · Mit Liebe'**
  String get stickerNameStampLove;

  /// No description provided for @stickerNameStampCheer.
  ///
  /// In de, this message translates to:
  /// **'Stempel · Applaus'**
  String get stickerNameStampCheer;

  /// No description provided for @stickerNameStampHappy.
  ///
  /// In de, this message translates to:
  /// **'Stempel · Glücklich'**
  String get stickerNameStampHappy;

  /// No description provided for @stampMotifLotus.
  ///
  /// In de, this message translates to:
  /// **'Lotus-Dancheong'**
  String get stampMotifLotus;

  /// No description provided for @stampMotifChrysanthemum.
  ///
  /// In de, this message translates to:
  /// **'Chrysanthemen-Dancheong'**
  String get stampMotifChrysanthemum;

  /// No description provided for @stampMotifPlum.
  ///
  /// In de, this message translates to:
  /// **'Pflaumenblüten-Dancheong'**
  String get stampMotifPlum;

  /// No description provided for @stampMotifBamboo.
  ///
  /// In de, this message translates to:
  /// **'Bambus-Dancheong'**
  String get stampMotifBamboo;

  /// No description provided for @stampMotifCloud.
  ///
  /// In de, this message translates to:
  /// **'Wolken-Dancheong'**
  String get stampMotifCloud;

  /// No description provided for @stampMotifOctagon.
  ///
  /// In de, this message translates to:
  /// **'Achteck-Dancheong'**
  String get stampMotifOctagon;

  /// No description provided for @stampMotifMountain.
  ///
  /// In de, this message translates to:
  /// **'Berg-Dancheong'**
  String get stampMotifMountain;

  /// No description provided for @stampMotifManja.
  ///
  /// In de, this message translates to:
  /// **'Manja-Dancheong'**
  String get stampMotifManja;

  /// No description provided for @stampMotifVine.
  ///
  /// In de, this message translates to:
  /// **'Ranken-Dancheong'**
  String get stampMotifVine;

  /// No description provided for @stampMotifChilbo.
  ///
  /// In de, this message translates to:
  /// **'Chilbo-Dancheong'**
  String get stampMotifChilbo;

  /// No description provided for @stampMotifGwigap.
  ///
  /// In de, this message translates to:
  /// **'Gwigap-Dancheong'**
  String get stampMotifGwigap;

  /// No description provided for @stampMotifWave.
  ///
  /// In de, this message translates to:
  /// **'Wellen-Dancheong'**
  String get stampMotifWave;

  /// No description provided for @stampMotifTaegeuk.
  ///
  /// In de, this message translates to:
  /// **'Taegeuk-Dancheong'**
  String get stampMotifTaegeuk;

  /// No description provided for @stampMotifPeony.
  ///
  /// In de, this message translates to:
  /// **'Pfingstrosen-Dancheong'**
  String get stampMotifPeony;

  /// No description provided for @stampMotifChangsal.
  ///
  /// In de, this message translates to:
  /// **'Fenstergitter-Dancheong'**
  String get stampMotifChangsal;

  /// No description provided for @stampMotifSuryeon.
  ///
  /// In de, this message translates to:
  /// **'Seerosen-Dancheong'**
  String get stampMotifSuryeon;

  /// No description provided for @stampMotifNoemun.
  ///
  /// In de, this message translates to:
  /// **'Noemun-Dancheong'**
  String get stampMotifNoemun;

  /// No description provided for @stampMotifMugunghwa.
  ///
  /// In de, this message translates to:
  /// **'Mugunghwa-Dancheong'**
  String get stampMotifMugunghwa;

  /// No description provided for @stampMotifMoran.
  ///
  /// In de, this message translates to:
  /// **'Moran-Dancheong'**
  String get stampMotifMoran;

  /// No description provided for @stampMotifMunbangsau.
  ///
  /// In de, this message translates to:
  /// **'Vier Schätze des Studierzimmers'**
  String get stampMotifMunbangsau;

  /// No description provided for @stampMotifBok.
  ///
  /// In de, this message translates to:
  /// **'Glückszeichen Bok (福)'**
  String get stampMotifBok;

  /// No description provided for @stampMotifCrane.
  ///
  /// In de, this message translates to:
  /// **'Fliegender Kranich'**
  String get stampMotifCrane;

  /// No description provided for @stampMotifWadang.
  ///
  /// In de, this message translates to:
  /// **'Lächelnder Dachziegel'**
  String get stampMotifWadang;

  /// No description provided for @stampMotifYeopjeon.
  ///
  /// In de, this message translates to:
  /// **'Drei Yeopjeon-Münzen'**
  String get stampMotifYeopjeon;

  /// No description provided for @stampMotifSoban.
  ///
  /// In de, this message translates to:
  /// **'Soban-Tisch'**
  String get stampMotifSoban;

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

  /// No description provided for @soriStageNavToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get soriStageNavToday;

  /// No description provided for @soriStageNavLearn.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get soriStageNavLearn;

  /// No description provided for @soriStageNavGames.
  ///
  /// In de, this message translates to:
  /// **'Spiele'**
  String get soriStageNavGames;

  /// No description provided for @soriStageNavHanok.
  ///
  /// In de, this message translates to:
  /// **'Hanok'**
  String get soriStageNavHanok;

  /// No description provided for @soriStageNavGye.
  ///
  /// In de, this message translates to:
  /// **'Gye'**
  String get soriStageNavGye;

  /// No description provided for @soriStageProfileTooltip.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get soriStageProfileTooltip;

  /// No description provided for @soriStageTodayEyebrow.
  ///
  /// In de, this message translates to:
  /// **'HEUTE'**
  String get soriStageTodayEyebrow;

  /// No description provided for @soriStageTodayTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein Satz. Ein Bauteil.'**
  String get soriStageTodayTitle;

  /// No description provided for @soriStageTodayEmpty.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine kurze Aktivität und baue an deiner Hanok weiter.'**
  String get soriStageTodayEmpty;

  /// No description provided for @soriStageMissionAction.
  ///
  /// In de, this message translates to:
  /// **'Heutige Mission starten'**
  String get soriStageMissionAction;

  /// No description provided for @soriStageTodayMissionEyebrow.
  ///
  /// In de, this message translates to:
  /// **'HEUTIGE MISSION'**
  String get soriStageTodayMissionEyebrow;

  /// No description provided for @soriStageMissionStart.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get soriStageMissionStart;

  /// No description provided for @hanokStageNameEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bauplatz'**
  String get hanokStageNameEmpty;

  /// No description provided for @hanokStageNameFoundation.
  ///
  /// In de, this message translates to:
  /// **'Fundament'**
  String get hanokStageNameFoundation;

  /// No description provided for @hanokStageNamePillars.
  ///
  /// In de, this message translates to:
  /// **'Säulen'**
  String get hanokStageNamePillars;

  /// No description provided for @hanokStageNameBeams.
  ///
  /// In de, this message translates to:
  /// **'Balken'**
  String get hanokStageNameBeams;

  /// No description provided for @hanokStageNameThatchRoof.
  ///
  /// In de, this message translates to:
  /// **'Strohdach'**
  String get hanokStageNameThatchRoof;

  /// No description provided for @hanokStageNameTileRoofPartial.
  ///
  /// In de, this message translates to:
  /// **'Erste Ziegel'**
  String get hanokStageNameTileRoofPartial;

  /// No description provided for @hanokStageNameTileRoofComplete.
  ///
  /// In de, this message translates to:
  /// **'Ziegeldach'**
  String get hanokStageNameTileRoofComplete;

  /// No description provided for @hanokStageNameDancheong.
  ///
  /// In de, this message translates to:
  /// **'Dancheong'**
  String get hanokStageNameDancheong;

  /// No description provided for @hanokStageNameGate.
  ///
  /// In de, this message translates to:
  /// **'Tor'**
  String get hanokStageNameGate;

  /// No description provided for @hanokStageNameWindows.
  ///
  /// In de, this message translates to:
  /// **'Fenster'**
  String get hanokStageNameWindows;

  /// No description provided for @hanokStageNameSideBuilding.
  ///
  /// In de, this message translates to:
  /// **'Sarangchae'**
  String get hanokStageNameSideBuilding;

  /// No description provided for @hanokStageNameJongga.
  ///
  /// In de, this message translates to:
  /// **'Jongga-Haus'**
  String get hanokStageNameJongga;

  /// No description provided for @soriStageBojagiTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein Bojagi wartet'**
  String get soriStageBojagiTitle;

  /// No description provided for @soriStageBojagiBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle eines von drei Stücken für dein Zimmer.'**
  String get soriStageBojagiBody;

  /// No description provided for @soriStageOpenBojagi.
  ///
  /// In de, this message translates to:
  /// **'Bojagi öffnen'**
  String get soriStageOpenBojagi;

  /// No description provided for @soriStageHanokNow.
  ///
  /// In de, this message translates to:
  /// **'Deine Hanok jetzt'**
  String get soriStageHanokNow;

  /// No description provided for @soriStageNextPiece.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Bauteil'**
  String get soriStageNextPiece;

  /// No description provided for @soriStageClosestQuests.
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft'**
  String get soriStageClosestQuests;

  /// No description provided for @soriStageLearnTitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle, wie du lernen möchtest.'**
  String get soriStageLearnTitle;

  /// No description provided for @soriStageLearnBody.
  ///
  /// In de, this message translates to:
  /// **'Jede Aktivität bleibt mit deinen Quests und deiner Hanok verbunden.'**
  String get soriStageLearnBody;

  /// No description provided for @soriStageGamesTitle.
  ///
  /// In de, this message translates to:
  /// **'Spiele mit einem klaren Ziel.'**
  String get soriStageGamesTitle;

  /// No description provided for @soriStageGamesBody.
  ///
  /// In de, this message translates to:
  /// **'Sieh XP, Bestleistung und passende Quest, bevor du startest.'**
  String get soriStageGamesBody;

  /// No description provided for @soriStageMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String soriStageMinutes(int minutes);

  /// No description provided for @soriStagePossibleReward.
  ///
  /// In de, this message translates to:
  /// **'Mögliche Belohnung'**
  String get soriStagePossibleReward;

  /// No description provided for @soriStageOpenActivity.
  ///
  /// In de, this message translates to:
  /// **'{activity} öffnen'**
  String soriStageOpenActivity(String activity);

  /// No description provided for @soriStageActivityDetails.
  ///
  /// In de, this message translates to:
  /// **'Details zu {activity}'**
  String soriStageActivityDetails(String activity);

  /// No description provided for @soriStageHanokTitle.
  ///
  /// In de, this message translates to:
  /// **'Baue ein Zuhause aus dem, was du kannst.'**
  String get soriStageHanokTitle;

  /// No description provided for @soriStageHanokBody.
  ///
  /// In de, this message translates to:
  /// **'Sieben dauerhafte Stufen zeigen genau, was gebaut ist und was als Nächstes öffnet.'**
  String get soriStageHanokBody;

  /// No description provided for @soriStageOpenMap.
  ///
  /// In de, this message translates to:
  /// **'Hanok-Karte öffnen'**
  String get soriStageOpenMap;

  /// No description provided for @soriStageQuests.
  ///
  /// In de, this message translates to:
  /// **'Quests'**
  String get soriStageQuests;

  /// No description provided for @soriStageDojang.
  ///
  /// In de, this message translates to:
  /// **'Dojang-Heft'**
  String get soriStageDojang;

  /// No description provided for @soriStageBojagi.
  ///
  /// In de, this message translates to:
  /// **'Bojagi'**
  String get soriStageBojagi;

  /// No description provided for @soriStageRooms.
  ///
  /// In de, this message translates to:
  /// **'Räume und Einrichtung'**
  String get soriStageRooms;

  /// No description provided for @soriStageGyePromise.
  ///
  /// In de, this message translates to:
  /// **'Versprechen dieser Woche'**
  String get soriStageGyePromise;

  /// No description provided for @soriStageGyeFlow.
  ///
  /// In de, this message translates to:
  /// **'Mission abschließen → Laterne → gemeinsame Hanok'**
  String get soriStageGyeFlow;

  /// No description provided for @pronunciationTitle.
  ///
  /// In de, this message translates to:
  /// **'Aussprache-Studio'**
  String get pronunciationTitle;

  /// No description provided for @pronunciationEyebrow.
  ///
  /// In de, this message translates to:
  /// **'MIT DEM TIGER SPRECHEN'**
  String get pronunciationEyebrow;

  /// No description provided for @pronunciationIntro.
  ///
  /// In de, this message translates to:
  /// **'Höre zuerst zu. Nimm danach freiwillig bis zu 10 Sekunden für eine Bewertung auf.'**
  String get pronunciationIntro;

  /// No description provided for @pronunciationPhrasesLoading.
  ///
  /// In de, this message translates to:
  /// **'Ausspracheübungen werden geladen …'**
  String get pronunciationPhrasesLoading;

  /// No description provided for @pronunciationPhrasesUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausspracheübungen nicht verfügbar'**
  String get pronunciationPhrasesUnavailableTitle;

  /// No description provided for @pronunciationPhrasesUnavailableBody.
  ///
  /// In de, this message translates to:
  /// **'Die Ausspracheübungen konnten nicht geladen werden. Bitte versuche es noch einmal.'**
  String get pronunciationPhrasesUnavailableBody;

  /// No description provided for @pronunciationPhrasesEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausspracheübungen'**
  String get pronunciationPhrasesEmptyTitle;

  /// No description provided for @pronunciationPhrasesEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für deinen Lernstand sind gerade keine geprüften Sätze verfügbar.'**
  String get pronunciationPhrasesEmptyBody;

  /// No description provided for @pronunciationListen.
  ///
  /// In de, this message translates to:
  /// **'Anhören'**
  String get pronunciationListen;

  /// No description provided for @pronunciationRecord.
  ///
  /// In de, this message translates to:
  /// **'Meine Stimme aufnehmen'**
  String get pronunciationRecord;

  /// No description provided for @pronunciationRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme läuft…'**
  String get pronunciationRecording;

  /// No description provided for @pronunciationAssessing.
  ///
  /// In de, this message translates to:
  /// **'Bewertung wird erstellt…'**
  String get pronunciationAssessing;

  /// No description provided for @pronunciationStop.
  ///
  /// In de, this message translates to:
  /// **'Stoppen und bewerten'**
  String get pronunciationStop;

  /// No description provided for @pronunciationContinueWithoutScore.
  ///
  /// In de, this message translates to:
  /// **'Ohne Bewertung weiter'**
  String get pronunciationContinueWithoutScore;

  /// No description provided for @pronunciationNextPhrase.
  ///
  /// In de, this message translates to:
  /// **'Nächster Satz'**
  String get pronunciationNextPhrase;

  /// No description provided for @pronunciationConsentTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Stimme bewerten lassen?'**
  String get pronunciationConsentTitle;

  /// No description provided for @pronunciationConsentBody.
  ///
  /// In de, this message translates to:
  /// **'Mit deiner gesonderten Einwilligung werden eine Aufnahme von höchstens 10 Sekunden und der angezeigte koreanische Satz sicher an Microsoft Azure Speech in der Region Deutschland West-Mitte gesendet. Hangul Sori speichert weder Aufnahme noch Satz auf seinem Server. Nur die Bewertungen und eine ID gegen Doppelzählung werden auf diesem Gerät gespeichert. Du kannst ohne Bewertung üben und die Einwilligung in den Einstellungen widerrufen.'**
  String get pronunciationConsentBody;

  /// No description provided for @pronunciationConsentAccept.
  ///
  /// In de, this message translates to:
  /// **'Ich stimme zu und möchte eine Bewertung'**
  String get pronunciationConsentAccept;

  /// No description provided for @pronunciationConsentDecline.
  ///
  /// In de, this message translates to:
  /// **'Ohne Bewertung üben'**
  String get pronunciationConsentDecline;

  /// No description provided for @pronunciationPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Der Mikrofonzugriff wurde nicht erlaubt. Anhören und Nachsprechen bleiben verfügbar.'**
  String get pronunciationPermissionDenied;

  /// No description provided for @pronunciationAssessmentUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Bewertung ist gerade nicht verfügbar. Deine normale Übung bleibt möglich.'**
  String get pronunciationAssessmentUnavailable;

  /// No description provided for @pronunciationRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Du hast das Bewertungslimit erreicht. Übe weiter und versuche es später erneut.'**
  String get pronunciationRateLimited;

  /// No description provided for @pronunciationScore.
  ///
  /// In de, this message translates to:
  /// **'Aussprachebewertung'**
  String get pronunciationScore;

  /// No description provided for @pronunciationScorePassed.
  ///
  /// In de, this message translates to:
  /// **'Bestanden. Diese Bewertung zählt einmal für deine Aussprache-Quest.'**
  String get pronunciationScorePassed;

  /// No description provided for @pronunciationScoreTryAgain.
  ///
  /// In de, this message translates to:
  /// **'Gute Übung. Erreiche beim nächsten Mal mindestens 80, um die Quest fortzusetzen.'**
  String get pronunciationScoreTryAgain;

  /// No description provided for @pronunciationAccuracy.
  ///
  /// In de, this message translates to:
  /// **'Genauigkeit'**
  String get pronunciationAccuracy;

  /// No description provided for @pronunciationFluency.
  ///
  /// In de, this message translates to:
  /// **'Sprechfluss'**
  String get pronunciationFluency;

  /// No description provided for @pronunciationCompleteness.
  ///
  /// In de, this message translates to:
  /// **'Vollständigkeit'**
  String get pronunciationCompleteness;

  /// No description provided for @settingsPronunciationConsentTitle.
  ///
  /// In de, this message translates to:
  /// **'Einwilligung zur Sprachbewertung'**
  String get settingsPronunciationConsentTitle;

  /// No description provided for @settingsPronunciationConsentDesc.
  ///
  /// In de, this message translates to:
  /// **'Erlaube freiwillige Aufnahmen von höchstens 10 Sekunden zur Bewertung durch Azure Speech in Deutschland West-Mitte. Ausschalten verhindert weitere Bewertungen.'**
  String get settingsPronunciationConsentDesc;

  /// No description provided for @settingsPronunciationConsentOff.
  ///
  /// In de, this message translates to:
  /// **'Sprachbewertung ist aus. Anhören und Nachsprechen bleiben verfügbar.'**
  String get settingsPronunciationConsentOff;

  /// No description provided for @soriStageReceiptEyebrow.
  ///
  /// In de, this message translates to:
  /// **'GERADE VERÄNDERT'**
  String get soriStageReceiptEyebrow;

  /// No description provided for @soriStageReceiptTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernen hat den Weg weitergebracht.'**
  String get soriStageReceiptTitle;

  /// No description provided for @soriStageReceiptSemantics.
  ///
  /// In de, this message translates to:
  /// **'Erhaltene Belohnungen'**
  String get soriStageReceiptSemantics;

  /// No description provided for @soriStageReceiptContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get soriStageReceiptContinue;

  /// No description provided for @soriStageActivityReady.
  ///
  /// In de, this message translates to:
  /// **'Jetzt verfügbar'**
  String get soriStageActivityReady;

  /// No description provided for @soriStageBrandLabel.
  ///
  /// In de, this message translates to:
  /// **'SORI STAGE'**
  String get soriStageBrandLabel;

  /// No description provided for @soriStageActivityInProgress.
  ///
  /// In de, this message translates to:
  /// **'In Arbeit'**
  String get soriStageActivityInProgress;

  /// No description provided for @soriStageActivityCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get soriStageActivityCompleted;

  /// No description provided for @soriStageActivityTitle.
  ///
  /// In de, this message translates to:
  /// **'{activityId, select, course{Kurs} hangul{Hangul} calligraphy{Buchstabe des Tages} pronunciation{Aussprache} vocab_packs{Wortpakete} srs{Wiederholen} hard_words{Schwierige Wörter} word_web{Nuancen & Gegenteile} grammar{Grammatik} listening{Hören} scenarios{Alltagsszenen} smalltalk{Small Talk} book_capture{Buch fotografieren} vocab_notebook{Vokabelheft} bookshelf{Bücherregal} word_search{Wortsuche} daily_game{Tageschallenge} chosung{Anlaut-Quiz} syllable_cross{Silben-Rätsel} cloze{Lückentext} speed_match{Blitz-Paare} sentence_arcade{Satz-Arcade} kkeunmari{Kkeunmari} custom_quiz{Eigenes Quiz} custom_matching{Eigenes Matching} custom_typing{Eigenes Tippen} other{Lernaktivität}}}'**
  String soriStageActivityTitle(String activityId);

  /// No description provided for @soriStageActivityDescription.
  ///
  /// In de, this message translates to:
  /// **'{activityId, select, course{Dein geführter Weg durch echte Situationen.} hangul{Silben bauen und sicher lesen.} calligraphy{Jeden Tag ein Schriftzeichen entdecken.} pronunciation{Hören, nachsprechen und auf Wunsch bewerten.} vocab_packs{Wörter nach Alltagsthema lernen.} srs{Wörter genau im richtigen Moment auffrischen.} hard_words{Gezielt an deinen Stolperwörtern arbeiten.} word_web{Synonyme, Gegenteile und Wendungen zu deinen Wörtern.} grammar{Muster verstehen und direkt anwenden.} listening{Kurze natürliche Sätze sicher erkennen.} scenarios{Café, Verkehr und Gespräche üben.} smalltalk{Kurze Gespräche flüssig verbinden.} book_capture{Wörter aus deinem Material übernehmen.} vocab_notebook{Dein Heft fotografieren und genau diese Wörter üben.} bookshelf{Eigene Seiten und Wortlisten verwalten.} word_search{Ein Wort und seine Lernwege finden.} daily_game{Ein kurzer Mix für heute.} chosung{Wörter an ihren Anfangslauten erkennen.} syllable_cross{Silben kombinieren und Wörter finden.} cloze{Das passende Wort im Satz abrufen.} speed_match{Bedeutungen schnell und sicher verbinden.} sentence_arcade{Sätze unter Zeitdruck richtig bauen.} kkeunmari{Eine Wortkette gegen den Tiger spielen.} custom_quiz{Ein Wortpaket im Bücherregal auswählen.} custom_matching{Deine Wörter als Paare festigen.} custom_typing{Deine Wörter aktiv aus dem Gedächtnis holen.} other{Weiterlernen.}}}'**
  String soriStageActivityDescription(String activityId);

  /// No description provided for @soriStageCatalogCopy.
  ///
  /// In de, this message translates to:
  /// **'{copyKey, select, firstCompletion{Beim ersten Abschluss} finishSession{Wenn du die Runde abschließt} verifiedLearning{Nach einem bestätigten Lernerfolg} rewardXp{Lern-XP} rewardQuest{Passende Quest} rewardHanok{Verifizierter Hanok-Baufortschritt} rewardStamp{Dojang-Stempel} rewardBest{Persönliche Bestleistung} rewardNone{Keine direkte Belohnung} rewardQuestProgress{Quest-Fortschritt} rewardHanokPiece{Neues Hanok-Bauteil} rewardBojagi{Bojagi} rewardGyeLantern{Gye-Laterne} other{Belohnung}}}'**
  String soriStageCatalogCopy(String copyKey);

  /// No description provided for @questActionLabel.
  ///
  /// In de, this message translates to:
  /// **'{actionKey, select, openQuests{Quests öffnen} openVocabulary{Wortpakete öffnen} openScenarios{Alltagsszenen öffnen} practicePronunciation{Aussprache üben} playKkeunmari{Kkeunmari spielen} openHangul{Hangul öffnen} openCalligraphy{Buchstabe des Tages öffnen} openToday{Heutige Mission öffnen} openGye{Gye öffnen} playChosung{Anlaut-Quiz spielen} other{Öffnen}}}'**
  String questActionLabel(String actionKey);

  /// No description provided for @questSeasonOpens.
  ///
  /// In de, this message translates to:
  /// **'Öffnet am {date}'**
  String questSeasonOpens(String date);

  /// No description provided for @soriStagePreviewCopy.
  ///
  /// In de, this message translates to:
  /// **'{copyKey, select, todayEyebrow{HEUTE} todayTitle{Ein Satz. Ein Bauteil.} nearComplete{Fast geschafft} cafeOrder{Im Café bestellen} strongWords{Starke Alltagswörter} sevenDayStreak{Sieben Tage dranbleiben} lessonEyebrow{LEKTION 2 VON 4} lessonPhrase{덜 맵게 해 주세요} listen{Hören} naturalTempo{Natürliches Tempo} speak{Sprechen} rhythmMouth{Rhythmus und Mundbild} remember{Erinnern} withoutHelp{Ohne Hilfe abrufen} beginListening{Mit Hören beginnen} receiptEyebrow{GERADE VERÄNDERT} receiptTitle{Dein Satz trägt jetzt das Dach.} beamStage{DAECHEONG · BALKEN 3} newBeam{1 neuer Balken im Bauplan} xpEarned{Lern-XP +12} completedMission{für die abgeschlossene Mission} questEarned{Quest-Fortschritt +1} scenarioProgress{Alltagsszenen · 4 von 10} hanokEarned{Hanok-Bauteil +1} verifiedSpeaking{durch bestätigtes Sprechen} continueToday{Weiter zu Heute} journeyEyebrow{DEIN WEG} journeyTitle{Alles Lernen baut am selben Ort.} missionEyebrow{WENIGER SCHARF BESTELLEN} missionTitle{Hören. Sprechen. Im Alltag anwenden.} missionReward{Abschließen → Lern-XP + verifizierter Fortschritt} missionStart{Mission starten} bojagiWaiting{1 Bojagi wartet} bojagiBody{Wähle eines von drei Stücken für dein Zimmer.} other{Sori-Stage-Vorschau}}'**
  String soriStagePreviewCopy(String copyKey);

  /// No description provided for @soriStagePreviewProgress.
  ///
  /// In de, this message translates to:
  /// **'{current} von {target}'**
  String soriStagePreviewProgress(int current, int target);

  /// No description provided for @soriStageActivityStart.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get soriStageActivityStart;

  /// No description provided for @soriStageActivityLocked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get soriStageActivityLocked;

  /// No description provided for @culturalHelpSemantics.
  ///
  /// In de, this message translates to:
  /// **'Mehr über {term} erfahren'**
  String culturalHelpSemantics(String term);

  /// No description provided for @culturalMeaningLabel.
  ///
  /// In de, this message translates to:
  /// **'Was ist das?'**
  String get culturalMeaningLabel;

  /// No description provided for @culturalStoryLabel.
  ///
  /// In de, this message translates to:
  /// **'Warum war das wichtig?'**
  String get culturalStoryLabel;

  /// No description provided for @culturalClose.
  ///
  /// In de, this message translates to:
  /// **'Kulturgeschichte schließen'**
  String get culturalClose;

  /// No description provided for @culturalObjectHint.
  ///
  /// In de, this message translates to:
  /// **'Neugierig? Tippe auf einen Gegenstand.'**
  String get culturalObjectHint;

  /// No description provided for @culturalObjectHintDismiss.
  ///
  /// In de, this message translates to:
  /// **'Hinweis schließen'**
  String get culturalObjectHintDismiss;

  /// No description provided for @vocabNotebookTitle.
  ///
  /// In de, this message translates to:
  /// **'Vokabelheft'**
  String get vocabNotebookTitle;

  /// No description provided for @vocabNotebookDesc.
  ///
  /// In de, this message translates to:
  /// **'Dein Heft fotografieren und genau diese Wörter üben.'**
  String get vocabNotebookDesc;

  /// No description provided for @vocabNotebookPreviewCta.
  ///
  /// In de, this message translates to:
  /// **'Diese Wörter übernehmen'**
  String get vocabNotebookPreviewCta;

  /// No description provided for @vocabNotebookResultHint.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort aus deinem Heft. Genau diese Wörter übst du danach.} other{{count} Wörter aus deinem Heft. Genau diese Wörter übst du danach.}}'**
  String vocabNotebookResultHint(int count);

  /// No description provided for @vocabNotebookDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Mein Vokabelheft'**
  String get vocabNotebookDefaultName;

  /// No description provided for @vocabNotebookEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Wortpaare gefunden'**
  String get vocabNotebookEmptyTitle;

  /// No description provided for @vocabNotebookEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Schreib Koreanisch und die Bedeutung in eine Zeile, zum Beispiel: 학교 - Schule. Dann übernimm genau diese Wörter.'**
  String get vocabNotebookEmptyBody;

  /// No description provided for @vocabNotebookPracticeCta.
  ///
  /// In de, this message translates to:
  /// **'Genau diese Wörter üben'**
  String get vocabNotebookPracticeCta;

  /// No description provided for @vocabNotebookPracticeHint.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Wort aus deinem Heft. Spiele damit, statt neue Vokabeln zu bekommen.} other{{count} Wörter aus deinem Heft. Spiele damit, statt neue Vokabeln zu bekommen.}}'**
  String vocabNotebookPracticeHint(int count);

  /// No description provided for @vocabNotebookAddPhoto.
  ///
  /// In de, this message translates to:
  /// **'Weitere Seite fotografieren'**
  String get vocabNotebookAddPhoto;

  /// No description provided for @vocabNotebookDropWord.
  ///
  /// In de, this message translates to:
  /// **'Wort weglassen'**
  String get vocabNotebookDropWord;

  /// No description provided for @vocabNotebookKeepWord.
  ///
  /// In de, this message translates to:
  /// **'Wort behalten'**
  String get vocabNotebookKeepWord;

  /// No description provided for @vocabNotebookNuanceCta.
  ///
  /// In de, this message translates to:
  /// **'Hanja und Nuancen'**
  String get vocabNotebookNuanceCta;

  /// No description provided for @vocabNotebookNuanceTitle.
  ///
  /// In de, this message translates to:
  /// **'Ähnlich, aber nicht gleich'**
  String get vocabNotebookNuanceTitle;

  /// No description provided for @vocabNotebookNuanceEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Vergleich'**
  String get vocabNotebookNuanceEmptyTitle;

  /// No description provided for @vocabNotebookNuanceEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere oder importiere Wörter, die nah beieinanderliegen. Hanja zeigt dann die andere Nuance oder die förmlichere Stufe.'**
  String get vocabNotebookNuanceEmptyBody;

  /// No description provided for @vocabNotebookSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Wörter konnten nicht gespeichert werden. Versuch es noch einmal.'**
  String get vocabNotebookSaveFailed;

  /// No description provided for @vocabNotebookNoHanja.
  ///
  /// In de, this message translates to:
  /// **'kein Hanja'**
  String get vocabNotebookNoHanja;

  /// No description provided for @vocabNotebookStudioCta.
  ///
  /// In de, this message translates to:
  /// **'Spiel aus diesen Wörtern bauen'**
  String get vocabNotebookStudioCta;

  /// No description provided for @vocabNotebookStudioTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Wortspiel'**
  String get vocabNotebookStudioTitle;

  /// No description provided for @vocabNotebookStudioHint.
  ///
  /// In de, this message translates to:
  /// **'Wähl die Wörter aus deinem Heft. Danach spielst du nur mit denen, und mit Sätzen, Dialogen und Nuancen-Übungen, die wir dafür schon haben.'**
  String get vocabNotebookStudioHint;

  /// No description provided for @vocabNotebookStudioSelectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle nehmen'**
  String get vocabNotebookStudioSelectAll;

  /// No description provided for @vocabNotebookStudioSelectNone.
  ///
  /// In de, this message translates to:
  /// **'Keine'**
  String get vocabNotebookStudioSelectNone;

  /// No description provided for @vocabNotebookStudioOwnGames.
  ///
  /// In de, this message translates to:
  /// **'Mit deinen Bedeutungen'**
  String get vocabNotebookStudioOwnGames;

  /// No description provided for @vocabNotebookStudioCorpusGames.
  ///
  /// In de, this message translates to:
  /// **'Mit unseren Sätzen'**
  String get vocabNotebookStudioCorpusGames;

  /// No description provided for @vocabNotebookStudioCorpusHint.
  ///
  /// In de, this message translates to:
  /// **'Nur vorhandene Sätze, Dialoge und Nuancen-Übungen. Es kommen keine neuen Wörter dazu.'**
  String get vocabNotebookStudioCorpusHint;

  /// No description provided for @vocabNotebookStudioLoading.
  ///
  /// In de, this message translates to:
  /// **'Vorhandene Spiele laden …'**
  String get vocabNotebookStudioLoading;

  /// No description provided for @vocabNotebookStudioCloze.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Lückentext · 1 Satz} other{Lückentext · {count} Sätze}}'**
  String vocabNotebookStudioCloze(int count);

  /// No description provided for @vocabNotebookStudioSatz.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Satz bauen · 1 Satz} other{Satz bauen · {count} Sätze}}'**
  String vocabNotebookStudioSatz(int count);

  /// No description provided for @vocabNotebookStudioSpeed.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Blitz-Paare · 1 Wort} other{Blitz-Paare · {count} Wörter}}'**
  String vocabNotebookStudioSpeed(int count);

  /// No description provided for @vocabNotebookStudioChosung.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Anlaut-Quiz · 1 Wort} other{Anlaut-Quiz · {count} Wörter}}'**
  String vocabNotebookStudioChosung(int count);

  /// No description provided for @vocabNotebookStudioNoCorpus.
  ///
  /// In de, this message translates to:
  /// **'Für diese Wörter haben wir noch keinen fertigen Satz. Spiel oben mit deinen eigenen Bedeutungen.'**
  String get vocabNotebookStudioNoCorpus;

  /// No description provided for @vocabNotebookStudioLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Einige unserer Sätze konnten nicht geladen werden. Verbindung prüfen und noch einmal versuchen.'**
  String get vocabNotebookStudioLoadFailed;

  /// No description provided for @vocabNotebookStudioSmalltalk.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Smalltalk · 1 Satz} other{Smalltalk · {count} Sätze}}'**
  String vocabNotebookStudioSmalltalk(int count);

  /// No description provided for @vocabNotebookStudioPronunciation.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Aussprache · 1 Satz} other{Aussprache · {count} Sätze}}'**
  String vocabNotebookStudioPronunciation(int count);

  /// No description provided for @vocabNotebookStudioScenarios.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Szenario · 1 Szene} other{Szenario · {count} Szenen}}'**
  String vocabNotebookStudioScenarios(int count);

  /// No description provided for @vocabNotebookStudioWordWeb.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{Nuancen & Gegenteile · 1 Wort} other{Nuancen & Gegenteile · {count} Wörter}}'**
  String vocabNotebookStudioWordWeb(int count);

  /// No description provided for @ttsUnavailableChannelOff.
  ///
  /// In de, this message translates to:
  /// **'Aussprache ist stumm geschaltet. Einstellungen → Ton'**
  String get ttsUnavailableChannelOff;

  /// No description provided for @ttsUnavailableQuota.
  ///
  /// In de, this message translates to:
  /// **'Heutiges Sprachlimit erreicht. Morgen geht es weiter.'**
  String get ttsUnavailableQuota;

  /// No description provided for @ttsUnavailablePending.
  ///
  /// In de, this message translates to:
  /// **'Die Stimme wird gerade erzeugt. Gleich nochmal antippen.'**
  String get ttsUnavailablePending;

  /// No description provided for @ttsUnavailableOffline.
  ///
  /// In de, this message translates to:
  /// **'Aussprache nicht verfügbar. Bist du online?'**
  String get ttsUnavailableOffline;

  /// No description provided for @mediaPhraseTitle.
  ///
  /// In de, this message translates to:
  /// **'Medien-Sätze'**
  String get mediaPhraseTitle;

  /// No description provided for @mediaPhraseDesc.
  ///
  /// In de, this message translates to:
  /// **'Übe Originalzeilen aus Interview-, Podcast-, Doku- und Debattenregistern auf deinem Niveau.'**
  String get mediaPhraseDesc;

  /// No description provided for @mediaPhraseContext.
  ///
  /// In de, this message translates to:
  /// **'Situation'**
  String get mediaPhraseContext;

  /// No description provided for @mediaPhraseLoading.
  ///
  /// In de, this message translates to:
  /// **'Medien-Sätze werden geladen …'**
  String get mediaPhraseLoading;

  /// No description provided for @mediaPhraseUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Medien-Sätze konnten nicht geladen werden. Bitte versuche es erneut.'**
  String get mediaPhraseUnavailable;

  /// No description provided for @mediaPhraseEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Satz für dieses Niveau'**
  String get mediaPhraseEmptyTitle;

  /// No description provided for @mediaPhraseEmpty.
  ///
  /// In de, this message translates to:
  /// **'Für dein Niveau sind gerade keine Medien-Sätze verfügbar.'**
  String get mediaPhraseEmpty;

  /// No description provided for @mediaPhraseProgress.
  ///
  /// In de, this message translates to:
  /// **'{current} von {total}'**
  String mediaPhraseProgress(int current, int total);

  /// No description provided for @mediaPhraseListenTarget.
  ///
  /// In de, this message translates to:
  /// **'{phrase} anhören'**
  String mediaPhraseListenTarget(String phrase);

  /// No description provided for @mediaPhrasePrevious.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get mediaPhrasePrevious;

  /// No description provided for @mediaPhraseNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get mediaPhraseNext;

  /// No description provided for @onboardingV2Back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get onboardingV2Back;

  /// No description provided for @onboardingV2Next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get onboardingV2Next;

  /// No description provided for @onboardingV2Loading.
  ///
  /// In de, this message translates to:
  /// **'Deine Anleitung wird vorbereitet …'**
  String get onboardingV2Loading;

  /// No description provided for @onboardingV2Saving.
  ///
  /// In de, this message translates to:
  /// **'Deine Auswahl wird gespeichert …'**
  String get onboardingV2Saving;

  /// No description provided for @onboardingV2CourseHistoryConflict.
  ///
  /// In de, this message translates to:
  /// **'Zu diesem Kursstart gibt es bereits Lernfortschritt. Behalte zum Abschließen der Einrichtung die aktuelle Stufe; später kannst du den Kurs in den Einstellungen ausdrücklich neu starten.'**
  String get onboardingV2CourseHistoryConflict;

  /// No description provided for @onboardingV2StoryFinish.
  ///
  /// In de, this message translates to:
  /// **'Meinen Start auswählen'**
  String get onboardingV2StoryFinish;

  /// No description provided for @onboardingV2StoryProgress.
  ///
  /// In de, this message translates to:
  /// **'Seite {current} von {total}'**
  String onboardingV2StoryProgress(int current, int total);

  /// No description provided for @onboardingV2Story1Eyebrow.
  ///
  /// In de, this message translates to:
  /// **'Zwei Wege, ein Lernort'**
  String get onboardingV2Story1Eyebrow;

  /// No description provided for @onboardingV2Story1Title.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernweg und dein eigenes Buch'**
  String get onboardingV2Story1Title;

  /// No description provided for @onboardingV2Story1Body.
  ///
  /// In de, this message translates to:
  /// **'Gehe Schritt für Schritt von A1 bis C2. Die Texterkennung einer fotografierten Buchseite läuft auf deinem Gerät. Erst wenn du Analysieren wählst, kann der erkannte Text zur Auswertung an einen Analysedienst in der EU gesendet werden.'**
  String get onboardingV2Story1Body;

  /// No description provided for @onboardingV2Story1HeroSemantics.
  ///
  /// In de, this message translates to:
  /// **'Vorschau auf den Stufenweg A1 bis C2 und die Analyse einer selbst fotografierten Buchseite.'**
  String get onboardingV2Story1HeroSemantics;

  /// No description provided for @onboardingV2Story1Item1Title.
  ///
  /// In de, this message translates to:
  /// **'Stufenweg A1 bis C2'**
  String get onboardingV2Story1Item1Title;

  /// No description provided for @onboardingV2Story1Item1Body.
  ///
  /// In de, this message translates to:
  /// **'Lernziele und Alltagsszenen bauen aufeinander auf.'**
  String get onboardingV2Story1Item1Body;

  /// No description provided for @onboardingV2Story1Item2Title.
  ///
  /// In de, this message translates to:
  /// **'Dein Buch fotografieren'**
  String get onboardingV2Story1Item2Title;

  /// No description provided for @onboardingV2Story1Item2Body.
  ///
  /// In de, this message translates to:
  /// **'Eine Seite wird erst erfasst, wenn du die Kamera selbst öffnest.'**
  String get onboardingV2Story1Item2Body;

  /// No description provided for @onboardingV2Story1Item3Title.
  ///
  /// In de, this message translates to:
  /// **'Text auf dem Gerät erkennen'**
  String get onboardingV2Story1Item3Title;

  /// No description provided for @onboardingV2Story1Item3Body.
  ///
  /// In de, this message translates to:
  /// **'Die Texterkennung der Aufnahme läuft auf deinem Gerät. Diese Anleitung fragt nicht nach Kamerazugriff.'**
  String get onboardingV2Story1Item3Body;

  /// No description provided for @onboardingV2Story1Item4Title.
  ///
  /// In de, this message translates to:
  /// **'Ergebnisse nach Typ'**
  String get onboardingV2Story1Item4Title;

  /// No description provided for @onboardingV2Story1Item4Body.
  ///
  /// In de, this message translates to:
  /// **'Wählst du Analysieren, kann der erkannte Text an einen Analysedienst in der EU gesendet und nach Wörtern, Ausdrücken, Grammatik und Sätzen aufbereitet werden.'**
  String get onboardingV2Story1Item4Body;

  /// No description provided for @onboardingV2Story1CurriculumClaim.
  ///
  /// In de, this message translates to:
  /// **'Ein stufenweises Curriculum, das sich an den CEFR-Handlungszielen und am Koreanischen Standardcurriculum des National Institute of Korean Language orientiert.'**
  String get onboardingV2Story1CurriculumClaim;

  /// No description provided for @onboardingV2Story1CurriculumSourcesAction.
  ///
  /// In de, this message translates to:
  /// **'Curriculum-Grundlage und Quellen'**
  String get onboardingV2Story1CurriculumSourcesAction;

  /// No description provided for @onboardingV2Story1CurriculumSourcesTitle.
  ///
  /// In de, this message translates to:
  /// **'Grundlage des Stufencurriculums'**
  String get onboardingV2Story1CurriculumSourcesTitle;

  /// No description provided for @onboardingV2Story1CurriculumSourcesBody.
  ///
  /// In de, this message translates to:
  /// **'Die aktuelle Zuordnung ist teilweise. Diese offiziellen Quellen dienen als Orientierung für den Lernweg; sie behaupten weder eine Zertifizierung noch eine vollständige Prüfungsabdeckung.'**
  String get onboardingV2Story1CurriculumSourcesBody;

  /// No description provided for @onboardingV2Story1CurriculumCefrAuthority.
  ///
  /// In de, this message translates to:
  /// **'Europarat · CEFR'**
  String get onboardingV2Story1CurriculumCefrAuthority;

  /// No description provided for @onboardingV2Story1CurriculumNiklAuthority.
  ///
  /// In de, this message translates to:
  /// **'National Institute of Korean Language'**
  String get onboardingV2Story1CurriculumNiklAuthority;

  /// No description provided for @onboardingV2Story1CurriculumDocument.
  ///
  /// In de, this message translates to:
  /// **'Offizielles Dokument'**
  String get onboardingV2Story1CurriculumDocument;

  /// No description provided for @onboardingV2Story1CurriculumVersion.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get onboardingV2Story1CurriculumVersion;

  /// No description provided for @onboardingV2Story1CurriculumCheckedAt.
  ///
  /// In de, this message translates to:
  /// **'Quelle geprüft am'**
  String get onboardingV2Story1CurriculumCheckedAt;

  /// No description provided for @onboardingV2Story1CurriculumUrl.
  ///
  /// In de, this message translates to:
  /// **'URL'**
  String get onboardingV2Story1CurriculumUrl;

  /// Barrierefreie Beschriftung zum Öffnen einer offiziellen Curriculum-Quelle.
  ///
  /// In de, this message translates to:
  /// **'Quelle öffnen: {sourceTitle}'**
  String onboardingV2Story1CurriculumOpenSource(String sourceTitle);

  /// No description provided for @onboardingV2Story1CurriculumSourcesClose.
  ///
  /// In de, this message translates to:
  /// **'Quellen schließen'**
  String get onboardingV2Story1CurriculumSourcesClose;

  /// No description provided for @onboardingV2Story2Eyebrow.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get onboardingV2Story2Eyebrow;

  /// No description provided for @onboardingV2Story2Title.
  ///
  /// In de, this message translates to:
  /// **'Vom ersten Zeichen bis zum Gespräch'**
  String get onboardingV2Story2Title;

  /// No description provided for @onboardingV2Story2Body.
  ///
  /// In de, this message translates to:
  /// **'Lernen verbindet Hangeul, Schreiben, Hören, Aussprache und Szenarien. Du entscheidest selbst, wann du Kamera, Mikrofon oder Ton verwendest.'**
  String get onboardingV2Story2Body;

  /// No description provided for @onboardingV2Story2HeroSemantics.
  ///
  /// In de, this message translates to:
  /// **'Vorschau auf Hangeul, Schreibübungen, Hör- und Aussprachetraining sowie Szenarien nach Level.'**
  String get onboardingV2Story2HeroSemantics;

  /// No description provided for @onboardingV2Story2Item1Title.
  ///
  /// In de, this message translates to:
  /// **'Hangeul'**
  String get onboardingV2Story2Item1Title;

  /// No description provided for @onboardingV2Story2Item1Body.
  ///
  /// In de, this message translates to:
  /// **'Konsonanten und Vokale erkennen und zusammensetzen.'**
  String get onboardingV2Story2Item1Body;

  /// No description provided for @onboardingV2Story2Item2Title.
  ///
  /// In de, this message translates to:
  /// **'Schreiben'**
  String get onboardingV2Story2Item2Title;

  /// No description provided for @onboardingV2Story2Item2Body.
  ///
  /// In de, this message translates to:
  /// **'Zeichen nachfahren und anschließend selbst schreiben.'**
  String get onboardingV2Story2Item2Body;

  /// No description provided for @onboardingV2Story2Item3Title.
  ///
  /// In de, this message translates to:
  /// **'Hören & Aussprache'**
  String get onboardingV2Story2Item3Title;

  /// No description provided for @onboardingV2Story2Item3Body.
  ///
  /// In de, this message translates to:
  /// **'Beispiele anhören und die eigene Aufnahme gezielt vergleichen.'**
  String get onboardingV2Story2Item3Body;

  /// No description provided for @onboardingV2Story2Item4Title.
  ///
  /// In de, this message translates to:
  /// **'Szenarien nach Level'**
  String get onboardingV2Story2Item4Title;

  /// No description provided for @onboardingV2Story2Item4Body.
  ///
  /// In de, this message translates to:
  /// **'Alltagssituationen und Kategorien passend zum gewählten Level öffnen.'**
  String get onboardingV2Story2Item4Body;

  /// No description provided for @onboardingV2Story3Eyebrow.
  ///
  /// In de, this message translates to:
  /// **'Karten und Gedächtnis'**
  String get onboardingV2Story3Eyebrow;

  /// No description provided for @onboardingV2Story3Title.
  ///
  /// In de, this message translates to:
  /// **'Merke dir, was dir wichtig ist'**
  String get onboardingV2Story3Title;

  /// No description provided for @onboardingV2Story3Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe Karten an, um sie zu wenden, und wische zur nächsten. Herz und Lesezeichen haben dabei bewusst verschiedene Aufgaben.'**
  String get onboardingV2Story3Body;

  /// No description provided for @onboardingV2Story3HeroSemantics.
  ///
  /// In de, this message translates to:
  /// **'Vorschau auf Kartensteuerung, Favoriten, gespeicherte Inhalte mit erhaltenem Inhaltstyp und die heutige Wiederholung unterstützter Wörter.'**
  String get onboardingV2Story3HeroSemantics;

  /// No description provided for @onboardingV2Story3Item1Title.
  ///
  /// In de, this message translates to:
  /// **'Karte wenden'**
  String get onboardingV2Story3Item1Title;

  /// No description provided for @onboardingV2Story3Item1Body.
  ///
  /// In de, this message translates to:
  /// **'Antippen zeigt die andere Kartenseite.'**
  String get onboardingV2Story3Item1Body;

  /// No description provided for @onboardingV2Story3Item2Title.
  ///
  /// In de, this message translates to:
  /// **'Weiterwischen'**
  String get onboardingV2Story3Item2Title;

  /// No description provided for @onboardingV2Story3Item2Body.
  ///
  /// In de, this message translates to:
  /// **'Eine Wischgeste bewegt dich durch den Stapel.'**
  String get onboardingV2Story3Item2Body;

  /// No description provided for @onboardingV2Story3Item3Title.
  ///
  /// In de, this message translates to:
  /// **'Herz = Favorit'**
  String get onboardingV2Story3Item3Title;

  /// No description provided for @onboardingV2Story3Item3Body.
  ///
  /// In de, this message translates to:
  /// **'Du merkst dir etwas ohne neue Wiederholungsaufgabe.'**
  String get onboardingV2Story3Item3Body;

  /// No description provided for @onboardingV2Story3Item4Title.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen = zum Lernen speichern'**
  String get onboardingV2Story3Item4Title;

  /// No description provided for @onboardingV2Story3Item4Body.
  ///
  /// In de, this message translates to:
  /// **'Auf unterstützten Wortkarten speichert das Lesezeichen das Wort in einem Wortpaket. Andere unterstützte gespeicherte Inhalte behalten in der Lernsammlung ihren echten Typ.'**
  String get onboardingV2Story3Item4Body;

  /// No description provided for @onboardingV2Story3Status.
  ///
  /// In de, this message translates to:
  /// **'Jetzt verfügbar: Favoriten, gespeicherte Inhalte und heute fällige unterstützte Wörter sind getrennte Ansichten in der Lernsammlung. Die aktuelle Wiederholung unterstützt nur Wörter; Grammatik, Sätze, Ausdrücke und Hangeul bleiben ohne vorgetäuschte Wiederholungsaktion gespeichert.'**
  String get onboardingV2Story3Status;

  /// No description provided for @onboardingV2Story4Eyebrow.
  ///
  /// In de, this message translates to:
  /// **'Spielen und Belohnungen'**
  String get onboardingV2Story4Eyebrow;

  /// No description provided for @onboardingV2Story4Title.
  ///
  /// In de, this message translates to:
  /// **'Üben, ausprobieren, Fortschritt sehen'**
  String get onboardingV2Story4Title;

  /// No description provided for @onboardingV2Story4Body.
  ///
  /// In de, this message translates to:
  /// **'In Spielen wendest du Gelerntes an. Hinweise, XP, persönliche Bestwerte und Quests machen sichtbar, was du getan hast. Sie ersetzen keinen Lernerfolg.'**
  String get onboardingV2Story4Body;

  /// No description provided for @onboardingV2Story4HeroSemantics.
  ///
  /// In de, this message translates to:
  /// **'Vorschau auf Spiele, Hinweise, XP, persönliche Bestwerte, Quests und mögliche Sammelbelohnungen.'**
  String get onboardingV2Story4HeroSemantics;

  /// No description provided for @onboardingV2Story4Status.
  ///
  /// In de, this message translates to:
  /// **'Belohnungsbeispiele: Hier wird nichts gutgeschrieben'**
  String get onboardingV2Story4Status;

  /// No description provided for @onboardingV2Story4CatalogTitle.
  ///
  /// In de, this message translates to:
  /// **'Mögliche Belohnungen aktueller Aktivitäten'**
  String get onboardingV2Story4CatalogTitle;

  /// Erklärt, dass die Belohnungsbeispiele im Onboarding schreibgeschützt aus dem aktuellen Aktivitätskatalog stammen.
  ///
  /// In de, this message translates to:
  /// **'Schreibgeschützte Beispiele aus {count} aktuellen Aktivitäten. Beim Ansehen dieser Seite wird nichts gutgeschrieben oder verändert.'**
  String onboardingV2Story4CatalogBody(int count);

  /// Barrierefreie Beschriftung einer möglichen Belohnung aus dem Aktivitätskatalog.
  ///
  /// In de, this message translates to:
  /// **'Mögliche Belohnung: {reward}'**
  String onboardingV2Story4PossibleReward(String reward);

  /// No description provided for @onboardingV2Story4Item1Title.
  ///
  /// In de, this message translates to:
  /// **'Spielhinweise'**
  String get onboardingV2Story4Item1Title;

  /// No description provided for @onboardingV2Story4Item1Body.
  ///
  /// In de, this message translates to:
  /// **'Kurze Hilfen bringen dich wieder in die Übung.'**
  String get onboardingV2Story4Item1Body;

  /// No description provided for @onboardingV2Story4Item2Title.
  ///
  /// In de, this message translates to:
  /// **'XP & persönliche Bestwerte'**
  String get onboardingV2Story4Item2Title;

  /// No description provided for @onboardingV2Story4Item2Body.
  ///
  /// In de, this message translates to:
  /// **'Sie halten deine Aktivität und eigene Entwicklung fest.'**
  String get onboardingV2Story4Item2Body;

  /// No description provided for @onboardingV2Story4Item3Title.
  ///
  /// In de, this message translates to:
  /// **'Quests & Stempel'**
  String get onboardingV2Story4Item3Title;

  /// No description provided for @onboardingV2Story4Item3Body.
  ///
  /// In de, this message translates to:
  /// **'Nur ausgewiesene Aktivitäten können diese Belohnungen enthalten.'**
  String get onboardingV2Story4Item3Body;

  /// No description provided for @onboardingV2Story4Item4Title.
  ///
  /// In de, this message translates to:
  /// **'Bojagi & Accessoires'**
  String get onboardingV2Story4Item4Title;

  /// No description provided for @onboardingV2Story4Item4Body.
  ///
  /// In de, this message translates to:
  /// **'Sammelobjekte werden später zum Gestalten verwendet.'**
  String get onboardingV2Story4Item4Body;

  /// No description provided for @onboardingV2Story5Eyebrow.
  ///
  /// In de, this message translates to:
  /// **'Kulturerbe-Reise'**
  String get onboardingV2Story5Eyebrow;

  /// No description provided for @onboardingV2Story5Title.
  ///
  /// In de, this message translates to:
  /// **'Stempelbuch, Bojagi und dein Hanok'**
  String get onboardingV2Story5Title;

  /// No description provided for @onboardingV2Story5Body.
  ///
  /// In de, this message translates to:
  /// **'Deine langfristige Reise führt vom Stempelbuch über Bojagi und Accessoires zum Gestalten von Räumen und historischen Häusern. Das erste Kapitel wird noch vorbereitet.'**
  String get onboardingV2Story5Body;

  /// No description provided for @onboardingV2Story5HeroSemantics.
  ///
  /// In de, this message translates to:
  /// **'Vorschau auf die künftige Kulturerbe-Reise mit Stempelbuch, Bojagi, Dekorationen und dem ersten Kapitel Ildu Gotaek.'**
  String get onboardingV2Story5HeroSemantics;

  /// No description provided for @onboardingV2Story5Status.
  ///
  /// In de, this message translates to:
  /// **'Erste Reise · Ildu Gotaek · In Vorbereitung'**
  String get onboardingV2Story5Status;

  /// No description provided for @onboardingV2Story5Item1Title.
  ///
  /// In de, this message translates to:
  /// **'Stempelbuch'**
  String get onboardingV2Story5Item1Title;

  /// No description provided for @onboardingV2Story5Item1Body.
  ///
  /// In de, this message translates to:
  /// **'Hier siehst du gesammelte Stempel und offene Stationen.'**
  String get onboardingV2Story5Item1Body;

  /// No description provided for @onboardingV2Story5Item2Title.
  ///
  /// In de, this message translates to:
  /// **'Bojagi öffnen'**
  String get onboardingV2Story5Item2Title;

  /// No description provided for @onboardingV2Story5Item2Body.
  ///
  /// In de, this message translates to:
  /// **'Ausgewiesene Belohnungen können Accessoires enthalten.'**
  String get onboardingV2Story5Item2Body;

  /// No description provided for @onboardingV2Story5Item3Title.
  ///
  /// In de, this message translates to:
  /// **'Räume gestalten'**
  String get onboardingV2Story5Item3Title;

  /// No description provided for @onboardingV2Story5Item3Body.
  ///
  /// In de, this message translates to:
  /// **'Erhaltene Accessoires werden an dafür vorgesehenen Orten eingesetzt.'**
  String get onboardingV2Story5Item3Body;

  /// No description provided for @onboardingV2Story5Item4Title.
  ///
  /// In de, this message translates to:
  /// **'Weitere Kapitel'**
  String get onboardingV2Story5Item4Title;

  /// No description provided for @onboardingV2Story5Item4Body.
  ///
  /// In de, this message translates to:
  /// **'Die Reise ist erweiterbar; Zahl und Reihenfolge stehen noch nicht fest.'**
  String get onboardingV2Story5Item4Body;

  /// No description provided for @onboardingV2Story5PreviewLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get onboardingV2Story5PreviewLabel;

  /// No description provided for @onboardingV2Story5InPreparationLabel.
  ///
  /// In de, this message translates to:
  /// **'In Vorbereitung'**
  String get onboardingV2Story5InPreparationLabel;

  /// No description provided for @onboardingV2Story5AssetReviewNote.
  ///
  /// In de, this message translates to:
  /// **'Bis Nutzungsrechte für die App und visuelle Prüfung freigegeben sind, wird hier keine Kulturerbe-Grafik verwendet.'**
  String get onboardingV2Story5AssetReviewNote;

  /// No description provided for @onboardingV2Story5SourcesAction.
  ///
  /// In de, this message translates to:
  /// **'Quellen und Angaben'**
  String get onboardingV2Story5SourcesAction;

  /// Titel des Quellenblatts zur Kulturerbe-Vorschau.
  ///
  /// In de, this message translates to:
  /// **'Quellen zu {estateName}'**
  String onboardingV2Story5SourcesTitle(String estateName);

  /// No description provided for @onboardingV2Story5SourcesBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Quellen belegen den Namen und den kulturellen Kontext der Vorschau, darunter die Verbindung des Ildu Gotaek zum Gelehrten Jeong Yeo-chang und seine Nutzung als Drehort. Ihr aktueller Registerstatus erlaubt nur das Zitieren; weitergehende Nutzungsrechte werden nicht zugesichert.'**
  String get onboardingV2Story5SourcesBody;

  /// No description provided for @onboardingV2Story5SourceInstitution.
  ///
  /// In de, this message translates to:
  /// **'Institution'**
  String get onboardingV2Story5SourceInstitution;

  /// No description provided for @onboardingV2Story5SourceYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get onboardingV2Story5SourceYear;

  /// Jahr der Kulturerbe-Quelle mit der Grundlage dieses Jahres im Register.
  ///
  /// In de, this message translates to:
  /// **'{year} ({basis})'**
  String onboardingV2Story5SourceYearValue(int year, String basis);

  /// No description provided for @onboardingV2Story5SourceYearPublished.
  ///
  /// In de, this message translates to:
  /// **'veröffentlicht'**
  String get onboardingV2Story5SourceYearPublished;

  /// No description provided for @onboardingV2Story5SourceYearUpdated.
  ///
  /// In de, this message translates to:
  /// **'aktualisiert'**
  String get onboardingV2Story5SourceYearUpdated;

  /// No description provided for @onboardingV2Story5SourceYearAccessed.
  ///
  /// In de, this message translates to:
  /// **'abgerufen'**
  String get onboardingV2Story5SourceYearAccessed;

  /// No description provided for @onboardingV2Story5SourceTitle.
  ///
  /// In de, this message translates to:
  /// **'Quellentitel'**
  String get onboardingV2Story5SourceTitle;

  /// No description provided for @onboardingV2Story5SourceAuthor.
  ///
  /// In de, this message translates to:
  /// **'Urheber'**
  String get onboardingV2Story5SourceAuthor;

  /// No description provided for @onboardingV2Story5SourceLicense.
  ///
  /// In de, this message translates to:
  /// **'Lizenzstatus'**
  String get onboardingV2Story5SourceLicense;

  /// No description provided for @onboardingV2Story5SourceLicenseKoglType1.
  ///
  /// In de, this message translates to:
  /// **'KOGL Typ 1'**
  String get onboardingV2Story5SourceLicenseKoglType1;

  /// No description provided for @onboardingV2Story5SourceLicenseCitationOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Zitat; weitergehende Nutzungsrechte nicht zugesichert'**
  String get onboardingV2Story5SourceLicenseCitationOnly;

  /// No description provided for @onboardingV2Story5SourceLicenseSeparatelyApproved.
  ///
  /// In de, this message translates to:
  /// **'Nutzung separat freigegeben'**
  String get onboardingV2Story5SourceLicenseSeparatelyApproved;

  /// No description provided for @onboardingV2Story5SourceUrl.
  ///
  /// In de, this message translates to:
  /// **'URL'**
  String get onboardingV2Story5SourceUrl;

  /// Beschriftung der Schaltfläche, die eine Kulturerbe-Quelle im Browser öffnet.
  ///
  /// In de, this message translates to:
  /// **'Quelle öffnen: {sourceTitle}'**
  String onboardingV2Story5OpenSource(String sourceTitle);

  /// No description provided for @onboardingV2Story5SourcesClose.
  ///
  /// In de, this message translates to:
  /// **'Quellen schließen'**
  String get onboardingV2Story5SourcesClose;

  /// No description provided for @onboardingV2SetupEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dein persönlicher Start'**
  String get onboardingV2SetupEyebrow;

  /// No description provided for @onboardingV2SetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Wofür lernst du, und wo steigst du ein?'**
  String get onboardingV2SetupTitle;

  /// No description provided for @onboardingV2SetupBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Ziel ändert nur die Reihenfolge von Einstiegstipps und Empfehlungen. Schwierigkeit, Inhalte, Fortschritt und Belohnungen bleiben gleich.'**
  String get onboardingV2SetupBody;

  /// No description provided for @onboardingV2SetupPurposeHeading.
  ///
  /// In de, this message translates to:
  /// **'1. Wähle dein Ziel'**
  String get onboardingV2SetupPurposeHeading;

  /// No description provided for @onboardingV2SetupLevelHeading.
  ///
  /// In de, this message translates to:
  /// **'2. Wähle deinen Startpunkt'**
  String get onboardingV2SetupLevelHeading;

  /// No description provided for @onboardingV2SetupLevelHelp.
  ///
  /// In de, this message translates to:
  /// **'Wähle den Startpunkt, der am besten zu dem passt, was du schon kannst. Du kannst ihn später in den Einstellungen ändern.'**
  String get onboardingV2SetupLevelHelp;

  /// No description provided for @onboardingV2SetupSelectLevelPrompt.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Level, um ein echtes Beispiel und die Lernziele zu sehen.'**
  String get onboardingV2SetupSelectLevelPrompt;

  /// No description provided for @onboardingV2SetupExampleLabel.
  ///
  /// In de, this message translates to:
  /// **'Beispiel auf diesem Level'**
  String get onboardingV2SetupExampleLabel;

  /// No description provided for @onboardingV2SetupCanDoLabel.
  ///
  /// In de, this message translates to:
  /// **'Das kannst du ungefähr schon'**
  String get onboardingV2SetupCanDoLabel;

  /// No description provided for @onboardingV2SetupLearnHereLabel.
  ///
  /// In de, this message translates to:
  /// **'Damit beginnst du hier'**
  String get onboardingV2SetupLearnHereLabel;

  /// No description provided for @onboardingV2SetupCompareAction.
  ///
  /// In de, this message translates to:
  /// **'Level vergleichen'**
  String get onboardingV2SetupCompareAction;

  /// No description provided for @onboardingV2SetupCompareTitle.
  ///
  /// In de, this message translates to:
  /// **'Welcher Startpunkt passt?'**
  String get onboardingV2SetupCompareTitle;

  /// No description provided for @onboardingV2SetupCompareBody.
  ///
  /// In de, this message translates to:
  /// **'Die direkte Auswahl ist dein Lernstart, kein Nachweis deiner Kenntnisse. Deinen Kurs-Startpunkt und dein Level zum Stöbern kannst du später getrennt ändern.'**
  String get onboardingV2SetupCompareBody;

  /// No description provided for @onboardingV2SetupCompareClose.
  ///
  /// In de, this message translates to:
  /// **'Vergleich schließen'**
  String get onboardingV2SetupCompareClose;

  /// No description provided for @onboardingV2SetupContinue.
  ///
  /// In de, this message translates to:
  /// **'Auswahl übernehmen'**
  String get onboardingV2SetupContinue;

  /// No description provided for @onboardingV2LevelA1ExampleKo.
  ///
  /// In de, this message translates to:
  /// **'안녕하세요.'**
  String get onboardingV2LevelA1ExampleKo;

  /// No description provided for @onboardingV2LevelA2ExampleKo.
  ///
  /// In de, this message translates to:
  /// **'아메리카노 한 잔 주세요.'**
  String get onboardingV2LevelA2ExampleKo;

  /// No description provided for @onboardingV2LevelB1ExampleKo.
  ///
  /// In de, this message translates to:
  /// **'어제 친구와 영화를 봤어요.'**
  String get onboardingV2LevelB1ExampleKo;

  /// No description provided for @onboardingV2LevelB2ExampleKo.
  ///
  /// In de, this message translates to:
  /// **'회의가 길어져서 조금 늦을 것 같아요.'**
  String get onboardingV2LevelB2ExampleKo;

  /// No description provided for @onboardingV2LevelC1ExampleKo.
  ///
  /// In de, this message translates to:
  /// **'확인된 사실과 현재의 해석을 나누어 설명하겠습니다.'**
  String get onboardingV2LevelC1ExampleKo;

  /// No description provided for @onboardingV2LevelC2ExampleKo.
  ///
  /// In de, this message translates to:
  /// **'침묵을 동의로 보면 질문의 틀만으로도 참여를 제한할 수 있습니다.'**
  String get onboardingV2LevelC2ExampleKo;

  /// No description provided for @onboardingV2PurposeLifeTravelTitle.
  ///
  /// In de, this message translates to:
  /// **'Alltag & Reisen'**
  String get onboardingV2PurposeLifeTravelTitle;

  /// No description provided for @onboardingV2PurposeLifeTravelBody.
  ///
  /// In de, this message translates to:
  /// **'Bestellen, Wege finden und tägliche Situationen meistern'**
  String get onboardingV2PurposeLifeTravelBody;

  /// No description provided for @onboardingV2PurposePeopleCultureTitle.
  ///
  /// In de, this message translates to:
  /// **'Menschen & Kultur'**
  String get onboardingV2PurposePeopleCultureTitle;

  /// No description provided for @onboardingV2PurposePeopleCultureBody.
  ///
  /// In de, this message translates to:
  /// **'Gespräche, Beziehungen und kulturelle Zusammenhänge'**
  String get onboardingV2PurposePeopleCultureBody;

  /// No description provided for @onboardingV2PurposeStudyWorkTitle.
  ///
  /// In de, this message translates to:
  /// **'Studium & Beruf'**
  String get onboardingV2PurposeStudyWorkTitle;

  /// No description provided for @onboardingV2PurposeStudyWorkBody.
  ///
  /// In de, this message translates to:
  /// **'Im Kurs, an der Hochschule und bei der Arbeit sicher handeln'**
  String get onboardingV2PurposeStudyWorkBody;

  /// No description provided for @onboardingV2PurposeKContentTitle.
  ///
  /// In de, this message translates to:
  /// **'K-Content'**
  String get onboardingV2PurposeKContentTitle;

  /// No description provided for @onboardingV2PurposeKContentBody.
  ///
  /// In de, this message translates to:
  /// **'Musik, Serien, Filme, Podcasts und Interviews besser verstehen'**
  String get onboardingV2PurposeKContentBody;

  /// No description provided for @onboardingV2CompanionEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernfreund'**
  String get onboardingV2CompanionEyebrow;

  /// No description provided for @onboardingV2CompanionTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer begleitet dich?'**
  String get onboardingV2CompanionTitle;

  /// No description provided for @onboardingV2CompanionBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle Taego oder Joy. Die Wahl ist für den ersten Start erforderlich; später kannst du den Lernfreund wechseln oder seine Anzeige ausschalten.'**
  String get onboardingV2CompanionBody;

  /// No description provided for @onboardingV2CompanionEqualNote.
  ///
  /// In de, this message translates to:
  /// **'Inhalte, Antworten, Hinweisstärke, XP, Fortschritt und Belohnungen sind bei beiden gleich.'**
  String get onboardingV2CompanionEqualNote;

  /// No description provided for @onboardingV2CompanionContinue.
  ///
  /// In de, this message translates to:
  /// **'Auswahl bestätigen'**
  String get onboardingV2CompanionContinue;

  /// No description provided for @onboardingV2CompanionTaegoRhythm.
  ///
  /// In de, this message translates to:
  /// **'Ruhig und Schritt für Schritt'**
  String get onboardingV2CompanionTaegoRhythm;

  /// No description provided for @onboardingV2CompanionTaegoBody.
  ///
  /// In de, this message translates to:
  /// **'Ordnet dieselben Hinweise in eine klare Reihenfolge und zeigt dir den nächsten sinnvollen Schritt.'**
  String get onboardingV2CompanionTaegoBody;

  /// No description provided for @onboardingV2CompanionTaegoSelected.
  ///
  /// In de, this message translates to:
  /// **'Taego wurde ausgewählt.'**
  String get onboardingV2CompanionTaegoSelected;

  /// No description provided for @onboardingV2CompanionJoyRhythm.
  ///
  /// In de, this message translates to:
  /// **'Kurz und direkt ins Üben'**
  String get onboardingV2CompanionJoyRhythm;

  /// No description provided for @onboardingV2CompanionJoyBody.
  ///
  /// In de, this message translates to:
  /// **'Gibt dieselben Hinweise als kurze Anstöße und feiert deinen nächsten Versuch.'**
  String get onboardingV2CompanionJoyBody;

  /// No description provided for @onboardingV2CompanionJoySelected.
  ///
  /// In de, this message translates to:
  /// **'Joy wurde ausgewählt.'**
  String get onboardingV2CompanionJoySelected;

  /// No description provided for @onboardingV2ConfirmationEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Bereit für den Start'**
  String get onboardingV2ConfirmationEyebrow;

  /// No description provided for @onboardingV2ConfirmationBody.
  ///
  /// In de, this message translates to:
  /// **'Das Begrüßungsvideo ist nur eine Vorstellung. Du kannst jederzeit weitergehen, auch wenn es nicht lädt.'**
  String get onboardingV2ConfirmationBody;

  /// No description provided for @onboardingV2ConfirmationStart.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsam starten'**
  String get onboardingV2ConfirmationStart;

  /// No description provided for @onboardingV2ConfirmationChange.
  ///
  /// In de, this message translates to:
  /// **'Anderen Lernfreund wählen'**
  String get onboardingV2ConfirmationChange;

  /// No description provided for @settingsLearningLevelsSection.
  ///
  /// In de, this message translates to:
  /// **'Lernstufen'**
  String get settingsLearningLevelsSection;

  /// No description provided for @settingsCourseStartTitle.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt im Kurs'**
  String get settingsCourseStartTitle;

  /// No description provided for @settingsCourseStartDescription.
  ///
  /// In de, this message translates to:
  /// **'Legt fest, wo dein fortlaufender Kurs beginnt. Eine neue Wahl ersetzt den aktuellen Kurspfad; frühere Einheiten gelten dadurch weder als beherrscht noch erhältst du XP oder Belohnungen.'**
  String get settingsCourseStartDescription;

  /// No description provided for @settingsBrowseLevelTitle.
  ///
  /// In de, this message translates to:
  /// **'Stufe zum Stöbern'**
  String get settingsBrowseLevelTitle;

  /// No description provided for @settingsBrowseLevelDescription.
  ///
  /// In de, this message translates to:
  /// **'Filtert nur Bibliotheken und Szenarien. Dein Kursfortschritt bleibt unverändert.'**
  String get settingsBrowseLevelDescription;

  /// No description provided for @settingsRecheckLevelTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Level neu einschätzen'**
  String get settingsRecheckLevelTitle;

  /// No description provided for @settingsRecheckLevelDescription.
  ///
  /// In de, this message translates to:
  /// **'Mache freiwillig einen Test mit acht Aufgaben. Das Ergebnis ist eine Empfehlung; den Startpunkt wählst weiterhin du.'**
  String get settingsRecheckLevelDescription;

  /// No description provided for @settingsCompanionVisibleTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernfreund anzeigen'**
  String get settingsCompanionVisibleTitle;

  /// No description provided for @settingsCompanionVisibleDescription.
  ///
  /// In de, this message translates to:
  /// **'Blende deinen Lernfreund ein oder aus, ohne die gewählte Figur zu ändern.'**
  String get settingsCompanionVisibleDescription;

  /// No description provided for @settingsGuideSection.
  ///
  /// In de, this message translates to:
  /// **'App-Anleitung'**
  String get settingsGuideSection;

  /// No description provided for @settingsGuideTitle.
  ///
  /// In de, this message translates to:
  /// **'Hangul-Sori-Anleitung öffnen'**
  String get settingsGuideTitle;

  /// No description provided for @settingsGuideDescription.
  ///
  /// In de, this message translates to:
  /// **'Sieh jederzeit nach, wie Lernen, Spiele, gespeicherte Inhalte, Belohnungen, dein Buch und wichtige Einstellungen funktionieren.'**
  String get settingsGuideDescription;

  /// No description provided for @settingsCourseStartConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt im Kurs ändern?'**
  String get settingsCourseStartConfirmTitle;

  /// No description provided for @settingsCourseStartConfirmDescription.
  ///
  /// In de, this message translates to:
  /// **'Dein fortlaufender Kurs startet bei {level} neu und ersetzt den bisherigen Kursfortschritt. Andere Übungsdaten, XP, Belohnungen und Sammlungen bleiben erhalten; frühere Einheiten gelten nicht als abgeschlossen.'**
  String settingsCourseStartConfirmDescription(String level);

  /// No description provided for @settingsCourseStartConfirmAction.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt ändern'**
  String get settingsCourseStartConfirmAction;

  /// No description provided for @guideHubAppBarTitle.
  ///
  /// In de, this message translates to:
  /// **'App-Anleitung'**
  String get guideHubAppBarTitle;

  /// No description provided for @guideHubEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Sicher loslegen'**
  String get guideHubEyebrow;

  /// No description provided for @guideHubTitle.
  ///
  /// In de, this message translates to:
  /// **'Finde jede wichtige Funktion'**
  String get guideHubTitle;

  /// No description provided for @guideHubDescription.
  ///
  /// In de, this message translates to:
  /// **'Öffne ein Thema genau dann, wenn du es brauchst. Vorschauen und angekündigte Funktionen werden klar gekennzeichnet und verhalten sich nie wie fertige Funktionen.'**
  String get guideHubDescription;

  /// No description provided for @guideCompletedLabel.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get guideCompletedLabel;

  /// No description provided for @guideRestoreTodayCard.
  ///
  /// In de, this message translates to:
  /// **'Start-Anleitung wieder auf Heute anzeigen'**
  String get guideRestoreTodayCard;

  /// No description provided for @guideTodayCardRestoredStatus.
  ///
  /// In de, this message translates to:
  /// **'Die Start-Anleitung wird wieder auf Heute angezeigt.'**
  String get guideTodayCardRestoredStatus;

  /// No description provided for @guidePreferenceWriteFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Einstellung der Anleitung konnte nicht gespeichert werden. Es wurde nichts geändert. Bitte versuche es erneut.'**
  String get guidePreferenceWriteFailed;

  /// No description provided for @guideFeatureNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Dieses Thema ist als Vorschau oder angekündigte Funktion markiert und lässt sich noch nicht als fertige Funktion öffnen.'**
  String get guideFeatureNotAvailable;

  /// No description provided for @guideAvailabilityLive.
  ///
  /// In de, this message translates to:
  /// **'Jetzt verfügbar'**
  String get guideAvailabilityLive;

  /// No description provided for @guideAvailabilityPreview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get guideAvailabilityPreview;

  /// No description provided for @guideAvailabilityComingSoon.
  ///
  /// In de, this message translates to:
  /// **'In Vorbereitung'**
  String get guideAvailabilityComingSoon;

  /// No description provided for @guideAvailabilityUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Nicht verfügbar'**
  String get guideAvailabilityUnavailable;

  /// No description provided for @guideOpenAction.
  ///
  /// In de, this message translates to:
  /// **'Anleitung ansehen'**
  String get guideOpenAction;

  /// No description provided for @guidePreviewAction.
  ///
  /// In de, this message translates to:
  /// **'Vorschau ansehen'**
  String get guidePreviewAction;

  /// No description provided for @guideDetailsAction.
  ///
  /// In de, this message translates to:
  /// **'Status ansehen'**
  String get guideDetailsAction;

  /// No description provided for @guideModuleEyebrow.
  ///
  /// In de, this message translates to:
  /// **'Thema im Überblick'**
  String get guideModuleEyebrow;

  /// No description provided for @guideModuleStepsTitle.
  ///
  /// In de, this message translates to:
  /// **'Das solltest du zuerst wissen'**
  String get guideModuleStepsTitle;

  /// No description provided for @guideModuleActionsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einen Bereich öffnen'**
  String get guideModuleActionsTitle;

  /// No description provided for @guideModulePassiveNotice.
  ///
  /// In de, this message translates to:
  /// **'Diese Erklärung fragt nicht nach Kamera- oder Mikrofonzugriff, spielt kein Audio ab, verändert keinen Lernfortschritt und vergibt keine Belohnungen.'**
  String get guideModulePassiveNotice;

  /// No description provided for @guideScenarioCategoryCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Szenario} other{{count} Szenarien}}'**
  String guideScenarioCategoryCount(int count);

  /// No description provided for @guideModulePersonalizedStartStep1.
  ///
  /// In de, this message translates to:
  /// **'Dein Lernziel ändert die Reihenfolge der Empfehlungen und dieser Startliste. Schwierigkeit, XP und Belohnungen bleiben gleich.'**
  String get guideModulePersonalizedStartStep1;

  /// No description provided for @guideModulePersonalizedStartStep2.
  ///
  /// In de, this message translates to:
  /// **'Der Kurs-Startpunkt setzt nach deiner Bestätigung fest, wo dein Kurs beginnt. Die Stufe zum Stöbern filtert nur Bibliotheken und Szenarien.'**
  String get guideModulePersonalizedStartStep2;

  /// No description provided for @guideModuleLearnStep1.
  ///
  /// In de, this message translates to:
  /// **'Hangeul-Übersicht, Karten und Schreiben sind getrennte Reiter. Öffne nur die Übung, die du gerade brauchst.'**
  String get guideModuleLearnStep1;

  /// No description provided for @guideModuleLearnStep2.
  ///
  /// In de, this message translates to:
  /// **'Unter Lernen findest du außerdem Hören, Aussprache und Szenarien nach Level. Kategorien stammen aus dem aktuellen Katalog; diese Anleitung erfindet keine Zuordnung.'**
  String get guideModuleLearnStep2;

  /// No description provided for @guideModuleLearnStep3.
  ///
  /// In de, this message translates to:
  /// **'Ein Zielbereich kann seinen eigenen kontextbezogenen Hinweis einblenden. Die Anleitung schickt dich nie automatisch durch mehrere Bereiche und setzt bereits abgeschlossene Hinweise nicht zurück.'**
  String get guideModuleLearnStep3;

  /// No description provided for @guideModuleMyBookStep1.
  ///
  /// In de, this message translates to:
  /// **'Kamera oder Galerie wählst du erst nach dem Öffnen der Aufnahme. Die Texterkennung läuft auf deinem Gerät; vor der Analyse prüfst du den erkannten koreanischen Text.'**
  String get guideModuleMyBookStep1;

  /// No description provided for @guideModuleMyBookStep2.
  ///
  /// In de, this message translates to:
  /// **'Wenn du Analysieren wählst, kann der erkannte Text an einen Analysedienst in der EU gesendet werden. Das fotografierte Bild bleibt auf deinem Gerät.'**
  String get guideModuleMyBookStep2;

  /// No description provided for @guideModuleMyBookStep3.
  ///
  /// In de, this message translates to:
  /// **'Unterstützte Seitenergebnisse, Wörter, Ausdrücke, Grammatik und Sätze lassen sich mit den heutigen Werkzeugen speichern. Diese Anleitung verspricht und erzeugt keine neuen KI-Übungen.'**
  String get guideModuleMyBookStep3;

  /// No description provided for @guideModuleCardsStep1.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Lernkarte, um sie umzudrehen. Wische, um zur nächsten Karte zu wechseln.'**
  String get guideModuleCardsStep1;

  /// No description provided for @guideModuleCardsStep2.
  ///
  /// In de, this message translates to:
  /// **'Ein Herz ist ein unverbindlicher Favorit und startet nie die verteilte Wiederholung. Ein Lesezeichen speichert unterstützte Inhalte in deiner Lernsammlung.'**
  String get guideModuleCardsStep2;

  /// No description provided for @guideModuleCardsStep3.
  ///
  /// In de, this message translates to:
  /// **'Die Lernsammlung trennt Favoriten, Gespeichertes und heute Fälliges. Der direkte Wiederholungsweg unterstützt derzeit fällige Wörter; andere gespeicherte Typen bleiben sichtbar und werden nicht als Wortwiederholung ausgegeben.'**
  String get guideModuleCardsStep3;

  /// No description provided for @guideModuleGamesStep1.
  ///
  /// In de, this message translates to:
  /// **'Hinweise helfen während eines Spiels. Ihre Nutzung zählt aber nicht als selbstständiger Abruf oder als Beherrschung.'**
  String get guideModuleGamesStep1;

  /// No description provided for @guideModuleGamesStep2.
  ///
  /// In de, this message translates to:
  /// **'XP, persönliche Rekorde und Quest-Fortschritt entstehen nur durch unterstützte abgeschlossene Aktivitäten. Das Ansehen dieser Anleitung vergibt nichts.'**
  String get guideModuleGamesStep2;

  /// No description provided for @guideModuleGamesStep3.
  ///
  /// In de, this message translates to:
  /// **'Stempel können mit Bojagi und Dekorationen verbunden sein. Im Hanok-Bereich siehst du das derzeit verfügbare Stempelbuch, Inventar und die Raumgestaltung.'**
  String get guideModuleGamesStep3;

  /// No description provided for @guideModuleSettingsStep1.
  ///
  /// In de, this message translates to:
  /// **'Kurs-Startpunkt und Stufe zum Stöbern sind getrennte Einstellungen: Die eine ändert den Kurs nach Bestätigung, die andere nur Inhaltsfilter.'**
  String get guideModuleSettingsStep1;

  /// No description provided for @guideModuleSettingsStep2.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählte Figur und Figurenanzeige sind getrennt. Du kannst Taego oder Joy behalten und die Figur auf dem Bildschirm ausblenden.'**
  String get guideModuleSettingsStep2;

  /// No description provided for @guideModuleSettingsStep3.
  ///
  /// In de, this message translates to:
  /// **'Lege das allgemeine Sprechtempo in den Einstellungen fest. Unterstützte Audioseiten haben zusätzlich einen Geschwindigkeits-Chip; die App-Anleitung kannst du jederzeit in den Einstellungen erneut öffnen.'**
  String get guideModuleSettingsStep3;

  /// No description provided for @guideModuleActionCourseStart.
  ///
  /// In de, this message translates to:
  /// **'Kurs-Startpunkt'**
  String get guideModuleActionCourseStart;

  /// No description provided for @guideModuleActionBrowseLevel.
  ///
  /// In de, this message translates to:
  /// **'Stufe zum Stöbern'**
  String get guideModuleActionBrowseLevel;

  /// No description provided for @guideModuleActionHangulOverview.
  ///
  /// In de, this message translates to:
  /// **'Hangeul-Übersicht'**
  String get guideModuleActionHangulOverview;

  /// No description provided for @guideModuleActionHangulCards.
  ///
  /// In de, this message translates to:
  /// **'Hangeul-Karten'**
  String get guideModuleActionHangulCards;

  /// No description provided for @guideModuleActionHangulWrite.
  ///
  /// In de, this message translates to:
  /// **'Hangeul schreiben üben'**
  String get guideModuleActionHangulWrite;

  /// No description provided for @guideModuleActionLearnStage.
  ///
  /// In de, this message translates to:
  /// **'Lernen öffnen'**
  String get guideModuleActionLearnStage;

  /// No description provided for @guideModuleActionCaptureTextbook.
  ///
  /// In de, this message translates to:
  /// **'Lehrbuchseite aufnehmen'**
  String get guideModuleActionCaptureTextbook;

  /// No description provided for @guideModuleActionStudyLibrary.
  ///
  /// In de, this message translates to:
  /// **'Lernsammlung öffnen'**
  String get guideModuleActionStudyLibrary;

  /// No description provided for @guideModuleActionGamesStage.
  ///
  /// In de, this message translates to:
  /// **'Spiele öffnen'**
  String get guideModuleActionGamesStage;

  /// No description provided for @guideModuleActionHanokStage.
  ///
  /// In de, this message translates to:
  /// **'Stempel und Dekoration öffnen'**
  String get guideModuleActionHanokStage;

  /// No description provided for @guideModuleActionCompanion.
  ///
  /// In de, this message translates to:
  /// **'Figur und Anzeige'**
  String get guideModuleActionCompanion;

  /// No description provided for @guideModuleActionVoiceSpeed.
  ///
  /// In de, this message translates to:
  /// **'Sprechtempo'**
  String get guideModuleActionVoiceSpeed;

  /// No description provided for @guideModuleActionGuideSettings.
  ///
  /// In de, this message translates to:
  /// **'App-Anleitung in den Einstellungen'**
  String get guideModuleActionGuideSettings;

  /// No description provided for @guideTopicPersonalizedStartTitle.
  ///
  /// In de, this message translates to:
  /// **'Ein Start, der zu mir passt'**
  String get guideTopicPersonalizedStartTitle;

  /// No description provided for @guideTopicPersonalizedStartDescription.
  ///
  /// In de, this message translates to:
  /// **'Erfahre, wie dein Ziel die Startliste und Empfehlungen sortiert und warum Kurs-Startpunkt und Stufe zum Stöbern verschieden sind.'**
  String get guideTopicPersonalizedStartDescription;

  /// No description provided for @guideTopicLearnTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernen'**
  String get guideTopicLearnTitle;

  /// No description provided for @guideTopicLearnDescription.
  ///
  /// In de, this message translates to:
  /// **'Finde Hangeul-Zeichen, Schreiben, Hören, Aussprache sowie Szenarien und Kategorien für dein Level.'**
  String get guideTopicLearnDescription;

  /// No description provided for @guideTopicMyBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Buch'**
  String get guideTopicMyBookTitle;

  /// No description provided for @guideTopicMyBookDescription.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere freiwillig eine Seite. Die Texterkennung läuft auf deinem Gerät. Wählst du Analysieren, kann der erkannte Text an einen Analysedienst in der EU gesendet werden. Unterstützte Ergebnisse kannst du anschließend speichern. Diese Anleitung fragt nicht nach Kamerazugriff.'**
  String get guideTopicMyBookDescription;

  /// No description provided for @guideTopicCardsAndMemoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Karten und Gedächtnis'**
  String get guideTopicCardsAndMemoryTitle;

  /// No description provided for @guideTopicCardsAndMemoryDescription.
  ///
  /// In de, this message translates to:
  /// **'Tippe zum Wenden und wische weiter. Ein Herz ist ein unverbindlicher Favorit und startet keine Wiederholung. Ein Lesezeichen hält unterstützte Inhalte in deiner Lernsammlung fest. Dort findest du Favoriten, gespeicherte Wörter, Grammatik, Sätze, Ausdrücke und Hangeul sowie unterstützte Wörter, die zur Wiederholung fällig sind.'**
  String get guideTopicCardsAndMemoryDescription;

  /// No description provided for @guideTopicGamesAndRewardsTitle.
  ///
  /// In de, this message translates to:
  /// **'Spielen und Belohnungen'**
  String get guideTopicGamesAndRewardsTitle;

  /// No description provided for @guideTopicGamesAndRewardsDescription.
  ///
  /// In de, this message translates to:
  /// **'Sieh, wie Hinweise, XP, persönliche Rekorde, Quests, Stempel, Bojagi, Accessoires und Raumgestaltung mit echten Lernaktivitäten zusammenhängen.'**
  String get guideTopicGamesAndRewardsDescription;

  /// No description provided for @guideTopicSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Einstellungen'**
  String get guideTopicSettingsTitle;

  /// No description provided for @guideTopicSettingsDescription.
  ///
  /// In de, this message translates to:
  /// **'Ändere Kurs-Startpunkt, Stufe zum Stöbern, Figur, Figurenanzeige und Sprechtempo in den Einstellungen. Auf unterstützten Audioseiten kannst du das Tempo außerdem direkt über den Geschwindigkeits-Chip ändern oder diese Anleitung erneut öffnen.'**
  String get guideTopicSettingsDescription;

  /// No description provided for @studyLibraryAppBarTitle.
  ///
  /// In de, this message translates to:
  /// **'Lernsammlung'**
  String get studyLibraryAppBarTitle;

  /// No description provided for @studyLibraryEyebrow.
  ///
  /// In de, this message translates to:
  /// **'FAVORITEN & GESPEICHERT'**
  String get studyLibraryEyebrow;

  /// No description provided for @studyLibraryTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles, was du behalten möchtest'**
  String get studyLibraryTitle;

  /// No description provided for @studyLibraryDescription.
  ///
  /// In de, this message translates to:
  /// **'Favoriten und gespeicherte Lerninhalte bleiben getrennt. So entscheidest du, was nur interessant ist und was in deine Lernsammlung gehört.'**
  String get studyLibraryDescription;

  /// No description provided for @studyLibraryRefresh.
  ///
  /// In de, this message translates to:
  /// **'Lernsammlung aktualisieren'**
  String get studyLibraryRefresh;

  /// No description provided for @studyLibraryHeartMeaningTitle.
  ///
  /// In de, this message translates to:
  /// **'Herz = Favorit'**
  String get studyLibraryHeartMeaningTitle;

  /// No description provided for @studyLibraryHeartMeaningBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Herz hält etwas griffbereit. Es fügt den Inhalt niemals automatisch zur Wiederholung hinzu.'**
  String get studyLibraryHeartMeaningBody;

  /// No description provided for @studyLibraryBookmarkMeaningTitle.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen = zum Lernen gespeichert'**
  String get studyLibraryBookmarkMeaningTitle;

  /// No description provided for @studyLibraryBookmarkMeaningBody.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Inhalte behalten ihren echten Typ: Wort, Grammatik, Satz, Ausdruck oder Hangeul.'**
  String get studyLibraryBookmarkMeaningBody;

  /// No description provided for @studyLibraryFavoritesTab.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get studyLibraryFavoritesTab;

  /// No description provided for @studyLibrarySavedTab.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get studyLibrarySavedTab;

  /// No description provided for @studyLibraryDueTab.
  ///
  /// In de, this message translates to:
  /// **'Heute fällig'**
  String get studyLibraryDueTab;

  /// No description provided for @studyLibraryViewSelectorLabel.
  ///
  /// In de, this message translates to:
  /// **'Ansicht der Lernsammlung wählen'**
  String get studyLibraryViewSelectorLabel;

  /// No description provided for @studyLibraryViewChoice.
  ///
  /// In de, this message translates to:
  /// **'{view}, {count, plural, one{1 Eintrag} other{{count} Einträge}}'**
  String studyLibraryViewChoice(String view, int count);

  /// No description provided for @studyLibraryViewSelected.
  ///
  /// In de, this message translates to:
  /// **'{view}. {count, plural, one{1 Eintrag angezeigt} other{{count} Einträge angezeigt}}'**
  String studyLibraryViewSelected(String view, int count);

  /// No description provided for @studyLibraryFavoritesDescription.
  ///
  /// In de, this message translates to:
  /// **'Ein Herz ist ein unverbindlicher Favorit. Favoriten starten von allein keine Wiederholung.'**
  String get studyLibraryFavoritesDescription;

  /// No description provided for @studyLibrarySavedDescription.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Wörter, Grammatik, Sätze, Ausdrücke und Hangeul behalten ihren eigenen Inhaltstyp.'**
  String get studyLibrarySavedDescription;

  /// No description provided for @studyLibraryDueDescription.
  ///
  /// In de, this message translates to:
  /// **'Hier erscheinen nur gespeicherte Wörter, die die aktuelle Wort-Wiederholung sicher unterstützt. Andere Inhalte bleiben gespeichert, bis eine passende Übungsform verfügbar ist.'**
  String get studyLibraryDueDescription;

  /// No description provided for @studyLibraryFavoriteStatus.
  ///
  /// In de, this message translates to:
  /// **'Favorit'**
  String get studyLibraryFavoriteStatus;

  /// No description provided for @studyLibrarySavedStatus.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get studyLibrarySavedStatus;

  /// No description provided for @studyLibraryDueStatus.
  ///
  /// In de, this message translates to:
  /// **'Fällig'**
  String get studyLibraryDueStatus;

  /// No description provided for @studyLibraryTypeWord.
  ///
  /// In de, this message translates to:
  /// **'Wort'**
  String get studyLibraryTypeWord;

  /// No description provided for @studyLibraryTypeGrammar.
  ///
  /// In de, this message translates to:
  /// **'Grammatik'**
  String get studyLibraryTypeGrammar;

  /// No description provided for @studyLibraryTypeSentence.
  ///
  /// In de, this message translates to:
  /// **'Satz'**
  String get studyLibraryTypeSentence;

  /// No description provided for @studyLibraryTypeExpression.
  ///
  /// In de, this message translates to:
  /// **'Ausdruck'**
  String get studyLibraryTypeExpression;

  /// No description provided for @studyLibraryTypeHangul.
  ///
  /// In de, this message translates to:
  /// **'Hangeul'**
  String get studyLibraryTypeHangul;

  /// No description provided for @studyLibraryLoading.
  ///
  /// In de, this message translates to:
  /// **'Deine Lernsammlung wird geladen …'**
  String get studyLibraryLoading;

  /// No description provided for @studyLibraryLoadErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Lernsammlung konnte nicht geladen werden'**
  String get studyLibraryLoadErrorTitle;

  /// No description provided for @studyLibraryLoadErrorBody.
  ///
  /// In de, this message translates to:
  /// **'Es wurde nichts verändert. Versuch noch einmal, deine lokalen Favoriten und gespeicherten Inhalte zu laden.'**
  String get studyLibraryLoadErrorBody;

  /// No description provided for @studyLibraryFavoritesEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Favoriten'**
  String get studyLibraryFavoritesEmptyTitle;

  /// No description provided for @studyLibraryFavoritesEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe bei unterstützten Inhalten auf ein Herz, um sie hier ohne zusätzliche Wiederholungen griffbereit zu halten.'**
  String get studyLibraryFavoritesEmptyBody;

  /// No description provided for @studyLibrarySavedEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts gespeichert'**
  String get studyLibrarySavedEmptyTitle;

  /// No description provided for @studyLibrarySavedEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen, deine Wortpakete und unterstützte Inhalte aus deinem Buch erscheinen hier mit ihrem echten Inhaltstyp.'**
  String get studyLibrarySavedEmptyBody;

  /// No description provided for @studyLibraryDueEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Für heute ist alles erledigt'**
  String get studyLibraryDueEmptyTitle;

  /// No description provided for @studyLibraryDueEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Keine unterstützten gespeicherten Wörter sind fällig. Grammatik, Sätze, Ausdrücke und Hangeul bleiben sicher gespeichert, ohne als Wörter ausgegeben zu werden.'**
  String get studyLibraryDueEmptyBody;

  /// No description provided for @studyLibraryUnresolvedTitle.
  ///
  /// In de, this message translates to:
  /// **'Quellinhalt nicht verfügbar'**
  String get studyLibraryUnresolvedTitle;

  /// No description provided for @studyLibraryUnresolvedBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Favorit bleibt erhalten, aber sein ursprünglicher Inhalt ({id}) kann derzeit nicht angezeigt werden.'**
  String studyLibraryUnresolvedBody(String id);

  /// No description provided for @studyLibraryBookmarkUnavailableTitle.
  ///
  /// In de, this message translates to:
  /// **'Einige gespeicherte Lesezeichen sind nicht verfügbar'**
  String get studyLibraryBookmarkUnavailableTitle;

  /// No description provided for @studyLibraryBookmarkCorruptBody.
  ///
  /// In de, this message translates to:
  /// **'Die Lesezeichendaten konnten nicht gelesen werden und blieben unverändert. Änderungen an Lesezeichen sind gesperrt; Favoriten und andere lokale Quellen werden weiterhin angezeigt.'**
  String get studyLibraryBookmarkCorruptBody;

  /// No description provided for @studyLibraryBookmarkFutureBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Lesezeichen wurden von einer neueren App-Version geschrieben und blieben unverändert. Änderungen an Lesezeichen sind gesperrt; Favoriten und andere lokale Quellen werden weiterhin angezeigt.'**
  String get studyLibraryBookmarkFutureBody;

  /// No description provided for @studyLibrarySaveBookmark.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen speichern'**
  String get studyLibrarySaveBookmark;

  /// No description provided for @studyLibraryRemoveBookmark.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen entfernen'**
  String get studyLibraryRemoveBookmark;

  /// No description provided for @studyLibrarySaveBookmarkFor.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen für {title} speichern'**
  String studyLibrarySaveBookmarkFor(String title);

  /// No description provided for @studyLibraryRemoveBookmarkFor.
  ///
  /// In de, this message translates to:
  /// **'Nur das Lesezeichen für {title} entfernen'**
  String studyLibraryRemoveBookmarkFor(String title);

  /// No description provided for @studyLibraryBookmarkSavedStatus.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen gespeichert. Dein Herz und alle Quellsammlungen bleiben unverändert.'**
  String get studyLibraryBookmarkSavedStatus;

  /// No description provided for @studyLibraryBookmarkRemovedStatus.
  ///
  /// In de, this message translates to:
  /// **'Lesezeichen entfernt. Dein Herz, Bücherregal, deine Wortpakete und der Wiederholungsverlauf bleiben unverändert.'**
  String get studyLibraryBookmarkRemovedStatus;

  /// No description provided for @studyLibraryBookmarkWriteBlocked.
  ///
  /// In de, this message translates to:
  /// **'Solange die Lesezeichendaten nicht verfügbar sind, können Lesezeichen nicht geändert werden. Nichts wurde überschrieben.'**
  String get studyLibraryBookmarkWriteBlocked;

  /// No description provided for @studyLibraryBookmarkWriteError.
  ///
  /// In de, this message translates to:
  /// **'Das Lesezeichen konnte nicht geändert werden. Deine vorhandenen Lerndaten wurden nicht verändert.'**
  String get studyLibraryBookmarkWriteError;

  /// No description provided for @studyLibraryStartWordReview.
  ///
  /// In de, this message translates to:
  /// **'Heutige Wort-Wiederholung öffnen'**
  String get studyLibraryStartWordReview;

  /// No description provided for @studyLibraryReviewScopeNote.
  ///
  /// In de, this message translates to:
  /// **'Dadurch öffnet sich der bestehende Wort-Wiederholungsstapel. Gespeicherte Grammatik, Sätze, Ausdrücke und Hangeul werden nicht als Wörter ausgegeben.'**
  String get studyLibraryReviewScopeNote;

  /// No description provided for @todayGuideTitle.
  ///
  /// In de, this message translates to:
  /// **'Hangul-Sori-Start-Anleitung'**
  String get todayGuideTitle;

  /// No description provided for @todayGuideDescription.
  ///
  /// In de, this message translates to:
  /// **'Die Anleitungsthemen sind passend zu deinem Lernziel sortiert, damit du mit dem Wichtigsten beginnen kannst.'**
  String get todayGuideDescription;

  /// No description provided for @todayGuideProgress.
  ///
  /// In de, this message translates to:
  /// **'{completed} von {total} Themen abgeschlossen'**
  String todayGuideProgress(int completed, int total);

  /// No description provided for @todayGuideOpenHub.
  ///
  /// In de, this message translates to:
  /// **'Vollständige App-Anleitung öffnen'**
  String get todayGuideOpenHub;

  /// No description provided for @todayGuideDismiss.
  ///
  /// In de, this message translates to:
  /// **'Start-Anleitung schließen'**
  String get todayGuideDismiss;

  /// No description provided for @todayGuideDismissedStatus.
  ///
  /// In de, this message translates to:
  /// **'Start-Anleitung geschlossen. Als Nächstes kommt dein heutiges Lernen.'**
  String get todayGuideDismissedStatus;

  /// No description provided for @homeActionLabel.
  ///
  /// In de, this message translates to:
  /// **'Zur Startseite'**
  String get homeActionLabel;

  /// No description provided for @homeActionConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Runde verlassen?'**
  String get homeActionConfirmTitle;

  /// No description provided for @homeActionConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Fortschritt in dieser Runde geht verloren, wenn du jetzt zur Startseite gehst.'**
  String get homeActionConfirmBody;

  /// No description provided for @homeActionConfirmLeave.
  ///
  /// In de, this message translates to:
  /// **'Zur Startseite'**
  String get homeActionConfirmLeave;

  /// No description provided for @homeActionConfirmStay.
  ///
  /// In de, this message translates to:
  /// **'Weiterspielen'**
  String get homeActionConfirmStay;
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
