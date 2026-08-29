import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import 'pressable.dart';
import 'route_observer.dart';
import 'tokens.dart';

/// **SoriSpeech** — TtsService 위 얇은 파사드.
///
/// text(+voice) 키 하나당 진행 중인 요청은 **하나뿐**이다 — speak 든
/// prefetch 든, 같은 키로 두 번째 요청이 들어오면 이미 진행 중인 첫 번째
/// 요청의 해석(디스크→Storage→CF)에 합류한다. 화면 전환 중 같은 문장이
/// prefetch 로 먼저 들어오고 곧이어 speak 로 다시 들어와도(또는 그 반대
/// 순서로) 실제 네트워크/CF 호출은 키당 한 번만 나간다(검수#13⑤ — 예전엔
/// speak/prefetch 가 서로 다른 두 맵을 썼는데, 그러면 이 교차 조합에서
/// 전혀 dedupe 되지 않았다).
///
/// 보장 범위: [speak] 는 항상 **재생을 보장**한다 — 합류한 요청이
/// prefetch(캐시만 채우고 끝) 였다면, 그 해석이 끝나길 기다린 뒤 실제
/// 재생을 이어서 시작한다(이땐 캐시가 이미 따뜻해 로컬 1단에서 사실상
/// 즉시 끝난다 — 네트워크가 두 번 나가는 게 아니다). 두 [speak] 호출이
/// 겹치면 방금 시작한 재생에 합류해(재시작하지 않는다) 하나의 완료를
/// 함께 기다린다. [prefetch] 는 합류한 요청이 이미 재생(또는 다른
/// prefetch) 이었다면 그 완료만 기다리고 별도 요청 없이 끝난다 — 캐시는
/// 그 요청이 끝나는 순간 이미 채워져 있기 때문이다.
class SoriSpeech {
  SoriSpeech._();

  /// text(+voice) 키 → 그 키의 유일한 진행 중 요청. 값은 "재생됐는가" —
  /// prefetch 전용 요청은 재생하지 않으므로 완료 시 false 로 채운다.
  static final Map<String, Future<bool>> _inFlight = {};

  /// 화면이 구독하는 발화 상태. 저수준 서비스의 전역 notifier를 화면에
  /// 직접 노출하지 않아 테스트 주입·실패·취소 경로도 같은 상태 계약을 탄다.
  static final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  static int _speechGeneration = 0;
  static String? _activeSpeechKey;

  /// 실제 재생 호출 지점 — 테스트가 `TtsService`/Firebase 없이 가짜
  /// 카운팅 리졸버로 갈아끼울 수 있게 훅으로 둔다. 기본은 진짜 서비스.
  @visibleForTesting
  static Future<bool> Function(String text, String voice) speakImpl =
      (text, voice) => TtsService.speak(text, voice: voice);

  /// 느린 학습 재생 훅. 화면은 이 파사드를 통해 기존 0.65 배수 계약을
  /// 유지하고 저수준 서비스를 직접 참조하지 않는다.
  @visibleForTesting
  static Future<bool> Function(String text, String voice) speakSlowImpl =
      (text, voice) => TtsService.speakSlow(text, voice: voice);

  /// 실제 프리페치 호출 지점 — 위와 같은 이유의 훅.
  @visibleForTesting
  static Future<void> Function(String text, String voice) prefetchImpl =
      (text, voice) => TtsService.prefetch(text, voice: voice);

  /// 실제 정지 호출 지점 — 위 두 훅과 같은 이유. [SoriSpeechIndicator] 가
  /// 재생 중 탭=정지(WCAG 4.1.2)를 실제 TtsService/플랫폼 채널 없이
  /// 검증할 수 있게 한다.
  @visibleForTesting
  static Future<void> Function() stopImpl = () => TtsService.stop();

