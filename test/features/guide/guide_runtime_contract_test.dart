import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';

void main() {
  test('purpose changes order without hiding any guide module', () {
    for (final motivation in const [
      'daily_travel',
      'people_culture',
      'study_work',
      'k_content',
      '',
    ]) {
      final topics = purposeOrderedGuideTopics(motivation);
      expect(topics, hasLength(GuideTopicCatalog.all.length));
      expect(
        topics.map((topic) => topic.id).toSet(),
        GuideTopicCatalog.all.map((topic) => topic.id).toSet(),
        reason: motivation,
      );
    }
  });

  test('each purpose keeps its three recommended modules first', () {
    List<GuideTopicId> firstThree(String motivation) =>
        purposeOrderedGuideTopics(
          motivation,
        ).take(3).map((topic) => topic.id).toList();

    expect(firstThree('daily_travel'), [
      GuideTopicId.personalizedStart,
      GuideTopicId.learn,
      GuideTopicId.myBook,
    ]);
    expect(firstThree('people_culture'), [
      GuideTopicId.learn,
      GuideTopicId.personalizedStart,
      GuideTopicId.gamesAndRewards,
    ]);
    expect(firstThree('study_work'), [
      GuideTopicId.personalizedStart,
      GuideTopicId.myBook,
      GuideTopicId.learn,
    ]);
    expect(firstThree('k_content'), [
      GuideTopicId.learn,
      GuideTopicId.gamesAndRewards,
      GuideTopicId.personalizedStart,
    ]);
  });

  test('legacy purpose aliases keep the same V2 guide priorities', () {
    List<GuideTopicId> ids(String motivation) =>
        purposeOrderedGuideTopics(motivation).map((topic) => topic.id).toList();

    expect(ids('loved'), ids('people_culture'));
    expect(ids('curious'), ids('people_culture'));
    expect(ids('kpop'), ids('k_content'));
    expect(ids('kdrama'), ids('k_content'));
    expect(ids('travel'), ids('daily_travel'));
    expect(ids('career'), ids('study_work'));
  });
}
