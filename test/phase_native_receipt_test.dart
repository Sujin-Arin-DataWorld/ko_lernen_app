import 'package:flutter_test/flutter_test.dart';
import '../test_driver/phase_native_receipt.dart';

void main() {
  Map<String, dynamic> receipt({bool audio = true}) => {
    'phaseNativeReceipt': 1,
    'widgetTestCount': 3,
    'audioEnabled': audio,
    'completedAudioPackets': audio ? 18 : 0,
  };
  test('rejects a nominally successful empty native run', () {
    for (final data in [
      null,
      <String, dynamic>{},
      {...receipt(), 'widgetTestCount': 0},
    ]) {
      expect(() => validatePhaseNativeReceipt(data), throwsStateError);
    }
  });
  test('audio-enabled run must prove completed playback', () {
    expect(
      () => validatePhaseNativeReceipt({
        ...receipt(),
        'completedAudioPackets': 0,
      }),
      throwsStateError,
    );
    expect(() => validatePhaseNativeReceipt(receipt()), returnsNormally);
  });
  test('fresh restore can succeed without replaying audio', () {
    expect(
      () => validatePhaseNativeReceipt(receipt(audio: false)),
      returnsNormally,
    );
  });
}
