import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

// Review-only fixtures. No production services, routes, storage or reward writes.
const previewHanok = 'assets/illustrations/hanok/ildu_v3_preview.png';
const previewCourtyard = 'assets/illustrations/gye/gye_showcase_courtyard.webp';
const previewCompanionVideo = 'assets/video/character/tiger_sitting2.mp4';
const previewCompanionPoster =
    'test/support/five_tabs_preview/video_poster.png';
const previewClosed = 'assets/illustrations/reward/reward_bojagi_closed.png';
const previewOpened = 'assets/illustrations/reward/reward_bojagi_open.png';
const previewStamp = 'assets/illustrations/stamps/stamp_lotus.png';
const learnGroups = <List<String>>[
  ['vocab_packs', 'grammar', 'word_web'],
  ['pronunciation', 'listening', 'scenarios', 'smalltalk'],
  ['hangul', 'calligraphy'],
  ['srs', 'my_words'],
];
const gamesOrder = [
  'daily_game',
  'chosung',
  'syllable_cross',
  'cloze',
  'speed_match',
  'sentence_arcade',
  'kkeunmari',
  'custom_practice',
];
String artPath(String id) => 'assets/illustrations/activities/$id.webp';
ActivityCatalogEntry activity(String id) =>
    soriActivityCatalog.singleWhere((e) => e.id == id);

class PreviewContent {
  PreviewContent(this.unit, this.scenario);
  final Map<String, dynamic> unit;
  final Map<String, dynamic> scenario;
  final Map<String, dynamic> first = jsonDecode(
    File(
      'test/support/five_tabs_preview/first_activity.json',
    ).readAsStringSync(),
  );
  ui.Image? companionFrame;
  Future<void> decodeCompanionFrame() async {
    if (companionFrame != null) {
      return;
    }
    final codec = await ui.instantiateImageCodec(
      File(previewCompanionPoster).readAsBytesSync(),
    );
    companionFrame = (await codec.getNextFrame()).image;
    codec.dispose();
  }

