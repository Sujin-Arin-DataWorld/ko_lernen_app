import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/screens/word_web_screen.dart';
import 'package:ko_lernen_app/services/pronunciation_phrase_loader.dart';
import 'package:ko_lernen_app/services/pronunciation_playback.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/word_relation_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Future<ByteData?> Function(String) read;
  final reads = <String, int>{};

  Future<ByteData?> readBundled(String path) => _readBundledFile(path);

  void resetLoaders() {
    PronunciationPhraseLoader.reset();
    SmalltalkLoader.reset();
    WordRelationService.resetForTesting();
    rootBundle.clear();
  }

  setUp(() async {
    stubSoriSpeech();
    resetLoaders();
    SharedPreferences.setMockInitialValues({
      'existing-progress': 'keep',
      'kl_user_level': 'a1',
      'kl_tut_smalltalk': true,
      'kl_tut_wordWeb': true,
    });
    Storage.resetForTesting();
    await Storage.init();
    reads.clear();
    read = readBundled;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final path = const StringCodec().decodeMessage(message)!;
          reads.update(path, (count) => count + 1, ifAbsent: () => 1);
          return read(path);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    resetLoaders();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  for (final failure in _failures) {
    test(
      'pronunciation loader recovers a ${failure.name} asset response without clearing caches',
      () async {
        _failFirstRead(
          path: PronunciationPhraseLoader.assetPath,
          failure: failure,
          reads: reads,
          setRead: (value) => read = value,
        );
        final before = await _preferences();

        final failed = await PronunciationPhraseLoader.load();
        expect(failed, isEmpty);
        expect(PronunciationPhraseLoader.lastError, isNotNull);

        PronunciationPhraseLoader.reset();
        final recovered = await PronunciationPhraseLoader.load();
        expect(reads[PronunciationPhraseLoader.assetPath], 2);
        expect(recovered.first.ko, '안녕하세요');
        expect(recovered.first.de, 'Hallo.');
        expect(recovered.first.en, 'Hello.');

        await PronunciationPhraseLoader.load();
        expect(reads[PronunciationPhraseLoader.assetPath], 2);
        expect(await _preferences(), before);
      },
    );

    test(
      'smalltalk loader recovers a ${failure.name} asset response without clearing caches',
      () async {
        const assetPath = 'assets/data/smalltalk.json';
        _failFirstRead(
          path: assetPath,
          failure: failure,
          reads: reads,
          setRead: (value) => read = value,
        );
        final before = await _preferences();

        await SmalltalkLoader.load();
        expect(SmalltalkLoader.lastError, isNotNull);
        expect(SmalltalkLoader.phrases, isEmpty);

        SmalltalkLoader.reset();
        await SmalltalkLoader.load();
        expect(reads[assetPath], 2);
        expect(SmalltalkLoader.phrases, isNotEmpty);
        expect(SmalltalkLoader.phrases.first.ko, isNotEmpty);
        expect(SmalltalkLoader.phrases.first.de, isNotEmpty);
        expect(SmalltalkLoader.phrases.first.en, isNotEmpty);

        await SmalltalkLoader.load();
        expect(reads[assetPath], 2);
        expect(await _preferences(), before);
      },
    );

    test(
      'word-web loader recovers a ${failure.name} asset response without clearing caches',
      () async {
        _failFirstRead(
          path: WordRelationService.assetPath,
          failure: failure,
          reads: reads,
          setRead: (value) => read = value,
        );
        final before = await _preferences();

        await expectLater(
          WordRelationService.load(),
          failure.missing ? throwsFlutterError : throwsFormatException,
        );

        final recovered = await WordRelationService.load();
        expect(reads[WordRelationService.assetPath], 2);
        expect(recovered.first.sourceKo, '안녕하세요');
        expect(recovered.first.sourceDe, 'Hallo (höflich)');
        expect(recovered.first.sourceEn, 'Hello (polite)');

        await WordRelationService.load();
        expect(reads[WordRelationService.assetPath], 2);
        expect(await _preferences(), before);
      },
    );
  }

  test(
    'word-web injected loader bypasses and preserves the successful bundled cache',
    () async {
      final bundled = await WordRelationService.load();
      var injectedCalls = 0;
      final injected = await WordRelationService.load(
        assetLoader: (_) async {
          injectedCalls++;
          return jsonEncode({
            'clusters': [
              {
                'id': 'injected_cluster',
                'sourceKo': '시험',
                'sourceVocabId': 'fixture_vocab',
                'level': 'A1',
                'synonyms': [
                  {'ko': '검사', 'de': 'Prüfung', 'en': 'test'},
                ],
              },
            ],
          });
        },
      );

      expect(injectedCalls, 1);
      expect(injected.single.id, 'injected_cluster');
      expect(injected.single.sourceKo, '시험');
      expect(reads[WordRelationService.assetPath], 1);

      final bundledAgain = await WordRelationService.load();
      expect(identical(bundledAgain, bundled), isTrue);
      expect(bundledAgain.first.id, 'rel_a1_0001');
      expect(reads[WordRelationService.assetPath], 1);
    },
  );

  for (final failure in _failures) {
    testWidgets(
      'pronunciation studio restores local practice controls after a ${failure.name} asset response',
      (tester) async {
        _failFirstRead(
          path: PronunciationPhraseLoader.assetPath,
          failure: failure,
          reads: reads,
          setRead: (value) => read = value,
        );
        final t = await AppL10n.delegate.load(const Locale('en'));

        await tester.pumpWidget(
          _host(
            PronunciationStudioScreen(
              recorder: const _NoopRecorder(),
              playback: const _NoopPlayback(),
              cloudAssessmentEnabled: false,
            ),
          ),
        );
        await _pumpUntil(tester, find.byType(SoriEmptyState));
        expect(
          find.text(t.pronunciationPhrasesUnavailableTitle),
          findsOneWidget,
        );

        await _press(tester, t.btnRetry);
        await _pumpUntil(tester, find.text('안녕하세요'));
        expect(reads[PronunciationPhraseLoader.assetPath], 2);
        expect(find.byType(SoriSpeechIndicator), findsOneWidget);
        expect(find.text(t.pronunciationRecord), findsOneWidget);
      },
    );

    testWidgets(
      'smalltalk restores its practice feed after a ${failure.name} asset response',
      (tester) async {
        const assetPath = 'assets/data/smalltalk.json';
        _failFirstRead(
          path: assetPath,
          failure: failure,
          reads: reads,
          setRead: (value) => read = value,
        );
        final t = await AppL10n.delegate.load(const Locale('en'));

        await tester.pumpWidget(_host(const SmalltalkScreen()));
        await _pumpUntil(tester, find.byType(AppError));
        expect(find.text(t.courseMissionLoadError), findsOneWidget);

        await _press(tester, t.btnRetry);
        await _pumpUntil(tester, find.byType(SoriContentFeed));
        expect(reads[assetPath], 2);
        expect(find.byType(AppError), findsNothing);
      },
    );

    testWidgets(
      'word-web restores study controls after a ${failure.name} asset response',
      (tester) async {
        _failFirstRead(
          path: WordRelationService.assetPath,
          failure: failure,
          reads: reads,
          setRead: (value) => read = value,
        );
        final t = await AppL10n.delegate.load(const Locale('en'));

        await tester.pumpWidget(
          _host(const WordWebScreen(seenLoader: _seenHello)),
        );
        await _pumpUntil(tester, find.byType(SoriEmptyState));
        expect(find.text(t.wordWebLoadErrorTitle), findsOneWidget);

        await _press(tester, t.btnRetry);
        await _pumpUntil(tester, find.byKey(const ValueKey('rel_a1_0001')));
        expect(reads[WordRelationService.assetPath], 2);
        expect(find.text('안녕하세요'), findsOneWidget);
        expect(find.text('Hello (polite)'), findsOneWidget);
      },
    );
  }
}

const List<_Failure> _failures = [
  _Failure(name: 'missing', missing: true),
  _Failure(name: 'malformed JSON', missing: false),
];

class _Failure {
  const _Failure({required this.name, required this.missing});

  final String name;
  final bool missing;
}

void _failFirstRead({
  required String path,
  required _Failure failure,
  required Map<String, int> reads,
  required void Function(Future<ByteData?> Function(String)) setRead,
}) {
  setRead((requested) async {
    if (requested == path && reads[requested] == 1) {
      if (failure.missing) {
        return null;
      }
      return ByteData.sublistView(Uint8List.fromList(utf8.encode('not json')));
    }
    return _readBundledFile(requested);
  });
}

Future<ByteData?> _readBundledFile(String path) async {
  final source = File(path);
  final file = await source.exists()
      ? source
      : File('build/unit_test_assets/$path');
  return ByteData.sublistView(await file.readAsBytes());
}

Future<Map<String, Object?>> _preferences() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, appChild) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: SoriTypeScale(child: appChild!),
    );
  },
  home: child,
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

Future<void> _press(WidgetTester tester, String label) async {
  final button = find.widgetWithText(SoriButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

Set<String> _seenHello() => const {'안녕하세요'};

class _NoopRecorder implements PronunciationRecorder {
  const _NoopRecorder();

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<Stream<Uint8List>> startPcm16Stream() async => const Stream.empty();

  @override
  Future<void> stop() async {}
}

class _NoopPlayback implements PronunciationPlayback {
  const _NoopPlayback();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play(Uint8List pcm16) async {}

  @override
  Future<void> stop() async {}
}
