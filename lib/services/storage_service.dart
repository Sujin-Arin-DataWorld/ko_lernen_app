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
  final double ease; // SM-2 Ease-Faktor (1.3 – 3.5)
  final int intervalDays; // aktuelles Intervall
  final String nextReviewIso; // 'YYYY-MM-DD'
  final int reviewCount; // wie oft wiederholt

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
    ease: (j['e'] as num?)?.toDouble() ?? 2.5,
    intervalDays: (j['i'] as num?)?.toInt() ?? 0,
    nextReviewIso: j['n'] as String? ?? '',
    reviewCount: (j['r'] as num?)?.toInt() ?? 0,
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
  static int _i(String k) => _prefs?.getInt(k) ?? 0;
  static String _s(String k) => _prefs?.getString(k) ?? '';
  static double _d(String k, [double dflt = 0]) => _prefs?.getDouble(k) ?? dflt;
  static List<String> _l(String k) => _prefs?.getStringList(k) ?? [];

  static Future<void> _si(String k, int v) async => _prefs?.setInt(k, v);
  static Future<void> _ss(String k, String v) async => _prefs?.setString(k, v);
  static Future<void> _sd(String k, double v) async => _prefs?.setDouble(k, v);
  static Future<void> _sl(String k, List<String> v) async =>
      _prefs?.setStringList(k, v);

  static bool _b(String k, [bool dflt = false]) => _prefs?.getBool(k) ?? dflt;
  static Future<void> _sb(String k, bool v) async => _prefs?.setBool(k, v);

  // ───────── Premium / Abo (RevenueCat-Cache) ─────────
  // `premiumCached` spiegelt das echte RevenueCat-Entitlement (offline-fähig,
  // bei jedem CustomerInfo-Update aktualisiert). `devPremiumOverride` ist ein
  // lokaler Test-Schalter (Settings → Debug), um Gating + Paywall ohne
  // Dashboard-Setup zu prüfen — verändert NICHT den echten Kaufstatus.
  static bool get premiumCached => _b('kl_premium_cached');
  static Future<void> setPremiumCached(bool v) => _sb('kl_premium_cached', v);

  static bool get devPremiumOverride => _b('kl_premium_dev_override');
  static Future<void> setDevPremiumOverride(bool v) =>
      _sb('kl_premium_dev_override', v);

  // ───────── Benachrichtigungen (M3) — tägliche Lern-Erinnerung ─────────
  static bool get notificationsEnabled => _b('kl_notif_enabled');
  static Future<void> setNotificationsEnabled(bool v) =>
      _sb('kl_notif_enabled', v);
  // Default 19:00 (Abend). getInt maskiert "ungesetzt", daher direkt mit ?? 19.
  static int get notificationHour => _prefs?.getInt('kl_notif_hour') ?? 19;
  static Future<void> setNotificationHour(int v) => _si('kl_notif_hour', v);

  // ───────── Interessen (M5) — Personalisierung des Tageskurses ─────────
  static List<String> get interests => _l('kl_interests');
  static Future<void> setInterests(List<String> v) => _sl('kl_interests', v);

  // ───────── Vokabeln ─────────
  static int get vokCorrect => _i('kl_vok_correct');
  static int get vokWrong => _i('kl_vok_wrong');
  static int get vokSkipped => _i('kl_vok_skipped');
  static int get vokLastIdx => _i('kl_vok_last_idx');
  static List<String> get vokSeenIds => _l('kl_vok_seen_ids');

  static Future<void> setVokCorrect(int v) => _si('kl_vok_correct', v);
  static Future<void> setVokWrong(int v) => _si('kl_vok_wrong', v);
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
  static int get chosungWrong => _i('kl_chosung_wrong');
  static Future<void> incChosungCorrect() =>
      _si('kl_chosung_correct', chosungCorrect + 1);
  static Future<void> incChosungWrong() =>
      _si('kl_chosung_wrong', chosungWrong + 1);

  // ───────── Wordle ─────────
  static int get wordleWins => _i('kl_wordle_wins');
  static int get wordleLosses => _i('kl_wordle_losses');
  static int get wordleStreak => _i('kl_wordle_streak');
  static int get wordleBestStreak => _i('kl_wordle_best_streak');
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
  static int get grammarLastIdx => _i('kl_gram_last_idx');
  static List<String> get grammarSeen => _l('kl_gram_seen');
  static List<String> get grammarHard => _l('kl_gram_hard');

  static Future<void> setGrammarLastIdx(int v) => _si('kl_gram_last_idx', v);
  static Future<void> addGrammarSeen(String pattern) async {
    final list = grammarSeen;
    if (!list.contains(pattern)) {
      list.add(pattern);
      await _sl('kl_gram_seen', list);
    }
  }

  static Future<void> markGrammarHard(String pattern) async {
    final list = grammarHard;
    if (!list.contains(pattern)) {
      list.add(pattern);
      await _sl('kl_gram_hard', list);
    }
  }

  static Future<void> markGrammarEasy(String pattern) async {
    final list = grammarHard;
    if (list.contains(pattern)) {
      list.remove(pattern);
      await _sl('kl_gram_hard', list);
    }
  }

  // ───────── App / Streak ─────────
  static String get lastOpenDate => _s('kl_last_open_date'); // 'YYYY-MM-DD'
  static int get streakDays => _i('kl_streak_days');
  static int get bestStreak => _i('kl_best_streak');

  /// Streak-Freeze Tokens. Verdient an jeder 7-Tage-Marke (Cap [kStreakFreezeMax]).
  /// Schützt automatisch genau einen verpassten Tag, damit der Streak überlebt.
  static int get streakFreezes => _i('kl_streak_freezes');
  static String get streakFreezeLastUsed => _s('kl_streak_freeze_last_used');
  static const int kStreakFreezeMax = 2;
  static const int kStreakFreezeRefillDays = 7;

  /// Beim App-Start aufrufen — aktualisiert Streak automatisch.
  /// [now] ist für Tests injizierbar; default = `DateTime.now()`.
  static Future<void> touchStreak({DateTime? now}) async {
    final today = _today(now);
    final last = lastOpenDate;
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
  static String get localeCode => _s('kl_locale'); // 'de', 'en', '' = system
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

  /// 도장첩 — 획득한 단청 도장 motif slug 목록 (DancheongMotif.name).
  static List<String> get earnedStamps => _l('kl_stamps_earned');
  static Future<void> addEarnedStamp(String motif) async {
    final list = earnedStamps;
    if (!list.contains(motif)) {
      list.add(motif);
      await _sl('kl_stamps_earned', list);
    }
  }

  static double get ttsRate => _d('kl_tts_rate', 0.42);
  static Future<void> setTtsRate(double v) => _sd('kl_tts_rate', v);

  /// Werbung anzeigen? Default true. User kann in Settings deaktivieren.
  static bool get adsEnabled => _prefs?.getBool('kl_ads_enabled') ?? true;
  static Future<void> setAdsEnabled(bool v) async =>
      _prefs?.setBool('kl_ads_enabled', v);

  /// Intro-Gate (솟을대문) schon gesehen? Erstlauf → volle Animation,
  /// danach kürzere Version.
  static bool get introSeen => _prefs?.getBool('kl_intro_seen') ?? false;
  static Future<void> setIntroSeen() async =>
      _prefs?.setBool('kl_intro_seen', true);

  // ───────── 온보딩 코치마크 1회성 플래그 (Stage 1) ─────────
  // `introSeen` 패턴과 동일. 각각 진입 화면에서 최초 1회 시트 표시.

  /// 책 한 컷 코치마크 표시됨?
  static bool get tutBookSeen => _prefs?.getBool('kl_tut_book') ?? false;
  static Future<void> setTutBookSeen() async =>
      _prefs?.setBool('kl_tut_book', true);

  /// 단어팩 진입 코치마크 표시됨?
  static bool get tutVocabPackSeen =>
      _prefs?.getBool('kl_tut_vocab_pack') ?? false;
  static Future<void> setTutVocabPackSeen() async =>
      _prefs?.setBool('kl_tut_vocab_pack', true);

  /// 단어팩 퀴즈 스테이지 인라인 배너 표시됨?
  static bool get tutPackQuizSeen =>
      _prefs?.getBool('kl_tut_pack_quiz') ?? false;
  static Future<void> setTutPackQuizSeen() async =>
      _prefs?.setBool('kl_tut_pack_quiz', true);

  /// 단어팩 보스 스테이지 인라인 배너 표시됨?
  static bool get tutPackBossSeen =>
      _prefs?.getBool('kl_tut_pack_boss') ?? false;
  static Future<void> setTutPackBossSeen() async =>
      _prefs?.setBool('kl_tut_pack_boss', true);

  /// 온보딩 3장 미리보기 캐러셀 표시됨? (Stage 2)
  static bool get introPreviewSeen =>
      _prefs?.getBool('kl_intro_preview_seen') ?? false;
  static Future<void> setIntroPreviewSeen() async =>
      _prefs?.setBool('kl_intro_preview_seen', true);

  /// 모든 튜토리얼·코치마크 플래그를 false로 리셋 (Settings "안내 다시 보기").
  /// `introSeen`(솟을대문 애니메이션)은 건드리지 않음 — 코치마크와 별도 개념.
  static Future<void> resetTutorials() async {
    await Future.wait([
      _sb('kl_tut_book', false),
      _sb('kl_tut_vocab_pack', false),
      _sb('kl_tut_pack_quiz', false),
      _sb('kl_tut_pack_boss', false),
      _sb('kl_intro_preview_seen', false),
    ]);
  }

  /// DSGVO/ToS-Einwilligung beim ersten Start akzeptiert? (Consent-Gate)
  static bool get consentAccepted =>
      _prefs?.getBool('kl_consent_accepted') ?? false;
  static Future<void> setConsentAccepted() async =>
      _prefs?.setBool('kl_consent_accepted', true);

  /// Geburtsjahr (optional, Alters-Gate für Gye/Community — GDPR-K §8 DSGVO).
  /// 0 = nicht angegeben. Siehe [AgeGateService].
  static int get birthYear => _prefs?.getInt('kl_birth_year') ?? 0;
  static Future<void> setBirthYear(int year) async =>
      _prefs?.setInt('kl_birth_year', year);

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
    final json =
        _srsCache?.map((k, v) => MapEntry(k, v.toJson())) ??
        const <String, dynamic>{};
    await _ss('kl_srs_v1', jsonEncode(json));
  }

  /// Roh-JSON des SRS-Decks (für CloudSync-Backup). Leer = kein Deck.
  static String get srsRawJson => _s('kl_srs_v1');

  /// SRS-Deck als Roh-JSON setzen (CloudSync-Restore) + Cache invalidieren,
  /// damit der nächste [_loadSrs] neu parst.
  static Future<void> setSrsRawJson(String json) async {
    await _ss('kl_srs_v1', json);
    _srsCache = null;
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
    final old =
        map[id] ??
        const SrsCard(
          ease: 2.5,
          intervalDays: 0,
          nextReviewIso: '',
          reviewCount: 0,
        );
    final now = DateTime.now();

    final SrsCard updated;
    if (gotIt) {
      final newInterval = old.intervalDays == 0
          ? 1
          : old.intervalDays == 1
          ? 3
          : (old.intervalDays * old.ease).round().clamp(1, 365);
      updated = SrsCard(
        ease: (old.ease + 0.05).clamp(1.3, 3.5),
        intervalDays: newInterval,
        nextReviewIso: _isoOf(now.add(Duration(days: newInterval))),
        reviewCount: old.reviewCount + 1,
      );
    } else {
      updated = SrsCard(
        ease: (old.ease - 0.2).clamp(1.3, 3.5),
        intervalDays: 1,
        nextReviewIso: _isoOf(now.add(const Duration(days: 1))),
        reviewCount: old.reviewCount + 1,
      );
    }
    map[id] = updated;
    await _persistSrs();
  }

  /// IDs die heute (oder früher) fällig sind. Noch nie gesehen → fällig.
  ///
  /// **Achtung**: Dies liefert ALLE fälligen Karten, inkl. nie gesehener.
  /// Bei Erstanwendung sind das tausende Karten → UX-Stress.
  /// Für die tägliche Lerneinheit lieber [todayNewIds] + [todayReviewIds]
  /// (Phase 1 SRS-UX-Patch in stately-rising-jongga).
  static Set<String> dueIds(Iterable<String> allIds) {
    final map = _loadSrs();
    final today = _today();
    return allIds.where((id) {
      final card = map[id];
      if (card == null) return true;
      return card.nextReviewIso.compareTo(today) <= 0;
    }).toSet();
  }

  // ── Phase 1 SRS-UX-Patch (stately-rising-jongga) ─────────────────────
  //
  // "Heute lernen" = neue Karten (max [max]) + Wiederholungs-Karten
  // (max [max]). Cap verhindert "522 due" Schock-UX bei Erstanwendung.
  //
  // Reihenfolge in [allIds] wird respektiert → CSV-Reihenfolge =
  // Lern-Reihenfolge (kuratiert nach Wichtigkeit / Pack-Order).
  //
  // ─────────────────────────────────────────────────────────────────────

  /// "Heute neu" — nie reviewed Karten, max [max]. Reihenfolge: wie [allIds].
  static List<String> todayNewIds(Iterable<String> allIds, {int max = 10}) {
    if (max <= 0) return const [];
    final map = _loadSrs();
    final out = <String>[];
    for (final id in allIds) {
      if (map[id] == null) {
        out.add(id);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// "Heute Wiederholung" — schon mal reviewed, jetzt fällig, max [max].
  /// Schließt nie-gesehene Karten aus (das sind "neue", siehe [todayNewIds]).
  static List<String> todayReviewIds(Iterable<String> allIds, {int max = 15}) {
    if (max <= 0) return const [];
    final map = _loadSrs();
    final today = _today();
    final out = <String>[];
    for (final id in allIds) {
      final card = map[id];
      if (card == null) continue; // nie gesehen → "neu", nicht "review"
      if (card.reviewCount == 0) continue;
      if (card.nextReviewIso.isEmpty ||
          card.nextReviewIso.compareTo(today) <= 0) {
        out.add(id);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// Tagesziel = Union(todayNewIds, todayReviewIds). Insertion-order erhalten.
  /// Liefert maximal `newMax + reviewMax` IDs.
  static List<String> todayGoalIds(
    Iterable<String> allIds, {
    int newMax = 10,
    int reviewMax = 15,
  }) {
    final fresh = todayNewIds(allIds, max: newMax);
    final review = todayReviewIds(allIds, max: reviewMax);
    final seen = <String>{};
    final out = <String>[];
    for (final id in [...fresh, ...review]) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  /// SRS-Status einer einzelnen Karte (z.B. für Debug/Anzeige).
  static SrsCard? srsCard(String id) => _loadSrs()[id];

  /// Anzahl aller Karten die jemals reviewed wurden.
  static int srsTotalReviewed() => _loadSrs().length;

  /// A2: "어려운 단어"(leech) — 반복해도 안 굳는 단어 IDs.
  /// 기준: 3회 이상 복습 + (ease ≤ 1.8 [여러 번 틀림] 또는 간격 ≤ 1일 [계속 리셋]).
  /// [allIds] 순서를 유지. 최대 [max]개.
  static List<String> hardIds(Iterable<String> allIds, {int max = 50}) {
    final map = _loadSrs();
    final out = <String>[];
    for (final id in allIds) {
      final c = map[id];
      if (c == null) continue;
      if (c.reviewCount >= 3 && (c.ease <= 1.8 || c.intervalDays <= 1)) {
        out.add(id);
        if (out.length >= max) break;
      }
    }
    return out;
  }

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
    final due =
        card.nextReviewIso.isEmpty || card.nextReviewIso.compareTo(today) <= 0;
    return due ? MasteryState.reviewDue : MasteryState.strong;
  }

  // ───────── Szenarien (Phase 5) ─────────
  /// Code wie 'a1', 'a2', 'b1', 'b2' — null bedeutet noch nicht gewählt
  /// (Onboarding-Trigger).
  static String? get userLevelCode {
    final v = _s('kl_user_level');
    return v.isEmpty ? null : v;
  }

  static Future<void> setUserLevelCode(String code) =>
      _ss('kl_user_level', code);

  /// XP-Gesamtpunkte. Level = (xp / 100) + 1.
  static int get xp => _i('kl_xp');
  static int get xpLevel => (xp ~/ 100) + 1;
  static int get xpToNext => 100 - (xp % 100);
  static Future<void> addXp(int amount) => _si('kl_xp', xp + amount);

  /// 계 피드에 마지막으로 broadcast 한 레벨 (2픽 levelUp 중복 방지).
  static int get lastGyeLevel => _i('kl_gye_level');
  static Future<void> setLastGyeLevel(int v) => _si('kl_gye_level', v);

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

  // ── Phase 2 (stately-rising-jongga) ── Pack-Fortschritt (lokal) ──────
  //
  // Lokale Source of Truth — überlebt offline. FirestoreProgressService
  // synct asynchron im Hintergrund (best-effort).
  //
  // Speicherformat: JSON-encoded Map<packId, PackProgress.toJson()>.
  // Schlüssel: `kl_pack_progress_v1` — Versionierung im Namen, damit
  // spätere Schema-Migrationen unterscheidbar bleiben.
  //
  // Hier wird absichtlich KEIN `PackProgress` importiert — Storage darf
  // keine model-Abhängigkeit haben (zirkulär bei Tests). Stattdessen
  // raw JSON Maps; `PackProgressService` dekodiert.
  // ─────────────────────────────────────────────────────────────────────

  static const String _packProgressKey = 'kl_pack_progress_v1';
  static Map<String, dynamic>? _packCache;

  static Map<String, Map<String, dynamic>> _loadPackJson() {
    if (_packCache != null) {
      return _packCache!.map(
        (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
      );
    }
    final raw = _s(_packProgressKey);
    if (raw.isEmpty) {
      _packCache = <String, dynamic>{};
      return const <String, Map<String, dynamic>>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _packCache = decoded;
      return decoded.map(
        (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
      );
    } catch (_) {
      _packCache = <String, dynamic>{};
      return const <String, Map<String, dynamic>>{};
    }
  }

  /// JSON-rohdaten eines Packs (null wenn nie gespeichert).
  /// Nutze `PackProgressService.get()` für typisierte Objekte.
  static Map<String, dynamic>? packProgressJson(String packId) {
    final map = _loadPackJson();
    return map[packId];
  }

  /// Alle Pack-Fortschritte als Raw-JSON. Für Bulk-load (Grid-Screen).
  static Map<String, Map<String, dynamic>> allPackProgressJson() =>
      _loadPackJson();

  /// Pack-Fortschritt schreiben (overwrite). Aufrufer ist verantwortlich
  /// für Merge-Logik (PackProgressService).
  static Future<void> setPackProgressJson(
    String packId,
    Map<String, dynamic> json,
  ) async {
    final cache = _packCache ?? <String, dynamic>{};
    cache[packId] = json;
    _packCache = cache;
    await _ss(_packProgressKey, jsonEncode(cache));
  }

  /// Mehrere Packs gleichzeitig schreiben (Migration / Cloud-restore).
  static Future<void> setManyPackProgressJson(
    Map<String, Map<String, dynamic>> entries,
  ) async {
    final cache = _packCache ?? <String, dynamic>{};
    cache.addAll(entries);
    _packCache = cache;
    await _ss(_packProgressKey, jsonEncode(cache));
  }

  /// Test-only: Pack-Cache invalidieren.
  @visibleForTesting
  static void resetPackProgressForTesting() {
    _packCache = null;
  }

  // ── Phase 5.1 (stately-rising-jongga) ── Custom Packs + Endpoint ────
  //
  // CustomPack JSON map: { packId: { name, sourcePageId, words: [...], ... } }
  // Endpoint: BookAnalysisService 가 부르는 Cloud Function URL (Settings UI).
  // ────────────────────────────────────────────────────────────────────

  static String get customPacksRawJson => _s('kl_custom_packs_v1');
  static Future<void> setCustomPacksRawJson(String json) =>
      _ss('kl_custom_packs_v1', json);

  static String get bookAnalysisEndpoint =>
      _s('kl_book_analysis_endpoint');
  static Future<void> setBookAnalysisEndpoint(String url) =>
      _ss('kl_book_analysis_endpoint', url.trim());

  // ── Phase 5 (stately-rising-jongga) ── 책 한 컷 / Bookshelf Storage ──
  //
  // Raw JSON string in SharedPreferences. Bookshelf-Service liest/parst.
  // ────────────────────────────────────────────────────────────────────
  static String get bookshelfRawJson => _s('kl_bookshelf_v1');
  static Future<void> setBookshelfRawJson(String json) =>
      _ss('kl_bookshelf_v1', json);

  /// Tagessperre für "책 한 컷" Analyse-Aufrufe — DeepL Free 한도 보호.
  /// Speichert `<isoDate>:<count>`.
  static const int kBookSnapDailyLimit = 20;

  static int bookSnapCountToday() {
    final raw = _s('kl_book_snap_quota');
    final today = _today();
    if (raw.isEmpty) return 0;
    final parts = raw.split(':');
    if (parts.length != 2) return 0;
    if (parts[0] != today) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  static Future<void> incBookSnapCountToday() async {
    final today = _today();
    final cur = bookSnapCountToday();
    await _ss('kl_book_snap_quota', '$today:${cur + 1}');
  }

  static bool get bookSnapQuotaReached =>
      bookSnapCountToday() >= kBookSnapDailyLimit;

  // ── Phase 4 (stately-rising-jongga) ── Kkeunmari-Wins Counter ───────
  //
  // Wird in `kkeunmari_screen._endGame()` inkrementiert bei Sieg
  // (tigerStuck / deadEnd). Quest `q_punggyeong` braucht ≥ 10.
  static int get kkeunmariWins => _i('kl_kkeunmari_wins');
  static Future<void> incKkeunmariWins() =>
      _si('kl_kkeunmari_wins', kkeunmariWins + 1);

  // ── Phase 4 (stately-rising-jongga) ── Quest-Abschluss-Persistenz ────
  //
  // Format: JSON Map<questId, ISO-Timestamp>. Storage gewinnt von Quest-
  // Tracker — beim ersten Erreichen des Targets wird hier markiert; die
  // Marke verschwindet nicht mehr (auch wenn der Counter später sinkt,
  // z.B. nach Reset).
  static const String _questCompletedKey = 'kl_quests_completed_v1';

  static Map<String, String> get questCompletions {
    final raw = _s(_questCompletedKey);
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return const {};
    }
  }

  static bool hasQuestCompleted(String id) => questCompletions.containsKey(id);

  static Future<void> markQuestCompleted(String id, {DateTime? at}) async {
    final map = Map<String, String>.from(questCompletions);
    if (map.containsKey(id)) return; // idempotent
    map[id] = (at ?? DateTime.now().toUtc()).toIso8601String();
    await _ss(_questCompletedKey, jsonEncode(map));
  }

  // ── Phase 3 (stately-rising-jongga) ── Gesehene Hanok-Stages ─────────
  //
  // Liste der bereits "gesehenen" HanokStage-Namen (z.B. ['empty',
  // 'foundation']). Wird vom HanokCinematic-Widget gelesen, um die
  // Übergangsszene nur einmal pro Stage auszuspielen.
  // ─────────────────────────────────────────────────────────────────────

  static List<String> get seenHanokStages => _l('kl_hanok_stages_seen_v1');

  static bool hasSeenHanokStage(String stageName) =>
      seenHanokStages.contains(stageName);

  static Future<void> markHanokStageSeen(String stageName) async {
    final list = seenHanokStages;
    if (list.contains(stageName)) return;
    list.add(stageName);
    await _sl('kl_hanok_stages_seen_v1', list);
  }

  // ───────── Reset ─────────
  static Future<void> resetAll() async {
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final k in keys) {
      if (k.startsWith('kl_')) await _prefs?.remove(k);
    }
    _srsCache = null;
    _packCache = null;
  }

  static Future<void> resetSession() async {
    // Game-Punkte zurücksetzen, Streak/Profil-Daten bleiben
    await _si('kl_vok_correct', 0);
    await _si('kl_vok_wrong', 0);
    await _si('kl_vok_skipped', 0);
    await _si('kl_vok_last_idx', 0);
    await _sl('kl_vok_seen_ids', []);
  }
}
