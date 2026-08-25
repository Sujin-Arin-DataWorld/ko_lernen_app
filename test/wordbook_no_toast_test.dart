import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Jin 2026-08-19, 가장 크게 반복한 불만:
/// "가장중요한건 저장기능인 책갈피 누르면 added ....to your word list가
///  안사라져. 0.5초후에 사라지게해줘. 아니면 밑에 창 안뜨고 하트누르는것처럼
///  책갈피가 채워지는 효과 나오게해줘."
///
/// 후자를 택했다. 0.5초 duration 은 이미 시도됐고 실패했는데, duration 이
/// 문제가 아니었기 때문이다:
///  - `hideCurrentSnackBar()` 는 ~250ms 역방향을 시작할 뿐 항목은
///    dismissed 에서야 큐에서 빠진다 → 곧이은 `showSnackBar` 는 교체가
///    아니라 **큐잉**이고, 연타하면 사슬처럼 쌓인다.
///  - Flutter 는 라우트가 current 일 때만 자동 소멸 타이머를 건다 →
///    모달 시트 위에서 뜬 바는 duration 과 무관하게 영영 안 사라진다.
/// 주석은 남겨야 한다 — 왜 이렇게 했는지가 그 파일에서 가장 중요한 문서다.
/// 잡아야 하는 건 되살아난 **코드**다.
String _codeOf(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .where((line) => !line.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  final add = _codeOf('lib/widgets/sori/wordbook_add.dart');

  test('저장 성공에 스낵바를 띄우지 않는다', () {
    expect(
      add,
      isNot(contains('hideCurrentSnackBar')),
      reason: 'hide 직후 show 는 교체가 아니라 큐잉이다 — 이게 안 사라지는 원인',
    );
    expect(
      add,
      isNot(contains('SnackBarAction')),
      reason: '액션이 달린 바는 모달 위에서 자동 소멸 타이머가 안 걸린다',
    );
    expect(add, isNot(contains('wbAdded')));
    expect(add, isNot(contains('wbAlreadyAdded')));
    expect(
      add,
      isNot(contains('bool notify')),
      reason: '화면마다 끄고 켜는 대신 성공 알림 자체를 없앴다',
    );
  });

  test('실패만 한 번 말한다', () {
    expect(add, contains('wbAddFailed'));
    expect(add, contains('soriToast'));
  });

  test('토스트 헬퍼는 큐가 자라지 않는 방식을 쓴다', () {
    final toast = _codeOf('lib/widgets/sori/toast.dart');
    expect(toast, contains('removeCurrentSnackBar'));
    expect(
      toast,
      isNot(contains('hideCurrentSnackBar')),
      reason: 'hide 는 역방향을 기다리므로 다음 바가 큐에 쌓인다',
    );
    expect(toast, isNot(contains('SnackBarAction')));
  });

  test('담김 상태를 저장소가 직접 알린다', () {
    final svc = _codeOf('lib/services/custom_pack_service.dart');
    expect(
      svc,
      contains('ValueNotifier<int> revision'),
      reason: '화면이 setState 를 잊어도 아이콘이 갱신돼야 한다',
    );
    expect(svc, contains('revision.value++'));

    final feed = _codeOf('lib/widgets/sori/content_feed.dart');
    expect(feed, contains('CustomPackService.revision'));
    expect(feed, contains('Icons.bookmark_rounded'));
    expect(
      add,
      contains('Icons.bookmark_rounded'),
      reason: 'AddToWordbookButton 도 채워지는 상태를 가져야 한다',
    );
  });

  test('책갈피를 쓰는 피드 화면은 담김 판정 키를 넘긴다', () {
    const screens = {
      'review_session_screen': 'bookmarkKey:',
      'listening_play_screen': 'AddToWordbookButton',
      'vocab_pack_screen': 'bookmarkKey:',
      'grammar_screen': 'bookmarked:',
      'smalltalk_screen': 'bookmarked:',
    };
    screens.forEach((screen, marker) {
      final s = _codeOf('lib/screens/$screen.dart');
      expect(s, contains(marker), reason: '$screen 의 책갈피가 상태를 안 보여준다');
    });
  });
}
