/// Runtime identity used by canonical scenario dialogue.
///
/// The full writer bible lives in
/// `tools/content_factory/canonical_scenarios/character_profiles.json`.  The
/// app intentionally carries only the stable display-name and TTS contract.
/// A contract test keeps these values in sync with the writer bible.
class ScenarioCharacterProfile {
  const ScenarioCharacterProfile({
    required this.id,
    required this.nameKo,
    required this.nameDe,
    required this.nameEn,
    required this.voice,
  });

  final String id;
  final String nameKo;
  final String nameDe;
  final String nameEn;
  final String voice;

  String nameFor(String languageCode) => switch (languageCode) {
    'de' => nameDe,
    'en' => nameEn,
    _ => nameKo,
  };
}

abstract final class ScenarioCharacterCatalog {
  static const Map<String, ScenarioCharacterProfile> profiles = {
    'christian': ScenarioCharacterProfile(
      id: 'christian',
      nameKo: '크리스티안',
      nameDe: 'Christian',
      nameEn: 'Christian',
      voice: 'male',
    ),
    'sujin': ScenarioCharacterProfile(
      id: 'sujin',
      nameKo: '수진',
      nameDe: 'Sujin',
      nameEn: 'Sujin',
      voice: 'female',
    ),
    'maya': ScenarioCharacterProfile(
      id: 'maya',
      nameKo: '마야',
      nameDe: 'Maya',
      nameEn: 'Maya',
      voice: 'female',
    ),
    'hyuna': ScenarioCharacterProfile(
      id: 'hyuna',
      nameKo: '현아',
      nameDe: 'Hyuna',
      nameEn: 'Hyuna',
      voice: 'female',
    ),
    'andrea': ScenarioCharacterProfile(
      id: 'andrea',
      nameKo: '안드레아',
      nameDe: 'Andrea',
      nameEn: 'Andrea',
      voice: 'female',
    ),
    'lena': ScenarioCharacterProfile(
      id: 'lena',
      nameKo: '레나',
      nameDe: 'Lena',
      nameEn: 'Lena',
      voice: 'female',
    ),
    'daniel': ScenarioCharacterProfile(
      id: 'daniel',
      nameKo: '다니엘',
      nameDe: 'Daniel',
      nameEn: 'Daniel',
      voice: 'male',
    ),
    'clerk': ScenarioCharacterProfile(
      id: 'clerk',
      nameKo: '직원',
      nameDe: 'Mitarbeiterin',
      nameEn: 'Staff member',
      voice: 'female',
    ),
    'instructor': ScenarioCharacterProfile(
      id: 'instructor',
      nameKo: '강사',
      nameDe: 'Kursleiterin',
      nameEn: 'Instructor',
      voice: 'female',
    ),
    'customer': ScenarioCharacterProfile(
      id: 'customer',
      nameKo: '손님',
      nameDe: 'Kunde',
      nameEn: 'Customer',
      voice: 'male',
    ),
    'driver': ScenarioCharacterProfile(
      id: 'driver',
      nameKo: '기사',
      nameDe: 'Fahrer',
      nameEn: 'Driver',
      voice: 'male',
    ),
    'coworker': ScenarioCharacterProfile(
      id: 'coworker',
      nameKo: '동료',
      nameDe: 'Kollegin',
      nameEn: 'Coworker',
      voice: 'female',
    ),
    'manager': ScenarioCharacterProfile(
      id: 'manager',
      nameKo: '팀장',
      nameDe: 'Teamleiter',
      nameEn: 'Team lead',
      voice: 'male',
    ),
    'professor': ScenarioCharacterProfile(
      id: 'professor',
      nameKo: '교수',
      nameDe: 'Professorin',
      nameEn: 'Professor',
      voice: 'female',
    ),
    'neighbor': ScenarioCharacterProfile(
      id: 'neighbor',
      nameKo: '이웃',
      nameDe: 'Nachbar',
      nameEn: 'Neighbor',
      voice: 'male',
    ),
    'pharmacist': ScenarioCharacterProfile(
      id: 'pharmacist',
      nameKo: '약사',
      nameDe: 'Apothekerin',
      nameEn: 'Pharmacist',
      voice: 'female',
    ),
    'server': ScenarioCharacterProfile(
      id: 'server',
      nameKo: '식당 직원',
      nameDe: 'Servicekraft',
      nameEn: 'Server',
      voice: 'male',
    ),
    'landlord': ScenarioCharacterProfile(
      id: 'landlord',
      nameKo: '집주인',
      nameDe: 'Vermieterin',
      nameEn: 'Landlord',
      voice: 'female',
    ),
    'moderator': ScenarioCharacterProfile(
      id: 'moderator',
      nameKo: '진행자',
      nameDe: 'Moderatorin',
      nameEn: 'Moderator',
      voice: 'female',
    ),
    'official': ScenarioCharacterProfile(
      id: 'official',
      nameKo: '담당자',
      nameDe: 'Sachbearbeiter',
      nameEn: 'Official',
      voice: 'male',
    ),
    'interviewer': ScenarioCharacterProfile(
      id: 'interviewer',
      nameKo: '면접관',
      nameDe: 'Interviewerin',
      nameEn: 'Interviewer',
      voice: 'female',
    ),
    'student': ScenarioCharacterProfile(
      id: 'student',
      nameKo: '학생',
      nameDe: 'Student',
      nameEn: 'Student',
      voice: 'male',
    ),
    'researcher': ScenarioCharacterProfile(
      id: 'researcher',
      nameKo: '연구자',
      nameDe: 'Forscherin',
      nameEn: 'Researcher',
      voice: 'female',
    ),
    'resident': ScenarioCharacterProfile(
      id: 'resident',
      nameKo: '주민',
      nameDe: 'Anwohner',
      nameEn: 'Resident',
      voice: 'male',
    ),
    'editor': ScenarioCharacterProfile(
      id: 'editor',
      nameKo: '편집자',
      nameDe: 'Redakteurin',
      nameEn: 'Editor',
      voice: 'female',
    ),
  };

  static ScenarioCharacterProfile? profileFor(String id) =>
      profiles[id.trim().toLowerCase()];
}
