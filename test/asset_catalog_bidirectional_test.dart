import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/pack_artwork_catalog.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/data/sticker_catalog.dart';
import 'package:ko_lernen_app/models/hanok_stage.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'package:ko_lernen_app/widgets/sori/gye_hanok.dart';
import 'package:ko_lernen_app/widgets/sori/placed_decoration.dart';

/// 카탈로그(코드) ↔ 실제 에셋 파일의 정합성 가드 — 5개 그룹, 그룹마다
/// 검사 방향이 다르다(각 `group` 주석에 방향 선택 근거).
///
/// `test/asset_orphan_guard_test.dart`(전 폴더, "stem 이 lib/ 소스 어딘가에
/// 문자열로 나타나는가"라는 느슨한 판정)와는 다르다 — 그 판정은 **다른
/// 이유로 우연히 같은 문자열이 lib/ 에 있어서** 통과하는 거짓 음성을
/// 놓친다(예: activities 그룹 참고). 여기는 그 폴더의 진짜 정본 — 실제로
/// import 되는 카탈로그 상수/enum, 또는 정본 매니페스트 — 하나와만
/// 대조한다.
Set<String> _stemsOf(Directory dir, {String? extension}) => dir
    .listSync()
    .whereType<File>()
    .map((f) => f.uri.pathSegments.last)
    .where((name) => extension == null || name.endsWith(extension))
    .map((name) => name.substring(0, name.lastIndexOf('.')))
    .toSet();

