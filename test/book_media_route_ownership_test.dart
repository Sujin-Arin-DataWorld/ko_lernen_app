import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/book_result_screen.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';
import 'package:ko_lernen_app/screens/book_capture_screen.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/snap_ocr_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  test('preview transfers its lease to result exactly once', () async {
    var discards = 0;
    final owner = BookPreviewMediaOwner(
      'pending:book:p_book_flow.jpg',
      discard: (_) async => discards++,
    );

    expect(owner.transfer(), isTrue);
    expect(owner.transfer(), isFalse);
    await owner.release();

    expect(discards, 0);
  });

  test('preview retake/back releases its lease', () async {
    String? discarded;
    final owner = BookPreviewMediaOwner(
      'pending:book:p_book_flow.jpg',
      discard: (encoded) async => discarded = encoded,
    );

    await owner.release();
    await owner.release();

    expect(discarded, 'pending:book:p_book_flow.jpg');
    expect(owner.transfer(), isFalse);
  });

  test('failed navigation handoff can reclaim and release ownership', () async {
    var discards = 0;
    final owner = BookPreviewMediaOwner(
      'pending:book:p_book_flow.jpg',
      discard: (_) async => discards++,
    );

    expect(owner.transfer(), isTrue);
    owner.reclaim();
    await owner.release();

    expect(discards, 1);
  });

  test('reclaim cannot resurrect an already released owner', () async {
    var discards = 0;
    final owner = BookPreviewMediaOwner(
      'pending:book:p_book_flow.jpg',
      discard: (_) async => discards++,
    );

    await owner.release();
    owner.reclaim();
    await owner.release();

    expect(discards, 1);
    expect(owner.transfer(), isFalse);
  });

  test(
    'resumed OCR releases the claimed lease for every terminal failure',
    () async {
      final lease = PendingMediaLease.tryParse(
        'pending:book:p_book_recovered.jpg',
      )!;
      final failures = [
        OcrResult.failure(reason: OcrFailure.noKoreanFound),
        OcrResult.failure(reason: OcrFailure.engineError, message: 'engine'),
        OcrResult.failure(reason: OcrFailure.engineError, message: 'timeout'),
      ];

      for (final failure in failures) {
        var durableLease = lease.encoded;
        final discarded = <String>[];
        final owner = RecoveredBookOcrLeaseOwner(
          claim: (expectedLease) async {
            if (durableLease != expectedLease) {
              return null;
            }
            durableLease = '';
            return '{"lease":"$expectedLease"}';
          },
          isDurablyRecovered: (candidate) => durableLease == candidate.encoded,
          discard: (candidate) async => discarded.add(candidate.encoded),
        );

        expect(await owner.keepForResult(lease, failure), isFalse);
        expect(durableLease, isEmpty);
        expect(discarded, [lease.encoded]);
      }
    },
  );

  test('resumed OCR preserves lease when claim outcome is unknown', () async {
    final lease = PendingMediaLease.tryParse(
      'pending:book:p_book_recovered.jpg',
    )!;
    var discarded = false;
    final owner = RecoveredBookOcrLeaseOwner(
      claim: (_) async => throw const PreferenceOutcomeUnknownException(
        'kl_recovered_book_lease',
      ),
      isDurablyRecovered: (_) => false,
      discard: (_) async => discarded = true,
    );

    expect(
      await owner.keepForResult(
        lease,
        OcrResult.failure(reason: OcrFailure.engineError, message: 'timeout'),
      ),
      isFalse,
    );
    expect(discarded, isFalse);
  });

  test(
    'unknown result save keeps stable intent and preserves lease ownership',
    () async {
      final intent = BookResultSaveIntent(
        pageId: 'page-stable',
        capturedAtIso: '2026-07-29T00:00:00.000Z',
      );
      var writes = 0;

      await expectLater(
        intent.run((pageId, capturedAtIso) async {
          writes++;
          expect(pageId, 'page-stable');
          expect(capturedAtIso, '2026-07-29T00:00:00.000Z');
          throw const PreferenceOutcomeUnknownException('kl_bookshelf_v1');
        }),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );

      expect(intent.isUnresolved, isTrue);
      expect(intent.canStart, isFalse);
      expect(intent.shouldDiscardLease, isFalse);
      await expectLater(
        intent.run((_, __) async => writes++),
        throwsStateError,
      );
      expect(writes, 1);
    },
  );

  test('retryable result save reuses page identity', () async {
    final intent = BookResultSaveIntent(
      pageId: 'page-stable',
      capturedAtIso: '2026-07-29T00:00:00.000Z',
    );
    final identities = <String>[];

    await expectLater(
      intent.run((pageId, capturedAtIso) async {
        identities.add('$pageId@$capturedAtIso');
        throw StateError('retryable');
      }),
      throwsStateError,
    );
    expect(intent.canStart, isTrue);
    expect(intent.shouldDiscardLease, isTrue);

    await intent.run((pageId, capturedAtIso) async {
      identities.add('$pageId@$capturedAtIso');
    });

    expect(identities, [
      'page-stable@2026-07-29T00:00:00.000Z',
      'page-stable@2026-07-29T00:00:00.000Z',
    ]);
    expect(intent.isSaved, isTrue);
    expect(intent.shouldDiscardLease, isFalse);
  });
}
