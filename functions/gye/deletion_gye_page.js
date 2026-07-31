"use strict";

const DELETE_COLLECTIONS = Object.freeze([
  "members",
  "departures",
  "bans",
  "feed",
  "reports",
  "stickers",
  "processed_packs",
  "notification_outbox",
]);
const CONTENT_STAGES = Object.freeze(["feed", "reports", "stickers"]);
const MAX_GYE_PAGE_SIZE = 100;

function pageFailure(code) {
  const error = new Error("Gye deletion page rejected unsafe state.");
  error.code = code;
  return error;
}

function boundedPageSize(value) {
  if (!Number.isInteger(value) || value < 1) {
    throw new TypeError("A positive Gye cleanup page size is required.");
  }
  return Math.min(value, MAX_GYE_PAGE_SIZE);
}

function initialState(targetData) {
  const stored = targetData?.workState;
  if (stored && typeof stored.stage === "string" &&
      Number.isInteger(stored.version) && stored.version >= 1) {
    return stored;
  }
  return { stage: "meta", version: 0, cursor: null };
}

function millis(value) {
  if (Number.isFinite(value)) return value;
  if (value && typeof value.toMillis === "function") {
    return value.toMillis();
  }
  return Number.MAX_SAFE_INTEGER;
}

function earlierSuccessor(left, right) {
  if (!left) return right;
  if (!right) return left;
  return left.joinedAtMillis < right.joinedAtMillis ||
      (left.joinedAtMillis === right.joinedAtMillis &&
        left.uid.localeCompare(right.uid) < 0)
    ? left
    : right;
}

