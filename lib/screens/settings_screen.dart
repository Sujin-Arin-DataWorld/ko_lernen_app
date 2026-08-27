import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sori/button.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/window_class.dart';
import '../widgets/sori/external_link.dart';
import '../services/storage_service.dart';
import '../services/audio_policy.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../services/privacy_consent_service.dart';
import '../services/word_image_service.dart';
import '../widgets/sori/sheet.dart';
import '../services/personalized_lesson_service.dart';
import '../services/premium_service.dart';
import '../services/tts_service.dart';
import '../services/locale_service.dart';
import '../services/data_loader.dart';
import '../services/auth_service.dart';
import '../services/app_version_service.dart';
import '../services/account/account_failure_diagnostics.dart';
import '../services/account/account_failure_reason.dart';
import '../services/account/account_transition_coordinator.dart';
import '../services/account/account_ui_operations.dart';
import '../services/account/cloud_backup_deletion.dart';
import '../services/account/cloud_restore_result.dart';
import '../services/account/cloud_write_session.dart';
import 'app_shell.dart';
import '../services/cloud_sync.dart';
import '../services/content_feedback_service.dart';
import '../services/course_progress_service.dart';
import '../models/scenario.dart';
import '../l10n/generated/app_localizations.dart';
import '../motion/transitions.dart';
import '../widgets/sori/account_operation_ui.dart';
import 'placement_diagnostic_screen.dart';

abstract interface class AccountDeletionCleanupOperations {
  Future<void> deleteRemoteAccount();
  Future<void> resetLocalStorage();
  Future<void> disablePush();
  Future<void> deleteLocalImages();
  Future<void> clearTtsCache();
  void resetInMemoryData();
}

class AccountDeletionFailure implements Exception {
  const AccountDeletionFailure(
    this.causes, {
    this.identityRecoveryPending = false,
  });

  final List<Object> causes;
  final bool identityRecoveryPending;

  @override
  String toString() =>
      'Account deletion did not complete cleanly (${causes.length} failure(s)).';
}

class AccountDeletionCleanupAdapter
    implements AccountDeletionCleanupOperations {
  factory AccountDeletionCleanupAdapter({
    required Future<void> Function() deleteRemote,
    required Future<void> Function() resetStorage,
    required Future<void> Function() disablePush,
    required Future<void> Function() deleteImages,
    required Future<void> Function() clearTts,
    required void Function() resetMemory,
  }) => AccountDeletionCleanupAdapter._(
    deleteRemote,
    resetStorage,
    disablePush,
    deleteImages,
    clearTts,
    resetMemory,
  );

  const AccountDeletionCleanupAdapter._(
    this._deleteRemote,
    this._resetStorage,
    this._disablePush,
    this._deleteImages,
    this._clearTts,
    this._resetMemory,
  );

  factory AccountDeletionCleanupAdapter.production({
    required FeedbackOutbox feedbackOutbox,
  }) => AccountDeletionCleanupAdapter(
    deleteRemote: () => AuthService.deleteAccount(
      closeFeedback: feedbackOutbox.closeAndDiscard,
    ),
    resetStorage: () => CourseProgressService.shared.runLocalStorageWipeBarrier(
      () => Storage.resetAllStrict(
        canonicalizeAccountDeletionCheckpoint:
            AuthService.canonicalizeCompletedDeletionCheckpoint,
      ),
    ),
    disablePush: pushService.disableStrict,
    deleteImages: WordImageService.deleteAllStrict,
    clearTts: TtsService.clearCacheStrict,
    resetMemory: () {
      DataLoader.reset();
    },
  );

  final Future<void> Function() _deleteRemote;
  final Future<void> Function() _resetStorage;
  final Future<void> Function() _disablePush;
  final Future<void> Function() _deleteImages;
  final Future<void> Function() _clearTts;
  final void Function() _resetMemory;

  @override
  Future<void> clearTtsCache() => _clearTts();

  @override
  Future<void> deleteLocalImages() => _deleteImages();

  @override
  Future<void> deleteRemoteAccount() => _deleteRemote();

  @override
  Future<void> disablePush() => _disablePush();

  @override
  void resetInMemoryData() => _resetMemory();

  @override
  Future<void> resetLocalStorage() => _resetStorage();
}

/// Joins account-deletion actions across every Settings route in this process.
/// The gate clears after settlement, so a later deliberate deletion remains
/// possible for the then-current account.
class AccountDeletionWorkflowGate {
  Future<void>? _inFlight;

  Future<void> run(Future<void> Function() operation) {
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    late final Future<void> guarded;
    guarded = operation().whenComplete(() {
      if (identical(_inFlight, guarded)) {
        _inFlight = null;
      }
    });
    _inFlight = guarded;
    return guarded;
  }
}

/// Stops before local destruction when remote deletion fails. Once the remote
/// identity is gone, every independent privacy cleanup is attempted and all
/// failures are reported together.
class AccountDeletionWorkflow {
  factory AccountDeletionWorkflow.production({
    required FeedbackOutbox feedbackOutbox,
    AccountDeletionFeedbackActivator? activateFeedback,
  }) => AccountDeletionWorkflow(
    AccountDeletionCleanupAdapter.production(feedbackOutbox: feedbackOutbox),
    finalizePendingFeedbackActivation: () =>
        AuthService.finalizePendingAccountDeletionFeedback(
          closeFeedback: feedbackOutbox.closeAndDiscard,
          activateFeedback: activateFeedback ?? (_) async => true,
        ),
    completeCheckpoint: () => AuthService.completeLocalAccountDeletionCleanup(
      activateFeedback: activateFeedback,
    ),
  );

  AccountDeletionWorkflow(
    this.operations, {
    Future<void> Function()? completeCheckpoint,
    Future<bool> Function()? finalizePendingFeedbackActivation,
    AccountDeletionWorkflowGate? gate,
  }) : _completeCheckpoint = completeCheckpoint ?? _noop,
       _finalizePendingFeedbackActivation =
           finalizePendingFeedbackActivation ?? _nothingToFinalize,
       _gate = gate ?? _sharedGate;

  static final AccountDeletionWorkflowGate _sharedGate =
      AccountDeletionWorkflowGate();
  final AccountDeletionCleanupOperations operations;
  final Future<void> Function() _completeCheckpoint;
  final Future<bool> Function() _finalizePendingFeedbackActivation;
  final AccountDeletionWorkflowGate _gate;

  static Future<void> _noop() async {}
  static Future<bool> _nothingToFinalize() async => false;

  Future<void> run() => _gate.run(_run);

  Future<void> _run() async {
    if (await _finalizePendingFeedbackActivation()) {
      return;
    }
    final failures = <Object>[];
    var identityRecoveryPending = false;
    try {
      await operations.deleteRemoteAccount();
    } on AccountDeletionRecoveryException catch (error) {
      failures.add(error);
      identityRecoveryPending = true;
    }

    await _runLocalCleanup(
      failures,
      identityRecoveryPending: identityRecoveryPending,
    );
  }

  Future<void> retryLocalCleanup() {
    return _gate.run(
      () => _runLocalCleanup(<Object>[], identityRecoveryPending: false),
    );
  }

  Future<void> _runLocalCleanup(
    List<Object> failures, {
    required bool identityRecoveryPending,
  }) async {
    await _attempt(operations.resetLocalStorage, failures);
    await _attempt(operations.disablePush, failures);
    await _attempt(operations.deleteLocalImages, failures);
    await _attempt(operations.clearTtsCache, failures);
    try {
      operations.resetInMemoryData();
    } catch (error) {
      failures.add(error);
    }

    if (failures.isNotEmpty) {
      throw AccountDeletionFailure(
        List<Object>.unmodifiable(failures),
        identityRecoveryPending: identityRecoveryPending,
      );
    }
    await _completeCheckpoint();
  }

  Future<void> _attempt(
    Future<void> Function() operation,
    List<Object> failures,
  ) async {
    try {
      await operation();
    } catch (error) {
      failures.add(error);
    }
  }
}

Uri? subscriptionManagementUri(TargetPlatform platform, {bool isWeb = false}) {
  if (isWeb) {
    return null;
  }
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return Uri.parse('https://apps.apple.com/account/subscriptions');
  }
  if (platform == TargetPlatform.android) {
    return Uri.parse('https://play.google.com/store/account/subscriptions');
  }
  return null;
}

