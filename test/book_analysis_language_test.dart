import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/services/book_analysis_service.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

class _RecordingClient extends http.BaseClient {
  final Completer<Map<String, dynamic>> requestBody =
      Completer<Map<String, dynamic>>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    requestBody.complete(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          '{"words":[],"expressions":[],"grammar":[],"sentences":[],"warnings":["offline_stub"],"analysisLanguage":"en"}',
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets('book analysis failure never renders the raw exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: BookResultScreen(
          args: const {'text': '공부하고 있어요.'},
          analyzer: ({required text, required targetLang}) =>
              Future.error(StateError('private backend detail')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('private backend detail'), findsNothing);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('English BookResult sends normalized en through the service', (
    tester,
  ) async {
    final client = _RecordingClient();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: BookResultScreen(
          args: const {'text': '공부하고 있어요.'},
          analyzer: ({required text, required targetLang}) {
            return BookAnalysisService.analyze(
              text: text,
              targetLang: targetLang,
              client: client,
              credentialsProvider: () async => const BookAnalysisCredentials(
                idToken: 'test-id-token',
                appCheckToken: 'test-app-check-token',
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(await client.requestBody.future, {
      'text': '공부하고 있어요.',
      'lang': 'en',
      'analysisLanguage': 'en',
    });
  });

  testWidgets('rate-limited analysis explains when to retry', (tester) async {
    const rateLimited = BookAnalysisResult(
      words: [],
      grammar: [],
      sentences: [],
      warnings: ['offline_stub', 'server_rate_limited'],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: BookResultScreen(
          args: const {'text': 'test'},
          analyzer: ({required text, required targetLang}) async => rateLimited,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Cloud analysis limit reached. Please try again in a minute.'),
      findsOneWidget,
    );
  });

  testWidgets('every analyzed sentence keeps its companion question button', (
    tester,
  ) async {
    final sentences = List<TranslatedSentence>.generate(
      20,
      (index) => TranslatedSentence(
        korean: '검증 문장 ${index + 1}입니다.',
        translationDe: 'Verified sentence ${index + 1}.',
        translationLanguage: 'en',
        sourceUnitId: 'unit:$index',
      ),
    );
    final result = BookAnalysisResult(
      words: const <ExtractedWord>[],
      grammar: const <GrammarHit>[],
      sentences: sentences,
      warnings: const <String>[],
      analysisLanguage: 'en',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: BookResultScreen(
          args: const {'text': '검증 문장'},
          analyzer: ({required text, required targetLang}) async => result,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('검증 문장 20입니다.'), findsOneWidget);
    expect(find.byTooltip('Ask your companion'), findsNWidgets(20));
  });

  testWidgets('bookshelf save never persists unsupported or bidi OCR text', (
    tester,
  ) async {
    final result = BookAnalysisResult(
      words: [ExtractedWord.manual(korean: '안녕', translationDe: 'Hallo')],
      grammar: const [],
      sentences: const [],
      warnings: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: BookResultScreen(
          args: const {'text': '안녕مرحبا하세요\u202E'},
          analyzer: ({required text, required targetLang}) async => result,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final save = find.byWidgetPredicate(
      (widget) =>
          widget is SoriButton && widget.icon == Icons.bookmark_add_outlined,
    );
    tester.widget<SoriButton>(save).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final saved = BookshelfService.getAllLocal().single;
    expect(saved.extractedText, contains('안녕'));
    expect(saved.extractedText, isNot(contains('مرحبا')));
    expect(saved.extractedText, isNot(contains('\u202E')));
  });

  testWidgets(
    'two successful locale requests both consume quota and only newest renders',
    (tester) async {
      final locale = ValueNotifier<Locale>(const Locale('de'));
      final pending = <String, Completer<BookAnalysisResult>>{
        'de': Completer<BookAnalysisResult>(),
        'en': Completer<BookAnalysisResult>(),
      };
      BookAnalysisResult result(String marker) => BookAnalysisResult(
        words: [ExtractedWord.manual(korean: marker, translationDe: marker)],
        grammar: const [],
        sentences: const [],
        warnings: const [],
      );

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, child) => MaterialApp(
            locale: value,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: BookResultScreen(
              args: const {'text': '공부하고 있어요'},
              analyzer: ({required text, required targetLang}) =>
                  pending[targetLang]!.future,
            ),
          ),
        ),
      );
      await tester.pump();
      locale.value = const Locale('en');
      await tester.pump();

      pending['en']!.complete(result('NEWEST_EN'));
      pending['de']!.complete(result('STALE_DE'));
      await tester.pump();
      await tester.pump();

      expect(Storage.bookSnapCountToday(), 2);
      expect(find.text('NEWEST_EN'), findsWidgets);
      expect(find.text('STALE_DE'), findsNothing);
    },
  );

  test(
    'Dart offline grammar fallback is German for de and English for en',
    () async {
      final german = await BookAnalysisService.analyze(
        text: '공부하고 있어요.',
        targetLang: 'de',
      );
      final english = await BookAnalysisService.analyze(
        text: '공부하고 있어요.',
        targetLang: 'en-US',
      );

      expect(german.grammar, isNotEmpty);
      expect(german.grammar.first.nameDe, contains('Progressiv'));
      expect(german.grammar.first.explanationDe, contains('Handlung'));
      expect(english.grammar, isNotEmpty);
      expect(english.grammar.first.nameDe, 'Progressive aspect (-고 있다)');
      expect(
        english.grammar.first.explanationDe,
        contains('currently in progress'),
      );
      expect(english.grammar.first.explanationDe, isNot(contains('Handlung')));
    },
  );

  test(
    'unsupported or missing Dart target language safely defaults to German',
    () async {
      expect(BookAnalysisService.normalizeTargetLanguage(null), 'de');
      expect(BookAnalysisService.normalizeTargetLanguage(''), 'de');
      expect(BookAnalysisService.normalizeTargetLanguage('fr-FR'), 'de');
      expect(BookAnalysisService.normalizeTargetLanguage('EN_us'), 'en');
      expect(BookAnalysisService.normalizeTargetLanguage('de-AT'), 'de');
    },
  );
}
