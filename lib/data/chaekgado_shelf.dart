import '../l10n/generated/app_localizations.dart';
import '../models/learner_level.dart';

/// 책가도 서재 — 레벨당 15칸의 정본 (기능 9 + 기능확장 3 + 관심 3).
///
/// **`tools/content_factory/shelf_assignment.py` 의 `SHELF_SLUGS` 을 그대로
/// 옮긴 것이다** — slug 철자·순서 전부 동일. 그 파일이 `Scenario.shelf` 필드
/// (`{level}_{slug}`, 264개 전수 태깅)의 정본이므로, 여기서 철자가 어긋나면
/// 칸이 조용히 빈다. 파이썬 쪽이 바뀌면 이 파일도 손으로 맞춰야 한다.
///
/// `imageKey` 는 `docs/LISTENING_CARD_ART_SPEC.md` 의 PascalCase 키
/// (`A1Transit` 등) — 두 표는 슬러그 순서가 1:1 이라(직접 대조 확인) 위치로
/// 짝지었다. 기존 50장 번들 카드가 이 매핑 그대로 재사용된다.
class ChaekgadoSlot {
  const ChaekgadoSlot(this.slug, this.imageKey);

  final String slug;
  final String imageKey;
}

const Map<LearnerLevel, List<ChaekgadoSlot>> kChaekgadoSlots = {
  LearnerLevel.a1: [
    ChaekgadoSlot('transit', 'A1Transit'),
    ChaekgadoSlot('taxi_stay', 'A1Arrival'),
    ChaekgadoSlot('counter', 'A1Counter'),
    ChaekgadoSlot('eat', 'A1Cafe'),
    ChaekgadoSlot('home', 'A1Home'),
    ChaekgadoSlot('greet', 'A1Greeting'),
    ChaekgadoSlot('repeat', 'A1Repair'),
    ChaekgadoSlot('body', 'A1Health'),
    ChaekgadoSlot('partner', 'A1Family'),
    ChaekgadoSlot('numbers', 'A1Numbers'),
    ChaekgadoSlot('phone', 'A1Phone'),
    ChaekgadoSlot('wayfinding', 'A1Wayfinding'),
    // 관심 3칸 — 레벨 공용 아트 3장(Social*)을 6레벨이 나눠 쓴다.
    // shelf_assignment.INTEREST_SLUGS 와 순서·철자 동일.
    ChaekgadoSlot('friends', 'SocialFriends'),
    ChaekgadoSlot('dating', 'SocialDating'),
    ChaekgadoSlot('fandom', 'SocialFandom'),
  ],
  LearnerLevel.a2: [
    ChaekgadoSlot('move', 'A2Travel'),
    ChaekgadoSlot('money', 'A2Bank'),
    ChaekgadoSlot('buy', 'A2Shopping'),
    ChaekgadoSlot('eat', 'A2Cafe'),
    ChaekgadoSlot('body', 'A2Body'),
    ChaekgadoSlot('apt', 'A2Neighbourhood'),
    ChaekgadoSlot('work', 'A2Work'),
    ChaekgadoSlot('plan', 'A2Plans'),
    ChaekgadoSlot('partner', 'A2Family'),
    ChaekgadoSlot('delivery', 'A2Delivery'),
    ChaekgadoSlot('enrolment', 'A2Enrolment'),
    ChaekgadoSlot('booking', 'A2Booking'),
    // 관심 3칸 — 레벨 공용 아트 3장(Social*)을 6레벨이 나눠 쓴다.
    // shelf_assignment.INTEREST_SLUGS 와 순서·철자 동일.
    ChaekgadoSlot('friends', 'SocialFriends'),
    ChaekgadoSlot('dating', 'SocialDating'),
    ChaekgadoSlot('fandom', 'SocialFandom'),
  ],
  LearnerLevel.b1: [
    ChaekgadoSlot('repair', 'B1Repairs'),
    ChaekgadoSlot('refund', 'B1Refund'),
    ChaekgadoSlot('bill', 'B1Receipts'),
    ChaekgadoSlot('delay', 'B1Delay'),
    ChaekgadoSlot('form', 'B1Paperwork'),
    ChaekgadoSlot('team', 'B1Team'),
    ChaekgadoSlot('neighbor', 'B1Neighbours'),
    ChaekgadoSlot('feel', 'B1Feelings'),
    ChaekgadoSlot('partner', 'B1Family'),
    ChaekgadoSlot('insurance', 'B1Insurance'),
    ChaekgadoSlot('incident', 'B1Incident'),
    ChaekgadoSlot('cancellation', 'B1Cancellation'),
    // 관심 3칸 — 레벨 공용 아트 3장(Social*)을 6레벨이 나눠 쓴다.
    // shelf_assignment.INTEREST_SLUGS 와 순서·철자 동일.
    ChaekgadoSlot('friends', 'SocialFriends'),
    ChaekgadoSlot('dating', 'SocialDating'),
    ChaekgadoSlot('fandom', 'SocialFandom'),
  ],
  LearnerLevel.b2: [
    ChaekgadoSlot('meeting', 'B2Meetings'),
    ChaekgadoSlot('evidence', 'B2Evidence'),
    ChaekgadoSlot('negotiate', 'B2Negotiation'),
    ChaekgadoSlot('contract', 'B2Contracts'),
    ChaekgadoSlot('notice', 'B2Notices'),
    ChaekgadoSlot('travel', 'B2Escalation'),
    ChaekgadoSlot('health', 'B2Medical'),
    ChaekgadoSlot('public', 'B2Public'),
    ChaekgadoSlot('partner', 'B2Family'),
    ChaekgadoSlot('hiring', 'B2Hiring'),
    ChaekgadoSlot('authorities', 'B2Authorities'),
    ChaekgadoSlot('privacy', 'B2Privacy'),
    // 관심 3칸 — 레벨 공용 아트 3장(Social*)을 6레벨이 나눠 쓴다.
    // shelf_assignment.INTEREST_SLUGS 와 순서·철자 동일.
    ChaekgadoSlot('friends', 'SocialFriends'),
    ChaekgadoSlot('dating', 'SocialDating'),
    ChaekgadoSlot('fandom', 'SocialFandom'),
  ],
  // C1/C2 — 재고는 12칸 중 4~6칸뿐이다(2026-08-18 기준). 나머지는 카드 아트
  // 없이 소품만 놓고 출시한다(ChaekgadoShelfCase 의 count==0 처리) — 24칸을
  // 전부 채워야 했던 옛 카드 그리드안과 달리, 이 결정 덕에 신규 아트 0장으로
  // 간다. 콘텐츠가 늘면 그때 해당 칸만 카드를 뽑는다.
  LearnerLevel.c1: [
    ChaekgadoSlot('briefing', 'C1Briefing'),
    ChaekgadoSlot('uncertainty', 'C1Uncertainty'),
    ChaekgadoSlot('access', 'C1Access'),
    ChaekgadoSlot('labor', 'C1InvisibleLabor'),
    ChaekgadoSlot('conflict_interest', 'C1Conflict'),
    ChaekgadoSlot('policy', 'C1Policy'),
    ChaekgadoSlot('clinical', 'C1Consent'),
    ChaekgadoSlot('critique', 'C1Critique'),
    ChaekgadoSlot('mediation', 'C1Mediation'),
    ChaekgadoSlot('methodology', 'C1Methodology'),
    ChaekgadoSlot('facework', 'C1Facework'),
    ChaekgadoSlot('attribution', 'C1Attribution'),
    // 관심 3칸 — 레벨 공용 아트 3장(Social*)을 6레벨이 나눠 쓴다.
    // shelf_assignment.INTEREST_SLUGS 와 순서·철자 동일.
    ChaekgadoSlot('friends', 'SocialFriends'),
    ChaekgadoSlot('dating', 'SocialDating'),
    ChaekgadoSlot('fandom', 'SocialFandom'),
  ],
  LearnerLevel.c2: [
    ChaekgadoSlot('automation', 'C2Automation'),
    ChaekgadoSlot('record', 'C2Records'),
    ChaekgadoSlot('discourse', 'C2Discourse'),
    ChaekgadoSlot('mandate', 'C2Authority'),
    ChaekgadoSlot('impact', 'C2Impact'),
    ChaekgadoSlot('memory', 'C2Memory'),
    ChaekgadoSlot('ethics', 'C2Ethics'),
    ChaekgadoSlot('history', 'C2History'),
    ChaekgadoSlot('aesthetic', 'C2Translation'),
    ChaekgadoSlot('limitation', 'C2Limitation'),
    ChaekgadoSlot('jurisdiction', 'C2Jurisdiction'),
    ChaekgadoSlot('representation', 'C2Representation'),
    // 관심 3칸 — 레벨 공용 아트 3장(Social*)을 6레벨이 나눠 쓴다.
    // shelf_assignment.INTEREST_SLUGS 와 순서·철자 동일.
    ChaekgadoSlot('friends', 'SocialFriends'),
    ChaekgadoSlot('dating', 'SocialDating'),
    ChaekgadoSlot('fandom', 'SocialFandom'),
  ],
};

