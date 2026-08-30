import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/audio_policy.dart';

void main() {
  late Map<String, dynamic> report;
  late List<Map<String, dynamic>> rows;

  setUpAll(() {
    report =
        jsonDecode(File('tool/audio_gain_report.json').readAsStringSync())
            as Map<String, dynamic>;
    rows = (report['assets'] as List<dynamic>).cast<Map<String, dynamic>>();
  });

  test('report covers every bundled runtime SFX and video exactly once', () {
    final diskPaths = <String>{
      ..._runtimeMediaUnder('assets/sfx'),
      ..._runtimeMediaUnder('assets/video'),
    };
    final reportPaths = rows
        .map((row) => row['path']! as String)
        .toList(growable: false);

    expect(report['schemaVersion'], 1);
    expect(reportPaths.toSet(), diskPaths);
    expect(
      reportPaths.length,
      diskPaths.length,
      reason: 'duplicate report path',
    );
    expect(report['assetCount'], diskPaths.length);
    expect(report['issues'], isEmpty);
    expect(report['decoderErrorCount'], 0);
    expect(report['targetIssueCount'], 0);
  });

  test('every row has decoder, hash, stream, and policy evidence', () {
    final sha256 = RegExp(r'^[0-9a-f]{64}$');
    for (final row in rows) {
      final path = row['path']! as String;
      expect(row['sourceSha256'], matches(sha256), reason: path);
      expect(row['decoderError'], isNull, reason: path);
      expect(
        row['channel'],
        isIn(<String>['gameFeedback', 'companion', 'ambience', 'cinematic']),
        reason: path,
      );

      if (_audioExtensions.contains(_extensionOf(path))) {
        expect(row['hasAudio'], isTrue, reason: path);
      }
      if (row['hasAudio'] == true) {
        expect(row['codec'], isNotNull, reason: path);
        expect(row['channels'], greaterThan(0), reason: path);
        expect(row['sampleRateHz'], greaterThan(0), reason: path);
        expect(row['durationSeconds'], greaterThan(0), reason: path);
        expect(row['meanDb'], isNotNull, reason: path);
        expect(row['maxDb'], isNotNull, reason: path);
        expect(row['truePeakDbtp'], isNotNull, reason: path);
      }
    }
  });

  test('only ADR-targeted channels receive a target', () {
    for (final row in rows) {
      final path = row['path']! as String;
      switch (row['channel']) {
        case 'ambience':
          expect(row['targetDb'], -40.0, reason: path);
        case 'cinematic':
          expect(row['targetDb'], -29.0, reason: path);
        case 'gameFeedback':
        case 'companion':
          expect(row['targetDb'], isNull, reason: path);
          expect(row['calculatedGain'], isNull, reason: path);
      }
    }
  });

  test('runtime attenuation matches measured ADR-targeted tracks', () {
    final tolerance = (report['policyTargets']['targetToleranceDb'] as num)
        .toDouble();
    for (final row in rows.where(
      (row) => row['targetDb'] != null && row['hasAudio'] == true,
    )) {
      final path = row['path']! as String;
      final measuredMean = (row['meanDb'] as num).toDouble();
      final target = (row['targetDb'] as num).toDouble();
      final calculated = (row['calculatedGain'] as num).toDouble();
      final runtimeGain = AudioPolicy.gainFor(path);
      final effectiveMean =
          measuredMean + 20 * math.log(runtimeGain) / math.ln10;

      expect(runtimeGain, closeTo(calculated, 0.001), reason: path);
      expect(runtimeGain, inInclusiveRange(0.0, 1.0), reason: path);
      expect(
        effectiveMean,
        lessThanOrEqualTo(target + tolerance + 0.001),
        reason: '$path effective mean $effectiveMean dB',
      );
    }
  });
}

const _audioExtensions = <String>{'.mp3', '.wav'};
const _videoExtensions = <String>{'.m4v', '.mov', '.mp4', '.webm'};

Set<String> _runtimeMediaUnder(String directory) {
  final root = Directory(directory);
  if (!root.existsSync()) {
    return <String>{};
  }
  return root
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => file.path.replaceAll('\\', '/'))
      .where((path) {
        final extension = _extensionOf(path);
        return _audioExtensions.contains(extension) ||
            _videoExtensions.contains(extension);
      })
      .toSet();
}

String _extensionOf(String path) {
  final slash = path.lastIndexOf('/');
  final dot = path.lastIndexOf('.');
  if (dot <= slash) {
    return '';
  }
  return path.substring(dot).toLowerCase();
}
