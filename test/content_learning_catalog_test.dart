import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_catalog.dart';
import 'package:ko_lernen_app/features/content_learning/content_learning_models.dart';
import 'package:ko_lernen_app/models/scenario.dart';

Map<String, dynamic> read(String name) =>
    jsonDecode(File('assets/data/$name.json').readAsStringSync())
        as Map<String, dynamic>;
void localized(LocalizedText text) {
  expect(text.ko.trim(), isNotEmpty);
  expect(text.de.trim(), isNotEmpty);
  expect(text.en.trim(), isNotEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
  for (final kind in LearningContentKind.values) {
    test(
      '${kind.name} catalog covers canonical sources with valid exercises',
      () async {
        final lessons = await ContentLearningCatalog.load(kind);
        final sources = <String, Map<String, dynamic>>{};
        for (final filename
            in kind == LearningContentKind.smalltalk
                ? ['smalltalk']
                : levels.map((l) => 'scenarios_$l')) {
          for (final source
              in read(filename)[kind == LearningContentKind.smalltalk
                      ? 'phrases'
                      : 'scenarios']
                  as List) {
            sources[source['id'] as String] = source as Map<String, dynamic>;
          }
        }
        final used = <String>[];
        for (final lesson in lessons) {
          localized(lesson.title);
          localized(lesson.intro);
          used.addAll(lesson.contentIds);
          final phrases = lesson.contentIds.map((id) => sources[id]!).toList();
          expect(
            phrases.every(
              (p) => (p['level'] as String).toLowerCase() == lesson.level,
            ),
            isTrue,
          );
          if (kind == LearningContentKind.smalltalk) {
            final cap = {
              'a1': 6,
              'a2': 6,
              'b1': 5,
              'b2': 5,
              'c1': 4,
              'c2': 4,
            }[lesson.level]!;
            expect(lesson.contentIds.length, lessThanOrEqualTo(cap));
            expect(
              lesson.questions.length,
              greaterThanOrEqualTo(lesson.contentIds.length + 1),
            );
            expect(lesson.questions.any((q) => q.skill == 'situation'), isTrue);
            for (final id in lesson.contentIds) {
              expect(
                lesson.questions.any((q) => q.sourceIds.contains(id)),
                isTrue,
              );
            }
            expect(
              phrases.every((p) => p['category'] == lesson.topicId),
              isTrue,
            );
          } else {
            expect(lesson.contentIds, hasLength(1));
            expect(lesson.questions.map((q) => q.skill).toSet(), {
              'situation',
              'meaning',
              'sentence',
              'response',
            });
            expect(lesson.topicId, phrases.single['shelf']);
          }
          final sourceKo = kind == LearningContentKind.smalltalk
              ? phrases.map((p) => p['ko'] as String).toSet()
              : (phrases.single['dialog'] as List)
                    .map((line) => line['ko'] as String)
                    .toSet();
          for (final q in lesson.questions) {
            localized(q.prompt);
            localized(q.explanation);
            if (q.type == 'choice') {
              for (final option in q.options) {
                localized(option);
              }
              for (final lang in ['ko', 'de', 'en']) {
                expect(
                  q.options.map((o) => o.pick(lang).trim()).toSet().length,
                  q.options.length,
                  reason: '${q.id} duplicate $lang choices',
                );
              }
            }
            if (q.audioKo.isNotEmpty) {
              expect(
                sourceKo,
                contains(q.audioKo),
                reason: '${q.id} unverified audio',
              );
            }
            if (q.evidenceKo.isNotEmpty) {
              expect(
                sourceKo,
                contains(q.evidenceKo),
                reason: '${q.id} missing exact evidence',
              );
            }
            if (q.type == 'order') {
              expect(sourceKo, contains(q.targetKo));
            }
          }
        }
        expect(used.toSet(), sources.keys.toSet());
        expect(used.length, sources.length);
      },
    );
  }
  test(
    'A1 theme park is authored 4/4/2; mood is a finite two-card lesson',
    () async {
      final lessons = await ContentLearningCatalog.load(
        LearningContentKind.smalltalk,
      );
      expect(
        lessons
            .where((l) => l.level == 'a1' && l.topicId == 'theme_park_date')
            .map((l) => l.contentIds.length)
            .toList(),
        [4, 4, 2],
      );
      expect(
        lessons
            .singleWhere((l) => l.level == 'a1' && l.topicId == 'mood')
            .contentIds,
        hasLength(2),
      );
    },
  );
}
