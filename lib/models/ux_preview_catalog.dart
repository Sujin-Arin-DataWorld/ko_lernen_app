/// Stable inventory for the debug-only UX rebuild gallery.
///
/// The ids intentionally mirror the 20 panels in
/// `docs/HANGUL_SORI_UX_REBUILD_MOCKUPS.html`. Keeping the inventory separate
/// from the widget builders lets tests prove that no mockup silently drops out
/// when production preview seams change.
enum UxPreviewSection { onboarding, daily, hanok, explore, gye, account }

class UxPreviewPanel {
  const UxPreviewPanel({
    required this.id,
    required this.section,
    required this.title,
  });

  final String id;
  final UxPreviewSection section;
  final String title;
}

const uxPreviewPanels = <UxPreviewPanel>[
  UxPreviewPanel(
    id: '01A',
    section: UxPreviewSection.onboarding,
    title: 'Pflicht-Einwilligung',
  ),
  UxPreviewPanel(
    id: '01B',
    section: UxPreviewSection.onboarding,
    title: 'Ziel und Startpunkt',
  ),
  UxPreviewPanel(
    id: '01C',
    section: UxPreviewSection.onboarding,
    title: 'Erste Stimme',
  ),
  UxPreviewPanel(
    id: '01D',
    section: UxPreviewSection.onboarding,
    title: 'Lernbegleitung',
  ),
  UxPreviewPanel(id: '02A', section: UxPreviewSection.daily, title: 'Heute'),
  UxPreviewPanel(
    id: '02B',
    section: UxPreviewSection.daily,
    title: 'Missionsbriefing',
  ),
  UxPreviewPanel(
    id: '02C',
    section: UxPreviewSection.daily,
    title: 'Erste Aufgabe',
  ),
  UxPreviewPanel(
    id: '02D',
    section: UxPreviewSection.daily,
    title: 'Can-do-Ergebnis',
  ),
  UxPreviewPanel(
    id: '03A',
    section: UxPreviewSection.hanok,
    title: 'Früher Hanokbau',
  ),
  UxPreviewPanel(
    id: '03B',
    section: UxPreviewSection.hanok,
    title: 'Hanok-Karte',
  ),
  UxPreviewPanel(
    id: '03C',
    section: UxPreviewSection.hanok,
    title: 'Sarangbang',
  ),
  UxPreviewPanel(id: '04A', section: UxPreviewSection.explore, title: 'Üben'),
  UxPreviewPanel(
    id: '04B',
    section: UxPreviewSection.explore,
    title: 'Entdecken',
  ),
  UxPreviewPanel(
    id: '04C',
    section: UxPreviewSection.explore,
    title: 'Dein Weg',
  ),
  UxPreviewPanel(
    id: '05A',
    section: UxPreviewSection.gye,
    title: 'Gye-Einstieg',
  ),
  UxPreviewPanel(
    id: '05B',
    section: UxPreviewSection.gye,
    title: 'Wochenversprechen',
  ),
  UxPreviewPanel(id: '05C', section: UxPreviewSection.gye, title: 'Gye-Hof'),
  UxPreviewPanel(id: '06A', section: UxPreviewSection.account, title: 'Profil'),
  UxPreviewPanel(
    id: '06B',
    section: UxPreviewSection.account,
    title: 'Offline',
  ),
  UxPreviewPanel(
    id: '06C',
    section: UxPreviewSection.account,
    title: 'Wiederholung zuerst',
  ),
];
