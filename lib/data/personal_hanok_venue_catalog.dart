import '../models/personal_hanok.dart';

/// Existing Hangul Sori destinations offered from a completed Hanok place.
///
/// This catalog intentionally stores only stable action ids and established
/// routes. It never reads progress, rewards, room placement, or Gye state.
enum PersonalHanokVenueAction {
  furnishAnbang,
  openBookshelf,
  searchWordbook,
  captureBook,
  furnishDaecheong,
  openLearningPath,
  openPractice,
  openDailyCharacter,
  openQuests,
  openDojang,
  openStats,
}

const _actionsByZone = <PersonalHanokZone, List<PersonalHanokVenueAction>>{
  PersonalHanokZone.anchae: <PersonalHanokVenueAction>[
    PersonalHanokVenueAction.furnishAnbang,
    PersonalHanokVenueAction.openBookshelf,
    PersonalHanokVenueAction.searchWordbook,
    PersonalHanokVenueAction.captureBook,
  ],
  PersonalHanokZone.daecheongmaru: <PersonalHanokVenueAction>[
    PersonalHanokVenueAction.furnishDaecheong,
    PersonalHanokVenueAction.openLearningPath,
  ],
  PersonalHanokZone.haengrangchae: <PersonalHanokVenueAction>[
    PersonalHanokVenueAction.openPractice,
  ],
  PersonalHanokZone.huwon: <PersonalHanokVenueAction>[
    PersonalHanokVenueAction.openDailyCharacter,
    PersonalHanokVenueAction.openQuests,
  ],
  PersonalHanokZone.sadang: <PersonalHanokVenueAction>[
    PersonalHanokVenueAction.openDojang,
    PersonalHanokVenueAction.openStats,
  ],
};

List<PersonalHanokVenueAction> personalHanokVenueActionsFor(
  PersonalHanokZone zone,
) => _actionsByZone[zone] ?? const <PersonalHanokVenueAction>[];

/// `null` is a deliberate local-sheet action, not an absent implementation.
String? personalHanokVenueRoute(PersonalHanokVenueAction action) =>
    switch (action) {
      PersonalHanokVenueAction.furnishAnbang => '/hanok/anbang',
      PersonalHanokVenueAction.openBookshelf => '/bookshelf',
      PersonalHanokVenueAction.searchWordbook => '/wordbook/search',
      PersonalHanokVenueAction.captureBook => '/book',
      PersonalHanokVenueAction.furnishDaecheong => '/hanok/daecheong',
      PersonalHanokVenueAction.openLearningPath => '/path',
      PersonalHanokVenueAction.openPractice => '/practice',
      PersonalHanokVenueAction.openDailyCharacter => null,
      PersonalHanokVenueAction.openQuests => '/quests',
      PersonalHanokVenueAction.openDojang => '/dojangcheop',
      PersonalHanokVenueAction.openStats => '/stats',
    };
