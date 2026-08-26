import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/content_share_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_share_recovery.dart';

Widget _app({
  required ContentStorySharer shareStory,
  required ContentTextCopier copyText,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => shareContentStoryWithRecovery(
          context: context,
          korean: '안녕하세요',
          gloss: 'Guten Tag',
          shareStory: shareStory,
          copyText: copyText,
        ),
        child: const Text('share'),
      ),
    ),
  ),
);

void main() {
  testWidgets('failed image share visibly offers text copy', (tester) async {
    String? copied;
    await tester.pumpWidget(
      _app(
        shareStory: ({required korean, required gloss}) async =>
            ShareOutcome.failed,
        copyText: (value) async => copied = value,
      ),
    );
    final t = AppL10n.of(tester.element(find.text('share')));

    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();

    expect(find.text(t.contentShareFailedTitle), findsOneWidget);
    expect(find.text(t.contentShareFailedBody), findsOneWidget);
    expect(find.text(t.contentShareRetry), findsOneWidget);
    expect(find.text(t.contentShareCopyText), findsOneWidget);

    await tester.tap(find.text(t.contentShareCopyText));
    await tester.pump();

    expect(copied, t.contentShareBody('안녕하세요', 'Guten Tag'));
    expect(find.text(t.contentShareCopied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry repeats image sharing and does not copy silently', (
    tester,
  ) async {
    var calls = 0;
    var copies = 0;
    await tester.pumpWidget(
      _app(
        shareStory: ({required korean, required gloss}) async {
          calls++;
          return calls == 1 ? ShareOutcome.failed : ShareOutcome.shared;
        },
        copyText: (value) async => copies++,
      ),
    );
    final t = AppL10n.of(tester.element(find.text('share')));

    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.contentShareRetry));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(copies, 0);
    expect(find.text(t.contentShareFailedTitle), findsNothing);
  });

  testWidgets('clipboard failure is visible instead of throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        shareStory: ({required korean, required gloss}) async =>
            ShareOutcome.failed,
        copyText: (value) => Future<void>.error(StateError('clipboard')),
      ),
    );
    final t = AppL10n.of(tester.element(find.text('share')));

    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.contentShareCopyText));
    await tester.pump();

    expect(find.text(t.contentShareCopyFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
