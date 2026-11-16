/**
 * seed-challenge.js
 *
 * Puts the one challenge document into the running firestore emulator. It uses
 * the admin sdk that functions/ already depends on, because the admin sdk is the
 * one client the emulator lets past the rules that block app writes.
 *
 * Run it after the emulators are up: node tools/seed-challenge.js
 */

// the admin sdk reads this to talk to the emulator instead of a real project
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

// functions/ has the admin sdk installed, so borrow it rather than adding a
// second copy for one script
const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({ projectId: "demo-cloud-quest" });

const challenge = {
  title: "Sort the Dining Hall Trays",
  prompt:
    "Write a function that takes one list of tray items and returns them grouped into clean, food, and trash. Start with one item, then make the whole list work.",
};

admin
  .firestore()
  .doc("challenges/today")
  .set(challenge)
  .then(() => {
    console.log("seeded challenges/today");
    process.exit(0);
  })
  .catch((error) => {
    console.error(`seeding failed: ${error.message}`);
    process.exit(1);
  });
