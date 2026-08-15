import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/book_capture_image_quality.dart';
import '../services/book_image_service.dart';
import '../services/crop_recovery_service.dart';
import '../services/picker_recovery_service.dart';
import '../services/snap_ocr_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/feature_coach.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

const int bookCaptureJpegQuality = 100;

Map<String, dynamic> buildBookPreviewArguments({
  required OcrResult ocr,
  required BookCaptureImageQuality imageQuality,
  required String imageLease,
}) {
  final warnings = <String>{
    ...imageQuality.warnings,
    ...ocr.qualityWarnings,
  }.toList(growable: false);
  final severeWarnings = <String>{
    ...imageQuality.severeWarnings,
    ...ocr.severeQualityWarnings,
  }.toList(growable: false);
  return <String, dynamic>{
    'text': ocr.text,
    'blockCount': ocr.blockCount,
    'qualityWarnings': warnings,
    'severeQualityWarnings': severeWarnings,
    'discardedBlockCount': ocr.discardedBlockCount,
    'ocrQuality': ocr.quality.toMap(),
    'imageQuality': imageQuality.toMap(),
    'imageLease': imageLease,
  };
}

/// Phase 5 (stately-rising-jongga) — Capture-Screen.
///
/// Flow: 카메라/갤러리 → image_cropper → ML Kit OCR →
///   Navigator.push '/book/preview' (args: { text, blockCount, imagePath })
class RecoveredBookOcrLeaseOwner {
  const RecoveredBookOcrLeaseOwner({
    required this.claim,
    required this.isDurablyRecovered,
    required this.discard,
  });

  final Future<String?> Function(String expectedLease) claim;
  final bool Function(PendingMediaLease lease) isDurablyRecovered;
  final Future<void> Function(PendingMediaLease lease) discard;

  Future<void> release(PendingMediaLease lease) async {
    try {
      final claimed = await claim(lease.encoded);
      if (claimed != null || !isDurablyRecovered(lease)) {
        await discard(lease);
      }
    } on PreferenceWriteException {
      // Reload proved the recovery record is still durable.
    } on PreferenceOutcomeUnknownException {
      // The record may still be durable; preserve the lease until refresh.
    }
  }

  Future<bool> keepForResult(PendingMediaLease lease, OcrResult result) async {
    if (result.isSuccess) {
      return true;
    }
    await release(lease);
    return false;
  }
}

class BookCaptureScreen extends StatefulWidget {
  const BookCaptureScreen({super.key});

  @override
  State<BookCaptureScreen> createState() => _BookCaptureScreenState();
}

class _BookCaptureScreenState extends State<BookCaptureScreen> {
  bool _busy = false;
  String? _errorKey;
  int _cropSequence = 0;
  late final String _workflowId =
      'book_${DateTime.now().microsecondsSinceEpoch}';

  String _newCropWorkflowId() =>
      '${_workflowId}_crop_${DateTime.now().microsecondsSinceEpoch}_'
      '${_cropSequence++}';

  String _newPickerWorkflowId() =>
      '${_workflowId}_picker_${DateTime.now().microsecondsSinceEpoch}_'
      '${_cropSequence++}';

  BookCropSession _cropSession(ImageCropper cropper) => BookCropSession(
    isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    refreshRecoveryState: Storage.refreshMediaRecoveryMarkers,
    ensureCanLaunch: () async {
      if (Storage.hasMediaRecoveryMarker) {
        throw StateError('An earlier crop recovery is still pending.');
      }
    },
    markLaunch: (workflowId) => Storage.markCropLaunch(workflowId: workflowId),
    clearLaunch: Storage.clearCropLaunch,
    clearCachedResult: () async {
      await cropper.recoverImage();
    },
  );

  bool _isDurablyRecovered(PendingMediaLease lease) =>
      RecoveredBookDraft.tryParse(Storage.recoveredBookLease)?.lease.encoded ==
      lease.encoded;

  Future<void> _discardUnlessDurablyRecovered(PendingMediaLease lease) async {
    if (_isDurablyRecovered(lease)) {
      return;
    }
    await (await BookImageService.store).discard(lease);
  }

  Future<void> _releaseRecoveredLease(PendingMediaLease lease) async {
    await RecoveredBookOcrLeaseOwner(
      claim: (expectedLease) =>
          Storage.claimRecoveredBookLease(expectedLease: expectedLease),
      isDurablyRecovered: _isDurablyRecovered,
      discard: (candidate) async =>
          (await BookImageService.store).discard(candidate),
    ).release(lease);
  }

  Future<void> _clearRecoveredAfterHandoff(PendingMediaLease lease) async {
    try {
      await Storage.claimRecoveredBookLease(expectedLease: lease.encoded);
    } on Object {
      // The destination route owns the lease. A duplicate durable record is
      // harmless and startup recovery ignores it after finalization.
    }
  }

