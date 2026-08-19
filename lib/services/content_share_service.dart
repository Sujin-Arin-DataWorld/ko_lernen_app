import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/sori/share_slip.dart';

/// 공유 결과 — 호출 화면이 실패를 사용자에게 말할 수 있게 한다.
enum ShareOutcome { shared, failed }

/// 콘텐츠 공유: **9:16 한지 두루마리 PNG 한 장.** 캡션 텍스트는 없다.
///
/// 왜 텍스트를 뺐나: 예전에는 이미지와 함께
/// `'{korean}\n{gloss}\nhangul-sori.com'` 을 같이 실어 보냈다. 파일 첨부가
/// 실패하거나 받는 앱이 텍스트를 선호하면 그 문자열만 남는다 — Jin 이 본
/// "N에 / Direction (to where?) / hangul-sori.com" 이 바로 그것이다.
/// 게다가 그 텍스트는 그림에 이미 적혀 있는 내용이라, 붙어 봐야 같은 말을
/// 두 번 하는 것이다. 이미지가 곧 메시지다.
///
/// 왜 임시 파일을 안 쓰나: `getTemporaryDirectory()` 와 `dart:io` 는 웹에서
/// 런타임에 던지고, 그 예외를 `catch (_) {}` 가 삼켜서 **아무 일도 안
/// 일어났다**. `XFile.fromData` 는 share_plus 가 io/web 양쪽에서 처리하므로
/// 플랫폼 분기도, path_provider 도, 고정 파일명 충돌도 없다.
class ContentShareService {
  static Future<ShareOutcome> shareStory({
    required String korean,
    required String gloss,
  }) async {
    try {
      final png = await ShareSlipRenderer.renderPng(
        korean: korean,
        gloss: gloss,
      );
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'hangul-sori-slip.png',
            ),
          ],
        ),
      );
      return result.status == ShareResultStatus.unavailable
          ? ShareOutcome.failed
          : ShareOutcome.shared;
    } catch (error, stack) {
      // 조용히 삼키지 않는다. 예전 `catch (_) {}` 때문에 웹에서 공유를
      // 눌러도 아무 반응이 없었고, 왜인지 알 길도 없었다.
      debugPrint('ContentShareService.shareStory failed: $error');
      debugPrintStack(stackTrace: stack);
      return ShareOutcome.failed;
    }
  }
}