class SubscriptionManagementException implements Exception {
  const SubscriptionManagementException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SubscriptionManagementLauncher {
  const SubscriptionManagementLauncher({
    required this.platform,
    required this.isWeb,
    required this.launchExternal,
  });

  final TargetPlatform platform;
  final bool isWeb;
  final Future<bool> Function(Uri uri) launchExternal;

  Future<void> open() async {
    final uri = subscriptionManagementUri(platform, isWeb: isWeb);
    if (uri == null) {
      throw const SubscriptionManagementException(
        'Subscription management is unavailable on this platform.',
      );
    }
    if (!await launchExternal(uri)) {
      throw const SubscriptionManagementException(
        'The subscription management route could not open.',
      );
    }
  }
}

enum SettingsInitialFocus {
  courseStart,
  browseLevel,
  companion,
  voiceSpeed,
  guide,
  account,
  accountDeletion,
}

abstract interface class NotificationSettingsOperations {
  Future<bool> requestPermission();

  Future<void> enable({
    required int hour,
    required String title,
    required String body,
    required String streakTitle,
    required String streakBody,
  });

  Future<void> disable();
}

class ProductionNotificationSettingsOperations
    implements NotificationSettingsOperations {
  const ProductionNotificationSettingsOperations();

  @override
  Future<bool> requestPermission() => NotificationService.requestPermission();

  @override
  Future<void> enable({
    required int hour,
    required String title,
    required String body,
    required String streakTitle,
    required String streakBody,
  }) async {
    await NotificationService.scheduleDaily(
      hour: hour,
      minute: 0,
      title: title,
      body: body,
    );
    await NotificationService.scheduleStreakSaver(
      hour: 21,
      minute: 0,
      title: streakTitle,
      body: streakBody,
    );
    // FCM is optional. A failed cloud registration must not undo local
    // reminder permission or scheduling.
    await pushService.enable();
  }

  @override
  Future<void> disable() async {
    await NotificationService.cancelAll();
    await pushService.disable();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.account,
    this.accountDeletionWorkflow,
    this.subscriptionManager,
    this.accountOperations,
    this.cloudDataDeletion,
    this.cloudDataDeletionJournalState,
    this.resetAllData,
    this.appVersionReader,
    this.initialFocus,
    this.notificationOperations,
  });

  final AuthAccountSnapshot? account;
  final AccountDeletionWorkflow? accountDeletionWorkflow;
  final SubscriptionManagementLauncher? subscriptionManager;
  final AccountUiOperations? accountOperations;
  final Future<CloudWriteResult> Function()? cloudDataDeletion;
  final ValueListenable<CloudBackupDeletionJournalState>?
  cloudDataDeletionJournalState;
  final Future<void> Function()? resetAllData;
  final AppVersionReader? appVersionReader;
  final SettingsInitialFocus? initialFocus;
  final NotificationSettingsOperations? notificationOperations;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '-';
  DateTime? _lastBackupAt;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _courseStartKey = GlobalKey();
  final GlobalKey _browseLevelKey = GlobalKey();
  final GlobalKey _companionKey = GlobalKey();
  final GlobalKey _voiceSpeedKey = GlobalKey();
  final GlobalKey _guideKey = GlobalKey();
  final GlobalKey _accountSectionKey = GlobalKey();
  final GlobalKey _accountDeletionKey = GlobalKey();
  final FocusNode _courseStartFocusNode = FocusNode(
    debugLabel: 'settings-course-start',
  );
  final FocusNode _browseLevelFocusNode = FocusNode(
    debugLabel: 'settings-browse-level',
  );
  final FocusNode _companionFocusNode = FocusNode(
    debugLabel: 'settings-companion',
  );
  final FocusNode _voiceSpeedFocusNode = FocusNode(
    debugLabel: 'settings-voice-speed',
  );
  final FocusNode _guideFocusNode = FocusNode(debugLabel: 'settings-guide');

  AppVersionReader get _appVersionReader =>
      widget.appVersionReader ?? const PackageAppVersionReader();

  AccountDeletionWorkflow get _accountDeletionWorkflow =>
      widget.accountDeletionWorkflow ??
      (throw StateError('Account deletion workflow is not configured.'));

  AccountUiOperations get _accountOperations =>
      widget.accountOperations ?? const ProductionAccountUiOperations();

  ValueListenable<CloudBackupDeletionJournalState>
  get _cloudDataDeletionJournalState =>
      widget.cloudDataDeletionJournalState ??
      AuthService.cloudBackupDeletionJournalState;

  SubscriptionManagementLauncher get _subscriptionManager =>
      widget.subscriptionManager ??
      SubscriptionManagementLauncher(
        platform: defaultTargetPlatform,
        isWeb: kIsWeb,
        launchExternal: (uri) =>
            launchUrl(uri, mode: LaunchMode.externalApplication),
      );

