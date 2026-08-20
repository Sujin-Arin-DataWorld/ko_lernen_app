import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/culture_notes_service.dart';
import 'card.dart';
import 'tokens.dart';

/// 단어에 붙는 "K-Culture" 연결 카드 (서양 학습자 어필).
///
/// 해당 단어에 [CultureNotesService] 노트가 있으면 표시, 없으면 [SizedBox.shrink].
/// 어느 단어-표시 화면(플래시카드·복습 등)에나 drop-in 가능. 노트 텍스트는
/// 검증 가능한 문화 사실만(§0 — 특정 곡 인용은 Jin 검수분만).
class CultureNoteCard extends StatelessWidget {
  final String korean;

  const CultureNoteCard({super.key, required this.korean});

  @override
  Widget build(BuildContext context) {
    final note = CultureNotesService.noteFor(korean);
    if (note == null) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final (icon, accent) = _kindStyle(note.kind);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        tinted: true,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  t.cultureNoteTitle,
                  style: tt.label.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(note.ko, style: tt.cultureTitle.copyWith(color: s.text)),
            const SizedBox(height: Spacing.xs),
            Text(note.text(lang), style: tt.bodySmall.copyWith(color: s.text)),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _kindStyle(String kind) => switch (kind) {
    'kpop' => (Icons.music_note_rounded, SoriColors.accent),
    'drama' => (Icons.movie_outlined, SoriColors.highlight),
    'film' => (Icons.theaters_outlined, SoriColors.primary),
    _ => (Icons.auto_stories_outlined, SoriColors.gold),
  };
}
