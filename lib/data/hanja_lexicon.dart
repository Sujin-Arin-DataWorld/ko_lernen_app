/// Curated Sino-Korean lexicon for distinguishing synonyms, register, and
/// nuance. Lookups are optional: missing words stay playable without Hanja.
library;

enum HanjaRegister { everyday, polite, formal, literary }

class HanjaRoot {
  const HanjaRoot({
    required this.character,
    required this.meaningDe,
    required this.meaningEn,
  });

  final String character;
  final String meaningDe;
  final String meaningEn;

  String meaningFor(String language) =>
      language == 'en' ? meaningEn : meaningDe;
}

class HanjaWordEntry {
  const HanjaWordEntry({
    required this.korean,
    required this.hanja,
    required this.register,
    required this.roots,
    this.synonymGroup = '',
    this.nuanceDe = '',
    this.nuanceEn = '',
  });

  final String korean;
  final String hanja;
  final HanjaRegister register;
  final List<HanjaRoot> roots;
  final String synonymGroup;
  final String nuanceDe;
  final String nuanceEn;

  String nuanceFor(String language) => language == 'en' ? nuanceEn : nuanceDe;

  bool get isFormal =>
      register == HanjaRegister.formal || register == HanjaRegister.literary;
}

class HanjaLexicon {
  const HanjaLexicon._();

