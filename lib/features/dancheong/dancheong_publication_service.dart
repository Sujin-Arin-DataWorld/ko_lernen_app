import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../services/storage_service.dart';
import 'dancheong_renderer.dart';
import 'dancheong_store.dart';

typedef DancheongCallable =
    Future<Object?> Function(String, Map<String, Object?>);

final class DancheongPublicationService {
  DancheongPublicationService({
    required this.store,
    DancheongCallable? call,
    String Function()? readRaw,
    Future<void> Function(String, void Function())? writeRaw,
  }) : call = call ?? _firebaseCall,
       readRaw = readRaw ?? (() => Storage.dancheongPublicationsRawJson),
       writeRaw =
           writeRaw ??
           ((raw, guard) => Storage.setDancheongPublicationsRawJsonStrict(
             raw,
             assertCurrentWrite: guard,
           ));
  final DancheongStore store;
  final DancheongCallable call;
  final String Function() readRaw;
  final Future<void> Function(String, void Function()) writeRaw;
  static Future<void>? _tail;
  static Future<void>? _operations;
  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final guard = store.captureGuard();
    final previous = _operations;
    final done = Completer<void>();
    _operations = done.future;
    try {
      if (previous != null) {
        await previous;
      }
      guard();
      return await action();
    } finally {
      if (identical(_operations, done.future)) {
        _operations = null;
      }
      done.complete();
    }
  }

  static Future<Object?> _firebaseCall(
    String name,
    Map<String, Object?> data,
  ) async => (await FirebaseFunctions.instanceFor(
    region: 'europe-west3',
  ).httpsCallable(name).call<Object?>(data)).data;
  String _key(DancheongExportPackage p) =>
      jsonEncode([p.artworkId, p.revision, p.format.name]);
  Map<String, Object?> _document() {
    final raw = readRaw();
    if (raw.isEmpty) {
      return {'version': 1, 'owners': <String, Object?>{}};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map ||
        decoded['version'] != 1 ||
        decoded['owners'] is! Map ||
        decoded.keys.any((key) => !{'version', 'owners'}.contains(key))) {
      throw const FormatException('Unsupported publication data');
    }
    for (final entry in (decoded['owners'] as Map).entries) {
      if (entry.key is! String ||
          (entry.key as String).isEmpty ||
          entry.value is! Map ||
          (entry.value as Map).length > 100) {
        throw const FormatException('Invalid publication owner');
      }
      for (final job in (entry.value as Map).entries) {
        final key = job.key is String ? jsonDecode(job.key as String) : null;
        final value = job.value;
        if (key is! List ||
            key.length != 3 ||
            key[0] is! String ||
            !_uuid.hasMatch(key[0] as String) ||
            key[1] is! int ||
            key[1] < 1 ||
            key[1] > 1000000 ||
            !{'portrait', 'story'}.contains(key[2]) ||
            value is! Map ||
            value.length != 4 ||
            value.keys.any(
              (k) => !{'requestId', 'digest', 'status', 'shareId'}.contains(k),
            ) ||
            value['requestId'] is! String ||
            !_uuid.hasMatch(value['requestId'] as String) ||
            value['digest'] is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['digest'] as String) ||
            !{'pending', 'active', 'revoked'}.contains(value['status']) ||
            (value['shareId'] != null &&
                (value['shareId'] is! String ||
                    !RegExp(
                      r'^[A-Za-z0-9_-]{32}$',
                    ).hasMatch(value['shareId'] as String))) ||
            (value['status'] != 'pending' && value['shareId'] == null)) {
          throw const FormatException('Invalid publication intent');
        }
      }
    }
    return Map<String, Object?>.from(decoded);
  }

  static final _uuid = RegExp(
    r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$',
    caseSensitive: false,
  );

  Map<String, Object?>? current(DancheongExportPackage p) {
    return currentFor(p.artworkId, p.revision, p.format.name);
  }

  Map<String, Object?>? currentFor(
    String artworkId,
    int revision,
    String format,
  ) {
    final owners = _document()['owners']! as Map;
    final owner = owners[store.currentOwnerKey];
    if (owner is! Map) {
      return null;
    }
    final value = owner[jsonEncode([artworkId, revision, format])];
    return value is Map ? Map<String, Object?>.from(value) : null;
  }

  Future<void> _save(String key, Map<String, Object?> value) async {
    final guard = store.captureGuard();
    final ownerKey = store.currentOwnerKey;
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      if (previous != null) {
        await previous;
      }
      guard();
      final document = _document();
      final owners = Map<String, Object?>.from(document['owners']! as Map);
      final owner = Map<String, Object?>.from(owners[ownerKey] as Map? ?? {});
      if (owner.length >= 100 && !owner.containsKey(key)) {
        throw StateError('Publication limit');
      }
      owner[key] = value;
      owners[ownerKey] = owner;
      await writeRaw(jsonEncode({'version': 1, 'owners': owners}), guard);
      guard();
    } finally {
      if (identical(_tail, done.future)) {
        _tail = null;
      }
      done.complete();
    }
  }

  Map<String, Object?> _response(Object? raw) {
    if (raw is! Map ||
        !{'pending', 'active', 'revoked'}.contains(raw['status']) ||
        raw['shareId'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{32}$').hasMatch(raw['shareId'] as String)) {
      throw const FormatException('Invalid publication response');
    }
    return {'status': raw['status'], 'shareId': raw['shareId']};
  }

  Future<Uri> publish(DancheongExportPackage package) =>
      _exclusive(() => _publish(package));
  Future<Uri> _publish(DancheongExportPackage package) async {
    final guard = store.captureGuard();
    if (store.currentOwnerKey == 'device') {
      throw const DancheongStoreFailure(DancheongStoreError.blocked);
    }
    if (package.png.length > 4 * 1024 * 1024) {
      throw const FormatException('public-image-too-large');
    }
    final c = package.composition;
    final manifest = <String, Object?>{
      'version': 1,
      'template': c.template.name,
      'templateVersion': c.templateVersion,
      'assetVersion': c.assetVersion,
      'format': package.format.name,
      'width': package.width,
      'height': package.height,
      'motifSlugs': c.motifSlugs,
      'koreanText': c.koreanText,
      'translation': c.translation,
      'translationLocale': c.translationLocale,
      'signature': c.signature,
      'border': c.border.name,
    };
    final digest = sha256
        .convert(
          utf8.encode(jsonEncode([manifest, package.revision, package.sha256])),
        )
        .toString();
    final key = _key(package);
    var intent = current(package);
    if (intent != null && intent['digest'] != digest) {
      throw const FormatException('Publication differs from saved intent');
    }
    if (intent == null) {
      intent = {
        'requestId': const Uuid().v4(),
        'digest': digest,
        'status': 'pending',
        'shareId': null,
      };
      await _save(key, intent);
      guard();
    }
    if (intent['status'] == 'revoked') {
      throw StateError('Publication was revoked');
    }
    final requestId = intent['requestId'];
    final recovered = await call('getOwnDancheongShare', {
      'requestId': requestId,
    });
    guard();
    Map<String, Object?> response;
    if (recovered is Map && recovered['status'] == 'active') {
      response = _response(recovered);
    } else if (recovered is Map && recovered['status'] == 'revoked') {
      await _save(key, {...intent, ..._response(recovered)});
      throw StateError('Publication was revoked');
    } else {
      response = _response(
        await call('createDancheongShare', {
          'requestId': requestId,
          'artworkRevision': package.revision,
          'manifest': manifest,
          'pngBase64': base64Encode(package.png),
        }),
      );
      guard();
    }
    await _save(key, {...intent, ...response});
    guard();
    if (response['status'] != 'active') {
      throw StateError('Publication is not active');
    }
    return Uri.https('hangul-sori.com', '/art/${response['shareId']}');
  }

  Future<void> revoke(DancheongExportPackage package) =>
      revokeFor(package.artworkId, package.revision, package.format.name);
  Future<void> revokeFor(String artworkId, int revision, String format) =>
      _exclusive(() async {
        final guard = store.captureGuard();
        final intent = currentFor(artworkId, revision, format);
        if (intent == null) {
          return;
        }
        final response = _response(
          await call('revokeDancheongShare', {
            'requestId': intent['requestId'],
          }),
        );
        guard();
        await _save(jsonEncode([artworkId, revision, format]), {
          ...intent,
          ...response,
        });
        guard();
      });
}
