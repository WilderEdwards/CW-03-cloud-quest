/*
 * coach_service.dart
 *
 * Sends the learner's question to the askQuestCoach function and returns the
 * hint it sends back. The app never tells the function who the learner is.
 */
import 'package:cloud_functions/cloud_functions.dart';

Future<String> getHint(String question) async {
  final trimmed = question.trim();
  // the function rejects anything longer, so trim here first
  final safeQuestion = trimmed.length > 300 ? trimmed.substring(0, 300) : trimmed;

  final callable = FirebaseFunctions.instance.httpsCallable('askQuestCoach');
  final result = await callable.call<Map<String, dynamic>>({
    'question': safeQuestion,
  });

  final reply = result.data['reply'];
  if (reply is! String) {
    throw StateError('The coach sent back something the app cannot read.');
  }
  return reply;
}
