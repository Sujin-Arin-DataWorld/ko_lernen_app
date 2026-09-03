import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';

void main() {
  // §COPY-1(J7)(a): every SoriCopyKey the model can carry must resolve to a
  // real ARB `soriStageCatalogCopy` select branch, not the ICU `other`
  // fallback — a key without a branch would silently render generic
  // "Reward"/"Belohnung" copy instead of the intended chip text.
  test('every SoriCopyKey resolves to a real ARB branch, not the ICU other fallback', () {
    for (final key in SoriCopyKey.values) {
      expect(
        AppL10nEn().soriStageCatalogCopy(key.name),
        isNot(AppL10nEn().soriStageCatalogCopy('__none__')),
      );
      expect(
        AppL10nDe().soriStageCatalogCopy(key.name),
        isNot(AppL10nDe().soriStageCatalogCopy('__none__')),
      );
    }
  });

  test('Learn catalog maps every approved content family exactly once', () {
    final learn = soriActivityCatalog
        .where((entry) => entry.tab == SoriStageTab.learn)
        .toList();
    expect(learn.map((entry) => entry.id).toSet(), <String>{
      'course',
      'hangul',
      'calligraphy',
      'pronunciation',
      'vocab_packs',
      'srs',
      'my_words',
      'word_web',
      'grammar',
      'listening',
      'scenarios',
      'smalltalk',
      'vocab_notebook',
    });
    expect(learn, hasLength(13));
  });

  test('Games catalog maps every built-in and custom game exactly once', () {
    final games = soriActivityCatalog
        .where((entry) => entry.tab == SoriStageTab.games)
        .toList();
    expect(games.map((entry) => entry.id).toSet(), <String>{
      'daily_game',
      'chosung',
      'syllable_cross',
      'cloze',
      'speed_match',
      'sentence_arcade',
      'kkeunmari',
      'custom_quiz',
      'custom_matching',
      'custom_typing',
    });
    expect(games, hasLength(10));
  });

  test('every entry has one stable id and complete action/reward metadata', () {
    expect(soriActivityCatalog.map((entry) => entry.id).toSet(), hasLength(23));
    for (final entry in soriActivityCatalog) {
      expect(entry.route, startsWith('/'), reason: entry.id);
      expect(entry.minutes, greaterThan(0), reason: entry.id);
      expect(entry.title.de.trim(), isNotEmpty, reason: entry.id);
      expect(entry.title.en.trim(), isNotEmpty, reason: entry.id);
      expect(entry.description.de.trim(), isNotEmpty, reason: entry.id);
      expect(entry.description.en.trim(), isNotEmpty, reason: entry.id);
      expect(entry.reward.activityId, entry.id, reason: entry.id);
      expect(entry.reward.condition.de.trim(), isNotEmpty, reason: entry.id);
      expect(entry.reward.condition.en.trim(), isNotEmpty, reason: entry.id);
      expect(entry.reward.items, isNotEmpty, reason: entry.id);
      expect(entry.iconName.trim(), isNotEmpty, reason: entry.id);
    }
  });

  test('owned routes are unique and launcher aliases never win lookup', () {
    final owners = soriActivityCatalog
        .where((entry) => entry.ownsRoute)
        .toList();
    final ownersByRoute = <String, List<String>>{};
    for (final owner in owners) {
      for (final route in <String>[owner.route, ...owner.detailRouteAliases]) {
        ownersByRoute.putIfAbsent(route, () => <String>[]).add(owner.id);
        expect(activityForRoute(route)?.id, owner.id, reason: route);
      }
    }
    expect(
      ownersByRoute.values.every((ownerIds) => ownerIds.length == 1),
      isTrue,
      reason: ownersByRoute.toString(),
    );

    final myWords = soriActivityCatalog.singleWhere(
      (entry) => entry.id == 'my_words',
    );
    expect(myWords.ownsRoute, isTrue);
    expect(myWords.route, '/my_words');
    for (final route in const <String>[
      '/wordbook/search',
      '/bookshelf',
      '/hard_words',
      '/book',
    ]) {
      expect(
        activityForRoute(route)?.id,
        'my_words',
        reason:
            'legacy/detail route $route must resolve to its canonical owner',
      );
    }

    for (final id in const <String>[
      'custom_quiz',
      'custom_matching',
      'custom_typing',
    ]) {
      final launcher = soriActivityCatalog.singleWhere(
        (entry) => entry.id == id,
      );
      expect(launcher.route, '/my_words', reason: id);
      expect(launcher.ownsRoute, isFalse, reason: id);
      expect(activityForRoute(launcher.route)?.id, 'my_words', reason: id);
    }
  });

  test('every visible activity launches a route registered by the app', () {
    final registered = _registeredRoutes();
    for (final entry in soriActivityCatalog) {
      expect(registered, contains(entry.route), reason: entry.id);
      if (entry.ownsRoute) {
        for (final alias in entry.detailRouteAliases) {
          expect(registered, contains(alias), reason: '${entry.id}: $alias');
        }
      }
    }
  });
}

Set<String> _registeredRoutes() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final switchStart = mainSource.indexOf('onGenerateRoute: (settings) {');
  final switchEnd = mainSource.indexOf('\n            default:', switchStart);
  expect(switchStart, greaterThanOrEqualTo(0));
  expect(switchEnd, greaterThan(switchStart));

  final registered = <String>{};
  final routeSwitch = mainSource.substring(switchStart, switchEnd);
  for (final match in RegExp(
    r"case\s+(?:'([^']+)'|([A-Za-z_]\w*))\s*:",
  ).allMatches(routeSwitch)) {
    final literal = match.group(1);
    final identifier = match.group(2);
    final route = literal ?? _stringConstantValues(identifier!).singleOrNull;
    expect(route, isNotNull, reason: 'unresolved route case $identifier');
    registered.add(route!);
  }
  return registered;
}

List<String> _stringConstantValues(String identifier) {
  final declaration = RegExp(
    '''const\\s+String\\s+${RegExp.escape(identifier)}\\s*=\\s*['"]([^'"]+)['"]\\s*;''',
  );
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((source) => source.path.endsWith('.dart'))
      .expand(
        (source) => declaration
            .allMatches(source.readAsStringSync())
            .map((match) => match.group(1)!),
      )
      .toList();
}
