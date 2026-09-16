/// B1+ 단어 심화 노트 (C9-T0) — `assets/data/usage_notes.json`.
///
/// vocab/grammar id 당 0~1개, 카드 뒷면(`_FlipBack`)의 접이식 "쓰임" 구획에만
/// 쓰인다. 파일이 없거나 이 id의 노트가 없으면 화면은 아무것도 바꾸지 않는다
/// (offline-safe, incremental rollout) — `DataLoader.loadUsageNotes()` 참고.
library;

/// ko/de/en 3개 언어 텍스트 묶음 — 뉘앙스·전형 상황·패턴·연어 공용 shape.
class UsageNoteText {
  final String ko;
  final String de;
  final String en;

  const UsageNoteText({this.ko = '', this.de = '', this.en = ''});

  factory UsageNoteText.fromJson(Map<String, dynamic> json) => UsageNoteText(
    ko: (json['ko'] as String?)?.trim() ?? '',
    de: (json['de'] as String?)?.trim() ?? '',
    en: (json['en'] as String?)?.trim() ?? '',
  );

  /// UI 언어 텍스트(en 있으면 en, 없으면 de로 폴백).
  String forLang(String lang) => lang == 'en' && en.isNotEmpty ? en : de;

  bool get isEmpty => ko.isEmpty && de.isEmpty && en.isEmpty;
}

/// 유의어 대비 1~2개. `vocabId`가 살아있는 표제어를 가리키면(선택) 향후
/// 딥링크에 쓸 수 있지만 이 카드 UI는 텍스트만 보여준다.
class UsageNoteContrast {
  final String headword;
  final String? vocabId;
  final String ko;
  final String de;
  final String en;

  const UsageNoteContrast({
    required this.headword,
    this.vocabId,
    this.ko = '',
    this.de = '',
    this.en = '',
  });

  factory UsageNoteContrast.fromJson(Map<String, dynamic> json) {
    final rawVocabId = json['vocabId'];
    return UsageNoteContrast(
      headword: (json['headword'] as String?)?.trim() ?? '',
      vocabId: rawVocabId is String && rawVocabId.trim().isNotEmpty
          ? rawVocabId.trim()
          : null,
      ko: (json['ko'] as String?)?.trim() ?? '',
      de: (json['de'] as String?)?.trim() ?? '',
      en: (json['en'] as String?)?.trim() ?? '',
    );
  }

  String forLang(String lang) => lang == 'en' && en.isNotEmpty ? en : de;
}

/// 예문 1개 — 격식/비격식 등 register 태그를 함께 들고 다닌다.
class UsageNoteExample {
  final String ko;
  final String de;
  final String en;
  final String register;

  const UsageNoteExample({
    this.ko = '',
    this.de = '',
    this.en = '',
    this.register = 'neutral',
  });

  factory UsageNoteExample.fromJson(Map<String, dynamic> json) =>
      UsageNoteExample(
        ko: (json['ko'] as String?)?.trim() ?? '',
        de: (json['de'] as String?)?.trim() ?? '',
        en: (json['en'] as String?)?.trim() ?? '',
        register: (json['register'] as String?)?.trim() ?? 'neutral',
      );

  String forLang(String lang) => lang == 'en' && en.isNotEmpty ? en : de;
}

/// 표제어 한 개(vocab/grammar id)에 대한 심화 노트 전체.
class UsageNote {
  final String id;
  final String level;
  final UsageNoteText nuance;
  final UsageNoteText situation;
  final List<UsageNoteText> patterns;
  final List<UsageNoteText> collocations;
  final List<UsageNoteContrast> contrasts;
  final String register;
  final List<UsageNoteExample> examples;

  const UsageNote({
    required this.id,
    required this.level,
    required this.nuance,
    required this.situation,
    this.patterns = const [],
    this.collocations = const [],
    this.contrasts = const [],
    this.register = 'neutral',
    this.examples = const [],
  });

  factory UsageNote.fromJson(Map<String, dynamic> json) {
    List<UsageNoteText> textList(String key) => (json[key] as List? ?? const [])
        .whereType<Map>()
        .map((e) => UsageNoteText.fromJson(e.cast<String, dynamic>()))
        .toList();
    return UsageNote(
      id: (json['id'] as String?)?.trim() ?? '',
      level: (json['level'] as String?)?.trim() ?? '',
      nuance: json['nuance'] is Map
          ? UsageNoteText.fromJson((json['nuance'] as Map).cast<String, dynamic>())
          : const UsageNoteText(),
      situation: json['situation'] is Map
          ? UsageNoteText.fromJson(
              (json['situation'] as Map).cast<String, dynamic>(),
            )
          : const UsageNoteText(),
      patterns: textList('patterns'),
      collocations: textList('collocations'),
      contrasts: (json['contrasts'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => UsageNoteContrast.fromJson(e.cast<String, dynamic>()))
          .toList(),
      register: (json['register'] as String?)?.trim() ?? 'neutral',
      examples: (json['examples'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => UsageNoteExample.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
