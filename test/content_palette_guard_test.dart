import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 콘텐츠 화면의 색 계약 — Jin 이 실제로 공부하는 표면에만 건다.
///
/// Jin 2026-08-19:
///  - "저 골든색은 카드에 쓰지말아줘 너무 답답해보여. 우리 컬러인 진한
///     그린쪽이나 레벨 버튼 쪽 하늘색으로 바꾸고"
///  - "hangul에서 지금 색상을 약간 골동색, 탁한 하늘, 그린배경 썼는데
///     뭔가 조잡해 색상이 너무 많달까???"
///
/// 규칙: CTA·강조는 녹청(primary/contentCta) 하나, 보조는 하늘(info) 하나.
/// 황(gold)은 **XP·스트릭 전용**이라 카드 위에는 못 온다. 석간주(accent/
/// like/hangul)는 하트·책갈피 같은 애정 표시 전용이다.
const _contentScreens = <String>[
  'grammar_screen',
  'hangul_screen',
  'daily_char_sheet',
  'listening_play_screen',
  'listening_screen',
  'smalltalk_screen',
  'vocab_pack_screen',
  'review_session_screen',
  'cloze_game_screen',
  'satz_arcade_screen',
  'scenario_player_screen',
  'custom_pack_play_screen',
  'legacy_vocab_screen',
];

/// 아직 못 걷어낸 자리. **줄어들기만 한다.**
const _pendingMigration = <String, Set<String>>{
  // XP 실적 표시 — 황의 정당한 용법이라 남긴다.
  'review_session_screen': {'SoriColors.gold'},
  // 콤보 팝은 카드가 아니라 떠오르는 보상 연출이다.
  'vocab_pack_screen': {'SoriColors.gold'},
};

String _codeOf(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .where((line) => !line.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  const banned = <String>[
    'SoriColors.gold',
    'SoriColors.goldOnLight',
    'SoriColors.onGoldFill',
    'SoriColors.tiger',
    'SoriColors.tigerOnLight',
    'SoriColors.warning',
    'SoriColors.darkSurface',
    'SoriColors.darkText',
    'SoriColors.darkTextMuted',
    'SoriColors.darkTextDim',
    'SoriColors.darkAccent',
    'SoriColors.darkPrimary',
  ];

  for (final screen in _contentScreens) {
    test('$screen 은 황·타이거·다크토큰을 카드에 쓰지 않는다', () {
      final path = 'lib/screens/$screen.dart';
      if (!File(path).existsSync()) {
        return;
      }
      final code = _codeOf(path);
      final allowed = _pendingMigration[screen] ?? const <String>{};
      for (final token in banned) {
        if (allowed.contains(token)) {
          continue;
        }
        expect(
          code,
          isNot(contains(token)),
          reason:
              '$screen 에 $token 이 남아 있다. 카드 강조는 녹청, 보조는 하늘, '
              '황은 XP 전용이다',
        );
      }
    });
  }

  test('허용목록은 줄어들기만 한다', () {
    final total = _pendingMigration.values.fold<int>(
      0,
      (sum, tokens) => sum + tokens.length,
    );
    expect(
      total,
      lessThanOrEqualTo(2),
      reason: '2026-08-19 실측 2건. 이 숫자는 내려가기만 한다',
    );
  });

  test('한글 화면은 다크 테마 토큰을 크림 배경 위에 쓰지 않는다', () {
    // `_DetailSheet` 는 밝은 앱 위의 거의 검정 카드였고, 섹션 라벨과
    // 탭바 비선택 색은 다크 테마용 회색이라 크림 위에서 대비가 낮았다.
    final code = _codeOf('lib/screens/hangul_screen.dart');
    expect(code, isNot(contains('SoriColors.dark')));
    expect(
      code,
      isNot(contains('SoriColors.hangul')),
      reason: '석간주는 하트·책갈피 전용 — 자음은 녹청, 모음은 하늘색',
    );
  });

  test('죽은 시각 파라미터가 되살아나지 않는다', () {
    // 둘 다 값이 전달되기만 하고 paint/build 에서 한 번도 안 읽혔다.
    expect(
      _codeOf('lib/screens/hangul_screen.dart'),
      isNot(contains('gradient:')),
    );
    expect(
      _codeOf('lib/widgets/stroke_canvas.dart'),
      isNot(contains('guideColor')),
    );
  });
}