  /// 테스트 간 격리 — in-flight 맵과 훅을 진짜 구현으로 되돌린다.
  @visibleForTesting
  static void resetForTesting() {
    _inFlight.clear();
    ++_speechGeneration;
    _activeSpeechKey = null;
    speaking.value = false;
    speakImpl = (text, voice) => TtsService.speak(text, voice: voice);
    speakSlowImpl = (text, voice) => TtsService.speakSlow(text, voice: voice);
    prefetchImpl = (text, voice) => TtsService.prefetch(text, voice: voice);
    stopImpl = () => TtsService.stop();
  }

  static Future<bool> speak(String text, {String? voice}) {
    final resolvedVoice = voice ?? 'auto';
    final key = '$resolvedVoice|$text';
    final existing = _inFlight[key];
    if (existing != null) {
      // 이미 이 키로 뭔가 진행 중이다(재생이든 prefetch 든) — 새 해석을
      // 내지 않고 그게 끝나길 기다린다. 그게 재생이었다면(played=true) 그
      // 재생에 합류하는 것으로 끝. prefetch 였다면(played=false) 캐시만
      // 찼을 뿐 아무 소리도 안 났으므로 이어서 실제로 재생한다.
      return existing.then((played) {
        if (played) return true;
        return _startSpeak(key, text, resolvedVoice, speakImpl);
      });
    }
    return _startSpeak(key, text, resolvedVoice, speakImpl);
  }

  static Future<bool> speakSlow(String text, {String? voice}) {
    final resolvedVoice = voice ?? 'auto';
    final key = 'slow|$resolvedVoice|$text';
    final existing = _inFlight[key];
    if (existing != null) return existing;
    return _startSpeak(key, text, resolvedVoice, speakSlowImpl);
  }

  // ⚠️ speakImpl(...)/prefetchImpl(...) 뒤의 .then/.whenComplete 는 반드시
  // (1) 중간 변수로 한 번 끊고 (2) 콜백을 블록 바디로 쓸 것.
  // 진짜 원인(정정, 2026-08-27 사후 재분석): `_inFlight` 의 값 타입이
  // `Future<bool>` 이라, 화살표 바디 `.whenComplete(() =>
  // _inFlight.remove(key))` 는 `_inFlight.remove(key)` 의 반환값 — 바로
  // 그 키에 막 저장된, **지금 만들고 있는 이 future 자신** — 을 콜백의
  // 반환값으로 암묵 반환한다. `whenComplete` 콜백이 Future 를 반환하면
  // 바깥 future 는 그 반환된 Future 가 끝날 때까지 완료를 미루는데,
  // 여기선 그 반환된 Future 가 바깥 future 자기 자신이라 완료가 영원히
  // 미뤄진다(self-await). 예전 주석은 "원인 미상 + speak()↔prefetch()
  // 교차 합류에서만 재현"이라 적었지만 이건 착시였다 — 자기대기는 호출
  // 방식과 무관하게 항상 걸리고, 단독 호출 테스트는 그 Future 의 완료를
  // 끝까지 기다리지 않아 증상이 안 보였을 뿐이다. 블록 바디(`() {
  // _inFlight.remove(key); }`)는 반환값이 없어(void) 이 문제가 원천적으로
  // 없다 — 인라인 체인 방식으로 되돌릴 땐 이 메커니즘을 반드시 재확인할 것.
  static Future<bool> _startSpeak(
    String key,
    String text,
    String voice,
    Future<bool> Function(String text, String voice) resolver,
  ) {
    final previousKey = _activeSpeechKey;
    if (previousKey != null && previousKey != key) {
      // 취소된 요청의 완료가 나중에 와도 같은 키의 새 요청에 합류하지 않게
      // 맵에서 먼저 떼어낸다. 완료 콜백도 identity를 확인하므로 새 값을
      // 지우지 않는다.
      _inFlight.remove(previousKey);
    }
    final generation = ++_speechGeneration;
    _activeSpeechKey = key;
    speaking.value = true;

    Future<bool> resolve() async {
      if (previousKey != null && previousKey != key) {
        try {
          await stopImpl();
        } catch (_) {
          // 정지는 best-effort다. 새 발화까지 막거나 UI에 예외를 누출하지 않는다.
        }
      }
      if (generation != _speechGeneration) return false;
      try {
        return await resolver(text, voice);
      } catch (_) {
        // TtsService의 캐시→Storage→CF fallback은 그대로 두고, 최종 실패만
        // 화면 경계에서 false로 강등한다. 인디케이터는 아래 완료 블록에서
        // 반드시 idle로 복귀한다.
        return false;
      }
    }

    final resolved = resolve();
    late final Future<bool> future;
    future = resolved.whenComplete(() {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
      if (generation == _speechGeneration && _activeSpeechKey == key) {
        _activeSpeechKey = null;
        speaking.value = false;
      }
    });
    _inFlight[key] = future;
    return future;
  }

