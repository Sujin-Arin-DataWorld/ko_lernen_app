// Design-review fixture only: no production assessment, network, or storage.
// "Saved" below is an explicit simulated confirmation, never persistence proof.
const COST = 40;
const BUILDING_ID = 'fixture-ildu-building';
const CLAIM_ID = 'fixture:milestone:a1_01_greetings_hangul';
const GOALS = Object.freeze([
  Object.freeze({
    id: 'a1_01_greetings_hangul',
    de: 'Erste Begrüßung und Nachfragen',
    en: 'First greetings and asking again',
  }),
  Object.freeze({
    id: 'a1_02_self_intro_identity',
    de: 'Name und Herkunft nennen',
    en: 'Saying your name and where you are from',
  }),
]);

/**
 * Connected preview state. Methods return false for rejected/duplicate actions.
 * Snapshots are immutable; only confirmation methods change fixture accounting.
 * This bounded journey contains one new milestone and one construction target.
 */
export class JourneyModel {
  #wallet = Object.freeze({ balance: 30, earned: 30, spent: 0, eligible: 0, owned: 0 });
  #scene = 'W03';
  #receipt = null;
  #intent = null;
  #pending = null;
  #stale = false;
  #learningStarted = false;
  #claimConfirmed = false;
  #buildStatus = null;
  #committedTarget = null;
  #goalIndex = 0;
  #initialOwned = 0;
  #buildingId = BUILDING_ID;

  constructor({ owned = 0, buildingId = BUILDING_ID } = {}) {
    if (!Number.isInteger(owned) || owned < 0 || owned > 15 || typeof buildingId !== 'string' || !buildingId) {
      throw new Error('Invalid construction fixture');
    }
    this.#initialOwned = owned;
    this.#buildingId = buildingId;
    this.#wallet = Object.freeze({ balance: 30, earned: 30, spent: 0, eligible: owned, owned });
  }