  @override
  void initState() {
    super.initState();
    // 첫 진입 시 코치마크 1회 표시 (initState에서 직접 showModalBottomSheet 금지
    // → postFrameCallback으로 위젯 트리 안정화 후 호출).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (!Storage.tutBookSeen) {
        await showFeatureCoachSheet(context, FeatureCoach.book);
        await Storage.setTutBookSeen();
      }
      await _resumeRecoveredBook();
    });
  }

  Future<void> _resumeRecoveredBook() async {
    if (_busy || !mounted) {
      return;
    }
    final cropTitle = AppL10n.of(context).bookCropTitle;
    PendingMediaLease? sourceLease;
    PendingMediaLease? croppedLease;
    try {
      await Storage.refreshRecoveredMediaRecords();
      final recovered = Storage.recoveredBookLease;
      if (recovered.isEmpty) {
        return;
      }
      final draft = RecoveredBookDraft.tryParse(recovered);
      if (draft == null) {
        return;
      }
      sourceLease = draft.lease;
      final store = await BookImageService.store;
      final recoveredSource = await store.resolvePending(sourceLease);
      if (recoveredSource == null) {
        return;
      }
      setState(() => _busy = true);
      if (draft.phase == RecoveredBookPhase.cropped) {
        croppedLease = sourceLease;
        sourceLease = null;
      } else {
        final cropWorkflowId = _newCropWorkflowId();
        final cropper = ImageCropper();
        final accepted = await _cropSession(cropper).run(
          workflowId: cropWorkflowId,
          crop: () => cropper.cropImage(
            sourcePath: recoveredSource.path,
            compressQuality: bookCaptureJpegQuality,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: cropTitle,
                toolbarColor: SoriColors.primary,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false,
              ),
              IOSUiSettings(title: cropTitle, aspectRatioLockEnabled: false),
            ],
          ),
          acceptAndRecord: (cropped) =>
              acceptBookCrop(path: cropped.path, workflowId: cropWorkflowId),
        );
        if (accepted == null) {
          await _releaseRecoveredLease(sourceLease);
          sourceLease = null;
          return;
        }
        croppedLease = accepted.lease;
        final displaced = accepted.displacedLease;
        if (displaced != null && displaced.encoded != croppedLease.encoded) {
          await store.discard(displaced);
          if (sourceLease.encoded == displaced.encoded) {
            sourceLease = null;
          }
        }
      }
      final ocrLease = croppedLease;
      final ocrFile = store.pendingFile(ocrLease);
      final imageQualityFuture = BookCaptureImageQualityAnalyzer.analyzeFile(
        ocrFile,
      );
      final ocr = await SnapOcrService.recognizeKorean(ocrFile).timeout(
        const Duration(seconds: 45),
        onTimeout: () => OcrResult.failure(
          reason: OcrFailure.engineError,
          message: 'timeout',
        ),
      );
      final imageQuality = await imageQualityFuture;
      if (!mounted) {
        await _releaseRecoveredLease(ocrLease);
        croppedLease = null;
        return;
      }
      final keepOcrLease = await RecoveredBookOcrLeaseOwner(
        claim: (expectedLease) =>
            Storage.claimRecoveredBookLease(expectedLease: expectedLease),
        isDurablyRecovered: _isDurablyRecovered,
        discard: (candidate) async =>
            (await BookImageService.store).discard(candidate),
      ).keepForResult(ocrLease, ocr);
      if (!mounted) {
        if (keepOcrLease) {
          await _releaseRecoveredLease(ocrLease);
        }
        croppedLease = null;
        return;
      }
      if (!keepOcrLease) {
        croppedLease = null;
        setState(() {
          _errorKey = ocr.failure == OcrFailure.noKoreanFound
              ? 'no_korean'
              : 'ocr_error';
        });
        return;
      }
      setState(() => _busy = false);
      final navigation = Navigator.of(context).pushNamed(
        '/book/preview',
        arguments: buildBookPreviewArguments(
          ocr: ocr,
          imageQuality: imageQuality,
          imageLease: ocrLease.encoded,
        ),
      );
      croppedLease = null;
      await _clearRecoveredAfterHandoff(ocrLease);
      await navigation;
    } on Object {
      if (mounted) {
        setState(() => _errorKey = 'unknown');
      }
    } finally {
      try {
        if (sourceLease != null) {
          try {
            await _discardUnlessDurablyRecovered(sourceLease);
          } on Object {
            // Startup TTL reconciliation retries cleanup.
          }
        }
        if (croppedLease != null) {
          try {
            await _discardUnlessDurablyRecovered(croppedLease);
          } on Object {
            // Startup TTL reconciliation retries cleanup.
          }
        }
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) {
      return;
    }
    final l10n = AppL10n.of(context);

    // 웹은 "책 한 컷" 파이프라인(카메라 + dart:io File + ML Kit 온디바이스 OCR)을
    // 지원하지 않는다 → 무한 로딩 대신 명확히 안내하고 종료. (모바일 전용 기능)
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookCaptureWebNotice),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

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

    PendingMediaLease? pickedPending;
    PendingMediaLease? pending;
    try {
      // image_picker_android opens the system picker for gallery images, so
      // broad media-library permission is neither needed nor requested.
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          if (!mounted) {
            return;
          }
          setState(() {
            _busy = false;
            _errorKey = 'permission';
          });
          return;
        }
      }

      final usePickerRecovery =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      if (usePickerRecovery) {
        await Storage.refreshMediaRecoveryMarkers();
        if (Storage.hasMediaRecoveryMarker) {
          throw StateError('An earlier picker recovery is still pending.');
        }
      }
      final pickerWorkflowId = _newPickerWorkflowId();
      if (usePickerRecovery) {
        await Storage.markPickerLaunch(
          purpose: 'book',
          workflowId: pickerWorkflowId,
          attemptId: pickerWorkflowId,
        );
      }
      final XFile? picked;
      var pickerAccepted = false;
      try {
        picked = await ImagePicker().pickImage(
          source: source,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: bookCaptureJpegQuality,
        );
        if (picked == null) {
          pickerAccepted = true;
        } else {
          pickedPending = await acceptPickedBook(
            path: picked.path,
            workflowId: pickerWorkflowId,
            journalId: pickerWorkflowId,
          );
          pickerAccepted = true;
        }
      } finally {
        if (usePickerRecovery && pickerAccepted) {
          await Storage.clearPickerLaunch();
        }
      }
      if (picked == null) {
        if (!mounted) {
          return;
        }
        setState(() => _busy = false);
        return;
      }

      // Crop
      final cropWorkflowId = _newCropWorkflowId();
      final cropper = ImageCropper();
      final pickedFile = (await BookImageService.store).pendingFile(
        pickedPending!,
      );
      final accepted = await _cropSession(cropper).run(
        workflowId: cropWorkflowId,
        crop: () => cropper.cropImage(
          sourcePath: pickedFile.path,
          compressQuality: bookCaptureJpegQuality,
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
        ),
        acceptAndRecord: (cropped) =>
            acceptBookCrop(path: cropped.path, workflowId: cropWorkflowId),
      );
      if (accepted == null) {
        await _releaseRecoveredLease(pickedPending);
        pickedPending = null;
        if (!mounted) {
          return;
        }
        setState(() => _busy = false);
        return;
      }

      pending = accepted.lease;
      final displaced = accepted.displacedLease;
      if (displaced != null && displaced.encoded != pending.encoded) {
        try {
          await (await BookImageService.store).discard(displaced);
          if (pickedPending.encoded == displaced.encoded) {
            pickedPending = null;
          }
        } on Object {
          // Startup TTL reconciliation retries displaced-record cleanup.
        }
      }
      final file = (await BookImageService.store).pendingFile(pending);

      // OCR — erster Aufruf lädt das ML-Kit-Korean-Modell herunter (kann
      // dauern). Endlos-Spinner vermeiden: 45s Timeout → Fehlerkarte.
      final imageQualityFuture = BookCaptureImageQualityAnalyzer.analyzeFile(
        file,
      );
      final ocr = await SnapOcrService.recognizeKorean(file).timeout(
        const Duration(seconds: 45),
        onTimeout: () => OcrResult.failure(
          reason: OcrFailure.engineError,
          message: 'timeout',
        ),
      );
      final imageQuality = await imageQualityFuture;
      if (!ocr.isSuccess) {
        await _releaseRecoveredLease(pending);
        pending = null;
        if (!mounted) {
          return;
        }
        setState(() {
          _busy = false;
          _errorKey = ocr.failure == OcrFailure.noKoreanFound
              ? 'no_korean'
              : 'ocr_error';
        });
        return;
      }

      if (!mounted) {
        await _releaseRecoveredLease(pending);
        pending = null;
        return;
      }
      setState(() => _busy = false);

      final navigation = Navigator.of(context).pushNamed(
        '/book/preview',
        arguments: buildBookPreviewArguments(
          ocr: ocr,
          imageQuality: imageQuality,
          imageLease: pending.encoded,
        ),
      );
      final handedOff = pending;
      pending = null;
      await _clearRecoveredAfterHandoff(handedOff);
      await navigation;
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = 'unknown');
    } finally {
      try {
        if (pickedPending != null) {
          try {
            await _discardUnlessDurablyRecovered(pickedPending);
          } on Object {
            // Startup recovery retains durable picker ownership.
          }
        }
        if (pending != null) {
          try {
            await _discardUnlessDurablyRecovered(pending);
          } on Object {
            // Startup TTL reconciliation retries cleanup.
          }
        }
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    }
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
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.lg),
                Center(
                  child: Image.asset(
                    'assets/illustrations/book/book_camera_guide.png',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Mascot(
                      kind: MascotKind.magpie,
                      emotion: MascotEmotion.smile,
                      size: 130,
                    ),
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
