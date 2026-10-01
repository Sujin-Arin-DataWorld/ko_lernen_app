import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/services/haptic_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    HapticService.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        });
    calls.clear();
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  test(
    'mute audio still allows outcome haptics; haptic off blocks every type',
    () async {
      await Storage.setSndMaster(false);
      SoundService.correct();
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['HapticFeedbackType.lightImpact']);
      await Storage.setHapticsEnabled(false);
      await HapticService.selectionClick();
      await HapticService.lightImpact();
      await HapticService.mediumImpact();
      await HapticService.heavyImpact();
      expect(calls, hasLength(1));
    },
  );
  test(
    'duplicate result layers emit one mild pulse; distinct outcome is preserved',
    () async {
      await HapticService.lightImpact();
      await HapticService.lightImpact();
      await HapticService.mediumImpact();
      expect(calls, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    },
  );
  test(
    'rapid selections are not throttled; preferences survive reload',
    () async {
      await HapticService.selectionClick();
      await HapticService.selectionClick();
      expect(calls, hasLength(2));
      await Storage.setHapticsEnabled(false);
      await Storage.setReducedMotion(true);
      Storage.resetForTesting();
      await Storage.init();
      expect(Storage.hapticsEnabled, isFalse);
      expect(Storage.reducedMotion, isTrue);
    },
  );
}
