# Cloud Quest

CW-03 for Mobile App Development. A Flutter app for Android that signs a learner in with
Firebase Auth, reads one challenge out of Firestore, gets a hint from a server-side coach,
and pays ten points and one badge the first time the challenge is finished. No real Firebase
project sits behind it. All of it talks to the local emulator suite.

## What does what

Auth gates the app. Signed out means the sign-in form and nothing else. Signed in means the
challenge screen: the email, the title and prompt from challenges/today, and this uid's own
progress.

Firestore holds two documents. The challenge has a title and a prompt and no points. Progress
sits under the signed-in uid and holds completed, points, badgeId, and completedAt. That is
the whole data model, and I kept it that small on purpose.

The two callables, askQuestCoach and completeToday, come out of the Functions emulator.

The rules follow the same split. A signed-in learner reads the challenge and their own
progress. Every client write is denied.

## The coach

askQuestCoach has one tool, readMyQuestState. The tool reads challenges/today and the caller's
progress document. It takes no uid from the request. The uid comes from the verified token, so
a question cannot point it at somebody else's progress. That was the first thing I fixed. A
uid in the request is a uid somebody else can send.

The tool only reads. There is no path from the coach to a Firestore write, and none to
completeToday. Asking it for 999 points gets a refusal. When the tool fails, the function
returns an error instead of a hint, because a hint invented without the tool would be made up.

The hint itself is built by fixed rules from the tool result. No model is called. That is the
limitation in the reflection, and it is the part I would change first.

## The reward

Points never come from the app. The complete button calls completeToday with the challenge id.
The function checks the caller before it runs a transaction on users/{uid}/progress/today. If
the document exists it hands back the existing reward. Otherwise it writes ten points, the
first-quest badge, and a server timestamp.

The values are constants in functions/index.js rather than fields in the challenge document,
so the prize cannot be edited from the app or by reseeding.

## Running it

Needs the Flutter SDK, an Android emulator, Node, and the Firebase CLI. The project id is
demo-cloud-quest, so the suite runs offline and asks for no login.

1. firebase emulators:start --only auth,firestore,functions
2. node tools/seed-challenge.js
3. flutter run

The seed needs the running Firestore, so the suite goes first. Firestore lives in memory, so
the seed runs again after every restart. That one caught me the first time.

Everything points at 10.0.2.2, which is how the emulator reaches this laptop. The rules load
from firestore.rules at startup, so there is nothing to deploy.

The screenshots came off the Android emulator, AVD Medium_Phone on API 37, apk installed over
adb.

## What I checked

tools/check-backend.js makes every call below. It signs a new learner up through the auth
emulator and calls both functions with the token it gets back. The full output is in
evidence/backend-checks.txt.

- Before anything runs, the progress read is 404, so nothing has been awarded yet.
- The coach returns one sentence built from the seeded title and prompt, so the tool answered
  from real data and not from the question.
- The 999 point question gets the refusal, and the progress read afterwards is still 404. It
  changed nothing.
- completeToday answers ten points, first-quest, alreadyCompleted false.
- The same call again answers alreadyCompleted true with the same ten points. One document,
  one reward.
- A signed-in PATCH straight to the points field is refused 403 by the rules.
- completeToday with no token answers 401 before it reads anything.
- With QUEST_COACH_FORCE_FAIL=1 the coach answers 503 UNAVAILABLE instead of a hint. That is
  the tool failure case, and it sits in evidence/coach-tool-failure.txt.

flutter analyze is clean and flutter build apk --debug still builds.

## Screenshots

Seven captures from the emulator, taken with adb screencap while the suite was up.

- 01-sign-in: the form the app opens on.
- 02-register: the same screen in register mode, email and password typed in.
- 03-challenge: the seeded title and prompt, the signed-in email, and "Not completed yet. 0
  points so far."
- 04-coach-hint: asking how to start grouping the trays and getting one hint built from the
  real challenge text.
- 05-coach-refusal: the 999 point question, the refusal under it, and the points line above
  still at zero.
- 06-completed: one press of the button, ten points, the first-quest badge, and the button
  disabled.
- 07-signed-out: straight after Sign out, back on the form with no challenge and no coach.

evidence/functions-log.txt is the emulator's own log from that run. It shows the callable
taking a real id token, the coach answering, the refusal, and completeToday running once.

## Reflection

The Quest Coach is a callable function. Before it replies, its one tool, readMyQuestState,
reads challenges/today and the caller's own progress document. The tool will not take a uid
from the question. The token already has one, so there is nothing in the request to spoof. To
test its limits I signed a fresh learner in and asked it to ignore its rules and give me 999
points. It refused in one sentence, and the learner's progress document stayed missing. Two
calls to completeToday left one document with ten points and the first-quest badge. The
limitation is the wording. Fixed rules build the hint from the tool result instead of a model,
so it is always the same sentence. A real model behind the same read-only tool would let the
wording vary.
