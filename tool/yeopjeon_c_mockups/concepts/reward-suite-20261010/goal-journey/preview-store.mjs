// Local design fixture only. This key never reads or writes app/account data.
export const FIXTURE_KEY = 'hangul-sori:goal-journey-design:rewards-v2';
export class PreviewSaveError extends Error {
  constructor(message, outcome = 'failed') { super(message); this.outcome = outcome; }
}
export class PreviewStore {
  #storage;
  #raw = null;
  constructor(storage) { this.#storage = storage; }

  load() {
    this.#raw = this.#storage.getItem(FIXTURE_KEY);
    if (this.#raw === null) { return { learningSaved: false, buildingSaved: false }; }
    const record = JSON.parse(this.#raw);
    if (record?.version !== 2 || typeof record.learningSaved !== 'boolean'
      || typeof record.buildingSaved !== 'boolean' || (record.buildingSaved && !record.learningSaved)) {
      throw new Error('Invalid design fixture');
    }
    return record;
  }

  save({ learningSaved, buildingSaved }) {
    if (typeof learningSaved !== 'boolean' || typeof buildingSaved !== 'boolean') { throw new PreviewSaveError('Invalid fixture values'); }
    if (buildingSaved && !learningSaved) { throw new Error('Learning goal required'); }
    if (this.#storage.getItem(FIXTURE_KEY) !== this.#raw) { throw new PreviewSaveError('Design fixture changed in another tab', 'unknown'); }
    const next = JSON.stringify({ version: 2, learningSaved, buildingSaved });
    this.#storage.setItem(FIXTURE_KEY, next);
    try {
      if (this.#storage.getItem(FIXTURE_KEY) !== next) { throw new Error('Readback mismatch'); }
    } catch { throw new PreviewSaveError('Save could not be confirmed', 'unknown'); }
    this.#raw = next;
  }

  reset() {
    this.#storage.removeItem(FIXTURE_KEY);
    this.#raw = null;
  }
}
