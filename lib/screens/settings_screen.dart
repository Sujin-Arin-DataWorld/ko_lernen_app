import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/locale_service.dart';
import '../services/data_loader.dart';
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
          // ── Sprache ──
          _Section(label: t.settingsLanguage),
          _RadioTile<String>(
            title: t.settingsLanguageSystem,
            value: 'system',
            groupValue: currentLocale == null ? 'system' : currentLocale.languageCode,
            onChanged: (_) => setState(() => setLocale(null)),
          ),
          _RadioTile<String>(
            title: t.settingsLanguageDe,
            value: 'de',
            groupValue: currentLocale == null ? 'system' : currentLocale.languageCode,
            onChanged: (_) => setState(() => setLocale(const Locale('de'))),
          ),
          _RadioTile<String>(
            title: t.settingsLanguageEn,
            value: 'en',
            groupValue: currentLocale == null ? 'system' : currentLocale.languageCode,
            onChanged: (_) => setState(() => setLocale(const Locale('en'))),
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
                    Text(t.settingsTtsRateSlow,  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(t.settingsTtsRateNormal, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(t.settingsTtsRateFast,  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          // ── Reset ──
          _Section(label: ''),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(t.settingsReset, style: const TextStyle(color: AppColors.danger)),
            onTap: _confirmReset,
          ),

          // ── About ──
          _Section(label: t.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.settingsVersion(_appVersion())),
            subtitle: const Text('Made with ❤️ in Berlin'),
          ),
        ],
      ),
    );
  }

  String _appVersion() => '1.0.0';

  void _confirmReset() {
    final t = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t.settingsReset),
        content: Text(t.settingsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await Storage.resetAll();
              DataLoader.reset();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.popUntil(context, (r) => r.isFirst);
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
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  const _RadioTile({required this.title, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
