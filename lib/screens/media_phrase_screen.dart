import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/media_phrase.dart';
import '../services/analytics_service.dart';
import '../services/data_loader.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// The complete reviewed media corpus is open independently of placement.
List<MediaPhrase> openMediaPhraseCatalog(List<MediaPhrase> phrases) =>
    List<MediaPhrase>.unmodifiable(phrases);

class MediaPhraseScreen extends StatefulWidget {
  const MediaPhraseScreen({super.key, this.loader, this.speaker});

  final Future<List<MediaPhrase>> Function()? loader;
  final Future<bool> Function(String text)? speaker;

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

  Future<void> _load({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final usesProductionLoader = widget.loader == null;
      final all = await (widget.loader ?? DataLoader.loadMediaPhrases)();
      if (!mounted) return;
      final failed =
          usesProductionLoader &&
          all.isEmpty &&
          DataLoader.mediaPhrasesError != null;
      setState(() {
        _phrases = failed ? const <MediaPhrase>[] : openMediaPhraseCatalog(all);
        _loading = false;
        _failed = failed;
        _index = 0;
      });
      if (_phrases.isNotEmpty) {
        unawaited(Analytics.lessonStarted(lessonType: 'media_phrase'));
      }
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
      eyebrow: _phrases.isEmpty ? null : _phrases[_index].level.toUpperCase(),
      headline: t.mediaPhraseTitle,
      description: t.mediaPhraseDesc,
      maxWidth: SoriMaxWidth.prose,
      children: [
        if (_loading)
          Semantics(
            liveRegion: true,
            label: t.mediaPhraseLoading,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
              child: AppLoading(message: t.mediaPhraseLoading),
            ),
          )
        else if (_failed)
          AppError(
            message: t.mediaPhraseUnavailable,
            messageLiveRegion: true,
            onRetry: () {
              if (widget.loader == null) {
                DataLoader.resetMediaPhrases();
              }
              _load(showLoading: true);
            },
          )
        else if (_phrases.isEmpty)
          SoriEmptyState(
            icon: Icons.library_music_outlined,
            title: t.mediaPhraseEmptyTitle,
            body: t.mediaPhraseEmpty,
            ctaLabel: t.btnClose,
            onCta: () => Navigator.of(context).maybePop(),
            illustrationMaxHeight: 120,
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
          key: ValueKey('media-phrase-card-${phrase.id}'),
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
                  Semantics(
                    key: const ValueKey('media-phrase-progress'),
                    container: true,
                    liveRegion: true,
                    label: t.mediaPhraseProgress(_index + 1, _phrases.length),
                    excludeSemantics: true,
                    child: Text(
                      '${_index + 1} / ${_phrases.length}',
                      style: text.label,
                    ),
                  ),
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
                key: const ValueKey('media-phrase-listen'),
                label: t.pronunciationListen,
                semanticLabel: t.mediaPhraseListenTarget(phrase.korean),
                icon: Icons.volume_up_rounded,
                fullWidth: true,
                onTap: () {
                  (widget.speaker ?? TtsService.speak)(phrase.korean);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: SoriButton.outlined(
                key: const ValueKey('media-phrase-previous'),
                label: t.mediaPhrasePrevious,
                onTap: _index == 0 ? null : () => setState(() => _index -= 1),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: SoriButton.filled(
                key: const ValueKey('media-phrase-next'),
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
