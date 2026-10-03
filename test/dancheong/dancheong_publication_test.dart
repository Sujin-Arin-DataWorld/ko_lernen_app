import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_renderer.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_publication_service.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  test(
    'simultaneous publication persists one pending request and never uploads twice',
    () async {
      var raw = '';
      var uploads = 0;
      var active = false;
      final sessions = CloudWriteSessionController()..acquire('owner');
      final store = DancheongStore(readRaw: () => '', sessions: sessions);
      late DancheongPublicationService service;
      service = DancheongPublicationService(
        store: store,
        readRaw: () => raw,
        writeRaw: (value, guard) async {
          guard();
          raw = value;
        },
        call: (name, data) async {
          expect(service.current(_package())!['requestId'], isNotNull);
          if (name == 'getOwnDancheongShare') {
            return active ? {'shareId': 'A' * 32, 'status': 'active'} : null;
          }
          uploads++;
          active = true;
          return {'shareId': 'A' * 32, 'status': 'active'};
        },
      );
      final links = await Future.wait([
        service.publish(_package()),
        service.publish(_package()),
      ]);
      expect(links[0], links[1]);
      expect(uploads, 1);
    },
  );
  test(
    'UID changes during callable await cannot attach a result to another owner',
    () async {
      var raw = '';
      final sessions = CloudWriteSessionController()..acquire('owner-a');
      final store = DancheongStore(readRaw: () => '', sessions: sessions);
      final entered = Completer<void>(), gate = Completer<Object?>();
      final service = DancheongPublicationService(
        store: store,
        readRaw: () => raw,
        writeRaw: (value, guard) async {
          guard();
          raw = value;
        },
        call: (name, data) async {
          if (name == 'getOwnDancheongShare') {
            return null;
          }
          entered.complete();
          return gate.future;
        },
      );
      final operation = service.publish(_package());
      final assertion = expectLater(
        operation,
        throwsA(isA<DancheongStoreFailure>()),
      );
      await entered.future;
      sessions.acquire('owner-b');
      gate.complete({'shareId': 'A' * 32, 'status': 'active'});
      await assertion;
      expect(service.current(_package()), isNull);
      expect(store.currentOwner().artworks, isEmpty);
      sessions.acquire('owner-a');
      expect(service.current(_package())!['status'], 'pending');
    },
  );
  test(
    'lost creation response recovers same request after restart before any reupload',
    () async {
      var raw = '';
      String? firstRequest;
      var uploads = 0;
      var active = false;
      final store = DancheongStore(
        readRaw: () => '',
        sessions: CloudWriteSessionController()..acquire('owner'),
      );
      Future<Object?> call(String name, Map<String, Object?> data) async {
        if (name == 'getOwnDancheongShare') {
          return active ? {'shareId': 'A' * 32, 'status': 'active'} : null;
        }
        uploads++;
        firstRequest = data['requestId'] as String;
        active = true;
        throw StateError('response lost');
      }

      DancheongPublicationService service() => DancheongPublicationService(
        store: store,
        readRaw: () => raw,
        writeRaw: (value, guard) async {
          guard();
          raw = value;
        },
        call: call,
      );
      final package = DancheongExportPackage(
        artworkId: '00000000-0000-4000-8000-000000000001',
        revision: 1,
        format: DancheongFormat.portrait,
        png: Uint8List.fromList([1, 2, 3]),
        width: 1080,
        height: 1350,
        composition: DancheongComposition(
          template: DancheongTemplate.flower,
          format: DancheongFormat.portrait,
          motifSlugs: ['lotus'],
        ),
        sha256: 'a' * 64,
      );
      await expectLater(service().publish(package), throwsStateError);
      expect(service().current(package)!['requestId'], firstRequest);
      expect((await service().publish(package)).path, '/art/${'A' * 32}');
      expect(uploads, 1);
      expect(service().current(package)!['status'], 'active');
    },
  );
}

DancheongExportPackage _package() => DancheongExportPackage(
  artworkId: '00000000-0000-4000-8000-000000000001',
  revision: 1,
  format: DancheongFormat.portrait,
  png: Uint8List.fromList([1, 2, 3]),
  width: 1080,
  height: 1350,
  composition: DancheongComposition(
    template: DancheongTemplate.flower,
    format: DancheongFormat.portrait,
    motifSlugs: ['lotus'],
  ),
  sha256: 'a' * 64,
);
