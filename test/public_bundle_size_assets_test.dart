import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/ildu_turntable_catalog.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_art.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/sori/c_learning_surface.dart';
import 'package:ko_lernen_app/widgets/sori/c_material_assets.dart';

const _paperSha =
    'de51969fdc7fbd7f2f4c0c87acbe5061afdaf799b9a90937c5abbf2b6570e464';
const _jadeSha =
    '88bd3a7d543ac5fb7b7436c892b174ec977bc717520f218699fc137c255c77fe';
const _cloudSha =
    'c728baced6dd3bff2729bf2a28dbf62e3954ad91a04594e04dc923fbd530f6a5';
const _turnaroundRoot = 'assets/illustrations/personal_hanok_v3/turnarounds/';
const _originalHashes = {
  '${_turnaroundRoot}changgo_relocation.png':
      'fdcbe4a9dc7a33e879a82f7f949acfc1625dd7d7994f6cf51900096d275bc45c',
  '$_turnaroundRoot사랑채':
      '3a7234b6841f850d0a96c650fc9eea318ddac27872b4fbfd15c0b2f9f99df93a',
  '$_turnaroundRoot솟을대문.png':
      '089bc9b1c63373bb9c60750d4239a1166985e176ed2023fe1c086b032a03c501',
  '$_turnaroundRoot솟을대문1.png':
      '8a9ace584e291fb8df1cff9870751bdc2964bb273cd0f4c687a16c07aa99af0d',
  '$_turnaroundRoot솟을대문2.png':
      '85e660cb6628042ee6249cc849f390356a2c586bd7c056e183d6101617181d44',
  '$_turnaroundRoot솟을대문6.png':
      '943c3baf16f4d8129bbae09f0443c17ee69dd82653b9a228c79e90889977d1a6',
  '$_turnaroundRoot솟을대문8.png':
      '9d032f469b0902358eebcf7fdc894b3a300e53e091adf9c6102e4baf5a3ad6bd',
  'assets/illustrations/einleitung_generated/intro-interest-kcontent.png':
      'b1142b8f1311980024294f4676947bd2720dbc4715c7203c45d96f1747045ef5',
  'assets/illustrations/einleitung_generated/intro-cloud-mark.png': _cloudSha,
  'assets/illustrations/concept_c/hangul_atelier/paper-atlas.png': _paperSha,
  'assets/illustrations/c_learning/paper-atlas.png': _paperSha,
  'assets/illustrations/c_learning/jade.png': _jadeSha,
};

List<Map<String, dynamic>> _rows(Map<String, dynamic> json, String key) =>
    (json[key] as List).cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final provenance =
      jsonDecode(
            File(
              'docs/assets/APPROVED_BUNDLE_SIZE_20261030.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('all twelve excluded originals retain their baseline bytes', () {
    expect(
      provenance['baselineCommit'],
      '2ac799eb0bfa507f72e7eb3e5bcbb78f8a77cbed',
    );
    final preserved = <String, Map<String, dynamic>>{
      for (final row in _rows(provenance, 'unbundledTurnarounds'))
        row['asset'] as String: row,
      for (final row in _rows(provenance, 'sharedAliases'))
        row['originalAsset'] as String: row,
      for (final row in _rows(provenance, 'archived'))
        row['originalAsset'] as String: row,
    };
    expect(preserved.keys.toSet(), _originalHashes.keys.toSet());
    for (final entry in _originalHashes.entries) {
      final row = preserved[entry.key]!;
      final location = row['asset'] as String? ?? entry.key;
      expect(row['sha256'], entry.value, reason: entry.key);
      expect(
        sha256.convert(File(location).readAsBytesSync()).toString(),
        entry.value,
        reason: location,
      );
    }
  });

  test(
    'actual bundle excludes originals and loads exact shared payloads',
    () async {
      final assets = (await AssetManifest.loadFromAssetBundle(
        rootBundle,
      )).listAssets().toSet();
      for (final original in _originalHashes.keys) {
        expect(assets, isNot(contains(original)), reason: original);
      }
      for (final row in _rows(provenance, 'archived')) {
        expect(assets, isNot(contains(row['asset'])));
      }
      for (final entry in {
        SoriCMaterialAssets.paperAtlas: _paperSha,
        SoriCMaterialAssets.jade: _jadeSha,
        ApprovedChromeAssets.cloud: _cloudSha,
      }.entries) {
        expect(assets, contains(entry.key));
        final bytes = await rootBundle.load(entry.key);
        expect(
          sha256
              .convert(
                bytes.buffer.asUint8List(
                  bytes.offsetInBytes,
                  bytes.lengthInBytes,
                ),
              )
              .toString(),
          entry.value,
        );
      }
      final frames = {
        for (final spec in kIlDuTurntables.values)
          for (final frame in spec.frames) frame.assetPath,
      };
      final downloadManifest = File(
        'assets/data/hanok_download_manifest.json',
      ).readAsStringSync();
      for (final row in _rows(provenance, 'unbundledTurnarounds')) {
        final path = row['asset'] as String;
        expect(frames, isNot(contains(path)), reason: path);
        expect(downloadManifest.contains(path), isFalse, reason: path);
      }
    },
  );

  test(
    'Einleitung manifest covers shipped files and preserved source records',
    () {
      final manifest =
          jsonDecode(
                File(
                  'tool/einleitung_generated_assets.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final active = _rows(manifest, 'files');
      final actual = Directory('assets/illustrations/einleitung_generated')
          .listSync()
          .whereType<File>()
          .map((file) => file.path.replaceAll('\\', '/'))
          .toSet();
      expect(active, hasLength(35));
      expect(active.map((row) => row['asset']).toSet(), actual);
      expect(_rows(manifest, 'preservedFiles'), hasLength(2));
      final alias = _rows(manifest, 'runtimeAliases').single;
      expect(alias['name'], 'intro-cloud-mark');
      expect(alias['asset'], ApprovedChromeAssets.cloud);
      expect(alias['sha256'], _cloudSha);
      for (final row in _rows(manifest, 'preservedFiles')) {
        expect(row['sha256'], _originalHashes[row['originalAsset']]);
        expect(
          sha256
              .convert(File(row['asset'] as String).readAsBytesSync())
              .toString(),
          row['sha256'],
        );
      }
    },
  );

  testWidgets('intro cloud reuses the approved complete original', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.square(dimension: 120, child: CIntroArt('cloud-mark')),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, ApprovedChromeAssets.cloud);
    expect(image.fit, BoxFit.contain);
    expect(image.filterQuality, FilterQuality.medium);
  });

  for (final example in [
    (
      name: 'learning paper',
      widget: const SoriCMaterialSurface(child: SizedBox.expand()),
      asset: SoriCMaterialAssets.paperAtlas,
    ),
    (
      name: 'learning jade',
      widget: const SoriCMaterialSurface(
        material: SoriCMaterial.jade,
        child: SizedBox.expand(),
      ),
      asset: SoriCMaterialAssets.jade,
    ),
    (
      name: 'Atelier paper',
      widget: const CAtelierPaper(child: SizedBox.expand()),
      asset: SoriCMaterialAssets.paperAtlas,
    ),
  ]) {
    testWidgets('${example.name} loads its byte-identical shared texture', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(width: 144, height: 160, child: example.widget),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetBundleImageProvider;
      final key = await provider.obtainKey(const ImageConfiguration());
      expect(key.name, example.asset);
      expect(tester.takeException(), isNull);
    });
  }
}
