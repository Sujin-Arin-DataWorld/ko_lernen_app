import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'book_image_service.dart';
import 'storage_service.dart';

enum PickerPurpose { book, word }

class PickerRecoveryMarker {
  const PickerRecoveryMarker({
    required this.purpose,
    required this.workflowId,
    this.attemptId,
  });

  final PickerPurpose purpose;
  final String workflowId;
  final String? attemptId;
  String get journalId => attemptId ?? workflowId;

  static PickerRecoveryMarker? tryParse(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map ||
          decoded['workflowId'] is! String ||
          (decoded['workflowId'] as String).isEmpty) {
        return null;
      }
      final purpose = switch (decoded['purpose']) {
        'book' => PickerPurpose.book,
        'word' => PickerPurpose.word,
        _ => null,
      };
      return purpose == null
          ? null
          : PickerRecoveryMarker(
              purpose: purpose,
              workflowId: decoded['workflowId'] as String,
              attemptId:
                  decoded['attemptId'] is String &&
                      (decoded['attemptId'] as String).isNotEmpty
                  ? decoded['attemptId'] as String
                  : null,
            );
    } on FormatException {
      return null;
    }
  }
}

class LostPickerData {
  const LostPickerData({this.paths = const [], this.error});

  final List<String> paths;
  final String? error;
}

Future<PendingMediaLease> acceptPickedBook({
  required String path,
  required String workflowId,
  required String journalId,
  ManagedMediaStore? mediaStore,
}) async {
  final store = mediaStore ?? await BookImageService.store;
  final lease = await store.stageRecoveredPicker(
    File(path),
    journalId,
    ManagedMediaKind.book,
  );
  if (lease == null) {
    throw StateError('Recovered picker output escaped application cache.');
  }
  final previousRecord = await Storage.setRecoveredBookLease(
    RecoveredBookDraft(
      workflowId: workflowId,
      lease: lease,
      phase: RecoveredBookPhase.picked,
    ).encoded,
  );
  await store.deleteTrustedTemporary(File(path));
  final previous = RecoveredBookDraft.tryParse(previousRecord)?.lease;
  if (previous != null && previous.encoded != lease.encoded) {
    try {
      await store.discard(previous);
    } on Object {
      // Pending TTL reconciliation retries displaced-book cleanup.
    }
  }
  return lease;
}

Future<PendingMediaLease> acceptPickedWord({
  required String path,
  required String workflowId,
  required String journalId,
  ManagedMediaStore? mediaStore,
}) async {
  final store = mediaStore ?? await BookImageService.store;
  final lease = await store.stageRecoveredPicker(
    File(path),
    journalId,
    ManagedMediaKind.word,
  );
  if (lease == null) {
    throw StateError('Recovered picker output escaped application cache.');
  }
  final displaced = await Storage.setRecoveredWordLease(
    jsonEncode({'workflowId': workflowId, 'lease': lease.encoded}),
  );
  await store.deleteTrustedTemporary(File(path));
  for (final encoded in displaced) {
    final previous = PendingMediaLease.tryParse(encoded);
    if (previous != null && previous.encoded != lease.encoded) {
      try {
        await store.discard(previous);
      } on Object {
        // Pending TTL reconciliation retries displaced-word cleanup.
      }
    }
  }
  return lease;
}

class PickerRecoveryService {
  static Future<void>? _startupOperation;

