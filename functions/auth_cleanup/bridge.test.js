const test = require("node:test");
const assert = require("node:assert/strict");

const { createAuthUserDeletionBridge } = require("./bridge");

/** recursiveDelete 호출과 접근한 컬렉션을 기록하는 최소 Firestore 대역. */
function fakeFirestore({ failWith = null } = {}) {
  const touchedCollections = [];
  const deleted = [];
  return {
    touchedCollections,
    deleted,
    collection(name) {
      touchedCollections.push(name);
      return {
        doc: (id) => ({ __path: `${name}/${id}` }),
      };
    },
    async recursiveDelete(ref) {
      if (failWith) {
        throw failWith;
      }
      deleted.push(ref.__path);
    },
  };
}

test("out-of-band Auth 삭제: users/{uid} 트리를 지워 Firestore 트리거를 깨운다", async () => {
  const db = fakeFirestore();
  const bridge = createAuthUserDeletionBridge({ firestore: db });

  const result = await bridge({ uid: "abc123" });

  assert.deepEqual(db.deleted, ["users/abc123"]);
  assert.equal(result.status, "bridged");
});

test("계 정리를 직접 하지 않는다 — gye 컬렉션을 건드리면 안 된다", async () => {
  const db = fakeFirestore();
  const bridge = createAuthUserDeletionBridge({ firestore: db });

  await bridge({ uid: "abc123" });

  // 승계·memberCount·members·bans 는 functions/gye 의 on_user_deleted 소유다.
  // 여기서 gye 를 열면 2026-08-12 회귀(차단자 승계·이중 감산·익명화 누락)가
  // 되살아난다.
  assert.deepEqual(db.touchedCollections, ["users"]);
  assert.ok(!db.touchedCollections.includes("gye"));
});

test("정상 삭제 플로우가 먼저 지웠어도 멱등하다", async () => {
  const db = fakeFirestore();
  const bridge = createAuthUserDeletionBridge({ firestore: db });

  // account_deletion_worker 가 이미 users/{uid} 를 지운 뒤 Auth 삭제가 오는
  // 순서. 브리지는 같은 대상에 반복 실행해도 안전해야 한다 — 이미 정리된
  // 트리를 다시 훑는 것뿐이라 부작용이 없다.
  await bridge({ uid: "abc123" });
  await bridge({ uid: "abc123" });

  assert.deepEqual(db.deleted, ["users/abc123", "users/abc123"]);
});

test("recursiveDelete 실패를 삼키지 않는다", async () => {
  const boom = new Error("firestore unavailable");
  const db = fakeFirestore({ failWith: boom });
  const bridge = createAuthUserDeletionBridge({ firestore: db });

  // 삼키면 계 정리가 누락된 채 실행이 '성공'으로 기록된다.
  await assert.rejects(() => bridge({ uid: "abc123" }), /firestore unavailable/);
});

test("uid 가 없으면 거부한다", async () => {
  const db = fakeFirestore();
  const bridge = createAuthUserDeletionBridge({ firestore: db });

  await assert.rejects(() => bridge({}), TypeError);
  await assert.rejects(() => bridge({ uid: "" }), TypeError);
  assert.deepEqual(db.deleted, []);
});

test("Firestore 의존성이 없으면 생성 자체가 실패한다", () => {
  assert.throws(() => createAuthUserDeletionBridge(), TypeError);
  assert.throws(
    () => createAuthUserDeletionBridge({ firestore: {} }),
    TypeError,
  );
});
