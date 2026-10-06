import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/models/yeopjeon_reward_moment.dart';
import 'package:ko_lernen_app/services/audio_policy.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';
import 'package:ko_lernen_app/widgets/sori/video_lease.dart';
import 'package:ko_lernen_app/widgets/sori/yeopjeon_reward_presentation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'support/real_fonts.dart';

class _Video extends VideoPlayerController {
  _Video() : super.asset('test') {
    value = const VideoPlayerValue(
      duration: Duration(seconds: 5),
      size: Size(960, 960),
      isInitialized: true,
    );
  }
  final volumes = <double>[];
  int plays = 0;
  bool released = false;
  @override
  Future<void> setLooping(bool loop) async {
    expect(loop, isFalse);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> play() async {
    plays++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  // The fake never allocates a native handle or platform streams.
  // ignore: must_call_super
  Future<void> dispose() async {
    released = true;
  }
}

YeopjeonRewardMoment _moment({bool first = true, bool recovery = false}) =>
    YeopjeonRewardMoment(
      claims: {
        'daily:2026-10-04:${first ? 'first' : 'second'}': first ? 20 : 10,
      },
      balance: first ? 20 : 30,
      source: recovery
          ? YeopjeonRewardSource.recovery
          : YeopjeonRewardSource.currentActivity,
      day: '2026-10-04',
    );

Widget _app(
  Widget child, {
  bool reduced = false,
  LearningJourneyObserver? observer,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  localizationsDelegates: AppL10n.localizationsDelegates,
  supportedLocales: AppL10n.supportedLocales,
  navigatorObservers: [soriRouteObserver, if (observer != null) observer],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_snd_master': false,
      'kl_haptics_enabled': false,
    });
    await Storage.init();
    AudioPolicy.instance.restoreDuckNow();
    SoundService.playImpl = (_) {};
  });
  tearDown(SoundService.resetForTesting);

  testWidgets('wallet contact releases the film before opening its detail', (
    tester,
  ) async {
    final video = _Video();
    var opened = 0;
    final lease = VideoLeaseCoordinator<VideoPlayerController>(
      create: (_) async => video,
      dispose: (v) => v.dispose(),
    );
    await tester.pumpWidget(
      _app(
        YeopjeonRewardPresentation(
          moment: _moment(),
          leaseCoordinator: lease,
          onOpenWallet: () => opened++,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(video.plays, 1);
    await tester.tap(find.byKey(const ValueKey('reward-confirmed-balance')));
    await tester.pump();
    await tester.pump();
    expect(opened, 1);
    expect(video.released, isTrue);
    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.text('+20'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'one-second deadline releases a late film and keeps confirmed amounts',
    (tester) async {
      final ready = Completer<VideoPlayerController>();
      final video = _Video();
      var allocations = 0;
      final lease = VideoLeaseCoordinator<VideoPlayerController>(
        create: (_) {
          allocations++;
          return ready.future;
        },
        dispose: (v) => v.dispose(),
      );
      await tester.pumpWidget(
        _app(
          YeopjeonRewardPresentation(
            moment: _moment(),
            leaseCoordinator: lease,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('Wallet balance: 20 yeopjeon'), findsOneWidget);
      expect(allocations, 1);
      await tester.pump(const Duration(milliseconds: 1001));
      ready.complete(video);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(video.plays, 0);
      expect(video.released, isTrue);
      expect(find.byType(VideoPlayer), findsNothing);
      expect(find.text('Wallet balance: 20 yeopjeon'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('speech mutes the film and background never restarts it', (
    tester,
  ) async {
    final video = _Video();
    final lease = VideoLeaseCoordinator<VideoPlayerController>(
      create: (_) async => video,
      dispose: (v) => v.dispose(),
    );
    await AudioPolicy.instance.setMasterOn(true);
    await AudioPolicy.instance.setDuckOnSpeech(false);
    AudioPolicy.instance.noteSpeechStarted();
    await tester.pumpWidget(
      _app(
        YeopjeonRewardPresentation(moment: _moment(), leaseCoordinator: lease),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(video.plays, 1);
    expect(video.volumes, everyElement(0));
    AudioPolicy.instance.restoreDuckNow();
    await tester.pump();
    expect(video.volumes.last, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(video.released, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(video.plays, 1);
    expect(find.byType(VideoPlayer), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    AudioPolicy.instance.restoreDuckNow();
  });

  testWidgets(
    'second, recovered and reduced-motion payouts never allocate video',
    (tester) async {
      var allocations = 0;
      final lease = VideoLeaseCoordinator<VideoPlayerController>(
        create: (_) async {
          allocations++;
          return _Video();
        },
        dispose: (v) => v.dispose(),
      );
      for (final config in [
        (false, false, false),
        (true, true, false),
        (true, false, true),
      ]) {
        await tester.pumpWidget(
          _app(
            YeopjeonRewardPresentation(
              key: UniqueKey(),
              moment: _moment(first: config.$1, recovery: config.$2),
              leaseCoordinator: lease,
            ),
            reduced: config.$3,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        expect(find.byType(VideoPlayer), findsNothing);
      }
      expect(allocations, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final visible in [true, false]) {
    testWidgets(
      'only a painted amount is shown to the journey: visible=$visible',
      (tester) async {
        final observer = LearningJourneyObserver();
        late BuildContext originContext;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                originContext = context;
                return const Text('origin');
              },
            ),
            observer: observer,
          ),
        );
        final journey = observer.begin(ModalRoute.of(originContext)!)!;
        final attempt = journey.beginAttempt()..complete();
        final moment = _moment(first: false);
        Navigator.of(originContext).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              body: ListView(
                children: [
                  if (!visible) const SizedBox(height: 1200),
                  YeopjeonRewardPresentation(moment: moment, attempt: attempt),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        final receipt = RewardReceipt(
          activityId: 'lesson',
          receiptId: 'id',
          yeopjeonReward: moment,
          items: [
            RewardReceiptItem(
              kind: SoriRewardKind.yeopjeon,
              amount: 10,
              identity: moment.claims.keys.single,
              label: const SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
            ),
          ],
        );
        expect(journey.unshown(receipt).isEmpty, visible);
        expect(journey.unshown(receipt).yeopjeonReward == null, visible);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'account invalidation stops the film and hides the stale receipt',
    (tester) async {
      final video = _Video();
      final lease = VideoLeaseCoordinator<VideoPlayerController>(
        create: (_) async => video,
        dispose: (v) => v.dispose(),
      );
      await tester.pumpWidget(
        _app(
          YeopjeonRewardPresentation(
            moment: _moment(),
            leaseCoordinator: lease,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      LocalDataLifetime.invalidate();
      await tester.pump();
      expect(video.released, isTrue);
      expect(find.text('Wallet balance: 20 yeopjeon'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'decoder failure falls back once and never changes saved balances',
    (tester) async {
      final sounds = <String>[];
      await AudioPolicy.instance.setMasterOn(true);
      SoundService.playImpl = sounds.add;
      final lease = VideoLeaseCoordinator<VideoPlayerController>(
        create: (_) async => throw StateError('decoder unavailable'),
        dispose: (v) => v.dispose(),
      );
      await tester.pumpWidget(
        _app(
          YeopjeonRewardPresentation(
            moment: _moment(),
            leaseCoordinator: lease,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(VideoPlayer), findsNothing);
      expect(find.byKey(const ValueKey('reward-flight-coin')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Wallet balance: 20 yeopjeon'), findsOneWidget);
      expect(sounds, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'closing before initialization releases a late controller without play',
    (tester) async {
      final ready = Completer<VideoPlayerController>();
      final video = _Video();
      final lease = VideoLeaseCoordinator<VideoPlayerController>(
        create: (_) => ready.future,
        dispose: (v) => v.dispose(),
      );
      await tester.pumpWidget(
        _app(
          YeopjeonRewardPresentation(
            moment: _moment(),
            leaseCoordinator: lease,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      ready.complete(video);
      await tester.pump();
      expect(video.plays, 0);
      expect(video.released, isTrue);
    },
  );

  testWidgets('an explicit different reveal revokes this film without replay', (
    tester,
  ) async {
    final videos = [_Video(), _Video()];
    var index = 0;
    final lease = VideoLeaseCoordinator<VideoPlayerController>(
      create: (_) async => videos[index++],
      dispose: (v) => v.dispose(),
    );
    await tester.pumpWidget(
      _app(
        YeopjeonRewardPresentation(moment: _moment(), leaseCoordinator: lease),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(videos.first.plays, 1);
    final other = lease.register(
      asset: 'explicit-reveal',
      eligible: true,
      onGranted: (_) {},
    );
    await tester.pump();
    await tester.pump();
    expect(videos.first.released, isTrue);
    expect(find.byType(VideoPlayer), findsNothing);
    await other.release();
    await tester.pump(const Duration(seconds: 2));
    expect(index, 2);
    expect(videos.first.plays, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final change in ['resize', 'reduce-motion']) {
    testWidgets(
      '$change settles a moving bundle with the same confirmed balance',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final presentation = YeopjeonRewardPresentation(
          moment: _moment(first: false),
        );
        await tester.pumpWidget(_app(presentation));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));
        expect(
          find.byKey(const ValueKey('reward-flight-coin')),
          findsOneWidget,
        );
        if (change == 'resize') {
          tester.view.physicalSize = const Size(800, 600);
          await tester.pump();
        } else {
          await tester.pumpWidget(_app(presentation, reduced: true));
        }
        expect(find.byKey(const ValueKey('reward-flight-coin')), findsNothing);
        expect(find.text('Wallet balance: 30 yeopjeon'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const ValueKey('reward-flight-coin')), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final hidden in ['background', 'disabled ticker']) {
    testWidgets(
      'a result painted in $hidden consumes no claim until actually visible',
      (tester) async {
        final observer = LearningJourneyObserver();
        late BuildContext origin;
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) {
                origin = context;
                return const Text('origin');
              },
            ),
            observer: observer,
          ),
        );
        final journey = observer.begin(ModalRoute.of(origin)!)!;
        final attempt = journey.beginAttempt()..complete();
        final moment = _moment(first: false);
        if (hidden == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
        }
        Navigator.of(origin).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              body: TickerMode(
                enabled: hidden != 'disabled ticker',
                child: YeopjeonRewardPresentation(
                  moment: moment,
                  attempt: attempt,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        final receipt = RewardReceipt(
          activityId: 'lesson',
          receiptId: 'hidden',
          yeopjeonReward: moment,
          items: [
            RewardReceiptItem(
              kind: SoriRewardKind.yeopjeon,
              amount: 10,
              identity: moment.claims.keys.single,
              label: const SoriLocalizedCopy(de: 'Yeopjeon', en: 'Yeopjeon'),
            ),
          ],
        );
        expect(journey.unshown(receipt).isEmpty, isFalse);
        expect(find.byKey(const ValueKey('reward-flight-coin')), findsNothing);
        if (hidden == 'background') {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          await tester.pump();
          expect(journey.unshown(receipt).isEmpty, isTrue);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
