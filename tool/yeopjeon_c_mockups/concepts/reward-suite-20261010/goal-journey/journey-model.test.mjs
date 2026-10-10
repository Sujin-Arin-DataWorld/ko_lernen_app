// Fixture accounting guards; these tests do not certify production persistence.
import test from 'node:test';
import assert from 'node:assert/strict';
import { JourneyModel } from './journey-model.mjs';

function ready() {
  const model = new JourneyModel();
  assert.equal(model.startLearning(), true);
  assert.equal(model.beginLearningSave(), true);
  assert.equal(model.confirmLearningSave(), true);
  assert.equal(model.go('W04'), true);
  return model;
}

function savingBuild() {
  const model = ready();
  assert.equal(model.openBuild(), true);
  assert.equal(model.beginBuild(), true);
  return model;
}

test('initial money is previously earned; summary and help do not mint', () => {
  const model = new JourneyModel();
  assert.equal(model.scene, 'W03');
  assert.deepEqual(model.wallet, { balance: 30, earned: 30, spent: 0, eligible: 0, owned: 0 });
  for (const scene of ['W01', 'I01', 'I02', 'I03', 'W03']) {
    assert.equal(model.go(scene), true);
    assert.equal(model.wallet.balance, 30);
  }
  assert.equal(model.currentGoal.id, 'a1_01_greetings_hangul');
  assert.equal(model.openBuild(), false);
});

test('learning saving leaves accounting unchanged; confirmed distinct claim earns once', () => {
  const model = new JourneyModel();
  assert.equal(model.confirmLearningSave(), false);
  assert.equal(model.beginLearningSave(), false);
  model.startLearning();
  model.beginLearningSave();
  assert.equal(model.scene, 'R07');
  assert.equal(model.pending, 'learning');
  assert.equal(model.wallet.balance, 30);
  assert.equal(model.wallet.eligible, 0);
  assert.equal(model.receipt, null);
  assert.equal(model.beginLearningSave(), false);
  assert.equal(model.startLearning(), false);
  assert.equal(model.confirmLearningSave(), true);
  assert.equal(model.scene, 'R03');
  assert.deepEqual(model.wallet, { balance: 70, earned: 70, spent: 0, eligible: 1, owned: 0 });
  assert.deepEqual({ before: model.receipt.before, after: model.receipt.after, amount: model.receipt.amount },
    { before: 30, after: 70, amount: 40 });
  assert.equal(model.confirmLearningSave(), false);
  model.go('W04');
  model.go('R03');
  assert.equal(model.wallet.balance, 70);
});

test('success scenes and construction targets cannot be fabricated by navigation', () => {
  const model = new JourneyModel();
  for (const scene of ['W04', 'B01', 'B02', 'B03', 'B04', 'B05', 'R03', 'R07', 'W05', 'bogus', '__proto__']) {
    assert.equal(model.go(scene), false, scene);
  }
  assert.equal(model.wallet.balance, 30);
  assert.equal(model.scene, 'W03');
});

test('construction confirmation freezes target and predicted debit; cancellation is free', () => {
  const model = ready();
  assert.equal(model.openBuild(), true);
  const intent = model.intent;
  assert.equal(intent.targetStage, 1);
  assert.equal(intent.ownedBefore, 0);
  assert.equal(intent.before, 70);
  assert.equal(intent.cost, 40);
  assert.equal(intent.predictedAfter, 30);
  assert.equal(model.wallet.balance, 70);
  assert.equal(model.wallet.owned, 0);
  assert.equal(model.cancelBuild(), true);
  assert.equal(model.scene, 'W04');
  assert.equal(model.intent, null);
  assert.equal(model.wallet.balance, 70);
  assert.equal(model.confirmBuildSave(), false);
});

test('saving never debits optimistically and rejects duplicate presses and cancellation', () => {
  const model = savingBuild();
  const wallet = model.wallet;
  assert.equal(model.scene, 'B02');
  assert.equal(model.pending, 'build');
  assert.equal(model.beginBuild(), false);
  assert.equal(model.openBuild(), false);
  assert.equal(model.cancelBuild(), false);
  assert.equal(model.go('W04'), false);
  assert.equal(model.go('B03'), false);
  assert.equal(model.wallet, wallet);
  assert.equal(model.confirmBuildSave(), true);
  assert.deepEqual(model.wallet, { balance: 30, earned: 70, spent: 40, eligible: 1, owned: 1 });
});

test('confirmed construction cannot repeat or silently buy the following target', () => {
  const model = savingBuild();
  model.confirmBuildSave();
  assert.equal(model.confirmBuildSave(), false);
  assert.equal(model.checkOriginalTarget('saved'), false);
  assert.equal(model.openBuild(), false);
  assert.equal(model.beginBuild(), false);
  assert.equal(model.go('R03'), false); // Old +40 receipt must not restore spent money visually.
  assert.equal(model.wallet.balance, 30);
  assert.equal(model.wallet.spent, 40);
  assert.equal(model.wallet.owned, 1);
});

test('known failure keeps balances and allows an explicit same-stage retry', () => {
  const model = savingBuild();
  const original = model.intent;
  assert.equal(model.failBuild(), true);
  assert.equal(model.scene, 'B04');
  assert.equal(model.wallet.balance, 70);
  assert.equal(model.wallet.owned, 0);
  assert.equal(model.confirmBuildSave(), false);
  assert.equal(model.openBuild(), true);
  assert.deepEqual(model.intent, original);
  assert.equal(model.beginBuild(), true);
  assert.equal(model.confirmBuildSave(), true);
  assert.equal(model.wallet.spent, 40);
});