  static const HanjaRoot _hak = HanjaRoot(
    character: '學',
    meaningDe: 'lernen',
    meaningEn: 'learn',
  );
  static const HanjaRoot _gyo = HanjaRoot(
    character: '校',
    meaningDe: 'Schule',
    meaningEn: 'school',
  );
  static const HanjaRoot _saeng = HanjaRoot(
    character: '生',
    meaningDe: 'Leben / geboren',
    meaningEn: 'life / born',
  );
  static const HanjaRoot _sa = HanjaRoot(
    character: '師',
    meaningDe: 'Lehrer',
    meaningEn: 'teacher',
  );
  static const HanjaRoot _in = HanjaRoot(
    character: '人',
    meaningDe: 'Mensch',
    meaningEn: 'person',
  );
  static const HanjaRoot _gan = HanjaRoot(
    character: '間',
    meaningDe: 'zwischen',
    meaningEn: 'between',
  );
  static const HanjaRoot _guk = HanjaRoot(
    character: '國',
    meaningDe: 'Land',
    meaningEn: 'country',
  );
  static const HanjaRoot _ga = HanjaRoot(
    character: '家',
    meaningDe: 'Haus / Familie',
    meaningEn: 'house / family',
  );
  static const HanjaRoot _jeong = HanjaRoot(
    character: '庭',
    meaningDe: 'Hof / Haushalt',
    meaningEn: 'yard / household',
  );
  static const HanjaRoot _ju = HanjaRoot(
    character: '住',
    meaningDe: 'wohnen',
    meaningEn: 'reside',
  );
  static const HanjaRoot _taek = HanjaRoot(
    character: '宅',
    meaningDe: 'Wohnung',
    meaningEn: 'dwelling',
  );
  static const HanjaRoot _si = HanjaRoot(
    character: '始',
    meaningDe: 'beginnen',
    meaningEn: 'begin',
  );
  static const HanjaRoot _jak = HanjaRoot(
    character: '作',
    meaningDe: 'machen',
    meaningEn: 'make',
  );
  static const HanjaRoot _gae = HanjaRoot(
    character: '開',
    meaningDe: 'öffnen',
    meaningEn: 'open',
  );
  static const HanjaRoot _saYong = HanjaRoot(
    character: '使',
    meaningDe: 'gebrauchen',
    meaningEn: 'use',
  );
  static const HanjaRoot _yong = HanjaRoot(
    character: '用',
    meaningDe: 'nutzen',
    meaningEn: 'utilize',
  );
  static const HanjaRoot _i = HanjaRoot(
    character: '利',
    meaningDe: 'Nutzen',
    meaningEn: 'benefit',
  );
  static const HanjaRoot _saengGak = HanjaRoot(
    character: '覺',
    meaningDe: 'gewahr werden',
    meaningEn: 'become aware',
  );
  static const HanjaRoot _go = HanjaRoot(
    character: '考',
    meaningDe: 'erwägen',
    meaningEn: 'consider',
  );
  static const HanjaRoot _eo = HanjaRoot(
    character: '語',
    meaningDe: 'Sprache',
    meaningEn: 'language',
  );
  static const HanjaRoot _eon = HanjaRoot(
    character: '言',
    meaningDe: 'Wort / sagen',
    meaningEn: 'word / say',
  );
  static const HanjaRoot _sik = HanjaRoot(
    character: '食',
    meaningDe: 'essen',
    meaningEn: 'eat',
  );
  static const HanjaRoot _saSa = HanjaRoot(
    character: '事',
    meaningDe: 'Angelegenheit',
    meaningEn: 'affair',
  );
  static const HanjaRoot _gwan = HanjaRoot(
    character: '觀',
    meaningDe: 'betrachten',
    meaningEn: 'observe',
  );
  static const HanjaRoot _chal = HanjaRoot(
    character: '察',
    meaningDe: 'prüfen',
    meaningEn: 'examine',
  );
  static const HanjaRoot _iHae = HanjaRoot(
    character: '解',
    meaningDe: 'lösen / verstehen',
    meaningEn: 'solve / understand',
  );
  static const HanjaRoot _inJi = HanjaRoot(
    character: '知',
    meaningDe: 'wissen',
    meaningEn: 'know',
  );
  static const HanjaRoot _inIn = HanjaRoot(
    character: '認',
    meaningDe: 'anerkennen',
    meaningEn: 'recognize',
  );
  static const HanjaRoot _hwal = HanjaRoot(
    character: '活',
    meaningDe: 'leben / tätig',
    meaningEn: 'live / active',
  );
  static const HanjaRoot _geo = HanjaRoot(
    character: '居',
    meaningDe: 'sich aufhalten',
    meaningEn: 'dwell',
  );
  static const HanjaRoot _saMang = HanjaRoot(
    character: '死',
    meaningDe: 'sterben',
    meaningEn: 'die',
  );
  static const HanjaRoot _mang = HanjaRoot(
    character: '亡',
    meaningDe: 'vergehen',
    meaningEn: 'perish',
  );
  static const HanjaRoot _seon = HanjaRoot(
    character: '選',
    meaningDe: 'wählen',
    meaningEn: 'choose',
  );
  static const HanjaRoot _ho = HanjaRoot(
    character: '好',
    meaningDe: 'mögen',
    meaningEn: 'like',
  );
  static const HanjaRoot _mun = HanjaRoot(
    character: '問',
    meaningDe: 'fragen',
    meaningEn: 'ask',
  );
  static const HanjaRoot _je = HanjaRoot(
    character: '題',
    meaningDe: 'Thema',
    meaningEn: 'topic',
  );
  static const HanjaRoot _gwa = HanjaRoot(
    character: '課',
    meaningDe: 'Aufgabe',
    meaningEn: 'assignment',
  );
  static const HanjaRoot _dap = HanjaRoot(
    character: '答',
    meaningDe: 'antworten',
    meaningEn: 'answer',
  );
  static const HanjaRoot _byeon = HanjaRoot(
    character: '辯',
    meaningDe: 'darlegen',
    meaningEn: 'explain',
  );
  static const HanjaRoot _won = HanjaRoot(
    character: '原',
    meaningDe: 'Ursprung',
    meaningEn: 'origin',
  );
  static const HanjaRoot _inIn2 = HanjaRoot(
    character: '因',
    meaningDe: 'Grund',
    meaningEn: 'reason',
  );
  static const HanjaRoot _gyeol = HanjaRoot(
    character: '結',
    meaningDe: 'binden / Ergebnis',
    meaningEn: 'bind / result',
  );
  static const HanjaRoot _gwa2 = HanjaRoot(
    character: '果',
    meaningDe: 'Frucht / Folge',
    meaningEn: 'fruit / outcome',
  );
  static const HanjaRoot _seong = HanjaRoot(
    character: '成',
    meaningDe: 'vollenden',
    meaningEn: 'complete',
  );
  static const HanjaRoot _beop = HanjaRoot(
    character: '法',
    meaningDe: 'Methode / Gesetz',
    meaningEn: 'method / law',
  );
  static const HanjaRoot _sik2 = HanjaRoot(
    character: '式',
    meaningDe: 'Form / Weise',
    meaningEn: 'form / manner',
  );
  static const HanjaRoot _jong = HanjaRoot(
    character: '終',
    meaningDe: 'enden',
    meaningEn: 'end',
  );
  static const HanjaRoot _ryo = HanjaRoot(
    character: '了',
    meaningDe: 'abschließen',
    meaningEn: 'finish',
  );
  static const HanjaRoot _choe = HanjaRoot(
    character: '最',
    meaningDe: 'am meisten',
    meaningEn: 'most',
  );
  static const HanjaRoot _cho = HanjaRoot(
    character: '初',
    meaningDe: 'Anfang',
    meaningEn: 'beginning',
  );
  static const HanjaRoot _iHu = HanjaRoot(
    character: '後',
    meaningDe: 'danach',
    meaningEn: 'after',
  );
  static const HanjaRoot _gi = HanjaRoot(
    character: '期',
    meaningDe: 'Zeitraum',
    meaningEn: 'period',
  );
  static const HanjaRoot _hoe = HanjaRoot(
    character: '會',
    meaningDe: 'sich treffen',
    meaningEn: 'meet',
  );
  static const HanjaRoot _ui = HanjaRoot(
    character: '議',
    meaningDe: 'beraten',
    meaningEn: 'discuss',
  );
  static const HanjaRoot _dae = HanjaRoot(
    character: '對',
    meaningDe: 'gegenüber',
    meaningEn: 'toward',
  );
  static const HanjaRoot _hwa = HanjaRoot(
    character: '話',
    meaningDe: 'Gespräch',
    meaningEn: 'talk',
  );
  static const HanjaRoot _to = HanjaRoot(
    character: '討',
    meaningDe: 'erörtern',
    meaningEn: 'debate',
  );
  static const HanjaRoot _ron = HanjaRoot(
    character: '論',
    meaningDe: 'Abhandlung',
    meaningEn: 'treatise',
  );
  static const HanjaRoot _bu = HanjaRoot(
    character: '付',
    meaningDe: 'anvertrauen',
    meaningEn: 'entrust',
  );
  static const HanjaRoot _tak = HanjaRoot(
    character: '託',
    meaningDe: 'bitten',
    meaningEn: 'request',
  );
  static const HanjaRoot _yo = HanjaRoot(
    character: '要',
    meaningDe: 'brauchen',
    meaningEn: 'need',
  );
  static const HanjaRoot _cheong = HanjaRoot(
    character: '請',
    meaningDe: 'ersuchen',
    meaningEn: 'petition',
  );
  static const HanjaRoot _gu = HanjaRoot(
    character: '求',
    meaningDe: 'fordern',
    meaningEn: 'demand',
  );
  static const HanjaRoot _yak = HanjaRoot(
    character: '約',
    meaningDe: 'vereinbaren',
    meaningEn: 'agree',
  );
  static const HanjaRoot _sok = HanjaRoot(
    character: '束',
    meaningDe: 'binden',
    meaningEn: 'bind',
  );
  static const HanjaRoot _gye = HanjaRoot(
    character: '契',
    meaningDe: 'Vertrag',
    meaningEn: 'contract',
  );
  static const HanjaRoot _gyu = HanjaRoot(
    character: '規',
    meaningDe: 'Regel',
    meaningEn: 'rule',
  );
  static const HanjaRoot _chik = HanjaRoot(
    character: '則',
    meaningDe: 'Vorschrift',
    meaningEn: 'regulation',
  );
  static const HanjaRoot _yul = HanjaRoot(
    character: '律',
    meaningDe: 'Gesetz',
    meaningEn: 'statute',
  );
  static const HanjaRoot _sin = HanjaRoot(
    character: '身',
    meaningDe: 'Körper',
    meaningEn: 'body',
  );
  static const HanjaRoot _che = HanjaRoot(
    character: '體',
    meaningDe: 'Leib',
    meaningEn: 'physique',
  );
  static const HanjaRoot _jeong2 = HanjaRoot(
    character: '精',
    meaningDe: 'Geist',
    meaningEn: 'spirit',
  );
  static const HanjaRoot _sin2 = HanjaRoot(
    character: '神',
    meaningDe: 'Seele',
    meaningEn: 'mind',
  );
  static const HanjaRoot _gam = HanjaRoot(
    character: '感',
    meaningDe: 'fühlen',
    meaningEn: 'feel',
  );
  static const HanjaRoot _jeong3 = HanjaRoot(
    character: '情',
    meaningDe: 'Empfindung',
    meaningEn: 'emotion',
  );
  static const HanjaRoot _seup = HanjaRoot(
    character: '習',
    meaningDe: 'üben',
    meaningEn: 'practice',
  );
  static const HanjaRoot _gwan2 = HanjaRoot(
    character: '慣',
    meaningDe: 'gewohnt',
    meaningEn: 'accustomed',
  );
  static const HanjaRoot _neung = HanjaRoot(
    character: '能',
    meaningDe: 'können',
    meaningEn: 'able',
  );
  static const HanjaRoot _ryeok = HanjaRoot(
    character: '力',
    meaningDe: 'Kraft',
    meaningEn: 'power',
  );
  static const HanjaRoot _sil = HanjaRoot(
    character: '實',
    meaningDe: 'wirklich',
    meaningEn: 'real',
  );
  static const HanjaRoot _jae = HanjaRoot(
    character: '才',
    meaningDe: 'Talent',
    meaningEn: 'talent',
  );
  static const HanjaRoot _do = HanjaRoot(
    character: '道',
    meaningDe: 'Weg',
    meaningEn: 'way',
  );
  static const HanjaRoot _ro = HanjaRoot(
    character: '路',
    meaningDe: 'Straße',
    meaningEn: 'road',
  );
  static const HanjaRoot _gong = HanjaRoot(
    character: '空',
    meaningDe: 'leer / Raum',
    meaningEn: 'empty / space',
  );
  static const HanjaRoot _jik = HanjaRoot(
    character: '職',
    meaningDe: 'Amt / Beruf',
    meaningEn: 'office / job',
  );
  static const HanjaRoot _eop = HanjaRoot(
    character: '業',
    meaningDe: 'Tätigkeit',
    meaningEn: 'occupation',
  );
  static const HanjaRoot _jang = HanjaRoot(
    character: '場',
    meaningDe: 'Ort',
    meaningEn: 'place',
  );
  static const HanjaRoot _sang = HanjaRoot(
    character: '商',
    meaningDe: 'Handel',
    meaningEn: 'commerce',
  );
  static const HanjaRoot _jeom = HanjaRoot(
    character: '店',
    meaningDe: 'Laden',
    meaningEn: 'shop',
  );
  static const HanjaRoot _si2 = HanjaRoot(
    character: '市',
    meaningDe: 'Markt',
    meaningEn: 'market',
  );
  static const HanjaRoot _ga3 = HanjaRoot(
    character: '價',
    meaningDe: 'Preis',
    meaningEn: 'price',
  );
  static const HanjaRoot _gyeok = HanjaRoot(
    character: '格',
    meaningDe: 'Rang / Maß',
    meaningEn: 'rank / measure',
  );
  static const HanjaRoot _ui2 = HanjaRoot(
    character: '醫',
    meaningDe: 'heilen',
    meaningEn: 'heal',
  );
  static const HanjaRoot _byeong = HanjaRoot(
    character: '病',
    meaningDe: 'Krankheit',
    meaningEn: 'illness',
  );
  static const HanjaRoot _won2 = HanjaRoot(
    character: '院',
    meaningDe: 'Einrichtung',
    meaningEn: 'institution',
  );
  static const HanjaRoot _yak2 = HanjaRoot(
    character: '藥',
    meaningDe: 'Medizin',
    meaningEn: 'medicine',
  );
  static const HanjaRoot _chin = HanjaRoot(
    character: '親',
    meaningDe: 'nah / verwandt',
    meaningEn: 'close / kin',
  );
  static const HanjaRoot _gu2 = HanjaRoot(
    character: '舊',
    meaningDe: 'alt / bekannt',
    meaningEn: 'old / familiar',
  );
  static const HanjaRoot _gyo2 = HanjaRoot(
    character: '教',
    meaningDe: 'lehren',
    meaningEn: 'teach',
  );
  static const HanjaRoot _seup2 = HanjaRoot(
    character: '習',
    meaningDe: 'lernen',
    meaningEn: 'learn',
  );
  static const HanjaRoot _si3 = HanjaRoot(
    character: '時',
    meaningDe: 'Zeit',
    meaningEn: 'time',
  );
  static const HanjaRoot _gak = HanjaRoot(
    character: '刻',
    meaningDe: 'Augenblick',
    meaningEn: 'moment',
  );
  static const HanjaRoot _geum = HanjaRoot(
    character: '今',
    meaningDe: 'jetzt',
    meaningEn: 'now',
  );
  static const HanjaRoot _il = HanjaRoot(
    character: '日',
    meaningDe: 'Tag',
    meaningEn: 'day',
  );
  static const HanjaRoot _myeong = HanjaRoot(
    character: '明',
    meaningDe: 'hell / nächster',
    meaningEn: 'bright / next',
  );
  static const HanjaRoot _seong2 = HanjaRoot(
    character: '姓',
    meaningDe: 'Familienname',
    meaningEn: 'surname',
  );
  static const HanjaRoot _myeong2 = HanjaRoot(
    character: '名',
    meaningDe: 'Name',
    meaningEn: 'name',
  );
  static const HanjaRoot _yeon = HanjaRoot(
    character: '年',
    meaningDe: 'Jahr',
    meaningEn: 'year',
  );
  static const HanjaRoot _ryeong = HanjaRoot(
    character: '齡',
    meaningDe: 'Alter',
    meaningEn: 'age',
  );
  static const HanjaRoot _yeo = HanjaRoot(
    character: '旅',
    meaningDe: 'reisen',
    meaningEn: 'travel',
  );
  static const HanjaRoot _haeng = HanjaRoot(
    character: '行',
    meaningDe: 'gehen',
    meaningEn: 'go',
  );
  static const HanjaRoot _gwan3 = HanjaRoot(
    character: '觀',
    meaningDe: 'schauen',
    meaningEn: 'view',
  );
  static const HanjaRoot _gwang = HanjaRoot(
    character: '光',
    meaningDe: 'Licht / Sehen',
    meaningEn: 'light / sight',
  );
  static const HanjaRoot _cha = HanjaRoot(
    character: '車',
    meaningDe: 'Wagen',
    meaningEn: 'vehicle',
  );
  static const HanjaRoot _dong = HanjaRoot(
    character: '動',
    meaningDe: 'bewegen',
    meaningEn: 'move',
  );
  static const HanjaRoot _seo = HanjaRoot(
    character: '書',
    meaningDe: 'schreiben / Buch',
    meaningEn: 'write / book',
  );
  static const HanjaRoot _chaek = HanjaRoot(
    character: '冊',
    meaningDe: 'Heft / Buch',
    meaningEn: 'volume / book',
  );
  static const HanjaRoot _mun2 = HanjaRoot(
    character: '文',
    meaningDe: 'Schrift',
    meaningEn: 'writing',
  );
  static const HanjaRoot _ja = HanjaRoot(
    character: '字',
    meaningDe: 'Schriftzeichen',
    meaningEn: 'character',
  );
  static const HanjaRoot _jang2 = HanjaRoot(
    character: '章',
    meaningDe: 'Satz / Kapitel',
    meaningEn: 'sentence / chapter',
  );
  static const HanjaRoot _ui3 = HanjaRoot(
    character: '意',
    meaningDe: 'Sinn',
    meaningEn: 'sense',
  );
  static const HanjaRoot _mi = HanjaRoot(
    character: '味',
    meaningDe: 'Geschmack / Bedeutung',
    meaningEn: 'taste / meaning',
  );
  static const HanjaRoot _han = HanjaRoot(
    character: '漢',
    meaningDe: 'Han / sino',
    meaningEn: 'Han / sino',
  );
  static const HanjaRoot _dan = HanjaRoot(
    character: '單',
    meaningDe: 'einzeln',
    meaningEn: 'single',
  );
  static const HanjaRoot _eoHwi = HanjaRoot(
    character: '彙',
    meaningDe: 'Sammlung',
    meaningEn: 'collection',
  );
  static const HanjaRoot _dong2 = HanjaRoot(
    character: '同',
    meaningDe: 'gleich',
    meaningEn: 'same',
  );
  static const HanjaRoot _ui4 = HanjaRoot(
    character: '義',
    meaningDe: 'Bedeutung',
    meaningEn: 'meaning',
  );
  static const HanjaRoot _gyeok2 = HanjaRoot(
    character: '格',
    meaningDe: 'Formstufe',
    meaningEn: 'register',
  );
  static const HanjaRoot _sik3 = HanjaRoot(
    character: '式',
    meaningDe: 'Form',
    meaningEn: 'form',
  );
  static const HanjaRoot _jon = HanjaRoot(
    character: '尊',
    meaningDe: 'ehren',
    meaningEn: 'honor',
  );
  static const HanjaRoot _ching = HanjaRoot(
    character: '稱',
    meaningDe: 'bezeichnen',
    meaningEn: 'call',
  );
  static const HanjaRoot _gong2 = HanjaRoot(
    character: '工',
    meaningDe: 'Arbeit / Mühe',
    meaningEn: 'work / effort',
  );
  static const HanjaRoot _bu2 = HanjaRoot(
    character: '夫',
    meaningDe: 'Mann / Mühe',
    meaningEn: 'man / effort',
  );
  static const List<HanjaRoot> _none = <HanjaRoot>[];

