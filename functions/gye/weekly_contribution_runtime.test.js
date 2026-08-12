"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  findEligiblePromiseCheckpoint,
  shouldCreditPromiseContribution,
  weeklyContributionReceiptId,
  weeklyContributionWeekKey,
  weeklyPromiseFor,
} = require("./weekly_contribution_runtime");

const cafeOrderMissionContentLinkId = "link:e6a9f1197b48c79f58655c9a";

function checkpoint(overrides = {}) {
  return {
    id: "checkpoint-1",
    scenarioId: "bunshik_tteokbokki",
    courseUnitId: "a1_04_order_request_object",
    missionContentLinkId: cafeOrderMissionContentLinkId,
    score: 0.7,
    occurredAt: "2026-08-10T10:00:00.000Z",
    courseEligible: true,
    ...overrides,
  };
}

function meta(overrides = {}) {
  return {
    weeklyPromiseSchemaVersion: 1,
    weeklyPromiseId: "cafe_order",
    weeklyPromiseTarget: 3,
    weeklyPromiseWeekKey: "2026-08-10",
    ...overrides,
  };
}

test("weekly promise ids are an explicit, stable allow-list", () => {
  assert.equal(weeklyPromiseFor("cafe_order").scenarioId, "bunshik_tteokbokki");
  assert.equal(
    weeklyPromiseFor("cafe_order").missionContentLinkId,
    cafeOrderMissionContentLinkId,
  );
  assert.equal(
    weeklyPromiseFor("directions").missionContentLinkId,
    "link:49a189a1b8b9e4fa022a4557",
  );
  assert.equal(
    weeklyPromiseFor("self_introduction").missionContentLinkId,
    "link:94c139e887716700674589b2",
  );
  assert.equal(weeklyPromiseFor("invent_a_scene"), null);
});

test("only an exact, active, 70-percent course checkpoint is eligible", () => {
  const raw = JSON.stringify({
    scenarioCheckpoints: [
      checkpoint({ score: 0.69 }),
      checkpoint({ courseEligible: false, occurredAt: "2026-08-10T11:00:00.000Z" }),
      checkpoint({ scenarioId: "taxi_kakao", occurredAt: "2026-08-10T12:00:00.000Z" }),
      checkpoint({
        missionContentLinkId: "link:wrong-but-nonempty",
        occurredAt: "2026-08-10T12:30:00.000Z",
      }),
      checkpoint({ id: "checkpoint-2", occurredAt: "2026-08-10T13:00:00.000Z" }),
    ],
  });

  assert.deepEqual(findEligiblePromiseCheckpoint({
    promiseId: "cafe_order",
    courseMasteryJson: raw,
  }), checkpoint({ id: "checkpoint-2", occurredAt: "2026-08-10T13:00:00.000Z" }));
});

test("malformed, browse-only, or foreign course evidence does not light a lantern", () => {
  assert.equal(findEligiblePromiseCheckpoint({
    promiseId: "cafe_order",
    courseMasteryJson: "not-json",
  }), null);
  assert.equal(findEligiblePromiseCheckpoint({
    promiseId: "cafe_order",
    courseMasteryJson: JSON.stringify({
      scenarioCheckpoints: [checkpoint({ missionContentLinkId: null })],
    }),
  }), null);
  assert.equal(findEligiblePromiseCheckpoint({
    promiseId: "cafe_order",
    courseMasteryJson: JSON.stringify({
      scenarioCheckpoints: [checkpoint({ missionContentLinkId: "" })],
    }),
  }), null);
  assert.equal(findEligiblePromiseCheckpoint({
    promiseId: "cafe_order",
    courseMasteryJson: JSON.stringify({
      scenarioCheckpoints: [checkpoint({
        missionContentLinkId: "link:wrong-but-nonempty",
      })],
    }),
  }), null);
  assert.equal(findEligiblePromiseCheckpoint({
    promiseId: "cafe_order",
    courseMasteryJson: JSON.stringify({
      scenarioCheckpoints: [checkpoint({ courseUnitId: "other" })],
    }),
  }), null);
});

test("a contribution is bound to its week and anonymous deterministic receipt", () => {
  const weekKey = weeklyContributionWeekKey("2026-08-10T10:00:00.000Z");
  assert.equal(weekKey, "2026-08-10");
  const first = weeklyContributionReceiptId({
    gyeId: "ABC234",
    uid: "learner-a",
    promiseId: "cafe_order",
    weekKey,
  });
  const second = weeklyContributionReceiptId({
    gyeId: "ABC234",
    uid: "learner-a",
    promiseId: "cafe_order",
    weekKey,
  });
  assert.equal(first, second);
  assert.equal(first.includes("learner-a"), false);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta(), checkpoint: checkpoint(), weekKey,
  }), true);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta(), checkpoint: checkpoint(), weekKey, receiptExists: true,
  }), false);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta(),
    checkpoint: checkpoint({ missionContentLinkId: null }),
    weekKey,
  }), false);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta(),
    checkpoint: checkpoint({ missionContentLinkId: "" }),
    weekKey,
  }), false);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta(),
    checkpoint: checkpoint({ missionContentLinkId: "link:wrong-but-nonempty" }),
    weekKey,
  }), false);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta({ weeklyPromiseWeekKey: "2026-08-03" }),
    checkpoint: checkpoint(), weekKey,
  }), false);
  assert.equal(shouldCreditPromiseContribution({
    meta: meta({ weeklyPromiseSchemaVersion: 0 }),
    checkpoint: checkpoint(), weekKey,
  }), false);
});