  NotificationSettingsOperations get _notificationOperations =>
      widget.notificationOperations ??
      const ProductionNotificationSettingsOperations();

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadLastBackupAt();
    // 계정 pending 저널 admission 을 **화면 진입 즉시** 시작한다.
    // 계정 섹션은 lazy ListView 하단이라 위젯 마운트(AccountNewLinkGuard
    // initState)에만 맡기면 위쪽 콘텐츠가 길어질수록 admission 이 스크롤
    // 시점으로 밀린다 — "첫 프레임부터 잠금" 보장을 여기서 앵커한다.
    // (마운트 시 재호출은 idempotent — refreshPendingState 는 상태 재읽기.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ops = _accountOperations;
      // AccountUiPendingStateSource 는 AccountUiOperations 의 서브타입이 아니라
      // is-승격이 안 됨 — account_operation_ui.dart 의 _source 와 같은 캐스트.
      final source = ops is AccountUiPendingStateSource
          ? ops as AccountUiPendingStateSource
          : null;
      source?.refreshPendingState();
    });
    if (widget.cloudDataDeletionJournalState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AuthService.refreshCloudBackupDeletionJournalState();
      });
    }
    if (widget.initialFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_seekInitialFocus());
      });
    }
  }

  FocusNode? _focusNodeFor(SettingsInitialFocus focus) => switch (focus) {
    SettingsInitialFocus.courseStart => _courseStartFocusNode,
    SettingsInitialFocus.browseLevel => _browseLevelFocusNode,
    SettingsInitialFocus.companion => _companionFocusNode,
    SettingsInitialFocus.voiceSpeed => _voiceSpeedFocusNode,
    SettingsInitialFocus.guide => _guideFocusNode,
    SettingsInitialFocus.account ||
    SettingsInitialFocus.accountDeletion => null,
  };

  Future<void> _seekInitialFocus([int attempt = 0]) async {
    if (!mounted || widget.initialFocus == null) return;
    final focus = widget.initialFocus!;
    final key = switch (focus) {
      SettingsInitialFocus.courseStart => _courseStartKey,
      SettingsInitialFocus.browseLevel => _browseLevelKey,
      SettingsInitialFocus.companion => _companionKey,
      SettingsInitialFocus.voiceSpeed => _voiceSpeedKey,
      SettingsInitialFocus.guide => _guideKey,
      SettingsInitialFocus.account => _accountSectionKey,
      SettingsInitialFocus.accountDeletion => _accountDeletionKey,
    };
    final targetContext = key.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.12,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      if (mounted && widget.initialFocus == focus) {
        _focusNodeFor(focus)?.requestFocus();
      }
      return;
    }
    if (attempt >= 64 || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nextOffset = attempt == 0
        ? position.minScrollExtent
        : (position.pixels + position.viewportDimension * 0.72)
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble();
    if (attempt > 0 && (nextOffset - position.pixels).abs() < 0.5) {
      return;
    }
    // Settings uses a lazy scrolling list, so a typed destination can have no
    // BuildContext until its region is built. Scan forward with overlapping
    // viewports instead of relying on fragile hard-coded content fractions.
    _scrollController.jumpTo(nextOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_seekInitialFocus(attempt + 1));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _courseStartFocusNode.dispose();
    _browseLevelFocusNode.dispose();
    _companionFocusNode.dispose();
    _voiceSpeedFocusNode.dispose();
    _guideFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _confirmPronunciationConsent() async {
    final t = AppL10n.of(context);
    return await showSoriDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => SoriDialog(
            title: Text(t.pronunciationConsentTitle),
            content: Text(t.pronunciationConsentBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(t.pronunciationConsentDecline),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(t.pronunciationConsentAccept),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _loadAppVersion() async {
    try {
      final version = await _appVersionReader.readVersion();
      if (mounted) {
        setState(() => _appVersion = version);
      }
    } catch (_) {
      // Keep the neutral placeholder when native package metadata is absent.
    }
  }

  Future<void> _loadLastBackupAt() async {
    final at = await CloudSync.lastBackupAt();
    if (mounted) {
      setState(() => _lastBackupAt = at);
    }
  }

  String _formatBackupTime(DateTime at) {
    final local = at.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  // ── M3: Benachrichtigungen ──────────────────────────────────
  String _notifTimeLabel() =>
      '${Storage.notificationHour.toString().padLeft(2, '0')}:00';

  Future<void> _onToggleNotif(bool v) async {
    final t = AppL10n.of(context);
    await Storage.setNotificationsEnabled(v);
    if (v) {
      final granted = await _notificationOperations.requestPermission();
      if (granted) {
        await _notificationOperations.enable(
          hour: Storage.notificationHour,
          title: t.notificationTitle,
          body: t.notificationBody,
          streakTitle: t.notifStreakSaverTitle,
          streakBody: t.notifStreakSaverBody,
        );
      } else {
        await Storage.setNotificationsEnabled(false);
        await _notificationOperations.disable();
        if (!mounted) return;
        soriToast(context, t.settingsNotifDenied);
      }
    } else {
      await _notificationOperations.disable();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickNotifTime() async {
    final t = AppL10n.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: Storage.notificationHour, minute: 0),
    );
    if (picked == null) return;
    await Storage.setNotificationHour(picked.hour);
    await NotificationService.scheduleDaily(
      hour: picked.hour,
      minute: 0,
      title: t.notificationTitle,
      body: t.notificationBody,
    );
    await NotificationService.scheduleStreakSaver(
      hour: 21,
      minute: 0,
      title: t.notifStreakSaverTitle,
      body: t.notifStreakSaverBody,
    );
    if (mounted) setState(() {});
  }

  // ── M5: Interessen-Auswahl (für den personalisierten Tageskurs) ──
  String _interestLabel(AppL10n t, String key) {
    switch (key) {
      case 'everyday':
        return t.interestEveryday;
      case 'food_shopping':
        return t.interestFoodShopping;
      case 'work_study':
        return t.interestWorkStudy;
      case 'travel':
        return t.interestTravel;
      case 'feelings_people':
        return t.interestFeelingsPeople;
      case 'health_body':
        return t.interestHealthBody;
      default:
        return key;
    }
  }

  Future<void> _showInterestPicker() async {
    final t = AppL10n.of(context);
    final selected = Storage.interests.toSet();
    await showSoriSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.interestsSheetTitle,
              style: SoriTextTheme.of(
                context,
              ).h3.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PersonalizedLessonService.allInterests.map((k) {
                final on = selected.contains(k);
                return FilterChip(
                  label: Text(_interestLabel(t, k)),
                  selected: on,
                  onSelected: (v) => setSheet(() {
                    if (v) {
                      selected.add(k);
                    } else {
                      selected.remove(k);
                    }
                  }),
                  selectedColor: SoriColors.primary.withValues(alpha: 0.18),
                  checkmarkColor: SoriColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SoriButton.filled(
              label: t.btnApply,
              fullWidth: true,
              onTap: () async {
                await Storage.setInterests(selected.toList());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  String _providerLabel(AppL10n t, AuthProviderState providers) {
    if (providers.isGoogleLinked && providers.isAppleLinked) {
      return t.authProviderGoogleAndApple;
    }
    if (providers.isAppleLinked) {
      return t.authProviderApple;
    }
    return t.authProviderGoogle;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final currentLocale = localeNotifier.value;
    final account = widget.account ?? AuthService.accountSnapshot;
    final providers = account.providers;

    return SoriStandardPage(
      appBarTitle: t.settingsTitle,
      controller: _scrollController,
      maxWidth: SoriMaxWidth.form,
      padding: const EdgeInsets.fromLTRB(0, Spacing.sm, 0, Spacing.xxxl),
      children: [
        // ── 서재 헤더 (한옥 학자방 일러스트) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.xs,
            Spacing.lg,
            Spacing.md,
          ),
          child: HanokHeader(
            asset: 'assets/illustrations/hanok/study_scholar.png',
            fallbackIcon: Icons.tune_rounded,
          ),
        ),

        // ── Erscheinungsbild: Dark Mode in v2.0 deaktiviert ──
        // (App läuft ausschließlich im Light-Theme — Auswahl entfernt.)

        // ── Sprache ──
        _Section(label: t.settingsLanguage),
        RadioGroup<String>(
          groupValue: currentLocale == null
              ? 'system'
              : currentLocale.languageCode,
          onChanged: (v) => setState(() {
            switch (v) {
              case 'de':
                setLocale(const Locale('de'));
              case 'en':
                setLocale(const Locale('en'));
              default:
                setLocale(null);
            }
          }),
          child: Column(
            children: [
              _RadioTile<String>(
                title: t.settingsLanguageSystem,
                value: 'system',
              ),
              _RadioTile<String>(title: t.settingsLanguageDe, value: 'de'),
              _RadioTile<String>(title: t.settingsLanguageEn, value: 'en'),
            ],
          ),
        ),

        // Course placement and browsing filters are intentionally independent.
        _Section(label: t.settingsLearningLevelsSection),
        ListTile(
          key: _courseStartKey,
          focusNode: _courseStartFocusNode,
          leading: const Icon(Icons.route_outlined, color: SoriColors.primary),
          title: Text(t.settingsCourseStartTitle),
          subtitle: Text(
            '${_courseStartLevelDisplay(t)}\n${t.settingsCourseStartDescription}',
            style: SoriTextTheme.of(context).caption,
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: _showCourseStartDialog,
        ),
        ListTile(
          key: _browseLevelKey,
          focusNode: _browseLevelFocusNode,
          leading: const Icon(
            Icons.explore_outlined,
            color: SoriColors.primary,
          ),
          title: Text(t.settingsBrowseLevelTitle),
          subtitle: Text(
            '${_browseLevelDisplay(t)}\n${t.settingsBrowseLevelDescription}',
            style: SoriTextTheme.of(context).caption,
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: _showBrowseLevelDialog,
        ),
        ListTile(
          leading: const Icon(
            Icons.fact_check_outlined,
            color: SoriColors.primary,
          ),
          title: Text(t.settingsRecheckLevelTitle),
          subtitle: Text(
            t.settingsRecheckLevelDescription,
            style: SoriTextTheme.of(context).caption,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openPlacementDiagnostic,
        ),

        // ── Lernbegleiter (캐릭터) ──
        // 2026-07-31 신설. 이전에는 `/character_selection` 으로 가는
        // 진입점이 앱 전체에 0개라 온보딩에서 한 번 고르면 영원히 못 바꿨다.
        // 여기서 바꾸면 MascotPreference 통지로 홈·게임이 즉시 따라온다.
        _Section(label: t.characterSelectionTitle),
        ListenableBuilder(
          listenable: Listenable.merge([
            MascotPreference.kind,
            MascotPreference.preference,
          ]),
          builder: (context, _) {
            final kind = MascotPreference.chosenKind;
            return ListTile(
              key: _companionKey,
              focusNode: _companionFocusNode,
              leading: Mascot(kind: kind, size: 34),
              title: Text(
                kind == MascotKind.magpie
                    ? t.characterRomanMagpie
                    : t.characterNameTiger,
              ),
              subtitle: Text(
                kind == MascotKind.magpie
                    ? t.characterTraitMagpie
                    : t.characterTraitTiger,
                style: SoriTextTheme.of(context).caption,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: SoriColors.lightTextMuted,
              ),
              onTap: () => _showMascotDialog(kind),
            );
          },
        ),
        ValueListenableBuilder<CompanionPreference>(
          valueListenable: MascotPreference.preference,
          builder: (context, preference, _) => SwitchListTile(
            secondary: const Icon(
              Icons.visibility_outlined,
              color: SoriColors.primary,
            ),
            title: Text(t.settingsCompanionVisibleTitle),
            subtitle: Text(
              t.settingsCompanionVisibleDescription,
              style: SoriTextTheme.of(context).caption,
            ),
            value: preference != CompanionPreference.none,
            onChanged: (visible) async {
              await MascotPreference.setVisible(visible);
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ),

        // ── Ton (ADR-002 §7) — AudioPolicy 단일 진실원천 ──
        _Section(label: t.settingsSoundSection),
        const _SoundSettings(),

        // ── TTS Speed ── 전역 배수 프리셋 (엔진 base rate 는 저장값 유지).
        // 구 0.1–1.0 슬라이더는 mp3 배속 의미가 불투명했다 — 이제 모든
        // 학습 화면과 같은 0.5×–1.5× 프리셋 컨트롤을 공유한다.
        Focus(
          key: _voiceSpeedKey,
          focusNode: _voiceSpeedFocusNode,
          child: Semantics(
            container: true,
            focusable: true,
            label: t.settingsTtsRate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(label: t.settingsTtsRate),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: TtsSpeedControl(
                    mode: TtsSpeedControlMode.row,
                    onChanged: (_) {
                      // ignore: discarded_futures
                      TtsService.speak('안녕하세요');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Erinnerung (M3) ──
        _Section(label: t.settingsNotifSection),
        SwitchListTile(
          secondary: const Icon(
            Icons.notifications_active_outlined,
            color: SoriColors.primary,
          ),
          title: Text(t.settingsNotifTitle),
          subtitle: Text(
            t.settingsNotifSubtitle,
            style: SoriTextTheme.of(context).caption,
          ),
          value: Storage.notificationsEnabled,
          activeThumbColor: SoriColors.primary,
          onChanged: _onToggleNotif,
        ),
        if (Storage.notificationsEnabled)
          ListTile(
            leading: const Icon(
              Icons.schedule_outlined,
              color: SoriColors.primary,
            ),
            title: Text(t.settingsNotifTime),
            trailing: Text(
              _notifTimeLabel(),
              style: SoriTextTheme.of(
                context,
              ).label.copyWith(color: SoriColors.primary),
            ),
            onTap: _pickNotifTime,
          ),

        // ── Interessen (M5) — für den personalisierten Tageskurs ──
        _Section(label: t.settingsInterestsTitle),
        ListTile(
          leading: const Icon(
            Icons.category_outlined,
            color: SoriColors.primary,
          ),
          title: Text(t.settingsInterestsTitle),
          subtitle: Text(
            t.settingsInterestsSubtitle,
            style: SoriTextTheme.of(context).caption,
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: SoriColors.darkTextMuted,
          ),
          onTap: _showInterestPicker,
        ),

        // ── Cloud-Backup (Firebase Auth) ──
        KeyedSubtree(
          key: _accountSectionKey,
          child: _Section(label: t.settingsCloudSection),
        ),
        AccountPendingOperationPanel(
          operations: _accountOperations,
          retryLocalDeletion: _onDeleteAccount,
          cloudDeletionState: _cloudDataDeletionJournalState,
          resumeCloudDeletion: _onDeleteCloudData,
          onCompleted: () async {
            if (mounted) setState(() {});
          },
        ),
        if (!providers.isDurable)
          ValueListenableBuilder<CloudBackupDeletionJournalState>(
            valueListenable: _cloudDataDeletionJournalState,
            builder: (context, cloudDeletionState, _) {
              final durableActionsAvailable =
                  cloudDeletionState == CloudBackupDeletionJournalState.clear;
              return AccountNewLinkGuard(
                operations: _accountOperations,
                builder: (context, linkAvailable) => Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.cloud_outlined,
                        color: SoriColors.primary,
                      ),
                      title: Text(t.settingsCloudSignInPrompt),
                      subtitle: Text(t.settingsCloudSignInDesc),
                      onTap: linkAvailable && durableActionsAvailable
                          ? _onGoogleTap
                          : () => _showActionLocked(cloudDeletionState),
                    ),
                    if (AuthService.appleSignInAvailable)
                      ListTile(
                        leading: const Icon(Icons.apple),
                        title: Text(t.authAppleSignIn),
                        subtitle: Text(t.settingsCloudSignInDesc),
                        onTap: linkAvailable && durableActionsAvailable
                            ? _onAppleTap
                            : () => _showActionLocked(cloudDeletionState),
                      ),
                  ],
                ),
              );
            },
          ),
        if (providers.isDurable) ...[
          ListTile(
            leading: const Icon(
              Icons.cloud_outlined,
              color: SoriColors.primary,
            ),
            title: Text(
              t.settingsCloudSignedIn(
                account.displayName ?? _providerLabel(t, providers),
              ),
            ),
            subtitle: Text(t.settingsCloudSignedInDesc),
          ),
          AccountNewLinkGuard(
            operations: _accountOperations,
            builder: (context, accountActionsAvailable) => Column(
              children: [
                ValueListenableBuilder<CloudBackupDeletionJournalState>(
                  valueListenable: _cloudDataDeletionJournalState,
                  builder: (context, cloudDeletionState, _) => ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: Text(t.settingsCloudBackupNow),
                    subtitle: Text(
                      _lastBackupAt == null
                          ? t.settingsCloudLastBackupNever
                          : t.settingsCloudLastBackup(
                              _formatBackupTime(_lastBackupAt!),
                            ),
                    ),
                    onTap:
                        accountActionsAvailable &&
                            cloudDeletionState ==
                                CloudBackupDeletionJournalState.clear
                        ? _onBackupTap
                        : () => _showActionLocked(cloudDeletionState),
                  ),
                ),
                ValueListenableBuilder<CloudBackupDeletionJournalState>(
                  valueListenable: _cloudDataDeletionJournalState,
                  builder: (context, cloudDeletionState, _) => ListTile(
                    leading: const Icon(Icons.cloud_download_outlined),
                    title: Text(t.settingsCloudRestore),
                    onTap:
                        accountActionsAvailable &&
                            cloudDeletionState ==
                                CloudBackupDeletionJournalState.clear
                        ? _onRestoreTap
                        : () => _showActionLocked(cloudDeletionState),
                  ),
                ),
                ValueListenableBuilder<CloudBackupDeletionJournalState>(
                  valueListenable: _cloudDataDeletionJournalState,
                  builder: (context, cloudDeletionState, _) => ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(t.profileSignOut),
                    onTap:
                        accountActionsAvailable &&
                            cloudDeletionState ==
                                CloudBackupDeletionJournalState.clear
                        ? _onSignOutTap
                        : () => _showActionLocked(cloudDeletionState),
                  ),
                ),
                ValueListenableBuilder<CloudBackupDeletionJournalState>(
                  valueListenable: _cloudDataDeletionJournalState,
                  builder: (context, cloudDeletionState, _) => ListTile(
                    leading: const Icon(
                      Icons.cloud_off_outlined,
                      color: SoriColors.danger,
                    ),
                    title: Text(
                      t.settingsCloudDeleteData,
                      style: SoriTextTheme.of(
                        context,
                      ).cardTitle.copyWith(color: SoriColors.danger),
                    ),
                    subtitle: Text(t.settingsCloudDeleteDataDesc),
                    // A persisted journal resumes the exact server request
                    // regardless of the account guard — the guard reports
                    // `blocked` for this very journal, which previously
                    // made its own resume unreachable (dead code).
                    onTap:
                        cloudDeletionState ==
                            CloudBackupDeletionJournalState.pending
                        ? _confirmCloudDeleteResume
                        : accountActionsAvailable &&
                              cloudDeletionState ==
                                  CloudBackupDeletionJournalState.clear
                        ? _confirmCloudDelete
                        : () => _showActionLocked(cloudDeletionState),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── 광고 섹션 제거 (2026-08-12, hardening fcec48d 이식) ──
        // 앱에 광고 SDK 가 없다 — ad_service.dart 는 스텁이고 google_mobile_ads
        // 는 비활성이다. 그런데 설정에 "광고 표시" 토글이 살아 있으면 Play
        // Data Safety 의 "광고 없음" 진술과 정면으로 모순된다. 토글을 지운다.
        // (키 자체는 storage_service 에 남기되 기본값을 false 로 내렸다 —
        //  토글만 지우면 기존 기기에 kl_ads_enabled=true 가 남아 향후 광고를
        //  도입할 때 기본 ON 이 된다.)

        // Permanent app guide. Dismissing the Today checklist never removes
        // this route.
        _Section(label: t.settingsGuideSection),
        ListTile(
          key: _guideKey,
          focusNode: _guideFocusNode,
          leading: const Icon(Icons.map_outlined, color: SoriColors.primary),
          title: Text(t.settingsGuideTitle),
          subtitle: Text(
            t.settingsGuideDescription,
            style: SoriTextTheme.of(context).caption,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushNamed('/guide'),
        ),

        // ── 안내 다시 보기 ──
        _Section(label: t.settingsTutorialResetSection),
        ListTile(
          leading: const Icon(Icons.replay_rounded),
          title: Text(t.settingsTutorialResetTitle),
          subtitle: Text(t.settingsTutorialResetSubtitle),
          onTap: _resetTutorials,
        ),

        // ── Datenschutz: Analytics/Crashlytics Opt-in (TTDSG §25,
        //    DSGVO Art. 7 Abs. 3 — jederzeit widerrufbar) ──
        _Section(label: t.settingsPrivacySection),
        SwitchListTile(
          secondary: const Icon(Icons.insights_outlined),
          title: Text(t.settingsAnalyticsTitle),
          subtitle: Text(t.settingsAnalyticsDesc),
          value: Storage.analyticsConsent,
          onChanged: (v) async {
            await PrivacyConsentService.setAnalytics(v);
            if (mounted) {
              setState(() {});
            }
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bug_report_outlined),
          title: Text(t.settingsCrashTitle),
          subtitle: Text(t.settingsCrashDesc),
          value: Storage.crashConsent,
          onChanged: (v) async {
            await PrivacyConsentService.setCrash(v);
            if (mounted) {
              setState(() {});
            }
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.mic_none_rounded),
          title: Text(t.settingsPronunciationConsentTitle),
          subtitle: Text(
            Storage.pronunciationConsent
                ? t.settingsPronunciationConsentDesc
                : t.settingsPronunciationConsentOff,
            style: SoriTextTheme.of(context).caption,
          ),
          value: Storage.pronunciationConsent,
          onChanged: (value) async {
            if (value && !await _confirmPronunciationConsent()) {
              return;
            }
            await Storage.setPronunciationConsent(value);
            if (mounted) {
              setState(() {});
            }
          },
        ),

        // ── Reset ──
        _Section(label: ''),
        AccountNewLinkGuard(
          operations: _accountOperations,
          builder: (context, accountActionsAvailable) => Column(
            children: [
              // Local reset stays available in every journal state: the
              // wipe preserves durable account journals (see
              // Storage.resetAll) and only an active replacement
              // transition may still refuse it at the storage fence.
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: SoriColors.danger,
                ),
                title: Text(
                  t.settingsReset,
                  style: SoriTextTheme.of(
                    context,
                  ).cardTitle.copyWith(color: SoriColors.danger),
                ),
                onTap: _confirmReset,
              ),
              ValueListenableBuilder<CloudBackupDeletionJournalState>(
                valueListenable: _cloudDataDeletionJournalState,
                builder: (context, cloudDeletionState, _) => KeyedSubtree(
                  key: _accountDeletionKey,
                  child: ListTile(
                    leading: const Icon(
                      Icons.person_remove_outlined,
                      color: SoriColors.danger,
                    ),
                    title: Text(
                      t.settingsAccountDelete,
                      style: SoriTextTheme.of(
                        context,
                      ).cardTitle.copyWith(color: SoriColors.danger),
                    ),
                    subtitle: Text(t.settingsAccountDeleteDesc),
                    onTap:
                        accountActionsAvailable &&
                            cloudDeletionState ==
                                CloudBackupDeletionJournalState.clear
                        ? _confirmAccountDelete
                        : () => _showActionLocked(cloudDeletionState),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── DEBUG: Premium-Override (nur im Debug-Build sichtbar) ──
        // Damit Gating + Paywall ohne RevenueCat-Dashboard testbar sind.
        // Wird im Release-Build NICHT angezeigt (kein Gratis-Premium-Schalter).
        if (kDebugMode) ...[
          _Section(label: 'DEBUG'),
          SwitchListTile(
            secondary: const Icon(
              Icons.workspace_premium_outlined,
              color: SoriColors.gold,
            ),
            title: const Text('Premium (Dev-Override)'),
            subtitle: Text(
              'Nur Debug: testet Gating/Paywall ohne RevenueCat',
              style: SoriTextTheme.of(context).cardSubtitle,
            ),
            value: Storage.devPremiumOverride,
            activeThumbColor: SoriColors.gold,
            onChanged: (v) async {
              await PremiumService.setDevOverride(v);
              if (mounted) setState(() {});
            },
          ),
        ],

        // ── About ──
        _Section(label: t.settingsAbout),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(t.settingsVersion(_appVersion)),
          subtitle: Text(t.settingsMadeWith),
        ),
        ListTile(
          leading: const Icon(Icons.auto_stories_outlined),
          title: Text(t.settingsOriginStoryTitle),
          subtitle: Text(t.settingsOriginStorySubtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _showOriginStory,
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(t.settingsPrivacyTitle),
          subtitle: Text(t.settingsPrivacySubtitle),
          trailing: const Icon(Icons.copy_rounded, size: 18),
          onTap: _copyPrivacyUrl,
        ),
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined),
          title: Text(t.settingsAccountDeletionTitle),
          subtitle: Text(t.settingsAccountDeletionSubtitle),
          trailing: const Icon(Icons.copy_rounded, size: 18),
          onTap: _copyDeletionUrl,
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(t.settingsTermsTitle),
          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
          onTap: () => openExternalUrl(context, _termsUrl),
        ),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: Text(t.settingsImpressumTitle),
          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
          onTap: () => openExternalUrl(context, _impressumUrl),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(t.settingsLicensesTitle),
          subtitle: Text(t.settingsLicensesSubtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Hangul Sori',
            applicationVersion: _appVersion,
            applicationLegalese: '© 2026 Hangul Sori',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.library_books_outlined),
          title: Text(t.settingsDataSourcesTitle),
          subtitle: Text(t.settingsDataSourcesSubtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _showDataSources,
        ),
      ],
    );
  }

  void _showOriginStory() {
    final t = AppL10n.of(context);
    showSoriSheet<void>(
      context: context,
      maxTextScaleFactor: 2.0,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              t.settingsOriginStoryTitle,
              style: SoriTextTheme.of(ctx).h2,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Text(t.settingsOriginStoryBody, style: SoriTextTheme.of(ctx).body),
          const SizedBox(height: Spacing.md),
          Text(
            t.settingsOriginStoryFounder,
            style: SoriTextTheme.of(ctx).bodySmall.copyWith(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.outlined(
            label: MaterialLocalizations.of(ctx).closeButtonLabel,
            fullWidth: true,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  /// CC BY-SA 2.0 KR 라이선스 준수 — NIKL 우리말샘 등 데이터 출처 표시.
  void _showDataSources() {
    final t = AppL10n.of(context);
    showSoriSheet<void>(
      context: context,
      showHandle: true,
      scrollable: false,
      maxHeightFactor: 0.92,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          children: [
            Text(t.settingsDataSourcesTitle, style: SoriTextTheme.of(ctx).h2),
            const SizedBox(height: 6),
            Text(
              t.settingsDataSourcesIntro,
              style: SoriTextTheme.of(ctx).bodySmall.copyWith(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            const _DataSourceCard(
              name: '우리말샘 (National Institute of Korean Language)',
              role: 'Korean definitions, English translations, vocabulary',
              license: 'CC BY-SA 2.0 KR',
              url: 'https://opendict.korean.go.kr',
              attribution: '국립국어원 우리말샘 (opendict.korean.go.kr)',
            ),
            const _DataSourceCard(
              name: 'open-korean-text',
              role: 'Verified Korean noun dictionary (~140k entries)',
              license: 'Apache 2.0',
              url: 'https://github.com/open-korean-text/open-korean-text',
              attribution: 'open-korean-text contributors',
            ),
            const _DataSourceCard(
              name: 'hermitdave/FrequencyWords',
              role: 'Korean word frequency ranking (OpenSubtitles)',
              license: 'CC BY-SA 4.0',
              url: 'https://github.com/hermitdave/FrequencyWords',
              attribution: 'Hermit Dave & OpenSubtitles community',
            ),
            const _DataSourceCard(
              name: 'DeepL',
              role: 'Korean → German translation',
              license:
                  'Translation output: factual data, attribution voluntary',
              url: 'https://www.deepl.com',
              attribution: 'DeepL SE',
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SoriColors.warning.withValues(alpha: 0.10),
                borderRadius: SoriRadius.brSm,
                border: Border.all(
                  color: SoriColors.warning.withValues(alpha: 0.30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: SoriColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.settingsDataLicenseNote,
                          style: SoriTextTheme.of(ctx).label,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.settingsDataLicenseBody,
                    style: SoriTextTheme.of(ctx).caption.copyWith(
                      height: 1.5,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.btnClose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _privacyUrl = 'https://hangul-sori.com/privacy';
  static const String _termsUrl = 'https://hangul-sori.com/terms';
  static const String _impressumUrl = 'https://hangul-sori.com/impressum';
  static const String _deletionUrl = 'https://hangul-sori.com/account-deletion';

  Future<void> _copyPrivacyUrl() async {
    await _copyUrl(_privacyUrl);
  }

  Future<void> _copyDeletionUrl() async {
    await _copyUrl(_deletionUrl);
  }

  Future<void> _copyUrl(String url) async {
    // Im Browser öffnen; bei Fehler (kein Browser/Web-Sandbox) Fallback auf
    // Zwischenablage + Snackbar (in [openExternalUrl]).
    HapticFeedback.selectionClick();
    await openExternalUrl(context, url);
  }

  String _levelLabel(AppL10n t, LearnerLevel lvl) {
    final name = switch (lvl) {
      LearnerLevel.a1 => t.onboardingLevelA1,
      LearnerLevel.a2 => t.onboardingLevelA2,
      LearnerLevel.b1 => t.onboardingLevelB1,
      LearnerLevel.b2 => t.onboardingLevelB2,
      LearnerLevel.c1 => t.onboardingLevelC1,
      LearnerLevel.c2 => t.onboardingLevelC2,
    };
    return '${lvl.display} · $name';
  }

  String _courseStartLevelDisplay(AppL10n t) {
    final level =
        LearnerLevel.fromCode(Storage.dedicatedCoursePlacementLevelCode) ??
        LearnerLevel.fromCode(Storage.userLevelCode) ??
        LearnerLevel.a1;
    return _levelLabel(t, level);
  }

  String _browseLevelDisplay(AppL10n t) {
    final level =
        LearnerLevel.fromCode(Storage.browseLevelCode) ??
        LearnerLevel.fromCode(Storage.userLevelCode) ??
        LearnerLevel.a1;
    return _levelLabel(t, level);
  }

  /// 학습 동반 캐릭터 변경. 저장은 [MascotPreference.set] 하나로 통일 —
  /// 온보딩 선택 화면과 완전히 같은 경로라 두 곳이 어긋날 수 없다.
  Future<void> _showMascotDialog(MascotKind current) async {
    final t = AppL10n.of(context);
    const options = <MascotKind>[MascotKind.tiger, MascotKind.magpie];
    final picked = await showSoriDialog<MascotKind>(
      context: context,
      builder: (ctx) => SoriSimpleDialog(
        title: Text(t.characterSelectionTitle),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, option),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Mascot(kind: option, size: 44),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option == MascotKind.magpie
                                ? t.characterRomanMagpie
                                : t.characterNameTiger,
                            style: SoriTextTheme.of(ctx).cardTitle,
                          ),
                          Text(
                            option == MascotKind.magpie
                                ? t.characterTraitMagpie
                                : t.characterTraitTiger,
                            style: SoriTextTheme.of(ctx).caption,
                          ),
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
            ),
        ],
      ),
    );
    if (picked != null && picked != current) {
      await MascotPreference.setChosen(picked);
    }
  }

  Future<LearnerLevel?> _pickLevel({
    required String title,
    required LearnerLevel current,
  }) {
    final t = AppL10n.of(context);
    return showSoriDialog<LearnerLevel>(
      context: context,
      builder: (ctx) => SoriSimpleDialog(
        title: Text(title),
        children: [
          for (final level in LearnerLevel.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(level),
              child: Row(
                children: [
                  Expanded(child: Text(_levelLabel(t, level))),
                  if (level == current)
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
  }

  Future<void> _showCourseStartDialog() async {
    final t = AppL10n.of(context);
    final current =
        LearnerLevel.fromCode(Storage.dedicatedCoursePlacementLevelCode) ??
        LearnerLevel.fromCode(Storage.userLevelCode) ??
        LearnerLevel.a1;
    final picked = await _pickLevel(
      title: t.settingsCourseStartTitle,
      current: current,
    );
    if (!mounted || picked == null || picked == current) {
      return;
    }
    final confirmed = await showSoriDialog<bool>(
      context: context,
      builder: (ctx) => SoriDialog(
        title: Text(t.settingsCourseStartConfirmTitle),
        content: Text(t.settingsCourseStartConfirmDescription(picked.display)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.settingsCourseStartConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await CourseProgressService.shared.initializeForPlacement(
      picked.code,
      syncBrowseLevel: false,
    );
    if (mounted) {
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  Future<void> _showBrowseLevelDialog() async {
    final t = AppL10n.of(context);
    final current =
        LearnerLevel.fromCode(Storage.browseLevelCode) ??
        LearnerLevel.fromCode(Storage.userLevelCode) ??
        LearnerLevel.a1;
    final picked = await _pickLevel(
      title: t.settingsBrowseLevelTitle,
      current: current,
    );
    if (picked == null || picked == current) {
      return;
    }
    await Storage.setBrowseLevelCode(picked.code);
    if (mounted) {
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  Future<void> _openPlacementDiagnostic() async {
    await Navigator.of(context).push<void>(
      SoriTransitions.fadeScale(
        (_) => PlacementDiagnosticScreen(
          onChooseLevel: (levelCode) async {
            await CourseProgressService.shared.initializeForPlacement(
              levelCode,
              // A diagnostic result is the one Settings action that moves both
              // the sequential course and the library filter. Commit both in
              // the course writer so a rejected preference write cannot leave
              // the learner split across two levels.
              syncBrowseLevel: true,
            );
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onBackupTap() async {
    final t = AppL10n.of(context);
    try {
      final result = await CloudSync.backupWithResult();
      if (!mounted) return;
      if (result != CloudWriteResult.completed) {
        soriToast(context, t.accountOperationRetryBody);
        return;
      }
      soriNotice(
        context,
        t.settingsCloudBackupSuccess,
        duration: const Duration(seconds: 2),
      );
      await _loadLastBackupAt();
    } catch (_) {
      if (!mounted) return;
      _showOfflineDialog(retry: _onBackupTap);
    }
  }

  Future<void> _onRestoreTap() async {
    final t = AppL10n.of(context);
    try {
      final result = await CloudSync.restoreWithResult();
      if (!mounted) return;
      final message = switch (result) {
        CloudRestoreResult.completed => t.settingsCloudRestoreSuccess,
        CloudRestoreResult.empty => t.settingsCloudRestoreEmpty,
        CloudRestoreResult.blocked ||
        CloudRestoreResult.stale => t.accountOperationRetryBody,
      };
      if (result == CloudRestoreResult.blocked ||
          result == CloudRestoreResult.stale) {
        soriToast(context, message);
      } else {
        soriNotice(context, message);
      }
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _showOfflineDialog(retry: _onRestoreTap);
    }
  }

  Future<void> _onDeleteCloudData() async {
    final t = AppL10n.of(context);
    try {
      final result =
          await (widget.cloudDataDeletion ?? AuthService.deleteCloudData)();
      if (!mounted) return;
      if (result != CloudWriteResult.completed) {
        soriToast(context, t.settingsCloudDeleteDataFailed);
        return;
      }
      HapticFeedback.heavyImpact();
      soriNotice(
        context,
        t.settingsCloudDeleteDataSuccess,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      if (!mounted) return;
      soriToast(context, t.settingsCloudDeleteDataFailed);
    }
  }

  Future<void> _onDeleteAccount() {
    return _runAccountDeletion(_accountDeletionWorkflow.run);
  }

  Future<void> _retryLocalAccountCleanup() {
    return _runAccountDeletion(_accountDeletionWorkflow.retryLocalCleanup);
  }

  Future<void> _runAccountDeletion(Future<void> Function() operation) async {
    final t = AppL10n.of(context);
    final rootNav = Navigator.of(context);
    try {
      await operation();
      if (!mounted) {
        return;
      }
      HapticFeedback.heavyImpact();
      soriNotice(
        context,
        t.settingsAccountDeleteSuccess,
        duration: const Duration(seconds: 3),
      );
      // Local cleanup removes consent and the V2 journal. Restart through the
      // single first-run resolver so account deletion can never bypass the
      // legal gate or enter AppShell with an empty identity.
      rootNav.pushNamedAndRemoveUntil('/splash', (route) => false);
    } on AccountDeletionFailure catch (failure) {
      // 원인 리스트는 예외에 실려 오는데 지금까지 **한 번도 기록되지 않았다**.
      // UI 문구는 그대로 두고 로그에만 남긴다(redaction 은 진단 유틸이 보장).
      AccountFailureDiagnostics.logAll(
        'deletion.cleanupFailed',
        failure.causes,
        detail: 'identityRecoveryPending=${failure.identityRecoveryPending}',
      );
      if (!mounted) {
        return;
      }
      await showSafeAccountFailure(
        context,
        deletion: true,
        retry: failure.identityRecoveryPending
            ? _onDeleteAccount
            : _retryLocalAccountCleanup,
      );
    } catch (error) {
      // ⚠️ 예전엔 `catch (_)` 였다. 여기로 오는 대표 케이스가 원격 삭제 거부
      // (`AccountOperationFailure` — appCheckRequired·authenticationRequired 등)
      // 인데 오류 객체를 통째로 버려서, 실기기에서 `operation: null` 만 남고
      // **거부 사유를 끝내 알 수 없었다**(2026-08-06). deletion journal 탈출구는
      // 바로 이 코드로 "서버 operation 이 존재할 수 없음"을 판정해야 하므로
      // 보존이 선행 조건이다. 사용자 화면 문구는 종전과 동일하게 안전한 고정
      // 문구만 쓴다 — raw exception 은 로그에만, 그것도 redact 된 코드만.
      AccountFailureDiagnostics.log('deletion.failed', error);
      if (!mounted) {
        return;
      }
      await showSafeAccountFailure(
        context,
        deletion: true,
        retry: _onDeleteAccount,
        reason: classifyAccountFailure(error),
      );
    }
  }

  Future<void> _openSubscriptionManagement() async {
    final t = AppL10n.of(context);
    try {
      await _subscriptionManager.open();
    } catch (_) {
      if (!mounted) {
        return;
      }
      soriToast(context, t.settingsManageSubscriptionFailed);
    }
  }

  void _showOfflineDialog({required Future<void> Function() retry}) {
    final t = AppL10n.of(context);
    showSoriDialog<void>(
      context: context,
      builder: (ctx) => SoriDialogFrame(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        insetPadding: const EdgeInsets.all(Spacing.xl),
        shape: RoundedRectangleBorder(borderRadius: SoriRadius.brLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: SoriEmptyState(
            asset: 'assets/illustrations/error/offline_lantern.png',
            icon: Icons.wifi_off_rounded,
            title: t.settingsOfflineTitle,
            body: t.settingsOfflineBody,
            ctaLabel: t.btnRetry,
            onCta: () {
              Navigator.of(ctx).pop();
              retry();
            },
            secondaryLabel: t.btnCancel,
            onSecondary: () => Navigator.of(ctx).pop(),
            illustrationMaxHeight: 160,
            accent: SoriColors.gold,
          ),
        ),
      ),
    );
  }

  Future<void> _onGoogleTap() async {
    await runConfirmedAccountLink(
      context,
      operations: _accountOperations,
      provider: AccountLinkProvider.google,
      onCompleted: () async {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _onAppleTap() async {
    await runConfirmedAccountLink(
      context,
      operations: _accountOperations,
      provider: AccountLinkProvider.apple,
      onCompleted: () async {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _onSignOutTap() async {
    try {
      await AuthService.signOut();
    } catch (_) {
      // signOut bricht still ab, wenn Firebase nicht verfügbar ist.
    }
    if (mounted) setState(() {});
  }

  Future<void> _resetTutorials() async {
    await Storage.resetTutorials();
    if (!mounted) {
      return;
    }
    final t = AppL10n.of(context);
    final nav = Navigator.of(context);
    HapticFeedback.lightImpact();
    soriNotice(
      context,
      t.settingsTutorialResetDone,
      duration: const Duration(seconds: 2),
    );
    // 홈으로 돌아가 즉시 안내 투어를 다시 띄운다(재시작 불필요).
    nav.popUntil((r) => r.isFirst);
    AppShell.replayHomeTour.value++;
  }

  void _confirmReset() {
    final t = AppL10n.of(context);
    showSoriDialog<void>(
      context: context,
      builder: (ctx) => SoriDialog(
        backgroundColor: SoriSurfaces.of(context).surface,
        title: Text(t.settingsReset),
        content: Text(t.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SoriColors.danger),
            onPressed: () async {
              final dialogNav = Navigator.of(ctx);
              final rootNav = Navigator.of(context);
              try {
                final injectedReset = widget.resetAllData;
                if (injectedReset != null) {
                  // Test/embedding adapters own their own serialization.
                  await injectedReset();
                } else {
                  await CourseProgressService.shared.runLocalStorageWipeBarrier(
                    Storage.resetAll,
                  );
                }
                await WordImageService.deleteAll();
                await TtsService.clearCache();
                DataLoader.reset();
                if (!mounted || !ctx.mounted) return;
                dialogNav.pop();
                HapticFeedback.heavyImpact();
                // A complete local reset removes consent and the V2 journal.
                // Always restart through the single first-run resolver instead
                // of leaving an unconsented AppShell alive in memory.
                rootNav.pushNamedAndRemoveUntil('/splash', (route) => false);
              } on CloudBackupDeletionResetBlockedException {
                if (!mounted) return;
                if (ctx.mounted) {
                  dialogNav.pop();
                }
                if (!mounted) return;
                soriToast(context, t.accountOperationRetryBody);
              }
            },
            child: Text(t.btnConfirm),
          ),
        ],
      ),
    );
  }

  void _confirmCloudDelete() {
    final t = AppL10n.of(context);
    _showDangerConfirm(
      title: t.settingsCloudDeleteDataConfirmTitle,
      body: t.settingsCloudDeleteDataConfirmBody,
      confirmLabel: t.btnDelete,
      onConfirm: _onDeleteCloudData,
    );
  }

  /// Resume wording for a persisted cloud-deletion journal — the request is
  /// continued, never created twice, so the new-deletion warning would lie.
  void _confirmCloudDeleteResume() {
    final t = AppL10n.of(context);
    _showDangerConfirm(
      title: t.settingsCloudResumeDeleteTitle,
      body: t.settingsCloudResumeDeleteBody,
      confirmLabel: t.accountLockedResumeNow,
      onConfirm: _onDeleteCloudData,
    );
  }

  /// Locked tiles route their tap here instead of going dead (onTap: null
  /// swallowed taps with zero feedback — Jin's "button does not press" bug).
  Future<void> _showActionLocked(
    CloudBackupDeletionJournalState cloudDeletionState,
  ) {
    return showAccountActionLocked(
      context,
      operations: _accountOperations,
      cloudDeletionState: cloudDeletionState,
      resumeCloudDeletion: _onDeleteCloudData,
      retryDeletion: _onDeleteAccount,
    );
  }

  void _confirmAccountDelete() {
    final t = AppL10n.of(context);
    _showDangerConfirm(
      title: t.settingsAccountDeleteConfirmTitle,
      body: t.settingsAccountDeleteConfirmBody,
      warning: t.settingsAccountDeleteSubscriptionWarning,
      secondaryActionLabel: t.settingsManageSubscription,
      onSecondaryAction: _openSubscriptionManagement,
      confirmLabel: t.btnDelete,
      onConfirm: _onDeleteAccount,
    );
  }

  void _showDangerConfirm({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    String? warning,
    String? secondaryActionLabel,
    Future<void> Function()? onSecondaryAction,
  }) {
    final t = AppL10n.of(context);
    showSoriDialog<void>(
      context: context,
      builder: (ctx) => SoriDialog(
        backgroundColor: SoriSurfaces.of(context).surface,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            if (warning != null) ...[
              const SizedBox(height: Spacing.md),
              Text(
                warning,
                style: SoriTextTheme.of(context).body.copyWith(
                  color: SoriColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (secondaryActionLabel != null && onSecondaryAction != null)
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SoriColors.danger),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              nav.pop();
              await onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: SoriTextTheme.of(context).cardSubtitle.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (label.isNotEmpty) const SizedBox(width: 10),
          // 단청 골드 hairline — 잡지식 섹션 리듬(SoriSectionHeader와 동일 어휘).
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: SoriColors.gold.withValues(alpha: 0.35),
                borderRadius: SoriRadius.brPill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final String title;
  final T value;
  const _RadioTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      activeColor: SoriColors.primary,
    );
  }
}

/// 데이터 출처 카드 — Settings → Data sources sheet.
/// CC BY-SA 2.0 KR 라이선스 준수 (NIKL 우리말샘) + 기타 외부 데이터 attribution.
class _DataSourceCard extends StatelessWidget {
  final String name;
  final String role;
  final String license;
  final String url;
  final String attribution;

  const _DataSourceCard({
    required this.name,
    required this.role,
    required this.license,
    required this.url,
    required this.attribution,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.selectionClick();
    if (!context.mounted) return;
    soriNotice(context, url, duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: SoriRadius.brMd,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: SoriRadius.brMd,
            border: Border.all(color: onSurface.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(name, style: SoriTextTheme.of(context).cardTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SoriColors.primary.withValues(alpha: 0.15),
                      borderRadius: SoriRadius.brSm,
                    ),
                    child: Text(
                      license,
                      style: SoriTextTheme.of(context).eyebrow.copyWith(
                        color: SoriColors.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                role,
                style: SoriTextTheme.of(context).caption.copyWith(
                  color: onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.link_rounded, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      url,
                      style: SoriTextTheme.of(context).caption.copyWith(
                        color: onSurface.withValues(alpha: 0.7),
                      ),
                      softWrap: true,
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 14),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Attribution: $attribution',
                style: SoriTextTheme.of(context).caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 사운드 설정 (ADR-002 §7) — AudioPolicy 가 단일 진실원천.
// 마스터 off 는 하위를 숨기지 않고 비활성(구조 유지, §7-1).
// ═══════════════════════════════════════════════════════════════════════

class _SoundSettings extends StatelessWidget {
  const _SoundSettings();

  /// 미리듣기 — 호랑이는 growl(그르릉, "사운드 설정에서 세밀 조정"용으로
  /// 제작된 전용 사운드), 까치는 인사 짹짹. 현재 볼륨 그대로 재생.
  static Future<void> _previewCompanion() async {
    final volume = AudioPolicy.instance.volumeFor(SoundChannel.companion);
    if (volume <= 0) {
      return;
    }
    final kind = MascotPreference.selectedKind;
    if (kind == null) {
      return;
    }
    final asset = kind == MascotKind.tiger
        ? 'sfx/growl_tiger.mp3'
        : 'sfx/greet_magpie.mp3';
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      player.onPlayerComplete.listen((_) {
        player?.dispose();
      });
      await player.play(AssetSource(asset), volume: volume);
    } catch (_) {
      await player?.dispose();
    }
  }

  static void _previewSpeech() {
    TtsService.speak('안녕하세요');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final policy = AudioPolicy.instance;
    return ListenableBuilder(
      listenable: policy,
      builder: (context, _) {
        final master = policy.masterOn;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              secondary: const Icon(
                Icons.volume_up_outlined,
                color: SoriColors.primary,
              ),
              title: Text(t.settingsSoundMaster),
              subtitle: Text(t.settingsSoundMasterDesc),
              value: master,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                policy.setMasterOn(v);
              },
            ),
            if (master)
              _SoundVolumeSlider(
                semanticLabel: t.settingsSoundMasterVolume,
                value: policy.masterVolume,
                onChanged: (v) {
                  policy.setMasterVolume(v);
                },
              ),
            _SoundChannelTile(
              channel: SoundChannel.gameFeedback,
              icon: Icons.sports_esports_outlined,
              title: t.settingsSoundGame,
              subtitle: t.settingsSoundGameDesc,
              master: master,
              onPreview: SoundService.correct,
            ),
            _SoundChannelTile(
              channel: SoundChannel.companion,
              icon: Icons.pets,
              title: t.settingsSoundCompanion,
              subtitle: t.settingsSoundCompanionDesc,
              master: master,
              onPreview: _previewCompanion,
            ),
            _SoundChannelTile(
              channel: SoundChannel.ambience,
              icon: Icons.landscape_outlined,
              title: t.settingsSoundAmbience,
              subtitle: t.settingsSoundAmbienceDesc,
              master: master,
            ),
            _SoundChannelTile(
              channel: SoundChannel.cinematic,
              icon: Icons.door_front_door_outlined,
              title: t.settingsSoundCinematic,
              subtitle: t.settingsSoundCinematicDesc,
              master: master,
            ),
            _SoundChannelTile(
              channel: SoundChannel.speech,
              icon: Icons.record_voice_over_outlined,
              title: t.settingsSoundSpeech,
              subtitle: t.settingsSoundSpeechDesc,
              offWarning: t.settingsSoundSpeechWarn,
              master: master,
              onPreview: _previewSpeech,
            ),
            // 채널 타일과 동일하게 — 마스터 off 시 비활성 + 흐림(시각 일관).
            Opacity(
              opacity: master ? 1.0 : 0.4,
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.volume_down_outlined,
                  color: SoriColors.primary,
                ),
                title: Text(t.settingsSoundDuck),
                subtitle: Text(t.settingsSoundDuckDesc),
                value: policy.duckOnSpeech,
                onChanged: master
                    ? (v) {
                        policy.setDuckOnSpeech(v);
                      }
                    : null,
              ),
            ),
            // iOS 전용 — Android 에는 "무음 스위치"라는 개념이 없고,
            // AudioPolicy 도 이 값을 Android 컨텍스트에 반영하지 않는다
            // (반영하면 벨소리 스트림으로 라우팅돼 앱 전체가 무음이 된다 —
            // AudioPolicy.buildAndroidContext 주석). 죽은 컨트롤을 노출하지
            // 않기 위해 Android/웹에서는 타일 자체를 감춘다.
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
              Opacity(
                opacity: master ? 1.0 : 0.4,
                child: SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_paused_outlined,
                    color: SoriColors.primary,
                  ),
                  title: Text(t.settingsSoundRespectSilent),
                  subtitle: Text(t.settingsSoundRespectSilentDesc),
                  value: policy.respectSilentMode,
                  onChanged: master
                      ? (v) {
                          policy.setRespectSilentMode(v);
                        }
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SoundChannelTile extends StatelessWidget {
  final SoundChannel channel;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? offWarning;
  final bool master;
  final VoidCallback? onPreview;

  const _SoundChannelTile({
    required this.channel,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.master,
    this.offWarning,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final policy = AudioPolicy.instance;
    final on = policy.isOn(channel);
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, color: SoriColors.primary),
          title: Text(title),
          // speech 를 끈 뒤에는 경고를 본문 자리에 보여준다 — 끄기 전
          // 확인 다이얼로그는 두지 않는다 (ADR §7-1).
          subtitle: Text(!on && offWarning != null ? offWarning! : subtitle),
          // Switch 에 채널명 라벨 병합 — raw ListTile+trailing 구조라
          // 스크린리더가 켜짐/꺼짐만 읽는 것을 방지 (ADR §7-2).
          trailing: Semantics(
            label: title,
            child: Switch(
              value: on,
              onChanged: master
                  ? (v) {
                      HapticFeedback.selectionClick();
                      policy.setChannelOn(channel, v);
                    }
                  : null,
            ),
          ),
          // 행 본문 탭 = 그 카테고리 대표 소리 미리듣기 (현재 볼륨 그대로).
          onTap: master && on && onPreview != null ? onPreview : null,
        ),
        // 슬라이더는 켜졌을 때만 — 항상 펼치면 설정이 슬라이더 벽이 된다.
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: (master && on)
              ? _SoundVolumeSlider(
                  semanticLabel: title,
                  value: policy.sliderOf(channel),
                  onChanged: (v) {
                    policy.setChannelVolume(channel, v);
                  },
                  onChangeEnd: onPreview,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
    return master ? body : Opacity(opacity: 0.4, child: body);
  }
}

class _SoundVolumeSlider extends StatelessWidget {
  final String semanticLabel;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onChangeEnd;

  const _SoundVolumeSlider({
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
        label: semanticLabel,
        value: '$percent %',
        child: Slider(
          value: value.clamp(0.0, 1.0),
          divisions: 10,
          label: '$percent %',
          onChanged: onChanged,
          onChangeEnd: (_) => onChangeEnd?.call(),
        ),
      ),
    );
  }
}
