import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_controller.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  test(
    'editing revision 1 uses its text and preserves a different unfinished draft',
    () async {
      const id = '00000000-0000-4000-8000-000000000001';
      DancheongComposition composition(String text) => DancheongComposition(
        template: DancheongTemplate.flower,
        format: DancheongFormat.portrait,
        motifSlugs: ['lotus'],
        koreanText: text,
      );
      var raw = DancheongLocalDocument(
        owners: {
          'owner': DancheongOwnerDocument(
            artworks: [
              for (var r = 1; r <= 2; r++)
                DancheongArtwork(
                  id: id,
                  revision: r,
                  composition: composition('Revision $r'),
                  completedAt: DateTime.utc(2026),
                ),
            ],
            drafts: [
              DancheongDraft(
                id: id,
                composition: composition('Unfinished draft'),
                updatedAt: DateTime.utc(2026),
              ),
            ],
          ),
        },
      ).encode();
      final store = DancheongStore(
        readRaw: () => raw,
        writeRaw: (v, g) async {
          g();
          raw = v;
        },
        sessions: CloudWriteSessionController()..acquire('owner'),
        readOwned: () => {'lotus'},
      );
      final editor = DancheongController(
        store: store,
        owned: () => {'lotus'},
        draftId: id,
        sourceRevision: 1,
      );
      expect(editor.composition.koreanText, 'Revision 1');
      expect(editor.id, isNot(id));
      editor.update(editor.composition.copyWith(signature: 'Jürgen'));
      await editor.flush();
      expect(
        store.currentOwner().drafts.first.composition.koreanText,
        'Unfinished draft',
      );
      expect(
        store.currentOwner().drafts.last.composition.koreanText,
        'Revision 1',
      );
      expect(
        store.currentOwner().artworks[1].composition.koreanText,
        'Revision 2',
      );
      editor.dispose();
    },
  );
}
