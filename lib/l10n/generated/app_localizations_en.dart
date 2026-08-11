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
  String get paywallProcessing => 'One moment …';

  @override
  String get paywallSuccess => 'Premium is active. Enjoy!';

  @override
  String get paywallFailed => 'Purchase not completed.';

  @override
  String get paywallRestoreNone => 'No previous purchases found.';

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
  String get companionNeutralThinking => 'Preparing the next round …';

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
  String get characterSelectedTiger => '태고가 선택되었습니다.';

  @override
  String get characterSelectedMagpie => '조이가 선택되었습니다.';

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
  String get moduleVocabDesc => '500+ cards · A1 → B2 · TTS';

  @override
  String get moduleGrammarTitle => 'Grammar';

  @override
  String get moduleGrammarDesc => '85+ patterns · clearly explained';

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
  String get loadingVocab => 'Loading vocabulary …';

  @override
  String get loadingGrammar => 'Loading grammar …';

  @override
  String get hintTapToFlip => 'Tap to flip';

  @override
  String get hintTapForExplanation => 'Tap for explanation';

  @override
  String get chosungQuestion => 'Which word?';

  @override
  String get chosungInputHint => 'Type in Korean …';

  @override
  String get chosungShowHint => 'Listen (hint)';

  @override
  String get chosungCorrect => '✓ Correct!';

  @override
  String get chosungAnswer => 'Answer';

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
  String get wordleErrorHangul => 'Hangul only please';

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
  String get settingsTtsRateSlow => 'Slow';

  @override
  String get settingsTtsRateNormal => 'Normal';

  @override
  String get settingsTtsRateFast => 'Fast';

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
    return 'Ø ${seconds}s per question';
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
      'The image stays on your device. Only the extracted text is analyzed.';

  @override
  String get bookCaptureCamera => 'Camera';

  @override
  String get bookCaptureGallery => 'From gallery';

  @override
  String get bookCaptureLoading => 'Reading text …';

  @override
  String get bookCaptureErrorNoKorean =>
      'No Korean detected. Try a clearer photo.';

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
    return '$count text blocks detected. Fix any typos if needed.';
  }

  @override
  String get bookPreviewAnalyze => 'Analyze';

  @override
  String get bookPreviewRetake => 'Retake';

  @override
  String get bookResultTitle => 'Result';

  @override
  String get loadErrorTryAgain => 'Something went wrong. Please try again.';

  @override
  String get bookResultAnalyzing => 'Looking up words & grammar …';

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
  String get gyeCreatedTitle => 'Gye created!';

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
  String get bookResultSectionWords => 'Words';

  @override
  String get bookResultSectionGrammar => 'Grammar';

  @override
  String get bookResultSectionSentences => 'Sentences';

  @override
  String get bookResultSave => 'Save to my bookshelf';

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
      'These stamps are keepsakes for the word packs you clear. To furnish your Hanok rooms, finish quests and open the bundles you earn.';

  @override
  String get dojangDecorHintCta => 'Go to Quests';

  @override
  String get hanokCinematicIntro => 'Your hanok is growing.';

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
  String get vocabPackResultCleared => 'Pack cleared!';

  @override
  String get vocabPackResultClearedAgain => 'Already cleared. Nice review!';

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
  String get vocabPackResultBackToGrid => 'Back to packs';

  @override
  String get vocabPackResultGeschafft =>
      'You did it! You\'ve mastered this vocab pack.';

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
  String get onboardingPage1Subtitle => 'Taego is here to help you learn';

  @override
  String get onboardingPage2Title => '5 minutes a day';

  @override
  String get onboardingPage2Subtitle => 'Short lessons that fit your day';

  @override
  String get onboardingPage3Title => 'Streaks matter';

  @override
  String get onboardingPage3Subtitle => 'Learn regularly to earn rewards.';

  @override
  String get onboardingPage4Title => 'How much time do you have?';

  @override
  String get onboardingGoal5min => '5 minutes';

  @override
  String get onboardingGoal10min => '10 minutes';

  @override
  String get onboardingGoal15min => '15 minutes';

  @override
  String get onboardingStartEyebrow => 'Your first path';

  @override
  String get onboardingStartTitle => 'What do you want to speak Korean for?';

  @override
  String get onboardingStartBody =>
      'This chooses your first situations – not your ability.';

  @override
  String get onboardingStartTravelTitle => 'Getting around Korea';

  @override
  String get onboardingStartTravelBody =>
      'Cafés, directions, shopping and help';

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
  String get onboardingStartNewTitle => 'I am just starting';

  @override
  String get onboardingStartNewBody =>
      'Begin directly with listening and speaking';

  @override
  String get onboardingStartExistingTitle => 'I already know some Korean';

  @override
  String get onboardingStartExistingBody =>
      'Choose a level or take 8–10 questions';

  @override
  String get onboardingStartPrimary => 'Open my first scene';

  @override
  String get onboardingStartChooseLevel => 'Choose a level';

  @override
  String get onboardingStartLoading => 'Preparing your first scene …';

  @override
  String get onboardingStartChangePoint => 'Change starting point';

  @override
  String get onboardingFirstSceneTravelCanDo =>
      'I can answer politely at immigration.';

  @override
  String get onboardingFirstScenePeopleCanDo =>
      'I can introduce myself in a friendly way.';

  @override
  String get onboardingFirstSceneWorkCanDo =>
      'I can briefly introduce myself in class or at work.';

  @override
  String get onboardingCompanionChoose => 'Choose a study buddy';

  @override
  String get onboardingCompanionSkip => 'Not now';

  @override
  String get onboardingCompanionEyebrow => 'Your study companion';

  @override
  String get onboardingCompanionPrompt =>
      'Choose Taego or Joy. Both can help, and you can decide later too.';

  @override
  String get onboardingCompanionSelectedTiger => 'Taego will learn with you.';

  @override
  String get onboardingCompanionSelectedMagpie => 'Joy will learn with you.';

  @override
  String get onboardingCompanionSelectionBody =>
      'You can change your choice any time in your profile.';

  @override
  String get onboardingCompanionContinue =>
      'Continue to Today with a companion';

  @override
  String get onboardingCompanionChange => 'Choose someone else';

  @override
  String get firstVoiceStamp => 'FIRST\nVOICE';

  @override
  String get firstVoiceTitle => 'You understood your first Korean.';

  @override
  String get firstVoiceBody =>
      'You understood a first Korean expression and can use it in your scene.';

  @override
  String get firstVoicePhraseBody => 'a sentence you can now hear and answer.';

  @override
  String get firstVoiceCanDo => 'I can greet someone kindly.';

  @override
  String get firstVoiceCanDoBody => 'Your A1 path begins with this scene.';

  @override
  String get firstVoiceCompanionTitle => 'Would you like a learning companion?';

  @override
  String get firstVoiceCompanionBody =>
      'They celebrate successes and explain hints. You can also decide later.';

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
      'We start at your level. Earlier levels stay open, later ones unlock as you progress.';

  @override
  String get onboardingLevelA1 => 'Beginner';

  @override
  String get onboardingLevelA1Desc => 'Just starting out';

  @override
  String get onboardingLevelA2 => 'Basic';

  @override
  String get onboardingLevelA2Desc => 'Greetings, simple ordering';

  @override
  String get onboardingLevelB1 => 'Intermediate';

  @override
  String get onboardingLevelB1Desc => 'Daily conversations';

  @override
  String get onboardingLevelB2 => 'Advanced';

  @override
  String get onboardingLevelB2Desc => 'Fluent, including nuance';

  @override
  String get onboardingExampleA1Trans => 'Hello / Good day.';

  @override
  String get onboardingExampleA2Trans => 'Iced Americano in tall, please.';

  @override
  String get onboardingExampleB1Trans =>
      'Yesterday I watched a movie with a friend. Really fun.';

  @override
  String get onboardingExampleB2Trans =>
      'Meeting is running long, I\'ll be a bit late.';

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
  String get scenariosListSubtitle => 'Learn by living it';

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
  String get particlePopHint => 'Drag the correct particle into the slot.';

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
      'Great work! New missions arrive tomorrow.';

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
  String get listeningPickFirst => 'Pick a scenario above to start.';

  @override
  String get listeningEmptyTitle => 'No scenarios yet';

  @override
  String get listeningEmptyBody =>
      'Once scenarios are available, you can listen to them here.';

  @override
  String get kkeunmariTitle => 'Word Chain';

  @override
  String get kkeunmariSubtitle => 'Last syllable → next word';

  @override
  String get kkeunmariYourTurn => 'Your turn';

  @override
  String get kkeunmariTigerTurn => 'Tiger thinking …';

  @override
  String kkeunmariStartHint(Object syl) {
    return 'Start with “$syl”';
  }

  @override
  String get kkeunmariInputHint => 'Type a Korean word …';

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
  String get shareGenerating => 'Creating code …';

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
  String get wbAutoFillRunning => 'Looking up translation …';

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
  String get clozeLevelAll => 'All';

  @override
  String get speedMatchTitle => 'Speed Match';

  @override
  String get speedMatchDesc => 'Match against the clock';

  @override
  String get speedMatchInstruction => 'Tap a Korean word, then its meaning.';

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
  String get wbTypingHint => 'In Korean …';

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
  String get wbSearchHint => 'Search word or meaning …';

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
    return '$count in a row!';
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
  String get pathStatusCurrent => 'Current';

  @override
  String get pathStatusCompleted => 'Completed';

  @override
  String get pathStatusBypassed => 'Start level bypassed';

  @override
  String get pathStatusNext => 'Next';

  @override
  String get pathShowMorePractice => 'Show more practice';

  @override
  String get pathHideMorePractice => 'Hide more practice';

  @override
  String get gyeEmptyHeadline =>
      'Learning alone is complete. Together can feel warmer.';

  @override
  String get gyeEmptyLead =>
      'A Gye is a small group that holds a weekly intention together.';

  @override
  String get gyeFindOrCreate => 'Find or create a Gye';

  @override
  String get gyeContinueSolo => 'Continue without a group';

  @override
  String get gyeEmptyPreviewCaption =>
      'A preview of a shared courtyard — never a requirement for your path';

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
  String get profileLearningCompanion => 'Learning companion';

  @override
  String get profileSpaceSection => 'My space';

  @override
  String get profileGye => 'Group (Gye)';

  @override
  String get profileGyeDescription => 'Open your optional learning group';

  @override
  String get profileGyeLoading => 'Loading group …';

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
  String get profileLearningDataPreparing => 'Preparing export …';

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
      'Checking your account and learning progress safely …';

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
  String get grammarEasy => 'Got it';

  @override
  String get grammarHard => 'Difficult';

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
      'Scan, look something up, listen, or take a short practice break. Explore never replaces today\'s learning step.';

  @override
  String get discoverSearchHint => 'Search: pronunciation, book, OCR …';

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
      'Photograph a book page and learn directly from its text.';

  @override
  String get discoverPriorityPronunciationTitle => 'Hear pronunciation';

  @override
  String get discoverPriorityPronunciationBody =>
      'Listen closely and practise Korean sounds in context.';

  @override
  String get discoverPriorityWordsTitle => 'Dictionary & My words';

  @override
  String get discoverPriorityWordsBody =>
      'Look up a word or open your saved collection.';

  @override
  String get navLearn => 'Learn';

  @override
  String get navPractice => 'Practice';

  @override
  String get navWordbook => 'Words';

  @override
  String get navGye => 'Group';

  @override
  String get gyeTabSubtitle => 'Learn together · Gye';

  @override
  String get gyeExplainWhat =>
      'A gye is an optional small group for learning Korean. Learning alone is complete, too.';

  @override
  String get gyeExplainWhy =>
      'A shared hanok makes encouragement visible. It is never a competition or a requirement for your learning path.';

  @override
  String get gyeExplainHow =>
      'Create a group or join with a 6-digit code when you are ready.';

  @override
  String get gyePrivacyTitle => 'What others can see';

  @override
  String get gyePrivacyBody =>
      'Only that you contributed — never your answers, words, or assessment results.';

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
      'A lantern lights after a course-linked scene is completed at 70%. Answers, scores, and who contributed stay private.';

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
  String get gyePromiseSceneCta => 'Open today’s contribution scene';

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
  String get gyeCourtyardTitle =>
      'A shared place for small, safe encouragement.';

  @override
  String get gyeCourtyardBody =>
      'The courtyard visual follows the existing weekly goal data. It does not change anyone\'s personal course or hanok.';

  @override
  String get gyeSafeMessage => 'Send a safe encouragement';

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
  String get practiceEyebrow => 'Practice on your terms';

  @override
  String get practiceTitle => 'What do you want to strengthen?';

  @override
  String get practiceSubtitle =>
      'Choose a need first. Your single next learning step stays on Home.';

  @override
  String get practiceDueTitle => 'Review words due';

  @override
  String get practiceDueEmpty => 'Open a review whenever you want';

  @override
  String get practiceSecLearn => 'Practice something in particular';

  @override
  String get practiceSecGames => 'Play freely';

  @override
  String get practiceSecWords => 'Your words';

  @override
  String get practiceSecSpace => 'Your learning space';

  @override
  String get practiceFocusedDescription => 'Pronunciation, grammar, or writing';

  @override
  String get practiceFreeDescription => 'Word chains, letters, and short games';

  @override
  String get practiceWordsDescription => 'Open saved words and books';

  @override
  String get practiceAllActivities => 'Show all activities';

  @override
  String get practiceHideAllActivities => 'Hide all activities';

  @override
  String get pathEvidenceTitle => 'How progress becomes verified';

  @override
  String get pathEvidenceBody =>
      'Browsing saves history only. A course unit is verified through its active assessment and at least 70% in every linked scenario checkpoint.';

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
      'Step 1 · Learn: flip the cards and study them';

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
      'Choose a level from A1 to B2 and decide whether to show vowels';

  @override
  String get coachChosungStep3Title => 'Type your answer';

  @override
  String get coachChosungStep3Body => 'Type the full Korean word and confirm';

  @override
  String get coachSilbenStep1Title => 'Syllable crossword';

  @override
  String get coachSilbenStep1Body =>
      'Fill the grid: each row is a Korean word — words cross at shared syllables. The red cell is selected';

  @override
  String get coachSilbenStep2Title => 'Read the clues';

  @override
  String get coachSilbenStep2Body =>
      'Arrow = direction in the grid. Meaning and example sentence help — ○○ hides the target word';

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
  String get coachListeningStep2Title => 'Speed & subtitles';

  @override
  String get coachListeningStep2Body =>
      'Adjust playback speed from 0.75× to 1.25× and choose a subtitle mode';

  @override
  String get coachListeningStep3Title => 'Line by line';

  @override
  String get coachListeningStep3Body =>
      'Listen and tap ⟳ to replay, or Next to advance';

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
      '\"Got it\" extends the interval · \"Didn\'t know\" brings the card back sooner';

  @override
  String get coachLegacyVocabTitle => 'Flashcard';

  @override
  String get coachLegacyVocabBody =>
      'Tap to flip · long-press to hear it at slow speed';

  @override
  String get coachLearningPathTitle => 'Your learning path';

  @override
  String get coachLearningPathBody =>
      'Start at the orange \"Now\" node and work your way forward step by step';

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
      'Complete vocabulary packs to unlock all 8 Dancheong stamp designs';

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
      'Streak, XP and accuracy show how far you have already come';

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
  String get questCheckAnswer => 'Check';

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
  String get scenarioRoleplayHint => 'Your turn. Write your own reply.';

  @override
  String get scenarioRoleplayTurn => 'Your reply';

  @override
  String get scenarioRoleplayDoneTitle => 'Role-play complete!';

  @override
  String get scenarioRoleplayDoneBody =>
      'You carried the conversation yourself.';

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
  String get testerFeedbackSubmitting => 'Sending feedback …';

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
  String get onboardingDiagnosticCta => 'Not sure? Take 8 questions';

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
  String get courseMissionNow => 'now';

  @override
  String get courseMissionPreviewTag => 'preview';

  @override
  String get courseMissionStartPractice => 'Start practice';

  @override
  String get courseMissionPreviewNotice =>
      'You can preview this mission. Scores and progress count only when it is active.';

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
  String get homeTodayReviewAction => 'Review now';

  @override
  String get homeTodayScenarioAction => 'Practice this scene';

  @override
  String get homeTodayPackDescription => 'Practice the words you need next.';

  @override
  String get homeTodayReviewDescription =>
      'So the sentence is ready in your next scene.';

  @override
  String get homeTodayReviewReasonTitle => 'Why review today?';

  @override
  String get homeTodayReviewReason =>
      'So greetings, requests, and answers are ready for your next scene.';

  @override
  String get homeTodayReviewTime =>
      'About 3 minutes · then your path continues.';

  @override
  String get homeUnavailableTitle => 'Your path could not refresh.';

  @override
  String get homeUnavailableDescription =>
      'Your saved reviews and completed content are still available on this device.';

  @override
  String get homeUnavailableSafeTitle => 'Safe to do now';

  @override
  String get homeUnavailableSafeBody =>
      'Review uses only learning content saved on this device.';

  @override
  String get homeUnavailableCta => 'Review saved words';

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
  String get sarangbangHubDesc =>
      'Your next study step begins in the Sarangbang.';

  @override
  String get bojagiTitle => 'Bojagi bundle';

  @override
  String get bojagiOpenHint => 'Tap the knot to open the bundle.';

  @override
  String get bojagiPickTitle => 'Pick one';

  @override
  String get bojagiPickBody =>
      'Whatever you leave stays in the pool and can turn up in a later bundle.';

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
  String get hanokWorldEarlyTitle => 'A roof begins with a voice.';

  @override
  String get hanokWorldEarlyBody =>
      'Your foundation grows with every secure sentence from everyday life.';

  @override
  String get hanokWorldMapEyebrow => 'Your walkable courtyard';

  @override
  String get hanokWorldMapTitle => 'Where would you like to go?';

  @override
  String get hanokWorldMapBody =>
      'One place, one purpose. Learning does not start from an empty map.';

  @override
  String get hanokWorldOpenNextScene => 'See the next scene';

  @override
  String get hanokWorldNextBeamTitle => 'Next beam in your construction plan';

  @override
  String hanokWorldSafeSceneProgress(int current, int total) {
    return '$current of $total scenes secure';
  }

  @override
  String get hanokWorldIntro =>
      'Keep learning where your Hanok grows. Each finished place leads to a familiar part of Hangul Sori.';

  @override
  String get hanokWorldLegacyTitle => 'Your courtyard is taking shape';

  @override
  String get hanokWorldLegacyBody =>
      'Finish your A1 and A2 path. Your first B1 progress opens the gate to the full Hanok map.';

  @override
  String get hanokWorldMapHint =>
      'Tap a finished building to continue learning there.';

  @override
  String get hanokWorldOpenSarangbang => 'Study in the Sarangbang';

  @override
  String get hanokWorldProgress => 'Your Hanok construction progress';

  @override
  String get hanokWorldGyeBridgeTitle => 'The Gye courtyard';

  @override
  String get hanokWorldGyeBridgeBody =>
      'Your private Hanok and the shared Gye courtyard grow side by side. Meet your learning group there.';

  @override
  String get hanokWorldGyeBridgeOpen => 'Visit the Gye courtyard';

  @override
  String get hanokWorldPlacesTitle => 'Places in your Hanok';

  @override
  String get hanokWorldPlacesBody =>
      'Use this list to choose a finished place.';

  @override
  String get hanokMapPlaceSarangbang => 'Sarangbang\nStudy today';

  @override
  String get hanokMapPlaceDaecheong => 'Daecheong\nYour path';

  @override
  String get hanokMapPlaceHaengrang => 'Haengrang\nPractice';

  @override
  String get hanokMapPlaceAnchae => 'Anchae\nWords';

  @override
  String get hanokMapPlaceHuwon => 'Huwon\nTasks';

  @override
  String get hanokMapPlaceSadang => 'Sadang\nAchievements';

  @override
  String get hanokZoneSarangbang => 'Sarangbang · today\'s study';

  @override
  String get hanokZoneDaecheong => 'Daecheongmaru · learning path';

  @override
  String get hanokZoneHaengrang => 'Haengrangchae · practice';

  @override
  String get hanokZoneAnchae => 'Anchae · my collection';

  @override
  String get hanokZoneHuwon => 'Huwon · daily goal';

  @override
  String get hanokZoneSadang => 'Sadang · achievements';

  @override
  String get hanokWorldPurposeSarangbang =>
      'Return to today\'s scene and the expressions you have earned.';

  @override
  String get hanokWorldPurposeDaecheong =>
      'See your course path and choose the next verified mission.';

  @override
  String get hanokWorldPurposeHaengrang =>
      'Choose a focused practice or a short game.';

  @override
  String get hanokWorldPurposeAnchae =>
      'Open your saved words, books, and personal learning collection.';

  @override
  String get hanokWorldPurposeHuwon =>
      'Choose a quiet daily character moment or an existing quest.';

  @override
  String get hanokWorldPurposeSadang =>
      'Look back at the visible milestones of your learning path.';

  @override
  String get hanokWorldPurposeGyeRoad =>
      'The shared Gye courtyard stays separate from your private Hanok.';

  @override
  String get hanokWorldSelectPlaceTitle => 'Choose a finished place';

  @override
  String get hanokWorldSelectPlaceBody =>
      'Tap a building on the map or choose one from the accessible list.';

  @override
  String hanokWorldPlaceReadyBody(String place) {
    return '$place is ready to welcome your next study step.';
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
  String get hanokWorldRevealBody =>
      'Wood, dust, and dancheong: a new part of your Hanok has taken shape.';

  @override
  String get hanokWorldRevealContinue => 'Continue to the map';

  @override
  String get hanokVenueFurnishRoom => 'Furnish this room';

  @override
  String get hanokVenueAnbangBody =>
      'This quiet inner room keeps the words, pages, and learning collections that matter to you.';

  @override
  String get hanokVenueDaecheongBody =>
      'On the open maru, continue your learning path or make the room your own.';

  @override
  String get hanokVenueHaengrangBody =>
      'Your practice atelier is waiting in the entrance wing for another round.';

  @override
  String get hanokVenueHuwonBody =>
      'The rear garden holds a quiet moment for today’s letter or a new quest.';

  @override
  String get hanokVenueSadangBody =>
      'The shrine keeps the visible traces of everything you have learned.';

  @override
  String get sarangbangStudyTitle => 'Sarangbang';

  @override
  String get sarangbangStudyIntroTitle => 'Today\'s words have arrived.';

  @override
  String get sarangbangStudyIntroBody =>
      'Here you can see what you have actually worked for.';

  @override
  String get sarangbangStudySceneLabel => 'Your study room';

  @override
  String get sarangbangStudyFurnish => 'Furnish the study room';

  @override
  String get sarangbangFurnishTitle => 'Furnish';

  @override
  String get sarangbangFurnishBody =>
      'New objects come from existing, clearly marked learning rewards.';

  @override
  String get sarangbangStoredTitle => 'Stored today';

  @override
  String get sarangbangStoredEmpty =>
      'New expressions and secure scenes appear here once you have worked for them.';

  @override
  String sarangbangStoredBody(Object detail) {
    return '$detail · Your current scene remains selected on Home.';
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
      other: '$scenes secure scenes',
      one: '1 secure scene',
      zero: 'no secure scenes',
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
}
