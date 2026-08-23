import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_play_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/scroll_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 재생 카드의 **기하 계약** (2026-08-23 P2).
///
/// 두루마리 짧은 카드 PNG 는 축 띠(위/아래)와 종이 여백(좌/우)이 그림에 구워져
/// 있다. 예전 코드는 인셋을 절대 dp 로 clamp 해서 카드가 커질수록 비례를 놓쳤고,
/// 글자가 축 위로/종이 밖으로 나갔다(진단 B2). 또 `FittedBox(scaleDown)` 이
/// 크기를 주도해 줄 길이마다 글자가 커졌다 작아졌다 했다(진단 B3).
///
/// 여기서 지키는 두 가지:
/// 1. 여러 줄로 접히는 한국어가 축 띠 rect 와 겹치지 않고 종이 좌우 안에 있다.
/// 2. 같은 덱의 서로 다른 두 카드에서 한국어 폰트 크기가 **같다**.
///
/// 픽셀 골든이 아니라 위젯 좌표 단언이라 Windows 로컬에서도 돈다.

/// 360dp 폭에서 확실히 여러 줄로 접히는 대사.
const String _kLongLine = '오늘 저녁에 친구들이랑 홍대에서 만나서 노래해요';

/// 같은 덱의 짧은 대사 — 폰트가 줄 길이에 반응하면 여기서 값이 달라진다.
const String _kShortLine = '네 좋아요';

Scenario _scenario() => Scenario(
  id: 'play_layout',
  level: LearnerLevel.a1,
  emoji: '📻',
  register: Register.polite,
  shelf: 'a1_friends',
  backdrop: 'home',
  title: const LocalizedText(ko: '약속', de: 'Verabredung', en: 'Meetup'),
  intro: const LocalizedText(ko: '', de: 'Intro', en: 'Intro'),
  vocab: const [],
  grammarIds: const [],
  dialog: const [
    DialogLine(speaker: 'jieun', ko: _kLongLine, de: 'de1', en: 'en1'),
    DialogLine(speaker: 'user', ko: _kShortLine, de: 'de2', en: 'en2'),
    DialogLine(speaker: 'jieun', ko: '그럼 이따 봐요', de: 'de3', en: 'en3'),
  ],
  quests: const [],
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

/// 실제로 몇 줄로 접혔는지 — 글자 상자의 서로 다른 y 개수로 센다.
/// (렌더 트리 좌표라 안전망 FittedBox 의 배율과 무관하다.)
int _lineCount(WidgetTester tester, Finder finder, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}

double _koFontSize(WidgetTester tester, String text) {
  final widget = tester.widget<Text>(find.text(text));
  final size = widget.style?.fontSize;
  expect(size, isNotNull, reason: '한국어 줄은 명시 폰트 크기를 받아야 한다');
  return size!;
}

void main() {
  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(360, 640);
    view.devicePixelRatio = 1;
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_listening_play': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('여러 줄 한국어가 축 띠를 안 밟고 종이 안에 머문다', (tester) async {
    await tester.pumpWidget(_app(ListeningPlayScreen(scenario: _scenario())));
    await tester.pump();

    final koFinder = find.text(_kLongLine);
    expect(koFinder, findsOneWidget);
    expect(
      _lineCount(tester, koFinder, _kLongLine),
      greaterThanOrEqualTo(3),
      reason: '이 대사는 360dp 종이 폭에서 최소 3줄로 접혀야 계약이 의미가 있다',
    );

    final card = tester.getRect(find.byType(SoriShortScrollCard));
    final rodTop = card.top + card.height * kScrollRodTopFraction;
    final rodBottom = card.bottom - card.height * kScrollRodBottomFraction;
    final paperLeft = card.left + card.width * kScrollPaperSideFraction;
    final paperRight = card.right - card.width * kScrollPaperSideFraction;

    final ko = tester.getRect(koFinder);
    const tolerance = 0.5;
    expect(
      ko.top,
      greaterThanOrEqualTo(rodTop - tolerance),
      reason: '위 축 띠와 겹쳤다',
    );
    expect(
      ko.bottom,
      lessThanOrEqualTo(rodBottom + tolerance),
      reason: '아래 축 띠와 겹쳤다',
    );
    expect(ko.left, greaterThanOrEqualTo(paperLeft - tolerance));
    expect(ko.right, lessThanOrEqualTo(paperRight + tolerance));

    // 카드 맨 아래 요소(재생 꼬리표)까지 축 띠 안쪽이어야 한다.
    final replay = tester.getRect(find.text('Wiederholen'));
    expect(replay.bottom, lessThanOrEqualTo(rodBottom + tolerance));
    expect(replay.left, greaterThanOrEqualTo(paperLeft - tolerance));
    expect(replay.right, lessThanOrEqualTo(paperRight + tolerance));

    // 카드는 화면 비율 고정이 아니라 콘텐츠가 정한다 — 옛 0.34 고정 흔적 배제.
    expect(card.height, greaterThanOrEqualTo(200.0 - tolerance));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('같은 덱의 두 카드는 한국어 폰트 크기가 같다', (tester) async {
    await tester.pumpWidget(_app(ListeningPlayScreen(scenario: _scenario())));
    await tester.pump();

    final first = _koFontSize(tester, _kLongLine);

    await tester.tap(find.text('Weiter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(_kShortLine), findsOneWidget);
    final second = _koFontSize(tester, _kShortLine);

    expect(second, first, reason: '줄 길이에 따라 글자가 요동치면 안 된다 (덱 공유 균일값)');
    await tester.pump(const Duration(milliseconds: 400));
  });
}
