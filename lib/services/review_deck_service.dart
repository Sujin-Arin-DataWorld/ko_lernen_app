import '../models/book_page.dart';
import '../models/vocab.dart';
import 'bookshelf_service.dart';
import 'custom_pack_service.dart';
import 'data_loader.dart';
import 'personalized_lesson_service.dart';

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

    // 1. 기본 CSV — 레벨 오름차순 안정 정렬. `todayNewIds` 는 입력 순서대로
    //    신규 카드를 뽑는데 CSV 원본은 레벨이 뒤섞여 있어, 그대로 두면 A2
    //    학습자에게 B1/B2 신규 단어가 나간다 (2026-08-13 테스터 리포트:
    //    "A2인데 양극화"). 레벨 내부의 큐레이션(pack) 순서는 보존한다.
    try {
      for (final v in sortByLevelStable(await DataLoader.loadVocab())) {
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

  /// 레벨 오름차순(A1부터 C2) **안정** 정렬. 같은 레벨 안에서는 입력
  /// 순서(큐레이션·pack_order)를 보존한다. Dart 의 `List.sort` 는 불안정이라
  /// 원본 인덱스를 tie-breaker 로 쓴다.
  static List<Vocab> sortByLevelStable(List<Vocab> list) {
    final indexed = <MapEntry<int, Vocab>>[
      for (var i = 0; i < list.length; i++) MapEntry(i, list[i]),
    ];
    indexed.sort((a, b) {
      final d =
          PersonalizedLessonService.levelRank(a.value.level) -
          PersonalizedLessonService.levelRank(b.value.level);
      return d != 0 ? d : a.key - b.key;
    });
    return [for (final e in indexed) e.value];
  }
}
