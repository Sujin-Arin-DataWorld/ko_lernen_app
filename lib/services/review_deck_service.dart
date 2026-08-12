import '../models/book_page.dart';
import '../models/vocab.dart';
import 'bookshelf_service.dart';
import 'custom_pack_service.dart';
import 'data_loader.dart';

/// A1 (암기 엔진) — 복습 가능한 **모든** 단어의 단일 소스.
///
/// 기본 CSV 단어장 + "나만의 단어장"(커스텀 팩) + "책 한 컷"(책장) 단어를
/// 하나의 `List<Vocab>` 로 합쳐, 메인 SRS "오늘의 복습"이 사용자가 직접 모은
/// 단어까지 포함하도록 한다. 한국어 표제어 기준 중복 제거 (CSV 우선).
///
/// SRS 는 한국어 문자열을 키로 쓰므로, 여기서 합친 단어가 그대로
/// `Storage.todayGoalIds` / `srsReview` 와 연결된다.
class ReviewDeckService {
  static const String customLevelTag = '★'; // 복습 카드 우상단 레벨 표시용

  static Vocab _fromWord(ExtractedWord w) => Vocab(
    korean: w.korean,
    romanization: w.romanization,
    german: w.translationDe,
    level: customLevelTag,
    posDe: w.posDe,
    exampleKorean: w.exampleKorean,
    exampleGerman: w.exampleDe,
    topic: '',
  );

  /// CSV + 커스텀 팩 + 책장 단어를 합친 복습 풀. 한국어 기준 중복 제거.
  static Future<List<Vocab>> allReviewable() async {
    final out = <Vocab>[];
    final seen = <String>{};

    void add(Vocab v) {
      final k = v.korean.trim();
      if (k.isEmpty || !seen.add(k)) return;
      out.add(v);
    }

    // 1. 기본 CSV (커리큘럼 순서 보존 → "오늘 신규" 선정 순서 유지).
    try {
      for (final v in await DataLoader.loadVocab()) {
        add(v);
      }
    } catch (_) {
      /* CSV 로드 실패 시 커스텀만으로도 동작 */
    }

    // 2. 나만의 단어장 (커스텀 팩).
    for (final pack in CustomPackService.getAll()) {
      for (final w in pack.words) {
        add(_fromWord(w));
      }
    }

    // 3. 책 한 컷 (책장 페이지) 단어.
    try {
      for (final page in BookshelfService.getAllLocal()) {
        for (final w in page.words) {
          add(_fromWord(w));
        }
      }
    } catch (_) {
      /* best-effort */
    }

    return out;
  }
}
