import 'dart:math' as math;
import 'dart:typed_data';

/// Converts interleaved PCM16 to the recorder contract: 16 kHz, mono, little
/// endian. Weighted sample intervals keep duration independent of input chunk
/// boundaries, including 44.1 kHz sources and incomplete interleaved frames.
class Pcm16StreamNormalizer {
  Pcm16StreamNormalizer({required this.sampleRate, required this.channels}) {
    if (sampleRate < 8000 ||
        sampleRate > 192000 ||
        channels < 1 ||
        channels > 8) {
      throw const FormatException('Unsupported PCM capture format');
    }
    _outputRemaining = sampleRate;
  }

  final int sampleRate, channels;
  Uint8List _carry = Uint8List(0);
  late int _outputRemaining;
  double _weighted = 0;

  Uint8List add(Uint8List chunk) {
    final bytes = Uint8List(_carry.length + chunk.length)
      ..setAll(0, _carry)
      ..setAll(_carry.length, chunk);
    final frameBytes = channels * 2;
    final completeBytes = bytes.length - bytes.length % frameBytes;
    final input = ByteData.sublistView(bytes);
    final output = <int>[];
    for (var offset = 0; offset < completeBytes; offset += frameBytes) {
      var total = 0;
      for (var channel = 0; channel < channels; channel++) {
        total += input.getInt16(offset + channel * 2, Endian.little);
      }
      final mono = total / channels;
      var inputRemaining = 16000;
      while (inputRemaining > 0) {
        final weight = math.min(inputRemaining, _outputRemaining);
        _weighted += mono * weight;
        inputRemaining -= weight;
        _outputRemaining -= weight;
        if (_outputRemaining == 0) {
          output.add((_weighted / sampleRate).round().clamp(-32768, 32767));
          _weighted = 0;
          _outputRemaining = sampleRate;
        }
      }
    }
    _carry = Uint8List.fromList(bytes.sublist(completeBytes));
    final result = Uint8List(output.length * 2);
    final data = ByteData.sublistView(result);
    for (var i = 0; i < output.length; i++) {
      data.setInt16(i * 2, output[i], Endian.little);
    }
    return result;
  }
}
