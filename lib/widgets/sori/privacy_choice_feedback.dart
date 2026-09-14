import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/privacy_consent_service.dart';
import '../../services/storage_service.dart';
import 'button.dart';
import 'dialog.dart';

/// Settings uses the same pending/native/SDK authority as admission consumers.
class PrivacyChoiceControl extends StatefulWidget {
  const PrivacyChoiceControl({
    super.key,
    required this.purpose,
    required this.title,
    required this.description,
    required this.icon,
  });
  final PrivacyPurpose purpose;
  final String title;
  final String description;
  final IconData icon;
  @override
  State<PrivacyChoiceControl> createState() => _PrivacyChoiceControlState();
}

class _PrivacyChoiceControlState extends State<PrivacyChoiceControl> {
  bool _failed = false;
  bool _dialogOpen = false;
  int _epoch = PrivacyChoiceStorage.epoch;
  int _revision = 0;
  bool? _requested;
  @override
  void initState() {
    super.initState();
    PrivacyConsentService.changes.addListener(_changed);
    PrivacyChoiceStorage.changes.addListener(_changed);
  }

  void _changed() {
    if (!mounted) {
      return;
    }
    if (_epoch != PrivacyChoiceStorage.epoch) {
      _epoch = PrivacyChoiceStorage.epoch;
      _revision++;
      _requested = null;
      _failed = false;
    } else if (_requested case final selected?
        when PrivacyConsentService.isChoiceSettled(widget.purpose, selected)) {
      _failed = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    PrivacyConsentService.changes.removeListener(_changed);
    PrivacyChoiceStorage.changes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _set(bool enabled) async {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final epoch = PrivacyChoiceStorage.epoch;
    _epoch = epoch;
    final revision = ++_revision;
    _requested = enabled;
    if (enabled && widget.purpose == PrivacyPurpose.pronunciation) {
      if (_dialogOpen) {
        return;
      }
      _dialogOpen = true;
      try {
        await ensurePronunciationPrivacyConsent(context);
      } finally {
        _dialogOpen = false;
      }
      return;
    }
    setState(() => _failed = false);
    try {
      await PrivacyConsentService.setChoice(widget.purpose, enabled);
    } on Object {
      if (mounted &&
          epoch == PrivacyChoiceStorage.epoch &&
          revision == _revision &&
          !PrivacyConsentService.isChoiceSettled(widget.purpose, enabled)) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = PrivacyChoiceStorage.choice(widget.purpose);
    final status = PrivacyConsentService.status(widget.purpose);
    final selected = state.desired as bool? ?? state.confirmed == true;
    final pending = state.pending || status == PrivacyApplicationStatus.pending;
    final failed =
        _failed ||
        state.failed ||
        status == PrivacyApplicationStatus.retryRequired;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: ValueKey('privacy-choice-${widget.purpose.name}'),
          secondary: Icon(widget.icon),
          title: Text(widget.title),
          subtitle: Text(widget.description),
          value: selected,
          onChanged: _set,
        ),
        if (pending || failed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrivacyChoiceFeedback(
              pending: pending && !failed,
              withdrawal: !selected,
              selectionSaved:
                  !state.pending &&
                  !state.failed &&
                  state.confirmed == selected,
              onRetry: () => _set(selected),
            ),
          ),
      ],
    );
  }
}

class PrivacyChoiceFeedback extends StatelessWidget {
  const PrivacyChoiceFeedback({
    super.key,
    required this.pending,
    required this.withdrawal,
    required this.onRetry,
    this.selectionSaved = false,
  });
  final bool selectionSaved;
  final bool pending;
  final bool withdrawal;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            pending
                ? t.privacyChoicePending
                : selectionSaved
                ? t.privacyApplicationUnconfirmed
                : withdrawal
                ? t.privacyWithdrawalUnconfirmed
                : t.privacyChoiceUnconfirmed,
          ),
        ),
        if (!pending)
          SoriButton.ghost(
            label: t.btnRetry,
            size: SoriButtonSize.md,
            onTap: onRetry,
          ),
      ],
    );
  }
}

Future<bool> ensurePronunciationPrivacyConsent(BuildContext context) async {
  if (PrivacyConsentService.canSubmitPronunciation) {
    return true;
  }
  return await showSoriDialog<bool>(
        context: context,
        builder: (_) => const _PronunciationPrivacyDialog(),
      ) ??
      false;
}

class _PronunciationPrivacyDialog extends StatefulWidget {
  const _PronunciationPrivacyDialog();
  @override
  State<_PronunciationPrivacyDialog> createState() =>
      _PronunciationPrivacyDialogState();
}

class _PronunciationPrivacyDialogState
    extends State<_PronunciationPrivacyDialog> {
  int _epoch = PrivacyChoiceStorage.epoch;
  int _revision = 0;
  bool _saving = false;
  bool _failed = false;
  bool _desired = true;
  @override
  void initState() {
    super.initState();
    PrivacyChoiceStorage.changes.addListener(_changed);
    PrivacyConsentService.changes.addListener(_changed);
  }

  void _changed() {
    if (!mounted) {
      return;
    }
    if (_epoch != PrivacyChoiceStorage.epoch) {
      _epoch = PrivacyChoiceStorage.epoch;
      _revision++;
      _saving = false;
      _failed = false;
    } else if (PrivacyConsentService.isChoiceSettled(
      PrivacyPurpose.pronunciation,
      _desired,
    )) {
      _failed = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    PrivacyChoiceStorage.changes.removeListener(_changed);
    PrivacyConsentService.changes.removeListener(_changed);
    super.dispose();
  }

  Future<void> _save(bool desired) async {
    if (ModalRoute.of(context)?.isCurrent != true ||
        (_saving && _desired == desired)) {
      return;
    }
    final epoch = PrivacyChoiceStorage.epoch;
    _epoch = epoch;
    final revision = ++_revision;
    setState(() {
      _saving = true;
      _failed = false;
      _desired = desired;
    });
    try {
      await PrivacyConsentService.setChoice(
        PrivacyPurpose.pronunciation,
        desired,
      );
      if (!mounted ||
          epoch != PrivacyChoiceStorage.epoch ||
          revision != _revision ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      Navigator.of(
        context,
      ).pop(desired && PrivacyConsentService.canSubmitPronunciation);
    } on Object {
      if (mounted &&
          epoch == PrivacyChoiceStorage.epoch &&
          revision == _revision &&
          !PrivacyConsentService.isChoiceSettled(
            PrivacyPurpose.pronunciation,
            desired,
          )) {
        setState(() {
          _failed = true;
        });
      }
    } finally {
      if (mounted && revision == _revision) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriDialog(
      title: Text(t.pronunciationConsentTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.pronunciationConsentBody),
          if (_saving || _failed)
            PrivacyChoiceFeedback(
              pending: _saving,
              withdrawal: !_desired,
              onRetry: () => _save(_desired),
            ),
        ],
      ),
      actions: [
        SoriButton.outlined(
          label: t.pronunciationConsentDecline,
          size: SoriButtonSize.md,
          onTap: () => _save(false),
        ),
        SoriButton.filled(
          label: t.pronunciationConsentAccept,
          size: SoriButtonSize.md,
          onTap: _saving ? null : () => _save(true),
        ),
      ],
    );
  }
}
