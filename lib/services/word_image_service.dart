import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'book_image_service.dart';
import 'picker_recovery_service.dart';
import 'storage_service.dart';

class ManagedMediaCleanupException implements Exception {
  const ManagedMediaCleanupException(this.causes);

  final List<Object> causes;
}

class WordImageService {
  static Future<PendingMediaLease?> pickPending(
    ImageSource source, {
    required String workflowId,
    ImagePicker? picker,
    Future<void> Function({
      required String purpose,
      required String workflowId,
    })?
    markLaunch,
    Future<void> Function()? clearLaunch,
  }) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return null;
      }
    }
    final attemptId =
        '${workflowId}_picker_${DateTime.now().microsecondsSinceEpoch}';
    final usePickerRecovery =
        Platform.isAndroid || markLaunch != null || clearLaunch != null;
    if (usePickerRecovery && markLaunch == null) {
      if (Storage.pickerRecoveryMarkerJson.isNotEmpty) {
        throw StateError('An earlier picker recovery is still pending.');
      }
      await Storage.markPickerLaunch(
        purpose: 'word',
        workflowId: workflowId,
        attemptId: attemptId,
      );
    } else if (usePickerRecovery) {
      await markLaunch!(purpose: 'word', workflowId: attemptId);
    }
    var pickerAccepted = false;
    try {
      final picked = await (picker ?? ImagePicker()).pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (picked == null) {
        pickerAccepted = true;
        return null;
      }
      final staged = await acceptPickedWord(
        path: picked.path,
        workflowId: workflowId,
        journalId: attemptId,
      );
      pickerAccepted = true;
      return staged;
    } finally {
      if (usePickerRecovery && pickerAccepted) {
        await (clearLaunch ?? Storage.clearPickerLaunch)();
      }
    }
  }

  static Future<File?> resolve(String? encoded) async =>
      BookImageService.resolve(encoded);

  static Future<void> deleteAll({
    Future<Directory> Function()? documentsDirectory,
  }) async {
    try {
      await deleteAllStrict(documentsDirectory: documentsDirectory);
    } on Object {
      // Ordinary reset is intentionally best effort.
    }
  }

  static Future<void> deleteAllStrict({
    Future<Directory> Function()? documentsDirectory,
  }) async {
    final docs =
        await (documentsDirectory ?? getApplicationDocumentsDirectory)();
    final failures = <Object>[];
    try {
      final configuredStore = documentsDirectory == null
          ? await BookImageService.store
          : ManagedMediaStore(
              documentsDirectory: docs,
              temporaryDirectory: docs,
            );
      await configuredStore.deleteAllStrict();
    } on Object catch (error) {
      failures.add(error);
    }
    for (final name in const ['wordbook_images', 'book_images']) {
      try {
        final legacy = Directory('${docs.path}${Platform.pathSeparator}$name');
        if (await legacy.exists()) {
          final docsCanonical = await docs.resolveSymbolicLinks();
          final legacyCanonical = await legacy.resolveSymbolicLinks();
          final expectedCanonical =
              '$docsCanonical${Platform.pathSeparator}$name';
          if (await FileSystemEntity.type(legacy.path, followLinks: false) ==
                  FileSystemEntityType.link ||
              !_samePath(legacyCanonical, expectedCanonical)) {
            throw StateError('Legacy media directory escaped documents.');
          }
          await legacy.delete(recursive: true);
        }
      } on Object catch (error) {
        failures.add(error);
      }
    }
    if (failures.isNotEmpty) {
      throw ManagedMediaCleanupException(List<Object>.unmodifiable(failures));
    }
  }

  static bool _samePath(String first, String second) {
    String normalize(String value) {
      var normalized = value.replaceAll(r'\', '/');
      if (Platform.isWindows) {
        normalized = normalized.toLowerCase();
      }
      return normalized.endsWith('/')
          ? normalized.substring(0, normalized.length - 1)
          : normalized;
    }

    return normalize(first) == normalize(second);
  }
}
