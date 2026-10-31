/// Login screen for SmartShutter users.
/// Delegates to AuthScreen with login mode.
library;

import 'package:flutter/material.dart';
import 'package:smart_shutter/screens/auth/auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(
      initialMode: AuthInitialMode.login,
      animateEntrance: true,
    );
  }
}
