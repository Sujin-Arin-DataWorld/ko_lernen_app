// Phase E — LessonRecommenderService.
//
// 추천 알고리즘이 홈 학습 경로의 "now" 노드 선택과 동일한지 + 레벨 진급이
// 실제 unlock 모델(첫 non-cleared·non-locked 팩)을 따르는지 검증.
//
// 실제 번들 CSV(95팩)를 로드한다 → 콘텐츠 정확값이 아니라 "불변 속성"만 단언
// (콘텐츠가 바뀌어도 깨지지 않게): 첫 추천은 A1 첫 팩, inProgress 우선,
// A1 전부 클리어 시 A2로 진급.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/services/lesson_recommender_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    Storage.resetPackProgressForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    VocabPackService.reset();
  });

  Future<void> store(String id, String level, int total, PackStatus s) async {
    await Storage.setPackProgressJson(
      id,
      PackProgress.fresh(
        packId: id,
        level: level,
        wordsTotal: total,
        status: s,
      ).toJson(),
    );
  }

  test('번들 CSV 가 테스트에서 로드된다 (전제)', () async {
    final all = await VocabPackService.loadAll();
    expect(
      all,
      isNotEmpty,
      reason: 'korean_vocab.csv 가 flutter test 에서 로드되어야 함',
    );
    expect(all.any((p) => p.level == 'A1'), isTrue);
  });

  test('신규 사용자 → A1 첫 팩 newChallenge, userLevel A1', () async {
    final all = await VocabPackService.loadAll();
    final firstA1 = all.firstWhere((p) => p.level == 'A1');

    final rec = await LessonRecommenderService.getNextLesson();
    expect(rec, isNotNull);
    expect(rec!.kind, LessonKind.newChallenge);
    expect(rec.level, 'A1');
    expect(rec.packId, firstA1.id);

    expect(await LessonRecommenderService.getUserLevel(), 'A1');
  });

  test('진행 중 팩이 있으면 → 그 팩 continueLearning', () async {
    final a1 = await VocabPackService.packsForLevel('A1');
    final first = a1.first;
    await store(first.id, 'A1', first.total, PackStatus.inProgress);

    final rec = await LessonRecommenderService.getNextLesson();
    expect(rec, isNotNull);
    expect(rec!.kind, LessonKind.continueLearning);
    expect(rec.packId, first.id);
  });

  test('A1 전부 클리어 → A2 추천 + userLevel A2', () async {
    final a1 = await VocabPackService.packsForLevel('A1');
    for (final p in a1) {
      await store(p.id, 'A1', p.total, PackStatus.cleared);
    }

    expect(await LessonRecommenderService.getUserLevel(), 'A2');

    final rec = await LessonRecommenderService.getNextLesson();
    expect(rec, isNotNull);
    expect(rec!.level, 'A2');
    expect(rec.kind, LessonKind.newChallenge);
  });
}
