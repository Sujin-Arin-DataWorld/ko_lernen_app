enum HanokAssetFailureKind {
  explicitDownloadNeeded,
  network,
  corrupt,
  cacheFull,
  storage,
  removed,
  unknownAsset,
}

/// Codes are for localized UI; internal errors never contain tokens or URLs.
class HanokAssetFailure implements Exception {
  final HanokAssetFailureKind kind;
  const HanokAssetFailure(this.kind);
  @override
  String toString() => 'HanokAssetFailure(${kind.name})';
}
