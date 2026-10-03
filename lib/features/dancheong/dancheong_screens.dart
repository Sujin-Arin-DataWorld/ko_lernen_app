import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../screens/dojangcheop_screen.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import '../../widgets/sori/standard_page.dart';
import '../../widgets/sori/tokens.dart';
import 'dancheong_catalog.dart';
import 'dancheong_controller.dart';
import 'dancheong_models.dart';
import 'dancheong_publication_service.dart';
import 'dancheong_renderer.dart';
import 'dancheong_share_service.dart';
import 'dancheong_store.dart';
import 'dancheong_visitor_entry.dart';

enum DancheongStudioTab { patterns, artwork }

final class DancheongStudioArgs {
  const DancheongStudioArgs({this.tab = DancheongStudioTab.patterns});
  final DancheongStudioTab tab;
}

final class DancheongEditorArgs {
  const DancheongEditorArgs({
    this.draftId,
    this.sourceRevision,
    this.motifSlug,
    this.template,
  });
  final String? draftId;
  final int? sourceRevision;
  final String? motifSlug;
  final DancheongTemplate? template;
}

final class DancheongArtworkArgs {
  const DancheongArtworkArgs({required this.id, required this.revision});
  final String id;
  final int revision;
}

Set<String> _owned() => knownOwnedMotifs(Storage.earnedStamps);
String _borderName(AppL10n t, DancheongBorder border) => switch (border) {
  DancheongBorder.brocadeFlow => t.dancheongBorderFlow,
  DancheongBorder.colorRibbon => t.dancheongBorderRibbon,
  DancheongBorder.lotusScroll => t.dancheongBorderLotus,
  DancheongBorder.none => t.dancheongBorderNone,
};
String _templateName(AppL10n t, DancheongTemplate template) =>
    switch (template) {
      DancheongTemplate.flower => t.dancheongFlower,
      DancheongTemplate.brocade => t.dancheongBrocade,
      DancheongTemplate.letter => t.dancheongLetter,
    };
Widget _failure(BuildContext context, Object? error, DancheongStore store) {
  final t = AppL10n.of(context);
  final damaged =
      error is DancheongStoreFailure &&
      {
        DancheongStoreError.corrupt,
        DancheongStoreError.unsupported,
      }.contains(error.code);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        damaged
            ? t.dancheongDamaged
            : error is DancheongStoreFailure &&
                  error.code == DancheongStoreError.limit
            ? t.dancheongCapacity
            : t.dancheongBlocked,
      ),
      if (damaged)
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: Storage.dancheongStudioRawJson),
            );
          },
          child: Text(t.dancheongExportData),
        ),
    ],
  );
}

class DancheongStudioScreen extends StatefulWidget {
  const DancheongStudioScreen({
    super.key,
    this.arguments = const DancheongStudioArgs(),
    this.store,
  });
  final DancheongStudioArgs arguments;
  final DancheongStore? store;
  @override
  State<DancheongStudioScreen> createState() => _StudioState();
}

