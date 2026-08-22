// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get paywallTitle => 'Hangul Sori Premium';

  @override
  String get paywallSubtitle => 'Learn Korean whenever you want.';

  @override
  String get paywallBenefit1 => 'All vocabulary packs (A2 · B1 · B2)';

  @override
  String get paywallBenefit2 => 'All conversation scenarios';

  @override
  String get paywallBenefit3 => 'Unlimited reviews (SRS)';

  @override
  String get paywallBenefit4 =>
      'Your personal AI course with new content every day';

  @override
  String get paywallBenefit5 => 'Book snapshot without a daily limit';

  @override
  String get paywallPriceFallback => '€5 / month';

  @override
  String get paywallPricePerMonth => '/ month';

  @override
  String get paywallEyebrow => 'Premium';

  @override
  String get paywallCtaStart => 'Unlock Premium';

  @override
  String get paywallCtaRestore => 'Restore purchases';

  @override
  String get paywallClose => 'Maybe later';

  @override
  String get paywallLegal =>
      'Cancel anytime. The subscription renews automatically until you cancel.';

  @override
  String get paywallNotAvailable =>
      'Subscriptions aren\'t available in this build yet.';

  @override
  String get paywallProcessing => 'One moment…';

  @override
  String get paywallSuccess => 'Premium is active. Enjoy!';

  @override
  String get paywallFailed => 'Purchase not completed.';

  @override
  String get paywallRestoreNone => 'No previous purchases found.';

  @override
  String get paywallRestoreFailed =>
      'Purchases could not be restored. Try again.';

  @override
  String streakDisplay(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get streakDialogTitle => 'Keep your streak alive';

  @override
  String get streakDialogSubtitle => 'Learn every day and build your streak.';

  @override
  String get streakDialogEarned => 'Streaks unlock rewards';

  @override
  String streakDialogCurrent(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Current streak: $_temp0';
  }

  @override
  String streakDialogLastActivity(Object time) {
    return 'Last activity: $time';
  }

  @override
  String get streakDialogLearnNow => 'Learn now';

  @override
  String get characterSelectionTitle => 'Who\'s your study buddy?';

  @override
  String get companionNoneName => 'No learning companion';

  @override
  String get companionNoneDescription =>
      'You can choose Taego or Joy at any time later.';

  @override
  String get companionNeutralThinking => 'Preparing the next round…';

  @override
  String get homeMagpieBubbleStart => 'Let\'s take it one character at a time.';

  @override
  String get homeMagpieBubbleResume =>
      'Good to see you. Shall we review a little first?';

  @override
  String get homeLearnNowCtaMagpie => 'Continue calmly';

  @override
  String get homeFirstWeekTitle => 'Your first week';

  @override
  String get characterNameTiger => '태고';

  @override
  String get characterRomanTiger => 'Taego';

  @override
  String get characterTraitTiger => 'Reliable & brave';

  @override
  String get characterDescTiger =>
      'In Korean folk art, the tiger is the lord of the mountains. Taego is calm and steadfast. He stays by your side when learning gets difficult.';

  @override
  String get characterNameMagpie => '조이';

  @override
  String get characterRomanMagpie => 'Joy';

  @override
  String get characterTraitMagpie => 'Cheerful & lively';

  @override
  String get characterDescMagpie =>
      'In Korea, the magpie is a bird of good luck that brings happy news. Joy celebrates your progress and keeps lessons light.';

  @override
  String get characterSelectedTiger => 'You chose Taego.';

  @override
  String get characterSelectedMagpie => 'You chose Joy.';

  @override
  String get characterSelectionHint => 'Tap your study buddy';

  @override
  String get reviewTitle => 'Today\'s review';

  @override
  String get reviewEmptyTitle => 'All done!';

  @override
  String get reviewEmptyBody =>
      'No cards are due today. Play a game or learn a new pack. Those words will return here for review.';

  @override
  String get reviewDoneTitle => 'Nice work!';

  @override
  String get reviewDoneBody => 'You\'ve reviewed your due cards.';

  @override
  String get reviewBonusLabel => 'Phrase of the day';

  @override
  String get homeReviewTitle => 'Today\'s review';

  @override
  String homeReviewDue(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n words due',
      one: '1 word due',
    );
    return '$_temp0';
  }

  @override
  String get homeReviewDone => 'All reviewed today';

  @override
  String get settingsNotifSection => 'Reminder';

  @override
  String get settingsNotifTitle => 'Daily reminder';

  @override
  String get settingsNotifSubtitle => 'Taego reminds you to study';

  @override
  String get settingsNotifTime => 'Time';

  @override
  String get settingsNotifDenied =>
      'Notifications are disabled. Enable them in system settings.';

  @override
  String get notificationTitle => 'Hangul Sori';

  @override
  String get notificationBody =>
      'Taego is ready when you are. Time for Korean! 🐯';

  @override
  String get homeCourseTitle => 'Your daily course';

  @override
  String get homeCourseDesc => 'Built around your weak spots and interests';

  @override
  String get settingsInterestsTitle => 'Interests';

  @override
  String get settingsInterestsSubtitle => 'Topics for your daily course';

  @override
  String get interestsSheetTitle => 'What are you into?';

  @override
  String get interestEveryday => 'Everyday';

  @override
  String get interestFoodShopping => 'Food & shopping';

  @override
  String get interestWorkStudy => 'Work & study';

  @override
  String get interestTravel => 'Travel & transport';

  @override
  String get interestFeelingsPeople => 'Feelings & people';

  @override
  String get interestHealthBody => 'Health & body';

  @override
  String get smalltalkTitle => 'Small talk';

  @override
  String get smalltalkEmpty => 'No phrases for this selection.';

  @override
  String get smalltalkReply => 'Sample answer';

  @override
  String get smalltalkPickCategory => 'Choose a topic';

  @override
  String get homeSmalltalkCardTitle => 'Small talk';

  @override
  String get homeSmalltalkCardDesc => 'Conversation starters by topic';

  @override
  String get appTitle => 'Learn Korean';

  @override
  String get welcomeMsg => 'Hi! You\'ve got this today 💪';

  @override
  String get footerCheer => 'Keep going. You\'ve got this. 🌟';

  @override
  String get sectionModules => 'Modules';

  @override
  String get sectionGames => 'Games';

  @override
  String get sectionStats => 'Statistics';

  @override
  String get moduleHangulTitle => 'Hangul';

  @override
  String get moduleHangulDesc => '14 consonants + 10 vowels';

  @override
  String get moduleVocabTitle => 'Vocabulary';

  @override
  String get moduleVocabDesc => '1,188 cards · A1 → C2 · TTS';

  @override
  String get moduleGrammarTitle => 'Grammar';

  @override
  String get moduleGrammarDesc => '176 patterns · A1 → C2';

  @override
  String get moduleListenTitle => 'Listening';

  @override
  String get moduleListenDesc => 'Hear and understand sentences';

  @override
  String get gameChosungTitle => 'Initial Quiz';

  @override
  String get gameChosungDesc => 'Guess the word from its initial consonants';

  @override
  String get gameWordleTitle => 'Syllable Puzzle';

  @override
  String get gameWordleDesc => '2-3 syllables · 6 tries';

  @override
  String get navVocab => 'Vocab';

  @override
  String get navGrammar => 'Grammar';

  @override
  String get navListen => 'Listening';

  @override
  String get navHangul => 'Hangul';

  @override
  String get navChosung => 'Initial Quiz';

  @override
  String get navWordle => 'Syllable Puzzle';

  @override
  String get navSettings => 'Settings';

  @override
  String get navStats => 'Stats';

  @override
  String get btnHoeren => 'Listen';

  @override
  String get btnSkip => 'Skip';

  @override
  String get btnSubmit => 'Check';

  @override
  String get btnNext => 'Next';

  @override
  String get btnPrev => 'Back';

  @override
  String get legacyVocabPrevious => 'Previous card';

  @override
  String get btnRandom => 'Random';

  @override
  String get btnGewusst => 'Got it!';

  @override
  String get btnNichtGewusst => 'Didn\'t know';

  @override
  String get btnNewGame => 'New game';

  @override
  String get btnConfirm => 'OK';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnRetry => 'Try again';

  @override
  String get btnClose => 'Close';

  @override
  String get btnApply => 'Apply';

  @override
  String get btnPlay => 'Play';

  @override
  String get btnDelete => 'Delete';

  @override
  String get gameLoading => 'Preparing game…';

  @override
  String gameRoundProgress(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String get bookshelfTitle => 'My bookshelf';

  @override
  String get bookshelfAddPage => 'Add page';

  @override
  String get bookshelfEmptyTitle => 'No pages yet';

  @override
  String get bookshelfEmptyBody =>
      'Snap your first textbook page. Detected words will appear here.';

  @override
  String get bookshelfEmptyCta => 'Snap a page';

  @override
  String get bookshelfEmptyPreview => 'Empty page';

  @override
  String get bookshelfSectionPages => 'Pages';

  @override
  String get bookshelfSectionCustomPacks => 'Custom packs';

  @override
  String bookshelfTileMeta(int words, int grammar, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words words',
      one: '1 word',
    );
    return '$_temp0 · $grammar grammar · $date';
  }

  @override
  String bookshelfPackMeta(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get bookshelfPageTitle => 'Page';

  @override
  String get bookshelfPageNotFoundTitle => 'Page not found';

  @override
  String get bookshelfPageNotFoundBody => 'It may have been deleted.';

  @override
  String get bookshelfCreatePackCta => 'Create a custom pack from this page';

  @override
  String get bookshelfCreatePackTitle => 'New custom pack';

  @override
  String get bookshelfCreatePackName => 'Name';

  @override
  String bookshelfDefaultPackName(Object date) {
    return 'Pack $date';
  }

  @override
  String get bookshelfCreatePackSaved => 'Pack saved.';

  @override
  String get bookshelfDeletePageTitle => 'Delete page?';

  @override
  String get bookshelfDeletePageBody => 'The page will be permanently removed.';

  @override
  String get bookshelfDeletePackTitle => 'Delete pack?';

  @override
  String bookshelfDeletePackBody(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get customPackPlayTitle => 'Custom pack practice';

  @override
  String get customPackNotFoundTitle => 'Pack not found';

  @override
  String get customPackNotFoundBody => 'It may have been deleted.';

  @override
  String get customPackEmptyTitle => 'Pack is empty';

  @override
  String get customPackEmptyBody => 'This pack has no words yet.';

  @override
  String get customPackResultTitle => 'Done';

  @override
  String get customPackResultDone => 'All cards done!';

  @override
  String customPackResultStats(int learned, int total) {
    return '$learned of $total marked as known';
  }

  @override
  String get customPackResultAgain => 'Go again';

  @override
  String get customPackResultBack => 'Back to bookshelf';

  @override
  String get homeBookCardTitle => 'Book page';

  @override
  String get homeBookCardDesc => 'Snap → words & grammar';

  @override
  String get homeBookshelfCardTitle => 'My bookshelf';

  @override
  String get homeBookshelfCardDesc => 'Saved pages & custom packs';

  @override
  String get homeQuestsCardTitle => 'Quests';

  @override
  String get homeQuestsCardDesc => 'Unlock more hanok decorations';

  @override
  String get settingsBookEndpointSection => 'Cloud analysis endpoint';

  @override
  String get settingsBookEndpointHint =>
      'Cloud Function URL (DeepL + OKT). Empty = offline grammar only.';

  @override
  String get settingsBookEndpointSave => 'Save';

  @override
  String get settingsBookEndpointSaved => 'Endpoint saved.';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterLevel => 'Level';

  @override
  String get filterTheme => 'Topic';

  @override
  String get filterType => 'Type';

  @override
  String get filterDifficulty => 'Difficulty';

  @override
  String get filterDirection => 'Front shows';

  @override
  String get filterAll => 'All';

  @override
  String get filterDirKoDe => '🇰🇷 Korean → 🇩🇪 German';

  @override
  String get filterDirDeKo => '🇩🇪 German → 🇰🇷 Korean';

  @override
  String get emptyVocab =>
      'No words match this filter.\nAdjust your selection.';

  @override
  String get emptyGrammar => 'No patterns match this filter.';

  @override
  String get loadingVocab => 'Loading vocabulary…';

  @override
  String get loadingGrammar => 'Loading grammar…';

  @override
  String get hintTapToFlip => 'Tap to flip';

  @override
  String get hintTapForExplanation => 'Tap for explanation';

  @override
  String get chosungQuestion => 'Which word?';

  @override
  String get chosungInputHint => 'Type in Korean…';

  @override
  String get chosungShowHint => 'Listen (hint)';

  @override
  String get chosungCorrect => '✓ Correct!';

  @override
  String get chosungAnswer => 'Answer';

  @override
  String get chosungEmptyBody =>
      'No suitable words are ready for this learning level yet.';

  @override
  String get chosungBackspace => 'Delete last character';

  @override
  String chosungCorrectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correct answers',
      one: '1 correct answer',
    );
    return '$_temp0';
  }

  @override
  String chosungWrongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wrong answers',
      one: '1 wrong answer',
    );
    return '$_temp0';
  }

  @override
  String get chosungPadHiddenNote =>
      'From B1 onwards, there is no key helper. Type the word with your Korean keyboard.';

  @override
  String get wordleHowTitle => 'How to play';

  @override
  String get wordleHowIntro =>
      'Guess the Korean word in 6 tries. The colors give clues.';

  @override
  String get wordleHowExact => 'Exact';

  @override
  String get wordleHowExactDesc => 'Letter in the right position';

  @override
  String get wordleHowWrong => 'Wrong spot';

  @override
  String get wordleHowWrongDesc => 'Letter is in the word, but not here';

  @override
  String get wordleHowAbsent => 'Not in word';

  @override
  String get wordleHowAbsentDesc => 'Letter is not in the word';

  @override
  String get wordleHowOutro =>
      'A new word every day.\nUse shuffle for a random one.';

  @override
  String wordleErrorLength(int n) {
    return 'Please enter $n syllables';
  }

  @override
  String get wordleErrorHangul => 'Hangul only, please';

  @override
  String get wordleResultWin => 'You got it!';

  @override
  String get wordleResultLose => '😢 Out of tries';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System language';

  @override
  String get settingsLanguageDe => 'Deutsch';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsTtsRate => 'Speech speed';

  @override
  String get ttsSpeedLabel => 'Speed';

  @override
  String ttsSpeedChip(String speed) {
    return '$speed×';
  }

  @override
  String get ttsSpeedSheetTitle => 'Speech speed';

  @override
  String get settingsSoundSection => 'Sound';

  @override
  String get settingsSoundMaster => 'Sound';

  @override
  String get settingsSoundMasterDesc => 'Turns all app sounds on or off';

  @override
  String get settingsSoundMasterVolume => 'Overall volume';

  @override
  String get settingsSoundGame => 'Game feedback';

  @override
  String get settingsSoundGameDesc => 'Correct, wrong, combo, level-up';

  @override
  String get settingsSoundCompanion => 'Study buddies';

  @override
  String get settingsSoundCompanionDesc =>
      'Tiger and magpie: greetings and cheers';

  @override
  String get settingsSoundAmbience => 'Background ambience';

  @override
  String get settingsSoundAmbienceDesc =>
      'Quiet Hanok atmosphere on some screens';

  @override
  String get settingsSoundCinematic => 'Intro on launch';

  @override
  String get settingsSoundCinematicDesc =>
      'The sound of the gate when the app opens';

  @override
  String get settingsSoundSpeech => 'Korean pronunciation';

  @override
  String get settingsSoundSpeechDesc => 'Reads Korean words aloud';

  @override
  String get settingsSoundSpeechWarn =>
      'Without this sound you won\'t hear any pronunciation';

  @override
  String get settingsSoundDuck => 'Quieter during pronunciation';

  @override
  String get settingsSoundDuckDesc =>
      'Background sounds get quieter while Korean is being read';

  @override
  String get settingsSoundRespectSilent => 'Respect silent mode';

  @override
  String get settingsSoundRespectSilentDesc =>
      'No sound while the device is muted';

  @override
  String get settingsReset => 'Reset all data';

  @override
  String get settingsResetConfirm =>
      'Really delete all learning progress? This cannot be undone.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(Object v) {
    return 'Version $v';
  }

  @override
  String get settingsPrivacyTitle => 'Privacy Policy';

  @override
  String get settingsPrivacySubtitle => 'Copy link';

  @override
  String settingsPrivacyCopied(Object url) {
    return 'Link copied: $url';
  }

  @override
  String get settingsPrivacySection => 'Privacy';

  @override
  String get settingsAnalyticsTitle => 'Usage statistics';

  @override
  String get settingsAnalyticsDesc =>
      'Share anonymous app usage (Firebase Analytics)';

  @override
  String get settingsCrashTitle => 'Crash reports';

  @override
  String get settingsCrashDesc => 'Helps us fix bugs faster (Crashlytics)';

  @override
  String get settingsTermsTitle => 'Terms of Service';

  @override
  String get settingsImpressumTitle => 'Legal Notice (Impressum)';

  @override
  String get settingsLicensesTitle => 'Open-source licenses';

  @override
  String get settingsLicensesSubtitle => 'Bundled libraries';

  @override
  String get settingsDataSourcesTitle => 'Data sources';

  @override
  String get settingsDataSourcesSubtitle =>
      'Dictionaries, frequency lists, translations';

  @override
  String get settingsDataSourcesIntro =>
      'This app\'s content is built on publicly available language data. Each source is listed below with its license and attribution.';

  @override
  String get settingsDataLicenseNote => 'CC BY-SA 2.0 KR Notice';

  @override
  String get settingsDataLicenseBody =>
      'Korean dictionary data (definitions, translations) is sourced from 우리말샘 (National Institute of Korean Language) under CC BY-SA 2.0 KR. Derivative content (such as the JSON files bundled with this app) is shared under the same license.';

  @override
  String get statsHeader => 'Your progress';

  @override
  String get statsCardsLearned => 'Cards learned';

  @override
  String get statsAccuracy => 'Accuracy';

  @override
  String get statsStreak => 'Streak';

  @override
  String get statsBestStreak => 'Best streak';

  @override
  String get statsStreakShield => 'Streak shield';

  @override
  String get statsStreakShieldHint => 'Shields one missed day.';

  @override
  String get statsWordleWins => 'Syllable Puzzle wins';

  @override
  String get statsWordleStreak => 'Syllable Puzzle streak';

  @override
  String get screenVocabTitle => 'Vocabulary';

  @override
  String get screenGrammarTitle => 'Grammar';

  @override
  String get screenWordleTitle => 'Syllable Puzzle';

  @override
  String get silbenEmptyBody =>
      'No syllable puzzles are ready for your learning level yet.';

  @override
  String get screenHangulTitle => 'Hangul';

  @override
  String get filterOpenBtn => 'Open filter';

  @override
  String get hangulTabOverview => 'Overview';

  @override
  String get hangulTabCards => 'Cards';

  @override
  String get hangulTabWrite => 'Writing';

  @override
  String get hangulConsonantsLabel => '자음 · Consonants';

  @override
  String get hangulVowelsLabel => '모음 · Vowels';

  @override
  String get hangulSyllableLabel => '🧩 음절 구조 · Syllable composition';

  @override
  String get hangulPronounceBtn => 'Pronounce';

  @override
  String get hangulRulesTitle => 'Hangul writing rules';

  @override
  String get hangulRulesBody =>
      '① Top → Bottom   ② Horizontal → Vertical   ③ Left → Right';

  @override
  String get hangulStrokeOrderTitle => '📽 Stroke order (tap to replay)';

  @override
  String get hangulTraceTitle => 'Trace with your finger';

  @override
  String get hangulClearBtn => 'Clear';

  @override
  String hangulPronounceLetter(Object letter) {
    return 'Pronounce $letter';
  }

  @override
  String get hangulChipConsonants => 'Consonants';

  @override
  String get hangulChipVowels => 'Vowels';

  @override
  String get hangulChipSyllables => 'Syllables';

  @override
  String get hangulCheckModeLabel => 'Stroke check';

  @override
  String get hangulCheckModePractice => 'Free practice';

  @override
  String get hangulCheckModeExam => 'Strict';

  @override
  String get hangulCheckModePracticeHint =>
      'You get hints, but nothing is erased.';

  @override
  String get hangulCheckModeExamHint =>
      'Order and direction both have to be right.';

  @override
  String hangulStrokeProgress(int current, int total) {
    return 'Stroke $current / $total';
  }

  @override
  String hangulStrokeNextHint(int index) {
    return 'Now draw stroke $index.';
  }

  @override
  String hangulStrokeWrongOrder(int drawn, int expected) {
    return 'That is stroke $drawn. Draw stroke $expected first.';
  }

  @override
  String hangulStrokeWrongDirection(int index) {
    return 'Right line, wrong direction. Stroke $index goes the other way.';
  }

  @override
  String hangulStrokeWrongShape(int index) {
    return 'That does not match any stroke. Look at stroke $index on the left.';
  }

  @override
  String get hangulStrokeTooShort =>
      'Too short. Draw the stroke in one motion.';

  @override
  String hangulStrokeLetterDone(Object letter) {
    return '$letter is done! On to the next one.';
  }

  @override
  String hangulLettersDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count letters done',
      one: '1 letter done',
    );
    return '$_temp0';
  }

  @override
  String get hangulHardOnly => 'Difficult only';

  @override
  String get chosungModeWithVowels => 'Initial + vowel';

  @override
  String get chosungModeInitialsOnly => 'Initials only';

  @override
  String get chosungSlotVowel => 'Vowel';

  @override
  String get chosungSlotBatchim => 'Batchim';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String questTypeUnsupported(Object type) {
    return 'Quest type \"$type\" is not available yet.';
  }

  @override
  String get customPackCsvHint => '안녕하세요, hello\\n사과, apple';

  @override
  String get packStateLocked => 'locked';

  @override
  String get packStatePremium => 'Premium';

  @override
  String get packStateCleared => 'cleared';

  @override
  String get packStateAvailable => 'available';

  @override
  String packSemantics(Object title, Object state, int learned, int total) {
    return 'Pack $title, $state, $learned of $total learned';
  }

  @override
  String get packLockedHintShort => 'Unlock first';

  @override
  String smalltalkUseWith(Object context) {
    return 'Use with: $context';
  }

  @override
  String get smalltalkSaferAlternativeAndNext =>
      'Safer alternative and next turn';

  @override
  String get smalltalkSaferAlternative => 'Safer alternative';

  @override
  String get smalltalkNextTurn => 'Next turn';

  @override
  String wordleSyllableCount(int n) {
    return '$n-syllable word · 6 tries';
  }

  @override
  String wordleMeaning(Object german) {
    return 'Meaning: $german';
  }

  @override
  String wordleAnswerLabel(Object target) {
    return 'Answer: $target';
  }

  @override
  String wordleInputHint(int n) {
    return '$n syllables…';
  }

  @override
  String get wordleLegendCorrect => 'Right spot';

  @override
  String get wordleLegendPresent => 'Wrong spot';

  @override
  String get wordleLegendAbsent => 'Not in word';

  @override
  String get wordleSubmitBtn => 'Submit';

  @override
  String get wordleNewWordBtn => 'New word';

  @override
  String get wordleHelpTooltip => 'How to play';

  @override
  String get wordleShuffleTooltip => 'New word';

  @override
  String get settingsAdsSection => 'Ads';

  @override
  String get settingsShowAds => 'Show ads';

  @override
  String get settingsShowAdsDesc => 'Helps keep the app running';

  @override
  String get placeholderComingSoon => 'Coming soon 🚧';

  @override
  String get chosungSubmitBtn => 'Confirm';

  @override
  String get chosungHintBtn => 'Hint';

  @override
  String chosungAnswerLabel(Object word) {
    return 'Answer: $word';
  }

  @override
  String get chosungRoundDoneTitle => 'Round complete!';

  @override
  String chosungRoundAccuracy(int percent) {
    return '$percent% correct';
  }

  @override
  String chosungRoundAvgTime(Object seconds) {
    return 'Avg ${seconds}s per question';
  }

  @override
  String get chosungRoundContinue => 'Keep going';

  @override
  String chosungRoundLevelUp(Object level) {
    return 'Awesome! Try level $level.';
  }

  @override
  String chosungRoundKeepLevel(Object level) {
    return 'Nice work. Stay on level $level for now.';
  }

  @override
  String chosungRoundReview(Object level) {
    return 'No worries. Give level $level another try.';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsSubtitle => 'Your learning progress';

  @override
  String get statsDays => 'Days';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsCards => 'Cards';

  @override
  String get statsPercent => 'Accuracy';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsEmpty =>
      'No data yet. Start with your first practice session. 🚀';

  @override
  String get statsVokSection => 'Vocabulary';

  @override
  String get statsGamesSection => 'Games';

  @override
  String get statsStreakSection => 'Streak';

  @override
  String statsBestLabel(int n) {
    return 'Best: $n';
  }

  @override
  String get vocabModeAll => 'All';

  @override
  String get vocabModeDue => 'Due today';

  @override
  String vocabDueBadge(int n) {
    return '$n due';
  }

  @override
  String vocabTodayBadge(int newCount, int reviewCount) {
    return 'Today ($newCount new · $reviewCount review)';
  }

  @override
  String get vocabDueEmpty => 'All done for today!\nCome back tomorrow.';

  @override
  String get vocabDueEmptyAction => 'Practice anyway';

  @override
  String get vocabPacksTitle => 'Vocab packs';

  @override
  String get vocabPacksLevelMenu => 'Switch level';

  @override
  String get vocabPacksScopedHint => 'Only packs for your current mission.';

  @override
  String get vocabPacksBrowseAllCta => 'Browse all vocab packs';

  @override
  String vocabPacksProgressLabel(int cleared, int total) {
    return '$cleared/$total packs cleared';
  }

  @override
  String get vocabPacksEmptyTitle => 'No packs yet';

  @override
  String get vocabPacksEmptyBody =>
      'No vocabulary prepared for this level yet.';

  @override
  String get vocabPackLockedNoPrev => 'This pack is still locked.';

  @override
  String vocabPackLockedHint(Object prev) {
    return 'Clear \"$prev\" first with ≥ 70% on bosses.';
  }

  @override
  String get bookCaptureTitle => 'Snap a page';

  @override
  String get bookCaptureHero => 'Snap a textbook page';

  @override
  String get bookCaptureSubtitle =>
      'Keep the page straight, sharp, and tightly cropped. The image stays on your device; only extracted text is analyzed.';

  @override
  String get bookCaptureCamera => 'Camera';

  @override
  String get bookCaptureGallery => 'From gallery';

  @override
  String get bookCaptureLoading => 'Reading text…';

  @override
  String get bookCaptureErrorNoKorean =>
      'No reliable Korean was detected. Retake the page straight on, sharper, and closer.';

  @override
  String get bookCaptureErrorPermission =>
      'Permission denied. You can grant it in Settings.';

  @override
  String get bookCaptureErrorQuota =>
      'Daily limit reached (20 pages). Come back tomorrow.';

  @override
  String get bookCaptureErrorOcr => 'Text recognition failed.';

  @override
  String get bookCaptureErrorUnknown => 'Unexpected error.';

  @override
  String get bookCropTitle => 'Crop area';

  @override
  String get bookPreviewTitle => 'Check the text';

  @override
  String bookPreviewHint(int count) {
    return '$count text lines detected. Compare and fix any errors.';
  }

  @override
  String get bookPreviewTextFieldHint => 'Korean text…';

  @override
  String get bookPreviewEditorLabel => 'Recognized text';

  @override
  String get bookPreviewQualityWarning =>
      'Uncertain or unsupported script was removed. Check the Korean text carefully before analysis.';

  @override
  String get bookPreviewSevereQualityWarning =>
      'The photo or text recognition is too uncertain. Retaking the photo is recommended. To continue anyway, first correct the OCR text yourself.';

  @override
  String get bookPreviewAnalyze => 'Analyze';

  @override
  String get bookPreviewRetake => 'Retake';

  @override
  String get bookResultTitle => 'Result';

  @override
  String get loadErrorTryAgain => 'Something went wrong. Please try again.';

  @override
  String get bookResultAnalyzing => 'Looking up words & grammar…';

  @override
  String bookResultFoundN(int n) {
    return '$n new words found';
  }

  @override
  String get dojangTitle => 'Stamp Book';

  @override
  String get dojangEmptyTitle => 'No stamps yet';

  @override
  String get dojangEmptyBody =>
      'Clear vocab packs to collect dancheong stamps.';

  @override
  String get dojangEmptyCta => 'Open vocabulary packs';

  @override
  String dojangProgress(int earned, int total) {
    return '$earned of $total stamps collected';
  }

  @override
  String get gyeEntryTitle => 'Study Gye';

  @override
  String get gyeEntryDesc => 'Build a hanok together';

  @override
  String get gyeChooserTitle => 'Gye (study group)';

  @override
  String get gyeChooserCreate => 'Create a Gye';

  @override
  String get gyeChooserJoin => 'Join with code';

  @override
  String get gyeCreateTitle => 'Create Gye';

  @override
  String get gyeJoinTitle => 'Join Gye';

  @override
  String get gyeNameLabel => 'Gye name';

  @override
  String get gyeNameHint => 'e.g. Morning Tigers';

  @override
  String get gyeNicknameLabel => 'Your nickname';

  @override
  String get gyeNicknameHint => 'Shown to gye members';

  @override
  String get gyeCodeLabel => 'Entry code';

  @override
  String get gyeCodeInputLabel => '6-digit code';

  @override
  String get gyeCreateCta => 'Create';

  @override
  String get gyeJoinCta => 'Join';

  @override
  String get gyeCreatingLoading => 'Creating Gye…';

  @override
  String get gyeJoiningLoading => 'Joining Gye…';

  @override
  String get gyeCreatedTitle => 'Gye created!';

  @override
  String gyeCreatedAnnouncement(Object name, Object code) {
    return 'Gye $name was created. Entry code: $code.';
  }

  @override
  String get gyeShareCode => 'Share code';

  @override
  String get gyeInviteTitle => 'Invite friends';

  @override
  String get gyeInviteBody =>
      'Share the code with friends so they can join your gye.';

  @override
  String get gyeCopyCode => 'Copy code';

  @override
  String get gyeCodeCopied => 'Code copied';

  @override
  String gyeShareMessage(Object code) {
    return 'Join my Hangul Sori gye! Code: $code';
  }

  @override
  String gyeJoinedSnack(Object name) {
    return 'Joined $name!';
  }

  @override
  String get gyeErrNetwork => 'Network error. Please try again.';

  @override
  String get gyeErrNotFound => 'No gye found for that code.';

  @override
  String get gyeErrFull => 'This gye is full (max 10).';

  @override
  String get gyeErrTooMany => 'You can be in up to 3 gye at once.';

  @override
  String get gyeErrName => 'Please enter a valid gye name.';

  @override
  String get gyeErrNickname => 'Please enter a valid nickname.';

  @override
  String get gyeErrProfanity => 'Please choose a different word.';

  @override
  String get gyeErrAgeRestricted =>
      'Gye is for ages 16 and up. Because only your self-declared on-device birth year is stored, the conservative check unlocks at a year difference of at least 17.';

  @override
  String get gyeAgeYearTitle => 'Birth year';

  @override
  String get gyeAgeYearBody =>
      'Gye is for ages 16 and up. Your birth year is self-declared, stored only on this device, and is not identity verification. Without month and day, the conservative check unlocks at a year difference of at least 17.';

  @override
  String get gyeAgeYearHint => 'e.g. 2005';

  @override
  String get gyeOpenCta => 'Open gye';

  @override
  String get gyeTitle => 'Gye';

  @override
  String get gyeNotFoundTitle => 'Gye not found';

  @override
  String get gyeNotFoundBody => 'This gye may have been removed.';

  @override
  String gyeMembersN(int count) {
    return '$count members';
  }

  @override
  String get gyeWeeklyGoal => 'This week\'s goal';

  @override
  String get gyeNoGoal => 'No weekly goal set yet';

  @override
  String get gyeDureTitle => 'Together this week';

  @override
  String get gyeDureMe => 'Me';

  @override
  String get gyeDureEmpty => 'Nothing here yet. Clear a pack to get started.';

  @override
  String get gyeChallengeTitle => 'Everyone in?';

  @override
  String get gyeChallengeDone => 'Everyone\'s in!';

  @override
  String get dureTitleDuru => 'Pillar';

  @override
  String get dureTitleNewcomer => 'Newcomer';

  @override
  String get dureTitleSprout => 'Sprout';

  @override
  String get dureTitleHelper => 'Helper';

  @override
  String get gyeFeedTitle => 'Activity';

  @override
  String get gyeFeedEmpty =>
      'No activity yet. Clear packs together to grow the courtyard!';

  @override
  String gyeFeedPackCleared(Object name) {
    return '$name cleared a pack';
  }

  @override
  String gyeFeedQuest(Object name) {
    return '$name completed a quest';
  }

  @override
  String gyeFeedLevelUp(Object name) {
    return '$name leveled up';
  }

  @override
  String gyeFeedSticker(Object name) {
    return '$name sent a sticker';
  }

  @override
  String get gyeCheer1 => 'Together!';

  @override
  String get gyeCheer2 => 'You got this!';

  @override
  String get gyeCheer3 => 'We miss you!';

  @override
  String get gyeCheer4 => 'Almost there!';

  @override
  String get gyeCheer5 => 'Let\'s go!';

  @override
  String get gyeCheerTitle => 'Send cheer';

  @override
  String get gyeFeedGoalAchieved => 'Weekly goal reached! Your hanok grows.';

  @override
  String get gyeFeedAllIn => 'Everyone contributed this week!';

  @override
  String gyeFeedGoalAchievedMvp(int packs, Object mvp) {
    String _temp0 = intl.Intl.pluralLogic(
      packs,
      locale: localeName,
      other: '$packs packs',
      one: '1 pack',
    );
    return 'Weekly goal reached! $_temp0 · MVP $mvp';
  }

  @override
  String get gyeStickerSend => 'Send sticker';

  @override
  String get gyeStickerRateLimited =>
      'Too many stickers at once. Try again in a moment.';

  @override
  String get gyeStickerCatTiger => 'Tiger';

  @override
  String get gyeStickerCatMagpie => 'Magpie';

  @override
  String get gyeStickerCatDancheong => 'Dancheong';

  @override
  String get gyeStickerCatHangul => 'Hangul';

  @override
  String get gyeStickerCatFood => 'Food';

  @override
  String get gyeStickerCatStamp => 'Stamps';

  @override
  String get gyeLeave => 'Leave gye';

  @override
  String get gyeLeaveConfirm => 'Leave this gye?';

  @override
  String get gyeOwnerLeaveUnavailable =>
      'The owner cannot leave until ownership transfer or group deletion is available.';

  @override
  String get gyeMembersTitle => 'Members';

  @override
  String get gyeMemberSelf => 'You';

  @override
  String get gyeRoleOwner => 'Owner';

  @override
  String get gyeReportTitle => 'Report member';

  @override
  String get gyeReportReasonSpam => 'Spam';

  @override
  String get gyeReportReasonInappropriate => 'Inappropriate content';

  @override
  String get gyeReportReasonHarassment => 'Harassment';

  @override
  String get gyeReportReasonOther => 'Other';

  @override
  String get gyeReportNoteHint => 'Note (optional)';

  @override
  String get gyeReportSubmit => 'Report';

  @override
  String get gyeReportSent => 'Report submitted. Thank you.';

  @override
  String get gyeBlockTitle => 'Block member?';

  @override
  String get gyeBlockBody =>
      'You won\'t see this person\'s stickers, cheers or posts anymore. You can unblock them anytime in the member list.';

  @override
  String get gyeBlockConfirm => 'Block';

  @override
  String get gyeUnblock => 'Unblock';

  @override
  String get gyeBlockedLabel => 'Blocked';

  @override
  String get gyeBlockedSnack => 'Member blocked. Their posts are now hidden.';

  @override
  String gyeMvpCard(Object name, int packs) {
    String _temp0 = intl.Intl.pluralLogic(
      packs,
      locale: localeName,
      other: '$packs packs',
      one: '1 pack',
    );
    return 'A round of applause for $name: $_temp0 last week! 👏';
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
      other: '$days-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String gyeProfileWeekly(int packs) {
    String _temp0 = intl.Intl.pluralLogic(
      packs,
      locale: localeName,
      other: '$packs packs this week',
      one: '1 pack this week',
    );
    return '$_temp0';
  }

  @override
  String get gyeAllInCelebrate => 'Everyone contributed this week!';

  @override
  String get gyeReactTooltip => 'React';

  @override
  String get bookResultOfflineNotice =>
      'The server is unavailable. Only grammar patterns were detected offline.';

  @override
  String get bookResultCredentialsNotice =>
      'Secure analysis is unavailable on this device. Sign in, check the connection, and try again.';

  @override
  String get bookResultRateLimited =>
      'Cloud analysis limit reached. Please try again in a minute.';

  @override
  String get bookResultQualityNotice =>
      'Uncertain or non-Korean content was kept out of vocabulary, grammar, and audio.';

  @override
  String get bookResultTranslationUnavailable =>
      'The translation service did not return every meaning. Check the result before saving or try again.';

  @override
  String get bookResultNoKoreanNotice =>
      'No reliable Korean text remained. Check the text or retake the page.';

  @override
  String get bookResultSectionWords => 'Words';

  @override
  String get bookResultSectionExpressions => 'Expressions';

  @override
  String get bookResultSectionGrammar => 'Grammar';

  @override
  String get bookResultSectionSentences => 'Sentences';

  @override
  String bookStudyAskTitle(String name) {
    return 'Ask $name about this item';
  }

  @override
  String get bookStudyAskGenericTitle => 'Questions about this item';

  @override
  String get bookStudyAskButton => 'Ask your companion';

  @override
  String get bookStudyAskWhyForm => 'Why does this form look like this?';

  @override
  String get bookStudyAskExample => 'Show an example from this page';

  @override
  String get bookStudyAskCompare => 'Compare it with similar grammar';

  @override
  String get bookStudyAskQuiz => 'Give me a quick question';

  @override
  String get bookStudyAskMeaning => 'What does this mean?';

  @override
  String get bookStudyAskGrammarInSentence => 'Which grammar is used here?';

  @override
  String get bookStudyNoEvidence =>
      'I couldn\'t find evidence for that in this page analysis.';

  @override
  String get bookStudyAdditionalExample => 'Another verified example';

  @override
  String get bookStudyQuizPrompt =>
      'Answer using only the evidence on this page.';

  @override
  String get bookStudyShowAnswer => 'Show answer';

  @override
  String get bookStudyTaegoAnswerLead => 'Let\'s verify it step by step.';

  @override
  String get bookStudyJoyAnswerLead => 'Here\'s the short version!';

  @override
  String get bookStudyTaegoIntro =>
      'I\'ll point to the exact evidence in your result.';

  @override
  String get bookStudyJoyIntro => 'Let\'s look at the exact evidence together!';

  @override
  String get bookStudyGenericIntro =>
      'This answer uses only the validated analysis result.';

  @override
  String get bookStudyEvidenceLabel => 'Evidence from this page';

  @override
  String get bookResultSave => 'Save to my bookshelf';

  @override
  String get bookResultSaving => 'Saving page…';

  @override
  String get bookResultSaveUnresolved => 'Save status could not be confirmed';

  @override
  String get bookResultSaveUnresolvedBody =>
      'Check your bookshelf before trying to save this page again.';

  @override
  String get bookResultSaved => 'Page saved.';

  @override
  String get bookResultBackToCapture => 'Snap another page';

  @override
  String get questsTitle => 'Special quests';

  @override
  String get questsEmptyTitle => 'No quests yet';

  @override
  String get questsEmptyBody =>
      'Start a pack. Your quest progress will appear here.';

  @override
  String get questsSectionInProgress => 'In progress';

  @override
  String questsInProgressCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quests in progress',
      one: '1 quest in progress',
    );
    return '$_temp0';
  }

  @override
  String questsRewardSemantics(String reward) {
    return 'Reward: $reward';
  }

  @override
  String get questsSectionAvailable => 'Available';

  @override
  String get questsSectionCompleted => 'Cleared';

  @override
  String get questsSectionSeasonalLocked => 'Seasonal (locked)';

  @override
  String get questsSeasonalBadge => 'Season';

  @override
  String get questsCompletionCelebration =>
      'New decoration for your room unlocked!';

  @override
  String get questsOpenGiftCta => 'Open the bundle';

  @override
  String get homeBojagiTitle => 'A gift is waiting';

  @override
  String homeBojagiBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bundles are waiting. Open them and furnish your room.',
      one: 'One bundle is waiting. Open it and furnish your room.',
    );
    return '$_temp0';
  }

  @override
  String get dojangDecorHintBody =>
      'Your collected Dancheong stamps are now decorating pieces too. Place them freely in your Sarangbang; they remain visible in the stamp book.';

  @override
  String get dojangDecorHintCta => 'Decorate the Sarangbang';

  @override
  String dojangStampEarned(String stamp) {
    return '$stamp, collected';
  }

  @override
  String dojangStampLocked(String stamp) {
    return '$stamp, not collected yet';
  }

  @override
  String get hanokCinematicIntro => 'Your hanok is growing.';

  @override
  String get hanokA1MapLabel => 'Your hanok under construction';

  @override
  String get hanokA1MapUnavailable => 'Hanok illustration unavailable';

  @override
  String get hanokStageEmpty => 'Preparing the plot';

  @override
  String get hanokStageFoundation => 'Laying foundation stones';

  @override
  String get hanokStagePillars => 'Raising pillars';

  @override
  String get hanokStageBeams => 'Building the roof frame';

  @override
  String get hanokStageThatch => 'Thatched roof finished';

  @override
  String get hanokStageTilePartial => 'Laying tiles';

  @override
  String get hanokStageTileComplete => 'Tile roof complete';

  @override
  String get hanokStageDancheong => 'Dancheong painted';

  @override
  String get hanokStageGate => 'Gate raised';

  @override
  String get hanokStageWindows => 'Lattice doors fitted';

  @override
  String get hanokStageSideBuilding => 'Side wing added';

  @override
  String get hanokStageJongga => 'Jongga complete';

  @override
  String get vocabPackPlayTitle => 'Pack practice';

  @override
  String get vocabPackLearnHint => 'Tap to flip';

  @override
  String get vocabPackDontKnow => 'Don\'t know';

  @override
  String get vocabPackGotIt => 'Got it';

  @override
  String get deckActionSave => 'Save';

  @override
  String get contentActionFlip => 'Flip';

  @override
  String get contentActionLike => 'Like';

  @override
  String get contentActionShare => 'Share';

  @override
  String get contentActionBookmark => 'Save';

  @override
  String get deckFlipFirstHint => 'Tap the card to flip it first';

  @override
  String get coachSoriDeckTitle => 'Swipe to the next card';

  @override
  String get coachSoriDeckBody =>
      'Swipe up or down for the next card. ? flips, the heart likes for later, the bookmark adds to your wordbook.';

  @override
  String get coachSoriDeckBodyNoSave =>
      'Swipe up or down for the next card. ? flips, the heart likes for later.';

  @override
  String get vocabPackStageLearn => 'Learn';

  @override
  String get vocabPackStageQuiz => 'Quiz';

  @override
  String get vocabPackStageBoss => 'Boss';

  @override
  String get vocabPackQuizHint => 'Pick the right translation';

  @override
  String get vocabPackBossHint => 'Listen, then choose';

  @override
  String get vocabPackBossReplayAudio => 'Play again';

  @override
  String get vocabPackTapToFlip => 'Tap to flip';

  @override
  String get vocabPackResultTitle => 'Result';

  @override
  String get vocabPackResultCleared => 'Pack completed!';

  @override
  String get vocabPackResultClearedAgain => 'Already completed. Nice review!';

  @override
  String get vocabPackResultRetry => 'So close. Try again!';

  @override
  String get vocabPackResultBossLabel => 'Boss accuracy';

  @override
  String get vocabPackResultQuizLabel => 'Quiz';

  @override
  String get vocabPackResultXpLabel => 'Reward';

  @override
  String vocabPackResultNextPack(Object next) {
    return 'Continue to \"$next\"';
  }

  @override
  String get vocabPackResultRetryCta => 'Try again';

  @override
  String get vocabPackResultRecallCta => 'Recall in Korean';

  @override
  String get vocabPackResultHardWordsCta => 'Practice tricky words';

  @override
  String get vocabPackResultBackToGrid => 'Back to packs';

  @override
  String get vocabPackResultGeschafft =>
      'Completed! Review these words again later.';

  @override
  String get vocabPackRecallTitle => 'From memory';

  @override
  String get vocabPackRecallIntro =>
      'Optional: read the meaning and type the Korean word.';

  @override
  String get vocabPackRecallPrompt => 'What is this in Korean?';

  @override
  String get vocabPackRecallInputHint => 'Type in Korean…';

  @override
  String get vocabPackRecallHintCta => 'Show first syllable';

  @override
  String vocabPackRecallHintLabel(Object hint) {
    return 'Starts with “$hint”';
  }

  @override
  String get vocabPackRecallShowAnswerCta => 'Show answer';

  @override
  String get vocabPackRecallCorrect => 'Correct. Recalled directly.';

  @override
  String get vocabPackRecallCorrectWithHint => 'Correct, with a hint.';

  @override
  String get vocabPackRecallIncorrect => 'Not quite.';

  @override
  String get vocabPackRecallRevealed => 'Answer shown.';

  @override
  String vocabPackRecallAnswer(Object answer) {
    return 'Correct: $answer';
  }

  @override
  String get vocabPackRecallDoneTitle => 'Recall practice complete';

  @override
  String vocabPackRecallDoneScore(int correct, int total) {
    return '$correct of $total recalled directly';
  }

  @override
  String get vocabPackRecallReviewLater => 'Review these words again later.';

  @override
  String get vocabPackRecallBackToResult => 'Back to result';

  @override
  String get vocabPackRecallNoBossWords =>
      'This pack has no Boss words for typing practice.';

  @override
  String get moduleStatsTitle => 'Statistics';

  @override
  String get moduleStatsDesc => 'Streak, cards, accuracy';

  @override
  String get settingsCloudSection => 'Cloud backup';

  @override
  String settingsCloudSignedIn(Object name) {
    return 'Signed in: $name';
  }

  @override
  String get settingsCloudSignInPrompt => 'Back up with Google';

  @override
  String get settingsCloudSignedInDesc => 'Your data is backed up to the cloud';

  @override
  String get settingsCloudSignInDesc =>
      'So your progress survives a phone change';

  @override
  String get settingsCloudBackupNow => 'Back up now';

  @override
  String get settingsCloudRestore => 'Restore from cloud';

  @override
  String get settingsCloudBackupSuccess => 'Backup successful ✓';

  @override
  String get settingsCloudRestoreSuccess => 'Restored ✓';

  @override
  String get settingsCloudRestoreEmpty => 'No cloud data';

  @override
  String settingsCloudAuthFailed(Object error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get settingsCloudDeleteData => 'Delete cloud data';

  @override
  String get settingsCloudDeleteDataDesc =>
      'Removes your Firestore backup. Local progress stays on this device.';

  @override
  String get settingsCloudDeleteDataConfirmTitle => 'Delete cloud data?';

  @override
  String get settingsCloudDeleteDataConfirmBody =>
      'This deletes the cloud backup for your Firebase account. Your local progress on this device is kept.';

  @override
  String get settingsCloudDeleteDataSuccess => 'Cloud data deleted';

  @override
  String get settingsCloudDeleteDataFailed =>
      'Cloud data could not be deleted.';

  @override
  String get settingsAccountDelete => 'Delete account and all data';

  @override
  String get settingsAccountDeleteDesc =>
      'Deletes your Firebase account, cloud backup, and local progress.';

  @override
  String get settingsAccountDeleteConfirmTitle => 'Delete account permanently?';

  @override
  String get settingsAccountDeleteConfirmBody =>
      'This deletes your Firebase account, Google and Apple links, Firestore cloud backup, and local learning data on this device. This cannot be undone. Google or Apple may ask you to sign in again to confirm.';

  @override
  String get settingsAccountDeleteSubscriptionWarning =>
      'This does not cancel an App Store or Play Store subscription.';

  @override
  String get settingsManageSubscription => 'Manage store subscription';

  @override
  String get settingsManageSubscriptionFailed =>
      'Subscription management could not be opened.';

  @override
  String get settingsAccountDeleteSuccess => 'Account and data deleted';

  @override
  String settingsAccountDeleteFailed(Object error) {
    return 'Deletion failed: $error';
  }

  @override
  String get settingsAccountDeletionTitle => 'Account & data deletion';

  @override
  String get settingsAccountDeletionSubtitle => 'Copy account-deletion link';

  @override
  String get statsGotIt => 'Got it';

  @override
  String get statsNotGotIt => 'Didn\'t know';

  @override
  String get statsSkipped => 'Skipped';

  @override
  String get statsCorrect => 'Correct';

  @override
  String get statsWrong => 'Wrong';

  @override
  String get statsLosses => 'Lost';

  @override
  String get statsBestShort => 'Best';

  @override
  String get statsWinRate => 'Win rate';

  @override
  String get onboardingPage1Title => 'Meet your study buddy';

  @override
  String get onboardingPage1Subtitle => 'Taego learns with you';

  @override
  String get onboardingPage2Title => '5 minutes a day';

  @override
  String get onboardingPage2Subtitle => 'Short enough to fit your day';

  @override
  String get onboardingPage3Title => 'Days in a row count';

  @override
  String get onboardingPage3Subtitle => 'Keep it up and you unlock rewards.';

  @override
  String get onboardingPage4Title => 'How much time do you have?';

  @override
  String get onboardingGoal5min => '5 minutes';

  @override
  String get onboardingGoal10min => '10 minutes';

  @override
  String get onboardingGoal15min => '15 minutes';

  @override
  String get onboardingStartEyebrow => 'Your start';

  @override
  String get onboardingStartTitle => 'What do you need Korean for?';

  @override
  String get onboardingStartBody =>
      'This just picks where you start. It\'s not a test.';

  @override
  String get onboardingStartTravelTitle => 'Getting around Korea';

  @override
  String get onboardingStartTravelBody =>
      'Cafés, asking the way, shops, getting help';

  @override
  String get onboardingStartPeopleTitle => 'Talking with people';

  @override
  String get onboardingStartPeopleBody => 'Friends, family and everyday life';

  @override
  String get onboardingStartWorkTitle => 'Study or work';

  @override
  String get onboardingStartWorkBody => 'Ask and understand politely';

  @override
  String get onboardingStartPoint => 'Starting point';

  @override
  String get onboardingStartNewTitle => 'I\'m just starting';

  @override
  String get onboardingStartNewBody => 'Straight into listening and speaking';

  @override
  String get onboardingStartExistingTitle => 'I already know some Korean';

  @override
  String get onboardingStartExistingBody =>
      'Choose a level or answer eight to ten questions';

  @override
  String get onboardingStartPrimary => 'Start my first scene';

  @override
  String get onboardingStartChooseLevel => 'Choose a level';

  @override
  String get onboardingStartLoading => 'Preparing your first scene…';

  @override
  String get onboardingStartChangePoint => 'Change starting point';

  @override
  String get onboardingFirstSceneTravelCanDo =>
      'I can answer politely at immigration.';

  @override
  String get onboardingFirstScenePeopleCanDo => 'I can introduce myself.';

  @override
  String get onboardingFirstSceneWorkCanDo =>
      'I can briefly introduce myself in class or at work.';

  @override
  String get onboardingCompanionChoose => 'Choose a study buddy';

  @override
  String get onboardingCompanionSkip => 'Not now';

  @override
  String get onboardingCompanionEyebrow => 'Your study buddy';

  @override
  String get onboardingCompanionPrompt =>
      'Choose Taego or Joy. Both can help, and you can decide later too.';

  @override
  String get onboardingCompanionSelectedTiger => 'Taego is coming with you.';

  @override
  String get onboardingCompanionSelectedMagpie => 'Joy is coming with you.';

  @override
  String get onboardingCompanionSelectionBody =>
      'You can change this later in your profile.';

  @override
  String get onboardingCompanionContinue => 'Go to Today with your buddy';

  @override
  String get onboardingCompanionChange => 'Choose again';

  @override
  String get firstVoiceStamp => 'FIRST\nVOICE';

  @override
  String get firstVoiceTitle => 'You understood your first Korean.';

  @override
  String get firstVoiceBody =>
      'You caught a Korean phrase and can use it in your scene.';

  @override
  String get firstVoicePhraseBody => 'a sentence you can now hear and answer.';

  @override
  String firstVoiceSceneSummary(int completed, int total) {
    return '$completed of $total tasks completed';
  }

  @override
  String get firstVoiceCanDo => 'I can greet someone kindly.';

  @override
  String get firstVoiceCanDoBody => 'Your A1 path begins with this scene.';

  @override
  String get firstVoiceCompanionTitle => 'Want a study buddy?';

  @override
  String get firstVoiceCompanionBody =>
      'They cheer you on and explain hints. You can decide later.';

  @override
  String get firstVoiceSkip => 'Go straight to Today';

  @override
  String get missionContextLabel => 'Current mission';

  @override
  String get courseMissionPath => 'Your mission path';

  @override
  String get courseMissionDetails => 'Mission details';

  @override
  String get courseMissionCheck => 'Check your understanding';

  @override
  String missionContextStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingTitle => 'What\'s your level?';

  @override
  String get onboardingSubtitle =>
      'We start where you are. Earlier levels stay open. Later ones unlock as you go.';

  @override
  String get onboardingLevelA1 => 'Beginner';

  @override
  String get onboardingLevelA1Desc => 'Just starting out';

  @override
  String get onboardingLevelA2 => 'Basic';

  @override
  String get onboardingLevelA2Desc => 'Greetings, simple orders';

  @override
  String get onboardingLevelB1 => 'Intermediate';

  @override
  String get onboardingLevelB1Desc => 'Everyday conversations already work';

  @override
  String get onboardingLevelB2 => 'Advanced';

  @override
  String get onboardingLevelB2Desc => 'Fluent, including nuance';

  @override
  String get onboardingLevelC1 => 'Proficient';

  @override
  String get onboardingLevelC1Desc =>
      'Evidence, institutions, fine distinctions';

  @override
  String get onboardingLevelC2 => 'Expert';

  @override
  String get onboardingLevelC2Desc =>
      'Break texts down and choose your wording';

  @override
  String get onboardingExampleA1Trans => 'Hello / Hi.';

  @override
  String get onboardingExampleA2Trans => 'An americano, please.';

  @override
  String get onboardingExampleB1Trans =>
      'Yesterday I watched a movie with a friend.';

  @override
  String get onboardingExampleB2Trans =>
      'The meeting is running long, so I\'ll be a bit late.';

  @override
  String get onboardingExampleC1Trans =>
      'I\'ll explain the confirmed facts and our current reading separately.';

  @override
  String get onboardingExampleC2Trans =>
      'If you take silence as yes, the way you ask can already shut people out.';

  @override
  String get onboardingSkip => 'Skip for now (starts at A1)';

  @override
  String get onboardingPrompt =>
      'Choose your level. You can change it later in Settings.';

  @override
  String get onboardingTigerGreeting => 'Welcome!\nWhere do you want to start?';

  @override
  String get onboardingDifficulty => 'Difficulty';

  @override
  String get onboardingExampleLabel => 'What this level sounds like';

  @override
  String get onboardingCompareCta => 'Not sure? Compare the levels';

  @override
  String get onboardingCompareTitle => 'What changes at each level?';

  @override
  String get onboardingCompareIntro =>
      'Earlier levels stay open. You can change your level anytime in Settings.';

  @override
  String get onboardingCompareColCan => 'What you can already do';

  @override
  String get onboardingCompareColLearn => 'What you\'ll learn here';

  @override
  String get onboardingCompareClose => 'Got it';

  @override
  String get onboardingLevelA1Can => 'You may know a few words already.';

  @override
  String get onboardingLevelA1Learn =>
      'Reading and writing Hangeul, introducing yourself, numbers.';

  @override
  String get onboardingLevelA2Can =>
      'You read Hangeul and know simple greetings.';

  @override
  String get onboardingLevelA2Learn =>
      'Ordering, shopping, asking for directions, the polite -요 form.';

  @override
  String get onboardingLevelB1Can =>
      'You handle simple everyday conversations.';

  @override
  String get onboardingLevelB1Learn =>
      'Telling stories, giving opinions, linking sentences, past tense.';

  @override
  String get onboardingLevelB2Can =>
      'You speak fluently about everyday topics.';

  @override
  String get onboardingLevelB2Learn =>
      'Work and news, nuance, idioms, honorifics.';

  @override
  String get onboardingLevelC1Can =>
      'You can talk through hard topics and say how sure you are.';

  @override
  String get onboardingLevelC1Learn =>
      'Evidence, uncertainty, inclusive systems, public explanations.';

  @override
  String get onboardingLevelC2Can =>
      'You can unpack assumptions, framing, and official language.';

  @override
  String get onboardingLevelC2Learn =>
      'Discourse, interpretation, technology ethics, accountable decisions.';

  @override
  String get homeHeroGreetingMorning => 'Good morning!';

  @override
  String get homeHeroGreetingAfternoon => 'Hi there!';

  @override
  String get homeHeroGreetingEvening => 'Good evening!';

  @override
  String get homeTigerBubbleStart => 'Up for 5 minutes of Korean?';

  @override
  String get homeTigerBubbleStreak => 'Streak\'s alive! Keep it going';

  @override
  String get homeTigerBubbleResume => 'Welcome back!';

  @override
  String get homeHeroActionContinue => 'Continue learning';

  @override
  String get homeHeroActionStart => 'New pack';

  @override
  String get homeShieldLabel => 'Shield';

  @override
  String get homePathSection => 'Your path';

  @override
  String get homePathLocked => 'Locked';

  @override
  String get homePathCurrent => 'Now';

  @override
  String get homeLearnNowCta => 'Learn now';

  @override
  String get homeTigerBubbleResumeSub => '5 minutes is all it takes!';

  @override
  String get homePathDone => 'Done';

  @override
  String get scenariosListTitle => 'Scenarios';

  @override
  String get scenariosListSubtitle => 'Practise real-life situations';

  @override
  String scenariosCardMeta(int xp) {
    return '5 to 7 minutes · +$xp XP';
  }

  @override
  String scenariosLocked(Object level) {
    return 'Reach $level to unlock';
  }

  @override
  String scenariosLevelBadge(Object level) {
    return 'Level $level';
  }

  @override
  String get scenariosEmpty => 'Coming soon 🚧';

  @override
  String get scenariosEmptyTitle => 'Coming soon';

  @override
  String get scenariosEmptyBody => 'New scenarios are on the way.';

  @override
  String get scenariosLoadFailedTitle => 'Hmm, something went wrong';

  @override
  String get statsFirstEntryTitle => 'Your progress starts here';

  @override
  String get statsFirstEntryBody =>
      'Finish a scenario. Your progress will appear here.';

  @override
  String get statsFirstEntryCta => 'Start your first scenario';

  @override
  String get settingsOfflineTitle => 'No connection';

  @override
  String get settingsOfflineBody =>
      'Cloud sync needs an active internet connection. Try again later.';

  @override
  String get vocabDueEmptyTitle => 'All done for today!';

  @override
  String get vocabDueEmptyBody =>
      'You finished your due cards. Come back tomorrow or learn new words.';

  @override
  String get moduleScenariosTitle => 'Scenarios';

  @override
  String get moduleScenariosDesc =>
      'Practice everyday situations: cafés, airports, introductions…';

  @override
  String get scenarioIntroTitle => 'Intro';

  @override
  String get scenarioVocabTitle => 'Vocabulary';

  @override
  String get scenarioDialogTitle => 'Dialogue';

  @override
  String get scenarioGrammarTitle => 'Grammar';

  @override
  String get scenarioQuestsTitle => 'Mini-quests';

  @override
  String scenarioQuestProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get scenarioCulturalNote => 'Culture note';

  @override
  String get scenarioStartBtn => 'Let\'s go';

  @override
  String get scenarioNextBtn => 'Next';

  @override
  String get scenarioCompleteBtn => 'Complete';

  @override
  String get scenarioResultReturnBtn => 'Back to my path';

  @override
  String get scenarioSavedEyebrow => 'YOUR SCENE IS SAVED';

  @override
  String get scenarioSavedTitle => 'You can return to your Hanok now.';

  @override
  String get scenarioSavedPhrase => 'A phrase for your next scene';

  @override
  String get scenarioSavedStructure => 'Structure for this scene';

  @override
  String get scenarioSavedEmpty =>
      'Your practice is saved and ready for review.';

  @override
  String get scenarioSavedReturnHanok => 'Back to my Hanok';

  @override
  String get scenarioSavedRepeat => 'Practise this scene again';

  @override
  String get scenarioResultSaving => 'Saving this completed scene…';

  @override
  String get scenarioResultSaveRetry => 'Try saving again';

  @override
  String get scenarioStructureChangedTitle => 'Your Hanok has changed.';

  @override
  String scenarioStructureChangedBody(String stage) {
    return 'New structure: $stage';
  }

  @override
  String get scenarioStructureUnchangedTitle =>
      'Your Hanok keeps its current structure.';

  @override
  String get scenarioStructureUnchangedBody =>
      'No new structure was unlocked by this checkpoint.';

  @override
  String get scenarioStructureUnavailableTitle => 'Your Hanok structure';

  @override
  String get scenarioStructureUnavailableBody =>
      'Open your Hanok to see the current verified construction.';

  @override
  String get scenarioCanDoVerifiedTitle => 'You can do this now.';

  @override
  String get scenarioCanDoVerifiedBody =>
      'This scene\'s checkpoint was saved independently.';

  @override
  String get scenarioCanDoReviewTitle => 'Not secure yet.';

  @override
  String get scenarioCanDoReviewBody =>
      'This checkpoint was saved, but it is below this mission\'s verified threshold. Practise the scene again.';

  @override
  String get scenarioCanDoPracticeTitle => 'Practice saved.';

  @override
  String get scenarioCanDoPracticeBody =>
      'This scene is stored as practice and does not change your course step.';

  @override
  String scenarioXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String scenarioStarsLabel(int stars) {
    return '$stars of 3 stars';
  }

  @override
  String get scenarioRecapTitle => 'What you learned';

  @override
  String scenarioRecapWordsLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words practiced',
      one: '1 word practiced',
    );
    return '$_temp0';
  }

  @override
  String scenarioRecapAccuracyLine(int passed, int total) {
    return '$passed of $total quests on first try';
  }

  @override
  String scenarioRecapGrammarLine(String pattern) {
    return 'Grammar focus: $pattern';
  }

  @override
  String get scenarioNextRecommendedTitle => 'Suggested next';

  @override
  String get scenarioNextRecommendedCta => 'Open';

  @override
  String scenarioNextRecommendedAllDone(String level) {
    return 'All $level scenarios completed.';
  }

  @override
  String get questCorrect => 'Correct!';

  @override
  String get questWrong => 'Not quite';

  @override
  String get questNext => 'Next';

  @override
  String get questRetry => 'Try again';

  @override
  String get questAnswerSelected => 'Selected';

  @override
  String get questAnswerRevealed => 'The correct answer is shown.';

  @override
  String get questTryAgainHint => 'Almost. Try once more.';

  @override
  String get questViewResult => 'View result';

  @override
  String get questDontKnowYet => 'I don’t know yet';

  @override
  String get questListeningQuestion => 'What does this sentence mean?';

  @override
  String get questTypeListening => 'Listen';

  @override
  String get questTypeTranslation => 'Translate';

  @override
  String get questTypeCloze => 'Fill the gap';

  @override
  String get questTypeParticle => 'Choose a particle';

  @override
  String get questTypeBatchim => 'Add batchim';

  @override
  String get questTypeSentence => 'Build a sentence';

  @override
  String get questTypeDictation => 'Dictation';

  @override
  String get questTypeWriting => 'Write';

  @override
  String get diktatUseWordBlocks => 'No Korean keyboard? Use word blocks';

  @override
  String get diktatUseKeyboard => 'Type with the keyboard';

  @override
  String get particlePopHint => 'Choose the correct particle for the sentence.';

  @override
  String get particlePopExplanation =>
      'After consonant: 은/이/을 · After vowel: 는/가/를';

  @override
  String get settingsUserLevel => 'My level';

  @override
  String get settingsUserLevelChange => 'Change level';

  @override
  String get statsXpTitle => 'Scenario progress';

  @override
  String get statsXp => 'XP';

  @override
  String statsLevelLabel(int n) {
    return 'Level $n';
  }

  @override
  String statsToNextLevel(int n, int next) {
    return '$n XP to level $next';
  }

  @override
  String get statsScenariosCompleted => 'Scenarios completed';

  @override
  String get statsBadgesTitle => 'Badges';

  @override
  String get statsNoBadges =>
      'None yet. Complete a scenario to earn your first! 🚀';

  @override
  String statsWeekDaySemantics(String weekday, String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'todayCompleted': 'today, completed',
      'today': 'today',
      'completed': 'completed',
      'pending': 'not completed',
      'other': 'not completed',
    });
    return '$weekday: $_temp0';
  }

  @override
  String get homeRecommended => 'Recommended today';

  @override
  String get homeAllDone => 'All scenarios done!';

  @override
  String get homeNoScenario => 'Scenarios for your level coming soon';

  @override
  String get homeGreetingLearn => 'Practice Korean for everyday situations';

  @override
  String get homeTodaySection => 'Today';

  @override
  String get missionHeroCtaStart => 'Let\'s go';

  @override
  String get missionHeroCtaContinue => 'Continue';

  @override
  String missionHeroCourseMeta(int n, int total) {
    return 'Mission $n of $total';
  }

  @override
  String missionHeroPackMeta(Object level) {
    return 'Vocabulary pack · Level $level';
  }

  @override
  String missionHeroReviewTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Review $n words',
      one: 'Review 1 word',
    );
    return '$_temp0';
  }

  @override
  String get missionHeroReviewMeta => 'Today\'s review';

  @override
  String missionHeroScenarioMeta(Object level) {
    return 'Scenario · Level $level';
  }

  @override
  String get missionHeroAllDoneTitle => 'Done for today';

  @override
  String get missionHeroAllDoneBody =>
      'You are done for today. New missions are ready tomorrow.';

  @override
  String get missionHeroAnotherRound => 'One more round';

  @override
  String missionHeroSemantics(Object title, Object level) {
    return 'Next mission: $title, level $level';
  }

  @override
  String get settingsThemeTitle => 'Appearance';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get dailyCharTitle => 'Letter of the day';

  @override
  String get dailyCharSubtitle => 'Watch the stroke-order guide';

  @override
  String get dailyCharFallbackSubtitle => 'Look at today’s letter';

  @override
  String get dailyCharGuideHint => 'Done unlocks after the guide finishes.';

  @override
  String get dailyCharDoneToday => 'Done today ✓';

  @override
  String get dailyCharFinish => 'Done';

  @override
  String dailyCharStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days total',
      one: '1 day total',
    );
    return '$_temp0';
  }

  @override
  String get dailyCharGreatJob => 'Great job!';

  @override
  String get vocabModeFavorites => 'Favorites';

  @override
  String vocabFavoritesBadge(int n) {
    return '$n';
  }

  @override
  String get vocabHearExample => 'Hear example';

  @override
  String get vocabSlowHint => 'Long press: slow';

  @override
  String get vocabEmptyFavorites =>
      'No favorites yet\nTap the star on hard words';

  @override
  String get listeningTitle => 'Listening';

  @override
  String get listeningSubtitle => 'Hear a scenario at natural speed';

  @override
  String get listeningSelectScenario => 'Choose scenario';

  @override
  String get listeningSpeedLabel => 'Speed';

  @override
  String get listeningSubtitleLabel => 'Subtitles';

  @override
  String get listeningSubtitleKo => 'Korean';

  @override
  String get listeningSubtitleNative => 'Translation';

  @override
  String get listeningSubtitleBoth => 'Both';

  @override
  String get listeningSubtitleOff => 'Off';

  @override
  String get listeningReplay => 'Replay';

  @override
  String get listeningGotIt => 'Got it';

  @override
  String get listeningPrev => 'Back';

  @override
  String get listeningNext => 'Next';

  @override
  String listeningProgress(int i, int n) {
    return '$i/$n';
  }

  @override
  String get listeningCompleteTitle => 'Done!';

  @override
  String listeningCompleteBody(int n, int xp) {
    return 'Heard $n lines · +$xp XP';
  }

  @override
  String get listeningPickFirst => 'Tap a shelf to start.';

  @override
  String get listeningEmptyTitle => 'No scenarios yet';

  @override
  String get listeningEmptyBody =>
      'Once scenarios are available, you can listen to them here.';

  @override
  String get listeningShelfEmpty => 'not stocked yet';

  @override
  String listeningShelfScenarioCount(int n) {
    return '$n scenarios';
  }

  @override
  String listeningLineCount(int n) {
    return '$n lines';
  }

  @override
  String get listeningShelfA1Transit => 'Getting on & off';

  @override
  String get listeningShelfA1Arrival => 'Taxi, airport & lodging';

  @override
  String get listeningShelfA1Counter => 'Shops & counters';

  @override
  String get listeningShelfA1Cafe => 'Café & snacks';

  @override
  String get listeningShelfA1Home => 'Home & front door';

  @override
  String get listeningShelfA1Greeting => 'Greetings & how to address people';

  @override
  String get listeningShelfA1Repair => 'I didn\'t catch that';

  @override
  String get listeningShelfA1Health => 'Pharmacy, weather & safety';

  @override
  String get listeningShelfA1Family => 'First visit to the partner\'s family';

  @override
  String get listeningShelfA1Numbers => 'Numbers & time';

  @override
  String get listeningShelfA1Phone => 'Calls & messages';

  @override
  String get listeningShelfA1Wayfinding => 'Directions & signs';

  @override
  String get listeningShelfA2Travel => 'Travel, lodging & lost items';

  @override
  String get listeningShelfA2Bank => 'Bank, mobile plans & fees';

  @override
  String get listeningShelfA2Shopping => 'Buying & paying';

  @override
  String get listeningShelfA2Cafe => 'Café & restaurant';

  @override
  String get listeningShelfA2Body => 'Body, doctor & sport';

  @override
  String get listeningShelfA2Neighbourhood => 'Building & neighbours';

  @override
  String get listeningShelfA2Work => 'First days at work';

  @override
  String get listeningShelfA2Plans => 'Plans & staying in touch';

  @override
  String get listeningShelfA2Family => 'Partner\'s family & holidays';

  @override
  String get listeningShelfA2Delivery => 'Deliveries & receiving';

  @override
  String get listeningShelfA2Enrolment => 'Enrolment & classes';

  @override
  String get listeningShelfA2Booking => 'Booking & rebooking';

  @override
  String get listeningShelfB1Repairs => 'Repairs & defects';

  @override
  String get listeningShelfB1Refund => 'Refunds & warranty';

  @override
  String get listeningShelfB1Receipts => 'Receipts & billing';

  @override
  String get listeningShelfB1Delay => 'Rescheduling & delays';

  @override
  String get listeningShelfB1Paperwork => 'Paperwork & authorisation';

  @override
  String get listeningShelfB1Team => 'Team & handover';

  @override
  String get listeningShelfB1Neighbours => 'Neighbours & shared spaces';

  @override
  String get listeningShelfB1Feelings => 'Feelings & relationships';

  @override
  String get listeningShelfB1Family =>
      'Closeness & distance with the partner\'s family';

  @override
  String get listeningShelfB1Insurance => 'Treatment & insurance';

  @override
  String get listeningShelfB1Incident => 'Accidents & reports';

  @override
  String get listeningShelfB1Cancellation => 'Cancelling & moving out';

  @override
  String get listeningShelfB2Meetings => 'Leading meetings';

  @override
  String get listeningShelfB2Evidence => 'Evidence & figures';

  @override
  String get listeningShelfB2Negotiation => 'Negotiating terms';

  @override
  String get listeningShelfB2Contracts => 'Contracts & signatures';

  @override
  String get listeningShelfB2Notices => 'Formal letters & objections';

  @override
  String get listeningShelfB2Escalation => 'Escalating while travelling';

  @override
  String get listeningShelfB2Medical => 'Medicine & billing';

  @override
  String get listeningShelfB2Public => 'Speaking & writing in public';

  @override
  String get listeningShelfB2Family => 'Boundaries with the partner\'s family';

  @override
  String get listeningShelfB2Hiring => 'Hiring & appraisal';

  @override
  String get listeningShelfB2Authorities => 'Authorities & permits';

  @override
  String get listeningShelfB2Privacy => 'Data & consent';

  @override
  String get listeningShelfC1Briefing => 'Briefing & the right to speak';

  @override
  String get listeningShelfC1Uncertainty => 'Uncertainty & sampling';

  @override
  String get listeningShelfC1Access => 'Access rights & deadlines';

  @override
  String get listeningShelfC1InvisibleLabor => 'Invisible labour in the family';

  @override
  String get listeningShelfC1Conflict => 'Conflicts of interest & bias';

  @override
  String get listeningShelfC1Policy => 'Interpretation & discretion';

  @override
  String get listeningShelfC1Consent => 'Informed consent';

  @override
  String get listeningShelfC1Critique => 'Cultural & art criticism';

  @override
  String get listeningShelfC1Mediation => 'Intercultural mediation';

  @override
  String get listeningShelfC1Methodology => 'Methodology & reproducibility';

  @override
  String get listeningShelfC1Facework => 'Objecting without loss of face';

  @override
  String get listeningShelfC1Attribution => 'Citation & source responsibility';

  @override
  String get listeningShelfC2Automation => 'Automated decisions';

  @override
  String get listeningShelfC2Records => 'Gaps in the record';

  @override
  String get listeningShelfC2Discourse => 'Assumptions in discourse';

  @override
  String get listeningShelfC2Authority => 'Limits & revocation of mandates';

  @override
  String get listeningShelfC2Impact => 'Unequal impact';

  @override
  String get listeningShelfC2Memory => 'Remembering places & names';

  @override
  String get listeningShelfC2Ethics => 'Research ethics & consent';

  @override
  String get listeningShelfC2History => 'Historiography & reconciliation';

  @override
  String get listeningShelfC2Translation => 'Aesthetics & untranslatability';

  @override
  String get listeningShelfC2Limitation => 'Time limits & prescription';

  @override
  String get listeningShelfC2Jurisdiction => 'Jurisdiction & boundaries';

  @override
  String get listeningShelfC2Representation => 'Who speaks for whom';

  @override
  String get listeningShelfSocialFriends => 'Friends & gaming';

  @override
  String get listeningShelfSocialDating => 'Dating & relationships';

  @override
  String get listeningShelfSocialFandom => 'Fandom & videos';

  @override
  String get kkeunmariTitle => 'Word Chain';

  @override
  String get kkeunmariEmptyBody =>
      'No words are ready for this game right now.';

  @override
  String get kkeunmariSubtitle => 'Last syllable → next word';

  @override
  String get kkeunmariYourTurn => 'Your turn';

  @override
  String get kkeunmariTigerTurn => 'Tiger thinking…';

  @override
  String kkeunmariStartHint(Object syl) {
    return 'Start with “$syl”';
  }

  @override
  String get kkeunmariInputHint => 'Type a Korean word…';

  @override
  String get kkeunmariSubmit => 'Send';

  @override
  String get kkeunmariDictionaryChecking => 'Checking the dictionary…';

  @override
  String get kkeunmariNotDictionaryWord =>
      'This is not a dictionary word for the game.';

  @override
  String get kkeunmariDictionaryUnavailable =>
      'The dictionary cannot be checked right now. Try a known word or try again shortly.';

  @override
  String get kkeunmariNotInPool =>
      'I don\'t know that one yet. Try another word. 🐯';

  @override
  String get kkeunmariNotKorean => 'Hangul only, please';

  @override
  String kkeunmariWrongStart(Object syl) {
    return 'Must start with “$syl”';
  }

  @override
  String get kkeunmariAlreadyUsed => 'Already used';

  @override
  String get kkeunmariTimeUp => 'Time’s up!';

  @override
  String get kkeunmariDeadEnd => '한방단어 (dead end): the chain ends here.';

  @override
  String kkeunmariChainLength(int n) {
    return 'Chain: $n';
  }

  @override
  String kkeunmariFinalScore(int xp) {
    return '+$xp XP';
  }

  @override
  String get kkeunmariPlayAgain => 'Play again';

  @override
  String get kkeunmariBackHome => 'Home';

  @override
  String kkeunmariTimerSeconds(int n) {
    return '${n}s';
  }

  @override
  String get kkeunmariResultTitle => 'Game over';

  @override
  String kkeunmariResultBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n words',
      one: '1 word',
    );
    return 'You chained $_temp0.';
  }

  @override
  String get gameKkeunmariTitle => 'Word Chain';

  @override
  String get gameKkeunmariDesc => 'Last syllable → next word';

  @override
  String get vocabMasteryFresh => 'New';

  @override
  String get vocabMasteryLearning => 'Learning';

  @override
  String get vocabMasteryReviewDue => 'Review due';

  @override
  String get vocabMasteryStrong => 'Strong';

  @override
  String get scenariosPathTitle => 'Your path';

  @override
  String scenariosPathProgress(int done, int total) {
    return '$done/$total unlocked';
  }

  @override
  String get scenariosPathNextLabel => 'Next up';

  @override
  String get scenariosPathStartCta => 'Start';

  @override
  String get scenariosPathAllDone => 'All scenarios completed';

  @override
  String scenariosPathLevelProgress(Object level, int done, int total) {
    return '$level: $done/$total ★';
  }

  @override
  String get shareTooltip => 'Share';

  @override
  String get shareTitle => 'Share pack';

  @override
  String get shareGenerating => 'Creating code…';

  @override
  String get shareCodeLabel => 'Friend code';

  @override
  String get shareCopyCode => 'Copy code';

  @override
  String get shareCodeCopied => 'Code copied';

  @override
  String get shareViaApp => 'Share via app';

  @override
  String get shareExpiryNote => 'Code valid for 30 days.';

  @override
  String get shareError => 'Sharing failed. Are you online?';

  @override
  String get shareEmpty => 'This pack has no words.';

  @override
  String sharePackBody(Object name, int count, Object code) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return 'I’m sharing the vocabulary pack “$name” ($_temp0) from Hangul Sori with you! Enter code $code in the app to import it. hangul-sori.com';
  }

  @override
  String get redeemTooltip => 'Import with code';

  @override
  String get redeemTitle => 'Import pack';

  @override
  String get redeemHint => 'Enter the 6-character code';

  @override
  String get redeemAction => 'Import';

  @override
  String get redeemLoading => 'Importing pack…';

  @override
  String redeemSuccess(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return 'Imported “$name” ($_temp0)';
  }

  @override
  String get redeemNotFound => 'Code not found.';

  @override
  String get redeemExpired => 'This code has expired.';

  @override
  String get redeemError => 'Import failed. Are you online?';

  @override
  String get createWordbookCta => 'My word list';

  @override
  String get createWordbookTitle => 'New word list';

  @override
  String get createWordbookHint => 'Give your word list a name.';

  @override
  String get wbEditTooltip => 'Edit';

  @override
  String get wbEditTitle => 'Edit word list';

  @override
  String get wbAddWord => 'Add word';

  @override
  String get wbEditWordTitle => 'Edit word';

  @override
  String get wbEmptyTitle => 'No words yet';

  @override
  String get wbEmptyBody =>
      'Add your first word or let the app fill in the translation automatically.';

  @override
  String get wbFieldKorean => 'Korean';

  @override
  String get wbFieldMeaning => 'Meaning';

  @override
  String get wbFieldExample => 'Example sentence (optional)';

  @override
  String get wbAutoFill => 'Auto-fill';

  @override
  String get wbAutoFillRunning => 'Looking up translation…';

  @override
  String get wbAutoFillOffline =>
      'Auto-fill isn\'t available right now. Please enter the translation yourself.';

  @override
  String get wbSaveWord => 'Save';

  @override
  String get wbNeedKorean => 'Please enter a Korean word.';

  @override
  String get wbDeleteWordTitle => 'Delete word?';

  @override
  String get wbDeleteWordBody => 'This word will be removed from the list.';

  @override
  String get wbRenameTitle => 'Rename';

  @override
  String get wbRenameLabel => 'Name';

  @override
  String get wbStudyCards => 'Study cards';

  @override
  String get wbQuiz => 'Quiz';

  @override
  String get quizNeedMore => 'You need at least 4 words with a meaning.';

  @override
  String get quizQuestion => 'What does this word mean?';

  @override
  String quizScore(int correct, int total) {
    return '$correct / $total correct';
  }

  @override
  String get quizResultTitle => 'Quiz finished';

  @override
  String get quizResultBody => 'Nice work! Run the list again to improve.';

  @override
  String get quizAgain => 'Again';

  @override
  String get gameNewBest => 'New record!';

  @override
  String gameBestAccuracy(int percent) {
    return 'Best accuracy: $percent%';
  }

  @override
  String gameBestTries(int count) {
    return 'Best: $count tries';
  }

  @override
  String get clozeTitle => 'Fill in the Blank';

  @override
  String get clozeDesc => 'The missing word in a sentence';

  @override
  String get clozeInstruction => 'Choose the missing word.';

  @override
  String get clozeEmptyBody =>
      'No sentences for this level yet. Pick another level.';

  @override
  String get clozeLevelLabel => 'Level';

  @override
  String get clozeLevelAll => 'All';

  @override
  String get speedMatchTitle => 'Speed Match';

  @override
  String get speedMatchDesc => 'Match against the clock';

  @override
  String get speedMatchInstruction => 'Tap a Korean word, then its meaning.';

  @override
  String get speedMatchEmptyBody =>
      'There are not enough word pairs for this learning level yet.';

  @override
  String get speedMatchAllLevels => 'Use all learning levels';

  @override
  String speedMatchScore(int count) {
    return '$count pairs';
  }

  @override
  String speedMatchBest(int count) {
    return 'Best: $count pairs';
  }

  @override
  String get dailyTitle => 'Daily Challenge';

  @override
  String get dailyDesc => 'Daily puzzle · streak';

  @override
  String get dailyAlreadyDone =>
      'Already done today. You\'re in practice mode.';

  @override
  String dailyStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get satzArcadeTitle => 'Build a Sentence';

  @override
  String get satzArcadeDesc => 'Order words into a sentence';

  @override
  String get homeWordbookCardTitle => 'My word list';

  @override
  String get homeWordbookCardDesc => 'Build and study your own list';

  @override
  String get csvImportTitle => 'Import CSV';

  @override
  String get csvImportHint =>
      'One line per word: Korean, meaning, example (optional). Comma-separated.';

  @override
  String get csvImportButton => 'Import';

  @override
  String get csvImportEmpty => 'No valid rows found.';

  @override
  String csvImportResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words imported',
      one: '1 word imported',
    );
    return '$_temp0';
  }

  @override
  String get wbPhotoCamera => 'Camera';

  @override
  String get wbPhotoGallery => 'Gallery';

  @override
  String get wbPhotoRemove => 'Remove photo';

  @override
  String get hardWordsTitle => 'Tricky words';

  @override
  String hardWordsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words just won’t stick',
      one: '1 word just won’t stick',
    );
    return '$_temp0';
  }

  @override
  String get hardWordsEmptyTitle => 'Nothing tricky';

  @override
  String get hardWordsEmptyBody =>
      'No especially hard words right now. If a word keeps giving you trouble, it will show up here.';

  @override
  String get hardWordsStudyCta => 'Drill these';

  @override
  String get hardWordsHardQuizCta => 'Hard quiz: spelling';

  @override
  String get hardQuizTitle => 'Hard quiz';

  @override
  String get hardQuizHint => 'Pick the correct spelling.';

  @override
  String hardQuizCorrectFeedback(String word) {
    return 'Correct: $word';
  }

  @override
  String hardQuizWrongFeedback(String word) {
    return 'The correct spelling is: $word';
  }

  @override
  String get hardQuizFinish => 'See result';

  @override
  String get hardQuizDoneTitle => 'Round complete!';

  @override
  String hardQuizScore(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String get wordWebTitle => 'Word web';

  @override
  String get wordWebHubDesc =>
      'Neighbors, opposites, and expressions for words you have already studied';

  @override
  String wordWebSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words with neighbors',
      one: '1 word with neighbors',
    );
    return '$_temp0';
  }

  @override
  String get wordWebEmptyTitle => 'No web yet';

  @override
  String get wordWebEmptyBody =>
      'Study words in a pack, the course, or a practice game. Then neighbors, opposites, and expressions for those exact words show up here.';

  @override
  String get wordWebLoadErrorTitle => 'Web did not load';

  @override
  String get wordWebLoadErrorBody =>
      'The word-web file could not be read. This is not an empty study history. Try again.';

  @override
  String get wordWebBrowseLevelCta => 'Browse words at my level';

  @override
  String get wordWebOpenVocabCta => 'Open vocabulary packs';

  @override
  String get wordWebQuizCta => 'Practice these words';

  @override
  String get wordWebLearnedFilter => 'Learned';

  @override
  String get wordWebLevelFilter => 'My level';

  @override
  String get wordWebSynonymSection => 'Similar words';

  @override
  String get wordWebAntonymSection => 'Opposites';

  @override
  String get wordWebRelatedSection => 'Related words';

  @override
  String get wordWebExpressionSection => 'Expressions';

  @override
  String get wordWebQuizTitle => 'Word-web practice';

  @override
  String get wordWebQuizHintSynonym => 'Which word sits close to it?';

  @override
  String get wordWebQuizHintAntonym => 'What is the opposite?';

  @override
  String get wordWebQuizHintRelated => 'What belongs with it?';

  @override
  String get wordWebQuizHintExpression =>
      'Which expression matches the meaning?';

  @override
  String get wordWebQuizDoneTitle => 'Round complete!';

  @override
  String get wordWebQuizEmptyTitle => 'No round yet';

  @override
  String get wordWebQuizEmptyBody =>
      'There are not enough comparison words for this set yet. Study the cards first, or learn a few more words.';

  @override
  String wordWebQuizScore(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String wordWebClusterCount(
    int synonyms,
    int antonyms,
    int related,
    int expressions,
  ) {
    return '$synonyms similar · $antonyms opposite · $related related · $expressions expression';
  }

  @override
  String get wordWebExampleLabel => 'In a sentence';

  @override
  String get wordWebCoachTitle => 'Your word web';

  @override
  String get wordWebCoachBody =>
      'Tap a word from your study history. The web shows neighbors, opposites, and an expression, separate from Hanja and nuance in the notebook.';

  @override
  String get wbMatching => 'Match pairs';

  @override
  String get wbMatchingHint => 'Tap a Korean word, then its meaning.';

  @override
  String get wbMatchingNeedMore => 'You need at least 2 words with a meaning.';

  @override
  String get wbMatchingDone => 'All pairs matched!';

  @override
  String get wbMatchingDoneBody => 'One more round?';

  @override
  String get wbTyping => 'Spell it';

  @override
  String get wbTypingNeedMore => 'You need at least 1 word with a meaning.';

  @override
  String get wbTypingPrompt => 'Type the Korean word:';

  @override
  String get wbTypingHint => 'In Korean…';

  @override
  String wbTypingAnswer(Object answer) {
    return 'Correct: $answer';
  }

  @override
  String get wbQuickPackName => '⭐ Quick saves';

  @override
  String get wbAddTooltip => 'Add to word list';

  @override
  String get wbCoachTitle => 'Save words here';

  @override
  String get wbCoachBody =>
      'Tap the bookmark to save a word and review it daily. You can also make your own flashcards from your word list.';

  @override
  String wbAdded(Object word) {
    return 'Added $word to your word list';
  }

  @override
  String wbAlreadyAdded(Object word) {
    return '$word is already in your word list';
  }

  @override
  String get wbAddFailed => 'Couldn\'t add it';

  @override
  String get wbViewAction => 'View';

  @override
  String get wbSearchTitle => 'My words';

  @override
  String get wbSearchHint => 'Search word or meaning…';

  @override
  String get wbSearchClear => 'Clear search';

  @override
  String get wbSearchEmpty => 'No matches';

  @override
  String get wbSearchNoWords =>
      'No saved words yet. Tap the bookmark icon while learning.';

  @override
  String wbSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get wbPosAll => 'All';

  @override
  String get wbSearchCta => 'Search my words';

  @override
  String comboPop(int count) {
    return '$count in a row';
  }

  @override
  String get pathTitle => 'Your path';

  @override
  String pathHanokStage(int n) {
    return 'Hanok · Stage $n/12';
  }

  @override
  String get pathHanokSub => 'Your courtyard grows with every pack you master.';

  @override
  String pathLevelPacks(int done, int total) {
    return '$done/$total packs';
  }

  @override
  String get pathNodeNow => 'Now';

  @override
  String get pathLockedHint => 'Clear the previous pack first.';

  @override
  String get pathSeeAll => 'Full path';

  @override
  String get pathJumpToNow => 'To the current step';

  @override
  String pathStoryEyebrow(Object level) {
    return '$level · Everyday life in Korea';
  }

  @override
  String get pathStoryTitle => 'You build from greetings to living.';

  @override
  String get pathStoryBody =>
      'Every section ends with a situation you can handle yourself.';

  @override
  String get pathOpenCurrentMission => 'Open current mission';

  @override
  String get pathCourseMissionsTitle => 'Course missions';

  @override
  String get pathCourseMissionsBody =>
      'One clear next step connects vocabulary, grammar, games, and scenarios.';

  @override
  String get pathStatusCurrent => 'continue';

  @override
  String get pathStatusCompleted => 'done';

  @override
  String get pathStatusBypassed => 'Start level bypassed';

  @override
  String get pathStatusNext => 'later';

  @override
  String pathCompletedCanDo(Object canDo) {
    return 'I can: $canDo';
  }

  @override
  String pathCurrentCanDo(Object canDo) {
    return 'Now: $canDo';
  }

  @override
  String get pathNextAfterEvidence => 'Next after your evidence';

  @override
  String get pathShowMorePractice => 'Show more practice';

  @override
  String get pathHideMorePractice => 'Hide more practice';

  @override
  String get gyeVoluntaryEyebrow => 'Optional learning community';

  @override
  String get gyeEmptyHeadline =>
      'Learning alone is complete. Together can feel warmer.';

  @override
  String get gyeEmptyLead =>
      'A 계 is a small group that holds a weekly intention together.';

  @override
  String get gyeFindOrCreate => 'Find or create a 계';

  @override
  String get gyeContinueSolo => 'Continue without a group';

  @override
  String get gyeEmptyPreviewCaption =>
      'This is a preview of the shared courtyard. It is not required for your learning path.';

  @override
  String get homePathCardTitle => 'Learning path';

  @override
  String get homePathCardSub => 'See where you are';

  @override
  String get homeBrowseTitle => 'Browse all';

  @override
  String get homeBrowseSub => 'Modules & games';

  @override
  String get notifStreakSaverTitle => '🔥 Don\'t lose your streak!';

  @override
  String get notifStreakSaverBody => 'A quick lesson keeps it alive.';

  @override
  String notifDailyStreakBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days in a row',
      one: '1 day in a row',
    );
    return '🔥 $_temp0. Want to keep it going today?';
  }

  @override
  String get ttsListen => 'Pronunciation';

  @override
  String ttsListenTarget(Object target) {
    return 'Pronunciation: $target';
  }

  @override
  String get navProfile => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuestName => 'Guest';

  @override
  String get profileGuestBadge => 'Keep your streak, XP & hanok';

  @override
  String profileJourneyTitle(Object name) {
    return 'Your path, $name';
  }

  @override
  String profileJourneySummary(Object level, Object goal) {
    return '$level · $goal';
  }

  @override
  String get profileGuestDesc =>
      'Right now, your progress is only on this device. Back it up with Google to keep it when you switch phones.';

  @override
  String get profileConnectedBadge => 'Account connected';

  @override
  String profileConnectedProviderBadge(Object provider) {
    return 'Connected with $provider';
  }

  @override
  String get profileConnectedDesc =>
      'Your progress can now be backed up to the cloud.';

  @override
  String get profileStatStreak => 'Day streak';

  @override
  String get profileStatLevel => 'Level';

  @override
  String get profileStatWords => 'Words';

  @override
  String get profileViewStats => 'View all stats';

  @override
  String get profileLearningSection => 'My learning';

  @override
  String get profileEditAction => 'edit';

  @override
  String get profileLearningGoal => 'My goal';

  @override
  String get profileLearningGoalNotSet => 'Choose what brings you to Korean';

  @override
  String get profileLearningStartPoint => 'My starting point';

  @override
  String get profileLearningStartPointConfirmTitle => 'Change starting point?';

  @override
  String get profileLearningStartPointConfirmBody =>
      'This resets your current course progress, completed units, practice evidence, and scene checks. Saved vocabulary and account data remain intact.';

  @override
  String get profileLearningStartPointConfirmCancel => 'Cancel';

  @override
  String get profileLearningStartPointConfirmAction =>
      'Change and reset course progress';

  @override
  String get profileLearningStartPointChangeFailed =>
      'The starting point could not be changed. Try again.';

  @override
  String get profileLearningCompanion => 'Learning companion';

  @override
  String get profileSpaceSection => 'My space';

  @override
  String get profileGye => 'Group (계)';

  @override
  String get profileGyeDescription => 'Open your optional learning group';

  @override
  String get profileGyeLoading => 'Loading group…';

  @override
  String get profileGyeNone => 'No group selected';

  @override
  String get profilePrivacyAccount => 'Privacy & account';

  @override
  String get profilePrivacyAccountDescription =>
      'Data, backup, and account controls';

  @override
  String get profileLearningData => 'My learning data';

  @override
  String get profileLearningDataDescription =>
      'Export local learning progress as JSON';

  @override
  String get profileLearningDataPreparing => 'Preparing export…';

  @override
  String get profileLearningDataExportReady =>
      'Your learning data is ready to share.';

  @override
  String get profileLearningDataExportFailed =>
      'The export could not be prepared.';

  @override
  String get profileAccountDelete => 'Delete account';

  @override
  String get profileAccountDeleteDescription =>
      'Open the protected deletion flow';

  @override
  String profileSafeSituations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count safe situations',
      one: '1 safe situation',
      zero: 'no safe situations yet',
    );
    return '$_temp0';
  }

  @override
  String get profileProgressSection => 'My progress';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get accountNudgeTitle => 'Save your progress';

  @override
  String get accountNudgeBody =>
      'Connect with Google so your streak and vocabulary survive a phone change.';

  @override
  String get accountNudgeConnect => 'Connect with Google';

  @override
  String get accountNudgeLater => 'Later';

  @override
  String get accountSafeConnectTitle => 'Connect this account safely?';

  @override
  String get errorOffline =>
      'No internet. Your progress is safe on this device.';

  @override
  String get accountSafeConnectExplain =>
      'Your local and cloud data are reviewed before anything is replaced. An existing account is never overwritten automatically.';

  @override
  String get accountSafeConnectConfirm => 'Connect safely';

  @override
  String get accountOperationInProgress =>
      'Checking your account and learning progress safely…';

  @override
  String get accountOperationResumeTitle => 'Resume account switch';

  @override
  String get accountOperationResumeBody =>
      'The safe account switch is saved. Your data stays protected until every step is complete.';

  @override
  String get accountOperationResume => 'Resume';

  @override
  String get accountOperationCancel => 'Cancel switch';

  @override
  String get accountOperationBlockedTitle => 'Your account is protected';

  @override
  String get accountOperationBlockedBody =>
      'The switch was paused. Your existing data is untouched. You can try again later.';

  @override
  String get accountOperationRetryTitle => 'Connection not completed';

  @override
  String get accountOperationRetryBody =>
      'The safe check could not be completed. You can retry the same operation.';

  @override
  String get accountOperationSupportBody =>
      'If the operation stays blocked, contact support. Never share sign-in codes or recovery keys.';

  @override
  String get accountDeletionPendingTitle => 'Deletion will continue';

  @override
  String get accountDeletionPendingBody =>
      'The safe deletion operation is not complete yet. Retry the same operation; your request will not be created twice.';

  @override
  String get accountLockedCloudDeletionTitle => 'Cloud deletion will continue';

  @override
  String get accountLockedCloudDeletionBody =>
      'A saved cloud data deletion is not complete yet. Account actions stay locked until it finishes. You can continue the deletion now; it will not be created twice.';

  @override
  String get accountLockedResumeNow => 'Continue now';

  @override
  String get accountLockedRefresh => 'Refresh status';

  @override
  String get accountFailureReasonAppCheck =>
      'The app integrity check failed. Update the app or try again later.';

  @override
  String get accountFailureReasonOffline =>
      'No internet connection. Check your network and try again.';

  @override
  String get accountFailureReasonAuth =>
      'Your sign-in needs to be confirmed. Sign in again and retry.';

  @override
  String get accountFailureReasonServer =>
      'The server is temporarily unavailable. Try again in a few minutes.';

  @override
  String get settingsCloudResumeDeleteTitle => 'Continue cloud deletion';

  @override
  String get settingsCloudResumeDeleteBody =>
      'The saved deletion request will continue. It will not be created twice.';

  @override
  String settingsCloudLastBackup(String time) {
    return 'Last backup: $time';
  }

  @override
  String get settingsCloudLastBackupNever => 'No backup yet';

  @override
  String get settingsResetDoneJournalKept =>
      'Reset complete. One open account task was kept and will continue automatically.';

  @override
  String get gyeAccountTransitionPaused =>
      'An account change is in progress. Group actions are safely paused and return when it is complete.';

  @override
  String get authAppleSignIn => 'Sign in with Apple';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authProviderApple => 'Apple';

  @override
  String get authProviderGoogleAndApple => 'Google & Apple';

  @override
  String get consentTitle => 'Welcome to Hangul Sori';

  @override
  String get consentBody =>
      'Your learning progress stays on your device by default. Optional features such as cloud backup, study groups, photo word capture, and pronunciation audio process specific data on EU servers. See the privacy policy for details.';

  @override
  String get consentEyebrow => 'Before you begin';

  @override
  String get consentCardTitle => 'Privacy & learning account';

  @override
  String get consentCardBody =>
      'Clearly explained · adjustable in your profile at any time. Groups always remain optional.';

  @override
  String get consentDataOptIn =>
      'Optional: share anonymous usage statistics and crash reports so we can improve Hangul Sori. Off by default. Change it here or anytime in Settings.';

  @override
  String get consentContinueCta => 'Continue';

  @override
  String get consentPrivacyCta => 'Privacy policy';

  @override
  String get consentTermsCta => 'Terms of service';

  @override
  String get consentAgreeCta => 'Agree & start';

  @override
  String get consentFootnote =>
      'By continuing you agree to our Terms of Service and Privacy Policy.';

  @override
  String get consentAnalyticsOptIn =>
      'Share anonymous usage statistics (optional)';

  @override
  String get consentCrashOptIn => 'Share anonymous crash reports (optional)';

  @override
  String get consentOptionalHint =>
      'Both are optional and can be changed anytime in Settings.';

  @override
  String get consentInviteTitle => 'Show me where you get stuck';

  @override
  String get consentInviteBody =>
      'I never see what you\'re learning. Anonymous numbers just show me where a lot of learners get stuck at the same spot, and that\'s exactly where I fix things. Your name, email, and learning content stay on your phone.';

  @override
  String get consentInviteYes => 'Allow all';

  @override
  String get consentInviteNo => 'Only essentials';

  @override
  String get consentInviteCustomize => 'Choose individually';

  @override
  String get consentInviteSave => 'Save';

  @override
  String get grammarEasy => 'Got it';

  @override
  String get grammarHard => 'Difficult';

  @override
  String get grammarChoiceCta => 'Practice with examples';

  @override
  String get grammarChoiceTitle => 'Grammar practice';

  @override
  String get grammarChoiceEyebrow => 'Recognize the sentence';

  @override
  String get grammarChoiceInstruction =>
      'Which Korean grammar pattern matches the highlighted part?';

  @override
  String grammarChoicePromptSemantics(String sentence, String focus) {
    return 'Sentence: $sentence. Highlighted part: $focus.';
  }

  @override
  String get grammarChoiceCorrect => 'Correct.';

  @override
  String grammarChoiceIncorrect(String pattern) {
    return 'The matching pattern is: $pattern';
  }

  @override
  String get grammarChoiceKoreanExampleLabel => 'Example in Korean';

  @override
  String get grammarChoiceExplanationLabel => 'Why this fits';

  @override
  String get grammarChoiceFinish => 'See result';

  @override
  String get grammarChoiceDoneTitle => 'Round complete';

  @override
  String grammarChoiceScore(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String get grammarChoicePracticeOnly =>
      'This practice does not change your course progress.';

  @override
  String get grammarChoiceAgain => 'New round';

  @override
  String get grammarChoiceBack => 'Back to grammar';

  @override
  String get grammarChoiceUnavailableTitle => 'No practice available yet';

  @override
  String get grammarChoiceUnavailableBody =>
      'This level does not have enough reviewed examples yet.';

  @override
  String get grammarChoiceSaveError =>
      'We couldn\'t save this difficulty marker. You can still continue.';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscover => 'Explore';

  @override
  String get discoverEyebrow => 'Tools & culture';

  @override
  String get discoverTitle => 'Find exactly what you need.';

  @override
  String get discoverSubtitle =>
      'Scan, look something up, listen, or take a short break.';

  @override
  String get discoverSearchHint => 'Search: e.g. pronunciation, book, OCR…';

  @override
  String get discoverStartHere => 'Go straight to your goal';

  @override
  String get discoverAllTools => 'All features';

  @override
  String get discoverNoResults => 'No matching feature found.';

  @override
  String get discoverNoResultsHint =>
      'Try a need such as pronunciation, book, review, or conversation.';

  @override
  String get discoverCategoryAll => 'All';

  @override
  String get discoverCategoryLearn => 'Learn';

  @override
  String get discoverCategoryPractice => 'Practice';

  @override
  String get discoverCategoryWords => 'Words';

  @override
  String get discoverCategoryProgress => 'Your path';

  @override
  String get discoverCategoryForMe => 'For me';

  @override
  String get discoverCategoryLanguage => 'Language';

  @override
  String get discoverCategoryLeisure => 'Leisure';

  @override
  String get discoverPriorityBookTitle => 'Scan a book';

  @override
  String get discoverPriorityBookBody =>
      'Understand text from your course book';

  @override
  String get discoverPriorityPronunciationTitle => 'Hear pronunciation';

  @override
  String get discoverPriorityPronunciationBody => 'Compare sounds slowly';

  @override
  String get discoverPriorityWordsTitle => 'Dictionary & My words';

  @override
  String get discoverPriorityWordsBody => 'Find saved words again';

  @override
  String get navLearn => 'Learn';

  @override
  String get navPractice => 'Practice';

  @override
  String get navWordbook => 'Words';

  @override
  String get navGye => 'Group';

  @override
  String get gyeTabSubtitle => 'Learn together · 계';

  @override
  String get gyeExplainWhat =>
      'A 계 (gye) is a small group for learning Korean, and joining is up to you. Learning on your own works just as well.';

  @override
  String get gyeExplainWhy =>
      'A shared hanok shows how you cheer each other on. There is no competition here, and you do not need the group to make progress.';

  @override
  String get gyeExplainHow =>
      'Create a group or join with a 6-digit code when you are ready.';

  @override
  String get gyePrivacyTitle => 'What others see';

  @override
  String get gyePrivacyBody =>
      'It only shows that you contributed. Your answers, words, and assessment results stay private.';

  @override
  String get gyeExplainWhatShort => 'A small, voluntary study group.';

  @override
  String get gyeExplainWhyShort => 'A shared hanok, not a competition.';

  @override
  String get gyeExplainHowShort => 'Join with a 6-digit code.';

  @override
  String get gyeShowcaseCaption =>
      'This is what your shared hanok can look like';

  @override
  String get gyeExplainMore => 'Learn more';

  @override
  String get gyeWeeklyEyebrow => 'Together this week';

  @override
  String get gyeWeeklyTitle => 'Keep the courtyard lights on together.';

  @override
  String get gyeWeeklyBody =>
      'This count reflects completed packs in your current Gye. It is not a score, ranking, or record of answers.';

  @override
  String get gyePromisePickerLabel => 'This week\'s shared real-life scene';

  @override
  String get gyePromiseCafeOrder => 'Three people practise ordering politely';

  @override
  String get gyePromiseDirections =>
      'Three people practise asking for directions';

  @override
  String get gyePromiseSelfIntroduction =>
      'Three people practise introducing themselves';

  @override
  String get gyePromiseEyebrow => 'This week, together';

  @override
  String get gyePromiseCafeOrderTitle =>
      'Let three people practise ordering politely.';

  @override
  String get gyePromiseDirectionsTitle =>
      'Let three people practise asking for directions.';

  @override
  String get gyePromiseSelfIntroductionTitle =>
      'Let three people practise introducing themselves.';

  @override
  String get gyePromiseBody =>
      'Each person helps with one completed, matching learning action.';

  @override
  String get gyePromiseEligibility =>
      'Only the matching course-linked scene completed at 70% counts as a contribution.';

  @override
  String gyePromiseProgress(int done, int target) {
    return '$done of $target lanterns are lit';
  }

  @override
  String gyePromiseRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'contributions',
      one: 'contribution',
    );
    return '$count more course-linked scene $_temp0 this week';
  }

  @override
  String get gyePromiseContributionCompleteTitle => 'Anonymous contribution';

  @override
  String get gyePromiseContributionCompleteBody =>
      'A matching scene was completed. Identity and result stay private.';

  @override
  String get gyePromiseContributionPendingTitle => 'One light is still waiting';

  @override
  String get gyePromiseContributionPendingBody =>
      'Your next contribution can come from Today.';

  @override
  String get gyePromisePrivacyRule =>
      'No ranking. No pressure. Nobody can block another learner’s path.';

  @override
  String get gyePromiseSceneCta => 'Open today’s scene';

  @override
  String get gyeTodayFallbackCta => 'Go to Today';

  @override
  String get gyeTodayUnavailable =>
      'Today is unavailable right now. Please try again shortly.';

  @override
  String get gyePromiseIntentionAction => 'View weekly intention';

  @override
  String get gyeRulesAndMembers => 'Rules & members';

  @override
  String get gyeRulesTitle => 'Rules for a safe courtyard';

  @override
  String get gyeRulesBody =>
      'Encourage without comparing. Answers, results, and individual contributions stay private. Reporting and blocking are always available.';

  @override
  String get gyeOpenToday => 'Open today\'s learning';

  @override
  String get gyeCourtyardEyebrow => 'Your courtyard';

  @override
  String gyeCourtyardLightsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lanterns are lit today.',
      one: 'One lantern is lit today.',
      zero: 'The first lantern is waiting today.',
    );
    return '$_temp0';
  }

  @override
  String get gyeCourtyardLightsThree => 'Three lanterns are lit today.';

  @override
  String get gyeCourtyardTitle =>
      'A shared place for small, safe encouragement.';

  @override
  String get gyeCourtyardBody =>
      'The courtyard visual follows the existing weekly goal data. It does not change anyone\'s personal course or hanok.';

  @override
  String get gyeSafeMessage => 'Send a safe message';

  @override
  String get coachGyeTabTitle => 'Learn together';

  @override
  String get coachGyeTabBody =>
      'A study group (Gye) is a small, non-competitive group. Your learning progress grows a shared hanok.';

  @override
  String get motivationSheetTitle => 'Why are you learning Korean?';

  @override
  String get motivationSheetSubtitle =>
      'Pick your reason, and we\'ll choose encouragement that fits it.';

  @override
  String get motivationKpop => 'K-Pop';

  @override
  String get motivationKdrama => 'K-Dramas & Movies';

  @override
  String get motivationTravel => 'Travel to Korea';

  @override
  String get motivationCulture => 'Culture & Language';

  @override
  String get motivationLoved => 'Friends & Family';

  @override
  String get motivationCareer => 'Work & Study';

  @override
  String get motivationCurious => 'Just curious';

  @override
  String get motivationLineKpop =>
      'Soon you\'ll understand your favorite songs!';

  @override
  String get motivationLineKdrama => 'Soon you\'ll watch without subtitles!';

  @override
  String get motivationLineTravel =>
      'Soon you\'ll be able to order in Seoul with confidence!';

  @override
  String get motivationLineCulture => 'Every word opens a new world.';

  @override
  String get motivationLineLoved =>
      'Soon you\'ll speak to them from the heart!';

  @override
  String get motivationLineCareer => 'Korean opens new doors.';

  @override
  String get motivationLineCurious => 'Curiosity is the best teacher!';

  @override
  String get motivationChangeLabel => 'Why I\'m learning';

  @override
  String get homeDailyGoalLabel => 'Daily goal';

  @override
  String get homeDailyGoalDone => 'Daily goal reached!';

  @override
  String get cultureNoteTitle => 'K-Culture';

  @override
  String milestoneStreakTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak!',
      one: '1-day streak!',
    );
    return '$_temp0';
  }

  @override
  String milestoneLevelTitle(int count) {
    return 'Level $count reached!';
  }

  @override
  String milestoneVocabTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words learned!',
      one: '1 word learned!',
    );
    return '$_temp0';
  }

  @override
  String get milestoneStreakBody => 'Regular practice pays off. Keep it up!';

  @override
  String get milestoneLevelBody => 'Your Korean grows every single day.';

  @override
  String get milestoneVocabBody => 'Word by word, you\'re getting there!';

  @override
  String get milestoneCta => 'Keep going';

  @override
  String get feedbackCompletionContinue => 'Continue';

  @override
  String get practiceEyebrow => 'Without today\'s mission';

  @override
  String get practiceTitle => 'What do you want to strengthen?';

  @override
  String get practiceSubtitle => 'Choose an intention, not a game first.';

  @override
  String get practiceDueTitle => 'Review due words';

  @override
  String get practiceDueEmpty => 'Open a review whenever you want';

  @override
  String practiceDueContext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words are waiting for context',
      one: '1 word is waiting for context',
      zero: 'No words are waiting for context',
    );
    return '$_temp0';
  }

  @override
  String get practiceWordsPurposeTitle => 'Open my words';

  @override
  String get practiceSecLearn => 'Practice something in particular';

  @override
  String get practiceSecGames => 'Play';

  @override
  String get practiceSecWords => 'Your words';

  @override
  String get practiceSecSpace => 'Your learning space';

  @override
  String get practiceFocusedDescription => 'Pronunciation, grammar, or writing';

  @override
  String get practiceFreeDescription => 'Word chains, letters, short games';

  @override
  String get practiceWordsDescription => 'Saved words and books';

  @override
  String get practiceAllActivities => 'Show all activities';

  @override
  String get practiceHideAllActivities => 'Hide all activities';

  @override
  String get pathEvidenceTitle => 'How you recognize progress';

  @override
  String get pathEvidenceBody =>
      'Free browsing counts as history. A section becomes secure only through its matching active assessment and at least 70% in every linked scenario checkpoint.';

  @override
  String get coachBookTitle => 'Snap a page';

  @override
  String get coachBookStep1 => '📸 Take a photo of your textbook or a menu';

  @override
  String get coachBookStep2 => '🔍 Text is detected and analyzed automatically';

  @override
  String get coachBookStep3 => 'New words are saved straight to your word list';

  @override
  String get coachBookLimitNote => 'Daily limit: 20 pages';

  @override
  String get coachVocabPackTitle => 'Learn in 3 steps';

  @override
  String get coachVocabPackStep1 =>
      'Step 1 · Learn: tap or ? to flip, then swipe up. Heart = play later, bookmark = wordbook';

  @override
  String get coachVocabPackStep2 => 'Step 2 · Quiz: pick the right translation';

  @override
  String get coachVocabPackStep3 =>
      'Step 3 · Boss: listen and choose the meaning';

  @override
  String get coachPackStageQuiz => 'Quiz time! Pick the right translation.';

  @override
  String get coachPackStageBoss => 'The boss round is next. Listen closely!';

  @override
  String get coachBtnGotIt => 'Got it!';

  @override
  String get previewSkip => 'Skip';

  @override
  String get previewNext => 'Next';

  @override
  String get previewStart => 'Let\'s go';

  @override
  String get previewPage1Title => 'One photo beats 30 taps';

  @override
  String get previewPage1Body =>
      'Snap a textbook page or a menu. Sori identifies the words, grammar, and sentences, then saves them to your bookshelf. The photo stays on your device.';

  @override
  String get previewPage2Title => 'Your hanok grows';

  @override
  String get previewPage2Body =>
      'Each pack you master helps your hanok grow, from the foundation and pillars to the tiled roof and your own jongga courtyard. There are 12 stages.';

  @override
  String get previewPage3Title => 'Five minutes a day is enough';

  @override
  String get previewPage3Body =>
      'Taego checks in once a day and keeps your streak alive. Miss one? Streak Shield catches it for you.';

  @override
  String hubLearnLevel(int level) {
    return 'Level $level';
  }

  @override
  String hubLearnNextPack(String name) {
    return 'Next up: $name';
  }

  @override
  String get hubLearnAllDone => 'All packs completed!';

  @override
  String hubPracticeStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days in a row',
      one: '1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get hubPracticeStreakZero => 'Start today!';

  @override
  String hubWordbookSaved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n words saved',
      one: '1 word saved',
    );
    return '$_temp0';
  }

  @override
  String get hubWordbookEmpty => 'No words saved yet';

  @override
  String get settingsTutorialResetSection => 'Intro';

  @override
  String get settingsTutorialResetTitle => 'Reset intro';

  @override
  String get settingsTutorialResetSubtitle =>
      'Show the carousel & tips again on next launch';

  @override
  String get settingsTutorialResetDone => 'Intro reset';

  @override
  String get navTourNext => 'Next';

  @override
  String get navTourSkip => 'Skip';

  @override
  String get navTourDone => 'Done';

  @override
  String get coachHomeMissionTitle => 'Your first mission starts here';

  @override
  String get coachHomeMissionBody =>
      'Tap this card. Hangul Sori picks a task for you each day.';

  @override
  String get coachPracticeHubTitle => 'Practice';

  @override
  String get coachPracticeHubBody =>
      'Find games, words, and grammar here to review what you know.';

  @override
  String get coachHomeTab0Title => 'Home';

  @override
  String get coachHomeTab0Body => 'Your path & today\'s tasks in one place';

  @override
  String get coachHomeTab1Title => 'Practice';

  @override
  String get coachHomeTab1Body => 'Games, words & grammar to review';

  @override
  String get coachHomeTab2Title => 'Gye';

  @override
  String get coachHomeTab2Body => 'Reach your goals together';

  @override
  String get coachHomeTab3Title => 'Profile';

  @override
  String get coachHomeTab3Body => 'Stats, settings & account';

  @override
  String get coachHomePathTitle => 'Learning path';

  @override
  String get coachHomePathBody =>
      'Clear packs in order. Your tiger grows with you.';

  @override
  String get coachHomeBookTitle => 'Book snapshot';

  @override
  String get coachHomeBookBody =>
      'Turn a photo of your textbook into a word list';

  @override
  String get introSkipHint => 'Tap to skip';

  @override
  String get bookCaptureWebNotice =>
      '📱 ‘Snap a page’ only works in the mobile app (camera + on-device OCR).';

  @override
  String get bookshelfCreatePackNameHint => 'e.g. Step 1: Lesson 5';

  @override
  String get settingsMadeWith => 'Made with ❤ in Germany';

  @override
  String get coachChosungStep1Title => 'Syllable puzzle';

  @override
  String get coachChosungStep1Body =>
      'Fill in the dotted slots to complete the word';

  @override
  String get coachChosungStep2Title => 'Level & difficulty';

  @override
  String get coachChosungStep2Body =>
      'Choose a level from A1 to C2 and decide whether to show vowels';

  @override
  String get coachChosungStep3Title => 'Type your answer';

  @override
  String get coachChosungStep3Body => 'Type the full Korean word and confirm';

  @override
  String get coachSilbenStep1Title => 'Syllable crossword';

  @override
  String get coachSilbenStep1Body =>
      'Fill the grid: each row is a Korean word. Words cross at shared syllables. The red cell is selected.';

  @override
  String get coachSilbenStep2Title => 'Read the clues';

  @override
  String get coachSilbenStep2Body =>
      'The arrow shows the direction in the grid. The meaning and example sentence help. ○○ hides the target word.';

  @override
  String get coachSilbenStep3Title => 'Tap syllables';

  @override
  String get coachSilbenStep3Body =>
      'Tap a syllable below to fill the selected cell. Correct ones lock in green, wrong ones shake';

  @override
  String get coachWordleStep1Title => '6 attempts';

  @override
  String get coachWordleStep1Body =>
      'Guess the hidden word. You have 6 attempts.';

  @override
  String get coachWordleStep2Title => 'Use the clues';

  @override
  String get coachWordleStep2Body =>
      'Syllable count, word class and meaning help you narrow it down';

  @override
  String get coachWordleStep3Title => 'Input & colors';

  @override
  String get coachWordleStep3Body =>
      'Type → Enter · 🟩 correct · 🟨 wrong position · ⬜ not present';

  @override
  String get coachKkeunmariStep1Title => 'Last syllable counts';

  @override
  String get coachKkeunmariStep1Body =>
      'Start your word with the highlighted final syllable';

  @override
  String get coachKkeunmariStep2Title => 'Turn & timer';

  @override
  String get coachKkeunmariStep2Body =>
      'You have 30 seconds per turn. Can you beat the tiger?';

  @override
  String get coachKkeunmariStep3Title => 'Type a word';

  @override
  String get coachKkeunmariStep3Body =>
      'Enter a valid Korean word. The tiger responds automatically.';

  @override
  String get coachListeningStep1Title => 'Choose a situation';

  @override
  String get coachListeningStep1Body =>
      'Tap a card to select the scenario you want to listen to';

  @override
  String get coachListeningStep2Title => 'Speed';

  @override
  String get coachListeningStep2Body =>
      'One speed icon at the top. ? shows the translation on the line, not as a chip row.';

  @override
  String get coachListeningStep3Title => 'Line by line';

  @override
  String get coachListeningStep3Body =>
      'Fling up for the next line. Double-tap likes the line; it does not save to the wordbook.';

  @override
  String get coachHangulTitle => 'Three tabs for learning Hangul';

  @override
  String get coachHangulBody =>
      'Overview shows all characters · Cards help you practice · Write trains your strokes';

  @override
  String get coachGrammarStep1Title => 'Flip the card';

  @override
  String get coachGrammarStep1Body =>
      'Tap the card to reveal the explanation and examples';

  @override
  String get coachGrammarStep2Title => 'Filter & mark';

  @override
  String get coachGrammarStep2Body =>
      'Filter by level or type. Mark tricky cards with 🤔 as hard.';

  @override
  String get coachSmalltalkStep1Title => 'Pick a topic';

  @override
  String get coachSmalltalkStep1Body =>
      'Tap the topic field to choose from 18 categories';

  @override
  String get coachSmalltalkStep2Title => 'Pronunciation & wordbook';

  @override
  String get coachSmalltalkStep2Body =>
      'Tap a card to hear it. Use ＋ to save the phrase to your word list.';

  @override
  String get coachScenarioStep1Title => 'How scenarios work';

  @override
  String get coachScenarioStep1Body =>
      'Vocab → Dialogue → Grammar → Quests → Result. Work through them in that order.';

  @override
  String get coachScenarioStep2Title => 'Next & progress';

  @override
  String get coachScenarioStep2Body =>
      'Tap Next to advance · the bar at the top shows your progress';

  @override
  String get coachReviewStep1Title => 'Reveal the card';

  @override
  String get coachReviewStep1Body =>
      'Think of the meaning first. Then tap the card to check your answer.';

  @override
  String get coachReviewStep2Title => 'Got it or not?';

  @override
  String get coachReviewStep2Body =>
      '\"Got it\" extends the interval · \"Didn\'t know\" brings the card back sooner. After flipping you can also swipe: right = got it, left = didn\'t know.';

  @override
  String get coachLegacyVocabTitle => 'Flashcard';

  @override
  String get coachLegacyVocabBody =>
      'Tap to flip · long-press to hear it at slow speed';

  @override
  String get coachLearningPathTitle => 'Your learning path';

  @override
  String get coachLearningPathBody =>
      'Start with the highlighted current step and work forward from there.';

  @override
  String get coachBookshelfStep1Title => 'Create a wordbook';

  @override
  String get coachBookshelfStep1Body =>
      'Tap ＋ in the top right to create your own wordbook';

  @override
  String get coachBookshelfStep2Title => 'Search saved words';

  @override
  String get coachBookshelfStep2Body =>
      'Tap 🔍 to search all saved words and filter by part of speech';

  @override
  String get coachCpEditStep1Title => 'Add words';

  @override
  String get coachCpEditStep1Body =>
      'Tap ＋ Add word · or import via CSV · photo · auto-fill';

  @override
  String get coachCpEditStep2Title => '4 study modes';

  @override
  String get coachCpEditStep2Body =>
      'Cards · Matching · Typing · Quiz. Pick the mode that suits you.';

  @override
  String get coachCpPlayTitle => 'Study with flashcards';

  @override
  String get coachCpPlayBody =>
      'Tap to flip · \"Got it\" adds the word to the SRS review system';

  @override
  String get coachCpQuizTitle => 'Guess the meaning';

  @override
  String get coachCpQuizBody =>
      'Choose the correct meaning. Your result is saved for review.';

  @override
  String get coachCpMatchingTitle => 'Match pairs';

  @override
  String get coachCpMatchingBody =>
      'Tap a Korean word on the left, then tap its meaning on the right';

  @override
  String get coachCpTypingTitle => 'Type the word';

  @override
  String get coachCpTypingBody =>
      'See the meaning and type the Korean word. This takes more recall than simply recognizing it.';

  @override
  String get coachHardWordsTitle => 'Stubborn words';

  @override
  String get coachHardWordsBody =>
      'Words you keep forgetting appear here, ready for focused practice.';

  @override
  String get coachDojangTitle => 'Collect Dancheong stamps';

  @override
  String get coachDojangBody =>
      'Complete vocabulary packs to unlock all 14 Dancheong stamp designs';

  @override
  String get coachGyeStep1Title => 'Weekly goal';

  @override
  String get coachGyeStep1Body =>
      'See your shared progress here. Learning together can help you stay on track.';

  @override
  String get coachGyeStep2Title => 'Send a sticker';

  @override
  String get coachGyeStep2Body =>
      'Tap the smiley button to send an encouraging sticker to your group';

  @override
  String get coachProfileTitle => 'Your account';

  @override
  String get coachProfileBody =>
      'Connect with Google to keep your streak and vocabulary when you switch phones.';

  @override
  String get coachStatsTitle => 'Learning stats';

  @override
  String get coachStatsBody =>
      'Streak, XP and accuracy show how far you\'ve come';

  @override
  String get coachQuestsTitle => 'Quests & rewards';

  @override
  String get coachQuestsBody =>
      'Complete quests to earn decorations for your Hanok rooms';

  @override
  String get coachScenariosTitle => 'Situational dialogues';

  @override
  String get coachScenariosBody =>
      'Tap a scenario to practice real everyday situations. They unlock from A2 onwards.';

  @override
  String get questSatzBauenInstruction => 'Tap the words in the correct order';

  @override
  String get questCheckAnswer => 'Check answer';

  @override
  String get questReplayAudio => 'Listen again';

  @override
  String get questBuildAnswerLabel => 'Build your answer';

  @override
  String get questEmptyAnswerSlot => 'Empty answer slot';

  @override
  String get diktatInstruction => 'Listen and type what you hear';

  @override
  String get diktatSpacingHint => 'Almost! Check the word spacing';

  @override
  String get diktatShowMeaning => 'Show meaning';

  @override
  String get diktatSpellingHint => 'Almost there. Check your spelling.';

  @override
  String get questDiagOrder => 'The words are right, but the order is not.';

  @override
  String get questDiagParticle => 'Almost! Check the particle (조사)';

  @override
  String get questDiagCount => 'Check how many words you used';

  @override
  String get questDiagWord =>
      'One word does not fit. Check the highlighted word.';

  @override
  String get scenarioRoleplayTitle => 'Role-play';

  @override
  String get scenarioRoleplayHint =>
      'Your turn. Build the reply from the tiles.';

  @override
  String get scenarioRoleplayTurn => 'Your reply';

  @override
  String get scenarioRoleplayDoneTitle => 'Role-play complete!';

  @override
  String get scenarioRoleplayDoneBody =>
      'You carried the conversation yourself.';

  @override
  String get scenarioWriteAfterRoleplayTitle => 'Try it in your own words';

  @override
  String get scenarioWriteAfterRoleplayBody =>
      'Write one short Korean reply for this situation. This optional check does not affect your score.';

  @override
  String get scenarioWriteAfterRoleplayInputLabel => 'Your Korean sentence';

  @override
  String get scenarioWriteAfterRoleplayInputHint =>
      'Write a short reply in Korean';

  @override
  String get scenarioWriteAfterRoleplayCheck => 'Check sentence';

  @override
  String get scenarioWriteAfterRoleplayChecking => 'Checking…';

  @override
  String get scenarioWriteAfterRoleplayDownload => 'Download on-device checker';

  @override
  String get scenarioWriteAfterRoleplayDownloading => 'Downloading checker…';

  @override
  String get scenarioWriteAfterRoleplayOriginalLabel => 'Your original';

  @override
  String get scenarioWriteAfterRoleplaySuggestionLabel => 'Suggestion';

  @override
  String get scenarioWriteAfterRoleplayChangesLabel => 'Checked changes';

  @override
  String get scenarioWriteAfterRoleplayChangeReasonUnavailable =>
      'The on-device checker does not provide a verified reason for each change.';

  @override
  String get scenarioWriteAfterRoleplaySceneGrammarReference =>
      'Reference grammar from this scene';

  @override
  String get scenarioWriteAfterRoleplayWhyLabel => 'Scene grammar';

  @override
  String get scenarioWriteAfterRoleplayNoChanges => 'No changes suggested.';

  @override
  String get scenarioWriteAfterRoleplayFallbackTitle =>
      'Practice with this scene';

  @override
  String get scenarioWriteAfterRoleplayFallbackBody =>
      'Automatic proofreading isn\'t available here. You can still compare your sentence with the verified scene language and grammar.';

  @override
  String get scenarioWriteAfterRoleplayDownloadRequired =>
      'Download the on-device checker before checking your sentence.';

  @override
  String get scenarioWriteAfterRoleplayReady =>
      'Checker ready. Tap Check sentence again.';

  @override
  String get scenarioWriteAfterRoleplayAskCompanion =>
      'Ask about this scene\'s grammar';

  @override
  String get scenarioWriteAfterRoleplayCompanionTitle =>
      'Explanation from this scene';

  @override
  String get testerFeedbackCardTitle => 'Tiger Pulse';

  @override
  String get testerFeedbackCardBody =>
      'Two quick choices help us make Hangul Sori better.';

  @override
  String get testerFeedbackCardCta => 'Give the tiger a clue';

  @override
  String get testerFeedbackCategoryBug => 'Report a problem';

  @override
  String get testerFeedbackCategoryContent => 'Rate the learning content';

  @override
  String get testerFeedbackCategoryOther => 'Something else';

  @override
  String get testerFeedbackIssueAreaLabel => 'What is affected?';

  @override
  String get testerFeedbackIssueAreaUi => 'Display';

  @override
  String get testerFeedbackIssueAreaAnswer => 'Answer';

  @override
  String get testerFeedbackIssueAreaAudio => 'Audio';

  @override
  String get testerFeedbackIssueAreaTranslation => 'Translation';

  @override
  String get testerFeedbackIssueAreaNavigation => 'Navigation';

  @override
  String get testerFeedbackIssueAreaOther => 'Something else';

  @override
  String get testerFeedbackContentSignalLabel => 'How did this activity feel?';

  @override
  String get testerFeedbackContentSignalTooEasy => 'Too easy';

  @override
  String get testerFeedbackContentSignalRight => 'Just right';

  @override
  String get testerFeedbackContentSignalTooHard => 'Too hard';

  @override
  String get testerFeedbackContentSignalUnclear => 'Unclear';

  @override
  String get testerFeedbackContentFocusLabel => 'What made it feel that way?';

  @override
  String get testerFeedbackContentFocusExplanation => 'Explanation';

  @override
  String get testerFeedbackContentFocusExamples => 'Examples';

  @override
  String get testerFeedbackContentFocusQuestions => 'Tasks';

  @override
  String get testerFeedbackContentFocusPace => 'Pace';

  @override
  String get testerFeedbackContentFocusAudio => 'Audio';

  @override
  String get testerFeedbackContentFocusTranslation => 'Translation';

  @override
  String get testerFeedbackContentFocusOther => 'Something else';

  @override
  String get testerFeedbackPulseLearningPrompt => 'How did this activity feel?';

  @override
  String get testerFeedbackPulseBookPrompt =>
      'How reliable did this result feel?';

  @override
  String get testerFeedbackPulseQuestPrompt =>
      'Did this quest feel worth completing?';

  @override
  String get testerFeedbackPulseMilestonePrompt =>
      'Did this celebration motivate you?';

  @override
  String get testerFeedbackPulseReasonPrompt => 'What made it feel that way?';

  @override
  String get testerFeedbackPulsePositiveReasonPrompt => 'What worked well?';

  @override
  String get testerFeedbackExperienceReasonPrompt =>
      'What influenced your answer?';

  @override
  String get testerFeedbackBookSignalPositive => 'Looks right';

  @override
  String get testerFeedbackBookSignalMixed => 'Partly right';

  @override
  String get testerFeedbackBookSignalNegative => 'Doesn\'t look right';

  @override
  String get testerFeedbackBookSignalUnsure => 'Not sure';

  @override
  String get testerFeedbackQuestSignalPositive => 'Very motivating';

  @override
  String get testerFeedbackQuestSignalMixed => 'A nice extra';

  @override
  String get testerFeedbackQuestSignalNegative => 'Not motivating';

  @override
  String get testerFeedbackQuestSignalUnsure => 'I didn\'t understand it';

  @override
  String get testerFeedbackMilestoneSignalPositive => 'Loved it';

  @override
  String get testerFeedbackMilestoneSignalMixed => 'Nice';

  @override
  String get testerFeedbackMilestoneSignalNegative => 'Too much';

  @override
  String get testerFeedbackMilestoneSignalUnsure => 'Not meaningful';

  @override
  String get testerFeedbackExperienceFocusKoreanText => 'Korean text';

  @override
  String get testerFeedbackExperienceFocusWordMeanings => 'Word meanings';

  @override
  String get testerFeedbackExperienceFocusGrammar => 'Grammar';

  @override
  String get testerFeedbackExperienceFocusTranslation => 'Translation';

  @override
  String get testerFeedbackExperienceFocusResultMissing => 'Missing result';

  @override
  String get testerFeedbackExperienceFocusGoal => 'Goal';

  @override
  String get testerFeedbackExperienceFocusDifficulty => 'Difficulty';

  @override
  String get testerFeedbackExperienceFocusReward => 'Reward';

  @override
  String get testerFeedbackExperienceFocusInstructions => 'Instructions';

  @override
  String get testerFeedbackExperienceFocusLength => 'Length';

  @override
  String get testerFeedbackExperienceFocusTiming => 'Timing';

  @override
  String get testerFeedbackExperienceFocusVisuals => 'Visuals';

  @override
  String get testerFeedbackExperienceFocusMessage => 'Message';

  @override
  String get testerFeedbackExperienceFocusFrequency => 'Frequency';

  @override
  String get testerFeedbackExperienceFocusOther => 'Something else';

  @override
  String get testerFeedbackBugExpectedLabel => 'What should have happened?';

  @override
  String get testerFeedbackBugExpectedHint =>
      'Briefly describe the expected behavior.';

  @override
  String get testerFeedbackBugActualLabel => 'What happened instead?';

  @override
  String get testerFeedbackBugActualHint =>
      'Briefly describe the actual behavior.';

  @override
  String get testerFeedbackBugFrequencyLabel => 'How often did this happen?';

  @override
  String get testerFeedbackBugFrequencyEveryTime => 'Every time';

  @override
  String get testerFeedbackBugFrequencySometimes => 'Sometimes';

  @override
  String get testerFeedbackBugFrequencyOnce => 'Once';

  @override
  String get testerFeedbackBugImpactLabel => 'How much did this affect you?';

  @override
  String get testerFeedbackBugImpactCanContinue => 'I could continue';

  @override
  String get testerFeedbackBugImpactSlowsLearning => 'It slowed me down';

  @override
  String get testerFeedbackBugImpactBlocksLearning => 'I couldn\'t continue';

  @override
  String get testerFeedbackBugRequired =>
      'Please complete every required bug report field.';

  @override
  String get testerFeedbackMessageLabel => 'Optional note';

  @override
  String get testerFeedbackMessageHint => 'Would you like to add anything?';

  @override
  String get testerFeedbackOtherMessageLabel => 'Your note';

  @override
  String get testerFeedbackOtherMessageHint =>
      'What else would you like to tell us?';

  @override
  String get testerFeedbackMessageRequired => 'Please write a short message.';

  @override
  String get testerFeedbackContentFeedbackRequired =>
      'Please choose both a signal and a focus.';

  @override
  String get testerFeedbackMessageTooLong =>
      'Your message can be at most 1,000 characters.';

  @override
  String get testerFeedbackSubmit => 'Send pulse';

  @override
  String get testerFeedbackCancel => 'Cancel';

  @override
  String get testerFeedbackBack => 'Back';

  @override
  String get testerFeedbackSubmitting => 'Sending feedback…';

  @override
  String get testerFeedbackSubmitted =>
      'Thanks. Your feedback helps us improve.';

  @override
  String get testerFeedbackStampAccepted => 'Stamp earned!';

  @override
  String get testerFeedbackPending =>
      'Saved on this device. We\'ll send it when you\'re online.';

  @override
  String get testerFeedbackSubmitFailed =>
      'Your feedback could not be sent yet.';

  @override
  String get testerFeedbackRetry => 'Try again';

  @override
  String get testerFeedbackPrivacyReminder =>
      'Do not include contact details, answers, personal data, or screenshots.';

  @override
  String get testerFeedbackMissionScenario => 'Complete a scenario';

  @override
  String get testerFeedbackMissionWordWork => 'Practise with words';

  @override
  String get testerFeedbackMissionListening => 'Complete a listening activity';

  @override
  String get testerFeedbackMissionGames => 'Complete a game round';

  @override
  String get testerFeedbackMissionLanguageForm => 'Practise grammar or Hangul';

  @override
  String get testerFeedbackCompleteGrammar => 'Finish grammar practice';

  @override
  String get testerFeedbackCompleteHangul => 'Finish Hangul practice';

  @override
  String get testerFeedbackCompleteDailyHangul => 'Finish today\'s character';

  @override
  String get testerFeedbackPromptScenario =>
      'Did any part feel like something you could really say in this situation?';

  @override
  String get testerFeedbackPromptWordWork =>
      'Do these words feel useful and memorable?';

  @override
  String get testerFeedbackPromptGrammar =>
      'Do the explanation and examples make the rule clear?';

  @override
  String get testerFeedbackPromptHangul =>
      'Does the connection between letter shape and sound feel natural?';

  @override
  String get testerFeedbackPromptGame =>
      'Would you play this game again? What would you change?';

  @override
  String get testerFeedbackPromptListening =>
      'Are the pace and voices easy to follow?';

  @override
  String get testerFeedbackPromptGeneric =>
      'What would make this activity better?';

  @override
  String testerFeedbackPassportProgress(int completed, int total) {
    return 'Tester passport $completed / $total';
  }

  @override
  String testerFeedbackNextMission(String mission) {
    return 'Next beta mission: $mission';
  }

  @override
  String get onboardingDiagnosticCta => 'Not sure? Answer 8 questions';

  @override
  String get placementTitle => 'Quick placement check';

  @override
  String placementProgress(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get placementNoRecording =>
      'No recording. Just choose the best answer.';

  @override
  String get placementSeeRecommendation => 'See recommendation';

  @override
  String get placementRecommendedStart => 'Recommended start';

  @override
  String placementScoreSummary(Object correct, Object total) {
    return 'You got $correct of $total right. This is only a recommendation: you can choose any level.';
  }

  @override
  String placementStartAt(Object level) {
    return 'Start at $level';
  }

  @override
  String get placementChooseYourself => 'Or choose yourself';

  @override
  String get courseMissionTitle => 'Your next mission';

  @override
  String get courseMissionTitleShort => 'Course mission';

  @override
  String get courseMissionLoadError => 'The course data could not be loaded.';

  @override
  String get courseMissionCompleteTitle => 'Mission complete';

  @override
  String get courseMissionCompleteBody =>
      'You have completed every learning step in this mission.';

  @override
  String get courseMissionNow => 'now';

  @override
  String get courseMissionPreviewTag => 'preview';

  @override
  String get courseMissionStartPractice => 'Start practice';

  @override
  String courseMissionBriefScene(String scene) {
    return 'Your next scene: $scene';
  }

  @override
  String courseMissionBriefTime(int minutes) {
    return '$minutes min to the scene';
  }

  @override
  String courseMissionBriefStepMeta(int current, int total, int minutes) {
    return 'Step $current of $total · $minutes min';
  }

  @override
  String courseMissionBriefRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more steps stay ready after this brief.',
      one: '1 more step stays ready after this brief.',
    );
    return '$_temp0';
  }

  @override
  String get courseMissionBriefStart => 'Start step 1';

  @override
  String get courseMissionBriefWhy => 'Why this scene?';

  @override
  String get courseMissionBriefStepVocab => 'Hear the key words';

  @override
  String get courseMissionBriefStepGrammar => 'Build the sentence';

  @override
  String get courseMissionBriefStepCloze => 'Choose the missing words';

  @override
  String get courseMissionBriefStepSatz => 'Put the sentence together';

  @override
  String get courseMissionBriefStepScenario => 'Speak in the scene';

  @override
  String get courseMissionBriefStepSmalltalk => 'Answer in the situation';

  @override
  String get courseMissionBriefListenTitle => 'Hear the situation';

  @override
  String get courseMissionBriefListenBody => 'Recognize the polite form';

  @override
  String get courseMissionBriefBuildTitle => 'Build your sentence';

  @override
  String get courseMissionBriefBuildBody => 'Choose the missing words';

  @override
  String get courseMissionBriefCheckpointTitle => 'Complete the final check';

  @override
  String get courseMissionBriefCheckpointBody =>
      'Answer the last task for this mission';

  @override
  String get courseMissionBriefSceneTitle => 'Speak in the scene';

  @override
  String get courseMissionBriefSceneBody => 'One real answer, no guessing';

  @override
  String get courseMissionBriefListenCta => 'Listen now';

  @override
  String get courseMissionBriefBuildCta => 'Build now';

  @override
  String get courseMissionBriefCheckpointCta => 'Start the final check';

  @override
  String get courseMissionBriefSceneCta => 'Start the scene';

  @override
  String courseMissionBriefMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get courseMissionPreviewNotice =>
      'You can preview this mission. Scores and progress count only when it is active.';

  @override
  String get courseReassessmentTitle => 'Prove your ability';

  @override
  String get courseReassessmentEyebrow => 'PRODUCTIVE EVIDENCE';

  @override
  String get courseReassessmentLoading => 'Preparing your task.';

  @override
  String get courseReassessmentLoadError =>
      'This assessment could not be loaded safely.';

  @override
  String get courseReassessmentError =>
      'The evidence could not be saved. Please try again.';

  @override
  String courseReassessmentStep(int current, int total) {
    return 'Evidence $current of $total';
  }

  @override
  String courseReassessmentProjectStep(int current, int total) {
    return 'Project step $current of $total';
  }

  @override
  String get courseReassessmentRole => 'Your role';

  @override
  String get courseReassessmentPrivacy =>
      'Free writing and notes are not sent to Firebase or analytics. Verified speaking is unavailable until its separate consent and privacy-preserving service are ready.';

  @override
  String get courseReassessmentAnswer => 'Your Korean answer';

  @override
  String get courseReassessmentAnswerHint =>
      'Express the meaning in your own words.';

  @override
  String courseReassessmentLength(int minimum, int maximum) {
    return '$minimum to $maximum Korean characters';
  }

  @override
  String courseReassessmentEvidencePoint(int index) {
    return 'Evidence point $index';
  }

  @override
  String get courseReassessmentEvidencePointHint =>
      'Write this point in Korean and include it in your complete answer.';

  @override
  String get courseReassessmentSourceForPoint => 'Source for this point';

  @override
  String get courseReassessmentSources => 'Compare the materials';

  @override
  String courseReassessmentSource(int index) {
    return 'Source $index';
  }

  @override
  String get courseReassessmentProjectReviewTitle =>
      'Review the sources before you respond';

  @override
  String get courseReassessmentProjectReviewBody =>
      'Read every newly introduced source and open its provenance. This receipt records only the source IDs, not your notes.';

  @override
  String get courseReassessmentProjectMarkReviewed =>
      'I read and compared this source';

  @override
  String get courseReassessmentProjectShowProvenance => 'Show provenance';

  @override
  String get courseReassessmentProjectHideProvenance => 'Hide provenance';

  @override
  String get courseReassessmentProjectCompleteReview =>
      'Complete source review';

  @override
  String get courseReassessmentProjectReviewing => 'Checking sources …';

  @override
  String get courseReassessmentProjectReviewIncomplete =>
      'Read every source and open each provenance note before continuing.';

  @override
  String get courseReassessmentConnectSources =>
      'Mark the relationships between sources';

  @override
  String get courseReassessmentRelationship => 'Role of this source';

  @override
  String get courseReassessmentSubmit => 'Check my answer';

  @override
  String get courseReassessmentSubmitEvidence => 'Check source connections';

  @override
  String get courseReassessmentChecking => 'Checking …';

  @override
  String get courseReassessmentOralUnavailableTitle =>
      'Verified speaking is not available yet';

  @override
  String get courseReassessmentOralUnavailableBody =>
      'The current 10-second read-aloud exercise only practices pronunciation, so it cannot issue this ability seal. A separate unscripted assessment lasting 45 to 120 seconds will be enabled only after its consent, privacy, and scoring service passes review.';

  @override
  String get courseReassessmentPrerequisiteTitle =>
      'An earlier piece of evidence is still missing';

  @override
  String get courseReassessmentPrerequisiteBody =>
      'Complete the linked evidence first. Your position in the course will not be rewound.';

  @override
  String get courseReassessmentOpenPrerequisite => 'Open missing evidence';

  @override
  String get courseReassessmentPassedTitle => 'Evidence passed';

  @override
  String courseReassessmentPassedBody(int score) {
    return '$score%. Only the result and its exact task provenance were saved.';
  }

  @override
  String get courseReassessmentTryAgainTitle => 'Not secure enough yet';

  @override
  String courseReassessmentTryAgainBody(int score) {
    return '$score%. Your answer was not saved. You can revise it now.';
  }

  @override
  String get courseReassessmentContinue => 'Open the next evidence task';

  @override
  String get courseReassessmentRetry => 'Revise my answer';

  @override
  String get courseReassessmentFinish => 'Done';

  @override
  String get courseReassessmentCompleteTitle => 'Speaking and writing verified';

  @override
  String get courseReassessmentCompleteBody =>
      'All required productive evidence for this ability has been checked. Your course position stayed unchanged.';

  @override
  String get courseReassessmentModeGuidedProduction =>
      'Guided original response';

  @override
  String get courseReassessmentModeDictation => 'Dictation';

  @override
  String get courseReassessmentModeConnectedProduction => 'Connected writing';

  @override
  String get courseReassessmentModeOpenWriting => 'Open writing';

  @override
  String get courseReassessmentModeOral => 'Oral delivery';

  @override
  String get courseReassessmentModeConnectedEvidence => 'Connect sources';

  @override
  String get courseReassessmentRoleSupport => 'supports the claim';

  @override
  String get courseReassessmentRoleContrast => 'shows a contrast';

  @override
  String get courseReassessmentRoleLimitation => 'limits the claim';

  @override
  String get courseReassessmentRoleComplement => 'adds complementary evidence';

  @override
  String get courseReassessmentRoleContext => 'provides context';

  @override
  String get courseReassessmentRoleStakeholder =>
      'shows a stakeholder perspective';

  @override
  String get courseReassessmentRoleCounterexample =>
      'provides a counterexample';

  @override
  String get courseSectionToday => 'What counts today';

  @override
  String get courseSectionFamilies => 'Expression families';

  @override
  String get courseSectionSurfaces => 'Real-life cards';

  @override
  String get courseSectionRepair => 'Quick repair';

  @override
  String get courseSectionPractice => 'Mission practice';

  @override
  String get coursePracticeVocab => 'Vocabulary practice';

  @override
  String get coursePracticeGrammar => 'Grammar cards';

  @override
  String get coursePracticeCloze => 'Fill the gap';

  @override
  String get coursePracticeSatz => 'Build a sentence';

  @override
  String get coursePracticeScenario => 'Scenario checkpoint';

  @override
  String get coursePracticeSmalltalk => 'Small talk';

  @override
  String get courseCheckpointCheck => 'Quick check';

  @override
  String get courseCheckpointGrammarPrompt =>
      'Which pattern fits this example?';

  @override
  String get courseCheckpointSmalltalkPrompt =>
      'Which relationship is this line safe for?';

  @override
  String get courseCheckpointCorrect =>
      'Correct. This mission has recorded evidence.';

  @override
  String get courseCheckpointIncorrect =>
      'Review it once more. The safe choice is marked.';

  @override
  String get courseCheckpointSaved => 'Already saved in this session.';

  @override
  String get courseCheckpointSaveError =>
      'Your progress could not be saved. Please try again.';

  @override
  String get courseStatePreview => 'Preview';

  @override
  String get courseStateIntroduced => 'Introduced';

  @override
  String get courseStatePractice => 'Practice';

  @override
  String get courseStateCheckpointPassed => 'Checkpoint passed';

  @override
  String get courseStateReviewDue => 'Quick repair';

  @override
  String get courseStateStable => 'Stable';

  @override
  String get courseAxisBatchim => 'final consonant (받침)';

  @override
  String get courseAxisSentenceRole => 'sentence role';

  @override
  String get courseAxisRelationship => 'relationship and situation';

  @override
  String get courseAxisSetting => 'place and purpose';

  @override
  String get courseUsageOfficial => 'official setting';

  @override
  String get courseUsageEverydayPolite => 'polite everyday speech';

  @override
  String get courseUsageCloseOnly => 'only with a close relationship';

  @override
  String get courseUsageOfficialOrService => 'official or service setting';

  @override
  String get courseUsageFriendlyPolite => 'friendly, polite speech';

  @override
  String get courseUsageServiceRequest => 'service request';

  @override
  String get courseUsagePaymentNotice => 'payment notice';

  @override
  String get moduleBadgeNew => 'NEW';

  @override
  String get moduleBadgeDue => 'DUE';

  @override
  String get homeMadangEyebrow => 'Today in the Sarangbang';

  @override
  String get homeSarangbangCta => 'Study in the Sarangbang';

  @override
  String get homeTodayEyebrow => 'Your real-life action today';

  @override
  String get homeTodayFirst => 'Today first';

  @override
  String get homeTodayMissionStart => 'Start this scene';

  @override
  String get homeTodayCourseAction => 'Practice this action';

  @override
  String get homeTodayPackAction => 'Practice these words';

  @override
  String get homeTodayReviewAction => 'Review';

  @override
  String get homeTodayScenarioAction => 'Practice this scene';

  @override
  String get homeTodayPackDescription => 'Practice the words you need next.';

  @override
  String homeTodayReviewMission(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Review $n words in context',
      one: 'Review 1 word in context',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayReviewDescription => 'Give your safe sentences a voice.';

  @override
  String homeTodayReviewLead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n words are ready before anything new is added.',
      one: '1 word is ready before anything new is added.',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayNextAction => 'Your next action';

  @override
  String get homeTodayReviewReasonTitle => 'Why review today?';

  @override
  String get homeTodayReviewReason =>
      'So greetings, requests, and answers are easier to reach in the next scene.';

  @override
  String get homeTodayReviewTime =>
      'About 3 minutes · then your path continues.';

  @override
  String get homeUnavailableEyebrow => 'Connection paused';

  @override
  String get homeUnavailableTitle => 'Your path is waiting for you.';

  @override
  String get homeUnavailableDescription =>
      'New group and account actions briefly need internet. Your saved reviews are ready.';

  @override
  String get homeUnavailableDescriptionNoReview =>
      'New group and account actions briefly need internet. Try the connection again.';

  @override
  String get homeUnavailableSafeTitle => 'Safe to do now';

  @override
  String get homeUnavailableSafeBody =>
      'Review saved words and view previous content.';

  @override
  String get homeUnavailableCta => 'Review saved words';

  @override
  String get homeUnavailableRetry => 'Try again';

  @override
  String get homeUnavailableRetryGeneric => 'Try again';

  @override
  String get homeRemoteUnavailableEyebrow => 'Service paused';

  @override
  String get homeRemoteUnavailableTitle => 'Your path is still saved.';

  @override
  String get homeRemoteUnavailableDescription =>
      'The online service is not responding right now. Your saved reviews are ready.';

  @override
  String get homeRemoteUnavailableDescriptionNoReview =>
      'The online service is not responding right now. Try again shortly.';

  @override
  String get homeLocalUnavailableEyebrow => 'Today needs another try';

  @override
  String get homeLocalUnavailableTitle => 'Your saved learning is still safe.';

  @override
  String get homeLocalUnavailableDescription =>
      'Today could not be prepared from the local learning data. Your saved reviews are still ready.';

  @override
  String get homeLocalUnavailableDescriptionNoReview =>
      'Today could not be prepared from the local learning data. Try loading it again.';

  @override
  String get homeEmptyCta => 'Review saved words';

  @override
  String get homeTodayScenarioDescription =>
      'Listen, choose, and speak the scene.';

  @override
  String get homeHanokPreviewTitle => 'My Hanok';

  @override
  String get homeHanokPreviewBody => 'Your learning makes your Hanok grow.';

  @override
  String get homeHanokPreviewCta => 'Open my Hanok';

  @override
  String homeFocusDate(String weekday) {
    return 'Today · $weekday';
  }

  @override
  String get homeFocusBuildTitle => 'Your house grows with real ability.';

  @override
  String get homeFocusMore => 'More learning options';

  @override
  String get homeFocusLess => 'Hide learning options';

  @override
  String get homeFocusLaterTitle => 'Later today';

  @override
  String homeFocusLaterBody(int count) {
    return '$count reviews stay ready after your first action.';
  }

  @override
  String hanokNarrativeVerified(String stage, String canDo) {
    return 'Structure: $stage. Verified: $canDo';
  }

  @override
  String hanokNarrativeNext(String stage, String canDo) {
    return 'Structure: $stage. Next: $canDo';
  }

  @override
  String hanokNarrativeStarting(String stage) {
    return 'Structure: $stage. Begin with your first scene.';
  }

  @override
  String get hanokNarrativeMaterialSource =>
      'Course scenes shape the structure. Packs, reviews, and quests add materials and decor.';

  @override
  String get sarangbangTitle => 'Study room';

  @override
  String get sarangbangEmptyTitle => 'Nothing to arrange yet';

  @override
  String get sarangbangEmptyBody =>
      'Finish quests and open your bojagi bundle. Then you can furnish the room.';

  @override
  String get sarangbangPickTitle => 'What goes here?';

  @override
  String get sarangbangClear => 'Leave this spot empty';

  @override
  String get sarangbangHubDesc => 'Continue learning in the Sarangbang.';

  @override
  String get bojagiTitle => 'Bojagi bundle';

  @override
  String get bojagiLoading => 'Preparing your bundle…';

  @override
  String get bojagiOpenHint => 'Tap the knot to open the bundle.';

  @override
  String get bojagiPickTitle => 'Pick one';

  @override
  String get bojagiPickBody =>
      'Whatever you leave stays in the pool and can turn up in a later bundle.';

  @override
  String bojagiChooseDecoration(String name) {
    return 'Choose $name';
  }

  @override
  String get bojagiEmptyTitle => 'No bundle waiting';

  @override
  String get bojagiEmptyBody => 'Finish a quest and you get a bundle for it.';

  @override
  String get bojagiAllOwnedTitle => 'Nothing new inside';

  @override
  String get bojagiAllOwnedBody =>
      'You already own all three pieces from this bundle.';

  @override
  String get bojagiProblemTitle => 'This bundle will not open right now';

  @override
  String get bojagiProblemBody =>
      'Try again in a moment. Your bundle is not lost.';

  @override
  String get bojagiRetry => 'Try again';

  @override
  String get bojagiClaimedTitle => 'Got it!';

  @override
  String bojagiClaimedAnnouncement(String name) {
    return 'Got it: $name';
  }

  @override
  String get bojagiGoToRoom => 'Place it in the room';

  @override
  String get bojagiNext => 'Open the next bundle';

  @override
  String get bojagiCollectionCompleteTitle => 'Collection complete';

  @override
  String get bojagiCollectionCompleteBody =>
      'You already own every room piece. Archive this bundle to continue.';

  @override
  String get bojagiArchiveComplete => 'Archive bundle';

  @override
  String get hanokWorldTitle => 'My Hanok world';

  @override
  String get hanokWorldEarlyEyebrow => 'Your courtyard · A1';

  @override
  String get hanokWorldEarlyTitle =>
      'Your first scene is the start of your Hanok.';

  @override
  String get hanokWorldEarlyBody =>
      'Every everyday sentence you can use confidently strengthens your foundation.';

  @override
  String hanokWorldEarlyVerifiedBody(Object canDo) {
    return 'Your foundation stands: $canDo';
  }

  @override
  String get hanokWorldMapEyebrow => 'Your walkable courtyard';

  @override
  String get hanokWorldMapTitle => 'Where would you like to go?';

  @override
  String get hanokWorldMapBody =>
      'Each building takes you to a part of Hangul Sori.';

  @override
  String get hanokWorldOpenNextScene => 'See the next scene';

  @override
  String get hanokWorldNextBeamTitle => 'Next building step';

  @override
  String get hanokWorldExploreHouse => 'Explore my house';

  @override
  String hanokWorldSafeSceneProgress(int current, int total) {
    return '$current of $total scenarios mastered';
  }

  @override
  String get hanokWorldIntro =>
      'Continue learning as your Hanok grows. Each completed building leads to an area of Hangul Sori.';

  @override
  String get hanokWorldLegacyTitle => 'Your courtyard is growing';

  @override
  String get hanokWorldLegacyBody =>
      'Finish A1 and A2. Your first B1 progress opens the full Hanok map.';

  @override
  String get hanokWorldMapHint =>
      'Tap a completed building to continue learning there.';

  @override
  String get hanokWorldOpenSarangbang => 'Study in the Sarangbang';

  @override
  String get hanokWorldProgress => 'Your Hanok construction progress';

  @override
  String get hanokWorldGyeBridgeTitle => 'The Gye courtyard';

  @override
  String get hanokWorldGyeBridgeBody =>
      'The Gye courtyard is separate from your private Hanok. Meet your learning group there.';

  @override
  String get hanokWorldGyeBridgeOpen => 'Visit the Gye courtyard';

  @override
  String get hanokWorldPlacesTitle => 'Show places as a list';

  @override
  String get hanokWorldPlacesBody =>
      'Choose an available place from this list.';

  @override
  String get hanokMapPlaceSarangbang => '사랑방\nStudy today';

  @override
  String get hanokMapPlaceDaecheong => '대청마루\nYour path';

  @override
  String get hanokMapPlaceHaengrang => '행랑채\nPractice';

  @override
  String get hanokMapPlaceAnchae => '안채\nWords';

  @override
  String get hanokMapPlaceHuwon => '후원\nTasks';

  @override
  String get hanokMapPlaceSadang => '사당\nAchievements';

  @override
  String get hanokZoneSarangbang => '사랑방 · Your scene today';

  @override
  String get hanokZoneDaecheong => '대청마루 · Your path';

  @override
  String get hanokZoneHaengrang => '행랑채 · Practice';

  @override
  String get hanokZoneAnchae => '안채 · My words';

  @override
  String get hanokZoneHuwon => '후원 · Tasks';

  @override
  String get hanokZoneSadang => '사당 · Achievements';

  @override
  String get hanokWorldPurposeSarangbang =>
      'Return to today\'s scene and the expressions you have earned.';

  @override
  String get hanokWorldPurposeDaecheong =>
      'View your course path and choose the next available mission.';

  @override
  String get hanokWorldPurposeHaengrang =>
      'Choose a focused practice or a short game.';

  @override
  String get hanokWorldPurposeAnchae =>
      'Open your saved words, books, and personal learning collection.';

  @override
  String get hanokWorldPurposeHuwon =>
      'Choose the letter of the day or a quest.';

  @override
  String get hanokWorldPurposeSadang =>
      'View the milestones in your learning path.';

  @override
  String get hanokWorldPurposeGyeRoad =>
      'The shared Gye courtyard stays separate from your private Hanok.';

  @override
  String get hanokWorldSelectPlaceTitle => 'Choose an available place';

  @override
  String get hanokWorldSelectPlaceBody =>
      'Tap a building on the map or choose one from the list.';

  @override
  String hanokWorldPlaceReadyBody(String place) {
    return '$place is now available.';
  }

  @override
  String hanokWorldOpenPlace(String place) {
    return 'Enter $place';
  }

  @override
  String get hanokWorldTodayMarker => 'Today\'s study';

  @override
  String hanokWorldTodaySceneDetail(int minutes, String expression) {
    return '$minutes minutes · say “$expression”';
  }

  @override
  String get hanokWorldGoThere => 'Go there';

  @override
  String hanokWorldRevealTitle(String place) {
    return '$place is complete';
  }

  @override
  String get hanokWorldRevealBody => 'Your Hanok has grown by one area.';

  @override
  String get hanokWorldRevealContinue => 'Continue to the map';

  @override
  String get hanokVenueFurnishRoom => 'Furnish this room';

  @override
  String get hanokVenueAnbangBody =>
      'Find your saved words, books, and learning collections here.';

  @override
  String get hanokVenueDaecheongBody =>
      'Continue your learning path or furnish this room.';

  @override
  String get hanokVenueHaengrangBody =>
      'Start another practice round in the entrance wing.';

  @override
  String get hanokVenueHuwonBody =>
      'Use the rear garden for the letter of the day or a new quest.';

  @override
  String get hanokVenueSadangBody =>
      'View the milestones in your learning path in the shrine.';

  @override
  String get sarangbangStudyTitle => 'Sarangbang';

  @override
  String get sarangbangStudyIntroTitle => 'What you learned today';

  @override
  String get sarangbangStudyIntroBody =>
      'Find your learning progress for today here.';

  @override
  String get sarangbangStudySceneLabel => 'Your learning room';

  @override
  String get sarangbangStudyFurnish => 'Furnish the study room';

  @override
  String get sarangbangFurnishTitle => 'Furnish';

  @override
  String get sarangbangFurnishBody =>
      'You receive new objects as clearly marked rewards.';

  @override
  String get sarangbangStoredTitle => 'Collected today';

  @override
  String get sarangbangStoredEmpty =>
      'New expressions and mastered scenarios appear here once you unlock them.';

  @override
  String sarangbangStoredBody(Object detail) {
    return '$detail · Your current scene stays selected on Home.';
  }

  @override
  String sarangbangStoredRecord(int expressions, int scenes, int beams) {
    String _temp0 = intl.Intl.pluralLogic(
      expressions,
      locale: localeName,
      other: '$expressions expressions',
      one: '1 expression',
      zero: 'No expressions',
    );
    String _temp1 = intl.Intl.pluralLogic(
      scenes,
      locale: localeName,
      other: '$scenes mastered scenarios',
      one: '1 mastered scenario',
      zero: 'no mastered scenarios',
    );
    String _temp2 = intl.Intl.pluralLogic(
      beams,
      locale: localeName,
      other: '$beams beams in the construction plan',
      one: '1 beam in the construction plan',
      zero: 'no beams in the construction plan',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get sarangbangOpenToday => 'Open today\'s scene';

  @override
  String get sarangbangReturnCourtyard => 'To the courtyard';

  @override
  String get personalRoomAnbangTitle => 'Anbang';

  @override
  String get personalRoomDaecheongTitle => 'Daecheongmaru';

  @override
  String get personalRoomAnbangBody =>
      'A quiet inner room for the words and moments you keep.';

  @override
  String get personalRoomDaecheongBody =>
      'An open hall where your learning path can continue.';

  @override
  String get personalRoomEmptyHint =>
      'Open a Bojagi bundle to add your first room piece.';

  @override
  String get personalRoomLockedTitle => 'This room is still being built';

  @override
  String get personalRoomLockedBody =>
      'Continue the learning path to open this part of your Hanok.';

  @override
  String get personalRoomReturnToMap => 'Back to the Hanok map';

  @override
  String get personalRoomAnbangStudy => 'Explore my collection';

  @override
  String get personalRoomDaecheongStudy => 'Continue the learning path';

  @override
  String get personalRoomEditorHint =>
      'Drag a piece anywhere in the room. Use two fingers to rotate and resize it. The toolbar also works without gestures.';

  @override
  String get personalRoomInventoryTitle => 'My decorating chest';

  @override
  String get personalRoomInventoryDecorations => 'Furnishings';

  @override
  String get personalRoomInventoryStickers => 'Stickers';

  @override
  String get personalRoomInventoryStamps => 'Stamps';

  @override
  String get personalRoomNoDecorations =>
      'No furnishings yet. Open a Bojagi bundle to receive one.';

  @override
  String get personalRoomNoStamps =>
      'No Dancheong stamps yet. Complete a word pack to earn one.';

  @override
  String personalRoomSelectedItem(String item) {
    return 'Selected: $item';
  }

  @override
  String get personalRoomMoveLeft => 'Move left';

  @override
  String get personalRoomMoveRight => 'Move right';

  @override
  String get personalRoomMoveUp => 'Move up';

  @override
  String get personalRoomMoveDown => 'Move down';

  @override
  String get personalRoomMakeSmaller => 'Make smaller';

  @override
  String get personalRoomMakeLarger => 'Make larger';

  @override
  String get personalRoomRotateLeft => 'Rotate left';

  @override
  String get personalRoomRotateRight => 'Rotate right';

  @override
  String get personalRoomSendBackward => 'Send one layer backward';

  @override
  String get personalRoomBringForward => 'Bring one layer forward';

  @override
  String get personalRoomRemoveItem => 'Return to the chest';

  @override
  String personalRoomAddItem(String item) {
    return 'Place $item in the room';
  }

  @override
  String get personalRoomItemInUse => 'Already used in a room';

  @override
  String get personalRoomStickerLimit =>
      'Another copy cannot be placed here. Put something away first.';

  @override
  String get personalRoomSaveFailed =>
      'The arrangement could not be saved. Try again.';

  @override
  String get personalRoomFutureLayout =>
      'This arrangement comes from a newer app version and remains read-only.';

  @override
  String get personalRoomSelectItemHint => 'Select to arrange';

  @override
  String get personalRoomStickerFallback => 'Sticker';

  @override
  String get personalRoomStampFallback => 'Dancheong stamp';

  @override
  String get decorNameMunbangsau => 'Scholar\'s writing set (문방사우)';

  @override
  String get decorNameSeoan => 'Writing desk (서안)';

  @override
  String get decorNameChaekgado => 'Bookshelf screen (책가도)';

  @override
  String get decorNameGatBuchae => 'Hat and fan (갓·부채)';

  @override
  String get decorNameJagaeMungap => 'Mother-of-pearl chest (자개 문갑)';

  @override
  String get decorNameSoban => 'Tray table (소반)';

  @override
  String get decorNameSagunjaMaehwa => 'Plum blossom scroll (매화)';

  @override
  String get decorNameSagunjaNan => 'Orchid scroll (난초)';

  @override
  String get decorNameSagunjaGuk => 'Chrysanthemum scroll (국화)';

  @override
  String get decorNameSagunjaJuk => 'Bamboo scroll (대나무)';

  @override
  String get decorNamePyeonaek => 'Name plaque (편액)';

  @override
  String get decorNameJangdokdae => 'Jangdokdae (jar terrace)';

  @override
  String get decorNameMaehwa => 'Plum tree (매화)';

  @override
  String get decorNameSonamu => 'Old pine (노송)';

  @override
  String get decorNamePond => 'Pond & carp (연못)';

  @override
  String get decorNameSeokdeung => 'Stone lantern (장명등)';

  @override
  String get decorNamePunggyeong => 'Wind chime (풍경)';

  @override
  String get decorNameDoldam => 'Stone wall (돌담)';

  @override
  String get decorNameKkachiNest => 'Magpie nest (까치 둥지)';

  @override
  String get decorNameDokkaebiFire => 'Goblin fire (도깨비불)';

  @override
  String get decorNameSeollalFlag => 'Lunar New Year Yutnori (윷놀이)';

  @override
  String get decorNameChuseokMoon => 'Chuseok full moon (보름달)';

  @override
  String get decorNameHangeuldayPlaque => 'Hangul Day Sejong plaque (세종 편액)';

  @override
  String get decorNameKite => 'Children\'s Day kite (연)';

  @override
  String get decorNameSabangtakja => 'Open shelf stand (사방탁자)';

  @override
  String get decorNameBoryoSet => 'Master\'s floor seat (보료)';

  @override
  String get decorNameBangseokPair => 'Floor cushions (방석)';

  @override
  String get decorNameBandaji => 'Front-opening chest (반닫이)';

  @override
  String get decorNameHwaro => 'Charcoal brazier (화로)';

  @override
  String get decorNameDeungjan => 'Oil lamp stand (등잔대)';

  @override
  String get decorNameGeomungo => 'Geomungo zither (거문고)';

  @override
  String get decorNameBaduk => 'Baduk board (바둑판)';

  @override
  String get decorNameMokchim => 'Wooden pillow (목침)';

  @override
  String get decorNameByeongpungSmall => 'Two-panel screen (소병풍)';

  @override
  String get decorNameGobi => 'Letter rack (고비)';

  @override
  String get decorNameHyangno => 'Incense burner (향로)';

  @override
  String get decorNameFallback => 'Decoration';

  @override
  String get stickerNameTigerCheer => 'Cheering tiger';

  @override
  String get stickerNameTigerClap => 'Clapping tiger';

  @override
  String get stickerNameTigerSurprised => 'Surprised tiger';

  @override
  String get stickerNameTigerSad => 'Sad tiger';

  @override
  String get stickerNameTigerLove => 'Loving tiger';

  @override
  String get stickerNameMagpieDance => 'Dancing magpie';

  @override
  String get stickerNameMagpieWave => 'Waving magpie';

  @override
  String get stickerNameMagpieSleep => 'Sleeping magpie';

  @override
  String get stickerNameMagpieSing => 'Singing magpie';

  @override
  String get stickerNameMagpieEncourage => 'Encouraging magpie';

  @override
  String get stickerNameDancheongFlower => 'Dancheong flower';

  @override
  String get stickerNameDancheongStar => 'Dancheong star';

  @override
  String get stickerNameDancheongCloud => 'Dancheong cloud';

  @override
  String get stickerNameDancheongLantern => 'Dancheong lantern';

  @override
  String get stickerNameDancheongHanji => 'Hanji paper';

  @override
  String get stickerNameHangulKk => 'ㅋㅋ · Laughing';

  @override
  String get stickerNameHangulHh => 'ㅎㅎ · Chuckling';

  @override
  String get stickerNameHangulFighting => '화이팅! · You can do it';

  @override
  String get stickerNameHangulBest => '최고! · The best';

  @override
  String get stickerNameHangulGood => '굿 · Good job';

  @override
  String get stickerNameFoodTteok => 'Tteok rice cakes';

  @override
  String get stickerNameFoodTea => 'Korean tea';

  @override
  String get stickerNameFoodKimbap => 'Gimbap';

  @override
  String get stickerNameFoodHotteok => 'Hotteok';

  @override
  String get stickerNameFoodSikhye => 'Sikhye rice drink';

  @override
  String get stickerNameStampWellDone => 'Stamp · Well done';

  @override
  String get stickerNameStampFighting => 'Stamp · You can do it';

  @override
  String get stickerNameStampLove => 'Stamp · With love';

  @override
  String get stickerNameStampCheer => 'Stamp · Cheers';

  @override
  String get stickerNameStampHappy => 'Stamp · Happy';

  @override
  String get stampMotifLotus => 'Lotus dancheong';

  @override
  String get stampMotifChrysanthemum => 'Chrysanthemum dancheong';

  @override
  String get stampMotifPlum => 'Plum dancheong';

  @override
  String get stampMotifBamboo => 'Bamboo dancheong';

  @override
  String get stampMotifCloud => 'Cloud dancheong';

  @override
  String get stampMotifOctagon => 'Octagon dancheong';

  @override
  String get stampMotifMountain => 'Mountain dancheong';

  @override
  String get stampMotifManja => 'Manja dancheong';

  @override
  String get stampMotifVine => 'Vine dancheong';

  @override
  String get stampMotifChilbo => 'Chilbo dancheong';

  @override
  String get stampMotifGwigap => 'Gwigap dancheong';

  @override
  String get stampMotifWave => 'Wave dancheong';

  @override
  String get stampMotifTaegeuk => 'Taegeuk dancheong';

  @override
  String get stampMotifPeony => 'Peony dancheong';

  @override
  String get gyeDedicationTitle => 'Shared exhibition';

  @override
  String get gyeDedicationAction => 'Exhibit';

  @override
  String get gyeDedicationPickerBody =>
      'Choose a room decoration to show in the shared courtyard. It stays in your private collection.';

  @override
  String get gyeDedicationEmpty =>
      'Open a Bojagi bundle to add a room decoration before showing one here.';

  @override
  String get gyeDedicationWithdraw => 'Remove from exhibition';

  @override
  String get gyeDedicationKeepOwned =>
      'Your decoration stays in your private room.';

  @override
  String get gyeDedicationConfirmTitle => 'Show this in the courtyard?';

  @override
  String gyeDedicationConfirmBody(String decoration) {
    return 'Everyone in this Gye can see $decoration. Your private collection and room stay unchanged.';
  }

  @override
  String get gyeDedicationWithdrawConfirmBody =>
      'Remove this exhibit from the shared courtyard? Your private decoration stays yours.';

  @override
  String get gyeDedicationConfirm => 'Show in courtyard';

  @override
  String get gyeDedicationUpdateFailed =>
      'The exhibition could not be updated. Try again.';

  @override
  String get gyeDedicationConflict =>
      'The exhibition changed elsewhere. The latest view is shown.';

  @override
  String get gyeDedicationRetry => 'Try again';

  @override
  String get accountLinkUnavailableTitle =>
      'Connecting is not possible right now';

  @override
  String get accountLinkUnavailableBody =>
      'Cloud services are unavailable on this device, so sign-in could not be started. Your learning progress stays saved locally. Check your internet connection and restart the app.';

  @override
  String get accountLinkOfflineTitle => 'No internet connection';

  @override
  String get accountLinkOfflineBody =>
      'Connecting an account needs internet. Your progress stays saved on this device.';

  @override
  String get accountLinkFailedTitle => 'Connecting failed';

  @override
  String get accountLinkFailedBody =>
      'The operation could not be completed. Please try again in a moment.';

  @override
  String get soriStageNavToday => 'Today';

  @override
  String get soriStageNavLearn => 'Learn';

  @override
  String get soriStageNavGames => 'Games';

  @override
  String get soriStageNavHanok => 'Hanok';

  @override
  String get soriStageNavGye => 'Gye';

  @override
  String get soriStageProfileTooltip => 'Profile';

  @override
  String get soriStageTodayEyebrow => 'TODAY';

  @override
  String get soriStageTodayTitle => 'One phrase. One building piece.';

  @override
  String get soriStageTodayEmpty =>
      'Choose a short activity and keep your Hanok moving.';

  @override
  String get soriStageMissionAction => 'Start today\'s mission';

  @override
  String get soriStageTodayMissionEyebrow => 'TODAY\'S MISSION';

  @override
  String get soriStageMissionStart => 'Start';

  @override
  String get hanokStageNameEmpty => 'Building site';

  @override
  String get hanokStageNameFoundation => 'Foundation';

  @override
  String get hanokStageNamePillars => 'Pillars';

  @override
  String get hanokStageNameBeams => 'Beams';

  @override
  String get hanokStageNameThatchRoof => 'Thatched roof';

  @override
  String get hanokStageNameTileRoofPartial => 'First roof tiles';

  @override
  String get hanokStageNameTileRoofComplete => 'Tiled roof';

  @override
  String get hanokStageNameDancheong => 'Dancheong';

  @override
  String get hanokStageNameGate => 'Gate';

  @override
  String get hanokStageNameWindows => 'Windows';

  @override
  String get hanokStageNameSideBuilding => 'Sarangchae annex';

  @override
  String get hanokStageNameJongga => 'Jongga estate';

  @override
  String get soriStageBojagiTitle => 'A Bojagi is waiting';

  @override
  String get soriStageBojagiBody => 'Choose one of three pieces for your room.';

  @override
  String get soriStageOpenBojagi => 'Open Bojagi';

  @override
  String get soriStageHanokNow => 'Your Hanok now';

  @override
  String get soriStageNextPiece => 'Next building piece';

  @override
  String get soriStageClosestQuests => 'Nearly complete';

  @override
  String get soriStageLearnTitle => 'Choose how you want to learn.';

  @override
  String get soriStageLearnBody =>
      'Every activity stays connected to your quests and Hanok.';

  @override
  String get soriStageGamesTitle => 'Play with a clear purpose.';

  @override
  String get soriStageGamesBody =>
      'See the XP, personal best, and related quest before you start.';

  @override
  String soriStageMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get soriStagePossibleReward => 'Possible reward';

  @override
  String soriStageOpenActivity(String activity) {
    return 'Open $activity';
  }

  @override
  String soriStageActivityDetails(String activity) {
    return 'Details for $activity';
  }

  @override
  String get soriStageHanokTitle => 'Build a home from what you can do.';

  @override
  String get soriStageHanokBody =>
      'Seven permanent stages show exactly what is built and what opens next.';

  @override
  String get soriStageOpenMap => 'Open Hanok map';

  @override
  String get soriStageQuests => 'Quests';

  @override
  String get soriStageDojang => 'Stamp book';

  @override
  String get soriStageBojagi => 'Bojagi';

  @override
  String get soriStageRooms => 'Rooms and furnishing';

  @override
  String get soriStageGyePromise => 'This week\'s promise';

  @override
  String get soriStageGyeFlow =>
      'Mission complete → lantern → shared Hanok progress';

  @override
  String get pronunciationTitle => 'Pronunciation studio';

  @override
  String get pronunciationEyebrow => 'SPEAK WITH THE TIGER';

  @override
  String get pronunciationIntro =>
      'Listen first. Then record up to 10 seconds if you want an assessment.';

  @override
  String get pronunciationPhrasesLoading => 'Loading pronunciation practice …';

  @override
  String get pronunciationPhrasesUnavailableTitle =>
      'Pronunciation practice unavailable';

  @override
  String get pronunciationPhrasesUnavailableBody =>
      'The pronunciation practice could not be loaded. Please try again.';

  @override
  String get pronunciationPhrasesEmptyTitle => 'No pronunciation practice yet';

  @override
  String get pronunciationPhrasesEmptyBody =>
      'There are no reviewed sentences available for your learning level yet.';

  @override
  String get pronunciationListen => 'Listen';

  @override
  String get pronunciationRecord => 'Record my voice';

  @override
  String get pronunciationRecording => 'Recording…';

  @override
  String get pronunciationAssessing => 'Preparing your score…';

  @override
  String get pronunciationStop => 'Stop and assess';

  @override
  String get pronunciationContinueWithoutScore => 'Continue without a score';

  @override
  String get pronunciationNextPhrase => 'Next phrase';

  @override
  String get pronunciationConsentTitle => 'Use your voice for an assessment?';

  @override
  String get pronunciationConsentBody =>
      'With your separate consent, a recording of up to 10 seconds and the shown Korean phrase are sent securely to Microsoft Azure Speech in Germany West Central. Hangul Sori does not store the recording or phrase on its server. Only the scores and a duplicate-prevention ID are saved on this device. You can practise without assessment and withdraw consent in Settings.';

  @override
  String get pronunciationConsentAccept => 'I agree and want a score';

  @override
  String get pronunciationConsentDecline => 'Practise without a score';

  @override
  String get pronunciationPermissionDenied =>
      'Microphone access was not granted. Listening and repeat-after-me practice are still available.';

  @override
  String get pronunciationAssessmentUnavailable =>
      'The score is unavailable right now. Your basic practice still counts.';

  @override
  String get pronunciationRateLimited =>
      'You have reached the assessment limit. Continue practising and try again later.';

  @override
  String get pronunciationScore => 'Pronunciation score';

  @override
  String get pronunciationScorePassed =>
      'Passed. This assessment counts once toward your pronunciation quest.';

  @override
  String get pronunciationScoreTryAgain =>
      'Good practice. Try again for 80 or more to advance the quest.';

  @override
  String get pronunciationAccuracy => 'Accuracy';

  @override
  String get pronunciationFluency => 'Fluency';

  @override
  String get pronunciationCompleteness => 'Completeness';

  @override
  String get settingsPronunciationConsentTitle => 'Voice assessment consent';

  @override
  String get settingsPronunciationConsentDesc =>
      'Allow optional recordings of up to 10 seconds to be assessed by Azure Speech in Germany West Central. Turning this off stops future assessments.';

  @override
  String get settingsPronunciationConsentOff =>
      'Voice assessment is off. Listen-and-repeat practice remains available.';

  @override
  String get soriStageReceiptEyebrow => 'JUST CHANGED';

  @override
  String get soriStageReceiptTitle =>
      'Your learning moved the journey forward.';

  @override
  String get soriStageReceiptSemantics => 'Earned rewards';

  @override
  String get soriStageReceiptContinue => 'Continue';

  @override
  String get soriStageActivityReady => 'Ready now';

  @override
  String get soriStageBrandLabel => 'SORI STAGE';

  @override
  String get soriStageActivityInProgress => 'In progress';

  @override
  String get soriStageActivityCompleted => 'Completed';

  @override
  String soriStageActivityTitle(String activityId) {
    String _temp0 = intl.Intl.selectLogic(activityId, {
      'course': 'Course',
      'hangul': 'Hangul',
      'calligraphy': 'Calligraphy',
      'pronunciation': 'Pronunciation',
      'vocab_packs': 'Vocabulary packs',
      'srs': 'SRS review',
      'hard_words': 'Hard words',
      'word_web': 'Word web',
      'grammar': 'Grammar',
      'listening': 'Listening',
      'scenarios': 'Real-life scenarios',
      'smalltalk': 'Small Talk',
      'book_capture': 'Scan a book',
      'vocab_notebook': 'Vocab notebook',
      'bookshelf': 'Bookshelf',
      'word_search': 'Word search',
      'daily_game': 'Daily challenge',
      'chosung': 'Chosung quiz',
      'syllable_cross': 'Syllable cross',
      'cloze': 'Cloze',
      'speed_match': 'Speed Match',
      'sentence_arcade': 'Sentence arcade',
      'kkeunmari': 'Kkeunmari',
      'custom_quiz': 'Custom quiz',
      'custom_matching': 'Custom matching',
      'custom_typing': 'Custom typing',
      'other': 'Learning activity',
    });
    return '$_temp0';
  }

  @override
  String soriStageActivityDescription(String activityId) {
    String _temp0 = intl.Intl.selectLogic(activityId, {
      'course': 'Your guided path through real situations.',
      'hangul': 'Build syllables and read with confidence.',
      'calligraphy': 'Write one character with intention.',
      'pronunciation': 'Listen, repeat, and optionally assess.',
      'vocab_packs': 'Learn words by everyday topic.',
      'srs': 'Strengthen due words at the right moment.',
      'hard_words': 'Focus on the words that trip you up.',
      'word_web':
          'Neighbors, opposites, and expressions for words you have already studied.',
      'grammar': 'Understand patterns and use them right away.',
      'listening': 'Recognize short natural phrases.',
      'scenarios': 'Practice cafés, transport, and conversations.',
      'smalltalk': 'Connect short conversations naturally.',
      'book_capture': 'Bring words in from your own material.',
      'vocab_notebook':
          'Photograph your notebook and practice those exact words.',
      'bookshelf': 'Manage your pages and word lists.',
      'word_search': 'Find a word and its learning paths.',
      'daily_game': 'A short mix for today.',
      'chosung': 'Recognize words from their first sounds.',
      'syllable_cross': 'Combine syllables and find words.',
      'cloze': 'Recall the right word in a sentence.',
      'speed_match': 'Match meanings quickly and accurately.',
      'sentence_arcade': 'Build sentences under time pressure.',
      'kkeunmari': 'Play a word chain against the tiger.',
      'custom_quiz': 'Choose a word pack from your bookshelf.',
      'custom_matching': 'Strengthen your words as pairs.',
      'custom_typing': 'Actively recall your own words.',
      'other': 'Continue learning.',
    });
    return '$_temp0';
  }

  @override
  String soriStageCatalogCopy(String copyKey) {
    String _temp0 = intl.Intl.selectLogic(copyKey, {
      'firstCompletion': 'On first completion',
      'finishSession': 'When you finish the session',
      'verifiedLearning': 'After verified learning',
      'rewardXp': 'Learning XP',
      'rewardQuest': 'Related quest',
      'rewardHanok': 'Verified Hanok construction progress',
      'rewardStamp': 'Dojang stamp',
      'rewardBest': 'Personal best',
      'rewardNone': 'No direct reward',
      'rewardQuestProgress': 'Quest progress',
      'rewardHanokPiece': 'New Hanok building piece',
      'rewardBojagi': 'Bojagi',
      'rewardGyeLantern': 'Gye lantern',
      'other': 'Reward',
    });
    return '$_temp0';
  }

  @override
  String questActionLabel(String actionKey) {
    String _temp0 = intl.Intl.selectLogic(actionKey, {
      'openQuests': 'Open quests',
      'openVocabulary': 'Open vocabulary packs',
      'openScenarios': 'Open real-life scenarios',
      'practicePronunciation': 'Practice pronunciation',
      'playKkeunmari': 'Play Kkeunmari',
      'openHangul': 'Open Hangul',
      'openCalligraphy': 'Open calligraphy',
      'openToday': 'Open today\'s mission',
      'openGye': 'Open Gye',
      'playChosung': 'Play Chosung',
      'other': 'Open',
    });
    return '$_temp0';
  }

  @override
  String questSeasonOpens(String date) {
    return 'Opens $date';
  }

  @override
  String soriStagePreviewCopy(String copyKey) {
    String _temp0 = intl.Intl.selectLogic(copyKey, {
      'todayEyebrow': 'TODAY',
      'todayTitle': 'One phrase. One building piece.',
      'nearComplete': 'Nearly complete',
      'cafeOrder': 'Order at a café',
      'strongWords': 'Strong everyday words',
      'sevenDayStreak': 'Keep going for seven days',
      'lessonEyebrow': 'LESSON 2 OF 4',
      'lessonPhrase': '덜 맵게 해 주세요',
      'listen': 'Listen',
      'naturalTempo': 'Natural tempo',
      'speak': 'Speak',
      'rhythmMouth': 'Rhythm and mouth cues',
      'remember': 'Remember',
      'withoutHelp': 'Recall without help',
      'beginListening': 'Start with listening',
      'receiptEyebrow': 'JUST CHANGED',
      'receiptTitle': 'Your phrase now supports the roof.',
      'beamStage': 'DAECHEONG · BEAM 3',
      'newBeam': '1 new beam in the construction plan',
      'xpEarned': 'Learning XP +12',
      'completedMission': 'for the completed mission',
      'questEarned': 'Quest progress +1',
      'scenarioProgress': 'Real-life scenarios · 4 of 10',
      'hanokEarned': 'Hanok building piece +1',
      'verifiedSpeaking': 'from verified speaking',
      'continueToday': 'Continue to Today',
      'journeyEyebrow': 'YOUR JOURNEY',
      'journeyTitle': 'Every kind of learning builds in the same place.',
      'missionEyebrow': 'ORDER LESS SPICY',
      'missionTitle': 'Listen. Speak. Use it in real life.',
      'missionReward': 'Complete → learning XP + verified progress',
      'missionStart': 'Start mission',
      'bojagiWaiting': '1 Bojagi is waiting',
      'bojagiBody': 'Choose one of three pieces for your room.',
      'other': 'Sori Stage preview',
    });
    return '$_temp0';
  }

  @override
  String soriStagePreviewProgress(int current, int target) {
    return '$current of $target';
  }

  @override
  String get soriStageActivityStart => 'Start';

  @override
  String get soriStageActivityLocked => 'Locked';

  @override
  String culturalHelpSemantics(String term) {
    return 'Learn more about $term';
  }

  @override
  String get culturalMeaningLabel => 'What is it?';

  @override
  String get culturalStoryLabel => 'Why did it matter?';

  @override
  String get culturalClose => 'Close cultural story';

  @override
  String get culturalObjectHint => 'Curious? Tap an object to learn more.';

  @override
  String get culturalObjectHintDismiss => 'Dismiss hint';

  @override
  String get vocabNotebookTitle => 'Vocab notebook';

  @override
  String get vocabNotebookDesc =>
      'Photograph your notebook and practice those exact words.';

  @override
  String get vocabNotebookPreviewCta => 'Keep these words';

  @override
  String vocabNotebookResultHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count words from your notebook. You will practice exactly these words next.',
      one:
          '1 word from your notebook. You will practice exactly this word next.',
    );
    return '$_temp0';
  }

  @override
  String get vocabNotebookDefaultName => 'My vocab notebook';

  @override
  String get vocabNotebookEmptyTitle => 'No word pairs found';

  @override
  String get vocabNotebookEmptyBody =>
      'Write Korean and the meaning on one line, for example: 학교 - Schule. Then keep exactly those words.';

  @override
  String get vocabNotebookPracticeCta => 'Practice these exact words';

  @override
  String vocabNotebookPracticeHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count words from your notebook. Play with them instead of getting new vocabulary.',
      one:
          '1 word from your notebook. Play with it instead of getting new vocabulary.',
    );
    return '$_temp0';
  }

  @override
  String get vocabNotebookAddPhoto => 'Photograph another page';

  @override
  String get vocabNotebookDropWord => 'Leave this word out';

  @override
  String get vocabNotebookKeepWord => 'Keep this word';

  @override
  String get vocabNotebookNuanceCta => 'Hanja and nuance';

  @override
  String get vocabNotebookNuanceTitle => 'Close, but not the same';

  @override
  String get vocabNotebookNuanceEmptyTitle => 'No comparison yet';

  @override
  String get vocabNotebookNuanceEmptyBody =>
      'Photograph or import words that sit close together. Hanja then shows the other nuance or the more formal level.';

  @override
  String get vocabNotebookSaveFailed =>
      'The words could not be saved. Try again.';

  @override
  String get vocabNotebookNoHanja => 'no Hanja';

  @override
  String get vocabNotebookStudioCta => 'Build a game from these words';

  @override
  String get vocabNotebookStudioTitle => 'My word game';

  @override
  String get vocabNotebookStudioHint =>
      'Pick the words from your notebook. You then play only those, plus sentences, dialogues and word webs we already have for them.';

  @override
  String get vocabNotebookStudioSelectAll => 'Take all';

  @override
  String get vocabNotebookStudioSelectNone => 'None';

  @override
  String get vocabNotebookStudioOwnGames => 'With your meanings';

  @override
  String get vocabNotebookStudioCorpusGames => 'With our sentences';

  @override
  String get vocabNotebookStudioCorpusHint =>
      'Only sentences, dialogues and word webs we already have. No new vocabulary is added.';

  @override
  String get vocabNotebookStudioLoading => 'Loading available games…';

  @override
  String vocabNotebookStudioCloze(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cloze · $count sentences',
      one: 'Cloze · 1 sentence',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioSatz(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Build a sentence · $count sentences',
      one: 'Build a sentence · 1 sentence',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioSpeed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Speed Match · $count words',
      one: 'Speed Match · 1 word',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioChosung(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chosung · $count words',
      one: 'Chosung · 1 word',
    );
    return '$_temp0';
  }

  @override
  String get vocabNotebookStudioNoCorpus =>
      'We do not have a ready sentence for these words yet. Use your own meanings above.';

  @override
  String get vocabNotebookStudioLoadFailed =>
      'Some of our sentences could not load. Check the connection and try again.';

  @override
  String vocabNotebookStudioSmalltalk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Small talk · $count lines',
      one: 'Small talk · 1 line',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioPronunciation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pronunciation · $count sentences',
      one: 'Pronunciation · 1 sentence',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioScenarios(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scenario · $count scenes',
      one: 'Scenario · 1 scene',
    );
    return '$_temp0';
  }

  @override
  String vocabNotebookStudioWordWeb(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Word web · $count words',
      one: 'Word web · 1 word',
    );
    return '$_temp0';
  }

  @override
  String get ttsUnavailableChannelOff =>
      'Pronunciation is muted. Settings → Sound';

  @override
  String get ttsUnavailableQuota =>
      'Daily voice limit reached. It resets tomorrow.';

  @override
  String get ttsUnavailablePending =>
      'The voice is being generated. Tap again in a moment.';

  @override
  String get ttsUnavailableOffline =>
      'Pronunciation unavailable. Are you online?';

  @override
  String get mediaPhraseTitle => 'Media lines';

  @override
  String get mediaPhraseDesc =>
      'Practice original interview, podcast, documentary, and debate lines at your level.';

  @override
  String get mediaPhraseContext => 'Situation';

  @override
  String get mediaPhraseLoading => 'Loading media lines…';

  @override
  String get mediaPhraseUnavailable =>
      'The media lines could not be loaded. Please try again.';

  @override
  String get mediaPhraseEmptyTitle => 'No line for this level yet';

  @override
  String get mediaPhraseEmpty => 'There are no media lines for your level yet.';

  @override
  String mediaPhraseProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String mediaPhraseListenTarget(String phrase) {
    return 'Listen to $phrase';
  }

  @override
  String get mediaPhrasePrevious => 'Previous';

  @override
  String get mediaPhraseNext => 'Next';
}
