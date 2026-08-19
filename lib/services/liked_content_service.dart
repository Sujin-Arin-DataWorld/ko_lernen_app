import '../models/liked_content.dart';
import 'storage_service.dart';

/// Play-later likes. Does **not** write the wordbook / `quickAdd`.
class LikedContentService {
  static const String vocab = 'vocab';
  static const String grammar = 'grammar';
  static const String hangul = 'hangul';
  static const String listening = 'listening';
  static const String smalltalk = 'smalltalk';

  static String keyFor({required String kind, required String id}) =>
      LikedContent(kind: kind, id: id).key;

  static bool isLiked({required String kind, required String id}) =>
      Storage.isLikedContent(keyFor(kind: kind, id: id));

  static Future<bool> toggle({required String kind, required String id}) =>
      Storage.toggleLikedContent(keyFor(kind: kind, id: id));

  static List<LikedContent> all() {
    return [
      for (final raw in Storage.likedContentKeys)
        if (LikedContent.tryParse(raw) case final item?) item,
    ];
  }
}
