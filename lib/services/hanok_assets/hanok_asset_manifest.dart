import 'dart:convert';

/// The shipped manifest is the only authority for remote artwork paths.
class HanokAssetManifest {
  static const bucket = 'ko-lernen-app.firebasestorage.app';
  final List<HanokAssetPack> packs;
  final Map<String, HanokAsset> assets;
  final Map<String, HanokAssetPack> packsByAsset;

  HanokAssetManifest._(this.packs, this.assets, this.packsByAsset);

  factory HanokAssetManifest.parse(String source) {
    final json = jsonDecode(source);
    void require(bool condition) {
      if (!condition) {
        throw const FormatException('Invalid Hanok artwork manifest');
      }
    }

    require(json is Map<String, dynamic>);
    require(
      json['schemaVersion'] is int &&
          json['schemaVersion'] == 1 &&
          json['storageBucket'] == bucket,
    );
    require(json['packs'] is List && (json['packs'] as List).isNotEmpty);
    final packs = <HanokAssetPack>[];
    final assets = <String, HanokAsset>{};
    final owners = <String, HanokAssetPack>{};
    final ids = <String>{};
    final hashes = <String, HanokAsset>{};
    for (final rawPack in json['packs']) {
      require(rawPack is Map<String, dynamic>);
      final id = rawPack['id'];
      require(
        id is String && RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id),
      );
      require(ids.add(id));
      final title = rawPack['title'];
      require(title is Map<String, dynamic>);
      require((title as Map).values.every((value) => value is String));
      for (final lang in ['ko', 'en', 'de']) {
        require(
          title[lang] is String && (title[lang] as String).trim().isNotEmpty,
        );
      }
      require(
        rawPack['assets'] is List && (rawPack['assets'] as List).isNotEmpty,
      );
      final entries = <HanokAsset>[];
      for (final raw in rawPack['assets']) {
        require(raw is Map<String, dynamic>);
        final path = raw['asset'];
        final hash = raw['sha256'];
        final bytes = raw['bytes'];
        final type = raw['contentType'];
        require(
          path is String &&
              RegExp(
                r'^assets/(?:[A-Za-z0-9_-]+/)+[A-Za-z0-9_-]+\.(png|webp)$',
              ).hasMatch(path),
        );
        require(hash is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(hash));
        require(bytes is int && bytes > 0 && bytes <= 300 * 1024 * 1024);
        final extension = (path as String).split('.').last;
        require(type == 'image/$extension');
        require(raw['storagePath'] == 'learning-art/v1/$hash.$extension');
        require(!assets.containsKey(path));
        final entry = HanokAsset._(path, hash, bytes, type, raw['storagePath']);
        final previous = hashes[hash];
        require(
          previous == null ||
              (previous.bytes == bytes && previous.contentType == type),
        );
        hashes[hash] = entry;
        assets[path] = entry;
        entries.add(entry);
      }
      final pack = HanokAssetPack._(
        id,
        Map<String, String>.from(title),
        entries,
      );
      packs.add(pack);
      for (final entry in entries) {
        owners[entry.asset] = pack;
      }
    }
    return HanokAssetManifest._(
      List.unmodifiable(packs),
      Map.unmodifiable(assets),
      Map.unmodifiable(owners),
    );
  }
}

class HanokAssetPack {
  final String id;
  final Map<String, String> title;
  final List<HanokAsset> assets;
  HanokAssetPack._(this.id, Map<String, String> title, List<HanokAsset> assets)
    : title = Map.unmodifiable(title),
      assets = List.unmodifiable(assets);
  int get totalBytes => assets.fold(0, (sum, entry) => sum + entry.bytes);
}

class HanokAsset {
  final String asset;
  final String sha256;
  final int bytes;
  final String contentType;
  final String storagePath;
  HanokAsset._(
    this.asset,
    this.sha256,
    this.bytes,
    this.contentType,
    this.storagePath,
  );
  String get filename => storagePath.split('/').last;
  Uri get mediaUri => Uri(
    scheme: 'https',
    host: 'firebasestorage.googleapis.com',
    pathSegments: ['v0', 'b', HanokAssetManifest.bucket, 'o', storagePath],
    queryParameters: {'alt': 'media'},
  );
}