  get wallet() { return this.#wallet; }
  get scene() { return this.#scene; }
  get receipt() { return this.#receipt; }
  get intent() { return this.#intent; }
  get pending() { return this.#pending; }
  get isStale() { return this.#stale; }
  get currentGoal() { return this.#stale ? null : GOALS[this.#goalIndex]; }

  // View navigation never creates claims or spends money. Transaction scenes
  // cannot be entered merely by changing a URL or clicking a review tab.
  go(scene) {
    if (this.#stale || this.#pending || this.#buildStatus === 'unknown') { return false; }
    if (scene === 'B01') { return this.openBuild(); }
    if (scene === 'W05') { return this.nextGoal(); }
    const allowed = {
      W03: !this.#claimConfirmed,
      W04: this.#wallet.eligible > this.#wallet.owned && this.#wallet.balance >= COST,
      R03: this.#receipt !== null && this.#receipt.after === this.#wallet.balance,
      B03: this.#buildStatus === 'saved',
      B04: this.#buildStatus === 'failed',
      LEARN: this.#learningStarted,
      W01: true,
      I01: true,
      I02: true,
      I03: true,
    };
    if (allowed[scene] !== true) { return false; }
    this.#scene = scene;
    return true;
  }

  startLearning() {
    if (this.#stale || this.#pending || this.#buildStatus === 'unknown') { return false; }
    this.#goalIndex = this.#claimConfirmed ? 1 : 0;
    this.#learningStarted = true;
    this.#scene = 'LEARN';
    return true;
  }

  beginLearningSave() {
    if (this.#stale || this.#pending || this.#scene !== 'LEARN'
      || !this.#learningStarted || this.#claimConfirmed || this.#goalIndex !== 0) { return false; }
    this.#pending = 'learning';
    this.#scene = 'R07';
    return true;
  }

  confirmLearningSave() {
    if (this.#stale || this.#pending !== 'learning' || this.#claimConfirmed) { return false; }
    const before = this.#wallet.balance;
    this.#wallet = Object.freeze({
      ...this.#wallet,
      balance: before + COST,
      earned: this.#wallet.earned + COST,
      eligible: this.#initialOwned + 1,
    });
    this.#claimConfirmed = true;
    this.#pending = null;
    this.#learningStarted = false;
    this.#receipt = Object.freeze({ before, after: this.#wallet.balance, amount: COST, claimId: CLAIM_ID });
    this.#scene = 'R03';
    return true;
  }

  openBuild() {
    if (this.#stale || this.#pending || this.#buildStatus === 'unknown'
      || this.#wallet.owned >= this.#wallet.eligible || this.#wallet.balance < COST) { return false; }
    this.#intent = Object.freeze({
      buildingId: this.#buildingId,
      targetStage: this.#wallet.owned + 1,
      ownedBefore: this.#wallet.owned,
      before: this.#wallet.balance,
      cost: COST,
      predictedAfter: this.#wallet.balance - COST,
    });
    this.#buildStatus = 'prepared';
    this.#scene = 'B01';
    return true;
  }

  cancelBuild() {
    if (this.#stale || this.#pending || !this.#intent
      || !['prepared', 'failed'].includes(this.#buildStatus)) { return false; }
    this.#intent = null;
    this.#buildStatus = null;
    this.#scene = 'W04';
    return true;
  }

  beginBuild() {
    if (this.#stale || this.#pending || this.#scene !== 'B01'
      || this.#buildStatus !== 'prepared' || !this.#matchesOriginalTarget()) { return false; }
    this.#pending = 'build';
    this.#buildStatus = 'pending';
    this.#scene = 'B02';
    return true;
  }

  confirmBuildSave() {
    if (this.#stale || this.#pending !== 'build' || this.#buildStatus !== 'pending') { return false; }
    return this.#commitOriginalTarget();
  }

  failBuild() {
    if (this.#stale || this.#pending !== 'build' || this.#buildStatus !== 'pending') { return false; }
    this.#pending = null;
    this.#buildStatus = 'failed';
    this.#scene = 'B04';
    return true;
  }

  unknownBuild() {
    if (this.#stale || this.#pending !== 'build' || this.#buildStatus !== 'pending') { return false; }
    this.#pending = null;
    this.#buildStatus = 'unknown';
    this.#scene = 'B05';
    return true;
  }

  // Simulated strict readback of the frozen original target, never buildNext().
  checkOriginalTarget(outcome = 'unknown') {
    if (this.#stale || !this.#intent || this.#buildStatus !== 'unknown') { return false; }
    if (outcome === 'saved') { return this.#commitOriginalTarget(); }
    if (outcome === 'not-saved') {
      if (!this.#matchesOriginalTarget()) { return false; }
      this.#buildStatus = 'prepared';
      this.#scene = 'B01';
      return true;
    }
    // Still unknown (including invalid input): preserve the original intent.
    return false;
  }

  nextGoal() {
    if (this.#stale || this.#pending || this.#buildStatus !== 'saved'
      || this.#wallet.owned !== this.#initialOwned + 1) { return false; }
    this.#goalIndex = 1;
    this.#scene = 'W05';
    return true;
  }

  changeAccount() {
    if (this.#stale) { return false; }
    this.#stale = true;
    // Unknown replacement account is null, not a made-up zero balance.
    this.#wallet = null;
    this.#receipt = null;
    this.#intent = null;
    this.#pending = null;
    this.#learningStarted = false;
    this.#buildStatus = null;
    this.#scene = 'W08';
    return true;
  }

  #matchesOriginalTarget() {
    return this.#intent !== null
      && this.#intent.buildingId === this.#buildingId
      && this.#intent.targetStage === this.#wallet.owned + 1
      && this.#intent.ownedBefore === this.#wallet.owned
      && this.#intent.before === this.#wallet.balance
      && this.#wallet.eligible >= this.#intent.targetStage
      && this.#wallet.balance >= this.#intent.cost;
  }

  #commitOriginalTarget() {
    if (!this.#matchesOriginalTarget() || this.#committedTarget === this.#intent.targetStage) { return false; }
    this.#wallet = Object.freeze({
      ...this.#wallet,
      balance: this.#wallet.balance - this.#intent.cost,
      spent: this.#wallet.spent + this.#intent.cost,
      owned: this.#intent.targetStage,
    });
    this.#committedTarget = this.#intent.targetStage;
    this.#pending = null;
    this.#buildStatus = 'saved';
    this.#scene = 'B03';
    return true;
  }
}
