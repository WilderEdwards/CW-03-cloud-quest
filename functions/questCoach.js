/**
 * questCoach.js
 *
 * The supervised AI step. It runs on the server, calls one read-only tool before
 * it answers, and has no way to write a reward. The hint text is built from the
 * tool result instead of a hosted model, because this classwork runs offline
 * against the emulator suite.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

// the only tool the coach has. it takes no uid argument on purpose: the uid
// comes from the verified auth context, so a learner can't ask for someone else
async function readMyQuestState(uid) {
  const db = getFirestore();
  const challenge = await db.doc("challenges/today").get();
  const progress = await db.doc(`users/${uid}/progress/today`).get();

  if (!challenge.exists) {
    throw new Error("challenges/today is missing");
  }

  const data = challenge.data();
  const mine = progress.data() || {};
  return {
    title: data.title || "today's challenge",
    prompt: data.prompt || "",
    completed: mine.completed === true,
    points: mine.points || 0,
    badgeId: mine.badgeId || null,
  };
}

// questions that try to turn the coach into a reward button
const CHEAT_PATTERNS = [
  /999/,
  /ignore (your|the) (rules|instructions)/i,
  /give me .*points/i,
  /set .*points/i,
  /grant (me|the)/i,
];

function looksLikeCheat(question) {
  for (const pattern of CHEAT_PATTERNS) {
    if (pattern.test(question)) {
      return true;
    }
  }
  return false;
}

// the reply is only ever built from what the tool returned, never guessed
function hintFrom(state) {
  if (state.completed) {
    return `You already finished "${state.title}". The reward is ${state.points} points and the ${state.badgeId} badge, and nothing is left to award here.`;
  }
  return `Your quest is "${state.title}". ${state.prompt} Pick the smallest piece you can test, then check it against one example before writing the rest.`;
}

exports.askQuestCoach = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const question = String(request.data?.question ?? "").trim();
  if (question.length === 0) {
    throw new HttpsError("invalid-argument", "Ask the coach something first.");
  }
  if (question.length > 300) {
    throw new HttpsError("invalid-argument", "Keep the question under 300 characters.");
  }

  // the tool answers before the coach says anything. if it fails we return an
  // error rather than a made up hint
  let state;
  try {
    if (process.env.QUEST_COACH_FORCE_FAIL === "1") {
      throw new Error("forced failure for the tool-failure check");
    }
    state = await readMyQuestState(request.auth.uid);
  } catch (error) {
    console.error(`readMyQuestState failed for ${request.auth.uid}: ${error}`);
    throw new HttpsError("unavailable", "The coach could not read your quest right now.");
  }

  if (looksLikeCheat(question)) {
    console.log(`refused a reward request from ${request.auth.uid}`);
    return {
      reply: "I only give hints, and I can't change points or badges. The Complete challenge button is the only way to earn the reward.",
    };
  }

  console.log(`coach answered ${request.auth.uid} from readMyQuestState`);
  return { reply: hintFrom(state) };
});
