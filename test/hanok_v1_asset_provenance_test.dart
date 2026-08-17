import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

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
        final composition = _object(
          states['composition'],
          'a1ConstructionStates.composition',
        );
        expect(
          _string(composition['tool'], 'composition.tool'),
          'tool/compose_hanok_a1_state.py',
        );
        expect(
          _string(composition['baseRole'], 'composition.baseRole'),
          'site_base',
        );
        final layer = _object(composition['layer'], 'composition.layer');
        expect(_string(layer['format'], 'composition.layer.format'), 'PNG');
        expect(
          _string(layer['colorMode'], 'composition.layer.colorMode'),
          'RGBA',
        );
        expect(
          (
            _integer(layer['width'], 'composition.layer.width'),
            _integer(layer['height'], 'composition.layer.height'),
          ),
          (854, 309),
        );
        final localAnchor = _object(
          layer['anchorLocal'],
          'composition.layer.anchorLocal',
        );
        expect(
          (
            _integer(localAnchor['x'], 'composition.layer.anchorLocal.x'),
            _integer(localAnchor['y'], 'composition.layer.anchorLocal.y'),
          ),
          (427, 309),
        );
        expect(
          _integer(
            composition['sourceOutsideSocketChangedPixels'],
            'composition.sourceOutsideSocketChangedPixels',
          ),
          0,
        );
        final continuity = _object(
          composition['cumulativeContinuity'],
          'composition.cumulativeContinuity',
        );
        expect(
          _string(continuity['requiredFromStageId'], 'requiredFromStageId'),
          '04_cornerstones_choseok',
        );
        expect(
          _integer(continuity['foundationBandHeight'], 'foundationBandHeight'),
          80,
        );
        expect(_number(continuity['minimumAlphaIoU'], 'minimumAlphaIoU'), 0.94);
        expect(
          _integer(
            continuity['maximumFootprintEdgeDriftPixels'],
            'maximumFootprintEdgeDriftPixels',
          ),
          12,
        );
        final encoder = _object(composition['encoder'], 'composition.encoder');
        expect(_string(encoder['library'], 'encoder.library'), 'Pillow');
        expect(_string(encoder['format'], 'encoder.format'), 'WebP');
        expect(_integer(encoder['quality'], 'encoder.quality'), 82);
        expect(_integer(encoder['method'], 'encoder.method'), 6);
        expect(
          _number(
            composition['decodedOutsideSocketMaxMeanError'],
            'composition.decodedOutsideSocketMaxMeanError',
          ),
          5.0,
        );
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
    test('declares a machine-readable generation ledger', () {
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
      final records = _objects(ledger['records'], 'generationLedger.records');
      expect(records, hasLength(13));
      expect(
        records
            .expand(
              (record) => _objects(
                record['outputAssets'],
                'generationRecord.outputAssets',
              ),
            )
            .map((output) => output['decision']),
        [
          'rejected',
          'rejected',
          'rejected',
          'approved',
          'rejected',
          'approved',
          'rejected',
          'rejected',
          'rejected',
          'rejected',
          'rejected',
          'approved',
        ],
      );
      expect(
        records.fold<double>(
          0,
          (sum, record) =>
              sum + _number(record['costCredits'], 'record.costCredits'),
        ),
        closeTo(12.6, 1e-9),
      );
    });

    test(
      'approved transparent pilot artifacts are hash-locked and QA-only',
      () {
        final pilot = _object(
          manifest['a1TransparentPilot'],
          'a1TransparentPilot',
        );
        expect(_string(pilot['stageId'], 'pilot.stageId'), '06_columns');
        expect(
          _string(pilot['status'], 'pilot.status'),
          'approved_reference_pilot',
        );
        expect(_boolean(pilot['runtime'], 'pilot.runtime'), isFalse);

        final artifacts = <(String, int, int, int, int)>[
          ('rawLayer', 2172, 724, 4, 962603),
          ('normalizedLayer', 854, 309, 4, 211415),
          // package:image exposes decoded WebP as RGBA even though Pillow's
          // encoded source contract is RGB; the Python compositor checks mode.
          ('composite', 1536, 1152, 4, 276120),
        ];
        for (final artifactContract in artifacts) {
          final artifact = _object(
            pilot[artifactContract.$1],
            'pilot.${artifactContract.$1}',
          );
          final path = _string(
            artifact['path'],
            'pilot.${artifactContract.$1}.path',
          );
          final file = File(path);
          expect(file.existsSync(), isTrue, reason: path);
          final bytes = file.readAsBytesSync();
          expect(bytes.length, artifactContract.$5, reason: path);
          expect(
            sha256.convert(bytes).toString(),
            _sha256(artifact['sha256'], '$path.sha256'),
          );
          final decoded = img.decodeImage(bytes);
          expect(decoded, isNotNull, reason: path);
          expect(
            (decoded!.width, decoded.height, decoded.numChannels),
            (artifactContract.$2, artifactContract.$3, artifactContract.$4),
            reason: path,
          );
        }

        final normalized = _object(pilot['normalizedLayer'], 'normalizedLayer');
        expect(
          _integer(normalized['anchorPixels'], 'anchorPixels'),
          greaterThan(0),
        );
        expect(_integer(normalized['chromaPixels'], 'chromaPixels'), 0);
        final composite = _object(pilot['composite'], 'composite');
        expect(
          _integer(
            composite['sourceOutsideSocketChangedPixels'],
            'sourceOutsideSocketChangedPixels',
          ),
          0,
        );
        expect(
          _number(
            composite['decodedOutsideSocketMeanError'],
            'decodedOutsideSocketMeanError',
          ),
          lessThanOrEqualTo(5.0),
        );
        expect(
          _strings(
            _object(pilot['visualReview'], 'visualReview')['checks'],
            'visualReview.checks',
          ),
          contains('no_beams_purlins_rafters_roof_walls_or_changho'),
        );
      },
    );

    test('approved cumulative QA states are hash-locked and QA-only', () {
      final approved = _object(
        manifest['a1ApprovedQaStates'],
        'a1ApprovedQaStates',
      );
      expect(_integer(approved['schemaVersion'], 'schemaVersion'), 1);
      expect(_boolean(approved['runtime'], 'runtime'), isFalse);
      final states = _objects(approved['states'], 'states');
      expect(states, hasLength(2));
      final state = states.firstWhere(
        (item) => item['stageId'] == '05_timber_preparation',
      );
      expect(_string(state['stageId'], 'stageId'), '05_timber_preparation');
      expect(_string(state['status'], 'status'), 'approved_qa');

      final artifacts = <(String, int, int, int, int)>[
        ('rawLayer', 2160, 728, 4, 801696),
        ('normalizedLayer', 854, 309, 4, 178584),
        // package:image exposes decoded WebP as RGBA even though Pillow's
        // encoded source contract is RGB; the Python compositor checks mode.
        ('composite', 1536, 1152, 4, 276882),
      ];
      for (final contract in artifacts) {
        final artifact = _object(state[contract.$1], contract.$1);
        final path = _string(artifact['path'], '${contract.$1}.path');
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final bytes = file.readAsBytesSync();
        expect(bytes.length, contract.$5, reason: path);
        expect(
          sha256.convert(bytes).toString(),
          _sha256(artifact['sha256'], '$path.sha256'),
        );
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull, reason: path);
        expect(
          (decoded!.width, decoded.height, decoded.numChannels),
          (contract.$2, contract.$3, contract.$4),
          reason: path,
        );
      }

      final normalized = _object(state['normalizedLayer'], 'normalizedLayer');
      expect(_integer(normalized['anchorPixels'], 'anchorPixels'), 909);
      expect(_integer(normalized['chromaPixels'], 'chromaPixels'), 0);
      final composite = _object(state['composite'], 'composite');
      expect(
        _integer(
          composite['sourceOutsideSocketChangedPixels'],
          'sourceOutsideSocketChangedPixels',
        ),
        0,
      );
      expect(
        _number(
          composite['decodedOutsideSocketMeanError'],
          'decodedOutsideSocketMeanError',
        ),
        lessThanOrEqualTo(5.0),
      );
      expect(
        _strings(
          _object(state['visualReview'], 'visualReview')['checks'],
          'visualReview.checks',
        ),
        contains('no_upright_columns_or_later_structure'),
      );
    });

    test('approved beams and changbang QA state is exact and continuous', () {
      final approved = _object(
        manifest['a1ApprovedQaStates'],
        'a1ApprovedQaStates',
      );
      final states = _objects(approved['states'], 'states');
      final state = states.firstWhere(
        (item) => item['stageId'] == '07_beams_changbang',
      );
      expect(_string(state['status'], 'status'), 'approved_qa');
      expect(
        _string(state['generationRecordId'], 'generationRecordId'),
        'hanok_a1_07_beams_changbang_semantic_recraft_approved_20260817',
      );

      final artifacts = <(String, int, int, int, int)>[
        ('rawLayer', 2172, 724, 4, 1558117),
        ('normalizedLayer', 854, 309, 4, 228583),
        // package:image exposes decoded WebP as RGBA even though Pillow's
        // encoded source contract is RGB; the Python compositor checks mode.
        ('composite', 1536, 1152, 4, 278848),
      ];
      for (final contract in artifacts) {
        final artifact = _object(state[contract.$1], contract.$1);
        final path = _string(artifact['path'], '${contract.$1}.path');
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final bytes = file.readAsBytesSync();
        expect(bytes.length, contract.$5, reason: path);
        expect(
          sha256.convert(bytes).toString(),
          _sha256(artifact['sha256'], '$path.sha256'),
        );
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull, reason: path);
        expect(
          (decoded!.width, decoded.height, decoded.numChannels),
          (contract.$2, contract.$3, contract.$4),
          reason: path,
        );
      }

      final normalized = _object(state['normalizedLayer'], 'normalizedLayer');
      expect(_integer(normalized['anchorPixels'], 'anchorPixels'), 991);
      expect(_integer(normalized['chromaPixels'], 'chromaPixels'), 0);
      final continuity = _object(
        normalized['cumulativeContinuity'],
        'cumulativeContinuity',
      );
      expect(
        _integer(continuity['foundationBandHeight'], 'foundationBandHeight'),
        80,
      );
      expect(_number(continuity['alphaIoU'], 'alphaIoU'), greaterThan(0.94));
      expect(
        _integer(
          continuity['maximumEdgeDriftPixels'],
          'maximumEdgeDriftPixels',
        ),
        0,
      );

      final composite = _object(state['composite'], 'composite');
      expect(
        _integer(
          composite['sourceOutsideSocketChangedPixels'],
          'sourceOutsideSocketChangedPixels',
        ),
        0,
      );
      expect(
        _number(
          composite['decodedOutsideSocketMeanError'],
          'decodedOutsideSocketMeanError',
        ),
        lessThanOrEqualTo(5.0),
      );
      final checks = _strings(
        _object(state['visualReview'], 'visualReview')['checks'],
        'visualReview.checks',
      );
      expect(checks, contains('exactly_seven_primary_columns_preserved'));
      expect(checks, contains('no_midheight_sujang_rails_or_secondary_posts'));
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
        final records = _objects(ledger['records'], 'generationLedger.records');
        final ids = <String>{};
        final priorGeneratedOutputs = <String, String>{};
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
          expect(credits, greaterThanOrEqualTo(0));
          if (credits == 0) {
            expect(
              _string(record['costDisposition'], '$id.costDisposition'),
              anyOf(
                'charged_then_fully_refunded',
                'outside_bbanana_credit_budget',
              ),
            );
          }
          _sha256(record['promptSha256'], '$id.promptSha256');

          for (final input in _objects(
            record['inputAssets'],
            '$id.inputAssets',
          )) {
            final path = _string(input['path'], '$id.inputAssets.path');
            final digest = _sha256(input['sha256'], '$id.inputAssets.sha256');
            expect(
              allowedInputs[path] ?? priorGeneratedOutputs[path],
              digest,
              reason:
                  '$id used an input without an exact allowlist or prior-ledger lineage',
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
            expect(
              priorGeneratedOutputs.containsKey(path),
              isFalse,
              reason: '$id redefined generated output path $path',
            );
            priorGeneratedOutputs[path] = digest;
            expect(
              _string(output['decision'], '$id.outputAssets.decision'),
              anyOf('approved', 'rejected'),
            );
          }

          if (_list(record['outputAssets'], '$id.outputAssets').isEmpty) {
            expect(_string(record['status'], '$id.status'), 'failed');
            _string(record['failureReason'], '$id.failureReason');
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
