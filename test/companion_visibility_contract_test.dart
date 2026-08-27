import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    MascotPreference.load();
  });

  test('hiding a companion preserves the selected identity', () async {
    await MascotPreference.set(MascotKind.magpie);
    await MascotPreference.setVisible(false);

    expect(MascotPreference.selectedKind, isNull);
    expect(MascotPreference.chosenKind, MascotKind.magpie);
    expect(Storage.selectedCompanion, 'magpie');
    expect(Storage.companionVisible, isFalse);

    MascotPreference.load();
    expect(MascotPreference.selectedKind, isNull);
    expect(MascotPreference.chosenKind, MascotKind.magpie);

    await MascotPreference.setVisible(true);
    expect(MascotPreference.selectedKind, MascotKind.magpie);
    expect(Storage.preferredMascot, 'magpie');
  });

  test(
    'legacy none migrates to a hidden fallback without losing visibility',
    () async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_preferred_mascot': 'none'});
      await Storage.init();
      MascotPreference.load();

      expect(MascotPreference.selectedKind, isNull);
      expect(MascotPreference.chosenKind, MascotKind.tiger);
      expect(Storage.companionVisible, isFalse);
    },
  );

  test('selected companion rejects none as an identity', () async {
    expect(
      () => Storage.setSelectedCompanion('none'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
