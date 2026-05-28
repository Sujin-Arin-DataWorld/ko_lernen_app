import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

/// Mastery-Status eines Vokabel-/Lerneintrags. Aus SRS-Daten abgeleitet,
/// nicht separat persistiert.
enum MasteryState {
  /// Noch nie reviewed — frische Karte.
  fresh,
  /// Erste paar Wiederholungen, kurzes Intervall (≤ 3 Tage).
  learning,
  /// Intervall > 3 Tage, fällig (heute oder früher).
  reviewDue,
  /// Intervall > 3 Tage, sitzt — nicht fällig.
  strong,
}

/// Spaced Repetition card state.
/// Felder kurz benannt, damit JSON klein bleibt (viele tausend Vokabeln möglich).
class SrsCard {
  final double ease;          // SM-2 Ease-Faktor (1.3 – 3.5)
  final int    intervalDays;  // aktuelles Intervall
  final String nextReviewIso; // 'YYYY-MM-DD'
  final int    reviewCount;   // wie oft wiederholt

  const SrsCard({
    required this.ease,
    required this.intervalDays,
    required this.nextReviewIso,
    required this.reviewCount,
  });

  Map<String, dynamic> toJson() => {
    'e': ease,
    'i': intervalDays,
    'n': nextReviewIso,
    'r': reviewCount,
  };

  factory SrsCard.fromJson(Map<String, dynamic> j) => SrsCard(
    ease:          (j['e'] as num?)?.toDouble() ?? 2.5,
    intervalDays:  (j['i'] as num?)?.toInt()    ?? 0,
    nextReviewIso: j['n'] as String?            ?? '',
    reviewCount:   (j['r'] as num?)?.toInt()    ?? 0,
  );
}

/// Persistente Speicherung — Lernfortschritt, Spielstand, Einstellungen.
/// Alle Schlüssel mit Präfix `kl_`. iOS und Android automatisch (über
/// `SharedPreferences`, das auf iOS `NSUserDefaults` nutzt).
class Storage {
  static SharedPreferences? _prefs;

