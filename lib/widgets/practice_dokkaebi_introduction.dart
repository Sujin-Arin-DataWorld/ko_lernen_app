import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'sori/button.dart';
import 'sori/c_gallery/c_materials.dart';
import 'sori/dokkaebi_intro.dart';
import 'sori/external_link.dart';
import 'sori/tokens.dart';

/// The approved large carved frame has its own dark introduction surface.
/// Exploring culture or replaying the film never records practice or rewards.
class PracticeDokkaebiIntroduction extends StatefulWidget {
  const PracticeDokkaebiIntroduction({super.key, this.paddedBySheet = false});
  final bool paddedBySheet;

  @override
  State<PracticeDokkaebiIntroduction> createState() =>
      _PracticeDokkaebiIntroductionState();
}

class _PracticeDokkaebiIntroductionState
    extends State<PracticeDokkaebiIntroduction> {
  int _replay = 0;
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    Widget section(String title, String body, List<Widget> details) =>
        CPaperPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: text.h3),
              const SizedBox(height: 8),
              Text(body, style: text.body),
              ...details,
            ],
          ),
        );
    Widget source(String label, String url) => SoriButton.ghost(
      label: label,
      onTap: () => openExternalUrl(context, url),
      fullWidth: true,
    );
    return Scaffold(
      backgroundColor: const Color(0xff101827),
      appBar: AppBar(
        backgroundColor: const Color(0xff101827),
        foregroundColor: Colors.white,
        title: Text(
          t.cultureDokkaebiName,
          style: text.chromeTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          tooltip: t.btnClose,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const ValueKey('dokkaebi-intro-scroll'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 342),
                      child: DokkaebiIntro(
                        key: ValueKey('approved-dokkaebi-intro-$_replay'),
                        onFinished: () {
                          if (mounted) {
                            setState(() => _finished = true);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '도깨비',
                    textAlign: TextAlign.center,
                    style: text.cultureTitle.copyWith(color: Colors.white),
                  ),
                  if (_finished) ...[
                    const SizedBox(height: 16),
                    CMaterialAction(
                      label: t.practiceDokkaebiGesture,
                      onTap: () => setState(() {
                        _finished = false;
                        _replay++;
                      }),
                    ),
                  ],
                  const SizedBox(height: 24),
                  section(
                    t.practiceDokkaebiTalesTitle,
                    t.practiceDokkaebiTalesBody,
                    [
                      const SizedBox(height: 8),
                      Text(t.practiceDokkaebiFormNote, style: text.bodySmall),
                      Text(t.practiceDokkaebiAbout, style: text.bodySmall),
                      Text(t.practiceDokkaebiFireWord, style: text.bodySmall),
                      source(
                        t.practiceDokkaebiFolkloreSource,
                        'https://encykorea.aks.ac.kr/Article/E0015531',
                      ),
                      source(
                        t.practiceDokkaebiFolkloreSource,
                        'https://encykorea.aks.ac.kr/Article/E0015527',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  section(
                    t.practiceDokkaebiHomeTitle,
                    t.practiceDokkaebiHomeBody,
                    [
                      const SizedBox(height: 8),
                      Text('귀면와', style: text.cultureTitle),
                      Text(t.practiceDokkaebiRoofBody, style: text.bodySmall),
                      source(
                        t.practiceDokkaebiMuseumSource,
                        'https://www.museum.go.kr/site/main/relic/search/view?relicId=1478',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  section(
                    t.practiceDokkaebiLearningTitle,
                    t.practiceDokkaebiLearningBody,
                    [
                      const SizedBox(height: 8),
                      Text(
                        t.practiceDokkaebiLearningNote,
                        style: text.bodySmall,
                      ),
                      Text(t.practiceDokkaebiAppStory, style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CMaterialAction(
                    label: t.practiceDokkaebiReturn,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
