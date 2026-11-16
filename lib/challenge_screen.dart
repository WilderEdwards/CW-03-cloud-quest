/*
 * challenge_screen.dart
 *
 * Shows today's challenge, this learner's points, and the coach hint box.
 * The screen asks the reward function for points; it never writes them itself.
 */
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'services/challenge_service.dart';
import 'services/coach_service.dart';
import 'services/reward_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _auth = AuthService();
  final _question = TextEditingController();

  QuestState? _quest;
  bool _loading = true;
  bool _completing = false;
  bool _askingCoach = false;
  String? _loadError;
  String? _rewardMessage;
  String? _coachReply;
  String? _coachError;

  @override
  void initState() {
    super.initState();
    _loadQuest();
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  // reads the shared challenge and this learner's progress from firestore
  Future<void> _loadQuest() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final quest = await loadToday();
      if (!mounted) return;
      setState(() => _quest = quest);
    } catch (error) {
      debugPrint('loading the quest failed: $error');
      if (!mounted) return;
      setState(() => _loadError = 'Could not load today\'s challenge.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // the only way points are ever awarded. the function decides, not this screen
  Future<void> _complete() async {
    setState(() {
      _completing = true;
      _rewardMessage = null;
      _loadError = null;
    });
    try {
      final result = await completeChallenge();
      if (!mounted) return;
      setState(() {
        _rewardMessage = result.alreadyCompleted
            ? 'You already finished this quest. Still ${result.points} points and the ${result.badgeId} badge.'
            : 'Quest complete! ${result.points} points and the ${result.badgeId} badge.';
      });
      await _loadQuest();
    } on FirebaseFunctionsException catch (error) {
      debugPrint('completeToday failed: ${error.code}');
      if (!mounted) return;
      setState(() {
        _loadError = 'The reward could not be saved (${error.code}). Try again.';
      });
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _askCoach() async {
    final text = _question.text.trim();
    if (text.isEmpty) {
      setState(() => _coachError = 'Type a question for the coach first.');
      return;
    }

    setState(() {
      _askingCoach = true;
      _coachError = null;
      _coachReply = null;
    });
    try {
      final reply = await getHint(text);
      if (!mounted) return;
      setState(() => _coachReply = reply);
    } catch (error) {
      // the coach never invents quest state, so a failed tool call shows an error
      debugPrint('askQuestCoach failed: $error');
      if (!mounted) return;
      setState(() => _coachError = 'The coach is unavailable right now. Try again.');
    } finally {
      if (mounted) setState(() => _askingCoach = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final quest = _quest;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Signed in as ${user?.email ?? user?.uid ?? 'unknown'}'),
                  const SizedBox(height: 16),
                  if (_loadError != null) ...[
                    Text(
                      _loadError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (quest != null) ...[
                    Text(quest.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(quest.prompt),
                    const SizedBox(height: 16),
                    Text(
                      quest.completed
                          ? 'Completed. ${quest.points} points, badge ${quest.badgeId}.'
                          : 'Not completed yet. 0 points so far.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _completing || quest.completed ? null : _complete,
                      child: _completing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              quest.completed
                                  ? 'Challenge complete'
                                  : 'Complete challenge',
                            ),
                    ),
                    if (_rewardMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_rewardMessage!),
                    ],
                    const Divider(height: 32),
                    Text('Ask the Quest Coach', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _question,
                      enabled: !_askingCoach,
                      maxLength: 300,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ask for a hint',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: _askingCoach ? null : _askCoach,
                        child: Text(_askingCoach ? 'Thinking...' : 'Get hint'),
                      ),
                    ),
                    if (_coachError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _coachError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    if (_coachReply != null) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_coachReply!),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}
