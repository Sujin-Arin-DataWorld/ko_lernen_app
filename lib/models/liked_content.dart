/// One liked item in the play-later drawer (not the wordbook archive).
class LikedContent {
  const LikedContent({required this.kind, required this.id});

  final String kind;
  final String id;

  String get key => '$kind|$id';

  static LikedContent? tryParse(String raw) {
    final split = raw.split('|');
    if (split.length != 2) {
      return null;
    }
    final kind = split[0].trim();
    final id = split[1].trim();
    if (kind.isEmpty || id.isEmpty) {
      return null;
    }
    return LikedContent(kind: kind, id: id);
  }
}
