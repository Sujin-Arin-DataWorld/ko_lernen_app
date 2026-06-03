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
  /// **'Lern Koreanisch ohne Grenzen.'**
  String get paywallSubtitle;

  /// No description provided for @paywallBenefit1.
  ///
  /// In de, this message translates to:
  /// **'Alle Vokabel-Packs (A2 · B1 · B2)'**
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
  /// **'Dein persönlicher KI-Kurs — jeden Tag neu'**
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
  /// **'Premium starten'**
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
  /// **'Premium ist aktiv. Viel Spaß! 🎉'**
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

  /// No description provided for @reviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute lernen'**
  String get reviewTitle;

  /// No description provided for @reviewEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles erledigt!'**
  String get reviewEmptyTitle;

  /// No description provided for @reviewEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für heute sind keine Karten fällig. Spiel eine Runde oder lern ein neues Pack — die Wörter tauchen hier zur Wiederholung auf.'**
  String get reviewEmptyBody;

  /// No description provided for @reviewDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Stark! 🎉'**
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
  /// **'Heute lernen'**
  String get homeReviewTitle;

  /// No description provided for @homeReviewDue.
  ///
  /// In de, this message translates to:
  /// **'{n} Wörter fällig'**
  String homeReviewDue(int n);

  /// No description provided for @homeReviewDone.
  ///
  /// In de, this message translates to:
  /// **'Heute alles wiederholt 🎉'**
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
  /// **'Der Tiger erinnert dich ans Lernen'**
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
  /// **'Der Tiger wartet — Zeit für Koreanisch! 🐯'**
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
  /// **'Knipse deine erste Lehrbuchseite — die analysierten Wörter landen hier.'**
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
  /// **'Eigene Packs'**
  String get bookshelfSectionCustomPacks;

  /// No description provided for @bookshelfTileMeta.
  ///
  /// In de, this message translates to:
  /// **'{words} Wörter · {grammar} Grammatik · {date}'**
  String bookshelfTileMeta(int words, int grammar, String date);

  /// No description provided for @bookshelfPackMeta.
  ///
  /// In de, this message translates to:
  /// **'{n} Wörter'**
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
  /// **'Custom-Pack aus dieser Seite'**
  String get bookshelfCreatePackCta;

  /// No description provided for @bookshelfCreatePackTitle.
  ///
  /// In de, this message translates to:
  /// **'Neuer Custom-Pack'**
  String get bookshelfCreatePackTitle;

  /// No description provided for @bookshelfCreatePackName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get bookshelfCreatePackName;

  /// No description provided for @bookshelfCreatePackSaved.
  ///
  /// In de, this message translates to:
  /// **'Pack gespeichert.'**
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
  /// **'Pack löschen?'**
  String get bookshelfDeletePackTitle;

  /// No description provided for @bookshelfDeletePackBody.
  ///
  /// In de, this message translates to:
  /// **'Soll \"{name}\" gelöscht werden?'**
  String bookshelfDeletePackBody(Object name);

  /// No description provided for @customPackPlayTitle.
  ///
  /// In de, this message translates to:
  /// **'Custom-Pack üben'**
  String get customPackPlayTitle;

  /// No description provided for @customPackNotFoundTitle.
  ///
  /// In de, this message translates to:
  /// **'Pack nicht gefunden'**
  String get customPackNotFoundTitle;

  /// No description provided for @customPackNotFoundBody.
  ///
  /// In de, this message translates to:
  /// **'Möglicherweise wurde es gelöscht.'**
  String get customPackNotFoundBody;

  /// No description provided for @customPackEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Pack ist leer'**
  String get customPackEmptyTitle;

  /// No description provided for @customPackEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Pack enthält noch keine Wörter.'**
  String get customPackEmptyBody;

  /// No description provided for @customPackResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Geschafft'**
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
  /// **'Knipsen → Wörter & Grammatik'**
  String get homeBookCardDesc;

  /// No description provided for @homeBookshelfCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Bücherregal'**
  String get homeBookshelfCardTitle;

  /// No description provided for @homeBookshelfCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Seiten & Custom-Packs'**
  String get homeBookshelfCardDesc;

  /// No description provided for @homeQuestsCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Quests'**
  String get homeQuestsCardTitle;

  /// No description provided for @homeQuestsCardDesc.
  ///
  /// In de, this message translates to:
  /// **'Mehr Hanok-Dekoration freischalten'**
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

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In de, this message translates to:
  /// **'URL kopieren'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsPrivacyCopied.
  ///
  /// In de, this message translates to:
  /// **'URL kopiert: {url}'**
  String settingsPrivacyCopied(Object url);

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
  /// **'Schöne Übung — bleib bei Stufe {level}.'**
  String chosungRoundKeepLevel(Object level);

  /// No description provided for @chosungRoundReview.
  ///
  /// In de, this message translates to:
  /// **'Übe Stufe {level} ruhig nochmal.'**
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

  /// Tagesziel Chip — N neue Karten + M Wiederholungen (Phase 1 SRS-UX-Patch, stately-rising-jongga).
  ///
  /// In de, this message translates to:
  /// **'🔥 Heute ({newCount} neu · {reviewCount} Wdh.)'**
  String vocabTodayBadge(int newCount, int reviewCount);

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

  /// No description provided for @vocabPacksTitle.
  ///
  /// In de, this message translates to:
  /// **'Vokabel-Packs'**
  String get vocabPacksTitle;

  /// No description provided for @vocabPacksLevelMenu.
  ///
  /// In de, this message translates to:
  /// **'Level wechseln'**
  String get vocabPacksLevelMenu;

  /// No description provided for @vocabPacksProgressLabel.
  ///
  /// In de, this message translates to:
  /// **'{cleared}/{total} Packs geklärt'**
  String vocabPacksProgressLabel(int cleared, int total);

  /// No description provided for @vocabPacksEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Packs'**
  String get vocabPacksEmptyTitle;

  /// No description provided for @vocabPacksEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Level sind noch keine Vokabeln vorbereitet.'**
  String get vocabPacksEmptyBody;

  /// No description provided for @vocabPackLockedNoPrev.
  ///
  /// In de, this message translates to:
  /// **'🔒 Dieses Pack ist noch gesperrt.'**
  String get vocabPackLockedNoPrev;

  /// No description provided for @vocabPackLockedHint.
  ///
  /// In de, this message translates to:
  /// **'🔒 Schaffe zuerst \"{prev}\" mit ≥ 70 % Bossen.'**
  String vocabPackLockedHint(Object prev);

  /// No description provided for @bookCaptureTitle.
  ///
  /// In de, this message translates to:
  /// **'Buchseite einlesen'**
  String get bookCaptureTitle;

  /// No description provided for @bookCaptureHero.
  ///
  /// In de, this message translates to:
  /// **'Knipse eine Lehrbuchseite'**
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
  /// **'Kein Koreanisch erkannt — bitte eine deutlichere Aufnahme.'**
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
  /// **'{count} Textblöcke erkannt — bei Bedarf korrigieren.'**
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

  /// No description provided for @bookResultAnalyzing.
  ///
  /// In de, this message translates to:
  /// **'Wörter & Grammatik werden untersucht …'**
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
  /// **'Schließe Vokabelpakete ab, um Dancheong-Stempel zu sammeln.'**
  String get dojangEmptyBody;

  /// No description provided for @dojangProgress.
  ///
  /// In de, this message translates to:
  /// **'{earned} von {total} Stempeln gesammelt'**
  String dojangProgress(int earned, int total);

  /// No description provided for @bookResultOfflineNotice.
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar — nur Grammatikmuster offline erkannt.'**
  String get bookResultOfflineNotice;

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
  /// **'Beginne ein Pack — die ersten Quest-Fortschritte erscheinen hier.'**
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
  /// **'Geklärt'**
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

  /// No description provided for @hanokCinematicIntro.
  ///
  /// In de, this message translates to:
  /// **'Dein Hanok wächst —'**
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
  /// **'Pack-Übung'**
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
  /// **'🎉 Pack geklärt!'**
  String get vocabPackResultCleared;

  /// No description provided for @vocabPackResultClearedAgain.
  ///
  /// In de, this message translates to:
  /// **'Bereits geklärt — gut wiederholt!'**
  String get vocabPackResultClearedAgain;

  /// No description provided for @vocabPackResultRetry.
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft — nochmal probieren!'**
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
  /// **'Zurück zu den Packs'**
  String get vocabPackResultBackToGrid;

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
  /// **'Dadurch wird das Cloud-Backup für das aktuelle Firebase-Konto gelöscht. Lokale Fortschritte auf diesem Gerät werden nicht gelöscht.'**
  String get settingsCloudDeleteDataConfirmBody;

  /// No description provided for @settingsCloudDeleteDataSuccess.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Daten gelöscht'**
  String get settingsCloudDeleteDataSuccess;

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
  /// **'Dadurch werden dein Firebase-Konto, die Google-Verknüpfung, das Firestore-Cloud-Backup und lokale Lerndaten auf diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden. Google kann dich zur Bestätigung erneut anmelden lassen.'**
  String get settingsAccountDeleteConfirmBody;

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
  /// **'Info-URL zur Löschung kopieren'**
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

  /// No description provided for @onboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ist dein Level?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wir fangen bei dir an. Frühere Levels bleiben offen, spätere schaltest du frei.'**
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
  /// **'Tippe dein Level — du kannst es in den Einstellungen ändern.'**
  String get onboardingPrompt;

  /// No description provided for @onboardingTigerGreeting.
  ///
  /// In de, this message translates to:
  /// **'환영해요!\n어떤 레벨부터 시작할까요?'**
  String get onboardingTigerGreeting;

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
  /// **'Sollen wir 5 Minuten lernen? 📖'**
  String get homeTigerBubbleStart;

  /// No description provided for @homeTigerBubbleStreak.
  ///
  /// In de, this message translates to:
  /// **'Streak hält! Weiter so 🔥'**
  String get homeTigerBubbleStreak;

  /// No description provided for @homeTigerBubbleResume.
  ///
  /// In de, this message translates to:
  /// **'Willkommen zurück!'**
  String get homeTigerBubbleResume;

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
  /// **'Erreiche {level} um freizuschalten'**
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
  /// **'Wir bereiten neue Szenarien mit Sorgfalt vor.'**
  String get scenariosEmptyBody;

  /// No description provided for @scenariosLoadFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Hmm, etwas ist schiefgelaufen'**
  String get scenariosLoadFailedTitle;

  /// No description provided for @statsFirstEntryTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Reise beginnt'**
  String get statsFirstEntryTitle;

  /// No description provided for @statsFirstEntryBody.
  ///
  /// In de, this message translates to:
  /// **'Starte ein Szenario — danach füllt sich diese Seite mit deinem Fortschritt.'**
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
  /// **'Lerne wie ein Koreaner lebt — Café, Flughafen, Vorstellung…'**
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
  /// **'Los geht\'s'**
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
  /// **'{count} Wörter geübt'**
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
  /// **'Noch keine — schließe Szenarien ab! 🚀'**
  String get statsNoBadges;

  /// No description provided for @homeRecommended.
  ///
  /// In de, this message translates to:
  /// **'Heute empfohlen ✨'**
  String get homeRecommended;

  /// No description provided for @homeAllDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Szenarien geschafft! 🎉'**
  String get homeAllDone;

  /// No description provided for @homeNoScenario.
  ///
  /// In de, this message translates to:
  /// **'Bald gibt es Szenarien für dein Level'**
  String get homeNoScenario;

  /// No description provided for @homeGreetingLearn.
  ///
  /// In de, this message translates to:
  /// **'Lerne Koreanisch wie ein Local'**
  String get homeGreetingLearn;

  /// No description provided for @homeTodaySection.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get homeTodaySection;

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
  /// **'1 Min nachzeichnen'**
  String get dailyCharSubtitle;

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
  /// **'{n} Tage gesamt'**
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
  /// **'⭐ {n}'**
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
  /// **'Noch keine Favoriten ⭐\nMarkiere schwierige Wörter mit dem Stern'**
  String get vocabEmptyFavorites;

  /// No description provided for @listeningTitle.
  ///
  /// In de, this message translates to:
  /// **'Hören'**
  String get listeningTitle;

  /// No description provided for @listeningSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Hör ein Szenario in echtem Tempo'**
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
  /// **'Wähle oben ein Szenario aus, um zu starten.'**
  String get listeningPickFirst;

  /// No description provided for @listeningEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Szenarien'**
  String get listeningEmptyTitle;

  /// No description provided for @listeningEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Sobald neue Szenarien geladen sind, kannst du sie hier anhören.'**
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

  /// No description provided for @kkeunmariNotInPool.
  ///
  /// In de, this message translates to:
  /// **'Kenn ich noch nicht — versuch ein anderes 🐯'**
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
  /// **'한방단어 — die Kette endet hier'**
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
  /// **'Du hast {n} Wörter verkettet.'**
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
  /// **'Pack teilen'**
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
  /// **'Dieser Pack hat keine Wörter.'**
  String get shareEmpty;

  /// No description provided for @sharePackBody.
  ///
  /// In de, this message translates to:
  /// **'Ich teile mit dir den Vokabel-Pack „{name}“ ({count} Wörter) aus Hangul Sori! Gib in der App den Code {code} ein, um ihn zu importieren. hangul-sori.com'**
  String sharePackBody(Object name, int count, Object code);

  /// No description provided for @redeemTooltip.
  ///
  /// In de, this message translates to:
  /// **'Mit Code importieren'**
  String get redeemTooltip;

  /// No description provided for @redeemTitle.
  ///
  /// In de, this message translates to:
  /// **'Pack importieren'**
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
  /// **'„{name}“ importiert ({count} Wörter)'**
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
  /// **'Füge dein erstes Wort hinzu — oder lass die Übersetzung automatisch ausfüllen.'**
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
  /// **'Auto-Ausfüllen gerade nicht verfügbar — bitte manuell eintragen.'**
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
  /// **'{count} Wörter importiert'**
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
  /// **'Schwierige Wörter'**
  String get hardWordsTitle;

  /// No description provided for @hardWordsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'{count} Wörter wollen einfach nicht sitzen'**
  String hardWordsSubtitle(int count);

  /// No description provided for @hardWordsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Sorgenkinder 🎉'**
  String get hardWordsEmptyTitle;

  /// No description provided for @hardWordsEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Im Moment gibt es keine besonders schwierigen Wörter. Lern weiter — falls eins hakt, taucht es hier auf.'**
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
  /// **'Tippe ein koreanisches Wort, dann seine Bedeutung.'**
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
  /// **'{count} Wörter'**
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
  /// **'{count}er-Combo! 🔥'**
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
  /// **'Dein Hof wächst mit jedem gemeisterten Pack.'**
  String get pathHanokSub;

  /// No description provided for @pathLevelPacks.
  ///
  /// In de, this message translates to:
  /// **'{done}/{total} Packs'**
  String pathLevelPacks(int done, int total);

  /// No description provided for @pathNodeNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get pathNodeNow;

  /// No description provided for @pathLockedHint.
  ///
  /// In de, this message translates to:
  /// **'Schließe zuerst das vorherige Pack ab.'**
  String get pathLockedHint;

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
  /// **'Eine kurze Lektion reicht, um dranzubleiben.'**
  String get notifStreakSaverBody;

  /// No description provided for @notifDailyStreakBody.
  ///
  /// In de, this message translates to:
  /// **'🔥 {days} Tage am Stück — heute weiter?'**
  String notifDailyStreakBody(int days);

  /// No description provided for @ttsListen.
  ///
  /// In de, this message translates to:
  /// **'Aussprache'**
  String get ttsListen;
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
