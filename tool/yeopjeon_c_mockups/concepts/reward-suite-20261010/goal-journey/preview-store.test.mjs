import test from 'node:test';
import assert from 'node:assert/strict';
import { PreviewStore, FIXTURE_KEY } from './preview-store.mjs';

function memoryStorage() {
  const values = new Map();
  return { values, getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
}
test('sample save survives a fresh store with the same browser data', () => {
  const storage = memoryStorage(), first = new PreviewStore(storage);
  assert.deepEqual(first.load(), { learningSaved: false, buildingSaved: false });
  first.save({ learningSaved: true, buildingSaved: true });
  assert.deepEqual(new PreviewStore(storage).load(), { version: 2, learningSaved: true, buildingSaved: true });
});
test('a failed write never reports a saved building', () => {
  const storage = memoryStorage(), store = new PreviewStore(storage);
  store.load(); storage.setItem = () => { throw new Error('Quota exceeded'); };
  assert.throws(() => store.save({ learningSaved: true, buildingSaved: true }), /Quota/);
  assert.equal(storage.getItem(FIXTURE_KEY), null);
});
test('a failed readback after a write has an unknown outcome', () => {
  const storage = memoryStorage(), store = new PreviewStore(storage);
  store.load();
  const read = storage.getItem;
  storage.setItem = (key, value) => { storage.values.set(key, value); storage.getItem = () => { throw new Error('Read denied'); }; };
  assert.throws(() => store.save({ learningSaved: true, buildingSaved: true }), error => error.outcome === 'unknown');
  storage.getItem = read;
  assert.equal(store.load().buildingSaved, true);
});
test('a different tab cannot be silently overwritten', () => {
  const storage = memoryStorage(), first = new PreviewStore(storage), second = new PreviewStore(storage);
  first.load(); second.load(); first.save({ learningSaved: true, buildingSaved: false });
  assert.throws(() => second.save({ learningSaved: true, buildingSaved: true }), error => error.outcome === 'unknown');
  assert.equal(new PreviewStore(storage).load().buildingSaved, false);
});
test('reset removes only the design fixture key', () => {
  const storage = memoryStorage(), store = new PreviewStore(storage);
  storage.setItem('other-design', 'keep'); store.load(); store.save({ learningSaved: true, buildingSaved: true }); store.reset();
  assert.equal(storage.getItem(FIXTURE_KEY), null); assert.equal(storage.getItem('other-design'), 'keep');
});
test('corrupt and impossible records are rejected', () => {
  for (const record of ['null', '{', JSON.stringify({ version: 2, learningSaved: false, buildingSaved: true }), JSON.stringify({ version: 1, learningSaved: true, buildingSaved: true })]) {
    const storage = memoryStorage(); storage.setItem(FIXTURE_KEY, record);
    assert.throws(() => new PreviewStore(storage).load());
  }
});
test('a construction write requires a completed goal and boolean values', () => {
  const storage = memoryStorage(), store = new PreviewStore(storage); store.load();
  assert.throws(() => store.save({ learningSaved: false, buildingSaved: true }), /required/);
  assert.throws(() => store.save({ learningSaved: 'true', buildingSaved: true }), /Invalid/);
  assert.equal(storage.getItem(FIXTURE_KEY), null);
});

