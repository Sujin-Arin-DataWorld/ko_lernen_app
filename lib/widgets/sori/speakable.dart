import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/tts_service.dart';
import 'pressable.dart';
import 'route_observer.dart';
import 'tokens.dart';

/// **SoriSpeech** — TtsService 위 얇은 파사드. speak/prefetch 를 텍스트별
/// 공유 in-flight Future 로 묶어, 화면 전환 중 같은 문장을 두 번 요청해도
/// 네트워크/CF 호출이 한 번만 나가게 한다.
class SoriSpeech {
  SoriSpeech._();

  static final Map<String, Future<bool>> _inFlightSpeak = {};
  static final Map<String, Future<void>> _inFlightPrefetch = {};

  static Future<bool> speak(String text, {String? voice}) {
    final key = '${voice ?? 'auto'}|$text';
    final existing = _inFlightSpeak[key];
    if (existing != null) return existing;
    final future = TtsService.speak(text, voice: voice ?? 'auto').whenComplete(
      () => _inFlightSpeak.remove(key),
    );
    _inFlightSpeak[key] = future;
    return future;
  }

  static Future<void> prefetch(String text, {String? voice}) {
    final key = '${voice ?? 'auto'}|$text';
    final existing = _inFlightPrefetch[key];
    if (existing != null) return existing;
    final future = TtsService.prefetch(
      text,
      voice: voice ?? 'auto',
    ).whenComplete(() => _inFlightPrefetch.remove(key));
    _inFlightPrefetch[key] = future;
    return future;
  }

  static Future<void> stop() => TtsService.stop();
}

/// **SoriSpeakable** — 탭=재생 카드 래퍼. **플립 카드에는 쓰지 않는다** —
/// 플립 카드(탭=뒤집기)는 [SoriSpeechIndicator]만 쓴다(§4 계약).
class SoriSpeakable extends StatelessWidget {
  const SoriSpeakable({
    super.key,
    required this.text,
    required this.child,
    this.voice,
  });

  final String text;
  final String? voice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => SoriSpeech.speak(text, voice: voice),
      child: child,
    );
  }
}

/// **SoriSpeechIndicator** — 플립 카드 좌상단 재생 아이콘. 자기 탭을
/// [SoriPressable] 로 직접 처리해 `SoriContentFeed` 의 카드 배경 더블탭
/// Listener 와 절대 같은 아레나에 들어가지 않는다(검수#13① —
/// `SoriContentFeed.topAccessory` 슬롯에만 넣을 것).
class SoriSpeechIndicator extends StatelessWidget {
  const SoriSpeechIndicator({super.key, required this.text, this.voice});

  final String text;
  final String? voice;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService.speaking,
      builder: (context, speaking, _) => SizedBox(
        width: 40,
        height: 40,
        child: OverflowBox(
          minWidth: 44,
          maxWidth: 44,
          minHeight: 44,
          maxHeight: 44,
          child: SoriPressable(
            onTap: () => SoriSpeech.speak(text, voice: voice),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: s.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(
                speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                size: 18,
                color: SoriColors.contentCta,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **ContentSpeechController** — 진입/전환 자동재생 + 이웃 prefetch +
/// 전환 시 정지. `SoriStudyFrame`/`SoriContentFeed` 를 감싸는 화면의
/// `State` 가 `RouteAware` 대신 이 컨트롤러 하나를 들고 위임한다.
class ContentSpeechController with RouteAware {
  ContentSpeechController();

  Timer? _debounce;
  int _generation = 0;

  /// [route]는 화면의 `ModalRoute.of(context)`. `soriRouteObserver` 구독을
  /// 이 안에서 처리한다 — 호출부는 `didChangeDependencies`에서 한 번만
  /// 부르면 된다.
  void subscribe(ModalRoute<dynamic> route) {
    soriRouteObserver.subscribe(this, route);
  }

  void unsubscribe() {
    soriRouteObserver.unsubscribe(this);
  }

  /// 화면 진입/카드 전환 시 호출 — 150-250ms 디바운스 뒤 자동재생.
  /// 디바운스 중 다시 불리면(빠른 스와이프) 이전 예약은 취소된다.
  void playOnEnter(String text, {String? voice}) {
    final generation = ++_generation;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (generation != _generation) return; // 그새 supersede 됨
      SoriSpeech.speak(text, voice: voice);
    });
  }

  /// 다음/이전 카드 문장을 미리 받아 둔다(재생하지 않음).
  void prefetchNeighbors(Iterable<String> texts, {String? voice}) {
    for (final text in texts) {
      SoriSpeech.prefetch(text, voice: voice);
    }
  }

  @override
  void didPushNext() {
    _debounce?.cancel();
    ++_generation;
    TtsService.stop();
  }

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPopNext() {}

  /// 화면이 dispose 되기 전 호출 — `deactivate()`에서 부른다.
  void deactivate() {
    _debounce?.cancel();
    ++_generation;
    TtsService.stop();
  }

  void dispose() {
    _debounce?.cancel();
    unsubscribe();
  }
}
