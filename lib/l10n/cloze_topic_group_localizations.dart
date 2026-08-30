import '../data/cloze_topic_groups.dart';
import 'generated/app_localizations.dart';

/// Exhaustive DE/EN presentation mapping for stable cloze topic-group IDs.
extension ClozeTopicGroupLocalizations on ClozeTopicGroupId {
  String localizedLabel(AppL10n t) => switch (this) {
    ClozeTopicGroupId.everydayHome => t.clozeGroupEverydayHome,
    ClozeTopicGroupId.peopleRelationships => t.clozeGroupPeopleRelationships,
    ClozeTopicGroupId.travelServices => t.clozeGroupTravelServices,
    ClozeTopicGroupId.workEducation => t.clozeGroupWorkEducation,
    ClozeTopicGroupId.languageMedia => t.clozeGroupLanguageMedia,
    ClozeTopicGroupId.societyInstitutions => t.clozeGroupSocietyInstitutions,
    ClozeTopicGroupId.technologyScience => t.clozeGroupTechnologyScience,
    ClozeTopicGroupId.healthNatureLeisure => t.clozeGroupHealthNatureLeisure,
  };

  String localizedDescription(AppL10n t) => switch (this) {
    ClozeTopicGroupId.everydayHome => t.clozeGroupEverydayHomeDescription,
    ClozeTopicGroupId.peopleRelationships =>
      t.clozeGroupPeopleRelationshipsDescription,
    ClozeTopicGroupId.travelServices => t.clozeGroupTravelServicesDescription,
    ClozeTopicGroupId.workEducation => t.clozeGroupWorkEducationDescription,
    ClozeTopicGroupId.languageMedia => t.clozeGroupLanguageMediaDescription,
    ClozeTopicGroupId.societyInstitutions =>
      t.clozeGroupSocietyInstitutionsDescription,
    ClozeTopicGroupId.technologyScience =>
      t.clozeGroupTechnologyScienceDescription,
    ClozeTopicGroupId.healthNatureLeisure =>
      t.clozeGroupHealthNatureLeisureDescription,
  };
}
