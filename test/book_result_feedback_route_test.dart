import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/app_error.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/progress.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets(
    'a visible Book Result has one safe card and retry allocates a new completion',
    (tester) async {
      const sensitiveOcr = 'OCR_PRIVATE_TEXT_DO_NOT_TRANSMIT';
      const sensitiveImageLease = 'file:///private/camera/lease.jpg';
      final locale = ValueNotifier<Locale>(const Locale('en'));
      var analysisCalls = 0;

      final firstResult = _result(
        warnings: const ['offline_stub', 'server_rate_limited'],
      );
      final retryResult = _result(warnings: const ['server_rate_limited']);

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, child) => MaterialApp(
            locale: value,
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: ContentFeedbackControllerScope(
              featureGate: const TesterFeedbackFeatureGate(enabled: true),
              submitFeedback: (_, __) async =>
                  const ContentFeedbackSubmitResult(
                    status: ContentFeedbackSubmitStatus.accepted,
                  ),
              resumePending: () async => const ContentFeedbackResumeResult(),
              child: BookResultScreen(
                args: const {
                  'text': sensitiveOcr,
                  'imageLease': sensitiveImageLease,
                },
                analyzer: ({required text, required targetLang}) async {
                  switch (++analysisCalls) {
                    case 1:
                      return firstResult;
                    case 2:
                      throw StateError('retryable analysis failure');
                    case 3:
                      return retryResult;
                    default:
                      throw StateError('unexpected analysis call');
                  }
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ContentFeedbackCard), findsOneWidget);
      expect(find.byType(SoriProgressBar), findsNothing);
      final firstContext = tester
          .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
          .feedbackContext;
      expect(firstContext.contentType, 'book_analysis');
      expect(firstContext.contentId, 'book_analysis');
      expect(firstContext.contentLabel, 'book_analysis');
      expect(firstContext.completionId, isNotEmpty);
      expect(
        firstContext.scoreSummary,
        'words:4; grammar:1; sentences:2; source:offline',
      );
      expect(
        firstContext.toWire().values.whereType<String>(),
        isNot(contains(sensitiveOcr)),
      );
      expect(
        firstContext.toWire().values.whereType<String>(),
        isNot(contains(sensitiveImageLease)),
      );

      locale.value = const Locale('de');
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppError), findsOneWidget);
      expect(find.byType(ContentFeedbackCard), findsNothing);

      tester.widget<AppError>(find.byType(AppError)).onRetry!();
      await tester.pump();
      await tester.pump();

      expect(find.byType(ContentFeedbackCard), findsOneWidget);
      final retryContext = tester
          .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
          .feedbackContext;
      expect(retryContext.completionId, isNot(firstContext.completionId));
      expect(
        retryContext.scoreSummary,
        'words:4; grammar:1; sentences:2; source:rate_limited',
      );
    },
  );

  testWidgets('warnings-free Book Result records an online feedback source', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bookResultHost(
        featureGate: const TesterFeedbackFeatureGate(enabled: true),
        result: const BookAnalysisResult(
          words: [],
          grammar: [],
          sentences: [],
          warnings: [],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ContentFeedbackCard), findsOneWidget);
    expect(
      tester
          .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
          .feedbackContext
          .scoreSummary,
      'words:0; grammar:0; sentences:0; source:online',
    );
  });

  testWidgets(
    'disabled feedback gate leaves no Book feedback card or spacer before Save',
    (tester) async {
      await tester.pumpWidget(
        _bookResultHost(
          featureGate: const TesterFeedbackFeatureGate(enabled: false),
          result: const BookAnalysisResult(
            words: [],
            grammar: [],
            sentences: [],
            warnings: [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final saveFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SoriButton && widget.icon == Icons.bookmark_add_outlined,
      );
      final save = tester.widget<SoriButton>(saveFinder);
      final resultColumn = tester
          .widgetList<Column>(
            find.ancestor(of: saveFinder, matching: find.byType(Column)),
          )
          .singleWhere(
            (column) => column.children.any((child) => identical(child, save)),
          );
      final saveIndex = resultColumn.children.indexWhere(
        (child) => identical(child, save),
      );

      expect(
        <Object?>[
          find.byType(ContentFeedbackCard).evaluate().isNotEmpty,
          _sizedBoxHeight(resultColumn.children[saveIndex - 1]),
          _sizedBoxHeight(resultColumn.children[saveIndex - 2]),
        ],
        <Object?>[false, Spacing.md, Spacing.lg],
      );
    },
  );
}

Widget _bookResultHost({
  required TesterFeedbackFeatureGate featureGate,
  required BookAnalysisResult result,
}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  home: ContentFeedbackControllerScope(
    featureGate: featureGate,
    submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
      status: ContentFeedbackSubmitStatus.accepted,
    ),
    resumePending: () async => const ContentFeedbackResumeResult(),
    child: BookResultScreen(
      args: const {'text': 'fixture text'},
      analyzer: ({required text, required targetLang}) async => result,
    ),
  ),
);

double? _sizedBoxHeight(Widget widget) =>
    widget is SizedBox ? widget.height : null;

BookAnalysisResult _result({required List<String> warnings}) =>
    BookAnalysisResult(
      words: List<ExtractedWord>.generate(
        4,
        (index) => ExtractedWord.manual(
          korean: '단어$index',
          translationDe: 'Wort $index',
        ),
      ),
      grammar: const [
        GrammarHit(
          patternId: 'grammar',
          nameDe: 'Grammar',
          matchedText: '문법',
          level: 'A1',
          explanationDe: 'Explanation',
        ),
      ],
      sentences: const [
        TranslatedSentence(korean: '문장 하나', translationDe: 'Ein Satz.'),
        TranslatedSentence(korean: '문장 둘', translationDe: 'Zwei Sätze.'),
      ],
      warnings: warnings,
    );
