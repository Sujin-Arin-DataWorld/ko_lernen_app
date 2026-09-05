import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/motion/transitions.dart';

/// §B1(2026-09-03) — 일반 라우트는 플랫폼 네이티브 전환([SoriTransitions.page]
/// / [SoriPageRoute])을 쓴다. `fadeScale`은 첫 실행(온보딩) 전용으로 남는다.
void main() {
  group('SoriTransitions.page', () {
    testWidgets('returns a MaterialPageRoute subtype', (tester) async {
      final route = SoriTransitions.page<void>((_) => const SizedBox());
      expect(route, isA<MaterialPageRoute<void>>());
      expect(route, isA<SoriPageRoute<void>>());
    });

    testWidgets('carries the settings it was given', (tester) async {
      const settings = RouteSettings(name: '/some/route');
      final route = SoriTransitions.page<void>(
        (_) => const SizedBox(),
        settings: settings,
      );
      expect(route.settings, settings);
    });
  });

  group('SoriPageRoute reduceMotion', () {
    // MaterialRouteTransitionMixin.transitionDuration reads the active
    // PageTransitionsTheme off `navigator!.context`, so the route must
    // actually be pushed before either getter can be read.
    testWidgets('collapses transition durations to zero when true', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
      );
      final route = SoriPageRoute<void>(
        builder: (_) => const SizedBox(),
        reduceMotion: true,
      );
      unawaited(navigatorKey.currentState!.push(route));
      await tester.pump();

      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
    });

    testWidgets('keeps the platform theme duration when false', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
      );
      final route = SoriPageRoute<void>(
        builder: (_) => const SizedBox(),
        reduceMotion: false,
      );
      unawaited(navigatorKey.currentState!.push(route));
      await tester.pump();

      expect(route.transitionDuration, isNot(Duration.zero));
      expect(route.reverseTransitionDuration, isNot(Duration.zero));
    });
  });

  group('static migration guards', () {
    test('lib/main.dart no longer calls SoriTransitions.fadeScale', () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source.contains('fadeScale('), isFalse);
    });

    test(
      'MaterialPageRoute construction is confined to dev-only screens',
      () {
        // 운영 화면은 전부 SoriTransitions.page로 옮겼다. 남는 건 dev 전용
        // 미리보기 하네스 3개뿐이다 — onboarding_level_screen.dart는
        // assets_unused/retired_code/로 격리되어 lib에서 사라졌다.
        const allowedFiles = <String>{
          'lib/screens/app_review_demo_screen.dart',
          'lib/screens/ux_preview_app.dart',
          'lib/screens/ux_preview_gallery_screen.dart',
        };
        final invocation = RegExp(r'MaterialPageRoute\s*(<[^>]*>)?\s*\(');
        final offenders = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) =>
                  invocation.hasMatch(file.readAsStringSync()),
            )
            .map(_relativePath)
            .toSet();

        expect(offenders, allowedFiles);
      },
    );

    test(
      'SoriTransitions.fadeScale is confined to first-run files',
      () {
        // consent/intro_gate/splash/onboarding_v2_journey는 firstRun 래퍼
        // (transitions.dart:58-73)를 쓰므로 여기 안 잡힌다.
        // onboarding_level_screen.dart·onboarding_start_screen.dart는
        // assets_unused/retired_code/로 격리되어 lib에서 사라졌으므로
        // 이 집합에서도 뺐다.
        const allowedFiles = <String>{
          'lib/motion/transitions.dart',
          'lib/services/onboarding_journey.dart',
          'lib/screens/character_selection_screen.dart',
          'lib/screens/first_voice_success_screen.dart',
          'lib/screens/onboarding_preview_screen.dart',
        };
        final invocation = RegExp(r'\bfadeScale\s*(<[^>]*>)?\s*\(');
        final offenders = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) => invocation.hasMatch(
                _blankStringsAndComments(file.readAsStringSync()),
              ),
            )
            .map(_relativePath)
            .toSet();

        expect(offenders, allowedFiles);
      },
    );
  });
}

String _relativePath(File file) {
  final path = file.path.replaceAll('\\', '/');
  return 'lib/${path.split('lib/').last}';
}

String _blankStringsAndComments(String source) {
  final output = source.split('');
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      final limit = end < 0 ? source.length : end;
      for (var cursor = index; cursor < limit; cursor++) {
        output[cursor] = ' ';
      }
      index = limit;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final end = source.indexOf('*/', index + 2);
      final limit = end < 0 ? source.length : end + 2;
      for (var cursor = index; cursor < limit; cursor++) {
        output[cursor] = ' ';
      }
      index = limit;
      continue;
    }
    final quote = source[index];
    if (quote == "'" || quote == '"') {
      var cursor = index + 1;
      while (cursor < source.length) {
        if (source[cursor] == r'\') {
          cursor += 2;
          continue;
        }
        if (source[cursor] == quote) {
          cursor++;
          break;
        }
        cursor++;
      }
      for (var blank = index; blank < cursor; blank++) {
        output[blank] = ' ';
      }
      index = cursor;
      continue;
    }
    index++;
  }
  return output.join();
}
