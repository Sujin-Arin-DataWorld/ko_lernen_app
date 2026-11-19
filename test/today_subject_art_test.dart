import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/course_mission_brief.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/today_subject_art.dart';

CoursePick _pick(CourseUnit unit) => CoursePick(
  unit: unit,
  missionNumber: 1,
  totalMissions: 48,
  fraction: 0,
  started: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'real first links preserve the four exact Figma topic subjects',
    () async {
      final catalog = await CurriculumCatalog.load();
      const expected = {
        'a2_02_plans_proposals': 'plans-proposals.png',
        'b2_03_precise_requests': 'request-negotiation.png',
        'c1_04_play_time_policy': 'participation-policy.png',
        'c2_01_interpretation_institutions': 'institutional-mandate.png',
      };
      for (final entry in expected.entries) {
        final unit = catalog.courseUnitFor(entry.key)!;
        final brief = CourseMissionBrief.from(
          unit: unit,
          links: catalog.linksForCourseUnit(unit.id),
          scenarios: const [],
          isCurrent: true,
        );
        expect(brief.firstLink, isNotNull);
        expect(
          TodaySubjectArt.topicForPick(
            _pick(unit),
            link: brief.firstLink,
          )?.path,
          '${TodaySubjectArt.root}${entry.value}',
          reason: entry.key,
        );
      }
    },
  );

  test(
    'active real vocabulary selects its pack within a broader unit',
    () async {
      final catalog = await CurriculumCatalog.load();
      final words = await DataLoader.loadVocab();
      final word = words.firstWhere((word) => word.packId == 'a2_restaurant_1');
      final unit = catalog.courseUnitFor('a2_05_delivery_services')!;
      final link = catalog
          .linksForContent(CurriculumContentKind.vocab, word.id)
          .singleWhere((link) => link.courseUnitId == unit.id);

      // Delivery and product problems have no blanket restaurant illustration.
      expect(TodaySubjectArt.topicForPick(_pick(unit)), isNull);
      expect(
        TodaySubjectArt.topicForPick(_pick(unit), link: link)?.path,
        '${TodaySubjectArt.root}restaurant.png',
      );
      final unrelated = catalog.courseUnitFor('a2_04_feelings_health')!;
      expect(
        TodaySubjectArt.topicForPick(_pick(unrelated), link: link),
        isNull,
        reason: 'A stale link from another unit must not leak its subject.',
      );
    },
  );

  test(
    'the receipt resolves against the current vocabulary and graph',
    () async {
      final receipt =
          jsonDecode(
                File('docs/assets/today-topic-art.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final catalog = await CurriculumCatalog.load();
      final vocabulary = {
        for (final word in await DataLoader.loadVocab()) word.id: word,
      };

      for (final raw in receipt['linkedVocabularySubjects'] as List) {
        final entry = raw as Map<String, dynamic>;
        final unit = catalog.courseUnitFor(entry['courseUnitId'] as String)!;
        final expected = TodaySubjectArt.subjectImages[entry['subject']]!;
        final ids = (entry['vocabularyIds'] as List).cast<String>();
        expect(ids, isNotEmpty);
        for (final id in ids) {
          expect(vocabulary[id]?.packId, entry['packId'], reason: id);
          final link = catalog
              .linksForContent(CurriculumContentKind.vocab, id)
              .singleWhere((link) => link.courseUnitId == unit.id);
          expect(
            TodaySubjectArt.topicForPick(_pick(unit), link: link),
            same(expected),
            reason: '${unit.id}:$id',
          );
        }
      }
      for (final raw in receipt['courseSubjects'] as List) {
        final entry = raw as Map<String, dynamic>;
        final unit = catalog.courseUnitFor(entry['courseUnitId'] as String)!;
        expect(unit.checkpointContentIds, entry['checkpointContentIds']);
        expect(
          TodaySubjectArt.topicForPick(_pick(unit)),
          same(TodaySubjectArt.subjectImages[entry['subject']]),
        );
      }
    },
  );

  test(
    'installed originals keep the recorded bytes and native optical bounds',
    () {
      final receipt =
          jsonDecode(
                File('docs/assets/today-topic-art.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final raw in receipt['assets'] as List) {
        final entry = raw as Map<String, dynamic>;
        final asset = File(entry['asset'] as String);
        expect(
          sha256.convert(asset.readAsBytesSync()).toString(),
          entry['sha256'],
          reason: asset.path,
        );
        final image = TodaySubjectArt.subjectImages[entry['subject']]!;
        final size = (entry['size'] as List).cast<num>();
        final bounds = (entry['renderRegionPixels'] as List).cast<num>();
        expect(image.path, asset.path);
        expect(
          image.region,
          Rect.fromLTRB(
            bounds[0] / size[0],
            bounds[1] / size[1],
            bounds[2] / size[0],
            bounds[3] / size[1],
          ),
        );
        expect(image.region.width, greaterThan(0));
        expect(image.region.height, greaterThan(0));
        expect(image.region.left, greaterThanOrEqualTo(0));
        expect(image.region.top, greaterThanOrEqualTo(0));
        expect(image.region.right, lessThanOrEqualTo(1));
        expect(image.region.bottom, lessThanOrEqualTo(1));
      }
    },
  );

  test(
    'unreviewed subjects retain an honest fallback despite similar names',
    () async {
      final catalog = await CurriculumCatalog.load();
      final numbers = catalog.courseUnitFor('a1_05_numbers_time')!;
      expect(TodaySubjectArt.topicForPick(_pick(numbers)), isNull);
      expect(TodaySubjectArt.forPick(_pick(numbers)), isA<CReferenceArt>());
      for (final id in ['a1_body', 'a1_numbers', 'a2_unknown_1']) {
        final pick = PackPick(
          pack: VocabPack(id: id, level: 'A2', words: const []),
          fraction: 0,
        );
        expect(TodaySubjectArt.topicForPick(pick), isNull, reason: id);
      }
      final apology = catalog.courseUnitFor('a1_10_health_safety')!;
      expect(
        TodaySubjectArt.topicForPick(_pick(apology))?.path,
        '${TodaySubjectArt.root}sorry-thanks.png',
        reason: 'Current broken-glass checkpoint is an apology, not anatomy.',
      );
    },
  );

  test(
    'the existing greeting, Hangul and review environments are preserved',
    () async {
      final catalog = await CurriculumCatalog.load();
      final greeting = catalog.courseUnitFor('a1_01_greetings_hangul')!;
      final cases = <(MissionPick, Rect)>[
        (_pick(greeting), const Rect.fromLTRB(0, .08, .5, .5)),
        (const HangulIntroPick(), const Rect.fromLTRB(0, .58, .5, 1)),
        (const ReviewPick(dueCount: 12), const Rect.fromLTRB(.5, .08, 1, .5)),
      ];
      for (final (pick, region) in cases) {
        final art = TodaySubjectArt.forPick(pick) as CAtlasArt;
        expect(art.path, TodaySubjectArt.environments);
        expect(art.region, region);
      }
    },
  );
}