  static Future<void> prefetch(String text, {String? voice}) {
    final resolvedVoice = voice ?? 'auto';
    final key = '$resolvedVoice|$text';
    final existing = _inFlight[key];
    if (existing != null) {
      // 이미 이 키로 뭔가 진행 중이다 — 그게 끝나면(재생 경로였어도 같은
      // 해석 단계를 거치므로) 캐시는 이미 채워져 있다. 별도 요청을 내지
      // 않고 완료만 기다린다.
      return existing.then((_) {});
    }
    // _startSpeak 위 경고 참고 — 중간 변수 + 블록 바디 콜백 형태를 유지할 것.
    Future<void> resolve() async {
      try {
        await prefetchImpl(text, resolvedVoice);
      } catch (_) {
        // 프리페치는 best-effort다. 실제 탭의 speak fallback 순서는 건드리지
        // 않고, 미리받기 실패만 화면 밖으로 누출하지 않는다.
      }
    }

    final resolved = resolve();
    final notPlayed = resolved.then((_) {
      return false;
    });
    late final Future<bool> future;
    future = notPlayed.whenComplete(() {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    });
    _inFlight[key] = future;
    return future;
  }

  /// 여러 문장을 제한된 동시성으로 미리 받는다. 각 요청은 [prefetch]를
  /// 통과하므로 단건/배치 호출이 같은 in-flight 맵과 실패 격리를 공유한다.
  static Future<void> prefetchAll(
    Iterable<String> texts, {
    String? voice,
    int concurrency = 3,
  }) async {
    final queue = <String>{
      for (final text in texts)
        if (text.trim().isNotEmpty) text.trim(),
    }.toList();
    if (queue.isEmpty) return;

    var next = 0;
    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= queue.length) return;
        await prefetch(queue[index], voice: voice);
      }
    }

    final laneCount = concurrency.clamp(1, queue.length);
    await Future.wait([for (var i = 0; i < laneCount; i++) worker()]);
  }

  static Future<void> stop() async {
    final activeKey = _activeSpeechKey;
    ++_speechGeneration;
    _activeSpeechKey = null;
    if (activeKey != null) {
      _inFlight.remove(activeKey);
    }
    speaking.value = false;
    try {
      await stopImpl();
    } catch (_) {
      // UI 정지는 fail-soft다. 상태는 이미 idle로 복귀했다.
    }
  }
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
    void handleTap() {
      SoriSpeech.speak(text, voice: voice);
    }

    return Semantics(
      button: true,
      onTap: handleTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: handleTap,
        child: child,
      ),
    );
  }
}

/// **SoriSpeechIndicator** — 플립 카드 좌상단 재생 아이콘. 자기 탭을
/// [SoriPressable] 로 직접 처리해 `SoriContentFeed` 의 카드 배경 더블탭
/// Listener 와 절대 같은 아레나에 들어가지 않는다(검수#13① —
/// `SoriContentFeed.topAccessory` 슬롯에만 넣을 것).
///
/// 실제 탭 영역은 [SoriLayout.chromeRowTouchHeight](48dp — T9 의 48dp 피드
/// 스탬프와 같은 최소 터치 타깃 기준)로 잡는다. 예전엔 바깥
/// `SizedBox`가 40×40 이라 Flutter 가 히트테스트를 그 40×40 에서
/// 끊었다(`OverflowBox` 의 44×44 초과분은 **보이기만** 하고 눌리지
/// 않았다 — 검수#13 보강 fix 3). `SoriPressable` 을 48×48 `SizedBox` 로
/// 직접 감싸 `_Stamp`(content_feed.dart)와 같은 패턴으로 바꿨다 — 시각
/// 배지(44dp 원)·아이콘(18) 크기는 그대로다.
class SoriSpeechIndicator extends StatelessWidget {
  const SoriSpeechIndicator({super.key, required this.text, this.voice});

