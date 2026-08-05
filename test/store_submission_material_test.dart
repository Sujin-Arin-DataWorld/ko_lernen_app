import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store listings state the verified current content inventory', () {
    final englishListing = File('docs/store/listing-en.md').readAsStringSync();
    final germanListing = File('docs/store/listing-de.md').readAsStringSync();

    expect(englishListing, contains('`Hangul Sori: Learn Korean`'));
    expect(englishListing, contains('`Korean in your own hanok`'));
    expect(
      englishListing,
      contains('24 characters. It fits Apple\'s 30-character subtitle limit.'),
    );
    expect(germanListing, contains('`Hangul Sori: Koreanisch`'));
    expect(germanListing, contains('`Koreanisch im eigenen Hanok`'));
    expect(englishListing, contains('558 vocabulary entries'));
    expect(englishListing, contains('64 themed packs'));
    expect(englishListing, contains('39 real-life scenarios'));
    expect(englishListing, contains('17 special quests'));
    expect(germanListing, contains('558 Vokabeleinträge'));
    expect(germanListing, contains('64 Themenpacks'));
    expect(germanListing, contains('39 Alltagsszenarien'));
    expect(germanListing, contains('17 Spezial-Quests'));
    expect(englishListing, isNot(contains('526')));
    expect(englishListing, isNot(contains('61 themed packs')));
    expect(englishListing, isNot(contains('13+')));
    expect(germanListing, isNot(contains('526')));
    expect(germanListing, isNot(contains('61 Packs')));
    expect(germanListing, isNot(contains('13+')));
  });

  test(
    'App Store handoff fixes the release identity and external proof gates',
    () {
      final handoff = File(
        'docs/store/app-store-connect-v2.0.5.md',
      ).readAsStringSync();

      expect(handoff, contains('com.sujinarin.koLernenApp'));
      expect(handoff, contains('`2.0.5`'));
      expect(handoff, contains('`11`'));
      expect(handoff, contains('Education (recommended'));
      expect(handoff, contains('verify live hosting before submission'));
      expect(handoff, contains('`https://hangul-sori.com/support.html`'));
      expect(handoff, contains('| Support URL |'));
      expect(handoff, contains('| Support contact |'));
      expect(handoff, isNot(contains('Support URL or contact')));
      expect(handoff, contains('[data-safety.md](data-safety.md)'));
      expect(
        handoff,
        contains('[ios-external-setup.md](ios-external-setup.md)'),
      );
      expect(handoff, contains('guest'));
      expect(handoff, contains('TestFlight'));
      expect(handoff, contains('age-rating questionnaire'));
    },
  );

  test('iPad screenshot brief requires real alpha-free source captures', () {
    final shotList = File(
      'docs/store/screenshot-shotlist.md',
    ).readAsStringSync();

    expect(shotList, contains('2752 × 2064 landscape'));
    expect(shotList, contains('2064 × 2752 portrait'));
    expect(shotList, contains('interactive personal Hanok map'));
    expect(shotList, contains('real iOS simulator or device capture'));
    expect(
      shotList,
      contains(
        'Screenshots captured from non-iOS app builds, web pages, or AI mockups',
      ),
    );
    expect(shotList, isNot(contains('App screenshots, web screenshots')));
    expect(shotList, contains('1–10 PNGs per device family'));
    expect(shotList, contains('no alpha channel'));
    expect(shotList, contains('1290 × 2796'));
    expect(shotList, contains('AI mockups cannot be submitted'));
    expect(
      shotList,
      contains('docs/store/captures/app-store-ios/<locale>/<device>/'),
    );
  });

  test(
    'store readme distinguishes copy-ready material from external proof',
    () {
      final readme = File('docs/store/README.md').readAsStringSync();

      expect(readme, contains('app-store-connect-v2.0.5.md'));
      expect(readme, contains('Copy-ready source'));
      expect(readme, contains('External proof required before submission'));
      expect(readme, contains('no web or AI substitutes'));
      expect(readme, contains('[Support page](../support.html)'));
    },
  );

  test('support page offers bilingual support without legal claims', () {
    final supportPage = File('docs/support.html').readAsStringSync();

    expect(supportPage, contains('lang="en"'));
    expect(supportPage, contains('lang="de"'));
    expect(supportPage, contains('mailto:hello@hangul-sori.com'));
    expect(supportPage, contains('privacy.html'));
    expect(supportPage, contains('account-deletion.html'));
  });
}
