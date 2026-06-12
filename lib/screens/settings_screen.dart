import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/external_link.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/privacy_consent_service.dart';
import '../services/word_image_service.dart';
import '../widgets/sori/sheet.dart';
import '../services/personalized_lesson_service.dart';
import '../services/premium_service.dart';
import '../services/tts_service.dart';
import '../services/locale_service.dart';
import '../services/data_loader.dart';
import '../services/auth_service.dart';
import '../services/book_analysis_service.dart';
import '../services/cloud_sync.dart';
import '../models/scenario.dart';
import '../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _ttsRate;
  late final TextEditingController _endpointCtrl;

  @override
  void initState() {
    super.initState();
    _ttsRate = Storage.ttsRate;
    _endpointCtrl = TextEditingController(text: Storage.bookAnalysisEndpoint);
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEndpoint() async {
    final url = _endpointCtrl.text.trim();
    await Storage.setBookAnalysisEndpoint(url);
    BookAnalysisService.setEndpoint(url);
    if (!mounted) return;
    final t = AppL10n.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.settingsBookEndpointSaved),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
      } else {
        await Storage.setNotificationsEnabled(false);
        messenger.showSnackBar(SnackBar(content: Text(t.settingsNotifDenied)));
      }
    } else {
      await NotificationService.cancelAll();
    }
    if (mounted) setState(() {});
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
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
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
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  await Storage.setInterests(selected.toList());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                },
                child: Text(t.btnApply),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final currentLocale = localeNotifier.value;

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
                style: const TextStyle(
                  fontSize: 12,
                  color: SoriColors.darkTextMuted,
                ),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: SoriColors.darkTextMuted,
                        ),
                      ),
                      Text(
                        t.settingsTtsRateNormal,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SoriColors.darkTextMuted,
                        ),
                      ),
                      Text(
                        t.settingsTtsRateFast,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SoriColors.darkTextMuted,
                        ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: SoriColors.darkTextMuted,
                ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: SoriColors.darkTextMuted,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: SoriColors.darkTextMuted,
              ),
              onTap: _showInterestPicker,
            ),

            // ── Cloud-Backup (Firebase Auth) ──
            _Section(label: t.settingsCloudSection),
            ListTile(
              leading: const Icon(
                Icons.cloud_outlined,
                color: SoriColors.primary,
              ),
              title: Text(
                (AuthService.isGoogleLinked || AuthService.isAppleLinked)
                    ? t.settingsCloudSignedIn(
                        AuthService.displayName ?? 'Google',
                      )
                    : t.settingsCloudSignInPrompt,
              ),
              subtitle: Text(
                (AuthService.isGoogleLinked || AuthService.isAppleLinked)
                    ? t.settingsCloudSignedInDesc
                    : t.settingsCloudSignInDesc,
              ),
              onTap: (AuthService.isGoogleLinked || AuthService.isAppleLinked)
                  ? null
                  : _onGoogleTap,
            ),
            if (!AuthService.isGoogleLinked &&
                !AuthService.isAppleLinked &&
                AuthService.appleSignInAvailable)
              ListTile(
                leading: const Icon(Icons.apple),
                title: Text(t.authAppleSignIn),
                subtitle: Text(t.settingsCloudSignInDesc),
                onTap: _onAppleTap,
              ),
            if (AuthService.isGoogleLinked || AuthService.isAppleLinked) ...[
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(t.settingsCloudBackupNow),
                onTap: _onBackupTap,
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: Text(t.settingsCloudRestore),
                onTap: _onRestoreTap,
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(t.profileSignOut),
                onTap: _onSignOutTap,
              ),
              ListTile(
                leading: const Icon(
                  Icons.cloud_off_outlined,
                  color: SoriColors.danger,
                ),
                title: Text(
                  t.settingsCloudDeleteData,
                  style: const TextStyle(color: SoriColors.danger),
                ),
                subtitle: Text(t.settingsCloudDeleteDataDesc),
                onTap: _confirmCloudDelete,
              ),
            ],

            // ── Werbung ──
            _Section(label: t.settingsAdsSection),
            SwitchListTile(
              title: Text(t.settingsShowAds),
              subtitle: Text(
                t.settingsShowAdsDesc,
                style: const TextStyle(
                  fontSize: 12,
                  color: SoriColors.darkTextMuted,
                ),
              ),
              value: Storage.adsEnabled,
              onChanged: (v) async {
                await Storage.setAdsEnabled(v);
                if (mounted) setState(() {});
              },
              activeThumbColor: SoriColors.primary,
            ),

            // ── Phase 5 — Cloud Analysis Endpoint ──
            _Section(label: t.settingsBookEndpointSection),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.settingsBookEndpointHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: SoriSurfaces.of(context).textMuted,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: _endpointCtrl,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveEndpoint(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'https://us-central1-…/analyze_korean_text',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(t.settingsBookEndpointSave),
                      onPressed: _saveEndpoint,
                    ),
                  ),
                ],
              ),
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
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: SoriColors.danger,
              ),
              title: Text(
                t.settingsReset,
                style: const TextStyle(color: SoriColors.danger),
              ),
              onTap: _confirmReset,
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: SoriColors.danger,
              ),
              title: Text(
                t.settingsAccountDelete,
                style: const TextStyle(color: SoriColors.danger),
              ),
              subtitle: Text(t.settingsAccountDeleteDesc),
              onTap: _confirmAccountDelete,
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
            Text(
              t.settingsDataSourcesTitle,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
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

  String _appVersion() => '1.0.1';

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
        backgroundColor: SoriColors.darkSurface,
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
      await CloudSync.backup();
      if (!mounted) return;
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
      final ok = await CloudSync.restore();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? t.settingsCloudRestoreSuccess : t.settingsCloudRestoreEmpty,
          ),
        ),
      );
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
      await AuthService.deleteCloudData();
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.settingsCloudDeleteDataSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(t.settingsAccountDeleteFailed(e.toString()))),
      );
    }
  }

  Future<void> _onDeleteAccount() async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final rootNav = Navigator.of(context);
    try {
      await AuthService.deleteAccount();
      await Storage.resetAll();
      // DSGVO Art. 17 — lokale Dateien außerhalb der SharedPreferences:
      // Wortfotos (wordbook_images/) + TTS-Audio-Cache.
      await WordImageService.deleteAll();
      await TtsService.clearCache();
      DataLoader.reset();
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.settingsAccountDeleteSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
      rootNav.pushNamedAndRemoveUntil('/intro', (route) => false);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(t.settingsAccountDeleteFailed(e.toString()))),
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
    try {
      if (AuthService.isGoogleLinked) {
        await AuthService.signOut();
      } else {
        final user = await AuthService.linkWithGoogle();
        if (user != null) {
          await CloudSync.backup();
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppL10n.of(context).settingsCloudAuthFailed(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _onAppleTap() async {
    try {
      final user = await AuthService.linkWithApple();
      if (user != null) {
        await CloudSync.backup();
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppL10n.of(context).settingsCloudAuthFailed(e.toString()),
          ),
        ),
      );
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.settingsTutorialResetDone),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _confirmReset() {
    final t = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoriColors.darkSurface,
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
              await Storage.resetAll();
              await WordImageService.deleteAll();
              await TtsService.clearCache();
              DataLoader.reset();
              if (!mounted) return;
              dialogNav.pop();
              rootNav.popUntil((r) => r.isFirst);
              HapticFeedback.heavyImpact();
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
      confirmLabel: t.btnDelete,
      onConfirm: _onDeleteAccount,
    );
  }

  void _showDangerConfirm({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
  }) {
    final t = AppL10n.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoriColors.darkSurface,
        title: Text(title),
        content: Text(body),
        actions: [
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: SoriColors.darkTextMuted,
        ),
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
