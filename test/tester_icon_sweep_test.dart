import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('task_alt 테스터 아이콘은 lib/ 에서 사라졌다 (지시서 1.13/1.17)', () {
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.readAsStringSync().contains('task_alt')) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
