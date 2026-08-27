import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/heritage_journey_contract.dart';

void main() {
  group('Ildu Gotaek preview', () {
    test('is source-backed, preview-only, and has no runtime asset', () {
      final descriptor = HeritageJourneyCatalog.ilduGotaekPreview;
      final chapter = descriptor.chapters.single;

      expect(descriptor.validate().isValid, isTrue);
      expect(chapter.availability, HeritageAvailability.preview);
      expect(chapter.assetAuthority.status, HeritageAssetReviewStatus.none);
      expect(chapter.assetAuthority.runtimeAssetPath, isNull);
      expect(chapter.sources, hasLength(2));
      expect(
        chapter.sources.every(
          (source) => source.license.authority != HeritageUseAuthority.unknown,
        ),
        isTrue,
      );
    });
  });

  test('fails closed when a pending-review asset is declared approved', () {
    final chapter = _chapter(
      assetAuthority: const HeritageAssetAuthority(
        status: HeritageAssetReviewStatus.approved,
        runtimeAssetPath:
            'assets/illustrations/personal_hanok_v3/pending_review/gate.png',
        authorityVersion: 'visual-v3',
        approvedBy: 'reviewer',
        approvedAtIso: '2026-08-26',
      ),
    );

    final result = chapter.validate();
    expect(result.isValid, isFalse);
    expect(result.hasCode('heritage.pending_review_asset'), isTrue);
  });

  test('fails when source attribution is incomplete', () {
    final chapter = _chapter(
      sources: [
        HeritageSourceReference(
          institution: '',
          sourceYear: 0,
          yearBasis: HeritageSourceYearBasis.accessed,
          title: '',
          url: Uri.parse('https://example.org/source'),
          author: '',
          license: const HeritageLicenseReference(
            authority: HeritageUseAuthority.citationOnly,
            displayName: 'Citation only',
          ),
          checkedAtIso: '2026-08-26',
        ),
      ],
    );

    final result = chapter.validate();
    expect(result.isValid, isFalse);
    expect(result.hasCode('heritage.missing_attribution'), isTrue);
  });

  test('live chapter requires approved asset and learning-beat binding', () {
    final chapter = _chapter(availability: HeritageAvailability.live);

    final result = chapter.validate();
    expect(result.hasCode('heritage.live_without_approved_asset'), isTrue);
    expect(result.hasCode('heritage.live_without_approved_binding'), isTrue);
  });

  test('approved-looking live metadata cannot self-authorize', () {
    final chapter = _chapter(
      availability: HeritageAvailability.live,
      assetAuthority: _approvedAsset,
      learningBeatBinding: _approvedBinding,
    );

    final result = chapter.validate();

    expect(result.hasCode('heritage.asset_not_bundled'), isTrue);
    expect(result.hasCode('heritage.unresolved_asset_approval'), isTrue);
    expect(result.hasCode('heritage.unresolved_learning_beat_map'), isTrue);
    expect(result.hasCode('heritage.live_without_approved_binding'), isTrue);
  });

  test('live chapter resolves bundled asset and reviewed beat map', () {
    expect(File(_runtimeAssetPath).existsSync(), isTrue);
    final chapter = _chapter(
      availability: HeritageAvailability.live,
      assetAuthority: _approvedAsset,
      learningBeatBinding: _approvedBinding,
      progress: const EstateProgressSnapshot(
        completedEvidenceBeatIds: {'beat-greeting'},
        decorationInventoryIds: {},
      ),
    );

    final result = chapter.validate(
      publicationAuthority: _publicationAuthority,
    );

    expect(result.violations, isEmpty);
  });

  test('live progress cannot cite a beat absent from the approved map', () {
    final chapter = _chapter(
      availability: HeritageAvailability.live,
      assetAuthority: _approvedAsset,
      learningBeatBinding: _approvedBinding,
      progress: const EstateProgressSnapshot(
        completedEvidenceBeatIds: {'beat-not-reviewed'},
        decorationInventoryIds: {},
      ),
    );

    final result = chapter.validate(
      publicationAuthority: _publicationAuthority,
    );

    expect(result.hasCode('heritage.unresolved_progress_beat'), isTrue);
  });

  test('separately approved license requires resolvable approval evidence', () {
    final missingEvidence = _chapter(
      sources: [_source(license: _separatelyApprovedLicense())],
    ).validate(publicationAuthority: _publicationAuthority);
    final unknownEvidence = _chapter(
      sources: [
        _source(
          license: _separatelyApprovedLicense(
            approvalEvidenceId: 'license-approval-unknown-v1',
          ),
        ),
      ],
    ).validate(publicationAuthority: _publicationAuthority);
    final approved = _chapter(
      sources: [
        _source(
          license: _separatelyApprovedLicense(
            approvalEvidenceId: _licenseEvidenceId,
          ),
        ),
      ],
    ).validate(publicationAuthority: _publicationAuthority);
    final unverifiable =
        _chapter(
          sources: [
            _source(
              license: _separatelyApprovedLicense(
                approvalEvidenceId: _licenseEvidenceId,
              ),
            ),
          ],
        ).validate(
          publicationAuthority: HeritagePublicationAuthority(
            bundledRuntimeAssetPaths: const {},
            assetApprovals: const [],
            learningBeatMaps: const [],
            separatelyApprovedLicenses: [
              HeritageLicenseApprovalEvidence(
                evidenceId: _licenseEvidenceId,
                evidenceUrl: Uri.parse('http://localhost/approval'),
                approvedBy: 'rights-reviewer',
                approvedAtIso: '2026-08-26',
              ),
            ],
          ),
        );

    expect(
      missingEvidence.hasCode('heritage.missing_license_approval_evidence'),
      isTrue,
    );
    expect(
      unknownEvidence.hasCode('heritage.unresolved_license_approval_evidence'),
      isTrue,
    );
    expect(
      unverifiable.hasCode('heritage.unresolved_license_approval_evidence'),
      isTrue,
    );
    expect(approved.isValid, isTrue);
  });
}

