import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_venue_catalog.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';

void main() {
  group('personal Hanok venue catalog', () {
    test('keeps the Sarangbang recommendation surface direct', () {
      expect(
        personalHanokVenueActionsFor(PersonalHanokZone.sarangbang),
        isEmpty,
      );
    });

    test('gives the Anchae its interior and saved-learning destinations', () {
      expect(
        personalHanokVenueActionsFor(PersonalHanokZone.anchae),
        orderedEquals(const <PersonalHanokVenueAction>[
          PersonalHanokVenueAction.furnishAnbang,
          PersonalHanokVenueAction.openBookshelf,
          PersonalHanokVenueAction.searchWordbook,
          PersonalHanokVenueAction.captureBook,
        ]),
      );
    });

    test('keeps the Huwon attached to today’s letter and quests', () {
      expect(
        personalHanokVenueActionsFor(PersonalHanokZone.huwon),
        orderedEquals(const <PersonalHanokVenueAction>[
          PersonalHanokVenueAction.openDailyCharacter,
          PersonalHanokVenueAction.openQuests,
        ]),
      );
      expect(
        personalHanokVenueRoute(PersonalHanokVenueAction.openDailyCharacter),
        isNull,
      );
      expect(
        personalHanokVenueRoute(PersonalHanokVenueAction.openQuests),
        '/quests',
      );
    });

    test('does not make the noninteractive Gye road into a personal venue', () {
      expect(personalHanokVenueActionsFor(PersonalHanokZone.gyeRoad), isEmpty);
    });
  });
}
