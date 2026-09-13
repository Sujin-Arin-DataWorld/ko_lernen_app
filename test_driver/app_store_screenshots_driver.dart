import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Platform.environment['APP_STORE_SCREENSHOT_OUTPUT'];
  if (output == null || output.isEmpty) {
    throw StateError('APP_STORE_SCREENSHOT_OUTPUT is required.');
  }
  final outputDirectory = Directory(output);
  await outputDirectory.create(recursive: true);

  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [arguments]) async {
      if (!RegExp(r'^\d{2}-[a-z0-9-]+$').hasMatch(name)) {
        return false;
      }
      final decoded = image.decodePng(Uint8List.fromList(bytes));
      if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
        return false;
      }
      final rgb = decoded.convert(numChannels: 3);
      final png = image.encodePng(rgb, level: 6);
      final destination = File('${outputDirectory.path}/$name.png');
      await destination.writeAsBytes(png, flush: true);
      return await destination.length() > 0;
    },
  );
}