function createGyeDeletionPageCleaner({
  firestore,
  fieldValue,
  documentIdFieldPath,
  anonymizeMeta,
  anonymizeFeed,
  anonymizeReport,
  anonymizeSticker,
  shouldDeleteReportForUid,
} = {}) {
  if (!firestore || typeof firestore.collection !== "function" ||
      !fieldValue || typeof fieldValue.arrayRemove !== "function" ||
      documentIdFieldPath === undefined ||
      typeof anonymizeMeta !== "function" ||
      typeof anonymizeFeed !== "function" ||
      typeof anonymizeReport !== "function" ||
      typeof anonymizeSticker !== "function" ||
      typeof shouldDeleteReportForUid !== "function") {
    throw new TypeError("Complete Gye deletion page dependencies are required.");
  }

  function queryPage(collection, state, limit) {
    let query = collection
      .orderBy(documentIdFieldPath)
      .limit(limit);
    if (typeof state.cursor === "string" && state.cursor.length > 0) {
      query = query.startAfter(state.cursor);
    }
    return query.get();
  }

  function nextState(state, change) {
    return {
      ...state,
      ...change,
      version: state.version + 1,
    };
  }

  async function currentTarget(transaction, targetRef, expected) {
    const target = await transaction.get(targetRef);
    if (!target.exists) return null;
    const state = initialState(target.data() || {});
    if (state.version !== expected.version ||
        state.stage !== expected.stage ||
        (state.cursor || null) !== (expected.cursor || null)) {
      throw pageFailure("cleanup-progress-changed");
    }
    return target;
  }

  function writeState(transaction, targetRef, state, change) {
    const updated = nextState(state, change);
    transaction.set(targetRef, { workState: updated }, { merge: true });
    return { done: updated.stage === "done", state: updated };
  }

  function contentFields(name, transformed) {
    if (name === "reports") {
      return {
        reporterUid: transformed.reporterUid,
        targetUid: transformed.targetUid,
        note: transformed.note,
      };
    }
    if (name === "stickers") {
      return {
        senderUid: transformed.senderUid,
        senderNickname: transformed.senderNickname,
      };
    }
    return {
      actorUid: transformed.actorUid,
      actorNickname: transformed.actorNickname,
      payload: transformed.payload,
    };
  }

  function transformFor(name, source, uid, nickname) {
    if (name === "reports") return anonymizeReport(source, uid);
    if (name === "stickers") {
      return anonymizeSticker(source, uid, nickname);
    }
    return anonymizeFeed(source, uid, nickname);
  }

  async function cleanupPage({
    targetRef,
    targetData,
    gref,
    gyeId,
    uid,
    nickname = "",
    pageSize,
    runFencedTransaction,
  } = {}) {
    if (!targetRef || typeof targetRef.collection !== "function" ||
        !gref || typeof gref.collection !== "function" ||
        typeof gyeId !== "string" || gyeId.length === 0 ||
        typeof uid !== "string" || uid.length === 0 ||
        typeof runFencedTransaction !== "function") {
      throw new TypeError("Complete Gye deletion page context is required.");
    }
    const limit = boundedPageSize(pageSize);
    const state = initialState(targetData);
    const memberTargets = targetRef.collection("member_targets");

    if (state.stage === "done") return { done: true, state };

    if (state.stage === "meta") {
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const meta = await transaction.get(gref);
        if (!meta.exists) {
          transaction.set(gref, {
            lifecycleState: "deleting",
            orphanCleanup: true,
          }, { merge: true });
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "scanDeletionMembers",
          });
        }
        const source = meta.data() || {};
        if (source.lifecycleState === "deleting") {
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "scanDeletionMembers",
          });
        }
        const transformed = anonymizeMeta(source, uid, nickname);
        if (transformed !== source) {
          transaction.update(gref, {
            lastWeekMvpUid: transformed.lastWeekMvpUid,
            lastWeekMvp: transformed.lastWeekMvp,
          });
        }
        return writeState(transaction, targetRef, state, {
          stage: CONTENT_STAGES[0],
          cursor: null,
        });
      });
    }

    if (CONTENT_STAGES.includes(state.stage)) {
      const name = state.stage;
      const page = await queryPage(gref.collection(name), state, limit);
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const meta = await transaction.get(gref);
        if (!meta.exists ||
            (meta.data() || {}).lifecycleState === "deleting") {
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "scanDeletionMembers",
          });
        }
        const documents = page.docs.length === 0
          ? []
          : await transaction.getAll(
            ...page.docs.map((document) => document.ref),
          );
        for (const document of documents) {
          if (!document.exists) continue;
          const source = document.data() || {};
          if (name === "reports" &&
              shouldDeleteReportForUid(source, uid)) {
            transaction.delete(document.ref);
            continue;
          }
          const transformed = transformFor(name, source, uid, nickname);
          if (transformed !== source) {
            transaction.update(
              document.ref,
              contentFields(name, transformed),
            );
          }
        }
        const pageComplete = page.docs.length < limit;
        const index = CONTENT_STAGES.indexOf(name);
        return writeState(transaction, targetRef, state, {
          stage: pageComplete
            ? CONTENT_STAGES[index + 1] || "reconcile"
            : name,
          cursor: pageComplete ? null : page.docs.at(-1).id,
        });
      });
    }

    if (state.stage === "reconcile") {
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const meta = await transaction.get(gref);
        const departingRef = gref.collection("members").doc(uid);
        const departing = await transaction.get(departingRef);
        if (!meta.exists ||
            (meta.data() || {}).lifecycleState === "deleting") {
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "scanDeletionMembers",
          });
        }
        const data = meta.data() || {};
        if (data.ownerId !== uid) {
          if (departing.exists) {
            transaction.delete(departingRef);
            if (Number.isInteger(data.memberCount)) {
              transaction.update(gref, {
                memberCount: Math.max(0, data.memberCount - 1),
              });
            }
          }
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "done",
          });
        }
        return writeState(transaction, targetRef, state, {
          stage: "resetMemberTargets",
          cursor: null,
          afterStage: "scanOwnerMembers",
          expectedMemberCount: Number.isInteger(data.memberCount)
            ? data.memberCount
            : null,
          remainingCount: 0,
          successor: null,
        });
      });
    }

    if (state.stage === "resetMemberTargets") {
      const page = await memberTargets
        .orderBy(documentIdFieldPath)
        .limit(limit)
        .get();
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const documents = page.docs.length === 0
          ? []
          : await transaction.getAll(
            ...page.docs.map((document) => document.ref),
          );
        documents
          .filter((document) => document.exists)
          .forEach((document) => transaction.delete(document.ref));
        if (page.docs.length > 0) return { done: false, state };
        const afterStage = typeof state.afterStage === "string"
          ? state.afterStage
          : "done";
        return writeState(transaction, targetRef, state, {
          stage: afterStage,
          cursor: null,
          afterStage: null,
          ...(afterStage === "scanOwnerMembers"
            ? { remainingCount: 0, successor: null }
            : {}),
        });
      });
    }

    if (state.stage === "scanOwnerMembers" ||
        state.stage === "scanDeletionMembers") {
      const page = await queryPage(
        gref.collection("members"),
        state,
        limit,
      );
      const memberRefs = page.docs.map((document) => document.ref);
      const banRefs = page.docs.map((document) =>
        gref.collection("bans").doc(document.id));
      const deletionRefs = page.docs.map((document) =>
        firestore.collection("account_deletions").doc(document.id));
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const meta = await transaction.get(gref);
        if (state.stage === "scanOwnerMembers" &&
            (!meta.exists ||
              (meta.data() || {}).lifecycleState === "deleting" ||
              (meta.data() || {}).ownerId !== uid)) {
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "reconcile",
          });
        }
        const currentMembers = memberRefs.length === 0
          ? []
          : await transaction.getAll(...memberRefs);
        const currentBans = banRefs.length === 0
          ? []
          : await transaction.getAll(...banRefs);
        const currentDeletions = deletionRefs.length === 0
          ? []
          : await transaction.getAll(...deletionRefs);
        let remainingCount = Number.isInteger(state.remainingCount)
          ? state.remainingCount
          : 0;
        let successor = state.successor || null;
        for (let index = 0; index < currentMembers.length; index += 1) {
          const member = currentMembers[index];
          if (!member.exists) continue;
          const memberUid = member.id;
          transaction.set(
            memberTargets.doc(memberUid),
            { uid: memberUid },
            { merge: true },
          );
          if (state.stage !== "scanOwnerMembers" || memberUid === uid) {
            continue;
          }
          remainingCount += 1;
          const memberData = member.data() || {};
          const banData = currentBans[index]?.exists
            ? currentBans[index].data() || {}
            : {};
          if (memberData.status !== "active" ||
              (currentBans[index]?.exists && banData.active !== false) ||
              currentDeletions[index]?.exists) {
            continue;
          }
          successor = earlierSuccessor(successor, {
            uid: memberUid,
            joinedAtMillis: millis(
              memberData.joinedAtMillis ?? memberData.joinedAt,
            ),
          });
        }
        const pageComplete = page.docs.length < limit;
        return writeState(transaction, targetRef, state, {
          stage: pageComplete
            ? state.stage === "scanOwnerMembers"
              ? "finalizeOwner"
              : "clearDeletionMemberCaches"
            : state.stage,
          cursor: pageComplete ? null : page.docs.at(-1).id,
          remainingCount,
          successor,
        });
      });
    }

    if (state.stage === "finalizeOwner") {
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const meta = await transaction.get(gref);
        if (!meta.exists ||
            (meta.data() || {}).lifecycleState === "deleting") {
          return writeState(transaction, targetRef, state, {
            stage: "clearDeletionMemberCaches",
            cursor: null,
          });
        }
        const metaData = meta.data() || {};
        const countChanged =
          Number.isInteger(state.expectedMemberCount) &&
          metaData.memberCount !== state.expectedMemberCount;
        if (metaData.ownerId !== uid || countChanged) {
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "reconcile",
          });
        }

        const successorUid =
          typeof state.successor?.uid === "string"
            ? state.successor.uid
            : null;
        let successor = null;
        let successorBan = null;
        let successorDeletion = null;
        if (successorUid) {
          [successor, successorBan, successorDeletion] =
            await transaction.getAll(
              gref.collection("members").doc(successorUid),
              gref.collection("bans").doc(successorUid),
              firestore.collection("account_deletions").doc(successorUid),
            );
        }
        const successorData = successor?.exists
          ? successor.data() || {}
          : {};
        const successorIsValid = successor?.exists &&
          successorData.status === "active" &&
          (!successorBan?.exists ||
            (successorBan.data() || {}).active === false) &&
          !successorDeletion?.exists;
        if (successorUid && !successorIsValid) {
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "scanOwnerMembers",
            remainingCount: 0,
            successor: null,
          });
        }

        if (successorIsValid) {
          const departingRef = gref.collection("members").doc(uid);
          const departing = await transaction.get(departingRef);
          if (departing.exists) transaction.delete(departingRef);
          transaction.update(gref, {
            ownerId: successorUid,
            memberCount: Number.isInteger(state.remainingCount)
              ? state.remainingCount
              : 0,
            lifecycleState: "active",
          });
          transaction.update(successor.ref, {
            role: "owner",
            status: "active",
          });
          return writeState(transaction, targetRef, state, {
            stage: "resetMemberTargets",
            cursor: null,
            afterStage: "done",
          });
        }

        transaction.set(
          gref,
          { lifecycleState: "deleting" },
          { merge: true },
        );
        return writeState(transaction, targetRef, state, {
          stage: "clearDeletionMemberCaches",
          cursor: null,
        });
      });
    }

    if (state.stage === "clearDeletionMemberCaches") {
      const page = await memberTargets
        .orderBy(documentIdFieldPath)
        .limit(limit)
        .get();
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const targets = page.docs.length === 0
          ? []
          : await transaction.getAll(
            ...page.docs.map((document) => document.ref),
          );
        const userRefs = targets
          .filter((target) => target.exists)
          .map((target) => firestore.collection("users").doc(target.id));
        const users = userRefs.length === 0
          ? []
          : await transaction.getAll(...userRefs);
        for (const user of users) {
          if (user.exists) {
            transaction.update(user.ref, {
              gyeIds: fieldValue.arrayRemove(gyeId),
            });
          }
        }
        targets
          .filter((target) => target.exists)
          .forEach((target) => transaction.delete(target.ref));
        if (page.docs.length > 0) return { done: false, state };
        return writeState(transaction, targetRef, state, {
          stage: "clearDeletionCachedUsers",
          cursor: null,
        });
      });
    }

    if (state.stage === "clearDeletionCachedUsers") {
      const page = await firestore
        .collection("users")
        .where("gyeIds", "array-contains", gyeId)
        .orderBy(documentIdFieldPath)
        .limit(limit)
        .get();
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const users = page.docs.length === 0
          ? []
          : await transaction.getAll(
            ...page.docs.map((document) => document.ref),
          );
        users
          .filter((user) =>
            user.exists &&
            Array.isArray((user.data() || {}).gyeIds) &&
            (user.data() || {}).gyeIds.includes(gyeId))
          .forEach((user) => transaction.update(user.ref, {
            gyeIds: fieldValue.arrayRemove(gyeId),
          }));
        if (page.docs.length > 0) return { done: false, state };
        return writeState(transaction, targetRef, state, {
          stage: "deleteCollections",
          cursor: null,
          collectionIndex: 0,
        });
      });
    }

    if (state.stage === "deleteCollections") {
      const index = Number.isInteger(state.collectionIndex)
        ? state.collectionIndex
        : 0;
      if (index >= DELETE_COLLECTIONS.length) {
        return runFencedTransaction(async ({ transaction }) => {
          if (!await currentTarget(transaction, targetRef, state)) {
            return { done: true };
          }
          return writeState(transaction, targetRef, state, {
            stage: "deleteParent",
            cursor: null,
          });
        });
      }
      const page = await gref
        .collection(DELETE_COLLECTIONS[index])
        .orderBy(documentIdFieldPath)
        .limit(limit)
        .get();
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        const documents = page.docs.length === 0
          ? []
          : await transaction.getAll(
            ...page.docs.map((document) => document.ref),
          );
        documents
          .filter((document) => document.exists)
          .forEach((document) => transaction.delete(document.ref));
        return writeState(transaction, targetRef, state, {
          stage: "deleteCollections",
          cursor: null,
          collectionIndex: page.docs.length < limit ? index + 1 : index,
        });
      });
    }

    if (state.stage === "deleteParent") {
      return runFencedTransaction(async ({ transaction }) => {
        if (!await currentTarget(transaction, targetRef, state)) {
          return { done: true };
        }
        for (let index = 0; index < DELETE_COLLECTIONS.length; index += 1) {
          const remainder = await transaction.get(
            gref
              .collection(DELETE_COLLECTIONS[index])
              .orderBy(documentIdFieldPath)
              .limit(1),
          );
          if (!remainder.empty) {
            return writeState(transaction, targetRef, state, {
              stage: "deleteCollections",
              cursor: null,
              collectionIndex: index,
            });
          }
        }
        transaction.delete(gref);
        return writeState(transaction, targetRef, state, {
          stage: "done",
          cursor: null,
        });
      });
    }

    throw pageFailure("invalid-gye-cleanup-state");
  }

  return Object.freeze({ cleanupPage });
}

module.exports = {
  createGyeDeletionPageCleaner,
};