  static const List<HanjaWordEntry> words = <HanjaWordEntry>[
    HanjaWordEntry(
      korean: '학교',
      hanja: '學校',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_hak, _gyo],
      synonymGroup: 'school',
      nuanceDe: 'Alltagswort für die Schule als Ort.',
      nuanceEn: 'Everyday word for school as a place.',
    ),
    HanjaWordEntry(
      korean: '학생',
      hanja: '學生',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_hak, _saeng],
      synonymGroup: 'student',
      nuanceDe: 'Wer an einer Schule lernt.',
      nuanceEn: 'Someone who learns at a school.',
    ),
    HanjaWordEntry(
      korean: '선생',
      hanja: '先生',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[
        HanjaRoot(character: '先', meaningDe: 'zuerst', meaningEn: 'first'),
        _saeng,
      ],
      synonymGroup: 'teacher',
      nuanceDe: 'Höfliche Anrede und Alltagswort für Lehrkraft.',
      nuanceEn: 'Polite address and everyday word for a teacher.',
    ),
    HanjaWordEntry(
      korean: '교사',
      hanja: '教師',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gyo2, _sa],
      synonymGroup: 'teacher',
      nuanceDe: 'Berufsbezeichnung, oft auf Formularen.',
      nuanceEn: 'Job title, often on forms.',
    ),
    HanjaWordEntry(
      korean: '공부',
      hanja: '工夫',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_gong2, _bu2],
      synonymGroup: 'study',
      nuanceDe: 'Alltägliches Lernen und Üben.',
      nuanceEn: 'Everyday studying and practice.',
    ),
    HanjaWordEntry(
      korean: '학습',
      hanja: '學習',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_hak, _seup2],
      synonymGroup: 'study',
      nuanceDe: 'Formelleres Wort für den Lernprozess.',
      nuanceEn: 'More formal word for the learning process.',
    ),
    HanjaWordEntry(
      korean: '친구',
      hanja: '親舊',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_chin, _gu2],
      synonymGroup: 'friend',
      nuanceDe: 'Nahe stehende Person im Alltag.',
      nuanceEn: 'A close person in everyday life.',
    ),
    HanjaWordEntry(
      korean: '사람',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'person',
      nuanceDe: 'Native Wort für einen Menschen im Alltag.',
      nuanceEn: 'Native word for a person in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '인간',
      hanja: '人間',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_in, _gan],
      synonymGroup: 'person',
      nuanceDe: 'Der Mensch als Gattung oder in abstrakten Texten.',
      nuanceEn: 'The human as a species or in abstract texts.',
    ),
    HanjaWordEntry(
      korean: '나라',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'country',
      nuanceDe: 'Alltagswort für ein Land.',
      nuanceEn: 'Everyday word for a country.',
    ),
    HanjaWordEntry(
      korean: '국가',
      hanja: '國家',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[
        _guk,
        HanjaRoot(character: '家', meaningDe: 'Staatswesen', meaningEn: 'state'),
      ],
      synonymGroup: 'country',
      nuanceDe: 'Der Staat als Institution.',
      nuanceEn: 'The state as an institution.',
    ),
    HanjaWordEntry(
      korean: '집',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'home',
      nuanceDe: 'Das Haus, in dem man wohnt.',
      nuanceEn: 'The house where one lives.',
    ),
    HanjaWordEntry(
      korean: '주택',
      hanja: '住宅',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_ju, _taek],
      synonymGroup: 'home',
      nuanceDe: 'Wohnung oder Wohnhaus in amtlicher Sprache.',
      nuanceEn: 'Housing in official language.',
    ),
    HanjaWordEntry(
      korean: '가정',
      hanja: '家庭',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_ga, _jeong],
      synonymGroup: 'home',
      nuanceDe: 'Die Familie als Haushalt, nicht das Gebäude.',
      nuanceEn: 'The family as a household, not the building.',
    ),
    HanjaWordEntry(
      korean: '시작',
      hanja: '始作',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_si, _jak],
      synonymGroup: 'start',
      nuanceDe: 'Etwas anfangen im Alltag.',
      nuanceEn: 'Starting something in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '개시',
      hanja: '開始',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gae, _si],
      synonymGroup: 'start',
      nuanceDe: 'Offizielle Eröffnung oder Aufnahme.',
      nuanceEn: 'Official opening or commencement.',
    ),
    HanjaWordEntry(
      korean: '사용',
      hanja: '使用',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_saYong, _yong],
      synonymGroup: 'use',
      nuanceDe: 'Etwas gebrauchen, oft ein Werkzeug oder Wort.',
      nuanceEn: 'Using something, often a tool or word.',
    ),
    HanjaWordEntry(
      korean: '이용',
      hanja: '利用',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_i, _yong],
      synonymGroup: 'use',
      nuanceDe: 'Einen Dienst oder eine Gelegenheit nutzen.',
      nuanceEn: 'Using a service or an opportunity.',
    ),
    HanjaWordEntry(
      korean: '생각',
      hanja: '生覺',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_saeng, _saengGak],
      synonymGroup: 'thought',
      nuanceDe: 'Alltägliches Denken oder eine Meinung.',
      nuanceEn: 'Everyday thinking or an opinion.',
    ),
    HanjaWordEntry(
      korean: '사고',
      hanja: '思考',
      register: HanjaRegister.literary,
      roots: <HanjaRoot>[
        HanjaRoot(character: '思', meaningDe: 'denken', meaningEn: 'think'),
        _go,
      ],
      synonymGroup: 'thought',
      nuanceDe: 'Bewusstes Nachdenken, oft schriftlich.',
      nuanceEn: 'Deliberate thinking, often in writing.',
    ),
    HanjaWordEntry(
      korean: '말',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'speech',
      nuanceDe: 'Gesprochene Worte im Alltag.',
      nuanceEn: 'Spoken words in everyday life.',
    ),
    HanjaWordEntry(
      korean: '언어',
      hanja: '言語',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_eon, _eo],
      synonymGroup: 'speech',
      nuanceDe: 'Eine Sprache als System.',
      nuanceEn: 'A language as a system.',
    ),
    HanjaWordEntry(
      korean: '먹다',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'eat',
      nuanceDe: 'Essen als Handlung.',
      nuanceEn: 'The act of eating.',
    ),
    HanjaWordEntry(
      korean: '식사',
      hanja: '食事',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_sik, _saSa],
      synonymGroup: 'eat',
      nuanceDe: 'Eine Mahlzeit, höflicher als 먹다.',
      nuanceEn: 'A meal, more polite than 먹다.',
    ),
    HanjaWordEntry(
      korean: '보다',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'see',
      nuanceDe: 'Sehen oder anschauen.',
      nuanceEn: 'To see or look at.',
    ),
    HanjaWordEntry(
      korean: '관찰',
      hanja: '觀察',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gwan, _chal],
      synonymGroup: 'see',
      nuanceDe: 'Genau und bewusst beobachten.',
      nuanceEn: 'To observe carefully and deliberately.',
    ),
    HanjaWordEntry(
      korean: '알다',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'know',
      nuanceDe: 'Etwas kennen oder wissen.',
      nuanceEn: 'To know or be familiar with.',
    ),
    HanjaWordEntry(
      korean: '이해',
      hanja: '理解',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_i, _iHae],
      synonymGroup: 'know',
      nuanceDe: 'Den Sinn wirklich begreifen.',
      nuanceEn: 'To actually grasp the meaning.',
    ),
    HanjaWordEntry(
      korean: '인지',
      hanja: '認知',
      register: HanjaRegister.literary,
      roots: <HanjaRoot>[_inIn, _inJi],
      synonymGroup: 'know',
      nuanceDe: 'Wahrnehmen oder anerkennen, oft fachlich.',
      nuanceEn: 'To perceive or recognize, often technical.',
    ),
    HanjaWordEntry(
      korean: '살다',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'live',
      nuanceDe: 'Leben oder wohnen.',
      nuanceEn: 'To live or reside.',
    ),
    HanjaWordEntry(
      korean: '생활',
      hanja: '生活',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_saeng, _hwal],
      synonymGroup: 'live',
      nuanceDe: 'Der Alltag und die Lebensweise.',
      nuanceEn: 'Daily life and way of living.',
    ),
    HanjaWordEntry(
      korean: '거주',
      hanja: '居住',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_geo, _ju],
      synonymGroup: 'live',
      nuanceDe: 'Amtlich an einem Ort wohnen.',
      nuanceEn: 'To reside somewhere in official language.',
    ),
    HanjaWordEntry(
      korean: '죽다',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'die',
      nuanceDe: 'Direktes Alltagswort für sterben.',
      nuanceEn: 'Direct everyday word for dying.',
    ),
    HanjaWordEntry(
      korean: '사망',
      hanja: '死亡',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_saMang, _mang],
      synonymGroup: 'die',
      nuanceDe: 'Formelles Wort, etwa in Nachrichten.',
      nuanceEn: 'Formal word, for example in news.',
    ),
    HanjaWordEntry(
      korean: '좋아하다',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'like',
      nuanceDe: 'Etwas gern mögen.',
      nuanceEn: 'To like something.',
    ),
    HanjaWordEntry(
      korean: '선호',
      hanja: '選好',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_seon, _ho],
      synonymGroup: 'like',
      nuanceDe: 'Eine bewusste Vorliebe, oft schriftlich.',
      nuanceEn: 'A deliberate preference, often written.',
    ),
    HanjaWordEntry(
      korean: '문제',
      hanja: '問題',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_mun, _je],
      synonymGroup: 'problem',
      nuanceDe: 'Ein Problem oder eine Prüfungsfrage.',
      nuanceEn: 'A problem or an exam question.',
    ),
    HanjaWordEntry(
      korean: '과제',
      hanja: '課題',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_gwa, _je],
      synonymGroup: 'problem',
      nuanceDe: 'Eine gestellte Aufgabe, oft Hausaufgabe.',
      nuanceEn: 'An assigned task, often homework.',
    ),
    HanjaWordEntry(
      korean: '대답',
      hanja: '對答',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_dae, _dap],
      synonymGroup: 'answer',
      nuanceDe: 'Mündliche Antwort im Gespräch.',
      nuanceEn: 'A spoken answer in conversation.',
    ),
    HanjaWordEntry(
      korean: '답변',
      hanja: '答辯',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_dap, _byeon],
      synonymGroup: 'answer',
      nuanceDe: 'Schriftliche oder offizielle Stellungnahme.',
      nuanceEn: 'A written or official response.',
    ),
    HanjaWordEntry(
      korean: '이유',
      hanja: '理由',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[
        _i,
        HanjaRoot(character: '由', meaningDe: 'Grund', meaningEn: 'reason'),
      ],
      synonymGroup: 'reason',
      nuanceDe: 'Warum jemand etwas tut.',
      nuanceEn: 'Why someone does something.',
    ),
    HanjaWordEntry(
      korean: '원인',
      hanja: '原因',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_won, _inIn2],
      synonymGroup: 'reason',
      nuanceDe: 'Die sachliche Ursache eines Ereignisses.',
      nuanceEn: 'The factual cause of an event.',
    ),
    HanjaWordEntry(
      korean: '결과',
      hanja: '結果',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_gyeol, _gwa2],
      synonymGroup: 'result',
      nuanceDe: 'Was am Ende herauskommt.',
      nuanceEn: 'What comes out at the end.',
    ),
    HanjaWordEntry(
      korean: '성과',
      hanja: '成果',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_seong, _gwa2],
      synonymGroup: 'result',
      nuanceDe: 'Ein erreichten Erfolg oder Ertrag.',
      nuanceEn: 'An achieved success or yield.',
    ),
    HanjaWordEntry(
      korean: '방법',
      hanja: '方法',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[
        HanjaRoot(character: '方', meaningDe: 'Richtung / Art', meaningEn: 'way'),
        _beop,
      ],
      synonymGroup: 'method',
      nuanceDe: 'Wie man etwas macht.',
      nuanceEn: 'How one does something.',
    ),
    HanjaWordEntry(
      korean: '방식',
      hanja: '方式',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[
        HanjaRoot(character: '方', meaningDe: 'Art', meaningEn: 'manner'),
        _sik2,
      ],
      synonymGroup: 'method',
      nuanceDe: 'Die Art und Weise, oft systematisch.',
      nuanceEn: 'The manner, often systematic.',
    ),
    HanjaWordEntry(
      korean: '끝',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'end',
      nuanceDe: 'Das Ende einer Sache im Alltag.',
      nuanceEn: 'The end of something in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '종료',
      hanja: '終了',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_jong, _ryo],
      synonymGroup: 'end',
      nuanceDe: 'Offizielle Beendigung.',
      nuanceEn: 'Official termination.',
    ),
    HanjaWordEntry(
      korean: '최종',
      hanja: '最終',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_choe, _jong],
      synonymGroup: 'end',
      nuanceDe: 'Das Letzte in einer Reihe, endgültig.',
      nuanceEn: 'The last in a series, final.',
    ),
    HanjaWordEntry(
      korean: '처음',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'first',
      nuanceDe: 'Das erste Mal oder der Anfang.',
      nuanceEn: 'The first time or the beginning.',
    ),
    HanjaWordEntry(
      korean: '최초',
      hanja: '最初',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_choe, _cho],
      synonymGroup: 'first',
      nuanceDe: 'Das allererste, oft historisch.',
      nuanceEn: 'The very first, often historical.',
    ),
    HanjaWordEntry(
      korean: '이후',
      hanja: '以後',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[
        HanjaRoot(character: '以', meaningDe: 'ab', meaningEn: 'from'),
        _iHu,
      ],
      synonymGroup: 'after',
      nuanceDe: 'Von einem Zeitpunkt an danach.',
      nuanceEn: 'From a point in time onward.',
    ),
    HanjaWordEntry(
      korean: '동안',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'period',
      nuanceDe: 'Während einer Zeitspanne.',
      nuanceEn: 'During a stretch of time.',
    ),
    HanjaWordEntry(
      korean: '기간',
      hanja: '期間',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gi, _gan],
      synonymGroup: 'period',
      nuanceDe: 'Ein festgelegter Zeitraum.',
      nuanceEn: 'A defined period of time.',
    ),
    HanjaWordEntry(
      korean: '모임',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'meeting',
      nuanceDe: 'Ein Treffen unter Leuten.',
      nuanceEn: 'A gathering of people.',
    ),
    HanjaWordEntry(
      korean: '회의',
      hanja: '會議',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_hoe, _ui],
      synonymGroup: 'meeting',
      nuanceDe: 'Eine förmliche Besprechung.',
      nuanceEn: 'A formal meeting.',
    ),
    HanjaWordEntry(
      korean: '이야기',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'talk',
      nuanceDe: 'Eine Geschichte oder ein Gespräch.',
      nuanceEn: 'A story or a conversation.',
    ),
    HanjaWordEntry(
      korean: '대화',
      hanja: '對話',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_dae, _hwa],
      synonymGroup: 'talk',
      nuanceDe: 'Ein Austausch zwischen Personen.',
      nuanceEn: 'An exchange between people.',
    ),
    HanjaWordEntry(
      korean: '토론',
      hanja: '討論',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_to, _ron],
      synonymGroup: 'talk',
      nuanceDe: 'Eine begründete Auseinandersetzung.',
      nuanceEn: 'A reasoned debate.',
    ),
    HanjaWordEntry(
      korean: '부탁',
      hanja: '付託',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_bu, _tak],
      synonymGroup: 'request',
      nuanceDe: 'Jemanden um einen Gefallen bitten.',
      nuanceEn: 'To ask someone for a favor.',
    ),
    HanjaWordEntry(
      korean: '요청',
      hanja: '要請',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_yo, _cheong],
      synonymGroup: 'request',
      nuanceDe: 'Eine höfliche, oft schriftliche Bitte.',
      nuanceEn: 'A polite, often written request.',
    ),
    HanjaWordEntry(
      korean: '요구',
      hanja: '要求',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_yo, _gu],
      synonymGroup: 'request',
      nuanceDe: 'Eine Forderung, bestimmter als 부탁.',
      nuanceEn: 'A demand, firmer than 부탁.',
    ),
    HanjaWordEntry(
      korean: '약속',
      hanja: '約束',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_yak, _sok],
      synonymGroup: 'promise',
      nuanceDe: 'Eine persönliche Zusage.',
      nuanceEn: 'A personal promise.',
    ),
    HanjaWordEntry(
      korean: '계약',
      hanja: '契約',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gye, _yak],
      synonymGroup: 'promise',
      nuanceDe: 'Ein rechtlich bindender Vertrag.',
      nuanceEn: 'A legally binding contract.',
    ),
    HanjaWordEntry(
      korean: '규칙',
      hanja: '規則',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_gyu, _chik],
      synonymGroup: 'rule',
      nuanceDe: 'Eine Regel in Schule oder Alltag.',
      nuanceEn: 'A rule at school or in daily life.',
    ),
    HanjaWordEntry(
      korean: '법',
      hanja: '法',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_beop],
      synonymGroup: 'rule',
      nuanceDe: 'Das Gesetz im Allgemeinen.',
      nuanceEn: 'The law in general.',
    ),
    HanjaWordEntry(
      korean: '법률',
      hanja: '法律',
      register: HanjaRegister.literary,
      roots: <HanjaRoot>[_beop, _yul],
      synonymGroup: 'rule',
      nuanceDe: 'Konkrete gesetzliche Vorschriften.',
      nuanceEn: 'Concrete legal statutes.',
    ),
    HanjaWordEntry(
      korean: '몸',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'body',
      nuanceDe: 'Der Körper im Alltag.',
      nuanceEn: 'The body in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '신체',
      hanja: '身體',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_sin, _che],
      synonymGroup: 'body',
      nuanceDe: 'Der Körper in medizinischer oder amtlicher Sprache.',
      nuanceEn: 'The body in medical or official language.',
    ),
    HanjaWordEntry(
      korean: '마음',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'mind',
      nuanceDe: 'Gefühl und innere Haltung.',
      nuanceEn: 'Feeling and inner attitude.',
    ),
    HanjaWordEntry(
      korean: '정신',
      hanja: '精神',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_jeong2, _sin2],
      synonymGroup: 'mind',
      nuanceDe: 'Geist, Bewusstsein, mentale Kraft.',
      nuanceEn: 'Mind, consciousness, mental strength.',
    ),
    HanjaWordEntry(
      korean: '기분',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'feeling',
      nuanceDe: 'Die Stimmung im Moment.',
      nuanceEn: 'The mood of the moment.',
    ),
    HanjaWordEntry(
      korean: '감정',
      hanja: '感情',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_gam, _jeong3],
      synonymGroup: 'feeling',
      nuanceDe: 'Eine benennbare Emotion.',
      nuanceEn: 'A nameable emotion.',
    ),
    HanjaWordEntry(
      korean: '습관',
      hanja: '習慣',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_seup, _gwan2],
      synonymGroup: 'habit',
      nuanceDe: 'Eine wiederholte Gewohnheit.',
      nuanceEn: 'A repeated habit.',
    ),
    HanjaWordEntry(
      korean: '버릇',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'habit',
      nuanceDe: 'Oft eine kleine, manchmal störende Angewohnheit.',
      nuanceEn: 'Often a small, sometimes annoying mannerism.',
    ),
    HanjaWordEntry(
      korean: '능력',
      hanja: '能力',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_neung, _ryeok],
      synonymGroup: 'ability',
      nuanceDe: 'Ob jemand etwas kann.',
      nuanceEn: 'Whether someone can do something.',
    ),
    HanjaWordEntry(
      korean: '실력',
      hanja: '實力',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_sil, _ryeok],
      synonymGroup: 'ability',
      nuanceDe: 'Gezeigte Könnerschaft durch Übung.',
      nuanceEn: 'Demonstrated skill from practice.',
    ),
    HanjaWordEntry(
      korean: '재능',
      hanja: '才能',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_jae, _neung],
      synonymGroup: 'ability',
      nuanceDe: 'Eine angeborene Begabung.',
      nuanceEn: 'An innate talent.',
    ),
    HanjaWordEntry(
      korean: '길',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'road',
      nuanceDe: 'Ein Weg, den man geht.',
      nuanceEn: 'A path one walks.',
    ),
    HanjaWordEntry(
      korean: '도로',
      hanja: '道路',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_do, _ro],
      synonymGroup: 'road',
      nuanceDe: 'Eine Straße für Fahrzeuge.',
      nuanceEn: 'A road for vehicles.',
    ),
    HanjaWordEntry(
      korean: '공간',
      hanja: '空間',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gong, _gan],
      synonymGroup: 'space',
      nuanceDe: 'Raum im abstrakten oder planerischen Sinn.',
      nuanceEn: 'Space in an abstract or planning sense.',
    ),
    HanjaWordEntry(
      korean: '방',
      hanja: '房',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[
        HanjaRoot(character: '房', meaningDe: 'Zimmer', meaningEn: 'room'),
      ],
      synonymGroup: 'space',
      nuanceDe: 'Ein Zimmer im Haus.',
      nuanceEn: 'A room in a house.',
    ),
    HanjaWordEntry(
      korean: '일',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'work',
      nuanceDe: 'Arbeit oder eine Sache, die zu tun ist.',
      nuanceEn: 'Work or a thing that needs doing.',
    ),
    HanjaWordEntry(
      korean: '직업',
      hanja: '職業',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_jik, _eop],
      synonymGroup: 'work',
      nuanceDe: 'Der Beruf als Rolle.',
      nuanceEn: 'The occupation as a role.',
    ),
    HanjaWordEntry(
      korean: '직장',
      hanja: '職場',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_jik, _jang],
      synonymGroup: 'work',
      nuanceDe: 'Der Arbeitsplatz, nicht die Tätigkeit.',
      nuanceEn: 'The workplace, not the activity.',
    ),
    HanjaWordEntry(
      korean: '가게',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'shop',
      nuanceDe: 'Ein kleiner Laden.',
      nuanceEn: 'A small shop.',
    ),
    HanjaWordEntry(
      korean: '상점',
      hanja: '商店',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_sang, _jeom],
      synonymGroup: 'shop',
      nuanceDe: 'Ein Geschäft in förmlicherer Sprache.',
      nuanceEn: 'A store in more formal language.',
    ),
    HanjaWordEntry(
      korean: '시장',
      hanja: '市場',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_si2, _jang],
      synonymGroup: 'shop',
      nuanceDe: 'Markt als Ort oder als Wirtschaft.',
      nuanceEn: 'A market as a place or as an economy.',
    ),
    HanjaWordEntry(
      korean: '값',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'price',
      nuanceDe: 'Was etwas kostet im Alltag.',
      nuanceEn: 'What something costs in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '가격',
      hanja: '價格',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_ga3, _gyeok],
      synonymGroup: 'price',
      nuanceDe: 'Der Preis in Läden, Listen und Nachrichten.',
      nuanceEn: 'The price in shops, lists, and news.',
    ),
    HanjaWordEntry(
      korean: '의사',
      hanja: '醫師',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_ui2, _sa],
      synonymGroup: 'doctor',
      nuanceDe: 'Ärztin oder Arzt.',
      nuanceEn: 'A doctor.',
    ),
    HanjaWordEntry(
      korean: '병원',
      hanja: '病院',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_byeong, _won2],
      synonymGroup: 'hospital',
      nuanceDe: 'Das Krankenhaus.',
      nuanceEn: 'The hospital.',
    ),
    HanjaWordEntry(
      korean: '약',
      hanja: '藥',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_yak2],
      synonymGroup: 'medicine',
      nuanceDe: 'Medizin oder Heilmittel.',
      nuanceEn: 'Medicine or a remedy.',
    ),
    HanjaWordEntry(
      korean: '시간',
      hanja: '時間',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_si3, _gan],
      synonymGroup: 'time',
      nuanceDe: 'Zeit als Dauer oder Uhrzeit.',
      nuanceEn: 'Time as duration or clock time.',
    ),
    HanjaWordEntry(
      korean: '시각',
      hanja: '時刻',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_si3, _gak],
      synonymGroup: 'time',
      nuanceDe: 'Ein genauer Zeitpunkt.',
      nuanceEn: 'An exact point in time.',
    ),
    HanjaWordEntry(
      korean: '오늘',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'today',
      nuanceDe: 'Heute im Alltag.',
      nuanceEn: 'Today in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '금일',
      hanja: '今日',
      register: HanjaRegister.literary,
      roots: <HanjaRoot>[_geum, _il],
      synonymGroup: 'today',
      nuanceDe: 'Heute in förmlichen Schreiben.',
      nuanceEn: 'Today in formal writing.',
    ),
    HanjaWordEntry(
      korean: '내일',
      hanja: '來日',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[
        HanjaRoot(character: '來', meaningDe: 'kommen', meaningEn: 'come'),
        _il,
      ],
      synonymGroup: 'tomorrow',
      nuanceDe: 'Morgen im Alltag.',
      nuanceEn: 'Tomorrow in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '명일',
      hanja: '明日',
      register: HanjaRegister.literary,
      roots: <HanjaRoot>[_myeong, _il],
      synonymGroup: 'tomorrow',
      nuanceDe: 'Morgen in sehr förmlicher Sprache.',
      nuanceEn: 'Tomorrow in very formal language.',
    ),
    HanjaWordEntry(
      korean: '이름',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'name',
      nuanceDe: 'Der Name, den man im Alltag sagt.',
      nuanceEn: 'The name used in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '성명',
      hanja: '姓名',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_seong2, _myeong2],
      synonymGroup: 'name',
      nuanceDe: 'Vor- und Familienname auf Formularen.',
      nuanceEn: 'Full name on forms.',
    ),
    HanjaWordEntry(
      korean: '나이',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'age',
      nuanceDe: 'Das Alter im Gespräch.',
      nuanceEn: 'Age in conversation.',
    ),
    HanjaWordEntry(
      korean: '연령',
      hanja: '年齡',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_yeon, _ryeong],
      synonymGroup: 'age',
      nuanceDe: 'Das Alter in Statistiken und Formularen.',
      nuanceEn: 'Age in statistics and forms.',
    ),
    HanjaWordEntry(
      korean: '여행',
      hanja: '旅行',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_yeo, _haeng],
      synonymGroup: 'travel',
      nuanceDe: 'Eine Reise machen.',
      nuanceEn: 'To take a trip.',
    ),
    HanjaWordEntry(
      korean: '관광',
      hanja: '觀光',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_gwan3, _gwang],
      synonymGroup: 'travel',
      nuanceDe: 'Sehenswürdigkeiten ansehen.',
      nuanceEn: 'To see sights.',
    ),
    HanjaWordEntry(
      korean: '차',
      hanja: '車',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_cha],
      synonymGroup: 'car',
      nuanceDe: 'Auto im Alltag. Kann auch Tee bedeuten.',
      nuanceEn: 'Car in everyday speech. Can also mean tea.',
    ),
    HanjaWordEntry(
      korean: '자동차',
      hanja: '自動車',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[
        HanjaRoot(character: '自', meaningDe: 'selbst', meaningEn: 'self'),
        _dong,
        _cha,
      ],
      synonymGroup: 'car',
      nuanceDe: 'Kraftfahrzeug, eindeutiger als 차.',
      nuanceEn: 'Motor vehicle, clearer than 차.',
    ),
    HanjaWordEntry(
      korean: '책',
      hanja: '冊',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_chaek],
      synonymGroup: 'book',
      nuanceDe: 'Ein Buch zum Lesen.',
      nuanceEn: 'A book to read.',
    ),
    HanjaWordEntry(
      korean: '도서',
      hanja: '圖書',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[
        HanjaRoot(character: '圖', meaningDe: 'Bild / Plan', meaningEn: 'figure'),
        _seo,
      ],
      synonymGroup: 'book',
      nuanceDe: 'Bücher in Bibliotheken und Katalogen.',
      nuanceEn: 'Books in libraries and catalogs.',
    ),
    HanjaWordEntry(
      korean: '글',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'writing',
      nuanceDe: 'Geschriebener Text.',
      nuanceEn: 'Written text.',
    ),
    HanjaWordEntry(
      korean: '문자',
      hanja: '文字',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_mun2, _ja],
      synonymGroup: 'writing',
      nuanceDe: 'Schriftzeichen oder eine SMS.',
      nuanceEn: 'A written character or a text message.',
    ),
    HanjaWordEntry(
      korean: '문장',
      hanja: '文章',
      register: HanjaRegister.polite,
      roots: <HanjaRoot>[_mun2, _jang2],
      synonymGroup: 'writing',
      nuanceDe: 'Ein vollständiger Satz.',
      nuanceEn: 'A complete sentence.',
    ),
    HanjaWordEntry(
      korean: '뜻',
      hanja: '',
      register: HanjaRegister.everyday,
      roots: _none,
      synonymGroup: 'meaning',
      nuanceDe: 'Die Bedeutung eines Wortes im Alltag.',
      nuanceEn: 'The meaning of a word in everyday speech.',
    ),
    HanjaWordEntry(
      korean: '의미',
      hanja: '意味',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_ui3, _mi],
      synonymGroup: 'meaning',
      nuanceDe: 'Die Bedeutung in Erklärung oder Analyse.',
      nuanceEn: 'Meaning in an explanation or analysis.',
    ),
    HanjaWordEntry(
      korean: '한자',
      hanja: '漢字',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_han, _ja],
      synonymGroup: 'hanja',
      nuanceDe: 'Chinesische Schriftzeichen im Koreanischen.',
      nuanceEn: 'Chinese characters used in Korean.',
    ),
    HanjaWordEntry(
      korean: '단어',
      hanja: '單語',
      register: HanjaRegister.everyday,
      roots: <HanjaRoot>[_dan, _eo],
      synonymGroup: 'word',
      nuanceDe: 'Ein einzelnes Wort.',
      nuanceEn: 'A single word.',
    ),
    HanjaWordEntry(
      korean: '어휘',
      hanja: '語彙',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_eo, _eoHwi],
      synonymGroup: 'word',
      nuanceDe: 'Der Wortschatz als Menge.',
      nuanceEn: 'Vocabulary as a set.',
    ),
    HanjaWordEntry(
      korean: '동의어',
      hanja: '同意語',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_dong2, _ui4, _eo],
      synonymGroup: 'synonym',
      nuanceDe: 'Wörter mit ähnlicher Bedeutung.',
      nuanceEn: 'Words with a similar meaning.',
    ),
    HanjaWordEntry(
      korean: '격식',
      hanja: '格式',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_gyeok2, _sik3],
      synonymGroup: 'register',
      nuanceDe: 'Wie förmlich eine Formulierung ist.',
      nuanceEn: 'How formal a wording is.',
    ),
    HanjaWordEntry(
      korean: '존칭',
      hanja: '尊稱',
      register: HanjaRegister.formal,
      roots: <HanjaRoot>[_jon, _ching],
      synonymGroup: 'honorific',
      nuanceDe: 'Eine ehrende Anrede oder Verbform.',
      nuanceEn: 'An honoring address or verb form.',
    ),
    HanjaWordEntry(
      korean: '말씀',
      hanja: '',
      register: HanjaRegister.polite,
      roots: _none,
      synonymGroup: 'speech',
      nuanceDe: 'Höfliche Form von 말, für die Worte anderer.',
      nuanceEn: 'Honorific form of 말, for someone else’s words.',
    ),
  ];

  static final Map<String, HanjaWordEntry> _byKorean = <String, HanjaWordEntry>{
    for (final entry in words) entry.korean: entry,
  };

  static HanjaWordEntry? lookup(String korean) {
    final trimmed = korean.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final direct = _byKorean[trimmed];
    if (direct != null) {
      return direct;
    }
    if (trimmed.endsWith('하다') && trimmed.length > 2) {
      return _byKorean[trimmed.substring(0, trimmed.length - 2)];
    }
    if (trimmed.endsWith('되다') && trimmed.length > 2) {
      return _byKorean[trimmed.substring(0, trimmed.length - 2)];
    }
    return null;
  }

  static List<HanjaWordEntry> groupmates(HanjaWordEntry entry) {
    if (entry.synonymGroup.isEmpty) {
      return <HanjaWordEntry>[entry];
    }
    return words
        .where((candidate) => candidate.synonymGroup == entry.synonymGroup)
        .toList(growable: false);
  }
}
