import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/korean_proofreading_service.dart';
import 'package:ko_lernen_app/services/scenario_writing_check_service.dart';

void main() {
  group('ScenarioWritingEvidence', () {
    test('uses user dialogue and only complete inline grammar', () {
      final evidence = ScenarioWritingEvidence.fromScenario(
        scenario: _scenario,
        language: 'en',
      );

      expect(evidence.references.map((reference) => reference.korean), <String>[
        '저는 내일 공부할 거예요.',
      ]);
      expect(
        evidence.references.single.localizedMeaning,
        'I will study tomorrow.',
      );
      expect(evidence.grammar?.title, 'Future plan');
      expect(evidence.grammar?.explanation, 'Use -(으)ㄹ 거예요 for a plan.');
    });

    test('never infers a why answer from grammarIds', () {
      final evidence = ScenarioWritingEvidence.fromScenario(
        scenario: _scenarioWithoutInlineGrammar,
        language: 'en',
      );

      expect(evidence.grammar, isNull);
      expect(evidence.references, isNotEmpty);
    });
  });

  group('ScenarioWritingCheckService', () {
    test(
      'validates correction and recomputes changes from trusted strings',
      () async {
        final gateway = _FakeGateway(
          availability: const KoreanProofreadingAvailability(
            status: KoreanProofreadingStatus.available,
          ),
          result: const KoreanProofreadingResult(
            status: KoreanProofreadingStatus.completed,
            originalText: '저는 내일 공부할 거에요.',
            suggestion: '저는 내일 공부할 거예요.',
            changes: <KoreanProofreadingChange>[
              KoreanProofreadingChange(
                originalText: 'untrusted',
                replacementText: 'payload',
              ),
            ],
          ),
        );
        final service = ScenarioWritingCheckService(gateway: gateway);

        final outcome = await service.check(
          input: '  저는 내일 공부할 거에요.  ',
          evidence: _evidence,
        );

        expect(outcome.kind, ScenarioWritingCheckKind.suggestion);
        expect(outcome.facts.originalText, '  저는 내일 공부할 거에요.  ');
        expect(outcome.facts.suggestion, '저는 내일 공부할 거예요.');
        expect(outcome.facts.changes, hasLength(1));
        expect(outcome.facts.changes.single.originalText, '거에요');
        expect(outcome.facts.changes.single.replacementText, '거예요');
        expect(gateway.checkCalls, 1);
        expect(gateway.proofreadCalls, 1);
        expect(gateway.lastProofreadInput, '저는 내일 공부할 거에요.');
        expect(gateway.downloadCalls, 0);
      },
    );

    test(
      'requires a separate download action and never auto-proofreads',
      () async {
        final gateway = _FakeGateway(
          availability: const KoreanProofreadingAvailability(
            status: KoreanProofreadingStatus.downloadable,
          ),
          downloadAvailability: const KoreanProofreadingAvailability(
            status: KoreanProofreadingStatus.available,
          ),
        );
        final service = ScenarioWritingCheckService(gateway: gateway);

        final first = await service.check(
          input: '저는 내일 공부할 거예요.',
          evidence: _evidence,
        );
        expect(first.kind, ScenarioWritingCheckKind.downloadRequired);
        expect(gateway.downloadCalls, 0);
        expect(gateway.proofreadCalls, 0);

        final downloaded = await service.download(
          input: '저는 내일 공부할 거예요.',
          evidence: _evidence,
        );
        expect(downloaded.kind, ScenarioWritingCheckKind.ready);
        expect(gateway.downloadCalls, 1);
        expect(gateway.proofreadCalls, 0);
      },
    );

    test('fails closed when availability status and error disagree', () async {
      final gateway = _FakeGateway(
        availability: const KoreanProofreadingAvailability(
          status: KoreanProofreadingStatus.available,
          error: KoreanProofreadingError.malformedResponse,
        ),
      );
      final service = ScenarioWritingCheckService(gateway: gateway);

      final outcome = await service.check(
        input: '저는 내일 공부할 거예요.',
        evidence: _evidence,
      );

      expect(outcome.kind, ScenarioWritingCheckKind.fallback);
      expect(outcome.error, KoreanProofreadingError.malformedResponse);
      expect(gateway.proofreadCalls, 0);
    });

    test(
      'NFD input remains exact in facts without inventing a correction',
      () async {
        final gateway = _FakeGateway(
          availability: const KoreanProofreadingAvailability(
            status: KoreanProofreadingStatus.available,
          ),
          result: const KoreanProofreadingResult(
            status: KoreanProofreadingStatus.completed,
            originalText: '가요.',
            suggestion: '가요.',
          ),
        );
        final service = ScenarioWritingCheckService(gateway: gateway);

        final outcome = await service.check(input: '가요.', evidence: _evidence);

        expect(outcome.kind, ScenarioWritingCheckKind.noChanges);
        expect(outcome.facts.originalText, '가요.');
        expect(gateway.lastProofreadInput, '가요.');
      },
    );

    test(
      'unsupported platform returns authored evidence without throwing',
      () async {
        final gateway = _FakeGateway(
          availability: const KoreanProofreadingAvailability(
            status: KoreanProofreadingStatus.unsupportedPlatform,
            error: KoreanProofreadingError.unavailable,
          ),
        );
        final service = ScenarioWritingCheckService(gateway: gateway);

        final outcome = await service.check(
          input: '저는 내일 공부할 거예요.',
          evidence: _evidence,
        );

        expect(outcome.kind, ScenarioWritingCheckKind.fallback);
        expect(outcome.facts.evidence, same(_evidence));
        expect(
          outcome.facts.evidence.references.single.korean,
          '저는 내일 공부할 거예요.',
        );
        expect(outcome.facts.evidence.grammar?.title, 'Future plan');
        expect(gateway.proofreadCalls, 0);
      },
    );

    test('rejects contaminated or mismatched generated responses', () async {
      final gateway = _FakeGateway(
        availability: const KoreanProofreadingAvailability(
          status: KoreanProofreadingStatus.available,
        ),
        result: const KoreanProofreadingResult(
          status: KoreanProofreadingStatus.completed,
          originalText: '저는 내일 공부할 거예요.',
          suggestion: '저는 내일 공부할 거예요. مرحبا',
        ),
      );
      final service = ScenarioWritingCheckService(gateway: gateway);

      final contaminated = await service.check(
        input: '저는 내일 공부할 거예요.',
        evidence: _evidence,
      );
      expect(contaminated.kind, ScenarioWritingCheckKind.fallback);
      expect(contaminated.error, KoreanProofreadingError.responseRejected);

      gateway.result = const KoreanProofreadingResult(
        status: KoreanProofreadingStatus.completed,
        originalText: '다른 원문이에요.',
        suggestion: '저는 내일 공부할 거예요.',
      );
      final mismatched = await service.check(
        input: '저는 내일 공부할 거예요.',
        evidence: _evidence,
      );
      expect(mismatched.kind, ScenarioWritingCheckKind.fallback);
      expect(mismatched.error, KoreanProofreadingError.responseRejected);
    });

    test(
      'catches gateway failures and rejects unsafe input before native calls',
      () async {
        final throwing = _FakeGateway(
          availability: const KoreanProofreadingAvailability(
            status: KoreanProofreadingStatus.available,
          ),
          throwOnProofread: true,
        );
        final service = ScenarioWritingCheckService(gateway: throwing);

        final failed = await service.check(
          input: '저는 내일 공부할 거예요.',
          evidence: _evidence,
        );
        expect(failed.kind, ScenarioWritingCheckKind.fallback);
        expect(failed.error, KoreanProofreadingError.unknown);

        final rejected = await service.check(
          input: '저는 내일 공부할 거예요. مرحبا',
          evidence: _evidence,
        );
        expect(rejected.kind, ScenarioWritingCheckKind.fallback);
        expect(rejected.error, KoreanProofreadingError.invalidInput);
        expect(throwing.checkCalls, 1);

        final tooLong = await service.check(
          input: '가' * 241,
          evidence: _evidence,
        );
        expect(tooLong.kind, ScenarioWritingCheckKind.fallback);
        expect(tooLong.error, KoreanProofreadingError.inputTooLong);
        expect(throwing.checkCalls, 1);
      },
    );
  });
}

