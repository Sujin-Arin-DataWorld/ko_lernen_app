/// 닉네임·계 이름 욕설 deny-list (KO/DE/EN 스타터).
///
/// ⚠️ 스타터 세트 — 출시 전 확장 필요(plan §7.6: ~100단어). 부분 포함 검사라
/// 거짓 양성을 줄이려 명백한 비속어만 담음. 정규화 시 **한글은 보존**(공백·구분
/// 기호만 제거) — `\W` 통째 제거하면 한글이 사라져 한국어 욕설을 못 잡음.
const Set<String> _denyList = {
  // EN
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'dick', 'cunt',
  'nigger', 'faggot', 'slut', 'whore', 'rape', 'nazi', 'retard',
  // DE
  'scheisse', 'scheiße', 'arschloch', 'fotze', 'hurensohn', 'wichser',
  'schlampe', 'nutte', 'hure',
  // KO (한글 + 로마자)
  '씨발', '시발', '병신', '개새끼', '지랄', '존나', '꺼져', '닥쳐', '죽어',
  'shibal', 'sibal', 'ssibal', 'byeongsin', 'gaesaekki',
};

final RegExp _sep = RegExp(r'[\s._\-*~`!@#\$%^&()+=]+');

/// deny-list 단어가 포함되면 true. 소문자화 + 공백/구분기호 제거(한글 보존) 후
/// 부분 문자열 검사(난독화 's.h.i.t' / 's h i t' 일부 흡수).
bool containsProfanity(String text) {
  final norm = text.toLowerCase().replaceAll(_sep, '');
  if (norm.isEmpty) {
    return false;
  }
  for (final w in _denyList) {
    final wn = w.toLowerCase().replaceAll(_sep, '');
    if (wn.isNotEmpty && norm.contains(wn)) {
      return true;
    }
  }
  return false;
}
