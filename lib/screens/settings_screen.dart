import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/external_link.dart';
import '../services/storage_service.dart';
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
import '../services/account/account_transition_coordinator.dart';
import '../services/account/account_ui_operations.dart';
import '../services/account/cloud_backup_deletion.dart';
import '../services/account/cloud_restore_result.dart';
import '../services/account/cloud_write_session.dart';
import 'app_shell.dart';
import '../services/cloud_sync.dart';
import '../models/scenario.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/account_operation_ui.dart';

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

  factory AccountDeletionCleanupAdapter.production() =>
      AccountDeletionCleanupAdapter(
        deleteRemote: AuthService.deleteAccount,
        resetStorage: () => Storage.resetAllStrict(
          canonicalizeAccountDeletionCheckpoint:
              AuthService.canonicalizeCompletedDeletionCheckpoint,
        ),
        disablePush: pushService.disableStrict,
        deleteImages: WordImageService.deleteAllStrict,
        clearTts: TtsService.clearCacheStrict,
        resetMemory: DataLoader.reset,
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

/// Stops before local destruction when remote deletion fails. Once the remote
/// identity is gone, every independent privacy cleanup is attempted and all
/// failures are reported together.
class AccountDeletionWorkflow {
  const AccountDeletionWorkflow(
    this.operations, {
    Future<void> Function()? completeCheckpoint,
  }) : _completeCheckpoint = completeCheckpoint ?? _noop;

  final AccountDeletionCleanupOperations operations;
  final Future<void> Function() _completeCheckpoint;

  static Future<void> _noop() async {}

  Future<void> run() async {
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
    return _runLocalCleanup(<Object>[], identityRecoveryPending: false);
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
  });

  final AuthAccountSnapshot? account;
  final AccountDeletionWorkflow? accountDeletionWorkflow;
  final SubscriptionManagementLauncher? subscriptionManager;
  final AccountUiOperations? accountOperations;
  final Future<CloudWriteResult> Function()? cloudDataDeletion;
  final ValueListenable<CloudBackupDeletionJournalState>?
  cloudDataDeletionJournalState;
  final Future<void> Function()? resetAllData;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _ttsRate;

  AccountDeletionWorkflow get _accountDeletionWorkflow =>
      widget.accountDeletionWorkflow ??
      AccountDeletionWorkflow(
        AccountDeletionCleanupAdapter.production(),
        completeCheckpoint: AuthService.completeLocalAccountDeletionCleanup,
      );

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

  @override
  void initState() {
    super.initState();
    _ttsRate = Storage.ttsRate;
    if (widget.cloudDataDeletionJournalState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AuthService.refreshCloudBackupDeletionJournalState();
      });
    }
  }

  // ── M3: Benachrichtigungen ──────────────────────────────────
  String _notifTimeLabel() =>
      '${Storage.notificationHour.toString().padLeft(2, '0')}:00';

  Future<void> _onToggleNotif(bool v) async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Storage.setNotificationsEnabled(v);
    if (v) {
      final granted = await NotificationService.requestPermission();
      if (granted) {
        await NotificationService.scheduleDaily(
          hour: Storage.notificationHour,
          minute: 0,
          title: t.notificationTitle,
          body: t.notificationBody,
        );
        // 늦은 저녁 스트릭 보호 알림 (별도 채널 · 강한 retention 넛지)
        await NotificationService.scheduleStreakSaver(
          hour: 21,
          minute: 0,
          title: t.notifStreakSaverTitle,
          body: t.notifStreakSaverBody,
        );
        // FCM is optional. A failed cloud registration must not undo local
        // reminder permission or scheduling.
        await pushService.enable();
      } else {
        await Storage.setNotificationsEnabled(false);
        await pushService.disable();
        messenger.showSnackBar(SnackBar(content: Text(t.settingsNotifDenied)));
      }
    } else {
      await NotificationService.cancelAll();
      await pushService.disable();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: soriClampPadding(
            MediaQuery.sizeOf(context).width,
            base: const EdgeInsets.symmetric(vertical: 8),
          ),
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

            // ── Lernlevel ──
            _Section(label: t.settingsUserLevel),
            ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: SoriColors.primary,
              ),
              title: Text(_levelDisplay(t)),
              subtitle: Text(
                t.settingsUserLevelChange,
                style: SoriTextTheme.of(context).caption,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: SoriColors.darkTextMuted,
              ),
              onTap: _showLevelDialog,
            ),

            // ── TTS Speed ──
            _Section(label: t.settingsTtsRate),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  Slider(
                    value: _ttsRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: _ttsRate.toStringAsFixed(2),
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _ttsRate = v);
                    },
                    onChangeEnd: (v) {
                      TtsService.setRate(v);
                      TtsService.speak('안녕하세요');
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.settingsTtsRateSlow,
                        style: SoriTextTheme.of(context).cardSubtitle,
                      ),
                      Text(
                        t.settingsTtsRateNormal,
                        style: SoriTextTheme.of(context).cardSubtitle,
                      ),
                      Text(
                        t.settingsTtsRateFast,
                        style: SoriTextTheme.of(context).cardSubtitle,
                      ),
                    ],
                  ),
                ],
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SoriColors.primary,
                  ),
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
            _Section(label: t.settingsCloudSection),
            AccountPendingOperationPanel(
              operations: _accountOperations,
              retryLocalDeletion: _onDeleteAccount,
              onCompleted: () async {
                if (mounted) setState(() {});
              },
            ),
            if (!providers.isDurable)
              ValueListenableBuilder<CloudBackupDeletionJournalState>(
                valueListenable: _cloudDataDeletionJournalState,
                builder: (context, cloudDeletionState, _) {
                  final durableActionsAvailable =
                      cloudDeletionState ==
                      CloudBackupDeletionJournalState.clear;
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
                              : null,
                        ),
                        if (AuthService.appleSignInAvailable)
                          ListTile(
                            leading: const Icon(Icons.apple),
                            title: Text(t.authAppleSignIn),
                            subtitle: Text(t.settingsCloudSignInDesc),
                            onTap: linkAvailable && durableActionsAvailable
                                ? _onAppleTap
                                : null,
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
                        onTap:
                            accountActionsAvailable &&
                                cloudDeletionState ==
                                    CloudBackupDeletionJournalState.clear
                            ? _onBackupTap
                            : null,
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
                            : null,
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
                            : null,
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
                          style: const TextStyle(color: SoriColors.danger),
                        ),
                        subtitle: Text(t.settingsCloudDeleteDataDesc),
                        // A confirmed pending journal may resume the exact server
                        // request; loading does not disclose or act on journal data.
                        onTap:
                            accountActionsAvailable &&
                                cloudDeletionState !=
                                    CloudBackupDeletionJournalState.loading
                            ? _confirmCloudDelete
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Werbung ──
            _Section(label: t.settingsAdsSection),
            SwitchListTile(
              title: Text(t.settingsShowAds),
              subtitle: Text(
                t.settingsShowAdsDesc,
                style: SoriTextTheme.of(context).caption,
              ),
              value: Storage.adsEnabled,
              onChanged: (v) async {
                await Storage.setAdsEnabled(v);
                if (mounted) setState(() {});
              },
              activeThumbColor: SoriColors.primary,
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

            // ── Reset ──
            _Section(label: ''),
            AccountNewLinkGuard(
              operations: _accountOperations,
              builder: (context, accountActionsAvailable) => Column(
                children: [
                  ValueListenableBuilder<CloudBackupDeletionJournalState>(
                    valueListenable: _cloudDataDeletionJournalState,
                    builder: (context, cloudDeletionState, _) => ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: SoriColors.danger,
                      ),
                      title: Text(
                        t.settingsReset,
                        style: const TextStyle(color: SoriColors.danger),
                      ),
                      onTap:
                          accountActionsAvailable &&
                              cloudDeletionState ==
                                  CloudBackupDeletionJournalState.clear
                          ? _confirmReset
                          : null,
                    ),
                  ),
                  ValueListenableBuilder<CloudBackupDeletionJournalState>(
                    valueListenable: _cloudDataDeletionJournalState,
                    builder: (context, cloudDeletionState, _) => ListTile(
                      leading: const Icon(
                        Icons.person_remove_outlined,
                        color: SoriColors.danger,
                      ),
                      title: Text(
                        t.settingsAccountDelete,
                        style: const TextStyle(color: SoriColors.danger),
                      ),
                      subtitle: Text(t.settingsAccountDeleteDesc),
                      onTap:
                          accountActionsAvailable &&
                              cloudDeletionState ==
                                  CloudBackupDeletionJournalState.clear
                          ? _confirmAccountDelete
                          : null,
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
                subtitle: const Text(
                  'Nur Debug — testet Gating/Paywall ohne RevenueCat',
                  style: TextStyle(
                    fontSize: 12,
                    color: SoriColors.darkTextMuted,
                  ),
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
              title: Text(t.settingsVersion(_appVersion())),
              subtitle: Text(t.settingsMadeWith),
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
                applicationVersion: _appVersion(),
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
        ),
      ),
    );
  }

  /// CC BY-SA 2.0 KR 라이선스 준수 — NIKL 우리말샘 등 데이터 출처 표시.
  void _showDataSources() {
    final t = AppL10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // edge-to-edge: 상단 시스템바를 피해서 연다 (잘림 방어).
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Theme.of(
                    ctx,
                  ).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(t.settingsDataSourcesTitle, style: SoriTextTheme.of(ctx).h2),
            const SizedBox(height: 6),
            Text(
              t.settingsDataSourcesIntro,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
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
                borderRadius: BorderRadius.circular(12),
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
                      Text(
                        t.settingsDataLicenseNote,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.settingsDataLicenseBody,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12.5,
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

  static const String _privacyUrl = 'https://hangul-sori.com/privacy.html';
  static const String _termsUrl = 'https://hangul-sori.com/terms.html';
  static const String _impressumUrl = 'https://hangul-sori.com/impressum.html';
  static const String _deletionUrl =
      'https://hangul-sori.com/account-deletion.html';

  // pubspec.yaml `version:`과 동기 — 버전 범프 시 함께 갱신할 것.
  String _appVersion() => '2.0.1';

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

  String _levelDisplay(AppL10n t) {
    final lvl = LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final name = switch (lvl) {
      LearnerLevel.a1 => t.onboardingLevelA1,
      LearnerLevel.a2 => t.onboardingLevelA2,
      LearnerLevel.b1 => t.onboardingLevelB1,
      LearnerLevel.b2 => t.onboardingLevelB2,
    };
    return '${lvl.display} — $name';
  }

  void _showLevelDialog() {
    final t = AppL10n.of(context);
    final current =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    String nameFor(LearnerLevel lvl) => switch (lvl) {
      LearnerLevel.a1 => t.onboardingLevelA1,
      LearnerLevel.a2 => t.onboardingLevelA2,
      LearnerLevel.b1 => t.onboardingLevelB1,
      LearnerLevel.b2 => t.onboardingLevelB2,
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoriSurfaces.of(context).surface,
        title: Text(t.settingsUserLevel),
        content: RadioGroup<LearnerLevel>(
          groupValue: current,
          onChanged: (v) async {
            if (v == null) return;
            final nav = Navigator.of(ctx);
            await Storage.setUserLevelCode(v.code);
            HapticFeedback.selectionClick();
            if (!mounted) return;
            nav.pop();
            setState(() {});
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: LearnerLevel.values.map((lvl) {
              return RadioListTile<LearnerLevel>(
                title: Text('${lvl.display} — ${nameFor(lvl)}'),
                value: lvl,
                activeColor: SoriColors.primary,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.btnCancel),
          ),
        ],
      ),
    );
  }

  Future<void> _onBackupTap() async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await CloudSync.backupWithResult();
      if (!mounted) return;
      if (result != CloudWriteResult.completed) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.accountOperationRetryBody)),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.settingsCloudBackupSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showOfflineDialog(retry: _onBackupTap);
    }
  }

  Future<void> _onRestoreTap() async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await CloudSync.restoreWithResult();
      if (!mounted) return;
      final message = switch (result) {
        CloudRestoreResult.completed => t.settingsCloudRestoreSuccess,
        CloudRestoreResult.empty => t.settingsCloudRestoreEmpty,
        CloudRestoreResult.blocked ||
        CloudRestoreResult.stale => t.accountOperationRetryBody,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _showOfflineDialog(retry: _onRestoreTap);
    }
  }

  Future<void> _onDeleteCloudData() async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result =
          await (widget.cloudDataDeletion ?? AuthService.deleteCloudData)();
      if (!mounted) return;
      if (result != CloudWriteResult.completed) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.settingsCloudDeleteDataFailed)),
        );
        return;
      }
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.settingsCloudDeleteDataSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(t.settingsCloudDeleteDataFailed)),
      );
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
    final messenger = ScaffoldMessenger.of(context);
    final rootNav = Navigator.of(context);
    try {
      await operation();
      if (!mounted) {
        return;
      }
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.settingsAccountDeleteSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
      rootNav.pushNamedAndRemoveUntil('/intro', (route) => false);
    } on AccountDeletionFailure catch (failure) {
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      await showSafeAccountFailure(
        context,
        deletion: true,
        retry: _onDeleteAccount,
      );
    }
  }

  Future<void> _openSubscriptionManagement() async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _subscriptionManager.open();
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(t.settingsManageSubscriptionFailed)),
      );
    }
  }

  void _showOfflineDialog({required Future<void> Function() retry}) {
    final t = AppL10n.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
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
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.lightImpact();
    // 홈으로 돌아가 즉시 안내 투어를 다시 띄운다(재시작 불필요).
    nav.popUntil((r) => r.isFirst);
    AppShell.replayHomeTour.value++;
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.settingsTutorialResetDone),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmReset() {
    final t = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                await (widget.resetAllData?.call() ?? Storage.resetAll());
                await WordImageService.deleteAll();
                await TtsService.clearCache();
                DataLoader.reset();
                if (!mounted || !ctx.mounted) return;
                dialogNav.pop();
                rootNav.popUntil((r) => r.isFirst);
                HapticFeedback.heavyImpact();
              } on CloudBackupDeletionResetBlockedException {
                if (!mounted) return;
                if (ctx.mounted) {
                  dialogNav.pop();
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.accountOperationRetryBody)),
                );
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                style: const TextStyle(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                borderRadius: BorderRadius.circular(1),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(url), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: onSurface.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SoriColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      license,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
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
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
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
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 14),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Attribution: $attribution',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
