import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// W10 T-N1 (Jin 결정 D-1) — 앱의 안내형 학습 경로 기능은 "Kurs"가 아니라
/// "Lernpfad"로 부른다. 이 가드는 그 개명이 새 문구로 되돌아가지 않도록
/// 잠근다.
///
/// 예외는 두 갈래다:
/// - [_realWorldExceptions]: 앱 기능이 아니라 실제 강의/수업을 가리키는
///   DE "Kurs" 두 곳 — `onboardingFirstSceneWorkCanDo`("im Kurs oder auf
///   der Arbeit")와 `onboardingV2PurposeStudyWorkBody`("in Kurs, Studium
///   und Beruf").
/// - [_icuSelectorExceptions]: EN ARB 값 안에 `course{…}`라는 ICU select
///   분기 리터럴이 그대로 남아 있는 두 키. 이 `course`는
///   `lib/data/sori_activity_catalog.dart`의 `id: 'course'`
///   (Dart activityId, 번역 대상 아님)를 가리키는 식별자라 렌더링되는
///   영어 단어가 아니다 — 안에 담긴 실제 문구(soriStageActivityTitle의
///   "Learning path", soriStageActivityDescription의 "Your guided path
///   through real situations.")는 이미 개명되어 있다.
/// - `discoverPriorityBookBody`("Understand text from your course book")
///   의 "course book" 은 교과서라는 뜻의 실생활 명사이지 앱의 Lernpfad
///   기능이 아니다 — 위 두 갈래와 같은 성격이라 아래 리스트에 함께 둔다.
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

  const kursAllowlist = <String>{
    'onboardingFirstSceneWorkCanDo',
    'onboardingV2PurposeStudyWorkBody',
  };

  // EN 스캔 전용: "course"가 실제 영단어 뜻(관용구/실생활 명사)이거나
  // Dart activityId를 가리키는 ICU select 리터럴이라 렌더링되는 학습-경로
  // 문구가 아닌 키. 디자이너 확인 대기 — STEP 3 작업 중 새로 발견됨.
  const courseWordAllowlist = <String>{
    // "course book" = 교과서(실생활 명사), 앱의 Lernpfad 기능이 아니다.
    'discoverPriorityBookBody',
    // ICU select 리터럴 `course{…}`가 Dart의 activityId 'course'
    // (lib/data/sori_activity_catalog.dart id: 'course')를 가리킨다 —
    // 번역 대상이 아닌 식별자라 항상 "course"를 담고 있다. 안의 실제
    // 문구는 이미 "Learning path"/"Your guided path..."로 개명됨.
    'soriStageActivityTitle',
    'soriStageActivityDescription',
  };

  final kursPattern = RegExp(r'\bkurs', caseSensitive: false);
  final coursePattern = RegExp(r'\bcourse\b', caseSensitive: false);

  test('no DE string outside the real-world-class allowlist says "Kurs"', () {
    final offenders = <String>[];
    de.forEach((key, value) {
      if (key.startsWith('@') || value is! String) {
        return;
      }
      if (kursAllowlist.contains(key)) {
        return;
      }
      if (kursPattern.hasMatch(value)) {
        offenders.add('$key: $value');
      }
    });
    expect(
      offenders,
      isEmpty,
      reason:
          '앱 기능은 이제 "Lernpfad"라고 부른다(W10 T-N1, Jin 결정 D-1). '
          '"Kurs"가 남아 있으면 위 예외 목록에 없는 새 회귀다:\n'
          '${offenders.join('\n')}',
    );
  });

  test(
    'no EN string outside the class/identifier allowlist says "course"',
    () {
      final offenders = <String>[];
      en.forEach((key, value) {
        if (key.startsWith('@') || value is! String) {
          return;
        }
        if (courseWordAllowlist.contains(key)) {
          return;
        }
        if (coursePattern.hasMatch(value)) {
          offenders.add('$key: $value');
        }
      });
      expect(
        offenders,
        isEmpty,
        reason:
            '앱 기능은 이제 "learning path"라고 부른다(W10 T-N1, Jin 결정 D-1). '
            '"course"가 남아 있으면 위 예외 목록에 없는 새 회귀다:\n'
            '${offenders.join('\n')}',
      );
    },
  );
}
