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
  String get paywallSubtitle => 'Learn Korean without limits.';

  @override
  String get paywallBenefit1 => 'All vocabulary packs (A2 · B1 · B2)';

  @override
  String get paywallBenefit2 => 'All conversation scenarios';

  @override
  String get paywallBenefit3 => 'Unlimited reviews (SRS)';

  @override
  String get paywallBenefit4 => 'Your personal AI course — fresh every day';

  @override
  String get paywallBenefit5 => 'Book snapshot without a daily limit';

  @override
  String get paywallPriceFallback => '€5 / month';

  @override
  String get paywallPricePerMonth => '/ month';

  @override
  String get paywallCtaStart => 'Start Premium';

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
  String get paywallSuccess => 'Premium is active. Enjoy! 🎉';

  @override
  String get paywallFailed => 'Purchase not completed.';

  @override
  String get paywallRestoreNone => 'No previous purchases found.';

  @override
  String streakDisplay(Object days) {
    return '🔥 $days days';
  }

  @override
  String get streakDialogTitle => 'Keep your streak alive';

  @override
  String get streakDialogSubtitle =>
      'Learn every day — watch your streak grow!';

  @override
  String get streakDialogEarned => 'Streaks unlock rewards';

  @override
  String streakDialogCurrent(Object days) {
    return 'Current streak: $days days';
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
  String get characterNameTiger => '든든이';

  @override
  String get characterTraitTiger => 'Reliable & brave';

  @override
  String get characterNameMagpie => '쌤쌤이';

  @override
  String get characterTraitMagpie => 'Cheerful & lively';

  @override
  String get reviewTitle => 'Today\'s review';

  @override
  String get reviewEmptyTitle => 'All done!';

  @override
  String get reviewEmptyBody =>
      'No cards are due today. Play a round or learn a new pack — those words will show up here for review.';

  @override
  String get reviewDoneTitle => 'Nice work! 🎉';

  @override
  String get reviewDoneBody => 'You\'ve reviewed your due cards.';

  @override
  String get reviewBonusLabel => 'Phrase of the day';

  @override
  String get homeReviewTitle => 'Today\'s review';

  @override
  String homeReviewDue(int n) {
    return '$n words due';
  }

  @override
  String get homeReviewDone => 'All reviewed today 🎉';

  @override
  String get settingsNotifSection => 'Reminder';

  @override
  String get settingsNotifTitle => 'Daily reminder';

  @override
  String get settingsNotifSubtitle => 'The tiger reminds you to study';

  @override
  String get settingsNotifTime => 'Time';

  @override
  String get settingsNotifDenied =>
      'Notifications are disabled. Enable them in system settings.';

  @override
  String get notificationTitle => 'Hangul Sori';

  @override
  String get notificationBody => 'The tiger\'s waiting — time for Korean! 🐯';

  @override
  String get homeCourseTitle => 'Your daily course';

  @override
  String get homeCourseDesc => 'Tailored to your weak spots & interests';

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
  String get welcomeMsg => 'Hi! All the best today 💪';

  @override
  String get footerCheer => 'Keep going — you got this 🌟';

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
  String get moduleGrammarDesc => '85+ patterns · German explanations';

  @override
  String get moduleListenTitle => 'Listening';

  @override
  String get moduleListenDesc => 'Hear and understand sentences';

  @override
  String get gameChosungTitle => 'Initial Quiz';

  @override
  String get gameChosungDesc => 'Guess the word from its initial consonants';

  @override
  String get gameWordleTitle => 'Wordle';

  @override
  String get gameWordleDesc => '2–3 syllables · 6 tries';

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
  String get navWordle => 'Wordle';

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
      'Snap your first textbook page — the analyzed words will land here.';

  @override
  String get bookshelfEmptyCta => 'Snap a page';

  @override
  String get bookshelfSectionPages => 'Pages';

  @override
  String get bookshelfSectionCustomPacks => 'Custom packs';

  @override
  String bookshelfTileMeta(int words, int grammar, String date) {
    return '$words words · $grammar grammar · $date';
  }

  @override
  String bookshelfPackMeta(int n) {
    return '$n words';
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
  String get wordleResultWin => '🎉 You got it!';

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
  String get settingsPrivacySubtitle => 'Copy URL';

  @override
  String settingsPrivacyCopied(Object url) {
    return 'URL copied: $url';
  }

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
  String get statsWordleWins => 'Wordle wins';

  @override
  String get statsWordleStreak => 'Wordle streak';

  @override
  String get screenVocabTitle => 'Vocabulary';

  @override
  String get screenGrammarTitle => 'Grammar';

  @override
  String get screenWordleTitle => 'Wordle';

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
  String get hangulRulesTitle => '✏️ Hangul writing rules';

  @override
  String get hangulRulesBody =>
      '① Top → Bottom   ② Horizontal → Vertical   ③ Left → Right';

  @override
  String get hangulStrokeOrderTitle => '📽 Stroke order (tap to replay)';

  @override
  String get hangulTraceTitle => '✍️ trace with your finger';

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
    return 'Strong! Try level $level.';
  }

  @override
  String chosungRoundKeepLevel(Object level) {
    return 'Nice run — stay on level $level.';
  }

  @override
  String chosungRoundReview(Object level) {
    return 'Take another pass on level $level.';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsSubtitle => 'Your learning progress';

  @override
  String get statsDays => 'Days';

  @override
  String get statsCards => 'Cards';

  @override
  String get statsPercent => 'Accuracy';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsEmpty => 'No data yet — let\'s go! 🚀';

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
    return '🔥 $n due';
  }

  @override
  String vocabTodayBadge(int newCount, int reviewCount) {
    return '🔥 Today ($newCount new · $reviewCount review)';
  }

  @override
  String get vocabDueEmpty => '🎉 All done for today!\nCome back tomorrow.';

  @override
  String get vocabDueEmptyAction => 'Practice anyway';

  @override
  String get vocabPacksTitle => 'Vocab packs';

  @override
  String get vocabPacksLevelMenu => 'Switch level';

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
  String get vocabPackLockedNoPrev => '🔒 This pack is still locked.';

  @override
  String vocabPackLockedHint(Object prev) {
    return '🔒 Clear \"$prev\" first with ≥ 70% on bosses.';
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
      'No Korean detected — try a clearer shot.';

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
    return '$count text blocks detected — fix typos if needed.';
  }

  @override
  String get bookPreviewAnalyze => 'Analyze';

  @override
  String get bookPreviewRetake => 'Retake';

  @override
  String get bookResultTitle => 'Result';

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
  String get gyeErrTooMany => 'You can join up to 3 gye.';

  @override
  String get gyeErrName => 'Please enter a valid gye name.';

  @override
  String get gyeErrNickname => 'Please enter a valid nickname.';

  @override
  String get gyeErrProfanity => 'Please choose a different word.';

  @override
  String get gyeErrAgeRestricted => 'Gye is available from age 16 (GDPR).';

  @override
  String get gyeAgeYearTitle => 'Birth year';

  @override
  String get gyeAgeYearBody =>
      'Gye is available from age 16 (GDPR). Please enter your birth year.';

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
  String get gyeDureEmpty => 'Empty so far — clear a pack to break ground!';

  @override
  String get gyeChallengeTitle => 'Everyone in?';

  @override
  String get gyeChallengeDone => 'Everyone\'s in! 🔥';

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
  String get gyeFeedGoalAchieved => 'Weekly goal reached! 🎉 Your hanok grows.';

  @override
  String gyeFeedGoalAchievedMvp(int packs, Object mvp) {
    return 'Weekly goal reached! 🎉 $packs packs · MVP $mvp';
  }

  @override
  String get gyeStickerSend => 'Send sticker';

  @override
  String get gyeStickerRateLimited => 'Too many stickers — slow down a moment.';

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
  String get bookResultOfflineNotice =>
      'Server unreachable — only grammar patterns detected offline.';

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
      'Start a pack — quest progress will start appearing here.';

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
      'New courtyard decoration unlocked!';

  @override
  String get hanokCinematicIntro => 'Your hanok is growing —';

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
  String get vocabPackBossHint => 'Listen and choose';

  @override
  String get vocabPackBossReplayAudio => 'Play again';

  @override
  String get vocabPackTapToFlip => 'Tap to flip';

  @override
  String get vocabPackResultTitle => 'Result';

  @override
  String get vocabPackResultCleared => '🎉 Pack cleared!';

  @override
  String get vocabPackResultClearedAgain => 'Already cleared — nice review!';

  @override
  String get vocabPackResultRetry => 'So close — try again!';

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
  String get vocabPackResultGeschafft => 'Done! You mastered this vocab pack.';

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
      'This deletes your cloud backup for the current Firebase account. Local progress on this device is not deleted.';

  @override
  String get settingsCloudDeleteDataSuccess => 'Cloud data deleted';

  @override
  String get settingsAccountDelete => 'Delete account and all data';

  @override
  String get settingsAccountDeleteDesc =>
      'Deletes your Firebase account, cloud backup, and local progress.';

  @override
  String get settingsAccountDeleteConfirmTitle => 'Delete account permanently?';

  @override
  String get settingsAccountDeleteConfirmBody =>
      'This deletes your Firebase account, Google link, Firestore cloud backup, and local learning data on this device. This cannot be undone. Google may ask you to sign in again to confirm.';

  @override
  String get settingsAccountDeleteSuccess => 'Account and data deleted';

  @override
  String settingsAccountDeleteFailed(Object error) {
    return 'Deletion failed: $error';
  }

  @override
  String get settingsAccountDeletionTitle => 'Account & data deletion';

  @override
  String get settingsAccountDeletionSubtitle => 'Copy deletion info URL';

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
  String get onboardingPage1Subtitle =>
      'The tiger joins you on your learning journey';

  @override
  String get onboardingPage2Title => '5 minutes a day';

  @override
  String get onboardingPage2Subtitle => 'Short, effective, always accessible';

  @override
  String get onboardingPage3Title => '🔥 Streaks matter';

  @override
  String get onboardingPage3Subtitle =>
      'The more you come, the more rewards you earn!';

  @override
  String get onboardingPage4Title => 'How much time do you have?';

  @override
  String get onboardingGoal5min => '5 minutes';

  @override
  String get onboardingGoal10min => '10 minutes';

  @override
  String get onboardingGoal15min => '15 minutes';

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
  String get onboardingSkip => 'Decide later (A1 default)';

  @override
  String get onboardingPrompt =>
      'Tap your level — you can change it in Settings.';

  @override
  String get onboardingTigerGreeting => '환영해요!\n어떤 레벨부터 시작할까요?';

  @override
  String get homeHeroGreetingMorning => 'Good morning!';

  @override
  String get homeHeroGreetingAfternoon => 'Hi there!';

  @override
  String get homeHeroGreetingEvening => 'Good evening!';

  @override
  String get homeTigerBubbleStart => 'Shall we study for 5 minutes? 📖';

  @override
  String get homeTigerBubbleStreak => 'Streak alive! Keep going 🔥';

  @override
  String get homeTigerBubbleResume => 'Welcome back!';

  @override
  String get homeHeroActionContinue => 'Continue learning';

  @override
  String get homeHeroActionStart => 'New word pack';

  @override
  String get homeShieldLabel => 'Shield';

  @override
  String get homePathSection => 'Your path';

  @override
  String get homePathLocked => 'Locked';

  @override
  String get homePathCurrent => 'Now';

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
  String get scenariosEmptyBody => 'We\'re crafting new scenarios with care.';

  @override
  String get scenariosLoadFailedTitle => 'Hmm, something went wrong';

  @override
  String get statsFirstEntryTitle => 'Your story begins here';

  @override
  String get statsFirstEntryBody =>
      'Start a scenario — this page will fill with your progress.';

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
      'Learn how Koreans actually live — café, airport, intro…';

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
    return '$count words practiced';
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
  String get statsScenariosCompleted => 'Scenarios done';

  @override
  String get statsBadgesTitle => 'Badges';

  @override
  String get statsNoBadges => 'None yet — finish scenarios! 🚀';

  @override
  String get homeRecommended => 'Recommended today ✨';

  @override
  String get homeAllDone => 'All scenarios done! 🎉';

  @override
  String get homeNoScenario => 'Scenarios for your level coming soon';

  @override
  String get homeGreetingLearn => 'Learn Korean like a local';

  @override
  String get homeTodaySection => 'Today';

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
  String get dailyCharSubtitle => '1-min trace';

  @override
  String get dailyCharDoneToday => 'Done today ✓';

  @override
  String get dailyCharFinish => 'Done';

  @override
  String dailyCharStreak(int n) {
    return '$n days total';
  }

  @override
  String get dailyCharGreatJob => 'Nice!';

  @override
  String get vocabModeFavorites => 'Favorites';

  @override
  String vocabFavoritesBadge(int n) {
    return '⭐ $n';
  }

  @override
  String get vocabHearExample => 'Hear example';

  @override
  String get vocabSlowHint => 'Long press: slow';

  @override
  String get vocabEmptyFavorites =>
      'No favorites yet ⭐\nTap the star on hard words';

  @override
  String get listeningTitle => 'Listening';

  @override
  String get listeningSubtitle => 'Hear a scenario at real-life pace';

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
      'Once scenarios load, you can listen to them here.';

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
  String get kkeunmariNotInPool =>
      'I don\'t know this one yet — try another 🐯';

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
  String get kkeunmariDeadEnd => '한방단어 — the chain ends here';

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
    return 'You chained $n words.';
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
    return 'I\'m sharing the vocabulary pack “$name” ($count words) from Hangul Sori with you! Enter code $code in the app to import it. hangul-sori.com';
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
    return 'Imported “$name” ($count words)';
  }

  @override
  String get redeemNotFound => 'Code not found.';

  @override
  String get redeemExpired => 'This code has expired.';

  @override
  String get redeemError => 'Import failed. Are you online?';

  @override
  String get createWordbookCta => 'Own word list';

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
      'Add your first word — or let the translation fill in automatically.';

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
      'Auto-fill isn\'t available right now — please type it in.';

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
  String get homeWordbookCardTitle => 'Own word list';

  @override
  String get homeWordbookCardDesc => 'Build & study your own';

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
    return '$count words imported';
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
    return '$count words just won\'t stick';
  }

  @override
  String get hardWordsEmptyTitle => 'Nothing tricky 🎉';

  @override
  String get hardWordsEmptyBody =>
      'No especially hard words right now. Keep learning — if one keeps tripping you up, it\'ll show up here.';

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
      'Tap the bookmark to save a word and review it daily — you can even build your own flashcards from your word list!';

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
    return '$count words';
  }

  @override
  String get wbPosAll => 'All';

  @override
  String get wbSearchCta => 'Search my words';

  @override
  String comboPop(int count) {
    return '$count in a row! 🔥';
  }

  @override
  String get pathTitle => 'Learning path';

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
    return '🔥 $days days in a row — keep going today?';
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
  String get profileGuestBadge => 'Guest mode';

  @override
  String get profileGuestDesc =>
      'Your progress lives only on this device. Save it with Google so it survives a phone change.';

  @override
  String get profileConnectedBadge => 'Connected with Google';

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
  String get authAppleSignIn => 'Sign in with Apple';

  @override
  String get consentTitle => 'Welcome to Hangul Sori';

  @override
  String get consentBody =>
      'Before you start — Hangul Sori keeps your learning progress on your device by default. Please take a moment to see how we handle your data.';

  @override
  String get consentPrivacyCta => 'Read the privacy policy';

  @override
  String get consentAgreeCta => 'Agree & start';

  @override
  String get consentFootnote =>
      'By continuing you agree to our Privacy Policy.';

  @override
  String get grammarEasy => 'Got it';

  @override
  String get grammarHard => 'Difficult';

  @override
  String get navHome => 'Home';

  @override
  String get navLearn => 'Learn';

  @override
  String get navPractice => 'Practice';

  @override
  String get navWordbook => 'Words';

  @override
  String get navGye => 'Gye';

  @override
  String get practiceSecLearn => 'Learn';

  @override
  String get practiceSecGames => 'Games';

  @override
  String get practiceSecWords => 'Words';

  @override
  String get coachBookTitle => 'Snap a page';

  @override
  String get coachBookStep1 => '📸 Take a photo of your textbook or a menu';

  @override
  String get coachBookStep2 => '🔍 Text is detected and analyzed automatically';

  @override
  String get coachBookStep3 =>
      '📚 New words are saved straight to your word list';

  @override
  String get coachBookLimitNote => 'Daily limit: 20 pages';

  @override
  String get coachVocabPackTitle => 'Learn in 3 steps';

  @override
  String get coachVocabPackStep1 =>
      '📖 Step 1 · Learn — flip the cards and absorb them';

  @override
  String get coachVocabPackStep2 =>
      '✏️ Step 2 · Quiz — pick the right translation';

  @override
  String get coachVocabPackStep3 =>
      '🎯 Step 3 · Boss — listen and choose the meaning';

  @override
  String get coachPackStageQuiz => 'Quiz time! Pick the right translation.';

  @override
  String get coachPackStageBoss => 'The boss is waiting — listen closely!';

  @override
  String get coachBtnGotIt => 'Got it!';

  @override
  String get previewSkip => 'Skip';

  @override
  String get previewNext => 'Next';

  @override
  String get previewStart => 'Let\'s go';

  @override
  String get previewPage1Title => 'Photo → Word list';

  @override
  String get previewPage1Body =>
      'Snap a photo of your textbook or a menu — words land straight in your learning list.';

  @override
  String get previewPage2Title => 'Your hanok grows';

  @override
  String get previewPage2Body =>
      'Every word pack you finish builds your own Korean house — brick by brick.';

  @override
  String get previewPage3Title => 'Daily with the Tiger';

  @override
  String get previewPage3Body =>
      'Even 5 minutes a day keeps the progress going. The Tiger will remind you.';

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
    return '$n days in a row';
  }

  @override
  String get hubPracticeStreakZero => 'Start today!';

  @override
  String hubWordbookSaved(int n) {
    return '$n words saved';
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
  String get coachHomeTab2Body => 'Reach your goals together with friends';

  @override
  String get coachHomeTab3Title => 'Profile';

  @override
  String get coachHomeTab3Body => 'Stats, settings & account';

  @override
  String get coachHomePathTitle => 'Learning path';

  @override
  String get coachHomePathBody =>
      'Clear word packs in order — the tiger grows with you';

  @override
  String get coachHomeBookTitle => 'Book snapshot';

  @override
  String get coachHomeBookBody =>
      'Photo of your textbook — straight into your word list';
}
