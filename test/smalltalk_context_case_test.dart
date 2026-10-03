import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/smalltalk_context_catalog.dart';
import 'package:ko_lernen_app/models/scenario_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'ten complete triads have two cases per action and a genuine transfer',
    () async {
      final cases = await SmalltalkContextCatalog.load();
      expect(cases.length, 10);
      expect(cases.map((c) => c.id).toSet().length, 10);
      for (final topic in [
        'invite',
        'request',
        'refuse',
        'apologize',
        'repair',
      ]) {
        expect(cases.where((c) => c.topic == topic).length, 2);
      }
      for (final c in cases) {
        expect(c.base.context.ko, isNot(c.transfer.context.ko));
        expect(
          ScenarioCharacterCatalog.profileFor(c.base.characterId),
          isNotNull,
        );
        expect(
          ScenarioCharacterCatalog.profileFor(c.transfer.characterId),
          isNotNull,
        );
        expect(c.intents.length, greaterThanOrEqualTo(2));
        expect(
          c.intents.map((i) => i.id),
          contains(c.transfer.requiredIntentId),
        );
        for (final i in c.intents) {
          expect(i.expressions.length, greaterThanOrEqualTo(2));
          for (final e in i.expressions) {
            expect(e.followUpTokens.join(' '), e.followUp.ko);
            for (final text in [
              c.title,
              c.base.context,
              c.transfer.context,
              c.base.prompt,
              c.transfer.prompt,
              i.label,
              e.text,
              e.effect,
              e.followUp,
              e.partnerReply,
            ]) {
              expect(text.ko.trim(), isNotEmpty);
              expect(text.de.trim(), isNotEmpty);
              expect(text.en.trim(), isNotEmpty);
              expect(
                '${text.ko}${text.de}${text.en}',
                isNot(contains('\uFFFD')),
              );
            }
            expect(e.grammarValid, isTrue);
          }
        }
      }
    },
  );
}
