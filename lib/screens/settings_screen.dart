import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        title: Text(t.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Erscheinungsbild ──
          _Section(label: t.settingsThemeTitle),
          RadioGroup<ThemeMode>(
            groupValue: themeModeNotifier.value,
            onChanged: (m) => setState(() => setThemeMode(m ?? ThemeMode.system)),
            child: Column(
              children: [
                _RadioTile<ThemeMode>(title: t.settingsThemeSystem, value: ThemeMode.system),
                _RadioTile<ThemeMode>(title: t.settingsThemeLight, value: ThemeMode.light),
                _RadioTile<ThemeMode>(title: t.settingsThemeDark, value: ThemeMode.dark),
              ],
            ),
          ),

          // ── Sprache ──
          _Section(label: t.settingsLanguage),
          RadioGroup<String>(
            groupValue: currentLocale == null ? 'system' : currentLocale.languageCode,
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
                _RadioTile<String>(title: t.settingsLanguageSystem, value: 'system'),
                _RadioTile<String>(title: t.settingsLanguageDe, value: 'de'),
                _RadioTile<String>(title: t.settingsLanguageEn, value: 'en'),
              ],
            ),
          ),

          // ── Lernlevel ──
          _Section(label: t.settingsUserLevel),
          ListTile(
            leading: const Icon(Icons.school_outlined, color: SoriColors.primary),
            title: Text(_levelDisplay(t)),
            subtitle: Text(t.settingsUserLevelChange, style: const TextStyle(fontSize: 12, color: SoriColors.darkTextMuted)),
            trailing: const Icon(Icons.chevron_right, color: SoriColors.darkTextMuted),
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
                  min: 0.1, max: 1.0,
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
                    Text(t.settingsTtsRateSlow,  style: const TextStyle(fontSize: 11, color: SoriColors.darkTextMuted)),
                    Text(t.settingsTtsRateNormal, style: const TextStyle(fontSize: 11, color: SoriColors.darkTextMuted)),
                    Text(t.settingsTtsRateFast,  style: const TextStyle(fontSize: 11, color: SoriColors.darkTextMuted)),
                  ],
                ),
              ],
            ),
          ),

          // ── Cloud-Backup (Firebase Auth) ──
          _Section(label: t.settingsCloudSection),
          ListTile(
            leading: const Icon(Icons.cloud_outlined, color: SoriColors.primary),
            title: Text(AuthService.isGoogleLinked
                ? t.settingsCloudSignedIn(AuthService.displayName ?? 'Google')
                : t.settingsCloudSignInPrompt),
            subtitle: Text(AuthService.isGoogleLinked
                ? t.settingsCloudSignedInDesc
                : t.settingsCloudSignInDesc),
            onTap: _onGoogleTap,
          ),
          if (AuthService.isGoogleLinked) ...[
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title:   Text(t.settingsCloudBackupNow),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await CloudSync.backup();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(t.settingsCloudBackupSuccess), duration: const Duration(seconds: 2)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title:   Text(t.settingsCloudRestore),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await CloudSync.restore();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(ok ? t.settingsCloudRestoreSuccess : t.settingsCloudRestoreEmpty)),
                );
                setState(() {});
              },
            ),
          ],

          // ── Werbung ──
          _Section(label: t.settingsAdsSection),
          SwitchListTile(
            title: Text(t.settingsShowAds),
            subtitle: Text(t.settingsShowAdsDesc, style: const TextStyle(fontSize: 12, color: SoriColors.darkTextMuted)),
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
            title: Text(t.settingsReset, style: const TextStyle(color: SoriColors.danger)),
            onTap: _confirmReset,
          ),

          // ── About ──
          _Section(label: t.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.settingsVersion(_appVersion())),
            subtitle: const Text('Made with ❤️ in Germany'),
          ),
        ],
      ),
    );
  }

  String _appVersion() => '1.0.1';

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
    final current = LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
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
        SnackBar(content: Text(AppL10n.of(context).settingsCloudAuthFailed(e.toString()))),
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
