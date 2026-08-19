import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/liked_content_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('toggle likes without writing wordbook favorites', () async {
    expect(
      LikedContentService.isLiked(kind: LikedContentService.vocab, id: '학교'),
      isFalse,
    );
    final liked = await LikedContentService.toggle(
      kind: LikedContentService.vocab,
      id: '학교',
    );
    expect(liked, isTrue);
    expect(
      LikedContentService.isLiked(kind: LikedContentService.vocab, id: '학교'),
      isTrue,
    );
    expect(Storage.vokFavorites, isEmpty);
    expect(LikedContentService.all(), hasLength(1));

    final unliked = await LikedContentService.toggle(
      kind: LikedContentService.vocab,
      id: '학교',
    );
    expect(unliked, isFalse);
    expect(LikedContentService.all(), isEmpty);
  });
}
