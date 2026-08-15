import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/pronunciation_phrase_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PronunciationPhraseLoader.reset);
  tearDown(PronunciationPhraseLoader.reset);

  test(
    'bundled migration seed preserves the four approved live phrases',
    () async {
      final phrases = await PronunciationPhraseLoader.load();

      expect(PronunciationPhraseLoader.lastError, isNull);
      final byId = {for (final phrase in phrases) phrase.id: phrase};
      expect(byId['pronunciation_a1_0001']?.ko, '안녕하세요');
      expect(byId['pronunciation_a1_0002']?.ko, '감사합니다');
      expect(byId['pronunciation_a2_0001']?.ko, '덜 맵게 해 주세요');
      expect(byId['pronunciation_a2_0002']?.ko, '지하철역이 어디예요?');
      expect(byId['pronunciation_a1_0001']?.level, LearnerLevel.a1);
      expect(byId['pronunciation_a2_0001']?.level, LearnerLevel.a2);
    },
  );

  test('parser requires the versioned reviewed phrase schema', () {
    final phrases = PronunciationPhraseLoader.parse(
      jsonEncode({
        'version': 1,
        'phrases': [
          {
            'id': 'pronunciation_b1_0001',
            'level': 'b1',
            'ko': '회의는 내일로 미뤄졌어요.',
            'de': 'Das Treffen wurde auf morgen verschoben.',
            'en': 'The meeting was postponed until tomorrow.',
            'focus': '유음화',
          },
          {
            'id': 'pronunciation_c2_0001',
            'level': 'c2',
            'ko': '책임 소재를 분명히 짚고 넘어가겠습니다.',
            'de': 'Ich werde die Verantwortlichkeit klar benennen.',
            'en': 'I will clearly identify where responsibility lies.',
            'focus': '된소리되기',
          },
        ],
      }),
    );

    expect(phrases, hasLength(2));
    expect(phrases.last.level, LearnerLevel.c2);
    expect(
      () => PronunciationPhraseLoader.parse(
        '{"version": 1, "phrases": [{"id": "bad"}]}',
      ),
      throwsFormatException,
    );
    expect(
      () => PronunciationPhraseLoader.parse(
        jsonEncode({
          'version': 1,
          'phrases': [
            {
              'id': 'pronunciation_b2_0001',
              'level': 'a1',
              'ko': '안녕하세요',
              'de': 'Guten Tag.',
              'en': 'Hello.',
              'focus': 'ㅎ 발음',
            },
          ],
        }),
      ),
      throwsFormatException,
    );
  });

  test('filters phrases cumulatively through canonical learner ranks', () {
    const phrases = <PronunciationPhrase>[
      PronunciationPhrase(
        id: 'pronunciation_a1_0001',
        level: LearnerLevel.a1,
        ko: '안녕하세요',
        de: 'Guten Tag.',
        en: 'Hello.',
        focus: 'ㅎ 발음',
      ),
      PronunciationPhrase(
        id: 'pronunciation_a2_0001',
        level: LearnerLevel.a2,
        ko: '덜 맵게 해 주세요',
        de: 'Bitte weniger scharf.',
        en: 'Please make it less spicy.',
        focus: '경음화',
      ),
      PronunciationPhrase(
        id: 'pronunciation_b1_0001',
        level: LearnerLevel.b1,
        ko: '회의는 내일로 미뤄졌어요.',
        de: 'Das Treffen wurde auf morgen verschoben.',
        en: 'The meeting was postponed until tomorrow.',
        focus: '유음화',
      ),
      PronunciationPhrase(
        id: 'pronunciation_b2_0001',
        level: LearnerLevel.b2,
        ko: '의견을 서면으로 제출해 주세요.',
        de: 'Bitte reichen Sie Ihre Meinung schriftlich ein.',
        en: 'Please submit your opinion in writing.',
        focus: '연음',
      ),
      PronunciationPhrase(
        id: 'pronunciation_c1_0001',
        level: LearnerLevel.c1,
        ko: '자료의 한계를 함께 밝혀야 합니다.',
        de: 'Die Grenzen der Daten müssen ebenfalls genannt werden.',
        en: 'The limitations of the data must also be stated.',
        focus: '비음화',
      ),
      PronunciationPhrase(
        id: 'pronunciation_c2_0001',
        level: LearnerLevel.c2,
        ko: '책임 소재를 분명히 짚고 넘어가겠습니다.',
        de: 'Ich werde die Verantwortlichkeit klar benennen.',
        en: 'I will clearly identify where responsibility lies.',
        focus: '된소리되기',
      ),
    ];

    expect(
      PronunciationPhraseLoader.forLearnerLevel(
        phrases,
        LearnerLevel.a1,
      ).map((phrase) => phrase.id),
      ['pronunciation_a1_0001'],
    );
    expect(
      PronunciationPhraseLoader.forLearnerLevel(
        phrases,
        LearnerLevel.b1,
      ).map((phrase) => phrase.id),
      [
        'pronunciation_a1_0001',
        'pronunciation_a2_0001',
        'pronunciation_b1_0001',
      ],
    );
    expect(
      PronunciationPhraseLoader.forLearnerLevel(
        phrases,
        LearnerLevel.b2,
      ).map((phrase) => phrase.id),
      hasLength(4),
    );
    expect(
      PronunciationPhraseLoader.forLearnerLevel(
        phrases,
        LearnerLevel.c2,
      ).map((phrase) => phrase.id),
      hasLength(6),
    );
  });
}
