import 'package:flutter/material.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';

class ListeningObjectSpec {
  const ListeningObjectSpec(this.file, this.bounds);
  final String file;
  final Rect bounds;
}

/// Byte-identical approved independent objects; bounds remove transparent space only.
const listeningObjects = <String, ListeningObjectSpec>{
  'c1_briefing': ListeningObjectSpec(
    '01-c1-briefing.png',
    Rect.fromLTWH(48.0, 92.0, 1168.0, 1096.0),
  ),
  'c1_uncertainty': ListeningObjectSpec(
    '02-c1-uncertainty.png',
    Rect.fromLTWH(29.0, 223.0, 1195.0, 902.0),
  ),
  'c1_methodology': ListeningObjectSpec(
    '03-c1-methodology.png',
    Rect.fromLTWH(38.0, 164.0, 1187.0, 917.0),
  ),
  'c1_critique': ListeningObjectSpec(
    '04-c1-critique.png',
    Rect.fromLTWH(41.0, 139.0, 1192.0, 944.0),
  ),
  'c1_attribution': ListeningObjectSpec(
    '05-c1-attribution.png',
    Rect.fromLTWH(20.0, 119.0, 1194.0, 1096.0),
  ),
  'c2_automation': ListeningObjectSpec(
    '06-c2-automation.png',
    Rect.fromLTWH(34.0, 150.0, 1203.0, 1002.0),
  ),
  'c2_record': ListeningObjectSpec(
    '07-c2-record.png',
    Rect.fromLTWH(54.0, 278.0, 1175.0, 729.0),
  ),
  'c2_discourse': ListeningObjectSpec(
    '08-c2-discourse.png',
    Rect.fromLTWH(18.0, 165.0, 1218.0, 1020.0),
  ),
  'c2_memory': ListeningObjectSpec(
    '09-c2-memory.png',
    Rect.fromLTWH(71.0, 244.0, 1133.0, 936.0),
  ),
  'c2_ethics': ListeningObjectSpec(
    '10-c2-ethics.png',
    Rect.fromLTWH(46.0, 178.0, 1181.0, 913.0),
  ),
  'a1_eat': ListeningObjectSpec(
    '11-a1-cafe.png',
    Rect.fromLTWH(19.0, 287.0, 1220.0, 857.0),
  ),
  'a1_taxi_stay': ListeningObjectSpec(
    '12-a1-arrival.png',
    Rect.fromLTWH(19.0, 65.0, 1218.0, 1169.0),
  ),
  'a1_greet': ListeningObjectSpec(
    '13-a1-greeting.png',
    Rect.fromLTWH(26.0, 169.0, 1214.0, 968.0),
  ),
  'a1_phone': ListeningObjectSpec(
    '14-a1-phone.png',
    Rect.fromLTWH(67.0, 86.0, 1123.0, 1139.0),
  ),
  'a1_partner': ListeningObjectSpec(
    '15-a1-family.png',
    Rect.fromLTWH(62.0, 200.0, 1147.0, 927.0),
  ),
  'a2_delivery': ListeningObjectSpec(
    '16-a2-delivery.png',
    Rect.fromLTWH(37.0, 66.0, 1188.0, 1155.0),
  ),
  'a2_eat': ListeningObjectSpec(
    '17-a2-restaurant.png',
    Rect.fromLTWH(22.0, 260.0, 1221.0, 885.0),
  ),
  'a2_buy': ListeningObjectSpec(
    '18-a2-shopping.png',
    Rect.fromLTWH(45.0, 218.0, 1190.0, 967.0),
  ),
  'a2_body': ListeningObjectSpec(
    '19-a2-health.png',
    Rect.fromLTWH(41.0, 98.0, 1173.0, 1124.0),
  ),
  'a2_work': ListeningObjectSpec(
    '20-a2-work.png',
    Rect.fromLTWH(29.0, 135.0, 1208.0, 1023.0),
  ),
  'a1_body': ListeningObjectSpec(
    'a1_body.png',
    Rect.fromLTWH(16.0, 28.0, 1222.0, 1226.0),
  ),
  'a1_counter': ListeningObjectSpec(
    'a1_counter.png',
    Rect.fromLTWH(0.0, 19.0, 1236.0, 1235.0),
  ),
  'a1_home': ListeningObjectSpec(
    'a1_home.png',
    Rect.fromLTWH(0.0, 27.0, 1198.0, 1213.0),
  ),
  'a1_numbers': ListeningObjectSpec(
    'a1_numbers.png',
    Rect.fromLTWH(0.0, 47.0, 1228.0, 1207.0),
  ),
  'a1_repeat': ListeningObjectSpec(
    'a1_repeat.png',
    Rect.fromLTWH(0.0, 36.0, 1244.0, 1218.0),
  ),
  'a1_transit': ListeningObjectSpec(
    'a1_transit.png',
    Rect.fromLTWH(0.0, 39.0, 1240.0, 1215.0),
  ),
  'a1_wayfinding': ListeningObjectSpec(
    'a1_wayfinding.png',
    Rect.fromLTWH(0.0, 41.0, 1234.0, 1213.0),
  ),
  'a2_apt': ListeningObjectSpec(
    'a2_apt.png',
    Rect.fromLTWH(0.0, 49.0, 1225.0, 1205.0),
  ),
  'a2_booking': ListeningObjectSpec(
    'a2_booking.png',
    Rect.fromLTWH(0.0, 31.0, 1238.0, 1223.0),
  ),
  'a2_enrolment': ListeningObjectSpec(
    'a2_enrolment.png',
    Rect.fromLTWH(0.0, 35.0, 1238.0, 1219.0),
  ),
  'a2_money': ListeningObjectSpec(
    'a2_money.png',
    Rect.fromLTWH(0.0, 109.0, 1232.0, 1145.0),
  ),
  'a2_move': ListeningObjectSpec(
    'a2_move.png',
    Rect.fromLTWH(0.0, 67.0, 1222.0, 1187.0),
  ),
  'a2_partner': ListeningObjectSpec(
    'a2_partner.png',
    Rect.fromLTWH(0.0, 21.0, 1232.0, 1233.0),
  ),
  'a2_plan': ListeningObjectSpec(
    'a2_plan.png',
    Rect.fromLTWH(0.0, 31.0, 1242.0, 1223.0),
  ),
  'b1_bill': ListeningObjectSpec(
    'b1_bill.png',
    Rect.fromLTWH(0.0, 7.0, 1251.0, 1247.0),
  ),
  'b1_cancellation': ListeningObjectSpec(
    'b1_cancellation.png',
    Rect.fromLTWH(0.0, 33.0, 1240.0, 1221.0),
  ),
  'b1_delay': ListeningObjectSpec(
    'b1_delay.png',
    Rect.fromLTWH(40.0, 84.0, 1180.0, 1170.0),
  ),
  'b1_feel': ListeningObjectSpec(
    'b1_feel.png',
    Rect.fromLTWH(0.0, 64.0, 1234.0, 1190.0),
  ),
  'b1_form': ListeningObjectSpec(
    'b1_form.png',
    Rect.fromLTWH(0.0, 9.0, 1236.0, 1245.0),
  ),
  'b1_incident': ListeningObjectSpec(
    'b1_incident.png',
    Rect.fromLTWH(0.0, 86.0, 1242.0, 1168.0),
  ),
  'b1_insurance': ListeningObjectSpec(
    'b1_insurance.png',
    Rect.fromLTWH(16.0, 39.0, 1223.0, 1215.0),
  ),
  'b1_neighbor': ListeningObjectSpec(
    'b1_neighbor.png',
    Rect.fromLTWH(0.0, 20.0, 1230.0, 1234.0),
  ),
  'b1_partner': ListeningObjectSpec(
    'b1_partner.png',
    Rect.fromLTWH(0.0, 0.0, 1240.0, 1254.0),
  ),
  'b1_refund': ListeningObjectSpec(
    'b1_refund.png',
    Rect.fromLTWH(0.0, 7.0, 1220.0, 1247.0),
  ),
  'b1_repair': ListeningObjectSpec(
    'b1_repair.png',
    Rect.fromLTWH(0.0, 95.0, 1208.0, 1141.0),
  ),
  'b1_team': ListeningObjectSpec(
    'b1_team.png',
    Rect.fromLTWH(24.0, 26.0, 1229.0, 1228.0),
  ),
  'b2_authorities': ListeningObjectSpec(
    'b2_authorities.png',
    Rect.fromLTWH(0.0, 94.0, 1237.0, 1160.0),
  ),
  'b2_contract': ListeningObjectSpec(
    'b2_contract.png',
    Rect.fromLTWH(0.0, 39.0, 1235.0, 1168.0),
  ),
  'b2_evidence': ListeningObjectSpec(
    'b2_evidence.png',
    Rect.fromLTWH(0.0, 80.0, 1218.0, 1174.0),
  ),
  'b2_health': ListeningObjectSpec(
    'b2_health.png',
    Rect.fromLTWH(0.0, 0.0, 1239.0, 1254.0),
  ),
  'b2_hiring': ListeningObjectSpec(
    'b2_hiring.png',
    Rect.fromLTWH(0.0, 0.0, 1236.0, 1254.0),
  ),
  'b2_meeting': ListeningObjectSpec(
    'b2_meeting.png',
    Rect.fromLTWH(0.0, 93.0, 1240.0, 1161.0),
  ),
  'b2_negotiate': ListeningObjectSpec(
    'b2_negotiate.png',
    Rect.fromLTWH(0.0, 19.0, 1240.0, 1235.0),
  ),
  'b2_notice': ListeningObjectSpec(
    'b2_notice.png',
    Rect.fromLTWH(0.0, 17.0, 1234.0, 1237.0),
  ),
  'b2_partner': ListeningObjectSpec(
    'b2_partner.png',
    Rect.fromLTWH(0.0, 130.0, 1223.0, 1124.0),
  ),
  'b2_privacy': ListeningObjectSpec(
    'b2_privacy.png',
    Rect.fromLTWH(0.0, 37.0, 1218.0, 1217.0),
  ),
  'b2_public': ListeningObjectSpec(
    'b2_public.png',
    Rect.fromLTWH(0.0, 17.0, 1234.0, 1237.0),
  ),
  'b2_travel': ListeningObjectSpec(
    'b2_travel.png',
    Rect.fromLTWH(0.0, 105.0, 1240.0, 1149.0),
  ),
  'c1_access': ListeningObjectSpec(
    'c1_access.png',
    Rect.fromLTWH(0.0, 23.0, 1240.0, 1231.0),
  ),
  'c1_clinical': ListeningObjectSpec(
    'c1_clinical.png',
    Rect.fromLTWH(0.0, 37.0, 1230.0, 1217.0),
  ),
  'c1_conflict_interest': ListeningObjectSpec(
    'c1_conflict_interest.png',
    Rect.fromLTWH(0.0, 0.0, 1237.0, 1220.0),
  ),
  'c1_facework': ListeningObjectSpec(
    'c1_facework.png',
    Rect.fromLTWH(0.0, 0.0, 1238.0, 1254.0),
  ),
  'c1_labor': ListeningObjectSpec(
    'c1_labor.png',
    Rect.fromLTWH(0.0, 25.0, 1222.0, 1229.0),
  ),
  'c1_mediation': ListeningObjectSpec(
    'c1_mediation.png',
    Rect.fromLTWH(0.0, 23.0, 1239.0, 1231.0),
  ),
  'c1_policy': ListeningObjectSpec(
    'c1_policy.png',
    Rect.fromLTWH(0.0, 37.0, 1230.0, 1217.0),
  ),
  'c2_aesthetic': ListeningObjectSpec(
    'c2_aesthetic.png',
    Rect.fromLTWH(16.0, 167.0, 1224.0, 1087.0),
  ),
  'c2_history': ListeningObjectSpec(
    'c2_history.png',
    Rect.fromLTWH(28.0, 32.0, 1204.0, 1222.0),
  ),
  'c2_impact': ListeningObjectSpec(
    'c2_impact.png',
    Rect.fromLTWH(0.0, 39.0, 1254.0, 1215.0),
  ),
  'c2_jurisdiction': ListeningObjectSpec(
    'c2_jurisdiction.png',
    Rect.fromLTWH(0.0, 37.0, 1237.0, 1217.0),
  ),
  'c2_limitation': ListeningObjectSpec(
    'c2_limitation.png',
    Rect.fromLTWH(0.0, 19.0, 1237.0, 1235.0),
  ),
  'c2_mandate': ListeningObjectSpec(
    'c2_mandate.png',
    Rect.fromLTWH(0.0, 0.0, 1244.0, 1254.0),
  ),
  'c2_representation': ListeningObjectSpec(
    'c2_representation.png',
    Rect.fromLTWH(0.0, 0.0, 1251.0, 1254.0),
  ),
  'a1_dating': ListeningObjectSpec(
    'social_dating.png',
    Rect.fromLTWH(0.0, 19.0, 1214.0, 1235.0),
  ),
  'a2_dating': ListeningObjectSpec(
    'social_dating.png',
    Rect.fromLTWH(0.0, 19.0, 1214.0, 1235.0),
  ),
  'b1_dating': ListeningObjectSpec(
    'social_dating.png',
    Rect.fromLTWH(0.0, 19.0, 1214.0, 1235.0),
  ),
  'b2_dating': ListeningObjectSpec(
    'social_dating.png',
    Rect.fromLTWH(0.0, 19.0, 1214.0, 1235.0),
  ),
  'c1_dating': ListeningObjectSpec(
    'social_dating.png',
    Rect.fromLTWH(0.0, 19.0, 1214.0, 1235.0),
  ),
  'c2_dating': ListeningObjectSpec(
    'social_dating.png',
    Rect.fromLTWH(0.0, 19.0, 1214.0, 1235.0),
  ),
  'a1_fandom': ListeningObjectSpec(
    'social_fandom.png',
    Rect.fromLTWH(40.0, 25.0, 1194.0, 1229.0),
  ),
  'a2_fandom': ListeningObjectSpec(
    'social_fandom.png',
    Rect.fromLTWH(40.0, 25.0, 1194.0, 1229.0),
  ),
  'b1_fandom': ListeningObjectSpec(
    'social_fandom.png',
    Rect.fromLTWH(40.0, 25.0, 1194.0, 1229.0),
  ),
  'b2_fandom': ListeningObjectSpec(
    'social_fandom.png',
    Rect.fromLTWH(40.0, 25.0, 1194.0, 1229.0),
  ),
  'c1_fandom': ListeningObjectSpec(
    'social_fandom.png',
    Rect.fromLTWH(40.0, 25.0, 1194.0, 1229.0),
  ),
  'c2_fandom': ListeningObjectSpec(
    'social_fandom.png',
    Rect.fromLTWH(40.0, 25.0, 1194.0, 1229.0),
  ),
  'a1_friends': ListeningObjectSpec(
    'social_friends.png',
    Rect.fromLTWH(0.0, 61.0, 1238.0, 1193.0),
  ),
  'a2_friends': ListeningObjectSpec(
    'social_friends.png',
    Rect.fromLTWH(0.0, 61.0, 1238.0, 1193.0),
  ),
  'b1_friends': ListeningObjectSpec(
    'social_friends.png',
    Rect.fromLTWH(0.0, 61.0, 1238.0, 1193.0),
  ),
  'b2_friends': ListeningObjectSpec(
    'social_friends.png',
    Rect.fromLTWH(0.0, 61.0, 1238.0, 1193.0),
  ),
  'c1_friends': ListeningObjectSpec(
    'social_friends.png',
    Rect.fromLTWH(0.0, 61.0, 1238.0, 1193.0),
  ),
  'c2_friends': ListeningObjectSpec(
    'social_friends.png',
    Rect.fromLTWH(0.0, 61.0, 1238.0, 1193.0),
  ),
};

class ListeningObjectArt extends StatelessWidget {
  const ListeningObjectArt(this.topicId, {super.key});
  final String topicId;
  @override
  Widget build(BuildContext context) {
    final spec = listeningObjects[topicId];
    if (spec == null) {
      return const CReferenceArt(CReferencePart.listening);
    }
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fitted = applyBoxFit(
            BoxFit.contain,
            spec.bounds.size,
            constraints.biggest,
          );
          final scale = fitted.destination.width / spec.bounds.width;
          return Center(
            child: SizedBox.fromSize(
              size: fitted.destination,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -spec.bounds.left * scale,
                    top: -spec.bounds.top * scale,
                    width: 1254 * scale,
                    height: 1254 * scale,
                    child: Image.asset(
                      'assets/illustrations/c_listening/${spec.file}',
                      cacheWidth: 512,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) =>
                          const CReferenceArt(CReferencePart.listening),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
