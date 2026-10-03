import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_controller.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import '../support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  test(
    'finish persists current input once and old identity cannot save',
    () async {
      var raw = '';
      final sessions = CloudWriteSessionController()..acquire('a');
      final store = DancheongStore(
        readRaw: () => raw,
        writeRaw: (value, guard) async {
          guard();
          raw = value;
        },
        sessions: sessions,
        readOwned: () => {'lotus'},
      );
      final controller = DancheongController(
        store: store,
        owned: () => {'lotus'},
        motifSlug: 'lotus',
      );
      controller.update(
        controller.composition.copyWith(koreanText: '안녕, Jürgen'),
      );
      final art = await controller.finish();
      expect(art.composition.koreanText, '안녕, Jürgen');
      expect(store.currentOwner().drafts, isEmpty);
      sessions.acquire('b');
      expect(controller.isCurrent, isFalse);
      await expectLater(
        controller.flush(),
        throwsA(isA<DancheongStoreFailure>()),
      );
      expect(store.currentOwner().artworks, isEmpty);
      controller.dispose();
    },
  );
  test('no guessed material and a failed save keeps unsaved input', () async {
    final sessions = CloudWriteSessionController()..acquire('a');
    final store = DancheongStore(
      readRaw: () => '',
      writeRaw: (value, guard) async {
        throw StateError('rejected');
      },
      sessions: sessions,
    );
    final controller = DancheongController(
      store: store,
      owned: () => {},
      motifSlug: 'unknown',
    );
    expect(controller.composition.motifSlugs, isEmpty);
    controller.update(controller.composition.copyWith(signature: 'Jürgen'));
    await expectLater(controller.flush(), throwsStateError);
    expect(controller.composition.signature, 'Jürgen');
    expect(controller.saved, isFalse);
    expect(controller.error, isNotNull);
    controller.dispose();
  });
}
