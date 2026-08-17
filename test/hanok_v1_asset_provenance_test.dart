import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _manifestPath = 'docs/assets/HANOK_V1_ASSET_PROVENANCE.json';

void main() {
  late Map<String, dynamic> manifest;

  setUpAll(() {
    final file = File(_manifestPath);
    expect(
      file.existsSync(),
      isTrue,
      reason: '한옥 V1 provenance 계약이 없으면 외부 생성은 fail-closed다.',
    );
    manifest = _object(jsonDecode(file.readAsStringSync()), _manifestPath);
  });

  group('Hanok V1 camera and runtime asset contract', () {
    test(
      'uses the exact north-up camera, canvas, socket, and absolute anchor',
      () {
        final camera = _object(manifest['camera'], 'camera');
        expect(
          _string(camera['id'], 'camera.id'),
          'personal_map_north_up_oblique_v2',
        );
        expect(
          _string(camera['orientation'], 'camera.orientation'),
          'north_up',
        );
        expect(
          _string(camera['lightDirection'], 'camera.lightDirection'),
          'top_left',
        );

        final canvas = _object(camera['canvas'], 'camera.canvas');
        expect(_integer(canvas['width'], 'camera.canvas.width'), 1536);
        expect(_integer(canvas['height'], 'camera.canvas.height'), 1152);

        final socket = _object(camera['socket'], 'camera.socket');
        final x = _integer(socket['x'], 'camera.socket.x');
        final y = _integer(socket['y'], 'camera.socket.y');
        final width = _integer(socket['width'], 'camera.socket.width');
        final height = _integer(socket['height'], 'camera.socket.height');
        expect((x, y, width, height), (160, 614, 854, 309));
        expect(_integer(socket['zGroup'], 'camera.socket.zGroup'), 22);

        final anchor = _object(
          socket['anchorCanvas'],
          'camera.socket.anchorCanvas',
        );
        final anchorX = _integer(anchor['x'], 'camera.socket.anchorCanvas.x');
        final anchorY = _integer(anchor['y'], 'camera.socket.anchorCanvas.y');
        expect((anchorX, anchorY), (587, 923));
        expect(anchorX, x + width ~/ 2);
        expect(anchorY, y + height);
        expect(x + width, lessThanOrEqualTo(1536));
        expect(y + height, lessThanOrEqualTo(1152));
      },
    );

    test(
      'declares all A1 01-16 files without pretending they already ship',
      () {
        final limits = _object(manifest['runtimeLimits'], 'runtimeLimits');
        final states = _object(
          limits['a1ConstructionStates'],
          'runtimeLimits.a1ConstructionStates',
        );
        expect(
          _string(states['root'], 'a1ConstructionStates.root'),
          'assets/illustrations/personal_hanok_v2/a1/states/',
        );
        expect(
          _string(states['deliveryMilestone'], 'deliveryMilestone'),
          'PR4',
        );
        expect(_integer(states['width'], 'a1ConstructionStates.width'), 1536);
        expect(_integer(states['height'], 'a1ConstructionStates.height'), 1152);
        expect(
          _string(states['format'], 'a1ConstructionStates.format'),
          'WebP',
        );
        expect(
          _string(states['colorMode'], 'a1ConstructionStates.colorMode'),
          'RGB',
        );
        expect(_integer(states['hardMaxBytes'], 'hardMaxBytes'), 350000);
        expect(
          _integer(limits['decodedMemoryMaxBytes'], 'decodedMemoryMaxBytes'),
          33554432,
        );
        expect(
          _strings(states['forbiddenBakedElements'], 'forbiddenBakedElements'),
          ['ui', 'text', 'watermark'],
        );
        expect(_strings(states['expectedFiles'], 'expectedFiles'), const [
          '01_site_setout.webp',
          '02_plan_layout.webp',
          '03_foundation_gidan.webp',
          '04_cornerstones_choseok.webp',
          '05_timber_preparation.webp',
          '06_columns.webp',
          '07_beams_changbang.webp',
          '08_purlins_sangnyang.webp',
          '09_rafters_roof_frame.webp',
          '10_roof_base.webp',
          '11_choga_roof.webp',
          '12_wall_frame_sujang.webp',
          '13_earth_walls.webp',
          '14_ondol_maru.webp',
          '15_changho_finish.webp',
          '16_landscape_move_in.webp',
        ]);
      },
    );
  });

  group('Model-input provenance', () {
    test(
      'allowlist is exact, project-owned, metadata-checked, and hash-locked',
      () async {
        final inputs = _objects(
          manifest['allowedModelInputs'],
          'allowedModelInputs',
        );
        final byPath = {
          for (final input in inputs)
            _string(input['path'], 'allowedModelInputs.path'): input,
        };
        expect(byPath.keys, {
          'assets/illustrations/personal_hanok_v2/map/site_base_light.png',
          'assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png',
          'assets_unused/pending_review/reference_full_estate.png',
        });

        final expectedRoles = {
          'assets/illustrations/personal_hanok_v2/map/site_base_light.png': (
            'site_base',
            'standard',
            true,
          ),
          'assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png':
              ('completed_house_source', 'standard', true),
          'assets_unused/pending_review/reference_full_estate.png': (
            'qa_composite',
            'optional_qa_context_only',
            false,
          ),
        };

        for (final entry in byPath.entries) {
          final input = entry.value;
          final expected = expectedRoles[entry.key]!;
          expect(_string(input['role'], '${entry.key}.role'), expected.$1);
          expect(_string(input['usage'], '${entry.key}.usage'), expected.$2);
          expect(
            _boolean(input['runtime'], '${entry.key}.runtime'),
            expected.$3,
          );

          final file = File(entry.key);
          expect(
            await file.exists(),
            isTrue,
            reason: '${entry.key} is missing',
          );
          final bytes = await file.readAsBytes();
          expect(
            sha256.convert(bytes).toString(),
            _sha256(input['sha256'], '${entry.key}.sha256'),
            reason: '${entry.key} changed without provenance review',
          );

          final metadata = _object(
            input['fileMetadata'],
            '${entry.key}.fileMetadata',
          );
          expect(_string(metadata['format'], '${entry.key}.format'), 'PNG');
          expect(
            _integer(metadata['bytes'], '${entry.key}.bytes'),
            bytes.length,
          );
          final png = _readPngMetadata(bytes, entry.key);
          expect(_integer(metadata['width'], '${entry.key}.width'), png.width);
          expect(
            _integer(metadata['height'], '${entry.key}.height'),
            png.height,
          );
          expect(
            _string(metadata['colorMode'], '${entry.key}.colorMode'),
            png.colorMode,
          );

          final rights = _object(
            input['rightsAttestation'],
            '${entry.key}.rights',
          );
          expect(
            _string(rights['basis'], '${entry.key}.rights.basis'),
            anyOf(
              'original_or_authorized_project_asset',
              'deterministic_composite_of_authorized_project_assets',
            ),
          );
          expect(
            _string(rights['owner'], '${entry.key}.rights.owner'),
            'Hangul Sori / Sujin Park',
          );
          expect(
            _string(
              rights['thirdPartyVisualReferences'],
              '${entry.key}.rights.thirdPartyVisualReferences',
            ),
            'none_uploaded',
          );
        }
      },
    );

    test(
      'keeps screenshots, Vivasam, legacy Hanok, and Gye in distinct policies',
      () {
        final restricted = {
          for (final source in _objects(
            manifest['restrictedSources'],
            'restrictedSources',
          ))
            _string(source['id'], 'restrictedSources.id'): source,
        };
        expect(restricted.keys, {
          'user_attached_screenshots',
          'vivasam',
          'legacy_personal_hanok',
          'gye_art',
        });

        for (final id in const ['user_attached_screenshots', 'vivasam']) {
          final source = restricted[id]!;
          expect(
            _string(source['classification'], '$id.classification'),
            'reference_only_user_supplied',
          );
          expect(
            _string(source['runtimePolicy'], '$id.runtimePolicy'),
            'not_shipped',
          );
          expect(
            _string(source['modelInputPolicy'], '$id.modelInputPolicy'),
            'forbidden',
          );
          expect(
            _string(source['derivativePolicy'], '$id.derivativePolicy'),
            'copy_trace_recolor_forbidden',
          );
        }

        final legacy = restricted['legacy_personal_hanok']!;
        expect(
          _string(legacy['runtimePolicy'], 'legacy.runtimePolicy'),
          'currently_shipped_but_superseded_until_pr7',
        );
        expect(
          _string(legacy['modelInputPolicy'], 'legacy.modelInputPolicy'),
          'forbidden',
        );

        final gye = restricted['gye_art']!;
        expect(
          _string(gye['runtimePolicy'], 'gye.runtimePolicy'),
          'gye_runtime_only',
        );
        expect(
          _string(gye['modelInputPolicy'], 'gye.modelInputPolicy'),
          'forbidden',
        );
        expect(
          _string(gye['derivativePolicy'], 'gye.derivativePolicy'),
          'personal_hanok_reuse_forbidden',
        );
      },
    );

    test(
      'QA composite is optional model context and never a runtime asset',
      () {
        final qa = _object(manifest['qaComposite'], 'qaComposite');
        expect(
          _string(qa['path'], 'qaComposite.path'),
          'assets_unused/pending_review/reference_full_estate.png',
        );
        expect(_boolean(qa['runtime'], 'qaComposite.runtime'), isFalse);
        expect(
          _string(qa['modelInputUsage'], 'qaComposite.modelInputUsage'),
          'optional_qa_context_only',
        );
        final policy = _object(
          manifest['personalHanokRuntimePolicy'],
          'personalHanokRuntimePolicy',
        );
        expect(
          _strings(policy['forbiddenFragments'], 'forbiddenFragments'),
          contains('reference_full_estate.png'),
        );
      },
    );
  });

  group('Generation ledger and progression separation', () {
    test('declares a machine-readable zero-call generation ledger', () {
      final ledger = _object(manifest['generationLedger'], 'generationLedger');
      expect(
        _integer(ledger['schemaVersion'], 'generationLedger.schemaVersion'),
        1,
      );
      expect(
        _string(ledger['hashAlgorithm'], 'generationLedger.hashAlgorithm'),
        'sha256',
      );
      final budgets = _object(
        ledger['budgetCredits'],
        'generationLedger.budgetCredits',
      );
      expect(_number(budgets['staticMax'], 'budgetCredits.staticMax'), 200.0);
      expect(_number(budgets['videoMax'], 'budgetCredits.videoMax'), 10.4);
      expect(_number(budgets['totalMax'], 'budgetCredits.totalMax'), 210.4);
      final schema = _object(
        ledger['recordSchema'],
        'generationLedger.recordSchema',
      );
      expect(
        _strings(schema['requiredFields'], 'recordSchema.requiredFields'),
        [
          'id',
          'provider',
          'model',
          'mediaKind',
          'occurredAtUtc',
          'costCredits',
          'promptSha256',
          'inputAssets',
          'outputAssets',
        ],
      );
      expect(_strings(schema['inputAssetFields'], 'inputAssetFields'), [
        'path',
        'sha256',
      ]);
      expect(_strings(schema['outputAssetFields'], 'outputAssetFields'), [
        'path',
        'sha256',
        'decision',
      ]);
        expect(_list(ledger['records'], 'generationLedger.records'), isEmpty);
    });

    test('locks the transparent socket compositor and atomic promotion', () {
      final contract = _object(
        manifest['a1TransparentLayerContract'],
        'a1TransparentLayerContract',
      );
      final socket = _object(contract['socketLayer'], 'socketLayer');
      expect(_integer(socket['width'], 'socketLayer.width'), 854);
      expect(_integer(socket['height'], 'socketLayer.height'), 309);
      final anchor = _object(socket['localAnchor'], 'socketLayer.localAnchor');
      expect((_integer(anchor['x'], 'localAnchor.x'), _integer(anchor['y'], 'localAnchor.y')), (427, 309));
      final output = _object(contract['output'], 'output');
      expect(_string(output['format'], 'output.format'), 'WebP');
      expect(_integer(output['quality'], 'output.quality'), 82);
      expect(_integer(output['method'], 'output.method'), 6);
      expect(_integer(output['hardMaxBytes'], 'output.hardMaxBytes'), 350000);
      final qa = _object(contract['qa'], 'qa');
      expect(_integer(qa['sourceOutsideChangedPixels'], 'sourceOutsideChangedPixels'), 0);
      expect(_number(qa['decodedOutsideMeanErrorMax'], 'decodedOutsideMeanErrorMax'), 5.0);
      final continuity = _object(contract['continuity'], 'continuity');
      expect(_number(continuity['minPreviousRecall'], 'minPreviousRecall'), 0.97);
      expect(_integer(continuity['maxEdgeDriftPx'], 'maxEdgeDriftPx'), 2);
      final promotion = _object(contract['promotion'], 'promotion');
      expect(
        _string(promotion['qaRoot'], 'promotion.qaRoot'),
        'assets_unused/pending_review/a1_states/',
      );
      expect(
        _string(promotion['runtimeRoot'], 'promotion.runtimeRoot'),
        'assets/illustrations/personal_hanok_v2/a1/states/',
      );
      expect(_boolean(promotion['atomic'], 'promotion.atomic'), isTrue);
      expect(
        _boolean(promotion['pubspecUntilComplete'], 'pubspecUntilComplete'),
        isFalse,
      );
    });

    test('resolves the site base by role, not allowlist index', () {
      final inputs = _objects(
        manifest['allowedModelInputs'],
        'allowedModelInputs',
      );
      final siteBases = [
        for (final input in inputs)
          if (_string(input['role'], 'allowedModelInputs.role') == 'site_base')
            input,
      ];
      expect(siteBases, hasLength(1));
      expect(
        _string(siteBases.single['path'], 'site_base.path'),
        'assets/illustrations/personal_hanok_v2/map/site_base_light.png',
      );
    });

    test('does not register unapproved A1 states or the QA composite in pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('personal_hanok_v2/a1/'), isFalse);
      expect(pubspec.contains('reference_full_estate.png'), isFalse);
      expect(pubspec.contains('assets_unused/'), isFalse);
      expect(
        Directory('assets/illustrations/personal_hanok_v2/a1/states').existsSync(),
        isFalse,
      );
    });

    test(
      'future generation records fail closed on rights, hashes, and budget',
      () {
        final ledger = _object(
          manifest['generationLedger'],
          'generationLedger',
        );
        final budgets = _object(
          ledger['budgetCredits'],
          'generationLedger.budgetCredits',
        );
        final allowedInputs = {
          for (final input in _objects(
            manifest['allowedModelInputs'],
            'allowedModelInputs',
          ))
            _string(input['path'], 'allowedModelInputs.path'): _sha256(
              input['sha256'],
              'allowedModelInputs.sha256',
            ),
        };
        final knownInputs = Map<String, String>.from(allowedInputs);
        final records = _objects(ledger['records'], 'generationLedger.records');
        final ids = <String>{};
        var staticCredits = 0.0;
        var videoCredits = 0.0;

        for (final record in records) {
          final id = _string(record['id'], 'generationRecord.id');
          expect(
            ids.add(id),
            isTrue,
            reason: 'duplicate generation record $id',
          );
          _string(record['provider'], '$id.provider');
          _string(record['model'], '$id.model');
          final mediaKind = _string(record['mediaKind'], '$id.mediaKind');
          expect(mediaKind, anyOf('static', 'video'));
          final occurredAt = _string(
            record['occurredAtUtc'],
            '$id.occurredAtUtc',
          );
          final parsed = DateTime.tryParse(occurredAt);
          expect(
            parsed != null && parsed.isUtc && occurredAt.endsWith('Z'),
            isTrue,
            reason: '$id.occurredAtUtc must be canonical UTC',
          );
          final credits = _number(record['costCredits'], '$id.costCredits');
          expect(credits, greaterThan(0));
          _sha256(record['promptSha256'], '$id.promptSha256');

          for (final input in _objects(
            record['inputAssets'],
            '$id.inputAssets',
          )) {
            final path = _string(input['path'], '$id.inputAssets.path');
            expect(
              knownInputs[path],
              _sha256(input['sha256'], '$id.inputAssets.sha256'),
              reason: '$id used a non-allowlisted or unapproved derived input',
            );
          }
          for (final output in _objects(
            record['outputAssets'],
            '$id.outputAssets',
          )) {
            final path = _string(output['path'], '$id.outputAssets.path');
            expect(
              path.contains('..') || RegExp(r'^[A-Za-z]:').hasMatch(path),
              isFalse,
            );
            final digest = _sha256(output['sha256'], '$id.outputAssets.sha256');
            final decision = _string(
              output['decision'],
              '$id.outputAssets.decision',
            );
            expect(decision, anyOf('approved', 'rejected'));
            if (decision == 'approved') {
              knownInputs[path] = digest;
            }
          }

          if (mediaKind == 'static') {
            staticCredits += credits;
          } else {
            videoCredits += credits;
          }
        }

        expect(
          staticCredits,
          lessThanOrEqualTo(_number(budgets['staticMax'], 'staticMax')),
        );
        expect(
          videoCredits,
          lessThanOrEqualTo(_number(budgets['videoMax'], 'videoMax')),
        );
        expect(
          staticCredits + videoCredits,
          lessThanOrEqualTo(_number(budgets['totalMax'], 'totalMax')),
        );
      },
    );

    test('lets an approved ledger output seed the next transparent layer', () {
      final allowed = {
        'assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png':
            'f523e93ff70040cef5066ee93caeb1e2ce54a3b19625bc615ac02c4c336dbff1',
      };
      final known = Map<String, String>.from(allowed);
      const derived =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      for (final record in [
        {
          'inputAssets': [
            {
              'path':
                  'assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png',
              'sha256': allowed.values.single,
            },
          ],
          'outputAssets': [
            {
              'path':
                  'assets_unused/pending_review/a1_layers/06_columns_layer.png',
              'sha256': derived,
              'decision': 'approved',
            },
          ],
        },
        {
          'inputAssets': [
            {
              'path':
                  'assets_unused/pending_review/a1_layers/06_columns_layer.png',
              'sha256': derived,
            },
          ],
          'outputAssets': [
            {
              'path':
                  'assets_unused/pending_review/a1_layers/05_timber_preparation_layer.png',
              'sha256':
                  'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
              'decision': 'approved',
            },
          ],
        },
      ]) {
        for (final input in _objects(record['inputAssets'], 'lineage.input')) {
          final path = _string(input['path'], 'lineage.input.path');
          expect(known[path], _sha256(input['sha256'], 'lineage.input.sha256'));
        }
        for (final output in _objects(record['outputAssets'], 'lineage.output')) {
          if (_string(output['decision'], 'lineage.decision') == 'approved') {
            known[_string(output['path'], 'lineage.output.path')] = _sha256(
              output['sha256'],
              'lineage.output.sha256',
            );
          }
        }
      }
      expect(known.containsKey(allowed.keys.single), isTrue);
      expect(
        known['assets_unused/pending_review/a1_layers/06_columns_layer.png'],
        derived,
      );
    });

    test(
      'does not derive asset contracts from curriculum or content counts',
      () {
        expect(_string(manifest['scope'], 'scope'), 'hanok_v1_assets_only');
        expect(
          _string(
            manifest['contentProgressAuthority'],
            'contentProgressAuthority',
          ),
          'none',
        );
        final keys = <String>{};
        _collectKeys(manifest, keys);
        expect(
          keys.intersection({
            'courseUnitCount',
            'courseUnits',
            'segmentCount',
            'contentRecordCount',
            'rewardCount',
          }),
          isEmpty,
        );
      },
    );
  });
}