const _scenario = Scenario(
  id: 'writing-check-test',
  level: LearnerLevel.a2,
  emoji: '✍️',
  register: Register.polite,
  title: LocalizedText(ko: '계획', de: 'Plan', en: 'Plan'),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: <VocabRef>[],
  grammarIds: <String>['future_plan'],
  grammarBlock: GrammarBlock(
    title: LocalizedText(ko: '미래 계획', de: 'Zukunftsplan', en: 'Future plan'),
    explanation: LocalizedText(
      ko: '계획에는 -(으)ㄹ 거예요를 써요.',
      de: 'Für einen Plan verwendet man -(으)ㄹ 거예요.',
      en: 'Use -(으)ㄹ 거예요 for a plan.',
    ),
  ),
  dialog: <DialogLine>[
    DialogLine(
      speaker: 'minsu',
      ko: '내일 뭐 할 거예요?',
      de: 'Was machen Sie morgen?',
      en: 'What will you do tomorrow?',
    ),
    DialogLine(
      speaker: 'user',
      ko: '저는 내일 공부할 거예요.',
      de: 'Ich werde morgen lernen.',
      en: 'I will study tomorrow.',
    ),
  ],
  quests: <QuestSpec>[],
);

const _scenarioWithoutInlineGrammar = Scenario(
  id: 'writing-check-no-inline-grammar',
  level: LearnerLevel.a2,
  emoji: '✍️',
  register: Register.polite,
  title: LocalizedText(ko: '계획', de: 'Plan', en: 'Plan'),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: <VocabRef>[],
  grammarIds: <String>['future_plan'],
  dialog: <DialogLine>[
    DialogLine(
      speaker: 'user',
      ko: '저는 내일 공부할 거예요.',
      de: 'Ich werde morgen lernen.',
      en: 'I will study tomorrow.',
    ),
  ],
  quests: <QuestSpec>[],
);

