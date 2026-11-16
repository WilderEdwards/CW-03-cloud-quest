/*
 * reward_service.dart
 *
 * Calls the completeToday function and turns its answer into a small result the
 * screen can show. The points and badge values never come from the app.
 */
import 'package:cloud_functions/cloud_functions.dart';

// what completeToday sends back. alreadyCompleted is true when the learner
// tapped twice, or the call was retried, and the reward already existed
class RewardResult {
  RewardResult({
    required this.points,
    required this.badgeId,
    required this.alreadyCompleted,
  });

  final int points;
  final String? badgeId;
  final bool alreadyCompleted;
}

Future<RewardResult> completeChallenge() async {
  // the app only names the challenge. the function works out the uid and the
  // points/badge values on the server
  final callable = FirebaseFunctions.instance.httpsCallable('completeToday');
  final result = await callable.call<Map<String, dynamic>>({
    'challengeId': 'today',
  });

  final data = result.data;
  return RewardResult(
    points: (data['points'] as num?)?.toInt() ?? 0,
    badgeId: data['badgeId'] as String?,
    alreadyCompleted: data['alreadyCompleted'] as bool? ?? false,
  );
}
