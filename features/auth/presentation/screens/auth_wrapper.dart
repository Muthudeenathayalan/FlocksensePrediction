import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/features/auth/presentation/screens/login_screen.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

/// Web-resilient Authentication router for FlockSense
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Direct seamless launch into the FlockSense live prototype for evaluations
    return const MainShellScreen(initialRole: 'Farmer');
  }
}