  final String text;
  final String? voice;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: SoriSpeech.speaking,
      builder: (context, speaking, _) {
        // 재생 중엔 탭이 재생을 다시 걸지 않고 멈춘다. 예전엔 둘 다
        // speak() 뿐이라, 재생 중 탭이 이미 진행 중인 요청에 합류만 하고
        // 끝나는 사실상 아무 일도 안 하는 조작이었다 — 그런데도 값(value)은
        // "재생 중"이라는, 대응하는 조작이 있는 것처럼 들리는 상태를
        // 알렸다(WCAG 4.1.2). 두 onTap 이 반드시 같은 분기를 타야 하므로
        // 한 곳에 묶는다 — 따로 적으면 이 버그가 재발한다.
        void handleTap() {
          if (speaking) {
            SoriSpeech.stop();
          } else {
            SoriSpeech.speak(text, voice: voice);
          }
        }

        return Semantics(
          button: true,
          label: t.speechIndicatorLabel,
          value: speaking ? t.speechIndicatorSpeaking : t.speechIndicatorIdle,
          onTap: handleTap,
          child: ExcludeSemantics(
            child: SoriPressable(
              onTap: handleTap,
              child: SizedBox(
                width: SoriLayout.chromeRowTouchHeight,
                height: SoriLayout.chromeRowTouchHeight,
                child: Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: s.surface.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        speaking
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_up_rounded,
                        size: 18,
                        color: SoriColors.contentCta,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// **ContentSpeechController** — 진입/전환 자동재생 + 이웃 prefetch +
/// 전환 시 정지. `SoriStudyFrame`/`SoriContentFeed` 를 감싸는 화면의
/// `State` 가 `RouteAware` 대신 이 컨트롤러 하나를 들고 위임한다.
///
/// [didPushNext]/[deactivate] 의 `TtsService.stop()` 은 **다음 프레임으로
/// 미룬다**(검수#13 보강 fix 2). 둘 다 화면 트리가 교체되는 빌드/레이아웃
/// 단계 한복판에서 불릴 수 있는데, `TtsService.stop()` 은 전역 `speaking`
/// ValueNotifier 를 동기로 뒤집어 그걸 구독하는 [SoriSpeechIndicator]의
/// `ValueListenableBuilder` 가 build 중에 다시 setState 를 시도하게
/// 만든다("setState() or markNeedsBuild() called during build" — T13,
/// `review_session_flipgate_test.dart` 5건 회귀로 발견, 화면별
/// `addPostFrameCallback` 워크어라운드 대신 여기서 한 번에 고친다). 세대
/// 토큰(`_generation`) 증가는 동기로 남긴다 — 예약된 `playOnEnter` 를
/// 즉시 무효화해야 하므로. 실제 정지 호출 하나만 한 프레임 미루면
/// 충돌 없이 같은 체감 지연(≈16ms, 사람 귀에 안 들림)으로 안전해지고,
/// 소비자(화면)마다 이 워크어라운드를 반복할 필요가 없다.
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
    _deferredStop();
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
    _deferredStop();
  }

  /// `TtsService.stop()` 을 다음 프레임으로 미룬다 — 클래스 doc 참고.
  void _deferredStop() {
    WidgetsBinding.instance.addPostFrameCallback((_) => SoriSpeech.stop());
  }

  void dispose() {
    _debounce?.cancel();
    unsubscribe();
  }
}
