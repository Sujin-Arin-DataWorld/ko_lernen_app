import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/sori/share_slip.dart';

/// Content share: 두루마리 PNG first, text caption as fallback.
class ContentShareService {
  static Future<void> shareStoryText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<void> shareStory({
    required String korean,
    required String gloss,
    String? caption,
  }) async {
    final line = caption ?? '$korean\n$gloss\nhangul-sori.com';
    try {
      final png = await ShareSlipRenderer.renderPng(
        korean: korean,
        gloss: gloss,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hangul-sori-slip.png');
      await file.writeAsBytes(png, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: line,
        ),
      );
    } catch (_) {
      await shareStoryText(line);
    }
  }
}
