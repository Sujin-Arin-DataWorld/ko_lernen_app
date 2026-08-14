import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/learner_motivation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// **캐릭터 배선 회귀 가드** (2026-07-31).
///
/// 배경: `Storage.preferredMascot` 을 읽는 곳이 앱 전체에 3곳뿐이었고 홈은
/// 그중에 없어서, 까치를 골라도 홈·게임결과·레슨완료가 전부 호랑이였다.
///
/// ⚠️ 위젯 테스트로 "홈에 tiger_ 문자열이 없다"를 검사하면 **안 된다** —
/// 테스트 환경은 `TigerStageVideo.videoReady == false` 라 영상 경로를 아예
/// 타지 않으므로 배선이 끊겨 있어도 통과한다. 그래서 여기서는
/// **순수 함수**(에셋 선택 로직)와 **소스 스캔**(리터럴 잔존)으로 검증한다.
void main() {
  final t = AppL10nEn();

  group('MascotPreference — 단일 진입점', () {
    test('선택 가능 목록은 현재 캐릭터 두 종만 포함한다', () {
      expect(
        MascotPreference.selectableKinds,
        orderedEquals(const [MascotKind.tiger, MascotKind.magpie]),
      );
    });

    test('현재 선택 캐릭터만 parse/encode 왕복', () {
      expect(MascotPreference.parse('magpie'), MascotKind.magpie);
      expect(MascotPreference.parse('tiger'), MascotKind.tiger);
      // 미설정/오타는 기존 기본값(호랑이)로 — 회귀 0.
      expect(MascotPreference.parse(''), MascotKind.tiger);
      expect(MascotPreference.parse('kkachi'), MascotKind.tiger);
      for (final k in const [MascotKind.tiger, MascotKind.magpie]) {
        expect(MascotPreference.parse(MascotPreference.encode(k)), k);
      }
    });

    test('명시적 none은 레거시 기본 Tiger와 구별한다', () {
      expect(MascotPreference.decode('none'), CompanionPreference.none);
      expect(MascotPreference.decode('magpie'), CompanionPreference.magpie);
      expect(MascotPreference.decode(''), CompanionPreference.tiger);
      expect(MascotPreference.mascotKindFor(CompanionPreference.none), isNull);
    });

    test('폐기된 jieun/minsu 별칭은 호랑이로 정규화한다', () {
      for (final legacy in const [MascotKind.jieun, MascotKind.minsu]) {
        expect(MascotPreference.encode(legacy), 'tiger');
        expect(
          MascotPreference.parse(MascotPreference.encode(legacy)),
          MascotKind.tiger,
        );
      }
    });

    test('set() 은 폐기된 별칭을 notifier에 남기지 않는다', () async {
      addTearDown(() => MascotPreference.kind.value = MascotKind.tiger);
      for (final legacy in const [MascotKind.jieun, MascotKind.minsu]) {
        await MascotPreference.set(legacy);
        expect(MascotPreference.current, MascotKind.tiger);
      }
    });

    test('other() 는 반대쪽', () {
      expect(MascotPreference.other(MascotKind.tiger), MascotKind.magpie);
      expect(MascotPreference.other(MascotKind.magpie), MascotKind.tiger);
    });

    testWidgets('CompanionBuilder previews none without storage mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompanionBuilder(
            previewPreference: CompanionPreference.none,
            builder: (context, kind) => Mascot(kind: kind),
            noneBuilder: (context) => const Icon(
              Icons.person_outline_rounded,
              key: ValueKey('neutral-companion-slot'),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('neutral-companion-slot')), findsOne);
      expect(find.byType(Mascot), findsNothing);
    });
  });

  group('캐릭터별 클립 선택 — 두 캐릭터가 실제로 다르다', () {
    test('홈 히어로 밴드 (greet/pace)', () {
      expect(
        TigerStageVideo.greetFor(MascotKind.tiger),
        isNot(TigerStageVideo.greetFor(MascotKind.magpie)),
      );
      expect(
        TigerStageVideo.paceFor(MascotKind.tiger),
        isNot(TigerStageVideo.paceFor(MascotKind.magpie)),
      );
      expect(TigerStageVideo.greetFor(MascotKind.magpie), contains('magpie'));
      expect(TigerStageVideo.paceFor(MascotKind.magpie), contains('magpie'));
      expect(TigerStageVideo.greetFor(MascotKind.tiger), contains('tiger'));
    });

    test('세션 완료 / 생각 중 클립', () {
      expect(
        CharacterClips.sessionCompleteFor(MascotKind.magpie),
        contains('magpie'),
      );
      expect(
        CharacterClips.sessionCompleteFor(MascotKind.tiger),
        contains('tiger'),
      );
      expect(CharacterClips.thinkingFor(MascotKind.magpie), contains('magpie'));
      expect(CharacterClips.thinkingFor(MascotKind.tiger), contains('tiger'));
    });

    test('선택된 클립 파일이 실제로 존재한다', () {
      final assets = <String>{
        for (final k in MascotKind.values) ...[
          TigerStageVideo.greetFor(k),
          TigerStageVideo.paceFor(k),
          CharacterClips.sessionCompleteFor(k),
          CharacterClips.thinkingFor(k),
          CharacterClips.greetFor(k),
          CharacterClips.chooseFor(k),
        ],
      };
      for (final a in assets) {
        expect(File(a).existsSync(), isTrue, reason: '에셋 없음: $a');
      }
    });
  });

  group('캐릭터 목소리 — 어조만 다르고 구조는 같다', () {
    test('1일차 인사가 캐릭터별로 다르다', () {
      final tiger = homeTigerBubble(t, streak: 0, xp: 0);
      final magpie = homeTigerBubble(
        t,
        streak: 0,
        xp: 0,
        kind: MascotKind.magpie,
      );
      expect(tiger, isNot(magpie));
      expect(magpie, isNotEmpty);
    });

    test('재방문 인사가 캐릭터별로 다르다', () {
      final tiger = homeTigerBubble(t, streak: 1, xp: 40);
      final magpie = homeTigerBubble(
        t,
        streak: 1,
        xp: 40,
        kind: MascotKind.magpie,
      );
      expect(tiger, isNot(magpie));
    });

    test('kind 기본값은 호랑이 — 기존 호출부 회귀 0', () {
      expect(
        homeTigerBubble(t, streak: 0, xp: 0),
        homeTigerBubble(t, streak: 0, xp: 0, kind: MascotKind.tiger),
      );
    });
  });

  group('대비 자동 판정 — 디자인 규칙을 코드가 강제한다', () {
    test('밝은 채움 위에는 흰 글씨를 쓰지 않는다', () {
      // 규칙(2026-07-31 세션): gold·tiger 채움 위 흰 글씨 금지.
      expect(SoriColors.onFill(SoriColors.tiger), SoriColors.lightText);
      expect(SoriColors.onFill(SoriColors.gold), SoriColors.lightText);
      expect(SoriColors.onFill(SoriColors.warning), SoriColors.lightText);
      // 어두운 채움은 기존대로 흰 글씨.
      expect(SoriColors.onFill(SoriColors.primary), Colors.white);
      expect(SoriColors.onFill(SoriColors.accent), Colors.white);
      expect(SoriColors.onFill(SoriColors.danger), Colors.white);
    });

    test('onFill 결과는 항상 AA(4.5:1) 이상', () {
      const fills = <Color>[
        SoriColors.primary,
        SoriColors.accent,
        SoriColors.tiger,
        SoriColors.gold,
        SoriColors.warning,
        SoriColors.danger,
        SoriColors.info,
      ];
      for (final f in fills) {
        expect(
          SoriColors.contrastRatio(SoriColors.onFill(f), f),
          greaterThanOrEqualTo(4.5),
          reason: '채움 $f 위 글자 대비 미달',
        );
      }
    });

    test('배경과 3:1 미만인 채움에는 보강 테두리가 붙는다', () {
      const bg = SoriColors.lightBg;
      // tiger 는 배경 대비 2.14:1 → 테두리 필요.
      final edge = SoriColors.fillOutline(SoriColors.tiger, bg);
      expect(edge, isNotNull);
      expect(SoriColors.contrastRatio(edge!, bg), greaterThanOrEqualTo(3.0));
      // primary 는 4.80:1 → 불필요.
      expect(SoriColors.fillOutline(SoriColors.primary, bg), isNull);
    });

    test('contrastRatio 기준값', () {
      expect(
        SoriColors.contrastRatio(Colors.white, Colors.black),
        closeTo(21.0, 0.01),
      );
      expect(
        SoriColors.contrastRatio(SoriColors.lightText, SoriColors.lightBg),
        greaterThan(14.0),
      );
    });
  });

  group('소스 가드 — 하드코딩 재발 방지', () {
    test('selected-companion surfaces never read the legacy non-null kind', () {
      // Policy table: these surfaces personalize the learner's companion and
      // must therefore support explicit none. Fixed book/listening artwork and
      // an explicitly supplied GameOverCard mascot are authored brand/game
      // decoration, not a stored learner preference.
      const selectedCompanionFiles = <String>[
        'lib/screens/book_result_screen.dart',
        'lib/screens/chosung_quiz_screen.dart',
        'lib/screens/custom_pack_play_screen.dart',
        // home_screen.dart 는 Phase 4(79ae4a0) 레거시 삭제로 소멸 — 현 홈
        // 표면은 SoriStage Today + 공용 home_hero 다 (2026-08-14 죽은 참조 수리).
        'lib/screens/sori_stage/sori_stage_today_screen.dart',
        'lib/widgets/sori/home_hero.dart',
        'lib/screens/kkeunmari_screen.dart',
        'lib/screens/profile_screen.dart',
        'lib/screens/review_session_screen.dart',
        'lib/screens/scenario_player_screen.dart',
        'lib/screens/settings_screen.dart',
        'lib/screens/vocab_pack_result_screen.dart',
        'lib/widgets/sori/character_clip.dart',
        'lib/widgets/sori/game_reward.dart',
        'lib/widgets/sori/milestone_celebration.dart',
        'lib/widgets/sori/path_trail.dart',
        'lib/widgets/sori/tiger_video.dart',
      ];
      final offenders = <String>[];
      for (final path in selectedCompanionFiles) {
        final source = File(path).readAsStringSync();
        if (source.contains('MascotPreference.kind.value') ||
            source.contains('MascotPreference.current')) {
          offenders.add(path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'none을 stale Tiger로 바꾸는 legacy read: $offenders',
      );
    });

    test('brand/game character surfaces remain explicit', () {
      const authored = <String, String>{
        'lib/screens/listening_screen.dart': 'fallbackKind: MascotKind.magpie',
        'lib/widgets/sori/game_reward.dart': 'widget.mascotKind ??',
        'lib/screens/book_result_screen.dart':
            'Fixed book artwork is brand decoration',
      };
      for (final entry in authored.entries) {
        expect(
          File(entry.key).readAsStringSync(),
          contains(entry.value),
          reason: '${entry.key} lost its explicit surface classification',
        );
      }
    });

    test('결과·완료 화면에 MascotKind.tiger 리터럴이 없다', () {
      // ① 진짜 하드코딩이 있던 파일들. ② 승패 연출(won ? magpie : tiger)과
      // ③ 선택 화면은 대상이 아니다 — 여기 목록에 넣지 말 것.
      const guarded = <String>[
        'lib/screens/book_result_screen.dart',
        'lib/screens/chosung_quiz_screen.dart',
        'lib/screens/custom_pack_play_screen.dart',
        'lib/screens/vocab_pack_result_screen.dart',
        'lib/screens/review_session_screen.dart',
        'lib/screens/kkeunmari_screen.dart',
      ];
      final offenders = <String>[];
      for (final path in guarded) {
        final lines = File(path).readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final l = lines[i];
          if (!l.contains('MascotKind.tiger')) continue;
          // 승패 연출은 허용.
          if (l.contains('won ?') || l.contains('pct >=')) continue;
          offenders.add('$path:${i + 1}  ${l.trim()}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: '선택 캐릭터를 무시하는 하드코딩:\n${offenders.join('\n')}',
      );
    });

    test('홈은 s.textDim 을 쓰지 않는다 (2.89:1)', () {
      // home_screen.dart 삭제(79ae4a0) 후 현 홈 표면으로 재지정 (2026-08-14).
      for (final path in const [
        'lib/screens/sori_stage/sori_stage_today_screen.dart',
        'lib/widgets/sori/home_hero.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('s.textDim'), isFalse, reason: path);
      }
    });
  });
}
