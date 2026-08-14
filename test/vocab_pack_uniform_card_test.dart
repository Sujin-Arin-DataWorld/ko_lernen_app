// 단어카드 타이포 균일성 + 예문 음성 (2026-08-14 Jin 리포트):
// ① 제시어 크기는 덱 공유값 하나 — 짧은 단어와 긴 단어의 **렌더된** 글자
//    높이(FittedBox 변환 포함)가 같아야 한다. FittedBox(scaleDown)가 현재
//    단어만 보고 줄이면 카드를 넘길 때마다 크기가 요동친다.
// ② 뒷면 예문은 탭해서 들을 수 있어야 한다 (SoriPressable + 스피커 아이콘).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';

Vocab _word(int n, String korean, {bool boss = false}) => Vocab(
  id: 'uc_v$n',
  korean: korean,
  romanization: 'r$n',
  german: 'UC-GER-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$korean 예문입니다.',
  exampleGerman: 'Beispielsatz $n.',
  topic: 'test',
  packId: 'a1_uc_1',
  packOrder: n,
  isReviewBoss: boss,
);

Future<AppL10n> _pump(WidgetTester tester, VocabPack pack) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => [pack],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  testWidgets('short and long words render the headline at the same size', (
    tester,
  ) async {
    // 폰 뷰포트 — 넓은 기본(800×600)에서는 긴 단어도 안 줄어들어 버그가
    // 재현되지 않는다. 실기기 제보 환경과 같은 좁은 폭으로 고정.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const short = '하나';
    const long = '지속가능성발전소';
    final pack = VocabPack(
      id: 'a1_uc_1',
      level: 'A1',
      words: [_word(1, short), _word(2, long), _word(3, '셋째', boss: true)],
    );
    await _pump(tester, pack);

    // 카드 1 (짧은 단어) — 렌더된 rect 는 FittedBox 변환까지 반영한다.
    final shortRect = tester.getRect(find.text(short));
    final shortSize = tester.widget<Text>(find.text(short)).style!.fontSize!;

    // 카드 2 (긴 단어)로 전진.
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final longRect = tester.getRect(find.text(long));
    final longSize = tester.widget<Text>(find.text(long)).style!.fontSize!;

    expect(
      longSize,
      shortSize,
      reason: '제시어 fontSize 는 덱 공유값 하나여야 한다 (단어 길이 무관)',
    );
    expect(
      longRect.height,
      closeTo(shortRect.height, 0.5),
      reason:
          '렌더된 글자 높이가 다르면 FittedBox 가 긴 단어를 몰래 줄인 것 — '
          '카드를 넘길 때마다 크기가 요동친다',
    );
    // 긴 단어도 카드 폭 안에 들어간다 (덱 최장 단어 기준 실측).
    expect(longRect.width, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deck-uniform size shrinks below the cap when a long word exists',
    (tester) async {
      // 순수 헬퍼 검증 — 짧은 덱은 cap, 긴 단어가 섞이면 cap 미만의 공유값.
      late double onlyShort;
      late double withLong;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              onlyShort = soriUniformFitSize(
                context,
                texts: const ['하나', '둘'],
                maxWidth: 400,
                cap: 96,
                min: 30,
              );
              withLong = soriUniformFitSize(
                context,
                texts: const ['하나', '지속가능성발전소에서'],
                maxWidth: 400,
                cap: 96,
                min: 30,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(onlyShort, 96);
      expect(withLong, lessThan(96));
      expect(withLong, greaterThanOrEqualTo(30));
    },
  );

  testWidgets('flipped back offers tappable example audio', (tester) async {
    final pack = VocabPack(
      id: 'a1_uc_1',
      level: 'A1',
      words: [_word(1, '하나'), _word(2, '둘째', boss: true)],
    );
    await _pump(tester, pack);

    // 뒤집기 전: 예문 없음 (앞면).
    expect(find.text('하나 예문입니다.'), findsNothing);

    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 뒷면: 예문 + 스피커 아이콘 + 탭/롱프레스 가능한 SoriPressable.
    expect(find.textContaining('하나 예문입니다.'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
    final pressable = tester.widget<SoriPressable>(
      find.byType(SoriPressable).first,
    );
    expect(pressable.onTap, isNotNull);
    expect(pressable.onLongPress, isNotNull);

    // 재생 호출이 예외 없이 동작한다 (TTS 는 테스트 환경에서 폴백 no-op).
    pressable.onTap!();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