EstateChapter _chapter({
  HeritageAvailability availability = HeritageAvailability.preview,
  List<HeritageSourceReference>? sources,
  HeritageAssetAuthority assetAuthority = const HeritageAssetAuthority.none(),
  LearningBeatBinding learningBeatBinding =
      const LearningBeatBinding.unassigned(),
  EstateProgressSnapshot progress = const EstateProgressSnapshot.empty(),
}) {
  return EstateChapter(
    estateId: 'test-estate',
    officialName: 'Test Estate',
    availability: availability,
    sources: sources ?? [_source()],
    assetAuthority: assetAuthority,
    learningBeatBinding: learningBeatBinding,
    progress: progress,
    cultureStoryLocalizationKey: 'heritageTestEstateStory',
  );
}

HeritageSourceReference _source({HeritageLicenseReference? license}) {
  return HeritageSourceReference(
    institution: 'Test Authority',
    sourceYear: 2026,
    yearBasis: HeritageSourceYearBasis.accessed,
    title: 'Test source',
    url: Uri.parse('https://example.org/source'),
    author: 'Test Authority',
    license:
        license ??
        const HeritageLicenseReference(
          authority: HeritageUseAuthority.citationOnly,
          displayName: 'Citation only',
        ),
    checkedAtIso: '2026-08-26',
  );
}

HeritageLicenseReference _separatelyApprovedLicense({
  String? approvalEvidenceId,
}) {
  return HeritageLicenseReference(
    authority: HeritageUseAuthority.separatelyApproved,
    displayName: 'Separately approved reuse',
    approvalEvidenceId: approvalEvidenceId,
  );
}

const _runtimeAssetPath =
    'assets/illustrations/personal_hanok_v2/map/site_base_light.png';
const _licenseEvidenceId = 'license-approval-test-source-v1';
const _approvedAsset = HeritageAssetAuthority(
  status: HeritageAssetReviewStatus.approved,
  runtimeAssetPath: _runtimeAssetPath,
  authorityVersion: 'asset-authority-v1',
  approvedBy: 'asset-reviewer',
  approvedAtIso: '2026-08-26',
);
const _approvedBinding = LearningBeatBinding(
  status: LearningBeatBindingStatus.approved,
  beatMapId: 'test-estate-beat-map',
  version: 'beat-map-v1',
  approvedBy: 'learning-reviewer',
  approvedAtIso: '2026-08-26',
);
final _publicationAuthority = HeritagePublicationAuthority(
  bundledRuntimeAssetPaths: {_runtimeAssetPath},
  assetApprovals: [
    HeritageAssetApprovalEvidence(
      runtimeAssetPath: _runtimeAssetPath,
      authorityVersion: 'asset-authority-v1',
      approvedBy: 'asset-reviewer',
      approvedAtIso: '2026-08-26',
    ),
  ],
  learningBeatMaps: [
    HeritageLearningBeatMapEvidence(
      beatMapId: 'test-estate-beat-map',
      version: 'beat-map-v1',
      approvedBy: 'learning-reviewer',
      approvedAtIso: '2026-08-26',
      evidenceBeatIds: {'beat-greeting'},
    ),
  ],
  separatelyApprovedLicenses: [
    HeritageLicenseApprovalEvidence(
      evidenceId: _licenseEvidenceId,
      evidenceUrl: Uri.parse('https://example.org/approvals/test-source-v1'),
      approvedBy: 'rights-reviewer',
      approvedAtIso: '2026-08-26',
    ),
  ],
);
