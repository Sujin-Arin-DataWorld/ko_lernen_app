import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';

void main() {
  test(
    'reads only the authenticated owner passport state in catalog order',
    () async {
      final calls =
          <({String ownerUid, String collectionId, String documentId})>[];
      final reader = ContentFeedbackPassportReader(
        currentUid: () => 'owner-uid',
        readDocument:
            ({
              required ownerUid,
              required collectionId,
              required documentId,
            }) async {
              calls.add((
                ownerUid: ownerUid,
                collectionId: collectionId,
                documentId: documentId,
              ));
              return <String, Object?>{
                'catalogVersion': 1,
                'completedMissionIds': <String>[
                  'beta_scenario',
                  'beta_listening',
                ],
                'updatedAt': Object(),
              };
            },
      );

      expect(await reader.readCompletedMissionIds(), <String>{
        'beta_scenario',
        'beta_listening',
      });
      expect(
        calls,
        <({String ownerUid, String collectionId, String documentId})>[
          (
            ownerUid: 'owner-uid',
            collectionId: 'tester_passport',
            documentId: 'state',
          ),
        ],
      );
    },
  );

  test(
    'missing malformed and unordered passport states restore as empty',
    () async {
      final malformedStates = <Object?>[
        null,
        const <String, Object?>{},
        const <String, Object?>{
          'catalogVersion': 2,
          'completedMissionIds': <String>['beta_scenario'],
        },
        const <String, Object?>{
          'catalogVersion': 1,
          'completedMissionIds': <String>['unknown_mission'],
        },
        const <String, Object?>{
          'catalogVersion': 1,
          'completedMissionIds': <String>['beta_listening', 'beta_scenario'],
        },
        const <String, Object?>{
          'catalogVersion': 1,
          'completedMissionIds': <String>['beta_scenario', 'beta_scenario'],
        },
        const <String, Object?>{
          'catalogVersion': 1,
          'completedMissionIds': <Object?>['beta_scenario', 7],
        },
      ];

      for (final state in malformedStates) {
        final reader = ContentFeedbackPassportReader(
          currentUid: () => 'owner-uid',
          readDocument:
              ({
                required ownerUid,
                required collectionId,
                required documentId,
              }) async => state,
        );
        expect(await reader.readCompletedMissionIds(), isEmpty);
      }
    },
  );

  test(
    'auth switch while reading treats the returned state as foreign',
    () async {
      var liveUid = 'owner-uid';
      final document = Completer<Object?>();
      final reader = ContentFeedbackPassportReader(
        currentUid: () => liveUid,
        readDocument:
            ({required ownerUid, required collectionId, required documentId}) =>
                document.future,
      );

      final pending = reader.readCompletedMissionIds();
      liveUid = 'foreign-uid';
      document.complete(const <String, Object?>{
        'catalogVersion': 1,
        'completedMissionIds': <String>['beta_scenario'],
      });

      expect(await pending, isEmpty);
    },
  );

  test('UID and read failures are redacted to an empty state', () async {
    final uidFailure = ContentFeedbackPassportReader(
      currentUid: () => throw StateError('private uid detail'),
      readDocument:
          ({
            required ownerUid,
            required collectionId,
            required documentId,
          }) async => throw StateError('must not read'),
    );
    final readFailure = ContentFeedbackPassportReader(
      currentUid: () => 'owner-uid',
      readDocument:
          ({
            required ownerUid,
            required collectionId,
            required documentId,
          }) async => throw StateError('private feedback detail'),
    );

    expect(await uidFailure.readCompletedMissionIds(), isEmpty);
    expect(await readFailure.readCompletedMissionIds(), isEmpty);
  });
}
