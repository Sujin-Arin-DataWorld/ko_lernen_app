import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const callerPaths = <String>[
    'lib/screens/custom_pack_play_screen.dart',
    'lib/screens/grammar_screen.dart',
    'lib/screens/hangul_screen.dart',
    'lib/screens/legacy_vocab_screen.dart',
    'lib/screens/listening_play_screen.dart',
    'lib/screens/review_session_screen.dart',
    'lib/screens/smalltalk_screen.dart',
    'lib/screens/vocab_pack_screen.dart',
  ];

  test('all eight like callers use the shared confirmed-choice owner', () {
    for (final path in callerPaths) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('ConfirmedChoiceActionOwner'),
        reason: '$path must own confirmed pending/failure/retry state.',
      );
      expect(
        source,
        contains('ConfirmedChoiceTarget.liked('),
        reason: '$path must freeze a concrete liked-content target.',
      );
      expect(
        source,
        isNot(contains('LikedContentService.toggle(')),
        reason: '$path must not bypass confirmed UI ownership.',
      );
    }
  });

  test('legacy vocabulary keeps its add-only star path explicit', () {
    final source = File(
      'lib/screens/legacy_vocab_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ConfirmedChoiceTarget.legacyFavorite('));
    expect(source, contains('_choiceOwner.set('));
    expect(source, contains('true,'));
    expect(source, contains('_favorites = Storage.vokFavorites.toSet()'));
  });

  test('source-sensitive callers freeze a rendered source token', () {
    final listening = File(
      'lib/screens/listening_play_screen.dart',
    ).readAsStringSync();
    final customPack = File(
      'lib/screens/custom_pack_play_screen.dart',
    ).readAsStringSync();
    final vocabPack = File(
      'lib/screens/vocab_pack_screen.dart',
    ).readAsStringSync();
    final smalltalk = File(
      'lib/screens/smalltalk_screen.dart',
    ).readAsStringSync();

    expect(listening, contains('sourceGeneration != _likeSourceGeneration'));
    expect(listening, contains('!identical(scenario, _scenario)'));
    expect(customPack, contains('presentation == _serve'));
    expect(customPack, contains('_serve++;'));
    expect(vocabPack, contains('sourceGeneration != _likeSourceGeneration'));
    expect(vocabPack, contains('_likeSourceIsCurrent'));
    expect(
      RegExp(
        r'widget\.phrases\s*\?\?\s*SmalltalkLoader\.phrases',
      ).allMatches(smalltalk).length,
      greaterThanOrEqualTo(2),
    );
    expect(smalltalk, contains('_phrasesFor(category: current.id'));
  });
}
