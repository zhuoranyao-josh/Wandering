const {logger} = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();

const firestore = getFirestore();
const FUNCTION_EVENT_COLLECTION = "functionEvents";

exports.onCommentCreated = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    await syncPostCounter({
      event,
      delta: 1,
      eventType: "comment_created",
      fieldName: "commentCount",
      itemId: event.params.commentId,
    });
  },
);

exports.onCommentDeleted = onDocumentDeleted(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    await syncPostCounter({
      event,
      delta: -1,
      eventType: "comment_deleted",
      fieldName: "commentCount",
      itemId: event.params.commentId,
    });
  },
);

exports.onPostLikeCreated = onDocumentCreated(
  "posts/{postId}/likes/{userId}",
  async (event) => {
    await syncPostCounter({
      event,
      delta: 1,
      eventType: "post_like_created",
      fieldName: "likeCount",
      itemId: event.params.userId,
    });
  },
);

exports.onPostLikeDeleted = onDocumentDeleted(
  "posts/{postId}/likes/{userId}",
  async (event) => {
    await syncPostCounter({
      event,
      delta: -1,
      eventType: "post_like_deleted",
      fieldName: "likeCount",
      itemId: event.params.userId,
    });
  },
);

exports.onUserFollowCreated = onDocumentCreated(
  "users/{userId}/following/{targetUserId}",
  async (event) => {
    await syncFollowCounts({
      event,
      delta: 1,
      eventType: "user_follow_created",
    });
  },
);

exports.onUserFollowDeleted = onDocumentDeleted(
  "users/{userId}/following/{targetUserId}",
  async (event) => {
    await syncFollowCounts({
      event,
      delta: -1,
      eventType: "user_follow_deleted",
    });
  },
);

async function syncPostCounter({event, delta, eventType, fieldName, itemId}) {
  const postId = event.params.postId;
  const eventId = `${eventType}_${event.id}`;
  const eventRef = firestore.collection(FUNCTION_EVENT_COLLECTION).doc(eventId);
  const postRef = firestore.collection("posts").doc(postId);

  // 用事务把“去重 + 计数更新”绑在一起，避免重复投递造成计数偏移。
  await firestore.runTransaction(async (transaction) => {
    const eventDoc = await transaction.get(eventRef);
    if (eventDoc.exists) {
      logger.info("Community post counter event already processed, skip.", {
        eventId,
        postId,
        itemId,
        eventType,
        fieldName,
      });
      return;
    }

    const postDoc = await transaction.get(postRef);
    if (!postDoc.exists) {
      logger.warn("Community post missing when syncing counter.", {
        eventId,
        postId,
        itemId,
        eventType,
        fieldName,
      });
      transaction.set(eventRef, {
        eventType,
        fieldName,
        postId,
        itemId,
        status: "skipped_missing_post",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const currentValue = readNonNegativeCount(postDoc.data()?.[fieldName]);
    const nextValue = safeNextCount(currentValue, delta);

    transaction.update(postRef, {
      [fieldName]: nextValue,
    });
    transaction.set(eventRef, {
      eventType,
      fieldName,
      postId,
      itemId,
      status: "applied",
      delta,
      previousValue: currentValue,
      nextValue,
      processedAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Community post counter synced.", {
    eventId,
    postId,
    itemId,
    eventType,
    fieldName,
    delta,
  });
}

async function syncFollowCounts({event, delta, eventType}) {
  const userId = event.params.userId;
  const targetUserId = event.params.targetUserId;
  const eventId = `${eventType}_${event.id}`;
  const eventRef = firestore.collection(FUNCTION_EVENT_COLLECTION).doc(eventId);
  const userRef = firestore.collection("users").doc(userId);
  const targetUserRef = firestore.collection("users").doc(targetUserId);

  // 关注计数同时更新两侧用户文档，确保 follower / following 始终成对变化。
  await firestore.runTransaction(async (transaction) => {
    const eventDoc = await transaction.get(eventRef);
    if (eventDoc.exists) {
      logger.info("Community follow event already processed, skip.", {
        eventId,
        userId,
        targetUserId,
        eventType,
      });
      return;
    }

    const [userDoc, targetUserDoc] = await Promise.all([
      transaction.get(userRef),
      transaction.get(targetUserRef),
    ]);
    if (!userDoc.exists || !targetUserDoc.exists) {
      logger.warn("Community user missing when syncing follow counts.", {
        eventId,
        userId,
        targetUserId,
        eventType,
      });
      transaction.set(eventRef, {
        eventType,
        userId,
        targetUserId,
        status: "skipped_missing_user",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const currentFollowingCount = readNonNegativeCount(
      userDoc.data()?.followingCount,
    );
    const currentFollowerCount = readNonNegativeCount(
      targetUserDoc.data()?.followerCount,
    );
    const nextFollowingCount = safeNextCount(currentFollowingCount, delta);
    const nextFollowerCount = safeNextCount(currentFollowerCount, delta);

    transaction.update(userRef, {
      followingCount: nextFollowingCount,
    });
    transaction.update(targetUserRef, {
      followerCount: nextFollowerCount,
    });
    transaction.set(eventRef, {
      eventType,
      userId,
      targetUserId,
      status: "applied",
      delta,
      previousFollowingCount: currentFollowingCount,
      nextFollowingCount,
      previousFollowerCount: currentFollowerCount,
      nextFollowerCount,
      processedAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Community follow counts synced.", {
    eventId,
    userId,
    targetUserId,
    eventType,
    delta,
  });
}

function readNonNegativeCount(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.trunc(value));
  }
  return 0;
}

function safeNextCount(currentValue, delta) {
  return Math.max(0, currentValue + delta);
}