void main() {
  group('stickers', () {
    // 완전 양방향을 고른 이유: `kStickers` 는 코드(1~30) 연속성이 생명이라
    // 파일 쪽 결번(키→파일 누락)과 다 만든 뒤 카탈로그 등록을 잊은 파일
    // (파일→키 누락) 둘 다 배포 사고다 — 스티커 피커가 깨지거나 만든
    // 그림이 절대 안 뜬다.
    final catalogSlugs = kStickers.map((s) => s.slug).toSet();
    final fileStems = _stemsOf(Directory('assets/stickers'), extension: '.png');

    test('kStickers 30종 모두 PNG 파일이 있다 (키 → 파일)', () {
      final missing = catalogSlugs.difference(fileStems);
      expect(
        missing,
        isEmpty,
        reason: 'kStickers 에 있는데 assets/stickers/*.png 가 없습니다: $missing',
      );
    });

    test('assets/stickers 의 모든 PNG 가 kStickers 에 등록되어 있다 (파일 → 키)', () {
      final orphaned = fileStems.difference(catalogSlugs);
      expect(
        orphaned,
        isEmpty,
        reason:
            'assets/stickers/ 에 있는데 kStickers 에 없습니다(고아 또는 미등록): '
            '$orphaned',
      );
    });

    test('정본 30종 카운트가 어긋나지 않았다', () {
      expect(catalogSlugs.length, 30);
      expect(fileStems.length, 30);
    });
  });

  group('decorations', () {
    // 완전 양방향을 고른 이유: 정본이 `kAvailableDecorations`(코드 리터럴,
    // "실제로 PNG가 존재하는 장식 슬러그"라고 그 자리에 이미 문서화되어
    // 있다) ∪ `ildu_world_manifest_v1.json` 의 `decorations[].asset` 두
    // 곳에 흩어져 있다 — 사람이 둘 중 하나만 갱신하고 다른 하나를 잊으면
    // ① 그림은 있는데 어디서도 안 부르는 고아, ② 코드/manifest 는 부르는데
    // 그림이 없어 런타임 폴백(플레이스홀더)으로 새는 두 사고가 다 난다.
    late Set<String> catalogSlugs;
    late Set<String> fileStems;

    setUpAll(() {
      final manifest =
          jsonDecode(
                File(
                  'assets/data/ildu_world_manifest_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final manifestSlugs = (manifest['decorations'] as List)
          .cast<Map<String, dynamic>>()
          .map((d) => d['asset'] as String)
          .where((asset) => asset.endsWith('.png'))
          .map((asset) => asset.substring(0, asset.length - 4))
          .toSet();
      catalogSlugs = {...kAvailableDecorations, ...manifestSlugs};
      fileStems = _stemsOf(
        Directory('assets/illustrations/decorations'),
        extension: '.png',
      );
    });

    test('정본 슬러그는 모두 PNG 파일이 있다 (키 → 파일)', () {
      final missing = catalogSlugs.difference(fileStems);
      expect(
        missing,
        isEmpty,
        reason:
            'kAvailableDecorations 또는 ildu_world_manifest_v1.json 에 있는데 '
            'assets/illustrations/decorations/*.png 가 없습니다: $missing',
      );
    });

    test('모든 decoration PNG 가 lib 리터럴 또는 manifest 에 등장한다 (파일 → 키)', () {
      final orphaned = fileStems.difference(catalogSlugs);
      expect(
        orphaned,
        isEmpty,
        reason:
            'assets/illustrations/decorations/ 에 있는데 kAvailableDecorations 에도 '
            'ildu_world_manifest_v1.json 에도 없습니다(고아): $orphaned',
      );
    });
  });

  group('gye', () {
    // 완전 양방향을 고른 이유: `_elements` 는 `GyeHanok` 이 매주 진행도에
    // 따라 순서대로 실체화하는 **고정 8장 세트** — 한 장이라도 파일이
    // 없으면 그 주의 진행도 연출이 깨지고(키→파일), 반대로 만들어 놓고
    // `_elements` 에 못 넣은 그림은 영원히 안 뜬다(파일→키). `_elements` 는
    // `_GyeHanokState` 비공개 필드라 import 할 수 없어 소스 텍스트에서
    // 슬러그 리터럴을 그대로 뽑는다.
    late Set<String> elementSlugs;
    late Set<String> fileStems;

    setUpAll(() {
      final source = File('lib/widgets/sori/gye_hanok.dart').readAsStringSync();
      elementSlugs = RegExp(
        r"slug: '(gye_[a-zA-Z0-9_]+)'",
      ).allMatches(source).map((m) => m.group(1)!).toSet();
      final showcaseStem = GyeShowcaseArtwork.asset
          .split('/')
          .last
          .split('.')
          .first;
      elementSlugs = {...elementSlugs, showcaseStem};
      fileStems = Directory('assets/illustrations/gye')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .map((name) => name.substring(0, name.lastIndexOf('.')))
          .toSet();
    });

    test('_elements 슬러그 8종 + showcase 모두 파일이 있다 (키 → 파일)', () {
      // 8 개별 요소 + 1 showcase courtyard = 9.
      expect(elementSlugs.length, 9);
      final missing = elementSlugs.difference(fileStems);
      expect(
        missing,
        isEmpty,
        reason:
            'gye_hanok.dart 가 참조하는데 assets/illustrations/gye/ 에 없습니다: $missing',
      );
    });

    test('assets/illustrations/gye 의 모든 파일이 코드에 등장한다 (파일 → 키)', () {
      final orphaned = fileStems.difference(elementSlugs);
      expect(
        orphaned,
        isEmpty,
        reason:
            'assets/illustrations/gye/ 에 있는데 gye_hanok.dart 의 _elements/showcase 에 '
            '없습니다(고아): $orphaned',
      );
    });
  });

  group('hanok_stages', () {
    // 단방향(키 → 파일)만 고른 이유: `HanokStage` 12종은 진행도 cascade 가
    // 정확히 12단계일 것을 전제한다 — 파일 결번은 그 단계에서 즉시
    // 그라데이션 폴백으로 샌다(과거 sidebuilding 오타 사고, 이 파일 주석
    // 참고). 반대로 `_dark` 파일은 **아직 없는 것이 의도**(라이트 테마만
    // 우선 제작)이므로 파일→키 역방향은 강제하지 않고, 있어도(light 만)
    // 실패시키지 않는다 — dark 부재를 실패로 만들면 다음 다크 아트 드롭
    // 전까지 이 테스트가 영구히 빨간불이 된다.
    test('assetSlug 12종 모두 stage_{slug}_light.png 가 있다 (키 → 파일)', () {
      expect(HanokStage.values.length, 12);
      final missing = <String>[];
      for (final stage in HanokStage.values) {
        final path =
            'assets/illustrations/hanok_stages/stage_${stage.assetSlug}_light.png';
        if (!File(path).existsSync()) missing.add(path);
      }
      expect(
        missing,
        isEmpty,
        reason: 'HanokStage.assetSlug 인데 파일이 없습니다: $missing',
      );
    });

    test('모든 stage_*_light.png 가 assetSlug 에 등장한다 (파일 → 키, light 만)', () {
      final slugs = HanokStage.values.map((s) => s.assetSlug).toSet();
      final lightStems = Directory('assets/illustrations/hanok_stages')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.endsWith('_light.png'))
          .map(
            (name) => name.substring(
              'stage_'.length,
              name.length - '_light.png'.length,
            ),
          );
      final orphaned = lightStems
          .where((slug) => !slugs.contains(slug))
          .toList();
      expect(
        orphaned,
        isEmpty,
        reason:
            'stage_*_light.png 인데 HanokStage.assetSlug 어디에도 없습니다(고아): $orphaned',
      );
    });
  });

  group('activities and packs', () {
    // 파일→키 단방향만 고른 이유(pubspec.yaml:177-182 주석 근거): 두 폴더
    // 모두 "파일이 없으면 코드가 폴백을 그린다"는 규약으로 설계됐다
    // (activities = ActivityIconFallback 원형 아이콘, packs = 단청 도장
    // 폴백) — 아트 드롭 전에도 화면이 정상 배포되게 하기 위한 의도적
    // 결번이라 키→파일 방향을 넣으면 그 설계를 어기고 매번 실패한다.
    // 반대로 파일이 있는데 카탈로그에 없는 stem 은 순수한 낭비(고아
    // webp)이거나 이름이 다른 카탈로그(예: `discover_catalog.dart`)의 id 와
    // 우연히 같아 `asset_orphan_guard_test.dart` 의 느슨한 substring 판정만
    // 통과하고 실제로는 아무 코드도 안 부르는 상태일 수 있어 여기서 잡는다.
    // 2026-09-01 감사 실측 — discover_catalog id와 이름만 겹치는 고아. 카탈로그
    // 매핑은 Jin 결정 대기. 이 목록은 줄이기만 한다.
    // 2026-09-05 W10 T-L2 — 'vocab_notebook' 카드가 카탈로그에서 빠졌지만
    // 라우트/화면은 그대로 살아 있다(같은 사유: discover_catalog id와 이름만
    // 겹침). discover_catalog.dart 는 IconData 만 쓰고 자산 경로를 갖지
    // 않아 이 webp 를 옮길 곳이 없다 — 같은 패턴이라 여기 합류시킨다.
    const activitiesOrphanAllowlist = <String>{
      'bookshelf',
      'book_capture',
      'hard_words',
      'word_search',
      'vocab_notebook',
    };

    test('모든 activities/*.webp 가 soriActivityCatalog 의 id 다', () {
      final ids = soriActivityCatalog.map((e) => e.id).toSet();
      final fileStems = _stemsOf(
        Directory('assets/illustrations/activities'),
        extension: '.webp',
      );
      final orphaned = fileStems
          .difference(ids)
          .difference(activitiesOrphanAllowlist);
      expect(
        orphaned,
        isEmpty,
        reason:
            'assets/illustrations/activities/ 에 있는데 soriActivityCatalog 의 어느 '
            'id 와도 안 맞습니다(고아 또는 다른 카탈로그와 이름만 겹침): $orphaned',
      );
    });

    test('모든 packs/*.webp 가 보상 모티프 또는 승인된 팩 ID다', () {
      final names = {
        ...DancheongMotif.values.map((m) => m.name),
        ...PackArtworkCatalog.dedicatedPackIds,
      };
      final fileStems = _stemsOf(
        Directory('assets/illustrations/packs'),
        extension: '.webp',
      );
      final orphaned = fileStems.difference(names);
      expect(
        orphaned,
        isEmpty,
        reason:
            'assets/illustrations/packs/ 에 있는데 보상 모티프나 승인된 팩 ID 어느 '
            '쪽에도 없습니다(고아): $orphaned',
      );
    });

    test('25개 보상 모티프가 모두 PACKS WebP를 가진다', () {
      final motifNames = DancheongMotif.values
          .map((motif) => motif.name)
          .toSet();
      final fileStems = _stemsOf(
        Directory('assets/illustrations/packs'),
        extension: '.webp',
      );
      final missing = motifNames.difference(fileStems);

      expect(DancheongMotif.values.length, 25);
      expect(missing, isEmpty, reason: 'PACKS WebP가 없는 보상 모티프: $missing');
    });

    test('승인된 팩 ID는 CSV에 존재하고 전용 WebP를 가진다', () {
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(File('assets/data/korean_vocab.csv').readAsStringSync());
      final header = rows.first.map((cell) => cell.toString()).toList();
      final packIdColumn = header.indexOf('pack_id');
      expect(packIdColumn, greaterThanOrEqualTo(0));

      final csvPackIds = rows
          .skip(1)
          .map((row) => row[packIdColumn].toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      final unknown = PackArtworkCatalog.dedicatedPackIds.difference(
        csvPackIds,
      );
      final missingFiles = PackArtworkCatalog.dedicatedPackIds
          .where(
            (id) => !File('assets/illustrations/packs/$id.webp').existsSync(),
          )
          .toList();

      expect(unknown, isEmpty, reason: 'CSV에 없는 전용 팩 ID: $unknown');
      expect(missingFiles, isEmpty, reason: '전용 WebP가 없는 팩 ID: $missingFiles');
      expect(PackArtworkCatalog.dedicatedPackIds.length, 113);
    });
  });

  group('stamps', () {
    // 완전 양방향을 고른 이유: 코드→파일(모든 DancheongMotif 에 stamp_*.png
    // 가 있다)은 dancheong_stamp_test.dart 가 이미 강제하지만, 파일→enum
    // 역방향(고아 stamp_*.png 탐지)은 이 그룹이 최초다.
    final names = DancheongMotif.values.map((m) => m.name).toSet();
    final fileStems =
        _stemsOf(Directory('assets/illustrations/stamps'), extension: '.png')
            .map((stem) => stem.startsWith('stamp_') ? stem.substring(6) : stem)
            .toSet();

    test('DancheongMotif 의 모든 name 에 stamp_*.png 가 있다 (키 → 파일)', () {
      final missing = names.difference(fileStems);
      expect(
        missing,
        isEmpty,
        reason:
            'DancheongMotif 에 있는데 assets/illustrations/stamps/stamp_*.png 가 '
            '없습니다: $missing',
      );
    });

    test('모든 stamp_*.png 가 DancheongMotif 의 name 이다 (파일 → 키)', () {
      final orphaned = fileStems.difference(names);
      expect(
        orphaned,
        isEmpty,
        reason:
            'assets/illustrations/stamps/ 에 있는데 DancheongMotif 의 어느 name 과도 '
            '안 맞습니다(고아): $orphaned',
      );
    });
  });
}
