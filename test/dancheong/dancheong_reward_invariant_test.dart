import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_renderer.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import '../support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  test(
    'creating, finishing and exporting writes only artwork data, preserving every learning preference',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_earned_stamps': ['lotus'],
        'kl_xp': 137,
        'kl_pending_boxes': ['box1'],
        'kl_yeopjeon_wallet_v1': '{"balance":150}',
        'kl_course_progress_v2': '{"sentinel":true}',
      });
      await Storage.init();
      final preferences = await SharedPreferences.getInstance();
      Map<String, Object?> snapshot() => {
        for (final key in preferences.getKeys())
          if (key != Storage.dancheongStudioPreferenceKey)
            key: preferences.get(key),
      };
      final before = snapshot();
      final store = DancheongStore(
        sessions: CloudWriteSessionController()..acquire('invariant-owner'),
        readOwned: () => {'lotus'},
      );
      final draft = DancheongDraft(
        id: '00000000-0000-4000-8000-000000000003',
        composition: DancheongComposition(
          template: DancheongTemplate.flower,
          format: DancheongFormat.portrait,
          motifSlugs: ['lotus'],
          koreanText: '안녕',
        ),
        updatedAt: DateTime.utc(2026),
      );
      await store.saveDraft(draft);
      final art = await store.finishDraft(draft.id);
      final export = await DancheongRenderer().render(
        art,
        ownedSlugs: {'lotus'},
      );
      expect(export.png, isNotEmpty);
      expect(store.currentOwner().artworks.single.revision, 1);
      expect(snapshot(), before);
    },
  );
}
