import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CTA 어휘 가드 — 같은 동작에 새 단어가 끼어드는 것을 막는다.
///
/// 대상: `lib/l10n/app_de.arb` / `app_en.arb` 에서 키가 `btn` 로 시작하거나
/// `Cta` 로 끝나는 항목 전부(생성 파일은 보지 않는다 — arb 원본만 정본).
///
/// 규칙: 각 키의 값은 ⓐ 허용 어휘 집합에 있거나 ⓑ 예외 맵에 실측값 그대로
/// 등재돼 있어야 한다. 새 키가 둘 다 아니면 실패 — 메시지에 키와 값을 낸다.
/// 예외 맵의 값이 arb 실제값과 달라져도 실패한다(문구를 몰래 바꾸는 걸 막는다).
///
/// 예외 맵은 **하향 전용**이다 — 이 파일 정정·정리로 항목이 줄면 상한도
/// 낮춰야 하며, 새 CTA가 예외 맵에 또 쌓이는 걸 목적으로 두지 않는다.
void main() {
  late Map<String, dynamic> de;
  late Map<String, dynamic> en;

  setUpAll(() {
    de =
        json.decode(File('lib/l10n/app_de.arb').readAsStringSync())
            as Map<String, dynamic>;
    en =
        json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
  });

  List<String> ctaKeys(Map<String, dynamic> arb) {
    return arb.keys
        .where(
          (k) =>
              !k.startsWith('@') &&
              (k.startsWith('btn') || k.endsWith('Cta')),
        )
        .toList()
      ..sort();
  }

  test('CTA 키 값은 허용 어휘 또는 등재된 예외뿐이다 (DE)', () {
    final keys = ctaKeys(de);
    final violations = <String>[];
    for (final key in keys) {
      final value = de[key] as String;
      if (_allowedDe.contains(value)) continue;
      final exception = _exceptionsDe[key];
      if (exception == null) {
        violations.add('$key = "$value" (허용 어휘도 예외도 아님)');
      } else if (exception != value) {
        violations.add(
          '$key = "$value" (예외 맵 등재값 "$exception" 과 다름 — 몰래 바뀜)',
        );
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'DE CTA 어휘 드리프트:\n${violations.join('\n')}',
    );
  });

  test('CTA 키 값은 허용 어휘 또는 등재된 예외뿐이다 (EN)', () {
    final keys = ctaKeys(en);
    final violations = <String>[];
    for (final key in keys) {
      final value = en[key] as String;
      if (_allowedEn.contains(value)) continue;
      final exception = _exceptionsEn[key];
      if (exception == null) {
        violations.add('$key = "$value" (허용 어휘도 예외도 아님)');
      } else if (exception != value) {
        violations.add(
          '$key = "$value" (예외 맵 등재값 "$exception" 과 다름 — 몰래 바뀜)',
        );
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'EN CTA 어휘 드리프트:\n${violations.join('\n')}',
    );
  });

  test('예외 맵 항목 수는 상한을 넘지 않는다 (하향 전용 래칫)', () {
    expect(_exceptionsDe.length, lessThanOrEqualTo(_exceptionCeiling));
    expect(_exceptionsEn.length, lessThanOrEqualTo(_exceptionCeiling));
  });
}

/// 허용 어휘 (DE) — 지시서 확정 목록.
const _allowedDe = <String>{
  'Starten',
  'Weiter',
  'Weiterlernen',
  'Üben',
  'Fertig',
  'Prüfen',
  'Zurück',
  'Abbrechen',
  'Schließen',
  'Löschen',
  'Übernehmen',
  'Erneut versuchen',
  'Überspringen',
  'OK',
};

/// 허용 어휘 (EN) — 지시서 확정 목록.
const _allowedEn = <String>{
  'Start',
  'Next',
  'Continue learning',
  'Practice',
  'Done',
  'Check',
  'Back',
  'Cancel',
  'Close',
  'Delete',
  'Apply',
  'Try again',
  'Skip',
  'OK',
};

/// 예외 맵 항목 수 상한. **이 숫자는 내려갈 수만 있다** — 새 CTA 키가
/// 예외 맵에 더 쌓이는 걸 정상 경로로 두지 않는다(허용 어휘를 쓰거나,
/// 정말 다른 동작이면 설계 룰링을 받아 어휘를 확장한다).
/// 실측 54(DE/EN 각각)에 붙여 둔다 — 여유 칸을 두지 않는다. 내려갈 수만
/// 있다(2026-09-04 재실측: DE 54건, EN 54건 — 여유 없음, 이전 가정과 다름).
/// 2026-09-07 재실측: 결제/레벨 해제 정리로 arb에서 사라진 onboarding CTA
/// 2건을 고아 등재에서 제거하고 grammarBrowseAllCta(탐색 CTA, 기존 예외와
/// 같은 부류)를 등재 — DE 53건, EN 53건. 상한 54 → 53 (하향).
/// wordWebBrowseLevelCta 는 콘텐츠 전면 개방으로 문구가 바뀌어 등재값 갱신.
const _exceptionCeiling = 53;

/// DE 예외 맵 — 2026-09-04 PR4-T5 정정 후 실측값 그대로 등재.
const _exceptionsDe = <String, String>{
  'bookshelfCreatePackCta': 'Eigenes Paket aus dieser Seite',
  'bookshelfEmptyCta': 'Seite einlesen',
  'btnGewusst': 'Gewusst!',
  'btnHoeren': 'Hören',
  'btnNewGame': 'Neues Spiel',
  'btnNichtGewusst': 'Nicht gewusst',
  'btnRandom': 'Zufällig',
  'consentAgreeCta': 'Zustimmen & loslegen',
  'consentDemoCta': 'App ansehen',
  'consentPrivacyCta': 'Datenschutzerklärung',
  'consentTermsCta': 'Nutzungsbedingungen',
  'courseMissionBriefBuildCta': 'Jetzt bauen',
  'courseMissionBriefCheckpointCta': 'Abschlusscheck starten',
  'courseMissionBriefListenCta': 'Jetzt hören',
  'courseMissionBriefSceneCta': 'Szene beginnen',
  'createWordbookCta': 'Eigene Wortliste',
  'dojangDecorHintCta': 'Sarangbang gestalten',
  'dojangEmptyCta': 'Vokabelpakete öffnen',
  'grammarBrowseAllCta': 'Alle Grammatikmuster ansehen',
  'grammarChoiceCta': 'Mit Beispielen üben',
  'grammarPlanFinishedRestartCta': 'Neu starten',
  'gyeCreateCta': 'Erstellen',
  'gyeJoinCta': 'Beitreten',
  'gyeOpenCta': 'Gye öffnen',
  'gyePromiseSceneCta': 'Meine heutige Szene öffnen',
  'gyeTodayFallbackCta': 'Zu Heute',
  'hardWordsHardQuizCta': 'Schweres Quiz: Schreibweise',
  'hardWordsStudyCta': 'Gezielt wiederholen',
  'homeEmptyCta': 'Gespeicherte Wörter wiederholen',
  'homeHanokPreviewCta': 'Mein Hanok öffnen',
  'homeLearnNowCta': 'Jetzt lernen',
  'homeSarangbangCta': 'Im Sarangbang lernen',
  'homeUnavailableCta': 'Gespeicherte Wörter wiederholen',
  'ilduWorldLockedCta': 'Passende Mission ansehen',
  'listeningReviewCta': 'Zeile für Zeile wiederholen',
  'questsOpenGiftCta': 'Bündel öffnen',
  'scenarioNextRecommendedCta': 'Öffnen',
  'statsFirstEntryCta': 'Erstes Szenario starten',
  'testerFeedbackCardCta': 'Gib dem Tiger einen Hinweis',
  'vocabNotebookNuanceCta': 'Hanja und Nuancen',
  'vocabNotebookPracticeCta': 'Genau diese Wörter üben',
  'vocabNotebookPreviewCta': 'Diese Wörter übernehmen',
  'vocabNotebookStudioCta': 'Spiel aus diesen Wörtern bauen',
  'vocabPackRecallHintCta': 'Erste Silbe zeigen',
  'vocabPackRecallShowAnswerCta': 'Antwort zeigen',
  'vocabPackResultHardWordsCta': 'Schwierige Wörter üben',
  'vocabPackResultRecallCta': 'Auf Koreanisch abrufen',
  'vocabPackResultRetryCta': 'Nochmal versuchen',
  'vocabPacksBrowseAllCta': 'Alle Vokabel-Pakete ansehen',
  'wbSearchCta': 'Meine Wörter durchsuchen',
  'wordWebBrowseLevelCta': 'Alle Niveaus ansehen',
  'wordWebOpenVocabCta': 'Wortpakete öffnen',
  'wordWebQuizCta': 'Diese Wörter üben',
};

/// EN 예외 맵 — 2026-09-04 PR4-T5 정정 후 실측값 그대로 등재.
///
/// `consentContinueCta` 의 "Continue" 는 법적 동의 문맥이라 지시서상 예외로
/// 남긴다(허용 어휘 "Continue learning" 과는 다른 단어라 예외 맵에 등재).
const _exceptionsEn = <String, String>{
  'bookshelfCreatePackCta': 'Create a custom pack from this page',
  'bookshelfEmptyCta': 'Snap a page',
  'btnGewusst': 'Got it!',
  'btnHoeren': 'Listen',
  'btnNewGame': 'New game',
  'btnNichtGewusst': "Didn't know",
  'btnRandom': 'Random',
  'consentAgreeCta': 'Agree & start',
  'consentContinueCta': 'Continue',
  'consentDemoCta': 'View demo',
  'consentPrivacyCta': 'Privacy policy',
  'consentTermsCta': 'Terms of service',
  'courseMissionBriefBuildCta': 'Build now',
  'courseMissionBriefCheckpointCta': 'Start the final check',
  'courseMissionBriefListenCta': 'Listen now',
  'courseMissionBriefSceneCta': 'Start the scene',
  'createWordbookCta': 'My word list',
  'dojangDecorHintCta': 'Decorate the Sarangbang',
  'dojangEmptyCta': 'Open vocabulary packs',
  'grammarBrowseAllCta': 'Browse all grammar',
  'grammarChoiceCta': 'Practice with examples',
  'grammarPlanFinishedRestartCta': 'Start over',
  'gyeCreateCta': 'Create',
  'gyeJoinCta': 'Join',
  'gyeOpenCta': 'Open gye',
  'gyePromiseSceneCta': 'Open today’s scene',
  'gyeTodayFallbackCta': 'Go to Today',
  'hardWordsHardQuizCta': 'Hard quiz: spelling',
  'hardWordsStudyCta': 'Drill these',
  'homeEmptyCta': 'Review saved words',
  'homeHanokPreviewCta': 'Open my Hanok',
  'homeLearnNowCta': 'Learn now',
  'homeSarangbangCta': 'Study in the Sarangbang',
  'homeUnavailableCta': 'Review saved words',
  'ilduWorldLockedCta': 'See the matching mission',
  'listeningReviewCta': 'Review line by line',
  'questsOpenGiftCta': 'Open the bundle',
  'scenarioNextRecommendedCta': 'Open',
  'statsFirstEntryCta': 'Start your first scenario',
  'testerFeedbackCardCta': 'Give the tiger a clue',
  'vocabNotebookNuanceCta': 'Hanja and nuance',
  'vocabNotebookPracticeCta': 'Practice these exact words',
  'vocabNotebookPreviewCta': 'Keep these words',
  'vocabNotebookStudioCta': 'Build a game from these words',
  'vocabPackRecallHintCta': 'Show first syllable',
  'vocabPackRecallShowAnswerCta': 'Show answer',
  'vocabPackResultHardWordsCta': 'Practice tricky words',
  'vocabPackResultRecallCta': 'Recall in Korean',
  'vocabPacksBrowseAllCta': 'Browse all vocab packs',
  'wbSearchCta': 'Search my words',
  'wordWebBrowseLevelCta': 'Browse all levels',
  'wordWebOpenVocabCta': 'Open vocabulary packs',
  'wordWebQuizCta': 'Practice these words',
};
