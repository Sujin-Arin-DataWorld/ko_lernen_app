import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../services/auth_service.dart';
import '../services/account/account_transition_coordinator.dart';
import '../services/account/account_ui_operations.dart';
import '../services/account/cloud_backup_deletion.dart';
import '../services/account/cloud_write_session.dart';
import '../services/storage_service.dart';
import '../services/course_progress_service.dart';
import '../services/gye_service.dart';
import '../services/learning_data_export_service.dart';
import '../data/learner_motivation.dart';
import '../models/gye.dart';
import '../models/scenario.dart';
import '../widgets/sori/motivation_sheet.dart';
import '../widgets/sori/account_operation_ui.dart';
import '../l10n/generated/app_localizations.dart';
import 'settings_screen.dart';

String _providerLabel(AppL10n t, AuthProviderState providers) {
  if (providers.isGoogleLinked && providers.isAppleLinked) {
    return t.authProviderGoogleAndApple;
  }
  if (providers.isAppleLinked) {
    return t.authProviderApple;
  }
  return t.authProviderGoogle;
}

/// **ProfileScreen** (`/profile`) — Identitäts- & Konto-Hub.
///
/// Duolingo-Muster: anonymer Start, aber das Konto ist *sichtbar* und lädt
/// aktiv zum Sichern ein (statt versteckt in den Einstellungen). Tiefen-
/// Statistik bleibt in [StatsScreen] (`/stats`); hier nur Identität,
/// Konto-Status und eine Kurz-Übersicht (Streak · Level · Vokabeln).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.account,
    this.accountOperations,
    this.cloudDataDeletionJournalState,
    this.cloudDataDeletion,
    this.loadGyeMetas,
    this.exportLearningData,
    this.initializePlacement,
    this.previewMode = false,
    this.previewMotivation,
    this.previewLevel,
    this.previewCompanion,
    this.onChangeMotivation,
    this.onChangeStartPoint,
    this.onChangeCompanion,
    this.onOpenAccountControls,
    this.onOpenGye,
    this.onOpenAccountDeletion,
    this.enableCoach = true,
  });

  /// Production Profile surface with every mutating action disabled and all
  /// asynchronous account/group state supplied by the Gallery.
  const ProfileScreen.preview({
    super.key,
    required this.accountOperations,
    required this.cloudDataDeletionJournalState,
    required this.loadGyeMetas,
    this.account = const AuthAccountSnapshot(
      providers: AuthProviderState(isGoogleLinked: false, isAppleLinked: false),
      displayName: 'Vorschau',
    ),
    this.previewMotivation,
    this.previewLevel,
    this.previewCompanion,
    this.onChangeMotivation,
    this.onChangeStartPoint,
    this.onChangeCompanion,
  }) : cloudDataDeletion = null,
       exportLearningData = null,
       initializePlacement = null,
       onOpenAccountControls = null,
       onOpenGye = null,
       onOpenAccountDeletion = null,
       enableCoach = false,
       previewMode = true;

  final AuthAccountSnapshot? account;
  final AccountUiOperations? accountOperations;
  final ValueListenable<CloudBackupDeletionJournalState>?
  cloudDataDeletionJournalState;
  final Future<CloudWriteResult> Function()? cloudDataDeletion;
  final Future<List<GyeMeta>> Function()? loadGyeMetas;
  final Future<void> Function()? exportLearningData;
  final Future<void> Function(String levelCode)? initializePlacement;
  final bool previewMode;
  final LearnerMotivation? previewMotivation;
  final LearnerLevel? previewLevel;
  final CompanionPreference? previewCompanion;
  final VoidCallback? onChangeMotivation;
  final VoidCallback? onChangeStartPoint;
  final VoidCallback? onChangeCompanion;
  final VoidCallback? onOpenAccountControls;
  final VoidCallback? onOpenGye;
  final VoidCallback? onOpenAccountDeletion;
  final bool enableCoach;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with ScreenCoachMixin<ProfileScreen> {
  bool _busy = false;
  bool _exportBusy = false;
  late final Future<List<GyeMeta>> _gyeMetas;

  AccountUiOperations get _accountOperations =>
      widget.accountOperations ?? const ProductionAccountUiOperations();

  ValueListenable<CloudBackupDeletionJournalState>
  get _cloudDataDeletionJournalState =>
      widget.cloudDataDeletionJournalState ??
      AuthService.cloudBackupDeletionJournalState;

  // ── 코치마크 타겟 ──
  final GlobalKey _accountCardKey = GlobalKey();

  @override
  String get coachId => 'profile';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _accountCardKey,
        title: t.coachProfileTitle,
        body: t.coachProfileBody,
        icon: Icons.cloud_upload_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final loadGyeMetas = widget.loadGyeMetas;
    _gyeMetas = loadGyeMetas != null
        ? loadGyeMetas()
        : widget.previewMode
        ? Future<List<GyeMeta>>.value(const <GyeMeta>[])
        : GyeService.myGyeMetas();
    if (widget.enableCoach) scheduleCoach();
    if (!widget.previewMode && widget.cloudDataDeletionJournalState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AuthService.refreshCloudBackupDeletionJournalState();
      });
    }
  }

  Future<void> _connectWith(AccountLinkProvider provider) async {
    if (widget.previewMode) return;
    setState(() => _busy = true);
    try {
      await runConfirmedAccountLink(
        context,
        operations: _accountOperations,
        provider: provider,
        onCompleted: () async {
          if (mounted) setState(() {});
        },
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (widget.previewMode) return;
    try {
      await AuthService.signOut();
    } catch (_) {
      // signOut bricht still ab, wenn Firebase nicht verfügbar ist.
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resumeCloudDeletion() async {
    if (widget.previewMode) return;
    await (widget.cloudDataDeletion ?? AuthService.deleteCloudData)();
    if (mounted) {
      setState(() {});
    }
  }

  /// Locked account cards route taps here instead of rendering dead buttons.
  Future<void> _showActionLocked(
    CloudBackupDeletionJournalState cloudDeletionState,
  ) {
    if (widget.previewMode) return Future<void>.value();
    return showAccountActionLocked(
      context,
      operations: _accountOperations,
      cloudDeletionState: cloudDeletionState,
      resumeCloudDeletion: _resumeCloudDeletion,
    );
  }

  Future<void> _changeMotivation() async {
    if (widget.previewMode) {
      widget.onChangeMotivation?.call();
      return;
    }
    await showMotivationSheet(context);
    if (mounted) {
      setState(() {});
    }
  }

  LearnerLevel get _learningStartPoint =>
      widget.previewLevel ??
      LearnerLevel.fromCode(Storage.dedicatedCoursePlacementLevelCode) ??
      LearnerLevel.fromCode(Storage.userLevelCode) ??
      LearnerLevel.a1;

  String _levelLabel(AppL10n t) => _levelName(t, _learningStartPoint);

  String _levelName(AppL10n t, LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => '${level.display} (${t.onboardingLevelA1})',
    LearnerLevel.a2 => '${level.display} (${t.onboardingLevelA2})',
    LearnerLevel.b1 => '${level.display} (${t.onboardingLevelB1})',
    LearnerLevel.b2 => '${level.display} (${t.onboardingLevelB2})',
  };

  Future<void> _changeLevel() async {
    if (widget.previewMode) {
      widget.onChangeStartPoint?.call();
      return;
    }
    final t = AppL10n.of(context);
    final current = _learningStartPoint;
    final selected = await showDialog<LearnerLevel>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.profileLearningStartPoint),
        children: [
          for (final level in LearnerLevel.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(level),
              child: Row(
                children: [
                  Icon(
                    level == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: level == current
                        ? SoriColors.primary
                        : SoriSurfaces.of(context).textMuted,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: Text(_levelName(t, level))),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) {
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.profileLearningStartPointConfirmTitle),
        content: Text(t.profileLearningStartPointConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.profileLearningStartPointConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.profileLearningStartPointConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final initializePlacement = widget.initializePlacement;
      if (initializePlacement != null) {
        await initializePlacement(selected.code);
      } else {
        await CourseProgressService.shared.initializeForPlacement(
          selected.code,
          syncBrowseLevel: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Profile start-point change failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.profileLearningStartPointChangeFailed)),
        );
      }
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeCompanion() async {
    if (widget.previewMode) {
      widget.onChangeCompanion?.call();
      return;
    }
    final t = AppL10n.of(context);
    final current = MascotPreference.preference.value;
    const options = <CompanionPreference>[
      CompanionPreference.tiger,
      CompanionPreference.magpie,
      CompanionPreference.none,
    ];
    final selected = await showDialog<CompanionPreference>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(t.characterSelectionTitle),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(option),
              child: Row(
                children: [
                  if (MascotPreference.mascotKindFor(option) case final kind?)
                    Mascot(kind: kind, size: 42)
                  else
                    const SizedBox.square(
                      dimension: 42,
                      child: Icon(Icons.person_outline_rounded),
                    ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(switch (option) {
                          CompanionPreference.none => t.companionNoneName,
                          CompanionPreference.tiger => t.characterNameTiger,
                          CompanionPreference.magpie => t.characterRomanMagpie,
                        }),
                        Text(switch (option) {
                          CompanionPreference.none =>
                            t.companionNoneDescription,
                          CompanionPreference.tiger => t.characterTraitTiger,
                          CompanionPreference.magpie => t.characterTraitMagpie,
                        }, style: SoriTextTheme.of(context).caption),
                      ],
                    ),
                  ),
                  if (option == current)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: SoriColors.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      final kind = MascotPreference.mascotKindFor(selected);
      if (kind == null) {
        await MascotPreference.setNone();
      } else {
        await MascotPreference.set(kind);
      }
    }
  }

  Future<void> _openAccountControls() async {
    final override = widget.onOpenAccountControls;
    if (override != null) {
      override();
      return;
    }
    if (widget.previewMode) return;
    await Navigator.of(
      context,
    ).pushNamed('/settings', arguments: SettingsInitialFocus.account);
    if (mounted) {
      setState(() {});
    }
  }

  void _openGye() {
    final override = widget.onOpenGye;
    if (override != null) {
      override();
      return;
    }
    if (widget.previewMode) return;
    Navigator.pushNamed(context, '/gye/hub');
  }

  void _openAccountDeletion() {
    final override = widget.onOpenAccountDeletion;
    if (override != null) {
      override();
      return;
    }
    if (widget.previewMode) return;
    Navigator.of(
      context,
    ).pushNamed('/settings', arguments: SettingsInitialFocus.accountDeletion);
  }

  Future<void> _exportLearningData() async {
    if (_exportBusy) return;
    if (widget.previewMode && widget.exportLearningData == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final t = AppL10n.of(context);
    setState(() => _exportBusy = true);
    try {
      final export = widget.exportLearningData;
      if (export != null) {
        await export();
      } else {
        final package = LearningDataExportService.buildPackage();
        await LearningDataExportService.sharePackage(package);
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.profileLearningDataExportReady)),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.profileLearningDataExportFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final account = widget.account ?? AuthService.accountSnapshot;
    final providers = account.providers;
    final linked = providers.isDurable;
    final providerLabel = _providerLabel(t, providers);
    final name = account.displayName;
    final motivation =
        widget.previewMotivation ?? learnerMotivationFromId(Storage.motivation);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SoriContentClamp(
          base: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          builder: (context, padding) => ListView(
            padding: padding,
            children: [
              // 06A: first surface = a learning route the learner can alter,
              // not a dashboard of account state. Account controls remain
              // below the editable learning choices.
              SoriCard(
                variant: SoriCardVariant.hero,
                accent: SoriColors.primary,
                tinted: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.profileJourneyTitle(
                              linked
                                  ? (name ?? providerLabel)
                                  : t.profileGuestName,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SoriTextTheme.of(context).h2,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            '${t.profileJourneySummary(_levelLabel(t), motivation?.label(t) ?? t.profileLearningGoalNotSet)} · '
                            '${t.profileSafeSituations(Storage.completedScenarios.length)}',
                            style: SoriTextTheme.of(context).bodySmall,
                          ),
                          if (linked) ...[
                            const SizedBox(height: 2),
                            Text(
                              t.profileConnectedProviderBadge(providerLabel),
                              style: SoriTextTheme.of(context).caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    _Avatar(
                      size: 96,
                      preference: widget.previewCompanion,
                      // ⚠️ 이 카드의 **실제 채움색**을 넘긴다. 아바타 클립은 흰
                      // 매트를 multiply 로 지우므로 결과가 이 값이 되는데, 예전엔
                      // 스캐폴드 크림(#FAF6EC)을 넘겨서 teal 카드(#EDF3ED) 위에
                      // 크림 사각형이 떴다(Jin 2026-08-12 실기기, 실측 확인).
                      // 위 SoriCard 의 accent·tinted 와 반드시 같은 인자를 쓴다.
                      backdrop: SoriCard.resolvedBackground(
                        context,
                        accent: SoriColors.primary,
                        tinted: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _ProfileSectionLabel(
                label: t.profileLearningSection,
                action: t.profileEditAction,
              ),
              const SizedBox(height: Spacing.sm),
              SoriCard(
                variant: SoriCardVariant.base,
                child: Column(
                  children: [
                    _ProfileSettingTile(
                      key: const ValueKey('profile-learning-goal'),
                      icon: motivation?.icon ?? Icons.flag_outlined,
                      label: t.profileLearningGoal,
                      value:
                          motivation?.label(t) ?? t.profileLearningGoalNotSet,
                      onTap: _changeMotivation,
                    ),
                    const Divider(height: 1),
                    _ProfileSettingTile(
                      key: const ValueKey('profile-learning-start-point'),
                      icon: Icons.school_outlined,
                      label: t.profileLearningStartPoint,
                      value: _levelLabel(t),
                      onTap: _changeLevel,
                    ),
                    const Divider(height: 1),
                    if (widget.previewCompanion case final previewPreference?)
                      _ProfileSettingTile(
                        key: const ValueKey('profile-learning-companion'),
                        icon: switch (previewPreference) {
                          CompanionPreference.none =>
                            Icons.person_outline_rounded,
                          CompanionPreference.tiger => Icons.pets_outlined,
                          CompanionPreference.magpie =>
                            Icons.flutter_dash_rounded,
                        },
                        label: t.profileLearningCompanion,
                        value: switch (previewPreference) {
                          CompanionPreference.none => t.companionNoneName,
                          CompanionPreference.tiger => t.characterNameTiger,
                          CompanionPreference.magpie => t.characterRomanMagpie,
                        },
                        onTap: _changeCompanion,
                      )
                    else
                      ValueListenableBuilder<CompanionPreference>(
                        valueListenable: MascotPreference.preference,
                        builder: (context, preference, _) =>
                            _ProfileSettingTile(
                              key: const ValueKey('profile-learning-companion'),
                              icon: switch (preference) {
                                CompanionPreference.none =>
                                  Icons.person_outline_rounded,
                                CompanionPreference.tiger =>
                                  Icons.pets_outlined,
                                CompanionPreference.magpie =>
                                  Icons.flutter_dash_rounded,
                              },
                              label: t.profileLearningCompanion,
                              value: switch (preference) {
                                CompanionPreference.none => t.companionNoneName,
                                CompanionPreference.tiger =>
                                  t.characterNameTiger,
                                CompanionPreference.magpie =>
                                  t.characterRomanMagpie,
                              },
                              onTap: _changeCompanion,
                            ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _ProfileSectionLabel(label: t.profileSpaceSection),
              const SizedBox(height: Spacing.sm),
              SoriCard(
                variant: SoriCardVariant.base,
                child: Column(
                  children: [
                    _ProfileSettingTile(
                      key: const ValueKey('profile-account-controls'),
                      icon: Icons.shield_outlined,
                      label: t.profilePrivacyAccount,
                      value: t.profilePrivacyAccountDescription,
                      onTap: _openAccountControls,
                    ),
                    const Divider(height: 1),
                    FutureBuilder<List<GyeMeta>>(
                      future: _gyeMetas,
                      builder: (context, snapshot) => _ProfileSettingTile(
                        key: const ValueKey('profile-gye'),
                        icon: Icons.groups_2_outlined,
                        label: t.profileGye,
                        value:
                            snapshot.connectionState == ConnectionState.waiting
                            ? t.profileGyeLoading
                            : snapshot.hasError ||
                                  (snapshot.data ?? const <GyeMeta>[]).isEmpty
                            ? t.profileGyeNone
                            : snapshot.data!.first.name,
                        onTap: _openGye,
                      ),
                    ),
                    const Divider(height: 1),
                    _ProfileSettingTile(
                      key: const ValueKey('profile-learning-data-export'),
                      icon: Icons.file_download_outlined,
                      label: t.profileLearningData,
                      value: _exportBusy
                          ? t.profileLearningDataPreparing
                          : t.profileLearningDataDescription,
                      onTap: _exportLearningData,
                    ),
                    const Divider(height: 1),
                    _ProfileSettingTile(
                      key: const ValueKey('profile-account-delete'),
                      icon: Icons.person_remove_outlined,
                      label: t.profileAccountDelete,
                      value: t.profileAccountDeleteDescription,
                      destructive: true,
                      onTap: _openAccountDeletion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // The full durable account controls follow the learner's
              // journey, choices, and space. Its connected-provider badge is
              // already visible in the hero above.
              AccountPendingOperationPanel(
                operations: _accountOperations,
                cloudDeletionState: _cloudDataDeletionJournalState,
                resumeCloudDeletion: _resumeCloudDeletion,
                onCompleted: () async {
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _accountCardKey,
                child: ValueListenableBuilder<CloudBackupDeletionJournalState>(
                  valueListenable: _cloudDataDeletionJournalState,
                  builder: (context, cloudDeletionState, _) =>
                      AccountNewLinkGuard(
                        operations: _accountOperations,
                        builder: (context, linkAvailable) => linked
                            ? _ConnectedCard(
                                name: name ?? providerLabel,
                                onSignOut:
                                    linkAvailable &&
                                        cloudDeletionState ==
                                            CloudBackupDeletionJournalState
                                                .clear
                                    ? _signOut
                                    : () =>
                                          _showActionLocked(cloudDeletionState),
                              )
                            : _GuestCard(
                                busy: _busy,
                                onConnect:
                                    linkAvailable &&
                                        cloudDeletionState ==
                                            CloudBackupDeletionJournalState
                                                .clear
                                    ? () => _connectWith(
                                        AccountLinkProvider.google,
                                      )
                                    : () =>
                                          _showActionLocked(cloudDeletionState),
                                onConnectApple:
                                    !_accountOperations.appleSignInAvailable
                                    ? null
                                    : linkAvailable &&
                                          cloudDeletionState ==
                                              CloudBackupDeletionJournalState
                                                  .clear
                                    ? () => _connectWith(
                                        AccountLinkProvider.apple,
                                      )
                                    : () =>
                                          _showActionLocked(cloudDeletionState),
                              ),
                      ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              _ProfileSectionLabel(label: t.profileProgressSection),
              const SizedBox(height: Spacing.sm),
              const _StatsRow(),
              const SizedBox(height: Spacing.md),
              SoriButton.outlined(
                label: t.profileViewStats,
                icon: Icons.bar_chart_rounded,
                fullWidth: true,
                onTap: () => Navigator.pushNamed(context, '/stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────

class _Avatar extends StatefulWidget {
  const _Avatar({this.size = 168, this.preference, this.backdrop});

  final double size;
  final CompanionPreference? preference;

  /// 아바타 **바로 뒤에 실제로 칠해지는 색**. 클립의 흰 매트를 multiply 로
  /// 지우면 결과가 정확히 이 값이 되므로, 여기에 부모가 그리는 색이 아닌 다른
  /// 값을 주면 그 차이가 사각형으로 보인다. null 이면 스캐폴드 색으로 폴백한다.
  final Color? backdrop;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  @override
  void initState() {
    super.initState();
    // 설정에서 캐릭터를 바꾸면(태고↔조이) 프로필 아바타도 즉시 반영.
    if (widget.preference == null) {
      MascotPreference.preference.addListener(_onKindChanged);
    }
  }

  @override
  void didUpdateWidget(covariant _Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preference == null && widget.preference != null) {
      MascotPreference.preference.removeListener(_onKindChanged);
    } else if (oldWidget.preference != null && widget.preference == null) {
      MascotPreference.preference.addListener(_onKindChanged);
    }
  }

  void _onKindChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.preference == null) {
      MascotPreference.preference.removeListener(_onKindChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jin 2026-08-06: 프로필 아바타 = 캐릭터 영상 복원. Impeller 를 끈 뒤
    // (AndroidManifest) Android<33 fence 버그가 사라져, 홈 히어로와 디코더를
    // 영상 lease 로 직렬화하면 깜빡임 없이 재생된다(탭 전환 시 보이는 쪽만
    // lease 획득). 클립은 카탈로그(`_tigerProfileClips`)가 정한 프로필 포즈를
    // 따른다 — 까치=magpie_bob2 대기 홉, 호랑이(태고)=tiger_sitting2 앉은 자세.
    // 둘 다 **루프 가능**해야 한다: 원샷을 쓰면 재생이 끝나며 텍스처가 회수돼
    // 아바타가 비어 버린다(tiger_walking_front 가 그랬다).
    final preference = widget.preference ?? MascotPreference.preference.value;
    final kind = MascotPreference.mascotKindFor(preference);
    if (kind == null) {
      return SizedBox.square(
        key: const ValueKey('profile_avatar_none'),
        dimension: widget.size,
        child: Semantics(
          label: AppL10n.of(context).companionNoneName,
          image: true,
          child: Icon(
            Icons.person_outline_rounded,
            size: widget.size * 0.42,
            color: SoriSurfaces.of(context).textMuted,
          ),
        ),
      );
    }
    final isMagpie = kind == MascotKind.magpie;
    return SizedBox.square(
      dimension: widget.size,
      child: Center(
        child: CharacterClipPlayer(
          key: ValueKey('profile_avatar_${kind.name}'),
          asset: isMagpie
              ? CharacterClips.magpieBob2
              : CharacterClips.tigerSitting2,
          size: widget.size,
          // 둘 다 루프 가능한 클립이라 loop:true. 원샷 클립을 쓰면 재생이
          // 끝나는 순간 lease 가 반납돼 아바타가 비므로 금지(아래 ⚠️ 참고).
          loop: true,
          // 뒤에 칠해지는 **그 색 그대로**여야 한다. 아바타는 스캐폴드 위가
          // 아니라 tinted 히어로 카드 안에 있으므로 부모가 카드의 실제 채움색을
          // [_Avatar.backdrop] 으로 넘긴다. 예전엔 여기서 스캐폴드 색을 읽어
          // teal 카드(#EDF3ED) 위에 크림(#FAF6EC) 사각형이 떴다.
          // 폴백으로만 스캐폴드 색을 쓴다 — `s.bg` 는 SoriSurfaces 가 brightness
          // 만 보고 팔레트 변종을 못 봐서 부적합.
          blendColor:
              widget.backdrop ?? Theme.of(context).scaffoldBackgroundColor,
          // Jin 2026-08-06: 프로필 정적 폴백 끔 → 투명(배경 비침).
          // ⚠️ 단 reduce-motion 에서는 켠다. 영상 lease 는 `!reduceMotion` 을
          //    요구해서(video_lease.dart) 접근성 설정 사용자는 영상을 못 받는데,
          //    폴백까지 끄면 아바타 자리가 통째로 빈칸이 된다.
          // ⚠️ 폴백을 끈 상태에서는 **원샷 클립 금지** — 재생이 끝나면 플레이어가
          //    lease 를 반납하고 투명 폴백으로 떨어져 아바타 자리가 통째로
          //    빈칸이 된다. 프로필 클립은 반드시 루프 가능한 것만 쓴다.
          staticFallback: CharacterClipPlayer.videoUnavailable(context),
          fallbackKind: kind,
          fallbackEmotion: MascotEmotion.smile,
        ),
      ),
    );
  }
}

/// Gast: lädt zum Sichern ein (der Kern-Nudge).
class _GuestCard extends StatelessWidget {
  final bool busy;
  final VoidCallback? onConnect;
  final VoidCallback? onConnectApple;
  const _GuestCard({
    required this.busy,
    required this.onConnect,
    this.onConnectApple,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      tinted: true,
      accent: SoriColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: SoriColors.gold,
                size: 22,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  t.profileGuestBadge,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.profileGuestDesc,
            style: TextStyle(fontSize: 13, height: 1.45, color: s.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            t.accountSafeConnectExplain,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: s.textMuted),
          ),
          const SizedBox(height: 16),
          SoriButton.filled(
            label: t.settingsCloudSignInPrompt,
            icon: Icons.cloud_upload_outlined,
            fullWidth: true,
            onTap: busy ? null : onConnect,
          ),
          if (onConnectApple != null) ...[
            const SizedBox(height: 8),
            SoriButton.outlined(
              label: t.authAppleSignIn,
              icon: Icons.apple,
              fullWidth: true,
              onTap: busy ? null : onConnectApple,
            ),
          ],
        ],
      ),
    );
  }
}

/// Verbunden: zeigt Status + Abmelden.
class _ConnectedCard extends StatelessWidget {
  final String? name;
  final VoidCallback? onSignOut;
  const _ConnectedCard({required this.name, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      tinted: true,
      accent: SoriColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: SoriColors.primary,
                size: 22,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  t.settingsCloudSignedIn(name ?? 'Google'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.profileConnectedDesc,
            style: TextStyle(fontSize: 13, height: 1.45, color: s.textMuted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SoriButton.ghost(
              label: t.profileSignOut,
              icon: Icons.logout_rounded,
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({required this.label, this.action});

  final String label;
  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
    child: Row(
      children: [
        Expanded(child: Text(label, style: SoriTextTheme.of(context).label)),
        if (action != null)
          Text(action!, style: SoriTextTheme.of(context).caption),
      ],
    ),
  );
}

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      leading: Icon(
        icon,
        color: destructive ? SoriColors.danger : SoriColors.primary,
      ),
      title: Text(
        label,
        style: SoriTextTheme.of(
          context,
        ).cardTitle.copyWith(color: destructive ? SoriColors.danger : null),
      ),
      subtitle: Text(value, style: SoriTextTheme.of(context).caption),
      trailing: const Icon(Icons.chevron_right_rounded),
      minVerticalPadding: Spacing.xs,
      onTap: onTap,
    ),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            value: '${Storage.streakDays}',
            label: t.profileStatStreak,
            color: SoriColors.tiger,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            value: '${Storage.xpLevel}',
            label: t.profileStatLevel,
            color: SoriColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.menu_book_rounded,
            value: '${Storage.vokCorrect}',
            label: t.profileStatWords,
            color: SoriColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: s.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: s.textMuted, height: 1.2),
          ),
        ],
      ),
    );
  }
}