  /// In `main()` vor `runApp` aufrufen.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Test-only: leert den `_prefs`-Cache, damit ein neuer
  /// `SharedPreferences.setMockInitialValues(...)` plus `Storage.init()`
  /// frische Werte liefert. Im Produktionscode niemals aufrufen.
  @visibleForTesting
  static void resetForTesting() {
    _prefs = null;
    _srsCache = null;
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

  /// Vokabel-Favoriten — Stern-Markierung für gezieltes Wiederholen.
  static List<String> get vokFavorites => _l('kl_vok_favorites');
  static bool isVokFavorite(String id) => vokFavorites.contains(id);
  static Future<void> toggleVokFavorite(String id) async {
    final list = vokFavorites;
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await _sl('kl_vok_favorites', list);
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

  /// Streak-Freeze Tokens. Verdient an jeder 7-Tage-Marke (Cap [kStreakFreezeMax]).
  /// Schützt automatisch genau einen verpassten Tag, damit der Streak überlebt.
  static int    get streakFreezes        => _i('kl_streak_freezes');
  static String get streakFreezeLastUsed => _s('kl_streak_freeze_last_used');
  static const int kStreakFreezeMax = 2;
  static const int kStreakFreezeRefillDays = 7;

  /// Beim App-Start aufrufen — aktualisiert Streak automatisch.
  /// [now] ist für Tests injizierbar; default = `DateTime.now()`.
  static Future<void> touchStreak({DateTime? now}) async {
    final today = _today(now);
    final last  = lastOpenDate;
    if (last == today) return;

    int newStreak = 1;
    int freezes = streakFreezes;
    bool freezeUsed = false;

    if (last.isNotEmpty) {
      final lastDate = DateTime.tryParse(last);
      if (lastDate != null) {
        final diff = DateTime.parse(today).difference(lastDate).inDays;
        if (diff == 1) {
          newStreak = streakDays + 1;
        } else if (diff == 2 && freezes > 0) {
          // Genau ein verpasster Tag → Freeze einsetzen.
          newStreak = streakDays + 1;
          freezes -= 1;
          freezeUsed = true;
        }
      }
    }

    await _ss('kl_last_open_date', today);
    await _si('kl_streak_days', newStreak);
    if (newStreak > bestStreak) await _si('kl_best_streak', newStreak);

    if (newStreak > 0 &&
        newStreak % kStreakFreezeRefillDays == 0 &&
        freezes < kStreakFreezeMax) {
      freezes += 1;
    }
    await _si('kl_streak_freezes', freezes);
    if (freezeUsed) {
      await _ss('kl_streak_freeze_last_used', today);
    }
  }

  static String _today([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // ───────── Einstellungen ─────────
  static String get localeCode => _s('kl_locale');             // 'de', 'en', '' = system
  static Future<void> setLocaleCode(String v) => _ss('kl_locale', v);

  /// Theme-Modus: 'light' / 'dark' / '' = System.
  static String get themeMode => _s('kl_theme_mode');
  static Future<void> setThemeMode(String v) => _ss('kl_theme_mode', v);

  /// Daily Calligraphy — Liste der ISO-Daten (YYYY-MM-DD) an denen geübt wurde.
  static List<String> get calligraphyDates => _l('kl_callig_dates');
  static Future<void> addCalligraphyDate(String iso) async {
    final list = calligraphyDates;
    if (!list.contains(iso)) {
      list.add(iso);
      await _sl('kl_callig_dates', list);
    }
  }
  static bool get calligraphyDoneToday => calligraphyDates.contains(_today());
  static int get calligraphyTotalDays => calligraphyDates.length;

  static double get ttsRate => _d('kl_tts_rate', 0.42);
  static Future<void> setTtsRate(double v) => _sd('kl_tts_rate', v);

  /// Werbung anzeigen? Default true. User kann in Settings deaktivieren.
  static bool get adsEnabled => _prefs?.getBool('kl_ads_enabled') ?? true;
  static Future<void> setAdsEnabled(bool v) async => _prefs?.setBool('kl_ads_enabled', v);

  /// Intro-Gate (솟을대문) schon gesehen? Erstlauf → volle Animation,
  /// danach kürzere Version.
  static bool get introSeen => _prefs?.getBool('kl_intro_seen') ?? false;
  static Future<void> setIntroSeen() async => _prefs?.setBool('kl_intro_seen', true);

  // ───────── SRS (Spaced Repetition, SM-2 vereinfacht) ─────────
  static Map<String, SrsCard>? _srsCache;

  static Map<String, SrsCard> _loadSrs() {
    if (_srsCache != null) return _srsCache!;
    final raw = _s('kl_srs_v1');
    if (raw.isEmpty) return _srsCache = {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _srsCache = decoded.map(
        (k, v) => MapEntry(k, SrsCard.fromJson(v as Map<String, dynamic>)),
      );
      return _srsCache!;
    } catch (_) {
      return _srsCache = {};
    }
  }

  static Future<void> _persistSrs() async {
    final json = _srsCache?.map((k, v) => MapEntry(k, v.toJson())) ?? const <String, dynamic>{};
    await _ss('kl_srs_v1', jsonEncode(json));
  }

  static String _isoOf(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Nach einer Wiederholung aufrufen. `gotIt` = richtig beantwortet?
  ///
  /// Vereinfachter SM-2:
  /// - Erstes Mal richtig → Intervall 1 Tag
  /// - Zweites Mal richtig → Intervall 3 Tage
  /// - Danach richtig → Intervall × Ease (gerundet, max 365)
  /// - Falsch → Intervall zurück auf 1 Tag, Ease − 0.2
  /// - Richtig → Ease + 0.05 (1.3 ≤ Ease ≤ 3.5)
  static Future<void> srsReview(String id, {required bool gotIt}) async {
    final map = _loadSrs();
    final old = map[id] ?? const SrsCard(ease: 2.5, intervalDays: 0, nextReviewIso: '', reviewCount: 0);
    final now = DateTime.now();

    final SrsCard updated;
    if (gotIt) {
      final newInterval = old.intervalDays == 0
          ? 1
          : old.intervalDays == 1
              ? 3
              : (old.intervalDays * old.ease).round().clamp(1, 365);
      updated = SrsCard(
        ease:          (old.ease + 0.05).clamp(1.3, 3.5),
        intervalDays:  newInterval,
        nextReviewIso: _isoOf(now.add(Duration(days: newInterval))),
        reviewCount:   old.reviewCount + 1,
      );
    } else {
      updated = SrsCard(
        ease:          (old.ease - 0.2).clamp(1.3, 3.5),
        intervalDays:  1,
        nextReviewIso: _isoOf(now.add(const Duration(days: 1))),
        reviewCount:   old.reviewCount + 1,
      );
    }
    map[id] = updated;
    await _persistSrs();
  }

  /// IDs die heute (oder früher) fällig sind. Noch nie gesehen → fällig.
  static Set<String> dueIds(Iterable<String> allIds) {
    final map = _loadSrs();
    final today = _today();
    return allIds.where((id) {
      final card = map[id];
      if (card == null) return true;
      return card.nextReviewIso.compareTo(today) <= 0;
    }).toSet();
  }

  /// SRS-Status einer einzelnen Karte (z.B. für Debug/Anzeige).
  static SrsCard? srsCard(String id) => _loadSrs()[id];

  /// Anzahl aller Karten die jemals reviewed wurden.
  static int srsTotalReviewed() => _loadSrs().length;

  /// Mastery-Status eines Vokabel-Items, abgeleitet aus SRS-Daten.
  /// - [MasteryState.fresh]      → nie reviewed
  /// - [MasteryState.learning]   → reviewed, Intervall ≤ 3 Tage
  /// - [MasteryState.reviewDue]  → Intervall > 3 Tage, fällig (heute/früher)
  /// - [MasteryState.strong]     → Intervall > 3 Tage, noch nicht fällig
  static MasteryState vocabMastery(String id, {DateTime? now}) {
    final card = _loadSrs()[id];
    if (card == null || card.reviewCount == 0) return MasteryState.fresh;
    if (card.intervalDays <= 3) return MasteryState.learning;
    final today = _today(now);
    final due = card.nextReviewIso.isEmpty ||
        card.nextReviewIso.compareTo(today) <= 0;
    return due ? MasteryState.reviewDue : MasteryState.strong;
  }

  // ───────── Szenarien (Phase 5) ─────────
  /// Code wie 'a1', 'a2', 'b1', 'b2' — null bedeutet noch nicht gewählt
  /// (Onboarding-Trigger).
  static String? get userLevelCode {
    final v = _s('kl_user_level');
    return v.isEmpty ? null : v;
  }
  static Future<void> setUserLevelCode(String code) => _ss('kl_user_level', code);

  /// XP-Gesamtpunkte. Level = (xp / 100) + 1.
  static int get xp        => _i('kl_xp');
  static int get xpLevel   => (xp ~/ 100) + 1;
  static int get xpToNext  => 100 - (xp % 100);
  static Future<void> addXp(int amount) => _si('kl_xp', xp + amount);

  /// Sterne pro Szenario (0–3). Speichert nur Verbesserungen.
  static Map<String, int> get scenarioStars {
    final raw = _s('kl_scenario_stars');
    if (raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }
  static Future<void> setScenarioStars(String id, int stars) async {
    final m = scenarioStars;
    if ((m[id] ?? 0) < stars) {
      m[id] = stars;
      await _ss('kl_scenario_stars', jsonEncode(m));
    }
  }

  static List<String> get completedScenarios => _l('kl_completed_scenarios');
  static Future<void> addCompletedScenario(String id) async {
    final list = completedScenarios;
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_completed_scenarios', list);
    }
  }

  static List<String> get earnedBadges => _l('kl_earned_badges');
  static Future<void> earnBadge(String id) async {
    final list = earnedBadges;
    if (!list.contains(id)) {
      list.add(id);
      await _sl('kl_earned_badges', list);
    }
  }

  // ───────── Reset ─────────
  static Future<void> resetAll() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final k in keys) {
      if (k.startsWith('kl_')) await _prefs?.remove(k);
    }
    _srsCache = null;
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
