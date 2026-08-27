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

  /// 실제 재생 호출 지점 — 테스트가 `TtsService`/Firebase 없이 가짜
  /// 카운팅 리졸버로 갈아끼울 수 있게 훅으로 둔다. 기본은 진짜 서비스.
  @visibleForTesting
  static Future<bool> Function(String text, String voice) speakImpl =
      (text, voice) => TtsService.speak(text, voice: voice);

  /// 실제 프리페치 호출 지점 — 위와 같은 이유의 훅.
  @visibleForTesting
  static Future<void> Function(String text, String voice) prefetchImpl =
      (text, voice) => TtsService.prefetch(text, voice: voice);

  /// 테스트 간 격리 — in-flight 맵과 훅을 진짜 구현으로 되돌린다.
  @visibleForTesting
  static void resetForTesting() {
    _inFlight.clear();
    speakImpl = (text, voice) => TtsService.speak(text, voice: voice);
    prefetchImpl = (text, voice) => TtsService.prefetch(text, voice: voice);
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
        return _startSpeak(key, text, resolvedVoice);
      });
    }
    return _startSpeak(key, text, resolvedVoice);
  }

  // ⚠️ speakImpl(...)/prefetchImpl(...) 뒤의 .then/.whenComplete 는 반드시
  // (1) 중간 변수로 한 번 끊고 (2) 콜백을 블록 바디로 쓸 것.
  // 관찰(2026-08-27, 검수#13): 함수-타입 필드 호출 뒤에 `.then((_) => false)`/
  // `.whenComplete(() => _inFlight.remove(key))` 처럼 콜백을 한 문으로 이어 붙이면,
  // `speak()`↔`prefetch()` 교차 합류 경로에서 그 Future 가 완료되지 않고 영원히
  // pending 으로 남는 현상이 보고됐다(공유 in-flight 맵을 거쳐 다른 함수의 `.then`이
  // 그 결과를 기다릴 때만 재현, 단독 호출로는 재현 안 됨). 원인은 특정되지 않았으나,
  // 아래 형태(중간 변수 + 블록 바디)로 바꾸면 항상 해소되므로, 인라인 체인 방식으로
  // 리팩터링할 때는 재검증이 필요하다.
  static Future<bool> _startSpeak(String key, String text, String voice) {
    final resolved = speakImpl(text, voice);
    final future = resolved.whenComplete(() {
      _inFlight.remove(key);
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
    final resolved = prefetchImpl(text, resolvedVoice);
    final notPlayed = resolved.then((_) {
      return false;
    });
    final future = notPlayed.whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
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
      valueListenable: TtsService.speaking,
      builder: (context, speaking, _) => Semantics(
        button: true,
        label: t.speechIndicatorLabel,
        value: speaking ? t.speechIndicatorSpeaking : t.speechIndicatorIdle,
        onTap: () => SoriSpeech.speak(text, voice: voice),
        child: ExcludeSemantics(
          child: SoriPressable(
            onTap: () => SoriSpeech.speak(text, voice: voice),
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
      ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => TtsService.stop());
  }

  void dispose() {
    _debounce?.cancel();
    unsubscribe();
  }
}
