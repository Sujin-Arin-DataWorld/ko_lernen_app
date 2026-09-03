import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/study_library_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps favorites, saved types, and due words separate', (
    tester,
  ) async {
    final repository = _libraryRepository();
    final bookmarkStorage = _MemoryBookmarkStorage();
    await tester.pumpWidget(
      _app(
        StudyLibraryScreen(
          repository: repository,
          bookmarkStore: bookmarkStorage.store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('좋다'), findsOneWidget);
    expect(find.text('학교'), findsNothing);
    await tester.scrollUntilVisible(find.text('-고 있다'), 240);
    expect(find.text('-고 있다'), findsOneWidget);

    await _selectView(tester, StudyLibraryView.saved);

    for (final entry in const <String, String>{
      '학교': 'Word',
      '-아/어야 하다': 'Grammar',
      '학교에 가요.': 'Sentence',
      '잘 부탁드립니다': 'Expression',
      'ㅏ': 'Hangeul',
    }.entries) {
      await tester.scrollUntilVisible(find.text(entry.key), 240);
      expect(find.text(entry.key), findsOneWidget);
      expect(find.text(entry.value), findsWidgets);
    }

    await _selectView(tester, StudyLibraryView.due);

    await tester.scrollUntilVisible(find.text('학교'), 240);
    expect(find.text('학교'), findsOneWidget);
    expect(find.text('좋다'), findsNothing);
    expect(find.text('-아/어야 하다'), findsNothing);
    expect(find.text('학교에 가요.'), findsNothing);
  });

  testWidgets('opens only the existing supported word review from Due', (
    tester,
  ) async {
    final bookmarkStorage = _MemoryBookmarkStorage();
    await tester.pumpWidget(
      _app(
        StudyLibraryScreen(
          repository: _libraryRepository(),
          bookmarkStore: bookmarkStorage.store,
        ),
        routes: {
          '/review': (_) => const Scaffold(
            body: SizedBox(key: ValueKey('existing-word-review')),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
    await _selectView(tester, StudyLibraryView.due);

    final action = find.byKey(
      const ValueKey('study-library-start-word-review'),
    );
    await tester.scrollUntilVisible(action, 240);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('existing-word-review')), findsOneWidget);
  });

  testWidgets(
    'saved type filters keep grammar and sentences out of the word deck',
    (tester) async {
      final bookmarkStorage = _MemoryBookmarkStorage();
      await tester.pumpWidget(
        _app(
          StudyLibraryScreen(
            repository: _libraryRepository(),
            bookmarkStore: bookmarkStorage.store,
          ),
          routes: <String, WidgetBuilder>{
            '/grammar': (_) => const Scaffold(
              body: SizedBox(key: ValueKey('grammar-practice-route')),
            ),
            '/smalltalk': (_) => const Scaffold(
              body: SizedBox(key: ValueKey('sentence-practice-route')),
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      await _selectView(tester, StudyLibraryView.saved);

      await _selectType(tester, StudyLibraryItemType.grammar);

      expect(find.text('-아/어야 하다'), findsOneWidget);
      expect(find.text('학교'), findsNothing);
      expect(find.text('학교에 가요.'), findsNothing);
      expect(
        find.byKey(const ValueKey('study-library-start-word-review')),
        findsNothing,
      );
      final grammarAction = find.byKey(
        const ValueKey('study-library-open-grammar-practice'),
      );
      await tester.scrollUntilVisible(grammarAction, 200);
      expect(tester.getSize(grammarAction).height, greaterThanOrEqualTo(48));
      await tester.tap(grammarAction);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('grammar-practice-route')),
        findsOneWidget,
      );

      Navigator.of(
        tester.element(find.byKey(const ValueKey('grammar-practice-route'))),
      ).pop();
      await tester.pumpAndSettle();
      await _selectType(tester, StudyLibraryItemType.sentence);

      expect(find.text('학교에 가요.'), findsOneWidget);
      expect(find.text('-아/어야 하다'), findsNothing);
      final sentenceAction = find.byKey(
        const ValueKey('study-library-open-sentence-practice'),
      );
      await tester.scrollUntilVisible(sentenceAction, 200);
      await tester.tap(sentenceAction);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sentence-practice-route')),
        findsOneWidget,
      );
    },
  );

  testWidgets('reports quarantined bookmarks without hiding other sources', (
    tester,
  ) async {
    final grammar = StudyItemKey(
      type: StudyLibraryItemType.grammar,
      id: 'grammar-liked',
    );
    final bookmarkStorage = _MemoryBookmarkStorage(
      raw: '{"version":999,"items":[]}',
    );
    final repository = StudyLibraryRepository(
      likedReader: _LikedReader([
        _record(
          grammar,
          StudyLibraryOrigin.liked,
          'grammar|grammar-liked',
          primary: '-(으)ㄴ 적이 있다',
        ),
      ]),
      customPackReader: const _CustomReader([]),
      bookshelfReader: const _BookshelfReader([]),
      srsReader: const _SrsReader([]),
      bookmarkReader: ProductionStudyLibraryBookmarkReader(
        bookmarkStorage.store,
        languageCode: 'en',
      ),
    );

    await tester.runAsync(repository.load);
    await tester.pumpWidget(
      _app(
        StudyLibraryScreen(
          repository: repository,
          bookmarkStore: bookmarkStorage.store,
        ),
      ),
    );

    await _settleLibrary(tester, repository);

    expect(find.text('Some saved bookmarks are unavailable'), findsOneWidget);
    expect(find.textContaining('newer app version'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('-(으)ㄴ 적이 있다'), 240);
    expect(find.text('-(으)ㄴ 적이 있다'), findsOneWidget);
    final action = find.byKey(
      ValueKey('study-library-bookmark-action-${grammar.encoded}'),
    );
    await tester.scrollUntilVisible(action, 160);
    expect(tester.widget<SoriButton>(action).onTap, isNull);
  });

  testWidgets(
    'typed save and remove preserve the heart and every source repository',
    (tester) async {
      final key = StudyItemKey(
        type: StudyLibraryItemType.grammar,
        id: 'liked-grammar',
      );
      final likedRecords = <StudyLibrarySourceRecord>[
        _record(
          key,
          StudyLibraryOrigin.liked,
          'grammar|liked-grammar',
          primary: '-고 싶다',
        ),
      ];
      final bookshelfRecords = <StudyLibrarySourceRecord>[
        _record(
          key,
          StudyLibraryOrigin.bookshelf,
          'page-1:grammar:0',
          primary: '-고 싶다',
          secondary: 'want to do',
        ),
      ];
      final bookmarkStorage = _MemoryBookmarkStorage();
      final repository = StudyLibraryRepository(
        likedReader: _LikedReader(likedRecords),
        customPackReader: const _CustomReader([]),
        bookshelfReader: _BookshelfReader(bookshelfRecords),
        srsReader: const _SrsReader([]),
        bookmarkReader: ProductionStudyLibraryBookmarkReader(
          bookmarkStorage.store,
          languageCode: 'en',
        ),
      );

      await tester.runAsync(repository.load);
      await tester.pumpWidget(
        _app(
          StudyLibraryScreen(
            repository: repository,
            bookmarkStore: bookmarkStorage.store,
          ),
        ),
      );

      await _settleLibrary(tester, repository);

      final action = find.byKey(
        ValueKey('study-library-bookmark-action-${key.encoded}'),
      );
      await tester.scrollUntilVisible(action, 200);
      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pump();
      expect(find.text('Save bookmark'), findsOneWidget);
      await tester.tap(action);
      await _settleLibrary(tester, repository);

      expect(bookmarkStorage.store.read().bookmarks.single.key, key);
      expect(bookmarkStorage.writeCount, 1);
      await tester.scrollUntilVisible(action, 160);
      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pump();
      expect(find.text('Remove bookmark'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);

      await tester.tap(action);
      await _settleLibrary(tester, repository);

      expect(bookmarkStorage.store.read().bookmarks, isEmpty);
      expect(bookmarkStorage.writeCount, 2);
      expect(
        likedRecords.single.sources.single.origin,
        StudyLibraryOrigin.liked,
      );
      expect(
        bookshelfRecords.single.sources.single.origin,
        StudyLibraryOrigin.bookshelf,
      );
      final after = (await tester.runAsync(repository.load))!;
      final entry = after.entries.single;
      expect(entry.isLiked, isTrue);
      expect(entry.isSaved, isTrue);
      expect(entry.origins, contains(StudyLibraryOrigin.bookshelf));
      expect(entry.origins, isNot(contains(StudyLibraryOrigin.typedBookmark)));
    },
  );

  testWidgets('German UI reflows at 320x640 and 200 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final bookmarkStorage = _MemoryBookmarkStorage();
    await tester.pumpWidget(
      _app(
        StudyLibraryScreen(
          repository: _libraryRepository(),
          bookmarkStore: bookmarkStorage.store,
        ),
        locale: const Locale('de'),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _openViewSheet(tester);
    for (final view in StudyLibraryView.values) {
      final control = find.byKey(ValueKey('study-library-view-${view.name}'));
      expect(control, findsOneWidget);
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(find.byKey(const ValueKey('study-library-view-saved')));
    await tester.pumpAndSettle();
    await _openTypeSheet(tester);
    for (final type in StudyLibraryItemType.values) {
      final control = find.byKey(ValueKey('study-library-type-${type.name}'));
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleLibrary(
  WidgetTester tester,
  StudyLibraryRepository repository,
) async {
  await tester.pump();
  await tester.runAsync(repository.load);
  await tester.pumpAndSettle();
}

Future<void> _openViewSheet(WidgetTester tester) async {
  final selector = find.byKey(const ValueKey('study-library-view-selector'));
  await tester.drag(find.byType(ListView), const Offset(0, 1000));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(selector, 200);
  await tester.tapAt(tester.getTopLeft(selector) + const Offset(24, 24));
  await tester.pumpAndSettle();
}

Future<void> _selectView(WidgetTester tester, StudyLibraryView view) async {
  await _openViewSheet(tester);
  await tester.tap(find.byKey(ValueKey('study-library-view-${view.name}')));
  await tester.pumpAndSettle();
}

Future<void> _openTypeSheet(WidgetTester tester) async {
  final f = find.byKey(const ValueKey('study-library-type-selector'));
  // §W-A2 재조사: 리스트 콘텐츠가 바뀌며 이 버튼의 y좌표가 매번 달라지는데
  // (측정: 첫 호출 y=56~104, 재호출 y=25.6~73.6 — 실측 30.4px 이동),
  // ensureVisible 없이 좌표만 재조회해 탭하면 직전 라우트 팝 전환의 오버레이
  // 잔상과 같은 화면좌표에서 충돌한다(실측: hit test가 RenderAnimatedOpacity/
  // _RenderTheater 체인 아래 다른 아이콘 글리프에 맞았다). 스크롤 가능
  // 목록 안의 크롬 행이므로 ensureVisible 로 명시적으로 자리를 잡는다.
  // origin/main §259 쪽은 리스트를 먼저 드래그해 스크롤 위치까지 맞춘 뒤
  // scrollUntilVisible/Scrollable.ensureVisible로 자리를 잡는다 — 서로 다른
  // 하위 문제(목록 스크롤 위치 vs 전환 오버레이 히트테스트 경합)를 다루므로
  // 병합 시 둘 다 유지한다.
  await tester.drag(find.byType(ListView), const Offset(0, 1000));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(f, 100);
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _selectType(WidgetTester tester, StudyLibraryItemType type) async {
  await _openTypeSheet(tester);
  await tester.tap(find.byKey(ValueKey('study-library-type-${type.name}')));
  await tester.pumpAndSettle();
}

Widget _app(
  Widget home, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  routes: routes,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child ?? const SizedBox.shrink(),
  ),
  home: home,
);

StudyLibraryRepository _libraryRepository() {
  final likedGrammar = StudyItemKey(
    type: StudyLibraryItemType.grammar,
    id: 'liked-progressive',
  );
  final heartOnlyWord = StudyItemKey(type: StudyLibraryItemType.word, id: '좋다');
  final savedWord = StudyItemKey(type: StudyLibraryItemType.word, id: '학교');
  return StudyLibraryRepository(
    likedReader: _LikedReader([
      _record(
        likedGrammar,
        StudyLibraryOrigin.liked,
        'grammar|liked-progressive',
        primary: '-고 있다',
      ),
      _record(
        heartOnlyWord,
        StudyLibraryOrigin.liked,
        'vocab|좋다',
        primary: '좋다',
      ),
    ]),
    customPackReader: const _CustomReader([]),
    bookshelfReader: const _BookshelfReader([]),
    srsReader: _SrsReader([
      StudyLibrarySrsRecord(key: savedWord, reviewCount: 3, isDue: true),
      StudyLibrarySrsRecord(key: heartOnlyWord, reviewCount: 4, isDue: true),
    ]),
    bookmarkReader: _BookmarkReader([
      _record(
        savedWord,
        StudyLibraryOrigin.typedBookmark,
        'unit-word',
        primary: '학교',
        secondary: 'school',
      ),
      _record(
        StudyItemKey(type: StudyLibraryItemType.grammar, id: 'must-grammar'),
        StudyLibraryOrigin.typedBookmark,
        'unit-grammar',
        primary: '-아/어야 하다',
      ),
      _record(
        StudyItemKey(
          type: StudyLibraryItemType.sentence,
          id: 'school-sentence',
        ),
        StudyLibraryOrigin.typedBookmark,
        'unit-sentence',
        primary: '학교에 가요.',
      ),
      _record(
        StudyItemKey(
          type: StudyLibraryItemType.expression,
          id: 'greeting-expression',
        ),
        StudyLibraryOrigin.typedBookmark,
        'unit-expression',
        primary: '잘 부탁드립니다',
      ),
      _record(
        StudyItemKey(type: StudyLibraryItemType.hangul, id: 'vowel-a'),
        StudyLibraryOrigin.typedBookmark,
        'unit-hangul',
        primary: 'ㅏ',
      ),
    ]),
  );
}

StudyLibrarySourceRecord _record(
  StudyItemKey key,
  StudyLibraryOrigin origin,
  String sourceId, {
  String? primary,
  String? secondary,
}) => StudyLibrarySourceRecord(
  key: key,
  primaryText: primary,
  secondaryText: secondary,
  sources: [StudyLibrarySource(origin: origin, sourceId: sourceId)],
);

final class _LikedReader implements StudyLibraryLikedReader {
  const _LikedReader(this.records);
  final List<StudyLibrarySourceRecord> records;

  @override
  Future<List<StudyLibrarySourceRecord>> readLiked() async => records;
}

final class _CustomReader implements StudyLibraryCustomPackReader {
  const _CustomReader(this.records);
  final List<StudyLibrarySourceRecord> records;

  @override
  Future<List<StudyLibrarySourceRecord>> readCustomPackItems() async => records;
}

final class _BookshelfReader implements StudyLibraryBookshelfReader {
  const _BookshelfReader(this.records);
  final List<StudyLibrarySourceRecord> records;

  @override
  Future<List<StudyLibrarySourceRecord>> readBookshelfItems() async => records;
}

final class _SrsReader implements StudyLibrarySrsReader {
  const _SrsReader(this.records);
  final List<StudyLibrarySrsRecord> records;

  @override
  Future<List<StudyLibrarySrsRecord>> readSrsRecords() async => records;
}

final class _BookmarkReader implements StudyLibraryBookmarkReader {
  const _BookmarkReader(this.records);

  final List<StudyLibrarySourceRecord> records;

  @override
  Future<StudyLibraryBookmarkSourceSnapshot> readBookmarks() async =>
      StudyLibraryBookmarkSourceSnapshot(
        records: records,
        health: StudyLibraryBookmarkHealth.healthy,
      );
}

final class _MemoryBookmarkStorage {
  _MemoryBookmarkStorage({this.raw = ''});

  String raw;
  int writeCount = 0;

  late final TypedStudyBookmarkStore store = TypedStudyBookmarkStore(
    readRaw: () => raw,
    writeRaw: (value) async {
      raw = value;
      writeCount++;
    },
  );
}
