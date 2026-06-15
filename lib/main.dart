/// Entry point of the SmartShutter application.
/// This file initializes the Flutter app, sets up the global state management using Provider,
/// and configures the theme and routing. It ensures all necessary bindings are initialized
/// before the app runs and wraps the entire app with state providers for centralized state management.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
      ],
      child: const SmartShutterApp(),
    ),
  );
}

class SmartShutterApp extends StatelessWidget {
  const SmartShutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShutter',
      theme: AppTheme.theme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
