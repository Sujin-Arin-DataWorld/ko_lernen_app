import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/snap_ocr_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/tokens.dart';

/// Phase 5 (stately-rising-jongga) — Capture-Screen.
///
/// Flow: 카메라/갤러리 → image_cropper → ML Kit OCR →
///   Navigator.push '/book/preview' (args: { text, blockCount, imagePath })
class BookCaptureScreen extends StatefulWidget {
  const BookCaptureScreen({super.key});

  @override
  State<BookCaptureScreen> createState() => _BookCaptureScreenState();
}

class _BookCaptureScreenState extends State<BookCaptureScreen> {
  bool _busy = false;
  String? _errorKey;

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    final l10n = AppL10n.of(context);

    // Tageslimit check (DeepL Free 보호) — analyze 호출 전이라도 OCR 자체는
    // permitted, 그러나 의미 없음 (분석 미실행). 명확한 UX 위해 차단.
    if (Storage.bookSnapQuotaReached) {
      setState(() => _errorKey = 'quota');
      return;
    }

    setState(() {
      _busy = true;
      _errorKey = null;
    });

    try {
      // Permission
      final perm = source == ImageSource.camera
          ? await Permission.camera.request()
          : (Platform.isAndroid && _isAndroid13Plus()
                ? await Permission.photos.request()
                : await Permission.storage.request());
      if (!perm.isGranted) {
        setState(() {
          _busy = false;
          _errorKey = 'permission';
        });
        return;
      }

      // Pick
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 85,
      );
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }

      // Crop
      final cropper = ImageCropper();
      final cropped = await cropper.cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.bookCropTitle,
            toolbarColor: SoriColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: l10n.bookCropTitle,
            aspectRatioLockEnabled: false,
          ),
        ],
      );
      if (cropped == null) {
        setState(() => _busy = false);
        return;
      }

      final file = File(cropped.path);

      // OCR
      final ocr = await SnapOcrService.recognizeKorean(file);
      if (!ocr.isSuccess) {
        setState(() {
          _busy = false;
          _errorKey = ocr.failure == OcrFailure.noKoreanFound
              ? 'no_korean'
              : 'ocr_error';
        });
        return;
      }

      if (!mounted) return;
      setState(() => _busy = false);

      await Navigator.of(context).pushNamed(
        '/book/preview',
        arguments: <String, dynamic>{
          'text': ocr.text,
          'blockCount': ocr.blockCount,
          'imagePath': file.path,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorKey = 'unknown';
      });
    }
  }

  // Heuristik — Material Android 13 (SDK 33)+ unterscheidet Storage vs Photos.
  // permission_handler abstrahiert; wir checken via Platform versions check.
  bool _isAndroid13Plus() {
    // Wir haben kein direktes SDK-Level — wir behandeln einfach immer mit
    // Permission.photos für moderne Android. permission_handler erkennt
    // automatisch das richtige Manifest-Recht.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_busy) {
      return Scaffold(
        appBar: AppBar(title: Text(t.bookCaptureTitle)),
        body: AppLoading(message: t.bookCaptureLoading),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.bookCaptureTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.lg),
              const Center(
                child: Mascot(
                  kind: MascotKind.magpie,
                  emotion: MascotEmotion.smile,
                  size: 130,
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.bookCaptureHero,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.bookCaptureSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: SoriSurfaces.of(context).textMuted,
                ),
              ),
              const Spacer(),
              if (_errorKey != null) _ErrorCard(errorKey: _errorKey!),
              if (_errorKey != null) const SizedBox(height: Spacing.md),
              SoriButton(
                label: t.bookCaptureCamera,
                icon: Icons.photo_camera_outlined,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.primary,
                fullWidth: true,
                onTap: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: Spacing.sm),
              SoriButton(
                label: t.bookCaptureGallery,
                icon: Icons.photo_library_outlined,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.info,
                fullWidth: true,
                onTap: () => _pick(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String errorKey;
  const _ErrorCard({required this.errorKey});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final msg = switch (errorKey) {
      'no_korean' => t.bookCaptureErrorNoKorean,
      'permission' => t.bookCaptureErrorPermission,
      'quota' => t.bookCaptureErrorQuota,
      'ocr_error' => t.bookCaptureErrorOcr,
      _ => t.bookCaptureErrorUnknown,
    };
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: SoriColors.warning,
      tinted: true,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: SoriColors.warning),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
