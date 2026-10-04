import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/cultural_help.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'reward_chest_screen.dart';

void main() => runApp(const RewardChestPreviewApp());

class RewardChestPreviewApp extends StatefulWidget {
  const RewardChestPreviewApp({super.key});

  @override
  State<RewardChestPreviewApp> createState() => _RewardChestPreviewAppState();
}

class _RewardChestPreviewAppState extends State<RewardChestPreviewApp> {
  late Locale _locale = Locale(
    Uri.base.queryParameters['lang'] == 'en' ? 'en' : 'de',
  );
  var _run = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppL10n.of(context).rewardChestPreviewTitle,
    theme: AppTheme.light,
    themeMode: ThemeMode.light,
    locale: _locale,
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: Builder(
      builder: (context) {
        final t = AppL10n.of(context);
        return CulturalGlossaryBuilder(
          builder: (context, glossary) {
            const slug = 'decoration_jagae_mungap';
            final entry = glossary?.entry('jagae_mungap');
            return Stack(
              children: [
                RewardChestScreen(
                  key: ValueKey(_run),
                  itemAsset: 'assets/illustrations/decorations/$slug.png',
                  itemName: decorName(t, slug),
                  subtitle: decorTerm(t, slug),
                  itemDescription: entry?.localized(t.localeName).meaning,
                  totalXp: 1280,
                  xpLevel: 13,
                  xpToNext: 20,
                  continueLabel: t.rewardChestPlaceSarangbang,
                  onLearnMore: entry == null
                      ? null
                      : () => showCulturalTermSheet(context, entry),
                  enableAudio: false,
                  showBlueMagic: Uri.base.queryParameters['blue'] != '0',
                  previewSecond: double.tryParse(
                    Uri.base.queryParameters['at'] ?? '',
                  ),
                  onContinue: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.rewardChestPreviewPlacement)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: SafeArea(
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final code in ['de', 'en'])
                            TextButton(
                              onPressed: () =>
                                  setState(() => _locale = Locale(code)),
                              style: TextButton.styleFrom(
                                foregroundColor: _locale.languageCode == code
                                    ? SoriColors.primary
                                    : SoriSurfaces.of(context).textMuted,
                              ),
                              child: Text(code.toUpperCase()),
                            ),
                          IconButton(
                            tooltip: t.rewardChestReplay,
                            onPressed: () => setState(() => _run += 1),
                            icon: const Icon(Icons.replay_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
