import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import '../tool/visual_review/approved_word_chain_gallery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Lora': ['assets/fonts/Lora/Lora-Variable.ttf'],
      'MaruBuriOTF': [
        'assets/fonts/MaruBuri/MaruBuri-Regular.otf',
        'assets/fonts/MaruBuri/MaruBuri-SemiBold.otf',
        'assets/fonts/MaruBuri/MaruBuri-Bold.otf',
      ],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final asset in entry.value) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  });

  for (var f = 0; f < 3; f++) {
    testWidgets(
      'approved ${'ABC'[f]} keeps reference geometry and real Korean input',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(402, 874));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ApprovedWordChainGalleryApp(fixture: f, normalizeCapture: true),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(ApprovedGameNavigation)),
          const Rect.fromLTWH(0, 792, 402, 82),
        );
        final first = tester.getRect(
          find.byKey(const ValueKey('word-chain-syllable-0')),
        );
        final expected = [
          const Rect.fromLTWH(69, 311, 130, 118),
          const Rect.fromLTWH(35, 316, 108, 108),
          const Rect.fromLTWH(31.5, 324, 75, 92),
        ][f];
        expect(first.left, closeTo(expected.left, .1));
        expect(first.top, closeTo(expected.top, .1));
        expect(first.size, expected.size);
        final submit = tester.getRect(
          find.byKey(const ValueKey('word-chain-submit')),
        );
        expect(submit, const Rect.fromLTWH(28, 713, 346, 56));
        expect(792 - submit.bottom, greaterThanOrEqualTo(16));
        final input = tester.widget<TextField>(find.byType(TextField));
        expect(input.maxLength, 20);
        await tester.enterText(find.byType(TextField), '한국어');
        expect(input.controller!.text, '한국어');
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'approved ${'ABC'[f]} fits safe-area native height with full CTA gap',
      (tester) async {
        tester.view.devicePixelRatio = 2.75;
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.padding = const FakeViewPadding(top: 121, bottom: 99);
        tester.view.viewPadding = const FakeViewPadding(top: 121, bottom: 99);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await tester.pumpWidget(ApprovedWordChainGalleryApp(fixture: f));
        await tester.pumpAndSettle();
        final submit = tester.getRect(
          find.byKey(const ValueKey('word-chain-submit')),
        );
        final nav = tester.getRect(find.byType(ApprovedGameNavigation));
        expect(submit.height, greaterThanOrEqualTo(48));
        expect(submit.bottom + 16, lessThanOrEqualTo(nav.top + .1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  final cases = [
    ('천상열차분야지도', 'Acht Silben'),
    ('검사', 'Untersuchung; Kontrolle; Staatsanwalt/Staatsanwältin'),
    (
      '언니',
      'older sister (used by a female); form of address for an older woman',
    ),
    ('책임감', 'Verantwortungsbewusstsein'),
    ('강', ''),
    // Explicit input-boundary stress, not represented as a bundled real word.
    ('가' * 20, '20-character validation boundary'),
  ];
  for (final entry in cases) {
    testWidgets(
      '320px at 200% preserves ${entry.$1.characters.length} syllables and full gloss',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _host(
            ApprovedWordChainFixture(
              fixture: 0,
              word: entry.$1,
              meaning: entry.$2,
            ),
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < entry.$1.characters.length; i++) {
          final tile = find.byKey(ValueKey('word-chain-syllable-$i'));
          final rect = tester.getRect(tile);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        if (entry.$2.isNotEmpty) {
          final text = tester.widget<Text>(find.text(entry.$2));
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          expect(text.maxLines, isNull);
        }
        final submit = find.byKey(const ValueKey('word-chain-submit'));
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(submit).bottom + 16,
          lessThanOrEqualTo(
            tester.getRect(find.byType(ApprovedGameNavigation)).top + .1,
          ),
        );
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final speed in ['0.75×', '1.25×']) {
    testWidgets(
      '200% keeps the complete real $speed speed label inside its target',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _host(
            ApprovedWordChainFixture(fixture: 0, speedLabel: speed),
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        final label = find.text(speed);
        final button = find.ancestor(
          of: label,
          matching: find.byType(ApprovedArtButton),
        );
        expect(
          tester.getSize(label).height + 10,
          lessThanOrEqualTo(tester.getSize(button).height + .1),
        );
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'keyboard scroll exposes the editable input and submit together',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(402, 874));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(const ApprovedWordChainFixture(fixture: 1, autofocus: true)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '거울');
      await tester.pumpWidget(
        _host(
          const ApprovedWordChainFixture(fixture: 1, autofocus: true),
          keyboard: 300,
        ),
      );
      await tester.pumpAndSettle();
      final input = tester.getRect(find.byType(TextField));
      final submit = tester.getRect(
        find.byKey(const ValueKey('word-chain-submit')),
      );
      final nav = tester.getRect(find.byType(ApprovedGameNavigation));
      expect(input.top, greaterThanOrEqualTo(0));
      expect(submit.bottom, lessThanOrEqualTo(nav.top));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '거울',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(Widget child, {double scale = 1, double keyboard = 0}) =>
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: body!,
      ),
      home: child,
    );
