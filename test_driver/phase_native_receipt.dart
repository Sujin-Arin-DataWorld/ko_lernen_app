/// Reject an empty native test run even when the runner reports success.
void validatePhaseNativeReceipt(Map<String, dynamic>? data) {
  if (data == null ||
      data['phaseNativeReceipt'] != 1 ||
      data['widgetTestCount'] is! int ||
      (data['widgetTestCount'] as int) < 1 ||
      data['audioEnabled'] is! bool ||
      data['completedAudioPackets'] is! int ||
      (data['audioEnabled'] == true &&
          (data['completedAudioPackets'] as int) < 1)) {
    throw StateError('Missing or incomplete Phase native execution receipt');
  }
}
