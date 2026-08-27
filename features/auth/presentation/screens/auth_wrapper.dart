import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/features/auth/presentation/screens/login_screen.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

/// Web-resilient Authentication router for FlockSense
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const LoginScreen();
        }
        return const MainShellScreen();
      },
    );
  }
}