Map<String, dynamic> _object(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    fail('$label must be a JSON object');
  }
  return value;
}

List<Object?> _list(Object? value, String label) {
  if (value is! List<Object?>) {
    fail('$label must be an array');
  }
  return value;
}

List<Map<String, dynamic>> _objects(Object? value, String label) => [
  for (final entry in _list(value, label)) _object(entry, label),
];

List<String> _strings(Object? value, String label) => [
  for (final entry in _list(value, label)) _string(entry, label),
];

String _string(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    fail('$label must be a non-empty string');
  }
  return value;
}

int _integer(Object? value, String label) {
  if (value is! int) {
    fail('$label must be an integer');
  }
  return value;
}

double _number(Object? value, String label) {
  if (value is! num || !value.isFinite) {
    fail('$label must be a finite number');
  }
  return value.toDouble();
}

bool _boolean(Object? value, String label) {
  if (value is! bool) {
    fail('$label must be a boolean');
  }
  return value;
}

String _sha256(Object? value, String label) {
  final digest = _string(value, label);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
    fail('$label must be a lower-case SHA-256 digest');
  }
  return digest;
}

_PngMetadata _readPngMetadata(Uint8List bytes, String label) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 26 ||
      !Iterable<int>.generate(8).every((i) => bytes[i] == signature[i])) {
    fail('$label must be a PNG file');
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  final colorMode = switch (bytes[25]) {
    2 => 'RGB',
    6 => 'RGBA',
    final colorType => fail(
      '$label uses unsupported PNG color type $colorType',
    ),
  };
  return _PngMetadata(width: width, height: height, colorMode: colorMode);
}

void _collectKeys(Object? value, Set<String> keys) {
  if (value is Map<String, dynamic>) {
    for (final entry in value.entries) {
      keys.add(entry.key);
      _collectKeys(entry.value, keys);
    }
  } else if (value is List<Object?>) {
    for (final entry in value) {
      _collectKeys(entry, keys);
    }
  }
}

class _PngMetadata {
  final int width;
  final int height;
  final String colorMode;

  const _PngMetadata({
    required this.width,
    required this.height,
    required this.colorMode,
  });
}
