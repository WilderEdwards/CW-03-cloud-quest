/*
 * challenge_service.dart
 *
 * Reads the shared challenge document and this learner's progress document in
 * one trip. Both reads depend on a signed-in uid.
 */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// the two documents the challenge screen needs, read together
class QuestState {
  QuestState({
    required this.title,
    required this.prompt,
    required this.completed,
    required this.points,
    required this.badgeId,
  });

  final String title;
  final String prompt;
  final bool completed;
  final int points;
  final String? badgeId;
}

Future<QuestState> loadToday() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError('Sign in before loading the quest.');
  }

  // challenges/today is shared and read only. the progress document is scoped to
  // this uid, and only the reward function is allowed to write it
  final challenge = await FirebaseFirestore.instance
      .collection('challenges')
      .doc('today')
      .get();
  final progress = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('progress')
      .doc('today')
      .get();

  final challengeData = challenge.data();
  if (challengeData == null) {
    throw StateError('Today\'s challenge has not been seeded yet.');
  }

  final progressData = progress.data();
  return QuestState(
    title: challengeData['title'] as String? ?? 'Today\'s challenge',
    prompt: challengeData['prompt'] as String? ?? '',
    completed: progressData?['completed'] as bool? ?? false,
    points: (progressData?['points'] as num?)?.toInt() ?? 0,
    badgeId: progressData?['badgeId'] as String?,
  );
}
