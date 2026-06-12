/// 닉네임·계 이름 욕설 deny-list (KO/DE/EN — 출시 세트 ~100 엔트리).
///
/// 부분 포함 검사라 **거짓 양성 회피가 우선**: 짧거나 일반 단어에 포함되는
/// 형태는 의도적으로 제외 (예: 'ass'→Wasser/Klasse, 'anal'→Analyse/Kanal,
/// 'cock'→peacock, 'coon'→raccoon, 'mongo'→Mongolei, '년'/'놈' 단독→연도·이름,
/// 'kkk'→ㅋㅋㅋ 로마자). 활용형은 어간이 잡으면 중복 등재하지 않는다.
/// 정규화 시 **한글은 보존**(공백·구분 기호만 제거) — `\W` 통째 제거하면
/// 한글이 사라져 한국어 욕설을 못 잡음.
const Set<String> _denyList = {
  // ── EN ──
  'fuck', 'shit', 'bitch', 'asshole', 'bastard', 'dickhead', 'cunt',
  'nigger', 'nigga', 'faggot', 'slut', 'whore', 'rape', 'nazi', 'retard',
  'motherfucker', 'wanker', 'twat', 'douchebag', 'jackass', 'dumbass',
  'blowjob', 'handjob', 'cocksucker', 'pussy', 'dildo', 'porno',
  'penis', 'vagina', 'hitler', 'whitepower', 'chink', 'kike', 'spic',
  'wetback', 'towelhead', 'tranny',
  // ── DE ──
  'scheisse', 'scheiße', 'arschloch', 'fotze', 'hurensohn', 'wichser',
  'schlampe', 'nutte', 'hure', 'fick', 'verfickt', 'missgeburt',
  'mistgeburt', 'drecksau', 'scheisskerl', 'schwuchtel', 'kanake',
  'neger', 'untermensch', 'judensau', 'siegheil', 'schwanzlutscher',
  'wixer', 'wixxer', 'hurenkind', 'hurentochter', 'penner', 'spasti',
  'muschi', 'arschficker',
  // ── KO (한글) ──
  '씨발', '씨팔', '시발', '병신', '개새끼', '개새', '개색기', '개색끼',
  '지랄', '존나', '존만', '꺼져', '닥쳐', '죽어',
  '좆같', '좆까', '좆나', '좆밥', '자지', '보지', '섹스', '야동', '강간',
  '창녀', '창년', '걸레년', '미친놈', '미친년', '또라이', '썅',
  '쌍놈', '쌍년', '호로새끼', '후레자식', '느금마', '니애미', '니애비',
  '엠창', '애미뒤진', '애비뒤진', '틀딱',
  // ── KO (로마자 표기) ──
  'shibal', 'sibal', 'ssibal', 'byeongsin', 'gaesaekki', 'jonna', 'jiral',
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
