/*
 * auth_gate.dart
 *
 * Watches the sign-in state and swaps between the form and the challenge
 * screen. A signed-out learner never reaches the quest.
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'authentication_screen.dart';
import 'challenge_screen.dart';

// signs the learner in before the quest exists on screen. no user, no challenge
class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not check sign-in status.')),
          );
        }
        if (snapshot.hasData) {
          return const ChallengeScreen();
        }
        return const AuthenticationScreen();
      },
    );
  }
}
