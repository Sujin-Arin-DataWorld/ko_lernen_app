import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native microphone permission strings and optional Android permission exist',
    () {
      final android = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final de = File(
        'ios/Runner/de.lproj/InfoPlist.strings',
      ).readAsStringSync();
      final en = File(
        'ios/Runner/en.lproj/InfoPlist.strings',
      ).readAsStringSync();

      expect(android, contains('android.permission.RECORD_AUDIO'));
      expect(plist, contains('NSMicrophoneUsageDescription'));
      expect(de, contains('NSMicrophoneUsageDescription'));
      expect(en, contains('NSMicrophoneUsageDescription'));
      expect(de, contains('10 Sekunden'));
      expect(en, contains('up to 10 seconds'));
    },
  );

  test(
    'privacy policy states processor, region, consent and non-retention',
    () {
      final privacy = File(
        'docs/privacy.html',
      ).readAsStringSync(encoding: utf8);
      for (final required in const <String>[
        'Microsoft Azure Speech',
        'germanywestcentral',
        'App Check',
        'up to 10 seconds',
        'does not write the recording',
        'Deutschland West-Mitte',
        'schreibt weder Aufnahme noch Referenzsatz',
        '최대 10초',
        '서버 저장소나 로그에 기록하지 않습니다',
      ]) {
        expect(
          privacy,
          contains(required),
          reason: 'Missing privacy fact: $required',
        );
      }
    },
  );

  test('Firebase declares isolated Node 22 pronunciation codebase', () {
    final firebase =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, Object?>;
    final functions = (firebase['functions']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final pronunciation = functions.singleWhere(
      (entry) => entry['source'] == 'functions/pronunciation',
    );
    expect(pronunciation['codebase'], 'pronunciation-firebase-functions');
    expect(pronunciation['runtime'], 'nodejs22');
  });

  test('clients cannot manipulate server-owned pronunciation quota counters', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(
      rules,
      contains('match /pronunciation_rate_limits/{document=**}'),
    );
    expect(
      rules,
      contains("collectionName != 'pronunciation_rate_limits'"),
    );
  });
}