final _evidence = ScenarioWritingEvidence.fromScenario(
  scenario: _scenario,
  language: 'en',
);

final class _FakeGateway implements ScenarioProofreadingGateway {
  _FakeGateway({
    required this.availability,
    this.downloadAvailability = const KoreanProofreadingAvailability(
      status: KoreanProofreadingStatus.available,
    ),
    this.result,
    this.throwOnProofread = false,
  });

  KoreanProofreadingAvailability availability;
  KoreanProofreadingAvailability downloadAvailability;
  KoreanProofreadingResult? result;
  bool throwOnProofread;

  int checkCalls = 0;
  int downloadCalls = 0;
  int proofreadCalls = 0;
  int closeCalls = 0;
  String? lastProofreadInput;

  @override
  Future<KoreanProofreadingAvailability> check() async {
    checkCalls++;
    return availability;
  }

  @override
  Future<KoreanProofreadingAvailability> download() async {
    downloadCalls++;
    return downloadAvailability;
  }

  @override
  Future<KoreanProofreadingResult> proofread(String originalText) async {
    proofreadCalls++;
    lastProofreadInput = originalText;
    if (throwOnProofread) {
      throw StateError('proofreading failed');
    }
    return result ??
        KoreanProofreadingResult(
          status: KoreanProofreadingStatus.completed,
          originalText: originalText,
          suggestion: originalText,
        );
  }

  @override
  Future<void> close() async {
    closeCalls++;
  }
}
