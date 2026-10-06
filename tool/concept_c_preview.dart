import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ko_lernen_app/models/companion_art.dart';
import 'package:ko_lernen_app/models/home_navigation_art.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_objects.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_diy_preview.dart';
import 'concept_c_onboarding_preview.dart';

/// Visual proof using native Flutter layers, not screenshot hotspots.
/// Real service bindings belong to SoriStageShell; this entry never mutates data.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  // Explicit gallery-only example; the default remains the unjoined state.
  if (Uri.base.queryParameters['view'] == 'einleitung') {
    runApp(const COnboardingPreviewApp());
    return;
  }
  runApp(
    CPreviewApp(
      group: Uri.base.queryParameters['group'] == 'joined_example'
          ? const CGroupSnapshot(
              name: 'Unser Dienstag',
              memberCount: 7,
              litLanterns: 1,
              totalLanterns: 3,
            )
          : null,
    ),
  );
}

class CPreviewApp extends StatelessWidget {
  const CPreviewApp({super.key, this.group, this.savedPacks = const []});
  final CGroupSnapshot? group;
  final List<CGamePackSnapshot> savedPacks;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    scrollBehavior: const CPreviewScrollBehavior(),
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Paperlogy',
      scaffoldBackgroundColor: CPalette.jade,
      colorScheme: ColorScheme.fromSeed(seedColor: CPalette.jade),
    ),
    builder: (context, child) {
      final scale = double.tryParse(Uri.base.queryParameters['scale'] ?? '');
      final motion = Uri.base.queryParameters['reduce'];
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: scale == null ? null : TextScaler.linear(scale),
          disableAnimations: motion == null ? null : motion == '1',
        ),
        child: child!,
      );
    },
    home: Material(
      color: CPalette.deepJade,
      child: CPreviewSpaces(group: group, savedPacks: savedPacks),
    ),
  );
}

/// The browser mock supports the same vertical gesture as a phone, including a
/// mouse drag inside the scaled gallery frame. Wheel and trackpad remain native.
class CPreviewScrollBehavior extends MaterialScrollBehavior {
  const CPreviewScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}

/// A confirmed group projection, supplied by the real service at integration.
/// Null in this independent preview means the deliberately selected unjoined view.
class CGroupSnapshot {
  const CGroupSnapshot({
    required this.name,
    required this.memberCount,
    required this.litLanterns,
    required this.totalLanterns,
  }) : assert(memberCount >= 0),
       assert(totalLanterns > 0),
       assert(litLanterns >= 0 && litLanterns <= totalLanterns);
  final String name;
  final int memberCount;
  final int litLanterns;
  final int totalLanterns;
}

class CPreviewSpaces extends StatefulWidget {
  const CPreviewSpaces({super.key, this.group, this.savedPacks = const []});
  final CGroupSnapshot? group;
  final List<CGamePackSnapshot> savedPacks;
  @override
  State<CPreviewSpaces> createState() => _CPreviewSpacesState();
}

class _CPreviewSpacesState extends State<CPreviewSpaces> {
  final controllers = List.generate(5, (_) => ScrollController());
  late int selected = (int.tryParse(Uri.base.queryParameters['tab'] ?? '') ?? 0)
      .clamp(0, 4);
  bool english = Uri.base.queryParameters['lang'] == 'en';
  String? detail;
  String? action;
  String level = 'A2';
  bool flipped = false;
  String? choice;
  bool showAll = false;
  String? selectedPackId;

