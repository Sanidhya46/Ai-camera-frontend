/// Registration screen for new SmartShutter users.
/// Delegates to AuthScreen with register mode.
library;

import 'package:flutter/material.dart';
import 'package:smart_shutter/screens/auth/auth_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(
      initialMode: AuthInitialMode.register,
      animateEntrance: true,
    );
  }
}
