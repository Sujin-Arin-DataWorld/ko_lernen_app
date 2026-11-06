import 'package:flutter/material.dart';

import '../../models/curriculum.dart';
import '../../services/mission_recommender.dart';
import 'c_gallery/c_materials.dart';

/// Content identity, rather than a translated title, owns Today artwork.
/// Original bytes, semantic evidence and deliberate gaps: docs/assets/today-topic-art.json.
abstract final class TodaySubjectArt {
  static const root = 'assets/illustrations/concept_c/today/';
  static const atlas = '${root}today-props.png';
  static const environments = '${root}today-environments.png';
  static const packAssets = <String, String>{
    'a1_sorry_thanks_1': '${root}sorry-thanks.png',
    'a1_repair_language_1': '${root}repair-language.png',
    'a1_transport': '${root}transport.png',
    'a2_restaurant_1': '${root}restaurant.png',
    'a2_partner_chuseok_basic_1': '${root}chuseok.png',
  };
  static const greetings = Rect.fromLTRB(3 / 1254, 191 / 1254, .5, 530 / 1254);
  static const review = Rect.fromLTRB(641 / 1254, 165 / 1254, 1, 541 / 1254);
  static const hangul = Rect.fromLTRB(3 / 1254, 807 / 1254, .5, 1085 / 1254);
  static const chest = Rect.fromLTRB(.5, 729 / 1254, 1248 / 1254, 1177 / 1254);

  /// Standalone originals, drawn with optical regions rather than edited PNGs.
  static const subjectImages = <String, TodaySubjectImage>{
    'a1_body': TodaySubjectImage(
      '${root}sorry-thanks.png',
      Rect.fromLTRB(16 / 1254, 28 / 1254, 1238 / 1254, 1254 / 1254),
    ),
    'a1_counter': TodaySubjectImage(
      '${root}shop-counter.png',
      Rect.fromLTRB(0 / 1254, 19 / 1254, 1236 / 1254, 1254 / 1254),
    ),
    'a1_home': TodaySubjectImage(
      '${root}home-key.png',
      Rect.fromLTRB(0 / 1254, 27 / 1254, 1198 / 1254, 1240 / 1254),
    ),
    'a1_repeat': TodaySubjectImage(
      '${root}repair-language.png',
      Rect.fromLTRB(0 / 1254, 36 / 1254, 1244 / 1254, 1254 / 1254),
    ),
    'a1_transit': TodaySubjectImage(
      '${root}transport.png',
      Rect.fromLTRB(0 / 1254, 39 / 1254, 1240 / 1254, 1254 / 1254),
    ),
    'a2_apt': TodaySubjectImage(
      '${root}recycling-rules.png',
      Rect.fromLTRB(0 / 1254, 49 / 1254, 1225 / 1254, 1254 / 1254),
    ),
    'a2_booking': TodaySubjectImage(
      '${root}restaurant.png',
      Rect.fromLTRB(0 / 1254, 31 / 1254, 1238 / 1254, 1254 / 1254),
    ),
    'a2_move': TodaySubjectImage(
      '${root}travel-adjustment.png',
      Rect.fromLTRB(0 / 1254, 67 / 1254, 1222 / 1254, 1254 / 1254),
    ),
    'a2_partner': TodaySubjectImage(
      '${root}chuseok.png',
      Rect.fromLTRB(0 / 1254, 21 / 1254, 1232 / 1254, 1254 / 1254),
    ),
    'a2_plan': TodaySubjectImage(
      '${root}plans-proposals.png',
      Rect.fromLTRB(22 / 1254, 231 / 1254, 1238 / 1254, 1158 / 1254),
    ),
    'b1_delay': TodaySubjectImage(
      '${root}travel-change.png',
      Rect.fromLTRB(40 / 1254, 84 / 1254, 1220 / 1254, 1254 / 1254),
    ),
    'b1_feel': TodaySubjectImage(
      '${root}relationship-feelings.png',
      Rect.fromLTRB(0 / 1254, 64 / 1254, 1234 / 1254, 1254 / 1254),
    ),
    'b1_refund': TodaySubjectImage(
      '${root}refund-remedy.png',
      Rect.fromLTRB(0 / 1254, 7 / 1254, 1220 / 1254, 1254 / 1254),
    ),
    'b1_team': TodaySubjectImage(
      '${root}work-coordination.png',
      Rect.fromLTRB(24 / 1254, 26 / 1254, 1253 / 1254, 1254 / 1254),
    ),
    'b2_evidence': TodaySubjectImage(
      '${root}media-evidence.png',
      Rect.fromLTRB(0 / 1254, 80 / 1254, 1218 / 1254, 1254 / 1254),
    ),
    'b2_hiring': TodaySubjectImage(
      '${root}job-interview.png',
      Rect.fromLTRB(0 / 1254, 0 / 1254, 1236 / 1254, 1254 / 1254),
    ),
    'b2_negotiate': TodaySubjectImage(
      '${root}request-negotiation.png',
      Rect.fromLTRB(31 / 1254, 373 / 1254, 1224 / 1254, 1155 / 1254),
    ),
    'b2_public': TodaySubjectImage(
      '${root}shared-public-space.png',
      Rect.fromLTRB(0 / 1254, 17 / 1254, 1234 / 1254, 1254 / 1254),
    ),
    'c1_policy': TodaySubjectImage(
      '${root}participation-policy.png',
      Rect.fromLTRB(47 / 1254, 220 / 1254, 1210 / 1254, 1216 / 1254),
    ),
    'c2_mandate': TodaySubjectImage(
      '${root}institutional-mandate.png',
      Rect.fromLTRB(29 / 1254, 296 / 1254, 1230 / 1254, 1113 / 1254),
    ),
    'c1_fandom': TodaySubjectImage(
      '${root}fan-participation.png',
      Rect.fromLTRB(40 / 1254, 25 / 1254, 1234 / 1254, 1254 / 1254),
    ),
  };

