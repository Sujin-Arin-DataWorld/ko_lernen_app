import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_stage.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

void main() {
  group('onboarding V2 companion confirmation media contract', () {
    test('uses the dedicated choose clip for each companion', () {
      expect(
        CharacterClips.chooseFor(MascotKind.tiger),
        'assets/video/character/tiger_choose.mp4',
      );
      expect(
        CharacterClips.chooseFor(MascotKind.magpie),
        'assets/video/character/magpie_choose.mp4',
      );
    });

    test('choose clips do not derive a separate companion SFX', () {
      expect(
        CharacterClips.sfxFor(CharacterClips.chooseFor(MascotKind.tiger)),
        isNull,
      );
      expect(
        CharacterClips.sfxFor(CharacterClips.chooseFor(MascotKind.magpie)),
        isNull,
      );
    });
  });

  // 2026-08-31 실기기: 확정 화면에서 비디오 뒤로 크림 사각형 매트가 보이고
  // 그 위에 정적 마스코트가 원형으로 겹쳐 보였다. 원인은 (1) blendColor가
  // 확정 스테이지의 실제 배경(그라디언트)과 다른 값이었고 (2) staticFallback이
  // 무조건 true라 초기화 중에도 정적 PNG가 떴기 때문. 아래는 그 배선 계약을
  // 소스 레벨에서 고정한다 — `character_clip_matte_test.dart`의 바이너리
  // 클립 대비 소스 검사(§'CharacterClips ↔ 번들 클립이 양방향으로 일치한다')와
  // 같은 기법이다: 이 화면은 videoReady=false 로만 안전하게 위젯 테스트할 수
  // 있어(플랫폼 채널 미모킹) 필드값만으로는 "무조건 true로 되돌아감"을 잡아낼
  // 수 없다. 소스 스캔으로 그 회귀를 직접 막는다.
  group('onboarding V2 confirmation preview source wiring', () {
    late String source;

    setUpAll(() {
      // Normalize CRLF → LF: on Windows checkouts the file is read with `\r\n`
      // line endings, which would silently break every `\n  }\n` search below.
      source = File(
        'lib/screens/onboarding_v2/onboarding_v2_journey_screen.dart',
      ).readAsStringSync().replaceAll('\r\n', '\n');
    });

    String previewBuilderBody() {
      final start = source.indexOf('Widget _buildCompanionPreview(');
      expect(start, greaterThanOrEqualTo(0));
      final end = source.indexOf('\n  }\n', start);
      expect(end, greaterThan(start));
      return source.substring(start, end);
    }

    test(
      'staticFallback tracks device video availability, never hardcoded',
      () {
        final body = previewBuilderBody();
        expect(
          body,
          contains('staticFallback: CharacterClipPlayer.videoUnavailable('),
          reason:
              'Hard-coding staticFallback:true redraws the static mascot even '
              'while the clip plays, reproducing the circular-overlay bug.',
        );
        expect(body, isNot(contains('staticFallback: true')));
      },
    );

    test('blendColor is wired to the shared stage matte, not a bare token', () {
      final body = previewBuilderBody();
      expect(
        body,
        contains('OnboardingConfirmationStage.matteFor(context, isJoy:'),
        reason:
            'The matte must come from the same function the stage backdrop '
            'uses so the two colors can never drift apart.',
      );
    });

    test('playback speed is set to the deliberate slower welcome pace', () {
      final body = previewBuilderBody();
      expect(body, contains('playbackSpeed: 0.85'));
    });
  });

  group('onboarding V2 confirmation preview widget contract', () {
    setUp(() async {
      TigerStageVideo.videoReady = false;
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
      await Storage.init();
    });

    Future<CharacterClipPlayer> pumpConfirmation(
      WidgetTester tester,
      OnboardingCompanion companion,
    ) async {
      final state =
          OnboardingJourneyState.initial(
            DateTime.utc(2026, 8, 31, 12),
          ).copyWith(
            phase: OnboardingPhase.confirmation,
            storyPage: StoryPageId.heritageJourney,
            purposeDraft: OnboardingPurpose.dailyTravel,
            levelDraft: LearnerLevel.a1,
            companionDraft: companion,
          );
      final coordinator = FirstRunCoordinator(
        repository: _MemoryJourneyRepository(state),
        legacyStateReader: _LegacyReader(
          const LegacyOnboardingSnapshot(
            consentAccepted: true,
            hasCompletedOnboarding: false,
          ),
        ),
        commitGateway: _CommitGateway(),
        clock: () => DateTime.utc(2026, 8, 31, 12),
      );

      await tester.pumpWidget(
        MaterialApp(
          // A fresh key forces a full teardown/rebuild on every call within
          // the same test — without it, Flutter treats the second call as an
          // update to the same element and reuses OnboardingV2JourneyScreen's
          // State, so it never re-runs _load() for the new companion.
          key: UniqueKey(),
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: OnboardingV2JourneyScreen(
            firstRunCoordinator: coordinator,
            initialResolution: FirstRunResolution(
              entry: FirstRunEntry.confirmation,
              state: state,
              migratedLegacyState: false,
            ),
          ),
        ),
      );
      for (
        var attempt = 0;
        attempt < 50 && find.byType(CharacterClipPlayer).evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CharacterClipPlayer), findsOneWidget);
      return tester.widget<CharacterClipPlayer>(
        find.byType(CharacterClipPlayer),
      );
    }

    testWidgets('confirmation preview plays at the deliberate slower pace', (
      tester,
    ) async {
      final player = await pumpConfirmation(tester, OnboardingCompanion.taego);
      expect(player.playbackSpeed, 0.85);
    });

    testWidgets(
      'confirmation preview matte exactly matches the stage backdrop for both companions',
      (tester) async {
        for (final companion in OnboardingCompanion.values) {
          final player = await pumpConfirmation(tester, companion);
          final stageContext = tester.element(
            find.byType(OnboardingConfirmationStage),
          );
          final expectedMatte = OnboardingConfirmationStage.matteFor(
            stageContext,
            isJoy: companion == OnboardingCompanion.joy,
          );
          expect(
            player.blendColor,
            expectedMatte,
            reason:
                'BlendMode.multiply only absorbs the clip\'s white mat when '
                'blendColor equals the color painted immediately behind it.',
          );

          final stageDecoration =
              tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(OnboardingConfirmationStage),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration;
          expect(
            stageDecoration.gradient,
            isNull,
            reason:
                'A gradient backdrop cannot equal a single blendColor at '
                'every pixel behind the video.',
          );
          expect(stageDecoration.color, expectedMatte);
        }
      },
    );

    testWidgets(
      'confirmation preview staticFallback matches live video availability',
      (tester) async {
        final player = await pumpConfirmation(tester, OnboardingCompanion.joy);
        final playerContext = tester.element(find.byType(CharacterClipPlayer));
        expect(
          player.staticFallback,
          CharacterClipPlayer.videoUnavailable(playerContext),
        );
      },
    );
  });
}

