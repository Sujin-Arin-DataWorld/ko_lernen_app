import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_models.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';

const draftId = '00000000-0000-4000-8000-000000000002';

DancheongDraft draft() => DancheongDraft(
  id: draftId,
  composition: DancheongComposition(
    template: DancheongTemplate.flower,
    format: DancheongFormat.portrait,
    motifSlugs: ['lotus'],
  ),
  updatedAt: DateTime.utc(2026, 10, 3),
);

final class MemoryDocument {
  String raw = '';
  Completer<void>? gate;
  Completer<void>? entered;
  bool reject = false;
  Future<void> write(String value, void Function() guard) async {
    entered?.complete();
    await gate?.future;
    guard();
    if (reject) {
      throw StateError('Native write rejected');
    }
    raw = value;
  }
}

void main() {
  late MemoryDocument memory;
  late CloudWriteSessionController sessions;
  DancheongStore store() => DancheongStore(
    readRaw: () => memory.raw,
    writeRaw: memory.write,
    sessions: sessions,
    readOwned: () => {'lotus'},
  );

  setUp(() {
    memory = MemoryDocument();
    sessions = CloudWriteSessionController()..acquire('owner-a');
  });

  test(
    'new store after restart restores draft and empty edited captions',
    () async {
      await store().saveDraft(draft());
      await store().saveCaption('de', '');
      await store().saveCaption('en', 'My own words');
      final restarted = store().currentOwner();
      expect(restarted.drafts.single.id, draftId);
      expect(restarted.captions, {'de': '', 'en': 'My own words'});
    },
  );

  test('account B never sees A artwork or captions', () async {
    await store().saveDraft(draft());
    await store().saveCaption('de', 'Private A');
    sessions.acquire('owner-b');
    expect(store().currentOwner().drafts, isEmpty);
    expect(store().currentOwner().captions, isEmpty);
    sessions.acquire('owner-a');
    expect(store().currentOwner().drafts.single.id, draftId);
  });

  test(
    'A to B to A invalidates a delayed write with the original UID',
    () async {
      memory.gate = Completer<void>();
      memory.entered = Completer<void>();
      final save = store().saveDraft(draft());
      final expectation = expectLater(
        save,
        throwsA(isA<DancheongStoreFailure>()),
      );
      await memory.entered!.future;
      sessions.acquire('owner-b');
      sessions.acquire('owner-a');
      memory.gate!.complete();
      await expectation;
      expect(memory.raw, '');
    },
  );

  test('local reset invalidates a delayed draft save', () async {
    memory.gate = Completer<void>();
    memory.entered = Completer<void>();
    final save = store().saveDraft(draft());
    final expectation = expectLater(
      save,
      throwsA(isA<DancheongStoreFailure>()),
    );
    await memory.entered!.future;
    LocalDataLifetime.invalidate();
    memory.gate!.complete();
    await expectation;
    expect(memory.raw, '');
  });

  test('malformed data is not replaced by an empty document on save', () async {
    memory.raw = '{';
    await expectLater(
      store().saveDraft(draft()),
      throwsA(isA<DancheongStoreFailure>()),
    );
    expect(memory.raw, '{');
  });

  test('failed durable write does not claim a saved draft', () async {
    memory.reject = true;
    await expectLater(store().saveDraft(draft()), throwsStateError);
    expect(store().currentOwner().drafts, isEmpty);
  });

  test(
    'two store instances serialize caption updates without losing either',
    () async {
      await Future.wait([
        store().saveCaption('de', 'Mein Werk'),
        store().saveCaption('en', 'My artwork'),
      ]);
      expect(store().currentOwner().captions, {
        'de': 'Mein Werk',
        'en': 'My artwork',
      });
    },
  );

  test(
    'finishing removes only the draft and repeated finish cannot duplicate it',
    () async {
      final storage = store();
      await storage.saveDraft(draft());
      final first = await storage.finishDraft(draftId);
      expect(first.revision, 1);
      expect(storage.currentOwner().drafts, isEmpty);
      await expectLater(
        storage.finishDraft(draftId),
        throwsA(isA<DancheongStoreFailure>()),
      );
      expect(storage.currentOwner().artworks, hasLength(1));
      await storage.saveDraft(draft());
      final edited = await storage.finishDraft(draftId);
      expect(edited.revision, 2);
      expect(storage.currentOwner().artworks.map((art) => art.revision), [
        1,
        2,
      ]);
    },
  );

  test(
    'unknown or missing owned material cannot produce finished art',
    () async {
      final storage = store();
      await storage.saveDraft(draft());
      final changedOwnership = DancheongStore(
        readRaw: () => memory.raw,
        writeRaw: memory.write,
        sessions: sessions,
        readOwned: () => {},
      );
      await expectLater(
        changedOwnership.finishDraft(draftId),
        throwsA(isA<DancheongStoreFailure>()),
      );
      expect(storage.currentOwner().drafts, hasLength(1));
      expect(storage.currentOwner().artworks, isEmpty);
    },
  );
}
