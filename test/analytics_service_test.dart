import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/analytics_service.dart';

class _RecordedEvent {
  const _RecordedEvent(this.name, this.parameters);
  final String name;
  final Map<String, Object>? parameters;
}

class _FakeAnalyticsClient implements AnalyticsEventClient {
  final List<_RecordedEvent> events = [];
  final List<String> screens = [];
  bool throwOnNext = false;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (throwOnNext) {
      throwOnNext = false;
      throw StateError('analytics unavailable');
    }
    events.add(_RecordedEvent(name, parameters));
  }

  @override
  Future<void> logScreenView({required String screenName}) async {
    if (throwOnNext) {
      throwOnNext = false;
      throw StateError('analytics unavailable');
    }
    screens.add(screenName);
  }
}

void main() {
  group('AnalyticsController', () {
    test('forwards events and screen views when consent is granted', () async {
      final client = _FakeAnalyticsClient();
      final controller = AnalyticsController(
        hasConsent: () => true,
        client: client,
      );

      await controller.logEvent('pack_completed', parameters: {'pack_id': 'a1'});
      await controller.logScreenView('/vocab');

      expect(client.events, hasLength(1));
      expect(client.events.single.name, 'pack_completed');
      expect(client.events.single.parameters, {'pack_id': 'a1'});
      expect(client.screens, ['/vocab']);
    });

    test('no-ops entirely when consent is withheld', () async {
      final client = _FakeAnalyticsClient();
      final controller = AnalyticsController(
        hasConsent: () => false,
        client: client,
      );

      await controller.logEvent('pack_completed');
      await controller.logScreenView('/vocab');

      expect(client.events, isEmpty);
      expect(client.screens, isEmpty);
    });

    test('swallows client errors so a flow is never broken', () async {
      final client = _FakeAnalyticsClient()..throwOnNext = true;
      final controller = AnalyticsController(
        hasConsent: () => true,
        client: client,
      );

      // Must not throw even though the underlying client does.
      await controller.logEvent('gye_created');
      expect(client.events, isEmpty);
    });

    test('re-reads consent on every call (late opt-in is honoured)', () async {
      final client = _FakeAnalyticsClient();
      var consent = false;
      final controller = AnalyticsController(
        hasConsent: () => consent,
        client: client,
      );

      await controller.logEvent('gye_joined');
      expect(client.events, isEmpty);

      consent = true;
      await controller.logEvent('gye_joined');
      expect(client.events.single.name, 'gye_joined');
    });
  });
}
