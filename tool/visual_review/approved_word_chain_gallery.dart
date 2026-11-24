import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_word_chain_view.dart';

/// Presentation evidence only: these explicit approved Figma states never feed
/// the learning engine. Run with APPROVED_WORD_CHAIN_FIXTURE=0, 1 or 2.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const ApprovedWordChainGalleryApp());
}

const approvedWordChainFixtureNames = [
  'word-chain-a',
  'word-chain-b',
  'word-chain-c',
];

class ApprovedWordChainGalleryApp extends StatelessWidget {
  const ApprovedWordChainGalleryApp({
    super.key,
    this.fixture = const int.fromEnvironment('APPROVED_WORD_CHAIN_FIXTURE'),
    this.captureKey,
    this.normalizeCapture = false,
  });
  final int fixture;
  final Key? captureKey;
  final bool normalizeCapture;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: normalizeCapture
          ? MediaQuery.of(context).copyWith(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
              viewInsets: EdgeInsets.zero,
              textScaler: TextScaler.noScaling,
              disableAnimations: true,
            )
          : MediaQuery.of(context),
      child: RepaintBoundary(key: captureKey, child: child!),
    ),
    home: ApprovedWordChainFixture(fixture: fixture),
  );
}

class ApprovedWordChainFixture extends StatefulWidget {
  const ApprovedWordChainFixture({
    super.key,
    required this.fixture,
    this.word,
    this.meaning,
    this.speedLabel = '1×',
    this.autofocus = false,
  });
  final int fixture;
  final String? word, meaning;
  final String speedLabel;
  final bool autofocus;
  @override
  State<ApprovedWordChainFixture> createState() =>
      _ApprovedWordChainFixtureState();
}

class _ApprovedWordChainFixtureState extends State<ApprovedWordChainFixture> {
  late final _controller = TextEditingController(
    text: ['', '거울', '권리'][widget.fixture],
  );
  final _focus = FocusNode();
  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    final word = widget.word ?? ['가방', '자전거', '의사결정권'][f];
    final chain = widget.word == null
        ? [
            ['가방'],
            ['커피', '피자', '자전거'],
            ['운동', '동의', '의사결정권'],
          ][f]
        : [word];
    return ApprovedWordChainFrame(
      title: 'Wortkette',
      contentBuilder: (context, close) {
        final t = AppL10n.of(context);
        final last = word.characters.last;
        return ApprovedWordChainView(
          title: t.kkeunmariTitle,
          instruction: t.kkeunmariSubtitle,
          turnLabel: t.kkeunmariYourTurn,
          timerLabel: t.kkeunmariTimerSeconds([30, 24, 18][f]),
          chainLabel: t.kkeunmariChainLength(chain.length),
          chain: chain,
          word: word,
          meaning:
              widget.meaning ?? ['Tasche', 'Fahrrad', 'Entscheidungsrecht'][f],
          requiredSyllable: last,
          requiredHint: t.kkeunmariStartHint(last),
          inputHint: t.kkeunmariInputHint,
          listenLabel: t.approvedGameListen,
          listenSemantics: t.ttsListenTarget(word),
          submitLabel: t.kkeunmariSubmit,
          controller: _controller,
          focusNode: _focus,
          close: close,
          autofocus: widget.autofocus,
          onSubmit: () {},
          onListen: () {},
          speedLabel: widget.speedLabel,
          onSpeed: () {},
        );
      },
    );
  }
}