  /// Explicit subject matches to current course units, never a level prefix.
  static const courseSubjects = <String, String>{
    'a1_03_topic_subject_particles': 'a1_counter',
    'a1_06_transport_directions': 'a1_transit',
    'a1_08_clarify_repair': 'a1_repeat',
    'a1_09_home_daily_life': 'a1_home',
    'a1_10_health_safety': 'a1_body',
    'a1_14_payment_delivery': 'a1_counter',
    'a1_16_survival_capstone': 'a2_plan',
    'a2_02_plans_proposals': 'a2_plan',
    'a2_07_travel_repair': 'a2_move',
    'a2_08_home_money': 'a1_home',
    'b1_01_experience_reasons': 'b1_delay',
    'b1_03_work_softening': 'b1_team',
    'b1_04_relationships': 'b1_feel',
    'b1_05_complaint_resolution': 'b1_refund',
    'b1_06_life_capstone': 'a2_apt',
    'b2_03_precise_requests': 'b2_negotiate',
    'b2_05_interview': 'b2_hiring',
    'b2_06_advanced_capstone': 'b2_public',
    'c1_02_inclusive_sustainable_systems': 'c1_policy',
    'c1_03_media_evidence_literacy': 'b2_evidence',
    'c1_04_play_time_policy': 'c1_policy',
    'c1_05_fan_labor_sustainability': 'c1_fandom',
    'c2_01_interpretation_institutions': 'c2_mandate',
  };

  static const packSubjects = <String, String>{
    'a1_sorry_thanks_1': 'a1_body',
    'a1_payment_delivery_1': 'a1_counter',
    'a1_home_daily_1': 'a1_home',
    'a2_home_1': 'a1_home',
    'a1_repair_language_1': 'a1_repeat',
    'a1_transport': 'a1_transit',
    'b1_apt_rules_1': 'a2_apt',
    'a2_restaurant_1': 'a2_booking',
    'a2_transport': 'a2_move',
    'a2_partner_chuseok_basic_1': 'a2_partner',
    'a2_plans_proposals_1': 'a2_plan',
    'b1_travel_change_1': 'b1_delay',
    'b1_emotions_relations_1': 'b1_feel',
    'b1_work_coordination_1': 'b1_team',
    'b2_digital_judgment_1': 'b2_evidence',
    'c1_media_evidence_1': 'b2_evidence',
    'b2_team_negotiation_1': 'b2_negotiate',
    'b2_shared_space_coordination_1': 'b2_public',
    'c1_participation_design_1': 'c1_policy',
    'c1_play_time_policy_1': 'c1_policy',
    'c2_institutional_mediation_1': 'c2_mandate',
    'c1_fan_labor_1': 'c1_fandom',
  };

