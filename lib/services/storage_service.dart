import 'package:shared_preferences/shared_preferences.dart';

/// Persistente Speicherung — Lernfortschritt, Spielstand, Einstellungen.
/// Alle Schlüssel mit Präfix `kl_`. iOS und Android automatisch (über
/// `SharedPreferences`, das auf iOS `NSUserDefaults` nutzt).
class Storage {
  static SharedPreferences? _prefs;

  /// In `main()` vor `runApp` aufrufen.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ───────── Generic helpers ─────────
  static int    _i(String k)             => _prefs?.getInt(k)    ?? 0;
  static String _s(String k)             => _prefs?.getString(k) ?? '';
  static double _d(String k, [double dflt = 0]) => _prefs?.getDouble(k) ?? dflt;
  static List<String> _l(String k)       => _prefs?.getStringList(k) ?? [];

  static Future<void> _si(String k, int v)         async => _prefs?.setInt(k, v);
  static Future<void> _ss(String k, String v)      async => _prefs?.setString(k, v);
  static Future<void> _sd(String k, double v)      async => _prefs?.setDouble(k, v);
  static Future<void> _sl(String k, List<String> v) async => _prefs?.setStringList(k, v);

  // ───────── Vokabeln ─────────
  static int  get vokCorrect  => _i('kl_vok_correct');
  static int  get vokWrong    => _i('kl_vok_wrong');
  static int  get vokSkipped  => _i('kl_vok_skipped');
  static int  get vokLastIdx  => _i('kl_vok_last_idx');
  static List<String> get vokSeenIds => _l('kl_vok_seen_ids');

  static Future<void> setVokCorrect(int v) => _si('kl_vok_correct', v);
  static Future<void> setVokWrong(int v)   => _si('kl_vok_wrong', v);
  static Future<void> setVokSkipped(int v) => _si('kl_vok_skipped', v);
  static Future<void> setVokLastIdx(int v) => _si('kl_vok_last_idx', v);
  static Future<void> addVokSeen(String id) async {
    final list = vokSeenIds;
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_vok_seen_ids', list);
    }
  }

  // ───────── Chosung Quiz ─────────
  static int get chosungCorrect => _i('kl_chosung_correct');
  static int get chosungWrong   => _i('kl_chosung_wrong');
  static Future<void> incChosungCorrect() => _si('kl_chosung_correct', chosungCorrect + 1);
  static Future<void> incChosungWrong()   => _si('kl_chosung_wrong',   chosungWrong   + 1);

  // ───────── Wordle ─────────
  static int get wordleWins        => _i('kl_wordle_wins');
  static int get wordleLosses      => _i('kl_wordle_losses');
  static int get wordleStreak      => _i('kl_wordle_streak');
  static int get wordleBestStreak  => _i('kl_wordle_best_streak');
  static Future<void> incWordleWins() async {
    await _si('kl_wordle_wins', wordleWins + 1);
    final s = wordleStreak + 1;
    await _si('kl_wordle_streak', s);
    if (s > wordleBestStreak) await _si('kl_wordle_best_streak', s);
  }
  static Future<void> incWordleLosses() async {
    await _si('kl_wordle_losses', wordleLosses + 1);
    await _si('kl_wordle_streak', 0);
  }

  // ───────── Grammatik ─────────
  static int  get grammarLastIdx => _i('kl_gram_last_idx');
  static List<String> get grammarSeen => _l('kl_gram_seen');
  static Future<void> setGrammarLastIdx(int v) => _si('kl_gram_last_idx', v);
  static Future<void> addGrammarSeen(String pattern) async {
    final list = grammarSeen;
    if (!list.contains(pattern)) {
      list.add(pattern);
      await _sl('kl_gram_seen', list);
    }
  }

  // ───────── App / Streak ─────────
  static String get lastOpenDate => _s('kl_last_open_date');  // 'YYYY-MM-DD'
  static int    get streakDays   => _i('kl_streak_days');
  static int    get bestStreak   => _i('kl_best_streak');

  /// Beim App-Start aufrufen — aktualisiert Streak automatisch.
  static Future<void> touchStreak() async {
    final today = _today();
    final last  = lastOpenDate;
    if (last == today) return;

    int newStreak = 1;
    if (last.isNotEmpty) {
      final lastDate = DateTime.tryParse(last);
      if (lastDate != null) {
        final diff = DateTime.parse(today).difference(lastDate).inDays;
        if (diff == 1) newStreak = streakDays + 1;
      }
    }
    await _ss('kl_last_open_date', today);
    await _si('kl_streak_days', newStreak);
    if (newStreak > bestStreak) await _si('kl_best_streak', newStreak);
  }

  static String _today() {
    final d = DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // ───────── Einstellungen ─────────
  static String get localeCode => _s('kl_locale');             // 'de', 'en', '' = system
  static Future<void> setLocaleCode(String v) => _ss('kl_locale', v);

  static double get ttsRate => _d('kl_tts_rate', 0.42);
  static Future<void> setTtsRate(double v) => _sd('kl_tts_rate', v);

  // ───────── Reset ─────────
  static Future<void> resetAll() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final k in keys) {
      if (k.startsWith('kl_')) await _prefs?.remove(k);
    }
  }

  static Future<void> resetSession() async {
    // Game-Punkte zurücksetzen, Streak/Profil-Daten bleiben
    await _si('kl_vok_correct', 0);
    await _si('kl_vok_wrong',   0);
    await _si('kl_vok_skipped', 0);
    await _si('kl_vok_last_idx', 0);
    await _sl('kl_vok_seen_ids', []);
  }
}
