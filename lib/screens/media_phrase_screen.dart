import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/learner_level.dart';
import '../models/media_phrase.dart';
import '../services/data_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// Exact-level media practice. A C-level learner must never receive an A1
/// greeting merely because it appears first in the asset.
List<MediaPhrase> mediaPhrasesForLevel(
  List<MediaPhrase> phrases,
  String? levelCode,
) {
  final level = LearnerLevel.fromCode(levelCode) ?? LearnerLevel.a1;
  return List<MediaPhrase>.unmodifiable(
    phrases.where((phrase) => phrase.level.toUpperCase() == level.display),
  );
}

class MediaPhraseScreen extends StatefulWidget {
  const MediaPhraseScreen({super.key, this.loader});

  final Future<List<MediaPhrase>> Function()? loader;

  @override
  State<MediaPhraseScreen> createState() => _MediaPhraseScreenState();
}

class _MediaPhraseScreenState extends State<MediaPhraseScreen> {
  List<MediaPhrase> _phrases = const [];
  var _index = 0;
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await (widget.loader ?? DataLoader.loadMediaPhrases)();
      if (!mounted) return;
      setState(() {
        _phrases = mediaPhrasesForLevel(all, Storage.userLevelCode);
        _loading = false;
        _failed = false;
        _index = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardPage(
      appBarTitle: t.mediaPhraseTitle,
      eyebrow: LearnerLevel.fromCode(Storage.userLevelCode)?.display ?? 'A1',
      headline: t.mediaPhraseTitle,
      description: t.mediaPhraseDesc,
      maxWidth: SoriMaxWidth.prose,
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_failed || _phrases.isEmpty)
          SoriCard(
            child: Column(
              children: [
                Text(t.mediaPhraseEmpty),
                const SizedBox(height: Spacing.md),
                SoriButton.outlined(label: t.btnRetry, onTap: _load),
              ],
            ),
          )
        else
          _phraseCard(context, _phrases[_index]),
      ],
    );
  }

  Widget _phraseCard(BuildContext context, MediaPhrase phrase) {
    final t = AppL10n.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final text = SoriTextTheme.of(context);
    return Column(
      children: [
        SoriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      phrase.sourceStyle,
                      style: text.label.copyWith(color: SoriColors.primary),
                    ),
                  ),
                  Text('${_index + 1} / ${_phrases.length}', style: text.label),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              Text(phrase.korean, style: text.h2),
              if (phrase.romanization.isNotEmpty) ...[
                const SizedBox(height: Spacing.xs),
                Text('[${phrase.romanization}]', style: text.cardSubtitle),
              ],
              const SizedBox(height: Spacing.md),
              Text(phrase.meaning(language), style: text.body),
              const SizedBox(height: Spacing.lg),
              Text(t.mediaPhraseContext, style: text.label),
              const SizedBox(height: Spacing.xs),
              Text(phrase.context(language), style: text.cardSubtitle),
              const SizedBox(height: Spacing.lg),
              SoriButton.outlined(
                label: t.pronunciationListen,
                icon: Icons.volume_up_rounded,
                onTap: () => TtsService.speak(phrase.korean),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: SoriButton.outlined(
                label: t.mediaPhrasePrevious,
                onTap: _index == 0 ? null : () => setState(() => _index -= 1),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: SoriButton.filled(
                label: t.mediaPhraseNext,
                onTap: _index + 1 >= _phrases.length
                    ? null
                    : () => setState(() => _index += 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