  // Immutable vocabulary identities from the current bundled CSV. ContentLink
  // identifies a word, not a pack; keep the unit guard and exact word membership.
  static const _linkedSubjects = <_LinkedSubject>[
    _LinkedSubject('a1_13_register_switching', 'a1_body', {
      'vocab_a1_0392',
      'vocab_a1_0393',
      'vocab_a1_0394',
      'vocab_a1_0395',
      'vocab_a1_0396',
      'vocab_a1_0397',
      'vocab_a1_0398',
      'vocab_a1_0399',
      'vocab_a1_0400',
      'vocab_a1_0401',
      'vocab_a1_0402',
      'vocab_a1_0403',
    }),
    _LinkedSubject('a1_14_payment_delivery', 'a1_counter', {
      'vocab_a1_0412',
      'vocab_a1_0413',
      'vocab_a1_0414',
      'vocab_a1_0415',
      'vocab_a1_0452',
      'vocab_a1_0453',
      'vocab_a1_0454',
      'vocab_a1_0455',
      'vocab_a1_0487',
      'vocab_a1_0488',
      'vocab_a1_0489',
      'vocab_a1_0490',
    }),
    _LinkedSubject('a1_09_home_daily_life', 'a1_home', {
      'vocab_b2_0201',
      'vocab_a1_0655',
      'vocab_a1_0656',
      'vocab_a1_0657',
      'vocab_a1_0658',
      'vocab_a1_0659',
      'vocab_a1_0660',
      'vocab_a1_0661',
      'vocab_a1_0662',
      'vocab_a1_0663',
      'vocab_a1_0664',
      'vocab_a1_0665',
      'vocab_a1_0666',
    }),
    _LinkedSubject('a2_08_home_money', 'a1_home', {
      'vocab_a2_0141',
      'vocab_a2_0142',
      'vocab_a2_0143',
      'vocab_a2_0144',
      'vocab_a2_0145',
      'vocab_a2_0146',
      'vocab_a2_0147',
      'vocab_a2_0148',
      'vocab_a2_0150',
      'vocab_a2_0530',
      'vocab_a2_0531',
      'vocab_a2_0532',
    }),
    _LinkedSubject('a1_08_clarify_repair', 'a1_repeat', {
      'vocab_b1_0188',
      'vocab_b1_0190',
      'vocab_b1_0196',
      'vocab_b2_0121',
      'vocab_a1_0408',
      'vocab_a1_0409',
      'vocab_a1_0410',
      'vocab_a1_0411',
      'vocab_a1_0456',
      'vocab_a1_0457',
      'vocab_a1_0458',
      'vocab_a1_0653',
      'vocab_a1_0654',
    }),
    _LinkedSubject('a1_06_transport_directions', 'a1_transit', {
      'vocab_a1_0027',
      'vocab_a1_0028',
      'vocab_a1_0087',
      'vocab_a1_0088',
      'vocab_a1_0445',
      'vocab_a1_0446',
      'vocab_a1_0447',
      'vocab_a1_0448',
      'vocab_a1_0449',
      'vocab_a1_0450',
      'vocab_a1_0451',
      'vocab_a1_0527',
    }),
    _LinkedSubject('b1_06_life_capstone', 'a2_apt', {
      'vocab_a2_0413',
      'vocab_a2_0414',
      'vocab_a2_0415',
      'vocab_a2_0416',
      'vocab_a2_0417',
      'vocab_a2_0418',
      'vocab_a2_0419',
      'vocab_a2_0420',
      'vocab_a2_0421',
      'vocab_a2_0422',
      'vocab_a2_0423',
      'vocab_a2_0424',
    }),
    _LinkedSubject('a2_05_delivery_services', 'a2_booking', {
      'vocab_a2_0185',
      'vocab_a2_0186',
      'vocab_a2_0187',
      'vocab_a2_0188',
      'vocab_a2_0189',
      'vocab_a2_0190',
      'vocab_a2_0191',
      'vocab_a2_0192',
      'vocab_a2_0193',
      'vocab_a2_0194',
      'vocab_a2_0195',
      'vocab_a2_0196',
    }),
    _LinkedSubject('a2_07_travel_repair', 'a2_move', {
      'vocab_a2_0016',
      'vocab_a2_0025',
      'vocab_a2_0026',
      'vocab_a2_0027',
      'vocab_a2_0044',
      'vocab_a2_0056',
      'vocab_a2_0105',
      'vocab_a2_0106',
      'vocab_a2_0107',
      'vocab_a2_0108',
      'vocab_a2_0110',
      'vocab_a2_0558',
    }),
    _LinkedSubject('a2_03_chat_relationships', 'a2_partner', {
      'vocab_a1_0272',
      'vocab_a1_0273',
      'vocab_a1_0274',
      'vocab_a1_0275',
      'vocab_a1_0276',
      'vocab_a1_0277',
      'vocab_a1_0278',
      'vocab_a1_0279',
      'vocab_a1_0280',
      'vocab_a1_0281',
      'vocab_a1_0283',
      'vocab_a2_0553',
    }),
    _LinkedSubject('a2_02_plans_proposals', 'a2_plan', {
      'vocab_a2_0461',
      'vocab_a2_0462',
      'vocab_a2_0463',
      'vocab_a2_0464',
      'vocab_a2_0495',
      'vocab_a2_0496',
      'vocab_a2_0497',
      'vocab_a2_0498',
      'vocab_a2_0499',
      'vocab_a2_0500',
      'vocab_a2_0555',
      'vocab_a2_0556',
    }),
    _LinkedSubject('b1_01_experience_reasons', 'b1_delay', {
      'vocab_a2_0344',
      'vocab_b1_0452',
      'vocab_b1_0453',
      'vocab_b1_0454',
      'vocab_b1_0455',
      'vocab_b1_0456',
      'vocab_b1_0457',
      'vocab_b1_0458',
      'vocab_b1_0459',
      'vocab_b1_0460',
      'vocab_b1_0461',
      'vocab_b1_0462',
      'vocab_b1_0463',
    }),
    _LinkedSubject('b1_04_relationships', 'b1_feel', {
      'vocab_b1_0005',
      'vocab_b1_0006',
      'vocab_b1_0017',
      'vocab_b1_0022',
      'vocab_b1_0023',
      'vocab_b1_0027',
      'vocab_b1_0029',
      'vocab_b1_0032',
      'vocab_b2_0145',
      'vocab_b2_0146',
    }),
    _LinkedSubject('b1_03_work_softening', 'b1_team', {
      'vocab_b1_0260',
      'vocab_b1_0261',
      'vocab_b1_0262',
      'vocab_b1_0263',
      'vocab_b1_0264',
      'vocab_b1_0265',
      'vocab_b1_0266',
      'vocab_b1_0267',
      'vocab_b1_0268',
      'vocab_b1_0269',
      'vocab_b1_0270',
      'vocab_b1_0271',
    }),
    _LinkedSubject('b2_02_professional_opinion', 'b2_evidence', {
      'vocab_b2_0277',
      'vocab_b2_0278',
      'vocab_b2_0279',
      'vocab_b2_0280',
      'vocab_b2_0281',
      'vocab_b2_0282',
      'vocab_b2_0283',
      'vocab_b2_0284',
      'vocab_b2_0285',
      'vocab_b2_0286',
      'vocab_b2_0287',
      'vocab_b2_0288',
    }),
    _LinkedSubject('c1_03_media_evidence_literacy', 'b2_evidence', {
      'vocab_c1_0169',
      'vocab_c1_0170',
      'vocab_c1_0171',
      'vocab_c1_0172',
      'vocab_c1_0173',
      'vocab_c1_0174',
      'vocab_c1_0175',
      'vocab_c1_0176',
      'vocab_c1_0177',
      'vocab_c1_0178',
      'vocab_c1_0179',
      'vocab_c1_0180',
    }),
    _LinkedSubject('b2_03_precise_requests', 'b2_negotiate', {
      'vocab_b2_0575',
      'vocab_b2_0576',
      'vocab_b2_0577',
      'vocab_b2_0578',
      'vocab_b2_0579',
      'vocab_b2_0580',
      'vocab_b2_0581',
      'vocab_b2_0582',
      'vocab_b2_0583',
      'vocab_b2_0584',
      'vocab_b2_0585',
      'vocab_b2_0586',
    }),
    _LinkedSubject('b2_04_complaint_resolution', 'b2_public', {
      'vocab_b2_0289',
      'vocab_b2_0290',
      'vocab_b2_0291',
      'vocab_b2_0292',
      'vocab_b2_0293',
      'vocab_b2_0294',
      'vocab_b2_0295',
      'vocab_b2_0296',
      'vocab_b2_0297',
      'vocab_b2_0298',
      'vocab_b2_0299',
      'vocab_b2_0300',
    }),
    _LinkedSubject('c1_02_inclusive_sustainable_systems', 'c1_policy', {
      'vocab_c1_0133',
      'vocab_c1_0134',
      'vocab_c1_0135',
      'vocab_c1_0136',
      'vocab_c1_0137',
      'vocab_c1_0138',
      'vocab_c1_0139',
      'vocab_c1_0140',
      'vocab_c1_0141',
      'vocab_c1_0142',
      'vocab_c1_0143',
      'vocab_c1_0144',
    }),
    _LinkedSubject('c1_04_play_time_policy', 'c1_policy', {
      'vocab_c1_0181',
      'vocab_c1_0182',
      'vocab_c1_0183',
      'vocab_c1_0184',
      'vocab_c1_0185',
      'vocab_c1_0186',
      'vocab_c1_0187',
      'vocab_c1_0188',
      'vocab_c1_0189',
      'vocab_c1_0190',
      'vocab_c1_0191',
      'vocab_c1_0192',
    }),
    _LinkedSubject('c2_01_interpretation_institutions', 'c2_mandate', {
      'vocab_c2_0001',
      'vocab_c2_0002',
      'vocab_c2_0003',
      'vocab_c2_0004',
      'vocab_c2_0005',
      'vocab_c2_0006',
      'vocab_c2_0007',
      'vocab_c2_0008',
      'vocab_c2_0009',
      'vocab_c2_0010',
      'vocab_c2_0011',
      'vocab_c2_0012',
    }),
    _LinkedSubject('c1_05_fan_labor_sustainability', 'c1_fandom', {
      'vocab_c1_0193',
      'vocab_c1_0194',
      'vocab_c1_0195',
      'vocab_c1_0196',
      'vocab_c1_0197',
      'vocab_c1_0198',
      'vocab_c1_0199',
      'vocab_c1_0200',
      'vocab_c1_0201',
      'vocab_c1_0202',
      'vocab_c1_0203',
      'vocab_c1_0204',
    }),
  ];

