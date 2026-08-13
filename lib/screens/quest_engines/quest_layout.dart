import 'package:flutter/widgets.dart';

import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/tts_speed_control.dart';

/// Gemeinsames Layout aller Quest-Engines.
///
/// Die Engine übergibt ihren Inhalt und ihre primäre Aktion **getrennt**.
/// Erst dadurch kann die Aktion unten am Rand stehen bleiben, statt mit dem
/// Inhalt wegzuscrollen (Jin 2026-08-13, Rollenspiel auf dem Gerät).
///
/// Welche Form gewählt wird, hängt an der Höhe, die der Aufrufer gibt:
///
/// * **begrenzte Höhe** (Szenario-Player, Satz-Arcade): der Inhalt scrollt in
///   dem Platz, der übrig bleibt, und die Aktion bleibt unten stehen. Sie ist
///   damit ohne Scrollen erreichbar.
/// * **unbegrenzte Höhe** (ein Aufrufer, der selbst schon scrollt): Inhalt und
///   Aktion werden wie bisher untereinander gestapelt. Ohne diesen Zweig würde
///   `Expanded` unter unendlicher Höhe eine Assertion auslösen — genau der Fall,
///   den `test/satz_bauen_unbounded_height_test.dart` festhält.
class QuestLayout extends StatelessWidget {
  /// Der scrollbare Teil: Aufgabe, Optionen, Maskottchen.
  final Widget content;

  /// Die primäre Aktion, z. B. `Überprüfen` oder die Auflösungskarte mit
  /// `Weiter`. `null` bei Engines, die sofort beim Antippen auswerten
  /// (Lücken, Übersetzen) — dann bleibt das Layout ein reiner Scroll-Bereich.
  final Widget? action;

  /// Abstand zwischen Inhalt und Aktion.
  final double gap;

  /// Anteil der Höhe, den die angeheftete Aktion höchstens einnimmt.
  ///
  /// Auflösungskarten tragen einen Erklärtext und können lang werden. Ohne
  /// Deckel würde der Inhalt darüber auf null Höhe gedrückt. Über dem Deckel
  /// scrollt die Karte in sich selbst, damit nie etwas überläuft.
  static const double _actionMaxFraction = 0.6;

  /// Kopfraum im Scroll-Bereich.
  ///
  /// Die Engines setzen ihr Maskottchen mit `Positioned(top: -12)` über die
  /// Kante. In einem eigenen Scroll-Bereich würde genau das abgeschnitten.
  static const double _overhang = 14;

  /// Audio-Engines (Diktat, Hörverstehen, Batchim, Partikel) zeigen oben
  /// rechts den globalen Sprechtempo-Chip (2026-08-13 — Tempo überall, wo
  /// Sprache abgespielt wird). Engines ohne Audio lassen ihn weg.
  final bool showTtsSpeed;

  const QuestLayout({
    super.key,
    required this.content,
    this.action,
    this.gap = Spacing.md,
    this.showTtsSpeed = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pinnedAction = action;
        final speedBar = showTtsSpeed
            ? const Align(
                alignment: Alignment.centerRight,
                child: TtsSpeedControl(),
              )
            : null;

        if (!constraints.maxHeight.isFinite) {
          if (pinnedAction == null && speedBar == null) {
            return content;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (speedBar != null) ...[speedBar, SizedBox(height: gap)],
              content,
              if (pinnedAction != null) ...[
                SizedBox(height: gap),
                pinnedAction,
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (speedBar != null) speedBar,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: _overhang),
                child: content,
              ),
            ),
            if (pinnedAction != null) ...[
              SizedBox(height: gap),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * _actionMaxFraction,
                ),
                child: SingleChildScrollView(child: pinnedAction),
              ),
            ],
          ],
        );
      },
    );
  }
}
