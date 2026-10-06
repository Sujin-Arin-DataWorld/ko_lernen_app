import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/c_gallery/c_objects.dart';
import 'settings_screen.dart';
import 'sori_stage/c_stage_chrome.dart';

/// Concept-C settings landing page matching the approved 01-einstellungen
/// mockup. Existing SettingsScreen keeps ownership of every real toggle,
/// account flow and legal action; this hub only routes to the exact section.
class CSettingsHubScreen extends StatelessWidget {
  const CSettingsHubScreen({super.key});

  void _detail(BuildContext context, SettingsInitialFocus focus) =>
      Navigator.of(context).pushNamed('/settings/detail', arguments: focus);

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final en = Localizations.localeOf(context).languageCode == 'en';
    final rows = <_SettingsHubRow>[
      _SettingsHubRow(
        id: 'profile',
        title: t.profileTitle,
        subtitle: en
            ? 'Goal · starting point · learning companion'
            : 'Ziel · Startpunkt · Lernbegleitung',
        art: const CObjectArt(CObject.cloud),
        onTap: () => Navigator.of(context).pushNamed('/profile'),
      ),
      _SettingsHubRow(
        id: 'language-learning',
        title: en ? 'Language & learning' : 'Sprache & Lernen',
        subtitle: en
            ? 'Language · learning path · interests'
            : 'Sprache · Lernweg · Interessen',
        art: const CObjectArt(CObject.book),
        onTap: () => _detail(context, SettingsInitialFocus.language),
      ),
      _SettingsHubRow(
        id: 'sound-motion',
        title: en ? 'Sound & motion' : 'Ton & Bewegung',
        subtitle: en
            ? 'Voice · volume · vibration'
            : 'Stimme · Lautstärke · Vibration',
        art: Image.asset(
          'assets/illustrations/activities/pronunciation.webp',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        onTap: () => _detail(context, SettingsInitialFocus.voiceSpeed),
      ),
      _SettingsHubRow(
        id: 'reminders',
        title: en ? 'Reminders' : 'Erinnerungen',
        subtitle: en ? 'Your daily learning time' : 'Deine tägliche Lernzeit',
        art: const CObjectArt(CObject.lantern),
        onTap: () => _detail(context, SettingsInitialFocus.notifications),
      ),
      _SettingsHubRow(
        id: 'account',
        title: en ? 'Account & security' : 'Konto & Sicherung',
        subtitle: en
            ? 'Sign in · backup · restore'
            : 'Anmelden · Sichern · Wiederherstellen',
        art: const CObjectArt(CObject.stampbook),
        onTap: () => _detail(context, SettingsInitialFocus.account),
      ),
      _SettingsHubRow(
        id: 'privacy',
        title: en ? 'Privacy & data' : 'Datenschutz & Daten',
        subtitle: en
            ? 'Consent · export · reset'
            : 'Einwilligungen · Export · Zurücksetzen',
        art: Image.asset(
          'assets/illustrations/activities/my_words.webp',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        onTap: () => _detail(context, SettingsInitialFocus.privacy),
      ),
      _SettingsHubRow(
        id: 'downloads',
        title: en ? 'Downloads' : 'Downloads',
        subtitle: en ? 'Hanok for offline use' : 'Hanok für unterwegs',
        art: Image.asset(
          'assets/illustrations/concept_c/hanok_preview.png',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => const CObjectArt(CObject.lantern),
        ),
        onTap: () => _detail(context, SettingsInitialFocus.downloads),
      ),
      _SettingsHubRow(
        id: 'help',
        title: en ? 'Help & app info' : 'Hilfe & App-Info',
        subtitle: en
            ? 'Guide · legal · updates'
            : 'Anleitung · Rechtliches · Updates',
        art: const CObjectArt(CObject.book),
        onTap: () => _detail(context, SettingsInitialFocus.guide),
      ),
    ];

    return Scaffold(
      backgroundColor: CPalette.jade,
      body: CStageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: CStageHeader(
                  title: t.settingsTitle,
                  artwork: const CObjectArt(CObject.cloud),
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('c-settings-hub-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    CPaperPanel(
                      radius: 18,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            rows[i],
                            if (i != rows.length - 1)
                              Divider(
                                height: 1,
                                color: CPalette.brass.withValues(alpha: .55),
                              ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: CPalette.brass.withValues(alpha: .7),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: CObjectArt(CObject.seal, size: 22),
                              ),
                              Expanded(
                                child: Divider(
                                  color: CPalette.brass.withValues(alpha: .7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            en
                                ? 'Everything at your rhythm.'
                                : 'Alles in deinem Rhythmus.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 14,
                              color: CPalette.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHubRow extends StatelessWidget {
  const _SettingsHubRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final Widget art;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CImageTap(
    key: ValueKey('c-settings-hub-$id'),
    label: title,
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 78),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox.square(dimension: 62, child: art),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Paperlogy',
                      fontFamilyFallback: ['NotoSansKR'],
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: CPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Paperlogy',
                      fontFamilyFallback: ['NotoSansKR'],
                      fontSize: 13,
                      color: CPalette.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CArrow(dark: true, size: 16),
          ],
        ),
      ),
    ),
  );
}
