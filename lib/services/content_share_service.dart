import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/sori/share_slip.dart';

/// 콘텐츠 공유 — Content UI Bible §13 안 A(두루마리, 잠금) 이야기 이미지.
///
/// [shareStorySlip] 이 정본이다. 두루마리 PNG를 오프스크린으로 그려 시스템
/// 공유 시트에 파일로 넘긴다. 렌더링이 실패하면(캡처 예외·null 반환 등) 조용히
/// [shareStoryText] 로 내려간다 — 공유 버튼이 죽는 것보다 텍스트만 나가는 게
/// 낫다는 게 이 서비스의 유일한 판단이다.
class ContentShareService {
  static Future<void> shareStoryText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  /// [korean]/[gloss] 로 두루마리 이미지를 그려 [caption] 과 함께 공유한다.
  /// 화면은 이미 갖고 있는 `t.contentShareBody(korean, gloss)` 를 그대로
  /// [caption] 에 넘기면 된다 — 이미지 실패 시 그 문구가 텍스트 폴백이 된다.
  static Future<void> shareStorySlip({
    required String korean,
    required String gloss,
    required String caption,
  }) async {
    final png = await _renderSafely(korean: korean, gloss: gloss);
    if (png == null) {
      return shareStoryText(caption);
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/hangulsori_share_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          text: caption,
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      await shareStoryText(caption);
    }
  }

  static Future<List<int>?> _renderSafely({
    required String korean,
    required String gloss,
  }) async {
    try {
      return await renderShareSlipToPng(korean: korean, gloss: gloss);
    } catch (_) {
      return null;
    }
  }
}
