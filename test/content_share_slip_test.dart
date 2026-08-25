import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/share_slip.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// ⛔ 실제 폰트를 안 실으면 `flutter test` 는 모든 글자를 같은 폭의 사각형으로
/// 그린다 — 꼬리말 사각형 띠가 textColumn 을 넘어 마진 검사를 깨고, 크기
/// 이분 탐색도 실기기와 다르게 돈다 (`chaekgado_shelf_test.dart` 와 같은 이유).
Future<void> _loadRealFonts() async {
  final loader = FontLoader('WantedSans');
  for (final path in const [
    'assets/fonts/WantedSans/WantedSans-Regular.otf',
    'assets/fonts/WantedSans/WantedSans-Medium.otf',
    'assets/fonts/WantedSans/WantedSans-SemiBold.otf',
    'assets/fonts/WantedSans/WantedSans-Bold.otf',
    'assets/fonts/WantedSans/WantedSans-ExtraBold.otf',
  ]) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

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
  ///
  /// [mergeGap] 미만의 밝은 행은 같은 띠의 일부로 잇는다 — `잘`처럼 자모가
  /// 세로로 조합된 음절 하나가 줄 전체일 때, ㅈㅏ 와 ㄹ 사이의 2~3px 틈이
  /// 줄 경계로 세지면 안 된다. 실제 줄 간격은 1080 기준 35px 를 넘는다.
  int inkBandsIn(Rect rect, double threshold, {int mergeGap = 16}) {
    var bands = 0;
    var gapRun = 1 << 20;
    for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
      var hasInk = false;
      for (var x = rect.left.ceil(); x < rect.right.floor(); x += 2) {
        if (at(x, y).computeLuminance() < threshold) {
          hasInk = true;
          break;
        }
      }
      if (hasInk) {
        if (gapRun >= mergeGap) bands++;
        gapRun = 0;
      } else {
        gapRun++;
      }
    }
    return bands;
  }

  void dispose() => image.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadRealFonts);

  // 실제 에셋의 황갈 종이는 **선형** 휘도(computeLuminance)로 바닥이 0.30,
  // 그레인 최저치가 0.32~0.37이다 (2026-08-25 PIL 선형 실측 — 절차형 폴백의
  // 상아색 #FFFDF6(0.75+)과 전혀 다르다). 먹(78% 알파)은 코어가 0.06, 안티
  // 에일리어싱 중간값도 0.17 아래라, 0.25 가 그 사이의 안전한 문턱이다.
  const inkThreshold = 0.25;

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

    // 두루마리 바깥은 전부 벽이어야 한다. 황갈 종이(선형 0.5~0.6)는 벽과
    // 밝기가 비슷해서 예전 "벽 < 종이" 값 사다리는 못 쓴다 — 이 에셋에서
    // 족자를 벽에서 띄우는 건 짙은 축(선형 <0.25)과 그림자다. 그래서
    // (1) 벽은 밝고, (2) 두루마리 위쪽엔 짙은 축이 실제로 그려져 있는지 본다.
    final wall = slip.at(6, slip.image.height ~/ 2);
    expect(wall.computeLuminance(), greaterThan(0.5));
    final rodProbe = Rect.fromCenter(
      center: Offset(
        l.scrollImageRect.center.dx,
        l.scrollImageRect.top + l.scrollImageRect.height * 0.045,
      ),
      width: 200,
      height: 30,
    );
    expect(slip.darkestIn(rodProbe), lessThan(0.25));

    // 축·마구리까지 포함한 에셋 전체를 그릴 자리도 좌우상하에 여백이 남는다.
    expect(l.scrollImageRect.left, greaterThan(0));
    expect(l.scrollImageRect.right, lessThan(ShareSlipRenderer.storySize.width));
    expect(l.scrollImageRect.top, greaterThan(0));
    expect(l.scrollImageRect.bottom, lessThan(ShareSlipRenderer.storySize.height));
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

    // 종이 안 좌우 여백이 깨끗해야 한다 — 글이 [textColumn] 을 안 벗어나면
    // 구조상 종이도 못 벗어난다(margin 이 그 안쪽에 있으므로). 종이 바깥은
    // 이제 실제 생성 에셋의 그림(축·마구리)이라 밝기로 "글자 없음"을 잴 수
    // 없다 — 그 자리를 재는 대신 여기서 원인을 잡는다.
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

  test('아무리 긴 글도 꼬리말 자리를 침범하지 않는다', () async {
    // 회귀: 크기 이분 탐색은 제일 작은 글씨로도 안 들어가면 그 배치를 그대로
    // 돌려줬다 — 문단을 통째로 붙여넣으면 글(+도장)이 예산 높이를 넘어
    // 아래로 흘러나갔다. 지금은 들어가는 줄까지만 남기고 말줄임으로 끝낸다.
    //
    // [contentArea] 와 [wordmarkBand] 사이에 일부러 좁은 틈을 뒀다 — 그
    // 틈에 먹이 있으면 콘텐츠(위에서) 아니면 꼬리말(아래에서)이 침범한
    // 것이다. 종이 안은 전부 같은 밝은 아이보리라 이 틈만 밝기로 잴 수 있다
    // (종이 바깥은 이제 실제 생성 에셋이라 원래도 어둡다).
    final slip = await _Slip.render(
      korean: List.filled(40, '아주긴문장조각입니다').join(' '),
      gloss: List.filled(40, 'ein sehr langer Satz').join(' '),
    );
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);

    final gap = Rect.fromLTRB(
      l.paper.left + 4,
      l.contentArea.bottom + 2,
      l.paper.right - 4,
      l.wordmarkBand.top - 2,
    );
    expect(slip.darkestIn(gap), greaterThan(inkThreshold));
    slip.dispose();
  });

  test('한 어절짜리 낱말은 한 줄로 앉는다 — 음절이 갈리지 않는다', () async {
    // 회귀: 어절 안을 끊는 것도 "칸에 들어간다"로 세던 판이 있었다. 그러면
    // 크기 탐색이 `안녕하세요` 를 `안녕하`/`세요` 로 쪼개 놓고 글씨를 더
    // 키우는 쪽을 골라 이겼다. 낱말 하나는 반드시 한 줄이어야 한다.
    //
    // 먹 띠 = 한국어 줄들 + 뜻 한 줄 + 도장. 한국어가 한 줄이면 3, 쪼개지면 4.
    const bandThreshold = 0.25; // 도장 붉은색(0.19)까지 세고 종이결은 뺀다.

    // [contentArea] 로 잰다(paper 전체가 아니라) — paper 는 꼬리말 띠까지
    // 포함해서, 늘 그려지는 꼬리말이 매번 띠 하나를 더 보태 세는 셈이 된다.
    final single = await _Slip.render(korean: '안녕하세요', gloss: 'Guten Tag');
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);
    expect(single.inkBandsIn(l.contentArea.deflate(8), bandThreshold), 3);
    single.dispose();

    // 대조군: 어절이 둘이면 접혀서 한 줄이 는다 — 띠 세는 방법 자체가
    // 줄 수에 반응한다는 확인이다(항상 3 을 뱉는 검사가 아니다).
    final twoWords = await _Slip.render(
      korean: '잘 부탁드립니다',
      gloss: 'Guten Tag',
    );
    expect(twoWords.inkBandsIn(l.contentArea.deflate(8), bandThreshold), 4);
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

  test('꼬리말은 종이 칸 안에 앉는다 — 잘라 올려도 출처가 남는다', () async {
    final slip = await _Slip.render(korean: '안녕하세요', gloss: 'Guten Tag');
    final l = ShareSlipLayout.of(ShareSlipRenderer.storySize);

    // [wordmarkBand] 안에는 꼬리말 글자가 실제로 그려져 있어야 한다.
    expect(slip.darkestIn(l.wordmarkBand), lessThan(inkThreshold));

    // 종이 맨 아래 가장자리(꼬리말 띠 밖, 아직 paper 안)는 비어 있어야
    // 한다 — 꼬리말이 종이 밑단을 넘어 실제 에셋의 짙은 축 쪽으로 새면
    // 안 읽힌다.
    final belowWordmark = Rect.fromLTRB(
      l.paper.left + 4,
      l.wordmarkBand.bottom + 2,
      l.paper.right - 4,
      l.paper.bottom - 2,
    );
    expect(slip.darkestIn(belowWordmark), greaterThan(inkThreshold));
    slip.dispose();
  });
}