class _MemoryJourneyRepository implements OnboardingJourneyRepository {
  _MemoryJourneyRepository([this.state]);

  OnboardingJourneyState? state;

  @override
  Future<void> clear() async {
    state = null;
  }

  @override
  Future<OnboardingJourneyState?> load() async => state;

  @override
  Future<void> save(
    OnboardingJourneyState state, {
    void Function()? assertCurrentWrite,
  }) async {
    assertCurrentWrite?.call();
    this.state = state;
  }
}

class _LegacyReader implements LegacyOnboardingStateReader {
  _LegacyReader(this.snapshot);

  final LegacyOnboardingSnapshot snapshot;

  @override
  Future<LegacyOnboardingSnapshot> read() async => snapshot;
}

class _CommitGateway implements OnboardingCommitGateway {
  OnboardingPurpose? purpose;
  LearnerLevel? placement;
  LearnerLevel? browse;
  OnboardingCompanion? companion;

  @override
  Future<bool> hasConsent() async => true;

  @override
  Future<void> initializePlacement(
    LearnerLevel level, {
    String? expectedGeneration,
  }) async {
    placement = level;
  }

  @override
  Future<bool> isLegacyOnboardingComplete() async => true;

  @override
  Future<void> markLegacyOnboardingComplete() async {}

  @override
  Future<OnboardingCompanion?> readCompanion() async => companion;

  @override
  Future<OnboardingPlacementSnapshot> readPlacement() async {
    return OnboardingPlacementSnapshot(
      placementLevel: placement,
      browseLevel: browse,
    );
  }

  @override
  Future<OnboardingPurpose?> readPurpose() async => purpose;

  @override
  Future<void> saveCompanion(OnboardingCompanion companion) async {
    this.companion = companion;
  }

  @override
  Future<void> savePurpose(OnboardingPurpose purpose) async {
    this.purpose = purpose;
  }

  @override
  Future<void> synchronizeBrowseLevel(LearnerLevel level) async {
    browse = level;
  }
}
