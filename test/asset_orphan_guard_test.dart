import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 번들에 들어가는데 아무도 안 부르는 에셋을 잡는 **전 폴더** 가드.
/// (2026-08-07 신설 — docs/ASSET_INVENTORY_2026-08-06.md §"가드 사각지대")
///
/// 왜 필요했나. pubspec 에 등록된 에셋 폴더 22 개 중 디렉터리를 스캔하는
/// 테스트가 있는 것은 3 개뿐이었고, 그마저 `video/loops` 하나만 양방향이었다.
/// 그래서 `scenes/pharmacy.png`(1.6MB)·`decorations/dokkaebi_fire.png`(786KB)·
/// `video/character/magpie_right_walking_flying.mp4`(1.98MB) 가 전부 "APK 에는
/// 들어가지만 코드가 부르지 않는" 상태로 오래 살아남았다. AAB 기기별 다운로드
/// 여유가 10MB 뿐이라 무시할 크기가 아니다.
///
/// 판정. 파일명 또는 확장자를 뗀 stem 이 `lib/` 의 Dart 소스 어디에도 문자열로
/// 안 나타나면 고아로 본다. 카테고리 조립(`'scenes/$key.png'`)은 key 가
/// 소스에 리터럴로 있으므로 stem 검사에 걸린다 — 실제로 `pharmacy` 는 이 방식
/// 으로 잡혔을 것이다.
void main() {
  /// 런타임에 경로를 통째로 조립해 파일명이 소스에 안 나타나는 폴더.
  ///
  /// 면제는 공짜가 아니다 — 아래 `조립 근거` 문자열이 `lib/` 에 실제로 있어야
  /// 하고, 없으면 그 폴더를 렌더하는 코드가 사라졌다는 뜻이라 테스트가 깨진다.
  /// 면제 폴더를 늘릴 때는 반드시 근거 문자열을 함께 적을 것.
  const dynamicDirs = <String, String>{
    // 학습경로 헤더가 진행 단계에 따라 `stage_*_light.png` 를 고른다.
    'assets/illustrations/hanok_stages/': 'hanok_stages/',
    // 도장은 획득 id 로 `stamp_*.png` 를 조립한다.
    'assets/illustrations/stamps/': 'illustrations/stamps/',
  };

  /// 앱이 아니라 **테스트**가 읽는 번들 파일. 지우면 그 테스트가 깨진다.
  const testOnlyAssets = <String, String>{
    'assets/data/content_audit_manifest.json':
        'test/content_audit_manifest_test.dart 가 콘텐츠 수량 기준선으로 읽는다',
  };

  late final String libSource;
  late final List<String> assetDirs;

  setUpAll(() {
    libSource = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    // pubspec 의 `assets:` 항목. Flutter 는 디렉터리를 **비재귀**로 포함하므로
    // 여기 적힌 폴더의 직속 파일만이 번들 대상이다 — 같은 규칙으로 훑는다.
    assetDirs = RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true)
        .allMatches(File('pubspec.yaml').readAsStringSync())
        .map((m) => m.group(1)!)
        .toList();
  });

  test('pubspec 에 등록된 에셋 폴더를 실제로 찾았다', () {
    // 이 가드가 조용히 0 개를 훑고 통과하는 사고를 막는다.
    expect(assetDirs.length, greaterThan(15));
  });

  test('면제 폴더는 조립 근거가 lib/ 에 살아 있다', () {
    dynamicDirs.forEach((dir, evidence) {
      expect(
        libSource.contains(evidence),
        isTrue,
        reason:
            '$dir 를 동적 조립 폴더로 면제했는데 lib/ 에 "$evidence" 가 '
            '없습니다 — 렌더 코드가 사라졌다면 폴더째 고아입니다',
      );
    });
  });

  test('번들에 들어가는 모든 에셋을 lib/ 가 부른다', () {
    final orphans = <String>[];

    for (final dir in assetDirs) {
      if (dynamicDirs.containsKey(dir)) continue;
      final d = Directory(dir);
      if (!d.existsSync()) continue;

      for (final f in d.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.startsWith('.')) continue; // .gitkeep 등
        if (testOnlyAssets.containsKey('$dir$name')) continue;

        final stem = name.contains('.')
            ? name.substring(0, name.lastIndexOf('.'))
            : name;
        if (libSource.contains(name) || libSource.contains(stem)) continue;

        final kb = (f.lengthSync() / 1024).round();
        orphans.add('$dir$name (${kb}KB)');
      }
    }

    expect(
      orphans,
      isEmpty,
      reason:
          '이 파일들은 AAB 에 들어가는데 lib/ 어디서도 안 부릅니다.\n'
          '셋 중 하나를 하세요 — ① 실제로 배선한다, '
          '② assets_unused/pending_review/ 로 격리하고 README 에 사유·복원조건을 '
          '적는다, ③ 런타임 조립이면 dynamicDirs 에 조립 근거와 함께 등록한다.\n'
          '${orphans.join('\n')}',
    );
  });
}
