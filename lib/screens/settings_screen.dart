import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/tokens.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/locale_service.dart';
import '../services/data_loader.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync.dart';
import '../services/theme_service.dart';
import '../models/scenario.dart';
import '../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _ttsRate;

  @override
  void initState() {
    super.initState();
    _ttsRate = Storage.ttsRate;
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
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

          // ── Erscheinungsbild ──
          _Section(label: t.settingsThemeTitle),
          RadioGroup<ThemeMode>(
            groupValue: themeModeNotifier.value,
            onChanged: (m) => setState(() {
              setThemeMode(m ?? ThemeMode.system);
            }),
            child: Column(
              children: [
                _RadioTile<ThemeMode>(
                  title: t.settingsThemeSystem,
                  value: ThemeMode.system,
                ),
                _RadioTile<ThemeMode>(
                  title: t.settingsThemeLight,
                  value: ThemeMode.light,
                ),
                _RadioTile<ThemeMode>(
                  title: t.settingsThemeDark,
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),

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

          // ── Cloud-Backup (Firebase Auth) ──
          _Section(label: t.settingsCloudSection),
          ListTile(
            leading: const Icon(
              Icons.cloud_outlined,
              color: SoriColors.primary,
            ),
            title: Text(
              AuthService.isGoogleLinked
                  ? t.settingsCloudSignedIn(AuthService.displayName ?? 'Google')
                  : t.settingsCloudSignInPrompt,
            ),
            subtitle: Text(
              AuthService.isGoogleLinked
                  ? t.settingsCloudSignedInDesc
                  : t.settingsCloudSignInDesc,
            ),
            onTap: _onGoogleTap,
          ),
          if (AuthService.isGoogleLinked) ...[
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

          // ── Reset ──
          _Section(label: ''),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: SoriColors.danger),
            title: Text(
              t.settingsReset,
              style: const TextStyle(color: SoriColors.danger),
            ),
            onTap: _confirmReset,
          ),

          // ── About ──
          _Section(label: t.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.settingsVersion(_appVersion())),
            subtitle: const Text('Made with ❤️ in Germany'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(t.settingsPrivacyTitle),
            subtitle: Text(t.settingsPrivacySubtitle),
            trailing: const Icon(Icons.copy_rounded, size: 18),
            onTap: _copyPrivacyUrl,
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
    );
  }

  /// CC BY-SA 2.0 KR 라이선스 준수 — NIKL 우리말샘 등 데이터 출처 표시.
  void _showDataSources() {
    final t = AppL10n.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                  color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.4),
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
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
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
              license: 'Translation output: factual data, attribution voluntary',
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
                      const Icon(Icons.info_outline,
                          size: 18, color: SoriColors.warning),
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
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.85),
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

  String _appVersion() => '1.0.1';

  Future<void> _copyPrivacyUrl() async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: _privacyUrl));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.settingsPrivacyCopied(_privacyUrl)),
        duration: const Duration(seconds: 3),
      ),
    );
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
                        horizontal: 8, vertical: 3),
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
