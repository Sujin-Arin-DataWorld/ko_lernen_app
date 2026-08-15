import 'package:flutter/material.dart';

/// Lets a deck face claim vertical drags only when its content really
/// overflows. A normal [Scrollable] joins the gesture arena even with zero
/// scroll extent, which otherwise steals Sori Deck's up/down save and skip
/// gestures from cards that already fit.
class ScrollOnlyIfOverflowing extends ScrollPhysics {
  const ScrollOnlyIfOverflowing({super.parent});

  @override
  ScrollOnlyIfOverflowing applyTo(ScrollPhysics? ancestor) =>
      ScrollOnlyIfOverflowing(parent: buildParent(ancestor));

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (position.maxScrollExtent <= 0 && position.minScrollExtent >= 0) {
      return false;
    }
    return super.shouldAcceptUserOffset(position);
  }
}

/// Standard physics for the front and back of a Sori Deck card.
const ScrollPhysics kSoriCardFacePhysics = ScrollOnlyIfOverflowing(
  parent: ClampingScrollPhysics(),
);
