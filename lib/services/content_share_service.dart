import 'package:share_plus/share_plus.dart';

/// Text-share stub until the 두루마리 story image (bible §13 A) ships.
class ContentShareService {
  static Future<void> shareStoryText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }
}
