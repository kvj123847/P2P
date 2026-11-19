import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/authentication/splash_screen.dart';

class PeerTeachingApp extends StatelessWidget {
  const PeerTeachingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learn Share Grow',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
