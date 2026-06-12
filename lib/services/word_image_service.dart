import 'dart:io';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// "나만의 단어장" 단어 첨부 사진 — 촬영/선택 후 앱 문서 폴더에 영구 복사.
///
/// image_picker 가 주는 경로는 캐시/임시라 OS 가 지울 수 있으므로,
/// 앱 문서 폴더 `wordbook_images/` 로 복사해 절대 경로를 반환한다.
/// 표시 측은 항상 `Image.file(..., errorBuilder: ...)` 로 누락에 안전하게 대응.
class WordImageService {
  static final math.Random _rng = math.Random.secure();

  /// 사진 촬영(camera) 또는 갤러리(gallery) → 영구 경로 반환. 취소/거부 시 null.
  static Future<String?> pickAndSave(ImageSource source) async {
    // 카메라는 런타임 권한 필요. 갤러리는 시스템 피커라 별도 권한 불필요.
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return null;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked == null) {
      return null;
    }

    final docs = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${docs.path}/wordbook_images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final tail = _rng.nextInt(1 << 31).toRadixString(36);
    final dest = '${imgDir.path}/wb_${ts}_$tail.jpg';
    await File(picked.path).copy(dest);
    return dest;
  }

  /// 모든 첨부 사진 삭제 — 계정 삭제/전체 초기화 시 호출 (DSGVO Art. 17:
  /// SharedPreferences 만 지우면 `wordbook_images/` 의 jpg 가 기기에 남는다).
  static Future<void> deleteAll() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final imgDir = Directory('${docs.path}/wordbook_images');
      if (await imgDir.exists()) {
        await imgDir.delete(recursive: true);
      }
    } catch (_) {
      // best effort — 웹/권한 실패 시 무시
    }
  }

  /// 파일 삭제 (best effort). 사진 교체/삭제 시 옛 파일 정리용.
  static Future<void> deleteIfExists(String path) async {
    if (path.isEmpty) {
      return;
    }
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // best effort — 실패해도 무시
    }
  }
}