  /// A supplied link must belong to this unit. A reviewed active vocabulary
  /// pack gets its own subject; build/scene phases retain the unit subject.
  /// Unknown units and packs deliberately have no invented topic coverage.
  static TodaySubjectImage? topicForPick(
    MissionPick? pick, {
    ContentLink? link,
  }) {
    if (pick is PackPick) {
      return subjectImages[packSubjects[pick.pack.id]];
    }
    if (pick is! CoursePick) return null;
    if (link != null) {
      if (link.courseUnitId != pick.unit.id) return null;
      if (link.contentKind == CurriculumContentKind.vocab) {
        for (final subject in _linkedSubjects) {
          if (subject.unitId == pick.unit.id &&
              subject.vocabularyIds.contains(link.contentId)) {
            return subjectImages[subject.subject];
          }
        }
      }
    }
    return subjectImages[courseSubjects[pick.unit.id]];
  }

  static Widget forPick(MissionPick? pick, {ContentLink? link}) {
    final selected = topicForPick(pick, link: link);
    if (selected != null) {
      return CAtlasArt(
        path: selected.path,
        region: selected.region,
        fit: BoxFit.contain,
      );
    }

    final region = switch (pick) {
      HangulIntroPick() => const Rect.fromLTRB(0, .58, .5, 1),
      ReviewPick() => const Rect.fromLTRB(.5, .08, 1, .5),
      CoursePick(:final unit) when unit.id == 'a1_01_greetings_hangul' =>
        const Rect.fromLTRB(0, .08, .5, .5),
      _ => null,
    };
    return region == null
        ? const CReferenceArt(CReferencePart.book)
        : CAtlasArt(path: environments, region: region, fit: BoxFit.contain);
  }
}

/// Normalized native source region; source files remain byte-identical.
class TodaySubjectImage {
  const TodaySubjectImage(this.path, this.region);
  final String path;
  final Rect region;
}

class _LinkedSubject {
  const _LinkedSubject(this.unitId, this.subject, this.vocabularyIds);
  final String unitId;
  final String subject;
  final Set<String> vocabularyIds;
}