test('unknown readback preserves intent, money, and unresolved state', () => {
  const model = savingBuild();
  const intent = model.intent;
  const wallet = model.wallet;
  assert.equal(model.unknownBuild(), true);
  assert.equal(model.scene, 'B05');
  assert.equal(model.pending, null);
  assert.equal(model.checkOriginalTarget(), false);
  assert.equal(model.checkOriginalTarget('invalid'), false);
  assert.equal(model.openBuild(), false);
  assert.equal(model.beginBuild(), false);
  assert.equal(model.cancelBuild(), false);
  assert.equal(model.confirmBuildSave(), false);
  assert.equal(model.go('B03'), false);
  assert.equal(model.wallet, wallet);
  assert.equal(model.intent, intent);
});

test('saved readback settles original target exactly once without another write', () => {
  const model = savingBuild();
  const intent = model.intent;
  model.unknownBuild();
  assert.equal(model.checkOriginalTarget('saved'), true);
  assert.equal(model.scene, 'B03');
  assert.equal(model.intent, intent);
  assert.equal(model.wallet.owned, intent.targetStage);
  assert.equal(model.wallet.balance, 30);
  assert.equal(model.checkOriginalTarget('saved'), false);
  assert.equal(model.confirmBuildSave(), false);
  assert.equal(model.wallet.spent, 40);
});

test('not-saved readback exposes retry confirmation for the same frozen intent', () => {
  const model = savingBuild();
  const intent = model.intent;
  model.unknownBuild();
  assert.equal(model.checkOriginalTarget('not-saved'), true);
  assert.equal(model.scene, 'B01');
  assert.equal(model.intent, intent);
  assert.equal(model.wallet.balance, 70);
  assert.equal(model.beginBuild(), true);
  assert.equal(model.confirmBuildSave(), true);
  assert.equal(model.wallet.owned, 1);
});

test('next goal is actual course two; bounded fixture does not mint another milestone', () => {
  const model = savingBuild();
  assert.equal(model.nextGoal(), false);
  model.confirmBuildSave();
  assert.equal(model.nextGoal(), true);
  assert.equal(model.scene, 'W05');
  assert.equal(model.currentGoal.id, 'a1_02_self_intro_identity');
  assert.equal(model.startLearning(), true);
  assert.equal(model.scene, 'LEARN');
  assert.equal(model.beginLearningSave(), false);
  assert.equal(model.confirmLearningSave(), false);
  assert.equal(model.wallet.balance, 30);
});

test('immutable accounting and intents cannot be changed by animation consumers', () => {
  const model = ready();
  model.openBuild();
  assert.throws(() => { model.wallet.balance = 999; }, TypeError);
  assert.throws(() => { model.intent.targetStage = 2; }, TypeError);
  assert.throws(() => { model.receipt.amount = 999; }, TypeError);
  assert.throws(() => { model.scene = 'B03'; }, TypeError);
  assert.equal(model.wallet.balance, 70);
  assert.equal(model.intent.targetStage, 1);
});

test('account change removes old snapshots and rejects every late save callback', () => {
  for (const prepare of [
    () => { const m = new JourneyModel(); m.startLearning(); m.beginLearningSave(); return m; },
    savingBuild,
    () => { const m = savingBuild(); m.unknownBuild(); return m; },
  ]) {
    const model = prepare();
    assert.equal(model.changeAccount(), true);
    assert.equal(model.scene, 'W08');
    assert.equal(model.isStale, true);
    assert.equal(model.wallet, null);
    assert.equal(model.receipt, null);
    assert.equal(model.intent, null);
    assert.equal(model.pending, null);
    assert.equal(model.currentGoal, null);
    for (const action of [
      () => model.confirmLearningSave(), () => model.confirmBuildSave(),
      () => model.checkOriginalTarget('saved'), () => model.checkOriginalTarget('not-saved'),
      () => model.startLearning(), () => model.beginLearningSave(), () => model.openBuild(),
      () => model.cancelBuild(), () => model.beginBuild(), () => model.failBuild(),
      () => model.unknownBuild(), () => model.nextGoal(), () => model.go('W04'),
    ]) { assert.equal(action(), false); }
    assert.equal(model.wallet, null);
    assert.equal(model.scene, 'W08');
  }
});

test('a saved stage 7 fixture advances only its original stage 8 target', () => {
  const model = new JourneyModel({ owned: 7, buildingId: 'fixture-sarangchae-v3-16' });
  assert.equal(model.wallet.owned, 7); assert.equal(model.openBuild(), false);
  model.startLearning(); model.beginLearningSave(); model.confirmLearningSave();
  assert.equal(model.wallet.eligible, 8); assert.equal(model.wallet.balance, 70);
  model.go('W04'); model.openBuild(); assert.equal(model.intent.targetStage, 8);
  model.beginBuild(); model.confirmBuildSave();
  assert.equal(model.wallet.owned, 8); assert.equal(model.wallet.balance, 30);
  assert.equal(model.confirmBuildSave(), false); assert.equal(model.openBuild(), false);
  assert.equal(model.nextGoal(), true);
});
test('invalid construction baselines cannot create a target', () => {
  for (const owned of [-1, 16, 7.5, '7']) { assert.throws(() => new JourneyModel({ owned })); }
});
