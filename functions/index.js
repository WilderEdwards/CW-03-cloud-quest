/**
 * index.js
 *
 * The trusted half of Cloud Quest. completeToday is the only thing that ever
 * awards points, and the coach lives next door in questCoach.js.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { askQuestCoach } = require("./questCoach");

initializeApp();

// the reward lives in code, not in the challenge document, so nobody can edit
// the prize from the app
const POINTS = 10;
const BADGE_ID = "first-quest";

exports.completeToday = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  if (request.data?.challengeId !== "today") {
    throw new HttpsError("invalid-argument", "Unknown challenge.");
  }

  // the uid comes from the verified token, so a learner can only ever touch
  // their own progress document
  const uid = request.auth.uid;
  const db = getFirestore();
  const progressRef = db.doc(`users/${uid}/progress/today`);

  return db.runTransaction(async (transaction) => {
    const progress = await transaction.get(progressRef);
    if (progress.exists) {
      // a double tap or a retried call lands here and gets the same reward back
      const data = progress.data();
      return {
        completed: true,
        points: data.points,
        badgeId: data.badgeId,
        alreadyCompleted: true,
      };
    }

    const reward = {
      completed: true,
      points: POINTS,
      badgeId: BADGE_ID,
      completedAt: FieldValue.serverTimestamp(),
    };
    transaction.set(progressRef, reward);
    return {
      completed: true,
      points: reward.points,
      badgeId: reward.badgeId,
      alreadyCompleted: false,
    };
  });
});

exports.askQuestCoach = askQuestCoach;
