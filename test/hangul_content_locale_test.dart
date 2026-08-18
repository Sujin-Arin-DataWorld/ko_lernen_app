/// 한글 화면 학습 콘텐츠의 언어 계약 — 2026-08-18 신설.
///
/// 테스터(Amor, 2026-08-17): "EN 인터페이스인데 번역과 연상 힌트가 독일어로
/// 나온다." 원인은 데이터가 아니라 배선이었다 — `descriptionEn`/`exampleEn` 은
/// 50개 항목 전부 채워져 있었는데 화면이 `descriptionDe`/`exampleDe` 만 읽고
/// 있었고, EN 필드는 저장소 전체에서 **한 번도 읽히지 않는 데드 필드**였다.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/hangul_data.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

const _deDescription = "wie 'g' in Gabe (Anfang) / 'k' (Ende)";
const _enDescription = "like 'g' in good (start) / 'k' (end)";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_hangul': true});
    Storage.resetForTesting();
    await Storage.init();
  });

  group('데이터', () {
    test('자음·모음 34자 전부 영어 설명과 영어 예시 뜻이 있다', () {
      for (final c in [...consonants, ...vowels]) {
        expect(
          c.descriptionEn.trim(),
          isNotEmpty,
          reason: '${c.letter}: descriptionEn 이 비었다',
        );
        expect(
          c.descriptionDe.trim(),
          isNotEmpty,
          reason: '${c.letter}: descriptionDe 가 비었다',
        );
        if (c.exampleWord.isNotEmpty) {
          expect(
            c.exampleEn.trim(),
            isNotEmpty,
            reason: '${c.letter}: exampleEn 이 비었다',
          );
        }
      }
    });

    test('음절 16개도 영어 예시 뜻이 있다', () {
      for (final s in syllables) {
        if (s.exampleWord.isEmpty) {
          continue;
        }
        expect(s.exampleEn.trim(), isNotEmpty, reason: s.letter);
        expect(s.exampleFor('en'), s.exampleEn);
        expect(s.exampleFor('de'), s.exampleDe);
      }
    });

    test('접근자가 언어에 따라 갈린다', () {
      final g = consonants.firstWhere((c) => c.letter == 'ㄱ');
      expect(g.descriptionFor('en'), _enDescription);
      expect(g.descriptionFor('de'), _deDescription);
      expect(g.exampleFor('en'), 'bag');
      expect(g.exampleFor('de'), 'Tasche');
    });

    test('영어가 비면 독일어로 떨어진다 — 화면이 비지는 않는다', () {
      const fallback = HangulChar('ㅁ', 'm', 'deutsch', '', '문', 'Tür', '');
      expect(fallback.descriptionFor('en'), 'deutsch');
      expect(fallback.exampleFor('en'), 'Tür');
    });
  });

  test('한글 화면은 descriptionDe·exampleDe 를 직접 읽지 않는다', () {
    // 언어 분기를 건너뛴 직접 참조가 바로 이 버그의 형태였다.
    final source = File('lib/screens/hangul_screen.dart').readAsStringSync();
    for (final field in ['.descriptionDe', '.exampleDe']) {
      expect(
        source.contains(field),
        isFalse,
        reason: '$field 직접 참조 금지 — descriptionFor(lang)/exampleFor(lang) 사용',
      );
    }
  });

  testWidgets('EN 로케일에서는 영어 연상 설명만 보인다', (tester) async {
    await _pumpDetail(tester, const Locale('en'));
    expect(find.text(_enDescription), findsOneWidget);
    expect(find.text(_deDescription), findsNothing);
  });

  testWidgets('DE 로케일에서는 독일어 연상 설명만 보인다', (tester) async {
    await _pumpDetail(tester, const Locale('de'));
    expect(find.text(_deDescription), findsOneWidget);
    expect(find.text(_enDescription), findsNothing);
  });

  testWidgets('개요 탭 칩은 한국어 하드코딩이 아니다', (tester) async {
    await _pumpScreen(tester, const Locale('en'));
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Consonants'), findsWidgets);
    expect(find.text('자음'), findsNothing);
    expect(find.text('모음'), findsNothing);
    expect(find.text('음절'), findsNothing);
  });
}

Future<void> _pumpScreen(WidgetTester tester, Locale locale) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: HangulScreen(speechPlayer: (_) async => true),
    ),
  );
  await tester.pump();
}

Future<void> _pumpDetail(WidgetTester tester, Locale locale) async {
  await _pumpScreen(tester, locale);
  final target = find.byKey(const ValueKey('hangul-overview-ㄱ'));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
