import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/cloze_topic_groups.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';

typedef _ClozeGroupCopy = ({String label, String description});

_ClozeGroupCopy _clozeGroupCopy(AppL10n t, ClozeTopicGroupId group) =>
    switch (group) {
      ClozeTopicGroupId.everydayHome => (
        label: t.clozeGroupEverydayHome,
        description: t.clozeGroupEverydayHomeDescription,
      ),
      ClozeTopicGroupId.peopleRelationships => (
        label: t.clozeGroupPeopleRelationships,
        description: t.clozeGroupPeopleRelationshipsDescription,
      ),
      ClozeTopicGroupId.travelServices => (
        label: t.clozeGroupTravelServices,
        description: t.clozeGroupTravelServicesDescription,
      ),
      ClozeTopicGroupId.workEducation => (
        label: t.clozeGroupWorkEducation,
        description: t.clozeGroupWorkEducationDescription,
      ),
      ClozeTopicGroupId.languageMedia => (
        label: t.clozeGroupLanguageMedia,
        description: t.clozeGroupLanguageMediaDescription,
      ),
      ClozeTopicGroupId.societyInstitutions => (
        label: t.clozeGroupSocietyInstitutions,
        description: t.clozeGroupSocietyInstitutionsDescription,
      ),
      ClozeTopicGroupId.technologyScience => (
        label: t.clozeGroupTechnologyScience,
        description: t.clozeGroupTechnologyScienceDescription,
      ),
      ClozeTopicGroupId.healthNatureLeisure => (
        label: t.clozeGroupHealthNatureLeisure,
        description: t.clozeGroupHealthNatureLeisureDescription,
      ),
    };

// de/en 번역 키 parity 래칫 — 현재 델타 0. 늘리지 말 것.
// (@ 로 시작하는 메타데이터 항목은 템플릿(DE) 전용이 정상이라 제외.)
void main() {
  test('app_de.arb ↔ app_en.arb 번역 키 델타 0', () {
    Set<String> keysOf(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();

    final de = keysOf('lib/l10n/app_de.arb');
    final en = keysOf('lib/l10n/app_en.arb');
    final onlyDe = de.difference(en);
    final onlyEn = en.difference(de);
    expect(onlyDe, isEmpty, reason: 'DE 에만 있는 키 — EN 번역을 같이 추가할 것');
    expect(onlyEn, isEmpty, reason: 'EN 에만 있는 키 — DE 번역을 같이 추가할 것');
  });

  test('Cloze 8개 그룹은 DE/EN 라벨과 설명을 모두 해석한다', () {
    for (final t in <AppL10n>[AppL10nDe(), AppL10nEn()]) {
      expect(t.clozeGroupAll.trim(), isNotEmpty);
      for (final group in ClozeTopicGroups.ordered) {
        final copy = _clozeGroupCopy(t, group);
        expect(
          copy.label.trim(),
          isNotEmpty,
          reason: '${t.localeName}: $group label',
        );
        expect(
          copy.description.trim(),
          isNotEmpty,
          reason: '${t.localeName}: $group description',
        );
      }
    }
  });

  test('Cloze 그룹 라벨과 설명은 각 언어 안에서 서로 구별된다', () {
    for (final t in <AppL10n>[AppL10nDe(), AppL10nEn()]) {
      final copies = ClozeTopicGroups.ordered
          .map((group) => _clozeGroupCopy(t, group))
          .toList(growable: false);
      expect(
        {t.clozeGroupAll, ...copies.map((copy) => copy.label)},
        hasLength(ClozeTopicGroups.ordered.length + 1),
        reason: '${t.localeName}: labels',
      );
      expect(
        copies.map((copy) => copy.description).toSet(),
        hasLength(ClozeTopicGroups.ordered.length),
        reason: '${t.localeName}: descriptions',
      );
    }
  });

  test('Cloze DE/EN 그룹 문구에는 한국어 fallback이 없다', () {
    final hangul = RegExp(r'[\uAC00-\uD7A3]');
    for (final t in <AppL10n>[AppL10nDe(), AppL10nEn()]) {
      final visibleCopy = <String>[
        t.clozeGroupAll,
        for (final group in ClozeTopicGroups.ordered) ...[
          _clozeGroupCopy(t, group).label,
          _clozeGroupCopy(t, group).description,
        ],
      ];
      expect(visibleCopy.where(hangul.hasMatch), isEmpty, reason: t.localeName);
    }
  });
}
