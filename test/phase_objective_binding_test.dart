import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<Map<String, dynamic>> source() async =>
      jsonDecode(await rootBundle.loadString(PhaseTaskCatalog.assetPath))
          as Map<String, dynamic>;
  test(
    'all published paths retain unscored writing boundaries',
    () async {
      final catalog = await PhaseTaskCatalog.load();
      expect(
        catalog.objectives.every((o) => o.bindings.isNotEmpty),
        isTrue,
      );
      expect(catalog.objectives, hasLength(1668));
      final email = catalog.objectives.singleWhere(
        (o) => o.id == 'KP06:objective:writing/genre/email_informal:P',
      );
      expect(email.bindings.single.evaluationScope, 'includes_unscored');
      expect(
        catalog.objectives
            .singleWhere((o) => o.id == 'KP01:objective:grammar/G1:이다:P')
            .bindings
            .single
            .taskId,
        'KP01:production:01',
      );
    },
  );
  test('absent routes remain in the objective denominator', () async {
    final raw = await source();
    final objective = (raw['objectives'] as List).first;
    objective['bindings'] = <dynamic>[];
    objective['coverage'] = 'unverified';
    final catalog = PhaseTaskCatalog.parse(raw);
    expect(catalog.objectives, hasLength(1668));
    expect(catalog.objectives.first.bindings, isEmpty);
  });
  test(
    'missing material, criterion and false scoring scope are rejected',
    () async {
      for (final fault in [
        'material',
        'criterion',
        'scope',
        'task',
        'mode',
        'publication',
      ]) {
        final raw = await source();
        final objective = (raw['objectives'] as List).firstWhere(
          (o) => (o['bindings'] as List).isNotEmpty,
        );
        final binding = objective['bindings'][0];
        switch (fault) {
          case 'material':
            binding['materialIds'] = ['not-a-material'];
          case 'criterion':
            binding['criterionIds'] = ['not-a-question'];
          case 'scope':
            binding['evaluationScope'] = 'fully_assessable';
          case 'task':
            binding['taskId'] = 'KP30:missing';
          case 'mode':
            objective['mode'] = 'P';
          case 'publication':
            raw['publicationRecords'][0]['contentHash'] = '0' * 64;
        }
        expect(
          () => PhaseTaskCatalog.parse(raw),
          throwsFormatException,
          reason: fault,
        );
      }
    },
  );
  test(
    'v1 task catalogues remain readable without claiming objective coverage',
    () async {
      final raw = await source();
      raw['schemaVersion'] = 1;
      raw.remove('objectives');
      raw.remove('publicationRecords');
      final legacy = PhaseTaskCatalog.parse(raw);
      expect(legacy.tasks, isNotEmpty);
      expect(legacy.objectives, isEmpty);
    },
  );
}
