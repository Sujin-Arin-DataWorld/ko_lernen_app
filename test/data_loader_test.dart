import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DataLoader.reset);

  test(
    'loads every bundled vocabulary record after quoted CSV fields',
    () async {
      final vocab = await DataLoader.loadVocab();

      expect(vocab, hasLength(558));

      final yes = vocab.singleWhere((entry) => entry.korean == '네');
      expect(yes.exampleKorean, '네, 알겠어요.');
      expect(yes.exampleGerman, 'Ja, das stimmt.');

      final afterQuotedFields = vocab.singleWhere(
        (entry) => entry.korean == '이름',
      );
      expect(afterQuotedFields.romanization, 'ireum');
      expect(afterQuotedFields.german, 'Name');
      expect(afterQuotedFields.exampleGerman, 'Mein Name ist Christian.');
    },
  );
}
