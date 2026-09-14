import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

Future<VocabPackFinishRequest> packCompletionRequest({
  bool course = false,
  bool failed = false,
}) async {
  final packs = await VocabPackService.loadAll();
  final pack = packs.firstWhere((p) => p.bossWords.isNotEmpty);
  CoursePracticeContext? context;
  if (course) {
    final catalog = await CurriculumCatalog.load();
    final link = catalog.contentLinks.firstWhere(
      (link) =>
          link.contentKind == CurriculumContentKind.vocab &&
          pack.words.any((word) => word.id == link.contentId),
    );
    await CourseProgressService.shared.initializeForPlacement('a1');
    context = CoursePracticeContext.fromLink(link);
  }
  return VocabPackFinishRequest(
    pack: pack,
    siblingPacks: packs.where((p) => p.level == pack.level).toList(),
    bossAccuracy: failed ? 0 : 1,
    bossCorrect: failed ? 0 : pack.bossWords.length,
    bossTotal: pack.bossWords.length,
    quizCorrect: pack.normalWords.length,
    quizTotal: pack.normalWords.length,
    courseContext: context,
    completionStampMotif: motifForPackId(pack.id).name,
  );
}

// A different packaged vocabulary generation, without modifying any source asset.
void installChangedPackVocabulary() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final name = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        final file = File(name);
        if (!file.existsSync()) {
          return null;
        }
        var bytes = await file.readAsBytes();
        if (name == 'assets/data/korean_vocab.csv') {
          final raw = utf8.decode(bytes);
          final changed = raw.replaceFirst('안녕하세요', '안녕하십니까');
          if (changed == raw) {
            throw StateError('Expected production vocabulary witness missing');
          }
          bytes = Uint8List.fromList(utf8.encode(changed));
        }
        return ByteData.sublistView(bytes);
      });
  DataLoader.resetVocab();
  VocabPackService.reset();
}

void restorePackVocabulary() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
  DataLoader.resetVocab();
  VocabPackService.reset();
}
