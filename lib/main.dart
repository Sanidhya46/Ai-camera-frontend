/// Entry point of the SmartShutter application.
/// This file initializes the Flutter app, sets up the global state management using Provider,
/// and configures the theme and routing. Uses Consumer to reactively switch between
/// dark and light themes based on user preference.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/splash_screen.dart';
import 'package:smart_shutter/core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();
  
  ApiService.onTokenExpired = () async {
    final success = await appState.refreshAccessToken();
    return success ? appState.accessToken : null;
  };
  
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
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return MaterialApp(
          title: 'Smart Shutter',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