class _StudioState extends State<DancheongStudioScreen> {
  late final store = widget.store ?? DancheongStore();
  late final changes = store.changes;
  late var tab = widget.arguments.tab;
  final visitor = DancheongVisitorEntry.pending();
  bool deleting = false;
  Future<void> _delete({DancheongDraft? draft, DancheongArtwork? art}) async {
    if (deleting) {
      return;
    }
    final t = AppL10n.of(context);
    final guard = store.captureGuard();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.dancheongDelete),
        content: Text(
          art == null
              ? t.dancheongDeleteDraftNote
              : t.dancheongDeleteArtworkNote,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.dancheongPublicCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.dancheongDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => deleting = true);
    try {
      guard();
      if (draft != null) {
        await store.deleteDraft(draft.id);
      }
      if (art != null) {
        final publications = DancheongPublicationService(store: store);
        for (final format in DancheongFormat.values) {
          await publications.revokeFor(art.id, art.revision, format.name);
          guard();
        }
        await store.deleteArtwork(art.id, art.revision);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.dancheongError)));
      }
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    changes.addListener(_changed);
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    changes.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    DancheongOwnerDocument? owner;
    Object? error;
    try {
      owner = store.currentOwner();
    } catch (failure) {
      error = failure;
    }
    return SoriStandardFrame(
      appBarTitle: t.dancheongTitle,
      actions: const [CulturalHelpButton(termId: 'dancheong')],
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => ListView(
        padding: padding,
        children: [
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final value in DancheongStudioTab.values)
                ChoiceChip(
                  label: Text(
                    value == DancheongStudioTab.patterns
                        ? t.dancheongPatterns
                        : t.dancheongArtwork,
                  ),
                  selected: tab == value,
                  onSelected: (_) => setState(() => tab = value),
                ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          if (error != null)
            _failure(context, error, store)
          else ...[
            if (tab == DancheongStudioTab.patterns) ...[
              Text(t.dancheongIntro, style: SoriTextTheme.of(context).body),
              const SizedBox(height: Spacing.md),
              SoriButton.filled(
                key: const ValueKey('dancheong-create'),
                label: t.dancheongCreate,
                fullWidth: true,
                onTap: _owned().isEmpty || owner!.drafts.length >= 30
                    ? null
                    : () => Navigator.of(context).pushNamed(
                        '/dancheong-studio/edit',
                        arguments: DancheongEditorArgs(
                          template: visitor?.template,
                        ),
                      ),
              ),
              if (owner!.drafts.length >= 30) ...[
                Text(t.dancheongCapacity),
                TextButton(
                  onPressed: () =>
                      setState(() => tab = DancheongStudioTab.artwork),
                  child: Text(t.dancheongManage),
                ),
              ],
              if (_owned().isEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(t.dancheongFirstMaterial),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/path'),
                  child: Text(t.dancheongLearn),
                ),
              ],
              const SizedBox(height: Spacing.lg),
              const DojangcheopScreen(embedded: true),
              const SizedBox(height: Spacing.lg),
              Text(t.dancheongExamples, style: SoriTextTheme.of(context).h3),
              const SizedBox(height: Spacing.sm),
              Text(t.dancheongExampleNote),
              for (final path in [
                dancheongExamplePatternAsset,
                dancheongExampleLetterAsset,
              ]) ...[
                const SizedBox(height: Spacing.md),
                SizedBox(
                  height: 280,
                  child: Image.asset(
                    path,
                    fit: BoxFit.contain,
                    semanticLabel: t.dancheongExamples,
                  ),
                ),
              ],
            ] else ...[
              if (owner!.drafts.isEmpty && owner.artworks.isEmpty)
                Text(t.dancheongEmptyArtwork),
              for (final draft in owner.drafts.reversed) ...[
                SoriCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _templateName(t, draft.composition.template),
                        style: SoriTextTheme.of(context).h3,
                      ),
                      SoriButton.outlined(
                        label: t.dancheongDraft,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/dancheong-studio/edit',
                          arguments: DancheongEditorArgs(draftId: draft.id),
                        ),
                      ),
                      TextButton(
                        key: ValueKey('delete-draft-${draft.id}'),
                        onPressed: deleting
                            ? null
                            : () => _delete(draft: draft),
                        child: Text(t.dancheongDelete),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],
              for (final art in owner.artworks.reversed) ...[
                SoriCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 220,
                        child: DancheongArtworkView(
                          composition: art.composition,
                          ownedSlugs: _owned(),
                        ),
                      ),
                      Text(
                        _templateName(t, art.composition.template),
                        style: SoriTextTheme.of(context).h3,
                      ),
                      SoriButton.outlined(
                        label: t.dancheongArtwork,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/dancheong-artwork',
                          arguments: DancheongArtworkArgs(
                            id: art.id,
                            revision: art.revision,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: deleting ? null : () => _delete(art: art),
                        child: Text(t.dancheongDelete),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class DancheongEditorScreen extends StatefulWidget {
  const DancheongEditorScreen({
    super.key,
    required this.arguments,
    this.store,
    this.owned,
  });
  final DancheongEditorArgs arguments;
  final DancheongStore? store;
  final Set<String> Function()? owned;
  @override
  State<DancheongEditorScreen> createState() => _EditorState();
}

class _EditorState extends State<DancheongEditorScreen>
    with WidgetsBindingObserver {
  late final store = widget.store ?? DancheongStore();
  DancheongController? controller;
  Object? initializationError;
  bool canPop = false;
  bool leaving = false;
  Set<String> get owned => (widget.owned ?? _owned)();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      controller = DancheongController(
        store: store,
        owned: widget.owned ?? _owned,
        draftId: widget.arguments.draftId,
        sourceRevision: widget.arguments.sourceRevision,
        motifSlug: widget.arguments.motifSlug,
        template: widget.arguments.template,
      )..addListener(_changed);
    } catch (error) {
      initializationError = error;
      canPop = true;
    }
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_save());
    }
  }

  Future<bool> _save() async {
    try {
      await controller?.flush();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _leave() async {
    if (leaving || controller?.busy == true) {
      return;
    }
    leaving = true;
    var saved = controller?.isCurrent == false || await _save();
    if (mounted && !saved) {
      final t = AppL10n.of(context);
      saved =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(t.dancheongLeaveTitle),
              content: Text(t.dancheongLeaveNote),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(t.dancheongPublicCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(t.dancheongLeave),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (mounted && saved) {
      setState(() => canPop = true);
      Navigator.of(context).pop();
    }
    leaving = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.removeListener(_changed);
    controller?.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final art = await controller!.finish();
      if (mounted && controller!.isCurrent) {
        setState(() => canPop = true);
        await Navigator.of(context).pushReplacementNamed(
          '/dancheong-artwork',
          arguments: DancheongArtworkArgs(id: art.id, revision: art.revision),
        );
      }
    } catch (_) {
      /* Controller retains input and exposes error. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final c = controller;
    final valid = c != null && c.isCurrent;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_leave());
        }
      },
      child: SoriStandardFrame(
        appBarTitle: t.dancheongEditor,
        showHome: false,
        padding: const EdgeInsets.all(Spacing.lg),
        builder: (context, padding) {
          if (!valid) {
            return Padding(
              padding: padding,
              child: _failure(context, initializationError, store),
            );
          }
          final composition = c.composition;
          return ListView(
            padding: padding,
            children: [
              SizedBox(
                height: 330,
                child: DancheongArtworkView(
                  composition: composition,
                  ownedSlugs: owned,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(t.dancheongTemplate, style: SoriTextTheme.of(context).h3),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in DancheongTemplate.values)
                    ChoiceChip(
                      label: Text(_templateName(t, value)),
                      selected: composition.template == value,
                      onSelected: c.busy
                          ? null
                          : (_) =>
                                c.update(composition.copyWith(template: value)),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(t.dancheongBorder, style: SoriTextTheme.of(context).h3),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final border in DancheongBorder.values)
                    ChoiceChip(
                      key: ValueKey('dancheong-border-${border.name}'),
                      label: Text(_borderName(t, border)),
                      selected: composition.border == border,
                      onSelected: c.busy
                          ? null
                          : (_) =>
                                c.update(composition.copyWith(border: border)),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(t.dancheongFrameNote),
              const SizedBox(height: Spacing.md),
              Text(t.dancheongFormat),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in DancheongFormat.values)
                    ChoiceChip(
                      label: Text(
                        value == DancheongFormat.portrait
                            ? t.dancheongPortrait
                            : t.dancheongStory,
                      ),
                      selected: composition.format == value,
                      onSelected: c.busy
                          ? null
                          : (_) =>
                                c.update(composition.copyWith(format: value)),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(t.dancheongMaterials),
              if (owned.isEmpty) Text(t.dancheongFirstMaterial),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final motif in DancheongMotif.values.where(
                    (m) => owned.contains(m.name),
                  ))
                    FilterChip(
                      avatar: Image.asset(
                        motif.spec.assetPath,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      label: Text(motif.spec.localizedName(t)),
                      selected: composition.motifSlugs.contains(motif.name),
                      onSelected: c.busy
                          ? null
                          : (selected) {
                              final slugs = [...composition.motifSlugs];
                              if (selected) {
                                if (slugs.length >= 4) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.dancheongLimit)),
                                  );
                                  return;
                                }
                                slugs.add(motif.name);
                              } else {
                                slugs.remove(motif.name);
                              }
                              c.update(composition.copyWith(motifSlugs: slugs));
                            },
                    ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              TextFormField(
                key: const ValueKey('dancheong-korean-text'),
                initialValue: composition.koreanText,
                enabled: !c.busy,
                maxLength: 80,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: t.dancheongKoreanText,
                  alignLabelWithHint: true,
                ),
                onChanged: (value) =>
                    c.update(c.composition.copyWith(koreanText: value)),
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                initialValue: composition.translation,
                enabled: !c.busy,
                maxLength: 160,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: t.dancheongTranslation,
                  alignLabelWithHint: true,
                ),
                onChanged: (value) =>
                    c.update(c.composition.copyWith(translation: value)),
              ),
              const SizedBox(height: Spacing.sm),
              Text(t.dancheongTranslationLanguage),
              Wrap(
                spacing: 8,
                children: [
                  for (final code in ['de', 'en'])
                    ChoiceChip(
                      label: Text(code == 'de' ? 'Deutsch' : 'English'),
                      selected: (composition.translationLocale ?? 'de') == code,
                      onSelected: c.busy
                          ? null
                          : (_) => c.update(
                              composition.copyWith(translationLocale: code),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              TextFormField(
                initialValue: composition.signature,
                enabled: !c.busy,
                maxLength: 40,
                decoration: InputDecoration(labelText: t.dancheongSignature),
                onChanged: (value) =>
                    c.update(c.composition.copyWith(signature: value)),
              ),
              const SizedBox(height: Spacing.md),
              if (c.error != null)
                Text(
                  c.error is DancheongTextFitFailure
                      ? t.dancheongTextFit
                      : c.error is DancheongStoreFailure &&
                            (c.error as DancheongStoreFailure).code ==
                                DancheongStoreError.limit
                      ? t.dancheongCapacity
                      : t.dancheongError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                Text(c.saved ? t.dancheongSaved : t.dancheongSaving),
              const SizedBox(height: Spacing.md),
              SoriButton.outlined(
                label: t.dancheongSaveDraft,
                onTap: c.busy ? null : () => unawaited(_save()),
                fullWidth: true,
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.filled(
                key: const ValueKey('dancheong-finish'),
                label: t.dancheongFinish,
                loading: c.busy,
                onTap:
                    composition.motifSlugs.isEmpty ||
                        !composition.motifSlugs.every(owned.contains)
                    ? null
                    : _finish,
                fullWidth: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DancheongArtworkScreen extends StatefulWidget {
  const DancheongArtworkScreen({
    super.key,
    required this.arguments,
    this.store,
  });
  final DancheongArtworkArgs arguments;
  final DancheongStore? store;
  @override
  State<DancheongArtworkScreen> createState() => _ArtworkState();
}

class _ArtworkState extends State<DancheongArtworkScreen> {
  late final store = widget.store ?? DancheongStore();
  late final changes = store.changes;
  @override
  void initState() {
    super.initState();
    changes.addListener(_changed);
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    changes.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    DancheongArtwork? art;
    Object? error;
    try {
      art = store
          .currentOwner()
          .artworks
          .where(
            (a) =>
                a.id == widget.arguments.id &&
                a.revision == widget.arguments.revision,
          )
          .firstOrNull;
    } catch (failure) {
      error = failure;
    }
    final artwork = art;
    return SoriStandardFrame(
      appBarTitle: t.dancheongArtwork,
      padding: const EdgeInsets.all(Spacing.lg),
      builder: (context, padding) => ListView(
        padding: padding,
        children: [
          if (error != null)
            _failure(context, error, store)
          else if (artwork == null)
            Text(t.dancheongMissing)
          else ...[
            DancheongArtworkView(
              composition: artwork.composition,
              ownedSlugs: _owned(),
            ),
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              label: t.dancheongShare,
              fullWidth: true,
              onTap: () => Navigator.of(
                context,
              ).pushNamed('/dancheong-share', arguments: widget.arguments),
            ),
            const SizedBox(height: Spacing.sm),
            SoriButton.outlined(
              label: t.dancheongEdit,
              fullWidth: true,
              onTap: () => Navigator.of(context).pushNamed(
                '/dancheong-studio/edit',
                arguments: DancheongEditorArgs(
                  draftId: artwork.id,
                  sourceRevision: artwork.revision,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DancheongShareScreen extends StatefulWidget {
  const DancheongShareScreen({super.key, required this.arguments, this.store});
  final DancheongArtworkArgs arguments;
  final DancheongStore? store;
  @override
  State<DancheongShareScreen> createState() => _ShareState();
}

class _ShareState extends State<DancheongShareScreen>
    with WidgetsBindingObserver {
  late final store = widget.store ?? DancheongStore();
  late final publication = DancheongPublicationService(store: store);
  late final changes = store.changes;
  final caption = TextEditingController();
  final shareButton = GlobalKey();
  DancheongCaptionLocale language = DancheongCaptionLocale.de;
  DancheongFormat? format;
  String? activeCaptionKey;
  Timer? timer;
  bool busy = false;
  bool canPop = false;
  String? status;
  void Function()? identityGuard;
  Object? identityError;
  @override
  void initState() {
    super.initState();
    try {
      identityGuard = store.captureGuard();
    } catch (error) {
      identityError = error;
    }
    changes.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_saveCaption().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    caption.dispose();
    changes.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _saveCaption() async {
    timer?.cancel();
    if (activeCaptionKey == null) {
      return;
    }
    try {
      if (identityGuard == null) {
        throw const DancheongStoreFailure(DancheongStoreError.blocked);
      }
      identityGuard!();
      await store.saveCaption(activeCaptionKey!, caption.text);
      identityGuard!();
    } catch (_) {
      if (mounted) {
        setState(() => status = AppL10n.of(context).dancheongError);
      }
      rethrow;
    }
  }

  Future<void> _choose(DancheongCaptionLocale next) async {
    try {
      await _saveCaption();
      if (mounted) {
        setState(() {
          language = next;
          activeCaptionKey = null;
        });
      }
    } catch (_) {
      /* Preserve failed caption input. */
    }
  }

  Future<void> _image(DancheongArtwork art, {bool download = false}) async {
    final t = AppL10n.of(context);
    setState(() => busy = true);
    try {
      final guard = store.captureGuard();
      await _saveCaption();
      guard();
      final package = await DancheongRenderer().render(
        art,
        ownedSlugs: _owned(),
        assertCurrent: guard,
      );
      guard();
      if (!mounted) {
        return;
      }
      if (download) {
        await DancheongShareService().saveImage(package);
        guard();
      } else {
        final box =
            shareButton.currentContext!.findRenderObject()! as RenderBox;
        final outcome = await DancheongShareService().shareImage(
          package,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
        guard();
        if (mounted) {
          setState(
            () => status = switch (outcome) {
              DancheongShareOutcome.handedOff => t.dancheongHandedOff,
              DancheongShareOutcome.dismissed => t.dancheongDismissed,
              DancheongShareOutcome.unavailable => t.dancheongUnavailable,
              DancheongShareOutcome.failed => t.dancheongError,
            },
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => status = t.dancheongError);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _publish(DancheongArtwork art) async {
    final t = AppL10n.of(context);
    setState(() => busy = true);
    try {
      identityGuard!();
      await _saveCaption();
      final package = await DancheongRenderer().render(
        art,
        ownedSlugs: _owned(),
        assertCurrent: identityGuard,
      );
      identityGuard!();
      if (!mounted) {
        return;
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.dancheongPublicTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  child: Image.memory(package.png, fit: BoxFit.contain),
                ),
                const SizedBox(height: Spacing.md),
                Text(t.dancheongPublicBody),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.dancheongPublicCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.dancheongPublicConfirm),
            ),
          ],
        ),
      );
      identityGuard!();
      if (approved != true || !mounted) {
        return;
      }
      await publication.publish(package);
      identityGuard!();
      if (mounted) {
        setState(() => status = t.dancheongPublicReady);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => status =
              error is FormatException &&
                  error.message == 'public-image-too-large'
              ? t.dancheongPublicTooLarge
              : t.dancheongError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> _revoke(DancheongArtwork art) async {
    final t = AppL10n.of(context);
    setState(() => busy = true);
    try {
      identityGuard!();
      await publication.revokeFor(art.id, art.revision, format!.name);
      identityGuard!();
      if (mounted) {
        setState(() => status = t.dancheongPublicRevoked);
      }
    } catch (_) {
      if (mounted) {
        setState(() => status = t.dancheongError);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    DancheongOwnerDocument? owner;
    Object? error;
    try {
      if (identityError != null) {
        throw identityError!;
      }
      identityGuard!();
      owner = store.currentOwner();
    } catch (failure) {
      error = failure;
    }
    final art = owner?.artworks
        .where(
          (a) =>
              a.id == widget.arguments.id &&
              a.revision == widget.arguments.revision,
        )
        .firstOrNull;
    Map<String, Object?>? publicAttempt;
    if (art != null && error == null) {
      try {
        publicAttempt = publication.currentFor(
          art.id,
          art.revision,
          (format ?? art.composition.format).name,
        );
      } catch (_) {
        /* Preserve invalid publication data; private export stays available. */
      }
    }
    final publicId = publicAttempt?['status'] == 'active'
        ? publicAttempt!['shareId'] as String
        : null;
    if (art != null) {
      format ??= art.composition.format;
      final key = captionKey(
        artworkId: art.id,
        revision: art.revision,
        format: format!,
        locale: language,
      );
      if (key != activeCaptionKey) {
        activeCaptionKey = key;
        caption.text = owner!.captions.containsKey(key)
            ? owner.captions[key]!
            : lookupAppL10n(Locale(language.name)).dancheongDefaultCaption;
      }
    }
    return PopScope(
      canPop: canPop || error != null || art == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        try {
          await _saveCaption();
          if (mounted) {
            setState(() => canPop = true);
            Navigator.of(this.context).pop();
          }
        } catch (_) {
          /* Keep unsaved text. */
        }
      },
      child: SoriStandardFrame(
        appBarTitle: t.dancheongShareTitle,
        showHome: false,
        padding: const EdgeInsets.all(Spacing.lg),
        builder: (context, padding) => ListView(
          padding: padding,
          children: [
            if (error != null)
              _failure(context, error, store)
            else if (art == null)
              Text(t.dancheongMissing)
            else ...[
              SizedBox(
                height: 340,
                child: DancheongArtworkView(
                  composition: art.composition.copyWith(format: format),
                  ownedSlugs: _owned(),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(t.dancheongShareNote),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in DancheongFormat.values)
                    ChoiceChip(
                      label: Text(
                        value == DancheongFormat.portrait
                            ? t.dancheongPortrait
                            : t.dancheongStory,
                      ),
                      selected: format == value,
                      onSelected: busy
                          ? null
                          : (_) async {
                              try {
                                await _saveCaption();
                                if (mounted) {
                                  setState(() {
                                    format = value;
                                    activeCaptionKey = null;
                                  });
                                }
                              } catch (_) {}
                            },
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(t.dancheongCaptionLanguage),
              Wrap(
                spacing: 8,
                children: [
                  for (final locale in DancheongCaptionLocale.values)
                    ChoiceChip(
                      label: Text(
                        locale == DancheongCaptionLocale.de
                            ? 'Deutsch'
                            : 'English',
                      ),
                      selected: language == locale,
                      onSelected: busy
                          ? null
                          : (_) => unawaited(_choose(locale)),
                    ),
                ],
              ),
              TextField(
                controller: caption,
                maxLength: 2200,
                maxLines: null,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: t.dancheongCaption,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  timer?.cancel();
                  timer = Timer(const Duration(milliseconds: 400), () async {
                    try {
                      await _saveCaption();
                    } catch (_) {}
                  });
                },
              ),
              SoriButton.outlined(
                label: t.dancheongCopyCaption,
                fullWidth: true,
                onTap: busy
                    ? null
                    : () async {
                        try {
                          final guard = store.captureGuard();
                          await _saveCaption();
                          guard();
                          await Clipboard.setData(
                            ClipboardData(text: caption.text),
                          );
                          guard();
                          if (mounted) {
                            setState(() => status = t.dancheongCopied);
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(() => status = t.dancheongError);
                          }
                        }
                      },
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton.filled(
                key: shareButton,
                label: t.dancheongShareImage,
                loading: busy,
                fullWidth: true,
                onTap: () => _image(
                  DancheongArtwork(
                    id: art.id,
                    revision: art.revision,
                    composition: art.composition.copyWith(format: format),
                    completedAt: art.completedAt,
                  ),
                ),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.dancheongDownload,
                  fullWidth: true,
                  onTap: busy
                      ? null
                      : () => _image(
                          DancheongArtwork(
                            id: art.id,
                            revision: art.revision,
                            composition: art.composition.copyWith(
                              format: format,
                            ),
                            completedAt: art.completedAt,
                          ),
                          download: true,
                        ),
                ),
              ],
              if (status != null) ...[
                const SizedBox(height: Spacing.md),
                Text(status!, key: const ValueKey('dancheong-share-status')),
              ],
              const SizedBox(height: Spacing.lg),
              if (publicId == null)
                SoriButton.outlined(
                  label: t.dancheongPublicAction,
                  fullWidth: true,
                  onTap: busy || publicAttempt?['status'] == 'revoked'
                      ? null
                      : () => _publish(
                          DancheongArtwork(
                            id: art.id,
                            revision: art.revision,
                            composition: art.composition.copyWith(
                              format: format,
                            ),
                            completedAt: art.completedAt,
                          ),
                        ),
                )
              else ...[
                SoriButton.outlined(
                  label: t.dancheongPublicCopy,
                  fullWidth: true,
                  onTap: busy
                      ? null
                      : () async {
                          try {
                            identityGuard!();
                            final link = Uri.https(
                              'hangul-sori.com',
                              '/art/$publicId',
                              {'lang': language.name},
                            );
                            await Clipboard.setData(
                              ClipboardData(text: link.toString()),
                            );
                            identityGuard!();
                            if (mounted) {
                              setState(() => status = t.dancheongCopied);
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(() => status = t.dancheongError);
                            }
                          }
                        },
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton.outlined(
                  label: t.dancheongPublicRevoke,
                  fullWidth: true,
                  onTap: busy ? null : () => _revoke(art),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
