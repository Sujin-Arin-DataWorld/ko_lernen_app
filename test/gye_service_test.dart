import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/profanity_denylist.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/services/gye_service.dart';
import 'package:ko_lernen_app/widgets/sori/gye_feed.dart';

void main() {
  group('GyeService — 입장 코드', () {
    test('generateCode: 6자, 혼동 글자(O0I1L) 없음', () {
      for (var i = 0; i < 50; i++) {
        final c = GyeService.generateCode();
        expect(c.length, 6);
        expect(
          RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$').hasMatch(c),
          isTrue,
        );
        expect(c.contains(RegExp(r'[O0I1L]')), isFalse);
      }
    });

    test('isValidCodeFormat', () {
      final c = GyeService.generateCode();
      expect(GyeService.isValidCodeFormat(c), isTrue);
      expect(GyeService.isValidCodeFormat(c.toLowerCase()), isTrue); // 정규화
      expect(GyeService.isValidCodeFormat('ABC'), isFalse); // 짧음
      expect(GyeService.isValidCodeFormat('ABCDEO'), isFalse); // O 미포함
      expect(GyeService.isValidCodeFormat('ABCD1L'), isFalse); // 1·L 미포함
    });
  });

  group('GyeService.validatedName', () {
    test('trim 후 반환', () {
      expect(
        GyeService.validatedName('  Sori  ', 20, GyeError.invalidName),
        'Sori',
      );
    });
    test('빈/초과 길이 → throw', () {
      expect(
        () => GyeService.validatedName('', 20, GyeError.invalidName),
        throwsA(isA<GyeException>()),
      );
      expect(
        () => GyeService.validatedName('x' * 21, 20, GyeError.invalidName),
        throwsA(isA<GyeException>()),
      );
    });
    test('욕설 → throw', () {
      expect(
        () => GyeService.validatedName('shibal', 20, GyeError.invalidName),
        throwsA(isA<GyeException>()),
      );
    });
  });

  group('containsProfanity', () {
    test('EN/DE/KO + 난독화 잡음', () {
      expect(containsProfanity('fuck you'), isTrue);
      expect(containsProfanity('Arschloch!'), isTrue);
      expect(containsProfanity('병신'), isTrue);
      expect(containsProfanity('s.h.i.t'), isTrue);
    });
    test('깨끗한 이름 통과 (한글 보존)', () {
      expect(containsProfanity('안녕하세요'), isFalse);
      expect(containsProfanity('한글소리'), isFalse);
      expect(containsProfanity('Sori Team'), isFalse);
    });
    test('확장 세트 — 거짓 양성 회피 (일반 단어/지명/이름)', () {
      // 'ass'/'anal'/'cock'/'coon'/'mongo'/'년' 류 함정 미등재 확인.
      expect(containsProfanity('Wasserfall'), isFalse);
      expect(containsProfanity('Klasse 2026'), isFalse);
      expect(containsProfanity('Analyse-Profi'), isFalse);
      expect(containsProfanity('Peacock'), isFalse);
      expect(containsProfanity('Mongolei-Fan'), isFalse);
      expect(containsProfanity('한남동 주민'), isFalse);
      expect(containsProfanity('2026년 수강생'), isFalse);
      expect(containsProfanity('ㅋㅋㅋ'), isFalse);
    });
    test('확장 세트 — 신규 항목 차단', () {
      expect(containsProfanity('Hurensohn123'), isTrue);
      expect(containsProfanity('miss geburt'), isTrue);
      expect(containsProfanity('미친놈들'), isTrue);
      expect(containsProfanity('느금마야'), isTrue);
      expect(containsProfanity('motherFucker'), isTrue);
    });
  });

  group('filterBlocked (Play UGC 차단)', () {
    GyeFeedEvent ev(String actor, {Map<String, dynamic> payload = const {}}) =>
        GyeFeedEvent(
          id: actor,
          type: GyeFeedType.sticker,
          actorUid: actor,
          actorNickname: actor,
          payload: payload,
        );

    test('차단 없음 → 원본 그대로', () {
      final events = [ev('a'), ev('b')];
      expect(GyeService.filterBlocked(events, const {}), same(events));
    });

    test('차단한 actor의 이벤트 숨김', () {
      final out = GyeService.filterBlocked([ev('a'), ev('b'), ev('c')], {'b'});
      expect(out.map((e) => e.actorUid), ['a', 'c']);
    });

    test('차단한 사용자를 향한 응원(payload.targetUid)도 숨김', () {
      final out = GyeService.filterBlocked(
        [
          ev('a', payload: {'targetUid': 'b'}),
          ev('c', payload: {'targetUid': 'd'}),
        ],
        {'b'},
      );
      expect(out.length, 1);
      expect(out.single.actorUid, 'c');
    });
  });

  group('GyeFeed.splitReactions (피드 반응 D-3)', () {
    GyeFeedEvent ev(
      String id, {
      GyeFeedType type = GyeFeedType.packCleared,
      String? targetEventId,
      int stickerCode = 1,
    }) => GyeFeedEvent(
      id: id,
      type: type,
      actorUid: 'u_$id',
      actorNickname: id,
      payload: {
        'stickerCode': stickerCode,
        if (targetEventId != null) 'targetEventId': targetEventId,
      },
    );

    test('반응 없음 → 전부 타임라인', () {
      final split = GyeFeed.splitReactions([ev('e1'), ev('e2')]);
      expect(split.timeline.map((e) => e.id), ['e1', 'e2']);
      expect(split.reactions, isEmpty);
    });

    test('targetEventId 단 이벤트는 타임라인서 빠지고 대상별로 묶임', () {
      final split = GyeFeed.splitReactions([
        ev('e1'),
        ev('r1', type: GyeFeedType.sticker, targetEventId: 'e1'),
        ev('r2', type: GyeFeedType.sticker, targetEventId: 'e1'),
        ev('e2'),
      ]);
      expect(split.timeline.map((e) => e.id), ['e1', 'e2']);
      expect(split.reactions['e1']!.map((e) => e.id), ['r1', 'r2']);
      expect(split.reactions.containsKey('e2'), isFalse);
    });

    test('빈 targetEventId는 반응 아님 → 타임라인 유지', () {
      final split = GyeFeed.splitReactions([
        ev('r', type: GyeFeedType.sticker, targetEventId: ''),
      ]);
      expect(split.timeline.length, 1);
      expect(split.reactions, isEmpty);
    });
  });
}