  static PreviewContent load() {
    final curriculum = jsonDecode(
      File('assets/data/curriculum_manifest.json').readAsStringSync(),
    );
    final scenarios = jsonDecode(
      File('assets/data/scenarios_a1.json').readAsStringSync(),
    );
    return PreviewContent(
      (curriculum['courseUnits'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((e) => e['id'] == 'a1_01_greetings_hangul'),
      (scenarios['scenarios'] as List).cast<Map<String, dynamic>>().singleWhere(
        (e) => e['id'] == 'airport_arrival',
      ),
    );
  }
}

class FiveTabsPreview extends StatefulWidget {
  const FiveTabsPreview({
    super.key,
    required this.content,
    this.locale = 'de',
    this.initial = 'today',
    this.scale = 1,
    this.full = false,
  });
  final PreviewContent content;
  final String locale;
  final String initial;
  final double scale;
  final bool full;
  @override
  State<FiveTabsPreview> createState() => _PreviewState();
}

class _PreviewState extends State<FiveTabsPreview> {
  late String page =
      ['game-explanation', 'course-explanation'].contains(widget.initial)
      ? 'explanation'
      : widget.initial;
  late String detailId = widget.initial == 'game-explanation'
      ? 'daily_game'
      : widget.initial == 'course-explanation'
      ? 'course'
      : 'vocab_packs';
  bool guideExpanded = false;
  bool completed = false;
  int question = 0;
  int? selected;
  int previewScore = 0;
  bool resultFromInteraction = false;
  final sectionKeys = List.generate(4, (_) => GlobalKey());
  int selectedCategory = 0;
  String tr(String de, String en) => widget.locale == 'de' ? de : en;
  String copy(SoriLocalizedCopy s) => tr(s.de, s.en);
  String localized(dynamic m) => m[widget.locale] as String;
  void go(String value) => setState(() => page = value);
  Text txt(
    String s, {
    double size = 16,
    bool bold = false,
    Color? color,
    bool serif = false,
  }) => Text(
    s,
    style: TextStyle(
      fontFamily: serif ? 'MaruBuri' : 'Paperlogy',
      fontSize: size,
      height: 1.35,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: color ?? SoriColors.lightText,
    ),
  );
  Widget gap([double h = 12]) => SizedBox(height: h);
  Widget title(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: txt(s, size: 26, serif: true),
  );
  Widget label(String s) =>
      txt(s, size: 15, color: SoriColors.primary, bold: true);
  Widget button(
    String s,
    VoidCallback? tap, {
    String? id,
    bool secondary = false,
  }) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: secondary
        ? OutlinedButton(
            onPressed: tap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: txt(s, bold: true, color: SoriColors.primary),
          )
        : FilledButton(
            key: id == null ? null : ValueKey(id),
            onPressed: tap,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: txt(s, bold: true, color: Colors.white),
          ),
  );
  Widget link(String s, VoidCallback tap) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: tap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: const Size(48, 48),
        alignment: Alignment.centerLeft,
      ),
      child: txt(s, size: 15, bold: true, color: SoriColors.primary),
    ),
  );
  Widget panel(
    List<Widget> children, {
    Color? color,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? SoriColors.lightSurfaceRaised,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SoriColors.lightSurfaceAlt),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  Widget art(String path, {double? width, bool failure = false}) => SizedBox(
    width: width,
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: failure
          ? ColoredBox(
              color: SoriColors.lightSurface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: txt(
                    tr(
                      'Bild gerade nicht verfügbar',
                      'Image currently unavailable',
                    ),
                    size: 15,
                  ),
                ),
              ),
            )
          : Image.asset(path, fit: BoxFit.contain),
    ),
  );
  Widget compactArt(String path) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: art(path, width: 128),
  );
  Widget feature(String id, {bool goal = false}) {
    final e = activity(id);
    return panel([
      LayoutBuilder(
        builder: (context, c) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(
                goal
                    ? tr('Begrüßen & bedanken', 'Greetings & thanks')
                    : copy(e.title),
                size: 21,
                bold: true,
                serif: true,
              ),
              if (!goal) ...[gap(5), txt(copy(e.description), size: 15)],
              gap(8),
              txt(
                goal
                    ? tr('9 Wörter · ca. 7 Min.', '9 words · about 7 min.')
                    : '${e.minutes} Min.',
                size: 15,
              ),
            ],
          );
          if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compactArt(artPath(goal ? 'vocab_packs' : id)),
                gap(),
                text,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              compactArt(artPath(goal ? 'vocab_packs' : id)),
              const SizedBox(width: 12),
              Expanded(child: text),
            ],
          );
        },
      ),
      gap(12),
      button(
        goal
            ? tr('Jetzt lernen', 'Start learning')
            : tr('Runde starten', 'Start session'),
        () {
          if (goal) {
            go('activity');
          } else {
            detailId = id;
            go('selected-activity');
          }
        },
        id: 'main-cta',
      ),
      if (goal)
        Row(
          children: [
            Expanded(
              child: txt(
                tr('A1 · Einheit 1', 'A1 · Unit 1'),
                size: 15,
                color: SoriColors.lightTextMuted,
              ),
            ),
            Flexible(
              child: link(tr('Kurs ansehen', 'View course'), () {
                detailId = 'course';
                go('explanation');
              }),
            ),
          ],
        )
      else
        link(tr('So funktioniert’s', 'How it works'), () {
          detailId = id;
          go('explanation');
        }),
    ]);
  }

  Widget normalCard(String id) {
    final e = activity(id);
    return Container(
      key: ValueKey('card-$id'),
      decoration: BoxDecoration(
        color: SoriColors.lightSurfaceRaised,
        border: Border.all(color: SoriColors.lightSurfaceAlt),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            detailId = id;
            go('selected-activity');
          },
          onLongPress: () {
            detailId = id;
            go('explanation');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                art(artPath(id)),
                gap(8),
                txt(copy(e.title), size: 16, bold: true),
                gap(4),
                txt(
                  copy(e.description),
                  size: 15,
                  color: SoriColors.lightTextMuted,
                ),
                Row(
                  children: [
                    Expanded(
                      child: txt(
                        '${e.minutes} Min.',
                        size: 15,
                        color: SoriColors.lightTextMuted,
                      ),
                    ),
                    Flexible(
                      child: link(tr('Details', 'Details'), () {
                        detailId = id;
                        go('explanation');
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget grid(List<String> ids) => LayoutBuilder(
    builder: (context, c) {
      final cols =
          MediaQuery.textScalerOf(context).scale(1) >= 1.5 && c.maxWidth < 600
          ? 1
          : 2;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final id in ids) SizedBox(width: w, child: normalCard(id)),
        ],
      );
    },
  );
  List<Widget> learn() => [
    title(tr('Lernen', 'Learn')),
    feature('course', goal: true),
    gap(20),
    txt(tr('Selbst üben', 'Choose your practice'), size: 20, serif: true),
    gap(4),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < 4; i++)
          ChoiceChip(
            key: ValueKey('learn-category-$i'),
            selected: selectedCategory == i,
            showCheckmark: false,
            selectedColor: SoriColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selectedCategory == i
                  ? SoriColors.primary
                  : SoriColors.primary.withValues(alpha: 0.45),
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: (_) {
              setState(() => selectedCategory = i);
              final c = sectionKeys[i].currentContext;
              if (c != null) {
                Scrollable.ensureVisible(
                  c,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                );
              }
            },
            label: txt(
              [
                tr('Wörter', 'Words'),
                tr('Hören', 'Listen'),
                'Hangul',
                tr('Wiederholen', 'Review'),
              ][i],
              size: 15,
              bold: selectedCategory == i,
              color: selectedCategory == i ? Colors.white : SoriColors.primary,
            ),
          ),
      ],
    ),
    for (var i = 0; i < 4; i++) ...[
      Padding(
        key: sectionKeys[i],
        padding: EdgeInsets.only(top: i == 0 ? 8 : 24, bottom: 8),
        child: txt(groupTitle(i), size: 20, serif: true, bold: true),
      ),
      grid(learnGroups[i]),
    ],
  ];
  String groupTitle(int i) => [
    tr('Wörter & Sätze', 'Words & sentences'),
    tr('Hören & Sprechen', 'Listen & speak'),
    tr('Hangul & Schreiben', 'Hangul & writing'),
    tr('Wiederholen & eigene Wörter', 'Review & my words'),
  ][i];
  List<Widget> games() => [
    title(tr('Spiele', 'Games')),
    label(tr('FÜR HEUTE', 'FOR TODAY')),
    gap(10),
    feature('daily_game'),
    gap(24),
    txt(
      tr('Noch eine Runde?', 'Another round?'),
      size: 20,
      serif: true,
      bold: true,
    ),
    gap(),
    grid(gamesOrder.skip(1).toList()),
  ];
  Widget companionIntroduction() => LayoutBuilder(
    builder: (context, c) {
      final stacked =
          c.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) >= 1.5;
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 144,
              height: 125,
              child: Semantics(
                label: tr('Taego begleitet dich', 'Taego is here with you'),
                child: RepaintBoundary(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: 144,
                      maxHeight: 144,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          SoriColors.lightBg,
                          BlendMode.multiply,
                        ),
                        child: RawImage(
                          key: const ValueKey('companion-poster'),
                          image: widget.content.companionFrame,
                          fit: BoxFit.contain,
                          width: 144,
                          height: 144,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 0,
            child: Container(
              width: 120,
              height: 3,
              decoration: BoxDecoration(
                color: SoriColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              16,
              stacked ? 0 : 160,
              stacked ? 133 : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: stacked ? 0 : 100),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    txt(
                      tr('Schön, dass du da bist.', 'Good to see you.'),
                      size: 15,
                    ),
                    gap(5),
                    txt(tr('Heute', 'Today'), size: 26, serif: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  List<Widget> today() => [
    companionIntroduction(),
    if (completed || page == 'today-return') ...[
      panel([
        label(
          tr(
            'Deine erste Aktivität ist geschafft.',
            'Your first activity is complete.',
          ),
        ),
        gap(),
        txt(
          tr('Weiter auf deinem Lernweg', 'Keep going on your learning path'),
          size: 20,
          serif: true,
        ),
        gap(),
        txt(
          tr(
            'Grüßen, danken, verabschieden: Dein erster Schritt ist geschafft. Dein Kurs führt dich weiter.',
            'Greeting, thanking, saying goodbye: your first step is complete. Your course will guide you onward.',
          ),
        ),
        gap(),
        button(
          tr('Nächsten Schritt ansehen', 'See the next step'),
          () => go('learn'),
        ),
      ]),
      gap(24),
    ] else ...[
      feature('course', goal: true),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            link(
              guideExpanded
                  ? tr('Anleitung schließen', 'Hide guide')
                  : tr('Wie funktioniert’s?', 'How does it work?'),
              () => setState(() => guideExpanded = !guideExpanded),
            ),
            if (guideExpanded)
              txt(
                tr(
                  '1. Erste Aktivität starten\n2. Ergebnis ansehen\n3. Zu Heute zurückkehren\n4. Deinen Hanok entdecken',
                  '1. Start your first activity\n2. View your result\n3. Return to Today\n4. Explore your Hanok',
                ),
                size: 15,
              ),
          ],
        ),
      ),
      gap(16),
    ],
    panel([
      LayoutBuilder(
        builder: (context, c) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              txt(tr('Dein Hanok', 'Your Hanok'), size: 20, serif: true),
              gap(6),
              txt(tr('Dein koreanisches Haus.', 'Your Korean home.'), size: 15),
              link(tr('Entdecken', 'Explore'), () => go('hanok')),
            ],
          );
          if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, art(previewHanok)],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              art(previewHanok, width: 128),
            ],
          );
        },
      ),
    ]),
    gap(24),
    quest(),
  ];
  Widget quest() => panel([
    label(tr('NÄCHSTE QUEST · ALTE KIEFER', 'NEXT QUEST · OLD PINE')),
    gap(8),
    txt(tr('Schließe 10 Szenarien ab.', 'Complete 10 scenarios.')),
    gap(8),
    txt(tr('0 von 10 abgeschlossen', '0 of 10 completed'), size: 15),
    link(tr('Szenarien entdecken', 'Explore scenarios'), () {
      detailId = 'scenarios';
      go('explanation');
    }),
  ]);
  List<Widget> hanok() => [
    title('Hanok'),
    txt(
      tr('Dein Lernen hinterlässt Spuren.', 'Your learning leaves its mark.'),
      size: 16,
    ),
    gap(16),
    label(tr('DEIN HAUS HEUTE', 'YOUR HOUSE TODAY')),
    gap(8),
    LayoutBuilder(
      builder: (context, c) {
        final note = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label(tr('DEIN LERNWEG', 'YOUR LEARNING PATH')),
            gap(12),
            txt(
              tr('Ein Haus voller Erinnerungen', 'A house full of memories'),
              size: 21,
              serif: true,
            ),
            gap(12),
            txt(
              tr(
                'Bestätigte Lernerfolge werden Teil deines Hanok.',
                'Confirmed learning achievements become part of your Hanok.',
              ),
              size: 15,
            ),
          ],
        );
        if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
          return Column(
            children: [
              SizedBox(
                height: 310,
                child: Image.asset(previewHanok, fit: BoxFit.contain),
              ),
              gap(16),
              note,
            ],
          );
        }
        return Row(
          children: [
            SizedBox(
              width: c.maxWidth * .5,
              height: 320,
              child: Image.asset(previewHanok, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            Expanded(child: note),
          ],
        );
      },
    ),
    gap(12),
    txt(
      tr(
        'Dein Hanok wird gerade aktualisiert. Deine Lernerfolge bleiben gespeichert.',
        'Your Hanok is updating. Your learning achievements are saved.',
      ),
      size: 15,
    ),
    gap(12),
    Wrap(
      spacing: 16,
      children: [
        TextButton(
          onPressed: () => go('quests'),
          child: txt('Quests', size: 15, bold: true, color: SoriColors.primary),
        ),
        TextButton(
          onPressed: () => go('stamps'),
          child: txt(
            tr('Stempel', 'Stamps'),
            size: 15,
            bold: true,
            color: SoriColors.primary,
          ),
        ),
        TextButton(
          onPressed: () => go('bojagi-pending'),
          child: txt('Bojagi', size: 15, bold: true, color: SoriColors.primary),
        ),
      ],
    ),
    gap(16),
    quest(),
    gap(24),
    panel([
      txt(tr('Deine Sammlung', 'Your collection'), size: 20, serif: true),
      link(
        tr('Dojang · Stempel ansehen', 'Dojang · View stamps'),
        () => go('stamps'),
      ),
      link(
        tr('Bojagi · Geschenke ansehen', 'Bojagi · View gifts'),
        () => go('bojagi-pending'),
      ),
    ]),
  ];
  List<Widget> gye() => [
    title('Gye'),
    if (page == 'gye' || page == 'gye-empty') ...[
      txt(
        tr('Zusammen dranbleiben', 'Keep learning together'),
        size: 22,
        serif: true,
      ),
      gap(8),
      txt(
        tr(
          'Eine Gye ist dein kleiner Lernkreis. Ihr übt Koreanisch und gestaltet gemeinsam einen Hof.',
          'A Gye is your small learning circle. Practice Korean and build a courtyard together.',
        ),
      ),
      gap(18),
      art(previewCourtyard),
      gap(10),
      txt(
        tr('Euer Hof wird gerade aktualisiert.', 'Your courtyard is updating.'),
        size: 15,
      ),
      gap(20),
      button(
        tr('Lernkreis gründen', 'Create a learning circle'),
        () => go('gye-member'),
      ),
      gap(10),
      button(
        tr('Mit Einladung beitreten', 'Join with an invitation'),
        () => go('gye-join-error'),
        secondary: true,
      ),
      link(
        tr('Erst einmal allein weiterlernen', 'Continue learning on my own'),
        () => go('learn'),
      ),
    ] else ...[
      label(tr('UNSER LERNKREIS', 'OUR LEARNING CIRCLE')),
      gap(8),
      txt('Morgenlicht', size: 23, serif: true),
      gap(6),
      txt(
        tr(
          '4 Mitglieder · Gemeinsam Koreanisch lernen',
          '4 members · Learning Korean together',
        ),
        size: 15,
      ),
      gap(16),
      panel([
        txt(tr('Unser Wochenziel', 'Our weekly goal'), bold: true),
        gap(8),
        txt(
          tr('3 von 7 gemeinsamen Lerntagen', '3 of 7 shared learning days'),
          size: 15,
        ),
        gap(8),
        const LinearProgressIndicator(value: 3 / 7, minHeight: 5),
      ]),
      gap(18),
      art(previewCourtyard),
      gap(10),
      txt(
        tr('Euer Hof wird gerade aktualisiert.', 'Your courtyard is updating.'),
        size: 15,
      ),
      gap(18),
      button(
        tr('Heute gemeinsam lernen', 'Learn together today'),
        () => go('learn'),
      ),
      link(
        tr('Lernkreis ansehen', 'View learning circle'),
        () => go('gye-detail'),
      ),
      if (page == 'gye-detail')
        panel([
          txt(tr('Mitglieder', 'Members'), size: 20, serif: true),
          gap(),
          txt('Jin · Mia · Alex · Sam'),
          gap(),
          txt(
            tr(
              'Jede Lerneinheit zählt für euren gemeinsamen Weg.',
              'Every learning session contributes to your shared journey.',
            ),
          ),
        ]),
    ],
  ];
  // Review copy describes existing mechanics; source pointers are recorded in
  // rules-provenance.json. Reward conditions still come directly from catalog.
  String activityRules(String id) => switch (id) {
    'vocab_packs' => tr(
      'Lerne zuerst die 9 Wörter dieses Pakets mit Audio und Beispielen. Danach folgen 7 Quizfragen und 2 Bossfragen. Wähle jeweils die passende Bedeutung.',
      'First learn this pack’s 9 words with audio and examples. Then answer 7 quiz questions and 2 boss questions. Choose the matching meaning each time.',
    ),
    'daily_game' => tr(
      'Wähle das fehlende Wort in jedem Satz. Die Tagesrunde enthält bis zu 10 Lückentexte auf deinem Niveau; jeden Tag wird eine neue Auswahl zusammengestellt.',
      'Choose the missing word in each sentence. The daily session contains up to 10 gap-fill questions at your level, with a new selection each day.',
    ),
    'chosung' => tr(
      'Erkenne das Wort an seinen Anfangslauten und der Übersetzung. Tippe das koreanische Wort ein und prüfe deine Antwort. Im Hilfemodus siehst du zusätzlich die Vokale.',
      'Identify the word from its initial sounds and translation. Type the Korean word and check your answer. The hint mode also shows its vowels.',
    ),
    'course' => tr(
      'Öffne eine Einheit und folge den Schritten zum Hören, Üben und Anwenden. Die Kursübersicht zeigt dir, wo du weitermachen kannst.',
      'Open a unit and follow its listening, practice and application steps. The course overview shows where you can continue.',
    ),
    'hangul' => tr(
      'Wähle Buchstaben oder Silben, höre ihren Klang und übe die Schreibweise auf der Zeichenfläche.',
      'Choose letters or syllables, listen to their sounds and practice writing on the drawing area.',
    ),
    'calligraphy' => tr(
      'Entdecke das heutige Schriftzeichen und übe seine Striche auf der Zeichenfläche.',
      'Explore today’s character and practice its strokes on the drawing area.',
    ),
    'pronunciation' => tr(
      'Höre die Vorlage und sprich den Satz nach. Wiederhole ihn in deinem Tempo.',
      'Listen to the model and repeat the sentence. Practice again at your own pace.',
    ),
    'srs' => tr(
      'Öffne deine fälligen Wiederholungen und decke die Antwort auf. Markiere das Wort als bekannt oder schwierig.',
      'Open your due reviews and reveal the answer. Mark the word as known or difficult.',
    ),
    'my_words' => tr(
      'Suche ein Wort oder öffne deine gespeicherten Wörter. Wähle von dort aus, was du lernen möchtest.',
      'Search for a word or open your saved words, then choose what you want to learn.',
    ),
    'grammar' => tr(
      'Wähle ein Muster, lies die Erklärung und Beispiele und prüfe dein Verständnis in der passenden Übung.',
      'Choose a pattern, read its explanation and examples, and check your understanding in the related practice.',
    ),
    'listening' => tr(
      'Wähle eine Szene und höre den Dialog. Gehe danach die einzelnen Zeilen durch und höre sie bei Bedarf noch einmal.',
      'Choose a scene and listen to its dialogue. Then review the individual lines and play them again as needed.',
    ),
    'scenarios' => tr(
      'Höre den Dialog, lerne die Ausdrücke und löse die Aufgaben zur Szene.',
      'Listen to the dialogue, learn its expressions and complete the scene tasks.',
    ),
    'smalltalk' => tr(
      'Wähle ein Gesprächsthema, höre die kurzen Ausdrücke und sprich sie nach.',
      'Choose a conversation topic, listen to the short expressions and repeat them.',
    ),
    'word_web' => tr(
      'Öffne ein Wort und entdecke seine Synonyme, Gegenteile und Wendungen. Prüfe die Beziehungen anschließend im Quiz.',
      'Open a word and explore its synonyms, opposites and expressions. Then check these relationships in the quiz.',
    ),
    'syllable_cross' => tr(
      'Tippe auf ein Feld im Kreuzworträtsel und dann auf die passende Silbe aus dem Vorrat. Richtige Silben bleiben stehen; die Bedeutung und Beispielsätze helfen dir.',
      'Tap a crossword cell and then the matching syllable from the pool. Correct syllables stay in place; the meaning and example sentences provide clues.',
    ),
    'cloze' => tr(
      'Lies den Satz mit der Lücke und wähle das passende Wort aus den Antworten.',
      'Read the sentence with a gap and choose the missing word from the answers.',
    ),
    'speed_match' => tr(
      'Verbinde koreanische Wörter mit ihrer Bedeutung, bevor die Zeit abläuft.',
      'Match Korean words to their meanings before time runs out.',
    ),
    'sentence_arcade' => tr(
      'Ordne die Wortbausteine zum richtigen koreanischen Satz, bevor die Zeit abläuft.',
      'Arrange the word tiles into the correct Korean sentence before time runs out.',
    ),
    'kkeunmari' => tr(
      'Dein Wort muss mit der letzten Silbe des vorherigen Wortes beginnen. Gib es ein, bevor die Zeit abläuft; danach ist der Tiger dran.',
      'Your word must start with the final syllable of the previous word. Enter it before time runs out, then the tiger takes a turn.',
    ),
    'custom_practice' => tr(
      'Öffne deine gespeicherten Wörter und wähle Quiz, Matching oder Tippen als Übung.',
      'Open your saved words and choose quiz, matching or typing practice.',
    ),
    _ => throw StateError('Missing preview rules for $id'),
  };
  List<Widget> explanation() => [
    title(copy(activity(detailId).title)),
    art(artPath(detailId)),
    gap(20),
    txt(copy(activity(detailId).description), size: 19),
    gap(12),
    txt('${activity(detailId).minutes} Min. · ${tr('Richtwert', 'Estimated')}'),
    gap(24),
    label(tr('SO FUNKTIONIERT’S', 'HOW IT WORKS')),
    gap(10),
    txt(activityRules(detailId)),
    gap(24),
    label(tr('MÖGLICHE BELOHNUNGEN', 'POSSIBLE REWARDS')),
    gap(10),
    txt(copy(activity(detailId).reward.condition)),
    gap(8),
    for (final r in activity(detailId).reward.items)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: txt(copy(r.label), size: 15),
      ),
    gap(12),
    txt(
      tr(
        'Eine Runde ist ein Lernschritt. Ein Kursabschluss und Hanok-Fortschritt werden gesondert bestätigt.',
        'A session is one learning step. Course completion and Hanok progress are confirmed separately.',
      ),
      size: 15,
    ),
    gap(24),
    button(
      tr('Aktivität starten', 'Start activity'),
      () => go(detailId == 'vocab_packs' ? 'activity' : 'selected-activity'),
      id: 'explanation-start',
    ),
  ];
  List<Widget> result(bool game) => [
    title(
      tr(
        game ? 'Runde geschafft' : 'Aktivität geschafft',
        game ? 'Session complete' : 'Activity complete',
      ),
    ),
    Center(
      child: Icon(
        Icons.check_circle_outline,
        size: 62,
        color: SoriColors.primary,
      ),
    ),
    gap(18),
    txt(
      game
          ? copy(activity('daily_game').title)
          : widget.content.first['pack_title_${widget.locale}'] as String,
      size: 22,
      serif: true,
    ),
    gap(14),
    panel([
      label(tr('DEIN ERGEBNIS', 'YOUR RESULT')),
      gap(12),
      txt(
        game
            ? tr('Runde beendet', 'Session finished')
            : tr(
                '${resultFromInteraction ? previewScore : 9} von 9 Aufgaben richtig',
                '${resultFromInteraction ? previewScore : 9} of 9 tasks correct',
              ),
        size: 22,
        serif: true,
      ),
      gap(8),
      txt(
        tr(
          'Gut gemacht. Nimm den nächsten Schritt in deinem Tempo.',
          'Well done. Take your next step at your own pace.',
        ),
      ),
    ]),
    gap(24),
    if (!game) ...[
      txt(tr('Das hast du geübt', 'What you practiced'), size: 20, serif: true),
      gap(10),
      txt('안녕하세요 · 감사합니다\n안녕히 가세요 · 잘 자요'),
      gap(8),
      txt(
        tr(
          'Grüßen, danken und verabschieden.',
          'Greeting, thanking and saying goodbye.',
        ),
        size: 15,
      ),
      gap(24),
    ],
    txt(
      tr(
        'Weiterlernen oder kurz durchatmen? Dein Kurs wartet auf dich.',
        'Keep learning or take a breather? Your course is ready when you are.',
      ),
      size: 15,
    ),
    gap(24),
    button(tr('Zurück zu Heute', 'Back to Today'), () {
      completed = true;
      go('today-return');
    }, id: 'return-today'),
    gap(8),
    link(tr('Noch einmal üben', 'Practice again'), () {
      question = 0;
      selected = null;
      go('activity');
    }),
  ];
  List<Widget> states() => switch (page) {
    'quests' => [
      title(tr('Quests', 'Quests')),
      quest(),
      gap(24),
      txt(
        tr(
          'Jeder bestätigte Abschluss zählt.',
          'Every confirmed completion counts.',
        ),
        size: 15,
      ),
    ],
    'stamps' => [
      title(tr('Dojang · Deine Stempel', 'Dojang · Your stamps')),
      art(previewStamp),
      gap(24),
      txt(
        tr(
          'Hier sammeln sich deine Erfolge.',
          'Your achievements collect here.',
        ),
        size: 22,
        serif: true,
      ),
      gap(),
      txt(
        tr(
          'Noch kein Stempel. Schließe ein Wortpaket erstmals ab, um einen zu erhalten.',
          'No stamps yet. Complete a vocabulary pack for the first time to earn one.',
        ),
      ),
      gap(24),
      button(tr('Wortpakete entdecken', 'Explore vocabulary packs'), () {
        detailId = 'vocab_packs';
        go('explanation');
      }),
    ],
    'bojagi-pending' || 'bojagi-opening' || 'bojagi-result' => [
      title('Bojagi'),
      art(page == 'bojagi-pending' ? previewClosed : previewOpened),
      gap(24),
      txt(
        tr(
          page == 'bojagi-pending'
              ? 'Ein Geschenk wartet auf dich'
              : page == 'bojagi-opening'
              ? 'Dein Geschenk öffnet sich …'
              : 'Dein Geschenk ist geöffnet',
          page == 'bojagi-pending'
              ? 'A gift is waiting for you'
              : page == 'bojagi-opening'
              ? 'Your gift is opening …'
              : 'Your gift is open',
        ),
        size: 23,
        serif: true,
      ),
      gap(12),
      txt(
        tr(
          page == 'bojagi-result'
              ? 'Ein Dojang-Stempel für deine Sammlung.'
              : 'Deine bestätigte Belohnung ist bereit.',
          page == 'bojagi-result'
              ? 'A Dojang stamp for your collection.'
              : 'Your confirmed reward is ready.',
        ),
      ),
      gap(24),
      if (page == 'bojagi-result') art(previewStamp, width: 128),
      if (page != 'bojagi-opening')
        button(
          tr(
            page == 'bojagi-pending' ? 'Geschenk öffnen' : 'Sammlung ansehen',
            page == 'bojagi-pending' ? 'Open gift' : 'View collection',
          ),
          () => go(page == 'bojagi-pending' ? 'bojagi-opening' : 'stamps'),
        ),
      if (page == 'bojagi-opening') const LinearProgressIndicator(value: 0.55),
    ],
    'gye-join-error' => [
      title(tr('Lernkreis beitreten', 'Join a learning circle')),
      txt(
        tr('Dein Einladungscode', 'Your invitation code'),
        size: 20,
        serif: true,
      ),
      gap(16),
      const TextField(
        decoration: InputDecoration(
          labelText: 'Code',
          hintText: 'ABCD12',
          border: OutlineInputBorder(),
        ),
      ),
      gap(16),
      txt(
        tr(
          'Dieser Code ist nicht mehr gültig. Bitte lass dir einen neuen schicken.',
          'This code is no longer valid. Please ask for a new one.',
        ),
        color: SoriColors.danger,
      ),
      gap(24),
      button(tr('Erneut versuchen', 'Try again'), () => go('gye-member')),
      link(tr('Zurück zu Gye', 'Back to Gye'), () => go('gye')),
    ],
    'loading' => [
      title(tr('Heute', 'Today')),
      gap(24),
      const LinearProgressIndicator(value: 0.35),
      gap(24),
      txt(
        tr('Dein Lernweg wird geladen …', 'Loading your learning path …'),
        size: 20,
        serif: true,
      ),
    ],
    'offline' => [
      title(tr('Du bist offline', 'You’re offline')),
      const Icon(Icons.wifi_off, size: 52, color: SoriColors.primary),
      gap(24),
      txt(
        tr(
          'Du kannst mit heruntergeladenen Inhalten weiterlernen. Deinen Fortschritt gleichen wir ab, sobald du wieder online bist.',
          'You can keep learning with downloaded content. Your progress will sync when you’re online again.',
        ),
      ),
      gap(24),
      button(
        tr('Verfügbare Übungen ansehen', 'View available practice'),
        () => go('learn'),
      ),
      link(
        tr('Verbindung erneut prüfen', 'Check connection again'),
        () => go('loading'),
      ),
    ],
    'progress-unavailable' => [
      title(tr('Heute', 'Today')),
      panel([
        txt(
          tr(
            'Dein Fortschritt ist gerade nicht verfügbar',
            'Your progress is currently unavailable',
          ),
          size: 22,
          serif: true,
        ),
        gap(),
        txt(
          tr(
            'Versuche es erneut. Du kannst inzwischen frei üben.',
            'Try again. You can explore practice in the meantime.',
          ),
        ),
        gap(20),
        button(tr('Erneut laden', 'Try again'), () => go('loading')),
      ]),
      gap(24),
      button(
        tr('Übungen entdecken', 'Explore practice'),
        () => go('learn'),
        secondary: true,
      ),
    ],
    'image-failure' => [
      title(tr('Spiele', 'Games')),
      art(artPath('daily_game'), failure: true),
      gap(16),
      txt(copy(activity('daily_game').title), size: 22, serif: true),
      gap(),
      txt(copy(activity('daily_game').description)),
      gap(),
      txt('4 Min.'),
      gap(24),
      button(tr('Runde starten', 'Start session'), () => go('game-result')),
    ],
    _ => [],
  };
  Widget study(BuildContext context) {
    final words = widget.content.first['pack_words'] as List;
    final boss = page == 'activity-boss';
    final word = words[boss ? question + 7 : question % words.length];
    final quiz = page == 'activity-quiz' || boss;
    final options = [
      word[widget.locale] as String,
      words[(question + 1) % 9][widget.locale] as String,
      words[(question + 2) % 9][widget.locale] as String,
      words[(question + 3) % 9][widget.locale] as String,
    ];
    return SoriStudyFrame(
      title: tr('Begrüßung', 'Greetings'),
      eyebrow: quiz
          ? '${boss ? 'Boss' : 'Quiz'} · ${question + 1} / ${boss ? 2 : 7}'
          : '${question + 1} / ${words.length}',
      onLeave: () => go('today'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label(
              quiz
                  ? tr('ERKENNE DIE BEDEUTUNG', 'RECOGNIZE THE MEANING')
                  : tr('HÖREN UND KENNENLERNEN', 'LISTEN AND LEARN'),
            ),
            gap(22),
            txt(
              quiz
                  ? tr('Was bedeutet das?', 'What does this mean?')
                  : tr(
                      question == 0 ? 'Dein erstes Wort' : 'Dein nächstes Wort',
                      question == 0 ? 'Your first word' : 'Your next word',
                    ),
              size: 25,
              serif: true,
            ),
            gap(24),
            panel([
              if (quiz)
                Row(
                  children: [
                    Expanded(child: txt(word['ko'], size: 32, serif: true)),
                    IconButton(
                      key: const ValueKey('audio'),
                      onPressed: () {},
                      tooltip: tr('Audio anhören', 'Listen to audio'),
                      icon: const Icon(Icons.volume_up_outlined),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                )
              else ...[
                txt(word['ko'], size: 32, serif: true),
                gap(18),
                button(
                  tr('Audio anhören', 'Listen to audio'),
                  () {},
                  id: 'audio',
                ),
              ],
              if (!quiz) ...[
                gap(20),
                txt(word[widget.locale], size: 20),
                gap(20),
                txt(word['example_ko'], size: 20),
                gap(8),
                txt(word['example_${widget.locale}'], size: 15),
              ],
            ]),
            gap(24),
            if (quiz)
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    key: ValueKey('answer-$i'),
                    onPressed: () => setState(() => selected = i),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected == i
                          ? SoriColors.primarySoft
                          : SoriColors.lightSurfaceRaised,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: txt(options[i]),
                    ),
                  ),
                ),
            button(
              quiz
                  ? tr('Antwort prüfen', 'Check answer')
                  : tr('Nächstes Wort', 'Next word'),
              quiz && selected == null
                  ? null
                  : () {
                      setState(() {
                        if (quiz && selected == 0) {
                          previewScore++;
                        }
                        final limit = boss
                            ? 1
                            : quiz
                            ? 6
                            : 8;
                        if (question < limit) {
                          question++;
                        } else {
                          question = 0;
                          if (boss) {
                            resultFromInteraction = true;
                            page = 'learning-result';
                          } else {
                            page = quiz ? 'activity-boss' : 'activity-quiz';
                          }
                        }
                        selected = null;
                      });
                    },
              id: 'answer-next',
            ),
            gap(16),
            txt(
              tr(
                '9 Wörter lernen · 7 Quizfragen · 2 Bossfragen',
                'Learn 9 words · 7 quiz questions · 2 boss questions',
              ),
              size: 15,
            ),
            gap(24),
          ],
        ),
      ),
    );
  }

  List<Widget> content() => switch (page) {
    'today' || 'today-return' => today(),
    'learn' => learn(),
    'games' => games(),
    'hanok' => hanok(),
    'gye' || 'gye-empty' || 'gye-member' || 'gye-detail' => gye(),
    'explanation' => explanation(),
    'selected-activity' => [
      title(copy(activity(detailId).title)),
      art(artPath(detailId)),
      gap(24),
      txt(copy(activity(detailId).description)),
      gap(24),
      txt(
        tr('Die Aktivität ist ausgewählt.', 'Your activity is selected.'),
        size: 20,
        serif: true,
      ),
      gap(16),
      button(
        tr('Zurück zur Auswahl', 'Back to activities'),
        () => go(
          activity(detailId).tab == SoriStageTab.games ? 'games' : 'learn',
        ),
      ),
    ],
    'learning-result' => result(false),
    'game-result' => result(true),
    _ => states(),
  };
  Widget nav(bool rail) {
    const icons = [
      Icons.wb_sunny_outlined,
      Icons.menu_book_outlined,
      Icons.sports_esports_outlined,
      Icons.home_outlined,
      Icons.people_outline,
    ];
    const ids = ['today', 'learn', 'games', 'hanok', 'gye'];
    final names = [
      tr('Heute', 'Today'),
      tr('Lernen', 'Learn'),
      tr('Spiele', 'Games'),
      'Hanok',
      'Gye',
    ];
    return SoriAdaptiveNavigation(
      selectedIndex: ids.indexOf(page).clamp(0, 4),
      onDestinationSelected: (i) => go(ids[i]),
      items: [
        for (var i = 0; i < 5; i++)
          SoriAdaptiveNavigationItem(
            label: names[i],
            icon: icons[i],
            selectedIcon: icons[i],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: Locale(widget.locale),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) {
        if (page == 'learning-result' || page == 'game-result') {
          return SoriStudyFrame(
            title: tr('Ergebnis', 'Result'),
            onLeave: () => go('today'),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: result(page == 'game-result'),
              ),
            ),
          );
        }
        if (page == 'activity' ||
            page == 'activity-quiz' ||
            page == 'activity-boss') {
          return study(context);
        }
        final rail = SoriAdaptiveNavigation.usesRailForWidth(
          MediaQuery.sizeOf(context).width,
        );
        final body = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              key: ValueKey('scroll-$page'),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                key: const ValueKey('page-content'),
                children: content(),
              ),
            ),
          ),
        );
        return Scaffold(
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (rail && !widget.full)
                  SizedBox(
                    width: SoriAdaptiveNavigation.railWidthForWidth(
                      MediaQuery.sizeOf(context).width,
                    ),
                    child: nav(true),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
          bottomNavigationBar: rail || widget.full ? null : nav(false),
        );
      },
    ),
  );
}