/// `Scenario.shelf` 와 정확히 같은 문자열을 만든다 (`{level}_{slug}`).
String chaekgadoShelfId(LearnerLevel level, String slug) =>
    '${level.code}_$slug';

/// 칸 이름표 — ARB 가 정본, 여기는 `imageKey` → getter 매핑만 한다.
/// 표시명 원문은 `docs/LISTENING_CARD_ART_SPEC.md` 의 "표시명 (DE)" 열.
String chaekgadoSlotLabel(AppL10n t, String imageKey) => switch (imageKey) {
  'A1Transit' => t.listeningShelfA1Transit,
  'A1Arrival' => t.listeningShelfA1Arrival,
  'A1Counter' => t.listeningShelfA1Counter,
  'A1Cafe' => t.listeningShelfA1Cafe,
  'A1Home' => t.listeningShelfA1Home,
  'A1Greeting' => t.listeningShelfA1Greeting,
  'A1Repair' => t.listeningShelfA1Repair,
  'A1Health' => t.listeningShelfA1Health,
  'A1Family' => t.listeningShelfA1Family,
  'A1Numbers' => t.listeningShelfA1Numbers,
  'A1Phone' => t.listeningShelfA1Phone,
  'A1Wayfinding' => t.listeningShelfA1Wayfinding,
  'A2Travel' => t.listeningShelfA2Travel,
  'A2Bank' => t.listeningShelfA2Bank,
  'A2Shopping' => t.listeningShelfA2Shopping,
  'A2Cafe' => t.listeningShelfA2Cafe,
  'A2Body' => t.listeningShelfA2Body,
  'A2Neighbourhood' => t.listeningShelfA2Neighbourhood,
  'A2Work' => t.listeningShelfA2Work,
  'A2Plans' => t.listeningShelfA2Plans,
  'A2Family' => t.listeningShelfA2Family,
  'A2Delivery' => t.listeningShelfA2Delivery,
  'A2Enrolment' => t.listeningShelfA2Enrolment,
  'A2Booking' => t.listeningShelfA2Booking,
  'B1Repairs' => t.listeningShelfB1Repairs,
  'B1Refund' => t.listeningShelfB1Refund,
  'B1Receipts' => t.listeningShelfB1Receipts,
  'B1Delay' => t.listeningShelfB1Delay,
  'B1Paperwork' => t.listeningShelfB1Paperwork,
  'B1Team' => t.listeningShelfB1Team,
  'B1Neighbours' => t.listeningShelfB1Neighbours,
  'B1Feelings' => t.listeningShelfB1Feelings,
  'B1Family' => t.listeningShelfB1Family,
  'B1Insurance' => t.listeningShelfB1Insurance,
  'B1Incident' => t.listeningShelfB1Incident,
  'B1Cancellation' => t.listeningShelfB1Cancellation,
  'B2Meetings' => t.listeningShelfB2Meetings,
  'B2Evidence' => t.listeningShelfB2Evidence,
  'B2Negotiation' => t.listeningShelfB2Negotiation,
  'B2Contracts' => t.listeningShelfB2Contracts,
  'B2Notices' => t.listeningShelfB2Notices,
  'B2Escalation' => t.listeningShelfB2Escalation,
  'B2Medical' => t.listeningShelfB2Medical,
  'B2Public' => t.listeningShelfB2Public,
  'B2Family' => t.listeningShelfB2Family,
  'B2Hiring' => t.listeningShelfB2Hiring,
  'B2Authorities' => t.listeningShelfB2Authorities,
  'B2Privacy' => t.listeningShelfB2Privacy,
  'C1Briefing' => t.listeningShelfC1Briefing,
  'C1Uncertainty' => t.listeningShelfC1Uncertainty,
  'C1Access' => t.listeningShelfC1Access,
  'C1InvisibleLabor' => t.listeningShelfC1InvisibleLabor,
  'C1Conflict' => t.listeningShelfC1Conflict,
  'C1Policy' => t.listeningShelfC1Policy,
  'C1Consent' => t.listeningShelfC1Consent,
  'C1Critique' => t.listeningShelfC1Critique,
  'C1Mediation' => t.listeningShelfC1Mediation,
  'C1Methodology' => t.listeningShelfC1Methodology,
  'C1Facework' => t.listeningShelfC1Facework,
  'C1Attribution' => t.listeningShelfC1Attribution,
  'C2Automation' => t.listeningShelfC2Automation,
  'C2Records' => t.listeningShelfC2Records,
  'C2Discourse' => t.listeningShelfC2Discourse,
  'C2Authority' => t.listeningShelfC2Authority,
  'C2Impact' => t.listeningShelfC2Impact,
  'C2Memory' => t.listeningShelfC2Memory,
  'C2Ethics' => t.listeningShelfC2Ethics,
  'C2History' => t.listeningShelfC2History,
  'C2Translation' => t.listeningShelfC2Translation,
  'C2Limitation' => t.listeningShelfC2Limitation,
  'C2Jurisdiction' => t.listeningShelfC2Jurisdiction,
  'C2Representation' => t.listeningShelfC2Representation,
  'SocialFriends' => t.listeningShelfSocialFriends,
  'SocialDating' => t.listeningShelfSocialDating,
  'SocialFandom' => t.listeningShelfSocialFandom,
  _ => imageKey,
};