  static Future<void> recoverAtStartup({
    required bool isAndroid,
    LostDataGateway? gateway,
    ManagedMediaStore? mediaStore,
    Future<String?> Function(String value)? persistRecoveredBook,
    Future<List<String>> Function(String value)? persistRecoveredWord,
  }) {
    Future<void> recover(
      PickerPurpose purpose,
      String? path,
      String workflowId,
      String journalId,
    ) async {
      final activeStore = mediaStore ?? await BookImageService.store;
      final kind = purpose == PickerPurpose.book
          ? ManagedMediaKind.book
          : ManagedMediaKind.word;
      final lease = path == null
          ? await activeStore.findRecoveredPicker(journalId, kind)
          : await activeStore.stageRecoveredPicker(File(path), journalId, kind);
      if (lease == null) {
        return;
      }
      if (purpose == PickerPurpose.book) {
        final previousRecord =
            await (persistRecoveredBook ?? Storage.setRecoveredBookLease)(
              RecoveredBookDraft(
                workflowId: workflowId,
                lease: lease,
                phase: RecoveredBookPhase.picked,
              ).encoded,
            );
        final previous = RecoveredBookDraft.tryParse(previousRecord)?.lease;
        if (previous != null && previous.encoded != lease.encoded) {
          try {
            await activeStore.discard(previous);
          } on Object {
            // Pending TTL reconciliation retries displaced-book cleanup.
          }
        }
      } else {
        final displaced =
            await (persistRecoveredWord ?? Storage.setRecoveredWordLease)(
              jsonEncode({'workflowId': workflowId, 'lease': lease.encoded}),
            );
        for (final encoded in displaced) {
          final previous = PendingMediaLease.tryParse(encoded);
          if (previous != null && previous.encoded != lease.encoded) {
            try {
              await activeStore.discard(previous);
            } on Object {
              // Pending TTL reconciliation retries displaced-word cleanup.
            }
          }
        }
      }
      if (path != null) {
        await activeStore.deleteTrustedTemporary(File(path));
      }
    }

    return _startupOperation ??= PickerRecoveryCoordinator(
      gateway: gateway ?? ImagePickerLostDataGateway(),
      isAndroid: isAndroid,
      readMarker: () async =>
          PickerRecoveryMarker.tryParse(Storage.pickerRecoveryMarkerJson),
      clearMarker: Storage.clearPickerLaunch,
      recoverBook: (path, workflowId) =>
          recover(PickerPurpose.book, path, workflowId, workflowId),
      recoverWord: (path, workflowId) =>
          recover(PickerPurpose.word, path, workflowId, workflowId),
      recoverJournal: (marker) =>
          recover(marker.purpose, null, marker.workflowId, marker.journalId),
      recoverMarked: (path, marker) =>
          recover(marker.purpose, path, marker.workflowId, marker.journalId),
    ).recoverOnce();
  }

  static void resetForTesting() {
    _startupOperation = null;
  }
}

abstract interface class LostDataGateway {
  Future<LostPickerData> retrieveLostData();
}

class ImagePickerLostDataGateway implements LostDataGateway {
  ImagePickerLostDataGateway({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<LostPickerData> retrieveLostData() async {
    final response = await _picker.retrieveLostData();
    return LostPickerData(
      paths: response.files?.map((file) => file.path).toList() ?? const [],
      error: response.exception?.code,
    );
  }
}

class PickerRecoveryCoordinator {
  PickerRecoveryCoordinator({
    required this.gateway,
    required this.isAndroid,
    required this.readMarker,
    required this.clearMarker,
    required this.recoverBook,
    required this.recoverWord,
    this.recoverJournal,
    this.recoverMarked,
    this.setBusy,
  });

  final LostDataGateway gateway;
  final bool isAndroid;
  final Future<PickerRecoveryMarker?> Function() readMarker;
  final Future<void> Function() clearMarker;
  final Future<void> Function(String path, String workflowId) recoverBook;
  final Future<void> Function(String path, String workflowId) recoverWord;
  final Future<void> Function(PickerRecoveryMarker marker)? recoverJournal;
  final Future<void> Function(String? path, PickerRecoveryMarker marker)?
  recoverMarked;
  final void Function(bool value)? setBusy;
  Future<void>? _operation;

  Future<void> recoverOnce() {
    if (!isAndroid) {
      return Future<void>.value();
    }
    return _operation ??= _recover();
  }

  Future<void> _recover() async {
    setBusy?.call(true);
    var retrievalReturned = false;
    var shouldClearMarker = false;
    try {
      final marker = await readMarker();
      // retrieveLostData() clears image_picker's native cache. Await it fully:
      // a Dart timeout cannot cancel a late destructive completion.
      final result = await gateway.retrieveLostData();
      retrievalReturned = true;
      if (marker == null) {
        shouldClearMarker = true;
        return;
      }
      if (result.paths.isNotEmpty) {
        final path = result.paths.first;
        if (recoverMarked != null) {
          await recoverMarked!(path, marker);
        } else if (marker.purpose == PickerPurpose.book) {
          await recoverBook(path, marker.workflowId);
        } else {
          await recoverWord(path, marker.workflowId);
        }
      } else {
        if (recoverMarked != null) {
          await recoverMarked!(null, marker);
        } else {
          await recoverJournal?.call(marker);
        }
      }
      shouldClearMarker = true;
    } on Object {
      // A gateway failure or failed durable journal write preserves the marker
      // so the same workflow can reconnect on the next process launch.
    } finally {
      try {
        if (retrievalReturned && shouldClearMarker) {
          await clearMarker();
        }
      } finally {
        setBusy?.call(false);
      }
    }
  }
}
