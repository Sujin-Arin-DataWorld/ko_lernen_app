import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/share_slip.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 픽셀을 읽을 수 있게 디코드해 둔 렌더 결과.
class _Slip {
  _Slip(this._data, this.image);

  final Uint8List _data;
  final ui.Image image;

  static Future<_Slip> render({
    required String korean,
    required String gloss,
  }) async {
    final png = await ShareSlipRenderer.renderPng(korean: korean, gloss: gloss);
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final bytes = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    return _Slip(bytes!.buffer.asUint8List(), frame.image);
  }

  Color at(int x, int y) {
    final i = (y * image.width + x) * 4;
    return Color.fromARGB(
      _data[i + 3],
      _data[i],
      _data[i + 1],
      _data[i + 2],
    );
  }

  /// [rect] 안에서 가장 어두운 픽셀의 상대 휘도. 글자가 넘쳐 들어왔는지 본다.
  double darkestIn(Rect rect) {
    var darkest = 1.0;
    for (var y = rect.top.ceil(); y < rect.bottom.floor(); y += 2) {
      for (var x = rect.left.ceil(); x < rect.right.floor(); x += 2) {
        final l = at(x, y).computeLuminance();
        if (l < darkest) darkest = l;
      }
    }
    return darkest;
  }

  /// [rect] 안에서 먹이 있는 **가로 띠**의 개수. 글이 몇 줄로 앉았는지를
  /// 글자 자체를 못 읽는 자리에서 세는 방법이다.
  int inkBandsIn(Rect rect, double threshold) {
    var bands = 0;
    var inBand = false;
    for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
      var hasInk = false;
      for (var x = rect.left.ceil(); x < rect.right.floor(); x += 2) {
        if (at(x, y).computeLuminance() < threshold) {
          hasInk = true;
          break;
        }
      }
      if (hasInk && !inBand) bands++;
      inBand = hasInk;
    }
    return bands;
  }

  void dispose() => image.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 종이(#FFFDF6)·배접(#E5DCC4) 은 둘 다 휘도 0.75 위다. 먹(#1A1F1D) 은 0.02.
  // 0.45 는 그 사이 어디를 잡아도 되는 문턱이라, 글자 한 획만 들어와도 걸린다.
  const inkThreshold = 0.45;

  test('두루마리는 9:16이고 검정 외곽선이 없다', () async {
    final slip = await _Slip.render(korean: '안녕하세요', gloss: 'Guten Tag');
    final image = slip.image;

    expect(image.width / image.height, closeTo(9 / 16, 0.01));

    bool isBlackOutline(Color c) {
      return (c.r * 255) < 20 &&
          (c.g * 255) < 20 &&
          (c.b * 255) < 20 &&
          (c.a * 255) > 200;
    }

    expect(isBlackOutline(slip.at(0, 0)), isFalse);
    expect(isBlackOutline(slip.at(image.width - 1, 0)), isFalse);
    expect(isBlackOutline(slip.at(0, image.height - 1)), isFalse);
    expect(
      isBlackOutline(slip.at(image.width - 1, image.height - 1)),
      isFalse,
    );

    final mid = slip.at(image.width ~/ 2, (image.height * 0.12).round());
    expect(
      mid.computeLuminance(),
      greaterThan(SoriColors.lightText.computeLuminance()),
    );
    slip.dispose();
  });

  test('PNG 헤더가 붙어 나온다', () async {
    final png = await ShareSlipRenderer.renderPng(
      korean: '안녕하세요',
      gloss: 'Guten Tag',
    );
    expect(png.length, greaterThan(800));
    expect(png[0], 0x89);
    expect(png[1], 0x50);
  });

  test('족자는 화면 네 변에 닿지 않는다 — 벽 위에 걸려 있다', () async {
    final slip = await _Slip.render(korean: '안녕하세요', gloss: 'Guten Tag');
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);

    // 배접 바깥은 전부 벽이어야 한다. 벽은 종이보다 어둡다 — 그래야 족자가
    // 배경에서 떠오른다(값 사다리: 벽 < 배접 < 종이).
    final wall = slip.at(6, slip.image.height ~/ 2);
    final paper = slip.at(l.paper.center.dx.round(), l.paper.top.round() + 40);
    expect(wall.computeLuminance(), lessThan(paper.computeLuminance()));

    // 축까지 포함해도 좌우 끝에 여백이 남는다.
    expect(l.topRod.left, greaterThan(0));
    expect(l.bottomRod.right, lessThan(ShareSlipRenderer.storySize.width));
    expect(l.topRod.top, greaterThan(0));
    slip.dispose();
  });

  test('긴 문장도 종이 밖으로 넘치지 않는다', () async {
    // 어절이 많고 마지막 어절이 긴, 줄바꿈이 제일 어려운 모양.
    final slip = await _Slip.render(
      korean: '포기하지 않으면 언젠가는 반드시 이루어집니다',
      gloss: 'Wer nicht aufgibt, wird es eines Tages ganz sicher schaffen',
    );
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);

    // 종이의 좌우 여백 — 글칸 바깥이라 먹이 한 점도 없어야 한다.
    final leftMargin = Rect.fromLTRB(
      l.paper.left + 6,
      l.paper.top + 6,
      l.textColumn.left - 6,
      l.paper.bottom - 6,
    );
    final rightMargin = Rect.fromLTRB(
      l.textColumn.right + 6,
      l.paper.top + 6,
      l.paper.right - 6,
      l.paper.bottom - 6,
    );
    expect(slip.darkestIn(leftMargin), greaterThan(inkThreshold));
    expect(slip.darkestIn(rightMargin), greaterThan(inkThreshold));
    slip.dispose();
  });

  test('칸보다 넓은 어절 하나도 종이 밖으로 못 나간다', () async {
    // 회귀: 예전 판은 어절을 절대 안 끊어서, 띄어쓰기 없는 긴 낱말이 오면
    // 글씨를 최소까지 줄여도 한 줄에 안 들어가 **배접 위로 넘쳐 나갔다**.
    // 독일어 합성명사는 뜻 줄에서 실제로 이만큼 길어진다.
    final slip = await _Slip.render(
      korean: '한국어능력시험준비반수강생모집안내문',
      gloss: 'Rindfleischetikettierungsüberwachungsaufgabenübertragungsgesetz',
    );
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);

    // 종이 바깥(왼쪽 배접) 에 먹이 한 점도 없어야 한다.
    final outsidePaper = Rect.fromLTRB(
      l.mount.left + 4,
      l.paper.top,
      l.paper.left - 4,
      l.paper.bottom,
    );
    expect(slip.darkestIn(outsidePaper), greaterThan(inkThreshold));

    // 종이 안 좌우 여백도 깨끗해야 한다.
    expect(
      slip.darkestIn(
        Rect.fromLTRB(
          l.paper.left + 4,
          l.paper.top + 4,
          l.textColumn.left - 4,
          l.paper.bottom - 4,
        ),
      ),
      greaterThan(inkThreshold),
    );
    slip.dispose();
  });

  test('아무리 긴 글도 종이 위아래로 넘치지 않는다', () async {
    // 회귀: 크기 이분 탐색은 제일 작은 글씨로도 안 들어가면 그 배치를 그대로
    // 돌려줬다 — 문단을 통째로 붙여넣으면 글이 종이 위아래를 넘어 배접까지
    // 흘러나갔다. 지금은 들어가는 줄까지만 남기고 말줄임으로 끝낸다.
    final slip = await _Slip.render(
      korean: List.filled(40, '아주긴문장조각입니다').join(' '),
      gloss: List.filled(40, 'ein sehr langer Satz').join(' '),
    );
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);

    // 단청 띠(위 배접 한가운데)와 꼬리말(아래 배접 한가운데)은 원래 어두우니
    // 피하고, 종이 바로 위 배접만 본다 — 여기 먹이 있으면 글이 넘친 것이다.
    final gapAbovePaper = Rect.fromLTRB(
      l.mount.left + 4,
      l.paper.top - 24,
      l.mount.right - 4,
      l.paper.top - 3,
    );
    expect(slip.darkestIn(gapAbovePaper), greaterThan(inkThreshold));
    slip.dispose();
  });

  test('한 어절짜리 낱말은 한 줄로 앉는다 — 음절이 갈리지 않는다', () async {
    // 회귀: 어절 안을 끊는 것도 "칸에 들어간다"로 세던 판이 있었다. 그러면
    // 크기 탐색이 `안녕하세요` 를 `안녕하`/`세요` 로 쪼개 놓고 글씨를 더
    // 키우는 쪽을 골라 이겼다. 낱말 하나는 반드시 한 줄이어야 한다.
    //
    // 먹 띠 = 한국어 줄들 + 뜻 한 줄 + 도장. 한국어가 한 줄이면 3, 쪼개지면 4.
    const bandThreshold = 0.25; // 도장 붉은색(0.19)까지 세고 종이결은 뺀다.

    final single = await _Slip.render(korean: '안녕하세요', gloss: 'Guten Tag');
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);
    expect(single.inkBandsIn(l.paper.deflate(8), bandThreshold), 3);
    single.dispose();

    // 대조군: 어절이 둘이면 접혀서 한 줄이 는다 — 띠 세는 방법 자체가
    // 줄 수에 반응한다는 확인이다(항상 3 을 뱉는 검사가 아니다).
    final twoWords = await _Slip.render(
      korean: '잘 부탁드립니다',
      gloss: 'Guten Tag',
    );
    expect(twoWords.inkBandsIn(l.paper.deflate(8), bandThreshold), 4);
    twoWords.dispose();
  });

  test('같은 단어는 언제 렌더해도 같은 그림이 된다', () async {
    final a = await ShareSlipRenderer.renderPng(
      korean: '안녕하세요',
      gloss: 'Guten Tag',
    );
    final b = await ShareSlipRenderer.renderPng(
      korean: '안녕하세요',
      gloss: 'Guten Tag',
    );
    // 종이결이 난수라도 단어로 seed 를 잡으므로 바이트까지 같아야 한다.
    expect(a, equals(b));
  });

  test('뜻이 비어도 한국어만으로 렌더된다', () async {
    final slip = await _Slip.render(korean: '물', gloss: '');
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);
    // 뜻 줄이 없다고 글이 종이 밖으로 나가거나 빈 그림이 되면 안 된다.
    expect(slip.darkestIn(l.textColumn), lessThan(inkThreshold));
    slip.dispose();
  });

  test('꼬리말은 아래 배접 안에 앉는다 — 잘라 올려도 출처가 남는다', () async {
    final slip = await _Slip.render(korean: '안녕하세요', gloss: 'Guten Tag');
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);
    final lowerMount = Rect.fromLTRB(
      l.mount.left + 6,
      l.paper.bottom + 6,
      l.mount.right - 6,
      l.mount.bottom - 6,
    );
    // 배접(#E5DCC4, 휘도 0.72)만 있으면 문턱을 넘는다 — 글자가 있어야 내려간다.
    expect(slip.darkestIn(lowerMount), lessThan(inkThreshold));
    slip.dispose();
  });
}
