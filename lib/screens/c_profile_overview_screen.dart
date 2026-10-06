import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/c_gallery/c_objects.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/mascot_preference.dart';
import 'settings_screen.dart';
import 'sori_stage/c_stage_chrome.dart';

/// Concept-C profile landing page matching the approved guest/connected
/// profile mockups. Existing ProfileScreen remains the owner of account/export
/// mutations and is reachable at /profile/detail.
class CProfileOverviewScreen extends StatelessWidget {
  const CProfileOverviewScreen({
    super.key,
    this.account,
    this.previewMascot,
    this.previewLevel,
    this.previewGoal,
  });

  final AuthAccountSnapshot? account;
  final MascotKind? previewMascot;
  final String? previewLevel;
  final String? previewGoal;

  void _detail(BuildContext context) =>
      Navigator.of(context).pushNamed('/profile/detail');

  void _settings(BuildContext context, SettingsInitialFocus focus) =>
      Navigator.of(context).pushNamed('/settings/detail', arguments: focus);

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final en = Localizations.localeOf(context).languageCode == 'en';
    final resolvedAccount = account ?? AuthService.accountSnapshot;
    final linked = resolvedAccount.providers.isDurable;
    final mascot = previewMascot ?? MascotPreference.chosenKind;
    final name = linked
        ? (resolvedAccount.displayName ??
              (en ? 'Connected profile' : 'Verbundenes Profil'))
        : t.profileGuestName;
    final level = (previewLevel ?? Storage.userLevelCode ?? 'a1').toUpperCase();
    final rawGoal = previewGoal ?? Storage.motivation;
    final goal = rawGoal.trim().isEmpty
        ? (en ? 'Not set yet' : 'Noch nicht festgelegt')
        : rawGoal;

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
                  title: t.profileTitle,
                  artwork: const CObjectArt(CObject.settings),
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('c-profile-overview-scroll'),
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    CPaperPanel(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, bounds) {
                              final stack =
                                  bounds.maxWidth < 330 ||
                                  MediaQuery.textScalerOf(context).scale(16) >
                                      21;
                              final copy = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    en ? 'Your learning' : 'Dein Lernen',
                                    style: cStageCardTitle,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    linked
                                        ? (en
                                              ? 'Saved with your account'
                                              : 'Mit deinem Konto gesichert')
                                        : (en
                                              ? 'Saved on this device'
                                              : 'Auf diesem Gerät gespeichert'),
                                    style: cStageBody.copyWith(
                                      color: CPalette.mutedInk,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x55efe0c8),
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: CPalette.fineEdge,
                                      ),
                                    ),
                                    child: Text(
                                      mascot == MascotKind.magpie
                                          ? (en
                                                ? 'You learn with Joy. Together you discover Korean.'
                                                : 'Du lernst mit Joy. Gemeinsam entdeckst du Koreanisch.')
                                          : (en
                                                ? 'You learn with Taego. Together you discover Korean.'
                                                : 'Du lernst mit Taego. Gemeinsam entdeckst du Koreanisch.'),
                                      style: cStageBody.copyWith(
                                        color: CPalette.mutedInk,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                              final portrait = SizedBox.square(
                                dimension: 146,
                                child: Mascot(kind: mascot, size: 146),
                              );
                              if (stack) {
                                return Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: portrait,
                                    ),
                                    const SizedBox(height: 10),
                                    copy,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  portrait,
                                  const SizedBox(width: 14),
                                  Expanded(child: copy),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Divider(color: CPalette.brass.withValues(alpha: .65)),
                          _sectionTitle(en ? 'My learning' : 'Mein Lernen'),
                          _row(
                            id: 'goal',
                            art: const CObjectArt(CObject.book),
                            title: en ? 'My goal' : 'Mein Ziel',
                            value: goal,
                            onTap: () => _detail(context),
                          ),
                          _divider(),
                          _row(
                            id: 'start',
                            art: Image.asset(
                              'assets/illustrations/activities/hangul.webp',
                              fit: BoxFit.contain,
                            ),
                            title: en ? 'My starting point' : 'Mein Startpunkt',
                            value: level,
                            onTap: () => _settings(
                              context,
                              SettingsInitialFocus.courseStart,
                            ),
                          ),
                          _divider(),
                          _row(
                            id: 'companion',
                            art: const CObjectArt(CObject.lantern),
                            title: en ? 'Learning companion' : 'Lernbegleitung',
                            value: mascot == MascotKind.magpie
                                ? 'Joy'
                                : 'Taego',
                            onTap: () => _settings(
                              context,
                              SettingsInitialFocus.companion,
                            ),
                          ),
                          _sectionTitle(en ? 'My space' : 'Mein Raum'),
                          _row(
                            id: 'gye',
                            art: Image.asset(
                              'assets/illustrations/activities/smalltalk.webp',
                              fit: BoxFit.contain,
                            ),
                            title: en
                                ? 'My learning group'
                                : 'Meine Lerngruppe',
                            value: en ? 'Open your Gye' : 'Deine Gye öffnen',
                            onTap: () =>
                                Navigator.of(context).pushNamed('/gye/hub'),
                          ),
                          _divider(),
                          _row(
                            id: 'data',
                            art: const CObjectArt(CObject.stampbook),
                            title: en ? 'My learning data' : 'Meine Lerndaten',
                            value: en
                                ? 'Export and account tools'
                                : 'Export & Kontowerkzeuge',
                            onTap: () => _detail(context),
                          ),
                          const SizedBox(height: 12),
                          _sectionTitle(
                            en ? 'Secure progress' : 'Fortschritt sichern',
                          ),
                          Text(
                            linked
                                ? name
                                : (en
                                      ? 'An account is optional. You can keep learning.'
                                      : 'Ein Konto ist optional. Du kannst weiterlernen.'),
                            style: cStageBody.copyWith(
                              color: CPalette.mutedInk,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CMaterialAction(
                            label: linked
                                ? (en
                                      ? 'Account & backup'
                                      : 'Konto & Sicherung')
                                : (en
                                      ? 'Save with Google / Apple'
                                      : 'Mit Google / Apple sichern'),
                            onTap: () => _detail(context),
                          ),
                          const SizedBox(height: 10),
                          _row(
                            id: 'privacy',
                            art: Image.asset(
                              'assets/illustrations/activities/my_words.webp',
                              fit: BoxFit.contain,
                            ),
                            title: en
                                ? 'Privacy & account'
                                : 'Datenschutz & Konto',
                            value: en
                                ? 'Consent · data · account options'
                                : 'Einwilligungen · Datenverwaltung · Kontooptionen',
                            onTap: () => _settings(
                              context,
                              SettingsInitialFocus.privacy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CMaterialAction(
                            label: en ? 'View statistics' : 'Statistik ansehen',
                            gold: false,
                            onTap: () =>
                                Navigator.of(context).pushNamed('/stats'),
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

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
    child: Text(text, style: cStageCardTitle.copyWith(fontSize: 20)),
  );

  Widget _divider() =>
      Divider(height: 1, color: CPalette.brass.withValues(alpha: .55));

  Widget _row({
    required String id,
    required Widget art,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) => CImageTap(
    key: ValueKey('c-profile-$id'),
    label: title,
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 78),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox.square(dimension: 60, child: art),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: cStageBody.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: cStageBody.copyWith(
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
