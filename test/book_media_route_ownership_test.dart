import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/book_preview_screen.dart';

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
}