  String text(String de, String en) => english ? en : de;
  static const names = ['Heute', 'Lernen', 'Spiele', 'Hanok', 'Gye'];
  static const images = [
    HomeNavigationArt.today,
    HomeNavigationArt.learn,
    HomeNavigationArt.games,
    HomeNavigationArt.hanok,
    HomeNavigationArt.gye,
  ];

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void open(String id, String title) => setState(() {
    action = id;
    detail = title;
    choice = null;
    flipped = false;
  });
  Widget picture(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) => Image.asset(
    path,
    width: width,
    height: height,
    fit: fit,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
  Widget label(
    String value, {
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = CPalette.ink,
  }) => Text(
    value,
    style: TextStyle(
      fontFamily: RegExp('[가-힣ㄱ-ㅎㅏ-ㅣ]').hasMatch(value)
          ? 'NotoSansKR'
          : 'Paperlogy',
      fontSize: size,
      fontWeight: weight,
      height: 1.3,
      color: color,
      shadows: color == CPalette.paper
          ? const [Shadow(color: Color(0x66051914), offset: Offset(0, 1.2))]
          : null,
    ),
  );
  Widget gap([double height = 12]) => SizedBox(height: height);

  Widget button(String de, String en, String id, {bool gold = true}) =>
      CMaterialAction(
        label: text(de, en),
        gold: gold,
        onTap: () => open(id, text(de, en)),
      );

  Widget chrome({required int tab}) {
    final today = tab == 0;
    final largeType = MediaQuery.textScalerOf(context).scale(25) > 32.5;
    final title = [
      text('Heute', 'Today'),
      text('Dein Lernweg', 'Your learning path'),
      text('Spiele', 'Games'),
      text('Dein Hanok', 'Your Hanok'),
      text('Gemeinsam\nlernen', 'Learn\ntogether'),
    ][tab];
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: today ? (largeType ? 280 : 180) : (tab == 4 ? 141 : 118),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (today)
            Positioned(
              right: 2,
              bottom: -2,
              height: 142,
              width: 164,
              child: picture(CompanionArt.taegoPortrait),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              6,
              12,
              today && largeType ? 146 : 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 30,
                      height: 28,
                      child: CObjectArt(CObject.cloud),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: const CBrandWordmark()),
                    CImageTap(
                      label: text(
                        '80 Yeopjeon · Guthaben',
                        '80 Yeopjeon · balance',
                      ),
                      onTap: () =>
                          open('wallet', text('Dein Guthaben', 'Your balance')),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.fromLTRB(2, 2, 11, 2),
                            decoration: BoxDecoration(
                              color: CPalette.deepJade,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: CPalette.brass,
                                width: .8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CObjectArt(CObject.coin, size: 28),
                                ),
                                const SizedBox(width: 6),
                                label('80', color: CPalette.paper, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    CImageTap(
                      label: text('Einstellungen', 'Settings'),
                      onTap: () =>
                          open('settings', text('Einstellungen', 'Settings')),
                      child: const SizedBox.square(
                        dimension: 48,
                        child: Center(child: CSettingsCog()),
                      ),
                    ),
                  ],
                ),
                gap(4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: label(
                        title,
                        size: today ? 32 : 30,
                        weight: FontWeight.w700,
                        color: CPalette.paper,
                      ),
                    ),
                    if (tab == 1)
                      SizedBox(
                        width: 86,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 7,
                              bottom: 7,
                              child: CPaperPanel(
                                raised: false,
                                radius: 11,
                                padding: EdgeInsets.zero,
                                child: SizedBox.expand(),
                              ),
                            ),
                            DropdownButton<String>(
                              value: level,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(14),
                              dropdownColor: CPalette.paper,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              underline: const SizedBox(),
                              icon: const CArrow(
                                down: true,
                                dark: true,
                                size: 14,
                              ),
                              items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                                  .map(
                                    (x) => DropdownMenuItem(
                                      value: x,
                                      child: label(
                                        x,
                                        size: 17,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => level = v);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget board(Widget child, {EdgeInsets padding = const EdgeInsets.all(12)}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CPaperPanel(radius: 18, padding: padding, child: child),
      );

  Widget today() => Column(
    children: [
      chrome(tab: 0),
      board(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              key: const ValueKey('c-next-step'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: label(
                        text('DEIN NÄCHSTER SCHRITT', 'YOUR NEXT STEP'),
                        size: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffeee0cc),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CPalette.fineEdge),
                      ),
                      child: label('$level · 5 Min.', size: 13),
                    ),
                  ],
                ),
                gap(5),
                label(
                  text('Auf einen Kaffee', 'Coffee with a friend'),
                  size: 27,
                  weight: FontWeight.w700,
                ),
                gap(4),
                label(
                  text('Ein Treffen vereinbaren.', 'Arrange to meet.'),
                  size: 16,
                ),
                gap(9),
                const CSceneArt(CScene.coffee, height: 170),
                gap(6),
                button('Weiterlernen', 'Continue learning', 'course_mission'),
              ],
            ),
            gap(14),
            CPaperPanel(
              raised: false,
              radius: 10,
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: picture(
                      HomeNavigationArt.treasureChest,
                      height: 128,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label(
                          text('Schatztruhe', 'Treasure chest'),
                          size: 18,
                          weight: FontWeight.w700,
                        ),
                        gap(3),
                        label(
                          text('1 Fund wartet.', '1 find is waiting.'),
                          size: 14,
                        ),
                        gap(9),
                        button('Öffnen', 'Open', 'chest', gold: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gap(12),
            CImageTap(
              label: text('Dein Hanok ansehen', 'View your Hanok'),
              onTap: () => open('hanok', text('Dein Hanok', 'Your Hanok')),
              child: CPaperPanel(
                raised: false,
                radius: 10,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Row(
                        children: [
                          Expanded(
                            child: label(
                              text('Dein Hanok', 'Your Hanok'),
                              size: 17,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const CArrow(dark: true, size: 18),
                        ],
                      ),
                    ),
                    const CHanokScene(key: ValueKey('c-today-hanok-scene')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget learn() => Column(
    children: [
      chrome(tab: 1),
      board(
        Column(
          children: [
            Stack(
              children: [
                const Positioned(
                  top: 22,
                  left: 18,
                  right: 44,
                  child: Divider(
                    height: 1,
                    color: CPalette.fineEdge,
                    thickness: 2,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 20 : 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CWaxSeal(number: i + 1, active: i == 0),
                            gap(6),
                            label(
                              [
                                text(
                                  'Auf einen\nKaffee',
                                  'Coffee with\na friend',
                                ),
                                text('Hören', 'Listen'),
                                text('Antworten', 'Respond'),
                              ][i],
                              size: 14,
                              weight: i == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            gap(9),
            const CSceneArt(CScene.book, height: 165),
            gap(10),
            Row(
              children: [
                Expanded(
                  child: learningTile(
                    text('Wörter', 'Words'),
                    CReferencePart.words,
                    'vocab_packs',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: learningTile(
                    text('Hören', 'Listening'),
                    CReferencePart.listening,
                    'listening',
                  ),
                ),
              ],
            ),
            gap(10),
            Row(
              children: [
                Expanded(
                  child: learningTile(
                    'Hangeul',
                    CReferencePart.hangul,
                    'hangul',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: learningTile(
                    text('Wiederholen', 'Review'),
                    CReferencePart.review,
                    'srs',
                  ),
                ),
              ],
            ),
            gap(12),
            button(
              'Lernweg öffnen',
              'Open learning path',
              'course_mission',
              gold: false,
            ),
            gap(10),
            CImageTap(
              label: text('Alle 13 Lernangebote', 'All 13 learning activities'),
              onTap: () => open(
                'learning_catalog',
                text('Alle Lernangebote', 'All learning activities'),
              ),
              child: CPaperPanel(
                raised: false,
                radius: 8,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: label(
                            text(
                              'Alle Lernangebote',
                              'All learning activities',
                            ),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                        height: 20,
                        child: CArrow(dark: true, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget learningTile(String title, CReferencePart art, String id) => CImageTap(
    label: title,
    onTap: () => open(id, title),
    child: CPaperPanel(
      raised: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      radius: 10,
      child: Column(
        children: [
          SizedBox(
            height: 103,
            width: double.infinity,
            child: CReferenceArt(art),
          ),
          gap(4),
          label(title, size: 16, weight: FontWeight.w700),
        ],
      ),
    ),
  );

  Widget gameTile(String de, String en, String id, Widget art) => CImageTap(
    label: text(de, en),
    onTap: () => open(id, text(de, en)),
    child: CPaperPanel(
      raised: false,
      padding: const EdgeInsets.fromLTRB(5, 6, 5, 9),
      radius: 10,
      child: Column(
        children: [
          SizedBox(height: 89, width: double.infinity, child: art),
          gap(4),
          Text(
            text(de, en),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Paperlogy',
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: CPalette.ink,
            ),
          ),
        ],
      ),
    ),
  );

  Widget gamesHero() => LayoutBuilder(
    builder: (context, constraints) {
      final titleOutside = MediaQuery.textScalerOf(context).scale(25) > 32.5;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                const AspectRatio(
                  aspectRatio: CGameReferenceArt.heroAspectRatio,
                  child: CGameReferenceArt(CGameReferencePart.hero),
                ),
                if (!titleOutside)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * .74,
                      ),
                      padding: const EdgeInsets.fromLTRB(7, 3, 9, 1),
                      decoration: const BoxDecoration(
                        color: CPalette.paper,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: label(
                        text('Silben-Rätsel', 'Syllable puzzle'),
                        size: 25,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (titleOutside) ...[
            gap(6),
            label(
              text('Silben-Rätsel', 'Syllable puzzle'),
              size: 25,
              weight: FontWeight.w700,
            ),
          ],
        ],
      );
    },
  );

  Widget games() => Column(
    children: [
      chrome(tab: 2),
      board(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            gamesHero(),
            gap(4),
            label(
              text('Bedeutungen verbinden.', 'Connect meanings.'),
              size: 15,
            ),
            gap(9),
            button(
              'Spiel ansehen',
              'See the game',
              'syllable_cross',
              gold: false,
            ),
            gap(14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: gameTile(
                    'Anlaute',
                    'First sounds',
                    'chosung',
                    const CGameReferenceArt(CGameReferencePart.firstSounds),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: gameTile(
                    'Lückentext',
                    'Cloze',
                    'cloze',
                    const CGameReferenceArt(CGameReferencePart.cloze),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: gameTile(
                    'Blitz-Paare',
                    'Speed Match',
                    'speed_match',
                    const CGameReferenceArt(CGameReferencePart.pairs),
                  ),
                ),
              ],
            ),
            gap(10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: gameTile(
                    'Satzbau',
                    'Sentences',
                    'sentence_arcade',
                    const CGameReferenceArt(CGameReferencePart.sentence),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: gameTile(
                    'Wortkette',
                    'Word chain',
                    'kkeunmari',
                    const CGameReferenceArt(CGameReferencePart.wordChain),
                  ),
                ),
              ],
            ),
            gap(12),
            CImageTap(
              label: text('Eigene Wörter · DIY-Spiel', 'Your words · DIY game'),
              onTap: () =>
                  open('custom_practice', text('Eigene Wörter', 'Your words')),
              child: CPaperPanel(
                raised: false,
                radius: 10,
                padding: const EdgeInsets.all(9),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 96,
                      height: 76,
                      child: CGameReferenceArt(CGameReferencePart.yourWords),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label(
                            text('Eigene Wörter', 'Your words'),
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                          gap(3),
                          label(
                            text(
                              'Deine Sammlung wird zum Spiel.',
                              'Your collection becomes a game.',
                            ),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                    const CArrow(dark: true, size: 18),
                  ],
                ),
              ),
            ),
            gap(12),
            CImageTap(
              label: text('Tageschallenge ansehen', 'View daily challenge'),
              onTap: () =>
                  open('daily_game', text('Tageschallenge', 'Daily challenge')),
              child: CPaperPanel(
                raised: false,
                radius: 10,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const CGameObject(0, size: 43),
                    const SizedBox(width: 10),
                    Expanded(
                      child: label(
                        text('Tageschallenge', 'Daily challenge'),
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const CArrow(dark: true, size: 17),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget hanok() => Column(
    children: [
      chrome(tab: 3),
      board(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CHanokScene(key: ValueKey('c-hanok-scene')),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CPaperPanel(
                    raised: false,
                    radius: 12,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label(
                          text('Dein Baufortschritt', 'Your building progress'),
                          size: 17,
                          weight: FontWeight.w600,
                        ),
                        gap(10),
                        Stack(
                          children: [
                            Positioned(
                              top: 15,
                              left: 14,
                              right: 14,
                              child: Container(
                                height: 1.4,
                                color: CPalette.fineEdge,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                5,
                                (i) => CWaxSeal(active: i == 0, size: 30),
                              ),
                            ),
                          ],
                        ),
                        gap(10),
                        CPaperPanel(
                          raised: false,
                          radius: 9,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              const CObjectArt(CObject.coin, size: 36),
                              const SizedBox(width: 10),
                              Expanded(
                                child: label(
                                  '80 Yeopjeon',
                                  size: 17,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        gap(11),
                        button(
                          'Bauphase ansehen',
                          'View build phase',
                          'construction',
                        ),
                      ],
                    ),
                  ),
                  gap(12),
                  CPaperPanel(
                    raised: false,
                    radius: 12,
                    padding: const EdgeInsets.all(9),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: picture(
                            'assets/illustrations/concept_c/dancheong_preview_v3.png',
                            height: 104,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(
                                text('Dancheong-Atelier', 'Dancheong Studio'),
                                size: 17,
                                weight: FontWeight.w600,
                              ),
                              gap(5),
                              label(
                                text(
                                  'Muster · eigene Werke',
                                  'Patterns · your artwork',
                                ),
                                size: 14,
                              ),
                              gap(8),
                              button('Öffnen', 'Open', 'studio', gold: false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap(11),
                  CImageTap(
                    label: text('Stempelbuch öffnen', 'Open stamp book'),
                    onTap: () =>
                        open('stamps', text('Stempelbuch', 'Stamp book')),
                    child: CPaperPanel(
                      raised: false,
                      radius: 10,
                      padding: const EdgeInsets.all(7),
                      child: Row(
                        children: [
                          const CObjectArt(CObject.stampbook, size: 62),
                          const SizedBox(width: 9),
                          Expanded(
                            child: label(
                              text('Stempelbuch', 'Stamp book'),
                              size: 18,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const CArrow(dark: true, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        padding: EdgeInsets.zero,
      ),
    ],
  );

  Widget groupSecondary(String de, String en, String id) => CImageTap(
    label: text(de, en),
    onTap: () => open(id, text(de, en)),
    child: CPaperPanel(
      raised: false,
      radius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 42),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text(de, en),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CPalette.ink,
                ),
              ),
            ),
            const CArrow(dark: true, size: 17),
          ],
        ),
      ),
    ),
  );

  Widget gye() {
    final group = widget.group;
    return Column(
      children: [
        chrome(tab: 4),
        board(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CSceneArt(CScene.studyTogether, height: 285, radius: 0),
              const SizedBox(
                height: 18,
                child: CTexture(CMaterial.oak, opacity: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label(
                      group?.name ??
                          text('Deine Lerngruppe', 'Your learning group'),
                      size: 25,
                      weight: FontWeight.w700,
                    ),
                    gap(4),
                    if (group != null)
                      label(
                        text(
                          '${group.memberCount} Mitglieder',
                          '${group.memberCount} members',
                        ),
                        size: 15,
                      )
                    else
                      label(
                        text(
                          'Finde eine Gruppe oder gründe deine eigene.',
                          'Find a group or start your own.',
                        ),
                        size: 15,
                      ),
                    gap(12),
                    CPaperPanel(
                      raised: false,
                      radius: 10,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label(
                            text('Diese Woche', 'This week'),
                            size: 15,
                            weight: FontWeight.w600,
                          ),
                          gap(5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              group?.totalLanterns ?? 3,
                              (i) => Flexible(
                                child: CLantern(
                                  lit: group != null && i < group.litLanterns,
                                ),
                              ),
                            ),
                          ),
                          gap(6),
                          Text(
                            group == null
                                ? text(
                                    'Ein gemeinsames Ziel lässt eure Laternen leuchten.',
                                    'A shared goal lights your lanterns.',
                                  )
                                : text(
                                    '${group.litLanterns} von ${group.totalLanterns} Laternen',
                                    '${group.litLanterns} of ${group.totalLanterns} lanterns',
                                  ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 15,
                              height: 1.25,
                              color: CPalette.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    gap(13),
                    if (group != null) ...[
                      button(
                        'Gruppe öffnen',
                        'Open group',
                        'group',
                        gold: false,
                      ),
                      gap(10),
                      groupSecondary(
                        'Gruppe finden',
                        'Find a group',
                        'group_join',
                      ),
                      gap(10),
                      groupSecondary(
                        'Gruppe erstellen',
                        'Create group',
                        'group_create',
                      ),
                    ] else ...[
                      button(
                        'Gruppe finden',
                        'Find a group',
                        'group_join',
                        gold: false,
                      ),
                      gap(10),
                      groupSecondary(
                        'Gruppe erstellen',
                        'Create group',
                        'group_create',
                      ),
                      gap(10),
                      groupSecondary(
                        'Gye kennenlernen',
                        'Discover Gye',
                        'group_intro',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget bottomShelf() => Container(
    decoration: const BoxDecoration(
      color: CPalette.paper,
      border: Border(top: BorderSide(color: CPalette.fineEdge)),
      boxShadow: [
        BoxShadow(
          color: Color(0x66162d23),
          offset: Offset(0, -3),
          blurRadius: 9,
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
        child: Row(
          children: List.generate(
            5,
            (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CImageTap(
                  label: text(
                    names[i],
                    ['Today', 'Learn', 'Games', 'Hanok', 'Gye'][i],
                  ),
                  selected: selected == i,
                  onTap: () => setState(() {
                    selected = i;
                    detail = null;
                    action = null;
                  }),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected == i ? CPalette.jade : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: selected == i
                          ? Border.all(color: CPalette.brass, width: 1.3)
                          : null,
                      boxShadow: selected == i
                          ? const [
                              BoxShadow(
                                color: Color(0x6615352c),
                                offset: Offset(0, 3),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: picture(
                        images[i],
                        height: [1, 3, 4].contains(i) ? 44 : 40,
                        width: [1, 3, 4].contains(i) ? 44 : 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget detailPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CImageTap(
              label: text('Zurück', 'Back'),
              onTap: () => setState(() => detail = null),
              child: SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: label(
                    text('Zurück', 'Back'),
                    color: CPalette.paper,
                    size: 14,
                  ),
                ),
              ),
            ),
            gap(8),
            label(
              detail!,
              size: 26,
              weight: FontWeight.w700,
              color: CPalette.paper,
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CPaperPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (action == 'learning_catalog')
                ...learningRows()
              else if (action == 'custom_practice')
                CDiyPackChooser(
                  packs: widget.savedPacks,
                  english: english,
                  onCollect: () =>
                      open('my_words', text('Meine Wörter', 'My words')),
                  onPlay: (packId, mode) {
                    selectedPackId = packId;
                    open('diy_$mode', text('Eigene Spiele', 'My games'));
                  },
                )
              else if (action?.startsWith('diy_') ?? false) ...[
                picture(
                  'assets/illustrations/concept_c/diy_pieces.png',
                  height: 180,
                ),
                gap(14),
                label(
                  widget.savedPacks
                          .where((p) => p.id == selectedPackId)
                          .firstOrNull
                          ?.title ??
                      '',
                  size: 24,
                  weight: FontWeight.w700,
                ),
                gap(14),
                button(
                  'Spiel wechseln',
                  'Choose another game',
                  'custom_practice',
                  gold: false,
                ),
              ] else if (action == 'my_words') ...[
                const CSceneArt(CScene.book, height: 190),
                gap(),
                label(
                  text(
                    'Wörter für dein eigenes Spiel',
                    'Words for your own game',
                  ),
                  size: 24,
                  weight: FontWeight.w700,
                ),
                gap(8),
                label(
                  text(
                    'Speichere Wörter aus einer Lektion, einem Buch oder einem Gespräch.',
                    'Save words from a lesson, a book or a conversation.',
                  ),
                ),
                gap(18),
                button(
                  'Lernangebote öffnen',
                  'Open learning activities',
                  'learning_catalog',
                  gold: false,
                ),
              ] else if (action == 'group_intro') ...[
                const CSceneArt(CScene.studyTogether, height: 245),
                gap(14),
                label(
                  text(
                    'Ein Ziel. Gemeinsam lernen.',
                    'One goal. Learn together.',
                  ),
                  size: 24,
                  weight: FontWeight.w700,
                ),
                gap(8),
                label(
                  text(
                    'In eurer Gye macht ihr eine Lernzusage für die Woche. Jede erfüllte Zusage lässt eine Laterne leuchten.',
                    'Your Gye shares a weekly learning promise. Each fulfilled promise lights a lantern.',
                  ),
                ),
                gap(18),
                button(
                  'Gruppe finden',
                  'Find a group',
                  'group_join',
                  gold: false,
                ),
                gap(10),
                groupSecondary(
                  'Gruppe erstellen',
                  'Create group',
                  'group_create',
                ),
              ] else if (action == 'syllable_cross') ...[
                gamesHero(),
                gap(),
                label(
                  text(
                    'Lege die passende Silbe.',
                    'Place the matching syllable.',
                  ),
                  weight: FontWeight.w700,
                ),
                gap(),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['호', '텔', '변', '사', '상']
                      .map(
                        (x) => CMaterialAction(
                          label: x,
                          onTap: () => setState(() => choice = x),
                          selected: choice == x,
                          gold: choice == x,
                          compact: true,
                        ),
                      )
                      .toList(),
                ),
                gap(),
                label(
                  choice ?? text('Wähle einen Stein.', 'Choose a tile.'),
                  size: 20,
                ),
                gap(),
                button('Prüfen', 'Check', 'result'),
              ] else if (action == 'kkeunmari') ...[
                const SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CGameReferenceArt(CGameReferencePart.wordChain),
                ),
                gap(14),
                label('끝말잇기', size: 26, weight: FontWeight.w700),
                gap(8),
                label(
                  text(
                    'Das nächste Wort beginnt mit der letzten Silbe.',
                    'The next word begins with the last syllable.',
                  ),
                ),
                gap(12),
                label('사과 → 과자', size: 25),
              ] else if (action == 'vocab_packs' || action == 'srs') ...[
                const CSceneArt(CScene.book, height: 180),
                gap(20),
                CImageTap(
                  label: text('Wortkarte umdrehen', 'Turn word card'),
                  onTap: () => setState(() => flipped = !flipped),
                  child: CPaperPanel(
                    child: SizedBox(
                      height: 170,
                      child: Center(
                        child: label(
                          flipped ? text('Frühling', 'Spring') : '봄',
                          size: 38,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                gap(14),
                Row(
                  children: [
                    Expanded(
                      child: button('Gewusst', 'Known', 'result', gold: false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: button(
                        'Noch nicht',
                        'Not yet',
                        'result',
                        gold: false,
                      ),
                    ),
                  ],
                ),
              ] else if (action == 'wallet') ...[
                const CObjectArt(CObject.coin, size: 150),
                label('80 Yeopjeon', size: 30, weight: FontWeight.w700),
                gap(),
                button('Hanok ansehen', 'View Hanok', 'hanok', gold: false),
              ] else if (action == 'chest') ...[
                picture(HomeNavigationArt.treasureChest, height: 245),
                gap(),
                label(
                  text('Deine Schatztruhe', 'Your treasure chest'),
                  size: 24,
                  weight: FontWeight.w700,
                ),
                gap(),
                button('Fund ansehen', 'View find', 'chest_receipt'),
              ] else if (action == 'settings') ...[
                const CObjectArt(CObject.settings, size: 110),
                gap(),
                SwitchListTile(
                  title: label(text('English', 'Deutsch')),
                  value: english,
                  onChanged: (v) => setState(() => english = v),
                ),
                button('Dein Profil', 'Your profile', 'profile', gold: false),
              ] else if (action == 'group_join' ||
                  action == 'group_create') ...[
                const CSceneArt(CScene.studyTogether, height: 220),
                gap(),
                TextField(
                  decoration: InputDecoration(
                    labelText: text('Dein Spitzname', 'Your nickname'),
                  ),
                ),
                gap(),
                TextField(
                  decoration: InputDecoration(
                    labelText: action == 'group_join'
                        ? text('Gruppencode', 'Group code')
                        : text('Name der Gruppe', 'Group name'),
                  ),
                ),
                gap(),
                button('Auswahl prüfen', 'Review choice', 'group', gold: false),
              ] else if (action == 'hanok' || action == 'construction') ...[
                const CHanokScene(),
                gap(),
                button(
                  'Zur Übersicht',
                  'Back to overview',
                  'hanok',
                  gold: false,
                ),
              ] else if (action == 'group') ...[
                const CSceneArt(CScene.studyTogether, height: 270),
                gap(),
                label(
                  text('Unsere Lerngruppe', 'Our learning group'),
                  size: 24,
                  weight: FontWeight.w700,
                ),
                gap(),
                button(
                  'Unser Wochenziel',
                  'Our weekly promise',
                  'group_promise',
                  gold: false,
                ),
              ] else ...[
                CSceneArt(
                  selected == 2 ? CScene.syllables : CScene.book,
                  height: 220,
                ),
                gap(),
                label(
                  text('Dein nächster Lernschritt', 'Your next learning step'),
                  size: 22,
                  weight: FontWeight.w700,
                ),
                gap(),
                label(
                  text(
                    'Die genaue Lernansicht wird mit derselben C-Oberfläche gestaltet.',
                    'The exact learning view will use this same C material system.',
                  ),
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
      gap(20),
    ],
  );

  List<Widget> learningRows() {
    final items = [
      ['course', 'Lernweg', 'Learning path'],
      ['hangul', 'Hangul', 'Hangul'],
      ['calligraphy', 'Buchstabe des Tages', 'Character of the day'],
      ['pronunciation', 'Aussprache', 'Pronunciation'],
      ['vocab_packs', 'Wortpakete', 'Vocabulary packs'],
      ['srs', 'Wiederholen', 'Review'],
      ['my_words', 'Meine Wörter', 'My words'],
      ['grammar', 'Grammatik', 'Grammar'],
      ['book_capture', 'Buch fotografieren', 'Scan a book'],
      ['listening', 'Hören', 'Listening'],
      ['scenarios', 'Alltagsszenen', 'Real-life scenarios'],
      ['smalltalk', 'Small Talk', 'Small Talk'],
      ['word_web', 'Nuancen & Gegenteile', 'Nuances & opposites'],
    ];
    return items
        .expand((x) => [button(x[1], x[2], x[0], gold: false), gap(12)])
        .toList();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: SizedBox(
        width: constraints.maxWidth > 600 ? 390 : constraints.maxWidth,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: CPalette.paper,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: CPalette.deepJade),
              ),
              const Positioned.fill(
                child: CTexture(CMaterial.jade, opacity: .45),
              ),
              Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      top: !kIsWeb,
                      child: detail != null
                          ? SingleChildScrollView(child: detailPage())
                          : IndexedStack(
                              index: selected,
                              children: [today, learn, games, hanok, gye]
                                  .asMap()
                                  .entries
                                  .map(
                                    (x) => ExcludeFocus(
                                      excluding: selected != x.key,
                                      child: TickerMode(
                                        enabled: selected == x.key,
                                        child: SingleChildScrollView(
                                          key: ValueKey('c-scroll-${x.key}'),
                                          controller: controllers[x.key],
                                          child: x.value(),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                  bottomShelf(),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
