/**
 * check-coach-failure.js
 *
 * Checks what the coach does when its tool cannot read quest data. The functions
 * emulator has to be started with QUEST_COACH_FORCE_FAIL=1 for this run, so the
 * tool throws before it reads anything. The answer should be an error, not a hint.
 *
 * Run it with the emulators up: node tools/check-coach-failure.js
 */

const AUTH = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1";
const FUNCTIONS = "http://127.0.0.1:5001/demo-cloud-quest/us-central1";

async function main() {
  const email = `failure${Date.now()}@example.com`;
  const signUp = await fetch(`${AUTH}/accounts:signUp?key=demo-api-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: "password123", returnSecureToken: true }),
  });
  const account = await signUp.json();

  const response = await fetch(`${FUNCTIONS}/askQuestCoach`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${account.idToken}`,
    },
    body: JSON.stringify({ data: { question: "Any hint for today?" } }),
  });

  console.log(`coach with the tool forced to fail: ${response.status} ${await response.text()}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
