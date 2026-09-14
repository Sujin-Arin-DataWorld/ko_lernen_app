import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

import '../helpers/deck_actions.dart';

/// Canonical content is loaded outside the fake clock; mutation queues belong
/// to this widget test's own Zone. Production finish operations remain intact.
Future<VocabPack> loadCanonicalWidgetPack(WidgetTester tester) async {
  Storage.resetForTesting();
  await Storage.init();
  final packs = await tester.runAsync(() async {
    await CurriculumCatalog.load();
    return VocabPackService.loadAll();
  });
  CourseProgressService.shared.resetForTesting();
  DecorationRewardService.resetForTesting();
  return packs!.firstWhere((pack) => pack.bossWords.isNotEmpty);
}

Future<void> completeCanonicalWidgetPack(
  WidgetTester tester,
  VocabPack pack,
) async {
  final t = AppL10n.of(tester.element(find.byType(FlipCard)));
  for (var index = 0; index < pack.total; index++) {
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump(const Duration(milliseconds: 400));
    tapDeckAction(tester, t.vocabPackGotIt);
    await tester.pump(const Duration(milliseconds: 400));
  }
  for (var index = 0; index < pack.total; index++) {
    tester
        .widgetList<QuizChoice>(find.byType(QuizChoice))
        .firstWhere((choice) => choice.isCorrect)
        .onSelected!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
  }
}

Future<void> pumpUntilPackSignal(
  WidgetTester tester,
  bool Function() completed,
) async {
  for (var index = 0; index < 100 && !completed(); index++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(completed(), isTrue, reason: 'Owned pack operation must settle.');
}
